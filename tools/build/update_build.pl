#! /usr/bin/perl


    #   NOTE: This program was automatically generated by the Nuweb
    #   literate programming tool.  It is not intended to be modified
    #   directly.  If you wish to modify the code or use it in another
    #   project, you should start with the master, which is kept in the
    #   file orbits.w in the public GitHub repository:
    #       https://github.com/Fourmilab/orbits.git
    #   and is documented in the file orbits.pdf in the root directory
    #   of that repository.

    #
    #   Build 0  1900-01-01 00:00


    use strict;
    use warnings;

    use POSIX qw(strftime);

    my $bfile = "build.w";              # Build file name

    #   Read current file into string

    open(FI, "<$bfile") || die("Cannot open $bfile");
    my $btext = do {
        local $/ = undef;
        <FI>;
    };
    close(FI);

    #   Update build number and date

    my $date = strftime("%F %H:%M", gmtime(time()));

    $btext =~ m/\@d\s+Build\s+number\s+\@\{(\d+)\@/s;
    my $buildno = $1;
    $buildno++;

    #   Substitute build number and date into file

    $btext =~ s/(\@d\s+Build\s+number\s+\@\{)\d+/$1$buildno/s ||
        die("Cannot substitute build number");
    $btext =~ s/(\@d Build date and time \@\{)[^\@]+/$1$date/s ||
        die("Cannot substitute date");

    #   Write out the updated file

    open(FO, ">$bfile") || die("Cannot open $bfile for writing");
    print(FO $btext);
    close(FO);

    print("Build $buildno $date\n");
