include { FILTER_BAM         } from '../modules/local/perl_filterBAM'
include { GET_AVERAGE_LENGTH } from '../modules/local/perl_get_readlength'
include { SAMTOOLS_COUNT     } from '../modules/local/samtools_count'

workflow filter_deaminated {
    take:
        bam

    main:
        //
        // Filter bam files for damage for conditional substitutions
        //

        FILTER_BAM(bam)

        filterbam = FILTER_BAM.out.bam
        versions = FILTER_BAM.out.versions.first()

        GET_AVERAGE_LENGTH(filterbam)

        // save the output to the folder
        def outdir = "reluctant_${workflow.manifest.version}"

        GET_AVERAGE_LENGTH.out.txt
            .map{it[1]}
            .collectFile(name: 'average_fragment_length.L35MQ25.deam.txt', storeDir:"${outdir}/FilterBAM_L35MQ25_3termini")
        versions = versions.mix(GET_AVERAGE_LENGTH.out.versions.first())

        // save the length to the meta
        filterbam = filterbam.combine(GET_AVERAGE_LENGTH.out.txt, by:0)
            .map{ meta, bam, txt ->
                [
                    meta+['average_deam_fragment_length': txt.text.split(':')[1].trim() as float],
                    bam
                ]
            }

        // Count the number of deaminated fragments
        SAMTOOLS_COUNT(filterbam)
        filterbam = SAMTOOLS_COUNT.out.bam.map { meta, bam, count ->
            [ meta+['#deam_sequences_left': count as int], bam ]
        }
        // And write to file
        filterbam.collectFile(
            name: 'seq_number.L35MQ25.txt',
            storeDir:"${outdir}/FilterBAM_L35MQ25_3termini",
            newLine: true) {
            "${it[0].RG}: ${it[0].AncientReads}"
        }

        versions = versions.mix(SAMTOOLS_COUNT.out.versions.first())

    emit:
        bam = filterbam
        versions = versions
}