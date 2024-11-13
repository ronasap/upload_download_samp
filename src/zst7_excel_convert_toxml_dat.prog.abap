*&---------------------------------------------------------------------*
*& Include          ZST7_EXCEL_CONVERT_TOXML_DAT
*&---------------------------------------------------------------------*


DATA:
      GV_FULLPATH      TYPE STRING,
      GV_FILENAME      TYPE LOCALFILE VALUE 'C:\Users\Owner\Documents\xmlfile.xml',
      GCL_XML_DOCUMENT TYPE REF TO  IF_IXML_DOCUMENT,
      GCL_IXML         TYPE REF TO IF_IXML.


FIELD-SYMBOLS : <GT_DATA_1>      TYPE STANDARD TABLE,
                <GT_VENDOR_DATA> TYPE STANDARD TABLE.
