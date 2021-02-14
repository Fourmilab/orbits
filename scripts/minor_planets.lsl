    /*

                          Fourmilab Orbits

                            Minor Planets

        This script handles specification of the orbits of minor
        planets (asteroids and comets) and computation of their
        positions from their orbital elements.  It handles bodies
        in elliptical, parabolic, and hyperbolic orbits, and a
        variety of orbital element parameterisations.

    */

    key owner;                      // Owner UUID
    key whoDat = NULL_KEY;          // Avatar who sent command
    string helpFileName = "Fourmilab Orbits User Guide"; // Help notecard name

    list s_elem = [ ];              // Elements of currently tracked body

    float M_E = 2.718281828459045;  // Base of the natural logarithms

    //  Link messages

    //  Command processor messages
    integer LM_CP_COMMAND = 223;    // Process command

    //  Auxiliary services messages

    integer LM_AS_LEGEND = 541;         // Update floating text legend

    //  Minor planet messages

    integer LM_MP_TRACK = 571;      // Notify tracking minor planet

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

    //  sgn  --  Return sign of argument

    integer sgn(float v) {
        if (v == 0) {
            return 0;
        } else if (v > 0) {
            return 1;
        }
        return -1;
    }

    //  Hyperbolic trigonometric functions

    float flSinh(float x) {
        return (llPow(M_E, x) - llPow(M_E, -x)) / 2;
    }

    float flCosh(float x) {
        return (llPow(M_E, x) + llPow(M_E, -x)) / 2;
    }

    float flTanh(float x) {
        return flSinh(x) / flCosh(x);
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

        /*  We employ three different algorithms, each optimised for
            a particular range of eccentricities.  For hyperbolic
            orbits with eccentricity greater than 1.1, we use a
            first-principles solution of the hyperbolic Kepler
            equation by Newton-Raphson iteration.  Note that since
            LSL does not implement hyperbolic trigonometric functions,
            we use our own, defined above.  */

        if (e > 1.0) {
            float a1 = llFabs(q / (1 - e));
            float m = (K * t) / (a1 * llSqrt(a1));

            float eps = 1e-6;       // Convergence criterion
            float H = m;            // Initial estimate

            //  Initialise iteration
            f = (e * flSinh(H)) - H - m;
            float f_prime = (e * flCosh(H)) - 1;
            float ratio = f / f_prime;

            //  Iterate until we converge
            while (llFabs(ratio) > eps) {
                f = (e * flSinh(H)) - H - m;
                f_prime = (e * flCosh(H)) - 1;
                ratio = f / f_prime;

                if (llFabs(ratio) > eps) {
                    H = H - ratio;
                }
            }

            /*  Compute true anomaly v from hyperbolic anomaly H.  Note
                that in the outer expression, we use the circular
                arc tangent function: this is not an error--think about
                it!  */
            v = 2 * llAtan2(llSqrt((e + 1) / (e - 1)) * flTanh(H / 2), 1);
            //  Finally, compute radius vector to central body
            r = (-a1) * (1 - (e * flCosh(H)));

            return [ v, r ];
        }

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

    float J2000 = 2451545.0;            // Julian day of J2000 epoch
    float JulianCentury = 36525.0;      // Days in Julian century

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

    //  parseJD  --  Parse decimal Julian date into list of day and fraction

    list parseJD(string td) {
        list jf = llParseString2List(td, ["."], []);
        return [ (integer) llList2String(jf, 0),
                 (float) ("0." + llList2String(jf, 1)) ];
    }

    //  spec  --  Test if orbital element specified (not NaN)

    integer spec(float e) {
        return ((string) e) != "NaN";
    }

    //  parseOrbitalElements  --  Parse asteroid or comet orbital elements

    list parseOrbitalElements(string message) {
        list args = llParseString2List(message, [ " " ], []);   // Command and arguments
        args = fixQuotes(args);
        integer argn = llGetListLength(args);       // Number of arguments

        string m_name = llList2String(args, 1);

        //  Re-parse specification for case-insensitive comparisons
        args = llParseString2List(llToLower(message), [ " " ], []);
        args = fixQuotes(args);
        argn = llGetListLength(args);               // Number of arguments
        integer i;

        float NaN = (float) "nan";
        list m_Epoch = [ ];         // Epoch (JD)
        float m_a = NaN;            // Semi-major axis, AU
        float m_e = NaN;            // Eccentricity
        float m_i = NaN;            // Inclination, degrees
        float m_peri = NaN;         // Argument of periapse, degrees
        float m_node = NaN;         // Longitude of ascending node, degrees
        float m_M = NaN;            // Mean anomaly, degreees
        float m_H = NaN;            // Magnitude
        float m_G = NaN;            // Magnitude slope

        float m_q = NaN;            // Periapse distance, AU
        list m_Tp = [ ];            // Time of periapse, JD
        float m_n = NaN;            // Mean motion, degrees/day
        float m_P = NaN;            // Orbital period, days
        float m_Q = NaN;            // Apoapse distance, AU

        for (i = 2; i < argn; i += 2) {
            string var = llList2String(args, i);
            float val = NaN;
            if ((i + 1) < argn) {
                val = llList2Float(args, i + 1);
            }
            if (!spec(val)) {
                tawk("Bad value for var " + var +
                    " args[" + (string) (i + 1) + "]: " + (string) val +
                    " from " + llList2String(args, i + 1));
                return [ ];
            }

            if (abbrP(var, "a")) {          // a    Semi-major axis
                m_a = val;
            } else if (abbrP(var, "e")) {   // e    Eccentricity
                m_e = val;
            } else if (abbrP(var, "i")) {   // i    Inclination
                m_i = val;
            } else if (abbrP(var, "w")) {   // w    Argument of periapse
                m_peri = val;
            } else if (abbrP(var, "n")) {   // n    Longitude of ascending node
                m_node = val;
            } else if (abbrP(var, "m")) {   // M    Mean anomaly
                m_M = val;
            } else if (abbrP(var, "h")) {   // H    Magnitude
                m_H = val;
            } else if (abbrP(var, "g")) {   // G    Magnitude slope
                m_G = val;
            } else if (abbrP(var, "t")) {   // T    Epoch
                if (val != NaN) {
                    m_Epoch = parseJD(llList2String(args, i + 1));
                }
            } else if (abbrP(var, "p")) {   // P    Time of periapse
                if (val != NaN) {
                    m_Tp = parseJD(llList2String(args, i + 1));
                }
            } else if (abbrP(var, "q")) {   // q    Periapse distance
                m_q = val;
            } else {
                tawk("Invalid orbital element parameter \"" + var + \"\" (arg " +
                    (string) i + ")");
                return [ ];
            }
        }

        if ((!spec(m_e)) || (!spec(m_i)) || (!spec(m_peri)) ||
            (!spec(m_node))) {
            tawk(m_name + ": required orbital element (e, i, w, node) missing.");
            return [ ];
        }

        /*  If periapse date unspecified, compute it from
            the epoch, semi-major axis, and mean anomaly, if given.  */
        if ((m_Tp == [ ]) && (m_Epoch != [ ]) && spec(m_a) && spec(m_M)) {
            float peridelta = llSqrt(m_a * m_a * m_a) * m_M * (365.2422 / 360);
            integer pdi = llFloor(peridelta);
            peridelta -= pdi;
            integer pjd = llList2Integer(m_Epoch, 0) - pdi;
            float pjdf = llList2Float(m_Epoch, 1) - peridelta;
            while (pjdf < 0) {
                pjdf += 1;
                pjd--;
            }
            m_Tp = [ pjd, pjdf ];
        }

        /*  If periapse distance is unspecified, compute from
            semi_major axis and eccentricity, if specified.  */

        if ((!spec(m_q)) && spec(m_a) && spec(m_e)) {
            m_q = m_a - (m_a * m_e);
        }

        /*  If the semi-major axis is not specified, and the
            orbit is non-parabolic (m_e != 1), and the
            perihelion distance is known, compute it.  We
            follow the convention of assigning a negative
            semi-major axis to objects in hyperbolic orbits,
            which allows computing a mean motion which is useful
            in deriving a mean anomaly from the perihelion date.  */

        if ((!spec(m_a)) && (m_e != 1) && spec(m_q)) {
            m_a = m_q / (1 - m_e);
        }

        /*  Compute mean motion.  The magic number in the
            numerator is the Gaussian gravitational constant
            k = 0.01720209895 radians/day converted to degrees.
            The apoapse distance is computed from the semi-major
            axis and eccentricity and is, of course, only defined
            for elliptical orbits.  */
        if (m_e < 1) {
            m_n = 0.9856076686 / (m_a * llSqrt(m_a));
            m_P = 360 / m_n;
            m_Q = (1 + m_e) * m_a;
        } else if (m_e > 1) {
            //  This is how JPL computes it for objects in hyperbolic orbits
            m_n = 0.9856076686 / ((-m_a) * llSqrt(-m_a));
        }

        /*  If mean anomaly was not specified, and we know
            the distance and date of perihelion, compute it.  */

        if ((!spec(m_M)) && (m_Tp != [ ]) && spec(m_n)) {
            float deltat = (llList2Integer(m_Epoch, 0) - llList2Integer(m_Tp, 0)) +
                           (llList2Float(m_Epoch, 1) - llList2Float(m_Tp, 1));
            m_M = m_n * deltat;
        }

        return [ m_name ] +             // 0    Name
                m_Epoch +               // 1,2  epoch [ jd, jdf ]
                [ m_a,                  // 3    a (semi-major axis)
                  m_e,                  // 4    e (eccentricity)
                  m_i,                  // 5    i (inclination)
                  m_peri,               // 6    ῶ (argument of periapse)
                  m_node,               // 7    Ω (longitude of ascending node)
                  m_M,                  // 8    M (mean anomaly)
                  m_H,                  // 9    H (magnitude)
                  m_G ] +               // 10   G (magnitude slope)
                  m_Tp +                // 11,12 Tp (time of perhelion)
                [ m_q ,                 // 13   q (periapse distance)
                  m_n,                  // 14   n (mean motion)
                  m_P,                  // 15   P (orbital period)
                  m_Q                   // 16   Q (apoapse distance)
                ];
    }

    //  posMP  --  Compute position of currently-tracked minor planet

    list posMP(integer jd, float jdf) {
        vector pos = computeOrbit(s_elem, [ jd, jdf ]);
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
        return [ hlong, hlat, hrv ];
    }

/*
    //  dumpOrbitalElements  --  Dump orbital elements

    dumpOrbitalElements(list e) {
        tawk(llList2String(e, 0) + "\n" +
            "  Epoch " + editJDtoDec(llList2List(e, 1, 2)) + "  " +
                         editJDtoUTC(llList2List(e, 1, 2)) + "\n" +
            "  a " + (string) llList2Float(e, 3) + "\n" +
            "  e " + (string) llList2Float(e, 4) + "\n" +
            "  i " + (string) llList2Float(e, 5) + "\n" +
            "  ῶ " + (string) llList2Float(e, 6) + "\n" +
            "  Ω " + (string) llList2Float(e, 7) + "\n" +
            "  M " + (string) llList2Float(e, 8) + "\n" +
            "  H " + (string) llList2Float(e, 9) + "\n" +
            "  G " + (string) llList2Float(e, 10) + "\n" +
            "  Tp " + editJDtoDec(llList2List(e, 11, 12)) + "  " +
                      editJDtoUTC(llList2List(e, 11, 12)) + "\n" +
            "  q " + (string) llList2Float(e, 13) + "\n" +
            "  n " + (string) llList2Float(e, 14) + "\n" +
            "  P " + (string) llList2Float(e, 15) + "\n" +
            "  Q " + (string) llList2Float(e, 16)
        );
    }
*/

    /*  jyearl  --  Convert Julian date/time list to year, month, day,
                    which are returned as a list.  */

    list jyearl(list tdl) {
        float a;
        float alpha;
        integer yy;
        integer mm;

        float td = llList2Float(tdl, 0);
        float tdf = llList2Float(tdl, 1);

        tdf += 0.5;                     // Adjust for Julian date changes at noon
        if (tdf > 1.0) {                // If this advanced day
            td++;                       //    then bump the integral day
            tdf -= 1;                   //    and decrement fractional day
        }

        float z = td;
        float f = tdf;

        if (z < 2299161.0) {
            a = z;
        } else {
            alpha = llFloor((z - 1867216.25) / 36524.25);
            a = z + 1 + alpha - llFloor(alpha / 4);
        }

        float b = a + 1524;
        float c = llFloor((b - 122.1) / 365.25);
        float d = llFloor(365.25 * c);
        float e = llFloor((b - d) / 30.6001);

        if (e < 14) {
            mm = (integer) (e - 1);
        } else {
            mm = (integer) (e - 13);
        }

        if (mm > 2) {
            yy = (integer) (c - 4716);
        } else {
            yy = (integer) (c - 4715);
        }

        return [
                 yy,                                            // year
                 mm,                                            // month
                 (integer) (b - d - llFloor(30.6001 * e) + f)   // day
               ];
    }

    /*  JHMS  --  Convert Julian time to hour, minutes, and seconds,
                  returned as a list.  */

    list jhms(float j) {
        j += 0.5;                 // Astronomical to civil
        integer ij = (integer) ((j - llFloor(j)) * 86400.0);
        return [
                    (ij / 3600),        // hours
                    ((ij / 60) % 60),   // minutes
                    (ij % 60)           // seconds
               ];
    }

    /*  editJDtoUTC  --  Edit a Julian date pair list to UTC date and time.
                         Displays the time as hours and minutes, rounded
                         to the nearest minute.  */

    string zerofill(integer n, integer places) {        // Integer to string with zero fill
        string sn = (string) n;
        while (llStringLength(sn) < places) {
            sn = "0" + sn;
        }
        return sn;
    }

    string editJDtoUTC(list jd) {
        list utctime = jhms(llList2Float(jd, 1));

        //  Round to nearest minute
        if (llList2Integer(utctime, 2) >= 30) {
            integer utchour = llList2Integer(utctime, 0);
            integer utcmin = llList2Integer(utctime, 1) + 1;
            if (utcmin >= 60) {
                utcmin -= 60;
                utchour++;
                if (utchour >= 24) {
                    utchour -= 24;
                    jd = llListReplaceList(jd, [  llList2Float(jd, 0) + 1 ], 0, 0);
                }
            }
            utctime = [ utchour, utcmin, 0 ];
        }

        list utcdate = jyearl(jd);
        string textutc = zerofill(llList2Integer(utcdate, 0), 4) +
                   "-" + zerofill(llList2Integer(utcdate, 1), 2) +
                   "-" + zerofill(llList2Integer(utcdate, 2), 2) +
                   " " + zerofill(llList2Integer(utctime, 0), 2) +
                   ":" + zerofill(llList2Integer(utctime, 1), 2);
        return textutc;
    }

    //  editJDtoDec  --  Edit a Julian date pair list to a decimal Julian date

    string editJDtoDec(list jd) {
        string textjd = (string) llList2Float(jd, 0) + " " + (string) llList2Float(jd, 1);
        list ljd = llParseString2List(textjd, [".", " "], [" "]);
        textjd = llList2String(ljd, 0) + "." + llList2String(ljd, 3);

        return textjd;
    }

    /*  fixArgs  --  Transform command arguments into canonical form.
                     All white space within vector and rotation brackets
                     is elided so they will be parsed as single arguments.  */

    string fixArgs(string cmd) {
        cmd = llStringTrim(cmd, STRING_TRIM);
        integer l = llStringLength(cmd);
        integer inbrack = FALSE;
        integer i;
        string fcmd = "";

        for (i = 0; i < l; i++) {
            string c = llGetSubString(cmd, i, i);
            if (inbrack && ((c == ">") || (c == "}"))) {
                inbrack = FALSE;
            }
            if ((c == "<") || (c == "{")) {
                inbrack = TRUE;
            }
            if (!((c == " ") && inbrack)) {
                fcmd += c;
            }
        }
        return fcmd;
    }

    /*  fixQuotes  --   Adjacent arguments bounded by those
                        beginning and ending with quotes (") are
                        concatenated into single arguments with
                        the quotes elided.  */

    list fixQuotes(list args) {
        integer i;
        integer n = llGetListLength(args);

        for (i = 0; i < n; i++) {
            string arg = llList2String(args, i);
            if (llGetSubString(arg, 0, 0) == "\"") {
                /*  Argument begins with a quote.  If it ends with one,
                    strip them and we're done.  */
                if (llGetSubString(arg, -1, -1) == "\"") {
                    args = llListReplaceList(args,
                        [ llGetSubString(arg, 1, -2) ], i, i);
                } else {
                    /*  Concatenate arguments until we find one that ends
                        with a quote, then replace the multiple arguments
                        with the concatenation.  */
                    string rarg = llGetSubString(arg, 1, -1);
                    integer looking = TRUE;
                    integer j;

                    for (j = i + 1; looking && (j < n); j++) {
                        string narg = llList2String(args, j);
                        if (llGetSubString(narg, -1, -1) == "\"") {
                            rarg += " " + llGetSubString(narg, 0, -2);
                            looking = FALSE;
                        } else {
                            rarg += " " + narg;
                        }
                    }
                    if (!looking) {
                        args = llListReplaceList(args, [ rarg ], i, j - 1);
                    }
                }
            }
        }
        return args;
    }

    //  abbrP  --  Test if string matches abbreviation

    integer abbrP(string str, string abbr) {
        return abbr == llGetSubString(str, 0, llStringLength(abbr) - 1);
    }

    //  processAuxCommand  --  Process a command

    integer processAuxCommand(key id, list args) {

        whoDat = id;            // Direct chat output to sender of command

        string message = llList2String(args, 0);
        string lmessage = fixArgs(llToLower(message));
        args = llParseString2List(lmessage, [ " " ], []);   // Command and arguments
        integer argn = llGetListLength(args);       // Number of arguments
        string command = llList2String(args, 0);    // The command

        //  Asteroid                Set asteroid orbital elements
        //  Comet                   Set comet orbital elements

        /*  Elements for both kinds of bodies are specified in exactly
            the same fashion and variety of forms.  The only difference
            is which model is used to represent the body in the
            simulation.  */

        integer isAst;
        if ((isAst = abbrP(command, "as")) || abbrP(command, "co")) {
            if (argn < 2) {
                s_elem = [ ];
                llMessageLinked(LINK_THIS, LM_MP_TRACK,
                    llList2Json(JSON_ARRAY, [ FALSE ]), id);
            } else {
                list e = parseOrbitalElements(message);
                if (e != [ ]) {
                    if (s_elem != [ ]) {
                        //  Stop tracking and destroy previous body
                        llMessageLinked(LINK_THIS, LM_MP_TRACK,
                            llList2Json(JSON_ARRAY, [ FALSE ]), id);
                    }
                    s_elem = e;                 // Save active orbital elements

                    //  Inform simulation we're tracking an object
                    llMessageLinked(LINK_THIS, LM_MP_TRACK,
                        llList2Json(JSON_ARRAY,
                            [ TRUE,                     // 0    Status
                              llList2String(s_elem, 0), // 1    Name
                              llList2Float(s_elem, 15), // 2    Orbital period (note NaN m_e >= 1)
                              isAst,                    // 3    Is this asteroid (not comet) ?
                              llList2Integer(s_elem, 11), // 4  Julian day of perihelion...
                              llList2Float(s_elem, 12),   // 5  ...and fraction
                              llList2Float(s_elem, 3),  // 6    Semi-major axis (NaN m_e >= 1)
                              llList2Float(s_elem, 4)   // 7    Eccentricity
                            ]), id);
                }
            }

        //  Clear                   Clear chat for debugging

        } else if (abbrP(command, "cl")) {
            tawk("\n\n\n\n\n\n\n\n\n\n\n\n\n");

        //  Help                    Give User Guide notecard to requester

        } else if (abbrP(command, "he")) {
            llGiveInventory(whoDat, helpFileName);  // Give requester the User Guide notecard

        //  Status

        } else if (abbrP(command, "sta")) {
            string s = llGetScriptName() + " status:\n";

            integer mFree = llGetFreeMemory();
            integer mUsed = llGetUsedMemory();
            s += "  Script memory.  Free: " + (string) mFree +
                 "  Used: " + (string) mUsed + " (" +
                    (string) ((integer) llRound((mUsed * 100.0) / (mUsed + mFree))) + "%)";
            tawk(s);
/*
            if (s_elem != [ ]) {
                tawk("  Tracking:");
                dumpOrbitalElements(s_elem);
            }
*/
        }
        return TRUE;
    }

    integer BODY = 10;                  // Our body number

    integer LM_EP_CALC = 431;           // Calculate ephemeris
    integer LM_EP_RESULT = 432;         // Ephemeris calculation result
    integer LM_EP_STAT = 433;           // Print memory status

    default {

        on_rez(integer n) {
            llResetScript();
        }

        state_entry() {
            whoDat = owner = llGetOwner();
        }

        /*  The link_message() event receives commands from other scripts
            script and passes them on to the script processing functions
            within this script.  */

        link_message(integer sender, integer num, string str, key id) {
//tawk(llGetScriptName() + " link message sender " + (string) sender + "  num " + (string) num + "  str " + str + "  id " + (string) id);

            //  LM_CP_COMMAND (223): Process auxiliary command

            if (num == LM_CP_COMMAND) {
                processAuxCommand(id, llJson2List(str));

            //  LM_EP_CALC (431): Calculate ephemeris

            } else if (num == LM_EP_CALC) {
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

            //  LM_AS_LEGEND (541): Update floating text legend

            } else if (num == LM_AS_LEGEND) {
                /*  Why is this here?  Because we already have the JD
                    editing functions it needs, and information about
                    the currently tracked object, if any.  */
                list args = llJson2List(str);
                string legend;
                if (llList2Integer(args, 0) && (llList2Integer(args, 7) == 0)) {
                    legend = "Time " + (string) llList2Float(args, 1) + " years\n" +
                        "Step " + (string) llList2Integer(args, 2);
                } else {
                    list jdl = llList2List(args, 5, 6);
                    legend = "JD " + editJDtoDec(jdl) +
                        "\nUTC " + editJDtoUTC(jdl) +
                        "\nStep " + (string) llList2Integer(args, 2);
                    if (s_elem != [ ]) {
                        legend += "\nTrack " + llList2String(s_elem, 0);
                    }
                }
                llSetLinkPrimitiveParamsFast(LINK_THIS, [
                    PRIM_TEXT, legend, <0, 1, 0>, 1
                ]);
            }
        }
    }
