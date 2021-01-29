    /*

             Fourmilab Script Processor

                    by John Walker

    */

    //  Script Processor messages
    integer LM_SP_INIT = 50;        // Initialise
    integer LM_SP_RESET = 51;       // Reset script
    integer LM_SP_STAT = 52;        // Print status
    integer LM_SP_RUN = 53;         // Add script to queue
    integer LM_SP_GET = 54;         // Request next line from script
    integer LM_SP_INPUT = 55;       // Input line from script
    integer LM_SP_EOF = 56;         // Script input at end of file
    integer LM_SP_READY = 57;       // New script ready
    integer LM_SP_ERROR = 58;       // Requested operation failed

    string ncSource = "";           // Current notecard being read
    key ncQuery;                    // Handle for notecard query
    integer ncLine = 0;             // Current line in notecard
    integer ncBusy = FALSE;         // Are we reading a notecard ?
    float pauseExpiry = -1;         // Time [llGetTime()] when current pause expires
    integer pauseManual = FALSE;    // In manual pause ?
    integer pauseRegion = FALSE;    // Pause until region change
    integer regionChanged = 0;      // Count region changes
    list ncQueue = [ ];             // Stack of pending notecards to read
    list ncQline = [ ];             // Stack of pending notecard positions
    list ncLoops = [ ];             // Loop stack

    key whoDat;                     // User (UUID) who requested script

    key owner;                      // Owner of the vehicle
    key agent = NULL_KEY;           // Pilot, if any
    integer trace = FALSE;          // Generate trace output ?

    //  Command processor messages

    integer LM_CP_COMMAND = 223;    // Process command

    /*  tawk  --  Send a message to the interacting user in chat.
                  The recipient of the message is defined as
                  follows.  If an agent has provoked the message,
                  that avatar receives the message.  Otherwise,
                  the message goes to the owner of the object.
                  In either case, if the message is being sent to
                  the owner, it is sent with llOwnerSay(), which isn't
                  subject to the region rate gag, rather than
                  llRegionSayTo().  */

    tawk(string msg) {
        key whom = owner;
        if (agent != NULL_KEY) {
            whom = agent;
        }
        if (whom == owner) {
            llOwnerSay(msg);
        } else {
            llRegionSayTo(whom, PUBLIC_CHANNEL, msg);
        }
    }

    /*  ttawk  --  Send a message with tawk(), but only if trace
                   is nonzero.  This should only be used for simple
                   messages generated infrequently.  For complex,
                   high-volume messages you should use:
                       if (trace) { tawk(whatever); }
                   because that will not generate the message or call a
                   function when trace is not set.  */

    ttawk(string msg) {
        if (trace) {
            tawk(msg);
        }
    }

    //  abbrP  --  Test if string matches abbreviation

    integer abbrP(string str, string abbr) {
        return abbr == llGetSubString(str, 0, llStringLength(abbr) - 1);
    }

    //  pinterval  --  Parse an interval specification

    float pinterval(list args, integer n) {
        string ints = llList2String(args, n);
        string unit = llGetSubString(ints, -1, -1);

        if (llSubStringIndex("smhd", unit) >= 0) {
            ints = llGetSubString(ints, 0, -1);
        } else {
            unit = "s";
        }

        float interval = (float) ints;

        //  Note that seconds are implicit
        if (unit == "m") {
            interval *= 60;
        } else if (unit == "h") {
            interval *= 60 * 60;
        } else if (unit == "d") {
            interval *= 60 * 60 * 24;
        }
        return interval;
    }

    /*  processScriptCommand  --  Handle commands local to script processor.
                                  Returns TRUE if the command was processed
                                  locally, FALSE if it should be returned to
                                  the client.  These commands may be used
                                  only within scripts.  */

    integer processScriptCommand(string message) {
        integer echoCmd = TRUE;
        if (llGetSubString(llStringTrim(message, STRING_TRIM_HEAD), 0, 0) == "@") {
            echoCmd = FALSE;
            message = llGetSubString(llStringTrim(message, STRING_TRIM_HEAD), 1, -1);
        }

        string lmessage = llToLower(llStringTrim(message, STRING_TRIM));
        list args = llParseString2List(lmessage, [" "], [ ]);   // Command and arguments
        integer argn = llGetListLength(args);

        if ((argn >= 2) &&
            abbrP(llList2String(args, 0), "sc")) {

            string command = llList2String(args, 1);

            //  Script loop [n]             -- Loop n times (default infinite)

            if (abbrP(command, "lo")) {
                integer iters = -1;

                if (argn >= 3) {
                    iters = llList2Integer(args, 2);
                }
                ncLoops = [ iters, ncLine ] + ncLoops;

            //  Script end                  -- End loop

            } else if (abbrP(command, "en")) {
                integer iters = llList2Integer(ncLoops, 0);

                if ((iters > 1) || (iters < 0)) {
                    //  Make another iteration
                    if (iters > 1) {
                        iters--;
                    }
                    //  Update iteration count in loop stack
                    ncLoops = llListReplaceList(ncLoops, [ iters ], 0, 0);
                    //  Set line counter to line after loop statement
                    ncLine = llList2Integer(ncLoops, 1);
                } else {
                    /*  Final iteration: continue after end statement,
                        pop loop stack.  */
                    ncLoops = llDeleteSubList(ncLoops, 0, 1);
                }

            //  Script pause [ n/touch/region ] -- Wait n seconds, default 1, or for touch or region change

            } else if (abbrP(command, "pa")) {
                float howlong = 1;

                if (argn >= 3) {
                    string parg = llList2String(args, 2);

                    if (abbrP(parg, "to")) {
                        pauseManual = TRUE;
                    } else if (abbrP(parg, "re")) {
                        if (regionChanged == 0) {
                            pauseRegion = TRUE;
                        } else {
                            regionChanged = 0;
                        }
                    } else {
                        howlong = (float) parg;
                    }
                }

                if ((!pauseManual) && (!pauseRegion)) {
                    /*  Naively, you might ask why we don't just use llSleep()
                        here rather than going to all this trouble.  Well,
                        you see, even though each script is logically its own
                        process, in a dynamic, multi-script environment, with
                        lots of link messages flying about, scripts must cope
                        with the fact that the event queue is limited to only
                        64 items, after which events are silently discarded.
                        If an event goes dark for a while, as llSleep() would
                        cause it to do, it ceases to receive events and before
                        long its inbound event queue will overflow, resulting
                        in lost messages and all kinds of mayhem (usually
                        manifesting as just going to sleep for no apparent reason).

                        Note that this happens even if the link messages are not
                        directed to us, as there is no way to direct a link
                        message to a particular script.

                        Instead, we set the global variable pauseExpiry to the
                        llGetTime() value at which we wish the script to resume
                        and then rely upon the timer to get things going again
                        when that time arrives.  This leaves us able to receive
                        (and in all likelihood, ignore) the myriad messages that
                        may drop in the in-box while the pause is in effect.  */

                    pauseExpiry = llGetTime() + howlong;
                }

            //  Script wait [ n[unit] ] [ offset[unit] ] -- Wait until the next even n units + offset

            } else if (abbrP(command, "wa")) {
                float interval = 60;        // Default interval 1 minute
                float offset = 0;           // Default offset zero

                if (argn >= 3) {
                    interval = pinterval(args, 2);
                    if (argn >= 4) {
                        offset = pinterval(args, 3);
                    }
                }

                /*  Note that we use llGetUnixTime() here because we
                    wish to synchronise to even intervals on the wall
                    clock.  For example, if the user sets a wait for
                    every 10 minutes, we want to run at the top of
                    the next even 10 minutes, not 10 minutes from now.
                    If we used llGetTime(), we'd be syncing to
                    whenever the script started keeping its own
                    time, whatever that may be.  Now llGetUnixTime()
                    doesn't provide precision better than a second, but
                    the only way around that would be to use timestamps
                    which, being strings, would probably be so costly
                    to process we'd lose comparable precision anyway.  */

                integer t = llGetUnixTime();
                float st = llGetTime();
                pauseExpiry = st +
                    (interval - (t % llRound(interval)));
                if (offset > 0) {
                    pauseExpiry += offset;
                    while ((pauseExpiry - st) > interval) {
                        pauseExpiry -= interval;
                    }
                }
            } else {
                return FALSE;               // It's not one of our "Script"s
            }
            if (echoCmd) {
                tawk("++ " + message);      // Echo command to sender
            }
            return TRUE;
        }
        return FALSE;                       // Not "Script"
    }

    //  processNotecardCommands  --  Read and execute commands from a notecard

    processNotecardCommands(string ncname, key id) {
        if (llGetInventoryKey(ncname) == NULL_KEY) {
            llMessageLinked(LINK_THIS, LM_SP_ERROR, "No notecard named " + ncname, id);
            return;
        }
        if (ncBusy) {
            ncQueue = [ ncSource ] + ncQueue;
            ncQline = [ ncLine ] + ncQline;
            ttawk("Pushing script: " + ncSource + " at line " + (string) ncLine);
            ncSource = ncname;
            ncLine = 0;
        } else {
            ncSource = ncname;
            ncLine = 0;
            ncBusy = TRUE;                  // Mark busy reading notecard
            regionChanged = 0;
            llMessageLinked(LINK_THIS, LM_SP_READY, ncSource, id);
            ttawk("Begin script: " + ncSource);
        }
    }

    /*  inventoryName  --   Extract inventory item name from Set subcmd.
                            This is a horrific kludge which allows
                            names to be upper and lower case.  It finds the
                            subcommand in the lower case command then
                            extracts the text that follows, trimming leading
                            and trailing blanks, from the upper and lower
                            case original command.   */

    string inventoryName(string subcmd, string lmessage, string message) {
        //  Find subcommand in Set subcmd ...
        integer dindex = llSubStringIndex(lmessage, subcmd);
        //  Advance past space after subcmd
        dindex += llSubStringIndex(llGetSubString(lmessage, dindex, -1), " ") + 1;
        //  Note that STRING_TRIM elides any leading and trailing spaces
        return llStringTrim(llGetSubString(message, dindex, -1), STRING_TRIM);
    }

    /*  processAuxCommand  --  Process a command.  These commands
                               are used by the client to control
                               scripts.  They may appear either
                               in the client's interactive input or
                               in scripts.  */

    integer processAuxCommand(key id, list args) {

        whoDat = id;            // Direct chat output to sender of command

        string message = llList2String(args, 0);
        string lmessage = llList2String(args, 1);
        args = llDeleteSubList(args, 0, 1);
        integer argn = llGetListLength(args);       // Number of arguments
        string command = llList2String(args, 0);    // The command
        string sparam = llList2String(args, 1);     // First argument, for convenience

        //  Script                      Script commands

        if (abbrP(command, "sc") && (argn >= 2)) {

            //  Script list

            if (abbrP(sparam, "li")) {
                integer n = llGetInventoryNumber(INVENTORY_NOTECARD);
                integer i;
                integer j = 0;
                for (i = 0; i < n; i++) {
                    string s = llGetInventoryName(INVENTORY_NOTECARD, i);
                    if ((s != "") && (llGetSubString(s, 0, 7) == "Script: ")) {
                        tawk("  " + (string) (++j) + ". " + llGetSubString(s, 8, -1));
                    }
                }

            //  Script resume               -- Resume after pause

            } else if (abbrP(sparam, "re")) {
                if (ncBusy && ((pauseExpiry > 0) || pauseManual || pauseRegion)) {
                    pauseExpiry = -1;
                    pauseManual = pauseRegion = FALSE;
                    regionChanged = 0;
                    ncQuery = llGetNotecardLine(ncSource, ncLine);
                    ncLine++;
                }

            //  Script run script name

            } else if (abbrP(sparam, "ru")) {
                if (argn == 2) {
                    llResetScript();
                } else {
                    if (!ncBusy) {
                        agent = whoDat = id;            // User who started script
                    }
                    processNotecardCommands("Script: " +
                        inventoryName("ru", lmessage, message), id);
                }
            }
        }
        return TRUE;
    }

    default {

        on_rez(integer start_param) {
            llResetScript();
        }

        state_entry() {
            owner = llGetOwner();
            ncBusy = FALSE;                 // Mark no notecard being read
            pauseExpiry = -1;               // Mark not paused
            llSetTimerEvent(0);             // Cancel event timer
            ncQueue = [ ];                  // Queue of pending notecards
            ncQline = [ ];                  // Clear queue of return line numbers
            ncLoops = [ ];                  // Clear queue of loops
        }

        /*  The link_message() event receives commands from the client
            script and passes them on to the script processing functions
            within this script.  */

        link_message(integer sender, integer num, string str, key id) {
//ttawk("Script processor link message sender " + (string) sender + "  num " + (string) num + "  str " + str + "  id " + (string) id);

            //  LM_SP_INIT (50): Initialise script processor

            if (num == LM_SP_INIT) {
                if (ncBusy && trace) {
                    string nq = "";
                    if (llGetListLength(ncQueue) > 0) {
                        nq = " and outer scripts: " + llList2CSV(ncQueue);
                    }
                    ttawk("Terminating script: " + ncSource + nq);
                }
                ncSource = "";                  // No current notecard
                ncBusy = FALSE;                 // Mark no notecard being read
                pauseExpiry = -1;               // Mark not paused
                pauseManual = FALSE;            // Not in manual pause
                pauseRegion = FALSE;            // Not in region pause
                regionChanged = 0;              // No region change yet
                llSetTimerEvent(0);             // Cancel pause timer, if running
                ncQueue = [ ];                  // Queue of pending notecards
                ncQline = [ ];                  // Clear queue of return line numbers
                ncLoops = [ ];                  // Clear queue of loops

            //  LM_SP_RESET (51): Reset script

            } else if (num == LM_SP_RESET) {
                llResetScript();

            //  LM_SP_STAT (52): Report status

            } else if (num == LM_SP_STAT) {
                string stat = "Script processor:  Busy: " + (string) ncBusy;
                if (ncBusy) {
                    stat += "  Source: " + ncSource + "  Line: " + (string) ncLine +
                            "  Queue: " + llList2CSV(ncQueue) +
                            "  Loops: " + llList2CSV(ncLoops);
                }
                stat += "\n";
                integer mFree = llGetFreeMemory();
                integer mUsed = llGetUsedMemory();
                stat += "    Script memory.  Free: " + (string) mFree +
                        "  Used: " + (string) mUsed + " (" +
                        (string) ((integer) llRound((mUsed * 100.0) / (mUsed + mFree))) + "%)";

                llRegionSayTo(id, PUBLIC_CHANNEL, stat);

            //  LM_SP_RUN (53): Run script

            } else if (num == LM_SP_RUN) {
                if (!ncBusy) {
                    agent = whoDat = id;            // User who started script
                }
                processNotecardCommands(str, id);

            //  LM_SP_GET (54): Get next line from script

            } else if (num == LM_SP_GET) {
                if (ncBusy) {
                    ncQuery = llGetNotecardLine(ncSource, ncLine);
                    ncLine++;
                }

            //  LM_CP_COMMAND (223): Process auxiliary command

            } else if (num == LM_CP_COMMAND) {
                processAuxCommand(id, llJson2List(str));
            }
        }

        //  The dataserver event receives lines from the notecard we're reading

        dataserver(key query_id, string data) {
            if (query_id == ncQuery) {
                if (data == EOF) {
                    if (llGetListLength(ncQueue) > 0) {
                        //  This script is done.  Pop to outer script.
                        ncSource = llList2String(ncQueue, 0);
                        ncQueue = llDeleteSubList(ncQueue, 0, 0);
                        ncLine = llList2Integer(ncQline, 0);
                        ncQline = llDeleteSubList(ncQline, 0, 0);
                        ttawk("Pop to " + ncSource + " line " + (string) ncLine);
                        ncQuery = llGetNotecardLine(ncSource, ncLine);
                        ncLine++;
                    } else {
                        //  Finished top level script.  We're done
                        ncBusy = FALSE;         // Mark notecard input idle
                        ncSource = "";
                        ncLine = 0;
                        ttawk("Hard EOF: all scripts complete");
                        llMessageLinked(LINK_THIS, LM_SP_EOF, "", whoDat);
                    }
                } else {
                    string s = llStringTrim(data, STRING_TRIM);
                    //  Ignore comments and send valid commands to client
                    if ((llStringLength(s) > 0) && (llGetSubString(s, 0, 0) != "#")) {
                        if (processScriptCommand(s)) {
                            if (pauseExpiry > 0) {
                                /*  We have processed a Script pause command
                                    which paused script execution.  Set a timer
                                    event to fetch the next line from the script
                                    when the pause is complete.  */
                                llSetTimerEvent(pauseExpiry - llGetTime());
                            } else if ((!pauseManual) && (!pauseRegion)) {
                                //  Fetch next line from script
                                ncQuery = llGetNotecardLine(ncSource, ncLine);
                                ncLine++;
                            }
                        } else {
                            llMessageLinked(LINK_THIS, LM_SP_INPUT, s, whoDat);
                        }
                    } else {
                        /*  The process of aborting a script due to an error
                            in the script or other exogenous event is asynchronous
                            to the completion of a pending llGetNotecardLine()
                            request.  That means that it's possible we may get
                            here, receiving data for a script which has been
                            terminated while the request was pending.  If that's
                            the case ncBusy will be FALSE and we don't want to
                            request the next line, which will fail because
                            ncSource will have been cleared.  */
                        if (ncBusy) {
                            //  It was a comment or blank line; fetch the next
                            ncQuery = llGetNotecardLine(ncSource, ncLine);
                            ncLine++;
                        }
                    }
                }
            }
        }

        /*  The timer is used to resume processing of a script
            once the interval specified by a Script pause command
            has expired.  By its nature, only one pause can be in
            effect at a time, so we don't need any tangled logic
            here.  */

        timer() {
            pauseExpiry = -1;               // No pause in effect
            llSetTimerEvent(0);             // Cancel event timer
            ncQuery = llGetNotecardLine(ncSource, ncLine);
            ncLine++;
        }

        //  If we're in a manual pause, resume upon touch

        touch_start(integer n) {
            if (pauseManual) {
                pauseManual = FALSE;
                ncQuery = llGetNotecardLine(ncSource, ncLine);
                ncLine++;
            }
        }

        //  If we're in a region pause, resume when region changes

        changed(integer what) {
            if (what & CHANGED_REGION) {
                if (pauseRegion) {
                    pauseRegion = FALSE;
                    ncQuery = llGetNotecardLine(ncSource, ncLine);
                    ncLine++;
                    regionChanged = 0;
                } else {
                    /*  If we change regions while a script is running,
                        set regionChanged so the next Pause region does
                        not wait.  */
                    if (ncBusy) {
                        regionChanged++;
                    }
                }
            }
        }
    }
