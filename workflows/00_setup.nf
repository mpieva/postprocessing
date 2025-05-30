cyan = "\033[0;36m"
red = "\033[0;31m"
white = "\033[0m"
yellow = "\033[0;33m"

workflow setup {
    take: setup
    main:
        // write the commandline down
        log.info """
  [postprocessing]: Execution started: ${workflow.start.format('dd.MM.yyyy HH:mm')} ${cyan}
  ${white}${workflow.manifest.description} ${cyan}~ Version ${workflow.manifest.version} ${white}

 --------------------------------------------------------------
        """

        //
        //
        // Additional Setup, Copy Files etc.
        //
        //
        def outdir = "${params.reference_name}.${params.target_name}"
        def start = workflow.start.format('yyyyMMdd_HHmmss')

        def commandFile = new File("${outdir}/nextflow/${start}_commands.txt")
        // create the nextflow dir if it doesnt exist yet
        if(!commandFile.getParentFile().exists()) {
            commandFile.getParentFile().mkdirs();
        }
        // write the pipeline run info to file
        commandFile << "# User\t${workflow.userName}\n"
        commandFile << "# Date/Time\t${workflow.start.format('yyyy-MM-dd HH:mm:ss')}\n"
        commandFile << "# Git Revision\t${workflow.commitId ?: 'local run'} (${workflow.revision ?: 'No version'})\n"
        commandFile << "# Target File: ${params.target_file}\n"
        commandFile << "# Reference 4 Check: ${params.reference_file}\n"
        commandFile << "${workflow.commandLine}\n"       

        if( workflow.configFiles.size > 1 ){
            // configFiles[0] is the nextflow.config in the repository...
            // configFiles[1] is the one handed over with the -c flag
            def newconf = new File(workflow.configFiles[1] as String)
            def copyconf = new File("${outdir}/nextflow/${start}.config")

            copyconf << newconf.text
        }
}