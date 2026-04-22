 
 CREATE DATABASE IF NOT EXISTS transactions2;
 USE transactions2;
-- =====================================================
-- LIMPIEZA PREVIA
-- =====================================================

DROP TABLE IF EXISTS credit_card;
DROP TABLE IF EXISTS transaction;
DROP TABLE IF EXISTS company;

-- =====================================================
-- CREACIÓN DE TABLAS DIMENSIÓN
-- =====================================================

 CREATE TABLE IF NOT EXISTS company (
        id VARCHAR(15) PRIMARY KEY,
        company_name VARCHAR(255),
        phone VARCHAR(15),
        email VARCHAR(100),
        country VARCHAR(100),
        website VARCHAR(255)
    );
    
-- =====================================================
-- CREACIÓN DE TABLA DE HECHOS
-- =====================================================

 CREATE TABLE IF NOT EXISTS transaction (
        id VARCHAR(255) PRIMARY KEY,
        credit_card_id VARCHAR(15) REFERENCES credit_card(id),
        company_id VARCHAR(20), 
        user_id INT REFERENCES user(id),
        lat FLOAT,
        longitude FLOAT,
        timestamp TIMESTAMP,
        amount DECIMAL(10, 2),
        declined BOOLEAN,
        FOREIGN KEY (company_id) REFERENCES company(id) 
    );
    
-- =====================================================
-- CONSULTAS
-- =====================================================

-- EJERCICIO 2 (Con JOINS)

-- Listado de países con ventas
SELECT DISTINCT
	country
FROM company com
INNER JOIN transaction trans
	ON com.id = trans.company_id
WHERE declined = 0
ORDER BY country;

-- Conteo de países con ventas
SELECT 
	COUNT(DISTINCT com.country) AS cuantos_paises
FROM company com
INNER JOIN transaction trans
	ON com.id = trans.company_id
WHERE declined = 0;

-- País con la mayor media de ventas
SELECT 
  ROUND(AVG(trans.amount), 2) AS media_ventas, 
  com.company_name  
FROM company com
INNER JOIN transaction trans
  ON com.id = trans.company_id
WHERE trans.declined = 0
GROUP BY com.id
ORDER BY media_ventas DESC
LIMIT 1;

-- EJERCICIO 3 (Con subqueries)

-- Muestra todas las transacciones realizadas por empresas de Alemania. 
SELECT trans.*, -- query externa
  (SELECT com.country -- subquery intermedia
    FROM company com
    WHERE com.id = trans.company_id) AS country
FROM transaction trans
WHERE EXISTS (SELECT com.id FROM company com WHERE com.id = trans.company_id AND com.country = 'Germany'); -- subquery interna

-- Lista las empresas que han realizado transacciones por un amount superior a la media de todas las transacciones.
SELECT company_name
FROM company c
WHERE EXISTS (
    SELECT 1
    FROM transaction t
    WHERE t.company_id = c.id
      AND t.amount > (SELECT AVG(amount) FROM transaction)
);

-- Eliminarán del sistema las empresas que carecen de transacciones registradas, entrega el listado de estas empresas.

SELECT com.id AS empresas_sin_transacc -- Primero identifico cuales serian esas empresas que no tienen registros en transacciones por eso select
FROM company com
WHERE NOT EXISTS (
  SELECT 1 -- used to check whether a record matching your where clause exists.
  FROM transaction trans
  WHERE trans.company_id = com.id
);

-- EJERCICIO 4 (Nueva tabla)

-- Crear nueva tabla credit_card
CREATE TABLE credit_card (
    id VARCHAR(15) PRIMARY KEY,
    iban VARCHAR(34),
    pan VARCHAR(16),
    pin VARCHAR(4),
    cvv VARCHAR(4),
    expiring_date VARCHAR(10) NOT NULL
);

ALTER TABLE transaction -- Modifico transaction para crear la Foreign Key y para que sea de manera segura, uso constraint  
ADD CONSTRAINT fk_trans_cc_01
FOREIGN KEY (credit_card_id) REFERENCES credit_card(id);

-- Modificando la tabla credit_card, me aseguro que pan acepta los espacios
ALTER TABLE credit_card
MODIFY pan VARCHAR(19);

UPDATE credit_card
SET expiring_date = STR_TO_DATE(expiring_date, '%m/%d/%y'); -- modificación de la fecha para que esté en el formato adecuado (date)

-- EJERCICIO 5

-- El departamento de Recursos Humanos ha identificado un error en el número de cuenta asociado a su tarjeta de crédito
-- con ID CcU-2938. 
-- La información que debe mostrarse para este registro es: TR323456312213576817699999.
-- Recuerda mostrar que el cambio se realizó.

SELECT * -- primero reviso que sí está el id requerido y corroboro que el iban es distinto
FROM credit_card
WHERE id='CcU-2938';

UPDATE credit_card SET iban ='TR323456312213576817699999' WHERE id ='CcU-2938';

-- EJERCICIO 6

-- En la tabla "transaction" ingresa una nueva transacción con la siguiente información: (imagen)
INSERT INTO transaction (id, credit_card_id, company_id, user_id, lat, longitude, amount, declined) -- registro nuevo
VALUES ('108B1D1D-5B23-A76C-55EF-C568E49A99DD', 'CcU-9999', 'b-9999', 9999, 829.999, -117.999, 111.11, 0);

SELECT *
FROM transaction
WHERE credit_card_id = 'CcU-9999';

-- EJERCICIO 7

-- Desde recursos humanos te solicitan eliminar la columna "pan" de la tabla credit_card. Recuerda mostrar el cambio realizado.
ALTER TABLE credit_card
DROP COLUMN pan;

SELECT *
FROM credit_card
LIMIT 5;