# --
# Copyright (C) 2012-2018 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::OTRS::Znuny4OTRS::CacheCleanup)

package Kernel::System::UnitTest::Scheduler;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::Daemon::SchedulerDB',
    'Kernel::System::Log',
);

=head1 NAME

Kernel::System::UnitTest::Scheduler - Scheduler lib

=head1 SYNOPSIS

All Scheduler functions

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $UnitTestSchedulerObject = $Kernel::OM->Get('Kernel::System::UnitTest::Scheduler');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->CleanUp();

    return $Self;
}

=item CleanUp()

This function removes all entries in the SchedulerDB.

    my $Success = $UnitTestSchedulerObject->CleanUp(
        Type => 'AsynchronousExecutor', # optional
    );

=cut

sub CleanUp {
    my ( $Self, %Param ) = @_;

    my $SchedulerDBObject = $Kernel::OM->Get('Kernel::System::Daemon::SchedulerDB');

    my @DeleteTasks = $SchedulerDBObject->TaskList(
        Type => $Param{Type},
    );

    for my $DeleteTask (@DeleteTasks) {

        $SchedulerDBObject->TaskDelete(
            TaskID => $DeleteTask->{TaskID},
        );
    }

    return 1;
}

=item Execute()

This function executes all entries in the SchedulerDB.

    my $Success = $UnitTestSchedulerObject->Execute(
        Type => 'AsynchronousExecutor', # optional
    );

=cut

sub Execute {
    my ( $Self, %Param ) = @_;

    my $SchedulerDBObject = $Kernel::OM->Get('Kernel::System::Daemon::SchedulerDB');

    my @ExecuteTasks = $SchedulerDBObject->TaskList(
        Type => $Param{Type},
    );

    for my $ExecuteTask (@ExecuteTasks) {

        my %ExecuteTask = $SchedulerDBObject->TaskGet(
            TaskID => $ExecuteTask->{TaskID},
        );

        my $TaskHandlerObject
            = $Kernel::OM->Get( 'Kernel::System::Daemon::DaemonModules::SchedulerTaskWorker::' . $ExecuteTask{Type} );

        $TaskHandlerObject->Run(
            TaskID   => $ExecuteTask{TaskID},
            TaskName => $ExecuteTask{Name},
            Data     => $ExecuteTask{Data},
        );

        $SchedulerDBObject->TaskDelete(
            TaskID => $ExecuteTask{TaskID},
        );
    }

    return 1;
}

=item CheckCount()

This function checks the count of the entries in the SchedulerDB.

    my $Success = $UnitTestSchedulerObject->CheckCount(
        UnitTestObject => $Self,
        Count          => '2',
        Message        => "2 'AsynchronousExecutor' tasks added",    # optional
        Type           => 'AsynchronousExecutor',                    # optional
    );

=cut

sub CheckCount {
    my ( $Self, %Param ) = @_;

    my $SchedulerDBObject = $Kernel::OM->Get('Kernel::System::Daemon::SchedulerDB');
    my $LogObject         = $Kernel::OM->Get('Kernel::System::Log');

    # check needed stuff
    NEEDED:
    for my $Needed (qw(Count UnitTestObject)) {

        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my @CountCheckTasks = $SchedulerDBObject->TaskList(
        Type => $Param{Type},
    );

    if ( $Param{Type} ) {
        $Param{Message} ||= "$Param{Count} '$Param{Type}' tasks added";
    }
    else {
        $Param{Message} ||= "$Param{Count} tasks added";
    }

    return $Param{UnitTestObject}->Is(
        scalar @CountCheckTasks,
        $Param{Count},
        $Param{Message},
    );
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
