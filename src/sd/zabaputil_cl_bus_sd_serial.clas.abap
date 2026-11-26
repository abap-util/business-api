CLASS zabaputil_cl_bus_sd_serial DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_s_serial,
        posnr TYPE posnr_vl,
        matnr TYPE matnr,
        sernr TYPE gernr,
      END OF ty_s_serial.
    TYPES ty_t_serial TYPE STANDARD TABLE OF ty_s_serial WITH DEFAULT KEY.

    "! Reads the equipment master record of a serial number
    CLASS-METHODS read
      IMPORTING
        iv_matnr    TYPE matnr
        iv_sernr    TYPE gernr
      EXPORTING
        es_equi     TYPE equi
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Reads the serial numbers assigned to a delivery (all items or one)
    CLASS-METHODS read_by_delivery
      IMPORTING
        iv_vbeln    TYPE vbeln_vl
        iv_posnr    TYPE posnr_vl OPTIONAL
      EXPORTING
        et_serial   TYPE ty_t_serial
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zabaputil_cl_bus_sd_serial IMPLEMENTATION.

  METHOD read.

    CLEAR: es_equi, ev_is_error, et_bapiret.

    SELECT SINGLE * FROM equi INTO @es_equi WHERE matnr = @iv_matnr AND sernr = @iv_sernr ##WARN_OK.
    IF sy-subrc <> 0.
      zabaputil_cl_bus=>msg_add_text( EXPORTING iv_text    = |Serial number { iv_sernr } of material { iv_matnr } not found|
                                      CHANGING  ct_bapiret = et_bapiret ).
    ENDIF.

    zabaputil_cl_bus=>finish( CHANGING ct_bapiret  = et_bapiret
                                       cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD read_by_delivery.

    CLEAR: et_serial, ev_is_error, et_bapiret.

    IF iv_posnr IS INITIAL.
      SELECT ser01~posnr, objk~matnr, objk~sernr
        FROM ser01 INNER JOIN objk ON objk~obknr = ser01~obknr
        WHERE ser01~lief_nr = @iv_vbeln
        ORDER BY ser01~posnr, objk~sernr
        INTO TABLE @et_serial.
    ELSE.
      SELECT ser01~posnr, objk~matnr, objk~sernr
        FROM ser01 INNER JOIN objk ON objk~obknr = ser01~obknr
        WHERE ser01~lief_nr = @iv_vbeln AND ser01~posnr = @iv_posnr
        ORDER BY ser01~posnr, objk~sernr
        INTO TABLE @et_serial.
    ENDIF.

    zabaputil_cl_bus=>finish( CHANGING ct_bapiret  = et_bapiret
                                       cv_is_error = ev_is_error ).

  ENDMETHOD.

ENDCLASS.
