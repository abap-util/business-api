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

        zabaputil_cl_bus_util_context=>bapi_call_function(
                            EXPORTING iv_name    = '/SCWM/WHO_WHOHU_MAINT'
                                      it_param   = VALUE #( ( name = 'IV_LGNUM'   kind = abap_func_exporting value = lr_lgnum )
                                                            ( name = 'IV_WHO'     kind = abap_func_exporting value = lr_who )
                                                            ( name = 'IT_WHOHU'   kind = abap_func_exporting value = lr_whohu )
                                                            ( name = 'ET_BAPIRET' kind = abap_func_importing value = REF #( lt_return ) ) )
                            CHANGING  ct_bapiret = et_bapiret ).
        INSERT LINES OF lt_return INTO TABLE et_bapiret.
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

ENDCLASS.
