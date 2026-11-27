CLASS zabaputil_cl_bus_sd_shipment DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES ty_t_vttp TYPE STANDARD TABLE OF vttp WITH DEFAULT KEY.
    TYPES ty_t_vbeln TYPE STANDARD TABLE OF vbeln_vl WITH DEFAULT KEY.

    CONSTANTS:
      "! the status values of set_status( ) - the BAPISHIPMENTHEADER fields
      BEGIN OF cs_status,
        planned        TYPE string VALUE 'STATUS_PLAN',
        checked_in     TYPE string VALUE 'STATUS_CHECKIN',
        loading_start  TYPE string VALUE 'STATUS_LOAD_START',
        loading_end    TYPE string VALUE 'STATUS_LOAD_END',
        completed      TYPE string VALUE 'STATUS_COMPL',
        shipment_start TYPE string VALUE 'STATUS_SHPMNT_START',
        shipment_end   TYPE string VALUE 'STATUS_SHPMNT_END',
      END OF cs_status.

    "! Creates a shipment for deliveries (BAPI_SHIPMENT_CREATE)
    CLASS-METHODS create
      IMPORTING
        iv_shtyp    TYPE shtyp
        iv_tplst    TYPE tplst
        it_vbeln    TYPE ty_t_vbeln
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_tknum    TYPE tknum
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Reads header and items of a shipment
    CLASS-METHODS read
      IMPORTING
        iv_tknum    TYPE tknum
      EXPORTING
        es_vttk     TYPE vttk
        et_vttp     TYPE ty_t_vttp
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Sets a status of a shipment, one of cs_status (BAPI_SHIPMENT_CHANGE)
    CLASS-METHODS set_status
      IMPORTING
        iv_tknum    TYPE tknum
        iv_status   TYPE clike
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Adds deliveries to a shipment (BAPI_SHIPMENT_CHANGE)
    CLASS-METHODS add_deliveries
      IMPORTING
        iv_tknum    TYPE tknum
        it_vbeln    TYPE ty_t_vbeln
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Removes deliveries from a shipment (BAPI_SHIPMENT_CHANGE)
    CLASS-METHODS remove_deliveries
      IMPORTING
        iv_tknum    TYPE tknum
        it_vbeln    TYPE ty_t_vbeln
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Changes the forwarding agent of a shipment (BAPI_SHIPMENT_CHANGE)
    CLASS-METHODS change_carrier
      IMPORTING
        iv_tknum    TYPE tknum
        iv_tdlnr    TYPE tdlnr
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

  PROTECTED SECTION.
  PRIVATE SECTION.

    TYPES ty_t_item TYPE STANDARD TABLE OF bapishipmentitem WITH DEFAULT KEY.
    TYPES ty_t_item_action TYPE STANDARD TABLE OF bapishipmentitemaction WITH DEFAULT KEY.

    CLASS-METHODS call_change
      IMPORTING
        is_header        TYPE bapishipmentheader
        is_header_action TYPE bapishipmentheaderaction
        it_item          TYPE ty_t_item OPTIONAL
        it_item_action   TYPE ty_t_item_action OPTIONAL
      CHANGING
        ct_bapiret       TYPE bapirettab.

    CLASS-METHODS change_items
      IMPORTING
        iv_tknum    TYPE tknum
        it_vbeln    TYPE ty_t_vbeln
        iv_action   TYPE clike
        iv_commit   TYPE abap_bool
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

ENDCLASS.



CLASS zabaputil_cl_bus_sd_shipment IMPLEMENTATION.

  METHOD create.

    DATA ls_header TYPE bapishipmentheader.
    DATA lt_item   TYPE ty_t_item.
    DATA lv_vbeln  TYPE vbeln_vl.
          DATA temp1 LIKE LINE OF lt_item.
        DATA lx_error TYPE REF TO cx_root.

    CLEAR: ev_tknum, ev_is_error, et_bapiret.

    TRY.
        ls_header-shipment_type   = iv_shtyp.
        ls_header-trans_plan_pt   = iv_tplst.
        LOOP AT it_vbeln INTO lv_vbeln.
          
          CLEAR temp1.
          temp1-delivery = lv_vbeln.
          temp1-itenerary = sy-tabix.
          INSERT temp1 INTO TABLE lt_item.
        ENDLOOP.
        CALL FUNCTION 'BAPI_SHIPMENT_CREATE'
          EXPORTING
            headerdata = ls_header
          IMPORTING
            transport  = ev_tknum
          TABLES
            itemdata   = lt_item
            return     = et_bapiret.
        
      CATCH cx_root INTO lx_error.
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    IF ev_tknum IS INITIAL AND zabaputil_cl_bus_util_context=>bapi_check_is_error( et_bapiret ) = abap_false.
      zabaputil_cl_bus_util_context=>bapi_msg_add_text( EXPORTING iv_text    = 'No shipment created'
                                                        CHANGING  ct_bapiret = et_bapiret ).
    ENDIF.
    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD read.
      DATA temp2 TYPE string.

    CLEAR: es_vttk, et_vttp, ev_is_error, et_bapiret.

    SELECT SINGLE * FROM vttk INTO es_vttk WHERE tknum = iv_tknum.
    IF sy-subrc <> 0.
      
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
        EXPORTING
          input  = iv_tknum
        IMPORTING
          output = temp2.
zabaputil_cl_bus_util_context=>bapi_msg_add_text( EXPORTING iv_text    = |Shipment { temp2 } not found|
                                                        CHANGING  ct_bapiret = et_bapiret ).
    ELSE.
      SELECT * FROM vttp INTO TABLE et_vttp WHERE tknum = iv_tknum ORDER BY tpnum.
    ENDIF.

    zabaputil_cl_bus_util_context=>bapi_finish( CHANGING ct_bapiret  = et_bapiret
                                                         cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD set_status.

    DATA ls_header TYPE bapishipmentheader.
    DATA ls_action TYPE bapishipmentheaderaction.
    DATA lv_field  TYPE string.
    FIELD-SYMBOLS <value>  TYPE any.
    FIELD-SYMBOLS <action> TYPE any.
        DATA lx_error TYPE REF TO cx_root.

    CLEAR: ev_is_error, et_bapiret.

    TRY.
        ls_header-shipment_num = iv_tknum.
        lv_field = to_upper( iv_status ).
        ASSIGN COMPONENT lv_field OF STRUCTURE ls_header TO <value>.
        ASSIGN COMPONENT lv_field OF STRUCTURE ls_action TO <action>.
        IF <value> IS NOT ASSIGNED OR <action> IS NOT ASSIGNED.
          zabaputil_cl_bus_util_context=>bapi_msg_add_text( EXPORTING iv_text    = |Unknown shipment status { lv_field }|
                                                            CHANGING  ct_bapiret = et_bapiret ).
        ELSE.
          <value>  = abap_true.
          <action> = 'C'.
          call_change( EXPORTING is_header        = ls_header
                                 is_header_action = ls_action
                       CHANGING  ct_bapiret       = et_bapiret ).
        ENDIF.
        
      CATCH cx_root INTO lx_error.
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD add_deliveries.

    change_items( EXPORTING iv_tknum    = iv_tknum
                            it_vbeln    = it_vbeln
                            iv_action   = 'A'
                            iv_commit   = iv_commit
                  IMPORTING ev_is_error = ev_is_error
                            et_bapiret  = et_bapiret ).

  ENDMETHOD.

  METHOD remove_deliveries.

    change_items( EXPORTING iv_tknum    = iv_tknum
                            it_vbeln    = it_vbeln
                            iv_action   = 'D'
                            iv_commit   = iv_commit
                  IMPORTING ev_is_error = ev_is_error
                            et_bapiret  = et_bapiret ).

  ENDMETHOD.

  METHOD change_carrier.

    DATA ls_header TYPE bapishipmentheader.
    DATA ls_action TYPE bapishipmentheaderaction.
        DATA lx_error TYPE REF TO cx_root.

    CLEAR: ev_is_error, et_bapiret.

    TRY.
        ls_header-shipment_num   = iv_tknum.
        ls_header-service_agent_id = iv_tdlnr.
        ls_action-service_agent_id = 'C'.
        call_change( EXPORTING is_header        = ls_header
                               is_header_action = ls_action
                     CHANGING  ct_bapiret       = et_bapiret ).
        
      CATCH cx_root INTO lx_error.
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD change_items.

    DATA ls_header      TYPE bapishipmentheader.
    DATA ls_action      TYPE bapishipmentheaderaction.
    DATA lt_item        TYPE ty_t_item.
    DATA lt_item_action TYPE ty_t_item_action.
    DATA lv_vbeln       TYPE vbeln_vl.
          DATA temp3 LIKE LINE OF lt_item.
          DATA temp4 LIKE LINE OF lt_item_action.
        DATA lx_error TYPE REF TO cx_root.

    CLEAR: ev_is_error, et_bapiret.

    TRY.
        ls_header-shipment_num = iv_tknum.
        LOOP AT it_vbeln INTO lv_vbeln.
          
          CLEAR temp3.
          temp3-delivery = lv_vbeln.
          temp3-itenerary = sy-tabix.
          INSERT temp3 INTO TABLE lt_item.
          
          CLEAR temp4.
          temp4-delivery = iv_action.
          temp4-itenerary = iv_action.
          INSERT temp4 INTO TABLE lt_item_action.
        ENDLOOP.
        call_change( EXPORTING is_header        = ls_header
                               is_header_action = ls_action
                               it_item          = lt_item
                               it_item_action   = lt_item_action
                     CHANGING  ct_bapiret       = et_bapiret ).
        
      CATCH cx_root INTO lx_error.
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD call_change.

    DATA lt_item        TYPE ty_t_item.
    DATA lt_item_action TYPE ty_t_item_action.
    DATA lt_return      TYPE bapirettab.

    lt_item        = it_item.
    lt_item_action = it_item_action.
    CALL FUNCTION 'BAPI_SHIPMENT_CHANGE'
      EXPORTING
        headerdata       = is_header
        headerdataaction = is_header_action
      TABLES
        itemdata         = lt_item
        itemdataaction   = lt_item_action
        return           = lt_return.
    INSERT LINES OF lt_return INTO TABLE ct_bapiret.

  ENDMETHOD.

ENDCLASS.
