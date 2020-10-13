# --
# Copyright (C) 2012-2020 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

## nofilter(TidyAll::Plugin::OTRS::Perl::PerlCritic)
package Kernel::System::VariableCheck;    ## no critic

=head1 NAME

Kernel::System::VariableCheck

=head1 SYNOPSIS

VariableCheck helpers.

=cut

use strict;
use warnings;

my @NewTags = Package::Stash->new('Kernel::System::VariableCheck')->list_all_symbols('CODE');

our %EXPORT_TAGS = (    ## no critic
    all => \@NewTags,
);
Exporter::export_ok_tags('all');

our @ObjectDependencies = (
    'Kernel::System::DateTime',
    'Kernel::System::DynamicField',
);

=head2 IsDate()

Test supplied data to determine if it is a date var

returns 1 if data matches criteria or undef otherwise

    my $Result = IsDate(
        '2020-09-25', # data to be tested
    );

=cut

sub IsDate {
    my $TestData = $_[0];

    return   if !$TestData;
    return 0 if ( $TestData !~ /^(\d{4})-(\d{1,2})-(\d{1,2})$/ );

    my $DateTimeObject = $Kernel::OM->Create(
        'Kernel::System::DateTime',
        ObjectParams => {
            String => $TestData . ' 00:00:00',
        }
    );

    return 0 if !$DateTimeObject;

    return 1;
}

=head2 IsDateTime()

Test supplied data to determine if it is a date time var

returns 1 if data matches criteria or undef otherwise

    my $Result = IsDateTime(
        '2020-09-25 10:09:00', # data to be tested
    );

=cut

sub IsDateTime {
    my $TestData = $_[0];

    return   if !$TestData;
    return 0 if ( $TestData !~ /^(\d{4})-(\d{1,2})-(\d{1,2})\s(\d{1,2}):(\d{1,2}):(\d{1,2})$/ );

    my $DateTimeObject = $Kernel::OM->Create(
        'Kernel::System::DateTime',
        ObjectParams => {
            String => $TestData,
        }
    );

    return 0 if !$DateTimeObject;

    return 1;
}

=head2 IsDynamicField()

Test supplied data to determine if it is a dynamic field

returns 1 if data matches criteria or undef otherwise

    my $Result = IsDynamicField(
        'DynamicField_Test_Value', # data to be tested
    );

=cut

sub IsDynamicField {
    my $TestData = $_[0];
    my $Result   = $_[1];

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');

    return if !$TestData;

    # check if field is DynamicField
    my $DynamicFieldName;
    if ( $TestData =~ m{DynamicField_(\S+?)_Value} ) {
        $DynamicFieldName = $1;
    }
    elsif ( $TestData =~ m{DynamicField_(\S+?)_Key} ) {
        $DynamicFieldName = $1;
    }
    elsif ( $TestData =~ m{DynamicField_(.*)} ) {
        $DynamicFieldName = $1;
    }

    return 0 if !$DynamicFieldName;

    my $DynamicField = $DynamicFieldObject->DynamicFieldGet(
        Name => $DynamicFieldName,
    );

    if ( $Result && $DynamicField ) {
        return $DynamicField;
    }
    elsif ($DynamicField) {
        return 1;
    }

    return 0;
}

1;
