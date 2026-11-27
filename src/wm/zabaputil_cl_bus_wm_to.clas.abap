"! Transfer orders (LE-WM). create_from_delivery resets the delivery, HU and
"! serial number buffers before it posts only with iv_commit = abap_true:
"! with abap_false the caller owns the LUW, and the buffers hold what its
"! earlier calls posted.
CLASS zabaputil_cl_bus_wm_to DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES ty_t_ltap TYPE STANDARD TABLE OF ltap WITH DEFAULT KEY.

    "! Creates a transfer order for one material (L_TO_CREATE_SINGLE)
    "! @parameter iv_bwlvs  | WM movement type
    "! @parameter iv_squit  | abap_true: confirm at once
    CLASS-METHODS create
      IMPORTING
        iv_lgnum    TYPE lgnum
        iv_bwlvs    TYPE bwlvs
        iv_matnr    TYPE matnr
        iv_werks    TYPE werks_d
        iv_lgort    TYPE lgort_d OPTIONAL
        iv_charg    TYPE charg_d OPTIONAL
        iv_anfme    TYPE menge_d
        iv_altme    TYPE meins
        iv_vltyp    TYPE ltap_vltyp OPTIONAL
        iv_vlpla    TYPE ltap_vlpla OPTIONAL
        iv_nltyp    TYPE ltap_nltyp OPTIONAL
        iv_nlpla    TYPE ltap_nlpla OPTIONAL
        iv_squit    TYPE abap_bool DEFAULT abap_false
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_tanum    TYPE tanum
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Creates a transfer order for a delivery (L_TO_CREATE_DN)
    CLASS-METHODS create_from_delivery
      IMPORTING
        iv_lgnum    TYPE lgnum
        iv_vbeln    TYPE vbeln_vl
        iv_squit    TYPE abap_bool DEFAULT abap_false
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_tanum    TYPE tanum
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Creates a transfer order for a transfer requirement (L_TO_CREATE_TR)
    CLASS-METHODS create_from_requirement
      IMPORTING
        iv_lgnum    TYPE lgnum
        iv_tbnum    TYPE tbnum
        iv_squit    TYPE abap_bool DEFAULT abap_false
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_tanum    TYPE tanum
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Reads header and items of a transfer order
    CLASS-METHODS read
      IMPORTING
        iv_lgnum    TYPE lgnum
        iv_tanum    TYPE tanum
      EXPORTING
        es_ltak     TYPE ltak
        et_ltap     TYPE ty_t_ltap
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Confirms all items of a transfer order (L_TO_CONFIRM)
    CLASS-METHODS confirm
      IMPORTING
        iv_lgnum    TYPE lgnum
        iv_tanum    TYPE tanum
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Cancels a transfer order (L_TO_CANCEL)
    CLASS-METHODS cancel
      IMPORTING
        iv_lgnum    TYPE lgnum
        iv_tanum    TYPE tanum
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zabaputil_cl_bus_wm_to IMPLEMENTATION.

  METHOD create.

    DATA lv_anfme TYPE rl03t-anfme.
    DATA lv_altme TYPE rl03t-altme.
        DATA lx_error TYPE REF TO cx_root.

    CLEAR: ev_tanum, ev_is_error, et_bapiret.

    TRY.
        lv_anfme = iv_anfme.
        lv_altme = iv_altme.
        " a plain RAISE in the module would leave an older message in sy-msg
        CLEAR: sy-msgid, sy-msgno.
        CALL FUNCTION 'L_TO_CREATE_SINGLE'
          EXPORTING
            i_lgnum       = iv_lgnum
            i_bwlvs       = iv_bwlvs
            i_matnr       = iv_matnr
            i_werks       = iv_werks
            i_lgort       = iv_lgort
            i_charg       = iv_charg
            i_anfme       = lv_anfme
            i_altme       = lv_altme
            i_vltyp       = iv_vltyp
            i_vlpla       = iv_vlpla
            i_nltyp       = iv_nltyp
            i_nlpla       = iv_nlpla
            i_squit       = iv_squit
            i_commit_work = abap_false
          IMPORTING
            e_tanum       = ev_tanum
          EXCEPTIONS
            error_message = 98
            OTHERS        = 99.
        IF sy-subrc <> 0.
          zabaputil_cl_bus_util_context=>bapi_msg_add_sy( EXPORTING iv_context = 'L_TO_CREATE_SINGLE'
                                                          CHANGING  ct_bapiret = et_bapiret ).
        ENDIF.
        
      CATCH cx_root INTO lx_error.
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD create_from_delivery.
        DATA lx_error TYPE REF TO cx_root.

    CLEAR: ev_tanum, ev_is_error, et_bapiret.

    TRY.
        IF iv_commit = abap_true.
          zabaputil_cl_bus_util_context=>bapi_refresh_buffers( 'DELIVERY' ).
        ENDIF.
        CLEAR: sy-msgid, sy-msgno.
        CALL FUNCTION 'L_TO_CREATE_DN'
          EXPORTING
            i_lgnum       = iv_lgnum
            i_vbeln       = iv_vbeln
            i_squit       = iv_squit
            i_commit_work = abap_false
          IMPORTING
            e_tanum       = ev_tanum
          EXCEPTIONS
            error_message = 98
            OTHERS        = 99.
        IF sy-subrc <> 0.
          zabaputil_cl_bus_util_context=>bapi_msg_add_sy( EXPORTING iv_context = 'L_TO_CREATE_DN'
                                                          CHANGING  ct_bapiret = et_bapiret ).
        ENDIF.
        
      CATCH cx_root INTO lx_error.
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD create_from_requirement.
        DATA lx_error TYPE REF TO cx_root.

    CLEAR: ev_tanum, ev_is_error, et_bapiret.

    TRY.
        CLEAR: sy-msgid, sy-msgno.
        CALL FUNCTION 'L_TO_CREATE_TR'
          EXPORTING
            i_lgnum       = iv_lgnum
            i_tbnum       = iv_tbnum
            i_squit       = iv_squit
            i_commit_work = abap_false
          IMPORTING
            e_tanum       = ev_tanum
          EXCEPTIONS
            error_message = 98
            OTHERS        = 99.
        IF sy-subrc <> 0.
          zabaputil_cl_bus_util_context=>bapi_msg_add_sy( EXPORTING iv_context = 'L_TO_CREATE_TR'
                                                          CHANGING  ct_bapiret = et_bapiret ).
        ENDIF.
        
      CATCH cx_root INTO lx_error.
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD read.
      DATA temp1 TYPE string.

    CLEAR: es_ltak, et_ltap, ev_is_error, et_bapiret.

    SELECT SINGLE * FROM ltak INTO es_ltak WHERE lgnum = iv_lgnum AND tanum = iv_tanum.
    IF sy-subrc <> 0.
      
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
        EXPORTING
          input  = iv_tanum
        IMPORTING
          output = temp1.
zabaputil_cl_bus_util_context=>bapi_msg_add_text( EXPORTING iv_text    = |Transfer order { iv_lgnum }/{ temp1 } not found|
                                                        CHANGING  ct_bapiret = et_bapiret ).
    ELSE.
      SELECT * FROM ltap INTO TABLE et_ltap WHERE lgnum = iv_lgnum AND tanum = iv_tanum ORDER BY tapos.
    ENDIF.

    zabaputil_cl_bus_util_context=>bapi_finish( CHANGING ct_bapiret  = et_bapiret
                                                         cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD confirm.
        DATA lx_error TYPE REF TO cx_root.

    CLEAR: ev_is_error, et_bapiret.

    TRY.
        CLEAR: sy-msgid, sy-msgno.
        CALL FUNCTION 'L_TO_CONFIRM'
          EXPORTING
            i_lgnum       = iv_lgnum
            i_tanum       = iv_tanum
            i_squit       = abap_true
            i_commit_work = abap_false
          EXCEPTIONS
            error_message = 98
            OTHERS        = 99.
        IF sy-subrc <> 0.
          zabaputil_cl_bus_util_context=>bapi_msg_add_sy( EXPORTING iv_context = 'L_TO_CONFIRM'
                                                          CHANGING  ct_bapiret = et_bapiret ).
        ENDIF.
        
      CATCH cx_root INTO lx_error.
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD cancel.
        DATA lx_error TYPE REF TO cx_root.

    CLEAR: ev_is_error, et_bapiret.

    TRY.
        CLEAR: sy-msgid, sy-msgno.
        CALL FUNCTION 'L_TO_CANCEL'
          EXPORTING
            i_lgnum       = iv_lgnum
            i_tanum       = iv_tanum
            i_commit_work = abap_false
          EXCEPTIONS
            error_message = 98
            OTHERS        = 99.
        IF sy-subrc <> 0.
          zabaputil_cl_bus_util_context=>bapi_msg_add_sy( EXPORTING iv_context = 'L_TO_CANCEL'
                                                          CHANGING  ct_bapiret = et_bapiret ).
        ENDIF.
        
      CATCH cx_root INTO lx_error.
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

ENDCLASS.
