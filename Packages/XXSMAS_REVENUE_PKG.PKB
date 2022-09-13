CREATE OR REPLACE PACKAGE BODY XXSMAS_REVENUE_PKG
AS 

-------------------------------------------------------------------------------------------------------------------
--- Get Customer Name:
FUNCTION get_customer_name_func(p_ledger_name  IN VARCHAR2,
                                p_asset_number IN VARCHAR2
								)
RETURN VARCHAR2
AS

lv_customer_name VARCHAR2(240):=NULL;

BEGIN

BEGIN
SELECT UNIQUE customer_name 
INTO lv_customer_name 
FROM xxsmas_sheet1_dtls_tb 
WHERE 1=1 
AND customer_name IS NOT NULL
AND ledger_name=p_ledger_name --- ledger name
AND asset=p_asset_number;     --- asset number
EXCEPTION WHEN OTHERS THEN
lv_customer_name :=NULL;
END;

RETURN lv_customer_name ;

END get_customer_name_func;
-------------------------------------------------------------------------------------------------------------------
--- Get Periodwise Net Movement LR:
FUNCTION get_net_movement_lr (p_ledger_name  IN VARCHAR2,
                              p_asset_number IN VARCHAR2,
							  p_period_name  IN VARCHAR2
							 )
RETURN NUMBER
AS
lv_net_movement NUMBER:=0;
BEGIN

BEGIN
SELECT  SUM(NVL(net_movement,0))
INTO lv_net_movement
FROM xxsmas_sheet1_dtls_tb 
WHERE 1=1 
AND TYPE=1 
AND ledger_name=p_ledger_name --- ledger name
AND period_name=p_period_name --- period name
AND asset=p_asset_number;     --- asset number
EXCEPTION WHEN OTHERS THEN
lv_net_movement :=0;
END;

RETURN lv_net_movement ;

END get_net_movement_lr ;
-------------------------------------------------------------------------------------------------------------------
--- Get Periodwise Net Movement FMS:
FUNCTION get_net_movement_fms   (p_ledger_name  IN VARCHAR2,
                                 p_asset_number IN VARCHAR2,
								 p_period_name  IN VARCHAR2
								)
RETURN NUMBER
AS

lv_net_movement NUMBER:=0;

BEGIN

BEGIN
SELECT SUM(NVL(net_movement,0))
INTO lv_net_movement
FROM xxsmas_sheet1_dtls_tb 
WHERE 1=1 
AND TYPE=2 
AND ledger_name=p_ledger_name --- ledger name
AND period_name=p_period_name --- period name
AND asset=p_asset_number;     --- asset number
EXCEPTION WHEN OTHERS THEN
lv_net_movement :=0;
END;

RETURN lv_net_movement ;

END get_net_movement_fms ;
-------------------------------------------------------------------------------------------------------------------
--- Get Total LR:
FUNCTION get_total_net_movement_lr(p_ledger_name  IN VARCHAR2,
                                   p_asset_number IN VARCHAR2
								   )
RETURN NUMBER
AS

lv_net_movement NUMBER:=0;
BEGIN

BEGIN
SELECT  SUM(NVL(net_movement,0))
INTO lv_net_movement
FROM xxsmas_sheet1_dtls_tb 
WHERE 1=1 
AND TYPE=1 
AND ledger_name=p_ledger_name --- ledger name
AND asset=p_asset_number;     --- asset number
EXCEPTION WHEN OTHERS THEN
lv_net_movement :=0;
END;

RETURN lv_net_movement ;

END get_total_net_movement_lr  ;

----------------------------------------------------------------------------------------------------------------
--- Get Total FMS:
FUNCTION get_total_net_movement_fms(p_ledger_name  IN VARCHAR2,
                                    p_asset_number IN VARCHAR2
									)
RETURN NUMBER
AS

lv_net_movement NUMBER:=0;

BEGIN

BEGIN
SELECT  SUM(NVL(net_movement,0))
INTO lv_net_movement
FROM xxsmas_sheet1_dtls_temp_tb 
WHERE 1=1 
AND TYPE=2
AND ledger_name=p_ledger_name --- ledger name
AND asset=p_asset_number;     --- asset number
EXCEPTION WHEN OTHERS THEN
lv_net_movement :=0;
END;

RETURN lv_net_movement ;

END get_total_net_movement_fms    ;
----------------------------------------------------------------------------------------------------------------
--- Get Sheet1 Details:
PROCEDURE  xxsmas_sheet1_proc (p_ledger_name IN VARCHAR2,p_period IN VARCHAR2) AS 

lv_period_number       NUMBER;
lv_period_year         VARCHAR2(15):=NULL;

BEGIN

DELETE xxsmas_sheet1_dtls_tb;
COMMIT;

--Get Period_number and Year:
BEGIN
SELECT UNIQUE gp.period_num,gp.period_year
INTO lv_period_number,lv_period_year
FROM gl_ledgers gl,
	 gl_periods gp
WHERE 1=1
AND gl.name=p_ledger_name -- parameter: ledger Name
AND gl.period_set_name=gp.period_set_name
AND gp.period_name=p_period; -- parameter: period name;
EXCEPTION WHEN OTHERS THEN
lv_period_number:=NULL;
lv_period_year:=NULL;
END;
-----


INSERT INTO "XXSMAS_SHEET1_DTLS_TB" 
   (	
    "TYPE"                  ,
	"LEDGER_NAME"           ,
	"LEDGER_CALENDAR"       ,
	"PERIOD_NAME"           , 
	"PERIOD_NUMBER"         ,
	"PERIOD_YEAR"           ,
	"LOCATION"              , 
	"LOCATION_DESCRIPTION"  ,
	"ASSET"                 , 
	"ASSET_DESCRIPTION"     , 
	"ACCOUNT"               ,
	"ACCOUNT_DESCRIPTION"   ,
	"CUSTOMER_NAME"         , 
	"OPENING_BALANCE"       ,
	"DEBIT"                 ,
	"CREDIT"                ,
	"NET_MOVEMENT"          ,
	"CLOSING_BALANCE"       
   )
SELECT  UNIQUE  
        1                                                                                     type,
        gl.name                                                                              ledger_name,
        gl.period_set_name                                                                   ledger_calendar,
        gb.period_name                                                                       period_name,
        gb.period_num                                                                        period_number,
		gb.period_year,
		gcc.segment2                                                                         location,
		apps.gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,2,gcc.segment2) location_description,
		gcc.segment3                                                                         asset,
		apps.gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,3,gcc.segment3) asset_description,
		gcc.segment4                                                                         account,
		apps.gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,4,gcc.segment4) account_description,	
        get_customer_name(p_ledger_id=>gb.ledger_id,p_code_combination_id=>gb.code_combination_id,p_period_name=>gb.period_name) customer_name, 
		SUM (NVL (gb.begin_balance_dr, 0) - NVL (gb.begin_balance_cr, 0))                    opening_balance,
		SUM(NVL (gb.period_net_dr, 0))                                                       debit,
		SUM(NVL (gb.period_net_cr,0))                                                        credit,
		SUM (NVL (gb.period_net_dr, 0) - NVL (gb.period_net_cr, 0))*-1                       net_movement,
		SUM ((NVL (gb.period_net_dr, 0) + NVL (gb.begin_balance_dr, 0)))
       - SUM (NVL (gb.period_net_cr, 0) + NVL (gb.begin_balance_cr, 0))                      closing_balance

FROM     gl_ledgers               gl,
         gl_balances              gb,
		 gl_code_combinations     gcc

WHERE 1=1
AND gl.ledger_id=gb.ledger_id
AND gb.actual_flag = 'A'
AND gb.template_id IS NULL
AND gb.period_num <=lv_period_number
AND gb.period_year=lv_period_year
AND gb.code_combination_id = gcc.code_combination_id
AND gcc.segment4 ='30100'
AND gcc.segment3<>'000000'
group by gl.name             ,
         gl.period_set_name  ,
         gb.period_name      ,
         gb.period_num       ,
		 gcc.segment2        ,	
		 gcc.segment3        ,	
         gcc.segment4        ,	
		 gb.period_year,
		 gcc.chart_of_accounts_id,
		 gb.code_combination_id,
		 gb.ledger_id
         order by segment4,segment3,gb.period_num asc;
COMMIT;		 


-----------------------------------------------------------------------------------------------------------------------------------------


INSERT INTO "XXSMAS_SHEET1_DTLS_TB" 
   (	
    "TYPE"                  ,
	"LEDGER_NAME"           ,
	"LEDGER_CALENDAR"       ,
	"PERIOD_NAME"           , 
	"PERIOD_NUMBER"         ,
	"PERIOD_YEAR"           ,
	"LOCATION"              , 
	"LOCATION_DESCRIPTION"  ,
	"ASSET"                 , 
	"ASSET_DESCRIPTION"     , 
	"ACCOUNT"               ,
	"ACCOUNT_DESCRIPTION"   ,
	"CUSTOMER_NAME"         , 
	"OPENING_BALANCE"       ,
	"DEBIT"                 ,
	"CREDIT"                ,
	"NET_MOVEMENT"          ,
	"CLOSING_BALANCE"       
   )
SELECT  UNIQUE  
        2                                                                                    type,
        gl.name                                                                              ledger_name,
        gl.period_set_name                                                                   ledger_calendar,
        gb.period_name                                                                       period_name,
        gb.period_num                                                                        period_number,
		gb.period_year,
		gcc.segment2                                                                         location,
		apps.gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,2,gcc.segment2) location_description,
		gcc.segment3                                                                         asset,
		apps.gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,3,gcc.segment3) asset_description,
		gcc.segment4                                                                         account,
		apps.gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,4,gcc.segment4) account_description,	
        get_customer_name(p_ledger_id=>gb.ledger_id,p_code_combination_id=>gb.code_combination_id,p_period_name=>gb.period_name) customer_name, 
		SUM (NVL (gb.begin_balance_dr, 0) - NVL (gb.begin_balance_cr, 0))                    opening_balance,
		SUM(NVL (gb.period_net_dr, 0))                                                       debit,
		SUM(NVL (gb.period_net_cr,0))                                                        credit,
		SUM (NVL (gb.period_net_dr, 0) - NVL (gb.period_net_cr, 0))*-1                       net_movement,
		SUM ((NVL (gb.period_net_dr, 0) + NVL (gb.begin_balance_dr, 0)))
       - SUM (NVL (gb.period_net_cr, 0) + NVL (gb.begin_balance_cr, 0))                      closing_balance

FROM     gl_ledgers               gl,
         gl_balances              gb,
		 gl_code_combinations     gcc

WHERE 1=1
AND gl.ledger_id=gb.ledger_id
AND gb.actual_flag = 'A'
AND gb.template_id IS NULL
AND gb.period_num <=lv_period_number
AND gb.period_year=lv_period_year
AND gb.code_combination_id = gcc.code_combination_id
AND gcc.segment4 ='30200'
AND gcc.segment3<>'000000'
group by gl.name             ,
         gl.period_set_name  ,
         gb.period_name      ,
         gb.period_num       ,
		 gcc.segment2        ,	
		 gcc.segment3        ,	
         gcc.segment4        ,	
		 gb.period_year,
		 gcc.chart_of_accounts_id,
		 gb.code_combination_id,
		 gb.ledger_id
         order by segment4,segment3,gb.period_num asc;
COMMIT;		

----
DELETE xxsmas_sheet1_dtls_tb
WHERE 1=1
AND asset IN (
SELECT asset FROM(SELECT asset,SUM(net_movement) FROM xxsmas_sheet1_dtls_tb WHERE 1=1 GROUP BY asset HAVING SUM(net_movement) =0));
COMMIT;	 
-------------------------------------------------------------------------------------------------------------------------------------------------------
END xxsmas_sheet1_proc;

--- Get Summary details:
PROCEDURE XXSMAS_SUMMARY_DTLS_PROC(p_ledger_name IN VARCHAR2,p_period IN VARCHAR2)
AS

lv_period_number NUMBER;
lv_period_year   VARCHAR2(15):=NULL;

BEGIN

--Get Period_number and Year:
BEGIN
SELECT UNIQUE gp.period_num,gp.period_year
INTO lv_period_number,lv_period_year
FROM gl_ledgers gl,
	 gl_periods gp
WHERE 1=1
AND gl.name=p_ledger_name -- parameter: ledger Name
AND gl.period_set_name=gp.period_set_name
AND gp.period_name=p_period; -- parameter: period name;
EXCEPTION WHEN OTHERS THEN
lv_period_number:=NULL;
lv_period_year:=NULL;
END;

DELETE XXSMAS_SUMMARY_DTLS_TB ;
COMMIT;

INSERT INTO XXSMAS_SUMMARY_DTLS_TB 
SELECT * FROM XXSMAS_SUMMARY_DTLS_VW 
WHERE 1=1 
AND ledger_name=p_ledger_name
AND period_year=lv_period_year
AND period_number<=lv_period_number;
COMMIT;

END XXSMAS_SUMMARY_DTLS_PROC;

--- Get Sheet2 Details:
PROCEDURE  xxsmas_sheet2_proc (p_ledger_name IN VARCHAR2,p_period IN VARCHAR2) AS 

lv_period_number       NUMBER;
lv_period_year         VARCHAR2(15):=NULL;

BEGIN

DELETE xxsmas_sheet2_dtls_tb;
COMMIT;

--Get Period_number and Year:
BEGIN
SELECT UNIQUE gp.period_num,gp.period_year
INTO lv_period_number,lv_period_year
FROM gl_ledgers gl,
	 gl_periods gp
WHERE 1=1
AND gl.name=p_ledger_name -- parameter: ledger Name
AND gl.period_set_name=gp.period_set_name
AND gp.period_name=p_period; -- parameter: period name;
EXCEPTION WHEN OTHERS THEN
lv_period_number:=NULL;
lv_period_year:=NULL;
END;
-----

INSERT INTO "XXSMAS_SHEET2_DTLS_TB" 
   (	
    "TYPE"                  ,
	"LEDGER_NAME"           ,
	"LEDGER_CALENDAR"       ,
	"PERIOD_NAME"           , 
	"PERIOD_NUMBER"         ,
	"PERIOD_YEAR"           ,
	"LOCATION"              , 
	"LOCATION_DESCRIPTION"  ,
	"ASSET"                 , 
	"ASSET_DESCRIPTION"     , 
	"ACCOUNT"               ,
	"ACCOUNT_DESCRIPTION"   ,
	"CUSTOMER_NAME"         , 
	"OPENING_BALANCE"       ,
	"DEBIT"                 ,
	"CREDIT"                ,
	"NET_MOVEMENT"          ,
	"CLOSING_BALANCE"       
   )
SELECT  UNIQUE  
        1                                                                                     type,
        gl.name                                                                              ledger_name,
        gl.period_set_name                                                                   ledger_calendar,
        gb.period_name                                                                       period_name,
        gb.period_num                                                                        period_number,
		gb.period_year,
		gcc.segment2                                                                         location,
		apps.gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,2,gcc.segment2) location_description,
		gcc.segment3                                                                         asset,
		apps.gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,3,gcc.segment3) asset_description,
		gcc.segment4                                                                         account,
		apps.gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,4,gcc.segment4) account_description,	
        get_customer_name(p_ledger_id=>gb.ledger_id,p_code_combination_id=>gb.code_combination_id,p_period_name=>gb.period_name) customer_name, 
		SUM (NVL (gb.begin_balance_dr, 0) - NVL (gb.begin_balance_cr, 0))                    opening_balance,
		SUM(NVL (gb.period_net_dr, 0))                                                       debit,
		SUM(NVL (gb.period_net_cr,0))                                                        credit,
		SUM (NVL (gb.period_net_dr, 0) - NVL (gb.period_net_cr, 0))*-1                       net_movement,
		SUM ((NVL (gb.period_net_dr, 0) + NVL (gb.begin_balance_dr, 0)))
       - SUM (NVL (gb.period_net_cr, 0) + NVL (gb.begin_balance_cr, 0))                      closing_balance

FROM     gl_ledgers               gl,
         gl_balances              gb,
		 gl_code_combinations     gcc

WHERE 1=1
AND gl.ledger_id=gb.ledger_id
AND gb.actual_flag = 'A'
AND gb.template_id IS NULL
AND gb.period_num <=lv_period_number
AND gb.period_year=lv_period_year
AND gb.code_combination_id = gcc.code_combination_id
AND gcc.segment4 ='30349'
group by gl.name             ,
         gl.period_set_name  ,
         gb.period_name      ,
         gb.period_num       ,
		 gcc.segment2        ,	
		 gcc.segment3        ,	
         gcc.segment4        ,	
		 gb.period_year,
		 gcc.chart_of_accounts_id,
		 gb.code_combination_id,
		 gb.ledger_id
         order by segment4,segment3,gb.period_num asc;
COMMIT;		

----
DELETE xxsmas_sheet2_dtls_tb
WHERE 1=1
AND asset IN (
SELECT asset FROM(SELECT asset,SUM(net_movement) FROM xxsmas_sheet2_dtls_tb WHERE 1=1 GROUP BY asset HAVING SUM(net_movement) =0));
COMMIT;	 
-------------------------------------------------------------------------------------------------------------------------------------------------------
END xxsmas_sheet2_proc;

--- Get Sheet3 Details:
PROCEDURE  xxsmas_sheet3_proc (p_ledger_name IN VARCHAR2,p_period IN VARCHAR2) AS 

lv_period_number       NUMBER;
lv_period_year         VARCHAR2(15):=NULL;

BEGIN

DELETE xxsmas_sheet3_dtls_tb;
COMMIT;

--Get Period_number and Year:
BEGIN
SELECT UNIQUE gp.period_num,gp.period_year
INTO lv_period_number,lv_period_year
FROM gl_ledgers gl,
	 gl_periods gp
WHERE 1=1
AND gl.name=p_ledger_name -- parameter: ledger Name
AND gl.period_set_name=gp.period_set_name
AND gp.period_name=p_period; -- parameter: period name;
EXCEPTION WHEN OTHERS THEN
lv_period_number:=NULL;
lv_period_year:=NULL;
END;
-----

INSERT INTO "XXSMAS_SHEET3_DTLS_TB" 
   (	
    "TYPE"                  ,
	"LEDGER_NAME"           ,
	"LEDGER_CALENDAR"       ,
	"PERIOD_NAME"           , 
	"PERIOD_NUMBER"         ,
	"PERIOD_YEAR"           ,
	"LOCATION"              , 
	"LOCATION_DESCRIPTION"  ,
	"ASSET"                 , 
	"ASSET_DESCRIPTION"     , 
	"ACCOUNT"               ,
	"ACCOUNT_DESCRIPTION"   ,
	"CUSTOMER_NAME"         , 
	"OPENING_BALANCE"       ,
	"DEBIT"                 ,
	"CREDIT"                ,
	"NET_MOVEMENT"          ,
	"CLOSING_BALANCE"       
   )
SELECT  UNIQUE  
        1                                                                                     type,
        gl.name                                                                              ledger_name,
        gl.period_set_name                                                                   ledger_calendar,
        gb.period_name                                                                       period_name,
        gb.period_num                                                                        period_number,
		gb.period_year,
		gcc.segment2                                                                         location,
		apps.gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,2,gcc.segment2) location_description,
		gcc.segment3                                                                         asset,
		apps.gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,3,gcc.segment3) asset_description,
		gcc.segment4                                                                         account,
		apps.gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,4,gcc.segment4) account_description,	
        get_customer_name(p_ledger_id=>gb.ledger_id,p_code_combination_id=>gb.code_combination_id,p_period_name=>gb.period_name) customer_name, 
		SUM (NVL (gb.begin_balance_dr, 0) - NVL (gb.begin_balance_cr, 0))                    opening_balance,
		SUM(NVL (gb.period_net_dr, 0))                                                       debit,
		SUM(NVL (gb.period_net_cr,0))                                                        credit,
		SUM (NVL (gb.period_net_dr, 0) - NVL (gb.period_net_cr, 0))*-1                       net_movement,
		SUM ((NVL (gb.period_net_dr, 0) + NVL (gb.begin_balance_dr, 0)))
       - SUM (NVL (gb.period_net_cr, 0) + NVL (gb.begin_balance_cr, 0))                      closing_balance

FROM     gl_ledgers               gl,
         gl_balances              gb,
		 gl_code_combinations     gcc

WHERE 1=1
AND gl.ledger_id=gb.ledger_id
AND gb.actual_flag = 'A'
AND gb.template_id IS NULL
AND gb.period_num <=lv_period_number
AND gb.period_year=lv_period_year
AND gb.code_combination_id = gcc.code_combination_id
AND gcc.segment4 ='30351'
group by gl.name             ,
         gl.period_set_name  ,
         gb.period_name      ,
         gb.period_num       ,
		 gcc.segment2        ,	
		 gcc.segment3        ,	
         gcc.segment4        ,	
		 gb.period_year,
		 gcc.chart_of_accounts_id,
		 gb.code_combination_id,
		 gb.ledger_id
         order by segment4,segment3,gb.period_num asc;
COMMIT;		 

----
DELETE xxsmas_sheet3_dtls_tb
WHERE 1=1
AND asset IN (
SELECT asset FROM(SELECT asset,SUM(net_movement) FROM xxsmas_sheet3_dtls_tb WHERE 1=1 GROUP BY asset HAVING SUM(net_movement) =0));
COMMIT;	
-------------------------------------------------------------------------------------------------------------------------------------------------------
END xxsmas_sheet3_proc;

--- Get Sheet4 Details:
PROCEDURE  xxsmas_sheet4_proc (p_ledger_name IN VARCHAR2,p_period IN VARCHAR2) AS 

lv_period_number       NUMBER;
lv_period_year         VARCHAR2(15):=NULL;

BEGIN

DELETE xxsmas_sheet4_dtls_tb;
COMMIT;

--Get Period_number and Year:
BEGIN
SELECT UNIQUE gp.period_num,gp.period_year
INTO lv_period_number,lv_period_year
FROM gl_ledgers gl,
	 gl_periods gp
WHERE 1=1
AND gl.name=p_ledger_name -- parameter: ledger Name
AND gl.period_set_name=gp.period_set_name
AND gp.period_name=p_period; -- parameter: period name;
EXCEPTION WHEN OTHERS THEN
lv_period_number:=NULL;
lv_period_year:=NULL;
END;
-----

INSERT INTO "XXSMAS_SHEET4_DTLS_TB" 
   (	
    "TYPE"                  ,
	"LEDGER_NAME"           ,
	"LEDGER_CALENDAR"       ,
	"PERIOD_NAME"           , 
	"PERIOD_NUMBER"         ,
	"PERIOD_YEAR"           ,
	"LOCATION"              , 
	"LOCATION_DESCRIPTION"  ,
	"ASSET"                 , 
	"ASSET_DESCRIPTION"     , 
	"ACCOUNT"               ,
	"ACCOUNT_DESCRIPTION"   ,
	"CUSTOMER_NAME"         , 
	"OPENING_BALANCE"       ,
	"DEBIT"                 ,
	"CREDIT"                ,
	"NET_MOVEMENT"          ,
	"CLOSING_BALANCE"       
   )
SELECT  UNIQUE  
        1                                                                                     type,
        gl.name                                                                              ledger_name,
        gl.period_set_name                                                                   ledger_calendar,
        gb.period_name                                                                       period_name,
        gb.period_num                                                                        period_number,
		gb.period_year,
		gcc.segment2                                                                         location,
		apps.gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,2,gcc.segment2) location_description,
		gcc.segment3                                                                         asset,
		apps.gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,3,gcc.segment3) asset_description,
		gcc.segment4                                                                         account,
		apps.gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,4,gcc.segment4) account_description,	
        get_customer_name(p_ledger_id=>gb.ledger_id,p_code_combination_id=>gb.code_combination_id,p_period_name=>gb.period_name) customer_name, 
		SUM (NVL (gb.begin_balance_dr, 0) - NVL (gb.begin_balance_cr, 0))                    opening_balance,
		SUM(NVL (gb.period_net_dr, 0))                                                       debit,
		SUM(NVL (gb.period_net_cr,0))                                                        credit,
		SUM (NVL (gb.period_net_dr, 0) - NVL (gb.period_net_cr, 0))*-1                       net_movement,
		SUM ((NVL (gb.period_net_dr, 0) + NVL (gb.begin_balance_dr, 0)))
       - SUM (NVL (gb.period_net_cr, 0) + NVL (gb.begin_balance_cr, 0))                      closing_balance

FROM     gl_ledgers               gl,
         gl_balances              gb,
		 gl_code_combinations     gcc

WHERE 1=1
AND gl.ledger_id=gb.ledger_id
AND gb.actual_flag = 'A'
AND gb.template_id IS NULL
AND gb.period_num <=lv_period_number
AND gb.period_year=lv_period_year
AND gb.code_combination_id = gcc.code_combination_id
AND gcc.segment4 ='30350'
group by gl.name             ,
         gl.period_set_name  ,
         gb.period_name      ,
         gb.period_num       ,
		 gcc.segment2        ,	
		 gcc.segment3        ,	
         gcc.segment4        ,	
		 gb.period_year,
		 gcc.chart_of_accounts_id,
		 gb.code_combination_id,
		 gb.ledger_id
         order by segment4,segment3,gb.period_num asc;
COMMIT;		

----
DELETE xxsmas_sheet4_dtls_tb
WHERE 1=1
AND asset IN (
SELECT asset FROM(SELECT asset,SUM(net_movement) FROM xxsmas_sheet4_dtls_tb WHERE 1=1 GROUP BY asset HAVING SUM(net_movement) =0));
COMMIT;	 
-------------------------------------------------------------------------------------------------------------------------------------------------------
END xxsmas_sheet4_proc;

--- Get sheet5 Details:
PROCEDURE  xxsmas_sheet5_proc (p_ledger_name IN VARCHAR2,p_period IN VARCHAR2) AS 

lv_period_number       NUMBER;
lv_period_year         VARCHAR2(15):=NULL;

BEGIN

DELETE xxsmas_sheet5_dtls_tb;
COMMIT;

--Get Period_number and Year:
BEGIN
SELECT UNIQUE gp.period_num,gp.period_year
INTO lv_period_number,lv_period_year
FROM gl_ledgers gl,
	 gl_periods gp
WHERE 1=1
AND gl.name=p_ledger_name -- parameter: ledger Name
AND gl.period_set_name=gp.period_set_name
AND gp.period_name=p_period; -- parameter: period name;
EXCEPTION WHEN OTHERS THEN
lv_period_number:=NULL;
lv_period_year:=NULL;
END;
-----

INSERT INTO xxsmas_sheet5_dtls_tb 
   (	
    "TYPE"                  ,
	"LEDGER_NAME"           ,
	"LEDGER_CALENDAR"       ,
	"PERIOD_NAME"           , 
	"PERIOD_NUMBER"         ,
	"PERIOD_YEAR"           ,
	"LOCATION"              , 
	"LOCATION_DESCRIPTION"  ,
	"ASSET"                 , 
	"ASSET_DESCRIPTION"     , 
	"ACCOUNT"               ,
	"ACCOUNT_DESCRIPTION"   ,
	"CUSTOMER_NAME"         , 
	"OPENING_BALANCE"       ,
	"DEBIT"                 ,
	"CREDIT"                ,
	"NET_MOVEMENT"          ,
	"CLOSING_BALANCE"       
   )
SELECT  UNIQUE  
        1                                                                                     type,
        gl.name                                                                              ledger_name,
        gl.period_set_name                                                                   ledger_calendar,
        gb.period_name                                                                       period_name,
        gb.period_num                                                                        period_number,
		gb.period_year,
		gcc.segment2                                                                         location,
		apps.gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,2,gcc.segment2) location_description,
		gcc.segment3                                                                         asset,
		apps.gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,3,gcc.segment3) asset_description,
		gcc.segment4                                                                         account,
		apps.gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,4,gcc.segment4) account_description,	
        get_customer_name(p_ledger_id=>gb.ledger_id,p_code_combination_id=>gb.code_combination_id,p_period_name=>gb.period_name) customer_name, 
		SUM (NVL (gb.begin_balance_dr, 0) - NVL (gb.begin_balance_cr, 0))                    opening_balance,
		SUM(NVL (gb.period_net_dr, 0))                                                       debit,
		SUM(NVL (gb.period_net_cr,0))                                                        credit,
		SUM (NVL (gb.period_net_dr, 0) - NVL (gb.period_net_cr, 0))*-1                       net_movement,
		SUM ((NVL (gb.period_net_dr, 0) + NVL (gb.begin_balance_dr, 0)))
       - SUM (NVL (gb.period_net_cr, 0) + NVL (gb.begin_balance_cr, 0))                      closing_balance

FROM     gl_ledgers               gl,
         gl_balances              gb,
		 gl_code_combinations     gcc

WHERE 1=1
AND gl.ledger_id=gb.ledger_id
AND gb.actual_flag = 'A'
AND gb.template_id IS NULL
AND gb.period_num <=lv_period_number
AND gb.period_year=lv_period_year
AND gb.code_combination_id = gcc.code_combination_id
AND gcc.segment4 ='30800'
group by gl.name             ,
         gl.period_set_name  ,
         gb.period_name      ,
         gb.period_num       ,
		 gcc.segment2        ,	
		 gcc.segment3        ,	
         gcc.segment4        ,	
		 gb.period_year,
		 gcc.chart_of_accounts_id,
		 gb.code_combination_id,
		 gb.ledger_id
         order by segment4,segment3,gb.period_num asc;
COMMIT;	

----
DELETE xxsmas_sheet5_dtls_tb
WHERE 1=1
AND asset IN (
SELECT asset FROM(SELECT asset,SUM(net_movement) FROM xxsmas_sheet5_dtls_tb WHERE 1=1 GROUP BY asset HAVING SUM(net_movement) =0));
COMMIT;	
	 
-------------------------------------------------------------------------------------------------------------------------------------------------------
END xxsmas_sheet5_proc;

--- Get sheet6 Details:
PROCEDURE  xxsmas_sheet6_proc (p_ledger_name IN VARCHAR2,p_period IN VARCHAR2) AS 

lv_period_number       NUMBER;
lv_period_year         VARCHAR2(15):=NULL;

BEGIN

DELETE xxsmas_sheet6_dtls_tb;
COMMIT;

--Get Period_number and Year:
BEGIN
SELECT UNIQUE gp.period_num,gp.period_year
INTO lv_period_number,lv_period_year
FROM gl_ledgers gl,
	 gl_periods gp
WHERE 1=1
AND gl.name=p_ledger_name -- parameter: ledger Name
AND gl.period_set_name=gp.period_set_name
AND gp.period_name=p_period; -- parameter: period name;
EXCEPTION WHEN OTHERS THEN
lv_period_number:=NULL;
lv_period_year:=NULL;
END;
-----

INSERT INTO xxsmas_sheet6_dtls_tb
   (	
    "TYPE"                  ,
	"LEDGER_NAME"           ,
	"LEDGER_CALENDAR"       ,
	"PERIOD_NAME"           , 
	"PERIOD_NUMBER"         ,
	"PERIOD_YEAR"           ,
	"LOCATION"              , 
	"LOCATION_DESCRIPTION"  ,
	"ASSET"                 , 
	"ASSET_DESCRIPTION"     , 
	"ACCOUNT"               ,
	"ACCOUNT_DESCRIPTION"   ,
	"CUSTOMER_NAME"         , 
	"OPENING_BALANCE"       ,
	"DEBIT"                 ,
	"CREDIT"                ,
	"NET_MOVEMENT"          ,
	"CLOSING_BALANCE"       
   )
SELECT  UNIQUE  
        1                                                                                     type,
        gl.name                                                                              ledger_name,
        gl.period_set_name                                                                   ledger_calendar,
        gb.period_name                                                                       period_name,
        gb.period_num                                                                        period_number,
		gb.period_year,
		gcc.segment2                                                                         location,
		apps.gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,2,gcc.segment2) location_description,
		gcc.segment3                                                                         asset,
		apps.gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,3,gcc.segment3) asset_description,
		gcc.segment4                                                                         account,
		apps.gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,4,gcc.segment4) account_description,	
        get_customer_name(p_ledger_id=>gb.ledger_id,p_code_combination_id=>gb.code_combination_id,p_period_name=>gb.period_name) customer_name, 
		SUM (NVL (gb.begin_balance_dr, 0) - NVL (gb.begin_balance_cr, 0))                    opening_balance,
		SUM(NVL (gb.period_net_dr, 0))                                                       debit,
		SUM(NVL (gb.period_net_cr,0))                                                        credit,
		SUM (NVL (gb.period_net_dr, 0) - NVL (gb.period_net_cr, 0))*-1                       net_movement,
		SUM ((NVL (gb.period_net_dr, 0) + NVL (gb.begin_balance_dr, 0)))
       - SUM (NVL (gb.period_net_cr, 0) + NVL (gb.begin_balance_cr, 0))                      closing_balance

FROM     gl_ledgers               gl,
         gl_balances              gb,
		 gl_code_combinations     gcc

WHERE 1=1
AND gl.ledger_id=gb.ledger_id
AND gb.actual_flag = 'A'
AND gb.template_id IS NULL
AND gb.period_num <=lv_period_number
AND gb.period_year=lv_period_year
AND gb.code_combination_id = gcc.code_combination_id
AND gcc.segment4 ='30212'
group by gl.name             ,
         gl.period_set_name  ,
         gb.period_name      ,
         gb.period_num       ,
		 gcc.segment2        ,	
		 gcc.segment3        ,	
         gcc.segment4        ,	
		 gb.period_year,
		 gcc.chart_of_accounts_id,
		 gb.code_combination_id,
		 gb.ledger_id
         order by segment4,segment3,gb.period_num asc;
COMMIT;	

----
DELETE xxsmas_sheet6_dtls_tb
WHERE 1=1
AND asset IN (
SELECT asset FROM(SELECT asset,SUM(net_movement) FROM xxsmas_sheet6_dtls_tb WHERE 1=1 GROUP BY asset HAVING SUM(net_movement) =0));
COMMIT;		 
-------------------------------------------------------------------------------------------------------------------------------------------------------
END xxsmas_sheet6_proc;

--- Get sheet7 Details:
PROCEDURE  xxsmas_sheet7_proc (p_ledger_name IN VARCHAR2,p_period IN VARCHAR2) AS 

lv_period_number       NUMBER;
lv_period_year         VARCHAR2(15):=NULL;

BEGIN

DELETE xxsmas_sheet7_dtls_tb;
COMMIT;

--Get Period_number and Year:
BEGIN
SELECT UNIQUE gp.period_num,gp.period_year
INTO lv_period_number,lv_period_year
FROM gl_ledgers gl,
	 gl_periods gp
WHERE 1=1
AND gl.name=p_ledger_name -- parameter: ledger Name
AND gl.period_set_name=gp.period_set_name
AND gp.period_name=p_period; -- parameter: period name;
EXCEPTION WHEN OTHERS THEN
lv_period_number:=NULL;
lv_period_year:=NULL;
END;
-----

INSERT INTO xxsmas_sheet7_dtls_tb
   (	
    "TYPE"                  ,
	"LEDGER_NAME"           ,
	"LEDGER_CALENDAR"       ,
	"PERIOD_NAME"           , 
	"PERIOD_NUMBER"         ,
	"PERIOD_YEAR"           ,
	"LOCATION"              , 
	"LOCATION_DESCRIPTION"  ,
	"ASSET"                 , 
	"ASSET_DESCRIPTION"     , 
	"ACCOUNT"               ,
	"ACCOUNT_DESCRIPTION"   ,
	"CUSTOMER_NAME"         , 
	"OPENING_BALANCE"       ,
	"DEBIT"                 ,
	"CREDIT"                ,
	"NET_MOVEMENT"          ,
	"CLOSING_BALANCE"       
   )
SELECT  UNIQUE  
        1                                                                                     type,
        gl.name                                                                              ledger_name,
        gl.period_set_name                                                                   ledger_calendar,
        gb.period_name                                                                       period_name,
        gb.period_num                                                                        period_number,
		gb.period_year,
		gcc.segment2                                                                         location,
		apps.gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,2,gcc.segment2) location_description,
		gcc.segment3                                                                         asset,
		apps.gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,3,gcc.segment3) asset_description,
		gcc.segment4                                                                         account,
		apps.gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,4,gcc.segment4) account_description,	
        get_customer_name(p_ledger_id=>gb.ledger_id,p_code_combination_id=>gb.code_combination_id,p_period_name=>gb.period_name) customer_name, 
		SUM (NVL (gb.begin_balance_dr, 0) - NVL (gb.begin_balance_cr, 0))                    opening_balance,
		SUM(NVL (gb.period_net_dr, 0))                                                       debit,
		SUM(NVL (gb.period_net_cr,0))                                                        credit,
		SUM (NVL (gb.period_net_dr, 0) - NVL (gb.period_net_cr, 0))*-1                       net_movement,
		SUM ((NVL (gb.period_net_dr, 0) + NVL (gb.begin_balance_dr, 0)))
       - SUM (NVL (gb.period_net_cr, 0) + NVL (gb.begin_balance_cr, 0))                      closing_balance

FROM     gl_ledgers               gl,
         gl_balances              gb,
		 gl_code_combinations     gcc

WHERE 1=1
AND gl.ledger_id=gb.ledger_id
AND gb.actual_flag = 'A'
AND gb.template_id IS NULL
AND gb.period_num <=lv_period_number
AND gb.period_year=lv_period_year
AND gb.code_combination_id = gcc.code_combination_id
AND gcc.segment4 ='38003'
group by gl.name             ,
         gl.period_set_name  ,
         gb.period_name      ,
         gb.period_num       ,
		 gcc.segment2        ,	
		 gcc.segment3        ,	
         gcc.segment4        ,	
		 gb.period_year,
		 gcc.chart_of_accounts_id,
		 gb.code_combination_id,
		 gb.ledger_id
         order by segment4,segment3,gb.period_num asc;
COMMIT;		 

----
DELETE xxsmas_sheet7_dtls_tb
WHERE 1=1
AND asset IN (
SELECT asset FROM(SELECT asset,SUM(net_movement) FROM xxsmas_sheet7_dtls_tb WHERE 1=1 GROUP BY asset HAVING SUM(net_movement) =0));
COMMIT;	
-------------------------------------------------------------------------------------------------------------------------------------------------------
END xxsmas_sheet7_proc;

--- Get sheet9 Details:
PROCEDURE  xxsmas_sheet9_proc (p_ledger_name IN VARCHAR2,p_period IN VARCHAR2) AS 

lv_period_number       NUMBER;
lv_period_year         VARCHAR2(15):=NULL;

BEGIN

DELETE xxsmas_sheet9_dtls_tb;
COMMIT;

--Get Period_number and Year:
BEGIN
SELECT UNIQUE gp.period_num,gp.period_year
INTO lv_period_number,lv_period_year
FROM gl_ledgers gl,
	 gl_periods gp
WHERE 1=1
AND gl.name=p_ledger_name -- parameter: ledger Name
AND gl.period_set_name=gp.period_set_name
AND gp.period_name=p_period; -- parameter: period name;
EXCEPTION WHEN OTHERS THEN
lv_period_number:=NULL;
lv_period_year:=NULL;
END;
-----

INSERT INTO xxsmas_sheet9_dtls_tb
   (	
    "TYPE"                  ,
	"LEDGER_NAME"           ,
	"LEDGER_CALENDAR"       ,
	"PERIOD_NAME"           , 
	"PERIOD_NUMBER"         ,
	"PERIOD_YEAR"           ,
	"LOCATION"              , 
	"LOCATION_DESCRIPTION"  ,
	"ASSET"                 , 
	"ASSET_DESCRIPTION"     , 
	"ACCOUNT"               ,
	"ACCOUNT_DESCRIPTION"   ,
	"CUSTOMER_NAME"         , 
	"OPENING_BALANCE"       ,
	"DEBIT"                 ,
	"CREDIT"                ,
	"NET_MOVEMENT"          ,
	"CLOSING_BALANCE"       
   )
SELECT  UNIQUE  
        1                                                                                     type,
        gl.name                                                                              ledger_name,
        gl.period_set_name                                                                   ledger_calendar,
        gb.period_name                                                                       period_name,
        gb.period_num                                                                        period_number,
		gb.period_year,
		gcc.segment2                                                                         location,
		apps.gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,2,gcc.segment2) location_description,
		gcc.segment3                                                                         asset,
		apps.gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,3,gcc.segment3) asset_description,
		gcc.segment4                                                                         account,
		apps.gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,4,gcc.segment4) account_description,	
        get_customer_name(p_ledger_id=>gb.ledger_id,p_code_combination_id=>gb.code_combination_id,p_period_name=>gb.period_name) customer_name, 
		SUM (NVL (gb.begin_balance_dr, 0) - NVL (gb.begin_balance_cr, 0))                    opening_balance,
		SUM(NVL (gb.period_net_dr, 0))                                                       debit,
		SUM(NVL (gb.period_net_cr,0))                                                        credit,
		SUM (NVL (gb.period_net_dr, 0) - NVL (gb.period_net_cr, 0))*-1                       net_movement,
		SUM ((NVL (gb.period_net_dr, 0) + NVL (gb.begin_balance_dr, 0)))
       - SUM (NVL (gb.period_net_cr, 0) + NVL (gb.begin_balance_cr, 0))                      closing_balance

FROM     gl_ledgers               gl,
         gl_balances              gb,
		 gl_code_combinations     gcc

WHERE 1=1
AND gl.ledger_id=gb.ledger_id
AND gb.actual_flag = 'A'
AND gb.template_id IS NULL
AND gb.period_num <=lv_period_number
AND gb.period_year=lv_period_year
AND gb.code_combination_id = gcc.code_combination_id
AND gcc.segment4 ='30353'
group by gl.name             ,
         gl.period_set_name  ,
         gb.period_name      ,
         gb.period_num       ,
		 gcc.segment2        ,	
		 gcc.segment3        ,	
         gcc.segment4        ,	
		 gb.period_year,
		 gcc.chart_of_accounts_id,
		 gb.code_combination_id,
		 gb.ledger_id
         order by segment4,segment3,gb.period_num asc;
COMMIT;	

----
DELETE xxsmas_sheet9_dtls_tb
WHERE 1=1
AND asset IN (
SELECT asset FROM(SELECT asset,SUM(net_movement) FROM xxsmas_sheet9_dtls_tb WHERE 1=1 GROUP BY asset HAVING SUM(net_movement) =0));
COMMIT;		 
-------------------------------------------------------------------------------------------------------------------------------------------------------
END xxsmas_sheet9_proc;

--- Get sheet10 Details:
PROCEDURE  xxsmas_sheet10_proc (p_ledger_name IN VARCHAR2,p_period IN VARCHAR2) AS 

lv_period_number       NUMBER;
lv_period_year         VARCHAR2(15):=NULL;

BEGIN

DELETE xxsmas_sheet10_dtls_tb;
COMMIT;

--Get Period_number and Year:
BEGIN
SELECT UNIQUE gp.period_num,gp.period_year
INTO lv_period_number,lv_period_year
FROM gl_ledgers gl,
	 gl_periods gp
WHERE 1=1
AND gl.name=p_ledger_name -- parameter: ledger Name
AND gl.period_set_name=gp.period_set_name
AND gp.period_name=p_period; -- parameter: period name;
EXCEPTION WHEN OTHERS THEN
lv_period_number:=NULL;
lv_period_year:=NULL;
END;
-----

INSERT INTO xxsmas_sheet10_dtls_tb
   (	
    "TYPE"                  ,
	"LEDGER_NAME"           ,
	"LEDGER_CALENDAR"       ,
	"PERIOD_NAME"           , 
	"PERIOD_NUMBER"         ,
	"PERIOD_YEAR"           ,
	"LOCATION"              , 
	"LOCATION_DESCRIPTION"  ,
	"ASSET"                 , 
	"ASSET_DESCRIPTION"     , 
	"ACCOUNT"               ,
	"ACCOUNT_DESCRIPTION"   ,
	"CUSTOMER_NAME"         , 
	"OPENING_BALANCE"       ,
	"DEBIT"                 ,
	"CREDIT"                ,
	"NET_MOVEMENT"          ,
	"CLOSING_BALANCE"       
   )
SELECT  UNIQUE  
        1                                                                                     type,
        gl.name                                                                              ledger_name,
        gl.period_set_name                                                                   ledger_calendar,
        gb.period_name                                                                       period_name,
        gb.period_num                                                                        period_number,
		gb.period_year,
		gcc.segment2                                                                         location,
		apps.gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,2,gcc.segment2) location_description,
		gcc.segment3                                                                         asset,
		apps.gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,3,gcc.segment3) asset_description,
		gcc.segment4                                                                         account,
		apps.gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,4,gcc.segment4) account_description,	
        get_customer_name(p_ledger_id=>gb.ledger_id,p_code_combination_id=>gb.code_combination_id,p_period_name=>gb.period_name) customer_name, 
		SUM (NVL (gb.begin_balance_dr, 0) - NVL (gb.begin_balance_cr, 0))                    opening_balance,
		SUM(NVL (gb.period_net_dr, 0))                                                       debit,
		SUM(NVL (gb.period_net_cr,0))                                                        credit,
		SUM (NVL (gb.period_net_dr, 0) - NVL (gb.period_net_cr, 0))*-1                       net_movement,
		SUM ((NVL (gb.period_net_dr, 0) + NVL (gb.begin_balance_dr, 0)))
       - SUM (NVL (gb.period_net_cr, 0) + NVL (gb.begin_balance_cr, 0))                      closing_balance

FROM     gl_ledgers               gl,
         gl_balances              gb,
		 gl_code_combinations     gcc

WHERE 1=1
AND gl.ledger_id=gb.ledger_id
AND gb.actual_flag = 'A'
AND gb.template_id IS NULL
AND gb.period_num <=lv_period_number
AND gb.period_year=lv_period_year
AND gb.code_combination_id = gcc.code_combination_id
AND gcc.segment4 ='30403'
group by gl.name             ,
         gl.period_set_name  ,
         gb.period_name      ,
         gb.period_num       ,
		 gcc.segment2        ,	
		 gcc.segment3        ,	
         gcc.segment4        ,	
		 gb.period_year,
		 gcc.chart_of_accounts_id,
		 gb.code_combination_id,
		 gb.ledger_id
         order by segment4,segment3,gb.period_num asc;
COMMIT;	

----
DELETE xxsmas_sheet10_dtls_tb
WHERE 1=1
AND asset IN (
SELECT asset FROM(SELECT asset,SUM(net_movement) FROM xxsmas_sheet10_dtls_tb WHERE 1=1 GROUP BY asset HAVING SUM(net_movement) =0));
COMMIT;	 
-------------------------------------------------------------------------------------------------------------------------------------------------------
END xxsmas_sheet10_proc;

--- Get sheet11 Details:
PROCEDURE  xxsmas_sheet11_proc (p_ledger_name IN VARCHAR2,p_period IN VARCHAR2) AS 

lv_period_number       NUMBER;
lv_period_year         VARCHAR2(15):=NULL;

BEGIN

DELETE xxsmas_sheet11_dtls_tb;
COMMIT;

--Get Period_number and Year:
BEGIN
SELECT UNIQUE gp.period_num,gp.period_year
INTO lv_period_number,lv_period_year
FROM gl_ledgers gl,
	 gl_periods gp
WHERE 1=1
AND gl.name=p_ledger_name -- parameter: ledger Name
AND gl.period_set_name=gp.period_set_name
AND gp.period_name=p_period; -- parameter: period name;
EXCEPTION WHEN OTHERS THEN
lv_period_number:=NULL;
lv_period_year:=NULL;
END;
-----

INSERT INTO xxsmas_sheet11_dtls_tb
   (	
    "TYPE"                  ,
	"LEDGER_NAME"           ,
	"LEDGER_CALENDAR"       ,
	"PERIOD_NAME"           , 
	"PERIOD_NUMBER"         ,
	"PERIOD_YEAR"           ,
	"LOCATION"              , 
	"LOCATION_DESCRIPTION"  ,
	"ASSET"                 , 
	"ASSET_DESCRIPTION"     , 
	"ACCOUNT"               ,
	"ACCOUNT_DESCRIPTION"   ,
	"CUSTOMER_NAME"         , 
	"OPENING_BALANCE"       ,
	"DEBIT"                 ,
	"CREDIT"                ,
	"NET_MOVEMENT"          ,
	"CLOSING_BALANCE"       
   )
SELECT  UNIQUE  
        1                                                                                     type,
        gl.name                                                                              ledger_name,
        gl.period_set_name                                                                   ledger_calendar,
        gb.period_name                                                                       period_name,
        gb.period_num                                                                        period_number,
		gb.period_year,
		gcc.segment2                                                                         location,
		apps.gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,2,gcc.segment2) location_description,
		gcc.segment3                                                                         asset,
		apps.gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,3,gcc.segment3) asset_description,
		gcc.segment4                                                                         account,
		apps.gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,4,gcc.segment4) account_description,	
        get_customer_name(p_ledger_id=>gb.ledger_id,p_code_combination_id=>gb.code_combination_id,p_period_name=>gb.period_name) customer_name, 
		SUM (NVL (gb.begin_balance_dr, 0) - NVL (gb.begin_balance_cr, 0))                    opening_balance,
		SUM(NVL (gb.period_net_dr, 0))                                                       debit,
		SUM(NVL (gb.period_net_cr,0))                                                        credit,
		SUM (NVL (gb.period_net_dr, 0) - NVL (gb.period_net_cr, 0))*-1                       net_movement,
		SUM ((NVL (gb.period_net_dr, 0) + NVL (gb.begin_balance_dr, 0)))
       - SUM (NVL (gb.period_net_cr, 0) + NVL (gb.begin_balance_cr, 0))                      closing_balance

FROM     gl_ledgers               gl,
         gl_balances              gb,
		 gl_code_combinations     gcc

WHERE 1=1
AND gl.ledger_id=gb.ledger_id
AND gb.actual_flag = 'A'
AND gb.template_id IS NULL
AND gb.period_num <=lv_period_number
AND gb.period_year=lv_period_year
AND gb.code_combination_id = gcc.code_combination_id
AND gcc.segment4 ='30501'
group by gl.name             ,
         gl.period_set_name  ,
         gb.period_name      ,
         gb.period_num       ,
		 gcc.segment2        ,	
		 gcc.segment3        ,	
         gcc.segment4        ,	
		 gb.period_year,
		 gcc.chart_of_accounts_id,
		 gb.code_combination_id,
		 gb.ledger_id
         order by segment4,segment3,gb.period_num asc;
COMMIT;		 

----
DELETE xxsmas_sheet11_dtls_tb
WHERE 1=1
AND asset IN (
SELECT asset FROM(SELECT asset,SUM(net_movement) FROM xxsmas_sheet11_dtls_tb WHERE 1=1 GROUP BY asset HAVING SUM(net_movement) =0));
COMMIT;
-------------------------------------------------------------------------------------------------------------------------------------------------------
END xxsmas_sheet11_proc;

--- Get Sheet1 Main Details:
PROCEDURE xxsmas_sheet_main(errbuf OUT VARCHAR2,
                             retcode OUT VARCHAR2,
							 p_ledger_name IN VARCHAR2,
							 p_period IN VARCHAR2)
AS

lv_serial_number NUMBER:=0;
lv_total_lr      NUMBER:=0;
lv_total_fms     NUMBER:=0;

lv_period_number       NUMBER;
lv_period_year         VARCHAR2(15):=NULL;
lv_total               NUMBER:=0;
lv_sheet               VARCHAR2(10):=NULL;
lv_client_name         VARCHAR2(240):=NULL;

BEGIN

--Get Period_number and Year:
BEGIN
SELECT UNIQUE gp.period_num,gp.period_year
INTO lv_period_number,lv_period_year
FROM gl_ledgers gl,
	 gl_periods gp
WHERE 1=1
AND gl.name=p_ledger_name -- parameter: ledger Name
AND gl.period_set_name=gp.period_set_name
AND gp.period_name=p_period; -- parameter: period name;
EXCEPTION WHEN OTHERS THEN
lv_period_number:=NULL;
lv_period_year:=NULL;
END;

BEGIN
xxsmas_summary_dtls_proc(p_ledger_name=>p_ledger_name,p_period=>p_period);
END;

BEGIN
xxsmas_sheet1_proc(p_ledger_name=>p_ledger_name,p_period=>p_period);
END; 

BEGIN
xxsmas_sheet2_proc(p_ledger_name=>p_ledger_name,p_period=>p_period);
END; 


BEGIN
xxsmas_sheet3_proc(p_ledger_name=>p_ledger_name,p_period=>p_period);
END; 

BEGIN
xxsmas_sheet4_proc(p_ledger_name=>p_ledger_name,p_period=>p_period);
END; 

BEGIN
xxsmas_sheet5_proc(p_ledger_name=>p_ledger_name,p_period=>p_period);
END; 

BEGIN
xxsmas_sheet6_proc(p_ledger_name=>p_ledger_name,p_period=>p_period);
END; 

BEGIN
xxsmas_sheet7_proc(p_ledger_name=>p_ledger_name,p_period=>p_period);
END; 

BEGIN
xxsmas_sheet9_proc(p_ledger_name=>p_ledger_name,p_period=>p_period);
END; 

BEGIN
xxsmas_sheet10_proc(p_ledger_name=>p_ledger_name,p_period=>p_period);
END; 

BEGIN
xxsmas_sheet11_proc(p_ledger_name=>p_ledger_name,p_period=>p_period);
END; 


fnd_file.put_line(fnd_file.output,'<?xml version="1.0"?>
<?mso-application progid="Excel.Sheet"?>
<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"
 xmlns:o="urn:schemas-microsoft-com:office:office"
 xmlns:x="urn:schemas-microsoft-com:office:excel"
 xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"
 xmlns:html="http://www.w3.org/TR/REC-html40">
 <DocumentProperties xmlns="urn:schemas-microsoft-com:office:office">
  <Author>Tamilselvan.E</Author>
  <LastAuthor>Tamilselvan.E</LastAuthor>
  <Created>2022-09-07T13:33:18Z</Created>
  <LastSaved>2022-09-07T13:38:53Z</LastSaved>
  <Version>16.00</Version>
 </DocumentProperties>
 <OfficeDocumentSettings xmlns="urn:schemas-microsoft-com:office:office">
  <AllowPNG/>
 </OfficeDocumentSettings>
 <ExcelWorkbook xmlns="urn:schemas-microsoft-com:office:excel">
  <WindowHeight>7050</WindowHeight>
  <WindowWidth>20490</WindowWidth>
  <WindowTopX>0</WindowTopX>
  <WindowTopY>0</WindowTopY>
  <ProtectStructure>False</ProtectStructure>
  <ProtectWindows>False</ProtectWindows>
 </ExcelWorkbook>
 <Styles>
  <Style ss:ID="Default" ss:Name="Normal">
   <Alignment ss:Vertical="Bottom"/>
   <Borders/>
   <Font ss:FontName="Calibri" x:Family="Swiss" ss:Size="11" ss:Color="#000000"/>
   <Interior/>
   <NumberFormat/>
   <Protection/>
  </Style>
  <Style ss:ID="s62">
   <Alignment ss:Horizontal="Center" ss:Vertical="Bottom"/>
   <Borders/>
   <Font ss:FontName="Tahoma" x:Family="Swiss" ss:Color="#000000" ss:Bold="1"/>
  </Style>
  <Style ss:ID="s63">
   <Alignment ss:Horizontal="Center" ss:Vertical="Bottom"/>
   <Borders/>
   <Font ss:FontName="Tahoma" x:Family="Swiss" ss:Color="#000000" ss:Bold="1"/>
   <Interior ss:Color="#FFFF00" ss:Pattern="Solid"/>
  </Style>
  <Style ss:ID="s64">
   <Interior ss:Color="#FFFF00" ss:Pattern="Solid"/>
  </Style>
  <Style ss:ID="s65">
   <Font ss:FontName="Tahoma" x:Family="Swiss" ss:Color="#000000" ss:Bold="1"/>
  </Style>
  <Style ss:ID="s68">
   <Borders/>
   <Font ss:FontName="Tahoma" x:Family="Swiss" ss:Color="#000000" ss:Bold="1"/>
  </Style>
  <Style ss:ID="s69">
   <Alignment ss:Horizontal="Center" ss:Vertical="Bottom"/>
   <Borders/>
   <Font ss:FontName="Tahoma" x:Family="Swiss" ss:Color="#000000" ss:Bold="1"/>
  </Style>
  <Style ss:ID="s73">
   <Borders/>
   <Font ss:FontName="Tahoma" x:Family="Swiss" ss:Color="#000000"/>
  </Style>
  <Style ss:ID="s74">
   <Alignment ss:Vertical="Top" ss:WrapText="1"/>
   <Borders/>
   <Font ss:FontName="Tahoma" x:Family="Swiss" ss:Color="#000000"/>
   <Interior ss:Color="#FFFFFF" ss:Pattern="Solid"/>
  </Style>
    <Style ss:ID="Bold">
     <Font ss:Bold="1"/>
  </Style>
    <Style ss:ID="s75">
   <Borders/>
   <Font ss:FontName="Tahoma" x:Family="Swiss" ss:Color="#000000" ss:Bold="1"/>
   <Interior ss:Color="#FFFF00" ss:Pattern="Solid"/>
  </Style>
 </Styles>');
 
 --- Summary:
 
 
 fnd_file.put_line(fnd_file.output,'
 <Worksheet ss:Name="Summary">
  <Table ss:ExpandedColumnCount="100" ss:ExpandedRowCount="100" x:FullColumns="1"
   x:FullRows="1" ss:DefaultRowHeight="15">
<Column ss:AutoFitWidth="0" ss:Width="80"/>
<Column ss:AutoFitWidth="0" ss:Width="120"/>
<Column ss:AutoFitWidth="0" ss:Width="80"/>
<Column ss:AutoFitWidth="0" ss:Width="80"/>');

FOR j IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
LOOP
fnd_file.put_line(fnd_file.output,'<Column ss:AutoFitWidth="0" ss:Width="90"/>');
END LOOP;

fnd_file.put_line(fnd_file.output,'
   <Row>
    <Cell ss:StyleID="s65"><Data ss:Type="String">SMAS Auto Leasing India Private Limited</Data></Cell>
   </Row>
   <Row>
    <Cell ss:StyleID="s65"><Data ss:Type="String">Schedule of Revenue from operation/Other Income as at '||p_period||'</Data></Cell>
   </Row>
   <Row ss:Index="4">
    <Cell ss:StyleID="s75"><Data ss:Type="String">A/c Code</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Account Name</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Sheet No.</Data></Cell>
	<Cell ss:StyleID="s75"><Data ss:Type="String">Total</Data></Cell>');
	
	FOR i IN (SELECT period_name,period_num,period_year FROM gl_periods
              WHERE 1=1
              AND period_year=lv_period_year
			  AND period_num<=lv_period_number
              ORDER BY period_num DESC)
      LOOP
	  fnd_file.put_line(fnd_file.output,'<Cell ss:StyleID="s75"><Data ss:Type="String">'||i.period_name||'</Data></Cell>');
	  END LOOP;
	  fnd_file.put_line(fnd_file.output,'</Row>');  

   FOR i IN (SELECT UNIQUE account,account_description,DECODE(account,'30100','1','30200','1','30349','2','30351','3') sheet  
              FROM xxsmas_summary_dtls_tb 
			  WHERE TYPE=1 
			  ORDER BY account ASC)
   LOOP   
   
   lv_sheet:=i.sheet;
   fnd_file.put_line(fnd_file.output,'
    <Row>
    <Cell><Data ss:Type="String">'||i.account||'</Data></Cell>
    <Cell><Data ss:Type="String">'||i.account_description||'</Data></Cell>	
    <Cell><Data ss:Type="String">'||lv_sheet||'</Data></Cell>');
	 
	  lv_total:=0;
	  
	  BEGIN
	  SELECT SUM(NVL(net_movement,0)) 
	  INTO lv_total 
	  FROM xxsmas_summary_dtls_tb 
	  WHERE 1=1 
	  AND account=i.account;
	  EXCEPTION WHEN OTHERS THEN
	  lv_total :=0;
	  END;
	
	fnd_file.put_line(fnd_file.output,'  
	<Cell><Data ss:Type="String">'||lv_total ||'</Data></Cell>');
	
	FOR j IN (SELECT period_name,period_num,period_year FROM gl_periods
              WHERE 1=1
              AND period_year=lv_period_year
			  AND period_num<=lv_period_number
              ORDER BY period_num DESC)
      LOOP
	  
	  lv_total:=0;
	  
	  BEGIN
	  SELECT SUM(NVL(net_movement,0)) 
	  INTO lv_total 
	  FROM xxsmas_summary_dtls_tb 
	  WHERE 1=1 
	  AND TYPE=1
	  AND account=i.account 
	  AND period_name=j.period_name;
	  EXCEPTION WHEN OTHERS THEN
	  lv_total :=0;
	  END;
	  
	  fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');
	  END LOOP;			
      fnd_file.put_line(fnd_file.output,'</Row>');
   END LOOP;
   
     fnd_file.put_line(fnd_file.output,'<Row>
    <Cell><Data ss:Type="String"></Data></Cell>
   </Row>');
   
      lv_total:=0;
	  
	  BEGIN
	  SELECT SUM(NVL(net_movement,0)) 
	  INTO lv_total 
	  FROM xxsmas_summary_dtls_tb 
	  WHERE 1=1 
	  AND TYPE=1;
	  EXCEPTION WHEN OTHERS THEN
	  lv_total :=0;
	  END;
	  
   fnd_file.put_line(fnd_file.output,'<Row>
    <Cell><Data ss:Type="String"></Data></Cell>
	<Cell ss:StyleID="s75"><Data ss:Type="String">Total :</Data></Cell>
	<Cell><Data ss:Type="String"></Data></Cell>
	<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');
	
		FOR j IN (SELECT period_name,period_num,period_year FROM gl_periods
              WHERE 1=1
              AND period_year=lv_period_year
			  AND period_num<=lv_period_number
              ORDER BY period_num DESC)
      LOOP
	  
	  lv_total:=0;
	  
	  BEGIN
	  SELECT SUM(NVL(net_movement,0)) 
	  INTO lv_total 
	  FROM xxsmas_summary_dtls_tb 
	  WHERE 1=1 
	  AND TYPE=1
	  AND period_name=j.period_name;
	  EXCEPTION WHEN OTHERS THEN
	  lv_total :=0;
	  END;
	  
	  fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');
	  
	  END LOOP;	
	  
      fnd_file.put_line(fnd_file.output,'</Row>');
   
   
   
     fnd_file.put_line(fnd_file.output,'<Row>
    <Cell><Data ss:Type="String"></Data></Cell>
   </Row>');


   FOR i IN (SELECT UNIQUE account,account_description,DECODE
                                                    (account,
                                                     '30350','4',
                                                     '30353','9',
                                                     '30403','10', 
                                                     '30800','5',
                                                     '30212','6',
                                                     '30501','11',
                                                     '38003','7') sheet 
			FROM xxsmas_summary_dtls_tb 
			WHERE TYPE=2 
			ORDER BY account ASC)
   
   LOOP 
   
   lv_sheet:=i.sheet;
   
   fnd_file.put_line(fnd_file.output,'
   <Row>
    <Cell><Data ss:Type="String">'||i.account||'</Data></Cell>
    <Cell><Data ss:Type="String">'||i.account_description||'</Data></Cell>	
    <Cell><Data ss:Type="String">'||lv_sheet||'</Data></Cell>');
	
	  lv_total:=0;
	  
	  BEGIN
	  SELECT SUM(NVL(net_movement,0)) 
	  INTO lv_total 
	  FROM xxsmas_summary_dtls_tb 
	  WHERE 1=1 
	  AND account=i.account;
	  EXCEPTION WHEN OTHERS THEN
	  lv_total :=0;
	  END;
	
	fnd_file.put_line(fnd_file.output,'  
	<Cell><Data ss:Type="String">'||lv_total ||'</Data></Cell>');
	
	FOR j IN (SELECT period_name,period_num,period_year FROM gl_periods
              WHERE 1=1
              AND period_year=lv_period_year
			  AND period_num<=lv_period_number
              ORDER BY period_num DESC)
      LOOP
	  
	  lv_total:=0;
	  BEGIN
	  SELECT SUM(NVL(net_movement,0)) 
	  INTO lv_total 
	  FROM xxsmas_summary_dtls_tb 
	  WHERE 1=1 
	  AND TYPE=2
	  AND ACCOUNT=i.account 
	  AND period_name=j.period_name;
	  EXCEPTION WHEN OTHERS THEN
	  lv_total :=0;
	  END;
	  
	  fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');
	  END LOOP;			
      fnd_file.put_line(fnd_file.output,'</Row>');
   END LOOP;
   
   
     fnd_file.put_line(fnd_file.output,'<Row>
    <Cell><Data ss:Type="String"></Data></Cell>
   </Row>');
   
      lv_total:=0;
	  BEGIN
	  SELECT SUM(NVL(net_movement,0)) 
	  INTO lv_total 
	  FROM xxsmas_summary_dtls_tb 
	  WHERE 1=1 
	  AND TYPE=2;
	  EXCEPTION WHEN OTHERS THEN
	  lv_total :=0;
	  END;
	  
   fnd_file.put_line(fnd_file.output,'<Row>
    <Cell><Data ss:Type="String"></Data></Cell>
	<Cell ss:StyleID="s75"><Data ss:Type="String">Total :</Data></Cell>
	<Cell><Data ss:Type="String"></Data></Cell>
	<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');
	
		FOR j IN (SELECT period_name,period_num,period_year FROM gl_periods
              WHERE 1=1
              AND period_year=lv_period_year
			  AND period_num<=lv_period_number
              ORDER BY period_num DESC)
      LOOP
	  
	  lv_total:=0;
	  
	  BEGIN
	  SELECT SUM(NVL(net_movement,0)) 
	  INTO lv_total 
	  FROM xxsmas_summary_dtls_tb 
	  WHERE 1=1 
	  AND TYPE=2
	  AND period_name=j.period_name;
	  EXCEPTION WHEN OTHERS THEN
	  lv_total :=0;
	  END;
	  
	  fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');
	  
	  END LOOP;	
	  
   fnd_file.put_line(fnd_file.output,'</Row>');
   
   
   fnd_file.put_line(fnd_file.output,'<Row>
    <Cell><Data ss:Type="String"></Data></Cell>
   </Row>');

     lv_total:=0;
	 
  	  BEGIN
	  SELECT SUM(NVL(net_movement,0)) 
	  INTO lv_total 
	  FROM xxsmas_summary_dtls_tb 
	  WHERE 1=1;
	  EXCEPTION WHEN OTHERS THEN
	  lv_total :=0;
	  END;
	  
   fnd_file.put_line(fnd_file.output,'<Row>
    <Cell><Data ss:Type="String"></Data></Cell>
	<Cell ss:StyleID="s75"><Data ss:Type="String">Grand Total :</Data></Cell>
	<Cell><Data ss:Type="String"></Data></Cell>
	<Cell ss:StyleID="s65"><Data ss:Type="Number">'||lv_total||'</Data></Cell>');
	
		FOR j IN (SELECT period_name,period_num,period_year FROM gl_periods
              WHERE 1=1
              AND period_year=lv_period_year
			  AND period_num<=lv_period_number
              ORDER BY period_num DESC)
      LOOP
	  
	  lv_total:=0;
	  
	  BEGIN
	  SELECT SUM(NVL(net_movement,0)) 
	  INTO lv_total 
	  FROM xxsmas_summary_dtls_tb 
	  WHERE 1=1 
	  AND period_name=j.period_name;
	  EXCEPTION WHEN OTHERS THEN
	  lv_total :=0;
	  END;
	  
	  fnd_file.put_line(fnd_file.output,'<Cell ss:StyleID="s65"><Data ss:Type="Number">'||lv_total||'</Data></Cell>');
	  
	  END LOOP;	
	  
   fnd_file.put_line(fnd_file.output,'</Row>');
   
   
   fnd_file.put_line(fnd_file.output,'
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <PageSetup>
    <Header x:Margin="0.3"/>
    <Footer x:Margin="0.3"/>
    <PageMargins x:Bottom="0.75" x:Left="0.7" x:Right="0.7" x:Top="0.75"/>
   </PageSetup>
   <Selected/>
   <Panes>
    <Pane>
     <Number>3</Number>
     <ActiveRow>4</ActiveRow>
     <ActiveCol>3</ActiveCol>
    </Pane>
   </Panes>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>');
 --------------------------------Summary Completed-----------------------------------------------
 fnd_file.put_line(fnd_file.output,'
 <Worksheet ss:Name="1.OL LR AND FMS Rev">
  <Table ss:ExpandedColumnCount="100" ss:ExpandedRowCount="10000000" x:FullColumns="1"
   x:FullRows="1" ss:DefaultColumnWidth="63.75" ss:DefaultRowHeight="15">
   <Column ss:AutoFitWidth="0" ss:Width="75"/>
   <Column ss:AutoFitWidth="0" ss:Width="91.5"/>
   <Column ss:AutoFitWidth="0" ss:Width="75.75"/>
   <Column ss:AutoFitWidth="0" ss:Width="81"/>
   <Column ss:AutoFitWidth="0" ss:Width="85.5"/>
   <Column ss:AutoFitWidth="0" ss:Width="79.5"/>
   <Column ss:AutoFitWidth="0" ss:Width="76.5"/>
   <Column ss:AutoFitWidth="0" ss:Width="82.5"/>
   <Column ss:AutoFitWidth="0" ss:Width="94.5"/>
   <Column ss:AutoFitWidth="0" ss:Width="78"/>');
   
   	  FOR j IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
      LOOP
	  fnd_file.put_line(fnd_file.output,'<Column ss:AutoFitWidth="0" ss:Width="90"/>');
	  END LOOP;
	  
	 FOR j IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
      LOOP
	  fnd_file.put_line(fnd_file.output,'<Column ss:AutoFitWidth="0" ss:Width="90"/>');
	  END LOOP;

fnd_file.put_line(fnd_file.output,'	  
   <Column ss:AutoFitWidth="0" ss:Width="120"/>
   <Column ss:AutoFitWidth="0" ss:Width="120"/>
   <Column ss:AutoFitWidth="0" ss:Width="120"/>
   <Column ss:AutoFitWidth="0" ss:Width="120"/>
   <Column ss:AutoFitWidth="0" ss:Width="120"/>
   <Column ss:AutoFitWidth="0" ss:Width="120"/>
   <Column ss:AutoFitWidth="0" ss:Width="120"/>
   <Column ss:AutoFitWidth="0" ss:Width="120"/>
   <Column ss:AutoFitWidth="0" ss:Width="120"/>
   <Column ss:AutoFitWidth="0" ss:Width="120"/>
   <Column ss:AutoFitWidth="0" ss:Width="120"/>
   <Column ss:AutoFitWidth="0" ss:Width="120"/>
   <Column ss:AutoFitWidth="0" ss:Width="120"/>');
   
     fnd_file.put_line(fnd_file.output,'<Row>
    <Cell ss:StyleID="s65"><Data ss:Type="String">Schedule of Revenue Income from Apr-'||SUBSTR(lv_period_year,3,2)||' to '||p_period||' </Data></Cell></Row>');
   
  

  fnd_file.put_line(fnd_file.output,'
   <Row ss:Index="3">
    <Cell ss:StyleID="s75"><Data ss:Type="String">Sno</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Old Assets No.</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Oracle code</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Assets No.</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Remarks</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Insta LR</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Inst FMS</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">RV Type </Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">LR - Total</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">FMS - Total</Data></Cell>');
	
	  FOR i IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
      LOOP
	  fnd_file.put_line(fnd_file.output,'<Cell ss:StyleID="s75"><Data ss:Type="String">LR-'||i.period_name||'</Data></Cell>');
	  END LOOP;
	  
	  FOR j IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
      LOOP
	  fnd_file.put_line(fnd_file.output,'<Cell ss:StyleID="s75"><Data ss:Type="String">FMS-'||j.period_name||'</Data></Cell>');
	  END LOOP;
	 
    fnd_file.put_line(fnd_file.output,'	 
    <Cell ss:StyleID="s75"><Data ss:Type="String">Monthly  LR</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Monthly FMS</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Vechile No</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Oracle Code</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Client Name</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Billing Arrear/Advance</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Location</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Rental Category</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Contract Start Date</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Contract End Date</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Variant Name</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Status of Asset</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Sold Month</Data></Cell>
   </Row>');   
   --------------------------

   lv_serial_number:=0;

FOR header IN (SELECT UNIQUE ledger_name,
                             location_description,
                             asset,
							 remarks,
	                         insta_lr ,
	                         insta_fms,
	                         rv_type ,
	                         vechile_no,
	                         billing_type,
							 asset oracle_code,
                        
	                         rental_category,
	                         contract_start_date,
	                         contract_end_date,
	                         variant_name,
	                         asset_status,
	                         sold_month	
                FROM  xxsmas_sheet1_dtls_tb 
				WHERE 1=1
				ORDER BY ASSET ASC)
LOOP				

lv_serial_number:=lv_serial_number+1;

   fnd_file.put_line(fnd_file.output,'	 
   <Row>
    <Cell><Data ss:Type="Number">'||lv_serial_number||'</Data></Cell>
    <Cell><Data ss:Type="String"></Data></Cell>
    <Cell><Data ss:Type="String">'||header.asset||'</Data></Cell>
    <Cell><Data ss:Type="String">'||header.asset||'</Data></Cell>
    <Cell><Data ss:Type="String">'||header.remarks||'</Data></Cell>
    <Cell><Data ss:Type="Number">'||header.insta_lr||'</Data></Cell>
    <Cell><Data ss:Type="Number">'||header.insta_fms||'</Data></Cell>
    <Cell><Data ss:Type="String">'||header.rv_type||'</Data></Cell>
    <Cell><Data ss:Type="Number">'||get_total_net_movement_lr(p_ledger_name=>header.ledger_name,p_asset_number=>header.asset)||'</Data></Cell>
    <Cell><Data ss:Type="Number">'||get_total_net_movement_fms(p_ledger_name=>header.ledger_name,p_asset_number=>header.asset)||'</Data></Cell>');

	  FOR i IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
      LOOP
	  fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||get_net_movement_lr(p_ledger_name=>p_ledger_name,p_asset_number=>header.asset,p_period_name=>i.period_name)||'</Data></Cell>');
	  END LOOP;
	  
	  FOR i IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
      LOOP
	  fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||get_net_movement_fms(p_ledger_name=>p_ledger_name,p_asset_number=>header.asset,p_period_name=>i.period_name)||'</Data></Cell>');
	  END LOOP;
	  
	fnd_file.put_line(fnd_file.output,'  
    <Cell><Data ss:Type="Number"></Data></Cell>
    <Cell><Data ss:Type="Number"></Data></Cell>
    <Cell><Data ss:Type="String">'||header.vechile_no||'</Data></Cell>
    <Cell><Data ss:Type="String">'||header.oracle_code||'</Data></Cell>
    <Cell><Data ss:Type="String">'||get_customer_name_func(p_ledger_name=>header.ledger_name,p_asset_number=>header.asset)||'</Data></Cell>
    <Cell><Data ss:Type="String">'||header.billing_type||'</Data></Cell>
    <Cell><Data ss:Type="String">'||header.location_description||'</Data></Cell>
    <Cell><Data ss:Type="String">'||header.rental_category||'</Data></Cell>
    <Cell><Data ss:Type="String">'||header.contract_start_date||'</Data></Cell>
    <Cell><Data ss:Type="String">'||header.contract_end_date||'</Data></Cell>
    <Cell><Data ss:Type="String">'||header.variant_name||'</Data></Cell>
    <Cell><Data ss:Type="String">'||header.asset_status||'</Data></Cell>
    <Cell><Data ss:Type="String">'||header.sold_month||'</Data></Cell>
    </Row>');
	END LOOP;
	
	BEGIN
 SELECT SUM(NVL(net_movement,0)) INTO lv_total_lr FROM xxsmas_sheet1_dtls_tb WHERE 1=1 AND type=1;
 SELECT SUM(NVL(net_movement,0)) INTO lv_total_fms FROM xxsmas_sheet1_dtls_tb WHERE 1=1 AND type=2;
END;  
 
   
   fnd_file.put_line(fnd_file.output,'	 
   <Row>
    <Cell><Data ss:Type="String"></Data></Cell>
    <Cell><Data ss:Type="String"></Data></Cell>
	<Cell><Data ss:Type="String"></Data></Cell>
    <Cell><Data ss:Type="String"></Data></Cell>
	<Cell ss:StyleID="s75"><Data ss:Type="String">Grand Total :</Data></Cell>
    <Cell><Data ss:Type="String"></Data></Cell>
	<Cell><Data ss:Type="String"></Data></Cell>
    <Cell><Data ss:Type="String"></Data></Cell>	
    <Cell><Data ss:Type="String">'||lv_total_lr||'</Data></Cell>
	<Cell><Data ss:Type="String">'||lv_total_fms||'</Data></Cell>');
	  
	FOR i IN (SELECT period_number,SUM(NVL(net_movement,0)) TOTAL
              FROM xxsmas_sheet1_dtls_tb 
              WHERE 1=1 
              AND type=1
              GROUP BY period_number
              ORDER BY period_number DESC)
      LOOP
	  fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||i.total||'</Data></Cell>');
	  END LOOP;
	  
	FOR i IN (SELECT period_number,SUM(NVL(net_movement,0)) TOTAL
              FROM xxsmas_sheet1_dtls_tb 
              WHERE 1=1 
              AND type=2
              GROUP BY period_number
              ORDER BY period_number DESC)
      LOOP
	  fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||i.total||'</Data></Cell>');
	  END LOOP;
	  
	fnd_file.put_line(fnd_file.output,'  
    <Cell><Data ss:Type="Number"></Data></Cell>
    <Cell><Data ss:Type="Number"></Data></Cell>
    <Cell><Data ss:Type="String"></Data></Cell>
    <Cell><Data ss:Type="String"></Data></Cell>
    <Cell><Data ss:Type="String"></Data></Cell>
    <Cell><Data ss:Type="String"></Data></Cell>
    <Cell><Data ss:Type="String"></Data></Cell>
    <Cell><Data ss:Type="String"></Data></Cell>
    <Cell><Data ss:Type="String"></Data></Cell>
    <Cell><Data ss:Type="String"></Data></Cell>
    <Cell><Data ss:Type="String"></Data></Cell>
    <Cell><Data ss:Type="String"></Data></Cell>
    <Cell><Data ss:Type="String"></Data></Cell>
    </Row>');
	
	fnd_file.put_line(fnd_file.output,'
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <PageSetup>
    <Header x:Margin="0.3"/>
    <Footer x:Margin="0.3"/>
    <PageMargins x:Bottom="0.75" x:Left="0.7" x:Right="0.7" x:Top="0.75"/>
   </PageSetup>
   <Selected/>
   <Panes>
    <Pane>
     <Number>3</Number>
     <ActiveRow>12</ActiveRow>
     <ActiveCol>5</ActiveCol>
    </Pane>
   </Panes>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>');
 
 ---------2. OL FMS Income Others------------
 fnd_file.put_line(fnd_file.output,'
  <Worksheet ss:Name="2. OL FMS Income Others">
  <Table ss:ExpandedColumnCount="100" ss:ExpandedRowCount="100000" x:FullColumns="1"
   x:FullRows="1" ss:DefaultRowHeight="15">
   <Column ss:AutoFitWidth="0" ss:Width="120"/>
   <Column ss:AutoFitWidth="0" ss:Width="80"/>
   <Column ss:AutoFitWidth="0" ss:Width="80"/>
   <Column ss:AutoFitWidth="0" ss:Width="80"/>');
   
   FOR j IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
LOOP
fnd_file.put_line(fnd_file.output,'<Column ss:AutoFitWidth="0" ss:Width="90"/>');
END LOOP;
   
   fnd_file.put_line(fnd_file.output,'<Column ss:AutoFitWidth="0" ss:Width="120"/>');
   
   --- Heading 1:
   fnd_file.put_line(fnd_file.output,
   '<Row>
    <Cell ss:StyleID="s65"><Data ss:Type="String">SMAS Auto Leasing India Private Limited</Data></Cell>
   </Row>');
   --- Heading 2:
   fnd_file.put_line(fnd_file.output,
   '<Row>
    <Cell ss:StyleID="s65"><Data ss:Type="String">FMS Income Others for the Period ended '||p_period||'-'||lv_period_year||'</Data></Cell>
   </Row>');
   
   --- Column heading:
   fnd_file.put_line(fnd_file.output,'
   <Row ss:Index="4">
    <Cell ss:StyleID="s75"><Data ss:Type="String">Remarks</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Assets No.</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Oracle code</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Total</Data></Cell>');
	
	--- Dynamic period name as columns:
	FOR i IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
    LOOP
	fnd_file.put_line(fnd_file.output,'<Cell ss:StyleID="s75"><Data ss:Type="String">'||i.period_name||'</Data></Cell>');
	END LOOP;
	
	fnd_file.put_line(fnd_file.output,'
	<Cell ss:StyleID="s75"><Data ss:Type="String">Client Name</Data></Cell>
   </Row>');
   
   FOR i IN (SELECT UNIQUE asset FROM xxsmas_sheet3_dtls_tb ORDER BY asset ASC)
   LOOP
   --- Column Values:
   fnd_file.put_line(fnd_file.output,'
   <Row>
    <Cell><Data ss:Type="String">Deficit Foreclosure FMS</Data></Cell>
	<Cell><Data ss:Type="String">'||i.asset||'</Data></Cell>
	<Cell><Data ss:Type="String">'||i.asset||'</Data></Cell>');

	lv_total:=0;
	
	BEGIN
	SELECT SUM(NVL(net_movement,0)) INTO lv_total 
	FROM xxsmas_sheet3_dtls_tb 
	WHERE 1=1 
	AND asset=i.asset;
	END;
	
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');


	FOR j IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
    LOOP
	
    lv_total:=0;
	
	BEGIN
	SELECT SUM(NVL(net_movement,0)) INTO lv_total 
	FROM xxsmas_sheet3_dtls_tb 
	WHERE 1=1 
	AND asset=i.asset
	AND period_name=j.period_name;
	EXCEPTION WHEN OTHERS THEN
	lv_total:=0;
	END;		
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');
	END LOOP;

    lv_client_name:=NULL;
	
	BEGIN
	SELECT UNIQUE customer_name 
	INTO lv_client_name
	FROM xxsmas_sheet3_dtls_tb 
	WHERE 1=1 
	AND asset=i.asset
	AND customer_name IS NOT NULL
	AND ROWNUM=1;
	EXCEPTION WHEN OTHERS THEN
	lv_client_name:=NULL;
	END;
	
	IF lv_client_name IS NOT NULL THEN
    fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="String">'||lv_client_name||'</Data></Cell>');
	ELSE
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="String"></Data></Cell>');
	END IF;
	
	fnd_file.put_line(fnd_file.output,'</Row>');
	END LOOP;
	
	--- Grand Total:
	
	 fnd_file.put_line(fnd_file.output,'<Row>
    <Cell><Data ss:Type="String"></Data></Cell>
	<Cell><Data ss:Type="String"></Data></Cell>
	<Cell ss:StyleID="s75"><Data ss:Type="String">Grand Total :</Data></Cell>');
	
	lv_total:=0;
	
	BEGIN
	SELECT SUM(NVL(net_movement,0)) INTO lv_total 
	FROM xxsmas_sheet3_dtls_tb 
	WHERE 1=1 ;
	EXCEPTION WHEN OTHERS THEN
	lv_total:=0;
	END;		
	
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');
	
	
	FOR j IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
    LOOP
	
    lv_total:=0;
	
	BEGIN
	SELECT SUM(NVL(net_movement,0)) INTO lv_total 
	FROM xxsmas_sheet3_dtls_tb 
	WHERE 1=1 
	AND period_name=j.period_name;
	EXCEPTION WHEN OTHERS THEN
	lv_total:=0;
	END;		
	
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');
	END LOOP;
	
   
   fnd_file.put_line(fnd_file.output,'</Row>');
   
   fnd_file.put_line(fnd_file.output,'
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <PageSetup>
    <Header x:Margin="0.3"/>
    <Footer x:Margin="0.3"/>
    <PageMargins x:Bottom="0.75" x:Left="0.7" x:Right="0.7" x:Top="0.75"/>
   </PageSetup>
   <Selected/>
   <Panes>
    <Pane>
     <Number>3</Number>
     <ActiveRow>8</ActiveRow>
     <ActiveCol>5</ActiveCol>
    </Pane>
   </Panes>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>');
 
 ---------3. OL Excess Mileages charges------------
 fnd_file.put_line(fnd_file.output,'
  <Worksheet ss:Name="3. OL Excess Mileages charges">
  <Table ss:ExpandedColumnCount="100" ss:ExpandedRowCount="100000" x:FullColumns="1"
   x:FullRows="1" ss:DefaultRowHeight="15">
   <Column ss:AutoFitWidth="0" ss:Width="80"/>
   <Column ss:AutoFitWidth="0" ss:Width="80"/>
   <Column ss:AutoFitWidth="0" ss:Width="80"/>');

FOR j IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
LOOP
fnd_file.put_line(fnd_file.output,'<Column ss:AutoFitWidth="0" ss:Width="90"/>');
END LOOP;

   fnd_file.put_line(fnd_file.output,'
   <Column ss:AutoFitWidth="0" ss:Width="120"/>
   <Column ss:AutoFitWidth="0" ss:Width="120"/>');
   
   --- Heading 1:
   fnd_file.put_line(fnd_file.output,
   '<Row>
    <Cell ss:StyleID="s65"><Data ss:Type="String">SMAS Auto Leasing India Private Limited</Data></Cell>
   </Row>');
   --- Heading 2:
   fnd_file.put_line(fnd_file.output,
   '<Row>
    <Cell ss:StyleID="s65"><Data ss:Type="String">Excess Kms charges for  the Period ended '||p_period||'-'||lv_period_year||'</Data></Cell>
   </Row>');
   
   --- Column heading:
   fnd_file.put_line(fnd_file.output,'
   <Row ss:Index="4">
    <Cell ss:StyleID="s75"><Data ss:Type="String">Assets No.</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Oracle code</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Total</Data></Cell>');
	
	--- Dynamic period name as columns:
	FOR i IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
    LOOP
	fnd_file.put_line(fnd_file.output,'<Cell ss:StyleID="s75"><Data ss:Type="String">'||i.period_name||'</Data></Cell>');
	END LOOP;
	
	fnd_file.put_line(fnd_file.output,'
	<Cell ss:StyleID="s75"><Data ss:Type="String">Client Name</Data></Cell>
	<Cell ss:StyleID="s75"><Data ss:Type="String">Remarks</Data></Cell>
   </Row>');
   
   FOR i IN (SELECT UNIQUE asset FROM xxsmas_sheet3_dtls_tb ORDER BY asset ASC)
   LOOP
   --- Column Values:
   fnd_file.put_line(fnd_file.output,'
   <Row>
	<Cell><Data ss:Type="String">'||i.asset||'</Data></Cell>
	<Cell><Data ss:Type="String">'||i.asset||'</Data></Cell>');

	lv_total:=0;
	
	BEGIN
	SELECT SUM(NVL(net_movement,0)) INTO lv_total 
	FROM xxsmas_sheet3_dtls_tb 
	WHERE 1=1 
	AND asset=i.asset;
	END;
	
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');


	FOR j IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
    LOOP
	
    lv_total:=0;
	
	BEGIN
	SELECT SUM(NVL(net_movement,0)) INTO lv_total 
	FROM xxsmas_sheet3_dtls_tb 
	WHERE 1=1 
	AND asset=i.asset
	AND period_name=j.period_name;
	EXCEPTION WHEN OTHERS THEN
	lv_total:=0;
	END;		
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');
	END LOOP;

    lv_client_name:=NULL;
	
	BEGIN
	SELECT UNIQUE customer_name 
	INTO lv_client_name
	FROM xxsmas_sheet3_dtls_tb 
	WHERE 1=1 
	AND asset=i.asset
	AND customer_name IS NOT NULL
	AND ROWNUM=1;
	EXCEPTION WHEN OTHERS THEN
	lv_client_name:=NULL;
	END;
	
	IF lv_client_name IS NOT NULL THEN
    fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="String">'||lv_client_name||'</Data></Cell>');
	ELSE
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="String"></Data></Cell>');
	END IF;
	
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="String"></Data></Cell>');
	
	fnd_file.put_line(fnd_file.output,'</Row>');
	END LOOP;
	
	--- Grand Total:	
	 fnd_file.put_line(fnd_file.output,'<Row>
    <Cell><Data ss:Type="String"></Data></Cell>
	<Cell ss:StyleID="s75"><Data ss:Type="String">Grand Total :</Data></Cell>');
	
	lv_total:=0;
	
	BEGIN
	SELECT SUM(NVL(net_movement,0)) INTO lv_total 
	FROM xxsmas_sheet3_dtls_tb 
	WHERE 1=1 ;
	EXCEPTION WHEN OTHERS THEN
	lv_total:=0;
	END;		
	
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');
	
	
	FOR j IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
    LOOP
	
    lv_total:=0;
	
	BEGIN
	SELECT SUM(NVL(net_movement,0)) INTO lv_total 
	FROM xxsmas_sheet3_dtls_tb 
	WHERE 1=1 
	AND period_name=j.period_name;
	EXCEPTION WHEN OTHERS THEN
	lv_total:=0;
	END;		
	
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');
	END LOOP;
	
   
   fnd_file.put_line(fnd_file.output,'</Row>');
   
   fnd_file.put_line(fnd_file.output,'
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <PageSetup>
    <Header x:Margin="0.3"/>
    <Footer x:Margin="0.3"/>
    <PageMargins x:Bottom="0.75" x:Left="0.7" x:Right="0.7" x:Top="0.75"/>
   </PageSetup>
   <Selected/>
   <Panes>
    <Pane>
     <Number>3</Number>
     <ActiveRow>8</ActiveRow>
     <ActiveCol>5</ActiveCol>
    </Pane>
   </Panes>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>');
 
 
  ---------4.OL FC chgs------------
 fnd_file.put_line(fnd_file.output,'
  <Worksheet ss:Name="4.OL FC chgs">
  <Table ss:ExpandedColumnCount="100" ss:ExpandedRowCount="100000" x:FullColumns="1"
   x:FullRows="1" ss:DefaultRowHeight="15">
   <Column ss:AutoFitWidth="0" ss:Width="80"/>
   <Column ss:AutoFitWidth="0" ss:Width="80"/>
   <Column ss:AutoFitWidth="0" ss:Width="80"/>');
   
FOR j IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
LOOP
fnd_file.put_line(fnd_file.output,'<Column ss:AutoFitWidth="0" ss:Width="90"/>');
END LOOP;

   fnd_file.put_line(fnd_file.output,'
   <Column ss:AutoFitWidth="0" ss:Width="120"/>
   <Column ss:AutoFitWidth="0" ss:Width="120"/>');
   
   --- Heading 1:
   fnd_file.put_line(fnd_file.output,
   '<Row>
    <Cell ss:StyleID="s65"><Data ss:Type="String">SMAS Auto Leasing India Private Limited</Data></Cell>
   </Row>');
   --- Heading 2:
   fnd_file.put_line(fnd_file.output,
   '<Row>
    <Cell ss:StyleID="s65"><Data ss:Type="String">Foreclosure charges for  the Period ended '||p_period||'-'||lv_period_year||'</Data></Cell>
   </Row>');
   
   --- Column heading:
   fnd_file.put_line(fnd_file.output,'
   <Row ss:Index="4">
    <Cell ss:StyleID="s75"><Data ss:Type="String">Assets No.</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Oracle code</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Total</Data></Cell>');
	
	--- Dynamic period name as columns:
	FOR i IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
    LOOP
	fnd_file.put_line(fnd_file.output,'<Cell ss:StyleID="s75"><Data ss:Type="String">'||i.period_name||'</Data></Cell>');
	END LOOP;
	
	fnd_file.put_line(fnd_file.output,'
	<Cell ss:StyleID="s75"><Data ss:Type="String">Client Name</Data></Cell>
	<Cell ss:StyleID="s75"><Data ss:Type="String">Remarks</Data></Cell>
   </Row>');
   
   FOR i IN (SELECT UNIQUE asset FROM xxsmas_sheet4_dtls_tb ORDER BY asset ASC)
   LOOP
   --- Column Values:
   fnd_file.put_line(fnd_file.output,'
   <Row>
	<Cell><Data ss:Type="String">'||i.asset||'</Data></Cell>
	<Cell><Data ss:Type="String">'||i.asset||'</Data></Cell>');

	lv_total:=0;
	
	BEGIN
	SELECT SUM(NVL(net_movement,0)) INTO lv_total 
	FROM xxsmas_sheet4_dtls_tb 
	WHERE 1=1 
	AND asset=i.asset;
	END;
	
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');


	FOR j IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
    LOOP
	
    lv_total:=0;
	
	BEGIN
	SELECT SUM(NVL(net_movement,0)) INTO lv_total 
	FROM xxsmas_sheet4_dtls_tb 
	WHERE 1=1 
	AND asset=i.asset
	AND period_name=j.period_name;
	EXCEPTION WHEN OTHERS THEN
	lv_total:=0;
	END;		
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');
	END LOOP;

    lv_client_name:=NULL;
	
	BEGIN
	SELECT UNIQUE customer_name 
	INTO lv_client_name
	FROM xxsmas_sheet4_dtls_tb 
	WHERE 1=1 
	AND asset=i.asset
	AND customer_name IS NOT NULL
	AND ROWNUM=1;
	EXCEPTION WHEN OTHERS THEN
	lv_client_name:=NULL;
	END;
	
	IF lv_client_name IS NOT NULL THEN
    fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="String">'||lv_client_name||'</Data></Cell>');
	ELSE
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="String"></Data></Cell>');
	END IF;
	
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="String"></Data></Cell>');
	
	fnd_file.put_line(fnd_file.output,'</Row>');
	END LOOP;
	
	--- Grand Total:
	
	 fnd_file.put_line(fnd_file.output,'<Row>
    <Cell><Data ss:Type="String"></Data></Cell>
	<Cell ss:StyleID="s75"><Data ss:Type="String">Grand Total :</Data></Cell>');
	
	lv_total:=0;
	
	BEGIN
	SELECT SUM(NVL(net_movement,0)) INTO lv_total 
	FROM xxsmas_sheet4_dtls_tb 
	WHERE 1=1 ;
	EXCEPTION WHEN OTHERS THEN
	lv_total:=0;
	END;		
	
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');
	
	
	FOR j IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
    LOOP
	
    lv_total:=0;
	
	BEGIN
	SELECT SUM(NVL(net_movement,0)) INTO lv_total 
	FROM xxsmas_sheet4_dtls_tb 
	WHERE 1=1 
	AND period_name=j.period_name;
	EXCEPTION WHEN OTHERS THEN
	lv_total:=0;
	END;		
	
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');
	END LOOP;
	
   
   fnd_file.put_line(fnd_file.output,'</Row>');
   
   fnd_file.put_line(fnd_file.output,'
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <PageSetup>
    <Header x:Margin="0.3"/>
    <Footer x:Margin="0.3"/>
    <PageMargins x:Bottom="0.75" x:Left="0.7" x:Right="0.7" x:Top="0.75"/>
   </PageSetup>
   <Selected/>
   <Panes>
    <Pane>
     <Number>3</Number>
     <ActiveRow>8</ActiveRow>
     <ActiveCol>5</ActiveCol>
    </Pane>
   </Panes>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>');
 
 
   ---------5.Income other------------
 fnd_file.put_line(fnd_file.output,'
  <Worksheet ss:Name="5.Income other">
  <Table ss:ExpandedColumnCount="100" ss:ExpandedRowCount="100000" x:FullColumns="1"
   x:FullRows="1" ss:DefaultRowHeight="15">
<Column ss:AutoFitWidth="0" ss:Width="80"/>
<Column ss:AutoFitWidth="0" ss:Width="80"/>
<Column ss:AutoFitWidth="0" ss:Width="120"/>
<Column ss:AutoFitWidth="0" ss:Width="80"/>');

FOR j IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
LOOP
fnd_file.put_line(fnd_file.output,'<Column ss:AutoFitWidth="0" ss:Width="90"/>');
END LOOP;

fnd_file.put_line(fnd_file.output,'<Column ss:AutoFitWidth="0" ss:Width="120"/>');

   --- Heading 1:
   fnd_file.put_line(fnd_file.output,
   '<Row>
    <Cell ss:StyleID="s65"><Data ss:Type="String">SMAS Auto Leasing India Private Limited</Data></Cell>
   </Row>');
   --- Heading 2:
   fnd_file.put_line(fnd_file.output,
   '<Row>
    <Cell ss:StyleID="s65"><Data ss:Type="String">Income Others for  the Period ended '||p_period||'-'||lv_period_year||'</Data></Cell>
   </Row>');
   
   --- Column heading:
   fnd_file.put_line(fnd_file.output,'
   <Row ss:Index="4">
    <Cell ss:StyleID="s75"><Data ss:Type="String">Assets No.</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Oracle code</Data></Cell>
	<Cell ss:StyleID="s75"><Data ss:Type="String">Remarks</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Total</Data></Cell>');
	
	--- Dynamic period name as columns:
	FOR i IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
    LOOP
	fnd_file.put_line(fnd_file.output,'<Cell ss:StyleID="s75"><Data ss:Type="String">'||i.period_name||'</Data></Cell>');
	END LOOP;
	
	fnd_file.put_line(fnd_file.output,'
	<Cell ss:StyleID="s75"><Data ss:Type="String">Client Name</Data></Cell></Row>');
   
   FOR i IN (SELECT UNIQUE asset FROM xxsmas_sheet5_dtls_tb ORDER BY asset ASC)
   LOOP
   --- Column Values:
   fnd_file.put_line(fnd_file.output,'
   <Row>
	<Cell><Data ss:Type="String">'||i.asset||'</Data></Cell>
	<Cell><Data ss:Type="String">'||i.asset||'</Data></Cell>');
   fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="String"></Data></Cell>');

	lv_total:=0;
	
	BEGIN
	SELECT SUM(NVL(net_movement,0)) INTO lv_total 
	FROM xxsmas_sheet5_dtls_tb 
	WHERE 1=1 
	AND asset=i.asset;
	END;
	
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');


	FOR j IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
    LOOP
	
    lv_total:=0;
	
	BEGIN
	SELECT SUM(NVL(net_movement,0)) INTO lv_total 
	FROM xxsmas_sheet5_dtls_tb 
	WHERE 1=1 
	AND asset=i.asset
	AND period_name=j.period_name;
	EXCEPTION WHEN OTHERS THEN
	lv_total:=0;
	END;		
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');
	END LOOP;

    lv_client_name:=NULL;
	
	BEGIN
	SELECT UNIQUE customer_name 
	INTO lv_client_name
	FROM xxsmas_sheet5_dtls_tb 
	WHERE 1=1 
	AND asset=i.asset
	AND customer_name IS NOT NULL
	AND ROWNUM=1;
	EXCEPTION WHEN OTHERS THEN
	lv_client_name:=NULL;
	END;
	
	IF lv_client_name IS NOT NULL THEN
    fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="String">'||lv_client_name||'</Data></Cell>');
	ELSE
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="String"></Data></Cell>');
	END IF;
	
	
	
	fnd_file.put_line(fnd_file.output,'</Row>');
	END LOOP;
	
	--- Grand Total:
	
	 fnd_file.put_line(fnd_file.output,'<Row>
    <Cell><Data ss:Type="String"></Data></Cell>
	<Cell><Data ss:Type="String"></Data></Cell>
	<Cell ss:StyleID="s75"><Data ss:Type="String">Grand Total :</Data></Cell>');
	
	lv_total:=0;
	
	BEGIN
	SELECT SUM(NVL(net_movement,0)) INTO lv_total 
	FROM xxsmas_sheet5_dtls_tb 
	WHERE 1=1 ;
	EXCEPTION WHEN OTHERS THEN
	lv_total:=0;
	END;		
	
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');
	
	
	FOR j IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
    LOOP
	
    lv_total:=0;
	
	BEGIN
	SELECT SUM(NVL(net_movement,0)) INTO lv_total 
	FROM xxsmas_sheet5_dtls_tb 
	WHERE 1=1 
	AND period_name=j.period_name;
	EXCEPTION WHEN OTHERS THEN
	lv_total:=0;
	END;		
	
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');
	END LOOP;
	
   fnd_file.put_line(fnd_file.output,'</Row>');
   
   fnd_file.put_line(fnd_file.output,'
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <PageSetup>
    <Header x:Margin="0.3"/>
    <Footer x:Margin="0.3"/>
    <PageMargins x:Bottom="0.75" x:Left="0.7" x:Right="0.7" x:Top="0.75"/>
   </PageSetup>
   <Selected/>
   <Panes>
    <Pane>
     <Number>3</Number>
     <ActiveRow>8</ActiveRow>
     <ActiveCol>5</ActiveCol>
    </Pane>
   </Panes>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>');
 
   ---------6.FMS MO------------
 fnd_file.put_line(fnd_file.output,'
  <Worksheet ss:Name="6.FMS MO">
  <Table ss:ExpandedColumnCount="100" ss:ExpandedRowCount="100000" x:FullColumns="1"
   x:FullRows="1" ss:DefaultRowHeight="15">
   <Column ss:AutoFitWidth="0" ss:Width="80"/>
   <Column ss:AutoFitWidth="0" ss:Width="80"/>
   <Column ss:AutoFitWidth="0" ss:Width="80"/>');
   
FOR j IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
LOOP
fnd_file.put_line(fnd_file.output,'<Column ss:AutoFitWidth="0" ss:Width="90"/>');
END LOOP;

   fnd_file.put_line(fnd_file.output,'<Column ss:AutoFitWidth="0" ss:Width="120"/>');
   
   --- Heading 1:
   fnd_file.put_line(fnd_file.output,
   '<Row>
    <Cell ss:StyleID="s65"><Data ss:Type="String">Foreclosure Charges for  the Period ended '||p_period||'</Data></Cell>
   </Row>');
   
   --- Heading 2:
   fnd_file.put_line(fnd_file.output,
   '<Row>
    <Cell ss:StyleID="s65"><Data ss:Type="String">FMS -Mo Only</Data></Cell>
   </Row>');
   
   --- Column heading:
   fnd_file.put_line(fnd_file.output,'
   <Row ss:Index="4">
    <Cell ss:StyleID="s75"><Data ss:Type="String">Assets No.</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Oracle code</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Total</Data></Cell>');
	
	--- Dynamic period name as columns:
	FOR i IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
    LOOP
	fnd_file.put_line(fnd_file.output,'<Cell ss:StyleID="s75"><Data ss:Type="String">'||i.period_name||'</Data></Cell>');
	END LOOP;
	
	fnd_file.put_line(fnd_file.output,'
	<Cell ss:StyleID="s75"><Data ss:Type="String">Client Name</Data></Cell>
	
   </Row>');
   
   FOR i IN (SELECT UNIQUE asset FROM xxsmas_sheet6_dtls_tb ORDER BY asset ASC)
   LOOP
   --- Column Values:
   fnd_file.put_line(fnd_file.output,'
   <Row>
	<Cell><Data ss:Type="String">'||i.asset||'</Data></Cell>
	<Cell><Data ss:Type="String">'||i.asset||'</Data></Cell>');

	lv_total:=0;
	
	BEGIN
	SELECT SUM(NVL(net_movement,0)) INTO lv_total 
	FROM xxsmas_sheet6_dtls_tb 
	WHERE 1=1 
	AND asset=i.asset;
	EXCEPTION WHEN OTHERS THEN
	lv_total :=0;
	END;
	
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');


	FOR j IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
    LOOP
	
    lv_total:=0;
	
	BEGIN
	SELECT SUM(NVL(net_movement,0)) INTO lv_total 
	FROM xxsmas_sheet6_dtls_tb 
	WHERE 1=1 
	AND asset=i.asset
	AND period_name=j.period_name;
	EXCEPTION WHEN OTHERS THEN
	lv_total:=0;
	END;		
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');
	END LOOP;

    lv_client_name:=NULL;
	
	BEGIN
	SELECT UNIQUE customer_name 
	INTO lv_client_name
	FROM xxsmas_sheet6_dtls_tb 
	WHERE 1=1 
	AND asset=i.asset
	AND customer_name IS NOT NULL
	AND ROWNUM=1;
	EXCEPTION WHEN OTHERS THEN
	lv_client_name:=NULL;
	END;
	
	IF lv_client_name IS NOT NULL THEN
    fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="String">'||lv_client_name||'</Data></Cell>');
	ELSE
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="String"></Data></Cell>');
	END IF;
	
	fnd_file.put_line(fnd_file.output,'</Row>');
	END LOOP;
	
	--- Grand Total:
	
	 fnd_file.put_line(fnd_file.output,'<Row>
    <Cell><Data ss:Type="String"></Data></Cell>
	<Cell ss:StyleID="s75"><Data ss:Type="String">Grand Total :</Data></Cell>');
	
	lv_total:=0;
	
	BEGIN
	SELECT SUM(NVL(net_movement,0)) INTO lv_total 
	FROM xxsmas_sheet6_dtls_tb 
	WHERE 1=1 ;
	EXCEPTION WHEN OTHERS THEN
	lv_total:=0;
	END;		
	
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');
	
	
	FOR j IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
    LOOP
	
    lv_total:=0;
	
	BEGIN
	SELECT SUM(NVL(net_movement,0)) INTO lv_total 
	FROM xxsmas_sheet6_dtls_tb 
	WHERE 1=1 
	AND period_name=j.period_name;
	EXCEPTION WHEN OTHERS THEN
	lv_total:=0;
	END;		
	
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');
	END LOOP;
	
   
   fnd_file.put_line(fnd_file.output,'</Row>');
   
   fnd_file.put_line(fnd_file.output,'
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <PageSetup>
    <Header x:Margin="0.3"/>
    <Footer x:Margin="0.3"/>
    <PageMargins x:Bottom="0.75" x:Left="0.7" x:Right="0.7" x:Top="0.75"/>
   </PageSetup>
   <Selected/>
   <Panes>
    <Pane>
     <Number>3</Number>
     <ActiveRow>8</ActiveRow>
     <ActiveCol>5</ActiveCol>
    </Pane>
   </Panes>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>');
   
   

   ---------7.Bad debts written back------------
 fnd_file.put_line(fnd_file.output,'
  <Worksheet ss:Name="7.Bad debts written back">
  <Table ss:ExpandedColumnCount="100" ss:ExpandedRowCount="100000" x:FullColumns="1"
   x:FullRows="1" ss:DefaultRowHeight="15">
<Column ss:AutoFitWidth="0" ss:Width="80"/>
<Column ss:AutoFitWidth="0" ss:Width="80"/>
<Column ss:AutoFitWidth="0" ss:Width="80"/>');

FOR j IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
LOOP
fnd_file.put_line(fnd_file.output,'<Column ss:AutoFitWidth="0" ss:Width="90"/>');
END LOOP;

 fnd_file.put_line(fnd_file.output,'<Column ss:AutoFitWidth="0" ss:Width="120"/>
                                    <Column ss:AutoFitWidth="0" ss:Width="120"/>');
									
   --- Heading 1:
   fnd_file.put_line(fnd_file.output,
   '<Row>
    <Cell ss:StyleID="s65"><Data ss:Type="String">SMAS Auto Leasing India Private Limited</Data></Cell>
   </Row>');
   --- Heading 2:
   fnd_file.put_line(fnd_file.output,
   '<Row>
    <Cell ss:StyleID="s65"><Data ss:Type="String">Bad debts written off for period ended '||p_period||'</Data></Cell>
   </Row>');
   
   --- Column heading:
   fnd_file.put_line(fnd_file.output,'
   <Row ss:Index="4">
    <Cell ss:StyleID="s75"><Data ss:Type="String">Assets No.</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Oracle code</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Total</Data></Cell>');
	
	--- Dynamic period name as columns:
	FOR i IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
    LOOP
	fnd_file.put_line(fnd_file.output,'<Cell ss:StyleID="s75"><Data ss:Type="String">'||i.period_name||'</Data></Cell>');
	END LOOP;
	
	fnd_file.put_line(fnd_file.output,'<Cell ss:StyleID="s75"><Data ss:Type="String">Client Name</Data></Cell>');	
	fnd_file.put_line(fnd_file.output,'<Cell ss:StyleID="s75"><Data ss:Type="String">Remarks</Data></Cell>');
	fnd_file.put_line(fnd_file.output,'</Row>');

   FOR i IN (SELECT UNIQUE asset FROM xxsmas_sheet7_dtls_tb ORDER BY asset ASC)
   LOOP
   --- Column Values:
   fnd_file.put_line(fnd_file.output,'
    <Row>
	<Cell><Data ss:Type="String">'||i.asset||'</Data></Cell>
	<Cell><Data ss:Type="String">'||i.asset||'</Data></Cell>');

	lv_total:=0;
	
	BEGIN
	SELECT SUM(NVL(net_movement,0)) INTO lv_total 
	FROM xxsmas_sheet7_dtls_tb 
	WHERE 1=1 
	AND asset=i.asset;
	EXCEPTION WHEN OTHERS THEN
	lv_total :=0;
	END;
	
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');


	FOR j IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
    LOOP
	
    lv_total:=0;
	
	BEGIN
	SELECT SUM(NVL(net_movement,0)) INTO lv_total 
	FROM xxsmas_sheet7_dtls_tb 
	WHERE 1=1 
	AND asset=i.asset
	AND period_name=j.period_name;
	EXCEPTION WHEN OTHERS THEN
	lv_total:=0;
	END;		
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');
	END LOOP;

    lv_client_name:=NULL;
	
	BEGIN
	SELECT UNIQUE customer_name 
	INTO lv_client_name
	FROM xxsmas_sheet7_dtls_tb 
	WHERE 1=1 
	AND asset=i.asset
	AND customer_name IS NOT NULL
	AND ROWNUM=1;
	EXCEPTION WHEN OTHERS THEN
	lv_client_name:=NULL;
	END;
	
	IF lv_client_name IS NOT NULL THEN
    fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="String">'||lv_client_name||'</Data></Cell>');
	ELSE
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="String"></Data></Cell>');
	END IF;
	
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="String"></Data></Cell>');
	
	fnd_file.put_line(fnd_file.output,'</Row>');
	END LOOP;
	
	--- Grand Total:
	
	 fnd_file.put_line(fnd_file.output,'<Row>
    <Cell><Data ss:Type="String"></Data></Cell>
	<Cell ss:StyleID="s75"><Data ss:Type="String">Grand Total :</Data></Cell>');
	
	lv_total:=0;
	
	BEGIN
	SELECT SUM(NVL(net_movement,0)) INTO lv_total 
	FROM xxsmas_sheet7_dtls_tb 
	WHERE 1=1 ;
	EXCEPTION WHEN OTHERS THEN
	lv_total:=0;
	END;		
	
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');
	
	
	FOR j IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
    LOOP
	
    lv_total:=0;
	
	BEGIN
	SELECT SUM(NVL(net_movement,0)) INTO lv_total 
	FROM xxsmas_sheet7_dtls_tb 
	WHERE 1=1 
	AND period_name=j.period_name;
	EXCEPTION WHEN OTHERS THEN
	lv_total:=0;
	END;		
	
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');
	END LOOP;
	
   fnd_file.put_line(fnd_file.output,'</Row>');

   fnd_file.put_line(fnd_file.output,'
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <PageSetup>
    <Header x:Margin="0.3"/>
    <Footer x:Margin="0.3"/>
    <PageMargins x:Bottom="0.75" x:Left="0.7" x:Right="0.7" x:Top="0.75"/>
   </PageSetup>
   <Selected/>
   <Panes>
    <Pane>
     <Number>3</Number>
     <ActiveRow>8</ActiveRow>
     <ActiveCol>5</ActiveCol>
    </Pane>
   </Panes>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>');
 
 
   ---------09.FL Foreclosure Chgs------------
 fnd_file.put_line(fnd_file.output,'
  <Worksheet ss:Name="09.FL Foreclosure Chgs">
  <Table ss:ExpandedColumnCount="100" ss:ExpandedRowCount="100000" x:FullColumns="1"
   x:FullRows="1" ss:DefaultRowHeight="15">
<Column ss:AutoFitWidth="0" ss:Width="80"/>
<Column ss:AutoFitWidth="0" ss:Width="80"/>
<Column ss:AutoFitWidth="0" ss:Width="80"/>');

FOR j IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
LOOP
fnd_file.put_line(fnd_file.output,'<Column ss:AutoFitWidth="0" ss:Width="90"/>');
END LOOP;


 fnd_file.put_line(fnd_file.output,'<Column ss:AutoFitWidth="0" ss:Width="120"/>');
 
 
   --- Heading 1:
   fnd_file.put_line(fnd_file.output,
   '<Row>
    <Cell ss:StyleID="s65"><Data ss:Type="String">SMAS Auto Leasing India Private Limited</Data></Cell>
   </Row>');
   --- Heading 2:
   fnd_file.put_line(fnd_file.output,
   '<Row>
    <Cell ss:StyleID="s65"><Data ss:Type="String">FL-Foreclosure charges for  the Period ended '||p_period||'</Data></Cell>
   </Row>');
   
   --- Column heading:
   fnd_file.put_line(fnd_file.output,'
   <Row ss:Index="4">
    <Cell ss:StyleID="s75"><Data ss:Type="String">Assets No.</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Oracle code</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Total</Data></Cell>');
	
	--- Dynamic period name as columns:
	FOR i IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
    LOOP
	fnd_file.put_line(fnd_file.output,'<Cell ss:StyleID="s75"><Data ss:Type="String">'||i.period_name||'</Data></Cell>');
	END LOOP;
	
	fnd_file.put_line(fnd_file.output,'<Cell ss:StyleID="s75"><Data ss:Type="String">Client Name</Data></Cell>	
   </Row>');
   
   FOR i IN (SELECT UNIQUE asset FROM xxsmas_sheet9_dtls_tb ORDER BY asset ASC)
   LOOP
   --- Column Values:
   fnd_file.put_line(fnd_file.output,'
    <Row>
	<Cell><Data ss:Type="String">'||i.asset||'</Data></Cell>
	<Cell><Data ss:Type="String">'||i.asset||'</Data></Cell>');

	lv_total:=0;
	
	BEGIN
	SELECT SUM(NVL(net_movement,0)) INTO lv_total 
	FROM xxsmas_sheet9_dtls_tb 
	WHERE 1=1 
	AND asset=i.asset;
	END;
	
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');


	FOR j IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
    LOOP
	
    lv_total:=0;
	
	BEGIN
	SELECT SUM(NVL(net_movement,0)) INTO lv_total 
	FROM xxsmas_sheet9_dtls_tb 
	WHERE 1=1 
	AND asset=i.asset
	AND period_name=j.period_name;
	EXCEPTION WHEN OTHERS THEN
	lv_total:=0;
	END;		
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');
	END LOOP;

    lv_client_name:=NULL;
	
	BEGIN
	SELECT UNIQUE customer_name 
	INTO lv_client_name
	FROM xxsmas_sheet9_dtls_tb 
	WHERE 1=1 
	AND asset=i.asset
	AND customer_name IS NOT NULL
	AND ROWNUM=1;
	EXCEPTION WHEN OTHERS THEN
	lv_client_name:=NULL;
	END;
	
	IF lv_client_name IS NOT NULL THEN
    fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="String">'||lv_client_name||'</Data></Cell>');
	ELSE
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="String"></Data></Cell>');
	END IF;
	
	fnd_file.put_line(fnd_file.output,'</Row>');
	END LOOP;
	
	--- Grand Total:
	
	 fnd_file.put_line(fnd_file.output,'<Row>
    <Cell><Data ss:Type="String"></Data></Cell>
	<Cell ss:StyleID="s75"><Data ss:Type="String">Grand Total :</Data></Cell>');
	
	lv_total:=0;
	
	BEGIN
	SELECT SUM(NVL(net_movement,0)) INTO lv_total 
	FROM xxsmas_sheet9_dtls_tb 
	WHERE 1=1 ;
	EXCEPTION WHEN OTHERS THEN
	lv_total:=0;
	END;		
	
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');
	
	
	FOR j IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
    LOOP
	
    lv_total:=0;
	
	BEGIN
	SELECT SUM(NVL(net_movement,0)) INTO lv_total 
	FROM xxsmas_sheet9_dtls_tb 
	WHERE 1=1 
	AND period_name=j.period_name;
	EXCEPTION WHEN OTHERS THEN
	lv_total:=0;
	END;		
	
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');
	END LOOP;
	
   
   fnd_file.put_line(fnd_file.output,'</Row>');
   
   fnd_file.put_line(fnd_file.output,'
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <PageSetup>
    <Header x:Margin="0.3"/>
    <Footer x:Margin="0.3"/>
    <PageMargins x:Bottom="0.75" x:Left="0.7" x:Right="0.7" x:Top="0.75"/>
   </PageSetup>
   <Selected/>
   <Panes>
    <Pane>
     <Number>3</Number>
     <ActiveRow>8</ActiveRow>
     <ActiveCol>5</ActiveCol>
    </Pane>
   </Panes>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>');


  ---------10.FL income------------
 fnd_file.put_line(fnd_file.output,'
  <Worksheet ss:Name="10.FL income">
  <Table ss:ExpandedColumnCount="100" ss:ExpandedRowCount="100000" x:FullColumns="1"
   x:FullRows="1" ss:DefaultRowHeight="15">
<Column ss:AutoFitWidth="0" ss:Width="80"/>
<Column ss:AutoFitWidth="0" ss:Width="80"/>
<Column ss:AutoFitWidth="0" ss:Width="120"/>
<Column ss:AutoFitWidth="0" ss:Width="80"/>');

FOR j IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
LOOP
fnd_file.put_line(fnd_file.output,'<Column ss:AutoFitWidth="0" ss:Width="90"/>');
END LOOP;

fnd_file.put_line(fnd_file.output,'<Column ss:AutoFitWidth="0" ss:Width="120"/>');


   --- Heading 1:
   fnd_file.put_line(fnd_file.output,
   '<Row>
    <Cell ss:StyleID="s65"><Data ss:Type="String">SMAS Auto Leasing India Private Limited</Data></Cell>
   </Row>');
   --- Heading 2:
   fnd_file.put_line(fnd_file.output,
   '<Row>
    <Cell ss:StyleID="s65"><Data ss:Type="String">FL-Income Others for  the Period ended '||p_period||'</Data></Cell>
   </Row>');
   
   --- Column heading:
   fnd_file.put_line(fnd_file.output,'
   <Row ss:Index="4">
    <Cell ss:StyleID="s75"><Data ss:Type="String">Assets No.</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Oracle code</Data></Cell>
	<Cell ss:StyleID="s75"><Data ss:Type="String">Remarks</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Total</Data></Cell>');
	
	
	--- Dynamic period name as columns:
	FOR i IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
    LOOP
	fnd_file.put_line(fnd_file.output,'<Cell ss:StyleID="s75"><Data ss:Type="String">'||i.period_name||'</Data></Cell>');
	END LOOP;
	
	fnd_file.put_line(fnd_file.output,'<Cell ss:StyleID="s75"><Data ss:Type="String">Client Name</Data></Cell>	
   </Row>');
   
   FOR i IN (SELECT UNIQUE asset FROM xxsmas_sheet10_dtls_tb ORDER BY asset ASC)
   LOOP
   --- Column Values:
   fnd_file.put_line(fnd_file.output,'
    <Row>
	<Cell><Data ss:Type="String">'||i.asset||'</Data></Cell>
	<Cell><Data ss:Type="String">'||i.asset||'</Data></Cell>
	<Cell><Data ss:Type="String"></Data></Cell>');

	lv_total:=0;
	
	BEGIN
	SELECT SUM(NVL(net_movement,0)) INTO lv_total 
	FROM xxsmas_sheet10_dtls_tb 
	WHERE 1=1 
	AND asset=i.asset;
	END;
	
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');


	FOR j IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
    LOOP
	
    lv_total:=0;
	
	BEGIN
	SELECT SUM(NVL(net_movement,0)) INTO lv_total 
	FROM xxsmas_sheet10_dtls_tb 
	WHERE 1=1 
	AND asset=i.asset
	AND period_name=j.period_name;
	EXCEPTION WHEN OTHERS THEN
	lv_total:=0;
	END;		
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');
	END LOOP;

    lv_client_name:=NULL;
	
	BEGIN
	SELECT UNIQUE customer_name 
	INTO lv_client_name
	FROM xxsmas_sheet10_dtls_tb 
	WHERE 1=1 
	AND asset=i.asset
	AND customer_name IS NOT NULL
	AND ROWNUM=1;
	EXCEPTION WHEN OTHERS THEN
	lv_client_name:=NULL;
	END;
	
	IF lv_client_name IS NOT NULL THEN
    fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="String">'||lv_client_name||'</Data></Cell>');
	ELSE
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="String"></Data></Cell>');
	END IF;
	
	fnd_file.put_line(fnd_file.output,'</Row>');
	END LOOP;
	
	--- Grand Total:
	
	 fnd_file.put_line(fnd_file.output,'<Row>
    <Cell><Data ss:Type="String"></Data></Cell>
	<Cell><Data ss:Type="String"></Data></Cell>
	<Cell ss:StyleID="s75"><Data ss:Type="String">Grand Total :</Data></Cell>'
	);
	
	lv_total:=0;
	
	BEGIN
	SELECT SUM(NVL(net_movement,0)) INTO lv_total 
	FROM xxsmas_sheet10_dtls_tb 
	WHERE 1=1 ;
	EXCEPTION WHEN OTHERS THEN
	lv_total:=0;
	END;		
	
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');
	
	
	FOR j IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
    LOOP
	
    lv_total:=0;
	
	BEGIN
	SELECT SUM(NVL(net_movement,0)) INTO lv_total 
	FROM xxsmas_sheet10_dtls_tb 
	WHERE 1=1 
	AND period_name=j.period_name;
	EXCEPTION WHEN OTHERS THEN
	lv_total:=0;
	END;		
	
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');
	END LOOP;
	
   
   fnd_file.put_line(fnd_file.output,'</Row>');
   
   fnd_file.put_line(fnd_file.output,'
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <PageSetup>
    <Header x:Margin="0.3"/>
    <Footer x:Margin="0.3"/>
    <PageMargins x:Bottom="0.75" x:Left="0.7" x:Right="0.7" x:Top="0.75"/>
   </PageSetup>
   <Selected/>
   <Panes>
    <Pane>
     <Number>3</Number>
     <ActiveRow>8</ActiveRow>
     <ActiveCol>5</ActiveCol>
    </Pane>
   </Panes>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>');
 
 
   ---------11.Intt income others------------
 fnd_file.put_line(fnd_file.output,'
  <Worksheet ss:Name="11.Intt income others">
  <Table ss:ExpandedColumnCount="100" ss:ExpandedRowCount="100000" x:FullColumns="1"
   x:FullRows="1" ss:DefaultRowHeight="15">
<Column ss:AutoFitWidth="0" ss:Width="80"/>
<Column ss:AutoFitWidth="0" ss:Width="80"/>
<Column ss:AutoFitWidth="0" ss:Width="120"/>
<Column ss:AutoFitWidth="0" ss:Width="80"/>');

FOR j IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
LOOP
fnd_file.put_line(fnd_file.output,'<Column ss:AutoFitWidth="0" ss:Width="90"/>');
END LOOP;

fnd_file.put_line(fnd_file.output,'<Column ss:AutoFitWidth="0" ss:Width="120"/>');
   
   --- Heading 1:
   fnd_file.put_line(fnd_file.output,
   '<Row>
    <Cell ss:StyleID="s65"><Data ss:Type="String">SMAS Auto Leasing India Private Limited</Data></Cell>
   </Row>');
   --- Heading 2:
   fnd_file.put_line(fnd_file.output,
   '<Row>
    <Cell ss:StyleID="s65"><Data ss:Type="String">FL-Income Others for  the Period ended '||p_period||'</Data></Cell>
   </Row>');
   
   --- Column heading:
   fnd_file.put_line(fnd_file.output,'
   <Row ss:Index="4">
    <Cell ss:StyleID="s75"><Data ss:Type="String">Assets No.</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Oracle code</Data></Cell>
	<Cell ss:StyleID="s75"><Data ss:Type="String">Remarks</Data></Cell>
    <Cell ss:StyleID="s75"><Data ss:Type="String">Total</Data></Cell>
	');
	
	--- Dynamic period name as columns:
	FOR i IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
    LOOP
	fnd_file.put_line(fnd_file.output,'<Cell ss:StyleID="s75"><Data ss:Type="String">'||i.period_name||'</Data></Cell>');
	END LOOP;
	
	fnd_file.put_line(fnd_file.output,'<Cell ss:StyleID="s75"><Data ss:Type="String">Client Name</Data></Cell>	
   </Row>');
   
   FOR i IN (SELECT UNIQUE asset FROM xxsmas_sheet11_dtls_tb ORDER BY asset ASC)
   LOOP
   --- Column Values:
   fnd_file.put_line(fnd_file.output,'
    <Row>
	<Cell><Data ss:Type="String">'||i.asset||'</Data></Cell>
	<Cell><Data ss:Type="String">'||i.asset||'</Data></Cell>
	<Cell><Data ss:Type="String"></Data></Cell>');

	lv_total:=0;
	
	BEGIN
	SELECT SUM(NVL(net_movement,0)) INTO lv_total 
	FROM xxsmas_sheet11_dtls_tb 
	WHERE 1=1 
	AND asset=i.asset;
	END;
	
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');


	FOR j IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
    LOOP
	
    lv_total:=0;
	
	BEGIN
	SELECT SUM(NVL(net_movement,0)) INTO lv_total 
	FROM xxsmas_sheet11_dtls_tb 
	WHERE 1=1 
	AND asset=i.asset
	AND period_name=j.period_name;
	EXCEPTION WHEN OTHERS THEN
	lv_total:=0;
	END;		
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');
	END LOOP;

    lv_client_name:=NULL;
	
	BEGIN
	SELECT UNIQUE customer_name 
	INTO lv_client_name
	FROM xxsmas_sheet11_dtls_tb 
	WHERE 1=1 
	AND asset=i.asset
	AND customer_name IS NOT NULL
	AND ROWNUM=1;
	EXCEPTION WHEN OTHERS THEN
	lv_client_name:=NULL;
	END;
	
	IF lv_client_name IS NOT NULL THEN
    fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="String">'||lv_client_name||'</Data></Cell>');
	ELSE
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="String"></Data></Cell>');
	END IF;
	
	fnd_file.put_line(fnd_file.output,'</Row>');
	END LOOP;
	
	--- Grand Total:
	
	 fnd_file.put_line(fnd_file.output,'<Row>
    <Cell><Data ss:Type="String"></Data></Cell>
	<Cell><Data ss:Type="String"></Data></Cell>
	<Cell ss:StyleID="s75"><Data ss:Type="String">Grand Total :</Data></Cell>');
	
	lv_total:=0;
	
	BEGIN
	SELECT SUM(NVL(net_movement,0)) INTO lv_total 
	FROM xxsmas_sheet11_dtls_tb 
	WHERE 1=1 ;
	EXCEPTION WHEN OTHERS THEN
	lv_total:=0;
	END;		
	
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');
	
	
	FOR j IN (SELECT period_name,period_num,period_year FROM gl_periods
                WHERE 1=1
                AND period_year=lv_period_year
				AND period_num<=lv_period_number
               ORDER BY period_num DESC)
    LOOP
	
    lv_total:=0;
	
	BEGIN
	SELECT SUM(NVL(net_movement,0)) INTO lv_total 
	FROM xxsmas_sheet11_dtls_tb 
	WHERE 1=1 
	AND period_name=j.period_name;
	EXCEPTION WHEN OTHERS THEN
	lv_total:=0;
	END;		
	
	fnd_file.put_line(fnd_file.output,'<Cell><Data ss:Type="Number">'||lv_total||'</Data></Cell>');
	END LOOP;	
   
   fnd_file.put_line(fnd_file.output,'</Row>');
   
   fnd_file.put_line(fnd_file.output,'
  </Table>
  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
   <PageSetup>
    <Header x:Margin="0.3"/>
    <Footer x:Margin="0.3"/>
    <PageMargins x:Bottom="0.75" x:Left="0.7" x:Right="0.7" x:Top="0.75"/>
   </PageSetup>
   <Selected/>
   <Panes>
    <Pane>
     <Number>3</Number>
     <ActiveRow>8</ActiveRow>
     <ActiveCol>5</ActiveCol>
    </Pane>
   </Panes>
   <ProtectObjects>False</ProtectObjects>
   <ProtectScenarios>False</ProtectScenarios>
  </WorksheetOptions>
 </Worksheet>');
 
fnd_file.put_line(fnd_file.output,'</Workbook>');

END xxsmas_sheet_main;


END XXSMAS_REVENUE_PKG;

/
