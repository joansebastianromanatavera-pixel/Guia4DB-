create database if not exists Guia_3;

USE Guia_3;

drop table if exists Matricula;
drop table if exists Grupo;
drop table if exists Materia;
drop table if exists Profesor;
drop table if exists Estudiante;
drop table if exists Programa;

CREATE TABLE Programa (
    IdPrograma INT PRIMARY KEY,
    Facultad VARCHAR(50),
    NombrePrograma VARCHAR(50),
    Duracion INT
);

CREATE TABLE Estudiante (
    IdEstudiante INT PRIMARY KEY,
    PrimerNombre VARCHAR(50),
    SegundoNombre VARCHAR(50),
    PrimerApellido VARCHAR(50),
    SegundoApellido VARCHAR(50),
    CorreoEstudiante VARCHAR(80),
    PrefijoTelefono VARCHAR(5),
    Telefono VARCHAR(15),
    FechaNacimiento DATE,
    Direccion VARCHAR(80)
);

CREATE TABLE Profesor (
    IdProfesor INT PRIMARY KEY,
    PrimerNombreProfesor VARCHAR(50),
    SegundoNombreProfesor VARCHAR(50),
    PrimerApellidoProfesor VARCHAR(50),
    SegundoApellidoProfesor VARCHAR(50),
    CorreoProfesor VARCHAR(80),
    PrefijoTelefono VARCHAR(5),
    Telefono VARCHAR(15),
    FechaNacimiento DATE,
    Especialidad VARCHAR(60)
);

CREATE TABLE Materia (
    IdMateria INT PRIMARY KEY,
    NombreMateria VARCHAR(50),
    CreditosMateria INT,
    IdPrograma INT,
    FOREIGN KEY (IdPrograma) REFERENCES Programa(IdPrograma)
);

CREATE TABLE Grupo (
    IdGrupo INT PRIMARY KEY,
    IdMateria INT,
    IdProfesor INT,
    Periodo VARCHAR(20),
    Horario VARCHAR(40),
    Cupo INT,
    FOREIGN KEY (IdMateria) REFERENCES Materia(IdMateria),
    FOREIGN KEY (IdProfesor) REFERENCES Profesor(IdProfesor)
);

CREATE TABLE Matricula (
    IdMatricula INT PRIMARY KEY,
    IdEstudiante INT,
    IdGrupo INT,
    FechaMatricula DATE,
    NotaFinal DECIMAL(3,2),
    ValorMatricula INT,
    FOREIGN KEY (IdEstudiante) REFERENCES Estudiante(IdEstudiante),
    FOREIGN KEY (IdGrupo) REFERENCES Grupo(IdGrupo)
);
