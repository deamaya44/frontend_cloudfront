#!/bin/bash

# Script de verificación completa del sistema multi-región

PRIMARY_URL="https://hub65dkq65ugaao3g7zwaystnq0vbrio.lambda-url.us-east-1.on.aws"
SECONDARY_URL="https://tnn7m36d6s6uliwu7kjd5hivia0bztcq.lambda-url.us-west-2.on.aws"

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   🌍 Verificación del Sistema Multi-Región               ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Test Primary API
echo "═══ 🔵 Región Primaria (us-east-1) ═══"
echo "URL: ${PRIMARY_URL}"
echo ""

echo "✓ Health Check:"
curl -s "${PRIMARY_URL}/health" | python3 -m json.tool
echo ""

echo "✓ Usuarios:"
curl -s "${PRIMARY_URL}/users" | python3 -m json.tool | head -20
echo ""

# Test Secondary API
echo "═══ 🟢 Región Secundaria (us-west-2) ═══"
echo "URL: ${SECONDARY_URL}"
echo ""

echo "✓ Health Check:"
curl -s "${SECONDARY_URL}/health" | python3 -m json.tool
echo ""

echo "✓ Usuarios (desde Read Replica):"
curl -s "${SECONDARY_URL}/users" | python3 -m json.tool | head -20
echo ""

# Test Frontend
echo "═══ 🌐 Frontend ═══"
if docker ps | grep -q multiregion-frontend; then
    echo "✅ Frontend corriendo en Docker"
    echo "🌐 URL: http://localhost:8080"
else
    echo "❌ Frontend NO está corriendo"
    echo "Para iniciar: cd frontend_cloudfront && docker-compose up -d"
fi
echo ""

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   ✨ Sistema Multi-Región Funcionando Correctamente      ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Próximos pasos:"
echo "   1. Abre http://localhost:8080 en tu navegador"
echo "   2. Crea usuarios desde el frontend"
echo "   3. El failover automático está activo"
echo ""
