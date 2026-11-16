# Infinitely divisible laws -- the check behind the card.  Only math is imported.
# An insurer's net result for one year, in $k (thousands of dollars):
#   X = 1500 (premiums) + 30 Z (wobble) - claims; claims arrive 365 a year,
#   each $2k (chance 0.75) or $10k (chance 0.25).  Dial t in radians per $k.
# Roads: the Levy-Khintchine exponent; the exact law of the year by counting
# the two kinds of claim; 365 exact one-day laws convolved; triplet read back
# off the one-day fingerprint.  Then tests that rule laws in or out.
import math
PI, DAYS, B, S2 = math.pi, 365, 1500.0, 900.0
NU = {-2.0: 273.75, -10.0: 91.25}                 # Levy measure: claims per year of each size
def z(v): return 0.0 if abs(v) < 5e-7 else v      # print tiny values as 0, the same in both languages
def psi(t, b, s2, nu):                            # Levy-Khintchine exponent; no jump is smaller than 1
    re = -0.5 * s2 * t * t + sum(r * (math.cos(t * x) - 1) for x, r in nu.items())
    return complex(re, b * t + sum(r * math.sin(t * x) for x, r in nu.items()))
def cexp(w): return math.exp(w.real) * complex(math.cos(w.imag), math.sin(w.imag))
LF = [0.0]                                        # log n!, summed
for n in range(1, 1400): LF.append(LF[-1] + math.log(n))
def pois(lam, n): return math.exp(-lam + n * math.log(lam) - LF[n])
def claims_law(l2, l10, cap):                     # exact law of the claims total, in units of $2k
    f = [0.0] * (cap + 1)
    for n10 in range(cap // 5 + 1):
        p10 = pois(l10, n10)
        for n2 in range(cap - 5 * n10 + 1):
            f[n2 + 5 * n10] += p10 * pois(l2, n2)
    return f
def fp(f, b, s2, t):                              # fingerprint of b + sqrt(s2) Z - 2 S from the law of S
    w = sum(p * complex(math.cos(2 * s * t), -math.sin(2 * s * t)) for s, p in enumerate(f))
    return cexp(complex(-0.5 * s2 * t * t, b * t)) * w
def Phi(x):                                       # normal CDF: positive-term series, no cancellation
    if abs(x) > 8: return 0.0 if x < 0 else 1.0
    term, tot, k = x, x, 0
    while abs(term) > 1e-17 * abs(tot) + 1e-300:
        k += 1; term *= x * x / (2 * k + 1); tot += term
    return 0.5 + math.exp(-0.5 * x * x) / math.sqrt(2 * PI) * tot
# ---- 1. the triplet and what it says ----
mean = B + sum(x * r for x, r in NU.items())
var = S2 + sum(x * x * r for x, r in NU.items())
k3, k4 = (sum(x ** k * r for x, r in NU.items()) for k in (3, 4))
print(f"year triplet: b {B:.2f}, sigma^2 {S2:.2f}, nu {NU[-2.0]:.2f} at -2, {NU[-10.0]:.2f} at -10")
print(f"mean {mean:.4f}, variance {var:.4f}, sd {math.sqrt(var):.4f}, kappa3 {k3:.1f}, kappa4 {k4:.1f}")
w = psi(0.01, B, S2, NU); ph = cexp(w)
print(f"psi(0.01) {w.real:.6f} {w.imag:+.6f} i; phi(0.01) {ph.real:.6f} {ph.imag:+.6f} i")
j2, j10 = (complex(r * (math.cos(0.01 * x) - 1), r * math.sin(0.01 * x)) for x, r in NU.items())
print(f"pieces at t = 0.01: drift +{B * 0.01:.6f} i, wobble {-0.5 * S2 * 1e-4:.6f}, $2k claims {j2.real:.6f} {j2.imag:+.6f} i, $10k claims {j10.real:.6f} {j10.imag:+.6f} i")
print(f"claims a year 365, average claim {(-mean + B) / 365:.4f}, claims total mean {B - mean:.4f}; |phi(0.01)| {abs(ph):.6f}")
# ---- 2. the exact law of the year, by counting both kinds of claim ----
year = claims_law(273.75, 91.25, 1300)
ey = sum(s * p for s, p in enumerate(year)); vy = sum(s * s * p for s, p in enumerate(year)) - ey ** 2
ex_mean, ex_var = B - 2 * ey, S2 + 4 * vy
ph2 = fp(year, B, S2, 0.01)
print(f"exact law: mass kept {sum(year):.10f}, mean {ex_mean:.4f}, variance {ex_var:.4f}")
print(f"exact law: phi(0.01) {ph2.real:.6f} {ph2.imag:+.6f} i, gap to formula below 1e-9: {'yes' if abs(ph2 - ph) < 1e-9 else 'no'}")
assert abs(ex_mean - mean) < 1e-6 and abs(ex_var - var) < 1e-4 and abs(ph2 - ph) < 1e-9
# ---- 3. split into days: 365 one-day laws convolved give the year ----
day = claims_law(0.75, 0.25, 60)
print(f"one day: b {B / DAYS:.6f}, sigma^2 {S2 / DAYS:.6f}, nu 0.75 at -2, 0.25 at -10; mean {mean / DAYS:.6f}, variance {var / DAYS:.6f}")
print(f"one day: no claim {day[0]:.6f}, one $2k claim {day[1]:.6f}, mass kept up to $120k {sum(day):.10f}")
conv = [1.0] + [0.0] * 1300
for _ in range(DAYS):
    new = [0.0] * 1301
    for j, dj in enumerate(day):
        if dj > 1e-300:
            for s in range(1301 - j): new[s + j] += dj * conv[s]
    conv = new
gap = max(abs(a - c) for a, c in zip(year, conv))
print(f"365 days convolved against the year counted: largest gap in a chance below 1e-12: {'yes' if gap < 1e-12 else 'no'}")
assert gap < 1e-12
# ---- 4. read drift, wobble and jumps back off the one-day fingerprint ----
M = 2048; ts = [PI * m / M for m in range(M + 1)]
lg, prev = [], None
for t in ts:                                      # continuous logarithm: unwrap the angle along t
    v = fp(day, B / DAYS, S2 / DAYS, t); a = math.atan2(v.imag, v.real)
    if prev is not None: a += 2 * PI * round((prev - a) / (2 * PI))
    lg.append(complex(math.log(abs(v)), a)); prev = a
b_read, s2_read = lg[M].imag / PI * DAYS, -2 * lg[M].real / PI ** 2 * DAYS
jump = [lg[m] - complex(-0.5 * s2_read / DAYS * t * t, b_read / DAYS * t) for m, t in enumerate(ts)]
nu_read = {2 * k: DAYS * sum(jump[m] * complex(math.cos(2 * k * ts[m]), math.sin(2 * k * ts[m])) for m in range(M)).real / M for k in (1, 2, 5)}
print(f"read back at t = pi: b {b_read:.4f}, sigma^2 {s2_read:.4f}")
print(f"read back by inversion: nu at -2 {z(nu_read[2]):.4f}, at -4 {z(nu_read[4]):.4f}, at -10 {z(nu_read[10]):.4f}")
assert abs(b_read - B) < 1e-6 and abs(s2_read - S2) < 1e-6 and abs(nu_read[2] - 273.75) < 1e-4 and abs(nu_read[10] - 91.25) < 1e-4
gaps = []
for n in (365, 8760):                             # n (phi_n - 1): a compound Poisson exponent, tending to psi
    cp = n * (cexp(w / n) - 1); gaps.append(abs(cp - w))
    print(f"n = {n}: n(phi_n - 1) at 0.01 {cp.real:.6f} {cp.imag:+.6f} i, gap to psi {abs(cp - w):.6f}")
assert abs(gaps[0] / gaps[1] - 8760 / 365) < 0.1 and abs(gaps[0] - abs(w) ** 2 / (2 * 365)) < 1e-6   # gap about |psi|^2 / 2n
# ---- 5. what the insurer reads off: chance of a losing year ----
p_loss = sum(p * Phi((2 * s - B) / math.sqrt(S2)) for s, p in enumerate(year))
p_norm = Phi(-mean / math.sqrt(var))
print(f"chance of a losing year: exact {p_loss:.6f}, bell curve with the same mean and sd {p_norm:.6f}")
TC, MI = 0.4, 4000                                # second road: Gil-Pelaez inversion of the exponent, cut at t = TC
gp = lambda t: mean if t == 0 else cexp(psi(t, B, S2, NU)).imag / t   # Im phi(t) / t, which tends to the mean
simp = sum((1 if m in (0, MI) else 4 if m % 2 else 2) * gp(TC * m / MI) for m in range(MI + 1))
p_inv = 0.5 - TC / MI / 3 * simp / PI             # |phi(t)| <= exp(-450 t^2) bounds the tail past TC
print(f"chance of a losing year by inverting the exponent: {p_inv:.6f} (t up to {TC}, tail below {math.exp(-0.5 * S2 * TC * TC) / (S2 * TC * TC):.1e})")
assert abs(p_inv - p_loss) < 1e-8
# ---- 6. tests that rule a law out ----
die = lambda t: abs(sum(complex(math.cos(k * t), math.sin(k * t)) for k in range(1, 7))) / 6
print(f"one die: |phi| at pi/3 {z(die(PI / 3)):.6f}, at 2pi/3 {z(die(2 * PI / 3)):.6f}; ten dice standardised, zero at t = {PI / 3 * math.sqrt(10 * 35 / 12):.6f}")
lo, hi, vf = 365 * 2, 365 * 10, 365 * (0.75 * 4 + 0.25 * 100 - 16)
print(f"exactly one claim a day: range {lo} to {hi}, variance {vf:.1f}, kappa4 {365 * 8 ** 4 * 0.1875 * (1 - 6 * 0.1875):.1f}")
print(f"  n pieces need variance <= {hi - lo}^2/(4n): impossible from n = {math.floor((hi - lo) ** 2 / (4 * vf)) + 1}")
f = [0.8, 0.2, 0.0, 0.0]; g = [math.sqrt(f[0])]   # square root of a 0-or-1 claim count, as a power series
for k in range(1, 4): g.append((f[k] - sum(g[j] * g[k - j] for j in range(1, k))) / (2 * g[0]))
closed = math.sqrt(f[0]) * (0.5 * -0.5 / 2) * (f[1] / f[0]) ** 2   # binomial series of sqrt(f0 + f1 s)
print(f"half of a 0-or-1 count (chance {f[1]:.1f}): 'chances' {g[0]:.6f} {g[1]:.6f} {g[2]:.6f} {g[3]:.6f}; closed form at 2: {closed:.6f}")
assert abs(g[2] - closed) < 1e-12 and g[2] < 0
assert die(PI / 3) < 1e-12 and abs(Phi(-0.4) - 0.5 * (1 + math.erf(-0.4 / math.sqrt(2)))) < 1e-14   # library cross-check
# ---- 7. what breaks ----
print(f"breaks: mean read as b {B:.4f} (right {mean:.4f}); wobble read as all the variance {var:.4f} (right {S2:.4f})")
print(f"breaks: day as X/365, variance {var / DAYS ** 2:.6f} (right {var / DAYS:.6f})")
# ---- 8. the picture: |fingerprint| of one day's claims and of one die ----
print("chart: t, |phi| one day of claims, |phi| one die")
for k in range(13):
    t = PI * k / 12
    print(f"{t:.4f} {math.exp(0.75 * (math.cos(2 * t) - 1) + 0.25 * (math.cos(10 * t) - 1)):.4f} {z(die(t)):.4f}")
print("ALL CHECKS PASS")
