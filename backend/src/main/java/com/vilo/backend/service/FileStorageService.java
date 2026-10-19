package com.vilo.backend.service;

import org.springframework.web.multipart.MultipartFile;

public interface FileStorageService {

    /**
     * Stores an uploaded multipart file in the specified subfolder (e.g., "videos", "thumbnails").
     *
     * @param file the uploaded file
     * @param subDirectory subdirectory within the upload root (e.g., "videos", "thumbnails")
     * @return relative public URL path (e.g., "/uploads/videos/abc-123.mp4")
     */
    String storeFile(MultipartFile file, String subDirectory);

    /**
     * Deletes a file given its URL path or filename.
     *
     * @param fileUrl relative or full path/URL of the file to remove
     * @return true if deleted or not present, false if deletion failed
     */
    boolean deleteFile(String fileUrl);

    /**
     * Resolves the actual thumbnail folder name present on disk ("thumbnails", "thumnail", or "thumbnail").
     *
     * @return the resolved thumbnail directory name
     */
    String getThumbnailDirectoryName();
}
