#!/usr/bin/env perl

use strict;

# A program that reads a BAM file and calculates the average length of the sequences in a given BAM file. The output is a text file with the average length of the sequences rounded to the 1st decimal point.

# How to calculate the average? First, we need a subroutine.

sub average {
    my $size = scalar (@_); # A total number of elements in an array
    my ($sum, $average);
    foreach my $number (@_) {
	$sum += $number; # Sum of all the numbers in an array
    }
    $average = $sum/$size;
}

# Internal control to see if the subroutine works :)
# my @does_it_work = &average (1..5);
# print "Your average is: @does_it_work\n";

# Using a subroutine that calculates the average, we can see what is the average length of  sequences in a given BAM file.

my @sequence_length;

foreach my $file_name (@ARGV) { # For each of the BAM files provided
    open FILEHANDLE, "samtools view $file_name |"; # Open a BAM file using a filehandle
    open OUTPUT, ">>average_seq_length.txt"; # Open a text file that will serve as an output
    while (<FILEHANDLE>) {
        my @fields = split; # Split the columns in a BAM file with whitespaces
        push (@sequence_length, length($fields[9])); # Puts the length of the sequences that are in the column 10 in a BAM file into the array sequence_lengths that was initially empty
    }
    my $average_sequence_length = 0;
    if (scalar(@sequence_length) != 0) {
        $average_sequence_length = &average (@sequence_length);
    }
    printf "$file_name: " . "%.1f\n" , $average_sequence_length;
    printf OUTPUT "$file_name: " . "%.1f\n" , $average_sequence_length;
    close FILEHANDLE;
    close OUTPUT;
    @sequence_length = ( );
}
