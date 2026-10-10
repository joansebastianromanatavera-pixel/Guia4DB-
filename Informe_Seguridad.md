# Actividad 5 — Informe de Seguridad del Sistema `Guia_3`

**Universidad Manuela Beltrán · Bases de Datos · Guía de Laboratorio N.º 4**
**Eje temático:** Seguridad en BD — Usuarios, Privilegios, Roles y Auditoría
**SGBD:** MySQL 8.x · **Base de datos:** `Guia_3` (sistema académico de las Prácticas 1-3)
**Evidencia:** `Actividad 5/Scripts/05_Actividad5_Mapa_Seguridad.sql`

---

## 1. Objetivo y alcance

Este informe documenta el **mapa de seguridad** del sistema académico `Guia_3` tal como quedó tras las actividades 1 a 4: qué cuentas existen, qué roles agrupan sus permisos, qué puede hacer cada cuenta sobre cada tabla y qué mecanismos registran los cambios. También analiza los riesgos que siguen abiertos y propone las medidas necesarias para llevar el sistema a **producción**.

**Alcance:**

| Incluido | Fuera de alcance |
|---|---|
| 6 tablas de negocio: `Programa`, `Estudiante`, `Profesor`, `Materia`, `Grupo`, `Matricula` | Seguridad del sistema operativo y del hardware |
| Tabla de auditoría `auditoria_log` | Cuentas internas de MySQL (`mysql.sys`, `mysql.session`, etc.) |
| 4 usuarios, 3 roles, 2 triggers | Aplicaciones distintas a los scripts de la Actividad 3 |
| Código de acceso a datos (Python + MySQL Connector) | |

**Principio rector:** *mínimo privilegio*. Cada cuenta tiene solo los permisos que su función necesita (Elmasri & Navathe, 2016; Joint Task Force, 2020, control AC-6).

---

## 2. Arquitectura de seguridad por capas

La protección del sistema no depende de un solo control. Se organiza en capas, de modo que si una falla, la siguiente limita el daño (defensa en profundidad):

| # | Capa | Pregunta que responde | Control implementado | Actividad |
|:-:|---|---|---|:-:|
| 1 | **Autenticación** | ¿Quién eres y desde dónde te conectas? | `CREATE USER 'usuario'@'localhost' IDENTIFIED BY ...` (cuenta + host + contraseña) | 1 |
| 2 | **Autorización (DAC)** | ¿Qué puedes hacer y sobre qué objeto? | `GRANT` / `REVOKE` por tabla y por operación | 1 |
| 3 | **Autorización (RBAC)** | ¿Qué permisos corresponden a tu cargo? | Roles `rol_admin`, `rol_consultor`, `rol_operador` | 2 |
| 4 | **Aplicación** | ¿Puede un formulario inyectar SQL? | Consultas parametrizadas (prepared statements) | 3 |
| 5 | **Auditoría** | ¿Quién cambió qué, cuándo y qué había antes? | Triggers `AFTER UPDATE` / `AFTER DELETE` → `auditoria_log` | 4 |

---

## 3. Mapa de seguridad

### 3.1 Inventario de usuarios

| Usuario | Host permitido | Perfil / función | Origen de sus permisos | Alcance |
|---|---|---|---|---|
| `admin_bd` | `localhost` | DBA: administra el esquema y delega permisos | **Heredado** de `rol_admin` | `ALL PRIVILEGES` sobre `Guia_3.*` con `GRANT OPTION` |
| `analista` | `localhost` | Consulta y genera reportes; no modifica datos | **Heredado** de `rol_consultor` | `SELECT` sobre las 6 tablas de negocio |
| `operador` | `localhost` | Registra y corrige datos del día a día; no borra | **Heredado** de `rol_operador` | `SELECT, INSERT, UPDATE` sobre las 6 tablas de negocio |
| `auditor` | `localhost` | Revisa el rastro de cambios; independiente de la operación | **Directo** (sin rol) | `SELECT` sobre `auditoria_log` únicamente |

> **¿Por qué `@'localhost'`?** En MySQL una cuenta es el par *usuario + host*. Restringir el host a `localhost` significa que, aunque alguien robe la contraseña, no puede usarla desde otra máquina de la red. Es la primera barrera de autenticación.

**Evidencia:** Figura 5.1 (bloque 1 del script 05).

### 3.2 Inventario de roles

| Rol | Privilegios que agrupa | Asignado a | Activo por defecto |
|---|---|---|:-:|
| `rol_admin` | `ALL PRIVILEGES ON Guia_3.* WITH GRANT OPTION` | `admin_bd@localhost` | Sí |
| `rol_consultor` | `SELECT` sobre `Programa`, `Estudiante`, `Profesor`, `Materia`, `Grupo`, `Matricula` | `analista@localhost` | Sí |
| `rol_operador` | `SELECT, INSERT, UPDATE` sobre las mismas 6 tablas | `operador@localhost` | Sí |

En MySQL 8 un rol se guarda internamente como una cuenta **bloqueada y sin contraseña** (`account_locked = 'Y'`). Por eso aparece como `rol_consultor@%`: el `%` no es un riesgo, porque nadie puede iniciar sesión con un rol.

`SET DEFAULT ROLE` hace que el rol quede activo apenas el usuario se conecta. Sin esa instrucción el usuario tendría el rol asignado pero inactivo, y sus consultas fallarían con `ERROR 1142`.

**Evidencia:** Figura 5.2 (bloque 2 del script 05).

### 3.3 Diagrama de usuarios, roles y objetos

```
  USUARIOS                 ROLES                   OBJETOS (esquema Guia_3)
  ─────────                ─────                   ────────────────────────

  admin_bd@localhost ──▶ rol_admin ─────────▶ ALL PRIVILEGES + GRANT OPTION
                                                ├─ Programa, Estudiante, Profesor
                                                ├─ Materia, Grupo, Matricula
                                                └─ auditoria_log

  analista@localhost ──▶ rol_consultor ─────▶ SELECT
                                                └─ 6 tablas de negocio

  operador@localhost ──▶ rol_operador ──────▶ SELECT, INSERT, UPDATE (sin DELETE)
                                                └─ 6 tablas de negocio

  auditor@localhost  ┄┄┄┄┄┄┄ (directo) ┄┄┄┄┄▶ SELECT
                                                └─ auditoria_log

  ──▶ privilegio heredado por rol        ┄┄▶ privilegio directo
```

### 3.4 Matriz de privilegios efectivos

Leyenda: **S** = SELECT · **I** = INSERT · **U** = UPDATE · **D** = DELETE · **ALL** = todos los privilegios del esquema (incluye DDL: `CREATE`, `ALTER`, `DROP`, `TRIGGER`, …) · **G** = puede delegar (GRANT OPTION) · — = sin acceso

| Tabla | `admin_bd` | `analista` | `operador` | `auditor` |
|---|:-:|:-:|:-:|:-:|
| `Programa` | ALL + G | S | S I U | — |
| `Estudiante` | ALL + G | S | S I U | — |
| `Profesor` | ALL + G | S | S I U | — |
| `Materia` | ALL + G | S | S I U | — |
| `Grupo` | ALL + G | S | S I U | — |
| `Matricula` | ALL + G | S | S I U | — |
| `auditoria_log` | ALL + G | — | — | **S** |

**Decisiones de diseño:**

1. **`analista` y `operador` reciben permisos tabla por tabla, nunca con `Guia_3.*`.** Un comodín de esquema incluiría `auditoria_log` sin que nadie lo notara. Así el log queda fuera del alcance de quien opera los datos.
2. **`operador` no tiene `DELETE`.** Un error de digitación puede corregirse con `UPDATE`, pero un borrado es irreversible y puede romper la integridad referencial (`Matricula` → `Estudiante`). Borrar queda reservado al DBA.
3. **`auditor` no ve los datos de negocio.** Solo necesita el log para hacer su trabajo. Este es el principio de *necesidad de saber*.
4. **`operador` puede disparar los triggers sin tener `INSERT` sobre `auditoria_log`.** El trigger se ejecuta con los permisos de su `DEFINER`, no con los del usuario que hizo el cambio. Por eso el registro de auditoría ocurre aunque el operador no pueda escribir en el log, y tampoco puede falsificarlo.

**Resultado de las pruebas de acceso (Actividad 1 y 2):**

| Usuario | Puede | No puede (error obtenido) |
|---|---|---|
| `admin_bd` | Consultar, insertar, actualizar y borrar en todas las tablas; otorgar y revocar permisos | — |
| `analista` | `SELECT` en las 6 tablas de negocio | `INSERT`, `UPDATE`, `DELETE` en cualquier tabla y `SELECT` sobre `auditoria_log` → `ERROR 1142` |
| `operador` | `SELECT`, `INSERT`, `UPDATE` en las 6 tablas | `DELETE` en cualquier tabla y `SELECT` sobre `auditoria_log` → `ERROR 1142` |
| `auditor` | `SELECT` sobre `auditoria_log` | `SELECT` sobre cualquier tabla de negocio; `INSERT` en el log → `ERROR 1142` |

**Evidencia:** Figuras 5.3 y 5.4 (bloques 3 y 4 del script 05) y capturas de las Actividades 1 y 2.

### 3.5 Privilegio directo vs. privilegio heredado

| Aspecto | Directo (`auditor`) | Heredado por rol (`analista`, `operador`, `admin_bd`) |
|---|---|---|
| Cómo se otorga | `GRANT SELECT ON Guia_3.auditoria_log TO 'auditor'@'localhost'` | `GRANT ... TO 'rol_consultor'` y luego `GRANT 'rol_consultor' TO 'analista'@'localhost'` |
| Qué muestra `SHOW GRANTS FOR usuario` | El privilegio sobre la tabla | Solo la membresía: ``GRANT `rol_consultor`@`%` TO `analista`@`localhost` `` |
| Cómo ver los permisos reales | `SHOW GRANTS FOR usuario` | `SHOW GRANTS FOR usuario USING 'rol_consultor'` |
| Efecto de un `REVOKE` | Afecta solo a ese usuario | `REVOKE ... FROM 'rol_operador'` afecta **a todos** los miembros del rol al mismo tiempo |
| Mantenimiento | Una instrucción por usuario y por tabla | Se cambia el rol una vez y se propaga |
| Cuándo conviene | Excepciones puntuales, como una función única e independiente | Perfiles repetibles: varios analistas u operadores |

Para que la demostración fuera limpia, en la Actividad 2 se **retiraron los privilegios directos** que la Actividad 1 había dado a `admin_bd`, `analista` y `operador`. A partir de ese punto sus permisos vienen **solo** del rol. `auditor` se dejó con privilegio directo a propósito, como punto de contraste.

**Evidencia:** Figura 5.5 (bloque 5 del script 05).

### 3.6 Mecanismos de auditoría

**Tabla de log:**

| Columna | Tipo | Qué registra |
|---|---|---|
| `id` | `INT AUTO_INCREMENT` (PK) | Consecutivo del evento |
| `tabla` | `VARCHAR(64)` | Tabla afectada (`Estudiante`) |
| `operacion` | `ENUM('UPDATE','DELETE')` | Tipo de cambio |
| `usuario` | `VARCHAR(100)` | Cuenta que ejecutó el cambio (`USER()`, por ejemplo `operador@localhost`) |
| `fecha` | `DATETIME` | Momento del cambio (`NOW()`) |
| `dato_anterior` | `JSON` | Fila completa **antes** del cambio (valores `OLD.*`) |

**Triggers instalados:**

| Trigger | Momento | Evento | Tabla vigilada | Se ejecuta como |
|---|:-:|:-:|---|---|
| `trg_auditoria_estudiante_update` | `AFTER` | `UPDATE` | `Estudiante` | `root@localhost` (DEFINER) |
| `trg_auditoria_estudiante_delete` | `AFTER` | `DELETE` | `Estudiante` | `root@localhost` (DEFINER) |

**Flujo de un evento auditado:**

```
 operador@localhost                     MySQL                                   auditoria_log
 ──────────────────                     ─────                                   ─────────────
 UPDATE Estudiante SET Telefono=...  ─▶ 1. Verifica privilegio UPDATE (rol_operador) ✔
                                        2. Modifica la fila
                                        3. Dispara trg_auditoria_estudiante_update
                                           (corre con permisos del DEFINER)
                                        4. INSERT INTO auditoria_log  ─────────▶ id=1, UPDATE,
                                                                                operador@localhost,
                                                                                2026-10-.., {OLD...}
```

**Por qué `AFTER` y no `BEFORE`:** el trigger `AFTER` solo se ejecuta si la operación tuvo éxito. Si el `UPDATE` falla por una restricción, no queda un evento falso en el log. Además, el trigger y la operación son una sola unidad: si el `INSERT` en el log fallara, el cambio se revierte (en InnoDB). Así no puede haber cambios sin rastro.

**`USER()` vs `CURRENT_USER()` (corrección aplicada):** dentro de un trigger, `CURRENT_USER()` devuelve la cuenta **DEFINER**, es decir quien creó el trigger (`root`), y no quien hizo el cambio (Oracle, 2024c). Con esa función todos los eventos quedaban registrados como `root@localhost` y la columna `usuario` no servía para rastrear responsables. El script final usa `USER()`, que devuelve la cuenta de la sesión que ejecutó la sentencia.

**Ejemplo de registro:**

```json
{
  "IdEstudiante": 1099887766, "PrimerNombre": "Laura", "SegundoNombre": "Camila",
  "PrimerApellido": "Gomez", "SegundoApellido": "Rojas",
  "CorreoEstudiante": "laura.gomez@academia.umb.edu.co",
  "PrefijoTelefono": "+57", "Telefono": "3201122334",
  "FechaNacimiento": "2004-06-20", "Direccion": "Calle 100 #15-20"
}
```

Con este JSON es posible **reconstruir** el valor previo de cualquier fila modificada o eliminada, no solo saber que cambió.

**Evidencia:** Figuras 5.6 y 5.7 (bloques 7 y 8 del script 05) y capturas de la Actividad 4.

### 3.7 Control en la capa de aplicación (Actividad 3)

| | Antes (vulnerable) | Después (seguro) |
|---|---|---|
| Construcción | `f"... WHERE IdEstudiante = '{entrada}'"` | `"... WHERE IdEstudiante = %s"` + tupla de parámetros |
| Entrada `1031422990' OR '1'='1` | El `OR '1'='1'` se ejecuta como SQL y devuelve **toda** la tabla | Se trata como un valor literal: a lo sumo devuelve el registro exacto |
| Entrada `1031422990 OR 1=1 -- ` | El `--` comenta el `AND IdMatricula = ...` y se pierde el filtro | El `AND` se mantiene; la entrada no altera la estructura |
| Por qué funciona | Datos y código viajan mezclados en un solo texto | La estructura de la consulta queda fija antes de recibir los datos; los datos nunca se interpretan como código |

**Validación de entrada como segunda línea de defensa:** al comparar una cadena con una columna `INT`, MySQL la convierte a número tomando los dígitos iniciales (`'1031422990'' OR ...'` → `1031422990`). La consulta parametrizada ya impide la inyección, pero validar el tipo antes de consultar (`entrada.isdigit()`) rechaza entradas malformadas antes de que lleguen a la base de datos. OWASP (2023) recomienda combinar ambas medidas.

---

## 4. Evidencias del mapa de seguridad

Ejecutar `05_Actividad5_Mapa_Seguridad.sql` como `root` y capturar cada bloque:

| Figura | Bloque del script | Qué demuestra |
|:-:|:-:|---|
| 5.1 | 1 | Inventario de cuentas: 4 usuarios y 3 roles (bloqueados) |
| 5.2 | 2 | Asignación rol → usuario y roles activos por defecto |
| 5.3 | 3 | Privilegios a nivel de esquema (solo `rol_admin` tiene `Guia_3.*`) |
| 5.4 | 4 | Privilegios a nivel de tabla (matriz de la sección 3.4) |
| 5.5 | 5 | Directo vs heredado (`SHOW GRANTS` con y sin `USING`) |
| 5.6 | 6 | Cuentas con `GRANT OPTION` (insumo del hallazgo H2) |
| 5.7 | 7 | Triggers de auditoría instalados y su `DEFINER` |
| 5.8 | 8 | Resumen y detalle del log: quién, qué y cuándo |
| 5.9 | 9 | Postura del servidor: cuentas anónimas, host `%`, política de claves, TLS |

> El script solo **consulta** el catálogo (`mysql.user`, `mysql.role_edges`, `mysql.default_roles`, `mysql.tables_priv`, `information_schema`). No modifica la configuración del SGBD, en línea con la recomendación 5 del laboratorio.

---

## 5. Análisis de riesgos (hallazgos)

Severidad: **Alta** = permite fraude, fuga masiva o pérdida de evidencia · **Media** = facilita un ataque o expone datos personales · **Baja** = buena práctica pendiente.

| ID | Hallazgo | Riesgo concreto | Severidad | Estado |
|:-:|---|---|:-:|---|
| H1 | Contraseñas en texto plano en `01_Actividad1_Usuarios_Privilegios.sql` y en el README | Cualquier persona con acceso al repositorio o a la entrega obtiene las credenciales. Incumple la recomendación 11 de la guía | **Alta** | Abierto: aceptable solo en el laboratorio |
| H2 | `admin_bd` tiene `ALL` + `GRANT OPTION` sobre `Guia_3.*`, **incluida** `auditoria_log` | El administrador puede borrar o alterar el log que registra sus propios cambios, o hacer `DROP TRIGGER`. No hay separación de funciones | **Alta** | Abierto |
| H3 | El trigger registraba `CURRENT_USER()` (el DEFINER) | Todos los eventos aparecían como `root`: la auditoría no identificaba responsables | **Alta** | **Corregido** (`USER()`) |
| H4 | Los scripts de la Actividad 3 se conectan como `root` por defecto | Si la aplicación tuviera una inyección no detectada, el atacante tendría control total del servidor | **Alta** | Abierto |
| H5 | La auditoría cubre solo `Estudiante`, solo `UPDATE`/`DELETE`, y no guarda el valor nuevo | Cambios en `Matricula` (notas, valores) o inserciones fraudulentas no dejan rastro. `TRUNCATE` **no dispara** triggers `DELETE` | **Media** | Abierto |
| H6 | `analista` ve todos los datos personales: teléfono, dirección, correo, fecha de nacimiento, notas y valores | Exposición de datos personales sin necesidad de negocio (Ley 1581 de 2012) | **Media** | Abierto |
| H7 | Sin política de contraseñas, vencimiento ni bloqueo por intentos fallidos | Las contraseñas débiles o reutilizadas son vulnerables a fuerza bruta | **Media** | Abierto |
| H8 | No se exige conexión cifrada (TLS) | En red, las credenciales y los datos viajan en claro. Mitigado parcialmente por `@'localhost'` | **Media** | Abierto |
| H9 | `auditoria_log` vive en el mismo esquema que los datos y no tiene política de retención | Un `ALL ON Guia_3.*` siempre lo incluirá; el log crece sin control | **Baja** | Abierto |
| H10 | `fecha` usa `NOW()` (hora local del servidor) | Ambigüedad al correlacionar eventos entre servidores o con cambio de zona horaria | **Baja** | Abierto |
| H11 | Las entradas no se validaban antes de consultar | Comportamiento inesperado por conversión implícita de tipos | **Baja** | **Corregido** (validación `isdigit()`) |

---

## 6. Recomendaciones para producción

Las recomendaciones siguen el orden de las capas de la sección 2. Cada una indica qué hallazgo resuelve. Los fragmentos SQL son para **MySQL 8.0.19 o superior** y **no** se ejecutaron en el laboratorio, porque cambian la configuración del SGBD.

### 6.1 Autenticación

**R1. Ninguna contraseña en el código (H1).** Generar la contraseña en el servidor y entregarla por un canal seguro, o leerla de un gestor de secretos o de variables de entorno en la aplicación:

```sql
-- MySQL genera la clave y la muestra UNA sola vez; nunca queda escrita en el script
CREATE USER 'operador'@'localhost' IDENTIFIED BY RANDOM PASSWORD;
```

```python
# Aplicacion: la clave sale del entorno, no del codigo fuente
password = os.environ["DB_PASSWORD"]
```

**R2. Política de contraseñas, vencimiento y bloqueo (H7):**

```sql
INSTALL COMPONENT 'file://component_validate_password';
SET PERSIST validate_password.policy = 'STRONG';   -- mayusculas, numeros, simbolos
SET PERSIST validate_password.length = 12;

ALTER USER 'operador'@'localhost'
    PASSWORD EXPIRE INTERVAL 90 DAY      -- cambio obligatorio cada 90 dias
    PASSWORD HISTORY 5                   -- no reutilizar las 5 anteriores
    FAILED_LOGIN_ATTEMPTS 3              -- 3 intentos fallidos...
    PASSWORD_LOCK_TIME 1;                -- ...bloquean la cuenta 1 dia
```

**R3. Proteger y no usar `root` (H4).** Ejecutar `mysql_secure_installation`: elimina las cuentas anónimas y la base `test`, y limita `root` a `localhost`. `root` se reserva para emergencias. Ninguna aplicación ni persona lo usa en el día a día.

**R4. Cifrado en tránsito (H8):**

```sql
SET PERSIST require_secure_transport = ON;          -- rechaza conexiones sin TLS
ALTER USER 'admin_bd'@'localhost' REQUIRE SSL;
```

### 6.2 Autorización

**R5. Cuenta propia para la aplicación (H4).** La aplicación se conecta con una cuenta de mínimo privilegio, nunca con `root`. Se limita al host o subred del servidor de aplicaciones y a un número máximo de conexiones:

```sql
CREATE USER 'app_academico'@'10.0.0.%' IDENTIFIED BY RANDOM PASSWORD
    REQUIRE SSL WITH MAX_USER_CONNECTIONS 20;
GRANT 'rol_operador' TO 'app_academico'@'10.0.0.%';
SET DEFAULT ROLE 'rol_operador' TO 'app_academico'@'10.0.0.%';
```

**R6. Separación de funciones: sacar el log del alcance del DBA (H2, H9).** Mover `auditoria_log` a un esquema propio (`auditoria`) sobre el que `rol_admin` no tenga permisos. Los triggers usan como DEFINER una cuenta técnica bloqueada que solo puede **insertar**:

```sql
CREATE DATABASE auditoria;
-- (crear auditoria.auditoria_log con la misma estructura + dato_nuevo JSON)

CREATE USER 'trg_auditoria'@'localhost' ACCOUNT LOCK;     -- nadie puede iniciar sesion con ella
GRANT INSERT ON auditoria.auditoria_log TO 'trg_auditoria'@'localhost';
GRANT SELECT, TRIGGER ON Guia_3.Estudiante TO 'trg_auditoria'@'localhost';

-- Los triggers se recrean asi:
-- CREATE DEFINER = 'trg_auditoria'@'localhost' TRIGGER trg_auditoria_estudiante_update ...

GRANT SELECT ON auditoria.auditoria_log TO 'auditor'@'localhost';
```

Con esto, `admin_bd` sigue administrando `Guia_3.*` pero ya no puede tocar `auditoria.*`. Solo el auditor lee el log y solo los triggers escriben en él.

**R7. Retirar `GRANT OPTION` del rol administrativo (H2).** La delegación de permisos queda en una única cuenta DBA nominal, para que cada cambio de permisos tenga un responsable identificable:

```sql
REVOKE GRANT OPTION ON Guia_3.* FROM 'rol_admin';
```

**R8. Vistas y permisos por columna para datos personales (H6).** El analista trabaja con una vista que oculta o enmascara los datos sensibles, en lugar de la tabla base (Elmasri & Navathe, 2016, cap. 24: las vistas como mecanismo de seguridad):

```sql
CREATE SQL SECURITY DEFINER VIEW Guia_3.vw_estudiante_consulta AS
SELECT IdEstudiante,
       PrimerNombre, PrimerApellido,
       CONCAT('******', RIGHT(Telefono, 4))          AS Telefono,
       CONCAT(LEFT(CorreoEstudiante, 2), '***@***')  AS Correo
FROM   Guia_3.Estudiante;

REVOKE SELECT ON Guia_3.Estudiante FROM 'rol_consultor';
GRANT  SELECT ON Guia_3.vw_estudiante_consulta TO 'rol_consultor';

-- Alternativa: privilegio por columna
GRANT SELECT (IdEstudiante, PrimerNombre, PrimerApellido) ON Guia_3.Estudiante TO 'rol_consultor';
```

**R9. Revisión periódica de accesos.** Ejecutar el script `05_Actividad5_Mapa_Seguridad.sql` cada trimestre y cada vez que alguien cambie de cargo o salga de la organización. Las cuentas que ya no se usan se bloquean (`ALTER USER ... ACCOUNT LOCK`) antes de eliminarse.

### 6.3 Auditoría

**R10. Ampliar la cobertura (H5).** Crear triggers `AFTER INSERT`, `AFTER UPDATE` y `AFTER DELETE` en las tablas críticas, en especial `Matricula`, porque contiene `NotaFinal` y `ValorMatricula`, que son objetivos típicos de fraude. Agregar las columnas `dato_nuevo JSON` (valores `NEW.*`) y `host` para ver el antes y el después de cada cambio.

**R11. Hacer el log inalterable.** Aun con el permiso adecuado, nadie debería poder modificar ni borrar un evento:

```sql
-- Cuerpo de una sola sentencia: no requiere DELIMITER
CREATE TRIGGER trg_log_inmutable_upd BEFORE UPDATE ON auditoria.auditoria_log
FOR EACH ROW SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'auditoria_log es de solo insercion';

CREATE TRIGGER trg_log_inmutable_del BEFORE DELETE ON auditoria.auditoria_log
FOR EACH ROW SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'auditoria_log es de solo insercion';
```

**R12. Auditar lo que los triggers no ven.** Los triggers no capturan `SELECT`, `TRUNCATE`, `DROP`, cambios de permisos ni inicios de sesión fallidos. En producción conviene un plugin de auditoría del servidor (MySQL Enterprise Audit, Percona Audit Log Plugin o `server_audit` en MariaDB), que envíe los eventos a un sistema externo (SIEM) fuera del alcance del DBA.

**R13. Hora en UTC y retención (H10, H9).** Usar `UTC_TIMESTAMP()` en los triggers. Definir cuánto tiempo se conserva el log (por ejemplo, 5 años) y archivarlo por particiones mensuales.

### 6.4 Aplicación

**R14. Consultas parametrizadas obligatorias.** Ninguna consulta se arma concatenando texto (Actividad 3). Esto se verifica en revisión de código.

**R15. Validar entradas con lista blanca (H11).** Validar tipo, longitud y formato antes de consultar. Por ejemplo, el documento debe ser numérico y de 6 a 10 dígitos.

**R16. Mensajes de error genéricos.** Mostrar al usuario "Error al procesar la solicitud". El error SQL detallado va solo al log interno, porque revela nombres de tablas y columnas útiles para un atacante.

### 6.5 Operación e infraestructura

**R17. Red.** Configurar `bind-address` solo con la interfaz necesaria y abrir el puerto 3306 en el firewall únicamente para el servidor de aplicaciones. Desactivar `local_infile` (`SET PERSIST local_infile = OFF`) para impedir la lectura de archivos del cliente.

**R18. Copias de seguridad.** Programar `mysqldump --single-transaction --routines --triggers` diario, cifrar la copia, guardarla fuera del servidor y **probar la restauración** cada mes. Activar los *binary logs* para poder recuperar el estado en un momento puntual.

**R19. Actualizaciones.** Aplicar los parches de seguridad de MySQL cada trimestre (Oracle publica *Critical Patch Updates*).

### 6.6 Hoja de ruta priorizada

| Prioridad | Plazo | Recomendaciones | Hallazgos que cierra |
|:-:|---|---|---|
| 1 | Antes de salir a producción | R1, R3, R5, R6, R7, R14 | H1, H2, H4 |
| 2 | Primer mes | R2, R4, R8, R10, R11, R15, R16 | H5, H6, H7, H8, H11 |
| 3 | Primer trimestre | R9, R12, R13, R17, R18, R19 | H9, H10 |

---

## 7. Respuestas a las preguntas orientadoras

**¿Cuál es la diferencia entre autenticación y autorización?**
La autenticación verifica **quién** es el usuario: cuenta, host y contraseña (`CREATE USER`). La autorización decide **qué** puede hacer ese usuario ya identificado (`GRANT`/`REVOKE`, roles). En este sistema, `analista` se autentica correctamente, pero la autorización le niega el `INSERT` con `ERROR 1142`.

**¿Qué riesgos tiene usar `root` en producción?**
`root` tiene privilegios globales: puede leer, borrar o alterar cualquier base, crear cuentas, desactivar la auditoría y leer archivos del servidor. Si la aplicación usa `root` y sufre una inyección SQL, el atacante obtiene todo eso. Además, todos los cambios quedan a nombre de la misma cuenta, así que no hay trazabilidad (hallazgos H3 y H4).

**¿Cómo funciona la inyección SQL y qué la previene?**
Ocurre cuando la entrada del usuario se concatena dentro del texto de la consulta y el motor la interpreta como código (`' OR '1'='1`, `--`). Se previene con consultas parametrizadas, que separan estructura y datos. Se complementa con validación de entradas y con una cuenta de mínimo privilegio que limite el daño si algo falla (OWASP, 2023).

**¿Qué es un trigger de auditoría y cómo rastrea cambios?**
Es un procedimiento que el motor ejecuta automáticamente ante un evento (`UPDATE`, `DELETE`) en una tabla. Guarda en `auditoria_log` quién hizo el cambio, cuándo y cuál era el valor anterior (`OLD.*`). Como lo ejecuta el motor y no la aplicación, no se puede omitir desde el cliente.

---

## 8. Conclusiones

1. La combinación de **cuentas atadas a `localhost`**, **permisos por tabla** y **roles** permitió aplicar el principio de mínimo privilegio: cada perfil puede hacer exactamente su trabajo y las pruebas confirmaron con `ERROR 1142` todo lo que queda prohibido.
2. Los **roles** simplifican la administración: un solo `REVOKE` sobre `rol_operador` cambia los permisos de todos los operadores a la vez. El privilegio **directo** queda para casos excepcionales, como el del `auditor`.
3. Las **consultas parametrizadas** eliminan la inyección SQL de raíz porque los datos nunca se interpretan como código. La validación de entradas y una cuenta de aplicación sin privilegios administrativos completan la defensa.
4. La **auditoría por triggers** responde quién, qué, cuándo y qué había antes. La práctica también mostró un detalle técnico que la invalidaba: `CURRENT_USER()` registra al DEFINER del trigger y no a quien hizo el cambio, y se corrigió con `USER()`.
5. El riesgo más importante que queda es la **falta de separación de funciones**: el DBA puede alterar el log que lo vigila. En producción la auditoría debe vivir fuera de su alcance (R6, R11, R12).

---

## 9. Referencias (APA 7.ª ed.)

Congreso de la República de Colombia. (2012). *Ley Estatutaria 1581 de 2012, por la cual se dictan disposiciones generales para la protección de datos personales*. Diario Oficial No. 48.587.

Elmasri, R., & Navathe, S. B. (2016). *Fundamentals of database systems* (7th ed.). Pearson.

Joint Task Force. (2020). *Security and privacy controls for information systems and organizations* (NIST Special Publication 800-53, Rev. 5). National Institute of Standards and Technology. https://doi.org/10.6028/NIST.SP.800-53r5

Oracle. (2024a). *MySQL 8.0 reference manual: Using roles*. https://dev.mysql.com/doc/refman/8.0/en/roles.html

Oracle. (2024b). *MySQL 8.0 security guide*. https://dev.mysql.com/doc/mysql-security-excerpt/8.0/en/

Oracle. (2024c). *MySQL 8.0 reference manual: Stored object access control*. https://dev.mysql.com/doc/refman/8.0/en/stored-objects-security.html

Oracle. (2024d). *MySQL 8.0 reference manual: Password management*. https://dev.mysql.com/doc/refman/8.0/en/password-management.html

OWASP Foundation. (2023). *SQL injection prevention cheat sheet*. https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html

Silberschatz, A., Korth, H. F., & Sudarshan, S. (2019). *Database system concepts* (7th ed.). McGraw-Hill.
