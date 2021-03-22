
\date{2021 January 5}

Took another deep dive down a rabbit hole thanks to LSL's shoddy
implementation of its (inadequate) single precision floating point.
If single precision itself weren't an insult to anybody trying to
do physical modeling, the conversion of floating point numbers to
strings is a dagger in the back.  Suppose you have a floating point
number like, say, 1.67e-7, which is well within the dynamic range
and precision of a single precision IEEE float.  Now you cast the
value to a string and print it, for example:
\begin{verbatim}
    float a = 1.67e-7;
    llOwnerSay((string) a);
\end{verbatim}
What do you get?  Well, hold on to your hat, it's:
\begin{verbatim}
    0.000000
\end{verbatim}
That's right, it knows nothing of scientific notation, and shifts
every significant digit off the end of the six decimal places it
edits.  Now, foolishliy, try to pass that number from one script to
another by encoding it as JSON with, say:
\begin{verbatim}
    llOwnerSay(llList2Json(JSON_ARRAY, [ a ]));
\end{verbatim}
And the answer is...
\begin{verbatim}
     [0.000000]
\end{verbatim}
Yes, it uses the same idiot float to string conversion and loses the
entire mantissa.  I didn't just pull this number out of the air, by
the way.  It happens to be the mass of the planet Mercury expressed in
units of solar mass.  So what this means is that if you ever allow
LSL to express a float as a string, it makes Mercury as massless as a
photon.

The only way to work around this is to integrate something like the
LSL library {\tt float2Sci()} function, which is huge, complicated, and
excruciatingly slow, and explicitly call it wherever you need to pass
a float as a string.  This is just hideous, but shoddy happens, and
who're you gonna call?

\date{2021 January 6}

Well, the LSL Wiki recommends {\tt Float2Hex}, which encodes floats as
a C99 hexadecimal float with no loss of precision and is much faster
than {\tt float2Sci()}.  Well, that may be, and it does indeed work,
but it is still many times (around a factor 5 to 7) slower than the
native (float) conversion.  So, if performance matters, as when passing
values between scripts with JSON or CSV messages, the only practical
approach is to scale your values so they don't lose precision, then
scale them back on the receiving end.

\date{2021 January 8}

After a number of tests, it became evident that a model in which each
particle autonomously evaluated the forces on it and moved accordingly
simply wasn't going to work.

\date{2021 January 9}

Successive optimisation of performance of simulation.  Each test run is
64 steps.

\begin{verbatim}
                        Computation         Model update
Initial state             2.1787               14.8694
Float2Hex to (float)      0.7557               14.9567    In UPDATE message
Mindist 0.1               0.7315                8.2216    32 moves taken
llSetLinkPrimParamsFast   0.7994                1.4001    Eliminates 0.2 sec delay
Separate table of velocities from mParams
Send single message to update all masses
Send message as CSV, not JSON
\end{verbatim}

Added a ``Set kaboom n'' facility which causes masses to self-destruct if
an update places them greater than $n$ AU from the deployer.  This cleans
up runaway masses without counting on their dying due to going off
world or onto a parcel where they aren't permitted.

Added a Run on/off command, which calls timeStep off the timer, with a
time step tickTime which is currently fixed at 0.01 second.  Since this
is run off the timer, it is interruptable.

Modified the Step command to use the Run timer mechanism, limited by
a variable stepLimit which it sets to the specified count.  This can be
stopped by Run off.  If you set stepLimit to zero, the previous compute
bound code is used (temporarily) to allow running benchmarks which can
be compared to those above, when we get back to tuning again.

\date{2021 January 10}

Made a galaxy disc texture for the deployer.  The image is of NGC3982,
from:
\begin{verse}
    \url{https://esahubble.org/images/opo1036a/}\\
    \url{https://esahubble.org/copyright/}
\end{verse}
This as been processed into two texture images in textures/
\begin{verbatim}
    NGC3982.png         512x512 single sided
    NGC3982x2.png       1024x512 double sided
\end{verbatim}
In the latter image, the right side is flipped so when it's applied to
a sphere as follows, it covers both sides and aligns properly.
\begin{verbatim}
    Size        <1, 1, 0.05>
    Rotation    <0, 0, 0>
    Texture
        Scale   <1, 1, x>
        Repeats 1
        Rotation 90 deg.
    Offset      <0, 0, x>
\end{verbatim}

Added a ``Hide run'' command and support to hide the deployer while the
simulation is running.  You can, as before, hide or show the deployer
permanently with ``Hide on/off''.  A new {\tt setRun()} function handles all
state changes of ``runmode''.

\date{2021 January 11}

Modified {\tt fixArgs()} to remove the \{\ldots \} rotation syntax
which only applies to Euler angle rotations in the Calculator.

Modified the Mass command and REZ message handler to store and
pass the Mass colour specification as a string, allowing our
extended colour specifications to be passed to the mass in the INIT
message.  An extended colour specification is:
\begin{verbatim}
    <r, g, b [, alpha [ , glow ] ]>
\end{verbatim}
Note that {\tt fixArgs} handles eliding any spaces within the
specification, even though it may not look like a vector
or rotation.

Added code to the INIT message handler in Mass to handle the extended
colour specification.  The colour specification from the Mass statement
is parsed by the {\tt exColour()} function, which returns a list
containing the colour, alpha, and glow specifications, automatically
specifying omitted optional parameters.  If an invalid colour
specification is given, a list representing solid white with no glow is
returned.

Had another go at drawing (semi-)reasonable paths behind objects with
a particle system.  This time, I have the masses rotate themselves in
the direction of travel so their Z axis (the \verb+RIBBON_MASK+ particle
emission direction) is oriented along the vector from their old to new
position).  This works pretty well, but note that it uses the dreaded
{\tt llRotBetween()} and may flake out, requiring replacement by the more
reliable library function we've used elsewhere.  Also, it's not
optimised: there's no need to fiddle with rotating the masses unless
we're drawing paths, but we presently do it all the time.

Added the ability to trace paths by laying down temporary prims to form
lines along the orbits.  This is done in the masses with a new {\tt
flPlotLine()} function, which is a (reasonably) general line drawing
mechanism that works in region co-ordinates and plots with skinny
cylinders.  This is controlled by ``Set paths lines'' and can be turned
off with ``Set paths off''.  Particle paths continue to be available
via ``Set paths on''.  The prim path mechanism basically works, but
needs instrumentation and tuning to determine how much it costs us and
what we can do to reduce the simulation overhead.

Added computation of simulated time and display in a floating text
legend, along with the step number, above the deployer.   The legend
is controlled with ``Set legend on/off'' and is, by default, off.

\date{2021 January 12}

Proposal for simulated time: set the simulation rate with:
\begin{verbatim}
    Set simrate n
\end{verbatim}
where $n$ is the number of simulated years per second.  The simulator
will strive to approximate that rate.
\begin{verbatim}
    Set step n
\end{verbatim}
Set the number of simulated years per integration step.  This is the
default as long as accelerations do not force us to use smaller steps.
In the normal case (low accelerations), the simulation process is to
perform R/S steps per second, to which each is allotted S/R seconds
to complete, with a timed wait at the end of each step so the rate
simulation rate is achieved.

If high accelerations force us to a smaller step size, then we adjust
the number of steps accordingly, and reduce the wait between steps.
If the required number of steps take longer than we can compute at the
requested rate, we are in a time deficit situation and should report
this to the user.

This is complicated by the fact that it's possible we may be able to
compute steps faster than the masses can update themselves.  We need to
be able to detect this and have the masses discard updates to avoid
overflowing their inbound event queues.  Perhaps we should time stamp
the updates so the masses can detect getting behind.  Unfortunately,
we'll have to use Unix time with a resolution of only one second, since
{\tt llGetTime()} is local to each script.  An alternative is {\tt
llGetTIimeOfDay()}, but that requires handling wrapping around
midnight.  {\tt llGetTimestamp()} is right out, as it requires string
bashing which is way too costly.

\date{2021 January 12}

Added code to allow a suffix to be specified after the interval in
the Set simrate and Set steprate commands.  If no suffix is given,
the specification is interpreted as years.  Valid suffixes are:
\begin{verbatim}
        h       Hour
        d       Day
        w       Week (1/52 year)
        m       Month (1/12 year)
        y       Year (default)
        D       Decade
        C       Century
\end{verbatim}

\date{2021 January 13}

Created a new platform, ``Uraniborg'' (named after Tycho's
observatory), with a texture called ``Starfield'' which was generated
by ``Terranova Planet Maker''.

Created a utility to compile the Jet Propulsion Laboratory (JPL)
DE118 (digital ephemeris) initial state vector for the solar system
as of JD 2440400.5 (1969-06-28 00:00 UTC) into Mass commands to
define the bodies.  This program is:
\begin{verbatim}
    tools/solar_state_vector.pl
\end{verbatim}
and reads an unmodified file, {\tt tools/aconst.h} containing the
positions and velocities of the Sun, planets (including Pluto), and the
Earth's Moon.  The other properties of the bodies (name, mass, colour,
and radius) are taken from a table included in the program.  The output
is a list of Mass declarations in the format which can be read directly
by the Gravitation deployer.

The DE118 state vector is expressed with position units of astronomical
units (AU) and velocity of AU per day.  We transform velocity into our
units of AU per year.  Further, DE118 uses a co-ordinate system in
which the Z axis points to the Earth's north celestial pole, the X axis
points toward the vernal equinox, and the Y axis at Right Ascension 6
hours. The \verb+solar_state_vector.pl+ rotates the position and velocity
vector around the X axis to align the Z axis with the normal to the
ecliptic plane, transforming the co-ordinates to our heliocentric
co-ordinates.

Added an Epoch command which allows specifying the start epoch of a
model loaded into the simulator.  This doesn't presently do anything,
but it accepts the Epoch declaration generated from DE118 database.

\date{2021 January 14}

Ran the full Solar System simulation overnight, for 137,000 steps
and 377 simulated years, with no disasters or apparent errors in
the resulting configuration.

Built a complete box for the Uraniborg space model environment.  The
floor is unchanged, while the sides and root are double-sided versions
of the Uraniborg platform, with the star field on both sides, and
marked phantom, which allows objects and avatars to move through them
unimpeded.  They, however, serve as a background when viewing or
photographing models within the box.

\date{2021 January 23}

Moved generation of the floating text legend to Minor Planets to save
memory in the main script, and because the JD editing functions and
information about the tracked object are already there.

Built Asteroid and Comet models, with the comet generating particle
systems to showo the coma and tail, scaled to its distance from the
Sun, and the tail oriented away from the Sun.

Developed the first cut at a mass model generator for the numerical
integrator, with the first focus on central configurations such as
Trojan systems and rosettes.  This took a deep dive into the Perl {\tt
Math::Quaternion} and {\tt Math::Vector::Real} modules, which are well
worth mastering for this kind of work.

\date{2021 January 24}

Added the ability specify the number of orbit segments in the:
\begin{verbatim}
    Orbits body [ nsegments ]
\end{verbatim}
command.

Using the Asteroid body script as the pathfinder, added the ability to
display a floating text legend above the body showing the most recently
updated rectangular co-ordinates and radius vector (in AU) and the
heliocentric latitude and longitude in degrees.  This is generated by
{\tt updateLegend()}, which is passed only the rectangular co-ordinates
of the update: it figured out the heliocentric spherical co-ordinated
from that and deployerPos saved from when it was rezzed. A handy {\tt
rectSph()} function is provided for this transformation, which may
prove useful elsewhere.

Display of the legend is controlled by \verb+s_legend+ in the settings,
which may be toggled by touching the body.  We'll look into command and
script control of this further down the road.

Fixed parsing of Epoch statements with HH:MM[:SS] time specifications,
Julian day specifications without fractional parts.  Added a call so
the model is immediately updated when the Epoch is set.

Added ``Set real on/off/step n'' to control real time, in which the
planets display their current configuration.  The real time display is
update every 30 second by default, but may be changed with the ``step
n'' specification where $n$ is the interval in seconds.

In the process of putting together a sample of representative asteroid
and comet orbits as a test suite, somehow or other I accidentally ended
up with a UTF-8 character trailing one of the orbital element
parameters.  This, when imported into Minor Planets and eventually
passed to the ephemeris evaluator set off a Chinese fire drill of
disasters due to typos, inadequate error checking, and LSL's propensity
for propagating NaNs through a long series of computations until it
decides to tell you ``Math error'' with no more precision than the name
of the script in which it occurred.  After several hours of debugging
and tracing back to the source, the one-character fix became obvious,
but in the process error checking and fault tolerance in orbital
element specifications has been much improved, which is something I
intended to do anyway before shipping and would have been well advised
to do before it could have saved me a great deal of time and trouble.
In any case, everything works now with the examples that provoked the
original problem and further slips of the keyboard should be caught
before they cause calamity.

In order to suppport the forthcoming ``true ellipse orbit'' feature and
possible future optimisations I added the ability to request ephemeris
data for multiple dates in the \verb+LM_EP_CALC+ message simply by including
multiple Julian date/fraction pairs between the body bitmask and the
handle at the end.  The request concatenates all of the requested
ephemerides into a message, appends the handle, and returns it to
the requester.  This is 100\% compatible with existing requests that
only require the ephemeris for a single date.  As always, the Minor
Planets script serves as the pathfinder for this---it will be propagated
to the rest of the ephemeris scripts once it's fully tested here.

\date{2021 January 26}

Updated all of our display items which rez prims [{\tt flPlotLine()},
the creation of ellipses for orbits, and {\tt markerBall()}] to test
whether the item they're creating is 10 metres or more from the
deployer and do the little trick of moving the deployer there before
rezzing the object.  A new function, {\tt flRezRegion()}, which takes
the same arguments as {\tt llRezObject()}, handles this automatically.

\date{2021 January 27}

After several days of developing the mechanism to display elliptical
orbits with ellipses created from scaled and properly oriented cylinder
prims, I returned to figuring out why some minor planets ended up with
potato-shaped orbits.  Suspecting our usual nemesis of single precision
round-off, I developed tools to allow comparing an orbit computation by
Solar System Live with one done by our ``Orbit 10'' command.  These
tools are maintained in the \verb+.../Gravitation/orbit_debug+
directory (which is outside the Git repository).

Testing with orbit of 5496 (1973 NA), whose orbit displays hideously
and has orbital elements:
\begin{verbatim}
    Asteroid "5496 (1973 NA)" t 2455540.5 a 2.434695101869629
        e 0.6368122950745937 i 68.00432693434864 w 118.1062637269031
        node 101.0823617074469 M 322.5808921760293 H 16.0 G 0.150
\end{verbatim}
I found that the discrepancy between the two evaluators was almost
entirely in the B (heliocentric latitude) value, with errors as
high as 14.7\%.

Well, upon further investigation, LSL's single precision is (in this
case, and bearing in mind the hoops we jump through to cope with it)
completely exonerated.  The problem turned out to be a fat finger in
the expression in posMP() in Minor Planets which computes the
heliocentric latitude from the co-ordinates returned from
computeOrbit().  Once fixed, the discrepancy between the double
precision Solar System Live values and those computed in LSL were no
more than 0.01]% for the test orbit.

Performed an audit of all orbit tracing to validate its accuracy
against the double precision VSOP87 in Solar System Live and to check
whether the truncation of some of the periodic terms for the giant
planets due to the 64 Kb script memory limit compromised accuracy in
single precision evaluation.  Everything appears to be OK, and is more
than adequate for proper appearance at the scales in which we render
the model.

\date{2021 January 28}

Added preliminary support for plotting orbits of parabolic and
hyperbolic orbits.  If the orbit has no semi-major axis, we plot
outward from the periapse along both arms of the curve (positive time
and negative time) until we reach a limit in AU set by \verb+o_aulimit+
which is currently fixed at 10 AU.

Rewrote the Orbit command to integrate line and ellipse orbits and
allow the user to control whether the prims that represent them are
permanent or temporary.  The command is now:
\begin{verbatim}
    Orbit body [ segments/ellipse [ permanent ] ]
\end{verbatim}
At the moment, temporary ellipses are not implemented, but line orbits
may be either permanent or temporary.

Added the abililty of external commands (those not implemented within
the main script) to suspend scripts.  The code in the main script must
set scriptSuspend as usual, but when the external command is done, it
can send a \verb+LM_CP_RESUME+link message which will call {\tt
scriptResume()} and get the script running again.  Initially
implemented this for the Orbit command, allowing development of a minor
planet element parsing and orbit display test script, ``{\tt Script:
Orbits}''.

Meeus algorithms (including constants) are available for Go at:
\begin{verse}
    \url{https://godoc.org/github.com/soniakeys/meeus/v3}
\end{verse}

Integrated the multiple ephemeris request logic for \verb+LM_EP_CALC+
into {\tt Ephemeris: Mars}, which will serve as the pathfinder for
ellipse fitting to planets.  The code is essentially identical to that
developed and tested in Minor Planets, and will be integrated into the
other planet ephemeris calculators once it's checked out on Mars.

\date{2021 January 29}

Propagated the multiple request ephemeris code into the ephemeris
evaluators for all planets and tested them all with the "``orbit
\ldots\ ellipse'' command.  Everything worked except Pluto, which
awaits an overhaul to use the JPL orbital element definition instead of
the Meeus periodic term solution.

Decided to break with my tradition of not starting Git management of
the project until declaring a release candidate.  This project has
become sufficiently sprawling and complicated that maintaining an audit
trail of changes and being able to examine code prior to major
re-structurings justifies the additional overhead at this point. So I
created the repository:
\begin{verbatim}
    git init
\end{verbatim}
and populated it with the current state of the source code.
\begin{verbatim}
    git add --all
    git commit -m "Initial commit"
\end{verbatim}
Note that at this point I am not creating a GitHub repository, but
simply starting Git configuration control on a local basis.

Eliminated the unused items from the \verb+LM_OR_ELEMENTS+ messages
sent in orbital ellipse generation from the Orbits and Minor Planets
scripts.

Completed the first pass of moving the numerical integrator from the
main Gravitation script (where it has been disabled to avoid memory
crashes) to its own ``Numerical Integration'' script.  This script
handles the Mass command to declare the masses as well as running the
integration itself.  Most of this is done by processing commands
forwarded from the main script when a numerical integration model is
loaded.  The main script now forwards its settings to the other scripts
in the deployer with an \verb+LM_AS_SETTINGS+ link message as well as
to the masses with llRegionSay\ldots .  It is basically working, but
there are a lot of state-setting issues such as handling settings
turning the legend on and off while a numerical integration is running.

Fixed propagation of the legend settings to Numerical Integration.

Completed the initial implementation of a replacement for the Pluto
ephemeris calculator with a stripped-down version of the Minor Planets
evaluator using the JPL Small-Body Database orbital elements for Pluto,
which are hard coded into the \verb+s_elem+ list in the source.  From a
cursory test, plotting position and drawing the orbit appear to be
working OK, but fitting an orbit ellipse is wrong (while fitting an
ellipse to the same elements loaded as an asteroid works fine).  I'll
dig into this after night's restorative sleep.

\date{2021 January 30}

The problem with fitting an ellipse to Pluto's orbit was simple: we
didn't have the required table entries for the {\tt apsides()} function
in Orbits to find the perihelion time of Pluto.  I added them (from the
JPL Small-Body Database) and everything works fine now.

Script suspend and resume for the Orbit and Orbit \ldots\ ellipse
commands now work correctly.  The ``Orbits'' script may be used to
verify this as well as testing edge cases for orbit generation.

Fixed Script suspend/resume to work with Step command for planetary
theory.  Fixed script suspend/resume to work with the Step command
for numerical integration.

\date{2021 January 31}

Added script suspend/resume support for the Planet, Asteroid, Comet,
and Mass commands.  This is still tacky for the Planet command with no
arguments, which presently resumes after the first planet completes
initialisation.  It should wait until all of them have initialised.

Completed a very preliminary implementation of the cluster synthesiser
in \verb+tools/cluster_models/cluster.pl+.  It is parameterised by
arguments to the function {\tt addCluster()} (which will eventually be
set by the command line or a parameter file), and creates Mass
declarations for the specified number of masses, with or without a
central mass.  This is intended to model star clusters, and test models
typically run with parameters like:
\begin{verbatim}
    set auscale 0.00003
    set kaboom 250000
\end{verbatim}
as they are set in the {\tt Galcent} test script in the development
deployer. At the moment, all masses are placed in circular orbits, are
white, and have the same size.  Refinements to set these parameters
will be added over time---the immediate goal is to test the numerical
integrator in a complex environment, not make pretty pictures.

\date{2021 February 1}

W. B. Klemperer's paper on symmetrical meta-stable n-body central
configurations, ``Some Properties of Rosette Configurations of
Gravitating Bodies in Homographic Equilibrium'' ({\em Astronomical Journal}.
67 (3), April 1962: 162–167).
\begin{verse}
    \url{http://articles.adsabs.harvard.edu/pdf/1962AJ.....67..162K}
\end{verse}
contains equations for a parameter he calls ``$k$'' which provides a
correction factor to the sum of masses in the configuration that
computes the net central force on a body in a symmetrical polygonal
``rosette'' configuration that is used to calculate the constant angular
velocity at which the bodies will orbit (at least initially)
circularly.  These equations (two versions are supplied, one for an
even number of bodies, one for odd) are incorrect and do not reproduce
the values given in Table I which purport to have been computed from
them.  (The error(s) are in addition to the typographical error in the
equation for an even number of bodies, where ``$u$'' appears instead of the
intended ``$n$''.)  I cannot even figure out what Klemperer was trying to
do in the equations, so after wasting a great deal of time, I simply
re-derived the whole thing from first principles, implementing the
vector calculations in \verb+tools/cluster_models/cluster.pl+ in the function
netForce(), which computes the vector net force on a body in the
current model, taking the gravitational constant $G$ as 1.  It also
returns the total mass of bodies in the model, and Klemperer's $k$ value
may be computed as the magnitude of the force vector divided by the
total mass.  Testing this for the examples in Klemperer's paper shows
that the values in his Table I are correct, notwithstanding the
erroneous equations claimed to have produced them.  In any case, we can
now correctly compute the central force for any symmetrical
configuration, with much greater precision than the three significant
digits given in Klemperer's paper.

Added support for central masses in ring configurations.  With the
general computation of k, this doesn't require any special handling in
computation or orbital velocity, as the central mass is automatically
accounted for.  Adding even a large central mass doesn't noticeably
stabilise a three mass rosette configuration, which becomes undone due
to single precision round-off just about as quickly as in the absence
of one.

Added support for elliptical orbits in clusters generated by
{\tt addCluster()} in {\tt cluster.pl}.  After assigning a random eccentricity to
the orbit within the range specified in the {\tt addCluster()} call,
{\tt genCluster} computes the velocity of a body at periapse in an orbit with
the chosen semi-major axis and eccentricity around the centre of mass
using the vis-viva equation:
\begin{verse}
    \url{https://en.wikipedia.org/wiki/Vis-viva_equation}
\end{verse}
which simply expresses the invariant total energy of a geodesic orbit
as the sum of its gravitational potential and kinetic energy and
solving for periapse velocity, which is:
\[
    v = \sqrt{((1 - e) G M )/ ((1 + e) a)}
\]
where $a$ is the semi-major axis, $e$ the eccentricity, and $G M$ the
standard gravitational parameter ($\mu$).  For simplicity, we start all
bodies at apoapse and let evolution of the model shuffle them up
based upon the different orbital periods.

\date{2021 February 4}

In the Galactic Centre module, calculation of positions of sources S175
and S4714, both of which have eccentricities in excess of 0.98, were
failing when trying to use the Landgraf/Stumpff algorithm for
near-parabolic motion presented in chapter 35 of Meeus's {\em
Astronomical Algorithms}.  This is the algorithm we've been using in
Solar System Live for ages, but it simply does not work in single
precision floating point: it runs away and bails out on a failure to
converge.  I removed it and made {\tt gKepler} use the Roger Sinnott
binary search algorithm, which works for any eccentricity up to 1.
This corrected the calculation for these sources.

Making a synthetic comet with an eccentricity of 0.985, I verified that
the near-parabolic algorithm also fails in Minor Planets.  I removed it
from there as well, which gives a little more breathing room in script
memory there.

In an attempt to speed up updates when there are many objects in a
simulation (a case exacerbated by the Galactic Centre model, where the
full cluster now has 43 objects, I changed the distribution of position
updates to objects from individual {\tt llRegionSayTo()} calls for each
object to a collective update sent with {\tt llRegionSay()} which
contains as many object updates as will fit in 1024 characters.  This
is based upon research with Gridmark, which revealed that the
bottleneck with region messages is the rate at which they can be sent
and not the byte rate.  This way we can update all 43 objects with just
two messages.

To further improve performance, I replaced sending co-ordinates as
decimal numbers with the {\tt fuis()} and {\tt siuf()} functions from
the library:
\begin{verse}
    \url{http://wiki.secondlife.com/wiki/User:Strife_Onizuka/Float_Functions}
\end{verse}
which preserve all bits of a float's precision and encode each number
as just 6 base64 characters.  This allows packing more updates into a
message and is much faster when encoding and decoding.

With these changes in place, the computation and distribution of updates
appears to be substantially faster than all of the individual objects
can update themselves.  We'll need some form of feedback and throttling
to avoid lost messages and the consequent jerky updates.

\date{2021 February 5}

To avoid message loss and non-responsiveness to Run/stop commands, I
implemented a feedback mechanism which prevents sending an update
to Galactic Centre sources before they're all done moving from the
previous update.  This is done by having the last source created
(and how it detects it's last a dog-dirty trick, but lightning fast)
send an UPDATED message to the deployer when it's done moving.  In
Gravitation, we ignore timer ticks to update between the time we send
an \verb+LM_GC_UPDATE+ message and when the UPDATED confirmation arrives.
This keeps everything in sync and avoids flooding the message queue.

Modified {\tt sendSettings()} in Gravitation to include simEpoch in the
settings, and the Epoch command to push settings when changing the
Epoch.  Galactic Centre now uses this to place sources at their correct
position for the epoch rather than in placeholder positions which were
updated on the first simulation step.  This is a small refinement, but
it looks a lot less silly when you're starting up a simulation.

Implemented orbit tracing and elliptical orbit fitting for the Galactic
Centre model.  As with Minor Planets, this is done entirely within
Galactic Centre with only a little help from Orbits to draw the orbit
outline.

Completed a major code clean-up in the Mass and Source objects (those
used in Numerical Integration and Galactic Centre simulations,
respectively).  I removed lots of dead code dating to when the masses
had more autonomy, added support for the Set Labels command to show or
hide object labels, and generally made things more comprehensible.
This leaves only the Solar System planets to be done, but since the
script is replicated in each one, that's a lot more busy-work which I'll
defer until I'm confident there aren't more changes I need to propagate
to all of them.

Upgraded the Mass command handler in Numerical Integration to
correctly handle quoted body names in upper and lower case.  This
provides compatibility with the Asteroid and Comment commands in
Minor Planets and the Centre and Source declarations in Galactic
Centre.  This was simplified since all of the arguments to the Mass
command after the name are inherently case-insensitive.

\date{2021 February 6}

It appears that in the course of avatar events, occasionally a {\tt
llRegionSay[To]()} message will be lost, even when it is right nearby
in a nearly idle region and the recipient listener does not have a
problem with message queue overflow.  This happens every ten minutes or
so to one of the confirmation messages from Galactic Centre sources
which we use to throttle the rate at which updates are sent,resulting
in the simulation freezing up.  I added logic to the {\tt timer()}
event in Gravitation which sets a watchdog timer whenever it starts
deferring updates due to \verb+ev_updating+ being set.

After a much more involved struggle than was expected (or justified,
based upon the eventual solution), I got the sources created by
Galactic Centre to clean up their ``Set paths lines'' trails after
being deleted by the deployer.  This is a bit more complicated than you
might think, because the {\tt flPlotLine()} objects created for trails
do not have the main deployer as their creator, but rather the
individual sources which plotted them along the orbit.  This means the
trails will not respond to a {\tt ypres} message from the main
deployer, but instead must receive a message forwarded by the
individual source that rezzed them. (Since we always check the key of
the sender of a message to an object to avoid confusion if more than
one instance of one of our models is present in a given region.)  I
added code to forward the ypres message to the line segments and a
handler in the script within them to clean themselves up upon receiving
it.

I also confirmed that you don't need to mark a prim Temporary when
creating it with the builder, but that setting \verb+PRIM_TEMP_ON_REZ+
in its \verb+on_rez()+ event suffices.  This makes it much easier
working with temporary prims, as they don't ``peek-a-boo'' and
disappear while you're editing them before taking them into inventory.

The trails for Galactic Centre objects created by ``Set paths lines''
appeared to get out ahead of the objects as they moved along their
orbits because we updated the path with {\tt flPlotLine()} before
moving the object itself.  I changed the order of updates which fixed
such ``anticipatory orbiting''.

Propagated the changes from the Galactic Centre source object to the
Numerical Integration mass object which is very similar but not
identical (for one thing, it does not presently use the bulk update
message protocol or handshake completion of updates back to the
deployer).  Everything appears to be behaving.  These changes also,
of course, need to be installed in the Solar System planets, but as
noted above, I'll defer that larger and fussy job until I'm sure things
have settled down and I only need to visit them once.

``Ignore previous wire\ldots .''  The ``lost messages'' problem with
Galactic Centre that caused so much commotion above turned out to have
an entirely different and more subtle cause.  The ``GC Fast'' model I
was using for most of my testing included a ``S999'' source that I
ginned up in a hyperbolic path in order to test tracing non-closed
paths in the Orbits command.  Well, as it happened, that was the last
source declared in the model and, being on a hyperbolic trajectory,
eventually flew away out of Kaboom range and self-destructed.  Once the
source was gone, there was nobody to return the UPDATED confirmation to
the deployer, and the simulation would freeze.  The un-sticking code
wouldn't help, since the source responsible for acknowledging the
update had permanently shuffled off this grid of existence.

To cope with this, I moved handling of Kaboom detection from the Source
object's script into Galactic Centre itself, whose main update loop now
checks every new position computed for a source for being in excess of
\verb+s_kaboom+ AU from the deployer and  also for falling outside the
region box of $<[0,255), [0,255), [0,4096)>$.  If a source has strayed
beyond where it belongs, it is sent a KABOOM message and its key
removed from \verb+source_keys+, which causes it to be ignored on
subsequent update cycles.  Note that this does not handle sources
straying off the parcel but remaining within the region.  That will
take additional hackery in the new {\tt elKaboom()} function to deal
with.

This is not presently required for Numerical Integration masses as they
do not use a confirmation messages and may disappear without stalling
the simulation.  If and when we add confirmation to them, logic like
this will be required there as well.

To avert an imminent memory crisis in Galactic Centre (where we may
want to load more than forty known sources orbiting Sgr A*), I split
the user interface and parsing of object parameters into the original
Galactic Centre script and the evolution of orbital motion into a new
Galactic Patrol script, which is invoked by the main simulator and also
handles related functions such as plotting orbits and fitting ellipses
to closed orbits.  This gets all of the gnarly orbital mechanics and
storage of orbital elements out of Galactic Centre and allows Galactic
Patrol to handle that without all the clutter of parsing object
definitions and assorted text bashing.  There are many refinements to
be made (in particular, Galactic Patrol stores far more orbital element
information about each source than it actually needs, but it's
basically working and can load the complete galactic centre model
without blowing a gasket.

Went through all of the Ephemeris calculators for Solar System,
changing all of the calculation of periodic terms to perform additions
in the order of absolute magnitude, smallest to largest.  This serves
to make the most of the (severely) limited dynamic range available in
LSL's single precision floats.  I further cleaned up code, disabling
computation of some higher order powers of time which were not used in
some of the simpler sets of periodic terms.  Comparing results from the
original and optimised code showed only very minor differences in a few
items which wouldn't make a difference in the display, but given that
we're forced to deal with single precision, it makes me feel better
knowing that proper floating point hygeine allows is to make the most
of what we're given.

Modified the Pluto ephemeris calculator to range reduce the
heliocentric latitude to 0 to \verb+TWO_PI+.  This is consistent with
all of the other ephemeris calculators.  It actually doesn't make any
difference in any of our uses of the ephemeris results, but it's easier
to compare results among ephemeris calculations if they're all
consistent in the range of results they return.

\date{2021 February 7}

Further adjusted the division of responsibility between Galactic Centre
and Galactic Patrol to equalise memory usage between the two.  Galactic
Centre contained an entire copy of the orbital position calculation
code which was used simply for setting the initial position of newly
created sources.  To get rid of all that duplicated code, I modified
the creation of sources as follows.  When a new source is created,
Galactic Centre now places it coincident with the central mass, which
doesn't require the deployer to jump to the location of the mass.  Once
the mass is created and sends its SOURCED message, Galactic Centre
notifies Galactic Patrol with an \verb+LM_GP_SOURCE+ message which now
includes the current simEpoch as well as the source key and orbital
elements. When Galactic Patrol receives this message, it computes the
initial position of the mass at simEpoch and sends it to the mass with
llRegionSayTo() in an update (``{\tt U:}'') message addressed just to
that mass.  The Source menu in the object then moves to the specified
position using {\tt llSetLinkPrimitiveParamsFast()} if it is within ten
metres of the initial position and {\tt llSetRegionPos()} if it's
further away.

With these changes in place and all of the now-unused code in Galactic
Centre removed, after loading the entire ``Sgr A*'' model, with 45
sources, memory usage is only 67\% in Galactic Centre and 79\% in
Galactic Patrol.  These could further be reduced by modifying Galactic
Centre to discard the orbital elements of sources after sending them to
Galactic Patrol and Galactic Patrol to only store the orbital elements
it needs to compute the orbital position instead of the whole thing as
it presently does.  Since neither are presently near the cliff, and
we're unlikely to add many more sources to the model in the near
future, there's no reason to proceed further at this time.

\date{2021 February 8}

Began experimentation with automatically setting step and tick times
for Numerical Integration simulations.  To untangle the parameters, as
a temporary expedient I made ``Set steprate'' directly set the
integration step time in years, while ``Set simrate'' sets the timer tick
rate running steps in seconds.  This is horrid from a consistency
standpoint and incompatible with Solar System and Galactic Centre, but
it makes it a lot easier to observe the effect of settings.  I ran the
{\tt Galcent} model overnight with:
\begin{verbatim}
    Set step 20y
    Set sim 0.1
\end{verbatim}
and everything went smoothly, including stopping immediately when I
paused it after running all night.

Removed {\tt fixargs()} from Gravitation.  None of the commands parsed
there require its tender ministrations, so it was just wasting space
and time.

Moved processing of the ``Orbit'' command from Gravitation to the
Orbits script itself as an auxiliary command.  This saved a bit of
memory in the Gravitation script, but the main motivation was
permitting extension of the Orbit command to properly handle body names
of Solar System objects (including tracked minor planets), quoted body
names including spaces and upper and lower case, and improved error
detection and reporting.  The Orbit command now accepts names of Solar
System bodies as well as their index, permits quoted name fields, and
respects letter case for body names, including those it forwards to
Minor Planets and Galactic Centre for handling.

Completed a major revision to Numerical Integration's communication
with its Mass objects.  These previously used hex-encoded floating
point numbers to pass initial creation parameters and settings to
masses, and decimal numbers to send new positions.  Now they all use
Base64-encoded {\tt fuis()} and {\tt siuf()} to send floating-point
values with full precision in base64 encoded binary strings (actually,
integers). This allowed the complete elimination of the LSL Library
{\tt Float2Hex} function, which was huge in terms to static memory and
slow.  All onward communications from Numerical Integration now use
base64 encoding, although other components still speak in primitive
pidgin dialects.

\date{2021 February 9}

Ran a Numerical Integration {\tt Galcent} simulation with ``Set paths
lines'' overnight with no problems.

Updated Galactic Centre and Source to communicate settings to the
sources using {\tt fuis()} and {\tt siuf()} instead of decimal numbers.
This is faster and prevents loss of precision on values such as AUscale
which might otherwise be truncated.

Removed decoding of settings in Galactic Centre and Galactic Patrol
which were never actually used by those modules.

\date{2021 February 10}

Made the long-deferred and much-dreaded sweep through all of the Solar
System planets, updating them to receive their settings and update from
the deployer via {\tt fuis()}/{\tt siuf()}.  Most of the planets were
broken with respect to ``Set paths lines'', not containing the required
{\tt flPlotLine} object, which is now fixed.  I cleaned up some
obsolete code in the planets, some dating back to their Flocking Birds
ancestor.  The Asteroid and Comet models were updated like the planets,
and their generation of a floating text legend made to respect ``Set
labels'' from the deployer.

Set the colour of the trails drawn by Solar System planets based upon
the resistor colour code of their planet number.  Asteroids and comets
draw a silver trail, based on the 10\% tolerance band colour.

Moved the {\tt asteroid.lsl}, {\tt comet.lsl}, and
\verb+comet_head.lsl+ scripts from the {\tt scripts/ephemeris}
directory, where they were incorrectly placed, to the {\tt
scripts/planets} directory where they belong.

Installed the new, much faster, version of {\tt fuis()} in Galactic Centre,
Galactic Patrol, Gravitation, and Numerical Integration.  This version
removes capabilities we don't require (preservation of sign on negative
zero and encoding of infinities) and, in return, runs almost three
times faster than the version from the LSL Library.

\date{2021 February 11}

Rewrote the orbit computation code in the Orbits script's handling of
the \verb+LM_OR_PLOT+ and \verb+LM_EP_RESULT+ messages to store all its
Julian dates in the [ \verb+whole_day+, fraction ] list format, use
{\tt sumJD()} to increment dates while plotting the orbit, and a new
{\tt compJD()} function to compare dates in list format.  This removes
a great deal of code gnarl and makes it much easier to understand what
is going on.

Removed the special-purpose code for closing elliptical orbits and
replaced it with simple computation of the closing segment.  This
allows the adaptive segment length mechanism to work on the first
and last segments of the orbit without any special cases or duplication
of code.

Replaced the complex and ugly code for plotting parabolic and
hyperbolic trajectories with a much simpler strategy which computes the
start and end dates of the plot by subtracting and adding the extent to
be plotted from the perihelion date.  These are then used precisely as
the start and end dates of an elliptical orbit, and allows the adaptive
segment length mechanism to be used without modification.

Created a new model script, ``{\tt Nearby Stars}'', based upon the
table in A. K. Dewdney's {\em The Armchair Universe}, p. 235.  This
represents the positions and velocities of stars near the Sun, as known
in 1988.  I'll have see what's available from the Gaia data releases or
more recent catalogues to create a more comprehensive model.  This
isn't a particularly interesting model, since the nearby stars are so
far apart with respect to their masses, they just keep on going with
their own proper motions until they pass the Kaboom radius and go away.
I'll have to experiment with stirring things up with, say, a passing
through intermediate mass black hole, to see if that makes things more
thrilling.

\date{2021 February 13}

Completed a major revision of how orbits and plotted and ellipses fit
for orbits of sources orbiting the Galactic Centre.  Due to the
historical path by which the code was developed, there was a large
degree of duplication between the orbit displays generated for Solar
System bodies in Orbits and the equivalent code in Galactic Patrol.
This not only wasted space, but it made maintenance more difficult
because very similar functions were done in two different places. When,
for example, we added the adaptive step size for plotting orbits in
Orbits, it only applied to Solar System bodies and not Galactic Centre
sources.

The revision ripped out essentially all of the orbit-related code from
Galactic Centre and Galactic Patrol and replaced it with transmission
of the essential orbital elements when sources are added, then the
Orbits module sending a \verb+LM_EP_CALC+ message to Galactic Patrol to
calculate the positions of the source.  This is not entirely
straightforward because the ephemeris calculators for Solar System
return heliocentric spherical co-ordinates (L, B, R), while Galactic
Centre's evaluator computes rectangular (Cartesian) co-ordinates (X, Y,
Z), so when using these co-ordinates code must be aware of the source.
Nonetheless, the duplication of code is minor and most of the orbit
display code is now in common.  This dramatically reduced memory usage
in Galactic Centre and Galactic Patrol, making them entirely safe from
out of memory conditions even when loading large models such as our
``Sgr A*'' script.

Note that Minor Planets still has its own handler for the
\verb+LM_OR_ELLIPSE+ message, which largely duplicates that in Orbits.
Another refinement would be getting rid of it as well, but I will leave
this for another day, as the level of duplication is modest and we
aren't tight on memory in Minor Planets.

\date{2021 February 14}

Promoted the script containing examples of representative minor planets
to \verb+notecards/minor_planets.nc+ and added to the Git repository.

Completed the rationalisation of orbit display by removing the
\verb+LM_OR_ELLIPSE+ handler in Minor Planets and integrating
generation of orbit ellipses for minor planets with the main code in
Orbits.  This required ironing out a few wrinkles, such as transmitting
eccentricity and semi-major axis back to Orbits when a new minor planet
is tracked and modifying the {\tt apsides()} function in Orbits to
correctly compute the perihelion and aphelion dates for minor planets
from their orbital elements, but in the end little code was added there
and a great deal removed from Minor Planets.

Cleaned up all of the dead code commented out and made obsolete by the
re-organisation of the orbit and ellipse display mechanisms.

Began the upgrade of the Earth model to be responsive to the date.
Added code to process the Julian day included in the UPDATE message
from the deployer, extract the Gregorian month, and set the texture
for the Earth globe to the correct month from the inventory.  We
also calculate the Greenwich Mean Sidereal Time (GMST) which, in
conjunction with the position of the Earth (from the update) and
deployer (provided by the PINIT message), we should be able to
rotate the Earth so the proper hemisphere faces the Sun, but I shall
defer such a tilt with rotation until I've gotten some shut-eye.

Linked the Luna model to the Earth model as a sub-link, with the
intention of setting its position based upon our {\tt lowmoon()}
calculation from the date in the UPDATE message.  This is not presently
done.

\date{2021 February 15}

To make it simpler to initially position the Earth and Moon model, I
moved the Moon child prim so it's coincident with the centre of the
Earth.  This makes the centre of mass of the link set at the centre of
the Earth, so the initial rez of the pair goes to the right place.
(We don't worry about the Earth-Moon barycentre offset at this level
of scale.)  You can still easily edit the embedded Moon using Edit
linked and the {\tt Ctrl-}, key to select it.

This is just (yet another) reminder that if nothing seems to make any
sense, your script is utterly unresponsive, and nothing you do seems to
have any effect upon the situation, open the script that's vexing you
in the editor and look at the ``Running'' and ``Mono'' check boxes at the
bottom left (at least, that's where they are in Firestorm).  If they're
not checked, your script is dead to the world and will do nothing.
Editing and saving the script doesn't seem to change this. You have to
check both boxes and then edit and save or reset the script to get it
running.  The script may be disabled after a script error, and I've
seen it happen after a turbulent region crossing in a vehicle, but in
some cases it ``just happens'', probably as a result of linking
operations.  When it does, it will drive you nuts until you figure out
what is going on, so don't forget to check these two check boxes before
they double cross you.

Modified the Orbit command handler in Orbits to default the number
of segments in an orbit plot to 48, not 96.  This is more than adequate
now that we have the adaptive segment length handler.  It may be
possible to reduce it further based upon experimentation.

You can now specify a permanent orbit plot with the default number of
segments with ``Orbit {\em body} permanent'': there's no need to specify a
segment count.  You can still, of course, append the ``permanent''
modifier after a segment count.

Updated the ``flPlotLine Temporary'' and ``flPlotLine Permanent'' objects
in the deployer to use versions which are initially transparent.  This
avoids the disturbing flash of the unmodified object if the script is
slow to gain control and set the colour and length prescribed by the
function in the script which created the line.

Modified the Boot command to send the message to delete the entire
model before resetting the scripts.  There's no point keeping a model
around after a reset has caused them to forget everything about it.

At a first and second glance, the code we're using to point the Earth's
north pole at the right position in space looks correct.  This will
require more careful validation with other planets and verification
that it doesn't mess up handling of axial rotation when we get to that.

Changed the calls which create planet models from inventory in
Gravitation from {\tt llRezObject()} to {\tt llRezAtRoot()}.  This
allows us to use planet models in which the centre of the root prim is
not the computed centre of the link set, which we might want to do
should we wish to initially arrange satellites of a model in a manner
not entirely symmetrical around their primary.  Due to this problem,
Earth's Moon is presently hidden inside the core of the planet until
the link set is rezzed, but with the change this no longer need be
done.

\date{2021 February 16}

Setting of scale factors of objects and orbits in Solar System was
partly broken and the rest inconsistent.  Instead of using the
originally intended ``radscale'' setting, they used separate
\verb+m_scalePlanet+ and \verb+m_scaleStar+ values, which are
communicated in the PINIT message, before SETTINGS are known to
objects.  There was no way for the user to set these, however.  I added
a new:
\begin{verbatim}
    Set scale planet/star/au n
\end{verbatim}
command to set these and also the scale for astronomical units in
plotting orbits, previously set by ``Set AUscale'', which is now
deprecated, generates a warning, and will be removed after it is
extirpated from all of the scripts.  The originally intended Set
radscale, which is faithfully transmitted around everywhere in SETTINGS
packets, is actually only used when initially scaling Numerical
Integration and Galactic Centre masses based upon their mass.  I will
eventually replace this with \verb+m_scalePlanet+, but defer that until
I next revisit that module.

All of this was provoked by trying to figure out what the triaxial
ellipsoid shape of the Comet model was lost when creating it.  This,
of course, was due to our scaling the model too small and causing it
to be limited to 0.01 metres in region co-ordinates.  I'll have to see
how much bigger I need to make it to keep this from happening.

After experimentation, I made the Comet model 50\% larger in all three
axes, which preserves its triaxial aspect when rezzed with the default
Set scale planet 0.1 setting.

The code we added on 2021-02-06 to forward the {\tt ypres} message from
the Mass and Source objects to \verb+s_trails+ objects they created was
never ported to the Solar System planets, so their trails would persist
until the next garbage collection.  Here is a log of integrating this
code:
\begin{verbatim}
    Comet Asteroid Earth Mars Mercury Venus Jupiter Saturn Uranus
    Neptune Pluto
\end{verbatim}
Note that the Sun never makes trails.

Confirmed that setting up an omega rotation (\verb+PRIM_OMEGA+) in the
Comet object does not disturb the particle emission we use to generate
the tail.  Consequently, I added a random omega rotation (just made up,
since we know little about actual rotations other than the fact that
the few we've seen do appear to be rotating) to the Asteroid and Comet
models.  The axis and rate are chosen at random when the object is
rezzed.

\date{2021 February 17}

From a preliminary test, it looks like the position of the Moon is
correct with regard to the phases computed by Earth and Moon viewer.

The reason (or at least one of the reasons) north pole alignment for
Solar System bodies was wonky was that the {\tt eqtoecliptic()}
function, which appears in the script for each body, was completely
wonky.  Its computation of the heliocentric longitude ($\lambda$) was
from Planet Right, but the heliocentric latitude was from the Bungle
Nebula.  It neglected to multiply by the sine of the obliquity of the
ecliptic in the second term, and then forgot to take the arcsin of the
(wrong) difference.  Fixing these corrected the results to within
single precision roundoff of those in the example from Meeus.  Once
debugged in the Luna module, this, of course, needed to be propagated
to each of the Solar System body scripts.

Propagated the corrected {\tt eqtoecliptic()} to all of the Solar
System body models.  Jupiter and Saturn look much more reasonable now!

Removed the computation of equatorial co-ordinates for Luna in the
function {\tt lowmoon()} and the support functions it required.  Since
we need only the ecliptic co-ordinates, the equatorial co-ordinates
were never used and just a waste of time and space.

\date{2021 February 18}

Added a {\tt jdToMSD()} function in the Solar System Mars planet script
to convert a Julian day and fraction derived from Earth UTC to the
corresponding Mars Sol Day according to the procedure:
\begin{verse}
    \url{https://en.wikipedia.org/wiki/Timekeeping_on_Mars#Formulas_to_compute_MSD_and_MTC}
\end{verse}
Note that getting this to the second requires knowing the current
offset in seconds from TAI (atomic clock time) and UTC due to leap
seconds.  This cannot be computed, as it is entirely empirical based
upon measurements of the Earth's rotation and the priesthood of
timekeeping.  It is set by \verb+LEAP_SECOND_COUNT+ in the code, which
is 19 seconds as of today.  In practice, LSL single precision round-off
is greater than errors due to several seconds' discrepancy in this
value, and precision to the second is supererogatory when all we need
to do is put the meridian in an orientation that ``looks right''.

\date{2021 February 19}

After performing the appropriate rituals at the Temple of the Triple
Product and sacrificing a unit quarternion at the shrine of William
Rowan Hamilton, I think I have a function which will correctly manage
updating the rotation of a satellite which is tidally locked to its
primary.  The pathfinder for this is Luna (Earth's Moon), whose script
includes the function {\tt tidalLock()}, which is called with the
updated local position of the satellite and uses its
previously-computed (and invariant) north pole orientation ({\tt
npRot}) as a hidden argument. Since satellites are child prims of link
sets whose root prim is the primary they orbit, there is no need to
pass the location of the primary, as their local positions are already
relative to it.

The function computes the rotation around the axis defined by the
centre of the satellite and its north pole which causes the vector from
the satellite's centre through its prime meridian to fall within the
plane defined by the rotation axis and the centre of the primary. This
is complicated, as usual, by the need to keep track of which side of
the plane the meridian vector is starting from and adjust the direction
of the rotation accordingly.  The result is the complete rotation for
the satellite, consisting of the north pole orientation rotation
composed with the axial spin to align the meridian.  We assume, as is
the case for all tidally locked satellites in the solar system, that
the prime meridian has been defined as the point which is (more or
less, neglecting orbital eccentricity, etc.) fixed in the direction of
the primary.  If this be not the case, it's a simple matter to compose
a fixed offset with this vector to adjust to the desired meridian.

Got ``Set paths lines'' working for Luna: the code should carry over
for other satellites.  This is a bit more tricky than for a main body,
since we need to transform the satellite co-ordinates in local space to
region co-ordinates and cope with the motion of the primary body
(bringing the satellite with it).  Each trail segment is plotted from
the end of the previous one to the satellite's new position, taking
into account all of these motions.

Added code to propagate the {\tt ypres} message from Earth to Luna so
it can clean up any trail lines it has created.  Earth needs to wait
250 milliseconds between sending the message and committing its {\tt
llDie()} lest it destroy the satellite script before it gets a chance
to clean up its debris.

\date{2021 February 20}

By comparison with the JPL HORIZONS service, our calculation of
heliocentric longitude, latitude, and rectangular co-ordinates are
correct (or, at least the same conventions as they use).  In
particular, the heliocentric longitude for a body at the March equinox
is 180 degrees and its position falls along the $-$X axis.  This is
also consistent with the presentation by Solar System Live for views
from heliocentric latitude 90 degrees.

Integrated the ``Set label'' support code in all Solar System bodies
and, while I was at it, fixed the SETTINGS message handler to the label
appears as soon as it is enabled instead of waiting for the next UPDATE
message.

Implemented a major revision to how planets with satellites work which,
after getting over the speed bumps, should dramatically simplify how
they work and eliminate a great deal of confusion in the scripts that
run them.  Previously, the primary (planet) was the root link of the
link set, contained the main script that talks to the deployer, and
passed on updates to satellites, which were its child prims.  This had
the huge disadvantage that, while moving the planet along its orbit
correctly moved the satellites with it, any other change in orientation
of the planet (pointing its north pole at the correct location in
space, rotating around its axis every planetary day, etc.) would also
carry all of the satellites along with it, and require us to take out
the undesired rotation on every update of the primary and satellites.
This was not only ugly, complicated, and slow in terms of API calls, it
could result in jerky motion of the satellites as they were first moved
to unwanted locations by rotation of the primary, then moved back to
where the belong by their own scripts.  Even more horrible, there was
the possibility of synchronisation problems between the updating by the
main and satellite scripts if script performance was slow and messages
got backed up.

To avoid all (well, most) of this mess, I restructured planets with
satellites as follows.  Each has a hidden object with the name of the
planet (for example, ``{\tt S: Earth}'') which contains the main script
for the planet and all of the textures, auxiliary objects such as the
line plotting prims for {\tt flPlotLine()}, etc.  This is the root prim
of the link set, but in normal circumstances remains invisible to the
user (it can be shown for debugging by editing the texture).  It
contains child prims including one called ``Globe'', which is the
displayed globe of the planet and ones for every satellite.  The link
numbers for these are found using our {\tt findLinkNumber()} function
from their names, so no assumptions are made about link numbers.

The root prim is moved to move the planet and satellites around their
orbit, but it is never rotated: it always retains its original zero
rotation.  Any rotation of the globe is done by a local rotation to the
Globe child prim, which affects only it and does not interfere with
the satellites.  The satellites, in turn, are updated based on their
relative position to the primary and do not need to take into account
any rotations applied to the Globe, as it is now simply a peer child
prim, not their root prim.

The new planet structure appears to be working, albeit with the wrong
computation of north pole and hour angle, but manipulation of the
Globe no longer interacts with updating of the Moon, which is working
correctly.

\date{2021 February 21}

Removed unnecessary backing-out of primary rotation in Luna.  Since the
primary now always has a rotation of zero, it did no harm, but wasted
time and was potentially confusing.

To test by stepping at the sidereal rate use:
\begin{verbatim}
    Set steprate 23.934469h
\end{verbatim}
This will, of course, experience round-off over time thanks to single
precision arithmetic.

Using the Earth and Moon as the pathfinder, completed the initial
implementation and deployment of a ``complex planet''.  Although in
some ways the Earth and Moon is more complex than most (its rotation
must be synchronised to Greenwich Mean Sidereal Time computed from the
epoch, and a special evaluator is used to compute the position of the
Moon as opposed to standard orbital elements), it is not a completely
general case in that the Earth's north pole is coincident with the Z
axis of the equatorial co-ordinate system and it may be possible that
something in the general transformation from equatorial to ecliptic may
be backwards or otherwise messed up.

\date{2021 February 22}

Built our second ``complex planet'', Jupiter, along the lines of the
Earth, but with the four Galilean satellites, using Io as our
pathfinder to debug the satellite motion.  As expected, the nontrivial
north pole orientation of Jupiter smoked out a pullulating horde of
bugs from the roach motel which was {\tt rotPole()} in the planet
script.  With these fixed, it was time to move on to Io's orbit.

I originally adapted the Io script from the Luna script for Earth's
Moon and, after testing it with completely bogus orbit code for Luna,
moved on to computing its orbit from the orbital elements, then ran
out of time and had to move on to non-productive paperwork courtesy
of coercive government.

\date{2021 February 24}

Derivation of the Gaussian gravitational constant for an arbitrary
central mass is as follows.  In general,
\[
    k = \sqrt{G M}
\]
where G is:
\[
    6.6743\times 10^{11} {\rm m}^3 / {\rm kg}\ {\rm s}^2
\]
To convert to units for solar system astronomy, we wish to use:
\begin{verbatim}
    AU = 1.4959787e+11 m
    Msun = 1.98892e30 kg
    day = 86400 s
\end{verbatim}
so we compute:
\[
    k = \sqrt{G M\ {\rm AU}^{-3}\ {\rm day}^2}
\]
which can be done in Units Calculator as:
\begin{verbatim}
    sqrt(G sunmass ( 1 / au^3) day^2)
\end{verbatim}
yielding:
\begin{verbatim}
    0.017202099
\end{verbatim}
radians per day for a body orbiting the Sun at one astronomical
unit.

For our planetary satellite systems, we wish to work in units of
kilometres instead of astronomical units, but we continue to use
days.  We substitute in the mass of the planet in the same kg
units we used for the Sun.  For Jupiter, as an example:
\begin{verbatim}
    km = 1000 m
    Mjup = 1.8982e27 kg
\end{verbatim}
with Units Calculator:
\begin{verbatim}
    sqrt(G (1.8982e27 kg) ( 1 / (1000 m)^3) day^2)
\end{verbatim}
yielding:
\begin{verbatim}
   9.7249547e+08
\end{verbatim}
(I enter the mass of Jupiter as a number because Units Calculator's
``{\tt jupitermass}'' has a slightly different value than the currently
accepted standard.)

This value should produce correct results for satellites orbiting
Jupiter whose semi-major axis is specified in kilometres.

Substituted in the computed value for $k$ into {\tt gKepler} of the Io
script and---cazart---{\em it works}!  (At least based upon preliminary
testing.) Now it's a matter of making all of this cleaner and more
portable across different planets.

Completed the first draft of the new model of Jupiter for the Solar
System.  This will serve as the pathfinder for the other giant planets
with satellites.  Jupiter's north pole position is now correct (I'm
pretty sure), and implemented in a general way we can use for other
planets.  The same goes for rotation, which is synchronised with the
equatorial rotation speed but makes no attempt to align a ``prime
meridian'' (which doesn't exist for these giant planets), or do
anything about differential rotation by latitude.

The four satellites have scripts which differ only by the orbit and
physical parameters declared in the {\tt planets[]} list at the top.
Since all of these satellites are tidally locked, they use the {\tt
tidalLock()} function developed for Luna.

All of the orbit computation is based upon the GM value for the planet,
which is declared in its {\tt planet[]} list.  We use GM because for
many solar system bodies the product GM, which can be determined by the
orbits of satellites, is known better than its factors G and M
separately.  To adapt for a different planet, all that should need to
be changed is the GM value.

\date{2021 February 25}

Added an archive of all of the textures used in Solar System planet and
satellite models to the Git archive in the directory {\tt
textures/planets} with subdirectories for each body.

The one thing that's clear after getting Jupiter's satellites working
is just how hideous the scaling problems are going to be for a
pleasing display that fits into a tractable space for most people while
trying to preserve some semblance of being a scale model.  Our
compromises so far have worked reasonably well, allowing all of the
planets to be to scale (but with the Sun at 1/5 its scale) and orbits
to scale, albeit with planets and orbits to very different scales.

The introduction of satellites throws a huge monkey wrench into this:
at this scale Callisto is orbiting so far from Jupiter it almost hits
Jupiter's orbit on the far side of the solar system.  I am going to
have to spend some time thinking about approaches to this, but I'm
going to defer it until I do Saturn, which is probably going to make
things even worse, and Uranus, which is going to get the Z axis into
the game with its wonky inclination and satellite orbits.

This thing is becoming sufficiently big and complicated that I'm
uncomfortable having it based entirely upon a single Git repository,
and the size of the texture files, now incorporated within the
repository, make it unwieldy to back up wholesale with flashback.  I
created an archival repository on GitHub:
\begin{verbatim}
    orbits
\end{verbatim}
with access URLs:
\begin{verse}
    HTTPS: \url{https://github.com/Fourmilab/orbits.git} \\
    SSH:   git@@github.com:Fourmilab/orbits.git
\end{verse}

Linked the local repository to the GitHub archive:
\begin{verbatim}
    git remote add origin git@@github.com:Fourmilab/orbits.git
\end{verbatim}

Added a disclaimer to {\tt README.md} about the development status of
the code.

Confirmed that my local ``git sync'' command works with the remote
repository.

\date{2021 February 26}

Included the texture image for each Solar System body in its model.
We also include the textures in the development kit, but this makes
them easier to find should the models become separated or re-used in
other builds.

Created models for the moons of Uranus: Miranda, Ariel, Umbriel,
Titania, and Oberon.  Re-structured the model for Uranus in the same
way we've done for Jupiter and Saturn, adding the satellites as links
to the main box link and separating the planet globe as a separate
child link.  The fact that Uranus orbits ``on its side'' (inclination of
97.77 degrees) doesn't require any special handling since our code
which sets the planet's orientation based upon the celestial
co-ordinates of its north pole handles this in its stride.

The directory for Uranus in the Git repository was re-organised in the
same way as Jupiter and Saturn, with a main directory for the planet
and subdirectories for its satellites.

\date{2021 February 28}

After pushing farther and farther into the darkness of intractable
configuration control, with code duplicated among dozens of LSL scripts
and no way to easily disseminate changes, I stepped back and began to
re-cast this entire project as a Literate Programming project using
Nuweb.  The goal is to have, at minimum, all LSL scripts and, ideally,
all text files, generated from a master {\tt .w} file with Nuweb.  This
will allow incorporating common code from a single definition into
every script where it is used, eliminating the absurd burden of
maintaining dozens of copies of code across planets, satellites, and
other scripts in this sprawling project.

You have to start somewhere, so I decided to begin on the dark,
frozen plains of Neptune's moon Triton.  After porting masses of
foundation code, I now have a version of the Triton script which is
generated entirely automatically from the Nuweb file and, as far as I
can tell, works.

In the process, I have made major clean-ups of the code, using Nuweb to
define constants previously done with global variables (using script
memory space), unifying all of our Kepler equation solvers into a
single version, and exploting commonality between the scripts for
planets and their satellites.

This is all, still, by the standards of proper Literate Programming,
very crude, with much clean-up of what has been done so far remaining
and vast expanses of crufty code to import and integrate.  But the
proof of concept is complete: we can generate valid UTF-8 LSL code
from Nuweb and create PDF documentation containing UTF-8 characters
with no problems.  This clears the way to making this a much more
comprehensible and easy to maintain program.

The next step is to complete the integration of Neptune into the
Nuweb program: the planet script and ephemeris calculator and, in
the process, create the generic tools which will allow bringing in
all of the rest of the Solar System major planets.

\date{2021 March 1}

After much struggling with Nuweb, I have ported the ephemeris
calculation for Neptune to the Literate Programming implementation,
creating the framework whereby the calculators for all of the other
planets may be created with just a few lines of planet-specific code
and inherit all of the generic code that is defined only in one place.

Due to the fact that some of the giant planet evaluators fit in memory
only if we disable the memory status query that lets us know how close
we are to the edge, I implemented a down-dog-dirty trick to only
generate the memory status support code in evaluators with the room to
support it.

\date{2021 March 2}

Ported all of the planet scripts and their ephemeris calculators into
the Nuweb document.  Note that their use of the common planet code
will require the remaining planets which do not have separate planet
and Globe objects (Mercury, Venus, Mars, and Pluto) to be upgraded to
that structure.

\date{2021 March 3}

Integrated the Minor Planets script into the Nuweb document.  This
allowed making the {\tt posPlanet()} code common between Pluto
and Minor Planets.

\date{2021 March 4}

Completed integration of the Script Processor into Nuweb.

Installed the ephemeris calculators for the planets into the Deployer
object.  With the restructuring of the ephemeris, Mercury and Venus now
have separate ephemeris calculators while previously they were combined
into one script.

Enabled the {\tt \#include} feature in Firestorm Build preferences to
allow easier management of files created by Nuweb from the master
{\tt orbits.w} web.

Use the {\tt \#include} facility to integrate the Script Processor
produced from the web.  It seems to work just fine.

Replaced the ephemeris calculator scripts with includes from files
generated from the Web.

\date{2021 March 5}

After a Chinese fire drill due to a fat-finger where I pasted the
link to Pluto's ephemeris calculator where Venus was intended, the new
ephemeris calculators appear to be working as intended.

Turning off labels for planets was broken: the code that cleared
the floating text used {\tt LINK\_THIS} instead of {\tt lGlobe} to
set the text on the planet's globe.

Integrated the Asteroid and Comet object scripts produced from the web
into the model.  Both work correctly.

Integrated the Comet Head script into the web and replaced the script
in the object with the one generated from it.  It works fine.

Integrated the scripts for the satellites of Jupiter into the Nuweb
document.  This required a bit of work because it had been a while
since the embedded scripts were developer and the satellite script code
had evolved substantially since then.  The satellites now work, and for
the first time orbit in their Laplace planes, not forced to Jupiter's
equatorial plane (although there isn't much difference).  The scale for
the orbits is now the standard and may be way too big for Jupiter: I'll
defer consideration of satellite orbit scales until they're all done
and I can look at the whole thing together.

\date{2021 March 6}

Integrated the {\tt flPlotLine} and Marker Ball object scripts into the
Nuweb program.  I have yet to integrate the scripts generated from the
web to the objects and incorporate them into their hosts.  I verified
that the code generated is identical to that prior to the integration,
so there's no urgency getting to this.

Integrated the Minor Planets script generated from the Nuweb document,
replacing the original version.  Based on my usual test cases, it is
working correctly.

Integrated the satellites of Uranus into the web and replaced the
scripts in the planet object with those it generates.

Integrated the ``planet script'' for the Sun into the Nuweb file.  The
common planet script code did not handle the special scale factor for
stars, and hence on first creation the Sub was way too large.  I
integrated the code for the Sun's scale factor, which is used when the
body index number is zero.

One more tweak was necessary for the Sun as a ``planet'': its legend
display (which wasn't implemented when the original Sun script was
written) must skip the display of position since that is not only
meaningless but also divides by zero because the Sun's radius vector is
zero.  I now check for the body index and only display the name when it
is zero.

Built a new-style model for Mercury and installed the planet script
generated from the web.  Mercury now spins at the proper rate.

Built a new-style model for Venus and installed the web-generated
planet script.  In the process, I discovered our handling of planets
with retrograde rotation (which we indicate by a negative sidereal
rotation period) was incorrect.  I fixed this for the general case in
{\tt rotHour()} so both direct and retrograde rotation works.

Updated the Mars model to the new style and incorporated the planet
script generated by Nuweb.  In the process, I discovered the sign on
the right ascension for the north pole was incorrect.  Once fixed, the
orientation and rotation of the red planet looks to be correct.

Updated the Saturn model to use the script generated from the Nuweb
document.  This required the addition of parameters to the
{\tt Planet object script} macro to specify code to be run when the
{\tt PINIT} message is processed and when an {\tt UPDATE} message is
received from the deployer.  The Saturn model uses this to adjust the
ring system's scale and orientation to comport with those of the
planet when the object is created and initialised.

\date{2021 March 7}

Added screen-grabbed images for all of the planets in the web document.

The ephemeris calculator for Pluto was poorly-presented, running off
the end of the page.  I broke it into comprehensible pieces with
documentation for each chunk.

Revised the {\tt view} target in the Makefile to re-run Nuweb after a
preliminary run of XeLaTeX to update cross-references and table of
contents.

Integrated the web-generated script for the {\tt flPlotLine} object
into the master object and installed it for testing in the Pluto and
Charon models.  Note that everything else, at this moment, is still
running the (functionally equivalent) old version.

Built a new-style model of Pluto and Charon and integrated
web-generated scripts for both.  Pluto and Charon's orbits appear to
work correctly, but the wonky orbital inclination of Charon breaks our
{\tt tidalLock()} rotation computation.  I'm also not sure if Pluto's
rotation is in the right direction, given that it's sideways in its
orbit.  I'll need to look into both of these.

After a great deal of struggle and much parameter twiddling, I now have
an acceptably clean way that permits near-maximal code commonality
among all of the planets.  Earth required two planet-specific
interventions.  The first was to handle changing the texture to the
current month's Blue Marble image when the simulated month changes.
We'd already provided for this in the definition of {\tt Planet object
script} so this was straightforward.  The second was handling rotation
based on the current date, which required replacing the standard {\tt
rotHour()} with one specific to the planet which knows its absolute
meridian position at any given date.  This was handled by a new
argument to {\tt Planet object script} which allows us to specify a
suffix to the name of the {\tt rotHour()} function call.  In this case,
we specify ``{\tt Earth}'', calling {\tt rotHourEarth()} instead of the
standard function.  That function, in turn, computes the Greenwich
Meridian Standard Time for the simulated time and aligns the meridian
accordingly.

This is still more than a tad messy.  In particular, the script for a
planet like Earth contains many functions imported for a more standard
planet which aren't required and only waste space.  On the other hand,
a planet script has plenty of spare space and doesn't grow over time,
so there's no incentive other than purity of essence in removing them.
In any case, the new, improved Earth now appears to be working and
playing nicely with both the deployer and the (original) Luna model.

Next, it's on to the Luna model, which will be even more messy, since
it has its own, completely different changes from the stock satellite
code.  That will require an even more in-depth review of commonality
between the other satellites and Luna and re-organising code
accordingly.

\date{2021 March 8}

Updated the {\tt Makefile} to that the {\tt lint} target stops as
soon as {\tt lslint} finds an error in one of the scripts.

The whacky rotation of Charon was due to a fat-finger in specifying
the plane of rotation.  When corrected, it looks reasonable, but I
haven't yet confirmed it's in the correct direction.

Built the first, very rough cut, of merging the satellite script for
Luna with the script used for all other scripts.  It works, so now it's
a matter of factoring out commonality in the interest of concision and
maintainability.

Built a new master script for all of the other satellites,
incorporating the new common code which was extracted for use in Luna.
Rebuilt all the satellites using it, and tested with the satellites of
Jupiter, which appear to be behaving.

The periodic terms embedded in the main web were a distraction, so I
enabled the {\tt appendix} package and used it to create proper
appendices for the document, with the periodic terms, collected
together for all the planets, and the development log as appendices. I
also used the ``\verb+\chapter*+'' trick to remove the chapter number
from the Indices, making it stand out better in the table of contents
and on the page.

\date{2021 March 9}

Consolidated the path generation by particle system, which was
performed by identical code for planets, satellites, and minor planets,
into a single definition in Utility Functions which is used in all
cases.

Consolidated the mostly-identical declarations of global variables
for major planets, asteroids, and comets into a single ``Planet global
variables'' declaration.  Specific bodies then declare any of their
own that aren't common.

Cleaned up the messy business with the declaration of the {\tt
LM\_PL\_PINIT} message, which is used by the Saturn object script to
pass initialisation parameters to the ring system.  It was previously
declared for all planets and generated unreferenced variable warnings
for all but Saturn.  I moved its definition into the Saturn object
script so it won't cause trouble elsewhere.

Integrated the Source object script for Galactic Centre into the Nuweb
master.  This allowed sharing many of the common functions with the
Solar System model, including particle system path generation, which
was generalised to allow specification of the source for the colour of
the particle trails.  The {\tt exColour()} function, which parses an
extended colour specification including transparency and glow, and is
used by both Galactic Centre and Numerical Integration, was promoted
to be a top level utility function.

Migrated the Ecliptic Plane object script into the web and replaced the
script in the object with the one generated from it.  In the process, I
discovered that it included a copy of {\tt tawk} which it never used.
I eliminated it and everything appears to work correctly.

\date{2021 March 10}

Integrated the web-generated script for Marker Ball objects into the
master object.  Set Marker Balls as Phantom, like everything else we
create.  Added logic so when you directly rez a Marker Ball from
inventory it doesn't interpret the zero start parameter as instructions
to become a tiny black ball.  If you really want to create such a
beast, just give it a colour of <1, 1, 1>: nobody will notice the
difference.

Upgraded the definition of {\tt flPlotLine()} in the web to be the
extended version from the Orbits script which allows selection of
permanent or temporary plot lines and uses {\tt flRezRegion()}
(\ref{flRezRegion}) to allow plotting lines more than ten metres from
the object that created them.  I added inclusion of that function in
all places {\tt flPlotLine()} is used.

\date{2021 March 11}

Integrated the Orbit Plotting script and support utilities into the web
and replaced the script in the Deployer with that it generated.

Integrated the Orbit Ellipse script into the web and replaced its
script with the one it generated.  Added logic to prevent an instance
manually rezzed from inventory responding to commands from a deployer.

Added Elon Musk's Tesla Roadster ("Starman") to the test objects in
the Minor Planets example notecard.

\date{2021 March 12}

Integrated the Numerical Integration Mass script into the web.  There
are minor differences in the initialisation parameters and settings
between Galactic Centre Source objects and Mass objects which prevent
using the same code: these might be ironed out in the interest of
unifying the code, but now isn't the time for such refinements.

Integrated the Numerical Integration script into the web.  Verified
that it works as before.

\date{2021 March 13}

Completed the long-deferred ``big gulp''---bringing the main script,
now renamed {\tt deployer.lsl}, into the web.  This involved quite a
bit of clean-up, since there was duplication of names of functions in
that script which handle the Solar System model and those in other
scripts which perform analogous operations for Galactic Centre and
Numerical Integration.  The big win was that this provided a perfect
place to document the commands in the Deployer, which will provide a
head start when it comes time to compile the User Guide for the product
as a whole.

The magnitude of this thing is somewhat daunting: the entire program
is now 334 printed pages, and that's before integrating Galactic
Centre or any of the ancillary utilities and support files.

\date{2021 March 14}

Integrated the Galactic Centre script into the web, taking advantage
of commonality in the computation of the gravitational constant with
Numerical Integration, with the code being moved up to the Constants
section of Mathematical and Geometric Functions.

Integrated the Galactic Patrol script into the web.  This completes the
unification of all of the {\tt gKepler()} orbit calculation to use the
common function, leaving only the very simplified {\tt lunaKepler()}
used for the Earth's Moon an outlier, and it's so simple I'm not sure
adding all the complexity in using {\tt gKepler()} would make any
sense.

\date{2021 March 15}

Integrated the Rings of Saturn script into the web.  This was a simple
one, as its only job is to scale the rings to the same scale as the
globe of the planet.

Integrated the satellites of Saturn into the web.  This completes the
integration of all of the original scripts into the web.

\date{2021 March 16}

Completed the unification of orbital element parsing in Minor Planets
and Galactic Centre into a single {\tt parseOrbitalElements} function
declared in the Positional Astronomy utilities chapter.  Previously,
these simulations had near-identical copies of the same code, which
differed only in that the one for Minor Planets assumed the central
mass was the Sun while the one in Galactic Centre used the mass of the
central mass declared by the Centre command.  I made the central mass
an argument to the function and used the same function in both modules.

In the process, I discovered that when the orbital element parser is
computed derived elements from those given, for minor planets it
returned the value in degrees while for galactic centre sources it was
in radians. This actually did no harm, since we never used the value in
the galactic centre code, but in the interest of consistency (and since
all other angular orbital elements are in degrees), it now always
reports degrees.

\date{2021 March 17}

Started to make illustrations for the web document and the Marketplace
and fell into a rathole with {\tt flPlotLine()}.  You're supposed to be
able to set the width of the cylinder prims it creates with an argument
that selects from four available widths, but due to a fat finger in the
code, this was broken.  When I fixed that, I was able to select width,
but the available widths were inappropriate for our use, so I changed
them to something more reasonable.  This changed the request, but of
course the width is passed as an integer index in the start parameter,
and must be changed accordingly in the object that receives it.  There
were two copies of the table of widths, which led to heroic levels of
confusion until I figured out what was happening and unified them in
one macro which is used in both places.  Now it was just a matter of
replacing the {\tt flPlotLine} object in every model that traces its
path, recompiling the script in every object, and importing them into
the Deployer.

This illustrates how the lack of any kind of configuration control in
Second Life renders development and maintenance of complex models like
this an utter nightmare.  We now must ensure that every model that uses
{\tt flPlotLine()} has been recompiled, taken into inventory, and
incorporated into its parent object and ultimately into the Deployer.
I'm beginning to think the only way to cope with this may be a
broadcast of version number to every component and reporting if it
doesn't agree.

\date{2021 March 18}

Implemented a proper build number and data and time facility.  The
build number and date are kept in a {\tt build.w} file which is
included in the main {\tt orbits.w} Nuweb file in the Introduction
section.  The Status command now reports the build number and date.

Integrated the version checking code into all scripts in the Deployer
and all objects it creates.  This required a few special cases to
handle things like the Comet head linked object and Saturn's ring
system, where the root link must forward the {\tt VERSION} message to
the child link as a link message.  In the process of testing this with
Saturn, I discovered I'd never switched over its satellites to the
versions generated from the web---got better.

\date{2021 March 19}

Integrated the {\tt tools/build/update\_build.pl} program used to update
the build number and date into the web, along with a header to be used
for it and other Perl programs.

Implemented the first cut of ``Set Satellites {\tt on}/{\tt off} {\em
name}/$n$\ldots''.  This allows enabling or disabling the display of
satellites for arbitrary planets in the Solar System model, with
display by default off.  The mechanism is somewhat intricate: the
Deployer parses the statement and passes it on to objects with a {\tt
SETTINGS} message.  The planets receive this message and forward it to
their satellites via {\tt LM\_PS\_DEPMSG}, and the satellites then handle
hiding or displaying themselves by setting transparency and
transporting to the core of the planet, disabling processing of {\tt
UPDATE} messages as long as they are invisible.

\date{2021 March 20}

Implemented forwarding of {\tt VERSION} messages by objects created by
the Deployer which, in turn, create objects of their own.  The
principal example of this is planets, satellites, sources, and masses
which trace their trajectories with {\tt flPlotLine()} objects. All of
these now forward a {\tt VERSION} validation query with the version
passed by the Deployer ({\em not} their own, which may not be the same)
to objects they create, allowing them to verify their build number
against that of the Deployer.  For planets, this has currently been
integrated only into Saturn and its satellites---we'll need to go
around the Horn and update all of the others the next time we're
ready for a general overhaul of the Solar System model.

Modified the Deployer to use {\tt flRezRegion} to create planets.  This
avoids the Deployer's bobbing around when, in the usual case, the
planets are created within 9.5 metres of the Deployer's position.  It
also makes planet creation much faster, not that it really matters.

Fixed the Planet command to accept a range of planet number to be
created, as documented.  Somehow this had been omitted from the code.

Added the build number and date and time to the explanatory comment
at the beginning of files generated from the web.  This gets stripped
by the Firestorm preprocessor, but will be there when we manually
paste in the code for the final Marketplace version.

Integrated the {\tt Makefile} into the web, with the usual trickery to
{\tt unexpand} the space-delimited output from Nuweb, which we call
{\tt Makefile.mkf}, into the actual make file.  Added a {\tt squeaky}
target, under development, to delete everything generated from the web
and force it to be re-generated.

Made {\em le grand swoop} through all of the Solar System planets and
satellites and updated to the latest versions produced from the Web. In
the process, I fixes problems all over the place, including a number of
satellites which were still using scripts not generated from the web
and many with versions of {\tt flPlotLine} that did not support build
number checking.  All of this was fixed.  In the process of testing, I
discovered further problems with scaling of the Pluto model which were
corrected.  This is not, of course, the final pass through the Solar
System, but I think we're getting closer to be able to make some
pictures for the documentation and Marketplace listing.

At this point, as far as I know, every object in the entire model is
running a script generated from the web.  If not entirely ready for the
Grand Unification with the Git repository, we're getting closer.

\date{2021 March 21}

Changed the {\tt build} target in the {\tt Makefile} so it doesn't
generate the \LaTeX\ file and the {\tt view} target so it doesn't
generate the program files; this will make things a bit faster.

Added the {\tt -r} option to the run of Nuweb when generating the
documentation.  This automatically hyper-links all scrap references to
their definitions.

The ``permanent'' modifier on the ``Orbit'' command wasn't working. The
updated version of the script installed in the cylinder prim used by
{\tt flPlotLine()} to trace lines was unconditionally setting {\tt
PRIM\_TEMP\_ON\_REZ}, which overrode the status of the prim in
inventory.  I modified the script to check for the presence of the
substring ``{\tt Permanent}'' in the name of the prim and, if it's
specified, leave its temporary/permanent status as set in the
inventory.

The ``Set Satellites'' command with no argument was not displaying
Pluto's satellite Charon because the mask it set for the satellites
failed to set the $2^9$ bit---fixed.

Specifying planets by number in the ``Set Satellites'' command didn't
work because the clever code that fixes the case of the first letter
mangled single character specifications due to the odd way {\tt
llGetSubString()} works when given start indices beyond the end of the
string.  I rewrote the code to avoid the problem.

Once we move the development environment back into Git, the updating of
the build number and date would result in a large number of meaningless
Git transactions since on every build every would be updated to change
the build information.  I added the option to disable inclusion of the
build number until we're ready to start making release candidates and
want to re-establish configuration control over their contents.  The
build number is still incremented on every build to preserve
history---this simply skips embedding the build information in the
scripts.   This is explained by a comment before the inclusion of {\tt
build.w} in the Introduction chapter.

\date{2021 March 22}

Integrated the Literate Programming environment into the Git
repository.  The original {\tt scripts} and {\tt logs} directories have
been removed to an {\tt OBSOLETE} directory outside the repository.  A
{\tt .gitignore} file excludes temporary files generated during the
Nuweb build and subsequent generation steps from the repository, but we
do track changes to generated from content of the web.




\section{To Do}

Soft gravitational potential for n-body close encounters.

Re-test set paths (particles) for Solar System.  It may work better
now that we've de-coupled rotation from the root prim.  We could even
have a special particle emitter prim, but that would be costly compared
to its worth.

Saturn:
    Check inclination and north pole orientation.

Set tick as alternative sim spec.  Any two suffice, shows all 3
resulting.

Set path length to set expiration time of path particles.

Merge mode for collisions.  Goes "blop", sums mass and
momentum vectors, averages colours, and adjusts radius
based upon cube root of added mass.

Adjust sit position based upon rotation of bodies.

Only rotate body if we're generating paths with particles.

Send a single message to update the positions of all bodies
as opposed to one message per body.

Optimise paths via lines.  Only generate a line if the motion is
greater than a certain length or, perhaps, if the angle has
changed more than a threshold.

Computation of simulated time, define steps using it.  We should
attempt to simulate a fixed amount of *simulated time* in each clock
tick, regardless of how many integration steps it takes to do so,
depending upon the adaptive step size calculation.

Fix paths alignment.

Specify orbits by orbital elements, derive r and rdot.

Scale particle params with overall scale of comet?

Set legend on/off [ body... / all ]

Body legend display: save last update pos, use to show legend immediately
when touched.

Invert command to negate all velocities in numerical integration
models to run time backwards.
