# --
# Copyright (C) 2012-2017 Znuny GmbH, http://znuny.com/
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
);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    return if $LayoutObject->{Action} ne 'AdminPackageManager';

    my $ReposDisabled = $ConfigObject->Get('Znuny4OTRSRepoDisable');
    return if !$ReposDisabled;

    return if ${ $Param{Data} } !~ m{<!--HookStartOverview-->}sm;

    # Remove "Update repository information"
    ${ $Param{Data} } =~ s{(?<=<!--HookEndOverviewFileUpload-->)\s*<li>.*?</li>}{}sm;

    # Remove separator
    ${ $Param{Data} } =~ s{(?<=<!--HookStartOverviewFileUpload-->)(\s*<li) class="Separated"(>)}{$1$2}sm;

    # Remove "online repository"
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

    return 1;
}

1;
