#!/usr/bin/env perl

#analyzeBAM.pl
#written by Matthias Meyer 10.03.2013
#modified 20240522 by Merlin Szymanski
use strict;
use Getopt::Long;
use File::Basename;

my $minlength = 0;
my $maxlength;
my $minmapqual = 0;
my $paired;
my $filter = "";

GetOptions (
    "minlength=i" => \$minlength,
    "maxlength=i" => \$maxlength,
    "paired" => \$paired,
    "quality=i" => \$minmapqual,
    "filter=s" => \$filter
);

my @bamfiles = @ARGV;

###Start iterating over bam files
print STDOUT join ("\t", "#file", "raw", "&merged", "&filter_passed", "&L$minlength", "mappedL$minlength", "mappedL${minlength}MQ$minmapqual", "%mappedL${minlength}MQ${minmapqual}\n");

my %counts;

foreach my $bamfile (@bamfiles) {
    my $outname = basename ($bamfile);
    open(BAM, '<', "$bamfile");

###Go through bam file########
    %counts = ();
    while (my $line = <BAM>) {
        # Skip header
	    if ($line =~ /^\@/) {
	        next;
	    }
	    my @tmp = split /\t/, $line;

	    my ($flag, $chromosome, $start, $mapq, $length, $cigar, $header) = ($tmp[1], $tmp[2], $tmp[3], $tmp[4], length ($tmp[9]), $tmp[5], $tmp[0]);

        $flag = &decode_flag($flag);

        ### filterflags

        unless ($paired) {
            next if $flag =~ /2/; # all reverse reads are discarded at the start
            $counts{$outname}{"raw"}++;
            next if $flag =~ /1/;
            $counts{$outname}{"merged"}++;
        } else {
            $counts{$outname}{"raw"}++;
            unless ($flag =~ /p/) {
                $counts{$outname}{"merged"}++;
            }
        }


        # filter vendor
	    next if $flag =~ /f/;
        $counts{$outname}{"filtered"}++;

        # filter length
        next if $length < $minlength;
	    if ($maxlength) {
	        next if $length > $maxlength;
	    }
	    $counts{$outname}{"filteredL"}++;

        # filter unmapped
	    next if $flag =~ /u/;
	    next if $chromosome !~ /$filter/; #keep only chromosomes
	    $counts{$outname}{"filteredLmapped"}++;

        # filter quality
	    next if $mapq < $minmapqual;
	    $counts{$outname}{"filteredLmappedQ"}++;


    }
    close BAM;

    print STDOUT join ("\t",
		      $outname,
		      $counts{$outname}{"raw"} || 0,
		      $counts{$outname}{"merged"} || 0,
		      $counts{$outname}{"filtered"} || 0,
		      $counts{$outname}{"filteredL"} || 0,
		      $counts{$outname}{"filteredLmapped"} || 0,
		      $counts{$outname}{"filteredLmappedQ"} || 0);
    if ($counts{$outname}{"filteredL"} > 0) {
	    my $percent = sprintf("%.3f", $counts{$outname}{"filteredLmappedQ"} / $counts{$outname}{"filteredL"} * 100);
	    print STDOUT "\t", $percent;
    } else {
	    print STDOUT "\tNA";
    }
    print STDOUT "\n";
}

sub decode_flag {
    my $hex = shift(@_);
    my $bin = sprintf "%b", $hex;
    my $literal = "qdfs21RrUuPp";
    my $string;
    foreach my $pos (-length($bin) .. -1) {
        $string .= substr $literal, $pos, 1 if (substr $bin, $pos, 1);
    }
    return $string || "_";
}

sub help {
    print"
[options]
-minlength      minimum length filter [default 35]
-maxlength      maximum length filter [default OFF]
-qual           minimum map quality filter [default 0]
-paired         do not disregard paired reads (but all reverse reads are disregarded in counting)
-filter         positive filter expression on reference name
";
exit;
}
