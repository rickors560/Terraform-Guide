package com.myapp.api.controller;

import com.myapp.api.dto.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.Map;

@RestController
@RequestMapping("/api/health")
@Tag(name = "Health", description = "Health check endpoints")
public class HealthController {

    @Value("${app.version:1.0.0}")
    private String appVersion;

    @GetMapping
    @Operation(summary = "Health check", description = "Returns application health status, version, and timestamp")
    public ResponseEntity<ApiResponse<Map<String, Object>>> healthCheck() {
        Map<String, Object> health = Map.of(
                "status", "UP",
                "version", appVersion,
                "timestamp", Instant.now().toString()
        );
        return ResponseEntity.ok(ApiResponse.ok("Application is healthy", health));
    }
}
