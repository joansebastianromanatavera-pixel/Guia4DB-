#!/usr/bin/env python3
import getpass
import sys
import mysql.connector

def main():
    print("=" * 70)
    print(" ACTIVIDAD 3: CONSULTAS VULNERABLES A SQL INJECTION (ANTES)")
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
        # CASO 1: Búsqueda por Documento (Inyección Clásica OR 1=1)
        # ---------------------------------------------------------------------
        print("-" * 70)
        print("CASO 1: BÚSQUEDA DE ESTUDIANTE")
        print("-" * 70)

        # Entrada manipulada por el usuario
        payload_1 = "1031422990' OR '1'='1"

        # Concatenación directa con f-strings
        query_vulnerable_1 = f"SELECT IdEstudiante, PrimerNombre, PrimerApellido FROM Estudiante WHERE IdEstudiante = '{payload_1}'"
        print(f"Query concatenada:\n{query_vulnerable_1}\n")

        cursor.execute(query_vulnerable_1)
        res_1 = cursor.fetchall()
        print(f"Filas devueltas: {len(res_1)}")
        for r in res_1[:3]:
            print(f"  * {r}")
        if len(res_1) > 3:
            print("  * [...]")
        print("-> FALLO CRÍTICO: La condición '1'='1' forzó la exposición de toda la tabla.\n")

        # ---------------------------------------------------------------------
        # CASO 2: Verificación de Matrícula y Estudiante (Comentarios SQL)
        # ---------------------------------------------------------------------
        print("-" * 70)
        print("CASO 2: FILTRO COMPUESTO EN MATRÍCULA")
        print("-" * 70)

        # Entrada maliciosa que introduce un comentario en línea
        payload_estudiante = "1031422990 OR 1=1 -- "
        param_matricula = "9999"  # Matrícula inexistente

        # Concatenación directa
        query_vulnerable_2 = f"SELECT IdMatricula, IdEstudiante, ValorMatricula FROM Matricula WHERE IdEstudiante = {payload_estudiante} AND IdMatricula = {param_matricula}"
        print(f"Query concatenada:\n{query_vulnerable_2}\n")

        cursor.execute(query_vulnerable_2)
        res_2 = cursor.fetchall()
        print(f"Filas devueltas: {len(res_2)}")
        for r in res_2[:3]:
            print(f"  * {r}")
        print("-> FALLO CRÍTICO: El comentario '-- ' descartó la validación de matrícula y expuso registros indebidos.\n")

        cursor.close()
        conn.close()

    except mysql.connector.Error as err:
        print(f"\n[!] Error de base de datos: {err}", file=sys.stderr)

if __name__ == "__main__":
    main()