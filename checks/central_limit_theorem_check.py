# Central limit theorem -- the check behind the card.  Standard library only.
# The average of 1,000 fair-die rolls: how often does it land within 0.1 of 3.5?
# Road 1: the CLT, with Phi built from its own Taylor series.
# Road 2: the exact law of the sum, built one die at a time (every outcome counted).
# Road 3: a seeded simulation from a SplitMix64 generator written out below.
from math import sqrt, pi, exp, atan, tan

N, EPS, SEED = 1000, 0.1, 20260928
FAIR = [1 / 6] * 6                              # chance of faces 1..6
LOADED = [0.5, 0.1, 0.1, 0.1, 0.1, 0.1]         # a lopsided die: a one half the time

def Phi(z):                                     # standard normal area left of z, by series
    if abs(z) > 8:                              # beyond 8 spreads the area is 0 or 1 to 15 places
        return 0.0 if z < 0 else 1.0
    term, total = z, z
    for k in range(1, 300):
        term *= -z * z / (2 * k)
        total += term / (2 * k + 1)
    return 0.5 + total / sqrt(2 * pi)

def mean_sd(law):
    mu = sum((f + 1) * p for f, p in enumerate(law))
    return mu, sqrt(sum((f + 1 - mu) ** 2 * p for f, p in enumerate(law)))

def add_die(dist, law):                         # law of the sum after one more roll
    new = [0.0] * (len(dist) + 6)
    for s, c in enumerate(dist):
        if c:
            for f, p in enumerate(law):
                new[s + f + 1] += c * p
    return new

def within(dist, n, mu, eps, edges=False):      # chance the average misses mu by less than eps
    if edges:                                   # ... or by exactly eps too
        return sum(c for s, c in enumerate(dist) if abs(s - n * mu) <= n * eps + 1e-9)
    return sum(c for s, c in enumerate(dist) if abs(s - n * mu) < n * eps - 1e-9)

def clt(n, sd, eps):                            # the theorem's answer
    return 2 * Phi(eps * sqrt(n) / sd) - 1

MASK = (1 << 64) - 1
state = SEED
def splitmix():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return z ^ (z >> 31)

mu, sd = mean_sd(FAIR)
se_avg = sd / sqrt(N)
sq = sum((f + 1) ** 2 * p for f, p in enumerate(FAIR))
print(f"one die: mean {mu:.6f}, mean of squares {sq:.6f}, variance {sd * sd:.6f}, spread {sd:.6f}")
print(f"{N} rolls: root n {sqrt(N):.6f}, spread of the average {se_avg:.6f}")
print(f"  window {EPS} = {EPS / se_avg:.6f} spreads; Phi there {Phi(EPS / se_avg):.6f}")

dist, dists, grid = [1.0], {}, (1, 2, 10, 30, 100, 300, 1000)
for n in range(1, N + 1):
    dist = add_die(dist, FAIR)
    if n in grid:
        dists[n] = dist
road1 = clt(N, sd, EPS)
road2 = within(dist, N, mu, EPS)
edged = within(dist, N, mu, EPS, True)
tot = sum(dist)
m_sum = sum(s * c for s, c in enumerate(dist))
v_sum = sum((s - m_sum) ** 2 * c for s, c in enumerate(dist))
print(f"road 1, CLT: 2 Phi({EPS / se_avg:.6f}) - 1 = {road1:.6f}")
print(f"  outside the window: {1 - road1:.6f}")
print(f"road 2, exact law of the sum, miss under 0.1: {road2:.6f}; CLT minus exact {road1 - road2:.6f}")
print(f"  with the edges 3.4 and 3.6 included: {edged:.6f}")
print(f"  exact law: total {tot:.9f}, mean {m_sum:.6f}, variance {v_sum:.6f}")

R, hits, s1, s2 = 5000, 0, 0.0, 0.0
for _ in range(R):
    a = sum(1 + splitmix() % 6 for _ in range(N)) / N
    hits += abs(a - mu) < EPS - 1e-9
    s1 += a
    s2 += a * a
road3 = hits / R
se3 = sqrt(road3 * (1 - road3) / R)
sim_sd = sqrt((s2 - s1 * s1 / R) / (R - 1))
print(f"road 3, {R} simulated averages, seed {SEED}: {road3:.4f} (standard error {se3:.4f})")
print(f"  spread of the simulated averages {sim_sd:.6f}")

print("n, spread of average, exact without edges, exact with edges, CLT")
for n in grid:
    print(f"  {n:>4}  {sd / sqrt(n):.6f}  {within(dists[n], n, mu, EPS):.4f}  "
          f"{within(dists[n], n, mu, EPS, True):.4f}  {clt(n, sd, EPS):.4f}")
sd10 = sd * sqrt(10)
print("chart 1, average: " + " ".join(f"{s / 10:.1f}" for s in range(25, 46)))
print("chart 1, exact %: " + " ".join(f"{100 * dists[10][s]:.2f}" for s in range(25, 46)))
print("chart 1, bell %:  " + " ".join(f"{100 * exp(-((s - 35) / sd10) ** 2 / 2) / sqrt(2 * pi) / sd10:.2f}"
                                    for s in range(25, 46)))
print("chart 2, exact %: " + " ".join(f"{100 * within(dists[n], n, mu, EPS):.2f}" for n in grid[2:]))
print("chart 2, edges %: " + " ".join(f"{100 * within(dists[n], n, mu, EPS, True):.2f}" for n in grid[2:]))
print("chart 2, CLT %:   " + " ".join(f"{100 * clt(n, sd, EPS):.2f}" for n in grid[2:]))

def mgf_z(n, t=1.0):                            # moment generating function of Z_n at t
    m1 = sum(p * exp(t / sqrt(n) * (f + 1 - mu) / sd) for f, p in enumerate(FAIR))
    return m1 ** n
print("M of Z_n at t = 1: " + "  ".join(f"n={n} {mgf_z(n):.6f}" for n in (1, 10, 100, 1000))
      + f"  limit e^(1/2) {exp(0.5):.6f}")

lmu, lsd = mean_sd(LOADED)
ld = [1.0]
for _ in range(N):
    ld = add_die(ld, LOADED)
l_exact, l_clt = within(ld, N, lmu, EPS), clt(N, lsd, EPS)
print(f"loaded die: mean {lmu:.6f}, spread {lsd:.6f}; {N} rolls within 0.1: exact {l_exact:.4f}, CLT {l_clt:.4f}")

print("what breaks, the rule applied correctly gives %.4f" % road1)
print(f"  spread of one roll, no root n: {2 * Phi(EPS / sd) - 1:.4f}")
print(f"  divided by n, not root n: {2 * Phi(EPS * N / sd) - 1:.4f}")
print(f"  variance used as the spread: {2 * Phi(EPS * sqrt(N) / (sd * sd)) - 1:.4f}")
print(f"  one tail only: {Phi(EPS / se_avg) - 0.5:.4f}")
copies = sum(p for f, p in enumerate(FAIR) if abs(f + 1 - mu) < EPS)
print(f"  1000 copies of one roll, exact: {copies:.4f}")
c_exact = 2 / pi * atan(EPS)
RC, ch = 2000, 0
for _ in range(RC):
    a = sum(mu + tan(pi * (((splitmix() >> 11) + 0.5) / 2.0 ** 53 - 0.5)) for _ in range(N)) / N
    ch += abs(a - mu) < EPS
c_sim = ch / RC
c_se = sqrt(c_sim * (1 - c_sim) / RC)
print(f"  Cauchy readings, 1 or 1000 of them: {c_exact:.4f}; simulated 1000-averages {c_sim:.4f} ({c_se:.4f})")
print(f"try: window 0.05: {clt(N, sd, 0.05):.4f}; 4000 rolls: {clt(4000, sd, EPS):.4f}; "
      f"window 0.05 with 4000 rolls: {clt(4000, sd, 0.05):.4f}")

assert abs(road2 - road1) < 0.005, "exact law vs the CLT"
assert abs(road3 - road2) < 4 * se3, "simulation vs exact law"
assert abs(sim_sd - se_avg) < 4 * se_avg / sqrt(2 * R), "simulated spread vs sigma / root n"
assert abs(v_sum - N * 35 / 12) < 1e-6, "exact law's variance vs n times 35/12"
assert abs(mgf_z(1000) - exp(0.5)) < 1e-3, "MGF of Z_n approaches e^(t^2/2)"
assert abs(l_exact - l_clt) < 0.005, "lopsided die obeys the CLT too"
assert abs(c_sim - c_exact) < 4 * c_se, "Cauchy 1000-averages spread like one reading"
print("ALL CHECKS PASS")
