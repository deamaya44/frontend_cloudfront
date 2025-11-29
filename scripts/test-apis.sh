#!/bin/bash

# Script para probar las APIs de Lambda directamente
# Uso: ./test-apis.sh

PRIMARY_URL="https://hub65dkq65ugaao3g7zwaystnq0vbrio.lambda-url.us-east-1.on.aws"
SECONDARY_URL="https://tnn7m36d6s6uliwu7kjd5hivia0bztcq.lambda-url.us-west-2.on.aws"

echo "🧪 Probando APIs de Lambda..."
echo ""

test_api() {
    local url=$1
    local name=$2
    
    echo "═══════════════════════════════════════"
    echo "Testing: $name"
    echo "URL: $url"
    echo "═══════════════════════════════════════"
    echo ""
    
    # Test Health endpoint
    echo "📡 GET /health"
    response=$(curl -s -w "\nHTTP_CODE:%{http_code}" "$url/health" 2>&1)
    http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d: -f2)
    body=$(echo "$response" | grep -v "HTTP_CODE:")
    
    echo "Status: $http_code"
    echo "Response: $body"
    echo ""
    
    # Test root endpoint
    echo "📡 GET /"
    response=$(curl -s -w "\nHTTP_CODE:%{http_code}" "$url/" 2>&1)
    http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d: -f2)
    body=$(echo "$response" | grep -v "HTTP_CODE:")
    
    echo "Status: $http_code"
    echo "Response: $body"
    echo ""
    
    # Test GET /users
    echo "📡 GET /users"
    response=$(curl -s -w "\nHTTP_CODE:%{http_code}" "$url/users" 2>&1)
    http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d: -f2)
    body=$(echo "$response" | grep -v "HTTP_CODE:")
    
    echo "Status: $http_code"
    echo "Response: $body"
    echo ""
    
    # Test POST /users
    echo "📡 POST /users"
    response=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "$url/users" \
        -H "Content-Type: application/json" \
        -d '{"name":"Test User","email":"test@example.com"}' 2>&1)
    http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d: -f2)
    body=$(echo "$response" | grep -v "HTTP_CODE:")
    
    echo "Status: $http_code"
    echo "Response: $body"
    echo ""
    echo ""
}

test_api "$PRIMARY_URL" "Primary API (us-east-1)"
test_api "$SECONDARY_URL" "Secondary API (us-west-2)"

echo "✅ Pruebas completadas"
