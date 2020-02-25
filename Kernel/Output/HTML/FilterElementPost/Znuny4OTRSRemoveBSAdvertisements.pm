# --
# Copyright (C) 2012-2020 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::FilterElementPost::Znuny4OTRSRemoveBSAdvertisements;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Output::HTML::Layout',
);

use Kernel::System::VariableCheck qw(:all);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->AgentAppointmentEdit(%Param);
    $Self->AdminCloudServices(%Param);
    $Self->AdminNotificationEvent(%Param);
    $Self->AdminProcessManagement(%Param);
    $Self->AdminAppointmentNotificationEvent(%Param);
    $Self->Error(%Param);
    $Self->Footer(%Param);
    $Self->AdminPackageManager(%Param);

    return 1;
}

sub AgentAppointmentEdit {
    my ( $Self, %Param ) = @_;

    return if $Param{TemplateFile} ne 'AgentAppointmentEdit';

=for comment

Remove the following block:

    <div class="Field Info">
        <a href="[% Env("Baselink") %]Action=AdminOTRSBusiness" class="Button"><i class="fa fa-angle-double-up"></i> Auf <strong>OTRS Business Solution</strong>™ upgraden</a>
    </div>

=cut

    ${ $Param{Data} } =~ s{
        <div [^>]+ Field [^>]+ Info [^>]+ >
            \s*
            <a [^>]+ AdminOTRSBusiness [^>]+> .+? <\/a>
            \s*
        <\/div>
    }{}xmsi;

    return 1;
}

sub AdminCloudServices {
    my ( $Self, %Param ) = @_;

    return if $Param{TemplateFile} ne 'AdminCloudServices';

=for comment

Remove the following block:

    <span class="Recomendation">
        <a class="MasterActionLink Button" href="[% Env("Baselink") %]Action=AdminOTRSBusiness"><i class="fa fa-angle-double-up"></i> [% Translate("Upgrade to %s", OTRSBusinessLabel) %]</a>
    </span>

=cut

    ${ $Param{Data} } =~ s{
        <span [^>]+ Recomendation [^>]+ >
            \s*
            <a [^>]+ AdminOTRSBusiness [^>]+> .+? <\/a>
            \s*
        <\/span>
    }{}xmsi;

    return 1;
}

sub AdminNotificationEvent {
    my ( $Self, %Param ) = @_;

    return if $Param{TemplateFile} ne 'AdminNotificationEvent';

=for comment

Remove the following block:

     <div class="Field Info">
         <a href="[% Env("Baselink") %]Action=AdminOTRSBusiness" class="Button"><i class="fa fa-angle-double-up"></i> [% Translate("Upgrade to %s", OTRSBusinessLabel) %]</a>
     </div>

=cut

    ${ $Param{Data} } =~ s{
        <div [^>]+ Field [^>]+ Info [^>]+ >
            \s*
            <a [^>]+ AdminOTRSBusiness [^>]+> .+? <\/a>
            \s*
        <\/div>
    }{}xmsi;

    return 1;
}

sub AdminProcessManagement {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    return if $Param{TemplateFile} ne 'AdminProcessManagement';

=for comment

Remove the following block:

        <div class="WidgetSimple">
            <div class="Header">
                <h2>[% Translate("Example processes") | html %]</h2>
            </div>
            <div class="Content">
            [% IF Data.ExampleProcessList %]
                <p class="FieldExplanation">
                    [% Translate("Here you can activate best practice example processes that are part of %s. Please note that some additional configuration may be required.", OTRSBusinessLabel) %]
                </p>
                <ul class="ActionList SpacingTop">
                    <li>
                        <form action="[% Env("CGIHandle") %]" method="post" enctype="multipart/form-data" class="Validate PreventMultipleSubmits">
                            <input type="hidden" name="Action" value="[% Env("Action") %]"/>
                            <input type="hidden" name="Subaction" value="ProcessImport"/>
                            <input type="hidden" name="FormID" value="[% Data.FormID | html %]"/>
                            [% Data.ExampleProcessList %]
                            <div id="ExampleProcessError" class="TooltipErrorMessage"><p>[% Translate("This field is required.") | html %]</p></div>
                            <div id="ExampleProcessServerError" class="TooltipErrorMessage"><p>[% Translate("This field is required.") | html %]</p></div>
                            <fieldset class="SpacingTop">
                                <input type="checkbox" id="OverwriteExistingEntitiesExample" name="OverwriteExistingEntities" value="1" checked="checked" />
                                <label for="OverwriteExistingEntitiesExample">[% Translate("Overwrite existing entities") | html %]</label>
                            </fieldset>
                            <button class="CallForAction Fullsize Center SpacingTop" type="submit" value="[% Translate("Import example process") | html %]">
                                <span><i class="fa fa-upload"></i>[% Translate("Import example process") | html %]</span>
                            </button>
                        </form>
                    </li>
                </ul>
            [% ELSE %]
                <p class="FieldExplanation">
                    [% Translate("Do you want to benefit from processes created by experts? Upgrade to %s to be able to import some sophisticated example processes.", OTRSBusinessLinkLabel) %]
                </p>
            [% END %]
            </div>
        </div>

=cut

    my $ExampleProcessesText = $LayoutObject->{LanguageObject}->Translate('Example processes');
    my $DescriptionText      = $LayoutObject->{LanguageObject}->Translate('Description');

    ${ $Param{Data} } =~ s{
        <div [^>]+ WidgetSimple [^>]+ >
            \s*
            <div [^>]+ >
                \s*
                <h2>\Q$ExampleProcessesText\E<\/h2>
                \s*
            <\/div>
            \s*
            <div [^>]+ Content [^>]+ >
                .+?
            <\/div>
            \s*
        <\/div>
        (\s*
        <div [^>]+ WidgetSimple [^>]+ >
            \s*
            <div [^>]+ Header [^>]+ >
                \s*
                <h2>\Q$DescriptionText\E<\/h2>)
    }{$1}xmsi;

    return 1;
}

sub AdminAppointmentNotificationEvent {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    return if $Param{TemplateFile} ne 'AdminAppointmentNotificationEvent';

=for comment

Remove the following block:

[% RenderBlockStart("TransportRowDisabled") %]
                        <div class="Field">
                            <p class="FieldExplanation">
                                [% Translate("This feature is currently not available.") | html %]
                            </p>
                        </div>
[% RenderBlockEnd("TransportRowDisabled") %]
[% RenderBlockStart("TransportRowRecommendation") %]
                        <div class="Field Info">
                            <a href="[% Env("Baselink") %]Action=AdminOTRSBusiness" class="Button"><i class="fa fa-angle-double-up"></i> [% Translate("Upgrade to %s", OTRSBusinessLabel) %]</a>
                        </div>
[% RenderBlockEnd("TransportRowRecommendation") %]

=cut

    my $FeatureNotAvailableText
        = $LayoutObject->{LanguageObject}->Translate('This feature is currently not available.');

    ${ $Param{Data} } =~ s{
        <fieldset \s class="TableLike \s FixedLabel \s SpacingTop"> \s*
            <legend><span> [^<]* <\/span><\/legend> \s*
            <div \s class="Field"> \s*
                <p \s class="FieldExplanation"> \s*
                    .*?
                <\/p> \s*
            <\/div> \s*
            <div \s class="Field \s Info"> \s*
                <a \s href=" [^?]* \? Action=AdminOTRSBusiness" \s class="Button">.*?<\/a> \s*
            <\/div> \s*
            <div \s class="Clear"><\/div> \s*
        <\/fieldset>
    }{}xmsig;

    return 1;
}

sub Error {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    return if $Param{TemplateFile} ne 'Error';

=for comment

Remove the following block:

    [% IF !Data.OTRSBusinessIsInstalled %]
    <div class="MessageBox Info">
        <p class="SpacingTop">
            [% Translate("Really a bug? 5 out of 10 bug reports result from a wrong or incomplete installation of OTRS.") | html %]
            [% Translate("With %s, our experts take care of correct installation and cover your back with support and periodic security updates.", '<b>OTRS Business Solution™</b>') %]
            <br /><br />
            <a class="Button" href="https://www.otrs.com/contact/" target="_blank">
                [% Translate("Contact our service team now.") | html %]
            </a>
        </p>
    </div>
    [% END %]

=cut

    my $ServiceTeamText = $LayoutObject->{LanguageObject}->Translate('Contact our service team now.');

    ${ $Param{Data} } =~ s{
        <div [^>]+ MessageBox [^>]+ Info [^>]+ >
            \s*
            <p [^>]+ SpacingTop [^>]+ >
                .+?
                <a [^>]+ otrs [^>]+ contact [^>]+ >
                    \s* \Q$ServiceTeamText\E \s*
                <\/a>
                \s*
            <\/p>
            \s*
        <\/div>
    }{}xmsi;

    return 1;
}

sub Footer {
    my ( $Self, %Param ) = @_;

    return if $Param{TemplateFile} ne 'Footer';

=for comment

Remove the following block:

    $('body').on('click', 'a.OTRSBusinessRequired', function() {
        Core.UI.Dialog.ShowContentDialog(
            '<div class="OTRSBusinessRequiredDialog">' + [% Translate('This feature is part of the %s.  Please contact us at %s for an upgrade.', OTRSBusinessLabel, 'sales@otrs.com') | JSON %] + '<a class="Hidden" href="http://www.otrs.com/solutions/" target="_blank"><span></span></a></div>',
            '',
            '240px',
            'Center',
            true,
            [
               {
                   Label: [% Translate('Close') | JSON %],
                   Class: 'Primary',
                   Function: function () {
                       Core.UI.Dialog.CloseDialog($('.OTRSBusinessRequiredDialog'));
                   }
               },
               {
                   Label: [% Translate('Find out more about the %s', 'OTRS Business Solution™') | JSON %],
                   Class: 'Primary',
                   Function: function () {
                       $('.OTRSBusinessRequiredDialog').find('a span').trigger('click');
                   }
               }
            ]
        );
        return false;
    });

=cut

    ${ $Param{Data} }
        =~ s{ \$\('body'\)\.on\('click', \s 'a\.OTRSBusinessRequired', \s function\(\) \s \{ .*? \); \s* return \s false; \s* \}\); }{}xmsi;

    return 1;
}

sub AdminPackageManager {
    my ( $Self, %Param ) = @_;

    return if $Param{TemplateFile} ne 'AdminPackageManager';

=for comment

Remove the following block:

    <li>
        <p class="FieldExplanation Error">
            [% Translate("Cloud services are currently disabled.") | html %]
            </br>
            [% Translate("OTRS Verify™ can not continue!") | html %]
        </p>
        <form action="[% Env("CGIHandle") %]" method="post">
            <input type="hidden" name="Action" value="AdminSysConfig"/>
            <input type="hidden" name="Subaction" value="Edit"/>
            <input type="hidden" name="SysConfigGroup" value="CloudService"/>
            <input type="hidden" name="SysConfigSubGroup" value="Core"/>
            <fieldset>
                <button class="Fullsize CallForAction LittleSpacingTop Center" type="submit" value="[% Translate("Enable cloud services") | html %]">
                    <span><i class="fa fa-cloud"></i> [% Translate("Enable cloud services") | html %]</span>
                </button>
            </fieldset>
        </form>
    </li>

=cut

    ${ $Param{Data} }
        =~ s{<!--HookStartCloudServicesWarning-->.*?<!--HookEndCloudServicesWarning-->}{}ms;

    return 1;
}

1;
