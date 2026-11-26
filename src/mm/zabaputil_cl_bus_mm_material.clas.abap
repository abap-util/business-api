CLASS zabaputil_cl_bus_mm_material DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    "! Reads the general data and, with iv_werks, the plant data of a material
    CLASS-METHODS read
      IMPORTING
        iv_matnr    TYPE matnr
        iv_werks    TYPE werks_d OPTIONAL
      EXPORTING
        es_mara     TYPE mara
        es_marc     TYPE marc
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Changes material master data (BAPI_MATERIAL_SAVEDATA) - the data
    "! structures with their X structures; MATERIAL in is_headdata is filled
    CLASS-METHODS change
      IMPORTING
        iv_matnr        TYPE matnr
        is_headdata     TYPE bapimathead OPTIONAL
        is_clientdata   TYPE bapi_mara OPTIONAL
        is_clientdatax  TYPE bapi_marax OPTIONAL
        is_plantdata    TYPE bapi_marc OPTIONAL
        is_plantdatax   TYPE bapi_marcx OPTIONAL
        iv_commit       TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error     TYPE abap_bool
        et_bapiret      TYPE bapirettab.

    "! Changes gross weight, net weight and weight unit
    CLASS-METHODS change_weight
      IMPORTING
        iv_matnr    TYPE matnr
        iv_brgew    TYPE brgew
        iv_ntgew    TYPE ntgew
        iv_gewei    TYPE gewei
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Changes the MRP controller of a material in a plant
    CLASS-METHODS change_mrp_controller
      IMPORTING
        iv_matnr    TYPE matnr
        iv_werks    TYPE werks_d
        iv_dispo    TYPE dispo
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Sets or removes the deletion flag - client wide, or in one plant with iv_werks
    CLASS-METHODS set_deletion_flag
      IMPORTING
        iv_matnr    TYPE matnr
        iv_werks    TYPE werks_d OPTIONAL
        iv_flag     TYPE abap_bool DEFAULT abap_true
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zabaputil_cl_bus_mm_material IMPLEMENTATION.

  METHOD read.

    CLEAR: es_mara, es_marc, ev_is_error, et_bapiret.

    SELECT SINGLE * FROM mara INTO @es_mara WHERE matnr = @iv_matnr.
    IF sy-subrc <> 0.
      zabaputil_cl_bus=>msg_add_text( EXPORTING iv_text    = |Material { iv_matnr } not found|
                                      CHANGING  ct_bapiret = et_bapiret ).
    ELSEIF iv_werks IS NOT INITIAL.
      SELECT SINGLE * FROM marc INTO @es_marc WHERE matnr = @iv_matnr AND werks = @iv_werks.
      IF sy-subrc <> 0.
        zabaputil_cl_bus=>msg_add_text( EXPORTING iv_text    = |Material { iv_matnr } not found in plant { iv_werks }|
                                        CHANGING  ct_bapiret = et_bapiret ).
      ENDIF.
    ENDIF.

    zabaputil_cl_bus=>finish( CHANGING ct_bapiret  = et_bapiret
                                       cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD change.

    DATA ls_headdata TYPE bapimathead.
    DATA ls_return   TYPE bapiret2.
    DATA lt_messages TYPE STANDARD TABLE OF bapi_matreturn2 WITH DEFAULT KEY.

    CLEAR: ev_is_error, et_bapiret.

    TRY.
        ls_headdata = is_headdata.
        zabaputil_cl_bus=>set_material( EXPORTING iv_matnr = iv_matnr
                                        CHANGING  cs_data  = ls_headdata ).
        CALL FUNCTION 'BAPI_MATERIAL_SAVEDATA'
          EXPORTING
            headdata       = ls_headdata
            clientdata     = is_clientdata
            clientdatax    = is_clientdatax
            plantdata      = is_plantdata
            plantdatax     = is_plantdatax
          IMPORTING
            return         = ls_return
          TABLES
            returnmessages = lt_messages.
        zabaputil_cl_bus=>msg_add_table( EXPORTING it_table   = lt_messages
                                         CHANGING  ct_bapiret = et_bapiret ).
        IF zabaputil_cl_bus=>check_is_error( et_bapiret ) = abap_false.
          zabaputil_cl_bus=>msg_add_bapiret2( EXPORTING is_return  = ls_return
                                              CHANGING  ct_bapiret = et_bapiret ).
        ENDIF.
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus=>msg_add_exception( EXPORTING ix_error   = lx_error
                                             CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus=>finish( EXPORTING iv_commit   = iv_commit
                              CHANGING  ct_bapiret  = et_bapiret
                                        cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD change_weight.

    DATA ls_headdata    TYPE bapimathead.
    DATA ls_clientdata  TYPE bapi_mara.
    DATA ls_clientdatax TYPE bapi_marax.

    ls_headdata-basic_view   = abap_true.
    ls_clientdata-gross_wt   = iv_brgew.
    ls_clientdata-net_weight = iv_ntgew.
    ls_clientdata-unit_of_wt = iv_gewei.
    ls_clientdatax-gross_wt   = abap_true.
    ls_clientdatax-net_weight = abap_true.
    ls_clientdatax-unit_of_wt = abap_true.

    change( EXPORTING iv_matnr       = iv_matnr
                      is_headdata    = ls_headdata
                      is_clientdata  = ls_clientdata
                      is_clientdatax = ls_clientdatax
                      iv_commit      = iv_commit
            IMPORTING ev_is_error    = ev_is_error
                      et_bapiret     = et_bapiret ).

  ENDMETHOD.

  METHOD change_mrp_controller.

    DATA ls_headdata   TYPE bapimathead.
    DATA ls_plantdata  TYPE bapi_marc.
    DATA ls_plantdatax TYPE bapi_marcx.

    ls_headdata-mrp_view    = abap_true.
    ls_plantdata-plant      = iv_werks.
    ls_plantdata-mrp_ctrler = iv_dispo.
    ls_plantdatax-plant      = iv_werks.
    ls_plantdatax-mrp_ctrler = abap_true.

    change( EXPORTING iv_matnr      = iv_matnr
                      is_headdata   = ls_headdata
                      is_plantdata  = ls_plantdata
                      is_plantdatax = ls_plantdatax
                      iv_commit     = iv_commit
            IMPORTING ev_is_error   = ev_is_error
                      et_bapiret    = et_bapiret ).

  ENDMETHOD.

  METHOD set_deletion_flag.

    DATA ls_headdata    TYPE bapimathead.
    DATA ls_clientdata  TYPE bapi_mara.
    DATA ls_clientdatax TYPE bapi_marax.
    DATA ls_plantdata   TYPE bapi_marc.
    DATA ls_plantdatax  TYPE bapi_marcx.

    IF iv_werks IS INITIAL.
      ls_headdata-basic_view   = abap_true.
      ls_clientdata-del_flag   = iv_flag.
      ls_clientdatax-del_flag  = abap_true.
      change( EXPORTING iv_matnr       = iv_matnr
                        is_headdata    = ls_headdata
                        is_clientdata  = ls_clientdata
                        is_clientdatax = ls_clientdatax
                        iv_commit      = iv_commit
              IMPORTING ev_is_error    = ev_is_error
                        et_bapiret     = et_bapiret ).
    ELSE.
      ls_headdata-mrp_view     = abap_true.
      ls_plantdata-plant       = iv_werks.
      ls_plantdata-del_flag    = iv_flag.
      ls_plantdatax-plant      = iv_werks.
      ls_plantdatax-del_flag   = abap_true.
      change( EXPORTING iv_matnr      = iv_matnr
                        is_headdata   = ls_headdata
                        is_plantdata  = ls_plantdata
                        is_plantdatax = ls_plantdatax
                        iv_commit     = iv_commit
              IMPORTING ev_is_error   = ev_is_error
                        et_bapiret    = et_bapiret ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
