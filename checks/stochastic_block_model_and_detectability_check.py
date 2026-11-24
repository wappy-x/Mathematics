# The stochastic block model: plant two groups, find them, and test the Kesten-Stigum line.
# Python standard library only.  Every graph is synthetic, drawn by SplitMix64 from a stated seed.
import math
M64 = (1 << 64) - 1
def rng(s):                                       # SplitMix64: returns (new state, 64-bit draw)
    s = (s + 0x9E3779B97F4A7C15) & M64; z = s
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return s, z ^ (z >> 31)
def sbm(n, cin, cout, seed):                      # one coin per pair: c_in/n inside a group, c_out/n across
    h, st, E = n // 2, seed, []
    for i in range(n):
        for p, lo, hi in ((cin / n, i + 1, i // h * h + h), (cout / n if i < h else 0.0, h, n)):
            if p <= 0.0: continue
            lq, j = math.log(1.0 - p), lo - 1
            while True:                           # jump straight to the next pair whose coin lands "friends"
                st, r = rng(st); j += 1 + int(math.log(((r >> 11) + 1) / 2.0**53) / lq)
                if j >= hi: break
                E.append((i, j))
    return E
def dot(a, b):                                    # plain left-to-right sum (Python's sum() compensates rounding; Rust's does not)
    t = 0.0
    for u, v in zip(a, b): t += u * v
    return t
def norm(x): return math.sqrt(dot(x, x))
def nb(x, src, dst, n):                           # non-backtracking step: walk on, never straight back
    s = [0.0] * n
    for e in range(len(x)): s[src[e]] += x[e]
    return [s[dst[e]] - x[e ^ 1] for e in range(len(x))]
def detect(n, E, seed, deflate=True):             # spectral method on the non-backtracking matrix B
    src = [a for e in E for a in e]; dst = [b for a, b in E for b in (b, a)]
    x = [1.0] * len(src)
    for t in range(40):                           # top eigenvalue of B: about the mean degree c
        y = nb(x, src, dst, n); r = norm(y); lam1 = r / norm(x); x = [v / r for v in y]
    R, Lf = x, [x[e ^ 1] for e in range(len(x))]  # B's left eigenvector is its right one, edges flipped
    LR = dot(Lf, R)
    def defl(v):
        if not deflate: return v
        k = dot(Lf, v) / LR; return [a - k * b for a, b in zip(v, R)]
    st, x = seed + 1, []
    for e in range(len(src)): st, r = rng(st); x.append(1.0 if r >> 63 else -1.0)
    x = defl(x); r = norm(x); x = [v / r for v in x]; logs = []
    for t in range(100):                          # second eigenvector: power steps with the top one removed
        y = defl(nb(x, src, dst, n)); r = norm(y); logs.append(math.log(r)); x = [v / r for v in y]
    mu = math.exp(dot(logs[-20:], [1.0] * 20) / 20)           # growth per step over the last 20 steps
    z = [0.0] * n
    for e in range(len(x)): z[dst[e]] += x[e]     # each person's score: what flows in along their edges
    return lam1, mu, overlap(n, z)
def overlap(n, z):                                # 0 = coin toss, 1 = everyone right (either naming of the groups)
    right = sum((z[v] >= 0.0) == (v < n // 2) for v in range(n)); right = max(right, n - right)
    return 2 * right / n - 1, right
def adjacency_split(n, E, seed):                  # plain spectral: 100 power steps toward the adjacency second eigenvector
    nbr = [[] for _ in range(n)]
    for a, b in E: nbr[a].append(b); nbr[b].append(a)
    Ax = lambda x: [dot([x[w] for w in nbr[v]], [1.0] * len(nbr[v])) for v in range(n)]
    u = [1.0] * n
    for t in range(100): y = Ax(u); r = norm(y); u = [v / r for v in y]
    st, x = seed + 2, []
    for v in range(n): st, r = rng(st); x.append(1.0 if r >> 63 else -1.0)
    for t in range(100):
        y = Ax(x); k = dot(u, y); y = [a - k * b for a, b in zip(y, u)]
        r = norm(y); x = [v / r for v in y]
    return max(len(l) for l in nbr), overlap(n, x)
def pieces(n, E):                                 # flood fill: number of separate pieces, size of the largest
    nbr = [[] for _ in range(n)]
    for a, b in E: nbr[a].append(b); nbr[b].append(a)
    seen, count, big = [False] * n, 0, 0
    for s in range(n):
        if seen[s]: continue
        count += 1; seen[s] = True; stack, size = [s], 0
        while stack:
            v = stack.pop(); size += 1
            for w in nbr[v]:
                if not seen[w]: seen[w] = True; stack.append(w)
        big = max(big, size)
    return count, big
def census(cin, cout, T):                         # tree road: signal-to-noise of the depth-t census, exact recursion
    c, th = (cin + cout) / 2, (cin - cout) / (cin + cout); m, M2, out = 1.0, 1.0, []
    for t in range(T):
        M2, m = c * M2 + (c * th * m) * (c * th * m), c * th * m; out.append(m * m / (M2 - m * m))
    return out
N, SEED = 5000, 2026
print(f"people {N} in two groups of {N // 2}, seed {SEED}")
for cin, cout in ((5, 1), (4, 2)):
    snr = (cin - cout) ** 2 / (2 * (cin + cout))
    print(f"c_in {cin} c_out {cout}: (c_in - c_out)^2 = {(cin - cout) ** 2}  2(c_in + c_out) = {2 * (cin + cout)}  "
          f"lambda = {snr:.4f}  {'detectable' if snr > 1 else 'undetectable'}")
    print(f"  p_in {cin / N:.4f}  p_out {cout / N:.4f}  friends inside {(N // 2 - 1) * cin / N:.4f}  across {N // 2 * cout / N:.4f}"
          f"  theta {(cin - cout) / (cin + cout):.4f}  c theta^2 {(cin + cout) / 2 * ((cin - cout) / (cin + cout)) ** 2:.4f}")
    print(f"  predicted eigenvalues of B: c {(cin + cout) / 2:.4f}  community {(cin - cout) / 2:.4f}  bulk edge sqrt(c) {math.sqrt((cin + cout) / 2):.4f}")
    E = sbm(N, cin, cout, SEED); inside = sum((a < N // 2) == (b < N // 2) for a, b in E)
    lam1, mu, (q, right) = detect(N, E, SEED)
    alone = N - len(set(v for e in E for v in e))
    print(f"  graph: {len(E)} friendships, {inside} inside, {len(E) - inside} across, mean degree {2 * len(E) / N:.4f}, {alone} with none")
    ein, eout = (N // 2) * (N // 2 - 1) * cin / N, (N // 2) ** 2 * cout / N   # friendships the rates predict inside, across
    assert abs(inside - ein) < 4 * ein ** 0.5 and abs(len(E) - inside - eout) < 4 * eout ** 0.5, "friendship counts should match the rates"
    print(f"  measured: top eigenvalue {lam1:.4f}  next growth {mu:.4f}  right {right} of {N}  overlap {q:.4f}")
    t = census(cin, cout, 12)
    print(f"  tree census signal-to-noise, depth 1 2 4 8 12: " + " ".join(f"{t[i - 1]:.4f}" for i in (1, 2, 4, 8, 12)) + f"  limit {max(snr - 1, 0):.4f}")
    assert abs(lam1 - (cin + cout) / 2) < 0.1, "top eigenvalue should sit near the mean degree c"
    assert all(abs(t[i] - (snr - 1) / (1 - snr ** -(i + 1))) < 1e-9 for i in range(12)), "census recursion disagrees with its closed form"
    if snr > 1:
        assert abs(mu - (cin - cout) / 2) < 0.1 and q > 0.2, "above the line the community eigenvalue and the groups should show"
        E51, q51 = E, q
    else:
        assert abs(mu - math.sqrt((cin + cout) / 2)) < 0.1 and q < 0.05, "below the line only the bulk and a coin toss should show"
sweep = []
for cin in (3.5, 4.0, 4.5, 4.75, 5.0, 5.5, 5.75):  # mean degree 3 throughout; only the split between in and out moves
    cout = 6.0 - cin; snr = (cin - cout) * (cin - cout) / 12; _, mu, (q, _) = detect(N, sbm(N, cin, cout, SEED), SEED)
    sweep.append((snr, q)); print(f"sweep c_in {cin:.2f} c_out {cout:.2f}: lambda {snr:.4f}  next growth {mu:.4f}  overlap {q:.4f}")
assert max(q for s, q in sweep if s < 0.9) < 0.07 and 0.2 < min(q for s, q in sweep if s > 1.2), "a cliff near lambda = 1"
print("chart, lambda:overlap " + " ".join(f"{s:.2f}:{q:.2f}" for s, q in sweep))
print("what breaks, at c_in 5, c_out 1:")
dmax, (qa, ra) = adjacency_split(N, E51, SEED)
print(f"  plain adjacency eigenvector, 100 steps: right {ra} of {N}, overlap {qa:.4f}; busiest person {dmax} friends")
assert qa < 0.1 < q51, "plain adjacency should fail where non-backtracking succeeds"
cnt, big = pieces(N, E51)
print(f"  Laplacian: the network falls into {cnt} pieces (largest {big}), so {cnt} zero eigenvalues and lambda_2 = 0")
_, mu0, (q0, r0) = detect(N, E51, SEED, deflate=False)
print(f"  top eigenvector left in: growth {mu0:.4f}, right {r0} of {N}, overlap {q0:.4f}")
assert cnt > 1 and abs(mu0 - 3) < 0.1 and q0 < 0.1, "these mistakes should fail"
for n, seed in ((10000, SEED), (N, 7)):            # the "Try changing" runs
    lam1, mu, (q, right) = detect(n, sbm(n, 5, 1, seed), seed)
    print(f"try: c_in 5 c_out 1, {n} people, seed {seed}: top {lam1:.4f}  next growth {mu:.4f}  right {right} of {n}  overlap {q:.4f}")
print("ALL CHECKS PASS")
