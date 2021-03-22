\documentclass{report}

%    ****** TURN OFF HARDWARE TABS BEFORE EDITING THIS DOCUMENT ******
%
%   Should you ignore this admonition, tabs in the program code will
%   not be respected in the LaTeX-generated program document.
%   If that should occur, simply pass this file through
%   expand to replace the tabs with sequences of spaces.

%   This program is written using the Nuweb Literate Programming
%   tool:
%
%           http://sourceforge.net/projects/nuweb/
%
%   For information about Literate Programming, please visit the
%   site:   http://www.literateprogramming.com/

\setlength{\oddsidemargin}{0cm}
\setlength{\evensidemargin}{0cm}
\setlength{\topmargin}{0cm}
\addtolength{\topmargin}{-\headheight}
\addtolength{\topmargin}{-\headsep}
\setlength{\textheight}{22.5cm}
\setlength{\textwidth}{16.5cm}
\setlength{\marginparwidth}{1.25cm}
\setcounter{tocdepth}{6}
\setcounter{secnumdepth}{6}
\newcommand{\dense}{\setlength{\itemsep}{-1ex}}

%   Keep section numbers from colliding with title in TOC
\usepackage{tocloft}
\cftsetindents{subsection}{4em}{4em}
\cftsetindents{subsubsection}{6em}{5em}

%   Enable PDF output and hyperlinks within PDF files
\usepackage[unicode=true,pdftitle={Fourmilab Orbits},pdfauthor={John Walker},colorlinks=true,linkcolor=blue,urlcolor=blue]{hyperref}

%   Enable inclusion of graphics files
\usepackage{graphicx}

%   Enable proper support for appendices
\usepackage[toc,titletoc,title]{appendix}

%   Support text wrapping around figures
\usepackage{wrapfig}

\title{\bf Fourmilab Orbits \\
{\rm for Second Life}
}
\author{
    by \href{http://www.fourmilab.ch/}{John Walker}
}
\date{
    March 2021 \\
    \vspace{12ex}
    \includegraphics[width=3cm]{figures/fourlogo_640.png}
}

\begin{document}

\pagenumbering{roman}
\maketitle
\tableofcontents

\chapter{Introduction}
\pagenumbering{arabic}

%   The following allows disabling the build number and date and
%   time inclusion in programs during periods of active development.
%   The build number continues to be incremented as a record, but
%   we embed zero values here to avoid having files which are not
%   otherwise changed be updated by Nuweb.  Such unnecessary updates
%   would generate a large number of meangless Git transactions which
%   would only confuse the record of genuine changes to the code.
%
%   When it's time to go into production, re-enable the include of
%   build.w to restore the build number configuration control
%   facility.
%
%i build.w
@d Build number @{0@}
@d Build date and time @{1900-01-01 00:00@}

\subsection{Build number consistency checking}

The following code is used to check that subsidiary scripts and
the scripts within objects we create are from the same build number
as the Deployer.  This check is only made when explicitly requested
via the ``Test version'' command: since during development it will
almost always be the case that the latest scripts have not yet been
installed in objects we aren't actively testing.  We use
{\tt llOwnerSay()} instead of {\tt tawk()} to report discrepancies,
allowing this code to be used in simple scripts which don't have
that function.

\subsection{Check build number in Deployer scripts}

The {\tt LM\_AS\_VERSION} message requests a Deployer script to check
its build number against that of the Deployer and report any
discrepancy.

@d Check build number in Deployer scripts
@{
    //  LM_AS_VERSION (543): Check version consistency
    } else if (num == LM_AS_VERSION) {
        if ("@<Build number@>" != str) {
            llOwnerSay(llGetScriptName() +
                       " build mismatch: Deployer " + str +
                       " Local @<Build number@>");
        }
@}

\subsubsection{Check build number in created objects}

This code, inserted in the {\tt massChannel} message processor in
objects (for example, planets and numerical integration masses) we
create, checks build number and reports discrepancies.

@d Check build number in created objects
@{
    } else if (ccmd == "VERSION") {
        if ("@<Build number@>" != llList2String(msg, 1)) {
            llOwnerSay(llGetScriptName() +
                       " build mismatch: Deployer " + llList2String(msg, 1) +
                       " Local @<Build number@>");
        }
@}

\subsubsection{Forward build number check to objects we've created}

Objects created by the Deployer, for example Solar System planets and
Numerical Integration masses, may, in turn, create their own objects
such as {\tt flPlotLine} cylinders to trace orbital paths. Since these
objects listen only to messages from their creator, which is not the
Deployer, objects which create other objects must forward the {\tt
VERSION} message from the Deployer to them so that they may check their
own build number.  Note that we forward the build number we received
from the Deployer, not the object's own, which might not be the same.

@d Forward build number check to objects we've created
@{
    llRegionSay(@<massChannel@>,
        llList2Json(JSON_ARRAY, [ "VERSION", llList2String(msg, 1) ]));
@}

\chapter{Utility Functions}

This and the following chapter define a variety of functions which
are used in various places throughout the scripts in the product.
Because LSL does not have either source-level includes or separate
compilation, each script is entirely self-contained and must define
all of the functions is uses.  Consequently, we use the Literate
Programming macro facility much like the ``program library'' of a
computer in the 1950s, providing a collection of functions whose
source code may be included in scripts which require them simply by
citing their scrap names in their headers.

\section{Constants and Settings}

The following definitions are constants used widely within the
program and global settings.  They are incorporated directly within
the scripts by macro expansion, avoiding script storage.

\subsection{Communication channel}

This is the channel used by objects to communicate with one another.
Objects created by a deployer only respond to messages sent by that
deployer, avoiding interference even if multiple deployers and models
are running in the same region and using the same channel.

@d massChannel @( -982449822 @)

\subsection{Standard colours}

We use the following colour code, derived from the
\href{https://en.wikipedia.org/wiki/Electronic_color_code#Resistor_code}{resistor
colour code}, for a variety of purposes: choosing colours for bodies in
galactic centre simulations, identifying orbit trails, etc.

@d Colour:0:black @{ <0, 0, 0> @}
@d Colour:1:brown @{ <0.3176, 0.149, 0.1529> @}
@d Colour:2:red @{ <0.8, 0, 0> @}
@d Colour:3:orange @{ <0.847, 0.451, 0.2784> @}
@d Colour:4:yellow @{ <0.902, 0.788, 0.3176> @}
@d Colour:5:green @{ <0.3216, 0.5608, 0.3961> @}
@d Colour:6:blue @{ <0.00588, 0.3176, 0.5647> @}
@d Colour:7:violet @{ <0.4118, 0.4039, 0.8078> @}
@d Colour:8:grey @{ <0.4902, 0.4902, 0.4902> @}
@d Colour:9:white @{ <1, 1, 1> @}
@d Colour:10:silver @{ <0.749, 0.745, 0.749> @}
@d Colour:11:gold @{ <0.7529, 0.5137, 0.1529> @}

\section{Floating point hexadecimal encoding and decoding}

The {\tt fuis} and {\tt suif} functions encode and decode {\tt float}
values as Base64 encoded six character strings.  This is a fast
and compact encoding which preserves all of the (sorely limited)
precision of a these numbers.  These functions are based upon
code developed by Strife Onizuka and contributed to the LSL
Library.

\subsection{Encode floating point number as base64 string}
\label{fuis}

The {\tt fuis} function encodes its floating point argument as a six
character string encoded as base64.  This version is modified from the
original in the LSL Library.  By ignoring the distinction between $+0$
and $-0$, this version runs almost three times faster than the
original.  While this does not preserve floating point numbers
bit-for-bit, it doesn't make any difference in our calculations.

@d fuis: Encode floating point number as base64 string
@{
    string fuis(float a) {
        //  Detect the sign on zero.  It's ugly, but it gets you there
        //  integer b = 0x80000000 & ~llSubStringIndex(llList2CSV([a]), "-");   // Sign
        /*  Test for negative number, ignoring the difference between
            +0 and -0.  While this does not preserve floating point
            numbers bit-for-bit, it doesn't make any difference in
            our calculations and is almost three times faster than
            the original code above.  */
        integer b = 0;
        if (a < 0) {
            b = 0x80000000;
        }

        if (a) {        // Is it greater than or less than zero ?
            //  Denormalized range check and last stride of normalized range
            if ((a = llFabs(a)) < 2.3509887016445750159374730744445e-38) {
                b = b | (integer) (a / 1.4012984643248170709237295832899e-45);   // Math overlaps; saves CPU time
            //  We never need to transmit infinity, so save the time testing for it.
            // } else if (a > 3.4028234663852885981170418348452e+38) { // Round up to infinity
            //     b = b | 0x7F800000;                                 // Positive or negative infinity
            } else if (a > 1.4012984643248170709237295832899e-45) { // It should at this point, except if it's NaN
                integer c = ~-llFloor(llLog(a) * 1.4426950408889634073599246810019);
                //  Extremes will error towards extremes. The following corrects it
                b = b | (0x7FFFFF & (integer) (a * (0x1000000 >> c))) |
                        ((126 + (c = ((integer) a - (3 <= (a *= llPow(2, -c))))) + c) * 0x800000);
                //  The previous requires a lot of unwinding to understand
            } else {
                //  NaN time!  We have no way to tell NaNs apart so pick one arbitrarily
                b = b | 0x7FC00000;
            }
        }

        return llGetSubString(llIntegerToBase64(b), 0, 5);
    }
@| fuis @}

\subsubsection{Encode vector as base64 string}

The {\tt fv} function encodes the three components of a vector as
consecutive {\tt fuis} base64 strings.

@d fv: Encode vector as base64 string
@{
    string fv(vector v) {
        return fuis(v.x) + fuis(v.y) + fuis(v.z);
    }
@| fv @}

\subsection{Decode base64-encoded floating point number}

The {\tt siuf} function decodes a floating point number encoded with
{\tt fuis}.

@d siuf: Decode base64-encoded floating point number
@{
    float siuf(string b) {
        integer a = llBase64ToInteger(b);
        if (0x7F800000 & ~a) {
            return llPow(2, (a | !a) + 0xffffff6a) *
                      (((!!(a = (0xff & (a >> 23)))) * 0x800000) |
                       (a & 0x7fffff)) * (1 | (a >> 31));
        }
        return (!(a & 0x7FFFFF)) * (float) "inf" * ((a >> 31) | 1);
    }
@| siuf @}

\subsubsection{Decode base64-encoded vector}

This is a helper function to decode a vector packed as three
consecutive {\tt siuf}-encoded floats.

@d sv: Decode base64-encoded vector
@{
    vector sv(string b) {
        return(< siuf(llGetSubString(b, 0, 5)),
                 siuf(llGetSubString(b, 6, 11)),
                 siuf(llGetSubString(b, 12, -1)) >);
    }
@| sv @}

\section{Edit floating point numbers in parsimonious representation}

LSL's conversion of floating point numbers to decimal strings leaves
much to be desired when the goal is displaying values to a user
as opposed to diagnostic output for developers.  While there are
flexible editing routines for both decimal and scientific notation
in the LSL Library, they are very slow and consume a large amount
of scarce script memory.  Our {\tt ef} function takes the string
produced by casting a floating point number to a string and makes
it more primate-friendly by eliding trailing zeroes and deleting
the decimal point if the number is integral.  The function may be
called on a string containing one or more numbers; the numbers are
re-formatted without modifying the surrounding text.

\subsection{Edit floating point number to readable representation}

Note that this function takes a string as an argument.  If you're
passing a number, you must cast it to a string or else use the
{\tt efr} helper function below.

@d ef: Edit floating point number to readable representation
@{
    string ef(string s) {
        integer p = llStringLength(s) - 1;

        while (p >= 0) {
            //  Ignore non-digits after numbers
            while ((p >= 0) &&
                   (llSubStringIndex("0123456789", llGetSubString(s, p, p)) < 0)) {
                p--;
            }
            //  Verify we have a sequence of digits and one decimal point
            integer o = p - 1;
            integer digits = 1;
            integer decimals = 0;
            while ((o >= 0) &&
                   (llSubStringIndex("0123456789.", llGetSubString(s, o, o)) >= 0)) {
                o--;
                if (llGetSubString(s, o, o) == ".") {
                    decimals++;
                } else {
                    digits++;
                }
            }
            if ((digits > 1) && (decimals == 1)) {
                //  Elide trailing zeroes
                while ((p >= 0) && (llGetSubString(s, p, p) == "0")) {
                    s = llDeleteSubString(s, p, p);
                    p--;
                }
                //  If we've deleted all the way to the decimal point, remove it
                if ((p >= 0) && (llGetSubString(s, p, p) == ".")) {
                    s = llDeleteSubString(s, p, p);
                    p--;
                }
                //  Done with this number.  Skip to next non digit or decimal
                while ((p >= 0) &&
                       (llSubStringIndex("0123456789.", llGetSubString(s, p, p)) >= 0)) {
                    p--;
                }
            } else {
                //  This is not a floating point number
                p = o;
            }
        }
        return s;
    }
@| ef @}

\subsubsection{Edit float to readable representation}

This helper function casts its float argument to a string and calls
{\tt ef} to edit it to a readable string.

@d eff: Edit float to readable representation
@{
    string eff(float f) {
        return ef((string) f);
    }
@| eff @}

\subsubsection{Edit vector to readable representation}

This helper function casts its vector argument to a string and calls
{\tt ef} to edit it to a readable string.  It takes advantage of
the ability of {\tt ef} to process multiple numbers in its input
string.

@d efv: Edit vector to readable representation
@{
    string efv(vector v) {
        return ef((string) v);
    }
@| efv @}

\section{Transform local to region co-ordinates}

@d l2r: Transform local to region co-ordinates
@{
    vector l2r(vector loc) {
        return (loc * llGetRootRotation()) + llGetRootPosition();
    }
@| l2r @}

\section{Find a linked prim by name}

Find a linked prim by name avoids having to slavishly link prims in
order in complex builds to reference them later by link number.  You
should only call this once, in {\tt state\_entry()}, and then save the
link numbers in global variables.  Returns the prim number or $-1$ if
no such prim was found.  Caution: if there are more than one prim with
the given name, the first will be returned without warning of the
duplication.

@d findLinkNumber: Find a linked prim by name
@{
    integer findLinkNumber(string pname) {
        integer i = llGetLinkNumber() != 0;
        integer n = llGetNumberOfPrims() + i;

        for (; i < n; i++) {
            if (llGetLinkName(i) == pname) {
                return i;
            }
        }
        return -1;
    }
@| findLinkNumber @}

\section{Send a message to the interacting user in chat}

The {\tt tawk} function communicates with a user with whom
we're interacting in a variety of ways.  If the user has
sent us a command, their key will have been stored in the
global {\tt whoDat} and we direct the message to them.
If that user is our owner, we use {\tt llOwnerSay}, which
avoids the dreaded risk of being blocked due to a message
flood, which can only be lifted by restarting the region.
Otherwise, we use {\tt llRegionSayTo}, running the risk in
the interest of communication.  If we aren't in communication
with a user, we send the message to local chat on the public
channel.

@d tawk: Send a message to the interacting user in chat
@{
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
@| tawk @}

\section{Argument parsing}

These functions assist in parsing of arguments in commands entered
by the user in chat, submitted by scripts, or read from notecards
for various purposes.

\subsection{Transform vector and rotation arguments to canonical form}

The simple-minded parsing performed by {\tt llParseString2List()}
does not understand vector and rotation arguments, which are
delimited by angle brackets and may contain spaces between the
brackets which are ignored.  These embedded spaces will, however,
cause the argument to be broken into pieces and mis-interpreted
if left in place.  The {\tt fixArgs()} function takes a command
line and deletes all embedded spaces between brackets, guaranteeing
that they are parsed as a single argument.

@d fixArgs: Transform vector and rotation arguments to canonical form
@{
    string fixArgs(string cmd) {
        cmd = llStringTrim(cmd, STRING_TRIM);
        integer l = llStringLength(cmd);
        integer inbrack = FALSE;
        integer i;
        string fcmd = "";

        for (i = 0; i < l; i++) {
            string c = llGetSubString(cmd, i, i);
            if (inbrack && (c == ">")) {
                inbrack = FALSE;
            }
            if (c == "<") {
                inbrack = TRUE;
            }
            if (!((c == " ") && inbrack)) {
                fcmd += c;
            }
        }
        return fcmd;
    }
@| fixArgs @}

\subsection{Consolidate quoted arguments}

In some commands we wish to allow quoted arguments which may contain
spaces.  Since {\tt llParseString2List()} does not understand this
syntax and breaks arguments unconditionally at spaces, this function
post-processes an argument list and consolidates arguments from one
which starts with a quote to one which ends with a quote into a single
argument list item.  For consistency, a single argument which starts
and ends with a quote has the quotes removed.  Note that multiple
spaces within quoted arguments are compressed to a single space. You
can, if you wish, first process an argument list with {\tt fixArgs} to
canonicalise vectors and rotations, then post-process the list parsed
from its result with {\tt fixQuotes} to handle quoted arguments.

@d fixQuotes: Consolidate quoted arguments
@{
    list fixQuotes(list args) {
        integer i;
        integer n = llGetListLength(args);

        for (i = 0; i < n; i++) {
            string arg = llList2String(args, i);
            if (llGetSubString(arg, 0, 0) == "\"") {
                /*  Argument begins with a quote.  If it ends with one,
                    strip them and we're done.  */
                if (llGetSubString(arg, -1, -1) == "\"") {
                    args = llListReplaceList(args,
                        [ llGetSubString(arg, 1, -2) ], i, i);
                } else {
                    /*  Concatenate arguments until we find one that ends
                        with a quote, then replace the multiple arguments
                        with the concatenation.  */
                    string rarg = llGetSubString(arg, 1, -1);
                    integer looking = TRUE;
                    integer j;

                    for (j = i + 1; looking && (j < n); j++) {
                        string narg = llList2String(args, j);
                        if (llGetSubString(narg, -1, -1) == "\"") {
                            rarg += " " + llGetSubString(narg, 0, -2);
                            looking = FALSE;
                        } else {
                            rarg += " " + narg;
                        }
                    }
                    if (!looking) {
                        args = llListReplaceList(args, [ rarg ], i, j - 1);
                    }
                }
            }
        }
        return args;
    }
@| fixQuotes @}

\subsection{Test argument, allowing abbreviation}

Tests the first characters of {\tt str} against the abbreviation
{\tt abbr}.  This is a case-sensitive test: if you wish it to be
case-insensitive, convert the string to the same case as the
abbreviation before calling.

@d abbrP: Test argument, allowing abbreviation
@{
    integer abbrP(string str, string abbr) {
        return abbr == llGetSubString(str, 0, llStringLength(abbr) - 1);
    }
@| abbrP @}

\subsection{Parse an on/off parameter}

Parse a parameter which is ``on'' or ``off'', returning 1 or 0
respectively.  If the parameter is neither, display an error and return
$-1$.  In a number of places we allow parameters which can be ``on'',
``off'', or something else: this is accomplished simply by testing for
the other cases with {\tt abbrP()} or another comparison before calling
{\tt onOff()}.

@d onOff: Parse an on/off parameter
@{
    integer onOff(string param) {
        if (abbrP(param, "on")) {
            return TRUE;
        } else if (abbrP(param, "of")) {
            return FALSE;
        } else {
            tawk("Error: please specify on or off.");
            return -1;
        }
    }
@| onOff @}

\subsection{Edit an on/off parameter}

Return a string indicating whether the Boolean state is on or off.

@d eOnOff: Edit an on/off parameter
@{
    string eOnOff(integer p) {
        if (p) {
            return "on";
        }
        return "off";
    }
@| eOnOff @}

\subsection{Parse extended colour specification}
\label{exColour}

Colours for source objects are specified using an extended
notation which allows specification of transparency and glow
in addition to colour components:

\begin{verse}
    {\tt <} {\em red}{\tt ,} {\em green}{\tt ,} {\em blue}{\tt ,}
    {\em alpha}{\tt ,} {\em glow} {\tt >}
\end{verse}

\noindent
where all components are in the range $[0,1)]$.  For colour channels,
the value gives the intensity of that component.  For {\tt alpha}, 0
denotes transparent and 1 opaque, and {\tt glow} is the intensity of
glow with 0 no glow and 1 maximum intensity.

@d exColour: Parse extended colour specification
@{
    list exColour(string s) {
        if ((llGetSubString(s, 0, 0) == "<") &&
            (llGetSubString(s, -1, -1) == ">")) {
            list l = llParseStringKeepNulls(llGetSubString(s, 1, -2), [ "," ], [ ]);
            integer n = llGetListLength(l);
            if (n >= 3) {
                vector colour = < llList2Float(l, 0),
                                  llList2Float(l, 1),
                                  llList2Float(l, 2) >;
                float alpha = 1;
                float glow = 0;
                if (n >= 4) {
                    alpha = llList2Float(l, 3);
                    if (n >= 5) {
                        glow = llList2Float(l, 4);
                    }
                }
                return [ colour, alpha, glow ];
            }
        }
        return [ <1, 1, 1>, 1, 0 ];     // Default: solid white, no glow
    }
@| exColour @}

\section{Trace path with particle system}

If {\tt paths} is set, trace the path of a body as it moves by
depositing ribbon particles behind it.  This is a cheap way to show
trajectories, but has the limitations of all particle systems.  It
works very poorly for rotating bodies, as the direction of particle
emission changes with the orientation of the object to which it is
attached.

@d Trace path with particle system @'@'
@{
    if (paths) {
        llParticleSystem(
            [ PSYS_PART_FLAGS, PSYS_PART_EMISSIVE_MASK |
              PSYS_PART_INTERP_COLOR_MASK |
              PSYS_PART_RIBBON_MASK,
              PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_DROP,
              PSYS_PART_START_COLOR, @1,
              PSYS_PART_END_COLOR, @1,
              PSYS_PART_START_SCALE, <0.75, 0.75, 1>,
              PSYS_PART_END_SCALE, <0.75, 0.75, 1>,
              PSYS_SRC_MAX_AGE, 0,
              PSYS_PART_MAX_AGE, 8.0,
              PSYS_SRC_BURST_RATE, 0.0,
              PSYS_SRC_BURST_PART_COUNT, 60
            ]);
    } else {
        llParticleSystem([ ]);
    }
@}

\section{Kaboom: Destroy object}

When we want to emphatically get rid of an object, for example when
a body wanders beyond the range we wish to display or two masses in
a numerical integration simulation collide, {\tt kaboom()} generates
an explosion particle effect, plays a detonation sound, and commands
the object to self-destruct.

@d kaboom: Destroy object
@{
    kaboom(vector colour) {
        llPlaySound(Collision, 1);

        llParticleSystem([
            PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,

            PSYS_SRC_BURST_RADIUS, 0.05,

            PSYS_PART_START_COLOR, colour,
            PSYS_PART_END_COLOR, colour,

            PSYS_PART_START_ALPHA, 0.9,
            PSYS_PART_END_ALPHA, 0.0,

            PSYS_PART_START_SCALE, <0.3, 0.3, 0>,
            PSYS_PART_END_SCALE, <0.1, 0.1, 0>,

            PSYS_PART_START_GLOW, 1,
            PSYS_PART_END_GLOW, 0,

            PSYS_SRC_MAX_AGE, 0.1,
            PSYS_PART_MAX_AGE, 0.5,

            PSYS_SRC_BURST_RATE, 20,
            PSYS_SRC_BURST_PART_COUNT, 1000,

            PSYS_SRC_ACCEL, <0, 0, 0>,

            PSYS_SRC_BURST_SPEED_MIN, 2,
            PSYS_SRC_BURST_SPEED_MAX, 2,

            PSYS_PART_FLAGS, 0
                | PSYS_PART_EMISSIVE_MASK
                | PSYS_PART_INTERP_COLOR_MASK
                | PSYS_PART_INTERP_SCALE_MASK
                | PSYS_PART_FOLLOW_VELOCITY_MASK
        ]);

        llSleep(1);         // Need to wait to allow particles and sound to play
        llDie();
    }
@| kaboom @}

\chapter{Mathematical and Geometric Functions}

This is a collection of commonly-used functions which are not provided
by LSL.  They are used frequently in positional astronomy and
geometric modelling.

\section{Constants}

The following mathematical and astronomical constants are declared
here as macros, which allows them to be substituted in code without
occupying separate storage as global variables.

Base of the natural logarithms, $e$.
@d Ke @( 2.718281828459045 @)

Epoch J2000: we write this as an integer so that it may be used as
such or cast to a float as desired.
@d J2000 @( 2451545 @)

Days in a Julian century.
@d JulianCentury @( 36525.0 @)

Semi-major axis of Moon's orbit
@d MoonSemiMaj @( 384401 @)

\subsection{Gravitational constant}

We define the gravitational constant in a system of units where
length is measured in astronomical units, mass in solar masses, and
time in years.

@d Gravitational constant in astronomical units
@{
    float G_SI = 6.6732e-11;            // (Newton Metre^2) / Kilogram^2
    float AU = 149504094917.0;          // Metres / Astronomical unit
    float M_SUN = 1.989e30;             // Kilograms / Mass of Sun
    float YEAR = 31536000;              // Seconds / Year (365.0 * 24 * 60 * 60)
@}

From Newton's second law:
\[
F = m a
\]
with units
\[
    {\rm Newton} = \frac{\rm kg}{{\rm sec}^2}
\]
the fundamental units of the gravitational constant are:
\begin{eqnarray*}
       G & = & {\rm N}\ {\rm m}^2 / {\rm kg}^2 \\
         & = & ({\rm kg}\ {\rm m} / {\rm sec}^2)\ {\rm m}^2 / {\rm kg}^2 \\
         & = & {\rm kg}\ {\rm m}^3 / {\rm sec}^2\ {\rm kg}^2 \\
         & = & {\rm m}^3 / {\rm sec}^2\ {\rm kg}
\end{eqnarray*}
The conversion factor, therefore, between the SI gravitational
constant and its equivalent in our units is:
\[
    {\tt GRAV\_CONV} = {\tt AU}^3 / {\tt YEAR}^2\ {\tt M\_SUN}
\]
and the gravitational constant itself is obtained by dividing the
SI definition by this conversion factor.
\[
    {\tt GRAVCON} = {\tt G\_SI} / {\tt GRAV\_CONV}
\]

Now define our gravitational units.  Because LSL does not support
compile-time arithmetic, we'll have to initialise them when the
script starts running.

@d Gravitational constant in astronomical units
@{
    float GRAV_CONV;        // ((AU * AU * AU) / ((YEAR * YEAR) * M_SUN))
    float GRAVCON;          // (G_SI / GRAV_CONV)
@}

This is the code to initialise these constants.

@d Initialise gravitational constant in astronomical units
@{
    GRAV_CONV = ((AU * AU * AU) / ((YEAR * YEAR) * M_SUN));
    GRAVCON = G_SI / GRAV_CONV;
@}

\subsection{Standard gravitational parameters}

In a two body gravitational system, the standard gravitational
parameter:
\[
    \mu = G M
\]
of the central mass determines the trajectories of much smaller
masses under its gravitational influence: for objects in elliptical
orbits, their orbital periods.  $G$ is the Newtonian gravitational
constant and $M$ is the mass of the central body.  Here we define
$\mu$ for bodies in the solar system.  These values use a length
unit of metres and a time unit of seconds, with $\mu$ having
dimensions of ${\rm m}^3\,{\rm s}^{-2}$.

@d GM:Sun @{ 1.32712440018e20 @}
%d GM:Mercury @{ 2.2032e13 @}
%d GM:Venus @{ 3.24859e14 @}
@d GM:Earth @{ 3.986004418e14 @}
%d GM:Mars @{ 4.282837e13 @}
@d GM:Jupiter @{ 1.26686534e17 @}
@d GM:Saturn @{ 3.7931187e16 @}
@d GM:Uranus @{ 5.793939e15 @}
@d GM:Neptune @{ 6.836529e15 @}
@d GM:Pluto @{ 8.71e11 @}

\section{Range reduction of angles}

Computations such as evaluation of periodic terms in planetary
theories and mean motion since an epoch often result in angles
which are larger than a full circle.  Using such angles may
result in loss of precision, particularly in single precision
arithmetic.  These functions take an angle of arbitrary magnitude
and reduce it to the range of a full circle.

\subsection{Range reduce an angle in radians}

The argument, an angle in radians, is reduced to an angle in the
interval $[0,2\pi)$.

@d fixangr: Range reduce an angle in radians
@{
    float fixangr(float a) {
        return a - (TWO_PI * (llFloor(a / TWO_PI)));
    }
@| fixangr @}

\subsection{Range reduce an angle in degrees}

The argument, an angle in radians, is reduced to an angle in the
interval $[0,360)$.

@d fixangle: Range reduce an angle in degrees
@{
    float fixangle(float a) {
        return a - (360.0 * llFloor(a / 360.0));
    }
@| fixangle @}

\section{Spherical and rectangular co-ordinates}

These functions convert between spherical (often characterised as
longitude, latitude, and radius) and rectangular (Cartesian)
co-ordinates.

\subsection{Spherical to rectangular co-ordinate conversion}

Convert spherical co-ordinates (often referred to as $(L, B, R)$ or
$(\lambda, \beta, r)$ to rectangular $(X,Y,Z)$.  The scale factor is
not specified, and the units of the rectangular co-ordinates will be
the same as those of the radius in the spherical.

@d sphRect: Spherical to rectangular co-ordinate conversion
@{
    vector sphRect(float l, float b, float r) {
        return < r * llCos(b) * llCos(l),
                 r * llCos(b) * llSin(l),
                 r * llSin(b) >;
    }
@| sphRect @}

\subsection{Rectangular to spherical co-ordinate conversion}

Convert rectangular $(X,Y,Z)$ co-ordinates to spherical co-ordinates
(often referred to as $(L, B, R)$ or $(\lambda, \beta, r)$.  The scale
factor is not specified, and the units of the rectangular co-ordinates
will be the same as those of the radius in the spherical.

@d rectSph: Rectangular to spherical co-ordinate conversion
@{
    vector rectSph(vector rc) {
        float r = llVecMag(rc);
        return < llAtan2(rc.y, rc.x), llAsin(rc.z / r), r >;
    }
@| rectSph @}

\section{Signs and Magnitudes}

Functions for manipulating floating point and integer values.

\subsection{Sign of argument}

Returns $-1$ if the argument is negative, $1$ if positive, and $0$ if
it is zero.  (Yes, this is like the BASIC function---so mock me.)

@d sgn: Sign of argument
@{
    integer sgn(float v) {
        if (v == 0) {
            return 0;
        } else if (v > 0) {
            return 1;
        }
        return -1;
    }
@| sgn @}

\subsection{Test if value is NaN}

When parsing orbital elements, we initialise unspecified arguments to
IEEE 754 not-a-number (NaN) to distinguish from, say, zero, which is a
valid specification for many elements.  This function tests its
argument and returns {\tt TRUE} if it is NaN\@@.  This may be used
anywhere else you wish to make this test.

@d spec: Test if value is NaN
@{
    integer spec(float e) {
        return ((string) e) != "NaN";
    }
@| spec @}

\section{Hyperbolic Trigonometric Functions}

When computing hyperbolic trajectories, we require hyperbolic
trigonometric functions.  Here we define them in terms of functions
which are implemented in LSL.

\begin{eqnarray*}
    \sinh x & = & \frac{e^x - e^{-x}}{2} \\
    \cosh x & = & \frac{e^x + e^{-x}}{2} \\
    \tanh x & = & \frac{\sinh x}{\cosh x}
\end{eqnarray*}

@d Hyperbolic trigonometric functions
@{
    float flSinh(float x) {
        return (llPow(@<Ke@>, x) - llPow(@<Ke@>, -x)) / 2;
    }

    float flCosh(float x) {
        return (llPow(@<Ke@>, x) + llPow(@<Ke@>, -x)) / 2;
    }

    float flTanh(float x) {
        return flSinh(x) / flCosh(x);
    }
@| flSinh flCosh flTanh @}

\section{Random Unit Vector Generation}

Generate a unit vector in a direction which is uniformly distributed on
the unit sphere.  Getting this right is more subtle than you might
think. We use Marsaglia's method, as described in Marsaglia, G.
``Choosing a Point from the Surface of a Sphere.'' {\em Ann\@@.
Math\@@. Stat\@@.} {\bf 43}, 645--646, 1972.

@d randVec: Random Unit Vector Generation
@{
    vector randVec() {
        integer outside = TRUE;

        while (outside) {
            float x1 = 1 - llFrand(2);
            float x2 = 1 - llFrand(2);
            if (((x1 * x1) + (x2 * x2)) < 1) {
                outside = FALSE;
                float x = 2 * x1 * llSqrt(1 - (x1 * x1) - (x2 * x2));
                float y = 2 * x2 * llSqrt(1 - (x1 * x1) - (x2 * x2));
                float z = 1 - 2 * ((x1 * x1) + (x2 * x2));
                return < x, y, z >;
            }
        }
        return ZERO_VECTOR;         // Can't happen, but idiot compiler errors otherwise
    }
@| randVec @}

\chapter{Date and Time}

These functions provide various conversions and manipulations of
quantities representing date and time.  Our native representation
is Julian day and fraction which, because of the limited precision
of LSL single precision floats, we store as a list whose first
element is an integer day number and second is a float day fraction,
normalised to the range $[0,1)$.

\section{UTC to Julian day and fraction}

Convert a date and time in Coordinated Universal Time (UTC) to a Julian
Day and fraction, returned as a list of the whole day number and
fraction as a float.

@d jdate: UTC to Julian day and fraction
@{
    list jdate(integer year, integer mon, integer mday,
                integer hour, integer min, integer sec) {

        /*  Algorithm as given in Meeus, Astronomical Algorithms 2nd ed.,
            Chapter 7, page 61, with serious hackery to cope with the
            limits of single precision floats.  */

        integer a;
        integer b;

        integer m = mon + 1;
        integer y = year;

        if (m <= 2) {
            y--;
            m += 12;
        }

        /* Determine whether date is in Julian or Gregorian calendar based on
           canonical date of calendar reform. */

        if ((year < 1582) || ((year == 1582) && ((mon < 9) ||
            ((mon == 9) && (mday < 5))))) {
            b = 0;
        } else {
            a = y / 100;
            b = 2 - a + (a / 4);
        }

        integer dwhole = llFloor(365.25 * (y + 4716)) + llFloor(30.6001 * (m + 1)) +
            mday + b - 1524;
        float dfrac = ((sec + 60 * (min + (60 * hour))) / 86400.0) - 0.5;
        if (dfrac < 0) {
            dwhole--;
            dfrac += 1;
        }

        return [ dwhole, dfrac ];
    }
@| jdate @}

\subsection{Parse decimal Julian date and fraction}

Parse a string containing a Julian day and fraction specification
(for example, ``{\tt 2459273.5}'') into a list containing the
integral and fractional parts of the Julian day.

@d parseJD: Parse decimal Julian date and fraction
@{
    list parseJD(string td) {
        list jf = llParseString2List(td, ["."], []);
        return [ (integer) llList2String(jf, 0),
                 (float) ("0." + llList2String(jf, 1)) ];
    }
@| parseJD @}

\subsection{LSL timestamp to Julian day and fraction}

Obtain the current UTC date and time and return the Julian day and
fraction corresponding to it.

@d jdstamp: LSL timestamp to Julian day and fraction
@{
    list jdstamp(string s) {
        list t = llParseString2List(s, ["-", "T", ":", "."], []);

        return jdate(llList2Integer(t, 0), llList2Integer(t, 1) - 1, llList2Integer(t, 2),
                     llList2Integer(t, 3), llList2Integer(t, 4), llList2Integer(t, 5));
    }
@| jdstamp @}

\section{Julian day to UTC date and time}

These functions convert Julian day and fractions into Gregorian
dates and UTC times.

\section{Julian day to Greenwich Mean Sidereal Time}

Greenwich Mean Sidereal Time for a given instant expressed as a Julian
date and fraction.  We use a less general expression than in C language
{\em Earth and Moon Viewer} because it yields more accurate results
when computed in the single-precision floating point of LSL.

@d gmstx: Julian day to Greenwich Mean Sidereal Time
@{
    float gmstx(integer jd, float jdf) {
        /*  See simplified formula in:
                https://aa.usno.navy.mil/faq/docs/GAST.php  */
        float D = (jd - 2451545) + jdf;
        float GMST = 18.697374558 + 24.06570982441908 * D;
        GMST -= 24.0 * (llFloor(GMST / 24.0));
        return GMST;
    }
@| gmstx @}

\subsection{Julian day and fraction to Gregorian date}

Convert a Julian day and fraction stored in a list into a list
representing the Gregorian year, month, and day numbers without
any Unix-style jiggery-pokery about indices: month and day both
start at 1.

@d jyearl: Julian day and fraction to Gregorian date
@{
    list jyearl(list tdl) {
        float a;
        float alpha;
        integer yy;
        integer mm;

        float td = llList2Float(tdl, 0);
        float tdf = llList2Float(tdl, 1);

        tdf += 0.5;                     // Adjust for Julian date changes at noon
        if (tdf > 1.0) {                // If this advanced day
            td++;                       //    then bump the integral day
            tdf -= 1;                   //    and decrement fractional day
        }

        float z = td;
        float f = tdf;

        if (z < 2299161.0) {
            a = z;
        } else {
            alpha = llFloor((z - 1867216.25) / 36524.25);
            a = z + 1 + alpha - llFloor(alpha / 4);
        }

        float b = a + 1524;
        float c = llFloor((b - 122.1) / 365.25);
        float d = llFloor(365.25 * c);
        float e = llFloor((b - d) / 30.6001);

        if (e < 14) {
            mm = (integer) (e - 1);
        } else {
            mm = (integer) (e - 13);
        }

        if (mm > 2) {
            yy = (integer) (c - 4716);
        } else {
            yy = (integer) (c - 4715);
        }

        return [
                 yy,                                            // year
                 mm,                                            // month
                 (integer) (b - d - llFloor(30.6001 * e) + f)   // day
               ];
    }
@| jyearl @}

\subsection{Julian day and fraction to UTC time}

Convert a Julian day and fraction passed in a list to UTC
hours, minutes, and seconds returned in a list.

@d jhms: Julian day and fraction to UTC time
@{
    list jhms(float j) {
        j += 0.5;                 // Astronomical to civil
        integer ij = (integer) ((j - llFloor(j)) * 86400.0);
        return [
                    (ij / 3600),        // hours
                    ((ij / 60) % 60),   // minutes
                    (ij % 60)           // seconds
               ];
    }
@| jhms @}

\section{Julian day arithmetic}

\subsection{Increment Julian day and fraction}

Add a floating point duration (which may be positive or negative)
to a Julian day and fraction and return a list of the sum.

@d sumJD: Increment Julian day and fraction
@{
    list sumJD(list jd, float dur) {
        integer ajd = llList2Integer(jd, 0);    // Full days...
        float ajdf = llList2Float(jd, 1);       // ...and day fraction
        integer duri = llFloor(dur);
        dur -= duri;
        ajd += duri;
        ajdf += dur;
        integer ajdfi = llFloor(ajdf);
        ajd += ajdfi;
        ajdf -= ajdfi;
        return [ ajd, ajdf ];
    }
@| sumJD @}

\subsection{Compare Julian days and fractions}

Compare two lists representing Julian days and fractions and
return:

\begin{eqnarray*}
    a > b & & 1 \\
    a = b & & 0 \\
    a < b & & -1
\end{eqnarray*}

@d compJD: Compare Julian days and fractions
@{
    integer compJD(list a, list b) {
        integer ai = llList2Integer(a, 0);
        float af = llList2Float(a, 1);
        integer bi = llList2Integer(b, 0);
        float bf = llList2Float(b, 1);

        if ((ai == bi) && (af == bf)) {
            return 0;
        }
        if ((ai > bi) || ((ai == bi) && (af > bf))) {
            return 1;
        }
        return -1;
    }
@| compJD @}

\section{Edit Date and Time}

These functions edit dates and times from internal representations
to primate-readable forms.

\subsection{Edit Julian day to UTC date and time}

A Julian day and fraction is edited to a UTC date and time in the
format YYYY-MM-DD HH:MM:SS.

@d editJDtoUTC: Edit Julian day to UTC date and time
@{
    string zerofill(integer n, integer places) {        // Integer to string with zero fill
        string sn = (string) n;
        while (llStringLength(sn) < places) {
            sn = "0" + sn;
        }
        return sn;
    }

    string editJDtoUTC(list jd) {
        list utctime = jhms(llList2Float(jd, 1));

        //  Round to nearest minute
        if (llList2Integer(utctime, 2) >= 30) {
            integer utchour = llList2Integer(utctime, 0);
            integer utcmin = llList2Integer(utctime, 1) + 1;
            if (utcmin >= 60) {
                utcmin -= 60;
                utchour++;
                if (utchour >= 24) {
                    utchour -= 24;
                    jd = llListReplaceList(jd, [  llList2Float(jd, 0) + 1 ], 0, 0);
                }
            }
            utctime = [ utchour, utcmin, 0 ];
        }

        list utcdate = jyearl(jd);
        string textutc = zerofill(llList2Integer(utcdate, 0), 4) +
                   "-" + zerofill(llList2Integer(utcdate, 1), 2) +
                   "-" + zerofill(llList2Integer(utcdate, 2), 2) +
                   " " + zerofill(llList2Integer(utctime, 0), 2) +
                   ":" + zerofill(llList2Integer(utctime, 1), 2);
        return textutc;
    }
@| editJDtoUTC zerofill @}

\subsection{Edit Julian day to decimal}

A Julian day and fraction is edited to a UTC date and time in the
format JJJJJJJ.FFFFFF.

@d editJDtoDec: Edit Julian day to decimal Julian day and fraction
@{
    string editJDtoDec(list jd) {
        string textjd = (string) llList2Float(jd, 0) + " " + (string) llList2Float(jd, 1);
        list ljd = llParseString2List(textjd, [".", " "], [" "]);
        textjd = llList2String(ljd, 0) + "." + llList2String(ljd, 3);

        return textjd;
    }
@| editJDtoDec @}

\chapter{Plot Objects}

These functions create objects in space in order to mark items.

\section{Plot line in space}

Plot a line using a cylinder prim.  We accept fully general arguments,
which allows swapping out the function for one which communicates with
the rezzed object over {\tt llRegionSayTo()} instead of via the {\tt
llRezObject()} start parameter with no change to client code.  The
length may range from 0.01 to 10.24 metres and the colour is coded with
four bits of RGB values.  The diameter is chosen as the closest to one
from the {\tt flPlotLineDiam} list.  Whether the line is temporary or
permanent is determined by the hidden argument {\tt flPlotPerm} which
should be set before calling the function.

@d flPlotLineDiam @{ [ 0.01, 0.015, 0.02, 0.025 ] @}

@d flPlotLine: Plot line in space
@{
    //  List of selectable diameters for lines
    list flPlotLineDiam = @<flPlotLineDiam@>;
    integer flPlotPerm = FALSE;     // Use permanent objects for plotted lines ?

    flPlotLine(vector fromPoint, vector toPoint,
               vector colour, float diameter) {
        float length = llVecDist(fromPoint, toPoint);
        vector midPoint = (fromPoint + toPoint) / 2;

        //  Encode length as integer from 0 to 1023 (10 bits)
        integer ilength = llRound((length * 100) - 0.01);
        if (ilength > 1023) {
            ilength = 1023;
        }

        //  Encode colour as RGB with 16 levels of colour (12 bits)
        integer icolour = (llRound(colour.x * 15) << 8) |
                          (llRound(colour.y * 15) << 4) |
                           llRound(colour.z * 15);

        /*  Find the closest match to the requested diameter
            among the options available in flPlotLineDiam  */

        integer bestdia;
        float bestdiamatch = 1e20;
        integer diax;

        for (diax = 0; diax < 4; diax++) {
            float d = llFabs(diameter - llList2Float(flPlotLineDiam, diax));
            if (d < bestdiamatch) {
                bestdiamatch = d;
                bestdia = diax;
            }
        }

        string lineObj = "flPlotLine";
        if (flPlotPerm) {
            lineObj = "flPlotLine Permanent";
        }
        flRezRegion(lineObj, midPoint, ZERO_VECTOR,
            llRotBetween(<0, 0, 1>, llVecNorm(toPoint - midPoint)),
            ((bestdia << 22) | (icolour << 10) | ilength)
        );
    }
@| flPlotLine @}

\subsection{flPlotLine object script}

This script is placed within the line plotting objects created by
{\tt flPlotLine()}.  At creation time, it decodes the arguments in
the {\tt on\_rez()} start param and sets the diameter, colour, and
length to those specified.

Note that the object is created transparent, and only becomes visible
when its colour and opacity is set after we've received control and
decoded the start parameter.  This avoids having mis-scaled and
-coloured objects appear for a while when rezzing in regions with a
long delay between {\tt llRezObject()} and {\tt on\_rez()} running in
the new object.  The script marks the object temporary so it doesn't
count against land impact and goes away automatically the next time
the garbage collector runs unless the object's name contains the
substring ``{\tt Permanent}'', in which case its temporary/permanent
status is left as defined in the inventory.

We listen for the ``{\tt ypres}'' message from our deployer and, upon
receipt, self-destruct.  This allows cleaning up lines drawn when the
object that drew them goes away.

@o scripts/flPlotLine.lsl
@{
    @<Explanatory header for LSL files@>

    key deployer;                       // ID of deployer who created us
    integer massChannel = @<massChannel@>;   // Channel for communicating with deployer
    string ypres = "B?+:$$";            // It's pronounced "Wipers"

    //  List of selectable diameters for lines
    list diam = @<flPlotLineDiam@>;

    default {

        on_rez(integer sparam) {
            if (llSubStringIndex(llGetObjectName(), "Permanent") < 0) {
                llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_TEMP_ON_REZ, TRUE ]);
            }

            deployer = llList2Key(llGetObjectDetails(llGetKey(),
                            [ OBJECT_REZZER_KEY ]), 0);

            //  Listen for messages from deployer
            llListen(massChannel, "", NULL_KEY, "");

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
            llSetLinkPrimitiveParamsFast(LINK_THIS, [
                PRIM_SIZE, < diameter, diameter, len >,
                PRIM_COLOR, ALL_SIDES, colour, 1
            ]);
        }
@}

The listen event handles messages from the deployer. Note that our
deployer will be the body which created us to plot a trail, {\em not}
the main deployer which created the objects.  Consequently, it is the
responsibility of that object to send the ``{\tt ypres}'' message to
clean up its trails.

@o scripts/flPlotLine.lsl
@{
        listen(integer channel, string name, key id, string message) {
            if (channel == massChannel) {
                list msg = llJson2List(message);
                string ccmd = llList2String(msg, 0);

                if (id == deployer) {

                    //  Message from Deployer

                    //  ypres  --  Destroy object

                    if (ccmd == ypres) {
                        llDie();
@}

The {\tt VERSION} message requests this script to check its build
number against that of the Deployer and report any discrepancy.

@o scripts/flPlotLine.lsl
@{
                        @<Check build number in created objects@>
                    }
                }
            }
        }
    }
@}

\section{Place marker ball in space}

A spherical marker is placed at region location {\tt where} with
the specified {\tt diameter} between 0.01 and 2.56 metres and
{\tt colour}, which is passed as a 24 bit RGB value coded into
the start parameter passed to the rezzed object.  You cannot
place a marker more than ten metres from the object that creates
it.  Whether the marker ball is temporary or permanent is
determined by the properties of the object rezzed and its
script.

@d markerBall: Place marker ball in space
@{
    markerBall(vector where, float diameter, vector colour) {
        colour *= 255;
        integer sparam = (llRound((diameter - 0.01) * 100) << 24) |
            (llRound(colour.x) << 16) | (llRound(colour.y) << 8) |
            llRound(colour.z);
        flRezRegion("Marker ball", where,
                    ZERO_VECTOR, ZERO_ROTATION, sparam);
    }
@| markerBall @}

\subsection{Marker ball object script}

This script is placed inside the marker balls created by {\tt
markerBall()}.  It interprets the parameters encoded in the start
parameter and sets the size and colour of the ball.

@o scripts/marker_ball.lsl
@{
    @<Explanatory header for LSL files@>

    key deployer;                       // ID of deployer who hatched us
    integer massChannel = @<massChannel@>;  // Channel for communications
    string ypres = "B?+:$$";            // It's pronounced "Wipers"

    default {

        on_rez(integer sparam) {
            if (sparam != 0) {
//              llSetLinkPrimitiveParamsFast(LINK_THIS, [ PRIM_TEMP_ON_REZ, TRUE ]);

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

                llSetLinkPrimitiveParamsFast(LINK_THIS, [
                    PRIM_SIZE, < diameter, diameter, diameter >,
                    PRIM_COLOR, ALL_SIDES, colour, 1
                ]);
            }
        }
@}

We listen on the {\tt massChannel} for an ``{\tt ypres}'' message to
clean up objects created by our deployer.

@o scripts/marker_ball.lsl
@{
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
@}

The {\tt VERSION} message requests this script to check its build
number against that of the Deployer and report any discrepancy.

@o scripts/marker_ball.lsl
@{
                    @<Check build number in created objects@>
                    }
                }
            }
        }
    }
@}

\section{Rez object anywhere in region}
\label{flRezRegion}

Instantiate (``rez'') an object anywhere within the current region.
The {\tt llRezObject()} API call is limited to creating objects within
10 metres of the creating object's position.  We check how far away
the desired position is from our position and if it's more than 9.5
metres away (allowing a safety margin for Second Life's signature
sloppiness) use {\tt llSetRegionPos} to jump there, create the object,
then jump back to our original position.

@d flRezRegion: Rez object anywhere in region
@{
    flRezRegion(string inventory, vector pos, vector vel,
                rotation rot, integer param) {
        vector crepos = llGetPos();
        if (llVecDist(pos, crepos) <= 9.5) {
            llRezObject(inventory, pos, vel, rot, param);
        } else {
            //  It's ugly, but it gets you there
            llSetRegionPos(pos);
            llRezObject(inventory, pos, vel, rot, param);
            llSetRegionPos(crepos);
        }
    }
@| flRezRegion @}

\section{Orbit plotter}

The Orbit Plotter plots orbits (and trajectories for parabolic and
hyperbolic objects) in two entirely different ways: as paths traced out
by cylinder prims created with {\tt flPlotLine()} and ellipse objects
(a flat cylinder prim scaled and rotated to the orientation of the
orbit.

\subsection{Orbit plotter link messages}

These messages are used to request plotting of orbit paths and
ellipses.

@d Orbit plotter link messages
@{
    integer LM_OR_PLOT = 601;           // Plot orbit for body
    integer LM_OR_ELLIPSE = 602;        // Fit ellipse to body
@}

\subsection{Compute apsides of solar system bodies}

To plot orbits of bodies in elliptical orbits, we need to know their
apsides: dates of nearest and farthest points from the central mass.
For Solar System bodies, whose positions we compute from analytic
planetary theories, this isn't directly available, so the following
tables and code compute approximate dates of apsides for planets.
Minor planet apsides are computed from their orbital elements.

For Mercury through Neptune, we use the method of chapter 38 of Meeus,
{\em Astronomical Algorithms}, 2nd ed. For Pluto, I use values computed
from its orbital elements in the JPL Small-Body database.

@d apsides: Compute apsides of solar system bodies
@{
    list apsTerms = [           // Apsis date from k value
        2451590, 0.257, 87, 0.96934963, 0,              // Mercury
        2451738, 0.233, 224, 0.7008188, -0.0000000327,  // Venus
        2451547, 0.507, 365, 0.2596358, 0.0000000156,   // Earth
        2452195, 0.026, 686, 0.9957857, -0.0000001187,  // Mars
        2455636, 0.936, 4332, 0.897065, 0.0001367,      // Jupiter
        2452830, 0.12, 10764, 0.21676, 0.000827,        // Saturn
        2470213, 0.5, 30694, 0.8767, -0.00541,          // Uranus
        2468895, 0.1, 60190, 0.33, 0.03429,             // Neptune
        2447654, 0.5293, 90487, 0.276927, 0             // Pluto
    ];

    list apsK = [               // k value from year and decimal
        4.15201, 2000.12,                               // Mercury
        1.62549, 2000.53,                               // Venus
        0.99997, 2000.01,                               // Earth
        0.53166, 2001.78,                               // Mars
        0.0843, 2011.2,                                 // Jupiter
        0.03393, 2003.52,                               // Saturn
        0.0119, 2051.1,                                 // Uranus
        0.00607, 2047.5,                                // Neptune
        0.004036, 1989.3478                             // Pluto
    ];

    list apsides(integer body, float year, integer apoapsis) {
        if (body < 10) {
            //  Major planet: use tables above
            body--;
            integer bx = body * 2;
            float k = llRound(llList2Float(apsK, bx) *
                                (year - llList2Float(apsK, bx + 1)));
            if (apoapsis) {
                k += 0.5;
            }
            bx = body * 5;
            integer jd = llList2Integer(apsTerms, bx);
            float jdf = ((llList2Float(apsTerms, bx + 4) * (k * k)) +
                         (llList2Float(apsTerms, bx + 3) * k) +
                         (llList2Float(apsTerms, bx + 2) * k)) +
                        llList2Float(apsTerms, bx + 1);
            integer jdfi = llFloor(jdf);
            jd += jdfi;
            jdf -= jdfi;
            return [ jd, jdf ];
        } else {
            //  Minor planet: compute from orbital elements
            integer bx = body * bodiesE;
            list tp = mp_peri;
            if (apoapsis) {
                //  Apoapsis time is periapsis plus half orbital period
                tp = sumJD(tp, llList2Float(bodies, bx) / 2);
            }
            return tp;
        }
    }
@| apsides @}

\subsection{Create an orbit ellipse}

Create an ellipse object which shows the orbit of an object.  This is
called with arguments which describe the orbit by its orbital elements
and specific points (periapse, apoapse, and co-vertex) along it.  An
{\tt Orbit ellipse} object is created with the proper position,
orientation, and scale factor to illustrate the orbit of the body.

@d createOrbitEllipse: Create an orbit ellipse
@{
    list orbitParams = [ ];             // Orbit ellipse parameters
    integer orbitParamsE = 6;           // Orbit parameters entry length

    createOrbitEllipse(string args) {
        list el = llJson2List(args);
        integer m_body = llList2Integer(el, 0);
        string m_name = llList2String(el, 1);
        vector m_periapse = (vector) llList2String(el, 2);
        vector m_apoapse = (vector) llList2String(el, 3);
        float m_a = llList2Float(el, 4);
        float m_e = llList2Float(el, 5);
        float s_auscale = llList2Float(el, 6);
        vector m_covertex = (vector) llList2String(el, 7);

        //  Parameters derived from elements

        vector c_centre = (m_periapse + m_apoapse) / 2; // Centre point
        float c_b = m_a * llSqrt(1 - (m_e * m_e));      // Semi-minor axis
@| createOrbitEllipse @}

For debugging, create markers to show the points which define the
orbital ellipse.

@d createOrbitEllipse: Create an orbit ellipse
@{
//  Mark periapse, apoapse, co-vertex, centre, and normal
//markerBall(m_periapse, 0.1, <1, 0.25, 0.25>);       // Periapse: red
//markerBall(m_apoapse, 0.1, <0.25, 1, 0.25>);        // Apoapse: green
//markerBall(c_centre, 0.1, <1, 1, 0.25>);            // Centre: yellow
//markerBall(m_covertex, 0.1, <0.25, 0.25, 1>);       // Co-vertex: blue
// vector c_plnorm = llVecNorm(m_periapse - c_centre) %    // Normal to orbital plane
//    llVecNorm(m_covertex - c_centre);
//markerBall(c_centre + (c_plnorm * 0.15), 0.1, <1, 0.25, 1>);    // Normal to centre: magenta
@}

At this point the two vertices of the ellipse are coincident with the
periapse and apoapse of the orbit, and hence all that remains is to
rotate the ellipse around this axis (its local $X$ axis) until its
local $Y$ axis lines up with the co-vertex of the orbit.  Because {\tt
llRotBetween()} is the bad boy of LSL rotations, this is easier said
than done.  {\tt llRotBetween()} makes things line up, but it doesn't
tell you {\em how}, so the ellipse prim may now be in any possible
orientation with respect to where we want it to be.  It's trivially
easy to determine the angle between the ellipse's $X$ axis and the
co-vertex vector, but another matter entirely to decide which way to
rotate the thing in order to align them.  The following hackery
accomplishes that. There may be a far simpler one- or two-liner which
does the same thing, but so far it has eluded me.

First, we align the ellipse's semi-major axis with that of the orbit.

@d createOrbitEllipse: Create an orbit ellipse
@{
        rotation c_rotation = llRotBetween(<1, 0, 0>, llVecNorm(m_periapse - c_centre));

        vector c_left = llRot2Left(c_rotation);         // Local Y axis after apsides alignment
//markerBall(c_centre + (c_left * (c_b * s_auscale)), 0.1, <0.5, 0.5, 0.5>);
        // Vector from centre to covertex on orbit
        vector v1 = llVecNorm(m_covertex - c_centre);
        //  Angle to rotate ellipse around its local X axis
        float plxang = llAsin(llVecMag(c_left % v1));
        //  Angle between Y axis and covertex normal and periapse: sign detects flip of ellipse
        float dmdot = llVecNorm(c_left % v1) * llVecNorm(m_periapse - c_centre);
        //  Angle between Y axis and covertex: detects ellipse inversion
        float ladot = llAcos(v1 * c_left);
        if (ladot > PI_BY_TWO) {
            dmdot = -dmdot;
        }
        c_rotation = llAxisAngle2Rot(<1, 0, 0>, (dmdot * plxang)) * c_rotation;
@}

We now know the parameters needed to scale and orient the orbit
ellipse. Since we can't transmit them when it's created, save them to
send when the orbit ellipse's script checks in after creation.

@d createOrbitEllipse: Create an orbit ellipse
@{
        orbitParams += [ m_body,                                    // 0    Body number
                         m_name,                                    // 1    Name
                         <m_a * 2 * s_auscale, c_b * 2 * s_auscale, 0.01>,  // 2    Size
                         ZERO_ROTATION,                             // 3    Rotation
                         <1, 1, 0.5>,                               // 4    Colour
                         0.25                                       // 5    Alpha
                       ];

        //  Create the orbit ellipse at the centre

        flRezRegion("Orbit ellipse", c_centre,
                    ZERO_VECTOR, c_rotation, m_body);
        llMessageLinked(LINK_THIS, LM_CP_RESUME, "", whoDat);
    }
@}

\subsection{Process ``Orbits'' auxiliary command}

The main script delegates processing of the ``Orbits'' command to us
via the auxiliary command ({\tt LM\_CP\_COMMAND}) mechanism.  Here
we parse the command and initiate generation of the orbital plot.
We also handle the ``Status'' command, which may be forwarded to us
to ask how we're doing with script memory.

@d processOrbitsAuxCommand: Process ``Orbits'' auxiliary command
@{
    integer processOrbitsAuxCommand(key id, list oparams) {

        whoDat = id;            // Direct chat output to sender of command

        string message = llList2String(oparams, 0);
        list args = llParseString2List(llToLower(message), [ " " ], []);
        string command = llList2String(args, 0);    // The command
@}

The ``Orbits'' command has the syntax:

\begin{verse}
    {\tt Orbit} {\em body} [ {\em segments}/{\tt ellipse} [ {\tt permanent} ] ]
\end{verse}

\noindent
For the Solar System model, the {\em body} may be specified either as a
planet number, with $10$ denoting the currently-tracked minor planet,
or by the name of the planet or minor planet (which may not be
abbreviated and must be specified exactly).  For the Galactic Centre
model, the source may be specified by the number of the Source, in the
order they were declared, starting with 1, or by the full, exact name
of the source.  The optional parameters allow specifying the number of
segments used to plot the orbit (which will be adjusted automatically
in portions of rapid motion) or ``{\tt ellipse}'' to show the orbit as
an ellipse object (this cannot be used for objects which are on
parabolic or hyperbolic trajectories.  By default, orbit paths are
traced by temporary objects which do not count against land capacity
and are automatically deleted in the next garbage collection.  If
``{\tt permanent}'' is specified, permanent objects will be used
instead (note that this can easily hit the land capacity of smaller
parcels).

@d processOrbitsAuxCommand: Process ``Orbits'' auxiliary command
@{
        if (abbrP(command, "or")) {
            float s_auscale = llList2Float(oparams, 1);
            integer planetsPresent = llList2Integer(oparams, 2);
            vector deployerPos = (vector) llList2String(oparams, 4);
            list simEpoch = llList2List(oparams, 5, 6);

            //  Re-process arguments to preserve case and strings
            args = fixQuotes(llParseString2List(message, [ " " ], []));
            integer argn = llGetListLength(args);

            string body = llList2String(args, 1);
@}

If we are displaying the Solar System model, allow the user to specify
the name of the object, including a minor planet being tracked, by its
(full and exact) name as well as number.  Note how we cleverly exclude
the Sun along with no-find results.

@d processOrbitsAuxCommand: Process ``Orbits'' auxiliary command
@{
            if (planetsPresent) {
                integer p = llListFindList(bodies, [ body ]);
                if (p > bodiesE) {
                    body = (string) ((p - 3) / bodiesE);
                }
@}

If we are displaying the Galactic Centre model, similarly allow
specifying the source by name.  If a number is given, simply select the
source in the order they were declared.

@d processOrbitsAuxCommand: Process ``Orbits'' auxiliary command
@{
            } else if (gc_source != [ ]) {
                integer p = llListFindList(gc_source, [ body ]);
                if (p > 0) {
                    body = (string) (((p - 1) / gc_sourceE) + 1);
                }
            }

            integer segments = 48;
            integer permanent = FALSE;
            if (argn > 2) {
                if (abbrP(llToLower(llList2String(args, 2)), "el")) {
                    segments = -999;
                } else if (abbrP(llToLower(llList2String(args, 2)), "pe")) {
                    permanent = TRUE;
                } else {
                    segments = llList2Integer(args, 2);
                }
                if (argn > 3) {
                    permanent = abbrP(llToLower(llList2String(args, 3)), "pe");
                }
            }
@}

Now that the arguments have all been parsed, submit the request to plot
the orbit.  These link messages are actually procesed in this very
script, but doing this way allows us to move that lengthy code to
another script should we hit the script memory wall as features are
added.

@d processOrbitsAuxCommand: Process ``Orbits'' auxiliary command
@{
            if (segments == -999) {
               llMessageLinked(LINK_THIS, LM_OR_ELLIPSE,
                    llList2CSV([ body,  llList2Integer(simEpoch, 0),
                                 llList2Float(simEpoch, 1), s_auscale,
                                 deployerPos, permanent ]), whoDat);
            } else {
                llMessageLinked(LINK_THIS, LM_OR_PLOT,
                    llList2CSV([ body,  llList2Integer(simEpoch, 0),
                                 llList2Float(simEpoch, 1), s_auscale, segments,
                                 deployerPos, permanent ]), whoDat);
            }
@}

Process the ``Status'' command.  All it does is print script memory
status.

@d processOrbitsAuxCommand: Process ``Orbits'' auxiliary command
@{
        } else if (abbrP(command, "sta")) {
            string s = llGetScriptName() + " status:\n";

            integer mFree = llGetFreeMemory();
            integer mUsed = llGetUsedMemory();
            s += "  Script memory.  Free: " + (string) mFree +
                    "  Used: " + (string) mUsed + " (" +
                    (string) ((integer) llRound((mUsed * 100.0) / (mUsed + mFree))) + "%)";
            tawk(s);
        }
        return TRUE;
    }
@| processOrbitsAuxCommand @}

\subsection{Orbit plotter script}

This is the script which processes orbit plotting requests.
It processes ``Orbit'' commands forwarded by the Deployer and generates
the requested plot.

Declare the global variables.

@o scripts/orbits.lsl
@{
    @<Explanatory header for LSL files@>

    key owner;                          // Owner UUID
    key whoDat = NULL_KEY;              // Avatar who sent command

    integer massChannel = @<massChannel@>;  // Channel for communicating with Deployer

    integer ephHandle = 192523;         // Ephemeris handle for orbit tracing
    integer ephHandleEll = 192524;      // Ephemeris handle for ellipse fitting
@}

The {\tt bodies} list declares properties of Solar System planets. Even
though these are declared in the scripts for the individual objects, we
need to be able to access them even if the planet has not been
instantiated.  Items in each list entry are:

\hspace{4em}\vbox{
\begin{description}
\dense
    \item[0]    Orbital period (days)
    \item[1]    Eccentricity
    \item[2]    Semi-major axis (AU)
    \item[3]    Name
\end{description}
}

@o scripts/orbits.lsl
@{
    list bodies = [
        0, 0, 0,                                        "Sun",
        87.9691, 0.20563069, 0.38709893,                "Mercury",
        224.701, 0.00677323, 0.72333199,                "Venus",
        365.256363004, 0.01671022, 1.00000011,          "Earth",
        686.971, 0.09341233, 1.52366231,                "Mars",
        4332.59, 0.04839266, 5.20336301,                "Jupiter",
        10759.22, 0.05415060, 9.53707032,               "Saturn",
        30688.5, 0.04716771, 19.19126393,               "Uranus",
        60182.0, 0.00858587, 30.06896348,               "Neptune",
        90487.2769, 0.2502487, 39.4450697,              "Pluto",
        -1.0, 0, 0, "??MP??"                            // Minor planet tracked
    ];
    integer bodiesE = 4;            // Length of bodies entry
@}

For Galactic Centre objects, we are notified whenever a Source is
added.  We save its properties in the following list in a record
as follows:

\hspace{4em}\vbox{
\begin{description}
\dense
    \item[0]    Source index $[1, n]$
    \item[1]    Name
    \item[2]    Orbital period ({\tt NaN} if $e \geq 1$)
    \item[3--4]  Periapse date
    \item[5]    Eccentricity ($e$)
    \item[6]    Semi-major axis ({\tt NaN} if $e \geq 1$)
\end{description}
}

@o scripts/orbits.lsl
@{
    list gc_source = [ ];
    integer gc_sourceE = 7;         // Length of source entry
@}

The following variables are used in plotting orbits.

@o scripts/orbits.lsl
@{
    integer o_body;                     // Body
    list o_jd;                          // Julian day and fraction
    float o_auscale;                    // Astronomical unit scale factor
    integer o_nsegments;                // Number of segments to plot
    vector o_sunpos;                    // Position of Sun in region

    list mp_peri;                       // Time of perihelion for non-elliptical orbit
    integer o_parahyper;                // Parabolic/hyperbolic orbit for tracked body ?

    integer o_bselect;                  // Select index for body
    integer o_csegment;                 // Current segment
    float o_timestep;                   // Time step per segment
    vector o_olast;                     // Location of previous segment

    float angsegMax = 0.0872664626;     // 5 * DEG_TO_RAD
    vector o_prevseg;                   // Previous segment of orbit plot
    list prev_o_jd;                     // Start time of previous segment
    float eff_timestep = 0;             // Effective time step from adaptive adjustment
    list o_enddate;                     // End date of orbit plot
@}

We respond to and reply with the following link message codes.

@o scripts/orbits.lsl
@{
    @<Command processor messages@>
    @<Ephemeris link messages@>
    @<Minor planet link messages@>
    @<Galactic centre messages@>
    @<Orbit plotter link messages@>
    @<Auxiliary services messages@>
@}

Import the following utility functions.

@o scripts/orbits.lsl
@{
    @<tawk: Send a message to the interacting user in chat@>
    @<sumJD: Increment Julian day and fraction@>
    @<compJD: Compare Julian days and fractions@>
    @<jyearl: Julian day and fraction to Gregorian date@>
    @<flRezRegion: Rez object anywhere in region@>
    @<flPlotLine: Plot line in space@>
    @<sphRect: Spherical to rectangular co-ordinate conversion@>
/*
    @<markerBall: Place marker ball in space@>
*/
    @<fixQuotes: Consolidate quoted arguments@>
    @<abbrP: Test argument, allowing abbreviation@>
@}

These are our local functions, defined above.

@o scripts/orbits.lsl
@{
    @<apsides: Compute apsides of solar system bodies@>
    @<createOrbitEllipse: Create an orbit ellipse@>
    @<processOrbitsAuxCommand: Process ``Orbits'' auxiliary command@>
@}

Here is the event processor.  It lives to serve the Deployer, whence
cometh its invocations.  State entry is straightforward, simply
beginning to listen to objects we will be creating.  It might be nice
to defer starting the listener until we create the first object.

@o scripts/orbits.lsl
@{
    default {

        on_rez(integer start_param) {
            llResetScript();
        }

        state_entry() {
            whoDat = owner = llGetOwner();
            //  Listen for messages from objects we create
            llListen(massChannel, "", NULL_KEY, "");
        }
@}

We are event-driven, responding to link messages from other scripts.
Orbit plots are requested by the ``Orbit'' command, which is forwarded
by the main user interface script via the {\tt LM\_CP\_COMMAND}
message.

@o scripts/orbits.lsl
@{
        link_message(integer sender, integer num, string str, key id) {

            //  LM_CP_COMMAND (223): Process auxiliary command

            if (num == LM_CP_COMMAND) {
                processOrbitsAuxCommand(id, llJson2List(str));
@}

The {\tt LM\_CP\_REMOVE} message informs us that the user has requested
the removal of the entire model.  The main command processor sends the
``{\tt ypres}'' message to get rid of the objects, so we need only
adjust our local status to reflect their removal.

@o scripts/orbits.lsl
@{

            //  LM_CP_REMOVE (226): Remove model

            } if (num == LM_CP_REMOVE) {
                //  Drop tracking of Solar System minor planet
                integer bx = 10 * bodiesE;
                bodies = llListReplaceList(bodies, [ -1.0 ], bx, bx);
                gc_source = [ ];                // Remove Galactic Centre sources
@}

The {\tt LM\_OR\_PLOT} message starts the process of plotting an
orbital path.  We begin by unpacking the arguments from the request and
decide whether we're plotting an orbit in the Solar System or around
the Galactic Centre.

@o scripts/orbits.lsl
@{

            //  LM_OR_PLOT (601): Plot orbit

            } else if (num == LM_OR_PLOT) {
                list l = llCSV2List(str);
                o_body = llList2Integer(l, 0);          // Body
                o_auscale = llList2Float(l, 3);         // Astronomical unit scale factor
                o_nsegments = llList2Integer(l, 4);     // Number of segments to plot
                o_sunpos = (vector) llList2String(l, 5); // Position of Sun
                flPlotPerm = llList2Integer(l, 6);      // Use permanent lines ?
                integer gc = gc_source != [ ];          // Galactic Centre source ?
                integer gx = (o_body - 1) * gc_sourceE; // Source list index
                integer bx = o_body * bodiesE;          // Solar system body index

                o_csegment = 0;                     // Current segment being plotted
@}

Next, we must determine the orbital period and eccentricity, which is
specified differently for the Solar System and Galactic Centre. We
compute the start and end dates we're going to plot.  For an elliptical
orbit, these are simply the current time and one orbital period hence.
For an open (parabolic or hyperbolic) trajectory, we for a specified
time around the periapse.

@o scripts/orbits.lsl
@{

                float o_ecc;                        // Eccentricity
                float o_period;                     // Orbital period if o_ecc < 1
                if (gc) {
                    //  Galactic Centre source
                    o_bselect = (o_body << 16);
                    o_ecc = llList2Float(gc_source, gx + 5);
                    o_parahyper = o_ecc >= 1;
                    if (!o_parahyper) {
                        //  Convert years to days for period
                        o_period = llList2Float(gc_source, gx + 2) * 365.25;
                    } else {
                        mp_peri = llList2List(gc_source, gx + 3, gx + 4);
                    }
                } else {
                    //  Solar System body
                    o_bselect = 1 << o_body;
                    o_ecc = llList2Float(bodies, bx + 1);
                    if (!o_parahyper) {
                        o_period = llList2Float(bodies, bx);
                    }
                }
                if (o_parahyper) {
                    o_timestep = (2.5 * 365) / o_nsegments;
                } else {
                    o_timestep = o_period / o_nsegments;
                }
                if (!o_parahyper) {
                    o_jd = llList2List(l, 1, 2);    // Julian day and fraction
                    o_enddate = sumJD(o_jd, o_timestep * o_nsegments);
                } else {
                    /*  If the trajectory is parabolic or hyperbolic, begin
                        plotting at the start of the inbound arm toward the
                        periapse and plot to the end of the outbound arm.  */
                    o_jd = sumJD(mp_peri, -(o_timestep * o_nsegments));
                    o_enddate = sumJD(mp_peri, o_timestep * o_nsegments);
                }
                //  Ending date for orbit computation (or arm if open trajectory)
//tawk("Start date: " + llList2CSV(o_jd) + "  End date: " + llList2CSV(o_enddate));
@}

We're now ready to start the ephemeris calculation process.  Send the
{\tt LM\_EP\_CALC} request to the body's ephemeris calculator for the
starting date of the plot.

@o scripts/orbits.lsl
@{
                //  Start the first ephemeris calculation
                llMessageLinked(LINK_THIS, LM_EP_CALC,
                    llList2CSV([ o_bselect ] + o_jd + [ ephHandle ]), id);
@}

When we submit a {\tt LM\_EP\_CALC} request to the body's ephemeris
calculator, it responds with a {\tt LM\_EP\_RESULT} message containing
the position(s) for the requested date(s).  We make these requests in
two very different ways depending on whether we're plotting the orbital
path or representing it with an ellipse.

@o scripts/orbits.lsl
@{

            //  LM_EP_RESULT (432): Ephemeris calculation results

            } else if (num == LM_EP_RESULT) {
                list l = llCSV2List(str);
                integer body = llList2Integer(l, 0);        // Body
                integer gc = body >= 0x1000;                // Is this a Galactic Centre source ?
@}

If the request for an orbital path plot (identified by its having been
made with the ``handle'' {\tt ephHandle}), this provides one position
along the path.  We create a line segment between each pair of points
and, if we have not yet reached the end of the plot, submit the next
ephemeris request for the next segment.

@o scripts/orbits.lsl
@{
               //   Only process if handle is our own
               if (ephHandle == llList2Integer(l, -1)) {
                    vector where;
                    float L = llList2Float(l, 1);           // Ecliptical longitude
                    float B = llList2Float(l, 2);           // Ecliptical latitude
                    float R = llList2Float(l, 3);           // Radius
                    if (!gc) {
                        //  Solar System body
                        where = sphRect(L, B, R);
                    } else {
                        //  Galactic Centre source: already in rectangular co-ordinates
                        where = < L, B, R >;
                    }
                    vector rwhere = (where * o_auscale) + o_sunpos;
                    if (o_csegment == 0) {
                        //  This is the first point, just save for first segment
                        prev_o_jd = o_jd;
                    } else {
@}

This is the dreaded adaptive segment length computation.  We calculate
the angle this just-computed segment forms with the previous segment.
If this exceeds {\tt angSegMax}, we conclude that we need more segments
to avoid a Jagged Orbit.  This is accomplished by dividing the
previously estimated {\tt o\_timestep} by a factor determined by the
extent the measured angle exceeds the limit.  We then discard the
just-computed ephemeris position and start a new computation with the
reduced effective time step, {\tt eff\_timestep}.

@o scripts/orbits.lsl
@{
                        vector currseg = llVecNorm(rwhere - o_olast);
                        if (o_prevseg != ZERO_VECTOR) {
                            float angseg = llAcos(o_prevseg * currseg);
//tawk("Sector " + (string) o_csegment + " angle " + (string) (angseg * RAD_TO_DEG) +
//  "  JD " + llList2CSV(o_jd));
                            if ((angseg > angsegMax) && ((eff_timestep == 0) || (llFabs(eff_timestep) > 1))) {
                                integer splitseg = llCeil(angseg / angsegMax);
                                float j_timestep = o_timestep;
                                if (eff_timestep != 0) {
                                    j_timestep = eff_timestep;
                                }
                                eff_timestep = j_timestep / splitseg;
//tawk("  Split segment into " + (string) splitseg + " eff_timestep " + (string) eff_timestep +
//     " o_timestep " + (string) o_timestep);
                                o_jd = sumJD(prev_o_jd, eff_timestep);
                                llMessageLinked(LINK_THIS, LM_EP_CALC,
                                    llList2CSV([ o_bselect ] + o_jd + [ ephHandle ]), id);
                                //  Done until computation of reduced segment result appears
                                return;
                            } else {
                                eff_timestep = 0;
                            }
                        }
                        o_prevseg = currseg;
@}

The segment is sufficiently straight---plot it.

@o scripts/orbits.lsl
@{
//tawk("Plot segment " + (string) o_csegment + " from " + (string) o_olast + " to " + (string) rwhere);
                        float meanZ = ((o_olast.z - o_sunpos.z) +
                            (rwhere.z - o_sunpos.z)) / 2;
                        vector segcol = <0, 0.75, 0>;
                        if (meanZ < 0) {
                            segcol = <0.75, 0, 0>;
                        }
                        flPlotLine(o_olast, rwhere, segcol, 0.01);
                    }
                    o_csegment++;
                    o_olast = rwhere;
@}

Now advance the date and request the next point along the orbit.  We
then wait until the ephemeris calculator delivers the position for that
date.  If we've reached the end of the plot (where we started for an
ellipse, end date for an open trajectory), the plot is complete and we
allow a script which was paused while running the command to resume
execution.

@o scripts/orbits.lsl
@{
                    if (compJD(o_jd, o_enddate) < 0) {
                        prev_o_jd = o_jd;
                        o_jd = sumJD(o_jd, o_timestep);
                        /*  If the time step would take us past the computed
                            o_enddate, adjust it to end at that time.  */
                        if (compJD(o_jd, o_enddate) > 0) {
                            o_jd = o_enddate;
                        }
                        llMessageLinked(LINK_THIS, LM_EP_CALC,
                            llList2CSV([ o_bselect ] + o_jd + [ ephHandle ]), id);
                    } else {
                        /*  We've reached the end of the orbit.  Resume script
                            if suspended.  */
                        llMessageLinked(LINK_THIS, LM_CP_RESUME, "", id);
                    }

                } else if (ephHandleEll == llList2Integer(l, -1)) {
@}

We're fitting an ellipse to the body's orbit and have just received the
body's periapse, apoapse, and co-vertex location from its ephemeris
calculator.  For an ellipse, we need only this single ephemeris
request.  Now we're ready to create the ellipse to display the orbit.

@o scripts/orbits.lsl
@{
                    vector pXYZr;           // Periapse co-ordinates
                    vector aXYZr;           // Apoapse co-ordinates
                    vector cXYZr;           // Co-vertex co-ordinates
                    float m_a;              // Semi-major axis
                    float m_e;              // Eccentricity
                    if (!gc) {
                        vector wXYZ = sphRect(llList2Float(l, 1),   // Peri L
                                              llList2Float(l, 2),   // Peri B
                                              llList2Float(l, 3));  // Peri R
                        pXYZr = (wXYZ * o_auscale) + o_sunpos;
                        wXYZ = sphRect(llList2Float(l, 4),          // Apo  L
                                       llList2Float(l, 5),          // Apo  B
                                       llList2Float(l, 6));         // Apo  R
                        aXYZr = (wXYZ * o_auscale) + o_sunpos;
                        wXYZ = sphRect(llList2Float(l, 7),          // Cvtx L
                                       llList2Float(l, 8),          // Cvtx B
                                       llList2Float(l, 9));         // Cvtx R
                        cXYZr = (wXYZ * o_auscale) + o_sunpos;
                        m_a = llList2Float(bodies, (body * bodiesE) + 2);
                        m_e = llList2Float(bodies, (body * bodiesE) + 1);
                    } else {
                        /*  The Galactic Centre module returns galactic
                            rectangular co-ordinates, so they may be used
                            directly without transformation from spherical.  */
                        pXYZr = (< llList2Float(l, 1),
                                   llList2Float(l, 2),
                                   llList2Float(l, 3) > * o_auscale) + o_sunpos;
                        aXYZr = (< llList2Float(l, 4),
                                   llList2Float(l, 5),
                                   llList2Float(l, 6) > * o_auscale) + o_sunpos;
                        cXYZr = (< llList2Float(l, 7),
                                   llList2Float(l, 8),
                                   llList2Float(l, 9) > * o_auscale) + o_sunpos;
                        integer gx = ((body >> 16) - 1) * gc_sourceE; // Source list index
                        m_a = llList2Float(gc_source, gx + 6);
                        m_e = llList2Float(gc_source, gx + 5);
                    }
                    string ellargs = llList2Json(JSON_ARRAY, [
                        body,                       // 0    Body number
                        "Planet " + (string) body,  // 1    Body name
                        pXYZr,                      // 2    Periapse location
                        aXYZr,                      // 3    Apoapse location
                        m_a,                        // 4    Semi-major axis
                        m_e,                        // 5    Eccentricity
                        o_auscale,                  // 6    Astronomical unit scale factor
                        cXYZr                       // 7    Co-vertex location
                    ]);
                    createOrbitEllipse(ellargs);
                    llMessageLinked(LINK_THIS, LM_CP_RESUME, "", id);
               }
@}

We need the orbital parameters for Solar System minor planets being
tracked, so we listen for the {\tt LM\_MP\_TRACK} messages sent
whenever a new body is being tracked and save them for use when its
orbit is requested.

@o scripts/orbits.lsl
@{
            //  LM_MP_TRACK (571): Tracking minor planet

            } else if (num == LM_MP_TRACK) {
                /*  The main thing we care about is a minor planet's
                    orbital period.  If it's undefined, we must resort
                    to "other means" when plotting the orbit.  */
                list args = llJson2List(str);
                if (llList2Integer(args, 0)) {
                    integer bx = 10 * bodiesE;
                    //  Plug the tracked body's name and elements into the bodies list
                    float ecc = llList2Float(args, 7);
                    bodies = llListReplaceList(bodies,
                        [ llList2Float(args, 2),        // Orbital period
                          ecc,                          // Eccentricity
                          llList2Float(args, 6),        // Semi-major axis
                          llList2String(args, 1)        // Name
                        ], bx, bx + 3);
                    o_parahyper = ecc >= 1;
                    mp_peri = llList2List(args, 4, 5);  // Perihelion date and fraction
                } else {
                    //  Dropping tracking of current object
                    integer bx = 10 * bodiesE;
                    bodies = llListReplaceList(bodies,
                        [ -1.0, 0, 0, "??MP??"  ], bx, bx + 3);
                }
@}

The {\tt LM\_OR\_ELLIPSE} message requests fitting an ellipse to an
orbit.  It is sent after an ``Orbits'' command requesting such a plot
for a body is parsed.  We compute the dates of the periapse, apoapse,
and a co-vertex (a point where the ellipse intersects the semi-minor
axis).  The centre of the ellipse will be the midpoint between the
periapse and apoapse point.  These four points are sufficient to define
the unique shape, size, and orientation of the ellipse in space.  Here
we simply compose an ephemeris request to obtain the points we need and
wait for the reply to arrive.

@o scripts/orbits.lsl
@{
            //  LM_OR_ELLIPSE (602): Plot orbit ellipse

            } else if (num == LM_OR_ELLIPSE) {
                list l = llCSV2List(str);
                integer body = llList2Integer(l, 0);
                o_jd = llList2List(l, 1, 2);                    // Julian day and fraction
                o_auscale = llList2Float(l, 3);                 // Astronomical unit scale factor
                o_sunpos = (vector) llList2String(l, 4);        // Position of Sun

                list edate = jyearl(llList2List(l, 1, 2));
                /*  Compute approximate year and fraction from
                    month and day.  This is a rough approximation,
                    so there's no need to go back and do it with
                    full Julian day arithmetic.  */
                float eyear = llList2Integer(edate, 0) +
                              ((llList2Integer(edate, 1) - 1) / 12.0) +
                              ((llList2Integer(edate, 2) - 1) / 30.0);

                integer gc = gc_source != [ ];          // Galactic Centre source ?
                integer gx = (body - 1) * gc_sourceE;   // Source list index
                integer bx = body * bodiesE;            // Solar system body index

                //  Get dates of periapse and apoapse
                list dPeri;             // Periapse date
                list dApo;              // Apoapse date
                list dCvtx;             // Co-vertex date
                float m_e;              // Eccentricity
                float o_period;         // Orbital period
                if (gc) {
                    //  Galactic Centre source
                    o_bselect = (body << 16);
                    m_e = llList2Float(gc_source, gx + 5);              // Eccentricity
                    dPeri = llList2List(gc_source, gx + 3, gx + 4);     // Periapse date
                    if (m_e < 1) {      // Avoid math error is period is NaN for open trajectory
                        o_period = llList2Float(gc_source, gx + 2) * 365.25;    // Orbital period
                    }
                    dApo = sumJD(dPeri, o_period / 2);                  // Apoapse date
                } else {
                    //  Solar System body
                    o_bselect = 1 << body;
                    m_e = llList2Float(bodies, bx + 1);                 // Eccentricity
                    if (m_e < 1) {      // Avoid math error for undefined period
                        dPeri = apsides(body, eyear, FALSE);
                        dApo = apsides(body, eyear, TRUE);
                        o_period = llList2Float(bodies, bx);            // Orbital period
                    }
                }
                //  If eccentricity is >= 1, we can't fit an ellipse
                if (m_e >= 1) {
                    tawk("Cannot fit an ellipse.  Eccentricity is " + (string) m_e + ".");
                    llMessageLinked(LINK_THIS, LM_CP_RESUME, "", id);
                    return;
                }
                dCvtx = sumJD(dPeri,                                        // Compute co-vertex date
                              o_period * (0.25 - (m_e / TWO_PI)));
                list ephreq = [ o_bselect ] + dPeri + dApo + dCvtx + [ ephHandleEll ];
                llMessageLinked(LINK_THIS, LM_EP_CALC, llList2CSV(ephreq), id);
@}

Just as we listen for minor planets being tracked in the Solar System
model, we listen for {\tt LM\_GC\_SOURCES} messages informing us of
sources being added to the Galactic Centre model.  We save the source
information to allow us to plot its orbit, if requested.

@o scripts/orbits.lsl
@{

            //  LM_GC_SOURCES (752): Adding Galactic Centre source

            } else if (num == LM_GC_SOURCES) {
                /*  The main thing we care about is a source's
                    orbital period and perhielion date.  If its
                    eccentricity is >= 1, the orbital period is
                    undefined (NaN) and we plot an open
                    trajectory.  We also save the semi-major axis
                    (if defined) in case we'll be fitting an
                    ellipse.  */
                list args = llJson2List(str);
                if (llList2Integer(args, 1) > 0) {
                    gc_source += llList2List(args, 1, gc_sourceE);
                }
@}

The {\tt LM\_AS\_VERSION} message requests this script to check its
build number against that of the Deployer and report any discrepancy.

@o scripts/orbits.lsl
@{
            @<Check build number in Deployer scripts@>
            }
        }
@}

When we've created an ellipse to plot an orbit, it requires more
information than can be passed in an integer start parameter.  When the
ellipse is created, it sends an {\tt ORBITAL} message back to us as its
creator.  We respond with an {\tt ORBITING} message which supplies the
parameters to scale and orient the ellipse in space.

@o scripts/orbits.lsl
@{
        listen(integer channel, string name, key id, string message) {
//llOwnerSay(llGetScriptName() + " channel " + (string) channel + " id " + (string) id +  " message " + message);
            if (channel == massChannel) {
                list msg = llJson2List(message);
                string ccmd = llList2String(msg, 0);

                if (ccmd == "ORBITAL") {
                    integer m_index = llList2Integer(msg, 1);
                    integer i;
                    integer n = llGetListLength(orbitParams);

                    for (i = 0; i < n; i += orbitParamsE) {
                        if (llList2Integer(orbitParams, i) == m_index) {
                            llRegionSayTo(id, massChannel,
                                llList2Json(JSON_ARRAY, [ "ORBITING" ] +
                                    llList2List(orbitParams, i, i + (orbitParamsE - 1))));
                            //  Delete this item from orbitParams
                            orbitParams = llDeleteSubList(orbitParams, i, i + (orbitParamsE - 1));
                            return;
                        }
                    }
//tawk("Unable to find orbitParams for mass " + (string) m_index);
                }
            }
        }
    }
@}

\subsection{Orbit ellipse script}

When we create an ellipse to represent an orbit, an instance of an
``{\tt Orbit ellipse}'' object is created aligned with the centre of
the orbit (the midpoint between the periapse and apoapse).  The ellipse
object contains this script, which sends an {\tt ORBITAL} message to
the deployer to inform it that it's listening.  The deployer responds
with {\tt ORBITING} message which supplies the name, size, and colour
for the ellipse.  (Its position and orientation have already been set
at the time it was created.)

As usual, start with global variables.

@o scripts/orbit_ellipse.lsl
@{
    @<Explanatory header for LSL files@>

    key deployer;                       // ID of deployer who hatched us
    integer massChannel = @<massChannel@>;  // Channel for communicating with deployer
    string ypres = "B?+:$$";            // It's pronounced "Wipers"

    //  Configuration parameters

    integer m_index;                    // Index of body whose orbit we represent
    string m_name;                      // Name of orbit object
    vector m_size;                      // Size
    vector m_colour;                    // Colour
    float m_alpha;                      // Transparency (0 = transparent, 1 = solid)
@}

At creation time, we send the {\tt ORBITAL} message to the deployer to
inform it we're running and listening for parameters.  If we were
manually rezzed from the inventory (for editing, etc.), we don't notify
or listen for messages.

@o scripts/orbit_ellipse.lsl
@{
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
@}

The {\tt listen} event handler processes messages from the deployer.
We handle the ``{\tt ypres}'' message, which instructs us to
self-destruct when the user wishes to remove the current model.

@o scripts/orbit_ellipse.lsl
@{
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
@}

The {\tt ORBITING} message is sent in response to our {\tt ORBITAL}
message.  It provides the parameters to configure the orbit ellipse.
It will have already been placed at the correct position and rotation,
so all we need to do here is set the name, size (scale factors), and
colour.

@o scripts/orbit_ellipse.lsl
@{

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
@}

The {\tt VERSION} message requests this script to check its build
number against that of the Deployer and report any discrepancy.

@o scripts/orbit_ellipse.lsl
@{
                    @<Check build number in created objects@>
                    }
                }
            }
        }
    }
@}

\chapter{Script Processor}
\label{ScriptProcessor}

The Fourmilab Script processor is used in many Fourmilab projects.
Here it is used to provide a scripting facility for the
Deployer.

\section{Script processor messages}

The following link message codes are used by client scripts that
interact with the script processor.

@d Script processor messages
@{
    integer LM_SP_INIT = 50;        // Initialise
    integer LM_SP_RESET = 51;       // Reset script
    integer LM_SP_STAT = 52;        // Print status
    integer LM_SP_RUN = 53;         // Add script to queue
    integer LM_SP_GET = 54;         // Request next line from script
    integer LM_SP_INPUT = 55;       // Input line from script
    integer LM_SP_EOF = 56;         // Script input at end of file
    integer LM_SP_READY = 57;       // New script ready
    integer LM_SP_ERROR = 58;       // Requested operation failed
@| LM_SP_INIT LM_SP_RESET LM_SP_STAT LM_SP_RUN LM_SP_GET LM_SP_INPUT
   LM_SP_EOF LM_SP_READY LM_SP_ERROR @}

\section{Parse script interval specification}

Parse a specification representing a time interval.  A simple
integer indicates a time in seconds, while a suffix of ``{\tt m}''
indicates minutes, ``{\tt h}'' hours, and ``{\tt d}'' days.

@d pScriptInterval: Parse script interval specification
@{
    float pScriptInterval(list args, integer n) {
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
@| pScriptInterval @}

\section{Process script command}

The script processor is controlled by ``Script'' commands within the
script.  This function checks for and processes these commands locally.
It returns {\tt TRUE} if the command was processed locally, and {\tt
FALSE} if it should be returned to the client.  These commands may be
used only within scripts.

@d processScriptCommand: Process script command
@{
    integer processScriptCommand(string message) {
        integer echoCmd = TRUE;
        if (llGetSubString(llStringTrim(message, STRING_TRIM_HEAD), 0, 0) == "@@") {
            echoCmd = FALSE;
            message = llGetSubString(llStringTrim(message, STRING_TRIM_HEAD), 1, -1);
        }

        string lmessage = llToLower(llStringTrim(message, STRING_TRIM));
        list args = llParseString2List(lmessage, [" "], [ ]);
        integer argn = llGetListLength(args);

        if ((argn >= 2) &&
            abbrP(llList2String(args, 0), "sc")) {

            string command = llList2String(args, 1);
@| processScriptCommand @}

\subsection{Script loop command}

The ``Script loop [$n$]'' command begins a loop which will execute $n$
times or, if $n$ is omitted, until the script is terminated manually or
the program reset.  Loops may be nested, limited only by available
memory in the LSL script.

@d processScriptCommand: Process script command
@{
            if (abbrP(command, "lo")) {
                integer iters = -1;

                if (argn >= 3) {
                    iters = llList2Integer(args, 2);
                }
                ncLoops = [ iters, ncLine ] + ncLoops;
@}

\subsection{Script end command}

The ``Script end'' command marks the end of a loop begun with the
matching ``Script loop'' command.  If the iteration count has been
reached, control continues to the next line in the script.  Otherwise,
it jumps back to the line after the ``Script loop''.

@d processScriptCommand: Process script command
@{
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
@}

\subsection{Script pause command}

The ``Script pause [{\em when}]'' command suspends execution of the
script until the condition specified by {\em when} occurs.  If a number
is specified, the script pauses for that number of seconds.  If the
argument is ``{\tt touch}'', the script pauses until the object which
contains it is touched, and if ``{\tt region}'' is specified, the
script pauses until the object enters a new region (this is primarily
useful for wearable attachments which wish to do something on region
changes).

@d processScriptCommand: Process script command
@{
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
@}
Naively, you might ask why we don't just use {\tt llSleep()} here
rather than going to all this trouble.  Well, you see, even though each
script is logically its own process, in a dynamic, multi-script
environment, with lots of link messages flying about, scripts must cope
with the fact that the event queue is limited to only 64 items, after
which events are silently discarded. If an event goes dark for a while,
as {\tt llSleep()} would cause it to do, it ceases to receive events
and before long its inbound event queue will overflow, resulting in
lost messages and all kinds of mayhem (usually manifesting as just
going to sleep for no apparent reason).

Note that this happens even if the link messages are not directed to
us, as there is no way to direct a link message to a particular script.

Instead, we set the global variable {\tt pauseExpiry} to the {\tt
llGetTime()} value at which we wish the script to resume and then rely
upon the timer to get things going again when that time arrives.  This
leaves us able to receive (and in all likelihood, ignore) the myriad
messages that may drop in the in-box while the pause is in effect.

@d processScriptCommand: Process script command
@{

                    pauseExpiry = llGetTime() + howlong;
                }
@}

\subsection{Script wait command}

The ``Script wait [{\em n}[unit]] [{\em offset}[unit]]'' command
suspends execution of the script until the next even interval of $n$
units plus {\em offset} units of time occurs.  The unit suffixes are as
defined by the {\tt pScriptInterval()} function: nothing for seconds,
``{\tt m}'' for minutes, ``{\tt h}'' for hours, and ``{\tt d}'' for
days.  Note the difference between the ``pause'' and ``wait'' commands:
``pause'' suspends the script for a specified interval starting at the
present time, while ``wait'' suspends until the next specified wall
clock interval.  You might use ``wait'', for example, to schedule
presentations which occur, for example, at the top of every hour.

@d processScriptCommand: Process script command
@{
            } else if (abbrP(command, "wa")) {
                float interval = 60;        // Default interval 1 minute
                float offset = 0;           // Default offset zero

                if (argn >= 3) {
                    interval = pScriptInterval(args, 2);
                    if (argn >= 4) {
                        offset = pScriptInterval(args, 3);
                    }
                }
@}

Note that we use {\tt llGetUnixTime()} here because we wish to
synchronise to even intervals on the wall clock.  For example, if the
user sets a wait for every 10 minutes, we want to run at the top of the
next even 10 minutes, not 10 minutes from now. If we used {\tt
llGetTime()}, we'd be syncing to whenever the script started keeping
its own time, whatever that may be.  Now, {\tt llGetUnixTime()} doesn't
provide precision better than a second, but the only way around that
would be to use timestamps which, being strings, would probably be so
costly to process we'd lose comparable precision anyway.

@d processScriptCommand: Process script command
@{


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
@}

\section{Process script commands from notecard}

Start reading script commands from the notecard {\tt ncname} on behalf
of user {\tt id}.  Script invocations may be nested as deeply as
LSL script memory permits, and there are no problems running nested
scripts within loops of outer scripts: ``it just works''.

@d processNotecardCommands: Process script commands from notecard
@{
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
@| processNotecardCommands @}

\section{Extract inventory name from command}

Extract inventory item name from a command. This is a horrific kludge
which allows names to be upper and lower case.  It finds the subcommand
in the lower case command then extracts the text that follows, trimming
leading and trailing blanks, from the upper and lower case original
command.

@d inventoryName: Extract inventory name from command
@{
    string inventoryName(string subcmd, string lmessage, string message) {
        //  Find subcommand in Set subcmd ...
        integer dindex = llSubStringIndex(lmessage, subcmd);
        //  Advance past space after subcmd
        dindex += llSubStringIndex(llGetSubString(lmessage, dindex, -1), " ") + 1;
        //  Note that STRING_TRIM elides any leading and trailing spaces
        return llStringTrim(llGetSubString(message, dindex, -1), STRING_TRIM);
    }
@| inventoryName @}

\section{Process script control commands}

To centralise script-related processing, we offload parsing and
processing of the commands which control scripts from the main program,
which simply forwards any command that begins with ``Script'' to us via
the {\tt LM\_CP\_COMMAND} link message.  These commands may appear
within a script or be run directly from local chat.

@d processScriptAuxCommand: Process script control commands
@{
    integer processScriptAuxCommand(key id, list args) {

        whoDat = id;            // Direct chat output to sender of command

        string message = llList2String(args, 0);
        string lmessage = llList2String(args, 1);
        args = llDeleteSubList(args, 0, 1);
        integer argn = llGetListLength(args);       // Number of arguments
        string command = llList2String(args, 0);    // The command
        string sparam = llList2String(args, 1);     // First argument, for convenience

        //  Script                      Script commands

        if (abbrP(command, "sc") && (argn >= 2)) {
@| processScriptAuxCommand @}

The ``Script list'' command lists all scripts in the object's
inventory.  Scripts are notecards whose names must begin with
the prefix ``\verb*+Script: +''.

@d processScriptAuxCommand: Process script control commands
@{
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
@}

The ``Script resume'' command causes a paused script (whether due to a
timed delay, a manual pause, or a pause waiting to change region) to
resume execution.

@d processScriptAuxCommand: Process script control commands
@{
           } else if (abbrP(sparam, "re")) {
                if (ncBusy && ((pauseExpiry > 0) || pauseManual || pauseRegion)) {
                    pauseExpiry = -1;
                    pauseManual = pauseRegion = FALSE;
                    regionChanged = 0;
                    ncQuery = llGetNotecardLine(ncSource, ncLine);
                    ncLine++;
                }
@}

The ``Script run'' command runs the named script.  Scripts may be
nested: you can use the `Script run'' command within a script.
Entering ``Script run'' with no script name terminates all running
scripts.

@d processScriptAuxCommand: Process script control commands
@{
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
@}

\section{Script processor script}

Now put the pieces together and emit the script for the script
processor.

Begin by defining  global variables.

@o scripts/script_processor.lsl
@{
    @<Explanatory header for LSL files@>

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

    @<Command processor messages@>
    @<Script processor messages@>
    @<Auxiliary services messages@>
@}

We use the standard {\tt tawk()} function to communicate with the user,
and define a variant, {\tt ttawk()} which only outputs the message if
{\tt trace} mode is enabled.  Note that {\tt ttawk()} should only be
used for simple messages generated infrequently.  For complex,
high-volume messages you should use:
\begin{verbatim}
   if (trace) { tawk(whatever); }
\end{verbatim}
because that will neither generate the message nor call a function when
{\tt trace} is not set.

@o scripts/script_processor.lsl
@{
    @<tawk: Send a message to the interacting user in chat@>
    ttawk(string msg) {
        if (trace) {
            tawk(msg);
        }
    }

    @<abbrP: Test argument, allowing abbreviation@>
    @<pScriptInterval: Parse script interval specification@>
    @<processScriptCommand: Process script command@>
    @<processNotecardCommands: Process script commands from notecard@>
    @<inventoryName: Extract inventory name from command@>
    @<processScriptAuxCommand: Process script control commands@>
@}

This is the event handler for the script processor.  We have only a
single state, ``{\tt default}''.

@o scripts/script_processor.lsl
@{
   default {

        on_rez(integer start_param) {
            llResetScript();
        }
@}

At state entry, we initialise everything and enter the state of no
scripts running.

@o scripts/script_processor.lsl
@{

        state_entry() {
            owner = llGetOwner();
            ncBusy = FALSE;                 // Mark no notecard being read
            pauseExpiry = -1;               // Mark not paused
            llSetTimerEvent(0);             // Cancel event timer
            ncQueue = [ ];                  // Queue of pending notecards
            ncQline = [ ];                  // Clear queue of return line numbers
            ncLoops = [ ];                  // Clear queue of loops
        }
@}

The script processor is controlled by and interacts with client scripts
via link messages which are processed by the following event handler.

@o scripts/script_processor.lsl
@{
        link_message(integer sender, integer num, string str, key id) {
//ttawk("Script processor link message sender " + (string) sender + "  num " + (string) num + "  str " + str + "  id " + (string) id);
@}

The {\tt LM\_SP\_INIT} message initialises the script processor,
resetting it to the state of no scripts running.  It may be sent at
any time to terminate running scripts.

@o scripts/script_processor.lsl
@{
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
@}

The {\tt LM\_SP\_RESET} message performs a hard restart of this LSL
script, restoring everything to its state at initialisation.  This
shouldn't do anything more than {\tt LM\_SP\_INIT} does, but it's
available if you get really stuck.

@o scripts/script_processor.lsl
@{
            //  LM_SP_RESET (51): Reset script
            } else if (num == LM_SP_RESET) {
                llResetScript();
@}

The {\tt LM\_SP\_STAT} message reports status, including the current
script being run (if any) the stack of nested scripts, loops in
progress, and script memory usage.

@o scripts/script_processor.lsl
@{
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
@}

The {\tt LM\_SP\_RUN} message runs the script whose name is given by
the string argument.  If a script is currently running, it is placed
on the stack and will resume execution when the new script is complete.

@o scripts/script_processor.lsl
@{
            //  LM_SP_RUN (53): Run script
            } else if (num == LM_SP_RUN) {
                if (!ncBusy) {
                    agent = whoDat = id;            // User who started script
                }
                processNotecardCommands(str, id);
@}

{\tt LM\_SP\_GET} returns the next line from the script, sending it
to the requester via the {\tt LM\_SP\_INPUT} message or, if the end of
all scripts is reached, an {\tt LM\_SP\_EOF} message.  No indication
is given when completing a script and resuming execution of an outer
nested script.  LSL notecards are actually random-access, but other
than our looping commands, we do not provide this facility to clients
of the script processor.

@o scripts/script_processor.lsl
@{
            //  LM_SP_GET (54): Get next line from script
            } else if (num == LM_SP_GET) {
                if (ncBusy) {
                    ncQuery = llGetNotecardLine(ncSource, ncLine);
                    ncLine++;
                }
@}

The {\tt LM\_CP\_COMMAND} message is used by the main user interface
script to forward ``Script'' commands to us for processing.  This
saves memory and complexity in the main script and encapsulates all
the script logic in this program.

@o scripts/script_processor.lsl
@{
            //  LM_CP_COMMAND (223): Process auxiliary command
            } else if (num == LM_CP_COMMAND) {
                processScriptAuxCommand(id, llJson2List(str));
@}

The {\tt LM\_AS\_VERSION} message requests this script to check its
build number against that of the Deployer and report any discrepancy.

@o scripts/script_processor.lsl
@{
            @<Check build number in Deployer scripts@>
            }
        }
@}

When we request a line from the notecard in response to a
{\tt LM\_SP\_GET} message, it is delivered via a {\tt dataserver()}
event.

@o scripts/script_processor.lsl
@{

        //  The dataserver event receives lines from the notecard we're reading

        dataserver(key query_id, string data) {
            if (query_id == ncQuery) {
@}

When we request a line after the end of the notecard, we receive an
{\tt EOF} status.  If this is the only script running, report the
end of file to the requester.  Otherwise, end this notecard and
resume reading the outer script which invoked this one at the line
after the ``Script run'' command.

@o scripts/script_processor.lsl
@{
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
@}

When we receive a line from the script, we test whether it is a comment
or blank line and, if so, ignore it and proceed directly to the next
line.  Otherwise, we next test whether it is one of the script commands
which we process internally here and if so, execute it.  If it's
not an internal script command, pass it to the requester via an
{\tt LM\_SP\_INPUT} message.

@o scripts/script_processor.lsl
@{
                    string s = llStringTrim(data, STRING_TRIM);
                    //  Ignore comments and send valid commands to client
                    if ((llStringLength(s) > 0) && (llGetSubString(s, 0, 0) != "#")) {
                        if (processScriptCommand(s)) {
                            if (pauseExpiry > 0) {
@}

We have processed a Script pause command which paused script execution.
Set a timer event to fetch the next line from the script when the pause
is complete.

@o scripts/script_processor.lsl
@{
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
@}

The process of aborting a script due to an error in the script or other
exogenous event is asynchronous to the completion of a pending {\tt
llGetNotecardLine()} request.  That means that it's possible we may get
here, receiving data for a script which has been terminated while the
request was pending.  If that's the case {\tt ncBusy} will be {\tt
FALSE} and we don't want to request the next line, which will fail
because {\tt ncSource} will have been cleared.

@o scripts/script_processor.lsl
@{
                        if (ncBusy) {
                            //  It was a comment or blank line; fetch the next
                            ncQuery = llGetNotecardLine(ncSource, ncLine);
                            ncLine++;
                        }
                    }
                }
            }
        }
@}

The timer is used to resume processing of a script once the interval
specified by a ``Script pause'' command has expired.  By its nature,
only one pause can be in effect at a time, so we don't need any tangled
logic here.

@o scripts/script_processor.lsl
@{
        timer() {
            pauseExpiry = -1;               // No pause in effect
            llSetTimerEvent(0);             // Cancel event timer
            ncQuery = llGetNotecardLine(ncSource, ncLine);
            ncLine++;
        }
@}

If we're in a manual pause, resume upon an avatar's touching the
object in which we're running.

@o scripts/script_processor.lsl
@{
        touch_start(integer n) {
            if (pauseManual) {
                pauseManual = FALSE;
                ncQuery = llGetNotecardLine(ncSource, ncLine);
                ncLine++;
            }
        }
@}

If we're in a region pause, resume when the region changes.  This
is mostly of use in objects worn by avatars as attachments, allowing
scripts to be activated when the avatar arrives in a new region.
One gimmick is that if a region change occurs while a script is
running and not in a ``Script pause region'' wait, a flag is set so
the next such command will not wait.

@o scripts/script_processor.lsl
@{
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
@}

\chapter{Positional Astronomy}

These functions implement basic facilities required by positional
astronomy.  Some (for example, interconversion of equatorial and
ecliptic co-ordinates) are specific to the Earth and solar system,
while others are applicable to any system governed by Newtonian
gravitation.

\section{Equatorial and ecliptic co-ordinates}

Earth-based astronomers frequently specify celestial positions in
equatorial co-ordinates: right ascension ($\alpha$) and declination
($\delta$).  When performing calculations in the reference frame
of the Sun, ecliptical co-ordinates, ecliptical longitude ($\lambda$)
and latitude ($\beta$) are more convenient.  These co-ordinate systems
intersect along a vector to the March equinox, with the angle
between the ecliptic and equatorial planes referred to as the
``obliquity of the ecliptic'' ($\epsilon$).

\subsection{Obliquity of the ecliptic}

Calculate the obliquity of the ecliptic for a given Julian date.  This
uses Laskar's tenth-degree polynomial fit (J. Laskar, {\em Astronomy
and Astrophysics}, Vol\@@. 157, page 68 [1986]) which is accurate to
within 0.01 arc second between {\sc a.d\@@.} 1000 and {\sc a.d\@@.}
3000, and within a few seconds of arc for $\pm 10000$ years around {\sc
a.d\@@.} 2000.  If we're outside the range in which this fit is valid
(deep time) we simply return the J2000 value of the obliquity, which
happens to be almost precisely the mean.

The terms in the list {\tt oterms} were originally specified in arc
seconds.  In the interest of efficiency, we convert them to degrees by
dividing by 3600 and round to nine significant digits, which is the
maximum precision of the single-precision floats used by LSL.

@d obliqeq: Obliquity of the ecliptic
@{
    float obliqeq(integer jd, float jdf) {

        list oterms = [
            -1.30025833,
            -0.000430555556,
             0.555347222,
            -0.0142722222,
            -0.0693527778,
            -0.0108472222,
             0.00197777778,
             0.00774166667,
             0.00160833333,
             0.000680555556
        ];

        //  Again, we evaluate a number specified as 23°26'21".448 as degrees
        float eps = 23.4392911;
        float u;
        float v;
        integer i;

        v = u = ((jd - @<J2000@>) / (@<JulianCentury@> * 100)) + (jdf / (@<JulianCentury@> * 100));

        if (llFabs(u) < 1.0) {
            for (i = 0; i < 10; i++) {
                eps += llList2Float(oterms, i) * v;
                v *= u;
            }
        }
        return eps;
    }
@| obliqeq @}

\subsection{Equatorial to ecliptic co-ordinate conversion}

Transform equatorial (right ascension and declination) to ecliptic
(heliocentric latitude and longitude) co-ordinates. Note that the
inputs and outputs of this function are in radians.

@d eqtoecliptic: Equatorial to ecliptic co-ordinate conversion
@{
    list eqtoecliptic(integer jd, float jdf, float alpha, float delta) {
        // Obliquity of the ecliptic
        float eps = obliqeq(jd, jdf) * DEG_TO_RAD;

        float lambda = llAtan2((llSin(alpha) * llCos(eps)) +
                             (llTan(delta) * llSin(eps)),
                             llCos(alpha));
        float beta = llAsin((llSin(delta) * llCos(eps)) -
                            (llCos(delta) * llSin(eps) * llSin(alpha)));

        return [ lambda, beta ];
    }
@| eqtoecliptic @}

\section{Kepler's equation}

Kepler's equation is central in computing the trajectories of objects
under the influence of gravitation.  Notwithstanding the somewhat wonky
terminology, such as “mean anomaly” ($M$) and “eccentric anomaly”
($E$), what we're basically doing is computing the position of a body
in an elliptical orbit at a given time.  Formally, the equation is
written as:
\[
M = E - e \sin E
\]
where $e$ is the eccentricity of the ellipse.  From the eccentric
anomaly $E$, the position of the body along the ellipse is given
by:
\begin{eqnarray*}
    x & = & a(\cos E - e) \\
    y & = & b \sin E
\end{eqnarray*}
where $a$ is the semi-major axis and $b$ is the semi-minor axis
of the ellipse.  (Note that \( b = a \sqrt{1 - e^2} \).)

Since $\sin x$ is a transcendental function, there is no closed
form solution for the inverse equation, solving for $E$.  Consequently,
a variety of numerical methods have been developed over the centuries.
We use a variety here, based upon the eccentricity and the constraints
of single precision computation.

Analogues to Kepler's equation exist for parabolic and hyperbolic
trajectories: for hyperbolic motion, the equivalent is
\( M = e \sinh H - H \) where $H$ is the hyperbolic eccentric anomaly.

\subsection{gKepler: General motion in gravitational field}

This Kepler equation solver works for trajectories around a
body whose Gaussian gravitational constant ($k$) is given by the
argument {\tt GaussK}.  The value of $k$ is computed from
the standard gravitational parameter:
\[
    \mu = G M
\]
where $G$ is the Newtonian gravitational constant and $M$ is the
mass of the central body around which the object is moving (which
is assumed to be much more massive, permitting two-body approximations
to be used).  We may then compute $k$ as:
\[
    k = \sqrt{(\mu d^3) / t^2}
\]
where $d$ is the scale factor between the distance units we wish
to use (astronomical units, kilometres, parsecs, etc.) and the units
in which the gravitational constant is specified, and $t$ is the
similar scale factor between the time unit we prefer (day, year,
century, etc.) and that of the gravitational constant.  The result
will be a value in radians per time $t$ for an orbit at $d=1$.

Arguments to the solver are the eccentricity of the orbit $e$, the time
since periapse $t$, and the distance at periapse $q$, specified in the
units used to compute $k$.  The result is returned as a list containing
the true anomaly $v$ in radians and the distance $r$ (sometimes called
the radius vector) from the central mass to the orbiting body in units
of $d$.

@d gKepler: General motion in gravitational field
@{
    list gKepler(float e, float t, float q, float GaussK) {
//tawk("gKepler e " + (string) e + "  t " + (string) t + "  q " + (string) q);
        float f;
        float x;
        float d;
        float m1;
        integer i;

        float v;
        float r;

        if (e > 1.0) {
            @<Solve Kepler's equation for hyperbolic motion@>
        } else {
            @<Solve Kepler's equation for elliptical or parabolic motion@>
        }
        return [ v, r ];
    }
@| gKepler @}

\subsubsection{Solve Kepler's equation for hyperbolic motion}

@d Solve Kepler's equation for hyperbolic motion
@{
    float a1 = llFabs(q / (1 - e));
    float m = (GaussK * t) / (a1 * llSqrt(a1));

    float eps = 1e-6;       // Convergence criterion
    float H = m;            // Initial estimate

    //  Initialise iteration
    f = (e * flSinh(H)) - H - m;
    float f_prime = (e * flCosh(H)) - 1;
    float ratio = f / f_prime;

    //  Iterate until we converge
    while (llFabs(ratio) > eps) {
        f = (e * flSinh(H)) - H - m;
        f_prime = (e * flCosh(H)) - 1;
        ratio = f / f_prime;

        if (llFabs(ratio) > eps) {
            H = H - ratio;
        }
    }

    /*  Compute true anomaly v from hyperbolic anomaly H.  Note
        that in the outer expression, we use the circular
        arc tangent function: this is not an error--think about
        it!  */
    v = 2 * llAtan2(llSqrt((e + 1) / (e - 1)) * flTanh(H / 2), 1);
    //  Finally, compute radius vector to central body
    r = (-a1) * (1 - (e * flCosh(H)));
@}

\subsubsection{Solve Kepler's equation for elliptical or parabolic motion}

For elliptical and parabolic motion we use the solution by binary
search by Roger W. Sinnott, {\em Sky and Telescope}, Vol\@@. 70, page
159 (August 1985).  This is presented as the ``Third Method'' in
chapter 30 of Meeus, {\em Astronomical Algorithms}, 2nd ed. This works
for all eccentricities between 0 and 1.

@d Solve Kepler's equation for elliptical or parabolic motion
@{
    float m;
    float a1;
    float ev;

    a1 = q / (1 - e);
    m = GaussK * t * llPow(a1, -1.5);

    f = sgn(m);
    m = llFabs(m) / TWO_PI;
    m = (m - (llFloor(m))) * TWO_PI * f;
    if (m < 0) {
        m += TWO_PI;
    }
    f = 1;
    if (m > PI) {
        f = -1;
    }
    if (m > PI) {
        m = TWO_PI - m;
    }
    x = PI_BY_TWO;
    d = PI / 4;
    for (i = 0; i < 53; i++) {
        m1 = x - e * llSin(x);
        x = x + sgn(m - m1) * d;
        d /= 2;
    }
    x *= f;
    ev = llSqrt((1 + e) / (1 - e));
    r = a1 * (1 - e * llCos(x));
    x = 2 * llAtan2(ev * llSin(x / 2), llCos(x / 2));

    if (x < 0) {
        x += TWO_PI;
    }
    v = x;
@}

\section{Orbital position computation}

Given the elements defining an orbit (or trajectory, if parabolic or
hyperbolic) and a time specified by Julian day and fraction, we can
apply Kepler's equation to determine the rectangular co-ordinates of
the body with respect to the central mass.

\subsection{computeOrbit: Compute position of body in orbit}
\label{computeOrbit}

Given the orbital elements in the list {\tt elements}, the time
as a Julian day and fraction in {\tt jdl}, the Gaussian gravitational
constant for the central body in {\tt GaussK}, and the obliquity of
the co-ordinate system in which the elements are specified {\tt e}
(which will be the obliquity of the ecliptic in radians when computing solar
system orbits around the Sun and zero otherwise), compute the
rectangular co-ordinates of the body in its orbit.  Note that
the results is in whatever units were used to specify the orbital
elements and Gaussian gravitational constant.

@d computeOrbit: Compute position of body in orbit
@{
    vector computeOrbit(list elements, list jdl, float GaussK, float e) {
//        float e = obliqeq(llList2Integer(jdl, 0), llList2Float(jdl, 1)) * DEG_TO_RAD;
//        float e = 0;
        float w = llList2Float(elements, 6) * DEG_TO_RAD;
        float n = llList2Float(elements, 7) * DEG_TO_RAD;
        float i = llList2Float(elements, 5) * DEG_TO_RAD;
//tawk("ComputeOrbit  e " + (string) (RAD_TO_DEG * e) + "  w " + (string) (RAD_TO_DEG * w) + "  n " + (string) (RAD_TO_DEG * n) + "  i " + (string) (RAD_TO_DEG * i));

        float w1 = llSin(w);
        float w2 = llCos(w);
        float n1 = llSin(n);
        float n2 = llCos(n);
        float i1 = llSin(i);
        float i2 = llCos(i);
        float e1 = llSin(e);
        float e2 = llCos(e);

        float p7 = (w2 * n2) - (w1 * n1 * i2);
        float p8 = (((w2 * n1) + (w1 * n2 * i2)) * e2) - (w1 * i1 * e1);
        float p9 = (((w2 * n1) + (w1 * n2 * i2)) * e1) + (w1 * i1 * e2);
        float q7 = (-w1 * n2) - (w2 * n1 * i2);
        float q8 = (((-w1 * n1) + (w2 * n2 * i2)) * e2) - (w2 * i1 * e1);
        float q9 = (((-w1 * n1) + (w2 * n2 * i2)) * e1) + (w2 * i1 * e2);

        integer dti = llList2Integer(jdl, 0) - llList2Integer(elements, 11);
        float dtf = dti + (llList2Float(jdl, 1) - llList2Float(elements, 12));
        list k = gKepler(llList2Float(elements, 4),
                         dtf,
                         llList2Float(elements, 13), GaussK);
        if (k != [ ]) {
            float v = llList2Float(k, 0);
            float r = llList2Float(k, 1);
            float x1 = r * llCos(v);
            float y1 = r * llSin(v);

            return <  (p7 * x1) + (q7 * y1),
                      (p8 * x1) + (q8 * y1),
                      (p9 * x1) + (q9 * y1) >;
        }
        //  Kepler's equation solver failed
tawk(llGetScriptName() + ": Kepler solver failed.");
        return ZERO_VECTOR;
    }
@| computeOrbit @}

\section{Parse orbital elements}
\label{parseOrbitalElements}

This function parses the orbital element arguments, which may be
specified in any order and a variety of forms (for example, by
mean anomaly or perihelion date).  The other orbital elements are
computed from those given.  This is a general function which may
be used to specify Keplerian orbits or hyperbolic and parabolic
trajectories around arbitrary bodies, whose mass, in units of
solar masses, is given by the {\em massCtr} argument.

@d parseOrbitalElements: Parse orbital elements
@{
    list parseOrbitalElements(string message, float massCtr) {
        list args = llParseString2List(message, [ " " ], []);   // Command and arguments
        args = fixQuotes(args);
        integer argn = llGetListLength(args);       // Number of arguments

        string m_name = llList2String(args, 1);

        //  Re-parse specification for case-insensitive comparisons
        args = llParseString2List(llToLower(message), [ " " ], []);
        args = fixQuotes(args);
        argn = llGetListLength(args);               // Number of arguments
        integer i;
@| parseOrbitalElements @}

We begin by initialising the orbital element variables.  We use the
IEEE 754 floating-point ``not a number'' (NaN) to indicate an element
which has not been specified.  Unspecified elements computable from
those given will be synthesised later.

@d parseOrbitalElements: Parse orbital elements
@{
        float NaN = (float) "nan";
        list m_Epoch = [ ];         // Epoch (JD)
        float m_a = NaN;            // Semi-major axis, AU
        float m_e = NaN;            // Eccentricity
        float m_i = NaN;            // Inclination, degrees
        float m_peri = NaN;         // Argument of periapse, degrees
        float m_node = NaN;         // Longitude of ascending node, degrees
        float m_M = NaN;            // Mean anomaly, degreees
        float m_H = NaN;            // Magnitude
        float m_G = NaN;            // Magnitude slope

        float m_q = NaN;            // Periapse distance, AU
        list m_Tp = [ ];            // Time of periapse, JD
        float m_n = NaN;            // Mean motion, degrees/day
        float m_P = NaN;            // Orbital period, days
        float m_Q = NaN;            // Apoapse distance, AU
@}

Walk through the list of arguments and collect the elements specified,
which may be provided in any order.

@d parseOrbitalElements: Parse orbital elements
@{

        for (i = 2; i < argn; i += 2) {
            string var = llList2String(args, i);
            float val = NaN;
            if ((i + 1) < argn) {
                val = llList2Float(args, i + 1);
            }
            if (!spec(val)) {
                tawk("Bad value for var " + var +
                    " args[" + (string) (i + 1) + "]: " + (string) val +
                    " from " + llList2String(args, i + 1));
                return [ ];
            }

            if (abbrP(var, "a")) {          // a    Semi-major axis
                m_a = val;
            } else if (abbrP(var, "e")) {   // e    Eccentricity
                m_e = val;
            } else if (abbrP(var, "i")) {   // i    Inclination
                m_i = val;
            } else if (abbrP(var, "w")) {   // w    Argument of periapse
                m_peri = val;
            } else if (abbrP(var, "n")) {   // n    Longitude of ascending node
                m_node = val;
            } else if (abbrP(var, "m")) {   // M    Mean anomaly
                m_M = val;
            } else if (abbrP(var, "h")) {   // H    Magnitude
                m_H = val;
            } else if (abbrP(var, "g")) {   // G    Magnitude slope
                m_G = val;
            } else if (abbrP(var, "t")) {   // T    Epoch
                if (val != NaN) {
                    m_Epoch = parseJD(llList2String(args, i + 1));
                }
            } else if (abbrP(var, "p")) {   // P    Time of periapse
                if (val != NaN) {
                    m_Tp = parseJD(llList2String(args, i + 1));
                }
            } else if (abbrP(var, "q")) {   // q    Periapse distance
                m_q = val;
            } else {
                tawk("Invalid orbital element parameter \"" + var + \"\" (arg " +
                    (string) i + ")");
                return [ ];
            }
        }
@}

We've collected the element specifications.  Check if required elements
are missing and reject if so.

@d parseOrbitalElements: Parse orbital elements
@{
        if ((!spec(m_e)) || (!spec(m_i)) || (!spec(m_peri)) ||
            (!spec(m_node))) {
            tawk(m_name + ": required orbital element (e, i, w, node) missing.");
            return [ ];
        }
@}

If periapse date unspecified, compute it from the epoch, semi-major
axis, and mean anomaly, if given.

@d parseOrbitalElements: Parse orbital elements
@{
        if ((m_Tp == [ ]) && (m_Epoch != [ ]) && spec(m_a) && spec(m_M)) {
            float peridelta = llSqrt(m_a * m_a * m_a) * m_M * (365.2422 / 360);
            integer pdi = llFloor(peridelta);
            peridelta -= pdi;
            integer pjd = llList2Integer(m_Epoch, 0) - pdi;
            float pjdf = llList2Float(m_Epoch, 1) - peridelta;
            while (pjdf < 0) {
                pjdf += 1;
                pjd--;
            }
            m_Tp = [ pjd, pjdf ];
        }
@}

If periapse distance is unspecified, compute from semi-major axis and
eccentricity, if specified.

@d parseOrbitalElements: Parse orbital elements
@{
        if ((!spec(m_q)) && spec(m_a) && spec(m_e)) {
            m_q = m_a - (m_a * m_e);
        }
@}

If the semi-major axis is not specified, and the orbit is non-parabolic
(${\tt m\_e} \neq 1$), and the perihelion distance is known, compute
it.  We follow the convention of assigning a negative semi-major axis
to objects in hyperbolic orbits, which allows computing a mean motion
which is useful in deriving a mean anomaly from the perihelion date.

@d parseOrbitalElements: Parse orbital elements
@{
        if ((!spec(m_a)) && (m_e != 1) && spec(m_q)) {
            m_a = m_q / (1 - m_e);
        }
@}

Compute mean motion.  We compute motion in the gravitational field of
the central mass according to Newton's gravitational law.  The apoapse
distance is computed from the semi-major axis and eccentricity and is,
of course, only defined for elliptical orbits.  Mean motion is not
defined for parabolic trajectories, but for hyperbolic trajectories
we use the JPL definition yielding a negative mean motion figure.

When computing trajectories within the Solar System (${\rm massCtr} =
1$), we use the standard gravitational parameter for the Sun, which is
known to much greater precision than either of its two factors: the
Newtonian gravitational constant and the mass of the Sun.  For
trajectories in other systems, such as the Galactic Centre, we compute
it from first principles using the mass and gravitational constant
expressed in our units.

@d parseOrbitalElements: Parse orbital elements
@{
        if (m_e != 1) {
            float GM;

            if (massCtr == 1) {
                //  Solar system
                GM = 0.0172020989484;
            } else {
                //  Other central mass
                GM = llSqrt(massCtr * GRAVCON);
            }
            if (m_e < 1) {
                //  Elliptical orbit
                m_n = (GM / (m_a * llSqrt(m_a))) * RAD_TO_DEG;
//tawk("GRAVCON " + (string) GRAVCON + " massCtr " + (string) massCtr + " GM " + (string) GM + " m_n " + (string) m_n);
                m_P = 360 / m_n;
                m_Q = (1 + m_e) * m_a;
            } else {
                //  Hyperbolic trajectory
                //  This is how JPL defines it for hyperbolic objects
                m_n = (GM / ((-m_a) * llSqrt(-m_a))) * RAD_TO_DEG;
            }
        }
@}

If mean anomaly was not specified, and we know the mean motion and date
of perihelion, compute it.

@d parseOrbitalElements: Parse orbital elements
@{
        if ((!spec(m_M)) && (m_Tp != [ ]) && spec(m_n)) {
            float deltat = (llList2Integer(m_Epoch, 0) - llList2Integer(m_Tp, 0)) +
                           (llList2Float(m_Epoch, 1) - llList2Float(m_Tp, 1));
            m_M = fixangle(m_n * deltat);
        }
@}

If Epoch is unspecified, set to zero.

@d parseOrbitalElements: Parse orbital elements
@{
        if (m_Epoch == [ ]) {
            m_Epoch = [ 0, 0.0 ];
        }
@}

Return the source orbital elements in the form in which they will be
stored in the {\tt s\_sources} list.

@d parseOrbitalElements: Parse orbital elements
@{
        return [ m_name ] +             // 0    Name
                m_Epoch +               // 1,2  epoch [ jd, jdf ]
                [ m_a,                  // 3    a (semi-major axis)
                  m_e,                  // 4    e (eccentricity)
                  m_i,                  // 5    i (inclination)
                  m_peri,               // 6    ῶ (argument of periapse)
                  m_node,               // 7    Ω (longitude of ascending node)
                  m_M,                  // 8    M (mean anomaly)
                  m_H,                  // 9    H (magnitude)
                  m_G ] +               // 10   G (magnitude slope)
                  m_Tp +                // 11,12 Tp (time of perhelion)
                [ m_q ,                 // 13   q (periapse distance)
                  m_n,                  // 14   n (mean motion)
                  m_P,                  // 15   P (orbital period)
                  m_Q                   // 16   Q (apoapse distance)
                ];
    }
@}

\section{Dump orbital elements}

For debugging, dump the orbital elements of a body to local chat.

@d dumpOrbitalElements: Dump orbital elements
@{
    dumpOrbitalElements(list e) {
        tawk(llList2String(e, 0) + "\n" +
            "  Epoch " + (string) llList2Integer(e, 1) + " + " +
                         (string) llList2Float(e, 2) + "\n" +
            "  a " + (string) llList2Float(e, 3) + "\n" +
            "  e " + (string) llList2Float(e, 4) + "\n" +
            "  i " + (string) llList2Float(e, 5) + "\n" +
            "  ῶ " + (string) llList2Float(e, 6) + "\n" +
            "  Ω " + (string) llList2Float(e, 7) + "\n" +
            "  M " + (string) llList2Float(e, 8) + "\n" +
            "  H " + (string) llList2Float(e, 9) + "\n" +
            "  G " + (string) llList2Float(e, 10) + "\n" +
            "  Tp " + (string) llList2Integer(e, 11) + " + " +
                      (string) llList2Float(e, 12) + "\n" +
            "  q " + (string) llList2Float(e, 13) + "\n" +
            "  n " + (string) llList2Float(e, 14) + "\n" +
            "  P " + (string) llList2Float(e, 15) + "\n" +
            "  Q " + (string) llList2Float(e, 16)
        );
    }
@| dumpOrbitalElements @}

\chapter{Deployer}

The Deployer is the main user interface component of Fourmilab Orbits.
It listens for commands on local chat, processes many commands itself,
and routes other commands to the scripts that implement them with the
{\tt LM\_CP\_COMMAND} link message.

\section{Link message codes}

Communication among scripts within the Deployer is via link messages.
Each message has a code which identifies its functions.  Scripts
ignore messages they do not process.

\subsection{Command processor messages}

The following link messages are used to communicate with auxiliary
command processors in other scripts.

@d Command processor messages
@{
    integer LM_CP_COMMAND = 223;        // Process command
    integer LM_CP_RESUME = 225;         // Resume script after command
    integer LM_CP_REMOVE = 226;         // Remove simulation objects
@| LM_CP_COMMAND LM_CP_RESUME LM_CP_REMOVE @}

\subsection{Auxiliary services messages}

These messages are used to request services implemented in other
scripts or communicate information such as settings to them.

@d Auxiliary services messages
@{
    integer LM_AS_LEGEND = 541;         // Update floating text legend
    integer LM_AS_SETTINGS = 542;       // Update settings
    integer LM_AS_VERSION = 543;        // Check version consistency
@| LM_AS_LEGEND LM_AS_SETTINGS LM_AS_VERSION @}

\section{Check access}

Check if the user who submitted a command via chat has permission to
control the Deployer based upon the setting of {\tt restrictAccess},
which can limit access to its owner, members of the owner's group, or
open to the general public.

@d checkAccess: Check user permission to send commands
@{
    integer checkAccess(key id) {
        return (restrictAccess == 0) ||
               ((restrictAccess == 1) && llSameGroup(id)) ||
               (id == llGetOwner());
    }
@| checkAccess @}

\section{Resume script after command completion}

Commands which take a long time to execute suspend execution of a
script until they complete.  A command which suspended a script should
call this function to resume script execution.  Commands implemented in
other scripts send a {\tt LM\_CP\_RESUME} link message to invoke this
function.  No harm is done if this function is called when no script is
running or suspended.

@d scriptResume: Resume script after command completion
@{
    scriptResume() {
        if (scriptActive) {
            if (scriptSuspend) {
                scriptSuspend = FALSE;
                llMessageLinked(LINK_THIS, LM_SP_GET, "", NULL_KEY);
                if (trace) {
                    tawk("Script resumed.");
                }
            }
        }
    }
@| scriptResume @}

\section{Start or stop the simulation}

Commands which take a long time to execute suspend execution of a
script until they complete.  A command which suspended a script should
call this function to resume script execution.  Commands implemented in
other scripts send a {\tt LM\_CP\_RESUME} link message to invoke this
function.  No harm is done if this function is called when no script is
running or suspended.

@d setRunDeployer: Start or stop the simulation
@{
    setRunDeployer(integer run) {
        if (run != runmode) {
            runmode = run;
            if (runmode) {
                ev_updating = FALSE;
                llSetTimerEvent(tickTime);
                if (hidden == 2) {
                    llSetAlpha(0, ALL_SIDES);
                }
            } else {
                llSetTimerEvent(0);
                if (hidden == 2) {
                    llSetAlpha(1, ALL_SIDES);
                }
            }
        }
    }
@| setRunDeployer @}

\section{Parse simulation interval}
\label{parseSimInterval}

Parse an interval specification. By default, an interval is in years,
but may be specified in other units via the following suffixes, which
are case-sensitive.

\hspace{4em}\vbox{
\begin{description}
\dense
    \item[h]       Hour
    \item[d]       Day
    \item[w]       Week ($1/52$ year)
    \item[m]       Month ($1/12$ year)
    \item[y]       Year (default)
    \item[D]       Decade
    \item[C]       Century
\end{description}
}

@d parseSimInterval: Parse simulation interval
@{
    float parseSimInterval(string intv) {
        string unit = llGetSubString(intv, -1, -1);

        if (llSubStringIndex("hdwmDC", unit) >= 0) {
            intv = llGetSubString(intv, 0, -2);
        } else {
            unit = "y";
        }

        float interval = (float) intv;

        //  Note that years are implicit
        if (unit == "h") {
            interval /= 365 * 24;
        } else if (unit == "d") {
            interval /= 365;
        } else if (unit == "w") {
            interval /= 52;
        } else if (unit == "m") {
            interval /= 12;
        } else if (unit == "D") {
            interval *= 10;
        } else if (unit == "C") {
            interval *= 100;
        }

        return interval;
    }
@| parseSimInterval @}

\section{Send settings}

When the user or a script changes settings, send them to other scripts
and objects we have created, both as a {\tt LM\_AS\_SETTINGS} link
message and a region message on {\tt massChannel}.  Settings may be
sent either to a specific object or broadcast to all objects we've
created.

@d sendSettings: Send settings to objects
@{
    sendSettings(key id, integer mass) {
        string msg = llList2Json(JSON_ARRAY, [
                            "SETTINGS",         // 0
                            mass,               // 1
                            paths,              // 2
                            trace,              // 3
                            fuis(s_kaboom),     // 4
                            fuis(s_auscale),    // 5
                            fuis(s_radscale),   // 6
                            s_trails,           // 7
                            fuis(s_pwidth),     // 8
                            fuis(s_mindist),    // 9
                            fuis(s_deltat),     // 10
                            s_eclipshown,       // 11
                            fuis(s_eclipsize),  // 12
                            s_realtime,         // 13
                            fuis(s_realstep),   // 14
                            fuis(s_simRate),    // 15
                            fuis(s_stepRate),   // 16
                            fuis(s_zoffset),    // 17
                            s_legend ] +        // 18
                            simEpoch +          // 19,20
                            [ s_labels,         // 21
                            s_satShow ]         // 22
                      );
        if (mass == 0) {
            llRegionSay(massChannel, msg);
        } else {
            llRegionSayTo(id, massChannel, msg);
        }
        //  Inform other scripts in this object of new settings
        llMessageLinked(LINK_THIS, LM_AS_SETTINGS, msg, whoDat);
    }
@| sendSettings @}

\section{Update Deployer legend}

Due to limitations of script memory, the legend is actually formatted
and updated by code in the Minor Planets script which responds to the
{\tt LM\_AS\_LEGEND} message.

@d updateLegendDeployer: Update legend above deployer
@{
    updateLegendDeployer() {
        if (s_legend) {
            llMessageLinked(LINK_THIS, LM_AS_LEGEND,
                llList2Json(JSON_ARRAY, [
                    planetsPresent == 0,                // 0  Numerical integration ?
                    simTime,                            // 1    Integration years
                    stepNumber,                         // 2    Step number
                                                        //    Planetary theory ?
                    (planetsPresent & (1 << 10) != 0),  // 3    Tracking minor planet ?
                    llList2String(solarSystem, 10) ] +  // 4    Name of minor planet, if any
                    simEpoch +                          // 5,6  Simulation epoch
                                                        //    Galactic centre sources ?
                    [ gc_sources ]                      // 7    Number of sources
                ), whoDat);
        }
    }
@| updateLegendDeployer @}

\section{Update ephemeris for selected bodies}

Update ephemeris for selected bodies.  This simply initiates the update
process, which is performed asynchronously by the individual ephemeris
calculation scripts, which return their results via {\tt
LM\_EP\_RESULT} messages.  When all results have arrived, the message
handler will initiate the action prescribed by {\tt ephTask}.

@d updateEphemeris: Update ephemeris for selected bodies
@{
    list ephBodies;                 // List of ephemeris results
    integer ephRequests;            // Ephemeris bodies requested
    integer ephReplies;             // Ephemeris bodies who have replied
    string ephTask;                 // Task to run when ephemeris received
    integer ephHandle = 192521;     // Handle for ephemeris requests

float ephCalcStart;
    updateEphemeris(integer bodies, integer jd, float jdf) {
ephCalcStart = llGetTime();
        ephRequests = bodies;
        ephReplies = 0;
        ephBodies = [ ];
        integer i;
        for (i = 0; i < 10; i++) {
            ephBodies += [ 0, 0, 0 ];
        }
        llMessageLinked(LINK_THIS, LM_EP_CALC,
            llList2CSV([ bodies, jd, jdf, ephHandle ]), whoDat);
    }
@| updateEphemeris @}

\section{Update planets}

Update planets to the current simulated time, {\tt simEpoch}.

@d updatePlanets: Update planets
@{
    updatePlanets() {
        ephTask = "update";
        integer trackedp = planetsPresent & (1 << 10);
        updateEphemeris(((1 << 10) - 2) | trackedp,
            llList2Integer(simEpoch, 0), llList2Float(simEpoch, 1));
    }
@| updatePlanets @}

\section{Process command}

This is the main command processor for the application.  Commands
submitted directly from local chat or read from a script are processed
here, either locally or forwarded to other scripts for execution.

@d processDeployerCommand: Process command
@{
    integer processDeployerCommand(key id, string message, integer fromScript) {
        if (!checkAccess(id)) {
            llRegionSayTo(id, PUBLIC_CHANNEL,
                "You do not have permission to control this object.");
            return FALSE;
        }

        whoDat = id;            // Direct chat output to sender of command

        /*  If echo is enabled, echo command to sender unless
            prefixed with "@@".  The command is prefixed with ">>"
            if entered from chat or "++" if from a script.  */

        integer echoCmd = TRUE;
        if (llGetSubString(llStringTrim(message, STRING_TRIM_HEAD), 0, 0) == "@@") {
            echoCmd = FALSE;
            message = llGetSubString(llStringTrim(message, STRING_TRIM_HEAD), 1, -1);
        }
        if (echo && echoCmd) {
            string prefix = ">> ";
            if (fromScript) {
                prefix = "++ ";
            }
            tawk(prefix + message);                 // Echo command to sender
        }

        string lmessage = llToLower(llStringTrim(message, STRING_TRIM));
        list args = llParseString2List(lmessage, [" "], []);    // Command and arguments
        integer argn = llGetListLength(args);       // Number of arguments
        string command = llList2String(args, 0);    // The command
        string sparam = llList2String(args, 1);     // First argument, for convenience
@| processDeployerCommand @}

\subsection{Access {\em who}}

The ``Access'' command sets permission to send commands to one of
``{\tt owner}'', ``{\tt group}'', or ``{\tt public}''.

@d processDeployerCommand: Process command
@{
        if (abbrP(command, "ac")) {
            string who = sparam;

            if (abbrP(who, "p")) {          // Public
                restrictAccess = 0;
            } else if (abbrP(who, "g")) {   // Group
                restrictAccess = 1;
            } else if (abbrP(who, "o")) {   // Owner
                restrictAccess = 2;
            } else {
                tawk("Unknown access restriction \"" + who +
                    "\".  Valid: public, group, owner.\n");
                return FALSE;
            }
@}

\subsection{Boot}
\label{BootCommand}

Reset this and all other scripts to their initial settings and delete
all objects created by the simulation.

@d processDeployerCommand: Process command
@{
        } else if (abbrP(command, "bo")) {
            llRegionSay(massChannel, llList2Json(JSON_ARRAY, [ ypres ]));
            //  Reset the script processor
            llMessageLinked(LINK_THIS, LM_SP_RESET, "", whoDat);
            llResetOtherScript("Minor Planets");
            llResetOtherScript("Numerical Integration");
            llResetOtherScript("Orbits");
            llResetOtherScript("Galactic Centre");
            llResetOtherScript("Galactic Patrol");
//  MAYBE SEND A LM_CP_BOOT TO MASS RESET EPHEMERIS SCRIPTS ?
            llResetScript();
@}

\subsection{Channel $n$}

Change command channel.  Note that the channel change is lost on a
script reset.

@d processDeployerCommand: Process command
@{
        } else if (abbrP(command, "ch")) {
            integer newch = (integer) sparam;
            if ((newch < 2)) {
                tawk("Invalid channel " + (string) newch + ".");
                return FALSE;
            } else {
                llListenRemove(commandH);
                commandChannel = newch;
                commandH = llListen(commandChannel, "", NULL_KEY, "");
                tawk("Listening on /" + (string) commandChannel);
            }
@}

\subsection{Echo}

The text on the command is echoed to local chat.  This is often used
in scripts to inform the user what is going on.

@d processDeployerCommand: Process command
@{
        } else if (abbrP(command, "ec")) {
            string msg = inventoryName("ec", lmessage, message);
            if (msg == "") {
                msg = " ";
            }
            tawk(msg);
@}

\subsection{Epoch {\em date\_time}}

Set the time of the simulation.  This makes sense only for the Solar
System and Galactic Centre models.  You can specify the epoch either as
``{\tt now}'' for the current date and time, as a date and time in the
Gregorian calendar and Universal Time with ``{\tt
yyyy-mm-dd~hh:mm:ss}'', or as a Julian day number and fraction with
``{\tt jjjjjjjjjj.ffff}''.

@d processDeployerCommand: Process command
@{
        } else if (abbrP(command, "ep")) {
            integer goof = FALSE;
            if (argn >= 2) {
                string td = sparam;
                if (abbrP(td, "no")) {
                    simEpoch = jdstamp(llGetTimestamp());
                } else if (llSubStringIndex(td, "-") >= 0) {
                    list ymd = llParseString2List(td, ["-"], []);
                    integer yyyy;
                    integer mm;
                    integer dd;
                    integer HH = 0;
                    integer MM = 0;
                    integer SS = 0;
                    if (llGetListLength(ymd) >= 3) {
                        yyyy = (integer) llList2String(ymd, 0);
                        mm = (integer) llList2String(ymd, 1);
                        dd = (integer) llList2String(ymd, 2);
                        if (argn >= 3) {
                            string hm = llList2String(args, 2);
                            if (llSubStringIndex(hm, ":") >= 0) {
                                list hms = llParseString2List(hm, [":"], []);
                                HH = (integer) llList2String(hms, 0);
                                MM = (integer) llList2String(hms, 1);
                                SS = (integer) llList2String(hms, 2);
                            } else {
                                goof = TRUE;
                            }
                        }
                    } else {
                        goof = TRUE;
                    }
                    if (!goof) {
                        simEpoch = jdate(yyyy, mm - 1, dd, HH, MM, SS);
                    }
                } else if (llSubStringIndex(td, ".") >= 0) {
                    list jf = llParseString2List(td, ["."], []);
                    simEpoch = [ (float) llList2String(jf, 0),
                                (float) ("0." + llList2String(jf, 1)) ];
                } else if (((integer) llGetSubString(td, 0, 0)) > 0) {
                    simEpoch = [ (integer) td, 0.0 ];
                } else {
                    goof = TRUE;
                }
            } else {
                goof = TRUE;
            }
            if (goof) {
                tawk("Usage: set date yyyy-mm-dd hh:mm:ss / jjjjjjjj.ffff");
                return FALSE;
            } else {
                sendSettings(NULL_KEY, 0);
                updatePlanets();
            }
@}

\subsection{List [ {\em body}\ldots ]}

List information about the specified bodies by number, or all bodies if
no argument is given.

@d processDeployerCommand: Process command
@{
        } else if (abbrP(command, "li")) {
            if (argn < 2) {
                llRegionSay(massChannel,llList2Json(JSON_ARRAY, [ "LIST", 0 ]));
            } else {
                integer b;

                for (b = 1; b < argn; b++) {
                    llRegionSay(massChannel,llList2Json(JSON_ARRAY,
                        [ "LIST", llList2Integer(args, b) ]));
                }
            }
@}

\subsection{Orbit {\em body} [ {\em segments}/{\tt ellipse} [ {\tt permanent } ] ]}

Plot the orbit of the {\tt body}, which may be specified either by
number (with 10 indicating a minor planet being tracked in the Solar
System model) or by its name (which cannot be abbreviated and must
be specified exactly, including upper and lower case letters).  The
orbit can be shown either as a path traced with the specified number
of {\tt segments} (default 48, adjusted automatically in cases of
rapid motion) or as an ellipse object fit to the orbit.  The path of
an orbit is normally traced with temporary objects which do not count
against the land impact of the parcel and are automatically deleted in
the next garbage collection (usually every minute or so), but may be
made permanent by specifying that argument.

@d processDeployerCommand: Process command
@{
        } else if (abbrP(command, "or")) {
            llMessageLinked(LINK_THIS, LM_CP_COMMAND,
                llList2Json(JSON_ARRAY,
                    [ message, s_auscale, planetsPresent, gc_sources,
                      llGetPos() + <0, 0, s_zoffset> ] +
                      simEpoch), whoDat);
            scriptSuspend = TRUE;
@}

\subsection{Planet {\em start} {\em end}}

Add planets {\em start} through {\em end}  to the Solar System
simulation. Planets are specified by number, with 0 denoting the Sun
and 9 Pluto. If no number is specified, the Sun and all planets are
created.

@d processDeployerCommand: Process command
@{
        } else if (abbrP(command, "pl")) {
            if (runmode) {
                tawk("Cannot add a planet while running.");
                return FALSE;
            }

            integer plstart;
            integer plend;

            if (argn > 1) {
                plstart = plend = (integer) sparam;
                if (argn > 2) {
                    plend = llList2Integer(args, 2);
                }
            } else {
                plstart = 0;
                plend = 9;
            }

            integer plno;

            for (plno = plstart; plno <= plend; plno++) {
                string name = llList2String(solarSystem, plno);
                vector where = sphRect(
                    llList2Float(ephBodies, plno * 3),
                    llList2Float(ephBodies, (plno * 3) + 1),
                    llList2Float(ephBodies, (plno * 3) + 2));

                vector eggPos = llGetPos();

                where = (where * s_auscale) + eggPos + <0, 0, s_zoffset>;
 //               llSetRegionPos(where);
                if (trace) {
                    tawk("Deploying " + name + " at " + (string) where);
                }

                /*  Kludge: since zero indicates a manual rez of a planet
                    body, we use -1 as the start parameter for the Sun,
                    whose "planet number" is zero.  It converts it back
                    upon receipt.  */

                integer sp = plno;
                if (plno == 0) {
                    sp = -1;
                }
/*
                llRezAtRoot("S: " + name, where, ZERO_VECTOR,
                    llEuler2Rot(<0, PI_BY_TWO, 0>), sp);
                llSetRegionPos(eggPos);
*/
                flRezRegion("S: " + name, where, ZERO_VECTOR,
                    llEuler2Rot(<0, PI_BY_TWO, 0>), sp);
            }
            scriptSuspend = TRUE;
@}

\subsection{Remove}

Delete all objects created by the simulation.  In most cases, it's
better to use the ``Boot'' command (\ref{BootCommand}), which will
completely reset the simulation for a new model.

@d processDeployerCommand: Process command
@{
        } else if (abbrP(command, "re")) {
            setRunDeployer(FALSE);
            llRegionSay(massChannel, llList2Json(JSON_ARRAY, [ ypres ]));
            planetsPresent = 0;
            gc_sources = 0;
            llMessageLinked(LINK_THIS, LM_CP_REMOVE, "", whoDat);
            //  Reset step number and simulated time
            stepNumber = 0;
            simTime = 0;
            updateLegendDeployer();
@}

\subsection{Run [ {\tt on}/{\tt off} ]}

Run or stop the simulation.  If no argument is given, the run/stop
state is toggled.

@d processDeployerCommand: Process command
@{
        } else if (abbrP(command, "ru")) {
            stepLimit = 0;
            if (planetsPresent || (gc_sources > 0)) {
                if (argn < 2) {
                    setRunDeployer(!runmode);
                } else {
                    setRunDeployer(onOff(sparam));
                }
            } else {
                llMessageLinked(LINK_THIS, LM_CP_COMMAND,
                    llList2Json(JSON_ARRAY, [ message, lmessage ] + args), whoDat);
            }
@}

\subsection{Auxiliary commands}

The following commands are processed by other scripts.  Here we forward
them with the {\tt LM\_CP\_COMMAND} link message to the scripts which
handle them.

\hspace{4em}\vbox{
\begin{description}
\dense
\item[Asteroid]     Set asteroid orbital elements
\item[Centre]       Declare galactic central mass
\item[Clear]        Clear chat for debugging
\item[Comet]        Set comet orbital elements
\item[Help]         Request help notecards
\item[Mass]         Define mass for numerical integration
\item[Script]       Script commands
\item[Source]       Define galactic centre orbiting source
\end{description}
}


@d processDeployerCommand: Process command
@{
        } else if (
                   abbrP(command, "ce") ||
                   abbrP(command, "cl") ||
                   abbrP(command, "he") ||
                   abbrP(command, "sc")
                  ) {
            llMessageLinked(LINK_THIS, LM_CP_COMMAND,
                llList2Json(JSON_ARRAY, [ message, lmessage ] + args), whoDat);
        } else if (
                   //   These are commands which suspend a script until completion
                   abbrP(command, "as") ||
                   abbrP(command, "co") ||
                   abbrP(command, "ma") ||
                   abbrP(command, "so")
                  ) {
            llMessageLinked(LINK_THIS, LM_CP_COMMAND,
                llList2Json(JSON_ARRAY, [ message, lmessage ] + args), whoDat);
            scriptSuspend = TRUE;
@}

\subsection{Set}

The ``Set'' command sets a variety of parameters for the simulation.

@d processDeployerCommand: Process command
@{
        } else if (abbrP(command, "se")) {
            string svalue = llList2String(args, 2);
            float value = (float) svalue;
            integer changedSettings = FALSE;
@}

\subsubsection{Set AUscale}

This setting is obsolete.  Use ``Set scale AU'' instead.

@d processDeployerCommand: Process command
@{
            if (abbrP(sparam, "au")) {
tawk("SET AUSCALE deprecated.  Replace with Set scale AU.");
                s_auscale = value;
                changedSettings = TRUE;
@}

\subsubsection{Set Deltat $n$}

Sets the integration time step for the Numerical Integration
simulation.

@d processDeployerCommand: Process command
@{
            } else if (abbrP(sparam, "de")) {
                s_deltat = value;
                changedSettings = TRUE;
@}

\subsubsection{Set Ecliptic {\tt on}/{\tt off}/{\tt size} $n$}

Controls display of the ecliptic plane for the Solar System
model.  The ecliptic plane is shown as a transparent blue disc
whose size defaults to about the size of the orbit of Neptune.
The ``{\tt size}'' argument sets the size in astronomical units.

@d processDeployerCommand: Process command
@{
            } else if (abbrP(sparam, "ec")) {
                if (abbrP(svalue, "si")) {
                    s_eclipsize = (float) llList2String(args, 3);
                } else {
                    if (onOff(svalue)) {
                        llRezObject("Ecliptic plane",
                            llGetPos() + <0, 0, s_zoffset>, ZERO_VECTOR,
                            ZERO_ROTATION,
                            llFloor(s_eclipsize * 2 * s_auscale * 100));
                        s_eclipshown = TRUE;
                    } else {
                        llRegionSay(massChannel, llList2Json(JSON_ARRAY, [ planecrash ]));
                        s_eclipshown = FALSE;
                    }
                }
                changedSettings = TRUE;
@}

\subsubsection{Set Hide {\tt on}/{\tt off}/{\tt run}}

Hides or displays the Deployer object.  The ``{\tt run}''
option hides the Deployer while a simulation is running and
shows it while stopped.

@d processDeployerCommand: Process command
@{
            } else if (abbrP(sparam, "hi")) {
                if (abbrP(svalue, "ru")) {
                    hidden = 2;
                } else {
                    integer hi = onOff(svalue);
                    if (hi >= 0) {
                        hidden = hi;
                        llSetAlpha(1 - hidden, ALL_SIDES);
                    }
                }
@}

\subsubsection{Set Kaboom $n$}

Sets the distance, in astronomical units, at which objects
self-destruct when wandering too far from the Deployer.  This keeps
objects on parabolic or hyperbolic trajectories from going where
they don't belong.  It's especially useful in complex Numerical
Integration simulations where close encounters can cause masses
to be ejected with high velocities.  The default value is 50
astronomical units, beyond the aphelion of Pluto.

@d processDeployerCommand: Process command
@{
            } else if (abbrP(sparam, "ka")) {
                s_kaboom = value;
                changedSettings = TRUE;
@}

\subsubsection{Set Labels {\tt on}/{\tt off}}

Show or hide floating text labels above objects in the simulation.

@d processDeployerCommand: Process command
@{
            } else if (abbrP(sparam, "la")) {
                s_labels = onOff(svalue);
                changedSettings = TRUE;
@}

\subsubsection{Set Legend {\tt on}/{\tt off}}

Show or hide a floating text legend above the deployer which shows
the status of the simulation, including the simulated date.

@d processDeployerCommand: Process command
@{
            } else if (abbrP(sparam, "le")) {
                s_legend = onOff(svalue);
                if (s_legend) {
                    updateLegendDeployer();
                } else {
                    llSetLinkPrimitiveParamsFast(LINK_THIS, [
                        PRIM_TEXT, "", <0, 0, 0>, 0
                    ]);
                }
                changedSettings = TRUE;
@}

\subsubsection{Set Mindist $n$}

Set the minimum distance, in astronomical units, which objects must
move before the model is updated.  When running with a small time step,
skipping updates for slow-moving objects whose motion is not apparent
to the eye improves efficiency of the simulation.

@d processDeployerCommand: Process command
@{
            } else if (abbrP(sparam, "mi")) {
                s_mindist = value;
                changedSettings = TRUE;
@}

\subsubsection{Set Paths {\tt on}/{\tt off}/{\tt lines}}

Traces trajectories either by depositing particles along them or by
plotting lines using temporary primitive objects that do not count
against a parcel's land impact and are automatically deleted by the
garbage collector after an interval of around a minute.  This is
particularly interesting in Numerical Integration simulations, where
complex interactions among objects occur.

@d processDeployerCommand: Process command
@{
            } else if (abbrP(sparam, "pa")) {
                if (abbrP(svalue, "li")) {
                    if (paths) {
                        paths = FALSE;
                    }
                    s_trails = TRUE;
                } else {
                    s_trails = FALSE;
                    paths = onOff(svalue);
                }
                changedSettings = TRUE;
@}

\subsubsection{Set Pwidth $n$}

Sets the width of trails drawn by the ``Set Paths lines'' command.
The width is specified in Second Life region co-ordinates, and must
be one of the following values: $0.01$, $0.05$, $0.1$, or $0.5$
metres.

@d processDeployerCommand: Process command
@{
            } else if (abbrP(sparam, "pw")) {
                s_pwidth = value;
                changedSettings = TRUE;
@}

\subsubsection{Set Radscale $n$}

Sets the scale at which objects are rendered in the model, expressed as
a factor converting their radius to metres in the Second Life world.
The default value is $1/400000=0.0000025$.  This applies only to bodies
in the Numerical Integration and Galactic Centre models; use the ``Set
Scale'' command for Solar System bodies.

@d processDeployerCommand: Process command
@{
            } else if (abbrP(sparam, "ra")) {
                s_radscale = value;
                changedSettings = TRUE;
@}

\subsubsection{Set Real {\tt on}/{\tt off}/{\tt step} $n$}

Controls real-time mode for the Solar System and Galactic Centre
models.  When enabled, the model will display the objects at the
current date and time, updated every time {\tt step} in seconds
(default 30)

@d processDeployerCommand: Process command
@{
            } else if (abbrP(sparam, "re")) {
                if (abbrP(svalue, "st")) {
                    s_realstep = llList2Float(args, 3);
                } else {
                    s_realtime = onOff(svalue);
                }
                if (s_realtime) {
                    simEpoch = jdstamp(llGetTimestamp());
                    stepNumber++;
                    updatePlanets();
                    llSetTimerEvent(s_realstep);
                } else {
                    llSetTimerEvent(0);
                }
                changedSettings = TRUE;
@}

\subsubsection{Set Satellites {\tt on}/{\tt off} {\em name}/$n$\ldots}

Shows or hides satellites of the planets specified by name or number.

@d processDeployerCommand: Process command
@{
            } else if (abbrP(sparam, "sa")) {
                integer vis = onOff(svalue);
                integer mAnd = 0x3FF;
                integer mOr = 0;
                if (argn > 3) {
                    integer i;

                    for (i = 3; i < argn; i++) {
                        string pname = llList2String(args, i);
                        integer pn = llListFindList(solarSystem,
                            [ llToUpper(llGetSubString(pname, 0, 0)) +
                              llGetSubString(pname, 1, -1) ]);
                        if (pn < 1) {
                            pn = (integer) pname;
                        }

                        if (vis) {
                            mOr = mOr | (1 << pn);
                        } else {
                            mAnd = mAnd & (~(1 << pn));
                        }
                    }
                } else {
                    if (vis) {
                        mOr = 0x3FF;
                    } else {
                        mAnd = 0;
                    }
                }
                s_satShow = (s_satShow & mAnd) | mOr;
//tawk("satShow " + (string) s_satShow + " mAnd " + (string) mAnd + " mOr " + (string) mOr);
                changedSettings = TRUE;
@}

\subsubsection{Set Scale {\tt planet}/{\tt star}/{\tt AU} $n$}

Sets the scale factors for display of the Solar System model.  They
call space ``space'' because there's so much {\em space} there, and
this poses a challenge when trying to make a scale model of the
solar system.  If you show orbits at a scale that fits in a reasonable
space, the planets are too tiny to see, and if you make the planets
big enough to recognise, the Sun dwarfs everything else.  To cope
with this, we define three separate scale factors when rendering the
Solar System, which may be set by these parameters.  The {\tt planet}
scale factor, which defaults to 0.1, scales planets from units of 1000
kilometres diameter to Second Life metres.  A separate scale factor,
{\tt star}, sets the scale for the Sun, with a default of
$1/750\approx 0.001333\ldots$.  Finally, {\tt AU} sets the scale for
orbits, default 0.3, from astronomical units to Second Life metres.
These scale factors must be set before creating objects with the
``Planet'', ``Asteroid'', or ``Comet'' commands.

@d processDeployerCommand: Process command
@{
            } else if (abbrP(sparam, "sc")) {
                float factor = llList2Float(args, 3);
                if (abbrP(svalue, "au")) {
                    s_auscale = factor;
                    changedSettings = TRUE;
                } if (abbrP(svalue, "pl")) {
                    m_scalePlanet = factor;
                } else if (abbrP(svalue, "st")) {
                    m_scaleStar = factor;
                }
@}

\subsubsection{Set Simrate $n$}

Sets the simulation rate in years of simulated time per second of
simulation.

@d processDeployerCommand: Process command
@{
            } else if (abbrP(sparam, "si")) {
                s_simRate = parseSimInterval(svalue);
                changedSettings = TRUE;
@}

\subsubsection{Set Step $n$}

Sets the time step for the simulation, which is specified as a number
and unit suffix as defined by the {\tt parseSimInterval()}
(\ref{parseSimInterval}) function.  The step is ultimately set
in terms of years per step.  The rate at which the simulation is
updated is thus given by ${\rm Simrate}/{\rm Step}$.

@d processDeployerCommand: Process command
@{
            } else if (abbrP(sparam, "st")) {
                s_stepRate = parseSimInterval(svalue);
                changedSettings = TRUE;
@}

\subsubsection{Set Trace {\tt on}/{\tt off}}

Enables diagnostic output from the simulator as it runs, mostly of
interest to developers.

@d processDeployerCommand: Process command
@{
            } else if (abbrP(sparam, "tr")) {
                trace = onOff(svalue);
                changedSettings = TRUE;
@}

\subsubsection{Set Zoffset $n$}

Objects created by the Deployer are placed this number of metres above
its altitude.

@d processDeployerCommand: Process command
@{
            } else if (abbrP(sparam, "zo")) {
                s_zoffset = value;
                changedSettings = TRUE;

            } else {
                tawk("Set command invalid: unknown parameter.");
                return FALSE;
            }
            if (changedSettings) {
                sendSettings(NULL_KEY, 0);
            }
@}

\subsection{Status}

Show status in local chat.  We print local status and request other
scripts to report their status.

@d processDeployerCommand: Process command
@{
        } else if (abbrP(command, "sta")) {
            integer mFree = llGetFreeMemory();
            integer mUsed = llGetUsedMemory();
            string hidemode = eOnOff(hidden);
            if (hidden == 2) {
                hidemode = "run";
            }
            tawk(llGetScriptName() + " status:" +
                 "\n  Build @<Build number@> @<Build date and time@>" +
                 "\n  Script memory.  Free: " + (string) mFree +
                    "  Used: " + (string) mUsed + " (" +
                    (string) ((integer) llRound((mUsed * 100.0) / (mUsed + mFree))) + "%)"
            );
            llMessageLinked(LINK_THIS, LM_SP_STAT, "", whoDat);
            /*  Many modules with an auxiliary command processor
                handle the Status command within it.  */
            llMessageLinked(LINK_THIS, LM_CP_COMMAND,
                llList2Json(JSON_ARRAY, [ "Status", "status" ] + args), whoDat);
//            llMessageLinked(LINK_THIS, LM_OR_STAT, "", whoDat);
            llMessageLinked(LINK_THIS, LM_GP_STAT, "", whoDat);
@}

\subsection{Step $n$}

Step the simulation $n$ (default 1) time increments.  If the simulation
is in Run or Real time mode, it is stopped.

@d processDeployerCommand: Process command
@{
        } else if (abbrP(command, "ste")) {
            integer n = (integer) sparam;

            if (n < 1) {
                n = 1;
            }
            stepLimit = n;
            if (planetsPresent || (gc_sources > 0)) {
                setRunDeployer(TRUE);
            } else {
                llMessageLinked(LINK_THIS, LM_CP_COMMAND,
                    llList2Json(JSON_ARRAY, [ message, lmessage ] + args), whoDat);
            }
            scriptSuspend = TRUE;
@}

\subsection{Test {\em what}}

Run a test.  This is used for developers to run experimental code.  The
``Test version'' command broadcasts the build number of the Deployer to
all scripts within it with a {\tt LM\_AS\_VERSION} link message and to
all objects it has created by a {\tt VERSION} message.  Scripts should
check their own build number against it and report if they are not from
the same build.

@d processDeployerCommand: Process command
@{
        } else if (abbrP(command, "te")) {
            if (abbrP(sparam, "ve")) {          // Test version
                llMessageLinked(LINK_THIS, LM_AS_VERSION,
                    "@<Build number@>", whoDat);
                llRegionSay(massChannel,
                    llList2Json(JSON_ARRAY, [ "VERSION", "@<Build number@>" ]));
            } else {
                tawk("Unknown test.");
            }

        } else {
            tawk("Huh?  \"" + message + "\" undefined.  Chat /" +
                (string) commandChannel + " help for instructions.");
            return FALSE;
        }
        return TRUE;
    }
@}

\section{Deployer script}

We begin by declaring global variables for the script.

@o scripts/deployer.lsl
@{
    @<Explanatory header for LSL files@>

    key owner;                          //  Owner UUID
    string ownerName;                   //  Name of owner

    integer commandChannel = 222;       // Command channel in chat
    integer commandH;                   // Handle for command channel
    key whoDat = NULL_KEY;              // Avatar who sent command
    integer restrictAccess = 2;         // Access restriction: 0 none, 1 group, 2 owner
    integer echo = TRUE;                // Echo chat and script commands ?

    integer massChannel = @<massChannel@>;  // Channel for communicating with bodies
    integer massChH;                    // Mass channel listener handle
    string ypres = "B?+:$$";            // It's pronounced "Wipers"
    string planecrash = "P?+:$$";       // Selectively delete ecliptic plane

    //  Script processing

    integer scriptActive = FALSE;       // Are we reading from a script ?
    integer scriptSuspend = FALSE;      // Suspend script execution for asynchronous event

    //  Settings

    integer trace = FALSE;              // Trace mass behaviour
    integer paths = FALSE;              // Show particle trails from masss ?

    integer hidden = 2;                 // Is the deployer hidden ?
@}

Declare variables for keeping track of bodies in the currently
loaded model.

@o scripts/deployer.lsl
@{
    //  Names of solar system objects, corresponding to objects in inventory
    list solarSystem = [
        "Sun", "Mercury", "Venus", "Earth", "Mars",
        "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto",
        "??MP??"
    ];

    //  Keys of planets (filled in as they are rezzed)
    list planetKeys = [ NULL_KEY, NULL_KEY, NULL_KEY, NULL_KEY, NULL_KEY,
                        NULL_KEY, NULL_KEY, NULL_KEY, NULL_KEY, NULL_KEY,
                        NULL_KEY ];

    //  Bit mask of planets present, used to request ephemeris
    integer planetsPresent = 0;

    //  Galactic centre sources present
    integer gc_sources = 0;
@}

Settings, both communicated to bodies and local to the Deployer.

@o scripts/deployer.lsl
@{
    //  Settings communicated by deployer
    float s_kaboom = 50;                // Self destruct if this far (AU) from deployer
    float s_auscale = 0.3;              // Astronomical unit scale
    float s_radscale = 0.0000025;       // Radius scale
    integer s_trails = FALSE;           // Show trails with temporary prims
    float s_pwidth = 0.01;              // Paths/trails width
    float s_mindist = 0.01;             // Minimum distance to update

    float m_scalePlanet = 0.1;          // Scale of planet objects
    float m_scaleStar = 0.00133333;     // Scale of star objects
    integer s_labels = FALSE;           // Show labels on objects
    integer s_satShow = 0;              // Show satellites of planets ?

    //  These settings are not sent to the masses
    float s_deltat = 0.01;              // Integration time step
    float s_zoffset = 1;                // Z offset to create masses
    integer s_legend = FALSE;           // Display legend above deployer
    float s_simRate = 1;                // Simulation rate (years/second)
    float s_stepRate = 0.1;             // Integration step rate (years/step)
    integer s_eclipshown = FALSE;       // Showing the ecliptic
    float s_eclipsize = 30;             // Radius of ecliptic plane
    integer s_realtime = FALSE;         // Display solar system in real time
    float s_realstep = 30;              // Real time update interval, seconds

    integer stepNumber = 0;             // Step counter
    float simTime = 0;                  // Simulation time (years)

    integer runmode = FALSE;            // Running the simulation ?
    float tickTime = 0.01;              // Simulation update time
    integer stepLimit = 0;              // Simulation step counter
    list simEpoch;                      // Simulation epoch (jd, jdf)
    integer ev_updating = FALSE;        // Is an update in progress ?
    float ev_stuck;                     // Timeout start for ev_updating
    float ev_stuck_timeout = 2;         // Timeout interval for ev_updating
@}

We use the following link message codes to communicate with other
scripts.

@o scripts/deployer.lsl
@{
    @<Script processor messages@>
    @<Command processor messages@>
    @<Ephemeris link messages@>
    @<Auxiliary services messages@>
    @<Minor planet link messages@>
    @<Galactic centre messages@>
    @<Galactic patrol messages@>
@}

Import utility functions we use.

@o scripts/deployer.lsl
@{
    @<tawk: Send a message to the interacting user in chat@>

    @<fuis: Encode floating point number as base64 string@>
    @<fv: Encode vector as base64 string@>

    @<jdate: UTC to Julian day and fraction@>
    @<jdstamp: LSL timestamp to Julian day and fraction@>
    @<sumJD: Increment Julian day and fraction@>

    @<sphRect: Spherical to rectangular co-ordinate conversion@>

    @<abbrP: Test argument, allowing abbreviation@>
    @<onOff: Parse an on/off parameter@>
    @<eOnOff: Edit an on/off parameter@>
    @<inventoryName: Extract inventory name from command@>

    @<flRezRegion: Rez object anywhere in region@>
@}

Define our local functions.

@o scripts/deployer.lsl
@{
    @<sendSettings: Send settings to objects@>
    @<scriptResume: Resume script after command completion@>
    @<setRunDeployer: Start or stop the simulation@>
    @<updateLegendDeployer: Update legend above deployer@>
    @<updateEphemeris: Update ephemeris for selected bodies@>
    @<updatePlanets: Update planets@>
    @<checkAccess: Check user permission to send commands@>
    @<parseSimInterval: Parse simulation interval@>
    @<processDeployerCommand: Process command@>
@}

This is the Deployer's event processor.  On creation, simply reset the
script so all values are re-initialised.

@o scripts/deployer.lsl
@{
    default {

        on_rez(integer start_param) {
            llResetScript();
        }
@}

Upon state entry, start listening to local chat for commands from the
user, and on {\tt massChannel} for communications from bodies in the
simulation.

@o scripts/deployer.lsl
@{
        state_entry() {
            owner = llGetOwner();
            ownerName =  llKey2Name(owner);  //  Save name of owner

            llSetAlpha(1, ALL_SIDES);
//  Initially compute ephemeris so planets are created at current position
simEpoch = jdstamp(llGetTimestamp());
ephTask = "none";
updateEphemeris((1 << 10) - 2,
    llList2Integer(simEpoch, 0), llList2Float(simEpoch, 1));

            s_legend = FALSE;
            llSetLinkPrimitiveParamsFast(LINK_THIS, [
                PRIM_TEXT, "", <0, 0, 0>, 0
            ]);

            //  Start listening on the command chat channel
            commandH = llListen(commandChannel, "", NULL_KEY, "");
            llOwnerSay("Listening on /" + (string) commandChannel);

            //  Start listening on the mass channel
            massChH = llListen(massChannel, "", NULL_KEY, "");

            //  Send initial settings to other scripts
            sendSettings(NULL_KEY, 0);
        }
@}

The {\tt listen} event is used to receive {\tt PLANTED} messages when
Solar System bodies are created and respond with the {\tt PINIT}
message which provides them their properties and the initial settings.
It also receives user commands from local chat.

@o scripts/deployer.lsl
@{
       listen(integer channel, string name, key id, string message) {
//llOwnerSay("Listen channel " + (string) channel + " message " + message);
            if (channel == massChannel) {
                list msg = llJson2List(message);
                string ccmd = llList2String(msg, 0);

                if (ccmd == "PLANTED") {
                    integer mass_number = llList2Integer(msg, 1);
                    planetKeys = llListReplaceList(planetKeys, [ id ],
                        mass_number, mass_number);
                    planetsPresent = planetsPresent | (1 << mass_number);

                    llRegionSayTo(id, massChannel,
                        llList2Json(JSON_ARRAY, [ "PINIT", mass_number,
                            llList2String(solarSystem, mass_number),    // Name of body
                            fv(llGetPos() + <0, 0, s_zoffset>),         // Deployer position
                            fuis(m_scalePlanet),                        // Scale for planets
                            fuis(m_scaleStar),                          // Scale for stars
                            llList2Integer(simEpoch, 0),                // Epoch Julian day
                            fuis(llList2Float(simEpoch, 1))             // Epoch Julian day fraction
                    ]));

                    //  Send initial settings
                    sendSettings(id, mass_number);
//tawk("Planted body " + (string) mass_number + "  keys " + llList2CSV(planetKeys) + "  present " + (string) planetsPresent);
                    //  Resume deployer script, if suspended
                    llMessageLinked(LINK_THIS, LM_CP_RESUME, "", whoDat);
@}

When we're sending updates to Solar System planets, we need to pause
until all planets have updated themselves, lest we get ahead of things
and overflow the region message queue.  We do this by having the last
planet we update send an {\tt UPDATED} message back to us when it's
done, informing us we can send another round of updates.

@o scripts/deployer.lsl
@{
                } else if (ccmd == "UPDATED") {
                    ev_updating = FALSE;
                }
            } else {
@}

If this is a command from local chat, pass it to the command processor.

@o scripts/deployer.lsl
@{
                processDeployerCommand(id, message, FALSE);
            }
        }
@}

The link message event handles communications from other scripts within
the Deployer.  A number of messages are used to receive data and
status information from the Script Processor (\ref{ScriptProcessor}).

@o scripts/deployer.lsl
@{
        link_message(integer sender, integer num, string str, key id) {

            //  LM_SP_READY (57): Script ready to read
            if (num == LM_SP_READY) {
                scriptActive = TRUE;
                llMessageLinked(LINK_THIS, LM_SP_GET, "", id);  // Get the first line

            //  LM_SP_INPUT (55): Next executable line from script
            } else if (num == LM_SP_INPUT) {
                if (str != "") {                // Process only if not hard EOF
                    scriptSuspend = FALSE;
                    integer stat = processDeployerCommand(id, str, TRUE);
                    // Some commands may set scriptSuspend
                    if (stat) {
                        if (!scriptSuspend) {
                            llMessageLinked(LINK_THIS, LM_SP_GET, "", id);
                        }
                    } else {
                        //  Error in script command.  Abort script input.
                        scriptActive = scriptSuspend = FALSE;
                        llMessageLinked(LINK_THIS, LM_SP_INIT, "", id);
                        tawk("Script terminated.");
                    }
                }

            //  LM_SP_EOF (56): End of file reading from script
            } else if (num == LM_SP_EOF) {
                scriptActive = FALSE;           // Mark script input complete
                if (echo || trace) {
                    tawk("End script.");
                }

            //  LM_SP_ERROR (58): Error processing script request
            } else if (num == LM_SP_ERROR) {
                llRegionSayTo(id, PUBLIC_CHANNEL, "Script error: " + str);
                scriptActive = scriptSuspend = FALSE;
                llMessageLinked(LINK_THIS, LM_SP_INIT, "", id);
@}

The {\tt LM\_CP\_RESUME} message resumes a script whose execution
was suspended by a command processed by another script.

@o scripts/deployer.lsl
@{
            //  LM_CP_RESUME (225): Resume script after external command
            } else if (num == LM_CP_RESUME) {
                scriptResume();
@}

When we request an ephemeris calculation for Solar System bodies, the
results are returned from the individual calculators via {\tt
LM\_EP\_RESULT} messages.  We accumulate these results in the {\tt
ephBodies} list, and when we've received all that we requested, send
the new positions to the bodies in {\tt UPDATE} messages.

@o scripts/deployer.lsl
@{
            //  LM_EP_RESULT (432): Ephemeris calculation results
            } else if (num == LM_EP_RESULT) {
               list l = llCSV2List(str);
                integer handle = llList2Integer(l, 4);
                if (handle == ephHandle) {
                    integer body = llList2Integer(l, 0);
                    ephReplies = ephReplies | (1 << body);
                    integer bx = body * 3;
                    ephBodies = llListReplaceList(ephBodies, llList2List(l, 1, -2), bx, bx + 2);
                    if (ephReplies == ephRequests) {
//float ephCalcEnd = llGetTime();
//tawk("Ephemeris calculation time: " + (string) (ephCalcEnd - ephCalcStart));
                        if (ephTask == "update") {
                            integer i;

                            updateLegendDeployer();
                            for (i = 1; i <= 10; i++) {
                                if (llList2Key(planetKeys, i) != NULL_KEY) {
                                    integer p = i * 3;
                                    vector where = sphRect(
                                        llList2Float(ephBodies, p),
                                        llList2Float(ephBodies, p + 1),
                                        llList2Float(ephBodies, p + 2));

                                    vector eggPos = llGetPos();

                                    vector rwhere = (where * s_auscale) + eggPos + <0, 0, s_zoffset>;
                                    llRegionSayTo(llList2Key(planetKeys, i), massChannel,
                                        llList2Json(JSON_ARRAY, [ "UPDATE", i,
                                            fv(rwhere),                         // New rectangular co-ordinates
                                            llList2Integer(simEpoch, 0),        // Epoch Julian day
                                            fuis(llList2Float(simEpoch, 1))     // Epoch Julian day fraction
                                    ]));
                                }
                            }
                        }
                    }
                }
//else { tawk("Handle mismatch " + (string) ephHandle + "  Rep " + llList2CSV(l)); }
@}

When a minor planet is added to the Solar System model with the
``Asteroid'' or ``Comet'' command, the Minor Planets script informs us
via an {\tt LM\_MP\_TRACK} message.  We use this to create the model
for the body, add it to the list of bodies, and report it in the
legend.  If an object was previously tracked, it is removed and
deleted.

@o scripts/deployer.lsl
@{
            //  LM_MP_TRACK (571): Tracking minor planet
            } else if (num == LM_MP_TRACK) {
                list args = llJson2List(str);
                if (llList2Integer(args, 0)) {
                    string m_name = llList2String(args, 1);
//tawk("Now tracking minor planet (" + m_name + ")");
                    planetsPresent = planetsPresent | (1 << 10);
                    solarSystem = llListReplaceList(solarSystem, [ m_name ], 10, 10);
                    string bname = "Comet";
                    if (llList2Integer(args, 3)) {
                        bname = "Asteroid";
                    }
                    llRezAtRoot("S: " + bname, llGetPos() + <0, 0, s_zoffset>, ZERO_VECTOR,
                        llEuler2Rot(<0, PI_BY_TWO, 0>), 10);
                } else {
                    //  Dropping tracking of current object
                    planetsPresent = planetsPresent & (~(1 << 10));
                    solarSystem = llListReplaceList(solarSystem, [ "" ], 10, 10);
                    key mpk = llList2Key(planetKeys, 10);
                    if (mpk != NULL_KEY) {
                        planetKeys = llListReplaceList(planetKeys, [ NULL_KEY ], 10, 10);
                        llRegionSayTo(mpk, massChannel, llList2Json(JSON_ARRAY, [ ypres ]));
                    }
                }
                updatePlanets();
@}

Similarly, when a ``Source'' command is used to declare a Galactic
Centre model, we're notified by an {\tt LM\_GC\_SOURCES} message.
This lets us know we're running the Galactic Centre model instead of
the Solar System and adapt accordingly.

@o scripts/deployer.lsl
@{
            //  LM_GC_SOURCES (752): Modeling galactic centre
            } else if (num == LM_GC_SOURCES) {
                list l = llJson2List(str);
                gc_sources = llList2Integer(l, 0);  // Number of sources
                ev_updating = FALSE;
            }
        }
@}

The timer is used to update the simulation when we are in Run or
Real time mode.  Timer steps are adjusted to achieve the simulation
rate set by ``Set Simrate'' and ``Set Step''.  If we are forced
to defer the update because the previous one has not yet been
completed, a ``time deficit'' is reported in chat: this usually
means you should adjust the simulation rate parameters to slow the
frequency of updates.

@o scripts/deployer.lsl
@{
        timer() {
//tawk("Timer  real " + (string) s_realtime);
            if (ev_updating) {
//tawk("Deferred update: objects still moving.");
                if (ev_stuck == 0) {
                    ev_stuck = llGetTime();
                    return;
                } else if ((llGetTime() - ev_stuck) > ev_stuck_timeout) {
tawk("Galactic centre stuck after " + (string) (llGetTime() - ev_stuck) + ".  Restarting.");
                    ev_updating = 0;
                } else {
                    return;
                }
            }
            ev_stuck = 0;
            if (s_realtime) {
                simEpoch = jdstamp(llGetTimestamp());
                if (gc_sources > 0) {
                    llMessageLinked(LINK_THIS, LM_GP_UPDATE,
                        llList2CSV(simEpoch), whoDat);
                    ev_updating = TRUE;
                    updateLegendDeployer();
                } else {
                    updatePlanets();
                }
                stepNumber++;
            } else if (runmode) {
//tawk("Tick...");
float tstart = llGetTime();
integer nsteps = 0;
@}

In an analytical planetary theory we always get the answer immediately
calculation-wise, but not in real time, as we must wait for the
individual evaluators to reply.

@o scripts/deployer.lsl
@{
                simEpoch = sumJD(simEpoch, s_stepRate * 365.25);
                if (gc_sources > 0) {
                    llMessageLinked(LINK_THIS, LM_GP_UPDATE,
                        llList2CSV(simEpoch), whoDat);
                    ev_updating = TRUE;
                    updateLegendDeployer();
                } else {
                    updatePlanets();
                }
                nsteps++;
                stepNumber++;

                float tcomp = llGetTime() - tstart;
                if (stepLimit > 0) {
                    stepLimit--;
                    if (stepLimit <= 0) {
                        setRunDeployer(FALSE);
                        scriptResume();
tawk("Stopped.");
                    }
                }
                if (runmode) {
                    float wait = (s_stepRate / s_simRate) - tcomp;
                    if (wait <= 0) {
                        tawk("Time deficit: " + (string) wait);
                        wait = 0.001;
                    }
                    llSetTimerEvent(wait);
                }
            }
        }
    }
@}

\chapter{Solar System}

The Solar System is one of the principal models we implement.  It
uses a mix of analytical planetary theory (VSOP87) and computation
from orbital elements to model the Sun, major planets, their principal
satellites, and minor bodies such as asteroids and comets.

\section{Planets}

Positions of major planets (excluding Pluto) are computed using the
VSOP87 planetary theory (truncated in some cases to cope with LSL's
script memory limits).  The following code is common to all planets
and some is used by satellites as well.

\subsection{Align north pole}

Rotate the north pole of a body to its correct orientation in space.
The {\tt planet} list contains an item (22) which specifies the
orientation of the body's north pole as a vector in which the {\tt .x}
component is the right ascension and the {\tt .y} component the
declination of the north pole's position on the celestial sphere,
specified as equatorial co-ordinates, in degrees, at the epoch given by
list items 0 and 25. (The {\tt .z} component of this vector is
ignored.)

We require the orientation of the north pole in heliocentric ecliptical
space, which we obtain by first rotating the body about the global Y
axis to tilt the pole to the specified declination, then rotating
around the global Z axis to the azimuth specified by the right
ascension.  At this point, we have the globe properly oriented in
equatorial space.

But, we're not done.  To obtain the orientation in ecliptic
co-ordinates, so we must now tilt the globe along the global X axis,
which is the plane of intersection between the ecliptic and the
equatorial planes, aligned with the vector toward the March equinox.
Since the obliquity of the ecliptic varies with time, we need the
Julian day and fraction of the epoch in order to perform this
transformation.

We do not actually rotate the globe here, but rather return the
rotation computed to achieve the desired orientation.

@d rotPole: Align north pole
@{
    rotation rotPole(integer jd, float jdf) {
        float obleq = obliqeq(jd, jdf) * DEG_TO_RAD;    // Obliquity of the ecliptic
        vector npoled = llList2Vector(planet, 22);      // North pole, degrees
        vector npoler = npoled * DEG_TO_RAD;            // North pole, radians
        //  Tilt to declination
        rotation rpole = llEuler2Rot(<0, PI - npoler.y, 0>);

        //  Rotate to right ascension
        rpole = rpole * llEuler2Rot(<0, 0, npoler.x>);

        //  Tilt from equatorial to ecliptic plane
        rpole = rpole * llEuler2Rot(<-obleq, 0, 0>);

        /*  Compute axis around which the body rotates.
            This axis is defined by the vector from its
            centre to the north pole.  */
        vector raxis = < -1, 0, 0 > * rpole;
        /*  The local Z axis (yes, I know, it doesn't make any
            sense, but bear with me) defines the prime meridian.
            This must be determined after applying to rotation
            to align the north pole in space.  */
        vector lfwd = llRot2Up(rpole);
        /*  The cross product of the normalised vector from the
            centre of the body to zero latitude in ecliptic
            co-ordinates (its positive X axis) and the rotation
            axis gives us the normal to the plane defined by
            the rotation axis and zero latitude.  */
        vector xnorm = raxis % < -1, 0, 0 >;
        /*  Now, our task is to rotate the globe around its
            axis of rotation (raxis) so as to make the prime
            meridian vector (lfwd) fall within the plane to
            which xnorm is the normal.  The dot product of
            these two vectors is the cosine of the angle
            between them.  */
        float tang = PI_BY_TWO - llAcos(lfwd * xnorm);
        /*  The angle, tang, computed above, does not take into
            account whether the prime meridian vector, projected
            upon the line containing the centre of the body
            and ecliptic origin, is parallel or anti-parallel to the
            vector from the centre of the body to the
            origin.  We compute the angle between these two
            vectors from their dot product, and then test
            their direction using the magnitude of this angle.  */
        float fpxa = llAcos(lfwd * < -1, 0, 0 >);
        if (fpxa < PI_BY_TWO) {
            tang = -(PI + tang);
        }
//tawk("raxis " + (string) raxis + " lfwd " + (string) lfwd + " xnorm " + (string) xnorm + " tang " + (string) (tang * RAD_TO_DEG) + " fpxa " + (string) (fpxa * RAD_TO_DEG) + " totrot " + (string) (llRot2Euler(rpole * llAxisAngle2Rot(raxis, tang)) * RAD_TO_DEG));
        /*  Compose the prime meridian rotation with the
            north pole alignment rotation to obtain the
            complete body rotation.  */
        rpole = rpole * llAxisAngle2Rot(raxis, tang);
        return rpole;
    }
@| rotPole @}

\subsection{Rotate globe to subsolar meridian}

Compute a rotation around the polar axis to align the
subsolar point of the globe to point toward the Sun.
This is based upon the elapsed time since the start of
the rotation epoch and does not actually align with
the planet's rotation.  We use this for gas giants
and bodies where precise local time is not defined.

@d rotHour: Rotate globe to subsolar meridian
@{
    rotation rotHour(integer jd, float jdf) {
        /*  Compute axis around which the body rotates.
            This axis is defined by the vector from its
            centre to the north pole.  */
        vector raxis = < 1, 0, 0 > * npRot;
        /*  Compute rotation angle from the elapsed time
            since the start of the rotation epoch and the
            rotation period in days.  */
        float jde = (jd - llList2Integer(rotEpoch, 0)) +
                    (jdf - llList2Float(rotEpoch, 1));
        float period = llList2Float(planet, 21);
        float gangle = fixangr(TWO_PI * (jde / period));
        /*  Compose the prime meridian rotation with the
            north pole alignment rotation to obtain the
            complete satellite rotation.  */
        return npRot * llAxisAngle2Rot(raxis, sgn(period) * (-gangle));
    }
@| rotHour @}

\subsection{Forward deployer message to satellites}

To avoid having every satellite independently listen to messages from
the deployer (and hence receive messages for other planets, which it
would have to filter), planets take on the responsibility of forwarding
deployer messages relevant to satellites to them.  The raw message
string is forwarded: it's up to the satellites to parse and interpret
it.

@d tellSat: Forward deployer message to satellites
@{
    tellSat(string message) {
        llMessageLinked(LINK_ALL_CHILDREN, LM_PS_DEPMSG,
            message, deployer);
    }
@| tellSat @}

\subsection{Update planet legend}

Updates the floating text legend for a planet.  We display the planet's
name and heliocentric position in the colour used to trace its orbit.

@d updateLegendPlanet: Update planet legend
@{
    updateLegendPlanet(vector pos) {
        if (s_labels) {
            string legend = m_name;

            if (m_index > 0) {
                vector lbr = rectSph(pos);
                legend += "\nLong " + eff(fixangr(lbr.x) * RAD_TO_DEG) +
                            "° Lat " + eff(lbr.y * RAD_TO_DEG) +
                            "°\nRV " + eff(lbr.z) + " AU" +
                            "\nPos " + efv(pos);
            }
            llSetLinkPrimitiveParamsFast(lGlobe, [
                PRIM_TEXT, legend,llList2Vector(planet, 27), 1
            ]);
        }
    }
@| updateLegendPlanet @}

\subsection{Update satellites of planet}

Send message containing the current Julian day and fraction to
request this planet's satellites to update their position and
rotation.  To avoid having to send separate messages to each
satellite and keep track of their link numbers, we broadcast
to all child prims with {\tt LINK\_ALL\_CHILDREN}.  If we have
child links which don't care about updates (a ring system,
for example), they should simply ignore the {\tt LM\_PS\_UPDATE}
message.

@d updateSat: Update satellites of planet
@{
    updateSat(integer jd, float jdf) {
        llMessageLinked(LINK_ALL_CHILDREN, LM_PS_UPDATE,
                        llList2Json(JSON_ARRAY,
                            [ jd, fuis(jdf)     // 0,1  Julian day and fraction
                            ]), deployer);
    }
@| updateSat @}

\subsection{Process ``ypres'' message to self-destruct}

The ``{\tt ypres}'' (pronounced ``wipers'') message indicates it's time
to go: it is sent by the deployer when the user enters a Remove or Boot
command.  If we are generating orbit trails, forward the message to
satellites so they can clean up their own trails and wait a moment
before self-destructing (which will destroy the satellites as well,
since they are child prims) to let them finish their business.

@d Process planet ``ypres'' message to self-destruct@'@'
@{
    if (ccmd == ypres) {
        if (s_trails) {
            llRegionSay(massChannel,
                llList2Json(JSON_ARRAY, [ ypres ]));
            @1
        }
        llDie();
@}

\subsection{Process planet {\tt COLLIDE} message}

The {\tt COLLIDE} message indicates we've collided with another object.
Planets are never supposed to collide with one another, but you
never know\ldots .

@d Process planet {\tt COLLIDE} message
@{
        } else if (ccmd == "COLLIDE") {
            kaboom(llList2Vector(planet, 27));
@}

\subsection{Process planet {\tt LIST} message}

The {\tt LIST} message sends information about the planet to local
chat, including script memory usage, in which developers are
acutely interested.

@d Process planet {\tt LIST} message
@{
        } else if (ccmd == "LIST") {
            integer bnreq = llList2Integer(msg, 1);

            if ((bnreq == 0) || (bnreq == m_index)) {
                integer mFree = llGetFreeMemory();
                integer mUsed = llGetUsedMemory();

                tawk("Mass " + (string) m_index +
                     "  Name: " + m_name +
                     "  Position: " + efv(llGetPos()) +
                     "\n    Script memory.  Free: " + (string) mFree +
                        "  Used: " + (string) mUsed + " (" +
                        (string) ((integer) llRound((mUsed * 100.0) / (mUsed + mFree))) + "%)"
                    );
            }
@}


\subsection{Planet link messages}

The following link messages are used for local communications between
a planet and its satellites, which are linked to the planet object.

@d Planet link messages
@{
    //  Planetary satellite message
    integer LM_PS_DEPMSG = 811;         // Message from deployer
    integer LM_PS_UPDATE = 812;         // Update position and rotation
@| LM_PS_DEPMSG LM_PS_UPDATE @}

\subsection{Planet global variables}

The following global variables are used by the object scripts for both
major planets and minor planets (asteroids and comets) as well as
satellites of major planets.

@d Planet global variables
@{
    string ourName;                     // Our object name
    key owner;                          // UUID of owner
    key deployer;                       // ID of deployer who hatched us
    integer initState = 0;              // Initialisation state

    //  Properties of this mass
    integer s_trace = FALSE;            // Trace operations
    integer m_index;                    // Our mass index
    string m_name;                      // Name
    float m_scalePlanet;                // Planet scale

    //  Settings communicated by deployer
    float s_kaboom = 50;                // Self destruct if this far (AU) from deployer
    float s_auscale = 0.3;              // Astronomical unit scale
    integer s_trails = FALSE;           // Plot orbital trails ?
    float s_pwidth = 0.01;              // Paths/trails width
    float s_mindist = 0.1;              // Minimum distance to move
    integer s_labels = FALSE;           // Show floating text legend ?
    integer s_satShow = 0;              // Show satellites

    string ypres = "B?+:$$";            // It's pronounced "Wipers"

    vector deployerPos;                 // Deployer position

    key whoDat;                         // User with whom we're communicating
    integer paths;                      // Draw particle trail behind masses ?
@}

\subsection{Planet and minor planet global variables}

Major and minor planets share a few more global variables which
aren't used by satellites.

@d Planet and minor planet global variables
@{
    @<Planet global variables@>
    integer massChannel = @<massChannel@>;  // Channel for communicating with planets
    string Collision = "Balloon Pop";   // Explosion sound clip

    //  Link indices within the object
    integer lGlobe;                     // Planetary globe
@}

\subsection{Planet object script}

This is the generic script used for all planets. It is identical for
all planets, parameterised by values declared in the {\tt planet} list
declared at the top of the script for a specific planet.  This macro
takes two arguments which allow specific planet scripts to interpolate
code for object-specific processing.  The first is run at the end of
processing the {\tt PINIT} message from the deployer and may be used
to configure components of the model based upon information it
provides.  For example, the Saturn model uses this to scale and
rotate the ring system to conform to the size and orientation of the
planet.  The second is executed at completion of the {\tt UPDATE}
message.  Planets, like the Earth, which need to set their rotation
based upon the date of the update may use this to compute and set the
correct rotation.

We begin by declaring global variables used in the script.

@d Planet object script@'@'@'@'@'@'
@{
    @<Planet and minor planet global variables@>

    //  These are used only for major planets
    rotation npRot;                     // Rotation to orient north pole
    float m_scaleStar;                  // Star scale
    integer m_jd;                       // Epoch Julian day
    float m_jdf;                        // Epoch Julian day fraction
    list rotEpoch;                      // Base epoch for rotation

    //  Link messages
    @<Planet link messages@>
@}

Declare all of the functions used in the script.

@d Planet object script@'@'@'@'@'@'
@{
    @<findLinkNumber: Find a linked prim by name@>

    @<fuis: Encode floating point number as base64 string@>
    @<siuf: Decode base64-encoded floating point number@>
    @<sv: Decode base64-encoded vector@>

    @<ef: Edit floating point number to readable representation@>
    @<eff: Edit float to readable representation@>
    @<efv: Edit vector to readable representation@>

    @<flRezRegion: Rez object anywhere in region@>
    @<flPlotLine: Plot line in space@>

    @<obliqeq: Obliquity of the ecliptic@>

    @<sgn: Sign of argument@>
    @<rotHour: Rotate globe to subsolar meridian@>
    @<rotPole: Align north pole@>

    @<rectSph: Rectangular to spherical co-ordinate conversion@>
    @<fixangr: Range reduce an angle in radians@>

    @<tellSat: Forward deployer message to satellites@>
    @<updateLegendPlanet: Update planet legend@>
    @<updateSat: Update satellites of planet@>
    @<kaboom: Destroy object@>

    @<tawk: Send a message to the interacting user in chat@>
@}

We have a single state, {\tt default}.  At {\tt state\_entry()}, we
find the link for the displayed planet globe and save it for
subsequent manipulation.

@d Planet object script@'@'@'@'@'@'
@{
    default {

        state_entry() {
            whoDat = owner = llGetOwner();

            //  Find link indices within this link set by name
            lGlobe = findLinkNumber("Globe");
       }
@}

When created by the Deployer, we set up the sit target and start
listening for messages from the Deployer.  We send a {\tt PLANTED}
message back to the Deployer on its message channel informing it that
we're running and letting it know the key it can use to direct messages
to us.  We save the Deployer's key so we can pay attention only to
messages sent by our Deployer, ignoring any that may be sent on the
same channel by other Deployers in the region.

@d Planet object script@'@'@'@'@'@'
@{
        on_rez(integer start_param) {
            initState = 0;

            //  If start_param is zero, this is a simple manual rez
            if (start_param != 0) {
                if (start_param == -1) {
                    start_param = 0;
                }
                m_index = start_param;

                ourName = llGetObjectName();
                deployer = llList2Key(llGetObjectDetails(llGetKey(),
                                         [ OBJECT_REZZER_KEY ]), 0);

                //  Set sit target

                llSitTarget(<-0.8, 0, 0>, llAxisAngle2Rot(<0, 1, 0>, -PI_BY_TWO));
                llSetCameraEyeOffset(<-1.2, 0, -1.2>);
                llSetCameraAtOffset(<-1, 0, 1>);

                //  Listen for messages from deployer
                llListen(@<massChannel@>, "", NULL_KEY, "");

                //  Inform the deployer that we are now listening
                llRegionSayTo(deployer, massChannel,
                    llList2Json(JSON_ARRAY, [ "PLANTED", m_index ]));

                initState = 1;          // Waiting for SETTINGS and INIT
            }
        }
@}

We listen for messages from the Deployer.  These messages provide
configuration, settings, and position updates.  We check whether the
message was by our Deployer and ignore it if it's from another which
happens to be in the same region.

@d Planet object script@'@'@'@'@'@'
@{
        listen(integer channel, string name, key id, string message) {
//llOwnerSay("Planet " + llGetScriptName() + " channel " + (string) channel + " id " + (string) id +  " message " + message);

            if (channel == @<massChannel@>) {
                list msg = llJson2List(message);
                string ccmd = llList2String(msg, 0);

                if (id == deployer) {
                @<Process planet ``ypres'' message to self-destruct@'tellSat(message); llSleep(0.25);@'@>
                @<Process planet {\tt COLLIDE} message@>
                @<Process planet {\tt LIST} message@>
@}

The {\tt PINIT} message is sent by the Deployer in reply to our {\tt
PLANTED} greeting.  It provides information we need to configure
ourselves which wouldn't fit in the single integer the deployer gets to
pass us when rezzed.  This information includes the scale factor we use
to scale the globe to the desired in-world size, the position of the
Deployer, which lets us know the location of the Sun, and the base
epoch we use for rotation of the planet (for planets which do not have
precisely-defined local time).  We scale the planet and orient its
north pole to the celestial co-ordinates defined in its {\tt planet}
list.

@d Planet object script@'@'@'@'@'@'
@{
                    } else if (ccmd == "PINIT") {
                        if (m_index == llList2Integer(msg, 1)) {
                            m_name = llList2String(msg, 2);             // Name
                            deployerPos = sv(llList2String(msg, 3));    // Deployer position
                            m_scalePlanet = siuf(llList2String(msg, 4));    // Planet scale
                            m_scaleStar =  siuf(llList2String(msg, 5)); // Star scale
                            m_jd = llList2Integer(msg, 6);              // Epoch Julian day
                            m_jdf = siuf(llList2String(msg, 7));        // Epoch Julian day fraction
                            rotEpoch = [ m_jd, m_jdf ];                 // Base epoch for rotation

                            //  Set properties of object
                            float oscale = m_scalePlanet;
                            if (m_index == 0) {
                                oscale = m_scaleStar;
                            }

                            //  Compute size of body based upon scale factor

                            vector psize = < llList2Float(planet, 16),
                                             llList2Float(planet, 15),
                                             llList2Float(planet, 15) > * 0.0001 * oscale;

                            //  Calculate rotation to correctly orient north pole

                            npRot = rotPole(m_jd, m_jdf);

                            //  Set identity of body container
                            llSetLinkPrimitiveParamsFast(LINK_THIS, [
                                PRIM_DESC,  llList2Json(JSON_ARRAY,
                                    [ m_index, m_name, eff(llList2Float(planet, 17)) ])
, PRIM_ROTATION, ZERO_ROTATION    // TAKE OUT INITIAL ROTATION OF LEGACY REZ CODE
                            ]);


                            //  Set scale and orientation of globe
                            llSetLinkPrimitiveParamsFast(lGlobe, [
                                PRIM_SIZE, psize,           // Scale to proper size
                                PRIM_ROT_LOCAL, npRot       // Rotate north pole to proper orientation
                            ]);
                            @1
                            llSetStatus(STATUS_PHANTOM | STATUS_DIE_AT_EDGE, TRUE);

                            tellSat(message);
                            initState = 2;                  // INIT received, waiting for SETTINGS
                        }
@}

The {\tt SETTINGS} message is sent by the deployer after the {\tt
PINIT} message to deliver initial settings to the planet and then
subsequently whenever the user changes a setting that affects planets
with the Set command.  We forward these settings to satellites so
they may respond to them.

@d Planet object script@'@'@'@'@'@'
@{
                    } else if (ccmd == "SETTINGS") {
                        integer bn = llList2Integer(msg, 1);
                        if ((bn == 0) || (bn == m_index)) {
                            integer o_labels = s_labels;

                            paths = llList2Integer(msg, 2);
                            s_trace = llList2Integer(msg, 3);
                            s_kaboom = siuf(llList2String(msg, 4));
                            s_auscale = siuf(llList2String(msg, 5));
                            s_trails = llList2Integer(msg, 7);
                            s_pwidth = siuf(llList2String(msg, 8));
                            s_mindist = siuf(llList2String(msg, 9));
                            s_labels = llList2Integer(msg, 21);
                            s_satShow = llList2Integer(msg, 22);
                            tellSat(message);

                            //  Update label if state has changed
                            if (s_labels != o_labels) {
                                if (s_labels) {
                                    updateLegendPlanet((llGetPos() -
                                        deployerPos) / s_auscale);
                                } else {
                                    llSetLinkPrimitiveParamsFast(lGlobe, [
                                        PRIM_TEXT, "", ZERO_VECTOR, 0 ]);
                                }
                            }
                        }

                        if (initState == 2) {
                            initState = 3;
                        }

                        //  Set or clear particle trail depending upon paths
                        @<Trace path with particle system @{llList2Vector(planet, 27)@}@>
@}

The {\tt UPDATE} message is relatively simple for a planet, since the
deployer, in conjunction with the ephemeris module for the planet,
performs all of the calculations to determine the planet's position
and simply passes a vector giving its new heliocentric rectangular
co-ordinates.  We test whether the planet has moved beyond the
``kaboom'' distance and self-destruct if so.  The update message and
date are forwarded to satellites so they can update their positions
and rotations.

@d Planet object script@'@'@'@'@'@'
@{
                    } else if (ccmd == "UPDATE") {
                        vector p = llGetPos();
                        vector npos = sv(llList2String(msg, 2));
                        float dist = llVecDist(p, npos);

                        integer jd = llList2Integer(msg, 3);
                        float jdf = siuf(llList2String(msg, 4));
if (s_trace) {
    tawk(m_name + ": Update pos from " + (string) p + " to " + (string) npos +
        " dist " + (string) dist);
}
                        if ((s_kaboom > 0) &&
                            ((llVecDist(npos, deployerPos) / s_auscale) > s_kaboom)) {
                            kaboom(llList2Vector(planet, 27));
                            return;
                        }
                        if (dist >= s_mindist) {
                            llSetLinkPrimitiveParamsFast(LINK_THIS,
                                [ PRIM_POSITION, npos ]);
//                            if (paths) {
//                                llSetLinkPrimitiveParamsFast(LINK_THIS,
//                                    [ PRIM_ROTATION, llRotBetween(<0, 0, 1>, (npos - p)) ]);
//                            }
                            if (s_trails) {
                                flPlotLine(p, npos,llList2Vector(planet, 27), s_pwidth);
                            }
                        }
                        //  Rotate globe.  We don't rotate rings since you can't notice
                        llSetLinkPrimitiveParamsFast(lGlobe, [
                            PRIM_ROT_LOCAL, rotHour@3(jd, jdf)
                        ]);

                        updateLegendPlanet((npos - deployerPos) / s_auscale);
                        @2
                        updateSat(jd, jdf);     // Update position and rotation of satellites
@}

The {\tt VERSION} message requests this script to check its build
number against that of the Deployer and report any discrepancy.

@d Planet object script@'@'@'@'@'@'
@{
                    @<Check build number in created objects@>
                        @<Forward build number check to objects we've created@>
                        tellSat(message);
                    }
                }
            }
        }
     }
@}

\subsection{Ephemerides}

The positions of the planets (with the exception of Pluto) are
computed using the VSOP87 planetary theory, which directly
computes the ecliptical longitude, latitude, and radius
(termed $L$, $B$, and $R$) from a series of periodic terms
which are applied to the first five powers of the time
difference $\tau$ between the desired time and J2000 (Julian day
2451545.0).

In order to make the ephemeris-calculating scripts fit in the 64 Kb
LSL script memory space, we have truncated some of the least
significant terms in some of the series for the giant planets.
In practice, this results in no more loss of precision than
LSL's single precision arithmetic.  Not all sets of ephemerides
require the higher powers of some terms, so we specify the
evaluators separately and include only those we need for
the ephemeris we're calculating.  We take care to sum the terms
in order of magnitude from smaller to larger to minimise
truncation and round-off.

To generate these without a lot of duplication of code, we
exploit one of the lesser-known and more arcane features of
Nuweb: fragment arguments.  The ``Generic term evaluator''
fragment generates an evaluator for a term and power specified
by its arguments.  We then invoke this to generate the five
evaluators for each of the terms, which are used in the
ephemeris calculator for a specific planet.

\subsubsection{Periodic term evaluators}

@d Generic ephemeris term evaluator @'TERM@' @'SERIES@' @'TAUn@'
@{
    n = llGetListLength(term@1@2);
    x = 0;
    for (i = n - 3; i >= 0; i -= 3) {
        x += llList2Float(term@1@2, i) *
            llCos(llList2Float(term@1@2, i + 1) +
                  llList2Float(term@1@2, i + 2) * tau);
    }
    @1 += x * @3;
@}

@d Ephemeris term evaluator L0
@{
@<Generic ephemeris term evaluator @{L@} @{0@} @{1@}@>
@}

@d Ephemeris term evaluator L1
@{
@<Generic ephemeris term evaluator @{L@} @{1@} @{tau@}@>
@}

@d Ephemeris term evaluator L2
@{
@<Generic ephemeris term evaluator @{L@} @{2@} @{tau2@}@>
@}

@d Ephemeris term evaluator L3
@{
@<Generic ephemeris term evaluator @{L@} @{3@} @{tau3@}@>
@}

@d Ephemeris term evaluator L4
@{
@<Generic ephemeris term evaluator @{L@} @{4@} @{tau4@}@>
@}

@d Ephemeris term evaluator L5
@{
@<Generic ephemeris term evaluator @{L@} @{5@} @{tau5@}@>
@}

@d Ephemeris term evaluator B0
@{
@<Generic ephemeris term evaluator @{B@} @{0@} @{1@}@>
@}

@d Ephemeris term evaluator B1
@{
@<Generic ephemeris term evaluator @{B@} @{1@} @{tau@}@>
@}

@d Ephemeris term evaluator B2
@{
@<Generic ephemeris term evaluator @{B@} @{2@} @{tau2@}@>
@}

@d Ephemeris term evaluator B3
@{
@<Generic ephemeris term evaluator @{B@} @{3@} @{tau3@}@>
@}

@d Ephemeris term evaluator B4
@{
@<Generic ephemeris term evaluator @{B@} @{4@} @{tau4@}@>
@}

@d Ephemeris term evaluator B5
@{
@<Generic ephemeris term evaluator @{B@} @{5@} @{tau5@}@>
@}

@d Ephemeris term evaluator R0
@{
@<Generic ephemeris term evaluator @{R@} @{0@} @{1@}@>
@}

@d Ephemeris term evaluator R1
@{
@<Generic ephemeris term evaluator @{R@} @{1@} @{tau@}@>
@}

@d Ephemeris term evaluator R2
@{
@<Generic ephemeris term evaluator @{R@} @{2@} @{tau2@}@>
@}

@d Ephemeris term evaluator R3
@{
@<Generic ephemeris term evaluator @{R@} @{3@} @{tau3@}@>
@}

@d Ephemeris term evaluator R4
@{
@<Generic ephemeris term evaluator @{R@} @{4@} @{tau4@}@>
@}

@d Ephemeris term evaluator R5
@{
@<Generic ephemeris term evaluator @{R@} @{5@} @{tau5@}@>
@}

\subsubsection{Ephemeris link messages}

These link messages are used for communications between the deployer
and the ephemeris calculators for planets.

@d Ephemeris link messages
@{
    integer LM_EP_CALC = 431;           // Calculate ephemeris
    integer LM_EP_RESULT = 432;         // Ephemeris calculation result
    integer LM_EP_STAT = 433;           // Print memory status
@| LM_EP_CALC LM_EP_RESULT LM_EP_STAT @}

\subsubsection{Ephemeris calculator}

The ephemeris calculator evaluates the periodic terms for the planet
and returns the result.  To allow different numbers of terms to be used
by various planets, we provide a prologue and epilogue for the
calculator which are wrapped around the evaluation of terms.

@d Ephemeris calculator prologue
@{
    @<fixangr: Range reduce an angle in radians@>

    list posPlanet(integer jd, float jdf) {
        float tau = ((jd - @<J2000@>) / 365250.0) + (jdf / 365250.0);
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
@| posPlanet @}

@d Ephemeris calculator epilogue
@{
        return [ fixangr(L), B, R ];
    }
@}

\subsubsection{Ephemeris request processor position calculation}

When we receive an {\tt LM\_EP\_CALC} message, calculate the position
of the body for the specified date and return it to the requester
via an {\tt LM\_EP\_RESULT} message, identifying the recipient by the
{\tt handle} passed in the request.


@d Ephemeris request processor position calculation
@{
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
@}

\subsubsection{Ephemeris request processor memory status}

When requested, show script memory usage for this ephemeris
calculator in local chat.  We make this an option, since some
calculators which are close to the edge cannot afford to report
their parlous status.

@d Ephemeris request processor memory status
@{
//  LM_EP_STAT (433): Print memory status

} else if (num == LM_EP_STAT) {
    integer mFree = llGetFreeMemory();
    integer mUsed = llGetUsedMemory();
    llOwnerSay(llGetScriptName() + " status:" +
         " Script memory.  Free: " + (string) mFree +
            "  Used: " + (string) mUsed + " (" +
            (string) ((integer) llRound((mUsed * 100.0) / (mUsed + mFree))) + "%)"
    );
@}

\subsubsection{Ephemeris request processor}

This is the event handler for ephemeris scripts.  It processes
{\tt LM\_EP\_CALC} requests from the deployer and if the body
number in the request matches the one it supports, performs the
calculation and replies with an {\tt LM\_EP\_RESULT} with the
co-ordinates of the planet.

@d Ephemeris request processor@'MEMSTAT@'
@{
    default {
        state_entry() {
        }

        link_message(integer sender, integer num, string str, key id) {
            @<Auxiliary services messages@>
            @<Ephemeris request processor position calculation@>
            @<Check build number in Deployer scripts@>
            @1
            }
        }
    }
@}

\section{Satellites of planets}

With the exception of Earth's Moon (Luna), the position of planetary
satellites are computed from their orbital elements.  The following
code is common to all satellites.

\subsection{Compute satellite position from orbital elements}

Compute the satellite's position relative to its primary for the
specified Julian day and central body standard gravitational
parameter, returning its rectangular co-ordinates scaled to
region co-ordinates in the primary's local co-ordinate system.

@d Compute satellite position from orbital elements
@{
    vector lxyz = computeOrbit(s_elem, [ jd, jdf ], Gauss_k, 0);

    float s_satscale = 5e-5 * m_scalePlanet; // Scale factor, satellite orbit km to model metres
    vector mxyz = (lxyz * s_satscale) *
        (llEuler2Rot(<0, -PI_BY_TWO, 0>) * rotLaplace(jd, jdf));
//tawk(llGetScriptName() + " lxyz " + (string) lxyz + "  mxyz " + (string) mxyz   " s_auscale " + (string) s_auscale + "  s_satscale " + (string) (s_satscale * 1.0e7));
@}

\subsection{Tidal locking rotation}
\label{tidalLock}

Compute the rotation of a satellite to align its prime meridian with
the vector from the position of the satellite to the body it is
orbiting.  This accomplishes tidal locking of the satellite to the
primary.  Note that this is inexact for satellites in elliptical
orbits, as, rotating at a uniform speed, they will get ``ahead'' or
``behind'' depending upon their position in the orbit, even if the
mean rotation speed equals the orbital period.  (This is one of the
causes of lunar librations.)  But since most of the principal
satellites in the solar system are in near-circular orbits, geometric
tidal locking is ``close enough'' to appear correct at the scale at
which we are modeling.

@d tidalLock: Tidal locking rotation
@{
    rotation tidalLock(vector npos) {
        /*  Compute axis around which the body rotates.
            This axis is defined by the vector from its
            centre to the north pole.  */
        vector raxis = < 1, 0, 0 > * npRot;
        /*  The local Z axis (yes, I know, it doesn't make any
            sense, but bear with me) defines the prime meridian.
            This must be determined after applying to rotation
            to align the north pole in space.  */
        vector lfwd = llRot2Up(npRot);
        /*  The cross product of the normalised vector from the
            centre of the body to the centre of the primary (which,
            since the satellite is a child of the link set of
            which the primary is the root prim, is simply its local
            co-ordinates) and the rotation axis gives the normal to
            the plane defined by the rotation axis and the vector
            to the primary, passing through its centre.  */
        vector xnorm = raxis % llVecNorm(npos);
        /*  Now, our task is to rotate the satellite around its
            axis of rotation (raxis) so as to make the prime
            meridian vector (lfwd) fall within the plane to
            which xnorm is the normal.  The dot product of
            these two vectors is the cosine of the angle
            between them.  */
        float tang = PI_BY_TWO - llAcos(lfwd * xnorm); // Angle from prime meridian to axis-primary plane
        /*  The angle, tang, computed above, does not take into
            account whether the prime meridian vector, projected
            upon the line containing the centre of the satellite
            and primary, is parallel or anti-parallel to the
            vector from the centre of the satellite to the
            primary.  We compute the angle between these two
            vectors from their dot product, and then test
            their direction using the magnitude of this angle.  */
        float fpxa = llAcos(lfwd * llVecNorm(npos));
        if (fpxa < PI_BY_TWO) {
            tang = -(PI + tang);
        }
//tawk("npos " + (string) npos + " lfwd " + (string) lfwd + " tang " + (string) (tang * RAD_TO_DEG) + " ivang " + (string) (ivang * RAD_TO_DEG) + " flag " + (string) (ivang < PI_BY_TWO) + " fpxa " + (string) (fpxa * RAD_TO_DEG) + " totrot " + (string) (llRot2Euler(npRot * llAxisAngle2Rot(raxis, tang)) * RAD_TO_DEG));
        /*  Compose the prime meridian rotation with the
            north pole alignment rotation to obtain the
            complete satellite rotation.  */
        return npRot * llAxisAngle2Rot(raxis, tang);
    }
@| tidalLock @}

\subsection{Laplace plane orbit rotation}

Compute rotation to align satellite orbits with their local Laplace
plane.  Orbits of satellites of giant planets are often specified
relative to a Laplace plane which is specific to the satellite.  In
practice, these are very close to the planet's north pole direction,
but not identical. Here, we compute the rotation to transform orbit
positions to the Laplace plane.  Because the normal to the Laplace
plane is specified in equatorial co-ordinates, we require the date in
order to determine the obliquity of the ecliptic to transform to
ecliptic co-ordinates.

For planets whose satellite orbits are referenced to the planet's
equatorial plane, we simply enter its north pole co-ordinates as the
Laplace plane.

@d rotLaplace: Laplace plane orbit rotation
@{
    rotation rotLaplace(integer jd, float jdf) {
        float obleq = obliqeq(jd, jdf) * DEG_TO_RAD;    // Obliquity of the ecliptic
        vector npoled = llList2Vector(planet, 28);      // Laplace plane normal, degrees
        vector npoler = npoled * DEG_TO_RAD;            // Laplace plane normal, radians

        //  Tilt to declination
        rotation rpole = llEuler2Rot(<0, PI - npoler.y, 0>);

        //  Rotate to right ascension
        rpole = rpole * llEuler2Rot(<0, 0, npoler.x>);

        //  Tilt from equatorial to ecliptic plane
        rpole = rpole * llEuler2Rot(<-obleq, 0, 0>);

        /*  Compute normal to the Laplace plane.  */
        vector raxis = < -1, 0, 0 > * rpole;
        /*  The local Z axis (yes, I know, it doesn't make any
            sense, but bear with me) defines the prime meridian.
            This must be determined after applying to rotation
            to align the Laplace plane normal in space.  */
        vector lfwd = llRot2Up(rpole);
        /*  The cross product of the normalised vector from the
            centre of the body to zero latitude in ecliptic
            co-ordinates (its positive X axis) and the rotation
            axis gives us the normal to the plane defined by
            the plane normal and zero latitude.  */
        vector xnorm = raxis % < -1, 0, 0 >;
        /*  Now, our task is to rotate the globe around its
            axis of rotation (raxis) so as to make the prime
            meridian vector (lfwd) fall within the plane to
            which xnorm is the normal.  The dot product of
            these two vectors is the cosine of the angle
            between them.  */
        float tang = PI_BY_TWO - llAcos(lfwd * xnorm);
        /*  The angle, tang, computed above, does not take into
            account whether the prime meridian vector, projected
            upon the line containing the centre of the planet
            and ecliptic origin, is parallel or anti-parallel to the
            vector from the centre of the planet to the
            origin.  We compute the angle between these two
            vectors from their dot product, and then test
            their direction using the magnitude of this angle.  */
        float fpxa = llAcos(lfwd * < -1, 0, 0 >);
        if (fpxa < PI_BY_TWO) {
            tang = -(PI + tang);
        }
//tawk("raxis " + (string) raxis + " lfwd " + (string) lfwd + " xnorm " + (string) xnorm + " tang " + (string) (tang * RAD_TO_DEG) + " fpxa " + (string) (fpxa * RAD_TO_DEG) + " totrot " + (string) (llRot2Euler(rpole * llAxisAngle2Rot(raxis, tang)) * RAD_TO_DEG));
        /*  Compose the prime meridian rotation with the
            Laplace plane alignment rotation to obtain the
            complete orbit co-ordinate rotation.  */
        rpole = rpole * llAxisAngle2Rot(raxis, tang);
//tawk("rpole " + (string) (llRot2Euler(rpole) * RAD_TO_DEG));
        return rpole;
    }
@| rotLaplace @}

\subsection{Update satellite legend}

Updates the floating text legend for a satellite.  To avoid clutter, we
just display the name of the satellite in the same colour used for
tracing the path of its orbit.  If the satellite isn't visible, we
ignore all updates to the legend.

@d updateLegendSat: Update satellite floating text legend
@{
    updateLegendSat() {
//tawk("updateLegendSat() called");
        if (s_labels  && isSatVisible) {
//tawk("  Showing satellite legend");
            llSetLinkPrimitiveParamsFast(LINK_THIS, [
                PRIM_TEXT, llList2String(planet, 0),
                           llList2Vector(planet, 27), 1
            ]);
        }
    }
@| updateLegendSat @}

\subsection{Satellite object script components}

The following sections declare code which is common to the object
scripts of all planetary satellites, whether we compute their positions
from orbital elements or satellite-specific analytic theories.

\subsubsection{Satellite script global variables}

Declare global variables used in all satellite object scripts.  These
are mostly identical to major and minor planets, but we have a few more
of our own.

@d Satellite script global variables
@{
    @<Planet global variables@>

    rotation npRot;                     // Rotation to orient north pole

    integer m_jd;                       // Epoch Julian day
    float m_jdf;                        // Epoch Julian day fraction

    float startTime;                    // Time we were placed

    vector lastTrailP = ZERO_VECTOR;    // Last trail path point
@}

\subsubsection{Satellite script common functions}

These functions are used by all satellite scripts.  Those which
compute their position from orbital elements require additional
functions, declared separately.

@d Satellite script common functions
@{
    @<sv: Decode base64-encoded vector@>
    @<siuf: Decode base64-encoded floating point number@>

    @<eff: Edit float to readable representation@>
    @<efv: Edit vector to readable representation@>
    @<ef: Edit floating point number to readable representation@>

    @<l2r: Transform local to region co-ordinates@>

    @<obliqeq: Obliquity of the ecliptic@>

    @<rotPole: Align north pole@>
    @<tidalLock: Tidal locking rotation@>

    @<updateLegendSat: Update satellite floating text legend@>

    @<flRezRegion: Rez object anywhere in region@>
    @<flPlotLine: Plot line in space@>

    @<tawk: Send a message to the interacting user in chat@>
/*
@<dumpOrbitalElements: Dump orbital elements@>
*/
@}

\subsubsection{Show or hide satellite}

When the user enters a ``Set Satellite'' command affecting the planet
we orbit, the planet receives the {\tt SETTINGS} message from the
deployer and forwards it to its satellites via an {\tt LM\_PS\_DEPMSG}
message.  When we receive this message, if it applies to the planet
we orbit, this function is called with the visibility specified by
our planet's bit in the visibility mask.  If the visibility state has
changed, we respond as follows.

If we've become invisible, make the satellite transparent and hide it
at the centre of the planet, clearing {\tt isSatVisible}, which will
suppress subsequent {\tt UPDATE} messages forwarded by the planet.  If
we've just become visible, make the satellite visible again but leave
it at the centre of the planet until the next {\tt UPDATE} causes its
position to be computed and it to be moved to the correct position.

We clear any floating text legend above the satellite so it doesn't
poke out from the planet and set {\tt s\_labels} to {\tt FALSE} so that
if it's set when the satellite is made visible again it will be
restored.  Note that since all satellites are textured, we can assume
their colour it set to white and don't need to save and restore it when
changing tranparency.

@d setSatelliteVisibility: Show or hide satellite
@{
    integer isSatVisible = FALSE;           // Is satellite visible ?

    setSatelliteVisibility(integer visible) {
//tawk("Satellite visibility: " + (string) visible);
        if (visible != isSatVisible) {
            isSatVisible = visible;
            if (isSatVisible) {
//tawk("  Setting satellite visible.");
                //  Satellite is now visible
                llSetLinkPrimitiveParamsFast(LINK_THIS, [
                            PRIM_COLOR, ALL_SIDES, @<Colour:9:white@>, 1 ]);
                if (s_labels) {
                    updateLegendSat();
                }
            } else {
//tawk("  Setting satellite invisible.");
                //  Satellite is now invisible
                llSetLinkPrimitiveParamsFast(LINK_THIS, [
                            PRIM_COLOR, ALL_SIDES, @<Colour:9:white@>, 0,
                            PRIM_POS_LOCAL, ZERO_VECTOR,
                            PRIM_TEXT, "", ZERO_VECTOR, 0 ]);
                s_labels = FALSE;
            }
        }
    }
@| setSatelliteVisibility @}

\subsubsection{Satellite script {\tt on\_rez} event handler}

The {\tt on\_rez} function initialises the satellite object's
properties when its parent planet is created.

@d Satellite script {\tt on\_rez} event handler
@{
    on_rez(integer start_param) {
        initState = 0;

        //  If start_param is zero, this is a simple manual rez
        if (start_param != 0) {
            if (start_param == -1) {
                start_param = 0;
            }
            m_index = start_param;

            ourName = llGetObjectName();
            deployer = llList2Key(llGetObjectDetails(llGetKey(),
                                     [ OBJECT_REZZER_KEY ]), 0);

            //  Set sit target

            llSitTarget(<-0.8, 0, 0>, llAxisAngle2Rot(<0, 1, 0>, -PI_BY_TWO));
            llSetCameraEyeOffset(<-1.2, 0, -1.2>);
            llSetCameraAtOffset(<-1, 0, 1>);

            initState = 1;          // Waiting for SETTINGS and INIT
        }
    }
@}

\subsubsection{Satellite script link message handler}

As a child prim of the planet, we do not listen directly for messages
from the Deployer, but rather rely on the planet to forward any which
are relevant to us.  These are received as link messages, identified by
a code in the {\tt num} parameter giving its type.  The {\tt
LM\_PS\_DEPMSG} code is used to directly forward messages, unmodified,
from the Deployer.

The argument supplies the code which calculates the satellite's
position from the date passed in the {\tt UPDATE} message.

@d Satellite script link message handler@'@'
@{
        link_message(integer sender, integer num, string str, key id) {
//tawk(llGetScriptName() + " link message sender " + (string) sender + "  num " + (string) num + "  str " + str + "  id " + (string) id);

            //  LM_PS_DEPMSG (811): Deployer message forwarded by primary

            if (num == LM_PS_DEPMSG) {
                list msg = llJson2List(str);
                string ccmd = llList2String(msg, 0);
@}

The ``{\tt ypres}'' (pronounced ``wipers'') message indicates it's time
to go: it is sent by the deployer when the user enters the Remove or
Boot commands.  Since the root prim's deleting itself also deletes all
child prims, we needn't worry about that, and need only forward the
message to any orbit tracing {\tt flPlotLine} objects we've created.
Since these objects only respond to {\tt ypres} messages from the
object that created them, it's up to us to pass along the bad news.
Since these objects are created temporary, if we don't delete them the
garbage collector will eventually clean them up, but it's nicer and
more responsive to get rid of them the moment the planet is deleted.

@d Satellite script link message handler@'@'
@{
                if (ccmd == ypres) {
                    if (s_trails) {
                        llRegionSay(@<massChannel@>,
                            llList2Json(JSON_ARRAY, [ ypres ]));
                    }
@}

The {\tt LIST} message simply displays information about the satellite
in local chat.  It also shows script memory usage, which lets
developers know when they're approaching the edge of the cliff.

@d Satellite script link message handler@'@'
@{
                } else if (ccmd == "LIST") {
                    integer mFree = llGetFreeMemory();
                    integer mUsed = llGetUsedMemory();

                    tawk("Mass " + (string) m_index +
                         "  Name: " + m_name +
                         "  Position: " + efv(llGetPos()) +
                         "\n    Script memory.  Free: " + (string) mFree +
                            "  Used: " + (string) mUsed + " (" +
                            (string) ((integer) llRound((mUsed * 100.0) / (mUsed + mFree))) + "%)"
                    );
@}

The {\tt PINIT} message is sent by the deployer when the planet is
created and passed on to us.  It provides the scale factor which
determines how we scale ourselves along with the planet and the
current date, which allows us to compute the obliquity of the ecliptic
which is required to correctly orient our north pole in space.

@d Satellite script link message handler@'@'
@{
                } else if (ccmd == "PINIT") {
                    m_index = llList2Integer(msg, 1);           // Index of planet we orbit
                    m_name = llList2String(msg, 2);             // Name
                    deployerPos = sv(llList2String(msg, 3));    // Deployer position
                    m_scalePlanet = siuf(llList2String(msg, 4));    // Planet scale
                    m_jd = llList2Integer(msg, 6);              // Epoch Julian day
                    m_jdf = siuf(llList2String(msg, 7));        // Epoch Julian day fraction

                    //  Set properties of object
                    float oscale = m_scalePlanet;

                    //  Compute size of body based upon scale factor

                    vector psize = < llList2Float(planet, 16),
                                     llList2Float(planet, 15),
                                     llList2Float(planet, 15) > * 0.0001 * oscale;

                    //  Calculate rotation to correctly orient north pole

                    npRot = rotPole(m_jd, m_jdf);

                    llSetLinkPrimitiveParamsFast(LINK_THIS, [
                        PRIM_DESC,  llList2Json(JSON_ARRAY,
                            [ m_index, m_name, eff(llList2Float(planet, 17)) ]),
                        PRIM_SIZE, psize,           // Scale to proper size
                        PRIM_ROT_LOCAL, npRot       // Rotate north pole to proper orientation
                    ]);
                    llSetStatus(STATUS_PHANTOM | STATUS_DIE_AT_EDGE, TRUE);

                    initState = 2;                  // INIT received, waiting for SETTINGS
@}

The {\tt SETTINGS} message is sent by the deployer initially and
whenever the user changes any relevant settings with a ``Set'' command.
Settings which affect our operation include whether our path is to be
traced by lines and whether a floating text label should be displayed
with our name.  The big setting is whether satellites should be
displayed at all: that must be processed before all others so that when
satellites are displayed everything else updates, either immediately or
on the next {\tt UPDATE} message.

@d Satellite script link message handler@'@'
@{
                } else if (ccmd == "SETTINGS") {
                    integer o_labels = s_labels;

                    paths = llList2Integer(msg, 2);
                    s_trace = llList2Integer(msg, 3);
                    s_kaboom = siuf(llList2String(msg, 4));
                    s_auscale = siuf(llList2String(msg, 5));
                    s_trails = llList2Integer(msg, 7);
                    s_pwidth = siuf(llList2String(msg, 8));
                    s_mindist = siuf(llList2String(msg, 9));
                    s_labels = llList2Integer(msg, 21);
                    s_satShow = llList2Integer(msg, 22);

                    //  Update visibility of this satellite
                    setSatelliteVisibility((s_satShow & (1 << m_index)) != 0);

                    //  Update label if state has changed
                    if (s_labels != o_labels) {
                        if (s_labels) {
                            updateLegendSat();
                        } else {
                            llSetLinkPrimitiveParamsFast(LINK_THIS, [
                                PRIM_TEXT, "", ZERO_VECTOR, 0 ]);
                        }
                    }

                    if (initState == 2) {
                        initState = 3;                  // INIT and SETTINGS received
                        startTime = llGetTime();        // Remember when we started
                    }

                    //  Set or clear particle trail depending upon paths
                    @<Trace path with particle system @{llList2Vector(planet, 27)@}@>

                    if (!s_trails) {
                        lastTrailP = ZERO_VECTOR;
                    }
@}

The {\tt VERSION} message requests this script to check its build
number against that of the Deployer and report any discrepancy.  This
message is forwarded by the planet of which we are a child link.

@d Satellite script link message handler@'@'
@{
                @<Check build number in created objects@>
                    @<Forward build number check to objects we've created@>
                }
@}

The {\tt LM\_PS\_UPDATE} link message is sent by the planet to all of
its satellites whenever it receives an update message from the
deployer.  While the deployer directly tells the planet its new
heliocentric position, satellites are on their own: the message
provides the current Julian day and fraction, and they must then
compute their new position from their orbital elements and move there.
All of the satellites we model are (or are believed to be) tidally
locked to their primaries: they (more or less) keep the same face
pointing toward the planet.  Astrogeologists have defined the prime
meridian on maps of satellites as the that facing toward the planet.
When updating the position, we use {\tt tidalLock()} (\ref{tidalLock})
to compute the rotation to orient the prime meridian toward the planet.

The argument to the macro provides the scrap which actually computes
the position of the satellite, allowing us to use either the standard
code which computes from the orbital elements or a specific method for
the satellite, as we do for Luna (Earth's Moon).  This code must
compute the position of the satellite (in ecliptic co-ordinates in a
local frame where the planet is at the origin) from the Julian day and
fraction in {\tt jd} and {\tt jdf} and set the vector {\tt mxyz} to the
satellite's position.

If the satellite is not visible, we ignore {\tt UPDATE} messages.

@d Satellite script link message handler@'@'
@{
            } else if (num == LM_PS_UPDATE) {
                if (isSatVisible) {
                    list msg = llJson2List(str);

                    integer jd = llList2Integer(msg, 0);
                    float jdf = siuf(llList2String(msg, 1));

                    //  Compute position of satellite (code from argument)
                    @1

                    //  Need to take out north pole rotation of primary body
                    vector npos = mxyz * (ZERO_ROTATION / llGetRootRotation());
                    llSetLinkPrimitiveParamsFast(LINK_THIS, [
                                PRIM_POS_LOCAL, npos,
                                PRIM_ROT_LOCAL, tidalLock(npos) ]);

//                  if (paths) {
//                      llSetLinkPrimitiveParamsFast(LINK_THIS,
//                          [ PRIM_ROTATION, llRotBetween(<0, 0, 1>, (npos - p)) ]);
//                  }
                    if (s_trails) {
                        vector trailP = l2r(npos);
                        if (lastTrailP != ZERO_VECTOR) {
                            flPlotLine(lastTrailP, trailP, llList2Vector(planet, 27), s_pwidth);
                        }
                        lastTrailP = trailP;
                    }
                }
            }
        }
@}

\subsection{Satellite object script}

This is the script included in the root prim of all planetary
satellites whose positions we calculate from their orbital elements
(which is, at this writing, all of them with the exception of Luna
[Earth's Moon], for which we use an analytic theory that takes into
account perturbations and is more accurate). The script is identical
for all satellites which use it, parameterised by values declared in
the satellite-specific {\tt planet} list that is declared before it in
the script.

We begin with a list of orbital elements in the form we use throughout
the program for evaluating positions in orbits.  It is filled in, with
values synthesised as required, from the parameters in the {\tt planet}
list declared previously.  None of the initial values in this list are
significant.

@d Satellite object script
@{
    list s_elem = [
        "Name",                 // 0    Name
        0, 0.0,                 // 1,2  epoch [ jd, jdf ]
        0.0,                    // 3    a (semi-major axis)
        0.0,                    // 4    e (eccentricity)
        0.0,                    // 5    i (inclination)
        0.0,                    // 6    ῶ (argument of periapse)
        0.0,                    // 7    Ω (longitude of ascending node)
        0.0,                    // 8    M (mean anomaly)
        0.0,                    // 9    H (magnitude)
        0.0,                    // 10   G (magnitude slope)
        0, 0.0,                 // 11,12 Tp (time of perhelion)
        0.0,                    // 13   q (periapse distance)
        0.0,                    // 14   n (mean motion)
        0.0,                    // 15   P (orbital period)
        0.0                     // 16   Q (apoapse distance)
    ];
@}

The following global variables are used in the code.

@d Satellite object script
@{

    float Gauss_k;          // Gaussian gravitational constant for planet

    @<Satellite script global variables@>
@}

We use the following link messages to communicate with the planet of
which we are a satellite (and are within the same link set).

@d Satellite object script
@{
    //  Link messages
    @<Planet link messages@>
@}

Declare all of the functions used in the script.

@d Satellite object script
@{

    @<Satellite script common functions@>

    /*  The following are used only for satellites whose positions we
        compute from orbital elements.  */
    @<sgn: Sign of argument@>
    @<Hyperbolic trigonometric functions@>
    @<gKepler: General motion in gravitational field@>
    @<computeOrbit: Compute position of body in orbit@>
    @<rotLaplace: Laplace plane orbit rotation@>

    //  Satellite-specific functions
    @<setSatelliteVisibility: Show or hide satellite@>
@}

We have only one state, {\tt default}.  Here we declare it, beginning
with the {\tt state\_entry()} event which runs when the planet is
created by the deployer.  The satellite, a child prim of the planet,
receives control at this time.

@d Satellite object script
@{
    default {

        state_entry() {
            whoDat = owner = llGetOwner();
@}

The following code synthesises the complete set of orbital elements
from those we've specified in the static declaration of {\tt planet} at
the top  This is adapted from the code in the {\tt
parseOrbitalElements()} (\ref{parseOrbitalElements}) function of Minor
Planets, with unneeded generality removed.

@d Satellite object script
@{
            s_elem = llListReplaceList(s_elem,
                [ llList2String(planet, 0),         // Nane
                  llList2Integer(planet, 2),        // Epoch, jd
                  llList2Float(planet, 25),         //        jdf
                  llList2Float(planet, 3),          // Semi-major axis, km
                  llList2Float(planet, 4),          // Eccentricity
                  llList2Float(planet, 5),          // Inclination, degrees
                  llList2Float(planet, 7),          // ω    Argument of periapsis, degrees
                  llList2Float(planet, 6),          // Ω    Longitude of the ascending node, degrees
                  llList2Float(planet, 8)           // Mean anomaly, degrees
                ], 0, 8);

            float m_a = llList2Float(s_elem, 3);
            float m_e = llList2Float(s_elem, 4);
            float m_M = llList2Float(s_elem, 8);

            /*  Compute the periapse date from the epoch,
                semi-major axis, and mean anomaly.  */

            float m_a_m = m_a * 1000;               // Semi-major axis, metres
            //  Orbital period, days
            float m_Tp = (TWO_PI *
                          llSqrt((m_a_m * m_a_m * m_a_m) /
                          llList2Float(planet, 26))) / 86400;
            float peridelta = m_Tp * m_M * (365.2422 / 360);
            integer pdi = llFloor(peridelta);
            peridelta -= pdi;
            integer pjd = llList2Integer(s_elem, 1) - pdi;
            float pjdf = llList2Float(s_elem, 2) - peridelta;
            while (pjdf < 0) {
                pjdf += 1;
                pjd--;
            }
            s_elem = llListReplaceList(s_elem, [ pjd, pjdf ], 11, 12);

            /*  Compute periapse distance from semi_major axis
                and eccentricity.  */
            s_elem = llListReplaceList(s_elem, [ m_a - (m_a * m_e) ], 13, 13);
            //  Update mean motion, orbital period, and apoapse distance
            s_elem = llListReplaceList(s_elem,
                [ 360 / m_Tp, m_Tp, (1 + m_e) * m_a ], 14, 16);
@}

The satellite's orbit around its primary is governed by the mass
of the primary, which we express as the Gaussian gravitational
constant $k$, called {\tt Gauss\_k} in the script.  It is
computed from the standard gravitational parameter for the
planet ($\mu = G M$) and scale factors to express distance
in kilometres and time in days.  The magic number, 7.46496,
in the equation is the unit scale factor:
\[
    \frac{{\rm SecondsPerDay}^2}{{\rm MetresPerKilometre}^3} =
    \frac{(60\times 60\times 24)^2}{1000^3}
\]

@d Satellite object script
@{
            Gauss_k = llSqrt(llList2Float(planet, 26) * 7.46496);
//dumpOrbitalElements(s_elem);
        }
@}

The {\tt on\_rez()} event is received when the Deployer creates the
planet object.  The satellite, as a child prim of the planet, receives
this event at that time.  All we do here is remember our name and
the key of the deployer that created us, then set the sit target
should somebody want to ``ride a moon''.  The business with the
{\tt start\_param} skips this when we're manually rezzed
from inventory (for example, by a developer wishing to work on the
object) as opposed to created by the Deployer.

@d Satellite object script
@{
    @<Satellite script {\tt on\_rez} event handler@>
@}

As a child prim of the planet, we do not listen directly for messages
from the Deployer, but rather rely on the planet to forward any which
are relevant to us.  These are received as link messages, identified by
a code in the {\tt num} parameter giving its type.  The {\tt
LM\_PS\_DEPMSG} code is used to directly forward messages, unmodified,
from the Deployer.

@d Satellite object script
@{
    @<Satellite script link message handler@<Compute satellite position from orbital elements@>@>
    }
@}

\section{Planet definitions}

\subsection{Sun}

\begin{wrapfigure}{r}{4cm}
\centering
\includegraphics[width=3.8cm]{figures/orbits_sun.png}
\end{wrapfigure}
Yes, I am aware that the Sun is not a planet, but endowing it with
a standard planet script allows it to ``play nice'' with the Deployer
and handle creation, scaling, polar orientation, and destruction with
no special case code required.  A great deal of the planet script
is not used for the Sun, but that doesn't cost us anything, as there's
plenty of space left in its script memory.  As the Sun is the origin
of our heliocentric co-ordinate system, it requires no ephemeris
calculator.  (If we used the solar system barycentre as the origin,
we'd need to compute the ``orbit of the Sun'', but we don't.)

@d Sun properties
@{
    list planet = [
        "Sun",              // 0  Name of body
        "",                 // 1  Primary

        //  Orbital elements
        @<J2000@>,          // 2  Epoch (J2000), integer to avoid round-off

        0,                  // 3  a    Semi-major axis, AU
        0,                  // 4  e    Eccentricity
        0,                  // 5  i    Inclination, degrees
        0,                  // 6  Ω    Longitude of the ascending node, degrees
        0,                  // 7  ω    Argument of periapsis, degrees
        0,                  // 8  L    Mean longitude, degrees

        //  Orbital element centennial rates
        0,                  // 9  a    AU/century
        0,                  // 10 e    e/century
        0,                  // 11 i    "/century
        0,                  // 12 Ω    "/century
        0,                  // 13 ω    "/century
        0,                  // 14 L    "/century

        //  Physical properties
        695700.0,           // 15 Equatorial radius, km
        695700.0,           // 16 Polar radius, km
        1.9885e30,          // 17 Mass, kg
        1.408,              // 18 Mean density, g/cm³
        274,                // 19 Surface gravity, m/s²
        617.7,              // 20 Escape velocity, km/s
        25.05,              // 21 Sidereal rotation period, days
        <286.13, 63.87, 0>, // 22 North pole, RA, Dec
        7.25,               // 23 Axial inclination, degrees
        4.83,               // 24 Albedo (Absolute magnitude for luminous objects)

        //  Extras
        0.0,                // 25 Fractional part of epoch
        @<GM:Sun@>,         /* 26 Standard gravitational parameter (G M)
                                  of primary, m^3/sec^2  */
        @<Colour:0:black@>  // 27 Colour of trail tracing orbit
    ];
@}

\subsubsection{Star object}

@o scripts/planets/sun.lsl
@{
    @<Explanatory header for LSL files@>

    @<Sun properties@>
    @<Planet object script@'@'@'@'@'@'@>
@}

\subsection{Mercury}

\begin{wrapfigure}{r}{4cm}
\centering
\includegraphics[width=3.8cm]{figures/orbits_mercury.png}
\end{wrapfigure}
Mercury is the innermost planet.  With no satellites, it has a simple
definition.

@d Mercury properties
@{
    list planet = [
        "Mercury",          // 0  Name of body
        "Sun",              // 1  Primary

        //  Orbital elements
        @<J2000@>,          // 2  Epoch (J2000), integer to avoid round-off

        0.38709893,         // 3  a    Semi-major axis, AU
        0.20563069,         // 4  e    Eccentricity
        7.00487,            // 5  i    Inclination, degrees
        48.33167,           // 6  Ω    Longitude of the ascending node, degrees
        77.45645,           // 7  ω    Argument of periapsis, degrees
        252.25084,          // 8  L    Mean longitude, degrees

        //  Orbital element centennial rates
        0.00000066,         // 9  a    AU/century
        0.00002527,         // 10 e    e/century
        -23.51,             // 11 i    "/century
        -446.30,            // 12 Ω    "/century
        573.57,             // 13 ω    "/century
        538101628.29,       // 14 L    "/century

        //  Physical properties
        2439.7,             // 15 Equatorial radius, km
        2439.7,             // 16 Polar radius, km
        3.3011e23,          // 17 Mass, kg
        5.427,              // 18 Mean density, g/cm³
        3.7,                // 19 Surface gravity, m/s²
        4.25,               // 20 Escape velocity, km/s
        58.646,             // 21 Sidereal rotation period, days
        <281.01, 61.41, 0>, // 22 North pole, RA, Dec
        2.04,               // 23 Axial inclination, degrees
        0.106,              // 24 Albedo

        //  Extras
        0.0,                // 25 Fractional part of epoch
        @<GM:Sun@>,         /* 26 Standard gravitational parameter (G M)
                                  of primary, m^3/sec^2  */
        @<Colour:1:brown@>  // 27 Colour of trail tracing orbit
    ];
@}

\subsubsection{Planet object}

@o scripts/planets/mercury/mercury.lsl
@{
    @<Explanatory header for LSL files@>

    @<Mercury properties@>
    @<Planet object script@'@'@'@'@'@'@>
@}

\subsubsection{Ephemeris}

@o scripts/planets/mercury/eph_mercury.lsl
@{
    @<Explanatory header for LSL files@>

    integer BODY = 1;               // Our body number

@<Mercury periodic terms@>

@<Ephemeris link messages@>

@<Ephemeris calculator prologue@>

    @<Ephemeris term evaluator L0@>
    @<Ephemeris term evaluator L1@>
    @<Ephemeris term evaluator L2@>
    @<Ephemeris term evaluator L3@>
    @<Ephemeris term evaluator L4@>
    @<Ephemeris term evaluator L5@>

    @<Ephemeris term evaluator B0@>
    @<Ephemeris term evaluator B1@>
    @<Ephemeris term evaluator B2@>
    @<Ephemeris term evaluator B3@>
    @<Ephemeris term evaluator B4@>

    @<Ephemeris term evaluator R0@>
    @<Ephemeris term evaluator R1@>
    @<Ephemeris term evaluator R2@>
    @<Ephemeris term evaluator R3@>

@<Ephemeris calculator epilogue@>

@<Ephemeris request processor@<Ephemeris request processor memory status@>@>
@}

\subsection{Venus}

\begin{wrapfigure}{r}{4cm}
\centering
\includegraphics[width=3.8cm]{figures/orbits_venus.png}
\end{wrapfigure}
Venus is the second planet from the Sun.  Its axial tilt of more than
$90^{\circ}$ causes its rotation to be retrograde with respect to its
orbit around the Sun.  This makes it a good test for north pole
orientation and rotation.

@d Venus properties
@{
    list planet = [
        "Venus",            // 0  Name of body
        "Sun",              // 1  Primary

        //  Orbital elements
        @<J2000@>,          // 2  Epoch (J2000), integer to avoid round-off

        0.72333199,         // 3  a    Semi-major axis, AU
        0.00677323,         // 4  e    Eccentricity
        3.39471,            // 5  i    Inclination, degrees
        76.68069,           // 6  Ω    Longitude of the ascending node, degrees
        131.53298,          // 7  ω    Argument of periapsis, degrees
        181.97973,          // 8  L    Mean longitude, degrees

        //  Orbital element centennial rates
        0.00000092,         // 9  a    AU/century
        -0.00004938,        // 10 e    e/century
        -2.86,              // 11 i    "/century
        -996.89,            // 12 Ω    "/century
        -108.80,            // 13 ω    "/century
        210664136.06,       // 14 L    "/century

        //  Physical properties
        6051.8,             // 15 Equatorial radius, km
        6051.8,             // 16 Polar radius, km
        4.8675e24,          // 17 Mass, kg
        5.243,              // 18 Mean density, g/cm³
        8.87,               // 19 Surface gravity, m/s²
        10.36,              // 20 Escape velocity, km/s
        −243.025,           // 21 Sidereal rotation period, days
        <272.76, 67.16, 0>, // 22 North pole, RA, Dec
        177.36,             // 23 Axial inclination, degrees
        0.65,               // 24 Albedo

        //  Extras
        0.0,                // 25 Fractional part of epoch
        @<GM:Sun@>,         /* 26 Standard gravitational parameter (G M)
                                  of primary, m^3/sec^2  */
        @<Colour:2:red@>    // 27 Colour of trail tracing orbit
    ];
@}

\subsubsection{Planet object}

@o scripts/planets/venus/venus.lsl
@{
    @<Explanatory header for LSL files@>

    @<Venus properties@>
    @<Planet object script@'@'@'@'@'@'@>
@}

\subsubsection{Ephemeris}

@o scripts/planets/venus/eph_venus.lsl
@{
    @<Explanatory header for LSL files@>

    integer BODY = 2;               // Our body number

@<Venus periodic terms@>

@<Ephemeris link messages@>

@<Ephemeris calculator prologue@>

    @<Ephemeris term evaluator L0@>
    @<Ephemeris term evaluator L1@>
    @<Ephemeris term evaluator L2@>
    @<Ephemeris term evaluator L3@>
    @<Ephemeris term evaluator L4@>
    @<Ephemeris term evaluator L5@>

    @<Ephemeris term evaluator B0@>
    @<Ephemeris term evaluator B1@>
    @<Ephemeris term evaluator B2@>
    @<Ephemeris term evaluator B3@>
    @<Ephemeris term evaluator B4@>

    @<Ephemeris term evaluator R0@>
    @<Ephemeris term evaluator R1@>
    @<Ephemeris term evaluator R2@>
    @<Ephemeris term evaluator R3@>
    @<Ephemeris term evaluator R4@>

@<Ephemeris calculator epilogue@>

@<Ephemeris request processor@<Ephemeris request processor memory status@>@>
@}

\subsection{Earth}

\begin{wrapfigure}{r}{4cm}
\centering
\includegraphics[width=3.8cm]{figures/orbits_earth.png}
\end{wrapfigure}
Earth is in some ways the most complicated and special-case-prone of
our planet models.  For its satellite, Luna, we do not compute the
position from its orbital elements but instead use a more accurate
analytic theory which accounts for the principal perturbations that
affect its position.  Luna is tidally locked to the Earth, and is a
good test case for that mechanism.  Finally, the Earth's rotation is
not done by na\"\i ve extrapolation of its rotation rate but by
accurate computation of Greenwich Mean Sidereal time and orienting
the prime meridian correctly in space, resulting in the planet's
actual sub-solar point facing the Sun.

@d Earth properties
@{
    list planet = [
        "Earth",            // 0  Name of body
        "Sun",              // 1  Primary

        //  Orbital elements
        @<J2000@>,          // 2  Epoch (J2000), integer to avoid round-off

        1.00000011,         // 3  a    Semi-major axis, AU
        0.01671022,         // 4  e    Eccentricity
        0.00005,            // 5  i    Inclination, degrees
        -11.26064,          // 6  Ω    Longitude of the ascending node, degrees
        102.94719,          // 7  ω    Argument of periapsis, degrees
        100.46435,          // 8  L    Mean longitude, degrees

        //  Orbital element centennial rates
        -0.00000005,        // 9  a    AU/century
        -0.00003804,        // 10 e    e/century
        -46.94,             // 11 i    "/century
        -18228.25,          // 12 Ω    "/century
        1198.28,            // 13 ω    "/century
        129597740.63,       // 14 L    "/century

        //  Physical properties
        6378.1,             // 15 Equatorial radius, km
        6356.8,             // 16 Polar radius, km
        5.97237e24,         // 17 Mass, kg
        5.514,              // 18 Mean density, g/cm³
        9.80665,            // 19 Surface gravity, m/s²
        11.186,             // 20 Escape velocity, km/s
        0.99726968,         // 21 Sidereal rotation period, days
        <0, 90, 0>,         // 22 North pole, RA, Dec
        23.4392811,         // 23 Axial inclination, degrees
        0.367,              // 24 Albedo

        //  Extras
        0.0,                // 25 Fractional part of epoch
        @<GM:Sun@>,         /* 26 Standard gravitational parameter (G M)
                                  of primary, m^3/sec^2  */
        @<Colour:3:orange@> // 27 Colour of trail tracing orbit
    ];
@}

\subsubsection{Earth-specific updates}

Here we handle updates to the planet which are specific to Earth.

\paragraph{Update Earth texture when month changes}

For the Earth globe's texture, we use the NASA Earth Observatory Blue
Marble Monthly cloudless Earth images which, for each of the 12 months,
which show representative vegetation and snow and ice cover for the
middle of the month.  When the month of simulation time changes, we
swap the current texture for the texture of the new month.  This causes
some blurry action on the display of the globe for around a second, but
extensive investigation leads me to conclude that this is inherent in
the design of the viewer (both Firestorm and the Second Life standard)
which no script-level work-around can ameliorate.

@d updateTextureEarth: Update texture when month changes
@{
    integer currentMonth = -1;              // Current month texture

    updateTextureEarth(integer jd, float jdf) {
        list yymmdd = jyearl([ jd, jdf ]);
        if (llList2Integer(yymmdd, 1) != currentMonth) {
            currentMonth = llList2Integer(yymmdd, 1);
            llSetLinkPrimitiveParamsFast(lGlobe,
                [ PRIM_TEXTURE, ALL_SIDES,
                  "Earth_Day_" + llGetSubString("0" +
                    (string) currentMonth, -2, -1),
                  <1, 1, 1>, <0.75, 0, 0>, 3 * PI_BY_TWO ]);
        }
    }
@| updateTextureEarth @}

\paragraph{Rotate Earth to correct hour angle}

While for most planets we assume an arbitrary starting meridian
position and rotate from there, for Earth, whose rotation is known with
exquisite precision, we use the formula for Greenwich Mean Sidereal
time to compute the orientation of Earth's prime meridian in space and
then rotate accordingly.

@d rotHourEarth: Rotate Earth to correct hour angle
@{
    rotation rotHourEarth(integer jd, float jdf) {
        /*  Compute axis around which the body rotates.
            This axis is defined by the vector from its
            centre to the north pole.  */
        vector raxis = < 1, 0, 0 > * npRot;
        float gst = gmstx(jd, jdf);             // Hour angle at Greenwich
        float gangle = TWO_PI * (gst / 24);     // Rotation angle of prime meridian
        /*  Compose the prime meridian rotation with the
            north pole alignment rotation to obtain the
            complete satellite rotation.  */
        return npRot * llAxisAngle2Rot(raxis, -gangle);
    }
@}

\subsubsection{Planet object}

@o scripts/planets/earth/earth.lsl
@{
    @<Explanatory header for LSL files@>

    @<Earth properties@>

    @<jyearl: Julian day and fraction to Gregorian date@>
    @<gmstx: Julian day to Greenwich Mean Sidereal Time@>

    @<updateTextureEarth: Update texture when month changes@>
    @<rotHourEarth: Rotate Earth to correct hour angle@>

    @<Planet object script@'@'@'updateTextureEarth(jd, jdf);@'@'Earth@'@>
@}

\subsubsection{Ephemeris}

@o scripts/planets/earth/eph_earth.lsl
@{
    @<Explanatory header for LSL files@>

    integer BODY = 3;               // Our body number

@<Earth periodic terms@>

@<Ephemeris link messages@>

@<Ephemeris calculator prologue@>

    @<Ephemeris term evaluator L0@>
    @<Ephemeris term evaluator L1@>
    @<Ephemeris term evaluator L2@>
    @<Ephemeris term evaluator L3@>
    @<Ephemeris term evaluator L4@>
    @<Ephemeris term evaluator L5@>

    @<Ephemeris term evaluator B0@>
    @<Ephemeris term evaluator B1@>

    @<Ephemeris term evaluator R0@>
    @<Ephemeris term evaluator R1@>
    @<Ephemeris term evaluator R2@>
    @<Ephemeris term evaluator R3@>
    @<Ephemeris term evaluator R4@>

@<Ephemeris calculator epilogue@>

@<Ephemeris request processor@<Ephemeris request processor memory status@>@>
@}

\subsubsection{Satellites}

\paragraph{Luna}

The implementation of the model for Luna (Earth's Moon) is quite
different than other satellites of the Solar System.  The approximate
positions of other satellites are computed from their orbital elements.
Since the orbit of Luna is so fantastically complicated, due to
perturbations from the Sun and other planets, and known to very high
precision through laser retroreflector measurements, it is typically
computed using very complicated sets of periodic terms, much like the
orbits of the planets.  Given the constraints of LSL script memory and
single precision floating point arithmetic, we opt for a lower
precision calculation which is still more than adequate to show the
Moon in its proper relationship with the Earth at any given time, and
still far more accurate than a naïve calculation from mean orbital
elements.

\subparagraph{Satellite properties}

As noted above, the orbital elements in this list are not actually used
in computing the position of Luna: they are the mean ecliptic orbital
elements from the JPL “Planetary Satellite Mean Orbital Parameters”
database, and included for purposes of documentation and completeness.

@d Luna properties
@{
    list planet = [
        "Luna",           // 0  Name of body
        "Earth",          // 1  Primary

        //  Orbital elements (ecliptical)
        @<J2000@>,          // 2  Epoch (J2000), integer to avoid round-off
        384400,             // 3  a    Semi-major axis, km
        0.0554,             // 4  e    Eccentricity
        5.16,               // 5  i    Inclination, degrees
        125.08,             // 6  Ω    Longitude of the ascending node, degrees
        318.15,             // 7  ω    Argument of periapsis, degrees
        135.27,             // 8  M    Mean anomaly, degrees

        //  Orbital element precession periods
        0,                  // 9  a
        0,                  // 10 e
        0,                  // 11 i
        18.6,               // 12 Ω    Precession period/years
        5.997,              // 13 ω    Precession period/years
        0,                  // 14 M

        //  Physical properties
        1738.1,             // 15 Equatorial radius, km
        1736.0,             // 16 Polar radius, km
        7.342e22,           // 17 Mass, kg
        3.344,              // 18 Mean density, g/cm³
        1.62,               // 19 Surface gravity, m/s²
        2.38,               // 20 Escape velocity, km/s
        27.321661,          // 21 Sidereal rotation period, days
        <266.86, 65.64, 0>, // 22 North pole, RA, Dec
        1.5424,             // 23 Axial inclination, degrees
        0.136,              // 24 Albedo

        //  Extras
        0.5,                // 25 Fractional part of epoch
        @<GM:Earth@>,       /* 26 Standard gravitational parameter (G M)
                                  of primary, m^3/sec^2  */
        @<Colour:1:brown@>, // 27 Colour of trail tracing orbit
        <266.86, 65.64, 0>      // 28 Laplace plane of orbit: RA, Dec, Tilt
    ];
@}

\subparagraph{Luna simplified Kepler equation solver}

Computing the low-eccentricity orbit of Luna does not require the
complexity of our main Kepler equation solver, {\tt gKepler}.  To
avoid complicating the calculations in {\tt lowmoon} to provide
the arguments it requires, we employ the following rudimentary
iterative solver for the equation of Kepler.

@d lunaKepler: Luna simplified Kepler equation solver
@{
   float lunaKepler(float m, float ecc) {
        float e;
        float delta;
        float EPSILON = 1e-6;

        e = m = m * DEG_TO_RAD;
        do {
            delta = e - ecc * llSin(e) - m;
            e -= delta / (1 - ecc * llCos(e));
        } while (llFabs(delta) > EPSILON);
        return e;
    }
@}

\subparagraph{Luna position calculation}

This function performs a low-precision calculation of the position of
the Moon. We return a list containing ecliptic longitude, latitude, and
radius vector (distance) of the Moon.

@d lowmoon: Luna position calculation
@{
    list lowmoon(integer jd, float jdf) {

        // Elements of the Moon's orbit

        float Epoch = 2444238.5;    // Epoch: 1980-01-01 00:00 UTC
        float l0 = 64.975464;       // Moon's mean longitude
        float P0 = 349.383063;      // Mean longitude of the perigee
        float N0 = 151.950429;      // Mean longitude of the node
        float i  = 5.145396;        // Inclination
        float e  = 0.054900;        // Eccentricity
        float a  = @<MoonSemiMaj@>; // Moon's semi-major axis, km

        //  Elements of the Sun's apparent orbit

        float Epg = 278.833540;     // Ecliptic longitude
        float Omg = 282.596403;     // Ecliptic longitude of perigee
        float Es = 0.016718;        // Eccentricity

        float D = (jd - Epoch) + jdf;

        //              For the Sun

        float Ns = ((360.0 / 365.2422) * D);    // Circular orbit position
        float M = fixangle(Ns + Epg - Omg);     // Mean anomaly
        float sEc = lunaKepler(M, Es);          // Solve equation of Kepler
        sEc = llSqrt((1 + Es) / (1 - Es)) * llTan(sEc / 2);
        sEc = 2 * llAtan2(sEc, 1) * RAD_TO_DEG; // True anomaly
        float Las = fixangle(sEc + Omg);        // Sun's geocentric ecliptic longitude

        //              For the Moon

        float l = fixangle((13.1763966 * D) + l0);      // Mean longitude
        float Mm = fixangle(l - (0.1114041 * D) - P0);  // Mean anomaly
        float N = fixangle(N0 - 0.0529539 * D);         // Ascending node mean longitude
        float C = l - Las;                              // Correction for evection
        float Ev = 1.2739 * llSin(((2 * C) - Mm) * DEG_TO_RAD);  // Evection
        float Ae = 0.1858 * llSin(M * DEG_TO_RAD);      // Annual equation
        float A3 = 0.37 * llSin(M * DEG_TO_RAD);        // Third correction

        float Mpm = fixangle(Mm + Ev - Ae - A3);        // Corrected anomaly M'm
        float Ec = fixangle(6.2886 * llSin(Mpm * DEG_TO_RAD));   // Correction for equation of the centre
        float A4 = 0.214 * llSin(2 * Mpm * DEG_TO_RAD); // Fourth correction
        float lp = fixangle(l + Ev + Ec - Ae + A4);     // Corrected longitude
        float V = fixangle(0.6583 * llSin((2 * (lp - Las)) * DEG_TO_RAD));  // Variation

        float lpp = fixangle(lp + V);                   // True orbital longitude
        float Np = fixangle(N - (0.16 * llSin(M * DEG_TO_RAD)));    // Corrected longitude of the node
        float lm = (llAtan2(llSin((lpp - Np) * DEG_TO_RAD) * llCos(i * DEG_TO_RAD), // Ecliptic latitude
            llCos((lpp - Np) * DEG_TO_RAD)) * RAD_TO_DEG) + Np;
        // Ecliptic longitude
        float bm = llAsin(llSin(fixangle(lpp - Np) * DEG_TO_RAD) * llSin(i * DEG_TO_RAD)) * RAD_TO_DEG;

        float Rh = (a * (1 - (e * e))) /           // Radius vector (km)
            (1 + (e * llCos(fixangle(Mpm + Ec) * DEG_TO_RAD)));

        return [ 0, 0, Rh, lm, bm ];
    }
@}

\subparagraph{Compute position of Luna}

@d Compute position of Luna
@{
    list lp = lowmoon(jd, jdf);
    vector lxyz = sphRect(llList2Float(lp, 3) * DEG_TO_RAD,     // L
                          llList2Float(lp, 4) * DEG_TO_RAD,     // B
                          llList2Float(lp, 2));                 // R

    float s_satscale = 1.75e-6 * m_scalePlanet; // Scale factor, satellite orbit km to model metres
    vector mxyz = lxyz * s_satscale;
//tawk("Moon lp " + llList2CSV(lp) + "  lxyz " + (string) lxyz + "  mxyz " + (string) mxyz +
// " s_auscale " + (string) s_auscale + "  s_satscale " + (string) (s_satscale * 1.0e7));
@}

\subparagraph{Luna object script}

This is the object script for Luna, which is unique to that body.  Its
general structure follows that of the {\tt Satellite object script}
we use for other satellites, with special case code for Luna where
appropriate.

@o scripts/planets/earth/luna/luna.lsl
@{
    @<Explanatory header for LSL files@>

    @<Luna properties@>

    //  Functions specific to Luna position calculation
    @<fixangle: Range reduce an angle in degrees@>
    @<lunaKepler: Luna simplified Kepler equation solver@>
    @<sphRect: Spherical to rectangular co-ordinate conversion@>
    @<lowmoon: Luna position calculation@>

    //  Common satellite variables and functions
    @<Satellite script global variables@>
    @<Satellite script common functions@>
    @<Planet link messages@>
    @<setSatelliteVisibility: Show or hide satellite@>

    //  State handler
    default {
        state_entry() {
            whoDat = owner = llGetOwner();
        }

        @<Satellite script {\tt on\_rez} event handler@>

        @<Satellite script link message handler@<Compute position of Luna@>@>
    }
@}

\subsection{Mars}

\begin{wrapfigure}{r}{4cm}
\centering
\includegraphics[width=3.8cm]{figures/orbits_mars.png}
\end{wrapfigure}
Mars is a simple planet model.  We do not model its two tiny
satellites, and simply use the rotation rate without aligning the
actual proper face to the Sun.  This should be replaced by code which
calculates Mars time and correctly orients the planet with respect to
the Sun.

@d Mars properties
@{
    list planet = [
        "Mars",             // 0  Name of body
        "Sun",              // 1  Primary

        //  Orbital elements
        @<J2000@>,          // 2  Epoch (J2000), integer to avoid round-off

        1.52366231,         // 3  a    Semi-major axis, AU
        0.09341233,         // 4  e    Eccentricity
        1.85061,            // 5  i    Inclination, degrees
        49.57854,           // 6  Ω    Longitude of the ascending node, degrees
        336.04084,          // 7  ω    Argument of periapsis, degrees
        355.45332,          // 8  L    Mean longitude, degrees

        //  Orbital element centennial rates
        -0.00007221,        // 9  a    AU/century
        0.00011902,         // 10 e    e/century
        -25.47,             // 11 i    "/century
        -1020.19,           // 12 Ω    "/century
        1560.78,            // 13 ω    "/century
        68905103.78,        // 14 L    "/century

        //  Physical properties
        3396.2,             // 15 Equatorial radius, km
        3376.2,             // 16 Polar radius, km
        6.4171e23,          // 17 Mass, kg
        3.9335,             // 18 Mean density, g/cm³
        3.72076,            // 19 Surface gravity, m/s²
        5.027,              // 20 Escape velocity, km/s
        1.025957,           // 21 Sidereal rotation period, days
        <317.68143, 52.8865, 0>,    // 22 North pole, RA, Dec
        25.19,              // 23 Axial inclination, degrees
        0.150,              // 24 Albedo

        //  Extras
        0.0,                // 25 Fractional part of epoch
        @<GM:Sun@>,         /* 26 Standard gravitational parameter (G M)
                                  of primary, m^3/sec^2  */
        @<Colour:4:yellow@> // 27 Colour of trail tracing orbit
    ];
@}

\subsubsection{Planet object}

@o scripts/planets/mars/mars.lsl
@{
    @<Explanatory header for LSL files@>

    @<Mars properties@>
    @<Planet object script@'@'@'@'@'@'@>

@}

\subsubsection{Ephemeris}

@o scripts/planets/mars/eph_mars.lsl
@{
    @<Explanatory header for LSL files@>

    integer BODY = 4;               // Our body number

@<Mars periodic terms@>

@<Ephemeris link messages@>

@<Ephemeris calculator prologue@>

    @<Ephemeris term evaluator L0@>
    @<Ephemeris term evaluator L1@>
    @<Ephemeris term evaluator L2@>
    @<Ephemeris term evaluator L3@>
    @<Ephemeris term evaluator L4@>
    @<Ephemeris term evaluator L5@>

    @<Ephemeris term evaluator B0@>
    @<Ephemeris term evaluator B1@>
    @<Ephemeris term evaluator B2@>
    @<Ephemeris term evaluator B3@>
    @<Ephemeris term evaluator B4@>

    @<Ephemeris term evaluator R0@>
    @<Ephemeris term evaluator R1@>
    @<Ephemeris term evaluator R2@>
    @<Ephemeris term evaluator R3@>
    @<Ephemeris term evaluator R4@>

@<Ephemeris calculator epilogue@>

@<Ephemeris request processor@<Ephemeris request processor memory status@>@>
@}

\subsection{Jupiter}

\begin{wrapfigure}{r}{4cm}
\centering
\includegraphics[width=3.8cm]{figures/orbits_jupiter.png}
\end{wrapfigure}
Despite having four moons, Jupiter is a simple planet in our model.
Due to its differential rotation by latitude, there's no point trying
to get the correct face pointed toward the Sun, so we simply use its
mean rotation rate to spin it arbitrarily.  All of the Galilean
satellites are tidally locked, so their rotation straightforward.
The Laplace planes of their orbits, however, differ slightly from
Jupiter's equatorial plane, so this must be accounted for.  We
approximate the satellites' positions from their orbital elements.

@d Jupiter properties
@{
    list planet = [
        "Jupiter",          // 0  Name of body
        "Sun",              // 1  Primary

        //  Orbital elements
        @<J2000@>,          // 2  Epoch (J2000), integer to avoid round-off

        5.20336301,         // 3  a    Semi-major axis, AU
        0.04839266,         // 4  e    Eccentricity
        1.30530,            // 5  i    Inclination, degrees
        100.55615,          // 6  Ω    Longitude of the ascending node, degrees
        14.75385,           // 7  ω    Argument of periapsis, degrees
        34.40438,           // 8  L    Mean longitude, degrees

        //  Orbital element centennial rates
        0.00060737,         // 9  a    AU/century
        -0.00012880,        // 10 e    e/century
        -4.15,              // 11 i    "/century
        1217.17,            // 12 Ω    "/century
        839.93,             // 13 ω    "/century
        10925078.35,        // 14 L    "/century

        //  Physical properties
        71492.0,            // 15 Equatorial radius, km
        66854.0,            // 16 Polar radius, km
        1.8982e27,          // 17 Mass, kg
        1.326,              // 18 Mean density, g/cm³
        24.79,              // 19 Surface gravity, m/s²
        59.5,               // 20 Escape velocity, km/s
        0.4135417,          // 21 Sidereal rotation period, days
        <268.057, 64.495, 0>,// 22 North pole, RA, Dec
        3.13,               // 23 Axial inclination, degrees
        0.538,              // 24 Albedo

        //  Extras
        0.0,                // 25 Fractional part of epoch
        @<GM:Sun@>,         /* 26 Standard gravitational parameter (G M)
                                  of primary, m^3/sec^2  */
        @<Colour:5:green@>  // 27 Colour of trail tracing orbit
    ];
@}

\subsubsection{Planet object}

@o scripts/planets/jupiter/jupiter.lsl
@{
    @<Explanatory header for LSL files@>

    @<Jupiter properties@>
    @<Planet object script@'@'@'@'@'@'@>
@}

\subsubsection{Ephemeris}

@o scripts/planets/jupiter/eph_jupiter.lsl
@{
    @<Explanatory header for LSL files@>

    integer BODY = 5;               // Our body number

@<Jupiter periodic terms@>

@<Ephemeris link messages@>

@<Ephemeris calculator prologue@>

    @<Ephemeris term evaluator L0@>
    @<Ephemeris term evaluator L1@>
    @<Ephemeris term evaluator L2@>
    @<Ephemeris term evaluator L3@>
    @<Ephemeris term evaluator L4@>
    @<Ephemeris term evaluator L5@>

    @<Ephemeris term evaluator B0@>
    @<Ephemeris term evaluator B1@>
    @<Ephemeris term evaluator B2@>
    @<Ephemeris term evaluator B3@>
    @<Ephemeris term evaluator B4@>
    @<Ephemeris term evaluator B5@>

    @<Ephemeris term evaluator R0@>
    @<Ephemeris term evaluator R1@>
    @<Ephemeris term evaluator R2@>
    @<Ephemeris term evaluator R3@>
    @<Ephemeris term evaluator R4@>
    @<Ephemeris term evaluator R5@>

@<Ephemeris calculator epilogue@>

@<Ephemeris request processor@'@'@>
@}

\subsubsection{Satellites}

\paragraph{Io}

\subparagraph{Satellite properties}

The {\tt planet} list declares the specifics of this satellite
such as its orbit, physical properties, and rotation.  It contains
all of the parameters required by the generic ``Satellite object
script''.

@d Io properties
@{
    list planet = [
        "Io",               // 0  Name of body
        "Jupiter",          // 1  Primary

        //  Orbital elements
        2450464,            // 2  Epoch (1997-01-16.00), integer part

        421800,             // 3  a    Semi-major axis, km
        0.0041,             // 4  e    Eccentricity
        0.036,              // 5  i    Inclination, degrees
        43.977,             // 6  Ω    Longitude of the ascending node, degrees
        84.129,             // 7  ω    Argument of periapsis, degrees
        342.021,            // 8  M    Mean anomaly, degrees

        //  Orbital element precession periods
        0,                  // 9  a
        0,                  // 10 e
        0,                  // 11 i
        7.420,              // 12 Ω    Precession period/years
        1.625,              // 13 ω    Precession period/years
        0,                  // 14 M

        //  Physical properties
        3660.0,             // 15 Equatorial radius, km
        3737.4,             // 16 Polar radius, km
        8.931938e22,        // 17 Mass, kg
        3.528,              // 18 Mean density, g/cm³
        1.796,              // 19 Surface gravity, m/s²
        2.558,              // 20 Escape velocity, km/s
        1.769137786,        // 21 Sidereal rotation period, days
        <268.057, 64.495, 0>, // 22 North pole, RA, Dec  (USED JUPITER)
        0.0,                // 23 Axial inclination, degrees (UNKNOWN)
        0.63,               // 24 Albedo

        //  Extras
        0.5,                // 25 Fractional part of epoch
        @<GM:Jupiter@>,     /* 26 Standard gravitational parameter (G M)
                                  of primary, m^3/sec^2  */
        @<Colour:1:brown@>, // 27 Colour of trail tracing orbit
        <268.057, 64.495, 0.000>    // 28 Laplace plane of orbit: RA, Dec, Tilt
    ];
@}

\subparagraph{Satellite object}

@o scripts/planets/jupiter/io/io.lsl
@{
    @<Explanatory header for LSL files@>

    @<Io properties@>
    @<Satellite object script@>
@}

\paragraph{Europa}

\subparagraph{Satellite properties}

@d Europa properties
@{
    list planet = [
        "Europa",           // 0  Name of body
        "Jupiter",          // 1  Primary

        //  Orbital elements
        2450464,            // 2  Epoch (1997-01-16.00), integer part

        671100,             // 3  a    Semi-major axis, km
        0.0094,             // 4  e    Eccentricity
        0.466,              // 5  i    Inclination, degrees
        219.106,            // 6  Ω    Longitude of the ascending node, degrees
        88.970,             // 7  ω    Argument of periapsis, degrees
        171.016,            // 8  M    Mean anomaly, degrees

        //  Orbital element precession periods
        0,                  // 9  a
        0,                  // 10 e
        0,                  // 11 i
        30.184,             // 12 Ω    Precession period/years
        1.394,              // 13 ω    Precession period/years
        0,                  // 14 M

        //  Physical properties
        1560.8,             // 15 Equatorial radius, km
        1560.8,             // 16 Polar radius, km
        4.799844e22,        // 17 Mass, kg
        3.013,              // 18 Mean density, g/cm³
        1.314,              // 19 Surface gravity, m/s²
        2.025,              // 20 Escape velocity, km/s
        3.551181,           // 21 Sidereal rotation period, days
        <268.057, 64.495, 0>, // 22 North pole, RA, Dec  (USED JUPITER)
        0.0,                // 23 Axial inclination, degrees (UNKNOWN)
        0.67,               // 24 Albedo

        //  Extras
        0.5,                // 25 Fractional part of epoch
        @<GM:Jupiter@>,     /* 26 Standard gravitational parameter (G M)
                                  of primary, m^3/sec^2  */
        @<Colour:2:red@>,   // 27 Colour of trail tracing orbit
        <268.084, 64.506, 0.016>    // 28 Laplace plane of orbit: RA, Dec, Tilt
    ];
@}

\subparagraph{Satellite object}

@o scripts/planets/jupiter/europa/europa.lsl
@{
    @<Explanatory header for LSL files@>

    @<Europa properties@>
    @<Satellite object script@>
@}

\paragraph{Ganymede}

\subparagraph{Satellite properties}

@d Ganymede properties
@{
    list planet = [
        "Ganymede",         // 0  Name of body
        "Jupiter",          // 1  Primary

        //  Orbital elements
        2450464,            // 2  Epoch (1997-01-16.00), integer part

        1070400,            // 3  a    Semi-major axis, km
        0.0013,             // 4  e    Eccentricity
        0.177,              // 5  i    Inclination, degrees
        63.552,             // 6  Ω    Longitude of the ascending node, degrees
        192.417,            // 7  ω    Argument of periapsis, degrees
        317.540,            // 8  M    Mean anomaly, degrees

        //  Orbital element precession periods
        0,                  // 9  a
        0,                  // 10 e
        0,                  // 11 i
        132.654,            // 12 Ω    Precession period/years
        63.549,             // 13 ω    Precession period/years
        0,                  // 14 M

        //  Physical properties
        2634.1,             // 15 Equatorial radius, km
        2634.1,             // 16 Polar radius, km
        1.4819e23,          // 17 Mass, kg
        1.936,              // 18 Mean density, g/cm³
        1.428,              // 19 Surface gravity, m/s²
        2.741,              // 20 Escape velocity, km/s
        7.15455296,         // 21 Sidereal rotation period, days
        <268.057, 64.495, 0>, // 22 North pole, RA, Dec  (USED JUPITER)
        0.0,                // 23 Axial inclination, degrees (UNKNOWN)
        0.43,               // 24 Albedo

        //  Extras
        0.5,                // 25 Fractional part of epoch
        @<GM:Jupiter@>,     /* 26 Standard gravitational parameter (G M)
                                  of primary, m^3/sec^2  */
        @<Colour:3:orange@>,        // 27 Colour of trail tracing orbit
        <268.168, 64.543, 0.068>    // 28 Laplace plane of orbit: RA, Dec, Tilt
    ];
@}

\subparagraph{Satellite object}

@o scripts/planets/jupiter/ganymede/ganymede.lsl
@{
    @<Explanatory header for LSL files@>

    @<Ganymede properties@>
    @<Satellite object script@>
@}

\paragraph{Callisto}

\subparagraph{Satellite properties}

@d Callisto properties
@{
    list planet = [
        "Callisto",         // 0  Name of body
        "Jupiter",          // 1  Primary

        //  Orbital elements
        2450464,            // 2  Epoch (1997-01-16.00), integer part

        1882700,            // 3  a    Semi-major axis, km
        0.0074,             // 4  e    Eccentricity
        0.192,              // 5  i    Inclination, degrees
        298.848,            // 6  Ω    Longitude of the ascending node, degrees
        52.643,             // 7  ω    Argument of periapsis, degrees
        181.408,            // 8  M    Mean anomaly, degrees

        //  Orbital element precession periods
        0,                  // 9  a
        0,                  // 10 e
        0,                  // 11 i
        338.82,             // 12 Ω    Precession period/years
        205.75,             // 13 ω    Precession period/years
        0,                  // 14 M

        //  Physical properties
        2410.3,             // 15 Equatorial radius, km
        2410.3,             // 16 Polar radius, km
        1.075938e23,        // 17 Mass, kg
        1.8344,             // 18 Mean density, g/cm³
        1.235,              // 19 Surface gravity, m/s²
        2.440,              // 20 Escape velocity, km/s
        16.6890184,         // 21 Sidereal rotation period, days
        <268.057, 64.495, 0>, // 22 North pole, RA, Dec  (USED JUPITER)
        0.0,                // 23 Axial inclination, degrees (UNKNOWN)
        0.22,               // 24 Albedo

        //  Extras
        0.5,                // 25 Fractional part of epoch
        @<GM:Jupiter@>,     /* 26 Standard gravitational parameter (G M)
                                  of primary, m^3/sec^2  */
        @<Colour:4:yellow@>,        // 27 Colour of trail tracing orbit
        <268.639, 64.749, 0.356>    // 28 Laplace plane of orbit: RA, Dec, Tilt
    ];
@}

\subparagraph{Satellite object}

@o scripts/planets/jupiter/callisto/callisto.lsl
@{
    @<Explanatory header for LSL files@>

    @<Callisto properties@>
    @<Satellite object script@>
@}

\subsection{Saturn}

\begin{wrapfigure}{r}{4cm}
\centering
\includegraphics[width=3.8cm]{figures/orbits_saturn.png}
\end{wrapfigure}
Saturn is similar to Jupiter, only with seven satellites and a ring
system which we have to take care to orient to remain in the equatorial
plane when we align Saturn's north pole.  The ring model texture is
circularly symmetric, so there's no point in rotating it.

@d Saturn properties
@{
    list planet = [
        "Saturn",           // 0  Name of body
        "Sun",              // 1  Primary

        //  Orbital elements
        @<J2000@>,          // 2  Epoch (J2000), integer to avoid round-off

        9.53707032,         // 3  a    Semi-major axis, AU
        0.05415060,         // 4  e    Eccentricity
        2.48446,            // 5  i    Inclination, degrees
        113.71504,          // 6  Ω    Longitude of the ascending node, degrees
        92.43194,           // 7  ω    Argument of periapsis, degrees
        49.94432,           // 8  L    Mean longitude, degrees

        //  Orbital element centennial rates
        -0.00301530,        // 9  a    AU/century
        -0.00036762,        // 10 e    e/century
        6.11,               // 11 i    "/century
        -1591.05,           // 12 Ω    "/century
        -1948.89,           // 13 ω    "/century
        4401052.95,         // 14 L    "/century

        //  Physical properties
        60268.0,            // 15 Equatorial radius, km
        54364.0,            // 16 Polar radius, km
        5.6834e26,          // 17 Mass, kg
        0.687,              // 18 Mean density, g/cm³
        10.44,              // 19 Surface gravity, m/s²
        35.5,               // 20 Escape velocity, km/s
        0.4400231,          // 21 Sidereal rotation period, days
        <40.589, 83.537, 0>,// 22 North pole, RA, Dec
        26.73,              // 23 Axial inclination, degrees
        0.499,              // 24 Albedo

        //  Extras
        0.0,                // 25 Fractional part of epoch
        @<GM:Sun@>,         /* 26 Standard gravitational parameter (G M)
                                  of primary, m^3/sec^2  */
        @<Colour:6:blue@>   // 27 Colour of trail tracing orbit
    ];
@}

\subsubsection{Saturn-specific messages}

We use this message to forward the initialisation parameters (in
particular the scale factor) to Saturn's ring system so that it may
configure itself to the same scale as the planet.

@d Saturn-specific messages
@{
    integer LM_PL_PINIT = 531;
@| LM_PL_PINIT @}

\subsubsection{Planet object}

@o scripts/planets/saturn/saturn.lsl
@{
    @<Explanatory header for LSL files@>

    @<Saturn properties@>

    @<Saturn-specific messages@>

    @<Planet object script@<Configure Saturn ring system@>@'@'@'@'@>
@}

\paragraph{Configure Saturn ring system}

This code is interpolated into the {\tt PINIT} message handler for
Saturn.  It finds the link number for the ring system, forwards the
{\tt PINIT} message, which allows the ring system to apply the same
scale factor to itself as we're using for the planet, and then orients
the ring system to lie in Saturn's equatorial plane.  This is a little
tricky since the ring object was created with its zero rotation state
normal to the pole of the globe and must be rotated to align with the
pole.

@d Configure Saturn ring system

@{
    integer lRings = findLinkNumber("Saturn: ring system");

    llMessageLinked(lRings, LM_PL_PINIT, message, id);

    rotation eqRot = llEuler2Rot(<0, PI_BY_TWO, 0>) * npRot;
    llSetLinkPrimitiveParamsFast(lRings, [ PRIM_ROT_LOCAL, eqRot ]);
@}

\subsubsection{Ephemeris}

@o scripts/planets/saturn/eph_saturn.lsl
@{
    @<Explanatory header for LSL files@>

    integer BODY = 6;               // Our body number

@<Saturn periodic terms@>

@<Ephemeris link messages@>

@<Ephemeris calculator prologue@>

    @<Ephemeris term evaluator L0@>
    @<Ephemeris term evaluator L1@>
    @<Ephemeris term evaluator L2@>
    @<Ephemeris term evaluator L3@>
    @<Ephemeris term evaluator L4@>
    @<Ephemeris term evaluator L5@>

    @<Ephemeris term evaluator B0@>
    @<Ephemeris term evaluator B1@>
    @<Ephemeris term evaluator B2@>
    @<Ephemeris term evaluator B3@>
    @<Ephemeris term evaluator B4@>
    @<Ephemeris term evaluator B5@>

    @<Ephemeris term evaluator R0@>
    @<Ephemeris term evaluator R1@>
    @<Ephemeris term evaluator R2@>
    @<Ephemeris term evaluator R3@>
    @<Ephemeris term evaluator R4@>
    @<Ephemeris term evaluator R5@>

@<Ephemeris calculator epilogue@>

@<Ephemeris request processor@'@'@>
@}

\subsubsection{Satellites}

\paragraph{Ring System}

Saturn has a major ring system, much more apparent than those of the
other giant planets.  The rings extend to a diameter of around 140390
km from the centre of the planet, with the innermost visible rings at
around 74510 km from the centre.  The rings are in the equatorial plane
of the planet.

We model the rings as a cylinder whose texture (colour, intensity, and
transparency) is derived from Voyager imagery and stellar occultation
data.  The rings' texture is symmetrical around the origin: no attempt
to model ``spokes'' or other angular differences in appearance is
made.  Portions of the rings which are invisible in typical visible
light observation are made transparent, with transparency of parts
of the rings following observational data.

The ring object is linked to the Saturn planet main object oriented
in its equatorial plane.  When the planet object is created and orients
the north pole of its Globe object, it sends a {\tt LM\_PL\_PINIT}
message to the linked ring system so it can align its normal to the
ring plane with the north pole.

\subparagraph{Ring system object}

The ring system object listens for the {\tt PINIT} message which
provides scaling information to the planet.  It scales the ring
object to accord with the planet.  Note that rotation of the
ring system to align with the planet's north pole is handled in
the main planet script for Saturn.

@o scripts/planets/saturn/ring_system/ring_system.lsl
@{
    @<Explanatory header for LSL files@>

    integer ringDia = 140390;           // Ring system diameter (km)

    @<Planet link messages@>
    @<Saturn-specific messages@>

    @<siuf: Decode base64-encoded floating point number@>

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
                    vector psize = < ringDia, ringDia, 5 > *
                        0.0001 * m_scalePlanet;
                    llSetLinkPrimitiveParamsFast(LINK_THIS, [
                        PRIM_SIZE, psize
                    ]);
                }

           //  LM_PS_DEPMSG (811): Deployer message forwarded by primary

            } else if (num == LM_PS_DEPMSG) {
                list msg = llJson2List(str);
                string ccmd = llList2String(msg, 0);
@}

The {\tt VERSION} message requests this script to check its build
number against that of the Deployer and report any discrepancy.  This
message is forwarded by Saturn, of which we are a child link.

@o scripts/planets/saturn/ring_system/ring_system.lsl
@{
                if (FALSE) {                // Hack to use following macro
                @<Check build number in created objects@>
                }

            }
        }
     }
@}

\paragraph{Mimas}

\subparagraph{Satellite properties}

@d Mimas properties
@{
    list planet = [
        "Mimas",            // 0  Name of body
        "Saturn",           // 1  Primary

        //  Orbital elements
        @<J2000@>,          // 2  Epoch (J2000), integer part

        185539,             // 3  a    Semi-major axis, km
        0.0196,             // 4  e    Eccentricity
        1.574,              // 5  i    Inclination, degrees
        173.027,            // 6  Ω    Longitude of the ascending node, degrees
        332.499,            // 7  ω    Argument of periapsis, degrees
        14.848,             // 8  M    Mean anomaly, degrees

        //  Orbital element precession periods
        0,                  // 9  a
        0,                  // 10 e
        0,                  // 11 i
        0.986,              // 12 Ω    Precession period/years
        0.493,              // 13 ω    Precession period/years
        0,                  // 14 M

        //  Physical properties
        198.2,              // 15 Equatorial radius, km
        198.2,              // 16 Polar radius, km
        3.7493e19,          // 17 Mass, kg
        1.1479,             // 18 Mean density, g/cm³
        0.064,              // 19 Surface gravity, m/s²
        0.159,              // 20 Escape velocity, km/s
        0.942,              // 21 Sidereal rotation period, days
        <40.589, 83.537, 0>, // 22 North pole, RA, Dec  (USED SATURN)
        0.0,                // 23 Axial inclination, degrees
        0.962,              // 24 Albedo

        //  Extras
        0.0,                // 25 Fractional part of epoch
        @<GM:Saturn@>,      /* 26 Standard gravitational parameter (G M)
                                  of primary, m^3/sec^2  */
        @<Colour:1:brown@>, // 27 Colour of trail tracing orbit
        <40.589, 83.536, 0.002>     // 28 Laplace plane of orbit: RA, Dec, Tilt
    ];
@}

\subparagraph{Satellite object}

@o scripts/planets/saturn/mimas/mimas.lsl
@{
    @<Explanatory header for LSL files@>

    @<Mimas properties@>
    @<Satellite object script@>
@}

\paragraph{Enceladus}

\subparagraph{Satellite properties}

@d Enceladus properties
@{
    list planet = [
        "Enceladus",        // 0  Name of body
        "Saturn",           // 1  Primary

        //  Orbital elements
        @<J2000@>,          // 2  Epoch (J2000), integer part

        238042,             // 3  a    Semi-major axis, km
        0.0,                // 4  e    Eccentricity
        0.003,              // 5  i    Inclination, degrees
        342.507,            // 6  Ω    Longitude of the ascending node, degrees
        0.076,              // 7  ω    Argument of periapsis, degrees
        199.686,            // 8  M    Mean anomaly, degrees

        //  Orbital element precession periods
        0,                  // 9  a
        0,                  // 10 e
        0,                  // 11 i
        2.360,              // 12 Ω    Precession period/years
        1.184,              // 13 ω    Precession period/years
        0,                  // 14 M

        //  Physical properties
        252.1,              // 15 Equatorial radius, km
        252.1,              // 16 Polar radius, km
        1.08022e20,         // 17 Mass, kg
        1.609,              // 18 Mean density, g/cm³
        0.113,              // 19 Surface gravity, m/s²
        0.239,              // 20 Escape velocity, km/s
        1.370218,           // 21 Sidereal rotation period, days
        <40.589, 83.537, 0>, // 22 North pole, RA, Dec  (USED SATURN)
        0.0,                // 23 Axial inclination, degrees
        0.81,               // 24 Albedo

        //  Extras
        0.0,                // 25 Fractional part of epoch
        @<GM:Saturn@>,      /* 26 Standard gravitational parameter (G M)
                                  of primary, m^3/sec^2  */
        @<Colour:2:red@>,   // 27 Colour of trail tracing orbit
        <40.586, 83.536, 0.002>     // 28 Laplace plane of orbit: RA, Dec, Tilt
    ];
@}

\subparagraph{Satellite object}

@o scripts/planets/saturn/enceladus/enceladus.lsl
@{
    @<Explanatory header for LSL files@>

    @<Enceladus properties@>
    @<Satellite object script@>
@}

\paragraph{Tethys}

\subparagraph{Satellite properties}

@d Tethys properties
@{
    list planet = [
        "Tethys",           // 0  Name of body
        "Saturn",           // 1  Primary

        //  Orbital elements
        @<J2000@>,          // 2  Epoch (J2000), integer part
        294672,             // 3  a    Semi-major axis, km
        0.0001,             // 4  e    Eccentricity
        1.091,              // 5  i    Inclination, degrees
        259.842,            // 6  Ω    Longitude of the ascending node, degrees
        45.202,             // 7  ω    Argument of periapsis, degrees
        243.367,            // 8  M    Mean anomaly, degrees

        //  Orbital element precession periods
        0,                  // 9  a
        0,                  // 10 e
        0,                  // 11 i
        4.982,              // 12 Ω    Precession period/years
        2.490,              // 13 ω    Precession period/years
        0,                  // 14 M

        //  Physical properties
        531.1,              // 15 Equatorial radius, km
        531.1,              // 16 Polar radius, km
        6.17449e20,         // 17 Mass, kg
        0.984,              // 18 Mean density, g/cm³
        0.146,              // 19 Surface gravity, m/s²
        0.394,              // 20 Escape velocity, km/s
        1.887802,           // 21 Sidereal rotation period, days
        <40.589, 83.537, 0>, // 22 North pole, RA, Dec  (USED SATURN)
        0.0,                // 23 Axial inclination, degrees
        0.80,               // 24 Albedo

        //  Extras
        0.0,                // 25 Fractional part of epoch
        @<GM:Saturn@>,      /* 26 Standard gravitational parameter (G M)
                                  of primary, m^3/sec^2  */
        @<Colour:3:orange@>,        // 27 Colour of trail tracing orbit
        <40.578, 83.537, 0.001>     // 28 Laplace plane of orbit: RA, Dec, Tilt
    ];
@}

\subparagraph{Satellite object}

@o scripts/planets/saturn/tethys/tethys.lsl
@{
    @<Explanatory header for LSL files@>

    @<Tethys properties@>
    @<Satellite object script@>
@}

\paragraph{Dione}

\subparagraph{Satellite properties}

@d Dione properties
@{
    list planet = [
        "Dione",            // 0  Name of body
        "Saturn",           // 1  Primary

        //  Orbital elements
        @<J2000@>,          // 2  Epoch (J2000), integer part
        377415,             // 3  a    Semi-major axis, km
        0.0022,             // 4  e    Eccentricity
        0.028,              // 5  i    Inclination, degrees
        290.415,            // 6  Ω    Longitude of the ascending node, degrees
        284.315,            // 7  ω    Argument of periapsis, degrees
        322.232,            // 8  M    Mean anomaly, degrees

        //  Orbital element precession periods
        0,                  // 9  a
        0,                  // 10 e
        0,                  // 11 i
        11.709,             // 12 Ω    Precession period/years
        5.852,              // 13 ω    Precession period/years
        0,                  // 14 M

        //  Physical properties
        561.4,              // 15 Equatorial radius, km
        561.4,              // 16 Polar radius, km
        1.095452e21,        // 17 Mass, kg
        1.478,              // 18 Mean density, g/cm³
        0.232,              // 19 Surface gravity, m/s²
        0.51,               // 20 Escape velocity, km/s
        2.736915,           // 21 Sidereal rotation period, days
        <40.589, 83.537, 0>, // 22 North pole, RA, Dec  (USED SATURN)
        0.0,                // 23 Axial inclination, degrees
        0.998,              // 24 Albedo

        //  Extras
        0.0,                // 25 Fractional part of epoch
        @<GM:Saturn@>,      /* 26 Standard gravitational parameter (G M)
                                  of primary, m^3/sec^2  */
        @<Colour:4:yellow@>,        // 27 Colour of trail tracing orbit
        <40.544, 83.540, 0.005>     // 28 Laplace plane of orbit: RA, Dec, Tilt
    ];
@}

\subparagraph{Satellite object}

@o scripts/planets/saturn/dione/dione.lsl
@{
    @<Explanatory header for LSL files@>

    @<Dione properties@>
    @<Satellite object script@>
@}

\paragraph{Rhea}

\subparagraph{Satellite properties}

@d Rhea properties
@{
    list planet = [
        "Rhea",             // 0  Name of body
        "Saturn",           // 1  Primary

        //  Orbital elements
        @<J2000@>,          // 2  Epoch (J2000), integer part
        527068,             // 3  a    Semi-major axis, km
        0.0002,             // 4  e    Eccentricity
        0.333,              // 5  i    Inclination, degrees
        351.042,            // 6  Ω    Longitude of the ascending node, degrees
        241.619,            // 7  ω    Argument of periapsis, degrees
        179.781,            // 8  M    Mean anomaly, degrees

        //  Orbital element precession periods
        0,                  // 9  a
        0,                  // 10 e
        0,                  // 11 i
        35.832,             // 12 Ω    Precession period/years
        17.939,             // 13 ω    Precession period/years
        0,                  // 14 M

        //  Physical properties
        763.8,              // 15 Equatorial radius, km
        763.8,              // 16 Polar radius, km
        2.306518e21,        // 17 Mass, kg
        1.236,              // 18 Mean density, g/cm³
        0.264,              // 19 Surface gravity, m/s²
        0.635,              // 20 Escape velocity, km/s
        4.518212,           // 21 Sidereal rotation period, days
        <40.589, 83.537, 0>, // 22 North pole, RA, Dec  (USED SATURN)
        0.0,                // 23 Axial inclination, degrees
        0.949,              // 24 Albedo

        //  Extras
        0.0,                // 25 Fractional part of epoch
        @<GM:Saturn@>,      /* 26 Standard gravitational parameter (G M)
                                  of primary, m^3/sec^2  */
        @<Colour:5:green@>, // 27 Colour of trail tracing orbit
        <40.328, 83.559, 0.036>     // 28 Laplace plane of orbit: RA, Dec, Tilt
    ];
@}

\subparagraph{Satellite object}

@o scripts/planets/saturn/rhea/rhea.lsl
@{
    @<Explanatory header for LSL files@>

    @<Rhea properties@>
    @<Satellite object script@>
@}

\paragraph{Titan}

\subparagraph{Satellite properties}

@d Titan properties
@{
    list planet = [
        "Titan",            // 0  Name of body
        "Saturn",           // 1  Primary

        //  Orbital elements
        @<J2000@>,          // 2  Epoch (J2000), integer part
        1221865,            // 3  a    Semi-major axis, km
        0.0288,             // 4  e    Eccentricity
        0.306,              // 5  i    Inclination, degrees
        28.060,             // 6  Ω    Longitude of the ascending node, degrees
        180.532,            // 7  ω    Argument of periapsis, degrees
        163.310,            // 8  M    Mean anomaly, degrees

        //  Orbital element precession periods
        0,                  // 9  a
        0,                  // 10 e
        0,                  // 11 i
        704.60,             // 12 Ω    Precession period/years
        352.12,             // 13 ω    Precession period/years
        0,                  // 14 M

        //  Physical properties
        2574.73,            // 15 Equatorial radius, km
        2574.73,            // 16 Polar radius, km
        1.3452e23,          // 17 Mass, kg
        1.8798,             // 18 Mean density, g/cm³
        1.352,              // 19 Surface gravity, m/s²
        2.639,              // 20 Escape velocity, km/s
        15.945,             // 21 Sidereal rotation period, days
        <40.589, 83.537, 0>, // 22 North pole, RA, Dec  (USED SATURN)
        0.0,                // 23 Axial inclination, degrees
        0.22,               // 24 Albedo

        //  Extras
        0.0,                // 25 Fractional part of epoch
        @<GM:Saturn@>,      /* 26 Standard gravitational parameter (G M)
                                  of primary, m^3/sec^2  */
        @<Colour:6:blue@>,  // 27 Colour of trail tracing orbit
        <36.214, 83.949, 0.629>     // 28 Laplace plane of orbit: RA, Dec, Tilt
    ];
@}

\subparagraph{Satellite object}

@o scripts/planets/saturn/titan/titan.lsl
@{
    @<Explanatory header for LSL files@>

    @<Titan properties@>
    @<Satellite object script@>
@}

\paragraph{Iapetus}

\subparagraph{Satellite properties}

@d Iapetus properties
@{
    list planet = [
        "Iapetus",          // 0  Name of body
        "Saturn",           // 1  Primary

        //  Orbital elements
        @<J2000@>,          // 2  Epoch (J2000), integer part
        3560854,            // 3  a    Semi-major axis, km
        0.0293,             // 4  e    Eccentricity
        8.298,              // 5  i    Inclination, degrees
        81.105,             // 6  Ω    Longitude of the ascending node, degrees
        271.606,            // 7  ω    Argument of periapsis, degrees
        201.789,            // 8  M    Mean anomaly, degrees

        //  Orbital element precession periods
        0,                  // 9  a
        0,                  // 10 e
        0,                  // 11 i
        3438.73,            // 12 Ω    Precession period/years
        1676.69,            // 13 ω    Precession period/years
        0,                  // 14 M

        //  Physical properties
        734.5,              // 15 Equatorial radius, km
        734.5,              // 16 Polar radius, km
        1.805635e21,        // 17 Mass, kg
        1.088,              // 18 Mean density, g/cm³
        0.223,              // 19 Surface gravity, m/s²
        0.573,              // 20 Escape velocity, km/s
        79.3215,            // 21 Sidereal rotation period, days
        <40.589, 83.537, 0>, // 22 North pole, RA, Dec  (USED SATURN)
        0.0,                // 23 Axial inclination, degrees
        0.25,               // 24 Albedo

        //  Extras
        0.0,                // 25 Fractional part of epoch
        @<GM:Saturn@>,      /* 26 Standard gravitational parameter (G M)
                                  of primary, m^3/sec^2  */
        @<Colour:7:violet@>,// 27 Colour of trail tracing orbit
        <284.715, 78.749, 15.210>   // 28 Laplace plane of orbit: RA, Dec, Tilt
    ];
@}

\subparagraph{Satellite object}

@o scripts/planets/saturn/iapetus/iapetus.lsl
@{
    @<Explanatory header for LSL files@>

    @<Iapetus properties@>
    @<Satellite object script@>
@}

\subsection{Uranus}

\begin{wrapfigure}{r}{4cm}
\centering
\includegraphics[width=3.8cm]{figures/orbits_uranus.png}
\end{wrapfigure}
Uranus is modeleted similarly to Jupiter, but its wonky inclination
(it essentially orbits on its side, with the north pole [defined by
rotation] below the plane of the ecliptic).  As such, it is a test
case for such orientation.  Its five satellites orbit close to the
equatorial plane, and thus test computation and rendering of such
orbits and tidal locking of the satellites to the planet.

@d Uranus properties
@{
    list planet = [
        "Uranus",           // 0  Name of body
        "Sun",              // 1  Primary

        //  Orbital elements
        @<J2000@>,          // 2  Epoch (J2000), integer to avoid round-off

        19.19126393,        // 3  a    Semi-major axis, AU
        0.04716771,         // 4  e    Eccentricity
        0.76986,            // 5  i    Inclination, degrees
        74.22988,           // 6  Ω    Longitude of the ascending node, degrees
        170.96424,          // 7  ω    Argument of periapsis, degrees
        313.23218,          // 8  L    Mean longitude, degrees

        //  Orbital element centennial rates
        0.00152025,         // 9  a    AU/century
        -0.00019150,        // 10 e    e/century
        -2.09,              // 11 i    "/century
        -1681.40,           // 12 Ω    "/century
        1312.56,            // 13 ω    "/century
        1542547.79,         // 14 L    "/century

        //  Physical properties
        25559.0,            // 15 Equatorial radius, km
        24973.0,            // 16 Polar radius, km
        8.6810e25,          // 17 Mass, kg
        1.27,               // 18 Mean density, g/cm³
        8.69,               // 19 Surface gravity, m/s²
        21.3,               // 20 Escape velocity, km/s
        −0.71833,           // 21 Sidereal rotation period, days
        <257.311, -15.175, 0>,// 22 North pole, RA, Dec
        97.77,              // 23 Axial inclination, degrees
        0.488,              // 24 Albedo

        //  Extras
        0.0,                // 25 Fractional part of epoch
        @<GM:Sun@>,         /* 26 Standard gravitational parameter (G M)
                                  of primary, m^3/sec^2  */
        @<Colour:7:violet@> // 27 Colour of trail tracing orbit
    ];
@}

\subsubsection{Planet object}

@o scripts/planets/uranus/uranus.lsl
@{
    @<Explanatory header for LSL files@>

    @<Uranus properties@>
    @<Planet object script@'@'@'@'@'@'@>
@}

\subsubsection{Ephemeris}

@o scripts/planets/uranus/eph_uranus.lsl
@{
    @<Explanatory header for LSL files@>

    integer BODY = 7;               // Our body number

@<Uranus periodic terms@>

@<Ephemeris link messages@>

@<Ephemeris calculator prologue@>

    @<Ephemeris term evaluator L0@>
    @<Ephemeris term evaluator L1@>
    @<Ephemeris term evaluator L2@>
    @<Ephemeris term evaluator L3@>
    @<Ephemeris term evaluator L4@>

    @<Ephemeris term evaluator B0@>
    @<Ephemeris term evaluator B1@>
    @<Ephemeris term evaluator B2@>
    @<Ephemeris term evaluator B3@>
    @<Ephemeris term evaluator B4@>

    @<Ephemeris term evaluator R0@>
    @<Ephemeris term evaluator R1@>
    @<Ephemeris term evaluator R2@>
    @<Ephemeris term evaluator R3@>
    @<Ephemeris term evaluator R4@>

@<Ephemeris calculator epilogue@>

@<Ephemeris request processor@<Ephemeris request processor memory status@>@>
@}

\subsubsection{Satellites}

\paragraph{Miranda}

\subparagraph{Satellite properties}

@d Miranda properties
@{
    list planet = [
        "Miranda",          // 0  Name of body
        "Uranus",           // 1  Primary

        //  Orbital elements
        2444239,            // 2  Epoch (1980-01-01.0), integer part
        129900,             // 3  a    Semi-major axis, km
        0.0013,             // 4  e    Eccentricity
        4.338,              // 5  i    Inclination, degrees
        326.438,            // 6  Ω    Longitude of the ascending node, degrees
        68.312,             // 7  ω    Argument of periapsis, degrees
        311.330,            // 8  M    Mean anomaly, degrees

        //  Orbital element precession periods
        0,                  // 9  a
        0,                  // 10 e
        0,                  // 11 i
        17.727,             // 12 Ω    Precession period/years
        8.913,              // 13 ω    Precession period/years
        0,                  // 14 M

        //  Physical properties
        235.8,              // 15 Equatorial radius, km
        235.8,              // 16 Polar radius, km
        6.4e19,             // 17 Mass, kg
        1.20,               // 18 Mean density, g/cm³
        0.079,              // 19 Surface gravity, m/s²
        0.193,              // 20 Escape velocity, km/s
        1.413479,           // 21 Sidereal rotation period, days
        <257.311, -15.175, 0>, // 22 North pole, RA, Dec  (USED URANUS)
        0.0,                // 23 Axial inclination, degrees
        0.32,               // 24 Albedo

        //  Extras
        0.5,                // 25 Fractional part of epoch
        @<GM:Uranus@>,      /* 26 Standard gravitational parameter (G M)
                                  of primary, m^3/sec^2  */
        @<Colour:1:brown@>, // 27 Colour of trail tracing orbit
        <257.311, -15.175, 0>   // 28 Laplace plane of orbit: RA, Dec, Tilt
    ];
@}

\subparagraph{Satellite object}

@o scripts/planets/uranus/miranda/miranda.lsl
@{
    @<Explanatory header for LSL files@>

    @<Miranda properties@>
    @<Satellite object script@>
@}

\paragraph{Ariel}

\subparagraph{Satellite properties}

@d Ariel properties
@{
    list planet = [
        "Ariel",            // 0  Name of body
        "Uranus",           // 1  Primary

        //  Orbital elements
        2444239,            // 2  Epoch (1980-01-01.0), integer part
        190900,             // 3  a    Semi-major axis, km
        0.0012,             // 4  e    Eccentricity
        0.041,              // 5  i    Inclination, degrees
        22.394,             // 6  Ω    Longitude of the ascending node, degrees
        115.349,            // 7  ω    Argument of periapsis, degrees
        39.481,             // 8  M    Mean anomaly, degrees

        //  Orbital element precession periods
        0,                  // 9  a
        0,                  // 10 e
        0,                  // 11 i
        57.248,             // 12 Ω    Precession period/years
        28.788,             // 13 ω    Precession period/years
        0,                  // 14 M

        //  Physical properties
        578.9,              // 15 Equatorial radius, km
        578.9,              // 16 Polar radius, km
        1.251e21,           // 17 Mass, kg
        1.592,              // 18 Mean density, g/cm³
        0.269,              // 19 Surface gravity, m/s²
        0.559,              // 20 Escape velocity, km/s
        2.520,              // 21 Sidereal rotation period, days
        <257.311, -15.175, 0>, // 22 North pole, RA, Dec  (USED URANUS)
        0.0,                // 23 Axial inclination, degrees
        0.53,               // 24 Albedo

        //  Extras
        0.5,                // 25 Fractional part of epoch
        @<GM:Uranus@>,      /* 26 Standard gravitational parameter (G M)
                                  of primary, m^3/sec^2  */
        @<Colour:2:red@>,   // 27 Colour of trail tracing orbit
        <257.311, -15.175, 0>   // 28 Laplace plane of orbit: RA, Dec, Tilt
    ];
@}

\subparagraph{Satellite object}

@o scripts/planets/uranus/ariel/ariel.lsl
@{
    @<Explanatory header for LSL files@>

    @<Ariel properties@>
    @<Satellite object script@>
@}

\paragraph{Umbriel}

\subparagraph{Satellite properties}

@d Umbriel properties
@{
    list planet = [
        "Umbriel",          // 0  Name of body
        "Uranus",           // 1  Primary

        //  Orbital elements
        2444239,            // 2  Epoch (1980-01-01.0), integer part
        266000,             // 3  a    Semi-major axis, km
        0.0039,             // 4  e    Eccentricity
        0.128,              // 5  i    Inclination, degrees
        33.485,             // 6  Ω    Longitude of the ascending node, degrees
        84.709,             // 7  ω    Argument of periapsis, degrees
        12.469,             // 8  M    Mean anomaly, degrees

        //  Orbital element precession periods
        0,                  // 9  a
        0,                  // 10 e
        0,                  // 11 i
        126.951,            // 12 Ω    Precession period/years
        63.146,             // 13 ω    Precession period/years
        0,                  // 14 M

        //  Physical properties
        584.7,              // 15 Equatorial radius, km
        584.7,              // 16 Polar radius, km
        1.275e21,           // 17 Mass, kg
        1.39,               // 18 Mean density, g/cm³
        0.2,                // 19 Surface gravity, m/s²
        0.52,               // 20 Escape velocity, km/s
        4.144,              // 21 Sidereal rotation period, days
        <257.311, -15.175, 0>, // 22 North pole, RA, Dec  (USED URANUS)
        0.0,                // 23 Axial inclination, degrees
        0.26,               // 24 Albedo

        //  Extras
        0.5,                // 25 Fractional part of epoch
        @<GM:Uranus@>,      /* 26 Standard gravitational parameter (G M)
                                  of primary, m^3/sec^2  */
        @<Colour:3:orange@>,    // 27 Colour of trail tracing orbit
        <257.311, -15.175, 0>   // 28 Laplace plane of orbit: RA, Dec, Tilt
    ];
@}

\subparagraph{Satellite object}

@o scripts/planets/uranus/umbriel/umbriel.lsl
@{
    @<Explanatory header for LSL files@>

    @<Umbriel properties@>
    @<Satellite object script@>
@}

\paragraph{Titania}

\subparagraph{Satellite properties}

@d Titania properties
@{
    list planet = [
        "Titania",          // 0  Name of body
        "Uranus",           // 1  Primary

        //  Orbital elements
        2444239,            // 2  Epoch (1980-01-01.0), integer part
        436300,             // 3  a    Semi-major axis, km
        0.0011,             // 4  e    Eccentricity
        0.079,              // 5  i    Inclination, degrees
        99.771,             // 6  Ω    Longitude of the ascending node, degrees
        284.400,            // 7  ω    Argument of periapsis, degrees
        24.614,             // 8  M    Mean anomaly, degrees

        //  Orbital element precession periods
        0,                  // 9  a
        0,                  // 10 e
        0,                  // 11 i
        195.369,            // 12 Ω    Precession period/years
        161.525,            // 13 ω    Precession period/years
        0,                  // 14 M

        //  Physical properties
        788.4,              // 15 Equatorial radius, km
        788.4,              // 16 Polar radius, km
        3.400e21,           // 17 Mass, kg
        1.711,              // 18 Mean density, g/cm³
        0.379,              // 19 Surface gravity, m/s²
        0.773,              // 20 Escape velocity, km/s
        8.706234,           // 21 Sidereal rotation period, days (presumed synchronous)
        <257.311, -15.175, 0>, // 22 North pole, RA, Dec  (USED URANUS)
        0.0,                // 23 Axial inclination, degrees
        0.35,               // 24 Albedo

        //  Extras
        0.5,                // 25 Fractional part of epoch
        @<GM:Uranus@>,      /* 26 Standard gravitational parameter (G M)
                                  of primary, m^3/sec^2  */
        @<Colour:4:yellow@>,    // 27 Colour of trail tracing orbit
        <257.311, -15.175, 0>   // 28 Laplace plane of orbit: RA, Dec, Tilt
    ];
@}

\subparagraph{Satellite object}

@o scripts/planets/uranus/titania/titania.lsl
@{
    @<Explanatory header for LSL files@>

    @<Titania properties@>
    @<Satellite object script@>
@}

\paragraph{Oberon}

\subparagraph{Satellite properties}

@d Oberon properties
@{
    list planet = [
        "Oberon",           // 0  Name of body
        "Uranus",           // 1  Primary

        //  Orbital elements
        2444239,            // 2  Epoch (1980-01-01.0), integer part
        583500,             // 3  a    Semi-major axis, km
        0.0014,             // 4  e    Eccentricity
        0.068,              // 5  i    Inclination, degrees
        279.771,            // 6  Ω    Longitude of the ascending node, degrees
        104.400,            // 7  ω    Argument of periapsis, degrees
        283.088,            // 8  M    Mean anomaly, degrees

        //  Orbital element precession periods
        0,                  // 9  a
        0,                  // 10 e
        0,                  // 11 i
        195.37,             // 12 Ω    Precession period/years
        161.52,             // 13 ω    Precession period/years
        0,                  // 14 M

        //  Physical properties
        761.4,              // 15 Equatorial radius, km
        761.4,              // 16 Polar radius, km
        3.076e21,           // 17 Mass, kg
        1.63,               // 18 Mean density, g/cm³
        0.346,              // 19 Surface gravity, m/s²
        0.727,              // 20 Escape velocity, km/s
        13.463234,          // 21 Sidereal rotation period, days (presumed synchronous)
        <257.311, -15.175, 0>, // 22 North pole, RA, Dec  (USED URANUS)
        0.0,                // 23 Axial inclination, degrees
        0.31,               // 24 Albedo

        //  Extras
        0.5,                // 25 Fractional part of epoch
        @<GM:Uranus@>,      /* 26 Standard gravitational parameter (G M)
                                  of primary, m^3/sec^2  */
        @<Colour:5:green@>,     // 27 Colour of trail tracing orbit
        <257.311, -15.175, 0>   // 28 Laplace plane of orbit: RA, Dec, Tilt
    ];
@}

\subparagraph{Satellite object}

@o scripts/planets/uranus/oberon/oberon.lsl
@{
    @<Explanatory header for LSL files@>

    @<Oberon properties@>
    @<Satellite object script@>
@}

\subsection{Neptune}

\begin{wrapfigure}{r}{4cm}
\centering
\includegraphics[width=3.8cm]{figures/orbits_neptune.png}
\end{wrapfigure}
Neptune is a straightfoward planet, treated like Jupiter, with
only a single large satellite, Triton, which we model.

@d Neptune properties
@{
    list planet = [
        "Neptune",          // 0  Name of body
        "Sun",              // 1  Primary

        //  Orbital elements
        @<J2000@>,          // 2  Epoch (J2000), integer to avoid round-off

        30.06896348,        // 3  a    Semi-major axis, AU
        0.00858587,         // 4  e    Eccentricity
        1.76917,            // 5  i    Inclination, degrees
        131.72169,          // 6  Ω    Longitude of the ascending node, degrees
        44.97135,           // 7  ω    Argument of periapsis, degrees
        304.88003,          // 8  L    Mean longitude, degrees

        //  Orbital element centennial rates
        -0.00125196,        // 9  a    AU/century
        0.0000251,          // 10 e    e/century
        -3.64,              // 11 i    "/century
        -151.25,            // 12 Ω    "/century
        -844.43,            // 13 ω    "/century
        786449.21,          // 14 L    "/century

        //  Physical properties
        24764.0,            // 15 Equatorial radius, km
        24341.0,            // 16 Polar radius, km
        1.02413e26,         // 17 Mass, kg
        1.638,              // 18 Mean density, g/cm³
        11.15,              // 19 Surface gravity, m/s²
        23.5,               // 20 Escape velocity, km/s
        0.6713,             // 21 Sidereal rotation period, days
        <299.3, 42.950, 0>, // 22 North pole, RA, Dec
        28.32,              // 23 Axial inclination, degrees
        0.442,              // 24 Albedo

        //  Extras
        0.0,                // 25 Fractional part of epoch
        @<GM:Sun@>,         /* 26 Standard gravitational parameter (G M)
                                  of primary, m^3/sec^2  */
        @<Colour:8:grey@>   // 27 Colour of trail tracing orbit
    ];
@}

\subsubsection{Planet object}

@o scripts/planets/neptune/neptune.lsl
@{
    @<Explanatory header for LSL files@>

    @<Neptune properties@>
    @<Planet object script@'@'@'@'@'@'@>
@}

\subsubsection{Ephemeris}

@o scripts/planets/neptune/eph_neptune.lsl
@{
    @<Explanatory header for LSL files@>

    integer BODY = 8;               // Our body number

@<Neptune periodic terms@>

@<Ephemeris link messages@>

@<Ephemeris calculator prologue@>

    @<Ephemeris term evaluator L0@>
    @<Ephemeris term evaluator L1@>
    @<Ephemeris term evaluator L2@>
    @<Ephemeris term evaluator L3@>
    @<Ephemeris term evaluator L4@>

    @<Ephemeris term evaluator B0@>
    @<Ephemeris term evaluator B1@>
    @<Ephemeris term evaluator B2@>
    @<Ephemeris term evaluator B3@>
    @<Ephemeris term evaluator B4@>

    @<Ephemeris term evaluator R0@>
    @<Ephemeris term evaluator R1@>
    @<Ephemeris term evaluator R2@>
    @<Ephemeris term evaluator R3@>

@<Ephemeris calculator epilogue@>

@<Ephemeris request processor@<Ephemeris request processor memory status@>@>
@}

\subsubsection{Satellites}

\paragraph{Triton}

\subparagraph{Satellite properties}

The {\tt planet} list declares the specifics of this satellite
such as its orbit, physical properties, and rotation.  It contains
all of the parameters required by the generic ``Satellite object
script''.

@d Triton properties
@{
    list planet = [
        "Triton",           // 0  Name of body
        "Neptune",          // 1  Primary

        //  Orbital elements
        @<J2000@>,          // 2  Epoch (J2000), integer to avoid round-off
        354759,             // 3  a    Semi-major axis, km
        0.000016,           // 4  e    Eccentricity
        156.865,            // 5  i    Inclination, degrees
        177.608,            // 6  Ω    Longitude of the ascending node, degrees
        66.142,             // 7  ω    Argument of periapsis, degrees
        352.257,            // 8  M    Mean anomaly, degrees

        //  Orbital element precession periods
        0,                  // 9  a
        0,                  // 10 e
        0,                  // 11 i
        687.446,            // 12 Ω    Precession period/years
        386.371,            // 13 ω    Precession period/years
        0,                  // 14 M

        //  Physical properties
        1353.4,             // 15 Equatorial radius, km
        1353.4,             // 16 Polar radius, km
        2.1390e22,          // 17 Mass, kg
        2.061,              // 18 Mean density, g/cm³
        0.779,              // 19 Surface gravity, m/s²
        1.455,              // 20 Escape velocity, km/s
        5.876854,           // 21 Sidereal rotation period, days (presumed synchronous)
        <299.3, 42.950, 0>, // 22 North pole, RA, Dec  (USED NEPTUNE)
        0.0,                // 23 Axial inclination, degrees
        0.76,               // 24 Albedo

        //  Extras
        0.0,                // 25 Fractional part of epoch
        @<GM:Neptune@>,     /* 26 Standard gravitational parameter (G M)
                                  of primary, m^3/sec^2  */
        @<Colour:1:brown@>, // 27 Colour of trail tracing orbit
        <299.456, 43.414, 0.010>    // 28 Laplace plane of orbit: RA, Dec, Tilt
    ];
@}

\subparagraph{Satellite object}

@o scripts/planets/neptune/triton/triton.lsl
@{
    @<Explanatory header for LSL files@>

    @<Triton properties@>
    @<Satellite object script@>
@}

\subsection{Pluto}

\begin{wrapfigure}{r}{4cm}
\centering
\includegraphics[width=3.8cm]{figures/orbits_pluto.png}
\end{wrapfigure}
Pluto is an outlier in more ways than one.  It has the most inclined
and eccentric orbit of any planet, its north pole points south of the
ecliptic, and it has the largest moon by comparison to the planet of
any known solar system body.  All of this makes it an excellent test
case for our modeling code.  Because the moon, Charon, is so large
compared to Pluto, the two actually orbit around a barycentre outside
the planet.  We do not model that, but rather compute the position of
Pluto and compute the orbit of Charon relative to it.

@d Pluto properties
@{
    list planet = [
        "Pluto",            // 0  Name of body
        "Sun",              // 1  Primary

        //  Orbital elements
        @<J2000@>,          // 2  Epoch (J2000), integer to avoid round-off

        39.48168677,        // 3  a    Semi-major axis, AU
        0.24880766,         // 4  e    Eccentricity
        17.14175,           // 5  i    Inclination, degrees
        110.30347,          // 6  Ω    Longitude of the ascending node, degrees
        224.06676,          // 7  ω    Argument of periapsis, degrees
        238.92881,          // 8  L    Mean longitude, degrees

        //  Orbital element centennial rates
        -0.00076912,        // 9  a    AU/century
        0.00006465,         // 10 e    e/century
        11.07,              // 11 i    "/century
        -37.33,             // 12 Ω    "/century
        -132.25,            // 13 ω    "/century
        522747.90,          // 14 L    "/century

        //  Physical properties
        1188.3,             // 15 Equatorial radius, km
        1188.3,             // 16 Polar radius, km
        1.303e22,           // 17 Mass, kg
        1.854,              // 18 Mean density, g/cm³
        0.620,              // 19 Surface gravity, m/s²
        1.212,              // 20 Escape velocity, km/s
        6.387230,           // 21 Sidereal rotation period, days
        <132.993, −6.163, 0>,// 22 North pole, RA, Dec
        122.53,             // 23 Axial inclination, degrees
        0.575,              // 24 Albedo

        //  Extras
        0.0,                // 25 Fractional part of epoch
        @<GM:Sun@>,         /* 26 Standard gravitational parameter (G M)
                                  of primary, m^3/sec^2  */
        @<Colour:9:white@>  // 27 Colour of trail tracing orbit
    ];
@}

\subsubsection{Planet object}

@o scripts/planets/pluto/pluto.lsl
@{
    @<Explanatory header for LSL files@>

    @<Pluto properties@>
    @<Planet object script@'@'@'@'@'@'@>
@}

\subsubsection{Ephemeris}

@o scripts/planets/pluto/eph_pluto.lsl
@{
    @<Explanatory header for LSL files@>

    integer BODY = 9;               // Our body number

    key owner;                          // UUID of owner
    key whoDat;                         // User with whom we're communicating

@<Ephemeris link messages@>
@}

These are the orbital elements for Pluto from the JPL Small-Body
Database.  Only those specified in the database are here;
below we'll synthesise those not given.

@o scripts/planets/pluto/eph_pluto.lsl
@{
    list s_elem = [
        "Pluto",                // 0    Name
        2454000, 0.5,           // 1,2  epoch [ jd, jdf ]
        39.4450697257358,       // 3    a (semi-major axis)
        0.250248713478499,      // 4    e (eccentricity)
        17.089000919562,        // 5    i (inclination)
        112.5971416774872,      // 6    ῶ (argument of periapse)
        110.3769579554089,      // 7    Ω (longitude of ascending node)
        25.24718971218841,      // 8    M (mean anomaly)
        -0.4,                   // 9    H (magnitude)
        0.15,                   // 10   G (magnitude slope)
        0, 0.0,                 // 11,12 Tp (time of perhelion)
        0.0,                    // 13   q (periapse distance)
        0.0,                    // 14   n (mean motion)
        0.0,                    // 15   P (orbital period)
        0.0                     // 16   Q (apoapse distance)
    ];
@}

Import utility functions used in the ephemeris calculator.

@o scripts/planets/pluto/eph_pluto.lsl
@{
@<sgn: Sign of argument@>
@<Hyperbolic trigonometric functions@>
@<gKepler: General motion in gravitational field@>
@<obliqeq: Obliquity of the ecliptic@>
@<computeOrbit: Compute position of body in orbit@>
@<posPlanet: Compute solar system object position from orbital elements@>
/*
@<dumpOrbitalElements: Dump orbital elements@>
*/
@<tawk: Send a message to the interacting user in chat@>
@}

The event handler responds to requests from the Deployer script.

@o scripts/planets/pluto/eph_pluto.lsl
@{

    default {
        state_entry() {
            whoDat = owner = llGetOwner();
@}

The following code synthesises the complete set of orbital elements
from those we've specified in the static declaration of {\tt s\_elem}
at the top, taken from the JPL Small-Body Database.  This is adapted
from the code in the {\tt parseOrbitalElements()}
(\ref{parseOrbitalElements}) function of Minor Planets, with unneeded
generality removed.

@o scripts/planets/pluto/eph_pluto.lsl
@{
            float m_a = llList2Float(s_elem, 3);
            float m_e = llList2Float(s_elem, 4);
            float m_M = llList2Float(s_elem, 8);

            /*  Compute the periapse date from the epoch,
                semi-major axis, and mean anomaly.  */
            float peridelta = llSqrt(m_a * m_a * m_a) * m_M * (365.2422 / 360);
            integer pdi = llFloor(peridelta);
            peridelta -= pdi;
            integer pjd = llList2Integer(s_elem, 1) - pdi;
            float pjdf = llList2Float(s_elem, 2) - peridelta;
            while (pjdf < 0) {
                pjdf += 1;
                pjd--;
            }
            s_elem = llListReplaceList(s_elem, [ pjd, pjdf ], 11, 12);

            /*  Compute periapse distance from semi_major axis
                and eccentricity.  */
            s_elem = llListReplaceList(s_elem, [ m_a - (m_a * m_e) ], 13, 13);

            /*  Compute mean motion.  The magic number in the
                numerator is the Gaussian gravitational constant
                k = 0.01720209895 radians/day converted to degrees.
                The apoapse distance is computed from the semi-major
                axis and eccentricity and is, of course, only defined
                for elliptical orbits.  */
            float m_n = 0.9856076686 / (m_a * llSqrt(m_a));
            s_elem = llListReplaceList(s_elem, [ 360 / m_n, (1 + m_e) * m_a ], 15, 16);
//dumpOrbitalElements(s_elem);
        }
@}

Our link message handler responds to the previously-defined ephemeris
calculation and memory status requests.

@o scripts/planets/pluto/eph_pluto.lsl
@{

        link_message(integer sender, integer num, string str, key id) {
            @<Auxiliary services messages@>

            @<Ephemeris request processor position calculation@>
            @<Ephemeris request processor memory status@>
            @<Check build number in Deployer scripts@>
            }
        }
    }
@}

\subsubsection{Satellites}

\paragraph{Charon}

\subparagraph{Satellite properties}

@d Charon properties
@{
    list planet = [
        "Charon",           // 0  Name of body
        "Pluto",            // 1  Primary

        //  Orbital elements
        @<J2000@>,          // 2  Epoch (J2000), integer to avoid round-off
        19591,              // 3  a    Semi-major axis, km
        0.0002,             // 4  e    Eccentricity
        0.080,              // 5  i    Inclination, degrees
        26.928,             // 6  Ω    Longitude of the ascending node, degrees
        146.106,            // 7  ω    Argument of periapsis, degrees
        131.07,             // 8  M    Mean anomaly, degrees

        //  Orbital element precession periods
        0,                  // 9  a
        0,                  // 10 e
        0,                  // 11 i
        9020.398,           // 12 Ω    Precession period/years
        10178.040,          // 13 ω    Precession period/years
        0,                  // 14 M

        //  Physical properties
        606.0,              // 15 Equatorial radius, km
        606.0,              // 16 Polar radius, km
        1.58e21,            // 17 Mass, kg
        1.702,              // 18 Mean density, g/cm³
        0.288,              // 19 Surface gravity, m/s²
        0.59,               // 20 Escape velocity, km/s
        6.387230,           // 21 Sidereal rotation period, days (presumed synchronous)
        <132.993, −6.163, 0>, // 22 North pole, RA, Dec  (USED PLUTO)
        0.0,                // 23 Axial inclination, degrees
        0.4,                // 24 Albedo

        //  Extras
        0.0,                // 25 Fractional part of epoch
        @<GM:Pluto@>,       /* 26 Standard gravitational parameter (G M)
                                  of primary, m^3/sec^2  */
        @<Colour:1:brown@>, // 27 Colour of trail tracing orbit
        <132.993, −6.163, 0>    // 28 Laplace plane of orbit: RA, Dec, Tilt
    ];
@}

\subparagraph{Satellite object}

@o scripts/planets/pluto/charon/charon.lsl
@{
    @<Explanatory header for LSL files@>

    @<Charon properties@>
    @<Satellite object script@>
@}

\subsection{Minor Planets}

This script handles specification of the orbits of minor planets
(asteroids and comets) and computation of their positions from their
orbital elements.  It handles bodies in elliptical, parabolic, and
hyperbolic orbits, and a variety of orbital element parameterisations.

\subsubsection{Minor planet link messages}

@d Minor planet link messages
@{
    //  Minor planet messages

    integer LM_MP_TRACK = 571;      // Notify tracking minor planet
@| LM_MP_TRACK @}

\subsubsection{Compute solar system object position from orbital elements}

From the orbital elements in {\tt s\_elem} and the date argument,
compute the heliocentric longitude, latitude, and radius of the object.
Most of the heavy lifting is done by {\tt computeOrbit()}
(\ref{computeOrbit}), with this function converting its results to
heliocentric spherical co-ordinates.

@d posPlanet: Compute solar system object position from orbital elements
@{
    list posPlanet(integer jd, float jdf) {
        float obelix = obliqeq(jd, jdf) * DEG_TO_RAD;
        vector pos = computeOrbit(s_elem, [ jd, jdf ],
            0.01720209895, obelix);
        float x = pos.x;
        float y = pos.y;
        float z = pos.z;
        float hra = llAtan2(y, x);
        float hdec = llAtan2(z, llSqrt((x * x) + (y * y)));
        float hrv = llSqrt((x * x) + (y * y) + (z * z));
        float hlong = llAtan2((llSin(hra) * llCos(obelix)) +
                                (llTan(hdec) * llSin(obelix)), llCos(hra));
        float hlat = llAsin(llSin(hdec) * llCos(obelix) -
                                (llCos(hdec) * llSin(obelix) * llSin(hra)));
        return [ hlong, hlat, hrv ];
    }
@}


\subsubsection{Process minor planets command}

The Deployer forwards commands it doesn't process directly to other
scripts via the {\tt LM\_CP\_COMMAND} message.  Here we process
commands that are our responsibility:

\begin{itemize}
\dense
    \item Asteroid
    \item Comet
    \item Clear
    \item Help
    \item Status
\end{itemize}

The Clear and Help commands have nothing to do with minor planets,
and are included here solely to save space in the main command
processor script.

@d processMPCommand: Process minor planets command
@{
    integer processMPCommand(key id, list args) {

        whoDat = id;            // Direct chat output to sender of command

        string message = llList2String(args, 0);
        string lmessage = fixArgs(llToLower(message));
        args = llParseString2List(lmessage, [ " " ], []);   // Command and arguments
        integer argn = llGetListLength(args);       // Number of arguments
        string command = llList2String(args, 0);    // The command
@}

The Asteroid and Comet commands specify the name and orbital elements
of the body.  The commands have precisely the same syntax and differ
only in which model is used to display the body.  A minor planet is
declared as:

\begin{verse}
    {\tt Asteroid}/{\tt Comet} {\tt "}{\em Name}{\tt "}
        {\em elem} {\em value}\ldots
\end{verse}

The {\em Name} must be quoted if it contains spaces and may contain
upper and lower case characters.  The orbit elements are declared by
a series of {\em elem} and {\em value} pairs, where the element is
one of the following identifiers and the {\em value} is its numerical
value, with angles specified in degrees.  You can specify any consistent
set of elements: those which can be derived from the one given will be
computed from them.  All element names may be specified in either upper
or lower case and abbreviated to a single letter.

\hspace{4em}\vbox{
\begin{description}
\dense
    \item[a]        Semi-major axis, AU
    \item[ecc]      Eccentricity
    \item[inc]      Inclination, degrees
    \item[w]        Argument of perigee, degrees
    \item[node]     Longitude of ascending node, degrees
    \item[M]        Mean anomaly, degrees
    \item[H]        Magnitude
    \item[G]        Magnitude slope
    \item[T]        Epoch, Julian day and fraction
    \item[P]        Perigee date, Julian day and fraction
    \item[q]        Periapse distance, AU
\end{description}
}

\noindent
For example, the orbit of Encke's comet might be declared as follows,
with the precision of elements abbreviated in the interest of brevity.

{\footnotesize \tt
   Comet "2P/Encke" t 2457210.5 a 2.215 e 0.848 i 11.78 w 186.545 node 334.56 P 2456618.3 q 0.3359 H 3.4 G 0.12
}

@d processMPCommand: Process minor planets command
@{
        integer isAst;
        if ((isAst = abbrP(command, "as")) || abbrP(command, "co")) {
            if (argn < 2) {
                s_elem = [ ];
                llMessageLinked(LINK_THIS, LM_MP_TRACK,
                    llList2Json(JSON_ARRAY, [ FALSE ]), id);
            } else {
/////list e = parseOrbitalElements(message);
/////dumpOrbitalElements(e);
                list e = parseOrbitalElements(message, 1);
/////tawk("Guzz");
/////dumpOrbitalElements(e);

                if (e != [ ]) {
                    if (s_elem != [ ]) {
                        //  Stop tracking and destroy previous body
                        llMessageLinked(LINK_THIS, LM_MP_TRACK,
                            llList2Json(JSON_ARRAY, [ FALSE ]), id);
                    }
                    s_elem = e;                 // Save active orbital elements

                    //  Inform simulation we're tracking an object
                    llMessageLinked(LINK_THIS, LM_MP_TRACK,
                        llList2Json(JSON_ARRAY,
                            [ TRUE,                     // 0    Status
                              llList2String(s_elem, 0), // 1    Name
                              llList2Float(s_elem, 15), // 2    Orbital period (note NaN m_e >= 1)
                              isAst,                    // 3    Is this asteroid (not comet) ?
                              llList2Integer(s_elem, 11), // 4  Julian day of perihelion...
                              llList2Float(s_elem, 12),   // 5  ...and fraction
                              llList2Float(s_elem, 3),  // 6    Semi-major axis (NaN m_e >= 1)
                              llList2Float(s_elem, 4)   // 7    Eccentricity
                            ]), id);
                }
            }
@}

The Clear command sends white space to local chat to clear up
clutter whilst debugging.

@d processMPCommand: Process minor planets command
@{
        } else if (abbrP(command, "cl")) {
            tawk("\n\n\n\n\n\n\n\n\n\n\n\n\n");
@}

The Help command gives the User Guide notecard to the requester.

@d processMPCommand: Process minor planets command
@{
        } else if (abbrP(command, "he")) {
            llGiveInventory(whoDat, helpFileName);  // Give requester the User Guide notecard
@}

The Status command shows script memory status and, if enabled for
debugging, dumps the orbital elements of the currently-tracked
object.

@d processMPCommand: Process minor planets command
@{
        } else if (abbrP(command, "sta")) {
            string s = llGetScriptName() + " status:\n";

            integer mFree = llGetFreeMemory();
            integer mUsed = llGetUsedMemory();
            s += "  Script memory.  Free: " + (string) mFree +
                 "  Used: " + (string) mUsed + " (" +
                    (string) ((integer) llRound((mUsed * 100.0) / (mUsed + mFree))) + "%)";
            tawk(s);
/*
            if (s_elem != [ ]) {
                tawk("  Tracking:");
                dumpOrbitalElements(s_elem);
            }
*/
        }
        return TRUE;
    }
@}

\subsubsection{Minor planets script}

Finally, we can generate the Minor Planets script, which is placed
in the inventory of the Deployer.

@o scripts/minor_planets.lsl
@{
    @<Explanatory header for LSL files@>

    integer BODY = 10;              // Our body number

    key owner;                      // Owner UUID
    key whoDat = NULL_KEY;          // Avatar who sent command
    string helpFileName = "Fourmilab Orbits User Guide"; // Help notecard name

    list s_elem = [ ];              // Elements of currently tracked body

    @<Gravitational constant in astronomical units@>

    //  Link messages

@<Ephemeris link messages@>
@<Auxiliary services messages@>

@<Command processor messages@>
@<Minor planet link messages@>

@<tawk: Send a message to the interacting user in chat@>

@<sgn: Sign of argument@>
@<Hyperbolic trigonometric functions@>
@<fixangle: Range reduce an angle in degrees@>

@<gKepler: General motion in gravitational field@>
@<obliqeq: Obliquity of the ecliptic@>
@<computeOrbit: Compute position of body in orbit@>

@<parseJD: Parse decimal Julian date and fraction@>
@<spec: Test if value is NaN@>

@<posPlanet: Compute solar system object position from orbital elements@>

@<parseOrbitalElements: Parse orbital elements@>
/*
@<dumpOrbitalElements: Dump orbital elements@>
*/

@<jyearl: Julian day and fraction to Gregorian date@>
@<jhms: Julian day and fraction to UTC time@>
@<editJDtoUTC: Edit Julian day to UTC date and time@>
@<editJDtoDec: Edit Julian day to decimal Julian day and fraction@>

@<fixArgs: Transform vector and rotation arguments to canonical form@>
@<fixQuotes: Consolidate quoted arguments@>
@<abbrP: Test argument, allowing abbreviation@>

@<processMPCommand: Process minor planets command@>
@}

This is our state handler.  It serves exclusively as a processor of
link messages sent by other scripts in the Deployer.

@o scripts/minor_planets.lsl
@{
    default {

        on_rez(integer n) {
            llResetScript();
        }

        state_entry() {
            whoDat = owner = llGetOwner();
            @<Initialise gravitational constant in astronomical units@>
        }
@}

The {\tt link\_message()} event receives commands from other scripts
and processes for which we're responsible.

@o scripts/minor_planets.lsl
@{
        link_message(integer sender, integer num, string str, key id) {
//tawk(llGetScriptName() + " link message sender " + (string) sender + "  num " + (string) num + "  str " + str + "  id " + (string) id);
@}

We listen for commands which are not processed by the main script.
If it's one of ours, {\tt processMPCommand()} will handle it.

@o scripts/minor_planets.lsl
@{

            //  LM_CP_COMMAND (223): Process auxiliary command

            if (num == LM_CP_COMMAND) {
                processMPCommand(id, llJson2List(str));
@}

The {\tt LM\_EP\_CALC} message requests us to compute ephemerides for
the currently-tracked object.  The request may contain multiple Julian
days for which ephemerides are required: we compute each and return
them concatenated in a list identified by the integer ``handle''
supplied with the request.

@o scripts/minor_planets.lsl
@{
            //  LM_EP_CALC (431): Calculate ephemeris

            } else if (num == LM_EP_CALC) {
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
@}

The {\tt LM\_EP\_STAT} message reports our script memory usage in local
chat.  This is a generic message which is processed by all ephemeris
calculators.

@o scripts/minor_planets.lsl
@{
            //  LM_EP_STAT (433): Print memory status

            } else if (num == LM_EP_STAT) {
                integer mFree = llGetFreeMemory();
                integer mUsed = llGetUsedMemory();
                tawk(llGetScriptName() + " status:" +
                     " Script memory.  Free: " + (string) mFree +
                     "  Used: " + (string) mUsed + " (" +
                     (string) ((integer) llRound((mUsed * 100.0) / (mUsed + mFree))) + "%)"
                );
@}

The {\tt LM\_AS\_LEGEND} message updates the floating text legend for
the Deployer. Why is this here?  Because we already have the Julian day
editing functions it needs, and information about the currently tracked
object, if any.  And, of course, it keeps the main script from hitting
the 64 Kb script memory wall.

@o scripts/minor_planets.lsl
@{
            //  LM_AS_LEGEND (541): Update floating text legend

            } else if (num == LM_AS_LEGEND) {
                list args = llJson2List(str);
                string legend;
                if (llList2Integer(args, 0) && (llList2Integer(args, 7) == 0)) {
                    legend = "Time " + (string) llList2Float(args, 1) + " years\n" +
                        "Step " + (string) llList2Integer(args, 2);
                } else {
                    list jdl = llList2List(args, 5, 6);
                    legend = "JD " + editJDtoDec(jdl) +
                        "\nUTC " + editJDtoUTC(jdl) +
                        "\nStep " + (string) llList2Integer(args, 2);
                    if (s_elem != [ ]) {
                        legend += "\nTrack " + llList2String(s_elem, 0);
                    }
                }
                llSetLinkPrimitiveParamsFast(LINK_THIS, [
                    PRIM_TEXT, legend, <0, 1, 0>, 1
                ]);
@}

The {\tt LM\_AS\_VERSION} message requests this script to check its
build number against that of the Deployer and report any discrepancy.

@o scripts/minor_planets.lsl
@{
            @<Check build number in Deployer scripts@>
            }
        }
    }
@}

\subsection{Asteroid and Comet Objects}

These scripts are placed in the Asteroid and Comet objects created by
the Minor Planet script.  They perform the same functions as the planet
object scripts, but are simpler because they don't have to worry about
north pole orientation, rotation (we use a fake random rotation), or
satellites.  On the other hand, ``{\tt kaboom}'' handling: self-destruct if
the body wanders too far from the deployer, is important for these
bodies, some of which have wild and woolly trajectories.

\subsubsection{Boilerplate body definition}

This definition acts like the {\tt planet} list in the major planet
scripts.  Ignore the values, which were simply copied from another
list definition.  The relevant values are filled from the orbital
elements of the body, which are communicated when the object is
created.

@d Boilerplate body definition@'Asteroid@'
@{
    list planet = [
        "@1",               // 0  Name of body
        "Sun",              // 1  Primary

        //  Orbital elements
        2451545,            // 2  Epoch (J2000), integer to avoid round-off

        0.38709893,         // 3  a    Semi-major axis, AU
        0.20563069,         // 4  e    Eccentricity
        7.00487,            // 5  i    Inclination, degrees
        48.33167,           // 6  Ω    Longitude of the ascending node, degrees
        77.45645,           // 7  ω    Argument of periapsis, degrees
        252.25084,          // 8  L    Mean longitude, degrees

        //  Orbital element centennial rates
        0.00000066,         // 9  a    AU/century
        0.00002527,         // 10 e    e/century
        -23.51,             // 11 i    "/century
        -446.30,            // 12 Ω    "/century
        573.57,             // 13 ω    "/century
        538101628.29,       // 14 L    "/century

        //  Physical properties (unknown for all but a very few)
        0,                  // 15 Equatorial radius, km
        0,                  // 16 Polar radius, km
        0,                  // 17 Mass, kg
        0,                  // 18 Mean density, g/cm³
        0,                  // 19 Surface gravity, m/s²
        0,                  // 20 Escape velocity, km/s
        0,                  // 21 Sidereal rotation period, days
        ZERO_VECTOR,        // 22 North pole, RA, Dec
        0,                  // 23 Axial inclination, degrees
        0,                  // 24 Albedo

        //  Extras
        0.0,                // 25 Fractional part of epoch
        @<GM:Sun@>,         /* 26 Standard gravitational parameter (G M)
                                  of primary, m^3/sec^2  */
        @<Colour:10:silver@>    // 27 Colour of trail tracing orbit
     ];
@}

\subsubsection{Comet coma messages}

Comets have a separate linked prim to generate the coma around
the nucleus.  These messages are used by the main script to
communicate with the prim that manages the coma.

@d Comet coma and tail messages
@{
//float tailtogg = 0; // Comet tail toggle
    //  Link messages

    integer LM_CO_COMA = 81;            // Set coma intensity
    integer LM_CO_SCALE = 82;           // Set scale factor
@}

\subsubsection{Comet tail generation}

For comets, the tail is generated by a particle system in the main
object.  The function sets the length of the tail or, if {\tt length}
is zero, turns off display of the tail.

@d tail: Comet tail generation
@{
    tail(float length) {
        if (length > 0) {
            llParticleSystem([

                //  System Behaviour
                PSYS_PART_FLAGS,
                                   PSYS_PART_EMISSIVE_MASK
                                 | PSYS_PART_FOLLOW_SRC_MASK
                                 | PSYS_PART_INTERP_COLOR_MASK
                                 | PSYS_PART_INTERP_SCALE_MASK,

                //  System Presentation
                PSYS_SRC_PATTERN,
                                PSYS_SRC_PATTERN_DROP,

                PSYS_SRC_BURST_RADIUS, 0.1,
                PSYS_SRC_ANGLE_BEGIN,  0,
                PSYS_SRC_ANGLE_END,    0.5,

                //  Particle appearance
                PSYS_PART_START_COLOR, < 1, 1, 1 >,
                PSYS_PART_END_COLOR,   < 1, 1, 1 >,
                PSYS_PART_START_ALPHA, 0.2,
                PSYS_PART_END_ALPHA,   0,
                PSYS_PART_START_SCALE, < 0.03, 0.03, 0.03 >,
                PSYS_PART_END_SCALE,   < 0.5, 0.5, 0.5 >,
                PSYS_PART_START_GLOW,  0.0,
                PSYS_PART_END_GLOW,    0.0,

                //  Particle Blending
                PSYS_PART_BLEND_FUNC_SOURCE,
                                           PSYS_PART_BF_SOURCE_ALPHA,
                PSYS_PART_BLEND_FUNC_DEST,
                                           PSYS_PART_BF_ONE_MINUS_SOURCE_ALPHA,

                //  Particle Flow
                PSYS_SRC_MAX_AGE,          0,
                PSYS_PART_MAX_AGE,         1 * length,
                PSYS_SRC_BURST_RATE,       0.01,
                PSYS_SRC_BURST_PART_COUNT, 12,

                //  Particle Motion
                PSYS_SRC_ACCEL,           llVecNorm(llGetPos() - deployerPos),
                PSYS_SRC_OMEGA,           <0, 0, 0>,
                PSYS_SRC_BURST_SPEED_MIN, 1,
                PSYS_SRC_BURST_SPEED_MAX, 1

            ]);
        } else {
            llParticleSystem([ ]);
        }
    }
@| tail @}

\subsubsection{Asteroid and comet common functions}

The folllowing functions are used by both the Asteroid and
Comet object scripts.

@d Asteroid and comet common functions
@{
    @<Planet and minor planet global variables@>

    @<kaboom: Destroy object@>

    @<siuf: Decode base64-encoded floating point number@>
    @<sv: Decode base64-encoded vector@>

    @<ef: Edit floating point number to readable representation@>
    @<eff: Edit float to readable representation@>
    @<efv: Edit vector to readable representation@>

    @<flRezRegion: Rez object anywhere in region@>
    @<flPlotLine: Plot line in space@>

    @<randVec: Random Unit Vector Generation@>
    @<rectSph: Rectangular to spherical co-ordinate conversion@>
    @<fixangr: Range reduce an angle in radians@>

    @<updateLegendPlanet: Update planet legend@>

    @<tawk: Send a message to the interacting user in chat@>
@}

\subsubsection{Asteroid and comet initialisation}

Handle initialisation of the object when created.  The argument allows
passing in code specific to the body type at state entry (specifically,
for comets, clearing the tail display).

@d Asteroid and comet initialisation@'@'
@{
    default {

        state_entry() {
            whoDat = owner = llGetOwner();
            llSetLinkPrimitiveParamsFast(LINK_THIS, [
                PRIM_TEXT, "", ZERO_VECTOR, 0
            ]);
            @1
        }

        on_rez(integer start_param) {
            initState = 0;

            //  If start_param is zero, this is a simple manual rez
            if (start_param != 0) {
                if (start_param == -1) {
                    start_param = 0;
                }
                m_index = start_param;

                ourName = llGetObjectName();
                deployer = llList2Key(llGetObjectDetails(llGetKey(),
                                         [ OBJECT_REZZER_KEY ]), 0);

                //  Set sit target

                llSitTarget(<-0.8, 0, 0>, llAxisAngle2Rot(<0, 1, 0>, -PI_BY_TWO));
                llSetCameraEyeOffset(<-1.2, 0, -1.2>);
                llSetCameraAtOffset(<-1, 0, 1>);

                //  Listen for messages from deployer
                llListen(massChannel, "", NULL_KEY, "");

                //  Inform the deployer that we are now listening
                llRegionSayTo(deployer, massChannel,
                    llList2Json(JSON_ARRAY, [ "PLANTED", m_index ]));

                initState = 1;          // Waiting for SETTINGS and INIT
            }
        }
@}

\subsubsection{Process {\tt PINIT} message for asteroid and comet}

After the body is created, we send a {\tt PLANTED} message back to the
Deployer to let it know we're running and it responds with a {\tt
PINIT} message to provide us the settings from the Deployer that we
need to initialise.   This is just enough different than the code for
major planets that, at the moment, we have our own copy.

The argument allows the comet script to handle initialisation of the
tail upon creation.

@d Process {\tt PINIT} message for asteroid and comet@'@'
@{
        } else if (ccmd == "PINIT") {
            if (m_index == llList2Integer(msg, 1)) {
                m_name = llList2String(msg, 2);             // Name
                deployerPos = sv(llList2String(msg, 3));    // Deployer position
                m_scalePlanet = siuf(llList2String(msg, 4));    // Planet scale

                //  Set properties of object

                //  Compute size of body based upon scale factor

                vector psize = llList2Vector(llGetLinkPrimitiveParams(LINK_THIS,
                    [ PRIM_SIZE ]), 0) * m_scalePlanet;
                @1

                llSetLinkPrimitiveParamsFast(LINK_THIS, [
                    PRIM_DESC,  llList2Json(JSON_ARRAY,
                        [ m_index, m_name ]),
                    PRIM_SIZE, psize,           // Scale to proper size
                    // Start random rotation
                    PRIM_OMEGA, randVec(), llFrand(PI_BY_TWO), 1
                ]);
                llSetStatus(STATUS_PHANTOM | STATUS_DIE_AT_EDGE, TRUE);

                initState = 2;                  // INIT received, waiting for SETTINGS
            }
@}

\subsubsection{Process {\tt UPDATE} message for asteroid and comet}

The {\tt UPDATE} message informs us of our new position.  This is
computed by the Minor Planets script from the orbital elements of the
body and sent directly as the region co-ordinates to which we should
move.

The argument allows comets to update the tail based upon the
new position relative to the Sun.

@d Process {\tt UPDATE} message for asteroid and comet@'@'
@{
        } else if (ccmd == "UPDATE") {
            vector p = llGetPos();
            vector npos = sv(llList2String(msg, 2));
            //  Distance from previous position
            float dist = llVecDist(p, npos);
            //  Distance (AU) from the Sun
            float rvec = llVecDist(npos, deployerPos) / s_auscale;
if (s_trace) {
tawk(m_name + ": Update pos from " + (string) p + " to " + (string) npos +
" dist " + (string) dist);
}
            //  If we've ventured too far, go kaboom
            if ((s_kaboom > 0) & (rvec > s_kaboom)) {
                kaboom(llList2Vector(planet, 27));
                return;
            }

            if (dist >= s_mindist) {
                llSetLinkPrimitiveParamsFast(LINK_THIS,
                    [ PRIM_POSITION, npos ]);
                if (paths) {
                    llSetLinkPrimitiveParamsFast(LINK_THIS,
                        [ PRIM_ROTATION, llRotBetween(<0, 0, 1>, (npos - p)) ]);
                }
                if (s_trails) {
                    flPlotLine(p, npos, llList2Vector(planet, 27), s_pwidth);
                }
                @1
            }
            updateLegendPlanet((npos - deployerPos) / s_auscale);
@}

\subsubsection{Asteroid and comet message processor}

The {\tt listen} event receives messages from the Deployer.
These messages initialise the body and update its position as
the simulation runs.

@d Asteroid and comet message processor@'@'@'@'
@{
        listen(integer channel, string name, key id, string message) {
//llOwnerSay("Planet " + llGetScriptName() + " channel " + (string) channel + " id " + (string) id +  " message " + message);

            if (channel == massChannel) {
                list msg = llJson2List(message);
                string ccmd = llList2String(msg, 0);

                if (id == deployer) {
                @<Process planet ``ypres'' message to self-destruct@'@'@>
                @<Process planet {\tt COLLIDE} message@>
                @<Process planet {\tt LIST} message@>
                @<Process {\tt PINIT} message for asteroid and comet@1@>
@}

\paragraph{Process {\tt SETTINGS} message for asteroid and comet}

The Deployer sends a {\tt SETTINGS} message as soon as we're created to
inform us of the settings at that time and then additional messages
whenever settings change.  Again, what we do here is just enough
different than the way major planets handle settings that we have our
own copy, at least for the moment.

@d Asteroid and comet message processor@'@'@'@'
@{
                    } else if (ccmd == "SETTINGS") {
                        integer bn = llList2Integer(msg, 1);
                        if ((bn == 0) || (bn == m_index)) {
                            integer o_labels = s_labels;

                            paths = llList2Integer(msg, 2);
                            s_trace = llList2Integer(msg, 3);
                            s_kaboom = siuf(llList2String(msg, 4));
                            s_auscale = siuf(llList2String(msg, 5));
                            s_trails = llList2Integer(msg, 7);
                            s_pwidth = siuf(llList2String(msg, 8));
                            s_mindist = siuf(llList2String(msg, 9));
                            s_labels = llList2Integer(msg, 21);

                            //  Update label if state has changed
                            if (s_labels != o_labels) {
                                if (s_labels) {
                                    updateLegendPlanet((llGetPos() - deployerPos) / s_auscale);
                                } else {
                                    llSetLinkPrimitiveParamsFast(LINK_THIS, [
                                        PRIM_TEXT, "", ZERO_VECTOR, 0 ]);
                                }
                            }
                        }

                        if (initState == 2) {
                            initState = 3;                  // INIT and SETTINGS received
                        }

                        //  Set or clear particle trail depending upon paths
                        @<Trace path with particle system @{llList2Vector(planet, 27)@}@>
@}

The {\tt UPDATE} message
gives us the new position for the body when calculated by the
ephemeris calculator (which in this case is right in this script).

@d Asteroid and comet message processor@'@'@'@'
@{
                    @<Process {\tt UPDATE} message for asteroid and comet@2@>
@}

The {\tt VERSION} message requests this script to check its build
number against that of the Deployer and report any discrepancy.  If
this is the comet model, we forward the version check request to the
comet head script, which resides in the separate comet head linked
object.

@d Asteroid and comet message processor@'@'@'@'
@{
                    @<Check build number in created objects@>
                        @<Forward build number check to objects we've created@>
                        if (llList2String(planet, 0) == "Comet") {
                            @<Auxiliary services messages@>
                            llMessageLinked(LINK_ALL_CHILDREN, LM_AS_VERSION,
                                llList2String(msg, 1), id);
                        }
                    }
                }
            }
        }
@}

\subsubsection{Asteroid object script}

This is the script placed in Asteroid objects.

@o scripts/planets/asteroid.lsl
@{
    @<Explanatory header for LSL files@>

    @<Boilerplate body definition@'Asteroid@'@>
    @<Asteroid and comet common functions@>
    @<Asteroid and comet initialisation@'@'@>
        @<Asteroid and comet message processor@'@'@'@'@>
    }
@}

\subsubsection{Comet object script}

This is the script placed in Comet objects.  It is very similar to the
Asteroid script, and differs only in handling of the particle systems
used to display the comet's coma and tail.

@o scripts/planets/comet.lsl
@{
    @<Explanatory header for LSL files@>

    @<Boilerplate body definition@'Comet@'@>
    @<Comet coma and tail messages@>
    @<Asteroid and comet common functions@>
    @<tail: Comet tail generation@>
    @<Asteroid and comet initialisation@'tail(0);@'@>
        @<Asteroid and comet message processor@<Scale comet coma@>@<Update comet tail and coma@>@>
    }
@}

\paragraph{Scale comet coma}

Apply the planet scale factor to the comet's coma.

@d Scale comet coma
@{
llMessageLinked(LINK_THIS, LM_CO_SCALE, (string) m_scalePlanet, id);
@}

\paragraph{Update comet tail and coma}

For comets, we compute the distance to the Sun and display the
coma and tail accordingly.  When we are at a distance of 4
astronomical units or more from the Sun, no coma or tail is
displayed.

@d Update comet tail and coma
@{
        float tailLen = 1 - ((rvec - 1) / 3);
        if (tailLen < 0) {
            tailLen = 0;
        } else if (tailLen > 1) {
            tailLen = 1;
        }
        tail(tailLen);
        llMessageLinked(LINK_ALL_OTHERS, LM_CO_COMA,
            (string) tailLen, id);
@}

\subsubsection{Comet head script}

The comet object consists of two linked prims: the main body of the
comet which contains the main solar system body script.  The comet head
object is invisible and placed at the centre of the comet head. Its
only purpose is to generate the particle system which displays the
comet's coma.  A prim can only host one particle system, and since the
comet body generates the tail, we need the auxiliary head prim to emit
the coma.  This script receives link commands from the main script and
updates the coma particle system as requested.

@o scripts/planets/comet_head.lsl
@{
    @<Explanatory header for LSL files@>

    key owner;                          // UUID of owner
    key whoDat;                         // User with whom we're communicating

    @<Comet coma and tail messages@>
    @<Auxiliary services messages@>
@}

The {\tt head} function controls the particle system that generates
the comet's coma.  The intensity is controlled by the {\tt size}
argument which, if zero, hides the coma.

@o scripts/planets/comet_head.lsl
@{
    head(float size) {
        if (size > 0) {
            llParticleSystem([

                //  System Behaviour
                PSYS_PART_FLAGS,
                                   PSYS_PART_EMISSIVE_MASK
                                 | PSYS_PART_FOLLOW_SRC_MASK
                                 | PSYS_PART_INTERP_COLOR_MASK
                                 | PSYS_PART_INTERP_SCALE_MASK,

                //  System Presentation
                PSYS_SRC_PATTERN,
                                PSYS_SRC_PATTERN_DROP,

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
                                           PSYS_PART_BF_SOURCE_ALPHA,
                PSYS_PART_BLEND_FUNC_DEST,
                                           PSYS_PART_BF_ONE_MINUS_SOURCE_ALPHA,

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
@}

The event handler is simple and straightforward.  At object creation
time the coma is turned off.  When the comet moves, the {\tt UPDATE}
message handler sends a {\tt LM\_CO\_COMA} message to adjust the
appearance of the coma.  The {\tt LM\_CO\_SCALE} message scales the
head object along with its root prim so it doesn't poke through the
comet head body.

@o scripts/planets/comet_head.lsl
@{
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
@}

The {\tt LM\_AS\_VERSION} message requests this script to check its
build number against that of the Deployer and report any discrepancy.

@o scripts/planets/comet_head.lsl
@{
            @<Check build number in Deployer scripts@>
            }
        }
    }
@}

\section{Ecliptic plane}

The user can optionally display the ecliptic plane as a
semi-transparent light blue disc centred on the Sun and extending a
little beyond the orbit of Neptune.  This script runs in the plane
object and manages its simple and minimal interaction with the
Deployer.

Start out with a few global variables.

@o scripts/planets/ecliptic_plane.lsl
@{
    @<Explanatory header for LSL files@>

    key owner;                          // UUID of owner
    key whoDat;                         // User with whom we're communicating
    key deployer;                       // ID of deployer who created us

    integer massChannel = @<massChannel@>;  // Channel for communicating with planets
    string ypres = "B?+:$$";            // It's pronounced "Wipers"
    string planecrash = "P?+:$$";       // Selectively delete ecliptic plane
@}

Now we come to the event handler, starting with the ``in the
beginning'' stuff.  The ecliptic plane object is rezzed in the correct
position and orientation by the Deployer when it receives the ``Set
ecliptic on'' command.  Its region co-ordinates diameter is passed in
the start parameter, in units of centimetres.  Since that's all we need
to know, there's no need for a handshake with the deployer or delivery
of an initial configuration message.

@o scripts/planets/ecliptic_plane.lsl
@{
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
@}

The {\tt listen} event receives and processes messages from the
Deployer. We only listen to messages from the Deployer that created us,
avoiding interference if two are in the same region.

@o scripts/planets/ecliptic_plane.lsl
@{
        listen(integer channel, string name, key id, string message) {

            if (channel == massChannel) {
                list msg = llJson2List(message);
                string ccmd = llList2String(msg, 0);

                if (id == deployer) {
@}

The only messages we care about are those that command us to
self-destruct, either along with everything else in the model, or
just ourselves in response to ``Set ecliptic off''.  And that does
it for the listen message handler and the object script.

@o scripts/planets/ecliptic_plane.lsl
@{
                    if ((ccmd == ypres) || (ccmd == planecrash)) {
                        llDie();
@}

The {\tt VERSION} message requests this script to check its build
number against that of the Deployer and report any discrepancy.

@o scripts/planets/ecliptic_plane.lsl
@{
                    @<Check build number in created objects@>
                    }
                }
            }
        }
    }
@}

\chapter{Galactic Centre}

The Galactic Centre simulation models the trajectories of stars around
the 4 million solar mass black hole (Sagittarius A*) at the centre of
the Milky Way galaxy.  Discovery and analysis of these objects by
observations in infrared wavelengths shared the 2020 Nobel Prize in
Physics.

The Galactic Centre model is similar in structure to that of the
Solar System, computing the orbits (or, for hyperbolic objects,
trajectories) of sources based upon their most recently (as of
March 2021) published orbital elements.  Many of the orbits of
these objects are extreme by the staid standards of the solar system,
with inclinations and eccentricities which are essentially random.
The model is visually intriguing to watch, especially if you enable
the option to trace trajectories.

\section{Link messages}

The Galactic Centre scripts use the following link messages to
communicate with other scripts.

\subsection{Galactic centre messages}

@d Galactic centre messages
@{
    integer LM_GC_SOURCES = 752;        // Report number of sources
@| LM_GC_SOURCES @}

\subsection{Galactic patrol messages}

@d Galactic patrol messages
@{
    integer LM_GP_UPDATE = 771;         // Update positions for Julian day
    integer LM_GP_STAT = 773;           // Report statistics
    integer LM_GP_CENTRE = 774;         // Central mass properties
    integer LM_GP_SOURCE = 775;         // Orbiting source properties
@| LM_GP_UPDATE LM_GP_STAT LM_GP_CENTRE LM_GP_SOURCE @}

\subsection{Galactic centre model}

These variables describe the complete Galactic Centre model.
Identical copies are kept in the Galactic Centre and Galactic Patrol
scripts.

@d Galactic centre model
@{
    list s_sources = [ ];           // Orbital elements of sources
    integer s_sourcesE = 17;        // Size of sources list entry
    list source_keys = [ ];         // Keys of deployed sources

    integer nCentres = 0;           // Number of central bodies
    string nCentre;                 // Name of central body
    float mCentre;                  // Central body mass (solar masses)
    key kCentre;                    // Key of central body
@| s_sources source_keys @}

\section{Galactic centre command processor}

The Galactic Centre command processor creates a model of the galactic
centre by defining the central mass with the ``Centre'' command and
sources on trajectories under its influence with ``Source'' commands.

\subsection{Send settings to galactic centre sources}

Send the current settings to Galactic Centre sources.  Settings may
sent to a specific source by number, or broadcast to all sources if
the number specified is zero and its object key supplied.

@d sendSourceSettings: Send settings to galactic centre sources
@{
    sendSourceSettings(key id, integer source) {
        string msg = llList2Json(JSON_ARRAY, [ "SOURCE_SET", source,
                            paths,
                            s_trace,
                            fuis(s_auscale),
                            fuis(s_radscale),
                            s_trails,
                            fuis(s_pwidth),
                            fuis(s_mindist),
                            s_labels
                      ]);
        if (source == 0) {
            llRegionSay(massChannel, msg);
        } else {
            llRegionSayTo(id, massChannel, msg);
        }
    }
@| sendSourceSettings @}

\subsection{Process Galactic Centre command}

We process three commands forwarded by the Deployer via the
{\tt LM\_CP\_COMMAND} mechanism: ``Centre'', ``Source'', and
``Status''.  The first two define the masses at the galactic
centre, while the last sends our status to local chat.

@d processGCcommand: Process Galactic Centre command
@{
    integer processGCcommand(key id, list args) {

        whoDat = id;            // Direct chat output to sender of command

        string message = llList2String(args, 0);
        string lmessage = llToLower(message);
        args = llParseString2List(lmessage, [ " " ], []);   // Command and arguments
        string command = llList2String(args, 0);    // The command
@| processGCcommand @}

The ``Centre'' command defines the black hole at the galactic centre,
which is origin of our co-ordinate system.  Only one Centre may be
defined, and its only parameters are name and mass (as always, in terms
of solar masses).  Specifying a Centre clears any previously-defined
Sources and may be used to start a new model.

@d processGCcommand: Process Galactic Centre command
@{
        if (abbrP(command, "ce")) {
            nCentres++;
            //  Clear any previous lists of sources
            source_keys = [ ];
            s_sources = [ ];
            //  Re-process arguments to preserve case
            args = fixQuotes(llParseString2List(message, [ " " ], []));
            nCentre = llList2String(args, 1);
            mCentre = llList2Float(args, 3);
            vector eggPos = llGetPos();
            llRezObject("Source", eggPos + <0, 0, s_zoffset>, ZERO_VECTOR,
                llEuler2Rot(<PI_BY_TWO, 0, 0>),
                -1);
            llMessageLinked(LINK_THIS, LM_GC_SOURCES,
                llList2Json(JSON_ARRAY,
                    [ nCentres + llGetListLength(source_keys), // Number of sources
                      0,                            // This source index (0 = centre)
                      nCentre,                      // Name
                      0,                            // Orbital period (0 for centre)
                      0,                            // Time of periapse day...
                      0,                            // ...and fraction
                      0,                            // Eccentricity
                      0                             // Semi-major axis
                    ]), whoDat);
@}

A ``Source'' command adds a source to the Galactic Centre model. Each
source is specified by its name and orbital elements, which may be
supplied in any order or form which uniquely defines the orbit or
(parabolic or hyperbolic) trajectory.  Note that we (correctly) assume
that gravitational interactions among sources may be neglected, and
that they move solely under the influence of the central mass.

@d processGCcommand: Process Galactic Centre command
@{
        } else if (abbrP(command, "so")) {
/////            list e = parseSourceOrbitalElements(message);
/////dumpOrbitalElements(e);
            list e = parseOrbitalElements(message, mCentre);
/////tawk("Msg2 " + message);
/////tawk("Guzz");
/////dumpOrbitalElements(e);
            s_sources += e;
            source_keys += NULL_KEY;        // Reserve space for key
            integer massn = llGetListLength(source_keys);
            vector eggPos = llGetPos();
            vector rwhere = eggPos + <0, 0, s_zoffset>;
            //  Initially create source at centre
            llRezObject("Source", rwhere, ZERO_VECTOR,
                llEuler2Rot(<PI_BY_TWO, 0, 0>),
                massn);
            llMessageLinked(LINK_THIS, LM_GC_SOURCES,
                llList2Json(JSON_ARRAY,
                    [ nCentres + llGetListLength(source_keys), // 0  Number of sources
                      llGetListLength(source_keys), // 1    Source index
                      llList2String(e, 0),          // 2    Name
                      llList2Float(e, 15),          // 3    Orbital period (NaN if eccentricity >= 1)
                      llList2Integer(e, 11),        // 4    Time of periapse day...
                      llList2Float(e, 12),          // 5    ...and fraction
                      llList2Float(e, 4),           // 6    Eccentricity
                      llList2Float(e, 3)            // 7    Semi-major axis (NaN if eccentricity >= 1)
                    ]), whoDat);
@}

The ``Status'' command simply shows our script memory usage in local
chat.  It is sent by the Deployer when overall status is requested.

@d processGCcommand: Process Galactic Centre command
@{
        } else if (abbrP(command, "sta")) {
            string s = llGetScriptName() + " status:\n";

            integer mFree = llGetFreeMemory();
            integer mUsed = llGetUsedMemory();
            s += "  Script memory.  Free: " + (string) mFree +
                    "  Used: " + (string) mUsed + " (" +
                    (string) ((integer) llRound((mUsed * 100.0) / (mUsed + mFree))) + "%)";
            tawk(s);
        }
        return TRUE;
    }
@}

\subsection{Galactic centre script}

Start by defining global variables.

@o scripts/galactic_centre.lsl
@{
    @<Explanatory header for LSL files@>

    key owner;                      // Owner UUID
    key whoDat = NULL_KEY;          // Avatar who sent command

    integer massChannel = @<massChannel@>;  // Channel for communicating with sources

    @<Galactic centre model@>

    @<Gravitational constant in astronomical units@>
@}

To distinguish sources, we assign them arbitrary colours based upon
the order they were defined, using the resistor colour code (including
tolerance band values).

@o scripts/galactic_centre.lsl
@{
    list colours = [
        @<Colour:0:black@>,         // 0
        @<Colour:1:brown@>,         // 1
        @<Colour:2:red@>,           // 2
        @<Colour:3:orange@>,        // 3
        @<Colour:4:yellow@>,        // 4
        @<Colour:5:green@>,         // 5
        @<Colour:6:blue@>,          // 6
        @<Colour:7:violet@>,        // 7
        @<Colour:8:grey@>,          // 8
        @<Colour:9:white@>,         // 9

        @<Colour:10:silver@>,       // 10%
        @<Colour:11:gold@>          // 5%
    ];
@}

These are settings, both sent to the sources and used locally.

@o scripts/galactic_centre.lsl
@{
    //  Settings communicated by deployer
    float s_auscale = 0.3;              // Astronomical unit scale
    float s_radscale = 0.0000025;       // Radius scale
    integer s_trails = FALSE;           // Show trails with temporary prims
    float s_pwidth = 0.01;              // Paths/trails width
    float s_mindist = 0.01;             // Minimum distance to update
    integer s_labels = FALSE;           // Show labels on objects
    //  These settings are not sent to the masses
    float s_deltat = 0.01;              // Integration time step
    float s_zoffset = 1;                // Z offset to create masses
    integer s_legend = FALSE;           // Display legend above deployer
    integer s_trace = FALSE;            // Trace mass behaviour
    integer paths = FALSE;              // Show particle trails from mass ?

    list simEpoch;                      // Epoch of simulation
@}

We use the following link messages to communicate with other
scripts.

@o scripts/galactic_centre.lsl
@{
    @<Command processor messages@>
    @<Auxiliary services messages@>
    @<Galactic centre messages@>
    @<Galactic patrol messages@>
@}

Import utility functions we employ.

@o scripts/galactic_centre.lsl
@{
    @<tawk: Send a message to the interacting user in chat@>

    @<fuis: Encode floating point number as base64 string@>
    @<siuf: Decode base64-encoded floating point number@>

    @<parseJD: Parse decimal Julian date and fraction@>
    @<fixangle: Range reduce an angle in degrees@>
    @<spec: Test if value is NaN@>
    @<fixQuotes: Consolidate quoted arguments@>
    @<abbrP: Test argument, allowing abbreviation@>
    @<parseOrbitalElements: Parse orbital elements@>
/*
    @<dumpOrbitalElements: Dump orbital elements@>
*/
@}

Define local functions.

@o scripts/galactic_centre.lsl
@{
    @<sendSourceSettings: Send settings to galactic centre sources@>
    @<processGCcommand: Process Galactic Centre command@>
@}

Our event processor begins by initialising the script's variables
and beginning to listen on the channel it will use to communicate
with sources it creates.

@o scripts/galactic_centre.lsl
@{
    default {

        on_rez(integer n) {
            llResetScript();
        }

        state_entry() {
            whoDat = owner = llGetOwner();

            @<Initialise gravitational constant in astronomical units@>

            llListen(massChannel, "", NULL_KEY, "");
        }
@}

We listen for link messages from the Deployer which instruct us to do
various things.

@o scripts/galactic_centre.lsl
@{
        link_message(integer sender, integer num, string str, key id) {
//tawk(llGetScriptName() + " link message sender " + (string) sender + "  num " + (string) num + "  str " + str + "  id " + (string) id);
@}

The {\tt LM\_CP\_COMMAND} message forwards commands we process for
execution here.

@o scripts/galactic_centre.lsl
@{
            //  LM_CP_COMMAND (223): Process auxiliary command
            if (num == LM_CP_COMMAND) {
                processGCcommand(id, llJson2List(str));
@}

The {\tt LM\_CP\_REMOVE} message clears any model we've created.  Note
that the Deployer itself sends the ``{\tt ypres}'' message to destroy
the objects we've created, so we needn't do that here.

@o scripts/galactic_centre.lsl
@{
            //  LM_CP_REMOVE (226): Remove simulation objects
            } else if (num == LM_CP_REMOVE) {
                s_sources = [ ];            // Orbital elements of sources
                source_keys = [ ];          // Keys of deployed sources
                nCentres = 0;               // Number of central bodies
@}

The {\tt LM\_AS\_SETTINGS} message informs us when settings change.
We make a local copy of the settings which concern us and forward
them to sources we've created.

@o scripts/galactic_centre.lsl
@{
            //  LM_AS_SETTINGS (542): Update settings from main script
            } else if (num == LM_AS_SETTINGS) {
                list msg = llJson2List(str);

                /*  We only decode settings in which we're interested
                    or wish to pass on to sources we've created.  */
                paths = llList2Integer(msg, 2);
                s_trace = llList2Integer(msg, 3);
                s_auscale = siuf(llList2String(msg, 5));
                s_radscale = siuf(llList2String(msg, 6));
                s_trails = llList2Integer(msg, 7);
                s_pwidth = siuf(llList2String(msg, 8));
                s_mindist = siuf(llList2String(msg, 9));
                s_deltat = siuf(llList2String(msg, 10));
                s_zoffset = siuf(llList2String(msg, 17));
                s_legend = llList2Integer(msg, 18);
                simEpoch = llList2List(msg, 19, 20);
                s_labels = llList2Integer(msg, 21);

                sendSourceSettings(NULL_KEY, 0);
@}

The {\tt LM\_AS\_VERSION} message requests this script to check its
build number against that of the Deployer and report any discrepancy.

@o scripts/galactic_centre.lsl
@{
            @<Check build number in Deployer scripts@>
            }
        }
@}

When we create a new central mass or source, its script sends us a {\tt
SOURCED} message to inform us it's ready to receive commands from us.
We respond by sending an {\tt INIT} message to inform it of its
parameters and the current settings from the Deployer. We then send a
message to the Galactic Patrol to inform the stalwart Lensmen of its
existence in their territory.  This completes the addition of the new
body, and we resume execution of a script which may have been paused
during its creation and initialisation.

@o scripts/galactic_centre.lsl
@{
        listen(integer channel, string name, key id, string message) {
//llOwnerSay(llGetScriptName() + " channel " + (string) channel + " id " + (string) id +  " message " + message);
            if (channel == massChannel) {
                list msg = llJson2List(message);
                string ccmd = llList2String(msg, 0);

                if (ccmd == "SOURCED") {
                    integer mass_number = llList2Integer(msg, 1);
                    vector eggPos = llGetPos() + <0, 0, s_zoffset>;
@}

If the source number is $-1$, this is the central mass.  Initialise
it with the canned parameters we use for it and inform Galactic
Patrol of its existence.

@o scripts/galactic_centre.lsl
@{
                    if (mass_number == -1) {
                        kCentre = id;
                        llRegionSayTo(id, massChannel,
                            llList2Json(JSON_ARRAY, [ "INIT", mass_number,
                            nCentre,                        // Name of body
                            eggPos,                         // Initial position
                            ZERO_VECTOR,                    // Initial velocity
                            mCentre,                        // Mass
                            "<0.15, 0.15, 0.15, 1, 0.2>",   // Colour (extended)
                            75000,                          // Mean radius
                            eggPos                          // Deployer position
                        ]));
                        //  Inform the Galactic Patrol of the new central mass
                        llMessageLinked(LINK_THIS, LM_GP_CENTRE,
                            llList2Json(JSON_ARRAY, [
                                mass_number,                // Mass index
                                kCentre,                    // Central mass key
                                nCentre,                    // Name of body
                                mCentre,                    // Mass
                                eggPos                      // Initial position
                            ]), whoDat);
                    } else {
@}

Otherwise, this is a new source.  Save its key so we can communicate
with it subsequently, send its parameters, and notify Galactic Patrol
to add it to the plotting tank.

@o scripts/galactic_centre.lsl
@{
                        integer mindex = mass_number - 1;
                        //  Save key of mass object in source_keys
                        source_keys = llListReplaceList(source_keys, [ id ],
                            mindex, mindex);

                        integer sindex = mindex * s_sourcesE;
                        integer ncols = llGetListLength(colours) - 1;
                        string colour = (string) llList2Vector(colours,
                            (mindex % ncols) + 1);
                        llRegionSayTo(id, massChannel,
                            llList2Json(JSON_ARRAY, [ "INIT", mass_number,
                            llList2String(s_sources, sindex),       // Name of body
                            eggPos + < mass_number * 0.25, 0, 0 >,  // Initial position
                            ZERO_VECTOR,                            // Initial velocity
                            1,                                      // Mass
                            colour,                                 // Colour (extended)
                            25000,                                  // Mean radius
                            eggPos                                  // Deployer position
                        ]));
                        //  Inform the Galactic Patrol of the new orbiting source
                        llMessageLinked(LINK_THIS, LM_GP_SOURCE,
                            llList2Json(JSON_ARRAY, [
                                mass_number,                        // Source index
                                id ] +                              // Source key
                                simEpoch +                          // Epoch for initial position
                                llList2List(s_sources, mindex * s_sourcesE,
                                    ((mindex + 1) * s_sourcesE) - 1)
                            ), whoDat);
                    }

                    //  Send initial settings
                    sendSourceSettings(id, mass_number);
                    //  Resume deployer script, if suspended
                    llMessageLinked(LINK_THIS, LM_CP_RESUME, "", whoDat);
                }
            }
        }
    }
@}

\section{Galactic patrol}

The Galactic Patrol script handles evolution of the model and updating
sources to their current position.  The Galactic Centre script sends it
the model built from the Centre and Source commands it processes, and
this script updates and displays the model.  The only reason this is
split across two separate scripts (at the cost of substantial
complexity and duplication) is the 64 Kb script memory limit in LSL.

\subsection{Compute position of source}

Compute the position of a Galactic Centre source from its orbital
elements and a specified date.  A list of its rectangular galactic
co-ordinates is returned.

@d posGS: Compute position of source
@{
    list posGS(integer src, integer jd, float jdf) {
        src--;
        s_elem = llList2List(s_sources, src * s_sourcesE, ((src + 1) * s_sourcesE) - 1);
        vector pos = computeOrbit(s_elem, [ jd, jdf ],
/*  MESSY!  This is a phenomenally tacky way to calclate the GaussK
    parameter for the central mass.  We take the parameter for one solar
    mass and then multiply it by the square root of the central mass, which is
    expressed in units of solar masses, as that's how it scales.  There
    must be a cleaner way to derive this from first principles in the interest
    of comprehensibility.  Because we're working in galactic co-ordinates, the
    obliquity of the ecliptic is zero.  */
            llSqrt(mCentre) * 0.01720209895, 0);
        return [ pos.x, pos.y, pos.z ];
    }
@| posGS @}

\subsection{Determine if a source has moved out of range or region}

Test whether a source has moved beyond the ``Set kaboom'' range from
the Deployer or is about to wander outside the boundaries of its
region.  If so, it's probably a zwilnik bent on mischief and the Patrol
is justified employing its primary projectors to destroy it with a
coruscating, actinic blast of pure energy.

@d elKaboom: Determine if a source has moved out of range or region
@{
    integer elKaboom(vector rwhere, vector deployerPos) {
        //  Test if it's beyond our "Set kaboom" range
        if ((s_kaboom > 0) &&
            ((llVecDist(deployerPos, rwhere) / s_auscale) > s_kaboom)) {
            return TRUE;
        }
        //  Is object about to move outside the region ?
        return (rwhere.x < 0) || (rwhere.x >= REGION_SIZE) ||
               (rwhere.y < 0) || (rwhere.y >= REGION_SIZE) ||
               (rwhere.z < 0) || (rwhere.z >= 4096);
    }
@| elKaboom @}

\subsection{Galactic patrol script}

Assemble the Galactic Patrol script, starting as usual with global
variables.

@o scripts/galactic_patrol.lsl
@{
    @<Explanatory header for LSL files@>

    key owner;                      // Owner UUID
    key whoDat = NULL_KEY;          // Avatar who sent command

    integer massChannel = @<massChannel@>;  // Channel for communicating with sources
    float REGION_SIZE = 256;        // Second Life grid region size, metres

    list s_elem = [ ];              // Elements of sources
    @<Galactic centre model@>

    //  Settings communicated by deployer
    float s_kaboom = 50;                // Self destruct if this far (AU) from deployer
    float s_auscale = 0.3;              // Astronomical unit scale
    integer s_labels = FALSE;           // Show labels on objects
    //  These settings are not sent to the masses
    float s_zoffset = 1;                // Z offset to create masses
    integer s_legend = FALSE;           // Display legend above deployer

    list simEpoch;                      // Epoch of simulation
@}

We use the following link messages to communicate with other scripts.

@o scripts/galactic_patrol.lsl
@{
    @<Command processor messages@>
    @<Ephemeris link messages@>
    @<Auxiliary services messages@>
    @<Galactic patrol messages@>
@}

Import the following utility functions.

@o scripts/galactic_patrol.lsl
@{
    @<tawk: Send a message to the interacting user in chat@>

    @<fuis: Encode floating point number as base64 string@>
    @<siuf: Decode base64-encoded floating point number@>

    @<sgn: Sign of argument@>
    @<Hyperbolic trigonometric functions@>
    @<gKepler: General motion in gravitational field@>
    @<computeOrbit: Compute position of body in orbit@>

/*
@<dumpOrbitalElements: Dump orbital elements@>
*/
@}

Define our local functions.

@o scripts/galactic_patrol.lsl
@{
    @<posGS: Compute position of source@>
    @<elKaboom: Determine if a source has moved out of range or region@>
@}

On object creation, we re-initialise the script.  We do not need to
listen for messages from either the Deployer or the sources: all
such communications are handled by Galactic Centre, which passes on
information via link messages.

@o scripts/galactic_patrol.lsl
@{
    default {

        on_rez(integer n) {
            llResetScript();
        }

        state_entry() {
            whoDat = owner = llGetOwner();
        }
@}

All of our actions are in response to requests sent as link messages,
processed as follows.

@o scripts/galactic_patrol.lsl
@{
        link_message(integer sender, integer num, string str, key id) {
//tawk(llGetScriptName() + " link message sender " + (string) sender + "  num " + (string) num + "  str " + str + "  id " + (string) id);
@}

When the Deployer processes a Remove or Boot message, it directly
commands objects to destroy themselves, and sends a {\tt
LM\_CP\_REMOVE} message, which allows us to delete the sources from our
internal tables.

@o scripts/galactic_patrol.lsl
@{
            //  LM_CP_REMOVE (226): Remove simulation objects
            if (num == LM_CP_REMOVE) {
                s_sources = [ ];            // Orbital elements of sources
                source_keys = [ ];          // Keys of deployed sources
                nCentres = 0;               // Number of central bodies
@}

We process {\tt LM\_EP\_CALC} messages requesting ephemeris calculation
almost like the ephemeris calculators for Solar System bodies.  The
main difference is that rather than selecting bodies by a bit map, only
one source ephemeris calculation is requested at a time, by its source
number coded in the high-order 16 bits of the {\em body} field of the
request, distinguishing the request from one for Solar System bodies by
the low-order 16 bits being all zero.

Supporting the ephemeris calculation message allows plotting the paths
of and fitting ellipses to our source objects just as is done for Solar
System bodies.

@o scripts/galactic_patrol.lsl
@{
            //  LM_EP_CALC (431): Calculate ephemeris
            } else if (num == LM_EP_CALC) {
                if (s_sources != [ ]) {
                    list args = llCSV2List(str);
                    integer argn = llGetListLength(args);
                    integer body = llList2Integer(args, 0);
                    integer body_k = (body >> 16) - 1;
                    integer i = body_k * s_sourcesE;
                    if ((i >= 0) && (i < llGetListLength(s_sources))) {
                        s_elem = llList2List(s_sources, i, i + (s_sourcesE - 1));
                        list eph = [ ];

                        for (i = 1; (i + 1) < argn; i += 2) {
                            eph += posGS(body_k + 1, llList2Integer(args, i),
                                                     llList2Float(args, i + 1));
                        }
                        integer handle = llList2Integer(args, i);
                        llMessageLinked(LINK_THIS, LM_EP_RESULT,
                            (string) body + "," +
                            llList2CSV(eph + [ handle ]), id);
                    }
                }
@}

The {\tt LM\_AS\_SETTINGS} message from the Deployer informs us of
changes in settings.  Since the Galactic Centre script takes care
of forwarding settings to the sources, we need only extract settings
which directly control our operation.

@o scripts/galactic_patrol.lsl
@{
            //  LM_AS_SETTINGS (542): Update settings from main script
            } else if (num == LM_AS_SETTINGS) {
                list msg = llJson2List(str);

                /*  We only decode settings in which we're interested
                    or wish to pass on to masses we've created.  */
                s_kaboom = siuf(llList2String(msg, 4));
                s_auscale = siuf(llList2String(msg, 5));
                s_zoffset = siuf(llList2String(msg, 17));
                s_legend = llList2Integer(msg, 18);
                simEpoch = llList2List(msg, 19, 20);
                s_labels = llList2Integer(msg, 21);
@}

The {\tt LM\_AS\_VERSION} message requests this script to check its
build number against that of the Deployer and report any discrepancy.

@o scripts/galactic_patrol.lsl
@{
            @<Check build number in Deployer scripts@>
@}

The {\tt LM\_GP\_UPDATE} message requests we update the positions for
sources at the specified date.  Because Galactic Centre models may
contain a large number of sources and region messages are constrained
by rate of sending rather than byte bandwidth, we pack as many updates
as will fit in a 1024 byte region message and send them in batches from
which the individual sources extract the updates for themselves.
Benchmarking with Fourmilab Gridmark indicates that there is no loss in
efficiency in broadcasting messages via {\tt llRegionSay()} as opposed
to directing them to an individual object with {\tt llRegionSayTo()}.

@o scripts/galactic_patrol.lsl
@{
            //  LM_GP_UPDATE (771):  Update positions for Julian day
            } else if (num == LM_GP_UPDATE) {
                list d = llCSV2List(str);
                integer jd = llList2Integer(d, 0);
                float jdf = llList2Float(d, 1);
                vector deployerPos = llGetPos() + <0, 0, s_zoffset>;

                integer i;
                integer n = llGetListLength(source_keys);
                string upbulk = "U:";
                integer upbulkL = 2;

                for (i = 1; i <= n; i++) {
                    key k = llList2Key(source_keys, i - 1);
                    if (k != NULL_KEY) {
                        list p = posGS(i, jd, jdf);
                        vector pos = < llList2Float(p, 0), llList2Float(p, 1), llList2Float(p, 2) >;
                        vector rwhere = (pos * s_auscale) + deployerPos;
                        if (elKaboom(rwhere, deployerPos)) {
                            //  Source out of range: destroy and remove from list
                            llRegionSayTo(k, massChannel,
                                llList2Json(JSON_ARRAY, [ "KABOOM", i ]));
                            source_keys = llListReplaceList(source_keys,
                                [ NULL_KEY ], i - 1, i - 1);
                        } else {
                            string upsource = "{" + (string) i + "}" +
                                fuis(rwhere.x) + fuis(rwhere.y) + fuis(rwhere.z);
                            integer usL = llStringLength(upsource);
                            if ((upbulkL + usL) > 1024) {
                                llRegionSay(massChannel, upbulk);
                                upbulk = "U:";
                                upbulkL = 2;
                            }
                            upbulk += upsource;
                            upbulkL += usL;
                        }
                    }
                }
                llRegionSay(massChannel, "V" + llGetSubString(upbulk, 1, -1));
@}

When Galactic Centre adds the central mass to the model, it sends a
{\tt LM\_GP\_CENTRE} message to inform us.  We save the mass of the
body and clear any existing sources, preparing to define
a new model.

@o scripts/galactic_patrol.lsl
@{
            //  LM_GP_CENTRE (774): Define new central mass
            } else if (num == LM_GP_CENTRE) {
                list l = llJson2List(str);

                kCentre = llList2Key(l, 1);
                nCentre = llList2String(l, 2);
                mCentre = llList2Float(l, 3);
                // vector eggPos = (vector) llList2String(l, 4);
                nCentres = 1;
                //  Clear any previous lists of sources
                source_keys = [ ];
                s_sources = [ ];
@}

When Galactic Centre adds a source to the model, it sends a {\tt
LM\_GP\_SOURCE} message to notify us.  We save the properties of the
source in our copy of the {\tt s\_sources} list.

@o scripts/galactic_patrol.lsl
@{
            //  LM_GP_SOURCE (775): Define new orbiting source

            } else if (num == LM_GP_SOURCE) {
                list l = llJson2List(str);
                integer sindex = llList2Integer(l, 0);          // Source index
                key skey = llList2Key(l, 1);                    // Source key
                source_keys += skey;
                integer epochJD = llList2Integer(l, 2);         // Epoch Julian day and fraction
                float epochJDf = llList2Float(l, 3);
                s_sources += llList2List(l, 4, -1);             // Source parameters
                list p = posGS(sindex, epochJD, epochJDf);
                vector pos = < llList2Float(p, 0), llList2Float(p, 1), llList2Float(p, 2) >;
                vector rwhere = (pos * s_auscale) + llGetPos() + <0, 0, s_zoffset>;
                llRegionSayTo(skey, massChannel, "U:{" + (string) sindex + "}" +
                    fuis(rwhere.x) + fuis(rwhere.y) + fuis(rwhere.z));
@}

Report our script memory status when requested by the Status command
in the Deployer.

@o scripts/galactic_patrol.lsl
@{
           //  LM_GP_STAT (773): Report status
            } else if (num == LM_GP_STAT) {
                string s = llGetScriptName() + " status:\n";

                integer mFree = llGetFreeMemory();
                integer mUsed = llGetUsedMemory();
                s += "  Script memory.  Free: " + (string) mFree +
                        "  Used: " + (string) mUsed + " (" +
                        (string) ((integer) llRound((mUsed * 100.0) / (mUsed + mFree))) + "%)";
                tawk(s);
            }
        }
    }
@}

\section{Source object}

The sources are entirely controlled by the orbital position evaluator
in Galactic Patrol and have no autonomy.  The central mass is simply
a source with an index number of $-1$ located at the origin.

\subsection{Update position of source}

This function moves a source from its current position to the new
position given by the argument.  The distance being moved is
calculated, and if less than the {\tt s\_mindist} setting no move is
performed.  If the object is moving 10 metres or more, we move it with
{\tt llSetRegionPos()}, otherwise the faster {\tt
llSetLinkPrimitiveParamsFast}\ldots {\tt PRIM\_POSITION} is used. If
{\tt s\_trails} are enabled, a trail object is created between the old
and new positions.

@d updateSourcePosition: Update position of source
@{
    updateSourcePosition(vector npos) {
        vector p = llGetPos();
        float dist = llVecDist(p, npos);
        if (s_trace) {
            tawk(m_name + ": Update pos from " + (string) p + " to " + (string) npos +
        " dist " + (string) dist);
        }
        if (dist >= s_mindist) {
            if (dist >= 10) {
                //  If we've moved more than 10 metres, use llSetRegionPos()
                llSetRegionPos(npos);
            } else {
                llSetLinkPrimitiveParamsFast(LINK_THIS,
                    [ PRIM_POSITION, npos ]);
            }
            if (paths) {
                llSetLinkPrimitiveParamsFast(LINK_THIS,
                [ PRIM_ROTATION, llRotBetween(<0, 0, 1>, (npos - p)) ]);
            }
            if (s_trails) {
                flPlotLine(p, npos, m_colour, s_pwidth);
            }
        }
    }
@| updateSourcePosition @}

\subsection{Display floating text label}

If enabled, display the source's name as floating text above the
object.

@d Display floating text label
@{
    if (s_labels) {
        llSetLinkPrimitiveParamsFast(LINK_THIS, [
            PRIM_TEXT, m_name, <0, 0.75, 0>, 1
        ]);
    } else {
        llSetLinkPrimitiveParamsFast(LINK_THIS, [
            PRIM_TEXT, "", ZERO_VECTOR, 0
        ]);
    }
@}

\subsection{Object script}

This script runs in each source in the Galactic Centre simulation.  It
is identical for all bodies, parameterised by the {\tt INIT} message
sent by the Deployer when it is created.  We start by declaring global
variables.  These are similar to those for Solar System objects, but
with enough differences to make unification of them not worth the
bother.

@o scripts/galcent/source.lsl
@{
    @<Explanatory header for LSL files@>

    key owner;                          // UUID of owner
    key deployer;                       // ID of deployer who hatched us
    integer initState = 0;              // Initialisation state

    //  Properties of this mass
    integer s_trace = FALSE;            // Trace operations
    integer m_index;                    // Our mass index
    string m_name;                      // Name
    integer s_labels;                   // Show floating text label ?
    float m_mass;                       // Mass
    vector m_colour;                    // Colour
    float m_alpha;                      // Alpha (0 transparent, 1 solid)
    float m_glow;                       // Glow (0 none, 1 intense)
    float m_radius;                     // Mean radius

    string m_upkey;                     // Update key for bulk updates
    integer m_upkeyL;                   // Update key length

    //  Settings communicated by deployer
    float s_auscale = 0.2;              // Astronomical unit scale
    float s_radscale = 0.0000025;       // Radius scale
    integer s_trails = FALSE;           // Plot orbital trails ?
    float s_pwidth = 0.01;              // Paths/trails width
    float s_mindist = 0.1;              // Minimum distance to move

    integer massChannel = @<massChannel@>;  // Channel for communicating with the deployer
    string ypres = "B?+:$$";            // It's pronounced "Wipers"
    string Collision = "Balloon Pop";   // Explosion sound clip

    vector deployerPos;                 // Deployer position

    float startTime;                    // Time we were hatched

    key whoDat;                         // User with whom we're communicating
    integer paths;                      // Draw particle trail behind masses ?
    /* IF TRACE */
    integer b1;                         // Used to trace only mass 1
    /* END TRACE */
@}

We use a number of utility functions shared with other simulations and
models, as well as some of our own.

@o scripts/galcent/source.lsl
@{
    //  Shared utility functions
    @<siuf: Decode base64-encoded floating point number@>
    @<flRezRegion: Rez object anywhere in region@>
    @<flPlotLine: Plot line in space@>
    @<kaboom: Destroy object@>
    @<tawk: Send a message to the interacting user in chat@>
    @<exColour: Parse extended colour specification@>

    //  Model-specific functions
    @<updateSourcePosition: Update position of source@>
@}

This is our event handler, which has only the single {\tt default}
state.  Entry to the state is straightforward.

@o scripts/galcent/source.lsl
@{
    default {

        state_entry() {
            whoDat = owner = llGetOwner();
        }
@}

At object creation ({\tt on\_rez}) time, we build the unique key which
will identify updates for us in the bulk messages sent by the position
computation process.  We set a sit target for those who wish to ride
the object, start listening for messages from the Deployer, and send a
{\tt SOURCED} message to inform it that this source script is up and
running.

@o scripts/galcent/source.lsl
@{
        on_rez(integer start_param) {
            initState = 0;

            //  If start_param is zero, this is a simple manual rez
            if (start_param != 0) {
                m_index = start_param;

                //  Build search string for update key from m_index
                m_upkey = "{" + (string) m_index + "}";
                m_upkeyL = llStringLength(m_upkey);

                deployer = llList2Key(llGetObjectDetails(llGetKey(),
                            [ OBJECT_REZZER_KEY ]), 0);

                //  Set sit target

                llSitTarget(<-0.8, 0, 0>, llAxisAngle2Rot(<0, 1, 0>, -PI_BY_TWO));
                llSetCameraEyeOffset(<-1.2, 0, -1.2>);
                llSetCameraAtOffset(<-1, 0, 1>);

                //  Listen for messages from our deployer
                llListen(massChannel, "", NULL_KEY, "");

                //  Inform the deployer that we are now listening
                llRegionSayTo(deployer, massChannel,
                    llList2Json(JSON_ARRAY, [ "SOURCED", m_index ]));

                initState = 1;          // Waiting for SETTINGS and INIT
            }
        }
@}

The {\tt listen} event receives messages from the Deployer to provide
our initial parameters, settings, position updates, and notice of when
it's time to go away.

@o scripts/galcent/source.lsl
@{
        listen(integer channel, string name, key id, string message) {
//llOwnerSay("Source channel " + (string) channel + " id " + (string) id +  " message " + message);

            if (channel == massChannel) {
////////// CHECK FOR OUR DEPLOYER HERE /////////////////
@}

Check for an expedited bulk update message.  The Galactic Centre
simulator sends highly compacted messages containing the positions for
as many sources as will fit in a 1024 character {\tt llRegionSay()}
packet.  Each contains the numbers of sources which it is updating, in
a form that can be found by a single string search, and the $X$, $Y$,
and $Z$ region co-ordinates encoded as a six-character base64 strings
with {\tt fuis()} (\ref{fuis}).  This is much faster than sending
individual messages to each source [as region message sending is
constrained by message sending rate, not bandwidth, and {\tt
llRegionSayTo()} is no faster than {\tt llRegionSay()}].

@o scripts/galcent/source.lsl
@{
    if (llGetSubString(message, 1, 2) == ":{") {
        integer p = llSubStringIndex(message, m_upkey);
        if (p > 0) {
            vector npos = <
                siuf(llGetSubString(message, p + m_upkeyL, p + m_upkeyL + 5)),
                siuf(llGetSubString(message, p + m_upkeyL + 6, p + m_upkeyL + 11)),
                siuf(llGetSubString(message, p + m_upkeyL + 12, p + m_upkeyL + 17)) >;
            updateSourcePosition(npos);
            //  If this is the last source, report updates complete
            if (((p + m_upkeyL + 18) >= llStringLength(message)) &&
                (llGetSubString(message, 0, 0) == "V")) {
                llRegionSayTo(id, massChannel,
                    "[\"UPDATED\"," + (string) m_index + "]");
//llOwnerSay("Sent UPDATED from " + (string) m_index + " at " + (string) (p + m_upkeyL + 18));
            }
        }
        return;
    }
@}

This is not a bulk update message.  Decode it from JSON and process
according to its message type.

@o scripts/galcent/source.lsl
@{
    list msg = llJson2List(message);
    string ccmd = llList2String(msg, 0);

    if (id == deployer) {

        //  Message from Deployer

        //  ypres  --  Destroy mass

        @<Process planet ``ypres'' message to self-destruct@'@'@>

        //  COLLIDE  --  Handle collision with another mass
        //  KABOOM  --  Went out of range of deployer's control

        } else if ((ccmd == "COLLIDE") || (ccmd == "KABOOM")) {
            kaboom(m_colour);
@}

The {\tt LIST} command requests us to report our properties and
position to local chat, along with script memory usage.  This command
may be directed to either all sources or a specific source by index.

@o scripts/galcent/source.lsl
@{
    } else if (ccmd == "LIST") {
        integer bnreq = llList2Integer(msg, 1);

        if ((bnreq == 0) || (bnreq == m_index)) {
            integer mFree = llGetFreeMemory();
            integer mUsed = llGetUsedMemory();

            tawk("Source " + (string) m_index +
                 "  Name: " + m_name +
                 "  Mass: " + (string) m_mass +
                 "  Radius: " + (string) m_radius +
                 "  Position: " + (string) llGetPos() +
                 "\n    Script memory.  Free: " + (string) mFree +
                    "  Used: " + (string) mUsed + " (" +
                    (string) ((integer) llRound((mUsed * 100.0) / (mUsed + mFree))) + "%)"
                );
        }
@}

After being deployed, we send a {\tt SOURCED} message to the Deployer
to indicate we're ready.  It responds with an {\tt INIT} message which
informs us of our properties.  This is necessary since the process of
object creation can pass only a single integer and we need more
information than will fit.

@o scripts/galcent/source.lsl
@{
    } else if (ccmd == "INIT") {
        if (m_index == llList2Integer(msg, 1)) {
            m_name = llList2String(msg, 2);             // Name
            m_mass = llList2Float(msg, 5);              // Mass
            list xcol =  exColour(llList2String(msg, 6));   // Extended colour
            m_colour = llList2Vector(xcol, 0);          // Colour
            m_alpha = llList2Float(xcol, 1);            // Alpha
            m_glow = llList2Float(xcol, 2);             // Glow
            m_radius = llList2Float(msg, 7);            // Mean radius
            deployerPos = (vector) llList2String(msg, 8); // Deployer position

            /* IF TRACE */
            b1 = m_index == 1;
            /* END TRACE */

            //  Set properties of object
            llSetLinkPrimitiveParamsFast(LINK_THIS, [
                PRIM_COLOR, ALL_SIDES, m_colour, m_alpha,
                PRIM_GLOW, ALL_SIDES, m_glow,
                PRIM_DESC,  llList2Json(JSON_ARRAY, [ m_index, m_name, (string) m_mass ]),
                PRIM_SIZE, <m_radius, m_radius, m_radius> * s_radscale
            ]);
            llSetStatus(STATUS_PHANTOM | STATUS_DIE_AT_EDGE, TRUE);

            initState = 2;                  // INIT received, waiting for SETTINGS
        }
@}

The Deployer informs us of its settings with the {\tt SOURCE\_SET}
message.  This is always sent immediately after the {\tt INIT} message,
and subsequently whenever the settings change.  We're expected to be
able to update our settings on the fly.

@o scripts/galcent/source.lsl
@{

    //  SOURCE_SET  --  Set simulation parameters

    } else if (ccmd == "SOURCE_SET") {
        integer bn = llList2Integer(msg, 1);
        integer o_labels = s_labels;

        if ((bn == 0) || (bn == m_index)) {
            paths = llList2Integer(msg, 2);
            s_trace = llList2Integer(msg, 3);
            s_auscale = siuf(llList2String(msg, 4));
            s_radscale = siuf(llList2String(msg, 5));
            s_trails = llList2Integer(msg, 6);
            s_pwidth = siuf(llList2String(msg, 7));
            s_mindist = siuf(llList2String(msg, 8));
            s_labels = llList2Integer(msg, 9);
        }

        if (o_labels != s_labels) {
            o_labels = s_labels;
            @<Display floating text label@>
        }

        if (initState == 2) {
            initState = 3;                  // INIT and SETTINGS received
            startTime = llGetTime();        // Remember when we started
        }

        @<Trace path with particle system @{m_colour@}@>
@}

The {\tt VERSION} message requests this script to check its build
number against that of the Deployer and report any discrepancy.

@o scripts/galcent/source.lsl
@{
    @<Check build number in created objects@>
        @<Forward build number check to objects we've created@>
    }
@}

@o scripts/galcent/source.lsl
@{
                }
            }
        }
    }
@}

\chapter{Numerical Integration}

The Numerical Integration simulation is a first-principles simulation
of an $n$-body system moving under the laws of Newtonian gravitation.
The system is evolved in discrete time steps, computing the
gravitational force on each mass in the simulation, then integrating
to obtain its velocity and instantaneous position.  No assumptions
are made about trajectories: Keplerian orbits will be observed in
systems which manifest them (in particular, those with a large central
mass and much smaller orbiting masses), but far more complex behaviour
will be observed in many-body configurations.

\section{Numerical integrator}

This script resides in the Deployer, processes commands that define
numerical integration mass objects, runs and controls the simulation,
and communicates with the masses it creates.

The integrator operates in a somewhat unconventional system of units,
as defined below.  Length is measured in astronomical units (the mean
distance from the Earth to the Sun), mass in units of the mass of the
Sun, and time in years.  The following definitions derive the value of
the gravitational constant in this system of units from its handbook
definition in SI units.

@o scripts/numerical_integration.lsl
@{
    @<Explanatory header for LSL files@>

    @<Gravitational constant in astronomical units@>
@}

The {\tt mParams} list contains the definitions of the masses in the
simulation.  Items in the list are as follows.

\hspace{4em}\vbox{
\begin{description}
\dense
    \item[0]    Name
    \item[1]    Position (AU)
    \item[2]    Velocity (AU/year)
    \item[3]    Mass (solar masses)
    \item[4]    Colour (extended)
    \item[5]    Radius (mean radius, km)
    \item[6]    DeployerPos (region co-ordinates of deployer)
    \item[7]    MassKey (key of mass object)
\end{description}
}

@o scripts/numerical_integration.lsl
@{
    list mParams = [ ];         // Mass parameters
    integer mParamsE = 8;       // Mass parameters entry length
@}

Declare the global variables used in the script.

@o scripts/numerical_integration.lsl
@{
    key owner;                          // Owner UUID
    key whoDat = NULL_KEY;              // Avatar who sent command

    integer massChannel = @<massChannel@>;  // Channel for communicating with planets
    string ypres = "B?+:$$";            // It's pronounced "Wipers"

    //  Settings communicated by deployer
    float s_kaboom = 50;                // Self destruct if this far (AU) from deployer
    float s_auscale = 0.3;              // Astronomical unit scale
    float s_radscale = 0.0000025;       // Radius scale
    integer s_trails = FALSE;           // Show trails with temporary prims
    float s_pwidth = 0.01;              // Paths/trails width
    float s_mindist = 0.01;             // Minimum distance to update

    //  These settings are not sent to the masses
    float s_deltat = 0.01;              // Integration time step
    float s_zoffset = 1;                // Z offset to create masses
    integer s_legend = FALSE;           // Display legend above deployer
    float s_simRate = 1;                // Simulation rate (years/second)
    float s_stepRate = 0.1;             // Integration step rate (years/step)

    integer s_trace = FALSE;            // Trace mass behaviour
    integer paths = FALSE;              // Show particle trails from masss ?
    integer s_labels = FALSE;           // Show labels above masses ?

    integer stepNumber = 0;             // Step counter
    float stepsize = 0.1;       // Motion step size factor
//    float stepmin = 0.00001;    // Smallest step to use
//float stepmin = 0.01;    // Smallest step to use
float stepmin = 0.001; // INNER SYSTEM
    float simTime = 0;                  // Simulation time (years)
float ldeltat;
float collideDist = 0.0001;             // Criterion for declaring collision

    integer runmode = FALSE;            // Running the simulation ?
    float tickTime = 0.01;              // Simulation update time
    integer stepLimit = 0;              // Simulation step counter
    list simEpoch;                      // Simulation epoch (jd, jdf)
@}

The following link messages are used to communicate with other scripts
in the Deployer.

@o scripts/numerical_integration.lsl
@{
    @<Command processor messages@>
    @<Auxiliary services messages@>
@}

Import common functions we use.

@o scripts/numerical_integration.lsl
@{
    @<tawk: Send a message to the interacting user in chat@>

    @<fuis: Encode floating point number as base64 string@>
    @<fv: Encode vector as base64 string@>
    @<siuf: Decode base64-encoded floating point number@>

    @<fixArgs: Transform vector and rotation arguments to canonical form@>
    @<fixQuotes: Consolidate quoted arguments@>
    @<onOff: Parse an on/off parameter@>
    @<abbrP: Test argument, allowing abbreviation@>
@}

Define local functions.

@o scripts/numerical_integration.lsl
@{
    @<processIntCommand: Process numerical integration command@>
    @<setRunInt: Set run/stop mode@>
    @<updateIntLegend: Update legend@>
    @<sendIntSettings: Send settings to masses@>
    @<intTimeStep: Perform integration step@>
@}

Now we move on to the event handler.  On initialisation, we compute
the values for {\tt GRAV\_CONV} and {\tt GRAVCON}, described above,
and start listening for messages from masses we create.

@o scripts/numerical_integration.lsl
@{
    default {

        on_rez(integer start_param) {
            llResetScript();
        }

        state_entry() {
            whoDat = owner = llGetOwner();

            @<Initialise gravitational constant in astronomical units@>

            llListen(massChannel, "", NULL_KEY, "");
        }
@}

The {\tt link\_message} event handles messages from other scripts in the
Deployer, which passes on commands, clean-up requests, and settings.

@o scripts/numerical_integration.lsl
@{
        link_message(integer sender, integer num, string str, key id) {

            //  LM_CP_COMMAND (223): Process auxiliary command

            if (num == LM_CP_COMMAND) {
                processIntCommand(id, llJson2List(str));

            //  LM_CP_REMOVE (226): Remove simulation objects

            } else if (num == LM_CP_REMOVE) {
                mParams = [ ];              // Parameters of masses

            //  LM_AS_SETTINGS (542): Update settings from main script

            } else if (num == LM_AS_SETTINGS) {
                list msg = llJson2List(str);

                integer O_legend = s_legend;

                /*  We only decode settings in which we're interested
                    or wish to pass on to masses we've created.  */
                paths = llList2Integer(msg, 2);
                s_trace = llList2Integer(msg, 3);
                s_kaboom = siuf(llList2String(msg, 4));
                s_auscale = siuf(llList2String(msg, 5));
                s_radscale = siuf(llList2String(msg, 6));
                s_trails = llList2Integer(msg, 7);
                s_pwidth = siuf(llList2String(msg, 8));
                s_mindist = siuf(llList2String(msg, 9));
                s_deltat = siuf(llList2String(msg, 10));
                s_simRate = siuf(llList2String(msg, 15));
                s_stepRate = siuf(llList2String(msg, 16));
                s_zoffset = siuf(llList2String(msg, 17));
                s_legend = llList2Integer(msg, 18);
                simEpoch = llList2List(msg, 19, 20);
                s_labels = llList2Integer(msg, 21);

                sendIntSettings(NULL_KEY, 0);
                if (s_legend != O_legend) {
                    updateIntLegend();
                }
if (runmode) {
    llSetTimerEvent(s_simRate);
}
@}

The {\tt LM\_AS\_VERSION} message requests this script to check its
build number against that of the Deployer and report any discrepancy.

@o scripts/numerical_integration.lsl
@{
            @<Check build number in Deployer scripts@>
            }
        }
@}

When deployed and its script starts to run, each mass sends us a {\tt
NEWMASS} message with its mass number and key.  This allows us to send
it an {\tt INIT} message, encoded in JSON, containing the parameters
with which it should initialise itself.

@o scripts/numerical_integration.lsl
@{
        listen(integer channel, string name, key id, string message) {
//llOwnerSay(llGetScriptName() + " channel " + (string) channel + " id " + (string) id +  " message " + message);
            if (channel == massChannel) {
                list msg = llJson2List(message);
                string ccmd = llList2String(msg, 0);

                //  "It's so simple, so very simple, that only a child can do it!"
                if (ccmd == "NEWMASS") {
                    integer mass_number = llList2Integer(msg, 1);
                    integer mindex = (mass_number - 1) * mParamsE;
                    //  Save key of mass object in mParams
                    mParams = llListReplaceList(mParams, [ id ],
                        mindex + 7, mindex + 7);

                    llRegionSayTo(id, massChannel,
                        llList2Json(JSON_ARRAY, [ "MINIT", mass_number,
                        llList2String(mParams, mindex),                 // Name of body
                        fuis(llList2Float(mParams, mindex + 3)),        // Mass
                        llList2String(mParams, mindex + 4),             // Colour (extended)
                        fuis(llList2Float(mParams, mindex + 5)),        // Mean radius
                        fv(llList2Vector(mParams, mindex + 6))          // Deployer position
                    ]));

                    //  Send initial settings
                    sendIntSettings(id, mass_number);
                    //  Resume deployer script, if suspended
                    llMessageLinked(LINK_THIS, LM_CP_RESUME, "", whoDat);
                }
            }
        }
@}

While the simulation is running, the {\tt timer()} event calls
{\tt intTimeStep()} to evolve the model in time.

@o scripts/numerical_integration.lsl
@{
        timer() {
/*
            if (runmode) {
float tstart = llGetTime();
                float timeToStep = s_stepRate;
integer nsteps = 0;
                while (timeToStep > 0) {
                    /*  Numerical integration: perform one integration
                        step, with the possibility that the integrator
                        may take a smaller step than requested due to
                        large velocities and/or accelerations among
                        bodies.  *_/
                    float timeStepped = intTimeStep(timeToStep);
                    timeToStep -= timeStepped;
                    nsteps++;
                }
                float tcomp = llGetTime() - tstart;
                if (nsteps > 1) {
                    tawk("Update took " + (string) nsteps + " steps.");
                }
                if (stepLimit > 0) {
                    stepLimit--;
                    if (stepLimit <= 0) {
                        setRunInt(FALSE);
                        llMessageLinked(LINK_THIS, LM_CP_RESUME, "", whoDat);
tawk("Stopped.");
                    }
                }
                if (runmode) {
                    float wait = (s_stepRate / s_simRate) - tcomp;
                    if (wait <= 0) {
                        tawk("Time deficit: " + (string) wait);
                        wait = 0.001;
                    }
                    llSetTimerEvent(wait);
                }
            }
*/
            if (runmode) {
                intTimeStep(s_stepRate);
            }
        }
    }
@}

\subsection{Process commands}

Commands relating to Numerical Integration are forwarded to us by the
Deployer via the auxiliary command ({\tt LM\_CP\_COMMAND}) mechanism.

@d processIntCommand: Process numerical integration command
@{
    integer processIntCommand(key id, list args) {
        whoDat = id;            // Direct chat output to sender of command

        string message = llList2String(args, 0);
        string lmessage = fixArgs(llToLower(message));
        args = llParseString2List(lmessage, [ " " ], []);   // Command and arguments
        integer argn = llGetListLength(args);       // Number of arguments
        string command = llList2String(args, 0);    // The command
        string sparam = llList2String(args, 1);     // First argument, for convenience

        integer numint = mParams != [ ];
@| processIntCommand @}

The ``Mass'' command adds a mass to the simulation:

\begin{verse}
    Mass {\em name position velocity mass colour radius }
\end{verse}

\noindent
where {\em name} is the name of the body, which may be quoted if it
contains spaces, {\em position} is the initial position vector in
astronomical units, {\em velocity} is the initial velocity vector in
astronomical units per year, {\em mass} is the mass in units of solar
masses, {\em colour} is the display colour specified in the extended
form defined by {\tt exColour()} (\ref{exColour}), and {\em radius} is
the body's radius in kilometres.  The colour and radius affect only the
appearance of the body, not its behaviour in the simulation.

@d processIntCommand: Process numerical integration command
@{
        if (abbrP(command, "ma")) {
            if (runmode) {
                tawk("Cannot add a mass while running.");
                return FALSE;
            }

            //  Re-parse command to handle quotes and preserve letter case
            args = fixQuotes(llParseString2List(fixArgs(message), [ " " ], []));
            argn = llGetListLength(args);       // Number of arguments

            string name = llList2String(args, 1);
            vector where = (vector) llList2String(args, 2);

            vector eggPos = llGetPos();
            mParams += [ name, where, (vector) llList2String(args, 3),
                         (float) llList2String(args, 4),
                         /*  Note that we save the colour specification as a
                             string rather than a vector, which allows
                             passing our extended specification, including
                             alpha and glow, to the mass once it is created.  */
                         llList2String(args, 5),
                         (float) llList2String(args, 6),
                         eggPos + <0, 0, s_zoffset>,
                         NULL_KEY               // We don't yet know the key
                       ];

            where = (where * s_auscale) + eggPos + <0, 0, s_zoffset>;
            llSetRegionPos(where);
            if (s_trace) {
                tawk("Deploying " + name + " at " + (string) where);
            }
            llRezObject("Mass", where, ZERO_VECTOR,
//                ZERO_ROTATION,
llEuler2Rot(<PI_BY_TWO, 0, 0>),
                llGetListLength(mParams) / mParamsE);
            llSetRegionPos(eggPos);
@}

The ``Remove'' command deletes all mass objects from the simulation
and clears the local table of masses.

@d processIntCommand: Process numerical integration command
@{
        } else if (numint && abbrP(command, "re")) {
            setRunInt(FALSE);
            llRegionSay(massChannel, llList2Json(JSON_ARRAY, [ ypres ]));
            mParams = [ ];
            //  Reset step number and simulated time
            stepNumber = 0;
            simTime = 0;
            updateIntLegend();
@}

The ``Run on/off'' command starts or stops the simulation.  If given
with no argument, it toggles the stop/run state.

@d processIntCommand: Process numerical integration command
@{
        } else if (numint && abbrP(command, "ru")) {
            stepLimit = 0;
            if (argn < 2) {
                setRunInt(!runmode);
            } else {
                setRunInt(onOff(sparam));
            }
@}

The ``Status'' command shows script memory status in local chat.

@d processIntCommand: Process numerical integration command
@{
        } else if (abbrP(command, "sta")) {
            integer mFree = llGetFreeMemory();
            integer mUsed = llGetUsedMemory();
            tawk(llGetScriptName() + " status:" +
                 "\n  Script memory.  Free: " + (string) mFree +
                    "  Used: " + (string) mUsed + " (" +
                    (string) ((integer) llRound((mUsed * 100.0) / (mUsed + mFree))) + "%)"
            );
@}

The ``Step $n$'' command steps the simulation $n$ time steps.

@d processIntCommand: Process numerical integration command
@{
        } else if (numint && abbrP(command, "ste")) {
            integer n = (integer) sparam;

            if (n < 1) {
                n = 1;
            }
            stepLimit = n;
            setRunInt(TRUE);
        }

        return TRUE;
    }
@}

\subsection{Set run/stop mode}

Set or clear run mode.  When entering run mode, the timer is started at
the current tick rate.  When leaving it, the timer is cancelled.

@d setRunInt: Set run/stop mode
@{
    setRunInt(integer run) {
        if (run != runmode) {
            runmode = run;
            if (runmode) {
/*
                llSetTimerEvent(tickTime);
*/
llSetTimerEvent(s_simRate);
            } else {
                llSetTimerEvent(0);
            }
        }
    }
@| setRunInt @}

\subsection{Update legend}

When the simulation is running, update the floating text legend above
the Deployer to show the simulated time and integration step number.
We update the legend by sending an {\tt LM\_AS\_LEGEND} message to
the Minor Planets script which actually performs the update.

@d updateIntLegend: Update legend
@{
    updateIntLegend() {
        if (s_legend) {
            llMessageLinked(LINK_THIS, LM_AS_LEGEND,
                llList2Json(JSON_ARRAY, [
                    llGetListLength(mParams) > 0,       // 0  Numerical integration ?
                    simTime,                            // 1    Integration years
                    stepNumber,                         // 2    Step number
                                                        //    Planetary theory ?
                    FALSE,                              // 3    Tracking minor planet ?
                    "" ] +                              // 4    Name of minor planet, if any
                    simEpoch                            // 5,6  Simulation epoch
                ), whoDat);
        }
    }
@| updateIntLegend @}

\subsection{Send settings to masses}

Send settings to mass(es).  If {\tt mass} is nonzero, the message is
directed to that specific mass.  If zero, it is a broadcast to all
masses, and the {\tt id} argument is ignored.  These messages, with a
type of {\tt MASS\_SET}, should not be confused with the {\tt SETTINGS}
messages sent by the deployer.  They contain only parameters of
interest to the masses toiling in the fields.

@d sendIntSettings: Send settings to masses
@{
    sendIntSettings(key id, integer mass) {
        string msg = llList2Json(JSON_ARRAY, [ "MASS_SET", mass,
                            paths,
                            s_trace,
                            fuis(s_kaboom),
                            fuis(s_auscale),
                            fuis(s_radscale),
                            s_trails,
                            fuis(s_pwidth),
                            fuis(s_mindist),
                            s_labels
                      ]);
        if (mass == 0) {
            llRegionSay(massChannel, msg);
        } else {
            llRegionSayTo(id, massChannel, msg);
        }
    }
@| sendIntSettings @}

\subsection{Perform integration step}

This is the heart of the numerical integration process.  The
{\tt intTimeStep()} function performs one integration step of
{\tt deltat} years in length, updating the velocity and position
of each mass under the gravitational influence of all others.
The mass parameters are updated in place in the {\tt mParams}
list.  If proximity of masses or a high local velocity requires
reducing the integration step size, the actual step taken is
returned as the value of the function.

@d intTimeStep: Perform integration step
@{
    float intTimeStep(float deltat) {
        integer i;
        integer n = llGetListLength(mParams);
        list accelN = [ ];
        float mindist = 1e20;
        float maxvel = -1;
float softness = 0.1;
@| intTimeStep @}

The outer loop iterates over each mass in the simulation, computing
the vector sum of the gravitational force exerted upon it by all
of the other masses.  If the mass has been destroyed by a collision
or due to wandering beyond the {\tt kaboom} radius, its mass will
have been set to zero, indicating it should be ignored.

@d intTimeStep: Perform integration step
@{
        for (i = 0; i < n; i += mParamsE) {
            vector ai = ZERO_VECTOR;
            float mi = llList2Float(mParams, i + 3);    // Mass[i]
            if (mi > 0) {
                integer j;
                vector pi = llList2Vector(mParams, i + 1);  // Position[i]
                vector vi = llList2Vector(mParams, i + 2);  // Velocity[i]

@}

Now we iterate over the the other masses, computing the vector
sum of the gravitational force exerted by each:
\[
    \vec{F} = \sum_{i=1}^{n-1} \vec{D} \frac{G m_0 m_i}{r^2}
\]
where $G$ is the Newtonian gravitational constant, $m_0$ is the mass of
the object for which we're currently calculating, $m_i$ is the mass of
another object in the model, $\vec{D}$ is the unit vector from the
present to the other mass, and $r$ is the distance between them.  The
result, $\vec{F}$ is the force exerted by all other masses upon the
present mass.  Its acceleration is, then, by $F=ma$,
\[
    \vec{A} = \frac{\vec{F}}{m_0}
\].

Since we're computing the distances between each pair of masses, we
take the opportunity to check for collisions.  If two masses collide
(which we define as an approach to {\tt collideDist} or below), both
are sent {\tt COLLIDE} messages and zeroed out in the mass table.

The acceleration of each mass is saved in the {\tt accelN} list for
use in the next step.

@d intTimeStep: Perform integration step
@{
               //  Loop over peers of current mass...
                for (j = 0; j < n; j += mParamsE) {
                    if (i != j) {           // ...skipping itself, of course
                        float mj = llList2Float(mParams, j + 3);        // Mass[i]
                        if (mj > 0) {       // Ignore mass if destroyed by collision
                            vector pj = llList2Vector(mParams, j + 1);  // Position[i]
                            vector vj = llList2Vector(mParams, j + 2);  // Velocity[i]
                            float r = llVecDist(pi, pj);        // Distance to mass
                            if (r <= collideDist) {
                                /*  When masses collide!  Send collision
                                    messages to both masses.  */
                                llRegionSayTo(llList2Key(mParams, i + 7), massChannel,
                                    llList2Json(JSON_ARRAY, [ "COLLIDE",
                                        i / mParamsE, j / mParamsE ]));
                                llRegionSayTo(llList2Key(mParams, j + 7), massChannel,
                                    llList2Json(JSON_ARRAY, [ "COLLIDE",
                                        j / mParamsE, i / mParamsE ]));
                                //  Zero out velocities and masses of both dear departed bodies
                                mParams = llListReplaceList(mParams,
                                    [ ZERO_VECTOR, 0.0 ], i + 2, i + 3);
                                mParams = llListReplaceList(mParams,
                                    [ ZERO_VECTOR, 0.0 ], j + 2, j + 3);
                                //  Bail out processing this mass
                                jump collided;
                            }
                            vector rv = llVecNorm(pj - pi);     // Direction of mass
                            //  F = G (m1 m2) / ((r^2) + (softness ^ 2))
                            float force = (GRAVCON * (mi * mj)) /
//(r * r);
((r * r) + (softness * softness));
                            //  F = ma, hence a = F/m
                            float accel = force / mi;
                            ai += rv * accel;                   // Gravitational force vector
                            if (r < mindist) {
                                mindist = r;                    // Minimum distance between masses
                            }
                        }
                    }
                    @@collided;
                }
            }

            /*  At this point, ai contains the net acceleration
                produced by all other bodies upon this one.  We
                save this in an auxiliary accelN array for
                subsequent use in updating velocities.  */

            accelN += ai;
        }
@}

From the list of accelerations, we can now update the velocities of the
individual bodies, which is simply
\[
    \vec{V}_{i+1} = \vec{V}_i + \vec{A} t
\]
where $\vec{V}$ is the velocity of the body, $\vec{A}$ is its
gravitational acceleration, computed above, and $t$ is the time step of
the integration.

But first, we need to find the maximum velocity after applying the
acceleration.  This will allow us to adapt the integration time step
size ({\tt deltat}) to avoid loss of precision in high-velocity
encounters.  The velocity and acceleration of a mass destroyed in a
collision will both be zero, and will not influence this computation.

@d intTimeStep: Perform integration step
@{
        integer a;
        for (i = a = 0; i < n; i += mParamsE, a++) {
            float pvel = llVecMag(llList2Vector(mParams, i + 2) +
                                  llList2Vector(accelN, a));
            if (pvel > maxvel) {
                maxvel = pvel;
            }
        }
@}

Now that we know the maximum velocity of any body and may have adjusted
{\tt deltat} as a result, we can actually update the velocities for
that time step.  Since the velocity and acceleration of a mass
destroyed in a collision are zero, this will do nothing for them.

@d intTimeStep: Perform integration step
@{
/*
        deltat = stepsize * (mindist / maxvel);
        if (deltat < stepmin) {
            deltat = stepmin;
        }
*/
//  NEED TO CONSTRAIN BASED UPON MAXVEL
/*
        if (deltat < (stepsize * (mindist / maxvel))) {
            deltat = stepsize * (mindist / maxvel);
            if (deltat < stepmin) {
                deltat = stepmin;
            }
        }

if (s_trace) {
    tawk("Deltat = " + (string) deltat + "  previous " + (string) ldeltat +
        "  stepmin " + (string) stepmin);
ldeltat = deltat;
}
*/
        for (i = a = 0; i < n; i += mParamsE, a++) {
            vector vi = llList2Vector(mParams, i + 2);  // Velocity[i]
            vi += llList2Vector(accelN, a) * deltat;
            mParams = llListReplaceList(mParams, [ vi ], i + 2, i + 2);
        }
@}

And finally, with the velocities all updated, use them and {\tt deltat}
to update the positions.  If the mass has been destroyed in a
collision, we skip sending its update upon seeing that its mass has
been zeroed out.  The position update is just the derivative of the
velocity update:

\[
    \vec{P}_{i+1} = \vec{P}_i + \vec{V} t
\]


@d intTimeStep: Perform integration step
@{
        stepNumber++;
        simTime += deltat;
        updateIntLegend();
        vector depPos = llGetPos() + <0, 0, s_zoffset>;
        for (i = a = 0; i < n; i += mParamsE, a++) {
            if (llList2Float(mParams, i + 3) > 0) {
                vector where = llList2Vector(mParams, i + 1) +
                               (llList2Vector(mParams, i + 2) * deltat);
                mParams = llListReplaceList(mParams,
                    [ where ], i + 1, i + 1);

                //  Send update to the mass object

                vector rwhere  = (where * s_auscale) + depPos;
                llRegionSayTo(llList2Key(mParams, i + 7), massChannel,
                    llList2Json(JSON_ARRAY, [ "UMASS", a + 1,
                        fv(rwhere)
                ]));
            }
        }

        if (s_trace) {
            tawk("Simulation time: " + (string) simTime + " deltaT " + (string) deltat);
            for (i = 0; i < n; i += mParamsE) {
                tawk("  " + llList2String(mParams, i) + "  "  +
                    (string) llList2Vector(mParams, i + 1) + "  " +
                    (string) llList2Vector(mParams, i + 2));
            }
        }
        return deltat;                  // Return time actually stepped
    }
@}

\section{Mass object}

This script runs within each mass of a Numerical Integration
simulation.  The masses have no autonomy: they simply respond
to position updates computed and sent by the Numerical Integration
script in the Deployer.

Begin by declaring our global variables.

@o scripts/numint/mass.lsl
@{
    @<Explanatory header for LSL files@>

    key owner;                          // UUID of owner
    key deployer;                       // ID of deployer who hatched us
    integer initState = 0;              // Initialisation state

    //  Properties of this mass
    integer s_trace = FALSE;            // Trace operations
    integer m_index;                    // Our mass index
    string m_name;                      // Name
    integer s_labels;                   // Show floating text label ?
    float m_mass;                       // Mass
    vector m_colour;                    // Colour
    float m_alpha;                      // Alpha (0 transparent, 1 solid)
    float m_glow;                       // Glow (0 none, 1 intense)
    float m_radius;                     // Mean radius

    //  Settings communicated by deployer
    float s_kaboom = 50;                // Self destruct if this far (AU) from deployer
    float s_auscale = 0.2;              // Astronomical unit scale
    float s_radscale = 0.0000025;       // Radius scale
    integer s_trails = TRUE;            // Plot orbital trails ?
    float s_pwidth = 0.01;              // Paths/trails width
    float s_mindist = 0.1;              // Minimum distance to move

    integer massChannel = @<massChannel@>;  // Channel for communicating with deployer
    string ypres = "B?+:$$";            // It's pronounced "Wipers"
    string Collision = "Balloon Pop";   // Explosion sound clip

    vector deployerPos;                 // Deployer position (centre of cage)

    float startTime;                    // Time we were hatched

    key whoDat;                         // User with whom we're communicating
    integer paths;                      // Draw particle trail behind masses ?
    /* IF TRACE */
    integer b1;                         // Used to trace only mass 1
    /* END TRACE */
@}

Import utility functions we employ.

@o scripts/numint/mass.lsl
@{
    @<siuf: Decode base64-encoded floating point number@>
    @<sv: Decode base64-encoded vector@>

    @<kaboom: Destroy object@>

    @<flRezRegion: Rez object anywhere in region@>
    @<flPlotLine: Plot line in space@>

    @<tawk: Send a message to the interacting user in chat@>
    @<exColour: Parse extended colour specification@>
@}

The event handler begins by initialising the mass when it is created
by the deployer.  When the script receives control, it begins to
listen for messages from the deployer and sends a {\tt NEWMASS}
message to the deployer to inform it we're ready to receive our
initialisation parameters.

@o scripts/numint/mass.lsl
@{
    default {

        state_entry() {
            whoDat = owner = llGetOwner();
        }

        on_rez(integer start_param) {
            initState = 0;

            //  If start_param is zero, this is a simple manual rez
            if (start_param > 0) {
                m_index = start_param;

                deployer = llList2Key(llGetObjectDetails(llGetKey(),
                                [ OBJECT_REZZER_KEY ]), 0);

                //  Set sit target

                llSitTarget(<-0.8, 0, 0>, llAxisAngle2Rot(<0, 1, 0>, -PI_BY_TWO));
                llSetCameraEyeOffset(<-1.2, 0, -1.2>);
                llSetCameraAtOffset(<-1, 0, 1>);

                //  Listen for messages from our deployer
                llListen(massChannel, "", NULL_KEY, "");

                //  Inform the deployer that we are now listening
                llRegionSayTo(deployer, massChannel,
                    llList2Json(JSON_ARRAY, [ "NEWMASS", m_index ]));

                initState = 1;          // Waiting for SETTINGS and INIT
            }
        }
@}

The {\tt listen()} event receives messages from the deployer and
performs the requested actions.

@o scripts/numint/mass.lsl
@{
        listen(integer channel, string name, key id, string message) {
//llOwnerSay("Mass channel " + (string) channel + " id " + (string) id +  " message " + message);

            if (channel == massChannel) {
                list msg = llJson2List(message);
                string ccmd = llList2String(msg, 0);

                if (id == deployer) {
                    @<Process planet ``ypres'' message to self-destruct@{@}@>

                    //  COLLIDE  --  Handle collision with another mass

                    } else if (ccmd == "COLLIDE") {
                        kaboom(m_colour);
@}

The {\tt LIST} message shows information about the mass in local chat
as well as script memory usage.  It may either be directed to an
individual mass by index number or to all masses by an index of zero.

@o scripts/numint/mass.lsl
@{
                    } else if (ccmd == "LIST") {
                        integer bnreq = llList2Integer(msg, 1);

                        if ((bnreq == 0) || (bnreq == m_index)) {
                            integer mFree = llGetFreeMemory();
                            integer mUsed = llGetUsedMemory();

                            tawk("Mass " + (string) m_index +
                                 "  Name: " + m_name +
                                 "  Mass: " + (string) m_mass +
                                 "  Radius: " + (string) m_radius +
                                 "  Position: " + (string) llGetPos() +
                                 "\n    Script memory.  Free: " + (string) mFree +
                                    "  Used: " + (string) mUsed + " (" +
                                    (string) ((integer) llRound((mUsed * 100.0) /
                                    (mUsed + mFree))) + "%)"
                                );
                        }
@}

When a mass is created, it sends a {\tt NEWMASS} message to the
Deployer to inform it of its creation.  The deployer responds with a
{\tt MINIT} message which provides the mass the parameters it needs
to complete initialisation, including name, mass, colour, display
radius, and the position of the Deployer.

@o scripts/numint/mass.lsl
@{
                    } else if (ccmd == "MINIT") {
                        if (m_index == llList2Integer(msg, 1)) {
                            m_name = llList2String(msg, 2);             // Name
                            m_mass = siuf(llList2String(msg, 3));       // Mass
                            list xcol =  exColour(llList2String(msg, 4));   // Extended colour
                                m_colour = llList2Vector(xcol, 0);              // Colour
                                m_alpha = llList2Float(xcol, 1);                // Alpha
                                m_glow = llList2Float(xcol, 2);                 // Glow
                            m_radius = siuf(llList2String(msg, 5));     // Mean radius
                            deployerPos = sv(llList2String(msg, 6));    // Deployer position

                            /* IF TRACE */
                            b1 = m_index == 1;
                            /* END TRACE */

                            //  Set properties of object
                            llSetLinkPrimitiveParamsFast(LINK_THIS, [
                                PRIM_COLOR, ALL_SIDES, m_colour, m_alpha,
                                PRIM_GLOW, ALL_SIDES, m_glow,
                                PRIM_DESC,  llList2Json(JSON_ARRAY,
                                    [ m_index, m_name, (string) m_mass ]),
                                PRIM_SIZE, <m_radius, m_radius, m_radius> * s_radscale
                            ]);
                            llSetStatus(STATUS_PHANTOM | STATUS_DIE_AT_EDGE, TRUE);

                            initState = 2;      // INIT received, waiting for SETTINGS
                        }
@}

The simulation sends its settings to masses via the {\tt MASS\_SET}
message, which is sent immediately after the {\tt MINIT} message when
the mass is created and subsequently whenever the settings change.  Do
not confuse this message with the {\tt LM\_AS\_SETTINGS} link message
which is sent from the Deployer to other scripts within itself.

@o scripts/numint/mass.lsl
@{
                    } else if (ccmd == "MASS_SET") {
                        integer bn = llList2Integer(msg, 1);
                        integer o_labels = s_labels;

                        if ((bn == 0) || (bn == m_index)) {
                            paths = llList2Integer(msg, 2);
                            s_trace = llList2Integer(msg, 3);
                            s_kaboom = siuf(llList2String(msg, 4));
                            s_auscale = siuf(llList2String(msg, 5));
                            s_radscale = siuf(llList2String(msg, 6));
                            s_trails = llList2Integer(msg, 7);
                            s_pwidth = siuf(llList2String(msg, 8));
                            s_mindist = siuf(llList2String(msg, 9));
                            s_labels = llList2Integer(msg, 10);
                        }

                        if (o_labels != s_labels) {
                            o_labels = s_labels;
                            @<Display floating text label@>
                        }

                        if (initState == 2) {
                            initState = 3;                  // INIT and SETTINGS received, now flying
                            startTime = llGetTime();        // Remember when we started
                        }

                        //  Set or clear particle trail depending upon paths
                        @<Trace path with particle system @{m_colour@}@>
@}

At each step in the simulation, a {\tt UMASS} message is sent to each
mass, providing its new position.  The mass checks whether it has moved
beyond the ``kaboom'' distance from the Deployer and, if so,
self-destructs.  Otherwise, if the new position is greater than or
equal to the ``mindist'' setting, moves to the new position and, if
enabled, draws the trail from its previous position to the new.

@o scripts/numint/mass.lsl
@{
                    } else if (ccmd == "UMASS") {
                        vector p = llGetPos();
                        vector npos = sv(llList2String(msg, 2));
                        float dist = llVecDist(p, npos);
                        if (s_trace) {
                            tawk(m_name + ": Update pos from " + (string) p +
                                 " to " + (string) npos + " dist " + (string) dist);
                        }
                        if ((s_kaboom > 0) &&
                            ((llVecDist(npos, deployerPos) / s_auscale) > s_kaboom)) {
                            kaboom(m_colour);
                            return;
                        }
                        if (dist >= s_mindist) {
                            llSetLinkPrimitiveParamsFast(LINK_THIS,
                                [ PRIM_POSITION, npos ]);
                            if (paths) {
                                llSetLinkPrimitiveParamsFast(LINK_THIS,
                                    [ PRIM_ROTATION, llRotBetween(<0, 0, 1>, (npos - p)) ]);
                            }
                            if (s_trails) {
                                flPlotLine(p, npos, m_colour, s_pwidth);
                            }
                        }
@}

The {\tt VERSION} message requests this script to check its build
number against that of the Deployer and report any discrepancy.

@o scripts/numint/mass.lsl
@{
                        @<Check build number in created objects@>
                            @<Forward build number check to objects we've created@>
                    }
                }
            }
        }
     }
@}

\chapter{Meta and Miscellaneous}

This is a collection of items which are about building the programs and
tools used in the process.

\section{Explanatory header for LSL files}

This header comment appears at the top of all LSL files generated
from this web.  It explains where to go for the master source code.

@d Explanatory header for LSL files
@{
    /*  NOTE: This program was automatically generated by the Nuweb
        literate programming tool.  It is not intended to be modified
        directly.  If you wish to modify the code or use it in another
        project, you should start with the master, which is kept in the
        file orbits.w in the public GitHub repository:
            https://github.com/Fourmilab/orbits.git
        and is documented in the file orbits.pdf in the root directory
        of that repository.

        Build @<Build number@>  @<Build date and time@>  */
@}

\section{Explanatory header for shell-like files}

@d Explanatory header for shell-like files
@{
    #   NOTE: This program was automatically generated by the Nuweb
    #   literate programming tool.  It is not intended to be modified
    #   directly.  If you wish to modify the code or use it in another
    #   project, you should start with the master, which is kept in the
    #   file orbits.w in the public GitHub repository:
    #       https://github.com/Fourmilab/orbits.git
    #   and is documented in the file orbits.pdf in the root directory
    #   of that repository.
@}

\section{Explanatory header for Perl files}

This header comment appears at the top of all Perl files generated
from this web.  It explains where to go for the master source code.

@d Explanatory header for Perl files
@{#! /usr/bin/perl

@<Explanatory header for shell-like files@>
    #
    #   Build @<Build number@>  @<Build date and time@>
@}

\section{Makefile}

The {\tt Makefile} is used to control all build and maintenance
operations.  Due to a regrettable episode in the ancient history of
Unix, the distinction between hardware tab characters and other white
space is significant.  Nuweb always uses space characters, which would
break {\tt make}, so the {\tt Makefile} incorporates a little trick:
after performing a {\tt make~build} from the web, if this file has been
expanded to {\tt Makefile.mkf} and it is newer than the current {\tt
Makefile}, it is processed with {\tt sed} and {\tt unexpand} to restore
the tabs as required.

@o Makefile.mkf
@{
@<Explanatory header for shell-like files@>

PROJECT = orbits

#       Path names for build utilities

NUWEB = nuweb
LATEX = xelatex
PDFVIEW = evince
LSLINT = lslint
GNUFIND = find

duh:
        @@echo "What'll it be, mate?  build view peek lint stats clean"
@}

\subsection{Build program files}

Rebuild all changed files from the master Nuweb {\tt .w} files.
Here is where we perform the dirty trick to convert spaces to tabs
to a newly-generated {\tt Makefile} will work.

@o Makefile.mkf
@{
build:
        perl tools/build/update_build.pl
        $(NUWEB) -t $(PROJECT).w
        @@if [ \( ! -f Makefile \) -o \( Makefile.mkf -nt Makefile \) ] ; then \
                echo Makefile.mkf is newer than Makefile ; \
                sed "s/ \*$$//" Makefile.mkf | unexpand >Makefile ; \
        fi
@}

\subsection{Generate and view PDF document}

The {\tt view} target re-generates the master document containing
all documentation and code, while {\tt peek} simply view the
most-recently-generated document (without check if it is current).

@o Makefile.mkf
@{
view:
        $(NUWEB) -o -r $(PROJECT).w
        $(LATEX) $(PROJECT).tex
        # We have to re-run Nuweb to incorporate the updated TOC
        $(NUWEB) -o -r $(PROJECT).w
        $(LATEX) $(PROJECT).tex
        $(PDFVIEW) $(PROJECT).pdf

peek:
        $(PDFVIEW) $(PROJECT).pdf
@}

\subsection{Syntax check all LSL scripts}

All Linden Scripting Language programs in the directory tree are
checked with the {\tt lslint} utility.  This requires the GNU
{\tt find} utility, which supports the ``{\tt -quit}''
action that allows us to stop after the first error it detects.

@o Makefile.mkf
@{
lint:
        @@# Uses GNU find extension to quit on first lslint error
        $(GNUFIND) scripts -type f -name \*.lsl -print \
                \( -exec $(LSLINT) {} \; -o -quit \)
@}

\subsection{Show statistics of the project}

``How's it coming along?''  Compute and print statistics about the
project at the present time.

@o Makefile.mkf
@{
stats:
        @@echo Build `grep "Build number" build.w | sed 's/[^0-9]//g'` \
                `grep "Build date and time " build.w | \
                sed 's/[^:0-9 \-]//g' | sed 's/^ *//'`
        @@echo Web: `wc -l *.w`
        @@echo Scripts: `find scripts -type f -name \*.lsl -print | wc -l`
        @@echo Lines: `find scripts -type f -name \*.lsl -exec cat {} \; | wc -l`
        @@if [ -f $(PROJECT).log ] ; then \
                echo -n "Pages: " ; \
                tail -5 $(PROJECT).log | grep pages | sed 's/[^0-9]//g' ; \
        fi
@}

\subsection{Clean up intermediate files from earlier builds}

Delete intermediate files from the build process, or all files
generated from the web.

@o Makefile.mkf
@{
clean:
        rm -f nw[0-9]*[0-9] rm *.aux *.log *.out *.pdf *.tex *.toc

squeaky:
        #make clean
        #rm -f Makefile.mkf
        #find scripts -type f -name \*.lsl -exec rm -f {} \;
        #  Need to clean tools directory after all integrated here
@}

\section{Build number and date maintenance}

This Perl program is run by the {\tt Makefile} every time a ``{\tt make
build}'' is run.  It increments the build number and places the current
UTC date and time in the {\tt build.w} file which is included here to
implement build number consistency checking.

@o tools/build/update_build.pl
@{@<Explanatory header for Perl files@>

    use strict;
    use warnings;

    use POSIX qw(strftime);

    my $bfile = "build.w";              # Build file name

    #   Read current file into string

    open(FI, "<$bfile") || die("Cannot open $bfile");
    my $btext = do {
        local $/ = undef;
        <FI>;
    };
    close(FI);

    #   Update build number and date

    my $date = strftime("%F %H:%M", gmtime(time()));

    $btext =~ m/\@@d\s+Build\s+number\s+\@@\{(\d+)\@@/s;
    my $buildno = $1;
    $buildno++;

    #   Substitute build number and date into file

    $btext =~ s/(\@@d\s+Build\s+number\s+\@@\{)\d+/$1$buildno/s ||
        die("Cannot substitute build number");
    $btext =~ s/(\@@d Build date and time \@@\{)[^\@@]+/$1$date/s ||
        die("Cannot substitute date");

    #   Write out the updated file

    open(FO, ">$bfile") || die("Cannot open $bfile for writing");
    print(FO $btext);
    close(FO);

    print("Build $buildno $date\n");
@}

\clearpage
\stepcounter{chapter}
\vbox{
\chapter*{Indices} \label{indices}
\addcontentsline{toc}{chapter}{Indices}

Three indices are created automatically: an index of file
names, an index of macro names, and an index of user-specified
identifiers. An index entry includes the name of the entry, where it
was defined, and where it was referenced.
}

\section{Files}

@f

\section{Macros}

@m

\section{Identifiers}

Sections which define identifiers are underlined.

@u

\font\df=cmbx12
\def\date#1{{\medskip\noindent\df #1\medskip}}
\parskip=1ex
\parindent=0pt

\begin{appendices}

\chapter{Periodic terms for Solar System planet ephemeris calculations}

For all planets of the solar system, with the exception of Pluto, we
compute their positions with the VSOP87 analytic planetary theory, in
some cases truncated due to the limits of LSL script memory.  Each
calculation requires the evaluation of lengthy lists of periodic terms,
which are listed below for each planet.

\section{Mercury}

@D Mercury periodic terms
@{
@i ephemeris/mercury.w
@}

\clearpage
\section{Venus}

@D Venus periodic terms
@{
@i ephemeris/venus.w
@}

\clearpage
\section{Earth}

@D Earth periodic terms
@{
@i ephemeris/earth.w
@}

\clearpage
\section{Mars}

@D Mars periodic terms
@{
@i ephemeris/mars.w
@}

\clearpage
\section{Jupiter}

@D Jupiter periodic terms
@{
@i ephemeris/jupiter.w
@}

\clearpage
\section{Saturn}

@D Saturn periodic terms
@{
@i ephemeris/saturn.w
@}

\clearpage
\section{Uranus}

@D Uranus periodic terms
@{
@i ephemeris/uranus.w
@}

\clearpage
\section{Neptune}

@D Neptune periodic terms
@{
@i ephemeris/neptune.w
@}

\chapter{Development Log} \label{log}

@i log.w
\end{appendices}

\end{document}
