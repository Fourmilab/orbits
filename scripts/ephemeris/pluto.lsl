
   /*              _       _
             _ __ | |_   _| |_ ___
            | '_ \| | | | | __/ _ \
            | |_) | | |_| | || (_) |
            | .__/|_|\__,_|\__\___/
            |_|
    */

    /*  Each periodic term entry contains the factors by which the
        three fundamental angles are multiplied to form the alpha
        value.  The sine and cosine of alpha are combined with
        longitude, latitude, and radius values from the terms to
        sum to the final position.

        In order to preserve precision and in the interest of
        efficiency, we store all of these values as integers,
        with the longitude and latitude scaled by 1e-6 and the
        radius scaled by 1e-7.  */

    list plutoTerms = [
        /* 1*/ 0, 0, 1, -19798886, 19848454, -5453098, -14974876, 66867334, 68955876,
        /* 2*/ 0, 0, 2, 897499, -4955707, 3527363, 1672673, -11826086, -333765,
        /* 3*/ 0, 0, 3, 610820, 1210521, -1050939, 327763, 1593657, -1439953,
        /* 4*/ 0, 0, 4, -341639, -189719, 178691, -291925, -18948, 482443,
        /* 5*/ 0, 0, 5, 129027, -34863, 18763, 100448, -66634, -85576,
        /* 6*/ 0, 0, 6, -38215, 31061, -30594, -25838, 30841, -5765,
        /* 7*/ 0, 1, -1, 20349, -9886, 4965, 11263, -6140, 22254,
        /* 8*/ 0, 1, 0, -4045, -4904, 310, -132, 4434, 4443,
        /* 9*/ 0, 1, 1, -5885, -3238, 2036, -947, -1518, 641,
        /*10*/ 0, 1, 2, -3812, 3011, -2, -674, -5, 792,
        /*11*/ 0, 1, 3, -601, 3468, -329, -563, 518, 518,
        /*12*/ 0, 2, -2, 1237, 463, -64, 39, -13, -221,
        /*13*/ 0, 2, -1, 1086, -911, -94, 210, 837, -494,
        /*14*/ 0, 2, 0, 595, -1229, -8, -160, -281, 616,
        /*15*/ 1, -1, 0, 2484, -485, -177, 259, 260, -395,
        /*16*/ 1, -1, 1, 839, -1414, 17, 234, -191, -396,
        /*17*/ 1, 0, -3, -964, 1059, 582, -285, -3218, 370,
        /*18*/ 1, 0, -2, -2303, -1038, -298, 692, 8019, -7869,
        /*19*/ 1, 0, -1, 7049, 747, 157, 201, 105, 45637,
        /*20*/ 1, 0, 0, 1179, -358, 304, 825, 8623, 8444,
        /*21*/ 1, 0, 1, 393, -63, -124, -29, -896, -801,
        /*22*/ 1, 0, 2, 111, -268, 15, 8, 208, -122,
        /*23*/ 1, 0, 3, -52, -154, 7, 15, -133, 65,
        /*24*/ 1, 0, 4, -78, -30, 2, 2, -16,
        /*25*/ 1, 1, -3, -34, -26, 4, 2, -22, 7,
        /*26*/ 1, 1, -2, -43, 1, 3, 0, -8, 16,
        /*27*/ 1, 1, -1, -15, 21, 1, -1, 2, 9,
        /*28*/ 1, 1, 0, -1, 15, 0, -2, 12, 5,
        /*29*/ 1, 1, 1, 4, 7, 1, 0, 1, -3,
        /*30*/ 1, 1, 3, 1, 5, 1, -1, 1, 0,
        /*31*/ 2, 0, -6, 8, 3, -2, -3, 9, 5,
        /*32*/ 2, 0, -5, -3, 6, 1, 2, 2, -1,
        /*33*/ 2, 0, -4, 6, -13, -8, 2, 14, 10,
        /*34*/ 2, 0, -3, 10, 22, 10, -7, -65, 12,
        /*35*/ 2, 0, -2, -57, -32, 0, 21, 126, -233,
        /*36*/ 2, 0, -1, 157, -46, 8, 5, 270, 1068,
        /*37*/ 2, 0, 0, 12, -18, 13, 16, 254, 155,
        /*38*/ 2, 0, 1, -4, 8, -2, -3, -26, -2,
        /*39*/ 2, 0, 2, -5, 0, 0, 0, 7, 0,
        /*40*/ 2, 0, 3, 3, 4, 0, 1, -11, 4,
        /*41*/ 3, 0, -2, -1, -1, 0, 1, 4, -14,
        /*42*/ 3, 0, -1, 6, -3, 0, 0, 18, 35,
        /*43*/ 3, 0, 0, -1, -2, 0, 1, 13, 3
    ];

    integer J2000 = 2451545;            // Julian day of J2000 epoch
    float JulianCentury = 36525.0;      // Days in Julian century

    list posPluto(integer jd, float jdf) {

        /* This expansion for Pluto's position is valid only for years
           between 1885 and 2099.  If the date given is outside that
           range, return zero for the position.  */

        if ((jd < 2409543.0) || (jd >= 2488070.0)) {
            return [ 0, 0, 0 ];
        }

        float t = ((jd - J2000) / JulianCentury) + (jdf / JulianCentury);

        float j = DEG_TO_RAD * ( 34.35 + (3034.9057 * t));
        float s = DEG_TO_RAD * ( 50.08 + (1222.1138 * t));
        float p = DEG_TO_RAD * (238.96 +  (144.9600 * t));

        //  Initial components of position before periodic terms

        float cl = 238.956785 + 144.96 * t;
        float cb = -3.908202;
        float cr = 40.7247248;

        integer i;
        integer n = llGetListLength(plutoTerms);

        float lbscale = 0.000001;
        float rscale = 0.0000001;

        for (i = 0; i < n; i += 9) {
            float alpha = (llList2Integer(plutoTerms, i) * j) +
                          (llList2Integer(plutoTerms, i + 1) * s) +
                          (llList2Integer(plutoTerms, i + 2) * p);
            float salpha = llSin(alpha);
            float calpha = llCos(alpha);
            cl += (llList2Integer(plutoTerms, i + 3) * salpha * lbscale) +
                  (llList2Integer(plutoTerms, i + 4) * calpha * lbscale);
            cb += (llList2Integer(plutoTerms, i + 5) * salpha * lbscale) +
                  (llList2Integer(plutoTerms, i + 6) * calpha * lbscale);
            cr += (llList2Integer(plutoTerms, i + 7) * salpha * rscale) +
                  (llList2Integer(plutoTerms, i + 8) * calpha * rscale);
        }

        return [ fixangr(DEG_TO_RAD * cl), fixangr(DEG_TO_RAD * cb), cr ];
    }

    //  fixangr  --  Range reduce an angle in radians

    float fixangr(float a) {
        return a - (TWO_PI * (llFloor(a / TWO_PI)));
    }

    integer BODY = 9;                   // Our body number

    integer LM_EP_CALC = 431;           // Calculate ephemeris
    integer LM_EP_RESULT = 432;         // Ephemeris calculation result
    integer LM_EP_STAT = 433;           // Print memory status

    default {
        state_entry() {
        }

        link_message(integer sender, integer num, string str, key id) {

            //  LM_EP_CALC (431): Calculate ephemeris

            if (num == LM_EP_CALC) {
                list args = llCSV2List(str);
                integer argn = llGetListLength(args);
                if (llList2Integer(args, 0) & (1 << BODY)) {
                    list eph = [ ];
                    integer i;

                    for (i = 1; (i + 1) < argn; i += 2) {
                        eph += posPluto(llList2Integer(args, i),
                                        llList2Float(args, i + 1));
                    }
                    integer handle = llList2Integer(args, i);
                    llMessageLinked(LINK_THIS, LM_EP_RESULT,
                        (string) BODY + "," +
                        llList2CSV(eph + [ handle ]), id);
                }

            //  LM_EP_STAT (433): Print memory status

            } else if (num == LM_EP_STAT) {
                integer mFree = llGetFreeMemory();
                integer mUsed = llGetUsedMemory();
                llOwnerSay(llGetScriptName() + " status:" +
                     " Script memory.  Free: " + (string) mFree +
                        "  Used: " + (string) mUsed + " (" +
                        (string) ((integer) llRound((mUsed * 100.0) / (mUsed + mFree))) + "%)"
                );
            }
        }
    }
