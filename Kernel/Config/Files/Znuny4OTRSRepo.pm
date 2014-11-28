# --
# Kernel/Znuny4OTRSRepo.pm - overloads the file system check function to use the Znuny service for package verification
# Copyright (C) 2014 Znuny GmbH, http://znuny.com/
# --

use strict;
use warnings;

use Kernel::System::Package;

# disable redefine warnings in this scope
{
no warnings 'redefine';

sub Kernel::System::Package::_FileSystemCheck {
    my ( $Self, %Param ) = @_;

# ---
# Znuny4OTRS-Repo
# ---
    # set new pav url
    my $Type                  = $Kernel::OM->Get('Kernel::Config')->Get('Znuny4OTRSRepoType') || 'https';
    $Self->{PackageVerifyURL} = $Type . '://portal.znuny.com/api/addon_pav/';
# ---
    my $Home = $Param{Home} || $Self->{Home};

    # check Home
    if ( !-e $Home ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "No such home directory: $Home!",
        );
        return;
    }

    # create test files in following directories
    for my $Filepath (
        qw(/bin/ /Kernel/ /Kernel/System/ /Kernel/Output/ /Kernel/Output/HTML/ /Kernel/Modules/)
        )
    {
        my $Location = "$Home/$Filepath/check_permissons.$$";
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
