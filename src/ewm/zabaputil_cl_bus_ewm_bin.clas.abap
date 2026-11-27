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
        DATA temp1 LIKE REF TO lt_return.
DATA temp3 LIKE REF TO lv_true.
DATA temp6 LIKE REF TO lv_complete.
DATA temp7 LIKE REF TO lv_action.
DATA temp8 TYPE abap_func_parmbind_tab.
DATA temp9 LIKE LINE OF temp8.
          DATA temp2 LIKE REF TO lv_false.
DATA temp4 TYPE abap_func_parmbind_tab.
DATA temp5 LIKE LINE OF temp4.
        DATA lx_error TYPE REF TO cx_root.

    CLEAR: ev_is_error, et_bapiret.

    lv_action   = iv_action.
    lv_complete = iv_complete.

    TRY.
        CREATE DATA lr_lgnum TYPE ('/SCWM/LGNUM').
        ASSIGN lr_lgnum->* TO <field>.
        <field> = iv_lgnum.
        GET REFERENCE OF it_bins INTO lr_bins.

        
        GET REFERENCE OF lt_return INTO temp1.

GET REFERENCE OF lv_true INTO temp3.

GET REFERENCE OF lv_complete INTO temp6.

GET REFERENCE OF lv_action INTO temp7.

CLEAR temp8.

temp9-name = 'IV_LGNUM'.
temp9-kind = abap_func_exporting.
temp9-value = lr_lgnum.
INSERT temp9 INTO TABLE temp8.
temp9-name = 'IT_LAGP'.
temp9-kind = abap_func_exporting.
temp9-value = lr_bins.
INSERT temp9 INTO TABLE temp8.
temp9-name = 'IV_ACTION'.
temp9-kind = abap_func_exporting.
temp9-value = temp7.
INSERT temp9 INTO TABLE temp8.
temp9-name = 'IV_COMPLETE'.
temp9-kind = abap_func_exporting.
temp9-value = temp6.
INSERT temp9 INTO TABLE temp8.
temp9-name = 'IV_NO_ENQ'.
temp9-kind = abap_func_exporting.
temp9-value = temp3.
INSERT temp9 INTO TABLE temp8.
temp9-name = 'ET_BAPIRET'.
temp9-kind = abap_func_importing.
temp9-value = temp1.
INSERT temp9 INTO TABLE temp8.
zabaputil_cl_bus_util_context=>bapi_call_function(
                            EXPORTING iv_name    = '/SCWM/LAGP_MAINTAIN'
                                      it_param   = temp8
                            CHANGING  ct_bapiret = et_bapiret ).
        INSERT LINES OF lt_return INTO TABLE et_bapiret.

        " the module only fills the buffer - the posting writes the bins
        IF zabaputil_cl_bus_util_context=>bapi_check_is_error( et_bapiret ) = abap_false.
          
          GET REFERENCE OF lv_false INTO temp2.

CLEAR temp4.

temp5-name = 'IV_COMMIT_WORK'.
temp5-kind = abap_func_exporting.
temp5-value = temp2.
INSERT temp5 INTO TABLE temp4.
zabaputil_cl_bus_util_context=>bapi_call_function(
                              EXPORTING iv_name    = '/SCWM/TO_POST'
                                        it_param   = temp4
                              CHANGING  ct_bapiret = et_bapiret ).
        ENDIF.
        
      CATCH cx_root INTO lx_error.
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
