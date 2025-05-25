process DEAM_BAM_CPP {
    label "process_low"
    tag "$meta.id"

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    path("*.txt")                      , emit: txt
    path "versions.yml"                , emit: versions
    tuple val(meta), path('total.tsv') , emit: tsv


    script:
    def args = task.ext.args ?: ''
    """
    deamBAM $args ${bam} > /dev/null

    head -1 substitution_patterns.${bam.baseName}.txt > total.tsv
    tail -1 substitution_patterns.${bam.baseName}.txt >> total.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        deamBAM: \$(deamBAM | head -1)
    END_VERSIONS
    """
}