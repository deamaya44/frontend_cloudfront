# GitHub Actions Configuration

Este repositorio contiene el workflow de CI/CD para el despliegue automático del frontend.

## Workflow: Deploy Frontend

El workflow se activa automáticamente cuando hay cambios en la rama `main` o puede ejecutarse manualmente.

## Secrets Requeridos

Configura los siguientes secrets en tu repositorio:

### Settings > Secrets and variables > Actions > New repository secret

1. **`AWS_ACCESS_KEY_ID`**
   - Access Key ID de un usuario IAM con permisos para S3 y CloudFront

2. **`AWS_SECRET_ACCESS_KEY`**
   - Secret Access Key correspondiente

3. **`S3_FRONTEND_BUCKET`**
   - Nombre del bucket S3 primario (con replicación)
   - Ejemplo: `multiregion-356491328040-us-east-1-dev-data`

4. **`S3_FRONTEND_PREFIX`**
   - Prefijo dentro del bucket para los archivos
   - Ejemplo: `frontend/`

5. **`LAMBDA_API_URL`**
   - URL de tu función Lambda (obtenida de Terraform output)
   - Ejemplo: `https://abc123.lambda-url.us-east-1.on.aws`
   - **IMPORTANTE:** Este secret se inyecta automáticamente en `config.js` durante el deployment

6. **`CLOUDFRONT_DISTRIBUTION_ID`**
   - ID de la distribución de CloudFront
   - Ejemplo: `E1234ABCD5678`

## Flujo de Despliegue

1. **Checkout del código**
2. **Configuración de credenciales AWS**
3. **Generación de `config.js`** - Se crea dinámicamente con la URL de Lambda
4. **Sincronización a S3** - Archivos se suben al bucket primario con prefijo
5. **Cache control** - HTML y config.js sin cache, otros archivos con cache largo
6. **Invalidación de CloudFront** - Se invalida el cache
7. **Replicación automática** - Los archivos se replican a us-west-2

## Permisos IAM Requeridos

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::your-bucket-name",
        "arn:aws:s3:::your-bucket-name/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudfront:CreateInvalidation",
        "cloudfront:GetInvalidation"
      ],
      "Resource": "arn:aws:cloudfront::*:distribution/*"
    }
  ]
}
```

## Uso

### Despliegue Automático
```bash
git add .
git commit -m "Update frontend"
git push origin main
```

### Despliegue Manual
1. Ve a **Actions** en GitHub
2. Selecciona **Deploy Frontend to S3 and CloudFront**
3. Click en **Run workflow**

## Obtener la URL de Lambda

Desde tu proyecto Terraform:

```bash
cd /path/to/multiregion/multiregion
terraform output lambda_function_url
```

Copia el valor y configúralo como secret `LAMBDA_API_URL`.

## Verificación

Después del despliegue:
1. Espera 2-3 minutos para la invalidación de CloudFront
2. Accede a tu dominio de CloudFront
3. Verifica que la API URL en `config.js` sea correcta
4. Comprueba que el frontend pueda comunicarse con la Lambda
