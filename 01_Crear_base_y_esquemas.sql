--1.Creacion de base de datos del proyecto 
USE MASTER;
GO 
IF NOT EXISTS (SELECT* FROM sys.databases WHERE name='AventureWorks_DWH')
CREATE DATABASE AventureWorks_DWH;
GO 

USE AventureWorks_DWH;
GO 

CREATE SCHEMA STG; --Capa de persistencia temporal (Data Cruda )
GO 
CREATE SCHEMA DW; -- Capa de presentacion (modelo estrella )
GO
CREATE SCHEMA ETL; -- Creacion de la tabla de control 
GO