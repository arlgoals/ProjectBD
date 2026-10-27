DROP SCHEMA IF EXISTS biblioteca CASCADE;
CREATE SCHEMA biblioteca;
SET search_path TO biblioteca, public;

CREATE TABLE rol (
    tipo_rol VARCHAR(30) PRIMARY KEY
);
INSERT INTO rol (tipo_rol) VALUES ('Lector'), ('Bibliotecario'), ('Administrador'), ('Auditor');

CREATE TABLE usuario (
    id_usuario SERIAL PRIMARY KEY,
    documento VARCHAR(20) UNIQUE NOT NULL,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    correo VARCHAR(150) UNIQUE NOT NULL,
    telefono VARCHAR(20),
    clave_hash TEXT NOT NULL,
    tipo_rol VARCHAR(30) NOT NULL REFERENCES rol(tipo_rol),
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE categoria (
    id_categoria SERIAL PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE libro (
    isbn VARCHAR(13) PRIMARY KEY,
    titulo VARCHAR(200) NOT NULL,
    autor VARCHAR(150) NOT NULL,
    anio_publicacion SMALLINT,
    id_categoria INT REFERENCES categoria(id_categoria)
);

CREATE TABLE ejemplar (
    id_ejemplar SERIAL PRIMARY KEY,
    isbn VARCHAR(13) NOT NULL REFERENCES libro(isbn) ON DELETE CASCADE,
    numero_copia INT NOT NULL,
    estado VARCHAR(30) DEFAULT 'disponible',
    estanteria VARCHAR(50),
    UNIQUE(isbn, numero_copia)
);

CREATE TABLE prestamo (
    id_prestamo SERIAL PRIMARY KEY,
    id_ejemplar INT NOT NULL REFERENCES ejemplar(id_ejemplar),
    id_lector INT NOT NULL REFERENCES usuario(id_usuario),
    id_bibliotecario INT REFERENCES usuario(id_usuario),
    fecha_prestamo DATE NOT NULL DEFAULT CURRENT_DATE,
    fecha_esperada DATE NOT NULL,
    fecha_devolucion DATE,
    estado VARCHAR(20) DEFAULT 'activo'
);

-- Tabla para el taller: bitácora de rechazos
CREATE TABLE rechazo_carga (
    id_rechazo SERIAL PRIMARY KEY,
    archivo VARCHAR(100),
    linea INT,
    contenido TEXT,
    motivo TEXT,
    fecha_rechazo TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);