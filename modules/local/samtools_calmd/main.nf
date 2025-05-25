process SAMTOOLS_CALMD {
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.15.1--h1170115_0' :
        'quay.io/biocontainers/samtools:1.15.1--h1170115_0' }"
    tag "$meta.id"

    input:
    tuple val(meta), path(bam), path(fasta)

    output:
    tuple val(meta), path("*calmd.bam"), emit: bam
    path "versions.yml"                , emit: versions

    script:
    """
    samtools calmd ${bam} ${fasta} -b > ${bam.baseName}_calmd.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(samtools version | head -1 | cut -d' ' -f2)
    END_VERSIONS
    """
}