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
    integer s_trace = FALSE;            // Trace mass behaviour
    integer paths = FALSE;              // Show particle trails from mass ?

    list simEpoch;                      // Epoch of simulation

    //  Link messages

    //  Command processor messages
    integer LM_CP_COMMAND = 223;        // Process command
    integer LM_CP_RESUME = 225;         // Resume script after command
    integer LM_CP_REMOVE = 226;         // Remove simulation objects

    //  Auxiliary services messages

    integer LM_AS_SETTINGS = 542;       // Update settings

    //  Galactic centre messages

    integer LM_GC_SOURCES = 752;        // Report number of sources

    //  Galactic patrol messages

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

    /*  sendSettings  --  Send settings to source(s).  If source is
                          nonzero, the message is directed to
                          that specific source.  If zero, it is
                          a broadcast to all sources, and the id
                          argument is ignored.  These messages,
                          with a type of "SOURCE_SET", should not
                          be confused with the "SETTINGS" messages
                          set by the deployer.  They contain only
                          parameters of interest to sources.  */

    sendSettings(key id, integer source) {
        string msg = llList2Json(JSON_ARRAY, [ "SOURCE_SET", source,
                            paths,
                            s_trace,
                            fuis(s_auscale),
                            fuis(s_radscale),
                            s_trails,
                            fuis(s_pwidth),
                            fuis(s_mindist),
                            s_labels
                      ]);
        if (source == 0) {
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
        string command = llList2String(args, 0);    // The command

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
                llList2Json(JSON_ARRAY,
                    [ nCentres + llGetListLength(source_keys), // Number of sources
                      0,                            // This source index (0 = centre)
                      nCentre,                      // Name
                      0,                            // Orbital period (0 for centre)
                      0,                            // Time of periapse day...
                      0,                            // ...and fraction
                      0,                            // Eccentricity
                      0                             // Semi-major axis
                    ]), whoDat);


        //  Source

        } else if (abbrP(command, "so")) {
            list e = parseOrbitalElements(message);
            s_sources += e;
            source_keys += NULL_KEY;        // Reserve space for key
            integer massn = llGetListLength(source_keys);
            vector eggPos = llGetPos();
            vector rwhere = eggPos + <0, 0, s_zoffset>;
            //  Initially create source at centre
            llRezObject("Source", rwhere, ZERO_VECTOR,
                llEuler2Rot(<PI_BY_TWO, 0, 0>),
                massn);
            llMessageLinked(LINK_THIS, LM_GC_SOURCES,
                llList2Json(JSON_ARRAY,
                    [ nCentres + llGetListLength(source_keys), // 0  Number of sources
                      llGetListLength(source_keys), // 1    Source index
                      llList2String(e, 0),          // 2    Name
                      llList2Float(e, 15),          // 3    Orbital period (NaN if eccentricity >= 1)
                      llList2Integer(e, 11),        // 4    Time of periapse day...
                      llList2Float(e, 12),          // 5    ...and fraction
                      llList2Float(e, 4),           // 6    Eccentricity
                      llList2Float(e, 3)            // 7    Semi-major axis (NaN if eccentricity >= 1)
                    ]), whoDat);


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

                /*  We only decode settings in which we're interested
                    or wish to pass on to sources we've created.  */
                paths = llList2Integer(msg, 2);
                s_trace = llList2Integer(msg, 3);
                s_auscale = siuf(llList2String(msg, 5));
                s_radscale = siuf(llList2String(msg, 6));
                s_trails = llList2Integer(msg, 7);
                s_pwidth = siuf(llList2String(msg, 8));
                s_mindist = siuf(llList2String(msg, 9));
                s_deltat = siuf(llList2String(msg, 10));
                s_zoffset = siuf(llList2String(msg, 17));
                s_legend = llList2Integer(msg, 18);
                simEpoch = llList2List(msg, 19, 20);
                s_labels = llList2Integer(msg, 21);

                sendSettings(NULL_KEY, 0);
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
                                simEpoch +                          // Epoch for initial position
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
