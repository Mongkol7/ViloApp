package com.vilo.backend;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vilo.backend.dto.SendMessageRequest;
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
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
class ChatControllerTest {

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
    void testGetConversations() throws Exception {
        mockMvc.perform(get("/api/v1/chats/conversations")
                        .with(user(kimliza)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data").isArray());
    }

    @Test
    void testGetMessagesWithUser() throws Exception {
        mockMvc.perform(get("/api/v1/chats/" + mongkol.getId() + "/messages")
                        .with(user(kimliza)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.content").isArray());
    }

    @Test
    void testSendMessage() throws Exception {
        SendMessageRequest request = SendMessageRequest.builder()
                .content("Hello from Spring Boot integration test!")
                .build();

        mockMvc.perform(post("/api/v1/chats/" + mongkol.getId() + "/messages")
                        .with(user(kimliza))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.content").value("Hello from Spring Boot integration test!"))
                .andExpect(jsonPath("$.data.senderUsername").value("kimliza"))
                .andExpect(jsonPath("$.data.recipientUsername").value("mongkol"));
    }
}
