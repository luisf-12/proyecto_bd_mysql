-- PROYECTO: BASE DE DATOS EN MYSQL
-- 1. CREACIÓN Y SELECCIÓN DE LA BASE DE DATOS (DDL)
DROP DATABASE IF EXISTS bd_musica_streaming;
CREATE DATABASE bd_musica_streaming CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE bd_musica_streaming;

-- NIVEL 1: CREACIÓN DE ENTIDADES FUERTES (SIN LLAVES FORÁNEAS)
-- Tabla 1: grupo
-- (El atributo "componente" del diagrama E/R es multivaluado, por lo que se
--  normaliza en la tabla "componente" para cumplir la 1FN.)
CREATE TABLE grupo (
    nombre VARCHAR(100) NOT NULL,
    fecha_cre DATE NOT NULL,
    PRIMARY KEY (nombre)
) ENGINE=InnoDB;

-- Tabla 2: cancion
CREATE TABLE cancion (
    id_cancion INT AUTO_INCREMENT NOT NULL,
    titulo VARCHAR(150) NOT NULL,
    publica DATE NOT NULL,
    PRIMARY KEY (id_cancion)
) ENGINE=InnoDB;

-- Tabla 3: usuario
CREATE TABLE usuario (
    id_usuario INT AUTO_INCREMENT NOT NULL,
    correo VARCHAR(120) NOT NULL UNIQUE,
    url VARCHAR(200),
    fecha_alta DATE NOT NULL,
    PRIMARY KEY (id_usuario)
) ENGINE=InnoDB;

-- NIVEL 2: CREACIÓN DE ENTIDADES DEPENDIENTES (RELACIONES 1:N y 1:1)
-- Tabla 4: album (Relación 1:N "tiene" con la entidad grupo)
-- num_canciones se mantiene automáticamente con los triggers del Nivel 4.
CREATE TABLE album (
    id_album INT AUTO_INCREMENT NOT NULL,
    titulo VARCHAR(150) NOT NULL,
    fecha_publ DATE NOT NULL,
    num_canciones INT NOT NULL DEFAULT 0,
    nombre_grupo VARCHAR(100) NOT NULL,
    PRIMARY KEY (id_album),
    CONSTRAINT chk_album_num_canciones CHECK (num_canciones >= 0),
    CONSTRAINT fk_album_grupo
        FOREIGN KEY (nombre_grupo) REFERENCES grupo(nombre)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Tabla 5: componente (Atributo multivaluado de grupo, relación 1:N)
CREATE TABLE componente (
    id_componente INT AUTO_INCREMENT NOT NULL,
    nombre_grupo VARCHAR(100) NOT NULL,
    nombre_integrante VARCHAR(100) NOT NULL,
    PRIMARY KEY (id_componente),
    CONSTRAINT fk_componente_grupo
        FOREIGN KEY (nombre_grupo) REFERENCES grupo(nombre)
        ON UPDATE CASCADE
        ON DELETE CASCADE
) ENGINE=InnoDB;

-- Tabla 6: registrado (Especialización de usuario con cuota y fecha_fin)
CREATE TABLE registrado (
    id_usuario INT NOT NULL,
    cuota DECIMAL(10, 2) NOT NULL,
    fecha_fin DATE NOT NULL,
    PRIMARY KEY (id_usuario),
    CONSTRAINT chk_registrado_cuota CHECK (cuota >= 0),
    CONSTRAINT fk_registrado_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
        ON UPDATE CASCADE
        ON DELETE CASCADE
) ENGINE=InnoDB;

-- NIVEL 3: CREACIÓN DE TABLAS INTERMEDIAS (RELACIONES N:M)

-- Tabla 7: contiene (Relación N:M entre album y cancion)
CREATE TABLE contiene (
    id_album INT NOT NULL,
    id_cancion INT NOT NULL,
    PRIMARY KEY (id_album, id_cancion),
    CONSTRAINT fk_contiene_album
        FOREIGN KEY (id_album) REFERENCES album(id_album)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_contiene_cancion
        FOREIGN KEY (id_cancion) REFERENCES cancion(id_cancion)
        ON UPDATE CASCADE
        ON DELETE CASCADE
) ENGINE=InnoDB;

-- Tabla 8: stream (Relación N:M entre cancion y usuario con atributo fecha)
-- Se usa llave sustituta (id_stream) para permitir que un mismo usuario
-- reproduzca la misma canción muchas veces.
CREATE TABLE stream (
    id_stream INT AUTO_INCREMENT NOT NULL,
    id_cancion INT NOT NULL,
    id_usuario INT NOT NULL,
    fecha DATETIME NOT NULL,
    PRIMARY KEY (id_stream),
    CONSTRAINT fk_stream_cancion
        FOREIGN KEY (id_cancion) REFERENCES cancion(id_cancion)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_stream_usuario
        FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
        ON UPDATE CASCADE
        ON DELETE CASCADE
) ENGINE=InnoDB;

-- Tabla 9: descarga (Relación N:M entre cancion y registrado con n_veces y fecha)
CREATE TABLE descarga (
    id_descarga INT AUTO_INCREMENT NOT NULL,
    id_cancion INT NOT NULL,
    id_usuario INT NOT NULL,
    n_veces INT NOT NULL DEFAULT 1,
    fecha DATE NOT NULL,
    PRIMARY KEY (id_descarga),
    CONSTRAINT chk_descarga_n_veces CHECK (n_veces > 0),
    CONSTRAINT fk_descarga_cancion
        FOREIGN KEY (id_cancion) REFERENCES cancion(id_cancion)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_descarga_registrado
        FOREIGN KEY (id_usuario) REFERENCES registrado(id_usuario)
        ON UPDATE CASCADE
        ON DELETE CASCADE
) ENGINE=InnoDB;

-- NIVEL 4: ÍNDICES Y DISPARADORES (TRIGGERS)

-- Índice para agilizar la búsqueda de canciones por título
CREATE INDEX idx_titulo_cancion ON cancion(titulo);

-- Trigger: al agregar una canción a un álbum, suma 1 a album.num_canciones
CREATE TRIGGER trg_contiene_after_insert
AFTER INSERT ON contiene
FOR EACH ROW
    UPDATE album
    SET num_canciones = num_canciones + 1
    WHERE id_album = NEW.id_album;

-- Trigger: al quitar una canción de un álbum, resta 1 a album.num_canciones
-- (Nota: MySQL no activa triggers en borrados en cascada por llave foránea;
--  este trigger aplica a DELETE directos sobre la tabla contiene.)
CREATE TRIGGER trg_contiene_after_delete
AFTER DELETE ON contiene
FOR EACH ROW
    UPDATE album
    SET num_canciones = num_canciones - 1
    WHERE id_album = OLD.id_album;

-- SENTENCIAS DML: INSERCIÓN DE DATOS DE PRUEBA (INSERT)

INSERT INTO grupo (nombre, fecha_cre) VALUES
('Morat', '2011-12-13'),
('Soda Stereo', '1982-06-01');

INSERT INTO componente (nombre_grupo, nombre_integrante) VALUES
('Morat', 'Juan Pablo Isaza'),
('Morat', 'Juan Pablo Villamil'),
('Morat', 'Simón Vargas'),
('Morat', 'Martín Vargas'),
('Soda Stereo', 'Gustavo Cerati'),
('Soda Stereo', 'Zeta Bosio'),
('Soda Stereo', 'Charly Alberti');

INSERT INTO cancion (titulo, publica) VALUES
('Cómo te atreves', '2015-11-13'),
('Besos en guerra', '2017-11-03'),
('De música ligera', '1990-08-07'),
('Persiana americana', '1986-10-08');

INSERT INTO usuario (correo, url, fecha_alta) VALUES
('carlos.perez@correo.com', 'https://perfil.musica.com/carlosp', '2026-01-15'),
('laura.gomez@correo.com', 'https://perfil.musica.com/laurag', '2026-02-20'),
('andres.lopez@correo.com', 'https://perfil.musica.com/andresl', '2026-03-10');

-- num_canciones inicia en 0; los triggers lo actualizan al insertar en "contiene"
INSERT INTO album (titulo, fecha_publ, num_canciones, nombre_grupo) VALUES
('Sobre el amor y sus efectos secundarios', '2016-06-17', 0, 'Morat'),
('Balas perdidas', '2018-10-25', 0, 'Morat'),
('Canción animal', '1990-08-07', 0, 'Soda Stereo'),
('Signos', '1986-11-10', 0, 'Soda Stereo');

INSERT INTO registrado (id_usuario, cuota, fecha_fin) VALUES
(1, 19900.00, '2026-12-31'),
(2, 19900.00, '2026-11-30');

INSERT INTO contiene (id_album, id_cancion) VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4);

INSERT INTO stream (id_cancion, id_usuario, fecha) VALUES
(1, 1, '2026-10-10 14:30:00'),
(3, 2, '2026-10-11 18:15:00'),
(3, 3, '2026-10-12 09:45:00'),
(2, 1, '2026-10-12 20:00:00');

INSERT INTO descarga (id_cancion, id_usuario, n_veces, fecha) VALUES
(1, 1, 2, '2026-10-13'),
(3, 2, 5, '2026-10-14');

-- SENTENCIAS DML: ACTUALIZACIÓN, CONSULTA, SUBCONSULTAS, VISTAS Y BORRADO
-- 1. Ejemplo de UPDATE: Actualizar el número de descargas de un registro
UPDATE descarga
SET n_veces = 3
WHERE id_descarga = 1;

-- 2. Ejemplo de SELECT con WHERE y GROUP BY:
--    Total de reproducciones por canción desde el 1 de octubre de 2026
SELECT c.titulo AS cancion, COUNT(s.id_stream) AS total_streams
FROM cancion c
INNER JOIN stream s ON c.id_cancion = s.id_cancion
WHERE s.fecha >= '2026-10-01'
GROUP BY c.id_cancion, c.titulo;

-- 3. Ejemplo de Subconsulta:
--    Usuarios registrados con suscripción vigente (fecha_fin aún no vencida)
SELECT u.correo, u.fecha_alta
FROM usuario u
WHERE u.id_usuario IN (
    SELECT r.id_usuario
    FROM registrado r
    WHERE r.fecha_fin >= CURDATE()
);

-- 4. Creación de una Vista (VIEW): Catálogo completo de canciones con su álbum y grupo
CREATE OR REPLACE VIEW vista_catalogo_musical AS
SELECT
    g.nombre AS grupo,
    a.titulo AS album,
    c.titulo AS cancion,
    a.fecha_publ AS fecha_publicacion_album
FROM grupo g
INNER JOIN album a ON g.nombre = a.nombre_grupo
INNER JOIN contiene co ON a.id_album = co.id_album
INNER JOIN cancion c ON co.id_cancion = c.id_cancion;

-- Consultar la vista creada
SELECT * FROM vista_catalogo_musical;

-- 5. Ejemplo de DELETE: eliminar un registro de reproducción (stream)
DELETE FROM stream
WHERE id_stream = 4;

-- Verificar el resultado del DELETE (deben quedar 3 registros)
SELECT * FROM stream;

-- 6. Verificación de los triggers: num_canciones refleja las canciones en "contiene"
SELECT titulo, num_canciones FROM album;

-- 7. Consulta de los integrantes por grupo (tabla componente)
SELECT g.nombre AS grupo, co.nombre_integrante AS integrante
FROM grupo g
INNER JOIN componente co ON g.nombre = co.nombre_grupo
ORDER BY g.nombre, co.nombre_integrante;
