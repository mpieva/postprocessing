## Ancient DNA preprocessing pipeline

This is a pipeline for the initial processing of sequencing runs that are _not_ metagenomics samples.
For example the shotgun sequencing of a human bone sample

### Workflow

The first version of the Shotgun Sequencing pipeline follows Matejas Labfolder Entry

#### Preprocessing

- The run was mapped to `hg19_evan` with aDNA parameters
- adapters were trimmed with `leeHom`.

#### Pipeline Start

1. Split the mapped BAM files according to the perfect index match using splitBAM.pl from Matthias.

(Use quicksand start)

```
/home/mmeyer/perlscripts/solexa/filework/splitBAM.pl -byfile indices_PA5304.txt /mnt/ngs_data/231009_NS500559_0194_AHMKC7AFX5_PEdi_PA5304/results/aligned/s_all_sequence_tagged_ancient_hg19_evan.bam > splitting_stats.txt
```

2. Alternatively: Start with already demultiplexed reads
   (Use quicksand start)

3. Compute index stats and cross contamination

(Use quicksand, include index_stats)

```
perl /home/mmeyer/perlscripts/solexa/analysis/indexstats.pl splitting_stats.txt > index_stats.txt

perl /home/mmeyer/perlscripts/solexa/analysis/cross_cont.pl splitting_stats.txt > cross_contamination.txt
```

4. filter-bam

Filter BAM files for minimum length of 35 bp, mapping quality of at least 25, and remove duplicates:

```
mkdir AnalyzeBAM_L35MQ25
/home/mmeyer/perlscripts/solexa/analysis/analyzeBAM.pl  -nof -minlength 35 -qual 25 ../SplitBAM/*.bam

# compute average length of sequences

for i in *.bam; do perl /home/mateja_hajdinjak/Scripts/mateja_basic_bam/average_length_of_sequences.pl ${i} >> average_fragment_length.L35MQ25.txt; done

rm average_seq_*

```

5. Compute substitution patterns on the deduped, length and mapping quality filtered files

```
mkdir Substitution_patterns_L35MQ25

/home/mmeyer/perlscripts/solexa/analysis/substitution_patterns.pl -minread 35 -quality 25 ../AnalyzeBAM_L35MQ25/*.bam

perl /home/mmeyer/perlscripts/solexa/analysis/summarize_CT_frequencies.pl -screen * > CT_substitutions.L35MQ25.txt

rm *3p* *5p*

```

6. Compute conditional substitution patterns on the deduped, length and mapping quality filtered files

```
cd ..

mkdir Conditional_substitutions_L35MQ25

perl /home/mmeyer/perlscripts/solexa/analysis/filterBAM.pl -p3 0 -suffix deam3 ../AnalyzeBAM_L35MQ25/*.bam
perl /home/mmeyer/perlscripts/solexa/analysis/filterBAM.pl -p5 0 -suffix deam5../AnalyzeBAM_L35MQ25/*.bam
/home/mmeyer/perlscripts/solexa/analysis/substitution_patterns.pl -minread 35 -quality 25 *.bam
perl /home/mmeyer/perlscripts/solexa/analysis/summarize_CT_frequencies.pl -screen * -cond > conditional_substitutions.L35MQ25.txt
rm *bam *3p* *5p*
```

7. Filter for deaminated fragments only

```
mkdir FilterBAM_L35MQ25_3termini

/home/mmeyer/perlscripts/solexa/analysis/filterBAM.pl -p3 0,-1,-2 -p5 0,1,2 -suffix deam3_or_5 ../AnalyzeBAM_L35MQ25/*.bam

for i in *.bam; do samtools index ${i}; done

for i in *.bam; do perl /home/mateja_hajdinjak/Scripts/mateja_basic_bam/average_length_of_sequences.pl ${i} >> average_fragment_length.L35MQ25.deam.txt; done

for i in *.bam; do echo "${i}:" $(samtools view ${i} | wc -l) >> seq_number.L35MQ25.txt; done

rm average_seq*
```
