# --
# Kernel/Output/HTML/OutputFilterZnunyVerify.pm - replaces the OTRS verify logo with the Znuny version
# Copyright (C) 2012-2015 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::OutputFilterZnunyVerify;

use strict;
use warnings;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # check needed objects
    for my $Needed (qw(LayoutObject ConfigObject LogObject MainObject ParamObject)) {
        $Self->{$Needed} = $Param{$Needed} || die "Got no $Needed!";
    }

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    return if $Self->{LayoutObject}->{Action} ne 'AdminPackageManager';

    # replace logo in packlage list
    ${ $Param{Data} } =~ s{
        (<img\ssrc=")(.+?)("\sclass="OTRSVerifyLogo"\salt=")(.+?)("\s/>.+?<a\shref=.+?blank.+?>)(.+?)(</a>)
    }
    {
        my $Start1 = $1;
        my $Url    = $2;
        my $Start2 = $3;
        my $Title  = $4;
        my $Start3 = $5;
        my $Vendor = $6;
        my $Start4 = $7;
        if ( $Vendor !~ /otrs/i ) {
            $Url    =~ s/otrs-verify-small.png/znuny-verify-small.png/;
        }
        "$Start1$Url$Start2$Title$Start3$Vendor$Start4"
    }xmsgei;

    # replace logo in package view
    ${ $Param{Data} } =~ s{
        (<img\ssrc=".+?otrs-verify.png"\sclass="OTRSVerifyLogoBig")
    }
    {
        my $Part = $1;
        $Part =~ s/otrs-verify.png/znuny-verify.png/;
        $Part
    }xmsgei;

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
