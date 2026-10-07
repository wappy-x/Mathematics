# Hidden Markov models -- the check behind the card.  Standard library only.
# Hidden: the weather, a Markov chain on sunny, cloudy, rainy.  Seen: whether
# the first colleague through the office door carries an umbrella.  The week
# seen is umbrella, umbrella, none, none, umbrella.  Three roads: the forward
# and Viterbi recursions in floats; all 243 weather weeks enumerated in exact
# integers (every probability is a whole number of tenths); and 300000 weeks
# simulated with SplitMix64, seed 2026.  Then 2000 simulated days, where plain
# products underflow and logarithms or rescaling take over.
from math import log, exp, sqrt, inf
P = [[7, 3, 0], [3, 3, 4], [2, 2, 6]]    # tenths: row = today, column = tomorrow
NU = [5, 3, 2]                           # tenths: Monday's weather, before any umbrella
B = [1, 4, 8]                            # tenths: chance of an umbrella in each weather
OBS, K, NAME = [1, 1, 0, 0, 1], 3, "SCR"
WEEKS, LONG = 300000, 2000
p, nu = [[x / 10 for x in r] for r in P], [x / 10 for x in NU]
def b(i, y): return (B[i] if y else 10 - B[i]) / 10
def word(path): return "".join(NAME[i] for i in path)
def lg(x): return log(x) if x > 0 else -inf

# ---- road 1: the recursions ----
def forward(obs):                        # alpha_n(i) = P(y_1..y_n, X_n = i)
    a = [[nu[i] * b(i, obs[0]) for i in range(K)]]
    for y in obs[1:]:
        a.append([sum(a[-1][j] * p[j][i] for j in range(K)) * b(i, y) for i in range(K)])
    return a
def backward(obs):                       # beta_n(i) = P(y_n+1..y_N | X_n = i)
    be = [[1.0] * K]
    for y in reversed(obs[1:]):
        be.insert(0, [sum(p[i][j] * b(j, y) * be[0][j] for j in range(K)) for i in range(K)])
    return be
def viterbi(obs, f, op):                 # f, op = identity, times; or log, plus
    d, back = [[op(f(nu[i]), f(b(i, obs[0]))) for i in range(K)]], []
    for y in obs[1:]:
        row, arg = [], []
        for i in range(K):
            j = max(range(K), key=lambda j: (op(d[-1][j], f(p[j][i])), -j))
            arg.append(j); row.append(op(op(d[-1][j], f(p[j][i])), f(b(i, y))))
        d.append(row); back.append(arg)
    path = [max(range(K), key=lambda i: (d[-1][i], -i))]
    for arg in reversed(back): path.insert(0, arg[path[0]])
    return d, back, path
alpha, beta = forward(OBS), backward(OBS)
like = sum(alpha[-1])
post = [[alpha[n][i] * beta[n][i] / like for i in range(K)] for n in range(5)]
filt = [[x / sum(r) for x in r] for r in alpha]
delta, back, vpath = viterbi(OBS, lambda x: x, lambda u, v: u * v)
daywise = [max(range(K), key=lambda i: (post[n][i], -i)) for n in range(5)]

# ---- road 2: every weather week, exact integers in units of 10^-10 ----
def weight(path, obs):
    w = NU[path[0]] * (B[path[0]] if obs[0] else 10 - B[path[0]])
    for n in range(1, len(obs)):
        w *= P[path[n - 1]][path[n]] * (B[path[n]] if obs[n] else 10 - B[path[n]])
    return w
weeks = [[(c // 3 ** (4 - n)) % 3 for n in range(5)] for c in range(3 ** 5)]
ws = [weight(w, OBS) for w in weeks]
total = sum(ws)
best = max(range(len(weeks)), key=lambda c: (ws[c], -c))
epost = [[sum(ws[c] for c in range(len(weeks)) if weeks[c][n] == i) for i in range(K)] for n in range(5)]
vok = sum(abs(max(weight(w[:n + 1], OBS[:n + 1]) for w in weeks if w[n] == i) / 10 ** (2 * n + 2) - delta[n][i]) < 1e-15 for n in range(5) for i in range(K))

# ---- road 3: simulation ----
state = 2026
def draw():                              # SplitMix64, written out
    global state
    state = (state + 0x9E3779B97F4A7C15) & (2 ** 64 - 1)
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & (2 ** 64 - 1)
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & (2 ** 64 - 1)
    return z ^ (z >> 31)
def tenth(): return ((draw() >> 32) * 10) >> 32          # a whole number 0 to 9, each 1 in 10
def pick(row):
    u = tenth()
    for i in range(K):
        if u < row[i]: return i
        u -= row[i]
def run(days):
    x, xs, ys = pick(NU), [], []
    for n in range(days):
        if n: x = pick(P[x])
        xs.append(x); ys.append(1 if tenth() < B[x] else 0)
    return xs, ys
hits = vhits = rain_fri = 0
for _ in range(WEEKS):
    xs, ys = run(5)
    if ys == OBS:
        hits += 1; vhits += xs == vpath; rain_fri += xs[4] == 2
q, qv, qr = hits / WEEKS, vhits / hits, rain_fri / hits
se = lambda f, m: sqrt(f * (1 - f) / m)

# ---- 2000 days: underflow, rescaling, logarithms ----
xs, ys = run(LONG)
plain = sum(forward(ys)[-1])
a, loglik, scaled = [nu[i] * b(i, ys[0]) for i in range(K)], 0.0, []
for n in range(LONG):
    if n: a = [sum(a[j] * p[j][i] for j in range(K)) * b(i, ys[n]) for i in range(K)]
    c = sum(a); loglik += log(c); a = [x / c for x in a]; scaled.append((a, c))
la = [lg(nu[i]) + lg(b(i, ys[0])) for i in range(K)]
for y in ys[1:]:
    la = [lg(b(i, y)) + max(la) + log(sum(exp(la[j] + lg(p[j][i]) - max(la)) for j in range(K))) for i in range(K)]
logroad = max(la) + log(sum(exp(v - max(la)) for v in la))
bh, dayw, sok = [1.0] * K, [0] * LONG, 0
for n in range(LONG - 1, -1, -1):
    g = [scaled[n][0][i] * bh[i] for i in range(K)]; sok += abs(sum(g) - 1) < 1e-9
    dayw[n] = max(range(K), key=lambda i: (g[i], -i))
    bh = [sum(p[i][j] * b(j, ys[n]) * bh[j] for j in range(K)) / scaled[n][1] for i in range(K)]
_, _, lpath = viterbi(ys, lg, lambda u, v: u + v)
acc_v = sum(lpath[n] == xs[n] for n in range(LONG)) / LONG
acc_d = sum(dayw[n] == xs[n] for n in range(LONG)) / LONG
f4, f10 = lambda v: f"{v:.4f}", lambda v: f"{v:.10f}"; m1 = sum(nu[i] * b(i, 1) for i in range(K))   # umbrella chance from Monday's mix
print(f"model: P = {P} tenths; start {NU} tenths; umbrella chance {B} tenths; week seen {OBS}")
print("road 1, forward alpha_n(S, C, R), then filter P(X_n = . | umbrellas to day n):")
for n in range(5): print(f"  day {n + 1}  {' '.join(f10(v) for v in alpha[n])}   {' '.join(f4(v) for v in filt[n])}")
print(f"road 1, chance of this umbrella week, sum of alpha_5: {f10(like)}")
print("road 1, Viterbi delta_n(S, C, R) and best previous weather:")
for n in range(5): print(f"  day {n + 1}  {' '.join(f10(v) for v in delta[n])}   {word(back[n - 1]) if n else '---'}")
print(f"road 1, Viterbi week {word(vpath)}, joint chance {f10(max(delta[4]))}, given the umbrellas {f4(max(delta[4]) / like)}")
print("road 1, smoothed P(X_n = S, C, R | whole week), forward times backward:")
for n in range(5): print(f"  day {n + 1}  {' '.join(f4(v) for v in post[n])}")
print(f"road 2, {len(weeks)} weeks, {sum(w > 0 for w in ws)} possible; exact chance {total} / 10^10")
print(f"road 2, most likely week {word(weeks[best])}, weight {ws[best]} / 10^10; runner-up weight {sorted(ws)[-2]}")
print(f"road 2, largest gap to road 1's smoothed table: {max(abs(epost[n][i] / total - post[n][i]) for n in range(5) for i in range(K)):.1e}; Viterbi table entries equal to the best enumerated path: {vok} of 15")
print(f"road 3, {WEEKS} weeks, seed 2026: {hits} showed this umbrella week")
print(f"  chance of the week   {q:.5f}  se {se(q, WEEKS):.5f}  (exact {like:.5f})")
print(f"  week was {word(vpath)}      {qv:.4f}  se {se(qv, hits):.4f}  (exact {max(delta[4]) / like:.4f})")
print(f"  Friday was rainy     {qr:.4f}  se {se(qr, hits):.4f}  (exact {post[4][2]:.4f})")
print(f"what breaks, best weather day by day: {word(daywise)}, exact weight {weight(daywise, OBS)}")
print(f"what breaks, days treated as independent: {m1:.2f}^3 x {1 - m1:.2f}^2 = {m1 ** 3 * (1 - m1) ** 2:.4f}, not {like:.4f}")
print(f"what breaks, {LONG} days, plain forward products: {plain}")
print(f"  log-likelihood, rescaled forward {loglik:.6f}; log-space forward {logroad:.6f}; rescaled forward x backward sums to 1 on {sok} of {LONG} days")
print(f"  about 10^{loglik / log(10):.1f}; paths 3^{LONG} = 10^{LONG * log(3) / log(10):.1f}; forward steps {LONG * K * K}")
print(f"  days right: Viterbi week {acc_v:.4f}  se {se(acc_v, LONG):.4f}; day by day {acc_d:.4f}  se {se(acc_d, LONG):.4f}")
print(f"figure, trellis x = 60 + 60(n-1), y = 50 (S), 110 (C), 170 (R); Viterbi {[(60 + 60 * n, 50 + 60 * s) for n, s in enumerate(vpath)]}; day by day {[(60 + 60 * n, 50 + 60 * s) for n, s in enumerate(daywise)]}")
print(f"figure, rain filtered {', '.join(f'{r[2]:.2f}' for r in filt)}; rain smoothed {', '.join(f'{r[2]:.2f}' for r in post)}")
assert abs(like - total / 10 ** 10) < 1e-15                     # forward against enumeration
assert vpath == weeks[best] and vok == 15                      # Viterbi table against enumeration
assert max(abs(epost[n][i] / total - post[n][i]) for n in range(5) for i in range(K)) < 1e-12
assert abs(q - total / 10 ** 10) < 4 * se(q, WEEKS) and abs(qv - ws[best] / total) < 4 * se(qv, hits)
assert weight(daywise, OBS) == 0 and plain == 0.0 and abs(loglik - logroad) < 1e-8 and sok == LONG
print("ALL CHECKS PASS")
