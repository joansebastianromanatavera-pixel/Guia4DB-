USE Guia_3;

-- ============================================================================
-- 1. ESTRUCTURA DE LA TABLA auditoria_log
-- ============================================================================
CREATE TABLE IF NOT EXISTS auditoria_log (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    tabla         VARCHAR(64)              NOT NULL,
    operacion     ENUM('UPDATE', 'DELETE') NOT NULL,
    usuario       VARCHAR(100)             NOT NULL,
    fecha         DATETIME                 NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dato_anterior JSON                     NULL
);

-- ============================================================================
-- 2. TRIGGER AFTER UPDATE EN Estudiante
-- ============================================================================
DROP TRIGGER IF EXISTS trg_auditoria_estudiante_update;

DELIMITER $$
CREATE TRIGGER trg_auditoria_estudiante_update
AFTER UPDATE ON Estudiante
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_log (tabla, operacion, usuario, fecha, dato_anterior)
    VALUES (
        'Estudiante',
        'UPDATE',
        USER(),   -- cuenta que ejecuto el cambio (CURRENT_USER() daria el DEFINER del trigger)
        NOW(),
        JSON_OBJECT(
            'IdEstudiante', OLD.IdEstudiante,
            'PrimerNombre', OLD.PrimerNombre,
            'SegundoNombre', OLD.SegundoNombre,
            'PrimerApellido', OLD.PrimerApellido,
            'SegundoApellido', OLD.SegundoApellido,
            'CorreoEstudiante', OLD.CorreoEstudiante,
            'PrefijoTelefono', OLD.PrefijoTelefono,
            'Telefono', OLD.Telefono,
            'FechaNacimiento', OLD.FechaNacimiento,
            'Direccion', OLD.Direccion
        )
    );
END$$
DELIMITER ;

-- ============================================================================
-- 3. TRIGGER AFTER DELETE EN Estudiante
-- ============================================================================
DROP TRIGGER IF EXISTS trg_auditoria_estudiante_delete;

DELIMITER $$
CREATE TRIGGER trg_auditoria_estudiante_delete
AFTER DELETE ON Estudiante
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_log (tabla, operacion, usuario, fecha, dato_anterior)
    VALUES (
        'Estudiante',
        'DELETE',
        USER(),   -- cuenta que ejecuto el cambio (CURRENT_USER() daria el DEFINER del trigger)
        NOW(),
        JSON_OBJECT(
            'IdEstudiante', OLD.IdEstudiante,
            'PrimerNombre', OLD.PrimerNombre,
            'SegundoNombre', OLD.SegundoNombre,
            'PrimerApellido', OLD.PrimerApellido,
            'SegundoApellido', OLD.SegundoApellido,
            'CorreoEstudiante', OLD.CorreoEstudiante,
            'PrefijoTelefono', OLD.PrefijoTelefono,
            'Telefono', OLD.Telefono,
            'FechaNacimiento', OLD.FechaNacimiento,
            'Direccion', OLD.Direccion
        )
    );
END$$
DELIMITER ;