#!/usr/bin/perl
# --
# bin/znuny.Helper.pl
# Copyright (C) 2001-2015 Znuny GmbH, http://znuny.com/
# --
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU AFFERO General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA
# or see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;

# use ../ as lib location
use File::Basename;
use FindBin qw($RealBin);
use lib dirname($RealBin);

use Getopt::Std;

use Kernel::System::ObjectManager;

# create object manager
local $Kernel::OM = Kernel::System::ObjectManager->new(
    'Kernel::System::Log' => {
        LogPrefix => 'OTRS-znuny.Helper.pl',
    },
);

my $Helper = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

# get options
my %Opts;
getopt( 'hap', \%Opts );

if ( $Opts{h} ) {
    print "znuny.Helper.pl - OTRS helper functions\n";
    print "Copyright (C) 2013-2015 Znuny GmbH, http://znuny.com/\n";
    print "usage: znuny.Helper.pl -a install|uninstall -p /path/to/file.sopm\n";
    exit 1;
}
if ( !$Opts{a} ) {
    print STDERR "ERROR: need -a param\n";
    exit 1;
}
if ( !$Opts{p} ) {
    print STDERR "ERROR: need -p /path/to/file.sopm param\n";
    exit 1;
}

if ( lc( $Opts{a} ) eq 'install' ) {
    $Helper->_PackageInstall( File => $Opts{p} );
}
elsif ( lc( $Opts{a} ) eq 'uninstall' ) {
    $Helper->_PackageUninstall( File => $Opts{p} );
}
else {
    print STDERR "ERROR: unknown action '$Opts{a}'\n";
}
