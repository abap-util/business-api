"! EWM handling units. All /SCWM/ objects are reached dynamically, so the
"! class activates in systems without EWM and fails only when it is called there.
CLASS zabaputil_cl_bus_ewm_hu DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    "! Creates a handling unit with the packing class (/SCWM/CL_WM_PACKING) and
    "! saves it. The warehouse number is set in the transaction manager (/SCWM/CL_TM).
    "! @parameter iv_pmat    | packaging material, a product number
    "! @parameter iv_huident | handling unit number; initial: the number range of the packaging material
    "! @parameter iv_lgpla   | storage bin the handling unit is created on
    "! @parameter er_header  | reference to the header of the new handling unit (/SCWM/S_HUHDR_INT)
    CLASS-METHODS create
      IMPORTING
        iv_lgnum    TYPE clike
        iv_pmat     TYPE clike
        iv_huident  TYPE clike OPTIONAL
        iv_lgpla    TYPE clike OPTIONAL
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_huident  TYPE string
        er_header   TYPE REF TO data
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

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

  METHOD create.

    DATA lo_pack    TYPE REF TO object.
    DATA lv_lgnum   TYPE c LENGTH 4.
    DATA lv_huident TYPE c LENGTH 20.
    DATA lv_lgpla   TYPE c LENGTH 18.
    DATA lv_matid   TYPE zabaputil_cl_bus_ewm_stock=>ty_matid.
    DATA lv_false   TYPE abap_bool VALUE abap_false.
    FIELD-SYMBOLS <header> TYPE any.
    FIELD-SYMBOLS <field>  TYPE any.

    CLEAR: ev_huident, er_header, ev_is_error, et_bapiret.

    lv_lgnum   = iv_lgnum.
    lv_huident = zabaputil_cl_bus_util_context=>conv_alpha_in( iv_value  = iv_huident
                                                               iv_length = 20 ).
    lv_lgpla   = iv_lgpla.

    zabaputil_cl_bus_ewm_stock=>read_product_id( EXPORTING iv_matnr   = iv_pmat
                                                 IMPORTING ev_matid   = lv_matid
                                                           et_bapiret = et_bapiret ).

    IF zabaputil_cl_bus_util_context=>bapi_check_is_error( et_bapiret ) = abap_false.
      TRY.
          CALL METHOD ('/SCWM/CL_TM')=>('SET_LGNUM')
            EXPORTING
              iv_lgnum = lv_lgnum.
          CALL METHOD ('/SCWM/CL_WM_PACKING')=>('GET_INSTANCE')
            IMPORTING
              eo_instance = lo_pack.
          CALL METHOD lo_pack->('INIT')
            EXPORTING
              iv_lgnum = lv_lgnum
            EXCEPTIONS
              OTHERS   = 1.
          IF sy-subrc <> 0.
            zabaputil_cl_bus_util_context=>bapi_msg_add_sy( EXPORTING iv_context = 'INIT'
                                                            CHANGING  ct_bapiret = et_bapiret ).
          ELSE.
            CREATE DATA er_header TYPE ('/SCWM/S_HUHDR_INT').
            ASSIGN er_header->* TO <header>.
            CALL METHOD lo_pack->('CREATE_HU')
              EXPORTING
                iv_pmat    = lv_matid
                iv_huident = lv_huident
                i_location = lv_lgpla
              RECEIVING
                es_huhdr   = <header>
              EXCEPTIONS
                OTHERS     = 1.
            IF sy-subrc <> 0.
              zabaputil_cl_bus_util_context=>bapi_msg_add_sy( EXPORTING iv_context = 'CREATE_HU'
                                                              CHANGING  ct_bapiret = et_bapiret ).
            ELSE.
              CALL METHOD lo_pack->('SAVE')
                EXPORTING
                  iv_commit = lv_false
                  iv_wait   = lv_false
                EXCEPTIONS
                  OTHERS    = 1.
              IF sy-subrc <> 0.
                zabaputil_cl_bus_util_context=>bapi_msg_add_sy( EXPORTING iv_context = 'SAVE'
                                                                CHANGING  ct_bapiret = et_bapiret ).
              ELSE.
                ASSIGN COMPONENT 'HUIDENT' OF STRUCTURE <header> TO <field>.
                IF sy-subrc = 0.
                  ev_huident = <field>.
                ENDIF.
              ENDIF.
            ENDIF.
          ENDIF.
        CATCH cx_root INTO DATA(lx_error).
          zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                                 CHANGING  ct_bapiret = et_bapiret ).
      ENDTRY.
    ENDIF.

    IF zabaputil_cl_bus_util_context=>bapi_check_is_error( et_bapiret ) = abap_true.
      CLEAR: ev_huident, er_header.
    ENDIF.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD read.

    DATA lv_table   TYPE string VALUE '/SCWM/HUHDR'.
    DATA lv_lgnum   TYPE c LENGTH 4.
    DATA lv_huident TYPE c LENGTH 20.
    FIELD-SYMBOLS <header> TYPE any.

    CLEAR: er_header, ev_is_error, et_bapiret.

    lv_lgnum   = iv_lgnum.
    lv_huident = zabaputil_cl_bus_util_context=>conv_alpha_in( iv_value  = iv_huident
                                                               iv_length = 20 ).

    TRY.
        CREATE DATA er_header TYPE (lv_table).
        ASSIGN er_header->* TO <header>.
        SELECT SINGLE * FROM (lv_table) INTO @<header> WHERE lgnum = @lv_lgnum AND huident = @lv_huident ##WARN_OK.
        IF sy-subrc <> 0.
          CLEAR er_header.
          zabaputil_cl_bus_util_context=>bapi_msg_add_text( EXPORTING iv_text    = |Handling unit { iv_huident } not found in warehouse { iv_lgnum }|
                                                            CHANGING  ct_bapiret = et_bapiret ).
        ENDIF.
      CATCH cx_root INTO DATA(lx_error).
        CLEAR er_header.
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( CHANGING ct_bapiret  = et_bapiret
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
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( CHANGING ct_bapiret  = et_bapiret
                                                         cv_is_error = ev_is_error ).

  ENDMETHOD.

ENDCLASS.
