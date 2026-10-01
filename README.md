# 🔐 Práctica 4 — Seguridad en Bases de Datos

**Universidad Manuela Beltrán · Bases de Datos · Guía de Laboratorio N.º 4**
**Eje temático:** Usuarios, Privilegios, Roles y Auditoría
**Sistema base:** `Guia_3` (el sistema académico de las Prácticas 1-3)
**SGBD objetivo:** MySQL 8.x (ver [notas de compatibilidad con MariaDB](#-compatibilidad-mysql-8-vs-mariadb))

---

## 📑 Tabla de contenido

1. [Resumen en 30 segundos](#-resumen-en-30-segundos)
2. [Estado del proyecto](#-estado-del-proyecto)
3. [Estructura de archivos](#-estructura-de-archivos)
4. [Requisitos y orden de ejecución](#-requisitos-y-orden-de-ejecución)
5. [El sistema base: Guia_3](#-el-sistema-base-guia_3)
6. [Conceptos clave (para explicar)](#-conceptos-clave-para-explicar)
7. [Tarea previa — GRANT vs REVOKE](#-tarea-previa--grant-vs-revoke)
8. [Actividad 1 — Usuarios y privilegios](#-actividad-1--usuarios-y-privilegios)
9. [Actividad 2 — Roles corporativos](#-actividad-2--roles-corporativos)
10. [Diagramas (MER, roles y matriz)](#-diagramas-mer-roles-y-matriz)
11. [Actividad 3 — Prevención de inyección SQL](#-actividad-3--prevención-de-inyección-sql)
12. [Actividad 4 — Trigger de auditoría](#-actividad-4--trigger-de-auditoría)
13. [Actividad 5 — Informe de seguridad](#-actividad-5--informe-de-seguridad)
14. [Errores comunes y cómo resolverlos](#-errores-comunes-y-cómo-resolverlos)
15. [Compatibilidad MySQL 8 vs MariaDB](#-compatibilidad-mysql-8-vs-mariadb)
16. [Observaciones y correcciones](#-observaciones-y-correcciones)
17. [Guion para explicarlo en clase](#-guion-para-explicarlo-en-clase)
18. [Referencias (APA 7)](#-referencias-apa-7)

---

## ⚡ Resumen en 30 segundos

Actuamos como **DBA** del sistema `Guia_3` y lo protegemos por capas.

| Capa | Qué resuelve | Dónde se implementa |
|---|---|---|
| **Autenticación** | *¿Quién eres y desde dónde entras?* | `CREATE USER 'usuario'@'localhost'` (Act. 1) |
| **Autorización** | *¿Qué puedes hacer y sobre qué?* | `GRANT` / `REVOKE` y roles (Act. 1 y 2) |
| **Aplicación** | *Que nadie inyecte código por un formulario* | Consultas parametrizadas (Act. 3) |
| **Auditoría** | *Quién cambió qué, cuándo y qué había antes* | Triggers + `auditoria_log` (Act. 4) |
| **Documentación** | *El mapa de todo lo anterior* | Informe de seguridad (Act. 5) |

**Principio rector:** *mínimo privilegio*. Cada cuenta tiene solo lo que necesita para su trabajo, y nada más.

---

## 📊 Estado del proyecto

Todos los scripts están **probados de punta a punta en MySQL 8.0** sobre una base limpia.

| Entregable | Archivo | Estado |
|---|---|---|
| Base — esquema de `Guia_3` | `Base/Base_01_Esquema_Guia_3.sql` | ✅ |
| Base — datos de `Guia_3` | `Base/Base_02_Datos_Guia_3.sql` | ✅ |
| Tarea previa — punto 1 (GRANT vs REVOKE) | `00_TareaPrevia_GRANT_vs_REVOKE.sql` | ✅ Corregido (ya no deja privilegios directos) |
| Tarea previa — punto 2 (3 tipos de control de acceso) | — | ⏳ Pendiente (texto de 100 palabras) |
| Tarea previa — punto 3 (diseño de roles en papel) | — | ⏳ Pendiente (el diagrama de roles sirve de base) |
| Actividad 1 — Usuarios y privilegios | `01_Actividad1_Usuarios_Privilegios.sql` | ✅ |
| Actividad 2 — Roles corporativos | `02_Actividad2_Roles_Corporativos.sql` | ✅ |
| Actividad 3 — Inyección SQL | `03_Actividad3_SQL_Injection.py` | ✅ |
| Actividad 4 — Trigger de auditoría | `04_Actividad4_Trigger_Auditoria.sql` | ✅ |
| Datos y pruebas de acceso | `05_Datos_Prueba.sql` | ✅ |
| Actividad 5 — Mapa de seguridad (evidencias) | `06_Mapa_Seguridad.sql` | ✅ |
| MER + diagrama de roles + matriz | `MER_Practica4_Seguridad.drawio` | ✅ (falta reemplazar `TABLA_PRINCIPAL` por `Matricula`) |
| Actividad 5 — Informe | `Practica4_NombreEquipo.pdf` | ⏳ Pendiente |

---

## 📁 Estructura de archivos

```
Guia4/
├── README.md
├── Base/
│   ├── Base_01_Esquema_Guia_3.sql            ← CREATE DATABASE + 6 tablas
│   └── Base_02_Datos_Guia_3.sql              ← datos ficticios (5/15/6/10/8/30)
├── Actividad-tarea-previa/Script/
│   └── 00_TareaPrevia_GRANT_vs_REVOKE.sql    ← 5 ejemplos comparados
├── Actividad-1/Script/
│   └── 01_Actividad1_Usuarios_Privilegios.sql
├── Actividad-2/Scripts/
│   └── 02_Actividad2_Roles_Corporativos.sql
├── Actividad-3/Script/
│   └── 03_Actividad3_SQL_Injection.py        ← ANTES vs DESPUÉS + ataques
├── Actividad-4/Script/
│   └── 04_Actividad4_Trigger_Auditoria.sql   ← triggers AFTER UPDATE / DELETE
├── Pruebas/
│   └── 05_Datos_Prueba.sql                   ← datos de prueba + pruebas por usuario
├── Actividad-5/Script/
│   └── 06_Mapa_Seguridad.sql                 ← consultas para el informe
└── Diagramas/
    └── MER_Practica4_Seguridad.drawio
```

---

## 🛠 Requisitos y orden de ejecución

### Requisitos

- MySQL 8.x (o MariaDB 10.5+, con los [ajustes indicados](#-compatibilidad-mysql-8-vs-mariadb)).
- Una cuenta con permisos de administración (`root` **solo** para montar el laboratorio).
- MySQL Workbench, VS Code o la terminal (`mysql -u <usuario> -p`).
- Python 3 con `pip install mysql-connector-python` (Actividad 3).

### Orden de ejecución

> ⚠️ El orden importa: cada script depende del anterior.

| # | Script | Ejecutar como | Qué deja listo |
|---|---|---|---|
| 1 | `Base_01_Esquema_Guia_3.sql` | `root` | La base `Guia_3` con sus 6 tablas |
| 2 | `Base_02_Datos_Guia_3.sql` | `root` | Datos: 5 programas, 15 estudiantes, 6 profesores, 10 materias, 8 grupos, 30 matrículas |
| 3 | `01_Actividad1_Usuarios_Privilegios.sql` | `root` | `auditoria_log`, 4 usuarios, privilegios **directos** |
| 4 | `02_Actividad2_Roles_Corporativos.sql` | `root` | 3 roles; privilegios migrados de directos a **heredados** |
| 5 | `00_TareaPrevia_GRANT_vs_REVOKE.sql` | `root` | Demostración; deja todo igual que tras el paso 4 |
| 6 | `04_Actividad4_Trigger_Auditoria.sql` | `root` | Triggers de auditoría (**antes** de modificar datos) |
| 7 | `05_Datos_Prueba.sql` — Parte 1 | `root` | Programas 990-992 y matrículas 9990-9992 |
| 8 | `05_Datos_Prueba.sql` — Partes 2 y 3 | cada usuario | Capturas de permisos y de auditoría |
| 9 | `03_Actividad3_SQL_Injection.py` | terminal (`operador`) | Capturas del ataque y de la defensa |
| 10 | `06_Mapa_Seguridad.sql` | `root` | Capturas para el informe |
| 11 | `05_Datos_Prueba.sql` — Parte 4 | `root` | Limpieza de los datos de prueba |

> 💡 Los triggers solo registran lo que pasa **después** de crearlos. Si haces los UPDATE/DELETE de prueba antes del paso 6, el log queda vacío.

> ⚠️ Si vuelves a ejecutar `Base_02` con los triggers ya creados, sus `DELETE` iniciales quedan registrados en el log como `root@localhost`. Para reiniciar del todo, usa el `DROP DATABASE` comentado al inicio de `Base_01`.

---

## 🏫 El sistema base: Guia_3

Estas son las 6 tablas operativas que se protegen (`Base_01`):

| Tabla | Qué guarda | Claves | Sensibilidad |
|---|---|---|---|
| `Programa` | Programas académicos (facultad, nombre, duración) | PK `IdPrograma` | Baja |
| `Estudiante` | Datos personales (documento, correo, teléfono…) | PK `IdEstudiante` · FK `IdPrograma` | **Alta** |
| `Profesor` | Datos de docentes | PK `IdProfesor` | **Alta** |
| `Materia` | Catálogo de materias | PK `IdMateria` · FK `IdPrograma` | Baja |
| `Grupo` | Curso abierto de una materia con un profesor | PK `IdGrupo` · FK `IdMateria`, `IdProfesor` | Media |
| `Matricula` | Inscripción, nota final y valor pagado | PK `IdMatricula` · FK `IdEstudiante`, `IdGrupo` · UNIQUE (estudiante, grupo) | **Alta** (tabla auditada) |

Además hay una tabla de seguridad:

| Tabla | Qué guarda | Quién la lee |
|---|---|---|
| `auditoria_log` | Historial de cambios (UPDATE/DELETE) en `Matricula` | Solo `auditor` y `admin_bd` |

**Registros clave de `Base_02` que usan las pruebas:**

| Registro | Para qué |
|---|---|
| Estudiante `1031422990` | Prueba de INSERT del operador en la Act. 1 (no está en el Grupo 1, a propósito) |
| Estudiante `1020304050` | Recién admitido, sin matrículas; lo usa `05_Datos_Prueba.sql` |
| Grupo `1` | Prueba de INSERT del operador en la Act. 1 |

---

## 🧠 Conceptos clave (para explicar)

### Autenticación vs autorización

- **Autenticación** = demostrar *quién eres*: usuario, contraseña y host.
- **Autorización** = decidir *qué puedes hacer* una vez dentro: los privilegios.

> 💬 **Para explicarlo:** la autenticación es el carné que te deja entrar al edificio; la autorización son las llaves de las oficinas a las que puedes pasar.

### Cuenta = `'usuario'@'host'`

En MySQL una cuenta no es solo un nombre:

- `'operador'@'localhost'` → solo puede conectarse desde el mismo servidor.
- `'operador'@'%'` → desde cualquier lugar (**peligroso** en producción).
- Ojo: son **dos cuentas distintas**, cada una con su contraseña y sus privilegios.

### GRANT y REVOKE

| Comando | Qué hace | Ejemplo |
|---|---|---|
| `GRANT` | **Otorga** un privilegio | `GRANT SELECT ON Guia_3.Estudiante TO 'analista'@'localhost';` |
| `REVOKE` | **Retira** un privilegio otorgado | `REVOKE SELECT ON Guia_3.Estudiante FROM 'analista'@'localhost';` |

Detalle de sintaxis: GRANT usa **TO** y REVOKE usa **FROM**.

### Niveles de alcance de un privilegio

| Alcance | Sintaxis | Ejemplo en el proyecto |
|---|---|---|
| Global (todo el servidor) | `ON *.*` | No se usa (solo root) |
| Esquema completo | `ON Guia_3.*` | `admin_bd` / `rol_admin` |
| Tabla específica | `ON Guia_3.Estudiante` | `analista`, `operador`, `auditor` |

### WITH GRANT OPTION

Permite que el usuario **otorgue a otros** los privilegios que tiene. Es un privilegio en sí mismo, así que para quitarlo hay que nombrarlo explícitamente: `REVOKE ..., GRANT OPTION`.

### Rol

Un **rol** es un "paquete" de privilegios con nombre. En vez de dar 18 privilegios a cada usuario, se le dan al rol y el rol se asigna al usuario.

- **Ventaja:** si mañana entran 10 operadores nuevos, basta con `GRANT 'rol_operador' TO ...`.
- **Ventaja:** un `REVOKE` sobre el rol afecta a **todos** sus usuarios a la vez.

### Privilegio directo vs heredado

| | Directo | Heredado (por rol) |
|---|---|---|
| Cómo se otorga | `GRANT SELECT ... TO 'usuario'@'host'` | `GRANT SELECT ... TO 'rol'` + `GRANT 'rol' TO 'usuario'@'host'` |
| Qué muestra `SHOW GRANTS FOR usuario` | El privilegio en sí | Solo `GRANT 'rol' TO usuario` |
| Cómo ver el detalle | Directamente | `SHOW GRANTS FOR usuario USING 'rol'` |
| Si se revoca al rol… | No le afecta | Lo pierde |
| Usuario de ejemplo | `auditor` | `admin_bd`, `analista`, `operador` |

### DEFAULT ROLE

Asignar un rol **no lo activa**. Sin `SET DEFAULT ROLE`, el usuario inicia sesión con el rol "disponible pero apagado" y recibe `ERROR 1142` aunque tenga el rol asignado. Por eso el script de la Actividad 2 lo activa por defecto.

---

## ✏️ Tarea previa — GRANT vs REVOKE

**Archivo:** `00_TareaPrevia_GRANT_vs_REVOKE.sql`

El script muestra **5 ejemplos que suben de complejidad**, y cada uno es un par GRANT/REVOKE sobre `Guia_3`:

| # | Qué se otorga | A quién | Sobre qué | Lección |
|---|---|---|---|---|
| 1 | `SELECT` | `analista` | `Estudiante` | El caso más granular: 1 privilegio, 1 tabla |
| 2 | `INSERT` | `operador` | `Matricula` | El REVOKE es **selectivo**: quita INSERT sin tocar SELECT ni UPDATE |
| 3 | `ALL PRIVILEGES` + `GRANT OPTION` | `admin_bd` | `Guia_3.*` | Alcance de esquema; `GRANT OPTION` se revoca aparte |
| 4 | `UPDATE` | `rol_operador` (rol) | `Grupo` | Efecto **en cascada**: afecta a todos los usuarios del rol |
| 5 | El rol `rol_consultor` completo | `analista` | — | Se otorga o retira un **paquete entero** de privilegios |

**Respuesta corta para el entregable:**
> **GRANT** otorga privilegios (o roles) a un usuario o rol; **REVOKE** los retira. Ambos definen el mismo triple *qué privilegio · sobre qué objeto · a quién*, pero en sentido contrario.

---

## 👥 Actividad 1 — Usuarios y privilegios

**Archivo:** `01_Actividad1_Usuarios_Privilegios.sql`

### Paso 0 — Preparación: `auditoria_log`

Se crea la tabla de auditoría **antes** que los usuarios, porque hace falta que exista para poder darle `SELECT` al `auditor`. Los triggers que la alimentan llegan en la Actividad 4.

```sql
CREATE TABLE IF NOT EXISTS auditoria_log (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    tabla         VARCHAR(64)  NOT NULL,
    operacion     ENUM('UPDATE','DELETE') NOT NULL,
    usuario       VARCHAR(100) NOT NULL,
    fecha         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dato_anterior JSON         NULL
);
```

### Paso 1 — Los 4 usuarios

| Usuario | Perfil | Analogía |
|---|---|---|
| `admin_bd@localhost` | Administrador del esquema | El director: tiene todas las llaves y puede hacer copias |
| `analista@localhost` | Consulta y reportes | El que lee los archivos, pero no escribe en ellos |
| `operador@localhost` | Trabajo diario (registrar y actualizar) | La secretaria: registra y corrige, pero no destruye |
| `auditor@localhost` | Revisión del historial | El revisor externo: solo ve la bitácora |

Todos usan `@'localhost'`: solo se pueden conectar desde el propio servidor.

### Paso 2 — Privilegios directos

| Usuario | Privilegios | Alcance | Por qué |
|---|---|---|---|
| `admin_bd` | `ALL PRIVILEGES` + `WITH GRANT OPTION` | `Guia_3.*` | Administra todo y puede delegar |
| `analista` | `SELECT` | Las 6 tablas, **una por una** | Solo lectura; queda fuera `auditoria_log` |
| `operador` | `SELECT, INSERT, UPDATE` | Las 6 tablas, una por una | Trabajo diario, **sin DELETE** para evitar pérdida de datos |
| `auditor` | `SELECT` | Solo `auditoria_log` | Revisa el historial, no los datos |

> 💡 **Decisión de diseño clave:** a `analista` y `operador` se les dan los permisos **tabla por tabla** y no con `Guia_3.*`. Si se usara `Guia_3.*`, también podrían leer `auditoria_log`, y quienes son auditados no deberían ver ni tocar su propia bitácora.

### Paso 3 — Matriz de permisos (entregable)

| Usuario | SELECT | INSERT | UPDATE | DELETE | Leer `auditoria_log` | GRANT OPTION |
|---|:-:|:-:|:-:|:-:|:-:|:-:|
| `admin_bd` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `analista` | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `operador` | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| `auditor` | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |

*(SELECT/INSERT/UPDATE/DELETE = sobre las 6 tablas operativas.)*

### Paso 4 — Pruebas de acceso

Hay que conectarse **como cada usuario** en una sesión nueva y capturar el resultado de cada línea.

| Usuario | Prueba | Resultado esperado |
|---|---|---|
| `admin_bd` | `SELECT`, `INSERT`, `DELETE` en `Programa` | ✅ OK |
| `admin_bd` | `SELECT * FROM auditoria_log` | ✅ OK |
| `admin_bd` | `GRANT INSERT ... TO analista` | ✅ OK (tiene GRANT OPTION) |
| `analista` | `SELECT * FROM Estudiante` | ✅ OK |
| `analista` | `INSERT INTO Programa ...` | ❌ ERROR 1142 |
| `analista` | `DELETE FROM Estudiante ...` | ❌ ERROR 1142 |
| `analista` | `SELECT * FROM auditoria_log` | ❌ ERROR 1142 |
| `operador` | `SELECT`, `INSERT`, `UPDATE` en `Matricula` | ✅ OK |
| `operador` | `DELETE FROM Matricula ...` | ❌ ERROR 1142 |
| `operador` | `SELECT * FROM auditoria_log` | ❌ ERROR 1142 |
| `auditor` | `SELECT * FROM auditoria_log` | ✅ OK |
| `auditor` | `SELECT * FROM Estudiante` | ❌ ERROR 1142 |
| `auditor` | `INSERT INTO auditoria_log ...` | ❌ ERROR 1142 (solo lectura) |

> 📸 **Para las capturas:** muestra en la misma imagen el comando y el error. Un `ERROR 1142` no es un fallo de la práctica: es la **prueba de que la seguridad funciona**.

---

## 🛡 Actividad 2 — Roles corporativos

**Archivo:** `02_Actividad2_Roles_Corporativos.sql`

### Paso 1 — Los 3 roles

| Rol | Equivale al perfil de | Privilegios |
|---|---|---|
| `rol_admin` | `admin_bd` | `ALL PRIVILEGES ON Guia_3.*` + `WITH GRANT OPTION` |
| `rol_consultor` | `analista` | `SELECT` en las 6 tablas operativas |
| `rol_operador` | `operador` | `SELECT, INSERT, UPDATE` en las 6 tablas operativas |

### Paso 2 — Migración de directo a heredado

El script **retira** los privilegios directos de la Actividad 1 y los reemplaza por roles:

```
ANTES (Act. 1)                            DESPUÉS (Act. 2)
admin_bd  ── privilegios directos   →     admin_bd  ── rol_admin     ── privilegios
analista  ── privilegios directos   →     analista  ── rol_consultor ── privilegios
operador  ── privilegios directos   →     operador  ── rol_operador  ── privilegios
auditor   ── privilegio directo     →     auditor   ── privilegio directo  (a propósito)
```

> 💡 **Por qué `auditor` no se toca:** queda como **grupo de control**. Tener un usuario con privilegio directo al lado de tres con privilegios heredados permite **demostrar la diferencia**, que es justo lo que pide la guía.

### Paso 3 — Asignar y activar

```sql
GRANT 'rol_operador' TO 'operador'@'localhost';          -- asigna
SET DEFAULT ROLE 'rol_operador' TO 'operador'@'localhost'; -- activa al iniciar sesión
```

### Paso 4 — Demostración directo vs heredado

| Comando | Qué se ve |
|---|---|
| `SHOW GRANTS FOR 'auditor'@'localhost';` | `GRANT SELECT ON Guia_3.auditoria_log ...`, es decir, el privilegio **tal cual** |
| `SHOW GRANTS FOR 'analista'@'localhost';` | Solo `GRANT rol_consultor TO analista` |
| `SHOW GRANTS FOR 'analista'@'localhost' USING 'rol_consultor';` | Ahora sí aparecen los 6 `SELECT` heredados |

### Paso 5 — Demostración del efecto en cascada

```sql
REVOKE INSERT ON Guia_3.Programa FROM 'rol_operador';
-- operador ya NO puede insertar en Programa → ERROR 1142
-- auditor no se ve afectado (su privilegio es directo)
GRANT INSERT ON Guia_3.Programa TO 'rol_operador';  -- se restaura
```

### Paso 6 — Pruebas

| Usuario | Prueba | Esperado |
|---|---|---|
| `operador` | `SELECT CURRENT_ROLE();` | `` `rol_operador`@`%` `` |
| `operador` | `DELETE FROM Matricula ...` | ❌ ERROR 1142 |
| `analista` | `SELECT CURRENT_ROLE();` | `` `rol_consultor`@`%` `` |
| `analista` | `INSERT INTO Programa ...` | ❌ ERROR 1142 |
| `analista` | `SELECT * FROM Estudiante` | ✅ OK |
| `auditor` | `SELECT * FROM Matricula` | ❌ ERROR 1142 |
| `auditor` | `SELECT * FROM auditoria_log` | ✅ OK |
| `admin_bd` | `SELECT CURRENT_ROLE();` | `` `rol_admin`@`%` `` |
| `admin_bd` | `GRANT INSERT ... TO analista` | ✅ OK (GRANT OPTION heredado del rol) |

> ❓ **Pregunta típica del profe:** *"¿Por qué el rol sale como `@'%'`?"*
> Porque en MySQL los roles se crean como cuentas sin host específico (`'%'`). Un rol no inicia sesión, así que su host no tiene efecto práctico.

---

## 🗺 Diagramas (MER, roles y matriz)

**Archivo:** `MER_Practica4_Seguridad.drawio` (se abre en [app.diagrams.net](https://app.diagrams.net) → *Archivo → Abrir*)

### Página 1 — MER completo (5 módulos)

| Módulo | Actividad | Entidades | Idea central |
|---|---|---|---|
| **A · Seguridad** | 1 y 2 | `USUARIO_BD`, `ROL`, `PRIVILEGIO`, `OBJETO_BD`, `USUARIO_ROL`, `PRIVILEGIO_DIRECTO`, `ROL_PRIVILEGIO` | Un privilegio llega a un usuario por **dos caminos**: directo o vía rol |
| **B · Sistema** | Base | `TABLA_PRINCIPAL` (placeholder) | Los objetos protegidos |
| **C · Auditoría** | 4 | `AUDITORIA_LOG` + 2 triggers | El log se llena solo, sin FK |
| **D · Inyección SQL** | 3 | Flujo app → BD | Concatenar ❌ vs parametrizar ✅ |
| **E · Informe** | 5 | Nota resumen | El diagrama *es* el mapa de seguridad |

**Relaciones del módulo A (cardinalidades):**

| Relación | Cardinalidad | Lectura |
|---|---|---|
| `USUARIO_BD` — `USUARIO_ROL` — `ROL` | M:N | Un usuario puede tener varios roles; un rol, varios usuarios |
| `ROL` → `ROL_PRIVILEGIO` | 1:N | Un rol agrupa muchos privilegios |
| `USUARIO_BD` → `PRIVILEGIO_DIRECTO` | 1:N | Un usuario puede recibir muchos privilegios directos |
| `PRIVILEGIO` → `PRIVILEGIO_DIRECTO` / `ROL_PRIVILEGIO` | 1:N | Un tipo de privilegio se otorga muchas veces |
| `OBJETO_BD` → `PRIVILEGIO_DIRECTO` / `ROL_PRIVILEGIO` | 1:N | Sobre un objeto se dan muchos permisos |

> ⚠️ **Aclaración importante (para que no te la hagan en la sustentación):** el módulo A es un **modelo conceptual**. Esas tablas **no se crean a mano**: MySQL las gestiona internamente (`mysql.user`, `mysql.role_edges`, `mysql.default_roles`, `mysql.tables_priv`) cada vez que ejecutas `CREATE USER`, `GRANT` o `REVOKE`. El MER explica **cómo funciona** ese catálogo.

**¿Por qué `AUDITORIA_LOG` no tiene FK hacia las tablas auditadas?**
1. Si tuviera FK, al hacer `DELETE` del registro original el log **fallaría** o **se borraría en cascada**, y justo se perdería lo que se quiere guardar.
2. `usuario` se guarda como texto (`'operador@localhost'`) para que el historial sobreviva aunque la cuenta se elimine.

### Página 2 — Diagrama de roles y usuarios (entregable Act. 2)

Muestra la cadena `usuario → rol → privilegios`. Las líneas sólidas indican herencia por rol y la roja punteada, el privilegio directo del `auditor`.

### Página 3 — Matriz de permisos (entregable Act. 1)

Es la misma matriz de la [Actividad 1](#paso-3--matriz-de-permisos-entregable), en formato visual.

---

## 💉 Actividad 3 — Prevención de inyección SQL

**Archivo:** `03_Actividad3_SQL_Injection.py`

```bash
pip install mysql-connector-python
export DB_PASS='Operador_2026!'        # Windows PowerShell: $env:DB_PASS = 'Operador_2026!'
python 03_Actividad3_SQL_Injection.py
```

La contraseña **no está escrita en el código**: se lee de una variable de entorno o se pide por teclado (recomendación #11 de la guía).

### Las 2 consultas vulnerables y su ataque

| # | Consulta | Ataque | Qué logra el atacante (ANTES) | DESPUÉS |
|---|---|---|---|---|
| 1 | Buscar estudiante por documento | **Tautología**: `' OR '1'='1` | Ver los **15 estudiantes** con sus datos personales | 0 filas |
| 2 | Consultar notas de un estudiante | **UNION**: `0 UNION SELECT IdProfesor, CONCAT(...), Correo FROM Profesor` | Ver los **datos de los profesores** en la pantalla de notas | 0 filas |

### ANTES vs DESPUÉS

```python
# ❌ ANTES — el input se pega dentro del SQL
cur.execute(f"SELECT ... FROM Estudiante WHERE IdEstudiante = '{documento}'")
# con ' OR '1'='1  →  ... WHERE IdEstudiante = '' OR '1'='1'  → TODAS las filas

# ✅ DESPUÉS — prepared statement real
cur = conn.cursor(prepared=True)
cur.execute("SELECT ... FROM Estudiante WHERE IdEstudiante = %s", (documento,))
# ' OR '1'='1 se busca como texto literal → 0 filas
```

### Por qué funciona el prepared statement

La consulta viaja al servidor **en dos partes separadas**:
1. **La estructura** (`... WHERE IdEstudiante = ?`), que el servidor compila primero.
2. **Los datos**, que se insertan después **solo como valor**.

Como la estructura ya está fijada, el dato **nunca puede cambiar la lógica** de la consulta. El script lo demuestra ejecutando el prepared statement **con y sin** validación: en los dos casos el ataque falla.

### Defensa en profundidad

1. **Prepared statements**, la defensa principal.
2. **Validación de entrada**: un documento solo admite dígitos (`isdigit()`).
3. **Mínimo privilegio**: la app se conecta como `operador`, nunca como root. Aunque una inyección pasara, no podría borrar datos ni leer `auditoria_log`.

---

## 📜 Actividad 4 — Trigger de auditoría

**Archivo:** `04_Actividad4_Trigger_Auditoria.sql`

| Trigger | Evento | Tabla | Qué registra |
|---|---|---|---|
| `trg_matricula_au` | `AFTER UPDATE` | `Matricula` | `operacion='UPDATE'` + la fila **antes** del cambio |
| `trg_matricula_ad` | `AFTER DELETE` | `Matricula` | `operacion='DELETE'` + la fila borrada completa |
| `trg_log_bu` / `trg_log_bd` | `BEFORE UPDATE/DELETE` | `auditoria_log` | **Extra**: bloquea cualquier modificación del log (ni el admin puede borrar evidencia) |

**Qué va en cada columna:**

| Columna | Valor | Por qué |
|---|---|---|
| `tabla` | `'Matricula'` | Qué tabla cambió |
| `operacion` | `'UPDATE'` / `'DELETE'` | Qué tipo de cambio |
| `usuario` | `USER()` | Quién lo hizo (ver la nota siguiente) |
| `fecha` | `NOW()` | Cuándo |
| `dato_anterior` | `JSON_OBJECT(... OLD.* ...)` | Cómo estaba antes: permite reconstruir el registro |

> ⚠️ **`USER()` y no `CURRENT_USER()`:** dentro de un trigger, `CURRENT_USER()` devuelve el **definer** del trigger (root), no a quien hizo el cambio. `USER()` devuelve la cuenta que realmente se conectó (`operador@localhost`). Es una pregunta típica de sustentación.

> 💡 **Por qué el operador no necesita permisos sobre el log:** el trigger se ejecuta con los privilegios de su definer (root). Por eso `operador` hace UPDATE en `Matricula` y el log se llena solo, sin que `operador` pueda leerlo ni tocarlo. **No hay forma de saltarse la auditoría.**

> 💡 **Por qué `Matricula`:** tiene notas y dinero; es donde un cambio no autorizado haría más daño.

**Resultado esperado tras la Parte 3 del `05`:**

| operacion | usuario | dato_anterior |
|---|---|---|
| UPDATE | `operador@localhost` | `{"IdMatricula": 9990, "NotaFinal": null, ...}` |
| UPDATE | `operador@localhost` | `{"IdMatricula": 9991, ...}` |
| DELETE | `admin_bd@localhost` | `{"IdMatricula": 9992, ...}` |

**Leer campos del JSON:**
```sql
SELECT id, operacion, usuario,
       dato_anterior->>'$.IdMatricula' AS matricula,
       dato_anterior->>'$.NotaFinal'   AS nota_anterior
FROM auditoria_log ORDER BY id;
```

---

## 📋 Actividad 5 — Informe de seguridad

**Estado:** ⏳ pendiente. **Entregable:** `Practica4_NombreEquipo.pdf`

### Estructura exigida por la guía

1. Portada (institución, asignatura, guía, integrantes, fecha)
2. Introducción
3. Caso de estudio (`Guia_3`)
4. Desarrollo con **capturas** de cada actividad
5. Tarea previa resuelta + reflexión
6. Conclusiones y análisis crítico
7. Código SQL completo y comentado
8. Referencias APA 7

### Recomendaciones para producción (sección obligatoria)

| # | Recomendación | Por qué |
|---|---|---|
| 1 | No usar `root` para la aplicación ni el trabajo diario | Si se compromete, se compromete todo |
| 2 | Restringir el host (`'localhost'` o IP concreta, nunca `'%'`) | Reduce desde dónde se puede atacar |
| 3 | Contraseñas fuertes con expiración (`PASSWORD EXPIRE INTERVAL 90 DAY`) | Limita el daño de una contraseña filtrada |
| 4 | Nunca guardar contraseñas en texto plano en scripts ni código | Recomendación #11 de la guía; usar variables de entorno o un gestor de secretos |
| 5 | Usar roles en lugar de privilegios directos | Más fácil de mantener y de auditar |
| 6 | Revisar privilegios periódicamente (`SHOW GRANTS`) | Evita permisos acumulados que nadie usa |
| 7 | Proteger `auditoria_log`: nadie que sea auditado debe poder modificarlo | Un log editable no sirve como evidencia |
| 8 | Conexiones cifradas (TLS) | Evita que las credenciales viajen en claro |
| 9 | Consultas parametrizadas en toda la aplicación | Previene inyección SQL |
| 10 | Backups del log y de la base | Recuperación ante incidentes |

---

## 🧯 Errores comunes y cómo resolverlos

| Error | Causa probable | Solución |
|---|---|---|
| `ERROR 1142: ... command denied` | **Esperado** en las pruebas negativas; si aparece donde debía funcionar, falta el privilegio o el rol está inactivo | Revisa `SHOW GRANTS` y `SELECT CURRENT_ROLE();` |
| El usuario tiene el rol pero recibe 1142 | El rol no está activo | `SET DEFAULT ROLE ...` o, dentro de la sesión, `SET ROLE ALL;` |
| `CURRENT_ROLE()` devuelve `NONE` | Igual que el anterior | Igual que el anterior |
| `ERROR 1044: Access denied ... to database` | El usuario no tiene ningún privilegio sobre `Guia_3` | Normal para `auditor` en algunas herramientas; usa `USE Guia_3;` y consulta solo `auditoria_log` |
| `ERROR 1396: Operation CREATE USER failed` | El usuario ya existe | El script usa `IF NOT EXISTS`; para reiniciar: `DROP USER` |
| `ERROR 1452` en el INSERT de prueba de `Matricula` | `IdEstudiante` o `IdGrupo` no existen | Usa IDs reales de `Datos.sql` |
| `REVOKE` no quita `WITH GRANT OPTION` | `GRANT OPTION` es un privilegio aparte | `REVOKE ..., GRANT OPTION FROM ...` |
| Workbench sigue mostrando permisos viejos | La conexión se abrió antes del cambio | Cierra y vuelve a abrir la conexión |

---

## 🔄 Compatibilidad MySQL 8 vs MariaDB

Los scripts están escritos para **MySQL 8** (lo que pide la guía). Si los ejecutas en **MariaDB**, hay diferencias de sintaxis:

| Qué | MySQL 8 | MariaDB |
|---|---|---|
| Crear varios roles | `CREATE ROLE 'a', 'b', 'c';` | Uno por sentencia: `CREATE ROLE a;` |
| Rol por defecto | `SET DEFAULT ROLE 'r' TO 'u'@'h';` | `SET DEFAULT ROLE r FOR 'u'@'h';` |
| Ver privilegios de un rol | `SHOW GRANTS FOR u USING 'r';` | No existe `USING`: `SHOW GRANTS FOR r;` |
| `CURRENT_ROLE()` | `` `rol`@`%` `` | `rol` |
| Tipo `JSON` | Nativo | Alias de `LONGTEXT` (funciona igual para esta práctica) |

---

## 🩺 Observaciones y correcciones

**Ya corregido en esta versión:**
- ✅ La tarea previa ya no deja privilegios directos: los ejemplos 1-3 terminan en REVOKE y los comentarios explican que el privilegio heredado se conserva.
- ✅ El trigger usa `USER()` (con `CURRENT_USER()` todo el log saldría como root).
- ✅ Los datos de prueba usan un estudiante sin matrículas, así que nunca chocan con el `UNIQUE (IdEstudiante, IdGrupo)`.

**Pendiente antes de entregar:**
1. **Contraseñas en texto plano en el script de la Act. 1.** Contradicen la recomendación #11 de la guía. En la versión entregada conviene reemplazarlas por marcadores (`'<CAMBIAR>'`) y explicarlo en el informe.
2. **`FLUSH PRIVILEGES` es innecesario** después de `GRANT`/`REVOKE`. No es un error, solo redundante.
3. **Diagrama, página 2:** cambiar `bd_sistema.*` por `Guia_3` y "las 6 tablas operativas".
4. **Diagrama, página 1:** reemplazar `TABLA_PRINCIPAL` por `Matricula` y sus columnas, y usar `USER()` en `AUDITORIA_LOG.usuario`.
5. **Repetir las capturas** de la tarea previa con la versión corregida.

---

## 🎤 Guion para explicarlo en clase

**En 2 minutos, en este orden:**

1. **El problema** (15 s): *"Una base con una sola cuenta root es como un edificio con una única llave maestra que todos comparten."*
2. **Usuarios** (20 s): *"Creamos 4 cuentas con el principio de mínimo privilegio; cada una tiene solo lo que su trabajo necesita."* → mostrar la matriz.
3. **La prueba** (20 s): *"Cuando operador intenta borrar, MySQL responde ERROR 1142. Ese error es la evidencia de que funciona."*
4. **Roles** (25 s): *"En vez de repetir 18 GRANT por persona, los agrupamos en roles. Un solo REVOKE al rol afecta a todos a la vez."* → mostrar la demostración en cascada.
5. **Directo vs heredado** (20 s): *"Dejamos al auditor con privilegio directo como grupo de control: SHOW GRANTS lo muestra tal cual, mientras que en los demás solo aparece el rol."*
6. **Auditoría e inyección** (20 s): *"El log se llena solo con triggers y no tiene FK, para que sobreviva a los DELETE. La app usa consultas parametrizadas y se conecta sin root."*

### Preguntas probables y respuestas cortas

| Pregunta | Respuesta |
|---|---|
| ¿Autenticación vs autorización? | Quién eres (usuario@host + contraseña) vs qué puedes hacer (privilegios) |
| ¿Riesgo de usar root en producción? | Control total: un error o un ataque compromete todo el servidor |
| ¿Por qué el operador no tiene DELETE? | Para evitar pérdida accidental o maliciosa de datos; borrar queda para el admin |
| ¿Por qué no `Guia_3.*` para el analista? | Porque incluiría `auditoria_log`, y los auditados no deben ver su bitácora |
| ¿Qué pasa si no se hace `SET DEFAULT ROLE`? | El rol queda asignado pero inactivo, y el usuario recibe ERROR 1142 |
| ¿Cómo protege un prepared statement? | Separa estructura y datos: el dato nunca se ejecuta como código |
| ¿Por qué el log no tiene FK? | Un DELETE rompería o borraría el historial |

---

## 📚 Referencias (APA 7)

- Elmasri, R., & Navathe, S. B. (2016). *Fundamentals of database systems* (7th ed.). Pearson.
- Silberschatz, A., Korth, H. F., & Sudarshan, S. (2019). *Database system concepts* (7th ed.). McGraw-Hill.
- OWASP Foundation. (2023). *SQL injection prevention cheat sheet*. https://cheatsheetseries.owasp.org/
- Oracle Corporation. (2024). *MySQL 8.0 security guide*. https://dev.mysql.com/doc/mysql-security-excerpt/en/
- Beaulieu, A. (2020). *Learning SQL* (3rd ed.). O'Reilly Media.
