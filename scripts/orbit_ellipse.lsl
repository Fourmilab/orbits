    /*
                       Orbital Ellipse

        This object is used to display the ellipse in which a mass
        orbits around a central body.  It is rezzed at the centre
        of the orbit's ellipse (determined from its orbital elements)
        and sends the rezzer an ORBITAL message to inform it we're
        up and running and request our orbital parameters.

    */

    key deployer;                       // ID of deployer who hatched us
    integer massChannel = -982449822;   // Channel for communicating with planets
    string ypres = "B?+:$$";            // It's pronounced "Wipers"

    //  Configuration parameters

    integer m_index;                    // Index of body whose orbit we represent
    string m_name;                      // Name of orbit object
    vector m_size;                      // Size
    vector m_colour;                    // Colour
    float m_alpha;                      // Transparency (0 = transparent, 1 = solid)
    rotation m_rotation;                // Rotation (in region co-ordinates)

    default {

        on_rez(integer sparam) {
//            llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_TEMP_ON_REZ, TRUE ]);
//            llOwnerSay("Sparam " + (string) sparam + " vel " + (string) llGetVel());

            deployer = llList2Key(llGetObjectDetails(llGetKey(),
                            [ OBJECT_REZZER_KEY ]), 0);
            m_index = sparam;

            //  Listen for messages from deployer
            llListen(massChannel, "", NULL_KEY, "");

            /*  If start parameter is zero, this is manual rez from
                the inventory.  Set colour and transparency so we're
                visible and thus readily found for editing, even
                though our initial properties may render us
                invisible (to avoid scaring the chickens until we
                receive our configuration and adapt accordingly).  */

            if (sparam == 0) {
                llSetLinkPrimitiveParamsFast(LINK_THIS, [
                    PRIM_COLOR, ALL_SIDES, <1, 0.64706, 0>, 1
                ]);
            }

            //  Inform the deployer that we are now listening
            llRegionSayTo(deployer, massChannel,
                llList2Json(JSON_ARRAY, [ "ORBITAL", m_index ]));
        }

        //  The listen event handles message from the deployer

        listen(integer channel, string name, key id, string message) {
//llOwnerSay(llGetScriptName() + " channel " + (string) channel + " id " + (string) id +  " message " + message);
            if (channel == massChannel) {
                list msg = llJson2List(message);
                string ccmd = llList2String(msg, 0);

                if (id == deployer) {

                    //  Message from our Deployer

                    //  ypres  --  Destroy object

                    if (ccmd == ypres) {
                        llDie();

                    //  ORBITING  --  Set orbit parameters

                    } else if (ccmd == "ORBITING") {
//llOwnerSay("ORBITING params received " + llList2CSV(msg));
                        m_name = llList2String(msg, 2);
                        m_size = (vector) llList2String(msg, 3);
//                        m_rotation = (rotation) llList2String(msg, 4);
                        m_colour = (vector) llList2String(msg, 5);
                        m_alpha = (float) llList2Float(msg, 6);
                        llSetLinkPrimitiveParamsFast(LINK_THIS, [
                            PRIM_NAME, m_name,
                            PRIM_SIZE, m_size,
//                            PRIM_ROTATION, m_rotation,
                            PRIM_COLOR, ALL_SIDES, m_colour, m_alpha
                        ]);
                    }
                }
            }
        }
    }
