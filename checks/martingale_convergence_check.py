# Martingale convergence -- the check behind the card.  Standard library only.
# Polya's urn: 1 red and 1 blue ball; draw one at random, put it back with one
# more of its colour.  R reds after n draws; M_n = R/(n+2) is the fraction red.
# Roads: exact integer dynamic programming, listing every draw sequence, closed
# formulas, and a seeded SplitMix64 simulation printed with standard errors.
from math import gcd, factorial, sqrt, prod

def fr(p, q):                            # a fraction p/q, reduced, as text
    g = gcd(p, q)
    return f"{p // g}/{q // g}"
def law(n):                              # road 1: P(R = r) * (n+1)!, stepping the urn
    w = {1: 1}
    for t in range(n):                   # t+2 balls; red drawn with chance r/(t+2)
        nxt = {}
        for r, p in w.items():
            nxt[r + 1] = nxt.get(r + 1, 0) + p * r
            nxt[r] = nxt.get(r, 0) + p * (t + 2 - r)
        w = nxt
    return w
print("exact law of the reds R after n draws; road 2 is the formula P(R = r) = 1/(n+1)")
for n in range(1, 21):
    w, den = law(n), factorial(n + 1)
    assert sorted(w) == list(range(1, n + 2)) and all(p * (n + 1) == den for p in w.values())
    assert 2 * sum(r * p for r, p in w.items()) == (n + 2) * den      # E[M_n] = 1/2
    if n <= 3: print(f"n={n}: " + "  ".join(f"P(R={r}) = {fr(w[r], den)}" for r in sorted(w)))
print(f"by hand: M_1 = {fr(2, 3)} or {fr(1, 3)}, chance 1/2 each, average {fr(2 + 1, 6)}; 3 draws, 2 reds, each order: " + " ".join(
    f"{q} {fr(prod(1 + q[:t].count(c) for t, c in enumerate(q)), prod(range(2, 5)))}" for q in ("RRB", "RBR", "BRR")))
print("E[M_n] = 1/2 and every P(R = r) = 1/(n+1), n = 1..20: both roads agree")
def lo(r, t): return 5 * r <= 2 * (t + 2)   # M_t <= a = 0.4
def hi(r, t): return 5 * r >= 3 * (t + 2)   # M_t >= b = 0.6
def up_dp(n, one):                       # road 1: E[U_n], carrying (reds, armed) forward
    w, eu = {(1, False): one}, 0 * one   # weights stay exact when one = 1 (over (t+1)!)
    for t in range(n):
        nxt, c = {}, 0 * one
        for (r, armed), p in w.items():
            for r2, q in ((r + 1, r), (r, t + 2 - r)):
                up = armed and hi(r2, t + 1)     # an upcrossing completes
                if up: c += p * q
                key = (r2, not up and (armed or lo(r2, t + 1)))
                nxt[key] = nxt.get(key, 0 * one) + p * q
        if type(one) is int:             # integer weights over (t+2)!: rescale to (n+1)!
            eu += c * (factorial(n + 1) // factorial(t + 2))
            w = nxt
        else:
            eu += c / (t + 2)
            w = {k: v / (t + 2) for k, v in nxt.items()}
    return eu
def up_list(n):                          # road 2: every draw sequence, weighted
    total = 0
    for mask in range(1 << n):
        r, armed, u = 1, False, 0
        for t in range(n):
            r += mask >> t & 1
            up = armed and hi(r, t + 1)          # an upcrossing completes
            u, armed = u + up, not up and (armed or lo(r, t + 1))
        total += u * factorial(r - 1) * factorial(n - r + 1)  # k = r-1 reds: chance k!(n-k)!/(n+1)!
    return total
n, den = 16, factorial(17)
e1, e2 = up_dp(n, 1), up_list(n)
bnum = sum(max(2 * (n + 2) - 5 * j, 0) for j in range(1, n + 2))  # E[(M_n - a)^-] * 5(n+2)(n+1)
bden = 5 * (n + 2) * (n + 1)
assert e1 == e2                          # two roads to E[U]
assert e1 * bden < 5 * bnum * den        # E[U] under the bound; 1/(b - a) = 5
print(f"upcrossings of [0.4, 0.6] in {n} draws: E[U] by DP {fr(e1, den)} = {e1 / den:.6f}")
print(f"  by listing all {1 << n} draw sequences {fr(e2, den)} = {e2 / den:.6f}")
print(f"  E[(M_n - 0.4)^-] = {fr(bnum, bden)} = {bnum / bden:.6f}; bound E[(M_n - a)^-]/(b - a) = {5 * bnum / bden:.6f}")
eu1000 = up_dp(1000, 1.0)
print(f"E[U] in 1000 draws by DP {eu1000:.4f}; bound {5 * sum(max(0.4 - j / 1002, 0) for j in range(1, 1002)) / 1001:.4f}; limit bound (a^2/2)/(b-a) = {0.08 / 0.2:.4f}")
state = 20260929                         # SplitMix64, written out
def nxt64():
    global state
    state = (state + 0x9E3779B97F4A7C15) & (2 ** 64 - 1)
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & (2 ** 64 - 1)
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & (2 ** 64 - 1)
    return z ^ (z >> 31)
URNS, N, MARKS = 10000, 1000, (0, 1, 2, 5, 10, 20, 50, 100, 200, 500, 1000)
bins, ups, fin, gap, paths, early = [0] * 10, [], [], [], [], []
for i in range(URNS):
    r, armed, u, seen, f40 = 1, False, 0, {0: 0.5}, [0.5]
    for t in range(N):
        r += nxt64() % (t + 2) < r      # red with chance r/(t+2)
        if armed and hi(r, t + 1):
            u, armed = u + 1, False
        elif lo(r, t + 1):
            armed = True
        if t + 1 in MARKS: seen[t + 1] = r / (t + 3)
        if t < 40: f40.append(r / (t + 3))
        if t == 39 and u >= 2 and not early: early = [i + 1, f40]
    bins[min(int(10 * seen[N]), 9)] += 1
    ups.append(u); fin.append(seen[N]); gap.append((seen[N] - seen[100]) ** 2)
    if i < 3: paths.append(seen)
def mse(xs):
    m = sum(xs) / len(xs)
    return m, sqrt(sum((x - m) ** 2 for x in xs) / (len(xs) - 1) / len(xs))
print(f"simulation: {URNS} urns, {N} draws each, SplitMix64 seed 20260929")
for k in range(3):
    print(f"urn {k + 1}, M_n at n = 0 1 2 5 10 20 50 100 200 500 1000: " + " ".join(f"{paths[k][m]:.2f}" for m in MARKS))
print(f"urn {early[0]}, first with 2 upcrossings by draw 40, M_n for n = 0..40:")
print(" ".join(f"{x:.2f}" for x in early[1]))
exact_bin = [sum(1 for j in range(1, N + 2) if min(int(10 * j / (N + 2)), 9) == b) / (N + 1) for b in range(10)]
print("share of M_1000 in tenths 0-0.1 ... 0.9-1: " + " ".join(f"{b / URNS:.3f}" for b in bins))
print("  exact from the law, each tenth:           " + " ".join(f"{e:.3f}" for e in exact_bin))
assert all(abs(b / URNS - e) < 4 * sqrt(0.09 / URNS) for b, e in zip(bins, exact_bin))
(mf, sf), (mu, su), (mg, sg) = mse(fin), mse(ups), mse(gap)
g_exact = 1 / (6 * 102) - 1 / (6 * 1002)
print(f"mean M_1000 {mf:.4f} +- {sf:.4f} (exact 0.5000)")
print(f"mean upcrossings of [0.4, 0.6] {mu:.4f} +- {su:.4f} (exact {eu1000:.4f})")
print(f"mean (M_1000 - M_100)^2 {mg:.6f} +- {sg:.6f} (exact 1/612 - 1/6012 = {g_exact:.6f})")
assert abs(mf - 0.5) < 4 * sf
assert abs(mu - eu1000) < 4 * su
assert abs(mg - g_exact) < 4 * sg
print("RMS movement still to come after n draws, 1/sqrt(6(n+2)): " + " ".join(f"n={m} {1 / sqrt(6 * (m + 2)):.4f}" for m in (0, 10, 100, 1000)))
print("house example: a fair $1 game.  Without credit, from $10; with credit, S_n from 0")
w = [0.0] * 10 + [1.0] + [0.0] * 1001      # chance of each fortune, stopped at $0
for t in range(1, 1001):
    w = [w[0] + 0.5 * w[1], 0.5 * w[2]] + [0.5 * (w[x - 1] + w[x + 1]) for x in range(2, 1011)] + [0.0]
    if t in (100, 1000):
        p = [0.5 ** t]                    # road 2: reflection, P(-10 < S_t <= 10), binomial
        for j in range(t): p.append(p[-1] * (t - j) / (j + 1))
        refl = sum(q for j, q in enumerate(p) if -10 < 2 * j - t <= 10)
        mean = sum(x * q for x, q in enumerate(w))
        e_abs = sum(abs(2 * j - t) * q for j, q in enumerate(p))
        p0 = prod((2 * k - 1) / (2 * k) for k in range(1, t // 2 + 1))
        assert abs((1 - w[0]) - refl) < 1e-9 and abs(mean - 10) < 1e-9
        assert abs(e_abs - t * p0) < 1e-9 # E|S_t| = t P(S_t = 0) for even t
        print(f"n={t}: still playing {1 - w[0]:.4f} (reflection {refl:.4f}), mean fortune {mean:.4f}; E|S_n| {e_abs:.4f} (n P(S_n=0) {t * p0:.4f})")
n = 10                                    # doubling: stake 1, 2, 4, ... until the first win
e_x = e_abs = won = 0                     # sums over all 2^n equally likely coin sequences
for mask in range(1 << n):
    x, stake = 0, 1
    for t in range(n):
        if x == 1: break                  # won: stop betting
        if mask >> t & 1: x += stake
        else: x, stake = x - stake, 2 * stake
    e_x, e_abs, won = e_x + x, e_abs + abs(x), won + (x == 1)
assert e_x == 0                           # a fair game: average 0 at round n
assert e_abs * 2 ** (n - 1) == 2 ** (2 * n) - 2 ** n   # formula E|X| = 2 - 2^(1-n)
assert won == 2 ** n - 1                  # formula P(X = +1) = 1 - 2^(-n)
print(f"doubling, n={n}: E[X] = {e_x}, E|X| = {fr(e_abs, 2 ** n)} = {e_abs / 2 ** n:.6f}, P(won, X = +1) = {fr(won, 2 ** n)} = {1 - 0.5 ** n:.6f}")
