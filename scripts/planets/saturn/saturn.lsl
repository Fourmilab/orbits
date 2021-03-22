
    
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
            "Saturn",           // 0  Name of body
            "Sun",              // 1  Primary

            //  Orbital elements
             2451545 ,          // 2  Epoch (J2000), integer to avoid round-off

            9.53707032,         // 3  a    Semi-major axis, AU
            0.05415060,         // 4  e    Eccentricity
            2.48446,            // 5  i    Inclination, degrees
            113.71504,          // 6  Ω    Longitude of the ascending node, degrees
            92.43194,           // 7  ω    Argument of periapsis, degrees
            49.94432,           // 8  L    Mean longitude, degrees

            //  Orbital element centennial rates
            -0.00301530,        // 9  a    AU/century
            -0.00036762,        // 10 e    e/century
            6.11,               // 11 i    "/century
            -1591.05,           // 12 Ω    "/century
            -1948.89,           // 13 ω    "/century
            4401052.95,         // 14 L    "/century

            //  Physical properties
            60268.0,            // 15 Equatorial radius, km
            54364.0,            // 16 Polar radius, km
            5.6834e26,          // 17 Mass, kg
            0.687,              // 18 Mean density, g/cm³
            10.44,              // 19 Surface gravity, m/s²
            35.5,               // 20 Escape velocity, km/s
            0.4400231,          // 21 Sidereal rotation period, days
            <40.589, 83.537, 0>,// 22 North pole, RA, Dec
            26.73,              // 23 Axial inclination, degrees
            0.499,              // 24 Albedo

            //  Extras
            0.0,                // 25 Fractional part of epoch
             1.32712440018e20 ,         /* 26 Standard gravitational parameter (G M)
                                      of primary, m^3/sec^2  */
             <0.00588, 0.3176, 0.5647>    // 27 Colour of trail tracing orbit
        ];
    

    
        integer LM_PL_PINIT = 531;
    

    
        
            
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
            
            integer massChannel =  -982449822 ;  // Channel for communicating with planets
            string Collision = "Balloon Pop";   // Explosion sound clip

            //  Link indices within the object
            integer lGlobe;                     // Planetary globe
        

        //  These are used only for major planets
        rotation npRot;                     // Rotation to orient north pole
        float m_scaleStar;                  // Star scale
        integer m_jd;                       // Epoch Julian day
        float m_jdf;                        // Epoch Julian day fraction
        list rotEpoch;                      // Base epoch for rotation

        //  Link messages
        
            //  Planetary satellite message
            integer LM_PS_DEPMSG = 811;         // Message from deployer
            integer LM_PS_UPDATE = 812;         // Update position and rotation
        
    
        
            integer findLinkNumber(string pname) {
                integer i = llGetLinkNumber() != 0;
                integer n = llGetNumberOfPrims() + i;

                for (; i < n; i++) {
                    if (llGetLinkName(i) == pname) {
                        return i;
                    }
                }
                return -1;
            }
        

        
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
        
        
            float siuf(string b) {
                integer a = llBase64ToInteger(b);
                if (0x7F800000 & ~a) {
                    return llPow(2, (a | !a) + 0xffffff6a) *
                              (((!!(a = (0xff & (a >> 23)))) * 0x800000) |
                               (a & 0x7fffff)) * (1 | (a >> 31));
                }
                return (!(a & 0x7FFFFF)) * (float) "inf" * ((a >> 31) | 1);
            }
        
        
            vector sv(string b) {
                return(< siuf(llGetSubString(b, 0, 5)),
                         siuf(llGetSubString(b, 6, 11)),
                         siuf(llGetSubString(b, 12, -1)) >);
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
        
        
            string eff(float f) {
                return ef((string) f);
            }
        
        
            string efv(vector v) {
                return ef((string) v);
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
        

        
            integer sgn(float v) {
                if (v == 0) {
                    return 0;
                } else if (v > 0) {
                    return 1;
                }
                return -1;
            }
        
        
            rotation rotHour(integer jd, float jdf) {
                /*  Compute axis around which the body rotates.
                    This axis is defined by the vector from its
                    centre to the north pole.  */
                vector raxis = < 1, 0, 0 > * npRot;
                /*  Compute rotation angle from the elapsed time
                    since the start of the rotation epoch and the
                    rotation period in days.  */
                float jde = (jd - llList2Integer(rotEpoch, 0)) +
                            (jdf - llList2Float(rotEpoch, 1));
                float period = llList2Float(planet, 21);
                float gangle = fixangr(TWO_PI * (jde / period));
                /*  Compose the prime meridian rotation with the
                    north pole alignment rotation to obtain the
                    complete satellite rotation.  */
                return npRot * llAxisAngle2Rot(raxis, sgn(period) * (-gangle));
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
        

        
            vector rectSph(vector rc) {
                float r = llVecMag(rc);
                return < llAtan2(rc.y, rc.x), llAsin(rc.z / r), r >;
            }
        
        
            float fixangr(float a) {
                return a - (TWO_PI * (llFloor(a / TWO_PI)));
            }
        

        
            tellSat(string message) {
                llMessageLinked(LINK_ALL_CHILDREN, LM_PS_DEPMSG,
                    message, deployer);
            }
        
        
            updateLegendPlanet(vector pos) {
                if (s_labels) {
                    string legend = m_name;

                    if (m_index > 0) {
                        vector lbr = rectSph(pos);
                        legend += "\nLong " + eff(fixangr(lbr.x) * RAD_TO_DEG) +
                                    "° Lat " + eff(lbr.y * RAD_TO_DEG) +
                                    "°\nRV " + eff(lbr.z) + " AU" +
                                    "\nPos " + efv(pos);
                    }
                    llSetLinkPrimitiveParamsFast(lGlobe, [
                        PRIM_TEXT, legend,llList2Vector(planet, 27), 1
                    ]);
                }
            }
        
        
            updateSat(integer jd, float jdf) {
                llMessageLinked(LINK_ALL_CHILDREN, LM_PS_UPDATE,
                                llList2Json(JSON_ARRAY,
                                    [ jd, fuis(jdf)     // 0,1  Julian day and fraction
                                    ]), deployer);
            }
        
        
            kaboom(vector colour) {
                llPlaySound(Collision, 1);

                llParticleSystem([
                    PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,

                    PSYS_SRC_BURST_RADIUS, 0.05,

                    PSYS_PART_START_COLOR, colour,
                    PSYS_PART_END_COLOR, colour,

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

                //  Find link indices within this link set by name
                lGlobe = findLinkNumber("Globe");
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
                    llListen( -982449822 , "", NULL_KEY, "");

                    //  Inform the deployer that we are now listening
                    llRegionSayTo(deployer, massChannel,
                        llList2Json(JSON_ARRAY, [ "PLANTED", m_index ]));

                    initState = 1;          // Waiting for SETTINGS and INIT
                }
            }
    
            listen(integer channel, string name, key id, string message) {
    //llOwnerSay("Planet " + llGetScriptName() + " channel " + (string) channel + " id " + (string) id +  " message " + message);

                if (channel ==  -982449822 ) {
                    list msg = llJson2List(message);
                    string ccmd = llList2String(msg, 0);

                    if (id == deployer) {
                    
                        if (ccmd == ypres) {
                            if (s_trails) {
                                llRegionSay(massChannel,
                                    llList2Json(JSON_ARRAY, [ ypres ]));
                                tellSat(message); llSleep(0.25);
                            }
                            llDie();
                    
                    
                            } else if (ccmd == "COLLIDE") {
                                kaboom(llList2Vector(planet, 27));
                    
                    
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
                    
    
                        } else if (ccmd == "PINIT") {
                            if (m_index == llList2Integer(msg, 1)) {
                                m_name = llList2String(msg, 2);             // Name
                                deployerPos = sv(llList2String(msg, 3));    // Deployer position
                                m_scalePlanet = siuf(llList2String(msg, 4));    // Planet scale
                                m_scaleStar =  siuf(llList2String(msg, 5)); // Star scale
                                m_jd = llList2Integer(msg, 6);              // Epoch Julian day
                                m_jdf = siuf(llList2String(msg, 7));        // Epoch Julian day fraction
                                rotEpoch = [ m_jd, m_jdf ];                 // Base epoch for rotation

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

                                npRot = rotPole(m_jd, m_jdf);

                                //  Set identity of body container
                                llSetLinkPrimitiveParamsFast(LINK_THIS, [
                                    PRIM_DESC,  llList2Json(JSON_ARRAY,
                                        [ m_index, m_name, eff(llList2Float(planet, 17)) ])
    , PRIM_ROTATION, ZERO_ROTATION    // TAKE OUT INITIAL ROTATION OF LEGACY REZ CODE
                                ]);


                                //  Set scale and orientation of globe
                                llSetLinkPrimitiveParamsFast(lGlobe, [
                                    PRIM_SIZE, psize,           // Scale to proper size
                                    PRIM_ROT_LOCAL, npRot       // Rotate north pole to proper orientation
                                ]);
                                
                                    integer lRings = findLinkNumber("Saturn: ring system");

                                    llMessageLinked(lRings, LM_PL_PINIT, message, id);

                                    rotation eqRot = llEuler2Rot(<0, PI_BY_TWO, 0>) * npRot;
                                    llSetLinkPrimitiveParamsFast(lRings, [ PRIM_ROT_LOCAL, eqRot ]);
                                
                                llSetStatus(STATUS_PHANTOM | STATUS_DIE_AT_EDGE, TRUE);

                                tellSat(message);
                                initState = 2;                  // INIT received, waiting for SETTINGS
                            }
    
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
                                s_satShow = llList2Integer(msg, 22);
                                tellSat(message);

                                //  Update label if state has changed
                                if (s_labels != o_labels) {
                                    if (s_labels) {
                                        updateLegendPlanet((llGetPos() -
                                            deployerPos) / s_auscale);
                                    } else {
                                        llSetLinkPrimitiveParamsFast(lGlobe, [
                                            PRIM_TEXT, "", ZERO_VECTOR, 0 ]);
                                    }
                                }
                            }

                            if (initState == 2) {
                                initState = 3;
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
                            
    
                        } else if (ccmd == "UPDATE") {
                            vector p = llGetPos();
                            vector npos = sv(llList2String(msg, 2));
                            float dist = llVecDist(p, npos);

                            integer jd = llList2Integer(msg, 3);
                            float jdf = siuf(llList2String(msg, 4));
    if (s_trace) {
        tawk(m_name + ": Update pos from " + (string) p + " to " + (string) npos +
            " dist " + (string) dist);
    }
                            if ((s_kaboom > 0) &&
                                ((llVecDist(npos, deployerPos) / s_auscale) > s_kaboom)) {
                                kaboom(llList2Vector(planet, 27));
                                return;
                            }
                            if (dist >= s_mindist) {
                                llSetLinkPrimitiveParamsFast(LINK_THIS,
                                    [ PRIM_POSITION, npos ]);
    //                            if (paths) {
    //                                llSetLinkPrimitiveParamsFast(LINK_THIS,
    //                                    [ PRIM_ROTATION, llRotBetween(<0, 0, 1>, (npos - p)) ]);
    //                            }
                                if (s_trails) {
                                    flPlotLine(p, npos,llList2Vector(planet, 27), s_pwidth);
                                }
                            }
                            //  Rotate globe.  We don't rotate rings since you can't notice
                            llSetLinkPrimitiveParamsFast(lGlobe, [
                                PRIM_ROT_LOCAL, rotHour(jd, jdf)
                            ]);

                            updateLegendPlanet((npos - deployerPos) / s_auscale);
                            
                            updateSat(jd, jdf);     // Update position and rotation of satellites
    
                        
                            } else if (ccmd == "VERSION") {
                                if ("0" != llList2String(msg, 1)) {
                                    llOwnerSay(llGetScriptName() +
                                               " build mismatch: Deployer " + llList2String(msg, 1) +
                                               " Local 0");
                                }
                        
                            
                                llRegionSay( -982449822 ,
                                    llList2Json(JSON_ARRAY, [ "VERSION", llList2String(msg, 1) ]));
                            
                            tellSat(message);
                        }
                    }
                }
            }
         }
    
