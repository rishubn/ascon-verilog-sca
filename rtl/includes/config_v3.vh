// Licensed under the Creative Commons 1.0 Universal License (CC0), see LICENSE
// for details.
//
// Author: Robert Primas (rprimas 'at' proton.me, https://rprimas.github.io)
//
// "v3" configuration parameters for the Ascon core.
// - Ascon-128 + Ascon-Hash.
// - 32-bit data block interface.
// - 3 permutations round per clock cycle.
`ifndef _config_v3_vh_
`define _config_v3_vh_
parameter unsigned UROL = 3;
`endif