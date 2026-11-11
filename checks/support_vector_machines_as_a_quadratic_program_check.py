# Support vector machines as a quadratic program -- the check behind the card.
# Standard library only.  Three roads to the widest road between two estates:
# (1) the dual QP solved by SMO, written out; (2) every pair and triple of
# houses that could sit on the kerbs, listed; (3) the KKT certificate.
from math import sqrt, log10, floor
M64 = (1 << 64) - 1
class Rng:                                       # SplitMix64, seed 2026
    def __init__(self, seed): self.s = seed
    def u(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
def houses(seed):                                # 30 Northfield (+1), then 30 Southgate (-1), in metres
    r, P, N = Rng(seed), [], []
    while len(P) < 30 or len(N) < 30:
        a = floor(1000 * r.u()) / 10; b = floor(1000 * r.u()) / 10   # to 10 cm
        d = (3 * a + 4 * b - 300) / 5            # metres from the surveyor's line 3x + 4y = 300
        if d >= 4 and len(P) < 30: P.append((a, b))
        elif d <= -4 and len(N) < 30: N.append((a, b))
    return P + N, [1] * 30 + [-1] * 30
def dot(p, q): return p[0] * q[0] + p[1] * q[1]
def tot(v):                                      # plain left-to-right sum, as in Rust
    t = 0.0
    for a in v: t += a
    return t
def sci(x):                                      # 1.62e-12, printed the same way in Rust
    if x == 0: return "0"
    e = floor(log10(abs(x))); m = x / 10.0 ** e
    return f"{m:.2f}e{e}"
def smo(X, y, C=float("inf"), tol=1e-9):        # minimise 1/2 lam'Q lam - sum lam, Q_ij = y_i y_j x_i.x_j
    n = len(X); K = [[dot(p, q) for q in X] for p in X]
    lam, G, k, viol = [0.0] * n, [-1.0] * n, 0, []   # G = Q lam - 1, the slope, kept up to date
    while True:
        assert k < 10_000_000, "SMO must stop"   # a broken update fails here instead of looping for ever
        up = [t for t in range(n) if (y[t] > 0 and lam[t] < C) or (y[t] < 0 and lam[t] > 0)]
        dn = [t for t in range(n) if (y[t] < 0 and lam[t] < C) or (y[t] > 0 and lam[t] > 0)]
        i = max(up, key=lambda t: -y[t] * G[t]); j = min(dn, key=lambda t: -y[t] * G[t])
        v = -y[i] * G[i] + y[j] * G[j]           # how far the worst pair breaks the KKT conditions
        viol.append(v)
        if v < tol: break                        # stopping test
        t = v / (K[i][i] + K[j][j] - 2 * K[i][j])            # exact step along the pair's line
        t = min(t, C - lam[i] if y[i] > 0 else lam[i], lam[j] if y[j] > 0 else C - lam[j])
        lam[i] += y[i] * t; lam[j] -= y[j] * t
        for m in range(n): G[m] += y[m] * t * (K[m][i] - K[m][j])
        k += 1
    w = (tot(lam[m] * y[m] * X[m][0] for m in range(n)), tot(lam[m] * y[m] * X[m][1] for m in range(n)))
    sv = [m for m in range(n) if lam[m] > 1e-8]
    b = tot(y[m] - dot(w, X[m]) for m in sv) / len(sv)
    return lam, w, b, k, viol, sv
def enumerate_kerbs(X, y):                       # every road with 2 or 3 houses on its kerbs
    n, best, cands, feas = len(X), None, 0, 0
    def try_road(w, b):
        nonlocal best, cands, feas
        cands += 1
        if w is None: return
        if min(y[m] * (dot(w, X[m]) + b) for m in range(n)) < 1 - 1e-9: return
        feas += 1
        if best is None or dot(w, w) < dot(best[0], best[0]): best = (w, b)
    for p in range(n):
        for q in range(n):
            if y[p] > 0 > y[q]:                  # one house on each kerb, road square to p - q
                d = (X[p][0] - X[q][0], X[p][1] - X[q][1]); s = 2 / dot(d, d)
                w = (s * d[0], s * d[1]); try_road(w, -dot(w, X[p]) + 1)
    for p in range(n):
        for r in range(p + 1, n):
            if y[p] != y[r]: continue
            nrm = (X[p][1] - X[r][1], X[r][0] - X[p][0])     # square to the kerb through p and r
            for q in range(n):
                if y[q] == y[p]: continue
                den = y[p] * (dot(nrm, X[p]) - dot(nrm, X[q]))
                if abs(den) < 1e-12: try_road(None, 0); continue        # p, r, q in a line: no road
                w = (2 * nrm[0] / den, 2 * nrm[1] / den); try_road(w, y[p] - dot(w, X[p]))
    return best, cands, feas
def width(X, y, w, b):                           # twice the smallest signed clearance, in metres
    return 2 * min(y[m] * (dot(w, X[m]) + b) for m in range(len(X))) / sqrt(dot(w, w))
X, y = houses(2026); n = len(X)
lam, w, b, k, viol, sv = smo(X, y)
nw = sqrt(dot(w, w)); s = [y[m] * (dot(w, X[m]) + b) for m in range(n)]
print("houses: 30 Northfield (+1), 30 Southgate (-1), seed 2026")
print(f"road 1, dual by SMO: {k} steps from lam = 0, stop when violation < 1e-9")
print(f"  w = ({w[0]:.6f}, {w[1]:.6f})   b = {b:.6f}   width 2/|w| = {2 / nw:.4f} m")
for m in sv:
    print(f"  support vector {m:2d} at ({X[m][0]:4.1f}, {X[m][1]:4.1f}), y = {y[m]:+d}, lam = {lam[m]:.6f}")
print(f"  houses with lam > 1e-8: {len(sv)} of {n}; sum of lam = {tot(lam):.6f}, |w|^2 = {nw * nw:.6f}")
print("  log10 violation at k = 0, 20, .., 280, " + str(k) + ": " + " ".join(f"{log10(v):.2f}" for v in viol[::20] + [viol[-1]]))
(we, be), cands, feas = enumerate_kerbs(X, y)
dk = (X[34][0] - X[57][0], X[34][1] - X[57][1]); up = (X[10][0] - X[57][0], X[10][1] - X[57][1])
cl = (11 * up[0] + 16 * up[1]) / sqrt(377)      # by hand: the climb from kerb to kerb along (11, 16)
print(f"by hand: kerb 57 to 34 = ({dk[0]:.1f}, {dk[1]:.1f}), 57 to 10 = ({up[0]:.1f}, {up[1]:.1f}), sqrt(377) = {sqrt(377):.4f}, width {cl:.4f} m, 2/width = {2 / cl:.6f}")
print(f"road 2, every kerb pair and triple: {cands} roads tried, {feas} clear every house")
print(f"  best: w = ({we[0]:.6f}, {we[1]:.6f})   b = {be:.6f}   width {2 / sqrt(dot(we, we)):.4f} m")
p_val, d_val = 0.5 * nw * nw, tot(lam) - 0.5 * nw * nw
print("road 3, the KKT certificate:")
print(f"  p* = 1/2|w|^2 = {p_val:.9f}   d* = q(lam) = {d_val:.9f}   |gap| {sci(abs(p_val - d_val))}")
print(f"  smallest y_i(w.x_i + b) - 1 = {sci(min(s) - 1)}   smallest lam = {sci(min(lam))}")
print(f"  |sum lam_i y_i| = {sci(abs(tot(lam[m] * y[m] for m in range(n))))}   largest lam_i(s_i - 1) = {sci(max(lam[m] * (s[m] - 1) for m in range(n)))}")
L = tot(lam) / 2                                 # the dual's picture: nearest points of the two hulls
pn = [tot(lam[m] * X[m][c] for m in range(n) if y[m] > 0) / L for c in (0, 1)]
ps = [tot(lam[m] * X[m][c] for m in range(n) if y[m] < 0) / L for c in (0, 1)]
gapd = sqrt((pn[0] - ps[0]) ** 2 + (pn[1] - ps[1]) ** 2)
print(f"  nearest points of the hulls ({pn[0]:.2f}, {pn[1]:.2f}) and ({ps[0]:.2f}, {ps[1]:.2f}), {gapd:.4f} m apart")
print(f"  Southgate's nearest point = {lam[57] / L:.4f} of house 57 + {lam[34] / L:.4f} of house 34")
print(f"  house 13 at ({X[13][0]:.1f}, {X[13][1]:.1f}): lam = {sci(lam[13])}, {(s[13] - 1) / nw:.4f} m outside the kerb")
new = (60.0, 45.0); sc = dot(w, new) + b
print(f"lost record at (60.0, 45.0): score {sc:.4f}, {sc / nw:.2f} m from the centre line: " + ("Northfield" if sc > 0 else "Southgate"))
print("what breaks:")
print(f"  width read as 1/|w|: {1 / nw:.4f} m")
cn = [tot(X[m][c] for m in range(30)) / 30 for c in (0, 1)]; cs = [tot(X[m][c] for m in range(30, 60)) / 30 for c in (0, 1)]
wa = (cn[0] - cs[0], cn[1] - cs[1]); ba = -dot(wa, ((cn[0] + cs[0]) / 2, (cn[1] + cs[1]) / 2))
cut = sum(1 for m in range(n) if y[m] * (dot(wa, X[m]) + ba) < 0)
print(f"  road through the estates' averages: width {width(X, y, wa, ba):.4f} m, {cut} houses on the wrong side")
bw = y[0] - dot(w, X[0])
cutb = sum(1 for m in range(n) if y[m] * (dot(w, X[m]) + bw) < 0)
print(f"  b taken from house 0 (lam = 0): b = {bw:.4f}, {cutb} houses on the wrong side")
Xb = X[:]; Xb[30] = (60.0, 45.0)                 # one Southgate house moved into Northfield
_, cb, fb = enumerate_kerbs(Xb, y)
print(f"  one Southgate house moved to (60.0, 45.0): {fb} of {cb} roads clear every house")
for C in (1.0, 10.0, 100.0):
    lc, wc, bc, kc, _, _ = smo(Xb, y, C)
    print(f"    soft margin C = {C:5.0f}: dual value {tot(lc) - 0.5 * dot(wc, wc):.4f} after {kc} steps")
for m, spot in ((13, (42.0, 49.0)), (0, (0.0, 100.0))):           # try changing: move one house
    Xt = X[:]; Xt[m] = spot; lt, wt, _, kt, _, st = smo(Xt, y)
    print(f"try: house {m} moved to ({spot[0]:.1f}, {spot[1]:.1f}): width {2 / sqrt(dot(wt, wt)):.4f} m, support vectors {st}, {kt} steps")
assert len(sv) == 3 and abs(2 / nw - 2 / sqrt(dot(we, we))) < 1e-6        # roads 1 and 2 agree
assert abs(w[0] - we[0]) < 1e-6 and abs(w[1] - we[1]) < 1e-6 and abs(b - be) < 1e-5
assert abs(p_val - d_val) < 1e-9 and min(s) > 1 - 1e-7                     # certificate
assert abs(gapd - 2 / nw) < 1e-6 and abs(cl - 2 / nw) < 1e-9 and abs(tot(lam) - nw * nw) < 1e-9        # hull distance, sum lam
assert fb == 0 and width(X, y, wa, ba) < 2 / nw and cutb > 0 and lam[13] < 1e-12 < s[13] - 1
print("figure, kerb +1, centre, kerb -1 at x = 0 and 100: " + " ".join(f"{(c - b - w[0] * xx) / w[1]:.2f}" for c in (1, 0, -1) for xx in (0, 100)))
print("ALL CHECKS PASS")
