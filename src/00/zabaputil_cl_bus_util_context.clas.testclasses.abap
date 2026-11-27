CLASS ltcl_bapi_ops DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    " the components of BAPIRET2 the bapi_* methods read and write - no
    " DDIC type, which is what makes the methods generic
    TYPES:
      BEGIN OF ty_s_ret,
        type       TYPE c LENGTH 1,
        id         TYPE c LENGTH 20,
        number     TYPE n LENGTH 3,
        message    TYPE c LENGTH 220,
        message_v1 TYPE c LENGTH 50,
        message_v2 TYPE c LENGTH 50,
        message_v3 TYPE c LENGTH 50,
        message_v4 TYPE c LENGTH 50,
      END OF ty_s_ret,
      ty_t_ret TYPE STANDARD TABLE OF ty_s_ret WITH DEFAULT KEY.

    METHODS check_is_error          FOR TESTING.
    METHODS check_is_error_msgty    FOR TESTING.
    METHODS finish_without_commit   FOR TESTING.
    METHODS finish_keeps_error_flag FOR TESTING.
    METHODS msg_add_text            FOR TESTING.
    METHODS msg_add_exception       FOR TESTING.
    METHODS msg_add_bapiret2        FOR TESTING.
    METHODS msg_add_bapiret2_empty  FOR TESTING.
    METHODS msg_add_table_prott     FOR TESTING.
    METHODS msg_add_table_mesg      FOR TESTING.
    METHODS set_material_short      FOR TESTING.
    METHODS set_material_long       FOR TESTING.
    METHODS set_material_none       FOR TESTING.
    METHODS alpha_in                FOR TESTING.

ENDCLASS.

CLASS ltcl_bapi_ops IMPLEMENTATION.

  METHOD check_is_error.

    DATA lt_ret TYPE ty_t_ret.

    DATA temp1 TYPE ltcl_bapi_ops=>ty_t_ret.
    DATA temp2 LIKE LINE OF temp1.
    DATA temp3 TYPE ltcl_bapi_ops=>ty_t_ret.
    DATA temp4 LIKE LINE OF temp3.
    DATA temp5 TYPE ltcl_bapi_ops=>ty_t_ret.
    DATA temp6 LIKE LINE OF temp5.
    DATA temp7 TYPE ltcl_bapi_ops=>ty_t_ret.
    DATA temp8 LIKE LINE OF temp7.
    CLEAR temp1.
    
    temp2-type = `S`.
    INSERT temp2 INTO TABLE temp1.
    temp2-type = `W`.
    INSERT temp2 INTO TABLE temp1.
    lt_ret = temp1.
    cl_abap_unit_assert=>assert_false( zabaputil_cl_bus_util_context=>bapi_check_is_error( lt_ret ) ).

    
    CLEAR temp3.
    
    temp4-type = `S`.
    INSERT temp4 INTO TABLE temp3.
    temp4-type = `E`.
    INSERT temp4 INTO TABLE temp3.
    lt_ret = temp3.
    cl_abap_unit_assert=>assert_true( zabaputil_cl_bus_util_context=>bapi_check_is_error( lt_ret ) ).

    
    CLEAR temp5.
    
    temp6-type = `A`.
    INSERT temp6 INTO TABLE temp5.
    lt_ret = temp5.
    cl_abap_unit_assert=>assert_true( zabaputil_cl_bus_util_context=>bapi_check_is_error( lt_ret ) ).

    
    CLEAR temp7.
    
    temp8-type = `X`.
    INSERT temp8 INTO TABLE temp7.
    lt_ret = temp7.
    cl_abap_unit_assert=>assert_true( zabaputil_cl_bus_util_context=>bapi_check_is_error( lt_ret ) ).

    CLEAR lt_ret.
    cl_abap_unit_assert=>assert_false( zabaputil_cl_bus_util_context=>bapi_check_is_error( lt_ret ) ).

  ENDMETHOD.

  METHOD check_is_error_msgty.

    TYPES:
      BEGIN OF ty_s_prot,
        msgty TYPE c LENGTH 1,
      END OF ty_s_prot.
    DATA lt_prot TYPE STANDARD TABLE OF ty_s_prot WITH DEFAULT KEY.

    DATA temp9 LIKE lt_prot.
    DATA temp10 LIKE LINE OF temp9.
    CLEAR temp9.
    
    temp10-msgty = `I`.
    INSERT temp10 INTO TABLE temp9.
    temp10-msgty = `E`.
    INSERT temp10 INTO TABLE temp9.
    lt_prot = temp9.
    cl_abap_unit_assert=>assert_true( zabaputil_cl_bus_util_context=>bapi_check_is_error( lt_prot ) ).

  ENDMETHOD.

  METHOD finish_without_commit.

    DATA lt_ret      TYPE ty_t_ret.
    DATA lv_is_error TYPE abap_bool.

    DATA temp11 TYPE ltcl_bapi_ops=>ty_t_ret.
    DATA temp12 LIKE LINE OF temp11.
    DATA temp13 TYPE ltcl_bapi_ops=>ty_t_ret.
    DATA temp14 LIKE LINE OF temp13.
    CLEAR temp11.
    
    temp12-type = `S`.
    temp12-message = `ok`.
    INSERT temp12 INTO TABLE temp11.
    lt_ret = temp11.
    zabaputil_cl_bus_util_context=>bapi_finish( CHANGING ct_bapiret  = lt_ret
                                                     cv_is_error = lv_is_error ).
    cl_abap_unit_assert=>assert_false( lv_is_error ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( lt_ret ) ).

    
    CLEAR temp13.
    
    temp14-type = `E`.
    temp14-message = `failed`.
    INSERT temp14 INTO TABLE temp13.
    lt_ret = temp13.
    zabaputil_cl_bus_util_context=>bapi_finish( CHANGING ct_bapiret  = lt_ret
                                                     cv_is_error = lv_is_error ).
    cl_abap_unit_assert=>assert_true( lv_is_error ).

  ENDMETHOD.

  METHOD finish_keeps_error_flag.

    DATA lt_ret      TYPE ty_t_ret.
    DATA lv_is_error TYPE abap_bool.
    DATA temp15 TYPE ltcl_bapi_ops=>ty_t_ret.
    DATA temp16 LIKE LINE OF temp15.

    " an error flagged by the caller itself survives success messages
    lv_is_error = abap_true.
    
    CLEAR temp15.
    
    temp16-type = `S`.
    INSERT temp16 INTO TABLE temp15.
    lt_ret = temp15.
    zabaputil_cl_bus_util_context=>bapi_finish( CHANGING ct_bapiret  = lt_ret
                                                     cv_is_error = lv_is_error ).
    cl_abap_unit_assert=>assert_true( lv_is_error ).

  ENDMETHOD.

  METHOD msg_add_text.

    DATA lt_ret TYPE ty_t_ret.
    FIELD-SYMBOLS <temp17> LIKE LINE OF lt_ret.
    DATA temp18 LIKE sy-tabix.
    FIELD-SYMBOLS <temp19> LIKE LINE OF lt_ret.
    DATA temp20 LIKE sy-tabix.
    FIELD-SYMBOLS <temp21> LIKE LINE OF lt_ret.
    DATA temp22 LIKE sy-tabix.

    zabaputil_cl_bus_util_context=>bapi_msg_add_text( EXPORTING iv_text    = `not found`
                                                  CHANGING  ct_bapiret = lt_ret ).
    zabaputil_cl_bus_util_context=>bapi_msg_add_text( EXPORTING iv_text    = `just saying`
                                                            iv_type    = `I`
                                                  CHANGING  ct_bapiret = lt_ret ).

    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( lt_ret ) ).
    
    
    temp18 = sy-tabix.
    READ TABLE lt_ret INDEX 1 ASSIGNING <temp17>.
    sy-tabix = temp18.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_itab_line_not_found.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `E`
                                        act = <temp17>-type ).
    
    
    temp20 = sy-tabix.
    READ TABLE lt_ret INDEX 1 ASSIGNING <temp19>.
    sy-tabix = temp20.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_itab_line_not_found.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `not found`
                                        act = <temp19>-message ).
    
    
    temp22 = sy-tabix.
    READ TABLE lt_ret INDEX 2 ASSIGNING <temp21>.
    sy-tabix = temp22.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_itab_line_not_found.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `I`
                                        act = <temp21>-type ).

  ENDMETHOD.

  METHOD msg_add_exception.

    DATA lt_ret TYPE ty_t_ret.
        DATA lx_error TYPE REF TO cx_root.
    FIELD-SYMBOLS <temp23> LIKE LINE OF lt_ret.
    DATA temp24 LIKE sy-tabix.
    FIELD-SYMBOLS <temp25> LIKE LINE OF lt_ret.
    DATA temp26 LIKE sy-tabix.

    TRY.
        RAISE EXCEPTION TYPE zabaputil_cx_bus_util_error
          EXPORTING
            val = `the error text`.
        
      CATCH cx_root INTO lx_error.
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                           CHANGING  ct_bapiret = lt_ret ).
    ENDTRY.

    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( lt_ret ) ).
    
    
    temp24 = sy-tabix.
    READ TABLE lt_ret INDEX 1 ASSIGNING <temp23>.
    sy-tabix = temp24.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_itab_line_not_found.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `E`
                                        act = <temp23>-type ).
    
    
    temp26 = sy-tabix.
    READ TABLE lt_ret INDEX 1 ASSIGNING <temp25>.
    sy-tabix = temp26.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_itab_line_not_found.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `the error text`
                                        act = <temp25>-message ).

  ENDMETHOD.

  METHOD msg_add_bapiret2.

    DATA lt_ret TYPE ty_t_ret.

    DATA temp27 TYPE ty_s_ret.
    FIELD-SYMBOLS <temp28> LIKE LINE OF lt_ret.
    DATA temp29 LIKE sy-tabix.
    FIELD-SYMBOLS <temp30> LIKE LINE OF lt_ret.
    DATA temp31 LIKE sy-tabix.
    CLEAR temp27.
    temp27-type = `W`.
    temp27-id = `V1`.
    temp27-number = `123`.
    temp27-message = `careful`.
    zabaputil_cl_bus_util_context=>bapi_msg_add_bapiret2(
      EXPORTING is_return  = temp27
      CHANGING  ct_bapiret = lt_ret ).

    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( lt_ret ) ).
    
    
    temp29 = sy-tabix.
    READ TABLE lt_ret INDEX 1 ASSIGNING <temp28>.
    sy-tabix = temp29.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_itab_line_not_found.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `V1`
                                        act = <temp28>-id ).
    
    
    temp31 = sy-tabix.
    READ TABLE lt_ret INDEX 1 ASSIGNING <temp30>.
    sy-tabix = temp31.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_itab_line_not_found.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `123`
                                        act = <temp30>-number ).

  ENDMETHOD.

  METHOD msg_add_bapiret2_empty.

    DATA lt_ret TYPE ty_t_ret.

    DATA temp32 TYPE ty_s_ret.
    CLEAR temp32.
    zabaputil_cl_bus_util_context=>bapi_msg_add_bapiret2( EXPORTING is_return  = temp32
                                                      CHANGING  ct_bapiret = lt_ret ).
    cl_abap_unit_assert=>assert_initial( lt_ret ).

  ENDMETHOD.

  METHOD msg_add_table_prott.

    TYPES:
      BEGIN OF ty_s_prot,
        msgty TYPE c LENGTH 1,
        msgid TYPE c LENGTH 20,
        msgno TYPE n LENGTH 3,
        msgv1 TYPE c LENGTH 50,
      END OF ty_s_prot.
    DATA lt_prot TYPE STANDARD TABLE OF ty_s_prot WITH DEFAULT KEY.
    DATA lt_ret  TYPE ty_t_ret.

    DATA temp33 LIKE lt_prot.
    DATA temp34 LIKE LINE OF temp33.
    FIELD-SYMBOLS <temp35> LIKE LINE OF lt_ret.
    DATA temp36 LIKE sy-tabix.
    FIELD-SYMBOLS <temp37> LIKE LINE OF lt_ret.
    DATA temp38 LIKE sy-tabix.
    FIELD-SYMBOLS <temp39> LIKE LINE OF lt_ret.
    DATA temp40 LIKE sy-tabix.
    FIELD-SYMBOLS <temp41> LIKE LINE OF lt_ret.
    DATA temp42 LIKE sy-tabix.
    CLEAR temp33.
    
    temp34-msgty = `E`.
    temp34-msgid = `00`.
    temp34-msgno = `001`.
    temp34-msgv1 = `value`.
    INSERT temp34 INTO TABLE temp33.
    lt_prot = temp33.
    zabaputil_cl_bus_util_context=>bapi_msg_add_table( EXPORTING it_table   = lt_prot
                                                   CHANGING  ct_bapiret = lt_ret ).

    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( lt_ret ) ).
    
    
    temp36 = sy-tabix.
    READ TABLE lt_ret INDEX 1 ASSIGNING <temp35>.
    sy-tabix = temp36.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_itab_line_not_found.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `E`
                                        act = <temp35>-type ).
    
    
    temp38 = sy-tabix.
    READ TABLE lt_ret INDEX 1 ASSIGNING <temp37>.
    sy-tabix = temp38.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_itab_line_not_found.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `00`
                                        act = <temp37>-id ).
    
    
    temp40 = sy-tabix.
    READ TABLE lt_ret INDEX 1 ASSIGNING <temp39>.
    sy-tabix = temp40.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_itab_line_not_found.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `001`
                                        act = <temp39>-number ).
    
    
    temp42 = sy-tabix.
    READ TABLE lt_ret INDEX 1 ASSIGNING <temp41>.
    sy-tabix = temp42.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_itab_line_not_found.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `value`
                                        act = <temp41>-message_v1 ).
    cl_abap_unit_assert=>assert_true( zabaputil_cl_bus_util_context=>bapi_check_is_error( lt_ret ) ).

  ENDMETHOD.

  METHOD msg_add_table_mesg.

    " MESG names the message class ARBGB and the number TXTNR
    TYPES:
      BEGIN OF ty_s_mesg,
        msgty TYPE c LENGTH 1,
        arbgb TYPE c LENGTH 20,
        txtnr TYPE c LENGTH 3,
        text  TYPE c LENGTH 73,
      END OF ty_s_mesg.
    DATA lt_mesg TYPE STANDARD TABLE OF ty_s_mesg WITH DEFAULT KEY.
    DATA lt_ret  TYPE ty_t_ret.

    DATA temp43 LIKE lt_mesg.
    DATA temp44 LIKE LINE OF temp43.
    FIELD-SYMBOLS <temp45> LIKE LINE OF lt_ret.
    DATA temp46 LIKE sy-tabix.
    FIELD-SYMBOLS <temp47> LIKE LINE OF lt_ret.
    DATA temp48 LIKE sy-tabix.
    FIELD-SYMBOLS <temp49> LIKE LINE OF lt_ret.
    DATA temp50 LIKE sy-tabix.
    FIELD-SYMBOLS <temp51> LIKE LINE OF lt_ret.
    DATA temp52 LIKE sy-tabix.
    CLEAR temp43.
    
    temp44-msgty = `W`.
    temp44-arbgb = `VL`.
    temp44-txtnr = `042`.
    temp44-text = `a warning`.
    INSERT temp44 INTO TABLE temp43.
    lt_mesg = temp43.
    zabaputil_cl_bus_util_context=>bapi_msg_add_table( EXPORTING it_table   = lt_mesg
                                                   CHANGING  ct_bapiret = lt_ret ).

    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( lt_ret ) ).
    
    
    temp46 = sy-tabix.
    READ TABLE lt_ret INDEX 1 ASSIGNING <temp45>.
    sy-tabix = temp46.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_itab_line_not_found.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `W`
                                        act = <temp45>-type ).
    
    
    temp48 = sy-tabix.
    READ TABLE lt_ret INDEX 1 ASSIGNING <temp47>.
    sy-tabix = temp48.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_itab_line_not_found.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `VL`
                                        act = <temp47>-id ).
    
    
    temp50 = sy-tabix.
    READ TABLE lt_ret INDEX 1 ASSIGNING <temp49>.
    sy-tabix = temp50.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_itab_line_not_found.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `042`
                                        act = <temp49>-number ).
    
    
    temp52 = sy-tabix.
    READ TABLE lt_ret INDEX 1 ASSIGNING <temp51>.
    sy-tabix = temp52.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_sy_itab_line_not_found.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `a warning`
                                        act = <temp51>-message ).

  ENDMETHOD.

  METHOD set_material_short.

    TYPES:
      BEGIN OF ty_s_item,
        material TYPE c LENGTH 18,
        plant    TYPE c LENGTH 4,
      END OF ty_s_item.
    DATA ls_item TYPE ty_s_item.

    zabaputil_cl_bus_util_context=>bapi_set_material( EXPORTING iv_matnr = `MAT-1`
                                                  CHANGING  cs_data  = ls_item ).
    cl_abap_unit_assert=>assert_equals( exp = `MAT-1`
                                        act = ls_item-material ).

  ENDMETHOD.

  METHOD set_material_long.

    TYPES:
      BEGIN OF ty_s_item,
        material      TYPE c LENGTH 18,
        material_long TYPE c LENGTH 40,
      END OF ty_s_item.
    DATA ls_item TYPE ty_s_item.

    zabaputil_cl_bus_util_context=>bapi_set_material( EXPORTING iv_matnr = `A-MATERIAL-NUMBER-LONGER-THAN-18`
                                                  CHANGING  cs_data  = ls_item ).
    cl_abap_unit_assert=>assert_equals( exp = `A-MATERIAL-NUMBER-LONGER-THAN-18`
                                        act = ls_item-material_long ).
    cl_abap_unit_assert=>assert_initial( ls_item-material ).

  ENDMETHOD.

  METHOD set_material_none.

    TYPES:
      BEGIN OF ty_s_item,
        plant TYPE c LENGTH 4,
      END OF ty_s_item.
    DATA ls_item TYPE ty_s_item.

    zabaputil_cl_bus_util_context=>bapi_set_material( EXPORTING iv_matnr = `MAT-1`
                                                  CHANGING  cs_data  = ls_item ).
    cl_abap_unit_assert=>assert_initial( ls_item ).

  ENDMETHOD.

  METHOD alpha_in.

    cl_abap_unit_assert=>assert_equals( exp = `0080001234`
                                        act = zabaputil_cl_bus_util_context=>conv_alpha_in( `80001234` ) ).
    cl_abap_unit_assert=>assert_equals( exp = `000000000000004711`
                                        act = zabaputil_cl_bus_util_context=>conv_alpha_in( iv_value  = ` 4711 `
                                                                                        iv_length = 18 ) ).
    cl_abap_unit_assert=>assert_equals( exp = `MAT-1`
                                        act = zabaputil_cl_bus_util_context=>conv_alpha_in( `MAT-1` ) ).
    cl_abap_unit_assert=>assert_initial( zabaputil_cl_bus_util_context=>conv_alpha_in( `` ) ).

  ENDMETHOD.

ENDCLASS.
