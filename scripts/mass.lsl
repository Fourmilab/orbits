    /*
                      Numerical Integration Mass

                           by John Walker

        This script controls masses in a Fourmilab Orbits Numerical
        Integration simulation.  The masses simply respond to
        position updates from the Numerical Integration script.  They
        have no autonomy: they only go where ordered.

    */

    key owner;                          // UUID of owner
    key deployer;                       // ID of deployer who hatched us
    integer initState = 0;              // Initialisation state

    //  Properties of this mass
    integer s_trace = FALSE;            // Trace operations
    integer m_index;                    // Our mass index
    string m_name;                      // Name
    integer s_labels;                   // Show floating text label ?
    float m_mass;                       // Mass
    vector m_colour;                    // Colour
    float m_alpha;                      // Alpha (0 transparent, 1 solid)
    float m_glow;                       // Glow (0 none, 1 intense)
    float m_radius;                     // Mean radius

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

    float startTime;                    // Time we were hatched

    key whoDat;                         // User with whom we're communicating
    integer paths;                      // Draw particle trail behind masses ?
    /* IF TRACE */
    integer b1;                         // Used to trace only mass 1
    /* END TRACE */

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

    /*  exColour  --  Parse an extended colour specification:
                        <r, g, b [, alpha [ , glow ] ]>  */

    list exColour(string s) {
        if ((llGetSubString(s, 0, 0) == "<") &&
            (llGetSubString(s, -1, -1) == ">")) {
            list l = llParseStringKeepNulls(llGetSubString(s, 1, -2), [ "," ], [ ]);
            integer n = llGetListLength(l);
            if (n >= 3) {
                vector colour = < llList2Float(l, 0),
                                  llList2Float(l, 1),
                                  llList2Float(l, 2) >;
                float alpha = 1;
                float glow = 0;
                if (n >= 4) {
                    alpha = llList2Float(l, 3);
                    if (n >= 5) {
                        glow = llList2Float(l, 4);
                    }
                }
                return [ colour, alpha, glow ];
            }
        }
        return [ <1, 1, 1>, 1, 0 ];     // Default: solid white, no glow
    }

    default {

        state_entry() {
            whoDat = owner = llGetOwner();
        }

        on_rez(integer start_param) {
            initState = 0;

            //  If start_param is zero, this is a simple manual rez
            if (start_param > 0) {
                m_index = start_param;

                deployer = llList2Key(llGetObjectDetails(llGetKey(),
                                [ OBJECT_REZZER_KEY ]), 0);

                //  Set sit target

                llSitTarget(<-0.8, 0, 0>, llAxisAngle2Rot(<0, 1, 0>, -PI_BY_TWO));
                llSetCameraEyeOffset(<-1.2, 0, -1.2>);
                llSetCameraAtOffset(<-1, 0, 1>);

                //  Listen for messages from our deployer
                llListen(massChannel, "", NULL_KEY, "");

                //  Inform the deployer that we are now listening
                llRegionSayTo(deployer, massChannel,
                    llList2Json(JSON_ARRAY, [ "NEWMASS", m_index ]));

                initState = 1;          // Waiting for SETTINGS and INIT
            }
        }

        //  The listen event handles message from the deployer and other masses

        listen(integer channel, string name, key id, string message) {
//llOwnerSay("Mass channel " + (string) channel + " id " + (string) id +  " message " + message);

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
                                 "  Mass: " + (string) m_mass +
                                 "  Radius: " + (string) m_radius +
                                 "  Position: " + (string) llGetPos() +
                                 "\n    Script memory.  Free: " + (string) mFree +
                                    "  Used: " + (string) mUsed + " (" +
                                    (string) ((integer) llRound((mUsed * 100.0) / (mUsed + mFree))) + "%)"
                                );
                        }

                    //  MINIT  --  Set initial mass parameters after creation

                    } else if (ccmd == "MINIT") {
                        if (m_index == llList2Integer(msg, 1)) {
//tawk("MINIT  " + llList2CSV(msg));
                            m_name = llList2String(msg, 2);             // Name
                            m_mass = siuf(llList2String(msg, 3));       // Mass
                            list xcol =  exColour(llList2String(msg, 4));   // Extended colour
                                m_colour = llList2Vector(xcol, 0);              // Colour
                                m_alpha = llList2Float(xcol, 1);                // Alpha
                                m_glow = llList2Float(xcol, 2);                 // Glow
                            m_radius = siuf(llList2String(msg, 5));     // Mean radius
                            deployerPos = sv(llList2String(msg, 6));    // Deployer position

                            /* IF TRACE */
                            b1 = m_index == 1;
                            /* END TRACE */

                            //  Set properties of object
                            llSetLinkPrimitiveParamsFast(LINK_THIS, [
                                PRIM_COLOR, ALL_SIDES, m_colour, m_alpha,
                                PRIM_GLOW, ALL_SIDES, m_glow,
                                PRIM_DESC,  llList2Json(JSON_ARRAY, [ m_index, m_name, (string) m_mass ]),
                                PRIM_SIZE, <m_radius, m_radius, m_radius> * s_radscale
                            ]);
                            llSetStatus(STATUS_PHANTOM | STATUS_DIE_AT_EDGE, TRUE);

                            initState = 2;                  // INIT received, waiting for SETTINGS
                        }

                    /*  MASS_SET  --  Set simulation parameters relevant to masses.
                                      Do not confuse this message with the
                                      LM_AS_SETTINGS link message which is sent
                                      from the deployer.  This message is sent to
                                      the masses we've created to apprise them of
                                      settings relevant to their operation.  */

                    } else if (ccmd == "MASS_SET") {
                        integer bn = llList2Integer(msg, 1);
                        integer o_labels = s_labels;

                        if ((bn == 0) || (bn == m_index)) {
//tawk("MASS_SET  " + llList2CSV(msg));
                            paths = llList2Integer(msg, 2);
                            s_trace = llList2Integer(msg, 3);
                            s_kaboom = siuf(llList2String(msg, 4));
                            s_auscale = siuf(llList2String(msg, 5));
                            s_radscale = siuf(llList2String(msg, 6));
                            s_trails = llList2Integer(msg, 7);
                            s_pwidth = siuf(llList2String(msg, 8));
                            s_mindist = siuf(llList2String(msg, 9));
                            s_labels = llList2Integer(msg, 10);
                        }

                        if (o_labels != s_labels) {
                            o_labels = s_labels;
                            if (s_labels) {
                                llSetLinkPrimitiveParamsFast(LINK_THIS, [
                                    PRIM_TEXT, m_name, <0, 0.75, 0>, 1
                                ]);
                            } else {
                                llSetLinkPrimitiveParamsFast(LINK_THIS, [
                                    PRIM_TEXT, "", ZERO_VECTOR, 0
                                ]);
                            }
                        }

                        if (initState == 2) {
                            initState = 3;                  // INIT and SETTINGS received, now flying
                            startTime = llGetTime();        // Remember when we started
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

                    //  UMASS  --  Update mass position

                    } else if (ccmd == "UMASS") {
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
