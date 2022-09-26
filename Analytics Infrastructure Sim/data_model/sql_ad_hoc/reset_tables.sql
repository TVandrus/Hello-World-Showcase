
create schema "dev" ; -- rough work
create schema "dev_log" ; --dagster logging 
-- dbt-aware data model 
create schema "sim_src" ; 
create schema "sim_calc" ; 
create schema "sim_out" ; 
create schema "sim_state" ; -- dbt-aware, but either dbt-incremental or fully user-managed 

-- Create convenience data types in Postgres
CREATE DOMAIN "AccountNumber" AS varchar(15) NULL;
CREATE DOMAIN "Flag" AS bit NOT NULL;
CREATE DOMAIN "NameStyle" AS INT NOT NULL;
CREATE DOMAIN "Name" AS TEXT NULL;
CREATE DOMAIN "OrderNumber" AS varchar(25) NULL;
CREATE DOMAIN "Phone" AS varchar(25) NULL;

/* definitions for landing tables */

DROP TABLE IF EXISTS {{ source('src','aw_address') }} ;
CREATE TABLE {{ source('src','aw_address') }} (
    "AddressID" INT GENERATED ALWAYS AS IDENTITY(START 2000000 INCREMENT 1) ,
    "AddressLine1" TEXT NOT NULL, 
    "AddressLine2" TEXT, 
    "City" TEXT, 
    "StateProvinceID" INT NOT NULL,
    "PostalCode" VARCHAR(15) NOT NULL
); 
DROP TABLE IF EXISTS {{ source('src','aw_person') }} ;
CREATE TABLE {{ source('src','aw_person') }} (
    "BusinessEntityID" INT NOT NULL,
	"PersonType" CHAR(2) NOT NULL,
    "NameStyle" "NameStyle" NOT NULL,
    "Title" VARCHAR(8), 
    "FirstName" Name NOT NULL,
    "MiddleName" Name,
    "LastName" Name NOT NULL,
    "Suffix" VARCHAR(10), 
    "EmailPromotion" INT NOT NULL, 
    "AdditionalContactInfo" TEXT,
    "Demographics" TEXT 
);