CLASS zabaputil_cl_bus_sd_hu DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES ty_t_header TYPE STANDARD TABLE OF bapihuheader WITH DEFAULT KEY.
    TYPES ty_t_item TYPE STANDARD TABLE OF bapihuitem WITH DEFAULT KEY.

    "! Creates a handling unit (BAPI_HU_CREATE)
    "! @parameter iv_vhilm | packaging material
    "! @parameter iv_exidv | external HU number, initial: from the number range
    CLASS-METHODS create
      IMPORTING
        iv_vhilm    TYPE vhilm
        iv_werks    TYPE werks_d
        iv_lgort    TYPE lgort_d OPTIONAL
        iv_exidv    TYPE exidv OPTIONAL
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_exidv    TYPE exidv
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Reads header and items of a handling unit (BAPI_HU_GETLIST)
    CLASS-METHODS read
      IMPORTING
        iv_exidv    TYPE exidv
      EXPORTING
        es_header   TYPE bapihuheader
        et_item     TYPE ty_t_item
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Packs a material quantity into a handling unit (BAPI_HU_PACK)
    CLASS-METHODS pack_material
      IMPORTING
        iv_exidv    TYPE exidv
        iv_matnr    TYPE matnr
        iv_quantity TYPE vemng
        iv_unit     TYPE vemeh
        iv_werks    TYPE werks_d
        iv_lgort    TYPE lgort_d OPTIONAL
        iv_charg    TYPE charg_d OPTIONAL
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Packs a handling unit into another one (BAPI_HU_PACK)
    CLASS-METHODS pack_hu
      IMPORTING
        iv_exidv     TYPE exidv
        iv_exidv_sub TYPE exidv
        iv_commit    TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error  TYPE abap_bool
        et_bapiret   TYPE bapirettab.

    "! Unpacks a material quantity from a handling unit (BAPI_HU_UNPACK)
    CLASS-METHODS unpack_material
      IMPORTING
        iv_exidv    TYPE exidv
        iv_matnr    TYPE matnr
        iv_quantity TYPE vemng
        iv_unit     TYPE vemeh
        iv_werks    TYPE werks_d
        iv_lgort    TYPE lgort_d OPTIONAL
        iv_charg    TYPE charg_d OPTIONAL
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Unpacks a handling unit from another one (BAPI_HU_UNPACK)
    CLASS-METHODS unpack_hu
      IMPORTING
        iv_exidv     TYPE exidv
        iv_exidv_sub TYPE exidv
        iv_commit    TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error  TYPE abap_bool
        et_bapiret   TYPE bapirettab.

    "! Deletes a handling unit (BAPI_HU_DELETE)
    CLASS-METHODS delete
      IMPORTING
        iv_exidv    TYPE exidv
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

  PROTECTED SECTION.
  PRIVATE SECTION.

    CLASS-METHODS call_pack
      IMPORTING
        iv_exidv   TYPE exidv
        is_item    TYPE bapihuitmproposal
      CHANGING
        ct_bapiret TYPE bapirettab.

    CLASS-METHODS call_unpack
      IMPORTING
        iv_exidv   TYPE exidv
        is_item    TYPE bapihuitmunpack
      CHANGING
        ct_bapiret TYPE bapirettab.

ENDCLASS.



CLASS zabaputil_cl_bus_sd_hu IMPLEMENTATION.

  METHOD create.

    DATA ls_proposal TYPE bapihuhdrproposal.
    DATA ls_header   TYPE bapihuheader.

    CLEAR: ev_exidv, ev_is_error, et_bapiret.

    TRY.
        zabaputil_cl_bus_util_context=>bapi_refresh_buffers( 'HU' ).
        ls_proposal-hu_exid  = iv_exidv.
        ls_proposal-plant    = iv_werks.
        ls_proposal-stge_loc = iv_lgort.
        zabaputil_cl_bus_util_context=>bapi_set_material( EXPORTING iv_matnr = iv_vhilm
                                                                    iv_field = 'PACK_MAT'
                                                          CHANGING  cs_data  = ls_proposal ).
        CALL FUNCTION 'BAPI_HU_CREATE'
          EXPORTING
            headerproposal = ls_proposal
          IMPORTING
            huheader       = ls_header
            hukey          = ev_exidv
          TABLES
            return         = et_bapiret.
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD read.

    DATA lt_number TYPE STANDARD TABLE OF bapihunumber WITH DEFAULT KEY.
    DATA lt_header TYPE ty_t_header.

    CLEAR: es_header, et_item, ev_is_error, et_bapiret.

    TRY.
        lt_number = VALUE #( ( hu_exid = iv_exidv ) ).
        CALL FUNCTION 'BAPI_HU_GETLIST'
          EXPORTING
            notext    = abap_true
            onlykeys  = abap_false
          TABLES
            hunumbers = lt_number
            huheader  = lt_header
            huitem    = et_item
            return    = et_bapiret.
        READ TABLE lt_header INTO es_header INDEX 1.
        IF sy-subrc <> 0 AND zabaputil_cl_bus_util_context=>bapi_check_is_error( et_bapiret ) = abap_false.
          zabaputil_cl_bus_util_context=>bapi_msg_add_text( EXPORTING iv_text    = |Handling unit { iv_exidv ALPHA = OUT } not found|
                                                            CHANGING  ct_bapiret = et_bapiret ).
        ENDIF.
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( CHANGING ct_bapiret  = et_bapiret
                                                         cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD pack_material.

    DATA ls_item TYPE bapihuitmproposal.

    CLEAR: ev_is_error, et_bapiret.

    TRY.
        ls_item-hu_item_type = '1'.
        ls_item-pack_qty     = iv_quantity.
        ls_item-base_unit_qty = iv_unit.
        ls_item-plant        = iv_werks.
        ls_item-stge_loc     = iv_lgort.
        ls_item-batch        = iv_charg.
        zabaputil_cl_bus_util_context=>bapi_set_material( EXPORTING iv_matnr = iv_matnr
                                                          CHANGING  cs_data  = ls_item ).
        call_pack( EXPORTING iv_exidv   = iv_exidv
                             is_item    = ls_item
                   CHANGING  ct_bapiret = et_bapiret ).
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD pack_hu.

    DATA ls_item TYPE bapihuitmproposal.

    CLEAR: ev_is_error, et_bapiret.

    TRY.
        ls_item-hu_item_type     = '3'.
        ls_item-lower_level_exid = iv_exidv_sub.
        call_pack( EXPORTING iv_exidv   = iv_exidv
                             is_item    = ls_item
                   CHANGING  ct_bapiret = et_bapiret ).
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD unpack_material.

    DATA ls_item TYPE bapihuitmunpack.

    CLEAR: ev_is_error, et_bapiret.

    TRY.
        ls_item-hu_item_type  = '1'.
        ls_item-pack_qty      = iv_quantity.
        ls_item-base_unit_qty = iv_unit.
        ls_item-plant         = iv_werks.
        ls_item-stge_loc      = iv_lgort.
        ls_item-batch         = iv_charg.
        zabaputil_cl_bus_util_context=>bapi_set_material( EXPORTING iv_matnr = iv_matnr
                                                          CHANGING  cs_data  = ls_item ).
        call_unpack( EXPORTING iv_exidv   = iv_exidv
                               is_item    = ls_item
                     CHANGING  ct_bapiret = et_bapiret ).
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD unpack_hu.

    DATA ls_item TYPE bapihuitmunpack.

    CLEAR: ev_is_error, et_bapiret.

    TRY.
        ls_item-hu_item_type     = '3'.
        ls_item-lower_level_exid = iv_exidv_sub.
        call_unpack( EXPORTING iv_exidv   = iv_exidv
                               is_item    = ls_item
                     CHANGING  ct_bapiret = et_bapiret ).
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD delete.

    CLEAR: ev_is_error, et_bapiret.

    TRY.
        zabaputil_cl_bus_util_context=>bapi_refresh_buffers( 'HU' ).
        CALL FUNCTION 'BAPI_HU_DELETE'
          EXPORTING
            hukey  = iv_exidv
          TABLES
            return = et_bapiret.
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD call_pack.

    DATA lt_return TYPE bapirettab.

    zabaputil_cl_bus_util_context=>bapi_refresh_buffers( 'HU' ).
    CALL FUNCTION 'BAPI_HU_PACK'
      EXPORTING
        hukey        = iv_exidv
        itemproposal = is_item
      TABLES
        return       = lt_return.
    INSERT LINES OF lt_return INTO TABLE ct_bapiret.

  ENDMETHOD.

  METHOD call_unpack.

    DATA lt_return TYPE bapirettab.

    zabaputil_cl_bus_util_context=>bapi_refresh_buffers( 'HU' ).
    CALL FUNCTION 'BAPI_HU_UNPACK'
      EXPORTING
        hukey      = iv_exidv
        itemunpack = is_item
      TABLES
        return     = lt_return.
    INSERT LINES OF lt_return INTO TABLE ct_bapiret.

  ENDMETHOD.

ENDCLASS.
