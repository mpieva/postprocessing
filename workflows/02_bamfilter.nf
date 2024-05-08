include { ANALYZE_BAM }  from '../modules/local/perl_analyzeBAM'


workflow bamfilter {
    take:
        bam

    main:
        //
        // filter the bam by running analyzeBAM
        //

        ANALYZE_BAM(bam)

        versions = ANALYZE_BAM.out.versions
        bam = ANALYZE_BAM.out.bam

    emit:
        bam = bam
        versions = versions
}