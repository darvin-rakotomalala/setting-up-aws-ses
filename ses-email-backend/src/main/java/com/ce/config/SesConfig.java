package com.ce.config;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.http.urlconnection.UrlConnectionHttpClient;
import software.amazon.awssdk.services.sesv2.SesV2Client;

@Configuration
@EnableConfigurationProperties(SesProperties.class)
public class SesConfig {

    /**
     * Region and credentials come from the Lambda environment (AWS_REGION and the
     * execution role), so no keys exist anywhere in code or config.
     */
    @Bean(destroyMethod = "close")
    public SesV2Client sesV2Client() {
        return SesV2Client.builder()
                .httpClientBuilder(UrlConnectionHttpClient.builder())
                .build();
    }
}
