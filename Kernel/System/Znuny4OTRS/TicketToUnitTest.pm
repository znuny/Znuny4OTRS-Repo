# --
# Copyright (C) 2012-2017 Znuny GmbH, http://znuny.com/
# --
# $origin: otrs - 0000000000000000000000000000000000000000 - Kernel/System/Znuny4OTRS/TicketToUnitTest.pm
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Znuny4OTRS::TicketToUnitTest;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Cache',
    'Kernel::System::CustomerUser',
    'Kernel::System::DB',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::Priority',
    'Kernel::System::Queue',
    'Kernel::System::SLA',
    'Kernel::System::Service',
    'Kernel::System::State',
    'Kernel::System::Ticket',
    'Kernel::System::Time',
    'Kernel::System::Type',
    'Kernel::System::UnitTest::Helper',
    'Kernel::System::User',
);

use Kernel::System::VariableCheck qw(:all);

=head1 NAME

Kernel::System::Znuny4OTRS::TicketToUnitTest - creates unittest

=head1 SYNOPSIS

All TicketToUnitTest functions

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $TicketToUnitTestObject = $Kernel::OM->Get('Kernel::System::Znuny4OTRS::TicketToUnitTest');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

=item CreateUnitTest()

This function creates a unittest

    my $Output = $TicketToUnitTestObject->CreateUnitTest(
        TicketID => 123456,
    );

Returns:

    my $Output = 'UNITTEST-OUTPUT';

=cut

sub CreateUnitTest {
    my ( $Self, %Param ) = @_;

    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $TimeObject   = $Kernel::OM->Get('Kernel::System::Time');
    my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');

    # check needed stuff
    NEEDED:
    for my $Needed (qw(TicketID)) {
        next NEEDED if defined $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    # modul registrierung disabled / download / senden
    # Gruppe admin
    # Console::Command STDOut
    # dependencies

    my $UnitTest          = '';
    my $Output            = '';
    my $CurrentSystemTime = 0;
    my $UserID            = 1;
    my %TicketAttributes;

    my $Home           = $ConfigObject->Get('Home');
    my $Znuny4OTRSHome = "Kernel/System/Znuny4OTRS/TicketToUnitTest";

    my @HistoryLines = $TicketObject->HistoryGet(
        TicketID => $Param{TicketID},
        UserID   => $UserID,
    );

    LINE:
    for my $HistoryLine (@HistoryLines) {

        my $TimeStamp  = $HistoryLine->{CreateTime};
        my $SystemTime = $TimeObject->TimeStamp2SystemTime(
            String => $TimeStamp,
        );

        my %HistoryTicket = $Self->SystemTimeTicketGet(
            TicketID   => $Param{TicketID},
            SystemTime => $SystemTime,
        );

        # creates list of needed ticket attributes
        ATTRIBUTE:
        for my $Attribute (qw(Queue Type State Priority Owner Responsible CustomerUser Service SLA)) {

            my $AttributeKey = $Attribute;

            if ( $Attribute eq "Responsible" || $Attribute eq "Owner" ) {
                $AttributeKey = "User";
            }

            next ATTRIBUTE if !$HistoryTicket{$Attribute};
            next ATTRIBUTE if grep { $HistoryTicket{$Attribute} eq $_ } @{ $TicketAttributes{$AttributeKey} };
            push @{ $TicketAttributes{$AttributeKey} }, $HistoryTicket{$Attribute};
        }

        my $Module = "Kernel::System::Znuny4OTRS::TicketToUnitTest::$HistoryLine->{HistoryType}";
        my $LoadedModule = $MainObject->Require(
            $Module,
            Silent => 1,
        );

        if ( !$LoadedModule){
            $Output .= "# ATTENTION: Can't find modul for '$HistoryLine->{HistoryType}' Entry - $HistoryLine->{Name}\n";
            next LINE;
        }

        my $ModulOutput
            .= $Kernel::OM->Get($Module)->Run(
            %{$HistoryLine},
            %HistoryTicket,
        );

        next LINE if !$ModulOutput;
        $Output .= $ModulOutput;

        if ( $CurrentSystemTime < $SystemTime ) {

            $CurrentSystemTime = $SystemTime;

            my $TimeSetOutput = <<TIMESET;
# $TimeStamp
\$HelperObject->FixedTimeSet($SystemTime);
TIMESET

            $Output .= $TimeSetOutput . "\n";
        }
    }

    $Output .= <<'DEBUG';
# TODO: Remove if not needed anymore
# Otherwise the HelperObject won't
# delete the Ticket
delete $HelperObject->{TestTickets};
DEBUG

    my $Header        = $Self->GetHeader();
    my $NeededObjects = $Self->GetNeededObjects(%TicketAttributes);
    my $CreateObjects = $Self->GetCreateObjects(%TicketAttributes);

    $UnitTest = $Header;
    $UnitTest .= $NeededObjects;
    $UnitTest .= $CreateObjects;
    $UnitTest .= $Output;

    return $UnitTest;

}

=item GetHeader()

This function creates the unittest header

Returns:

    my $Output = 'UNITTEST-HEADER';

=cut

sub GetHeader {
    my ( $Self, %Param ) = @_;

    my $Header = <<'HEADER';
# ---
# Copyright (C) 2012-2017 Znuny GmbH, http://znuny.com/
# ---
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# ---

use strict;
use warnings;
use utf8;

use vars (qw($Self));

use Kernel::System::VariableCheck qw(:all);

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreSystemConfiguration => 1,
        RestoreDatabase            => 1,
    },
);

my $UserID = 1;
my $Success;
my $ArticleID;

HEADER

    return $Header;
}

=item GetNeededObjects()

This function creates the needed OM objects

Returns:

    my $Output = '
        # get needed objects
        my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
        my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    ';

=cut

sub GetNeededObjects {
    my ( $Self, %TicketAttributes ) = @_;

    my $Objects;
    my $DefaultObjects = <<'OBJECTS';
# get needed objects
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
OBJECTS

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $BackendObject      = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    for my $Attribute ( sort keys %TicketAttributes ) {
        $Objects .= "my \$" . $Attribute . "Object = \$Kernel::OM->Get('Kernel::System::" . $Attribute . "');\n";
    }

    $Objects = $DefaultObjects . $Objects . "\n";

    return $Objects;
}

=item GetCreateObjects()

This function creates the needed objects

Returns:

    my $Output = 'todo';

=cut

sub GetCreateObjects {
    my ( $Self, %TicketAttributes ) = @_;

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $BackendObject      = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my $PriorityObject     = $Kernel::OM->Get('Kernel::System::Priority');
    my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');
    my $QueueObject        = $Kernel::OM->Get('Kernel::System::Queue');
    my $UserObject         = $Kernel::OM->Get('Kernel::System::User');
    my $ServiceObject      = $Kernel::OM->Get('Kernel::System::Service');
    my $SLAObject          = $Kernel::OM->Get('Kernel::System::SLA');
    my $StateObject        = $Kernel::OM->Get('Kernel::System::State');
    my $TypeObject         = $Kernel::OM->Get('Kernel::System::Type');

    my $CreateObjects;

    if ($TicketAttributes{Priority}){

        for my $Priority (@{$TicketAttributes{Priority}}){

            my $PriorityID = $PriorityObject->PriorityLookup(
                Priority => '3 normal',
            );

            my %PriorityData = $PriorityObject->PriorityGet(
                PriorityID => $PriorityID,
                UserID     => 1,
            );

            $CreateObjects .= <<OBJECTS;
my \$True = \$PriorityObject->PriorityAdd(
    Name    => '$PriorityData{Name}',
    ValidID => '$PriorityData{ValidID}',
    UserID  => 1,
);

OBJECTS
        }
    }

    if ($TicketAttributes{CustomerUser}){

        for my $CustomerUser (@{$TicketAttributes{CustomerUser}}){

            my %CustomerUserData = $CustomerUserObject->CustomerUserDataGet(
                User => $CustomerUser,
            );

            $CreateObjects .= <<OBJECTS;
my \$CustomerUserLogin = \$CustomerUserObject->CustomerUserAdd(
    Source         => '$CustomerUserData{Source}',
    UserFirstname  => '$CustomerUserData{UserFirstname}',
    UserLastname   => '$CustomerUserData{UserLastname}',
    UserCustomerID => '$CustomerUserData{UserCustomerID}',
    UserLogin      => '$CustomerUserData{UserLogin}',
    UserPassword   => '$CustomerUserData{UserPassword}',
    UserEmail      => '$CustomerUserData{UserEmail}',
    ValidID        => '$CustomerUserData{ValidID}',
    UserID         => 1,
);

OBJECTS
        }
    }

    if ($TicketAttributes{Queue}){

        for my $Queue (@{$TicketAttributes{Queue}}){

            my %QueueData = $QueueObject->QueueGet(
                Name  => $Queue,
            );

# todo
# GroupID
# SystemAddressID
# SalutationID
# SignatureID

            for my $Value (sort keys %QueueData){
                $QueueData{$Value} //= '';
            }

            $CreateObjects .= <<OBJECTS;
\$QueueObject->QueueAdd(
    Name                => '$QueueData{Name}',
    ValidID             => '$QueueData{ValidID}',
    GroupID             => '$QueueData{GroupID}',
    Calendar            => '$QueueData{Calendar}',
    FirstResponseTime   => '$QueueData{FirstResponseTime}',
    FirstResponseNotify => '$QueueData{FirstResponseNotify}',
    UpdateTime          => '$QueueData{UpdateTime}',
    UpdateNotify        => '$QueueData{UpdateNotify}',
    SolutionTime        => '$QueueData{SolutionTime}',
    SolutionNotify      => '$QueueData{SolutionNotify}',
    UnlockTimeout       => '$QueueData{UnlockTimeout}',
    FollowUpID          => '$QueueData{FollowUpID}',
    FollowUpLock        => '$QueueData{FollowUpLock}',
    DefaultSignKey      => '$QueueData{DefaultSignKey}',
    SystemAddressID     => '$QueueData{SystemAddressID}',
    SalutationID        => '$QueueData{SalutationID}',
    SignatureID         => '$QueueData{SignatureID}',
    Comment             => '$QueueData{Comment}',
    UserID              => 1,
);

OBJECTS
        }

    }

    if ($TicketAttributes{State}){

        for my $State (@{$TicketAttributes{State}}){

            my %StateData = $StateObject->StateGet(
                Name  => $State,
            );

            $CreateObjects .= <<OBJECTS;
my \$ID = \$StateObject->StateAdd(
    Name    => '$StateData{Name}',
    Comment => '$StateData{Comment}',
    ValidID => '$StateData{ValidID}',
    TypeID  => '$StateData{TypeID}',
    UserID  => 1,
);

OBJECTS
        }

    }

    if ($TicketAttributes{Type}){

        for my $Type (@{$TicketAttributes{Type}}){

            my %TypeData = $TypeObject->TypeGet(
                Name  => $Type,
            );

            $CreateObjects .= <<OBJECTS;
my \$ID = \$TypeObject->TypeAdd(
    Name    => '$TypeData{Name}',
    ValidID => '$TypeData{ValidID}',
    UserID  => 1,
);

OBJECTS
        }

    }

    if ($TicketAttributes{Service}){

        for my $Service (@{$TicketAttributes{Service}}){

            my %ServiceData = $ServiceObject->ServiceGet(
                Name   => $Service,
                UserID => 1,
            );

            $ServiceData{ParentID} //= '';
            $ServiceData{Comment} //= '';

# todo
# ParentID
            $CreateObjects .= <<OBJECTS;
my \$ServiceID = \$ServiceObject->ServiceAdd(
    Name     => '$ServiceData{Name}',
    ParentID => '$ServiceData{ParentID}',
    ValidID  => '$ServiceData{ValidID}',
    Comment  => '$ServiceData{Comment}',
    UserID   => 1,
);

OBJECTS
        }

    }

    if ($TicketAttributes{SLA}){

        for my $SLA (@{$TicketAttributes{SLA}}){

            my $SLAID = $SLAObject->SLALookup(
                Name => $SLA,
            );

            my %SLAData = $SLAObject->SLAGet(
                SLAID  => $SLAID,
                UserID => 1,
            );

            my $ServiceIDs = '[';
            for my $ServiceID (@{$SLAData{ServiceIDs}}){
                $ServiceIDs .= "'$ServiceID',";
            }

            $ServiceIDs .= ']';

# todo
# correct service IDs

            $CreateObjects .= <<OBJECTS;
my \$SLAID = \$SLAObject->SLAAdd(
    ServiceIDs          => $ServiceIDs,
    Name                => '$SLAData{Name}',
    Calendar            => '$SLAData{Calendar}',
    FirstResponseTime   => '$SLAData{FirstResponseTime}',
    FirstResponseNotify => '$SLAData{FirstResponseNotify}',
    UpdateTime          => '$SLAData{UpdateTime}',
    UpdateNotify        => '$SLAData{UpdateNotify}',
    SolutionTime        => '$SLAData{SolutionTime}',
    SolutionNotify      => '$SLAData{SolutionNotify}',
    ValidID             => '$SLAData{ValidID}',
    Comment             => '$SLAData{Comment}',
    UserID              => 1,
);

OBJECTS
        }

    }

    if ($TicketAttributes{User}){

        for my $User (@{$TicketAttributes{User}}){

            my %UserData = $UserObject->GetUserData(
                User => $User,
            );

            $CreateObjects .= <<OBJECTS;
my \$UserID = \$UserObject->UserAdd(
    UserFirstname => '$UserData{UserFirstname}',
    UserLastname  => '$UserData{UserLastname}',
    UserLogin     => '$UserData{UserLogin}',
    UserPw        => '$UserData{UserPw}',
    UserEmail     => '$UserData{UserEmail}',
    ValidID       => '$UserData{ValidID}',
    ChangeUserID  => 1,
);

OBJECTS
        }
    }

    return $CreateObjects;
}


=item SystemTimeTicketGet()

Returns the HistoryTicketGet for a given SystemTime and TicketID.

    my %HistoryData = $BaseObject->SystemTimeTicketGet(
        SystemTime => 19435456436,
        TicketID   => 123,
        Force      => 0, # cache
    );

    %HistoryData = (
        TicketID                => 'TicketID'
        Type                    => 'Type'
        TypeID                  => 'TypeID'
        Queue                   => 'Queue'
        QueueID                 => 'QueueID'
        Priority                => 'Priority'
        PriorityID              => 'PriorityID'
        State                   => 'State'
        StateID                 => 'StateID'
        Owner                   => 'Owner'
        OwnerID                 => 'OwnerID'
        CreateUserID            => 'CreateUserID'
        CreateTime (timestamp)  => 'CreateTime (timestamp)'
        CreateOwnerID           => 'CreateOwnerID'
        CreatePriority          => 'CreatePriority'
        CreatePriorityID        => 'CreatePriorityID'
        CreateState             => 'CreateState'
        CreateStateID           => 'CreateStateID'
        CreateQueue             => 'CreateQueue'
        CreateQueueID           => 'CreateQueueID'
        LockFirst (timestamp)   => 'LockFirst (timestamp)'
        LockLast (timestamp)    => 'LockLast (timestamp)'
        UnlockFirst (timestamp) => 'UnlockFirst (timestamp)'
        UnlockLast (timestamp)  => 'UnlockLast (timestamp)'
    );

=cut

sub SystemTimeTicketGet {
    my ( $Self, %Param ) = @_;

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $TimeObject   = $Kernel::OM->Get('Kernel::System::Time');
    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');

    # check needed stuff
    NEEDED:
    for my $Needed (qw(TicketID SystemTime)) {
        next NEEDED if $Param{$Needed};

        $LogObject->Log(
            Priority => 'error',
            Message  => "Need $Needed in SystemTimeTicketGet!"
        );
        return;
    }

    my ( $Sec, $Min, $Hour, $Day, $Month, $Year ) = $TimeObject->SystemTime2Date(
        SystemTime => $Param{SystemTime},
    );

    return $Self->HistoryTicketGet(
        StopYear   => $Year,
        StopMonth  => $Month,
        StopDay    => $Day,
        StopHour   => $Hour,
        StopMinute => $Min,
        StopSecond => $Sec,
        TicketID   => $Param{TicketID},
        Force      => $Param{Force} || 0,    # 1: don't use cache
    );
}

=item HistoryTicketGet()

returns a hash of some of the ticket data
calculated based on ticket history info at the given date.

    my %HistoryData = $TicketObject->HistoryTicketGet(
        StopYear   => 2003,
        StopMonth  => 12,
        StopDay    => 24,
        StopHour   => 10, (optional, default 23)
        StopMinute => 0,  (optional, default 59)
        StopSecond => 0,  (optional, default 59)
        TicketID   => 123,
        Force      => 0,     # 1: don't use cache
    );

returns

    TicketNumber
    TicketID
    Type
    TypeID
    Queue
    QueueID
    Priority
    PriorityID
    State
    StateID
    Owner
    OwnerID
    CreateUserID
    CreateTime (timestamp)
    CreateOwnerID
    CreatePriority
    CreatePriorityID
    CreateState
    CreateStateID
    CreateQueue
    CreateQueueID
    LockFirst (timestamp)
    LockLast (timestamp)
    UnlockFirst (timestamp)
    UnlockLast (timestamp)
# ---
# Znuny4OTRS-Repo
# ---
    CustomerID
    CustomerUser
    Service
    ServiceID
    SLA
    SLAID
    Type
# ---

=cut

sub HistoryTicketGet {
    my ( $Self, %Param ) = @_;

# ---
    # Znuny4OTRS-Repo
# ---
    my $StateObject  = $Kernel::OM->Get('Kernel::System::State');
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $UserObject   = $Kernel::OM->Get('Kernel::System::User');
    my $TypeObject   = $Kernel::OM->Get('Kernel::System::Type');
    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $CacheObject  = $Kernel::OM->Get('Kernel::System::Cache');

    my @ClosedStateList = $StateObject->StateGetStatesByType(
        StateType => ['closed'],
        Result    => 'Name',
    );

# ---

    # check needed stuff
    for my $Needed (qw(TicketID StopYear StopMonth StopDay)) {
        if ( !$Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!"
            );
            return;
        }
    }

    # TODO
    $Self->{CacheType} = 'HistoryTicketGet' . $Param{TicketID};

    $Param{StopHour}   = defined $Param{StopHour}   ? $Param{StopHour}   : '23';
    $Param{StopMinute} = defined $Param{StopMinute} ? $Param{StopMinute} : '59';
    $Param{StopSecond} = defined $Param{StopSecond} ? $Param{StopSecond} : '59';

    # format month and day params
    for my $DateParameter (qw(StopMonth StopDay)) {
        $Param{$DateParameter} = sprintf( "%02d", $Param{$DateParameter} );
    }

    my $CacheKey = 'HistoryTicketGet::'
        . join( '::', map { ( $_ || 0 ) . "::$Param{$_}" } sort keys %Param );

    my $Cached = $CacheObject->Get(
        Type => $Self->{CacheType},
        Key  => $CacheKey,
    );
    if ( ref $Cached eq 'HASH' && !$Param{Force} ) {
        return %{$Cached};
    }

    my $Time
        = "$Param{StopYear}-$Param{StopMonth}-$Param{StopDay} $Param{StopHour}:$Param{StopMinute}:$Param{StopSecond}";

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    return if !$DBObject->Prepare(
        SQL => '
            SELECT th.name, tht.name, th.create_time, th.create_by, th.ticket_id,
                th.article_id, th.queue_id, th.state_id, th.priority_id, th.owner_id, th.type_id
            FROM ticket_history th, ticket_history_type tht
            WHERE th.history_type_id = tht.id
                AND th.ticket_id = ?
                AND th.create_time <= ?
            ORDER BY th.create_time, th.id ASC',
        Bind  => [ \$Param{TicketID}, \$Time ],
        Limit => 3000,
    );

    my %Ticket;
    while ( my @Row = $DBObject->FetchrowArray() ) {

        if ( $Row[1] eq 'NewTicket' ) {
            if (
                $Row[0] =~ /^\%\%(.+?)\%\%(.+?)\%\%(.+?)\%\%(.+?)\%\%(.+?)$/
                || $Row[0] =~ /Ticket=\[(.+?)\],.+?Q\=(.+?);P\=(.+?);S\=(.+?)/
                )
            {
                $Ticket{TicketNumber}   = $1;
                $Ticket{Queue}          = $2;
                $Ticket{CreateQueue}    = $2;
                $Ticket{Priority}       = $3;
                $Ticket{CreatePriority} = $3;
                $Ticket{State}          = $4;
                $Ticket{CreateState}    = $4;
                $Ticket{TicketID}       = $Row[4];
                $Ticket{Owner}          = 'root';
                $Ticket{CreateUserID}   = $Row[3];
                $Ticket{CreateTime}     = $Row[2];
            }
            else {

                # COMPAT: compat to 1.1
                # NewTicket
                $Ticket{TicketVersion} = '1.1';
                $Ticket{TicketID}      = $Row[4];
                $Ticket{CreateUserID}  = $Row[3];
                $Ticket{CreateTime}    = $Row[2];
            }
            $Ticket{CreateOwnerID}    = $Row[9] || '';
            $Ticket{CreatePriorityID} = $Row[8] || '';
            $Ticket{CreateStateID}    = $Row[7] || '';
            $Ticket{CreateQueueID}    = $Row[6] || '';
        }

        # COMPAT: compat to 1.1
        elsif ( $Row[1] eq 'PhoneCallCustomer' ) {
            $Ticket{TicketVersion} = '1.1';
            $Ticket{TicketID}      = $Row[4];
            $Ticket{CreateUserID}  = $Row[3];
            $Ticket{CreateTime}    = $Row[2];
        }
        elsif ( $Row[1] eq 'Move' ) {
            if (
                $Row[0] =~ /^\%\%(.+?)\%\%(.+?)\%\%(.+?)\%\%(.+?)/
                || $Row[0] =~ /^Ticket moved to Queue '(.+?)'/
                )
            {
                $Ticket{Queue} = $1;
            }
        }
        elsif (
            $Row[1] eq 'StateUpdate'
            || $Row[1] eq 'Close successful'
            || $Row[1] eq 'Close unsuccessful'
            || $Row[1] eq 'Open'
            || $Row[1] eq 'Misc'
            )
        {
            if (
                $Row[0] =~ /^\%\%(.+?)\%\%(.+?)(\%\%|)$/
                || $Row[0] =~ /^Old: '(.+?)' New: '(.+?)'/
                || $Row[0] =~ /^Changed Ticket State from '(.+?)' to '(.+?)'/
                )
            {
                $Ticket{State}     = $2;
                $Ticket{StateTime} = $Row[2];

# ---
                # Znuny4OTRS-Repo
# ---
                my $IsClosedState = grep { $_ eq $2 } @ClosedStateList;
                if ($IsClosedState) {

                    # always last close time
                    $Ticket{CloseTime} = $Row[2];

                    # list of all close times
                    push @{ $Ticket{CloseTimes} }, $Row[2];
                }

# ---

            }
        }
        elsif ( $Row[1] eq 'TicketFreeTextUpdate' ) {
            if ( $Row[0] =~ /^\%\%(.+?)\%\%(.+?)\%\%(.+?)\%\%(.+?)$/ ) {
                $Ticket{ 'Ticket' . $1 } = $2;
                $Ticket{ 'Ticket' . $3 } = $4;
                $Ticket{$1}              = $2;
                $Ticket{$3}              = $4;
            }
        }
        elsif ( $Row[1] eq 'TicketDynamicFieldUpdate' ) {

            # take care about different values between 3.3 and 4
            # 3.x: %%FieldName%%test%%Value%%TestValue1
            # 4.x: %%FieldName%%test%%Value%%TestValue1%%OldValue%%OldTestValue1
            if ( $Row[0] =~ /^\%\%FieldName\%\%(.+?)\%\%Value\%\%(.*?)(?:\%\%|$)/ ) {

                my $FieldName = $1;
                my $Value = $2 || '';
                $Ticket{$FieldName} = $Value;
                $Ticket{"DynamicField_$FieldName"} = $Value;

                # Backward compatibility for TicketFreeText and TicketFreeTime
                if ( $FieldName =~ /^Ticket(Free(?:Text|Key)(?:[?:1[0-6]|[1-9]))$/ ) {

                    # Remove the leading Ticket on field name
                    my $FreeFieldName = $1;
                    $Ticket{$FreeFieldName} = $Value;
                }
            }
        }
        elsif ( $Row[1] eq 'PriorityUpdate' ) {
            if ( $Row[0] =~ /^\%\%(.+?)\%\%(.+?)\%\%(.+?)\%\%(.+?)/ ) {
                $Ticket{Priority} = $3;
            }
        }
        elsif ( $Row[1] eq 'OwnerUpdate' ) {
            if ( $Row[0] =~ /^\%\%(.+?)\%\%(.+?)/ || $Row[0] =~ /^New Owner is '(.+?)'/ ) {
                $Ticket{Owner} = $1;
            }
        }
        elsif ( $Row[1] eq 'Lock' ) {
            if ( !$Ticket{LockFirst} ) {
                $Ticket{LockFirst} = $Row[2];
            }
            $Ticket{LockLast} = $Row[2];
        }
        elsif ( $Row[1] eq 'Unlock' ) {
            if ( !$Ticket{UnlockFirst} ) {
                $Ticket{UnlockFirst} = $Row[2];
            }
            $Ticket{UnlockLast} = $Row[2];
        }

# ---
        # Znuny4OTRS-Repo
# ---
        elsif ( $Row[1] eq 'CustomerUpdate' ) {
            if ( $Row[0] =~ /^\%\%(.+?)\=(.+?)\;(.+?)\=(.+?)\;/ ) {
                $Ticket{CustomerID}   = $2;
                $Ticket{CustomerUser} = $4;
            }
        }
        elsif ( $Row[1] eq 'ServiceUpdate' ) {
            if ( $Row[0] =~ /^\%\%(.*?)\%\%(.*?)\%\%(.*?)\%\%/ ) {
                $Ticket{Service}   = $1;
                $Ticket{ServiceID} = $2;
            }
        }
        elsif ( $Row[1] eq 'SLAUpdate' ) {

            if ( $Row[0] =~ /^\%\%(.*?)\%\%(.*?)\%\%(.*?)\%\%/ ) {
                $Ticket{SLA}   = $1;
                $Ticket{SLAID} = $2;
            }
        }
        elsif ( $Row[1] eq 'ResponsibleUpdate' ) {
            if ( $Row[0] =~ /^\%\%(.+?)\%\%(.+?)/ ) {
                $Ticket{Responsible}   = $1;
                $Ticket{ResponsibleID} = $2;
            }
        }
        elsif ( $Row[1] eq 'TicketLinkAdd' ) {
            if ( $Row[0] =~ /^\%\%(.+?)\%\%(.+?)%%(.+?)/ ) {
                push @{ $Ticket{LinkedTicketIDs} }, $2;
            }
        }
        elsif ( $Row[1] eq 'TicketLinkDelete' ) {
            if ( $Row[0] =~ /^\%\%(.+?)\%\%(.+?)%%(.+?)/ ) {

                # remove unlinked TicketID
                @{ $Ticket{LinkedTicketIDs} } = grep { $_ != $2 } @{ $Ticket{LinkedTicketIDs} };
            }
        }
        elsif ( $Row[1] eq 'TimeAccounting' ) {
            if ( $Row[0] =~ /^\%\%(\d+)\%\%(\d+)/ ) {
                $Ticket{TimeAccounting}    = $1;
                $Ticket{TimeAccountingSum} = $2;
            }
        }
        elsif ( $Row[1] eq 'SetPendingTime' ) {
            if ( $Row[0] =~ /^\%\%(.+?)$/ ) {
                $Ticket{PendingTime} = $1;
            }
        }

        $Ticket{CustomerID}     ||= '';
        $Ticket{CustomerUser}   ||= '';
        $Ticket{Service}        ||= '';
        $Ticket{ServiceID}      ||= '';
        $Ticket{SLA}            ||= '';
        $Ticket{SLAID}          ||= '';
        $Ticket{Type}           ||= '';
        $Ticket{Responsible}    ||= '';
        $Ticket{TimeAccounting} ||= '';
        $Ticket{PendingTime}    ||= '';

# ---

        # get default options
        $Ticket{TypeID}     = $Row[10] || '';
        $Ticket{OwnerID}    = $Row[9]  || '';
        $Ticket{PriorityID} = $Row[8]  || '';
        $Ticket{StateID}    = $Row[7]  || '';
        $Ticket{QueueID}    = $Row[6]  || '';
    }

# ---
    # Znuny4OTRS-Repo
# ---

    # get Owner if only OwnerID exists
    if ( !$Ticket{Owner} && $Ticket{OwnerID} ) {

        $Ticket{Owner} = $UserObject->UserLookup(
            UserID => $Ticket{OwnerID},
            Silent => 1,
        );
    }

    if ( $Ticket{TypeID} ) {
        $Ticket{Type} = $TypeObject->TypeLookup( TypeID => $Ticket{TypeID} );
    }

# ---

    if ( !%Ticket ) {
        $LogObject->Log(
            Priority => 'notice',
            Message  => "No such TicketID in ticket history till "
                . "'$Param{StopYear}-$Param{StopMonth}-$Param{StopDay} $Param{StopHour}:$Param{StopMinute}:$Param{StopSecond}' ($Param{TicketID})!",
        );
        return;
    }

    # update old ticket info
    my %CurrentTicketData = $TicketObject->TicketGet(

# ---
        # Znuny4OTRS-Repo
# ---
        #         TicketID      => $Ticket{TicketID},
        # use param ticket id is fallback because if you merge old tickets to new tickets then
        # the history will be like shit and there is no correct ticket data given
        TicketID => $Ticket{TicketID} || $Param{TicketID},

# ---
        DynamicFields => 0,
    );
    for my $TicketAttribute (qw(State Priority Queue TicketNumber)) {
        if ( !$Ticket{$TicketAttribute} ) {
            $Ticket{$TicketAttribute} = $CurrentTicketData{$TicketAttribute};
        }
        if ( !$Ticket{"Create$TicketAttribute"} ) {
            $Ticket{"Create$TicketAttribute"} = $CurrentTicketData{$TicketAttribute};
        }
    }

    # get time object
    my $TimeObject = $Kernel::OM->Get('Kernel::System::Time');

    my $SystemTime = $TimeObject->SystemTime();

    # check if we should cache this ticket data
    my ( $Sec, $Min, $Hour, $Day, $Month, $Year, $WDay ) = $TimeObject->SystemTime2Date(
        SystemTime => $SystemTime,
    );

    # if the request is for the last month or older, cache it
    if ( "$Year-$Month" gt "$Param{StopYear}-$Param{StopMonth}" ) {
        $CacheObject->Set(
            Type  => $Self->{CacheType},
            TTL   => $Self->{CacheTTL},
            Key   => $CacheKey,
            Value => \%Ticket,
        );
    }

    return %Ticket;
}

1;
