-- Practica 4 - Actividad 5: Mapa de seguridad del sistema Guia_3
-- Requiere: 01_Tablas, 02_Datos, Actividad 1, Actividad 2, tarea previa y Actividad 4.
-- Ejecutar como root. Solo consultas de lectura: no modifica nada.
-- Cada bloque = una captura para el informe.

USE Guia_3;

-- ============================================================================
-- 1. Inventario de cuentas (usuarios y roles)
--    En MySQL 8 un rol es una cuenta bloqueada y sin contrasena.
-- ============================================================================
SELECT  User                AS cuenta,
        Host                AS origen,
        IF(account_locked = 'Y' AND authentication_string = '', 'ROL', 'USUARIO') AS tipo,
        plugin              AS autenticacion,
        account_locked      AS bloqueada,
        password_expired    AS clave_expirada,
        password_last_changed AS ultimo_cambio_clave,
        password_lifetime   AS vigencia_dias
FROM    mysql.user
WHERE   User IN ('admin_bd','analista','operador','auditor',
                 'rol_admin','rol_consultor','rol_operador')
ORDER BY tipo DESC, cuenta;

-- ============================================================================
-- 2. Asignacion de roles a usuarios (aristas rol -> usuario)
-- ============================================================================
SELECT  re.FROM_USER          AS rol,
        re.TO_USER            AS usuario,
        re.TO_HOST            AS origen,
        re.WITH_ADMIN_OPTION  AS puede_reasignar_rol,
        IF(dr.USER IS NULL, 'NO', 'SI') AS activo_por_defecto
FROM    mysql.role_edges re
LEFT JOIN mysql.default_roles dr
       ON dr.USER = re.TO_USER AND dr.HOST = re.TO_HOST
      AND dr.DEFAULT_ROLE_USER = re.FROM_USER
ORDER BY rol;

-- ============================================================================
-- 3. Privilegios a nivel de ESQUEMA (Guia_3.*)
-- ============================================================================
SELECT  GRANTEE         AS beneficiario,
        GROUP_CONCAT(PRIVILEGE_TYPE ORDER BY PRIVILEGE_TYPE SEPARATOR ', ') AS privilegios,
        MAX(IS_GRANTABLE) AS con_grant_option
FROM    information_schema.SCHEMA_PRIVILEGES
WHERE   LOWER(TABLE_SCHEMA) = 'guia_3'
GROUP BY GRANTEE;

-- ============================================================================
-- 4. Privilegios a nivel de TABLA (matriz beneficiario x tabla)
-- ============================================================================
SELECT  CONCAT(User, '@', Host) AS beneficiario,
        Table_name              AS tabla,
        Table_priv              AS privilegios,
        Grantor                 AS otorgado_por
FROM    mysql.tables_priv
WHERE   LOWER(Db) = 'guia_3'
ORDER BY beneficiario, tabla;

-- ============================================================================
-- 5. Privilegios directos vs heredados (evidencia Actividad 2)
--    Sin USING se ve solo el rol; con USING se ven los permisos efectivos.
-- ============================================================================
SHOW GRANTS FOR 'auditor'@'localhost';                          -- directo
SHOW GRANTS FOR 'analista'@'localhost';                         -- solo el rol
SHOW GRANTS FOR 'analista'@'localhost' USING 'rol_consultor';   -- efectivo
SHOW GRANTS FOR 'operador'@'localhost' USING 'rol_operador';
SHOW GRANTS FOR 'admin_bd'@'localhost' USING 'rol_admin';

-- ============================================================================
-- 6. Cuentas con capacidad de delegar permisos (GRANT OPTION) - riesgo
-- ============================================================================
SELECT 'global'  AS nivel, CONCAT(User,'@',Host) AS cuenta FROM mysql.user WHERE Grant_priv = 'Y'
UNION ALL
SELECT 'esquema', CONCAT(User,'@',Host) FROM mysql.db WHERE Grant_priv = 'Y' AND LOWER(Db) = 'guia_3'
UNION ALL
SELECT 'tabla', CONCAT(User,'@',Host) FROM mysql.tables_priv
 WHERE FIND_IN_SET('Grant', Table_priv) AND LOWER(Db) = 'guia_3';

-- ============================================================================
-- 7. Mecanismos de auditoria: triggers instalados
-- ============================================================================
SELECT  TRIGGER_NAME        AS trigger_auditoria,
        ACTION_TIMING       AS momento,
        EVENT_MANIPULATION  AS evento,
        EVENT_OBJECT_TABLE  AS tabla_vigilada,
        DEFINER             AS se_ejecuta_como,
        CREATED             AS creado
FROM    information_schema.TRIGGERS
WHERE   LOWER(TRIGGER_SCHEMA) = 'guia_3'
ORDER BY tabla_vigilada, evento;

-- ============================================================================
-- 8. Resumen del log de auditoria (quien cambio que y cuando)
-- ============================================================================
SELECT  tabla, operacion, usuario,
        COUNT(*)   AS eventos,
        MIN(fecha) AS primer_evento,
        MAX(fecha) AS ultimo_evento
FROM    auditoria_log
GROUP BY tabla, operacion, usuario
ORDER BY tabla, operacion, usuario;

-- Detalle legible del dato anterior (ultimos 10 eventos)
SELECT  id, operacion, usuario, fecha,
        dato_anterior->>'$.IdEstudiante'   AS id_estudiante,
        dato_anterior->>'$.PrimerNombre'   AS nombre,
        dato_anterior->>'$.Telefono'       AS telefono_anterior,
        dato_anterior->>'$.Direccion'      AS direccion_anterior
FROM    auditoria_log
ORDER BY id DESC
LIMIT 10;

-- ============================================================================
-- 9. Postura de seguridad del servidor (hallazgos del informe)
-- ============================================================================
-- Cuentas anonimas o sin contrasena (deben ser 0 filas)
SELECT User, Host FROM mysql.user
WHERE (User = '' OR authentication_string = '')
  AND NOT (account_locked = 'Y');

-- Cuentas que aceptan conexion desde cualquier host
SELECT User, Host FROM mysql.user WHERE Host = '%' AND account_locked = 'N';

-- Politica de contrasenas, cifrado y otros parametros
SHOW VARIABLES WHERE Variable_name IN (
    'default_password_lifetime', 'require_secure_transport', 'have_ssl',
    'tls_version', 'local_infile', 'bind_address', 'partial_revokes',
    'activate_all_roles_on_login', 'sql_safe_updates', 'version'
) OR Variable_name LIKE 'validate_password%';
