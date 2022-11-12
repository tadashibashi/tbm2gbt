# Trackerboy .mod Exporter

*Command line tool to convert Trackerboy .tbm files to gbt-player compatible .mod files
Compatible with GB Studio 2 and 3*

## Build

1. Clone this module recursively, using --recurse-submodules
2. Install Nim: https://nim-lang.org/install.html
3. In the root directory of this repository, call:
    `nim compile -d:release tbm2mod.nim`

## Usage from the command line

`tbm2mod [-o:modfileOut] [-s:songNum] [-q] tbmfile`

| Flag | Value       | Description |
|------|-------------|-------------|
| -o   | output file | exported output filepath (default: \<inputfile\>.mod) |
| -s   | song number | zero-indexed (default: 0)
| -q   |             | turn off standard console output, errors still show 
|-h    |             | show this help dialogue |

### Examples

Export "mysong.tbm", song 0 to "mysong.mod" in the same directory

> `tbm2mod mysong.tbm`

Export "mysong.tbm", song 1 to "bin/changedname.mod"

> `tbm2mod -o:bin/changedname.mod -s:1 mysong.tbm`


## Composing for gbt-player in Trackerboy
---

### Guidelines
- Copy and use the provided gbt-template.tbm file when beginning a new composition.
- Leave the Trackerboy instruments and waveforms as-is, since they will not sound correctly during playback in gbt-player otherwise.
- Add a tempo (`Fxx`) command at the top of your file.
- Make sure to add a pattern skip effect (`Dxx`) at the end of any module with a pattern length less than 64.
- Since gbt-player is a compact driver with a subset of Trackerboy's effects catalogue, we've attached a list of compatible effects below.

### Compatible Effects
| Channel Effect  | Trackerboy Command | |
| --------------- | ------- | ------- |
| Arpeggio        | **0**xy | `x` - 1st note, `y` - 2nd note |
| Pitch up-slide  | **1**xx | `xx` - speed to slide upward (pitch units per frame)
| Pitch down-slide| **2**xx | `xx` - speed to slide downward (pitch units per frame)
| Volume Envelope | **E**xy | `x` - starting volume (0-F), `y` - envelope (0,8: none, 1-7: decay, 9-F: ramp to full volume) |
| Panning         | **I**0x | `x` - sets pan (1: left, 2: right, 3: center)
| Delayed Note-cut| **S**0x | `x` - number of frames until note cut
| Channel Timbre  | **V**0x | `x` - volume setting for CH3 only

| Song Effect  | Trackerboy Command | |
| --------------- | ------- | ------- |
| Pattern Jump    | **B**xx | `xx` - pattern to jump to
| Pattern Skip    | **D**xx | `xx` - row in next pattern to skip to
| Set speed       | **F**xx | `xx` - tempo of the song (1: fast - 1F: slow)


### Incompatible Effects
| Effect  | Trackerboy Command |
| --------------- | ------- |
| Automatic Port  | **3**xy |
| Square Vibrato  | **4**xx |
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

### Important Effect Compatibility Notes
- Note cuts, which appear in Trackerboy as a long dash in the note column, are interpreted by the exporter as an instant note cut effect. Therefore, please do not use an effect in the same row as such, as it will be ignored

- Timbre effect (**V**0x), for our purposes is exclusive to wave CH3, which actually sets its volume (not timbre/wave). For timbral changes in channels 1, 2, & 4, please use the appropriate instrument provided in the gbt template file, as **V**0x will be ignored in these channels.
Regarding timbre/waveforms in CH3, please do not use **E**xx. Instead, use the wave instruments provided by the gbt template file.

- Vibrato (**4**xy) is not supported in GBT-player. Due to this limitation, you'll need to use pitch up-slide (**1**xx) and pitch down-slide (**2**xx) instead to achieve this manually.

    For example:

        C-5 01 ---
        --- -- 201
        --- -- 101
        --- -- 201
        --- -- 101

Please check out [GB Studio's music docs](https://www.gbstudio.dev/docs/assets/music/music-gbt) for further info.

## Future Ideas
- Auto vibrato (add pitch up and down slides automatically)

## Last Remarks

- This converter is under development, so you may need to significantly edit the exported .mod file to produce the intended effect.
- Exporting with this tool overwrites the target file, so please be careful to not overwrite any important direct edits to the mod file you have made. It would be wise to save backup copies of important work.
