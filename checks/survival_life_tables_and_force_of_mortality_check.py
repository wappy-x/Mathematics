# Life tables and the force of mortality -- the check behind the card.  Standard library only.
# Mortality basis: Makeham's law mu(x) = A + B c^x with the Standard Ultimate Survival Model
# parameters.  The 10,000 policyholders aged 40 are the shelf's life office.
from math import exp, log

A, B, C = 0.00022, 2.7e-6, 1.124
X0, N0, TOP = 40, 10000.0, 130                 # start age, radix (lives at 40), last age in the table

def mu(x): return A + B * C ** x               # force of mortality at exact age x, per year

def simpson(f, a, b, n=200):                   # our own integrator; n must be even
    h = (b - a) / n
    s = f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))
    return s * h / 3.0

def surv_closed(x, t, a=A, b=B, c=C):          # road 1: the exponent integrated by hand
    return exp(-a * t - b / log(c) * c ** x * (c ** t - 1.0))

# road 2: build the life table year by year, integrating mu numerically inside each year
l = {X0: N0}
for x in range(X0, TOP):
    l[x + 1] = l[x] * exp(-simpson(mu, x, x + 1, 20))
p = {x: l[x + 1] / l[x] for x in range(X0, TOP)}
q = {x: 1.0 - p[x] for x in p}
d = {x: l[x] - l[x + 1] for x in p}

# road 3: simulate the 10,000 lives month by month using only the definition of mu
state = 20260928
def rnd():                                     # splitmix64, top 53 bits -> [0, 1)
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) * 2.0 ** -53
DT = 1.0 / 12.0
lives = []
for i in range(int(N0)):
    m = 0
    while m < 12 * (TOP - X0) and rnd() >= mu(X0 + (m + 0.5) * DT) * DT:
        m += 1
    lives.append((m + 0.5) * DT)
alive65 = sum(1 for t in lives if t > 25.0)

p25 = surv_closed(40, 25)
print("chance a 40-year-old reaches 65")
print(f"  1 closed form exp(-integral)     {p25:.6f}")
print(f"  2 life table l65 / l40           {l[65] / l[40]:.6f}")
print(f"  3 simulated, of 10,000 at 40     {alive65 / N0:.6f}  ({alive65} lives)")
print(f"  expected survivors of 10,000     {N0 * p25:.2f}")
g = B / log(C) * C ** 40 * (C ** 25 - 1.0)
print(f"  by hand: ln c {log(C):.6f}   B / ln c, times 10^5 {1e5 * B / log(C):.6f}")
print(f"  by hand: c^40 {C ** 40:.4f}   c^25 - 1 {C ** 25 - 1:.4f}")
print(f"  by hand: Gompertz part {g:.6f}   Makeham part {A * 25:.6f}   total {g + A * 25:.6f}")
print("life table, radix 10,000 at age 40")
print("  age      q_x        l_x       d_x     mu_x")
for x in (40, 50, 60, 64, 65, 66, 80, 90, 100):
    print(f"  {x:>3} {q[x]:>10.6f} {l[x]:>10.2f} {d[x]:>9.2f} {mu(x):>8.6f}")
e_curt = sum(l[X0 + k] for k in range(1, TOP - X0 + 1)) / N0
e_curt_d = sum(k * d[X0 + k] for k in range(TOP - X0)) / N0
e_comp = simpson(lambda t: surv_closed(40, t), 0.0, 90.0, 2000)
e_sim = sum(lives) / N0
se_sim = (sum((t - e_sim) ** 2 for t in lives) / (N0 - 1) / N0) ** 0.5
print("life expectancy at 40, years")
print(f"  curtate, sum of l(40+k)/l40      {e_curt:.6f}")
print(f"  curtate, sum of k d(40+k)/l40    {e_curt_d:.6f}")
print(f"  complete, integral of survival   {e_comp:.6f}")
print(f"  curtate + 1/2                    {e_curt + 0.5:.6f}")
print(f"  expected age at death, 40 + e    {40 + e_comp:.6f}")
print(f"  complete, simulated mean         {e_sim:.6f}  (standard error {se_sim:.6f})")
mu65_tab = (log(l[64]) - log(l[66])) / 2.0
print("force of mortality at 65, per year")
print(f"  formula A + B c^65               {mu(65):.6f}")
print(f"  from table (ln l64 - ln l66)/2   {mu65_tab:.6f}")
print(f"  q65 for comparison               {q[65]:.6f}")
print(f"  ratio mu65 / mu40 {mu(65) / mu(40):.2f}   c^10, growth per decade {C ** 10:.4f}")
# Gompertz fit: least squares of ln(-ln p_x) on the year's midpoint, ages 40..99
xs = [x + 0.5 for x in range(40, 100)]
ys = [log(-log(p[x])) for x in range(40, 100)]
mx, my = sum(xs) / len(xs), sum(ys) / len(ys)
slope = sum((u - mx) * (v - my) for u, v in zip(xs, ys)) / sum((u - mx) ** 2 for u in xs)
cg, bg = exp(slope), exp(my - slope * mx)
pg = surv_closed(40, 25, 0.0, bg, cg)
print("Gompertz fit to the table, ages 40 to 99")
print(f"  fitted B, times 10^6 {1e6 * bg:.6f}   fitted c {cg:.6f}")
print(f"  doubling time ln2 / ln c, years  {log(2) / log(cg):.6f}")
print(f"  25p40 under the fit              {pg:.6f}")
print(f"  mu40 fit {bg * cg ** 40:.6f}   table {mu(40):.6f}")
print("what breaks")
print(f"  1 - sum of q, ages 40-64         {1 - sum(q[x] for x in range(40, 65)):.6f}")
print(f"  1 - sum of q, ages 40-89         {1 - sum(q[x] for x in range(40, 90)):.6f}")
print(f"  right: l90 / l40                 {l[90] / l[40]:.6f}")
print(f"  flat hazard at mu40 for 25 years {exp(-25 * mu(40)):.6f}")
print(f"  Gompertz, Makeham constant A = 0 {surv_closed(40, 25, 0.0):.6f}")
ages = list(range(40, 115, 5))
print("chart ages   " + " ".join(f"{a}" for a in ages))
print("chart table  " + " ".join(f"{surv_closed(40, a - 40):.2f}" for a in ages))
print("chart fit    " + " ".join(f"{surv_closed(40, a - 40, 0.0, bg, cg):.2f}" for a in ages))
print("chart deaths " + " ".join(f"{sum(d[a + j] for j in range(5)):.0f}" for a in ages))
print("bars mu per 1,000 at 40..100 by 10  " + " ".join(f"{1000 * mu(a):.2f}" for a in range(40, 101, 10)))
print("try changing")
print(f"  c = 1.10: 25p40                  {surv_closed(40, 25, A, B, 1.10):.6f}")
print(f"  from 60 to 85: 25p60             {surv_closed(60, 25):.6f}")
print(f"  A doubled to 0.00044: 25p40      {surv_closed(40, 25, 2 * A):.6f}")

assert abs(l[65] / l[40] - p25) < 1e-10                                # table vs closed form
assert abs(alive65 / N0 - p25) < 4.0 * (p25 * (1 - p25) / N0) ** 0.5   # simulation within 4 sd
assert abs(e_curt - e_curt_d) < 1e-8                                   # two curtate sums agree
assert abs(e_comp - e_curt - 0.5) < 0.01                                # complete is curtate + 1/2
assert abs(e_sim - e_comp) < 4.0 * se_sim                              # simulated mean near complete
assert abs(mu65_tab - mu(65)) < 1e-4                                   # slope of ln l is mu
assert abs(pg - p25) < 0.01                                            # the fit lands near
assert abs(log(cg) - log(C)) < 0.01                                    # and recovers the ageing rate
print("all checks passed")
