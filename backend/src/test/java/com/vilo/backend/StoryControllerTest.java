package com.vilo.backend;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vilo.backend.dto.CreateStoryRequest;
import com.vilo.backend.entity.User;
import com.vilo.backend.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
class StoryControllerTest {

    @Autowired
    private WebApplicationContext context;

    @Autowired
    private UserRepository userRepository;

    private final ObjectMapper objectMapper = new ObjectMapper();

    private MockMvc mockMvc;
    private User kimliza;
    private User mongkol;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.webAppContextSetup(context)
                .apply(springSecurity())
                .build();

        kimliza = userRepository.findByUsername("kimliza").orElseThrow();
        mongkol = userRepository.findByUsername("mongkol").orElseThrow();
    }

    @Test
    void testGetActiveStories() throws Exception {
        mockMvc.perform(get("/api/v1/stories/active")
                        .with(user(kimliza)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data").isArray());
    }

    @Test
    void testCreateStoryAndRecordView() throws Exception {
        CreateStoryRequest request = CreateStoryRequest.builder()
                .message("Integration test story thought!")
                .musicTitle("Test Song")
                .musicArtist("Test Artist")
                .backgroundGradient("sunset")
                .expiresInHours(24)
                .build();

        String responseStr = mockMvc.perform(post("/api/v1/stories")
                        .with(user(kimliza))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.message").value("Integration test story thought!"))
                .andExpect(jsonPath("$.data.username").value("kimliza"))
                .andReturn().getResponse().getContentAsString();

        Long storyId = objectMapper.readTree(responseStr).path("data").path("id").asLong();

        // Record view from mongkol
        mockMvc.perform(post("/api/v1/stories/" + storyId + "/view")
                        .with(user(mongkol)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.viewCount").isNumber());

        // View viewers list
        mockMvc.perform(get("/api/v1/stories/" + storyId + "/viewers")
                        .with(user(kimliza)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data").isArray());

        // Delete story
        mockMvc.perform(delete("/api/v1/stories/" + storyId)
                        .with(user(kimliza)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));
    }
}
