# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## v0.5 [26.05.2025]

### Changes
- replace filterBam and subsitution pattern perl-scripts with Yanivs C++ versions
- plot read-length distribution after analyzeBAM
- plot deamination patterns by read-length
- update profiles (Reich_1240k)

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
  1. Use Yanivs analyzeBAM rewrite [gitlab](https://vcs.eva.mpg.de/yaniv_swiel/analysebam_cpp)
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
