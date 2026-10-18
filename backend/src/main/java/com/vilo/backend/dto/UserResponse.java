package com.vilo.backend.dto;

import com.vilo.backend.entity.Role;
import com.vilo.backend.entity.User;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.Set;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserResponse {

    private Long id;
    private String username;
    private String email;
    private String displayName;
    private String bio;
    private String avatarUrl;
    private Boolean isVerified;
    private Set<Role> roles;
    private int followersCount;
    private int followingCount;
    private Instant createdAt;

    public static UserResponse fromEntity(User user) {
        return UserResponse.builder()
                .id(user.getId())
                .username(user.getUsername())
                .email(user.getEmail())
                .displayName(user.getDisplayName() != null ? user.getDisplayName() : user.getUsername())
                .bio(user.getBio())
                .avatarUrl(user.getAvatarUrl())
                .isVerified(user.getIsVerified() != null ? user.getIsVerified() : false)
                .roles(user.getRoles())
                .followersCount(user.getFollowers() != null ? user.getFollowers().size() : 0)
                .followingCount(user.getFollowing() != null ? user.getFollowing().size() : 0)
                .createdAt(user.getCreatedAt())
                .build();
    }
}
