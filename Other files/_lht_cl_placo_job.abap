CLASS /lht/cl_placo_job DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_apj_dt_exec_object.
    INTERFACES if_apj_rt_exec_object.
    INTERFACES if_oo_adt_classrun.

    METHODS constructor.

    METHODS start_job
      IMPORTING
        it_parameters TYPE if_apj_rt_exec_object=>tt_templ_val.

    DATA out TYPE REF TO if_oo_adt_classrun_out.
    DATA application_log TYPE REF TO if_bali_log.

  PRIVATE SECTION.
    TYPES: BEGIN OF gty_s_verification_date,
             material          TYPE /lht/placo_mat_number,
             verification_date TYPE timestampl,
           END OF gty_s_verification_date.
    TYPES gty_t_verification_date TYPE STANDARD TABLE OF gty_s_verification_date WITH DEFAULT KEY.

    TYPES gty_t_materialnumbers TYPE STANDARD TABLE OF /lht/placo_mat_number WITH DEFAULT KEY.

    TYPES: BEGIN OF gty_s_interchange_worklist,
             material    TYPE /lht/placo_mat_number,
             criticality TYPE int4,
           END OF gty_s_interchange_worklist.
    TYPES gty_t_interchange_worklist TYPE STANDARD TABLE OF gty_s_interchange_worklist WITH DEFAULT KEY.

    "! <p class="shorttext synchronized"></p>
    "! This method performs verification date checks and sets a return value
    "! based on these validations.
    "! @parameter iv_last_verification_date | Last verification date to be checked<p class="shorttext synchronized"></p>
    "! @parameter rv_result                 | Return criticality<p class="shorttext synchronized"></p>
    CLASS-METHODS check_interchange_verification
      IMPORTING
        iv_last_verification_date TYPE /lht/placo_dats
      RETURNING
        VALUE(rv_result)          TYPE i.

    METHODS add_message_log_console
      IMPORTING
        i_number     TYPE symsgno
        i_severity   TYPE symsgty
        i_variable_1 TYPE string OPTIONAL
        i_variable_2 TYPE string OPTIONAL
        i_variable_3 TYPE string OPTIONAL
        i_variable_4 TYPE string OPTIONAL
      RAISING
        cx_bali_runtime.

    "! <p class="shorttext synchronized"></p>
    "! Converts the imported timestamp to ABAP formatted date
    "! @parameter iv_last_interchange_verific_d | Timestamp<p class="shorttext synchronized"></p>
    "! @parameter rv_date                       | ABAP formatted date<p class="shorttext synchronized"></p>
    CLASS-METHODS getVerificationDate
      IMPORTING
        iv_last_interchange_verific_d TYPE timestampl
      RETURNING
        VALUE(rv_date)                TYPE d.

    "! <p class="shorttext synchronized"></p>
    "! This method returns the verification date in the past dependent on the imported value
    "! @parameter iv_months_in_past            | Months to calculate in the past<p class="shorttext synchronized"></p>
    "! @parameter rv_verification_date_in_past | Past verification date<p class="shorttext synchronized"></p>
    CLASS-METHODS getVerificationDateInPast
      IMPORTING
        iv_months_in_past                   TYPE i
      RETURNING
        VALUE(rv_verification_date_in_past) TYPE d.

    "! <p class="shorttext synchronized"></p>
    "! This method iterates over the imported materials and returns relevant materials based on their verification dates.
    "! @parameter it_materials            | Materials to be checked<p class="shorttext synchronized"></p>
    "! @parameter rt_interchange_worklist | Relevant materials<p class="shorttext synchronized"></p>
    CLASS-METHODS getInterchangeWorklistItems
      IMPORTING
        it_materials                   TYPE gty_t_verification_date
      RETURNING
        VALUE(rt_interchange_worklist) TYPE gty_t_interchange_worklist.

    "! <p class="shorttext synchronized"></p>
    "! This method merges restricted interchangeabilities and normal interchangeabilities.
    "! @parameter it_restricted         | Restricted interchangeabilities<p class="shorttext synchronized"></p>
    "! @parameter it_interchanges       | Interchangeabilities<p class="shorttext synchronized"></p>
    "! @parameter rt_relevant_materials | All relevant materials without duplicates<p class="shorttext synchronized"></p>
    CLASS-METHODS mergeRelevantEntries
      IMPORTING
        it_restricted                TYPE gty_t_interchange_worklist
        it_interchanges              TYPE gty_t_interchange_worklist
      RETURNING
        VALUE(rt_relevant_materials) TYPE gty_t_interchange_worklist.

ENDCLASS.

CLASS /lht/cl_placo_job IMPLEMENTATION.

  METHOD add_message_log_console.
    IF sy-batch = abap_true.
      " Add a message as item to the log
      DATA(l_message) = cl_bali_message_setter=>create( id         = '/LHT/PLACO_MSG'
                                                        severity   = i_severity
                                                        number     = i_number
                                                        variable_1 = CONV #( i_variable_1 )
                                                        variable_2 = CONV #( i_variable_2 )
                                                        variable_3 = CONV #( i_variable_3 )
                                                        variable_4 = CONV #( i_variable_4 ) ).
      application_log->add_item( item = l_message ).

      cl_bali_log_db=>get_instance( )->save_log( log                        = application_log
                                                 assign_to_current_appl_job = abap_true ).

    ELSE.
      out->write( |Run in console| ).

      MESSAGE ID '/LHT/PLACO_MSG' TYPE 'S' NUMBER i_number
        WITH i_variable_1 i_variable_2 i_variable_3 i_variable_4
        INTO DATA(field).

      out->write( |Message: { field } | ).
    ENDIF.
  ENDMETHOD.

  METHOD check_interchange_verification.
    TRY.
        DATA(lv_verification_33m) = getverificationdateinpast( 33 ).
      CATCH cx_root.
    ENDTRY.

    TRY.
        DATA(lv_verification_36m) = getverificationdateinpast( 36 ).
      CATCH cx_root.
    ENDTRY.

    IF iv_last_verification_date <= lv_verification_36m.
      rv_result = 1.
    ENDIF.

    IF iv_last_verification_date > lv_verification_36m AND
       iv_last_verification_date < lv_verification_33m.
      rv_result = 2.
    ENDIF.
  ENDMETHOD.

  METHOD constructor.
    TRY.
        " Create a new Application Log
        DATA(l_log) = cl_bali_log=>create( ).

        " Add a header to the log
        l_log->set_header( header = cl_bali_header_setter=>create( object      = '/LHT/PLACO_APP_LOG'
                                                                   subobject   = 'PLACO_JOB'
                                                                   external_id = '' ) ).
        application_log = l_log.
      CATCH cx_bali_runtime ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

  METHOD getInterchangeWorklistItems.
    LOOP AT it_materials ASSIGNING FIELD-SYMBOL(<ls_material>).
      IF <ls_material>-verification_date IS INITIAL.
        CONTINUE.
      ENDIF.

      DATA(lv_verification_date) = getVerificationDate( <ls_material>-verification_date ).
      DATA(lv_criticality) = check_interchange_verification( iv_last_verification_date = lv_verification_date ).

      IF lv_criticality IS NOT INITIAL.
        INSERT VALUE gty_s_interchange_worklist( material    = <ls_material>-material
                                                 criticality = lv_criticality ) INTO TABLE rt_interchange_worklist.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD getVerificationDate.
    CONVERT TIME STAMP iv_last_interchange_verific_d TIME ZONE 'UTC' INTO DATE rv_date.
  ENDMETHOD.

  METHOD getVerificationDateInPast.
    rv_verification_date_in_past =
      xco_cp=>sy->date( )->subtract( iv_month       = iv_months_in_past
                                     io_calculation = xco_cp_time=>date_calculation->ultimo )->as( xco_cp_time=>format->abap )->value.
  ENDMETHOD.

  METHOD if_apj_dt_exec_object~get_parameters.
    " Return the supported selection parameters here
    et_parameter_def =
      VALUE #( kind           = if_apj_dt_exec_object=>parameter
               datatype       = 'C'
               changeable_ind = abap_true
               length         = 1 ( selname         = 'R_FORECA'
                                    param_text      = 'Process Forecast Upload'
                                    radio_group_ind = abap_true
                                    radio_group_id  = 'R1' )
                                  ( selname         = 'R_JOB'
                                    param_text      = 'Process All Materials'
                                    radio_group_ind = abap_true
                                    radio_group_id  = 'R1' )
                                  ( selname         = 'R_REPL'
                                    param_text      = 'Process Replenishment Time Upload'
                                    radio_group_ind = abap_true
                                    radio_group_id  = 'R1' )
                                  ( selname         = 'R_ERROR'
                                    param_text      = 'Process Error Log'
                                    radio_group_ind = abap_true
                                    radio_group_id  = 'R1' )
                                  ( selname         = 'C_DEL'
                                    param_text      = 'Delete all worklist entries before start'
                                    checkbox_ind    = abap_true ) ).

    " Return the default parameters values here
    et_parameter_val =
      VALUE #( kind = if_apj_dt_exec_object=>parameter
               sign   = 'I'
               option = 'EQ' ( selname = 'R_FORECA' low = abap_false )
                             ( selname = 'R_JOB'    low = abap_true  )
                             ( selname = 'R_REPL'   low = abap_false )
                             ( selname = 'R_ERROR'  low = abap_false )
                             ( selname = 'C_DEL'    low = abap_false ) ).
  ENDMETHOD.

  METHOD if_apj_rt_exec_object~execute.
    start_job( it_parameters = it_parameters ).
  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.
    me->out = out.
    start_job( VALUE #( ( kind    = if_apj_dt_exec_object=>parameter
                          sign    = 'I'
                          option  = 'EQ'
                          selname = 'R_JOB'
                          low     = abap_true ) ) ).

*    DATA lo_job_handling TYPE REF TO /lht/cl_placo_job_handling.
*    lo_job_handling->processerrorlogjob( ).

*    DATA io_placo_proccessing TYPE REF TO /lht/cl_placo_event_processing.
*    io_placo_proccessing = NEW #( ).
*    io_placo_proccessing->material_processing(
*        it_matnr = VALUE #( ( '722-4479-024:97896'    )
*                            ( '69002697-002:97896'    )
*                            ( '5E8071/329-0004:73030' ) )
*        iv_job   = abap_true ).
  ENDMETHOD.

  METHOD mergeRelevantEntries.
    rt_relevant_materials = it_interchanges.

    LOOP AT it_restricted REFERENCE INTO DATA(ls_restricted).
      IF NOT line_exists( rt_relevant_materials[ material    = ls_restricted->material
                                                 criticality = ls_restricted->criticality ] ).
        INSERT ls_restricted->* INTO TABLE rt_relevant_materials.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD start_job.
    DATA: lv_forecast        TYPE abap_boolean,
          lv_job             TYPE abap_boolean,
          lv_replenish       TYPE abap_boolean,
          lv_error_log       TYPE abap_boolean,
          lv_delete_worklist TYPE abap_boolean.

    LOOP AT it_parameters INTO DATA(ls_parameter).
      CASE ls_parameter-selname.
        WHEN 'R_FORECA'.
          lv_forecast = ls_parameter-low.
        WHEN 'R_JOB'.
          lv_job = ls_parameter-low.
        WHEN 'R_REPL'.
          lv_replenish = ls_parameter-low.
        WHEN 'R_ERROR'.
          lv_error_log = ls_parameter-low.
        WHEN 'C_DEL'.
          lv_delete_worklist = ls_parameter-low.
      ENDCASE.
    ENDLOOP.

    IF lv_delete_worklist = abap_true.
      DELETE FROM /lht/a_placo_wrk.
      DELETE FROM /lht/a_placo_mat.
    ENDIF.

    DATA(lo_job_handling) = NEW /lht/cl_placo_job_handling( ).

    IF lv_forecast = abap_true.
      lo_job_handling->processForecastJob( ).
    ELSEIF lv_job = abap_true.
      lo_job_handling->processScheduledJob( ).
    ELSEIF lv_replenish = abap_true.
      lo_job_handling->processConsumptionJob( ).
    ELSEIF lv_error_log = abap_true.
      lo_job_handling->processErrorLogJob( ).
    ENDIF.
  ENDMETHOD.
  
ENDCLASS.