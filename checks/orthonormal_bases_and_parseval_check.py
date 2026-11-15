# Orthonormal bases and Parseval -- the check behind the card.  Standard library only.
# The clip: one second of a 100 Hz tone at full scale 1, its negative half cut off
# by a rectifier: f(t) = max(sin(2 pi 100 t), 0).  The basis on [0, 1): the constant
# 1, and sqrt2 cos(2 pi n t), sqrt2 sin(2 pi n t) for n = 1, 2, 3, ...  Every infinite
# sum here is cut at K terms; the integrals are Simpson's rule written out, with
# grid points on every corner of the clip, where the tone crosses zero.
import math
PI, R2, F0 = math.pi, math.sqrt(2.0), 100
CELLS = 100000                                   # 1000 cells per 100 Hz cycle
TS = [i / CELLS for i in range(CELLS + 1)]
WS = [1.0 if i in (0, CELLS) else 4.0 if i % 2 else 2.0 for i in range(CELLS + 1)]

def clip(t): return max(math.sin(2 * PI * F0 * t), 0.0)
def other(t): return max(-math.sin(2 * PI * F0 * t), 0.0)   # the cut-off half
def integral(g): return sum(w * g(t) for w, t in zip(WS, TS)) / (3 * CELLS)   # over 1 s
def e(kind, n):                                  # one member of the basis
    if kind == "const": return lambda t: 1.0
    w = 2 * PI * n
    return (lambda t: R2 * math.cos(w * t)) if kind == "cos" else (lambda t: R2 * math.sin(w * t))
def coef(g, kind, n):                            # c = <e, g>, by integration
    b = e(kind, n); return integral(lambda t: b(t) * g(t))
def show(label, value): print(f"{label:<52}{value}")
def z(v): return v if abs(v) > 5e-7 else 0.0   # print 0.000000, never -0.000000

# ---- 1. the finite rehearsal: 8 samples of one cycle, 8 perpendicular patterns ----
N = 8
x = [max(math.sin(2 * PI * j / N), 0.0) for j in range(N)]
def ip8(u, v): return sum(a * b for a, b in zip(u, v)) / N       # mean of products
pats = [("constant", [1.0] * N)]
for k in range(1, N // 2):
    pats.append((f"cos {k}", [R2 * math.cos(2 * PI * k * j / N) for j in range(N)]))
    pats.append((f"sin {k}", [R2 * math.sin(2 * PI * k * j / N) for j in range(N)]))
pats.append(("alternating", [(-1.0) ** j for j in range(N)]))
worst = max(abs(ip8(p, q) - (1.0 if a == b else 0.0)) for a, p in pats for b, q in pats)
c8 = [ip8(p, x) for _, p in pats]
rebuilt = [sum(c * p[j] for c, (_, p) in zip(c8, pats)) for j in range(N)]
print("samples, one cycle   " + " ".join(f"{v:.6f}" for v in x))
print("nonzero coefficients " + ", ".join(f"{nm} {c:.6f}" for (nm, _), c in zip(pats, c8) if abs(c) > 1e-12))
print("their squares        " + ", ".join(f"{c * c:.6f}" for c in c8 if abs(c) > 1e-12))
show("rehearsal: energy, mean of squared samples", f"{ip8(x, x):.6f}")
show("rehearsal: ledger, sum of squared coefficients", f"{sum(c * c for c in c8):.6f}")
assert worst < 1e-12                                             # the 8 patterns are orthonormal
assert abs(sum(c * c for c in c8) - 0.25) < 1e-12                # Pythagoras in 8 dimensions
assert max(abs(r - v) for r, v in zip(rebuilt, x)) < 1e-12       # coefficients rebuild the samples

# ---- 2. the whole clip: coefficients by integration against the closed form ----
energy = integral(lambda t: clip(t) ** 2)
show("energy of the clip, by integration", f"{energy:.6f}")
def exact(kind, n):                              # closed-form coefficients of the clip
    if kind == "const": return 1 / PI
    if kind == "sin": return R2 / 4 if n == F0 else 0.0
    k = n // (2 * F0)
    return -R2 / (PI * (4 * k * k - 1)) if n % (2 * F0) == 0 else 0.0
print("basis member      by integration   closed form   share of energy")
for kind, n in [("const", 0), ("sin", 100), ("cos", 100), ("sin", 150),
                ("cos", 200), ("cos", 400), ("cos", 600)]:
    num, ex = coef(clip, kind, n), exact(kind, n)
    print(f"{kind + ' ' + str(n) + ' Hz':<18}{z(num):>13.6f}{ex:>14.6f}{100 * ex * ex / 0.25:>14.3f} %")
    assert abs(num - ex) < 1e-9                                  # integration agrees with closed form
assert abs(energy - 0.25) < 1e-9

# ---- 3. Bessel's ledger, cut after the cosine at 200J Hz, against the leftover ----
def ledger(J, const=True):
    return (1 / PI ** 2 if const else 0.0) + 0.125 + sum(
        2 / (PI ** 2 * (4 * k * k - 1) ** 2) for k in range(1, J + 1))
def leftover(J):                                 # energy of f - f_J, integrated directly
    def s(t):
        w = 2 * PI * F0 * t
        return 1 / PI + 0.5 * math.sin(w) - (2 / PI) * sum(
            math.cos(2 * k * w) / (4 * k * k - 1) for k in range(1, J + 1))
    return integral(lambda t: (clip(t) - s(t)) ** 2)
for J in [0, 1, 2]:
    gap, left = 0.25 - ledger(J), leftover(J)
    show(f"J = {J}: ledger, gap, leftover energy", f"{ledger(J):.6f}  {gap:.6f}  {left:.6f}")
    assert abs(gap - left) < 1e-8                                # energy = ledger + leftover
ks = [1, 2, 4, 8, 16, 32, 64]
print("chart, highest Hz kept " + ", ".join(str(200 * J) for J in ks))
print("chart, log10 of gap    " + ", ".join(f"{math.log10(0.25 - ledger(J)):.2f}" for J in ks))
show("J^3 x gap at J = 64; the rate 1/(24 pi^2)", f"{64 ** 3 * (0.25 - ledger(64)):.6f}  {1 / (24 * PI ** 2):.6f}")
tail = sum(1 / (4 * k * k - 1) ** 2 for k in range(1, 100001))
show("sum of 1/(4k^2-1)^2 to 100000; (pi^2-8)/16", f"{tail:.12f}  {(PI ** 2 - 8) / 16:.12f}")
assert abs(tail - (PI ** 2 - 8) / 16) < 1e-12                    # Parseval's equality, by series
assert abs(64 ** 3 * (0.25 - ledger(64)) * 24 * PI ** 2 - 1) < 0.05

# ---- 4. an incomplete set: drop the constant ----
for J in [1, 64]:
    show(f"constant dropped, J = {J}: ledger, gap", f"{ledger(J, False):.6f}  {0.25 - ledger(J, False):.6f}")
dc = lambda t: 1.0
show("steady level 1: <e, 1> for cos 200, sin 100", f"{z(coef(dc, 'cos', 200)):.6f}  {z(coef(dc, 'sin', 100)):.6f}")
assert 0.25 - ledger(1, False) > 0.25 - ledger(64, False) > 1 / PI ** 2   # it falls, never below 1/pi^2
assert abs(0.25 - ledger(64, False) - 1 / PI ** 2) < 1e-7        # the gap is the steady part's energy

# ---- 5. inner products survive: the two halves never overlap in time ----
ip_time = integral(lambda t: clip(t) * other(t))
oth = [(1 / PI) * (1 / PI), (R2 / 4) * (-R2 / 4)]                 # constant, sin 100
def ip_coef(J): return sum(oth) + sum(2 / (PI ** 2 * (4 * k * k - 1) ** 2) for k in range(1, J + 1))
show("<f, other half>: in time; by coefficients J=1, 64", f"{z(ip_time):.6f}  {z(ip_coef(1)):.6f}  {z(ip_coef(64)):.6f}")
assert abs(coef(other, "const", 0) - 1 / PI) < 1e-6 and abs(coef(other, "sin", 100) + R2 / 4) < 1e-6
assert abs(ip_coef(64)) < 1e-7

# ---- 6. Riesz-Fischer: which coefficient lists make a signal ----
for K in [10, 100, 1000, 10000]:
    a = sum(1 / n ** 2 for n in range(1, K + 1)); b = sum(1 / n for n in range(1, K + 1))
    show(f"energy of S_K, K = {K}: list 1/n, list 1/sqrt n", f"{a:.6f}  {b:.6f}")
da = sum(1 / n ** 2 for n in range(1001, 2001)); db = sum(1 / n for n in range(1001, 2001))
show("||S_2000 - S_1000||^2: list 1/n, list 1/sqrt n", f"{da:.6f}  {db:.6f}")
assert abs(a - PI ** 2 / 6) < 1.0001e-4 and abs(db - math.log(2)) < 1e-3

# ---- 7. what breaks ----
amps = 1 / PI + R2 / 4 + sum(R2 / (PI * (4 * k * k - 1)) for k in range(1, 100001))
sizes = 1 / PI + R2 / 4 + R2 / (2 * PI)          # telescoping: sum of 1/(4k^2-1) is 1/2
plain = [integral(clip), integral(lambda t: math.sin(2 * PI * F0 * t) * clip(t))] + [
    integral(lambda t, n=n: math.cos(2 * PI * n * t) * clip(t)) for n in range(200, 12801, 200)]
show("no sqrt2: ledger, plain cos and sin to 12800 Hz", f"{sum(c * c for c in plain):.6f}")
show("adding coefficient sizes, not squares", f"{sizes:.6f}")
assert abs(amps - sizes) < 1e-5
assert abs(sum(c * c for c in plain) - 1 / PI ** 2 - 0.5 * (0.25 - 1 / PI ** 2)) < 1e-6   # shares halved
print("ALL CHECKS PASS")
