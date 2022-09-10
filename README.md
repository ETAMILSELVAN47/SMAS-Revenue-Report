#### SMAS Project

**Description:** SMAS Revenue Report (Sep-2022)


**1. Create Tables:**

@XXSMAS_SUMMARY_DTLS_TB.sql

@XXSMAS_SHEET1_DTLS_TB.sql

@XXSMAS_SHEET2_DTLS_TB.sql

@XXSMAS_SHEET3_DTLS_TB.sql

@XXSMAS_SHEET4_DTLS_TB.sql

@XXSMAS_SHEET5_DTLS_TB.sql

@XXSMAS_SHEET6_DTLS_TB.sql

@XXSMAS_SHEET7_DTLS_TB.sql

@XXSMAS_SHEET9_DTLS_TB.sql

@XXSMAS_SHEET10_DTLS_TB.sql

@XXSMAS_SHEET11_DTLS_TB.sql

**2. Create Packages**

@XXSMAS_REVENUE_PKG.PKS

@XXSMAS_REVENUE_PKG.PKB

**3. Create views**

XXSMAS_SUMMARY_DTLS_VW

**4. Valueset**

   **Source:** SMAS-TEST
   
   **Target:** SMAS-PROD

   **Valueset Name: XXSMAS_REVENUE_LEDGER_SET**
   
   **Download:**
   
   FNDLOAD apps/testapps O Y DOWNLOAD $FND_TOP/patch/115/import/afffload.lct XXSMAS_REVENUE_LEDGER_SET.ldt VALUE_SET FLEX_VALUE_SET_NAME="XXSMAS_REVENUE_LEDGER_SET"
   
   **Upload:**
   
   FNDLOAD apps/<pwd> 0 Y UPLOAD $FND_TOP/patch/115/import/afffload.lct XXSMAS_REVENUE_LEDGER_SET.ldt
   
   **Valueset Name: XXSMAS_GL_PERIOD_NAME_SET**
   
   **Download:**
   
   FNDLOAD apps/testapps O Y DOWNLOAD $FND_TOP/patch/115/import/afffload.lct XXSMAS_GL_PERIOD_NAME_SET.ldt VALUE_SET FLEX_VALUE_SET_NAME="XXSMAS_GL_PERIOD_NAME_SET"
   
   **Upload:**
   
   FNDLOAD apps/<pwd> 0 Y UPLOAD $FND_TOP/patch/115/import/afffload.lct XXSMAS_GL_PERIOD_NAME_SET.ldt


**5.Concurrent Program**

   **Concurrent Program Name: SMAS Revenue Report**
   
   **Download:**
   
   FNDLOAD apps/testapps O Y DOWNLOAD $FND_TOP/patch/115/import/afcpprog.lct XXSMAS_REVENUE_REPORT.ldt PROGRAM APPLICATION_SHORT_NAME="XXSMAS" CONCURRENT_PROGRAM_NAME="XXSMAS_REVENUE_REPORT"
   
   **Upload:**
   
   FNDLOAD apps/<Pwd> 0 Y UPLOAD $FND_TOP/patch/115/import/afcpprog.lct XXSMAS_REVENUE_REPORT.ldt - WARNING=YES UPLOAD_MODE=REPLACE CUSTOM_MODE=FORCE
  
    
 **6. Assign Concurrent Program to Responsibility**
  
  **Concurrent Program Name:** SMAS Revenue Report
  
  **Parameters:**
  
  a)Ledger
  
  b)Period
