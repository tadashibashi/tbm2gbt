import cmdline
import gbtmod
import libtrackerboy/data
import std/[strutils, os, times, distros]
import fsnotify

# Command line program object type
type Tbm2Mod {.requiresInit.} = object
    args: CmdLineArgs
    baseData: string
    instData: string


proc init(T: type Tbm2Mod): T =
    var args = getArgs()

    # Check arguments
    if args.filenameIn == "":
        echo "Error: no input file to convert."
        displayHelp()
        quit(1)

    # If no output filename, use input name
    if args.filenameOut == "":
        args.filenameOut = args.filenameIn
        removeSuffix(args.filenameOut, ".tbm")
        args.filenameOut &= ".mod"

    return T(
        args: args,
        baseData: readFile(os.getAppDir() & "/data/base.bin"),
        instData: readFile(os.getAppDir() & "/data/inst.bin")
    )


proc main(self: Tbm2Mod, firstRun: bool = false) =
    var startTime = times.getTime()
    var args = self.args

    # Open trackerboy module file
    let module = openModule(args.filenameIn)
    # Check module against args for errors
    if module == nil:
        quit(1)
    if module.songs.len <= args.songNumber:
        echo "Error: Song " & $(args.songNumber) & " is out of range!"
        quit(2)
    let song = module.songs[args.songNumber]
    if args.startPattern >= song.order.len:
        echo "Error: pattern number exceeds the song's order length."
        quit(3)

    if firstRun:

         # Export display
        if not args.quiet:
            echo "------------------------------------------------"
            echo " Trackerboy .mod Exporter (gbt-player v4.0.5)\n"
            echo " Input file :  " & args.filenameIn
            echo " Output file:  " & args.filenameOut
            echo "\n Trackerboy Module"
            echo "     title    : " & module.title.toString()
            echo "     artist   : " & module.artist.toString()
            echo "     copyright: " & module.copyright.toString()
            echo " Song #" & $(args.songNumber)
            echo "     name     : " & song.name.toString()
            echo "     length   : " & $(song.order.len()) & " pattern" &
                (if song.order.len() > 1: "s" else: "")
            echo "     speed    : " & $(int(float(song.speed) / 16f))
            echo "  "
            echo "------------------------------------------------\n"

    # Do conversion and file write
    writeMod(song, args.startPattern, args.filenameOut, self.baseData, self.instData)

    if not args.quiet:
        # Display any caveats or problems from conversion here

        # Warn user if more than 1 effect columns on any channel
        for ch in countup(0, 3):
            if song.effectCounts[ch] > 1:
                echo "Warning: CH" & $(ch + 1) & " has more than one effect column. " &
                    "Effects on columns beyond the first are ignored."

        var deltaTime = getTime() - startTime
        echo "Conversion complete! (" & $(deltaTime.inMilliseconds) & "ms)"

    # Open .mod in default app
    if args.postOpen:
        var result = 0
        if distros.detectOs(MacOSX):
            result = os.execShellCmd("open \"" & args.filenameOut & "\"")
        elif distros.detectOs(Linux):
            result = os.execShellCmd("xdg-open \"" & args.filenameOut & "\"")
        elif distros.detectOs(Windows):
            result = os.execShellCmd("start \"" & args.filenameOut & "\"")
        else:
            echo "Error: could not open .mod file because your OS is not supported."
        if result != 0:
            echo "Error: failed to open .mod file with error code: \n" & $(result)


proc watcherEventHandler(self: Tbm2Mod, event: seq[PathEvent]) {.gcsafe.}=
    self.main()
    echo "Watching input file for changes..."


proc exec(self: Tbm2Mod) =
    let args = self.args

    if args.watch:
        if detectOs(MacOSX) or detectOs(Linux) or detectOs(Windows):
            var watcher = initWatcher()

            register(watcher, args.filenameIn, proc (event: seq[PathEvent]) = self.watcherEventHandler(event))
            self.watcherEventHandler(newSeq[PathEvent](0))
            self.main(true)
            while true:
                sleep(500)
                process(watcher)
        else:
            echo "Warning: argument -w ignored because file watcher is " &
                "incompatible with your OS. Supported systems: Windows, MacOS, Linux"
            self.main(true)
    else:
        self.main(true)


let program = Tbm2Mod.init()
program.exec()
