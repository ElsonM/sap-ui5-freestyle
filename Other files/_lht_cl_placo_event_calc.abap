"! <p class="shorttext synchronized" lang="en">Event Calculations</p>
CLASS /lht/cl_placo_event_calc DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES /lht/lo_mb_stock_i.

    TYPES gty_t_material_stock TYPE TABLE OF /lht/lo_mb_stock_i~entity_types-material_stock.
    TYPES gty_packed_number    TYPE p LENGTH 15 DECIMALS 4.
    TYPES: BEGIN OF gty_s_daily_consumption,
             day         TYPE int4,
             consumption TYPE gty_packed_number,
           END OF gty_s_daily_consumption.
    TYPES gty_t_daily_consumption TYPE TABLE OF gty_s_daily_consumption WITH DEFAULT KEY.

    TYPES: BEGIN OF ENUM gty_type_of_reorder_level,
             forecast VALUE IS INITIAL,
             historic VALUE 001,
           END OF ENUM gty_type_of_reorder_level.

    "! <p class="shorttext synchronized"></p>
    "! Calculates the sum of all materials with StorageLocationMRPIndicator '2'
    "! from the imported materials.<br/>
    "! Material stock is based on the type <em> tys_material_stock</em> from {@link /lht/lo_mb_stock_srv}.
    "!
    "! @parameter it_material_stock | Imported material stock based on <p class="shorttext synchronized"></p>
    "! @parameter rv_stock_level    | Returned stock level<p class="shorttext synchronized"></p>
    CLASS-METHODS calculaterelevantstocklevel
      IMPORTING it_material_stock     TYPE gty_t_material_stock
      RETURNING VALUE(rv_stock_level) TYPE /lht/placo_material_stock
      RAISING   /lht/cx_placo_check.

    "! <p class="shorttext synchronized"></p>
    "! This method calculates the optimal order quantity based on the given input parameters.
    "!
    "! @parameter iv_annual_consumption       | Annual consumption of the item.<p class="shorttext synchronized"></p>
    "! @parameter iv_order_costs              | Cost associated with placing an order.<p class="shorttext synchronized"></p>
    "! @parameter iv_stock_cost_rate          | Cost rate of the item stock.<p class="shorttext synchronized"></p>
    "! @parameter iv_moving_average_price     | Moving average price of the item.<p class="shorttext synchronized"></p>
    "! @parameter rv_suggestion_opt_order_qty | Optimal order quantity suggested by the calculation.<p class="shorttext synchronized"></p>
    CLASS-METHODS calculateSuggestionOptOrdQty
      IMPORTING iv_annual_consumption              TYPE gty_packed_number
                iv_order_costs                     TYPE gty_packed_number
                iv_stock_cost_rate                 TYPE gty_packed_number
                iv_moving_average_price            TYPE gty_packed_number
                iv_forecast_consumption            TYPE gty_packed_number
      RETURNING VALUE(rv_suggestion_opt_order_qty) TYPE int4
      RAISING   /lht/cx_placo_check.

    "! <p class="shorttext synchronized"></p>
    "! This method returns the stock reach based on the forecasted or annual consumption rate.
    "! The calculation considers the relevant stock level and the number of inflowing materials.
    "! @parameter iv_relevant_stock_level    | The relevant stock level to be considered.<p class="shorttext synchronized"></p>
    "! @parameter iv_forecasted_consumption  | OPTIONAL: The forecasted consumption. If provided, it will be used instead of the annual consumption rate. <p class="shorttext synchronized"></p>
    "! @parameter iv_annual_consumption      | The annual consumption.<p class="shorttext synchronized"></p>
    "! @parameter iv_number_of_inflowing_mat | The number of inflowing materials to be considered.<p class="shorttext synchronized"></p>
    "! @parameter rv_stock_reach             | The calculated stock reach, representing the number of days the stock can sustain the consumption. <p class="shorttext synchronized"></p>
    CLASS-METHODS calculateStockReachOpenPOs
      IMPORTING iv_relevant_stock_level    TYPE /lht/placo_material_stock
                iv_forecasted_consumption  TYPE int4 OPTIONAL
                iv_annual_consumption      TYPE gty_packed_number
                iv_number_of_inflowing_mat TYPE int4
      RETURNING VALUE(rv_stock_reach)      TYPE gty_packed_number
      RAISING   /lht/cx_placo_check.

    "! <p class="shorttext synchronized"></p>
    "! This method returns the stock reach based on the forecasted or annual consumption rate.
    "! The calculation considers the relevant stock level.
    "! @parameter iv_relevant_stock_level   | The relevant stock level to be considered.<p class="shorttext synchronized"></p>
    "! @parameter iv_forecasted_consumption | OPTIONAL: The forecasted consumption. If provided, it will be used instead of the annual consumption rate. <p class="shorttext synchronized"></p>
    "! @parameter iv_annual_consumption     | The annual consumption.<p class="shorttext synchronized"></p>
    "! @parameter rv_stock_reach            | The calculated stock reach, representing the number of days the stock can sustain the consumption.<p class="shorttext synchronized"></p>
    CLASS-METHODS calculateStockReachNoOpenPOs
      IMPORTING iv_relevant_stock_level   TYPE /lht/placo_material_stock
                iv_forecasted_consumption TYPE int4 OPTIONAL
                iv_annual_consumption     TYPE gty_packed_number
      RETURNING VALUE(rv_stock_reach)     TYPE gty_packed_number
      RAISING   /lht/cx_placo_check.

    "! <p class="shorttext synchronized"></p>
    "! This method returns the reorderr level based on daily consumption data, the replenishment time and safety stock.<br/>
    "! This is achieved by first calculating the consumption during the replenishment period, then determining the maximum consumption from all consumptions,
    "! and finally the maximum consumption is added to the safety stock.
    "! @parameter iv_replenishment_time | An integer representing the replenishment time, i.e., the time taken to replenish the stock. <p class="shorttext synchronized"></p>
    "! @parameter it_daily_consumption  | Input table containing daily consumption data. <p class="shorttext synchronized"></p>
    "! @parameter rv_reorder_level      | The calculated reorder level, which is the threshold indicating when new stock should be ordered to avoid stockouts. <p class="shorttext synchronized"></p>
    CLASS-METHODS calculateSuggestionReorderLvl
      IMPORTING iv_replenishment_time   TYPE /lht/placo_replenishment_time
                iv_type_of_reorder_lvl  TYPE gty_type_of_reorder_level OPTIONAL
                it_daily_consumption    TYPE gty_t_daily_consumption
      RETURNING VALUE(rv_reorder_level) TYPE gty_packed_number
      RAISING   /lht/cx_placo_check.

    CLASS-METHODS calculateRecReleaseQuantity
      IMPORTING iv_forecast                    TYPE int4
                iv_consumption_last_two_year   TYPE gty_packed_number
                iv_relevant_stock              TYPE /lht/placo_material_stock
      RETURNING VALUE(rv_rec_release_quantity) TYPE int4
      RAISING   /lht/cx_placo_check.

  PRIVATE SECTION.
    TYPES gty_t_replenish_consumption TYPE TABLE OF gty_packed_number WITH DEFAULT KEY.

    "! <p class="shorttext synchronized"></p>
    "! This method calculates the target index based on the current index, the replenishment time
    "! and the total number of rows in the table.<br/>
    "! If the sum of the current index and the replenishment time exceeds the total number of table lines,
    "! the target index is set to the total number of table lines. <br/>
    "! Otherwise, the target index is set to the sum of the current index and the replenishment time.
    "!
    "! @parameter iv_tabix              | The current index within the table <p class="shorttext synchronized"></p>
    "! @parameter iv_replenishment_time | The replenishment time as an integer. <p class="shorttext synchronized"></p>
    "! @parameter iv_table_lines        | The total number of rows in the table. <p class="shorttext synchronized"></p>
    "! @parameter rv_target_tabix       | The target index within the table, calculated based on the provided logic. <p class="shorttext synchronized"></p>
    CLASS-METHODS checkindexoftargetreplenish
      IMPORTING iv_tabix               TYPE int4
                iv_replenishment_time  TYPE /lht/placo_replenishment_time
                iv_table_lines         TYPE int4
      RETURNING VALUE(rv_target_tabix) TYPE int4
      RAISING
        /lht/cx_placo_check.

    "! <p class="shorttext synchronized"></p>
    "! This method returns the maximum consumption value from an input table.
    "! @parameter it_replenishment_consumption | An internal table containing integer consumption values. <p class="shorttext synchronized"></p>
    "! @parameter rv_max_consumption           | The resulting maximum consumption value from the input table. <p class="shorttext synchronized"></p>
    CLASS-METHODS getmaximumreplenishconsumption
      IMPORTING it_replenishment_consumption TYPE /lht/cl_placo_event_calc=>gty_t_replenish_consumption
      RETURNING VALUE(rv_max_consumption)    TYPE gty_packed_number
      RAISING
        /lht/cx_placo_check.

    "! <p class="shorttext synchronized"></p>
    "! This method returns the sum of all consumption values in the input table.
    "! @parameter it_consumption_values        | Input table containing integer consumption values <p class="shorttext synchronized"></p>
    "! @parameter rv_sum_of_consumption_values | Resulting sum of all the consumption values in the input table<p class="shorttext synchronized"></p>
    CLASS-METHODS getsumofconsumptionvalues
      IMPORTING it_consumption_values               TYPE /lht/cl_placo_event_calc=>gty_t_replenish_consumption
      RETURNING VALUE(rv_sum_of_consumption_values) TYPE gty_packed_number
      RAISING
        /lht/cx_placo_check.

    "! <p class="shorttext synchronized"></p>
    "! This method returns the total consumption values over a given replenishment period for all daily consumption entries.
    "! The method iterates over the input table, calculates the target index for each entry based on the replenishment time,
    "! retrieves the corresponding consumption values and then sums them up.
    "! @parameter it_daily_consumption         | An internal table containing daily consumption data. <p class="shorttext synchronized"></p>
    "! @parameter iv_replenishment_time        | An integer representing the replenishment time, i.e., the time taken to replenish the stock. <p class="shorttext synchronized"></p>
    "! @parameter rt_replenishment_consumption | An internal table that will hold the sums of consumption values over the replenishment periods for each daily consumption entry. <p class="shorttext synchronized"></p>
    CLASS-METHODS calculateconsumptinreplenish
      IMPORTING it_daily_consumption                TYPE gty_t_daily_consumption
                iv_replenishment_time               TYPE /lht/placo_replenishment_time
      RETURNING VALUE(rt_replenishment_consumption) TYPE gty_t_replenish_consumption
      RAISING
        /lht/cx_placo_check.

    "! <p class="shorttext synchronized"></p>
    "! This method populates the returning table with consumption values extracted from the input table for a specified range.<br/>
    "! The range is determined by the current index and the provided index.<br/>
    "!
    "! @parameter it_daily_consumption  | The input table containing daily consumption data.<p class="shorttext synchronized"></p>
    "! @parameter iv_starting_index     | The starting index from which the consumption values will be fetched.<p class="shorttext synchronized"></p>
    "! @parameter iv_target_index       | The end index up to which the consumption values will be fetched from the input table <p class="shorttext synchronized"></p>
    "! @parameter rt_consumption_values | The output table that will hold the replenishment consumption values.<p class="shorttext synchronized"></p>
    CLASS-METHODS getconsumptionvaluesforindex
      IMPORTING it_daily_consumption         TYPE gty_t_daily_consumption
                iv_starting_index            TYPE int4
                iv_target_index              TYPE int4
      RETURNING VALUE(rt_consumption_values) TYPE gty_t_replenish_consumption
      RAISING
        /lht/cx_placo_check.

    "! <p class="shorttext synchronized"></p>
    "! This methods returns the reoder level by summing the maximum consumption value and the safety stock value.
    "! @parameter iv_maximum_consumption | An integer representing the maximum consumption observed or expected during the lead time. <p class="shorttext synchronized"></p>
    "! @parameter rv_reorder_level       | The calculated reorder level, which is the sum of maximum consumption and safety stock. <p class="shorttext synchronized"></p>
    CLASS-METHODS getreorderlevel
      IMPORTING
                iv_maximum_consumption  TYPE gty_packed_number
      RETURNING VALUE(rv_reorder_level) TYPE gty_packed_number
      RAISING
        /lht/cx_placo_check.
    CLASS-METHODS calc_mean_daily_consumption
      IMPORTING
        it_daily_consumption             TYPE /lht/cl_placo_event_calc=>gty_t_daily_consumption
      RETURNING
        value(rv_mean_daily_consumption) TYPE gty_packed_number
      RAISING
        /lht/cx_placo_check.

    " CALCULATED_REPLENISHMENT_TIME.
ENDCLASS.



CLASS /LHT/CL_PLACO_EVENT_CALC IMPLEMENTATION.


  METHOD calculateconsumptinreplenish.
    TRY.
        " TODO: variable is assigned but never used (ABAP cleaner)
        LOOP AT it_daily_consumption REFERENCE INTO DATA(ls_daily_consumption).

          " 1. Calculate the target index for the replenishment period
          DATA(lv_target_tabix) = checkIndexOfTargetReplenish(
              iv_tabix              = sy-tabix
              iv_replenishment_time = iv_replenishment_time
              iv_table_lines        = lines( it_daily_consumption ) ).

          " 2. Retrieve the consumption values for the current index
          DATA(lt_consumption_values) = getConsumptionValuesForIndex(
                                            it_daily_consumption = it_daily_consumption
                                            iv_starting_index    = sy-tabix
                                            iv_target_index      = lv_target_tabix ).

          " 3. Sum the retrieved consumption values
          DATA(lv_sum_of_consumption_values) = getsumofconsumptionvalues(
                                                   lt_consumption_values ).
          " 4. Store the sum of consumption values in the output table
          INSERT lv_sum_of_consumption_values INTO TABLE rt_replenishment_consumption.
        ENDLOOP.
      CATCH /lht/cx_placo_check into data(cx_check).
        RAISE EXCEPTION NEW /lht/cx_placo_check(
            io_previous = cx_check ).
    ENDTRY.
  ENDMETHOD.


  METHOD calculaterecreleasequantity.
    TRY.
        DATA lv_relevant_consumption_value TYPE int4.

        " 1. Determine the relevant consumption value based on the forecast and last two years of consumption
        IF ( iv_forecast * 2 ) > iv_consumption_last_two_year.
          lv_relevant_consumption_value = iv_forecast * 2.
        ELSE.
          lv_relevant_consumption_value = iv_consumption_last_two_year.
        ENDIF.
        " 2. Multiply the relevant consumption value by 1.25 for safety reasons.
        lv_relevant_consumption_value *= '1.25'.

        " 3. Subtract relevant consumption value from the relevant stock
        rv_rec_release_quantity = iv_relevant_stock - lv_relevant_consumption_value.

        " 4. Ensure release quantity is not negative
        IF rv_rec_release_quantity < 0.
          rv_rec_release_quantity = 0.
        ENDIF.
      CATCH cx_root.
        RAISE EXCEPTION NEW /lht/cx_placo_check(
            iv_error_message = /lht/cx_placo_check=>rec_release_quantity ).
    ENDTRY.
  ENDMETHOD.


  METHOD calculaterelevantstocklevel.
    TRY.
        rv_stock_level = REDUCE i( INIT stock_level = 0
                                   FOR ls_material_stock IN it_material_stock
                                   WHERE ( storlocation_mrpindicator NOT BETWEEN 1 AND 2 )
                                   NEXT stock_level += ls_material_stock-valuated_unrestricted_uses ).
      CATCH cx_root.
        RAISE EXCEPTION NEW /lht/cx_placo_check(
            iv_error_message = /lht/cx_placo_check=>relevant_stock_level ).
    ENDTRY.
  ENDMETHOD.


  METHOD calculatestockreachnoopenpos.
    DATA lv_planned_consumption_per_day TYPE gty_packed_number.
    DATA lv_unrounded_stock_reach       TYPE gty_packed_number.

    TRY.
        " 1. Determine the planned consumption per day
        IF iv_forecasted_consumption IS INITIAL.
          lv_planned_consumption_per_day = iv_annual_consumption / 365.
        ELSE.
          lv_planned_consumption_per_day = iv_forecasted_consumption / 365.
        ENDIF.

        IF lv_planned_consumption_per_day <> 0.
          " 2. Calculate the unrounded stock reach
          lv_unrounded_stock_reach = iv_relevant_stock_level / lv_planned_consumption_per_day.

          " 3. Round down the stock reach to the nearest whole number
          rv_stock_reach = round( val  = lv_unrounded_stock_reach
                                  dec  = 0
                                  mode = cl_abap_math=>round_down ).
        ELSE.
          rv_stock_reach = 999999999.
        ENDIF.
      CATCH cx_root.
        RAISE EXCEPTION NEW /lht/cx_placo_check(
            iv_error_message = /lht/cx_placo_check=>stock_reach_no_open_po ).
    ENDTRY.
  ENDMETHOD.


  METHOD calculatestockreachopenpos.
    DATA lv_planned_consumption_per_day TYPE gty_packed_number.
    DATA lv_unrounded_stock_reach       TYPE gty_packed_number.

    TRY.
        " 1. Determine the planned consumption per day
        IF iv_forecasted_consumption IS INITIAL.
          lv_planned_consumption_per_day = iv_annual_consumption / 365.
        ELSE.
          lv_planned_consumption_per_day = iv_forecasted_consumption / 365.
        ENDIF.

        IF lv_planned_consumption_per_day <> 0.
          " 2. Calculate the unrounded stock reach
          lv_unrounded_stock_reach = ( iv_relevant_stock_level + iv_number_of_inflowing_mat ) / lv_planned_consumption_per_day.

          " 3. Round down the stock reach to the nearest whole number
          rv_stock_reach = round( val  = lv_unrounded_stock_reach
                                  dec  = 0
                                  mode = cl_abap_math=>round_down ).
        ELSE.
          rv_stock_reach = 999999999.
        ENDIF.
      CATCH cx_root.
        RAISE EXCEPTION NEW /lht/cx_placo_check(
            iv_error_message = /lht/cx_placo_check=>stock_reach_open_po ).
    ENDTRY.
  ENDMETHOD.


  METHOD calculateSuggestionOptOrdQty.
    DATA lv_fraction_result TYPE gty_packed_number.

    TRY.
        IF iv_moving_average_price IS INITIAL.
          rv_suggestion_opt_order_qty = 0.
          EXIT.
        ENDIF.
        " 1. Calculate the fraction result:
        lv_fraction_result = ( 2 * iv_annual_consumption * iv_order_costs )
                           / ( iv_moving_average_price * iv_stock_cost_rate ).

        IF lv_fraction_result > 0.
          " 2. Round the square root up to the nearest whole number:
          rv_suggestion_opt_order_qty = round( val  = sqrt( lv_fraction_result )
                                               dec  = 0
                                               mode = cl_abap_math=>round_up ).
        ELSE.
          rv_suggestion_opt_order_qty = 0.
        ENDIF.

        IF iv_forecast_consumption > iv_annual_consumption.
          DATA(lv_threshold) = CONV gty_packed_number( 2 * iv_forecast_consumption ).
        ELSE.
          lv_threshold = 2 * iv_annual_consumption.
        ENDIF.
        IF     rv_suggestion_opt_order_qty > lv_threshold
           AND rv_suggestion_opt_order_qty > 0.
          rv_suggestion_opt_order_qty = round( val  = lv_threshold
                                               dec  = 0
                                               mode = cl_abap_math=>round_up ).
        ENDIF.
      CATCH cx_root.
        RAISE EXCEPTION NEW /lht/cx_placo_check(
            iv_error_message = /lht/cx_placo_check=>suggest_opt_order_qty ).
    ENDTRY.
  ENDMETHOD.


  METHOD calculatesuggestionreorderlvl.
    TRY.
        " 1. Calculate the consumption values over the replenishment period
        DATA(lt_replenishment_consumptions) = calculateConsumptInReplenish(
            it_daily_consumption  = it_daily_consumption
            iv_replenishment_time = iv_replenishment_time ).

        " 2. Determine the maximum consumption from all replenishment consumptions
        DATA(lv_maximum_consumption) = getmaximumreplenishconsumption(
                                           lt_replenishment_consumptions ).

        " 3. Calculate the reorder level using maximum consumption and safety stock
        rv_reorder_level = getReorderLevel(
                               iv_maximum_consumption = lv_maximum_consumption ).
      CATCH /lht/cx_placo_check INTO DATA(cx_check).
        RAISE EXCEPTION NEW /lht/cx_placo_check( io_previous = cx_check ).

    ENDTRY.
    " Change of Calculation PCS-282____________________
    CASE iv_type_of_reorder_lvl.
      WHEN forecast.
        " Change of Calculation PCS-153____________________
        rv_reorder_level = round( val = rv_reorder_level * '1.2'
                                  dec = 0 ).
        "__________________________________________________
      WHEN historic.
        DATA(lv_mean_daily_consumption) = calc_mean_daily_consumption(
                                              it_daily_consumption ).

        IF lv_maximum_consumption < ( lv_mean_daily_consumption * iv_replenishment_time * 3 ).
          rv_reorder_level = round( val = rv_reorder_level * '1.2'
                                    dec = 0 ).
        ENDIF.

    ENDCASE.
    "__________________________________________________
  ENDMETHOD.


  METHOD checkindexoftargetreplenish.
    TRY.
        " 1. Calculate the initial target index
        rv_target_tabix = iv_tabix + iv_replenishment_time - 1.

        " 2. Ensure the target index does not exceed the total number of table lines
        IF rv_target_tabix > iv_table_lines.
          rv_target_tabix = iv_table_lines.
        ENDIF.
      CATCH cx_root.
        RAISE EXCEPTION NEW /lht/cx_placo_check(
            iv_error_message = /lht/cx_placo_check=>index_of_target_replenish ).
    ENDTRY.
  ENDMETHOD.


  METHOD getconsumptionvaluesforindex.
    TRY.
        rt_consumption_values = VALUE gty_t_replenish_consumption(
                                          FOR i = iv_starting_index UNTIL i > iv_target_index
                                          ( it_daily_consumption[
                                                day = i ]-consumption ) ).
      CATCH cx_root.
        RAISE EXCEPTION NEW /lht/cx_placo_check(
            iv_error_message = /lht/cx_placo_check=>consumption_of_index ).
    ENDTRY.
  ENDMETHOD.


  METHOD getmaximumreplenishconsumption.
    TRY.
        rv_max_consumption = REDUCE gty_packed_number( INIT max = it_replenishment_consumption[ 1 ]
                                        FOR ls_consumption IN it_replenishment_consumption
                                        NEXT max = COND gty_packed_number( WHEN ls_consumption > max
                                                           THEN ls_consumption
                                                           ELSE max ) ).

      CATCH cx_root.
        RAISE EXCEPTION NEW /lht/cx_placo_check(
            iv_error_message = /lht/cx_placo_check=>max_consumption_in_replenish ).
    ENDTRY.
  ENDMETHOD.


  METHOD getreorderlevel.
    TRY.
        rv_reorder_level = iv_maximum_consumption.
      CATCH cx_root.
        RAISE EXCEPTION NEW /lht/cx_placo_check(
            iv_error_message = /lht/cx_placo_check=>reorder_level ).
    ENDTRY.
  ENDMETHOD.


  METHOD getsumofconsumptionvalues.
    TRY.
        rv_sum_of_consumption_values = REDUCE gty_packed_number( INIT sum TYPE gty_packed_number
                                                        FOR lv_consumption_value IN it_consumption_values
                                                        NEXT sum = sum + lv_consumption_value ).
      CATCH cx_root.
        RAISE EXCEPTION NEW /lht/cx_placo_check(
            iv_error_message = /lht/cx_placo_check=>sum_of_consumption ).
    ENDTRY.
  ENDMETHOD.


  METHOD calc_mean_daily_consumption.
    " TODO: variable is assigned but never used (ABAP cleaner)
    DATA(lv_sum_of_consumption) = getsumofconsumptionvalues(
        VALUE #( FOR daily_consumption IN it_daily_consumption
                 ( daily_consumption-consumption ) ) ).

    rv_mean_daily_consumption = lv_sum_of_consumption / lines( it_daily_consumption ).

  ENDMETHOD.
ENDCLASS.