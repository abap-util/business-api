CLASS zabaputil_cl_bus_sd_order DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES ty_t_partner TYPE STANDARD TABLE OF bapiparnr WITH DEFAULT KEY.
    TYPES ty_t_item TYPE STANDARD TABLE OF bapisditm WITH DEFAULT KEY.
    TYPES ty_t_itemx TYPE STANDARD TABLE OF bapisditmx WITH DEFAULT KEY.
    TYPES ty_t_schedule TYPE STANDARD TABLE OF bapischdl WITH DEFAULT KEY.
    TYPES ty_t_schedulex TYPE STANDARD TABLE OF bapischdlx WITH DEFAULT KEY.
    TYPES ty_t_vbap TYPE STANDARD TABLE OF vbap WITH DEFAULT KEY.

    "! Creates a sales order (BAPI_SALESORDER_CREATEFROMDAT2)
    "! @parameter is_header   | DOC_TYPE, SALES_ORG, DISTR_CHAN, DIVISION, PURCH_NO_C, ...
    "! @parameter it_partner  | PARTN_ROLE (AG sold-to, WE ship-to), PARTN_NUMB
    "! @parameter it_item     | ITM_NUMBER, MATERIAL, PLANT, TARGET_QTY, ...
    "! @parameter it_schedule | ITM_NUMBER, REQ_QTY, REQ_DATE
    CLASS-METHODS create
      IMPORTING
        is_header   TYPE bapisdhd1
        it_partner  TYPE ty_t_partner
        it_item     TYPE ty_t_item
        it_schedule TYPE ty_t_schedule OPTIONAL
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_vbeln    TYPE vbeln_va
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Reads header and items of a sales order
    CLASS-METHODS read
      IMPORTING
        iv_vbeln    TYPE vbeln_va
      EXPORTING
        es_vbak     TYPE vbak
        et_vbap     TYPE ty_t_vbap
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Changes a sales order (BAPI_SALESORDER_CHANGE) - header, items and
    "! schedule lines with their X structures, UPDATEFLAG I/U/D per item
    CLASS-METHODS change
      IMPORTING
        iv_vbeln     TYPE vbeln_va
        is_header    TYPE bapisdh1 OPTIONAL
        is_headerx   TYPE bapisdh1x OPTIONAL
        it_item      TYPE ty_t_item OPTIONAL
        it_itemx     TYPE ty_t_itemx OPTIONAL
        it_schedule  TYPE ty_t_schedule OPTIONAL
        it_schedulex TYPE ty_t_schedulex OPTIONAL
        iv_commit    TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error  TYPE abap_bool
        et_bapiret   TYPE bapirettab.

    "! Changes the quantity of an order item: the quantity of its first schedule line
    "! (the lowest schedule line number); further schedule lines keep their quantity
    "! @parameter iv_quantity | the new quantity, in the sales unit of the item (VBAP-VRKME)
    "! @parameter iv_vrkme    | the unit of iv_quantity; when passed, a unit other than the
    "!                          sales unit of the item is an error, as the quantity is not converted
    CLASS-METHODS change_quantity
      IMPORTING
        iv_vbeln    TYPE vbeln_va
        iv_posnr    TYPE posnr_va
        iv_quantity TYPE kwmeng
        iv_vrkme    TYPE vrkme OPTIONAL
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Deletes a sales order item
    CLASS-METHODS delete_item
      IMPORTING
        iv_vbeln    TYPE vbeln_va
        iv_posnr    TYPE posnr_va
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Deletes a whole sales order
    CLASS-METHODS delete
      IMPORTING
        iv_vbeln    TYPE vbeln_va
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zabaputil_cl_bus_sd_order IMPLEMENTATION.

  METHOD create.

    DATA lt_partner  TYPE ty_t_partner.
    DATA lt_item     TYPE ty_t_item.
    DATA lt_schedule TYPE ty_t_schedule.

    CLEAR: ev_vbeln, ev_is_error, et_bapiret.

    TRY.
        lt_partner  = it_partner.
        lt_item     = it_item.
        lt_schedule = it_schedule.
        CALL FUNCTION 'BAPI_SALESORDER_CREATEFROMDAT2'
          EXPORTING
            order_header_in    = is_header
          IMPORTING
            salesdocument      = ev_vbeln
          TABLES
            return             = et_bapiret
            order_items_in     = lt_item
            order_partners     = lt_partner
            order_schedules_in = lt_schedule.
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    IF ev_vbeln IS INITIAL AND zabaputil_cl_bus_util_context=>bapi_check_is_error( et_bapiret ) = abap_false.
      zabaputil_cl_bus_util_context=>bapi_msg_add_text( EXPORTING iv_text    = 'No sales order created'
                                                        CHANGING  ct_bapiret = et_bapiret ).
    ENDIF.
    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD read.

    CLEAR: es_vbak, et_vbap, ev_is_error, et_bapiret.

    SELECT SINGLE * FROM vbak INTO @es_vbak WHERE vbeln = @iv_vbeln.
    IF sy-subrc <> 0.
      zabaputil_cl_bus_util_context=>bapi_msg_add_text( EXPORTING iv_text    = |Sales order { iv_vbeln ALPHA = OUT } not found|
                                                        CHANGING  ct_bapiret = et_bapiret ).
    ELSE.
      SELECT * FROM vbap INTO TABLE @et_vbap WHERE vbeln = @iv_vbeln ORDER BY posnr.
    ENDIF.

    zabaputil_cl_bus_util_context=>bapi_finish( CHANGING ct_bapiret  = et_bapiret
                                                         cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD change.

    DATA ls_headerx   TYPE bapisdh1x.
    DATA lt_item      TYPE ty_t_item.
    DATA lt_itemx     TYPE ty_t_itemx.
    DATA lt_schedule  TYPE ty_t_schedule.
    DATA lt_schedulex TYPE ty_t_schedulex.

    CLEAR: ev_is_error, et_bapiret.

    TRY.
        ls_headerx = is_headerx.
        IF ls_headerx-updateflag IS INITIAL.
          ls_headerx-updateflag = 'U'.
        ENDIF.
        lt_item      = it_item.
        lt_itemx     = it_itemx.
        lt_schedule  = it_schedule.
        lt_schedulex = it_schedulex.
        CALL FUNCTION 'BAPI_SALESORDER_CHANGE'
          EXPORTING
            salesdocument    = iv_vbeln
            order_header_in  = is_header
            order_header_inx = ls_headerx
          TABLES
            return           = et_bapiret
            order_item_in    = lt_item
            order_item_inx   = lt_itemx
            schedule_lines   = lt_schedule
            schedule_linesx  = lt_schedulex.
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD change_quantity.

    DATA lt_etenr     TYPE STANDARD TABLE OF etenr WITH DEFAULT KEY.
    DATA lv_etenr     TYPE etenr.
    DATA ls_item      TYPE bapisditm.
    DATA ls_itemx     TYPE bapisditmx.
    DATA ls_schedule  TYPE bapischdl.
    DATA ls_schedulex TYPE bapischdlx.
    DATA lt_item      TYPE ty_t_item.
    DATA lt_itemx     TYPE ty_t_itemx.
    DATA lt_schedule  TYPE ty_t_schedule.
    DATA lt_schedulex TYPE ty_t_schedulex.
    DATA lv_vrkme     TYPE vrkme.

    CLEAR: ev_is_error, et_bapiret.

    IF iv_vrkme IS NOT INITIAL.
      SELECT SINGLE vrkme FROM vbap INTO @lv_vrkme WHERE vbeln = @iv_vbeln AND posnr = @iv_posnr.
      IF sy-subrc = 0 AND lv_vrkme <> iv_vrkme.
        zabaputil_cl_bus_util_context=>bapi_msg_add_text( EXPORTING iv_text    = |Unit { iv_vrkme } is not the sales unit { lv_vrkme } of item { iv_posnr ALPHA = OUT }|
                                                          CHANGING  ct_bapiret = et_bapiret ).
        zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                    CHANGING  ct_bapiret  = et_bapiret
                                                              cv_is_error = ev_is_error ).
        RETURN.
      ENDIF.
    ENDIF.

    SELECT etenr FROM vbep
      WHERE vbeln = @iv_vbeln AND posnr = @iv_posnr
      ORDER BY etenr
      INTO TABLE @lt_etenr
      UP TO 1 ROWS.
    READ TABLE lt_etenr INTO lv_etenr INDEX 1.
    IF sy-subrc <> 0.
      lv_etenr = '0001'.
    ENDIF.

    ls_item-itm_number = iv_posnr.
    INSERT ls_item INTO TABLE lt_item.
    ls_itemx-itm_number = iv_posnr.
    ls_itemx-updateflag = 'U'.
    INSERT ls_itemx INTO TABLE lt_itemx.
    ls_schedule-itm_number = iv_posnr.
    ls_schedule-sched_line = lv_etenr.
    ls_schedule-req_qty    = iv_quantity.
    INSERT ls_schedule INTO TABLE lt_schedule.
    ls_schedulex-itm_number = iv_posnr.
    ls_schedulex-sched_line = lv_etenr.
    ls_schedulex-updateflag = 'U'.
    ls_schedulex-req_qty    = abap_true.
    INSERT ls_schedulex INTO TABLE lt_schedulex.

    change( EXPORTING iv_vbeln     = iv_vbeln
                      it_item      = lt_item
                      it_itemx     = lt_itemx
                      it_schedule  = lt_schedule
                      it_schedulex = lt_schedulex
                      iv_commit    = iv_commit
            IMPORTING ev_is_error  = ev_is_error
                      et_bapiret   = et_bapiret ).

  ENDMETHOD.

  METHOD delete_item.

    DATA ls_item  TYPE bapisditm.
    DATA ls_itemx TYPE bapisditmx.
    DATA lt_item  TYPE ty_t_item.
    DATA lt_itemx TYPE ty_t_itemx.

    ls_item-itm_number = iv_posnr.
    INSERT ls_item INTO TABLE lt_item.
    ls_itemx-itm_number = iv_posnr.
    ls_itemx-updateflag = 'D'.
    INSERT ls_itemx INTO TABLE lt_itemx.

    change( EXPORTING iv_vbeln    = iv_vbeln
                      it_item     = lt_item
                      it_itemx    = lt_itemx
                      iv_commit   = iv_commit
            IMPORTING ev_is_error = ev_is_error
                      et_bapiret  = et_bapiret ).

  ENDMETHOD.

  METHOD delete.

    DATA ls_headerx TYPE bapisdh1x.

    ls_headerx-updateflag = 'D'.
    change( EXPORTING iv_vbeln    = iv_vbeln
                      is_headerx  = ls_headerx
                      iv_commit   = iv_commit
            IMPORTING ev_is_error = ev_is_error
                      et_bapiret  = et_bapiret ).

  ENDMETHOD.

ENDCLASS.
