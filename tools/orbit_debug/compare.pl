
    #   Compare Solar System Live and Fourmilab Solar System
    #   to debug single precision and other computational problems.
    #
    #   Assumes you have files BODY_ssl.txt and BODY_lsl.txt for
    #   your named BODY.  Running:
    #
    #       perl compare.pl BODY
    #
    #   compares the two and produces a report showing the percent
    #   discrepancy in each of the computed values for the positions
    #   computed by the ephemeris over the orbit.

    use strict;
    use warnings;

    my $body = $ARGV[0];

    open(SSL, "<${body}_ssl.txt") || die("Cannot open ${body}_ssl.txt");
    open(LSL, "<${body}_lsl.txt") || die("Cannot open ${body}_lsl.txt");

    my ($ssl, $lsl);

    print <<"EOD";
         JD                L           B          R           X        Y       Z
EOD
    while ($ssl = <SSL>) {
        $lsl = <LSL> || die("Mismatched number of lines.");
        #              JD      L       B       R       X       Y       Z
        $ssl =~ m/\s*(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/;
        my ($sJD, $sL, $sB, $sR, $sX, $sY, $sZ) = ($1, $2, $3, $4, $5, $6, $7);
        #                   JD      JDF     L       B       R       X       Y       Z
        $lsl =~ m/^.*?:\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+<(\S+?),\s+(\S+?),\s+(\S+?)>/;
        my ($lJD, $lJDF, $lL, $lB, $lR, $lX, $lY, $lZ) = ($1, $2, $3, $4, $5, $6, $7, $8);

        $lJD += $lJDF;

        printf("SSL %14.6f   %10.4f  %10.4f  %8.4f    %8.5f %8.5f %8.5f\n",
               $sJD, $sL, $sB, $sR, $sX, $sY, $sZ);
        printf("LSL %14.6f   %10.4f  %10.4f  %8.4f    %8.5f %8.5f %8.5f\n",
               $lJD, $lL, $lB, $lR, $lX, $lY, $lZ);
        printf("    %14s   %10s  %10s  %8s    %8s %8s %8s\n\n",
               pd($sJD, $lJD), pd($sL, $lL), pd($sB, $lB), pd($sR, $lR),
               pd($sX, $lX), pd($sY, $lY), pd($sZ, $lZ));
    }

    close(LSL);
    close(SSL);

    sub pd {
        my ($sv, $lv) = @_;
        my $delta = $lv - $sv;
        my $percent = ($delta / $sv) * 100.0;

        return sprintf("%+.2f", $percent);
    }
