include { ANALYZE_BAM }  from '../modules/local/perl_analyzeBAM'


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

    emit:
        bam = bam
        versions = versions
}