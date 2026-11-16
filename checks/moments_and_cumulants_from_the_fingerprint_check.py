# Moments and cumulants -- the check behind the card.  Standard library only.
# 1,000 insured homes, money in thousands of dollars ($k).  Each home, in a
# year: no claim (0.95), a $2k leak (0.04) or a $20k fire (0.01).  Three roads
# to the cumulants of the yearly total S: add the one-home cumulants; read
# derivatives of the log-fingerprint at zero; and the exact law by convolution.
import math
N, VALS, PROBS = 1000, (0.0, 2.0, 20.0), (0.95, 0.04, 0.01)

def cumulants_from_moments(m1, m2, m3, m4):
    return (m1, m2 - m1**2, m3 - 3*m2*m1 + 2*m1**3,
            m4 - 4*m3*m1 - 3*m2**2 + 12*m2*m1**2 - 6*m1**4)

def law_of_total(p_leak, p_fire, n):      # chances of S = 0, 2, 4, ... $k
    law, p0 = [1.0], 1.0 - p_leak - p_fire
    for _ in range(n):                    # add one home at a time
        new = [0.0] * (len(law) + 10)
        for j, a in enumerate(law):
            new[j] += p0 * a; new[j + 1] += p_leak * a; new[j + 10] += p_fire * a
        law = new
    return law

def central(law):                         # mean and central moments 2, 3, 4
    m = sum(p * 2.0 * j for j, p in enumerate(law))
    c = [sum(p * (2.0 * j - m)**k for j, p in enumerate(law)) for k in (2, 3, 4)]
    return m, c[0], c[1], c[2]

def cmul(a, b): return (a[0]*b[0] - a[1]*b[1], a[0]*b[1] + a[1]*b[0])
def fingerprint_total(t):                 # phi_S(t) = phi_X(t)^1000, by squaring
    base = (sum(p * math.cos(t * v) for p, v in zip(PROBS, VALS)),
            sum(p * math.sin(t * v) for p, v in zip(PROBS, VALS)))
    out, k = (1.0, 0.0), N
    while k:
        if k & 1: out = cmul(out, base)
        base, k = cmul(base, base), k >> 1
    return out
def log_fingerprint(t):
    re, im = fingerprint_total(t)
    return (0.5 * math.log(re*re + im*im), math.atan2(im, re))

def derivs(f, h):                         # 1st to 4th derivatives at 0, differences
    f2, f1, f0, g1, g2 = f(2*h), f(h), f(0.0), f(-h), f(-2*h)
    return [(8*(f1[i] - g1[i]) - (f2[i] - g2[i])) / (12*h) for i in (0, 1)], \
           [(-f2[i] + 16*f1[i] - 30*f0[i] + 16*g1[i] - g2[i]) / (12*h*h) for i in (0, 1)], \
           [(f2[i] - 2*f1[i] + 2*g1[i] - g2[i]) / (2*h**3) for i in (0, 1)], \
           [(f2[i] - 4*f1[i] + 6*f0[i] - 4*g1[i] + g2[i]) / h**4 for i in (0, 1)]

def Phi(z):                               # bell-curve area left of z, one series
    term, s, k = z, z, 0
    while abs(term) > 1e-17:
        k += 1; term *= z * z / (2*k + 1); s += term
    return 0.5 + s * math.exp(-z * z / 2) / math.sqrt(2 * math.pi)

# road 1: one home's moments -> cumulants, then add 1,000 of them
mom = [sum(p * v**k for p, v in zip(PROBS, VALS)) for k in (1, 2, 3, 4)]
k_home = cumulants_from_moments(*mom)
k_add = [N * k for k in k_home]
# road 2: the fingerprint, logged and differentiated at t = 0; kappa_k = i^-k K^(k)(0)
d1, d2, d3, d4 = derivs(log_fingerprint, 5e-4)
k_fp = [d1[1], -d2[0], -d3[1], d4[0]]
e1, e2, _, _ = derivs(fingerprint_total, 1e-5)       # moments: phi^(k)(0) = i^k E[S^k]
# road 3: the exact law of the total, by convolution
law = law_of_total(0.04, 0.01, N)
m, c2, c3, c4 = central(law)
k_law = [m, c2, c3, c4 - 3*c2**2]

print(f"one home: E[X^k], k = 1..4     " + "  ".join(f"{x:.2f}" for x in mom))
print(f"{'cumulant':<9}{'one home':>15}{'1,000 added':>17}{'fingerprint':>17}{'exact law':>17}")
for k in range(4):
    print(f"k{k+1:<8}{k_home[k]:>15.6f}{k_add[k]:>17.4f}{k_fp[k]:>17.4f}{k_law[k]:>17.4f}")
print(f"from phi_S: E[S] = -i phi'(0)          {e1[1]:.4f}")
print(f"from phi_S: E[S^2] = -phi''(0)         {-e2[0]:.4f}")
print(f"  variance E[S^2] - E[S]^2             {-e2[0] - e1[1]**2:.4f}")
sd = math.sqrt(k_add[1])
skew = lambda k: k[2] / k[1]**1.5
kurt = lambda k: k[3] / k[1]**2
print(f"standard deviation of S, $k            {sd:.4f}")
print(f"skewness: one home, 1,000 homes        {skew(k_home):.6f}  {skew(k_law):.6f}")
print(f"excess kurtosis: one home, 1,000 homes {kurt(k_home):.6f}  {kurt(k_law):.6f}")
print("skewness by homes n = 1, 10, 100, 1000 " + " ".join(f"{skew(k_home)/math.sqrt(n):.2f}" for n in (1, 10, 100, 1000)))
print("kurtosis by homes n = 1, 10, 100, 1000 " + " ".join(f"{kurt(k_home)/n:.4f}" for n in (1, 10, 100, 1000)))
print(f"in dollars: k2 / 1e9 $^2, k3 / 1e13 $^3 {k_add[1]*1e6/1e9:.6f}  {k_add[2]*1e9/1e13:.6f}")
prof = [sum(p * (350.0 - 2.0*j - (350.0 - m))**k for j, p in enumerate(law)) for k in (2, 3, 4)]
print(f"profit 350 - S: k1..k4 from the law    {350.0 - m:.4f} {prof[0]:.4f} {prof[1]:.4f} {prof[2] - 3*prof[0]**2:.4f}")
lo, hi = 0.0, 5.0                         # z with Phi(z) = 0.995, by bisection
for _ in range(80):
    mid = (lo + hi) / 2; lo, hi = (mid, hi) if Phi(mid) < 0.995 else (lo, mid)
z = lo
g1, g2 = skew(k_add), kurt(k_add)
w1 = z + (z*z - 1) / 6 * g1
w2 = w1 + (z**3 - 3*z) / 24 * g2 - (2*z**3 - 5*z) / 36 * g1**2
cum, j995 = 0.0, 0
while cum + law[j995] < 0.995: cum += law[j995]; j995 += 1
print(f"z for 99.5%, and Phi(z) by the series  {z:.6f}  {Phi(z):.6f}")
print(f"99.5% reserve, $k: bell curve          {m + z*sd:.2f}")
print(f"  plus the skewness term               {m + w1*sd:.2f}")
print(f"  plus the kurtosis terms              {m + w2*sd:.2f}")
print(f"  exact, from the law; P(S <= it)      {2*j995:.2f}  {cum + law[j995]:.6f}")
print(f"  exact minus bell curve, minus skew   {2*j995 - (m + z*sd):.2f}  {2*j995 - (m + w1*sd):.2f}")
xs = list(range(380, 541, 20))
print("chart, total above x $k     " + " ".join(f"{x:5d}" for x in xs))
print("chart, exact law, percent   " + " ".join(f"{100*sum(law[x//2 + 1:]):5.2f}" for x in xs))
print("chart, bell curve, percent  " + " ".join(f"{100*(1 - Phi((x - m)/sd)):5.2f}" for x in xs))
# what breaks
mu4_home = k_home[3] + 3 * k_home[1]**2
print(f"wrong: 4th central moments added       {N*mu4_home:.2f}  (true {c4:.2f})")
raw3 = sum(p * (2.0*j)**3 for j, p in enumerate(law))
print(f"wrong: raw E[S^3] / sd^3 as skewness   {raw3 / sd**3:.4f}")
print(f"wrong: drop i^-k, 'variance' Re K''(0) {d2[0]:.4f}")
print(f"wrong: k3 to dollars with x1,000       {k_add[2]*1e3:.1f}")
storm = [0.9*a + 0.1*b for a, b in zip(law_of_total(0.03, 0.0075, N), law_of_total(0.13, 0.0325, N))]
sm, s2, s3, s4 = central(storm)
print(f"wrong: storm year, k1 k2 k3 of S       {sm:.4f} {s2:.4f} {s3:.4f}")
print(f"  storm year skewness                  {s3 / s2**1.5:.6f}")
for L in (1e3, 1e5, 1e7):                 # Pareto claims, index 2.5, from $10k
    print(f"Pareto 2.5: E[Y^3; Y <= {L:>8.0f} $k]   {2.5 * 10**2.5 * (math.sqrt(L) - math.sqrt(10)) / 0.5:.1f}")
die = cumulants_from_moments(*[sum(f**k for f in range(1, 7)) / 6 for k in (1, 2, 3, 4)])
print("dice: standardised total, n = 1, 10, 100: k3, k4 " + f"{die[2]:.6f} " + " ".join(f"{kurt(die)/n:.6f}" for n in (1, 10, 100)))

for a, b in zip(k_add, k_law): assert abs(a - b) < 1e-9 * abs(b), "cumulants add, against the exact law"
for a, b in zip(k_fp, k_law): assert abs(a - b) < 1e-4 * abs(b), "log-fingerprint derivatives, against the law"
assert abs(e1[1] - m) < 1e-8 * m, "E[S] from phi_S'(0), against the law"
assert abs(-e2[0] - (c2 + m*m)) < 1e-7 * (c2 + m*m), "E[S^2] from phi_S''(0), against the law"
assert abs(prof[1] + c3) < 1e-6 * c3, "flipping the sign flips k3"
assert abs(skew(k_law) * math.sqrt(N) - skew(k_home)) < 1e-9, "skewness falls as 1/sqrt(n)"
assert abs(Phi(z) - 0.5*(1 + math.erf(z/math.sqrt(2)))) < 1e-12, "series against library erf"
assert abs(m + w1*sd - 2*j995) < 1.0, "the skewness term lands within $1k of the exact reserve"
assert 2*j995 - (m + z*sd) > 10.0, "the bell curve alone under-reserves by over $10k"
assert abs(sm - m) < 1e-9 and s3 > 1.5 * c3, "storm year: same mean, cumulants no longer add"
print("ALL CHECKS PASS")
