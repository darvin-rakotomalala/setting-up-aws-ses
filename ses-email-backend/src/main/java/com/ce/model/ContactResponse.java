package com.ce.model;

public record ContactResponse(String status, String messageId) {

    public static ContactResponse sent(String messageId) {
        return new ContactResponse("sent", messageId);
    }
}
