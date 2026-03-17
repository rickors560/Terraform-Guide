package com.myapp.api.repository;

import com.myapp.api.entity.Product;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ProductRepository extends JpaRepository<Product, Long> {

    Page<Product> findByActiveTrue(Pageable pageable);

    Page<Product> findByCategory(String category, Pageable pageable);

    Page<Product> findByCategoryAndActiveTrue(String category, Pageable pageable);

    List<Product> findByNameContainingIgnoreCase(String name);

    boolean existsByName(String name);
}
