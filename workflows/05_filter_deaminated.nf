include { FILTER_BAM_CPP     } from '../modules/local/filterbam_cpp'
include { GET_AVERAGE_LENGTH } from '../modules/local/perl_get_readlength'
include { SAMTOOLS_COUNT     } from '../modules/local/samtools_count'

workflow filter_deaminated {
    take:
        bam

    main:

        def filterstring = "L${params.bamfilter_minlength}MQ${params.bamfilter_minqual}"
        def outdir = "results.${params.reference_name}.${params.target_name}"


        //
        // Filter bam files for damage for conditional substitutions
        //

        FILTER_BAM_CPP(bam)

        filterbam = FILTER_BAM_CPP.out.bam
        versions = FILTER_BAM_CPP.out.versions.first()

        GET_AVERAGE_LENGTH(filterbam)

        // save the output to the folder
        GET_AVERAGE_LENGTH.out.txt
            .map { "${it[0].id}\t${it[1].text.trim()}\n" }
            .collectFile(name: "average_fragment_length.${filterstring}.deam.txt", storeDir:"${outdir}/FilterBAM_${filterstring}_3termini")

        // save the length to the meta
        filterbam = filterbam.combine(GET_AVERAGE_LENGTH.out.txt, by:0)
            .map{ meta, bam, bai, txt ->
                [
                    meta+['average_deam_fragment_length': txt.text as float],
                    bam,
                ]
            }

        // Count the number of deaminated fragments
        SAMTOOLS_COUNT(filterbam)
        filterbam = SAMTOOLS_COUNT.out.bam.map { meta, bam, count ->
            [ meta+['#deam_sequences_left': count as int], bam ]
        }
        // And write to file
        filterbam.collectFile(
            name: "seq_number.${filterstring}.txt",
            storeDir:"${outdir}/FilterBAM_${filterstring}_3termini",
            newLine: true) {
            "${it[0].RG}: ${it[0]["#deam_sequences_left"]}"
        }

        versions = versions.mix(SAMTOOLS_COUNT.out.versions.first())

    emit:
        bam = filterbam
        versions = versions
}