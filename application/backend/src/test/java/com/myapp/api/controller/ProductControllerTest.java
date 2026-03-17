package com.myapp.api.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.myapp.api.dto.ProductDTO;
import com.myapp.api.exception.ResourceNotFoundException;
import com.myapp.api.security.JwtTokenProvider;
import com.myapp.api.service.ProductService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.bean.MockBean;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.is;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(ProductController.class)
class ProductControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private ProductService productService;

    @MockBean
    private JwtTokenProvider jwtTokenProvider;

    private ProductDTO.Response sampleProduct;
    private ProductDTO.CreateRequest createRequest;
    private ProductDTO.UpdateRequest updateRequest;

    @BeforeEach
    void setUp() {
        Instant now = Instant.now();
        sampleProduct = ProductDTO.Response.builder()
                .id(1L)
                .name("Wireless Headphones")
                .description("Premium noise-cancelling headphones")
                .price(new BigDecimal("149.99"))
                .category("Electronics")
                .stock(250)
                .imageUrl("https://images.example.com/headphones.jpg")
                .active(true)
                .createdAt(now)
                .updatedAt(now)
                .build();

        createRequest = ProductDTO.CreateRequest.builder()
                .name("Wireless Headphones")
                .description("Premium noise-cancelling headphones")
                .price(new BigDecimal("149.99"))
                .category("Electronics")
                .stock(250)
                .imageUrl("https://images.example.com/headphones.jpg")
                .build();

        updateRequest = ProductDTO.UpdateRequest.builder()
                .price(new BigDecimal("129.99"))
                .stock(200)
                .build();
    }

    @Test
    @DisplayName("GET /api/products - should return paginated products")
    void getAllProducts_shouldReturnPagedResponse() throws Exception {
        Page<ProductDTO.Response> page = new PageImpl<>(List.of(sampleProduct));
        when(productService.getAllProducts(any(Pageable.class))).thenReturn(page);

        mockMvc.perform(get("/api/products")
                        .param("page", "0")
                        .param("size", "20"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data", hasSize(1)))
                .andExpect(jsonPath("$.data[0].name", is("Wireless Headphones")));
    }

    @Test
    @DisplayName("GET /api/products/{id} - should return product by ID")
    void getProductById_shouldReturnProduct() throws Exception {
        when(productService.getProductById(1L)).thenReturn(sampleProduct);

        mockMvc.perform(get("/api/products/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.name", is("Wireless Headphones")))
                .andExpect(jsonPath("$.data.price", is(149.99)));
    }

    @Test
    @DisplayName("GET /api/products/{id} - should return 404 when product not found")
    void getProductById_shouldReturn404_whenNotFound() throws Exception {
        when(productService.getProductById(999L))
                .thenThrow(new ResourceNotFoundException("Product", "id", 999L));

        mockMvc.perform(get("/api/products/999"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success", is(false)));
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    @DisplayName("POST /api/products - should create product")
    void createProduct_shouldReturnCreatedProduct() throws Exception {
        when(productService.createProduct(any(ProductDTO.CreateRequest.class))).thenReturn(sampleProduct);

        mockMvc.perform(post("/api/products")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(createRequest)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.name", is("Wireless Headphones")));
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    @DisplayName("POST /api/products - should return 400 for invalid request")
    void createProduct_shouldReturn400_whenInvalid() throws Exception {
        ProductDTO.CreateRequest invalid = ProductDTO.CreateRequest.builder()
                .name("")
                .price(new BigDecimal("-1.00"))
                .category("")
                .build();

        mockMvc.perform(post("/api/products")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invalid)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    @DisplayName("PUT /api/products/{id} - should update product")
    void updateProduct_shouldReturnUpdatedProduct() throws Exception {
        ProductDTO.Response updated = ProductDTO.Response.builder()
                .id(1L)
                .name("Wireless Headphones")
                .description("Premium noise-cancelling headphones")
                .price(new BigDecimal("129.99"))
                .category("Electronics")
                .stock(200)
                .imageUrl("https://images.example.com/headphones.jpg")
                .active(true)
                .createdAt(sampleProduct.getCreatedAt())
                .updatedAt(Instant.now())
                .build();

        when(productService.updateProduct(eq(1L), any(ProductDTO.UpdateRequest.class))).thenReturn(updated);

        mockMvc.perform(put("/api/products/1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.price", is(129.99)));
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    @DisplayName("DELETE /api/products/{id} - should delete product")
    void deleteProduct_shouldReturn200() throws Exception {
        doNothing().when(productService).deleteProduct(1L);

        mockMvc.perform(delete("/api/products/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)));
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    @DisplayName("DELETE /api/products/{id} - should return 404 when product not found")
    void deleteProduct_shouldReturn404_whenNotFound() throws Exception {
        doThrow(new ResourceNotFoundException("Product", "id", 999L)).when(productService).deleteProduct(999L);

        mockMvc.perform(delete("/api/products/999"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success", is(false)));
    }
}
