    /*

                            Fourmilab Orbits

                             Galactic Centre

        This script handles specification of objects in the centre
        of a galaxy, processing the Centre and Source commands which
        declare the central object (usually a super-massive black
        hole) and the bodies ("Sources") which orbit it.  The only
        thing we need to know about the central body is its mass,
        and the orbits of the sources are specified as orbital
        elements in the same fashion we use for comets in Minor
        Planets.  Sources may be on elliptical, parabolic, or
        hyperbolic trajectories.

    */

    key owner;                      // Owner UUID
    key whoDat = NULL_KEY;          // Avatar who sent command

    integer massChannel = -982449822;   // Channel for communicating with sources
//    float REGION_SIZE = 256;        // Second Life grid region size, metres

    list s_elem = [ ];              // Elements of sources
    list s_sources = [ ];           // Orbital elements of sources
    integer s_sourcesE = 17;        // Size of sources list entry
    list source_keys = [ ];         // Keys of deployed sources

    integer nCentres = 0;           // Number of central bodies
    string nCentre;                 // Name of central body
    float mCentre;                  // Central body mass (solar masses)
    key kCentre;                    // Key of central body

//    integer m_updating = FALSE;     // Is an update in progress ?

    /*  Standard colour names and RGB values.  This is
        based upon the resistor colour code.  */

    list colours = [
        <0, 0, 0>,                   // 0
        <0.3176, 0.149, 0.1529>,     // 1
        <0.8, 0, 0>,                 // 2
        <0.847, 0.451, 0.2784>,      // 3
        <0.902, 0.788, 0.3176>,      // 4
        <0.3216, 0.5608, 0.3961>,    // 5
        <0.00588, 0.3176, 0.5647>,   // 6
        <0.4118, 0.4039, 0.8078>,    // 7
        <0.4902, 0.4902, 0.4902>,    // 8
        <1, 1, 1>,                   // 9

        <0.749, 0.745, 0.749>,       // 10%
        <0.7529, 0.5137, 0.1529>     // 5%
    ];

    float M_E = 2.718281828459045;  // Base of the natural logarithms

    float G_SI = 6.6732e-11;            // (Newton Metre^2) / Kilogram^2
    float AU = 149504094917.0;          // Metres / Astronomical unit
    float M_SUN = 1.989e30;             // Kilograms / Mass of Sun
    float YEAR = 31536000;              // Seconds / Year (365.0 * 24 * 60 * 60)

    /*  From Newton's second law, F = ma,

               Newton = kg m / sec^2

        the fundamental units of the gravitational constant are:

               G = N m^2 / kg^2
                 = (kg m / sec^2) m^2 / kg^2
                 = kg m^3 / sec^2 kg^2
                 = m^3 / sec^2 kg

        The conversion factor, therefore, between the SI gravitational
        constant and its equivalent in our units is:

               K = AU^3 / YEAR^2 M_SUN

    */

    float GRAV_CONV;                    // ((AU * AU * AU) / ((YEAR * YEAR) * M_SUN))

    /*  And finally the gravitational constant itself is obtained by
        dividing the SI definition by this conversion factor.  */

    float GRAVCON;                      // (G_SI / GRAV_CONV)

    //  Settings communicated by deployer
    float s_kaboom = 50;                // Self destruct if this far (AU) from deployer
    float s_auscale = 0.3;              // Astronomical unit scale
    float s_radscale = 0.0000025;       // Radius scale
    integer s_trails = FALSE;           // Show trails with temporary prims
    float s_pwidth = 0.01;              // Paths/trails width
    float s_mindist = 0.01;             // Minimum distance to update
    integer s_labels = FALSE;           // Show labels on objects
    //  These settings are not sent to the masses
    float s_deltat = 0.01;              // Integration time step
    float s_zoffset = 1;                // Z offset to create masses
    integer s_legend = FALSE;           // Display legend above deployer
    float s_simRate = 1;                // Simulation rate (years/second)
    float s_stepRate = 0.1;             // Integration step rate (years/step)
    integer s_eclipshown = FALSE;       // Showing the ecliptic
    float s_eclipsize = 30;             // Radius of ecliptic plane
    integer s_realtime = FALSE;         // Display solar system in real time
    float s_realstep = 30;              // Real time update interval, seconds
    integer s_trace = FALSE;            // Trace mass behaviour
    integer paths = FALSE;              // Show particle trails from mass ?

    list simEpoch;                      // Epoch of simulation

    //  Link messages

    //  Command processor messages
    integer LM_CP_COMMAND = 223;    // Process command
    integer LM_CP_RESUME = 225;         // Resume script after command
    integer LM_CP_REMOVE = 226;         // Remove simulation objects

    //  Auxiliary services messages

    integer LM_AS_SETTINGS = 542;       // Update settings

    //  Orbit messages

    integer LM_OR_PLOT = 601;           // Plot orbit for body
    integer LM_OR_ELLIPSE = 602;        // Fit ellipse to body
    integer LM_OR_ELEMENTS = 603;       // Orbital elements for ellipse object
    integer LM_OR_DRAW = 605;           // Draw a line of an orbit

    //  Galactic centre messages

    integer LM_GC_UPDATE = 751;         // Update positions for Julian day
    integer LM_GC_SOURCES = 752;        // Report number of sources

    //  Galactic patrol messages

    integer LM_GP_UPDATE = 771;         // Update positions for Julian day
    integer LM_GP_STAT = 773;           // Report statistics
    integer LM_GP_CENTRE = 774;         // Central mass properties
    integer LM_GP_SOURCE = 775;         // Orbiting source properties

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

    /*  fuis  --  Float union to base64-encoded integer
                  Designed and implemented by Strife Onizuka:
                    http://wiki.secondlife.com/wiki/User:Strife_Onizuka/Float_Functions  */
/*
    string fuis(float a) {
        integer b = 0x80000000 & ~llSubStringIndex(llList2CSV([a]), "-");   // Sign
        if ((a)) {      // Is it greater than or less than zero?
            if ((a = llFabs(a)) < 2.3509887016445750159374730744445e-38) {  // Denormalized range check & last stride of normalized range
                b = b | (integer)(a / 1.4012984643248170709237295832899e-45);   // Math overlaps; saves cpu time.
            } else if(a > 3.4028234663852885981170418348452e+38) {          // Round up to infinity
                b = b | 0x7F800000;                                         // Positive or negative infinity
            } else if (a > 1.4012984643248170709237295832899e-45) {         // It should at this point, except if it's NaN
                integer c = ~-llFloor(llLog(a) * 1.4426950408889634073599246810019);    // Extremes will error towards extremes. The following corrects it
                b = b | (0x7FFFFF & (integer)(a * (0x1000000 >> c))) | ((126 + (c = ((integer)a - (3 <= (a *= llPow(2, -c))))) + c) * 0x800000);
                // The previous requires a lot of unwinding to understand it.
            } else {
                b = b | 0x7FC00000;//NaN time! We have no way to tell NaN's apart so lets just choose one.
            }
        }//for grins, detect the sign on zero. it's not pretty but it works.
        return llGetSubString(llIntegerToBase64(b), 0, 5);
    }
*/

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
                     are the eccentricity (e), time since periapse (t),
                     distance at periapse (q), and the Gaussian
                     gravitational constant (GM) for the central
                     body.  A list is returned
                     containing the true anomaly v (radians) and
                     the radius vector to the central body r (AU).  */

    list gKepler(float e, float t, float q, float K) {
//tawk("gKepler e " + (string) e + "  t " + (string) t + "  q " + (string) q + " K " + (string) K);
        float f;
        float x;
        float d;
        float m1;
        integer i;

        float v;
        float r;

        /*  We employ two different algorithms, each optimised for
            a particular range of eccentricities.  For hyperbolic
            orbits with eccentricity greater than 1.0, we use a
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
            2nd ed.  We use this for all eccentricities less than or equal to 1.  */

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

    /*  computeOrbit  --  Compute heliocentric rectangular co-ordinates
                          of object from orbital elements.  */

    vector computeOrbit(list elements, list jdl) {
        float e = 0;
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
                         llList2Float(elements, 13), llSqrt(mCentre) * 0.01720209895);
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

    //  fixangr  --  Range reduce an angle in radians

    float fixangr(float a) {
        return a - (TWO_PI * (llFloor(a / TWO_PI)));
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
        list m_Epoch = [ 0, 0.0 ];  // Epoch (JD)
        float m_a = NaN;            // Semi-major axis, AU
        float m_e = NaN;            // Eccentricity
        float m_i = NaN;            // Inclination, degrees
        float m_peri = NaN;         // Argument of periapse, degrees
        float m_node = NaN;         // Longitude of ascending node, degrees
        float m_M = NaN;            // Mean anomaly, degreees
        float m_H = NaN;            // Magnitude
        float m_G = NaN;            // Magnitude slope

        float m_q = NaN;            // Periapse distance, AU
        list m_Tp = [ 0, 0.0 ];     // Time of periapse, JD
        float m_n = NaN;            // Mean motion, degrees/day
        float m_P = NaN;            // Orbital period, days
        float m_Q = NaN;            // Apoapse distance, AU

        for (i = 2; i < argn; i += 2) {
            string var = llList2String(args, i);
            float val = NaN;
            if ((i + 1) < argn) {
                val = llList2Float(args, i + 1);
            }
//tawk("arg " + (string) i + "  var " + var + "  val " + (string) val);
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

        /*  Compute mean motion.  We compute motion in the
            gravitational field of the central mass according
            to Newton's gravitational law.  Other orbiting
            masses are ignored as their masses are unknown and
            are negligible compared to the central mass.
            The apoapse distance is computed from the semi-major
            axis and eccentricity and is, of course, only defined
            for elliptical orbits.  */
        if (m_e < 1) {
            float GM = mCentre * GRAVCON;
            m_n = llSqrt(GM) / (m_a * llSqrt(m_a));
            m_P = TWO_PI / m_n;
            m_Q = (1 + m_e) * m_a;
        } else if (m_e > 1) {
            float GM = mCentre * GRAVCON;
            //  This is how JPL computes it for objects in hyperbolic orbits
            m_n = llSqrt(GM) / ((-m_a) * llSqrt(-m_a));
        }

        /*  If mean anomaly was not specified, and we know
            the mean motion and date of perihelion, compute it.  */

        if ((!spec(m_M)) && (m_Tp != [ ]) && spec(m_n)) {
            float deltat = (llList2Integer(m_Epoch, 0) - llList2Integer(m_Tp, 0)) +
                           (llList2Float(m_Epoch, 1) - llList2Float(m_Tp, 1));
            m_M = fixangr(m_n * deltat) * RAD_TO_DEG;
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

    //  posMP  --  Compute position of currently-tracked source

    list posMP(integer src, integer jd, float jdf) {
src--;
s_elem = llList2List(s_sources, src * s_sourcesE, ((src + 1) * s_sourcesE) - 1);
        vector pos = computeOrbit(s_elem, [ jd, jdf ]);
        return [ pos.x, pos.y, pos.z ];
    }
/*
    //  dumpOrbitalElements  --  Dump orbital elements

    dumpOrbitalElements(list e) {
        tawk(llList2String(e, 0) + "\n" +
            "  a " + (string) llList2Float(e, 3) + "\n" +
            "  e " + (string) llList2Float(e, 4) + "\n" +
            "  i " + (string) llList2Float(e, 5) + "\n" +
            "  ῶ " + (string) llList2Float(e, 6) + "\n" +
            "  Ω " + (string) llList2Float(e, 7) + "\n" +
            "  M " + (string) llList2Float(e, 8) + "\n" +
            "  H " + (string) llList2Float(e, 9) + "\n" +
            "  G " + (string) llList2Float(e, 10) + "\n" +
            "  Tp " + editJDtoDec(llList2List(e, 11, 12)) + "\n" +
            "  q " + (string) llList2Float(e, 13) + "\n" +
            "  n " + (string) llList2Float(e, 14) + "\n" +
            "  P " + (string) llList2Float(e, 15) + "\n" +
            "  Q " + (string) llList2Float(e, 16)
        );
    }

    //  editJDtoDec  --  Edit a Julian date pair list to a decimal Julian date

    string editJDtoDec(list jd) {
        string textjd = (string) llList2Float(jd, 0) + " " + (string) llList2Float(jd, 1);
        list ljd = llParseString2List(textjd, [".", " "], [" "]);
        textjd = llList2String(ljd, 0) + "." + llList2String(ljd, 3);

        return textjd;
    }
*/
    /*  sendSettings  --  Send settings to mass(es).  If mass is
                          nonzero, the message is directed to
                          that specific mass.  If zero, it is
                          a broadcast to all masses, and the id
                          argument is ignored.  */

    sendSettings(key id, integer mass) {
        string msg = llList2Json(JSON_ARRAY, [ "SETTINGS", mass,
                            paths,
                            s_trace,
                            s_kaboom,
                            s_auscale,
                            s_radscale,
                            s_trails,
                            s_pwidth,
                            s_mindist
                      ]);
        if (mass == 0) {
            llRegionSay(massChannel, msg);
        } else {
            llRegionSayTo(id, massChannel, msg);
        }
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
        string lmessage = llToLower(message);
        args = llParseString2List(lmessage, [ " " ], []);   // Command and arguments
        integer argn = llGetListLength(args);       // Number of arguments
        string command = llList2String(args, 0);    // The command
//        string sparam = llList2String(args, 1);     // First argument, for convenience

        //  Centre              Define central mass

        if (abbrP(command, "ce")) {
            nCentres++;
            //  Clear any previous lists of sources
            source_keys = [ ];
            s_sources = [ ];
            //  Re-process arguments to preserve case
            args = fixQuotes(llParseString2List(message, [ " " ], []));
            nCentre = llList2String(args, 1);
            mCentre = llList2Float(args, 3);
            vector eggPos = llGetPos();
            llRezObject("Source", eggPos + <0, 0, s_zoffset>, ZERO_VECTOR,
                llEuler2Rot(<PI_BY_TWO, 0, 0>),
                -1);
            llMessageLinked(LINK_THIS, LM_GC_SOURCES,
                (string) (nCentres + llGetListLength(source_keys)), whoDat);

        //  Source

        } else if (abbrP(command, "so")) {
            list e = parseOrbitalElements(message);
            s_sources += e;
//dumpOrbitalElements(e);
            source_keys += NULL_KEY;        // Reserve space for key
            integer massn = llGetListLength(source_keys);
            vector eggPos = llGetPos();
//            vector where = eggPos + < massn * 0.25, 0, s_zoffset >;
            list p = posMP(massn, llList2Integer(simEpoch, 0), llList2Float(simEpoch, 1));
            vector pos = < llList2Float(p, 0), llList2Float(p, 1), llList2Float(p, 2) >;
            vector rwhere = (pos * s_auscale) + (llGetPos() + <0, 0, s_zoffset>);
            llSetRegionPos(rwhere);
            llRezObject("Source", rwhere, ZERO_VECTOR,
                llEuler2Rot(<PI_BY_TWO, 0, 0>),
                massn);
            llSetRegionPos(eggPos);
            llMessageLinked(LINK_THIS, LM_GC_SOURCES,
                (string) (nCentres + llGetListLength(source_keys)), whoDat);

        //  Status

        } else if (abbrP(command, "sta")) {
            string s = llGetScriptName() + " status:\n";

            integer mFree = llGetFreeMemory();
            integer mUsed = llGetUsedMemory();
            s += "  Script memory.  Free: " + (string) mFree +
                    "  Used: " + (string) mUsed + " (" +
                    (string) ((integer) llRound((mUsed * 100.0) / (mUsed + mFree))) + "%)";
            tawk(s);
        }
        return TRUE;
    }

/*
    //  sumJD  --  Compute sum of Julian date list with float duration

    list sumJD(list jd, float dur) {
        integer ajd = llList2Integer(jd, 0);    // Full days...
        float ajdf = llList2Float(jd, 1);       // ...and day fraction
        integer duri = llFloor(dur);
        dur -= duri;
        ajd += duri;
        ajdf += dur;
        integer ajdfi = llFloor(ajdf);
        ajd += ajdfi;
        ajdf -= ajdfi;
        return [ ajd, ajdf ];
    }
*/

/*
    //  plotSeg  --  Plot a segment of an orbit

    integer flPlotPerm;                 // Plot with permanent objects ?

    plotSeg(vector from, vector to, float sunposZ) {
        float meanZ = ((from.z - sunposZ) +
            (to.z - sunposZ)) / 2;
        vector segcol = <0, 0.75, 0>;
        if (meanZ < 0) {
            segcol = <0.75, 0, 0>;
        }
        llMessageLinked(LINK_THIS, LM_OR_DRAW,
            llList2CSV([ from, to, segcol, 0.01, flPlotPerm ]), whoDat);
    }

    //  elKaboom  --  Determine if a source has moved out of range or region

    integer elKaboom(vector rwhere, vector deployerPos) {
        //  Test if it's beyond our "Set kaboom" range
        if ((s_kaboom > 0) &&
            ((llVecDist(deployerPos, rwhere) / s_auscale) > s_kaboom)) {
            return TRUE;
        }
        //  Is object about to move outside the region ?
        return (rwhere.x < 0) || (rwhere.x >= REGION_SIZE) ||
               (rwhere.y < 0) || (rwhere.y >= REGION_SIZE) ||
               (rwhere.z < 0) || (rwhere.z >= 4096);
    }
*/

//    integer BODY = 24;                  // Our body number

    default {

        on_rez(integer n) {
            llResetScript();
        }

        state_entry() {
            whoDat = owner = llGetOwner();

            //  Initialise computed constants
            GRAV_CONV = ((AU * AU * AU) / ((YEAR * YEAR) * M_SUN));
            GRAVCON = G_SI / GRAV_CONV;

            llListen(massChannel, "", NULL_KEY, "");
        }

        /*  The link_message() event receives commands from other scripts
            script and passes them on to the script processing functions
            within this script.  */

        link_message(integer sender, integer num, string str, key id) {
//tawk(llGetScriptName() + " link message sender " + (string) sender + "  num " + (string) num + "  str " + str + "  id " + (string) id);

            //  LM_CP_COMMAND (223): Process auxiliary command

            if (num == LM_CP_COMMAND) {
                processAuxCommand(id, llJson2List(str));

            //  LM_CP_REMOVE (226): Remove simulation objects

            } else if (num == LM_CP_REMOVE) {
                s_sources = [ ];            // Orbital elements of sources
                source_keys = [ ];          // Keys of deployed sources
                nCentres = 0;               // Number of central bodies

            //  LM_AS_SETTINGS (542): Update settings from main script

            } else if (num == LM_AS_SETTINGS) {
                list msg = llJson2List(str);

                paths = llList2Integer(msg, 2);
                s_trace = llList2Integer(msg, 3);
                s_kaboom = (float) llList2String(msg, 4);
                s_auscale = (float) llList2String(msg, 5);
                s_radscale = (float) llList2String(msg, 6);
                s_trails = llList2Integer(msg, 7);
                s_pwidth = (float) llList2String(msg, 8);
                s_mindist = (float) llList2String(msg, 9);
                s_deltat = (float) llList2String(msg, 10);
                s_eclipshown = llList2Integer(msg, 11);
                s_eclipsize = (float) llList2String(msg, 12);
                s_realtime = llList2Integer(msg, 13);
                s_realstep = (float) llList2String(msg, 14);
                s_simRate = (float) llList2String(msg, 15);
                s_stepRate = (float) llList2String(msg, 16);
                s_zoffset = (float) llList2String(msg, 17);
                s_legend = llList2Integer(msg, 18);
                simEpoch = llList2List(msg, 19, 20);
                s_labels = llList2Integer(msg, 21);

/*
            //  LM_OR_PLOT (601): Plot orbit

            } else if (num == LM_OR_PLOT) {
                if (s_sources != [ ]) {
                    list l = llCSV2List(str);
                    integer i;
                    integer k = 1;
                    integer n = llGetListLength(s_sources);
                    string body = llList2String(l, 0);
                    s_elem = [ ];
                    for (i = 0; i < n; i += s_sourcesE, k++) {
                        if (llToLower(llList2String(s_sources, i)) == body) {
                            s_elem = llList2List(s_sources, i, i + (s_sourcesE - 1));
                            jump foundOrb;
                        }
                    }
                    @foundOrb;

                    if (s_elem != [ ]) {
                        integer o_parahyper = llList2Float(s_elem, 4) >= 1;
                        integer o_jd;
                        float o_jdf;
                        integer o_arm;
                        if (!o_parahyper) {
                            o_jd = llList2Integer(l, 1);        // Julian day
                            o_jdf = llList2Float(l, 2);         // Julian day fraction
                        } else {
                            /*  If the orbit is parabolic or hyperbolic,
                                commence plotting at the periapse.  *_/
                            o_jd = llList2Integer(s_elem, 11);
                            o_jdf = llList2Float(s_elem, 12);
                            o_arm = 0;                      // Start on positive time arm
                        }
                        float o_auscale = llList2Float(l, 3);     // Astronomical unit scale factor
                        float o_nsegments = llList2Integer(l, 4); // Number of segments to plot
                        vector o_sunpos = (vector) llList2String(l, 5); // Position of Sun
                        integer flPlotPerm = llList2Integer(l, 6);  // Use permanent lines ?

                        integer o_csegment = 0;                     // Current segment being plotted
                        float o_period = llList2Float(s_elem, 15) * 365.25;
                        float o_timestep;
                        float o_aulimit = llList2Float(s_elem, 13) * 5; // Limit to plot open trajectories
                        if (o_parahyper) {
//  HACK--THIS SHOULD BE BASED ON ECCENTRICITY SOMEHOW
                            o_timestep = (5 * 365) / o_nsegments;
                        } else {
                            o_timestep = o_period / o_nsegments;
                        }
                        vector pXYZ0;
                        vector pXYZl;
                        for (i = 0; i < o_nsegments; i++) {
                            list orbXYZ =  posMP(k, o_jd, o_jdf);
                            vector wXYZ = < llList2Float(orbXYZ, 0),
                                            llList2Float(orbXYZ, 1),
                                            llList2Float(orbXYZ, 2) >;
                            vector pXYZr = (wXYZ * o_auscale) + o_sunpos;
                            if (i == 0) {
                                pXYZ0 = pXYZr;
                            } else {
                                plotSeg(pXYZl, pXYZr, o_sunpos.z);
                                llSleep(0.15);
                            }
                            pXYZl = pXYZr;
                            list ijd = sumJD([ o_jd, o_jdf ], o_timestep);
                            o_jd = llList2Integer(ijd, 0);
                            o_jdf = llList2Integer(ijd, 1);

                            if (o_parahyper &&
                                (((llVecDist(pXYZl, o_sunpos) / o_auscale) > o_aulimit) ||
                                 (i > (o_nsegments - 1)))) {
                                if (o_arm > 0) {
                                    llMessageLinked(LINK_THIS, LM_CP_RESUME, "", id);
                                    return;
                                } else {
                                    o_arm++;
                                    //  Restart to draw incoming arm
                                    o_jd = llList2Integer(s_elem, 11);
                                    o_jdf = llList2Float(s_elem, 12);
                                    i = -1;     // Because bottom of loop will increment
                                    o_timestep = -o_timestep;
                                }
                            }
                            plotSeg(pXYZl, pXYZ0, o_sunpos.z);
                         }
                    }
                    llMessageLinked(LINK_THIS, LM_CP_RESUME, "", id);
                }

            //  LM_OR_ELLIPSE (602): Plot orbit ellipse

            } else if (num == LM_OR_ELLIPSE) {
                if (s_sources != [ ]) {
                    list l = llCSV2List(str);
                    integer i;
                    integer k = 1;
                    integer n = llGetListLength(s_sources);
                    string body = llList2String(l, 0);
                    s_elem = [ ];
                    for (i = 0; i < n; i += s_sourcesE, k++) {
                        if (llToLower(llList2String(s_sources, i)) == body) {
                            s_elem = llList2List(s_sources, i, i + (s_sourcesE - 1));
                            jump foundIt;
                        }
                    }
                    @foundIt;
//tawk("Ellipse " + body + "  elem " + llList2CSV(s_elem));
                    /*  We can only display an ellipse if an object is being
                        tracked and its eccentricity is less than 1.  *_/
                    if ((s_elem != [ ]) &&
                        (llList2Float(s_elem, 4) < 1)) {
                        integer o_jd = llList2Integer(l, 1);            // Julian day
                        float o_jdf = llList2Float(l, 2);               // Julian day fraction
                        float o_auscale = llList2Float(l, 3);           // Astronomical unit scale factor
                        vector o_sunpos = (vector) llList2String(l, 4); // Position of Sun
                        float pdays = llList2Float(s_elem, 15) * 365.25; // Orbital period in days

                        //  Compute the location of the periapse

                        list periXYZ =  posMP(k,llList2Integer(s_elem, 11),
                                                llList2Float(s_elem, 12));
                        vector wXYZ = < llList2Float(periXYZ, 0),
                                        llList2Float(periXYZ, 1),
                                        llList2Float(periXYZ, 2) >;
                        vector pXYZr = (wXYZ * o_auscale) + o_sunpos;
//tawk("Periapse location: " + (string) pXYZr);

                        //  Compute the location of the apoapse

                        list pjd = sumJD(llList2List(s_elem, 11, 12),
                                         pdays / 2);
                        list apoXYZ = posMP(k, llList2Integer(pjd, 0),
                                               llList2Float(pjd, 1));
                        wXYZ = < llList2Float(apoXYZ, 0),
                                 llList2Float(apoXYZ, 1),
                                 llList2Float(apoXYZ, 2) >;
                        vector aXYZr = (wXYZ * o_auscale) + o_sunpos;
//tawk("Apoapse location: " + (string) aXYZr);

                        //  Compute the location of a co-vertex of the ellipse

                        list cjd = sumJD(llList2List(s_elem, 11, 12),
                                            pdays *
                                            (0.25 - (llList2Float(s_elem, 4) / TWO_PI)));
                        list cvxLBR = posMP(k, llList2Integer(cjd, 0),
                                               llList2Float(cjd, 1));
                        wXYZ = < llList2Float(cvxLBR, 0),
                                 llList2Float(cvxLBR, 1),
                                 llList2Float(cvxLBR, 2) >;
                        vector cXYZr = (wXYZ * o_auscale) + o_sunpos;
//tawk("Co-vertex location: " + (string) aXYZr);

                        /*  Compose and send a LM_OR_ELEMENTS message to the
                            Orbits module with "just the facts" needed for it
                            to configure an "Orbit ellipse" object to represent
                            the orbit.  *_/

                        llMessageLinked(LINK_THIS, LM_OR_ELEMENTS,
                            llList2Json(JSON_ARRAY, [
                                k,                          // 0    Body number
                                llList2String(s_elem, 0),   // 1    Body name
                                pXYZr,                      // 2    Periapse location
                                aXYZr,                      // 3    Apoapse location
                                llList2Float(s_elem, 3),    // 4    Semi-major axis
                                llList2Float(s_elem, 4),    // 5    Eccentricity
                                o_auscale,                  // 6    Astronomical unit scale factor
                                cXYZr                       // 7    Co-vertex location
                            ]), whoDat);
                    }

                }
*/

/*
            //  LM_GC_UPDATE (751):  Update positions for Julian day

            } else if (num == LM_GC_UPDATE) {
                list d = llCSV2List(str);
                integer jd = llList2Integer(d, 0);
                float jdf = llList2Float(d, 1);
                vector deployerPos = llGetPos() + <0, 0, s_zoffset>;

                integer i;
                integer n = llGetListLength(source_keys);
                string upbulk = "U:";
                integer upbulkL = 2;

//tawk("n = " + (string) n + " keys " + llList2CSV(source_keys));

                for (i = 1; i <= n; i++) {
                    key k = llList2Key(source_keys, i - 1);
                    if (k != NULL_KEY) {
                        list p = posMP(i, jd, jdf);
                        vector pos = < llList2Float(p, 0), llList2Float(p, 1), llList2Float(p, 2) >;
                        vector rwhere = (pos * s_auscale) + deployerPos;
                        if (elKaboom(rwhere, deployerPos)) {
                            //  Source out of range: destroy and remove from list
                            llRegionSayTo(k, massChannel,
                                llList2Json(JSON_ARRAY, [ "KABOOM", i ]));
                            source_keys = llListReplaceList(source_keys,
                                [ NULL_KEY ], i - 1, i - 1);
tawk("Source " + (string) i + " " + llList2String(s_sources, i * s_sourcesE) + ": Kaboom!  " +
    "rwhere " + (string) rwhere + " s_auscale " + (string) s_auscale + " dpos " + (string) deployerPos +
    "\n  " + llList2CSV(source_keys));
                        } else {
                            string upsource = "{" + (string) i + "}" +
                                fuis(rwhere.x) + fuis(rwhere.y) + fuis(rwhere.z);
                            integer usL = llStringLength(upsource);
                            if ((upbulkL + usL) > 1024) {
                                llRegionSay(massChannel, upbulk);
                                upbulk = "U:";
                                upbulkL = 2;
                            }
                            upbulk += upsource;
                            upbulkL += usL;
                        }
                    }
                }
                llRegionSay(massChannel, "V" + llGetSubString(upbulk, 1, -1));
//tawk("V" + llGetSubString(upbulk, 1, -1));
*/
            }
        }

        //  The listen event handles messages from objects we create

        listen(integer channel, string name, key id, string message) {
//llOwnerSay(llGetScriptName() + " channel " + (string) channel + " id " + (string) id +  " message " + message);
            if (channel == massChannel) {
                list msg = llJson2List(message);
                string ccmd = llList2String(msg, 0);

                /*  When deployed and its script starts to run, each
                    source sends us a SOURCED message with its source number
                    and key.  This allows us to send it an INIT message
                    containing, encoded in JSON, the parameters with
                    which it should initialise itself.  */

                if (ccmd == "SOURCED") {
                    integer mass_number = llList2Integer(msg, 1);
                    vector eggPos = llGetPos() + <0, 0, s_zoffset>;
                    if (mass_number == -1) {
                        kCentre = id;
                        llRegionSayTo(id, massChannel,
                            llList2Json(JSON_ARRAY, [ "INIT", mass_number,
                            nCentre,                        // Name of body
                            eggPos,                         // Initial position
                            ZERO_VECTOR,                    // Initial velocity
                            mCentre,                        // Mass
                            "<0.15, 0.15, 0.15, 1, 0.2>",   // Colour (extended)
                            75000,                          // Mean radius
                            eggPos                          // Deployer position
                        ]));
                        //  Inform the Galactic Patrol of the new central mass
                        llMessageLinked(LINK_THIS, LM_GP_CENTRE,
                            llList2Json(JSON_ARRAY, [
                                mass_number,                // Mass index
                                kCentre,                    // Central mass key
                                nCentre,                    // Name of body
                                mCentre,                    // Mass
                                eggPos                      // Initial position
                            ]), whoDat);
                    } else {
                        integer mindex = mass_number - 1;
                        //  Save key of mass object in source_keys
                        source_keys = llListReplaceList(source_keys, [ id ],
                            mindex, mindex);

                        integer sindex = mindex * s_sourcesE;
                        integer ncols = llGetListLength(colours) - 1;
                        string colour = (string) llList2Vector(colours,
                            (mindex % ncols) + 1);
                        llRegionSayTo(id, massChannel,
                            llList2Json(JSON_ARRAY, [ "INIT", mass_number,
                            llList2String(s_sources, sindex),       // Name of body
                            eggPos + < mass_number * 0.25, 0, 0 >,  // Initial position
                            ZERO_VECTOR,                            // Initial velocity
                            1,                                      // Mass
                            colour,                                 // Colour (extended)
                            25000,                                  // Mean radius
                            eggPos                                  // Deployer position
                        ]));
                        //  Inform the Galactic Patrol of the new orbiting source
                        llMessageLinked(LINK_THIS, LM_GP_SOURCE,
                            llList2Json(JSON_ARRAY, [
                                mass_number,                        // Source index
                                id ] +                              // Source key
                                llList2List(s_sources, mindex * s_sourcesE,
                                    ((mindex + 1) * s_sourcesE) - 1)
                            ), whoDat);
                    }

                    //  Send initial settings
                    sendSettings(id, mass_number);
                    //  Resume deployer script, if suspended
                    llMessageLinked(LINK_THIS, LM_CP_RESUME, "", whoDat);
                }
            }
        }
    }