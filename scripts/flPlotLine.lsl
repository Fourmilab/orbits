    /*
            flPlotLine Object Creation Settings

        Note that the object is created transparent, and only
        becomes visible when its colour and opacity is set
        after we've received control and decoded the start
        parameter.  This avoids having mis-scaled and -coloured
        objects appear for a while when rezzing in regions with
        a long delay between llRezObject() and on_rez() running
        in the new object.  */

    //  List of selectable diameters for lines
    list diam = [ 0.01, 0.05, 0.1, 0.5 ];

    default {

        on_rez(integer sparam) {
            llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_TEMP_ON_REZ, TRUE ]);
//            llOwnerSay("Sparam " + (string) sparam + " vel " + (string) llGetVel());

            /*  Decode start parameter:
                    Bits        Content
                    23-22       Diameter (index into diam list)
                    21-10       Colour (RRRRGGGGBBBB, 0-63 scaled)
                     9-0        Length (0.01 to 10.24 metres)  */

            float len = 0.01 + ((sparam & 1023) / 100.0);

            integer colspec = (sparam >> 10) & 0xFFF;
            vector colour = < (colspec >> 8),
                              (colspec >> 4) & 0xF,
                              (colspec & 0xF) > / 15.0;

            float diameter = llList2Float(diam, (sparam >> 22) & 3);
//            llOwnerSay("len " + (string) len +
//                "  colspec " + (string) colspec + "  col " + (string) colour +
//                " dia " + (string) diameter);
            llSetLinkPrimitiveParamsFast(LINK_THIS, [
                PRIM_SIZE, < diameter, diameter, len >,
                PRIM_COLOR, ALL_SIDES, colour, 1
            ]);
        }
    }
