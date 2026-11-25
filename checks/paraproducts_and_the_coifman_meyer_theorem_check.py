# Paraproducts and the Coifman-Meyer theorem -- the check behind the card.
# Standard library only.  Signals last 1 s, so every frequency is a whole number of hertz.
# Octave band j holds 2^j <= |xi| < 2^(j+1) Hz; band -1 holds xi = 0.
from fractions import Fraction as Fr
from math import cos, sin, pi, log, log2, sqrt, floor

def tones(*pairs):                            # amplitude A at a Hz is A/2 at +a and at -a
    c = {}
    for amp, a in pairs: c[a] = c[-a] = c.get(a, 0) + Fr(amp) / 2
    return c

band = lambda x: -1 if x == 0 else abs(x).bit_length() - 1
pile = lambda j, k: "LH" if k >= j + 2 else "HL" if j >= k + 2 else "HH"   # Bony's rule on two band numbers
def conv(f, g):                               # spectrum of the product: frequencies add
    h = {}
    for x, a in f.items():
        for y, b in g.items(): h[x + y] = h.get(x + y, 0) + a * b
    return {k: v for k, v in h.items() if v != 0}

def pieces(f, g):                             # low-high, high-low, high-high, from band pairs
    out = {"LH": {}, "HL": {}, "HH": {}}
    for x, a in f.items():
        for y, b in g.items():
            p = out[pile(band(x), band(y))]; p[x + y] = p.get(x + y, 0) + a * b
    return {k: {x: v for x, v in p.items() if v != 0} for k, p in out.items()}

def fft(a, inv=False):                        # iterative radix-2 transform, length a power of 2
    a, n, j = a[:], len(a), 0
    for i in range(1, n):
        bit = n >> 1
        while j & bit: j ^= bit; bit >>= 1
        j |= bit
        if i < j: a[i], a[j] = a[j], a[i]
    m = 2
    while m <= n:
        w = complex(cos(2 * pi / m), (1 if inv else -1) * sin(2 * pi / m))
        for s in range(0, n, m):
            z = 1
            for k in range(m // 2):
                u, v = a[s + k], a[s + k + m // 2] * z
                a[s + k], a[s + k + m // 2] = u + v, u - v; z *= w
        m *= 2
    return [x / n for x in a] if inv else a

ms = lambda c: sum(v * v for v in c.values())  # mean square over the second (energy per second)
show = lambda k, p: "%s piece: mean square %s; lines %s" % (k, ms(p), [("%d Hz" % x, str(2 * p[x] ** 2)) for x in sorted(p) if x > 0])
N = 16384                                     # samples in the 1 s window
def samples(c): return [sum(float(v) * cos(2 * pi * x * k / N) for x, v in c.items()) for k in range(N)]

pairs = [("bass x whistle", ((Fr(1, 2), 3500),), ((1, 55),)),
         ("two tracks", ((1, 55), (Fr(1, 2), 3500)), ((Fr(3, 5), 440), (Fr(2, 5), 3000))),
         ("440 Hz x (1000 Hz + 1500 Hz)", ((1, 440),), ((1, 1000), (1, 1500))), ("(1000 Hz + 1500 Hz) x 440 Hz", ((1, 1000), (1, 1500)), ((1, 440),))]
for name, ft, gt in pairs:
    f, g = tones(*ft), tones(*gt); P, fg = pieces(f, g), conv(f, g)
    tot = {x: sum(p.get(x, 0) for p in P.values()) for x in set().union(*P.values())}
    assert {k: v for k, v in tot.items() if v != 0} == fg  # road 1: exact fractions
    E = {"LH": {}, "HL": {}, "HH": {}}                      # each pile rebuilt from which tone meets which, bands by logarithm
    for (u, a), (v, c) in [(s, t) for s in ft for t in gt]:
        e = E["LH" if c >= 4 * 2 ** floor(log2(a)) else "HL" if a >= 4 * 2 ** floor(log2(c)) else "HH"]
        for x, y in conv(tones((u, a)), tones((v, c))).items(): e[x] = e.get(x, 0) + y
    assert {k: {x: y for x, y in p.items() if y != 0} for k, p in E.items()} == P
    assert all(abs(band(x + y) - max(band(x), band(y))) <= 1 for x in f for y in g if pile(band(x), band(y)) != "HH")  # Step 2
    print("%s: product lines at %s Hz, mean square %s V^4" % (name, sorted(x for x in fg if x > 0), ms(fg)))
    for k in ("LH", "HL", "HH"): print("  " + show(k, P[k]))
    sf, sg = samples(f), samples(g); F, G = fft([complex(v) for v in sf]), fft([complex(v) for v in sg])
    def bandpart(S, js):                      # road 2: cut the sampled transform into octave bands
        return [z.real for z in fft([S[i] if band(i if i < N // 2 else i - N) in js else 0 for i in range(N)], True)]
    jf = sorted({band(x) for x in f}); jg = sorted({band(x) for x in g})
    df = {j: bandpart(F, {j}) for j in jf}; dg = {j: bandpart(G, {j}) for j in jg}
    T = {"LH": [0.0] * N, "HL": [0.0] * N, "HH": [0.0] * N}
    for j, k in [(j, k) for j in jf for k in jg]: T[pile(j, k)] = [t + u * v for t, u, v in zip(T[pile(j, k)], df[j], dg[k])]
    err = max(abs(a * b - x - y - z) for a, b, x, y, z in zip(sf, sg, T["LH"], T["HL"], T["HH"]))
    S = {k: fft([complex(v) for v in T[k]]) for k in T}
    gap = max(abs(S[k][x % N] / N - float(P[k].get(x, 0))) for k in T for x in range(-N // 2, N // 2))
    assert err < 1e-9 and gap < 1e-9
    print("  time road: LH + HL + HH = f g at all %d samples, gap below 1e-9; piece spectra match, gap below 1e-9" % N)

assert all(2 ** band(x) <= x < 2 ** (band(x) + 1) for x in range(1, 9000))
print("bands: " + ", ".join("%d Hz in %d (%d to %d Hz)" % (x, band(x), 2 ** band(x), 2 ** (band(x) + 1) - 1) for x in (55, 440, 500, 1000, 1500, 3000, 3500)))
for label, gt in (("bass at 1500 Hz", ((1, 1500),)), ("bass doubled", ((2, 55),))):
    print("try: bass x whistle, %s: %s" % (label, "; ".join(show(k, p) for k, p in pieces(tones(*pairs[0][1]), tones(*gt)).items() if p)))
name, ft, gt = pairs[1]; f, g = tones(*ft), tones(*gt); P = pieces(f, g)
print("drop HH: LH + HL keep mean square %s of %s; 3500 - 3000 = 500 Hz lands in band %d, from two lines in band %d"
      % (ms(P["LH"]) + ms(P["HL"]), ms(conv(f, g)), band(500), band(3500)))
H1 = lambda c: sqrt(sum((1 + x * x) * float(v * v) for x, v in c.items()))
sup = lambda c: max(abs(v) for v in samples(c))
lhs, rhs = H1(conv(f, g)), sup(f) * H1(g) + H1(f) * sup(g)
print("product rule s = 1: ||fg||_H1 = %.3f, ||f||_sup = %.3f, ||g||_H1 = %.3f, ||f||_H1 = %.3f, ||g||_sup = %.3f"
      % (lhs, sup(f), H1(g), H1(f), sup(g)))
deriv = lambda c: [sum(-2 * pi * x * float(v) * sin(2 * pi * x * k / N) for x, v in c.items()) for k in range(N)]
sf, sg, df, dg = samples(f), samples(g), deriv(f), deriv(g)  # time road: ||h||_H1^2 = mean h^2 + mean (h'/2 pi)^2
h1t = sqrt(sum((a * b) ** 2 + ((da * b + a * db) / (2 * pi)) ** 2 for a, b, da, db in zip(sf, sg, df, dg)) / N)
print("  time road: ||fg||_H1 from samples of fg and (fg)' = f'g + fg' = %.3f" % h1t)
print("  bound ||f||_sup ||g||_H1 + ||f||_H1 ||g||_sup = %.3f, ratio %.4f" % (rhs, lhs / rhs))
for k in ("LH", "HL", "HH"): print("  %s piece: ||.||_H1 = %.3f" % (k, H1(P[k])))
assert lhs <= rhs and abs(lhs ** 2 - sum(H1(p) ** 2 for p in P.values())) < 1e-6 * lhs ** 2 and abs(h1t - lhs) < 1e-6 * lhs

# The dyadic paraproduct on [0, 1): pi_b f = sum over dyadic I of b_I <f>_I h_I, N = 2^n points.
def dyadic(b, n):
    M = 2 ** n; Is = [(s, L) for L in [M >> m for m in range(n)] for s in range(0, M, L)]
    coef = {(s, L): (sum(b[s:s + L // 2]) - sum(b[s + L // 2:s + L])) / sqrt(L * M) for s, L in Is}
    def op(f):                                # pi_b f
        out = [0.0] * M
        for (s, L), c in coef.items():
            a, h = c * sum(f[s:s + L]) / L, sqrt(M / L)
            for i in range(s, s + L): out[i] += a * h if i < s + L // 2 else -a * h
        return out
    def adj(g):                               # its adjoint: sum of b_I <g, h_I> 1_I / |I|
        out = [0.0] * M
        for (s, L), c in coef.items():
            a = c * sqrt(M / L) * (sum(g[s:s + L // 2]) - sum(g[s + L // 2:s + L])) / M * M / L
            for i in range(s, s + L): out[i] += a
        return out
    car, s0, L0 = max((sum(c * c for (s2, L2), c in coef.items() if s <= s2 and s2 + L2 <= s + L) * M / L, s, L) for s, L in Is)
    osc = max(sum((v - sum(b[s:s + L]) / L) ** 2 for v in b[s:s + L]) / L for s, L in Is)
    x = [1.0 if s0 <= i < s0 + L0 else 0.0 for i in range(M)]
    for _ in range(300):                       # power iteration on pi* pi, Rayleigh quotient rises
        y = adj(op(x)); r = sqrt(sum(v * v for v in y)); x = [v / r for v in y]
    q = sum(v * v for v in op(x)) / sum(v * v for v in x)
    haar = M * sum(c * c * (sum(x[s:s + L]) / L) ** 2 for (s, L), c in coef.items()) / sum(v * v for v in x)
    ip = [sum(u * v for u, v in zip(op(b), x)), sum(u * v for u, v in zip(b, adj(x)))]
    assert abs(haar - q) < 1e-9 * q and abs(ip[0] - ip[1]) < 1e-9 * abs(ip[0])  # sum b_I^2 <x>_I^2; <pi b, x> = <b, pi* x>
    lam = 0.0
    if n == 6:                                # second road: the explicit 64 x 64 matrix A, its transpose, top eigenvalue of A^T A
        A = [op([float(i == k) for i in range(M)]) for k in range(M)]
        Gm = [[sum(u * v for u, v in zip(A[r], A[c])) for c in range(M)] for r in range(M)]; z = [1.0] * M
        for _ in range(300): y = [sum(u * v for u, v in zip(row, z)) for row in Gm]; r = sqrt(sum(v * v for v in y)); z = [v / r for v in y]
        lam = sum(u * v for u, v in zip([sum(a * c for a, c in zip(row, z)) for row in Gm], z))
    return car, osc, q, max(abs(v) for v in b), lam

for label, p in [("log2(1/x)", 1), ("log2(1/x)^2", 2)]:
    for n in (6, 8, 10, 12):
        b = [log2(2 ** n / (i + 0.5)) ** p for i in range(2 ** n)]
        C, osc, q, top, lam = dyadic(b, n)
        print("%sb = %s, %4d points: Carleson %.4f, oscillation %.4f, ||pi_b||^2 %.4f, 4C %.4f, ||pi_b|| %.4f, max|b| %.4f"
              % ("try: " if n == 12 else "", label, 2 ** n, C, osc, q, 4 * C, sqrt(q), top))
        if lam: print("  explicit %d x %d matrix: top eigenvalue of its transpose times it %.4f" % (2 ** n, 2 ** n, lam))
        assert abs(C - osc) < 1e-9 and C - 1e-9 <= q <= 4 * C and (p == 2 or C < 1 / log(2) ** 2) and (n > 6 or abs(lam - q) < 1e-9 * q)
print("mean oscillation of log2(1/x) on any (0, a), unsampled: variance 1/(ln 2)^2 = %.4f, so ||pi_b|| <= 2/ln 2 = %.4f" % (1 / log(2) ** 2, 2 / log(2)))
print("ALL CHECKS PASS")
