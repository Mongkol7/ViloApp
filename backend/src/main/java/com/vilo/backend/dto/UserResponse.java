package com.vilo.backend.dto;

import com.vilo.backend.entity.Role;
import com.vilo.backend.entity.User;

import java.time.Instant;
import java.util.Set;

public class UserResponse {

    private Long id;
    private String username;
    private String email;
    private String displayName;
    private String bio;
    private String avatarUrl;
    private Boolean isVerified;
    private Boolean isFollowing;
    private Boolean followsYou;
    private Set<Role> roles;
    private int followersCount;
    private int followingCount;
    private Instant createdAt;

    public UserResponse() {
    }

    public UserResponse(Long id, String username, String email, String displayName, String bio,
                        String avatarUrl, Boolean isVerified, Set<Role> roles,
                        int followersCount, int followingCount, Instant createdAt) {
        this(id, username, email, displayName, bio, avatarUrl, isVerified, false, false, roles, followersCount, followingCount, createdAt);
    }

    public UserResponse(Long id, String username, String email, String displayName, String bio,
                        String avatarUrl, Boolean isVerified, Boolean isFollowing, Set<Role> roles,
                        int followersCount, int followingCount, Instant createdAt) {
        this(id, username, email, displayName, bio, avatarUrl, isVerified, isFollowing, false, roles, followersCount, followingCount, createdAt);
    }

    public UserResponse(Long id, String username, String email, String displayName, String bio,
                        String avatarUrl, Boolean isVerified, Boolean isFollowing, Boolean followsYou, Set<Role> roles,
                        int followersCount, int followingCount, Instant createdAt) {
        this.id = id;
        this.username = username;
        this.email = email;
        this.displayName = displayName;
        this.bio = bio;
        this.avatarUrl = avatarUrl;
        this.isVerified = isVerified;
        this.isFollowing = isFollowing;
        this.followsYou = followsYou;
        this.roles = roles;
        this.followersCount = followersCount;
        this.followingCount = followingCount;
        this.createdAt = createdAt;
    }

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

    public static UserResponse fromEntitySummary(User user) {
        int followers = 0;
        int following = 0;
        try {
            if (user.getFollowers() != null) followers = user.getFollowers().size();
            if (user.getFollowing() != null) following = user.getFollowing().size();
        } catch (Exception ignored) {}

        return UserResponse.builder()
                .id(user.getId())
                .username(user.getUsername())
                .email(user.getEmail())
                .displayName(user.getDisplayName() != null ? user.getDisplayName() : user.getUsername())
                .bio(user.getBio())
                .avatarUrl(user.getAvatarUrl())
                .isVerified(Boolean.TRUE.equals(user.getIsVerified()))
                .roles(user.getRoles())
                .followersCount(followers)
                .followingCount(following)
                .createdAt(user.getCreatedAt())
                .build();
    }

    public static Builder builder() {
        return new Builder();
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getDisplayName() {
        return displayName;
    }

    public void setDisplayName(String displayName) {
        this.displayName = displayName;
    }

    public String getBio() {
        return bio;
    }

    public void setBio(String bio) {
        this.bio = bio;
    }

    public String getAvatarUrl() {
        return avatarUrl;
    }

    public void setAvatarUrl(String avatarUrl) {
        this.avatarUrl = avatarUrl;
    }

    public Boolean getIsVerified() {
        return isVerified;
    }

    public void setIsVerified(Boolean isVerified) {
        this.isVerified = isVerified;
    }

    public Boolean getIsFollowing() {
        return isFollowing;
    }

    public void setIsFollowing(Boolean isFollowing) {
        this.isFollowing = isFollowing;
    }

    public Boolean getFollowsYou() {
        return followsYou != null ? followsYou : false;
    }

    public void setFollowsYou(Boolean followsYou) {
        this.followsYou = followsYou;
    }

    public Boolean getIsFriend() {
        return Boolean.TRUE.equals(isFollowing) && Boolean.TRUE.equals(followsYou);
    }

    public Set<Role> getRoles() {
        return roles;
    }

    public void setRoles(Set<Role> roles) {
        this.roles = roles;
    }

    public int getFollowersCount() {
        return followersCount;
    }

    public void setFollowersCount(int followersCount) {
        this.followersCount = followersCount;
    }

    public int getFollowingCount() {
        return followingCount;
    }

    public void setFollowingCount(int followingCount) {
        this.followingCount = followingCount;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }

    public static class Builder {
        private Long id;
        private String username;
        private String email;
        private String displayName;
        private String bio;
        private String avatarUrl;
        private Boolean isVerified = false;
        private Boolean isFollowing = false;
        private Boolean followsYou = false;
        private Set<Role> roles;
        private int followersCount;
        private int followingCount;
        private Instant createdAt;

        public Builder id(Long id) {
            this.id = id;
            return this;
        }

        public Builder username(String username) {
            this.username = username;
            return this;
        }

        public Builder email(String email) {
            this.email = email;
            return this;
        }

        public Builder displayName(String displayName) {
            this.displayName = displayName;
            return this;
        }

        public Builder bio(String bio) {
            this.bio = bio;
            return this;
        }

        public Builder avatarUrl(String avatarUrl) {
            this.avatarUrl = avatarUrl;
            return this;
        }

        public Builder isVerified(Boolean isVerified) {
            this.isVerified = isVerified;
            return this;
        }

        public Builder isFollowing(Boolean isFollowing) {
            this.isFollowing = isFollowing;
            return this;
        }

        public Builder followsYou(Boolean followsYou) {
            this.followsYou = followsYou;
            return this;
        }

        public Builder roles(Set<Role> roles) {
            this.roles = roles;
            return this;
        }

        public Builder followersCount(int followersCount) {
            this.followersCount = followersCount;
            return this;
        }

        public Builder followingCount(int followingCount) {
            this.followingCount = followingCount;
            return this;
        }

        public Builder createdAt(Instant createdAt) {
            this.createdAt = createdAt;
            return this;
        }

        public UserResponse build() {
            return new UserResponse(id, username, email, displayName, bio, avatarUrl, isVerified, isFollowing, followsYou, roles, followersCount, followingCount, createdAt);
        }
    }
}
