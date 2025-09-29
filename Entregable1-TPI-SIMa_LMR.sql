SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE DATABASE IF NOT EXISTS erp_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE erp_db;

-- =========================================================
-- 4. Módulo de Administración de Usuarios
-- =========================================================
CREATE TABLE IF NOT EXISTS Usuarios (
  usuario_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(150) NOT NULL,
  email VARCHAR(150) NOT NULL,
  username VARCHAR(100) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  UNIQUE KEY uq_usuarios_email (email),
  UNIQUE KEY uq_usuarios_username (username)
) ENGINE=InnoDB;

-- =========================================================
-- 1. Módulo de Gestión de Clientes
-- =========================================================
CREATE TABLE IF NOT EXISTS Clientes (
  cliente_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre_empresa VARCHAR(200) NOT NULL,
  tipo_cliente VARCHAR(20) NOT NULL,
  cuit_cuil VARCHAR(20) NULL,
  condicion_iva VARCHAR(30) NOT NULL,
  fecha_alta DATE NOT NULL,
  estado VARCHAR(20) NOT NULL,
  direccion_calle VARCHAR(200) NULL,
  direccion_ciudad VARCHAR(100) NULL,
  direccion_provincia VARCHAR(100) NULL,
  direccion_pais VARCHAR(100) NULL,
  telefono VARCHAR(50) NULL,
  email VARCHAR(150) NULL,
  observaciones TEXT NULL,
  UNIQUE KEY uq_clientes_cuit (cuit_cuil),
  UNIQUE KEY uq_clientes_email (email),
  CHECK (tipo_cliente IN ('EMPRESA','PARTICULAR','OTRO')),
  CHECK (condicion_iva IN ('RI','RNI','MONOTRIBUTO','EXENTO','CF','OTRO')),
  CHECK (estado IN ('ACTIVO','INACTIVO','SUSPENDIDO'))
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Contactos_Cliente (
  contacto_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  cliente_id INT UNSIGNED NOT NULL,
  nombre_contacto VARCHAR(150) NOT NULL,
  cargo VARCHAR(100) NULL,
  telefono VARCHAR(50) NULL,
  email VARCHAR(150) NULL,
  CONSTRAINT fk_contacto_cliente
    FOREIGN KEY (cliente_id) REFERENCES Clientes(cliente_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Segmentacion (
  segmento_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre_segmento VARCHAR(100) NOT NULL,
  descripcion VARCHAR(255) NULL,
  UNIQUE KEY uq_segmentacion_nombre (nombre_segmento)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Cliente_Segmento (
  cliente_id INT UNSIGNED NOT NULL,
  segmento_id INT UNSIGNED NOT NULL,
  PRIMARY KEY (cliente_id, segmento_id),
  CONSTRAINT fk_cliente_segmento_cliente
    FOREIGN KEY (cliente_id) REFERENCES Clientes(cliente_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_cliente_segmento_segmento
    FOREIGN KEY (segmento_id) REFERENCES Segmentacion(segmento_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Pedidos (
  pedido_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  cliente_id INT UNSIGNED NOT NULL,
  fecha_pedido DATE NOT NULL,
  estado_pedido VARCHAR(20) NOT NULL,
  monto_total DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  CHECK (estado_pedido IN ('BORRADOR','CONFIRMADO','FACTURADO','CANCELADO')),
  CONSTRAINT fk_pedido_cliente
    FOREIGN KEY (cliente_id) REFERENCES Clientes(cliente_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Tickets de reclamo (requiere Usuarios y Clientes)
CREATE TABLE IF NOT EXISTS Tickets_Reclamo (
  ticket_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  cliente_id INT UNSIGNED NOT NULL,
  fecha_apertura DATETIME NOT NULL,
  asunto VARCHAR(200) NOT NULL,
  tipo_reclamo VARCHAR(30) NOT NULL,
  estado_ticket VARCHAR(20) NOT NULL,
  responsable_id INT UNSIGNED NULL,
  fecha_cierre DATETIME NULL,
  prioridad VARCHAR(10) NOT NULL,
  CHECK (tipo_reclamo IN ('PRODUCTO','SERVICIO','FACTURACION','SOPORTE','OTRO')),
  CHECK (estado_ticket IN ('ABIERTO','EN_PROCESO','RESUELTO','CERRADO','CANCELADO')),
  CHECK (prioridad IN ('BAJA','MEDIA','ALTA','CRITICA')),
  CONSTRAINT fk_ticket_cliente
    FOREIGN KEY (cliente_id) REFERENCES Clientes(cliente_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_ticket_responsable
    FOREIGN KEY (responsable_id) REFERENCES Usuarios(usuario_id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- =========================================================
-- 2. Módulo de Inventario
-- =========================================================
CREATE TABLE IF NOT EXISTS Categorias (
  categoria_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre_categoria VARCHAR(120) NOT NULL,
  UNIQUE KEY uq_categorias_nombre (nombre_categoria)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Proveedores (
  proveedor_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre_proveedor VARCHAR(200) NOT NULL,
  CUIT_proveedor VARCHAR(20) NULL,
  telefono VARCHAR(50) NULL,
  correo_electronico VARCHAR(150) NULL,
  direccion_ciudad VARCHAR(100) NULL,
  direccion_provincia VARCHAR(100) NULL,
  direccion_pais VARCHAR(100) NULL,
  UNIQUE KEY uq_proveedores_cuit (CUIT_proveedor),
  UNIQUE KEY uq_proveedores_email (correo_electronico)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Almacenes (
  almacen_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  nombre_almacen VARCHAR(150) NOT NULL,
  direccion VARCHAR(255) NULL,
  UNIQUE KEY uq_almacen_nombre (nombre_almacen)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Productos (
  producto_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  codigo VARCHAR(60) NOT NULL,
  nombre VARCHAR(200) NOT NULL,
  descripcion TEXT NULL,
  categoria_id INT UNSIGNED NOT NULL,
  proveedor_id INT UNSIGNED NULL,
  precio_compra DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  precio_venta DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  stock_minimo INT NOT NULL DEFAULT 0,
  UNIQUE KEY uq_productos_codigo (codigo),
  CONSTRAINT fk_producto_categoria
    FOREIGN KEY (categoria_id) REFERENCES Categorias(categoria_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_producto_proveedor
    FOREIGN KEY (proveedor_id) REFERENCES Proveedores(proveedor_id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Movimientos_Inventario (
  movimiento_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  producto_id INT UNSIGNED NOT NULL,
  almacen_id INT UNSIGNED NOT NULL,
  tipo_movimiento VARCHAR(20) NOT NULL,
  cantidad DECIMAL(10,2) NOT NULL,
  fecha_movimiento DATETIME NOT NULL,
  documento_origen VARCHAR(50) NULL,
  referencia VARCHAR(255) NULL,
  CHECK (tipo_movimiento IN ('ENTRADA','SALIDA','AJUSTE_POSITIVO','AJUSTE_NEGATIVO','TRANSFERENCIA')),
  CONSTRAINT fk_mov_producto
    FOREIGN KEY (producto_id) REFERENCES Productos(producto_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_mov_almacen
    FOREIGN KEY (almacen_id) REFERENCES Almacenes(almacen_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Reportes (
  reporte_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tipo_reporte VARCHAR(100) NOT NULL,
  fecha_generacion DATETIME NOT NULL,
  datos_json JSON NULL
) ENGINE=InnoDB;

-- =========================================================
-- 3. Módulo de Registro de Compras y Ventas
-- =========================================================

-- Ventas y detalle
CREATE TABLE IF NOT EXISTS Ventas (
  venta_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  cliente_id INT UNSIGNED NOT NULL,
  fecha_venta DATETIME NOT NULL,
  monto_total DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  estado_venta VARCHAR(20) NOT NULL,
  usuario_id INT UNSIGNED NULL,
  CHECK (estado_venta IN ('BORRADOR','CONFIRMADA','FACTURADA','ANULADA')),
  CONSTRAINT fk_venta_cliente
    FOREIGN KEY (cliente_id) REFERENCES Clientes(cliente_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_venta_usuario
    FOREIGN KEY (usuario_id) REFERENCES Usuarios(usuario_id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Detalle_Venta (
  detalle_venta_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  venta_id INT UNSIGNED NOT NULL,
  producto_id INT UNSIGNED NOT NULL,
  cantidad DECIMAL(10,2) NOT NULL,
  precio_unitario DECIMAL(10,2) NOT NULL,
  subtotal DECIMAL(10,2) NOT NULL,
  CONSTRAINT fk_detalle_venta_venta
    FOREIGN KEY (venta_id) REFERENCES Ventas(venta_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_detalle_venta_producto
    FOREIGN KEY (producto_id) REFERENCES Productos(producto_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Compras y detalle
CREATE TABLE IF NOT EXISTS Compras (
  compra_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  proveedor_id INT UNSIGNED NOT NULL,
  fecha_compra DATETIME NOT NULL,
  monto_total DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  estado_compra VARCHAR(20) NOT NULL,
  CHECK (estado_compra IN ('BORRADOR','CONFIRMADA','FACTURADA','ANULADA')),
  CONSTRAINT fk_compra_proveedor
    FOREIGN KEY (proveedor_id) REFERENCES Proveedores(proveedor_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Detalle_Compra (
  detalle_compra_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  compra_id INT UNSIGNED NOT NULL,
  producto_id INT UNSIGNED NOT NULL,
  cantidad DECIMAL(10,2) NOT NULL,
  precio_unitario DECIMAL(10,2) NOT NULL,
  subtotal DECIMAL(10,2) NOT NULL,
  CONSTRAINT fk_detalle_compra_compra
    FOREIGN KEY (compra_id) REFERENCES Compras(compra_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_detalle_compra_producto
    FOREIGN KEY (producto_id) REFERENCES Productos(producto_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Facturas unificadas (ventas, compras y pedidos)
CREATE TABLE IF NOT EXISTS Facturas (
  factura_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  tipo_factura VARCHAR(5) NOT NULL,                -- A, B, C, NC, ND, etc.
  tipo_documento VARCHAR(20) NOT NULL,             -- FACTURA, NOTA_CREDITO, NOTA_DEBITO
  venta_id INT UNSIGNED NULL,
  compra_id INT UNSIGNED NULL,
  pedido_id INT UNSIGNED NULL,
  cliente_id INT UNSIGNED NULL,
  proveedor_id INT UNSIGNED NULL,
  fecha_emision DATE NOT NULL,
  fecha_vencimiento DATE NULL,
  monto_neto DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  monto_impuesto DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  monto_total DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  estado_pago VARCHAR(20) NOT NULL,
  CHECK (tipo_documento IN ('FACTURA','NOTA_CREDITO','NOTA_DEBITO')),
  CHECK (estado_pago IN ('PENDIENTE','PARCIAL','PAGADA','VENCIDA','ANULADA')),
  CONSTRAINT fk_factura_venta
    FOREIGN KEY (venta_id) REFERENCES Ventas(venta_id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_factura_compra
    FOREIGN KEY (compra_id) REFERENCES Compras(compra_id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_factura_pedido
    FOREIGN KEY (pedido_id) REFERENCES Pedidos(pedido_id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_factura_cliente
    FOREIGN KEY (cliente_id) REFERENCES Clientes(cliente_id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_factura_proveedor
    FOREIGN KEY (proveedor_id) REFERENCES Proveedores(proveedor_id)
    ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- Cuentas por Cobrar (clientes)
CREATE TABLE IF NOT EXISTS Cuentas_Por_Cobrar (
  cobro_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  factura_id INT UNSIGNED NOT NULL,
  fecha_cobro DATETIME NOT NULL,
  monto_cobrado DECIMAL(10,2) NOT NULL,
  metodo_cobro VARCHAR(30) NOT NULL,
  saldo_pendiente DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  CHECK (metodo_cobro IN ('EFECTIVO','TRANSFERENCIA','TARJETA','CHEQUE','OTRO')),
  CONSTRAINT fk_cxc_factura
    FOREIGN KEY (factura_id) REFERENCES Facturas(factura_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Cuentas por Pagar (proveedores)
CREATE TABLE IF NOT EXISTS Cuentas_Por_Pagar (
  pago_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  factura_id INT UNSIGNED NOT NULL,
  fecha_pago DATETIME NOT NULL,
  monto_pagado DECIMAL(10,2) NOT NULL,
  metodo_pago VARCHAR(30) NOT NULL,
  saldo_pendiente DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  CHECK (metodo_pago IN ('EFECTIVO','TRANSFERENCIA','TARJETA','CHEQUE','OTRO')),
  CONSTRAINT fk_cxp_factura
    FOREIGN KEY (factura_id) REFERENCES Facturas(factura_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Pagos (módulo clientes) - pagos de clientes aplicados a facturas
CREATE TABLE IF NOT EXISTS Pagos (
  pago_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  factura_id INT UNSIGNED NOT NULL,
  fecha_pago DATETIME NOT NULL,
  monto_pagado DECIMAL(10,2) NOT NULL,
  metodo_pago VARCHAR(30) NOT NULL,
  cliente_id INT UNSIGNED NOT NULL,
  CHECK (metodo_pago IN ('EFECTIVO','TRANSFERENCIA','TARJETA','CHEQUE','OTRO')),
  CONSTRAINT fk_pago_factura
    FOREIGN KEY (factura_id) REFERENCES Facturas(factura_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_pago_cliente
    FOREIGN KEY (cliente_id) REFERENCES Clientes(cliente_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

SET FOREIGN_KEY_CHECKS = 1;