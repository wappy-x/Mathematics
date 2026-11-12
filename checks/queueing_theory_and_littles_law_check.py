# Queues and Little's law -- the check behind the card.  Standard library only;
# nothing imported holds the answer.  One till: 55 customers an hour arrive, the
# till serves 60 an hour when busy.  Time is in hours, waits printed in minutes.
# Roads: closed forms (M/M/1, Erlang C, fixed service time); the cut equations
# solved state by state; the arrival's-eye view (wait = L / mu); and seeded
# simulations (SplitMix64) with batch standard errors, where Little's law is
# checked by sweeping the count of people in the shop over time.
from math import log, sqrt, factorial
LAM, MU, SEED, MASK = 55.0, 60.0, 20261111, (1 << 64) - 1
class SplitMix64:
    def __init__(self, seed): self.s = seed & MASK
    def uniform(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
    def expo(self, rate): return -log(1.0 - self.uniform()) / rate
def erlang_c(lam, mu, c):          # closed form: (chance of waiting, Wq in hours)
    a = lam / mu
    top = a ** c / factorial(c) / (1.0 - a / c)
    pw = top / (sum(a ** k / factorial(k) for k in range(c)) + top)
    return pw, pw / (c * mu - lam)
def cuts(lam, mu, c, nmax=6000):    # lam * p[n] = min(n+1, c) * mu * p[n+1], then normalise
    p = [1.0]
    for n in range(nmax): p.append(p[-1] * lam / (min(n + 1, c) * mu))
    s = sum(p)
    p = [x / s for x in p]
    L = sum(n * x for n, x in enumerate(p))
    Lq = sum((n - c) * p[n] for n in range(c, len(p)))
    return p, L, Lq
def simulate(lam, mu, c, n, rng, fixed=False, batches=20):
    free, t, arr, dep, means, acc = [0.0] * c, 0.0, [], [], [], 0.0
    for i in range(n):
        t += rng.expo(lam)
        s = 1.0 / mu if fixed else rng.expo(mu)
        k = min(range(c), key=lambda j: free[j])   # first till to come free, first come first served
        start = max(t, free[k])
        free[k] = start + s
        arr.append(t); dep.append(start + s); acc += start - t
        if (i + 1) % (n // batches) == 0: means.append(acc / (n // batches)); acc = 0.0
    m = sum(means) / batches
    se = sqrt(sum((x - m) ** 2 for x in means) / (batches - 1) / batches)
    return m, se, arr, dep
def sweep(arr, dep):                # time-average of the number in the shop, counted event by event
    T, i, j, num, last, area = arr[-1], 0, 0, 0, 0.0, 0.0
    while i < len(arr) or (j < len(dep) and dep[j] <= T):
        if i < len(arr) and arr[i] <= dep[j]: tm, step = arr[i], 1; i += 1
        else: tm, step = dep[j], -1; j += 1
        area += num * (tm - last); num += step; last = tm
    return area / T, len(arr) / T, sum(d - a for a, d in zip(arr, dep)) / len(arr)
mins = lambda h: 60.0 * h
rho = LAM / MU
L, W, Wq = rho / (1 - rho), 1.0 / (MU - LAM), rho / (MU - LAM)
p1, L1, Lq1 = cuts(LAM, MU, 1)
print(f"one till: busy {rho:.4f}, idle {mins(1 - rho):.1f} min an hour, spare rate {MU - LAM:.0f} an hour")
print(f"formula: L {L:.3f}, Lq {rho * rho / (1 - rho):.3f}, W {mins(W):.2f} min, Wq {mins(Wq):.2f} min, service {mins(1 / MU):.2f} min")
print(f"cut equations: P(empty) {p1[0]:.4f}, L {L1:.3f}, Lq {Lq1:.3f}, Wq = Lq/lam {mins(Lq1 / LAM):.2f} min")
print(f"arrival's view: Wq = L/mu {mins(L / MU):.2f} min; server alone: lam x service = {LAM / MU:.4f}")
assert abs(L1 - L) < 1e-9 and abs(Lq1 / LAM - Wq) < 1e-12 and abs(L / MU - Wq) < 1e-12
assert abs(p1[0] - (1 - rho)) < 1e-12 and abs(L1 - Lq1 - rho) < 1e-9   # Little on the till itself
print("figure, arrivals an hour, Wq M/M/1 min, Wq fixed service min")
for lam in [30, 36, 42, 48, 51, 54, 55, 57, 58, 59]:
    r = lam / MU
    print(f"figure, {lam}, {mins(r / (MU - lam)):.2f}, {mins(r / (2 * (MU - lam))):.2f}")
print("Wq at 50, 55, 56 an hour: " + ", ".join(f"{mins(x / MU / (MU - x)):.2f}" for x in (50, 55, 56)) + " min")
rows = [(f"one till, {LAM:.0f} an hour", LAM, 1), (f"two tills, {LAM:.0f} an hour", LAM, 2),
        (f"two tills, {2 * LAM:.0f} an hour", 2 * LAM, 2)]
for name, lam, c in rows:
    pw, wq = erlang_c(lam, MU, c)
    p, Lc, Lq = cuts(lam, MU, c)
    pw2 = sum(p[c:])
    print(f"{name}: each till busy {lam / (c * MU):.4f}, P(wait) {pw:.4f} (cuts {pw2:.4f}), Wq {mins(wq):.2f} min (cuts {mins(Lq / lam):.2f}), Lq {lam * wq:.3f}")
    assert abs(pw - pw2) < 1e-9 and abs(wq - Lq / lam) < 1e-12
split_wq = (LAM / 2 / MU) / (MU - LAM / 2)
print(f"two tills, separate lines, {LAM / 2:.1f} an hour each: Wq {mins(split_wq):.2f} min")
a, top = LAM / MU, (LAM / MU) ** 2 / 2 / (1 - LAM / MU / 2)
print(f"Erlang C by hand, two tills at {LAM:.0f}: top {top:.4f}, bottom {1 + a + top:.4f}, spare rate {2 * MU - LAM:.0f} an hour, "
      f"Wq {60 * mins(erlang_c(LAM, MU, 2)[1]):.0f} seconds")
rng = SplitMix64(SEED)
N = 1_000_000
for name, lam, c, fixed, want in [(f"M/M/1 at {LAM:.0f}", LAM, 1, False, Wq),
                                  (f"fixed {mins(1 / MU):.2f}-minute service at {LAM:.0f}", LAM, 1, True, Wq / 2),
                                  (f"M/M/2 at {2 * LAM:.0f}", 2 * LAM, 2, False, erlang_c(2 * LAM, MU, 2)[1])]:
    m, se, arr, dep = simulate(lam, MU, c, N, rng, fixed)
    print(f"simulated {name}: Wq {mins(m):.2f} min, s.e. {mins(se):.2f}, formula {mins(want):.2f}")
    assert abs(m - want) < 4 * se
    if c == 1:
        Ls, lam_hat, W_hat = sweep(arr, dep)
        print(f"  Little: L by sweep {Ls:.3f}; lam x W = {lam_hat:.3f} x {mins(W_hat):.2f} min = {lam_hat * W_hat:.3f}")
        assert abs(Ls - lam_hat * W_hat) < 0.01 * Ls
print(f"plugging 62 an hour into rho/(1 - rho): L = {(62 / MU) / (1 - 62 / MU):.1f}")
days, ends = 400, {55.0: [0.0] * 9, 62.0: [0.0] * 9}
for lam in ends:
    for _ in range(days):
        t, free, arr, dep = 0.0, 0.0, [], []
        while True:
            t += rng.expo(lam)
            if t > 8.0: break
            free = max(t, free) + rng.expo(MU)
            arr.append(t); dep.append(free)
        for a, d in zip(arr, dep):
            for h in range(1, 9):
                if a <= h < d: ends[lam][h] += 1.0 / days
    print(f"from empty, mean in shop at hours 1..8, {lam:.0f} an hour: " + " ".join(f"{x:.1f}" for x in ends[lam][1:]))
assert ends[62.0][8] > ends[62.0][4] + 4 and ends[62.0][8] > ends[55.0][8] + 8 and ends[55.0][8] < L
print(f"30 vans, 2.5-hour loop: Little gives {30 / 2.5:.0f} departures an hour")
pw3, wq3 = erlang_c(LAM, MU, 3)                       # the Try changing box, without editing
print(f"try: LAM 58 -> Wq {mins(58 / MU / (MU - 58)):.2f} min; MU 66 -> Wq {mins(LAM / 66 / (66 - LAM)):.2f} min, "
      f"and 62 an hour has long-run L {(62 / 66) / (1 - 62 / 66):.1f}")
print(f"try: three tills at {LAM:.0f} -> P(wait) {pw3:.4f}, Wq {mins(wq3):.2f} min ({60 * mins(wq3):.1f} seconds)")
print("ALL CHECKS PASS")
