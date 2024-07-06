<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

The project generates a PWM output approximating a sine wave of configurable frequency.

The tone generated is of frequency `project clock / (256 * (divider + 1))`

## How to test

Set {in[7:0], uio[3:0]} to the desired divider:

- A divider of 443 {0001 1011, 1011} should give approximately 440Hz
- A divider of 747 {0010 1110, 1011} should give approximately middle C

## External hardware

Tiny Tapeout [Audio Pmod](https://github.com/MichaelBell/tt-audio-pmod)
