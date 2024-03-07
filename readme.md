# Trackerboy to .MOD Converter

Create in [Trackerboy](https://www.trackerboy.org), export to [GB Studio](https://www.gbstudio.dev) .MOD files


## Motivation for this Program

Playback of the template gbt-player .mod file is highly inaccurate in mod editors, especially the noise channel. This exporter attempts to best match the sound heard in TrackerBoy to the sound output in GB Studio's player.

Trackerboy's interface is clean, user-friendly, and familiar to users of FamiTracker.

## Tools Used

![Nim](https://img.shields.io/badge/nim-%23FFE953.svg?style=for-the-badge&logo=nim&logoColor=white)


## Build
1. Clone this repository
2. Install Nim: https://nim-lang.org/install.html
3. In the root directory of this repository, call: `nimble build`
4. Use the built binary to convert your .tbm's via command line

## Usage via command line
`tbm2mod [-o:outfile] [-s:songnum] [-q] file.tbm`

| Flag | Value       | Description |
|------|-------------|-------------|
| -o   | output file | exported output filepath (default: \<inputfile\>.mod) |
| -s   | song number | zero-indexed (default: 0)
| -q   |             | turn off standard console output, errors still show
| -h   |             | show help dialogue |

### Example usage

##### Export `mysong.tbm`, song 0 to `mysong.mod` in the same directory.

> `tbm2mod mysong.tbm`

Note: omitting an output filename exports a file with the same name to the same directory as the input, but with the `.mod` extension

##### Export *mysong.tbm*, song 1 to *bin/newname.mod*

> `tbm2mod -o:bin/newname.mod -s:1 mysong.tbm`


## Composing for GB Studio in Trackerboy

This program uses a subset of Trackerboy's features to match GB Studio's player,
so the following guidelines should be followed.

### Guidelines
- Copy and use the provided gbt-template.tbm file when beginning a new composition.
- Leave the Trackerboy instruments and waveforms as-is, since they will not sound correctly during playback in gbt-player otherwise.
- Add a tempo (`Fxx`) command at the top of your file.
- Make sure to add a pattern skip effect (`Dxx`) at the end of any pattern with a length of less than 64.
- Noise channel range works on keys C4-B6. In GB Studio 3.0 and higher, you will get a gradient of timbres, otherwise the keyboard is distributed over only 8 tones.
- GB Studio's player can only process one column of effects, others besides the first column may sound in Trackerboy, but will be ignored in the exported file.

### Compatible Effects
| Channel Effect  | Trackerboy Command | |
| --------------- | ------- | ------- |
| Arpeggio        | **0**xy | `x` - 1st note, `y` - 2nd note |
| Pitch up-slide  | **1**xx | `xx` - speed to slide upward (pitch units per frame)
| Pitch down-slide| **2**xx | `xx` - speed to slide downward (pitch units per frame)
| Volume Envelope | **E**xy | `x` - starting volume (0-F), `y` - envelope (0,8: none, 1-7: decay, 9-F: ramp to full volume). For CH3, use **V**0x |
| Panning         | **I**0x | `x` - sets pan (1: left, 2: right, 3: center)
| Delayed Note-cut| **S**0x | `x` - number of frames until note cut
| Channel Timbre  | **V**0x | `x` - volume setting for **CH3 only** (0-3)

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

- ##### Volume envelope effects (`Exy`) must always be accompanied by a note

    One case where this can cause confusion is setting `E00` expecting a note cutoff. Instead, it is better to write a Trackerboy note cut (long dash that appears in the note column) or effect (`S00`)

- ##### Volume envelope effects (`Exy`) are "sticky"

    While you must accompany an `Exy` with a note, it's okay to write notes without an envelope effect - it will maintain the last envelope effect that was called on that channel.

- ##### Note cuts are effects

    Note cuts in Trackerboy are interpreted as an effect in GB Studio's player.
    Therefore, please do not write any effect in the same row - it will be ignored

- ##### Timbral effects are set by instrument number

    GB Studio uses instrument number presets to accomplish timbral changes.
    For changing timbre/waveforms in channels 1-4, please use the appropriate instrument numbers in the template file instead of using effects. `Vxx`, for our purposes will only be used as the volume setting for CH3, and will be ignored in channels 1, 2, & 4.

- ##### Auto-vibrato (`4xy`) is not supported in GB Studio

    Due to this limitation, you'll need to handcraft pitch up-slide (`1xx`) and pitch down-slide (`2xx`) to achieve this manually.

    For example:

        C-5 01 ---
        --- -- 201
        --- -- 101
        --- -- 201
        --- -- 101
        --- -- 100

    Pitch slides up (`1xx`) and down (`2xx`) get cancelled out to zero in GB Studio after the row is finished, but in Trackerboy they stick. For this reason, we recommend to use a second effect column to write `100` to stop the slide effect cosmetically in Trackerboy.

    In the last example, since writing `100` is redundant for GB Studio, let's move it over to column 2 make room for another effect in column 1. (Click on the `+` icon at the top of the channel column in Trackerboy to reveal another effect row):

        C-5 01 --- ---
        --- -- 201 ---
        --- -- 101 ---
        --- -- 201 ---
        --- -- 101 ---
        G-5 01 E20 100


For further reading, please check out [Trackerboy's Effect List](https://www.trackerboy.org/manual/tracker/effect-list/) and [GB Studio GBT Music docs](https://www.gbstudio.dev/docs/assets/music/music-gbt)

## Future Ideas
- Auto-vibrato (add pitch up and down slides automatically)

## Last Remarks

- Exporting with this tool overwrites the target file - please save backups of any direct edits you wish to keep at the export location before running the program.
- This converter targets the [GB Studio music player](https://github.com/tadashibashi/gbstudio-mod-example), which is based on a fork of gbt-player, and will not play back accurately using a build from gbt-player's main branch.
- For bug reports, please create a Github Issue.
