/*
=====================================================
EJERCICIO 8
Descarga los archivos CSV que encontrarás en el apartado de recursos:

american_users.csv
european_users.csv
companies.csv
credit_cards.csv
transactions.csv

Estudia y diseña una base de datos con un esquema de estrella que contenga,
al menos 4 tablas de las que puedas realizar las siguientes consultas:
=====================================================
*/

CREATE DATABASE IF NOT EXISTS user_transactions;
USE user_transactions;

-- =====================================================
-- LIMPIEZA PREVIA
-- =====================================================

DROP TABLE IF EXISTS fact_transactions;
DROP TABLE IF EXISTS dim_credit_cards;
DROP TABLE IF EXISTS dim_companies;
DROP TABLE IF EXISTS dim_users;

-- =====================================================
-- CREACIÓN DE TABLAS DIMENSIÓN
-- =====================================================

CREATE TABLE dim_users (
    user_id INT PRIMARY KEY,
    name VARCHAR(100),
    surname VARCHAR(100),
    phone VARCHAR(30),
    email VARCHAR(150),
    birth_date VARCHAR(30),
    country VARCHAR(100),
    city VARCHAR(100),
    postal_code VARCHAR(20),
    address VARCHAR(255),
    user_region VARCHAR(20)
);

CREATE TABLE dim_companies (
    company_id VARCHAR(20) PRIMARY KEY,
    company_name VARCHAR(255),
    phone VARCHAR(30),
    email VARCHAR(150),
    country VARCHAR(100),
    website VARCHAR(255)
);

CREATE TABLE dim_credit_cards (
    card_id VARCHAR(15) PRIMARY KEY,
    user_id INT,
    iban VARCHAR(34),
    pan VARCHAR(19),
    pin CHAR(4),
    cvv VARCHAR(4),
    track1 VARCHAR(255),
    track2 VARCHAR(255),
    expiring_date VARCHAR(10)
);

-- =====================================================
-- CREACIÓN DE TABLA DE HECHOS
-- =====================================================

CREATE TABLE fact_transactions (
    transaction_id CHAR(36) PRIMARY KEY,
    card_id VARCHAR(15),
    company_id VARCHAR(20),
    transaction_timestamp DATETIME,
    amount DECIMAL(10,2),
    declined TINYINT(1),
    user_id INT,
    lat DECIMAL(10,7),
    longitude DECIMAL(11,8),

    CONSTRAINT fk_fact_card
        FOREIGN KEY (card_id) REFERENCES dim_credit_cards(card_id),

    CONSTRAINT fk_fact_company
        FOREIGN KEY (company_id) REFERENCES dim_companies(company_id),

    CONSTRAINT fk_fact_user
        FOREIGN KEY (user_id) REFERENCES dim_users(user_id)
);
-- -------------------------
-- USUARIOS EUROPEOS
-- -------------------------
LOAD DATA LOCAL INFILE 'C:/Users/conta/Downloads/N1.Ex.8__ european_users.csv'
INTO TABLE dim_users
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS -- ignora la primera fila (header)
(user_id, name, surname, phone, email, birth_date, country, city, postal_code, address)
SET user_region = 'Europe'; 

-- -------------------------
-- USUARIOS AMERICANOS
-- -------------------------
LOAD DATA LOCAL INFILE 'C:/Users/conta/Downloads/N1-Ex.8__ american_users.csv'
INTO TABLE dim_users
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(user_id, name, surname, phone, email, birth_date, country, city, postal_code, address)
SET user_region = 'America';

-- -------------------------
-- COMPAÑÍAS
-- -------------------------
LOAD DATA LOCAL INFILE 'C:/Users/conta/Downloads/N1.Ex.8__ companies.csv'
INTO TABLE dim_companies
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(company_id, company_name, phone, email, country, website);

-- -------------------------
-- TARJETAS
-- -------------------------
LOAD DATA LOCAL INFILE 'C:/Users/conta/Downloads/N1.Ex.8__ credit_cards.csv'
INTO TABLE dim_credit_cards
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(card_id, user_id, iban, pan, pin, cvv, track1, track2, expiring_date);

-- -------------------------
-- TRANSACCIONES
-- este CSV usa ;
-- product_ids se ignora con variable temporal
-- -------------------------
LOAD DATA LOCAL INFILE 'C:/Users/conta/Downloads/N1.Ex.8__ transactions.csv'
INTO TABLE fact_transactions
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(transaction_id, card_id, company_id, transaction_timestamp, amount, declined, @product_ids, user_id, lat, longitude);

-- =====================================================
-- EJERCICIO 9
-- Realiza una subconsulta que muestre a todos los usuarios con más de 80 transacciones utilizando al menos 2 tablas.
-- =====================================================
SELECT 
    diu.user_id, -- query externa
    diu.name,
    diu.surname
FROM dim_users diu
WHERE diu.user_id IN (
    SELECT user_id -- subquery interna
    FROM fact_transactions
    GROUP BY user_id
    HAVING COUNT(*) > 80
);


-- =====================================================
-- EJERCICIO 10
-- Muestra la media de amount por IBAN de las tarjetas de crédito en la compañía Donec Ltd., utiliza por lo menos 2 tablas.
-- =====================================================

SELECT 
	cc.iban, 
	ROUND(AVG(amount), 2) AS media_amount,
    dc.company_name
FROM fact_transactions fa
JOIN dim_credit_cards cc 
    ON fa.card_id = cc.card_id
JOIN dim_companies dc
    ON fa.company_id = dc.company_id
WHERE dc.company_name = 'Donec Ltd'
GROUP BY cc.iban; -- b-2242

-- =====================================================
-- EJERCICIO 1 NIVEL 2 
-- Identifica los cinco días que se generó la mayor cantidad de ingresos en la empresa por ventas. 
-- Muestra la fecha de cada transacción junto con el total de las ventas.
-- =====================================================

SELECT 
    DATE(transaction_timestamp) AS fecha,
    SUM(amount) AS total_ventas
FROM fact_transactions
WHERE declined = 0
GROUP BY DATE(transaction_timestamp)
ORDER BY total_ventas DESC
LIMIT 5;

-- =====================================================
-- EJERCICIO 2 NIVEL 2 
-- Presenta el nombre, teléfono, país, fecha y amount, de aquellas empresas que realizaron transacciones con un valor
-- comprendido entre 350 y 400 euros y en alguna de estas fechas: 
-- 29 de abril de 2015, 20 de julio de 2018 y 13 de marzo de 2024. Ordena los resultados de mayor a menor cantidad.
-- =====================================================
SELECT 
	dc.company_name,
    dc.phone, dc.country,
    ft.transaction_timestamp,
    ft.amount
FROM dim_companies dc
JOIN fact_transactions ft
	ON dc.company_id = ft.company_id
WHERE ft.amount BETWEEN 350 AND 400
AND DATE(ft.transaction_timestamp) IN ('2015-04-29', '2018-07-20', '2024-03-13')
ORDER BY ft.amount DESC;

-- =====================================================
-- EJERCICIO 3 NIVEL 2 
-- Necesitamos optimizar la asignación de los recursos y dependerá de la capacidad operativa que se requiera,
-- por lo que te piden la información sobre la cantidad de transacciones que realizan las empresas, pero el departamento
-- de recursos humanos es exigente y quiere un listado de las empresas en las que especifiques si tienen más de 400
-- transacciones o menos.
-- =====================================================
SELECT 
    dc.company_name,
    COUNT(ft.transaction_id) AS num_transacciones,
    CASE
        WHEN COUNT(ft.transaction_id) > 400 THEN 'Más de 400 transacciones'
        ELSE '400 o menos transacciones'
    END AS categoria
FROM dim_companies dc
JOIN fact_transactions ft
    ON dc.company_id = ft.company_id
GROUP BY dc.company_id, dc.company_name
ORDER BY num_transacciones DESC;



