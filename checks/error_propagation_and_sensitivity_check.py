# Error propagation and sensitivity -- the check behind the card.  Standard library only.
# A cyclist in a full-size wind tunnel: drag coefficient Cd = 2F / (rho v^2 A) from a
# measured force F, air speed v, frontal area A and air density rho, each with a
# standard uncertainty.  Road 1: partial derivatives by hand.  Road 2: partial
# derivatives by central differences, from the formula alone.  Road 3: the
# exponent rule for a product of powers.  Road 4: a Monte Carlo of 200,000 rigs,
# normal errors from a SplitMix64 generator and Box-Muller, written out here.
from math import sqrt, log, cos, pi

def cd(F, v, A, rho): return 2.0 * F / (rho * v * v * A)

X = [24.0, 12.0, 0.400, 1.204]            # F in N, v in m/s, A in m^2, rho in kg/m^3
U = [0.24, 0.18, 0.008, 0.006]            # standard uncertainties, same units
NAMES = ["F", "v", "A", "rho"]
UNITS = ["N", "m/s", "m^2", "kg/m^3"]                # partials are per this unit
EXPO = [1, -2, -1, -1]                    # Cd = 2 F^1 v^-2 A^-1 rho^-1
M64 = (1 << 64) - 1

class SplitMix64:
    def __init__(self, seed): self.s = seed
    def next(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return z ^ (z >> 31)
    def unif(self): return ((self.next() >> 11) + 1) / 9007199254740992.0   # in (0, 1]
    def normal(self):                                                     # Box-Muller, cosine half
        return sqrt(-2.0 * log(self.unif())) * cos(2.0 * pi * self.unif())

def monte_carlo(u, n, seed):
    g = SplitMix64(seed); s1 = s2 = 0.0
    for _ in range(n):
        y = cd(*[X[i] + u[i] * g.normal() for i in range(4)])
        s1 += y; s2 += y * y
    mean = s1 / n
    return mean, sqrt((s2 - n * mean * mean) / (n - 1))

c0 = cd(*X)
# road 1: partial derivatives worked by hand
d1 = [2.0 / (X[3] * X[1] ** 2 * X[2]), -4.0 * X[0] / (X[3] * X[1] ** 3 * X[2]),
      -2.0 * X[0] / (X[3] * X[1] ** 2 * X[2] ** 2), -2.0 * X[0] / (X[3] ** 2 * X[1] ** 2 * X[2])]
# road 2: central differences, step one millionth of each input
d2 = []
for i in range(4):
    h = X[i] * 1e-6; up = X[:]; dn = X[:]; up[i] += h; dn[i] -= h
    d2.append((cd(*up) - cd(*dn)) / (2.0 * h))
terms = [abs(d1[i]) * U[i] for i in range(4)]
u_quad = sqrt(sum(t * t for t in terms))
u_num = sqrt(sum((d2[i] * U[i]) ** 2 for i in range(4)))
rel = [U[i] / X[i] for i in range(4)]
u_rel = sqrt(sum((EXPO[i] * rel[i]) ** 2 for i in range(4)))      # road 3, as a fraction of Cd
share = [100.0 * t * t / u_quad ** 2 for t in terms]
# second-order mean: Cd + 1/2 sum of (second partial) u^2; second partials by hand
d2nd = [0.0, 6.0 * c0 / X[1] ** 2, 2.0 * c0 / X[2] ** 2, 2.0 * c0 / X[3] ** 2]
mean2 = c0 + 0.5 * sum(d2nd[i] * U[i] ** 2 for i in range(4))
N = 200000
mc_mean, mc_sd = monte_carlo(U, N, 20260930)

print(f"Cd = 2F/(rho v^2 A)                 {c0:10.6f}")
print(f"by hand: 2F = {2*X[0]:.3f} N, rho v^2 A = {X[3]*X[1]**2*X[2]:.4f} N")
print("input   value      u        u/value   partial dCd/dx  by differences  exponent  unit of x")
for i in range(4):
    print(f"{NAMES[i]:<6}{X[i]:8.3f}{U[i]:9.4f}{100*rel[i]:9.2f} %{d1[i]:15.6f}{d2[i]:16.6f}{EXPO[i]:8d}  {UNITS[i]}")
print("budget  term |dCd/dx| u   rel term   squared, %^2   share of variance")
for i in range(4):
    print(f"{NAMES[i]:<6}{terms[i]:12.6f}{100*abs(EXPO[i])*rel[i]:11.2f} %{(100*EXPO[i]*rel[i])**2:14.4f}{share[i]:12.2f} %")
print(f"sum of squared rel terms, %^2       {sum((100*EXPO[i]*rel[i])**2 for i in range(4)):10.4f}")
print(f"u(Cd) road 1, hand partials         {u_quad:10.6f}")
print(f"u(Cd) road 2, central differences   {u_num:10.6f}")
print(f"u(Cd) road 3, exponent rule         {u_rel * c0:10.6f}   = {100*u_rel:.3f} % of Cd")
print(f"95% band, Cd +- 2u                  {c0 - 2*u_quad:10.6f} to {c0 + 2*u_quad:.6f}")
print(f"road 4, Monte Carlo {N} rigs, seed 20260930")
print(f"  sd of Cd                          {mc_sd:10.6f}   standard error {mc_sd/sqrt(2*N):.6f}")
print(f"  mean of Cd                        {mc_mean:10.6f}   standard error {mc_sd/sqrt(N):.6f}")
print(f"  second-order mean                 {mean2:10.6f}")

# what breaks, and what to buy
lin_sum = sum(terms)
no_square = c0 * sqrt(sum((rel[i] * (1 if i == 1 else abs(EXPO[i]))) ** 2 for i in range(4)))
def rel_with(r): return 100.0 * sqrt(sum((EXPO[i] * r[i]) ** 2 for i in range(4)))
print(f"wrong: add terms, no quadrature     {lin_sum:10.6f}   = {100*lin_sum/c0:.3f} %")
print(f"wrong: speed exponent 1, not 2      {no_square:10.6f}   = {100*no_square/c0:.3f} %")
print(f"wrong: worst corner, all inputs     {cd(X[0]+U[0], X[1]-U[1], X[2]-U[2], X[3]-U[3]) - c0:10.6f}")
print(f"buy: load cell 0.1 %                {rel_with([0.001, rel[1], rel[2], rel[3]]):10.3f} %")
print(f"buy: speed 0.5 %                    {rel_with([rel[0], 0.005, rel[2], rel[3]]):10.3f} %")
print(f"buy: area 1.0 %                     {rel_with([rel[0], rel[1], 0.010, rel[3]]):10.3f} %")
# far from small: the same sweep up to a hand-held anemometer, speed uncertainty 15 %
steps = [0.0, 2.5, 5.0, 7.5, 10.0, 12.5, 15.0]
fo, sim = [], []
for p in steps:
    fo.append(rel_with([rel[0], p / 100.0, rel[2], rel[3]]))
    far_mean, far_sd = monte_carlo([U[0], p / 100.0 * X[1], U[2], U[3]], N, 20260930)
    sim.append(100.0 * far_sd / c0)
far_mean2 = c0 + 0.5 * (d2nd[1] * (0.15 * X[1]) ** 2 + d2nd[2] * U[2] ** 2 + d2nd[3] * U[3] ** 2)
print(f"far: u(v) = 15 %, first order       {fo[-1]:10.3f} %")
print(f"far: Monte Carlo sd                 {sim[-1]:10.3f} %   mean {far_mean:.6f}")
print(f"far: second-order mean              {far_mean2:10.6f}")
print("chart, u(v) %       " + " ".join(f"{p:6.1f}" for p in steps))
print("chart, first order %" + " ".join(f"{p:6.2f}" for p in fo))
print("chart, simulated %  " + " ".join(f"{p:6.2f}" for p in sim))
print("chart, shares %     " + " ".join(f"{s:6.2f}" for s in share))

for i in range(4):
    assert abs(d1[i] - d2[i]) < 1e-6 * abs(d1[i]), "hand partial vs central difference"
assert abs(u_quad - u_rel * c0) < 1e-12, "hand partials vs exponent rule"
assert abs(u_num - u_quad) < 1e-8, "central differences vs hand partials"
assert abs(mc_sd - u_quad) < 0.01 * u_quad, "simulated spread vs first-order u, within 1 %"
assert abs(mc_mean - mean2) < 4.0 * mc_sd / sqrt(N), "simulated mean vs second-order mean"
assert max(range(4), key=lambda i: share[i]) == 1, "speed dominates the budget"
assert sim[-1] > 1.05 * fo[-1], "first order fails far out"
print("ALL CHECKS PASS")
