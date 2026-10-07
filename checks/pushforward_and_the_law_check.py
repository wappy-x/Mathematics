# The law of a random variable -- the check behind the card.  Standard library
# only, nothing imported.  Omega = (0, 1), probability = length.  The claim map
# sends a draw u to $0 if u <= 0.3, else to (u - 0.3)/0.7 x $1,000.  Exact
# probabilities are whole numbers of ten-thousandths.  Roads: preimage lengths;
# shelf 2's distribution function F; a grid of 100,000 equal tickets pushed
# forward one by one; a SplitMix64 simulation of a different map Y; bisection.
U, N = 10000, 100000                          # probability unit 1/10000; grid size
LO, HI = -10**6, 10**6                        # stand-ins for minus and plus infinity

def show(k):                                  # ten-thousandths -> "0.2100"
    return f"{k // U}.{k % U:04d}"

def cdf(t):                                   # road 2: shelf 2's F, in 1/10000
    return 0 if t < 0 else (3000 + 7 * t if t < 1000 else U)

def preimage(a, b):                           # road 1: length of {u : a < X(u) <= b}
    flat = 3000 if a < 0 <= b else 0          # the flat piece (0, 0.3], where X = 0
    lo, hi = max(a, 0), min(b, 1000)          # the ramp, u from 0.3 + 0.0007 lo to 0.3 + 0.0007 hi
    return flat + (7 * (hi - lo) if hi > lo else 0)

def xnum(i, n):                               # ticket i of n sits at u = (2i+1)/(2n); X = xnum/(140 n)
    return max(0, ((2 * i + 1) * 10 - 6 * n) * 10000)

def ynum(i, n):                               # a different map: Y = 0 if u > 0.7, else u/0.7 x $1,000
    return 0 if (2 * i + 1) * 10 > 14 * n else (2 * i + 1) * 100000

def grid(num, a, b, n=N):                     # road 3: count tickets whose value lands in (a, b]
    d = 140 * n
    return sum(1 for i in range(n) if a * d < num(i, n) <= b * d)

def dollars(v, n):                            # xnum/(140 n) to cents, rounded half up
    return f"{(v * 200 + 140 * n) // (280 * n) / 100:.2f}"

def splitmix(state):                          # road 4: SplitMix64, written out here
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return state, z ^ (z >> 31)

def quantile(p):                              # road 5: inf {x : F(x) >= p}, by bisection
    f = lambda x: 0.0 if x < 0 else (0.3 + 0.0007 * x if x < 1000 else 1.0)
    lo, hi = -1.0, 1001.0
    for _ in range(60):
        mid = (lo + hi) / 2
        lo, hi = (lo, mid) if f(mid) >= p else (mid, hi)
    return hi

# ---- ten tickets: the definition on a space small enough to list ----
ten = [xnum(i, 10) for i in range(10)]
print("ten tickets u = 0.05 .. 0.95, each 0.1; X in dollars:", "[" + ", ".join(dollars(v, 10) for v in ten) + "]")
hit = [i for i in range(10) if 200 * 1400 < ten[i] <= 500 * 1400]
print(f"ten tickets: law puts {ten.count(0) / 10} on $0 and 0.1 on each of {len(set(ten)) - 1} other values")
print(f"ten tickets: preimage of (200, 500] = tickets {hit}, probability {len(hit) / 10}")
coarse = [[], [0, 1, 2, 3, 4], [5, 6, 7, 8, 9], list(range(10))]
print(f"coarse sigma-algebra (none, 0-4, 5-9, all) holds tickets {hit}: {'yes' if hit in coarse else 'no'}")
assert hit == [4, 5, 6] and hit not in coarse and ten.count(0) == 3

# ---- the continuous claim: three roads to each probability ----
sets = [("{0}", -1, 0), ("(0, 200]", 0, 200), ("(200, 500]", 200, 500),
        ("(-inf, 250]", LO, 250), ("(900, inf)", 900, HI), ("(1000, inf)", 1000, HI)]
print("set | preimage length | F(b) - F(a) | grid of 100000 tickets")
for name, a, b in sets:
    g = grid(xnum, a, b)
    print(f"{name} | {show(preimage(a, b))} | {show(cdf(b) - cdf(a))} | {g / N:.5f}")
    assert preimage(a, b) == cdf(b) - cdf(a) and abs(g * U - preimage(a, b) * N) <= 2 * U
union = preimage(-1, 0) + preimage(200, 500) + preimage(900, HI)
ug = grid(xnum, -1, 0) + grid(xnum, 200, 500) + grid(xnum, 900, HI)
print(f"union {{0}} or (200, 500] or (900, inf): {show(union)} by additivity, {ug / N:.5f} by the grid")
assert union == cdf(0) - cdf(-1) + cdf(500) - cdf(200) + U - cdf(900) and abs(ug * U - union * N) <= 6 * U

# ---- the distribution function, and a different map with the same law ----
ts = list(range(-100, 1101, 100))
print("chart t:", ts)
print("chart F_X exact:", "[" + ", ".join(f"{cdf(t) / U:.2f}" for t in ts) + "]")
seed = 2026
state, draws = seed, []
for _ in range(20000):
    state, z = splitmix(state)
    u = (z >> 11) * 2.0 ** -53
    draws.append(0.0 if u > 0.7 else u / 0.7 * 1000)
sim = [sum(1 for y in draws if y <= t) / 20000 for t in ts]
print(f"chart F_Y simulated, 20000 draws, seed {seed}:", "[" + ", ".join(f"{s:.3f}" for s in sim) + "]")
fy = [grid(ynum, LO, t) for t in ts]
print("F_Y by the grid equals F_X at every chart t:", "yes" if all(abs(g * U - cdf(t) * N) <= 2 * U for g, t in zip(fy, ts)) else "no")
assert all(abs(g * U - cdf(t) * N) <= 2 * U for g, t in zip(fy, ts))
assert all(abs(s - cdf(t) / U) <= 4 * 0.0036 for s, t in zip(sim, ts))     # 4 standard errors

# ---- X is the quantile map of F ----
for p in (0.1, 0.3, 0.44, 0.65, 0.9):
    x = 0.0 if p <= 0.3 else (p - 0.3) / 0.7 * 1000
    print(f"u = {p}: X(u) = {x:.2f}, smallest x with F(x) >= u = {quantile(p):.2f}")
    assert abs(x - quantile(p)) < 1e-6

# ---- three kinds of law from the same draw u ----
fee = lambda i, n: 0 if 20 * i + 10 <= 6 * n else 500 * 140 * n      # $500 if u > 0.3
flat = lambda i, n: (2 * i + 1) * 70000                               # $1,000 x u
kinds = (("discrete, $500 fee", fee, [0, 0.3, 0.3, 1]), ("continuous, $1,000 x u", flat, [0, 0, 0.25, 0.5]),
         ("mixed, the claim", xnum, [0, 0.3, 0.475, 0.65]))               # closed forms, by hand
for name, f, want in kinds:
    at = [grid(f, LO, t, 10000) / 10000 for t in (-1, 0, 250, 500)]
    print(f"{name}: F(0-) {at[0]:.4f}, F(0) {at[1]:.4f}, F(250) {at[2]:.4f}, F(500) {at[3]:.4f}")
    assert at == want

# ---- what breaks ----
rnum = lambda i, n: -(-xnum(i, n) // (14000 * n)) * 14000 * n         # rounded up to $100
agree = all(grid(rnum, LO, t, 10000) == grid(xnum, LO, t, 10000) for t in range(0, 1001, 100))
r25 = grid(rnum, 200, 250, 10000)
print(f"thresholds 0, 100, .., 1000 only: rounded claim R agrees with X there: {'yes' if agree else 'no'}; "
      f"P(200 < . <= 250) X {show(preimage(200, 250))}, R {r25 / 10000:.4f}")
diff = sum(1 for i in range(N) if xnum(i, N) != ynum(i, N))
print(f"same law, different maps: X and Y differ on {diff} of {N} tickets")
even = [grid(flat, a, b, 10000) / 10000 for a, b in ((200, 500), (LO, 0))]
print(f"atom dropped, claim read as spread evenly on $0 to $1,000: P((200, 500]) = {even[0]:.4f}, "
      f"not {show(preimage(200, 500))}; P(X <= 0) = {even[1]:.4f}, not {show(cdf(0))}")
print(f"left limit read as F at the jump: F(0-) = {show(cdf(-1))}, F(0) = {show(cdf(0))}")
assert agree and r25 == 0 and preimage(200, 250) == 350 and diff == N and even == [0.3, 0.0]
px, py = lambda u: 50 + 280 * u, lambda x: 200 - 0.17 * x
print(f"figure, px = 50 + 280u, py = 200 - 0.17X: kink ({px(0.3):.1f}, {py(0):.1f}), top ({px(1):.1f}, {py(1000):.1f}), "
      f"band py {py(200):.1f} to {py(500):.1f}, preimage px {px(0.3 + 0.0007 * 200):.1f} to {px(0.3 + 0.0007 * 500):.1f}")
print("ALL CHECKS PASS")
