import argparse, io, random, subprocess
from ascon import *
from random import randint, getrandbits
# Terminal colors
OKGREEN = "\033[92m"
WARNING = "\033[93m"
FAIL = "\033[91m"
ENDC = "\033[0m"

# Specify verbose output of Ascon computations in software
VERBOSE_AEAD_SW = 0
VERBOSE_HASH_SW = 0

# Specify encryption, decryption, and/or hash operations for the Ascon core
INCL_ENC = 1
INCL_DEC = 1
INCL_HASH = 1

def XOR(a: bytes|bytearray, b: bytes|bytearray) -> bytes:
    """XOR two byte arrays"""
    return bytes([a_ ^ b_ for a_,b_ in zip(a, b)])

def randbytes(n: int) -> bytes:
    """Generate n random bytes"""
    return bytes([randint(0, 255) for _ in range(n)])

def randbinstr(length: int) -> str:
    return f'{getrandbits(length):=0{length}b}'
    
def binstr(vals) -> str:
    outstr = ""
    for v, l in vals:
        outstr += f'{v:=0{l}b}'
    return outstr

def split_data(data: bytes, num_shares: int):
    """Split data into n number of shares"""
    shares = bytearray()
    rand_sum = bytes(len(data))
    for i in range(num_shares-1):
        mask_i = randbytes(len(data))
        rand_sum = XOR(rand_sum, mask_i)
        shares.extend(mask_i)
    shares.extend(XOR(rand_sum, data))
    return shares

def combine_shares(data: bytearray, num_shares: int):
    share_size = len(data) // num_shares
    x = data[0:share_size]
    for i in range(share_size, len(data), share_size):
        x = XOR(x, data[i:i+share_size])
    return x

def str2bytes(s: str) -> bytes:
    l = []
    for i in range(0, len(s), 2):
        l.append(int(s[i:i+2], 16))
    return bytes(l)

# Write data segment to test vector file
def write_data_seg(f, x, xlen, num_shares):
    ccw = 4*num_shares
    assert xlen % 4 == 0
    for i in range(0, xlen, 4):
        b = split_data(x[i:i+4], num_shares)
        f.write("DAT ")
        f.write("".join(["{:02X}".format(bb) for bb in b]))
        f.write("\n")
    f.write("\n")
    
def write_tv_file(k, n, ad, p, c, m, d):
    f = open("tv/tv_shared.txt", "w")

    if INCL_ENC:
        f.write("# Load key\n")
        f.write("INS 30{:06x}\n".format(len(k)))
        write_data_seg(f, k, len(k), d)

        f.write("# Specify authenticated encryption\n")
        f.write("INS 00000000\n")
        f.write("\n")

        f.write("# Load nonce\n")
        f.write("INS 40{:06x}\n".format(len(n)))
        write_data_seg(f, n, len(n), d)

        if len(ad) > 0:
            f.write("# Load associated data\n")
            f.write("INS 50{:06x}\n".format(len(ad)))
            write_data_seg(f, ad, len(ad), d)

        f.write("# Load plaintext\n")
        f.write("INS 61{:06X}\n".format(len(p)))
        write_data_seg(f, p, len(p), d)

    if INCL_DEC:
        if not INCL_ENC:
            f.write("# Load key\n")
            f.write("INS 30{:06x}\n".format(len(k)))
            write_data_seg(f, k, len(k), d)

        f.write("# Specify authenticated decryption\n")
        f.write("INS 10000000\n")
        f.write("\n")

        f.write("# Load nonce\n")
        f.write("INS 40{:06x}\n".format(len(n)))
        write_data_seg(f, n, len(n), d)

        if len(ad) > 0:
            f.write("# Load associated data\n")
            f.write("INS 50{:06x}\n".format(len(ad)))
            write_data_seg(f, ad, len(ad), d)

        f.write("# Load ciphertext\n")
        f.write("INS 71{:06X}\n".format(len(p)))
        write_data_seg(f, c, len(c) - 16, d)

        f.write("# Load tag\n")
        f.write("INS 81{:06x}\n".format(16))
        write_data_seg(f, c[-16:], 16, d)

    if INCL_HASH:
        f.write("# Specify hashing\n")
        f.write("INS 20000000\n")
        f.write("\n")

        f.write("# Load message data\n")
        f.write("INS 51{:06x}\n".format(len(m)))
        write_data_seg(f, m, len(m), d)

    f.close()

# Print inputs/outputs of Ascon software implementation
def print_result(result, ad_pad, p_pad, c, m_pad, h):
    print()
    if result:
        print(f"{FAIL}")
    print("ad = " + "".join("{:02x}".format(x) for x in ad_pad))
    print("p  = " + "".join("{:02x}".format(x) for x in p_pad))
    print("c  = " + "".join("{:02x}".format(x) for x in c[:-16]))
    print("t  = " + "".join("{:02x}".format(x) for x in c[-16:]))
    print("m  = " + "".join("{:02x}".format(x) for x in m_pad))
    print("h  = " + "".join("{:02x}".format(x) for x in h))
    if result:
        print(f"ERROR{ENDC}")
        exit()
    else:
        print(f"{OKGREEN}PASS{ENDC}")
def run_tb(k, n, ad, p, variant, num_shares):
    ad_pad = bytearray(ad)
    p_pad = bytearray(p)
    m_pad = bytearray(ad)

    # 10*-pad inputs to block size (64 bits)
    if len(ad_pad) > 0:
        ad_pad.append(0x80)
        while len(ad_pad) % 8 != 0:
            ad_pad.append(0x00)
    p_pad.append(0x80)
    while len(p_pad) % 8 != 0:
        p_pad.append(0x00)
    m_pad.append(0x80)
    while len(m_pad) % 8 != 0:
        m_pad.append(0x00)
   
    # Compute Ascon in software
    c = ascon_aead(k, n, ad_pad, p_pad, VERBOSE_AEAD_SW)
    h = ascon_hash(m_pad, VERBOSE_HASH_SW)

    # Write test vector file for verilog test bench
    write_tv_file(k, n, ad_pad, p_pad, c, m_pad, num_shares)
    ps = subprocess.run(
        ["make", f'VERSION={variant}','VCD=1', 'verilator'],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=True,
        text=True,
    )
    stdout = io.StringIO(ps.stdout)
    tb_c = bytearray()
    tb_t = bytearray()
    tb_p = bytearray()
    tb_h = bytearray()
    tb_ver = bytearray()
    for line in stdout.readlines():
        print(line)
        if "c =>" in line:
            tb_c += bytearray.fromhex(line[5 : 5 + 16])
        if "t =>" in line:
            tb_t += bytearray.fromhex(line[5 : 5 + 16])
        if "p =>" in line:
            tb_p += bytearray.fromhex(line[5 : 5 + 16])
        if "h =>" in line:
            tb_h += bytearray.fromhex(line[5 : 5 + 16])
        if "v =>" in line:
            tb_ver += bytearray.fromhex("0" + line[5 : 5 + 1])
            
    print("ad = " + "".join("{:02x}".format(x) for x in ad_pad))
    print("p  = " + "".join("{:02x}".format(x) for x in tb_p))
    print("c  = " + "".join("{:02x}".format(x) for x in tb_c[:-16]))
    print("t  = " + "".join("{:02x}".format(x) for x in tb_t[-16:]))
    result = 0
    if INCL_ENC:
        result |= c[:-16] != tb_c
        result |= c[-16:] != tb_t
    if INCL_DEC:
        result |= p_pad != tb_p
        result |= tb_ver[0] != 1
    if INCL_HASH:
        result |= h != tb_h
    
   # print_result(result, ad_pad, tb_p, tb_c, m_pad, tb_h)
    print_result(result, ad_pad, p_pad, c, m_pad, h)
def run_tb_single(variant, num_shares):
    k = bytes.fromhex("000102030405060708090a0b0c0d0e0f")
    n = bytes.fromhex("000102030405060708090a0b0c0d0e0f")
    ad = bytes.fromhex("00010203")
    p = bytes.fromhex("00010203")
    print(variant)
    print("k  = " + "".join("{:02x}".format(x) for x in k))
    print("n  = " + "".join("{:02x}".format(x) for x in n))
    run_tb(k, n, ad, p, variant, num_shares)
    print(f"{OKGREEN}ALL PASS{ENDC}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-s",
        "--single",
        action="store",
        nargs="*",
        help="Perform a single test bench run.",
    )
    parser.add_argument(
        "-w",
        "--sweep",
        action="store",
        nargs="*",
        help="Sweep over inputs of different lengths and perform test bench runs.",
    )
    parser.add_argument(
        "-v",
        "--variant",
        nargs="?",
        default=1,
        type=int,
        help="The variant of the Ascon core: 1, 2, or 3",
    )
    parser.add_argument(
        "-d",
        "--num-shares",
        default=2,
        type=int
    )
    args = parser.parse_args()
    variant = f"v{args.variant}"
    run_tb_single(variant, args.num_shares)
