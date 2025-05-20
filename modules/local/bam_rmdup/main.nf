process BAM_RMDUP {
    container (workflow.containerEngine ? "merszym/biohazard_bamrmdup:v0.2.2" : null)
    tag "${meta.id}"
    label "process_low"
    label 'local'

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("${meta.RG}${meta.ontarget}.uniq.${meta.filter}.bam") , emit: bam
    tuple val(meta), path("${meta.RG}.${meta.filter}.rmdup.txt")                , emit: txt
    path "versions.yml"                                                         , emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    bam-rmdup $args -o  "${meta.RG}${meta.ontarget}.uniq.${meta.filter}.bam" ${bam} > "${meta.RG}.${meta.filter}.rmdup.txt"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bam-rmdup: \$(bam-rmdup --version 2>&1> /dev/null | cut -d ' ' -f3)
    END_VERSIONS
    """
}