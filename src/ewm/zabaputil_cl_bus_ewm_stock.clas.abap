"! EWM stock. All /SCWM/ objects are reached dynamically, so the class
"! activates in systems without EWM and fails only when it is called there.
CLASS zabaputil_cl_bus_ewm_stock DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    "! product id as the EWM tables and modules hold it (16 bytes)
    TYPES ty_matid TYPE x LENGTH 16.

    "! Converts a product number to the product id (/SCWM/CL_UI_STOCK_FIELDS)
    CLASS-METHODS read_product_id
      IMPORTING
        iv_matnr    TYPE clike
      EXPORTING
        ev_matid    TYPE ty_matid
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Reads a storage bin (/SCWM/LAGP)
    "! @parameter er_bin | reference to the /SCWM/LAGP row
    CLASS-METHODS read_bin
      IMPORTING
        iv_lgnum    TYPE clike
        iv_lgpla    TYPE clike
      EXPORTING
        er_bin      TYPE REF TO data
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Reads the available stock on a storage bin (/SCWM/AQUA)
    "! @parameter er_stock | reference to a standard table of /SCWM/AQUA
    CLASS-METHODS read_by_bin
      IMPORTING
        iv_lgnum    TYPE clike
        iv_lgpla    TYPE clike
      EXPORTING
        er_stock    TYPE REF TO data
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zabaputil_cl_bus_ewm_stock IMPLEMENTATION.

  METHOD read_product_id.

    DATA lo_fields TYPE REF TO object.
    DATA lv_matnr  TYPE c LENGTH 40.

    CLEAR: ev_matid, ev_is_error, et_bapiret.

    lv_matnr = iv_matnr.

    TRY.
        CREATE OBJECT lo_fields TYPE ('/SCWM/CL_UI_STOCK_FIELDS').
        CALL METHOD lo_fields->('GET_MATID_BY_NO')
          EXPORTING
            iv_matnr = lv_matnr
          RECEIVING
            ev_matid = ev_matid.
        IF ev_matid IS INITIAL.
          zabaputil_cl_bus_util_context=>bapi_msg_add_text( EXPORTING iv_text    = |Product { iv_matnr } not found|
                                                            CHANGING  ct_bapiret = et_bapiret ).
        ENDIF.
      CATCH cx_root INTO DATA(lx_error).
        CLEAR ev_matid.
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( CHANGING ct_bapiret  = et_bapiret
                                                         cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD read_bin.

    DATA lv_table TYPE string VALUE '/SCWM/LAGP'.
    DATA lv_lgnum TYPE c LENGTH 4.
    DATA lv_lgpla TYPE c LENGTH 18.
    FIELD-SYMBOLS <bin> TYPE any.

    CLEAR: er_bin, ev_is_error, et_bapiret.

    lv_lgnum = iv_lgnum.
    lv_lgpla = iv_lgpla.

    TRY.
        CREATE DATA er_bin TYPE (lv_table).
        ASSIGN er_bin->* TO <bin>.
        SELECT SINGLE * FROM (lv_table) INTO @<bin> WHERE lgnum = @lv_lgnum AND lgpla = @lv_lgpla.
        IF sy-subrc <> 0.
          CLEAR er_bin.
          zabaputil_cl_bus_util_context=>bapi_msg_add_text( EXPORTING iv_text    = |Storage bin { iv_lgpla } not found in warehouse { iv_lgnum }|
                                                            CHANGING  ct_bapiret = et_bapiret ).
        ENDIF.
      CATCH cx_root INTO DATA(lx_error).
        CLEAR er_bin.
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( CHANGING ct_bapiret  = et_bapiret
                                                         cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD read_by_bin.

    DATA lv_table TYPE string VALUE '/SCWM/AQUA'.
    DATA lv_lgnum TYPE c LENGTH 4.
    DATA lv_lgpla TYPE c LENGTH 18.
    FIELD-SYMBOLS <stock> TYPE STANDARD TABLE.

    CLEAR: er_stock, ev_is_error, et_bapiret.

    lv_lgnum = iv_lgnum.
    lv_lgpla = iv_lgpla.

    TRY.
        CREATE DATA er_stock TYPE STANDARD TABLE OF (lv_table).
        ASSIGN er_stock->* TO <stock>.
        SELECT * FROM (lv_table) INTO TABLE @<stock> WHERE lgnum = @lv_lgnum AND lgpla = @lv_lgpla.
      CATCH cx_root INTO DATA(lx_error).
        CLEAR er_stock.
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( CHANGING ct_bapiret  = et_bapiret
                                                         cv_is_error = ev_is_error ).

  ENDMETHOD.

ENDCLASS.
