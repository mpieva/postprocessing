process ANALYZE_BAM {
    label "process_low"
    tag "$meta.id"


    input:
    tuple val(meta), path("${meta.RG}.bam")

    output:
    tuple val(meta), path('*.bam'), emit: bam
    tuple val(meta), path('*.txt'), emit: stats
    path "versions.yml"           , emit: versions

    script:
    """
    #TODO: hardcoded path and hardcoded parameters... needs restructuring of the perlscript
    #TODO: no container at the moment, because it requires that super old samtools version...

    /home/mmeyer/perlscripts/solexa/analysis/analyzeBAM.pl -nof -minlength 35 -qual 25 ${meta.RG}.bam


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        analyzeBAM.pl: Live Version from Matthias home directory
    END_VERSIONS
    """
}