#!/usr/bin/env nextflow

include { SPLITBAM }        from '../modules/local/splitbam'
include { ESTIMATE_CC }     from '../modules/local/ccestimate'
include { INDEX_STATS }     from '../modules/local/perl_indexstats'
include { SAMTOOLS_SORT }   from '../modules/local/samtools_sort'

workflow splitbam {
    take:
        bam
        by
    main:
        // Split Bam by RGs
        SPLITBAM( [[:], bam, by] )

        // Estimate Crosscontamination
        ESTIMATE_CC(SPLITBAM.out.stats)
        cc_versions = ESTIMATE_CC.out.versions

        INDEX_STATS(SPLITBAM.out.stats)
        cc_versions = cc_versions.mix(INDEX_STATS.out.versions)

        bam = SPLITBAM.out.bams.transpose()
        SAMTOOLS_SORT(bam)


    emit:
        versions = cc_versions.mix(SPLITBAM.out.versions)
        bams = SAMTOOLS_SORT.out.bam
}
