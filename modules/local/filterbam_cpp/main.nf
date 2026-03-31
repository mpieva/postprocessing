process FILTER_BAM_CPP {
    label "process_low"
    tag "$meta.id"
    container (workflow.containerEngine ? "merszym/analyzebam_cpp:latest" : null)

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path('*.bam'), path(bai), emit: bam
    path "versions.yml"                      , emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    filterBAM $args ${bam}


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        filterBAM: \$(filterBAM --version)
    """
}