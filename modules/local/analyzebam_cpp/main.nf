process ANALYZE_BAM_CPP {
    label "process_low"
    label "process_low"
    tag "$meta.id"

    input:
    tuple val(meta), path("${meta.RG}.bam")

    output:
    tuple val(meta), path("${meta.RG}.bam"), emit: bam
    tuple val(meta), path('summary_stats.L*MQ*.txt')         , emit: stats
    tuple val(meta), path('*.tsv')         , emit: tsv // read-length-distribution
    path "versions.yml"                    , emit: versions

    script:
    def args = task.ext.args ?: ''
    """

    analyzeBAM $args -out_folder . ${meta.RG}.bam


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        analyzeBAM_ccp: Yanivs rewrite of Matthias' analyzeBAM (compiled from git, 20240812)
    END_VERSIONS
    """
}