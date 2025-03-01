#!/bin/bash

# Test the chat API with curl
echo "Testing chat API..."

# Create a test message payload
cat > test_payload.json << EOF
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
cat test_payload.json
echo ""

# Send the request to the API
echo "Sending request to API..."
curl -v -X POST \
  -H "Content-Type: application/json" \
  -d @test_payload.json \
  https://one-fact-api.fly.dev/api/v1/chat

echo ""
echo "Done testing."
