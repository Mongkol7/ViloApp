package com.vilo.backend.service;

import com.vilo.backend.dto.*;
import com.vilo.backend.entity.RefreshToken;
import com.vilo.backend.entity.Role;
import com.vilo.backend.entity.User;
import com.vilo.backend.exception.BadRequestException;
import com.vilo.backend.repository.RefreshTokenRepository;
import com.vilo.backend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;

    @Value("${application.security.jwt.refresh-token.expiration}")
    private long refreshExpiration;

    public AuthService(UserRepository userRepository,
                       RefreshTokenRepository refreshTokenRepository,
                       PasswordEncoder passwordEncoder,
                       JwtService jwtService,
                       AuthenticationManager authenticationManager) {
        this.userRepository = userRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.authenticationManager = authenticationManager;
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByUsername(request.getUsername())) {
            throw new BadRequestException("Username '" + request.getUsername() + "' is already taken");
        }
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new BadRequestException("Email '" + request.getEmail() + "' is already registered");
        }

        String defaultAvatar = "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=500";
        User user = User.builder()
                .username(request.getUsername().trim().toLowerCase())
                .email(request.getEmail().trim().toLowerCase())
                .password(passwordEncoder.encode(request.getPassword()))
                .displayName(request.getDisplayName() != null && !request.getDisplayName().isBlank() 
                        ? request.getDisplayName().trim() 
                        : request.getUsername().trim())
                .avatarUrl(defaultAvatar)
                .roles(Set.of(Role.ROLE_USER))
                .isVerified(false)
                .build();

        User savedUser = userRepository.save(user);

        return createAuthResponse(savedUser);
    }

    @Transactional
    public AuthResponse login(LoginRequest request) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        request.getUsernameOrEmail().trim().toLowerCase(),
                        request.getPassword()
                )
        );

        User user = userRepository.findByUsernameOrEmail(
                request.getUsernameOrEmail().trim().toLowerCase(),
                request.getUsernameOrEmail().trim().toLowerCase()
        ).orElseThrow(() -> new BadRequestException("User not found"));

        return createAuthResponse(user);
    }

    @Transactional
    public AuthResponse refreshToken(RefreshTokenRequest request) {
        RefreshToken refreshToken = refreshTokenRepository.findByToken(request.getRefreshToken())
                .orElseThrow(() -> new BadRequestException("Invalid refresh token"));

        if (refreshToken.isRevoked() || refreshToken.getExpiryDate().isBefore(Instant.now())) {
            refreshTokenRepository.delete(refreshToken);
            throw new BadRequestException("Refresh token is expired or revoked. Please log in again.");
        }

        User user = refreshToken.getUser();
        String newAccessToken = jwtService.generateToken(buildExtraClaims(user), user);

        return AuthResponse.builder()
                .accessToken(newAccessToken)
                .refreshToken(refreshToken.getToken())
                .tokenType("Bearer")
                .expiresIn(jwtService.getExpiration())
                .user(UserResponse.fromEntity(user))
                .build();
    }

    @Transactional
    public void logout(String refreshTokenString) {
        if (refreshTokenString != null && !refreshTokenString.isBlank()) {
            refreshTokenRepository.findByToken(refreshTokenString)
                    .ifPresent(refreshTokenRepository::delete);
        }
    }

    private AuthResponse createAuthResponse(User user) {
        Map<String, Object> extraClaims = buildExtraClaims(user);
        String accessToken = jwtService.generateToken(extraClaims, user);
        String refreshTokenString = jwtService.generateRefreshToken(user);

        RefreshToken refreshToken = RefreshToken.builder()
                .user(user)
                .token(refreshTokenString)
                .expiryDate(Instant.now().plusMillis(refreshExpiration))
                .revoked(false)
                .build();

        refreshTokenRepository.save(refreshToken);

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshTokenString)
                .tokenType("Bearer")
                .expiresIn(jwtService.getExpiration())
                .user(UserResponse.fromEntity(user))
                .build();
    }

    private Map<String, Object> buildExtraClaims(User user) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("userId", user.getId());
        claims.put("email", user.getEmail());
        claims.put("roles", user.getRoles().stream().map(Enum::name).toList());
        return claims;
    }
}
