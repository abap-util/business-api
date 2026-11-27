CLASS zabaputil_cl_bus_pp_order DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES ty_t_header TYPE STANDARD TABLE OF bapi_order_header1 WITH DEFAULT KEY.
    TYPES ty_t_position TYPE STANDARD TABLE OF bapi_order_item WITH DEFAULT KEY.
    TYPES ty_t_component TYPE STANDARD TABLE OF bapi_order_component WITH DEFAULT KEY.
    TYPES ty_t_operation TYPE STANDARD TABLE OF bapi_order_operation1 WITH DEFAULT KEY.

    "! Reads a production order with items, components and operations (BAPI_PRODORD_GET_DETAIL)
    CLASS-METHODS read
      IMPORTING
        iv_aufnr     TYPE aufnr
      EXPORTING
        es_header    TYPE bapi_order_header1
        et_position  TYPE ty_t_position
        et_component TYPE ty_t_component
        et_operation TYPE ty_t_operation
        ev_is_error  TYPE abap_bool
        et_bapiret   TYPE bapirettab.

    "! Releases a production order (BAPI_PRODORD_RELEASE)
    CLASS-METHODS release
      IMPORTING
        iv_aufnr    TYPE aufnr
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Checks the material availability of a production order (BAPI_PRODORD_CHECK_MAT_AVAIL).
    "! The outcome comes back as messages only: missing parts are typically a warning or an
    "! information in et_bapiret, which ev_is_error does not flag - ev_is_error says the check
    "! failed, not that material is missing. Once committed, the result is in the order's
    "! system status (MSPT missing parts, MACM material committed), which
    "! zabaputil_cl_bus_ca_status reads.
    CLASS-METHODS check_availability
      IMPORTING
        iv_aufnr    TYPE aufnr
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Completes a production order technically (BAPI_PRODORD_COMPLETE_TECH)
    CLASS-METHODS complete_technically
      IMPORTING
        iv_aufnr    TYPE aufnr
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

  PROTECTED SECTION.
  PRIVATE SECTION.

    "! the order BAPIs with the same interface: ORDERS in, RETURN and DETAIL_RETURN out
    CLASS-METHODS call_order_bapi
      IMPORTING
        iv_function TYPE clike
        iv_aufnr    TYPE aufnr
      CHANGING
        ct_bapiret  TYPE bapirettab.

ENDCLASS.



CLASS zabaputil_cl_bus_pp_order IMPLEMENTATION.

  METHOD read.

    DATA ls_objects TYPE bapi_pp_order_objects.
    DATA ls_return  TYPE bapiret2.
    DATA lt_header  TYPE ty_t_header.
        DATA lx_error TYPE REF TO cx_root.

    CLEAR: es_header, et_position, et_component, et_operation, ev_is_error, et_bapiret.

    TRY.
        ls_objects-header     = abap_true.
        ls_objects-positions  = abap_true.
        ls_objects-components = abap_true.
        ls_objects-operations = abap_true.
        CALL FUNCTION 'BAPI_PRODORD_GET_DETAIL'
          EXPORTING
            number        = iv_aufnr
            order_objects = ls_objects
          IMPORTING
            return        = ls_return
          TABLES
            header        = lt_header
            position      = et_position
            component     = et_component
            operation     = et_operation.
        zabaputil_cl_bus_util_context=>bapi_msg_add_bapiret2( EXPORTING is_return  = ls_return
                                                              CHANGING  ct_bapiret = et_bapiret ).
        READ TABLE lt_header INTO es_header INDEX 1.
        
      CATCH cx_root INTO lx_error.
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( CHANGING ct_bapiret  = et_bapiret
                                                         cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD release.

    CLEAR: ev_is_error, et_bapiret.

    call_order_bapi( EXPORTING iv_function = 'BAPI_PRODORD_RELEASE'
                               iv_aufnr    = iv_aufnr
                     CHANGING  ct_bapiret  = et_bapiret ).

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD check_availability.

    DATA ls_return TYPE bapiret2.
        DATA lx_error TYPE REF TO cx_root.

    CLEAR: ev_is_error, et_bapiret.

    TRY.
        CALL FUNCTION 'BAPI_PRODORD_CHECK_MAT_AVAIL'
          EXPORTING
            number = iv_aufnr
          IMPORTING
            return = ls_return.
        zabaputil_cl_bus_util_context=>bapi_msg_add_bapiret2( EXPORTING is_return  = ls_return
                                                              CHANGING  ct_bapiret = et_bapiret ).
        
      CATCH cx_root INTO lx_error.
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD complete_technically.

    CLEAR: ev_is_error, et_bapiret.

    call_order_bapi( EXPORTING iv_function = 'BAPI_PRODORD_COMPLETE_TECH'
                               iv_aufnr    = iv_aufnr
                     CHANGING  ct_bapiret  = et_bapiret ).

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD call_order_bapi.

    DATA lt_orders TYPE STANDARD TABLE OF bapi_order_key WITH DEFAULT KEY.
    DATA lt_detail TYPE STANDARD TABLE OF bapi_order_return WITH DEFAULT KEY.
    DATA ls_return TYPE bapiret2.

    DATA temp1 LIKE lt_orders.
    DATA temp2 LIKE LINE OF temp1.
    DATA temp3 LIKE REF TO lt_detail.
DATA temp4 LIKE REF TO lt_orders.
DATA temp5 LIKE REF TO ls_return.
DATA temp6 TYPE abap_func_parmbind_tab.
DATA temp7 LIKE LINE OF temp6.
    CLEAR temp1.
    
    temp2-order_number = iv_aufnr.
    INSERT temp2 INTO TABLE temp1.
    lt_orders = temp1.
    
    GET REFERENCE OF lt_detail INTO temp3.

GET REFERENCE OF lt_orders INTO temp4.

GET REFERENCE OF ls_return INTO temp5.

CLEAR temp6.

temp7-name = 'RETURN'.
temp7-kind = abap_func_importing.
temp7-value = temp5.
INSERT temp7 INTO TABLE temp6.
temp7-name = 'ORDERS'.
temp7-kind = abap_func_tables.
temp7-value = temp4.
INSERT temp7 INTO TABLE temp6.
temp7-name = 'DETAIL_RETURN'.
temp7-kind = abap_func_tables.
temp7-value = temp3.
INSERT temp7 INTO TABLE temp6.
zabaputil_cl_bus_util_context=>bapi_call_function(
                        EXPORTING iv_name    = iv_function
                                  it_param   = temp6
                        CHANGING  ct_bapiret = ct_bapiret ).
    zabaputil_cl_bus_util_context=>bapi_msg_add_bapiret2( EXPORTING is_return  = ls_return
                                                          CHANGING  ct_bapiret = ct_bapiret ).
    zabaputil_cl_bus_util_context=>bapi_msg_add_table( EXPORTING it_table   = lt_detail
                                                       CHANGING  ct_bapiret = ct_bapiret ).

  ENDMETHOD.

ENDCLASS.
