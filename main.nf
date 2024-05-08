#!/usr/bin/env nextflow

// include workflows for different executions of the pipeline
include { setup             } from './workflows/00_setup'
include { splitbam          } from './workflows/01_splitbam'
include { splitdir          } from './workflows/01_splitdir'
include { bamfilter         } from './workflows/02_bamfilter'

include { deamination_stats } from './workflows/08_deamination_stats'
include { write_reports     } from './workflows/09_reports.nf'

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

    // collect sorted bams
    bam = bam.map{ it[1] }.collect()
    bam = bam.map{ [[:], it] }

    bamfilter( bam )

    bam = bamfilter.out.bam
    ch_versions = ch_versions.mix( bamfilter.out.versions )

}
