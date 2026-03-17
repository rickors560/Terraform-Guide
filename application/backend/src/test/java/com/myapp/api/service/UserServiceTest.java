package com.myapp.api.service;

import com.myapp.api.dto.UserDTO;
import com.myapp.api.entity.User;
import com.myapp.api.exception.BadRequestException;
import com.myapp.api.exception.ResourceNotFoundException;
import com.myapp.api.mapper.UserMapper;
import com.myapp.api.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private UserMapper userMapper;

    @InjectMocks
    private UserService userService;

    private User sampleUser;
    private UserDTO.Response sampleResponse;
    private UserDTO.CreateRequest createRequest;
    private UserDTO.UpdateRequest updateRequest;

    @BeforeEach
    void setUp() {
        Instant now = Instant.now();

        sampleUser = User.builder()
                .id(1L)
                .username("jdoe")
                .email("john.doe@example.com")
                .firstName("John")
                .lastName("Doe")
                .role(User.Role.USER)
                .active(true)
                .createdAt(now)
                .updatedAt(now)
                .build();

        sampleResponse = UserDTO.Response.builder()
                .id(1L)
                .username("jdoe")
                .email("john.doe@example.com")
                .firstName("John")
                .lastName("Doe")
                .role(User.Role.USER)
                .active(true)
                .createdAt(now)
                .updatedAt(now)
                .build();

        createRequest = UserDTO.CreateRequest.builder()
                .username("jdoe")
                .email("john.doe@example.com")
                .firstName("John")
                .lastName("Doe")
                .role(User.Role.USER)
                .build();

        updateRequest = UserDTO.UpdateRequest.builder()
                .email("john.updated@example.com")
                .firstName("Johnny")
                .build();
    }

    @Test
    @DisplayName("getAllUsers - should return paginated users")
    void getAllUsers_shouldReturnPage() {
        Pageable pageable = PageRequest.of(0, 20);
        Page<User> page = new PageImpl<>(List.of(sampleUser));
        when(userRepository.findAll(pageable)).thenReturn(page);
        when(userMapper.toResponse(sampleUser)).thenReturn(sampleResponse);

        Page<UserDTO.Response> result = userService.getAllUsers(pageable);

        assertThat(result.getContent()).hasSize(1);
        assertThat(result.getContent().get(0).getUsername()).isEqualTo("jdoe");
        verify(userRepository).findAll(pageable);
    }

    @Test
    @DisplayName("getUserById - should return user when found")
    void getUserById_shouldReturnUser() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(sampleUser));
        when(userMapper.toResponse(sampleUser)).thenReturn(sampleResponse);

        UserDTO.Response result = userService.getUserById(1L);

        assertThat(result.getUsername()).isEqualTo("jdoe");
        assertThat(result.getEmail()).isEqualTo("john.doe@example.com");
    }

    @Test
    @DisplayName("getUserById - should throw ResourceNotFoundException when not found")
    void getUserById_shouldThrowWhenNotFound() {
        when(userRepository.findById(999L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> userService.getUserById(999L))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("User not found with id: '999'");
    }

    @Test
    @DisplayName("createUser - should create user successfully")
    void createUser_shouldCreate() {
        when(userRepository.existsByUsername("jdoe")).thenReturn(false);
        when(userRepository.existsByEmail("john.doe@example.com")).thenReturn(false);
        when(userMapper.toEntity(createRequest)).thenReturn(sampleUser);
        when(userRepository.save(any(User.class))).thenReturn(sampleUser);
        when(userMapper.toResponse(sampleUser)).thenReturn(sampleResponse);

        UserDTO.Response result = userService.createUser(createRequest);

        assertThat(result.getUsername()).isEqualTo("jdoe");
        verify(userRepository).save(any(User.class));
    }

    @Test
    @DisplayName("createUser - should throw BadRequestException when username taken")
    void createUser_shouldThrowWhenUsernameTaken() {
        when(userRepository.existsByUsername("jdoe")).thenReturn(true);

        assertThatThrownBy(() -> userService.createUser(createRequest))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("already taken");

        verify(userRepository, never()).save(any());
    }

    @Test
    @DisplayName("createUser - should throw BadRequestException when email in use")
    void createUser_shouldThrowWhenEmailInUse() {
        when(userRepository.existsByUsername("jdoe")).thenReturn(false);
        when(userRepository.existsByEmail("john.doe@example.com")).thenReturn(true);

        assertThatThrownBy(() -> userService.createUser(createRequest))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("already in use");

        verify(userRepository, never()).save(any());
    }

    @Test
    @DisplayName("updateUser - should update user successfully")
    void updateUser_shouldUpdate() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(sampleUser));
        when(userRepository.existsByEmail("john.updated@example.com")).thenReturn(false);
        when(userRepository.save(any(User.class))).thenReturn(sampleUser);
        when(userMapper.toResponse(any(User.class))).thenReturn(sampleResponse);

        UserDTO.Response result = userService.updateUser(1L, updateRequest);

        assertThat(result).isNotNull();
        verify(userMapper).updateEntity(updateRequest, sampleUser);
        verify(userRepository).save(sampleUser);
    }

    @Test
    @DisplayName("updateUser - should throw ResourceNotFoundException when not found")
    void updateUser_shouldThrowWhenNotFound() {
        when(userRepository.findById(999L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> userService.updateUser(999L, updateRequest))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    @DisplayName("deleteUser - should delete user successfully")
    void deleteUser_shouldDelete() {
        when(userRepository.existsById(1L)).thenReturn(true);

        userService.deleteUser(1L);

        verify(userRepository).deleteById(1L);
    }

    @Test
    @DisplayName("deleteUser - should throw ResourceNotFoundException when not found")
    void deleteUser_shouldThrowWhenNotFound() {
        when(userRepository.existsById(999L)).thenReturn(false);

        assertThatThrownBy(() -> userService.deleteUser(999L))
                .isInstanceOf(ResourceNotFoundException.class);
    }
}
