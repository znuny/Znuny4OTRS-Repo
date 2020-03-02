# --
# Copyright (C) 2012-2020 Znuny GmbH, http://znuny.com/
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

# IsITSMInstalled
my $IsITSMInstalled = $ZnunyUtilObject->IsITSMInstalled();

$Self->False(
    $IsITSMInstalled,
    'IsITSMInstalled false',
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
    $IsITSMInstalled,
    'IsITSMInstalled true',
);

1;
