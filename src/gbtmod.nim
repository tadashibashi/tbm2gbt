import libtrackerboy/[data, io, common, notes]
import std/[bitops, endians, math, os, streams]

# ----- Noise Period Calculation -----------------------------------
let gbtNoise8veDivs: array[4, uint8] = [0u8, 3u8, 6u8, 10u8]
let gbtPeriodNoiseAsTrackerboyMidi: array[8, uint8] = [32u8, 37u8, 42u8, 44u8, 45u8, 47u8, 48u8, 52u8]
let gbtWhiteNoiseAsTrackerboyMidi: array[8, uint8] = [31u8, 35u8, 39u8, 47u8, 55u8, 28u8, 33u8, 37u8]

type NoiseType = enum sevenBit, fifteenBit

# Returns the difference of the closest trackerboy midi value that gbt player uses
proc noiseClosest(noiseType: NoiseType, midi: uint8, outMidi: var uint8, outIndex: var uint8): int =
    var midi = midi
    var lowest: int = 1000000
    var lowestIndex: int = -1
    midi = (if noiseType == NoiseType.fifteenBit: 
        midi - 1 
    else:
        midi - 3)

    for i in countup(0, 7):
        var diff = int(midi) - (if noiseType == NoiseType.sevenBit: 
                int(gbtPeriodNoiseAsTrackerboyMidi[i]) 
            else: 
                int(gbtWhiteNoiseAsTrackerboyMidi[i])) 
        if abs(diff) < abs(lowest):
            lowest = diff
            lowestIndex = i
            if diff == 0: # numbers match, number found
                break

    outMidi = (if noiseType == NoiseType.sevenBit: gbtPeriodNoiseAsTrackerboyMidi[lowestIndex] 
        else: gbtWhiteNoiseAsTrackerboyMidi[lowestIndex])
    outIndex = uint8(lowestIndex)  
    return lowest

# ----- Tone Period Calculation ------------------------------------
proc noiseMidiToGbtMidi(noiseType: NoiseType, midi: uint8, outInst: var uint8): uint8 =
    var newMidi: uint8
    var index: uint8
    const middleC = 24
    var diff = noiseClosest(noiseType, midi, newMidi, index)
    var octave = int floor(float(diff)/4f) + 2
    var noteOffset = gbtNoise8veDivs[(diff + middleC) mod 4]

    let retMidi = uint8(octave) * 12u8 + noteOffset + 1

    # Get instrument number
    if noiseType == NoiseType.sevenBit:
        outInst = index + 16
    else:
        outInst = index + 24
    return retMidi

func midiToHertz(midi: uint8): float =
    return 440.0 * math.pow(2.0, ((float(midi + 2) + 24)/12.0)) # midi + 2 is a magic number...

# TODO: Use a lookup table instead of calculating every note?
func midiToModPeriod(midi: uint8): int =
    const c = 7159090.5 # NTSC
    # const c = 7093789.2 # PAL
    let period = c/(2.0 * midiToHertz(midi))
    return int(math.round(period))


# ----- Effects --------------------------------------------------
# Translates a Trackerboy effect to a GBT .mod effect
func tbToGbtEffect(ch: uint8, effect: Effect): uint16 =
    var fx: uint8 = 0
    var param: uint8 = 0

    case EffectType effect.effectType
        of etNoEffect: return 0
        of etArpeggio:
            # fx = 0
            param = effect.param
        of etSetEnvelope:
            fx = 9u8
            param = effect.param
        of etPatternSkip:
            fx = 0xD
            param = effect.param
        of etPatternGoto:
            fx = 0xB
            param = effect.param
        of etDelayedCut:
            fx = 0xE
            param = effect.param + 0xC
        of etSetPanning:
            fx = 0xE
            param = (case effect.param
                of 1u8: 0'u8
                of 2u8: 0xF'u8
                of 3u8: 8'u8
                else: 8'u8) + 0x80
        of etSetTempo:
            fx = 0xF
            param = rotateRightBits(effect.param, 4)
        of etPitchUp:
            fx = 0x1
            param = effect.param
        of etPitchDown:
            fx = 0x2
            param = effect.param
        of etSetTimbre:
            if ch == 2: # V commands effect wave ch volume in Trackerboy
                fx = 0xC
                param = effect.param * 0x10
        else: 
            return 0
    return rotateLeftBits(uint16(fx), 8) + param


# ----- Module ---------------------------------------------
func toString*(infoStr: InfoString): string =
    var res = newString(infoStr.len())
    copyMem(res[0].unsafeAddr, infoStr[0].unsafeAddr, infoStr.len())
    return res

# Opens and returns a Trackerboy module. Returns nil if there was a problem
proc openModule*(path: string): ref Module =
    let moduleBinary = readFile(path)
    var strm = newStringStream()
    strm.write(moduleBinary)
    strm.setPosition(0)

    var module = Module.new
    let res = module[].deserialize(strm)
    if res != frNone:
        echo "Error: failed to deserialize trackerboy module!"
        return nil
    return module

proc getPatternData(song: ref Song, ch: ChannelId, order: int): array[64, TrackRow] =
    var rows: array[64, TrackRow]
    
    for i in countup(0, song[].patternLen(order)-1):
        var row = song[].getRow(ch, song.order[order][ch], i)
        rows[i] = row
    return rows

# Converts song data into gbt player compatible .mod format, starting at patternNumber
proc writeMod*(song: ref Song, patternNumber: int, filenameOut: string): void =
    if patternNumber >= song.order.len:
        return
    

    var strm = newStringStream()
    
    # write template base
    let bin = readFile(os.getAppDir() & "/data/base.bin")
    strm.write(bin)

    # alter the module name
    var name: array[20, char]
    copyMem(name[0].addr, song.name[0].unsafeAddr, min(song.name.len, 20))
    copyMem(strm.data[0].unsafeAddr, name[0].unsafeAddr, 20)

    # alter the length data
    strm.data[950] = char(song.order.len)
    
    for i in countup(patternNumber, song.order.len-1):
        # write in sequence indices
        strm.data[952 + i] = char(i)

        # grab pattern data
        var patterns: array[4, array[64, TrackRow]]
        for channel in countup(0, 3):
            patterns[channel] = getPatternData(song, ChannelId(channel), i)
        # write data in each row (currently only note)
        for row in countup(0, 63):
            for channel in countup(0, 3):
                if song[].trackLen <= row:
                    strm.write("\0\0\0\0") # some nicer way to do this?
                    continue
                
                var 
                    data1: uint16 = 0
                    data2: uint16 = 0
                let 
                    trackRow = song[].getRow(ChannelId(channel), 
                        song[].order[i][ChannelId(channel)], row)
                
                # write the note with upper instrument bits
                if not trackRow.isEmpty():
                    var bytes1and2: uint16 = 0
                    var bytes3and4: uint16 = 0
                    var period: uint16 = 0
                    var instrument: uint8 = 1
                    var effect: uint16 = 
                        (if trackRow.note >= notes.noteCut:
                                0xEC0'u16
        
                            else: 
                                tbToGbtEffect(uint8 channel, trackRow.effects[0]))

                    if channel != 3:  # ch1, ch2, ch3
                        if not (trackRow.note >= notes.noteCut) and trackRow.note != 0:
                            period = uint16(midiToModPeriod(trackRow.note))
                            instrument = trackRow.instrument
                            
                    else:             # noise channel
                        let noiseType: NoiseType = (if trackRow.instrument == 0x11 + 1:
                            NoiseType.sevenBit else: NoiseType.fifteenBit)
                        period = uint16(midiToModPeriod(
                            noiseMidiToGbtMidi(noiseType, trackRow.note, instrument)))
                        if trackRow.note >= notes.noteCut or trackRow.note == 0:
                            instrument = 1

                    # write data into the correct bits
                    var 
                        instUpper = bitand(instrument-1, 0b11110000)
                        instLower = bitand(instrument-1, 0b00001111)
                    bytes1and2 += rotateLeftBits(uint16(instUpper), 8)
                    bytes1and2 += period
                    bytes3and4 += rotateLeftBits(uint16(instLower), 12)
                    bytes3and4 += effect
                    bigEndian16(addr(data1), addr(bytes1and2)) # ensure correct byte order
                    bigEndian16(addr(data2), addr(bytes3and4)) # ensure correct byte order
                
                strm.writeData(data1.unsafeAddr, 2)
                strm.writeData(data2.unsafeAddr, 2)

    # append sample data (for playback in mod players)
    let inst = readFile(os.getAppDir() & "/data/inst.bin")
    strm.write(inst)

    system.writeFile(filenameOut, strm.data)

# ----- Debugging -----------------------------------------------

# Debug print pattern data
proc printPatternData*(song: ref Song, ch: ChannelId, order: int): void =
    let pattern = getPatternData(song, ch, order)

    for row in pattern:
        if row.isEmpty():
            echo "---------"
        else:
            var str = "N" & $(row.note) & ", I" & 
                $(row.instrument) & ", FX: "
            for effect in row.effects:
                str &= $(effect.effectType) & " " & 
                    $(effect.param) & " - "
            echo str

# Debug print a particular channel's data for entire song
proc printSongData*(self: ref Module, index: int, ch: ChannelId): void =
    # Get Title
    var title = toString(self.title)
    echo "Title: " & title
    
    #Get Song 1 Pattern 1 Data
    let song = self.songs[0]
    echo "Song 1\n Name: " & song.name

    var speed = song.speed
    echo " Speed: " & $(speed)

    echo " Song track length:   " & $(song[].trackLen)
    echo " Song order length: " & $(song[].order.len)

    echo " ================= "
    for i in countup(0, song.order.len-1):
        printPatternData(song, ch, i)
        echo " ----- end pattern -----"