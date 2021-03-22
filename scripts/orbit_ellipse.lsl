
    
        /*  NOTE: This program was automatically generated by the Nuweb
            literate programming tool.  It is not intended to be modified
            directly.  If you wish to modify the code or use it in another
            project, you should start with the master, which is kept in the
            file orbits.w in the public GitHub repository:
                https://github.com/Fourmilab/orbits.git
            and is documented in the file orbits.pdf in the root directory
            of that repository.

            Build 0  1900-01-01 00:00  */
    

    key deployer;                       // ID of deployer who hatched us
    integer massChannel =  -982449822 ;  // Channel for communicating with deployer
    string ypres = "B?+:$$";            // It's pronounced "Wipers"

    //  Configuration parameters

    integer m_index;                    // Index of body whose orbit we represent
    string m_name;                      // Name of orbit object
    vector m_size;                      // Size
    vector m_colour;                    // Colour
    float m_alpha;                      // Transparency (0 = transparent, 1 = solid)

    default {

        on_rez(integer sparam) {
            deployer = llList2Key(llGetObjectDetails(llGetKey(),
                            [ OBJECT_REZZER_KEY ]), 0);
            m_index = sparam;

            if (sparam == 0) {
                llSetLinkPrimitiveParamsFast(LINK_THIS, [
                    PRIM_COLOR, ALL_SIDES, <1, 0.64706, 0>, 1
                ]);
            } else {
                //  Listen for messages from deployer
                llListen(massChannel, "", NULL_KEY, "");
                //  Inform the deployer that we are now listening
                llRegionSayTo(deployer, massChannel,
                    llList2Json(JSON_ARRAY, [ "ORBITAL", m_index ]));
            }
        }

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
                        m_name = llList2String(msg, 2);
                        m_size = (vector) llList2String(msg, 3);
                        m_colour = (vector) llList2String(msg, 5);
                        m_alpha = (float) llList2Float(msg, 6);
                        llSetLinkPrimitiveParamsFast(LINK_THIS, [
                            PRIM_NAME, m_name,
                            PRIM_SIZE, m_size,
                            PRIM_COLOR, ALL_SIDES, m_colour, m_alpha
                        ]);

                    
                        } else if (ccmd == "VERSION") {
                            if ("0" != llList2String(msg, 1)) {
                                llOwnerSay(llGetScriptName() +
                                           " build mismatch: Deployer " + llList2String(msg, 1) +
                                           " Local 0");
                            }
                    
                    }
                }
            }
        }
    }
