package com.myapp.api.repository;

import com.myapp.api.entity.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@Testcontainers
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
class UserRepositoryTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine")
            .withDatabaseName("testdb")
            .withUsername("test")
            .withPassword("test");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
        registry.add("spring.datasource.driver-class-name", () -> "org.postgresql.Driver");
        registry.add("spring.flyway.enabled", () -> "true");
    }

    @Autowired
    private UserRepository userRepository;

    private User testUser;

    @BeforeEach
    void setUp() {
        userRepository.deleteAll();
        testUser = User.builder()
                .username("testuser")
                .email("test@example.com")
                .firstName("Test")
                .lastName("User")
                .role(User.Role.USER)
                .active(true)
                .build();
    }

    @Test
    @DisplayName("Should save and find user by ID")
    void saveAndFindById() {
        User saved = userRepository.save(testUser);

        Optional<User> found = userRepository.findById(saved.getId());

        assertThat(found).isPresent();
        assertThat(found.get().getUsername()).isEqualTo("testuser");
        assertThat(found.get().getCreatedAt()).isNotNull();
        assertThat(found.get().getUpdatedAt()).isNotNull();
    }

    @Test
    @DisplayName("Should find user by username")
    void findByUsername() {
        userRepository.save(testUser);

        Optional<User> found = userRepository.findByUsername("testuser");

        assertThat(found).isPresent();
        assertThat(found.get().getEmail()).isEqualTo("test@example.com");
    }

    @Test
    @DisplayName("Should find user by email")
    void findByEmail() {
        userRepository.save(testUser);

        Optional<User> found = userRepository.findByEmail("test@example.com");

        assertThat(found).isPresent();
        assertThat(found.get().getUsername()).isEqualTo("testuser");
    }

    @Test
    @DisplayName("Should check username existence")
    void existsByUsername() {
        userRepository.save(testUser);

        assertThat(userRepository.existsByUsername("testuser")).isTrue();
        assertThat(userRepository.existsByUsername("nonexistent")).isFalse();
    }

    @Test
    @DisplayName("Should check email existence")
    void existsByEmail() {
        userRepository.save(testUser);

        assertThat(userRepository.existsByEmail("test@example.com")).isTrue();
        assertThat(userRepository.existsByEmail("nope@example.com")).isFalse();
    }

    @Test
    @DisplayName("Should find active users with pagination")
    void findByActiveTrue() {
        userRepository.save(testUser);

        User inactiveUser = User.builder()
                .username("inactive")
                .email("inactive@example.com")
                .firstName("Inactive")
                .lastName("User")
                .role(User.Role.USER)
                .active(false)
                .build();
        userRepository.save(inactiveUser);

        Page<User> activeUsers = userRepository.findByActiveTrue(PageRequest.of(0, 10));

        assertThat(activeUsers.getContent()).hasSize(1);
        assertThat(activeUsers.getContent().get(0).getUsername()).isEqualTo("testuser");
    }

    @Test
    @DisplayName("Should find users by role")
    void findByRole() {
        userRepository.save(testUser);

        User admin = User.builder()
                .username("admin")
                .email("admin@example.com")
                .firstName("Admin")
                .lastName("User")
                .role(User.Role.ADMIN)
                .active(true)
                .build();
        userRepository.save(admin);

        Page<User> admins = userRepository.findByRole(User.Role.ADMIN, PageRequest.of(0, 10));

        assertThat(admins.getContent()).hasSize(1);
        assertThat(admins.getContent().get(0).getRole()).isEqualTo(User.Role.ADMIN);
    }

    @Test
    @DisplayName("Should delete user")
    void deleteUser() {
        User saved = userRepository.save(testUser);

        userRepository.deleteById(saved.getId());

        assertThat(userRepository.findById(saved.getId())).isEmpty();
    }
}
