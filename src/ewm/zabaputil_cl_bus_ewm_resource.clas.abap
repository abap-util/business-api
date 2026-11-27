"! EWM resources. All /SCWM/ objects are reached dynamically, so the class
"! activates in systems without EWM and fails only when it is called there.
CLASS zabaputil_cl_bus_ewm_resource DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    "! Reads a resource (/SCWM/RSRC)
    "! @parameter er_resource | reference to the /SCWM/RSRC row
    CLASS-METHODS read
      IMPORTING
        iv_lgnum    TYPE clike
        iv_rsrc     TYPE clike
      EXPORTING
        er_resource TYPE REF TO data
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zabaputil_cl_bus_ewm_resource IMPLEMENTATION.

  METHOD read.

    DATA lv_table TYPE string VALUE '/SCWM/RSRC'.
    DATA lv_lgnum TYPE c LENGTH 4.
    DATA lv_rsrc  TYPE c LENGTH 18.
    FIELD-SYMBOLS <resource> TYPE any.
        DATA lx_error TYPE REF TO cx_root.

    CLEAR: er_resource, ev_is_error, et_bapiret.

    lv_lgnum = iv_lgnum.
    lv_rsrc  = iv_rsrc.

    TRY.
        CREATE DATA er_resource TYPE (lv_table).
        ASSIGN er_resource->* TO <resource>.
        SELECT SINGLE * FROM (lv_table) INTO <resource> WHERE lgnum = lv_lgnum AND rsrc = lv_rsrc.
        IF sy-subrc <> 0.
          CLEAR er_resource.
          zabaputil_cl_bus_util_context=>bapi_msg_add_text( EXPORTING iv_text    = |Resource { iv_rsrc } not found in warehouse { iv_lgnum }|
                                                            CHANGING  ct_bapiret = et_bapiret ).
        ENDIF.
        
      CATCH cx_root INTO lx_error.
        CLEAR er_resource.
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( CHANGING ct_bapiret  = et_bapiret
                                                         cv_is_error = ev_is_error ).

  ENDMETHOD.

ENDCLASS.
