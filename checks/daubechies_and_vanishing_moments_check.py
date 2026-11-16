# Daubechies D4: the four-tap filter from its conditions, and a day of air temperature.
# Standard library only.  Roads to the filter: the quadratic solved by hand, Newton's method
# on the raw conditions, and the factored form multiplied out.  Roads to the coefficients:
# filtering, the Taylor prediction, and the energy ledger with exact rebuilding.
import math
R2, R3 = math.sqrt(2), math.sqrt(3)
def fx(v, d=6): return f"{(v if abs(v) >= 0.5 * 10 ** -d else 0.0):.{d}f}"
def row(xs, d=6): return " ".join(fx(v, d) for v in xs)
def solve(A, b):  # Gaussian elimination with partial pivoting
    n = len(b); M = [A[i][:] + [b[i]] for i in range(n)]
    for c in range(n):
        p = max(range(c, n), key=lambda r: abs(M[r][c])); M[c], M[p] = M[p], M[c]
        for r in range(c + 1, n):
            f = M[r][c] / M[c][c]
            M[r] = [M[r][i] - f * M[c][i] for i in range(n + 1)]
    x = [0.0] * n
    for r in range(n - 1, -1, -1):
        x[r] = (M[r][n] - sum(M[r][i] * x[i] for i in range(r + 1, n))) / M[r][r]
    return x
# road 1: h0 + h2 = h1 + h3 = s, moment gives h1 = h0 + s/2, orthogonality 2 h0^2 - s h0 - s^2/4 = 0
s = 1 / R2
h0 = (s + math.sqrt(s * s + 2 * s * s)) / 4
h = [h0, h0 + s / 2, s - h0, s - h0 - s / 2]
print("D4 h, by the quadratic:", row(h))
# road 2: Newton's method on the four conditions, from a rough start
def F(v): return [sum(v) - R2, v[0] - v[1] + v[2] - v[3], -3 * v[0] + 2 * v[1] - v[2], v[0] * v[2] + v[1] * v[3]]
v = [0.7, 0.0, 0.0, 0.0]
for it in range(8):
    J = [[1, 1, 1, 1], [1, -1, 1, -1], [-3, 2, -1, 0], [v[2], v[3], v[0], v[1]]]
    v = [a - b for a, b in zip(v, solve(J, F(v)))]
print("D4 h, by Newton's method:", row(v))
assert max(abs(a - b) for a, b in zip(h, v)) < 1e-12
# road 3: H(z) = sqrt2 ((1 + 1/z)/2)^2 (a + b/z), a = (1 + sqrt3)/2, b = (1 - sqrt3)/2
a, b = (1 + R3) / 2, (1 - R3) / 2
fac = [R2 / 4 * c for c in (a, 2 * a + b, a + 2 * b, b)]
print("D4 h, factored form:", row(fac))
assert max(abs(x - y) for x, y in zip(h, fac)) < 1e-12
g = [h[3], -h[2], h[1], -h[0]]  # g_n = (-1)^n h_(3-n)
print("g:", row(g))
print(f"sum h {sum(h):.9f}  sum h^2 {sum(x * x for x in h):.9f}  h0h2+h1h3 {fx(h[0] * h[2] + h[1] * h[3], 9)}")
mom = [sum(g[m] * m ** p for m in range(4)) for p in range(3)]
print("moments of g, p = 0, 1, 2:", row(mom, 6), " C = half the p=2 moment", fx(mom[2] / 2))
assert abs(mom[0]) < 1e-12 and abs(mom[1]) < 1e-12
assert abs(mom[2] + math.sqrt(6) / 2) < 1e-12
# the scaling function at whole numbers: eigenvector of the refinement equation, by power iteration
p1, p2 = 0.5, 0.5
for it in range(60):
    p1, p2 = R2 * (h[1] * p1 + h[0] * p2), R2 * (h[3] * p1 + h[2] * p2)
    p1, p2 = p1 / (p1 + p2), p2 / (p1 + p2)
phi = {0: 0.0, 8: p1, 16: p2, 24: 0.0}  # keys in eighths
for step in (4, 2, 1):
    for m in range(step, 24, 2 * step):
        phi[m] = R2 * sum(h[n] * phi.get(2 * m - 8 * n, 0.0) for n in range(4))
psi = [R2 * sum(g[n] * phi.get(2 * m - 8 * n, 0.0) for n in range(4)) for m in range(25)]
print(f"phi(1) {p1:.6f} closed form {(1 + R3) / 2:.6f}   phi(2) {p2:.6f} closed form {(1 - R3) / 2:.6f}   eighths: area of phi {sum(phi.values()) / 8:.6f}, sum of psi {fx(sum(psi))}")
assert abs(p1 - (1 + R3) / 2) < 1e-12
assert abs(sum(phi.values()) / 8 - 1) < 1e-12 and abs(sum(psi)) < 1e-12 and abs(psi[12] - R3) < 1e-12  # area 1, moment 0, psi(1.5) = sqrt3
print("chart t:", row([m / 8 for m in range(25)], 3))
print("chart phi:", row([phi[m] for m in range(25)], 3))
print("chart psi:", row(psi, 3))
# the day: air temperature every 15 minutes, 96 readings, illustrative
DT = 0.25
def T(t): u = 2 * math.pi * (t - 9) / 24; return 16 + 6 * math.sin(u) + 1.5 * math.sin(2 * u)
def T2(t): u = 2 * math.pi * (t - 9) / 24; w = 2 * math.pi / 24; return -w * w * (6 * math.sin(u) + 6 * math.sin(2 * u))
x = [T(n * DT) for n in range(96)]
HA, GA = [s, s], [s, -s]
def step(z, lo, hi):
    n = len(z)
    return ([sum(lo[m] * z[(2 * k + m) % n] for m in range(len(lo))) for k in range(n // 2)],
            [sum(hi[m] * z[(2 * k + m) % n] for m in range(len(hi))) for k in range(n // 2)])
def inv(a, d, lo, hi):
    y = [0.0] * (2 * len(a))
    for k in range(len(a)):
        for m in range(len(lo)):
            y[(2 * k + m) % len(y)] += lo[m] * a[k] + hi[m] * d[k]
    return y
ramp = [12.0, 12.5, 13.0, 13.5]
print(f"straight line 12.0 12.5 13.0 13.5: D4 detail {fx(sum(g[m] * ramp[m] for m in range(4)))}"
      f"  Haar details {fx((ramp[0] - ramp[1]) * s)} {fx((ramp[2] - ramp[3]) * s)}")
q = x[36:40]
print("readings 9:00 to 9:45:", row(q, 4), " products g_m x_m:", row([g[m] * q[m] for m in range(4)]))
print("   ", " D4 detail", fx(sum(g[m] * q[m] for m in range(4))),
      " Haar", fx((q[0] - q[1]) * s), " prediction C x''(9.375) dt^2", fx(mom[2] / 2 * T2(9.375) * DT * DT))
print(f"day: {len(x)} readings every {DT} h, min {min(x):.2f} C  max {max(x):.2f} C  energy {sum(v * v for v in x):.4f}")
print("j | D4 max|d|, Taylor error, count > 0.1 actual, predicted | Haar max|d|, count > 0.1")
coef = {}
for name, lo, hi in (("D4", h, g), ("Haar", HA, GA)):
    z, ds = x, []
    for j in range(1, 5):
        z, d = step(z, lo, hi); ds.append(d)
    coef[name] = (z, ds)
zd, zh = coef["D4"][1], coef["Haar"][1]
nc = sum(abs(v) > 0.1 for v in coef["D4"][0]); tot = [nc, nc]  # coarse averages count in both
for j in range(1, 5):
    w = 2 ** (j - 1) * DT
    pred = [2 ** ((j - 1) / 2) * mom[2] / 2 * T2((2 ** j * k + 1.5 * (2 ** j - 1)) * DT) * w * w for k in range(len(zd[j - 1]))]
    err = max(abs(p - q) for p, q in zip(pred, zd[j - 1]))
    if j <= 2: assert err < 0.01
    ca, cp = sum(abs(v) > 0.1 for v in zd[j - 1]), sum(abs(v) > 0.1 for v in pred); tot = [tot[0] + ca, tot[1] + cp]
    print(f"{j} | {max(map(abs, zd[j - 1])):.4f} {err:.4f} {ca} {cp}"
          f" | {max(map(abs, zh[j - 1])):.4f} {sum(abs(v) > 0.1 for v in zh[j - 1])}")
print(f"D4 coefficients above 0.1 C, the {nc} coarse averages included: actual {tot[0]}, predicted {tot[1]}")
def kterm(name, lo, hi):  # fewest largest coefficients that rebuild every reading within 0.1 C
    z, ds = coef[name]
    allc = sorted([abs(v) for d in ds for v in d] + [abs(v) for v in z], reverse=True)
    for K in range(1, 97):
        cut = allc[K - 1]
        y = [v if abs(v) >= cut else 0.0 for v in z]
        for d in reversed(ds): y = inv(y, [v if abs(v) >= cut else 0.0 for v in d], lo, hi)
        e = max(abs(p - q) for p, q in zip(x, y))
        if e <= 0.1: return K, e, sum(c * c for c in allc)
for name, lo, hi in (("D4", h, g), ("Haar", HA, GA)):
    K, e, en = kterm(name, lo, hi)
    print(f"{name}: energy of coefficients {en:.4f}; keep the {K} largest of 96, worst error {e:.4f} C")
    assert abs(en - sum(v * v for v in x)) < 1e-9
assert kterm("D4", h, g)[0] < kterm("Haar", HA, GA)[0] / 2
x2 = [T(n * DT / 2) for n in range(192)]
m4, mh = max(map(abs, step(x2, h, g)[1])), max(map(abs, step(x2, HA, GA)[1]))
print(f"every 7.5 min: level-1 max D4 {m4:.4f} (ratio {max(map(abs, zd[0])) / m4:.2f})  Haar {mh:.4f} (ratio {max(map(abs, zh[0])) / mh:.2f})")
assert abs(max(map(abs, zd[0])) / m4 - 4) < 0.3 and abs(max(map(abs, zh[0])) / mh - 2) < 0.1
print("chart hour:", row([k / 2 for k in range(48)], 1))
print("chart level-1 Haar:", row(zh[0], 3))
print("chart level-1 D4:", row(zd[0], 3))
# what breaks
shower = [v - (3.0 if 61 <= n <= 64 else 0.0) for n, v in enumerate(x)]
ch4 = [abs(p - q) for p, q in zip(step(shower, h, g)[1], zd[0])]
chh = [abs(p - q) for p, q in zip(step(shower, HA, GA)[1], zh[0])]
print(f"shower 15:15-16:00, 3 C colder: level-1 details changed by > 0.1: D4 {sum(c > 0.1 for c in ch4)}"
      f" (largest {max(ch4):.4f}), Haar {sum(c > 0.1 for c in chh)} (largest {max(chh):.4f})")
assert sum(c > 0.1 for c in ch4) == 4 and sum(c > 0.1 for c in chh) == 2
dm = step(x[24:48], h, g)[1]
print(f"6:00-11:45 alone, wrapped: D4 level-1 largest inside {max(map(abs, dm[:-1])):.4f}, wrap-around {fx(dm[-1], 4)}")
assert abs(dm[-1]) > 10 * max(map(abs, dm[:-1]))
h3 = solve([[1, 1, 1, 1], [1, -1, 1, -1], [-3, 2, -1, 0], [-9, 4, -1, 0]], [R2, 0, 0, 0])
print("four taps, three moments: h", row(h3, 6), " h0h2+h1h3", fx(h3[0] * h3[2] + h3[1] * h3[3]))
assert abs(h3[0] * h3[2] + h3[1] * h3[3]) > 0.01
gw = [h[0], -h[1], h[2], -h[3]]  # signs alternated, order not reversed
def wrong(y): return max(abs(p - q) for p, q in zip(y, inv(*step(y, h, gw), h, gw)))
print(f"g not reversed: <h, g> {fx(sum(p * q for p, q in zip(h, gw)))}  worst rebuild error {wrong(x):.4f} C, shower day {wrong(shower):.4f} C")
print("ALL CHECKS PASS")
