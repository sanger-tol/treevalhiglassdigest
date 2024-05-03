#!/usr/bin/env nextflow

//
// MODULE IMPORT BLOCK
//
include { UPLOAD_HIGLASS_DATA     } from '../../modules/local/upload_higlass_data'
include { GENERATE_HIGLASS_LINK   } from '../../modules/local/generate_higlass_link'

workflow INGEST_HIGLASS {
    take:
    ch_tolid
    ch_mcool                       // Channel: path(file)
    ch_genome                      // Channel: path(file)
    ch_coverage                       // Channel: path(file)
    ch_repeatdensity                      // Channel: path(file)
    ch_gap                       // Channel: path(file)
    ch_telo                      // Channel: path(file)     
    ch_higlass_url
    ch_higlass_deployment_name
    ch_higlass_namespace
    ch_higlass_kubeconfig
    ch_higlass_upload_directory    // channel: val(higlass_upload_directory)

    main:
    ch_versions     = Channel.empty()

    UPLOAD_HIGLASS_DATA (
        ch_mcool,
        ch_genome,
        ch_coverage,
        ch_repeatdensity,
        ch_telo,
        ch_gap,
        ch_tolid,
        ch_higlass_upload_directory, 
        ch_higlass_kubeconfig, 
        ch_higlass_namespace, 
        ch_higlass_deployment_name )
    ch_versions = ch_versions.mix ( UPLOAD_HIGLASS_DATA.out.versions.first() )


    GENERATE_HIGLASS_LINK (
        UPLOAD_HIGLASS_DATA.out.file_name,
        ch_tolid,
        UPLOAD_HIGLASS_DATA.out.map_uuid, 
        UPLOAD_HIGLASS_DATA.out.grid_uuid,
        UPLOAD_HIGLASS_DATA.out.cov_uuid,
        UPLOAD_HIGLASS_DATA.out.rep_uuid,
        UPLOAD_HIGLASS_DATA.out.telo_uuid,
        UPLOAD_HIGLASS_DATA.out.gap_uuid,  
        ch_higlass_url, 
        UPLOAD_HIGLASS_DATA.out.genome_file)
    ch_versions = ch_versions.mix ( GENERATE_HIGLASS_LINK.out.versions.first() )

    emit:
    ch_higlass_link = GENERATE_HIGLASS_LINK.out.higlass_link
    versions        = ch_versions.ifEmpty(null)
}
