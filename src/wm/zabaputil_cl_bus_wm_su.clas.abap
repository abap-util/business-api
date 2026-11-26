CLASS zabaputil_cl_bus_wm_su DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES ty_t_lqua TYPE STANDARD TABLE OF lqua WITH DEFAULT KEY.

    "! Reads a storage unit and the quants on it
    CLASS-METHODS read
      IMPORTING
        iv_lenum    TYPE lenum
      EXPORTING
        es_lein     TYPE lein
        et_lqua     TYPE ty_t_lqua
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Moves a storage unit to another bin (L_TO_CREATE_MOVE_SU)
    CLASS-METHODS move
      IMPORTING
        iv_lenum    TYPE lenum
        iv_bwlvs    TYPE bwlvs
        iv_nltyp    TYPE ltap_nltyp
        iv_nlpla    TYPE ltap_nlpla
        iv_squit    TYPE abap_bool DEFAULT abap_false
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_tanum    TYPE tanum
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zabaputil_cl_bus_wm_su IMPLEMENTATION.

  METHOD read.

    CLEAR: es_lein, et_lqua, ev_is_error, et_bapiret.

    SELECT SINGLE * FROM lein INTO @es_lein WHERE lenum = @iv_lenum.
    IF sy-subrc <> 0.
      zabaputil_cl_bus=>msg_add_text( EXPORTING iv_text    = |Storage unit { iv_lenum ALPHA = OUT } not found|
                                      CHANGING  ct_bapiret = et_bapiret ).
    ELSE.
      SELECT * FROM lqua INTO TABLE @et_lqua WHERE lgnum = @es_lein-lgnum AND lenum = @iv_lenum ORDER BY lqnum.
    ENDIF.

    zabaputil_cl_bus=>finish( CHANGING ct_bapiret  = et_bapiret
                                       cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD move.

    CLEAR: ev_tanum, ev_is_error, et_bapiret.

    TRY.
        CALL FUNCTION 'L_TO_CREATE_MOVE_SU'
          EXPORTING
            i_lenum       = iv_lenum
            i_bwlvs       = iv_bwlvs
            i_nltyp       = iv_nltyp
            i_nlpla       = iv_nlpla
            i_squit       = iv_squit
            i_commit_work = abap_false
          IMPORTING
            e_tanum       = ev_tanum
          EXCEPTIONS
            error_message = 98
            OTHERS        = 99.
        IF sy-subrc <> 0.
          zabaputil_cl_bus=>msg_add_sy( EXPORTING iv_context = 'L_TO_CREATE_MOVE_SU'
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

ENDCLASS.
