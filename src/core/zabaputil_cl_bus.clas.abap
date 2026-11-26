CLASS zabaputil_cl_bus DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    "! Ends every method of the business API: sets cv_is_error when ct_bapiret
    "! holds a message of type E, A or X, and with iv_commit = abap_true commits
    "! (BAPI_TRANSACTION_COMMIT, wait) on success or rolls back on error.
    "! Without iv_commit the caller owns the LUW and nothing is committed.
    CLASS-METHODS finish
      IMPORTING
        iv_commit   TYPE abap_bool DEFAULT abap_false
      CHANGING
        ct_bapiret  TYPE bapirettab
        cv_is_error TYPE abap_bool.

    "! abap_true if the messages contain one of type E, A or X
    CLASS-METHODS check_is_error
      IMPORTING
        it_bapiret      TYPE bapirettab
      RETURNING
        VALUE(rv_error) TYPE abap_bool.

    "! Adds the message in sy-msgid/sy-msgno/sy-msgv1..4, as left by a function
    "! module call with EXCEPTIONS error_message - or, if there is none, an
    "! error naming iv_context
    CLASS-METHODS msg_add_sy
      IMPORTING
        iv_context TYPE clike OPTIONAL
      CHANGING
        ct_bapiret TYPE bapirettab.

    "! Adds a message with a free text
    CLASS-METHODS msg_add_text
      IMPORTING
        iv_text    TYPE clike
        iv_type    TYPE clike DEFAULT 'E'
      CHANGING
        ct_bapiret TYPE bapirettab.

    "! Adds an exception as error message, with the texts of its previous chain
    CLASS-METHODS msg_add_exception
      IMPORTING
        ix_error   TYPE REF TO cx_root
      CHANGING
        ct_bapiret TYPE bapirettab.

    "! Adds a single BAPIRET2 (BAPIs with a RETURN structure), if it is filled
    CLASS-METHODS msg_add_bapiret2
      IMPORTING
        is_return  TYPE bapiret2
      CHANGING
        ct_bapiret TYPE bapirettab.

    "! Adds the rows of any message table: BAPIRET1/2, BAPI_CORU_RETURN,
    "! BAPI_MATRETURN2, PROTT, MESG and the like. The fields are found by name
    "! (TYPE/MSGTY, ID/MSGID/ARBGB, NUMBER/MSGNO/TXTNR, MESSAGE_V1/MSGV1, ...)
    "! by the message class of abap-util (zabaputil_cl_bus_util_msg).
    CLASS-METHODS msg_add_table
      IMPORTING
        it_table   TYPE ANY TABLE
      CHANGING
        ct_bapiret TYPE bapirettab.

    "! Fills a material number into a BAPI structure: into &lt;field&gt;_LONG
    "! where the structure has it (S/4HANA, 40 characters), else into &lt;field&gt;
    CLASS-METHODS set_material
      IMPORTING
        iv_matnr TYPE clike
        iv_field TYPE clike DEFAULT 'MATERIAL'
      CHANGING
        cs_data  TYPE any.

    "! Resets the buffers of the logistics function modules, so that several
    "! postings in one session do not see stale data.
    "! @parameter iv_area | DELIVERY, HU, SERIAL or ALL
    CLASS-METHODS refresh_buffers
      IMPORTING
        iv_area TYPE clike DEFAULT 'ALL'.

    "! Calls a function module by name with a parameter table - for modules
    "! whose types are not in every system (EWM). A classic exception is
    "! added as message from sy-msg, a runtime error (unknown module or
    "! parameter) as exception text.
    CLASS-METHODS call_function
      IMPORTING
        iv_name    TYPE clike
        it_param   TYPE abap_func_parmbind_tab
      CHANGING
        ct_bapiret TYPE bapirettab.

    "! A document or object number in the internal format (leading zeros)
    CLASS-METHODS alpha_in
      IMPORTING
        iv_value         TYPE clike
        iv_length        TYPE i DEFAULT 10
      RETURNING
        VALUE(rv_result) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.

    " the messages of abap-util's message model as BAPIRET2
    CLASS-METHODS msg_add
      IMPORTING
        it_msg     TYPE zabaputil_cl_bus_util_context=>ty_t_msg
        iv_type    TYPE clike OPTIONAL
      CHANGING
        ct_bapiret TYPE bapirettab.

ENDCLASS.



CLASS zabaputil_cl_bus IMPLEMENTATION.

  METHOD finish.

    DATA ls_return TYPE bapiret2.

    IF check_is_error( ct_bapiret ) = abap_true.
      cv_is_error = abap_true.
    ENDIF.

    IF iv_commit = abap_false.
      RETURN.
    ENDIF.

    IF cv_is_error = abap_true.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      RETURN.
    ENDIF.

    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait   = abap_true
      IMPORTING
        return = ls_return.
    IF ls_return-type CA 'EAX' AND ls_return-type IS NOT INITIAL.
      msg_add_bapiret2( EXPORTING is_return  = ls_return
                        CHANGING  ct_bapiret = ct_bapiret ).
      cv_is_error = abap_true.
    ENDIF.

  ENDMETHOD.

  METHOD check_is_error.

    LOOP AT it_bapiret TRANSPORTING NO FIELDS WHERE type CA 'EAX'.
      rv_error = abap_true.
      RETURN.
    ENDLOOP.

  ENDMETHOD.

  METHOD msg_add_sy.

    IF sy-msgid IS INITIAL.
      msg_add_text( EXPORTING iv_text    = |{ iv_context } failed|
                    CHANGING  ct_bapiret = ct_bapiret ).
      RETURN.
    ENDIF.

    " a message left by EXCEPTIONS error_message is an error, whatever its type
    msg_add( EXPORTING it_msg     = zabaputil_cl_bus_util_msg=>msg_get_by_sy( )
                       iv_type    = COND #( WHEN sy-msgty CA 'AX' AND sy-msgty IS NOT INITIAL THEN sy-msgty ELSE 'E' )
             CHANGING  ct_bapiret = ct_bapiret ).

  ENDMETHOD.

  METHOD msg_add_text.

    DATA ls_return TYPE bapiret2.

    ls_return-type    = iv_type.
    ls_return-message = iv_text.
    INSERT ls_return INTO TABLE ct_bapiret.

  ENDMETHOD.

  METHOD msg_add_exception.

    msg_add( EXPORTING it_msg     = zabaputil_cl_bus_util_msg=>msg_get( ix_error )
                       iv_type    = 'E'
             CHANGING  ct_bapiret = ct_bapiret ).

  ENDMETHOD.

  METHOD msg_add_bapiret2.

    IF is_return-type IS INITIAL AND is_return-message IS INITIAL.
      RETURN.
    ENDIF.
    INSERT is_return INTO TABLE ct_bapiret.

  ENDMETHOD.

  METHOD msg_add_table.

    msg_add( EXPORTING it_msg     = zabaputil_cl_bus_util_msg=>msg_get( it_table )
             CHANGING  ct_bapiret = ct_bapiret ).

  ENDMETHOD.

  METHOD msg_add.

    DATA ls_return TYPE bapiret2.

    LOOP AT it_msg INTO DATA(ls_msg).
      CLEAR ls_return.
      ls_return-type       = COND #( WHEN iv_type IS NOT INITIAL THEN iv_type ELSE to_upper( ls_msg-type ) ).
      ls_return-id         = ls_msg-id.
      ls_return-number     = ls_msg-no.
      ls_return-message    = ls_msg-text.
      ls_return-message_v1 = ls_msg-v1.
      ls_return-message_v2 = ls_msg-v2.
      ls_return-message_v3 = ls_msg-v3.
      ls_return-message_v4 = ls_msg-v4.
      msg_add_bapiret2( EXPORTING is_return  = ls_return
                        CHANGING  ct_bapiret = ct_bapiret ).
    ENDLOOP.

  ENDMETHOD.

  METHOD set_material.

    DATA lv_field TYPE string.
    FIELD-SYMBOLS <value> TYPE any.

    lv_field = |{ to_upper( iv_field ) }_LONG|.
    ASSIGN COMPONENT lv_field OF STRUCTURE cs_data TO <value>.
    IF <value> IS NOT ASSIGNED.
      lv_field = to_upper( iv_field ).
      ASSIGN COMPONENT lv_field OF STRUCTURE cs_data TO <value>.
    ENDIF.
    IF <value> IS ASSIGNED.
      <value> = iv_matnr.
    ENDIF.

  ENDMETHOD.

  METHOD refresh_buffers.

    DATA lv_area TYPE string.

    lv_area = to_upper( iv_area ).

    TRY.
        IF lv_area = 'HU' OR lv_area = 'DELIVERY' OR lv_area = 'ALL'.
          CALL FUNCTION 'HU_PACKING_REFRESH'
            EXCEPTIONS
              OTHERS = 1.
        ENDIF.
        IF lv_area = 'DELIVERY' OR lv_area = 'ALL'.
          CALL FUNCTION 'LE_DELIVERY_REFRESH_BUFFER'
            EXCEPTIONS
              OTHERS = 1.
        ENDIF.
        IF lv_area = 'SERIAL' OR lv_area = 'DELIVERY' OR lv_area = 'ALL'.
          CALL FUNCTION 'SERIAL_INTTAB_REFRESH'
            EXCEPTIONS
              OTHERS = 1.
        ENDIF.
      CATCH cx_root ##NO_HANDLER.
        " a buffer that cannot be reset on this release is no error of the caller
    ENDTRY.

  ENDMETHOD.

  METHOD call_function.

    DATA lv_name      TYPE c LENGTH 30.
    DATA lt_param     TYPE abap_func_parmbind_tab.
    DATA lt_exception TYPE abap_func_excpbind_tab.

    lv_name  = to_upper( iv_name ).
    lt_param = it_param.
    lt_exception = VALUE #( ( name = 'ERROR_MESSAGE' value = 98 )
                            ( name = 'OTHERS'        value = 99 ) ).
    TRY.
        CALL FUNCTION lv_name
          PARAMETER-TABLE lt_param
          EXCEPTION-TABLE lt_exception.
        IF sy-subrc <> 0.
          msg_add_sy( EXPORTING iv_context = lv_name
                      CHANGING  ct_bapiret = ct_bapiret ).
        ENDIF.
      CATCH cx_root INTO DATA(lx_error).
        msg_add_exception( EXPORTING ix_error   = lx_error
                           CHANGING  ct_bapiret = ct_bapiret ).
    ENDTRY.

  ENDMETHOD.

  METHOD alpha_in.

    DATA lv_value TYPE c LENGTH 40.

    lv_value = iv_value.
    CONDENSE lv_value.
    IF lv_value CO '0123456789 ' AND strlen( lv_value ) < iv_length.
      rv_result = |{ lv_value ALPHA = IN WIDTH = iv_length }|.
    ELSE.
      rv_result = lv_value.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
