
   /*              _       _
             _ __ | |_   _| |_ ___
            | '_ \| | | | | __/ _ \
            | |_) | | |_| | || (_) |
            | .__/|_|\__,_|\__\___/
            |_|
    */

    integer J2000 = 2451545;            // Julian day of J2000 epoch
    float JulianCentury = 36525.0;      // Days in Julian century

    list s_elem = [
        "Pluto",                // 0    Name
        2454000, 0.5,           // 1,2  epoch [ jd, jdf ]
        39.4450697257358,       // 3    a (semi-major axis)
        0.250248713478499,      // 4    e (eccentricity)
        17.089000919562,        // 5    i (inclination)
        112.5971416774872,      // 6    ῶ (argument of periapse)
        110.3769579554089,      // 7    Ω (longitude of ascending node)
        25.24718971218841,      // 8    M (mean anomaly)
        -0.4,                   // 9    H (magnitude)
        0.15,                   // 10   G (magnitude slope)
        0, 0.0,                 // 11,12 Tp (time of perhelion)
        0.0,                    // 13   q (periapse distance)
        0.0,                    // 14   n (mean motion)
        0.0,                    // 15   P (orbital period)
        0.0                     // 16   Q (apoapse distance)
    ];

    integer BODY = 9;                   // Our body number

    integer LM_EP_CALC = 431;           // Calculate ephemeris
    integer LM_EP_RESULT = 432;         // Ephemeris calculation result
    integer LM_EP_STAT = 433;           // Print memory status

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
        float K = 0.01720209895;        // Gaussian gravitational constant

        /*  Solution by binary search by Roger W. Sinnott, Sky and Telescope,
            Vol. 70, page 159 (August 1985).  This is presented as the
            "Third Method" in chapter 30 of Meeus, "Astronomical Algorithms",
            2nd ed.  We use this for all eccentricities less than 0.98.  */

        float m;
        float a1;
        float ev;

        a1 = q / (1 - e);
        m = K * t * llPow(a1, -1.5);

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

    float obliqeq(float jd, float jdf) {
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

        v = u = ((jd - J2000) / (JulianCentury * 100)) + (jdf / (JulianCentury * 100));

        if (llFabs(u) < 1.0) {
            for (i = 0; i < 10; i++) {
                eps += llList2Float(oterms, i) * v;
                v *= u;
            }
        }
        return eps;
    }

    /*  computeOrbit  --  Compute heliocentric rectangular co-ordinates
                          of object from orbital elements.  */

    vector computeOrbit(list elements, list jdl) {
        float e = obliqeq(llList2Integer(jdl, 0), llList2Float(jdl, 1)) * DEG_TO_RAD;
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
        list k = gKepler(llList2Float(elements, 4), dtf,
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
        return ZERO_VECTOR;
    }

    //  posMP  --  Compute position of currently-tracked minor planet

    list posMP(integer jd, float jdf) {
        vector pos = computeOrbit(s_elem, [ jd, jdf ]);
//tawk("Heliocentric position: " + (string) pos + "  rv " + (string) llVecMag(pos));
        float x = pos.x;
        float y = pos.y;
        float z = pos.z;
        float obelix = obliqeq(jd, jdf) * DEG_TO_RAD;
        float hra = llAtan2(y, x);
        float hdec = llAtan2(z, llSqrt((x * x) + (y * y)));
        float hrv = llSqrt((x * x) + (y * y) + (z * z));
        float hlong = llAtan2((llSin(hra) * llCos(obelix)) +
                                (llTan(hdec) * llSin(obelix)), llCos(hra));
        float hlat = llAsin(llSin(hdec) * llCos(obelix) -
                                (llCos(hdec) * llSin(obelix) * llSin(hra)));
//tawk("pos " + (string) pos + " obelix " + (string) obelix + " hra " + (string) hra +
//    " hdec " + (string) hdec + " hrv " + (string) hrv + " hlong " + (string) hlong +
//    " hlat " + (string) hlat);
        return [ fixangr(hlong), hlat, hrv ];
    }

    //  fixangr  --  Range reduce an angle in radians

    float fixangr(float a) {
        return a - (TWO_PI * (llFloor(a / TWO_PI)));
    }

/*
    //  dumpOrbitalElements  --  Dump orbital elements

    dumpOrbitalElements(list e) {
        llOwnerSay(llList2String(e, 0) + "\n" +
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
            /*  The following code synthesises the complete
                set of orbital elements from those we've
                specified in the static declaration of s_elem
                at the top, taken from the JPL Small-Body
                Database.  This is adapted from the code in the
                parseOrbitalElements() function of Minor Planets,
                with unneeded generality removed.  */

            float m_a = llList2Float(s_elem, 3);
            float m_e = llList2Float(s_elem, 4);
            float m_M = llList2Float(s_elem, 8);

            /*  Compute the periapse date from the epoch,
                semi-major axis, and mean anomaly.  */
            float peridelta = llSqrt(m_a * m_a * m_a) * m_M * (365.2422 / 360);
            integer pdi = llFloor(peridelta);
            peridelta -= pdi;
            integer pjd = llList2Integer(s_elem, 1) - pdi;
            float pjdf = llList2Float(s_elem, 2) - peridelta;
            while (pjdf < 0) {
                pjdf += 1;
                pjd--;
            }
            s_elem = llListReplaceList(s_elem, [ pjd, pjdf ], 11, 12);
//                m_Tp = [ pjd, pjdf ];

            /*  Compute periapse distance from semi_major axis
                and eccentricity.  */
            s_elem = llListReplaceList(s_elem, [ m_a - (m_a * m_e) ], 13, 13);

            /*  Compute mean motion.  The magic number in the
                numerator is the Gaussian gravitational constant
                k = 0.01720209895 radians/day converted to degrees.
                The apoapse distance is computed from the semi-major
                axis and eccentricity and is, of course, only defined
                for elliptical orbits.  */
            float m_n = 0.9856076686 / (m_a * llSqrt(m_a));
//            m_P = 360 / m_n;
//            m_Q = (1 + m_e) * m_a;
            s_elem = llListReplaceList(s_elem, [ 360 / m_n, (1 + m_e) * m_a ], 15, 16);

//dumpOrbitalElements(s_elem);
        }

        link_message(integer sender, integer num, string str, key id) {

            //  LM_EP_CALC (431): Calculate ephemeris

            if (num == LM_EP_CALC) {
                list args = llCSV2List(str);
                integer argn = llGetListLength(args);
                if (llList2Integer(args, 0) & (1 << BODY)) {
                    list eph = [ ];
                    integer i;

                    for (i = 1; (i + 1) < argn; i += 2) {
                        eph += posMP(llList2Integer(args, i),
                                     llList2Float(args, i + 1));
                    }
                    integer handle = llList2Integer(args, i);
                    llMessageLinked(LINK_THIS, LM_EP_RESULT,
                        (string) BODY + "," +
                        llList2CSV(eph + [ handle ]), id);
                }

            //  LM_EP_STAT (433): Print memory status

            } else if (num == LM_EP_STAT) {
                integer mFree = llGetFreeMemory();
                integer mUsed = llGetUsedMemory();
                llOwnerSay(llGetScriptName() + " status:" +
                     " Script memory.  Free: " + (string) mFree +
                        "  Used: " + (string) mUsed + " (" +
                        (string) ((integer) llRound((mUsed * 100.0) / (mUsed + mFree))) + "%)"
                );
            }
        }
    }
