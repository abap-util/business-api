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
      DATA temp1 TYPE string.

    CLEAR: es_qals, ev_is_error, et_bapiret.

    SELECT SINGLE * FROM qals INTO es_qals WHERE prueflos = iv_prueflos.
    IF sy-subrc <> 0.
      
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
        EXPORTING
          input  = iv_prueflos
        IMPORTING
          output = temp1.
zabaputil_cl_bus_util_context=>bapi_msg_add_text( EXPORTING iv_text    = |Inspection lot { temp1 } not found|
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
        DATA temp1 TYPE string_table.
        DATA temp2 LIKE temp1.
          DATA temp8 TYPE string_table.
          DATA temp3 LIKE temp8.
            DATA temp4 LIKE REF TO ls_ud.
DATA temp10 LIKE REF TO lv_prueflos.
DATA temp7 TYPE abap_func_parmbind_tab.
DATA temp9 LIKE LINE OF temp7.
                DATA temp5 TYPE abap_func_excpbind_tab.
                DATA temp6 LIKE LINE OF temp5.
        DATA lx_error TYPE REF TO cx_root.

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
        
        CLEAR temp1.
        INSERT `BAPI2045LA` INTO TABLE temp1.
        INSERT `SPRAS` INTO TABLE temp1.
        
        temp2 = temp1.
        LOOP AT temp2 INTO lv_language_type.
          
          CLEAR temp8.
          INSERT `BAPIRETURN1` INTO TABLE temp8.
          INSERT `BAPIRET2` INTO TABLE temp8.
          
          temp3 = temp8.
          LOOP AT temp3 INTO lv_return_type.

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

            
            GET REFERENCE OF ls_ud INTO temp4.

GET REFERENCE OF lv_prueflos INTO temp10.

CLEAR temp7.

temp9-name = 'NUMBER'.
temp9-kind = abap_func_exporting.
temp9-value = temp10.
INSERT temp9 INTO TABLE temp7.
temp9-name = 'UD_DATA'.
temp9-kind = abap_func_exporting.
temp9-value = temp4.
INSERT temp9 INTO TABLE temp7.
temp9-name = 'LANGUAGE'.
temp9-kind = abap_func_exporting.
temp9-value = lr_language.
INSERT temp9 INTO TABLE temp7.
temp9-name = 'RETURN'.
temp9-kind = abap_func_importing.
temp9-value = lr_return.
INSERT temp9 INTO TABLE temp7.
lt_param = temp7.

            TRY.
                
                CLEAR temp5.
                
                temp6-name = 'ERROR_MESSAGE'.
                temp6-value = 98.
                INSERT temp6 INTO TABLE temp5.
                temp6-name = 'OTHERS'.
                temp6-value = 99.
                INSERT temp6 INTO TABLE temp5.
                CALL FUNCTION 'BAPI_INSPLOT_SETUSAGEDECISION'
                  PARAMETER-TABLE lt_param
                  EXCEPTION-TABLE temp5.
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
        
      CATCH cx_root INTO lx_error.
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

ENDCLASS.
