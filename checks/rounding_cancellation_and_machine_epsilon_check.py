# Machine epsilon and cancellation -- the check behind the card.  Standard library only.
# A runner's watch loses the fraction f = 1 - sqrt(1 - z) of each second, z = (v/c)^2.
# That is the small root of f^2 - 2f + z = 0.  The school formula loses its digits;
# the rewrite z / (1 + sqrt(1 - z)) keeps them, and the standard model bounds both.
import struct
from fractions import Fraction
from math import sqrt, log10, isqrt, ulp

def sci(x, p):                          # 2.220446049250313e-16, the same in Rust
    m, e = f"{x:.{p}e}".split("e")
    return f"{m}e{int(e)}"
C = 299792458.0                         # speed of light, m/s (exact by definition)
CC = 299792458 ** 2                     # c^2 as a whole number
U = 2.0 ** -53                          # unit roundoff: half the gap next to one

# ---- machine epsilon, three ways ----
one_bits = struct.unpack("<q", struct.pack("<d", 1.0))[0]
eps_bits = struct.unpack("<d", struct.pack("<q", one_bits + 1))[0] - 1.0
e = 1.0
while 1.0 + e / 2 > 1.0:                # stop when adding half of e changes nothing
    e /= 2
print(f"eps_mach from the bits of 1,{sci(eps_bits, 15)}")
print(f"eps_mach by halving,{sci(e, 15)}")
print(f"eps_mach library cross-check,{sci(ulp(1.0), 15)}")
print(f"unit roundoff u,{sci(U, 15)}")
print(f"fl(1 + u) - 1 in u,{(1.0 + U - 1.0) / U:.0f}")
print(f"fl(1 + 3u) - 1 in u,{(1.0 + 3 * U - 1.0) / U:.0f}")
gap = 2.0 ** -52
while gap * 2 ** 52 * 2 <= 1e6:         # the power of two at or below 1,000,000
    gap *= 2
print(f"gap near 1000000,{sci(gap, 3)},largest rounding,{sci(gap / 2, 3)}")
assert eps_bits == e == 2.0 ** -52 == ulp(1.0)
assert 1.0 + U == 1.0 and 1.0 + 3 * U == 1.0 + 4 * U      # ties go to the even neighbour

# ---- the runner, three roads to f ----
def naive(z): return 1.0 - sqrt(1.0 - z)            # the school formula's small root
def safe(z): return z / (1.0 + sqrt(1.0 - z))       # product of roots: small = z / big
def series(z): return z / 2 + z * z / 8             # 1 - sqrt(1 - z) = z/2 + z^2/8 + ...
def rel_err(fhat, v):                   # (fhat - f)/f against the exact f for speed v,
    num, den = fhat.as_integer_ratio()  # fhat = num/den exactly; f = z/2 (1 + w)
    r = (num * 2 * CC - v * v * den) / (v * v * den)
    zt = (v * v) / (C * C)
    w = zt / 4 + zt * zt / 8            # next terms are below 1e-30 here
    return (r - w) / (1 + w)
def exact_rel_err(fhat, v):             # Python-only road: whole-number square root
    S = 2 ** 400                        # sqrt(1 - z) to 400 bits, rounded down
    root = Fraction(isqrt((CC - v * v) * S * S // CC), S)
    return float(Fraction(fhat) / (Fraction(v * v, CC) / (1 + root)) - 1)

v = 5
z = (v * v) / (C * C)
x = 1.0 - z
s = sqrt(x)
fn, fs, fr = naive(z), safe(z), series(z)
en, es, er = rel_err(fn, v), rel_err(fs, v), rel_err(fr, v)
fu = fs / U
bound_n = 1.5 / fu + 2 * U              # 1.5u of absolute error, over f; plus z's 2u
print(f"runner speed,{v} m/s,speed of light,{C:.0f} m/s")
print(f"z = (v/c)^2,{sci(z, 15)},in u,{z / U:.4f}")
print(f"fl(1 - z),1 - {(1.0 - x) / U:.0f}u,rounding error in u,{(z - 3 * U) / U / (1 - z):.4f}")
print(f"fl(sqrt(1 - z)),1 - {(1.0 - s) / U:.0f}u,fl(1 + s),2 - {(2.0 - (1.0 + s)) / U:.0f}u")
print(f"f naive,{sci(fn, 15)}")
print(f"f safe,{sci(fs, 15)}")
print(f"f series,{sci(fr, 15)}")
print(f"f in u,{fu:.4f}")
print(f"naive error,{en * 100:.2f}%,bound,{bound_n * 100:.2f}%,ratio,{en / bound_n:.3f}")
print(f"safe error in u,{es / U:.4f},bound 4.75u,ratio,{es / U / 4.75:.3f}")
print(f"series error in u,{er / U:.4f}")
print(f"lag over a 1-hour run,{sci(fs * 3600, 3)} s")
assert abs(fs - fr) <= 4.75 * U * fr                # safe meets the series
assert abs(en - exact_rel_err(fn, v)) < 1e-14       # the error road meets exact roots
assert abs(es - exact_rel_err(fs, v)) < 1e-25
assert 0.5 < en < bound_n                           # naive: 60% off, inside its bound
assert abs(es) <= 4.75 * U                          # safe: inside its bound

# ---- five speeds: the naive error grows as f shrinks; the safe one does not ----
for v, name in [(2, "walk"), (5, "run"), (30, "car"), (250, "airliner"), (3874, "GPS satellite")]:
    z = (v * v) / (C * C)
    fs = safe(z)
    en, es = rel_err(naive(z), v), rel_err(fs, v)
    bound_n = 1.5 * U / fs + 2 * U
    assert abs(en) <= bound_n and abs(es) <= 4.75 * U
    assert abs(es - exact_rel_err(fs, v)) < 1e-25
    assert abs(fs - series(z)) <= 4.75 * U * fs     # the series meets the rewrite
    print(f"speed,{v},{name},f,{sci(fs, 3)},naive error,{sci(abs(en), 3)},bound,"
          f"{sci(bound_n, 3)},safe error in u,{es / U:.3f}")
    print(f"chart,{v},log10 naive,{log10(abs(en)):.2f},log10 bound,{log10(bound_n):.2f},"
          f"log10 safe,{log10(abs(es)):.2f}")

# ---- what breaks ----
z = 25 / (C * C)
print(f"flipped rewrite z/(1 - s),{sci(z / (1.0 - sqrt(1.0 - z)), 4)},should be,{sci(1.0 + sqrt(1.0 - z), 4)}")
z = 3874 * 3874 / (C * C)
t = rel_err(z / 2, 3874)
print(f"first term z/2 only at 3874 m/s,error,{sci(abs(t), 3)},in u,{abs(t) / U:.0f}")
assert abs(t) > 1e5 * U
print("ALL CHECKS PASS")
