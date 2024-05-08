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

-- WIP --

6. Compute conditional substitution patterns on the deduped, length and mapping quality filtered files

```

cd ..

mkdir Conditional_substitutions_L35MQ25

perl /home/mmeyer/perlscripts/solexa/analysis/filterBAM.pl -p3 0 -suffix deam3 ../AnalyzeBAM*L35MQ25/*.bam
perl /home/mmeyer/perlscripts/solexa/analysis/filterBAM.pl -p5 0 -suffix deam5../AnalyzeBAM*L35MQ25/*.bam
/home/mmeyer/perlscripts/solexa/analysis/substitution*patterns.pl -minread 35 -quality 25 *.bam
perl /home/mmeyer/perlscripts/solexa/analysis/summarize*CT_frequencies.pl -screen * -cond > conditional*substitutions.L35MQ25.txt
rm *bam *3p\* \_5p*

```

7. Filter for deaminated fragments only

```

mkdir FilterBAM_L35MQ25_3termini

/home/mmeyer/perlscripts/solexa/analysis/filterBAM.pl -p3 0,-1,-2 -p5 0,1,2 -suffix deam3_or_5 ../AnalyzeBAM_L35MQ25/\*.bam

for i in \*.bam; do samtools index ${i}; done

for i in \*.bam; do perl /home/mateja_hajdinjak/Scripts/mateja_basic_bam/average_length_of_sequences.pl ${i} >> average_fragment_length.L35MQ25.deam.txt; done

for i in \*.bam; do echo "${i}:" $(samtools view ${i} | wc -l) >> seq_number.L35MQ25.txt; done

rm average_seq\*
```
