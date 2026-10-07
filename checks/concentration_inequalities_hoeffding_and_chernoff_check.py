# Concentration: Hoeffding and Chernoff -- the check behind the card; only math is imported.
# 1,000 fair coin flips.  How likely is a share of heads of 0.55 or more?
# Roads: the three bounds by formula; Chernoff and Hoeffding rebuilt by minimising
# over the dial t numerically; the exact binomial tail, summed term by term; and a
# seeded simulation of 200,000 runs.  Then sample sizes, a 1-in-10 coin, what breaks.
import math

N, P, C, EPS, RUNS, SEED = 1000, 0.5, 0.55, 0.05, 200000, 20260928
M64 = 0xFFFFFFFFFFFFFFFF

def splitmix64(s):                          # the generator both languages share
    s = (s + 0x9E3779B97F4A7C15) & M64
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return s, z ^ (z >> 31)

def tail(n, p, k0):                         # exact P(S >= k0) for S ~ Binomial(n, p)
    lp, r, total = n * math.log(1 - p), math.log(p / (1 - p)), 0.0
    for k in range(n + 1):                  # lp = ln P(S = k), stepped up one k at a time
        if k >= k0:
            total += math.exp(lp)
        if k < n:
            lp += math.log((n - k) / (k + 1)) + r
    return total

def first_k(n):                             # smallest whole k with k / n >= 0.55
    return (11 * n + 19) // 20

def kl(c, p):                               # the Chernoff exponent D(c || p)
    return c * math.log(c / p) + (1 - c) * math.log((1 - c) / (1 - p))

def golden(f, lo, hi):                      # minimise a one-hump-down function on [lo, hi]
    g = (math.sqrt(5) - 1) / 2
    for _ in range(200):
        a, b = hi - g * (hi - lo), lo + g * (hi - lo)
        if f(a) < f(b):
            hi = b
        else:
            lo = a
    return (lo + hi) / 2

def log_chernoff(n, p, c, t):               # ln of e^(-t c n) M(t)^n, M(t) = 1 - p + p e^t
    return -t * c * n + n * math.log(1 - p + p * math.exp(t))

def row(label, v):
    print(f"{label:<52} {v:>14.10f}")

cheb = min(1.0, P * (1 - P) / (N * EPS * EPS))                  # road 1: the three formulas
hoef = math.exp(-2 * N * EPS * EPS)
cher = math.exp(-N * kl(C, P))
t_c = golden(lambda t: log_chernoff(N, P, C, t), 0.0, 5.0)     # road 2: minimise over the dial
cher_num = math.exp(log_chernoff(N, P, C, t_c))
t_h = golden(lambda t: -t * N * EPS + N * t * t / 8, 0.0, 5.0)
hoef_num = math.exp(-t_h * N * EPS + N * t_h * t_h / 8)
exact = tail(N, P, first_k(N))                               # road 3: sum the binomial law

state, hits, copied = SEED, 0, 0                                # road 4: 200,000 seeded runs
for _ in range(RUNS):
    heads = 0
    for j in range(16):                                         # 15 x 64 bits + 40 bits = 1,000 flips
        state, z = splitmix64(state)
        heads += (z if j < 15 else z & ((1 << 40) - 1)).bit_count()
        copied += (z & 1) >= C if j == 0 else 0                # broken 1: the run's first flip, copied
    hits += heads >= 550
sim, copy_sim = hits / RUNS, copied / RUNS
sim_se, copy_se = math.sqrt(sim * (1 - sim) / RUNS), math.sqrt(copy_sim * (1 - copy_sim) / RUNS)

grid = [i / 100 for i in range(-1000, 1001)]                    # Hoeffding's lemma, on a grid
ex_fair = max(math.log(math.cosh(t / 2)) - t * t / 8 for t in grid)
ex_tenth = max(math.log(0.9 * math.exp(-0.1 * t) + 0.1 * math.exp(0.9 * t)) - t * t / 8 for t in grid)

row("1 Chebyshev: 0.25 / (n eps^2)", cheb)
row("1 Hoeffding exponent: 2 n eps^2", 2 * N * EPS * EPS)
row("1 Hoeffding: exp(-2 n eps^2)", hoef)
row("1 Chernoff: D(0.55 || 0.5)", kl(C, P))
row("1 Chernoff: exp(-n D)", cher)
row("2 Chernoff by minimising over t: best t", t_c)
row("2   bound at that t", cher_num)
row("2 Hoeffding by minimising over t: best t", t_h)
row("2   bound at that t", hoef_num)
row("3 exact binomial tail P(S >= 550)", exact)
row("4 simulated, 200,000 runs: share with S >= 550", sim)
row("4   its standard error", sim_se)
row("worked: cosh(0.1), centred coin's M at t = 0.2", math.cosh(0.1))
row("worked: exp(0.2^2 / 8), Hoeffding's ceiling for it", math.exp(0.005))
row("lemma: largest excess on the grid, fair coin", ex_fair)
row("lemma: largest excess on the grid, 1-in-10 coin", ex_tenth)
row("two-sided: Hoeffding 2 exp(-2 n eps^2)", 2 * hoef)
row("two-sided: exact P(|S - 500| >= 50)", 2 * exact)
print("chart, percent:  n   Chebyshev   Hoeffding   exact")
for n in range(100, 1001, 100):
    print(f"chart, {n:>11}   {100 * min(1.0, 100 / n):>9.2f}   {100 * math.exp(-n / 200):>9.2f}   {100 * tail(n, P, first_k(n)):>5.2f}")
print("chart, t:       " + " ".join(f"{i / 20:>6.2f}" for i in range(9)))
print("chart, bound %: " + " ".join(f"{100 * math.exp(log_chernoff(N, P, C, i / 20)):>6.2f}" for i in range(9)))
n_h = math.ceil(math.log(100) / (2 * EPS * EPS))
ex_n = [tail(n, P, first_k(n)) for n in range(1, 1201)]
ok = [n for n in range(1, 1201) if ex_n[n - 1] <= 0.01]
bad = [n for n in range(1, 1201) if ex_n[n - 1] > 0.01]
print(f"99% sure: Chebyshev n = {round(0.25 / (0.01 * EPS * EPS))}, Hoeffding n = {n_h},"
      f" exact first n = {ok[0]}, last n above 0.01 = {bad[-1]}")
row(f"Hoeffding bound at n = {n_h}", math.exp(-2 * n_h * EPS * EPS))
row(f"Hoeffding bound at n = {n_h - 1}", math.exp(-2 * (n_h - 1) * EPS * EPS))
row(f"exact tail at n = {bad[-1] + 1}", ex_n[bad[-1]])
ten_ex, ten_ch = tail(N, 0.1, 150), math.exp(-N * kl(0.15, 0.1))
row("1-in-10 coin, S >= 150: Hoeffding", hoef)
row("1-in-10 coin: Chernoff exp(-n D(0.15 || 0.1))", ten_ch)
row("1-in-10 coin: exact tail", ten_ex)
row("die, 1,000 rolls, eps 0.1: Chebyshev, both sides", 35 / 12 / (N * 0.1 * 0.1))
row("die: Hoeffding, range 1 to 6, both sides", 2 * math.exp(-2 * N * 0.1 * 0.1 / 25))
alive, stopped, law = [1.0], 0.0, [1.0]                        # broken 3: look after every flip
for k in range(1, N + 1):                                       # law: the heads count, flip by flip
    alive = [0.5 * ((alive[s] if s < k else 0.0) + (alive[s - 1] if s > 0 else 0.0)) for s in range(k + 1)]
    law = [0.5 * ((law[s] if s < k else 0.0) + (law[s - 1] if s > 0 else 0.0)) for s in range(k + 1)]
    if k >= 100:
        for s in range(first_k(k), k + 1):
            stopped, alive[s] = stopped + alive[s], 0.0
row("3 the same tail, adding one flip at a time", sum(law[550:]))
copies = sum(1 for face in (0, 1) if face >= C) / 2             # broken 1: one flip copied
row("broken 1, one flip copied 1,000 times", copies)
print(f"broken 1, simulated, each run's first flip copied: {copy_sim:.4f} (standard error {copy_se:.4f})")
row("broken 2, +1/-1 score, width taken as 1: 'bound'", math.exp(-2 * N * 0.1 * 0.1))
row("broken 3, looked at after every flip, 100 to 1,000", stopped)

assert abs(cher_num - cher) < 1e-9 * cher, "Chernoff: closed form vs numerical minimum"
assert abs(hoef_num - hoef) < 1e-9 * hoef, "Hoeffding: closed form vs numerical minimum"
assert ex_fair <= 1e-15, "Hoeffding's lemma holds on the whole grid, fair coin"
assert ex_tenth <= 1e-15, "Hoeffding's lemma holds on the whole grid, 1-in-10 coin"
assert abs(sum(law[550:]) - exact) < 1e-12, "two exact roads: term by term, flip by flip"
assert exact <= cher, "exact under Chernoff"
assert cher <= hoef, "Chernoff under Hoeffding for a fair coin"
assert all(ex_n[n - 1] <= min(1.0, 100 / n) for n in range(1, 1201)), "exact under Chebyshev"
assert all(ex_n[n - 1] <= math.exp(-n / 200) for n in range(1, 1201)), "exact under Hoeffding"
assert abs(sim - exact) < 4 * sim_se, "simulation vs the exact tail"
assert math.exp(-2 * n_h * EPS * EPS) <= 0.01 < math.exp(-2 * (n_h - 1) * EPS * EPS), "whole-number n"
assert ten_ex <= ten_ch, "Chernoff holds for the 1-in-10 coin"
assert 1000 * ten_ch < hoef, "Chernoff sees the 1-in-10 coin, Hoeffding does not"
assert copy_sim - 4 * copy_se > hoef, "copied flips break the bound, simulated"
assert stopped > hoef, "looking after every flip breaks the bound"
assert math.exp(-2 * N * 0.1 * 0.1) < exact, "a misdeclared range promises less than the truth"
print("ALL CHECKS PASS")
