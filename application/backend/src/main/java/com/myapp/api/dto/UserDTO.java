package com.myapp.api.dto;

import com.myapp.api.entity.User;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

public final class UserDTO {

    private UserDTO() {
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class CreateRequest {

        @NotBlank(message = "Username is required")
        @Size(min = 3, max = 50, message = "Username must be between 3 and 50 characters")
        private String username;

        @NotBlank(message = "Email is required")
        @Email(message = "Email must be valid")
        @Size(max = 100, message = "Email must not exceed 100 characters")
        private String email;

        @NotBlank(message = "First name is required")
        @Size(max = 50, message = "First name must not exceed 50 characters")
        private String firstName;

        @NotBlank(message = "Last name is required")
        @Size(max = 50, message = "Last name must not exceed 50 characters")
        private String lastName;

        private User.Role role;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class UpdateRequest {

        @Email(message = "Email must be valid")
        @Size(max = 100, message = "Email must not exceed 100 characters")
        private String email;

        @Size(max = 50, message = "First name must not exceed 50 characters")
        private String firstName;

        @Size(max = 50, message = "Last name must not exceed 50 characters")
        private String lastName;

        private User.Role role;

        private Boolean active;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class Response {
        private Long id;
        private String username;
        private String email;
        private String firstName;
        private String lastName;
        private User.Role role;
        private Boolean active;
        private Instant createdAt;
        private Instant updatedAt;
    }
}
