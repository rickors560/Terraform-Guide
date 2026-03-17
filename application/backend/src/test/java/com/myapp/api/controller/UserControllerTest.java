package com.myapp.api.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.myapp.api.dto.UserDTO;
import com.myapp.api.entity.User;
import com.myapp.api.exception.ResourceNotFoundException;
import com.myapp.api.security.JwtTokenProvider;
import com.myapp.api.service.UserService;
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

@WebMvcTest(UserController.class)
class UserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private UserService userService;

    @MockBean
    private JwtTokenProvider jwtTokenProvider;

    private UserDTO.Response sampleUser;
    private UserDTO.CreateRequest createRequest;
    private UserDTO.UpdateRequest updateRequest;

    @BeforeEach
    void setUp() {
        Instant now = Instant.now();
        sampleUser = UserDTO.Response.builder()
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
    @DisplayName("GET /api/users - should return paginated users")
    void getAllUsers_shouldReturnPagedResponse() throws Exception {
        Page<UserDTO.Response> page = new PageImpl<>(List.of(sampleUser));
        when(userService.getAllUsers(any(Pageable.class))).thenReturn(page);

        mockMvc.perform(get("/api/users")
                        .param("page", "0")
                        .param("size", "20"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data", hasSize(1)))
                .andExpect(jsonPath("$.data[0].username", is("jdoe")));
    }

    @Test
    @DisplayName("GET /api/users/{id} - should return user by ID")
    void getUserById_shouldReturnUser() throws Exception {
        when(userService.getUserById(1L)).thenReturn(sampleUser);

        mockMvc.perform(get("/api/users/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.username", is("jdoe")))
                .andExpect(jsonPath("$.data.email", is("john.doe@example.com")));
    }

    @Test
    @DisplayName("GET /api/users/{id} - should return 404 when user not found")
    void getUserById_shouldReturn404_whenNotFound() throws Exception {
        when(userService.getUserById(999L))
                .thenThrow(new ResourceNotFoundException("User", "id", 999L));

        mockMvc.perform(get("/api/users/999"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success", is(false)));
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    @DisplayName("POST /api/users - should create user")
    void createUser_shouldReturnCreatedUser() throws Exception {
        when(userService.createUser(any(UserDTO.CreateRequest.class))).thenReturn(sampleUser);

        mockMvc.perform(post("/api/users")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(createRequest)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.username", is("jdoe")));
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    @DisplayName("POST /api/users - should return 400 for invalid request")
    void createUser_shouldReturn400_whenInvalid() throws Exception {
        UserDTO.CreateRequest invalid = UserDTO.CreateRequest.builder()
                .username("")
                .email("not-an-email")
                .firstName("")
                .lastName("")
                .build();

        mockMvc.perform(post("/api/users")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invalid)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    @DisplayName("PUT /api/users/{id} - should update user")
    void updateUser_shouldReturnUpdatedUser() throws Exception {
        UserDTO.Response updated = UserDTO.Response.builder()
                .id(1L)
                .username("jdoe")
                .email("john.updated@example.com")
                .firstName("Johnny")
                .lastName("Doe")
                .role(User.Role.USER)
                .active(true)
                .createdAt(sampleUser.getCreatedAt())
                .updatedAt(Instant.now())
                .build();

        when(userService.updateUser(eq(1L), any(UserDTO.UpdateRequest.class))).thenReturn(updated);

        mockMvc.perform(put("/api/users/1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.firstName", is("Johnny")));
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    @DisplayName("DELETE /api/users/{id} - should delete user")
    void deleteUser_shouldReturn200() throws Exception {
        doNothing().when(userService).deleteUser(1L);

        mockMvc.perform(delete("/api/users/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)));
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    @DisplayName("DELETE /api/users/{id} - should return 404 when user not found")
    void deleteUser_shouldReturn404_whenNotFound() throws Exception {
        doThrow(new ResourceNotFoundException("User", "id", 999L)).when(userService).deleteUser(999L);

        mockMvc.perform(delete("/api/users/999"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success", is(false)));
    }
}
