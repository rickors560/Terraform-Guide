package com.myapp.api.service;

import com.myapp.api.dto.UserDTO;
import com.myapp.api.entity.User;
import com.myapp.api.exception.BadRequestException;
import com.myapp.api.exception.ResourceNotFoundException;
import com.myapp.api.mapper.UserMapper;
import com.myapp.api.repository.UserRepository;
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
public class UserService {

    private static final Logger log = LoggerFactory.getLogger(UserService.class);

    private final UserRepository userRepository;
    private final UserMapper userMapper;

    public UserService(UserRepository userRepository, UserMapper userMapper) {
        this.userRepository = userRepository;
        this.userMapper = userMapper;
    }

    @Transactional(readOnly = true)
    public Page<UserDTO.Response> getAllUsers(Pageable pageable) {
        log.debug("Fetching all users, page: {}, size: {}", pageable.getPageNumber(), pageable.getPageSize());
        return userRepository.findAll(pageable).map(userMapper::toResponse);
    }

    @Transactional(readOnly = true)
    @Cacheable(value = "users", key = "#id")
    public UserDTO.Response getUserById(Long id) {
        log.debug("Fetching user by id: {}", id);
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", id));
        return userMapper.toResponse(user);
    }

    public UserDTO.Response createUser(UserDTO.CreateRequest request) {
        log.info("Creating user with username: {}", request.getUsername());

        if (userRepository.existsByUsername(request.getUsername())) {
            throw new BadRequestException("Username '" + request.getUsername() + "' is already taken");
        }
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new BadRequestException("Email '" + request.getEmail() + "' is already in use");
        }

        User user = userMapper.toEntity(request);
        if (user.getRole() == null) {
            user.setRole(User.Role.USER);
        }
        user.setActive(true);

        User savedUser = userRepository.save(user);
        log.info("User created with id: {}", savedUser.getId());
        return userMapper.toResponse(savedUser);
    }

    @CacheEvict(value = "users", key = "#id")
    public UserDTO.Response updateUser(Long id, UserDTO.UpdateRequest request) {
        log.info("Updating user with id: {}", id);

        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", id));

        if (request.getEmail() != null && !request.getEmail().equals(user.getEmail())) {
            if (userRepository.existsByEmail(request.getEmail())) {
                throw new BadRequestException("Email '" + request.getEmail() + "' is already in use");
            }
        }

        userMapper.updateEntity(request, user);
        User updatedUser = userRepository.save(user);
        log.info("User updated with id: {}", updatedUser.getId());
        return userMapper.toResponse(updatedUser);
    }

    @CacheEvict(value = "users", key = "#id")
    public void deleteUser(Long id) {
        log.info("Deleting user with id: {}", id);
        if (!userRepository.existsById(id)) {
            throw new ResourceNotFoundException("User", "id", id);
        }
        userRepository.deleteById(id);
        log.info("User deleted with id: {}", id);
    }
}
