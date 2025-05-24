process PLOT_READLENGTH{
    container (workflow.containerEngine ? "merszym/pandas_plt:nextflow" : null)
    tag "${meta.id}"
    label 'local'

    input:
    tuple val(meta), path(tsv)

    output:
    tuple val(meta), path("*.jpg") , emit: jpg

    script:
    """
    plot_readlength.py ${tsv} ${meta.RG}
    """
}