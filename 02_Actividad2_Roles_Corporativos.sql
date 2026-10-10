-- Practica 4 - Actividad 2: Roles corporativos
-- Requiere: 01_Actividad1_Usuarios_Privilegios.sql

USE Guia_3;

-- 1. Crear roles
CREATE ROLE IF NOT EXISTS 'rol_admin', 'rol_consultor', 'rol_operador';

-- 2. Privilegios por rol

-- rol_admin: control total
GRANT ALL PRIVILEGES ON Guia_3.* TO 'rol_admin' WITH GRANT OPTION;

-- rol_consultor: solo lectura, tabla por tabla (excluye auditoria_log)
GRANT SELECT ON Guia_3.Programa   TO 'rol_consultor';
GRANT SELECT ON Guia_3.Estudiante TO 'rol_consultor';
GRANT SELECT ON Guia_3.Profesor   TO 'rol_consultor';
GRANT SELECT ON Guia_3.Materia    TO 'rol_consultor';
GRANT SELECT ON Guia_3.Grupo      TO 'rol_consultor';
GRANT SELECT ON Guia_3.Matricula  TO 'rol_consultor';

-- rol_operador: lectura, insercion y actualizacion; sin DELETE
GRANT SELECT, INSERT, UPDATE ON Guia_3.Programa   TO 'rol_operador';
GRANT SELECT, INSERT, UPDATE ON Guia_3.Estudiante TO 'rol_operador';
GRANT SELECT, INSERT, UPDATE ON Guia_3.Profesor   TO 'rol_operador';
GRANT SELECT, INSERT, UPDATE ON Guia_3.Materia    TO 'rol_operador';
GRANT SELECT, INSERT, UPDATE ON Guia_3.Grupo      TO 'rol_operador';
GRANT SELECT, INSERT, UPDATE ON Guia_3.Matricula  TO 'rol_operador';

-- 3. Retirar privilegios directos de Actividad 1 (admin_bd, analista, operador)
-- auditor conserva el suyo a proposito, para contrastar directo vs rol
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'admin_bd'@'localhost';

REVOKE SELECT ON Guia_3.Programa   FROM 'analista'@'localhost';
REVOKE SELECT ON Guia_3.Estudiante FROM 'analista'@'localhost';
REVOKE SELECT ON Guia_3.Profesor   FROM 'analista'@'localhost';
REVOKE SELECT ON Guia_3.Materia    FROM 'analista'@'localhost';
REVOKE SELECT ON Guia_3.Grupo      FROM 'analista'@'localhost';
REVOKE SELECT ON Guia_3.Matricula  FROM 'analista'@'localhost';

REVOKE SELECT, INSERT, UPDATE ON Guia_3.Programa   FROM 'operador'@'localhost';
REVOKE SELECT, INSERT, UPDATE ON Guia_3.Estudiante FROM 'operador'@'localhost';
REVOKE SELECT, INSERT, UPDATE ON Guia_3.Profesor   FROM 'operador'@'localhost';
REVOKE SELECT, INSERT, UPDATE ON Guia_3.Materia    FROM 'operador'@'localhost';
REVOKE SELECT, INSERT, UPDATE ON Guia_3.Grupo      FROM 'operador'@'localhost';
REVOKE SELECT, INSERT, UPDATE ON Guia_3.Matricula  FROM 'operador'@'localhost';

-- 4. Asignar roles y activarlos por defecto
GRANT 'rol_admin'     TO 'admin_bd'@'localhost';
GRANT 'rol_consultor' TO 'analista'@'localhost';
GRANT 'rol_operador'  TO 'operador'@'localhost';

SET DEFAULT ROLE 'rol_admin'     TO 'admin_bd'@'localhost';
SET DEFAULT ROLE 'rol_consultor' TO 'analista'@'localhost';
SET DEFAULT ROLE 'rol_operador'  TO 'operador'@'localhost';

FLUSH PRIVILEGES;

-- 5. Verificacion: directo vs heredado por rol
SHOW GRANTS FOR 'auditor'@'localhost';                          -- directo
SHOW GRANTS FOR 'analista'@'localhost';                         -- solo muestra el rol
SHOW GRANTS FOR 'analista'@'localhost' USING 'rol_consultor';   -- privilegios reales
SHOW GRANTS FOR 'admin_bd'@'localhost';
SHOW GRANTS FOR 'admin_bd'@'localhost' USING 'rol_admin';
SHOW GRANTS FOR 'operador'@'localhost';
SHOW GRANTS FOR 'operador'@'localhost' USING 'rol_operador';

-- 6. Demostracion: REVOKE sobre un rol afecta a todos sus usuarios
REVOKE INSERT ON Guia_3.Programa FROM 'rol_operador';
-- operador ya no puede insertar en Programa
GRANT INSERT ON Guia_3.Programa TO 'rol_operador';  -- se restaura

-- 7. Pruebas de acceso
-- Conectar con cada usuario en una sesion nueva y ejecutar su bloque.

-- operador
-- SELECT CURRENT_ROLE();                                  -- rol_operador@%
-- DELETE FROM Guia_3.Matricula WHERE IdMatricula = 1;     -- ERROR 1142

-- analista
-- SELECT CURRENT_ROLE();                                  -- rol_consultor@%
-- INSERT INTO Guia_3.Programa (IdPrograma, Facultad, NombrePrograma, Duracion)
--   VALUES (996, 'x', 'x', 1);                             -- ERROR 1142
-- SELECT * FROM Guia_3.Estudiante;                         -- OK

-- auditor
-- SELECT * FROM Guia_3.Matricula;                          -- ERROR 1142
-- SELECT * FROM Guia_3.auditoria_log;                      -- OK

-- admin_bd
-- SELECT CURRENT_ROLE();                                   -- rol_admin@%
-- GRANT INSERT ON Guia_3.Programa TO 'analista'@'localhost';     -- OK
-- REVOKE INSERT ON Guia_3.Programa FROM 'analista'@'localhost';  -- restaura
