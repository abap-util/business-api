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

    DATA lt_param         TYPE abap_func_parmbind_tab.
    DATA lr_language      TYPE REF TO data.
    DATA lr_return        TYPE REF TO data.
    DATA ls_ud            TYPE bapi2045ud.
    DATA lv_prueflos      TYPE qplos.
    DATA lv_language_type TYPE string.
    DATA lv_return_type   TYPE string.
    DATA lv_called        TYPE abap_bool.
    DATA lv_subrc         TYPE sysubrc.
    FIELD-SYMBOLS <language> TYPE any.
    FIELD-SYMBOLS <field>    TYPE any.
    FIELD-SYMBOLS <return>   TYPE any.

    CLEAR: ev_is_error, et_bapiret.

    lv_prueflos = iv_prueflos.
    ls_ud       = is_ud.

    " LANGUAGE is the structure BAPI2045LA (LANGUAGE, LANGUAGE_ISO) and RETURN
    " a BAPIRETURN1 in the interface as documented - neither verified on a
    " system, and the language key passed for LANGUAGE before failed every
    " call with a type conflict. So both are created by name and the pairs
    " of types are tried in turn: a type conflict (CX_SY_DYN_CALL_ILLEGAL_TYPE)
    " is raised before the module runs, the next pair is safe to try
    TRY.
        LOOP AT VALUE string_table( ( `BAPI2045LA` ) ( `SPRAS` ) ) INTO lv_language_type.
          LOOP AT VALUE string_table( ( `BAPIRETURN1` ) ( `BAPIRET2` ) ) INTO lv_return_type.

            CREATE DATA lr_language TYPE (lv_language_type).
            ASSIGN lr_language->* TO <language>.
            UNASSIGN <field>.
            IF cl_abap_typedescr=>describe_by_data( <language> )->kind = cl_abap_typedescr=>kind_struct.
              ASSIGN COMPONENT 'LANGUAGE' OF STRUCTURE <language> TO <field>.
            ELSE.
              ASSIGN <language> TO <field>.
            ENDIF.
            IF <field> IS ASSIGNED.
              <field> = sy-langu.
            ENDIF.
            CREATE DATA lr_return TYPE (lv_return_type).

            lt_param = VALUE #( ( name = 'NUMBER'   kind = abap_func_exporting value = REF #( lv_prueflos ) )
                                ( name = 'UD_DATA'  kind = abap_func_exporting value = REF #( ls_ud ) )
                                ( name = 'LANGUAGE' kind = abap_func_exporting value = lr_language )
                                ( name = 'RETURN'   kind = abap_func_importing value = lr_return ) ).

            TRY.
                CALL FUNCTION 'BAPI_INSPLOT_SETUSAGEDECISION'
                  PARAMETER-TABLE lt_param
                  EXCEPTION-TABLE VALUE abap_func_excpbind_tab( ( name = 'ERROR_MESSAGE' value = 98 )
                                                                ( name = 'OTHERS'        value = 99 ) ).
                lv_subrc = sy-subrc.
              CATCH cx_sy_dyn_call_illegal_type.
                CONTINUE.
            ENDTRY.

            lv_called = abap_true.
            IF lv_subrc <> 0.
              zabaputil_cl_bus_util_context=>bapi_msg_add_sy( EXPORTING iv_context = 'BAPI_INSPLOT_SETUSAGEDECISION'
                                                              CHANGING  ct_bapiret = et_bapiret ).
            ENDIF.
            ASSIGN lr_return->* TO <return>.
            zabaputil_cl_bus_util_context=>bapi_msg_add_bapiret2( EXPORTING is_return  = <return>
                                                                  CHANGING  ct_bapiret = et_bapiret ).
            EXIT.

          ENDLOOP.
          IF lv_called = abap_true.
            EXIT.
          ENDIF.
        ENDLOOP.

        IF lv_called = abap_false.
          zabaputil_cl_bus_util_context=>bapi_msg_add_text( EXPORTING iv_text    = `BAPI_INSPLOT_SETUSAGEDECISION: LANGUAGE or RETURN has a type not handled here`
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
