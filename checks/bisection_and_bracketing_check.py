# Bisection and bracketing -- the check behind the card.  Standard library only.
# A $300,000 loan is repaid by 300 monthly payments of $1,800 (illustrative).
# Which yearly rate r, compounded monthly, makes the payments worth the loan?
# Road 1 halves a bracket.  Road 2 is the secant step, which keeps no bracket.
# Road 3 turns each rate back into a payment by the closed annuity formula.
# Then the floor of neighbouring doubles, the outward search, and four breaks.
import math, struct

LOAN, MONTHS = 300000.0, 300

def gap(r, pay=1800.0):                 # value today of the payments, minus the loan
    v, d, s = 1 / (1 + r / 12), 1.0, 0.0
    for _ in range(MONTHS):
        d *= v
        s += d
    return pay * s - LOAN

def payment(r):                         # road 3: closed form, L i (1+i)^N / ((1+i)^N - 1)
    i, p = r / 12, 1.0
    for _ in range(MONTHS): p *= 1 + i
    return LOAN * i * p / (p - 1)

def bisect(g, a, b, t_abs, t_rel, show=False):
    ga, k, seen = g(a), 0, [(a + b) / 2]
    while True:
        m = (a + b) / 2
        if (b - a) / 2 <= t_abs + t_rel * abs(m): return m, k, "test", seen, a, b
        if m == a or m == b: return m, k, "floor", seen, a, b
        gm = g(m)
        if gm == 0: return m, k, "zero", seen, a, b
        if (gm > 0) == (ga > 0): a, ga = m, gm
        else: b = m
        k += 1
        seen.append((a + b) / 2)
        if show and k <= 4: print(f"halving {k}: m = {100 * m:.4f}%, gap {gm:.2f}, keep [{100 * a:.4f}%, {100 * b:.4f}%]")
        if k == 3000: return m, k, "cap", seen, a, b

def steps_needed(a, b, tol):            # smallest k with (b - a) / 2^(k+1) <= tol
    k = 0
    while (b - a) / 2 ** (k + 1) > tol: k += 1
    return k

def find_bracket(g, a, b):              # step outward, doubling the width, until signs differ
    ga, gb, n = g(a), g(b), 0
    while (ga > 0) == (gb > 0) and n < 40:
        w = b - a
        if abs(ga) < abs(gb): a, b, gb = a - 2 * w, a, ga; ga = g(a)
        else: a, b, ga = b, b + 2 * w, gb; gb = g(b)
        n += 1
    return a, b, n

def secant(g, x0, x1):                  # road 2: the chord through the last two points
    g0, g1 = g(x0), g(x1)
    for _ in range(50):
        if g1 == g0: break
        x0, x1, g0 = x1, x1 - g1 * (x1 - x0) / (g1 - g0), g1
        g1 = g(x1)
    return x1

def next_double(x):                     # the double just above x > 0, from its bits
    return struct.unpack("<d", struct.pack("<q", struct.unpack("<q", struct.pack("<d", x))[0] + 1))[0]

A, B, T_ABS, T_REL = 0.01, 0.15, 1e-6, 1e-5
print(f"ends: gap(1%) = {gap(A):.2f}, gap(15%) = {gap(B):.2f}")
tol_floor = T_ABS + T_REL * A           # |m| >= 1% inside this bracket, so this tol is the least
k_pred = steps_needed(A, B, tol_floor)
print(f"promised: {k_pred} halvings, least tolerance {tol_floor:.3e}, log2 of {(B - A) / (2 * tol_floor):.1f} = {math.log2((B - A) / (2 * tol_floor)):.3f}")
r1, k1, why1, seen, a1, b1 = bisect(gap, A, B, T_ABS, T_REL, True)
bound = (b1 - a1) / 2
print(f"road 1: {k1} halvings, stopped by {why1}, rate {100 * r1:.6f}%, bound {bound:.3e}")
r2 = secant(gap, 0.05, 0.06)
print(f"road 2, secant from 5% and 6%: rate {100 * r2:.10f}%")
true1 = abs(r1 - r2)
print(f"true error {true1:.3e}, bound / true = {bound / true1:.1f}")
print(f"road 3, payment at road 1: {payment(r1):.4f}, at road 2: {payment(r2):.4f}")
print(f"cost: 2 end values + {k1} midpoints = {2 + k1} evaluations of 300 terms")
fa, fb, nb = find_bracket(gap, 0.01, 0.02)
print(f"outward from [1%, 2%]: [{100 * fa:.0f}%, {100 * fb:.0f}%] after {nb} widenings")
rf, kf, whyf, seenf, af, bf = bisect(gap, A, B, 0.0, 0.0)
print(f"floor: {kf} halvings, stopped by {whyf}, width {bf - af:.3e}, log2(0.14 / width) = {math.log2((B - A) / (bf - af)):.2f}")
print(f"floor ends are neighbours: {'yes' if next_double(af) == bf else 'no'}; floor minus road 2 = {rf - r2:.3e}")
ks = list(range(0, 41, 4))
print("chart, k:", " ".join(str(k) for k in ks))
print("chart, log10 bound:", " ".join(f"{math.log10((B - A) / 2 ** (k + 1)):.2f}" for k in ks))
print("chart, log10 true error:", " ".join(f"{math.log10(abs(seenf[k] - r2)):.2f}" for k in ks))
px = lambda r: 30 + (r - 0.01) / 0.14 * 300
br = [(0.01, 0.15)]
for m in seenf[:4]:
    lo, hi = br[-1]
    br.append((m, hi) if gap(m) > 0 else (lo, m))
print("figure, brackets in %:", " ".join(f"[{100 * lo:.4f},{100 * hi:.4f}]" for lo, hi in br))
print("figure, x pixels:", " ".join(f"{px(lo):.1f}-{px(hi):.1f}" for lo, hi in br), f"root {px(r2):.1f}")
# ---- what breaks ----
lo9 = lambda r: gap(r, 900.0)
r9 = bisect(lo9, A, B, T_ABS, T_REL)[0]
a9, b9, n9 = find_bracket(lo9, A, B)
s9 = bisect(lo9, a9, b9, T_ABS, T_REL)[0]
print(f"$900 a month: gap(1%) {lo9(A):.2f}, gap(15%) {lo9(B):.2f}; blind halving says {100 * r9:.4f}%")
print(f"  outward search: [{100 * a9:.0f}%, {100 * b9:.0f}%] after {n9}; rate {100 * s9:.4f}%")
pole = lambda r: 1 / (r - 0.07)
rp = bisect(pole, A, B, T_ABS, T_REL)[0]
print(f"jump at 7%: closes on {100 * rp:.6f}%, where the function is {pole(rp):.4e}")
ra, ka, whya = bisect(gap, A, B, 1e-20, 0.0)[:3]
print(f"t_abs = 1e-20 alone: {ka} halvings, stopped by {whya}, never by the test")
free = lambda r: gap(r, 1000.0)
rz, kz, whyz = bisect(free, -0.02, B, 0.0, T_REL)[:3]
rm, km, whym = bisect(free, -0.02, B, T_ABS, T_REL)[:3]
print(f"$1000 a month, true rate 0: t_rel alone {kz} halvings, stopped by {whyz} at {rz:.3e}")
print(f"  mixed test: {km} halvings, stopped by {whym} at {rm:.3e}")
# ---- try changing ----
print(f"try: t_abs 1e-8 and t_rel 1e-7 need {steps_needed(A, B, 1e-8 + 1e-7 * A)} halvings")
print(f"try: bracket [0%, 100%] needs {steps_needed(0.0, 1.0, T_ABS)} halvings")
r20 = bisect(lambda r: gap(r, 2000.0), A, B, T_ABS, T_REL)
print(f"try: $2,000 a month gives {100 * r20[0]:.4f}% in {r20[1]} halvings")
assert k1 == k_pred and why1 == "test"                  # the promise, kept to the step
assert true1 <= bound                                   # bisection meets secant within its bound
assert abs(payment(r2) - 1800.0) < 1e-6                 # closed form turns the rate back into $1,800
assert next_double(af) == bf and abs(rf - r2) < 1e-13   # floor: neighbouring doubles, near road 2
assert gap(fa) > 0 > gap(fb) and lo9(a9) > 0 > lo9(b9)  # the outward search really brackets
assert abs(s9 - secant(lo9, -0.01, -0.005)) < bound     # the negative rate, by secant too
assert whya == "floor" and whyz != "test" and whym == "test"
print("ALL CHECKS PASS")
