#!/usr/bin/perl
#
# Script to parse thru the probe data
#
# Usage: perl parse_probe.pl probe_file
#  
use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use YAML;
use YAML::XS;
use Data::Dumper;
use utf8;

my $home_x = 0;
my $home_y = 0;
my $probe_file = "data/probe_data_cmb.yml";

GetOptions(
  'x=i' => \$home_x,
  'y=i' => \$home_y,
  'p=s' => \$probe_file,
);
  
  my $bod;
  my $bodies = YAML::XS::LoadFile($probe_file);

# Calculate some metadata
  for $bod (@$bodies) {
    if (not defined($bod->{water})) { $bod->{water} = 0; }
    $bod->{distance} = sprintf("%.2f", sqrt(($home_x - $bod->{x})**2 + ($home_y - $bod->{y})**2));
    $bod->{ore_total} = 0;
    for my $ore_s (keys %{$bod->{ore}}) {
      if ($bod->{ore}->{$ore_s} > 1) { $bod->{ore_total} += $bod->{ore}->{$ore_s}; }
    }

  }


print "Name,O,Dist,X,Y,Type,Size,Total,Mineral,Amt\n";
for $bod (sort byscore @$bodies) {
  next unless ($bod->{type} eq "asteroid");
  if (not defined($bod->{empire}->{name})) { $bod->{empire}->{name} = "unclaimed"; } 
  if (not defined($bod->{water})) { $bod->{water} = 0; } 
  $bod->{image} =~ s/-.//;
  
  print join(",", $bod->{star_name}, $bod->{orbit}, $bod->{distance}, $bod->{x}, $bod->{y},
                  $bod->{image}, $bod->{size}, $bod->{ore_total});
  for my $ore (sort keys %{$bod->{ore}}) {
        if ($bod->{ore}->{$ore} > 1) {
          print ",$ore,", $bod->{ore}->{$ore};
        }
  }
  print "\n";
}

sub byscore {
   $a->{distance} <=> $b->{distance} ||
   $b->{ore_total} <=> $a->{ore_total};
    
}
