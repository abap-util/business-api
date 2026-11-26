CLASS zabaputil_cl_bus_ca_classif DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES ty_t_num TYPE STANDARD TABLE OF bapi1003_alloc_values_num WITH DEFAULT KEY.
    TYPES ty_t_char TYPE STANDARD TABLE OF bapi1003_alloc_values_char WITH DEFAULT KEY.
    TYPES ty_t_curr TYPE STANDARD TABLE OF bapi1003_alloc_values_curr WITH DEFAULT KEY.

    "! Reads the characteristic values of an object in a class (BAPI_OBJCL_GETDETAIL)
    "! @parameter iv_objectkey   | object key, e.g. the material number
    "! @parameter iv_objecttable | object table, e.g. MARA, MCH1 (batch)
    "! @parameter iv_classtype   | class type, e.g. 001 material, 023 batch
    CLASS-METHODS read
      IMPORTING
        iv_objectkey   TYPE clike
        iv_objecttable TYPE clike
        iv_classnum    TYPE clike
        iv_classtype   TYPE clike
      EXPORTING
        et_num         TYPE ty_t_num
        et_char        TYPE ty_t_char
        et_curr        TYPE ty_t_curr
        ev_is_error    TYPE abap_bool
        et_bapiret     TYPE bapirettab.

    "! Replaces the characteristic values of an object in a class (BAPI_OBJCL_CHANGE) -
    "! pass all values the object shall have, values not passed are removed
    CLASS-METHODS change
      IMPORTING
        iv_objectkey   TYPE clike
        iv_objecttable TYPE clike
        iv_classnum    TYPE clike
        iv_classtype   TYPE clike
        it_num         TYPE ty_t_num OPTIONAL
        it_char        TYPE ty_t_char OPTIONAL
        it_curr        TYPE ty_t_curr OPTIONAL
        iv_commit      TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error    TYPE abap_bool
        et_bapiret     TYPE bapirettab.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zabaputil_cl_bus_ca_classif IMPLEMENTATION.

  METHOD read.

    DATA lv_objectkey   TYPE c LENGTH 50.
    DATA lv_objecttable TYPE c LENGTH 30.
    DATA lv_classnum    TYPE c LENGTH 18.
    DATA lv_classtype   TYPE c LENGTH 3.

    CLEAR: et_num, et_char, et_curr, ev_is_error, et_bapiret.

    TRY.
        lv_objectkey   = iv_objectkey.
        lv_objecttable = iv_objecttable.
        lv_classnum    = iv_classnum.
        lv_classtype   = iv_classtype.
        CALL FUNCTION 'BAPI_OBJCL_GETDETAIL'
          EXPORTING
            objectkey       = lv_objectkey
            objecttable     = lv_objecttable
            classnum        = lv_classnum
            classtype       = lv_classtype
            keydate         = sy-datum
            language        = sy-langu
          TABLES
            allocvaluesnum  = et_num
            allocvalueschar = et_char
            allocvaluescurr = et_curr
            return          = et_bapiret.
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus=>msg_add_exception( EXPORTING ix_error   = lx_error
                                             CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus=>finish( CHANGING ct_bapiret  = et_bapiret
                                       cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD change.

    DATA lv_objectkey   TYPE c LENGTH 50.
    DATA lv_objecttable TYPE c LENGTH 30.
    DATA lv_classnum    TYPE c LENGTH 18.
    DATA lv_classtype   TYPE c LENGTH 3.
    DATA lt_num         TYPE ty_t_num.
    DATA lt_char        TYPE ty_t_char.
    DATA lt_curr        TYPE ty_t_curr.

    CLEAR: ev_is_error, et_bapiret.

    TRY.
        lv_objectkey   = iv_objectkey.
        lv_objecttable = iv_objecttable.
        lv_classnum    = iv_classnum.
        lv_classtype   = iv_classtype.
        lt_num  = it_num.
        lt_char = it_char.
        lt_curr = it_curr.
        CALL FUNCTION 'BAPI_OBJCL_CHANGE'
          EXPORTING
            objectkey          = lv_objectkey
            objecttable        = lv_objecttable
            classnum           = lv_classnum
            classtype          = lv_classtype
            status             = '1'
            keydate            = sy-datum
          TABLES
            allocvaluesnumnew  = lt_num
            allocvaluescharnew = lt_char
            allocvaluescurrnew = lt_curr
            return             = et_bapiret.
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus=>msg_add_exception( EXPORTING ix_error   = lx_error
                                             CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus=>finish( EXPORTING iv_commit   = iv_commit
                              CHANGING  ct_bapiret  = et_bapiret
                                        cv_is_error = ev_is_error ).

  ENDMETHOD.

ENDCLASS.
