"! EWM warehouse tasks. All /SCWM/ objects are reached dynamically, so the
"! class activates in systems without EWM and fails only when it is called there.
CLASS zabaputil_cl_bus_ewm_wt DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    "! Creates a warehouse task that moves a handling unit (/SCWM/TO_CREATE_MOVE_HU)
    "! @parameter iv_procty | warehouse process type
    "! @parameter iv_squit  | abap_true: confirm at once
    CLASS-METHODS create_hu
      IMPORTING
        iv_lgnum    TYPE clike
        iv_huident  TYPE clike
        iv_procty   TYPE clike
        iv_nltyp    TYPE clike OPTIONAL
        iv_nlpla    TYPE clike OPTIONAL
        iv_squit    TYPE abap_bool DEFAULT abap_false
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_tanum    TYPE string
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Creates warehouse tasks from rows of the standard create structure (/SCWM/TO_CREATE)
    "! @parameter it_create | rows of /SCWM/TT_TO_CREATE_INT
    "! @parameter ev_tanum  | number the module returns for the tasks created
    CLASS-METHODS create
      IMPORTING
        iv_lgnum    TYPE clike
        it_create   TYPE STANDARD TABLE
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_tanum    TYPE string
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Creates a warehouse task that moves a product quantity (/SCWM/TO_CREATE).
    "! The product number is converted to the product id by
    "! zabaputil_cl_bus_ewm_stock=>read_product_id( ).
    "! @parameter iv_procty   | warehouse process type
    "! @parameter iv_unit     | unit of iv_quantity (alternative unit of measure)
    "! @parameter iv_vlpla    | source bin
    "! @parameter iv_nlpla    | destination bin
    "! @parameter iv_vlenr    | source handling unit
    "! @parameter iv_nlenr    | destination handling unit
    "! @parameter iv_cat      | stock type
    "! @parameter iv_owner    | owner of the stock
    "! @parameter iv_entitled | party entitled to dispose
    "! @parameter iv_squit    | abap_true: confirm at once
    CLASS-METHODS create_product
      IMPORTING
        iv_lgnum    TYPE clike
        iv_procty   TYPE clike
        iv_matnr    TYPE clike
        iv_quantity TYPE numeric
        iv_unit     TYPE clike
        iv_vlpla    TYPE clike OPTIONAL
        iv_nlpla    TYPE clike OPTIONAL
        iv_vlenr    TYPE clike OPTIONAL
        iv_nlenr    TYPE clike OPTIONAL
        iv_cat      TYPE clike OPTIONAL
        iv_owner    TYPE clike OPTIONAL
        iv_entitled TYPE clike OPTIONAL
        iv_charg    TYPE clike OPTIONAL
        iv_squit    TYPE abap_bool DEFAULT abap_false
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_tanum    TYPE string
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Changes open warehouse tasks (/SCWM/TO_CHANGE)
    "! @parameter it_change | rows of the table type of the parameter IT_CHANGE
    CLASS-METHODS change
      IMPORTING
        iv_lgnum    TYPE clike
        it_change   TYPE STANDARD TABLE
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Reads a warehouse task - open (/SCWM/ORDIM_O) or confirmed (/SCWM/ORDIM_C)
    "! @parameter er_task | reference to the table row
    CLASS-METHODS read
      IMPORTING
        iv_lgnum    TYPE clike
        iv_tanum    TYPE clike
      EXPORTING
        er_task     TYPE REF TO data
        ev_is_open  TYPE abap_bool
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Confirms a warehouse task as planned (/SCWM/TO_CONFIRM)
    CLASS-METHODS confirm
      IMPORTING
        iv_lgnum    TYPE clike
        iv_tanum    TYPE clike
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

    "! Cancels a warehouse task (/SCWM/TO_CANCEL)
    CLASS-METHODS cancel
      IMPORTING
        iv_lgnum    TYPE clike
        iv_tanum    TYPE clike
        iv_commit   TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_is_error TYPE abap_bool
        et_bapiret  TYPE bapirettab.

  PROTECTED SECTION.
  PRIVATE SECTION.

    CLASS-METHODS call_with_task_table
      IMPORTING
        iv_function   TYPE clike
        iv_table_type TYPE clike
        iv_table_name TYPE clike
        iv_lgnum      TYPE clike
        iv_tanum      TYPE clike
      CHANGING
        ct_bapiret    TYPE bapirettab.

    CLASS-METHODS call_with_rows
      IMPORTING
        iv_function   TYPE clike
        iv_table_name TYPE clike
        iv_lgnum      TYPE clike
        it_rows       TYPE STANDARD TABLE
        iv_tanum      TYPE abap_bool DEFAULT abap_false
      EXPORTING
        ev_tanum      TYPE string
      CHANGING
        ct_bapiret    TYPE bapirettab.

    CLASS-METHODS set_component
      IMPORTING
        iv_name    TYPE clike
        iv_value   TYPE any
      CHANGING
        cs_row     TYPE any
        ct_bapiret TYPE bapirettab.

ENDCLASS.



CLASS zabaputil_cl_bus_ewm_wt IMPLEMENTATION.

  METHOD create_hu.

    DATA lr_table   TYPE REF TO data.
    DATA lr_lgnum   TYPE REF TO data.
    DATA lr_tanum   TYPE REF TO data.
    DATA lt_return  TYPE bapirettab.
    DATA lv_false   TYPE abap_bool VALUE abap_false.
    FIELD-SYMBOLS <table> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <row>   TYPE any.
    FIELD-SYMBOLS <field> TYPE any.

    CLEAR: ev_tanum, ev_is_error, et_bapiret.

    TRY.
        CREATE DATA lr_table TYPE ('/SCWM/TT_TO_CREA_HU').
        ASSIGN lr_table->* TO <table>.
        INSERT INITIAL LINE INTO TABLE <table> ASSIGNING <row>.
        ASSIGN COMPONENT 'HUIDENT' OF STRUCTURE <row> TO <field>.
        <field> = iv_huident.
        ASSIGN COMPONENT 'PROCTY' OF STRUCTURE <row> TO <field>.
        <field> = iv_procty.
        ASSIGN COMPONENT 'NLTYP' OF STRUCTURE <row> TO <field>.
        <field> = iv_nltyp.
        ASSIGN COMPONENT 'NLPLA' OF STRUCTURE <row> TO <field>.
        <field> = iv_nlpla.
        ASSIGN COMPONENT 'SQUIT' OF STRUCTURE <row> TO <field>.
        <field> = iv_squit.

        CREATE DATA lr_lgnum TYPE ('/SCWM/LGNUM').
        ASSIGN lr_lgnum->* TO <field>.
        <field> = iv_lgnum.
        CREATE DATA lr_tanum TYPE ('/SCWM/TANUM').

        zabaputil_cl_bus_util_context=>bapi_call_function(
                            EXPORTING iv_name    = '/SCWM/TO_CREATE_MOVE_HU'
                                      it_param   = VALUE #( ( name = 'IV_LGNUM'       kind = abap_func_exporting value = lr_lgnum )
                                                            ( name = 'IV_COMMIT_WORK' kind = abap_func_exporting value = REF #( lv_false ) )
                                                            ( name = 'IT_CREATE_HU'   kind = abap_func_exporting value = lr_table )
                                                            ( name = 'EV_TANUM'       kind = abap_func_importing value = lr_tanum )
                                                            ( name = 'ET_BAPIRET'     kind = abap_func_importing value = REF #( lt_return ) ) )
                            CHANGING  ct_bapiret = et_bapiret ).
        INSERT LINES OF lt_return INTO TABLE et_bapiret.
        ASSIGN lr_tanum->* TO <field>.
        ev_tanum = <field>.
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD create.

    CLEAR: ev_tanum, ev_is_error, et_bapiret.

    call_with_rows( EXPORTING iv_function   = '/SCWM/TO_CREATE'
                              iv_table_name = 'IT_CREATE'
                              iv_lgnum      = iv_lgnum
                              it_rows       = it_create
                              iv_tanum      = abap_true
                    IMPORTING ev_tanum      = ev_tanum
                    CHANGING  ct_bapiret    = et_bapiret ).

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD create_product.

    DATA lr_table TYPE REF TO data.
    DATA lv_matid TYPE zabaputil_cl_bus_ewm_stock=>ty_matid.
    FIELD-SYMBOLS <table> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <row>   TYPE any.

    CLEAR: ev_tanum, ev_is_error, et_bapiret.

    zabaputil_cl_bus_ewm_stock=>read_product_id( EXPORTING iv_matnr   = iv_matnr
                                                 IMPORTING ev_matid   = lv_matid
                                                           et_bapiret = et_bapiret ).

    IF zabaputil_cl_bus_util_context=>bapi_check_is_error( et_bapiret ) = abap_false.
      TRY.
          CREATE DATA lr_table TYPE ('/SCWM/TT_TO_CREATE_INT').
          ASSIGN lr_table->* TO <table>.
          INSERT INITIAL LINE INTO TABLE <table> ASSIGNING <row>.
          set_component( EXPORTING iv_name = 'PROCTY'   iv_value = iv_procty   CHANGING cs_row = <row> ct_bapiret = et_bapiret ).
          set_component( EXPORTING iv_name = 'MATID'    iv_value = lv_matid    CHANGING cs_row = <row> ct_bapiret = et_bapiret ).
          set_component( EXPORTING iv_name = 'ANFME'    iv_value = iv_quantity CHANGING cs_row = <row> ct_bapiret = et_bapiret ).
          set_component( EXPORTING iv_name = 'ALTME'    iv_value = iv_unit     CHANGING cs_row = <row> ct_bapiret = et_bapiret ).
          set_component( EXPORTING iv_name = 'VLPLA'    iv_value = iv_vlpla    CHANGING cs_row = <row> ct_bapiret = et_bapiret ).
          set_component( EXPORTING iv_name = 'NLPLA'    iv_value = iv_nlpla    CHANGING cs_row = <row> ct_bapiret = et_bapiret ).
          set_component( EXPORTING iv_name = 'VLENR'    iv_value = iv_vlenr    CHANGING cs_row = <row> ct_bapiret = et_bapiret ).
          set_component( EXPORTING iv_name = 'NLENR'    iv_value = iv_nlenr    CHANGING cs_row = <row> ct_bapiret = et_bapiret ).
          set_component( EXPORTING iv_name = 'CAT'      iv_value = iv_cat      CHANGING cs_row = <row> ct_bapiret = et_bapiret ).
          set_component( EXPORTING iv_name = 'OWNER'    iv_value = iv_owner    CHANGING cs_row = <row> ct_bapiret = et_bapiret ).
          set_component( EXPORTING iv_name = 'ENTITLED' iv_value = iv_entitled CHANGING cs_row = <row> ct_bapiret = et_bapiret ).
          set_component( EXPORTING iv_name = 'CHARG'    iv_value = iv_charg    CHANGING cs_row = <row> ct_bapiret = et_bapiret ).
          set_component( EXPORTING iv_name = 'SQUIT'    iv_value = iv_squit    CHANGING cs_row = <row> ct_bapiret = et_bapiret ).

          " a field the structure does not have is an error: no task without it
          IF zabaputil_cl_bus_util_context=>bapi_check_is_error( et_bapiret ) = abap_false.
            call_with_rows( EXPORTING iv_function   = '/SCWM/TO_CREATE'
                                      iv_table_name = 'IT_CREATE'
                                      iv_lgnum      = iv_lgnum
                                      it_rows       = <table>
                                      iv_tanum      = abap_true
                            IMPORTING ev_tanum      = ev_tanum
                            CHANGING  ct_bapiret    = et_bapiret ).
          ENDIF.
        CATCH cx_root INTO DATA(lx_error).
          zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                                 CHANGING  ct_bapiret = et_bapiret ).
      ENDTRY.
    ENDIF.

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD change.

    CLEAR: ev_is_error, et_bapiret.

    call_with_rows( EXPORTING iv_function   = '/SCWM/TO_CHANGE'
                              iv_table_name = 'IT_CHANGE'
                              iv_lgnum      = iv_lgnum
                              it_rows       = it_change
                    CHANGING  ct_bapiret    = et_bapiret ).

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD read.

    DATA lv_table TYPE string.
    DATA lv_lgnum TYPE c LENGTH 4.
    DATA lv_tanum TYPE c LENGTH 12.
    FIELD-SYMBOLS <task> TYPE any.

    CLEAR: er_task, ev_is_open, ev_is_error, et_bapiret.

    lv_lgnum = iv_lgnum.
    lv_tanum = zabaputil_cl_bus_util_context=>conv_alpha_in( iv_value  = iv_tanum
                                                             iv_length = 12 ).

    TRY.
        lv_table = '/SCWM/ORDIM_O'.
        CREATE DATA er_task TYPE (lv_table).
        ASSIGN er_task->* TO <task>.
        SELECT SINGLE * FROM (lv_table) INTO @<task> WHERE lgnum = @lv_lgnum AND tanum = @lv_tanum.
        IF sy-subrc = 0.
          ev_is_open = abap_true.
        ELSE.
          lv_table = '/SCWM/ORDIM_C'.
          CREATE DATA er_task TYPE (lv_table).
          ASSIGN er_task->* TO <task>.
          SELECT SINGLE * FROM (lv_table) INTO @<task> WHERE lgnum = @lv_lgnum AND tanum = @lv_tanum.
          IF sy-subrc <> 0.
            CLEAR er_task.
            zabaputil_cl_bus_util_context=>bapi_msg_add_text( EXPORTING iv_text    = |Warehouse task { iv_lgnum }/{ iv_tanum } not found|
                                                              CHANGING  ct_bapiret = et_bapiret ).
          ENDIF.
        ENDIF.
      CATCH cx_root INTO DATA(lx_error).
        CLEAR er_task.
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = et_bapiret ).
    ENDTRY.

    zabaputil_cl_bus_util_context=>bapi_finish( CHANGING ct_bapiret  = et_bapiret
                                                         cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD confirm.

    CLEAR: ev_is_error, et_bapiret.

    call_with_task_table( EXPORTING iv_function   = '/SCWM/TO_CONFIRM'
                                    iv_table_type = '/SCWM/TT_TO_CONF'
                                    iv_table_name = 'IT_CONF'
                                    iv_lgnum      = iv_lgnum
                                    iv_tanum      = iv_tanum
                          CHANGING  ct_bapiret    = et_bapiret ).

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD cancel.

    CLEAR: ev_is_error, et_bapiret.

    call_with_task_table( EXPORTING iv_function   = '/SCWM/TO_CANCEL'
                                    iv_table_type = '/SCWM/TT_CANCL'
                                    iv_table_name = 'IT_CANCL'
                                    iv_lgnum      = iv_lgnum
                                    iv_tanum      = iv_tanum
                          CHANGING  ct_bapiret    = et_bapiret ).

    zabaputil_cl_bus_util_context=>bapi_finish( EXPORTING iv_commit   = iv_commit
                                                CHANGING  ct_bapiret  = et_bapiret
                                                          cv_is_error = ev_is_error ).

  ENDMETHOD.

  METHOD call_with_task_table.

    DATA lr_table  TYPE REF TO data.
    DATA lr_lgnum  TYPE REF TO data.
    DATA lt_return TYPE bapirettab.
    DATA lv_false  TYPE abap_bool VALUE abap_false.
    DATA lv_type   TYPE string.
    FIELD-SYMBOLS <table> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <row>   TYPE any.
    FIELD-SYMBOLS <field> TYPE any.

    TRY.
        lv_type = iv_table_type.
        CREATE DATA lr_table TYPE (lv_type).
        ASSIGN lr_table->* TO <table>.
        INSERT INITIAL LINE INTO TABLE <table> ASSIGNING <row>.
        ASSIGN COMPONENT 'TANUM' OF STRUCTURE <row> TO <field>.
        <field> = zabaputil_cl_bus_util_context=>conv_alpha_in( iv_value  = iv_tanum
                                                                iv_length = 12 ).
        UNASSIGN <field>.
        ASSIGN COMPONENT 'SQUIT' OF STRUCTURE <row> TO <field>.
        IF <field> IS ASSIGNED.
          <field> = abap_true.
        ENDIF.

        CREATE DATA lr_lgnum TYPE ('/SCWM/LGNUM').
        ASSIGN lr_lgnum->* TO <field>.
        <field> = iv_lgnum.

        zabaputil_cl_bus_util_context=>bapi_call_function(
                            EXPORTING iv_name    = iv_function
                                      it_param   = VALUE #( ( name = 'IV_LGNUM'       kind = abap_func_exporting value = lr_lgnum )
                                                            ( name = 'IV_COMMIT_WORK' kind = abap_func_exporting value = REF #( lv_false ) )
                                                            ( name = to_upper( iv_table_name ) kind = abap_func_exporting value = lr_table )
                                                            ( name = 'ET_BAPIRET'     kind = abap_func_importing value = REF #( lt_return ) ) )
                            CHANGING  ct_bapiret = ct_bapiret ).
        INSERT LINES OF lt_return INTO TABLE ct_bapiret.
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = ct_bapiret ).
    ENDTRY.

  ENDMETHOD.

  METHOD call_with_rows.

    DATA lr_rows   TYPE REF TO data.
    DATA lr_lgnum  TYPE REF TO data.
    DATA lr_tanum  TYPE REF TO data.
    DATA lt_param  TYPE abap_func_parmbind_tab.
    DATA ls_param  TYPE abap_func_parmbind.
    DATA lt_return TYPE bapirettab.
    DATA lv_false  TYPE abap_bool VALUE abap_false.
    FIELD-SYMBOLS <field> TYPE any.

    CLEAR ev_tanum.

    TRY.
        CREATE DATA lr_lgnum TYPE ('/SCWM/LGNUM').
        ASSIGN lr_lgnum->* TO <field>.
        <field> = iv_lgnum.
        GET REFERENCE OF it_rows INTO lr_rows.

        ls_param-kind  = abap_func_exporting.
        ls_param-name  = 'IV_LGNUM'.
        ls_param-value = lr_lgnum.
        INSERT ls_param INTO TABLE lt_param.
        ls_param-name = 'IV_UPDATE_TASK'.
        GET REFERENCE OF lv_false INTO ls_param-value.
        INSERT ls_param INTO TABLE lt_param.
        ls_param-name = 'IV_COMMIT_WORK'.
        INSERT ls_param INTO TABLE lt_param.
        ls_param-name  = to_upper( iv_table_name ).
        ls_param-value = lr_rows.
        INSERT ls_param INTO TABLE lt_param.

        ls_param-kind = abap_func_importing.
        ls_param-name = 'ET_BAPIRET'.
        GET REFERENCE OF lt_return INTO ls_param-value.
        INSERT ls_param INTO TABLE lt_param.
        IF iv_tanum = abap_true.
          CREATE DATA lr_tanum TYPE ('/SCWM/TANUM').
          ls_param-name  = 'EV_TANUM'.
          ls_param-value = lr_tanum.
          INSERT ls_param INTO TABLE lt_param.
        ENDIF.

        zabaputil_cl_bus_util_context=>bapi_call_function( EXPORTING iv_name    = iv_function
                                                                     it_param   = lt_param
                                                           CHANGING  ct_bapiret = ct_bapiret ).
        INSERT LINES OF lt_return INTO TABLE ct_bapiret.
        IF lr_tanum IS BOUND.
          ASSIGN lr_tanum->* TO <field>.
          ev_tanum = <field>.
        ENDIF.
      CATCH cx_root INTO DATA(lx_error).
        zabaputil_cl_bus_util_context=>bapi_msg_add_exception( EXPORTING ix_error   = lx_error
                                                               CHANGING  ct_bapiret = ct_bapiret ).
    ENDTRY.

  ENDMETHOD.

  METHOD set_component.

    FIELD-SYMBOLS <field> TYPE any.

    IF iv_value IS INITIAL.
      RETURN.
    ENDIF.

    ASSIGN COMPONENT iv_name OF STRUCTURE cs_row TO <field>.
    IF sy-subrc <> 0.
      zabaputil_cl_bus_util_context=>bapi_msg_add_text( EXPORTING iv_text    = |Field { iv_name } is not part of the structure|
                                                        CHANGING  ct_bapiret = ct_bapiret ).
      RETURN.
    ENDIF.
    <field> = iv_value.

  ENDMETHOD.

ENDCLASS.
