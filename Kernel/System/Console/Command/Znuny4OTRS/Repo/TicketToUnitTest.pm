# --
# Copyright (C) 2012-2018 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Znuny4OTRS::Repo::TicketToUnitTest;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::Znuny4OTRS::TicketToUnitTest',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description(
        'Creates a UnitTest of Ticket.',
    );

    $Self->AddArgument(
        Name        => 'ticketid',
        Description => 'Specify the Ticket via TicketID: 123456',
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/\d+/smx,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $TicketToUnitTestObject = $Kernel::OM->Get('Kernel::System::Znuny4OTRS::TicketToUnitTest');

    my $CreateUnitTestOutput = $TicketToUnitTestObject->CreateUnitTest(
        TicketID => $Self->GetArgument('ticketid'),
    );

    $Self->Print("$CreateUnitTestOutput\n");

    return $Self->ExitCodeOk();
}

1;
