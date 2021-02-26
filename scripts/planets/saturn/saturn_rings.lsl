
    //  Saturn ring system configurator

    integer ringDia = 140390;           // Ring system diameter (km)

    //  Link messages

    integer LM_PL_PINIT = 531;          // Initialisation parameters

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

    default {

        state_entry() {
        }

        //  Process messages from other scripts

        link_message(integer sender, integer num, string str, key id) {

            //  Script Processor Messages

            //  LM_PL_PINIT (531): Initialise upon rez

            if (num == LM_PL_PINIT) {
                list msg = llJson2List(str);
                string ccmd = llList2String(msg, 0);

                if (ccmd == "PINIT") {
                    float m_scalePlanet = siuf(llList2String(msg, 4));  // Planet scale

                    //  Set properties of object
                    vector psize = < ringDia,
                                     ringDia,
                                     5 > * 0.0001 * m_scalePlanet;
                    llSetLinkPrimitiveParamsFast(LINK_THIS, [
                        PRIM_SIZE, psize
                    ]);
                }
            }
        }
     }
