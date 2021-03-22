
    
        /*  NOTE: This program was automatically generated by the Nuweb
            literate programming tool.  It is not intended to be modified
            directly.  If you wish to modify the code or use it in another
            project, you should start with the master, which is kept in the
            file orbits.w in the public GitHub repository:
                https://github.com/Fourmilab/orbits.git
            and is documented in the file orbits.pdf in the root directory
            of that repository.

            Build 0  1900-01-01 00:00  */
    

    integer BODY = 9;               // Our body number

    key owner;                          // UUID of owner
    key whoDat;                         // User with whom we're communicating


    integer LM_EP_CALC = 431;           // Calculate ephemeris
    integer LM_EP_RESULT = 432;         // Ephemeris calculation result
    integer LM_EP_STAT = 433;           // Print memory status


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


    integer sgn(float v) {
        if (v == 0) {
            return 0;
        } else if (v > 0) {
            return 1;
        }
        return -1;
    }


    float flSinh(float x) {
        return (llPow( 2.718281828459045 , x) - llPow( 2.718281828459045 , -x)) / 2;
    }

    float flCosh(float x) {
        return (llPow( 2.718281828459045 , x) + llPow( 2.718281828459045 , -x)) / 2;
    }

    float flTanh(float x) {
        return flSinh(x) / flCosh(x);
    }


    list gKepler(float e, float t, float q, float GaussK) {
//tawk("gKepler e " + (string) e + "  t " + (string) t + "  q " + (string) q);
        float f;
        float x;
        float d;
        float m1;
        integer i;

        float v;
        float r;

        if (e > 1.0) {
            
                float a1 = llFabs(q / (1 - e));
                float m = (GaussK * t) / (a1 * llSqrt(a1));

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
            
        } else {
            
                float m;
                float a1;
                float ev;

                a1 = q / (1 - e);
                m = GaussK * t * llPow(a1, -1.5);

                f = sgn(m);
                m = llFabs(m) / TWO_PI;
                m = (m - (llFloor(m))) * TWO_PI * f;
                if (m < 0) {
                    m += TWO_PI;
                }
                f = 1;
                if (m > PI) {
                    f = -1;
                }
                if (m > PI) {
                    m = TWO_PI - m;
                }
                x = PI_BY_TWO;
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
            
        }
        return [ v, r ];
    }


    float obliqeq(integer jd, float jdf) {

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

        //  Again, we evaluate a number specified as 23°26'21".448 as degrees
        float eps = 23.4392911;
        float u;
        float v;
        integer i;

        v = u = ((jd -  2451545 ) / ( 36525.0  * 100)) + (jdf / ( 36525.0  * 100));

        if (llFabs(u) < 1.0) {
            for (i = 0; i < 10; i++) {
                eps += llList2Float(oterms, i) * v;
                v *= u;
            }
        }
        return eps;
    }


    vector computeOrbit(list elements, list jdl, float GaussK, float e) {
//        float e = obliqeq(llList2Integer(jdl, 0), llList2Float(jdl, 1)) * DEG_TO_RAD;
//        float e = 0;
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
                         llList2Float(elements, 13), GaussK);
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


    list posPlanet(integer jd, float jdf) {
        float obelix = obliqeq(jd, jdf) * DEG_TO_RAD;
        vector pos = computeOrbit(s_elem, [ jd, jdf ],
            0.01720209895, obelix);
        float x = pos.x;
        float y = pos.y;
        float z = pos.z;
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



    default {
        state_entry() {
            whoDat = owner = llGetOwner();

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
            s_elem = llListReplaceList(s_elem, [ 360 / m_n, (1 + m_e) * m_a ], 15, 16);
//dumpOrbitalElements(s_elem);
        }


        link_message(integer sender, integer num, string str, key id) {
            
                integer LM_AS_LEGEND = 541;         // Update floating text legend
                integer LM_AS_SETTINGS = 542;       // Update settings
                integer LM_AS_VERSION = 543;        // Check version consistency
            

            
            //  LM_EP_CALC (431): Calculate ephemeris

            if (num == LM_EP_CALC) {
                list args = llCSV2List(str);
                integer argn = llGetListLength(args);
                if (llList2Integer(args, 0) & (1 << BODY)) {
                    list eph = [ ];
                    integer i;

                    for (i = 1; (i + 1) < argn; i += 2) {
                        eph += posPlanet(llList2Integer(args, i),
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
            
            
                //  LM_AS_VERSION (543): Check version consistency
                } else if (num == LM_AS_VERSION) {
                    if ("0" != str) {
                        llOwnerSay(llGetScriptName() +
                                   " build mismatch: Deployer " + str +
                                   " Local 0");
                    }
            
            }
        }
    }