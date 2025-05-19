process GET_PATTERNS {
    label "process_low"
    tag "$meta.id"

    input:
    tuple val(meta), path(bams)

    output:
    tuple val(meta), path('*.txt'), emit: txt
    tuple val(meta), path('*.pdf'), emit: pdf
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''

    """
    #TODO: hardcoded path and hardcoded parameters... needs restructuring of the perlscript
    #TODO: no container at the moment, because it requires that super old samtools version...

    /home/mmeyer/perlscripts/solexa/analysis/substitution_patterns.pl $args ${bams}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        substitution_patterns.pl: Live Version from Matthias home directory
    END_VERSIONS
    """
}