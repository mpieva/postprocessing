include { FILTER_BAM as FILTER_BAM_DEAM3  } from '../modules/local/filterbam_cpp'
include { FILTER_BAM as FILTER_BAM_DEAM5  } from '../modules/local/filterbam_cpp'
include { GET_PATTERNS } from '../modules/local/perl_substitution_patterns'
include { SUMMARIZE_CT } from '../modules/local/perl_summarize_CT'


workflow cond_substitutions {
    take:
        bam

    main:

        def filterstring = "L${params.bamfilter_minlength}MQ${params.bamfilter_minqual}"
        def outdir = "${params.reference_name}.${params.target_name}"


        //
        // Filter bam files for damage for conditional substitutions
        //

        FILTER_BAM_DEAM3(bam)

        filterbam = FILTER_BAM_DEAM3.out.bam
            .map{[
                it[0]+['suffix':'deam3'],
                it[1]
            ]}
        versions = FILTER_BAM_DEAM3.out.versions.first()

        FILTER_BAM_DEAM5(bam)

        filterbam = filterbam.mix(
            FILTER_BAM_DEAM5.out.bam
                .map{[
                    it[0]+['suffix':'deam5'],
                    it[1]
                ]}
        )

        //
        // look at substitution patterns
        //

        GET_PATTERNS(filterbam)

        versions = versions.mix(GET_PATTERNS.out.versions.first())
        txt = GET_PATTERNS.out.txt

        SUMMARIZE_CT(txt)
        versions = versions.mix(SUMMARIZE_CT.out.versions.first())

        // include the stats in the meta
        filterbam.combine( SUMMARIZE_CT.out.txt, by:0 )
            .map{ meta, bam, stats ->
                def new_vals = [:]
                def vals = stats.splitCsv(sep:'\t', header:true).first() // first because the splitCsv results in [[key:value]]
                // make sure the values are safed in the same meta,
                // but with other column headers (suffix_...) otherwise old entries are overwritten
                for (k in vals) {
                    new_vals["${meta.suffix}_${k.key}"] = k.value
                }

                [
                    meta+new_vals,
                    bam
                ]
            }
            .set{ filterbam }

        SUMMARIZE_CT.out.txt
            .collectFile(
                name: "conditional_substitutions.${filterstring}.txt",
                storeDir:"${outdir}/Conditional_substitutions_${filterstring}",
                keepHeader:true,
                sort: true
            ) { it[1] }

    emit:
        bam = filterbam
        versions = versions
}