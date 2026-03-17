package com.myapp.api.mapper;

import com.myapp.api.dto.UserDTO;
import com.myapp.api.entity.User;
import org.mapstruct.BeanMapping;
import org.mapstruct.Mapper;
import org.mapstruct.MappingTarget;
import org.mapstruct.NullValuePropertyMappingStrategy;

import java.util.List;

@Mapper(componentModel = "spring")
public interface UserMapper {

    UserDTO.Response toResponse(User user);

    List<UserDTO.Response> toResponseList(List<User> users);

    User toEntity(UserDTO.CreateRequest request);

    @BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
    void updateEntity(UserDTO.UpdateRequest request, @MappingTarget User user);
}
