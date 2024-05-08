process FILTER_BAM {
    label "process_low"
    tag "$meta.id"

    input:
    tuple val(meta), path(bams)

    output:
    tuple val(meta), path('*.bam'), emit: bam
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    #TODO: hardcoded path and hardcoded parameters... needs restructuring of the perlscript
    #TODO: no container at the moment, because it requires that super old samtools version...

    /home/mmeyer/perlscripts/solexa/analysis/filterBAM.pl $args ${bams}


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        filterBAM.pl: Live Version from Matthias home directory
    END_VERSIONS
    """
}