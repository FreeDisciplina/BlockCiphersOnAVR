## Bitsliced Implementations of Lightweight Block Ciphers on AVR 8-bit Microcontrollers

This is a program to implement lightweight block ciphers on AVR 8-bit microcontrollers using bitsliced technique.
Several algorithms have been implemented:

  - [PRINCE](http://eprint.iacr.org/2012/529)
  - [LED](http://eprint.iacr.org/2012/600)
  - [RECTANGLE](http://eprint.iacr.org/2014/084)
  - [SIMON and SPECK](http://eprint.iacr.org/2015/585)
  - [PRIDE](http://eprint.iacr.org/2014/453)
  
All of the implementation are written in assembly code and can be compiled using [Atmel Studio 6.2](http://www.atmel.com/tools/ATMELSTUDIO.aspx). The specific target device is the [AVR ATmega128 8-bit microcontroller](http://www.atmel.com/products/microcontrollers/avr/default.aspx).

For each cipher, we have implementations targeting to at least the two scenarios which are introduced in [2](http://eprint.iacr.org/2015/209).

They have verified the test vectors provided in the cipher specifications.

For more details on the techniques used to implement `PRINCE`, `LED` and `RECTANGLE`, please refer to the \[1\].

## References
[1] Bao, Z., Zhang, W., Luo, P., Lin, D.: Bitsliced Implementations of the PRINCE, LED and RECTANGLE Block Ciphers
on AVR 8-bit Microcontrollers. ICICS 2015.

[2] Dinu, D., Corre, Y. L., Khovratovich, D., Perrin, L., Großschädl, J., Biryukov, A.: Triathlon of Lightweight Block Ciphers for the Internet of Things, (http://eprint.iacr.org/2015/209).
