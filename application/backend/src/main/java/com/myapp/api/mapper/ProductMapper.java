package com.myapp.api.mapper;

import com.myapp.api.dto.ProductDTO;
import com.myapp.api.entity.Product;
import org.mapstruct.BeanMapping;
import org.mapstruct.Mapper;
import org.mapstruct.MappingTarget;
import org.mapstruct.NullValuePropertyMappingStrategy;

import java.util.List;

@Mapper(componentModel = "spring")
public interface ProductMapper {

    ProductDTO.Response toResponse(Product product);

    List<ProductDTO.Response> toResponseList(List<Product> products);

    Product toEntity(ProductDTO.CreateRequest request);

    @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    void updateEntity(ProductDTO.UpdateRequest request, @MappingTarget Product product);
}
