CLASS zabaputil_cl_bus_ca_classif DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES ty_t_num TYPE STANDARD TABLE OF bapi1003_alloc_values_num WITH DEFAULT KEY.
    TYPES ty_t_char TYPE STANDARD TABLE OF bapi1003_alloc_values_char WITH DEFAULT KEY.
    TYPES ty_t_curr TYPE STANDARD TABLE OF bapi1003_alloc_values_curr WITH DEFAULT KEY.

    "! Reads the characteristic values of an object in a class (BAPI_OBJCL_GETDETAIL)
    "! @parameter iv_objectkey   | object key, e.g. the material number; a key longer than
    "!                             50 characters is passed in OBJECTKEY_LONG (S/4HANA)
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
    "! pass all values the object shall have, values not passed are removed.
    "! A key longer than 50 characters is passed in OBJECTKEY_LONG (S/4HANA).
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

    "! calls a BAPI_OBJCL_* module with a key longer than OBJECTKEY (50 characters),
    "! e.g. a batch of a 40-character material number, in OBJECTKEY_LONG. Where the
    "! module has no such parameter the call fails with a message, never with a cut key.
    "! @parameter it_param | every parameter but OBJECTKEY_LONG and RETURN
    CLASS-METHODS call_with_long_key
      IMPORTING
        iv_function  TYPE clike
        iv_objectkey TYPE clike
        it_param     TYPE abap_func_parmbind_tab
      CHANGING
        ct_bapiret   TYPE bapirettab.

ENDCLASS.



CLASS zabaputil_cl_bus_ca_classif IMPLEMENTATION.

  METHOD read.

    DATA lv_objectkey   TYPE c LENGTH 50.
    DATA lv_objecttable TYPE c LENGTH 30.
    DATA lv_classnum    TYPE c LENGTH 18.
    DATA lv_classtype   TYPE c LENGTH 3.
    DATA lv_keydate     TYPE d.
    DATA lv_language    TYPE sy-langu.
          DATA temp1 LIKE REF TO et_curr.
DATA temp2 LIKE REF TO et_char.
DATA temp3 LIKE REF TO et_num.
DATA temp4 LIKE REF TO lv_language.
DATA temp5 LIKE REF TO lv_keydate.
DATA temp6 LIKE REF TO lv_classtype.
DATA temp7 LIKE REF TO lv_classnum.
DATA temp8 LIKE REF TO lv_objecttable.
DATA temp9 TYPE abap_func_parmbind_tab.
DATA temp10 LIKE LINE OF temp9.
        DATA lx_error TYPE REF TO cx_root.

    CLEAR: et_num, et_char, et_curr, ev_is_error, et_bapiret.

    TRY.
        lv_objectkey   = iv_objectkey.
        lv_objecttable = iv_objecttable.
        lv_classnum    = iv_classnum.
        lv_classtype   = iv_classtype.
        lv_keydate     = sy-datum.
        lv_language    = sy-langu.
        IF strlen( iv_objectkey ) > 50.
          
          GET REFERENCE OF et_curr INTO temp1.

GET REFERENCE OF et_char INTO temp2.

GET REFERENCE OF et_num INTO temp3.

GET REFERENCE OF lv_language INTO temp4.

GET REFERENCE OF lv_keydate INTO temp5.

GET REFERENCE OF lv_classtype INTO temp6.

GET REFERENCE OF lv_classnum INTO temp7.

GET REFERENCE OF lv_objecttable INTO temp8.

CLEAR temp9.

temp10-name = 'OBJECTTABLE'.
temp10-kind = abap_func_exporting.
temp10-value = temp8.
INSERT temp10 INTO TABLE temp9.
temp10-name = 'CLASSNUM'.
temp10-kind = abap_func_exporting.
temp10-value = temp7.
INSERT temp10 INTO TABLE temp9.
temp10-name = 'CLASSTYPE'.
temp10-kind = abap_func_exporting.
temp10-value = temp6.
INSERT temp10 INTO TABLE temp9.
temp10-name = 'KEYDATE'.
temp10-kind = abap_func_exporting.
temp10-value = temp5.
INSERT temp10 INTO TABLE temp9.
temp10-name = 'LANGUAGE'.
temp10-kind = abap_func_exporting.
temp10-value = temp4.
INSERT temp10 INTO TABLE temp9.
temp10-name = 'ALLOCVALUESNUM'.
temp10-kind = abap_func_tables.
temp10-value = temp3.
INSERT temp10 INTO TABLE temp9.
temp10-name = 'ALLOCVALUESCHAR'.
temp10-kind = abap_func_tables.
temp10-value = temp2.
INSERT temp10 INTO TABLE temp9.
temp10-name = 'ALLOCVALUESCURR'.
temp10-kind = abap_func_tables.
temp10-value = temp1.
INSERT temp10 INTO TABLE temp9.
call_with_long_key( EXPORTING iv_function  = 'BAPI_OBJCL_GETDETAIL'
                                        iv_objectkey = iv_objectkey
                                        it_param     = temp9
                              CHANGING  ct_bapiret   = et_bapiret ).
        ELSE.
          CALL FUNCTION 'BAPI_OBJCL_GETDETAIL'
            EXPORTING
              objectkey       = lv_objectkey
              objecttable     = lv_objecttable
              classnum        = lv_classnum
              classtype       = lv_classtype
              keydate         = lv_keydate
              language        = lv_language
            TABLES
              allocvaluesnum  = et_num
              allocvalueschar = et_char
              allocvaluescurr = et_curr
              return          = et_bapiret.
        ENDIF.
        
      CATCH cx_root INTO lx_error.
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( CHANGING ct_bapiret  = et_bapiret
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
    DATA lv_status      TYPE c LENGTH 1 VALUE '1'.
    DATA lv_keydate     TYPE d.
          DATA temp2 LIKE REF TO lt_curr.
DATA temp3 LIKE REF TO lt_char.
DATA temp4 LIKE REF TO lt_num.
DATA temp5 LIKE REF TO lv_keydate.
DATA temp6 LIKE REF TO lv_status.
DATA temp7 LIKE REF TO lv_classtype.
DATA temp8 LIKE REF TO lv_classnum.
DATA temp9 LIKE REF TO lv_objecttable.
DATA temp11 TYPE abap_func_parmbind_tab.
DATA temp12 LIKE LINE OF temp11.
        DATA lx_error TYPE REF TO cx_root.

    CLEAR: ev_is_error, et_bapiret.

    TRY.
        lv_objectkey   = iv_objectkey.
        lv_objecttable = iv_objecttable.
        lv_classnum    = iv_classnum.
        lv_classtype   = iv_classtype.
        lv_keydate     = sy-datum.
        lt_num  = it_num.
        lt_char = it_char.
        lt_curr = it_curr.
        IF strlen( iv_objectkey ) > 50.
          
          GET REFERENCE OF lt_curr INTO temp2.

GET REFERENCE OF lt_char INTO temp3.

GET REFERENCE OF lt_num INTO temp4.

GET REFERENCE OF lv_keydate INTO temp5.

GET REFERENCE OF lv_status INTO temp6.

GET REFERENCE OF lv_classtype INTO temp7.

GET REFERENCE OF lv_classnum INTO temp8.

GET REFERENCE OF lv_objecttable INTO temp9.

CLEAR temp11.

temp12-name = 'OBJECTTABLE'.
temp12-kind = abap_func_exporting.
temp12-value = temp9.
INSERT temp12 INTO TABLE temp11.
temp12-name = 'CLASSNUM'.
temp12-kind = abap_func_exporting.
temp12-value = temp8.
INSERT temp12 INTO TABLE temp11.
temp12-name = 'CLASSTYPE'.
temp12-kind = abap_func_exporting.
temp12-value = temp7.
INSERT temp12 INTO TABLE temp11.
temp12-name = 'STATUS'.
temp12-kind = abap_func_exporting.
temp12-value = temp6.
INSERT temp12 INTO TABLE temp11.
temp12-name = 'KEYDATE'.
temp12-kind = abap_func_exporting.
temp12-value = temp5.
INSERT temp12 INTO TABLE temp11.
temp12-name = 'ALLOCVALUESNUMNEW'.
temp12-kind = abap_func_tables.
temp12-value = temp4.
INSERT temp12 INTO TABLE temp11.
temp12-name = 'ALLOCVALUESCHARNEW'.
temp12-kind = abap_func_tables.
temp12-value = temp3.
INSERT temp12 INTO TABLE temp11.
temp12-name = 'ALLOCVALUESCURRNEW'.
temp12-kind = abap_func_tables.
temp12-value = temp2.
INSERT temp12 INTO TABLE temp11.
call_with_long_key( EXPORTING iv_function  = 'BAPI_OBJCL_CHANGE'
                                        iv_objectkey = iv_objectkey
                                        it_param     = temp11
                              CHANGING  ct_bapiret   = et_bapiret ).
        ELSE.
          CALL FUNCTION 'BAPI_OBJCL_CHANGE'
            EXPORTING
              objectkey          = lv_objectkey
              objecttable        = lv_objecttable
              classnum           = lv_classnum
              classtype          = lv_classtype
              status             = lv_status
              keydate            = lv_keydate
            TABLES
              allocvaluesnumnew  = lt_num
              allocvaluescharnew = lt_char
              allocvaluescurrnew = lt_curr
              return             = et_bapiret.
        ENDIF.
        
      CATCH cx_root INTO lx_error.
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD call_with_long_key.

    DATA lr_objectkey TYPE REF TO data.
    DATA lt_param     TYPE abap_func_parmbind_tab.
    DATA ls_param     TYPE abap_func_parmbind.
    DATA lt_return    TYPE bapirettab.
    FIELD-SYMBOLS <objectkey> TYPE any.

    CREATE DATA lr_objectkey TYPE ('BAPI1003_KEY-OBJECT_LONG').
    ASSIGN lr_objectkey->* TO <objectkey>.
    <objectkey> = iv_objectkey.
    IF <objectkey> <> iv_objectkey.
      zabaputil_cl_bus_util_context=>bapi_msg_add_text( EXPORTING iv_text    = |Object key { iv_objectkey } is too long|
                                                        CHANGING  ct_bapiret = ct_bapiret ).
      RETURN.
    ENDIF.

    lt_param = it_param.
    ls_param-kind  = abap_func_exporting.
    ls_param-name  = 'OBJECTKEY_LONG'.
    ls_param-value = lr_objectkey.
    INSERT ls_param INTO TABLE lt_param.
    ls_param-kind = abap_func_tables.
    ls_param-name = 'RETURN'.
    GET REFERENCE OF lt_return INTO ls_param-value.
    INSERT ls_param INTO TABLE lt_param.

    zabaputil_cl_bus_util_context=>bapi_call_function( EXPORTING iv_name    = iv_function
                                                                 it_param   = lt_param
                                                       CHANGING  ct_bapiret = ct_bapiret ).
    INSERT LINES OF lt_return INTO TABLE ct_bapiret.

  ENDMETHOD.

ENDCLASS.
