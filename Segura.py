#!/usr/bin/env python3
import getpass
import sys
import mysql.connector

def main():
    print("=" * 70)
    print(" ACTIVIDAD 3: CONSULTAS SEGURAS MEDIANTE PREPARED STATEMENTS (DESPUÉS)")
    print("=" * 70)

    db_user = input("Usuario MariaDB/MySQL [root]: ").strip() or "root"
    db_password = getpass.getpass("Contraseña: ")

    config = {
        "host": "localhost",
        "user": db_user,
        "password": db_password,
        "database": "Guia_3",
        "autocommit": True
    }

    try:
        conn = mysql.connector.connect(**config)
        cursor = conn.cursor(dictionary=True)
        print("\n[+] Conexión establecida con la base de datos 'Guia_3'.\n")

        # ---------------------------------------------------------------------
        # CASO 1: Búsqueda Parametrizada por Documento
        # ---------------------------------------------------------------------
        print("-" * 70)
        print("CASO 1: BÚSQUEDA DE ESTUDIANTE (PARAMETRIZADA)")
        print("-" * 70)

        payload_1 = "1031422990' OR '1'='1"

        # Consulta con marcador de posición posicional (%s)
        query_segura_1 = "SELECT IdEstudiante, PrimerNombre, PrimerApellido FROM Estudiante WHERE IdEstudiante = %s"
        print(f"Plantilla precompilada: {query_segura_1}")
        print(f"Parámetro transmitido: ({payload_1},)\n")

        cursor.execute(query_segura_1, (payload_1,))
        res_1 = cursor.fetchall()
        print(f"Filas devueltas: {len(res_1)}")
        if not res_1:
            print("-> PROTEGIDO: Cero registros devueltos. El motor buscó textualmente la cadena completa.\n")

        # ---------------------------------------------------------------------
        # CASO 2: Filtro Compuesto Parametrizado
        # ---------------------------------------------------------------------
        print("-" * 70)
        print("CASO 2: FILTRO COMPUESTO EN MATRÍCULA (PARAMETRIZADA)")
        print("-" * 70)

        payload_estudiante = "1031422990 OR 1=1 -- "
        param_matricula = 9999

        query_segura_2 = "SELECT IdMatricula, IdEstudiante, ValorMatricula FROM Matricula WHERE IdEstudiante = %s AND IdMatricula = %s"
        print(f"Plantilla precompilada: {query_segura_2}")
        print(f"Parámetros transmitidos: ({payload_estudiante}, {param_matricula})\n")

        cursor.execute(query_segura_2, (payload_estudiante, param_matricula))
        res_2 = cursor.fetchall()
        print(f"Filas devueltas: {len(res_2)}")
        if not res_2:
            print("-> PROTEGIDO: El motor mantuvo la lógica del operador AND y evaluó la entrada como dato puro.\n")

        cursor.close()
        conn.close()

    except mysql.connector.Error as err:
        print(f"\n[!] Error de base de datos: {err}", file=sys.stderr)

if __name__ == "__main__":
    main()