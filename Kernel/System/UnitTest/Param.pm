# --
# Copyright (C) 2012-2018 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::OTRS::Perl::ParamObject)

package Kernel::System::UnitTest::Param;

use strict;
use warnings;

use File::Spec;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::Log',
    'Kernel::System::Web::Request',
);

=head1 NAME

Kernel::System::UnitTest::Param - Helper to unit test Params

=head1 SYNOPSIS

Functions to unit test Params

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $UnitTestParamObject = $Kernel::OM->Get('Kernel::System::UnitTest::Param');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=item ParamUploadSet()

This function set an file path as a upload parameter for the param object.

    my $Success = $UnitTestParamObject->ParamUploadSet(
        Name     => 'Upload',
        Location => '...',
    );

Returns:

    my $Success = 1;

=cut

sub ParamUploadSet {
    my ( $Self, %Param ) = @_;

    my $LogObject   = $Kernel::OM->Get('Kernel::System::Log');
    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    # check needed stuff
    NEEDED:
    for my $Needed (qw(Name Location)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $Name     = $Param{Name};
    my $Location = $Param{Location};
    my ( $Volume, $Directories, $Filename ) = File::Spec->splitpath($Location);

    my $FH;
    open( $FH, '<', $Location );    ## no critic

    $ParamObject->{Query}->param(
        -name   => $Name,
        -values => [ $Filename, $FH ],
    );

    return 1;
}

=item ParamSet()

This function set a parameter for the param object.

    my $Success = $UnitTestParamObject->ParamSet(
        Name  => 'Upload',
        Value => '...',
    );

Returns:

    my $Success = 1;

=cut

sub ParamSet {
    my ( $Self, %Param ) = @_;

    my $LogObject   = $Kernel::OM->Get('Kernel::System::Log');
    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');

    # check needed stuff
    NEEDED:
    for my $Needed (qw(Name)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $Name  = $Param{Name};
    my $Value = $Param{Value};

    $ParamObject->{Query}->param(
        -name   => $Name,
        -values => $Value,
    );

    return 1;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
