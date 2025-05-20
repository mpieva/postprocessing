# Ancient DNA postprocessing pipeline

A nextflow pipeline for the basic post-processing of human shotgun or capture libraries (_not_ metagenomics samples). See pipeline-overview below.

## Execution

```
NXF_VER=24.04.4 nextflow run /mnt/scratch/merlin/software/run_postprocessing_pipeline/main.nf --split SPLIT -profile PROFILE [OPTIONS]

```
### SPLIT

The pipeline works on a directory of already demultiplexed and mapped BAM-files, provide the directory with the `--split` flag


### PROFILE and OPTIONS

Profiles are pre-settings for different use cases. At the moment this contains 

1. The mapping reference (the pipeline does a check if the references match)
2. The target-file (to filter for on-target reads)

please run 

```
nextflow run /mnt/scratch/merlin/software/run_postprocessing_pipeline/main.nf --help

```

to see all the available profiles and options!

## Pipeline

![Pipeline overview](assets/pipeline/pipeline_overview.svg)






#### Default filters

- minimum-length: 35
- minimum-quality: 25
- Only mapped
- Only merged
- Vendor OK (Illumina)
- Mapping to X,Y or Autosome

#### Contributions

- Mateja (Outline of pipeline, AverageLength)
- Yaniv (AnalyzeBam)
- Matthias (AnalyzeBam, FilterBam, SplitBAM)
