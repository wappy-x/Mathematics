# Beta-binomial -- the check behind the card.  Nothing imported holds the answer.
# A new coin shows 7 heads in 10 flips.  Prior Beta(2, 2) on its chance of heads, theta.
# Roads: (1) conjugate formulas, heads added to a, tails to b; (2) a 2,000-step grid updated
# flip by flip, integrated by Simpson's rule, never using the update rule; (3) a Polya urn,
# every draw path counted; (4) a seeded simulation keeping only coins that show 7 of 10.
from math import sqrt

A0, B0, N, S = 2, 2, 10, 7                   # prior counts; flips; heads
FLIPS = "HTHHHTHHTH"                         # the record, in order: 7 heads, 3 tails
A, B = A0 + S, B0 + N - S                    # the conjugate update: Beta(9, 5)

def fact(n):
    out = 1
    for j in range(2, n + 1):
        out *= j
    return out

def comb(n, k):
    return fact(n) // (fact(k) * fact(n - k))

def rising(x, k):                            # x (x+1) ... (x+k-1), whole numbers
    out = 1
    for j in range(k):
        out *= x + j
    return out

def bdens(t, a, b):                          # beta density, whole a and b
    return fact(a + b - 1) / (fact(a - 1) * fact(b - 1)) * t ** (a - 1) * (1 - t) ** (b - 1)

def pred(a, b, m, k):                        # road 1: chance of k heads in m more flips
    return comb(m, k) * rising(a, k) * rising(b, m - k) / rising(a + b, m)

def urn(red, blue, m):                       # road 3: every draw path of a Polya urn
    ways = [0] * (m + 1)
    for path in range(2 ** m):
        r, bl, w, k = red, blue, 1, 0
        for i in range(m):
            if path >> i & 1:
                w, r, k = w * r, r + 1, k + 1
            else:
                w, bl = w * bl, bl + 1
        ways[k] += w
    return ways, rising(red + blue, m)

# road 2: a grid on theta, prior times one factor per flip, integrated by Simpson's rule
G = 2000
h = 1.0 / G
ts = [i * h for i in range(G + 1)]
wt = [(1 if i in (0, G) else 4 if i % 2 else 2) * h / 3 for i in range(G + 1)]
post = [6 * t * (1 - t) for t in ts]         # Beta(2, 2) prior density
means = []
for c in FLIPS:
    post = [p * (t if c == "H" else 1 - t) for p, t in zip(post, ts)]
    z = sum(w * p for w, p in zip(wt, post))
    means.append(sum(w * t * p for w, t, p in zip(wt, ts, post)) / z)
def grid(f, lo=0):                           # Simpson: f(theta) x posterior, from node lo to 1
    n = G - lo
    return sum((1 if i in (0, n) else 4 if i % 2 else 2) * h / 3 * f(ts[lo + i]) * post[lo + i]
               for i in range(n + 1)) / z

T = A + B
mean, var = A / T, A * B / (T * T * (T + 1))
evid = comb(N, S) * fact(A - 1) * fact(B - 1) * fact(A0 + B0 - 1) / (fact(T - 1) * fact(A0 - 1) * fact(B0 - 1))
over = sum(comb(T - 1, j) for j in range(A)) / 2 ** (T - 1)   # P(theta > 1/2): fewer than 9 of 13 below
print(f"prior Beta({A0},{B0}): mean {A0 / (A0 + B0):.4f}, sd {sqrt(A0 * B0 / ((A0 + B0) ** 2 * (A0 + B0 + 1))):.4f}")
print(f"posterior Beta({A},{B}): mean {mean:.4f}, by grid {grid(lambda t: t):.4f}; sd {sqrt(var):.4f}, "
      f"by grid {sqrt(grid(lambda t: t * t) - grid(lambda t: t) ** 2):.4f}; mode {A - 1}/{T - 2} = {(A - 1) / (T - 2):.4f}; variance {A * B}/{T * T * (T + 1)}")
print(f"weights: prior {A0 + B0}/{T} = {(A0 + B0) / T:.4f}, data {N}/{T} = {N / T:.4f}; "
      f"{(A0 + B0) / T:.4f} x 0.5 + {N / T:.4f} x {S / N:.1f} = {(A0 + B0) / T * 0.5 + N / T * S / N:.4f}")
print(f"grid of {G + 1} points, means after each flip " + FLIPS + ": " + ", ".join(f"{m:.4f}" for m in means))
print(f"evidence P(7 of 10) = 16/143 = {16 / 143:.4f}; beta ratio {evid:.4f}; grid {comb(N, S) * z:.4f}; about 1 in {round(1 / evid)}")
c22, c84, c95 = (fact(a + b - 1) // (fact(a - 1) * fact(b - 1)) for a, b in ((2, 2), (8, 4), (9, 5)))
print(f"constants 1/B: Beta(2,2) {c22}, Beta(8,4) {c84}, Beta(9,5) {c95}; C(10,7) = {comb(N, S)}; "
      f"{comb(N, S)} x {c22} / {c95} = {comb(N, S) * c22}/{c95}")
print(f"P(theta > 0.5): prior 0.5000; posterior {int(over * 8192)}/8192 = {over:.4f}, by grid {grid(lambda t: 1, G // 2):.4f}")
w2, d2 = urn(A, B, 2)
print(f"next flip heads: {A}/{T} = {pred(A, B, 1, 1):.4f}; by grid {grid(lambda t: t):.4f}")
print(f"next two, k = 0, 1, 2: formula {', '.join(f'{pred(A, B, 2, k):.4f}' for k in range(3))}; "
      f"urn {w2}/{d2}; grid {', '.join(f'{grid(lambda t: comb(2, k) * t ** k * (1 - t) ** (2 - k)):.4f}' for k in range(3))}")
p = A / T
print(f"plug-in Binomial(2, {A}/{T}): {', '.join(f'{comb(2, k) * p ** k * (1 - p) ** (2 - k):.4f}' for k in range(3))}")
w10, d10 = urn(A, B, 10)
bb = [pred(A, B, 10, k) for k in range(11)]
pl = [comb(10, k) * p ** k * (1 - p) ** (10 - k) for k in range(11)]
gr = [grid(lambda t: comb(10, k) * t ** k * (1 - t) ** (10 - k)) for k in range(11)]
m10 = sum(k * q for k, q in enumerate(bb))
v10 = sum((k - m10) ** 2 * q for k, q in enumerate(bb))
print(f"next ten: mean {m10:.4f}; variance {v10:.4f}, closed form {10 * A * B * (T + 10) / (T * T * (T + 1)):.4f}; "
      f"plug-in variance {10 * p * (1 - p):.4f}; sd {sqrt(v10):.4f} against {sqrt(10 * p * (1 - p)):.4f}")
print(f"next ten, urn paths {2 ** 10}, total {sum(w10)} = 14 x 15 x ... x 23 = {d10}")
# road 4: simulation, SplitMix64 seed 20260929
MASK = (1 << 64) - 1
state = 20260929
def uniform():
    global state
    state = (state + 0x9E3779B97F4A7C15) & MASK
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return (((z ^ (z >> 31)) >> 11) + 0.5) / 2.0 ** 53
R = 200_000
kept, st, st2, sover, snext, stwo = 0, 0.0, 0.0, 0, 0, 0
for _ in range(R):
    th = sorted((uniform(), uniform(), uniform()))[1]   # middle of three uniforms: Beta(2, 2)
    if sum(uniform() < th for _ in range(N)) != S:
        continue
    f1, f2 = uniform() < th, uniform() < th
    kept, st, st2, sover = kept + 1, st + th, st2 + th * th, sover + (th > 0.5)
    snext, stwo = snext + f1, stwo + (f1 and f2)
acc, sm = kept / R, st / kept
ssd = sqrt(st2 / kept - sm * sm)
se = lambda q, n: sqrt(q * (1 - q) / n)
pn, p2, po = snext / kept, stwo / kept, sover / kept
print(f"simulated {R} coins, seed 20260929; kept {kept} showing 7 of 10; estimate (standard error)")
print(f"  evidence {acc:.4f} ({se(acc, R):.4f}); posterior mean {sm:.4f} ({ssd / sqrt(kept):.4f}); "
      f"P(theta > 0.5) {po:.4f} ({se(po, kept):.4f})")
print(f"  next flip heads {pn:.4f} ({se(pn, kept):.4f}); next two both heads {p2:.4f} ({se(p2, kept):.4f})")
# what breaks
print(f"mistake, plug-in for two more: both heads {p * p:.4f} not {pred(A, B, 2, 2):.4f}; "
      f"ten heads in ten {pl[10]:.4f} not {bb[10]:.4f}")
print(f"mistake, prior ignored: next flip {S / N:.4f}")
print(f"mistake, heads added to b: Beta({A0 + N - S},{B0 + S}) mean {(A0 + N - S) / T:.4f}")
d_over = sum(comb(A0 + 2 * N + B0 - 1, j) for j in range(A0 + 2 * S)) / 2 ** (A0 + 2 * N + B0 - 1)
print(f"mistake, the 10 flips counted twice: Beta({A0 + 2 * S},{B0 + 2 * (N - S)}) mean {(A0 + 2 * S) / (T + N):.4f}, "
      f"sd {sqrt((A0 + 2 * S) * (B0 + 2 * N - 2 * S) / ((T + N) ** 2 * (T + N + 1))):.4f}, P(theta > 0.5) {d_over:.4f}")
print(f"try: prior Beta(1,1) next flip {1 + S}/{2 + N} = {(1 + S) / (2 + N):.4f}; Beta(20,20) {(20 + S) / (40 + N):.4f}; "
      f"70 of 100 {A0 + 70}/{A0 + B0 + 100} = {(A0 + 70) / (A0 + B0 + 100):.4f}")
# figures
print("figure, theta: " + ", ".join(f"{i / 10:.1f}" for i in range(11)))
for a, b, lab in ((A0, B0, "prior Beta(2,2)"), (S + 1, N - S + 1, "data alone Beta(8,4)"), (A, B, "posterior Beta(9,5)")):
    print(f"figure, {lab}: " + ", ".join(f"{bdens(i / 10, a, b):.2f}" for i in range(11)))
print("figure, next ten, beta-binomial, percent: " + ", ".join(f"{100 * q:.2f}" for q in bb))
print("figure, next ten, plug-in binomial, percent: " + ", ".join(f"{100 * q:.2f}" for q in pl))
# asserts: every one sets two separate roads side by side
assert abs(grid(lambda t: t) - mean) < 1e-10 and abs(means[-1] - mean) < 1e-10
assert abs(grid(lambda t: 1, G // 2) - over) < 1e-10 and abs(comb(N, S) * z - evid) < 1e-10
assert all(w10[k] == comb(10, k) * rising(A, k) * rising(B, 10 - k) for k in range(11)) and sum(w10) == d10
assert all(abs(g - q) < 1e-10 for g, q in zip(gr, bb)) and abs(v10 - 10 * A * B * (T + 10) / (T * T * (T + 1))) < 1e-12
assert abs(sm - mean) < 4 * ssd / sqrt(kept) and abs(pn - mean) < 4 * se(pn, kept)
assert abs(acc - 16 / 143) < 4 * se(acc, R) and abs(p2 - pred(A, B, 2, 2)) < 4 * se(p2, kept)
