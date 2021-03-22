
    
        /*  NOTE: This program was automatically generated by the Nuweb
            literate programming tool.  It is not intended to be modified
            directly.  If you wish to modify the code or use it in another
            project, you should start with the master, which is kept in the
            file orbits.w in the public GitHub repository:
                https://github.com/Fourmilab/orbits.git
            and is documented in the file orbits.pdf in the root directory
            of that repository.

            Build 0  1900-01-01 00:00  */
    

    integer BODY = 2;               // Our body number


   /*       __   _____ _ __  _   _ ___
            \ \ / / _ \ '_ \| | | / __|
             \ V /  __/ | | | |_| \__ \
              \_/ \___|_| |_|\__,_|___/
    */
    list termL0 = [
        3.17614666774, 0, 0,
        0.01353968419, 5.59313319619, 10213.285546211,
        0.00089891645, 5.30650048468, 20426.571092422,
        5.477201e-005, 4.41630652531, 7860.4193924392,
        3.455732e-005, 2.69964470778, 11790.6290886588,
        2.372061e-005, 2.99377539568, 3930.2096962196,
        1.664069e-005, 4.2501893503, 1577.3435424478,
        1.438322e-005, 4.15745043958, 9683.5945811164,
        1.317108e-005, 5.18668219093, 26.2983197998,
        1.200521e-005, 6.15357115319, 30639.856638633,
        7.69314e-006, 0.81629615911, 9437.762934887,
        7.6138e-006, 1.9501470212, 529.6909650946,
        7.07676e-006, 1.06466707214, 775.522611324,
        5.84836e-006, 3.99839884762, 191.4482661116,
        4.99915e-006, 4.12340210074, 15720.8387848784,
        4.29498e-006, 3.58642859752, 19367.1891622328,
        3.26967e-006, 5.67736583705, 5507.5532386674,
        3.26221e-006, 4.59056473097, 10404.7338123226,
        2.31937e-006, 3.16251057072, 9153.9036160218,
        1.79695e-006, 4.65337915578, 1109.3785520934,
        1.55464e-006, 5.57043888948, 19651.048481098,
        1.28263e-006, 4.22604493736, 20.7753954924,
        1.27907e-006, 0.96209822685, 5661.3320491522,
        1.05547e-006, 1.53721191253, 801.8209311238
    ];

    list termL1 = [
        10213.529430529, 0, 0,
        0.00095707712, 2.46424448979, 10213.285546211,
        0.00014444977, 0.51624564679, 20426.571092422,
        2.13374e-006, 1.79547929368, 30639.856638633,
        1.73904e-006, 2.65535879443, 26.2983197998,
        1.51669e-006, 6.10635282369, 1577.3435424478,
        8.2233e-007, 5.7023413373, 191.4482661116,
        6.9734e-007, 2.68136034979, 9437.762934887,
        5.2408e-007, 3.60013087656, 775.522611324,
        3.8318e-007, 1.03379038025, 529.6909650946,
        2.9633e-007, 1.25056322354, 5507.5532386674,
        2.5056e-007, 6.10664792855, 10404.7338123226
    ];

    list termL2 = [
        0.00054127076, 0, 0,
        3.89146e-005, 0.34514360047, 10213.285546211,
        1.33788e-005, 2.02011286082, 20426.571092422,
        2.3836e-007, 2.04592119012, 26.2983197998,
        1.9331e-007, 3.53527371458, 30639.856638633,
        9.984e-008, 3.97130221102, 775.522611324,
        7.046e-008, 1.51962593409, 1577.3435424478,
        6.014e-008, 0.99926757893, 191.4482661116
    ];

    list termL3 = [
        1.35742e-006, 4.80389020993, 10213.285546211,
        7.7846e-007, 3.66876371591, 20426.571092422,
        2.6023e-007, 0, 0
    ];

    list termL4 = [
        1.14016e-006, 3.14159265359, 0,
        3.209e-008, 5.20514170164, 20426.571092422,
        1.714e-008, 2.51099591706, 10213.285546211
    ];

    list termL5 = [
        8.74e-009, 3.14159265359, 0
    ];

    list termB0 = [
        0.05923638472, 0.26702775813, 10213.285546211,
        0.00040107978, 1.14737178106, 20426.571092422,
        0.00032814918, 3.14159265359, 0,
        1.011392e-005, 1.08946123021, 30639.856638633,
        1.49458e-006, 6.25390296069, 18073.7049386502,
        1.37788e-006, 0.86020146523, 1577.3435424478,
        1.29973e-006, 3.67152483651, 9437.762934887,
        1.19507e-006, 3.70468812804, 2352.8661537718,
        1.07971e-006, 4.53903677647, 22003.9146348698
    ];

    list termB1 = [
        0.00513347602, 1.80364310797, 10213.285546211,
        4.3801e-005, 3.38615711591, 20426.571092422,
        1.99162e-006, 0, 0,
        1.96586e-006, 2.53001197486, 30639.856638633
    ];

    list termB2 = [
        0.00022377665, 3.38509143877, 10213.285546211,
        2.81739e-006, 0, 0,
        1.73164e-006, 5.25563766915, 20426.571092422,
        2.6945e-007, 3.87040891568, 30639.856638633
    ];

    list termB3 = [
        6.46671e-006, 4.99166565277, 10213.285546211,
        1.9952e-007, 3.14159265359, 0,
        5.54e-008, 0.77376923951, 20426.571092422,
        2.526e-008, 5.4449376302, 30639.856638633
    ];

    list termB4 = [
        1.4102e-007, 0.31537190181, 10213.285546211
    ];

    list termR0 = [
        0.72334820905, 0, 0,
        0.00489824185, 4.02151832268, 10213.285546211,
        1.658058e-005, 4.90206728012, 20426.571092422,
        1.632093e-005, 2.84548851892, 7860.4193924392,
        1.378048e-005, 1.128465906, 11790.6290886588,
        4.98399e-006, 2.58682187717, 9683.5945811164,
        3.73958e-006, 1.42314837063, 3930.2096962196,
        2.63616e-006, 5.5293818592, 9437.762934887,
        2.37455e-006, 2.55135903978, 15720.8387848784,
        2.21983e-006, 2.01346776772, 19367.1891622328,
        1.25896e-006, 2.72769833559, 1577.3435424478,
        1.19467e-006, 3.01975365264, 10404.7338123226
    ];

    list termR1 = [
        0.00034551039, 0.89198710598, 10213.285546211,
        2.34203e-006, 1.77224942714, 20426.571092422,
        2.33998e-006, 3.14159265359, 0
    ];

    list termR2 = [
        1.406587e-005, 5.0636639519, 10213.285546211,
        1.5529e-007, 5.47321687981, 20426.571092422,
        1.3059e-007, 0, 0
    ];

    list termR3 = [
        4.9582e-007, 3.2226355452, 10213.285546211
    ];

    list termR4 = [
        5.73e-009, 0.9222969782, 10213.285546211
    ];



    integer LM_EP_CALC = 431;           // Calculate ephemeris
    integer LM_EP_RESULT = 432;         // Ephemeris calculation result
    integer LM_EP_STAT = 433;           // Print memory status



    
        float fixangr(float a) {
            return a - (TWO_PI * (llFloor(a / TWO_PI)));
        }
    

    list posPlanet(integer jd, float jdf) {
        float tau = ((jd -  2451545 ) / 365250.0) + (jdf / 365250.0);
        float tau2 = tau * tau;
        float tau3 = tau2 * tau;
        float tau4 = tau3 * tau;
        float tau5 = tau4 * tau;

        float L = 0;
        float B = 0;
        float R = 0;

        integer i;
        integer n;
        float x;


    

        n = llGetListLength(termL0);
        x = 0;
        for (i = n - 3; i >= 0; i -= 3) {
            x += llList2Float(termL0, i) *
                llCos(llList2Float(termL0, i + 1) +
                      llList2Float(termL0, i + 2) * tau);
        }
        L += x * 1;
    
    
    

        n = llGetListLength(termL1);
        x = 0;
        for (i = n - 3; i >= 0; i -= 3) {
            x += llList2Float(termL1, i) *
                llCos(llList2Float(termL1, i + 1) +
                      llList2Float(termL1, i + 2) * tau);
        }
        L += x * tau;
    
    
    

        n = llGetListLength(termL2);
        x = 0;
        for (i = n - 3; i >= 0; i -= 3) {
            x += llList2Float(termL2, i) *
                llCos(llList2Float(termL2, i + 1) +
                      llList2Float(termL2, i + 2) * tau);
        }
        L += x * tau2;
    
    
    

        n = llGetListLength(termL3);
        x = 0;
        for (i = n - 3; i >= 0; i -= 3) {
            x += llList2Float(termL3, i) *
                llCos(llList2Float(termL3, i + 1) +
                      llList2Float(termL3, i + 2) * tau);
        }
        L += x * tau3;
    
    
    

        n = llGetListLength(termL4);
        x = 0;
        for (i = n - 3; i >= 0; i -= 3) {
            x += llList2Float(termL4, i) *
                llCos(llList2Float(termL4, i + 1) +
                      llList2Float(termL4, i + 2) * tau);
        }
        L += x * tau4;
    
    
    

        n = llGetListLength(termL5);
        x = 0;
        for (i = n - 3; i >= 0; i -= 3) {
            x += llList2Float(termL5, i) *
                llCos(llList2Float(termL5, i + 1) +
                      llList2Float(termL5, i + 2) * tau);
        }
        L += x * tau5;
    
    

    

        n = llGetListLength(termB0);
        x = 0;
        for (i = n - 3; i >= 0; i -= 3) {
            x += llList2Float(termB0, i) *
                llCos(llList2Float(termB0, i + 1) +
                      llList2Float(termB0, i + 2) * tau);
        }
        B += x * 1;
    
    
    

        n = llGetListLength(termB1);
        x = 0;
        for (i = n - 3; i >= 0; i -= 3) {
            x += llList2Float(termB1, i) *
                llCos(llList2Float(termB1, i + 1) +
                      llList2Float(termB1, i + 2) * tau);
        }
        B += x * tau;
    
    
    

        n = llGetListLength(termB2);
        x = 0;
        for (i = n - 3; i >= 0; i -= 3) {
            x += llList2Float(termB2, i) *
                llCos(llList2Float(termB2, i + 1) +
                      llList2Float(termB2, i + 2) * tau);
        }
        B += x * tau2;
    
    
    

        n = llGetListLength(termB3);
        x = 0;
        for (i = n - 3; i >= 0; i -= 3) {
            x += llList2Float(termB3, i) *
                llCos(llList2Float(termB3, i + 1) +
                      llList2Float(termB3, i + 2) * tau);
        }
        B += x * tau3;
    
    
    

        n = llGetListLength(termB4);
        x = 0;
        for (i = n - 3; i >= 0; i -= 3) {
            x += llList2Float(termB4, i) *
                llCos(llList2Float(termB4, i + 1) +
                      llList2Float(termB4, i + 2) * tau);
        }
        B += x * tau4;
    
    

    

        n = llGetListLength(termR0);
        x = 0;
        for (i = n - 3; i >= 0; i -= 3) {
            x += llList2Float(termR0, i) *
                llCos(llList2Float(termR0, i + 1) +
                      llList2Float(termR0, i + 2) * tau);
        }
        R += x * 1;
    
    
    

        n = llGetListLength(termR1);
        x = 0;
        for (i = n - 3; i >= 0; i -= 3) {
            x += llList2Float(termR1, i) *
                llCos(llList2Float(termR1, i + 1) +
                      llList2Float(termR1, i + 2) * tau);
        }
        R += x * tau;
    
    
    

        n = llGetListLength(termR2);
        x = 0;
        for (i = n - 3; i >= 0; i -= 3) {
            x += llList2Float(termR2, i) *
                llCos(llList2Float(termR2, i + 1) +
                      llList2Float(termR2, i + 2) * tau);
        }
        R += x * tau2;
    
    
    

        n = llGetListLength(termR3);
        x = 0;
        for (i = n - 3; i >= 0; i -= 3) {
            x += llList2Float(termR3, i) *
                llCos(llList2Float(termR3, i + 1) +
                      llList2Float(termR3, i + 2) * tau);
        }
        R += x * tau3;
    
    
    

        n = llGetListLength(termR4);
        x = 0;
        for (i = n - 3; i >= 0; i -= 3) {
            x += llList2Float(termR4, i) *
                llCos(llList2Float(termR4, i + 1) +
                      llList2Float(termR4, i + 2) * tau);
        }
        R += x * tau4;
    
    


        return [ fixangr(L), B, R ];
    }



    default {
        state_entry() {
        }

        link_message(integer sender, integer num, string str, key id) {
            
                integer LM_AS_LEGEND = 541;         // Update floating text legend
                integer LM_AS_SETTINGS = 542;       // Update settings
                integer LM_AS_VERSION = 543;        // Check version consistency
            
            
            //  LM_EP_CALC (431): Calculate ephemeris

            if (num == LM_EP_CALC) {
                list args = llCSV2List(str);
                integer argn = llGetListLength(args);
                if (llList2Integer(args, 0) & (1 << BODY)) {
                    list eph = [ ];
                    integer i;

                    for (i = 1; (i + 1) < argn; i += 2) {
                        eph += posPlanet(llList2Integer(args, i),
                                         llList2Float(args, i + 1));
                    }
                    integer handle = llList2Integer(args, i);
                    llMessageLinked(LINK_THIS, LM_EP_RESULT,
                        (string) BODY + "," +
                        llList2CSV(eph + [ handle ]), id);
                }
            
            
                //  LM_AS_VERSION (543): Check version consistency
                } else if (num == LM_AS_VERSION) {
                    if ("0" != str) {
                        llOwnerSay(llGetScriptName() +
                                   " build mismatch: Deployer " + str +
                                   " Local 0");
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
