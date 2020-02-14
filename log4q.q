/
    Forked from https://github.com/prodrive11/log4q 
    Reformatted for easier reading -- More verbose
\

\d .log4q

format: "%c\t[%p]:H=%h:PID[%i]:%d:%t:%f: %m\r\n";

sev: snk: `SILENT`DEBUG`INFO`WARN`ERROR`FATAL!();

// Specify digits allowed for %XXX mapping
digits: 5;

add: {
    h[first x]:: $[1 < count x; x 1; {x@y}];
    snk[y],:: first x;
 };

remove: {snk:: @[snk; y; except; x];};

// Define dict-map for h/fnMap
/ h - contains map for STDOUT/STDERR
h: fnMap: ()!();

// Define mapping for each type
fnMap["c"]: {[x;y] string x};
fnMap["f"]: {[x;y] string .z.f};
fnMap["p"]: {[x;y] string .z.p};
fnMap["P"]: {[x;y] string .z.P};
fnMap["m"]: {[x;y] y};
fnMap["h"]: {[x;y] string .z.h};
fnMap["i"]: {[x;y] string .z.i};
fnMap["d"]: {[x;y] string .z.d};
fnMap["D"]: {[x;y] string .z.D};
fnMap["t"]: {[x;y] string .z.t};
fnMap["T"]: {[x;y] string .z.T};

// Restrict logger to types mapped under fnMap
logger: {
    typeMap: raze key[fnMap] where format like/: ("*%" ,/: key[fnMap] ,\: "*");
    ssr/[format; "%",/:typeMap; .[;(x;y)] each fnMap[typeMap]]
 };

// Count regex char length (taken from kdb+ ssr)
countChars: {
    n: x?"[";    
    if[n = count x; :n];                                        // Return if no "["  
    x: _[n+ 2+ "^"= x @ n+1; x];                                
    n + .z.s $[count[x] = p: x?"]"; '"unmatched ]"; p] _ x      // Check for matching "]" for "["
 };

// Find indices of %XXXX and return as dictionary
findReg: {y, .[!; flip (0, countChars z) +/: x ss z; ()]}; 

// Generate print log msg
print: {$[10h ~ type x,:(); x; (2 = count x) & 10h = type first x; mapArgs[x]; .Q.s1 x]};

// Map log-args based on python "printf" methodology (ssr modified here)
/ Print up to `.log4q.digits specified 
/ 3 digits -----> max up to %999
mapArgs: {
    if[digits < 1; 
        '"Set .log4q.digits to above 1"
    ];
    searchSpace: 1_ ,[;"[0-9]"]\[digits;"%"];
    dict: findReg[first x]/[()!(); searchSpace];
    slicedStr: _[asc raze 0, flip (key dict; value dict); first x] except enlist "";
    idx: where slicedStr like "%[0-9]*";
    mapIdx: -1+ "J"$ 1 _/: slicedStr[idx];
    raze @[slicedStr; idx; formatArgs; @[(), last x; mapIdx]]
 };

// Format log-args
/ Example: .Q.trp[{1+`}; 1; {INFO ("Message:\n\n%1";enlist .Q.sbt y)}];
formatArgs: {
    $[10h = abs type y; y; 1 < count y; .Q.s1 y; null y; ""; .Q.s1 y]
 };

// Severity Level -- `INFO by default if -log cmdline not specified
sevLvl: $[`log in key .Q.opt .z.x; first[`$ upper .Q.opt[.z.x][`log]]; `INFO];

// Define `.log4q.s`.log4q.d`.log4q.i`.log4q.w`.log4q.e`.log4q.f 
// Correspond to `SILENT`DEBUG`INFO`WARN`ERROR`FATAL
l4qFnSpace: .Q.dd/:[``log4q; `$ ((), first ::) each string lower key snk];

// log4q Exceptions, Protected Evaluations
l4qExcept: {[h;e] '"log4q - ", string[h], " exception:", e};
l4qProtEval: {[stdIO;msg] .[`.log4q.h[stdIO]; (stdIO;msg); l4qExcept[stdIO]]};

l4qFnSpace set' {l4qProtEval[; logger[x; print y]] each snk[x]} @/: key[snk]; 

// Identity Function
n: (::);

// Mapping based on Severity Level specified 
sev: key[snk]!((s;d;i;w;e;f);(n;d;i;w;e;f);(n;n;i;w;e;f);(n;n;n;w;e;f);(n;n;n;n;e;f);(n;n;n;n;n;f));

// Add to h/snk dictionaries
add[1;`SILENT`DEBUG`INFO`WARN];
add[2;`ERROR`FATAL]; 

\d .

// Set `SILENT`DEBUG`INFO`WARN`ERROR`FATAL
key[.log4q.snk] set' .log4q.sev[.log4q.sevLvl];

/
========================
log4q alike 

    p.bukowinski@gmail.com
=========================

Features:
    * various severity levels
    * various logging levels
    * various sinks - STDIN/OUT, FILE, TCP
    * particular levels logs sent only to choosen sinks, all filtered by severity level
    * simplified set of pattern layouts available - runtime switchable
    * pre-log "printf" alike variables injecting

---------------
commandline opts:
---------------
    sets severity
    -log [(silent|debug|info|warn|error|fatal)]
    default severity: info

---------------
log examples:
---------------
ERROR "simple message";
INFO (23.;`test);
WARN `test;
SILENT 23;

/printf alike formatting:
q)INFO ("This is a log %1 %2 %3";(23;`adf;(3;{x+y});4));
INFO    [2012.03.01D23:44:01.593750000]:log4q.q: This is a log 23 `adf (3;{x+y})


---------------
default sinks:
---------------
(silent, debug, info and warn) to stdout
(warn, error and fatal) to stderr

---------------
Logs pattern layout - format (.log4q.format) 
---------------
* can be changed in runtime
supported formats:

    %c Category of the logging event.
    %d Current UTC date  (.z.d)
    %D Current local date  (.z.D)
    %t Current UTC time (.z.t)
    %T Current local time (.z.T)
    %f File where the logging event occurred (.z.f)
    %h Hostname (.z.h)
    %m The message to be logged
    %p UTC timestamp (.z.p)
    %P Local timestamp (.z.P)
    %i pid of the current process

ex.
q)ERROR "simple message";
ERROR   [2012.03.01D23:32:30.609375000]:PID[1924];log4q.q: simple message
q).log4q.format:"%c\t[%p]:H:%h;PID[%i];%d;%t;%f: %m\r\n"
q)ERROR ("%2 simple message";`another);
ERROR   [2020.02.15D17:24:04.629473000]:H:desktop-5dik518;PID[2016];2020.02.15;17:24:04.629;log4q.q: ` simple message

---------------
sinks management
---------------
* user manages handles on his own

/add sink  
* file handle
    .log4q.add[hopen `:my_test2.log;`INFO`ERROR]
* TCP handle with special modification function
    .log4q.add[(hopen `::5555:user:pass;{x@(`upd;`msg;y)});`INFO`ERROR`FATAL]
  
ex:
    q -p 5555
    -----------
    q)upd:{[x;y] 0N!(x;y);}

    q log4q.q -p 5001 -log info
    -----------
    q)INFO ("Test %1 log";1222);
    INFO    [2012.03.01D23:14:17.718750000]:log4q.q: Test 1222 log
    q)DEBUG ("Test %1 log";1222);
    q).log4q.snk
    SILENT| 1
    DEBUG | 1
    INFO  | 1
    WARN  | 1
    ERROR | 2
    FATAL | 2
    q).log4q.add[(hopen `::5555:user:pass;{x@(`upd;`msg;y)});`INFO`ERROR`FATAL]
    q).log4q.snk
    SILENT| ,1
    DEBUG | ,1
    INFO  | 1 1800
    WARN  | ,1
    ERROR | 2 1800
    FATAL | 2 1800
    q)ERROR ("Test %1 log";1222);
    ERROR   [2012.03.01D23:15:22.609375000]:log4q.q: Test 1222 log

    proc (5555)
    -----------
    q)(`msg;"ERROR\t[2012.03.01D23:15:22.609375000]:log4q.q: Test 1222 log\r\n")

/remove sink
    .log4q.remove[1;`DEBUG`INFO] /removes logging to stdout at DEBUG and `INFO severity

q).log4q.add[hopen `:my_test2.log;`INFO`ERROR]
q).log4q.snk
SILENT| ,1
DEBUG | ,1
INFO  | 1 1800
WARN  | ,1
ERROR | 2 1800
FATAL | ,2
q).log4q.remove[1800;`INFO`ERROR]
q).log4q.snk
SILENT| 1
DEBUG | 1
INFO  | 1
WARN  | 1
ERROR | 2
FATAL | 2
q).log4q.add[1800;`INFO`ERROR]
q).log4q.snk
SILENT| ,1
DEBUG | ,1
INFO  | 1 1800
WARN  | ,1
ERROR | 2 1800
FATAL | ,2
