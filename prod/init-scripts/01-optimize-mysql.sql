-- Script de inicialización para optimizar MariaDB para Koha
-- Se ejecuta automáticamente cuando se crea la base de datos

-- Crear usuario de solo lectura para monitoreo
CREATE USER IF NOT EXISTS 'monitor'@'%' IDENTIFIED BY 'monitor_password';
GRANT SELECT, PROCESS, REPLICATION CLIENT ON *.* TO 'monitor'@'%';

-- Optimizaciones para Koha
SET GLOBAL innodb_buffer_pool_size = 1073741824; -- 1GB
SET GLOBAL query_cache_size = 67108864; -- 64MB
SET GLOBAL max_connections = 200;

-- Configurar timezone
SET GLOBAL time_zone = '+00:00';

-- Crear índices adicionales para mejorar el rendimiento de Koha
USE koha_production;

-- Nota: Los índices específicos se crearán cuando Koha inicialice
-- Este archivo puede extenderse con configuraciones adicionales según sea necesario

FLUSH PRIVILEGES;
