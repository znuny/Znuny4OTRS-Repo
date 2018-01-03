# --
# Copyright (C) 2012-2018 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::FilterElementPost::Znuny4OTRSRepoAdminPackageManager;

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

    return if ${ $Param{Data} } !~ m{<!--HookStartOverview-->}sm;

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
            (?<=<!--HookEndOverviewFileUpload-->)
            (.*?)
            <div\s*class="WidgetSimple">
            .*?
            <h2>$OnlineRepositoryTranslatedString</h2>
            .*?
            <!--HookEndShowRemotePackage-->
            \s*
            </tbody>
            \s*
            </table>
            \s*
            </div>
            \s*
            </div>
            \s*
            <br/>
        }{$1}smx;
    }

    return if $RepoDisabled != 1;

    # Remove "Update repository information"
    ${ $Param{Data} } =~ s{(?<=<!--HookEndOverviewFileUpload-->)\s*<li>.*?</li>}{}sm;

    # Remove separator
    ${ $Param{Data} } =~ s{(?<=<!--HookStartOverviewFileUpload-->)(\s*<li) class="Separated"(>)}{$1$2}sm;

    return 1;
}

1;
