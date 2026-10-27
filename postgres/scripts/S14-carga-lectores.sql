\set ON_ERROR_STOP on
\if :{?archivo}
\else
    \set archivo /scripts/datos/lectores_semilla.csv
\endif

SET search_path TO biblioteca, public;

--Crear tablas de paso si no existen antes de empezar la validación e inserción

CREATE TABLE IF NOT EXISTS stg_linea(
  n INT GENERATED ALWAYS AS IDENTITY,
  linea TEXT
);

CREATE TABLE IF NOT EXISTS stg_lector(
  linea_csv INT GENERATED ALWAYS AS IDENTITY,
  linea_completa TEXT,
  num_campos INT,
  documento TEXT, nombres TEXT, apellidos TEXT, correo TEXT, telefono TEXT,
  motivo TEXT
);

BEGIN;

TRUNCATE stg_linea, stg_lector RESTART IDENTITY;

COPY stg_linea (linea) FROM :'archivo' WITH (FORMAT text);
DELETE FROM stg_linea WHERE n=1;

INSERT INTO stg_lector (linea_completa, num_campos, documento, nombres, apellidos, correo, telefono)

SELECT
  linea,
  array_length(string_to_array(linea, ','), 1),
  trim(split_part(linea, ',', 1)),
  trim(split_part(linea, ',', 2)),
  trim(split_part(linea, ',', 3)),
  trim(split_part(linea, ',', 4)),
  trim(split_part(linea, ',', 5))
FROM stg_linea;

-- 3. Validación

UPDATE stg_lector SET motivo = CASE
  WHEN num_campos <> 5 THEN 'tiene ' || num_campos || ' columnas, se esperaban 5'
  WHEN documento = '' THEN 'documento vacío'
  WHEN documento !~ '^[0-9]+$' THEN 'documento no numérico'
  WHEN nombres = '' OR apellidos = '' THEN 'nombres o apellidos vacíos'
  WHEN correo = '' THEN 'correo vacío'
  WHEN correo !~ '^[^@]+@[^@]+\.[^@]+$' THEN 'formato de correo inválido'
  WHEN telefono = '' THEN 'teléfono vacío'
  WHEN telefono !~ '^[0-9]+$' THEN 'teléfono no numérico'
  WHEN EXISTS (SELECT 1 FROM usuario u WHERE u.documento = stg_lector.documento) THEN 'documento ya existe en BD'
  WHEN EXISTS (SELECT 1 FROM usuario u WHERE u.correo = lower(stg_lector.correo)) THEN 'correo ya existe en BD'

END;

-- 4. Inserción 
CREATE EXTENSION IF NOT EXISTS pgcrypto;

INSERT INTO usuario (documento, nombres, apellidos, correo, telefono, clave_hash, tipo_rol)
SELECT 
    documento, 
    nombres, 
    apellidos, 
    lower(correo), 
    telefono, 
    crypt(documento, gen_salt('bf')), 
    'Lector'
FROM stg_lector 
WHERE motivo IS NULL;



-- 5. Bitácora
INSERT INTO rechazo_carga (archivo, linea, contenido, motivo)
SELECT :'archivo', linea_csv, linea_completa, motivo FROM stg_lector WHERE motivo IS NOT NULL;

COMMIT;