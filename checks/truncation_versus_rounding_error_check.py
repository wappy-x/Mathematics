# Truncation versus rounding -- the check behind the card.  Python standard
# library only; struct is used only to round a double to single precision.
# Road one: closed forms (the stone's speed 29.4 m/s and its truncation 4.9h;
# pi; e).  Road two: each method run at many steps, error against its law.
# Road three: the same slope in single precision, where only rounding changes.
import math, struct
U = 2.0 ** -53                                  # unit roundoff of a double
def r32(x): return struct.unpack("f", struct.pack("f", x))[0]   # round to single
def sci(x, d=2):                                # 1.23e-5, the same in Rust
    m, e = f"{x:.{d}e}".split("e")
    return f"{m}e{int(e)}"
def s(t): return 4.9 * t * t                    # metres fallen after t seconds
def s32(t): return r32(r32(r32(4.9) * t) * t)   # the same, in single precision
def fwd(h, t=3.0): return (s(t + h) - s(t)) / h
def ctr(h, t=3.0): return (s(t + h) - s(t - h)) / (2 * h)
def fwd32(h):
    h = r32(h)
    return r32(r32(s32(r32(3.0 + h)) - s32(3.0)) / h)
def lg(x): return math.log10(abs(x))
V = 29.4                                        # exact speed at t = 3 s
print(f"stone: s(3) = {s(3.0):.12f} m, s(3.01) = {s(3.01):.12f} m, exact speed 29.4 m/s; u = {sci(U)}")
fl, cl = [], []
for k in range(1, 14):
    h = 10.0 ** -k
    f, c = fwd(h), ctr(h)
    fl.append(f"{lg(f - V):.2f}"); cl.append(f"{lg(c - V):.2f}")
    print(f"h=1e-{k}: forward {f:.12f} err {sci(f - V)} = trunc {sci(4.9 * h)} + round {sci(f - V - 4.9 * h)}"
          f" (estimate {sci(2 * U * s(3.0) / h)}); central err {sci(c - V)}")
print("chart forward log10 err: " + ", ".join(fl))
print("chart central log10 err: " + ", ".join(cl))
print(f"step actually taken at h=1e-12: (3 + h) - 3 = {sci((3.0 + 1e-12) - 3.0, 6)}")
def halve(h): return (fwd(h) - fwd(h / 2)) / (fwd(h / 2) - fwd(h / 4))
q2, q12 = halve(1e-2), halve(1e-12)
print(f"halving test (change over next change, 2 if truncation rules): h=1e-2 {q2:.6f}; h=1e-12 {q12:.6f}")
for h in (1e-2, 1e-3, 1e-12):
    print(f"precision test h={sci(h, 0)}: double {fwd(h):.6f}, single {fwd32(h):.6f}, shift {sci(fwd32(h) - fwd(h))}")
print(f"stone at t=30 s, h=1e-12: forward err {sci(fwd(1e-12, 30.0) - 294.0)}, truncation still {sci(4.9e-12)}")
# cut-off series for e = 1 + 1/1! + 1/2! + ...
term, tot, ser = 1.0, 1.0, {}
for n in range(1, 21):
    term /= n; tot += term; ser[n] = tot - math.e
for n in (5, 10, 15, 16, 17, 20):
    nxt = 1.0
    for j in range(1, n + 2):
        nxt /= j
    print(f"series to 1/{n}!: err {sci(ser[n])}, next term {sci(nxt)}")
# trapezoid rule for pi = integral of 4/(1+x^2) from 0 to 1; law -h^2/6
tr = {}
for k in range(1, 8):
    n = 10 ** k
    acc = 3.0
    for i in range(1, n):
        x = i / n
        acc += 4.0 / (1.0 + x * x)
    tr[k] = acc / n - math.pi
    law = -1.0 / (6.0 * n * n)
    print(f"trapezoid n=1e{k}: err {sci(tr[k])}, law {sci(law)}, ratio {tr[k] / law + 0.0:.4f}")
# Euler steps for y' = y, y(0) = 1, to y(1) = e; law -e/(2N)
eu = {}
for k in range(1, 8):
    N = 10 ** k
    y = 1.0
    for _ in range(N):
        y += y / N
    eu[k] = y - math.e
    print(f"Euler N=1e{k}: err {sci(eu[k])}, law {sci(-math.e / (2 * N))}, ratio {eu[k] / (-math.e / (2 * N)):.6f}")
# the house example: 0.1 added ten million times (no truncation at all)
tot = 0.0
for _ in range(10 ** 7):
    tot += 0.1
bound = 10 ** 7 * U * 1e6
print(f"tracker: 0.1 added 1e7 times = {tot:.10f}, err {sci(tot - 1e6)}, bound n u total {sci(bound)}, ratio {(1e6 - tot) / bound:.3f}")
t8, y = 0.0, 1.0                                # two "Try changing" experiments
for _ in range(10 ** 7):
    t8 += 0.125; y *= 1 + 1 / 10 ** 7
print(f"try: 0.125 added 1e7 times err {sci(t8 - 1.25e6)}; Euler as y *= 1 + 1/N at N=1e7: ratio {(y - math.e) / (-math.e / 2e7):.6f}")
assert abs(fwd(1e-2) - V - 4.9e-2) < 1e-11                 # truncation is exactly 4.9h
assert abs(ctr(1e-12) - V) > 1e7 * abs(ctr(1e-2) - V)       # central: pure rounding grows
assert abs(fwd(1e-8) - V) * 1000 < abs(fwd(1e-12) - V)     # a smaller step got worse
assert abs(q2 - 2) < 1e-6 and abs(q12 - 2) > 1                # halving test tells them apart
assert fwd32(1e-12) == 0.0 and abs(fwd32(1e-2) - fwd(1e-2)) < 1e-3
assert 1.0 < -ser[10] * math.factorial(11) < 1.1 and abs(ser[20]) <= 2 * U * math.e   # tail, then floor
assert all(abs(tr[k] * 6 * 100 ** k - (-1)) < 1e-3 for k in range(1, 5)) and tr[7] > 0   # law, then flip
assert all(abs(eu[k] / (-math.e / (2 * 10 ** k)) - 1) < 2e-3 for k in range(3, 8))
assert 0 < 1e6 - tot < bound
print("ALL CHECKS PASS")
