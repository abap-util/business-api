CLASS ltcl_bus DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS check_is_error           FOR TESTING.
    METHODS finish_without_commit    FOR TESTING.
    METHODS finish_keeps_error_flag  FOR TESTING.
    METHODS msg_add_text             FOR TESTING.
    METHODS msg_add_exception        FOR TESTING.
    METHODS msg_add_bapiret2_empty   FOR TESTING.
    METHODS msg_add_table_prott      FOR TESTING.
    METHODS set_material_short       FOR TESTING.
    METHODS set_material_long        FOR TESTING.
    METHODS alpha_in                 FOR TESTING.

ENDCLASS.


CLASS ltcl_bus IMPLEMENTATION.

  METHOD check_is_error.

    DATA lt_bapiret TYPE bapirettab.

    lt_bapiret = VALUE #( ( type = 'S' ) ( type = 'W' ) ).
    cl_abap_unit_assert=>assert_false( zabaputil_cl_bus=>check_is_error( lt_bapiret ) ).

    lt_bapiret = VALUE #( ( type = 'S' ) ( type = 'E' ) ).
    cl_abap_unit_assert=>assert_true( zabaputil_cl_bus=>check_is_error( lt_bapiret ) ).

    lt_bapiret = VALUE #( ( type = 'A' ) ).
    cl_abap_unit_assert=>assert_true( zabaputil_cl_bus=>check_is_error( lt_bapiret ) ).

    lt_bapiret = VALUE #( ( type = 'X' ) ).
    cl_abap_unit_assert=>assert_true( zabaputil_cl_bus=>check_is_error( lt_bapiret ) ).

  ENDMETHOD.

  METHOD finish_without_commit.

    DATA lt_bapiret  TYPE bapirettab.
    DATA lv_is_error TYPE abap_bool.

    lt_bapiret = VALUE #( ( type = 'S' message = 'ok' ) ).
    zabaputil_cl_bus=>finish( CHANGING ct_bapiret  = lt_bapiret
                                       cv_is_error = lv_is_error ).
    cl_abap_unit_assert=>assert_false( lv_is_error ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( lt_bapiret ) ).

    lt_bapiret = VALUE #( ( type = 'E' message = 'failed' ) ).
    zabaputil_cl_bus=>finish( CHANGING ct_bapiret  = lt_bapiret
                                       cv_is_error = lv_is_error ).
    cl_abap_unit_assert=>assert_true( lv_is_error ).

  ENDMETHOD.

  METHOD finish_keeps_error_flag.

    DATA lt_bapiret  TYPE bapirettab.
    DATA lv_is_error TYPE abap_bool.

    " an error flagged by the method itself survives success messages
    lv_is_error = abap_true.
    lt_bapiret = VALUE #( ( type = 'S' ) ).
    zabaputil_cl_bus=>finish( CHANGING ct_bapiret  = lt_bapiret
                                       cv_is_error = lv_is_error ).
    cl_abap_unit_assert=>assert_true( lv_is_error ).

  ENDMETHOD.

  METHOD msg_add_text.

    DATA lt_bapiret TYPE bapirettab.

    zabaputil_cl_bus=>msg_add_text( EXPORTING iv_text    = 'not found'
                                    CHANGING  ct_bapiret = lt_bapiret ).
    zabaputil_cl_bus=>msg_add_text( EXPORTING iv_text    = 'just saying'
                                              iv_type    = 'I'
                                    CHANGING  ct_bapiret = lt_bapiret ).

    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( lt_bapiret ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'E'
                                        act = lt_bapiret[ 1 ]-type ).
    cl_abap_unit_assert=>assert_equals( exp = 'not found'
                                        act = lt_bapiret[ 1 ]-message ).
    cl_abap_unit_assert=>assert_equals( exp = 'I'
                                        act = lt_bapiret[ 2 ]-type ).

  ENDMETHOD.

  METHOD msg_add_exception.

    DATA lt_bapiret TYPE bapirettab.
    DATA lv_number  TYPE i.

    TRY.
        lv_number = 'abc'.
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus=>msg_add_exception( EXPORTING ix_error   = lx_error
                                             CHANGING  ct_bapiret = lt_bapiret ).
    ENDTRY.

    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = lv_number ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( lt_bapiret ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'E'
                                        act = lt_bapiret[ 1 ]-type ).
    cl_abap_unit_assert=>assert_not_initial( lt_bapiret[ 1 ]-message ).

  ENDMETHOD.

  METHOD msg_add_bapiret2_empty.

    DATA lt_bapiret TYPE bapirettab.

    zabaputil_cl_bus=>msg_add_bapiret2( EXPORTING is_return  = VALUE #( )
                                        CHANGING  ct_bapiret = lt_bapiret ).
    cl_abap_unit_assert=>assert_initial( lt_bapiret ).

  ENDMETHOD.

  METHOD msg_add_table_prott.

    TYPES:
      BEGIN OF ty_s_prot,
        msgty TYPE c LENGTH 1,
        msgid TYPE c LENGTH 20,
        msgno TYPE n LENGTH 3,
        msgv1 TYPE c LENGTH 50,
      END OF ty_s_prot.
    DATA lt_prot    TYPE STANDARD TABLE OF ty_s_prot WITH EMPTY KEY.
    DATA lt_bapiret TYPE bapirettab.

    lt_prot = VALUE #( ( msgty = 'E' msgid = '00' msgno = '001' msgv1 = 'value' ) ).
    zabaputil_cl_bus=>msg_add_table( EXPORTING it_table   = lt_prot
                                     CHANGING  ct_bapiret = lt_bapiret ).

    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( lt_bapiret ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'E'
                                        act = lt_bapiret[ 1 ]-type ).
    cl_abap_unit_assert=>assert_equals( exp = '00'
                                        act = lt_bapiret[ 1 ]-id ).
    cl_abap_unit_assert=>assert_equals( exp = '001'
                                        act = lt_bapiret[ 1 ]-number ).
    cl_abap_unit_assert=>assert_equals( exp = 'value'
                                        act = lt_bapiret[ 1 ]-message_v1 ).
    cl_abap_unit_assert=>assert_true( zabaputil_cl_bus=>check_is_error( lt_bapiret ) ).

  ENDMETHOD.

  METHOD set_material_short.

    TYPES:
      BEGIN OF ty_s_item,
        material TYPE c LENGTH 18,
        plant    TYPE c LENGTH 4,
      END OF ty_s_item.
    DATA ls_item TYPE ty_s_item.

    zabaputil_cl_bus=>set_material( EXPORTING iv_matnr = 'MAT-1'
                                    CHANGING  cs_data  = ls_item ).
    cl_abap_unit_assert=>assert_equals( exp = 'MAT-1'
                                        act = ls_item-material ).

  ENDMETHOD.

  METHOD set_material_long.

    TYPES:
      BEGIN OF ty_s_item,
        material      TYPE c LENGTH 18,
        material_long TYPE c LENGTH 40,
      END OF ty_s_item.
    DATA ls_item TYPE ty_s_item.

    zabaputil_cl_bus=>set_material( EXPORTING iv_matnr = 'A-MATERIAL-NUMBER-LONGER-THAN-18'
                                    CHANGING  cs_data  = ls_item ).
    cl_abap_unit_assert=>assert_equals( exp = 'A-MATERIAL-NUMBER-LONGER-THAN-18'
                                        act = ls_item-material_long ).
    cl_abap_unit_assert=>assert_initial( ls_item-material ).

  ENDMETHOD.

  METHOD alpha_in.

    cl_abap_unit_assert=>assert_equals( exp = '0080001234'
                                        act = zabaputil_cl_bus=>alpha_in( '80001234' ) ).
    cl_abap_unit_assert=>assert_equals( exp = '000000000000004711'
                                        act = zabaputil_cl_bus=>alpha_in( iv_value  = '4711'
                                                                          iv_length = 18 ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'MAT-1'
                                        act = zabaputil_cl_bus=>alpha_in( 'MAT-1' ) ).

  ENDMETHOD.

ENDCLASS.
