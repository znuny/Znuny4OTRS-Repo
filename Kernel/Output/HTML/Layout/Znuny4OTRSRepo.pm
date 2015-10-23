# --
# Kernel/Output/HTML/Layout/Znuny4OTRSRepo.pm
# Copyright (C) 2012-2015 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::Layout::Znuny4OTRSRepo;

use strict;
use warnings;

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::Output::HTML::Layout::Znuny4OTRSRepo - Znuny4OTRSRepo lib

=head1 SYNOPSIS

All Znuny4OTRSRepo functions.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object. Do not use it directly, instead use:

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

=cut

=item _OutputFilterHookShift()

modifies content and uses outputfilter hooks to get hook content

    my $Data = $ZnunyHelperObject->_OutputFilterHookShift(
        Name => 'DynamicField',
        All  => 1,
        %Param,
    );

Returns:

    my $Data = '.... html ...';

=cut

sub _OutputFilterHookShift {
    my ( $Self, %Param ) = @_;

    my $Name = $Param{Name};
    my $All  = $Param{All};

=for comment

Example html for a hook:

<!--HookStartDynamicField-->
        <div class="Row Row_DynamicField_ProcessManagementProcessID">
            <label id="LabelDynamicField_ProcessManagementProcessID" for="DynamicField_ProcessManagementProcessID">
                Prozess:
            </label>

            <div class="Field">
                <input type="text" class="DynamicFieldText W50pc" id="DynamicField_ProcessManagementProcessID" name="DynamicField_ProcessManagementProcessID" title="Process" value="" />
            </div>
            <div class="Clear"></div>
        </div>
<!--HookEndDynamicField-->

=cut

    my $Return    = '';
    my $HookRegex = qr{ <\!-- \s* HookStart$Name \s* --> .+? <\!-- \s* HookEnd$Name \s* --> }xmsi;
    my $Counter   = 0;

    # http://stackoverflow.com/questions/7374107/infinite-while-loop-in-perl
    HOOK:
    for my $Content ( ${ $Param{Data} } =~ m{$HookRegex}g ) {

        $Return .= $Content;

        ${ $Param{Data} } =~ s{\Q$Content\E}{};
        $Counter++;

        last HOOK if $Counter > 1000;
        last HOOK if !$All;
    }

    return $Return;
}

=item _OutputFilterHookReplace()

modifies content and uses outputfilter hooks to get hook content

    my $Success = $ZnunyHelperObject->_OutputFilterHookReplace(
        Name    => 'DynamicField',
        All     => 1,
        Replace => sub {
            my ( $Self, %Param ) = @_;

            my $Content = $Param{Content};

            $Content =~ s{test}{test2};

            return $Content;
        },
        %Param,
    );

Returns:

    my $Success = 1;

=cut

sub _OutputFilterHookReplace {
    my ( $Self, %Param ) = @_;

    my $All     = $Param{All};
    my $Name    = $Param{Name};
    my $Replace = $Param{Replace};

=for comment

Example html for a hook:

<!--HookStartDynamicField-->
        <div class="Row Row_DynamicField_ProcessManagementProcessID">
            <label id="LabelDynamicField_ProcessManagementProcessID" for="DynamicField_ProcessManagementProcessID">
                Prozess:
            </label>

            <div class="Field">
                <input type="text" class="DynamicFieldText W50pc" id="DynamicField_ProcessManagementProcessID" name="DynamicField_ProcessManagementProcessID" title="Process" value="" />
            </div>
            <div class="Clear"></div>
        </div>
<!--HookEndDynamicField-->

=cut

    my $Success;
    my $HookRegex = qr{ <\!-- \s* HookStart$Name \s* --> (.+?) <\!-- \s* HookEnd$Name \s* --> }xmsi;
    my $Counter   = 0;

    # http://stackoverflow.com/questions/7374107/infinite-while-loop-in-perl
    HOOK:
    for my $Content ( ${ $Param{Data} } =~ m{$HookRegex}g ) {

        my $ContentNew = $Replace->(
            %Param,
            Content => $Content,
        );

        ${ $Param{Data} } =~ s{\Q$Content\E}{$ContentNew};
        $Success = 1;
        $Counter++;

        last HOOK if $Counter > 1000;
        last HOOK if !$All;
    }

    return $Success;
}

=item _OutputFilterHookExists()

modifies content and uses outputfilter hooks to check if a hook exists

    my $Exists = $ZnunyHelperObject->_OutputFilterHookExists(
        Name => 'DynamicField',
        %Param,
    );

Returns:

    my $Exists = 1;

=cut

sub _OutputFilterHookExists {
    my ( $Self, %Param ) = @_;

    my $Name = $Param{Name};

=for comment

Example html for a hook:

<!--HookStartDynamicField-->
        <div class="Row Row_DynamicField_ProcessManagementProcessID">
            <label id="LabelDynamicField_ProcessManagementProcessID" for="DynamicField_ProcessManagementProcessID">
                Prozess:
            </label>

            <div class="Field">
                <input type="text" class="DynamicFieldText W50pc" id="DynamicField_ProcessManagementProcessID" name="DynamicField_ProcessManagementProcessID" title="Process" value="" />
            </div>
            <div class="Clear"></div>
        </div>
<!--HookEndDynamicField-->

=cut

    my $Return    = '';
    my $HookRegex = qr{ <\!-- \s* HookStart$Name \s* --> .+? <\!-- \s* HookEnd$Name \s* --> }xmsi;

    return if ${ $Param{Data} } !~ $HookRegex;
    return 1;
}

=item _OutputFilterHookInsertAfter()

modifies content and uses outputfilter hooks to add content after hook.

    my $Success = $ZnunyHelperObject->_OutputFilterHookInsertAfter(
        Name    => 'DynamicField',
        Content => '... html ...',
        %Param,
    );

Returns:

    my $Success = 1;

=cut

sub _OutputFilterHookInsertAfter {
    my ( $Self, %Param ) = @_;

    my $Name    = $Param{Name};
    my $Content = $Param{Content};

=for comment

Example html for a hook:

<!--HookStartDynamicField-->
        <div class="Row Row_DynamicField_ProcessManagementProcessID">
            <label id="LabelDynamicField_ProcessManagementProcessID" for="DynamicField_ProcessManagementProcessID">
                Prozess:
            </label>

            <div class="Field">
                <input type="text" class="DynamicFieldText W50pc" id="DynamicField_ProcessManagementProcessID" name="DynamicField_ProcessManagementProcessID" title="Process" value="" />
            </div>
            <div class="Clear"></div>
        </div>
<!--HookEndDynamicField-->

=cut

    return if !$Self->_OutputFilterHookExists(%Param);

    my $HookRegex = qr{ <\!-- \s* HookStart$Name \s* --> .+? <\!-- \s* HookEnd$Name \s* --> }xmsi;

    ${ $Param{Data} } =~ s{$HookRegex}{ $& $Content }xmsig;

    return 1;
}

=item _OutputFilterHookInsertBefore()

modifies content and uses outputfilter hooks to add content before hook.

    my $Success = $ZnunyHelperObject->_OutputFilterHookInsertBefore(
        Name    => 'DynamicField',
        Content => '... html ...',
        %Param,
    );

Returns:

    my $Success = 1;

=cut

sub _OutputFilterHookInsertBefore {
    my ( $Self, %Param ) = @_;

    my $Name    = $Param{Name};
    my $Content = $Param{Content};

=for comment

Example html for a hook:

<!--HookStartDynamicField-->
        <div class="Row Row_DynamicField_ProcessManagementProcessID">
            <label id="LabelDynamicField_ProcessManagementProcessID" for="DynamicField_ProcessManagementProcessID">
                Prozess:
            </label>

            <div class="Field">
                <input type="text" class="DynamicFieldText W50pc" id="DynamicField_ProcessManagementProcessID" name="DynamicField_ProcessManagementProcessID" title="Process" value="" />
            </div>
            <div class="Clear"></div>
        </div>
<!--HookEndDynamicField-->

=cut

    return if !$Self->_OutputFilterHookExists(%Param);

    my $HookRegex = qr{ <\!-- \s* HookStart$Name \s* --> .+? <\!-- \s* HookEnd$Name \s* --> }xmsi;

    ${ $Param{Data} } =~ s{$HookRegex}{ $Content $& }xmsig;

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
