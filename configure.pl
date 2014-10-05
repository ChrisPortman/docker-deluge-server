#!/bin/env perl

use strict;
use Digest::SHA;

my %DEFAULT_SETTINGS = (
  'ADMIN_USER'    => 'admin',
  'ADMIN_PASS'    => 'admin',
  'EMAIL_ADDRESS' => 'you@example.com',
  'SMTP_PORT'     => '25',
  'SMTP_SERVER'   => 'smtp.example.com',
  'SMTP_FROM'     => 'deluge@example.com', 
  'SMTP_USER'     => 'username',
  'SMTP_PASS'     => 'password',
  'SMTP_TLS'      => 'false',
  'XBMC_HOST'     => 'xbmc',
  'XBMC_USER'     => 'xbmc',
  'XBMC_PASS'     => 'xbmc',
  'XBMC_PORT'     => '80',
);

open my $fh, '<', '/tmp/environment.conf';
while (<$fh>) {
  next if /^#?\s*$/;
  my ($opt, $val) = $_ =~ /^\s*(.+)\s*:\s*(.+)\s*$/;

  $opt =~ s/^\s*//;
  $opt =~ s/\s*$//;
  $val =~ s/^\s*//;
  $val =~ s/\s*$//;

  $DEFAULT_SETTINGS{$opt} = $val;
}
close $fh;

if ($DEFAULT_SETTINGS{'PWD_SALT'} and $DEFAULT_SETTINGS{'ADMIN_PASS'}) {
  my $sha = Digest::SHA->new(1);
  $sha->add($DEFAULT_SETTINGS{'PWD_SALT'});
  $sha->add($DEFAULT_SETTINGS{'ADMIN_PASS'});
  $DEFAULT_SETTINGS{'PWD_SHA'} = $sha->hexdigest;
}

my @dirs  = ( '/etc/deluge' );
my @files = ( '/opt/download_manager/etc/downloads.conf', '/opt/torrent_manager/environments/production.yml' );

for my $dir (@dirs) {
  opendir(DIR, $dir)
    or (warn "Could not open directory $dir: $!\n" and next);

  while (my $file = readdir(DIR)) {
    my $filepath = "$dir/$file";

    next unless -f $filepath;
    next unless $file =~ /\.conf$/ or $file =~ /^auth$/;

    push @files, $filepath;
  }
}

for my $file (@files) {
  open (my $f, '<', $file)
    or (warn "Could not open $file: $!\n" and next);

  my $content;
  { local $/; $content = <$f>; }

  close $f;

  $content =~ s/%%([^%]+)%%/$DEFAULT_SETTINGS{$1}/g;

  open (my $f, '>', $file)
    or (warn "Could not open $file: $!\n" and next);

  print $f $content;
  close $f;
}

exit;


