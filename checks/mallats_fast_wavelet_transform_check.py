# Mallat's algorithm -- the check behind the card.  Standard library only.
# A 1024-sample stretch of an illustrative whistle (16000 samples a second,
# pitch 2000 + 4000 t Hz, taken from t = 0.175 s) goes down ten levels through
# the D4 filter pair with wrap-around ends, comes back up, and every multiply
# is counted.  Road one is the cascade; road two filters the record once per
# level with one long equivalent filter and keeps one output in 2^j.
import math

FS, N, J, T0 = 16000, 1024, 10, 0.175
R2, R3 = math.sqrt(2), math.sqrt(3)
H = [(1 + R3) / (4 * R2), (3 + R3) / (4 * R2), (3 - R3) / (4 * R2), (1 - R3) / (4 * R2)]
HAAR, L = [1 / R2, 1 / R2], len(H)
def highpass(h): return [(-1) ** n * h[len(h) - 1 - n] for n in range(len(h))]
G = highpass(H)
ops = [0]                                      # multiplies, counted as they happen

def split(s, h, g, wrap=True):                 # one level down: filter, keep every second
    n, lo, hi = len(s), [], []
    for k in range(n // 2):
        a = b = 0.0
        for m in range(len(h)):
            i = 2 * k + m
            if i < n or wrap:
                a += h[m] * s[i % n]; b += g[m] * s[i % n]; ops[0] += 2
        lo.append(a); hi.append(b)
    return lo, hi

def merge(lo, hi, h, g, wrap=True):            # one level up: each pair returns its share
    n = 2 * len(lo); out = [0.0] * n
    for k in range(len(lo)):
        for m in range(len(h)):
            i = 2 * k + m
            if i < n or wrap:
                out[i % n] += h[m] * lo[k] + g[m] * hi[k]; ops[0] += 2
    return out

def forward(x, h, g, levels, wrap=True):
    s, ds = list(x), []
    for _ in range(levels):
        s, d = split(s, h, g, wrap); ds.append(d)
    return s, ds

def inverse(s, ds, h, g, wrap=True):
    for d in reversed(ds): s = merge(s, d, h, g, wrap)
    return s

def direct(x, h, g, levels):                   # road two: long filters, no reuse
    n, e, ds, count = len(x), [1.0], [], 0
    def stretch(f, e, step):                   # e followed by f with gaps of step
        r = [0.0] * ((len(f) - 1) * step + len(e))
        for m, fm in enumerate(f):
            for p, ep in enumerate(e): r[m * step + p] += fm * ep
        return r
    def fold(f):                               # wrap a filter longer than the record
        r = [0.0] * min(len(f), n)
        for q, fq in enumerate(f): r[q % n] += fq
        return r
    def apply(f, j):
        nonlocal count
        count += (n >> j) * len(f)
        return [sum(f[q] * x[((k << j) + q) % n] for q in range(len(f))) for k in range(n >> j)]
    for j in range(1, levels + 1):
        ge, e = stretch(g, e, 2 ** (j - 1)), stretch(h, e, 2 ** (j - 1))
        ds.append(apply(fold(ge), j))
    return apply(fold(e), levels), ds, count

def trim(v): return f"{v:.4f}".rstrip("0").rstrip(".")
def maxerr(a, b): return max(abs(p - q) for p, q in zip(a, b))
def whistle(n): t = T0 + n / FS; return math.sin(2 * math.pi * (2000 * t + 2000 * t * t))

x = [whistle(n) for n in range(N)]
print(f"record: {N} samples at {FS} per second, {1000 * N / FS:.0f} ms, pitch {2000 + 4000 * T0:.0f} to {2000 + 4000 * (T0 + N / FS):.0f} Hz")
print("first samples x[0..3]: " + " ".join(f"{v:.6f}" for v in x[:4]))
print("low-pass h:  " + " ".join(f"{v:.6f}" for v in H))
print("high-pass g: " + " ".join(f"{v:.6f}" for v in G))
lag2 = H[0] * H[2] + H[1] * H[3]
print(f"sum h {sum(H):.6f}; sum h^2 {sum(v * v for v in H):.6f}; h overlap at shift 2 {abs(lag2):.6f}; sum g {abs(sum(G)):.6f}")
print(f"by hand, s1[0] = h . x[0..3] = {sum(H[m] * x[m] for m in range(4)):.6f}; d1[0] = g . x[0..3] = {sum(G[m] * x[m] for m in range(4)):.6f}")
ops[0] = 0
s, ds = forward(x, H, G, J)
fwd = ops[0]
energy_x = sum(v * v for v in x)
energy_c = s[0] ** 2 + sum(v * v for d in ds for v in d)
print("level  numbers  band (Hz)          share of energy")
bands = [(FS / 2 ** (j + 1), FS / 2 ** j, sum(v * v for v in ds[j - 1])) for j in range(1, J + 1)] + [(0.0, FS / 2 ** (J + 1), s[0] ** 2)]
for j, (lo, hi, e) in enumerate(bands, 1):
    name = f"{j:>5}" if j <= J else "coarse"
    count = len(ds[j - 1]) if j <= J else 1
    bar = "#" * round(40 * e / energy_c)
    print(f"{name:>6}  {count:>7}  {trim(lo):>7} to {trim(hi):<7}  {100 * e / energy_c:7.3f} % {bar}")
w = 2 * math.pi * 2828 / FS                    # mid-pitch, as an angle per sample
gain = (sum(h * math.cos(w * n) for n, h in enumerate(H)) ** 2 + sum(h * math.sin(w * n) for n, h in enumerate(H)) ** 2) / 2
print(f"share of power at 2828 Hz the low-pass passes on: {100 * gain:.3f} %; the high-pass: {100 * (1 - gain):.3f} %")
print(f"energy: samples {energy_x:.6f}, coefficients {energy_c:.6f}")
ops[0] = 0
back = inverse(s, ds, H, G)
inv = ops[0]
print(f"rebuild: largest error below 1e-12: {'yes' if maxerr(back, x) < 1e-12 else 'no'}")
s2, ds2, dcount = direct(x, H, G, J)
same = max(maxerr(s, s2), max(maxerr(a, b) for a, b in zip(ds, ds2)))
print(f"road two, long filters: same 1024 coefficients to 1e-9: {'yes' if same < 1e-9 else 'no'}")
print("multiplies per level, L x length in: " + " ".join(str(L * (N >> j)) for j in range(J)))
print(f"multiplies: cascade down {fwd}, formula 2L(N-1) = {2 * L * (N - 1)}, cascade up {inv}")
print(f"multiplies: long filters {dcount}; dense 1024 x 1024 matrix {N * N}; dense over cascade {N * N / fwd:.1f}")
print(f"per second at {FS} samples/s: {FS / N:.3f} blocks, cascade {FS / N * fwd:.0f}, dense {FS / N * N * N:.0f}")
print("record N  levels  cascade  per sample  long filters  dense N^2")
for n in [256, 1024, 4096, 16384]:
    y = [whistle(k) for k in range(n)]
    lv = n.bit_length() - 1
    ops[0] = 0; forward(y, H, G, lv); c = ops[0]
    dc = direct(y, H, G, lv)[2]
    assert c == 2 * L * (n - 1)                              # counted against the formula
    print(f"{n:>8}  {lv:>6}  {c:>7}  {c / n:10.4f}  {dc:>12}  {n * n:>9}")
ops[0] = 0
hs, hds = forward(x, HAAR, highpass(HAAR), J)
hcount = ops[0]
herr = maxerr(inverse(hs, hds, HAAR, highpass(HAAR)), x)
print(f"Haar pair: multiplies {hcount}, rebuild below 1e-12: {'yes' if herr < 1e-12 else 'no'}, d1[0] = (x0 - x1)/sqrt2: {'yes' if abs(hds[0][0] - (x[0] - x[1]) / R2) < 1e-12 else 'no'}")
cols = []                                      # the 16-point cascade as a matrix W, column by column
for i in range(16):
    a, b = forward([1.0 if k == i else 0.0 for k in range(16)], H, G, 4)
    cols.append(a + [v for d in b for v in d])
gram = max(abs(sum(p * q for p, q in zip(cols[a], cols[b])) - (a == b)) for a in range(16) for b in range(16))
print(f"16-point cascade as a matrix: W^T W = I to 1e-12: {'yes' if gram < 1e-12 else 'no'}")
bad = [(-1) ** n * H[n] for n in range(4)]
e_bad = maxerr(inverse(*forward(x, H, bad, J), H, bad), x)
print(f"mistake, high-pass not reversed (g[n] = (-1)^n h[n]): rebuild error {e_bad:.6f}")
e_zero = maxerr(inverse(*forward(x, H, G, J, False), H, G, False), x)
print(f"mistake, zeros past the end instead of wrap-around: rebuild error {e_zero:.6f}")
print(f"mistake, 1000 samples: levels before an odd length {(1000 & -1000).bit_length() - 1}")
print(f"mistake, no halving: multiplies {2 * L * N * J}, numbers kept {N * (J + 1)}")
assert fwd == 2 * L * (N - 1) and inv == fwd                # counter against 2L(N - 1)
assert same < 1e-9                                         # cascade against long filters
assert maxerr(back, x) < 1e-12 and herr < 1e-12            # exact inversion
assert abs(energy_x - energy_c) < 1e-9                     # energy kept
assert gram < 1e-12                                        # inverse is the transpose
assert e_bad > 0.1 and e_zero > 0.1                        # the two mistakes fail
print("ALL CHECKS PASS")
