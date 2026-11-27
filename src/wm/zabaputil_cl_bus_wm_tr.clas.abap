CLASS zabaputil_cl_bus_wm_tr DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES ty_t_ltbp TYPE STANDARD TABLE OF ltbp WITH DEFAULT KEY.

    "! Creates a transfer requirement for one material (L_TR_CREATE)
    "! @parameter iv_betyp | reference type, e.g. F production order
    "! @parameter iv_benum | reference number
    CLASS-METHODS create
      IMPORTING
        iv_lgnum    TYPE lgnum
        iv_bwlvs    TYPE bwlvs
        iv_matnr    TYPE matnr
        iv_werks    TYPE werks_d
        iv_lgort    TYPE lgort_d OPTIONAL
        iv_charg    TYPE charg_d OPTIONAL
        iv_menge    TYPE menge_d
        iv_meins    TYPE meins
        iv_betyp    TYPE lvs_betyp OPTIONAL
        iv_benum    TYPE lvs_benum OPTIONAL
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_tbnum    TYPE tbnum
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Reads header and items of a transfer requirement
    CLASS-METHODS read
      IMPORTING
        iv_lgnum    TYPE lgnum
        iv_tbnum    TYPE tbnum
      EXPORTING
        es_ltbk     TYPE ltbk
        et_ltbp     TYPE ty_t_ltbp
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Cancels a transfer requirement (L_TR_CANCEL)
    CLASS-METHODS cancel
      IMPORTING
        iv_lgnum    TYPE lgnum
        iv_tbnum    TYPE tbnum
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zabaputil_cl_bus_wm_tr IMPLEMENTATION.

  METHOD create.

    DATA lv_anfme TYPE rl03t-anfme.
    DATA lv_altme TYPE rl03t-altme.

    CLEAR: ev_tbnum, ev_is_error, et_bapiret.

    TRY.
        lv_anfme = iv_menge.
        lv_altme = iv_meins.
        " a plain RAISE in the module would leave an older message in sy-msg
        CLEAR: sy-msgid, sy-msgno.
        CALL FUNCTION 'L_TR_CREATE'
          EXPORTING
            i_lgnum       = iv_lgnum
            i_bwlvs       = iv_bwlvs
            i_betyp       = iv_betyp
            i_benum       = iv_benum
            i_matnr       = iv_matnr
            i_werks       = iv_werks
            i_lgort       = iv_lgort
            i_charg       = iv_charg
            i_anfme       = lv_anfme
            i_altme       = lv_altme
            i_commit_work = abap_false
          IMPORTING
            e_tbnum       = ev_tbnum
          EXCEPTIONS
            error_message = 98
            OTHERS        = 99.
        IF sy-subrc <> 0.
          zabaputil_cl_bus_util_context=>bapi_msg_add_sy( EXPORTING iv_context = 'L_TR_CREATE'
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

  METHOD read.

    CLEAR: es_ltbk, et_ltbp, ev_is_error, et_bapiret.

    SELECT SINGLE * FROM ltbk INTO @es_ltbk WHERE lgnum = @iv_lgnum AND tbnum = @iv_tbnum.
    IF sy-subrc <> 0.
      zabaputil_cl_bus_util_context=>bapi_msg_add_text( EXPORTING iv_text    = |Transfer requirement { iv_lgnum }/{ iv_tbnum ALPHA = OUT } not found|
                                                        CHANGING  ct_bapiret = et_bapiret ).
    ELSE.
      SELECT * FROM ltbp INTO TABLE @et_ltbp WHERE lgnum = @iv_lgnum AND tbnum = @iv_tbnum ORDER BY tbpos.
    ENDIF.

    zabaputil_cl_bus_util_context=>bapi_finish( CHANGING ct_bapiret  = et_bapiret
                                                         cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD cancel.

    CLEAR: ev_is_error, et_bapiret.

    TRY.
        CLEAR: sy-msgid, sy-msgno.
        CALL FUNCTION 'L_TR_CANCEL'
          EXPORTING
            i_lgnum       = iv_lgnum
            i_tbnum       = iv_tbnum
            i_commit_work = abap_false
          EXCEPTIONS
            error_message = 98
            OTHERS        = 99.
        IF sy-subrc <> 0.
          zabaputil_cl_bus_util_context=>bapi_msg_add_sy( EXPORTING iv_context = 'L_TR_CANCEL'
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

ENDCLASS.
