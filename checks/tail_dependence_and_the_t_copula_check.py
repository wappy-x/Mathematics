# Tail dependence and the t copula -- the check behind the card.  Standard library
# only, and nothing imported knows the answer: the normal and t curves, the root
# finder, the integrals and the random numbers are all written out below.
from math import sqrt, exp, log, pi, cos, sin, atan, acos
def Phi(x):                                  # normal CDF: series near 0, continued fraction in the tail
    if abs(x) < 3.0:
        term, total, n = x, x, 0
        while abs(term) > 1e-17 * abs(total) + 1e-300:
            n += 1
            term *= x * x / (2 * n + 1)
            total += term
        return 0.5 + total * exp(-0.5 * x * x) / sqrt(2 * pi)
    z = abs(x); f = z                        # Mills ratio by backward continued fraction
    for k in range(200, 0, -1):
        f = z + k / f
    tail = exp(-0.5 * z * z) / sqrt(2 * pi) / f
    return tail if x < 0 else 1.0 - tail
def bisect(F, p, lo, hi):                    # root finder: F increasing, F(root) = p
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if F(mid) < p else (lo, mid)
    return 0.5 * (lo + hi)
def t4_cdf(x):                               # Student t, 4 degrees of freedom, closed form
    r = sqrt(4.0 + x * x)
    one_plus_u = 4.0 / (r * (r - x)) if x < 0 else 1.0 + x / r
    return one_plus_u ** 2 * (2.0 - (one_plus_u - 1.0)) / 4.0
def t5_cdf(x):                               # Student t, 5 degrees of freedom, closed form
    th = atan(x / sqrt(5.0))
    return 0.5 + (th + sin(th) * cos(th) * (1.0 + 2.0 / 3.0 * cos(th) ** 2)) / pi
def simpson(f, a, b, n):
    h = (b - a) / n
    s = f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))
    return s * h / 3.0
def t_cdf_by_area(n, x):                     # any t curve as an area, substituting v = y / sqrt(n + y^2)
    f = lambda v: (1.0 - v * v) ** ((n - 2) / 2)
    return simpson(f, -1.0, x / sqrt(n + x * x), 4000) / simpson(f, -1.0, 1.0, 4000)
def joint_by_angle(cut, rho, student, n=20000):   # road 1: both scores below cut, as a 1-D angle integral
    al = acos(rho)
    def k(th):
        m = min(-cos(th), -cos(th - al))
        if m <= 0.0: return 0.0
        s = cut * cut / (m * m)
        return (1.0 + s / 4.0) ** -2.0 if student else exp(-0.5 * s)
    return simpson(k, pi / 2 + al, 1.5 * pi, n) / (2 * pi)
def phi(m): return exp(-0.5 * m * m) / sqrt(2 * pi)
def joint_by_factor(cut, rho, n=400):        # road 2: condition on the shared economy M
    b = sqrt(1.0 - rho)
    return simpson(lambda m: Phi((cut - sqrt(rho) * m) / b) ** 2 * phi(m), -9.0, 9.0, n)
def joint_t_by_factor(q, rho):               # road 2 for t: also average over the shared scale V = w^2
    return simpson(lambda w: w ** 3 * exp(-w * w / 2) / 2 * joint_by_factor(q * w / 2, rho, 200), 0.0, 12.0, 400)
state = [0x9E3779B97F4A7C15]
def uniform():                               # road 3: splitmix64 random numbers, written out
    state[0] = (state[0] + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state[0]
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0 + 1e-18
rho, p = 0.20, 0.05
lam_closed = 2.0 * t5_cdf(-sqrt(5.0 * (1.0 - rho) / (1.0 + rho)))
lam = lambda nu, r=rho: 2.0 * t_cdf_by_area(nu + 1, -sqrt((nu + 1) * (1.0 - r) / (1.0 + r)))
lam_area = lam(4)
a, q = bisect(Phi, p, -40.0, 0.0), bisect(t4_cdf, p, -1e6, 0.0)
jg1, jt1 = joint_by_angle(a, rho, False), joint_by_angle(q, rho, True)
jg2, jt2 = joint_by_factor(a, rho), joint_t_by_factor(q, rho)
draws, hit_g, hit_t = 400000, 0, 0
for _ in range(draws):                       # simulate the pair: two normals, one shared chi-square(4)
    r, th = sqrt(-2.0 * log(uniform())), 2.0 * pi * uniform()
    g1, g2 = r * cos(th), rho * r * cos(th) + sqrt(1 - rho * rho) * r * sin(th)
    s = sqrt(-2.0 * log(uniform() * uniform()) / 4.0)
    hit_g += (g1 < a and g2 < a); hit_t += (g1 / s < q and g2 / s < q)
mc_g, mc_t = hit_g / draws, hit_t / draws
dc = lambda j: (j - p * p) / (p * (1 - p))   # default correlation from a joint chance

print(f"rho {rho:.2f}, degrees of freedom 4, default chance each p = {p:.2f}")
print(f"lambda, Gaussian: 0 for every rho below 1")
print(f"lambda, t4, closed form        {lam_closed:.6f}")
print(f"lambda, t4, by area            {lam_area:.6f}")
arg = sqrt(5.0 * (1.0 - rho) / (1.0 + rho))
print(f"lambda pieces: 5(1-rho)/(1+rho), root, t5 area  {arg * arg:.6f} {arg:.6f} {t5_cdf(-arg):.6f}")
print(f"cutoff, normal  a = Phi^-1(p)  {a:.6f}")
print(f"cutoff, t4      q = t4^-1(p)   {q:.6f}")
print(f"joint, Gaussian, by angle      {jg1:.6f}")
print(f"joint, Gaussian, by factor     {jg2:.6f}")
print(f"joint, Gaussian, simulated     {mc_g:.6f}   ({hit_g} of {draws})")
print(f"joint, t4, by angle            {jt1:.6f}")
print(f"joint, t4, by factor and scale {jt2:.6f}")
print(f"joint, t4, simulated           {mc_t:.6f}   ({hit_t} of {draws})")
print(f"joint if independent, p*p      {p * p:.6f}")
print(f"default correlation, Gaussian  {dc(jg1):.6f}")
print(f"default correlation, t4        {dc(jt1):.6f}")
print(f"both | one, Gaussian, J/p      {jg1 / p:.6f}")
print(f"both | one, t4, J/p            {jt1 / p:.6f}")
print()
print("threshold p    Gaussian J/p   t4 J/p     t4/Gaussian")
cond = {}
for pp in (0.05, 0.01, 1e-3, 1e-4, 1e-6, 1e-8):
    aa, qq = bisect(Phi, pp, -40.0, 0.0), bisect(t4_cdf, pp, -1e6, 0.0)
    g, t = joint_by_angle(aa, rho, False) / pp, joint_by_angle(qq, rho, True) / pp
    cond[pp] = (g, t)
    print(f"{pp:<12.0e}   {g:.6f}       {t:.6f}   {t / g:10.2f}")
print("chart, Gaussian %  " + " ".join(f"{100 * cond[x][0]:.2f}" for x in cond))
print("chart, t4 %        " + " ".join(f"{100 * cond[x][1]:.2f}" for x in cond))
print("chart, t4 limit %  " + " ".join(f"{100 * lam_closed:.2f}" for x in cond))
print()
x_sen = 0.25                                 # senior layer: hit when a quarter of a large pool defaults
c = sqrt(1 - rho) * bisect(Phi, x_sen, -40.0, 40.0)
sen_g = Phi((a - c) / sqrt(rho))                  # Vasicek's curve
sen_t1 = simpson(lambda v: v * exp(-v / 2) / 4 * Phi((q * sqrt(v / 4) - c) / sqrt(rho)), 0.0, 70.0, 2000)
def v_below(m):                              # chance the scale V is small enough, for economy M = m
    z = c + sqrt(rho) * m
    if z >= 0: return 0.0
    w = 4.0 * (z / q) ** 2
    return 1.0 - exp(-w / 2) * (1 + w / 2)
sen_t2 = simpson(lambda m: phi(m) * v_below(m), -9.0, 9.0, 4000)
print(f"senior trigger: default fraction, loss at 40% recovery  {x_sen:.6f} {x_sen * 0.6:.6f}")
print(f"large pool, P(quarter default), Gaussian       {sen_g:.6f}")
print(f"large pool, P(quarter default), t4, over V     {sen_t1:.6f}")
print(f"large pool, P(quarter default), t4, over M     {sen_t2:.6f}")
print(f"large pool, t4 / Gaussian                      {sen_t1 / sen_g:.2f}")
print()
wrong_q = joint_by_angle(a, rho, True)       # t model fed the normal cutoff
print(f"wrong: normal cutoff in the t model, marginal  {t4_cdf(a):.6f}")
print(f"wrong: normal cutoff in the t model, joint     {wrong_q:.6f}")
print(f"wrong: rho read as default correlation         {rho:.6f}")
print(f"wrong: lambda read as the p = 5% chance        {jt1 / p:.6f}")
print(f"wrong: 30 degrees of freedom, lambda           {lam(30):.6f}")
print(f"try: lambda, t4, rho 0 / rho 0.5 / nu 10       {lam(4, 0.0):.6f} {lam(4, 0.5):.6f} {lam(10):.6f}")

assert abs(lam_closed - lam_area) < 1e-9,                    "two roads to lambda"
assert abs(cond[1e-8][1] - lam_closed) < 2e-3,               "deep finite threshold lands on the limit"
assert cond[1e-8][0] < 0.01 < cond[0.05][0],                 "Gaussian conditional chance drains away"
assert abs(jg1 - 0.00525) < 1e-5,                            "the shelf's house number, 0.525%"
assert abs(jg1 - jg2) < 1e-7,                                "Gaussian joint, angle vs factor"
assert abs(jt1 - jt2) < 1e-6,                                "t joint, angle vs factor-and-scale"
assert abs(mc_g - jg1) < 4 * sqrt(jg1 / draws),              "Gaussian simulation within 4 errors"
assert abs(mc_t - jt1) < 4 * sqrt(jt1 / draws),              "t simulation within 4 errors"
assert abs(sen_t1 - sen_t2) < 1e-6,                          "senior tail, two orders of integration"
assert abs(joint_by_angle(bisect(t4_cdf, 0.005, -1e6, 0.0), 0.5, True) / joint_by_angle(bisect(Phi, 0.005, -40.0, 0.0), 0.5, False) - 2.79) < 0.01, "Demarta-McNeil table: 2.79"
print("ALL CHECKS PASS")
