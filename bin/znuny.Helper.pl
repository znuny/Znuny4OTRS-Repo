#!/usr/bin/perl -w

# Copyright (C) 2013 Znuny GmbH, http://znuny.com

use strict;
use warnings;

# use ../ as lib location
use File::Basename;
use FindBin qw($RealBin);
use lib dirname($RealBin);

use Getopt::Std;
use Kernel::System::ZnunyHelper;

my $Helper = Kernel::System::ZnunyHelper->new();


# get options
my %Opts;
getopt( 'hap', \%Opts );

if ( $Opts{h} ) {
    print "znuny.Helper.pl - OTRS helper functions\n";
    print "Copyright (C) 2013-2013 Znuny GmbH, http://znuny.com/\n";
    print "usage: znuny.Helper.pl -a install|uninstall -p /path/to/file.sopm\n";
    exit 1;
}
if (!$Opts{a}) {
    print STDERR "ERROR: need -a param\n";
    exit 1;
}
if (!$Opts{p}) {
    print STDERR "ERROR: need -p /path/to/file.sopm param\n";
    exit 1;
}

if ( lc($Opts{a}) eq 'install' ) {
    $Helper->_PackageInstall( File => $Opts{p} );
}
elsif ( lc($Opts{a}) eq 'uninstall' ) {
    $Helper->_PackageUninstall( File => $Opts{p} );
}
else {
    print STDERR "ERROR: unknown action '$Opts{a}'\n";
}
