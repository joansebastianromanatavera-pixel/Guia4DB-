-- Tarea previa - Punto 1: GRANT vs REVOKE (5 ejemplos)
-- Requiere: 01_Actividad1_Usuarios_Privilegios.sql, 02_Actividad2_Roles_Corporativos.sql

USE Guia_3;

-- Ejemplo 1: privilegio puntual sobre una tabla
GRANT SELECT ON Guia_3.Estudiante TO 'analista'@'localhost';
REVOKE SELECT ON Guia_3.Estudiante FROM 'analista'@'localhost';
GRANT SELECT ON Guia_3.Estudiante TO 'analista'@'localhost';  -- restaura

-- Ejemplo 2: privilegio de escritura (REVOKE no afecta otros privilegios)
GRANT INSERT ON Guia_3.Matricula TO 'operador'@'localhost';
REVOKE INSERT ON Guia_3.Matricula FROM 'operador'@'localhost';
GRANT INSERT ON Guia_3.Matricula TO 'operador'@'localhost';  -- restaura

-- Ejemplo 3: esquema completo + GRANT OPTION (debe revocarse explicitamente)
GRANT ALL PRIVILEGES ON Guia_3.* TO 'admin_bd'@'localhost' WITH GRANT OPTION;
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'admin_bd'@'localhost';
GRANT ALL PRIVILEGES ON Guia_3.* TO 'admin_bd'@'localhost' WITH GRANT OPTION;  -- restaura

-- Ejemplo 4: privilegio sobre un ROL (afecta a todos sus usuarios)
GRANT UPDATE ON Guia_3.Grupo TO 'rol_operador';
REVOKE UPDATE ON Guia_3.Grupo FROM 'rol_operador';
GRANT UPDATE ON Guia_3.Grupo TO 'rol_operador';  -- restaura

-- Ejemplo 5: asignar/retirar un ROL completo a un usuario
GRANT 'rol_consultor' TO 'analista'@'localhost';
SET DEFAULT ROLE 'rol_consultor' TO 'analista'@'localhost';
REVOKE 'rol_consultor' FROM 'analista'@'localhost';
GRANT 'rol_consultor' TO 'analista'@'localhost';  -- restaura
SET DEFAULT ROLE 'rol_consultor' TO 'analista'@'localhost';

-- Limpieza: los ejemplos 1-3 dejaron privilegios DIRECTOS; se retiran para volver
-- al estado de la Actividad 2 (privilegios solo heredados por rol, salvo auditor)
REVOKE SELECT ON Guia_3.Estudiante FROM 'analista'@'localhost';
REVOKE INSERT ON Guia_3.Matricula  FROM 'operador'@'localhost';
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'admin_bd'@'localhost';

-- Verificacion final (debe verse igual que al cierre de Actividad 2)
SHOW GRANTS FOR 'admin_bd'@'localhost' USING 'rol_admin';
SHOW GRANTS FOR 'analista'@'localhost' USING 'rol_consultor';
SHOW GRANTS FOR 'operador'@'localhost' USING 'rol_operador';
SHOW GRANTS FOR 'auditor'@'localhost';
