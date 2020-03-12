# --
# Copyright (C) 2012-2020 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::ZnunyUtil;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
);

=head1 NAME

Kernel::System::ZnunyUtil

=head1 DESCRIPTION

All ZnunyUtil functions.

=head1 PUBLIC INTERFACE

=head2 new()

Create an object. Do not use it directly, instead use:

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $ZnunyUtilObject = $Kernel::OM->Get('Kernel::System::ZnunyUtil');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = \%Param;
    bless( $Self, $Type );

    return $Self;
}

=head2 IsITSMInstalled()

Checks if ITSM is installed.

    my $IsITSMInstalled = $ZnunyUtilObject->IsITSMInstalled();

    Returns 1 if ITSM is installed and 0 otherwise.

=cut

sub IsITSMInstalled {
    my ( $Self, %Param ) = @_;

    # Use cached result because it won't change within the process.
    return $Self->{ITSMInstalled} if defined $Self->{ITSMInstalled};

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    # Just use some arbitrary ITSM::Core SysConfig option to check if ITSM is present.
    $Self->{ITSMInstalled} = $ConfigObject->Get('Frontend::Module')->{AdminITSMCIPAllocate} ? 1 : 0;

    return $Self->{ITSMInstalled};
}

=head2 IsFrontendContext()

Checks if current code is being executed in frontend context, e. g. agent frontend.

    my $IsFrontendContext = $ZnunyUtilObject->IsFrontendContext();

    Returns 1 if current code is being executed in frontend context.
    Returns 0 if otherwise (e.g. console command context).

=cut

sub IsFrontendContext {
    my ( $Self, %Param ) = @_;

    # Note that "exists" is required. Otherwise Perl will create the key
    # with an undefined value which causes crashes since the object manager
    # won't work properly anymore.
    return if !exists $Kernel::OM->{Objects}->{'Kernel::Output::HTML::Layout'};

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    return if !$LayoutObject->{Action};

    return 1;
}

1;
