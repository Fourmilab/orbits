    /*
                     Fourmilab Gravitation

                        by John Walker
    */

    key owner;                          //  Owner UUID
    string ownerName;                   //  Name of owner

    integer commandChannel = 222;       // Command channel in chat
    integer commandH;                   // Handle for command channel
    key whoDat = NULL_KEY;              // Avatar who sent command
    integer restrictAccess = 2;         // Access restriction: 0 none, 1 group, 2 owner
    integer echo = TRUE;                // Echo chat and script commands ?

    integer massChannel = -982449822;   // Channel for communicating with bodies
    integer massChH;                    // Mass channel listener handle
    string ypres = "B?+:$$";            // It's pronounced "Wipers"
    string planecrash = "P?+:$$";       // Selectively delete ecliptic plane

    //  Script processing

    integer scriptActive = FALSE;       // Are we reading from a script ?
    integer scriptSuspend = FALSE;      // Suspend script execution for asynchronous event

    //  Settings

    integer trace = FALSE;              // Trace mass behaviour
    integer paths = FALSE;              // Show particle trails from masss ?

    integer hidden = 2;                 // Is the deployer hidden ?

    //  Parameters for the solar system model

    //  Names of solar system objects, corresponding to objects in inventory
    list solarSystem = [
        "Sun", "Mercury", "Venus", "Earth", "Mars",
        "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto",
        "??MP??"
    ];

    //  Keys of planets (filled in as they are rezzed)
    list planetKeys = [ NULL_KEY, NULL_KEY, NULL_KEY, NULL_KEY, NULL_KEY,
                        NULL_KEY, NULL_KEY, NULL_KEY, NULL_KEY, NULL_KEY,
                        NULL_KEY ];

    //  Bit mask of planets present, used to request ephemeris
    integer planetsPresent = 0;

    /* This program works in a somewhat unconventional system of units.
       Length is measured in astronomical units (the mean distance from
       the Earth to the Sun), mass in units of the mass of the Sun, and
       time in years.  The following definitions derive the value of the
       gravitational constant in this system of units from its handbook
       definition in SI units. */

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

    /*  mParams entry:
            0       Name
            1       Position        Astronomical units (AU)
            2       Velocity        AU / year
            3       Mass            Solar masses
            4       Colour          Colour (extended)
            5       Radius          Mean radius (km)
            6       DeployerPos     Region co-ordinates of deployer
            7       MassKey         Key of mass object  */
    integer mParamsE = 8;               // Mass parameters entry length
    list mParams = [ ];                 // Mass parameters

    //  Settings communicated by deployer
    float s_kaboom = 50;                // Self destruct if this far (AU) from deployer
    float s_auscale = 0.3;              // Astronomical unit scale
    float s_radscale = 0.0000025;       // Radius scale
    integer s_trails = FALSE;           // Show trails with temporary prims
    float s_pwidth = 0.01;              // Paths/trails width
    float s_mindist = 0.01;             // Minimum distance to update

    float m_scalePlanet = 0.1;          // Scale of planet objects
    float m_scaleStar = 0.00133333;     // Scale of star objects

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

    integer stepNumber = 0;             // Step counter
    float stepsize = 0.1;       // Motion step size factor
//    float stepmin = 0.00001;    // Smallest step to use
//float stepmin = 0.01;    // Smallest step to use
float stepmin = 0.001; // INNER SYSTEM
    float simTime = 0;                  // Simulation time (years)
float ldeltat;
float collideDist = 0.0001;             // Criterion for declaring collision

    integer runmode = FALSE;            // Running the simulation ?
    float tickTime = 0.01;              // Simulation update time
    integer stepLimit = 0;              // Simulation step counter
    list simEpoch;                      // Simulation epoch (jd, jdf)

    //  Script Processor messages

    integer LM_SP_INIT = 50;            // Initialise
    integer LM_SP_RESET = 51;           // Reset script
    integer LM_SP_STAT = 52;            // Print status
//  integer LM_SP_RUN = 53;             // Enqueue script as input source
    integer LM_SP_GET = 54;             // Request next line from script
    integer LM_SP_INPUT = 55;           // Input line from script
    integer LM_SP_EOF = 56;             // Script input at end of file
    integer LM_SP_READY = 57;           // Script ready to read
    integer LM_SP_ERROR = 58;           // Requested operation failed

    //  Command processor messages

    integer LM_CP_COMMAND = 223;        // Process command
    integer LM_CP_RESUME = 225;         // Resume script after command

    //  Ephemeris calculator messages

    integer LM_EP_CALC = 431;           // Calculate ephemeris
    integer LM_EP_RESULT = 432;         // Ephemeris calculation result
    integer LM_EP_STAT = 433;           // Print memory status

    //  Auxiliary services messages

    integer LM_AS_LEGEND = 541;         // Update floating text legend

    //  Minor planet messages

    integer LM_MP_TRACK = 571;          // Notify tracking minor planet

    //  Orbit messages

    integer LM_OR_PLOT = 601;           // Plot orbit for body
    integer LM_OR_ELLIPSE = 602;        // Fit ellipse to body
    integer LM_OR_STAT = 604;           // Print status

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

    /*  sendSettings  --  Send settings to mass(es).  If mass is
                          nonzero, the message is directed to
                          that specific mass.  If zero, it is
                          a broadcast to all masses, and the id
                          argument is ignored.  */

    sendSettings(key id, integer mass) {
        string msg = llList2Json(JSON_ARRAY, [ "SETTINGS", mass,
                            paths,
                            trace,
                            hf(s_kaboom),
                            hf(s_auscale),
                            hf(s_radscale),
                            s_trails,
                            hf(s_pwidth),
                            hf(s_mindist)
                      ]);
        if (mass == 0) {
            llRegionSay(massChannel, msg);
        } else {
            llRegionSayTo(id, massChannel, msg);
        }
    }

    //  updateLegend  --  Update legend above deployer

    updateLegend() {
        if (s_legend) {
            llMessageLinked(LINK_THIS, LM_AS_LEGEND,
                llList2Json(JSON_ARRAY, [
                    llGetListLength(mParams) > 0,       // 0  Numerical integration ?
                    simTime,                            // 1    Integration years
                    stepNumber,                         // 2    Step number
                                                        //    Planetary theory ?
                    (planetsPresent & (1 << 10) != 0),  // 3    Tracking minor planet ?
                    llList2String(solarSystem, 10) ] +  // 4    Name of minor planet, if any
                    simEpoch                            // 5,6  Simulation epoch
                ), whoDat);
        }
    }

    /*  Copyright Strife Onizuka, 2006-2007, LGPL,
        http://www.gnu.org/copyleft/lesser.html or (cc-by)
        http://creativecommons.org/licenses/by/3.0/  */

    string hv(vector v) {
        return "<" + hf(v.x) + "," +
                     hf(v.y) + "," +
                     hf(v.z) + ">";
    }

    string hexc = "0123456789ABCDEF";

    /*  We rename Float2Hex to hf() to avoid cluttering the
        many places we use it.  */
    string hf(float input) {
        if (input != (integer) input) {
            string str = (string)input;
            if (!~llSubStringIndex(str, ".")) {
                //  NaN or Infinities
                return str;
            }
            float unsigned = llFabs(input);
            integer exponent = llFloor((llLog(unsigned) / 0.69314718055994530941723212145818));

            //  Shift mantissa into integer range
            integer mantissa = (integer) ((unsigned /
                ((float) ("0x1p" + (string) (exponent -= ((exponent >> 31) | 1))))) * 0x4000000);
            //  Index of first one bit in mantissa
            integer index = (integer) (llLog(mantissa & -mantissa) / 0.69314718055994530941723212145818);
            str = "p" + (string) (exponent + index - 26);
            mantissa = mantissa >> index;
            do {
                str = llGetSubString(hexc, 15 & mantissa, 15 & mantissa) + str;
            } while ((mantissa = mantissa >> 4));

            if (input < 0) {
                return "-0x" + str;
            }
            return "0x" + str;
        }
        //  It's an integral value: just return decimal integer string
        return llDeleteSubString((string) input, -7, -1);
    }

    /*  JDATE  --   Compute Julian date and fraction from UTC
                    date and time. Warning: the mon argument is
                    a month index (0-11) as used in the Unix
                    struct tm, not a month number as in ISO
                    8601.  We return the whole day number and
                    fraction as an integer and float in a list
                    because a single precision float doesn't
                    have sufficient significant digits to
                    represent Julian day and fraction.  */

    list jdate(integer year, integer mon, integer mday,
                integer hour, integer min, integer sec) {
        /*  Algorithm as given in Meeus, Astronomical Algorithms 2nd ed.,
            Chapter 7, page 61, with serious hackery to cope with the
            limits of single precision floats.  */

        integer a;
        integer b;

        integer m = mon + 1;
        integer y = year;

        if (m <= 2) {
            y--;
            m += 12;
        }

        /* Determine whether date is in Julian or Gregorian calendar based on
           canonical date of calendar reform. */

        if ((year < 1582) || ((year == 1582) && ((mon < 9) ||
            ((mon == 9) && (mday < 5))))) {
            b = 0;
        } else {
            a = y / 100;
            b = 2 - a + (a / 4);
        }

        integer dwhole = llFloor(365.25 * (y + 4716)) + llFloor(30.6001 * (m + 1)) +
            mday + b - 1524;
        float dfrac = ((sec + 60 * (min + (60 * hour))) / 86400.0) - 0.5;
        if (dfrac < 0) {
            dwhole--;
            dfrac += 1;
        }

        return [ dwhole, dfrac ];
    }

    //  JDSTAMP  --  Get Julian date from an llGetTimestamp() string

    list jdstamp(string s) {
        list t = llParseString2List(s, ["-", "T", ":", "."], []);

        return jdate(llList2Integer(t, 0), llList2Integer(t, 1) - 1, llList2Integer(t, 2),
                     llList2Integer(t, 3), llList2Integer(t, 4), llList2Integer(t, 5));
    }

/*
    //  dynFK5  --  Convert co-ordinates from VSOP87 dynamic to FK5

    list dynFK5(integer jd, float jdf, float l, float b) {
        integer J2000 = 2451545;                // Julian day of J2000 epoch
        float JulianCentury = 36525.0;          // Days in Julian century
        float ASTOR = PI / (180.0 * 3600.0);    // Arc-seconds to radian

        float jc = ((jd - J2000) / JulianCentury) + (jdf / JulianCentury);

        float lprime = l - (DEG_TO_RAD * ((1.397 * jc) + (0.00031 * jc * jc)));
        l += ASTOR * (-0.09033 + (0.03916 * llTan(b) * (llCos(lprime) + llSin(lprime))));
        b += ASTOR * (0.03916 * (llCos(lprime) - llSin(lprime)));

        return [ l, b ];
    }
*/

    //  sphRect  --  Convert spherical (L, B, R) co-ordinates to rectangular

    vector sphRect(float l, float b, float r) {
        return < r * llCos(b) * llCos(l),
                 r * llCos(b) * llSin(l),
                 r * llSin(b) >;
    }

    /*  updateEphemeris  --  Update ephemeris for selected bodies.  This
                             simply initiates the update process, which is
                             performed asynchronously by the individual
                             ephemeris calculation scripts, which return
                             their results via LM_EP_RESULT messages.  When
                             all results have arrived, the message handler
                             will initiate the action prescribed by ephTask.  */

    list ephBodies;                 // List of ephemeris results
    integer ephRequests;            // Ephemeris bodies requested
    integer ephReplies;             // Ephemeris bodies who have replied
    string ephTask;                 // Task to run when ephemeris received
    integer ephHandle = 192521;     // Handle for ephemeris requests

float ephCalcStart;
    updateEphemeris(integer bodies, integer jd, float jdf) {
//tawk("updateEphemeris for " + (string) jd +  " + "  + (string) jdf);
ephCalcStart = llGetTime();
        ephRequests = bodies;
        ephReplies = 0;
        ephBodies = [ ];
        integer i;
        for (i = 0; i < 10; i++) {
            ephBodies += [ 0, 0, 0 ];
        }
        llMessageLinked(LINK_THIS, LM_EP_CALC,
            llList2CSV([ bodies, jd, jdf, ephHandle ]), whoDat);
    }

    //  updatePlanets  --  Update planets and tracked bodies to simEpoch

    updatePlanets() {
        ephTask = "update";
        integer trackedp = planetsPresent & (1 << 10);
        updateEphemeris(((1 << 10) - 2) | trackedp,
            llList2Integer(simEpoch, 0), llList2Float(simEpoch, 1));
    }

    //  checkAccess  --  Check if user has permission to send commands

    integer checkAccess(key id) {
        return (restrictAccess == 0) ||
               ((restrictAccess == 1) && llSameGroup(id)) ||
               (id == llGetOwner());
    }

    //  abbrP  --  Test if string matches abbreviation

    integer abbrP(string str, string abbr) {
        return abbr == llGetSubString(str, 0, llStringLength(abbr) - 1);
    }

    //  onOff  --  Parse an on/off parameter

    integer onOff(string param) {
        if (abbrP(param, "on")) {
            return TRUE;
        } else if (abbrP(param, "of")) {
            return FALSE;
        } else {
            tawk("Error: please specify on or off.");
            return -1;
        }
    }

    //  eOnOff  --  Edit an on/off parameter

    string eOnOff(integer p) {
        if (p) {
            return "on";
        }
        return "off";
    }

    /*  inventoryName  --   Extract inventory item name from Set subcmd.
                            This is a horrific kludge which allows
                            names to be upper and lower case.  It finds the
                            subcommand in the lower case command then
                            extracts the text that follows, trimming leading
                            and trailing blanks, from the upper and lower
                            case original command.   */

    string inventoryName(string subcmd, string lmessage, string message) {
        //  Find subcommand in Set subcmd ...
        integer dindex = llSubStringIndex(lmessage, subcmd);
        //  Advance past space after subcmd
        integer di = llSubStringIndex(llGetSubString(lmessage, dindex, -1), " ");
        if (di < 0) {
            return "";
        }
        dindex += di + 1;
        //  Note that STRING_TRIM elides any leading and trailing spaces
        return llStringTrim(llGetSubString(message, dindex, -1), STRING_TRIM);
    }

    /*  fixArgs  --  Transform command arguments into canonical form.
                     All white space within vector is elided so they
                     will be parsed as single arguments.  */

    string fixArgs(string cmd) {
        cmd = llStringTrim(cmd, STRING_TRIM);
        integer l = llStringLength(cmd);
        integer inbrack = FALSE;
        integer i;
        string fcmd = "";

        for (i = 0; i < l; i++) {
            string c = llGetSubString(cmd, i, i);
            if (inbrack && (c == ">")) {
                inbrack = FALSE;
            }
            if (c == "<") {
                inbrack = TRUE;
            }
            if (!((c == " ") && inbrack)) {
                fcmd += c;
            }
        }
        return fcmd;
    }

    /*  pinterval  --  Parse an interval specification.
                       By default, an interval is in years,
                       but may be specified in other units
                       via the following suffixes:
                            h       Hour
                            d       Day
                            w       Week (1/52 year)
                            m       Month (1/12 year)
                            y       Year (default)
                            D       Decade
                            C       Century  */

    float pinterval(string intv) {
        string unit = llGetSubString(intv, -1, -1);

        if (llSubStringIndex("hdwmDC", unit) >= 0) {
            intv = llGetSubString(intv, 0, -2);
        } else {
            unit = "y";
        }

        float interval = (float) intv;

        //  Note that years are implicit
        if (unit == "h") {
            interval /= 365 * 24;
        } else if (unit == "d") {
            interval /= 365;
        } else if (unit == "w") {
            interval /= 52;
        } else if (unit == "m") {
            interval /= 12;
        } else if (unit == "D") {
            interval *= 10;
        } else if (unit == "C") {
            interval *= 100;
        }
        return interval;
    }

    /*  scriptResume  --  Resume script execution when asynchronous
                          command completes.  */
    scriptResume() {
        if (scriptActive) {
            if (scriptSuspend) {
                scriptSuspend = FALSE;
                llMessageLinked(LINK_THIS, LM_SP_GET, "", NULL_KEY);
                if (trace) {
                    tawk("Script resumed.");
                }
            }
        }
    }

    //  processCommand  --  Process a command

    integer processCommand(key id, string message, integer fromScript) {

        if (!checkAccess(id)) {
            llRegionSayTo(id, PUBLIC_CHANNEL,
                "You do not have permission to control this object.");
            return FALSE;
        }

        whoDat = id;            // Direct chat output to sender of command

        /*  If echo is enabled, echo command to sender unless
            prefixed with "@".  The command is prefixed with ">>"
            if entered from chat or "++" if from a script.  */

        integer echoCmd = TRUE;
        if (llGetSubString(llStringTrim(message, STRING_TRIM_HEAD), 0, 0) == "@") {
            echoCmd = FALSE;
            message = llGetSubString(llStringTrim(message, STRING_TRIM_HEAD), 1, -1);
        }
        if (echo && echoCmd) {
            string prefix = ">> ";
            if (fromScript) {
                prefix = "++ ";
            }
            tawk(prefix + message);                 // Echo command to sender
        }

//        string lmessage = llToLower(llStringTrim(message, STRING_TRIM));
        string lmessage = fixArgs(llToLower(message));
        list args = llParseString2List(lmessage, [" "], []);    // Command and arguments
        integer argn = llGetListLength(args);       // Number of arguments
        string command = llList2String(args, 0);    // The command
        string sparam = llList2String(args, 1);     // First argument, for convenience

        //  Access who                  Restrict chat command access to public/group/owner

        if (abbrP(command, "ac")) {
            string who = sparam;

            if (abbrP(who, "p")) {          // Public
                restrictAccess = 0;
            } else if (abbrP(who, "g")) {   // Group
                restrictAccess = 1;
            } else if (abbrP(who, "o")) {   // Owner
                restrictAccess = 2;
            } else {
                tawk("Unknown access restriction \"" + who +
                    "\".  Valid: public, group, owner.\n");
                return FALSE;
            }

        //  Boot                    Reset the script to initial settings

        } else if (abbrP(command, "bo")) {
            //  Reset the script processor
            llMessageLinked(LINK_THIS, LM_SP_RESET, "", whoDat);
            llResetOtherScript("Minor Planets");
            llResetOtherScript("Orbits");
//  MAYBE SEND A LM_CP_BOOT TO MASS RESET EPHEMERIS SCRIPTS ?
            llResetScript();

        /*  Channel n               Change command channel.  Note that
                                    the channel change is lost on a
                                    script reset.  */
        } else if (abbrP(command, "ch")) {
            integer newch = (integer) sparam;
            if ((newch < 2)) {
                tawk("Invalid channel " + (string) newch + ".");
                return FALSE;
            } else {
                llListenRemove(commandH);
                commandChannel = newch;
                commandH = llListen(commandChannel, "", NULL_KEY, "");
                tawk("Listening on /" + (string) commandChannel);
            }

        //  Echo message                Display message

        } else if (abbrP(command, "ec")) {
            string msg = inventoryName("ec", lmessage, message);
            if (msg == "") {
                msg = " ";
            }
            tawk(msg);

        //  Epoch now                       Set date to current time
        //  Epoch yyyy-mm-dd hh:mm:ss       Set date to civil date
        //  Epoch jjjjjjjjjj.ffff           Set date to Julian day

        } else if (abbrP(command, "ep")) {
            integer goof = FALSE;
            if (argn >= 2) {
                string td = sparam;
                if (abbrP(td, "no")) {
                    simEpoch = jdstamp(llGetTimestamp());
                } else if (llSubStringIndex(td, "-") >= 0) {
                    list ymd = llParseString2List(td, ["-"], []);
                    integer yyyy;
                    integer mm;
                    integer dd;
                    integer HH = 0;
                    integer MM = 0;
                    integer SS = 0;
                    if (llGetListLength(ymd) >= 3) {
                        yyyy = (integer) llList2String(ymd, 0);
                        mm = (integer) llList2String(ymd, 1);
                        dd = (integer) llList2String(ymd, 2);
                        if (argn >= 3) {
                            string hm = llList2String(args, 2);
                            if (llSubStringIndex(hm, ":") >= 0) {
                                list hms = llParseString2List(hm, [":"], []);
                                HH = (integer) llList2String(hms, 0);
                                MM = (integer) llList2String(hms, 1);
                                SS = (integer) llList2String(hms, 2);
                            } else {
                                goof = TRUE;
                            }
                        }
                    } else {
                        goof = TRUE;
                    }
                    if (!goof) {
                        simEpoch = jdate(yyyy, mm - 1, dd, HH, MM, SS);
                    }
                } else if (llSubStringIndex(td, ".") >= 0) {
                    list jf = llParseString2List(td, ["."], []);
                    simEpoch = [ (float) llList2String(jf, 0),
                                (float) ("0." + llList2String(jf, 1)) ];
                } else if (((integer) llGetSubString(td, 0, 0)) > 0) {
                    simEpoch = [ (integer) td, 0.0 ];
                } else {
                    goof = TRUE;
                }
            } else {
                goof = TRUE;
            }
            if (goof) {
                tawk("Usage: set date yyyy-mm-dd hh:mm:ss / jjjjjjjj.ffff");
                return FALSE;
            } else {
                updatePlanets();
            }

        //  List [ mass mass... ]   List masses in region or specific masses

        } else if (abbrP(command, "li")) {
            if (argn < 2) {
                llRegionSay(massChannel,llList2Json(JSON_ARRAY, [ "LIST", 0 ]));
            } else {
                integer b;

                for (b = 1; b < argn; b++) {
                    llRegionSay(massChannel,llList2Json(JSON_ARRAY,
                        [ "LIST", llList2Integer(args, b) ]));
                }
            }

        //  Mass name position velocity mass colour radius

        } else if (abbrP(command, "ma")) {
            if (runmode) {
                tawk("Cannot add a mass while running.");
                return FALSE;
            }

            string name = sparam;
            vector where = (vector) llList2String(args, 2);

            vector eggPos = llGetPos();
            mParams += [ name, where, (vector) llList2String(args, 3),
                         (float) llList2String(args, 4),
                         /*  Note that we save the colour specification as a
                             string rather than a vector, which allows
                             passing our extended specification, including
                             alpha and glow, to the mass once it is created.  */
                         llList2String(args, 5),
                         (float) llList2String(args, 6),
                         eggPos + <0, 0, s_zoffset>,
                         NULL_KEY               // We don't yet know the key
                       ];

            where = (where * s_auscale) + eggPos + <0, 0, s_zoffset>;
            llSetRegionPos(where);
            if (trace) {
                tawk("Deploying " + name + " at " + (string) where);
            }
            llRezObject("Mass", where, ZERO_VECTOR,
//                ZERO_ROTATION,
llEuler2Rot(<PI_BY_TWO, 0, 0>),
                llGetListLength(mParams) / mParamsE);
            llSetRegionPos(eggPos);

        //  Orbit body [ segments/ellipse [ permanent ] ]

        } else if (abbrP(command, "or")) {
            integer body = (integer) sparam;
            integer segments = 96;
            integer permanent = FALSE;
            if (argn > 2) {
                if (abbrP(llList2String(args, 2), "el")) {
                    segments = -999;
                } else {
                    segments = llList2Integer(args, 2);
                }
                if (argn > 3) {
                    permanent = abbrP(llList2String(args, 3), "pe");
                }
            }
            if (segments == -999) {
               llMessageLinked(LINK_THIS, LM_OR_ELLIPSE,
                    llList2CSV([ body,  llList2Integer(simEpoch, 0),
                                 llList2Float(simEpoch, 1), s_auscale,
                                 llGetPos() + <0, 0, s_zoffset>, permanent ]), whoDat);
            } else {
                llMessageLinked(LINK_THIS, LM_OR_PLOT,
                    llList2CSV([ body,  llList2Integer(simEpoch, 0),
                                 llList2Float(simEpoch, 1), s_auscale, segments,
                                 llGetPos() + <0, 0, s_zoffset>, permanent ]), whoDat);
            }
            scriptSuspend = TRUE;

        //  Planet

        } else if (abbrP(command, "pl")) {
            if (runmode) {
                tawk("Cannot add a planet while running.");
                return FALSE;
            }

            integer plstart;
            integer plend;

            if (argn > 1) {
                plstart = plend = (integer) sparam;
            } else {
                plstart = 0;
                plend = 9;
            }

            integer plno;

            for (plno = plstart; plno <= plend; plno++) {
                string name = llList2String(solarSystem, plno);
                vector where = sphRect(
                    llList2Float(ephBodies, plno * 3),
                    llList2Float(ephBodies, (plno * 3) + 1),
                    llList2Float(ephBodies, (plno * 3) + 2));

                vector eggPos = llGetPos();

                where = (where * s_auscale) + eggPos + <0, 0, s_zoffset>;
                llSetRegionPos(where);
                if (trace) {
                    tawk("Deploying " + name + " at " + (string) where);
                }

                /*  Kludge: since zero indicates a manual rez of a planet
                    body, we use -1 as the start parameter for the Sun,
                    whose "planet number" is zero.  It converts it back
                    upon receipt.  */

                integer sp = plno;
                if (plno == 0) {
                    sp = -1;
                }
                llRezObject("S: " + name, where, ZERO_VECTOR,
                    llEuler2Rot(<0, PI_BY_TWO, 0>), sp);
                llSetRegionPos(eggPos);
            }

        //  Remove                  Remove all masses

        } else if (abbrP(command, "re")) {
            setRun(FALSE);
            llRegionSay(massChannel, llList2Json(JSON_ARRAY, [ ypres ]));
            mParams = [ ];
            planetsPresent = 0;
            //  Reset step number and simulated time
            stepNumber = 0;
            simTime = 0;
            updateLegend();

        //  Run on/off              Start or stop the simulation

        } else if (abbrP(command, "ru")) {
                stepLimit = 0;
            if (argn < 2) {
                setRun(!runmode);
            } else {
                setRun(onOff(sparam));
            }

        //     Handled by the Auxiliary Command Processor
        //  Asteroid                Set asteroid orbital elements
        //  Clear                   Clear chat for debugging
        //  Comet                   Set comet orbital elements
        //  Help                    Request help notecards
        //  Script                  Script commands

        } else if (abbrP(command, "as") ||
                   abbrP(command, "cl") ||
                   abbrP(command, "co") ||
                   abbrP(command, "he") ||
                   abbrP(command, "sc")) {
            llMessageLinked(LINK_THIS, LM_CP_COMMAND,
                llList2Json(JSON_ARRAY, [ message, lmessage ] + args), whoDat);

        //  Set                     Set simulation parameter

        } else if (abbrP(command, "se")) {
            string svalue = llList2String(args, 2);
            float value = (float) svalue;
            integer changedSettings = FALSE;

            //  AUscale n           Set astronomical unit scale

            if (abbrP(sparam, "au")) {
                s_auscale = value;
                changedSettings = TRUE;

            //  Deltat n            Integration time step

            } else if (abbrP(sparam, "de")) {
                s_deltat = value;
                changedSettings = TRUE;

            //  Ecliptic on/off/size n  Show/hide ecliptic plane

            } else if (abbrP(sparam, "ec")) {
                if (abbrP(svalue, "si")) {
                    s_eclipsize = (float) llList2String(args, 3);
                } else {
                    if (onOff(svalue)) {
                        llRezObject("Ecliptic plane",
                            llGetPos() + <0, 0, s_zoffset>, ZERO_VECTOR,
                            ZERO_ROTATION,
                            llFloor(s_eclipsize * 2 * s_auscale * 100));
                        s_eclipshown = TRUE;
                    } else {
                        llRegionSay(massChannel, llList2Json(JSON_ARRAY, [ planecrash ]));
                        s_eclipshown = FALSE;
                    }
                }

            //  Hide on/off/run         Hide/show the deployer

            } else if (abbrP(sparam, "hi")) {
                if (abbrP(svalue, "ru")) {
                    hidden = 2;
                } else {
                    integer hi = onOff(svalue);
                    if (hi >= 0) {
                        hidden = hi;
                        llSetAlpha(1 - hidden, ALL_SIDES);
                    }
                }

            //  Kaboom n            Self-destruct if this far from deployer

            } else if (abbrP(sparam, "ka")) {
                s_kaboom = value;
                changedSettings = TRUE;

            //  Legend on/off       Show/hide legend above deployer

            } else if (abbrP(sparam, "le")) {
                s_legend = onOff(svalue);
                if (s_legend) {
                    updateLegend();
                } else {
                    llSetLinkPrimitiveParamsFast(LINK_THIS, [
                        PRIM_TEXT, "", <0, 0, 0>, 0
                    ]);
                }

            } else if (abbrP(sparam, "trac")) {
                trace = onOff(svalue);

            //  Mindist n           Minimum distance to update masses

            } else if (abbrP(sparam, "mi")) {
                s_mindist = value;
                changedSettings = TRUE;

            //  Paths off/on/lines

            } else if (abbrP(sparam, "pa")) {
                if (abbrP(svalue, "li")) {
                    if (paths) {
                        paths = FALSE;
                    }
                    s_trails = TRUE;
                } else {
                    s_trails = FALSE;
                    paths = onOff(svalue);
                }
                changedSettings = TRUE;

            //  Pwidth n            Path/trail width

            } else if (abbrP(sparam, "pw")) {
                s_pwidth = value;
                changedSettings = TRUE;

            //  Radscale n          Radius scale

            } else if (abbrP(sparam, "ra")) {
                s_radscale = value;
                changedSettings = TRUE;

            //  Real on/off/step n  Real time mode and update interval

            } else if (abbrP(sparam, "re")) {
                if (abbrP(svalue, "st")) {
                    s_realstep = llList2Float(args, 3);
                } else {
                    s_realtime = onOff(svalue);
                }
                if (s_realtime) {
                    simEpoch = jdstamp(llGetTimestamp());
                    stepNumber++;
                    updatePlanets();
                    llSetTimerEvent(s_realstep);
                } else {
                    llSetTimerEvent(0);
                }

            //  Simrate n           Simulation rate (years/second)

            } else if (abbrP(sparam, "si")) {
                s_simRate = pinterval(svalue);

            //  Step n              Integration step rate (years/step)

            } else if (abbrP(sparam, "st")) {
                s_stepRate = pinterval(svalue);

            //  Trace on/off        Trace operation

            } else if (abbrP(sparam, "tr")) {
                trace = onOff(svalue);
                changedSettings = TRUE;

            //  Zoffset n           Z offset for creating masses

            } else if (abbrP(sparam, "zo")) {
                s_zoffset = value;
                changedSettings = TRUE;

            } else {
                tawk("Invalid.  Set volume");
                return FALSE;
            }
            if (changedSettings) {
                sendSettings(NULL_KEY, 0);
            }

        //  Status

        } else if (abbrP(command, "sta")) {
            integer mFree = llGetFreeMemory();
            integer mUsed = llGetUsedMemory();
            string hidemode = eOnOff(hidden);
            if (hidden == 2) {
                hidemode = "run";
            }
            tawk(llGetScriptName() + " status:" +
                 "\n  Script memory.  Free: " + (string) mFree +
                    "  Used: " + (string) mUsed + " (" +
                    (string) ((integer) llRound((mUsed * 100.0) / (mUsed + mFree))) + "%)"
            );
            llMessageLinked(LINK_THIS, LM_SP_STAT, "", whoDat);
            llMessageLinked(LINK_THIS, LM_CP_COMMAND,
                llList2Json(JSON_ARRAY, [ "Status", "status" ] + args), whoDat);
            llMessageLinked(LINK_THIS, LM_OR_STAT, "", whoDat);

        //  Step n              Step simulation n times

        } else if (abbrP(command, "ste")) {
            integer n = (integer) sparam;

            if (n < 1) {
                n = 1;
            }
/*
            integer i;
float t0 = llGetTime();
            for (i = 0; i < n; i++) {
                if (trace) {
                    tawk("- Step " + (string) (i + 1) + " -");
                }
                timeStep();
            }
float dt = llGetTime() - t0;
            tawk("Done " + (string) n + " steps.");
tawk("Run time: " + (string) dt);
*/
            stepLimit = n;
            setRun(TRUE);

            //  Test what       Run a test

        } else if (abbrP(command, "te")) {
            if (abbrP(sparam, "ep")) {              // Test ephemeris
/*
                ephTask = "list";
                tawk("Epoch " + (string) llList2Integer(simEpoch, 0) +
                    llGetSubString((string) llList2Float(simEpoch, 1), 1, -1));
                updateEphemeris((1 << 10) - 2,
                    llList2Integer(simEpoch, 0), llList2Float(simEpoch, 1));
*/
            } else {
                tawk("Unknown test.");
            }

        } else {
            tawk("Huh?  \"" + message + "\" undefined.  Chat /" +
                (string) commandChannel + " help for instructions.");
            return FALSE;
        }
        return TRUE;
    }

    //  setRun  --  Set run/stop mode

    setRun(integer run) {
        if (run != runmode) {
            runmode = run;
            if (runmode) {
                llSetTimerEvent(tickTime);
                if (hidden == 2) {
                    llSetAlpha(0, ALL_SIDES);
                }
            } else {
                llSetTimerEvent(0);
                if (hidden == 2) {
                    llSetAlpha(1, ALL_SIDES);
                }
            }
        }
    }

    //  timeStep  --  Run the simulation for one integration step

    float timeStep(float deltat) {
/*
        integer i;
        integer n = llGetListLength(mParams);
        list accelN = [ ];
        float mindist = 1e20;
        float maxvel = -1;

        //  Loop over masses
        for (i = 0; i < n; i += mParamsE) {
            vector ai = ZERO_VECTOR;
            float mi = llList2Float(mParams, i + 3);    // Mass[i]
            if (mi > 0) {
                integer j;
                vector pi = llList2Vector(mParams, i + 1);  // Position[i]
                vector vi = llList2Vector(mParams, i + 2);  // Velocity[i]

                //  Loop over peers of current mass...
                for (j = 0; j < n; j += mParamsE) {
                    if (i != j) {           // ...skipping itself, of course
                        float mj = llList2Float(mParams, j + 3);        // Mass[i]
                        if (mj > 0) {       // Ignore mass if destroyed by collision
                            vector pj = llList2Vector(mParams, j + 1);  // Position[i]
                            vector vj = llList2Vector(mParams, j + 2);  // Velocity[i]
                            float r = llVecDist(pi, pj);        // Distance to mass
                            if (r <= collideDist) {
                                /*  When masses collide!  Send collision
                                    messages to both masses.  *_/
                                llRegionSayTo(llList2Key(mParams, i + 7), massChannel,
                                    llList2Json(JSON_ARRAY, [ "COLLIDE",
                                        i / mParamsE, j / mParamsE ]));
                                llRegionSayTo(llList2Key(mParams, j + 7), massChannel,
                                    llList2Json(JSON_ARRAY, [ "COLLIDE",
                                        j / mParamsE, i / mParamsE ]));
                                //  Zero out velocities and masses of both dear departed bodies
                                mParams = llListReplaceList(mParams,
                                    [ ZERO_VECTOR, 0.0 ], i + 2, i + 3);
                                mParams = llListReplaceList(mParams,
                                    [ ZERO_VECTOR, 0.0 ], j + 2, j + 3);
                                //  Bail out processing this mass
                                jump collided;
                            }
                            vector rv = llVecNorm(pj - pi);     // Direction of mass
                            //  F = G (m1 m2) / r^2
                            float force = (GRAVCON * (mi * mj)) / (r * r);
                            //  F = ma, hence a = F/m
                            float accel = force / mi;
                            ai += rv * accel;                   // Gravitational force vector
                            if (r < mindist) {
                                mindist = r;                    // Minimum distance between masses
                            }
                        }
                    }
                    @collided;
                }
            }

            /*  At this point, ai contains the net acceleration
                produced by all other bodies upon this one.  We
                save this in an auxiliary accelN array for
                subsequent use in updating velocities.  *_/

            accelN += ai;
        }

        /*  From the list of accelerations, we can now update
            the velocities of the individual bodies.  But first,
            we need to find the maximum velocity after applying
            the acceleration.  This will allow us to adapt the
            integration time step size (deltat) to avoid loss of
            precision in high-velocity encounters.  The velocity
            and acceleration of a mass destroyed in a collision
            will both be zero, and will not influence this
            computation.  *_/

        integer a;
        for (i = a = 0; i < n; i += mParamsE, a++) {
            float pvel = llVecMag(llList2Vector(mParams, i + 2) +
                                  llList2Vector(accelN, a));
            if (pvel > maxvel) {
                maxvel = pvel;
            }
        }

        /*  Actually update the velocities, now that we know
            deltat.  Since the velocity and acceleration of a
            mass destroyed in a collision are zero, this will
            do nothing for them.  */

/*
        deltat = stepsize * (mindist / maxvel);
        if (deltat < stepmin) {
            deltat = stepmin;
        }
*_/
//  NEED TO CONSTRAIN BASED UPON MAXVEL
        if (deltat < (stepsize * (mindist / maxvel))) {
            deltat = stepsize * (mindist / maxvel);
            if (deltat < stepmin) {
                deltat = stepmin;
            }
        }

if (trace) {
    tawk("Deltat = " + (string) deltat + "  previous " + (string) ldeltat +
        "  stepmin " + (string) stepmin);
ldeltat = deltat;
}
        for (i = a = 0; i < n; i += mParamsE, a++) {
            vector vi = llList2Vector(mParams, i + 2);  // Velocity[i]
            vi += llList2Vector(accelN, a) * deltat;
            mParams = llListReplaceList(mParams, [ vi ], i + 2, i + 2);
        }

        /*  And finally, with the velocities all updated, use
            them and deltat to update the positions.  If the
            mass has been destroyed in a collision, we skip
            sending its update upon seeing that its mass has been
            zeroed out.  *_/

        stepNumber++;
        simTime += deltat;
        updateLegend();
vector eggPos = llGetPos() + <0, 0, s_zoffset>;
        for (i = a = 0; i < n; i += mParamsE, a++) {
            if (llList2Float(mParams, i + 3) > 0) {
                vector where = llList2Vector(mParams, i + 1) +
                               (llList2Vector(mParams, i + 2) * deltat);
                mParams = llListReplaceList(mParams,
                    [ where ], i + 1, i + 1);

                //  Send update to the mass object

                vector rwhere  = (where * s_auscale) + eggPos;
                llRegionSayTo(llList2Key(mParams, i + 7), massChannel,
                    llList2Json(JSON_ARRAY, [ "UPDATE", a + 1,
                        rwhere
                ]));
            }
        }

if (trace) {
tawk("Simulation time: " + (string) simTime + " deltaT " + (string) deltat);
for (i = 0; i < n; i += mParamsE) {
    tawk("  " + llList2String(mParams, i) + "  "  +
        (string) llList2Vector(mParams, i + 1) + "  " +
        (string) llList2Vector(mParams, i + 2));
}
}
        return deltat;                  // Return time actually stepped
*/ return 0;
    }

    default {

        on_rez(integer start_param) {
            llResetScript();
        }

        state_entry() {
            owner = llGetOwner();
            ownerName =  llKey2Name(owner);  //  Save name of owner

            //  Initialise computed constants
            GRAV_CONV = ((AU * AU * AU) / ((YEAR * YEAR) * M_SUN));
            GRAVCON = G_SI / GRAV_CONV;

            llSetAlpha(1, ALL_SIDES);

simEpoch = jdstamp(llGetTimestamp());
ephTask = "none";
updateEphemeris((1 << 10) - 2,
    llList2Integer(simEpoch, 0), llList2Float(simEpoch, 1));

            s_legend = FALSE;
            llSetLinkPrimitiveParamsFast(LINK_THIS, [
                PRIM_TEXT, "", <0, 0, 0>, 0
            ]);

            //  Start listening on the command chat channel
            commandH = llListen(commandChannel, "", NULL_KEY, "");
            llOwnerSay("Listening on /" + (string) commandChannel);

            //  Start listening on the mass channel
            massChH = llListen(massChannel, "", NULL_KEY, "");
        }

        /*  The listen event handler processes messages from
            our chat control channel and messages from masses we've
            deployed.  */

        listen(integer channel, string name, key id, string message) {
//llOwnerSay("Listen channel " + (string) channel + " message " + message);
            if (channel == massChannel) {
                list msg = llJson2List(message);
                string ccmd = llList2String(msg, 0);

                /*  When deployed and its script starts to run, each
                    mass sends us a REZ message with its mass number
                    and key.  This allows us to send it an INIT message
                    containing, encoded in JSON, the parameters with
                    which it should initialise itself.  */

                if (ccmd == "REZ") {
                    integer mass_number = llList2Integer(msg, 1);
                    integer mindex = (mass_number - 1) * mParamsE;
                    //  Save key of mass object in mParams
                    mParams = llListReplaceList(mParams, [ id ],
                        mindex + 7, mindex + 7);

                    llRegionSayTo(id, massChannel,
                        llList2Json(JSON_ARRAY, [ "INIT", mass_number,
                        llList2String(mParams, mindex),                 // Name of body
                        hv(llList2Vector(mParams, mindex + 1)),         // Initial position
                        hv(llList2Vector(mParams, mindex + 2)),         // Initial velocity
                        hf(llList2Float(mParams, mindex + 3)),          // Mass
                        llList2String(mParams, mindex + 4),             // Colour (extended)
                        hf(llList2Float(mParams, mindex + 5)),          // Mean radius
                        hv(llList2Vector(mParams, mindex + 6))          // Deployer position
                    ]));

                    //  Send initial settings
                    sendSettings(id, mass_number);

                /*  When a solar system body has been rezzed and is up
                    and running, its script sends a PLANTED message
                    communicating its key.  We respond with a PINIT
                    message which tells it the scale factors for stars
                    and planets which allow it to scale itself properly.
                    We then send the initial settings, which may be
                    updated as we're running.  */

                } else if (ccmd == "PLANTED") {
                    integer mass_number = llList2Integer(msg, 1);
                    planetKeys = llListReplaceList(planetKeys, [ id ],
                        mass_number, mass_number);
                    planetsPresent = planetsPresent | (1 << mass_number);

                    llRegionSayTo(id, massChannel,
                        llList2Json(JSON_ARRAY, [ "PINIT", mass_number,
                            llList2String(solarSystem, mass_number),    // Name of body
                            hv(llGetPos() + <0, 0, s_zoffset>),         // Deployer position
                            hf(m_scalePlanet),                          // Scale for planets
                            hf(m_scaleStar),                            // Scale for stars
                            llList2Integer(simEpoch, 0),                // Epoch Julian day
                            hf(llList2Float(simEpoch, 1))               // Epoch Julian day fraction
                    ]));

                    //  Send initial settings
                    sendSettings(id, mass_number);
//tawk("Planted body " + (string) mass_number + "  keys " + llList2CSV(planetKeys) + "  present " + (string) planetsPresent);
                }
            } else {
                processCommand(id, message, FALSE);
            }
        }

        //  Process messages from other scripts

        link_message(integer sender, integer num, string str, key id) {

            //  Script Processor Messages

            //  LM_SP_READY (57): Script ready to read

            if (num == LM_SP_READY) {
                scriptActive = TRUE;
                llMessageLinked(LINK_THIS, LM_SP_GET, "", id);  // Get the first line

            //  LM_SP_INPUT (55): Next executable line from script

            } else if (num == LM_SP_INPUT) {
                if (str != "") {                // Process only if not hard EOF
                    scriptSuspend = FALSE;
                    integer stat = processCommand(id, str, TRUE);
                    // Some commands may set scriptSuspend
                    if (stat) {
                        if (!scriptSuspend) {
                            llMessageLinked(LINK_THIS, LM_SP_GET, "", id);
                        }
                    } else {
                        //  Error in script command.  Abort script input.
                        scriptActive = scriptSuspend = FALSE;
                        llMessageLinked(LINK_THIS, LM_SP_INIT, "", id);
                        tawk("Script terminated.");
                    }
                }

            //  LM_SP_EOF (56): End of file reading from script

            } else if (num == LM_SP_EOF) {
                scriptActive = FALSE;           // Mark script input complete
                if (echo || trace) {
                    tawk("End script.");
                }

            //  LM_SP_ERROR (58): Error processing script request

            } else if (num == LM_SP_ERROR) {
                llRegionSayTo(id, PUBLIC_CHANNEL, "Script error: " + str);
                scriptActive = scriptSuspend = FALSE;
                llMessageLinked(LINK_THIS, LM_SP_INIT, "", id);

            //  LM_CP_RESUME (225): Resume script after external command

            } else if (num == LM_CP_RESUME) {
                scriptResume();

            //  LM_EP_RESULT (432): Ephemeris calculation results

            } else if (num == LM_EP_RESULT) {
               list l = llCSV2List(str);
/*               tawk("Body " + (string) llList2Integer(l, 0) +
                    "  L " + (string) (RAD_TO_DEG * llList2Float(l, 1))  +
                    "  B " + (string) (RAD_TO_DEG * llList2Float(l, 2))  +
                    "  R " + (string) llList2Float(l, 3)); */

                integer handle = llList2Integer(l, 4);
                if (handle == ephHandle) {
                    integer body = llList2Integer(l, 0);
                    ephReplies = ephReplies | (1 << body);
                    integer bx = body * 3;
                    ephBodies = llListReplaceList(ephBodies, llList2List(l, 1, -2), bx, bx + 2);
                    if (ephReplies == ephRequests) {
//float ephCalcEnd = llGetTime();
//tawk("Ephemeris calculation time: " + (string) (ephCalcEnd - ephCalcStart));
                        //  list:  List ephemeris results
    /*
                        if (ephTask == "list") {
                            integer i;
                            integer n = llGetListLength(solarSystem);

                            for (i = 0; i < n; i++) {
                                vector pos = sphRect(llList2Float(ephBodies, i * 3),
                                    llList2Float(ephBodies, (i * 3) + 1),
                                    llList2Float(ephBodies, (i * 3) + 2));

                                tawk(llList2String(solarSystem, i) + "   " +
                                    (string) (RAD_TO_DEG * llList2Float(ephBodies, i * 3)) + "   " +
                                    (string) (RAD_TO_DEG * llList2Float(ephBodies, (i * 3) + 1)) + "   " +
                                    (string) llList2Float(ephBodies, (i * 3) + 2) + "  " +
                                    (string) pos);
                            }

                        //  update:  Send ephemeris updates to solar system bodies

                        } else */ if (ephTask == "update") {
                            integer i;

                            updateLegend();
                            for (i = 1; i <= 10; i++) {
    if (llList2Key(planetKeys, i) != NULL_KEY) {
                                integer p = i * 3;
                                vector where = sphRect(
                                    llList2Float(ephBodies, p),
                                    llList2Float(ephBodies, p + 1),
                                    llList2Float(ephBodies, p + 2));

                                vector eggPos = llGetPos();

                                vector rwhere = (where * s_auscale) + eggPos + <0, 0, s_zoffset>;
                                llRegionSayTo(llList2Key(planetKeys, i), massChannel,
                                    llList2Json(JSON_ARRAY, [ "UPDATE", i,
                                        hv(rwhere),                     // New rectangular co-ordinates
                                        llList2Integer(simEpoch, 0),    // Epoch Julian day
                                        hf(llList2Float(simEpoch, 1))   // Epoch Julian day fraction
                                ]));

/*tawk("Send update: " + llList2Json(JSON_ARRAY, [ "UPDATE", i,
        llList2String(solarSystem, i),
        (string) rwhere
]) + "  where " + (string) where + "  s_auscale " + (string) s_auscale);*/
                                }
                            }
                        }
                    }
                }
//else { tawk("Handle mismatch " + (string) ephHandle + "  Rep " + llList2CSV(l)); }

            //  LM_MP_TRACK (571): Tracking minor planet

            } else if (num == LM_MP_TRACK) {
                list args = llJson2List(str);
                if (llList2Integer(args, 0)) {
                    string m_name = llList2String(args, 1);
tawk("Now tracking minor planet (" + m_name + ")");
                    planetsPresent = planetsPresent | (1 << 10);
                    solarSystem = llListReplaceList(solarSystem, [ m_name ], 10, 10);

                    vector eggPos = llGetPos();
                    vector where = ZERO_VECTOR; // Adjusted once co-ordinates arrive
                    where = (where * s_auscale) + eggPos + <0, 0, s_zoffset>;
                    if (trace) {
                        tawk("Deploying " + str + " at " + (string) where);
                    }
                    string bname = "Comet";
                    if (llList2Integer(args, 3)) {
                        bname = "Asteroid";
                    }
                    llRezObject("S: " + bname, where, ZERO_VECTOR,
                        llEuler2Rot(<0, PI_BY_TWO, 0>), 10);
                } else {
                    //  Dropping tracking of current object
                    planetsPresent = planetsPresent & (~(1 << 10));
                    solarSystem = llListReplaceList(solarSystem, [ "" ], 10, 10);
                    key mpk = llList2Key(planetKeys, 10);
                    if (mpk != NULL_KEY) {
                        planetKeys = llListReplaceList(planetKeys, [ NULL_KEY ], 10, 10);
                        llRegionSayTo(mpk, massChannel, llList2Json(JSON_ARRAY, [ ypres ]));
                    }
                }
                updatePlanets();
            }
        }

        //  The timer advances the simulation while it's running

        timer() {
//tawk("Timer  real " + (string) s_realtime);
            if (s_realtime) {
                simEpoch = jdstamp(llGetTimestamp());
                updatePlanets();
                stepNumber++;
            } else if (runmode) {
//tawk("Tick...");
                //  Are we performing numerical integration ?
                integer numInt = llGetListLength(mParams) > 0;
float tstart = llGetTime();
                float timeToStep = s_stepRate;
integer nsteps = 0;
                while (timeToStep > 0) {
                    if (numInt) {
                        /*  Numerical integration: perform one integration
                            step, with the possibility that the integrator
                            may take a smaller step than requested due to
                            large velocities and/or accelerations among
                            bodies.  */
                        float timeStepped = timeStep(timeToStep);
                        timeToStep -= timeStepped;
                        nsteps++;
                    } else {
                        /*  Analytical planetary theory: we always get the
                            answer immediately calculation-wise, but not in
                            real time, as we must wait for the individual
                            evaluators to reply.  */
                        integer simjd = llList2Integer(simEpoch, 0);
                        float simjdf = llList2Float(simEpoch, 1);
                        //  Update simulated time, propagating whole numbers from fraction
                        simjdf += s_stepRate * 365.25;
                        integer jdfi = llFloor(simjdf);
                        simjd += jdfi;
                        simjdf -= jdfi;
                        simEpoch = [ simjd, simjdf ];
                        updatePlanets();
                        timeToStep = 0;         // Analytical planetary theory always gets it in one
                        nsteps++;
                        stepNumber++;
                    }
                }
                float tcomp = llGetTime() - tstart;
                if (nsteps > 1) {
                    tawk("Update took " + (string) nsteps + " steps.");
                }
                if (stepLimit > 0) {
                    stepLimit--;
                    if (stepLimit <= 0) {
                        setRun(FALSE);
tawk("Stopped.");
                    }
                }
                if (runmode) {
                    float wait = (s_stepRate / s_simRate) - tcomp;
                    if (wait <= 0) {
                        tawk("Time deficit: " + (string) wait);
                        wait = 0.001;
                    }
                    llSetTimerEvent(wait);
                }
            }
        }
    }
