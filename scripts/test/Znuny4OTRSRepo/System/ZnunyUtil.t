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

my $HelperObject    = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ZnunyUtilObject = $Kernel::OM->Get('Kernel::System::ZnunyUtil');

#
# IsITSMInstalled()
#

my $IsITSMInstalled = $ZnunyUtilObject->IsITSMInstalled();

$Self->False(
    scalar $IsITSMInstalled,
    'IsITSMInstalled() must report ITSM as being not installed.',
);

$HelperObject->ConfigSettingChange(
    Valid => 1,
    Key   => 'Frontend::Module###AdminITSMCIPAllocate',
    Value => {
        'Group' => [
            'admin'
        ],
        'GroupRo'     => [],
        'Description' => 'Manage priority matrix.',
        'Title'       => 'Criticality ↔ Impact ↔ Priority',
        'NavBarName'  => 'Admin',
    },
);

$Kernel::OM->ObjectsDiscard(
    Objects => ['Kernel::System::ZnunyUtil'],
);

$ZnunyUtilObject = $Kernel::OM->Get('Kernel::System::ZnunyUtil');
$IsITSMInstalled = $ZnunyUtilObject->IsITSMInstalled();

$Self->True(
    scalar $IsITSMInstalled,
    'IsITSMInstalled() must report ITSM as being installed.',
);

#
# IsFrontendContext()
#

my $IsFrontendContext = $ZnunyUtilObject->IsFrontendContext();

$Self->False(
    scalar $IsFrontendContext,
    'IsFrontendContext() must report no frontend context.',
);

# Fake frontend context.
my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
$LayoutObject->{Action} = 'AgentTicketZoom';

$IsFrontendContext = $ZnunyUtilObject->IsFrontendContext();

$Self->True(
    scalar $IsFrontendContext,
    'IsFrontendContext() must report frontend context.',
);

1;
