include { BAM_RMDUP }                             from '../modules/local/bam_rmdup'
include { ANALYZE_BAM_CPP as ANALYZE_BAM_CPP_P1 } from '../modules/local/analyzebam_cpp'
include { ANALYZE_BAM_CPP as ANALYZE_BAM_CPP_P2 } from '../modules/local/analyzebam_cpp'
include { GET_AVERAGE_LENGTH }                    from '../modules/local/perl_get_readlength'


workflow analyzeBAM {
    take:
        bam

    main:

        // Some defs necessary for the writing to disc
        def outdir = "reluctant_${workflow.manifest.version}"
        def filterstring = "L${params.bamfilter_minlength}MQ${params.bamfilter_minqual}"

        bam = bam.map{ meta, bam ->
            [
                meta + ['filter':filterstring],
                bam
            ]
        }

        //
        // 1. Get all the stats from the Bamfile
        //

        ANALYZE_BAM_CPP_P1(bam, [])
        versions = ANALYZE_BAM_CPP_P1.out.versions.first()

        ANALYZE_BAM_CPP_P1.out.stats
            .map{it[1]}
            .collectFile(name: "summary_stats_${filterstring}.txt", storeDir:"${outdir}/AnalyzeBAM_${filterstring}", keepHeader:true)

        //
        // 2. Get the filtered BamFile
        //

        filterbam = ANALYZE_BAM_CPP_P1.out.bam

        // include the stats in the meta
        filterbam.combine( ANALYZE_BAM_CPP_P1.out.stats, by:0 )
        .map{ meta, bam, stats ->
            def vals = stats.splitCsv(sep:'\t', header:true).first() // first because the splitCsv results in [[key:value]]
            [
                meta+vals,
                bam
            ]
        }
        .set{ filterbam }

        //
        // 3. Run Bam-rmdup
        //

        BAM_RMDUP(filterbam)

        uniqbam = BAM_RMDUP.out.bam

        //
        // 4. Get Post-Bam-rmdup stats
        //

        uniqbam.combine( BAM_RMDUP.out.txt, by:0 )
        .map{ meta, bam, stats ->
            def vals = stats.splitCsv(header:true, sep:"\t").first() // first because the splitCsv results in [[key:value]]
            // sanitize the bam-rmdup output
            def tmp = [
                "in": vals["in"].replace(",",""),
                "unique":vals["out"].replace(",",""),
                "singletons":vals["single@MQ20"].replace(",",""),
            ]
            // do some additional calculations
            def rmdup_stats = tmp + ["average_dups": (tmp['in'] as int) / (tmp["unique"] as int) ]
            [
                meta+rmdup_stats,
                bam
            ]
        }
        .set{ uniqbam }

        //
        // 5. Get average fragment length
        //

        GET_AVERAGE_LENGTH(uniqbam)

        // save the output to the folder
        GET_AVERAGE_LENGTH.out.txt
            .map{it[1]}
            .collectFile(name: "average_fragment_length.${filterstring}.txt", storeDir:"${outdir}/AnalyzeBAM_${filterstring}")
        versions = versions.mix(GET_AVERAGE_LENGTH.out.versions.first())

        // save the length to the meta
        uniqbam = uniqbam.combine(GET_AVERAGE_LENGTH.out.txt, by:0)
            .map{ meta, bam, txt ->
                [
                    meta+['average_fragment_length': txt.text.split(':')[1].trim() as float],
                    bam
                ]
            }

    emit:
        bam = uniqbam
        versions = versions
}