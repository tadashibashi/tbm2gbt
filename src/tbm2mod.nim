import cmdline
import gbtmod
import libtrackerboy/data
import std/strutils

# Get command line arguments
var 
    filenameIn = ""
    filenameOut = ""
    songNumber = 0
    patternNumber = 0
    quiet = false
getArgs(filenameIn, filenameOut, songNumber, patternNumber, quiet)

# Check arguments
if filenameIn == "":
    echo "Error: no input file to convert."
    displayHelp()
    quit(1)

# If no output filename, use input name
if filenameOut == "":
    filenameOut = filenameIn
    removeSuffix(filenameOut, ".tbm")
    filenameOut &= ".mod"

# Open trackerboy module file
let module = openModule(filenameIn)

# Check module against args for errors
if module == nil:
    quit(1)
if module.songs.len <= songNumber:
    echo "Error: Song " & $(songNumber) & " is out of range!"
    quit(2)
let song = module.songs[songNumber]
if patternNumber >= song.order.len:
    echo "Error: pattern number exceeds the song's order length."
    quit(3)

# Export display
if not quiet:
    echo "------------------------------------------------"
    echo " Trackerboy .mod Exporter (gbt-player v4.0.5)\n"
    echo " Input file :  " & filenameIn 
    echo " Output file:  " & filenameOut
    echo "\n Trackerboy Module"
    echo "     title    : " & module.title.toString()
    echo "     artist   : " & module.artist.toString()
    echo "     copyright: " & module.copyright.toString()
    echo " Song #" & $(songNumber)
    echo "     name     : " & song.name.toString()
    echo "     length   : " & $(song.order.len()) & " pattern" & 
        (if song.order.len() > 1: "s" else: "")
    echo "     speed    : " & $(int(float(song.speed) / 16f))
    echo "  "
    echo "------------------------------------------------\n"

# Do conversion and file write
writeMod(song, patternNumber, filenameOut)


if not quiet:
    # Display any caveats or problems from conversion here

    # Warn user if more than 1 effect columns on any channel
    for ch in countup(0, 3):
        if song.effectCounts[ch] > 1:
            echo "Warning: CH" & $(ch + 1) & " has more than one effect column. " &
                "Effects on columns beyond the first are ignored."
    
    # :)
    echo "Conversion complete!"

