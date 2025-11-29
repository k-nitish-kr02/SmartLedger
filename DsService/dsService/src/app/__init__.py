from flask import Flask
from flask import request, jsonify
from .service.messageService import MessageService
from kafka import KafkaProducer
import json
import os
import jsonpickle

app = Flask(__name__)
app.config.from_pyfile('config.py')

messageService = MessageService()
kafka_host = os.getenv('KAFKA_HOST', 'localhost')
kafka_port = os.getenv('KAFKA_PORT', '9092')
kafka_bootstrap_servers = f"{kafka_host}:{kafka_port}"
print("Kafka server is "+kafka_bootstrap_servers)
print("\n")
producer = KafkaProducer(bootstrap_servers=kafka_bootstrap_servers,
                         value_serializer=lambda v: json.dumps(v).encode('utf-8'))

@app.route('/v1/ds/message', methods=['POST'])
def handle_message():
    try:
        # Check for user_id header (case-insensitive)
        user_id = request.headers.get('x-user-id') or request.headers.get('X-User-Id') or request.headers.get('X-User-ID')
        if not user_id:
            return jsonify({'error': 'x-user-id header is required'}), 400

        # Validate request body
        if not request.json:
            return jsonify({'error': 'Request body is required'}), 400

        message = request.json.get('message')
        if not message:
            return jsonify({'error': 'message field is required'}), 400

        # Process message through LLM service
        result = messageService.process_message(message)

        if result is not None:
            serialized_result = result.serialize()
            serialized_result['user_id'] = user_id
            
            # Generate external_id for idempotency if not present
            if 'external_id' not in serialized_result or not serialized_result['external_id']:
                import uuid
                serialized_result['external_id'] = str(uuid.uuid4())
            
            # Send to Kafka
            try:
                future = producer.send('expense_service', serialized_result)
                # Wait for send to complete (optional, for error handling)
                # record_metadata = future.get(timeout=10)
                producer.flush()  # Ensure message is sent
            except Exception as kafka_error:
                print(f"Error sending to Kafka: {kafka_error}")
                # Still return the result even if Kafka fails
                # In production, consider retry logic or DLQ
            
            return jsonify(serialized_result)
        else:
            return jsonify({'error': 'Invalid message format or not a bank SMS'}), 400
    except Exception as e:
        print(f"Error in handle_message: {e}")
        return jsonify({'error': 'Internal server error', 'details': str(e)}), 500

@app.route('/', methods=['GET'])
def handle_get():
    return 'Hello world'

@app.route('/health', methods=['GET'])
def health_check():
    return 'OK'

if __name__ == "__main__":
    app.run(host="localhost", port=8010, debug=True)