# 🚀 Quick Start Guide

## Paso 1: Configurar URLs de Lambda

### Opción A: Automático (Recomendado)
```bash
cd /home/tilin/multiregion/frontend_cloudfront
./setup-frontend.sh dev
```

### Opción B: Manual
Edita `config.js` y reemplaza las URLs:
```javascript
PRIMARY_API_URL: 'https://tu-url-lambda-region1.lambda-url.us-east-1.on.aws',
SECONDARY_API_URL: 'https://tu-url-lambda-region2.lambda-url.us-west-2.on.aws',
```

## Paso 2: Iniciar Frontend

```bash
docker-compose up -d
```

## Paso 3: Acceder

Abre tu navegador en: **http://localhost:8080**

---

## 🔄 Failover Automático

El frontend automáticamente:
- ✅ Usa la Lambda primaria (us-east-1) por defecto
- ⚠️ Cambia a la secundaria (us-west-2) si la primaria falla
- 🔄 Vuelve a la primaria cuando se recupera
- 📊 Muestra el estado en la barra superior

## 🛑 Detener

```bash
docker-compose down
```

---

Ver **README_FRONTEND.md** para más detalles.
