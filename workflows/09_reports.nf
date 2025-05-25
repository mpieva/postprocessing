workflow write_reports {
    take: ch_final
    take: ch_versions
    main:

    def outdir = "${params.reference_name}.${params.target_name}"
    def filterstring = "L${params.bamfilter_minlength}MQ${params.bamfilter_minqual}"

    //
    //
    // Write Reports
    //
    //

    ch_final.map{ meta -> 
        meta + [
            'panel':params.target_name 
        ]
    }.set{ch_final}

    // write the reports to file...
    ch_versions.unique().collectFile(name: 'pipeline_versions.yml', storeDir:"${outdir}/nextflow")

    //
    // Write now all the data to files!
    //


    //
    // this map contains the desired column names for the final report
    //
    header_map = [
    'base' : ['raw', 'merged','filter_passed', "L${params.bamfilter_minlength}"].join('\t'),
    'maps' : [
        "reference","reference_check",
        "mappedL${params.bamfilter_minlength}", "mapped${filterstring}", "%mapped${filterstring}", "panel", "target${filterstring}",
        "unique${filterstring}",'singletons', 'average_dups', 'average_fragment_length'].join('\t'),
    'deam' : ['#deam_sequences_left','average_deam_fragment_length',
                "5'CT", "5'CT_95CI","5'#refC","cond5'CT", "cond5'CT_95CI", "cond5'#refC", 
                "3'CT", "3'CT_95CI","3'#refC","cond3'CT", "cond3'CT_95CI", "cond3'#refC"
                ].join('\t')
    ]
    //
    // if the keys in the meta dont match the desired columns, map here the meta keys to the values...
    //
    value_map = [
        'maps' : [
            "reference_file","header_status",
            "mappedL${params.bamfilter_minlength}", "mapped${filterstring}", "%mapped${filterstring}", "panel", "in", // 'in' is what goes into bam-rmdup and its either the number of on-target or the mapped 
            "unique", "singletons", 'average_dups', 'average_fragment_length'].join('\t'),
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
        ].join('\t'), storeDir:"${outdir}/", newLine:true, sort:true
    ){[
        it.RG,
        getVals('base', it),
        getVals('maps', it),
        getVals('deam', it),
        ].join('\t')
    }
    .subscribe {
        println "[postprocessing]: Summary reports saved"
    }
}
