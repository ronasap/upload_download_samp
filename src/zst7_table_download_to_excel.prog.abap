*&---------------------------------------------------------------------*
*& Report ZST7_TABLE_DOWNLOAD_TO_EXCEL
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZST7_TABLE_DOWNLOAD_TO_EXCEL.


INCLUDE ZST7_TABLE_DOWN_TO_EXCEL_SEL.

INCLUDE ZST7_TABLE_DOWN_TO_EXCEL_DAT.

INCLUDE ZST7_TABLE_DOWN_TO_EXCEL_FRM.


INITIALIZATION.
  P_FILE = 'C:\Users\Owner\Documents\testdatadown.xlsx'.

START-OF-SELECTION.

  PERFORM CREATE_EXP_DATA.
