package com.myapp.api.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.Instant;

public final class ProductDTO {

    private ProductDTO() {
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class CreateRequest {

        @NotBlank(message = "Product name is required")
        @Size(max = 150, message = "Product name must not exceed 150 characters")
        private String name;

        @Size(max = 2000, message = "Description must not exceed 2000 characters")
        private String description;

        @NotNull(message = "Price is required")
        @DecimalMin(value = "0.01", message = "Price must be at least 0.01")
        private BigDecimal price;

        @NotBlank(message = "Category is required")
        @Size(max = 50, message = "Category must not exceed 50 characters")
        private String category;

        @Min(value = 0, message = "Stock cannot be negative")
        private Integer stock;

        @Size(max = 500, message = "Image URL must not exceed 500 characters")
        private String imageUrl;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class UpdateRequest {

        @Size(max = 150, message = "Product name must not exceed 150 characters")
        private String name;

        @Size(max = 2000, message = "Description must not exceed 2000 characters")
        private String description;

        @DecimalMin(value = "0.01", message = "Price must be at least 0.01")
        private BigDecimal price;

        @Size(max = 50, message = "Category must not exceed 50 characters")
        private String category;

        @Min(value = 0, message = "Stock cannot be negative")
        private Integer stock;

        @Size(max = 500, message = "Image URL must not exceed 500 characters")
        private String imageUrl;

        private Boolean active;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class Response {
        private Long id;
        private String name;
        private String description;
        private BigDecimal price;
        private String category;
        private Integer stock;
        private String imageUrl;
        private Boolean active;
        private Instant createdAt;
        private Instant updatedAt;
    }
}
