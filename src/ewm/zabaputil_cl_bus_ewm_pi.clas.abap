"! EWM physical inventory. All /SCWM/ and /LIME/ objects are reached dynamically,
"! so the class activates in systems without EWM and fails only when it is called there.
CLASS zabaputil_cl_bus_ewm_pi DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    "! Enters the count of physical inventory documents (/SCWM/PI_CALL_DOCUMENT_COUNT)
    "! @parameter is_head     | header data, the structure of the parameter IS_HEAD
    "! @parameter it_item     | counted items, the table type of the parameter IT_ITEM
    "! @parameter iv_simulate | abap_true: check only, nothing is counted
    CLASS-METHODS count
      IMPORTING
        is_head     TYPE any
        it_item     TYPE STANDARD TABLE
        iv_simulate TYPE abap_bool DEFAULT abap_false
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zabaputil_cl_bus_ewm_pi IMPLEMENTATION.

  METHOD count.

    DATA lr_head   TYPE REF TO data.
    DATA lr_item   TYPE REF TO data.
    DATA lt_return TYPE bapirettab.
    DATA lv_sim    TYPE abap_bool.
        DATA temp1 LIKE REF TO lt_return.
DATA temp2 LIKE REF TO lv_sim.
DATA temp3 TYPE abap_func_parmbind_tab.
DATA temp4 LIKE LINE OF temp3.
        DATA lx_error TYPE REF TO cx_root.

    CLEAR: ev_is_error, et_bapiret.

    lv_sim = iv_simulate.

    TRY.
        GET REFERENCE OF is_head INTO lr_head.
        GET REFERENCE OF it_item INTO lr_item.

        
        GET REFERENCE OF lt_return INTO temp1.

GET REFERENCE OF lv_sim INTO temp2.

CLEAR temp3.

temp4-name = 'IS_HEAD'.
temp4-kind = abap_func_exporting.
temp4-value = lr_head.
INSERT temp4 INTO TABLE temp3.
temp4-name = 'IT_ITEM'.
temp4-kind = abap_func_exporting.
temp4-value = lr_item.
INSERT temp4 INTO TABLE temp3.
temp4-name = 'I_SIM_MODE'.
temp4-kind = abap_func_exporting.
temp4-value = temp2.
INSERT temp4 INTO TABLE temp3.
temp4-name = 'ET_BAPIRET'.
temp4-kind = abap_func_importing.
temp4-value = temp1.
INSERT temp4 INTO TABLE temp3.
zabaputil_cl_bus_util_context=>bapi_call_function(
                            EXPORTING iv_name    = '/SCWM/PI_CALL_DOCUMENT_COUNT'
                                      it_param   = temp3
                            CHANGING  ct_bapiret = et_bapiret ).
        INSERT LINES OF lt_return INTO TABLE et_bapiret.
        
      CATCH cx_root INTO lx_error.
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

ENDCLASS.
