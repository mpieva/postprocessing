process GET_AVERAGE_LENGTH {
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/perl:5.32' :
        'quay.io/biocontainers/perl:5.32' }"
    label "process_low"
    tag "$meta.id"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("${meta.RG}.average_fragment_length.L35MQ25.txt"), emit: txt
    path "versions.yml"                                                    , emit: versions

    script:
    """
    average_length_of_sequences.pl ${bam} > ${meta.RG}.average_fragment_length.L35MQ25.txt;


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        average_length_of_sequences.pl: Version copied from Matejas home directory 2024-05-08
    END_VERSIONS
    """
}