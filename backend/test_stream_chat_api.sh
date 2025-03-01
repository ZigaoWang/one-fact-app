#!/bin/bash

# Test the streaming chat API with curl
echo "Testing streaming chat API..."

# Create a test message payload
cat > test_stream_payload.json << EOF
{
  "fact_id": "latest",
  "messages": [
    {
      "role": "user",
      "content": "Tell me more about this fact",
      "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    }
  ]
}
EOF

# Display the payload
echo "Request payload:"
cat test_stream_payload.json
echo ""

# Send the request to the API
echo "Sending request to streaming API..."
curl -v -X POST \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -d @test_stream_payload.json \
  https://one-fact-api.fly.dev/api/v1/chat/stream

echo ""
echo "Done testing."
