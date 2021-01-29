    /*
                           Fourmilab Mass

                           by John Walker

    */

    string ourName;                     // Our object name
    key owner;                          // UUID of owner
    key deployer;                       // ID of deployer who hatched us
    integer initState = 0;              // Initialisation state

    //  Properties of this mass
    integer s_trace = FALSE;            // Trace operations
    integer m_index;                    // Our mass index
    string m_name;                      // Name
//    vector m_pos;                       // Initial position (relative to deployer)
//    vector m_vel;                       // Initial velocity
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

    integer birdChannel = -982449822;   // Channel for communicating with planets
    string ypres = "B?+:$$";            // It's pronounced "Wipers"
    string Collision = "Balloon Pop";   // Explosion sound clip

    vector initialPos;                  // Initial bird position
    vector deployerPos;                 // Deployer position (centre of cage)

    float startTime;                    // Time we were hatched

    key whoDat;                         // User with whom we're communicating
    integer paths;                      // Draw particle trail behind masses ?
    /* IF TRACE */
    integer b1;                         // Used to trace only bird 1
    /* END TRACE */
    integer stepCount;                  // Total step count
float stepTime;                         // Step sequence start time
integer stepMove = 0;

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

    /* IF TRACE */

    /*  float2Sci  --  Edit floating point number to accurate
                       scientific notation.

        The following function is:
            Copyright © 2016 Linden Research, Inc.
            Licensed under Creative Commons Attribution-Share Alike 3.0
            Source: http://wiki.secondlife.com/wiki/Float2Sci

        It has been modified for use within Fourmilab CSV and,
        conveniently, is distributed under the same license.  */

    string float2Sci(float input) {
        if (input == 0) {           // Handle negative zero
            //  Remove trailing zeroes
            return llDeleteSubString((string) input, -5, -1);
        }

        float frac = llFabs(input); // Put the negative back at the end
        string mantissa = (string) frac;    // May be as long as 47 characters
        if (!~llSubStringIndex(mantissa, ".")) {
            return (string) input;  // Handle NaN and Infinities
        }

        integer exponent = -6;      // Default exponent for optical method
        if (frac == (float) mantissa) {
            mantissa = llDeleteSubString(mantissa, -7, -7); // Elide decimal point
            jump optical;
        }

        /*  Optical method failed:

            Ugly Math version; ugly in the sense that it is slow and
            not as elegant as working with it as a string.
                A) Calculate the exponent via approximation of C log2().
                B) Use kludge to avert fatal error in approximation of
                   log2 result (only a problem with values >= 0x1.FFFFF8p127).
                   (The exponent is sometimes reported as 128, which
                   will break float math, so we subtract the test for
                   128. max_float is 0x1.FFFFFEp127, so we are only
                   talking a very small fraction of numbers.)
                C) Normalise floats with questionable exponents.
                D) Calculate rounding error left from log2
                   approximation and add to normalization value. (The '|'
                   acts like a '+' in this instance but saves us one
                   byte.)  */

        integer position = (24 | (3 <= frac)) -                 // D
                     (integer) (frac /= llPow(2.0,              // C
                        exponent = (exponent -                  // B
                            ((exponent = llFloor(llLog(frac) /
                            0.69314718055994530941723212145818))// A
                                == 128))));

        /*  This pushes the float into the integer buffer exactly.
            since the shift is within integer range, we don't need to
            make a float.  */

        integer int = (integer) (frac * (1 << position));
        //  Since the float is in the integer buffer, we need to clear the float buffer.
        integer target = (integer) (frac = 0.0);

        /*  We don't use a traditional while loop, and instead opt for
            a do-while, because it's faster since we may have to do about
            128 iterations, this savings is important.  The exponent needs
            one final adjustment because of the shift, so we do it here to
            save memory and it's faster.

            The two loops try to make exponent == position by shifting
            and multiplying. when they are equal, then this should be
            true: ((int * llPow(10, exponent)) == llFabs(input)) That
            is of course assuming that the llPow(10, exponent) result
            has enough precision.

            We recycle position for these loops as a temporary buffer.
            This is so we can save a few operations.  If we didn't, then
            we could actually optimize the variable out of the code;
            though it would be slower.  */

        if (target > (exponent -= position)) {
            //  Apply the rest of the bit shift if |input| < 1
            do {
                if (int < 0x19999999) {     // (0x80000000 / 5)
                    //  Won't overflow, multiply in 5
                    int = int * 5 + (position = (integer) (frac *= 5.0));
                    frac -= (float) position;
                    target = ~-target;
                } else {
                    //  Overflow predicted, divide by 2
                    frac = (frac + (int & 1)) / 2;
                    int = int >> 1;
                    exponent = -~exponent;
                }
            } while (target ^ exponent);
        } else if (target ^ exponent) {     // Target < exponent
            //  Apply the rest of the bit shift if |input| > 1
            do {
                if  (int < 0x40000000) {    // (0x80000000 / 2)
                    //  Won't overflow, multiply in 2
                    int = (int << 1) + (position = (integer) (frac *= 2.0));
                    frac -= (float) position;
                    exponent = ~-exponent;
                }
                else {                      //  Overflow predicted, divide by 5
                    frac = (frac + (int % 5)) / 5.0;
                    int /= 5;
                    target = -~target;
                }
            } while (target ^ exponent);
        }

        /*  int is now properly calculated.  It holds enough data to
            accurately describe the input in conjunction with exponent.
            we feed this through optical to clean up the answer.  */

        mantissa = (string) int;

        @optical;

        /*  It's not an issue that we may be jumping over the
            initialization of some of the variables, we initialise
            everything we use here.

            To accurately describe a float you only need 9 decimal
            places; so we throw the extras away. */

        if (9 < (target = position = llStringLength(mantissa))) {
            position = 9;
        }

        //  Chop off the tailing zeroes; we don't need them.

        do;                 //  Faster then a while loop
        while ((llGetSubString(mantissa, position, position) == "0") &&
               (position = ~-position));

        /*  We do a bad thing: we recycle 'target' here, position is
            one less then target, "target + ~position" is the same as
            "target - (position + 1)" saves 6 bytes. This block of code
            actually does the cutting.  */

        if (target + ~position) {
            mantissa = llGetSubString(mantissa, 0, position);
        }

        /*  Insert the decimal point (not strictly needed).  We add the
            extra zero for aesthetics. by adding in the decimal point,
            which simplifies some of the code.  */

        mantissa = llInsertString(mantissa, 1, llGetSubString(".0", 0, !position));

        //  Adjust exponent from having added the decimal place
        if ((exponent += ~-target) != 0) {
            mantissa += "e" + (string) exponent;
        }

        //  Negate if input was negative
        if (input < 0) {
            return "-" + mantissa;
        }
        return mantissa;
    }
    //  End Linden Lab float2Sci() function

    //  ef  --  Edit floats in string to parsimonious representation

    string eff(float f) {
        return float2Sci(f);
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
    /* END TRACE */
    
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

                ourName = llGetObjectName();
                deployer = llList2Key(llGetObjectDetails(llGetKey(),
                                         [ OBJECT_REZZER_KEY ]), 0);
//tawk((string) m_index + ": deployer " + (string) deployer);
//                llSetBuoyancy(1);       // Set buoyancy of object: 0 = fall, 1 = float

                //  Set sit target

                llSitTarget(<-0.8, 0, 0>, llAxisAngle2Rot(<0, 1, 0>, -PI_BY_TWO));
                llSetCameraEyeOffset(<-1.2, 0, -1.2>);
                llSetCameraAtOffset(<-1, 0, 1>);

                //  Listen for messages from deployer and other masses
                llListen(birdChannel, "", NULL_KEY, "");

                //  Inform the deployer that we are now listening
                llRegionSayTo(deployer, birdChannel,
                    llList2Json(JSON_ARRAY, [ "REZ", m_index ]));
                    
                stepCount = 0;

                initState = 1;          // Waiting for SETTINGS and INIT
            }
        }

        //  The listen event handles message from the deployer and other masses

        listen(integer channel, string name, key id, string message) {
//llOwnerSay("Mass channel " + (string) channel + " id " + (string) id +  " message " + message);

            if (channel == birdChannel) {
                list msg = llJson2List(message);
                string ccmd = llList2String(msg, 0);

//if (id != deployer) {
//    tawk("Not our deployer!");
//}
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
                                 "  Mass: " + eff(m_mass) +
                                 "  Radius: " + eff(m_radius) +
                                 "  Position: " + efv(llGetPos()) +
                                 "\n    Script memory.  Free: " + (string) mFree +
                                    "  Used: " + (string) mUsed + " (" +
                                    (string) ((integer) llRound((mUsed * 100.0) / (mUsed + mFree))) + "%)"
                                );
                        }

                    //  INIT  --  Set initial parameters after creation

                    } else if (ccmd == "INIT") {
                        if (m_index == llList2Integer(msg, 1)) {
                            m_name = llList2String(msg, 2);             // Name
//                            m_pos = (vector) llList2String(msg, 3);     // Initial position
//                            m_vel = (vector) llList2String(msg, 4);     // Initial velocity
                            m_mass = llList2Float(msg, 5);              // Mass
                            list xcol =  exColour(llList2String(msg, 6));   // Extended colour
//tawk(m_name + " Xcol " + llList2String(msg, 6) + " => " + llList2CSV(xcol));
//                            m_colour = (vector) llList2String(msg, 6);  // Colour
                            m_colour = llList2Vector(xcol, 0);          // Colour
                            m_alpha = llList2Float(xcol, 1);            // Alpha
                            m_glow = llList2Float(xcol, 2);             // Glow
                            m_radius = llList2Float(msg, 7);            // Mean radius
                            deployerPos = (vector) llList2String(msg, 8); // Deployer position
                            
                            /* IF TRACE */
                            b1 = m_index == 1;
                            /* END TRACE */

                            //  Set properties of object
                            llSetLinkPrimitiveParamsFast(LINK_THIS, [
                                PRIM_COLOR, ALL_SIDES, m_colour, m_alpha,
                                PRIM_GLOW, ALL_SIDES, m_glow,
                                PRIM_DESC,  llList2Json(JSON_ARRAY, [ m_index, m_name, eff(m_mass) ]),
                                PRIM_SIZE, <m_radius, m_radius, m_radius> * s_radscale
                            ]);
                            llSetStatus(STATUS_PHANTOM | STATUS_DIE_AT_EDGE, TRUE);

                            initState = 2;                  // INIT received, waiting for SETTINGS
                        }

                    //  RESET  --  Restore initial position and velocity

                    } else if (ccmd == "RESET") {
                        llSetVelocity(ZERO_VECTOR, FALSE);
                        llLookAt(initialPos, 0.5, 0.5);
                        llMoveToTarget(initialPos, 0.05);
                        llSleep(0.25);
                        llStopLookAt();
                        llStopMoveToTarget();

                    //  SETTINGS  --  Set simulation parameters

                    } else if (ccmd == "SETTINGS") {
                        integer bn = llList2Integer(msg, 1);
                        if ((bn == 0) || (bn == m_index)) {
                            paths = llList2Integer(msg, 2);
                            s_trace = llList2Integer(msg, 3);
                            s_kaboom = (float) llList2String(msg, 4);
                            s_auscale = (float) llList2String(msg, 5);
                            s_radscale = (float) llList2String(msg, 6);
                            s_trails = llList2Integer(msg, 7);
                            s_pwidth = (float) llList2String(msg, 8);
                            s_mindist = (float) llList2String(msg, 9);
                        }

                        if (initState == 2) {
                            initState = 3;                  // INIT and SETTINGS received, now flying
                            startTime = llGetTime();        // Remember when we started
                        }

                        //  Set or clear particle trail depending upon paths
                        if (paths) {
/*  Experimental, under development
                            llParticleSystem(
                                [ PSYS_PART_FLAGS, PSYS_PART_EMISSIVE_MASK |
                                  PSYS_PART_INTERP_COLOR_MASK | PSYS_PART_FOLLOW_SRC_MASK,
                                  PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_DROP,
                                  PSYS_PART_START_COLOR, m_colour,
                                  PSYS_PART_END_COLOR, m_colour,
                                  PSYS_PART_START_SCALE, <0.2, 0.2, 0.2>,
                                  PSYS_PART_END_SCALE, <0.2, 0.2, 0.2>,
                                  PSYS_SRC_MAX_AGE, 0,
                                  PSYS_PART_MAX_AGE, 3.0,
                                  PSYS_SRC_BURST_RATE, 0.0,
                                  PSYS_SRC_BURST_PART_COUNT, 20
                                ]);
*/
/* From Flocking Birds */
                            llParticleSystem(
                                [ PSYS_PART_FLAGS, PSYS_PART_EMISSIVE_MASK |
                                    PSYS_PART_INTERP_COLOR_MASK |
                                    PSYS_PART_RIBBON_MASK,
                                  PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_DROP,
                                  PSYS_PART_START_COLOR, m_colour,
                                  PSYS_PART_END_COLOR, m_colour,
///                                  PSYS_PART_START_SCALE, <0.25, 0.25, 0.25>,
//                                  PSYS_PART_END_SCALE, <0.25, 0.25, 0.25>,
PSYS_PART_START_SCALE, <0.75, 0.75, 1>,
PSYS_PART_END_SCALE, <0.75, 0.75, 1>,
                                  PSYS_SRC_MAX_AGE, 0,
                                  PSYS_PART_MAX_AGE, 8.0,
                                  PSYS_SRC_BURST_RATE, 0.0,
                                  PSYS_SRC_BURST_PART_COUNT, 60
                                ]);
/* End Flocking Birds */
                        } else {
                            llParticleSystem([ ]);
                        }

                    //  UPDATE  --  Update mass position

                    } else if (ccmd == "UPDATE") {
if (llList2Integer(msg, 1) != m_index) {
    tawk(m_name + ": Huh?  Got update for wrong index: " + llList2CSV(msg));
    return;
}
if ((stepCount % 64) == 0) {
    stepTime = llGetTime();
}
//tawk(m_name + ":  " + llList2CSV(msg));
                        vector p = llGetPos();
                        vector npos = (vector) llList2String(msg, 2);
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
                            if (s_trails) {
                                flPlotLine(p, npos, m_colour, s_pwidth);
                            }
                            llSetLinkPrimitiveParamsFast(LINK_THIS,
                                [ PRIM_POSITION, npos ]);
if (paths) {
llSetLinkPrimitiveParamsFast(LINK_THIS,
    [ PRIM_ROTATION, llRotBetween(<0, 0, 1>, (npos - p)) ]);
}
stepMove++;
                        }
stepCount++;
/*  For benchmarks
if ((stepCount % 64) == 0) {
    float dt = llGetTime() - stepTime;
    tawk(m_name + ": Update time: " + (string) dt + "  (Step " + (string) stepCount + ", " +
        (string) stepMove + " moves)");
}
*/
                    }
                }
            }
        }
     }
