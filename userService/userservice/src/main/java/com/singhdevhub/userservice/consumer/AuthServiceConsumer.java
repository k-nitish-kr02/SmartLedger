package com.singhdevhub.userservice.consumer;

import com.singhdevhub.userservice.entities.UserInfoDto;
import com.singhdevhub.userservice.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.regex.Pattern;

@Service
@RequiredArgsConstructor
public class AuthServiceConsumer
{

    @Autowired
    private UserService userService;

    // Email validation pattern
    private static final Pattern EMAIL_PATTERN = Pattern.compile(
        "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
    );

    @KafkaListener(topics = "${spring.kafka.topic-json.name}", groupId = "${spring.kafka.consumer.group-id}")
    @Transactional
    public void listen(UserInfoDto eventData) {
        try{
            // Validate required fields
            if (eventData.getUserId() == null || eventData.getUserId().isEmpty()) {
                System.out.println("AuthServiceConsumer: UserId is required, skipping event");
                return;
            }

            // Validate email if provided
            if (eventData.getEmail() != null && !eventData.getEmail().isEmpty()) {
                if (!EMAIL_PATTERN.matcher(eventData.getEmail()).matches()) {
                    System.out.println("AuthServiceConsumer: Invalid email format: " + eventData.getEmail() + ", skipping event");
                    return;
                }
            }

            // Validate phone number if provided (phoneNumber is Long type)
            if (eventData.getPhoneNumber() != null) {
                String phoneNumberStr = eventData.getPhoneNumber().toString();
                // Basic validation: phone number should be at least 10 digits
                if (phoneNumberStr.length() < 10 || phoneNumberStr.length() > 15) {
                    System.out.println("AuthServiceConsumer: Invalid phone number length: " + phoneNumberStr + ", skipping event");
                    return;
                }
            }

            // Create or update user (idempotency is handled by checking if user exists)
            userService.createOrUpdateUser(eventData);
            System.out.println("AuthServiceConsumer: Successfully processed user event for userId: " + eventData.getUserId());
        }catch(Exception ex){
            ex.printStackTrace();
            System.out.println("AuthServiceConsumer: Exception is thrown while consuming kafka event: " + ex.getMessage());
            // In production, consider implementing dead letter queue (DLQ) for failed messages
            throw ex; // Re-throw to enable Kafka retry mechanism
        }
    }

}
