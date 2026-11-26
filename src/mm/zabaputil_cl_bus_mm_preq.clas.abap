CLASS zabaputil_cl_bus_mm_preq DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    "! Releases a purchase requisition item with a release code (BAPI_REQUISITION_RELEASE)
    CLASS-METHODS release
      IMPORTING
        iv_banfn          TYPE banfn
        iv_bnfpo          TYPE bnfpo
        iv_rel_code       TYPE frgco
        iv_commit         TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_rel_status_new TYPE frgzu
        ev_is_error       TYPE abap_bool
        et_bapiret        TYPE bapirettab.

    "! Resets the release of a purchase requisition item (BAPI_REQUISITION_RESET_RELEASE)
    CLASS-METHODS reset_release
      IMPORTING
        iv_banfn          TYPE banfn
        iv_bnfpo          TYPE bnfpo
        iv_rel_code       TYPE frgco
        iv_commit         TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_rel_status_new TYPE frgzu
        ev_is_error       TYPE abap_bool
        et_bapiret        TYPE bapirettab.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zabaputil_cl_bus_mm_preq IMPLEMENTATION.

  METHOD release.

    CLEAR: ev_rel_status_new, ev_is_error, et_bapiret.

    TRY.
        CALL FUNCTION 'BAPI_REQUISITION_RELEASE'
          EXPORTING
            number                 = iv_banfn
            rel_code               = iv_rel_code
            item                   = iv_bnfpo
          IMPORTING
            rel_status_new         = ev_rel_status_new
          TABLES
            return                 = et_bapiret
          EXCEPTIONS
            error_message = 1
            OTHERS        = 2.
        IF sy-subrc <> 0.
          zabaputil_cl_bus=>msg_add_sy( EXPORTING iv_context = 'BAPI_REQUISITION_RELEASE'
                                        CHANGING  ct_bapiret = et_bapiret ).
        ENDIF.
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus=>msg_add_exception( EXPORTING ix_error   = lx_error
                                             CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus=>finish( EXPORTING iv_commit   = iv_commit
                              CHANGING  ct_bapiret  = et_bapiret
                                        cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD reset_release.

    CLEAR: ev_rel_status_new, ev_is_error, et_bapiret.

    TRY.
        CALL FUNCTION 'BAPI_REQUISITION_RESET_RELEASE'
          EXPORTING
            number                   = iv_banfn
            rel_code                 = iv_rel_code
            item                     = iv_bnfpo
          IMPORTING
            rel_status_new           = ev_rel_status_new
          TABLES
            return                   = et_bapiret
          EXCEPTIONS
            error_message = 1
            OTHERS        = 2.
        IF sy-subrc <> 0.
          zabaputil_cl_bus=>msg_add_sy( EXPORTING iv_context = 'BAPI_REQUISITION_RESET_RELEASE'
                                        CHANGING  ct_bapiret = et_bapiret ).
        ENDIF.
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus=>msg_add_exception( EXPORTING ix_error   = lx_error
                                             CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus=>finish( EXPORTING iv_commit   = iv_commit
                              CHANGING  ct_bapiret  = et_bapiret
                                        cv_is_error = ev_is_error ).

  ENDMETHOD.

ENDCLASS.
