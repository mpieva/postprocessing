process PLOT_DEAM{
    container (workflow.containerEngine ? "merszym/pandas_plt:nextflow" : null)
    tag "${meta.id}"
    label 'local'

    input:
    tuple val(meta), path(txt)

    output:
    tuple val(meta), path("*.jpg") , emit: jpg

    when:
    meta['unique'] as int > 0

    script:
    """
    plot_deam_patterns.py ${meta.filename} \$(ls substitution_patterns_*.txt)
    """
}