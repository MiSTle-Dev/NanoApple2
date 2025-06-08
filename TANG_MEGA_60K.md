# Tang Mega 60K NEO

the core can be used in the [Tang Mega 60K NEO](https://wiki.sipeed.com/hardware/en/tang/tang-mega-60k/mega-60k.html).

Besides the significantly bigger FPGA over the Tang Nano 20K, the Tang Mega 60K adds several more features of
which some can be used in the area of retro computing as well. 

Although the Tang Mega 60K comes with a significant ammount of
DDR3-SDRAM, it also comes with a slot for the [Tang
SDRAM](https://wiki.sipeed.com/hardware/en/tang/tang-PMOD/FPGA_PMOD.html#TANG_SDRAM). Using this board allows to use the same SDR-SDRAM memory access methods.<br> 

The M0S required to control the core is to be mounted in the
**right PMOD** close to the HDMI connector with the help of the [M0S PMOD adapter](board/m0s_pmod) or directly (no Adapter) using a [PMOD RP2040-Zero](https://github.com/vossstef/tang_nano_20k_c64/tree/main/board/pizero_pmod/README.md).

Plug the optional Dualshock [DS2x2](https://wiki.sipeed.com/hardware/en/tang/tang-PMOD/FPGA_PMOD.html#PMOD_DS2x2) Interface into the **edge PMOD** slot.<br>

The whole setup will look like this:

![MiSTeryNano on TM60K NEO](./.assets/mega60k.png)

The firmware for the M0S Dock is the [same version as for the Tang
Nano 20K](firmware/misterynano_fw/).

On the software side the setup is very simuilar to the original Tang Nano 20K based solution. The resulting bitstream is flashed to the TM60K as usual needing latest Gowin Programmer GUI.


**HW modification**  
[Tang SDRAM Module](https://wiki.sipeed.com/hardware/en/tang/tang-PMOD/FPGA_PMOD.html#TANG_SDRAM) V1.2 modification to fit on the TM60k NEO dock.<br>
The capacitors are a bit too lange and touching the 60k FPGA plug-module.  
Use duct tape to cover the capacitors avoiding shortcuts or unsolder three that are blocking.  
There is a also newer Version 1.3 of the TANG_SDRAM available (90° angle) that likely fit. 
![parts](./.assets/sdram_mod.png)

> [!IMPORTANT]
> To enable the LCD Interface the tiny jumper J17 (near Button Key1 ) need to be plugged to position 1 + 2.

![setup](\.assets/tm60k_lcd.png)