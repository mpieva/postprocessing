include { GET_PATTERNS }  from '../modules/local/perl_substitution_patterns'
include { SUMMARIZE_CT }  from '../modules/local/perl_summarize_CT'


workflow substitutions {
    take:
        bam

    main:

        def filterstring = "L${params.bamfilter_minlength}MQ${params.bamfilter_minqual}"
        def outdir = "${params.reference}.${params.target}.proc${workflow.manifest.version}"


        //
        // look at substitution patterns
        //

        GET_PATTERNS(bam)

        versions = GET_PATTERNS.out.versions.first()
        txt = GET_PATTERNS.out.txt

        SUMMARIZE_CT(txt)
        versions = versions.mix(SUMMARIZE_CT.out.versions.first())

        // include the stats in the meta
        bam.combine( SUMMARIZE_CT.out.txt, by:0 )
            .map{ meta, bam, stats ->
                def vals = stats.splitCsv(sep:'\t', header:true).first() // first because the splitCsv results in [[key:value]]
                [
                    meta+vals,
                    bam
                ]
            }
            .set{ bam }

        SUMMARIZE_CT.out.txt
            .map{it[1]}
            .collectFile(name: "CT_substitutions.${filterstring}.txt", storeDir:"${outdir}/Substitution_patterns_${filterstring}", keepHeader:true)

    emit:
        bam = bam
        versions = versions
}