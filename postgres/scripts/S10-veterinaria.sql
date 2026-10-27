-- S10. Taller de claves y restricciones de integridad
-- Caso: clínica veterinaria "VetValle"
--
-- Uso (desde entorno-docker/, con este archivo copiado en postgres/scripts/):
--   docker compose exec postgres psql -U curso -d curso -f /scripts/S10-veterinaria.sql
--
-- Se puede correr cuantas veces se quiera: borra y recrea el esquema
-- "veterinaria" completo, sin tocar nada más de la base "curso".
-- Para trabajar después sobre estas tablas desde psql o pgAdmin:
--   SET search_path TO veterinaria;

DROP SCHEMA IF EXISTS veterinaria CASCADE;
CREATE SCHEMA veterinaria;
SET search_path TO veterinaria;

CREATE TABLE dueno (
    cedula    varchar(12)  PRIMARY KEY,
    nombre    varchar(80)  NOT NULL,
    telefono  varchar(15)  NOT NULL,           -- NO es clave: dos dueños de la misma casa pueden compartirlo
    correo    varchar(80)  UNIQUE              -- opcional, pero si se da no puede repetirse
);

CREATE TABLE veterinario (
    tarjeta_profesional  varchar(10)  PRIMARY KEY,
    cedula               varchar(12)  NOT NULL UNIQUE,   -- clave candidata no elegida (alterna)
    nombre               varchar(80)  NOT NULL,
    correo               varchar(80)  NOT NULL UNIQUE    -- otra clave alterna
);

CREATE TABLE mascota (
    id_mascota        integer      PRIMARY KEY,         -- clave sustituta: no hay clave natural confiable
    nombre            varchar(40)  NOT NULL,
    especie           varchar(10)  NOT NULL
                      CHECK (especie IN ('perro', 'gato', 'ave', 'otro')),
    fecha_nacimiento  date,                              -- desconocida en mascotas rescatadas
    cedula_dueno      varchar(12)  NOT NULL REFERENCES dueno (cedula)
);

CREATE TABLE cita (
    id_cita      integer       PRIMARY KEY,
    id_mascota   integer       NOT NULL REFERENCES mascota (id_mascota),
    tarjeta_vet  varchar(10)   NOT NULL REFERENCES veterinario (tarjeta_profesional),
    fecha_hora   timestamp     NOT NULL,
    motivo       varchar(100)  NOT NULL,
    costo        numeric(10,0) CHECK (costo >= 0),       -- NULL = aún no se ha facturado
    UNIQUE (tarjeta_vet, fecha_hora),                    -- un veterinario no atiende dos citas a la vez
    UNIQUE (id_mascota, fecha_hora)                      -- una mascota no está en dos citas a la vez
);

INSERT INTO dueno VALUES
    ('1107000001', 'María Gómez',    '3001112233', 'maria.gomez@correo.com'),
    ('1107000002', 'Julián Rojas',   '3012223344', NULL),
    ('1107000003', 'Luisa Martínez', '3154445566', 'luisa.m@correo.com'),
    ('16000004',   'Carlos Pérez',   '3187778899', 'cperez@correo.com');

INSERT INTO veterinario VALUES
    ('TP-1001', '31000111', 'Ana Restrepo', 'arestrepo@vetvalle.co'),
    ('TP-1002', '94000222', 'Felipe Soto',  'fsoto@vetvalle.co'),
    ('TP-1003', '66000333', 'Sara Lozano',  'slozano@vetvalle.co');

INSERT INTO mascota VALUES
    (1, 'Luna',  'perro', '2021-03-10', '1107000001'),
    (2, 'Michi', 'gato',  '2019-07-22', '1107000001'),
    (3, 'Luna',  'gato',  NULL,         '1107000003'),
    (4, 'Rocky', 'perro', '2018-01-05', '16000004'),
    (5, 'Kiwi',  'ave',   '2023-05-30', '1107000002');

INSERT INTO cita VALUES
    (1, 1, 'TP-1001', '2026-10-05 08:00', 'Vacunación',       60000),
    (2, 2, 'TP-1001', '2026-10-05 08:30', 'Control',          45000),
    (3, 3, 'TP-1002', '2026-10-05 08:00', 'Consulta general', 45000),
    (4, 4, 'TP-1003', '2026-10-06 10:00', 'Cirugía menor',   350000),
    (5, 1, 'TP-1002', '2026-10-12 09:00', 'Control',          45000);