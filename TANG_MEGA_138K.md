# Tang Mega 138K Pro

NanoApple2 can be used in the [Tang Mega 138K Pro](https://wiki.sipeed.com/hardware/en/tang/tang-mega-138k/mega-138k-pro.html).

The Tang Mega 138K Pro is bigger than the other bords supported my
MiSTeryNano. Unlike the Tang Nano 20K which is actually slightly
inferior to the original [MiST](https://github.com/mist-devel/mist-board/wiki), the Tang Mega 138K is even slightly
more powerful than the MiST's successor [MiSTer](https://mister-devel.github.io/MkDocs_MiSTer/).

Besides the significantly bigger FPGA over the Tang Nano 20K the Tang Mega 138K adds several more features of
which some can be used in the area of retro computing as well. 

Although the Tang Mega 138K Pro comes with a significant ammount of
DDR3-SDRAM, it also comes with a slot for the [Tang
SDRAM](https://wiki.sipeed.com/hardware/en/tang/tang-PMOD/FPGA_PMOD.html#TANG_SDRAM). Using this board allows to use the same SDR-SDRAM memory access
methods. DDR3 on the other hand is not supported by regular retro
implementations like the MiSTeryNano.

Plug the optional Dualshock [DS2x2](https://wiki.sipeed.com/hardware/en/tang/tang-PMOD/FPGA_PMOD.html#PMOD_DS2x2) Interface into the **left PMOD** slot.<br>

The M0S required to control the C64 Nano is to be mounted in the
**middle PMOD** with the help of the [M0S PMOD adapter](board/m0s_pmod) or directly (no Adapter) using a [PMOD RP2040-Zero](https://github.com/vossstef/tang_nano_20k_c64/tree/main/board/pizero_pmod/README.md).

The whole setup will look like this:

![MiSTeryNano on TM138K Pro](./.assets/ds2_m0s_pmod_tm138kpro.png)
![tm138k](\.assets/tm138k_lcd.png)
