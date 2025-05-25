process GET_AVERAGE_LENGTH {
    label "process_low"
    tag "$meta.id"

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("${meta.RG}.average_fragment_length.filteredLMQ.txt"), emit: txt
    path "versions.yml"                                                        , emit: versions

    script:
    """
    average_length_of_sequences.pl ${bam} > ${meta.RG}.average_fragment_length.filteredLMQ.txt;


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        average_length_of_sequences.pl: Version copied from Matejas home directory 2024-05-08
    END_VERSIONS
    """
}