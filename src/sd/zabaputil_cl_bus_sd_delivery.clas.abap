"! Outbound deliveries. The write methods reset the delivery, HU and serial
"! number buffers before they post only with iv_commit = abap_true: with
"! abap_false the caller owns the LUW, and the buffers hold what its earlier
"! calls posted.
CLASS zabaputil_cl_bus_sd_delivery DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES ty_t_lips TYPE STANDARD TABLE OF lips WITH DEFAULT KEY.
    TYPES ty_t_order_item TYPE STANDARD TABLE OF bapidlvreftosalesorder WITH DEFAULT KEY.
    TYPES ty_t_vbeln TYPE STANDARD TABLE OF vbeln_vl WITH DEFAULT KEY.

    "! Creates outbound deliveries for sales order items (BAPI_OUTB_DELIVERY_CREATE_SLS).
    "! The BAPI splits the items into several deliveries where they differ in a split
    "! criterion (shipping point, ship-to party, route, ...): ev_vbeln is the first,
    "! et_vbeln has all of them, and iv_commit = abap_true commits all of them.
    "! @parameter iv_ship_point     | shipping point, initial: determined by the system
    "! @parameter iv_due_date       | selection date, default today
    "! @parameter it_item           | order items: REF_DOC, REF_ITEM, DLV_QTY, SALES_UNIT
    "! @parameter ev_vbeln          | the (first) delivery created
    "! @parameter et_vbeln          | every delivery created - from the BAPI's DELIVERIES
    "! @parameter er_created_items  | the BAPI's CREATED_ITEMS (a table typed at runtime):
    "!                                which order item went into which delivery item -
    "!                                an order item missing from it was not delivered.
    "!                                Unbound where the system's BAPI has no such table
    CLASS-METHODS create_from_order
      IMPORTING
        iv_ship_point    TYPE vstel OPTIONAL
        iv_due_date      TYPE ledat DEFAULT sy-datum
        it_item          TYPE ty_t_order_item
        iv_commit        TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_vbeln         TYPE vbeln_vl
        et_vbeln         TYPE ty_t_vbeln
        er_created_items TYPE REF TO data
        ev_is_error      TYPE abap_bool
        et_bapiret       TYPE bapirettab.

    "! Reads header and items of a delivery
    CLASS-METHODS read
      IMPORTING
        iv_vbeln    TYPE vbeln_vl
      EXPORTING
        es_likp     TYPE likp
        et_lips     TYPE ty_t_lips
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Changes the delivery quantity of an item (BAPI_OUTB_DELIVERY_CHANGE)
    "! @parameter iv_lfimg | the new quantity, in the sales unit of the item (LIPS-VRKME)
    "! @parameter iv_vrkme | the unit of iv_lfimg; a unit other than the sales unit of the
    "!                       item is an error, as the quantity is not converted - the base
    "!                       quantity is computed with the item's own conversion factors
    CLASS-METHODS change_quantity
      IMPORTING
        iv_vbeln    TYPE vbeln_vl
        iv_posnr    TYPE posnr_vl
        iv_lfimg    TYPE lfimg
        iv_vrkme    TYPE vrkme
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Posts the goods issue of a delivery (BAPI_OUTB_DELIVERY_CONFIRM_DEC)
    CLASS-METHODS post_goods_issue
      IMPORTING
        iv_vbeln    TYPE vbeln_vl
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Reverses the goods issue of a delivery (WS_REVERSE_GOODS_ISSUE, as VL09)
    CLASS-METHODS reverse_goods_issue
      IMPORTING
        iv_vbeln    TYPE vbeln_vl
        iv_budat    TYPE budat DEFAULT sy-datum
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Deletes a delivery item (BAPI_OUTB_DELIVERY_CHANGE)
    CLASS-METHODS delete_item
      IMPORTING
        iv_vbeln    TYPE vbeln_vl
        iv_posnr    TYPE posnr_vl
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Deletes a whole delivery (BAPI_OUTB_DELIVERY_CHANGE)
    CLASS-METHODS delete
      IMPORTING
        iv_vbeln    TYPE vbeln_vl
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

  PROTECTED SECTION.
  PRIVATE SECTION.

    TYPES ty_t_item_chg TYPE STANDARD TABLE OF bapiobdlvitemchg WITH DEFAULT KEY.
    TYPES ty_t_item_ctrl TYPE STANDARD TABLE OF bapiobdlvitemctrlchg WITH DEFAULT KEY.

    "! @parameter iv_refresh | reset the delivery buffers first - only where the caller commits per call
    CLASS-METHODS call_change
      IMPORTING
        iv_vbeln       TYPE vbeln_vl
        iv_refresh     TYPE abap_bool
        iv_delete      TYPE abap_bool DEFAULT abap_false
        it_item_data   TYPE ty_t_item_chg OPTIONAL
        it_item_ctrl   TYPE ty_t_item_ctrl OPTIONAL
      CHANGING
        ct_bapiret     TYPE bapirettab.

ENDCLASS.



CLASS zabaputil_cl_bus_sd_delivery IMPLEMENTATION.

  METHOD create_from_order.

    DATA lt_item       TYPE ty_t_order_item.
    DATA lt_param      TYPE abap_func_parmbind_tab.
    DATA ls_param      TYPE abap_func_parmbind.
    DATA lr_deliveries TYPE REF TO data.
    DATA lr_created    TYPE REF TO data.
    DATA lv_ship_point TYPE vstel.
    DATA lv_due_date   TYPE ledat.
    DATA lv_vbeln      TYPE vbeln_vl.
    FIELD-SYMBOLS <deliveries> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <row>        TYPE any.
    FIELD-SYMBOLS <field>      TYPE any.

    CLEAR: ev_vbeln, et_vbeln, er_created_items, ev_is_error, et_bapiret.

    TRY.
        IF iv_commit = abap_true.
          zabaputil_cl_bus_util_context=>bapi_refresh_buffers( 'DELIVERY' ).
        ENDIF.
        lt_item       = it_item.
        lv_ship_point = iv_ship_point.
        lv_due_date   = iv_due_date.

        ls_param-kind = abap_func_exporting.
        ls_param-name = 'SHIP_POINT'.
        GET REFERENCE OF lv_ship_point INTO ls_param-value.
        INSERT ls_param INTO TABLE lt_param.
        ls_param-name = 'DUE_DATE'.
        GET REFERENCE OF lv_due_date INTO ls_param-value.
        INSERT ls_param INTO TABLE lt_param.
        ls_param-kind = abap_func_importing.
        ls_param-name = 'DELIVERY'.
        GET REFERENCE OF ev_vbeln INTO ls_param-value.
        INSERT ls_param INTO TABLE lt_param.
        ls_param-kind = abap_func_tables.
        ls_param-name = 'SALES_ORDER_ITEMS'.
        GET REFERENCE OF lt_item INTO ls_param-value.
        INSERT ls_param INTO TABLE lt_param.
        ls_param-name = 'RETURN'.
        GET REFERENCE OF et_bapiret INTO ls_param-value.
        INSERT ls_param INTO TABLE lt_param.

        " DELIVERIES and CREATED_ITEMS list every delivery and item created.
        " Neither they nor their row types are verified on a system: the
        " tables are created by name, and a call the module refuses for them
        " (a parameter or type it does not have - raised before it runs) is
        " made again without them
        TRY.
            CREATE DATA lr_deliveries TYPE STANDARD TABLE OF ('BAPISHPDELIVNUMB').
            CREATE DATA lr_created TYPE STANDARD TABLE OF ('BAPIDLVITEMCREATED').
            ls_param-name  = 'DELIVERIES'.
            ls_param-value = lr_deliveries.
            INSERT ls_param INTO TABLE lt_param.
            ls_param-name  = 'CREATED_ITEMS'.
            ls_param-value = lr_created.
            INSERT ls_param INTO TABLE lt_param.
          CATCH cx_sy_create_data_error.
            CLEAR: lr_deliveries, lr_created.
        ENDTRY.

        TRY.
            CALL FUNCTION 'BAPI_OUTB_DELIVERY_CREATE_SLS'
              PARAMETER-TABLE lt_param.
          CATCH cx_sy_dyn_call_param_not_found cx_sy_dyn_call_illegal_type INTO DATA(lx_call).
            IF lr_deliveries IS BOUND.
              DELETE lt_param WHERE name = 'DELIVERIES' OR name = 'CREATED_ITEMS'.
              CLEAR: lr_deliveries, lr_created.
              CALL FUNCTION 'BAPI_OUTB_DELIVERY_CREATE_SLS'
                PARAMETER-TABLE lt_param.
            ELSE.
              zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_call
                                                                     CHANGING  ct_bapiret = et_bapiret ).
            ENDIF.
        ENDTRY.

        IF ev_vbeln IS NOT INITIAL.
          INSERT ev_vbeln INTO TABLE et_vbeln.
        ENDIF.
        IF lr_deliveries IS BOUND.
          ASSIGN lr_deliveries->* TO <deliveries>.
          LOOP AT <deliveries> ASSIGNING <row>.
            ASSIGN COMPONENT 'DELIV_NUMB' OF STRUCTURE <row> TO <field>.
            IF sy-subrc = 0 AND <field> IS NOT INITIAL.
              lv_vbeln = <field>.
              IF NOT line_exists( et_vbeln[ table_line = lv_vbeln ] ).
                INSERT lv_vbeln INTO TABLE et_vbeln.
              ENDIF.
            ENDIF.
          ENDLOOP.
          er_created_items = lr_created.
        ENDIF.
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    IF ev_vbeln IS INITIAL AND zabaputil_cl_bus_util_context=>bapi_check_is_error( et_bapiret ) = abap_false.
      zabaputil_cl_bus_util_context=>bapi_msg_add_text( EXPORTING iv_text    = 'No delivery created'
                                                        CHANGING  ct_bapiret = et_bapiret ).
    ENDIF.
    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD read.

    CLEAR: es_likp, et_lips, ev_is_error, et_bapiret.

    SELECT SINGLE * FROM likp INTO @es_likp WHERE vbeln = @iv_vbeln.
    IF sy-subrc <> 0.
      zabaputil_cl_bus_util_context=>bapi_msg_add_text( EXPORTING iv_text    = |Delivery { iv_vbeln ALPHA = OUT } not found|
                                                        CHANGING  ct_bapiret = et_bapiret ).
    ELSE.
      SELECT * FROM lips INTO TABLE @et_lips WHERE vbeln = @iv_vbeln ORDER BY posnr.
    ENDIF.

    zabaputil_cl_bus_util_context=>bapi_finish( CHANGING ct_bapiret  = et_bapiret
                                                         cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD change_quantity.

    DATA lt_item_data TYPE ty_t_item_chg.
    DATA lt_item_ctrl TYPE ty_t_item_ctrl.
    DATA ls_lips      TYPE lips.

    CLEAR: ev_is_error, et_bapiret.

    TRY.
        SELECT SINGLE * FROM lips INTO @ls_lips WHERE vbeln = @iv_vbeln AND posnr = @iv_posnr.
        IF sy-subrc <> 0.
          zabaputil_cl_bus_util_context=>bapi_msg_add_text( EXPORTING iv_text    = |Delivery item { iv_vbeln ALPHA = OUT }/{ iv_posnr ALPHA = OUT } not found|
                                                            CHANGING  ct_bapiret = et_bapiret ).
        ELSEIF iv_vrkme IS NOT INITIAL AND iv_vrkme <> ls_lips-vrkme.
          " UMVKZ/UMVKN convert the item's sales unit to the base unit - a
          " quantity in another unit would be posted wrong by the ratio of the
          " two units
          zabaputil_cl_bus_util_context=>bapi_msg_add_text( EXPORTING iv_text    = |Unit { iv_vrkme } is not the sales unit { ls_lips-vrkme } of delivery item { iv_posnr ALPHA = OUT }|
                                                            CHANGING  ct_bapiret = et_bapiret ).
        ELSE.
          lt_item_data = VALUE #( ( deliv_numb      = iv_vbeln
                                    deliv_item      = iv_posnr
                                    dlv_qty         = iv_lfimg
                                    dlv_qty_imunit  = COND #( WHEN ls_lips-umvkn = 0 THEN iv_lfimg
                                                              ELSE iv_lfimg * ls_lips-umvkz / ls_lips-umvkn )
                                    sales_unit      = iv_vrkme
                                    base_uom        = ls_lips-meins
                                    fact_unit_nom   = ls_lips-umvkz
                                    fact_unit_denom = ls_lips-umvkn ) ).
          lt_item_ctrl = VALUE #( ( deliv_numb = iv_vbeln
                                    deliv_item = iv_posnr
                                    chg_delqty = abap_true ) ).
          call_change( EXPORTING iv_vbeln     = iv_vbeln
                                 iv_refresh   = iv_commit
                                 it_item_data = lt_item_data
                                 it_item_ctrl = lt_item_ctrl
                       CHANGING  ct_bapiret   = et_bapiret ).
        ENDIF.
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD post_goods_issue.

    DATA ls_header  TYPE bapiobdlvhdrcon.
    DATA ls_control TYPE bapiobdlvhdrctrlcon.

    CLEAR: ev_is_error, et_bapiret.

    TRY.
        IF iv_commit = abap_true.
          zabaputil_cl_bus_util_context=>bapi_refresh_buffers( 'DELIVERY' ).
        ENDIF.
        ls_header-deliv_numb   = iv_vbeln.
        ls_control-deliv_numb  = iv_vbeln.
        ls_control-post_gi_flg = abap_true.
        CALL FUNCTION 'BAPI_OUTB_DELIVERY_CONFIRM_DEC'
          EXPORTING
            header_data    = ls_header
            header_control = ls_control
            delivery       = iv_vbeln
          TABLES
            return         = et_bapiret.
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD reverse_goods_issue.

    DATA lt_mesg  TYPE STANDARD TABLE OF mesg WITH DEFAULT KEY.
    DATA ls_likp  TYPE likp.

    CLEAR: ev_is_error, et_bapiret.

    TRY.
        SELECT SINGLE * FROM likp INTO @ls_likp WHERE vbeln = @iv_vbeln.
        IF sy-subrc <> 0.
          zabaputil_cl_bus_util_context=>bapi_msg_add_text( EXPORTING iv_text    = |Delivery { iv_vbeln ALPHA = OUT } not found|
                                                            CHANGING  ct_bapiret = et_bapiret ).
        ELSE.
          IF iv_commit = abap_true.
            zabaputil_cl_bus_util_context=>bapi_refresh_buffers( 'DELIVERY' ).
          ENDIF.
          " a plain RAISE in the module would leave an older message in sy-msg
          CLEAR: sy-msgid, sy-msgno.
          CALL FUNCTION 'WS_REVERSE_GOODS_ISSUE'
            EXPORTING
              i_vbeln                   = iv_vbeln
              i_budat                   = iv_budat
              i_tcode                   = 'VL09'
              i_vbtyp                   = ls_likp-vbtyp
            TABLES
              t_mesg                    = lt_mesg
            EXCEPTIONS
              error_message = 1
              OTHERS        = 2.
          IF sy-subrc <> 0.
            zabaputil_cl_bus_util_context=>bapi_msg_add_sy( EXPORTING iv_context = 'WS_REVERSE_GOODS_ISSUE'
                                                            CHANGING  ct_bapiret = et_bapiret ).
          ENDIF.
          zabaputil_cl_bus_util_context=>bapi_msg_add_table( EXPORTING it_table   = lt_mesg
                                                             CHANGING  ct_bapiret = et_bapiret ).
        ENDIF.
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD delete_item.

    DATA lt_item_data TYPE ty_t_item_chg.
    DATA lt_item_ctrl TYPE ty_t_item_ctrl.

    CLEAR: ev_is_error, et_bapiret.

    TRY.
        lt_item_data = VALUE #( ( deliv_numb = iv_vbeln
                                  deliv_item = iv_posnr ) ).
        lt_item_ctrl = VALUE #( ( deliv_numb = iv_vbeln
                                  deliv_item = iv_posnr
                                  del_item   = abap_true ) ).
        call_change( EXPORTING iv_vbeln     = iv_vbeln
                               iv_refresh   = iv_commit
                               it_item_data = lt_item_data
                               it_item_ctrl = lt_item_ctrl
                     CHANGING  ct_bapiret   = et_bapiret ).
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD delete.

    CLEAR: ev_is_error, et_bapiret.

    TRY.
        call_change( EXPORTING iv_vbeln   = iv_vbeln
                               iv_refresh = iv_commit
                               iv_delete  = abap_true
                     CHANGING  ct_bapiret = et_bapiret ).
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD call_change.

    DATA ls_header    TYPE bapiobdlvhdrchg.
    DATA ls_control   TYPE bapiobdlvhdrctrlchg.
    DATA lt_item_data TYPE ty_t_item_chg.
    DATA lt_item_ctrl TYPE ty_t_item_ctrl.
    DATA lt_return    TYPE bapirettab.

    IF iv_refresh = abap_true.
      zabaputil_cl_bus_util_context=>bapi_refresh_buffers( 'DELIVERY' ).
    ENDIF.
    ls_header-deliv_numb  = iv_vbeln.
    ls_control-deliv_numb = iv_vbeln.
    ls_control-dlv_del    = iv_delete.
    lt_item_data = it_item_data.
    lt_item_ctrl = it_item_ctrl.

    CALL FUNCTION 'BAPI_OUTB_DELIVERY_CHANGE'
      EXPORTING
        header_data    = ls_header
        header_control = ls_control
        delivery       = iv_vbeln
      TABLES
        item_data      = lt_item_data
        item_control   = lt_item_ctrl
        return         = lt_return.
    INSERT LINES OF lt_return INTO TABLE ct_bapiret.

  ENDMETHOD.

ENDCLASS.
