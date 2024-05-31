include { SAMTOOLS_VIEW as SAMTOOLS_FILTER } from '../modules/local/samtools_view'
include { SAMTOOLS_VIEW as BAM_TO_SAM      } from '../modules/local/samtools_view'
include { BAM_RMDUP }                        from '../modules/local/bam_rmdup'
include { ANALYZE_BAM_P1 as BAM_STATS }      from '../modules/local/perl_analyzeBAM_p1'
include { GET_AVERAGE_LENGTH }               from '../modules/local/perl_get_readlength'


workflow analyzeBAM {
    take:
        bam

    main:

        // Some defs necessary for the writing to disc
        def outdir = "reluctant_${workflow.manifest.version}"
        def filterstring = "L${params.bamfilter_minlength}MQ${params.bamfilter_minqual}"

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

        BAM_STATS.out.stats
            .map{it[1]}
            .collectFile(name: "summary_stats_${filterstring}.txt", storeDir:"${outdir}/AnalyzeBAM_${filterstring}", keepHeader:true)


        //
        // 2. Filter the BamFile (parallel)
        //

        SAMTOOLS_FILTER(bam)

        filterbam = SAMTOOLS_FILTER.out.bam.map{
            [it[0], it[1]]
        }

        // include the stats in the meta
        filterbam.combine( BAM_STATS.out.stats, by:0 )
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
        .map { meta, bam ->
            // rename the entry to fit the final report
            [
                meta + ["unique${filterstring}": meta.unique],
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