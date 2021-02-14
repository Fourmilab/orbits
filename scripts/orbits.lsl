
    /*

                    Orbit Plotter

        This modules handles plotting of orbits in two entirely
        different methods: tracing the orbit by placing temporary
        cylinder prims acting as line segments and creating an
        ellipse object (thin cylinder prim) scaled and rotated to
        the spatial extent and orientation of the orbit.
    */

    key owner;                          // Owner UUID
    key whoDat = NULL_KEY;              // Avatar who sent command

    integer massChannel = -982449822;   // Channel for communicating with planets

    integer ephHandle = 192523;         // Ephemeris handle for orbit tracing
    integer ephHandleEll = 192524;      // Ephemeris handle for ellipse fitting

    /*  Solar system body properties

            0   Orbital period (days)
            1   Eccentricity
            2   Semi-major axis (AU)
            3   Name
    */

    list bodies = [
        0, 0, 0,                                        "Sun",
        87.9691, 0.20563069, 0.38709893,                "Mercury",
        224.701, 0.00677323, 0.72333199,                "Venus",
        365.256363004, 0.01671022, 1.00000011,          "Earth",
        686.971, 0.09341233, 1.52366231,                "Mars",
        4332.59, 0.04839266, 5.20336301,                "Jupiter",
        10759.22, 0.05415060, 9.53707032,               "Saturn",
        30688.5, 0.04716771, 19.19126393,               "Uranus",
        60182.0, 0.00858587, 30.06896348,               "Neptune",
        90487.2769, 0.2502487, 39.4450697,              "Pluto",
        -1.0, 0, 0, "??MP??"                            // Minor planet tracked
    ];
    integer bodiesE = 4;            // Length of bodies entry

    /*  Galactic Centre source properties

            0   Source index (1, n)
            1   Name
            2   Orbital period (NaN if eccentricity >= 1)
            3,4 Periapse date
            5   Eccentricity
            6   Semi-major axis (NaN if eccentricity >= 1)
    */

    list gc_source = [ ];
    integer gc_sourceE = 7;         // Length of source entry

    //  Parameters for current orbit plotting task

    integer o_body;                     // Body
    list o_jd;                          // Julian day and fraction
    float o_auscale;                    // Astronomical unit scale factor
    integer o_nsegments;                // Number of segments to plot
    vector o_sunpos;                    // Position of Sun in region

    list mp_peri;                       // Time of perihelion for non-elliptical orbit
    float o_aulimit = 10;               // Orbit plotting limit in AU
    integer o_parahyper;                // Parabolic/hyperbolic orbit for tracked body ?

    integer o_bselect;                  // Select index for body
    integer o_csegment;                 // Current segment
    float o_timestep;                   // Time step per segment
    vector o_olast;                     // Location of previous segment

    float angsegMax = 0.0872664626;     // 5 * DEG_TO_RAD
    vector o_prevseg;                   // Previous segment of orbit plot
    list prev_o_jd;                     // Start time of previous segment
    float eff_timestep = 0;             // Effective time step from adaptive adjustment
    list o_enddate;                     // End date of orbit plot

    //  Command processor messages

    integer LM_CP_COMMAND = 223;        // Process command
    integer LM_CP_RESUME = 225;         // Resume script after command
    integer LM_CP_REMOVE = 226;         // Remove simulation objects

    //  Ephemeris calculator messages

    integer LM_EP_CALC = 431;           // Calculate ephemeris
    integer LM_EP_RESULT = 432;         // Ephemeris calculation result

    //  Minor planet messages

    integer LM_MP_TRACK = 571;          // Notify tracking minor planet

    //  Galactic centre messages

    integer LM_GC_SOURCES = 752;        // Report number of sources

    //  Orbit messages

    integer LM_OR_PLOT = 601;           // Plot orbit for body
    integer LM_OR_ELLIPSE = 602;        // Fit ellipse to body

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

    /*  compJD  --  Compare two Juilan days.  Returns:
                    a > b       1
                    a = b       0
                    a < b      -1   */

    integer compJD(list a, list b) {
        integer ai = llList2Integer(a, 0);
        float af = llList2Float(a, 1);
        integer bi = llList2Integer(b, 0);
        float bf = llList2Float(b, 1);

        if ((ai == bi) && (af == bf)) {
            return 0;
        }
        if ((ai > bi) || ((ai == bi) && (af > bf))) {
            return 1;
        }
        return -1;
    }

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

    //  apsides  --  Compute perihelion and aphelion of planet

    list apsTerms = [           // Apsis date from k value
        2451590, 0.257, 87, 0.96934963, 0,              // Mercury
        2451738, 0.233, 224, 0.7008188, -0.0000000327,  // Venus
        2451547, 0.507, 365, 0.2596358, 0.0000000156,   // Earth
        2452195, 0.026, 686, 0.9957857, -0.0000001187,  // Mars
        2455636, 0.936, 4332, 0.897065, 0.0001367,      // Jupiter
        2452830, 0.12, 10764, 0.21676, 0.000827,        // Saturn
        2470213, 0.5, 30694, 0.8767, -0.00541,          // Uranus
        2468895, 0.1, 60190, 0.33, 0.03429,             // Neptune
        2447654, 0.5293, 90487, 0.276927, 0             // Pluto
    ];

    list apsK = [               // k value from year and decimal
        4.15201, 2000.12,                               // Mercury
        1.62549, 2000.53,                               // Venus
        0.99997, 2000.01,                               // Earth
        0.53166, 2001.78,                               // Mars
        0.0843, 2011.2,                                 // Jupiter
        0.03393, 2003.52,                               // Saturn
        0.0119, 2051.1,                                 // Uranus
        0.00607, 2047.5,                                // Neptune
        0.004036, 1989.3478                             // Pluto
    ];

    list apsides(integer body, float year, integer apoapsis) {
        if (body < 10) {
            //  Major planet: use tables above
            body--;
            integer bx = body * 2;
            float k = llRound(llList2Float(apsK, bx) *
                                (year - llList2Float(apsK, bx + 1)));
            if (apoapsis) {
                k += 0.5;
            }
            bx = body * 5;
            integer jd = llList2Integer(apsTerms, bx);
            float jdf = ((llList2Float(apsTerms, bx + 4) * (k * k)) +
                         (llList2Float(apsTerms, bx + 3) * k) +
                         (llList2Float(apsTerms, bx + 2) * k)) +
                        llList2Float(apsTerms, bx + 1);
            integer jdfi = llFloor(jdf);
            jd += jdfi;
            jdf -= jdfi;
            return [ jd, jdf ];
        } else {
            //  Minor planet: compute from orbital elements
            integer bx = body * bodiesE;
            list tp = mp_peri;
            if (apoapsis) {
                //  Apoapsis time is periapsis plus half orbital period
                tp = sumJD(tp, llList2Float(bodies, bx) / 2);
            }
            return tp;
        }
    }

    //  flRezRegion  --  Rez object anywhere in region

    flRezRegion(string inventory, vector pos, vector vel,
                rotation rot, integer param) {
        vector crepos = llGetPos();
        /*  Magic number is based upon 10 m limit in llRezObject()
            from creating prim's position.  We allow a little
            safety margin due to Second Life's signature sloppiness.  */
        if (llVecDist(pos, crepos) <= 9.5) {
            llRezObject(inventory, pos, vel, rot, param);
        } else {
            //  It's ugly, but it gets you there
            llSetRegionPos(pos);
            llRezObject(inventory, pos, vel, rot, param);
            llSetRegionPos(crepos);
        }
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
        string lineObj = "flPlotLine Temporary";
        if (flPlotPerm) {
            lineObj = "flPlotLine Permanent";
        }
        flRezRegion(lineObj, midPoint, ZERO_VECTOR,
            llRotBetween(<0, 0, 1>, llVecNorm(toPoint - midPoint)),
            ((diax << 22) | (icolour << 10) | ilength)
        );
    }

    //  sphRect  --  Convert spherical (L, B, R) co-ordinates to rectangular

    vector sphRect(float l, float b, float r) {
        return < r * llCos(b) * llCos(l),
                 r * llCos(b) * llSin(l),
                 r * llSin(b) >;
    }

/*
    //  markerBall  --  Place a marker ball

    markerBall(vector where, float diameter, vector colour) {
        colour *= 255;
        integer sparam = (llRound((diameter - 0.01) * 100) << 24) |
            (llRound(colour.x) << 16) | (llRound(colour.y) << 8) |
            llRound(colour.z);
        flRezRegion("Marker ball", where,
                    ZERO_VECTOR, ZERO_ROTATION, sparam);
    }
*/

    //  createOrbitEllipse  --  Create an orbit ellipse object

    list orbitParams = [ ];             // Orbit ellipse parameters
    integer orbitParamsE = 6;           // Orbit parameters entry length

    createOrbitEllipse(string args) {
        list el = llJson2List(args);
        integer m_body = llList2Integer(el, 0);
        string m_name = llList2String(el, 1);
        vector m_periapse = (vector) llList2String(el, 2);
        vector m_apoapse = (vector) llList2String(el, 3);
        float m_a = llList2Float(el, 4);
        float m_e = llList2Float(el, 5);
        float s_auscale = llList2Float(el, 6);
        vector m_covertex = (vector) llList2String(el, 7);

        //  Parameters derived from elements

        vector c_centre = (m_periapse + m_apoapse) / 2; // Centre point
        float c_b = m_a * llSqrt(1 - (m_e * m_e));      // Semi-minor axis

//  Mark periapse, apoapse, co-vertex, centre, and normal
//markerBall(m_periapse, 0.1, <1, 0.25, 0.25>);       // Periapse: red
//markerBall(m_apoapse, 0.1, <0.25, 1, 0.25>);        // Apoapse: green
//markerBall(c_centre, 0.1, <1, 1, 0.25>);            // Centre: yellow
//markerBall(m_covertex, 0.1, <0.25, 0.25, 1>);       // Co-vertex: blue
// vector c_plnorm = llVecNorm(m_periapse - c_centre) %    // Normal to orbital plane
//    llVecNorm(m_covertex - c_centre);
//markerBall(c_centre + (c_plnorm * 0.15), 0.1, <1, 0.25, 1>);    // Normal to centre: magenta

        // Align ellipse semi-major axis with orbit's

        rotation c_rotation = llRotBetween(<1, 0, 0>, llVecNorm(m_periapse - c_centre));

        /*  At this point the two vertices of the ellipse
            are coincident with the periapse and apoapse of
            the orbit, and hence all that remains is to
            rotate the ellipse around this axis (its local X
            axis) until its local Y axis lines up with the
            co-vertex of the orbit.  Because llRotBetween() is
            the bad boy of LSL rotations, this is easier said
            than done.  llRotBetween() makes things line up,
            but it doesn't tell you *how*, so the ellipse prim
            may now be in any possible orientation with respect
            to where we want it to be.  It's trivially easy to
            determine the angle between the ellipse's X axis
            and the co-vertex vector, but another matter entirely
            to decide which way to rotate the thing in order to
            align them.  The following hackery accomplishes that.
            There may be a far simpler one- or two-liner which
            does the same thing, but so far it has eluded me.  */

        vector c_left = llRot2Left(c_rotation);         // Local Y axis after apsides alignment
//markerBall(c_centre + (c_left * (c_b * s_auscale)), 0.1, <0.5, 0.5, 0.5>);
        // Vector from centre to covertex on orbit
        vector v1 = llVecNorm(m_covertex - c_centre);
        //  Angle to rotate ellipse around its local X axis
        float plxang = llAsin(llVecMag(c_left % v1));
        //  Angle between Y axis and covertex normal and periapse: sign detects flip of ellipse
        float dmdot = llVecNorm(c_left % v1) * llVecNorm(m_periapse - c_centre);
        //  Angle between Y axis and covertex: detects ellipse inversion
        float ladot = llAcos(v1 * c_left);
        if (ladot > PI_BY_TWO) {
            dmdot = -dmdot;
        }
        c_rotation = llAxisAngle2Rot(<1, 0, 0>, (dmdot * plxang)) * c_rotation;

        //  Save parameters to be delivered when ellipse checks in

        orbitParams += [ m_body,                                    // 0    Body number
                         m_name,                                    // 1    Name
                         <m_a * 2 * s_auscale, c_b * 2 * s_auscale, 0.01>,  // 2    Size
                         ZERO_ROTATION,                             // 3    Rotation
                         <1, 1, 0.5>,                               // 4    Colour
                         0.25                                       // 5    Alpha
                       ];

        //  Create the orbit ellipse at the centre

        flRezRegion("Orbit ellipse", c_centre,
                    ZERO_VECTOR, c_rotation, m_body);
        llMessageLinked(LINK_THIS, LM_CP_RESUME, "", whoDat);
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

    integer processAuxCommand(key id, list oparams) {

        whoDat = id;            // Direct chat output to sender of command

        string message = llList2String(oparams, 0);
        list args = llParseString2List(llToLower(message), [ " " ], []);
        string command = llList2String(args, 0);    // The command

        //  Orbit body [ segments/ellipse [ permanent ] ]

        if (abbrP(command, "or")) {
            float s_auscale = llList2Float(oparams, 1);
            integer planetsPresent = llList2Integer(oparams, 2);
            integer gc_sources = llList2Integer(oparams, 3);
            vector deployerPos = (vector) llList2String(oparams, 4);
            list simEpoch = llList2List(oparams, 5, 6);

            //  Re-process arguments to preserve case and strings
            args = fixQuotes(llParseString2List(message, [ " " ], []));
            integer argn = llGetListLength(args);

            string body = llList2String(args, 1);

            /*  If we are displaying the Solar System model, allow the
                user to specify the name of the object, including a minor
                planet being tracked, by its (full and exact) name as
                well as number.  Note how we cleverly exclude the Sun
                along with no-find results.  */
            if (planetsPresent) {
                integer p = llListFindList(bodies, [ body ]);
                if (p > bodiesE) {
                    body = (string) ((p - 3) / bodiesE);
                }

            /*  If we are displaying the Galactic Centre model, similarly
                allow specifying the source by name.  */

            } else if (gc_source != [ ]) {
                integer p = llListFindList(gc_source, [ body ]);
                if (p > 0) {
                    body = (string) (((p - 1) / gc_sourceE) + 1);
                }
            }

            integer segments = 96;
            integer permanent = FALSE;
            if (argn > 2) {
                if (abbrP(llToLower(llList2String(args, 2)), "el")) {
                    segments = -999;
                } else {
                    segments = llList2Integer(args, 2);
                }
                if (argn > 3) {
                    permanent = abbrP(llToLower(llList2String(args, 3)), "pe");
                }
            }
            if (segments == -999) {
               llMessageLinked(LINK_THIS, LM_OR_ELLIPSE,
                    llList2CSV([ body,  llList2Integer(simEpoch, 0),
                                 llList2Float(simEpoch, 1), s_auscale,
                                 deployerPos, permanent ]), whoDat);
            } else {
                llMessageLinked(LINK_THIS, LM_OR_PLOT,
                    llList2CSV([ body,  llList2Integer(simEpoch, 0),
                                 llList2Float(simEpoch, 1), s_auscale, segments,
                                 deployerPos, permanent ]), whoDat);
            }

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

    default {

        on_rez(integer start_param) {
            llResetScript();
        }

        state_entry() {
            whoDat = owner = llGetOwner();
            //  Listen for messages from objects we create
            llListen(massChannel, "", NULL_KEY, "");
        }

        //  Process messages from other scripts

        link_message(integer sender, integer num, string str, key id) {

            //  LM_CP_COMMAND (223): Process auxiliary command

            if (num == LM_CP_COMMAND) {
                processAuxCommand(id, llJson2List(str));

            //  LM_CP_COMMAND (226): Remove model

            } if (num == LM_CP_REMOVE) {
                //  Drop tracking of Solar System minor planet
                integer bx = 10 * bodiesE;
                bodies = llListReplaceList(bodies, [ -1.0 ], bx, bx);
                gc_source = [ ];                // Remove Galactic Centre sources

            //  LM_OR_PLOT (601): Plot orbit

            } else if (num == LM_OR_PLOT) {
                list l = llCSV2List(str);
                o_body = llList2Integer(l, 0);          // Body
                o_auscale = llList2Float(l, 3);         // Astronomical unit scale factor
                o_nsegments = llList2Integer(l, 4);     // Number of segments to plot
                o_sunpos = (vector) llList2String(l, 5); // Position of Sun
                flPlotPerm = llList2Integer(l, 6);      // Use permanent lines ?
                integer gc = gc_source != [ ];          // Galactic Centre source ?
                integer gx = (o_body - 1) * gc_sourceE; // Source list index
                integer bx = o_body * bodiesE;          // Solar system body index

                o_csegment = 0;                     // Current segment being plotted

                float o_ecc;                        // Eccentricity
                float o_period;                     // Orbital period if o_ecc < 1
                if (gc) {
                    //  Galactic Centre source
                    o_bselect = (o_body << 16);
                    o_ecc = llList2Float(gc_source, gx + 5);
                    o_parahyper = o_ecc >= 1;
                    if (!o_parahyper) {
                        //  Convert years to days for period
                        o_period = llList2Float(gc_source, gx + 2) * 365.25;
                    } else {
                        mp_peri = llList2List(gc_source, gx + 3, gx + 4);
                    }
                } else {
                    //  Solar System body
                    o_bselect = 1 << o_body;
                    o_ecc = llList2Float(bodies, bx + 1);
                    if (!o_parahyper) {
                        o_period = llList2Float(bodies, bx);
                    }
                }
                if (o_parahyper) {
                    o_timestep = (2.5 * 365) / o_nsegments;
                } else {
                    o_timestep = o_period / o_nsegments;
                }
                if (!o_parahyper) {
                    o_jd = llList2List(l, 1, 2);    // Julian day and fraction
                    o_enddate = sumJD(o_jd, o_timestep * o_nsegments);
                } else {
                    /*  If the trajectory is parabolic or hyperbolic, begin
                        plotting at the start of the inbound arm toward the
                        periapse and plot to the end of the outbound arm.  */
                    o_jd = sumJD(mp_peri, -(o_timestep * o_nsegments));
                    o_enddate = sumJD(mp_peri, o_timestep * o_nsegments);
                }
                //  Ending date for orbit computation (or arm if open trajectory)
//tawk("Start date: " + llList2CSV(o_jd) + "  End date: " + llList2CSV(o_enddate));
                //  Start the first ephemeris calculation
                llMessageLinked(LINK_THIS, LM_EP_CALC,
                    llList2CSV([ o_bselect ] + o_jd + [ ephHandle ]), id);

            //  LM_EP_RESULT (432): Ephemeris calculation results

            } else if (num == LM_EP_RESULT) {
                list l = llCSV2List(str);
                integer body = llList2Integer(l, 0);        // Body
                integer gc = body >= 0x1000;                // Is this a Galactic Centre source ?
               //   Only process if handle is our own
               if (ephHandle == llList2Integer(l, -1)) {
                    vector where;
                    float L = llList2Float(l, 1);           // Ecliptical longitude
                    float B = llList2Float(l, 2);           // Ecliptical latitude
                    float R = llList2Float(l, 3);           // Radius
                    if (!gc) {
                        //  Solar System body
                        where = sphRect(L, B, R);
                    } else {
                        //  Galactic Centre source: already in rectangular co-ordinates
                        where = < L, B, R >;
                    }
                    vector rwhere = (where * o_auscale) + o_sunpos;
                    if (o_csegment == 0) {
                        //  This is the first point, just save for first segment
                        prev_o_jd = o_jd;
                    } else {
                        /*  This is the dreaded adaptive segment length
                            computation.  We calculate the angle between
                            this just-computed segment forms with the
                            previous segment.  If this exceeds angSegMax,
                            we conclude that we need more segments to avoid
                            a Jagged Orbit.  This is accomplished by dividing
                            the previously estimated o_timestep by a factor
                            determined by the extent the measured angle
                            exceeds the limit.  We then discard the
                            just-computed ephemeris position and start a
                            new computation with the reduced effective
                            time step, eff_timestep.  */

                        vector currseg = llVecNorm(rwhere - o_olast);
                        if (o_prevseg != ZERO_VECTOR) {
                            float angseg = llAcos(o_prevseg * currseg);
//tawk("Sector " + (string) o_csegment + " angle " + (string) (angseg * RAD_TO_DEG) +
//  "  JD " + llList2CSV(o_jd));
                            if ((angseg > angsegMax) && ((eff_timestep == 0) || (llFabs(eff_timestep) > 1))) {
                                integer splitseg = llCeil(angseg / angsegMax);
                                float j_timestep = o_timestep;
                                if (eff_timestep != 0) {
                                    j_timestep = eff_timestep;
                                }
                                eff_timestep = j_timestep / splitseg;
//tawk("  Split segment into " + (string) splitseg + " eff_timestep " + (string) eff_timestep +
//     " o_timestep " + (string) o_timestep);
                                o_jd = sumJD(prev_o_jd, eff_timestep);
                                llMessageLinked(LINK_THIS, LM_EP_CALC,
                                    llList2CSV([ o_bselect ] + o_jd + [ ephHandle ]), id);
                                //  Done until computation of reduced segment result appears
                                return;
                            } else {
                                eff_timestep = 0;
                            }
                        }
                        o_prevseg = currseg;

//tawk("Plot segment " + (string) o_csegment + " from " + (string) o_olast + " to " + (string) rwhere);
                        float meanZ = ((o_olast.z - o_sunpos.z) +
                            (rwhere.z - o_sunpos.z)) / 2;
                        vector segcol = <0, 0.75, 0>;
                        if (meanZ < 0) {
                            segcol = <0.75, 0, 0>;
                        }
                        flPlotLine(o_olast, rwhere, segcol, 0.01);
                    }
                    o_csegment++;
                    o_olast = rwhere;

                    if (compJD(o_jd, o_enddate) < 0) {
                        prev_o_jd = o_jd;
                        o_jd = sumJD(o_jd, o_timestep);
                        /*  If the time step would take us past the computed
                            o_enddate, adjust it to end at that time.  */
                        if (compJD(o_jd, o_enddate) > 0) {
                            o_jd = o_enddate;
                        }
                        llMessageLinked(LINK_THIS, LM_EP_CALC,
                            llList2CSV([ o_bselect ] + o_jd + [ ephHandle ]), id);
                    } else {
                        /*  We've reached the end of the orbit.  Resume script
                            if suspended.  */
                        llMessageLinked(LINK_THIS, LM_CP_RESUME, "", id);
                    }

                } else if (ephHandleEll == llList2Integer(l, -1)) {
                    /*  We're fitting an ellipse to the body's orbit
                        and have just received the body's periapse,
                        apoapse, and co-vertex location from its
                        ephemeris calculator.  Now we're ready to
                        create the ellipse to display the orbit.  */
                    integer body = llList2Integer(l, 0);        // Body
                    vector pXYZr;           // Periapse co-ordinates
                    vector aXYZr;           // Apoapse co-ordinates
                    vector cXYZr;           // Co-vertex co-ordinates
                    float m_a;              // Semi-major axis
                    float m_e;              // Eccentricity
                    if (!gc) {
                        vector wXYZ = sphRect(llList2Float(l, 1),   // Peri L
                                              llList2Float(l, 2),   // Peri B
                                              llList2Float(l, 3));  // Peri R
                        pXYZr = (wXYZ * o_auscale) + o_sunpos;
                        wXYZ = sphRect(llList2Float(l, 4),          // Apo  L
                                       llList2Float(l, 5),          // Apo  B
                                       llList2Float(l, 6));         // Apo  R
                        aXYZr = (wXYZ * o_auscale) + o_sunpos;
                        wXYZ = sphRect(llList2Float(l, 7),          // Cvtx L
                                       llList2Float(l, 8),          // Cvtx B
                                       llList2Float(l, 9));         // Cvtx R
                        cXYZr = (wXYZ * o_auscale) + o_sunpos;
                        m_a = llList2Float(bodies, (body * bodiesE) + 2);
                        m_e = llList2Float(bodies, (body * bodiesE) + 1);
                    } else {
                        /*  The Galactic Centre module returns galactic
                            rectangular co-ordinates, so they may be used
                            directly without transformation from spherical.  */
                        pXYZr = (< llList2Float(l, 1),
                                   llList2Float(l, 2),
                                   llList2Float(l, 3) > * o_auscale) + o_sunpos;
                        aXYZr = (< llList2Float(l, 4),
                                   llList2Float(l, 5),
                                   llList2Float(l, 6) > * o_auscale) + o_sunpos;
                        cXYZr = (< llList2Float(l, 7),
                                   llList2Float(l, 8),
                                   llList2Float(l, 9) > * o_auscale) + o_sunpos;
                        integer gx = ((body >> 16) - 1) * gc_sourceE; // Source list index
                        m_a = llList2Float(gc_source, gx + 6);
                        m_e = llList2Float(gc_source, gx + 5);
                    }
                    string ellargs = llList2Json(JSON_ARRAY, [
                        body,                       // 0    Body number
                        "Planet " + (string) body,  // 1    Body name
                        pXYZr,                      // 2    Periapse location
                        aXYZr,                      // 3    Apoapse location
                        m_a,                        // 4    Semi-major axis
                        m_e,                        // 5    Eccentricity
                        o_auscale,                  // 6    Astronomical unit scale factor
                        cXYZr                       // 7    Co-vertex location
                    ]);
                    createOrbitEllipse(ellargs);
                    llMessageLinked(LINK_THIS, LM_CP_RESUME, "", id);
               }

            //  LM_MP_TRACK (571): Tracking minor planet

            } else if (num == LM_MP_TRACK) {
                /*  The main thing we care about is a minor planet's
                    orbital period.  If it's undefined, we must resort
                    to "other means" when plotting the orbit.  */
                list args = llJson2List(str);
                if (llList2Integer(args, 0)) {
                    integer bx = 10 * bodiesE;
                    //  Plug the tracked body's name and elements into the bodies list
                    float ecc = llList2Float(args, 7);
                    bodies = llListReplaceList(bodies,
                        [ llList2Float(args, 2),        // Orbital period
                          ecc,                          // Eccentricity
                          llList2Float(args, 6),        // Semi-major axis
                          llList2String(args, 1)        // Name
                        ], bx, bx + 3);
                    o_parahyper = ecc >= 1;
                    mp_peri = llList2List(args, 4, 5);  // Perihelion date and fraction
                } else {
                    //  Dropping tracking of current object
                    integer bx = 10 * bodiesE;
                    bodies = llListReplaceList(bodies,
                        [ -1.0, 0, 0, "??MP??"  ], bx, bx + 3);
                }

            //  LM_OR_ELLIPSE (602): Plot orbit ellipse

            } else if (num == LM_OR_ELLIPSE) {
                list l = llCSV2List(str);
                integer body = llList2Integer(l, 0);
                o_jd = llList2List(l, 1, 2);                    // Julian day and fraction
                o_auscale = llList2Float(l, 3);                 // Astronomical unit scale factor
                o_sunpos = (vector) llList2String(l, 4);        // Position of Sun

                list edate = jyearl(llList2List(l, 1, 2));
                /*  Compute approximate year and fraction from
                    month and day.  This is a rough approximation,
                    so there's no need to go back and do it with
                    full Julian day arithmetic.  */
                float eyear = llList2Integer(edate, 0) +
                              ((llList2Integer(edate, 1) - 1) / 12.0) +
                              ((llList2Integer(edate, 2) - 1) / 30.0);

                integer gc = gc_source != [ ];          // Galactic Centre source ?
                integer gx = (body - 1) * gc_sourceE;   // Source list index
                integer bx = body * bodiesE;            // Solar system body index

                //  Get dates of periapse and apoapse
                list dPeri;             // Periapse date
                list dApo;              // Apoapse date
                list dCvtx;             // Co-vertex date
                float m_e;              // Eccentricity
                float o_period;         // Orbital period
                if (gc) {
                    //  Galactic Centre source
                    o_bselect = (body << 16);
                    m_e = llList2Float(gc_source, gx + 5);              // Eccentricity
                    dPeri = llList2List(gc_source, gx + 3, gx + 4);     // Periapse date
                    if (m_e < 1) {      // Avoid math error is period is NaN for open trajectory
                        o_period = llList2Float(gc_source, gx + 2) * 365.25;    // Orbital period
                    }
                    dApo = sumJD(dPeri, o_period / 2);                  // Apoapse date
                } else {
                    //  Solar System body
                    o_bselect = 1 << body;
                    m_e = llList2Float(bodies, bx + 1);                 // Eccentricity
                    if (m_e < 1) {      // Avoid math error for undefined period
                        dPeri = apsides(body, eyear, FALSE);
                        dApo = apsides(body, eyear, TRUE);
                        o_period = llList2Float(bodies, bx);            // Orbital period
                    }
                }
                //  If eccentricity is >= 1, we can't fit an ellipse
                if (m_e >= 1) {
                    tawk("Cannot fit an ellipse.  Eccentricity is " + (string) m_e + ".");
                    llMessageLinked(LINK_THIS, LM_CP_RESUME, "", id);
                    return;
                }
                dCvtx = sumJD(dPeri,                                        // Compute co-vertex date
                              o_period * (0.25 - (m_e / TWO_PI)));
                list ephreq = [ o_bselect ] + dPeri + dApo + dCvtx + [ ephHandleEll ];
                llMessageLinked(LINK_THIS, LM_EP_CALC, llList2CSV(ephreq), id);

            //  LM_GC_SOURCES (752): Adding Galactic Centre source

            } else if (num == LM_GC_SOURCES) {
                /*  The main thing we care about is a source's
                    orbital period and perhielion date.  If its
                    eccentricity is >= 1, the orbital period is
                    undefined (NaN) and we plot an open
                    trajectory.  We also save the semi-major axis
                    (if defined) in case we'll be fitting an
                    ellipse.  */
                list args = llJson2List(str);
                if (llList2Integer(args, 1) > 0) {
                    gc_source += llList2List(args, 1, gc_sourceE);
                }
            }
        }

        //  The listen event handles message from objects we create

        listen(integer channel, string name, key id, string message) {
//llOwnerSay(llGetScriptName() + " channel " + (string) channel + " id " + (string) id +  " message " + message);
            if (channel == massChannel) {
                list msg = llJson2List(message);
                string ccmd = llList2String(msg, 0);

                if (ccmd == "ORBITAL") {
                    integer m_index = llList2Integer(msg, 1);
                    integer i;
                    integer n = llGetListLength(orbitParams);

                    for (i = 0; i < n; i += orbitParamsE) {
                        if (llList2Integer(orbitParams, i) == m_index) {
                            llRegionSayTo(id, massChannel,
                                llList2Json(JSON_ARRAY, [ "ORBITING" ] +
                                    llList2List(orbitParams, i, i + (orbitParamsE - 1))));
                            //  Delete this item from orbitParams
                            orbitParams = llDeleteSubList(orbitParams, i, i + (orbitParamsE - 1));
                            return;
                        }
                    }
//tawk("Unable to find orbitParams for mass " + (string) m_index);
                }
            }
        }
    }
