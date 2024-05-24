process SAMTOOLS_VIEW {
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.15.1--h1170115_0' :
        'quay.io/biocontainers/samtools:1.15.1--h1170115_0' }"
    tag "$meta.id"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path(bam), stdout     , emit: bam
    tuple val(meta), path("out.sam")       , emit: sam
    path "versions.yml"                    , emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    touch out.sam
    samtools view $args ${bam}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(samtools version | head -1 | cut -d' ' -f2)
    END_VERSIONS
    """
}