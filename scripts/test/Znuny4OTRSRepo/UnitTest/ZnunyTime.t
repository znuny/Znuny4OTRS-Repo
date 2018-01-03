# --
# Copyright (C) 2012-2018 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

# nofilter(TidyAll::Plugin::OTRS::Migrations::OTRS6::TimeObject)

use strict;
use warnings;
use utf8;

use vars (qw($Self));

use Kernel::System::VariableCheck qw(:all);

my $TimeObject      = $Kernel::OM->Get('Kernel::System::Time');
my $ZnunyTimeObject = $Kernel::OM->Get('Kernel::System::ZnunyTime');

# Just make sure that both time objects behave the same
my $SystemTime = $TimeObject->SystemTime();

my $TimeStamp = $TimeObject->SystemTime2TimeStamp( SystemTime => $SystemTime );
my $ZnunyTimeStamp = $ZnunyTimeObject->SystemTime2TimeStamp( SystemTime => $SystemTime );
$Self->Is(
    $ZnunyTimeStamp,
    $TimeStamp,
    'SystemTime2TimeStamp must result in equal values for Kernel::System::Time and Kernel::System::ZnunyTime.',
);

1;
