CLASS zabaputil_cl_bus_ca_status DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES ty_t_jstat TYPE STANDARD TABLE OF jstat WITH DEFAULT KEY.

    "! Reads the active statuses of an object (STATUS_READ) and their texts (STATUS_TEXT_EDIT)
    "! @parameter iv_objnr | object number, e.g. OR000001000123 for a production order
    CLASS-METHODS read
      IMPORTING
        iv_objnr       TYPE j_objnr
      EXPORTING
        et_status      TYPE ty_t_jstat
        ev_text_system TYPE string
        ev_text_user   TYPE string
        ev_is_error    TYPE abap_bool
        et_bapiret     TYPE bapirettab.

    "! abap_true if a system or user status is active for the object
    CLASS-METHODS check_is_set
      IMPORTING
        iv_objnr         TYPE j_objnr
        iv_stat          TYPE j_status
      RETURNING
        VALUE(rv_result) TYPE abap_bool.

    "! Sets or resets a user status (STATUS_CHANGE_EXTERN) and registers the
    "! update of the status buffer for the next commit (STATUS_UPDATE_ON_COMMIT)
    "! @parameter iv_inactive | abap_true: reset the status
    CLASS-METHODS set_user_status
      IMPORTING
        iv_objnr    TYPE j_objnr
        iv_stat     TYPE j_status
        iv_inactive TYPE abap_bool DEFAULT abap_false
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zabaputil_cl_bus_ca_status IMPLEMENTATION.

  METHOD read.

    DATA lv_line      TYPE c LENGTH 40.
    DATA lv_user_line TYPE c LENGTH 40.

    CLEAR: et_status, ev_text_system, ev_text_user, ev_is_error, et_bapiret.

    TRY.
        " a plain RAISE in the module would leave an older message in sy-msg
        CLEAR: sy-msgid, sy-msgno.
        CALL FUNCTION 'STATUS_READ'
          EXPORTING
            objnr            = iv_objnr
            only_active      = abap_true
          TABLES
            status           = et_status
          EXCEPTIONS
            error_message    = 98
            OTHERS           = 99.
        IF sy-subrc <> 0.
          zabaputil_cl_bus_util_context=>bapi_msg_add_sy( EXPORTING iv_context = 'STATUS_READ'
                                                          CHANGING  ct_bapiret = et_bapiret ).
        ELSE.
          CALL FUNCTION 'STATUS_TEXT_EDIT'
            EXPORTING
              objnr         = iv_objnr
              spras         = sy-langu
              flg_user_stat = abap_true
            IMPORTING
              line          = lv_line
              user_line     = lv_user_line
            EXCEPTIONS
              error_message = 98
              OTHERS        = 99.
          IF sy-subrc = 0.
            ev_text_system = lv_line.
            ev_text_user   = lv_user_line.
          ENDIF.
        ENDIF.
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( CHANGING ct_bapiret  = et_bapiret
                                                         cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD check_is_set.

    DATA lv_objnr TYPE j_objnr.

    SELECT SINGLE objnr FROM jest INTO @lv_objnr
      WHERE objnr = @iv_objnr AND stat = @iv_stat AND inact = @space.
    rv_result = xsdbool( sy-subrc = 0 ).

  ENDMETHOD.

  METHOD set_user_status.

    CLEAR: ev_is_error, et_bapiret.

    TRY.
        CLEAR: sy-msgid, sy-msgno.
        CALL FUNCTION 'STATUS_CHANGE_EXTERN'
          EXPORTING
            objnr         = iv_objnr
            user_status   = iv_stat
            set_inact     = iv_inactive
          EXCEPTIONS
            error_message = 98
            OTHERS        = 99.
        IF sy-subrc <> 0.
          zabaputil_cl_bus_util_context=>bapi_msg_add_sy( EXPORTING iv_context = 'STATUS_CHANGE_EXTERN'
                                                          CHANGING  ct_bapiret = et_bapiret ).
        ELSE.
          " the change only sits in the status buffer - this writes it with the commit
          CLEAR: sy-msgid, sy-msgno.
          CALL FUNCTION 'STATUS_UPDATE_ON_COMMIT'
            EXCEPTIONS
              error_message = 98
              OTHERS        = 99.
          IF sy-subrc <> 0.
            zabaputil_cl_bus_util_context=>bapi_msg_add_sy( EXPORTING iv_context = 'STATUS_UPDATE_ON_COMMIT'
                                                            CHANGING  ct_bapiret = et_bapiret ).
          ENDIF.
        ENDIF.
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

ENDCLASS.
