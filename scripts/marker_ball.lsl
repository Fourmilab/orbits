    /*
                            Marker Ball

        Note that the object is created transparent, and only
        becomes visible when its colour and opacity is set
        after we've received control and decoded the start
        parameter.  This avoids having mis-scaled and -coloured
        objects appear for a while when rezzing in regions with
        a long delay between llRezObject() and on_rez() running
        in the new object.  */

    key deployer;                       // ID of deployer who hatched us
    integer massChannel = -982449822;   // Channel for communications
    string ypres = "B?+:$$";            // It's pronounced "Wipers"

    default {

        on_rez(integer sparam) {
//            llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_TEMP_ON_REZ, TRUE ]);
//            llOwnerSay("Sparam " + (string) sparam + " vel " + (string) llGetVel());

            deployer = llList2Key(llGetObjectDetails(llGetKey(),
                                     [ OBJECT_REZZER_KEY ]), 0);

            //  Listen for messages from deployer
            llListen(massChannel, "", NULL_KEY, "");

            /*  Decode start parameter:
                    Bits        Content
                    31-24       Size (1 to 256 cm)
                    23-16       Colour R
                    15-8        Colour G
                     7-0        Colour B    */

            vector colour = < (sparam >> 16) & 0xFF,
                              (sparam >> 8) & 0xFF,
                              (sparam & 0xFF) > / 255.0;

            float diameter = (((sparam >> 24) & 0xFF) / 255.0) + 0.01;

//            llOwnerSay("  colour " + (string) colour + " diam " + (string) diameter);

            llSetLinkPrimitiveParamsFast(LINK_THIS, [
                PRIM_SIZE, < diameter, diameter, diameter >,
                PRIM_COLOR, ALL_SIDES, colour, 1
            ]);
        }

        //  The listen event handles message from the deployer

        listen(integer channel, string name, key id, string message) {
//llOwnerSay(llGetScriptName() + " channel " + (string) channel + " id " + (string) id +  " message " + message);
            if (channel == massChannel) {
                list msg = llJson2List(message);
                string ccmd = llList2String(msg, 0);

                if (id == deployer) {

                    //  Message from Deployer

                    //  ypres  --  Destroy marker

                    if (ccmd == ypres) {
                        llDie();
                    }
                }
            }
        }
    }
