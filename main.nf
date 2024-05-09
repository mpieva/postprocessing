#!/usr/bin/env nextflow

// include workflows for different executions of the pipeline
include { setup              } from './workflows/00_setup'
include { splitbam           }  from './workflows/01_splitbam'
include { splitdir           } from './workflows/01_splitdir'
include { bamfilter          } from './workflows/02_bamfilter'
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

def outdir = "reluctant_${workflow.manifest.version}"


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

bam        = params.bam      ? file( params.bam, checkIfExists:true) : ""
by         = params.rg       ? file( params.rg,  checkIfExists:true) : ""
split      = params.split    ? Channel.fromPath("${params.split}/*",     checkIfExists:true) : ""

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

    if (bam) {
        splitbam( bam,by )

        bam = splitbam.out.bams
        ch_versions = ch_versions.mix( splitbam.out.versions )
    }

    else {
        splitdir( split )

        bam = splitdir.out.bams
        ch_versions = ch_versions.mix( splitdir.out.versions )
    }

    //
    // 2. Filter the bam files
    //

    //include a meta-file with all fields existing
    bam.map {
        [
            it[0] + [
                "id":it[1].baseName.replace("sorted_",""),
                "RG":it[1].baseName.replace("sorted_",""),
            ],
            it[1]
        ]
    }
    .set{ bam }

    bamfilter( bam )

    analyzed_bam = bamfilter.out.bam
    ch_versions = ch_versions.mix( bamfilter.out.versions )

    //
    // 3. Calculate Subsitutions
    //

    substitutions(analyzed_bam)
    sub_bam = substitutions.out.bam
    sub_meta = sub_bam.map{meta, bam ->
            [['RG': meta.RG], meta]
        }
    ch_versions = ch_versions.mix( substitutions.out.versions )

    //
    // 4. Calculate conditional substitutions
    //

    cond_substitutions(analyzed_bam)
    cond_sub_bam = cond_substitutions.out.bam
    cond_sub_meta = cond_sub_bam.map{ meta, bam ->
        [['RG': meta.RG], meta]
    }
    ch_versions = ch_versions.mix( cond_substitutions.out.versions )

    //
    // 5. Filter deaminated
    //

    filter_deaminated(analyzed_bam)
    filter_bam = filter_deaminated.out.bam
    ch_versions = ch_versions.mix( filter_deaminated.out.versions )

    //
    // 6. Combine all the metas to gather the information
    //

    ch_meta = filter_bam.map{ [['RG': it[0].RG], it[0]] }
        .combine(sub_meta, by:0)
        .map{ key, meta1, meta2 ->
            [
                key,
                meta1+meta2
            ]
        }
        .combine(cond_sub_meta, by: 0)
        .map{ key, meta1, meta2 ->
            [
                key,
                meta1+meta2
            ]
        }

    //
    // TODO: Make the reports
    //

}
