"! EWM handling units. All /SCWM/ objects are reached dynamically, so the
"! class activates in systems without EWM and fails only when it is called there.
CLASS zabaputil_cl_bus_ewm_hu DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    "! Reads the header of a handling unit (/SCWM/HUHDR)
    "! @parameter er_header | reference to the /SCWM/HUHDR row
    CLASS-METHODS read
      IMPORTING
        iv_lgnum    TYPE clike
        iv_huident  TYPE clike
      EXPORTING
        er_header   TYPE REF TO data
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Reads the handling units on a storage bin (/SCWM/HUHDR)
    "! @parameter er_headers | reference to a standard table of /SCWM/HUHDR
    CLASS-METHODS read_by_bin
      IMPORTING
        iv_lgnum    TYPE clike
        iv_lgpla    TYPE clike
      EXPORTING
        er_headers  TYPE REF TO data
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zabaputil_cl_bus_ewm_hu IMPLEMENTATION.

  METHOD read.

    DATA lv_table   TYPE string VALUE '/SCWM/HUHDR'.
    DATA lv_lgnum   TYPE c LENGTH 4.
    DATA lv_huident TYPE c LENGTH 20.
    FIELD-SYMBOLS <header> TYPE any.

    CLEAR: er_header, ev_is_error, et_bapiret.

    lv_lgnum   = iv_lgnum.
    lv_huident = zabaputil_cl_bus=>alpha_in( iv_value  = iv_huident
                                             iv_length = 20 ).

    TRY.
        CREATE DATA er_header TYPE (lv_table).
        ASSIGN er_header->* TO <header>.
        SELECT SINGLE * FROM (lv_table) INTO @<header> WHERE lgnum = @lv_lgnum AND huident = @lv_huident ##WARN_OK.
        IF sy-subrc <> 0.
          CLEAR er_header.
          zabaputil_cl_bus=>msg_add_text( EXPORTING iv_text    = |Handling unit { iv_huident } not found in warehouse { iv_lgnum }|
                                          CHANGING  ct_bapiret = et_bapiret ).
        ENDIF.
      CATCH cx_root INTO DATA(lx_error).
        CLEAR er_header.
        zabaputil_cl_bus=>msg_add_exception( EXPORTING ix_error   = lx_error
                                             CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus=>finish( CHANGING ct_bapiret  = et_bapiret
                                       cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD read_by_bin.

    DATA lv_table TYPE string VALUE '/SCWM/HUHDR'.
    DATA lv_lgnum TYPE c LENGTH 4.
    DATA lv_lgpla TYPE c LENGTH 18.
    FIELD-SYMBOLS <headers> TYPE STANDARD TABLE.

    CLEAR: er_headers, ev_is_error, et_bapiret.

    lv_lgnum = iv_lgnum.
    lv_lgpla = iv_lgpla.

    TRY.
        CREATE DATA er_headers TYPE STANDARD TABLE OF (lv_table).
        ASSIGN er_headers->* TO <headers>.
        SELECT * FROM (lv_table) INTO TABLE @<headers> WHERE lgnum = @lv_lgnum AND lgpla = @lv_lgpla.
      CATCH cx_root INTO DATA(lx_error).
        CLEAR er_headers.
        zabaputil_cl_bus=>msg_add_exception( EXPORTING ix_error   = lx_error
                                             CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus=>finish( CHANGING ct_bapiret  = et_bapiret
                                       cv_is_error = ev_is_error ).

  ENDMETHOD.

ENDCLASS.
