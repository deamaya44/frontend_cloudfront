# Multi-Region Frontend con Failover Automático

Frontend con failover automático entre dos regiones AWS Lambda.

## 🚀 Inicio Rápido

### 1. Configurar URLs de Lambda

Edita `config.js` con tus URLs de Lambda:

```javascript
const CONFIG = {
    PRIMARY_API_URL: 'https://tu-lambda-url.lambda-url.us-east-1.on.aws',
    SECONDARY_API_URL: 'https://tu-lambda-url.lambda-url.us-west-2.on.aws',
    // ... resto de configuración
}
```

### 2. Ejecutar con Docker

```bash
cd /home/tilin/multiregion/frontend_cloudfront

# Iniciar el frontend
docker-compose up -d

# Ver logs
docker-compose logs -f

# Detener
docker-compose down
```

### 3. Acceder

Abre en tu navegador: **http://localhost:8080**

## 🔄 Cómo Funciona el Failover

### Failover Automático

1. **Inicio**: El frontend intenta conectarse primero a la Lambda primaria (us-east-1)
2. **Monitoreo**: Realiza health checks cada 30 segundos
3. **Detección**: Si la primaria falla, automáticamente cambia a la secundaria (us-west-2)
4. **Failback**: Si la primaria se recupera, vuelve automáticamente a ella

### Indicadores Visuales

- **✓ Healthy** (verde): API primaria funcionando
- **⚠ Failover Active** (amarillo): Usando API secundaria
- **✗ All APIs Down** (rojo): Ambas APIs caídas

La región activa se muestra en la barra de estado.

## ⚙️ Configuración

En `config.js`:

```javascript
const CONFIG = {
    PRIMARY_API_URL: 'https://...',      // Lambda región 1
    SECONDARY_API_URL: 'https://...',    // Lambda región 2
    
    FAILOVER_ENABLED: true,              // Activar failover automático
    HEALTH_CHECK_INTERVAL: 30000,        // Intervalo de health checks (ms)
    REQUEST_TIMEOUT: 5000,               // Timeout de requests (ms)
    MAX_RETRIES: 2                       // Reintentos antes de fallar
};
```

## 📊 Logs y Monitoreo

Abre la consola del navegador (F12) para ver:
- Estado de conexiones API
- Failovers automáticos
- Errores y reintentos

Ejemplo:
```
🚀 Initializing Multi-Region Frontend...
🔍 Testing API endpoints...
✅ Active API: us-east-1 (Primary)
🔍 Performing health check...
⚠️ Current API (Primary) is down
✅ Failing over to Secondary
```

## 🧪 Probar Failover

### Opción 1: Simular fallo de Lambda
```bash
# En otra terminal, detén la Lambda primaria en AWS o simula downtime
# El frontend automáticamente cambiará a la secundaria
```

### Opción 2: Modificar health check
Temporalmente cambia la URL primaria en `config.js` a una inválida para forzar failover.

## 🛠️ Sin Docker (Alternativa)

Si prefieres no usar Docker:

```bash
# Opción 1: Python
python3 -m http.server 8080

# Opción 2: Node.js (necesitas instalar http-server)
npx http-server -p 8080

# Opción 3: PHP
php -S localhost:8080
```

Luego abre: http://localhost:8080

## 📁 Estructura de Archivos

```
frontend_cloudfront/
├── docker-compose.yml       # Configuración Docker
├── nginx.conf              # Configuración Nginx
├── config.js               # URLs y configuración de failover
├── app.js                  # Lógica de failover automático
├── index.html              # Frontend HTML
├── style.css               # Estilos
└── README_FRONTEND.md      # Esta guía
```

## 🔧 Troubleshooting

### Error: CORS
Si ves errores de CORS en la consola:
- Verifica que tus Lambdas tengan CORS habilitado
- Las configuraciones en `lambda_function.py` ya incluyen CORS

### Error: Connection refused
- Verifica que Docker esté corriendo
- Verifica que el puerto 8080 no esté ocupado
- Prueba con otro puerto: `docker-compose -p 8081:80 up`

### Failover no funciona
- Abre la consola del navegador (F12)
- Verifica que las URLs en `config.js` sean correctas
- Verifica que `FAILOVER_ENABLED: true`

## 🎯 Escenarios de Uso

### Desarrollo Local
```bash
docker-compose up -d
# Modifica archivos HTML/CSS/JS
# Recarga el navegador para ver cambios
```

### Testing de Failover
1. Inicia el frontend
2. Verifica que funcione con la primaria
3. Detén la Lambda primaria en AWS
4. Observa el failover automático en la consola
5. Restaura la primaria
6. Observa el failback automático

### Producción
Para producción, considera:
- Deployar en S3 + CloudFront (ya configurado en Terraform)
- O usar un servidor Nginx/Apache
- El código de failover funciona igual

## 📝 Notas

- El failover es **transparente** para el usuario
- No se pierden datos durante el cambio
- El cambio de región toma ~1-2 segundos
- Ambas Lambdas deben apuntar a bases de datos sincronizadas (RDS Primary + Read Replica)

## 🆘 Soporte

Si tienes problemas:
1. Revisa los logs: `docker-compose logs`
2. Revisa la consola del navegador (F12)
3. Verifica las URLs en `config.js`
4. Verifica que las Lambdas estén corriendo: `curl https://tu-lambda-url/health`
