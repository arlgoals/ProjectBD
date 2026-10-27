-- 1. Tabla de Roles (Para manejar Lector, Bibliotecario, Administrador, Auditor)
CREATE TABLE roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE
);

-- 2. Tabla de Usuarios (Centraliza todos los perfiles y maneja el login)
CREATE TABLE usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    rol_id INT NOT NULL,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL, -- Contraseñas encriptadas
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    correo VARCHAR(100) UNIQUE,
    telefono VARCHAR(20),
    activo BOOLEAN DEFAULT TRUE, -- Maneja la "baja/inactivación" sin borrar datos (Soft Delete)
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (rol_id) REFERENCES roles(id)
);

-- 3. Tabla de Libros
CREATE TABLE libros (
    id INT AUTO_INCREMENT PRIMARY KEY,
    isbn VARCHAR(20) UNIQUE,
    titulo VARCHAR(255) NOT NULL,
    autor VARCHAR(255) NOT NULL,
    anio_publicacion INT,
    ejemplares_totales INT NOT NULL DEFAULT 1,
    ejemplares_disponibles INT NOT NULL DEFAULT 1, -- Se actualiza con préstamos/devoluciones
    activo BOOLEAN DEFAULT TRUE, -- Maneja la "baja/inactivación" sin perder historial
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Tabla de Préstamos (Conecta usuarios, libros y responsables)
CREATE TABLE prestamos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    libro_id INT NOT NULL,
    lector_id INT NOT NULL, -- El usuario que recibe el libro
    bibliotecario_id INT NOT NULL, -- El bibliotecario que registra la operación en mostrador
    fecha_prestamo DATE NOT NULL,
    fecha_devolucion_esperada DATE NOT NULL, -- Por defecto: fecha_prestamo + 14 días
    fecha_devolucion_real DATE, -- NULL si aún no se ha devuelto
    estado ENUM('activo', 'devuelto') DEFAULT 'activo',
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (libro_id) REFERENCES libros(id),
    FOREIGN KEY (lector_id) REFERENCES usuarios(id),
    FOREIGN KEY (bibliotecario_id) REFERENCES usuarios(id)
);

-- Índices recomendados para optimizar los reportes solicitados
CREATE INDEX idx_prestamos_lector ON prestamos(lector_id, estado);
CREATE INDEX idx_prestamos_fechas ON prestamos(fecha_devolucion_esperada, estado);
CREATE INDEX idx_libros_disponibilidad ON libros(activo, ejemplares_disponibles);