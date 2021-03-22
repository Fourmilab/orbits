
    
        /*  NOTE: This program was automatically generated by the Nuweb
            literate programming tool.  It is not intended to be modified
            directly.  If you wish to modify the code or use it in another
            project, you should start with the master, which is kept in the
            file orbits.w in the public GitHub repository:
                https://github.com/Fourmilab/orbits.git
            and is documented in the file orbits.pdf in the root directory
            of that repository.

            Build 0  1900-01-01 00:00  */
    

    
        list planet = [
            "Luna",           // 0  Name of body
            "Earth",          // 1  Primary

            //  Orbital elements (ecliptical)
             2451545 ,          // 2  Epoch (J2000), integer to avoid round-off
            384400,             // 3  a    Semi-major axis, km
            0.0554,             // 4  e    Eccentricity
            5.16,               // 5  i    Inclination, degrees
            125.08,             // 6  Ω    Longitude of the ascending node, degrees
            318.15,             // 7  ω    Argument of periapsis, degrees
            135.27,             // 8  M    Mean anomaly, degrees

            //  Orbital element precession periods
            0,                  // 9  a
            0,                  // 10 e
            0,                  // 11 i
            18.6,               // 12 Ω    Precession period/years
            5.997,              // 13 ω    Precession period/years
            0,                  // 14 M

            //  Physical properties
            1738.1,             // 15 Equatorial radius, km
            1736.0,             // 16 Polar radius, km
            7.342e22,           // 17 Mass, kg
            3.344,              // 18 Mean density, g/cm³
            1.62,               // 19 Surface gravity, m/s²
            2.38,               // 20 Escape velocity, km/s
            27.321661,          // 21 Sidereal rotation period, days
            <266.86, 65.64, 0>, // 22 North pole, RA, Dec
            1.5424,             // 23 Axial inclination, degrees
            0.136,              // 24 Albedo

            //  Extras
            0.5,                // 25 Fractional part of epoch
             3.986004418e14 ,       /* 26 Standard gravitational parameter (G M)
                                      of primary, m^3/sec^2  */
             <0.3176, 0.149, 0.1529> , // 27 Colour of trail tracing orbit
            <266.86, 65.64, 0>      // 28 Laplace plane of orbit: RA, Dec, Tilt
        ];
    

    //  Functions specific to Luna position calculation
    
        float fixangle(float a) {
            return a - (360.0 * llFloor(a / 360.0));
        }
    
    
       float lunaKepler(float m, float ecc) {
            float e;
            float delta;
            float EPSILON = 1e-6;

            e = m = m * DEG_TO_RAD;
            do {
                delta = e - ecc * llSin(e) - m;
                e -= delta / (1 - ecc * llCos(e));
            } while (llFabs(delta) > EPSILON);
            return e;
        }
    
    
        vector sphRect(float l, float b, float r) {
            return < r * llCos(b) * llCos(l),
                     r * llCos(b) * llSin(l),
                     r * llSin(b) >;
        }
    
    
        list lowmoon(integer jd, float jdf) {

            // Elements of the Moon's orbit

            float Epoch = 2444238.5;    // Epoch: 1980-01-01 00:00 UTC
            float l0 = 64.975464;       // Moon's mean longitude
            float P0 = 349.383063;      // Mean longitude of the perigee
            float N0 = 151.950429;      // Mean longitude of the node
            float i  = 5.145396;        // Inclination
            float e  = 0.054900;        // Eccentricity
            float a  =  384401 ; // Moon's semi-major axis, km

            //  Elements of the Sun's apparent orbit

            float Epg = 278.833540;     // Ecliptic longitude
            float Omg = 282.596403;     // Ecliptic longitude of perigee
            float Es = 0.016718;        // Eccentricity

            float D = (jd - Epoch) + jdf;

            //              For the Sun

            float Ns = ((360.0 / 365.2422) * D);    // Circular orbit position
            float M = fixangle(Ns + Epg - Omg);     // Mean anomaly
            float sEc = lunaKepler(M, Es);          // Solve equation of Kepler
            sEc = llSqrt((1 + Es) / (1 - Es)) * llTan(sEc / 2);
            sEc = 2 * llAtan2(sEc, 1) * RAD_TO_DEG; // True anomaly
            float Las = fixangle(sEc + Omg);        // Sun's geocentric ecliptic longitude

            //              For the Moon

            float l = fixangle((13.1763966 * D) + l0);      // Mean longitude
            float Mm = fixangle(l - (0.1114041 * D) - P0);  // Mean anomaly
            float N = fixangle(N0 - 0.0529539 * D);         // Ascending node mean longitude
            float C = l - Las;                              // Correction for evection
            float Ev = 1.2739 * llSin(((2 * C) - Mm) * DEG_TO_RAD);  // Evection
            float Ae = 0.1858 * llSin(M * DEG_TO_RAD);      // Annual equation
            float A3 = 0.37 * llSin(M * DEG_TO_RAD);        // Third correction

            float Mpm = fixangle(Mm + Ev - Ae - A3);        // Corrected anomaly M'm
            float Ec = fixangle(6.2886 * llSin(Mpm * DEG_TO_RAD));   // Correction for equation of the centre
            float A4 = 0.214 * llSin(2 * Mpm * DEG_TO_RAD); // Fourth correction
            float lp = fixangle(l + Ev + Ec - Ae + A4);     // Corrected longitude
            float V = fixangle(0.6583 * llSin((2 * (lp - Las)) * DEG_TO_RAD));  // Variation

            float lpp = fixangle(lp + V);                   // True orbital longitude
            float Np = fixangle(N - (0.16 * llSin(M * DEG_TO_RAD)));    // Corrected longitude of the node
            float lm = (llAtan2(llSin((lpp - Np) * DEG_TO_RAD) * llCos(i * DEG_TO_RAD), // Ecliptic latitude
                llCos((lpp - Np) * DEG_TO_RAD)) * RAD_TO_DEG) + Np;
            // Ecliptic longitude
            float bm = llAsin(llSin(fixangle(lpp - Np) * DEG_TO_RAD) * llSin(i * DEG_TO_RAD)) * RAD_TO_DEG;

            float Rh = (a * (1 - (e * e))) /           // Radius vector (km)
                (1 + (e * llCos(fixangle(Mpm + Ec) * DEG_TO_RAD)));

            return [ 0, 0, Rh, lm, bm ];
        }
    

    //  Common satellite variables and functions
    
        
            string ourName;                     // Our object name
            key owner;                          // UUID of owner
            key deployer;                       // ID of deployer who hatched us
            integer initState = 0;              // Initialisation state

            //  Properties of this mass
            integer s_trace = FALSE;            // Trace operations
            integer m_index;                    // Our mass index
            string m_name;                      // Name
            float m_scalePlanet;                // Planet scale

            //  Settings communicated by deployer
            float s_kaboom = 50;                // Self destruct if this far (AU) from deployer
            float s_auscale = 0.3;              // Astronomical unit scale
            integer s_trails = FALSE;           // Plot orbital trails ?
            float s_pwidth = 0.01;              // Paths/trails width
            float s_mindist = 0.1;              // Minimum distance to move
            integer s_labels = FALSE;           // Show floating text legend ?
            integer s_satShow = 0;              // Show satellites

            string ypres = "B?+:$$";            // It's pronounced "Wipers"

            vector deployerPos;                 // Deployer position

            key whoDat;                         // User with whom we're communicating
            integer paths;                      // Draw particle trail behind masses ?
        

        rotation npRot;                     // Rotation to orient north pole

        integer m_jd;                       // Epoch Julian day
        float m_jdf;                        // Epoch Julian day fraction

        float startTime;                    // Time we were placed

        vector lastTrailP = ZERO_VECTOR;    // Last trail path point
    
    
        
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
        

        
            vector l2r(vector loc) {
                return (loc * llGetRootRotation()) + llGetRootPosition();
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
                float tang = PI_BY_TWO - llAcos(lfwd * xnorm);
                /*  The angle, tang, computed above, does not take into
                    account whether the prime meridian vector, projected
                    upon the line containing the centre of the body
                    and ecliptic origin, is parallel or anti-parallel to the
                    vector from the centre of the body to the
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
                    complete body rotation.  */
                rpole = rpole * llAxisAngle2Rot(raxis, tang);
                return rpole;
            }
        
        
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
        

        
            updateLegendSat() {
        //tawk("updateLegendSat() called");
                if (s_labels  && isSatVisible) {
        //tawk("  Showing satellite legend");
                    llSetLinkPrimitiveParamsFast(LINK_THIS, [
                        PRIM_TEXT, llList2String(planet, 0),
                                   llList2Vector(planet, 27), 1
                    ]);
                }
            }
        

        
            flRezRegion(string inventory, vector pos, vector vel,
                        rotation rot, integer param) {
                vector crepos = llGetPos();
                if (llVecDist(pos, crepos) <= 9.5) {
                    llRezObject(inventory, pos, vel, rot, param);
                } else {
                    //  It's ugly, but it gets you there
                    llSetRegionPos(pos);
                    llRezObject(inventory, pos, vel, rot, param);
                    llSetRegionPos(crepos);
                }
            }
        
        
            //  List of selectable diameters for lines
            list flPlotLineDiam =  [ 0.01, 0.015, 0.02, 0.025 ] ;
            integer flPlotPerm = FALSE;     // Use permanent objects for plotted lines ?

            flPlotLine(vector fromPoint, vector toPoint,
                       vector colour, float diameter) {
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

                string lineObj = "flPlotLine";
                if (flPlotPerm) {
                    lineObj = "flPlotLine Permanent";
                }
                flRezRegion(lineObj, midPoint, ZERO_VECTOR,
                    llRotBetween(<0, 0, 1>, llVecNorm(toPoint - midPoint)),
                    ((bestdia << 22) | (icolour << 10) | ilength)
                );
            }
        

        
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
    
    
        //  Planetary satellite message
        integer LM_PS_DEPMSG = 811;         // Message from deployer
        integer LM_PS_UPDATE = 812;         // Update position and rotation
    
    
        integer isSatVisible = FALSE;           // Is satellite visible ?

        setSatelliteVisibility(integer visible) {
    //tawk("Satellite visibility: " + (string) visible);
            if (visible != isSatVisible) {
                isSatVisible = visible;
                if (isSatVisible) {
    //tawk("  Setting satellite visible.");
                    //  Satellite is now visible
                    llSetLinkPrimitiveParamsFast(LINK_THIS, [
                                PRIM_COLOR, ALL_SIDES,  <1, 1, 1> , 1 ]);
                    if (s_labels) {
                        updateLegendSat();
                    }
                } else {
    //tawk("  Setting satellite invisible.");
                    //  Satellite is now invisible
                    llSetLinkPrimitiveParamsFast(LINK_THIS, [
                                PRIM_COLOR, ALL_SIDES,  <1, 1, 1> , 0,
                                PRIM_POS_LOCAL, ZERO_VECTOR,
                                PRIM_TEXT, "", ZERO_VECTOR, 0 ]);
                    s_labels = FALSE;
                }
            }
        }
    

    //  State handler
    default {
        state_entry() {
            whoDat = owner = llGetOwner();
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
        

        
                link_message(integer sender, integer num, string str, key id) {
        //tawk(llGetScriptName() + " link message sender " + (string) sender + "  num " + (string) num + "  str " + str + "  id " + (string) id);

                    //  LM_PS_DEPMSG (811): Deployer message forwarded by primary

                    if (num == LM_PS_DEPMSG) {
                        list msg = llJson2List(str);
                        string ccmd = llList2String(msg, 0);
        
                        if (ccmd == ypres) {
                            if (s_trails) {
                                llRegionSay( -982449822 ,
                                    llList2Json(JSON_ARRAY, [ ypres ]));
                            }
        
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
        
                        } else if (ccmd == "PINIT") {
                            m_index = llList2Integer(msg, 1);           // Index of planet we orbit
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
                            s_satShow = llList2Integer(msg, 22);

                            //  Update visibility of this satellite
                            setSatelliteVisibility((s_satShow & (1 << m_index)) != 0);

                            //  Update label if state has changed
                            if (s_labels != o_labels) {
                                if (s_labels) {
                                    updateLegendSat();
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
        
                        
                            } else if (ccmd == "VERSION") {
                                if ("0" != llList2String(msg, 1)) {
                                    llOwnerSay(llGetScriptName() +
                                               " build mismatch: Deployer " + llList2String(msg, 1) +
                                               " Local 0");
                                }
                        
                            
                                llRegionSay( -982449822 ,
                                    llList2Json(JSON_ARRAY, [ "VERSION", llList2String(msg, 1) ]));
                            
                        }
        
                    } else if (num == LM_PS_UPDATE) {
                        if (isSatVisible) {
                            list msg = llJson2List(str);

                            integer jd = llList2Integer(msg, 0);
                            float jdf = siuf(llList2String(msg, 1));

                            //  Compute position of satellite (code from argument)
                            
                                list lp = lowmoon(jd, jdf);
                                vector lxyz = sphRect(llList2Float(lp, 3) * DEG_TO_RAD,     // L
                                                      llList2Float(lp, 4) * DEG_TO_RAD,     // B
                                                      llList2Float(lp, 2));                 // R

                                float s_satscale = 1.75e-6 * m_scalePlanet; // Scale factor, satellite orbit km to model metres
                                vector mxyz = lxyz * s_satscale;
                            //tawk("Moon lp " + llList2CSV(lp) + "  lxyz " + (string) lxyz + "  mxyz " + (string) mxyz +
                            // " s_auscale " + (string) s_auscale + "  s_satscale " + (string) (s_satscale * 1.0e7));
                            

                            //  Need to take out north pole rotation of primary body
                            vector npos = mxyz * (ZERO_ROTATION / llGetRootRotation());
                            llSetLinkPrimitiveParamsFast(LINK_THIS, [
                                        PRIM_POS_LOCAL, npos,
                                        PRIM_ROT_LOCAL, tidalLock(npos) ]);

        //                  if (paths) {
        //                      llSetLinkPrimitiveParamsFast(LINK_THIS,
        //                          [ PRIM_ROTATION, llRotBetween(<0, 0, 1>, (npos - p)) ]);
        //                  }
                            if (s_trails) {
                                vector trailP = l2r(npos);
                                if (lastTrailP != ZERO_VECTOR) {
                                    flPlotLine(lastTrailP, trailP, llList2Vector(planet, 27), s_pwidth);
                                }
                                lastTrailP = trailP;
                            }
                        }
                    }
                }
        
    }
