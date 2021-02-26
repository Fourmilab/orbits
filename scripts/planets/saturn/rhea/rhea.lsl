
    /*

                    Fourmilab Solar System

                        Rhea Definition

    */

    list planet = [
        "Rhea",             // 0  Name of body
        "Saturn",           // 1  Primary

        //  Orbital elements
        2451545,            // 2  Epoch (J2000), integer part
        527068,             // 3  a    Semi-major axis, km
        0.0002,             // 4  e    Eccentricity
        0.333,              // 5  i    Inclination, degrees
        351.042,            // 6  Ω    Longitude of the ascending node, degrees
        241.619,            // 7  ω    Argument of periapsis, degrees
        179.781,            // 8  M    Mean anomaly, degrees

        //  Orbital element precession periods
        0,                  // 9  a
        0,                  // 10 e
        0,                  // 11 i
        35.832,             // 12 Ω    Precession period/years
        17.939,             // 13 ω    Precession period/years
        0,                  // 14 M

        //  Physical properties
        763.8,              // 15 Equatorial radius, km
        763.8,              // 16 Polar radius, km
        2.306518e21,        // 17 Mass, kg
        1.236,              // 18 Mean density, g/cm³
        0.264,              // 19 Surface gravity, m/s²
        0.635,              // 20 Escape velocity, km/s
        4.518212,           // 21 Sidereal rotation period, days
        <40.589, 83.537, 0>, // 22 North pole, RA, Dec  (USED SATURN)
        0.0,                // 23 Axial inclination, degrees
        0.949,              // 24 Albedo

        //  Extras
        0.0,                // 25 Fractional part of epoch
        3.7931187e16,       /* 26 Standard gravitational parameter (G M)
                                  of primary, m^3/sec^2  */
        <0.902, 0.788, 0.3176>,     // 27 Colour of trail tracing orbit
        <40.328, 83.559, 0.036>     // 28 Laplace plane of orbit: RA, Dec, Tilt
    ];

    /*  This is a list of orbital elements in the form we
        use throughout the program for evaluating positions
        in orbits.  It is filled in, with values synthesised
        as required, from the parameters in the planet list
        above.  None of the initial values in this list are
        significant.  */

    list s_elem = [
        "Name",                 // 0    Name
        0, 0.0,                 // 1,2  epoch [ jd, jdf ]
        0.0,                    // 3    a (semi-major axis)
        0.0,                    // 4    e (eccentricity)
        0.0,                    // 5    i (inclination)
        0.0,                    // 6    ῶ (argument of periapse)
        0.0,                    // 7    Ω (longitude of ascending node)
        0.0,                    // 8    M (mean anomaly)
        0.0,                    // 9    H (magnitude)
        0.0,                    // 10   G (magnitude slope)
        0, 0.0,                 // 11,12 Tp (time of perhelion)
        0.0,                    // 13   q (periapse distance)
        0.0,                    // 14   n (mean motion)
        0.0,                    // 15   P (orbital period)
        0.0                     // 16   Q (apoapse distance)
    ];

    float GaussK;               // Gaussian gravitational constant for planet

    string ourName;                     // Our object name
    key owner;                          // UUID of owner
    key deployer;                       // ID of deployer who hatched us
    integer initState = 0;              // Initialisation state

    //  Properties of this mass
    integer s_trace = FALSE;            // Trace operations
    integer m_index;                    // Our mass index
    string m_name;                      // Name
    float m_scalePlanet;                // Planet scale
    integer m_jd;                       // Epoch Julian day
    float m_jdf;                        // Epoch Julian day fraction

    //  Settings communicated by deployer
    float s_kaboom = 50;                // Self destruct if this far (AU) from deployer
    float s_auscale = 0.3;              // Astronomical unit scale
    integer s_trails = FALSE;           // Plot orbital trails ?
    float s_pwidth = 0.01;              // Paths/trails width
    float s_mindist = 0.1;              // Minimum distance to move
    integer s_labels = FALSE;           // Show floating text legend ?

    integer massChannel = -982449822;   // Channel for communicating with planets
    string ypres = "B?+:$$";            // It's pronounced "Wipers"

    vector deployerPos;                 // Deployer position
    rotation npRot;                     // Rotation to orient north pole

    float startTime;                    // Time we were placed

    key whoDat;                         // User with whom we're communicating
    integer paths;                      // Draw particle trail behind masses ?
    vector lastTrailP = ZERO_VECTOR;    // Last trail path point

    //  Link messages

    //  Planetary satellite messages

    integer LM_PS_DEPMSG = 811;         // Message from deployer
    integer LM_PS_UPDATE = 812;         // Update position and rotation

    /*  siuf  --  Base64 encoded integer to float
                  Designed and implemented by Strife Onizuka:
                    http://wiki.secondlife.com/wiki/User:Strife_Onizuka/Float_Functions  */

    vector sv(string b) {
        return(< siuf(llGetSubString(b, 0, 5)),
                 siuf(llGetSubString(b, 6, 11)),
                 siuf(llGetSubString(b, 12, -1)) >);
    }

    float siuf(string b) {
        integer a = llBase64ToInteger(b);
        if (0x7F800000 & ~a) {
            return llPow(2, (a | !a) + 0xffffff6a) *
                      (((!!(a = (0xff & (a >> 23)))) * 0x800000) |
                       (a & 0x7fffff)) * (1 | (a >> 31));
        }
        return (!(a & 0x7FFFFF)) * (float) "inf" * ((a >> 31) | 1);
    }

    //  ef  --  Edit floats in string to parsimonious representation

    string eff(float f) {
        return ef((string) f);
    }

    string efv(vector v) {
        return ef((string) v);
    }

    string ef(string s) {
        integer p = llStringLength(s) - 1;

        while (p >= 0) {
            //  Ignore non-digits after numbers
            while ((p >= 0) &&
                   (llSubStringIndex("0123456789", llGetSubString(s, p, p)) < 0)) {
                p--;
            }
            //  Verify we have a sequence of digits and one decimal point
            integer o = p - 1;
            integer digits = 1;
            integer decimals = 0;
            while ((o >= 0) &&
                   (llSubStringIndex("0123456789.", llGetSubString(s, o, o)) >= 0)) {
                o--;
                if (llGetSubString(s, o, o) == ".") {
                    decimals++;
                } else {
                    digits++;
                }
            }
            if ((digits > 1) && (decimals == 1)) {
                //  Elide trailing zeroes
                while ((p >= 0) && (llGetSubString(s, p, p) == "0")) {
                    s = llDeleteSubString(s, p, p);
                    p--;
                }
                //  If we've deleted all the way to the decimal point, remove it
                if ((p >= 0) && (llGetSubString(s, p, p) == ".")) {
                    s = llDeleteSubString(s, p, p);
                    p--;
                }
                //  Done with this number.  Skip to next non digit or decimal
                while ((p >= 0) &&
                       (llSubStringIndex("0123456789.", llGetSubString(s, p, p)) >= 0)) {
                    p--;
                }
            } else {
                //  This is not a floating point number
                p = o;
            }
        }
        return s;
    }

    /*  flPlotLine  --  Plot a line using a cylinder prim.  We
                        accept fully general arguments, which
                        allows swapping out the function for one
                        which communicates with the rezzed object
                        over llRegionSayTo() instead of via the
                        llRezObject() start parameter with no change
                        to client code.  */

    //  List of selectable diameters for lines
    list flPlotLineDiam = [ 0.01, 0.05, 0.1, 0.5 ];

    flPlotLine(vector fromPoint, vector toPoint,
               vector colour, float diameter) {
//tawk("flPlotLine " + (string) fromPoint + " -> " + (string) toPoint);
        float length = llVecDist(fromPoint, toPoint);
        vector midPoint = (fromPoint + toPoint) / 2;

        //  Encode length as integer from 0 to 1023 (10 bits)
        integer ilength = llRound((length * 100) - 0.01);
        if (ilength > 1023) {
            ilength = 1023;
        }

        //  Encode colour as RGB with 16 levels of colour (12 bits)
        integer icolour = (llRound(colour.x * 15) << 8) |
                          (llRound(colour.y * 15) << 4) |
                           llRound(colour.z * 15);

        /*  Find the closest match to the requested diameter
            among the options available in flPlotLineDiam  */

        integer bestdia;
        float bestdiamatch = 1e20;
        integer diax;

        for (diax = 0; diax < 4; diax++) {
            float d = llFabs(diameter - llList2Float(flPlotLineDiam, diax));
            if (d < bestdiamatch) {
                bestdiamatch = d;
                bestdia = diax;
            }
        }
        llRezObject("flPlotLine", midPoint, ZERO_VECTOR,
            llRotBetween(<0, 0, 1>, llVecNorm(toPoint - midPoint)),
            ((diax << 22) | (icolour << 10) | ilength)
        );
    }

    float JulianCentury = 36525.0;      // Days in Julian century

    //  sgn  --  Return sign of argument

    integer sgn(float v) {
        if (v == 0) {
            return 0;
        } else if (v > 0) {
            return 1;
        }
        return -1;
    }

    /*  gKepler  --  High-precision solution to the equation
                     of Kepler for eccentricities between
                     0 and extreme hyperbolic orbits.  Arguments
                     are the eccentricity, time since periapse,
                     and distance at periapse.  A list is returned
                     containing the true anomaly v (radians) and
                     the radius vector to the central body r (AU).  */

    list gKepler(float e, float t, float q) {
//tawk("gKepler e " + (string) e + "  t " + (string) t + "  q " + (string) q);
        float f;
        float x;
        float d;
        float m1;
        integer i;

        float v;
        float r;

        /*  Solution by binary search by Roger W. Sinnott, Sky and Telescope,
            Vol. 70, page 159 (August 1985).  This is presented as the
            "Third Method" in chapter 30 of Meeus, "Astronomical Algorithms",
            2nd ed.  We use this for all eccentricities less than 0.98.  */

        float m;
        float a1;
        float ev;

        a1 = q / (1 - e);
        m = GaussK * t * llPow(a1, -1.5);

        f = sgn(m);
        m = llFabs(m) / (2 * PI);
        m = (m - (llFloor(m))) * 2 * PI * f;
        if (m < 0) {
            m += 2 * PI;
        }
        f = 1;
        if (m > PI) {
            f = -1;
        }
        if (m > PI) {
            m = (2 * PI) - m;
        }
        x = PI / 2;
        d = PI / 4;
        for (i = 0; i < 53; i++) {
            m1 = x - e * llSin(x);
            x = x + sgn(m - m1) * d;
            d /= 2;
        }
        x *= f;
        ev = llSqrt((1 + e) / (1 - e));
        r = a1 * (1 - e * llCos(x));
        x = 2 * llAtan2(ev * llSin(x / 2), llCos(x / 2));

        if (x < 0) {
            x += TWO_PI;
        }
        v = x;
        return [ v, r ];
    }

    /*  obliqeq  --  Calculate the obliquity of the ecliptic for
                     a given Julian date.  This uses Laskar's
                     tenth-degree polynomial fit (J. Laskar,
                     Astronomy and Astrophysics, Vol. 157, page
                     68 [1986]) which is accurate to within 0.01
                     arc second between AD 1000 and AD 3000, and
                     within a few seconds of arc for +/-10000
                     years around AD 2000.  If we're outside the
                     range in which this fit is valid (deep
                     time) we simply return the J2000 value of
                     the obliquity, which happens to be almost
                     precisely the mean.  */

    float obliqeq(integer jd, float jdf) {
        /*  These terms were originally specified in arc
            seconds.  In the interest of efficiency, we convert
            them to degrees by dividing by 3600 and round to
            nine significant digits, which is the maximum
            precision of the single-precision floats used by
            LSL.  */
        list oterms = [
            -1.30025833,
            -0.000430555556,
             0.555347222,
            -0.0142722222,
            -0.0693527778,
            -0.0108472222,
             0.00197777778,
             0.00774166667,
             0.00160833333,
             0.000680555556
        ];

        //  Again, we evaluate a number specified as 23d26'21".448 as degrees
        float eps = 23.4392911;
        float u;
        float v;
        integer i;

        v = u = ((jd - 2451545) / (JulianCentury * 100)) + (jdf / (JulianCentury * 100));

        if (llFabs(u) < 1.0) {
            for (i = 0; i < 10; i++) {
                eps += llList2Float(oterms, i) * v;
                v *= u;
            }
        }
        return eps;
    }

    /*  computeOrbit  --  Compute rectangular co-ordinates
                          of object from orbital elements.  */

    vector computeOrbit(list elements, list jdl) {
//        float e = obliqeq(llList2Integer(jdl, 0), llList2Float(jdl, 1)) * DEG_TO_RAD;
float e = 0;
        float w = llList2Float(elements, 6) * DEG_TO_RAD;
        float n = llList2Float(elements, 7) * DEG_TO_RAD;
        float i = llList2Float(elements, 5) * DEG_TO_RAD;
//tawk("ComputeOrbit  e " + (string) (RAD_TO_DEG * e) + "  w " + (string) (RAD_TO_DEG * w) + "  n " + (string) (RAD_TO_DEG * n) + "  i " + (string) (RAD_TO_DEG * i));

        float w1 = llSin(w);
        float w2 = llCos(w);
        float n1 = llSin(n);
        float n2 = llCos(n);
        float i1 = llSin(i);
        float i2 = llCos(i);
        float e1 = llSin(e);
        float e2 = llCos(e);

        float p7 = (w2 * n2) - (w1 * n1 * i2);
        float p8 = (((w2 * n1) + (w1 * n2 * i2)) * e2) - (w1 * i1 * e1);
        float p9 = (((w2 * n1) + (w1 * n2 * i2)) * e1) + (w1 * i1 * e2);
        float q7 = (-w1 * n2) - (w2 * n1 * i2);
        float q8 = (((-w1 * n1) + (w2 * n2 * i2)) * e2) - (w2 * i1 * e1);
        float q9 = (((-w1 * n1) + (w2 * n2 * i2)) * e1) + (w2 * i1 * e2);

        integer dti = llList2Integer(jdl, 0) - llList2Integer(elements, 11);
        float dtf = dti + (llList2Float(jdl, 1) - llList2Float(elements, 12));
        list k = gKepler(llList2Float(elements, 4),
                         dtf,
                         llList2Float(elements, 13));
        if (k != [ ]) {
            float v = llList2Float(k, 0);
            float r = llList2Float(k, 1);
            float x1 = r * llCos(v);
            float y1 = r * llSin(v);

            return <  (p7 * x1) + (q7 * y1),
                      (p8 * x1) + (q8 * y1),
                      (p9 * x1) + (q9 * y1) >;
        }
        //  Kepler's equation solver failed
tawk(llGetScriptName() + ": Kepler solver failed.");
        return ZERO_VECTOR;
    }

    //  posSat  --  Compute position of satellite

    vector posSat(integer jd, float jdf) {
        vector pos = computeOrbit(s_elem, [ jd, jdf ]);
        return pos;
    }

    /*  rotPole  --  Rotate the north pole of the Globe to its
                     correct orientation in space.  The planet
                     list contains an item (22) which specifies
                     the orientation of the body's north pole as
                     a vector in which the .x component is the
                     right ascension and the .y component the
                     declination of the north pole's position on
                     the celestial sphere, specified in equatorial
                     co-ordinates, in degrees, at the epoch given
                     by list item 0.  (The .z component of this
                     vector is ignored.)

                     We require the orientation of the north pole
                     in heliocentric ecliptical space, which we
                     obtain by first rotating the body about the
                     global Y axis to tilt the pole to the specified
                     declination, then rotating around the global
                     Z axis to the azimuth specified by the right
                     ascension.  At this point, we have the globe
                     properly oriented in equatorial space.

                     But, we're not done.  We require the orientation
                     in ecliptic co-ordinates, so we must now tilt
                     the globe along the global X axis, which is the
                     plane of intersection between the ecliptic and
                     the equatorial planes, aligned with the vector
                     toward the March equinox.  Since the obliquity
                     of the ecliptic varies with time, we require
                     the Julian day and fraction of the epoch in order
                     to perform this transformation.

                     We do not actually rotate the globe here, but
                     rather return the rotation computed to achieve
                     the desired orientation.  */

    rotation rotPole(integer jd, float jdf) {
        float obleq = obliqeq(jd, jdf) * DEG_TO_RAD;    // Obliquity of the ecliptic
        vector npoled = llList2Vector(planet, 22);      // North pole, degrees
        vector npoler = npoled * DEG_TO_RAD;            // North pole, radians
        //  Tilt to declination
        rotation rpole = llEuler2Rot(<0, PI - npoler.y, 0>);

        //  Rotate to right ascension
        rpole = rpole * llEuler2Rot(<0, 0, npoler.x>);

        //  Tilt from equatorial to ecliptic plane
        rpole = rpole * llEuler2Rot(<-obleq, 0, 0>);

        /*  Compute axis around which the body rotates.
            This axis is defined by the vector from its
            centre to the north pole.  */
        vector raxis = < -1, 0, 0 > * rpole;
        /*  The local Z axis (yes, I know, it doesn't make any
            sense, but bear with me) defines the prime meridian.
            This must be determined after applying to rotation
            to align the north pole in space.  */
        vector lfwd = llRot2Up(rpole);
        /*  The cross product of the normalised vector from the
            centre of the body to zero latitude in ecliptic
            co-ordinates (its positive X axis) and the rotation
            axis gives us the normal to the plane defined by
            the rotation axis and zero latitude.  */
        vector xnorm = raxis % < -1, 0, 0 >;
        /*  Now, our task is to rotate the globe around its
            axis of rotation (raxis) so as to make the prime
            meridian vector (lfwd) fall within the plane to
            which xnorm is the normal.  The dot product of
            these two vectors is the cosine of the angle
            between them.  */
        float tang = PI_BY_TWO - llAcos(lfwd * xnorm); // Angle from prime meridian to axis-ecliptic meridian plane
        /*  The angle, tang, computed above, does not take into
            account whether the prime meridian vector, projected
            upon the line containing the centre of the planet
            and ecliptic origin, is parallel or anti-parallel to the
            vector from the centre of the planet to the
            origin.  We compute the angle between these two
            vectors from their dot product, and then test
            their direction using the magnitude of this angle.  */
        float fpxa = llAcos(lfwd * < -1, 0, 0 >);
        if (fpxa < PI_BY_TWO) {
            tang = -(PI + tang);
        }
//tawk("raxis " + (string) raxis + " lfwd " + (string) lfwd + " xnorm " + (string) xnorm + " tang " + (string) (tang * RAD_TO_DEG) + " fpxa " + (string) (fpxa * RAD_TO_DEG) + " totrot " + (string) (llRot2Euler(rpole * llAxisAngle2Rot(raxis, tang)) * RAD_TO_DEG));
        /*  Compose the prime meridian rotation with the
            north pole alignment rotation to obtain the
            complete planet rotation.  */
        rpole = rpole * llAxisAngle2Rot(raxis, tang);
        return rpole;
    }

    //  tidalLock  --  Compute rotation to achieve tidal locking to primary

    rotation tidalLock(vector npos) {
        /*  Compute axis around which the body rotates.
            This axis is defined by the vector from its
            centre to the north pole.  */
        vector raxis = < 1, 0, 0 > * npRot;
        /*  The local Z axis (yes, I know, it doesn't make any
            sense, but bear with me) defines the prime meridian.
            This must be determined after applying to rotation
            to align the north pole in space.  */
        vector lfwd = llRot2Up(npRot);
        /*  The cross product of the normalised vector from the
            centre of the body to the centre of the primary (which,
            since the satellite is a child of the link set of
            which the primary is the root prim, is simply its local
            co-ordinates) and the rotation axis gives the normal to
            the plane defined by the rotation axis and the vector
            to the primary, passing through its centre.  */
        vector xnorm = raxis % llVecNorm(npos);
        /*  Now, our task is to rotate the satellite around its
            axis of rotation (raxis) so as to make the prime
            meridian vector (lfwd) fall within the plane to
            which xnorm is the normal.  The dot product of
            these two vectors is the cosine of the angle
            between them.  */
        float tang = PI_BY_TWO - llAcos(lfwd * xnorm); // Angle from prime meridian to axis-primary plane
        /*  The angle, tang, computed above, does not take into
            account whether the prime meridian vector, projected
            upon the line containing the centre of the satellite
            and primary, is parallel or anti-parallel to the
            vector from the centre of the satellite to the
            primary.  We compute the angle between these two
            vectors from their dot product, and then test
            their direction using the magnitude of this angle.  */
        float fpxa = llAcos(lfwd * llVecNorm(npos));
        if (fpxa < PI_BY_TWO) {
            tang = -(PI + tang);
        }
//tawk("npos " + (string) npos + " lfwd " + (string) lfwd + " tang " + (string) (tang * RAD_TO_DEG) + " ivang " + (string) (ivang * RAD_TO_DEG) + " flag " + (string) (ivang < PI_BY_TWO) + " fpxa " + (string) (fpxa * RAD_TO_DEG) + " totrot " + (string) (llRot2Euler(npRot * llAxisAngle2Rot(raxis, tang)) * RAD_TO_DEG));
        /*  Compose the prime meridian rotation with the
            north pole alignment rotation to obtain the
            complete satellite rotation.  */
        return npRot * llAxisAngle2Rot(raxis, tang);
    }

    /*  rotLaplace  --  Compute rotation to align orbit with
                        its local Laplace plane.  Orbits of
                        satellites of giant planets are often
                        specified relative to a Laplace plane
                        which is specific to the satellite.  In
                        practice, these are very close to the
                        planet's north pole direction, but not
                        identical.  Here, we compute the rotation
                        to transform orbit positions to the Laplace
                        plane.  Because the normal to the Laplace
                        plane is specified in equatorial co-ordinates,
                        we require the date in order to determine the
                        obliquity of the ecliptic to transform to
                        ecliptic co-ordinates.

                        For planets whose satellite orbits are referenced
                        to the planet's equatorial plane, simply enter
                        its north pole co-ordinates as the Laplace plane.  */

    rotation rotLaplace(integer jd, float jdf) {
        float obleq = obliqeq(jd, jdf) * DEG_TO_RAD;    // Obliquity of the ecliptic
        vector npoled = llList2Vector(planet, 28);      // Laplace plane normal, degrees
        vector npoler = npoled * DEG_TO_RAD;            // Laplace plane normal, radians

        //  Tilt to declination
        rotation rpole = llEuler2Rot(<0, PI - npoler.y, 0>);

        //  Rotate to right ascension
        rpole = rpole * llEuler2Rot(<0, 0, npoler.x>);

        //  Tilt from equatorial to ecliptic plane
        rpole = rpole * llEuler2Rot(<-obleq, 0, 0>);

        /*  Compute normal to the Laplace plane.  */
        vector raxis = < -1, 0, 0 > * rpole;
        /*  The local Z axis (yes, I know, it doesn't make any
            sense, but bear with me) defines the prime meridian.
            This must be determined after applying to rotation
            to align the Laplace plane normal in space.  */
        vector lfwd = llRot2Up(rpole);
        /*  The cross product of the normalised vector from the
            centre of the body to zero latitude in ecliptic
            co-ordinates (its positive X axis) and the rotation
            axis gives us the normal to the plane defined by
            the plane normal and zero latitude.  */
        vector xnorm = raxis % < -1, 0, 0 >;
        /*  Now, our task is to rotate the globe around its
            axis of rotation (raxis) so as to make the prime
            meridian vector (lfwd) fall within the plane to
            which xnorm is the normal.  The dot product of
            these two vectors is the cosine of the angle
            between them.  */
        float tang = PI_BY_TWO - llAcos(lfwd * xnorm); // Angle from prime meridian to axis-ecliptic meridian plane
        /*  The angle, tang, computed above, does not take into
            account whether the prime meridian vector, projected
            upon the line containing the centre of the planet
            and ecliptic origin, is parallel or anti-parallel to the
            vector from the centre of the planet to the
            origin.  We compute the angle between these two
            vectors from their dot product, and then test
            their direction using the magnitude of this angle.  */
        float fpxa = llAcos(lfwd * < -1, 0, 0 >);
        if (fpxa < PI_BY_TWO) {
            tang = -(PI + tang);
        }
//tawk("raxis " + (string) raxis + " lfwd " + (string) lfwd + " xnorm " + (string) xnorm + " tang " + (string) (tang * RAD_TO_DEG) + " fpxa " + (string) (fpxa * RAD_TO_DEG) + " totrot " + (string) (llRot2Euler(rpole * llAxisAngle2Rot(raxis, tang)) * RAD_TO_DEG));
        /*  Compose the prime meridian rotation with the
            Laplace plane alignment rotation to obtain the
            complete orbit co-ordinate rotation.  */
        rpole = rpole * llAxisAngle2Rot(raxis, tang);
//tawk("rpole " + (string) (llRot2Euler(rpole) * RAD_TO_DEG));
        return rpole;
    }

    //  l2r  --  Transform local to region co-ordinates

    vector l2r(vector loc) {
        return (loc * llGetRootRotation()) + llGetRootPosition();
    }

    //  updateLegend  --  Update floating text legend above body

    updateLegend() {
        if (s_labels) {
            llSetLinkPrimitiveParamsFast(LINK_THIS, [
                PRIM_TEXT, llList2String(planet, 0),
                           llList2Vector(planet, 27), 1
            ]);
        }
    }

    //  tawk  --  Send a message to the interacting user in chat

    tawk(string msg) {
        if (whoDat == NULL_KEY) {
            //  No known sender.  Say in nearby chat.
            llSay(PUBLIC_CHANNEL, msg);
        } else {
            /*  While debugging, when speaking to the owner, use llOwnerSay()
                rather than llRegionSayTo() to avoid the risk of a runaway
                blithering loop triggering the gag which can only be removed
                by a region restart.  */
            if (owner == whoDat) {
                llOwnerSay(msg);
            } else {
                llRegionSayTo(whoDat, PUBLIC_CHANNEL, msg);
            }
        }
    }

/*
    //  dumpOrbitalElements  --  Dump orbital elements

    dumpOrbitalElements(list e) {
        tawk(llList2String(e, 0) + "\n" +
            "  Epoch " + (string) llList2Integer(e, 1) + " + " +
                         (string) llList2Float(e, 2) + "\n" +
            "  a " + (string) llList2Float(e, 3) + "\n" +
            "  e " + (string) llList2Float(e, 4) + "\n" +
            "  i " + (string) llList2Float(e, 5) + "\n" +
            "  ῶ " + (string) llList2Float(e, 6) + "\n" +
            "  Ω " + (string) llList2Float(e, 7) + "\n" +
            "  M " + (string) llList2Float(e, 8) + "\n" +
            "  H " + (string) llList2Float(e, 9) + "\n" +
            "  G " + (string) llList2Float(e, 10) + "\n" +
            "  Tp " + (string) llList2Integer(e, 11) + " + " +
                      (string) llList2Float(e, 12) + "\n" +
            "  q " + (string) llList2Float(e, 13) + "\n" +
            "  n " + (string) llList2Float(e, 14) + "\n" +
            "  P " + (string) llList2Float(e, 15) + "\n" +
            "  Q " + (string) llList2Float(e, 16)
        );
    }
*/

    default {

        state_entry() {
            whoDat = owner = llGetOwner();

            /*  The following code synthesises the complete
                set of orbital elements from those we've
                specified in the static declaration of planet
                at the top  This is adapted from the code in the
                parseOrbitalElements() function of Minor Planets,
                with unneeded generality removed.  */

            s_elem = llListReplaceList(s_elem,
                [ llList2String(planet, 0),         // Nane
                  llList2Integer(planet, 2),        // Epoch, jd
                  llList2Float(planet, 25),         //        jdf
                  llList2Float(planet, 3),          // Semi-major axis, km
                  llList2Float(planet, 4),          // Eccentricity
                  llList2Float(planet, 5),          // Inclination, degrees
                  llList2Float(planet, 7),          // ω    Argument of periapsis, degrees
                  llList2Float(planet, 6),          // Ω    Longitude of the ascending node, degrees
                  llList2Float(planet, 8)           // Mean anomaly, degrees
                ], 0, 8);

            float m_a = llList2Float(s_elem, 3);
            float m_e = llList2Float(s_elem, 4);
            float m_M = llList2Float(s_elem, 8);

            /*  Compute the periapse date from the epoch,
                semi-major axis, and mean anomaly.  */

            float m_a_m = m_a * 1000;               // Semi-major axis, metres
            //  Orbital period, days
            float m_Tp = (TWO_PI *
                          llSqrt((m_a_m * m_a_m * m_a_m) /
                          llList2Float(planet, 26))) / 86400;
            float peridelta = m_Tp * m_M * (365.2422 / 360);
            integer pdi = llFloor(peridelta);
            peridelta -= pdi;
            integer pjd = llList2Integer(s_elem, 1) - pdi;
            float pjdf = llList2Float(s_elem, 2) - peridelta;
            while (pjdf < 0) {
                pjdf += 1;
                pjd--;
            }
            s_elem = llListReplaceList(s_elem, [ pjd, pjdf ], 11, 12);

            /*  Compute periapse distance from semi_major axis
                and eccentricity.  */
            s_elem = llListReplaceList(s_elem, [ m_a - (m_a * m_e) ], 13, 13);
            //  Update mean motion, orbital period, and apoapse distance
            s_elem = llListReplaceList(s_elem,
                [ 360 / m_Tp, m_Tp, (1 + m_e) * m_a ], 14, 16);

        /*  Gaussian gravitational constant for
            central body's mass, distances in kilometres,
            and time in days.  For example, for Jupiter:
                sqrt(G jupitermass (1 / (1000 m)^3) day^2)  */

        //  The magic number is (1 / 1000^3) * (secPerDay ^ 2)
        GaussK = llSqrt(llList2Float(planet, 26) * 7.46496);

//dumpOrbitalElements(s_elem);
        }

        on_rez(integer start_param) {
            initState = 0;

            //  If start_param is zero, this is a simple manual rez
            if (start_param != 0) {
                if (start_param == -1) {
                    start_param = 0;
                }
                m_index = start_param;

                ourName = llGetObjectName();
                deployer = llList2Key(llGetObjectDetails(llGetKey(),
                                         [ OBJECT_REZZER_KEY ]), 0);

                //  Set sit target

                llSitTarget(<-0.8, 0, 0>, llAxisAngle2Rot(<0, 1, 0>, -PI_BY_TWO));
                llSetCameraEyeOffset(<-1.2, 0, -1.2>);
                llSetCameraAtOffset(<-1, 0, 1>);

                initState = 1;          // Waiting for SETTINGS and INIT
            }
        }

        //  Process messages from the parent body, sent as link messages

        link_message(integer sender, integer num, string str, key id) {
//tawk(llGetScriptName() + " link message sender " + (string) sender + "  num " + (string) num + "  str " + str + "  id " + (string) id);

            //  LM_PS_DEPMSG (811): Deployer message forwarded by primary

            if (num == LM_PS_DEPMSG) {
                list msg = llJson2List(str);
                string ccmd = llList2String(msg, 0);

                //  ypres  --  Destroy mass

                if (ccmd == ypres) {
                    if (s_trails) {
                        /*  If we've been littering the world with
                            flPlotLine tracing our motion, clean them up
                            now rather than waiting for the garbage
                            collector to come around.  Note that since
                            we are the deployer for these objects, they
                            won't respond to a ypres message from the
                            deployer which rezzed us.  */
                        llRegionSay(massChannel,
                            llList2Json(JSON_ARRAY, [ ypres ]));
                    }

                //  LIST  --  List mass information

                } else if (ccmd == "LIST") {
                    integer mFree = llGetFreeMemory();
                    integer mUsed = llGetUsedMemory();

                    tawk("Mass " + (string) m_index +
                         "  Name: " + m_name +
                         "  Position: " + efv(llGetPos()) +
                         "\n    Script memory.  Free: " + (string) mFree +
                            "  Used: " + (string) mUsed + " (" +
                            (string) ((integer) llRound((mUsed * 100.0) / (mUsed + mFree))) + "%)"
                    );

                //  PINIT  --  Set initial parameters after creation

                } else if (ccmd == "PINIT") {
                    m_name = llList2String(msg, 2);             // Name
                    deployerPos = sv(llList2String(msg, 3));    // Deployer position
                    m_scalePlanet = siuf(llList2String(msg, 4));    // Planet scale
                    m_jd = llList2Integer(msg, 6);              // Epoch Julian day
                    m_jdf = siuf(llList2String(msg, 7));        // Epoch Julian day fraction

                    //  Set properties of object
                    float oscale = m_scalePlanet;

                    //  Compute size of body based upon scale factor

                    vector psize = < llList2Float(planet, 16),
                                     llList2Float(planet, 15),
                                     llList2Float(planet, 15) > * 0.0001 * oscale;

                    //  Calculate rotation to correctly orient north pole

                    npRot = rotPole(m_jd, m_jdf);

                    llSetLinkPrimitiveParamsFast(LINK_THIS, [
                        PRIM_DESC,  llList2Json(JSON_ARRAY,
                            [ m_index, m_name, eff(llList2Float(planet, 17)) ]),
                        PRIM_SIZE, psize,           // Scale to proper size
                        PRIM_ROT_LOCAL, npRot       // Rotate north pole to proper orientation
                    ]);
                    llSetStatus(STATUS_PHANTOM | STATUS_DIE_AT_EDGE, TRUE);

                    initState = 2;                  // INIT received, waiting for SETTINGS

                //  SETTINGS  --  Set simulation parameters

                } else if (ccmd == "SETTINGS") {
                    integer o_labels = s_labels;

                    paths = llList2Integer(msg, 2);
                    s_trace = llList2Integer(msg, 3);
                    s_kaboom = siuf(llList2String(msg, 4));
                    s_auscale = siuf(llList2String(msg, 5));
                    s_trails = llList2Integer(msg, 7);
                    s_pwidth = siuf(llList2String(msg, 8));
                    s_mindist = siuf(llList2String(msg, 9));
                    s_labels = llList2Integer(msg, 21);

                    //  Update label if state has changed
                    if (s_labels != o_labels) {
                        if (s_labels) {
                            updateLegend();
                        } else {
                            llSetLinkPrimitiveParamsFast(LINK_THIS, [
                                PRIM_TEXT, "", ZERO_VECTOR, 0 ]);
                        }
                    }

                    if (initState == 2) {
                        initState = 3;                  // INIT and SETTINGS received
                        startTime = llGetTime();        // Remember when we started
                    }

                    //  Set or clear particle trail depending upon paths
                    if (paths) {
                        llParticleSystem(
                            [ PSYS_PART_FLAGS, PSYS_PART_EMISSIVE_MASK |
                              PSYS_PART_INTERP_COLOR_MASK |
                              PSYS_PART_RIBBON_MASK,
                              PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_DROP,
                              PSYS_PART_START_COLOR, llList2Vector(planet, 27),
                              PSYS_PART_END_COLOR, llList2Vector(planet, 27),
                              PSYS_PART_START_SCALE, <0.75, 0.75, 1>,
                              PSYS_PART_END_SCALE, <0.75, 0.75, 1>,
                              PSYS_SRC_MAX_AGE, 0,
                              PSYS_PART_MAX_AGE, 8.0,
                              PSYS_SRC_BURST_RATE, 0.0,
                              PSYS_SRC_BURST_PART_COUNT, 60
                            ]);
                    } else {
                        llParticleSystem([ ]);
                    }

                    if (!s_trails) {
                        lastTrailP = ZERO_VECTOR;
                    }
                }

            //  LM_PS_UPDATE (812): Update position and rotation of satellite

            } else if (num == LM_PS_UPDATE) {
                list msg = llJson2List(str);

                integer jd = llList2Integer(msg, 0);
                float jdf = siuf(llList2String(msg, 1));

                vector lxyz = posSat(jd, jdf);

float s_satscale = 5e-5 * m_scalePlanet; // Scale factor, satellite orbit km to model metres
                vector mxyz = (lxyz * s_satscale) *
                    (llEuler2Rot(<0, -PI_BY_TWO, 0>) * rotLaplace(jd, jdf));
//tawk(llGetScriptName() + " lxyz " + (string) lxyz + "  mxyz " + (string) mxyz +
// " s_auscale " + (string) s_auscale + "  s_satscale " + (string) (s_satscale * 1.0e7));
                if (llVecDist(llGetPos(), mxyz) >= s_mindist) {
                    llSetLinkPrimitiveParamsFast(LINK_THIS, [
                                PRIM_POS_LOCAL, mxyz,
                                PRIM_ROT_LOCAL, tidalLock(mxyz) ]);

//                    if (paths) {
//                        llSetLinkPrimitiveParamsFast(LINK_THIS,
//                            [ PRIM_ROTATION, llRotBetween(<0, 0, 1>, (npos - p)) ]);
//                    }
                    if (s_trails) {
                        vector trailP = l2r(mxyz);
                        if (lastTrailP != ZERO_VECTOR) {
                            flPlotLine(lastTrailP, trailP,
                                       llList2Vector(planet, 27), s_pwidth);
                        }
                        lastTrailP = trailP;
                    }
                }
            }
        }
     }
