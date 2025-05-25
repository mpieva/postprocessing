process FILTER_BAM {
    label "process_low"
    tag "$meta.id"

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