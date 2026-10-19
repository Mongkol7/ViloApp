package com.vilo.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class CreateCommentRequest {

    @NotBlank(message = "Comment content cannot be blank")
    @Size(max = 1000, message = "Comment cannot exceed 1000 characters")
    private String content;

    private Long parentId;

    public CreateCommentRequest() {
    }

    public CreateCommentRequest(String content, Long parentId) {
        this.content = content;
        this.parentId = parentId;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public Long getParentId() {
        return parentId;
    }

    public void setParentId(Long parentId) {
        this.parentId = parentId;
    }
}
