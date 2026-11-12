# When to stop -- the check behind the card.  Standard library only.
# Two roots.  The yield of a 7-day bill, where the price curve is nearly flat,
# and the rate of a 25-year mortgage, reached by slow fixed-point steps.  The
# iterations use only + - * /, so Python and Rust print the same digits.
import math
def sci(x, d=3):                              # 1.234e-5, the way Rust prints it
    m, e = f"{x:.{d}e}".split("e"); return f"{m}e{int(e)}"
def pw(b, n):                                 # b to the power n, by repeated multiplying
    r = 1.0
    for _ in range(n): r *= b
    return r
TA, TR = 1e-12, 1e-9                          # absolute floor and relative tolerance
# ---- the flat curve: a bill paying $100 after `days` days, simple yield y a year ----
def bill(y, days): return 100.0 / (1.0 + y * days / 365.0)
def bill_slope(y, days):
    t = days / 365.0; return -100.0 * t / ((1.0 + y * t) * (1.0 + y * t))
def residual_stop(days, quote, cent):        # bisection, stopped on the residual alone
    lo, hi, rows = 0.0, 0.10, []
    while True:
        m = (lo + hi) / 2; r = bill(m, days) - quote; rows.append((m, r))
        if abs(r) <= cent: return m, rows
        lo, hi = (m, hi) if r > 0 else (lo, m)
def newton(days, quote, y, ta, tr, cap=50):  # Newton, stopped on the step
    for k in range(1, cap + 1):
        s = -(bill(y, days) - quote) / bill_slope(y, days); y += s
        if abs(s) <= ta + tr * abs(y): return y, k, s
    return y, cap, s
Q = bill(0.04, 7)
ystar = (100.0 - Q) / Q * 365.0 / 7          # road 1: the closed form
print(f"bill: 7 days, pays 100, quote {Q:.9f} at 4% (illustrative), t = {7/365:.9f} years")
ys, rows = residual_stop(7, Q, 0.01)
for k, (m, r) in enumerate(rows, 1):
    print(f"bisection step {k}: yield {100*m:.6f} %, price {bill(m, 7):.6f}, residual {r:.6f}")
sl = bill_slope(ys, 7); est = abs(rows[-1][1] / sl)
print(f"one-cent residual test stops at {100*ys:.6f} %, true {100*ystar:.6f} %, error {100*(ystar-ys):.6f} points")
print(f"slope at the stop {sl:.6f} $ per unit yield; residual/slope estimates {100*est:.6f} points")
yn, kn, sn = newton(7, Q, ys, TA, TR)        # road 2: Newton, stopped on its step
print(f"Newton from the stop: first step to {100*(ys+est):.6f} %; {kn} steps in all, yield {100*yn:.9f} %, error {sci(yn-ystar)}")
assert abs(ys - 0.0375) < 1e-15 and abs((ystar - ys) - 0.0025) < 1e-12   # the false stop
assert abs(yn - ystar) < 1e-14 and abs(est - (ystar - ys)) < 1e-6
# ---- the house example: a 25-year mortgage, 300 monthly payments ----
L, N = 300000.0, 300
def mortgage(M, tr, show):
    def F(i): return M * (1.0 - 1.0 / pw(1.0 + i, N)) / i - L   # dollars over or short
    def Fp(i):
        v = 1.0 / pw(1.0 + i, N); return M * (N * v / (1.0 + i) / i - (1.0 - v) / (i * i))
    def g(i): return M / L * (1.0 - 1.0 / pw(1.0 + i, N))         # the fixed-point form
    i = 0.002                                 # road 1: Newton on the dollar residual
    for _ in range(8): i -= F(i) / Fp(i)
    lo, hi = 0.001, 0.008                     # road 2: bisection, 60 halvings
    for _ in range(60):
        mid = (lo + hi) / 2; lo, hi = (lo, mid) if F(mid) < 0 else (mid, hi)
    q = M / L * N / pw(1.0 + i, N + 1)        # g'(i*), the slow factor
    x = [M / L]                               # road 3: the fixed-point steps
    for _ in range(160): x.append(g(x[-1]))
    assert abs(lo - i) < 1e-12 * i and abs(x[-1] - i) < 1e-12 * i
    def stop(est):                            # first k whose error estimate passes
        for k in range(2, 161):
            s = x[k] - x[k - 1]; qh = s / (x[k - 1] - x[k - 2])
            if abs(est(s, qh)) <= TA + tr * abs(x[k]): return k, qh
    kp, _ = stop(lambda s, qh: s)
    kc, qc = stop(lambda s, qh: qh / (1 - qh) * s)
    rp, rc = abs(x[kp] - i) / i, abs(x[kc] - i) / i
    over = abs(x[kp] - i) / (TA + tr * i)    # true error over the error promised
    if show: return i, q, x, Fp(i), kp, rp, over, kc, qc, rc, g
    return q, kp, over, kc
M = 1271.56
istar, q, x, slope, kp, rp, over, kc, qc, rc, g = mortgage(M, 1e-6, True)
print(f"mortgage: loan 300000, 300 payments of {M:.2f}; rate {istar:.15f} a month, {1200*istar:.6f} % a year")
print(f"slope {slope:.1f} $ per unit monthly rate; one cent of residual moves the annual rate {sci(0.01/abs(slope)*1200)} points")
print(f"same cent on the bill: {100*0.01/abs(bill_slope(ystar, 7)):.6f} points, {(0.01/abs(bill_slope(ystar, 7)))/(0.01/abs(slope)*12):.0f} times as much")
print(f"q = g'(i*) = {q:.6f}, q/(1-q) = {q/(1-q):.6f}")
print(f"error promised at tau_r 1e-6: {sci(TA + 1e-6 * istar)}; condition number: bill {Q/(ystar*abs(bill_slope(ystar, 7))):.1f}, mortgage {L/(istar*abs(slope)):.2f}")
for k in (1, 2, 3, 10, 20, 30, 40):
    st = x[k] - x[k - 1]
    print(f"k={k}: rate {1200*x[k]:.9f} %, error {sci(x[k]-istar)}, step {sci(st)}, error/step {(x[k]-istar)/st:.4f}")
s = x[kp] - x[kp - 1]; qh = s / (x[kp - 1] - x[kp - 2])
print(f"plain step test, tau_r 1e-6: stops at k={kp}, step {sci(s)}, q-hat {qh:.6f}, estimate {sci(-qh/(1-qh)*s)}, true {sci(x[kp]-istar)}")
print(f"  relative error {sci(rp)}, {over:.2f} times the error promised")
print(f"corrected test: stops at k={kc}, q-hat {qc:.6f}, relative error {sci(rc)}")
assert over > 1 and rp > 1e-6 and rc <= 1e-6 and abs(qc - q) < 1e-4
def aitken(k):                                # from x_k, x_k+1, x_k+2
    d1, d2 = x[k + 1] - x[k], x[k + 2] - x[k + 1]; den = d2 - d1
    return x[k + 2] - d2 * d2 / den if den != 0.0 else float("nan")
for k in (0, 10, 20, 30):
    print(f"Aitken from x{k}, x{k+1}, x{k+2}: error {sci(aitken(k)-istar)}; plain x{k+2}: {sci(x[k+2]-istar)}")
assert abs(aitken(20) - istar) < abs(x[22] - istar) / 100
z, ev = M / L, 0                              # Steffensen: Aitken, then restart from it
while True:
    g1 = g(z); g2 = g(g1); ev += 2
    d1, d2 = g1 - z, g2 - g1; zn = g2 - d2 * d2 / (d2 - d1)
    if abs(zn - z) <= TA + 1e-6 * abs(zn): break
    z = zn
print(f"Steffensen: {ev} evaluations of g, relative error {sci(abs(zn-istar)/istar)}; plain needs {kc}")
assert abs(zn - istar) / istar < 1e-9 and ev < kc / 3
d112 = (x[114] - x[113]) - (x[113] - x[112])
print(f"Aitken in the noise, k=104: error {sci(aitken(104)-istar)}; plain x106: {sci(x[106]-istar)}; k=112 divides by {sci(d112)}")
ks = range(5, 41, 5)
print("chart k:", " ".join(str(k) for k in ks))
print("chart log10 error:", " ".join(f"{math.log10(abs(x[k]-istar)):.2f}" for k in ks))
print("chart log10 step:", " ".join(f"{math.log10(abs(x[k]-x[k-1])):.2f}" for k in ks))
print("chart log10 Aitken:", " ".join(f"{math.log10(abs(aitken(k-2)-istar)):.2f}" for k in ks))
yz, kz, sz = newton(7, 100.0, 0.04, 0.0, TR)
yb, kb, sb = newton(7, 100.0, 0.04, TA, TR)
print(f"zero-yield quote, relative test only: {kz} steps (the cap), last step {sci(sz)}; with the floor: {kb} steps")
assert kz == 50 and kb < 10
y91, _ = residual_stop(91, bill(0.04, 91), 0.01)
print(f"try 91 days: one-cent residual test stops at {100*y91:.6f} %, error {100*(0.04-y91):.6f} points")
q6, kp6, x6, kc6 = mortgage(1932.90, 1e-6, False)
print(f"try 6 %, payment 1932.90: q {q6:.6f}, plain stops k={kp6} at {x6:.2f} times the error promised, corrected k={kc6}")
q9, kp9, x9, kc9 = mortgage(M, 1e-9, False)
print(f"try tau_r 1e-9: plain stops k={kp9} at {x9:.2f} times the error promised, corrected k={kc9}")
print("ALL CHECKS PASS")
