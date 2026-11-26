CLASS zabaputil_cl_bus_pm_measure DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    "! Creates a measurement document for a measuring point (MEASUREM_DOCUM_RFC_SINGLE_001)
    "! @parameter iv_value | the reading as text, e.g. '12.5'
    CLASS-METHODS create
      IMPORTING
        iv_point    TYPE imrc_point
        iv_value    TYPE clike
        iv_unit     TYPE clike OPTIONAL
        iv_date     TYPE dats DEFAULT sy-datum
        iv_time     TYPE tims DEFAULT sy-uzeit
        iv_text     TYPE clike OPTIONAL
        iv_reader   TYPE clike DEFAULT sy-uname
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_mdocm    TYPE imrc_mdocm
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Reads the last valid measurement document of a measuring point
    CLASS-METHODS read_last
      IMPORTING
        iv_point    TYPE imrc_point
      EXPORTING
        es_imrg     TYPE imrg
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zabaputil_cl_bus_pm_measure IMPLEMENTATION.

  METHOD create.

    DATA lv_value  TYPE c LENGTH 22.
    DATA lv_unit   TYPE c LENGTH 3.
    DATA lv_text   TYPE c LENGTH 40.
    DATA lv_reader TYPE c LENGTH 12.

    CLEAR: ev_mdocm, ev_is_error, et_bapiret.

    TRY.
        lv_value  = iv_value.
        lv_unit   = iv_unit.
        lv_text   = iv_text.
        lv_reader = iv_reader.
        CALL FUNCTION 'MEASUREM_DOCUM_RFC_SINGLE_001'
          EXPORTING
            measurement_point    = iv_point
            reading_date         = iv_date
            reading_time         = iv_time
            short_text           = lv_text
            reader               = lv_reader
            recorded_value       = lv_value
            recorded_unit        = lv_unit
            with_dialog_screen   = abap_false
            prepare_update       = abap_true
            commit_work          = abap_false
          IMPORTING
            measurement_document = ev_mdocm
          EXCEPTIONS
            error_message        = 98
            OTHERS               = 99.
        IF sy-subrc <> 0.
          zabaputil_cl_bus=>msg_add_sy( EXPORTING iv_context = 'MEASUREM_DOCUM_RFC_SINGLE_001'
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

  METHOD read_last.

    DATA lt_imrg TYPE STANDARD TABLE OF imrg WITH DEFAULT KEY.

    SELECT * FROM imrg
      WHERE point = @iv_point AND cancl = @space
      ORDER BY idate DESCENDING, itime DESCENDING
      INTO TABLE @lt_imrg
      UP TO 1 ROWS.
    CLEAR: es_imrg, ev_is_error, et_bapiret.
    READ TABLE lt_imrg INTO es_imrg INDEX 1.
    IF sy-subrc <> 0.
      zabaputil_cl_bus=>msg_add_text( EXPORTING iv_text    = |No measurement document for measuring point { iv_point ALPHA = OUT }|
                                      CHANGING  ct_bapiret = et_bapiret ).
    ENDIF.

    zabaputil_cl_bus=>finish( CHANGING ct_bapiret  = et_bapiret
                                       cv_is_error = ev_is_error ).

  ENDMETHOD.

ENDCLASS.
