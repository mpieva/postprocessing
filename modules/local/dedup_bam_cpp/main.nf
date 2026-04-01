process DEDUP_BAM_CPP {
    label "process_low"
    tag "$meta.id"
    container (workflow.containerEngine ? "merszym/ancient_dna_cpp_tools:97714ed" : null)

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("${meta.RG}${meta.ontarget}.uniq.${meta.filter}.bam"), path(bai) , emit: bam
    tuple val(meta), path("${meta.RG}.${meta.filter}.rmdup.txt")                           , emit: txt
    tuple val(meta), path("out.csv")                                                       , emit: csv
    path "versions.yml"                                                                    , emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    dedupBAM $args ${bam} > "${meta.RG}.${meta.filter}.rmdup.txt"

    #rename resulting bam-file
    mv *L0MQ0.bam ${meta.RG}${meta.ontarget}.uniq.${meta.filter}.bam

    # format output
    echo "in,unique,singletons,qc_fail" > out.csv
    grep lign "${meta.RG}.${meta.filter}.rmdup.txt" | tr -d " " | cut -f 2 -d ":" | paste -s -d ',' >> out.csv


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dedupBAM: \$(dedupBAM head -1 | cut -f 2 -d ' ')
    END_VERSIONS
    """
}