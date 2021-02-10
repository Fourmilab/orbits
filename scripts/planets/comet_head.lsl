    /*

                        Fourmilab Orbits

                        Comet Head Script

    */

    key owner;                          // UUID of owner
    key whoDat;                         // User with whom we're communicating

    //  Link messages

    integer LM_CO_COMA = 81;            // Set coma intensity
    integer LM_CO_SCALE = 82;           // Set scale factor

    //  head  --  Display the head (coma) of the comet

    head(float size) {
        if (size > 0) {
            llParticleSystem([

                //  System Behaviour
                PSYS_PART_FLAGS,
                                   PSYS_PART_EMISSIVE_MASK
                                 | PSYS_PART_FOLLOW_SRC_MASK
                                 | PSYS_PART_INTERP_COLOR_MASK
                                 | PSYS_PART_INTERP_SCALE_MASK
                                 ,

                //  System Presentation
                PSYS_SRC_PATTERN,
                                PSYS_SRC_PATTERN_DROP
                                ,

                PSYS_SRC_BURST_RADIUS, 0.1,
                PSYS_SRC_ANGLE_BEGIN,  0,
                PSYS_SRC_ANGLE_END,    0.5,

                //  Particle appearance
                PSYS_PART_START_COLOR, <0, 0.8, 0.85098>,
                PSYS_PART_END_COLOR,   <0, 0.8, 0.85098>,
                PSYS_PART_START_ALPHA, 0.25,
                PSYS_PART_END_ALPHA,   0,
                PSYS_PART_START_SCALE, < 0.03, 0.03, 0.03 >,
                PSYS_PART_END_SCALE,   < 0.3, 0.3, 0.3 >,
                PSYS_PART_START_GLOW,  0.0,
                PSYS_PART_END_GLOW,    0.0,

                //  Particle Blending
                PSYS_PART_BLEND_FUNC_SOURCE,
                                           PSYS_PART_BF_SOURCE_ALPHA
                                           ,
                PSYS_PART_BLEND_FUNC_DEST,
                                           PSYS_PART_BF_ONE_MINUS_SOURCE_ALPHA
                                           ,

                //  Particle Flow
                PSYS_SRC_MAX_AGE,          0,
                PSYS_PART_MAX_AGE,         0.5 * size,
                PSYS_SRC_BURST_RATE,       0.02,
                PSYS_SRC_BURST_PART_COUNT, 4,

                //  Particle Motion
                PSYS_SRC_ACCEL,           <0, 0, 0>,
                PSYS_SRC_OMEGA,           <0, 0, 0>,
                PSYS_SRC_BURST_SPEED_MIN, 1,
                PSYS_SRC_BURST_SPEED_MAX, 1

            ]);
        } else {
            llParticleSystem([ ]);
        }
    }

    default {

        state_entry() {
            whoDat = owner = llGetOwner();
            head(0);
        }

        link_message(integer sender, integer num, string str, key id) {

            //  LM_CO_COMA (81): Set intensity of coma

            if (num == LM_CO_COMA) {
                head((float) str);

            //  LM_CO_SCALE (82): Scale coma with parent body size
            } else if (num == LM_CO_SCALE) {
                vector psize = llList2Vector(llGetLinkPrimitiveParams(LINK_THIS,
                    [ PRIM_SIZE ]), 0);
                psize *= (float) str;
                llSetLinkPrimitiveParamsFast(LINK_THIS, [
                    PRIM_SIZE, psize            // Scale to proper size
                ]);
            }
        }
    }
