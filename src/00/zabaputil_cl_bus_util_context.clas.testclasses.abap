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
      ty_t_ret TYPE STANDARD TABLE OF ty_s_ret WITH EMPTY KEY.

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

    lt_ret = VALUE #( ( type = `S` ) ( type = `W` ) ).
    cl_abap_unit_assert=>assert_false( zabaputil_cl_bus_util_context=>bapi_check_is_error( lt_ret ) ).

    lt_ret = VALUE #( ( type = `S` ) ( type = `E` ) ).
    cl_abap_unit_assert=>assert_true( zabaputil_cl_bus_util_context=>bapi_check_is_error( lt_ret ) ).

    lt_ret = VALUE #( ( type = `A` ) ).
    cl_abap_unit_assert=>assert_true( zabaputil_cl_bus_util_context=>bapi_check_is_error( lt_ret ) ).

    lt_ret = VALUE #( ( type = `X` ) ).
    cl_abap_unit_assert=>assert_true( zabaputil_cl_bus_util_context=>bapi_check_is_error( lt_ret ) ).

    CLEAR lt_ret.
    cl_abap_unit_assert=>assert_false( zabaputil_cl_bus_util_context=>bapi_check_is_error( lt_ret ) ).

  ENDMETHOD.

  METHOD check_is_error_msgty.

    TYPES:
      BEGIN OF ty_s_prot,
        msgty TYPE c LENGTH 1,
      END OF ty_s_prot.
    DATA lt_prot TYPE STANDARD TABLE OF ty_s_prot WITH EMPTY KEY.

    lt_prot = VALUE #( ( msgty = `I` ) ( msgty = `E` ) ).
    cl_abap_unit_assert=>assert_true( zabaputil_cl_bus_util_context=>bapi_check_is_error( lt_prot ) ).

  ENDMETHOD.

  METHOD finish_without_commit.

    DATA lt_ret      TYPE ty_t_ret.
    DATA lv_is_error TYPE abap_bool.

    lt_ret = VALUE #( ( type = `S` message = `ok` ) ).
    zabaputil_cl_bus_util_context=>bapi_finish( CHANGING ct_bapiret  = lt_ret
                                                     cv_is_error = lv_is_error ).
    cl_abap_unit_assert=>assert_false( lv_is_error ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( lt_ret ) ).

    lt_ret = VALUE #( ( type = `E` message = `failed` ) ).
    zabaputil_cl_bus_util_context=>bapi_finish( CHANGING ct_bapiret  = lt_ret
                                                     cv_is_error = lv_is_error ).
    cl_abap_unit_assert=>assert_true( lv_is_error ).

  ENDMETHOD.

  METHOD finish_keeps_error_flag.

    DATA lt_ret      TYPE ty_t_ret.
    DATA lv_is_error TYPE abap_bool.

    " an error flagged by the caller itself survives success messages
    lv_is_error = abap_true.
    lt_ret = VALUE #( ( type = `S` ) ).
    zabaputil_cl_bus_util_context=>bapi_finish( CHANGING ct_bapiret  = lt_ret
                                                     cv_is_error = lv_is_error ).
    cl_abap_unit_assert=>assert_true( lv_is_error ).

  ENDMETHOD.

  METHOD msg_add_text.

    DATA lt_ret TYPE ty_t_ret.

    zabaputil_cl_bus_util_context=>bapi_msg_add_text( EXPORTING iv_text    = `not found`
                                                  CHANGING  ct_bapiret = lt_ret ).
    zabaputil_cl_bus_util_context=>bapi_msg_add_text( EXPORTING iv_text    = `just saying`
                                                            iv_type    = `I`
                                                  CHANGING  ct_bapiret = lt_ret ).

    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( lt_ret ) ).
    cl_abap_unit_assert=>assert_equals( exp = `E`
                                        act = lt_ret[ 1 ]-type ).
    cl_abap_unit_assert=>assert_equals( exp = `not found`
                                        act = lt_ret[ 1 ]-message ).
    cl_abap_unit_assert=>assert_equals( exp = `I`
                                        act = lt_ret[ 2 ]-type ).

  ENDMETHOD.

  METHOD msg_add_exception.

    DATA lt_ret TYPE ty_t_ret.

    TRY.
        RAISE EXCEPTION TYPE zabaputil_cx_bus_util_error
          EXPORTING
            val = `the error text`.
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                           CHANGING  ct_bapiret = lt_ret ).
    ENDTRY.

    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( lt_ret ) ).
    cl_abap_unit_assert=>assert_equals( exp = `E`
                                        act = lt_ret[ 1 ]-type ).
    cl_abap_unit_assert=>assert_equals( exp = `the error text`
                                        act = lt_ret[ 1 ]-message ).

  ENDMETHOD.

  METHOD msg_add_bapiret2.

    DATA lt_ret TYPE ty_t_ret.

    zabaputil_cl_bus_util_context=>bapi_msg_add_bapiret2(
      EXPORTING is_return  = VALUE ty_s_ret( type = `W` id = `V1` number = `123` message = `careful` )
      CHANGING  ct_bapiret = lt_ret ).

    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( lt_ret ) ).
    cl_abap_unit_assert=>assert_equals( exp = `V1`
                                        act = lt_ret[ 1 ]-id ).
    cl_abap_unit_assert=>assert_equals( exp = `123`
                                        act = lt_ret[ 1 ]-number ).

  ENDMETHOD.

  METHOD msg_add_bapiret2_empty.

    DATA lt_ret TYPE ty_t_ret.

    zabaputil_cl_bus_util_context=>bapi_msg_add_bapiret2( EXPORTING is_return  = VALUE ty_s_ret( )
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
    DATA lt_prot TYPE STANDARD TABLE OF ty_s_prot WITH EMPTY KEY.
    DATA lt_ret  TYPE ty_t_ret.

    lt_prot = VALUE #( ( msgty = `E` msgid = `00` msgno = `001` msgv1 = `value` ) ).
    zabaputil_cl_bus_util_context=>bapi_msg_add_table( EXPORTING it_table   = lt_prot
                                                   CHANGING  ct_bapiret = lt_ret ).

    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( lt_ret ) ).
    cl_abap_unit_assert=>assert_equals( exp = `E`
                                        act = lt_ret[ 1 ]-type ).
    cl_abap_unit_assert=>assert_equals( exp = `00`
                                        act = lt_ret[ 1 ]-id ).
    cl_abap_unit_assert=>assert_equals( exp = `001`
                                        act = lt_ret[ 1 ]-number ).
    cl_abap_unit_assert=>assert_equals( exp = `value`
                                        act = lt_ret[ 1 ]-message_v1 ).
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
    DATA lt_mesg TYPE STANDARD TABLE OF ty_s_mesg WITH EMPTY KEY.
    DATA lt_ret  TYPE ty_t_ret.

    lt_mesg = VALUE #( ( msgty = `W` arbgb = `VL` txtnr = `042` text = `a warning` ) ).
    zabaputil_cl_bus_util_context=>bapi_msg_add_table( EXPORTING it_table   = lt_mesg
                                                   CHANGING  ct_bapiret = lt_ret ).

    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( lt_ret ) ).
    cl_abap_unit_assert=>assert_equals( exp = `W`
                                        act = lt_ret[ 1 ]-type ).
    cl_abap_unit_assert=>assert_equals( exp = `VL`
                                        act = lt_ret[ 1 ]-id ).
    cl_abap_unit_assert=>assert_equals( exp = `042`
                                        act = lt_ret[ 1 ]-number ).
    cl_abap_unit_assert=>assert_equals( exp = `a warning`
                                        act = lt_ret[ 1 ]-message ).

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
