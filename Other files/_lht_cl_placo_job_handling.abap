CLASS /lht/cl_placo_job_handling DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING io_placo_proccessing TYPE REF TO /lht/cl_placo_event_processing OPTIONAL.

    METHODS processForecastJob.
    METHODS processScheduledJob.
    METHODS processConsumptionJob.
    METHODS processErrorLogJob.

    DATA go_placo_processing TYPE REF TO /lht/cl_placo_event_processing.

  PRIVATE SECTION.
    TYPES gty_t_mrpsets TYPE TABLE OF /lht/placo_mrp_set WITH DEFAULT KEY.
    TYPES gty_t_materials TYPE TABLE OF /lht/placo_mat_number WITH DEFAULT KEY.

    METHODS getAllMRPSetsFromNewestFC
      RETURNING
        VALUE(rt_disposets) TYPE gty_t_mrpsets.

    METHODS getExistingMaterials
      RETURNING
        VALUE(rt_existing_materials) TYPE gty_t_materials.

    METHODS getAllMRPSetsFromReplenish
      RETURNING VALUE(rt_disposets) TYPE gty_t_mrpsets.

    METHODS processChunks
      IMPORTING
        it_materials         TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_data
        iv_job               TYPE abap_boolean OPTIONAL
        io_placo_proccessing TYPE REF TO /lht/cl_placo_event_processing.

ENDCLASS.

CLASS /LHT/CL_PLACO_JOB_HANDLING IMPLEMENTATION.

  METHOD constructor.
    IF io_placo_proccessing IS NOT BOUND.
      go_placo_processing = NEW #( ).
    ELSE.
      go_placo_processing = io_placo_proccessing.
    ENDIF.
  ENDMETHOD.


  METHOD getAllMRPSetsFromNewestFC.
    SELECT SINGLE att_uuid FROM /lht/a_placo_fc
      WHERE local_created_at = ( SELECT MAX( local_created_at ) FROM /lht/a_placo_fc )
      INTO @DATA(lv_uuid).

    SELECT disposet FROM /lht/a_placo_fc
      WHERE att_uuid = @lv_uuid
      INTO TABLE @rt_disposets.
  ENDMETHOD.


  METHOD getAllMRPSetsFromReplenish.
    SELECT SINGLE att_uuid FROM /lht/a_placo_rp
      WHERE local_created_at = ( SELECT MAX( local_created_at ) FROM /lht/a_placo_rp )
      INTO @DATA(lv_uuid).

    SELECT disposet FROM /lht/a_placo_rp
      WHERE att_uuid = @lv_uuid
      INTO TABLE @rt_disposets.
  ENDMETHOD.


  METHOD processChunks.
    DATA lt_materials TYPE /lht/cm_lo_mm_materials_srv=>tyt_material_data.

    lt_materials = it_materials.

    DATA(lv_index) = 1.
    DATA(lv_chunk) = 100.
    DATA(lv_total_lines) = lines( lt_materials ).

    DO.
      IF lv_index > lv_total_lines.
        EXIT.
      ENDIF.

      io_placo_proccessing->material_processing(
        it_matnr = VALUE #(
                     FOR ls_material IN lt_materials FROM lv_index TO lv_chunk ( ls_material-material_number ) ) ).

      lv_index += 100.
      lv_chunk += 100.

      IF lv_chunk > lv_total_lines.
        lv_chunk = lv_total_lines.
      ENDIF.

      COMMIT ENTITIES.
    ENDDO.
  ENDMETHOD.


  METHOD processConsumptionJob.
    DATA(lt_mrpset) = getAllMRPSetsFromReplenish( ).

    DATA(lv_index) = 1.
    DATA(lv_chunk) = 100.
    DATA(lv_total_lines) = lines( lt_mrpset ).

    DO.
      IF lv_index > lv_total_lines.
        EXIT.
      ENDIF.

      TRY.
          DATA(lt_materials) =
            /lht/cl_placo_odata_helper=>read_mrpset_materials(
              it_disposets = VALUE #( FOR ls_mrpset IN lt_mrpset FROM lv_index TO lv_chunk ( ls_mrpset ) ) ).
        CATCH /lht/cx_placo_check.
          " handle exception
      ENDTRY.

      processChunks(
        it_materials         = VALUE #(
                                 FOR ls_material IN lt_materials ( material_number = ls_material-material_number ) )
        io_placo_proccessing = go_placo_processing ).

      lv_index += 100.
      lv_chunk += 100.

      IF lv_chunk > lv_total_lines.
        lv_chunk = lv_total_lines.
      ENDIF.
    ENDDO.
  ENDMETHOD.


  METHOD processErrorLogJob.
    DATA lr_material TYPE RANGE OF /lht/placo_mat_number.

    SELECT material FROM /lht/a_placo_elr
      INTO TABLE @DATA(lt_materials).

    lr_material = VALUE #( FOR material IN lt_materials
                           ( sign   = `I`
                             option = `EQ`
                             low    = material ) ).

    DELETE FROM /lht/a_placo_elr WHERE material IN @lr_material.

    processChunks( it_materials         = VALUE #(
                                            FOR ls_material IN lt_materials ( material_number = ls_material ) )
                   io_placo_proccessing = go_placo_processing ).
  ENDMETHOD.


  METHOD processForecastJob.
    DATA(lt_mrpset) = getAllMRPSetsFromNewestFC( ).

    DATA(lv_index) = 1.
    DATA(lv_chunk) = 100.
    DATA(lv_total_lines) = lines( lt_mrpset ).

    DO.
      IF lv_index > lv_total_lines.
        EXIT.
      ENDIF.

      TRY.
          DATA(lt_materials) =
            /lht/cl_placo_odata_helper=>read_mrpset_materials(
              it_disposets = VALUE #( FOR ls_mrpset IN lt_mrpset FROM lv_index TO lv_chunk ( ls_mrpset ) ) ).
        CATCH /lht/cx_placo_check.
          " handle exception
      ENDTRY.

      processChunks(
        it_materials         = VALUE #(
                                 FOR ls_material IN lt_materials ( material_number = ls_material-material_number ) )
        io_placo_proccessing = go_placo_processing ).

      lv_index += 100.
      lv_chunk += 100.

      IF lv_chunk > lv_total_lines.
        lv_chunk = lv_total_lines.
      ENDIF.
    ENDDO.
  ENDMETHOD.


  METHOD processScheduledJob.
    TRY.
        DATA(lt_materials) = /lht/cl_placo_odata_helper=>read_material_psg( ).
      CATCH /lht/cx_placo_check.
        " handle exception
    ENDTRY.

    DATA(lt_existing_materials) = getExistingMaterials( ).

    lt_materials = VALUE #( BASE lt_materials
      FOR ls_existing IN lt_existing_materials ( material_number = ls_existing ) ).

    SORT lt_materials ASCENDING BY material_number.
    DELETE ADJACENT DUPLICATES FROM lt_materials COMPARING material_number.

    processChunks( it_materials         = lt_materials
                   io_placo_proccessing = go_placo_processing ).
  ENDMETHOD.


  METHOD getExistingMaterials.
    SELECT material FROM /lht/a_placo_mat
      INTO TABLE @rt_existing_materials.
  ENDMETHOD.
ENDCLASS.