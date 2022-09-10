CREATE OR REPLACE PACKAGE XXSMAS_REVENUE_PKG
AS

--- Get Customer Name:
FUNCTION get_customer_name_func(p_ledger_name  IN VARCHAR2,
                                p_asset_number IN VARCHAR2
								)
RETURN VARCHAR2;

--- Get Periodwise Net Movement LR:
FUNCTION get_net_movement_lr (p_ledger_name  IN VARCHAR2,
                              p_asset_number IN VARCHAR2,
							  p_period_name  IN VARCHAR2
							 )
RETURN NUMBER;

--- Get Periodwise Net Movement FMS:
FUNCTION get_net_movement_fms   (p_ledger_name  IN VARCHAR2,
                                 p_asset_number IN VARCHAR2,
								 p_period_name  IN VARCHAR2
								)
RETURN NUMBER;

--- Get Total LR:
FUNCTION get_total_net_movement_lr(p_ledger_name  IN VARCHAR2,
                                   p_asset_number IN VARCHAR2
								   )
RETURN NUMBER;

--- Get Total FMS:
FUNCTION get_total_net_movement_fms(p_ledger_name  IN VARCHAR2,
                                    p_asset_number IN VARCHAR2
									)
RETURN NUMBER;

--- Get Sheet1 Main Details:
PROCEDURE xxsmas_sheet_main(errbuf OUT VARCHAR2,
                             retcode OUT VARCHAR2,
							 p_ledger_name IN VARCHAR2,
							 p_period IN VARCHAR2);
								
END XXSMAS_REVENUE_PKG;
/