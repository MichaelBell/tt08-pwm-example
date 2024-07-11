<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

The project reads PCM unsigned 8-bit audio data from flash and plays it as PWM output.

## How to test

Create a raw 8-bit, 48kHz audio file with:

    ffmpeg -i your_music.mp3 -f u8 -ar 48000 -ac 1 pcm.raw

Load that on to the flash at address 0.  This can be done using a Micropython script on the RP2040 on the Tiny Tapeout demo board while the design is in reset.

Start the design and listen to your music!

It may be wise to clear the rest of the flash to avoid hearing random noise when your audio file ends.

## External hardware

Tiny Tapeout [Audio Pmod](https://github.com/MichaelBell/tt-audio-pmod) with a [QSPI Pmod](https://github.com/mole99/qspi-pmod) plugged into it.
