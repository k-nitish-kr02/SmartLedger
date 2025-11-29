package com.expense.service.consumer;

import com.expense.service.dto.ExpenseDto;
import com.expense.service.service.ExpenseService;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@RequiredArgsConstructor
@Service
public class ExpenseConsumer
{

    private ExpenseService expenseService;

    @Autowired
    ExpenseConsumer(ExpenseService expenseService){
        this.expenseService = expenseService;
    }

    @KafkaListener(topics = "${spring.kafka.topic-json.name}", groupId = "${spring.kafka.consumer.group-id}")
    @Transactional
    public void listen(ExpenseDto eventData) {
        try{
            // Handle idempotency: Check if expense with same externalId already exists
            // If externalId is null or empty, generate one or skip duplicate check
            if (eventData.getExternalId() != null && !eventData.getExternalId().isEmpty()) {
                // Check if expense already exists (idempotency check)
                boolean exists = expenseService.expenseExists(eventData.getUserId(), eventData.getExternalId());
                if (exists) {
                    System.out.println("ExpenseConsumer: Duplicate event detected for externalId: " + eventData.getExternalId() + ", skipping...");
                    return; // Skip processing duplicate events
                }
            }
            
            // Process the expense
            boolean success = expenseService.createExpense(eventData);
            if (!success) {
                System.out.println("ExpenseConsumer: Failed to create expense for userId: " + eventData.getUserId());
            }
        }catch(Exception ex){
            ex.printStackTrace();
            System.out.println("ExpenseConsumer: Exception is thrown while consuming kafka event: " + ex.getMessage());
            // In production, consider implementing dead letter queue (DLQ) for failed messages
            throw ex; // Re-throw to enable Kafka retry mechanism
        }
    }

}
