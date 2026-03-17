package com.myapp.api;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

@SpringBootTest
@ActiveProfiles("dev")
class ApplicationTests {

    @Test
    void contextLoads() {
        // Verifies that the Spring application context starts up successfully
    }
}
