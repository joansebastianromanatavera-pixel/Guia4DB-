-- Practica 4 - Actividad 1: Usuarios y privilegios directos
-- Sistema: Guia_3

USE Guia_3;

-- Tabla de auditoria (minima, para poder otorgar SELECT a auditor)
CREATE TABLE IF NOT EXISTS auditoria_log (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    tabla           VARCHAR(64)   NOT NULL,
    operacion       ENUM('UPDATE','DELETE') NOT NULL,
    usuario         VARCHAR(100)  NOT NULL,
    fecha           DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dato_anterior   JSON          NULL
);

-- 1. Crear usuarios
CREATE USER IF NOT EXISTS 'admin_bd'@'localhost' IDENTIFIED BY 'AdminBD_2026!';
CREATE USER IF NOT EXISTS 'analista'@'localhost' IDENTIFIED BY 'Analista_2026!';
CREATE USER IF NOT EXISTS 'operador'@'localhost' IDENTIFIED BY 'Operador_2026!';
CREATE USER IF NOT EXISTS 'auditor'@'localhost'  IDENTIFIED BY 'Auditor_2026!';

-- 2. Privilegios directos por usuario

-- admin_bd: control total, puede otorgar permisos
GRANT ALL PRIVILEGES ON Guia_3.* TO 'admin_bd'@'localhost' WITH GRANT OPTION;

-- analista: solo lectura, tabla por tabla (excluye auditoria_log)
GRANT SELECT ON Guia_3.Programa   TO 'analista'@'localhost';
GRANT SELECT ON Guia_3.Estudiante TO 'analista'@'localhost';
GRANT SELECT ON Guia_3.Profesor   TO 'analista'@'localhost';
GRANT SELECT ON Guia_3.Materia    TO 'analista'@'localhost';
GRANT SELECT ON Guia_3.Grupo      TO 'analista'@'localhost';
GRANT SELECT ON Guia_3.Matricula  TO 'analista'@'localhost';

-- operador: lectura, insercion y actualizacion; sin DELETE
GRANT SELECT, INSERT, UPDATE ON Guia_3.Programa   TO 'operador'@'localhost';
GRANT SELECT, INSERT, UPDATE ON Guia_3.Estudiante TO 'operador'@'localhost';
GRANT SELECT, INSERT, UPDATE ON Guia_3.Profesor   TO 'operador'@'localhost';
GRANT SELECT, INSERT, UPDATE ON Guia_3.Materia    TO 'operador'@'localhost';
GRANT SELECT, INSERT, UPDATE ON Guia_3.Grupo      TO 'operador'@'localhost';
GRANT SELECT, INSERT, UPDATE ON Guia_3.Matricula  TO 'operador'@'localhost';

-- auditor: solo lectura del log
GRANT SELECT ON Guia_3.auditoria_log TO 'auditor'@'localhost';

FLUSH PRIVILEGES;

-- 3. Verificacion (capturas)
SHOW GRANTS FOR 'admin_bd'@'localhost';
SHOW GRANTS FOR 'analista'@'localhost';
SHOW GRANTS FOR 'operador'@'localhost';
SHOW GRANTS FOR 'auditor'@'localhost';

-- 4. Pruebas de acceso
-- Conectar con cada usuario en una sesion nueva y ejecutar su bloque.

-- admin_bd
-- SELECT * FROM Estudiante;                                     -- OK
-- INSERT INTO Programa (IdPrograma, Facultad, NombrePrograma, Duracion)
--   VALUES (999, 'Ingenieria', 'Prueba Admin', 8);               -- OK
-- DELETE FROM Programa WHERE IdPrograma = 999;                   -- OK
-- SELECT * FROM auditoria_log;                                   -- OK
-- GRANT INSERT ON Guia_3.Programa TO 'analista'@'localhost';     -- OK (GRANT OPTION)
-- REVOKE INSERT ON Guia_3.Programa FROM 'analista'@'localhost';  -- restaura

-- analista
-- SELECT * FROM Estudiante;                                      -- OK
-- INSERT INTO Programa (IdPrograma, Facultad, NombrePrograma, Duracion)
--   VALUES (998, 'Prueba', 'Prueba Analista', 4);                 -- ERROR 1142
-- DELETE FROM Estudiante WHERE IdEstudiante = 1;                  -- ERROR 1142
-- SELECT * FROM auditoria_log;                                    -- ERROR 1142

-- operador
-- SELECT * FROM Matricula;                                        -- OK
-- INSERT INTO Matricula (IdMatricula, IdEstudiante, IdGrupo, FechaMatricula, NotaFinal, ValorMatricula)
--   VALUES (9999, 1031422990, 1, CURDATE(), NULL, 500000);        -- OK
-- UPDATE Matricula SET NotaFinal = 4.5 WHERE IdMatricula = 9999;  -- OK
-- DELETE FROM Matricula WHERE IdMatricula = 9999;                 -- ERROR 1142
-- SELECT * FROM auditoria_log;                                    -- ERROR 1142

-- auditor
-- SELECT * FROM auditoria_log;                                    -- OK
-- SELECT * FROM Estudiante;                                       -- ERROR 1142
-- INSERT INTO auditoria_log (tabla, operacion, usuario, dato_anterior)
--   VALUES ('Prueba','DELETE','auditor', NULL);                   -- ERROR 1142
