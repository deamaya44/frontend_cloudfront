# Frontend CloudFront

Aplicación frontend simple que consume la API Lambda. Este es un repositorio independiente que se despliega automáticamente mediante GitHub Actions.

## Estructura

```
frontend_cloudfront/
├── index.html          # Página principal
├── style.css           # Estilos CSS
├── app.js             # Lógica JavaScript
├── config.js          # Configuración (generado automáticamente)
├── .github/
│   └── workflows/
│       └── deploy.yml # GitHub Actions workflow
└── README.md          # Este archivo
```

## Configuración

**NO necesitas configurar manualmente la URL de la API.** Se inyecta automáticamente durante el despliegue mediante GitHub Actions.

### Setup Inicial

1. **Crear repositorio en GitHub** para este frontend

2. **Configurar Secrets en GitHub:**
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `S3_FRONTEND_BUCKET` - ej: `multiregion-356491328040-us-east-1-dev-data`
   - `S3_FRONTEND_PREFIX` - ej: `frontend/`
   - `LAMBDA_API_URL` - Obtenerlo con: `terraform output lambda_function_url`
   - `CLOUDFRONT_DISTRIBUTION_ID`

3. **Push del código:**

```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin git@github.com:YOUR_USERNAME/frontend-repo.git
git push -u origin main
```

El despliegue se activará automáticamente.

## Características

- ✅ Diseño responsive
- ✅ Health check de la API
- ✅ CRUD de usuarios
- ✅ Indicador de región
- ✅ Manejo de errores
- ✅ Interfaz moderna con AWS branding

## Testing Local

Para probar localmente:

```bash
# Opción 1: Python
python -m http.server 8000

# Opción 2: Node.js
npx http-server

# Opción 3: PHP
php -S localhost:8000
```

**Nota:** Para testing local, edita temporalmente `config.js` con tu URL de Lambda local o de desarrollo.

```javascript
const API_URL = 'https://your-dev-lambda.lambda-url.us-east-1.on.aws';
```

⚠️ **No hagas commit de este cambio** - el archivo se regenera automáticamente en cada deployment.

## Despliegue

El despliegue se realiza automáticamente mediante GitHub Actions:

### Flujo Automático
1. Push a `main` activa el workflow
2. GitHub Actions genera `config.js` con la URL de Lambda (desde secret)
3. Sincroniza archivos al bucket S3 primario (prefijo `frontend/`)
4. Archivos se replican automáticamente a us-west-2
5. Invalida cache de CloudFront
6. ✅ Aplicación disponible en minutos

### Flujo Manual
1. Ve a **Actions** en GitHub
2. Selecciona **Deploy Frontend to S3 and CloudFront**  
3. Click en **Run workflow**

**Importante:** 
- El archivo `config.js` se genera automáticamente - NO lo edites manualmente
- Se usan los buckets S3 existentes con replicación Cross-Region
- Los archivos van al prefijo `frontend/` dentro del bucket

## Obtener URL de Lambda

Desde el proyecto Terraform:

```bash
cd /path/to/multiregion/multiregion
terraform output lambda_function_url
```

Configura este valor como secret `LAMBDA_API_URL` en GitHub.

## Arquitectura

```
Usuario → CloudFront → S3 (Frontend)
              ↓
         Lambda API → RDS PostgreSQL
```

## Multi-Región

La aplicación está preparada para funcionar en una arquitectura multi-región:

- **Región Primaria (us-east-1)**: Lambda + RDS primary
- **Región Secundaria (us-west-2)**: Lambda + RDS replica

CloudFront distribuye el contenido globalmente desde ambas regiones.
