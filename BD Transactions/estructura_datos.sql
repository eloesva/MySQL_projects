-- Creamos la base de datos
    CREATE DATABASE IF NOT EXISTS transactions;
    USE transactions;

    -- Creamos la tabla company
    CREATE TABLE IF NOT EXISTS company (
        id VARCHAR(15) PRIMARY KEY,
        company_name VARCHAR(255),
        phone VARCHAR(15),
        email VARCHAR(100),
        country VARCHAR(100),
        website VARCHAR(255)
    );


    -- Creamos la tabla transaction
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
    
-- Modifico transaction para crear la Foreign Key y para que sea de manera segura, uso constraint    
ALTER TABLE transaction
ADD CONSTRAINT fk_transaction_credit_card
FOREIGN KEY (credit_card_id) REFERENCES credit_card(id);
-- Modificando la tabla credit_card, me aseguro que pan acepta los espacios :C
ALTER TABLE credit_card
MODIFY pan VARCHAR(19);
    
-- EJERCICIO 2 / Utilizando JOINS:
-- a) Listado de los países que están generando ventas. 
--   Identificar venta: si declined = 0, significa que la venta procedió.
--   Dame los países (company) de todas las transacciones donde declined = 0 (transaction), conectadas mediante company_id

SELECT DISTINCT
	country, declined
FROM company com
INNER JOIN transaction trans
	ON com.id = trans.company_id
WHERE declined = 0
ORDER BY country;

-- b) Desde cuántos países se generan las ventas.
--   Cuéntame los países (y quizás muéstralos) de la consulta anterior
SELECT 
	COUNT(DISTINCT com.country) AS cuantos_paises
FROM company com
INNER JOIN transaction trans
	ON com.id = trans.company_id
WHERE declined = 0;

-- c) Identifica a la compañía con la mayor media de ventas.

SELECT 
  ROUND(AVG(trans.amount), 2) AS media_ventas, 
  com.company_name  
FROM company com
INNER JOIN transaction trans
  ON com.id = trans.company_id
WHERE declined = 0
GROUP BY com.id
ORDER BY media_ventas DESC
LIMIT 1;

-- EJERCICIO 3 / Utilizando sólo subconsultas (sin utilizar JOIN):

-- a) Muestra todas las transacciones realizadas por empresas de Alemania. 
-- multiple row subquery: de la tabla transaction muestra todo lo que coincida entre company_id y id de company donde 
-- (country = 'Alemania')

SELECT trans.*, -- query externa
  (SELECT com.country -- subquery internmedia
    FROM company com
    WHERE com.id = trans.company_id) AS country
FROM transaction trans
WHERE trans.company_id IN 
	(SELECT com.id
	 FROM company com
	 WHERE com.country = 'Germany'); -- subquery interna

-- b) Lista las empresas que han realizado transacciones por un amount superior a la media de todas las transacciones.

SELECT company_name -- query externa
FROM company
WHERE id IN 
  (SELECT company_id -- subquery intermedia
  FROM transaction
  GROUP BY company_id
  HAVING MAX(amount) > 
	(SELECT AVG(amount) -- subquery interna
     FROM transaction)
   );

-- c) Eliminarán del sistema las empresas que carecen de transacciones registradas, entrega el listado de estas empresas.

SELECT * -- Primero identifico cuales serian esas empresas que no tienen registros en transacciones por eso select
FROM company com
WHERE NOT EXISTS (
  SELECT 1 -- used to check whether a record matching your where clause exists.
  FROM transaction trans
  WHERE trans.company_id = com.id
);

 DELETE FROM company com -- En caso de querer eliminarlas totalmente, seria lo mismo pero con delete
 WHERE NOT EXISTS (
 SELECT 1
 FROM transaction trans
 WHERE trans.company_id = com.id
 );


-- EJERCICIO 4
-- Diseñar y crear una tabla llamada "credit_card" que almacene detalles cruciales sobre las tarjetas de crédito.
-- La nueva tabla debe ser capaz de identificar de forma única cada tarjeta y establecer una relación adecuada
-- con las otras dos tablas ("transaction" y "company"). Después de crear la tabla será necesario
-- que ingreses la información del documento denominado "datos_introducir_credit".
-- Recuerda mostrar el diagrama y realizar una breve descripción del mismo.

CREATE TABLE IF NOT EXISTS credit_card (
id VARCHAR(15) PRIMARY KEY,
iban VARCHAR(34) NOT NULL,
pan CHAR(16) NOT NULL,
pin CHAR(4) NOT NULL,
cvv VARCHAR(4) NOT NULL,
expiring_date VARCHAR(10) NOT NULL
);
-- DROP TABLE credit_card;

-- EJERCICIO 5
-- (Del ejercicio anterior, te falta escribir la descripción y los screenshots y todo hehe)

-- El departamento de Recursos Humanos ha identificado un error en el número de cuenta asociado a su tarjeta de crédito
-- con ID CcU-2938. 
-- La información que debe mostrarse para este registro es: TR323456312213576817699999.
-- Recuerda mostrar que el cambio se realizó.

SELECT * -- primero reviso que sí está el id requerido y corroboro que el iban es distinto
FROM credit_card
WHERE id='CcU-2938';

UPDATE credit_card SET iban ='TR323456312213576817699999' WHERE id ='CcU-2938';

-- EJERCICIO 6
-- En la tabla "transaction" ingresa una nueva transacción con la siguiente información: (VER IMAGEN descargada)
INSERT INTO company (id, company_name, phone, email, country, website) -- primero crear en company el id que se debe insertar
VALUES ('b-9999', 'Empresa Prueba', '123456789', 'test@test.com', 'Spain', 'www.test.com');

INSERT INTO credit_card (id, iban, pan, pin, cvv, expiring_date) -- primero crear en company el id que se debe insertar
VALUES ('CcU-9999', '111111', '5678952114', '0123', '4567', '10/2026');

INSERT INTO transaction (id, credit_card_id, company_id, user_id, lat, longitude, timestamp, amount, declined) -- registro nuevo
VALUES ('108B1D1D-5B23-A76C-55EF-C568E49A99DD', 'CcU-9999', 'b-9999', 9999, 829.999, -117.999, '2026-04-20 11:47:10', 111.11, 0);

SELECT *
FROM transaction
ORDER BY timestamp DESC
LIMIT 1;

SELECT *
FROM company
WHERE id = 'b-9999';

SELECT *
FROM credit_card
WHERE id = 'CcU-9999';

-- EJERCICIO 7
-- Desde recursos humanos te solicitan eliminar la columna "pan" de la tabla credit_card. Recuerda mostrar el cambio realizado.
-- ALTER TABLE credit_card
-- DROP COLUMN pan;

SELECT *
FROM credit_card
LIMIT 5;
    