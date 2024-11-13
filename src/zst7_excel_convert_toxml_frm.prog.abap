*&---------------------------------------------------------------------*
*& Include          ZST7_EXCEL_CONVERT_TOXML_FRM
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form get_filename
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM GET_FILENAME .

  DATA: LT_FILETABLE TYPE FILETABLE,
        LV_RC        TYPE SY-SUBRC.

  CALL METHOD CL_GUI_FRONTEND_SERVICES=>FILE_OPEN_DIALOG
    EXPORTING
      WINDOW_TITLE      = 'Select file'
      DEFAULT_EXTENSION = 'XLSX'
    CHANGING
      FILE_TABLE        = LT_FILETABLE
      RC                = LV_RC.
  IF SY-SUBRC <> 0.
*   Implement suitable error handling here
  ENDIF.

  READ TABLE LT_FILETABLE INDEX 1 ASSIGNING FIELD-SYMBOL(<FS>).
  MOVE <FS> TO: GV_FULLPATH, P_FILE.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form upload_data
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM UPLOAD_DATA .
  TYPE-POOLS : SLIS.

  " DATA LT_TABLE TYPE TABLE OF STRING.
  DATA :
    LT_RECORDS       TYPE SOLIX_TAB,
    LV_HEADERXSTRING TYPE XSTRING,
    LV_FILELENGTH    TYPE I.
  DATA: LT_SORTAB TYPE ABAP_SORTORDER_TAB,
        LS_SORTAB TYPE ABAP_SORTORDER.
  DATA: LS_MAPPING TYPE CL_ABAP_CORRESPONDING=>MAPPING_INFO,
        LT_MAPPING TYPE CL_ABAP_CORRESPONDING=>MAPPING_TABLE.
  DATA:
    LO_TYPE_DESCR     TYPE REF TO CL_ABAP_TYPEDESCR,
    LO_STRUCT_DESCR   TYPE REF TO CL_ABAP_STRUCTDESCR, "TYPE REF TO   CL_ABAP_TYPEDESCR,
    LO_TABLEDESCR     TYPE REF TO CL_ABAP_TABLEDESCR,
    LT_DESC_FIELDS    TYPE DDFIELDS,
    LV_NAME           TYPE CHAR30,
    LV_COUNT          TYPE I VALUE 1,
    LT_COMPONENTS_NEW TYPE  ABAP_COMPONENT_TAB,
    LS_COMPONENTS_NEW TYPE  ABAP_COMPONENTDESCR.
  DATA : LO_EXCEL_REF          TYPE REF TO CL_FDT_XL_SPREADSHEET,
         LCX_CX_FDT_EXCEL_CORE TYPE REF TO CX_FDT_EXCEL_CORE.

  CALL FUNCTION 'GUI_UPLOAD'
    EXPORTING
      FILENAME                = GV_FULLPATH
      FILETYPE                = 'BIN'
"     has_field_separator     = 'X'
    IMPORTING
      FILELENGTH              = LV_FILELENGTH
      HEADER                  = LV_HEADERXSTRING
    TABLES
      DATA_TAB                = LT_RECORDS
    EXCEPTIONS
      FILE_OPEN_ERROR         = 1
      FILE_READ_ERROR         = 2
      NO_BATCH                = 3
      GUI_REFUSE_FILETRANSFER = 4
      INVALID_TYPE            = 5
      NO_AUTHORITY            = 6
      UNKNOWN_ERROR           = 7
      BAD_DATA_FORMAT         = 8
      HEADER_NOT_ALLOWED      = 9
      SEPARATOR_NOT_ALLOWED   = 10
      HEADER_TOO_LONG         = 11
      UNKNOWN_DP_ERROR        = 12
      ACCESS_DENIED           = 13
      DP_OUT_OF_MEMORY        = 14
      DISK_FULL               = 15
      DP_TIMEOUT              = 16
      OTHERS                  = 17.

  "convert binary data to xstring

  CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
    EXPORTING
      INPUT_LENGTH = LV_FILELENGTH
    IMPORTING
      BUFFER       = LV_HEADERXSTRING
    TABLES
      BINARY_TAB   = LT_RECORDS
    EXCEPTIONS
      FAILED       = 1
      OTHERS       = 2.

  IF SY-SUBRC <> 0.
    "Implement suitable error handling here
  ENDIF.


  TRY .
      LO_EXCEL_REF = NEW CL_FDT_XL_SPREADSHEET(
        DOCUMENT_NAME = GV_FULLPATH
        XDOCUMENT     = LV_HEADERXSTRING ).
    CATCH CX_FDT_EXCEL_CORE INTO LCX_CX_FDT_EXCEL_CORE.
      "Implement suitable error handling here
  ENDTRY .

  "Get List of Worksheets
  LO_EXCEL_REF->IF_FDT_DOC_SPREADSHEET~GET_WORKSHEET_NAMES(
    IMPORTING
      WORKSHEET_NAMES = DATA(LT_WORKSHEETS) ).

*  if not lt_worksheets is initial.
  READ TABLE LT_WORKSHEETS INTO DATA(LV_WOKSHEETNAME) INDEX 1.


  DATA(LO_DATA_REF) = LO_EXCEL_REF->IF_FDT_DOC_SPREADSHEET~GET_ITAB_FROM_WORKSHEET(
    LV_WOKSHEETNAME ).

  "now you have excel work sheet data in dyanmic internal table
  ASSIGN LO_DATA_REF->* TO FIELD-SYMBOL(<GT_DATA>).



  "In the sample excel file created via program ZST7_TABLE_DOWNLOAD_TOEXCEL
  "column names  contained in the first row & generic table <GT_DATA>
  "hasn't structure
  " map fields of uploaded data table  to names in header line:
  """""""""""""
  LS_MAPPING-LEVEL = 0.
  LS_MAPPING-KIND = CL_ABAP_CORRESPONDING=>MAPPING_COMPONENT.
  "In uplouded file names of columns written in the first line
  LOOP AT <GT_DATA> ASSIGNING FIELD-SYMBOL(<FS_HEADER>) .
    EXIT.
  ENDLOOP.

  LO_TABLEDESCR ?= CL_ABAP_TABLEDESCR=>DESCRIBE_BY_DATA( <GT_DATA> ).

  LO_STRUCT_DESCR  ?=   LO_TABLEDESCR->GET_TABLE_LINE_TYPE( ).

  ASSIGN  LO_STRUCT_DESCR->COMPONENTS TO FIELD-SYMBOL(<FT_COMP>).
  LOOP AT <FT_COMP> ASSIGNING FIELD-SYMBOL(<FS_COMP>) .
    LV_COUNT = SY-TABIX.

    ASSIGN COMPONENT 4 OF STRUCTURE <FS_COMP> TO FIELD-SYMBOL(<FS_FIELD>).
    ASSIGN COMPONENT LV_COUNT OF STRUCTURE <FS_HEADER> TO FIELD-SYMBOL(<FS_NAME>).
    TRY.
        REPLACE ALL OCCURRENCES OF ` `  IN <FS_NAME> WITH '_'.
      CATCH CX_SY_REPLACE_INFINITE_LOOP.
    ENDTRY.

    IF <FS_NAME> IS INITIAL.
      LS_COMPONENTS_NEW-NAME =  <FS_FIELD>.
    ELSE.
      LS_COMPONENTS_NEW-NAME = <FS_NAME>.
    ENDIF.
    LS_MAPPING-SRCNAME = <FS_FIELD>.
    LS_MAPPING-DSTNAME = LS_COMPONENTS_NEW-NAME.
    APPEND LS_MAPPING TO LT_MAPPING.
    LS_COMPONENTS_NEW-TYPE = CL_ABAP_ELEMDESCR=>GET_STRING( ).
    CASE LV_COUNT.
      WHEN 1.
        LS_SORTAB-NAME = <FS_FIELD>.
        DATA(LS_SORT1) = LS_SORTAB.
      WHEN 2.
        LS_SORTAB-NAME = <FS_FIELD>.
        DATA(LS_SORT2) = LS_SORTAB.
      WHEN 4.
        LS_SORTAB-NAME = <FS_FIELD>.
        DATA(LS_SORT4) = LS_SORTAB.
    ENDCASE.

    "create new components table with updated column names
    APPEND LS_COMPONENTS_NEW TO LT_COMPONENTS_NEW.
  ENDLOOP.
  APPEND LS_SORT4 TO LT_SORTAB.
  APPEND LS_SORT1 TO LT_SORTAB.
  APPEND LS_SORT2 TO LT_SORTAB.
  SORT <GT_DATA> BY (LT_SORTAB).

  " create new structure description with updated column names

  DATA(LO_TABLEDESCR_UPD) = CL_ABAP_STRUCTDESCR=>CREATE( LT_COMPONENTS_NEW ).
  "create new data table with structure & updated column names
  DATA(LO_NEW_TABLEDESCR) = CL_ABAP_TABLEDESCR=>CREATE(
    P_LINE_TYPE  = LO_TABLEDESCR_UPD
    P_TABLE_KIND = CL_ABAP_TABLEDESCR=>TABLEKIND_STD
    P_UNIQUE     = ABAP_FALSE ).
  " APPEND LINES OF <GT_DATA> TO LO_NEW_TABLE.

  DATA :LO_NEW_TAB   TYPE REF TO DATA,
        LO_VEND_TAB  TYPE REF TO DATA,
        LO_ORDER_TAB TYPE REF TO DATA,
        LO_ITEM_TAB  TYPE REF TO DATA.
  CREATE DATA LO_NEW_TAB TYPE HANDLE LO_NEW_TABLEDESCR.
  CREATE DATA LO_VEND_TAB TYPE HANDLE LO_NEW_TABLEDESCR.
  CREATE DATA LO_ORDER_TAB TYPE HANDLE LO_NEW_TABLEDESCR.
  CREATE DATA LO_ITEM_TAB TYPE HANDLE LO_NEW_TABLEDESCR.


  ASSIGN LO_NEW_TAB->* TO <GT_DATA_1>.

* We instantiate class for Mapper
  DATA(LR_DYNAMIC_MAPPER) = CL_ABAP_CORRESPONDING=>CREATE(
    SOURCE      = <GT_DATA>
    DESTINATION = <GT_DATA_1>
    MAPPING     = LT_MAPPING ).
* Under the lr_dynamic_mapper object, we do the migration with the execute method.
  LR_DYNAMIC_MAPPER->EXECUTE(
    EXPORTING
      SOURCE      = <GT_DATA>
    CHANGING
      DESTINATION = <GT_DATA_1> ).
  " for future use to get orders of specific supplier
  ASSIGN LO_VEND_TAB->* TO <GT_VENDOR_DATA>.




ENDFORM.

*&---------------------------------------------------------------------*
*& Form transform_to_XML
*&---------------------------------------------------------------------*
*& *
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM TRANSFORM_TO_XML .
  DATA:
    LO_STREAMFACTORY TYPE REF TO IF_IXML_STREAM_FACTORY,
    LO_OSTREAM       TYPE REF TO IF_IXML_OSTREAM,
    LO_RENDERER      TYPE REF TO IF_IXML_RENDERER,
    LO_XMLDOC        TYPE REF TO CL_XML_DOCUMENT,
    LV_RC            TYPE I,
    LV_XML_SIZE      TYPE I,
    LR_OSTREAM       TYPE REF TO IF_IXML_OSTREAM,
    XML_STRING       TYPE XSTRING,
    LV_VENDOR        TYPE STRING,
    LV_COUNT         TYPE I.

  DATA: M_XMLDOC TYPE REF TO CL_XML_DOCUMENT.

  GCL_IXML = CL_IXML=>CREATE( ).

  GCL_XML_DOCUMENT = GCL_IXML->CREATE_DOCUMENT( ).
  DATA(LO_VENDORS) = GCL_XML_DOCUMENT->CREATE_SIMPLE_ELEMENT(
    NAME   = 'Suppliers'
    PARENT = GCL_XML_DOCUMENT ).

  LOOP AT <GT_DATA_1> ASSIGNING FIELD-SYMBOL(<FS_LINE>) .

    ASSIGN COMPONENT 4 OF STRUCTURE <FS_LINE> TO FIELD-SYMBOL(<FS_VEND>).

    IF <FS_VEND> IS INITIAL.
      PERFORM WRITE_ERR_LOG USING SY-TABIX.
    ELSE.
      ADD 1 TO LV_COUNT.

      IF LV_VENDOR IS INITIAL.
        LV_VENDOR = <FS_VEND>.
      ENDIF.

      IF <FS_VEND> NE LV_VENDOR.
        DATA(LO_VENDOR) = GCL_XML_DOCUMENT->CREATE_SIMPLE_ELEMENT(
          NAME   = 'Supplier'
          PARENT = LO_VENDORS
          VALUE  = LV_VENDOR ).

        PERFORM BUILD_IXML_DOM USING LO_VENDOR.
        CLEAR  <GT_VENDOR_DATA> .
        CLEAR LV_VENDOR.
      ELSE.

        APPEND <FS_LINE> TO <GT_VENDOR_DATA>.

      ENDIF.
    ENDIF.
  ENDLOOP.
* Create Stream Factory
  LO_STREAMFACTORY = GCL_IXML->CREATE_STREAM_FACTORY( ).

  LR_OSTREAM = LO_STREAMFACTORY->CREATE_OSTREAM_XSTRING( STRING = XML_STRING ).
* Create renderer
  LO_RENDERER = GCL_IXML->CREATE_RENDERER( OSTREAM  = LR_OSTREAM
                                           DOCUMENT = GCL_XML_DOCUMENT ).
* Set Pretty Print
  LR_OSTREAM->SET_PRETTY_PRINT( 'X' ).

* Render
  LV_RC = LO_RENDERER->RENDER( ).

* Get XML file size
  LV_XML_SIZE = LR_OSTREAM->GET_NUM_WRITTEN_RAW( ).

  CL_ABAP_BROWSER=>SHOW_XML(
    EXPORTING
      XML_XSTRING = XML_STRING
      TITLE       = 'Test XML'
      SIZE        = CL_ABAP_BROWSER=>MEDIUM ).
  CREATE OBJECT LO_XMLDOC.
  LO_XMLDOC->CREATE_WITH_DOM( DOCUMENT = GCL_XML_DOCUMENT ).
  LO_XMLDOC->EXPORT_TO_FILE( GV_FILENAME ).

* Display Output
  WRITE : 'XML File: ',GV_FILENAME, LV_XML_SIZE,  'Bytes'.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form build_ixml_dom
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> <FS_LINE>
*&---------------------------------------------------------------------*
FORM BUILD_IXML_DOM  USING PO_VENDOR TYPE REF TO IF_IXML_ELEMENT .


  DATA(LO_ORDERS) = GCL_XML_DOCUMENT->CREATE_SIMPLE_ELEMENT(
    NAME   = 'Orders'
    PARENT = PO_VENDOR ).
  LOOP AT <GT_VENDOR_DATA> ASSIGNING FIELD-SYMBOL(<FS_VEND_DATA>).
    ASSIGN COMPONENT 1 OF STRUCTURE <FS_VEND_DATA> TO FIELD-SYMBOL(<FS_ORD>). "Order number
    ASSIGN COMPONENT 2 OF STRUCTURE <FS_VEND_DATA> TO FIELD-SYMBOL(<FS_ITEM>).

    IF <FS_ITEM> = '10'.
      DATA(LO_ORDER) = GCL_XML_DOCUMENT->CREATE_SIMPLE_ELEMENT(
        NAME   = 'Order'
        PARENT = LO_ORDERS ).
      GCL_XML_DOCUMENT->CREATE_SIMPLE_ELEMENT( NAME   = 'order_num'
                                               PARENT = LO_ORDER
                                               VALUE  = <FS_ORD> ).
      DATA(LO_ITEMS) = GCL_XML_DOCUMENT->CREATE_SIMPLE_ELEMENT(
        NAME   = 'items'
        PARENT = LO_ORDER ).
      " to resolve the issue with loop at dynamic internal table by
      "'Where' condition dynamical where clause used:
      DATA(LV_WHERE) = |purchasing_document = | & |{ <FS_ORD> }|.
      LOOP AT <GT_VENDOR_DATA> ASSIGNING FIELD-SYMBOL(<FS_ITEM_LINE>) WHERE (LV_WHERE).
        ASSIGN COMPONENT 2 OF STRUCTURE <FS_ITEM_LINE> TO FIELD-SYMBOL(<FS_ITEMNUM>).
        ASSIGN COMPONENT 3 OF STRUCTURE <FS_ITEM_LINE> TO FIELD-SYMBOL(<FS_MAT>).
        ASSIGN COMPONENT 5 OF STRUCTURE <FS_ITEM_LINE> TO FIELD-SYMBOL(<FS_TEXT>).
        ASSIGN COMPONENT 11 OF STRUCTURE <FS_ITEM_LINE> TO FIELD-SYMBOL(<FS_PRICE>).
        DATA(LO_ITEM) = GCL_XML_DOCUMENT->CREATE_SIMPLE_ELEMENT(
          NAME   = 'Item'
          PARENT = LO_ITEMS
          VALUE  = <FS_ITEMNUM> ).

        LO_ITEM->SET_ATTRIBUTE( NAME  = 'Material'
                                VALUE = <FS_MAT> ).
        LO_ITEM->SET_ATTRIBUTE( NAME  = 'Mat.description'
                                VALUE = <FS_TEXT> ).
        LO_ITEM->SET_ATTRIBUTE( NAME  = 'net.price'
                                VALUE = <FS_PRICE> ).
      ENDLOOP.

    ENDIF.

  ENDLOOP.




ENDFORM.



*&---------------------------------------------------------------------*
*& Form write_err_log
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> <FS_4>
*&---------------------------------------------------------------------*
FORM WRITE_ERR_LOG  USING    PV_TABIX TYPE SYTABIX.
  "do something
ENDFORM.
