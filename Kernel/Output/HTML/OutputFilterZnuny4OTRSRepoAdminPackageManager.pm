# --
# Copyright (C) 2012-2017 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::OutputFilterZnuny4OTRSRepoAdminPackageManager;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::AuthSession',
);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject  = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');
    my $SessionObject = $Kernel::OM->Get('Kernel::System::AuthSession');

    return if $LayoutObject->{Action} ne 'AdminPackageManager';

    my $RepoDisabled = $ConfigObject->Get('Znuny4OTRSRepoDisable') // 0;
    my $RemoveOnlineRepository = $RepoDisabled == 1 ? 1 : 0;

    # If only Znuny repositories are disabled, remove online repository
    # if it previously has been generated with a Znuny URL
    if ( !$RemoveOnlineRepository && $RepoDisabled == 2 ) {
        my $SessionID   = $LayoutObject->{SessionID};
        my %SessionData = $SessionObject->GetSessionIDData(
            SessionID => $SessionID,
        );
        if (
            %SessionData
            && $SessionData{UserRepository}
            && $SessionData{UserRepository} =~ m{znuny}i
            )
        {
            $RemoveOnlineRepository = 1;
        }
    }

    if ($RemoveOnlineRepository) {
        my $OnlineRepositoryTranslatedString = $LayoutObject->{LanguageObject}->Translate('Online Repository');
        ${ $Param{Data} } =~ s{
            <div\s*class="WidgetSimple">
            \s*
            <div\s*class="Header">
            \s*
            <h2>$OnlineRepositoryTranslatedString</h2>
            .*?
            </tbody>
            \s*
            </table>
            \s*
            </div>
            \s*
            </div>
            \s*
            <br/>
        }{}smx;
    }

    return 1 if $RepoDisabled != 1;

    # Remove "Update repository information"
    my $UpdateRepositoryTranslatedString = $LayoutObject->{LanguageObject}->Translate('Update repository information');
    ${ $Param{Data} } =~ s{<li>.*?<button .*?$UpdateRepositoryTranslatedString.*?</li>}{}sm;

    # Remove separator
    ${ $Param{Data} } =~ s{(<ul class="ActionList">\s*<li) class="Separated"(>\s*<form)}{$1$2}sm;

    return 1;
}

1;
