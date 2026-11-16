# Convolution and Young's inequality -- the check behind the card.  Standard library only.
# Time t in seconds.  The lamp f is 1 on [0, 1) s.  The meter's window g is 1 per second
# on [0, 1) s.  Their convolution, the meter reading, is the triangle on [0, 2] s.
from math import exp, pi, log, sqrt
INF = float('inf')

def tri(t):                            # road 1: the overlap of [0, 1) and (t - 1, t]
    return max(0.0, min(t, 1.0) - max(0.0, t - 1.0))

def conv_mid(t, n):                    # road 2: the defining integral, n midpoint cells
    h = 1.0 / n
    return h * sum(1 for k in range(n) if 0.0 <= t - (k + 0.5) * h < 1.0)

def dconv(a, b):                       # road 3: the finite twin, exact whole numbers
    c = [0] * (len(a) + len(b) - 1)
    for i, x in enumerate(a):
        for j, y in enumerate(b):
            c[i + j] += x * y
    return c

def tri_norm(r, w=1.0):                # closed form r-size of the triangle from width-w gates
    return w if r == INF else (2 / (r + 1)) ** (1 / r) * w ** (1 + 1 / r)

def twin_norm(r, n, w=1.0):            # r-size of the sampled gates' discrete convolution
    h = w / n
    c = [h * min(m + 1, 2 * n - 1 - m) for m in range(2 * n - 1)]
    return max(c) if r == INF else (h * sum(x ** r for x in c)) ** (1 / r)

def gate_norm(p, w=1.0):
    return 1.0 if p == INF else w ** (1 / p)

def A(m):                              # Beckner's factor; A(1) = A(inf) = 1
    if m == 1 or m == INF:
        return 1.0
    mp = m / (m - 1)
    return sqrt(m ** (1 / m) / mp ** (1 / mp))

def conj(m):
    return INF if m == 1 else 1.0 if m == INF else m / (m - 1)

print("gates: lamp f on [0, 1) s, window g 1 per second on [0, 1) s")
for t in (0.25, 0.5, 1.0, 1.5, 1.75):
    a, b1, b2 = tri(t), conv_mid(t, 1000), conv_mid(t, 2000)
    assert abs(a - b1) < 1e-9 and abs(a - b2) < 1e-9
    print(f"reading at t = {t:.2f} s: overlap {a:.6f}, integral n=1000 {b1:.6f}, n=2000 {b2:.6f}")
print("chart,t," + ",".join(f"{k / 4:.2f}" for k in range(11)))
print("chart,lamp," + ",".join(f"{1.0 if k < 4 else 0.0:.2f}" for k in range(11)))
print("chart,reading," + ",".join(f"{tri(k / 4):.2f}" for k in range(11)))

gate, ramp, u = [1, 1, 1, 1], [1, 2, 3, 4], [1, 0, 2]   # four samples a second
assert dconv(gate, gate) == [1, 2, 3, 4, 3, 2, 1]
assert dconv(gate, ramp) == dconv(ramp, gate)
assert dconv(dconv(gate, ramp), u) == dconv(gate, dconv(ramp, u))   # u is not the gate
print("twin gate*gate", dconv(gate, gate))
print("twin gate*ramp", dconv(gate, ramp), "ramp*gate", dconv(ramp, gate))
print("twin (gate*ramp)*u", dconv(dconv(gate, ramp), u), "with u", u)
print("twin gate*(ramp*u)", dconv(gate, dconv(ramp, u)))

N, D = 1200, 0.01                      # Gaussians e^(-pi t^2) on a grid, cut off at 6 s
fk = [exp(-pi * (k * D) ** 2) for k in range(-2 * N, 2 * N + 1)]
f = [fk[2 * N + i - N // 2] for i in range(N + 1)]
hh = [D * sum(f[j] * fk[2 * N + i - j] for j in range(N + 1)) for i in range(N + 1)]
def gnorm(v, p):
    return max(v) if p == INF else (D * sum(x ** p for x in v)) ** (1 / p)
print(f"gaussian h(0): grid {hh[N // 2]:.6f}, closed form 1/sqrt(2) {1 / sqrt(2):.6f}")
print(f"cut-off 6 s; beyond it h stays below {exp(-pi * 18):.1e}")
assert abs(hh[N // 2] - 1 / sqrt(2)) < 1e-9

triples = [("1,1,1", 1, 1, 1), ("1,2,2", 1, 2, 2), ("4/3,4/3,2", 4 / 3, 4 / 3, 2),
           ("3/2,3/2,3", 1.5, 1.5, 3), ("2,2,inf", 2, 2, INF)]
print("young: p,q,r | gates | gates twin | gaussians | gaussians grid | best constant")
for lab, p, q, r in triples:
    assert abs(1 / p + 1 / q - 1 - (0 if r == INF else 1 / r)) < 1e-12
    g1 = tri_norm(r) / (gate_norm(p) * gate_norm(q))
    g2 = twin_norm(r, 2000)
    gn = lambda m: 1.0 if m == INF else m ** (-1 / (2 * m))
    hn = 1 / sqrt(2) * (1.0 if r == INF else (r / 2) ** (-1 / (2 * r)))
    c1 = hn / (gn(p) * gn(q))
    c2 = gnorm(hh, r) / (gnorm(f, p) * gnorm(f, q))
    best = A(p) * A(q) * A(conj(r))
    assert abs(g1 - g2) < 1e-6 and abs(c1 - c2) < 1e-9
    assert g1 <= best + 1e-12 and c1 <= best + 1e-12 and best <= 1 + 1e-12
    if lab in ("4/3,4/3,2", "3/2,3/2,3"):
        assert abs(c1 - best) < 1e-12  # Gaussians reach Beckner's constant
    print(f"young,{lab} | {g1:.6f} | {g2:.6f} | {c1:.6f} | {c2:.6f} | {best:.6f}")
print(f"worked: triangle squared, integrated {tri_norm(2) ** 2:.6f}; (4/3)^(3/4) {(4 / 3) ** 0.75:.6f}; 4^(1/4) {4 ** 0.25:.6f}")
a3 = (A(3), A(1.2), A(conj(6)))        # a rule-abiding triple, 1/3 + 5/6 = 1 + 1/6
assert a3[0] > 1 and abs(A(3) * A(1.5) - 1) < 1e-12   # one factor above 1; A(m) A(m') = 1
assert a3[0] * a3[1] * a3[2] <= 1
print(f"beckner: p,q,r = 3,1.2,6 | A(3) {a3[0]:.6f} | A(1.2) {a3[1]:.6f} | A(6') {a3[2]:.6f} | product {a3[0] * a3[1] * a3[2]:.6f}")
wa = sum(tri((k + 0.5) / 1000) * (2 if k >= 1000 else 1) for k in range(2000)) / 1000
assert abs(wa - 1.5) < 1e-9            # sliding changes size: seconds after 1 s count double
print(f"weighted: after 1 s each second counts double; gates' areas 1 and 1, triangle's area {wa:.6f} = 0.5 + 2 x 0.5")

print("scaling: gates of width w | ratio at p=q=4/3, r=2 | ratio at p=q=r=2 (off the rule) | twin n=1000")
for w in (0.01, 1.0, 100.0):
    good = tri_norm(2, w) / gate_norm(4 / 3, w) ** 2
    bad = tri_norm(2, w) / gate_norm(2, w) ** 2   # closed form sqrt(2/3) sqrt(w)
    twin = twin_norm(2, 1000, w) / gate_norm(2, w) ** 2
    assert abs(good - twin_norm(2, 1000, w) / gate_norm(4 / 3, w) ** 2) < 1e-6
    assert abs(bad - twin) < 1e-6 * bad
    print(f"scaling,w = {w:g} s | {good:.6f} | {bad:.6f} | {twin:.6f}")
fall = [4, 3, 2, 1]
print(f"try: w = 10000 s off the rule {tri_norm(2, 1e4) / gate_norm(2, 1e4) ** 2:.6f}; 10 cells at 0.25 s {conv_mid(0.25, 10):.1f}")
print("try: falling ramp, gate*fall", dconv(gate, fall), "(gate*fall)*u", dconv(dconv(gate, fall), u))

def G(s):                              # integral of 1/(1 + |u|) from 0 to s
    return log(1 + s) if s >= 0 else -log(1 - s)
def Hx(x):
    return (1 + x) * log(1 + x) - x
print("break: kernel 1/(1 + |t|), not in L1; area of lamp * kernel on [-L, L]")
for L in (10, 100, 1000):
    n = 200 * L
    num = sum(G(t) - G(t - 1) for t in (-L + (k + 0.5) * 2 * L / n for k in range(n))) * 2 * L / n
    assert abs(num - (Hx(L + 1) - Hx(L - 1))) < 1e-4
    print(f"break,L = {L} s: area {num:.6f}, closed form {Hx(L + 1) - Hx(L - 1):.6f}, 2 log L {2 * log(L):.6f}")
L, n = 1000, 200000
sq = sum((G(t) - G(t - 1)) ** 2 for t in (-L + (k + 0.5) * 2 * L / n for k in range(n))) * 2 * L / n
assert sqrt(sq + 2 / L) <= sqrt(2)   # 2-size with the tail bound stays under Young's bound
print(f"break: 2-size on [-1000, 1000] {sqrt(sq):.6f}, with tail at most {sqrt(sq + 2 / L):.6f}, Young bound sqrt(2) {sqrt(2):.6f}")
print("ALL CHECKS PASS")
