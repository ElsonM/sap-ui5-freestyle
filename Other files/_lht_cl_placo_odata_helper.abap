"! <p class="shorttext synchronized" lang="en">OData Helper Class for PLACO</p>
"! <p>Helper class for accessing and retrieving material data via OData services.</p>
"! <p>Provides centralized functionality to access material stock, consumption, descriptions,</p>
"! <p>valuations, MRP sets, interchangeabilities, purchase orders and other data.</p>
CLASS /lht/cl_placo_odata_helper DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES /lht/lo_md_placo_i.
    INTERFACES /lht/lo_mb_stock_i.
    INTERFACES /lht/cm_lo_mm_materials_srv_i.
    INTERFACES /lht/lo_mb_consumption_i.
    INTERFACES /lht/lo_me_po_data_srv_i.
    INTERFACES /lht/sd_vk13_i.
    INTERFACES /lht/lo_me_pr_data_srv_i.
    INTERFACES /lht/lo_me_pr_srv_i.
    INTERFACES /lht/if_placo_constants.
    INTERFACES /lht/if_vendor_odata.

    TYPES gty_purchase_order TYPE c LENGTH 10.

    TYPES gty_t_matnr TYPE TABLE OF matnr.
    TYPES gty_t_mat_doc  TYPE TABLE OF /lht/placo_mat_document.
    TYPES gty_t_ebeln TYPE TABLE OF ebeln.
    TYPES gty_t_purchase_order TYPE TABLE OF gty_purchase_order.
    TYPES gty_t_disposets TYPE TABLE OF /lht/placo_mrp_set WITH DEFAULT KEY.
    TYPES gty_t_movement_type TYPE TABLE OF /lht/placo_movement_type.
*    TYPES gty_t_lifnr TYPE TABLE OF lifnr.

    TYPES gty_s_worklist TYPE STRUCTURE FOR READ RESULT /lht/r_placo_worklist\\worklist.

    TYPES: BEGIN OF gty_material_deep_create.
      INCLUDE TYPE /lht/cm_lo_mm_materials_srv=>tys_material_data.
      TYPES: material_pool_capabilities TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_pool_capabiliti_2.
      TYPES: material_aircrafts_set     TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_aircrafts.
      TYPES: material_characteristics_s TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_characteristics.
      TYPES: material_classification_se TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_classification.
      TYPES: material_descriptions_set  TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_descriptions.
      TYPES: material_deviation_codes_s TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_deviation_codes.
      TYPES: material_examinations_set  TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_examinations.
      TYPES: material_interchangeabilit TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_interchangeabil_2.
      TYPES: material_legals_set        TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_legals.
      TYPES: material_longtext_set      TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_longtext.
      TYPES: material_mpd_3_letter_code TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_mpd_3_letter_co_2.
      TYPES: material_mpdlocations_set  TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_mpdlocations.
      TYPES: material_mrpsets_set       TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_mrpsets.
      TYPES: material_maintenance_level TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_maintenance_lev_2.
      TYPES: material_measurement_units TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_measurement_uni_2.
      TYPES: material_restricted_interc TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_restricted_inte_2.
      TYPES: material_specifications_se TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_specifications.
      TYPES: material_storage_locations TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_storage_locatio_2.
      TYPES: material_usage_sites_set   TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_usage_sites.
      TYPES: material_valuation_history TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_valuation_histo_2.
      TYPES: material_valuations_set    TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_valuations.
    TYPES: END OF gty_material_deep_create.

    CLASS-METHODS read_placo_zmmclass
      IMPORTING
        it_materialnumber TYPE gty_t_matnr
      EXPORTING
        et_zmmclass_data  TYPE /lht/lo_md_placo_srv=>tyt_zmmclass_worklist
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_placo_dailyConsumption
      IMPORTING
        it_materialnumber        TYPE gty_t_matnr         OPTIONAL
        it_material_doc          TYPE gty_t_mat_doc       OPTIONAL
        it_movement_type         TYPE gty_t_movement_type OPTIONAL
      EXPORTING
        et_dailyconsumption_data TYPE /lht/lo_md_placo_srv=>tyt_daily_consumption
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_stock_mat_stock
      IMPORTING
        it_materialnumber TYPE gty_t_matnr
      EXPORTING
        et_mat_stock_data TYPE /lht/lo_mb_stock_srv=>tyt_material_stock
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_material_mat_data
      IMPORTING
        it_materialnumber TYPE gty_t_matnr
      EXPORTING
        et_material_data  TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_data
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_material_storage_location
      IMPORTING
        it_materialnumber TYPE gty_t_matnr
      EXPORTING
        et_material_data  TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_storage_locatio_2
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_material_longtext
      IMPORTING
        iv_materialnumber    TYPE /lht/placo_mat_number
      EXPORTING
        et_material_longtext TYPE /lht/tt_placo_longtext_x04
      RAISING
        /lht/cx_placo_check.

*     CLASS-METHODS read_material_prices
*       IMPORTING
*         iv_materialnumber  TYPE /lht/placo_mat_number
*       EXPORTING
*         et_material_prices TYPE /lht/sd_vk13_srv=>tyt_material_price
*       RAISING
*         /lht/cx_placo_check.

    CLASS-METHODS read_relevant_material_matdata
      IMPORTING
        it_filters       TYPE if_rap_query_filter=>tt_name_range_pairs
      EXPORTING
        et_material_data TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_data
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_material_mat_desc
      IMPORTING
        it_materialnumber TYPE gty_t_matnr
        iv_language_key   TYPE /lht/placo_lenguage
      EXPORTING
        et_mat_desc_data  TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_descriptions
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_material_mat_valuations
      IMPORTING
        it_materialnumber      TYPE gty_t_matnr
      EXPORTING
        et_mat_valuations_data TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_valuations
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_material_mrpset
      IMPORTING
        it_materialnumber TYPE gty_t_matnr
      EXPORTING
        et_mrpset_data    TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_mrpsets
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_disposet_mrpset
      IMPORTING
        it_disposets   TYPE gty_t_disposets
      EXPORTING
        et_mrpset_data TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_mrpsets
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_material_valuations
      IMPORTING
        it_materialnumber           TYPE gty_t_matnr
      EXPORTING
        et_material_valuations_data TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_valuations
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_consumption_data
      IMPORTING
        it_materialnumber   TYPE gty_t_matnr
      EXPORTING
        et_consumption_data TYPE /lht/lo_mb_consumption_srv=>tyt_consumption_data
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_po_item_data
      IMPORTING
        it_purch_order    TYPE gty_t_ebeln OPTIONAL
        it_materialnumber TYPE gty_t_matnr OPTIONAL
      EXPORTING
        et_po_data        TYPE /lht/lo_me_po_data_srv=>tyt_purchase_order_items
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_open_po_data
      IMPORTING
        it_purchase_orders TYPE gty_t_purchase_order
      EXPORTING
        et_po_data         TYPE /lht/lo_me_po_data_srv=>tyt_purchase_orders
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_vk13_mat_mrpset
      IMPORTING
        it_materialnumber       TYPE gty_t_matnr
      EXPORTING
        et_vk13_mat_mrpset_data TYPE /lht/sd_vk13_srv=>tyt_material_price
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_mat_interchangeabilities
      IMPORTING
        it_materialnumber TYPE gty_t_matnr "/lht/cm_lo_mm_materials_srv=>tyt_material_data
      EXPORTING
        et_mat_inter_data TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_interchangeabil_2
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_mat_restricted_inter
      IMPORTING
        it_materialnumber      TYPE gty_t_matnr "/lht/cm_lo_mm_materials_srv=>tyt_material_data
      EXPORTING
        et_mat_rest_inter_data TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_restricted_inte_2
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_material_psg
      RETURNING
        VALUE(rt_material_data) TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_data
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_mrpset_materials
      IMPORTING
        it_disposets        TYPE gty_t_disposets
      RETURNING
        VALUE(rt_materials) TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_mrpsets
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_pr_item_data
      IMPORTING
        it_purch_req      TYPE gty_t_ebeln OPTIONAL
        it_materialnumber TYPE gty_t_matnr OPTIONAL
      EXPORTING
        et_pr_data        TYPE /lht/lo_me_pr_data_srv=>tyt_purchase_requisition_ite_2
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_vendors_data
      EXPORTING
        et_vendor_data  TYPE /lht/cm_lo_me_vendor_data_srv=>tyt_vendors
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_material_stor_loc_set
      IMPORTING
        it_materialnumber TYPE gty_t_matnr
      CHANGING
        ct_material_data  TYPE ANY TABLE
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_vendors_data_set
      CHANGING
        ct_vendor_data  TYPE ANY TABLE
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS deep_create_material_data
      IMPORTING
        is_materials      TYPE gty_s_worklist
        is_changed_values TYPE /lht/a_placo_mat
      RAISING
        /lht/cx_odata_exception.

    CLASS-METHODS create_purchase_requisition
      IMPORTING
        is_purchase_requisition               TYPE /LHT/A_PLACO_CREATE_PR
      RETURNING
        VALUE(rt_mapped_purchase_requisition) TYPE /lht/lo_me_pr_srv_i~x04_purchase_requisition
      RAISING
        /lht/cx_odata_exception.

  PRIVATE SECTION.
    ALIASES placo_entity_names FOR /lht/lo_md_placo_i~entity_set_names.
    ALIASES placo_proxy_key    FOR /lht/lo_md_placo_i~proxy_model_key.
    ALIASES placo_service_root FOR /lht/lo_md_placo_i~service_root.
    ALIASES placo_entity_types FOR /lht/lo_md_placo_i~entity_types.

    ALIASES stock_entity_names FOR /lht/lo_mb_stock_i~entity_set_names.
    ALIASES stock_proxy_key    FOR /lht/lo_mb_stock_i~proxy_model_key.
    ALIASES stock_service_root FOR /lht/lo_mb_stock_i~service_root.
    ALIASES stock_entity_types FOR /lht/lo_mb_stock_i~entity_types.

    ALIASES materials_entity_names FOR /lht/cm_lo_mm_materials_srv_i~entity_set_names.
    ALIASES materials_proxy_key    FOR /lht/cm_lo_mm_materials_srv_i~proxy_model_key.
    ALIASES materials_service_root FOR /lht/cm_lo_mm_materials_srv_i~service_root.
    ALIASES materials_entity_types FOR /lht/cm_lo_mm_materials_srv_i~entity_types.

    ALIASES consumption_entity_names FOR /lht/lo_mb_consumption_i~entity_set_names.
    ALIASES consumption_proxy_key    FOR /lht/lo_mb_consumption_i~proxy_model_key.
    ALIASES consumption_service_root FOR /lht/lo_mb_consumption_i~service_root.
    ALIASES consumption_entity_types FOR /lht/lo_mb_consumption_i~entity_types.

    ALIASES po_entity_names FOR /lht/lo_me_po_data_srv_i~entity_set_names.
    ALIASES po_proxy_key    FOR /lht/lo_me_po_data_srv_i~proxy_model_key.
    ALIASES po_service_root FOR /lht/lo_me_po_data_srv_i~service_root.
    ALIASES po_entity_types FOR /lht/lo_me_po_data_srv_i~entity_types.

    ALIASES pr_entity_names FOR /lht/lo_me_pr_data_srv_i~entity_set_names.
    ALIASES pr_proxy_key    FOR /lht/lo_me_pr_data_srv_i~proxy_model_key.
    ALIASES pr_service_root FOR /lht/lo_me_pr_data_srv_i~service_root.
    ALIASES pr_entity_types FOR /lht/lo_me_pr_data_srv_i~entity_types.

    ALIASES post_pr_entity_names FOR /lht/lo_me_pr_srv_i~entity_set_names.
    ALIASES post_pr_proxy_key    FOR /lht/lo_me_pr_srv_i~proxy_model_key.
    ALIASES post_pr_service_root FOR /lht/lo_me_pr_srv_i~service_root.
    ALIASES post_pr_entity_types FOR /lht/lo_me_pr_srv_i~entity_types.

    ALIASES vk13_entity_names FOR /lht/sd_vk13_i~entity_set_names.
    ALIASES vk13_proxy_key    FOR /lht/sd_vk13_i~proxy_model_key.
    ALIASES vk13_service_root FOR /lht/sd_vk13_i~service_root.
    ALIASES vk13_entity_types FOR /lht/sd_vk13_i~entity_types.

    ALIASES vendor_proxy_key FOR /lht/if_vendor_odata~proxy_model_key.
    ALIASES vendor_service   FOR /lht/if_vendor_odata~X04_Service.

    ALIASES communication FOR /lht/if_placo_constants~communication.

    TYPES ltt_t_navigation TYPE TABLE OF string WITH DEFAULT KEY.

    CLASS-METHODS mapWorklistToDeepEntity
      IMPORTING
        is_materials          TYPE gty_s_worklist
        is_changed_values     TYPE /lht/a_placo_mat
      RETURNING
        VALUE(rs_deep_create) TYPE gty_material_deep_create.

    CLASS-METHODS read_placo_zmmclass_set
      IMPORTING
        it_materialnumber TYPE gty_t_matnr
      CHANGING
        ct_zmmclass_data  TYPE ANY TABLE
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_placo_dailyConsumptio_set
      IMPORTING
        it_materialnumber         TYPE gty_t_matnr
        it_material_doc           TYPE gty_t_mat_doc
        it_movement_type          TYPE gty_t_movement_type OPTIONAL
      CHANGING
        ct_daily_consumption_data TYPE ANY TABLE
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_material_mrpset_set
      IMPORTING
        it_materialnumber TYPE gty_t_matnr
      EXPORTING
        et_mrpset_data    TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_mrpsets
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_disposet_mrpset_set
      IMPORTING
        it_disposets   TYPE gty_t_disposets
      EXPORTING
        et_mrpset_data TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_mrpsets
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_stock_mat_stock_set
      IMPORTING
        it_materialnumber TYPE gty_t_matnr
      CHANGING
        ct_mat_stock_data TYPE ANY TABLE
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_material_mat_data_entity
      IMPORTING
        iv_materialnumber TYPE matnr
      CHANGING
        cs_material_data  TYPE any
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_material_mat_data_set
      IMPORTING
        it_materialnumber TYPE gty_t_matnr
      CHANGING
        ct_material_data  TYPE ANY TABLE
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_mat_longtext_data_set
      IMPORTING
        iv_materialnumber TYPE /lht/placo_mat_number
      EXPORTING
        et_mat_longtext   TYPE /lht/tt_placo_longtext_x04
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_material_mat_desc_entity
      IMPORTING
        iv_materialnumber TYPE matnr
        iv_language_key   TYPE /lht/placo_lenguage
      CHANGING
        cs_mat_desc_data  TYPE any
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_material_mat_desc_set
      IMPORTING
        it_materialnumber TYPE gty_t_matnr
        iv_language_key   TYPE /lht/placo_lenguage
      CHANGING
        ct_mat_desc_data  TYPE ANY TABLE
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_material_mrpset_entity
      IMPORTING
        iv_materialnumber TYPE matnr
      CHANGING
        cs_mrpset_data    TYPE any
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_material_valuations_set
      IMPORTING
        it_materialnumber           TYPE gty_t_matnr
      CHANGING
        ct_material_valuations_data TYPE ANY TABLE
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_consumption_data_set
      IMPORTING
        it_materialnumber   TYPE gty_t_matnr
      CHANGING
        ct_consumption_data TYPE ANY TABLE
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_po_item_data_set
      IMPORTING
        it_purch_order    TYPE gty_t_ebeln OPTIONAL
        it_materialnumber TYPE gty_t_matnr OPTIONAL
      CHANGING
        ct_po_data        TYPE ANY TABLE
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_vk13_mat_mrpset_set
      IMPORTING
        it_materialnumber       TYPE gty_t_matnr
      CHANGING
        ct_material_mrpset_data TYPE ANY TABLE
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_open_po_data_set
      IMPORTING
        it_purchase_orders TYPE gty_t_purchase_order
      CHANGING
        ct_po_data         TYPE /lht/lo_me_po_data_srv=>tyt_purchase_orders
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_material_mat_valuatio_set
      IMPORTING
        it_materialnumber      TYPE gty_t_matnr
      CHANGING
        ct_mat_valuations_data TYPE ANY TABLE
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_pr_item_data_set
      IMPORTING
        it_purch_req      TYPE gty_t_ebeln OPTIONAL
        it_materialnumber TYPE gty_t_matnr OPTIONAL
      CHANGING
        ct_pr_data        TYPE ANY TABLE
      RAISING
        /lht/cx_placo_check.

    " ---------------------------------------------------------------------

    CLASS-METHODS read_material_entityset_srv
      IMPORTING
        iv_entityset_name      TYPE /iwbep/if_cp_runtime_types=>ty_entity_set_name
        it_filter              TYPE if_rap_query_filter=>tt_name_range_pairs       OPTIONAL
        iv_top                 TYPE i                                              OPTIONAL
        it_selected_properties TYPE /iwbep/if_cp_runtime_types=>ty_t_property_path OPTIONAL
      CHANGING
        ct_data                TYPE ANY TABLE
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_placo_entityset_srv
      IMPORTING
        iv_entityset_name      TYPE /iwbep/if_cp_runtime_types=>ty_entity_set_name
        it_filter              TYPE if_rap_query_filter=>tt_name_range_pairs       OPTIONAL
        it_selected_properties TYPE /iwbep/if_cp_runtime_types=>ty_t_property_path OPTIONAL
      CHANGING
        ct_data                TYPE ANY TABLE
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_material_longtext_srv
      IMPORTING
        iv_entityset_name TYPE /iwbep/if_cp_runtime_types=>ty_entity_set_name
        iv_mat_number     TYPE /lht/placo_mat_number
      EXPORTING
        et_mat_longtext   TYPE /lht/tt_placo_longtext_x04
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_stock_entityset_srv
      IMPORTING
        iv_entityset_name      TYPE /iwbep/if_cp_runtime_types=>ty_entity_set_name
        it_filter              TYPE if_rap_query_filter=>tt_name_range_pairs       OPTIONAL
        it_selected_properties TYPE /iwbep/if_cp_runtime_types=>ty_t_property_path OPTIONAL
      CHANGING
        ct_data                TYPE ANY TABLE
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_material_entity_srv
      IMPORTING
        iv_entityset_name TYPE /iwbep/if_cp_runtime_types=>ty_entity_set_name
        is_key            TYPE any
      CHANGING
        cs_data           TYPE any
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_consumption_entityset_srv
      IMPORTING
        iv_entityset_name      TYPE /iwbep/if_cp_runtime_types=>ty_entity_set_name
        it_filter              TYPE if_rap_query_filter=>tt_name_range_pairs       OPTIONAL
        it_selected_properties TYPE /iwbep/if_cp_runtime_types=>ty_t_property_path OPTIONAL
      CHANGING
        ct_data                TYPE ANY TABLE
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_po_entityset_srv
      IMPORTING
        iv_entityset_name      TYPE /iwbep/if_cp_runtime_types=>ty_entity_set_name
        it_filter              TYPE if_rap_query_filter=>tt_name_range_pairs       OPTIONAL
        it_selected_properties TYPE /iwbep/if_cp_runtime_types=>ty_t_property_path OPTIONAL
      CHANGING
        ct_data                TYPE ANY TABLE
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_pr_entityset_srv
      IMPORTING
        iv_entityset_name      TYPE /iwbep/if_cp_runtime_types=>ty_entity_set_name
        it_filter              TYPE if_rap_query_filter=>tt_name_range_pairs       OPTIONAL
        it_selected_properties TYPE /iwbep/if_cp_runtime_types=>ty_t_property_path OPTIONAL
      CHANGING
        ct_data                TYPE ANY TABLE
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_vk13_entityset_srv
      IMPORTING
        iv_entityset_name      TYPE /iwbep/if_cp_runtime_types=>ty_entity_set_name
        it_filter              TYPE if_rap_query_filter=>tt_name_range_pairs       OPTIONAL
        it_selected_properties TYPE /iwbep/if_cp_runtime_types=>ty_t_property_path OPTIONAL
      CHANGING
        ct_data                TYPE ANY TABLE
      RAISING
        /lht/cx_placo_check.

    CLASS-METHODS read_vendor_entityset_srv
      IMPORTING
        iv_entityset_name      TYPE /iwbep/if_cp_runtime_types=>ty_entity_set_name
        it_filter              TYPE if_rap_query_filter=>tt_name_range_pairs       OPTIONAL
        it_selected_properties TYPE /iwbep/if_cp_runtime_types=>ty_t_property_path OPTIONAL
      CHANGING
        ct_data                TYPE ANY TABLE
      RAISING
        /lht/cx_placo_check.

    " ---------------------------------------------------------------------

    CLASS-METHODS build_mat_filter
      IMPORTING
        it_material      TYPE gty_t_matnr
      RETURNING
        VALUE(rt_filter) TYPE if_rap_query_filter=>tt_name_range_pairs.

*    CLASS-METHODS build_vendor_filter
*      IMPORTING
*        it_vendor       TYPE gty_t_lifnr
*      RETURNING
*        VALUE(rt_filter) TYPE if_rap_query_filter=>tt_name_range_pairs.

    CLASS-METHODS build_vk13_filter
      IMPORTING
        it_material      TYPE gty_t_matnr
      RETURNING
        VALUE(rt_filter) TYPE if_rap_query_filter=>tt_name_range_pairs.

    CLASS-METHODS build_zmmclass_filter
      IMPORTING
        it_material      TYPE gty_t_matnr
      RETURNING
        VALUE(rt_filter) TYPE if_rap_query_filter=>tt_name_range_pairs.

    CLASS-METHODS build_mat_inter_filter
*      IMPORTING
*        iv_inter_check   TYPE abap_bool
      RETURNING
        VALUE(rt_filter) TYPE if_rap_query_filter=>tt_name_range_pairs.

    CLASS-METHODS build_ebeln_filter
      IMPORTING
        it_ebeln         TYPE gty_t_ebeln
      RETURNING
        VALUE(rt_filter) TYPE if_rap_query_filter=>tt_name_range_pairs.

    CLASS-METHODS build_valuations_filter
      IMPORTING
        it_material      TYPE gty_t_matnr
      RETURNING
        VALUE(rt_filter) TYPE if_rap_query_filter=>tt_name_range_pairs.

    CLASS-METHODS build_mat_desc_filter
      IMPORTING
        it_material      TYPE gty_t_matnr
        iv_language      TYPE /lht/placo_lenguage
      RETURNING
        VALUE(rt_filter) TYPE if_rap_query_filter=>tt_name_range_pairs.

    CLASS-METHODS build_consumption_data_filter
      IMPORTING
        it_material      TYPE gty_t_matnr
      RETURNING
        VALUE(rt_filter) TYPE if_rap_query_filter=>tt_name_range_pairs.

    CLASS-METHODS build_dailyConsumptio_filter
      IMPORTING
        it_material      TYPE gty_t_matnr         OPTIONAL
        it_material_doc  TYPE gty_t_mat_doc       OPTIONAL
        it_movement_type TYPE gty_t_movement_type OPTIONAL
      RETURNING
        VALUE(rt_filter) TYPE if_rap_query_filter=>tt_name_range_pairs.

    CLASS-METHODS build_psg_filter
      RETURNING
        VALUE(rt_filter) TYPE if_rap_query_filter=>tt_name_range_pairs.

    CLASS-METHODS build_po_mat_filter
      IMPORTING
        it_material      TYPE gty_t_matnr
      RETURNING
        VALUE(rt_filter) TYPE if_rap_query_filter=>tt_name_range_pairs.

    CLASS-METHODS build_po_filter
      IMPORTING
        it_purchase_orders TYPE gty_t_purchase_order
      RETURNING
        VALUE(rt_filter)   TYPE if_rap_query_filter=>tt_name_range_pairs.

    CLASS-METHODS getCorrespondingErrorMessage
      IMPORTING
        iv_entityset_name       TYPE /iwbep/if_cp_runtime_types=>ty_entity_set_name
      RETURNING
        VALUE(rv_error_message) TYPE /lht/cx_placo_check=>lty_reason.

    CLASS-METHODS build_mrpset_filter
      IMPORTING
        it_mrpsets       TYPE gty_t_disposets
      RETURNING
        VALUE(rt_filter) TYPE if_rap_query_filter=>tt_name_range_pairs.

    CLASS-METHODS build_pr_filter
      IMPORTING
        it_ebeln         TYPE gty_t_ebeln
      RETURNING
        VALUE(rt_filter) TYPE if_rap_query_filter=>tt_name_range_pairs.

    CLASS-METHODS build_pr_mat_filter
      IMPORTING
        it_materialnumber TYPE gty_t_matnr
      RETURNING
        VALUE(rt_filter)  TYPE if_rap_query_filter=>tt_name_range_pairs.

    CLASS-METHODS convertMaterialForPrPost
      IMPORTING
        is_purchase_requisition               TYPE /lht/a_placo_create_pr
      RETURNING
        VALUE(rt_mapped_purchase_requisition) TYPE /lht/lo_me_pr_srv_i~x04_purchase_requisition.

    CLASS-METHODS setPrNavigationForPrPost
      RETURNING
        VALUE(rt_navigation) TYPE ltt_t_navigation.

ENDCLASS.



CLASS /LHT/CL_PLACO_ODATA_HELPER IMPLEMENTATION.


  METHOD build_consumption_data_filter.
    DATA(lv_verification_date_in_past) =
      xco_cp=>sy->date( )->subtract( iv_month       = 24
                                     io_calculation = xco_cp_time=>date_calculation->ultimo )->as(
                                       xco_cp_time=>format->abap )->value.

    rt_filter = VALUE #( ( name  = 'MATERIALNUMBER'
                           range = VALUE #( FOR lv_material IN it_material
                                              ( low    = lv_material
                                                option = |EQ|
                                                sign   = |I| ) ) )
                         ( name  = |BUSINESSYEAR|
                           range = VALUE #( ( low    = lv_verification_date_in_past(4)
                                              option = |GE|
                                              sign   = |I| ) ) ) ).
  ENDMETHOD.


  METHOD build_dailyConsumptio_filter.
    DATA lv_today_minus_365 TYPE d.

    DATA(lv_today) = cl_abap_context_info=>get_system_date( ).
    lv_today_minus_365 = lv_today - 365.

    IF it_movement_type IS NOT INITIAL.
      rt_filter = VALUE #( ( name  = 'MATERIAL_NUMBER'
                             range = VALUE #( FOR lv_material IN it_material
                                                ( low    = lv_material
                                                  option = |EQ|
                                                  sign   = |I| ) ) )
                           ( name  = |MATERIAL_DOCUMENT_YEAR|
                             range = VALUE #( ( low    = lv_today_minus_365(4)
                                                option = |GE|
                                                sign   = |I| ) ) )
                           ( name  = |MOVEMENT_TYPE|
                             range = VALUE #( FOR lv_movement_type IN it_movement_type
                                                ( low    = lv_movement_type
                                                  option = |EQ|
                                                  sign   = |I| ) ) ) ).
    ELSE.
      rt_filter = VALUE #( ( name  = 'MATERIAL_DOCUMENT'
                             range = VALUE #( FOR lv_material_doc IN it_material_doc
                                                ( low    = lv_material_doc
                                                  option = |EQ|
                                                  sign   = |I| ) ) )
                           ( name  = |MATERIAL_DOCUMENT_YEAR|
                             range = VALUE #( ( low    = lv_today_minus_365(4)
                                                option = |GE|
                                                sign   = |I| ) ) ) ).
    ENDIF.
  ENDMETHOD.


  METHOD build_ebeln_filter.
    rt_filter = VALUE #( FOR lv_ebeln IN it_ebeln
                           ( name  = 'PURCHASE_ORDER'
                             range = VALUE #( ( low    = lv_ebeln
                                                option = |EQ|
                                                sign   = |I| ) ) ) ).
  ENDMETHOD.


  METHOD build_mat_desc_filter.
    rt_filter = VALUE #( ( name  = 'MATERIAL_NUMBER'
                           range = VALUE #( FOR lv_material IN it_material
                                              ( low    = lv_material
                                                option = |EQ|
                                                sign   = |I| ) ) )
                         ( name  = 'LANGUAGE_KEY'
                           range = VALUE  #( ( low    = iv_language
                                               option = |EQ|
                                               sign   = |I|  ) ) ) ).
  ENDMETHOD.


  METHOD build_mat_filter.
    rt_filter = VALUE #( ( name  = 'MATERIAL_NUMBER'
                           range = VALUE #( FOR lv_material IN it_material
                                              ( low    = lv_material
                                                option = |EQ|
                                                sign   = |I| ) ) ) ).
  ENDMETHOD.


  METHOD build_mat_inter_filter.
    rt_filter = VALUE #( ( name  = 'INTERCHANGEABILITIES_CHECK'
                           range = VALUE #( ( low    = 'X'
                                              option = |EQ|
                                              sign   = |I| ) ) ) ).
  ENDMETHOD.


  METHOD build_mrpset_filter.
    rt_filter = VALUE #( ( name  = 'MRPSET'
                           range = VALUE #( FOR lv_mrpset IN it_mrpsets
                                              ( low    = lv_mrpset
                                                option = |EQ|
                                                sign   = |I| ) ) ) ).
  ENDMETHOD.


  METHOD build_po_filter.
    rt_filter = VALUE #( ( name  = 'PURCHASE_ORDER'
                           range = VALUE #( FOR lv_purchase_order IN it_purchase_orders
                                              ( low    = lv_purchase_order
                                                option = |EQ|
                                                sign   = |I| ) ) ) ).
  ENDMETHOD.


  METHOD build_po_mat_filter.
    rt_filter = VALUE #( ( name  = 'MATERIAL'
                           range = VALUE #( FOR lv_material IN it_material
                                              ( low    = lv_material
                                                option = |EQ|
                                                sign   = |I| ) ) ) ).
  ENDMETHOD.


  METHOD build_pr_filter.
    rt_filter = VALUE #( FOR lv_ebeln IN it_ebeln
                         ( name  = 'PURCHASE_REQUISITION'
                           range = VALUE #( ( low    = lv_ebeln
                                              option = |EQ|
                                              sign   = |I| ) ) ) ).
  ENDMETHOD.


  METHOD build_psg_filter.
    SELECT planning_department FROM /lht/a_placo_pd INTO TABLE @DATA(lt_plan_departments).

    DATA(lv_index) = 1.
    DATA(lv_chunk) = 3.
    DATA(lv_total_lines) = lines( lt_plan_departments ).

    DO.
      IF lv_index > lv_total_lines.
        EXIT.
      ENDIF.
      INSERT VALUE #( name  = 'MATERIAL_PLANNING_DEPARTME'
                      range = VALUE #( FOR lv_plan_department IN lt_plan_departments
                                         FROM lv_index TO lv_chunk
                                         ( low    = lv_plan_department
                                           option = |EQ|
                                           sign   = |I| ) ) ) INTO TABLE rt_filter.
      lv_index += 3.
      lv_chunk += 3.
      IF lv_chunk > lv_total_lines.
        lv_chunk = lv_total_lines.
      ENDIF.
    ENDDO.
  ENDMETHOD.


  METHOD build_valuations_filter.
    rt_filter = VALUE #(
      ( name = 'MATERIAL_NUMBER' range = VALUE #( FOR lv_material IN it_material
                                   ( low = lv_material option = |EQ| sign = |I| ) ) )
      ( name  = |VALUATION_TYPE| range = VALUE #(
                                   ( low = |S|         option = |EQ| sign = |I| ) ) )
      ( name  = |VALUATION_AREA| range = VALUE #(
                                   ( low = |1000|      option = |EQ| sign = |I| ) ) ) ).
  ENDMETHOD.


  METHOD build_vk13_filter.
    rt_filter = VALUE #( ( name  = 'MATERIAL_NUMBER'
                           range = VALUE #( FOR lv_material IN it_material
                                              ( low    = lv_material
                                                option = |EQ|
                                                sign   = |I| ) ) )
                          ( name  = |CONDITION_TYPE|
                            range = VALUE #( ( low    = 'ZPR0'
                                               option = |GE|
                                               sign   = |I| ) ) )
                          ( name  = |CONDITION_TYPE|
                            range = VALUE #( ( low    = 'ZFMP'
                                               option = |GE|
                                               sign   = |I| ) ) )
                          ( name  = |CONDITION_TYPE|
                            range = VALUE #( ( low    = 'ZPXC'
                                               option = |GE|
                                               sign   = |I| ) ) ) ).
  ENDMETHOD.


  METHOD build_zmmclass_filter.
    rt_filter = VALUE #( ( name  = 'MATERIALNUMBER'
                           range = VALUE #( FOR lv_material IN it_material
                                              ( low    = lv_material
                                                option = |EQ|
                                                sign   = |I| ) ) ) ).
  ENDMETHOD.


  METHOD deep_create_material_data.
    " ____________________________________________________________________
    " \\ Mapping of navigation
    " ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    DATA lt_navigations TYPE TABLE OF string.

    DATA(ls_nav) = /lht/cm_lo_mm_materials_srv=>gcs_entity_type-material_data-navigation.

    APPEND ls_nav-material_aircrafts_set     TO lt_navigations.
    APPEND ls_nav-material_characteristics_s TO lt_navigations.
    APPEND ls_nav-material_classification_se TO lt_navigations.
    APPEND ls_nav-material_descriptions_set  TO lt_navigations.
    APPEND ls_nav-material_examinations_set  TO lt_navigations.
    APPEND ls_nav-material_interchangeabilit TO lt_navigations.
    APPEND ls_nav-material_legals_set        TO lt_navigations.
    APPEND ls_nav-material_longtext_set      TO lt_navigations.
    APPEND ls_nav-material_maintenance_level TO lt_navigations.
    APPEND ls_nav-material_measurement_units TO lt_navigations.
    APPEND ls_nav-material_mrpsets_set       TO lt_navigations.
    APPEND ls_nav-material_pool_capabilities TO lt_navigations.
    APPEND ls_nav-material_restricted_interc TO lt_navigations.
    APPEND ls_nav-material_specifications_se TO lt_navigations.
    APPEND ls_nav-material_storage_locations TO lt_navigations.
    APPEND ls_nav-material_usage_sites_set   TO lt_navigations.
    APPEND ls_nav-material_valuations_set    TO lt_navigations.

    " //
    TRY.
        DATA(lo_service_handler) = NEW /lht/cl_odata_service_handler(
            iv_btp_destination_name = communication-scenario
            iv_service_id           = communication-service
            iv_comm_arrangement     = abap_true
            is_proxy_model_key      = VALUE #(
              repository_id       = materials_proxy_key-repository_id
              proxy_model_id      = materials_proxy_key-proxy_model_id
              proxy_model_version = materials_proxy_key-proxy_model_version )
            iv_service_root         = materials_service_root ).

        lo_service_handler->create_post_request(
          /lht/cm_lo_mm_materials_srv_i~entity_set_names-material_data_set ).
      CATCH /lht/cx_odata_exception INTO DATA(lx_odata).
        RAISE EXCEPTION lx_odata.
    ENDTRY.

    " ____________________________________________________________________
    " \\ Setting deep entities
    " ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
    TRY.
        lo_service_handler->set_deep_entity(
            is_deep_entity = mapworklisttodeepentity(
              is_materials      = is_materials
              is_changed_values = is_changed_values )
            it_child_navigations = lt_navigations ).
      CATCH /lht/cx_odata_exception INTO DATA(lcx_interface_exc). " TODO: variable is assigned but never used (ABAP cleaner)
    ENDTRY.
    " //

    DATA(ls_business_data) = VALUE gty_material_deep_create( ).

    TRY.
        DATA(lo_response) = lo_service_handler->execute_post_request( ).
      CATCH /lht/cx_odata_exception INTO DATA(lx_odata2).
        RAISE EXCEPTION lx_odata2.
    ENDTRY.

    TRY.
        lo_response->get_business_data( IMPORTING es_business_data = ls_business_data ).
      CATCH /iwbep/cx_gateway.
    ENDTRY.
  ENDMETHOD.


  METHOD getCorrespondingErrorMessage.
    CASE iv_entityset_name.
      WHEN materials_entity_names-material_data_set.
        rv_error_message = /lht/cx_placo_check=>material_odata.
      WHEN materials_entity_names-material_rest_interchange_set.
        rv_error_message = /lht/cx_placo_check=>restricted_inter_odata.
      WHEN materials_entity_names-material_interchangeabili_set.
        rv_error_message = /lht/cx_placo_check=>interchangeabilities_odata.
      WHEN materials_entity_names-material_valuations_set.
        rv_error_message = /lht/cx_placo_check=>material_valuations_odata.
      WHEN materials_entity_names-material_mrpsets_set.
        rv_error_message = /lht/cx_placo_check=>mrpset_odata.
      WHEN materials_entity_names-material_descriptions_set.
        rv_error_message = /lht/cx_placo_check=>material_descriptions_odata.
      WHEN placo_entity_names-daily_consumption.
        rv_error_message = /lht/cx_placo_check=>daily_consumption_odata.
      WHEN placo_entity_names-zmmclass_worklist.
        rv_error_message = /lht/cx_placo_check=>zmmclass_odata.
      WHEN po_entity_names-purchaseorders.
        rv_error_message = /lht/cx_placo_check=>purchase_order_odata.
      WHEN po_entity_names-purchaseorderitems.
        rv_error_message = /lht/cx_placo_check=>purchase_order_odata.
      WHEN vk13_entity_names-material_price.
        rv_error_message = /lht/cx_placo_check=>vk13_odata.
      WHEN stock_entity_names-material_stock.
        rv_error_message = /lht/cx_placo_check=>material_stock_odata.
      WHEN consumption_entity_names-consumption_data.
        rv_error_message = /lht/cx_placo_check=>consumption_odata.
    ENDCASE.
  ENDMETHOD.


  METHOD mapWorklistToDeepEntity.
    SELECT SINGLE * FROM /lht/a_placo_mat
      WHERE material = @is_materials-Materialnumber
      INTO @DATA(ls_material).

    DATA lt_material_data TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_data.

    TRY.
        read_material_entityset_srv(
          EXPORTING
            iv_entityset_name = materials_entity_names-material_data_set
            it_filter         = build_mat_filter( VALUE #( ( ls_material-material ) ) )
          CHANGING
            ct_data           = lt_material_data ).
      CATCH /lht/cx_placo_check.
        " handle exception
    ENDTRY.

    IF lines( lt_material_data ) = 1.
      DATA(ls_material_data) = lt_material_data[ 1 ].
    ELSE.
      EXIT.
    ENDIF.

    rs_deep_create = VALUE #(
      material_number            = is_materials-Materialnumber
      manufacturer_part_number   = ls_material_data-manufacturer_part_number
      manufacturer               = ls_material_data-manufacturer
      material_type              = ls_material_data-material_type
      article_variance           = ls_material_data-article_variance
      material_planning_departme = ls_material_data-material_planning_departme
      pool_capability            = ls_material_data-pool_capability
      pool_capability_reason_cod = ls_material_data-pool_capability_reason_cod
      reorder_point              = COND #( WHEN is_changed_values-reorder_point IS NOT INITIAL
                                           THEN is_changed_values-reorder_point
                                           ELSE '' )
      commodity_code             = COND #( WHEN is_changed_values-customs_tariff_code IS NOT INITIAL
                                           THEN is_changed_values-customs_tariff_code
                                           ELSE '' )
      planned_delivery_time      = COND #( WHEN is_changed_values-replenishment_time IS NOT INITIAL
                                           THEN is_changed_values-replenishment_time
                                           ELSE '' )
      safety_stock               = COND #( WHEN is_changed_values-safety_stock IS NOT INITIAL
                                           THEN is_changed_values-safety_stock
                                           ELSE '' ) ).
  ENDMETHOD.


  METHOD read_consumption_data.
    read_consumption_data_set(
      EXPORTING
        it_materialnumber   = it_materialnumber
      CHANGING
        ct_consumption_data = et_consumption_data ).
  ENDMETHOD.


  METHOD read_consumption_data_set.
    read_consumption_entityset_srv(
      EXPORTING
        iv_entityset_name = consumption_entity_names-consumption_data
        it_filter         = build_consumption_data_filter( it_materialnumber )
      CHANGING
        ct_data           = ct_consumption_data ).
  ENDMETHOD.


  METHOD read_consumption_entityset_srv.
    TRY.
        DATA(lo_service_handler) = NEW /lht/cl_odata_service_handler(
                                     iv_btp_destination_name = 'X04_PLACO'
                                     iv_comm_arrangement     = abap_false
                                     is_proxy_model_key      = VALUE #(
                                       repository_id       = consumption_proxy_key-repository_id
                                       proxy_model_id      = consumption_proxy_key-proxy_model_id
                                       proxy_model_version = consumption_proxy_key-proxy_model_version )
                                     iv_service_root         = consumption_service_root
                                     iv_authn_mode           = if_a4c_cp_service=>service_specific ).

        lo_service_handler->create_read_request( iv_entity_set_name = iv_entityset_name
                                                 it_r_filters       = it_filter
                                                 it_propertys       = it_selected_properties ).

        lo_service_handler->execute_read_request( CHANGING ct_response_data = ct_data ).

        lo_service_handler->close( ).
      CATCH /lht/cx_odata_exception.
        RAISE EXCEPTION NEW /lht/cx_placo_check( iv_error_message = getCorrespondingErrorMessage( iv_entityset_name ) ).
    ENDTRY.
  ENDMETHOD.


  METHOD read_disposet_mrpset.
    read_disposet_mrpset_set(
      EXPORTING
        it_disposets   = it_disposets
      IMPORTING
        et_mrpset_data = et_mrpset_data ).
  ENDMETHOD.


  METHOD read_disposet_mrpset_set.
    read_material_entityset_srv(
      EXPORTING
        it_filter         = build_mrpset_filter( it_disposets )
        iv_entityset_name = materials_entity_names-material_mrpsets_set
      CHANGING
        ct_data           = et_mrpset_data ).
  ENDMETHOD.


  METHOD read_material_entityset_srv.
    TRY.
        DATA(lo_service_handler) = NEW /lht/cl_odata_service_handler(
                                     iv_btp_destination_name = 'X04_PLACO'
                                     iv_comm_arrangement     = abap_false
                                     is_proxy_model_key      = VALUE #(
                                       repository_id       = materials_proxy_key-repository_id
                                       proxy_model_id      = materials_proxy_key-proxy_model_id
                                       proxy_model_version = materials_proxy_key-proxy_model_version )
                                     iv_service_root         = materials_service_root
                                     iv_authn_mode           = if_a4c_cp_service=>service_specific ).

        lo_service_handler->create_read_request( iv_entity_set_name = iv_entityset_name
                                                 it_r_filters       = it_filter
                                                 it_propertys       = it_selected_properties ).

        lo_service_handler->execute_read_request( CHANGING ct_response_data = ct_data ).

        lo_service_handler->close( ).
      CATCH /lht/cx_odata_exception.
        IF lo_service_handler IS BOUND.
          lo_service_handler->close( ).
        ENDIF.

        RAISE EXCEPTION NEW /lht/cx_placo_check( iv_error_message = getCorrespondingErrorMessage( iv_entityset_name ) ).
    ENDTRY.
  ENDMETHOD.


  METHOD read_material_entity_srv.
    TRY.
        DATA(lo_service_handler) = NEW /lht/cl_odata_service_handler(
                                     iv_btp_destination_name = 'X04_PLACO'
                                     iv_comm_arrangement     = abap_false
                                     is_proxy_model_key      = VALUE #(
                                       repository_id       = materials_proxy_key-repository_id
                                       proxy_model_id      = materials_proxy_key-proxy_model_id
                                       proxy_model_version = materials_proxy_key-proxy_model_version )
                                     iv_service_root         = materials_service_root
                                     iv_authn_mode           = if_a4c_cp_service=>service_specific ).

        lo_service_handler->create_read_request_single(
          EXPORTING
            iv_entity_set_name = iv_entityset_name
            is_key             = is_key
         CHANGING
           cs_entity          = cs_data ).

        lo_service_handler->close( ).
      CATCH /lht/cx_odata_exception.
        RAISE EXCEPTION NEW /lht/cx_placo_check( iv_error_message = getCorrespondingErrorMessage( iv_entityset_name ) ).
    ENDTRY.
  ENDMETHOD.


  METHOD read_material_longtext.
    read_mat_longtext_data_set(
      EXPORTING
        iv_materialnumber = iv_materialnumber
      IMPORTING
        et_mat_longtext   = et_material_longtext ).
  ENDMETHOD.


  METHOD read_material_longtext_srv.
    DATA: lo_http_client        TYPE REF TO if_web_http_client,
          lo_client_proxy       TYPE REF TO /iwbep/if_cp_client_proxy,
          lo_read_list_response TYPE REF TO /iwbep/if_cp_response_read_lst,
          lo_read_response      TYPE REF TO /iwbep/if_cp_response_read,
          ls_response           TYPE /lht/placo_material_x04.

    TYPES: BEGIN OF ls_key,
             material_number TYPE /lht/placo_mat_number,
           END OF ls_key.

    TRY.
        " Create http client
        lo_http_client = cl_web_http_client_manager=>create_by_http_destination(
                         cl_http_destination_provider=>create_by_cloud_destination( i_name = 'X04_PLACO'
                                                                                    i_authn_mode =  if_a4c_cp_service=>service_specific ) ).

        lo_client_proxy = /iwbep/cl_cp_factory_remote=>create_v2_remote_proxy(
          EXPORTING
            is_proxy_model_key       = VALUE #( repository_id       = materials_proxy_key-repository_id
                                                proxy_model_id      = materials_proxy_key-proxy_model_id
                                                proxy_model_version = materials_proxy_key-proxy_model_version )
            io_http_client           = lo_http_client
            iv_relative_service_root = materials_service_root ).

        DATA(lo_resource_entity_nav) = lo_client_proxy->create_resource_for_entity_set( 'MATERIAL_DATA_SET' )->navigate_with_key( VALUE ls_key( material_number = iv_mat_number ) ).
        DATA(lo_read_request_expand) = lo_resource_entity_nav->create_request_for_read( ).

        DATA(lo_root) = lo_read_request_expand->create_expand_node( ).
        lo_root->add_expand( CONV #( iv_entityset_name ) ).

        lo_read_response = lo_read_request_expand->execute( ).
        lo_read_response->get_business_data( IMPORTING es_business_data = ls_response ).

        et_mat_longtext = ls_response-material_longtext_set.
      CATCH cx_root INTO DATA(lx_error).
    ENDTRY.
  ENDMETHOD.


  METHOD read_material_mat_data.
    DATA ls_material_data TYPE /lht/cm_lo_mm_materials_srv=>tys_material_data.

    IF lines( it_materialnumber ) > 1.
      read_material_mat_data_set(
        EXPORTING
          it_materialnumber = it_materialnumber
        CHANGING
          ct_material_data  = et_material_data ).
    ELSE.
      read_material_mat_data_entity(
        EXPORTING
          iv_materialnumber = it_materialnumber[ 1 ]
        CHANGING
          cs_material_data  = ls_material_data ).
      APPEND ls_material_data TO et_material_data.
    ENDIF.
  ENDMETHOD.


  METHOD read_material_mat_data_entity.
    DATA ls_material_data_key TYPE materials_entity_types-material_data.

    ls_material_data_key = VALUE #( material_number = iv_materialnumber ).

    read_material_entity_srv(
      EXPORTING
        iv_entityset_name = materials_entity_names-material_data_set
        is_key            = ls_material_data_key
      CHANGING
        cs_data           = cs_material_data ).
  ENDMETHOD.


  METHOD read_material_mat_data_set.
    read_material_entityset_srv(
      EXPORTING
        iv_entityset_name = materials_entity_names-material_data_set
        it_filter         = build_mat_filter( it_materialnumber )
      CHANGING
        ct_data           = ct_material_data ).
  ENDMETHOD.


  METHOD read_material_mat_desc.
    DATA ls_mat_desc_data TYPE /lht/cm_lo_mm_materials_srv=>tys_material_descriptions.

    IF lines( it_materialnumber ) > 1.
      read_material_mat_desc_set(
        EXPORTING
          iv_language_key   = iv_language_key
          it_materialnumber = it_materialnumber
        CHANGING
          ct_mat_desc_data  = et_mat_desc_data ).
    ELSE.
      read_material_mat_desc_entity(
        EXPORTING
          iv_language_key   = iv_language_key
          iv_materialnumber = it_materialnumber[ 1 ]
        CHANGING
          cs_mat_desc_data  = ls_mat_desc_data ).

      APPEND ls_mat_desc_data TO et_mat_desc_data.
    ENDIF.
  ENDMETHOD.


  METHOD read_material_mat_desc_entity.
    DATA ls_mat_desc_key TYPE materials_entity_types-material_descriptions.

    ls_mat_desc_key = VALUE #( material_number = iv_materialnumber
                               language_key    = iv_language_key ).

    read_material_entity_srv(
      EXPORTING
        iv_entityset_name = materials_entity_names-material_descriptions_set
        is_key            = ls_mat_desc_key
      CHANGING
        cs_data           = cs_mat_desc_data ).
  ENDMETHOD.


  METHOD read_material_mat_desc_set.
    read_material_entityset_srv(
      EXPORTING
        it_filter         = build_mat_desc_filter( it_material = it_materialnumber
                                                   iv_language = iv_language_key )
        iv_entityset_name = materials_entity_names-material_descriptions_set
      CHANGING
        ct_data           = ct_mat_desc_data ).
  ENDMETHOD.


  METHOD read_material_mat_valuations.
    read_material_mat_valuatio_set(
      EXPORTING
        it_materialnumber      = it_materialnumber
      CHANGING
        ct_mat_valuations_data = et_mat_valuations_data ).
  ENDMETHOD.


  METHOD read_material_mat_valuatio_set.
    read_material_entityset_srv(
      EXPORTING
        it_filter         = build_mat_filter( it_materialnumber )
        iv_entityset_name = materials_entity_names-material_valuations_set
      CHANGING
        ct_data           = ct_mat_valuations_data ).
  ENDMETHOD.


  METHOD read_material_mrpset.
    read_material_mrpset_set(
      EXPORTING
        it_materialnumber = it_materialnumber
      IMPORTING
        et_mrpset_data    = et_mrpset_data ).
  ENDMETHOD.


  METHOD read_material_mrpset_entity.
    DATA ls_mrpset_data_key TYPE materials_entity_types-material_mrpsets.

    ls_mrpset_data_key = VALUE #( material_number = iv_materialnumber ).

    read_material_entity_srv(
      EXPORTING
        iv_entityset_name = materials_entity_names-material_mrpsets_set
        is_key            = ls_mrpset_data_key
      CHANGING
        cs_data           = cs_mrpset_data ).
  ENDMETHOD.


  METHOD read_material_mrpset_set.
    read_material_entityset_srv(
      EXPORTING
        it_filter         = build_mat_filter( it_materialnumber )
        iv_entityset_name = materials_entity_names-material_mrpsets_set
      CHANGING
        ct_data           = et_mrpset_data ).
  ENDMETHOD.


  METHOD read_material_psg.
    DATA(lt_filter) = build_psg_filter( ).

    DATA(lt_material_data) = VALUE /lht/cm_lo_mm_materials_srv=>tyt_material_data( ).

    LOOP AT lt_filter REFERENCE INTO DATA(ls_filter).
      WAIT UP TO 3 SECONDS. " don't delete, otherwise X04 will crash ... sometimes!
      read_material_entityset_srv(
        EXPORTING
          iv_entityset_name      = materials_entity_names-material_data_set
          it_selected_properties = VALUE #( ( `MATERIAL_NUMBER` )
                                            ( `DELETED_FLAG` ) )
          it_filter              = VALUE #( ( ls_filter->* )
                                            ( name  = 'DELETED_FLAG'
                                              range = VALUE #( ( low    = abap_false
                                                                 option = |EQ|
                                                                 sign   = |I| ) ) )                                                 )
        CHANGING
          ct_data                = lt_material_data ).

      INSERT LINES OF lt_material_data INTO TABLE rt_material_data.
    ENDLOOP.
  ENDMETHOD.


  METHOD read_material_valuations.
    read_material_valuations_set(
      EXPORTING
        it_materialnumber           = it_materialnumber
      CHANGING
        ct_material_valuations_data = et_material_valuations_data ).
  ENDMETHOD.


  METHOD read_material_valuations_set.
    read_material_entityset_srv(
      EXPORTING
        it_filter         = build_valuations_filter( it_materialnumber )
        iv_entityset_name = materials_entity_names-material_valuations_set
      CHANGING
        ct_data           = ct_material_valuations_data ).
  ENDMETHOD.


  METHOD read_mat_interchangeabilities.
    read_material_entityset_srv(
      EXPORTING
        iv_entityset_name = materials_entity_names-material_interchangeabili_set
        it_filter         = build_mat_filter( it_materialnumber )
      CHANGING
        ct_data           = et_mat_inter_data ).
  ENDMETHOD.


  METHOD read_mat_longtext_data_set.
    read_material_longtext_srv(
      EXPORTING
        iv_mat_number     = iv_materialnumber
        iv_entityset_name = materials_entity_names-material_longtext_set
      IMPORTING
        et_mat_longtext   = et_mat_longtext ).
  ENDMETHOD.


  METHOD read_mat_restricted_inter.
    read_material_entityset_srv(
      EXPORTING
        iv_entityset_name = materials_entity_names-material_rest_interchange_set
        it_filter         = build_mat_filter( it_materialnumber )
      CHANGING
        ct_data           = et_mat_rest_inter_data ).
  ENDMETHOD.


  METHOD read_mrpset_materials.
    read_material_entityset_srv(
      EXPORTING
        it_filter         = build_mrpset_filter( it_disposets )
        iv_entityset_name = materials_entity_names-material_mrpsets_set
      CHANGING
        ct_data           = rt_materials ).
  ENDMETHOD.


  METHOD read_open_po_data.
    read_open_po_data_set(
      EXPORTING
        it_purchase_orders = it_purchase_orders
      CHANGING
        ct_po_data        = et_po_data ).
  ENDMETHOD.


  METHOD read_open_po_data_set.
    DATA lt_selected_properties TYPE /iwbep/if_cp_runtime_types=>ty_t_property_path.

    APPEND 'PURCHASE_ORDER' TO lt_selected_properties.

    DATA(lv_po_filter) = build_po_filter( it_purchase_orders ).

    read_po_entityset_srv(
      EXPORTING
        it_filter              = lv_po_filter
        iv_entityset_name      = po_entity_names-purchaseorders
        it_selected_properties = lt_selected_properties
      CHANGING
        ct_data                = ct_po_data ).
  ENDMETHOD.


  METHOD read_placo_dailyConsumption.
    TRY.
        read_placo_dailyConsumptio_set(
          EXPORTING
            it_materialnumber         = it_materialnumber
            it_material_doc           = it_material_doc
            it_movement_type          = it_movement_type
          CHANGING
            ct_daily_consumption_data = et_dailyconsumption_data ).
      CATCH /lht/cx_placo_check INTO DATA(cx_placo).
        RAISE EXCEPTION NEW /lht/cx_placo_check( io_previous = cx_placo ).
    ENDTRY.
  ENDMETHOD.


  METHOD read_placo_dailyConsumptio_set.
    TRY.
        read_placo_entityset_srv(
          EXPORTING
            it_filter         = build_dailyconsumptio_filter( it_material      = it_materialnumber
                                                              it_material_doc  = it_material_doc
                                                              it_movement_type = it_movement_type  )
            iv_entityset_name = placo_entity_names-daily_consumption
          CHANGING
            ct_data           = ct_daily_consumption_data ).
      CATCH /lht/cx_placo_check INTO DATA(cx_placo).
        RAISE EXCEPTION NEW /lht/cx_placo_check( io_previous = cx_placo ).
    ENDTRY.
  ENDMETHOD.


  METHOD read_placo_entityset_srv.
    TRY.
        DATA(lo_service_handler) = NEW /lht/cl_odata_service_handler(
                                           iv_btp_destination_name = 'X04_PLACO'
                                           iv_comm_arrangement     = abap_false
                                           is_proxy_model_key      = VALUE #(
                                               repository_id       = placo_proxy_key-repository_id
                                               proxy_model_id      = placo_proxy_key-proxy_model_id
                                               proxy_model_version = placo_proxy_key-proxy_model_version )
                                           iv_service_root         = placo_service_root
                                           iv_authn_mode           = if_a4c_cp_service=>service_specific  ).

        lo_service_handler->create_read_request( iv_entity_set_name = iv_entityset_name
                                                 it_r_filters       = it_filter
                                                 it_propertys       = it_selected_properties ).

        lo_service_handler->execute_read_request( CHANGING ct_response_data = ct_data ).

        lo_service_handler->close( ).
      CATCH /lht/cx_odata_exception.
        RAISE EXCEPTION NEW /lht/cx_placo_check( iv_error_message = getCorrespondingErrorMessage( iv_entityset_name ) ).
    ENDTRY.
  ENDMETHOD.


  METHOD read_placo_zmmclass.
    TRY.
        read_placo_zmmclass_set(
          EXPORTING
            it_materialnumber = it_materialnumber
          CHANGING
            ct_zmmclass_data  = et_zmmclass_data ).
      CATCH /lht/cx_placo_check INTO DATA(cx_placo).
        RAISE EXCEPTION NEW /lht/cx_placo_check( io_previous = cx_placo ).
    ENDTRY.
  ENDMETHOD.


  METHOD read_placo_zmmclass_set.
    TRY.
        read_placo_entityset_srv(
          EXPORTING
            it_filter         = build_zmmclass_filter( it_materialnumber )
            iv_entityset_name = placo_entity_names-zmmclass_worklist
          CHANGING
            ct_data           = ct_zmmclass_data ).
      CATCH /lht/cx_placo_check INTO DATA(cx_placo).
        RAISE EXCEPTION NEW /lht/cx_placo_check( io_previous = cx_placo ).
    ENDTRY.
  ENDMETHOD.


  METHOD read_po_entityset_srv.
    TRY.
        DATA(lo_service_handler) = NEW /lht/cl_odata_service_handler(
                                           iv_btp_destination_name = 'X04_PLACO'
                                           iv_comm_arrangement     = abap_false
                                           is_proxy_model_key      = VALUE #(
                                               repository_id       = po_proxy_key-repository_id
                                               proxy_model_id      = po_proxy_key-proxy_model_id
                                               proxy_model_version = po_proxy_key-proxy_model_version )
                                           iv_service_root         = po_service_root
                                           iv_authn_mode           = if_a4c_cp_service=>service_specific ).

        lo_service_handler->create_read_request( iv_entity_set_name = iv_entityset_name
                                                 it_r_filters       = it_filter
                                                 it_propertys       = it_selected_properties ).

        lo_service_handler->execute_read_request( CHANGING ct_response_data = ct_data ).

        lo_service_handler->close( ).
      CATCH /lht/cx_odata_exception.
        RAISE EXCEPTION NEW /lht/cx_placo_check( iv_error_message = getCorrespondingErrorMessage( iv_entityset_name ) ).
    ENDTRY.
  ENDMETHOD.


  METHOD read_po_item_data.
    IF it_purch_order IS NOT INITIAL.
      read_po_item_data_set(
        EXPORTING
          it_purch_order = it_purch_order
        CHANGING
          ct_po_data     = et_po_data ).
    ENDIF.

    IF it_materialnumber IS NOT INITIAL.
      read_po_item_data_set(
        EXPORTING
          it_materialnumber = it_materialnumber
        CHANGING
          ct_po_data        = et_po_data ).
    ENDIF.
  ENDMETHOD.


  METHOD read_po_item_data_set.
    DATA lt_selected_properties TYPE /iwbep/if_cp_runtime_types=>ty_t_property_path.

    IF it_purch_order IS NOT INITIAL.
      APPEND 'MATERIAL' TO lt_selected_properties.

      read_po_entityset_srv(
        EXPORTING
          it_filter              = build_ebeln_filter( it_purch_order )
          iv_entityset_name      = po_entity_names-purchaseorderitems
          it_selected_properties = lt_selected_properties
        CHANGING
          ct_data                = ct_po_data ).
    ENDIF.

    IF it_materialnumber IS NOT INITIAL.
      APPEND 'PURCHASE_ORDER'             TO lt_selected_properties.
      APPEND 'DELIVERY_COMPLETED_INDICAT' TO lt_selected_properties.
      APPEND 'DELETION_INDICATOR'         TO lt_selected_properties.
      APPEND 'MATERIAL'                   TO lt_selected_properties.
      APPEND 'ORDER_QUANTITY'             TO lt_selected_properties.
      APPEND 'ITEM_IS_STATISTICAL'        TO lt_selected_properties.
      APPEND 'LAST_CHANGED_ON'            TO lt_selected_properties.

      read_po_entityset_srv(
        EXPORTING
          it_filter              = build_po_mat_filter( it_materialnumber )
          iv_entityset_name      = po_entity_names-purchaseorderitems
          it_selected_properties = lt_selected_properties
        CHANGING
          ct_data                = ct_po_data ).
    ENDIF.
  ENDMETHOD.


  METHOD read_pr_entityset_srv.
    TRY.
        DATA(lo_service_handler) = NEW /lht/cl_odata_service_handler(
                                     iv_btp_destination_name = 'X04_PLACO'
                                     iv_comm_arrangement     = abap_false
                                     is_proxy_model_key      = VALUE #(
                                       repository_id       = pr_proxy_key-repository_id
                                       proxy_model_id      = pr_proxy_key-proxy_model_id
                                       proxy_model_version = pr_proxy_key-proxy_model_version )
                                     iv_service_root         = pr_service_root
                                     iv_authn_mode           = if_a4c_cp_service=>service_specific ).

        lo_service_handler->create_read_request( iv_entity_set_name = iv_entityset_name
                                                 it_r_filters       = it_filter
                                                 it_propertys       = it_selected_properties ).

        lo_service_handler->execute_read_request( CHANGING ct_response_data = ct_data ).

        lo_service_handler->close( ).
      CATCH /lht/cx_odata_exception.
        RAISE EXCEPTION NEW /lht/cx_placo_check( iv_error_message = getCorrespondingErrorMessage( iv_entityset_name ) ).
    ENDTRY.
  ENDMETHOD.


  METHOD read_pr_item_data.
    IF it_purch_req IS NOT INITIAL.
      read_pr_item_data_set(
        EXPORTING
          it_purch_req = it_purch_req
        CHANGING
          ct_pr_data   = et_pr_data ).
    ENDIF.

    IF it_materialnumber IS NOT INITIAL.
      read_pr_item_data_set(
        EXPORTING
          it_materialnumber = it_materialnumber
        CHANGING
          ct_pr_data        = et_pr_data ).
    ENDIF.
  ENDMETHOD.


  METHOD read_pr_item_data_set.
    DATA lt_selected_properties TYPE /iwbep/if_cp_runtime_types=>ty_t_property_path.

    IF it_purch_req IS NOT INITIAL.
      APPEND 'PURCHASE_REQUISITION' TO lt_selected_properties.
      APPEND 'MATERIAL'             TO lt_selected_properties.

      read_pr_entityset_srv(
        EXPORTING
          it_filter              = build_pr_filter( it_purch_req )
          iv_entityset_name      = pr_entity_names-purchase_requisition_items
          it_selected_properties = lt_selected_properties
        CHANGING
          ct_data                = ct_pr_data ).
    ENDIF.

    IF it_materialnumber IS NOT INITIAL.
      APPEND 'MATERIAL'          TO lt_selected_properties.
      APPEND 'PROCESSING_STATUS' TO lt_selected_properties.
      APPEND 'QUANTITY'          TO lt_selected_properties.
      APPEND 'CHANGED_ON'        TO lt_selected_properties.
      APPEND 'PURCHASING_GROUP'  TO lt_selected_properties.

      read_pr_entityset_srv(
        EXPORTING
          it_filter              = build_pr_mat_filter( it_materialnumber )
          iv_entityset_name      = pr_entity_names-purchase_requisition_items
          it_selected_properties = lt_selected_properties
        CHANGING
          ct_data                = ct_pr_data ).
    ENDIF.
  ENDMETHOD.


  METHOD read_relevant_material_matdata.
    " Get only not deleted mats
    read_material_entityset_srv(
      EXPORTING
        iv_entityset_name = materials_entity_names-material_data_set
        it_filter         = it_filters
      CHANGING
        ct_data           = et_material_data ).

  ENDMETHOD.


  METHOD read_stock_entityset_srv.
    TRY.
        DATA(lo_service_handler) = NEW /lht/cl_odata_service_handler(
                                     iv_btp_destination_name = 'X04_PLACO'
                                     iv_comm_arrangement     = abap_false
                                     is_proxy_model_key      = VALUE #(
                                       repository_id       = stock_proxy_key-repository_id
                                       proxy_model_id      = stock_proxy_key-proxy_model_id
                                       proxy_model_version = stock_proxy_key-proxy_model_version )
                                     iv_service_root         = stock_service_root
                                     iv_authn_mode           = if_a4c_cp_service=>service_specific ).
        lo_service_handler->create_read_request( iv_entity_set_name = iv_entityset_name
                                                 it_r_filters       = it_filter
                                                 it_propertys       = it_selected_properties ).

        lo_service_handler->execute_read_request( CHANGING ct_response_data = ct_data ).

        lo_service_handler->close( ).
      CATCH /lht/cx_odata_exception.
        RAISE EXCEPTION NEW /lht/cx_placo_check( iv_error_message = getCorrespondingErrorMessage( iv_entityset_name ) ).
    ENDTRY.
  ENDMETHOD.


  METHOD read_stock_mat_stock.
    read_stock_mat_stock_set(
      EXPORTING
        it_materialnumber = it_materialnumber
      CHANGING
        ct_mat_stock_data = et_mat_stock_data ).
  ENDMETHOD.


  METHOD read_stock_mat_stock_set.
    DATA lt_selected_properties TYPE /iwbep/if_cp_runtime_types=>ty_t_property_path.

    APPEND 'PLANT'                      TO lt_selected_properties.
    APPEND 'VALUATED_UNRESTRICTED_USES' TO lt_selected_properties.
    APPEND 'STORLOCATION_MRPINDICATOR'  TO lt_selected_properties.

    read_stock_entityset_srv(
      EXPORTING
        it_filter              = build_mat_filter( it_materialnumber )
        iv_entityset_name      = stock_entity_names-material_stock
        it_selected_properties = lt_selected_properties
      CHANGING
        ct_data                = ct_mat_stock_data ).
  ENDMETHOD.


  METHOD read_vk13_entityset_srv.
    TRY.
        DATA(lo_service_handler) = NEW /lht/cl_odata_service_handler(
                                     iv_btp_destination_name = 'X04_PLACO'
                                     iv_comm_arrangement     = abap_false
                                     is_proxy_model_key      = VALUE #(
                                        repository_id       = vk13_proxy_key-repository_id
                                        proxy_model_id      = vk13_proxy_key-proxy_model_id
                                        proxy_model_version = vk13_proxy_key-proxy_model_version )
                                     iv_service_root         = vk13_service_root
                                     iv_authn_mode           = if_a4c_cp_service=>service_specific ).

        lo_service_handler->create_read_request( iv_entity_set_name = iv_entityset_name
                                                 it_r_filters       = it_filter
                                                 it_propertys       = it_selected_properties ).

        lo_service_handler->execute_read_request( CHANGING ct_response_data = ct_data ).

        lo_service_handler->close( ).
      CATCH /lht/cx_odata_exception.
        RAISE EXCEPTION NEW /lht/cx_placo_check( iv_error_message = getCorrespondingErrorMessage( iv_entityset_name ) ).
    ENDTRY.
  ENDMETHOD.


  METHOD read_vk13_mat_mrpset.
    read_vk13_mat_mrpset_set(
      EXPORTING
        it_materialnumber       = it_materialnumber
      CHANGING
        ct_material_mrpset_data = et_vk13_mat_mrpset_data ).
  ENDMETHOD.


  METHOD read_vk13_mat_mrpset_set.
    read_vk13_entityset_srv(
      EXPORTING
        it_filter         = build_mat_filter( it_materialnumber )
        iv_entityset_name = vk13_entity_names-material_price
      CHANGING
        ct_data           = ct_material_mrpset_data ).
  ENDMETHOD.


  METHOD build_pr_mat_filter.
    rt_filter = VALUE #( FOR material IN it_materialnumber
                         ( name  = 'MATERIAL'
                           range = VALUE #( ( low    = material
                                              option = |EQ|
                                              sign   = |I| ) ) ) ).
  ENDMETHOD.


  METHOD convertMaterialForPrPost.
    rt_mapped_purchase_requisition = VALUE #(
        pr_header_nav     = VALUE #( (  pr_type = is_purchase_requisition-order_type ) )
        prheader_x_nav    = VALUE #( ( pr_type = `X` ) )
        pritem_nav        = VALUE #(
          ( preq_item         = `00001`
            material_external = is_purchase_requisition-material
            plant             = is_purchase_requisition-plant
            store_loc         = is_purchase_requisition-storage_location
            pur_group         = is_purchase_requisition-purchasing_group
            quantity          = is_purchase_requisition-quantity
            des_vendor        = is_purchase_requisition-desired_vendor
            val_type          = is_purchase_requisition-valuation_type
            del_datcat_ext    = `T`
            deliv_date        = is_purchase_requisition-delivery_date
            purch_org         = `0001`
            trackingno        = is_purchase_requisition-request_nr ) )
        pritem_x_nav      = VALUE #( ( preq_item         = `00001`
                                       material_external = `X`
                                       plant             = `X`
                                       store_loc         = `X`
                                       pur_group         = `X`
                                       quantity          = `X`
                                       des_vendor        = `X`
                                       val_type          = `X`
                                       del_datcat_ext    = `X`
                                       deliv_date        = `X`
                                       purch_org         = `X`
                                       trackingno        = `X` ) )
         pritem_text_nav = VALUE #( ( preq_item = `00001`
                                      text      = is_purchase_requisition-position_text
                                      text_id   = 'B02' ) ) ).
  ENDMETHOD.


  METHOD create_purchase_requisition.
    TRY.
        DATA(lo_service_handler) = NEW /lht/cl_odata_service_handler(
            iv_btp_destination_name = communication-scenario
            iv_service_id           = communication-service
            iv_comm_arrangement     = abap_true
            is_proxy_model_key      = VALUE #(
              repository_id       = post_pr_proxy_key-repository_id
              proxy_model_id      = post_pr_proxy_key-proxy_model_id
              proxy_model_version = post_pr_proxy_key-proxy_model_version )
            iv_service_root         = post_pr_service_root ).
      CATCH /lht/cx_odata_exception.
*        RAISE EXCEPTION NEW /lht/cx_placo_check( iv_error_message = getCorrespondingErrorMessage( iv_entityset_name ) ).
    ENDTRY.

    lo_service_handler->create_post_request( post_pr_entity_names-purchase_requisition_set ).

    TRY.
        lo_service_handler->set_deep_entity(
          is_deep_entity       = convertMaterialForPRPost( is_purchase_requisition )
          it_child_navigations = setPRNavigationForPRPost( ) ).
      CATCH /lht/cx_odata_exception INTO DATA(lcx_interface_exc). " TODO: variable is assigned but never used (ABAP cleaner)
    ENDTRY.

    TRY.
        DATA(lo_response) = lo_service_handler->execute_post_request( ).
        TRY.
            IF lo_response IS INITIAL.
              RETURN.
              lo_response->get_business_data(
                IMPORTING
                  es_business_data = rt_mapped_purchase_requisition ).
            ENDIF.
          CATCH /iwbep/cx_gateway.
            " handle exception
        ENDTRY.
      CATCH /lht/cx_odata_exception INTO lcx_interface_exc.
    ENDTRY.
  ENDMETHOD.


  METHOD read_material_storage_location.
    read_material_stor_loc_set(
      EXPORTING
        it_materialnumber = it_materialnumber
      CHANGING
        ct_material_data  = et_material_data ).
  ENDMETHOD.


  METHOD read_material_stor_loc_set.
    read_material_entityset_srv(
      EXPORTING
        iv_entityset_name = materials_entity_names-material_storagelocations_set
        it_filter         = build_mat_filter( it_materialnumber )
      CHANGING
        ct_data           = ct_material_data ).
  ENDMETHOD.


  METHOD setPrNavigationForPrPost.
    DATA(ls_nav) = /lht/lo_me_pr_srv=>gcs_entity_type-purchase_requisition-navigation.

    APPEND ls_nav-praccount_nav TO rt_navigation.
    APPEND ls_nav-praccount_x_nav TO rt_navigation.
    APPEND ls_nav-praddr_del_nav TO rt_navigation.
    APPEND ls_nav-prheader_text_nav TO rt_navigation.
    APPEND ls_nav-prheader_x_nav TO rt_navigation.
    APPEND ls_nav-pritem_cust_nav TO rt_navigation.
    APPEND ls_nav-pritem_cust_x_nav TO rt_navigation.
    APPEND ls_nav-pritem_nav TO rt_navigation.
    APPEND ls_nav-pritem_text_nav TO rt_navigation.
    APPEND ls_nav-pritem_x_nav TO rt_navigation.
    APPEND ls_nav-pr_header_nav TO rt_navigation.
  ENDMETHOD.


  METHOD read_vendors_data.
    read_vendors_data_set(
      CHANGING
        ct_vendor_data  = et_vendor_data ).
  ENDMETHOD.


  METHOD read_vendors_data_set.
     read_vendor_entityset_srv(
      EXPORTING
        iv_entityset_name = 'VENDORS_SET'
      CHANGING
        ct_data           = ct_vendor_data ).
  ENDMETHOD.


  METHOD read_vendor_entityset_srv.
    TRY.
        DATA(lo_service_handler) = NEW /lht/cl_odata_service_handler(
                                     iv_btp_destination_name = 'X04_PLACO'
                                     iv_comm_arrangement     = abap_false
                                     is_proxy_model_key      = VALUE #(
                                       repository_id       = vendor_proxy_key-repository_id
                                       proxy_model_id      = vendor_proxy_key-proxy_model_id
                                       proxy_model_version = vendor_proxy_key-proxy_model_version )
                                     iv_service_root         = vendor_service-service_root
                                     iv_authn_mode           = if_a4c_cp_service=>service_specific ).

        lo_service_handler->create_read_request( iv_entity_set_name = iv_entityset_name
                                                 it_r_filters       = it_filter
                                                 it_propertys       = it_selected_properties ).

        lo_service_handler->execute_read_request( CHANGING ct_response_data = ct_data ).

        lo_service_handler->close( ).
      CATCH /lht/cx_odata_exception.
        RAISE EXCEPTION NEW /lht/cx_placo_check( iv_error_message = getCorrespondingErrorMessage( iv_entityset_name ) ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.