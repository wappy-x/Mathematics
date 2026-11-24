# Online convex optimisation and regret -- the check behind the card.  Standard library only.
# Each morning a tracker overlay commits to a mix w of three sector sleeves (w on the simplex),
# then sees the day's loss f_t(w) = -c_t.w + (mu/2)|w - z|^2, where c_t is each sleeve's return
# minus the sleeves' average and z is the index mix.  Roads: online gradient descent (two step
# rules) and exponentiated gradient, scored against the best fixed mix in hindsight, which is
# found by a projection formula and by enumerating a grid of mixes; the proved bounds; the floor
# on coin-flip days, by a recursion and by binomial sums; online-to-batch over 200 simulated years.
import math

T, n, mu, D, G = 250, 3, 0.01, math.sqrt(2), 0.05
z, m = [0.5, 0.3, 0.2], [0.0006, 0.0002, -0.0004]   # index mix; mean daily return of each sleeve
M64 = (1 << 64) - 1
def splitmix(s):
    s = (s + 0x9E3779B97F4A7C15) & M64; x = s
    x = ((x ^ (x >> 30)) * 0xBF58476D1CE4E5B9) & M64
    x = ((x ^ (x >> 27)) * 0x94D049BB133111EB) & M64
    return s, x ^ (x >> 31)
def dot(a, b): return sum(x * y for x, y in zip(a, b))
def proj(v):              # nearest point of the simplex: shift every entry by one amount, clip at 0
    cs, th = 0.0, 0.0
    for i, x in enumerate(sorted(v, reverse=True)):
        cs += x
        if x > (cs - 1) / (i + 1): th = (cs - 1) / (i + 1)
    return [max(x - th, 0.0) for x in v]
def year(seed):           # 250 days of centred returns: sleeve mean plus uniform noise of +-1.5 %
    C = []
    for t in range(T):
        r = []
        for i in range(n):
            seed, x = splitmix(seed); r.append(m[i] + 0.015 * (2 * (x >> 11) / 2**53 - 1))
        C.append([x - sum(r) / n for x in r])
    return C
def f(c, w): return -dot(c, w) + mu / 2 * sum((a - b)**2 for a, b in zip(w, z))
def grad(c, w): return [-a + mu * (b - y) for a, b, y in zip(c, w, z)]
def ogd(C, step):         # commit w_t, see f_t, step against its gradient, project back
    w, L, W = z[:], 0.0, []
    for t, c in enumerate(C, 1):
        W.append(w); L += f(c, w); g = grad(c, w)
        w = proj([a - step(t) * b for a, b in zip(w, g)])
    return L, W + [w]         # mixes w_1 .. w_(T+1)
def best_fixed(C):        # sum of f_t = (mu t/2)|w - z - S/(mu t)|^2 + const, so project
    S = [sum(c[i] for c in C) for i in range(n)]
    u = proj([z[i] + S[i] / (mu * len(C)) for i in range(n)])
    return u, sum(f(c, u) for c in C), S

C = year(2024)
print(f"gradient bound: max |c_t| + mu sqrt(2) = {max(math.sqrt(dot(c, c)) for c in C) + mu * D:.4f} <= G = {G}")
u, best, S = best_fixed(C)
N = 600; grid = min(-dot(S, w) + mu * T / 2 * sum((a - b)**2 for a, b in zip(w, z))
                    for i in range(N + 1) for j in range(N + 1 - i) for w in [[i / N, j / N, (N - i - j) / N]])
print(f"best fixed mix in hindsight: ({u[0]:.4f}, {u[1]:.4f}, {u[2]:.4f}), total loss {best:.6f}; "
      f"grid of {(N + 1) * (N + 2) // 2} mixes: {grid:.6f}")
assert best <= grid + 1e-12 and grid - best < 1e-6
eta = lambda t: D / (G * math.sqrt(t))
h, w0 = 1e-6, [0.2, 0.3, 0.5]         # the gradient against central differences
for i in range(n):
    up, dn = ([y + s * h * (k == i) for k, y in enumerate(w0)] for s in (1, -1))
    assert abs((f(C[0], up) - f(C[0], dn)) / (2 * h) - grad(C[0], w0)[i]) < 1e-9
c, g = C[0], grad(C[0], z); v = [a - eta(1) * b for a, b in zip(z, g)]; w2 = proj(v)
print(f"day 1: c_1 = ({c[0]:+.5f}, {c[1]:+.5f}, {c[2]:+.5f}), step {eta(1):.4f}, "
      f"w_1 - step g_1 = ({v[0]:.4f}, {v[1]:.4f}, {v[2]:.4f}), w_2 = ({w2[0]:.4f}, {w2[1]:.4f}, {w2[2]:.4f})")
L, W = ogd(C, eta)
clip = 0
for t in range(T):        # the one-step inequality of Step 1, every day, against the hindsight mix
    g = grad(C[t], W[t]); clip += min(a - eta(t + 1) * b for a, b in zip(W[t], g)) < 0
    d0, d1 = (sum((a - b)**2 for a, b in zip(W[k], u)) for k in (t, t + 1))
    assert abs(sum(W[t + 1]) - 1) < 1e-12 and min(W[t + 1]) >= 0      # each mix is on the simplex
    assert dot(g, [a - b for a, b in zip(W[t], u)]) <= (d0 - d1) / (2 * eta(t + 1)) + eta(t + 1) * dot(g, g) / 2 + 1e-15
bound = 1.5 * D * G * math.sqrt(T)
print(f"OGD, step D/(G sqrt t): loss {L:.6f}, regret {L - best:.6f} ({(L - best) / T:.6f} a day); "
      f"bound 1.5 D G sqrt(T) = 1.5 x {D:.4f} x {G} x {math.sqrt(T):.4f} = {bound:.6f} ({bound / T:.6f} a day)")
p2 = G * G / 2 * sum(eta(t) for t in range(1, T + 1)); L4 = ogd(C, lambda t: 4 * eta(t))[0]   # G guessed 4x too small
print(f"bound parts: D^2/(2 alpha_T) = {D * D / (2 * eta(T)):.6f}, (G^2/2) sum alpha_t = {p2:.6f} <= D G sqrt(T) = "
      f"{D * G * math.sqrt(T):.6f}; steps 4 times too long: regret {L4 - best:.6f}, slope part {4 * p2:.6f}")
assert p2 <= D * G * math.sqrt(T) < 4 * p2 and L4 - best > L - best
print(f"the projection clipped a sleeve to 0 on {clip} of {T} days; the one-step inequality held on all {T}")
assert 0 < L - best <= bound
ts = list(range(25, T + 1, 25)); reg = []
for t in ts: reg.append(ogd(C[:t], eta)[0] - best_fixed(C[:t])[1])
print("chart, days", ts); print("chart, regret", " ".join(f"{r:.4f}" for r in reg))
print("chart, bound", " ".join(f"{1.5 * D * G * math.sqrt(t):.4f}" for t in ts))
Ls = ogd(C, lambda t: 1 / (mu * t))[0]; bsc = G * G / (2 * mu) * (1 + math.log(T))
print(f"OGD, step 1/(mu t): regret {Ls - best:.6f}; bound G^2/(2 mu) (1 + ln T) = {bsc:.6f}; "
      f"with mu = 0.002 it would be {G * G / (2 * 0.002) * (1 + math.log(T)):.6f}")
assert 0 < Ls - best <= bsc < bound
e = math.sqrt(2 * math.log(n) / T) / G; w, Le, gi = [1 / n] * n, 0.0, 0.0   # exponentiated gradient
for c in C:               # gi: sum over days of the squared largest slope entry
    Le += f(c, w); g = grad(c, w); gi += max(map(abs, g)) ** 2
    w = [a * math.exp(-e * b) for a, b in zip(w, g)]; w = [a / sum(w) for a in w]
beg = G * math.sqrt(2 * T * math.log(n))
dd = sum(x * math.log(n * x) for x in u if x > 0) / e + e * gi / 2   # the proof's bound, D(u||w_1)/e + e gi/2
print(f"exponentiated gradient, rate {e:.4f}: regret {Le - best:.6f}; bound G sqrt(2 T ln n) = {beg:.6f}; "
      f"on this year's slopes {dd:.6f}")
assert 0 < Le - best <= dd <= beg and abs(sum(w) - 1) < 1e-12
print(f"2,000 assets, each gradient entry within {G}: OGD bound {1.5 * D * G * math.sqrt(2000) * math.sqrt(T):.2f}, "
      f"exponentiated gradient bound {G * math.sqrt(2 * T * math.log(2000)):.2f}")

# floor: two sleeves, gradient +-(a, -a) on fair coin days; every method expects loss 0
a = G / math.sqrt(2); P = {0: 1.0}; fl = []
for t in range(1, T + 1):
    Q = {}
    for s, p in P.items(): Q[s + 1] = Q.get(s + 1, 0) + p / 2; Q[s - 1] = Q.get(s - 1, 0) + p / 2
    P = Q
    if t % 25 == 0: fl.append(a * sum(abs(s) * p for s, p in P.items()))
p, E = 0.5**T, 0.0
for k in range(T + 1): E += p * abs(2 * k - T); p = p * (T - k) / (k + 1)
print("chart, coin-day floor", " ".join(f"{x:.4f}" for x in fl))
print(f"coin days: a = {a:.6f}, E|S_T| = {E:.4f}, floor a E|S_T| = {a * E:.4f}; G sqrt(T/pi) = "
      f"{G * math.sqrt(T / math.pi):.4f}; bound / floor = {bound / (a * E):.3f}")
assert abs(fl[-1] - a * E) < 1e-12 and a * E < bound

# what breaks: follow the leader, and a step that never shrinks, on alternating days
alt = [[-a / 2, a / 2]] + [[a, -a] if t % 2 else [-a, a] for t in range(1, T)]
def lin(step, leader=False):
    w, L, S2 = [0.5, 0.5], 0.0, [0.0, 0.0]
    for t, c in enumerate(alt, 1):
        if leader: w = [0.5, 0.5] if S2[0] == S2[1] else ([1.0, 0.0] if S2[0] > S2[1] else [0.0, 1.0])
        L -= dot(c, w); S2 = [S2[0] + c[0], S2[1] + c[1]]
        w = proj([x + step(t) * y for x, y in zip(w, c)])
    return L + max(S2)
ftl, fix, og = lin(eta, True), lin(lambda t: D / G), lin(eta)
print(f"alternating days: follow the leader regret {ftl:.4f}, fixed step {D / G:.4f} regret {fix:.4f}, OGD regret {og:.4f}")
assert ftl > 8 and fix > 8 and og <= bound

# online-to-batch: 200 independent years; F(w) = E f(w) has the true best mix u*
mc = [x - sum(m) / n for x in m]; us = proj([z[i] + mc[i] / mu for i in range(n)])
F = lambda w: -dot(mc, w) + mu / 2 * sum((a - b)**2 for a, b in zip(w, z))
ex, rg, last, fit, seed = [], [], [], [], 7
for r in range(200):
    seed, s0 = splitmix(seed); Cr = year(s0); Lr, Wr = ogd(Cr, eta)
    wb = [sum(w[i] for w in Wr[:T]) / T for i in range(n)]
    ex.append(F(wb) - F(us)); rg.append((Lr - sum(f(c, us) for c in Cr)) / T)
    last.append(F(Wr[-1]) - F(us)); fit.append(F(best_fixed(Cr)[0]) - F(us))
mean = lambda x: sum(x) / len(x); se = math.sqrt((mean([x * x for x in rg]) - mean(rg)**2) / 200)
print(f"true best mix u* = ({us[0]:.4f}, {us[1]:.4f}, {us[2]:.4f}); over 200 years, excess daily loss of")
print(f"  OGD's average mix {mean(ex):.7f}, its last mix {mean(last):.7f}, refit on the year {mean(fit):.7f}")
print(f"  OGD's regret against u* per day {mean(rg):.7f} (standard error {se:.7f}); bound per day {bound / T:.6f}")
assert mean(ex) <= mean(rg) + 4 * se and mean(ex) < mean(last)
print("ALL CHECKS PASS")
