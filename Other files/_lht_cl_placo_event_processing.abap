"! <p class="shorttext">PLACO Event Processing</p>
"! <p>This class handles the processing of material planning events in the PLACO system. </p>
"! <p>It analyzes material data from various sources to determine which materials require attention <br>
"! and creates appropriate worklist entries based on different criteria (consumption changes,
"! reorder point breaches, interchangeability verification, etc.).
"! </p>
"! <p>
"! The class performs the following main functions: <br>
"! - Collects material master data, stock levels, consumption data, and other metrics <br>
"! - Calculates key planning figures (replenishment time, stock reach, forecast data) <br>
"! - Determines which materials should be added to different worklists <br>
"! - Persists material data and worklist entries to the database
"! </p>
"! <p>
"! The main entry points are material_processing() and purch_ord_processing() methods <br>
"! which trigger the analysis and processing flow for materials. </p>
CLASS /lht/cl_placo_event_processing DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES gty_t_placo_mat_number TYPE TABLE OF /lht/placo_mat_number WITH DEFAULT KEY.

    "!
    "! Processes materials by retrieving relevant data, calculating parameters,
    "! and determining worklist entries.
    "!
    "! @parameter it_matnr            | List of material numbers to be processed
    "! @parameter io_error_log |
    "! @raising   /lht/cx_placo_check | If an error occurs during processing
    METHODS material_processing
      IMPORTING
         it_matnr     TYPE gty_t_placo_mat_number
         io_error_log TYPE REF TO /lht/cl_placo_error_handling OPTIONAL.

    "!
    "! Processes purchase orders and triggers material processing for the related materials.
    "!
    "! @parameter iv_ebeln            | Purchase order number to be processed
    "! @raising   /lht/cx_placo_check | If an error occurs during processing
    METHODS purch_ord_processing
      IMPORTING
        iv_ebeln TYPE /lht/placo_purch_order
      RAISING
        /lht/cx_placo_check.

    "! <p class="shorttext synchronized"></p>
    "!
    "! Processes purchase requisitions and triggers material processing for the related materials.
    "!
    "! @parameter iv_ebeln            | Purchase requisition number <p class="shorttext synchronized"></p>
    "! @raising   /lht/cx_placo_check | If an error occurs during processing <p class="shorttext synchronized"></p>
    METHODS purch_requisition_processing
      IMPORTING
        iv_ebeln TYPE /lht/placo_purch_order
      RAISING
        /lht/cx_placo_check.

  PRIVATE SECTION.
    TYPES: BEGIN OF gty_s_stock_data,
             materialnumber TYPE matnr,
             stock          TYPE p LENGTH 7 DECIMALS 3,
           END OF gty_s_stock_data.

    TYPES gty_packed_number  TYPE p LENGTH 15 DECIMALS 4.

    TYPES gty_t_stock_data   TYPE STANDARD TABLE OF gty_s_stock_data WITH DEFAULT KEY.
    TYPES gty_t_placo_matnr  TYPE TABLE OF /lht/placo_mat_number.
    TYPES gty_t_r_placo_mast TYPE STANDARD TABLE OF /lht/r_placo_worklist WITH DEFAULT KEY.
    TYPES gty_t_r_placo_mat  TYPE STANDARD TABLE OF /lht/r_placo_materials WITH DEFAULT KEY.
    TYPES gty_t_a_placo_mat  TYPE STANDARD TABLE OF /lht/a_placo_mat WITH DEFAULT KEY.
    TYPES gty_t_a_placo_wrk  TYPE STANDARD TABLE OF /lht/a_placo_wrk WITH DEFAULT KEY.

    TYPES: BEGIN OF gty_s_verification_date,
             material          TYPE /lht/placo_mat_number,
             verification_date TYPE timestampl,
           END OF gty_s_verification_date.
    TYPES gty_t_verification_date TYPE STANDARD TABLE OF gty_s_verification_date WITH DEFAULT KEY.

    TYPES: BEGIN OF gty_s_interchange_worklist,
             material    TYPE /lht/placo_mat_number,
             criticality TYPE int4,
           END OF gty_s_interchange_worklist.
    TYPES gty_t_interchange_worklist TYPE STANDARD TABLE OF gty_s_interchange_worklist WITH DEFAULT KEY.

    TYPES: BEGIN OF gty_s_open_pos_materials,
             material TYPE /lht/placo_mat_number,
             open_pos TYPE int4,
             days_since_oldest_open_po type int4,
           END OF gty_s_open_pos_materials.
    TYPES gty_t_open_pos_materials TYPE STANDARD TABLE OF gty_s_open_pos_materials WITH DEFAULT KEY.

    TYPES: BEGIN OF gty_s_daily_consumption,
             date   TYPE dats,
             amount TYPE int4,
           END OF gty_s_daily_consumption.
    TYPES gty_t_daily_consumption   TYPE STANDARD TABLE OF gty_s_daily_consumption WITH DEFAULT KEY.

    TYPES gty_r_planning_department TYPE RANGE OF /lht/placo_planning_department.
    TYPES gty_r_materials           TYPE RANGE OF /lht/placo_mat_number.

    "!
    "! Filters stock data for a specific material.
    "!
    "! @parameter it_stock_data     | Stock data for all materials
    "! @parameter iv_materialnumber | Material number to filter for
    "! @parameter rt_stock_data     | Filtered stock data for the specified material
    METHODS get_relevant_stock
      IMPORTING
        it_stock_data        TYPE /lht/lo_mb_stock_srv=>tyt_material_stock
        iv_materialnumber    TYPE /lht/placo_mat_number
      RETURNING
        VALUE(rt_stock_data) TYPE /lht/lo_mb_stock_srv=>tyt_material_stock.

    "!
    "! Calculates consumption per day for the last year.
    "!
    "! @parameter it_consumption        | Consumption data grouped by date
    "! @parameter rt_daily_consumptions | Daily consumption for 365 days
    "! @raising   /lht/cx_placo_check   | If calculation fails
    METHODS getConsumptionPerDay
      IMPORTING
        it_consumption               TYPE /lht/cl_placo_event_processing=>gty_t_daily_consumption
      RETURNING
        VALUE(rt_daily_consumptions) TYPE /lht/cl_placo_event_calc=>gty_t_daily_consumption
      RAISING
        /lht/cx_placo_check.

    "!
    "! Persists worklist data to the database.
    "!
    "! @parameter it_worklists        | Worklist data to be persisted
    "! @parameter it_materials        | Related material data
    "! @raising   /lht/cx_placo_check | If persistence fails
    METHODS persist_worklist
      IMPORTING
        it_worklists TYPE /lht/cl_placo_event_processing=>gty_t_r_placo_mast
        it_materials TYPE /lht/cl_placo_event_processing=>gty_t_r_placo_mat
      RAISING
        /lht/cx_placo_check.

    "!
    "! Persists material data to the database.
    "!
    "! @parameter it_materials        | Material data to be persisted
    "! @raising   /lht/cx_placo_check | If persistence fails
    METHODS persist_materials
      IMPORTING
        it_materials TYPE /lht/cl_placo_event_processing=>gty_t_r_placo_mat
      RAISING
        /lht/cx_placo_check.

    "! <p class="shorttext synchronized"></p>
    "!
    "! @parameter it_stock_data       | <p class="shorttext synchronized"></p>
    "! @parameter rt_aggr_stock_data  | <p class="shorttext synchronized"></p>
    "! @raising   /lht/cx_placo_check | <p class="shorttext synchronized"></p>
    METHODS aggregate_stock_per_mat
      IMPORTING
        it_stock_data             TYPE /lht/lo_mb_stock_srv=>tyt_material_stock
      RETURNING
        VALUE(rt_aggr_stock_data) TYPE gty_t_stock_data
      RAISING
        /lht/cx_placo_check.

    "!
    "! Persists material and worklist entities to the database.
    "!
    "! @parameter it_material_data    | Material data to be persisted
    "! @parameter it_worklist_data    | Worklist data to be persisted
    "! @raising   /lht/cx_placo_check | If an error occurs during persistence
    METHODS persist_entities
      IMPORTING
        it_material_data TYPE gty_t_r_placo_mat
        it_worklist_data TYPE gty_t_r_placo_mast
      RAISING
        /lht/cx_placo_check.

    "!
    "! Calculates the annual consumption for a material based on consumption data.
    "!
    "! @parameter iv_matnr              | Material number
    "! @parameter it_consumption_data   | Consumption data for all materials
    "! @parameter iv_months_in_past |
    "! @parameter rv_annual_consumption | Calculated annual consumption value
    "! @raising   /lht/cx_placo_check   | If annual consumption cannot be calculated
    METHODS get_annual_consumption
      IMPORTING
        iv_matnr                     TYPE /lht/placo_mat_number
        it_consumption_data          TYPE /lht/lo_mb_consumption_srv=>tyt_consumption_data
        iv_months_in_past            TYPE int4
      RETURNING
        VALUE(rv_annual_consumption) TYPE gty_packed_number
      RAISING
        /lht/cx_placo_check.

*    METHODS get_safety_stock
*      IMPORTING
*        iv_materialnumber      TYPE /lht/placo_mat_number
*        it_material_data       TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_data
*      RETURNING
*        VALUE(rv_safety_stock) TYPE /lht/placo_safety_stock. "/lht/cm_lo_mm_materials_srv=>tys_material_data-safety_stock.

    "!
    "! Retrieves open purchase order positions for materials.
    "!
    "! @parameter it_materialnumber | List of material numbers
    "! @parameter et_last_purchase_orders |
    "! @parameter rt_open_pos       | List of open purchase order positions
    "! @raising /lht/cx_placo_check |
    METHODS get_purchase_order_data
      IMPORTING
        it_materialnumber       TYPE gty_t_placo_mat_number
      EXPORTING
        et_last_purchase_orders TYPE /lht/lo_me_po_data_srv=>tyt_purchase_order_items
      RETURNING
        VALUE(rt_open_pos)      TYPE gty_t_open_pos_materials
      RAISING
        /lht/cx_placo_check.

    "!
    "! Retrieves the previous forecast value for a disposition set.
    "!
    "! @parameter iv_disposet | Disposition set
    "! @parameter rv_forecast | Previous forecast value
    METHODS get_old_forecast
      IMPORTING
        iv_disposet        TYPE /lht/placo_mrp_set
      RETURNING
        VALUE(rv_forecast) TYPE int4.

    "!
    "! Retrieves the latest forecast value for a disposition set.
    "!
    "! @parameter iv_disposet         | Disposition set
    "! @parameter ev_qualityindicator | Quality indicator for the forecast
    "! @parameter rv_forecast         | Latest forecast value
    METHODS get_new_forecast
      IMPORTING
         iv_disposet        TYPE /lht/placo_mrp_set
      EXPORTING
        ev_qualityIndicator TYPE int4
      RETURNING
        VALUE(rv_forecast)  TYPE int4.

    "!
    "! Retrieves the replenishment time for a disposition set.
    "!
    "! @parameter iv_disposet           | Disposition set
    "! @parameter rv_replenishment_time | Calculated replenishment time
    "! @raising   /lht/cx_placo_check   | If replenishment time cannot be calculated
    METHODS get_replenishment_time
      IMPORTING
        iv_disposet                  TYPE /lht/placo_mrp_set
      RETURNING
        VALUE(rv_replenishment_time) TYPE /lht/placo_replenishment_time
      RAISING
        /lht/cx_placo_check.

    "!
    "! Retrieves daily consumption data for a material.
    "!
    "! @parameter iv_materialnumber    | Material number
    "! @parameter it_daily_consumption | Daily consumption data for all materials
    "! @parameter rt_daily_consumption | Daily consumption data for the specified material
    "! @raising   /lht/cx_placo_check  | If daily consumption data cannot be retrieved
    METHODS get_daily_consumption
      IMPORTING
        iv_materialnumber           TYPE /lht/placo_mat_number
        it_daily_consumption        TYPE /lht/lo_md_placo_srv=>tyt_daily_consumption
      RETURNING
        VALUE(rt_daily_consumption) TYPE /lht/cl_placo_event_calc=>gty_t_daily_consumption
      RAISING
        /lht/cx_placo_check.

    "!
    "! Converts timestamp to date for verification date.
    "!
    "! @parameter iv_last_interchange_verific_d | Timestamp of last verification
    "! @parameter rv_date                       | Converted date
    METHODS getVerificationDate
      IMPORTING
        iv_last_interchange_verific_d TYPE timestampl
      RETURNING
        VALUE(rv_date)                TYPE d.

    "!
    "! Calculates a date in the past for verification checks.
    "!
    "! @parameter iv_months_in_past            | Number of months to go back
    "! @parameter rv_verification_date_in_past | Date in the past
    "! @raising   /lht/cx_placo_check          | If date calculation fails
    METHODS getVerificationDateInPast
      IMPORTING
        iv_months_in_past                   TYPE i
      RETURNING
        VALUE(rv_verification_date_in_past) TYPE d
      RAISING
        /lht/cx_placo_check.

*    METHODS get_reorder_lvl
*      IMPORTING
*        iv_materialnumber TYPE /lht/placo_mat_number
*        it_material_data  TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_data
*      RETURNING
*        VALUE(r_result)   TYPE int4.

*    METHODS get_moving_average_price
*      IMPORTING
*        iv_materialnumber              TYPE /lht/placo_mat_number
*        it_valuations_table            TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_valuations
*      RETURNING
*        VALUE(rv_moving_average_price) TYPE /lht/cl_placo_event_calc=>gty_packed_number.

    "!
    "! Handles worklist information based on determination results.
    "!
    "! @parameter iv_add_to_worklist_cc  | Flag for consumption change worklist
    "! @parameter iv_add_to_worklist_rp  | Flag for reorder point worklist
    "! @parameter iv_add_to_worklist_int | Flag for interchange worklist
    "! @parameter iv_add_to_worklist_zmm | Flag for ZMM class worklist
    "! @parameter iv_add_to_worklist_os |
    "! @parameter iv_materialnumber      | Material number
    "! @parameter iv_criticality_rp      | Criticality level for reorder point
    "! @parameter iv_criticality_cc      | Criticality level for consumption change
    "! @parameter iv_criticality_int     | Criticality level for interchange
    "! @parameter iv_criticality_zmm     | Criticality level for ZMM class
    "! @parameter iv_criticality_os |
    "! @parameter ct_mat_worklist_info   | List of worklist information to be updated
    METHODS handle_worklist_info
      IMPORTING
        iv_add_to_worklist_cc  TYPE abap_boolean
        iv_add_to_worklist_rp  TYPE abap_boolean
        iv_add_to_worklist_int TYPE abap_boolean
        iv_add_to_worklist_zmm TYPE abap_boolean
        iv_add_to_worklist_os  TYPE abap_boolean
        iv_materialnumber      TYPE /lht/placo_mat_number
        iv_criticality_rp      TYPE int4
        iv_criticality_cc      TYPE int4
        iv_criticality_int     TYPE int4
        iv_criticality_zmm     TYPE int4
        iv_criticality_os      TYPE int4
      CHANGING
        ct_mat_worklist_info   TYPE gty_t_r_placo_mast.

    "!
    "! Adds a worklist entry to the worklist information table.
    "!
    "! @parameter iv_materialnumber     | Material number
    "! @parameter iv_criticality        | Criticality level
    "! @parameter iv_worklist_indicator | Worklist indicator type
    "! @parameter ct_mat_worklist_info  | List of worklist information to be updated
    METHODS append_worklist_entry
      IMPORTING
        iv_materialnumber     TYPE /lht/placo_mat_number
        iv_criticality        TYPE int4
        iv_worklist_indicator TYPE int1
      CHANGING
        ct_mat_worklist_info  TYPE gty_t_r_placo_mast.

    "!
    "! Retrieves data from various OData services for material processing.
    "!
    "! @parameter it_matnr                    | List of material numbers
    "! @parameter et_material_data            | Retrieved material data
    "! @parameter et_mrpset_data              | Retrieved MRP set data
    "! @parameter et_mat_desc_data            | Retrieved material description data
    "! @parameter et_material_valuations_data | Retrieved material valuation data
    "! @parameter et_consumption_data         | Retrieved consumption data
    "! @parameter et_mat_stock_data           | Retrieved material stock data
    "! @parameter et_dailyconsumption_data    | Retrieved daily consumption data
    "! @parameter et_mat_inter_data           | Retrieved material interchangeability data
    "! @parameter et_mat_rest_inter_data      | Retrieved restricted interchangeability data
    "! @parameter et_zmmclass_data            | Retrieved ZMM class data
    "! @parameter et_relevant_materials       | List of relevant materials
    "! @parameter et_mrpsets_to_mat_data |
    "! @parameter et_purchase_requisition_data |
    "! @parameter et_max_material_requests |
    "! @raising   /lht/cx_placo_check         | If OData service retrieval fails
    "! @parameter et_vk13_mat_mrpset_data     | Retrieved VK13 material MRP set data
    METHODS read_odata_services
      IMPORTING
        it_matnr                     TYPE gty_t_placo_mat_number
      EXPORTING
        et_material_data             TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_data
        et_mrpset_data               TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_mrpsets
        et_mat_desc_data             TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_descriptions
        et_material_valuations_data  TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_valuations
        et_consumption_data          TYPE /lht/lo_mb_consumption_srv=>tyt_consumption_data
        et_mat_stock_data            TYPE /lht/lo_mb_stock_srv=>tyt_material_stock
*        et_vk13_mat_mrpset_data      TYPE /lht/sd_vk13_srv=>tyt_material_price
        et_dailyconsumption_data     TYPE /lht/lo_md_placo_srv=>tyt_daily_consumption
        et_mat_inter_data            TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_interchangeabil_2
        et_mat_rest_inter_data       TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_restricted_inte_2
        et_zmmclass_data             TYPE /lht/lo_md_placo_srv=>tyt_zmmclass_worklist
        et_relevant_materials        TYPE gty_t_placo_matnr
        et_mrpsets_to_mat_data       TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_mrpsets
        et_purchase_requisition_data TYPE /lht/lo_me_pr_data_srv=>tyt_purchase_requisition_ite_2
        et_max_material_requests     TYPE /lht/cl_placo_max_mat_request=>gty_t_mat_request
      RAISING
        /lht/cx_placo_check.

    "!
    "! Determines if material should be added to worklists based on various criteria.
    "!
    "! @parameter iv_relevant_stock         | Current stock level
    "! @parameter iv_open_pos               | Number of open purchase orders
    "! @parameter iv_forecast_old           | Previous forecast value
    "! @parameter iv_forecast_new           | New forecast value
    "! @parameter iv_sugstn_for_reorder_lvl | Suggested reorder level
    "! @parameter iv_reorder_lvl            | Current reorder level
    "! @parameter iv_materialnumber         | Material number
    "! @parameter iv_annual_consumption |
    "! @parameter it_zmmclass_data          | ZMM class data for the material
    "! @parameter is_interchange_worklist   | Interchange worklist entry if exists
    "! @parameter is_interchange_relevant |
    "! @parameter iv_leading_partnumber |
    "! @parameter iv_stock_reach |
    "! @parameter iv_created_on |
    "! @parameter iv_consumption_last_two_years |
    "! @parameter iv_hold_on_stock_flag |
    "! @parameter iv_disposet |
    "! @parameter iv_open_purchase_requisitions |
    "! @parameter iv_mat_req_in_last_4_weeks |
    "! @parameter ev_add_to_worklist_cc     | Output flag for consumption change worklist
    "! @parameter ev_add_to_worklist_rp     | Output flag for reorder point worklist
    "! @parameter ev_add_to_worklist_int    | Output flag for interchange worklist
    "! @parameter ev_add_to_worklist_zmm    | Output flag for ZMM class worklist
    "! @parameter ev_add_to_worklist_os |
    "! @parameter ct_mat_worklist_info      | List of worklist information to be updated
    "! @raising   /lht/cx_placo_check       | If an error occurs during determination
    METHODS determine_worklist
      IMPORTING
        iv_relevant_stock             TYPE /lht/placo_material_stock
        iv_open_pos                   TYPE int4
        iv_forecast_old               TYPE int4
        iv_forecast_new               TYPE int4
        iv_sugstn_for_reorder_lvl     TYPE gty_packed_number
        iv_reorder_lvl                TYPE int4
        iv_materialnumber             TYPE matnr
        iv_annual_consumption         TYPE gty_packed_number
        it_zmmclass_data              TYPE /lht/lo_md_placo_srv=>tyt_zmmclass_worklist
        is_interchange_worklist       TYPE gty_s_interchange_worklist
        is_interchange_relevant       TYPE abap_boolean
        iv_leading_partnumber         TYPE /lht/placo_leading_part
        iv_stock_reach                TYPE gty_packed_number
        iv_created_on                 TYPE timestampl
        iv_consumption_last_two_years TYPE gty_packed_number
        iv_hold_on_stock_flag         TYPE /lht/placo_hold_on_stock_flag
        iv_disposet                   TYPE /lht/placo_mrp_set
        iv_open_purchase_requisitions TYPE int4
        iv_mat_req_in_last_4_weeks    TYPE abap_boolean OPTIONAL
      EXPORTING
        ev_add_to_worklist_cc         TYPE abap_boolean
        ev_add_to_worklist_rp         TYPE abap_boolean
        ev_add_to_worklist_int        TYPE abap_boolean
        ev_add_to_worklist_zmm        TYPE abap_boolean
        ev_add_to_worklist_os         TYPE abap_boolean
      CHANGING
        ct_mat_worklist_info          TYPE gty_t_r_placo_mast
      RAISING
        /lht/cx_placo_check.

    "!
    "! Processes interchangeabilities for materials.
    "!
    "! @parameter it_mat_inter_data       | Interchangeability data
    "! @parameter it_mat_rest_inter_data  | Restricted interchangeability data
    "! @parameter et_interchange_worklist | Generated interchange worklist
    "! @raising   /lht/cx_placo_check     | If interchangeability processing fails
    METHODS process_interchangeabilities
      IMPORTING
        it_mat_inter_data       TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_interchangeabil_2
        it_mat_rest_inter_data  TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_restricted_inte_2
      EXPORTING
        et_interchange_worklist TYPE gty_t_interchange_worklist
      RAISING
        /lht/cx_placo_check.

    "!
    "! Identifies materials requiring interchangeability checks.
    "!
    "! @parameter it_materials            | Materials to check for interchangeability
    "! @parameter rt_interchange_worklist | Worklist of materials requiring interchangeability checks
    "! @raising   /lht/cx_placo_check     | If interchangeability check fails
    METHODS getInterchangeWorklistItems
      IMPORTING
        it_materials                   TYPE gty_t_verification_date
      RETURNING
        VALUE(rt_interchange_worklist) TYPE gty_t_interchange_worklist
      RAISING
        /lht/cx_placo_check.

    "!
    "! Merges normal and restricted interchangeability entries.
    "!
    "! @parameter it_restricted         | Restricted interchangeability entries
    "! @parameter it_interchanges       | Normal interchangeability entries
    "! @parameter rt_relevant_materials | Merged list of relevant materials
    METHODS mergeRelevantEntries
      IMPORTING
        it_restricted                TYPE gty_t_interchange_worklist
        it_interchanges              TYPE gty_t_interchange_worklist
      RETURNING
        VALUE(rt_relevant_materials) TYPE gty_t_interchange_worklist.

    "!
    "! Checks if interchangeability verification is needed based on verification date.
    "!
    "! @parameter iv_last_verification_date | Last verification date
    "! @parameter rv_result                 | Criticality level based on verification date
    "! @raising   /lht/cx_placo_check       | If verification check fails
    METHODS check_interchange_verification
      IMPORTING
        iv_last_verification_date TYPE /lht/placo_dats
      RETURNING
        VALUE(rv_result)          TYPE i
      RAISING
        /lht/cx_placo_check.

    "!
    "! Groups daily consumption data by date.
    "!
    "! @parameter it_daily_consumptions | Daily consumption data
    "! @parameter rt_daily_consumptions | Daily consumption grouped by date
    "! @raising   /lht/cx_placo_check   | If grouping fails
    METHODS getDailyConsumptionPerDate
      IMPORTING
        it_daily_consumptions        TYPE /lht/lo_md_placo_srv=>tyt_daily_consumption
      RETURNING
        VALUE(rt_daily_consumptions) TYPE gty_t_daily_consumption
      RAISING
        /lht/cx_placo_check.

    "!
    "! Checks if a worklist entry already exists for a material.
    "!
    "! @parameter iv_relevant_material | Material to check
    "! @parameter rt_existing_worklists |
    METHODS checkForExistingWorklist
      IMPORTING
        iv_relevant_material         TYPE /lht/placo_mat_number
      RETURNING
        VALUE(rt_existing_worklists) TYPE gty_t_a_placo_wrk.

    "!
    "! Deletes all worklist entries for a material.
    "!
    "! @parameter it_worklists |
    "! @parameter iv_consumption_change |
    "! @parameter iv_reorder_point_breach |
    "! @parameter iv_interchangeabilities |
    "! @parameter iv_zmm |
    "! @parameter iv_overstock |
    METHODS deleteWorklistEntry
      IMPORTING
        it_worklists            TYPE gty_t_a_placo_wrk
        iv_consumption_change   TYPE abap_boolean
        iv_reorder_point_breach TYPE abap_boolean
        iv_interchangeabilities TYPE abap_boolean
        iv_zmm                  TYPE abap_boolean
        iv_overstock            TYPE abap_boolean.

    "!
    "! Filters materials based on planning department.
    "!
    "! @parameter it_materials | Materials to filter
    "! @parameter rt_materials | Filtered materials matching planning departments
    METHODS checkMatForPlanDepartment
      IMPORTING
        it_materials        TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_data
      RETURNING
        VALUE(rt_materials) TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_data.

    "!
    "! Creates daily consumption data based on a forecast value.
    "!
    "! @parameter iv_forecast             | Forecast value
    "! @parameter rt_forecast_consumption | Daily consumption data derived from forecast
    METHODS getDailyConsumptionForForecast
      IMPORTING
        iv_forecast                    TYPE int4
      RETURNING
        VALUE(rt_forecast_consumption) TYPE /lht/cl_placo_event_calc=>gty_t_daily_consumption.

    "!
    "! Compares the relevant materials to backend material data.
    "! If the relevant material has no data, new entry in error log is created.
    "!
    "! @parameter it_material_data | Material data from backend
    "! @parameter it_relevant_data | Relevant materialnumbers
    "! @parameter rt_relevant_data | All relevant materialnumbers with existing backend information
    METHODS compareMaterialDataToRelevant
      IMPORTING
        it_material_data        TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_data
        it_relevant_data        TYPE gty_t_placo_matnr
      RETURNING
        VALUE(rt_relevant_data) TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_data.

    METHODS get_single_mat_disposet
      IMPORTING
        it_mrpsets                     TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_mrpsets
      RETURNING
        VALUE(rt_singel_mat_disposets) TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_mrpsets.

    METHODS checkForEmptyMaterialNumbers
      IMPORTING
        it_matnr            TYPE /lht/cl_placo_event_processing=>gty_t_placo_mat_number
      RETURNING
        VALUE(rt_materials) TYPE /lht/cl_placo_event_processing=>gty_t_placo_mat_number.

    METHODS compareSuggestions
      IMPORTING
        iv_suggested_reorder_lvl        TYPE /lht/cl_placo_event_calc=>gty_packed_number
        iv_forecasted_reorder_lvl       TYPE /lht/cl_placo_event_calc=>gty_packed_number
      RETURNING
        VALUE(rv_suggested_reorder_lvl) TYPE /lht/cl_placo_event_calc=>gty_packed_number.

    METHODS getYearsAgo
      IMPORTING
        iv_years_in_past        TYPE i
      RETURNING
        VALUE(rv_years_in_past) TYPE timestampl.

    METHODS deleteMaterialFromErrorLog
      IMPORTING it_materialnumber TYPE gty_t_placo_mat_number.

    METHODS sumOpenPurchaseRequisitions
      IMPORTING
        it_purchase_requisitions  TYPE /lht/lo_me_pr_data_srv=>tyt_purchase_requisition_ite_2
        iv_materialnumber         TYPE /lht/placo_mat_number
      RETURNING
        VALUE(rv_sum_of_open_prs) TYPE int4.

    METHODS getLastMaterialRequest
      IMPORTING
        it_material_requests            TYPE /lht/cl_placo_max_mat_request=>gty_t_mat_request
      RETURNING
        VALUE(rv_last_material_request) TYPE timestampl.

    METHODS getLastPurchaseOrders
      IMPORTING
        it_materialnumber              TYPE /lht/cl_placo_event_processing=>gty_t_placo_mat_number
        it_po_data                     TYPE /lht/lo_me_po_data_srv=>tyt_purchase_order_items
      RETURNING
        VALUE(rt_last_purchase_orders) TYPE /lht/lo_me_po_data_srv=>tyt_purchase_order_items.

    METHODS getPlanningDepartmentRange
      RETURNING
        VALUE(rr_plan_departments) TYPE gty_r_planning_department.

    METHODS getMaterialsRange
      IMPORTING
        it_materials        TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_data
      RETURNING
        VALUE(rr_materials) TYPE gty_r_materials.

    METHODS checkForMaterialRequest
      IMPORTING
        it_material_requests     TYPE /lht/cl_placo_max_mat_request=>gty_t_mat_request
        iv_weeks_in_past         TYPE i
      RETURNING
        VALUE(rv_mat_req_exists) TYPE abap_boolean.

    METHODS checkSingleMRPSet
      IMPORTING
        iv_mrpset                            TYPE /lht/placo_mrp_set
        it_mrpsets                           TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_mrpsets
      RETURNING
        VALUE(rv_is_single_material_mrp_set) TYPE /lht/placo_single_mat_mrp_set.

    METHODS getDaysSinceOldestOpenPO
      IMPORTING
        iv_oldest_date                   TYPE timestampl
      RETURNING
        VALUE(rv_days_since_oldest_date) TYPE int4.

    METHODS getOldestOpenPO
      IMPORTING
        it_open_puchase_orders TYPE /lht/lo_me_po_data_srv=>tyt_purchase_order_items
      RETURNING
        VALUE(rv_oldest_date)  TYPE timestampl.

    METHODS comparisonReplenishmentTime
      IMPORTING
        iv_replenishment_time        TYPE /lht/placo_replenishment_time
        iv_days_since_oldest_open_po TYPE int4
      RETURNING
        VALUE(rv_replenishment_time) TYPE /lht/placo_replenishment_time.

    METHODS checkInterchangeRelevancy
      IMPORTING
        iv_single_disposet                     TYPE /lht/placo_mrp_set
        it_restricted_interchange              TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_restricted_inte_2
       RETURNING
         VALUE(rv_interchangeability_relevant) TYPE abap_boolean.

    METHODS deleteMatWithDeletionInd
      IMPORTING
        it_material_data        TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_data
      RETURNING
        VALUE(rt_material_data) TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_data.

ENDCLASS.



CLASS /LHT/CL_PLACO_EVENT_PROCESSING IMPLEMENTATION.


  METHOD aggregate_stock_per_mat.
    " This method aggregates the stock data for each material number.
    " It takes a table of stock data as input and returns a table with aggregated stock data.

    "~ Loop through the input stock data and aggregate the stock per material number
    "~ using a TRY-CATCH block to handle any exceptions that may occur during the process.
    TRY.
        LOOP AT it_stock_data ASSIGNING FIELD-SYMBOL(<fs_import_stock_data>).
          ASSIGN rt_aggr_stock_data[ materialnumber = <fs_import_stock_data>-material_number ] TO FIELD-SYMBOL(<fs_export_stock_data>).

          IF sy-subrc = 0.
            " If the material is already in the aggregation table, add the stock
            <fs_export_stock_data>-stock += <fs_import_stock_data>-valuated_unrestricted_uses.
          ELSE.
            " If the material is not yet in the aggregation table, add a new entry
            INSERT VALUE #( materialnumber = <fs_import_stock_data>-material_number
                            stock          = <fs_import_stock_data>-valuated_unrestricted_uses ) INTO TABLE rt_aggr_stock_data.
          ENDIF.
        ENDLOOP.
      CATCH cx_root.
        RAISE EXCEPTION NEW /lht/cx_placo_check( iv_error_message = /lht/cx_placo_check=>aggregate_stock_per_mat ).
    ENDTRY.
  ENDMETHOD.


  METHOD handle_worklist_info.
    IF iv_add_to_worklist_cc = abap_true.
      append_worklist_entry(
        EXPORTING
          iv_materialnumber     = iv_materialnumber
          iv_worklist_indicator = /lht/if_placo_constants=>gc_worklists-consumption_change
          iv_criticality        = iv_criticality_cc
        CHANGING
          ct_mat_worklist_info  = ct_mat_worklist_info ).
    ENDIF.

    IF iv_add_to_worklist_rp = abap_true.
      append_worklist_entry(
        EXPORTING
          iv_materialnumber     = iv_materialnumber
          iv_worklist_indicator = /lht/if_placo_constants=>gc_worklists-reorder_point_breach
          iv_criticality        = iv_criticality_rp
        CHANGING
          ct_mat_worklist_info  = ct_mat_worklist_info ).
    ENDIF.

    IF iv_add_to_worklist_int = abap_true.
      append_worklist_entry(
        EXPORTING
          iv_materialnumber     = iv_materialnumber
          iv_worklist_indicator = /lht/if_placo_constants=>gc_worklists-interchangeabilities
          iv_criticality        = iv_criticality_int
        CHANGING
          ct_mat_worklist_info  = ct_mat_worklist_info ).
    ENDIF.

    IF iv_add_to_worklist_zmm = abap_true.
      append_worklist_entry(
        EXPORTING
          iv_materialnumber     = iv_materialnumber
          iv_worklist_indicator = /lht/if_placo_constants=>gc_worklists-zmm
          iv_criticality        = iv_criticality_zmm
        CHANGING
          ct_mat_worklist_info  = ct_mat_worklist_info ).
    ENDIF.

    IF iv_add_to_worklist_os = abap_true.
      append_worklist_entry(
        EXPORTING
          iv_materialnumber     = iv_materialnumber
          iv_worklist_indicator = /lht/if_placo_constants=>gc_worklists-overstock
          iv_criticality        = iv_criticality_os
        CHANGING
          ct_mat_worklist_info  = ct_mat_worklist_info ).
    ENDIF.
  ENDMETHOD.


  METHOD compareSuggestions.
    IF iv_suggested_reorder_lvl > iv_forecasted_reorder_lvl.
      rv_suggested_reorder_lvl = iv_suggested_reorder_lvl.
    ELSE.
      rv_suggested_reorder_lvl = iv_forecasted_reorder_lvl.
    ENDIF.
  ENDMETHOD.


  METHOD deleteWorklistEntry.
    DATA lt_worklist_uuids TYPE STANDARD TABLE OF sysuuid_x16.

    DATA(lv_materialnumber) = VALUE #( it_worklists[ 1 ]-MaterialNumber OPTIONAL ).

    LOOP AT it_worklists REFERENCE INTO DATA(ls_worklist).
      CASE ls_worklist->worklist.
        WHEN /lht/if_placo_constants=>gc_worklists-consumption_change.
          IF iv_consumption_change = abap_false.
            INSERT ls_worklist->uuid INTO TABLE lt_worklist_uuids.
          ENDIF.
        WHEN /lht/if_placo_constants=>gc_worklists-reorder_point_breach.
          IF iv_reorder_point_breach = abap_false.
            INSERT ls_worklist->uuid INTO TABLE lt_worklist_uuids.
          ENDIF.
        WHEN /lht/if_placo_constants=>gc_worklists-interchangeabilities.
          IF iv_interchangeabilities = abap_false.
            INSERT ls_worklist->uuid INTO TABLE lt_worklist_uuids.
          ENDIF.
        WHEN /lht/if_placo_constants=>gc_worklists-zmm.
          IF iv_zmm = abap_false.
            INSERT ls_worklist->uuid INTO TABLE lt_worklist_uuids.
          ENDIF.
        WHEN /lht/if_placo_constants=>gc_worklists-overstock.
          IF iv_overstock = abap_false.
            INSERT ls_worklist->uuid INTO TABLE lt_worklist_uuids.
          ENDIF.
      ENDCASE.
    ENDLOOP.

    IF iv_consumption_change   = abap_false AND
       iv_interchangeabilities = abap_false AND
       iv_reorder_point_breach = abap_false AND
       iv_zmm                  = abap_false AND
       iv_overstock            = abap_false AND
       lv_materialnumber IS NOT INITIAL.
      SELECT master_uuid FROM /lht/a_placo_mat  "#EC CI_SEL_NESTED
        WHERE material = @lv_materialnumber
        INTO TABLE @DATA(lt_all_material_uuids).

      MODIFY ENTITIES OF /lht/r_placo_materials
             ENTITY Materials
             DELETE FROM VALUE #( FOR material IN lt_all_material_uuids
                                    ( MasterUUID = material-master_uuid ) ).
    ENDIF.

*    COMMIT ENTITIES.

    MODIFY ENTITIES OF /lht/r_placo_worklist
           ENTITY Worklist
           DELETE FROM VALUE #( FOR worklist IN lt_worklist_uuids
                                ( UUID = worklist ) ).
  ENDMETHOD.


  METHOD getDailyConsumptionForForecast.
    DATA(lv_daily_consumption) = CONV /lht/cl_placo_event_calc=>gty_packed_number( iv_forecast / 365 ).

    DO 365 TIMES.
      INSERT VALUE #( day         = sy-index
                      consumption = lv_daily_consumption ) INTO TABLE rt_forecast_consumption.
    ENDDO.
  ENDMETHOD.


  METHOD getInterchangeWorklistItems.
    LOOP AT it_materials ASSIGNING FIELD-SYMBOL(<ls_material>).
      IF <ls_material>-verification_date IS INITIAL.
        CONTINUE.
      ENDIF.

      DATA(lv_verification_date) = getVerificationDate( <ls_material>-verification_date ).

      TRY.
          DATA(lv_criticality) = check_interchange_verification( iv_last_verification_date = lv_verification_date ).
        CATCH /lht/cx_placo_check INTO DATA(cx_check).
          RAISE EXCEPTION NEW /lht/cx_placo_check( io_previous = cx_check ).
      ENDTRY.
      IF lv_criticality IS NOT INITIAL.
        INSERT VALUE gty_s_interchange_worklist( material    = <ls_material>-material
                                                 criticality = lv_criticality ) INTO TABLE rt_interchange_worklist.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD purch_requisition_processing.
    DATA lt_materials TYPE gty_t_placo_mat_number.
    DATA lt_ebeln     TYPE TABLE OF ebeln.

    " READ PURCHASE ORDER ITEMS : OData: /lht/lo_me_po_data_srv
    " ---------------------------------------------------------------------------
    APPEND iv_ebeln TO lt_ebeln.

    TEST-SEAM read_po_requi_item_data.
      /lht/cl_placo_odata_helper=>read_pr_item_data(
        EXPORTING
          it_purch_req = lt_ebeln
        IMPORTING
          et_pr_data   = DATA(lt_req_items) ).
    END-TEST-SEAM.

    SORT lt_req_items ASCENDING BY material.
    DELETE ADJACENT DUPLICATES FROM lt_req_items COMPARING material.

    LOOP AT lt_req_items ASSIGNING FIELD-SYMBOL(<ls_req_item>).
      APPEND <ls_req_item>-material TO lt_materials.
    ENDLOOP.

    TEST-SEAM material_processing_requi.
      material_processing( it_matnr = lt_materials ).
    END-TEST-SEAM.
  ENDMETHOD.


  METHOD getYearsAgo.
    DATA(lv_date_in_past) =
      CONV d( xco_cp=>sy->date( )->subtract( iv_year        = iv_years_in_past
                                             io_calculation = xco_cp_time=>date_calculation->ultimo )->as(
                                               xco_cp_time=>format->abap )->value ).

    CONVERT DATE lv_date_in_past INTO TIME STAMP rv_years_in_past TIME ZONE sy-zonlo.
  ENDMETHOD.


  METHOD getConsumptionPerDay.
    TRY.
        DATA(lv_today) = cl_abap_context_info=>get_system_date( ).
        DATA(lv_date_picker) = lv_today - 365.

        DO 365 TIMES.
          APPEND VALUE #( day         = sy-index
                          consumption = COND #( WHEN line_exists( it_consumption[ date = lv_date_picker ] )
                                                THEN it_consumption[ date = lv_date_picker ]-amount
                                                ELSE 0  ) ) TO rt_daily_consumptions.
          lv_date_picker += 1.
        ENDDO.
      CATCH cx_root.
        RAISE EXCEPTION NEW /lht/cx_placo_check( iv_error_message = /lht/cx_placo_check=>daily_consumption_per_day ).
    ENDTRY.
  ENDMETHOD.


  METHOD check_interchange_verification.
    " Exception Class for Processing
    DATA cx_placo TYPE REF TO /lht/cx_placo_check.

    TRY.
        DATA(lv_verification_33m) = getVerificationDateInPast( 33 ).
      CATCH /lht/cx_placo_check INTO cx_placo.
        RAISE EXCEPTION NEW /lht/cx_placo_check( io_previous = cx_placo ).
    ENDTRY.

    TRY.
        DATA(lv_verification_36m) = getVerificationDateInPast( 36 ).
      CATCH /lht/cx_placo_check INTO cx_placo.
        RAISE EXCEPTION NEW /lht/cx_placo_check( io_previous = cx_placo ).
    ENDTRY.

    IF iv_last_verification_date <= lv_verification_36m.
      rv_result = 1.
    ENDIF.

    IF iv_last_verification_date > lv_verification_36m AND
       iv_last_verification_date < lv_verification_33m.
      rv_result = 2.
    ENDIF.
  ENDMETHOD.


  METHOD getDailyConsumptionPerDate.
    TRY.
        LOOP AT it_daily_consumptions REFERENCE INTO DATA(ls_daily_consumption)
          GROUP BY ls_daily_consumption->booking_date INTO DATA(ls_g_booking_date).
          DATA(lv_converted_date) = CONV string( ls_g_booking_date ).
          lv_converted_date = lv_converted_date(8).

          INSERT VALUE #(
              date   = lv_converted_date
              amount = REDUCE i( INIT sum = 0
                                 FOR booking_date IN GROUP ls_g_booking_date
                                 NEXT sum += COND i(
                                   WHEN booking_date-movement_type = /lht/if_placo_constants=>gc_movement_types-bwa_984 OR
                                        booking_date-movement_type = /lht/if_placo_constants=>gc_movement_types-bwa_946 OR
                                        booking_date-movement_type = /lht/if_placo_constants=>gc_movement_types-bwa_262
                                   THEN - booking_date-amount
                                   ELSE booking_date-amount ) ) ) INTO TABLE rt_daily_consumptions.
        ENDLOOP.
      CATCH cx_root.
        RAISE EXCEPTION NEW /lht/cx_placo_check(
            iv_error_message = /lht/cx_placo_check=>daily_consumption_per_date ).
    ENDTRY.
  ENDMETHOD.


  METHOD compareMaterialDataToRelevant.
    DATA cl_error_log TYPE REF TO /lht/cl_placo_error_handling.
    DATA lt_materials_without_mat_data TYPE /lht/cl_placo_error_handling=>lty_materials.

    LOOP AT it_relevant_data REFERENCE INTO DATA(lv_relevant_data).
      IF line_exists( it_material_data[ material_number = lv_relevant_data->* ] ).
        INSERT it_material_data[ material_number = lv_relevant_data->* ] INTO TABLE rt_relevant_data.
      ELSE.
        INSERT lv_relevant_data->* INTO TABLE lt_materials_without_mat_data.
      ENDIF.
    ENDLOOP.

    IF lt_materials_without_mat_data IS NOT INITIAL.
      MESSAGE e200(/lht/placo_error_msg) INTO DATA(lv_error_message).

      cl_error_log = NEW #( ).

      cl_error_log->logmaterial( it_material = lt_materials_without_mat_data
                                 iv_message  = lv_error_message ).
    ENDIF.
  ENDMETHOD.


  METHOD persist_materials.
    TYPES lty_s_r_placo_mat_upd TYPE STRUCTURE FOR UPDATE /lht/r_placo_materials\\materials.
    TYPES lty_s_r_placo_mat_cre TYPE STRUCTURE FOR CREATE /lht/r_placo_materials\\materials.

    DATA ls_r_placo_mat_upd  TYPE lty_s_r_placo_mat_upd.
    DATA ls_r_placo_mat_cre  TYPE lty_s_r_placo_mat_cre.
    DATA lo_failed           TYPE RESPONSE FOR FAILED EARLY /lht/r_placo_materials.

    DATA lr_material         TYPE RANGE OF /lht/placo_mat_number.
    DATA lt_failed_materials TYPE gty_t_placo_mat_number.

    lr_material = VALUE #(
        FOR lv_material IN it_materials
        ( sign = 'I' option = 'EQ' low = lv_material-Material high = '' ) ).

    SELECT * FROM /lht/a_placo_mat "#EC CI_SEL_NESTED
      WHERE material IN @lr_material
      INTO TABLE @DATA(lt_placo_mat).

    TRY.
        LOOP AT it_materials REFERENCE INTO DATA(ls_material_data).
          CLEAR lo_failed.
          IF VALUE #( lt_placo_mat[ material = ls_material_data->Material ] OPTIONAL ) IS NOT INITIAL.
            MOVE-CORRESPONDING ls_material_data->* TO ls_r_placo_mat_upd.
            ls_r_placo_mat_upd-MasterUuid = lt_placo_mat[ material = ls_material_data->Material ]-master_uuid.

            MODIFY ENTITIES OF /lht/r_placo_materials
                   ENTITY Materials
                   UPDATE
                   FIELDS ( material plant mrpcontroller mpg mrpprofile mrparea mrpset
                            materialstock planningdepartment CustomsTariffCode sourcecustomstariff
                            reorderpoint annualconsumption TwoYearConsumption forecastconsumption forecastvariance
                            matclass MatDescription mattype MovingAveragePrice MovingAveragePriceCurrency
                            Priority ExtManufacturer FFFClass AircraftType StockLevel ReorderLevel
                            OrderQuantity SuggOptOrderQty StockReach StockReachNop ReplenishmentTime
                            SafetyStock LeadingPart Manufacturer CheckCustomsTariff WorkCenter
                            Unit DescrExtManufacturer PlannedDeliveryTime ArticleVariance
                            ConditionType HoldOnStockFlag LastPurchaseOrderOn LastAnfoOn
                            MatCreatedOn RecommendedReleasedQuantity LastChangedAt MaxDeliveryTimeOpenPo
                            MaxDelivTimeOpenPoReorderPoint SingleMaterialMrpSetFlag )
                   WITH VALUE #( ( ls_r_placo_mat_upd ) )
                   FAILED lo_failed.

            CLEAR ls_r_placo_mat_upd.
          ELSE.
            MOVE-CORRESPONDING ls_material_data->* TO ls_r_placo_mat_cre.
            " ls_r_placo_mast_cre-%control-Material = if_abap_behv=>mk-on. TODO: All behv needs to be to ON in all create and update!!

            MODIFY ENTITIES OF /lht/r_placo_materials
                   ENTITY Materials
                   CREATE AUTO FILL CID
                   SET FIELDS WITH VALUE #( ( ls_r_placo_mat_cre ) )
                   FAILED lo_failed.

            CLEAR ls_r_placo_mat_cre.
          ENDIF.

          IF lo_failed IS NOT INITIAL.
            INSERT ls_material_data->Material INTO TABLE lt_failed_materials.
          ENDIF.
        ENDLOOP.
      CATCH cx_root.
        RAISE EXCEPTION NEW /lht/cx_placo_check(
            iv_error_message = /lht/cx_placo_check=>persist_materials ).
    ENDTRY.

    IF lt_failed_materials IS NOT INITIAL.
      RAISE EXCEPTION NEW /lht/cx_placo_check(
                              iv_error_message = /lht/cx_placo_check=>persist_materials
                              it_materials     = lt_failed_materials ).
    ENDIF.
  ENDMETHOD.


  METHOD getVerificationDate.
    CONVERT TIME STAMP iv_last_interchange_verific_d TIME ZONE 'UTC' INTO DATE rv_date.
  ENDMETHOD.


  METHOD getVerificationDateInPast.
    TRY.
        rv_verification_date_in_past =
          xco_cp=>sy->date( )->subtract( iv_month       = iv_months_in_past
                                         io_calculation = xco_cp_time=>date_calculation->ultimo )->as( xco_cp_time=>format->abap )->value.
      CATCH cx_root.
        RAISE EXCEPTION NEW /lht/cx_placo_check( iv_error_message = /lht/cx_placo_check=>verification_date_in_past ).
    ENDTRY.
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


  METHOD deleteMaterialFromErrorLog.
    DATA lr_material TYPE RANGE OF /lht/placo_mat_number.

    lr_material = VALUE #( FOR material IN it_materialnumber
                           ( sign   = `I`
                             option = `EQ`
                             low    = material ) ).

    SELECT * FROM /lht/r_placo_error_log "#EC CI_SEL_NESTED
      WHERE material IN @lr_material
      INTO TABLE @DATA(lt_logs_to_be_deleted).

*    MODIFY ENTITIES OF /lht/r_placo_error_log
*        ENTITY ErrorLog
*        ALL FIELDS WITH VALUE #( FOR log IN lt_logs_to_be_deleted ( UUID = log-uuid ) )
*        RESULT DATA(lt_result).

    MODIFY ENTITIES OF /lht/r_placo_error_log
           ENTITY ErrorLog
           DELETE FROM
           VALUE #( FOR log IN lt_logs_to_be_deleted
                    ( uuid = log-uuid ) ).
  ENDMETHOD.


  METHOD get_daily_consumption.
    " Exception Class for Processing
    DATA cx_placo TYPE REF TO /lht/cx_placo_check.

    TRY.
        DATA(lt_consumption) = getdailyconsumptionperdate(
                                 it_daily_consumptions = VALUE #( FOR daily_consumption IN it_daily_consumption
                                                                  WHERE ( material_number = iv_materialnumber ) ( daily_consumption ) ) ).
      CATCH /lht/cx_placo_check INTO cx_placo.
        RAISE EXCEPTION NEW /lht/cx_placo_check( io_previous = cx_placo ).
    ENDTRY.

    TRY.
        rt_daily_consumption = getconsumptionperday( lt_consumption ).
      CATCH /lht/cx_placo_check INTO cx_placo.
        RAISE EXCEPTION NEW /lht/cx_placo_check( io_previous = cx_placo ).
    ENDTRY.
  ENDMETHOD.


  METHOD get_replenishment_time.
    TRY.
        IF iv_disposet IS INITIAL.
          RETURN.
        ENDIF.

        SELECT SINGLE calculated_replenishment_time "#EC CI_SEL_NESTED
          FROM /lht/a_placo_rp
          WHERE local_created_at = (
              SELECT MAX( local_created_at ) FROM /lht/a_placo_rp )
            AND disposet         = @iv_disposet
          INTO @rv_replenishment_time.
      CATCH cx_root.
        RAISE EXCEPTION NEW /lht/cx_placo_check( iv_error_message = /lht/cx_placo_check=>replenishment_time ).
    ENDTRY.
  ENDMETHOD.


  METHOD get_old_forecast.
    IF iv_disposet IS INITIAL.
      RETURN.
    ENDIF.

    SELECT DISTINCT local_created_at  "#EC CI_SEL_NESTED
      FROM /lht/a_placo_fc
      ORDER BY local_created_at DESCENDING
      INTO TABLE @DATA(lt_dates).

    IF lt_dates IS INITIAL OR lines( lt_dates ) < 2.
      RETURN.
    ENDIF.

    DATA(lv_second_latest) = lt_dates[ 2 ]-local_created_at.

    SELECT SINGLE forecast FROM /lht/a_placo_fc  "#EC CI_SEL_NESTED
      WHERE local_created_at = @lv_second_latest
        AND disposet         = @iv_disposet
      INTO @rv_forecast.
  ENDMETHOD.


  METHOD get_annual_consumption.
    DATA lv_annual_consumption TYPE gty_packed_number.

    " 1. Get the date of oldest year to be considered
    DATA(lv_oldest_year) =
      xco_cp=>sy->date( )->subtract( iv_month       = iv_months_in_past
                                     io_calculation = xco_cp_time=>date_calculation->ultimo )->as( xco_cp_time=>format->abap )->value.

    " 2. Get the current date
    DATA(lv_date) = xco_cp=>sy->date( ).

    " 3. Get the month of the oldest year to be considered
    DATA(lv_month) = CONV i( lv_oldest_year+4(2) ).

    TRY.
        " 4. Loop through the consumption data for the given material number
        LOOP AT it_consumption_data REFERENCE INTO DATA(ls_consumption)
          WHERE materialnumber  = iv_matnr AND
                businessyear   >= lv_oldest_year(4) AND
                businessyear   <= lv_date->year.

          " 5. Calculate the annual consumption based on the current year, oldest year, or other years
          CASE ls_consumption->businessyear.
            " 6. Current year
            WHEN lv_date->year.
              DO lv_date->month TIMES. " Number of Columns with totalconsumption
                DATA(lv_column_curr_year) = |totalconsumption_{ sy-index }|.
                lv_annual_consumption += ls_consumption->(lv_column_curr_year).
              ENDDO.
            " 7. Oldest year
            WHEN lv_oldest_year(4).
              DATA(lv_counter) = lv_month. " 20250805
              WHILE lv_counter < 14.
                DATA(lv_column_oldest_year) = |totalconsumption_{ lv_counter }|.
                lv_annual_consumption += ls_consumption->(lv_column_oldest_year).
                lv_counter += 1.
              ENDWHILE.
            " 8. Other years
            WHEN OTHERS.
              DO 13 TIMES. " Number of Columns with totalconsumption
                DATA(lv_column_other_year) = |totalconsumption_{ sy-index }|.
                lv_annual_consumption += ls_consumption->(lv_column_other_year).
              ENDDO.
          ENDCASE.
        ENDLOOP.

        " 9. Round the annual consumption value
        rv_annual_consumption = round( val  = lv_annual_consumption
                                       dec  = 0
                                       mode = cl_abap_math=>round_up ).
      CATCH cx_root.
        RAISE EXCEPTION NEW /lht/cx_placo_check(
            iv_error_message = /lht/cx_placo_check=>annual_consumption ).
    ENDTRY.
  ENDMETHOD.


  METHOD get_new_forecast.
    IF iv_disposet IS INITIAL.
      RETURN.
    ENDIF.

    SELECT SINGLE * FROM /lht/a_placo_fc  "#EC CI_SEL_NESTED
      WHERE local_created_at = ( SELECT MAX( local_created_at ) FROM /lht/a_placo_fc )
        AND disposet         = @iv_disposet
        INTO @DATA(lv_forecast_data).
    rv_forecast = lv_forecast_data-forecast.

    ev_qualityindicator = lv_forecast_data-quality_indicator.
  ENDMETHOD.


  METHOD append_worklist_entry.
    APPEND VALUE #( MaterialNumber = iv_materialnumber
                    Worklist       = iv_worklist_indicator
                    Criticality    = iv_criticality ) TO ct_mat_worklist_info.
  ENDMETHOD.


  METHOD checkForEmptyMaterialNumbers.
    LOOP AT it_matnr REFERENCE INTO DATA(lv_matnr).
      IF lv_matnr->* <> ''.
        INSERT lv_matnr->* INTO TABLE rt_materials.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD read_odata_services.
    TRY.
        " READ Materials OData: /LHT/LO_MM_MATERIALS -> Entity: MaterialData
        " -------------------------------------------------------------------
        /lht/cl_placo_odata_helper=>read_material_mat_data(
          EXPORTING
            it_materialnumber = it_matnr
          IMPORTING
            et_material_data  = et_material_data ).

        deleteMatWithDeletionInd(
          it_material_data = VALUE #(
            FOR material IN et_material_data WHERE ( deleted_flag = abap_true ) ( material ) ) ).

        IF lines( it_matnr ) <> lines( et_material_data ).
          et_material_data = compareMaterialDataToRelevant( it_material_data = et_material_data
                                                            it_relevant_data = it_matnr ).
        ENDIF.

        TEST-SEAM checkmatforplandepartment.
          et_material_data = checkMatForPlanDepartment( et_material_data ).
        END-TEST-SEAM.

        IF lines( et_material_data ) = 0.
          RETURN.
        ENDIF.

        " READ Materials OData: /LHT/LO_MM_MATERIALS -> Entity: MRPSet
        " ---------------------------------------------------------------------------
        /lht/cl_placo_odata_helper=>read_material_mrpset(
          EXPORTING
            it_materialnumber = VALUE #( FOR material IN et_material_data ( material-material_number ) )
          IMPORTING
            et_mrpset_data    = DATA(lt_mrpset_data) ).

        DELETE lt_mrpset_data WHERE plant <> '1000' AND plant <> '2000'.

        IF lt_mrpset_data IS INITIAL.
          RAISE EXCEPTION NEW /lht/cx_placo_check(
              iv_error_message = /lht/cx_placo_check=>no_relevant_materials_found ).
          RETURN.
        ENDIF.

        et_mrpset_data = lt_mrpset_data.

        et_relevant_materials = VALUE #(
          FOR ls_materialnumber IN lt_mrpset_data ( ls_materialnumber-material_number ) ).

        " READ Materials OData: /LHT/LO_MM_MATERIAL -> Entity: MaterialDescriptions
        " ---------------------------------------------------------------------------
        /lht/cl_placo_odata_helper=>read_material_mat_desc(
          EXPORTING
            it_materialnumber = et_relevant_materials
            iv_language_key   = 'DE'
          IMPORTING
            et_mat_desc_data  = et_mat_desc_data ).

        " READ Materials OData: /LHT/LO_MM_MATERIALS -> Entity: MaterialValuations
        " ---------------------------------------------------------------------------
        /lht/cl_placo_odata_helper=>read_material_valuations(
          EXPORTING
            it_materialnumber           = et_relevant_materials
          IMPORTING
            et_material_valuations_data = et_material_valuations_data ).

        " READ Materials OData: /LHT/LO_MB_CONSUMPTION -> Entity: ConsumptionData
        " ---------------------------------------------------------------------------
        /lht/cl_placo_odata_helper=>read_consumption_data(
          EXPORTING
            it_materialnumber   = et_relevant_materials
          IMPORTING
            et_consumption_data = et_consumption_data ).

        " READ Materials OData: /LHT/LO_MB_STOCK -> Entity: MaterialStock
        " ---------------------------------------------------------------------------
        /lht/cl_placo_odata_helper=>read_stock_mat_stock(
          EXPORTING
            it_materialnumber = et_relevant_materials
          IMPORTING
            et_mat_stock_data = et_mat_stock_data ).

        " READ PLACO OData: /LHT/LO_MD_PLACO -> Entity: DailyConsumption
        " ---------------------------------------------------------------------------
        /lht/cl_placo_odata_helper=>read_placo_dailyconsumption(
          EXPORTING
            it_materialnumber        = et_relevant_materials
            it_movement_type         = VALUE #( ( '261' )
                                                ( '945' )
                                                ( '983' )
                                                ( '984' )
                                                ( '946' )
                                                ( '262' ) )
          IMPORTING
            et_dailyconsumption_data = et_dailyconsumption_data ).

        " READ VK13: OData: /LHT/SD_VK13 -> Entity: MaterialPrice
        " ---------------------------------------------------------------------------

        /lht/cl_placo_odata_helper=>read_pr_item_data(
          EXPORTING
            it_materialnumber = et_relevant_materials
          IMPORTING
            et_pr_data        = et_purchase_requisition_data ).

        "Not needed yet, atm getting the Data out of the PO Item Entity
*        /lht/cl_placo_odata_helper=>read_open_po_data(
*          EXPORTING
*            it_materialnumber = lt_relevant_materials
*          IMPORTING
*            et_po_data = DATA(lt_po_data) ).

        " READ Materials OData: /LHT/LO_MM_MATERIALS -> Entity: Interchangeabilities  (02)
        " ----------------------------------------------------------------------------------
        /lht/cl_placo_odata_helper=>read_mat_Interchangeabilities(
          EXPORTING
            it_materialnumber = et_relevant_materials
          IMPORTING
            et_mat_inter_data = et_mat_inter_data  ).

        " READ Materials OData: /LHT/LO_MM_MATERIALS -> Entity: Restricted Interchangeabilities  (05/01)
        " -------------------------------------------------------------------------------------------------
        /lht/cl_placo_odata_helper=>read_mat_restricted_inter(
          EXPORTING
            it_materialnumber      = VALUE #( FOR interchangeability IN et_mat_inter_data
                                              ( interchangeability-parts_interchange_group_nu ) )
          IMPORTING
            et_mat_rest_inter_data = et_mat_rest_inter_data ).

        " READ Materials OData: /LHT/LO_MD_PLACO -> Entity: ZMMCLASS
        " ----------------------------------------------------------------------------------
        /lht/cl_placo_odata_helper=>read_placo_zmmclass(
          EXPORTING
            it_materialnumber = et_relevant_materials
          IMPORTING
            et_zmmclass_data  = et_zmmclass_data ).

        IF lt_mrpset_data IS NOT INITIAL.
          DATA lt_disposets TYPE /lht/cl_placo_odata_helper=>gty_t_disposets.

          LOOP AT lt_mrpset_data INTO DATA(ls_mrpset_data).
            IF ls_mrpset_data-mrpset IS NOT INITIAL.
              APPEND ls_mrpset_data-mrpset TO lt_disposets.
            ENDIF.
          ENDLOOP.

          DELETE ADJACENT DUPLICATES FROM lt_disposets.

          " READ Materials OData: /LHT/LO_MM_MATERIALS -> Entity: MRPSet with Disposet
          " ---------------------------------------------------------------------------
          /lht/cl_placo_odata_helper=>read_disposet_mrpset(
            EXPORTING
              it_disposets   = lt_disposets
            IMPORTING
              et_mrpset_data = et_mrpsets_to_mat_data ).
        ENDIF.

        " READ MAX Material Requests
        " ----------------------------------------------------------------------------------
        et_max_material_requests =
          /lht/cl_placo_max_mat_request=>get_max_material_requests( et_relevant_materials ).
      CATCH /lht/cx_placo_check INTO DATA(cx_placo).
        RAISE EXCEPTION NEW /lht/cx_placo_check( io_previous = cx_placo ).
    ENDTRY.
  ENDMETHOD.


  METHOD material_processing.

    "~ For saving the result of the Worklist Loop
    DATA lt_mat_worklist_info TYPE gty_t_r_placo_mast.

    "~ For saving information inside of the Loop
    DATA ls_material_data             TYPE /lht/r_placo_materials.
    DATA lt_material_data_cds         TYPE TABLE OF /lht/r_placo_materials.
    DATA lt_material                  TYPE gty_t_placo_mat_number.
    DATA lv_qualityIndicator_forecast TYPE int4.
    DATA lt_last_po_dates             TYPE /lht/lo_me_po_data_srv=>tyt_purchase_order_items.

    " Exception Class for Processing
    DATA cx_placo     TYPE REF TO /lht/cx_placo_check.
    DATA cl_error_log TYPE REF TO /lht/cl_placo_error_handling.

    lt_material = checkforemptymaterialnumbers( it_matnr ).

    IF lt_material IS INITIAL.
      RETURN.
    ENDIF.

    IF io_error_log IS NOT INITIAL.
      cl_error_log = io_error_log.
    ELSE.
      cl_error_log = NEW #( ).
    ENDIF.

    "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    " Get all Information from the OData-Services
    "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    TRY.
        TEST-SEAM read_odata_services.
          read_odata_services(
            EXPORTING
              it_matnr                     = lt_material
            IMPORTING
              et_material_data             = DATA(lt_material_data)
              et_mrpset_data               = DATA(lt_mrpset_data)
              et_mat_desc_data             = DATA(lt_mat_desc_data)
              et_material_valuations_data  = DATA(lt_material_valuations_data)
              et_consumption_data          = DATA(lt_consumption_data)
              et_mat_stock_data            = DATA(lt_mat_stock_data)
*              et_vk13_mat_mrpset_data      = DATA(lt_vk13_mat_mrpset_data)
              et_dailyconsumption_data     = DATA(lt_daily_consumption)
              et_mat_inter_data            = DATA(lt_material_interchange_data)
              et_mat_rest_inter_data       = DATA(lt_mat_rest_interchange_data)
              et_zmmclass_data             = DATA(lt_zmmclass_data)
              et_relevant_materials        = DATA(lt_relevant_materials)
              et_mrpsets_to_mat_data       = DATA(lt_mrpsets_to_mat_data)
              et_purchase_requisition_data = DATA(lt_purchase_requisition_data)
              et_max_material_requests     = DATA(lt_material_requests) ).
        END-TEST-SEAM.
      CATCH /lht/cx_placo_check INTO cx_placo.
        IF cx_placo->if_t100_message~t100key-msgno = CONV i( cx_placo->no_relevant_materials_found ).
          RETURN.
        ELSE.
          cl_error_log->logmaterial( it_material = it_matnr
                                     iv_message  = cx_placo->get_text( ) ).
          RETURN.
        ENDIF.
    ENDTRY.

    TRY.
        TEST-SEAM aggregate_stock_per_mat.
          DATA(lt_aggr_stock_data) = aggregate_stock_per_mat( it_stock_data = lt_mat_stock_data ).
        END-TEST-SEAM.
      CATCH /lht/cx_placo_check INTO cx_placo.
        cl_error_log->logmaterial( it_material = it_matnr
                                   iv_message  = cx_placo->get_text( ) ).
        RETURN.
    ENDTRY.

    TRY.
        TEST-SEAM process_interchangeabilities.
          process_interchangeabilities(
            EXPORTING
              it_mat_inter_data       = lt_material_interchange_data
              it_mat_rest_inter_data  = lt_mat_rest_interchange_data
            IMPORTING
              et_interchange_worklist = DATA(lt_interchange_worklist) ).
        END-TEST-SEAM.
      CATCH /lht/cx_placo_check INTO cx_placo.
        cl_error_log->logmaterial( it_material = it_matnr
                                   iv_message  = cx_placo->get_text( ) ).
        RETURN.
    ENDTRY.

    TRY.
        TEST-SEAM get_open_pos.
          DATA(lt_open_pos) =
            get_purchase_order_data(
              EXPORTING
                it_materialnumber       = lt_relevant_materials
              IMPORTING
                et_last_purchase_orders = lt_last_po_dates ).
        END-TEST-SEAM.
      CATCH /lht/cx_placo_check INTO cx_placo.
        cl_error_log->logmaterial( it_material = it_matnr
                                   iv_message  = cx_placo->get_text( ) ).
        RETURN.
    ENDTRY.

    DATA(lt_single_mat_disposets) = get_single_mat_disposet( lt_mrpsets_to_mat_data ).
*    lt_relevant_materials = compareMaterialDataToRelevant( it_material_data = lt_material_data
*                                                           it_relevant_data = lt_relevant_materials ).

    LOOP AT lt_relevant_materials REFERENCE INTO DATA(lv_relevant_material).
      " Check if there is a Azure forecast, if there is a forecast fill Daily consumption with forecast info
      " if not fill with historic info regarding the daily consumption of the last 365 days
      " As for now there is no daily forecast for Consumptiondata!

      CLEAR ls_material_data.
      CLEAR lv_qualityIndicator_forecast.

      "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      " Getter functions to get additional Informations
      "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      TRY.
          TEST-SEAM get_replenishment_time.
            DATA(lv_replenishment_time) =
              get_replenishment_time(
                iv_disposet = VALUE #( lt_mrpset_data[ material_number = lv_relevant_material->* ]-mrpset OPTIONAL ) ).
          END-TEST-SEAM.
        CATCH /lht/cx_placo_check INTO cx_placo.
          cl_error_log->logmaterial( it_material = VALUE #( ( lv_relevant_material->* ) )
                                     iv_message  = cx_placo->get_text( ) ).
          CONTINUE.
      ENDTRY.

      " PCS-243 | Consideration of days since oldest open PO
      DATA(lv_days_since_oldest_open_po) =
        VALUE #( lt_open_pos[ material = lv_relevant_material->* ]-days_since_oldest_open_po OPTIONAL ).
      " End of PCS-243

      DATA(lv_open_purchase_requisitions) =
        sumOpenPurchaseRequisitions( it_purchase_requisitions = lt_purchase_requisition_data
                                     iv_materialnumber        = lv_relevant_material->* ).

      DATA(lv_safety_stock) =
        CONV i( round( val  = lt_material_data[ material_number = lv_relevant_material->* ]-safety_stock
                       dec  = 0
                       mode = cl_abap_math=>round_up ) ).

*      get_safety_stock( it_material_data  = lt_material_data
*                        iv_materialnumber = lv_relevant_material->* ).

      TRY.
          DATA(lt_daily_consumption_for_mat) =
            get_daily_consumption(
              iv_materialnumber    = lv_relevant_material->*
              it_daily_consumption = lt_daily_consumption ).
        CATCH /lht/cx_placo_check INTO cx_placo.
          cl_error_log->logmaterial( it_material = VALUE #( ( lv_relevant_material->* ) )
                                     iv_message  = cx_placo->get_text( ) ).
          CONTINUE.
      ENDTRY.

      TRY.
          DATA(lv_annual_consumption) =
            get_annual_consumption(
              it_consumption_data = lt_consumption_data
              iv_months_in_past   = 12
              iv_matnr            = lv_relevant_material->* ).
        CATCH /lht/cx_placo_check INTO cx_placo.
          cl_error_log->logmaterial( it_material = VALUE #( ( lv_relevant_material->* ) )
                                     iv_message  = cx_placo->get_text( ) ).
          CONTINUE.
      ENDTRY.

      TRY.
          DATA(lv_consumption_last_two_years) =
            get_annual_consumption(
              it_consumption_data = lt_consumption_data
              iv_months_in_past   = 24
              iv_matnr            = lv_relevant_material->* ).
        CATCH /lht/cx_placo_check INTO cx_placo.
          cl_error_log->logmaterial( it_material = VALUE #( ( lv_relevant_material->* ) )
                                     iv_message  = cx_placo->get_text( ) ).
          CONTINUE.
      ENDTRY.

      TRY.
          DATA(lv_relevant_stock_lvl) =
            /lht/cl_placo_event_calc=>calculateRelevantStockLevel(
              get_relevant_stock( it_stock_data     = lt_mat_stock_data
                                  iv_materialnumber = lv_relevant_material->* ) ).
        CATCH /lht/cx_placo_check INTO cx_placo.
          cl_error_log->logmaterial( it_material = VALUE #( ( lv_relevant_material->* ) )
                                     iv_message  = cx_placo->get_text( ) ).
          CONTINUE.
      ENDTRY.

      DATA(lv_open_pos) = VALUE #( lt_open_pos[ material = lv_relevant_material->* ]-open_pos OPTIONAL ).

      DATA(lv_forecast_old) =
        get_old_forecast( iv_disposet = VALUE #( lt_mrpset_data[ material_number = lv_relevant_material->* ]-mrpset OPTIONAL ) ).

      DATA(lv_forecast_new) = get_new_forecast(
        EXPORTING
          iv_disposet         = VALUE #( lt_mrpset_data[ material_number = lv_relevant_material->* ]-mrpset OPTIONAL )
        IMPORTING
          ev_qualityindicator = lv_qualityIndicator_forecast ).

      DATA(lv_reorder_lvl) = VALUE i( lt_material_data[ material_number = lv_relevant_material->* ]-reorder_point ).

*      get_reorder_lvl( iv_materialnumber = lv_relevant_material->*
*                       it_material_data  = lt_material_data ).

*      DATA(ls_additional_material_data) = getAdditionalInformation( iv_relevant_material = lv_relevant_material->* )

      "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      " Calculate PPP Worklist
      "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

      " Determine Meldebestandsvorschlagswert (needed for Worklist determination)
      TRY.
          " PCS-206 | Splitting the calculation for forecasted reorder level and suggested reorder level
          " PCS-243 | Splitting the calculation for Replenishment Time and Day since oldest open PO
          DATA(lv_suggestedReorderLvl) =
            /lht/cl_placo_event_calc=>calculatesuggestionreorderlvl(
              iv_replenishment_time  = lv_replenishment_time
              iv_type_of_reorder_lvl = /lht/cl_placo_event_calc=>historic
              it_daily_consumption   = lt_daily_consumption_for_mat ).

          IF lv_forecast_new IS NOT INITIAL.
            DATA(lv_forecasted_reorder_lvl) =
              /lht/cl_placo_event_calc=>calculatesuggestionreorderlvl(
                iv_replenishment_time  = lv_replenishment_time
                iv_type_of_reorder_lvl = /lht/cl_placo_event_calc=>forecast
                it_daily_consumption   = getDailyConsumptionForForecast( lv_forecast_new ) ).

            lv_suggestedReorderLvl = compareSuggestions( iv_suggested_reorder_lvl  = lv_suggestedReorderLvl
                                                         iv_forecasted_reorder_lvl = lv_forecasted_reorder_lvl ).
          ENDIF.

          DATA(lv_reorder_level_old_open_po) =
            /lht/cl_placo_event_calc=>calculatesuggestionreorderlvl(
              iv_replenishment_time  = CONV #( lv_days_since_oldest_open_po )
              iv_type_of_reorder_lvl = /lht/cl_placo_event_calc=>historic
              it_daily_consumption   = lt_daily_consumption_for_mat ).

          IF lv_forecast_new IS NOT INITIAL.
            DATA(lv_forecast_level_old_open_po) =
              /lht/cl_placo_event_calc=>calculatesuggestionreorderlvl(
                iv_replenishment_time  = CONV #( lv_days_since_oldest_open_po )
                iv_type_of_reorder_lvl = /lht/cl_placo_event_calc=>forecast
                it_daily_consumption   = getDailyConsumptionForForecast( lv_forecast_new ) ).

            lv_reorder_level_old_open_po = compareSuggestions( iv_suggested_reorder_lvl  = lv_reorder_level_old_open_po
                                                               iv_forecasted_reorder_lvl = lv_forecast_level_old_open_po ).
          ENDIF.
          " End of PCS-243
          " End of PCS-206
        CATCH /lht/cx_placo_check INTO cx_placo.
          cl_error_log->logmaterial( it_material = VALUE #( ( lv_relevant_material->* ) )
                                     iv_message  = cx_placo->get_text( ) ).
          CONTINUE.
      ENDTRY.

      TRY.
          DATA(lv_stock_reach_open_po) =
            /lht/cl_placo_event_calc=>calculatestockreachopenpos(
              iv_relevant_stock_level    = lv_relevant_stock_lvl
              iv_forecasted_consumption  = lv_forecast_new
              iv_annual_consumption      = lv_annual_consumption
              iv_number_of_inflowing_mat = lv_open_pos ).
        CATCH /lht/cx_placo_check INTO cx_placo.
          cl_error_log->logmaterial( it_material = VALUE #( ( lv_relevant_material->* ) )
                                     iv_message  = cx_placo->get_text( ) ).
          CONTINUE.
      ENDTRY.

      TRY.
          DATA(lv_stock_reach) =
            /lht/cl_placo_event_calc=>calculatestockreachnoopenpos(
              iv_relevant_stock_level   = lv_relevant_stock_lvl
              iv_forecasted_consumption = lv_forecast_new
              iv_annual_consumption     = lv_annual_consumption ).
        CATCH /lht/cx_placo_check INTO cx_placo.
          cl_error_log->logmaterial( it_material = VALUE #( ( lv_relevant_material->* ) )
                                     iv_message  = cx_placo->get_text( ) ).
          CONTINUE.
      ENDTRY.

      "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      " Determine if its a single mat disposet
      "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

      DATA(lv_interchange_relevant) =
        checkInterchangeRelevancy(
          iv_single_disposet        = VALUE #( lt_single_mat_disposets[ material_number = lv_relevant_material->* ]-mrpset OPTIONAL )
          it_restricted_interchange = VALUE #( FOR restricted IN lt_mat_rest_interchange_data
                                               WHERE ( material_number = VALUE #( lt_material_interchange_data[
                                                                                    material_number = lv_relevant_material->* ]-parts_interchange_group_nu OPTIONAL ) )
                                               ( restricted ) ) ).

      "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      " Get last material request
      "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      DATA(lv_last_material_request) =
        getLastMaterialRequest( VALUE #( FOR material_request IN lt_material_requests
                                         WHERE ( MaterialNumber = lv_relevant_material->* )
                                         ( material_request ) ) ).

      DATA(lv_mat_req_in_last_4_weeks) =
        checkForMaterialRequest(
          it_material_requests = VALUE #( FOR material_request IN lt_material_requests
                                          WHERE ( MaterialNumber = lv_relevant_material->* )
                                          ( material_request ) )
          iv_weeks_in_past     = 4 ).

      "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      " Process Interchangeabilities
      "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

*      DATA(lt_relevant_interchange) =
*        getInterchangeWorklistItems(
*          VALUE #( FOR ls_interchangeability IN lt_interchangeabilities
*          ( material          = ls_interchangeability-material_number
*            verification_date = ls_interchangeability-last_interchange_verific_d ) ) ).
*      DATA(lt_relevant_restricted) =
*        getInterchangeWorklistItems(
*          VALUE #( FOR ls_restricted IN lt_restricted_interchanges
*          ( material          = ls_restricted-material_number
*            verification_date = ls_restricted-lastinterchangeverificdate ) ) ).
*      " //
*      " ____________________________________________________________________
*      " \\ Merge the relevant entries from restricted interchangeabilities
*      " \\ and normal interchangeabilitites
*      " ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
*      DATA(lt_interchange_worklist) = mergeRelevantEntries( it_restricted   = lt_relevant_restricted
*                                                            it_interchanges = lt_relevant_interchange ).
*
*      " //
*      DELETE lt_materials WHERE deleted_flag = abap_true.

      "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      " Determine if this entry is worklist relevant
      "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

      TRY.
          TEST-SEAM determine_worklist.
            determine_worklist(
              EXPORTING
                iv_relevant_stock             = lv_relevant_stock_lvl
                iv_open_pos                   = lv_open_pos
                iv_forecast_old               = lv_forecast_old
                iv_forecast_new               = lv_forecast_new
                iv_sugstn_for_reorder_lvl     = lv_suggestedReorderLvl
                iv_reorder_lvl                = lv_reorder_lvl
                iv_materialnumber             = lv_relevant_material->*
                iv_annual_consumption         = lv_annual_consumption
                it_zmmclass_data              = lt_zmmclass_data
                is_interchange_worklist       = VALUE #( lt_interchange_worklist[
                                                           material = lv_relevant_material->* ] OPTIONAL )
                is_interchange_relevant       = lv_interchange_relevant
                iv_leading_partnumber         = VALUE #( lt_mrpset_data[
                                                           material_number = lv_relevant_material->* ]-leading_part OPTIONAL )
                iv_stock_reach                = lv_stock_reach_open_po
                iv_created_on                 = VALUE #( lt_material_data[
                                                           material_number = lv_relevant_material->* ]-created_on OPTIONAL )
                iv_consumption_last_two_years = lv_consumption_last_two_years
                iv_hold_on_stock_flag         = VALUE #( lt_material_data[
                                                           material_number = lv_relevant_material->* ]-hold_on_stock_flag OPTIONAL )
                iv_disposet                   = VALUE #( lt_mrpset_data[
                                                           material_number = lv_relevant_material->* ]-mrpset OPTIONAL )
                iv_open_purchase_requisitions = lv_open_purchase_requisitions
                iv_mat_req_in_last_4_weeks    = lv_mat_req_in_last_4_weeks
              IMPORTING
                ev_add_to_worklist_cc         = DATA(lv_add_to_worklist_cc)
                ev_add_to_worklist_rp         = DATA(lv_add_to_worklist_rp)
                ev_add_to_worklist_zmm        = DATA(lv_add_to_worklist_zmm)
                ev_add_to_worklist_int        = DATA(lv_add_to_worklist_int)
                ev_add_to_worklist_os         = DATA(lv_add_to_worklist_os)
              CHANGING
                ct_mat_worklist_info          = lt_mat_worklist_info  ).
          END-TEST-SEAM.
        CATCH /lht/cx_placo_check INTO cx_placo.
          cl_error_log->logmaterial( it_material = VALUE #( ( lv_relevant_material->* ) )
                                     iv_message  = cx_placo->get_text( ) ).
          CONTINUE.
      ENDTRY.

      "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

      "~ If there is no new worklist entry, we can skip the following processing
      IF lv_add_to_worklist_cc  = abap_false OR
         lv_add_to_worklist_rp  = abap_false OR
         lv_add_to_worklist_zmm = abap_false OR
         lv_add_to_worklist_int = abap_false OR
         lv_add_to_worklist_os  = abap_false.

        TEST-SEAM checkforexistingworklist.
          DATA(lt_worklist_exists) = checkforexistingworklist( iv_relevant_material = lv_relevant_material->* ).
        END-TEST-SEAM.

        IF lt_worklist_exists IS NOT INITIAL.
          TEST-SEAM deleteworklistentry.
            deleteworklistentry( it_worklists            = lt_worklist_exists
                                 iv_consumption_change   = lv_add_to_worklist_cc
                                 iv_reorder_point_breach = lv_add_to_worklist_rp
                                 iv_interchangeabilities = lv_add_to_worklist_int
                                 iv_zmm                  = lv_add_to_worklist_zmm
                                 iv_overstock            = lv_add_to_worklist_os ).
          END-TEST-SEAM.
          DATA(lv_entries_were_deleted) = abap_true.
        ENDIF.
      ENDIF.

      "~ If its a new PPP-Worklist entry we need to calculate some more fields
      IF lv_add_to_worklist_cc = abap_true OR lv_add_to_worklist_rp = abap_true.
        TRY.
            DATA(lv_suggestion_opt_order_qty) =
              /lht/cl_placo_event_calc=>calculatesuggestionoptordqty(
                iv_annual_consumption   = lv_annual_consumption
                iv_forecast_consumption = CONV #( lv_forecast_new )
                iv_moving_average_price = VALUE #( lt_material_valuations_data[
                                                     material_number = lv_relevant_material->* ]-moving_average_price )
                iv_order_costs          = 200
                iv_stock_cost_rate      = '0.0715' ).
          CATCH /lht/cx_placo_check INTO cx_placo.
            cl_error_log->logmaterial( it_material = VALUE #( ( lv_relevant_material->* ) )
                                       iv_message  = cx_placo->get_text( ) ).
            CONTINUE.
        ENDTRY.
      ENDIF.

      " If a new Overstock Worlist entry is created, we need to calculate additional fields
      " START | Removal of overstock functionality.
*      IF lv_add_to_worklist_os = abap_true.
*        DATA(lv_overstock_criticality) = lt_mat_worklist_info[
*          MaterialNumber = lv_relevant_material->*
*          Worklist       = /lht/if_placo_constants=>gc_worklists-overstock ]-Criticality.
*
*        DATA(lv_rec_release_qty) = VALUE int4( ).
*
*        CASE lv_overstock_criticality.
*          WHEN 1.
*            lv_rec_release_qty = lv_relevant_stock_lvl.
*          WHEN 2.
*            TRY.
*                lv_rec_release_qty =
*                  /lht/cl_placo_event_calc=>calculaterecreleasequantity(
*                    iv_relevant_stock            = lv_relevant_stock_lvl
*                    iv_forecast                  = lv_forecast_new
*                    iv_consumption_last_two_year = lv_consumption_last_two_years ).
*              CATCH /lht/cx_placo_check INTO cx_placo.
*                cl_error_log->logmaterial( it_material = VALUE #( ( lv_relevant_material->* ) )
*                                           iv_message  = cx_placo->get_text( ) ).
*                CONTINUE.
*            ENDTRY.
*        ENDCASE.
*      ENDIF.
      " END | Removal of overstock functionality.

      "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      " Field mapping for the Material Entity
      "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      IF lv_add_to_worklist_cc  = abap_true OR
         lv_add_to_worklist_rp  = abap_true OR
         lv_add_to_worklist_zmm = abap_true OR
         lv_add_to_worklist_int = abap_true OR
         lv_add_to_worklist_os  = abap_true.

        ls_material_data-Material      = lv_relevant_material->*.
        ls_material_data-Plant         = VALUE #( lt_material_data[ material_number = lv_relevant_material->* ]-inventory_management_plant OPTIONAL ).
        ls_material_data-MRPController = VALUE #( lt_material_data[ material_number = lv_relevant_material->* ]-mrpcontroller OPTIONAL ).
        ls_material_data-MPG           = VALUE #( lt_material_data[ material_number = lv_relevant_material->* ]-material_planning_departme OPTIONAL ).
        ls_material_data-MRPProfile    = VALUE #( lt_material_data[ material_number = lv_relevant_material->* ]-mrpprofile OPTIONAL ).
        ls_material_data-Manufacturer  = VALUE #( lt_material_data[ material_number = lv_relevant_material->* ]-manufacturer OPTIONAL ).
        ls_material_data-MRPArea       = VALUE #( lt_mrpset_data[ material_number = lv_relevant_material->* ]-mrparea OPTIONAL ).
        ls_material_data-MRPSet        = VALUE #( lt_mrpset_data[ material_number = lv_relevant_material->* ]-mrpset OPTIONAL ).
        ls_material_data-LeadingPart   = VALUE #( lt_mrpset_data[ material_number = lv_relevant_material->* ]-leading_part OPTIONAL ).

        " START | CR: PCS-198 Swapping mapping for MaterialStock and StockLevel_______________________
        ls_material_data-MaterialStock = lv_relevant_stock_lvl.
        " END   | CR: PCS-198 Swapping mapping for MaterialStock and StockLevel_______________________

*        ls_material_data-VK13Amount = VALUE #( lt_material_mrpset[ material_number = lv_relevant_material->* ]-amount OPTIONAL ).
*        ls_material_data-VK13Curr   = VALUE #( lt_material_mrpset[ material_number = lv_relevant_material->* ]-condition_currency OPTIONAL ).

        ls_material_data-ReorderPoint               = VALUE #( lt_material_data[ material_number = lv_relevant_material->* ]-reorder_point OPTIONAL ).
        ls_material_data-AnnualConsumption          = lv_annual_consumption.
        ls_material_data-TwoYearConsumption         = lv_consumption_last_two_years.
        ls_material_data-ForecastConsumption        = lv_forecast_new.
        ls_material_data-ForecastVariance           = lv_qualityIndicator_forecast.
        ls_material_data-PlanningDepartment         = VALUE #( lt_material_data[ material_number = lv_relevant_material->* ]-material_planning_departme OPTIONAL ).
        ls_material_data-MatClass                   = VALUE #( lt_material_data[ material_number = lv_relevant_material->* ]-material_class OPTIONAL ).
        ls_material_data-MatDescription             = VALUE #( lt_mat_desc_data[ material_number = lv_relevant_material->* ]-material_description OPTIONAL ).
        ls_material_data-MatType                    = VALUE #( lt_material_data[ material_number = lv_relevant_material->* ]-material_type OPTIONAL ).
        ls_material_data-MovingAveragePrice         = VALUE #( lt_material_valuations_data[ material_number = lv_relevant_material->* ]-moving_average_price OPTIONAL ).
        ls_material_data-MovingAveragePriceCurrency = 'EUR'.
        ls_material_data-ExtManufacturer            = VALUE #( lt_material_data[ material_number = lv_relevant_material->* ]-external_manufacturer OPTIONAL ).
        ls_material_data-PlannedDeliveryTime        = VALUE #( lt_material_data[ material_number = lv_relevant_material->* ]-planned_delivery_time OPTIONAL ).
        ls_material_data-DescrExtManufacturer       = VALUE #( lt_material_data[ material_number = lv_relevant_material->* ]-descr_external_manufacture OPTIONAL ).

*        ls_material_data-priority = ls_material_data-extmanufacturer.

        ls_material_data-FFFClass = VALUE #( lt_material_data[ material_number = lv_relevant_material->* ]-fffclass OPTIONAL ).
        ls_material_data-Unit     = VALUE #( lt_material_data[ material_number = lv_relevant_material->* ]-base_unit_of_measure OPTIONAL ).

        " START | CR: PCS-198 Swapping mapping for materialstock and stocklevel_______________________
        ls_material_data-StockLevel = VALUE #( lt_aggr_stock_data[ MaterialNumber = lv_relevant_material->* ]-stock OPTIONAL ).
        " END   | CR: PCS-198 Swapping mapping for materialstock and stocklevel_______________________

        ls_material_data-ReorderLevel             = lv_suggestedReorderLvl.
        ls_material_data-OrderQuantity            = lv_suggestion_opt_order_qty.
        ls_material_data-SuggOptOrderQty          = lv_suggestion_opt_order_qty.
        ls_material_data-StockReach               = lv_stock_reach_open_po.
        ls_material_data-StockReachNoP            = lv_stock_reach.
        ls_material_data-ReplenishmentTime        = lv_replenishment_time.
        ls_material_data-SafetyStock              = VALUE #( lt_material_data[ material_number = lv_relevant_material->* ]-safety_stock OPTIONAL ).
        ls_material_data-CustomsTariffCode        = VALUE #( lt_material_data[ material_number = lv_relevant_material->* ]-commodity_code OPTIONAL ).
        ls_material_data-SourceCustomsTariff      = VALUE #( lt_material_data[ material_number = lv_relevant_material->* ]-source_of_customs_tariff_n OPTIONAL ).
        ls_material_data-CheckCustomsTariff       = VALUE #( lt_material_data[ material_number = lv_relevant_material->* ]-insp_code_for_customs_tari OPTIONAL ).
        ls_material_data-WorkCenter               = VALUE #( lt_material_data[ material_number = lv_relevant_material->* ]-object_idwork_place OPTIONAL ).
        ls_material_data-ArticleVariance          = VALUE #( lt_material_data[ material_number = lv_relevant_material->* ]-article_variance OPTIONAL ).
        ls_material_data-SingleMaterialMrpSetFlag = checkSingleMrpSet( iv_mrpset  = ls_material_data-mrpset
                                                                       it_mrpsets = lt_single_mat_disposets ).

        " PCS-243 | Consideration of Delivery Time Open POs
        ls_material_data-MaxDeliveryTimeOpenPo          = lv_days_since_oldest_open_po.
        ls_material_data-MaxDelivTimeOpenPoReorderPoint = lv_reorder_level_old_open_po.
        " End of PCS-243

        " Overstock Module extra data
*        ls_material_data-ConditionType = VALUE #( lt_vk13_mat_mrpset_data[ material_number = lv_relevant_material->* ]-condition_type OPTIONAL ).

        ls_material_data-HoldOnStockFlag = VALUE #( lt_material_data[ material_number = lv_relevant_material->* ]-hold_on_stock_flag OPTIONAL ).
        ls_material_data-MatCreatedOn    = VALUE #( lt_material_data[ material_number = lv_relevant_material->* ]-created_on OPTIONAL ).

*        ls_material_data-RecommendedReleasedQuantity = lv_rec_release_qty.

        ls_material_data-LastAnfoOn          = lv_last_material_request.
        ls_material_data-LastPurchaseOrderOn = VALUE #( lt_last_po_dates[ material = lv_relevant_material->* ]-last_changed_on OPTIONAL ).
        " End Overstock

        APPEND ls_material_data TO lt_material_data_cds.
        "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      ENDIF.
    ENDLOOP.

    IF lines( lt_material_data_cds ) < 1.
      IF lv_entries_were_deleted = abap_true.
      ENDIF.
      RETURN.
    ENDIF.

    TRY.
        TEST-SEAM persist_entities.
          persist_entities( it_material_data = lt_material_data_cds
                            it_worklist_data = lt_mat_worklist_info ).
        END-TEST-SEAM.
      CATCH /lht/cx_placo_check INTO cx_placo.
        IF cx_placo->gt_materials IS INITIAL.
          cl_error_log->logmaterial(
              it_material = VALUE #( FOR material IN lt_material_data_cds
                                     ( material-Material ) )
              iv_message  = cx_placo->get_text( ) ).
        ELSE.
          cl_error_log->logmaterial( it_material = cx_placo->gt_materials
                                     iv_message  = cx_placo->get_text( ) ).
        ENDIF.
    ENDTRY.

    deleteMaterialFromErrorLog( VALUE #( FOR material IN lt_material_data_cds
                                         ( material-material ) ) ).
  ENDMETHOD.


  METHOD process_interchangeabilities.
    " Exception Class for Processing
    DATA cx_placo TYPE REF TO /lht/cx_placo_check.

    GET TIME STAMP FIELD DATA(lv_today).

    TRY.
        DATA(lt_relevant_interchange) =
          getInterchangeWorklistItems(
            VALUE #( FOR ls_interchangeability IN it_mat_inter_data
                     WHERE ( interchangeabilities_check = abap_true AND
                           ( interchange_check_not_need  > lv_today OR interchange_check_not_need IS INITIAL ) )
                     ( material          = ls_interchangeability-material_number
                       verification_date = ls_interchangeability-last_interchange_verific_d ) ) ).
      CATCH /lht/cx_placo_check INTO cx_placo.
        RAISE EXCEPTION NEW /lht/cx_placo_check( io_previous = cx_placo ).
        " handle exception
    ENDTRY.

    TRY.
        DATA(lt_relevant_restricted) = getInterchangeWorklistItems(
            VALUE #( FOR ls_restricted IN it_mat_rest_inter_data
                     WHERE ( interchangeabilitieschecke = abap_true AND
                           ( interchangechecknotneeded  > lv_today OR interchangechecknotneeded IS INITIAL ) )
                     ( material          = ls_restricted-material_number
                       verification_date = ls_restricted-lastinterchangeverificdate ) ) ).
      CATCH /lht/cx_placo_check INTO cx_placo.
        RAISE EXCEPTION NEW /lht/cx_placo_check( io_previous = cx_placo ).
    ENDTRY.

    " \\ Merge the relevant entries from restricted interchangeabilities
    " \\ and normal interchangeabilitites
    et_interchange_worklist =
      mergeRelevantEntries( it_restricted   = lt_relevant_restricted
                            it_interchanges = lt_relevant_interchange ).
  ENDMETHOD.


  METHOD determine_worklist.
    "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    " Determine if this entry is worklist relevant
    "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    DATA lv_criticality_cc  TYPE int4.
    DATA lv_criticality_int TYPE int4.
    DATA lv_criticality_rp  TYPE int4.
    DATA lv_criticality_zmm TYPE int4.
    DATA lv_criticality_os  TYPE int4.

    TRY.
        TEST-SEAM add_to_worklist.
          " START | CR: PCS-213 Changed critiera for worklist entries _______________________
          /lht/cl_placo_event_worklist=>check_piece_part_planning(
            EXPORTING
              iv_relevant_stock         = iv_relevant_stock
              iv_open_pos               = iv_open_pos
              iv_forecast_new           = iv_forecast_new
              iv_sugstn_for_reorder_lvl = iv_sugstn_for_reorder_lvl
              iv_reorder_lvl            = iv_reorder_lvl
              iv_annual_consumption     = iv_annual_consumption
              iv_open_purchase_requisitions = iv_open_purchase_requisitions
            IMPORTING
              ev_criticality_cc         = lv_criticality_cc
              ev_criticality_rp         = lv_criticality_rp
              ev_add_to_worklist_cc     = ev_add_to_worklist_cc
              ev_add_to_worklist_rp     = ev_add_to_worklist_rp ).

*            ev_add_to_worklist_cc = /lht/cl_placo_event_worklist=>check_consumption_change(
*              EXPORTING
*                iv_relevant_stock         = iv_relevant_stock
*                iv_open_pos               = iv_open_pos
*                iv_forecast_old           = iv_forecast_old
*                iv_forecast_new           = iv_forecast_new
*                iv_sugstn_for_reorder_lvl = iv_sugstn_for_reorder_lvl
*                iv_reorder_lvl            = iv_reorder_lvl
*              IMPORTING
*                ev_criticality            = lv_criticality_cc ).

*             ev_add_to_worklist_rp = /lht/cl_placo_event_worklist=>check_reorder_point_breach(
*               EXPORTING
*                 iv_relevant_stock             = iv_relevant_stock
*                 iv_open_pos                   = iv_open_pos
*                 iv_suggestion_for_reorder_lvl = iv_sugstn_for_reorder_lvl
*                 iv_reorder_lvl                = iv_reorder_lvl
*                 iv_forecast_old               = iv_forecast_old
*                 iv_forecast_new               = iv_forecast_new
*               IMPORTING
*                 ev_criticality                = lv_criticality_rp ).
          " END | CR: PCS-213 Changed critiera for worklist entries _________________________

          " START | CR: PCS-189 Additional critiera for worklist entries _______________________
          IF ev_add_to_worklist_cc = abap_true.
            ev_add_to_worklist_cc =
              /lht/cl_placo_event_worklist=>checkForLeadingPartnumber(
                iv_criticality        = lv_criticality_cc
                iv_worklist_indicator = /lht/if_placo_constants=>gc_worklists-consumption_change
                iv_materialnumber     = iv_materialnumber
                iv_leading_partnumber = iv_leading_partnumber ).
          ENDIF.
          " END | CR: PCS-189 Additional critiera for worklist entries _________________________

          " START | CR: PCS-189 Additional critiera for worklist entries _______________________
          IF ev_add_to_worklist_rp = abap_true.
            ev_add_to_worklist_rp =
              /lht/cl_placo_event_worklist=>checkForLeadingPartnumber(
                iv_criticality        = lv_criticality_rp
                iv_worklist_indicator = /lht/if_placo_constants=>gc_worklists-reorder_point_breach
                iv_materialnumber     = iv_materialnumber
                iv_leading_partnumber = iv_leading_partnumber ).
          ENDIF.
          " END | CR: PCS-189 Additional critiera for worklist entries _________________________

          ev_add_to_worklist_zmm =
            /lht/cl_placo_event_worklist=>check_zmmclass_entrys(
              EXPORTING
                iv_materialnumber = iv_materialnumber
                it_zmmclass_data  = it_zmmclass_data
              IMPORTING
                ev_criticality    = lv_criticality_zmm ).

          " START | Removed implementation of overstock module
*          /lht/cl_placo_event_worklist=>check_overstock(
*            EXPORTING
*              iv_relevant_stock             = iv_relevant_stock
*              iv_stock_reach                = iv_stock_reach
*              iv_created_on                 = iv_created_on
*              iv_forecast_new               = iv_forecast_new
*              iv_annual_consumption         = iv_annual_consumption
*              iv_consumption_last_two_years = iv_consumption_last_two_years
*              iv_hold_on_stock_flag         = iv_hold_on_stock_flag
*              iv_disposet                   = iv_disposet
*              iv_mat_req_in_last_4_weeks = iv_mat_req_in_last_4_weeks
*            IMPORTING
*               ev_add_to_worklist_os         = ev_add_to_worklist_os
*               ev_criticality_os             = lv_criticality_os ).
            " END | Removed implementation of overstock module
        END-TEST-SEAM.

        IF is_interchange_worklist IS NOT INITIAL AND is_interchange_relevant = abap_true.
          ev_add_to_worklist_int = abap_true.
          lv_criticality_int = is_interchange_worklist-criticality.
        ELSE.
          ev_add_to_worklist_int = abap_false.
        ENDIF.
        "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        IF ev_add_to_worklist_cc  = abap_false AND
           ev_add_to_worklist_rp  = abap_false AND
           ev_add_to_worklist_int = abap_false AND
           ev_add_to_worklist_zmm = abap_false AND
           ev_add_to_worklist_os  = abap_false.
          RETURN.
        ENDIF.

        TEST-SEAM handle_worklist_info.
          handle_worklist_info(
            EXPORTING
              iv_add_to_worklist_cc  = ev_add_to_worklist_cc
              iv_add_to_worklist_rp  = ev_add_to_worklist_rp
              iv_add_to_worklist_int = ev_add_to_worklist_int
              iv_add_to_worklist_zmm = ev_add_to_worklist_zmm
              iv_add_to_worklist_os  = ev_add_to_worklist_os
              iv_materialnumber      = iv_materialnumber
              iv_criticality_cc      = lv_criticality_cc
              iv_criticality_rp      = lv_criticality_rp
              iv_criticality_int     = lv_criticality_int
              iv_criticality_zmm     = lv_criticality_zmm
              iv_criticality_os      = lv_criticality_os
            CHANGING
              ct_mat_worklist_info   = ct_mat_worklist_info ).
        END-TEST-SEAM.
      CATCH /lht/cx_placo_check INTO DATA(cx_check).
        RAISE EXCEPTION NEW /lht/cx_placo_check( io_previous = cx_check ).
    ENDTRY.
  ENDMETHOD.


  METHOD persist_worklist.
    TYPES lty_s_r_placo_workl_upd TYPE STRUCTURE FOR UPDATE /lht/r_placo_worklist.
    TYPES lty_s_r_placo_workl_cre TYPE STRUCTURE FOR CREATE /lht/r_placo_worklist.

    DATA ls_r_placo_workl_upd TYPE lty_s_r_placo_workl_upd.
    DATA ls_r_placo_workl_cre TYPE lty_s_r_placo_workl_cre.
    DATA lo_failed TYPE RESPONSE FOR FAILED EARLY /lht/r_placo_worklist.

    DATA lr_material TYPE RANGE OF /lht/placo_mat_number.
    DATA lt_failed_materials  TYPE gty_t_placo_mat_number.

    lr_material = VALUE #(
      FOR lv_material IN it_materials
      ( sign = 'I' option = 'EQ' low = lv_material-Material high = '' ) ).

    SELECT * FROM /lht/a_placo_wrk "#EC CI_SEL_NESTED
      WHERE MaterialNumber IN @lr_material
      INTO TABLE @DATA(lt_placo_wrk).

    TRY.
        LOOP AT it_worklists REFERENCE INTO DATA(ls_worklist).
          CLEAR lo_failed.
          IF VALUE #( lt_placo_wrk[ MaterialNumber = ls_worklist->Materialnumber
                                    Worklist       = ls_worklist->Worklist ] OPTIONAL ) IS NOT INITIAL.

            MOVE-CORRESPONDING ls_worklist->* TO ls_r_placo_workl_upd.

            ls_r_placo_workl_upd-UUID = lt_placo_wrk[
              MaterialNumber = ls_worklist->Materialnumber
              Worklist       = ls_worklist->Worklist ]-UUID.

            MODIFY ENTITIES OF /lht/r_placo_worklist
                   ENTITY Worklist
                   UPDATE
                   SET FIELDS WITH VALUE #( ( ls_r_placo_workl_upd ) )
                   " TODO: variable is assigned but never used (ABAP cleaner)
                   MAPPED DATA(lo_mapped)
                   " TODO: variable is assigned but never used (ABAP cleaner)
                   REPORTED DATA(lo_reported)
                   FAILED lo_failed.

            CLEAR ls_r_placo_workl_upd.

          ELSE.

            MOVE-CORRESPONDING ls_worklist->* TO ls_r_placo_workl_cre.

            MODIFY ENTITIES OF /lht/r_placo_worklist
                   ENTITY Worklist
                   CREATE AUTO FILL CID
                   SET FIELDS WITH VALUE #( ( ls_r_placo_workl_cre ) )
                   FAILED lo_failed.

            CLEAR ls_r_placo_workl_cre.

          ENDIF.

          IF lo_failed IS NOT INITIAL.
            INSERT ls_worklist->Materialnumber INTO TABLE lt_failed_materials.
          ENDIF.
        ENDLOOP.
      CATCH cx_root.
        RAISE EXCEPTION NEW /lht/cx_placo_check(
            iv_error_message = /lht/cx_placo_check=>persist_worklist ).
    ENDTRY.

    IF lt_failed_materials IS NOT INITIAL.
      RAISE EXCEPTION NEW /lht/cx_placo_check( iv_error_message = /lht/cx_placo_check=>persist_worklist
                                               it_materials     = lt_failed_materials ).
    ENDIF.
  ENDMETHOD.


  METHOD checkMatForPlanDepartment.
    DATA(lr_planning_departments) = getPlanningDepartmentRange( ).
    DATA(lr_existing_materials) = getMaterialsRange( it_materials ).

    IF lr_existing_materials IS NOT INITIAL.
      rt_materials = VALUE #( FOR ls_material IN it_materials
                              WHERE ( material_planning_departme IN lr_planning_departments OR
                                      material_number            IN lr_existing_materials ) ( ls_material ) ).
    ELSE.
      rt_materials = VALUE #( FOR ls_material IN it_materials
                              WHERE ( material_planning_departme IN lr_planning_departments ) ( ls_material ) ).
    ENDIF.
  ENDMETHOD.


  METHOD checkForExistingWorklist.
    SELECT * FROM /lht/a_placo_wrk  "#EC CI_SEL_NESTED
      WHERE MaterialNumber = @iv_relevant_material
      INTO TABLE @DATA(lt_worklist_entries).

    IF lt_worklist_entries IS NOT INITIAL.
      rt_existing_worklists = lt_worklist_entries.
    ENDIF.
  ENDMETHOD.


  METHOD purch_ord_processing.
    DATA lt_materials TYPE gty_t_placo_mat_number.
    DATA lt_ebeln     TYPE TABLE OF ebeln.

    " READ PURCHASE ORDER ITEMS : OData: /lht/lo_me_po_data_srv
    " ---------------------------------------------------------------------------
    APPEND iv_ebeln TO lt_ebeln.

    TEST-SEAM read_po_item_data.
      /lht/cl_placo_odata_helper=>read_po_item_data(
        EXPORTING
          it_purch_order = lt_ebeln
        IMPORTING
          et_po_data     = DATA(lt_order_items) ).
    END-TEST-SEAM.

    SORT lt_order_items ASCENDING BY material.
    DELETE ADJACENT DUPLICATES FROM lt_order_items COMPARING material.

    LOOP AT lt_order_items ASSIGNING FIELD-SYMBOL(<ls_order_item>).
      APPEND <ls_order_item>-material TO lt_materials.
    ENDLOOP.

    TEST-SEAM material_processing.
      material_processing( it_matnr = lt_materials ).
    END-TEST-SEAM.
  ENDMETHOD.


  METHOD get_single_mat_disposet.
    DATA lt_sorted_diposet TYPE SORTED TABLE OF /lht/cm_lo_mm_materials_srv=>tys_material_mrpsets WITH NON-UNIQUE KEY mrpset.

    LOOP AT it_mrpsets INTO DATA(ls_mrpset).
      IF ls_mrpset-mrpset IS NOT INITIAL.
        INSERT ls_mrpset INTO table lt_sorted_diposet.
      ENDIF.
    ENDLOOP.

    LOOP AT lt_sorted_diposet INTO DATA(lv_dp).
      DATA(lt_filtered_disposet) = FILTER #( lt_sorted_diposet WHERE mrpset = lv_dp-mrpset  ).

      IF lines( lt_filtered_disposet ) < 2.
        INSERT lv_dp INTO table rt_singel_mat_disposets.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD persist_entities.
    DATA lr_material TYPE RANGE OF /lht/placo_mat_number.

    " Exception Class for Processing
    DATA cx_placo            TYPE REF TO /lht/cx_placo_check.
    DATA lt_failed_materials TYPE gty_t_placo_matnr.

    TEST-SEAM wrk_and_mat_db_select.
    END-TEST-SEAM.

    DATA(lt_materials) = it_material_data.
    DATA(lt_worklists) = it_worklist_data.

    GET TIME STAMP FIELD DATA(lv_timestamp).

    LOOP AT lt_materials ASSIGNING FIELD-SYMBOL(<ls_material>).
      <ls_material>-LastChangedAt = lv_timestamp.
    ENDLOOP.

    TRY.
        persist_materials( it_materials = lt_materials ).
      CATCH /lht/cx_placo_check INTO cx_placo.
        IF cx_placo->gt_materials IS INITIAL.
          RAISE EXCEPTION NEW /lht/cx_placo_check( io_previous = cx_placo ).
        ENDIF.

        LOOP AT cx_placo->gt_materials REFERENCE INTO DATA(lv_failed_material).
          INSERT lv_failed_material->* INTO TABLE lt_failed_materials.
        ENDLOOP.

        IF lt_failed_materials IS NOT INITIAL.
          lr_material = VALUE #( FOR material IN lt_failed_materials
                                 ( sign = 'I' option = 'EQ' low = material high = '' ) ).
          DELETE lt_worklists WHERE Materialnumber IN lr_material.
          DELETE lt_materials WHERE Material IN lr_material.
        ENDIF.
    ENDTRY.

    TRY.
        persist_worklist( it_worklists = lt_worklists
                          it_materials = lt_materials ).
      CATCH /lht/cx_placo_check INTO cx_placo.
        IF cx_placo->gt_materials IS INITIAL.
          RAISE EXCEPTION NEW /lht/cx_placo_check( io_previous = cx_placo ).
        ENDIF.

        LOOP AT cx_placo->gt_materials REFERENCE INTO DATA(lv_failed_material_from_wrk).
          INSERT lv_failed_material_from_wrk->* INTO TABLE lt_failed_materials.
        ENDLOOP.
    ENDTRY.

    IF lt_failed_materials IS NOT INITIAL.
      RAISE EXCEPTION NEW /lht/cx_placo_check( io_previous  = cx_placo
                                               it_materials = lt_failed_materials ).
    ENDIF.
  ENDMETHOD.


  METHOD sumOpenPurchaseRequisitions.
    rv_sum_of_open_prs = REDUCE i( INIT sum = 0
                                   FOR purchase_requisition IN it_purchase_requisitions
                                   WHERE ( material = iv_materialnumber AND processing_status <> 'B' )
                                   NEXT sum += purchase_requisition-quantity ).
  ENDMETHOD.


  METHOD get_purchase_order_data.
    TEST-SEAM read_po_item_data_open_pos.
      /lht/cl_placo_odata_helper=>read_po_item_data(
        EXPORTING
          it_materialnumber = it_materialnumber
        IMPORTING
          et_po_data        = DATA(lt_po_data)  ).
    END-TEST-SEAM.

    et_last_purchase_orders = getLastPurchaseOrders( it_materialnumber = it_materialnumber
                                                     it_po_data        = lt_po_data ).

    DELETE lt_po_data WHERE deletion_indicator = |X|.
    DELETE lt_po_data WHERE delivery_completed_indicat = |X|.

    " PCS-205 | Additional criteria for open purchase orders
    DELETE lt_po_data WHERE deletion_indicator = |L|.
    DELETE lt_po_data WHERE delivery_completed_indicat = |L|.
    DELETE lt_po_data WHERE item_is_statistical = |X|.
    DELETE lt_po_data WHERE last_changed_on < getyearsago( 4 ).
    " End of PCS-205

    DELETE ADJACENT DUPLICATES FROM lt_po_data COMPARING purchase_order purchase_order_item.

    LOOP AT it_materialnumber INTO DATA(lv_material).
      DATA(lv_po_data_to_mat) = REDUCE i( INIT sum = 0
                                          FOR ls_po_data IN Lt_po_data
                                          WHERE ( material = lv_material )
                                          NEXT sum += ls_po_data-order_quantity ).

    " PCS-243 | Consideration of days since oldest open PO
      DATA(lv_days_since_oldest_open_po) =
        getDaysSinceOldestOpenPO(
          getOldestOpenPO( VALUE #( FOR ls_po_data IN lt_po_data WHERE ( material = lv_material ) ( ls_po_data ) ) ) ).
    " End of PCS-243

      APPEND VALUE #( material                  = lv_material
                      open_pos                  = lv_po_data_to_mat
                      days_since_oldest_open_po = lv_days_since_oldest_open_po ) TO rt_open_pos.

    ENDLOOP.
  ENDMETHOD.


  METHOD getlastmaterialrequest.
    IF it_material_requests IS NOT INITIAL.
      DATA(lv_last_request) = REDUCE d( INIT max = it_material_requests[ 1 ]-requestcreationtimestamp
                                         FOR material_request IN it_material_requests
                                         NEXT max = COND d( WHEN material_request-requestcreationtimestamp > max
                                                            THEN material_request-requestcreationtimestamp
                                                            ELSE max ) ).
    ENDIF.

    CONVERT DATE lv_last_request
            INTO TIME STAMP rv_last_material_request TIME ZONE sy-zonlo.
  ENDMETHOD.


  METHOD getMaterialsRange.
    SELECT material FROM /lht/a_placo_mat "#EC CI_SEL_NESTED
      FOR ALL ENTRIES IN @it_materials
      WHERE material = @it_materials-material_number
      INTO TABLE @DATA(lt_existing_materials).

    rr_materials =
      VALUE #( FOR material IN lt_existing_materials
        ( sign   = `I`
          option = `EQ`
          low    = material ) ).
  ENDMETHOD.


  METHOD getLastPurchaseOrders.
    LOOP AT it_materialnumber REFERENCE INTO DATA(lv_material).
      DATA(lv_last_request) = REDUCE #( INIT max TYPE timestampl
                                        FOR purchase_order IN it_po_data
                                        WHERE ( material = lv_material->* )
                                        NEXT max = COND #( WHEN purchase_order-last_changed_on > max
                                                           THEN purchase_order-last_changed_on
                                                           ELSE max ) ).
*      CONVERT DATE lv_last_request
*              INTO TIME STAMP DATA(lv_last_request_ts) TIME ZONE sy-zonlo.
      INSERT VALUE #( material        = lv_material->*
                      last_changed_on = lv_last_request ) INTO TABLE rt_last_purchase_orders.
    ENDLOOP.
  ENDMETHOD.


  METHOD getPlanningDepartmentRange.
    SELECT planning_department FROM /lht/a_placo_pd  "#EC CI_SEL_NESTED
      INTO TABLE @DATA(lt_planning_departments).

    rr_plan_departments =
      VALUE #( FOR ls_planning_department IN lt_planning_departments
        ( sign   = `I`
          option = `EQ`
          low    = ls_planning_department ) ).
  ENDMETHOD.


  METHOD checkForMaterialRequest.
    DATA(lv_weeks_in_past) =
      xco_cp=>sy->date( )->add( iv_day         = ( 7 * iv_weeks_in_past )
                                io_calculation = xco_cp_time=>date_calculation->ultimo )->as( xco_cp_time=>format->abap )->value.

    DATA(lv_date_in_past) = CONV d( lv_weeks_in_past(8) ).

    rv_mat_req_exists = REDUCE abap_boolean( INIT exists = abap_false
                                             FOR mat_req IN it_material_requests
                                             WHERE ( requestdate > lv_date_in_past AND
                                                   ( requeststatus <> 'CLOSED' OR
                                                     requeststatus <> 'STORNO' ) )
                                             NEXT exists = abap_true ).
  ENDMETHOD.


  METHOD get_relevant_stock.
    rt_stock_data =
      VALUE #( FOR ls_stock_data IN it_stock_data WHERE ( material_number = iv_materialnumber )
        ( ls_stock_data ) ).
  ENDMETHOD.


  METHOD checkInterchangeRelevancy.
    IF iv_single_disposet IS INITIAL.
      rv_interchangeability_relevant = abap_true.
      EXIT.
    ENDIF.

    LOOP AT it_restricted_interchange REFERENCE INTO DATA(ls_restricted_interchange).
      CASE ls_restricted_interchange->cause_of_part_exchange.
        WHEN `05`.
          rv_interchangeability_relevant = abap_true.
          EXIT.
        WHEN `01`.
          rv_interchangeability_relevant = abap_true.
          EXIT.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.


  METHOD checkSingleMRPSet.
    IF line_exists( it_mrpsets[ mrpset = iv_mrpset ] ).
      rv_is_single_material_mrp_set = abap_true.
    ELSE.
      rv_is_single_material_mrp_set = abap_false.
    ENDIF.
  ENDMETHOD.


  METHOD comparisonReplenishmentTime.
    IF iv_replenishment_time < iv_days_since_oldest_open_po.
      rv_replenishment_time = iv_days_since_oldest_open_po.
    ELSE.
      rv_replenishment_time = iv_replenishment_time.
    ENDIF.
  ENDMETHOD.


  METHOD deleteMatWithDeletionInd.
    DATA lt_materials_to_delete TYPE TABLE FOR DELETE /lht/r_placo_materials.
    DATA lt_worklists_to_delete TYPE TABLE FOR DELETE /lht/r_placo_worklist.

    IF it_material_data IS INITIAL.
      RETURN.
    ENDIF.

    SELECT master_uuid FROM /lht/a_placo_mat
      FOR ALL ENTRIES IN @it_material_data
      WHERE material = @it_material_data-material_number
      INTO TABLE @DATA(lt_material_uuids_to_delete). "#EC CI_SEL_NESTED

    SELECT UUID FROM /lht/a_placo_wrk
      FOR ALL ENTRIES IN @it_material_data
      WHERE materialNumber = @it_material_data-material_number
      INTO TABLE @DATA(lt_worklist_uuids_to_delete). "#EC CI_SEL_NESTED

    lt_materials_to_delete =
      VALUE #( FOR ls_material_uuid IN lt_material_uuids_to_delete
        ( MasterUUID = ls_material_uuid-master_uuid ) ).

    lt_worklists_to_delete =
      VALUE #( FOR ls_worklist_uuid IN lt_worklist_uuids_to_delete
        ( UUID = ls_worklist_uuid-uuid ) ).

    MODIFY ENTITIES OF /lht/r_placo_materials
           ENTITY Materials
           DELETE FROM lt_materials_to_delete.

    MODIFY ENTITIES OF /lht/r_placo_worklist
           ENTITY Worklist
           DELETE FROM lt_worklists_to_delete.
  ENDMETHOD.


  METHOD getDaysSinceOldestOpenPO.
    IF iv_oldest_date = 0.
      rv_days_since_oldest_date = 0.
      EXIT.
    ENDIF.

    DATA(lv_zonlo) = xco_cp_time=>time_zone->user->value.
    DATA(lv_today) = cl_abap_context_info=>get_system_date( ).

    CONVERT TIME STAMP iv_oldest_date TIME ZONE lv_zonlo INTO DATE DATA(lv_oldest_date).

    rv_days_since_oldest_date = lv_today - lv_oldest_date.
  ENDMETHOD.


  METHOD getOldestOpenPO.
    rv_oldest_date = REDUCE #( INIT oldest TYPE timestampl
                               FOR purchase_order IN it_open_puchase_orders
                               NEXT oldest = COND #( WHEN purchase_order-last_changed_on < oldest OR oldest IS INITIAL
                                                     THEN purchase_order-last_changed_on
                                                     ELSE oldest ) ).
  ENDMETHOD.
ENDCLASS.