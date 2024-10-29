workflow write_reports {
    take: ch_final
    take: ch_versions
    main:

    def basedir = "${params.reference}.${params.target}.proc${workflow.manifest.version}"
    def filterstring = "L${params.bamfilter_minlength}MQ${params.bamfilter_minqual}"

    //
    //
    // Write Reports
    //
    //

    // write the reports to file...
    ch_versions.unique().collectFile(name: 'pipeline_versions.yml', storeDir:"${basedir}/nextflow")

    //
    // Write now all the data to files!
    //


    //
    // this map contains the desired column names for the final report
    //
    header_map = [
    'base' : ['raw', 'merged','filter_passed', "L${params.bamfilter_minlength}"].join('\t'),
    'maps' : ["mappedL${params.bamfilter_minlength}", "mapped${filterstring}", "%mapped${filterstring}", "unique${filterstring}",'singletons', 'average_dups', 'average_fragment_length'].join('\t'),
    'deam' : ['#deam_sequences_left','average_deam_fragment_length',
                "5'CT", "5'CT_95CI","5'#refC", "3'CT", "3'CT_95CI","3'#refC",
                "deam5_3'CT", "deam5_3'CT_95CI", "deam5_3'#refC",
                "deam3_5'CT", "deam3_5'CT_95CI", "deam3_5'#refC"
                ].join('\t')
    ]
    //
    // if the keys in the meta dont match the desired columns, map here the meta keys to the values here...
    //
    value_map = [
        'maps' : ["mappedL${params.bamfilter_minlength}", "mapped${filterstring}", "%mapped${filterstring}", "unique", "singletons", 'average_dups', 'average_fragment_length'].join('\t'),
    ]

    def getVals = {String key, meta, res=[] ->
        if(value_map[key]) {
            header = value_map[key]
        } else {
            header = header_map[key]
        }
        // then
        header.split('\t').each{
            def entry_key = it.trim()
            res << meta[entry_key]
            }
        res.join('\t')
    }

    ch_final
    .collectFile( name:"final_report.tsv",
        seed:[
        'RG',
        header_map['base'],
        header_map['maps'],
        header_map['deam'],
        ].join('\t'), storeDir:"${basedir}/", newLine:true, sort:true
    ){[
        it.RG,
        getVals('base', it),
        getVals('maps', it),
        getVals('deam', it),
        ].join('\t')
    }
    .subscribe {
        println "[reluctant]: Summary reports saved"
    }
}
