package com.myapp.api.service;

import com.myapp.api.dto.ProductDTO;
import com.myapp.api.entity.Product;
import com.myapp.api.exception.BadRequestException;
import com.myapp.api.exception.ResourceNotFoundException;
import com.myapp.api.mapper.ProductMapper;
import com.myapp.api.repository.ProductRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class ProductService {

    private static final Logger log = LoggerFactory.getLogger(ProductService.class);

    private final ProductRepository productRepository;
    private final ProductMapper productMapper;

    public ProductService(ProductRepository productRepository, ProductMapper productMapper) {
        this.productRepository = productRepository;
        this.productMapper = productMapper;
    }

    @Transactional(readOnly = true)
    public Page<ProductDTO.Response> getAllProducts(Pageable pageable) {
        log.debug("Fetching all products, page: {}, size: {}", pageable.getPageNumber(), pageable.getPageSize());
        return productRepository.findAll(pageable).map(productMapper::toResponse);
    }

    @Transactional(readOnly = true)
    @Cacheable(value = "products", key = "#id")
    public ProductDTO.Response getProductById(Long id) {
        log.debug("Fetching product by id: {}", id);
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Product", "id", id));
        return productMapper.toResponse(product);
    }

    public ProductDTO.Response createProduct(ProductDTO.CreateRequest request) {
        log.info("Creating product with name: {}", request.getName());

        if (productRepository.existsByName(request.getName())) {
            throw new BadRequestException("Product with name '" + request.getName() + "' already exists");
        }

        Product product = productMapper.toEntity(request);
        if (product.getStock() == null) {
            product.setStock(0);
        }
        product.setActive(true);

        Product savedProduct = productRepository.save(product);
        log.info("Product created with id: {}", savedProduct.getId());
        return productMapper.toResponse(savedProduct);
    }

    @CacheEvict(value = "products", key = "#id")
    public ProductDTO.Response updateProduct(Long id, ProductDTO.UpdateRequest request) {
        log.info("Updating product with id: {}", id);

        Product product = productRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Product", "id", id));

        if (request.getName() != null && !request.getName().equals(product.getName())) {
            if (productRepository.existsByName(request.getName())) {
                throw new BadRequestException("Product with name '" + request.getName() + "' already exists");
            }
        }

        productMapper.updateEntity(request, product);
        Product updatedProduct = productRepository.save(product);
        log.info("Product updated with id: {}", updatedProduct.getId());
        return productMapper.toResponse(updatedProduct);
    }

    @CacheEvict(value = "products", key = "#id")
    public void deleteProduct(Long id) {
        log.info("Deleting product with id: {}", id);
        if (!productRepository.existsById(id)) {
            throw new ResourceNotFoundException("Product", "id", id);
        }
        productRepository.deleteById(id);
        log.info("Product deleted with id: {}", id);
    }
}
