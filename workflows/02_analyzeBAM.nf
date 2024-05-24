include { SAMTOOLS_VIEW as SAMTOOLS_FILTER } from '../modules/local/samtools_view'
include { SAMTOOLS_VIEW as BAM_TO_SAM      } from '../modules/local/samtools_view'
include { BAM_RMDUP }                        from '../modules/local/bam_rmdup'
include { ANALYZE_BAM_P1 as BAM_STATS }      from '../modules/local/perl_analyzeBAM_p1'


workflow analyzeBAM {
    take:
        bam

    main:

        //
        // 0. Convert bam to sam for analyzeBAM
        //

        BAM_TO_SAM(bam)
        versions = BAM_TO_SAM.out.versions.first()

        samfile = BAM_TO_SAM.out.sam

        //
        // 1. Get all the stats from the Bamfile
        //

        BAM_STATS(samfile)
        versions = versions.mix(BAM_STATS.out.versions.first())

        //
        // 2. Filter the BamFile (parallel)
        //

        SAMTOOLS_FILTER(bam)

        bam = SAMTOOLS_FILTER.out.bam.map{
            [it[0], it[1]]
        }

        // include the stats in the meta
        bam.combine( BAM_STATS.out.stats, by:0 )
        .map{ meta, bam, stats ->
            def vals = stats.splitCsv(sep:'\t', header:true).first() // first because the splitCsv results in [[key:value]]
            [
                meta+vals,
                bam
            ]
        }
        .set{ bam }

        //save the summary of the summary_stats_file
        def outdir = "reluctant_${workflow.manifest.version}"

        BAM_STATS.out.stats
            .map{it[1]}
            .collectFile(name: 'summary_stats_L35MQ25.txt', storeDir:"${outdir}/AnalyzeBAM_L35MQ25", keepHeader:true)
            // #TODO: make L35MQ25 variable based on flags

        //
        // 3. Run Bam-rmdup
        //

        BAM_RMDUP(bam)

        bam = BAM_RMDUP.out.bam

        //
        // 4. Get Post-Bam-rmdup stats
        // #TODO

    emit:
        bam = bam
        versions = versions
}