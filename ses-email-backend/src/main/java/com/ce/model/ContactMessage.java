package com.ce.model;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record ContactMessage(

        @NotBlank(message = "senderName is required")
        @Size(max = 100, message = "senderName must be at most 100 characters")
        @Pattern(regexp = "^[^\\r\\n]*$", message = "senderName must not contain line breaks")
        String senderName,

        @NotBlank(message = "senderEmail is required")
        @Email(message = "senderEmail must be a valid email address")
        @Size(max = 254, message = "senderEmail must be at most 254 characters")
        String senderEmail,

        @NotBlank(message = "senderSubject is required")
        @Size(max = 150, message = "senderSubject must be at most 150 characters")
        @Pattern(regexp = "^[^\\r\\n]*$", message = "senderSubject must not contain line breaks")
        String senderSubject,

        @NotBlank(message = "senderMessage is required")
        @Size(max = 5000, message = "senderMessage must be at most 5000 characters")
        String senderMessage) {
}
