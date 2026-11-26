CLASS zabaputil_cl_bus_qm_insp_lot DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    "! Reads an inspection lot
    CLASS-METHODS read
      IMPORTING
        iv_prueflos TYPE qplos
      EXPORTING
        es_qals     TYPE qals
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Records the usage decision of an inspection lot (BAPI_INSPLOT_SETUSAGEDECISION)
    "! @parameter is_ud | UD_SELECTED_SET, UD_PLANT, UD_CODE_GROUP, UD_CODE, ...
    CLASS-METHODS set_usage_decision
      IMPORTING
        iv_prueflos TYPE qplos
        is_ud       TYPE bapi2045ud
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zabaputil_cl_bus_qm_insp_lot IMPLEMENTATION.

  METHOD read.

    CLEAR: es_qals, ev_is_error, et_bapiret.

    SELECT SINGLE * FROM qals INTO @es_qals WHERE prueflos = @iv_prueflos.
    IF sy-subrc <> 0.
      zabaputil_cl_bus_util_context=>bapi_msg_add_text( EXPORTING iv_text    = |Inspection lot { iv_prueflos ALPHA = OUT } not found|
                                                        CHANGING  ct_bapiret = et_bapiret ).
    ENDIF.

    zabaputil_cl_bus_util_context=>bapi_finish( CHANGING ct_bapiret  = et_bapiret
                                                         cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD set_usage_decision.

    DATA ls_return TYPE bapiret2.

    CLEAR: ev_is_error, et_bapiret.

    TRY.
        CALL FUNCTION 'BAPI_INSPLOT_SETUSAGEDECISION'
          EXPORTING
            number   = iv_prueflos
            ud_data  = is_ud
            language = sy-langu
          IMPORTING
            return   = ls_return.
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
