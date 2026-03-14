package ru.egorich88.kafka;

import org.apache.kafka.clients.consumer.*;
import org.apache.kafka.common.PartitionInfo;
import org.apache.kafka.common.TopicPartition;
import org.apache.kafka.common.serialization.StringDeserializer;

import java.time.Duration;
import java.util.*;

/**
 * Утилита для поиска сообщений в Kafka по ключу.
 * Использование: java -cp ... ru.egorich88.kafka.MessageSearch <bootstrap> <topic> <key>
 */
public class MessageSearch {
    public static void main(String[] args) throws Exception {
        if (args.length < 3) {
            System.err.println("Usage: MessageSearch <bootstrap> <topic> <key>");
            System.exit(1);
        }
        String bootstrap = args[0];
        String topic = args[1];
        String searchKey = args[2];

        Properties props = new Properties();
        props.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrap);
        props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
        props.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class.getName());
        props.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");
        props.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, "false");

        try (KafkaConsumer<String, String> consumer = new KafkaConsumer<>(props)) {
            // Получаем список партиций топика
            List<PartitionInfo> partitions = consumer.partitionsFor(topic);
            if (partitions == null || partitions.isEmpty()) {
                System.err.println("Topic not found: " + topic);
                return;
            }

            List<TopicPartition> tps = new ArrayList<>();
            for (PartitionInfo p : partitions) {
                tps.add(new TopicPartition(topic, p.partition()));
            }
            consumer.assign(tps);
            consumer.seekToBeginning(tps); // начинаем с начала

            boolean found = false;
            while (!found) {
                ConsumerRecords<String, String> records = consumer.poll(Duration.ofMillis(1000));
                for (ConsumerRecord<String, String> record : records) {
                    if (record.key() != null && record.key().equals(searchKey)) {
                        System.out.printf("Found: offset=%d, partition=%d, key=%s, value=%s%n",
                                record.offset(), record.partition(), record.key(), record.value());
                        found = true;
                        break;
                    }
                }
                if (records.isEmpty()) break; // дошли до конца
            }
            if (!found) {
                System.out.println("No messages with key '" + searchKey + "' found.");
            }
        }
    }
}
