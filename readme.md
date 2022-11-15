# Trackerboy .mod Converter

Command line tool to convert Trackerboy .tbm to gbt-player .mod files.

## Build
1. Clone this repository
2. Install Nim: https://nim-lang.org/install.html
3. In the root directory of this repository, call:
    `nimble build`
4. Use the built binary to convert your .tbm's via command line

## Usage via command line
`tbm2mod [-o:outfile] [-s:songnum] [-q] file.tbm`

| Flag | Value       | Description |
|------|-------------|-------------|
| -o   | output file | exported output filepath (default: \<inputfile\>.mod) |
| -s   | song number | zero-indexed (default: 0)
| -q   |             | turn off standard console output, errors still show 
| -h   |             | show help dialogue |

### Examples

Export *mysong.tbm*, song 0 to *mysong.mod* in the same directory

> `tbm2mod mysong.tbm`

Export *mysong.tbm*, song 1 to *bin/newname.mod*

> `tbm2mod -o:bin/newname.mod -s:1 mysong.tbm`


## Composing for gbt-player in Trackerboy

### Guidelines
- Copy and use the provided gbt-template.tbm file when beginning a new composition.
- Leave the Trackerboy instruments and waveforms as-is, since they will not sound correctly during playback in gbt-player otherwise.
- Add a tempo (`Fxx`) command at the top of your file.
- Make sure to add a pattern skip effect (`Dxx`) at the end of any pattern with a length of less than 64.
- Noise channel range works on keys C4-B6. In GB Studio 3.0 and higher, you will get a gradient of timbres. However, it is a special version of gbt-player. Every other version of gbt-player will be constricted to 8 particular tones across the keyboard.
- Since gbt-player is a compact driver with a subset of Trackerboy's effects catalogue, we've attached a list of compatible effects below.
- You can only use one column of effects, others will be ignored.

### Compatible Effects
| Channel Effect  | Trackerboy Command | |
| --------------- | ------- | ------- |
| Arpeggio        | **0**xy | `x` - 1st note, `y` - 2nd note |
| Pitch up-slide  | **1**xx | `xx` - speed to slide upward (pitch units per frame)
| Pitch down-slide| **2**xx | `xx` - speed to slide downward (pitch units per frame)
| Volume Envelope | **E**xy | `x` - starting volume (0-F), `y` - envelope (0,8: none, 1-7: decay, 9-F: ramp to full volume). For CH3, use **V**0x |
| Panning         | **I**0x | `x` - sets pan (1: left, 2: right, 3: center)
| Delayed Note-cut| **S**0x | `x` - number of frames until note cut
| Channel Timbre  | **V**0x | `x` - volume setting for CH3 only (0-3)

| Song Effect     | Trackerboy Command | |
| --------------- | ------- | ------- |
| Pattern Jump    | **B**xx | `xx` - pattern to jump to
| Pattern Skip    | **D**xx | `xx` - row in next pattern to skip to
| Set speed       | **F**xx | `xx` - tempo of the song (1: fast - 1F: slow)


### Incompatible Effects
| Effect  | Trackerboy Command |
| --------------- | ------- |
| Automatic Port  | **3**xy |
| Square Vibrato  | **4**xy |
| Vibrato Delay   | **5**xx |
| Pattern Halt    | **C**00 |
| Note Delay      | **G**xx |
| Sweep Register  | **H**xx |
| Global Volume   | **J**xy |
| Lock Channel    | **L**00 |
| Fine Tuning     | **P**xx |
| Note Slide-up   | **Q**xy |
| Note Slide-down | **R**xy |
| Play SFX        | **T**xx |

### Effect Compatibility Notes
- Envelope effect (`Exy`) must always be accompanied by a note when set. On the other hand, it's okay to write notes without an envelope effect. It will maintain the last envelope effect that was called on the channel. One case where this can easily cause a user error is: setting `E00`, expecting to cut off a note. Instead, it is better to write a note cut note (long dash) or effect (`S00`)

- Note cuts, which appear in Trackerboy as a long dash, are interpreted by this converter as a note cut effect. Therefore, please do not write any effect in the same row as such, as it will be ignored

- Timbre effect (`Vxx`), for our purposes is exclusive to wave CH3 (which actually sets its volume, not timbre). For changing timbre/waveforms in CH3, please do not use Trackerboy's `Exx` command. Instead, use the wave instruments provided by the gbt template file. This is the same for timbral changes in 1, 2, & 4 – please use the appropriate instrument provided in the gbt template file, as `Vxx` will be ignored in channels 1, 2, & 4.

- Auto-vibrato (`4xy`) is not supported in GBT-player. Due to this limitation, you'll need to use pitch up-slide (`1xx`) and pitch down-slide (`2xx`) instead to achieve this manually.

    For example:

        C-5 01 ---
        --- -- 201
        --- -- 101
        --- -- 201
        --- -- 101
        --- -- 100

- Pitch slides up (`1xx`) and down (`2xx`) get cancelled out to zero in gbt-player after the row is finished, but in Trackerboy they stick. For this reason, we recommend to use a second effect column to write `100` to stop the slide effect in Trackerboy.

    In the last example, since `100` is redundant in gbt-player, let's move it over to column 2 make room for another effect in column 1. (Click on the `+` icon at the top of the channel to reveal another effect row):
        C-5 01 --- ---
        --- -- 201 ---
        --- -- 101 ---
        --- -- 201 ---
        --- -- 101 ---
        G-5 01 E20 100


Please check out [Trackerboy's Effect List](https://www.trackerboy.org/manual/tracker/effect-list/) and [GB Studio's GBT Music docs](https://www.gbstudio.dev/docs/assets/music/music-gbt) for further info.

## Future Ideas
- Auto-vibrato (add pitch up and down slides automatically)

## Last Remarks
- This converter is under development, so you may need to significantly edit the exported .mod file to produce the intended effect.
- Exporting with this tool overwrites the target file, so please be careful to not overwrite any important direct edits to the mod file you have made. It would be wise to save backup copies of any important work.
