workflow write_reports {
    take: ch_final
    take: ch_versions
    main:

    def basedir = "reluctant_${workflow.manifest.version}"

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

    header_map = [
    'base' : ['raw', '&merged','&filter_passed', '&L35'].join('\t'),
    'maps' : ['mappedL35', 'mappedL35MQ25','%mappedL35MQ25', 'uniqueL35MQ25'].join('\t'),
    'dups' : ['average_dups', 'singletons','average_fragment_length'].join('\t'),
    'deam' : ['#deam_sequences_left','average_deam_fragment_length',
                "5'CT", "5'CT_95CI","5'#refC", "3'CT", "3'CT_95CI","3'#refC",
                "deam5_3'CT", "deam5_3'CT_95CI", "deam5_3'#refC",
                "deam3_5'CT", "deam3_5'CT_95CI", "deam3_5'#refC"
                ].join('\t')
    ]

    def getVals = {String header, meta, res=[] ->
        header.split('\t').each{res << meta[it]}
        res.join('\t')
    }

    ch_final
    .collectFile( name:"final_report.tsv",
        seed:[
        'RG',
        header_map['base'],
        header_map['maps'],
        header_map['dups'],
        header_map['deam'],
        ].join('\t'), storeDir:"${basedir}/", newLine:true, sort:true
    ){[
        it.RG,
        getVals(header_map['base'], it),
        getVals(header_map['maps'], it),
        getVals(header_map['dups'], it),
        getVals(header_map['deam'], it),
        ].join('\t')
    }
    .subscribe {
        println "[reluctant]: Summary reports saved"
    }
}
