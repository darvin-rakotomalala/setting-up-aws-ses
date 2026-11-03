package com.ce.config;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

/**
 * Bound from {@code app.ses.*}; fail fast at startup if the mail setup is incomplete.
 */
@Validated
@ConfigurationProperties(prefix = "app.ses")
public record SesProperties(
        @NotBlank @Email String senderEmail,
        @NotBlank @Email String recipientEmail,
        String configurationSet) {
}
