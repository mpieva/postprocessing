include { ANALYZE_BAM        }  from '../modules/local/perl_analyzeBAM'
include { GET_AVERAGE_LENGTH }  from '../modules/local/perl_get_readlength'


workflow bamfilter {
    take:
        bam

    main:
        //
        // filter the bam by running analyzeBAM
        //

        ANALYZE_BAM(bam)

        versions = ANALYZE_BAM.out.versions.first()
        bam = ANALYZE_BAM.out.bam

        // include the stats in the meta
        bam.combine( ANALYZE_BAM.out.stats, by:0 )
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

        ANALYZE_BAM.out.stats
            .map{it[1]}
            .collectFile(name: 'summary_stats_L35MQ25.txt', storeDir:"${outdir}/AnalyzeBAM_L35MQ25", keepHeader:true)

        //
        // Get average fragment length
        //

        GET_AVERAGE_LENGTH(bam)

        // save the output to the folder
        GET_AVERAGE_LENGTH.out.txt
            .map{it[1]}
            .collectFile(name: 'average_fragment_length.L35MQ25.txt', storeDir:"${outdir}/AnalyzeBAM_L35MQ25")
        versions = versions.mix(GET_AVERAGE_LENGTH.out.versions.first())

        // save the length to the meta
        bam = bam.combine(GET_AVERAGE_LENGTH.out.txt, by:0)
            .map{ meta, bam, txt ->
                [
                    meta+['Average_Fragment_Length': txt.text.split(':')[1].trim() as float],
                    bam
                ]
            }

    emit:
        bam = bam
        versions = versions
}