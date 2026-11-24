# Optimal filters -- the check behind the card.  Standard library only.  ECG hum spec, fs = 500 Hz:
# half power or more to 20 Hz, 40 dB off from 49.8 to 250 Hz.  Roads: order formula against a search of
# built designs; gain against closed-form ripple levels; a simulated sine; the FIR's alternation count.
import math, cmath
FS, FP, FST, ATT, RP = 500.0, 20.0, 49.8, 40.0, 3.0
wp, ws = 2 * math.pi * FP / FS, 2 * math.pi * FST / FS
Wp = math.tan(wp / 2)                                   # prewarped passband edge
r = math.tan(ws / 2) / Wp                               # warped edge ratio
EPS = math.sqrt(10 ** (RP / 10) - 1)                    # ripple size: passband floor 1/sqrt(1 + eps^2)
D = math.sqrt(10 ** (ATT / 10) - 1) / EPS               # how far the stopband must sit below that
def db(g): return 20 * math.log10(g) if g > 1e-15 else -300.0
def resp(zs, ps, g, f):                                 # H(z) on the unit circle from zeros and poles
    z = cmath.exp(2j * math.pi * f / FS)
    return g * math.prod(z - q for q in zs) / math.prod(z - p for p in ps)
def poly(rts):                                          # multiply out the product of (1 - root z^-1)
    c = [1 + 0j]
    for q in rts: c = [u - q * v for u, v in zip(c + [0], [0] + c)]
    return [v.real for v in c]
def digital(za, pa, h0, N):                             # bilinear map z = (1 + s)/(1 - s), s scaled by Wp
    zs, ps = [(1 + Wp * q) / (1 - Wp * q) for q in za] + [-1.0] * (N - len(za)), [(1 + Wp * p) / (1 - Wp * p) for p in pa]
    return zs, ps, h0 / abs(resp(zs, ps, 1.0, 0.0))     # gain at 0 Hz set to h0
def agm_K(k):                                           # complete elliptic integral K(k) by the AGM
    a, b = 1.0, math.sqrt(1 - k * k)
    for _ in range(40): a, b = (a + b) / 2, math.sqrt(a * b)
    return math.pi / (2 * a)
def F(phi, k, n=200000):                                # integral of 1/sqrt(1 - k^2 sin^2 t), Simpson's rule
    return phi / n / 3 * sum((1 if i in (0, n) else 4 if i % 2 else 2) / math.sqrt(1 - (k * math.sin(i * phi / n)) ** 2) for i in range(n + 1))
def cde(u, k):                                          # Jacobi cd(uK, k) by descending Landen steps
    ks = []
    for _ in range(10): k = (k / (1 + math.sqrt(1 - k * k))) ** 2; ks.append(k)
    w = cmath.cos(u * math.pi / 2)
    for kn in reversed(ks): w = (1 + kn) * w / (1 + kn * w * w)
    return w
def butter(N): return digital([], [cmath.exp(1j * math.pi * (2 * i + N + 1) / (2 * N)) for i in range(N)], 1.0, N)
def cheby(N, e=EPS):
    a, th = math.asinh(1 / e) / N, [(2 * i + 1) * math.pi / (2 * N) for i in range(N)]
    return digital([], [complex(-math.sinh(a) * math.sin(t), math.cosh(a) * math.cos(t)) for t in th], 1.0 if N % 2 else 1 / math.sqrt(1 + e * e), N)
def ellip(N, e=EPS):
    k, u = 1 / r, [(2 * i - 1) / N for i in range(1, N // 2 + 1)]
    k1 = k ** N * math.prod(cde(1 - ui, k).real ** 4 for ui in u)          # sn(uK) = cd((1 - u)K)
    v0 = F(math.atan(1 / e), math.sqrt(1 - k1 * k1), 4000) / (N * agm_K(k1))
    za = [1j / (k * cde(ui, k).real) for ui in u]                          # zeros in the stopband
    pa = [1j * cde(ui - 1j * v0, k) for ui in u] + ([1j * cde(1 - 1j * v0, k)] if N % 2 else [])
    za, pa = za + [q.conjugate() for q in za], pa + [p.conjugate() for p in pa[:N // 2]]
    return digital(za, pa, 1.0 if N % 2 else 1 / math.sqrt(1 + e * e), N) + (k1,)
stop = [FST + 0.05 * i for i in range(4005)]            # 49.8 to 250 Hz in 0.05 Hz steps
pas = [0.05 * i for i in range(401)]                    # 0 to 20 Hz
def worst(d): return max(abs(resp(*d[:3], f)) for f in stop)
def meets(d): return abs(resp(*d[:3], FP)) ** 2 >= 0.5 - 1e-9 and worst(d) <= 10 ** (-ATT / 20)
def gdelay(d, f, h=1e-4): return -cmath.phase(resp(*d[:3], f + h) / resp(*d[:3], f - h)) / (4 * math.pi * h) * 1000
def settled(b, a, f):                                   # run the difference equation on a sine; amplitude, last 5 s
    y = []
    for n in range(3000):
        y.append(sum(b[k] * math.sin(2 * math.pi * f * (n - k) / FS) for k in range(len(b)) if n >= k) - sum(a[k] * y[n - k] for k in range(1, len(a)) if n >= k))
    return 2 * abs(sum(v * cmath.exp(-2j * math.pi * f * n / FS) for n, v in enumerate(y) if n >= 500)) / 2500
nb, nc = math.log10(10 ** (ATT / 10) - 1) / (2 * math.log10(r)), math.acosh(D) / math.acosh(r)
ks = (1 / r, math.sqrt(1 - 1 / r ** 2), 1 / D, math.sqrt(1 - 1 / D ** 2))   # K(k), K'(k) = K(sqrt(1 - k^2))
Kv, Ks = [agm_K(k) for k in ks], [F(math.pi / 2, k) for k in ks]; ne = Kv[0] * Kv[3] / (Kv[1] * Kv[2])
print(f"spec: fs {FS:.0f} Hz; half power or more to {FP:.0f} Hz; {ATT:.0f} dB off from {FST:.1f} Hz to {FS / 2:.0f} Hz")
print(f"by hand: warped edge ratio r {r:.4f}; ripple eps {EPS:.4f}, floor {db(1 / math.sqrt(1 + EPS ** 2)):.3f} dB; D {D:.2f}")
print(f"Butterworth: log10(10^(A/10) - 1) / (2 log10 r) = {math.log10(10 ** (ATT / 10) - 1):.5f} / {2 * math.log10(r):.4f} = {nb:.3f}")
print(f"Chebyshev:   acosh(D) / acosh(r) = {math.acosh(D):.4f} / {math.acosh(r):.4f} = {nc:.3f}")
print(f"elliptic:    K(1/r) {Kv[0]:.4f}, K' {Kv[1]:.4f}; K(1/D) {Kv[2]:.4f}, K' {Kv[3]:.4f}; ratio {ne:.3f}")
print(f"K by Simpson's rule agrees with the AGM to 1e-9: {'yes' if max(abs(a - b) for a, b in zip(Kv, Ks)) < 1e-9 else 'no'}")
print("design       order: search formula  mult  pole radius  worst stop dB  hum left uV  sim=H  peak delay ms")
des, rows = {}, []
for name, mk, need in [("Butterworth", butter, nb), ("Chebyshev I", cheby, nc), ("elliptic", ellip, ne)]:
    n = next(n for n in range(1, 12) if meets(mk(n)))
    des[name] = d = mk(n)
    amp, h = settled([d[2] * c for c in poly(d[0])], poly(d[1]), 50.2), abs(resp(*d[:3], 50.2))
    rows.append((n, math.ceil(need), max(abs(p) for p in d[1]), amp, h))
    print(f"{name:12s}         {n:3d}    {math.ceil(need):3d}     {2 * n + 1:3d}     {rows[-1][2]:.4f}       {db(worst(d)):7.2f}"
          f"       {500 * amp:6.2f}    {'yes' if abs(amp - h) < 1e-6 else 'no '}     {max(gdelay(d, f) for f in pas[1:]):6.2f}")
c4, e3, T4 = des["Chebyshev I"], des["elliptic"], lambda x: math.cos(4 * math.acos(x)) if x <= 1 else math.cosh(4 * math.acosh(x))
cf = max(abs(abs(resp(*c4[:3], f)) - 1 / math.sqrt(1 + (EPS * T4(math.tan(math.pi * f / FS) / Wp)) ** 2)) for f in pas + stop)
print(f"Chebyshev 4 against 1/sqrt(1 + eps^2 T4^2), both bands, agree to 1e-12: {'yes' if cf < 1e-12 else 'no'}")
ep, est = [db(abs(resp(*e3[:3], f))) for f in pas], -10 * math.log10(1 + (EPS / e3[3]) ** 2)
print(f"elliptic 3: passband {min(ep):.3f} to {round(max(ep), 3) + 0.0:.3f} dB; stopband peaks {db(worst(e3)):.2f} dB, theory {est:.2f} dB; "
      f"zero at {FS / (2 * math.pi) * cmath.phase(e3[0][0]):.2f} Hz")
def remez(L, K):                                        # Parks-McClellan exchange; weight K in the passband
    M = (L - 1) // 2; np_, ns = max(4, round(32 * (M + 2) * wp / (wp + math.pi - ws))), 32 * (M + 2)
    g = [wp * i / (np_ - 1) for i in range(np_)] + [ws + (math.pi - ws) * i / (ns - L % 2) for i in range(ns)]
    cs = [math.cos(w / 2) if L % 2 == 0 else 1.0 for w in g]   # even L: amplitude is cos(w/2) times a polynomial, 0 at 250 Hz
    Dg, Wg = [1 / c for c in cs[:np_]] + [0.0] * ns, [K * c for c in cs[:np_]] + cs[np_:]
    ext = [round(i * (len(g) - 1) / (M + 1)) for i in range(M + 2)]
    for _ in range(60):
        x = [math.cos(g[e]) for e in ext]               # bw, gm: barycentric weights
        bw = [1 / math.prod(x[i] - x[j] for j in range(M + 2) if j != i) for i in range(M + 2)]
        dl = sum(bw[i] * Dg[e] for i, e in enumerate(ext)) / sum(bw[i] * (-1) ** i / Wg[e] for i, e in enumerate(ext))
        C = [Dg[e] - (-1) ** i * dl / Wg[e] for i, e in enumerate(ext)]   # A must hit these at the old set
        gm = [1 / math.prod(x[i] - x[j] for j in range(M + 1) if j != i) for i in range(M + 1)]
        def A(w):                                       # the cosine polynomial, barycentric form
            t = math.cos(w)
            if t in x[:M + 1]: return C[x.index(t)]
            q = [gm[i] / (t - x[i]) for i in range(M + 1)]
            return sum(qi * ci for qi, ci in zip(q, C)) / sum(q)
        E = [Wg[i] * (Dg[i] - A(w)) for i, w in enumerate(g)]
        side = lambda i: [j for j in (i - 1, i + 1) if 0 <= j < len(g) and (j < np_) == (i < np_)]
        new = []                                        # new set: alternating peaks of the error
        for i in range(len(g)):
            if abs(E[i]) < abs(dl) * (1 - 1e-6) or any((E[i] - E[j]) * E[i] < 0 for j in side(i)): continue
            if not new or (E[i] > 0) != (E[new[-1]] > 0): new.append(i)
            elif abs(E[i]) > abs(E[new[-1]]): new[-1] = i
        while len(new) > M + 2: new.pop(0 if abs(E[new[0]]) < abs(E[new[-1]]) else -1)
        if len(new) < M + 2 or new == ext: break
        ext = new
    Am = [A(2 * math.pi * m / L) * (math.cos(math.pi * m / L) if L % 2 == 0 else 1) for m in range(M + 1)]   # taps from L samples
    return [(Am[0] + 2 * sum(Am[m] * math.cos(2 * math.pi * m * (n - (L - 1) / 2) / L) for m in range(1, M + 1))) / L for n in range(L)], abs(dl)
def amp(h, f): return sum(v * math.cos(2 * math.pi * f / FS * (k - (len(h) - 1) / 2)) for k, v in enumerate(h))
def alternations(h, K):                                 # sign changes between the peaks of the weighted error
    e = [K * (1 - amp(h, f)) for f in pas] + [-amp(h, f) for f in stop]; top = 0.995 * max(map(abs, e))
    pk = [i for i in range(len(e)) if abs(e[i]) >= top and (i in (0, 400, 401, len(e) - 1) or abs(e[i]) >= max(abs(e[i - 1]), abs(e[i + 1])))]
    return 1 + sum(1 for i, j in zip(pk, pk[1:]) if (e[i] > 0) != (e[j] > 0))
dp3, fir = (1 - 10 ** (-RP / 20)) / (1 + 10 ** (-RP / 20)), {}   # a 3 dB band written as 1 +- dp
for name, dp, ds, L0 in [("PM, flat", 0.01, 0.01, 11), ("PM, even L", 0.01, 0.01, 10), ("PM, 3 dB ripple", dp3, 0.01 * (1 + dp3), 11)]:
    L = next(L for L in range(L0, 81, 2) if remez(L, ds / dp)[1] <= ds)
    (h, dl), dl2 = remez(L, ds / dp), remez(L - 2, ds / dp)[1]
    sc = 1 / max(amp(h, f) for f in pas) if dp > 0.05 else 1.0   # the rippled design is scaled to peak gain 1
    kai = (-20 * math.log10(math.sqrt(dp * ds)) - 13) / (14.6 * (FST - FP) / FS) + 1
    ws_, al = max(abs(amp(h, f)) for f in stop), alternations(h, ds / dp)
    fir[name] = h
    print(f"{name}: {L} taps, M = {(L - 1) / 2:g}, delay {(L - 1) / 2 / FS * 1000:.0f} ms (Kaiser's estimate {kai:.1f} taps); ripple {dl:.5f}, {L - 2} taps {dl2:.5f}")
    print(f"  measured: worst stop {db(sc * ws_):.2f} dB, at 20 Hz {db(sc * abs(amp(h, FP))):.2f} dB; alternations {al} of "
          f"{(L - 1) // 2 + 2} needed; hum left {500 * sc * settled(h, [1.0], 50.2):.2f} uV")
    assert dl <= ds < dl2 and al >= (L - 1) // 2 + 2 and abs(ws_ - dl) < 1e-2 * dl and sc * abs(amp(h, FP)) >= math.sqrt(0.5)
def hamming(L, fc=(FP + FST) / 2):                      # the window design of Digital filters
    h = [(0.54 - 0.46 * math.cos(2 * math.pi * k / (L - 1))) * (math.sin(2 * math.pi * fc / FS * (k - (L - 1) / 2)) / (math.pi * (k - (L - 1) / 2)) if 2 * k != L - 1 else 2 * fc / FS) for k in range(L)]
    return [v / sum(h) for v in h]
hw = {L: db(max(abs(amp(hamming(L), f)) for f in stop)) for L in (51, 53)}
print(f"Hamming FIR from Digital filters: 53 taps worst stop {hw[53]:.2f} dB, 51 taps {hw[51]:.2f} dB")
print("chart, f Hz     " + " ".join(f"{2.5 * i:5.1f}" for i in range(101)))
for nm, d in [*des.items(), ("PM, flat", fir["PM, flat"]), ("Hamming 53", hamming(53))]:
    gain = [abs(resp(*d[:3], 2.5 * i)) if len(d) < 5 else abs(amp(d, 2.5 * i)) for i in range(101)]
    print(f"chart, {nm:11s} " + " ".join(f"{round(max(db(v), -80), 1) + 0.0:5.1f}" for v in gain))
brk = [db(worst(cheby(3))), db(worst(ellip(2))), db(worst(ellip(3, math.sqrt(10 ** 0.01 - 1))))]
print(f"breaks: Chebyshev order 3 {brk[0]:.2f} dB; elliptic order 2 {brk[1]:.2f} dB; elliptic 3 held to 0.1 dB ripple {brk[2]:.2f} dB")
assert [x[0] for x in rows] == [x[1] for x in rows] == [5, 4, 3] and all(x[2] < 1 and abs(x[3] - x[4]) < 1e-6 for x in rows)
assert max(abs(a - b) for a, b in zip(Kv, Ks)) < 1e-9 and cf < 1e-12 and hw[53] < -40 < hw[51] and min(brk) > -40
assert abs(max(ep)) < 1e-9 and abs(min(ep) + RP) < 1e-6 and abs(db(worst(e3)) - est) < 1e-6
print("ALL CHECKS PASS")
