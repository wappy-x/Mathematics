# Filter banks: split a music clip into two bands, halve each, rejoin, get the clip back.
# Standard library only.  Roads: the bank run sample by sample (circular filters on a
# 0.1 s clip that repeats), the z-domain conditions as exact integer polynomials, and
# a DFT of each branch's output against the closed form for the alias it carries.
import math

FS, N = 44100, 4410                      # sample rate in Hz; 0.1 s clip, DFT bins 10 Hz apart
R2 = math.sqrt(2.0)
# Haar pair, each tap times sqrt 2: analysis H, G; synthesis F0 = G(-z), F1 = -H(-z)
HAAR = ([1, 1], [1, -1], [1, 1], [-1, 1], R2)          # (H, G, F0, F1, scale of each)
# LeGall 5/3 pair as integer numerators: H/8, G/2, F0/2, F1/8
L53 = ([-1, 2, 6, 2, -1], [1, -2, 1], [1, 2, 1], [1, 2, -6, 2, 1])

def mul(p, q):                           # polynomial product in z^-1 (convolution of taps)
    r = [0] * (len(p) + len(q) - 1)
    for i, a in enumerate(p):
        for j, b in enumerate(q):
            r[i + j] += a * b
    return r

def neg(p): return [c if k % 2 == 0 else -c for k, c in enumerate(p)]     # P(z) -> P(-z)
def add(p, q):
    n = max(len(p), len(q)); p, q = p + [0] * (n - len(p)), q + [0] * (n - len(q))
    return [a + b for a, b in zip(p, q)]

def show(v): return " ".join(str(c) for c in v)

def clip(f_hi):               # illustrative: A at 440 Hz, amplitude 0.5, plus a shimmer
    return [0.5 * math.cos(2 * math.pi * 440 * n / FS) + 0.2 * math.cos(2 * math.pi * f_hi * n / FS)
            for n in range(N)]

def filt(taps, x, s):                    # circular filter: y[n] = sum_k taps[k] x[n-k] / s
    return [sum(t * x[(n - k) % len(x)] for k, t in enumerate(taps)) / s for n in range(len(x))]

def halve_and_stuff(y): return [v if n % 2 == 0 else 0.0 for n, v in enumerate(y)]

def branches(x, bank, hi_gain=1.0, flip=1.0):          # (low branch out, high branch out)
    H, G, F0, F1, s = bank
    low = filt(F0, halve_and_stuff(filt(H, x, s)), s)
    high = filt([flip * c for c in F1], halve_and_stuff([hi_gain * v for v in filt(G, x, s)]), s)
    return low, high

COS = [math.cos(2 * math.pi * k / N) for k in range(N)]
SIN = [math.sin(2 * math.pi * k / N) for k in range(N)]
def bin_of(x, f):                         # DFT at f Hz as a complex number scaled to amplitude
    m = f * N // FS
    re = sum(v * COS[(m * n) % N] for n, v in enumerate(x))
    im = -sum(v * SIN[(m * n) % N] for n, v in enumerate(x))
    return complex(re, im) * 2 / N
def amp(x, f): return abs(bin_of(x, f))
def f4(v): return f"{v:.4f}"

# ---- road 1: the conditions as polynomials, exact integers ----
H, G, F0, F1, _ = HAAR
t_haar, a_haar = add(mul(F0, H), mul(F1, G)), add(mul(F0, neg(H)), mul(F1, neg(G)))
print("Haar, 2*(F0 H + F1 G) taps:", show(t_haar), "  2*(F0 H(-z) + F1 G(-z)):", show(a_haar))
assert t_haar == [0, 4, 0] and a_haar == [0, 0, 0]     # T = z^-1 (delay 1), alias term 0
H5, G5, F05, F15 = L53
assert G5 == neg(F05) and F15 == [-c for c in neg(H5)] # the cross-mirror rule, 5/3 pair
p5 = mul(H5, F05)
t53, a53 = add(mul(F05, H5), mul(F15, G5)), add(mul(F05, neg(H5)), mul(F15, neg(G5)))
print("5/3, 16*P = 16*H F0 taps:", show(p5))
print("5/3, 16*(F0 H + F1 G):", show(t53), "  16*(alias):", show(a53))
assert t53 == [0, 0, 0, 32, 0, 0, 0] and a53 == [0] * 7  # T = z^-3, alias term 0

# ---- road 2: the bank run sample by sample on the clip ----
x = clip(14000)
print("clip x[0..3]:", " ".join(f4(v) for v in x[:4]))
low, high = branches(x, HAAR)
out = [a + b for a, b in zip(low, high)]
lo_band = halve_and_stuff(filt(H, x, R2)); hi_band = halve_and_stuff(filt(G, x, R2))
print("time 2: low s =", f4(lo_band[2]), " high d =", f4(hi_band[2]),
      " rebuilt x~[2], x~[3] =", f4(out[2]), f4(out[3]))
err = max(abs(out[n] - x[(n - 1) % N]) for n in range(N))
print("Haar, largest |x~[n] - x[n-1]| over 4410 samples below 1e-12:", "yes" if err < 1e-12 else "no")
assert err < 1e-12
xi = [round(32767 * v) for v in x]       # the same clip as 16-bit integers, through the 5/3 bank
li = [sum(c * xi[(n - k) % N] for k, c in enumerate(H5)) if n % 2 == 0 else 0 for n in range(N)]
hi = [sum(c * xi[(n - k) % N] for k, c in enumerate(G5)) if n % 2 == 0 else 0 for n in range(N)]
oi = [sum(c * li[(n - k) % N] for k, c in enumerate(F05)) + sum(c * hi[(n - k) % N]
      for k, c in enumerate(F15)) for n in range(N)]  # every term over 16
ok = all(oi[n] == 16 * xi[(n - 3) % N] for n in range(N))
print("5/3 on 4410 integer samples: rebuilt exactly, 3 samples late:", "yes" if ok else "no")
assert ok

# ---- road 3: what each branch carries, DFT against closed form ----
def alias_pred(a, f_alias): return a * 0.5 * abs(math.sin(2 * math.pi * f_alias / FS))
for f in (440, 14000, 8050):
    print(f"at {f:>5} Hz  low branch {f4(amp(low, f))}  high branch {f4(amp(high, f))}  sum {f4(amp(out, f))}")
bl, bh = bin_of(low, 8050), bin_of(high, 8050)
print("high branch alias / low branch alias at 8050 Hz:", f4((bh / bl).real))
print("closed form for each branch's alias, 0.2 * sin(2 pi 8050/44100) / 2:", f4(alias_pred(0.2, 8050)))
assert abs(amp(low, 8050) - alias_pred(0.2, 8050)) < 1e-9 and abs(bh / bl + 1) < 1e-9
assert abs(amp(low, 440) - 0.5 * math.cos(math.pi * 440 / FS) ** 2) < 1e-9
assert amp(out, 8050) < 1e-12 and abs(amp(out, 14000) - 0.2) < 1e-9

# ---- what breaks ----
print("drop the high band: 8050 Hz phantom", f4(amp(low, 8050)), " 14000 Hz kept", f4(amp(low, 14000)))
l2, h2 = branches(x, HAAR, flip=-1.0)
o2 = [a + b for a, b in zip(l2, h2)]
print("F1 sign flipped: 8050 Hz", f4(amp(o2, 8050)), " 14000 Hz", f4(amp(o2, 14000)))
assert abs(amp(o2, 8050) - 2 * alias_pred(0.2, 8050)) < 1e-9
l3, h3 = branches(x, HAAR, hi_gain=0.5)
o3 = [a + b for a, b in zip(l3, h3)]
print("high band halved: 8050 Hz", f4(amp(o3, 8050)), " 14000 Hz", f4(amp(o3, 14000)))
assert abs(amp(o3, 8050) - 0.5 * alias_pred(0.2, 8050)) < 1e-9

# ---- try changing ----
for f_hi, f_al in ((4000, 18050), (11000, 11050)):
    l4, h4 = branches(clip(f_hi), HAAR)
    print(f"shimmer {f_hi} Hz: alias at {f_al} Hz, low branch {f4(amp(l4, f_al))}, rejoined {f4(amp([a + b for a, b in zip(l4, h4)], f_al))}")
B53 = ([c / 8 for c in H5], [c / 2 for c in G5], [c / 2 for c in F05], [c / 8 for c in F15], 1.0)
l5, h5 = branches(x, B53)
print("5/3, drop the high band: 8050 Hz phantom", f4(amp(l5, 8050)))

# ---- chart: Haar gains, 0 to 22050 Hz in 2205 Hz steps ----
fr = range(0, 22051, 2205)
print("chart, low gain:", " ".join(f"{R2 * abs(math.cos(math.pi * f / FS)):.2f}" for f in fr))
print("chart, high gain:", " ".join(f"{R2 * abs(math.sin(math.pi * f / FS)):.2f}" for f in fr))
print("ALL CHECKS PASS")
