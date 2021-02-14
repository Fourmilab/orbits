    /*

                            Fourmilab Orbits

                             Galactic Patrol

        This script manages the evolution of a model of objects near
        the galactic centre which have been created by commands
        processed by the Galactic Centre script.  That script send
        us the definitions of object and we handle updating the model
        from their orbital elements.

        This is split out, with all of the added complexity that creates,
        purely due to LSL's 64 Kb script memory limit.

    */

    key owner;                      // Owner UUID
    key whoDat = NULL_KEY;          // Avatar who sent command

    integer massChannel = -982449822;   // Channel for communicating with sources
    float REGION_SIZE = 256;        // Second Life grid region size, metres

    list s_elem = [ ];              // Elements of sources
    list s_sources = [ ];           // Orbital elements of sources
    integer s_sourcesE = 17;        // Size of sources list entry
    list source_keys = [ ];         // Keys of deployed sources

    integer nCentres = 0;           // Number of central bodies
    string nCentre;                 // Name of central body
    float mCentre;                  // Central body mass (solar masses)
    key kCentre;                    // Key of central body

    float M_E = 2.718281828459045;  // Base of the natural logarithms

    //  Settings communicated by deployer
    float s_kaboom = 50;                // Self destruct if this far (AU) from deployer
    float s_auscale = 0.3;              // Astronomical unit scale
    integer s_labels = FALSE;           // Show labels on objects
    //  These settings are not sent to the masses
    float s_zoffset = 1;                // Z offset to create masses
    integer s_legend = FALSE;           // Display legend above deployer

    list simEpoch;                      // Epoch of simulation

    //  Link messages

    //  Command processor messages

    integer LM_CP_REMOVE = 226;         // Remove simulation objects

    //  Ephemeris calculation messages

    integer LM_EP_CALC = 431;           // Calculate ephemeris
    integer LM_EP_RESULT = 432;         // Ephemeris calculation result

    //  Auxiliary services messages

    integer LM_AS_SETTINGS = 542;       // Update settings

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

    string fuis(float a) {
        //  Detect the sign on zero.  It's ugly, but it gets you there
        //  integer b = 0x80000000 & ~llSubStringIndex(llList2CSV([a]), "-");   // Sign
        /*  Test for negative number, ignoring the difference between
            +0 and -0.  While this does not preserve floating point
            numbers bit-for-bit, it doesn't make any difference in
            our calculations and is almost three times faster than
            the original code above.  */
        integer b = 0;
        if (a < 0) {
            b = 0x80000000;
        }

        if (a) {        // Is it greater than or less than zero ?
            //  Denormalized range check and last stride of normalized range
            if ((a = llFabs(a)) < 2.3509887016445750159374730744445e-38) {
                b = b | (integer) (a / 1.4012984643248170709237295832899e-45);   // Math overlaps; saves CPU time
            //  We never need to transmit infinity, so save the time testing for it.
            // } else if (a > 3.4028234663852885981170418348452e+38) { // Round up to infinity
            //     b = b | 0x7F800000;                                 // Positive or negative infinity
            } else if (a > 1.4012984643248170709237295832899e-45) { // It should at this point, except if it's NaN
                integer c = ~-llFloor(llLog(a) * 1.4426950408889634073599246810019);
                //  Extremes will error towards extremes. The following corrects it
                b = b | (0x7FFFFF & (integer) (a * (0x1000000 >> c))) |
                        ((126 + (c = ((integer) a - (3 <= (a *= llPow(2, -c))))) + c) * 0x800000);
                //  The previous requires a lot of unwinding to understand
            } else {
                //  NaN time!  We have no way to tell NaNs apart so pick one arbitrarily
                b = b | 0x7FC00000;
            }
        }

        return llGetSubString(llIntegerToBase64(b), 0, 5);
    }

    /*  siuf  --  Base64 encoded integer to float
                  Designed and implemented by Strife Onizuka:
                    http://wiki.secondlife.com/wiki/User:Strife_Onizuka/Float_Functions  */

    float siuf(string b) {
        integer a = llBase64ToInteger(b);
        if (0x7F800000 & ~a) {
            return llPow(2, (a | !a) + 0xffffff6a) *
                      (((!!(a = (0xff & (a >> 23)))) * 0x800000) |
                       (a & 0x7fffff)) * (1 | (a >> 31));
        }
        return (!(a & 0x7FFFFF)) * (float) "inf" * ((a >> 31) | 1);
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
                     are the eccentricity (e), time since periapse (t),
                     distance at periapse (q), and the Gaussian
                     gravitational constant (GM) for the central
                     body.  A list is returned containing the
                     true anomaly v (radians) and the radius
                     vector to the central body r (AU).  */

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

    //  posGS  --  Compute position of currently-tracked source

    list posGS(integer src, integer jd, float jdf) {
        src--;
        s_elem = llList2List(s_sources, src * s_sourcesE, ((src + 1) * s_sourcesE) - 1);
        vector pos = computeOrbit(s_elem, [ jd, jdf ]);
        return [ pos.x, pos.y, pos.z ];
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

    default {

        on_rez(integer n) {
            llResetScript();
        }

        state_entry() {
            whoDat = owner = llGetOwner();

            llListen(massChannel, "", NULL_KEY, "");
        }

        /*  The link_message() event receives commands from other scripts
            script and passes them on to the script processing functions
            within this script.  */

        link_message(integer sender, integer num, string str, key id) {
//tawk(llGetScriptName() + " link message sender " + (string) sender + "  num " + (string) num + "  str " + str + "  id " + (string) id);

            //  LM_CP_REMOVE (226): Remove simulation objects

            if (num == LM_CP_REMOVE) {
                s_sources = [ ];            // Orbital elements of sources
                source_keys = [ ];          // Keys of deployed sources
                nCentres = 0;               // Number of central bodies

            //  LM_EP_CALC (431): Calculate ephemeris

            } else if (num == LM_EP_CALC) {
                if (s_sources != [ ]) {
                    list args = llCSV2List(str);
                    integer argn = llGetListLength(args);
                    integer body = llList2Integer(args, 0);
                    integer body_k = (body >> 16) - 1;
                    integer i = body_k * s_sourcesE;
                    if ((i >= 0) && (i < llGetListLength(s_sources))) {
                        s_elem = llList2List(s_sources, i, i + (s_sourcesE - 1));
                        list eph = [ ];

                        for (i = 1; (i + 1) < argn; i += 2) {
                            eph += posGS(body_k + 1, llList2Integer(args, i),
                                                     llList2Float(args, i + 1));
                        }
                        integer handle = llList2Integer(args, i);
                        llMessageLinked(LINK_THIS, LM_EP_RESULT,
                            (string) body + "," +
                            llList2CSV(eph + [ handle ]), id);
                    }
                }

            //  LM_AS_SETTINGS (542): Update settings from main script

            } else if (num == LM_AS_SETTINGS) {
                list msg = llJson2List(str);

                /*  We only decode settings in which we're interested
                    or wish to pass on to masses we've created.  */
                s_kaboom = siuf(llList2String(msg, 4));
                s_auscale = siuf(llList2String(msg, 5));
                s_zoffset = siuf(llList2String(msg, 17));
                s_legend = llList2Integer(msg, 18);
                simEpoch = llList2List(msg, 19, 20);
                s_labels = llList2Integer(msg, 21);

            //  LM_GP_UPDATE (771):  Update positions for Julian day

            } else if (num == LM_GP_UPDATE) {
                list d = llCSV2List(str);
                integer jd = llList2Integer(d, 0);
                float jdf = llList2Float(d, 1);
                vector deployerPos = llGetPos() + <0, 0, s_zoffset>;

                integer i;
                integer n = llGetListLength(source_keys);
                string upbulk = "U:";
                integer upbulkL = 2;

                for (i = 1; i <= n; i++) {
                    key k = llList2Key(source_keys, i - 1);
                    if (k != NULL_KEY) {
                        list p = posGS(i, jd, jdf);
                        vector pos = < llList2Float(p, 0), llList2Float(p, 1), llList2Float(p, 2) >;
                        vector rwhere = (pos * s_auscale) + deployerPos;
                        if (elKaboom(rwhere, deployerPos)) {
                            //  Source out of range: destroy and remove from list
                            llRegionSayTo(k, massChannel,
                                llList2Json(JSON_ARRAY, [ "KABOOM", i ]));
                            source_keys = llListReplaceList(source_keys,
                                [ NULL_KEY ], i - 1, i - 1);
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

            //  LM_GP_CENTRE (774): Define new central mass

            } else if (num == LM_GP_CENTRE) {
                list l = llJson2List(str);

                kCentre = llList2Key(l, 1);
                nCentre = llList2String(l, 2);
                mCentre = llList2Float(l, 3);
                // vector eggPos = (vector) llList2String(l, 4);
                nCentres = 1;
                //  Clear any previous lists of sources
                source_keys = [ ];
                s_sources = [ ];

            //  LM_GP_SOURCE (775): Define new orbiting source

            } else if (num == LM_GP_SOURCE) {
                list l = llJson2List(str);
                integer sindex = llList2Integer(l, 0);          // Source index
                key skey = llList2Key(l, 1);                    // Source key
                source_keys += skey;
                integer epochJD = llList2Integer(l, 2);         // Epoch Julian day and fraction
                float epochJDf = llList2Float(l, 3);
                s_sources += llList2List(l, 4, -1);             // Source parameters
                list p = posGS(sindex, epochJD, epochJDf);
                vector pos = < llList2Float(p, 0), llList2Float(p, 1), llList2Float(p, 2) >;
                vector rwhere = (pos * s_auscale) + llGetPos() + <0, 0, s_zoffset>;
                llRegionSayTo(skey, massChannel, "U:{" + (string) sindex + "}" +
                    fuis(rwhere.x) + fuis(rwhere.y) + fuis(rwhere.z));

            //  LM_GP_STAT (773): Report status

            } else if (num == LM_GP_STAT) {
                string s = llGetScriptName() + " status:\n";

                integer mFree = llGetFreeMemory();
                integer mUsed = llGetUsedMemory();
                s += "  Script memory.  Free: " + (string) mFree +
                        "  Used: " + (string) mUsed + " (" +
                        (string) ((integer) llRound((mUsed * 100.0) / (mUsed + mFree))) + "%)";
                tawk(s);
            }
        }
    }
