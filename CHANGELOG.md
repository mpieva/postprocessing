# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## v0.12 [30.03.2026]

- Full containerization of all pipeline processes.
- Full switch to Yanivs c++ implementations of aDNA tools 
- Add Elephant, Rat and Varanus profiles

### Updates
- Replace average-sequence-length perl-script with containerized samtools/awk function
- Update version of ancient_dna_cpp_tools
    - Remove the compiled binaries and the src (ancient_dna_cpp_tools) from this repo
    - Run ancient_dna_cpp_tools in a containerized environment (see [Dockerfile](assets/docker/analyzebam_cpp_dockerfile))
- For non-circular reference genomes, replace bam-rmdup with dedupBam v0.21 (ancient_dna_cpp_tools). 
    - Force the use of bam-rmdup with the `--deduplication_tool bam-rmdup` flag
- Add more profiles
    - `shotgun_loxAfr4` (Elephant) 
    - `shotgun_ratNor6` (Rat)
    - `shotgun_varKom` (Varanus)


## v0.11 [11.11.2025]

### Bugfixes

- Fix processing of files that have no ontarget-sequences -> or 'null' ontarget-sequences (e.g. in shotgun profile)

## v0.10

### Bugfixes

- Fix processing of files that have no ontarget-sequences
- Skip deam-plotting for empty files
- fix size-bin calculation for single-read BAM files

## v0.9 [16.10.2025]

- Add the 'AA288_AA292_archaicPlus' profile

## v0.8 [05.08.2025]

- Fix the bamrmdup_circular flag (was not working before)
- Add the 'AA163_humanMT' profile

## v0.7 [04.08.2025]

Minor changes related to naming of output-files and table-headers

- include the processing parameters in the 'final_report.tsv' filename (#1)
- remove single quotes from header names (make parsing easier)
- add coreDB Ids in the final report

### Changes

## v0.6 [08.07.2025]

### Critical Bugfix
- Fix duplicated meta-namespace in the analyzeBAM module, causing a swap in meta-maps, causing random swaps of IDs (RGs) and the calculated values in both the filenames and in the final report!. True IDs are only preserved in the headers of the BAM files from before the pipeline.  

## v0.5 [26.05.2025]

### Changes
- replace filterBam and subsitution pattern perl-scripts with Yanivs C++ versions
- plot read-length distribution after analyzeBAM
- plot deamination patterns by read-length
- update profiles: Twist_1240k, AA213_1240k

## v0.4 [20.05.2025]

Cleanup and Consistent file-naming

### Changes
- include `ontarget` in the filename is target-file is provided
- fix a few 'null' values in output files
- include the reference-file name in the final report
- add a cheap bam-header-check to see if the bam file was actually mapped to the required reference

## v0.3 [19.05.2025]

Use the C++ implementation of analyzeBam (written by Yaniv) for processing

### Changes

- **Replace the analyzeBAM workflow**
  1. Use Yanivs analyzeBAM rewrite [github](https://github.com/yanivsw/ancient_dna_cpp_tools)
  2. This results in a slighly different naming of the columns in the output tables ("merged" instead of "&merged")
  3. include the 'shotgun' and 'archaicAdmixture' profile

## v0.2 [31.05.2024]

This is a working version of a very basic sequencing postprocessing pipeline.See the README for the BPMN diagram of the pipeline

### Changes

- **Replace Matthias analyzeBAM script** with three fixed steps
  1. First part of AnalyzeBAM.pl that prints all the counts
  2. in parallel samtools view for applying all filters at once
  3. bam-rmdup on the filtered bamfile
     - Doesnt open the bamfile again after bam-rmdup but parses the bam-rmdup txt output for the post-deduplication stats
- include a **chromosome filter** to filter by default for X,Y or autosomes

## v0.1

This is the working version of a basic sequencing postprocessing pipeline.

- see the README for a overview of the existing steps
