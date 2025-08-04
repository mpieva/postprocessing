#!/usr/bin/env nextflow

// include workflows for different executions of the pipeline
include { setup              } from './workflows/00_setup'
include { splitbam           } from './workflows/01_splitbam'
include { splitdir           } from './workflows/01_splitdir'
include { analyzeBAM         } from './workflows/02_analyzeBAM'
include { substitutions      } from './workflows/03_substitutions'
include { filter_deaminated  } from './workflows/05_filter_deaminated'
include { write_reports      } from './workflows/09_reports.nf'

//The colors
red = "\033[0;31m"
white = "\033[0m"
yellow = "\033[0;33m"

// Define some functions

def exit_with_error_msg(error, text){
    println "[postprocessing]: ${red}${error}: ${text}${white}"
    exit 0
}
def get_warn_msg(text){
    return "[postprocessing]: ${yellow}(WARN): ${text}${white}"
}
def get_info_msg(text){
    return "[postprocessing]: ${text}"
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
    log.info get_info_msg("Use: nextflow run mpieva/postprocessing {--rg FILE --bam FILE | --split DIR}")
    exit_with_error_msg("ArgumentError", "Too many arguments")
}
if(!params.split && !(params.bam && params.rg)){
    log.info get_info_msg("Use: nextflow run mpieva/postprocessing {--rg FILE --bam FILE | --split DIR}")
    exit_with_error_msg("ArgumentError", "Too few arguments")
}

//
//
// input Channels
//
//

ch_bam        = params.bam            ? file( params.bam, checkIfExists:true) : ""
ch_by         = params.rg             ? file( params.rg,  checkIfExists:true) : ""
ch_split      = params.split          ? Channel.fromPath("${params.split}/*", checkIfExists:true) : ""
ch_targetfile = params.target_file    ? Channel.fromPath("${params.target_file}", checkIfExists:true) : Channel.fromPath("${baseDir}/assets/pipeline/no_target.bed")
ch_reference  = Channel.fromPath("${params.reference_file}", checkIfExists:true) 

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

    //Take the time to fill the meta-map with some information
    ch_bam.map { it ->
        def file = it[1]
        def name = file.baseName.replace("sorted_", "")
        
        // Regex to extract the coredb ID (e.g., Lib.P.9540 or Cap.A.1234)
        def matcher = name =~ /(Lib|Cap)[_.]?([A-Z])[_.]?(\d+)/
        def coredb_id = matcher.find() ? "${matcher.group(1)}.${matcher.group(2)}.${matcher.group(3)}" : null

        [
            it[0] + [
                "id"            : name,
                "RG"            : name,
                "file"          : name,
                "reference"     : params.reference_name,
                "reference_file": params.reference_file,
                "target"        : params.target_file ? true : false,
                "ontarget"      : params.target_file ? '.ontarget' : '',
                "coredb"        : coredb_id
            ],
            file
        ]
    }
    .set{ ch_bam }

    analyzeBAM( ch_bam, ch_targetfile )

    ch_analyzed_bam = analyzeBAM.out.bam
    ch_versions = ch_versions.mix( analyzeBAM.out.versions )

    //
    // 3. Calculate Subsitutions
    //

    substitutions(ch_analyzed_bam, ch_reference)
    //ch_sub_bam = substitutions.out.bam
    ch_sub_meta = substitutions.out.meta.map{ meta ->
        [['RG':meta.RG], meta]
    }
    //ch_versions = ch_versions.mix( substitutions.out.versions )

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
            meta1+meta2
        }

    //
    // 9. Make the reports
    //

    write_reports(ch_meta, ch_versions)

}
