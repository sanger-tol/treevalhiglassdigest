process UPLOAD_HIGLASS_DATA {
    tag "$meta.id"
    label 'process_single'

    container "bitnami/kubectl:1.27"

    input:
    tuple val(meta), path(mcool)
    tuple val(meta2), path(genome)
    tuple val(meta), path(coverage)
    tuple val(meta2), path(repeat_density)
    tuple val(meta), path(telomere)
    tuple val(meta2), path(seqgap)
    val(tolid)
    path(upload_dir)
    val(higlass_kubeconfig)
    val(higlass_namespace)
    val(higlass_deployment_name)

    output:
    env map_uuid, emit: map_uuid
    env grid_uuid, emit: grid_uuid
    env cov_uuid, emit: cov_uuid
    env rep_uuid, emit: rep_uuid
    env telo_uuid, emit: telo_uuid
    env gap_uuid, emit: gap_uuid
    env file_name, emit: file_name
    tuple val(meta2), path(genome), emit: genome_file
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "UPLOAD_HIGLASS_DATA modules do not support Conda. Please use Docker / Singularity / Podman instead."
    }

    // def project_name = "${higlass_data_project_dir}/${species.replaceAll('\\s','_')}/${assembly}"
    def file_name = "${tolid}"
    // uid cannot contain a "."
    def uid = "${file_name.replaceAll('\\.','_')}"

    """
    # Configure kubectl access to the namespace
    export KUBECONFIG=${higlass_kubeconfig}
    kubectl config get-contexts
    kubectl config set-context --current --namespace=${higlass_namespace}

    # Find the name of the pod
    sel=\$(kubectl get deployments.apps ${higlass_deployment_name} --output=json | jq -j '.spec.selector.matchLabels | to_entries | .[] | "\\(.key)=\\(.value),"')
    sel2=\${sel%?}
    pod_name=\$(kubectl get pod --selector=\$sel2 --output=jsonpath={.items[0].metadata.name})
    echo "\$pod_name"

    # Copy the files to the upload area
    mkdir -p ${upload_dir}/${tolid}
    cp -f $mcool ${upload_dir}/${tolid}/${file_name}.mcool
    cp -f $genome ${upload_dir}/${tolid}/${file_name}.genome
    cp -f $coverage ${upload_dir}/${tolid}/${file_name}_coverage.bw
    cp -f $repeat_density ${upload_dir}/${tolid}/${file_name}_repeat_density.bw
    cp -f $telomere ${upload_dir}/${tolid}/${file_name}_telomere.bed
    cp -f $seqgap ${upload_dir}/${tolid}/${file_name}_gap.bed

    # Loop over files to load them in Kubernetes

    files_to_upload=(".mcool" ".genome" "_coverage.bw" "_repeat_density.bw" "_telomere.bed" "_gap.bed")

    for file_ext in \${files_to_upload[@]}; do
        echo "loading \$file_ext file"

        # Set file type and uuid to use for tileset. This uuid is needed for creating viewconfig.

        if [[ \$file_ext == ".mcool" ]]
        then
            file_type="map"
            map_uuid=${tolid}_map
        elif [[ \$file_ext == ".genome" ]]
        then
            file_type="grid"
            grid_uuid=${tolid}_grid
        elif [[ \$file_ext == "_coverage.bw" ]]
        then
            file_type="coverage"
            cov_uuid=${tolid}_coverage
        elif [[ \$file_ext == "_repeat_density.bw" ]]
        then
            file_type="repeat_density"
            rep_uuid=${tolid}_repeat_density
        elif [[ \$file_ext == "_telomere.bed" ]]
        then
            file_type="telomere"
            telo_uuid=${tolid}_telomere
        elif [[ \$file_ext == "_gap.bed" ]]
        then
            file_type="seqgap"
            gap_uuid=${tolid}_seqgap
        fi

        # Call the bash script to handle upload of file to higlass server

        echo "\$file_ext loaded"
    done

    upload_higlass_file.sh \$pod_name ${tolid}

    # Set file name to pass through to view config creation
    file_name=${tolid}

    echo "done"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kubectl: \$(kubectl version --output=json | jq -r ".clientVersion.gitVersion")
    END_VERSIONS
    """

    
}
