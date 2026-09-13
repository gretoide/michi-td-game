# ADR-0001: Stack tecnológico de Michi TD V1

- **Estado:** aceptado
- **Fecha:** 2026-09-13
- **Alcance:** cliente desktop y API de Michi TD V1

## Contexto

Michi TD V1 necesita una base técnica reproducible para el cliente desktop y la API de autenticación. Esta decisión fija el stack ya elegido y sus versiones operativas, sin agregar funcionalidades de producto.

## Decisión

### Cliente desktop

- **Engine:** Godot `4.7.2.stable.official.ed1daf0bf`.
- **Lenguaje:** GDScript.
- **Aplicación:** desktop standalone.
- **Renderer:** GL Compatibility.
- **Target V1:** Windows Desktop.
- **Viewport:** 1920×1080, con ventana inicial de 1280×720.

### Backend

- **Framework:** NestJS `11.2.3` (resuelto en `michi-td-api/package-lock.json`).
- **Runtime:** Node.js `24.14.1` verificado localmente; el requisito del proyecto es Node.js `24+`.
- **Package manager:** npm `11.11.0` verificado localmente.
- **Lockfile:** `package-lock.json`, formato `lockfileVersion: 3`; las instalaciones reproducibles usan `npm ci`.
- **Lenguaje/compilación:** TypeScript `5.9.3` resuelto, target ES2022 y módulo CommonJS.
- **ORM:** Prisma `6.19.0` y `@prisma/client` `6.19.0`.
- **Base de datos:** MongoDB Atlas mediante el datasource MongoDB de Prisma, base `michi_td`. La versión del servidor es administrada externamente por Atlas y no está fijada en este repositorio; debe registrarse en la configuración del entorno de despliegue cuando se formalice ese entorno.

### Componentes backend relevantes

- JWT: `@nestjs/jwt` `11.0.2`.
- Validación: `class-validator` `0.14.2` y `class-transformer` `0.5.1`.
- Contraseñas: `bcryptjs` `3.0.3`.
- Email: `nodemailer` `10.0.9`.
- Documentación: `@nestjs/swagger` `11.4.7`.
- Tests: Jest `29.7.0`, ts-jest `29.4.12` y Supertest `7.2.2`.

Las versiones anteriores son las resueltas por el lockfile; los rangos declarados permanecen en `michi-td-api/package.json`.

## Reproducibilidad y validación

Desde `michi-td-api`:

```powershell
npm ci
npm run prisma:generate
npm run prisma:validate
npm run build
npm test
```

Desde `michi-td-game`:

```powershell
godot --headless --path . --editor --quit
godot --headless --path . --quit-after 2
godot --headless --path . --export-debug "Windows Desktop" build/michi-td.exe
```

La build desktop V1 inicial sólo tiene target Windows Desktop. No se fija todavía un target Linux o macOS.

## Consecuencias

- El cliente incluye sus assets runtime localmente en el export de Godot.
- La API mantiene responsabilidades de autenticación, usuarios, sesiones y email; este ADR no introduce online, meta-progresión ni servicios adicionales.
- Actualizar una versión mayor requiere modificar este ADR, los manifests/lockfiles correspondientes y repetir las validaciones.
