# Gamma and beta distributions -- the check behind the card.  Nothing imported holds the answer.
# Help desk: emails arrive at 12 per hour, rate LAM = 0.2 per minute; T = the wait for the 3rd.
# Shop page: the chance V that a visitor buys, with a Beta(2, 8) prior.  Roads: closed forms
# (the gamma integral, Poisson and binomial sums); Simpson's rule on the densities; and a
# seeded simulation that adds exponential gaps and never uses a gamma or beta formula.
from math import exp, log, sqrt, pi

LAM, K, A, B = 0.2, 3, 2, 8                  # per minute; emails; the prior's two parameters

def simpson(g, a, b, n=4000):                # Simpson's rule, n even
    h = (b - a) / n
    s = g(a) + g(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * g(a + i * h)
    return s * h / 3

def fact(n):
    out = 1
    for j in range(2, n + 1):
        out *= j
    return out

def gdens(t, k=K, lam=LAM):                  # gamma density: shape k (whole), rate lam
    return lam ** k * t ** (k - 1) * exp(-lam * t) / fact(k - 1)

def gsurv(t, k=K, lam=LAM):                  # P(T > t) = P(fewer than k emails by t), Poisson sum
    return exp(-lam * t) * sum((lam * t) ** j / fact(j) for j in range(k))

def bdens(v, a=A, b=B):                      # beta density, whole a and b: 1/B(a,b) = (a+b-1)!/((a-1)!(b-1)!)
    return fact(a + b - 1) / (fact(a - 1) * fact(b - 1)) * v ** (a - 1) * (1 - v) ** (b - 1)

def btail(v, a=A, b=B):                      # P(V > v) = P(fewer than a of a+b-1 uniforms below v)
    n = a + b - 1
    return sum(fact(n) // (fact(j) * fact(n - j)) * v ** j * (1 - v) ** (n - j) for j in range(a))

def bisect(g, target, lo, hi):               # g decreasing: find x with g(x) = target
    for _ in range(100):
        mid = (lo + hi) / 2
        lo, hi = (mid, hi) if g(mid) > target else (lo, mid)
    return (lo + hi) / 2

MASK = (1 << 64) - 1
state = 20260928                             # SplitMix64, seed 20260928
def uniform():                               # strictly between 0 and 1
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return (((z ^ (z >> 31)) >> 11) + 0.5) / 2.0 ** 53

# the gamma integral, and the three-email density built by convolution
gam = [simpson(lambda t: t ** (n - 1) * exp(-t), 0.0, 80.0, 8000) for n in (1, 2, 3, 4)]
print("gamma integral by Simpson, n = 1..4: " + ", ".join(f"{g:.6f}" for g in gam)
      + "; (n-1)! = " + ", ".join(str(fact(n - 1)) for n in (1, 2, 3, 4)))
half = 2 * simpson(lambda u: exp(-u * u), 0.0, 8.0)
print(f"Gamma(1/2) = 2 x area under exp(-u^2): {half:.6f}; sqrt(pi) = {sqrt(pi):.6f}")
conv = [simpson(lambda s: gdens(s, 2) * gdens(t - s, 1), 0.0, t) for t in (10.0, 20.0)]
print(f"3-email density at 10, 20 min: convolution {conv[0]:.6f}, {conv[1]:.6f}; "
      f"formula {gdens(10.0):.6f}, {gdens(20.0):.6f}")
# T, the wait for three emails
mean_s = simpson(lambda t: t * gdens(t), 0.0, 200.0, 8000)
var_s = simpson(lambda t: (t - mean_s) ** 2 * gdens(t), 0.0, 200.0, 8000)
median = bisect(gsurv, 0.5, 0.0, 100.0)
print(f"T: mean k/lam = {K / LAM:.3f}, by Simpson {mean_s:.3f}; variance k/lam^2 = {K / LAM ** 2:.3f}, "
      f"by Simpson {var_s:.3f}; sd {sqrt(K) / LAM:.3f}")
print(f"T: mode (k-1)/lam = {(K - 1) / LAM:.3f} min; median by bisection {median:.3f} min; "
      f"E[T^2] = k(k+1)/lam^2 = {K * (K + 1) / LAM ** 2:.3f}; one gap: mean {1 / LAM:.3f}, variance {1 / LAM ** 2:.3f}")
for t in (20.0, 30.0):
    print(f"P(T > {t:.0f}): Poisson sum {gsurv(t):.4f}; 1 - Simpson area {1 - simpson(gdens, 0.0, t):.4f}")
print(f"P(T <= 10): {1 - gsurv(10.0):.4f}; e^-4 = {exp(-4):.6f}, 13 e^-4 = {13 * exp(-4):.4f}")
# V, the conversion rate
norm_s = simpson(lambda v: v ** (A - 1) * (1 - v) ** (B - 1), 0.0, 1.0)
mean_b = A / (A + B)
var_b = A * B / ((A + B) ** 2 * (A + B + 1))
bmean_s = simpson(lambda v: v * bdens(v), 0.0, 1.0)
bvar_s = simpson(lambda v: (v - bmean_s) ** 2 * bdens(v), 0.0, 1.0)
print(f"B(2,8) by Simpson {norm_s:.6f}; 1! 7! / 9! = 1/{fact(9) // fact(7)} = {1 / 72:.6f}")
print(f"V: mean a/(a+b) = {mean_b:.4f}, by Simpson {bmean_s:.4f}; variance {var_b:.6f}, "
      f"by Simpson {bvar_s:.6f}; sd {sqrt(var_b):.4f}; mode {(A - 1) / (A + B - 2):.4f}")
print(f"P(V > 0.3): binomial sum {btail(0.3):.4f}; Simpson area {simpson(bdens, 0.3, 1.0):.4f}; "
      f"0.7^9 = {0.7 ** 9:.6f}, 9(0.3)(0.7^8) = {9 * 0.3 * 0.7 ** 8:.6f}")
lo90, hi90 = bisect(btail, 0.95, 0.0, 1.0), bisect(btail, 0.05, 0.0, 1.0)
print(f"P(V < 0.1): {1 - btail(0.1):.4f}; middle 90 percent: {lo90:.4f} to {hi90:.4f}")
for a, b in ((4, 16), (1, 1)):
    print(f"Beta({a},{b}): mean {a / (a + b):.4f}, sd {sqrt(a * b / ((a + b) ** 2 * (a + b + 1))):.4f}, "
          f"P(V > 0.3) {btail(0.3, a, b):.4f}")
# simulation: three exponential gaps for T; share of the first 2 of 10 gaps for V
N = 100_000
st, st2, t20, t30 = 0.0, 0.0, 0, 0
for _ in range(N):
    t = sum(-log(uniform()) / LAM for _ in range(K))
    st, st2, t20, t30 = st + t, st2 + t * t, t20 + (t > 20), t30 + (t > 30)
sm = st / N
ssd = sqrt(st2 / N - sm * sm)
p20, p30 = t20 / N, t30 / N
sv, sv2, v3 = 0.0, 0.0, 0
for _ in range(N):
    gaps = [-log(uniform()) for _ in range(A + B)]
    v = sum(gaps[:A]) / sum(gaps)
    sv, sv2, v3 = sv + v, sv2 + v * v, v3 + (v > 0.3)
vm = sv / N
vvar = sv2 / N - vm * vm
pv = v3 / N
print(f"simulated {N} waits and {N} shares, seed 20260928; estimate (standard error)")
print(f"  T: mean {sm:.3f} ({ssd / sqrt(N):.3f}), sd {ssd:.3f}; P(T > 20) {p20:.4f} "
      f"({sqrt(p20 * (1 - p20) / N):.4f}); P(T > 30) {p30:.4f} ({sqrt(p30 * (1 - p30) / N):.4f})")
print(f"  V: mean {vm:.4f} ({sqrt(vvar / N):.4f}), variance {vvar:.6f}; P(V > 0.3) {pv:.4f} "
      f"({sqrt(pv * (1 - pv) / N):.4f})")
# what breaks
print(f"mistake, rate 0.2 read as scale 0.2 min: mean {K * 0.2:.3f} min")
print(f"mistake, Gamma(3) read as 3! = 6: P(T > 20) {gsurv(20.0) * fact(2) / fact(3):.4f}")
print(f"mistake, one gap counted three times: variance {9 / LAM ** 2:.3f}; "
      f"P(T > 20) {exp(-LAM * 20 / 3):.4f}; P(T > 30) {exp(-LAM * 30 / 3):.4f}")
print(f"mistake, Beta(8,2) for Beta(2,8): mean {B / (A + B):.4f}; P(V > 0.3) {btail(0.3, B, A):.4f}")
print(f"mistake, second moment called the variance: {A * (A + 1) / ((A + B) * (A + B + 1)):.6f}; "
      f"squared average {mean_b ** 2:.6f}")
print(f"try: 5 emails, P(T > 20) {gsurv(20.0, 5):.4f}; 24 an hour, P(T > 20) {gsurv(20.0, 3, 0.4):.4f}; "
      f"Beta(20,80) sd {sqrt(1600 / (100 ** 2 * 101)):.4f}")
# figures
ts = [4.0 * i for i in range(11)]
vs = [0.05 * i for i in range(13)]
print("figure, minutes: " + ", ".join(f"{t:.0f}" for t in ts))
for k in (1, 2, 3):
    print(f"figure, {k} email(s): " + ", ".join(f"{gdens(t, k):.3f}" for t in ts))
print("figure, rate: " + ", ".join(f"{v:.2f}" for v in vs))
for a, b in ((1, 1), (2, 8), (4, 16)):
    print(f"figure, Beta({a},{b}): " + ", ".join(f"{bdens(v, a, b):.2f}" for v in vs))
# asserts: every one compares two independent roads
assert all(abs(gam[n - 1] - fact(n - 1)) < 1e-9 for n in (1, 2, 3, 4))
assert abs(half - sqrt(pi)) < 1e-9
assert all(abs(c - gdens(t)) < 1e-9 for c, t in zip(conv, (10.0, 20.0)))
assert abs(mean_s - K / LAM) < 1e-6 and abs(var_s - K / LAM ** 2) < 1e-5
assert abs(gsurv(20.0) - (1 - simpson(gdens, 0.0, 20.0))) < 1e-10
assert abs(norm_s - 1 / 72) < 1e-12
assert abs(bmean_s - mean_b) < 1e-10 and abs(bvar_s - var_b) < 1e-10
assert abs(btail(0.3) - simpson(bdens, 0.3, 1.0)) < 1e-10
assert abs(sm - K / LAM) < 4 * ssd / sqrt(N) and abs(p20 - gsurv(20.0)) < 4 * sqrt(p20 * (1 - p20) / N)
assert abs(vm - mean_b) < 4 * sqrt(vvar / N) and abs(pv - btail(0.3)) < 4 * sqrt(pv * (1 - pv) / N)
