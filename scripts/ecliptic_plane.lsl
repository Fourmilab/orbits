    /*

                    Fourmilab Solar System

                        Ecliptic Plane

    */

    key owner;                          // UUID of owner
    key whoDat;                         // User with whom we're communicating
    key deployer;                       // ID of deployer who created us

    integer massChannel = -982449822;   // Channel for communicating with planets
    string ypres = "B?+:$$";            // It's pronounced "Wipers"
    string planecrash = "P?+:$$";       // Selectively delete ecliptic plane

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
        }

        on_rez(integer start_param) {
            //  If start_param is zero, this is a simple manual rez
            if (start_param != 0) {
                deployer = llList2Key(llGetObjectDetails(llGetKey(),
                                         [ OBJECT_REZZER_KEY ]), 0);

                /*  Scale plane to correct size.  The size in metres is
                    passed in the start_param in units of centimetres.  */
                float xyscale = start_param / 100.0;
                llSetLinkPrimitiveParamsFast(LINK_THIS, [
                    PRIM_SIZE, < xyscale, xyscale, 0.01 >
                ]);

                //  Listen for messages from deployer
                llListen(massChannel, "", NULL_KEY, "");
            }
        }

        //  The listen event handles messages from the deployer

        listen(integer channel, string name, key id, string message) {

            if (channel == massChannel) {
                list msg = llJson2List(message);
                string ccmd = llList2String(msg, 0);

                if (id == deployer) {

                    //  Message from our Deployer

                    //  ypres       --  Destroy everything, including us
                    //  planecrash  --  Remove just ecliptic plane

                    if ((ccmd == ypres) || (ccmd == planecrash)) {
                        llDie();
                    }
                }
            }
        }
    }
