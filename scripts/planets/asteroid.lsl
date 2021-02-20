
    /*

                    Fourmilab Solar System

                      Asteroid Definition

    */

    list planet = [
        "Asteroid",         // 0  Name of body
        "Sun",              // 1  Primary

        //  Orbital elements
        2451545,            // 2  Epoch (J2000), integer to avoid round-off

        0.38709893,         // 3  a    Semi-major axis, AU
        0.20563069,         // 4  e    Eccentricity
        7.00487,            // 5  i    Inclination, degrees
        48.33167,           // 6  Ω    Longitude of the ascending node, degrees
        77.45645,           // 7  ω    Argument of periapsis, degrees
        252.25084,          // 8  L    Mean longitude, degrees

        //  Orbital element centennial rates
        0.00000066,         // 9  a    AU/century
        0.00002527,         // 10 e    e/century
        -23.51,             // 11 i    "/century
        -446.30,            // 12 Ω    "/century
        573.57,             // 13 ω    "/century
        538101628.29,       // 14 L    "/century

        //  Physical properties
        0,                  // 15 Equatorial radius, km
        0,                  // 16 Polar radius, km
        0,                  // 17 Mass, kg
        0,                  // 18 Mean density, g/cm³
        0,                  // 19 Surface gravity, m/s²
        0,                  // 20 Escape velocity, km/s
        0,                  // 21 Sidereal rotation period, days
        ZERO_VECTOR,        // 22 North pole, RA, Dec
        0,                  // 23 Axial inclination, degrees
        0                   // 24 Albedo
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

    //  Settings communicated by deployer
    float s_kaboom = 50;                // Self destruct if this far (AU) from deployer
    float s_auscale = 0.3;              // Astronomical unit scale
    integer s_trails = FALSE;           // Plot orbital trails ?
    float s_pwidth = 0.01;              // Paths/trails width
    float s_mindist = 0.1;              // Minimum distance to move
    integer s_labels = FALSE;           // Show floating text legend ?

    integer massChannel = -982449822;   // Channel for communicating with planets
    string ypres = "B?+:$$";            // It's pronounced "Wipers"
    string Collision = "Balloon Pop";   // Explosion sound clip

    vector deployerPos;                 // Deployer position (centre of cage)

    key whoDat;                         // User with whom we're communicating
    integer paths;                      // Draw particle trail behind masses ?

vector m_colour = < 0.749, 0.745, 0.749 >;  // HACK--SPECIFY COLOUR IN planet LIST

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

    //  randVec  --  Generate a random unit vector

    vector randVec() {
        /*  Random unit vector by Marsaglia's method:
            Marsaglia, G. "Choosing a Point from the Surface
            of a Sphere." Ann. Math. Stat. 43, 645-646, 1972.  */
        integer outside = TRUE;

        while (outside) {
            float x1 = 1 - llFrand(2);
            float x2 = 1 - llFrand(2);
            if (((x1 * x1) + (x2 * x2)) < 1) {
                outside = FALSE;
                float x = 2 * x1 * llSqrt(1 - (x1 * x1) - (x2 * x2));
                float y = 2 * x2 * llSqrt(1 - (x1 * x1) - (x2 * x2));
                float z = 1 - 2 * ((x1 * x1) + (x2 * x2));
                return < x, y, z >;
            }
        }
        return ZERO_VECTOR;         // Can't happen, but idiot compiler errors otherwise
    }

    /*  rectSph  --  Convert rectangular co-ordinates to spherical.
                     The spherical co-ordinates are returned in a
                     vector <L, B, R> with angles in radians.  */

    vector rectSph(vector rc) {
        float r = llVecMag(rc);
        return < llAtan2(rc.y, rc.x), llAsin(rc.z / r), r >;
    }

    //  fixangr  --  Range reduce an angle in radians

    float fixangr(float a) {
        return a - (TWO_PI * (llFloor(a / TWO_PI)));
    }

    //  updateLegend  --  Update floating text legend above body

    updateLegend(vector pos) {
        if (s_labels) {
            string legend;
            vector lbr = rectSph(pos);

            legend = m_name +
                     "\nLong " + eff(fixangr(lbr.x) * RAD_TO_DEG) +
                        "° Lat " + eff(lbr.y * RAD_TO_DEG) +
                     "°\nRV " + eff(lbr.z) + " AU" +
                     "\nPos " + efv(pos);
            llSetLinkPrimitiveParamsFast(LINK_THIS, [
                PRIM_TEXT, legend, <1, 1, 0>, 1
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

    default {

        state_entry() {
            whoDat = owner = llGetOwner();
            llSetLinkPrimitiveParamsFast(LINK_THIS, [
                PRIM_TEXT, "", ZERO_VECTOR, 0
            ]);
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

                            //  Set properties of object

                            //  Compute size of body based upon scale factor

                            vector psize = llList2Vector(llGetLinkPrimitiveParams(LINK_THIS,
                                [ PRIM_SIZE ]), 0) * m_scalePlanet;

                            llSetLinkPrimitiveParamsFast(LINK_THIS, [
                                PRIM_DESC,  llList2Json(JSON_ARRAY,
                                    [ m_index, m_name ]),
                                PRIM_SIZE, psize,           // Scale to proper size
                                // Start random rotation
                                PRIM_OMEGA, randVec(), llFrand(PI_BY_TWO), 1
                            ]);
                            llSetStatus(STATUS_PHANTOM | STATUS_DIE_AT_EDGE, TRUE);

                            initState = 2;                  // INIT received, waiting for SETTINGS
                        }

                    //  SETTINGS  --  Set simulation parameters

                    } else if (ccmd == "SETTINGS") {
                        integer bn = llList2Integer(msg, 1);
                        if ((bn == 0) || (bn == m_index)) {
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
                                    updateLegend((llGetPos() - deployerPos) / s_auscale);
                                } else {
                                    llSetLinkPrimitiveParamsFast(LINK_THIS, [
                                        PRIM_TEXT, "", ZERO_VECTOR, 0 ]);
                                }
                            }
                        }

                        if (initState == 2) {
                            initState = 3;                  // INIT and SETTINGS received
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
                        //  Distance from previous position
                        float dist = llVecDist(p, npos);
                        //  Distance (AU) from the Sun
                        float rvec = llVecDist(npos, deployerPos) / s_auscale;
if (s_trace) {
    tawk(m_name + ": Update pos from " + (string) p + " to " + (string) npos +
        " dist " + (string) dist);
}
                        //  If we've ventured too far, go kaboom
                        if ((s_kaboom > 0) & (rvec > s_kaboom)) {
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
                        updateLegend((npos - deployerPos) / s_auscale);
                    }
                }
            }
        }

/*
        //  Toggle legend on touch

        touch_start(integer n) {
            s_labels = !s_labels;
            if (!s_labels) {
                llSetLinkPrimitiveParamsFast(LINK_THIS, [
                    PRIM_TEXT, "", ZERO_VECTOR, 0
                ]);
            }
        }
*/
     }
