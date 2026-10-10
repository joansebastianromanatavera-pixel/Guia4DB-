USE Guia_3;

-- 1. Limpieza de pruebas previas y desactivación de modo seguro temporal
SET SQL_SAFE_UPDATES = 0;
DELETE FROM Estudiante WHERE IdEstudiante = 1099887766;

-- 2. Insertar estudiante de prueba
INSERT INTO Estudiante (
    IdEstudiante, PrimerNombre, SegundoNombre, PrimerApellido, SegundoApellido,
    CorreoEstudiante, PrefijoTelefono, Telefono, FechaNacimiento, Direccion
) VALUES (
    1099887766, 'Laura', 'Camila', 'Gomez', 'Rojas',
    'laura.gomez@academia.umb.edu.co', '+57', '3201122334', '2004-06-20', 'Calle 100 #15-20'
);

-- 3. Simular UPDATE (Dispara trg_auditoria_estudiante_update)
UPDATE Estudiante 
SET Telefono = '3109988776', Direccion = 'Carrera 7 #72-41'
WHERE IdEstudiante = 1099887766;

-- 4. Simular DELETE (Dispara trg_auditoria_estudiante_delete)
DELETE FROM Estudiante 
WHERE IdEstudiante = 1099887766;

-- 5. Consulta para la captura de pantalla de resultados
SELECT 
    id, 
    tabla, 
    operacion, 
    usuario, 
    fecha, 
    dato_anterior 
FROM auditoria_log;
-- 6. Prueba con usuarios distintos (evidencia de "quien" hizo el cambio)
-- Conectar con cada usuario en una sesion nueva y ejecutar su bloque.

-- operador (tiene INSERT/UPDATE, no DELETE)
-- USE Guia_3;
-- INSERT INTO Estudiante (IdEstudiante, PrimerNombre, PrimerApellido, CorreoEstudiante)
--   VALUES (1099887767, 'Prueba', 'Auditoria', 'prueba@academia.umb.edu.co');
-- UPDATE Estudiante SET Telefono = '3000000000' WHERE IdEstudiante = 1099887767;  -- log: operador@localhost
-- DELETE FROM Estudiante WHERE IdEstudiante = 1099887767;                         -- ERROR 1142

-- admin_bd
-- USE Guia_3;
-- DELETE FROM Estudiante WHERE IdEstudiante = 1099887767;                         -- log: admin_bd@localhost

-- auditor
-- SELECT id, operacion, usuario, fecha FROM Guia_3.auditoria_log ORDER BY id;     -- OK, ve los 3 usuarios
