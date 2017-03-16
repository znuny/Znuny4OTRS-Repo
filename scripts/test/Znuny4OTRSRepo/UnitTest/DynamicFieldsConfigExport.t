# --
# Copyright (C) 2012-2017 Znuny GmbH, http://znuny.com/
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
my $YAMLObject           = $Kernel::OM->Get('Kernel::System::YAML');

# Create dynamic fields to test export
my @DynamicFieldConfigs = (
    {
        Name       => $UnitTestHelperObject->GetRandomID(),
        Label      => 'Dynamic field export test 1',
        ObjectType => 'Ticket',
        FieldType  => 'Text',
        Config     => {
            DefaultValue => "",
        },
    },
    {
        Name       => $UnitTestHelperObject->GetRandomID(),
        Label      => 'Dynamic field export test 2',
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

my $InternalDynamicFieldName = $ConfigObject->Get('Process::DynamicFieldProcessManagementProcessID');
my @OptionalConfigKeys       = (qw(ChangeTime CreateTime ID InternalField ValidID));

# Test export
my @Tests = (
    {
        Name         => 'Export as Perl structure with internal fields and all config keys',
        ExportParams => {
            Format                => 'perl',
            IncludeInternalFields => 1,
            IncludeAllConfigKeys  => 1,
        },
    },
    {
        Name         => 'Export as Perl structure with internal fields and limited config keys',
        ExportParams => {
            Format                => 'perl',
            IncludeInternalFields => 1,
            IncludeAllConfigKeys  => 0,
        },
    },
    {
        Name         => 'Export as Perl structure without internal fields and all config keys',
        ExportParams => {
            Format                => 'perl',
            IncludeInternalFields => 0,
            IncludeAllConfigKeys  => 1,
        },
    },
    {
        Name         => 'Export as Perl structure without internal fields and limited config keys',
        ExportParams => {
            Format                => 'perl',
            IncludeInternalFields => 0,
            IncludeAllConfigKeys  => 0,
        },
    },
    {
        Name         => 'Export as YAML structure with internal fields and all config keys',
        ExportParams => {
            Format                => 'yml',
            IncludeInternalFields => 1,
            IncludeAllConfigKeys  => 1,
        },
    },
    {
        Name         => 'Export as YAML structure with internal fields and limited config keys',
        ExportParams => {
            Format                => 'yml',
            IncludeInternalFields => 1,
            IncludeAllConfigKeys  => 0,
        },
    },
    {
        Name         => 'Export as YAML structure without internal fields and all config keys',
        ExportParams => {
            Format                => 'yml',
            IncludeInternalFields => 0,
            IncludeAllConfigKeys  => 1,
        },
    },
    {
        Name         => 'Export as YAML structure without internal fields and limited config keys',
        ExportParams => {
            Format                => 'yml',
            IncludeInternalFields => 0,
            IncludeAllConfigKeys  => 0,
        },
    },
);

TEST:
for my $Test (@Tests) {
    my $Export = $ZnunyHelperObject->_DynamicFieldsConfigExport( %{ $Test->{ExportParams} } );

    # Turn export into Perl structure.
    if ( $Test->{ExportParams}->{Format} eq 'perl' ) {
        $Export =~ s{\A(\$VAR1)}{\$Export};
        eval $Export;    #nofilter(TidyAll::Plugin::OTRS::Perl::PerlCritic)
    }
    elsif ( $Test->{ExportParams}->{Format} eq 'yml' ) {
        $Export = $YAMLObject->Load(
            Data => $Export,
        );
    }
    else {
        return;
    }

    # Check for created dynamic fields
    for my $ExpectedDynamicFieldConfig (@DynamicFieldConfigs) {
        my @ExportedDynamicFieldConfigs = grep { $_->{Name} eq $ExpectedDynamicFieldConfig->{Name} } @{$Export};

        $Self->Is(
            scalar @ExportedDynamicFieldConfigs,
            1,
            "$Test->{Name} - Dynamic field must be found in export.",
        ) || next TEST;

        my $ExportedDynamicFieldConfig = shift @ExportedDynamicFieldConfigs;

        # Compare some field values
        for my $Field (qw(Label ObjectType FieldType)) {
            $Self->Is(
                $ExportedDynamicFieldConfig->{$Field},
                $ExpectedDynamicFieldConfig->{$Field},
                "$Test->{Name} - Value of field $Field must match expected one.",
            );
        }

        # Internal fields must be included if parameter IncludeInternalFields has been given.
        # This will be tested with one of the standard OTRS dynamic fields of process management.
        my @ExportedInternalDynamicFieldConfigs = grep { $_->{Name} eq $InternalDynamicFieldName } @{$Export};
        if ( $Test->{ExportParams}->{IncludeInternalFields} ) {
            $Self->Is(
                scalar @ExportedInternalDynamicFieldConfigs,
                1,
                "$Test->{Name} - Internal dynamic field $InternalDynamicFieldName must be found in export.",
            );
        }
        else {
            $Self->Is(
                scalar @ExportedInternalDynamicFieldConfigs,
                0,
                "$Test->{Name} - Internal dynamic field $InternalDynamicFieldName must not be found in export.",
            );
        }

        # Check that certain config keys are (not) present in the export.
        for my $OptionalConfigKey (@OptionalConfigKeys) {
            if ( $Test->{ExportParams}->{IncludeAllConfigKeys} ) {
                $Self->True(
                    exists $ExportedDynamicFieldConfig->{$OptionalConfigKey},
                    "$Test->{Name} - Config key $OptionalConfigKey must be found in export.",
                );
            }
            else {
                $Self->False(
                    exists $ExportedDynamicFieldConfig->{$OptionalConfigKey},
                    "$Test->{Name} - Config key $OptionalConfigKey must not be found in export.",
                );
            }
        }
    }
}

1;
