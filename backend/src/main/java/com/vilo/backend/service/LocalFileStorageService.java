package com.vilo.backend.service;

import com.vilo.backend.exception.BadRequestException;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.UUID;

@Service
public class LocalFileStorageService implements FileStorageService {

    private static final Logger log = LoggerFactory.getLogger(LocalFileStorageService.class);

    @Value("${app.storage.upload-dir:./uploads}")
    private String uploadDir;

    private Path rootStoragePath;

    @PostConstruct
    public void init() {
        try {
            this.rootStoragePath = Paths.get(uploadDir).toAbsolutePath().normalize();
            Files.createDirectories(this.rootStoragePath);
            Files.createDirectories(this.rootStoragePath.resolve("videos"));
            Files.createDirectories(this.rootStoragePath.resolve("photos"));
            String thumbDir = getThumbnailDirectoryName();
            Files.createDirectories(this.rootStoragePath.resolve(thumbDir));
            log.info("Local storage directories initialized at: {} with thumbnail subfolder: {}", this.rootStoragePath, thumbDir);
        } catch (IOException e) {
            log.error("Failed to initialize upload directory: {}", e.getMessage(), e);
            throw new RuntimeException("Could not initialize local storage folder", e);
        }
    }

    @Override
    public String getThumbnailDirectoryName() {
        if (this.rootStoragePath != null) {
            if (Files.exists(this.rootStoragePath.resolve("thumnail"))) {
                return "thumnail";
            }
            if (Files.exists(this.rootStoragePath.resolve("thumbnail"))) {
                return "thumbnail";
            }
            if (Files.exists(this.rootStoragePath.resolve("thumbnails"))) {
                return "thumbnails";
            }
        }
        if (Files.exists(Paths.get("uploads", "thumnail")) || Files.exists(Paths.get("backend", "uploads", "thumnail"))) {
            return "thumnail";
        }
        if (Files.exists(Paths.get("uploads", "thumbnail")) || Files.exists(Paths.get("backend", "uploads", "thumbnail"))) {
            return "thumbnail";
        }
        return "thumbnails";
    }

    @Override
    public String storeFile(MultipartFile file, String subDirectory) {
        if (file == null || file.isEmpty()) {
            throw new BadRequestException("Uploaded file cannot be empty");
        }

        String rawOriginalFilename = file.getOriginalFilename();
        String originalFilename = rawOriginalFilename != null ? StringUtils.cleanPath(rawOriginalFilename) : "file";
        String extension = "";
        int dotIndex = originalFilename.lastIndexOf('.');
        if (dotIndex >= 0) {
            extension = originalFilename.substring(dotIndex);
        }

        String uniqueFilename = UUID.randomUUID().toString() + extension;

        String resolvedSubDir = subDirectory;
        if ("thumbnails".equalsIgnoreCase(subDirectory) || "thumnail".equalsIgnoreCase(subDirectory) || "thumbnail".equalsIgnoreCase(subDirectory)) {
            resolvedSubDir = getThumbnailDirectoryName();
        }

        try {
            Path targetDirectory = this.rootStoragePath.resolve(resolvedSubDir).normalize();
            if (!Files.exists(targetDirectory)) {
                Files.createDirectories(targetDirectory);
            }

            Path targetPath = targetDirectory.resolve(uniqueFilename).normalize();

            // Guard against path traversal
            if (!targetPath.startsWith(this.rootStoragePath)) {
                throw new BadRequestException("Invalid path sequence in filename");
            }

            Files.copy(file.getInputStream(), targetPath, StandardCopyOption.REPLACE_EXISTING);
            log.debug("Stored file {} to {}", uniqueFilename, targetPath);

            return "/uploads/" + resolvedSubDir + "/" + uniqueFilename;
        } catch (IOException e) {
            log.error("Failed to store file {}: {}", uniqueFilename, e.getMessage(), e);
            throw new BadRequestException("Failed to store file: " + e.getMessage());
        }
    }

    @Override
    public boolean deleteFile(String fileUrl) {
        if (!StringUtils.hasText(fileUrl)) {
            return false;
        }

        try {
            String relativePath = fileUrl;
            int uploadsIdx = fileUrl.indexOf("/uploads/");
            if (uploadsIdx >= 0) {
                relativePath = fileUrl.substring(uploadsIdx + "/uploads/".length());
            }

            Path filePath = this.rootStoragePath.resolve(relativePath).normalize();

            if (!filePath.startsWith(this.rootStoragePath)) {
                log.warn("Attempted path traversal deletion with path: {}", fileUrl);
                return false;
            }

            return Files.deleteIfExists(filePath);
        } catch (IOException e) {
            log.error("Could not delete file {}: {}", fileUrl, e.getMessage(), e);
            return false;
        }
    }
}
