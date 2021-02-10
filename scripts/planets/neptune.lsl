
    /*

                    Fourmilab Solar System

                      Planet Definition

    */

    list planet = [
        "Neptune",          // 0  Name of body
        "Sun",              // 1  Primary

        //  Orbital elements
        2451545,            // 2  Epoch (J2000), integer to avoid round-off

        30.06896348,        // 3  a    Semi-major axis, AU
        0.00858587,         // 4  e    Eccentricity
        1.76917,            // 5  i    Inclination, degrees
        131.72169,          // 6  Ω    Longitude of the ascending node, degrees
        44.97135,           // 7  ω    Argument of periapsis, degrees
        304.88003,          // 8  L    Mean longitude, degrees

        //  Orbital element centennial rates
        -0.00125196,        // 9  a    AU/century
        0.0000251,          // 10 e    e/century
        -3.64,              // 11 i    "/century
        -151.25,            // 12 Ω    "/century
        -844.43,            // 13 ω    "/century
        786449.21,          // 14 L    "/century

        //  Physical properties
        24764.0,            // 15 Equatorial radius, km
        24341.0,            // 16 Polar radius, km
        1.02413e26,         // 17 Mass, kg
        1.638,              // 18 Mean density, g/cm³
        11.15,              // 19 Surface gravity, m/s²
        23.5,               // 20 Escape velocity, km/s
        0.6713,             // 21 Sidereal rotation period, days
        <299.3, 42.950, 0>, // 22 North pole, RA, Dec
        28.32,              // 23 Axial inclination, degrees
        0.442               // 24 Albedo
    ];

    string ourName;                     // Our object name
    key owner;                          // UUID of owner
    key deployer;                       // ID of deployer who hatched us
    integer initState = 0;              // Initialisation state

    //  Properties of this mass
    integer s_trace = FALSE;            // Trace operations
    integer m_index;                    // Our mass index
    string m_name;                      // Name
    float m_scalePlanet;                // Planet scale
    float m_scaleStar;                  // Star scale
    integer m_jd;                       // Epoch Julian day
    float m_jdf;                        // Epoch Julian day fraction

    //  Settings communicated by deployer
    float s_kaboom = 50;                // Self destruct if this far (AU) from deployer
    float s_auscale = 0.2;              // Astronomical unit scale
    float s_radscale = 0.0000025;       // Radius scale
    integer s_trails = TRUE;            // Plot orbital trails ?
    float s_pwidth = 0.01;              // Paths/trails width
    float s_mindist = 0.1;              // Minimum distance to move

    integer massChannel = -982449822;   // Channel for communicating with planets
    string ypres = "B?+:$$";            // It's pronounced "Wipers"
    string Collision = "Balloon Pop";   // Explosion sound clip

    vector deployerPos;                 // Deployer position (centre of cage)

    key whoDat;                         // User with whom we're communicating
    integer paths;                      // Draw particle trail behind masses ?

vector m_colour = < 0.4902, 0.4902, 0.4902 >;   // HACK--SPECIFY COLOUR IN planet LIST

    //  Destroy mass after collision or going out of range

    kaboom() {
        llPlaySound(Collision, 1);

        llParticleSystem([
            PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,

            PSYS_SRC_BURST_RADIUS, 0.05,

            PSYS_PART_START_COLOR, m_colour,
            PSYS_PART_END_COLOR, m_colour,

            PSYS_PART_START_ALPHA, 0.9,
            PSYS_PART_END_ALPHA, 0.0,

            PSYS_PART_START_SCALE, <0.3, 0.3, 0>,
            PSYS_PART_END_SCALE, <0.1, 0.1, 0>,

            PSYS_PART_START_GLOW, 1,
            PSYS_PART_END_GLOW, 0,

            PSYS_SRC_MAX_AGE, 0.1,
            PSYS_PART_MAX_AGE, 0.5,

            PSYS_SRC_BURST_RATE, 20,
            PSYS_SRC_BURST_PART_COUNT, 1000,

            PSYS_SRC_ACCEL, <0, 0, 0>,

            PSYS_SRC_BURST_SPEED_MIN, 2,
            PSYS_SRC_BURST_SPEED_MAX, 2,

            PSYS_PART_FLAGS, 0
                | PSYS_PART_EMISSIVE_MASK
                | PSYS_PART_INTERP_COLOR_MASK
                | PSYS_PART_INTERP_SCALE_MASK
                | PSYS_PART_FOLLOW_VELOCITY_MASK
        ]);

        llSleep(1);         // Need to wait to allow particles and sound to play
        llDie();
    }

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

    /*  eqtoecliptic  --  Transform equatorial (right ascension and
                          declination) to ecliptic (heliocentric
                          latitude and longitide) co-ordinates.  */

    list eqtoecliptic(integer jd, float jdf, float alpha, float delta) {
        // Obliquity of the ecliptic
        float eps = obliqeq(jd, jdf) * DEG_TO_RAD;

        float lambda = llAtan2((llSin(alpha) * llCos(eps)) +
                             (llTan(delta) * llSin(eps)),
                             llCos(alpha));
        float beta = (llSin(delta) * llCos(eps)) - (llCos(delta) * llSin(alpha));

        return [ lambda, beta ];
    }

    //  sphRect  --  Convert spherical (L, B, R) co-ordinates to rectangular

    vector sphRect(float l, float b, float r) {
        return < r * llCos(b) * llCos(l),
                 r * llCos(b) * llSin(l),
                 r * llSin(b) >;
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

                //  Listen for messages from deployer
                llListen(massChannel, "", NULL_KEY, "");

                //  Inform the deployer that we are now listening
                llRegionSayTo(deployer, massChannel,
                    llList2Json(JSON_ARRAY, [ "PLANTED", m_index ]));

                initState = 1;          // Waiting for SETTINGS and INIT
            }
        }

        //  The listen event handles message from the deployer

        listen(integer channel, string name, key id, string message) {
//llOwnerSay("Planet " + llGetScriptName() + " channel " + (string) channel + " id " + (string) id +  " message " + message);

            if (channel == massChannel) {
                list msg = llJson2List(message);
                string ccmd = llList2String(msg, 0);

                if (id == deployer) {

                    //  Message from Deployer

                    //  ypres  --  Destroy mass

                    if (ccmd == ypres) {
                        llDie();

                    //  COLLIDE  --  Handle collision with another mass

                    } else if (ccmd == "COLLIDE") {
                        kaboom();

                    //  LIST  --  List mass information

                    } else if (ccmd == "LIST") {
                        integer bnreq = llList2Integer(msg, 1);

                        if ((bnreq == 0) || (bnreq == m_index)) {
                            integer mFree = llGetFreeMemory();
                            integer mUsed = llGetUsedMemory();

                            tawk("Mass " + (string) m_index +
                                 "  Name: " + m_name +
                                 "  Position: " + efv(llGetPos()) +
                                 "\n    Script memory.  Free: " + (string) mFree +
                                    "  Used: " + (string) mUsed + " (" +
                                    (string) ((integer) llRound((mUsed * 100.0) / (mUsed + mFree))) + "%)"
                                );
                        }

                    //  PINIT  --  Set initial parameters after creation

                    } else if (ccmd == "PINIT") {
                        if (m_index == llList2Integer(msg, 1)) {
                            m_name = llList2String(msg, 2);             // Name
                            deployerPos = sv(llList2String(msg, 3));    // Deployer position
                            m_scalePlanet = siuf(llList2String(msg, 4));    // Planet scale
                            m_scaleStar =  siuf(llList2String(msg, 5)); // Star scale
                            m_jd = llList2Integer(msg, 6);              // Epoch Julian day
                            m_jdf = siuf(llList2String(msg, 7));        // Epoch Julian day fraction

                            //  Set properties of object
                            float oscale = m_scalePlanet;
                            if (m_index == 0) {
                                oscale = m_scaleStar;
                            }

                            //  Compute size of body based upon scale factor

                            vector psize = < llList2Float(planet, 16),
                                             llList2Float(planet, 15),
                                             llList2Float(planet, 15) > * 0.0001 * oscale;

                            //  Calculate rotation to correctly orient north pole

                            vector npole = llList2Vector(planet, 22);
                            list npecl = eqtoecliptic(m_jd, m_jdf,
                                npole.x * DEG_TO_RAD, npole.y * DEG_TO_RAD);
                            vector npvec = sphRect(llList2Float(npecl, 0), llList2Float(npecl, 1), 1);
                            rotation nprot = llRotBetween(<-1, 0, 0>, npvec);

                            llSetLinkPrimitiveParamsFast(LINK_THIS, [
                                PRIM_DESC,  llList2Json(JSON_ARRAY,
                                    [ m_index, m_name, eff(llList2Float(planet, 17)) ]),
                                PRIM_SIZE, psize,           // Scale to proper size
                                PRIM_ROTATION, nprot        // Rotate north pole to proper orientation
                            ]);
                            llSetStatus(STATUS_PHANTOM | STATUS_DIE_AT_EDGE, TRUE);

                            initState = 2;                  // INIT received, waiting for SETTINGS
                        }

                    //  SETTINGS  --  Set simulation parameters

                    } else if (ccmd == "SETTINGS") {
                        integer bn = llList2Integer(msg, 1);
                        if ((bn == 0) || (bn == m_index)) {
                            paths = llList2Integer(msg, 2);
                            s_trace = llList2Integer(msg, 3);
                            s_kaboom = siuf(llList2String(msg, 4));
                            s_auscale = siuf(llList2String(msg, 5));
                            s_radscale = siuf(llList2String(msg, 6));
                            s_trails = llList2Integer(msg, 7);
                            s_pwidth = siuf(llList2String(msg, 8));
                            s_mindist = siuf(llList2String(msg, 9));
                        }

                        if (initState == 2) {
                            initState = 3;                  // INIT and SETTINGS received, now flying
                        }

                        //  Set or clear particle trail depending upon paths
                        if (paths) {
                            llParticleSystem(
                                [ PSYS_PART_FLAGS, PSYS_PART_EMISSIVE_MASK |
                                  PSYS_PART_INTERP_COLOR_MASK |
                                  PSYS_PART_RIBBON_MASK,
                                  PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_DROP,
                                  PSYS_PART_START_COLOR, m_colour,
                                  PSYS_PART_END_COLOR, m_colour,
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

                    //  UPDATE  --  Update mass position

                    } else if (ccmd == "UPDATE") {
                        vector p = llGetPos();
                        vector npos = sv(llList2String(msg, 2));
                        float dist = llVecDist(p, npos);
if (s_trace) {
    tawk(m_name + ": Update pos from " + (string) p + " to " + (string) npos +
        " dist " + (string) dist);
}
                        if ((s_kaboom > 0) &&
                            ((llVecDist(npos, deployerPos) / s_auscale) > s_kaboom)) {
                            kaboom();
                            return;
                        }
                        if (dist >= s_mindist) {
                            llSetLinkPrimitiveParamsFast(LINK_THIS,
                                [ PRIM_POSITION, npos ]);
                            if (paths) {
                                llSetLinkPrimitiveParamsFast(LINK_THIS,
                                    [ PRIM_ROTATION, llRotBetween(<0, 0, 1>, (npos - p)) ]);
                            }
                            if (s_trails) {
                                flPlotLine(p, npos, m_colour, s_pwidth);
                            }
                        }
                    }
                }
            }
        }
     }
