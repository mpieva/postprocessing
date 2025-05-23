process FILTER_BAM {
    label "process_low"
    tag "$meta.id"

    input:
    tuple val(meta), path(bams)

    output:
    tuple val(meta), path('*.bam'), emit: bam
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    filterBAM $args ${bams}


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        filterBAM: \$(filterBAM --version)
    """
}