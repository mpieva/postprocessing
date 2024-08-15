process ANALYZE_BAM_CPP {
    label "process_low"
    label "process_low"
    tag "$meta.id"

    input:
    tuple val(meta), path("${meta.RG}.bam")
    path target

    output:
    tuple val(meta), path("${meta.RG}.${meta.filter}.bam")                          , emit: bam
    tuple val(meta), path("summary_stats.${meta.filter}.txt")                       , emit: stats
    tuple val(meta), path("read_length_distribution.${meta.RG}.${meta.filter}.tsv") , emit: tsv // read-length-distribution
    path "versions.yml"                                                             , emit: versions

    script:
    def args = task.ext.args ?: ''
    def target = target ? "-targetfile ${target}" : ''
    """

    analyzeBAM $args -out_folder $target  . ${meta.RG}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        analyzeBAM_ccp: \$(analyzeBAM | head -1 | cut -d ' ' -f2)
    END_VERSIONS
    """
}