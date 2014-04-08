
# Copyright (C) 2013-2014 Znuny GmbH, http://znuny.com/

use strict;
use warnings;
use Kernel::System::Package;

use vars qw(@ISA);

# disable redefine warnings in this scope
{
no warnings 'redefine';

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
