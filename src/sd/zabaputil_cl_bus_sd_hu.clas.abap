"! Handling units. The write methods reset the HU buffers (HU_PACKING_REFRESH)
"! before they post only with iv_commit = abap_true: with abap_false the
"! caller owns the LUW, the buffers hold the HUs its earlier calls created or
"! packed, and several calls - create, then pack - are committed together.
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

    "! packs (BAPI_HU_PACK) or unpacks (BAPI_HU_UNPACK) one item
    "! @parameter is_item | BAPIHUITMPROPOSAL to pack, BAPIHUITMUNPACK to unpack
    CLASS-METHODS call_pack
      IMPORTING
        iv_unpack   TYPE abap_bool
        iv_exidv    TYPE exidv
        is_item     TYPE any
        iv_commit   TYPE abap_bool
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

ENDCLASS.



CLASS zabaputil_cl_bus_sd_hu IMPLEMENTATION.

  METHOD create.

    DATA ls_proposal TYPE bapihuhdrproposal.
    DATA ls_header   TYPE bapihuheader.
        DATA lx_error TYPE REF TO cx_root.

    CLEAR: ev_exidv, ev_is_error, et_bapiret.

    TRY.
        IF iv_commit = abap_true.
          zabaputil_cl_bus_util_context=>bapi_refresh_buffers( 'HU' ).
        ENDIF.
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
        
      CATCH cx_root INTO lx_error.
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    IF ev_exidv IS INITIAL AND zabaputil_cl_bus_util_context=>bapi_check_is_error( et_bapiret ) = abap_false.
      zabaputil_cl_bus_util_context=>bapi_msg_add_text( EXPORTING iv_text    = 'No handling unit created'
                                                        CHANGING  ct_bapiret = et_bapiret ).
    ENDIF.
    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD read.

    DATA lt_number TYPE STANDARD TABLE OF bapihunumber WITH DEFAULT KEY.
    DATA lt_header TYPE ty_t_header.
        DATA temp1 LIKE lt_number.
        DATA temp2 LIKE LINE OF temp1.
          DATA temp3 TYPE string.
        DATA lx_error TYPE REF TO cx_root.

    CLEAR: es_header, et_item, ev_is_error, et_bapiret.

    TRY.
        
        CLEAR temp1.
        
        temp2-hu_exid = iv_exidv.
        INSERT temp2 INTO TABLE temp1.
        lt_number = temp1.
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
          
          CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
            EXPORTING
              input  = iv_exidv
            IMPORTING
              output = temp3.
zabaputil_cl_bus_util_context=>bapi_msg_add_text( EXPORTING iv_text    = |Handling unit { temp3 } not found|
                                                            CHANGING  ct_bapiret = et_bapiret ).
        ENDIF.
        
      CATCH cx_root INTO lx_error.
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( CHANGING ct_bapiret  = et_bapiret
                                                         cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD pack_material.

    DATA ls_item TYPE bapihuitmproposal.

    ls_item-hu_item_type  = '1'.
    ls_item-pack_qty      = iv_quantity.
    ls_item-base_unit_qty = iv_unit.
    ls_item-plant         = iv_werks.
    ls_item-stge_loc      = iv_lgort.
    ls_item-batch         = iv_charg.
    zabaputil_cl_bus_util_context=>bapi_set_material( EXPORTING iv_matnr = iv_matnr
                                                      CHANGING  cs_data  = ls_item ).

    call_pack( EXPORTING iv_unpack   = abap_false
                         iv_exidv    = iv_exidv
                         is_item     = ls_item
                         iv_commit   = iv_commit
               IMPORTING ev_is_error = ev_is_error
                         et_bapiret  = et_bapiret ).

  ENDMETHOD.

  METHOD pack_hu.

    DATA ls_item TYPE bapihuitmproposal.

    ls_item-hu_item_type     = '3'.
    ls_item-lower_level_exid = iv_exidv_sub.

    call_pack( EXPORTING iv_unpack   = abap_false
                         iv_exidv    = iv_exidv
                         is_item     = ls_item
                         iv_commit   = iv_commit
               IMPORTING ev_is_error = ev_is_error
                         et_bapiret  = et_bapiret ).

  ENDMETHOD.

  METHOD unpack_material.

    DATA ls_item TYPE bapihuitmunpack.

    ls_item-hu_item_type  = '1'.
    ls_item-pack_qty      = iv_quantity.
    ls_item-base_unit_qty = iv_unit.
    ls_item-plant         = iv_werks.
    ls_item-stge_loc      = iv_lgort.
    ls_item-batch         = iv_charg.
    zabaputil_cl_bus_util_context=>bapi_set_material( EXPORTING iv_matnr = iv_matnr
                                                      CHANGING  cs_data  = ls_item ).

    call_pack( EXPORTING iv_unpack   = abap_true
                         iv_exidv    = iv_exidv
                         is_item     = ls_item
                         iv_commit   = iv_commit
               IMPORTING ev_is_error = ev_is_error
                         et_bapiret  = et_bapiret ).

  ENDMETHOD.

  METHOD unpack_hu.

    DATA ls_item TYPE bapihuitmunpack.

    ls_item-hu_item_type     = '3'.
    ls_item-lower_level_exid = iv_exidv_sub.

    call_pack( EXPORTING iv_unpack   = abap_true
                         iv_exidv    = iv_exidv
                         is_item     = ls_item
                         iv_commit   = iv_commit
               IMPORTING ev_is_error = ev_is_error
                         et_bapiret  = et_bapiret ).

  ENDMETHOD.

  METHOD delete.
        DATA lx_error TYPE REF TO cx_root.

    CLEAR: ev_is_error, et_bapiret.

    TRY.
        IF iv_commit = abap_true.
          zabaputil_cl_bus_util_context=>bapi_refresh_buffers( 'HU' ).
        ENDIF.
        CALL FUNCTION 'BAPI_HU_DELETE'
          EXPORTING
            hukey  = iv_exidv
          TABLES
            return = et_bapiret.
        
      CATCH cx_root INTO lx_error.
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD call_pack.

    DATA lt_return TYPE bapirettab.
        DATA lx_error TYPE REF TO cx_root.

    CLEAR: ev_is_error, et_bapiret.

    TRY.
        IF iv_commit = abap_true.
          zabaputil_cl_bus_util_context=>bapi_refresh_buffers( 'HU' ).
        ENDIF.
        IF iv_unpack = abap_true.
          CALL FUNCTION 'BAPI_HU_UNPACK'
            EXPORTING
              hukey      = iv_exidv
              itemunpack = is_item
            TABLES
              return     = lt_return.
        ELSE.
          CALL FUNCTION 'BAPI_HU_PACK'
            EXPORTING
              hukey        = iv_exidv
              itemproposal = is_item
            TABLES
              return       = lt_return.
        ENDIF.
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
