CLASS zabaputil_cl_bus_mm_goodsmvt DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES ty_t_item TYPE STANDARD TABLE OF bapi2017_gm_item_create WITH DEFAULT KEY.

    CONSTANTS:
      "! GM_CODE of BAPI_GOODSMVT_CREATE
      BEGIN OF cs_code,
        goods_receipt_po    TYPE c LENGTH 2 VALUE '01',
        goods_receipt_order TYPE c LENGTH 2 VALUE '02',
        goods_issue         TYPE c LENGTH 2 VALUE '03',
        transfer_posting    TYPE c LENGTH 2 VALUE '04',
        other_receipts      TYPE c LENGTH 2 VALUE '05',
        reversal            TYPE c LENGTH 2 VALUE '06',
      END OF cs_code.

    "! Posts any goods movement (BAPI_GOODSMVT_CREATE)
    "! @parameter iv_code   | one of cs_code
    "! @parameter is_header | PSTNG_DATE, DOC_DATE, HEADER_TXT, REF_DOC_NO
    "! @parameter it_item   | the items: MATERIAL, PLANT, STGE_LOC, MOVE_TYPE, ENTRY_QNT, ...
    CLASS-METHODS create
      IMPORTING
        iv_code     TYPE clike
        is_header   TYPE bapi2017_gm_head_01 OPTIONAL
        it_item     TYPE ty_t_item
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_mblnr    TYPE mblnr
        ev_mjahr    TYPE mjahr
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Transfer posting from storage location to storage location (311)
    CLASS-METHODS transfer_storage_location
      IMPORTING
        iv_matnr      TYPE matnr
        iv_werks      TYPE werks_d
        iv_lgort_from TYPE lgort_d
        iv_lgort_to   TYPE lgort_d
        iv_menge      TYPE erfmg
        iv_meins      TYPE erfme
        iv_charg      TYPE charg_d OPTIONAL
        iv_commit     TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_mblnr      TYPE mblnr
        ev_mjahr      TYPE mjahr
        ev_is_error   TYPE abap_bool
        et_bapiret    TYPE bapirettab.

    "! Transfer posting from plant to plant (301)
    CLASS-METHODS transfer_plant
      IMPORTING
        iv_matnr      TYPE matnr
        iv_werks_from TYPE werks_d
        iv_lgort_from TYPE lgort_d
        iv_werks_to   TYPE werks_d
        iv_lgort_to   TYPE lgort_d
        iv_menge      TYPE erfmg
        iv_meins      TYPE erfme
        iv_charg      TYPE charg_d OPTIONAL
        iv_commit     TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_mblnr      TYPE mblnr
        ev_mjahr      TYPE mjahr
        ev_is_error   TYPE abap_bool
        et_bapiret    TYPE bapirettab.

    "! Transfer posting between stock types in one storage location:
    "! 321 quality to unrestricted, 322 back, 343 blocked to unrestricted, 344 back
    CLASS-METHODS transfer_stock_type
      IMPORTING
        iv_bwart    TYPE bwart
        iv_matnr    TYPE matnr
        iv_werks    TYPE werks_d
        iv_lgort    TYPE lgort_d
        iv_menge    TYPE erfmg
        iv_meins    TYPE erfme
        iv_charg    TYPE charg_d OPTIONAL
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_mblnr    TYPE mblnr
        ev_mjahr    TYPE mjahr
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Goods issue for a production or maintenance order (261)
    CLASS-METHODS goods_issue_order
      IMPORTING
        iv_aufnr    TYPE aufnr
        iv_matnr    TYPE matnr
        iv_werks    TYPE werks_d
        iv_lgort    TYPE lgort_d
        iv_menge    TYPE erfmg
        iv_meins    TYPE erfme
        iv_charg    TYPE charg_d OPTIONAL
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_mblnr    TYPE mblnr
        ev_mjahr    TYPE mjahr
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Goods issue for a reservation item (movement type of the reservation)
    CLASS-METHODS goods_issue_reservation
      IMPORTING
        iv_rsnum    TYPE rsnum
        iv_rspos    TYPE rspos
        iv_menge    TYPE erfmg
        iv_lgort    TYPE lgort_d OPTIONAL
        iv_charg    TYPE charg_d OPTIONAL
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_mblnr    TYPE mblnr
        ev_mjahr    TYPE mjahr
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Goods receipt without reference (561, initial entry of stock)
    CLASS-METHODS goods_receipt_initial
      IMPORTING
        iv_matnr    TYPE matnr
        iv_werks    TYPE werks_d
        iv_lgort    TYPE lgort_d
        iv_menge    TYPE erfmg
        iv_meins    TYPE erfme
        iv_charg    TYPE charg_d OPTIONAL
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_mblnr    TYPE mblnr
        ev_mjahr    TYPE mjahr
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Cancels a material document (BAPI_GOODSMVT_CANCEL)
    CLASS-METHODS cancel
      IMPORTING
        iv_mblnr        TYPE mblnr
        iv_mjahr        TYPE mjahr
        iv_budat        TYPE budat DEFAULT sy-datum
        iv_commit       TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_mblnr_cancel TYPE mblnr
        ev_mjahr_cancel TYPE mjahr
        ev_is_error     TYPE abap_bool
        et_bapiret      TYPE bapirettab.

  PROTECTED SECTION.
  PRIVATE SECTION.

    CLASS-METHODS item
      IMPORTING
        iv_bwart         TYPE bwart
        iv_matnr         TYPE matnr OPTIONAL
        iv_werks         TYPE werks_d OPTIONAL
        iv_lgort         TYPE lgort_d OPTIONAL
        iv_charg         TYPE charg_d OPTIONAL
        iv_menge         TYPE erfmg
        iv_meins         TYPE erfme OPTIONAL
      RETURNING
        VALUE(rs_result) TYPE bapi2017_gm_item_create.

ENDCLASS.



CLASS zabaputil_cl_bus_mm_goodsmvt IMPLEMENTATION.

  METHOD create.

    DATA ls_header TYPE bapi2017_gm_head_01.
    DATA ls_code   TYPE bapi2017_gm_code.
    DATA lt_item   TYPE ty_t_item.

    CLEAR: ev_mblnr, ev_mjahr, ev_is_error, et_bapiret.

    TRY.
        ls_header = is_header.
        IF ls_header-pstng_date IS INITIAL.
          ls_header-pstng_date = sy-datum.
        ENDIF.
        IF ls_header-doc_date IS INITIAL.
          ls_header-doc_date = sy-datum.
        ENDIF.
        ls_code-gm_code = iv_code.
        lt_item = it_item.
        CALL FUNCTION 'BAPI_GOODSMVT_CREATE'
          EXPORTING
            goodsmvt_header  = ls_header
            goodsmvt_code    = ls_code
          IMPORTING
            materialdocument = ev_mblnr
            matdocumentyear  = ev_mjahr
          TABLES
            goodsmvt_item    = lt_item
            return           = et_bapiret.
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus=>msg_add_exception( EXPORTING ix_error   = lx_error
                                             CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus=>finish( EXPORTING iv_commit   = iv_commit
                              CHANGING  ct_bapiret  = et_bapiret
                                        cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD transfer_storage_location.

    DATA(ls_item) = item( iv_bwart = '311'
                          iv_matnr = iv_matnr
                          iv_werks = iv_werks
                          iv_lgort = iv_lgort_from
                          iv_charg = iv_charg
                          iv_menge = iv_menge
                          iv_meins = iv_meins ).
    ls_item-move_stloc = iv_lgort_to.

    create( EXPORTING iv_code     = cs_code-transfer_posting
                      it_item     = VALUE #( ( ls_item ) )
                      iv_commit   = iv_commit
            IMPORTING ev_mblnr    = ev_mblnr
                      ev_mjahr    = ev_mjahr
                      ev_is_error = ev_is_error
                      et_bapiret  = et_bapiret ).

  ENDMETHOD.

  METHOD transfer_plant.

    DATA(ls_item) = item( iv_bwart = '301'
                          iv_matnr = iv_matnr
                          iv_werks = iv_werks_from
                          iv_lgort = iv_lgort_from
                          iv_charg = iv_charg
                          iv_menge = iv_menge
                          iv_meins = iv_meins ).
    ls_item-move_plant = iv_werks_to.
    ls_item-move_stloc = iv_lgort_to.
    ls_item-move_batch = iv_charg.

    create( EXPORTING iv_code     = cs_code-transfer_posting
                      it_item     = VALUE #( ( ls_item ) )
                      iv_commit   = iv_commit
            IMPORTING ev_mblnr    = ev_mblnr
                      ev_mjahr    = ev_mjahr
                      ev_is_error = ev_is_error
                      et_bapiret  = et_bapiret ).

  ENDMETHOD.

  METHOD transfer_stock_type.

    create( EXPORTING iv_code     = cs_code-transfer_posting
                      it_item     = VALUE #( ( item( iv_bwart = iv_bwart
                                                     iv_matnr = iv_matnr
                                                     iv_werks = iv_werks
                                                     iv_lgort = iv_lgort
                                                     iv_charg = iv_charg
                                                     iv_menge = iv_menge
                                                     iv_meins = iv_meins ) ) )
                      iv_commit   = iv_commit
            IMPORTING ev_mblnr    = ev_mblnr
                      ev_mjahr    = ev_mjahr
                      ev_is_error = ev_is_error
                      et_bapiret  = et_bapiret ).

  ENDMETHOD.

  METHOD goods_issue_order.

    DATA(ls_item) = item( iv_bwart = '261'
                          iv_matnr = iv_matnr
                          iv_werks = iv_werks
                          iv_lgort = iv_lgort
                          iv_charg = iv_charg
                          iv_menge = iv_menge
                          iv_meins = iv_meins ).
    ls_item-orderid = iv_aufnr.

    create( EXPORTING iv_code     = cs_code-goods_issue
                      it_item     = VALUE #( ( ls_item ) )
                      iv_commit   = iv_commit
            IMPORTING ev_mblnr    = ev_mblnr
                      ev_mjahr    = ev_mjahr
                      ev_is_error = ev_is_error
                      et_bapiret  = et_bapiret ).

  ENDMETHOD.

  METHOD goods_issue_reservation.

    DATA ls_resb TYPE resb.

    CLEAR: ev_mblnr, ev_mjahr, ev_is_error, et_bapiret.

    SELECT SINGLE * FROM resb INTO @ls_resb WHERE rsnum = @iv_rsnum AND rspos = @iv_rspos ##WARN_OK.
    IF sy-subrc <> 0.
      zabaputil_cl_bus=>msg_add_text( EXPORTING iv_text    = |Reservation item { iv_rsnum ALPHA = OUT }/{ iv_rspos ALPHA = OUT } not found|
                                      CHANGING  ct_bapiret = et_bapiret ).
      zabaputil_cl_bus=>finish( CHANGING ct_bapiret  = et_bapiret
                                         cv_is_error = ev_is_error ).
      RETURN.
    ENDIF.

    DATA(ls_item) = item( iv_bwart = ls_resb-bwart
                          iv_matnr = ls_resb-matnr
                          iv_werks = ls_resb-werks
                          iv_lgort = COND #( WHEN iv_lgort IS NOT INITIAL THEN iv_lgort ELSE ls_resb-lgort )
                          iv_charg = COND #( WHEN iv_charg IS NOT INITIAL THEN iv_charg ELSE ls_resb-charg )
                          iv_menge = iv_menge
                          iv_meins = ls_resb-erfme ).
    ls_item-reserv_no = iv_rsnum.
    ls_item-res_item  = iv_rspos.

    create( EXPORTING iv_code     = cs_code-goods_issue
                      it_item     = VALUE #( ( ls_item ) )
                      iv_commit   = iv_commit
            IMPORTING ev_mblnr    = ev_mblnr
                      ev_mjahr    = ev_mjahr
                      ev_is_error = ev_is_error
                      et_bapiret  = et_bapiret ).

  ENDMETHOD.

  METHOD goods_receipt_initial.

    create( EXPORTING iv_code     = cs_code-other_receipts
                      it_item     = VALUE #( ( item( iv_bwart = '561'
                                                     iv_matnr = iv_matnr
                                                     iv_werks = iv_werks
                                                     iv_lgort = iv_lgort
                                                     iv_charg = iv_charg
                                                     iv_menge = iv_menge
                                                     iv_meins = iv_meins ) ) )
                      iv_commit   = iv_commit
            IMPORTING ev_mblnr    = ev_mblnr
                      ev_mjahr    = ev_mjahr
                      ev_is_error = ev_is_error
                      et_bapiret  = et_bapiret ).

  ENDMETHOD.

  METHOD cancel.

    DATA ls_headret TYPE bapi2017_gm_head_ret.

    CLEAR: ev_mblnr_cancel, ev_mjahr_cancel, ev_is_error, et_bapiret.

    TRY.
        CALL FUNCTION 'BAPI_GOODSMVT_CANCEL'
          EXPORTING
            materialdocument    = iv_mblnr
            matdocumentyear     = iv_mjahr
            goodsmvt_pstng_date = iv_budat
          IMPORTING
            goodsmvt_headret    = ls_headret
          TABLES
            return              = et_bapiret.
        ev_mblnr_cancel = ls_headret-mat_doc.
        ev_mjahr_cancel = ls_headret-doc_year.
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus=>msg_add_exception( EXPORTING ix_error   = lx_error
                                             CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus=>finish( EXPORTING iv_commit   = iv_commit
                              CHANGING  ct_bapiret  = et_bapiret
                                        cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD item.

    rs_result-move_type = iv_bwart.
    rs_result-plant     = iv_werks.
    rs_result-stge_loc  = iv_lgort.
    rs_result-batch     = iv_charg.
    rs_result-entry_qnt = iv_menge.
    rs_result-entry_uom = iv_meins.
    zabaputil_cl_bus=>set_material( EXPORTING iv_matnr = iv_matnr
                                    CHANGING  cs_data  = rs_result ).

  ENDMETHOD.

ENDCLASS.
