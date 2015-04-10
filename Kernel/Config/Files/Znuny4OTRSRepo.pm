# --
# Kernel/Config/Files/Znuny4OTRSRepo.pm - overloads the file system check function to use the Znuny service for package verification
# Copyright (C) 2001-2015 OTRS AG, http://otrs.com/
# Copyright (C) 2012-2015 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;

use Kernel::System::CloudService;

our $ObjectManagerDisabled = 1;

# disable redefine warnings in this scope
{
no warnings 'redefine';

sub Kernel::System::CloudService::new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # set system registration data
    %{ $Self->{RegistrationData} } =
        $Kernel::OM->Get('Kernel::System::SystemData')->SystemDataGroupGet(
        Group  => 'Registration',
        UserID => 1,
        );

# ---
# Znuny4OTRS-Repo
# ---
#     # set URL for calling cloud services
#     $Self->{CloudServiceURL} = 'https://cloud.otrs.com/otrs/public.pl';
    # set new cloud service url
    my $Schema               = $Kernel::OM->Get('Kernel::Config')->Get('Znuny4OTRSRepoType') || 'https';
    $Self->{CloudServiceURL} = $Schema .'://'. $Kernel::OM->Get('Kernel::Config')->Get('Znuny4OTRSCloudServiceProxyURL');
# ---

    return $Self;
}

}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
