# --
# Kernel/Output/HTML/OutputFilterZnunyVerify.pm
# Copyright (C) 2012-2016 Znuny GmbH, http://znuny.com/
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
    for my $Needed (
        qw(
        LayoutObject ConfigObject LogObject MainObject ParamObject
        )
        )
    {
        $Self->{$Needed} = $Param{$Needed} || die "Got no $Needed!";
    }

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    return if $Self->{LayoutObject}->{Action} ne 'AdminPackageManager';

=for comment

example html for verify replacement


    <img src="/otrs-web/skins/Agent/default/img//otrs-verify-small.png" class="OTRSVerifyLogo" alt="Dieses Paket wurde von OTRSVerify (tm) geprüft" />
    <a href="/otrs/index.pl?Action=AdminPackageManager;Subaction=View;Name=DynamicFieldRemoteDB;Version=1.3.0">DynamicFieldRemoteDB</a>

=cut

    # replace logo in packlage list
    ${ $Param{Data} } =~ s{
        (<img [^>]* src="([^"]+ \Qotrs-verify-small.png\E)" [^>]* class="OTRSVerifyLogo" [^>]* >) \s* <a [^>]* >([^<]+)<\/a> \s* <\/td> \s*
        <td> .*? <\/td> \s*
        <td> .*? <\/td> \s*
        <td><a [^>]* >([^>]+)<\/a><\/td>
    }
    {

        my $HTML = $&;
        my $ImageHTML = $1;
        my $ImageSource = $2;
        my $PackageName = $3;
        my $Vendor = $4;

        if ( $Vendor =~ m{znuny}xmsi ) {
            my $HTMLNew = $HTML;

            $HTMLNew =~ s{\Qotrs-verify-small.png\E}{znuny-verify-small.png}xmsi;

            $HTMLNew;
        }
        elsif ( $Vendor =~ m{otrs}xmsi ) {
            $HTML;
        } else {
            my $HTMLNew = $HTML;

            $HTMLNew =~ s{\Q$ImageHTML\E}{}xmsi;

            $HTMLNew;
        }

    }xmsgei;

    # replace logo in package view
    ${ $Param{Data} } =~ s{
        <img [^>]* class="OTRSVerifyLogoBig" [^>]* >
    }
    {}xmsgi;

    return 1;

}

1;
