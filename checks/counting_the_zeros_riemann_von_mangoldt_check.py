# Counting the zeros -- the check behind the card.  Standard library only.
# Road 1: the Riemann-von Mangoldt count N(T) = 1 + theta(T)/pi + S(T): theta
# from Stirling's series for log Gamma, S(T) = arg zeta(1/2 + iT)/pi followed
# step by step along a line.  Road 2: count the sign changes of Hardy's Z(t),
# which is real on the critical line, with two independent evaluators.
import math, cmath
PI = math.pi
B = [1/6, -1/30, 1/42, -1/30, 5/66, -691/2730, 7/6, -3617/510, 43867/798, -174611/330]

def zeta(s):                     # Euler-Maclaurin summation, n0 > |Im s|/4
    n0 = int(abs(s.imag) / 4) + 20
    tot = sum(n ** -s for n in range(1, n0)) + n0 ** (1 - s) / (s - 1) + n0 ** -s / 2
    term, fact = s * n0 ** (-s - 1), 2.0
    for k in range(1, 11):       # Bernoulli corrections B_2k/(2k)! s(s+1)..(s+2k-2)
        tot += B[k - 1] / fact * term
        term *= (s + 2 * k - 1) * (s + 2 * k) / n0 ** 2
        fact *= (2 * k + 1) * (2 * k + 2)
    return tot

def theta(t):                    # arg Gamma(1/4 + it/2) - (t/2) log pi, exactly
    z, shift = complex(0.25, t / 2), 0.0
    for _ in range(10):          # Gamma(z) = Gamma(z + 10) / (z (z+1) ... (z+9))
        shift += cmath.phase(z); z += 1
    lg = (z - 0.5) * cmath.log(z) - z + 1 / (12 * z) - 1 / (360 * z ** 3) + 1 / (1260 * z ** 5)
    return lg.imag - shift - t / 2 * math.log(PI)

def theta_series(t):             # the same angle from the asymptotic series
    return t / 2 * math.log(t / (2 * PI)) - t / 2 - PI / 8 + 1 / (48 * t) + 7 / (5760 * t ** 3)

def z_em(t):                     # Hardy's Z(t) = e^{i theta(t)} zeta(1/2 + it)
    return (cmath.exp(1j * theta(t)) * zeta(complex(0.5, t))).real

def z_rs(t):                     # Riemann-Siegel: about sqrt(t/2pi) cosines
    a = math.sqrt(t / (2 * PI)); m = int(a); p = a - m
    tot = sum(math.cos(theta_series(t) - t * math.log(n)) / math.sqrt(n) for n in range(1, m + 1))
    if abs(math.cos(2 * PI * p)) < 1e-9: p += 1e-7      # removable 0/0
    c0 = math.cos(2 * PI * (p * p - p - 1 / 16)) / math.cos(2 * PI * p)
    return 2 * tot + (-1) ** (m - 1) * c0 / math.sqrt(a)

def S(T, steps=300):             # arg zeta along 2 + iT -> 1/2 + iT, from Re > 0
    w = zeta(complex(2, T)); ang = cmath.phase(w)
    for i in range(1, steps + 1):
        w2 = zeta(complex(2 - 1.5 * i / steps, T)); ang += cmath.phase(w2 / w); w = w2
    return ang / PI

def scan(fn, h, hi=1000.0, lo=10.0):   # sign changes of fn on lo, lo+h, ..., hi
    n = round((hi - lo) / h); prev, count, at = fn(lo), 0, [0]
    for i in range(1, n + 1):
        v = fn(lo + i * h); count += (v > 0) != (prev > 0); prev = v; at.append(count)
    return count, at

def smooth(T): return 1 + theta(T) / PI
def main(T): return T / (2 * PI) * math.log(T / (2 * PI)) - T / (2 * PI) + 7 / 8
T = 1000.0
n_em, at_em = scan(z_em, 0.05)
n_rs, at_rs = scan(z_rs, 0.02)
road1 = smooth(T) + S(T)
print("height T = 1000")
print(f"smooth part 1 + theta(T)/pi = {smooth(T):.6f}")
print(f"main term (T/2pi)log(T/2pi) - T/2pi + 7/8 = {main(T):.6f}; dropped Stirling term 1/(48 pi T) = {1 / (48 * PI * T):.6f}")
u = T / (2 * PI); z2 = zeta(complex(2, 0)).real - 1
print(f"by hand: T/2pi = {u:.6f}, log = {math.log(u):.6f}, product = {u * math.log(u):.4f}, minus T/2pi = {u * math.log(u) - u:.4f}")
print(f"theta(1000) = {theta(T):.4f}; on Re s = 2, |zeta - 1| <= {z2:.6f}, so |arg|/pi < {math.asin(z2) / PI:.4f}")
print(f"S(T) = arg zeta(1/2 + iT)/pi = {S(T):.6f}")
print(f"road 1: N(T) = smooth part + S(T) = {road1:.6f}")
print(f"road 1 at T = 10: {round(smooth(10) + S(10))}")
print(f"road 2a: sign changes of Z, Euler-Maclaurin, step 0.05 = {n_em}")
print(f"road 2b: sign changes of Z, Riemann-Siegel, step 0.02 = {n_rs}")
print(f"Z(1000): Euler-Maclaurin {z_em(T):.6f}, Riemann-Siegel {z_rs(T):.6f}")
assert abs(theta(T) - theta_series(T)) < 1e-9 and abs(theta(50) - theta_series(50)) < 1e-9
assert abs(road1 - round(road1)) < 1e-6 and round(road1) == n_em == n_rs
assert abs(z_em(T) - z_rs(T)) < 1e-2 and abs(smooth(10) + S(10)) < 1e-6
print("T, smooth part, S(T), road 1, road 2a, road 2b")
for T2 in (100, 200, 500, 1000):
    r1 = smooth(T2) + S(T2); e, r = at_em[round((T2 - 10) / 0.05)], at_rs[round((T2 - 10) / 0.02)]
    print(f"{T2}, {smooth(T2):.4f}, {S(T2):.4f}, {r1:.4f}, {e}, {r}")
    assert abs(r1 - e) < 1e-6 and e == r

zeros = []                       # bisect every bracket found by road 2b
for i in range(1, len(at_rs)):
    if at_rs[i] > at_rs[i - 1]:
        a, b = 10 + (i - 1) * 0.02, 10 + i * 0.02
        for _ in range(40):
            m = (a + b) / 2
            if (z_em(m) > 0) == (z_em(a) > 0): a = m
            else: b = m
        zeros.append((a + b) / 2)
gaps = [zeros[k + 1] - zeros[k] for k in range(len(zeros) - 1)]
print(f"first zero {zeros[0]:.6f}; zero number 649 at {zeros[-1]:.6f}")
print(f"last three zeros below 1000: {zeros[-3]:.4f}, {zeros[-2]:.4f}, {zeros[-1]:.4f}")
print(f"density near 1000: log(T/2pi)/2pi = {math.log(T / (2 * PI)) / (2 * PI):.6f} zeros per unit height")
print(f"mean gap near 1000: 2pi/log(T/2pi) = {2 * PI / math.log(T / (2 * PI)):.6f}")
k9 = at_em[round(890 / 0.05)]
print(f"zeros between 900 and 1000: {n_em - k9}, smooth part predicts {smooth(1000) - smooth(900):.4f}")
print(f"their average gap = {(zeros[-1] - zeros[k9]) / (n_em - k9 - 1):.6f}")
lo, near = min(gaps), gaps[k9:]
print(f"smallest gap below 1000 = {lo:.4f}, from the zero at {zeros[gaps.index(lo)]:.4f}")
print(f"gaps between 900 and 1000: smallest {min(near):.4f}, largest {max(near):.4f}")
assert abs((n_em - k9) - (smooth(1000) - smooth(900))) < 2 and len(zeros) == 649
for T2 in (100, 10 ** 4, 10 ** 6, 10 ** 9):
    print(f"predicted at T = {T2}: main term {main(T2):.1f}, mean gap {2 * PI / math.log(T2 / (2 * PI)):.4f}")
r4 = smooth(1e4) + S(1e4)        # road 1 at T = 10^4, where rounding the main term fails
print(f"road 1 at T = 10000: smooth part {smooth(1e4):.4f} + S(T) {S(1e4):.4f} = {r4:.4f}")

print("chart, T from 950 to 1000 in steps of 2.5: count, smooth part")
print("count:", ", ".join(str(at_em[round((950 + 2.5 * j - 10) / 0.05)]) for j in range(21)))
print("smooth:", ", ".join(f"{smooth(950 + 2.5 * j):.2f}" for j in range(21)))
sv = [(at_em[round((t - 10) / 0.05)] - smooth(t), t) for t in range(15, 1001)]
worst = max(sv, key=lambda x: abs(x[0]))
wrong = sum(1 for s, t in sv if round(smooth(t)) != at_em[round((t - 10) / 0.05)])
print(f"S(T) at whole T from 15 to 1000: largest |S| = {abs(worst[0]):.4f} at T = {worst[1]}")
print(f"mistake, round the smooth part and drop S(T): wrong at {wrong} of {len(sv)} heights")
wl = T / (2 * PI) * math.log(T) - T / (2 * PI) + 7 / 8
print(f"mistake, log T for log(T/2pi): {wl:.2f}")
print(f"mistake, drop the 7/8: {main(T) - 7 / 8:.2f}")
c1, c5 = scan(z_rs, 1.0)[0], scan(z_rs, 0.5)[0]
print(f"mistake, scan Z in steps of 1.0: {c1}; steps of 0.5: {c5}")
assert c1 < n_rs and c5 < n_rs and wrong > 0 and abs(wl - n_em) > 100
assert abs(r4 - round(r4)) < 1e-4 and round(r4) == 10142 != round(main(1e4))   # the known count N(10^4)
print("ALL CHECKS PASS")
