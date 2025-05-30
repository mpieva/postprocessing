include { DEAM_BAM_CPP   } from '../modules/local/deam_bam_cpp'
include { SAMTOOLS_CALMD } from '../modules/local/samtools_calmd'
include { SAMTOOLS_INDEX } from '../modules/local/samtools_index'
include { PLOT_DEAM      } from '../modules/local/pandas_plot_deam'

workflow substitutions {
    take:
        bam
        reference

    main:

        def filterstring = "L${params.bamfilter_minlength}MQ${params.bamfilter_minqual}"
        def outdir = "${params.reference_name}.${params.target_name}"

        //
        // Fist, fix MD-tag
        //
        
        ch_bam = bam.combine(reference).map{ meta, bam, bai, fa ->
            [meta, bam, fa]
        }

        SAMTOOLS_CALMD(ch_bam)
        ch_calmd_bam = SAMTOOLS_CALMD.out.bam

        //
        // Then, index fasta again
        //

        SAMTOOLS_INDEX(ch_calmd_bam)

        ch_calmd_indexed = SAMTOOLS_INDEX.out.indexed

        ch_calmd_indexed = ch_calmd_indexed.map{meta, bam, bai ->
            [
                meta+['filename':bam.baseName],
                bam,
                bai
            ]
        }

        //
        // Then, Yanivs CPP-script
        //

        DEAM_BAM_CPP(ch_calmd_indexed)
        
        deam_stats = DEAM_BAM_CPP.out.tsv.map{meta, stats ->
            meta+stats.splitCsv(sep:'\t', header:true).first()
        }
        versions = DEAM_BAM_CPP.out.versions

        //
        // Plot Patterns
        //

        PLOT_DEAM(DEAM_BAM_CPP.out.txt)


    emit:
        meta = deam_stats
        versions = versions
}