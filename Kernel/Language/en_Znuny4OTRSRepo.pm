# --
# Copyright (C) 2012-2022 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::en_Znuny4OTRSRepo;

use strict;
use warnings;

use utf8;

sub Data {
    my $Self = shift;

    # AdminZnuny4OTRSFiles
    $Self->{Translation}->{'FullPath'}             = 'Full path';
    $Self->{Translation}->{'StateMessage'}         = 'State message';
    $Self->{Translation}->{'OriginalMD5'}          = 'Original MD5';

    return 1;
}

1;
