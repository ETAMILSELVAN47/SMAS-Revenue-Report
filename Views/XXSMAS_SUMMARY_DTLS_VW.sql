--------------------------------------------------------
--  File created - Saturday-September-10-2022   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for View XXSMAS_SUMMARY_DTLS_VW
--------------------------------------------------------

  CREATE OR REPLACE FORCE VIEW "APPS"."XXSMAS_SUMMARY_DTLS_VW" ("TYPE", "LEDGER_NAME", "LEDGER_CALENDAR", "PERIOD_NAME", "PERIOD_NUMBER", "PERIOD_YEAR", "ACCOUNT", "ACCOUNT_DESCRIPTION", "OPENING_BALANCE", "DEBIT", "CREDIT", "NET_MOVEMENT", "CLOSING_BALANCE") AS 
  SELECT "TYPE","LEDGER_NAME","LEDGER_CALENDAR","PERIOD_NAME","PERIOD_NUMBER","PERIOD_YEAR","ACCOUNT","ACCOUNT_DESCRIPTION","OPENING_BALANCE","DEBIT","CREDIT","NET_MOVEMENT","CLOSING_BALANCE" FROM (
SELECT  UNIQUE 
        1          TYPE,    
        gl.name            ledger_name,
        gl.period_set_name ledger_calendar,
        gb.period_name     period_name,
        gb.period_num      period_number,
		gb.period_year     period_year,
        gcc.segment4       account,		
		apps.gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,4,gcc.segment4) account_description,
		SUM (NVL (gb.begin_balance_dr, 0) - NVL (gb.begin_balance_cr, 0))  opening_balance,
		SUM(NVL (gb.period_net_dr, 0)) debit,
		SUM(NVL (gb.period_net_cr,0))  credit,
		SUM (NVL (gb.period_net_dr, 0) - NVL (gb.period_net_cr, 0))*-1 net_movement,
		SUM ((NVL (gb.period_net_dr, 0) + NVL (gb.begin_balance_dr, 0)))
       - SUM (NVL (gb.period_net_cr, 0) + NVL (gb.begin_balance_cr, 0)) closing_balance

FROM     gl_ledgers               gl,
         gl_balances              gb,
		 gl_code_combinations     gcc

WHERE 1=1
AND gl.ledger_id=gb.ledger_id
AND gb.actual_flag = 'A'
AND gb.template_id IS NULL
AND gb.code_combination_id = gcc.code_combination_id
AND gcc.segment4 IN (
'30100',
'30200',
'30349',
'30351')

group by gl.name             ,
         gl.period_set_name  ,
         gb.period_name      ,
         gb.period_num       ,
         gcc.segment4        ,	
		 gb.period_year,
		 gcc.chart_of_accounts_id
UNION

SELECT  UNIQUE 
        2           TYPE,    
        gl.name            ledger_name,
        gl.period_set_name ledger_calendar,
        gb.period_name     period_name,
        gb.period_num      period_number,
		gb.period_year      period_year,
        gcc.segment4       account,		
		apps.gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,4,gcc.segment4) account_description,
		SUM (NVL (gb.begin_balance_dr, 0) - NVL (gb.begin_balance_cr, 0))  opening_balance,
		SUM(NVL (gb.period_net_dr, 0)) debit,
		SUM(NVL (gb.period_net_cr,0))  credit,
		SUM (NVL (gb.period_net_dr, 0) - NVL (gb.period_net_cr, 0))*-1 net_movement,
		SUM ((NVL (gb.period_net_dr, 0) + NVL (gb.begin_balance_dr, 0)))
       - SUM (NVL (gb.period_net_cr, 0) + NVL (gb.begin_balance_cr, 0)) closing_balance

FROM     gl_ledgers               gl,
         gl_balances              gb,
		 gl_code_combinations     gcc

WHERE 1=1
AND gl.ledger_id=gb.ledger_id
AND gb.actual_flag = 'A'
AND gb.template_id IS NULL
AND gb.code_combination_id = gcc.code_combination_id
AND gcc.segment4 IN (
'30350',
'30353',
'30403',
'30800',
'30212',
'30501',
'38003'
)
group by gl.name             ,
         gl.period_set_name  ,
         gb.period_name      ,
         gb.period_num       ,
         gcc.segment4        ,
         gb.period_year,		 
		 gcc.chart_of_accounts_id)
ORDER BY 6,1,5 DESC
;
