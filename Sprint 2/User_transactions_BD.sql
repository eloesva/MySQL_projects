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
-- EJERCICIO 1 N2 
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