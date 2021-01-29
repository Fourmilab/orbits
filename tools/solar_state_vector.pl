
    #   Create the initial solar system state vector from the
    #   JPL digital ephemeris state vector for 2440400.50
    #   (1969-06-28), as extracted into the file aconst.h
    #   from the DE118i-2 release used in my Quarter Million Year
    #   Canon of Solar System Transits:
    #
    #       https://www.fourmilab.ch/documents/canon_transits/

    use strict;
    use warnings;

    use Math::Trig;
    use Math::Quaternion;
#    use Data::Dumper;

    my @bodies = (
        "Mass Mercury  <pos> <vel> 1.666667e-7 <0.75, 0.75, 0.75> 2439.4",
        "Mass Venus  <pos> <vel> 2.44786e-6 <1, 1, 1> 6051.8",
        "Mass Earth  <pos> <vel> 3.04044e-6 <0.3, 0.3, 1> 6371.0084",
        "Mass Mars  <pos> <vel> 3.22716e-7, <1, 0.3, 0.3> 3389.50",
        "Mass Jupiter <pos> <vel> 0.000954782 <0.75, 0.72, 0.72> 69911",
        "Mass Saturn  <pos> <vel> 0.00285837 <0.7, 0.7, 0.3> 58232",
        "Mass Uranus  <pos> <vel> 4.38596e-5 <0.4, 0.8, 0.7> 25362",
        "Mass Neptune  <pos> <vel> 5.18135e-5 <0.4, 0.7, 0.8> 24622",
        "Mass Pluto  <pos> <vel> 6.5526779e-9 <0.8, 0.6, 0.6> 1188.3",
        "Mass Moon  <pos> <vel> 3.6944e-8 <0.5, 0.5, 0.5> 1737.5",
        "Mass Sun <pos> <vel> 1 <1, 1, 0, 1, 0.1> 24000"
    );

    my $sci = qr/[\d\.eE\+\-]+/;   # Number in scientific notation

    my $epoch;
    my (@pos, @vel);

    open(AC, "<aconst.h") || die("Cannot open aconst.h");

    my $n = 0;          # Line number
    my $p = 0;          # Body number
    my $e = 0;          # Element number within body
    my @elem;           # Element assembly buffer
    while (my $l = <AC>) {
        chomp($l);

        if ($l !~ m/^\s*;/) {
            $n++;

            #   Process epoch declaration
            if ($n == 1) {
                $l =~ m/($sci)/ || die("$n: cannot parse ($l)");
                $epoch = $1 + 0;
            }

            #   Ignore lunar librations

            #   Process state vector element value
            if ($n >= 8) {
                $l =~ m/($sci)/ || die("$n: cannot parse ($l)");
                push(@elem, $1 + 0);
                $e++;
                if ($e >= 6) {
                    push(@pos, [ $elem[1], $elem[3], $elem[5] ]);
                    push(@vel, [ $elem[0], $elem[2], $elem[4] ]);
                    @elem = ( );
                    $e = 0;
                    $p++;
                    if ($p >= 11) {
                        last;
                    }
                }
            }
        }
    }
    close(AC);

    #   We have now read the position and velocity records for
    #   all bodies and stored them in the @pos and @vel arrays.
    #   Now we're ready to generate the Fourmilab Gravitation
    #   commands to create these masses with properties as given
    #   in the @bodies table above and the state we've read,
    #   transformed into our heliocentric co-ordinate system.

    #   The DE118 state vector expresses position and velocity
    #   co-ordinates in a system where the Z axis points to the
    #   Earth's north celestial pole.  We wish our co-ordinates
    #   to be in a heliocentric co-ordinate system aligned with
    #   the Z axis normal to the ecliptic, so we pre-compute the
    #   quaternion we'll use in gh() below to transform these
    #   vectors into our preferred co-ordinate system.
    my $rotz = Math::Quaternion->new({
        axis => [ 1, 0, 0 ],
        angle => deg2rad(-obliqeq($epoch)) });

    #   Velocities in the DE118 state vector are given in
    #   units of AU/day, while our integrator requires
    #   velocities in AU/year.  This defines the conversion
    #   factor for velocities.
    my $velScale = 365.2422;

    print("\n#   Solar System State Vector\n\n");
    print("Epoch $epoch\n\n");
    print("#   Obliquity of the ecliptic: " . obliqeq($epoch) . "\n\n");

    my $ff = "%.8e";                # Floating point format phrase

    for (my $i = 0; $i < scalar(@bodies); $i++) {
        my $s = $bodies[$i];

        $s =~ m/Mass\s+(\S+)\s+<[^>]+>\s+<[^>]+>\s+(\S+)\s+(<[^>]+>)\s+(\S+)\s*$/ ||
            die("Cannot parse \$bodies[$i]: $s");

        my ($bname, $mass, $colour, $radius) = ($1, $2, $3, $4);
        my $posi = fv(gh($pos[$i][0], $pos[$i][1], $pos[$i][2]));
        my $velo = fv(gh($vel[$i][0] * $velScale, $vel[$i][1] * $velScale, $vel[$i][2] * $velScale));

        print("Mass $bname $posi $velo $mass $colour $radius\n");
    }

    #   Format a vector containing numbers in scientific notation

    sub fv {
        my ($x, $y, $z) = @_;

        my $vs = sprintf("<$ff, $ff, $ff>", $x, $y, $z);
        $vs =~ s/e\+00//ig;
        $vs =~ s/(e[\+\-])0/$1/ig;
        $vs =~ s/(e)\+/$1/ig;
        return $vs;
    }

    #   Convert geocentric to heliocentric co-ordinates

    sub gh {
        my ($x, $y, $z) = @_;

        my @ha = $rotz->rotate_vector(( $x, $y, $z ));
        return @ha; #( $ha[0], $ha[1], $ha[2] );
    }

    #   OBLIQEQ  --  Calculate the obliquity of the ecliptic for a given
    #                Julian date.  This uses Laskar's tenth-degree
    #                polynomial fit (J. Laskar, Astronomy and
    #                Astrophysics, Vol. 157, page 68 [1986]) which is
    #                accurate to within 0.01 arc second between AD 1000
    #                and AD 3000, and within a few seconds of arc for
    #                +/-10000 years around AD 2000.  If we're outside the
    #                range in which this fit is valid (deep time) we
    #                simply return the J2000 value of the obliquity, which
    #                happens to be almost precisely the mean.  */


    sub obliqeq {
        my ($jd) = @_;

        my ($eps, $u, $v, $i);

        my $J2000 = 2451545.0;          # Julian day of J2000 epoch
        my $JulianCentury = 36525.0;    # Days in Julian century

        my @oterms = (
            -4680.93,
               -1.55,
             1999.25,
              -51.38,
             -249.67,
              -39.05,
                7.12,
               27.87,
                5.79,
                2.45
        );

        $v = $u = ($jd - $J2000) / ($JulianCentury * 100);

        $eps = 23 + (26 / 60.0) + (21.448 / 3600.0);

        if (abs($u) < 1.0) {
            for ($i = 0; $i < 10; $i++) {
                $eps += ($oterms[$i] / 3600.0) * $v;
                $v *= $u;
            }
        }
        return $eps;
    }

