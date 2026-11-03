package com.ce.service;

import com.ce.config.SesProperties;
import com.ce.model.ContactMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.sesv2.SesV2Client;
import software.amazon.awssdk.services.sesv2.model.Body;
import software.amazon.awssdk.services.sesv2.model.Content;
import software.amazon.awssdk.services.sesv2.model.Destination;
import software.amazon.awssdk.services.sesv2.model.EmailContent;
import software.amazon.awssdk.services.sesv2.model.Message;
import software.amazon.awssdk.services.sesv2.model.SendEmailRequest;
import software.amazon.awssdk.services.sesv2.model.SendEmailResponse;

/**
 * Java port of the Python Lambda:
 *
 * <pre>
 * client.send_email(Source=from, Destination={'ToAddresses':[to]},
 *                   Message={'Subject':{'Data':subject}, 'Body':{'Text':{'Data':body}}})
 * </pre>
 * <p>
 * Differences (all deliberate):
 * <ul>
 *   <li>From/To are fixed by configuration; the visitor's address goes in Reply-To.</li>
 *   <li>Uses the SES v2 API and the Terraform-managed configuration set.</li>
 *   <li>Explicit UTF-8, subject sanitised against header injection.</li>
 *   <li>Returns the SES message id instead of serialising the whole SDK response.</li>
 * </ul>
 */
@Service
public class SesEmailService {

    private static final Logger log = LoggerFactory.getLogger(SesEmailService.class);
    private static final String CHARSET = "UTF-8";
    private static final String SUBJECT_PREFIX = "[Contact Form] ";

    private final SesV2Client ses;
    private final SesProperties properties;

    public SesEmailService(SesV2Client ses, SesProperties properties) {
        this.ses = ses;
        this.properties = properties;
    }

    /**
     * @return the SES message id
     */
    public String send(ContactMessage message) {
        SendEmailRequest request = SendEmailRequest.builder()
                .fromEmailAddress(properties.senderEmail())
                .destination(Destination.builder().toAddresses(properties.recipientEmail()).build())
                .replyToAddresses(message.senderEmail())
                .configurationSetName(blankToNull(properties.configurationSet()))
                .content(EmailContent.builder()
                        .simple(Message.builder()
                                .subject(utf8(SUBJECT_PREFIX + stripLineBreaks(message.senderSubject())))
                                .body(Body.builder().text(utf8(buildBody(message))).build())
                                .build())
                        .build())
                .build();

        SendEmailResponse response = ses.sendEmail(request);

        // Never log names, addresses or message text (PII); the message id is enough to trace it.
        log.info("Contact email sent, sesMessageId={}", response.messageId());
        return response.messageId();
    }

    private static String buildBody(ContactMessage m) {
        return """
                You received a new message from the contact form.
                
                Name:    %s
                Email:   %s
                Subject: %s
                
                Message:
                %s
                """.formatted(
                stripLineBreaks(m.senderName()),
                m.senderEmail(),
                stripLineBreaks(m.senderSubject()),
                m.senderMessage());
    }

    private static Content utf8(String data) {
        return Content.builder().data(data).charset(CHARSET).build();
    }

    private static String stripLineBreaks(String value) {
        return value.replaceAll("[\\r\\n]+", " ").trim();
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value;
    }
}
