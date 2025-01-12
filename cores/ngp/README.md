# NeoGeo Pocket Compatible FPGA core by Jotego

Please support the project
* Patreon: https://patreon.com/jotego
* Paypal: https://paypal.me/topapate

# System Details

| unit    | memory (kB) | remarks        |
|:--------|:------------|:---------------|
| T800H   | 12+4        | upper 4 shared |
| Z80     |  4          | shared         |
| Fix     |  8          |                |
| Scroll  |  4          | 2kB per layer  |
| Objects |   .25       |                |
| Total   | 32          |                |

- Is the video chip connection to the data bus 16 or 8 bits?
- Palette RAM is 16-bit access only and has no wait states

Because of the awkward video timing, the system needs some sort of buffer to output analog video. It is not clear whether it can be done with the amount of BRAM available in MiST/SiDi. That's why the core only targets MiSTer and Pocket right now.

# Key Mapping

- A, B buttons are mapped to the first two buttons in the gamepad
- Start button is mapped to _1P_ (keyboard key `1` or gamepad _select_)
- Power button is mapped to _coin_ (keyboard key `5` or gamepad _start_)

# Cartridge Loading

The first time you insert batteries into a NGP, the system will boot and present a menu. You can go through the set-up process or not. What matters is that when you press the power button in the actual machine, it will suspend the system but keep the memory alive. When you press the power button again, if there is a cartridge, it will not show the setup menu. The core needs the user to replicate this procedure in order to play games.

1. Load the core
2. Use the virtual power button to _turn off_ the NGP
3. Load the cartridge through the OSD menu

If you want to load a new game while the core is working, go directly to step 2.

# Simulation & Debugging

In order to simulate with a cartridge, this has to be named `cart.bin`. The firmware should be called `rom.bin`. Check out [JTFRAME documentation](../../modules/jtframe/doc/sdram.md)

The system can reset from two locations:

- FF1DE8 		reset vector interrupt
- FF1800		power-button interrupt

See more simulation setup notes [here](ver/game/README.md).

## MiSTer

MiSTer scaler automatically handles the awkward video format. This means that the core will only work via HDMI. MiSTer's analog output may work if it is configured to output the scaler video. Compiling the sound CPU is most likely needed for the system to work correctly. All this means that you need to run full compilations for all tests: `jtcore ngp -mr`

The analog video output will not work without a frame buffer because the line period is 83.82us, very far from the typical 64us required. If the system was ignorant of the video output, it would be possible to output at a different rate but the CPU has access to the video circuitry internals and knows at which point of the line the graphics hardware is working. Therefore, only HDMI output is supported.

## MAME

Supply the cartridge name with `-cart`. It is possible to boot with no cartridge too.

`mame ngp -cart cartridge.ngp`

F1 serves as the power button. You probably need to press F1 if the emulator shows a blank screen on start up.

MAME may save the main CPU RAM (12kB) to `~/.mame/nvram/ngp`. Then it will boot from it the next time MAME is run. When it boots from NVRAM, it starts at a different PC address (PC=FF1800). This skips the configuration screen and tries to emulate the standby mode of the original hardware.

You may have NVRAM savings enabled by default, which can make the boot process confusing. Disable it in the `~/.mame/mame.ini` by setting `nvram_save 0`. If you want to save the NVRAM at some point, call MAME with `-nvram_save` and press F1 to power off the device. Then quit MAME and a valid NVRAM should have been generated at `~/.mame/nvram`.

# Cartridge

Manufacturer ID 0x98

Size (kB) | Device ID | Chip count
----------|-----------|-----------
32~512    |   0xAB    |    1
1024      |   0x2C    |    1
2048      |   0x2F    |    1
4096      |   0x2F    |    2

## NGP Compatible Games

According to MAME:

**Purely monochrome**
| Short name | full name                                                                |
|:-----------|:-------------------------------------------------------------------------|
| kofr1      | Pocket Fighting Series - King of Fighters R-1 (Euro, Jpn)                |
| kof_mlon   | King of Fighters R-1 & Melon-chan no Seichou Nikki (Jpn, Prototype)      |
| samsho     | Pocket Fighting Series - Samurai Spirit! (Jpn) ~ Samurai Shodown! (Euro) |
| shougi     | Shougi no Tatsujin (Jpn)                                                 |
| neocup98   | Pocket Sports Series - Neo Geo Cup '98 (Euro, Jpn)                       |
| neocher    | Pocket Casino Series - Neo Cherry Master (Euro, Jpn)                     |
| melonchn   | Melon-chan no Seichou Nikki (Jpn)                                        |
| tsunapn    | Renketsu Puzzle Tsunagete Pon! (Jpn)                                     |
| bstars     | Pocket Sports Series - Baseball Stars (Euro, Jpn)                        |
| ptennis    | Pocket Sports Series - Pocket Tennis (Euro, Jpn)                         |

**Compatible color games**

| Short name | full name                                                   |
|:-----------|:------------------------------------------------------------|
| snkgalsj   | SNK Gals' Fighters (Jpn)                                    |
| kofr2      | Pocket Fighting Series - King of Fighters R-2 (World)       |
| rockmanb   | Rockman - Battle & Fighters (Jpn)                           |
| bigbang    | Big Bang Pro Wrestling (Jpn)                                |
| divealrmj  | Dive Alert - Barn Hen (Jpn)                                 |
| memories   | Memories Off - Pure (Jpn)                                   |
| rockmanbd  | Rockman - Battle & Fighters (Jpn, Demo)                     |
| samsho2    | Pocket Fighting Series - Samurai Shodown! 2 (World)         |
| svccardp   | SNK vs. Capcom - Gekitotsu Card Fighters (Jpn, Demo)        |
| kofpara    | The King of Fighters - Battle de Paradise (Jpn)             |
| dynaslug   | Dynamite Slugger (Euro, Jpn)                                |
| pachinko   | Pachinko Hisshou Guide - Pocket Parlor (Jpn)                |
| kofr2d     | Pocket Fighting Series - King of Fighters R-2 (World, Demo) |
| magdropj   | Magical Drop Pocket (Jpn)                                   |
| cotton     | Fantastic Night Dreams Cotton (Euro)                        |
| infinity   | Infinity Cure (Jpn)                                         |

# Contact

* https://twitter.com/topapate
* https://twitter.com/jotegojp
* https://github.com/jotego/jtcores/issues

# Thanks to December 2023 Patrons
