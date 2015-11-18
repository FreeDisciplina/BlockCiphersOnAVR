## Bitsliced Implementations of Lightweight Block Ciphers on AVR 8-bit Microcontrollers

This is a program to implement lightweight block ciphers on AVR 8-bit microcontrollers using bitsliced technique.
Several algorithms have been implemented:

  - [PRINCE](http://eprint.iacr.org/2012/529) - *A Low-latency Block Cipher for Pervasive Computing Applications*
  - [LED](http://eprint.iacr.org/2012/600) - *The LED Block Cipher*
  - [RECTANGLE](http://eprint.iacr.org/2014/084) - *A Bit-slice Lightweight Block Cipher Suitable for Multiple Platforms*
  - [SIMON and SPECK](http://eprint.iacr.org/2015/585) - *Block Ciphers for the Internet of Things*
  - [PRIDE](http://eprint.iacr.org/2014/453) - *Block Ciphers - Focus On The Linear Layer*
  
All of the implementation are written in assembly code and can be compiled using [Atmel Studio 6.2](http://www.atmel.com/tools/ATMELSTUDIO.aspx). The specific target device is the [AVR ATmega128 8-bit microcontroller](http://www.atmel.com/products/microcontrollers/avr/default.aspx).

For each cipher, we have implementations targeting to at least the two scenarios which are introduced in [\[2\]](http://eprint.iacr.org/2015/209).

They have verified the test vectors provided in the cipher specifications.

For more details on the techniques used to implement `PRINCE`, `LED` and `RECTANGLE`, please refer to our paper [\[1\]](http://eprint.iacr.org/2015/1118), for details on the techniques used to implement `SIMON` and `SPECK`, please refer to [\[3\]](http://eprint.iacr.org/2014/947), and for details on implementation of `PRIDE`, please refer to [\[4\]](http://eprint.iacr.org/2014/453).

## References
[1] Bao, Z., Zhang, W., Luo, P., Lin, D.: Bitsliced Implementations of the PRINCE, LED and RECTANGLE Block Ciphers on AVR 8-bit Microcontrollers. http://eprint.iacr.org/2015/1118.

[2] Dinu, D., Corre, Y. L., Khovratovich, D., Perrin, L., Großschädl, J., Biryukov, A.: Triathlon of Lightweight Block Ciphers for the Internet of Things, http://eprint.iacr.org/2015/209.

[3] Beaulieu, R., Shors, D., Smith, J., Treatman-Clark, S., Weeks, B., and Wingers, L.,: The Simon and Speck Block Ciphers on AVR 8-bit Microcontrollers. http://eprint.iacr.org/2014/947.

[4] Albrecht, M.R., Driessen, B., Kavun, E., Leander, G., Paar, C., Yalçin, T.: Block Ciphers - Focus On The Linear Layer (feat. PRIDE). In: Garay, J., Gennaro, R. (eds.) CRYPTO 2014. LNCS, vol 8616, pp.57–76. Springer, Heidelberg (2014). http://eprint.iacr.org/2014/453.
