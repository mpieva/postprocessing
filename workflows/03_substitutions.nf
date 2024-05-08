include { GET_PATTERNS }  from '../modules/local/perl_substitution_patterns'
include { SUMMARIZE_CT }  from '../modules/local/perl_summarize_CT'


workflow substitutions {
    take:
        bam

    main:
        //
        // look at substitution patterns
        //

        GET_PATTERNS(bam)

        versions = GET_PATTERNS.out.versions.first()
        txt = GET_PATTERNS.out.txt

        SUMMARIZE_CT(txt)
        versions = SUMMARIZE_CT.out.versions.first()

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

        // save the stats to the dir
        def outdir = "reluctant_${workflow.manifest.version}"

        SUMMARIZE_CT.out.txt
            .map{it[1]}
            .collectFile(name: 'CT_substitutions.L35MQ25.txt', storeDir:"${outdir}/Substitution_patterns_L35MQ25", keepHeader:true)

    emit:
        bam = bam
        versions = versions
}