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

my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

# IsDateTime()
my @Tests = (
    {
        Description => 'IsDateTime() - Data is undef',
        Data        => undef,
        Result      => undef,
    },
    {
        Description => 'IsDateTime() - Data is invalid',
        Data        => '2020-09-25 10:09:00abc',
        Result      => 0,
    },
    {
        Description => 'IsDateTime() - Data is valid',
        Data        => '2020-09-25 10:09:00',
        Result      => 1,
    },
);

for my $Test (@Tests) {

    $Self->Is(
        scalar IsDateTime(
            $Test->{Data},
        ),
        scalar $Test->{Result},
        $Test->{Description},
    );
}

# IsDynamicField()

my @DynamicFields = (
    {
        Name       => 'IsDynamicField',
        Label      => 'IsDynamicField',
        ObjectType => 'Ticket',
        FieldType  => 'Text',
        Config     => {
            DefaultValue => '',
            Link         => '',
        },
    },
);
$ZnunyHelperObject->_DynamicFieldsCreate(@DynamicFields);

@Tests = (
    {
        Description => 'IsDynamicField() - Data is undef',
        Data        => undef,
        Result      => undef,
    },
    {
        Description => 'IsDynamicField() - Data is invalid',
        Data        => 'IsDynamicFieldabc',
        Result      => 0,
    },
    {
        Description => 'IsDynamicField() - Data DynamicField_ is valid',
        Data        => 'DynamicField_IsDynamicField',
        Result      => 1,
    },
    {
        Description => 'IsDynamicField() - Data DynamicField_***_Value is valid',
        Data        => 'DynamicField_IsDynamicField_Value',
        Result      => 1,
    },
    {
        Description => 'IsDynamicField() - Data DynamicField_***_Key is valid',
        Data        => 'DynamicField_IsDynamicField_Key',
        Result      => 1,
    },
);

for my $Test (@Tests) {

    $Self->Is(
        scalar IsDynamicField(
            $Test->{Data},
        ),
        scalar $Test->{Result},
        $Test->{Description},
    );
}

1;
