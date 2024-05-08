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
    println "[??]: ${red}${error}: ${text}${white}"
    exit 0
}
def get_warn_msg(text){
    return "[??]: ${yellow}(WARN): ${text}${white}"
}
def get_info_msg(text){
    return "[??]: ${text}"
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

def outdir = "quicksand_${workflow.manifest.version}"


if(params.split && (params.bam || params.rg)){
    log.info get_info_msg("Use: nextflow run mpieva/?? {--rg FILE --bam FILE | --split DIR}")
    exit_with_error_msg("ArgumentError", "Too many arguments")
}
if(!params.split && !(params.bam && params.rg)){
    log.info get_info_msg("Use: nextflow run mpieva/?? {--rg FILE --bam FILE | --split DIR}")
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
    meta = Channel.fromPath("$baseDir/assets/pipeline/meta.tsv").splitCsv(sep:'\t', header:true)
    bam.combine(meta).map{ m1, bam, meta -> [meta, bam] }.set{ bam }

    bam.map {
        [
            it[0] + [
                "id":it[1].baseName,
                "RG":it[1].baseName,
            ],
            it[1]
        ]
    }.set{ bam }
    bamfilter( bam )

    bam = bamfilter.out.bam
    ch_versions = ch_versions.mix( bamfilter.out.versions )

    //
    // 8. Run Deamination workflow
    //

    deamination_stats( best, deduped.fixed )

    // get the meta-table from the "best"-libraries
    best = deamination_stats.out.best.map{ it[0] }
    fixed = deamination_stats.out.fixed.map{ it[0] }

    ch_final.mix( best ).mix( fixed ).set{ch_final}

    //
    // 9. Write the output files
    //

    write_reports( ch_final, ch_versions )
}
