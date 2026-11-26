CLASS zabaputil_cl_bus_pm_equipment DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    "! Creates an equipment (BAPI_EQUI_CREATE)
    "! @parameter iv_equnr    | external number, initial: from the number range
    "! @parameter is_general  | DESCRIPT, MANFACTURE, OBJECTTYPE, PLANPLANT, ...
    "! @parameter is_specific | EQUICATGRY, MATERIAL, SERIALNO, ...
    CLASS-METHODS create
      IMPORTING
        iv_equnr    TYPE equnr OPTIONAL
        is_general  TYPE bapi_itob
        is_specific TYPE bapi_itob_eq_only
        iv_date     TYPE dats DEFAULT sy-datum
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_equnr    TYPE equnr
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Reads an equipment (BAPI_EQUI_GETDETAIL)
    CLASS-METHODS read
      IMPORTING
        iv_equnr    TYPE equnr
      EXPORTING
        es_general  TYPE bapi_itob
        es_specific TYPE bapi_itob_eq_only
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Changes an equipment (BAPI_EQUI_CHANGE) - data with their X structures
    CLASS-METHODS change
      IMPORTING
        iv_equnr     TYPE equnr
        is_general   TYPE bapi_itob OPTIONAL
        is_generalx  TYPE bapi_itobx OPTIONAL
        is_specific  TYPE bapi_itob_eq_only OPTIONAL
        is_specificx TYPE bapi_itob_eq_onlyx OPTIONAL
        iv_date      TYPE dats DEFAULT sy-datum
        iv_commit    TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error  TYPE abap_bool
        et_bapiret   TYPE bapirettab.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zabaputil_cl_bus_pm_equipment IMPLEMENTATION.

  METHOD create.

    DATA ls_return TYPE bapiret2.

    CLEAR: ev_equnr, ev_is_error, et_bapiret.

    TRY.
        CALL FUNCTION 'BAPI_EQUI_CREATE'
          EXPORTING
            external_number = iv_equnr
            data_general    = is_general
            data_specific   = is_specific
            valid_date      = iv_date
          IMPORTING
            equipment       = ev_equnr
            return          = ls_return.
        zabaputil_cl_bus=>msg_add_bapiret2( EXPORTING is_return  = ls_return
                                            CHANGING  ct_bapiret = et_bapiret ).
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus=>msg_add_exception( EXPORTING ix_error   = lx_error
                                             CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus=>finish( EXPORTING iv_commit   = iv_commit
                              CHANGING  ct_bapiret  = et_bapiret
                                        cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD read.

    DATA ls_return TYPE bapiret2.

    CLEAR: es_general, es_specific, ev_is_error, et_bapiret.

    TRY.
        CALL FUNCTION 'BAPI_EQUI_GETDETAIL'
          EXPORTING
            equipment         = iv_equnr
          IMPORTING
            data_general_exp  = es_general
            data_specific_exp = es_specific
            return            = ls_return.
        zabaputil_cl_bus=>msg_add_bapiret2( EXPORTING is_return  = ls_return
                                            CHANGING  ct_bapiret = et_bapiret ).
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus=>msg_add_exception( EXPORTING ix_error   = lx_error
                                             CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus=>finish( CHANGING ct_bapiret  = et_bapiret
                                       cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD change.

    DATA ls_return TYPE bapiret2.

    CLEAR: ev_is_error, et_bapiret.

    TRY.
        CALL FUNCTION 'BAPI_EQUI_CHANGE'
          EXPORTING
            equipment      = iv_equnr
            data_general   = is_general
            data_generalx  = is_generalx
            data_specific  = is_specific
            data_specificx = is_specificx
            valid_date     = iv_date
          IMPORTING
            return         = ls_return.
        zabaputil_cl_bus=>msg_add_bapiret2( EXPORTING is_return  = ls_return
                                            CHANGING  ct_bapiret = et_bapiret ).
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus=>msg_add_exception( EXPORTING ix_error   = lx_error
                                             CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus=>finish( EXPORTING iv_commit   = iv_commit
                              CHANGING  ct_bapiret  = et_bapiret
                                        cv_is_error = ev_is_error ).

  ENDMETHOD.

ENDCLASS.
