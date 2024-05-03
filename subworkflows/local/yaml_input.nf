#!/usr/bin/env nextflow

import org.yaml.snakeyaml.Yaml

workflow YAML_INPUT {
    take:
    input_file  // params.input

    main:
    ch_versions = Channel.empty()

    input_file
        .map { file -> readYAML(file) }
        .set { yamlfile }

    //
    // LOGIC: PARSES THE TOP LEVEL OF YAML VALUES
    //
    yamlfile
        .flatten()
        .multiMap { data ->
                sample:                 ( data.sample )
                higlass:                ( data.higlass )
        }
        .set{ group }

    //
    // LOGIC: PARSES THE SECOND LEVEL OF YAML VALUES PER ABOVE OUTPUT CHANNEL
    //
  
    group
        .sample
        .multiMap { data ->
                    tolid:      data.tolid
                    directory:  data.directory
        }
        .set{ sample_data }

    group
        .higlass
        .multiMap { data ->
                    higlass_url:                data.higlass_url
                    higlass_deployment_name:    data.higlass_deployment_name
                    higlass_namespace:          data.higlass_namespace
                    higlass_kubeconfig:         data.higlass_kubeconfig
                    higlass_upload_directory:   data.higlass_upload_directory
        }
        .set{ higlass_data }

    emit:
    tolid                               = sample_data.tolid
    directory                           = sample_data.directory
    higlass_url                         = higlass_data.higlass_url
    higlass_deployment_name             = higlass_data.higlass_deployment_name
    higlass_namespace                   = higlass_data.higlass_namespace
    higlass_kubeconfig                  = higlass_data.higlass_kubeconfig
    higlass_upload_directory            = higlass_data.higlass_upload_directory

    versions                         = ch_versions.ifEmpty(null)
}

def readYAML( yamlfile ) {
    return new Yaml().load( new FileReader( yamlfile.toString() ) )
}
