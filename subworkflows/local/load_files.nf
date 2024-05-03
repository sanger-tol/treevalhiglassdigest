#!/usr/bin/env nextflow

//
// MODULE IMPORT BLOCK
//

workflow LOAD_FILES {
    take:
    ch_tolid
    ch_input_dir    // channel: val(higlass_upload_directory)

    main:
    ch_versions     = Channel.empty()


    //
    // LOGIC: make channel of hic reads as input for GENERATE_CRAM_CSV
    //
    ch_input_dir
        .combine(ch_tolid)
        .map { input_dir, tolid ->
                tuple(
                    [ id: tolid, single_end: true],
                    input_dir
                )
        }
        .set { input_path }

    ch_file_mcool                   = GrabFileMcool(input_path)
    ch_file_genome                  = GrabFileGenome(input_path)
    ch_file_coverage                = GrabFileCoverage(input_path)
    ch_file_repeatdensity           = GrabFileRepeatDensity(input_path)
    ch_file_gap                     = GrabFileGap(input_path)
    ch_file_telo                    = GrabFileTelo(input_path)

    emit:
    mcool                        = ch_file_mcool
    genome                       = ch_file_genome
    coverage                     = ch_file_coverage
    repeatdensity                = ch_file_repeatdensity
    gap                          = ch_file_gap
    telo                         = ch_file_telo
    versions                     = ch_versions.ifEmpty(null)
}

process GrabFileMcool {
    label 'process_tiny'

    tag "${meta.id}"
    executor 'local'

    input:
    tuple val(meta), path("in")

    output:
    tuple val(meta), path("in/*/hic_files/*.mcool")

    "true"
}

process GrabFileGenome {
    label 'process_tiny'

    tag "${meta.id}"
    executor 'local'

    input:
    tuple val(meta), path("in")

    output:
    tuple val(meta), path("in/*/treeval_upload/*.genome")

    "true"
}

process GrabFileCoverage {
    label 'process_tiny'

    tag "${meta.id}"
    executor 'local'

    input:
    tuple val(meta), path("in")

    output:
    tuple val(meta), path("in/*/hic_files/*_coverage_normal.bigWig")

    "true"
}

process GrabFileRepeatDensity {
    label 'process_tiny'

    tag "${meta.id}"
    executor 'local'

    input:
    tuple val(meta), path("in")

    output:
    tuple val(meta), path("in/*/hic_files/*_repeat_density.bigWig")

    "true"
}

process GrabFileGap {
    label 'process_tiny'

    tag "${meta.id}"
    executor 'local'

    input:
    tuple val(meta), path("in")

    output:
    tuple val(meta), path("in/*/hic_files/*_gap.bed")

    "true"
}

process GrabFileTelo {
    label 'process_tiny'

    tag "${meta.id}"
    executor 'local'

    input:
    tuple val(meta), path("in")

    output:
    tuple val(meta), path("in/*/hic_files/*_telomere.bed")

    "true"
}