include { BAM_RMDUP }          from '../modules/local/bam_rmdup'
include { ANALYZE_BAM_CPP }    from '../modules/local/analyzebam_cpp'
include { GET_AVERAGE_LENGTH } from '../modules/local/perl_get_readlength'


workflow analyzeBAM {
    take:
        bam
        ch_targetfile

    main:

        // Some defs necessary for the writing to disc
        def outdir = "${params.reference_name}.${params.target_name}"
        def filterstring = "L${params.bamfilter_minlength}MQ${params.bamfilter_minqual}"

        bam = bam.map{ meta, bam ->
            [
                meta + ['filter':filterstring],
                bam
            ]
        }

        // add to the meta if we have a target or not!
        ch_analyzebam = bam.combine(ch_targetfile)
            .map{ meta, bam, target -> 
                [
                    meta+['target': target.baseName == 'no_target' ? false : true],
                    bam,
                    target
                ]
            }
            .multiMap{ meta, bam, targetfile ->
                bam: [meta, bam]
                target: [meta, targetfile]
            }

        //
        // 1. Get all the stats from the Bamfile
        //

        ANALYZE_BAM_CPP(ch_analyzebam.bam, ch_analyzebam.target)
        versions = ANALYZE_BAM_CPP.out.versions.first()

        ANALYZE_BAM_CPP.out.stats
            .map{it[1]}
            .collectFile(name: "summary_stats_${filterstring}.txt", storeDir:"${outdir}/AnalyzeBAM_${filterstring}", keepHeader:true)

        //
        // 2. Get the filtered BamFile
        //

        filterbam = ANALYZE_BAM_CPP.out.bam

        // include the stats in the meta
        filterbam.combine( ANALYZE_BAM_CPP.out.stats, by:0 )
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
                "in": vals["in"].replace(",",""), // corresponds to MappedBam
                "unique":vals["out"].replace(",",""), // corresponds to UniqueBam
                "singletons":vals["single@MQ20"].replace(",",""), // corresponds to singletons
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