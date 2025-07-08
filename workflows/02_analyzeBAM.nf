include { CHECK_HEADER       } from '../modules/local/header_check'
include { SAMTOOLS_INDEX     } from '../modules/local/samtools_index' 
include { BAM_RMDUP          } from '../modules/local/bam_rmdup'
include { ANALYZE_BAM_CPP    } from '../modules/local/analyzebam_cpp'
include { GET_AVERAGE_LENGTH } from '../modules/local/perl_get_readlength'
include { PLOT_READLENGTH    } from '../modules/local/pandas_plot_length'  


workflow analyzeBAM {
    take:
        ch_bam
        ch_targetfile

    main:

        // Some defs necessary for the writing to disc
        def outdir = "${params.reference_name}.${params.target_name}"
        def filterstring = "L${params.bamfilter_minlength}MQ${params.bamfilter_minqual}"

        ch_bam.map{ meta, bam ->
            [
                meta + ['filter':filterstring],
                bam
            ]
        }
        .set{ ch_bam }

        //
        // Header Check
        //

        CHECK_HEADER(ch_bam)

        echo = CHECK_HEADER.out.echo
        
        ch_bam.combine(echo, by:0)
            .map{ meta, bam, status -> 
                [
                    meta+['header_status':status.strip()],
                    bam
                ]
            }
            .set{ ch_bam }
        
        ch_analyzebam = ch_bam.combine(ch_targetfile)
            .multiMap{ meta, bam, targetfile ->
                bam: [meta, bam]
                target: targetfile
            }

        SAMTOOLS_INDEX(ch_analyzebam.bam)
        ch_indexed_bam = SAMTOOLS_INDEX.out.indexed

        //
        // 1. Get all the stats from the Bamfile
        //

        ANALYZE_BAM_CPP(ch_indexed_bam, ch_analyzebam.target)
        ch_versions = ANALYZE_BAM_CPP.out.versions.first()

        ANALYZE_BAM_CPP.out.stats
            .map{it[1]}
            .collectFile(name: "summary_stats_${filterstring}.txt", storeDir:"${outdir}/AnalyzeBAM_${filterstring}", keepHeader:true)

        
        PLOT_READLENGTH(ANALYZE_BAM_CPP.out.tsv)

        //
        // 2. Get the filtered BamFile
        //

        ch_filterbam = ANALYZE_BAM_CPP.out.bam

        // include the stats in the meta
        ch_filterbam.combine( ANALYZE_BAM_CPP.out.stats, by:0 )
        .map{ meta, bam, bai, stats ->
            def vals = stats.splitCsv(sep:'\t', header:true).first() // first because the splitCsv results in [[key:value]]
            [
                meta+vals,
                bam,
                bai
            ]
        }
        .set{ ch_filterbam }

        //
        // 3. Run Bam-rmdup
        //

        BAM_RMDUP(ch_filterbam)

        ch_uniqbam = BAM_RMDUP.out.bam

        //
        // 4. Get Post-Bam-rmdup stats
        //

        ch_uniqbam.combine( BAM_RMDUP.out.txt, by:0 )
        .map{ meta, bam, bai, stats ->
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
                bam,
                bai
            ]
        }
        .set{ ch_uniqbam }

        //
        // 5. Get average fragment length
        //

        GET_AVERAGE_LENGTH(ch_uniqbam)

        // save the output to the folder
        GET_AVERAGE_LENGTH.out.txt
            .map{it[1]}
            .collectFile(name: "average_fragment_length.${filterstring}.txt", storeDir:"${outdir}/AnalyzeBAM_${filterstring}")
        ch_versions = ch_versions.mix(GET_AVERAGE_LENGTH.out.versions.first())

        // save the length to the meta
        ch_uniqbam = ch_uniqbam.combine(GET_AVERAGE_LENGTH.out.txt, by:0)
            .map{ meta, bam, bai, txt ->
                [
                    meta+['average_fragment_length': txt.text.split(':')[1].trim() as float],
                    bam,
                    bai
                ]
            }

    emit:
        bam = ch_uniqbam
        versions = ch_versions
}