process SUMMARIZE_CT {
    label "process_low"

    input:
    tuple val(meta), path(txt)

    output:
    tuple val(meta), path('CT_substitutions.L35MQ25.txt'), emit: txt
    path "versions.yml"                                  , emit: versions

    script:
    """
    #TODO: hardcoded path and hardcoded parameters... needs restructuring of the perlscript
    #TODO: no container at the moment, because it requires that super old samtools version...
    #TODO: are the minread and quality necessary (again) ??

    /home/mmeyer/perlscripts/solexa/analysis/summarize_CT_frequencies.pl -screen ${txt} > CT_substitutions.L35MQ25.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        summarize_CT_frequencies.pl: Live Version from Matthias home directory
    END_VERSIONS
    """
}