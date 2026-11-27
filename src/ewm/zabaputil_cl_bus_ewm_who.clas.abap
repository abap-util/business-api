"! EWM warehouse orders. All /SCWM/ objects are reached dynamically, so the class
"! activates in systems without EWM and fails only when it is called there.
CLASS zabaputil_cl_bus_ewm_who DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    "! Maintains the handling units assigned to a warehouse order (/SCWM/WHO_WHOHU_MAINT)
    "! @parameter iv_who   | warehouse order
    "! @parameter it_whohu | rows of /SCWM/TT_WHOHU_MAINT, the field UPDKZ names the action per row
    CLASS-METHODS maintain_hus
      IMPORTING
        iv_lgnum    TYPE clike
        iv_who      TYPE clike
        it_whohu    TYPE STANDARD TABLE
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zabaputil_cl_bus_ewm_who IMPLEMENTATION.

  METHOD maintain_hus.

    DATA lr_lgnum  TYPE REF TO data.
    DATA lr_who    TYPE REF TO data.
    DATA lr_whohu  TYPE REF TO data.
    DATA lt_return TYPE bapirettab.
    FIELD-SYMBOLS <field> TYPE any.
        DATA temp1 LIKE REF TO lt_return.
DATA temp2 TYPE abap_func_parmbind_tab.
DATA temp3 LIKE LINE OF temp2.
        DATA lx_error TYPE REF TO cx_root.

    CLEAR: ev_is_error, et_bapiret.

    TRY.
        CREATE DATA lr_lgnum TYPE ('/SCWM/LGNUM').
        ASSIGN lr_lgnum->* TO <field>.
        <field> = iv_lgnum.
        CREATE DATA lr_who TYPE ('/SCWM/DE_WHO').
        ASSIGN lr_who->* TO <field>.
        <field> = zabaputil_cl_bus_util_context=>conv_alpha_in( iv_value  = iv_who
                                                                iv_length = 10 ).
        GET REFERENCE OF it_whohu INTO lr_whohu.

        
        GET REFERENCE OF lt_return INTO temp1.

CLEAR temp2.

temp3-name = 'IV_LGNUM'.
temp3-kind = abap_func_exporting.
temp3-value = lr_lgnum.
INSERT temp3 INTO TABLE temp2.
temp3-name = 'IV_WHO'.
temp3-kind = abap_func_exporting.
temp3-value = lr_who.
INSERT temp3 INTO TABLE temp2.
temp3-name = 'IT_WHOHU'.
temp3-kind = abap_func_exporting.
temp3-value = lr_whohu.
INSERT temp3 INTO TABLE temp2.
temp3-name = 'ET_BAPIRET'.
temp3-kind = abap_func_importing.
temp3-value = temp1.
INSERT temp3 INTO TABLE temp2.
zabaputil_cl_bus_util_context=>bapi_call_function(
                            EXPORTING iv_name    = '/SCWM/WHO_WHOHU_MAINT'
                                      it_param   = temp2
                            CHANGING  ct_bapiret = et_bapiret ).
        INSERT LINES OF lt_return INTO TABLE et_bapiret.
        
      CATCH cx_root INTO lx_error.
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

ENDCLASS.
