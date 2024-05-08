process GET_PATTERNS {
    label "process_low"

    input:
    tuple val(meta), path(bams)

    output:
    tuple val(meta), path('*.txt'), emit: txt
    tuple val(meta), path('*.pdf'), emit: pdf
    path "versions.yml"           , emit: versions

    script:
    """
    #TODO: hardcoded path and hardcoded parameters... needs restructuring of the perlscript
    #TODO: no container at the moment, because it requires that super old samtools version...
    #TODO: are the minread and quality necessary (again) ??

    /home/mmeyer/perlscripts/solexa/analysis/substitution_patterns.pl -minread 35 -quality 25 ${bams}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        substitution_patterns.pl: Live Version from Matthias home directory
    END_VERSIONS
    """
}