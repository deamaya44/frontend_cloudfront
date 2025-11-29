#!/bin/bash

# Script para ejecutar el init_db.sql a través de una Lambda temporal
# Esto evita problemas de conectividad directa a RDS

set -e

ENVIRONMENT=${1:-dev}
LAMBDA_NAME="multiregion-${ENVIRONMENT}-api"
REGION="us-east-1"

echo "🔧 Creando script de inicialización de base de datos..."
echo ""

# Crear un script Python temporal que ejecute el SQL
cat > /tmp/init_db_lambda.py << 'EOFPY'
import json
import os
import psycopg2
import boto3

def handler(event, context):
    # Environment variables
    DB_HOST = os.environ.get('DB_HOST').split(':')[0]
    DB_NAME = os.environ.get('DB_NAME')
    DB_USER = os.environ.get('DB_USER')
    DB_SECRET_ARN = os.environ.get('DB_SECRET_ARN')
    DB_PORT = os.environ.get('DB_PORT', '5432')
    
    # Get password from Secrets Manager
    client = boto3.client('secretsmanager')
    response = client.get_secret_value(SecretId=DB_SECRET_ARN)
    
    if 'SecretString' in response:
        secret = response['SecretString']
        try:
            secret_dict = json.loads(secret)
            db_password = secret_dict.get('password') or secret_dict.get('Password') or secret
        except json.JSONDecodeError:
            db_password = secret
    else:
        db_password = response['SecretBinary'].decode('utf-8')
    
    # SQL Script
    init_sql = """
-- Crear tabla de usuarios
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Crear índice en email
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Crear función para actualizar timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Crear trigger si no existe
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_users_updated_at') THEN
        CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END
$$;

-- Insertar datos de ejemplo
INSERT INTO users (name, email) VALUES 
    ('John Doe', 'john@example.com'),
    ('Jane Smith', 'jane@example.com'),
    ('Bob Wilson', 'bob@example.com')
ON CONFLICT (email) DO NOTHING;
    """
    
    try:
        # Connect to database
        conn = psycopg2.connect(
            host=DB_HOST,
            database=DB_NAME,
            user=DB_USER,
            password=db_password,
            port=DB_PORT,
            connect_timeout=5,
            sslmode='require'
        )
        
        cursor = conn.cursor()
        
        # Execute SQL script
        cursor.execute(init_sql)
        conn.commit()
        
        # Get user count
        cursor.execute("SELECT COUNT(*) FROM users")
        user_count = cursor.fetchone()[0]
        
        cursor.close()
        conn.close()
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Database initialized successfully',
                'user_count': user_count
            })
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        }
EOFPY

echo "📤 Invocando Lambda para inicializar la base de datos..."
echo ""

# Invocar la Lambda existente pero con el código de inicialización inline
# Usamos la Lambda existente que ya tiene acceso a RDS
aws lambda invoke \
    --function-name ${LAMBDA_NAME} \
    --region ${REGION} \
    --payload '{"action": "init_db"}' \
    --cli-binary-format raw-in-base64-out \
    /tmp/lambda_response.json > /dev/null 2>&1 || true

echo "Nota: La Lambda existente no tiene el código de inicialización."
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "Alternativa: Ejecuta este SQL manualmente en tu RDS"
echo "═══════════════════════════════════════════════════════════"
echo ""
cat << 'EOFSQL'
-- Copia y pega este SQL en tu cliente de base de datos:

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_users_updated_at') THEN
        CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END
$$;

INSERT INTO users (name, email) VALUES 
    ('John Doe', 'john@example.com'),
    ('Jane Smith', 'jane@example.com'),
    ('Bob Wilson', 'bob@example.com')
ON CONFLICT (email) DO NOTHING;
EOFSQL

echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Para ejecutar el SQL, puedes usar:"
echo ""
echo "1. AWS RDS Query Editor (en la consola web):"
echo "   https://console.aws.amazon.com/rds/home?region=${REGION}#query-editor:"
echo ""
echo "2. Desde EC2 en la misma VPC:"
echo "   psql -h <RDS_ENDPOINT> -U postgres_admin -d postgres -f init_db.sql"
echo ""
echo "3. pgAdmin o cualquier cliente PostgreSQL"
echo ""
