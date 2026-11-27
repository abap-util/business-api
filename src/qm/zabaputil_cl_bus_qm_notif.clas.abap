CLASS zabaputil_cl_bus_qm_notif DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES ty_t_item TYPE STANDARD TABLE OF bapi2078_notitemi WITH DEFAULT KEY.
    TYPES ty_t_item_e TYPE STANDARD TABLE OF bapi2078_notiteme WITH DEFAULT KEY.
    TYPES ty_t_task_e TYPE STANDARD TABLE OF bapi2078_nottaske WITH DEFAULT KEY.

    "! Creates and saves a quality notification (BAPI_QUALNOT_CREATE + _SAVE)
    "! @parameter is_header | SHORT_TEXT, MATERIAL, PLANT, BATCH, ...
    "! @parameter it_item   | the defects: D_CODEGRP, D_CODE, DESCRIPT, ...
    CLASS-METHODS create
      IMPORTING
        iv_qmart    TYPE qmart
        is_header   TYPE bapi2078_nothdri
        it_item     TYPE ty_t_item OPTIONAL
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_qmnum    TYPE qmnum
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Reads a quality notification (BAPI_QUALNOT_GETDETAIL)
    CLASS-METHODS read
      IMPORTING
        iv_qmnum    TYPE qmnum
      EXPORTING
        es_header   TYPE bapi2078_nothdre
        et_item     TYPE ty_t_item_e
        et_task     TYPE ty_t_task_e
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Adds defects to a quality notification and saves it (BAPI_QUALNOT_ADD_DATA + _SAVE)
    CLASS-METHODS add_defects
      IMPORTING
        iv_qmnum    TYPE qmnum
        it_item     TYPE ty_t_item
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



CLASS zabaputil_cl_bus_qm_notif IMPLEMENTATION.

  METHOD create.

    DATA ls_header_e TYPE bapi2078_nothdre.
    DATA lt_item     TYPE ty_t_item.

    CLEAR: ev_qmnum, ev_is_error, et_bapiret.

    TRY.
        lt_item = it_item.
        CALL FUNCTION 'BAPI_QUALNOT_CREATE'
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
      zabaputil_cl_bus_util_context=>bapi_msg_add_text( EXPORTING iv_text    = 'No quality notification created'
                                                        CHANGING  ct_bapiret = et_bapiret ).
    ENDIF.
    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD read.

    CLEAR: es_header, et_item, et_task, ev_is_error, et_bapiret.

    TRY.
        CALL FUNCTION 'BAPI_QUALNOT_GETDETAIL'
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

  METHOD add_defects.

    DATA lt_item  TYPE ty_t_item.
    DATA lv_qmnum TYPE qmnum.

    CLEAR: ev_is_error, et_bapiret.

    TRY.
        lt_item = it_item.
        CALL FUNCTION 'BAPI_QUALNOT_ADD_DATA'
          EXPORTING
            number  = iv_qmnum
          TABLES
            notitem = lt_item
            return  = et_bapiret.
        IF zabaputil_cl_bus_util_context=>bapi_check_is_error( et_bapiret ) = abap_false.
          save( EXPORTING iv_qmnum   = iv_qmnum
                IMPORTING ev_qmnum   = lv_qmnum
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
    DATA ls_header TYPE bapi2078_nothdre.

    CLEAR ev_qmnum.
    CALL FUNCTION 'BAPI_QUALNOT_SAVE'
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
