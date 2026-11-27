CLASS zabaputil_cl_bus_pm_notif DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES ty_t_item TYPE STANDARD TABLE OF bapi2080_notitemi WITH DEFAULT KEY.
    TYPES ty_t_item_e TYPE STANDARD TABLE OF bapi2080_notiteme WITH DEFAULT KEY.
    TYPES ty_t_task_e TYPE STANDARD TABLE OF bapi2080_nottaske WITH DEFAULT KEY.

    "! Creates and saves a maintenance notification (BAPI_ALM_NOTIF_CREATE + _SAVE)
    "! @parameter iv_qmart  | notification type
    "! @parameter is_header | SHORT_TEXT, EQUIPMENT, FUNCT_LOC, PRIORITY, ...
    CLASS-METHODS create
      IMPORTING
        iv_qmart    TYPE qmart
        is_header   TYPE bapi2080_nothdri
        it_item     TYPE ty_t_item OPTIONAL
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_qmnum    TYPE qmnum
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Reads a maintenance notification (BAPI_ALM_NOTIF_GET_DETAIL)
    CLASS-METHODS read
      IMPORTING
        iv_qmnum    TYPE qmnum
      EXPORTING
        es_header   TYPE bapi2080_nothdre
        et_item     TYPE ty_t_item_e
        et_task     TYPE ty_t_task_e
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Changes the header of a notification and saves it (BAPI_ALM_NOTIF_DATA_MODIFY + _SAVE)
    CLASS-METHODS change
      IMPORTING
        iv_qmnum    TYPE qmnum
        is_header   TYPE bapi2080_nothdri
        is_headerx  TYPE bapi2080_nothdri_x
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Completes a task of a notification and saves it (BAPI_ALM_NOTIF_TASK_COMPLETE + _SAVE)
    CLASS-METHODS complete_task
      IMPORTING
        iv_qmnum    TYPE qmnum
        iv_task_key TYPE clike
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Completes a notification and saves it (BAPI_ALM_NOTIF_CLOSE + _SAVE)
    CLASS-METHODS close
      IMPORTING
        iv_qmnum    TYPE qmnum
        iv_date     TYPE dats DEFAULT sy-datum
        iv_time     TYPE tims DEFAULT sy-uzeit
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

  PROTECTED SECTION.
  PRIVATE SECTION.

    "! saves the notification; a new one gets its final number here
    CLASS-METHODS save
      IMPORTING
        iv_qmnum   TYPE qmnum
      EXPORTING
        ev_qmnum   TYPE qmnum
      CHANGING
        ct_bapiret TYPE bapirettab.

ENDCLASS.



CLASS zabaputil_cl_bus_pm_notif IMPLEMENTATION.

  METHOD create.

    DATA ls_header_e TYPE bapi2080_nothdre.
    DATA lt_item     TYPE ty_t_item.

    CLEAR: ev_qmnum, ev_is_error, et_bapiret.

    TRY.
        lt_item = it_item.
        CALL FUNCTION 'BAPI_ALM_NOTIF_CREATE'
          EXPORTING
            notif_type         = iv_qmart
            notifheader        = is_header
          IMPORTING
            notifheader_export = ls_header_e
          TABLES
            notitem            = lt_item
            return             = et_bapiret.
        IF zabaputil_cl_bus_util_context=>bapi_check_is_error( et_bapiret ) = abap_false.
          save( EXPORTING iv_qmnum   = ls_header_e-notif_no
                IMPORTING ev_qmnum   = ev_qmnum
                CHANGING  ct_bapiret = et_bapiret ).
        ENDIF.
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    IF ev_qmnum IS INITIAL AND zabaputil_cl_bus_util_context=>bapi_check_is_error( et_bapiret ) = abap_false.
      zabaputil_cl_bus_util_context=>bapi_msg_add_text( EXPORTING iv_text    = 'No notification created'
                                                        CHANGING  ct_bapiret = et_bapiret ).
    ENDIF.
    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD read.

    CLEAR: es_header, et_item, et_task, ev_is_error, et_bapiret.

    TRY.
        CALL FUNCTION 'BAPI_ALM_NOTIF_GET_DETAIL'
          EXPORTING
            number             = iv_qmnum
          IMPORTING
            notifheader_export = es_header
          TABLES
            notitem            = et_item
            notiftask          = et_task
            return             = et_bapiret.
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( CHANGING ct_bapiret  = et_bapiret
                                                         cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD change.

    CLEAR: ev_is_error, et_bapiret.

    TRY.
        CALL FUNCTION 'BAPI_ALM_NOTIF_DATA_MODIFY'
          EXPORTING
            number        = iv_qmnum
            notifheader   = is_header
            notifheader_x = is_headerx
          TABLES
            return        = et_bapiret.
        IF zabaputil_cl_bus_util_context=>bapi_check_is_error( et_bapiret ) = abap_false.
          save( EXPORTING iv_qmnum   = iv_qmnum
                CHANGING  ct_bapiret = et_bapiret ).
        ENDIF.
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD complete_task.

    DATA lv_task_key TYPE c LENGTH 4.

    CLEAR: ev_is_error, et_bapiret.

    TRY.
        lv_task_key = iv_task_key.
        lv_task_key = |{ lv_task_key ALPHA = IN }|.
        CALL FUNCTION 'BAPI_ALM_NOTIF_TASK_COMPLETE'
          EXPORTING
            number   = iv_qmnum
            task_key = lv_task_key
          TABLES
            return   = et_bapiret.
        IF zabaputil_cl_bus_util_context=>bapi_check_is_error( et_bapiret ) = abap_false.
          save( EXPORTING iv_qmnum   = iv_qmnum
                CHANGING  ct_bapiret = et_bapiret ).
        ENDIF.
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD close.

    DATA ls_status TYPE bapi2080_notsti.

    CLEAR: ev_is_error, et_bapiret.

    TRY.
        ls_status-refdate = iv_date.
        ls_status-reftime = iv_time.
        ls_status-langu   = sy-langu.
        CALL FUNCTION 'BAPI_ALM_NOTIF_CLOSE'
          EXPORTING
            number   = iv_qmnum
            syststat = ls_status
          TABLES
            return   = et_bapiret.
        IF zabaputil_cl_bus_util_context=>bapi_check_is_error( et_bapiret ) = abap_false.
          save( EXPORTING iv_qmnum   = iv_qmnum
                CHANGING  ct_bapiret = et_bapiret ).
        ENDIF.
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD save.

    DATA lt_return TYPE bapirettab.
    DATA ls_header TYPE bapi2080_nothdre.

    CLEAR ev_qmnum.
    CALL FUNCTION 'BAPI_ALM_NOTIF_SAVE'
      EXPORTING
        number      = iv_qmnum
      IMPORTING
        notifheader = ls_header
      TABLES
        return      = lt_return.
    INSERT LINES OF lt_return INTO TABLE ct_bapiret.
    ev_qmnum = COND #( WHEN ls_header-notif_no IS NOT INITIAL THEN ls_header-notif_no ELSE iv_qmnum ).

  ENDMETHOD.

ENDCLASS.
