# Holder's inequality on a week of wind and prices: the check behind the card.
# Standard library only. Own Simpson integrator, own minimiser, own random numbers.
W = [3, 5, 8, 2, 6, 4, 7]           # mean wind speed each day, m/s = MWh sold that day
C = [60, 50, 30, 70, 40, 55, 35]    # electricity price each day, $/MWh
INF = float("inf")

def norm(v, p, mu=None):            # the p-size of v against weights mu (counting measure if None)
    mu = mu or [1.0] * len(v)
    if p == INF: return float(max(abs(x) for x, m in zip(v, mu) if m > 0))
    return sum(m * abs(x) ** p for x, m in zip(v, mu)) ** (1.0 / p)
def conj(p): return INF if p == 1 else (1.0 if p == INF else p / (p - 1))
def bound(u, v, p, mu=None): return norm(u, p, mu) * norm(v, conj(p), mu)
def f6(x): return f"{x:.6f}"

dot = sum(a * b for a, b in zip(W, C))
print("data,revenue by day $," + " ".join(str(a * b) for a, b in zip(W, C)))
print("data,revenue sum w*c $," + str(dot))
print("norms,wind 1 2 3 inf," + " ".join(f6(norm(W, p)) for p in (1, 2, 3, INF)))
print("norms,price 1 3/2 2 inf," + " ".join(f6(norm(C, p)) for p in (1, 1.5, 2, INF)))
print(f"norms,sum w^2 sum c^2,{sum(a * a for a in W)} {sum(b * b for b in C)}")

# road 1: the bound for many conjugate pairs, and the best p by golden-section search
ps = [1, 1.25, 1.5, 1.75, 2, 3, 4, 6, 10, INF]
for p in ps:
    b = bound(W, C, p)
    assert b >= dot, p
    print(f"sweep,p={p} q={conj(p):.4f},{b:.2f}")
lo, hi, g = 1.01, 6.0, (5 ** 0.5 - 1) / 2
for _ in range(80):
    m1, m2 = hi - g * (hi - lo), lo + g * (hi - lo)
    if bound(W, C, m1) < bound(W, C, m2): hi = m2
    else: lo = m1
pbest = (lo + hi) / 2
print("best,p q bound," + f6(pbest) + " " + f6(conj(pbest)) + " " + f6(bound(W, C, pbest)))

# road 2: Cauchy-Schwarz slack in whole numbers, by Lagrange's identity
lhs = sum(a * a for a in W) * sum(b * b for b in C) - dot * dot
rhs = sum((W[i] * C[j] - W[j] * C[i]) ** 2 for i in range(7) for j in range(i + 1, 7))
assert lhs == rhs
cs_by_identity = (dot * dot + rhs) ** 0.5
assert abs(cs_by_identity - bound(W, C, 2)) < 1e-9
print(f"lagrange,norms route,{lhs}")
print(f"lagrange,pairs route,{rhs}")
print("lagrange,sqrt(1515^2 + pairs)," + f6(cs_by_identity))

# road 3: the proof itself, day by day: Young on the rescaled values at p = 2 and p = 3
for p in (2, 3):
    q = conj(p); F = [a / norm(W, p) for a in W]; G = [b / norm(C, q) for b in C]
    gaps = [f ** p / p + h ** q / q - f * h for f, h in zip(F, G)]
    assert min(gaps) >= 0                                   # Young at every day: the step that can fail
    assert abs(sum(gaps) - (1 - dot / bound(W, C, p))) < 1e-12   # consistency only: algebra once 1/p + 1/q = 1
    if p == 2:
        for i in range(7):
            print(f"young p=2,day {i + 1} F G FG gap,{F[i]:.4f} {G[i]:.4f} {F[i] * G[i]:.4f} {gaps[i]:.4f}")
    print(f"young p={p},sum FG sum gaps," + f6(sum(f * h for f, h in zip(F, G))) + " " + f6(sum(gaps)))

# the same week as an average: uniform probability 1/7 on each day
P = [1 / 7] * 7
avg = sum(m * a * b for m, a, b in zip(P, W, C))
assert abs(bound(W, C, 2, P) - bound(W, C, 2) / 7) < 1e-9 and avg <= bound(W, C, 2, P)
print("average,mean wind mean price," + f6(sum(W) / 7) + " " + f6(sum(C) / 7))
print("average,E[wc] and its p=2 bound," + f6(avg) + " " + f6(bound(W, C, 2, P)))

# correlation, two roads: centred vectors in floats, raw sums in whole numbers
mw, mc = sum(W) / 7, sum(C) / 7
dw, dc = [a - mw for a in W], [b - mc for b in C]
r1 = sum(a * b for a, b in zip(dw, dc)) / (norm(dw, 2) * norm(dc, 2))
num = 7 * dot - sum(W) * sum(C)
r2 = num / ((7 * sum(a * a for a in W) - sum(W) ** 2) * (7 * sum(b * b for b in C) - sum(C) ** 2)) ** 0.5
assert abs(r1 - r2) < 1e-12 and abs(r1) <= 1
print("correlation,centred sums of squares," + f6(norm(dw, 2) ** 2) + " " + f6(norm(dc, 2) ** 2))
print(f"correlation,sum of centred products,{num / 7:.6f}")
print("correlation,centred route raw route," + f6(r1) + " " + f6(r2))
print("correlation,uncentred cosine," + f6(dot / bound(W, C, 2)))

# equality: sizes in proportion
for p, v, lab in ((2, [10 * a for a in W], "p=2 price 10w"), (3, [a * a for a in W], "p=3 price w^2"),
                  (4, [a ** 3 for a in W], "p=4 price w^3")):
    s = sum(a * b for a, b in zip(W, v))
    assert abs(bound(W, v, p) - s) < 1e-9 * s
    print(f"equality,{lab} sum bound,{s} " + f6(bound(W, v, p)))

ws, cs = sorted(W), sorted(C)     # windiest day paired with the highest price
srt = sum(a * b for a, b in zip(ws, cs))
assert dot < srt <= bound(ws, cs, 2)
print(f"equality,sorted pairing revenue and its p=2 bound,{srt} " + f6(bound(ws, cs, 2)))

# what breaks
fake33 = norm(W, 3) * norm(C, 3)
rev = sum(a ** 0.5 for a in W) ** 2 / sum(1 / b for b in C)
assert fake33 < dot and rev < dot
print("breaks,p=q=3 not conjugate," + f6(fake33))
print("breaks,p=1/2 q=-1 pieces (sum sqrt w)^2 sum 1/c," + f6(sum(a ** 0.5 for a in W) ** 2) + " " + f6(sum(1 / b for b in C)))
print("breaks,p=1/2 q=-1," + f6(rev))
print("breaks,sum w vs ||w||_2 counting," + f6(norm(W, 1)) + " " + f6(norm(W, 2)))
print("breaks,mean w vs ||w||_2 probability," + f6(norm(W, 1, P)) + " " + f6(norm(W, 2, P)))

# Young's inequality as areas: a = 2, b = 3, p = 3, curve y = x^2
def simpson(f, a, b, n=2000):
    h = (b - a) / n
    return (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))) * h / 3
a, b = 2.0, 3.0
A, B = simpson(lambda x: x * x, 0, a), simpson(lambda x: b - x * x, 0, b ** 0.5)   # B: left of the curve
sliver = simpson(lambda x: x * x - b, b ** 0.5, a)
assert abs(A - a ** 3 / 3) < 1e-9 and abs(B - b ** 1.5 / 1.5) < 1e-6 and abs(A + B - a * b - sliver) < 1e-6
print("young area,A B ab sliver," + " ".join(f6(x) for x in (A, B, a * b, sliver)))
print(f"figure,origin 40 210 unit 45,a_x {40 + 45 * a:.2f} b_y {210 - 45 * b:.2f} "
      f"top_y {210 - 45 * a * a:.2f} cross_x {40 + 45 * b ** 0.5:.2f} ctrl_x {40 + 45 * a / 2:.2f} {40 + 45 * b ** 0.5 / 2:.2f}")

# random pairs: SplitMix64, seed 20260929; no pair beats its bound
S, MASK = 20260929, (1 << 64) - 1
def rnd():
    global S
    S = (S + 0x9E3779B97F4A7C15) & MASK; z = S
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
    return ((z ^ (z >> 31)) >> 11) / 2.0 ** 53
worst = 0.0
for _ in range(20000):
    p = 1.1 + 6.9 * rnd()
    u = [2 * rnd() - 1 for _ in range(7)]; v = [2 * rnd() - 1 for _ in range(7)]
    worst = max(worst, sum(abs(x * y) for x, y in zip(u, v)) / bound(u, v, p))
assert worst <= 1 + 1e-12
print("random,20000 pairs p in 1.1 to 8 largest sum/bound," + f6(worst))
print("All checks passed.")
