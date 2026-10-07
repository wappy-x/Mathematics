# Alternating series -- the check behind the card.  Nothing is imported.
# Road one adds the terms 1 - 1/2 + 1/3 - ... in order.  Road two builds ln 2
# with no series at all: Simpson's rule on the area under 1/(1+t), t from 0 to 1.

def simpson(f, a, b, panels):            # parabolas through each pair of strips
    h = (b - a) / panels
    s = f(a) + f(b)
    for i in range(1, panels):
        s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3

def partial(terms, n):                   # add the first n terms, in the given order
    total = 0.0
    for k in range(1, n + 1):
        total += terms(k)
    return total

harmonic = lambda k: (1.0 if k % 2 else -1.0) / k
def rearranged(k):                       # two odd reciprocals up, then one even down
    m, r = (k + 2) // 3, k % 3
    return 1.0 / (4 * m - 3) if r == 1 else (1.0 / (4 * m - 1) if r == 2 else -1.0 / (2 * m))
def geo_rearranged(k):                   # 1 - 1/2 + 1/4 - ... in the same two-up, one-down order
    m, r = (k + 2) // 3, k % 3
    return 0.25 ** (2 * m - 2) if r == 1 else (0.25 ** (2 * m - 1) if r == 2 else -0.5 * 0.25 ** (m - 1))

L = simpson(lambda t: 1.0 / (1.0 + t), 0.0, 1.0, 2000)
print(f"ln 2 by Simpson, 2000 strips: {L:.9f}")
print("chart S_n, n=1..12: " + " ".join(f"{partial(harmonic, n):.2f}" for n in range(1, 13)))
print("chart T_n, n=1..12: " + " ".join(f"{partial(rearranged, n):.2f}" for n in range(1, 13)))
for n in (10, 100, 999):
    s = partial(harmonic, n)
    err, bound = L - s, 1.0 / (n + 1)
    assert abs(err) <= bound         # the tail is no bigger than the next term
    assert (err > 0) == (n % 2 == 0) # and it points the way the next term points
    print(f"N={n}: S_N={s:.9f}  ln2-S_N={err:+.9f}  bound b_(N+1)={bound:.9f}")
n_bound = next(n for n in range(1, 10 ** 6) if 1.0 / (n + 1) <= 0.001)
s, n_true = 0.0, 0
while n_true == 0 or abs(L - s) > 0.001:   # walk until the true error is small
    n_true += 1
    s += harmonic(n_true)
print(f"within 0.001: bound certifies N={n_bound}; true error first there at N={n_true}")
for m in (10, 100, 1000):
    t = partial(rearranged, 3 * m)
    slack = 1.0 / (4 * m + 1) + 0.5 / (2 * m + 1)   # two alternating tails, added
    assert abs(t - 1.5 * L) <= slack
    print(f"rearranged, {m} triples: T={t:.9f}  (3/2)ln2={1.5 * L:.9f}  gap={t - 1.5 * L:+.9f}")
for m in (8, 64):
    seq = []
    for k in range(1, m + 1):
        seq += [1.0 / k, -1.0 / (2 * k)]     # alternates, shrinks to 0, not steadily
    half_h = partial(lambda k: 1.0 / k, m) / 2
    print(f"not decreasing, {m} pairs: total={sum(seq):.6f}  H_m/2={half_h:.6f}")
print("not shrinking, 1-1+1-...: " + " ".join(f"{partial(lambda k: (-1) ** (k + 1), n):.0f}" for n in range(1, 7)))
geo = partial(lambda k: (-0.5) ** (k - 1), 60)
geo_re = partial(geo_rearranged, 60)
assert abs(geo_re - 2 / 3) < 1e-12   # absolute convergence: order is harmless
print(f"1-1/2+1/4-...: in order={geo:.9f}  reordered={geo_re:.9f}  closed form 2/3={2 / 3:.9f}")
print("all checks passed")
