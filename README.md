## Ancient DNA preprocessing pipeline

This is a pipeline for the initial processing of sequencing runs that are _not_ metagenomics samples.
For example the shotgun sequencing of a human bone sample

### Workflow

The first version of the Shotgun Sequencing pipeline follows Matejas Labfolder Entry

#### Preprocessing

- The run was mapped to `hg19_evan` with aDNA parameters
- adapters were trimmed with `leeHom`.

#### Pipeline

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
- Matthias (AnalyzeBam, FilterBam, SplitBAM)
