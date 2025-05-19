#!/usr/bin/env nextflow

// include workflows for different executions of the pipeline
include { setup              } from './workflows/00_setup'
include { splitbam           } from './workflows/01_splitbam'
include { splitdir           } from './workflows/01_splitdir'
include { analyzeBAM         } from './workflows/02_analyzeBAM'
include { substitutions      } from './workflows/03_substitutions'
include { cond_substitutions } from './workflows/04_conditional_substitutions'
include { filter_deaminated  } from './workflows/05_filter_deaminated'
include { write_reports      } from './workflows/09_reports.nf'

//The colors
red = "\033[0;31m"
white = "\033[0m"
yellow = "\033[0;33m"

// Define some functions

def exit_with_error_msg(error, text){
    println "[reluctant]: ${red}${error}: ${text}${white}"
    exit 0
}
def get_warn_msg(text){
    return "[reluctant]: ${yellow}(WARN): ${text}${white}"
}
def get_info_msg(text){
    return "[reluctant]: ${text}"
}
def exit_missing_required(flag){
    exit_with_error_msg("ArgumentError", "missing required argument ${flag}")
}

//
//
// Help
//
//

if (params.help){
    print file("$baseDir/assets/pipeline/help.txt").text
    exit 0
}

//
//
// Validation of input parameters
//
//

if(params.split && (params.bam || params.rg)){
    log.info get_info_msg("Use: nextflow run mpieva/reluctant {--rg FILE --bam FILE | --split DIR}")
    exit_with_error_msg("ArgumentError", "Too many arguments")
}
if(!params.split && !(params.bam && params.rg)){
    log.info get_info_msg("Use: nextflow run mpieva/reluctant {--rg FILE --bam FILE | --split DIR}")
    exit_with_error_msg("ArgumentError", "Too few arguments")
}

//
//
// input Channels
//
//

ch_bam        = params.bam          ? file( params.bam, checkIfExists:true) : ""
ch_by         = params.rg           ? file( params.rg,  checkIfExists:true) : ""
ch_split      = params.split        ? Channel.fromPath("${params.split}/*", checkIfExists:true) : ""
ch_targetfile = params.target_file  ? Channel.fromPath("${params.target_file}", checkIfExists:true) : []

ch_versions = Channel.empty()
ch_final = Channel.empty()


//
//
// The main workflow
//
//

workflow {

    //
    // 0. Setup the folders etc.
    //

    setup([])

    //
    // 1. Input Processing ~ Input Parameters
    //

    if (ch_bam) {
        splitbam( ch_bam, ch_by )

        ch_bam = splitbam.out.bams
        ch_versions = ch_versions.mix( splitbam.out.versions )
    }

    else {
        splitdir( ch_split )

        ch_bam = splitdir.out.bams
        ch_versions = ch_versions.mix( splitdir.out.versions )
    }

    //
    // 2. Filter the bam files
    //

    //include a meta-file with all fields existing
    ch_bam.map {
        [
            it[0] + [
                "id":it[1].baseName.replace("sorted_",""),
                "RG":it[1].baseName.replace("sorted_",""),
            ],
            it[1]
        ]
    }
    .set{ ch_bam }

    analyzeBAM( ch_bam, ch_targetfile )

    ch_analyzed_bam = analyzeBAM.out.bam
    ch_versions = ch_versions.mix( analyzeBAM.out.versions )

    //
    // 3. Calculate Subsitutions
    //

    substitutions(ch_analyzed_bam)
    ch_sub_bam = substitutions.out.bam
    ch_sub_meta = ch_sub_bam.map{meta, bam ->
            [['RG': meta.RG], meta]
        }
    ch_versions = ch_versions.mix( substitutions.out.versions )

    //
    // 4. Calculate conditional substitutions
    //

    cond_substitutions(ch_analyzed_bam)
    ch_cond_sub_bam = cond_substitutions.out.bam

    ch_cond_sub_meta = ch_cond_sub_bam
        .map{ meta, bam ->
            [['RG': meta.RG], meta]
        }
        .groupTuple(by:0) // get deam3 and deam5 back into one entry
        .map{ key, metas ->
            [
                key,
                metas[0]+metas[1]
            ]
        }

    ch_versions = ch_versions.mix( cond_substitutions.out.versions )

    //
    // 5. Filter deaminated
    //

    filter_deaminated(ch_analyzed_bam)
    ch_filter_bam = filter_deaminated.out.bam
    ch_versions = ch_versions.mix( filter_deaminated.out.versions )

    //
    // 6. Combine all the metas to gather the information
    //

    ch_meta = ch_filter_bam.map{ [['RG': it[0].RG], it[0]] }
        .combine(ch_sub_meta, by:0)
        .map{ key, meta1, meta2 ->
            [
                key,
                meta1+meta2
            ]
        }
        .combine(ch_cond_sub_meta, by: 0)
        .map{ key, meta1, meta2 ->
            meta1+meta2
        }

    //
    // 9. Make the reports
    //
    write_reports(ch_meta, ch_versions)

}
