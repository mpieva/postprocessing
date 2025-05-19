# Ancient DNA postprocessing pipeline

This is a pipeline for the initial processing of BAM-files that are _not_ metagenomics samples. This currently includes _shotgun_ sequenced data and nuclear _capture_ data (based on a target file).

This pipeline produces only the **most basic** summary-statistics. Files should be already mapped to the correct reference genome!

### Workflow

The first version of the Shotgun Sequencing pipeline follows Matejas Labfolder Entry.

#### Preprocessing

- The run was mapped to `hg19_evan` with aDNA parameters
- adapters were trimmed with `leeHom`.

#### Pipeline

![Pipeline overview](assets/pipeline/pipeline_overview.svg)

#### Profiles

Profiles are available for different basic-processings and pre-set references/target-files.
The pipeline includes a basic verification that the references match!

1. Profile `shotgun` 

```
- Requires mapping to hg19_evan
- No target-file
```


#### Run the pipeline

```
nextflow run /mnt/scratch/merlin/software/run_postprocessing_pipeline/main.nf --split SPLIT -profile PROFILE

```

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
