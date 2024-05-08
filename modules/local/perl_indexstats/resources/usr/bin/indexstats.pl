#! /usr/bin/env perl

use strict;

my $top = 10;

my (%stats, $total, %matrix, %norm,%unexpected_pair, %expected_p7, %expected_p5, %expected_rg, %unexpected_rg, %p5_to_p7, %index_to_rg, $dual_use, %cross);

&help unless $ARGV[0];

open READ, $ARGV[0] or die "no input file\n";
while (my $line = <READ>) {
    chomp $line;
    next unless $line =~ /^\d/;
    my ($number, $p7seq, $p7ind, $p5seq, $p5ind, $rg) = split /\t/, $line;
    $stats{"raw"} += $number;
    next if $p7seq =~ /N/; #disregard all indices with N
    next if $p5seq =~ /N/;
    $total += $number;
    my $p7_ident = 0;
    $p7_ident = 1 unless $p7ind =~ /-/;
    my $p5_ident = 0;
    $p5_ident = 1 unless $p5ind =~ /-/;
    my $lib = 0;
    if ($p7ind =~ /phix/i && $p5ind =~ /phix/i) {
	$stats{"expected_pair"} += $number;
	next;
    }
    $lib = 1 unless $rg eq "unknown" || $rg eq "unexpected";
    if ($lib) {
	$expected_rg{$rg}{"p7"} = $p7ind;
	$expected_rg{$rg}{"p5"} = $p5ind;
	$expected_rg{$rg}{"count"} = $number;
	$p5_to_p7{$p5ind} = $p7ind;
	$index_to_rg{"$p7ind.$p5ind"} = $rg;
	$stats{"expected_pair"} += $number;
	if (exists $expected_p7{$p7ind} || $expected_p5{$p5ind}) {
	    $dual_use++;
	}
	$expected_p7{$p7ind}++;
	$expected_p5{$p5ind}++;
	$norm{"sum"} += $number;
	$norm{"pairs"}++;
	$matrix{$p7ind}{$p5ind} += $number;
#	$expected_pair{"$p7ind.$p5ind"}++;
	next;
    }
    if ($p7_ident && $p5_ident && ! $lib) {
	$stats{"unexpected_pair"} += $number;
	$matrix{$p7ind}{$p5ind} = $number;
	$unexpected_pair{"$p7ind,$p5ind"} += $number;
	next;
    }
    if ($p7_ident || $p5_ident && ! $lib) {
	$stats{"single_index"} += $number;
	next;
    }
    if (! $p7_ident && ! $p5_ident) {
	$stats{"no_index"} += $number;
	next;
    }
    die "unexpected line: $line\n";
}

foreach my $pair (keys %unexpected_pair) {
    my ($p7, $p5) = split /,/, $pair;
    my $number = $unexpected_pair{$pair};
#    print "unexpected: $number $p7 $p5\n";###debug
    if (exists $expected_p7{$p7} && exists $expected_p5{$p5}) {
	$stats{"corner"} += $number;
#	print "corner seen: $number p7 $p7, p5 $p5\n";###debug
    }
}

if ($dual_use) {
    print "No cross-contamination statistics due to dual occurance of at least one p7 or p5 index\n";
} else {
    foreach my $rg (keys %expected_rg) {
	my $p7_exp = $expected_rg{$rg}{"p7"};
	my $p5_exp = $expected_rg{$rg}{"p5"};
	my $count_exp = $expected_rg{$rg}{"count"};
	foreach my $p5_search (keys %expected_p5) { #go through all expected p5
	    next if $p5_search eq $p5_exp;
	    next unless exists $matrix{$p7_exp}{$p5_search}; #find any match between expected p7 and p5 from other rg
	    my $other_p7 = $p5_to_p7{$p5_search};           #identified other p7
	    next unless exists $matrix{$other_p7}{$p5_exp}; #check if the other corner exists too
	    my $corner1 = $matrix{$p7_exp}{$p5_search};
	    my $corner2 = $matrix{$other_p7}{$p5_exp};
	    my $lowest_corner = $corner1;
	    $lowest_corner = $corner2 if $corner2 < $corner1;
	    my $cross_cont = (($lowest_corner / $count_exp)**2) * $count_exp;
	    my $cont_lib = $index_to_rg{"$other_p7.$p5_search"};
#	    print "RG: $rg, EXP_p7: $p7_exp, EXP_p5: $p5_exp, UNEXP_p5: $p5_search, OTH_p7: $other_p7, COR1: $corner1, COR2: $corner2, CONT: $cross_cont\n";
	    $cross{"$cont_lib into $rg"} = $cross_cont;
	}
    }
}

print "#\tnumber\t%\n";
print "observations\t", $stats{"raw"} || 0, "\n";
print "quality_passed\t", $total, "\t100.00", "\n";
print "expected_pair\t", $stats{"expected_pair"}, "\t", sprintf ("%.2f", $stats{"expected_pair"} / $total *100), "\n";
print "unexpected_pair\t", $stats{"unexpected_pair"}, "\t", sprintf ("%.2f", $stats{"unexpected_pair"} / $total *100), "\n";
print "corner_pair\t", $stats{"corner"} || 0, "\t", sprintf ("%.2f", $stats{"corner"} / $total *100), "\n";
print "one_index_only\t", $stats{"single_index"}, "\t", sprintf ("%.2f", $stats{"single_index"} / $total *100), "\n";
print "no_index\t", $stats{"no_index"}, "\t", sprintf ("%.2f", $stats{"no_index"} / $total *100), "\n";
print "\nTop $top suspects for cross-contamination\n";

my $counter = 0;
foreach my $element (sort {$cross{$b} <=> $cross{$a}} keys %cross) {
    $counter++;
    my $value = sprintf ("%.3f", $cross{$element});
    print "$element\t($value reads)\n";
    last if $counter == $top;
}

sub help {
    print "

This script reads the output from splitBAM (the text file with all observed index combinations) and computes summary statistics.

[usage]
./indexstats.pl file.txt

[output]
STDOUT            basic summary statistics

";
exit;
}
