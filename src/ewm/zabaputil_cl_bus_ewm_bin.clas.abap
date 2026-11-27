"! EWM storage bins. All /SCWM/ objects are reached dynamically, so the class
"! activates in systems without EWM and fails only when it is called there.
CLASS zabaputil_cl_bus_ewm_bin DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    "! Creates, changes or deletes storage bins (/SCWM/LAGP_MAINTAIN) and saves
    "! them (/SCWM/TO_POST). The bins are not locked by the module call. With
    "! iv_commit = abap_true the buffers of the transaction manager (/SCWM/CL_TM)
    "! are cleaned up after the commit or rollback.
    "! @parameter it_bins     | rows of /SCWM/TT_LAGP_MAINTAIN
    "! @parameter iv_action   | action, a constant WMEGC_BIN_* of the type group WMEGC
    "! @parameter iv_complete | abap_true: all bins or none, abap_false: every bin without an error
    CLASS-METHODS maintain
      IMPORTING
        iv_lgnum    TYPE clike
        it_bins     TYPE STANDARD TABLE
        iv_action   TYPE clike
        iv_complete TYPE abap_bool DEFAULT abap_true
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

  PROTECTED SECTION.
  PRIVATE SECTION.

    "! bapi_finish( ) - and with iv_commit, once it has committed or rolled back,
    "! the cleanup of the EWM transaction manager (/SCWM/CL_TM=>CLEANUP), so its
    "! buffers of this posting do not reach the next call in the session. Without
    "! iv_commit the caller's LUW is still open: its buffers stay
    CLASS-METHODS finish
      IMPORTING
        iv_commit   TYPE abap_bool
      CHANGING
        et_bapiret  TYPE bapirettab
        ev_is_error TYPE abap_bool.

ENDCLASS.



CLASS zabaputil_cl_bus_ewm_bin IMPLEMENTATION.

  METHOD maintain.

    DATA lr_lgnum    TYPE REF TO data.
    DATA lr_bins     TYPE REF TO data.
    DATA lt_return   TYPE bapirettab.
    DATA lv_action   TYPE c LENGTH 1.
    DATA lv_complete TYPE abap_bool.
    DATA lv_true     TYPE abap_bool VALUE abap_true.
    DATA lv_false    TYPE abap_bool VALUE abap_false.
    FIELD-SYMBOLS <field> TYPE any.

    CLEAR: ev_is_error, et_bapiret.

    lv_action   = iv_action.
    lv_complete = iv_complete.

    TRY.
        CREATE DATA lr_lgnum TYPE ('/SCWM/LGNUM').
        ASSIGN lr_lgnum->* TO <field>.
        <field> = iv_lgnum.
        GET REFERENCE OF it_bins INTO lr_bins.

        zabaputil_cl_bus_util_context=>bapi_call_function(
                            EXPORTING iv_name    = '/SCWM/LAGP_MAINTAIN'
                                      it_param   = VALUE #( ( name = 'IV_LGNUM'    kind = abap_func_exporting value = lr_lgnum )
                                                            ( name = 'IT_LAGP'     kind = abap_func_exporting value = lr_bins )
                                                            ( name = 'IV_ACTION'   kind = abap_func_exporting value = REF #( lv_action ) )
                                                            ( name = 'IV_COMPLETE' kind = abap_func_exporting value = REF #( lv_complete ) )
                                                            ( name = 'IV_NO_ENQ'   kind = abap_func_exporting value = REF #( lv_true ) )
                                                            ( name = 'ET_BAPIRET'  kind = abap_func_importing value = REF #( lt_return ) ) )
                            CHANGING  ct_bapiret = et_bapiret ).
        INSERT LINES OF lt_return INTO TABLE et_bapiret.

        " the module only fills the buffer - the posting writes the bins
        IF zabaputil_cl_bus_util_context=>bapi_check_is_error( et_bapiret ) = abap_false.
          zabaputil_cl_bus_util_context=>bapi_call_function(
                              EXPORTING iv_name    = '/SCWM/TO_POST'
                                        it_param   = VALUE #( ( name = 'IV_COMMIT_WORK' kind = abap_func_exporting value = REF #( lv_false ) ) )
                              CHANGING  ct_bapiret = et_bapiret ).
        ENDIF.
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    finish( EXPORTING iv_commit   = iv_commit
            CHANGING  et_bapiret  = et_bapiret
                      ev_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD finish.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

    IF iv_commit = abap_true.
      TRY.
          CALL METHOD ('/SCWM/CL_TM')=>('CLEANUP').
        CATCH cx_root ##NO_HANDLER.
          " no transaction manager to clean up - nothing was buffered there
      ENDTRY.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
