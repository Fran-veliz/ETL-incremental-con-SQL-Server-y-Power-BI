DECLARE @FechaInicio DATE ='2000-01-01'
DECLARE @FechaFin DATE='2030-12-31'

WHILE @FechaInicio <=@FechaFin

BEGIN 
   INSERT INTO DW.Dim_Tiempo(
       DateKey ,      -- yyyymmdd
       Fecha ,
       Dia ,
       DiaSemana ,
       NombreDia ,
       Mes ,
       NombreMes ,
       MesNumero ,
       Trimestre ,
       Año ,
       SemanaAño ,
       EsFinSemana ,
       AñoFiscal ,
       MesFiscal ,
       TrimestreFiscal 
   
   )
  VALUES (
  CONVERT(INT ,FORMAT(@FechaInicio,'yyyyMMdd')),
  @FechaInicio,
  DAY(@FechaInicio),
  DATEPART(WEEKDAY,@FechaInicio),--DIA SEMANA
  DATENAME(WEEKDAY,@FechaInicio),--NOMBRE DIA 
  MONTH(@FechaInicio),
  DATENAME(MONTH,@FechaInicio),--NOMBRE DE MES 
  MONTH(@FechaInicio),
  DATEPART(QUARTER,@FechaInicio),
  YEAR(@FechaInicio),
  DATEPART(WEEK,@FechaInicio),
  CASE WHEN DATEPART(WEEKDAY,@FechaInicio) IN (1,7) THEN 1 ELSE 0 END ,--SI ES SABADO O DOMINGO 1 SINO 0(EGLIS-FCHA)
  YEAR(@FechaInicio),
  MONTH(@FechaInicio),
  DATEPART(QUARTER,@FechaInicio)
  );

  SET @FechaInicio=DATEADD(DAY,1,@FechaInicio);
END ;
GO 