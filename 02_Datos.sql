use Guia_3;

set foreign_key_checks = 0;
truncate table Matricula;
truncate table Grupo;
truncate table Materia;
truncate table Profesor;
truncate table Estudiante;
truncate table Programa;
set foreign_key_checks = 1;

insert into Programa values (
    1,
    'Ingenieria',
    'Ingenieria de software',
    8
	),
	(
    2,
    'Salud',
    'Enfermeria',
    8
	),
	(
	3,
    'Artes',
    'Cine y television',
    8
	),
	(
	4,
    'Administración',
    'Administración de empresas',
    8
    ),
    (
	5,
    'Ciencias humanas y sociales',
    'Psicologia',
    8
    );

insert into Estudiante values (
    1031422990,
    'Juan',
    'Manuel',
    'Gamez',
    'Nieto',
    'juangamez.mn@academia.umb.edu.co',
    '+57',
    '3163561010',
    '2007-11-10',
    'Calle 157c #91-86'
	),
	(
	1011765342,
    'Esteban',
    null,
    'Salvador',
    'Guzman',
    'estebansalvador@academia.umb.edu.co',
    '+57',
    '3157271771',
    '1991-05-24',
    'Calle 80 #30-16'
    ),
    (
    1028886975,
	'Joan',
	'Sebastian',
	'Romagna',
	'Taverna',
	'joanromana.st@academia.umb.edu.co',
	'+57',
	'3238181755',
	'2007-12-18',
    'Calle 13 #19-01'
	),
    (
	1030281186,
    'Andres',
    'Felipe',
    'Dueñas',
    'Martinez',
    'andresduenas.fm@academima.umb.edu.co',
    '+57',
    '3178630693',
    '2007-07-19',
    null
    ),
    (
	1122151498,
    'Andres',
    'Eduardo',
    'Viafara',
    'Marchena',
    'andresviafara.em@academia.umb.edu.co',
    '+57',
    '3052480817',
    '2007-09-07',
    null
    );

insert into Profesor values (
    501,
    'John',
    'Leonardo',
    'Hernandez',
    'Matiz',
    'john.hernandezm@docentes.umb.edu.co',
    '+57',
    '3124213508', -- A.C
    '1971-12-15',
    'Entornos virtuales de aprendizaje'
	),
	(
    502,
    'Olga',
    'Lucia',
    'Roa',
    'Bohorquez',
    'olga.roa@docentes.umb.edu.co',
    '+57',
    '3135548965',
    '1975-06-21',
    'Magister en Ingeniería de sistemas y computación'
	),
	(
    503,
    'Julieth',
    'Ximena',
    'Reyes',
    'Sepúlveda',
    'julieth.reyes@docentes.umb.edu.co',
	'+57',
    '3168952310',
    '1980-11-01',
    null
	),
	(
	504,
    'María',
    'Fernanda',
    'Gómez',
    'Vásquez',
    'mariaf.gomez@docentes.umb.edu.co',
    '+57',
    '3135548965',
    '1901-02-20',
    null
    ),
    (
	505,
    'Jose',
    'Andrés',
    'Primiciero',
    'Matamoros',
    'jose.primiciero@docentes.umb.edu.co',
    '+57',
    '3135548965',
    '1575-04-18',
    null
    );

insert into Materia values (
    201,
    'Teoria de bases de datos',
    4,
    1
	),
	(
    202,
    'Taller de programacion',
    3,
    1
	),
	(
    203,
    'Probabilidad y estadistica',
    2,
    1
	),
	(
	204,
    'Taller de investigación cuantitativa',
    1,
    5
    ),
	(
	205,
    'Filosofia',
    2,
    5
    );

insert into Grupo values (
    1,
    201,
    501,
    '2026-2',
    'Martes 8-10 am y jueves 11-1 pm',
    null
);
insert into Grupo values (
    2,
    202,
    502,
    '2026-2',
    'Miercoles 2-4 pm',
    25
);
insert into Grupo values (
    3,
    203,
    503,
    '2026-2',
    'Martes 12-2 pm',
    null
);
insert into Grupo values (
	4,
    204,
    504,
    '2026-2',
    'Viernes 5-6 pm',
    80
    );
insert into Grupo values (
	5,
    205,
    505,
    '2025-1',
    'Jueves 9-11 am',
    null
    );

insert into Matricula values (
    1,
    1031422990,
    1,
    '2026-07-28',
    4.5,
    1200000.00
);
insert into Matricula values (
    2,
    1031422990,
    2,
    '2026-07-28',
    4.2,
    950000.00
);
insert into Matricula values (
    3,
    1031422990,
    3,
    '2026-07-28',
    3.9,
    700000.00
);
insert into Matricula values (
    4,
    1031422990,
    4,
    '2026-07-28',
    4.8,
    450000.00
);
insert into Matricula values (
    5,
    1031422990,
    5,
    '2026-07-28',
    4.0,
    700000.00
);

insert into Matricula values (
    6,
    1028886975,
    1,
    '2026-07-29',
    3.8,
    1200000.00
);
insert into Matricula values (
    7,
    1028886975,
    2,
    '2026-07-29',
    4.1,
    950000.00
);
insert into Matricula values (
    8,
    1028886975,
    4,
    '2026-07-29',
    4.6,
    450000.00
);

insert into Matricula values (
    9,
    1011765342,
    1,
    '2026-07-30',
    3.5,
    1200000.00
);
insert into Matricula values (
    10,
    1011765342,
    2,
    '2026-07-30',
    4.0,
    950000.00
);
insert into Matricula values (
    11,
    1011765342,
    3,
    '2026-07-30',
    4.7,
    700000.00
);

insert into Matricula values (
    12,
    1030281186,
    4,
    '2026-08-01',
    3.7,
    450000.00
);

insert into Matricula values (
    13,
    1122151498,
    4,
    '2026-08-01',
    4.3,
    450000.00
);
