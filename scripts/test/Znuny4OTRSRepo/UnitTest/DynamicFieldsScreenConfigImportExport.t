# --
# Copyright (C) 2012-2018 Znuny GmbH, http://znuny.com/
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
        RestoreSystemConfiguration => 1,
        RestoreDatabase            => 1,
    },
);

my $ZnunyHelperObject    = $Kernel::OM->Get('Kernel::System::ZnunyHelper');
my $ConfigObject         = $Kernel::OM->Get('Kernel::Config');
my $SysConfigObject      = $Kernel::OM->Get('Kernel::System::SysConfig');
my $UnitTestHelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

# Create dynamic fields to test export
my @DynamicFieldConfigs = (
    {
        Name       => "DynField" . $UnitTestHelperObject->GetRandomID(),
        Label      => 'Dynamic field test 1',
        ObjectType => 'Ticket',
        FieldType  => 'Text',
        Config     => {
            DefaultValue => "",
        },
    },
    {
        Name       => "DynField" . $UnitTestHelperObject->GetRandomID(),
        Label      => 'Dynamic field test 2',
        ObjectType => 'Ticket',
        FieldType  => 'Text',
        Config     => {
            DefaultValue => "",
        },
    },
    {
        Name       => "DynField" . $UnitTestHelperObject->GetRandomID(),
        Label      => 'Dynamic field test 3',
        ObjectType => 'Ticket',
        FieldType  => 'Text',
        Config     => {
            DefaultValue => "",
        },
    },
    {
        Name       => "DynField" . $UnitTestHelperObject->GetRandomID(),
        Label      => 'Dynamic field test 4',
        ObjectType => 'Ticket',
        FieldType  => 'Text',
        Config     => {
            DefaultValue => "",
        },
    },
);

my $DynamicFieldsCreated = $ZnunyHelperObject->_DynamicFieldsCreate(@DynamicFieldConfigs);

$Self->True(
    scalar $DynamicFieldsCreated,
    'Dynamic fields must have been created successfully.',
);

# Test export
my @Tests = (
    {
        Name       => 'Import and Export one DynamicField with one DynamicFieldScreens.',
        ImportData => {
            $DynamicFieldConfigs[0]->{Name} => {
                'Ticket::Frontend::AgentTicketZoom###DynamicField' => 1,
            },
        },
    },
    {
        Name       => 'Import and Export one DynamicField with one DefaultColumnsScreens.',
        ImportData => {
            $DynamicFieldConfigs[1]->{Name} => {
                'AgentCustomerInformationCenter::Backend###0120-CIC-TicketNew'             => 1,
                'AgentCustomerInformationCenter::Backend###0100-CIC-TicketPendingReminder' => 2,
                'DashboardBackend###0100-TicketPendingReminder'                            => 0,
                'DashboardBackend###0140-RunningTicketProcess'                             => 1,
                'DashboardBackend###0120-TicketNew'                                        => 0,
            },
        },
    },
    {
        Name       => 'Import and Export multiple DynamicFields with multiple screens.',
        ImportData => {
            $DynamicFieldConfigs[2]->{Name} => {
                'AgentCustomerInformationCenter::Backend###0120-CIC-TicketNew'             => 1,
                'AgentCustomerInformationCenter::Backend###0100-CIC-TicketPendingReminder' => 2,
                'DashboardBackend###0100-TicketPendingReminder'                            => 0,
                'DashboardBackend###0140-RunningTicketProcess'                             => 1,
                'DashboardBackend###0120-TicketNew'                                        => 0,
                'Ticket::Frontend::AgentTicketLockedView###DefaultColumns'                 => 1,
                'Ticket::Frontend::AgentTicketQueue###DefaultColumns'                      => 2,
                'Ticket::Frontend::AgentTicketPhone###DynamicField'                        => 0,
                'Ticket::Frontend::AgentTicketZoom###DynamicField'                         => 1,
                'Ticket::Frontend::CustomerTicketOverview###DynamicField'                  => 2,
                'Ticket::Frontend::OverviewPreview###DynamicField'                         => 2,
            },
            $DynamicFieldConfigs[3]->{Name} => {
                'AgentCustomerInformationCenter::Backend###0100-CIC-TicketPendingReminder' => 2,
                'DashboardBackend###0140-RunningTicketProcess'                             => 1,
                'Ticket::Frontend::AgentTicketResponsible###DynamicField'                  => 1,
                'Ticket::Frontend::AgentTicketSearch###DefaultColumns'                     => 1,
                'Ticket::Frontend::AgentTicketZoom###DynamicField'                         => 0,
                'Ticket::Frontend::CustomerTicketOverview###DynamicField'                  => 2,
                'Ticket::Frontend::AgentTicketOwner###DynamicField'                        => 1,
                'Ticket::Frontend::OverviewPreview###DynamicField'                         => 1,
            },
        },
    },
);

TEST:
for my $Test (@Tests) {

    $Self->True(
        $Test->{Name},
        "$Test->{Name}",
    );

    my @DynamicFields = sort keys %{ $Test->{ImportData} };

    my %Export = $ZnunyHelperObject->_DynamicFieldsScreenConfigExport(
        DynamicFields => \@DynamicFields
    );
    for my $DynamicField ( sort keys %{ $Test->{ImportData} } ) {

        $Self->False(
            $Export{$DynamicField},
            "ScreenConfig for '$DynamicField' is not defined.",
        );
    }

    my $Import = $ZnunyHelperObject->_DynamicFieldsScreenConfigImport(
        Config => $Test->{ImportData},
    );

    %Export = $ZnunyHelperObject->_DynamicFieldsScreenConfigExport(
        DynamicFields => \@DynamicFields
    );

    DYNAMICFIELD:
    for my $DynamicField ( sort keys %{ $Test->{ImportData} } ) {

        $Self->True(
            $Export{$DynamicField},
            "ScreenConfig for '$DynamicField' is defined.",
        );

        next DYNAMICFIELD if !$Export{$DynamicField};

        $Self->IsDeeply(
            $Export{$DynamicField},
            $Test->{ImportData}->{$DynamicField},
            "Import and export for '$DynamicField' was successful .",
        );
    }
}

1;
