# --
# Copyright (C) 2012-2022 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

use Kernel::System::VariableCheck qw(:all);

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

# get needed objects
my $HelperObject      = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $LinkObject        = $Kernel::OM->Get('Kernel::System::LinkObject');
my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

my $TicketID1 = $HelperObject->TicketCreate();
my $TicketID2 = $HelperObject->TicketCreate();

my %LinkKeyList = $LinkObject->LinkKeyList(
    Object1   => 'Ticket',
    Key1      => $TicketID1,
    Object2   => 'Ticket',
    State     => 'Valid',
    Type      => 'Normal',
    Direction => 'Both',
    UserID    => 1,
);

$Self->False(
    %LinkKeyList ? 1 : 0,
    'There are no links between ticket 1 and ticket 2',
);

$HelperObject->ConsoleCommand(
    CommandModule => 'Kernel::System::Console::Command::Znuny4OTRS::Repo::Maint::LinkObject::LinkAdd',
    Parameter     => [
        '--source-object', 'Ticket', '--source-key', $TicketID1, '--target-object', 'Ticket',
        '--target-key', $TicketID2, '--type', 'Normal', '--state', 'Valid'
    ],
);

%LinkKeyList = $LinkObject->LinkKeyList(
    Object1   => 'Ticket',
    Key1      => $TicketID1,
    Object2   => 'Ticket',
    State     => 'Valid',
    Type      => 'Normal',
    Direction => 'Both',
    UserID    => 1,
);

$Self->True(
    %LinkKeyList ? 1 : 0,
    'There is now a link between ticket 1 and ticket 2',
);

$HelperObject->ConsoleCommand(
    CommandModule => 'Kernel::System::Console::Command::Znuny4OTRS::Repo::Maint::LinkObject::LinkDelete',
    Parameter     => [
        '--source-object', 'Ticket', '--source-key', $TicketID1, '--target-object', 'Ticket',
        '--target-key', $TicketID2, '--type', 'Normal'
    ],
);

%LinkKeyList = $LinkObject->LinkKeyList(
    Object1   => 'Ticket',
    Key1      => $TicketID1,
    Object2   => 'Ticket',
    State     => 'Valid',
    Type      => 'Normal',
    Direction => 'Both',
    UserID    => 1,
);

$Self->False(
    %LinkKeyList ? 1 : 0,
    'There are no links between ticket 1 and ticket 2',
);

1;
