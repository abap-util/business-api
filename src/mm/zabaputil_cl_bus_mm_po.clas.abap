CLASS zabaputil_cl_bus_mm_po DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES ty_t_item TYPE STANDARD TABLE OF bapimepoitem WITH DEFAULT KEY.
    TYPES ty_t_itemx TYPE STANDARD TABLE OF bapimepoitemx WITH DEFAULT KEY.

    "! Reads header and items of a purchase order (BAPI_PO_GETDETAIL1)
    CLASS-METHODS read
      IMPORTING
        iv_ebeln    TYPE ebeln
      EXPORTING
        es_header   TYPE bapimepoheader
        et_item     TYPE ty_t_item
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Changes a purchase order (BAPI_PO_CHANGE) - header and items with their X structures
    CLASS-METHODS change
      IMPORTING
        iv_ebeln    TYPE ebeln
        is_header   TYPE bapimepoheader OPTIONAL
        is_headerx  TYPE bapimepoheaderx OPTIONAL
        it_item     TYPE ty_t_item OPTIONAL
        it_itemx    TYPE ty_t_itemx OPTIONAL
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Sets (L) or removes the deletion indicator of a purchase order item
    CLASS-METHODS set_deletion_flag
      IMPORTING
        iv_ebeln    TYPE ebeln
        iv_ebelp    TYPE ebelp
        iv_flag     TYPE abap_bool DEFAULT abap_true
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zabaputil_cl_bus_mm_po IMPLEMENTATION.

  METHOD read.

    CLEAR: es_header, et_item, ev_is_error, et_bapiret.

    TRY.
        CALL FUNCTION 'BAPI_PO_GETDETAIL1'
          EXPORTING
            purchaseorder = iv_ebeln
          IMPORTING
            poheader      = es_header
          TABLES
            return        = et_bapiret
            poitem        = et_item.
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus=>msg_add_exception( EXPORTING ix_error   = lx_error
                                             CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus=>finish( CHANGING ct_bapiret  = et_bapiret
                                       cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD change.

    DATA lt_item  TYPE ty_t_item.
    DATA lt_itemx TYPE ty_t_itemx.

    CLEAR: ev_is_error, et_bapiret.

    TRY.
        lt_item  = it_item.
        lt_itemx = it_itemx.
        CALL FUNCTION 'BAPI_PO_CHANGE'
          EXPORTING
            purchaseorder = iv_ebeln
            poheader      = is_header
            poheaderx     = is_headerx
          TABLES
            return        = et_bapiret
            poitem        = lt_item
            poitemx       = lt_itemx.
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus=>msg_add_exception( EXPORTING ix_error   = lx_error
                                             CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus=>finish( EXPORTING iv_commit   = iv_commit
                              CHANGING  ct_bapiret  = et_bapiret
                                        cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD set_deletion_flag.

    change( EXPORTING iv_ebeln    = iv_ebeln
                      it_item     = VALUE #( ( po_item    = iv_ebelp
                                               delete_ind = COND #( WHEN iv_flag = abap_true THEN 'L' ELSE ' ' ) ) )
                      it_itemx    = VALUE #( ( po_item    = iv_ebelp
                                               po_itemx   = abap_true
                                               delete_ind = abap_true ) )
                      iv_commit   = iv_commit
            IMPORTING ev_is_error = ev_is_error
                      et_bapiret  = et_bapiret ).

  ENDMETHOD.

ENDCLASS.
