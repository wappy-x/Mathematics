# PageRank by power iteration: one pass over the links per step, dangling pages
# folded into the jump, a stopping rule that certifies the ranking, at two sizes.
A = 0.85                                            # the damping factor, alpha
NAMES = ["Home", "Map", "Prices", "Join", "Help", "Terms"]
LINKS = [[1, 2, 5], [0], [0, 3], [1, 4, 5], [0, 5], []]   # Terms is a PDF: no links out

def step(x, links, a=A, fold=True):                 # one pass: touches each link once
    n, y, dang = len(x), [0.0] * len(x), 0.0
    for i in range(n):
        if links[i]:
            share = a * x[i] / len(links[i])
            for j in links[i]:
                y[j] += share
        else:
            dang += x[i]                            # rank parked on a dangling page
    extra = ((a * dang if fold else 0.0) + (1 - a)) / n
    return [v + extra for v in y]

def l1(x, y):                                       # total size of the differences
    return sum(abs(p - q) for p, q in zip(x, y))

def f4(x):
    return " ".join(f"{v:.4f}" for v in x)

def iterate(links, a, passes, x=None, fold=True):
    x = x or [1 / len(links)] * len(links)
    for _ in range(passes):
        x = step(x, links, a, fold)
    return x

def certify(links, a, cap=300):                     # stop when bound < smallest gap
    x, k = [1 / len(links)] * len(links), 0
    while k < cap:
        xn = step(x, links, a); k += 1
        bound, s = a / (1 - a) * l1(xn, x), sorted(xn, reverse=True)
        x = xn
        if bound < min(s[i] - s[i + 1] for i in range(len(s) - 1)):
            return k, " > ".join(NAMES[i] for i in sorted(range(len(x)), key=lambda i: -x[i]))
    return "none by", f"pass {cap}: {f4(x)}"        # a tie is never certified

def solve(links, a):                                # road 2: Gaussian elimination
    n = len(links)
    M = [[float(i == j) for j in range(n)] + [(1 - a) / n] for i in range(n)]
    for i in range(n):
        out = links[i] or list(range(n))            # dangling: spread evenly
        for j in out:
            M[j][i] -= a / len(out)
    for c in range(n):
        p = max(range(c, n), key=lambda r: abs(M[r][c]))
        M[c], M[p] = M[p], M[c]
        for r in range(n):
            if r != c:
                f = M[r][c] / M[c][c]
                M[r] = [u - f * v for u, v in zip(M[r], M[c])]
    return [M[i][n] / M[i][i] for i in range(n)]

def splitmix(s):                                    # SplitMix64, written out
    s = (s + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = ((s ^ (s >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return s, (z ^ (z >> 31)) >> 11                 # 53 random bits
n, pi = 6, solve(LINKS, A)
print("page              " + " ".join(f"{s:>6}" for s in NAMES))
print("pi, solved         " + f4(pi) + f"  links {sum(len(l) for l in LINKS)}")
inflow = 1 / 6 + 1 / 12 + 1 / 12                    # Map, Prices, Help into Home
print(f"by hand, Home: links in {inflow:.4f}, x alpha {A * inflow:.4f}, "
      f"Terms' share {A / 36:.4f}, jump {(1 - A) / 6:.4f}, total {A * inflow + A / 36 + (1 - A) / 6:.4f}")
x, hist, e0 = [1 / n] * n, [], l1([1 / n] * n, pi)
print(f"pass  0  {f4(x)}  error {e0:.4f}")
for k in range(1, 61):                              # road 1: power iteration
    xn = step(x, LINKS)
    d, e = l1(xn, x), l1(xn, pi)
    s = sorted(xn, reverse=True)
    hist.append((k, xn, d, e, A / (1 - A) * d, min(s[i] - s[i + 1] for i in range(n - 1))))
    assert e <= A / (1 - A) * d + 1e-15 and e <= A ** k * e0 + 1e-15   # the two promises
    x = xn
for k, xn, d, e, b, g in hist[:12]:
    print(f"pass {k:2d}  {f4(xn)}  change {d:.4f}  bound {b:.4f}  gap {g:.4f}  error {e:.4f}")
stop, order = certify(LINKS, A)
print(f"certified at pass {stop}: {order}, total {sum(hist[11][1]):.6f}, alpha/(1-alpha) {A / (1 - A):.2f}")
print("chart, error      " + " ".join(f"{h[3]:.4f}" for h in hist[:12]))
print("chart, 0.85^k e0  " + " ".join(f"{A ** h[0] * e0:.4f}" for h in hist[:12]))
pu = iterate(LINKS, 1.0, 400)                       # same site with no damping
eu = [l1(iterate(LINKS, 1.0, k), pu) for k in (39, 40)]
r_d, r_u = hist[39][3] / hist[38][3], eu[1] / eu[0]
print(f"error shrink per pass: damped {r_d:.4f}, undamped {r_u:.4f}, ratio {r_d / r_u:.4f}")
print("no damping, limit  " + f4(pu))
seed, page, visits = 2026, 0, [0] * n               # road 3: a random surfer
for t in range(1000000):
    seed, u = splitmix(seed)
    seed, v = splitmix(seed)
    if LINKS[page] and u < A * 2 ** 53:
        page = LINKS[page][v * len(LINKS[page]) >> 53]
    else:
        page = v * n >> 53
    visits[page] += 1
sim = [c / 1000000 for c in visits]
print("surfer, 1e6 clicks " + f4(sim))
y = iterate(LINKS, A, 12, fold=False)               # what breaks
print("wrong: Terms' rank dropped, 12 passes " + f4(y) + f"  total {sum(y):.4f}")
z = iterate(LINKS[:5] + [[5]], A, 300)
print("wrong: Terms links to itself          " + f4(z))
w = [iterate([[1], [0]], 1.0, k, [1.0, 0.0]) for k in (100, 101)] + [iterate([[1], [0]], A, 30, [1.0, 0.0])]
for lab, v in zip(("no damping, pass 100", "no damping, pass 101", "alpha 0.85, pass 30"), w):
    print("two-page loop, " + lab, f4(v))
for a in (0.99, 0.5):
    print(f"try: alpha {a}, certified at pass", *certify(LINKS, a))
print("try: Home drops Terms, certified at pass", *certify([[1, 2]] + LINKS[1:], A))
print("try: Help drops Terms, certified", *certify(LINKS[:4] + [[0], []], A))
N, seed, net = 5000, 7, []                          # at scale: 5,000 people, synthetic
for i in range(N):
    seed, u = splitmix(seed)
    fol = []
    while len(fol) < u % 21:                        # follows 0 to 20 people
        seed, v = splitmix(seed)
        j = ((v * v) >> 53) * N >> 53               # low numbers are more popular
        if j != i and j not in fol:
            fol.append(j)
    net.append(fol)
m = sum(len(f) for f in net)
print("people", N, " links", m, " follow nobody", sum(1 for f in net if not f))
ref = iterate(net, A, 250)
x, k, d, errs = [1 / N] * N, 0, 1.0, [l1([1 / N] * N, ref)]
while A / (1 - A) * d >= 1e-6:                      # stop: guaranteed error < 1e-6
    xn = step(x, net); k += 1
    d, x = l1(xn, x), xn
    errs.append(l1(x, ref))
kp = next(t for t in range(1, 999) if 2 * A ** t < 1e-6)
print("per pass: link visits", m + N, " full table", N * N)
print("passes:", k, " promised at most", kp, " total visits", k * (m + N), " full table", k * N * N)
print(f"error shrink per pass, last: {errs[-1] / errs[-2]:.4f}")
top = sorted(range(N), key=lambda i: -x[i])[:3]
print("top three people", *top, " ".join(f"{x[i]:.5f}" for i in top))
assert max(abs(p - q) for p, q in zip(hist[59][1], pi)) < 1e-11       # iteration = solve
assert max(abs(p - q) for p, q in zip(sim, pi)) < 0.002              # surfer = solve
assert abs(r_d / r_u - A) < 1e-3                    # damping scales the shrink by alpha
assert stop == 12 and abs(sum(hist[11][1]) - 1) < 1e-12
assert sum(y) < 0.9 and z[5] > 0.5 and l1(w[0], w[1]) > 1.99      # the three breaks
assert all(errs[t + 1] <= A * errs[t] + 1e-15 for t in range(k)) and k <= kp
print("ALL CHECKS PASS")
