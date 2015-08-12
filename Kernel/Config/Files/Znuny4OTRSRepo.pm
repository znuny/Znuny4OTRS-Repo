# --
# Kernel/Config/Files/Znuny4OTRSRepo.pm
# Copyright (C) 2001-2015 OTRS AG, http://otrs.com/
# Copyright (C) 2012-2015 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::OTRS::Perl::PerlCritic)

use strict;
use warnings;
use Kernel::System::Package;

# disable redefine warnings in this scope
{
no warnings 'redefine';

# backup original PackageVerify()
my $PackageVerifyOld = \&Kernel::System::Package::PackageVerify;

# redefine PackageVerify() of Kernel::System::Package
*Kernel::System::Package::PackageVerify = sub {
    my ( $Self, %Param ) = @_;

    my $PackageVerification = $Self->{ConfigObject}->Get('PackageVerification');
    return 'verified' if !$PackageVerification;

    # execute original function
    return &{$PackageVerifyOld}( $Self, %Param );
};

# backup original PackageVerifyAll()
my $PackageVerifyAllOld = \&Kernel::System::Package::PackageVerifyAll;

# redefine PackageVerifyAll() of Kernel::System::Package
*Kernel::System::Package::PackageVerifyAll = sub {
    my ( $Self, %Param ) = @_;

    my $PackageVerification = $Self->{ConfigObject}->Get('PackageVerification');
    if ( !$PackageVerification ) {
        # get installed package list
        my @PackageList = $Self->RepositoryList(
            Result => 'Short',
        );

        # and take the short way ;)
        my %Result;
        for my $Package (@PackageList) {
            $Result{ $Package->{Name} } = 'verified';
        }

        return %Result;
    }

    # execute original function
    return &{$PackageVerifyAllOld}( $Self, %Param );
};



sub Kernel::System::Package::_FileSystemCheck {
    my ( $Self, %Param ) = @_;

    # set new pav url
    my $Type = $Self->{ConfigObject}->Get('Znuny4OTRSRepoType') || 'https';
    $Self->{PackageVerifyURL} = $Type . '://portal.znuny.com/api/addon_pav/';

    my $Home = $Param{Home} || $Self->{Home};

    # check Home
    if ( !-e $Home ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => "No such home directory: $Home!",
        );
        return;
    }

    # create test files in following directories
    for (qw(/bin/ /Kernel/ /Kernel/System/ /Kernel/Output/ /Kernel/Output/HTML/ /Kernel/Modules/)) {
        my $Location = "$Home/$_/check_permissons.$$";
        my $Content  = 'test';

        # create test file
        my $Write = $Self->{MainObject}->FileWrite(
            Location => $Location,
            Content  => \$Content,
        );

        # return false if not created
        return if !$Write;

        # delete test file
        $Self->{MainObject}->FileDelete( Location => $Location );
    }

    return 1;
}

}

1;
