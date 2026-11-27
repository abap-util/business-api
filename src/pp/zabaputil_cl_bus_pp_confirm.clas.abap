CLASS zabaputil_cl_bus_pp_confirm DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES ty_t_timeticket TYPE STANDARD TABLE OF bapi_pp_timeticket WITH DEFAULT KEY.
    TYPES ty_t_goodsmovement TYPE STANDARD TABLE OF bapi2017_gm_item_create WITH DEFAULT KEY.
    TYPES ty_t_link TYPE STANDARD TABLE OF bapi_link_conf_goodsmov WITH DEFAULT KEY.
    TYPES ty_t_detail_return TYPE STANDARD TABLE OF bapi_coru_return WITH DEFAULT KEY.

    "! Proposes time tickets for operations (BAPI_PRODORDCONF_GET_TT_PROP) -
    "! fill ORDERID, OPERATION and YIELD, get back the proposed values and goods movements
    CLASS-METHODS read_proposal
      IMPORTING
        it_timeticket    TYPE ty_t_timeticket
      EXPORTING
        et_timeticket    TYPE ty_t_timeticket
        et_goodsmovement TYPE ty_t_goodsmovement
        et_link          TYPE ty_t_link
        ev_is_error      TYPE abap_bool
        et_bapiret       TYPE bapirettab.

    "! Posts time ticket confirmations with their goods movements (BAPI_PRODORDCONF_CREATE_TT)
    "! @parameter et_detail_return | the BAPI's DETAIL_RETURN, one row per time ticket:
    "!                               the confirmation number and counter of each posted
    "!                               ticket (the input of cancel( )) next to its message
    CLASS-METHODS create
      IMPORTING
        it_timeticket    TYPE ty_t_timeticket
        it_goodsmovement TYPE ty_t_goodsmovement OPTIONAL
        it_link          TYPE ty_t_link OPTIONAL
        iv_commit        TYPE abap_bool DEFAULT abap_false
      EXPORTING
        et_detail_return TYPE ty_t_detail_return
        ev_is_error      TYPE abap_bool
        et_bapiret       TYPE bapirettab.

    "! Cancels a confirmation (BAPI_PRODORDCONF_CANCEL)
    CLASS-METHODS cancel
      IMPORTING
        iv_rueck    TYPE co_rueck
        iv_rmzhl    TYPE co_rmzhl
        iv_budat    TYPE budat DEFAULT sy-datum
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zabaputil_cl_bus_pp_confirm IMPLEMENTATION.

  METHOD read_proposal.

    DATA ls_return TYPE bapiret2.
    DATA lt_detail TYPE STANDARD TABLE OF bapi_coru_return WITH DEFAULT KEY.

    CLEAR: et_timeticket, et_goodsmovement, et_link, ev_is_error, et_bapiret.

    TRY.
        et_timeticket = it_timeticket.
        CALL FUNCTION 'BAPI_PRODORDCONF_GET_TT_PROP'
          IMPORTING
            return             = ls_return
          TABLES
            timetickets        = et_timeticket
            goodsmovements     = et_goodsmovement
            link_conf_goodsmov = et_link
            detail_return      = lt_detail.
        zabaputil_cl_bus_util_context=>bapi_msg_add_bapiret2( EXPORTING is_return  = ls_return
                                                              CHANGING  ct_bapiret = et_bapiret ).
        zabaputil_cl_bus_util_context=>bapi_msg_add_table( EXPORTING it_table   = lt_detail
                                                           CHANGING  ct_bapiret = et_bapiret ).
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( CHANGING ct_bapiret  = et_bapiret
                                                         cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD create.

    DATA ls_return        TYPE bapiret2.
    DATA lt_detail        TYPE ty_t_detail_return.
    DATA lt_timeticket    TYPE ty_t_timeticket.
    DATA lt_goodsmovement TYPE ty_t_goodsmovement.
    DATA lt_link          TYPE ty_t_link.

    CLEAR: et_detail_return, ev_is_error, et_bapiret.

    TRY.
        lt_timeticket    = it_timeticket.
        lt_goodsmovement = it_goodsmovement.
        lt_link          = it_link.
        CALL FUNCTION 'BAPI_PRODORDCONF_CREATE_TT'
          IMPORTING
            return             = ls_return
          TABLES
            timetickets        = lt_timeticket
            goodsmovements     = lt_goodsmovement
            link_conf_goodsmov = lt_link
            detail_return      = lt_detail.
        et_detail_return = lt_detail.
        zabaputil_cl_bus_util_context=>bapi_msg_add_bapiret2( EXPORTING is_return  = ls_return
                                                              CHANGING  ct_bapiret = et_bapiret ).
        zabaputil_cl_bus_util_context=>bapi_msg_add_table( EXPORTING it_table   = lt_detail
                                                           CHANGING  ct_bapiret = et_bapiret ).
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD cancel.

    DATA ls_return TYPE bapiret2.

    CLEAR: ev_is_error, et_bapiret.

    TRY.
        CALL FUNCTION 'BAPI_PRODORDCONF_CANCEL'
          EXPORTING
            confirmation        = iv_rueck
            confirmationcounter = iv_rmzhl
            postg_date          = iv_budat
          IMPORTING
            return              = ls_return.
        zabaputil_cl_bus_util_context=>bapi_msg_add_bapiret2( EXPORTING is_return  = ls_return
                                                              CHANGING  ct_bapiret = et_bapiret ).
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

ENDCLASS.
