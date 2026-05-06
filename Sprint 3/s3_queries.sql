-- BRONZE

 CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-estefaniat.sprint3_bronze.transactions_raw`
(
  id STRING,
  card_id STRING,
  business_id STRING,
  timestamp STRING,
  amount STRING,
  declined STRING,
  product_ids STRING,
  user_id STRING,
  lat STRING,
  longitude STRING
)
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/ERP/transactions.csv'],
  field_delimiter = ';',
  skip_leading_rows = 1
);

CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-estefaniat.sprint3_bronze.companies_raw`(
  id STRING,
  company_name STRING,
  phone STRING,
  email STRING,
  country STRING,
  website STRING)
  OPTIONS (
    format = 'CSV',
    uris = ['gs://bootcamp-data-analytics-public/ERP/companies.csv'],
    skip_leading_rows = 1);

-- 3. american_users_raw
CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-estefaniat.sprint3_bronze.american_users_raw`(
  id STRING,
  name STRING,
  surname STRING,
  phone STRING,
  email STRING,
  birth_date STRING,
  country STRING,
  city STRING,
  postal_code STRING,
  address STRING)
  OPTIONS (
    format = 'CSV',
    uris = ['gs://bootcamp-data-analytics-public/CRM/american_users.csv'],
    skip_leading_rows = 1);

-- 4. european_users_raw
CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-estefaniat.sprint3_bronze.european_users_raw`(
  id STRING,
  name STRING,
  surname STRING,
  phone STRING,
  email STRING,
  birth_date STRING,
  country STRING,
  city STRING,
  postal_code STRING,
  address STRING)
  OPTIONS (
    format = 'CSV',
    uris = ['gs://bootcamp-data-analytics-public/CRM/european_users.csv'],
    skip_leading_rows = 1);

-- 5. credit_cards_raw
CREATE OR REPLACE EXTERNAL TABLE `sprint3-analytics-estefaniat.sprint3_bronze.credit_cards_raw`(
  id STRING,
  user_id STRING,
  iban STRING,
  pan STRING,
  pin STRING,
  cvv STRING,
  track1 STRING,
  track2 STRING,
  expiring_date STRING)
  OPTIONS (
    format = 'CSV',
    uris = ['gs://bootcamp-data-analytics-public/CRM/credit_cards.csv'],
    skip_leading_rows = 1);

-- transactions_raw_native
CREATE OR REPLACE TABLE `sprint3-analytics-estefaniat.sprint3_bronze.transactions_raw_native`
AS
SELECT * FROM `sprint3-analytics-estefaniat.sprint3_bronze.transactions_raw`;

-- 5 días con mayores ingresos del año 2021
SELECT
  DATE(SAFE.PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%S', timestamp)) AS fecha,
  SUM(SAFE_CAST(amount AS FLOAT64)) AS ingresos -- Si encuentra un valor raro, devuelve NULL en esa fila y la query sigue
FROM `sprint3_bronze.transactions_raw`
WHERE EXTRACT(YEAR FROM SAFE.PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%S', timestamp)) = 2021
GROUP BY fecha
ORDER BY ingresos DESC
LIMIT 5;


-- Lista el nombre, país y fecha de las transacciones realizadas por empresas que realizaron operaciones entre 100 y 200 euros en alguna de estas fechas: 29-04-2015, 20-07-2018 o 13-03-2024.

SELECT 
  c.company_name,
  c.country,
  DATE(SAFE.PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%S', t.timestamp)) AS fecha --primero convierte a timestamp y luego obtiene fecha sin horas
FROM `sprint3_bronze.transactions_raw_native` AS t
JOIN `sprint3_bronze.companies_raw` AS c
  ON t.business_id = c.id
WHERE SAFE_CAST(t.amount AS FLOAT64) BETWEEN 100 AND 200
  AND DATE(SAFE.PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%S', t.timestamp)) IN (
    DATE '2015-04-29',
    DATE '2018-07-20',
    DATE '2024-03-13'
  );
  
  -- Comparación de consultas tabla externa vs nativa
  SELECT id
  FROM `sprint3_bronze.transactions_raw`;
  
   SELECT id
  FROM `sprint3_bronze.transactions_raw_native`;
  
  -- Comparación de consultas con y sin LIMIT
  SELECT *
  FROM `sprint3_bronze.transactions_raw`;

  SELECT *
  FROM `sprint3_bronze.transactions_raw`
  LIMIT 10;

-- SILVER
-- Creación de tabla limpia para productos
CREATE OR REPLACE TABLE `sprint3-analytics-estefaniat.sprint3_silver.products_clean` AS
SELECT
  id AS product_id,
  product_name AS name,
  SAFE_CAST(REPLACE(warehouse_id, 'WH-', '') AS INT64) AS warehouse_id,
  SAFE_CAST(REGEXP_REPLACE(CAST(price AS STRING), r'[^0-9.]', '') AS FLOAT64) AS price,
  colour,
  weight
FROM `sprint3-analytics-estefaniat.sprint3_bronze.products_raw`;

-- Tabla limpia para transactions
CREATE OR REPLACE TABLE `sprint3-analytics-estefaniat.sprint3_silver.transactions_clean` AS
SELECT
  id AS transaction_id,
  card_id,
  business_id,
  SAFE.PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%S', timestamp) AS timestamp,
  IFNULL(SAFE_CAST(amount AS FLOAT64), 0) AS amount,
  declined,
  product_ids,
  user_id,
  SAFE_CAST(lat AS FLOAT64) AS lat,
  SAFE_CAST(longitude AS FLOAT64) AS longitude
FROM `sprint3-analytics-estefaniat.sprint3_bronze.transactions_raw`;

-- Union de usuarios

CREATE OR REPLACE TABLE `sprint3-analytics-estefaniat.sprint3_silver.users_combined` AS

SELECT
  id AS user_id,
  name,
  surname,
  phone,
  email,
  birth_date,
  country,
  city,
  postal_code,
  address,
  'US' AS origin
FROM `sprint3-analytics-estefaniat.sprint3_bronze.american_users_raw`

UNION ALL

SELECT
  id AS user_id,
  name,
  surname,
  phone,
  email,
  birth_date,
  country,
  city,
  postal_code,
  address,
  'EU' AS origin
FROM `sprint3-analytics-estefaniat.sprint3_bronze.european_users_raw`;

-- Companies y credit cards clean

CREATE OR REPLACE TABLE `sprint3-analytics-estefaniat.sprint3_silver.companies_clean` AS
SELECT
  id AS company_id,
  company_name,
  phone,
  email,
  country,
  website
FROM `sprint3-analytics-estefaniat.sprint3_bronze.companies_raw`;

CREATE OR REPLACE TABLE `sprint3-analytics-estefaniat.sprint3_silver.credit_cards_clean` AS
SELECT
  id AS card_id,
  user_id,
  iban,
  pan,
  pin,
  cvv,
  track1,
  track2,
  expiring_date
FROM `sprint3-analytics-estefaniat.sprint3_bronze.credit_cards_raw`;

-- GOLD

-- Si la media de compra es superior a 260 € , etiqueta como "Premium", si es inferior, etiqueta como "Standard" 

CREATE OR REPLACE VIEW `sprint3-analytics-estefaniat.sprint3_gold.v_marketing_kpis` AS
SELECT
  c.company_name,
  c.phone,
  c.country,
  AVG(t.amount) AS avg_purchase,
  CASE
    WHEN AVG(t.amount) > 260 THEN 'Premium'
    ELSE 'Standard'
  END AS client_tier
FROM `sprint3-analytics-estefaniat.sprint3_silver.companies_clean` AS c
JOIN `sprint3-analytics-estefaniat.sprint3_silver.transactions_clean` AS t
  ON c.company_id = t.business_id
GROUP BY
  c.company_name,
  c.phone,
  c.country;

  SELECT *
FROM `sprint3-analytics-estefaniat.sprint3_gold.v_marketing_kpis`
ORDER BY
  CASE 
    WHEN client_tier = 'Premium' THEN 1
    ELSE 2
  END,
  avg_purchase DESC;

  -- Ranking de productos
CREATE OR REPLACE TABLE `sprint3-analytics-estefaniat.sprint3_gold.product_sales_ranking` AS

WITH unnested_products AS (
  SELECT
    SAFE_CAST(TRIM(product_id) AS INT64) AS product_id
  FROM `sprint3-analytics-estefaniat.sprint3_silver.transactions_clean`,
  UNNEST(SPLIT(product_ids, ',')) AS product_id
),

product_sales AS (
  SELECT
    product_id,
    COUNT(*) AS total_sold
  FROM unnested_products
  WHERE product_id IS NOT NULL
  GROUP BY product_id
)

SELECT
  p.product_id,
  p.name,
  p.price,
  p.colour,
  IFNULL(ps.total_sold, 0) AS total_sold
FROM `sprint3-analytics-estefaniat.sprint3_silver.products_clean` AS p
LEFT JOIN product_sales AS ps
  ON p.product_id = ps.product_id
ORDER BY total_sold DESC;

SELECT *
FROM `sprint3-analytics-estefaniat.sprint3_gold.product_sales_ranking`
ORDER BY total_sold DESC;

  


