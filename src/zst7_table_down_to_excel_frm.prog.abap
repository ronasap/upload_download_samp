*&---------------------------------------------------------------------*
*& Include          ZST7_TABLE_DOWN_TO_EXCEL_FRM
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form get_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM CREATE_EXP_DATA .
  TYPES: BEGIN OF LTP_LINE_BIN,

           DATA(1024) TYPE X,

         END OF LTP_LINE_BIN.

  DATA: LT_DATA_TAB_BIN TYPE STANDARD TABLE OF LTP_LINE_BIN.
  DATA :LV_FIELDNAME  TYPE FIELDNAME,
        LT_FIELDNAMES TYPE STANDARD TABLE OF FIELDNAME.
  SELECT *
    FROM ZST9_PURORDERDET
    UP TO 50 ROWS
    INTO TABLE @DATA(LT_SRCTAB).


  BREAK-POINT.

  CALL FUNCTION 'SAP_CONVERT_TO_XLS_FORMAT'
    EXPORTING
      I_LINE_HEADER     = ' '
      I_FILENAME        = P_FILE
      I_APPL_KEEP       = ' '
    TABLES
      I_TAB_SAP_DATA    = LT_SRCTAB
    EXCEPTIONS
      CONVERSION_FAILED = 1
      OTHERS            = 2.
  IF SY-SUBRC <> 0.
* Implement suitable error handling here
  ENDIF.
 write sy-subrc.

ENDFORM.
