# Interpolation: Riesz-Thorin, Marcinkiewicz, Hausdorff-Young -- the check behind the card.
# Standard library only.  The example: a shutter gate, 1 V for W = 0.001 s.  Roads: closed
# forms against integrals done here by Simpson or midpoint sums, the spectrum's 4th-power
# area against the triangle's energy on the time side, an exact 16-point DFT on random
# signals, and the maximal function by brute-force window search against its closed form.
from math import sin, cos, exp, pi, sqrt, log

W = 0.001                                   # gate open time, seconds; height 1 V

def sinc(u): return 1.0 if u == 0 else sin(pi * u) / (pi * u)

def S(q, lobes=2000, m=32):                 # area under |sinc u|^q over the line, Simpson per lobe
    tot = 0.0
    for k in range(lobes):
        h, s = 1.0 / m, 0.0
        for j in range(m + 1):
            c = 1 if j in (0, m) else (4 if j % 2 else 2)
            s += c * abs(sinc(k + j * h)) ** q
        tot += s * h / 3
    tail = 2 * lobes ** (1 - q) / (pi ** q * (q - 1))   # the area past the cut-off is below this
    return 2 * tot, tail

def ft_gate(xi, n=2000):                    # the transform integral itself, midpoint rule
    re = im = 0.0
    for k in range(n):
        t = (k + 0.5) * W / n
        re += cos(2 * pi * xi * t) * W / n; im -= sin(2 * pi * xi * t) * W / n
    return sqrt(re * re + im * im)

print(f"gate: mass ||f||_1 {W:.6f} V s; |f^(0)| integral {ft_gate(0):.6f}; |f^(300)| integral {ft_gate(300):.6f}, closed form {W * abs(sinc(W * 300)):.6f}")
assert abs(ft_gate(300) - W * abs(sinc(W * 300))) < 1e-9
s2, t2 = S(2)
s4, t4 = S(4)
s6, t6 = S(6)
assert abs(s2 - 1) < 2e-4 and abs(s4 - 2 / 3) < 1e-8 and abs(s6 - 0.55) < 1e-8
print(f"energy: ||f||_2^2 {W:.6f}; area of |f^|^2 {W * s2:.6f} (cut-off 2000 lobes, tail below {W * t2:.1e})")
p, q = 4 / 3, 4.0                           # halfway: 1/p = 3/4 sits midway between 1 and 1/2
tri = sum(min(t, 2 * W - t) ** 2 for t in ((k + 0.5) * 2 * W / 20000 for k in range(20000))) * 2 * W / 20000
print(f"area of |f^|^4: frequency side {W ** 3 * s4:.6e}; time side, energy of f*f {tri:.6e}; exact 2w^3/3 {2 * W ** 3 / 3:.6e}")
assert abs(tri - W ** 3 * s4) < 1e-14
lhs, rhs = (W ** 3 * s4) ** 0.25, W ** 0.75
print(f"halfway: ||f^||_4 {lhs:.6f}; ||f||_4/3 {rhs:.6f}; ratio {lhs / rhs:.6f}; Riesz-Thorin bound 1^(1/2) x 1^(1/2) = 1")
assert lhs < rhs

def gauss_ratio(p):                         # bell e^(-pi t^2) is its own transform; ||g||_p = p^(-1/2p)
    if p == 1: return 1.0
    pp = p / (p - 1)
    return (p ** (1 / p) / pp ** (1 / pp)) ** 0.5

def gnorm(p, n=12000):                      # ||g||_p by midpoint sum on [-6, 6]
    return (sum(exp(-p * pi * ((k + 0.5) * 12 / n - 6) ** 2) for k in range(n)) * 12 / n) ** (1 / p)
for pt in (4 / 3, 1.5):
    pp = pt / (pt - 1)
    assert abs(gnorm(pp) / gnorm(pt) - gauss_ratio(pt)) < 1e-9
print(f"bell at p 4/3: ratio by sums {gnorm(4.0) / gnorm(4 / 3):.6f}; closed form {gauss_ratio(4 / 3):.6f}")
inv = [1.0, 0.9, 0.8, 0.75, 0.7, 0.6, 0.5]
gate_r, bell_r = [], []
for a in inv:
    if a in (1.0, 0.5): gate_r.append(1.0)  # the ends: tallest point of |sinc| is 1; Plancherel
    else:
        pp = 1 / (1 - a); sq, tq = S(pp)
        assert tq < 1e-5
        gate_r.append(sq ** (1 / pp))
    bell_r.append(gauss_ratio(1 / a))
    assert gate_r[-1] <= bell_r[-1] + 1e-6 <= 1 + 2e-6
print("chart, 1/p:", " ".join(f"{a:.2f}" for a in inv))
print("chart, gate ratio:", " ".join(f"{r:.4f}" for r in gate_r))
print("chart, bell ratio:", " ".join(f"{r:.4f}" for r in bell_r))

state = 2026                                # SplitMix64, so Python and Rust draw the same signals
def rnd():
    global state
    state = (state + 0x9E3779B97F4A7C15) % 2 ** 64
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) % 2 ** 64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) % 2 ** 64
    return ((z ^ (z >> 31)) >> 11) / 2 ** 53 * 2 - 1
N = 16
def dft(x): return [sum(x[n] * complex(cos(2 * pi * k * n / N), -sin(2 * pi * k * n / N)) for n in range(N)) for k in range(N)]
def norm(v, r): return sum(abs(c) ** r for c in v) ** (1 / r)
worst = 0.0
for trial in range(500):
    x = [complex(rnd(), rnd()) for _ in range(N)]
    X = dft(x)
    assert abs(norm(X, 2) - 4 * norm(x, 2)) < 1e-9 and max(abs(c) for c in X) <= norm(x, 1)
    worst = max(worst, norm(X, 4) / norm(x, 4 / 3))
d, fl = dft([1.0] + [0.0] * 15), dft([1.0] * 16)
assert worst < 2 and abs(norm(d, 4) - 2) < 1e-12 and abs(norm(fl, 4) / norm([1.0] * 16, 4 / 3) - 2) < 1e-12
print(f"16-point DFT: M0 1, M1 sqrt(16) = 4, bound sqrt(1 x 4) = 2; worst of 500 random {worst:.4f}; spike {norm(d, 4):.4f}; flat {norm(fl, 4) / norm([1.0] * 16, 4 / 3):.4f}")

def Mf(d): return 1.0 if d < 0 else 0.5 / (d / W + 1)   # d = distance outside the gate, s
def Mbrute(x):                              # try windows (x - h, x + h), h = W/1000 ... 20 W
    return max(max(0.0, min(x + h, W) - max(x - h, 0.0)) / (2 * h) for h in (k * W / 1000 for k in range(1, 20001)))
for r in (0.5, 1.0, 4.0):
    assert abs(Mbrute(W + r * W) - Mf(r * W)) < 1e-12
    print(f"Mf at {r:g} w outside: window search {Mbrute(W + r * W):.6f} V; closed form {Mf(r * W):.6f} V")
for al in (0.1, 0.25, 0.5):
    lam = W * (1 / al - 1); n = 200000; step = 40 * W / n
    samp = step * sum(1 for k in range(n) if Mf(abs((k + 0.5) * step - 20 * W + W / 2) - W / 2) > al)
    assert abs(samp - lam) < 2 * step and lam <= 3 * W / al
    print(f"level {al:g} V: length of Mf > level {lam * 1e3:.4f} ms, sampled {samp * 1e3:.4f} ms; weak bound 3||f||_1/level {3 * W / al * 1e3:.4f} ms")
n = 100000
cake = sum(2 * a * (W * (1 / a - 1) if a < 0.5 else W) for a in ((k + 0.5) / n for k in range(n))) / n
assert abs(cake - 1.5 * W) < 1e-9
Cp = lambda p: 2 * (3 * p / (p - 1)) ** (1 / p)
Mtrue = lambda p: (1 + 2 ** (1 - p) / (p - 1)) ** (1 / p)   # ||Mf||_p/||f||_p, from the closed form of Mf
assert abs(Mtrue(2) ** 2 - cake / W) < 1e-6                  # against the layer-cake sum
assert abs(Cp(4 / 3) - (4 / 3 * 6 * 2 ** (1 / 3) / (1 / 3)) ** 0.75) < 1e-12   # the proof's p(2A0)(2A1)^(p-1)/(p-1)
print(f"p 2: ||Mf||_2^2 layer cake {cake * 1e3:.6f}, closed form w(1 + 1/2) {1.5 * W * 1e3:.6f} (x 1e-3 V^2 s)")
print(f"p 2: ||Mf||_2/||f||_2 {sqrt(1.5):.4f}; Marcinkiewicz C_2 = 2 sqrt(6) {Cp(2):.4f}")
for pt in (4 / 3, 1.1, 1.01):
    true = Mtrue(pt)
    assert 3 ** (1 / pt) < true < Cp(pt)       # the bare geometric mean 3^(1-theta) x 1^theta is too small
    print(f"p {pt:.2f}: ||Mf||_p/||f||_p {true:.4f}; C_p {Cp(pt):.4f}; geometric mean 3^(1/p) {3 ** (1 / pt):.4f}")

mis = [(w ** 3 * s4) ** 0.25 / w ** (2 / 3) for w in (1e-3, 1.0, 1e3, 1e6)]   # ||f^||_4 / ||f||_3/2
assert abs(mis[0] - (2 / 3) ** 0.25 * W ** (1 / 12)) < 1e-9 and mis[3] > 2.5   # exact s4 = 2/3 gives (2/3)^(1/4) w^(1/12)
print("breaks, p = 3/2 with q = 4: ratio ||f^||_4/||f||_3/2 at w = 1 ms, 1 s, 1000 s, 1e6 s:", " ".join(f"{r:.4f}" for r in mis))
def chirp_ratio(b):                         # f = e^(-pi (1 + ib) t^2): |f^| is a wider, lower bell
    return (1 + b * b) ** (1 / 8) * (4 / 3) ** (-3 / 8) / 4 ** (-1 / 8)
def chirp_ft(b, xi, n=40000):               # the transform integral itself, on [-6, 6] s
    re = im = 0.0
    for k in range(n):
        t = (k + 0.5) * 12 / n - 6; ph = -pi * b * t * t - 2 * pi * xi * t; a = exp(-pi * t * t) * 12 / n
        re += a * cos(ph); im += a * sin(ph)
    return sqrt(re * re + im * im)
assert abs(chirp_ft(10, 3) - (101) ** -0.25 * exp(-pi * 9 / 101)) < 1e-9
print("breaks, p = 4 > 2: chirp ratio ||f^||_4/3/||f||_4 at sweep 0, 10, 100, 1000:",
      " ".join(f"{chirp_ratio(b):.4f}" for b in (0, 10, 100, 1000)))
fh = lambda b, p: (sum(((1 + b * b) ** -0.25 * exp(-pi * ((k + 0.5) * 0.01 - 60) ** 2 / (1 + b * b))) ** p for k in range(12000)) * 0.01) ** (1 / p)
assert chirp_ratio(1000) > 5 and abs(fh(10, 4 / 3) / gnorm(4.0) - chirp_ratio(10)) < 1e-9   # |f^| summed on [-60, 60]
grid = sum(Mf((k + 0.5) * 1e-5) for k in range(100000)) * 1e-5   # one side, 0 to 1 s, midpoint sum
assert abs(W + 2 * grid - (W + W * log((1 + W) / W))) < 1e-8
for D in (1.0, 1000.0):
    print(f"breaks, p = 1: area under Mf over {D:g} s each side {W + W * log((D + W) / W):.6f} V s; ||f||_1 {W:.6f} V s")
print(f"try: 1/p 0.85: gate ratio {S(1 / (1 - 0.85))[0] ** (1 - 0.85):.4f}, bell ratio {gauss_ratio(1 / 0.85):.4f}; W 0.004 s: ||f^||_4 {(0.004 ** 3 * s4) ** 0.25:.6f}, ||f||_4/3 {0.004 ** 0.75:.6f}")
print(f"try: level 0.05 V: length of Mf > level {W * (1 / 0.05 - 1) * 1e3:.4f} ms, weak bound {3 * W / 0.05 * 1e3:.4f} ms; chirp ratio at sweep 10000 {chirp_ratio(10000):.4f}")
print("ALL CHECKS PASS")
