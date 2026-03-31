process GET_AVERAGE_LENGTH {
    label "process_low"
    tag "$meta.id"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.15.1--h1170115_0' :
        'quay.io/biocontainers/samtools:1.15.1--h1170115_0' }"

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("average.txt"), emit: txt

    script:
    """
    samtools view ${bam} | awk '{sum+=length(\$10); n++} END {print sum/n}' > average.txt
    """
}