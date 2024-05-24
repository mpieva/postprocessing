process SAMTOOLS_VIEW {
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.15.1--h1170115_0' :
        'quay.io/biocontainers/samtools:1.15.1--h1170115_0' }"
    tag "$meta.id"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), stdout        , emit: stdout, optional: true
    tuple val(meta), path("*.bam") , emit: bam,    optional: true
    tuple val(meta), path("*.sam") , emit: sam,    optional: true
    path "versions.yml"            , emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    samtools view $args ${bam}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(samtools version | head -1 | cut -d' ' -f2)
    END_VERSIONS
    """
}