process INDEX_STATS {
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/perl:5.32' :
        'quay.io/biocontainers/perl:5.32' }"
    label "process_low"

    input:
    tuple val(meta), path(splittingstats)

    output:
    tuple val(meta), path('index_stats.txt') , emit: stats
    path "versions.yml"                     , emit: versions

    script:
    """
    indexstats.pl ${splittingstats} > index_stats.txt


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        indexstats: Version copied from Matthias home directory 2024-05-08
    END_VERSIONS
    """
}