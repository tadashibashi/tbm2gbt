import std/[os, parseopt, strutils]

proc displayHelp*(): void =
    echo ".tbm => .gbt converter usage\n"
    echo "tbm2gbt [-o:modfileOut] [-s:songNum] tbmfile"
    echo "   -o   filename     exported output filepath (default: <inputfile>.mod)"
    echo "   -s   songnumber   zero-indexed (default: 0)"
    echo "   -q                turn off standard console output, errors will still show"
    echo "   -w                watches file input file for changes every second, and auto-exports"
    echo "   -f                open the generated .mod file after converting"
    echo "   -h                show this help dialogue"

type CmdLineArgs* = tuple
    filenameIn: string
    filenameOut: string
    songNumber: int
    startPattern: int
    quiet: bool
    watch: bool
    postOpen: bool

proc getArgs*(): CmdLineArgs =
    var args = initOptParser(commandLineParams())
    var ret: CmdLineArgs
    ret.filenameIn = ""
    ret.filenameOut = ""
    ret.songNumber = 0
    ret.startPattern = 0
    ret.quiet = false
    ret.watch = false
    ret.postOpen = false

    while true:
        args.next()
        case args.kind
        of cmdEnd: break
        of cmdShortOption, cmdLongOption:
            case args.key
            of "o":
                ret.filenameOut = args.val
            of "s":
                ret.songNumber = parseInt(args.val)
            of "p":
                ret.startPattern = parseInt(args.val)
            of "h":
                displayHelp()
            of "q":
                ret.quiet = true
            of "w":
                ret.watch = true
            of "f":
                ret.postOpen = true
        of cmdArgument:
            ret.filenameIn = args.key

    return ret