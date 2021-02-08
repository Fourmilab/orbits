
    /*
                        Fourmilab Solar System

                         Numerical Integration
    */

    key owner;                          // Owner UUID
    key whoDat = NULL_KEY;              // Avatar who sent command

    integer massChannel = -982449822;   // Channel for communicating with planets
    string ypres = "B?+:$$";            // It's pronounced "Wipers"

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


    integer s_trace = FALSE;            // Trace mass behaviour
    integer paths = FALSE;              // Show particle trails from masss ?

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

    //  Link messages

    //  Command processor messages

    integer LM_CP_COMMAND = 223;    // Process command
    integer LM_CP_RESUME = 225;         // Resume script after command
    integer LM_CP_REMOVE = 226;         // Remove simulation objects

    //  Auxiliary services messages

    integer LM_AS_LEGEND = 541;         // Update floating text legend
    integer LM_AS_SETTINGS = 542;       // Update settings

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

    /*  fixArgs  --  Transform command arguments into canonical form.
                     All white space within vector and rotation brackets
                     is elided so they will be parsed as single arguments.  */

    string fixArgs(string cmd) {
        cmd = llStringTrim(cmd, STRING_TRIM);
        integer l = llStringLength(cmd);
        integer inbrack = FALSE;
        integer i;
        string fcmd = "";

        for (i = 0; i < l; i++) {
            string c = llGetSubString(cmd, i, i);
            if (inbrack && ((c == ">") || (c == "}"))) {
                inbrack = FALSE;
            }
            if ((c == "<") || (c == "{")) {
                inbrack = TRUE;
            }
            if (!((c == " ") && inbrack)) {
                fcmd += c;
            }
        }
        return fcmd;
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

    //  abbrP  --  Test if string matches abbreviation

    integer abbrP(string str, string abbr) {
        return abbr == llGetSubString(str, 0, llStringLength(abbr) - 1);
    }

    //  processAuxCommand  --  Process a command

    integer processAuxCommand(key id, list args) {
        whoDat = id;            // Direct chat output to sender of command

        string message = llList2String(args, 0);
        string lmessage = fixArgs(llToLower(message));
        args = llParseString2List(lmessage, [ " " ], []);   // Command and arguments
        integer argn = llGetListLength(args);       // Number of arguments
        string command = llList2String(args, 0);    // The command
        string sparam = llList2String(args, 1);     // First argument, for convenience

        integer numint = mParams != [ ];

        //  Mass name position velocity mass colour radius

        if (abbrP(command, "ma")) {
            if (runmode) {
                tawk("Cannot add a mass while running.");
                return FALSE;
            }

            //  Re-parse command to handle quotes and preserve letter case
            args = fixQuotes(llParseString2List(fixArgs(message), [ " " ], []));
            argn = llGetListLength(args);       // Number of arguments

            string name = llList2String(args, 1);
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
            if (s_trace) {
                tawk("Deploying " + name + " at " + (string) where);
            }
            llRezObject("Mass", where, ZERO_VECTOR,
//                ZERO_ROTATION,
llEuler2Rot(<PI_BY_TWO, 0, 0>),
                llGetListLength(mParams) / mParamsE);
            llSetRegionPos(eggPos);

        //  Remove                  Remove all masses

        } else if (numint && abbrP(command, "re")) {
            setRun(FALSE);
            llRegionSay(massChannel, llList2Json(JSON_ARRAY, [ ypres ]));
            mParams = [ ];
            //  Reset step number and simulated time
            stepNumber = 0;
            simTime = 0;
            updateLegend();

        //  Run on/off              Start or stop the simulation

        } else if (numint && abbrP(command, "ru")) {
            stepLimit = 0;
            if (argn < 2) {
                setRun(!runmode);
            } else {
                setRun(onOff(sparam));
            }

        //  Status

        } else if (abbrP(command, "sta")) {
            integer mFree = llGetFreeMemory();
            integer mUsed = llGetUsedMemory();
            tawk(llGetScriptName() + " status:" +
                 "\n  Script memory.  Free: " + (string) mFree +
                    "  Used: " + (string) mUsed + " (" +
                    (string) ((integer) llRound((mUsed * 100.0) / (mUsed + mFree))) + "%)"
            );

        //  Step n              Step simulation n times

        } else if (numint && abbrP(command, "ste")) {
            integer n = (integer) sparam;

            if (n < 1) {
                n = 1;
            }
            stepLimit = n;
            setRun(TRUE);
        }

        return TRUE;
    }

    //  setRun  --  Set run/stop mode

    setRun(integer run) {
        if (run != runmode) {
            runmode = run;
            if (runmode) {
/*
                llSetTimerEvent(tickTime);
*/
llSetTimerEvent(s_simRate);
            } else {
                llSetTimerEvent(0);
            }
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
                    FALSE,                              // 3    Tracking minor planet ?
                    "" ] +                              // 4    Name of minor planet, if any
                    simEpoch                            // 5,6  Simulation epoch
                ), whoDat);
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
                            s_trace,
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

    //  timeStep  --  Run the simulation for one integration step

    float timeStep(float deltat) {
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
                                    messages to both masses.  */
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
                subsequent use in updating velocities.  */

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
            computation.  */

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
*/
//  NEED TO CONSTRAIN BASED UPON MAXVEL
/*
        if (deltat < (stepsize * (mindist / maxvel))) {
            deltat = stepsize * (mindist / maxvel);
            if (deltat < stepmin) {
                deltat = stepmin;
            }
        }

if (s_trace) {
    tawk("Deltat = " + (string) deltat + "  previous " + (string) ldeltat +
        "  stepmin " + (string) stepmin);
ldeltat = deltat;
}
*/
        for (i = a = 0; i < n; i += mParamsE, a++) {
            vector vi = llList2Vector(mParams, i + 2);  // Velocity[i]
            vi += llList2Vector(accelN, a) * deltat;
            mParams = llListReplaceList(mParams, [ vi ], i + 2, i + 2);
        }

        /*  And finally, with the velocities all updated, use
            them and deltat to update the positions.  If the
            mass has been destroyed in a collision, we skip
            sending its update upon seeing that its mass has been
            zeroed out.  */

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

if (s_trace) {
tawk("Simulation time: " + (string) simTime + " deltaT " + (string) deltat);
for (i = 0; i < n; i += mParamsE) {
    tawk("  " + llList2String(mParams, i) + "  "  +
        (string) llList2Vector(mParams, i + 1) + "  " +
        (string) llList2Vector(mParams, i + 2));
}
}
        return deltat;                  // Return time actually stepped
    }

    default {

        on_rez(integer start_param) {
            llResetScript();
        }

        state_entry() {
            whoDat = owner = llGetOwner();

            //  Initialise computed constants
            GRAV_CONV = ((AU * AU * AU) / ((YEAR * YEAR) * M_SUN));
            GRAVCON = G_SI / GRAV_CONV;

            llListen(massChannel, "", NULL_KEY, "");
        }

        //  Process messages from other scripts

        link_message(integer sender, integer num, string str, key id) {

            //  LM_CP_COMMAND (223): Process auxiliary command

            if (num == LM_CP_COMMAND) {
                processAuxCommand(id, llJson2List(str));

            //  LM_CP_REMOVE (226): Remove simulation objects

            } else if (num == LM_CP_REMOVE) {
                mParams = [ ];              // Parameters of masses

            //  LM_AS_SETTINGS (542): Update settings from main script

            } else if (num == LM_AS_SETTINGS) {
                list msg = llJson2List(str);

                integer O_legend = s_legend;

                paths = llList2Integer(msg, 2);
                s_trace = llList2Integer(msg, 3);
                s_kaboom = (float) llList2String(msg, 4);
                s_auscale = (float) llList2String(msg, 5);
                s_radscale = (float) llList2String(msg, 6);
                s_trails = llList2Integer(msg, 7);
                s_pwidth = (float) llList2String(msg, 8);
                s_mindist = (float) llList2String(msg, 9);
                s_deltat = (float) llList2String(msg, 10);
                s_eclipshown = llList2Integer(msg, 11);
                s_eclipsize = (float) llList2String(msg, 12);
                s_realtime = llList2Integer(msg, 13);
                s_realstep = (float) llList2String(msg, 14);
                s_simRate = (float) llList2String(msg, 15);
                s_stepRate = (float) llList2String(msg, 16);
                s_zoffset = (float) llList2String(msg, 17);
                s_legend = llList2Integer(msg, 18);

                if (s_legend != O_legend) {
                    updateLegend();
                }
if (runmode) {
    llSetTimerEvent(s_simRate);
}
            }

        }

        //  The listen event handles messages from objects we create

        listen(integer channel, string name, key id, string message) {
//llOwnerSay(llGetScriptName() + " channel " + (string) channel + " id " + (string) id +  " message " + message);
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
                    //  Resume deployer script, if suspended
                    llMessageLinked(LINK_THIS, LM_CP_RESUME, "", whoDat);
                }
            }
        }

        //  The timer advances the simulation while it's running

        timer() {
/*
            if (runmode) {
float tstart = llGetTime();
                float timeToStep = s_stepRate;
integer nsteps = 0;
                while (timeToStep > 0) {
                    /*  Numerical integration: perform one integration
                        step, with the possibility that the integrator
                        may take a smaller step than requested due to
                        large velocities and/or accelerations among
                        bodies.  *_/
                    float timeStepped = timeStep(timeToStep);
                    timeToStep -= timeStepped;
                    nsteps++;
                }
                float tcomp = llGetTime() - tstart;
                if (nsteps > 1) {
                    tawk("Update took " + (string) nsteps + " steps.");
                }
                if (stepLimit > 0) {
                    stepLimit--;
                    if (stepLimit <= 0) {
                        setRun(FALSE);
                        llMessageLinked(LINK_THIS, LM_CP_RESUME, "", whoDat);
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
*/
            if (runmode) {
                timeStep(s_stepRate);
            }
        }
    }
