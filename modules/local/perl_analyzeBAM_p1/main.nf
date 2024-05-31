process ANALYZE_BAM_P1 {
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/perl:5.32' :
        'quay.io/biocontainers/perl:5.32' }"
    label "process_low"
    label "process_low"
    tag "$meta.id"


    input:
    tuple val(meta), path("${meta.RG}.sam")

    output:
    tuple val(meta), path("${meta.RG}.sam"), emit: sam
    tuple val(meta), path('*.txt')         , emit: stats
    path "versions.yml"                    , emit: versions

    script:
    def args = task.ext.args ?: ''
    """

    analyzeBAM_p1.pl $args ${meta.RG}.sam > stats.txt


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        analyzeBAM_p1.pl: Modified first part of analyzeBAM (20240522)
    END_VERSIONS
    """
}