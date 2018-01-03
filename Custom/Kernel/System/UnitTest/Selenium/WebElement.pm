# --
# Copyright (C) 2001-2018 OTRS AG, http://otrs.com/
# Copyright (C) 2012-2018 Znuny GmbH, http://znuny.com/
# --
# $origin: otrs - 04139bf7d2feaf7631ce64edada6d19fea6a3328 - Kernel/System/UnitTest/Selenium/WebElement.pm
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::UnitTest::Selenium::WebElement;

use strict;
use warnings;

use parent qw(Selenium::Remote::WebElement);

=head1 NAME

Kernel::System::UnitTest::Selenium::WebElement - Utility functions for Selenium WebElements


=head2 VerifiedSubmit()

Submit a form element, and wait for the page to be fully loaded (works only in OTRS)

    $SeleniumObject->VerifiedSubmit();

=cut

sub VerifiedSubmit {
    my ( $Self, $Params ) = @_;

    $Self->submit();

    $Self->driver()->WaitFor(
        JavaScript =>
            'return typeof(Core) == "object" && typeof(Core.App) == "object" && Core.App.PageLoadComplete'
    ) || die "OTRS API verification failed after element submit.";

    return;
}

=head2 VerifiedClick()

click an element that causes a page get/reload/submit and wait for the page to be fully loaded
(works only in OTRS).

    $SeleniumObject->VerifiedClick(
        $Button             # optional, see Selenium docs
    );

=cut

sub VerifiedClick {    ## no critic
    my $Self = shift;

    $Self->SUPER::click(@_);

    $Self->driver()->WaitFor(
        JavaScript =>
            'return typeof(Core) == "object" && typeof(Core.App) == "object" && Core.App.PageLoadComplete'
    ) || die "OTRS API verification failed after element click.";

    return;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
