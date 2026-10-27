\set ON_ERROR_STOP on
\if :{?archivo}
\else
    \set archivo /scripts/datos/libros_semilla.csv
\endif

SET search_path TO biblioteca, public;

--Crear tablas de paso si no existen antes de empezar la validación e inserción

CREATE TABLE IF NOT EXISTS stg_linea (
    n INT GENERATED ALWAYS AS IDENTITY,
    linea TEXT
);

CREATE TABLE IF NOT EXISTS stg_libro (
    linea_csv INT GENERATED ALWAYS AS IDENTITY,
    linea_completa TEXT,
    num_campos INT,
    isbn TEXT, titulo TEXT, autor TEXT, categoria TEXT, anio_publicacion TEXT, ejemplares TEXT,
    motivo TEXT
);

BEGIN;

TRUNCATE stg_linea, stg_libro RESTART IDENTITY;

COPY stg_linea (linea) FROM :'archivo' WITH (FORMAT text);
DELETE FROM stg_linea WHERE n=1;

INSERT INTO stg_libro (linea_completa, num_campos, isbn, titulo, autor, categoria, anio_publicacion, ejemplares)
SELECT
    linea,
    array_length(string_to_array(linea, ','), 1),
    trim(split_part(linea, ',', 1)),
    trim(split_part(linea, ',', 2)),
    trim(split_part(linea, ',', 3)),
    trim(split_part(linea, ',', 4)),
    trim(split_part(linea, ',', 5)),
    trim(split_part(linea, ',', 6))
FROM stg_linea;

-- 3. Validación
UPDATE stg_libro SET motivo = CASE
    WHEN num_campos <> 6 THEN 'tiene ' || num_campos || ' columnas, se esperaban 6'
    WHEN isbn = '' THEN 'isbn vacío'
    WHEN isbn !~ '^[0-9]{13}$' THEN 'isbn no tiene 13 dígitos'
    WHEN anio_publicacion !~ '^[0-9]{1,4}$' THEN 'año no numérico'
    WHEN anio_publicacion::integer > EXTRACT(YEAR FROM CURRENT_DATE) THEN 'año de publicación en el futuro'
    WHEN ejemplares !~ '^[0-9]+$' THEN 'ejemplares no numérico'
    WHEN EXISTS (SELECT 1 FROM libro l WHERE l.isbn = stg_libro.isbn) THEN 'isbn ya existe'
END;

-- 4. Inserción (Manejando Categorías y Ejemplares)
INSERT INTO categoria (nombre)
SELECT DISTINCT categoria FROM stg_libro WHERE motivo IS NULL ON CONFLICT (nombre) DO NOTHING;

INSERT INTO libro (isbn, titulo, autor, anio_publicacion, id_categoria)
SELECT s.isbn, s.titulo, s.autor, s.anio_publicacion::smallint, c.id_categoria
FROM stg_libro s JOIN categoria c ON c.nombre = s.categoria
WHERE s.motivo IS NULL;

INSERT INTO ejemplar (isbn, numero_copia)
SELECT s.isbn, g.n
FROM stg_libro s CROSS JOIN LATERAL generate_series(1, s.ejemplares::integer) AS g(n)
WHERE s.motivo IS NULL;

-- 5. Bitácora
INSERT INTO rechazo_carga (archivo, linea, contenido, motivo)
SELECT :'archivo', linea_csv, linea_completa, motivo FROM stg_libro WHERE motivo IS NOT NULL;

COMMIT;