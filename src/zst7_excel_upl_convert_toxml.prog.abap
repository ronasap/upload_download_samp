*&---------------------------------------------------------------------*
*& Report ZST7_EXCEL_APL_CONVERT_TOXML
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZST7_EXCEL_UPL_CONVERT_TOXML.

INCLUDE ZST7_EXCEL_CONVERT_TOXML_DAT.

INCLUDE ZST7_EXCEL_CONVERT_TOXML_SEL.

INCLUDE ZST7_EXCEL_CONVERT_TOXML_FRM.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR P_FILE.

  PERFORM GET_FILENAME.

  PERFORM UPLOAD_DATA .

  PERFORM TRANSFORM_TO_XML.
