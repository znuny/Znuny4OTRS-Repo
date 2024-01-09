# --
# Copyright (C) 2012 Znuny GmbH, https://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::PreApplicationZnuny4OTRSRepo;

use strict;
use warnings;

our $ObjectManagerDisabled = 1;

use Kernel::System::VariableCheck qw(:all);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub PreRun {
    my ( $Self, %Param ) = @_;

    my $LayoutObject    = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ZnunyUtilObject = $Kernel::OM->Get('Kernel::System::ZnunyUtil');

    #
    # Check for CKE plugin preventimagepaste which is not available anymore in Znuny >= 6.0.31.
    # Some packages use this plugin and would fail if not able to check if it is present before.
    #
    my $IsCKEPreventImagePastePluginAvailable = $ZnunyUtilObject->IsCKEPreventImagePastePluginAvailable();

    $LayoutObject->AddJSData(
        Key   => 'CKEditor::Plugins::PreventImagePaste::Available',
        Value => $IsCKEPreventImagePastePluginAvailable,
    );

    return;
}

1;
