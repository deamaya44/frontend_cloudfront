#!/bin/bash

# Script para inicializar la base de datos RDS con la tabla users
# Uso: ./init-database.sh [environment]

set -e

ENVIRONMENT=${1:-dev}
REGION="us-east-1"
DB_IDENTIFIER="multiregion-${ENVIRONMENT}-rds"
SECRET_NAME="rds_admin_password_${ENVIRONMENT}_2"

echo "🔍 Obteniendo información de la base de datos..."
echo ""

# Obtener el endpoint de RDS
DB_ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier ${DB_IDENTIFIER} \
    --region ${REGION} \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text 2>/dev/null || echo "NOT_FOUND")

if [ "$DB_ENDPOINT" == "NOT_FOUND" ]; then
    echo "❌ Error: No se pudo encontrar la instancia RDS '${DB_IDENTIFIER}' en ${REGION}"
    exit 1
fi

echo "✅ RDS Endpoint: ${DB_ENDPOINT}"

# Obtener la contraseña desde Secrets Manager
echo "🔐 Obteniendo contraseña desde Secrets Manager..."
DB_PASSWORD=$(aws secretsmanager get-secret-value \
    --secret-id ${SECRET_NAME} \
    --region ${REGION} \
    --query 'SecretString' \
    --output text 2>/dev/null || echo "NOT_FOUND")

if [ "$DB_PASSWORD" == "NOT_FOUND" ]; then
    echo "❌ Error: No se pudo obtener la contraseña del secret '${SECRET_NAME}'"
    exit 1
fi

echo "✅ Contraseña obtenida"
echo ""

# Configurar variables para psql
export PGHOST=${DB_ENDPOINT}
export PGPORT=5432
export PGDATABASE=postgres
export PGUSER=postgres_admin
export PGPASSWORD=${DB_PASSWORD}

echo "📋 Configuración:"
echo "   Host:     ${PGHOST}"
echo "   Port:     ${PGPORT}"
echo "   Database: ${PGDATABASE}"
echo "   User:     ${PGUSER}"
echo ""

# Verificar si psql está instalado
if ! command -v psql &> /dev/null; then
    echo "❌ Error: psql no está instalado"
    echo ""
    echo "Para instalar psql:"
    echo "  Ubuntu/Debian: sudo apt-get install postgresql-client"
    echo "  macOS:         brew install postgresql"
    echo "  Amazon Linux:  sudo yum install postgresql"
    exit 1
fi

# Probar conexión
echo "🔌 Probando conexión a la base de datos..."
if psql -c "SELECT version();" > /dev/null 2>&1; then
    echo "✅ Conexión exitosa"
else
    echo "❌ Error: No se pudo conectar a la base de datos"
    echo ""
    echo "Posibles causas:"
    echo "1. El Security Group no permite conexiones desde tu IP"
    echo "2. La base de datos no es públicamente accesible"
    echo "3. La contraseña es incorrecta"
    echo ""
    echo "Para conectar desde tu máquina local, considera:"
    echo "- Usar un bastion host en la VPC"
    echo "- Usar AWS Systems Manager Session Manager"
    echo "- Temporalmente hacer la RDS públicamente accesible"
    exit 1
fi

echo ""
echo "📝 Ejecutando script de inicialización..."
echo ""

# Ejecutar el script SQL
if psql -f ../backend_lambda/init_db.sql; then
    echo ""
    echo "✅ Script ejecutado exitosamente"
    echo ""
    
    # Verificar que la tabla existe
    echo "🔍 Verificando tabla users..."
    USER_COUNT=$(psql -t -c "SELECT COUNT(*) FROM users;")
    echo "✅ Tabla 'users' creada. Total de usuarios: ${USER_COUNT}"
else
    echo ""
    echo "❌ Error ejecutando el script SQL"
    exit 1
fi

echo ""
echo "═══════════════════════════════════════"
echo "✨ Base de datos inicializada correctamente"
echo "═══════════════════════════════════════"
echo ""
echo "Ahora puedes usar el frontend en: http://localhost:8080"
