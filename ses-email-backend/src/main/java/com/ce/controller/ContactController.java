package com.ce.controller;

import com.ce.model.ContactMessage;
import com.ce.model.ContactResponse;
import com.ce.service.SesEmailService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api")
public class ContactController {

    private final SesEmailService emailService;

    public ContactController(SesEmailService emailService) {
        this.emailService = emailService;
    }

    /** POST /api/contact - validates the body, then emails the site owner through SES. */
    @PostMapping("/contact")
    public ResponseEntity<ContactResponse> sendContactMessage(@Valid @RequestBody ContactMessage message) {
        String messageId = emailService.send(message);
        return ResponseEntity.ok(ContactResponse.sent(messageId));
    }

    /** GET /api/health - cheap liveness check that does not touch SES. */
    @GetMapping("/health")
    public Map<String, String> health() {
        return Map.of("Status", "UP");
    }
}
