CLASS zabaputil_cl_bus_mm_inventory DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES ty_t_create_item TYPE STANDARD TABLE OF bapi_physinv_create_items WITH DEFAULT KEY.
    TYPES ty_t_count_item TYPE STANDARD TABLE OF bapi_physinv_count_items WITH DEFAULT KEY.

    "! Creates a physical inventory document (BAPI_MATPHYSINV_CREATE)
    "! @parameter is_header | PLANT, STGE_LOC, DOC_DATE, PLAN_DATE, ...
    "! @parameter it_item   | MATERIAL, BATCH, ...
    CLASS-METHODS create
      IMPORTING
        is_header   TYPE bapi_physinv_create_head
        it_item     TYPE ty_t_create_item
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_iblnr    TYPE iblnr
        ev_gjahr    TYPE gjahr
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Enters a count for a physical inventory document (BAPI_MATPHYSINV_COUNT)
    "! @parameter it_item | ITEM, MATERIAL, BATCH, ENTRY_QNT, ENTRY_UOM, ZERO_COUNT
    CLASS-METHODS count
      IMPORTING
        iv_iblnr    TYPE iblnr
        iv_gjahr    TYPE gjahr
        iv_date     TYPE dats DEFAULT sy-datum
        it_item     TYPE ty_t_count_item
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Posts the differences of a counted document (BAPI_MATPHYSINV_POSTDIFF)
    "! @parameter ev_mblnr | the material document of the posting
    "! @parameter ev_mjahr | its year: the year of the posting date, as for every material document
    CLASS-METHODS post_differences
      IMPORTING
        iv_iblnr    TYPE iblnr
        iv_gjahr    TYPE gjahr
        iv_budat    TYPE budat DEFAULT sy-datum
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_mblnr    TYPE mblnr
        ev_mjahr    TYPE mjahr
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zabaputil_cl_bus_mm_inventory IMPLEMENTATION.

  METHOD create.

    DATA lt_item TYPE ty_t_create_item.
    DATA ls_head TYPE bapi_physinv_create_head.
        DATA lx_error TYPE REF TO cx_root.

    CLEAR: ev_iblnr, ev_gjahr, ev_is_error, et_bapiret.

    TRY.
        lt_item = it_item.
        ls_head = is_header.
        CALL FUNCTION 'BAPI_MATPHYSINV_CREATE'
          EXPORTING
            head          = ls_head
          IMPORTING
            physinventory = ev_iblnr
            fiscalyear    = ev_gjahr
          TABLES
            items         = lt_item
            return        = et_bapiret.
        
      CATCH cx_root INTO lx_error.
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    IF ev_iblnr IS INITIAL AND zabaputil_cl_bus_util_context=>bapi_check_is_error( et_bapiret ) = abap_false.
      zabaputil_cl_bus_util_context=>bapi_msg_add_text( EXPORTING iv_text    = 'No physical inventory document created'
                                                        CHANGING  ct_bapiret = et_bapiret ).
    ENDIF.
    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD count.

    DATA lt_item TYPE ty_t_count_item.
        DATA lx_error TYPE REF TO cx_root.

    CLEAR: ev_is_error, et_bapiret.

    TRY.
        lt_item = it_item.
        CALL FUNCTION 'BAPI_MATPHYSINV_COUNT'
          EXPORTING
            physinventory = iv_iblnr
            fiscalyear    = iv_gjahr
            count_date    = iv_date
          TABLES
            items         = lt_item
            return        = et_bapiret.
        
      CATCH cx_root INTO lx_error.
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD post_differences.
        DATA lx_error TYPE REF TO cx_root.
      DATA temp1 LIKE ev_mjahr.

    CLEAR: ev_mblnr, ev_mjahr, ev_is_error, et_bapiret.

    TRY.
        CALL FUNCTION 'BAPI_MATPHYSINV_POSTDIFF'
          EXPORTING
            physinventory    = iv_iblnr
            fiscalyear       = iv_gjahr
            pstng_date       = iv_budat
          IMPORTING
            materialdocument = ev_mblnr
          TABLES
            return           = et_bapiret.
        
      CATCH cx_root INTO lx_error.
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    IF ev_mblnr IS INITIAL AND zabaputil_cl_bus_util_context=>bapi_check_is_error( et_bapiret ) = abap_false.
      zabaputil_cl_bus_util_context=>bapi_msg_add_text( EXPORTING iv_text    = 'No material document created'
                                                        CHANGING  ct_bapiret = et_bapiret ).
    ELSEIF ev_mblnr IS NOT INITIAL.
      " a material document is numbered in the year of its posting date
      
      IF iv_budat IS INITIAL.
        temp1 = sy-datum(4).
      ELSE.
        temp1 = iv_budat(4).
      ENDIF.
      ev_mjahr = temp1.
    ENDIF.
    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

ENDCLASS.
