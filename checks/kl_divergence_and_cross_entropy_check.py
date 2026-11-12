# KL divergence and cross-entropy -- the check behind the card.  Standard library only.
# A London station codes its daily sky with a Lisbon station's codebook.
# Roads: the sums; a simulated radio log encoded, counted and decoded bit by bit;
# and a fitted dial found by likelihood, by divergence and by matching the mean.
import math

SKY = ["sunny", "cloudy", "drizzle", "rain"]
P = [0.125, 0.5, 0.25, 0.125]                  # London's table (synthetic, round numbers)
Q = [0.5, 0.25, 0.125, 0.125]                  # Lisbon's table (synthetic, round numbers)
LISBON = ["0", "10", "110", "111"]             # Lisbon's prefix code
LONDON = ["110", "0", "10", "111"]             # London's own prefix code

def H(p): return -sum(a * math.log2(a) for a in p if a > 0)
def cross(p, q): return sum(a * (-math.log2(b) if b > 0 else math.inf) for a, b in zip(p, q) if a > 0)
def kl(p, q): return sum(a * (math.log2(a / b) if b > 0 else math.inf) for a, b in zip(p, q) if a > 0)

def splitmix(state):                           # SplitMix64, written out
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return state, z ^ (z >> 31)

def draw_days(n, seed):
    s, days = seed, []
    for _ in range(n):
        s, z = splitmix(s)
        u = (z >> 11) / 9007199254740992.0
        acc, k = 0.0, 0
        while k < 3 and u >= acc + P[k]:
            acc += P[k]; k += 1
        days.append(k)
    return days

def decode(bits, code):
    out, word = [], ""
    for b in bits:
        word += b
        if word in code:
            out.append(code.index(word)); word = ""
    return out

def dial(t):                                   # Lisbon's table, each step wetter times t
    w = [Q[0], Q[1] * t, Q[2] * t * t, Q[3] * t * t * t]
    return [x / sum(w) for x in w]

def fit(target):                               # bisection: the dial whose mean wetness is target
    lo, hi = 0.5, 3.0
    for _ in range(60):
        mid = (lo + hi) / 2
        if sum(k * w for k, w in enumerate(dial(mid))) < target: lo = mid
        else: hi = mid
    return lo

def f(label, x): print(f"{label:<40}{x:>12.6f}")

print("sky              " + "".join(f"{s:>9}" for s in SKY))
print("London p         " + "".join(f"{a:>9.3f}" for a in P))
print("Lisbon q         " + "".join(f"{a:>9.3f}" for a in Q))
print("Lisbon codeword  " + "".join(f"{c:>9}" for c in LISBON))
print("London codeword  " + "".join(f"{c:>9}" for c in LONDON))
print("Kraft sums, Lisbon and London         " + f"{sum(2.0 ** -len(c) for c in LISBON):.3f} {sum(2.0 ** -len(c) for c in LONDON):.3f}")
hp, hpq, d, drev = H(P), cross(P, Q), kl(P, Q), kl(Q, P)
f("H(p)     London sky, London code", hp)
f("H(p,q)   London sky, Lisbon code", hpq)
f("D(p||q)  by the sum of p log2(p/q)", d)
f("D(p||q)  as H(p,q) - H(p)", hpq - hp)
f("D(q||p)  Lisbon sky, London code", drev)
f("bits wasted in a 365-day year", 365 * d)
terms = [(a * math.log(b / a), a * (b / a - 1)) for a, b in zip(P, Q)]
f("-D in nats, sum of p ln(q/p)", sum(x for x, _ in terms))
f("Gibbs ceiling, sum of p (q/p - 1)", sum(y for _, y in terms))
tv = 0.5 * sum(abs(a - b) for a, b in zip(P, Q))
f("total variation TV(p,q)", tv)
f("Pinsker ceiling sqrt(D ln2 / 2)", math.sqrt(d * math.log(2) / 2))

N = 100000
days = draw_days(N, 20261111)
for name, code in (("Lisbon", LISBON), ("London", LONDON)):
    bits = "".join(code[k] for k in days)
    lens = [len(code[k]) for k in days]
    mean = len(bits) / N
    se = math.sqrt(sum((x - mean) ** 2 for x in lens) / (N - 1) / N)
    assert decode(bits, code) == days, "the prefix code must decode back to the log"
    print(f"simulated {N} days, {name} code: {len(bits)} bits = {mean:.6f} per day (se {se:.6f})")
    if name == "Lisbon": sim_lis, se_lis = mean, se
    else: sim_lon = mean

print("wrong: arguments swapped, D(q||p)       " + f"{drev:12.6f}")
print("wrong: sum of log2(p/q), no weights     " + f"{sum(math.log2(a / b) for a, b in zip(P, Q)):12.6f}")
print("wrong: natural log, nats not bits       " + f"{sum(a * math.log(a / b) for a, b in zip(P, Q)):12.6f}")
print("broken: Lisbon table with rain at 0     " + f"{kl(P, [0.5, 0.3125, 0.1875, 0.0]):12.6f}")

year = days[:365]
cnt = [year.count(k) for k in range(4)]
ph = [c / 365 for c in cnt]
print("one year of the log, counts          " + " ".join(f"{c:>4}" for c in cnt) + f"   mean wetness {sum(k * c for k, c in enumerate(cnt)) / 365:.6f}")
f("H(p-hat), the year's own entropy", H(ph))
ts = [0.5 + 0.25 * i for i in range(11)]
nll = [-sum(math.log2(dial(t)[k]) for k in year) / 365 for t in ts]
gap = [H(ph) + kl(ph, dial(t)) for t in ts]
print("chart, dial t   " + " ".join(f"{t:5.2f}" for t in ts))
print("chart, bits/day " + " ".join(f"{x:5.3f}" for x in nll))
grid = [0.5 + 0.001 * i for i in range(2501)]
t_like = max(grid, key=lambda t: sum(math.log2(dial(t)[k]) for k in year))
t_div = min(grid, key=lambda t: kl(ph, dial(t)))
t_mean = fit(sum(year) / 365)                  # the year's own table
t_true = fit(sum(k * a for k, a in enumerate(P)))   # London's true table: the floor data tends to
f("best dial by likelihood (grid 0.001)", t_like)
f("best dial by divergence (grid 0.001)", t_div)
f("best dial by matching mean wetness", t_mean)
f("divergence left at the best dial", kl(ph, dial(t_mean)))
print("fitted table     " + "".join(f"{a:>9.3f}" for a in dial(t_mean)))
f("best dial for London's true table", t_true)
f("divergence floor for London's true table", kl(P, dial(t_true)))

assert abs(hp - 1.75) < 1e-12 and abs(hpq - 2.25) < 1e-12, "hand values of the card"
assert abs(d - (hpq - hp)) < 1e-12 and d > 0 and drev != d, "divergence = cross-entropy - entropy"
assert abs(sum(P[k] * len(LISBON[k]) for k in range(4)) - hpq) < 1e-12, "Lisbon lengths are -log2 q"
assert abs(sim_lis - hpq) < 4 * se_lis and abs((sim_lis - sim_lon) - d) < 0.02, "simulated radio log"
assert all(x <= y for x, y in terms) and tv <= math.sqrt(d * math.log(2) / 2), "Gibbs and Pinsker"
assert all(abs(a - b) < 1e-9 for a, b in zip(nll, gap)), "average code length = H(p-hat) + D"
assert abs(t_like - t_div) < 0.0011 and abs(t_like - t_mean) < 0.001, "likelihood peak = divergence floor"
assert all(kl(P, dial(t)) >= kl(P, dial(t_true)) - 1e-12 for t in grid), "the true table's floor"
print("ALL CHECKS PASS")
