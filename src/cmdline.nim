import std/[os, parseopt, strutils]

proc displayHelp*(): void =
    echo ".tbm => .gbt converter usage\n"
    echo "tbm2gbt [-o:modfileOut] [-s:songNum] tbmfile"
    echo "   -o   filename     exported output filepath (default: <inputfile>.mod)"
    echo "   -s   songnumber   zero-indexed (default: 0)"
    echo "   -q                turn off standard console output, errors will still show"
    echo "   -w                watches file input file for changes every second, and auto-exports"
    echo "   -h                show this help dialogue"

proc getArgs*(filenameIn: var string, filenameOut: var string, 
    songNumber: var int, patternNumber: var int, quiet: var bool, watch: var bool): void =
    var args = initOptParser(commandLineParams())

    filenameIn = ""
    filenameOut = ""
    songNumber = 0
    patternNumber = 0
    quiet = false
    watch = false

    while true:
        args.next()
        case args.kind
        of cmdEnd: break
        of cmdShortOption, cmdLongOption:
            case args.key
            of "o":
                filenameOut = args.val
            of "s":
                songNumber = parseInt(args.val)
            of "p":
                patternNumber = parseInt(args.val)
            of "h":
                displayHelp()
            of "q":
                quiet = true
            of "w":
                watch = true
        of cmdArgument:
            filenameIn = args.key