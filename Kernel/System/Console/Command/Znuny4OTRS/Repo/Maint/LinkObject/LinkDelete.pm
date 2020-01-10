# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2012-2020 Znuny GmbH, http://znuny.com/
# --
# $origin: otrs - pull - 1973 - Kernel/System/Console/Command/Maint/LinkObject/LinkDelete.pm
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Console::Command::Znuny4OTRS::Repo::Maint::LinkObject::LinkDelete;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::System::LinkObject',
    'Kernel::System::Log',
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Delete link for objects.');
    $Self->AddOption(
        Name        => 'source-object',
        Description => "The source link object (e.g. 'Ticket').",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/.*/,
    );
    $Self->AddOption(
        Name        => 'source-key',
        Description => "The source link key.",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/.*/,
    );
    $Self->AddOption(
        Name        => 'target-object',
        Description => "The source link object (e.g. 'Ticket').",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/.*/,
    );
    $Self->AddOption(
        Name        => 'target-key',
        Description => "The source link key.",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/.*/,
    );
    $Self->AddOption(
        Name        => 'type',
        Description => "The type for the link (e.g. 'Normal', 'ParentChild').",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/.*/,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LinkObject = $Kernel::OM->Get('Kernel::System::LinkObject');
    my $LogObject  = $Kernel::OM->Get('Kernel::System::Log');

    $Self->Print("<yellow>Delete link for objects...</yellow>\n\n");

    my $SourceObject = $Self->GetOption('source-object');
    my $SourceKey    = $Self->GetOption('source-key');
    my $TargetObject = $Self->GetOption('target-object');
    my $TargetKey    = $Self->GetOption('target-key');
    my $Type         = $Self->GetOption('type');

    # link add
    my $Success = $LinkObject->LinkDelete(
        Object1 => $SourceObject,
        Key1    => $SourceKey,
        Object2 => $TargetObject,
        Key2    => $TargetKey,
        Type    => $Type,
        UserID  => 1,
    );

    if (!$Success) {
        my $Message = $LogObject->GetLogEntry(
            Type => 'error',
            What => 'Message',
        );

        $Self->PrintError("$Message\n");
        return $Self->ExitCodeError();
    }

    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
