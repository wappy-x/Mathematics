# Plunnecke-Ruzsa and Freiman -- the check behind the card.  Standard library only.
# A = {0..4} with {100..104}.  Every sumset is counted by brute force and set beside
# a block-count formula, the Plunnecke-Ruzsa bound, Petridis's best subset, Ruzsa's
# injection, the progression Freiman predicts, and 300 random sets as evidence.
from itertools import combinations
def plus(X, Y): return sorted({x + y for x in X for y in Y})
def minus(X, Y): return sorted({x - y for x in X for y in Y})
def copies(X, k):                       # kA: k copies of X added; 0A = {0}
    out = [0]
    for _ in range(k): out = plus(out, X)
    return out
def dec(num, den):                      # exact decimal of num/den when den divides 10^8
    k = next(k for k in range(9) if 10**k % den == 0)
    s = str(num * 10**k // den).rjust(k + 1, "0")
    return (s[:len(s) - k] + "." + s[len(s) - k:]).rstrip("0").rstrip(".") if k else s
def name(k, l): return (f"{k}A" if k > 1 else "A") + (f"-{l}A" if l > 1 else "-A" if l else "")
def yn(c): return "yes" if c else "no"
def best_subsets(A, B):                 # Petridis: nonempty X in A with least |X+B|/|X|
    subs = [X for r in range(1, len(A) + 1) for X in combinations(A, r)]
    lo = min(subs, key=lambda X: len(plus(X, B)) / len(X))
    num, den = len(plus(lo, B)), len(lo)
    return num, den, [X for X in subs if len(plus(X, B)) * den == num * len(X)]

A = list(range(5)) + list(range(100, 105))
n, s2 = len(A), len(plus(A, A))
print(f"|A| = {n}, |A+A| = {s2}, K = {dec(s2, n)}; floor 2|A|-1 = {2 * n - 1}, most possible {n * (n + 1) // 2}")
for k, l in [(1, 1), (2, 0), (2, 1), (3, 0), (2, 2), (4, 0), (3, 3)]:
    size = len(minus(copies(A, k), copies(A, l)))
    m = k + l
    blocks = (4 * m + 1) * (m + 1)      # road two: m+1 blocks of 4m+1, from the 2-D picture
    bound = dec(s2**m, n**(m - 1))      # K^(k+l)|A| = 27^m / 10^(m-1)
    print(f"|{name(k, l)}| = {size}; blocks (4*{m}+1)({m}+1) = {blocks}; bound K^{m}|A| = {bound}")
    assert size == blocks and size * n**(m - 1) <= s2**m
num, den, best = best_subsets(A, A)
print(f"Petridis: least |X+A|/|X| = {num}/{den} = {dec(num, den)}, among {2**n - 1} subsets, reached by {len(best)}; it is A itself: {yn(list(best[0]) == A)}")
X = list(best[0])
for cname, C in [("A", A), ("2A", copies(A, 2)), ("3A", copies(A, 3)), ("-A", minus([0], A))]:
    lhs, rhs = len(plus(plus(X, A), C)), len(plus(X, C))
    print(f"lemma with C = {cname}: |X+A+C| = {lhs} <= K'|X+C| = {dec(num * rhs, den)}")
    assert lhs * den <= num * rhs
Y = copies(A, 2)                        # Ruzsa: (x, d) -> (x + y_d, x + z_d), d = y_d - z_d
pick = {}
for y in Y:
    for z in Y: pick.setdefault(y - z, (y, z))
image = {(x + pick[d][0], x + pick[d][1]) for x in A for d in pick}
XY = set(plus(A, Y))
print(f"Ruzsa map on A x (2A-2A): {n} x {len(pick)} = {n * len(pick)} pairs, {len(image)} distinct images, "
      f"all in (A+2A)x(A+2A): {yn(all(a in XY and b in XY for a, b in image))}")
print(f"triangle: |A||2A-2A| = {n * len(pick)} <= |A+2A|^2 = {len(XY)**2} <= (K^2|A|)^2 = {dec(s2**4, n**2)}")
print(f"so |2A-2A| <= {dec(len(XY)**2, n)} <= K^4|A| = {dec(s2**4, n**3)}")
assert len(image) == n * len(pick) and n * len(pick) <= len(XY)**2
P = sorted({a + 100 * b for a in range(5) for b in range(2)})
print(f"Freiman: P = a + 100b (0<=a<=4, 0<=b<=1) has {len(P)} members = 5 x 2, equals A: {yn(P == A)}")
g = 0
for a in A:                             # Euclid's algorithm on the gaps from the least member
    h = a - A[0]
    while h: g, h = h, g % h
line = (A[-1] - A[0]) // g + 1
print(f"shortest 1-D progression holding A: step {g}, {line} terms = {dec(line, n)} x |A|")
print(f"3k-4 test: |A+A| = {s2} vs 3|A|-4 = {3 * n - 4}; its promise, length <= {s2 - n + 1}, would fail: {line} terms")
print(f"Chang: |A+A| < alpha|A| for alpha just above {dec(s2, n)} gives dimension <= {s2 // n - 1}")
assert P == A and line == 105 and s2 > 3 * n - 4
V = list(range(1 << 10))                # all 1,024 vectors of 0s and 1s, added by XOR
xs = {u ^ v for u in V for v in V}
print(f"mod-2 vectors: |A| = {len(V)}, |A+A| = {len(xs)}, K = {len(xs) // len(V)}; a step v has v+v = 0, "
      f"so dimension >= {len(V).bit_length() - 1}")
assert len(xs) == len(V)
T = [0, 1, 3]
print(f"mistake, A-A taken as no bigger than A+A: T = {T} has |T+T| = {len(plus(T, T))}, |T-T| = {len(minus(T, T))}")
assert len(minus(T, T)) > len(plus(T, T))
D = sorted({2 * a for a in A})
print(f"mistake, kA read as k times each member: 2*A has {len(D)} members, 2A has {s2}")
A2, B2, C2 = [0, 2, 5, 7, 17], [0, 2], [0, 5]
lhs, rhs, ab = len(plus(plus(A2, B2), C2)), len(plus(A2, C2)), len(plus(A2, B2))
print(f"mistake, Petridis step with X = all of S = {A2}, B = {B2}, C = {C2}: "
      f"|S+B+C| = {lhs} > (|S+B|/|S|)|S+C| = ({ab}/{len(A2)}) x {rhs} = {dec(ab * rhs, len(A2))}")
num2, den2, best2 = best_subsets(A2, B2)
for Xb in best2:
    l2, r2 = len(plus(plus(Xb, B2), C2)), len(plus(Xb, C2))
    print(f"  best X = {list(Xb)}, ratio {dec(num2, den2)}: |X+B+C| = {l2} <= {dec(num2 * r2, den2)}")
    assert l2 * den2 <= num2 * r2
assert lhs * len(A2) > ab * rhs
state = 2026                            # SplitMix64, seed 2026: random sets as evidence
def rnd():
    global state
    state = (state + 0x9E3779B97F4A7C15) % 2**64
    z = state
    z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9 % 2**64
    z = (z ^ (z >> 27)) * 0x94D049BB133111EB % 2**64
    return z ^ (z >> 31)
tests, worst = 0, (0, 1)
for _ in range(300):
    R = set()
    while len(R) < 6: R.add(rnd() % 50)
    R = sorted(R); r2s = len(plus(R, R))
    for k in range(5):
        for l in range(5 - k):
            if k + l < 2 or l == 0 and k == 2 or k == 0: continue
            sz = len(minus(copies(R, k), copies(R, l)))
            top, bot = sz * 6**(k + l - 1), r2s**(k + l)
            assert top <= bot
            tests += 1
            if top * worst[1] > worst[0] * bot: worst = (top, bot)
print(f"random sets: 300 sets of 6 from 0..49, {tests} bounds with k+l = 2 to 4 checked, worst size/bound = {worst[0] / worst[1]:.4f}")
print("ALL CHECKS PASS")
