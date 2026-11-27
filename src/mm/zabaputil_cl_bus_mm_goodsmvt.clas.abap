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

    "! Goods issue for a reservation item, with the movement type of the reservation.
    "! A transfer reservation (movement type 3xx) is posted as transfer posting (GM code 04)
    "! to the receiving plant and storage location of the reservation, any other with GM code 03.
    "! @parameter iv_menge | the quantity, in iv_meins
    "! @parameter iv_meins | the unit of iv_menge; initial: the unit of entry of the
    "!                       reservation (RESB-ERFME), not necessarily the base unit
    CLASS-METHODS goods_issue_reservation
      IMPORTING
        iv_rsnum    TYPE rsnum
        iv_rspos    TYPE rspos
        iv_menge    TYPE erfmg
        iv_meins    TYPE erfme OPTIONAL
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

    "! posts one item with create( )
    CLASS-METHODS post_single
      IMPORTING
        iv_code     TYPE clike
        is_item     TYPE bapi2017_gm_item_create
        iv_commit   TYPE abap_bool
      EXPORTING
        ev_mblnr    TYPE mblnr
        ev_mjahr    TYPE mjahr
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

ENDCLASS.



CLASS zabaputil_cl_bus_mm_goodsmvt IMPLEMENTATION.

  METHOD create.

    DATA ls_header TYPE bapi2017_gm_head_01.
    DATA ls_code   TYPE bapi2017_gm_code.
    DATA lt_item   TYPE ty_t_item.
        DATA lx_error TYPE REF TO cx_root.

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
        
      CATCH cx_root INTO lx_error.
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    IF ev_mblnr IS INITIAL AND zabaputil_cl_bus_util_context=>bapi_check_is_error( et_bapiret ) = abap_false.
      zabaputil_cl_bus_util_context=>bapi_msg_add_text( EXPORTING iv_text    = 'No material document created'
                                                        CHANGING  ct_bapiret = et_bapiret ).
    ENDIF.
    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD transfer_storage_location.

    DATA ls_item TYPE bapi2017_gm_item_create.

    ls_item = item( iv_bwart = '311'
                    iv_matnr = iv_matnr
                    iv_werks = iv_werks
                    iv_lgort = iv_lgort_from
                    iv_charg = iv_charg
                    iv_menge = iv_menge
                    iv_meins = iv_meins ).
    ls_item-move_stloc = iv_lgort_to.
    " the receiving batch, as in transfer_plant( ): a storage location
    " transfer keeps the batch
    ls_item-move_batch = iv_charg.

    post_single( EXPORTING iv_code     = cs_code-transfer_posting
                           is_item     = ls_item
                           iv_commit   = iv_commit
                 IMPORTING ev_mblnr    = ev_mblnr
                           ev_mjahr    = ev_mjahr
                           ev_is_error = ev_is_error
                           et_bapiret  = et_bapiret ).

  ENDMETHOD.

  METHOD transfer_plant.

    DATA ls_item TYPE bapi2017_gm_item_create.

    ls_item = item( iv_bwart = '301'
                    iv_matnr = iv_matnr
                    iv_werks = iv_werks_from
                    iv_lgort = iv_lgort_from
                    iv_charg = iv_charg
                    iv_menge = iv_menge
                    iv_meins = iv_meins ).
    ls_item-move_plant = iv_werks_to.
    ls_item-move_stloc = iv_lgort_to.
    ls_item-move_batch = iv_charg.

    post_single( EXPORTING iv_code     = cs_code-transfer_posting
                           is_item     = ls_item
                           iv_commit   = iv_commit
                 IMPORTING ev_mblnr    = ev_mblnr
                           ev_mjahr    = ev_mjahr
                           ev_is_error = ev_is_error
                           et_bapiret  = et_bapiret ).

  ENDMETHOD.

  METHOD transfer_stock_type.

    DATA ls_item TYPE bapi2017_gm_item_create.

    ls_item = item( iv_bwart = iv_bwart
                    iv_matnr = iv_matnr
                    iv_werks = iv_werks
                    iv_lgort = iv_lgort
                    iv_charg = iv_charg
                    iv_menge = iv_menge
                    iv_meins = iv_meins ).

    post_single( EXPORTING iv_code     = cs_code-transfer_posting
                           is_item     = ls_item
                           iv_commit   = iv_commit
                 IMPORTING ev_mblnr    = ev_mblnr
                           ev_mjahr    = ev_mjahr
                           ev_is_error = ev_is_error
                           et_bapiret  = et_bapiret ).

  ENDMETHOD.

  METHOD goods_issue_order.

    DATA ls_item TYPE bapi2017_gm_item_create.

    ls_item = item( iv_bwart = '261'
                    iv_matnr = iv_matnr
                    iv_werks = iv_werks
                    iv_lgort = iv_lgort
                    iv_charg = iv_charg
                    iv_menge = iv_menge
                    iv_meins = iv_meins ).
    ls_item-orderid = iv_aufnr.

    post_single( EXPORTING iv_code     = cs_code-goods_issue
                           is_item     = ls_item
                           iv_commit   = iv_commit
                 IMPORTING ev_mblnr    = ev_mblnr
                           ev_mjahr    = ev_mjahr
                           ev_is_error = ev_is_error
                           et_bapiret  = et_bapiret ).

  ENDMETHOD.

  METHOD goods_issue_reservation.

    DATA ls_item  TYPE bapi2017_gm_item_create.
    DATA lv_lgort TYPE lgort_d.
    DATA lv_charg TYPE charg_d.
    DATA lv_code  TYPE bapi2017_gm_code-gm_code.
    DATA lv_meins TYPE erfme.

    DATA ls_resb TYPE resb.
    FIELD-SYMBOLS <umcha> TYPE any.
      DATA temp1 TYPE string.
DATA temp2 TYPE string.

    CLEAR: ev_mblnr, ev_mjahr, ev_is_error, et_bapiret.

    SELECT SINGLE * FROM resb INTO ls_resb WHERE rsnum = iv_rsnum AND rspos = iv_rspos ##WARN_OK.
    IF sy-subrc <> 0.
      
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
        EXPORTING
          input  = iv_rsnum
        IMPORTING
          output = temp1.

CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
  EXPORTING
    input  = iv_rspos
  IMPORTING
    output = temp2.
zabaputil_cl_bus_util_context=>bapi_msg_add_text( EXPORTING iv_text    = |Reservation item { temp1 }/{ temp2 } not found|
                                                        CHANGING  ct_bapiret = et_bapiret ).
      zabaputil_cl_bus_util_context=>bapi_finish( CHANGING ct_bapiret  = et_bapiret
                                                           cv_is_error = ev_is_error ).
      RETURN.
    ENDIF.

    lv_lgort = iv_lgort.
    IF lv_lgort IS INITIAL.
      lv_lgort = ls_resb-lgort.
    ENDIF.
    lv_charg = iv_charg.
    IF lv_charg IS INITIAL.
      lv_charg = ls_resb-charg.
    ENDIF.
    lv_meins = iv_meins.
    IF lv_meins IS INITIAL.
      lv_meins = ls_resb-erfme.
    ENDIF.

    ls_item = item( iv_bwart = ls_resb-bwart
                    iv_matnr = ls_resb-matnr
                    iv_werks = ls_resb-werks
                    iv_lgort = lv_lgort
                    iv_charg = lv_charg
                    iv_menge = iv_menge
                    iv_meins = lv_meins ).
    ls_item-reserv_no = iv_rsnum.
    ls_item-res_item  = iv_rspos.

    " GM code 03 does not allow transfer movement types
    IF ls_resb-bwart(1) = '3'.
      lv_code = cs_code-transfer_posting.
      ls_item-move_plant = ls_resb-umwrk.
      ls_item-move_stloc = ls_resb-umlgo.
      " the receiving batch where the reservation names one - by name, as
      " the field is not verified on every release; otherwise the BAPI
      " derives it, as before
      ASSIGN COMPONENT 'UMCHA' OF STRUCTURE ls_resb TO <umcha>.
      IF sy-subrc = 0 AND <umcha> IS NOT INITIAL.
        ls_item-move_batch = <umcha>.
      ENDIF.
    ELSE.
      lv_code = cs_code-goods_issue.
    ENDIF.

    post_single( EXPORTING iv_code     = lv_code
                           is_item     = ls_item
                           iv_commit   = iv_commit
                 IMPORTING ev_mblnr    = ev_mblnr
                           ev_mjahr    = ev_mjahr
                           ev_is_error = ev_is_error
                           et_bapiret  = et_bapiret ).

  ENDMETHOD.

  METHOD goods_receipt_initial.

    DATA ls_item TYPE bapi2017_gm_item_create.

    ls_item = item( iv_bwart = '561'
                    iv_matnr = iv_matnr
                    iv_werks = iv_werks
                    iv_lgort = iv_lgort
                    iv_charg = iv_charg
                    iv_menge = iv_menge
                    iv_meins = iv_meins ).

    post_single( EXPORTING iv_code     = cs_code-other_receipts
                           is_item     = ls_item
                           iv_commit   = iv_commit
                 IMPORTING ev_mblnr    = ev_mblnr
                           ev_mjahr    = ev_mjahr
                           ev_is_error = ev_is_error
                           et_bapiret  = et_bapiret ).

  ENDMETHOD.

  METHOD cancel.

    DATA ls_headret TYPE bapi2017_gm_head_ret.
        DATA lx_error TYPE REF TO cx_root.

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
        
      CATCH cx_root INTO lx_error.
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD post_single.

    DATA lt_item TYPE ty_t_item.

    INSERT is_item INTO TABLE lt_item.

    create( EXPORTING iv_code     = iv_code
                      it_item     = lt_item
                      iv_commit   = iv_commit
            IMPORTING ev_mblnr    = ev_mblnr
                      ev_mjahr    = ev_mjahr
                      ev_is_error = ev_is_error
                      et_bapiret  = et_bapiret ).

  ENDMETHOD.

  METHOD item.

    rs_result-move_type = iv_bwart.
    rs_result-plant     = iv_werks.
    rs_result-stge_loc  = iv_lgort.
    rs_result-batch     = iv_charg.
    rs_result-entry_qnt = iv_menge.
    rs_result-entry_uom = iv_meins.
    zabaputil_cl_bus_util_context=>bapi_set_material( EXPORTING iv_matnr = iv_matnr
                                                      CHANGING  cs_data  = rs_result ).

  ENDMETHOD.

ENDCLASS.
