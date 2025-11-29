#!/bin/bash

# Script para inicializar la tabla users en RDS usando el endpoint de Lambda
# Uso: ./init-db-via-lambda.sh

set -e

PRIMARY_URL="https://hub65dkq65ugaao3g7zwaystnq0vbrio.lambda-url.us-east-1.on.aws"

echo "🔧 Inicializando base de datos PostgreSQL..."
echo ""
echo "URL: ${PRIMARY_URL}/init-db"
echo ""

# Esperar a que la Lambda esté lista (después del deploy)
echo "⏳ Esperando a que Lambda esté lista..."
sleep 5

# Llamar al endpoint de inicialización
echo "📤 Enviando request de inicialización..."
response=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "${PRIMARY_URL}/init-db" 2>&1)
http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d: -f2)
body=$(echo "$response" | grep -v "HTTP_CODE:")

echo ""
echo "Status Code: $http_code"
echo "Response:"
echo "$body" | python3 -m json.tool 2>/dev/null || echo "$body"
echo ""

if [ "$http_code" == "200" ]; then
    echo "✅ Base de datos inicializada correctamente"
    echo ""
    echo "🧪 Probando endpoint /users..."
    users_response=$(curl -s "${PRIMARY_URL}/users")
    echo "$users_response" | python3 -m json.tool 2>/dev/null || echo "$users_response"
    echo ""
    echo "🎉 ¡Todo listo! Ahora puedes usar el frontend:"
    echo "   http://localhost:8080"
else
    echo "❌ Error al inicializar la base de datos"
    echo ""
    echo "Posibles causas:"
    echo "1. La Lambda no tiene permisos para ejecutar DDL en RDS"
    echo "2. La Lambda no puede conectarse a RDS"
    echo "3. La tabla ya existe"
    echo ""
    echo "Revisa los logs de Lambda en CloudWatch para más detalles"
fi

echo ""
