process DEDUP_BAM_CPP {
    label "process_low"
    tag "$meta.id"
    container (workflow.containerEngine ? "merszym/analyzebam_cpp:latest" : null)

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("${meta.RG}${meta.ontarget}.uniq.${meta.filter}.bam"), path(bai) , emit: bam
    tuple val(meta), path("${meta.RG}.${meta.filter}.rmdup.txt")                           , emit: txt
    path "versions.yml"                                                                    , emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    dedupBAM $args -o "${meta.RG}${meta.ontarget}.uniq.${meta.filter}.bam" ${bam} > "${meta.RG}.${meta.filter}.rmdup.txt"


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dedupBAM: \$(dedupBAM --version)
    """
}