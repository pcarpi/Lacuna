#!/usr/bin/perl
#
# Script to parse thru the probe data and try to
# find stars that have been missed in probe net
#
# Usage: perl close_stars.pl
#  
use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use YAML;
use YAML::XS;
use Data::Dumper;
use utf8;

my $home_x;
my $home_y;
my $max_dist = 250;
my $probe_file = "data/probe_data_cmb.yml";
my $star_file   = "data/stars.csv";
my $planet_file = "data/planet_score.yml";
my $planet = '';
my $zone = '';
my $help; my $nodist = 0; my $showprobe = 0;

GetOptions(
  'x=i'          => \$home_x,
  'y=i'          => \$home_y,
  'planet=s'     => \$planet,
  'max_dist=i'   => \$max_dist,
  'nodist'       => \$nodist,
  'probe=s'      => \$probe_file,
  'stars=s'      => \$star_file,
  'showprobe'    => \$showprobe,
  'help'         => \$help,
  'zone=s'       => \$zone,
);
  
  usage() if ($help);

  my $bod;
  my $bodies;
  my $planets;
  if (-e $probe_file) {
    $bodies  = YAML::XS::LoadFile($probe_file);
  }
  else {
    print STDERR "$probe_file not found!\n";
    die;
  }
  if (-e "$planet_file") {
    $planets = YAML::XS::LoadFile($planet_file);
  }
  else {
    unless (defined($home_x) and defined($home_y)) {
      print STDERR "$planet_file not found!\n";
      die;
    }
  }
  unless (defined($home_x) and defined($home_y)) {
    ($home_x, $home_y) = get_coord($planets, $planet);
  }

  my $stars;
  if (-e "$star_file") {
    $stars = get_stars("$star_file", $zone);
  }
  else {
    print STDERR "$star_file not found!\n";
    die;
  }

  my %sys;

  for $bod (@$bodies) {
    my $star_id = $bod->{star_id};
    next if (defined($sys{$star_id}));
    next unless (defined($stars->{$bod->{star_id}}));

    my $sys_data = {
      dist => sprintf("%.2f", sqrt(($home_x - $stars->{$bod->{star_id}}->{x})**2 +
                                   ($home_y - $stars->{$bod->{star_id}}->{y})**2)),
      probed => 1,
    };
    $sys{$star_id} = $sys_data;
  }

  for my $star_id (keys %$stars) {
    next if (defined($sys{$star_id}));
    my $dist = sprintf("%.2f", sqrt(($home_x - $stars->{$star_id}->{x})**2 +
                                    ($home_y - $stars->{$star_id}->{y})**2));
    next if ($dist > $max_dist);
    my $sys_data = {
      dist => $dist,
      probed => 0,
    };
    $sys{$star_id} = $sys_data;
  }

  print "ID,Name,X,Y,Color,Zone,P,Dist\n";
  for my $key (keys %sys) {
    next if (!$showprobe and $sys{$key}->{probed});
    printf "%s,%s,%s,%s,%s,%s,%s,%s\n",
      $key,
      $stars->{$key}->{name},
      $stars->{$key}->{x},
      $stars->{$key}->{y},
      $stars->{$key}->{color},
      $stars->{$key}->{zone},
      $sys{$key}->{probed},
      $sys{$key}->{dist};
  }
exit;

sub get_stars {
  my ($sfile, $sector) = @_;

  my $fh;
  open ($fh, "<", "$sfile") or die;

  my $fline = <$fh>;
  my %star_hash;
  while(<$fh>) {
    chomp;
    my ($id, $name, $x, $y, $color, $zone) = split(/,/, $_, 6);
#    next if $zone ne $sector;
    $star_hash{$id} = {
      id    => $id,
      name  => $name,
      x     => $x,
      y     => $y,
      color => $color,
      zone  => $zone,
    }
  }
  return \%star_hash;
}

sub get_coord {
  my ($planets, $pname) = @_;

#  print "$pname : ", join(":", keys %{$planets}), "\n";
  my ($prime) = grep { $planets->{$_}->{prime} } keys %{$planets};
#  print "Planet: $prime\n";
  my $px = $planets->{"$prime"}->{x};
  my $py = $planets->{"$prime"}->{y};

#  print $px, $py, "\n";
  if (defined($planets->{"$pname"})) {
    return $planets->{"$pname"}->{x}, $planets->{"$pname"}->{y};
  }
  return $px, $py
  
}

sub usage {
    diag(<<END);
Usage: $0 [options]

This program takes your supplied probe file and reports which stars
within a certain distance have not been probed.
Probe file generation by probe_yaml.pl and merge_probe.pl

Options:
  --help      - Prints this out
  --x Num     - X coord for distance calculation
  --y Num     - X coord for distance calculation
  --probe     - probe_file,
  --planet    - planet to measure distance from
  --max_dist  - Maximum Distance to report on
  --stars     - star file, default data/stars.csv
  --showprobe - show probed stars.  Default is to show unprobed stars
  --zone      - Only show named zone as in '-3|0'
END
 exit 1;
}

sub diag {
    my ($msg) = @_;
    print STDERR $msg;
}
