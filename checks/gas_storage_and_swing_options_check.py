# Gas storage and swing contracts -- the check behind the card.  Standard library only.  The 25-05
# Henry Hub strip (USD/MMBtu, Apr..Mar).  A store holds 100 units (1 unit = 10,000 MMBtu), moves at most
# 25 a month, starts and ends empty.  The price reverts (speed 3 a year, vol 60%) on a tree fitted to the strip.
from math import exp, log, sqrt, ceil, pi
from itertools import product

MON = ["Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "Jan", "Feb", "Mar"]
F = [2.70, 2.55, 2.50, 2.50, 2.55, 2.62, 2.75, 3.05, 3.35, 3.50, 3.40, 3.05]
r, c, CAP, LIM, KAP, SIG, SUB, K, NR = 0.05, 0.02, 100, 25, 3.0, 0.60, 8, 3.00, 4
D = [exp(-r * m / 12) for m in range(12)]                # discount to 1 April
ACT, g = (-25, 0, 25), exp(-r / 12)                     # withdraw, hold, inject; one month's discount
def cash(a, p): return -a * p - c * abs(a)              # buy a units (sell if a < 0), pay the cost

def intrinsic(curve, m0, I0, lim=LIM):                  # road 1: backwards over inventory
    V = {I: 0.0 if I == 0 else -1e18 for I in range(0, CAP + 1, 25)}
    for m in range(11, m0 - 1, -1):
        W = {I: max((cash(a, curve[m]) * D[m] / D[m0] + V[I + a], a)
                    for a in range(-lim, lim + 1, 25) if 0 <= I + a <= CAP) for I in V}
        V = {I: W[I][0] for I in W}
    return W[I0]
iv, best = intrinsic(F, 0, 0)[0], (-1e18, None)         # road 2: try all 3^12 schedules
for s in product(ACT, repeat=12):
    lev = [sum(s[:m + 1]) for m in range(12)]
    if min(lev) >= 0 and max(lev) <= CAP and lev[-1] == 0:
        best = max(best, (sum(cash(a, F[m]) * D[m] for m, a in enumerate(s)), s))
plan = best[1]

def tree(kap, sig):     # SUB small steps a month, exact step mean and variance, edges turn inward
    dt = 1 / 12 / SUB; M = exp(-kap * dt) - 1
    dy = sqrt(3 * sig * sig * (1 - exp(-2 * kap * dt)) / (2 * kap)); JM = ceil(0.184 / -M); N = 2 * JM + 1
    P = [[0.0] * N for _ in range(N)]
    for j in range(-JM, JM + 1):
        q, m = j * j * M * M, j * M
        br = ([(j, 7/6 + (q + 3*m)/2), (j-1, -1/3 - q - 2*m), (j-2, 1/6 + (q + m)/2)] if j == JM else
              [(j+2, 1/6 + (q - m)/2), (j+1, -1/3 - q + 2*m), (j, 7/6 + (q - 3*m)/2)] if j == -JM else
              [(j+1, 1/6 + (q + m)/2), (j, 2/3 - q), (j-1, 1/6 + (q - m)/2)])
        for k, p in br: P[j + JM][k + JM] += p
    T = P
    for _ in range(SUB - 1): T = [[sum(T[i][k] * P[k][j] for k in range(N)) for j in range(N)] for i in range(N)]
    Q = [[1.0 if i == JM else 0.0 for i in range(N)]]   # chance of each node, month by month
    for m in range(11): Q.append([sum(Q[-1][i] * T[i][k] for i in range(N)) for k in range(N)])
    S = [[exp((i - JM) * dy) for i in range(N)] for m in range(12)]
    for m in range(12):                                 # shift each month onto the strip
        sh = F[m] / sum(Q[m][i] * S[m][i] for i in range(N)); S[m] = [s * sh for s in S[m]]
    return T, Q, S, JM, dy

def dp(T, S, states, moves, end):                       # backwards over (month, node, state)
    N = len(T); V = {s: [end(s)] * N for s in states}; pol = {}
    for m in range(11, -1, -1):
        C = {s: [g * sum(T[i][k] * V[s][k] for k in range(N)) if m < 11 else end(s) for i in range(N)] for s in states}
        for s in states:
            for i in range(N):
                V[s][i], pol[m, i, s] = max((cf + C[s2][i], s2) for s2, cf in moves(s, S[m][i]))
    return V, pol
st = lambda I, p: [(I + a, cash(a, p)) for a in ACT if 0 <= I + a <= CAP]
sw = lambda n, p: [(n, 0.0)] + ([(n - 1, max(p - K, 0.0))] if n else [])
emp = lambda I: 0.0 if I == 0 else -1e18                # the store must end empty
def storage(kap, sig): t = tree(kap, sig); return dp(t[0], t[2], range(0, CAP + 1, 25), st, emp)[0][0][t[3]]
T, Q, S, JM, dy = tree(KAP, SIG); N = len(T)
stor, spol = dp(T, S, range(0, CAP + 1, 25), st, emp)
swv, wpol = dp(T, S, range(13), sw, lambda n: 0.0)

G = [[None] * 12 for _ in range(12)]                    # G[m][t][i]: forward for t at node i, month m
for t in range(12):
    v = S[t][:]
    for m in range(t, -1, -1): G[m][t] = v; v = [sum(T[i][k] * v[k] for k in range(N)) for i in range(N)]
dist, ri, rp = {(JM, 0): 1.0}, 0.0, {}                  # rolling intrinsic: re-plan, do month one
for m in range(12):
    nd = {}
    for (i, I), p in dist.items():
        a = rp[m, i, I] = intrinsic([0.0] * m + [G[m][t][i] for t in range(m, 12)], m, I)[1]
        ri += p * D[m] * cash(a, S[m][i])
        for k in range(N if m < 11 else 0): nd[k, I + a] = nd.get((k, I + a), 0.0) + p * T[i][k]
    dist = nd

def ncdf(x):                                            # bell-curve area, Simpson's rule
    h = x / 2000; s = 1 + exp(-x * x / 2)
    for k in range(1, 2000): s += (4 if k % 2 else 2) * exp(-(k * h) * (k * h) / 2)
    return 0.5 + s * h / 3 / sqrt(2 * pi)
eur, b76 = [], []
for m in range(12):
    eur.append(D[m] * sum(Q[m][i] * max(S[m][i] - K, 0) for i in range(N)))
    v = SIG * SIG * (1 - exp(-2 * KAP * m / 12)) / (2 * KAP); s = sqrt(v)
    d = (log(F[m] / K) + v / 2) / s if s else 0.0
    b76.append(D[m] * (F[m] * ncdf(d) - K * ncdf(d - s)) if s else D[m] * max(F[m] - K, 0))

NP, acc, state, top4 = 20000, [0.0] * 8, 20261123, sum(sorted(eur)[-NR:])  # road 3: walk the tree
for _ in range(NP):
    i, I, n, J, w1, w2, w3 = JM, 0, NR, 0, 0.0, 0.0, 0.0
    for m in range(12):
        I2, n2, a = spol[m, i, I], wpol[m, i, n], rp[m, i, J]; w1 += D[m] * cash(I2 - I, S[m][i])
        w2 += D[m] * max(S[m][i] - K, 0) * (n - n2); w3 += D[m] * cash(a, S[m][i]); I, n, J = I2, n2, J + a
        state = (state * 6364136223846793005 + 1442695040888963407) % 2 ** 64; u, k = (state >> 11) / 2 ** 53, 0
        while k < N - 1 and u > T[i][k]: u -= T[i][k]; k += 1
        i = k
    acc = [x + y for x, y in zip(acc, (w1, w1 * w1, w2, w2 * w2, w3, w3 * w3, w1 - w3, (w1 - w3) * (w1 - w3)))]; assert I == 0 == J, "store ends empty"
mc1, mc2, mc3, mcd = (acc[k] / NP for k in (0, 2, 4, 6))   # storage, swing, rolling, storage minus rolling
se1, se2, se3, sed = (sqrt((acc[k + 1] / NP - (acc[k] / NP) ** 2) / NP) for k in (0, 2, 4, 6))

print(f"store {CAP} units of 10,000 MMBtu, {LIM} a month, cost {c:.2f}, r {r:.2f}, kappa {KAP:.1f}, sigma {SIG:.2f}")
print(f"tree: {SUB} steps a month, {N} nodes, log-price step {dy:.4f}; swing strike {K:.2f}, {NR} rights")
print("month  forward  plan  level  discount  cash today")
for m in range(12):
    print(f"{MON[m]:<6} {F[m]:7.2f} {plan[m]:+5d} {sum(plan[:m + 1]):6d} {D[m]:9.6f} {cash(plan[m], F[m]) * D[m]:11.4f}")
print(f"intrinsic, backwards over inventory  {iv:9.4f}")
print(f"intrinsic, all 3^12 schedules        {best[0]:9.4f}")
print(f"rolling intrinsic, exact on the tree {ri:9.4f}\n  simulated, 20,000 paths            {mc3:9.4f}  s.e. {se3:.4f}")
print(f"storage on the tree, backwards       {stor[0][JM]:9.4f}")
print(f"  simulated, 20,000 paths            {mc1:9.4f}  s.e. {se1:.4f}")
print(f"  full minus rolling, exact {stor[0][JM] - ri:.4f}, same paths {mcd:.4f}  s.e. {sed:.4f}")
print(f"extrinsic: rolling, full tree        {ri - iv:9.4f} {stor[0][JM] - iv:9.4f}")
gap = max(abs(G[0][t][JM] - F[t]) for t in range(12))     # each month's prices rolled back to 1 April
print(f"tree rolled back = strip, every month{'yes' if gap < 1e-12 else 'no':>9}")
print("month  European tree  Black-76")
for m in range(12): print(f"{MON[m]:<6} {eur[m]:13.4f} {b76[m]:9.4f}")
print(f"strip of 12 Europeans, tree, B76     {sum(eur):9.4f} {sum(b76):9.4f}")
print(f"swing, 12 rights on the tree         {swv[12][JM]:9.4f}")
print(f"swing, 1 right = one American        {swv[1][JM]:9.4f}")
print(f"swing, 4 rights                      {swv[NR][JM]:9.4f}")
print(f"  simulated, 20,000 paths            {mc2:9.4f}  s.e. {se2:.4f}")
print(f"4 American options                   {NR * swv[1][JM]:9.4f}")
print(f"best 4 Europeans, fixed months       {top4:9.4f}")
print(f"dollars: intrinsic {iv * 1e4:.0f}, tree {stor[0][JM] * 1e4:.0f}, swing {swv[NR][JM] * 1e4:.0f}, 4 Americans {NR * swv[1][JM] * 1e4:.0f}")
print("lowest price that uses a right, by rights left 1 2 3 4")
for m in (8, 9, 10, 11):
    print(f"  {MON[m]}  " + " ".join(f"{min([S[m][i] for i in range(N) if wpol[m, i, n] < n] or [0.0]):5.2f}" for n in (1, 2, 3, 4)))
print(f"wrong: no 25-a-month limit           {intrinsic(F, 0, 0, 100)[0]:9.4f}")
print(f"try: 50 a month, intrinsic           {intrinsic(F, 0, 0, 50)[0]:9.4f}")
print(f"try: sigma 30%, storage              {storage(KAP, 0.30):9.4f}")
print(f"try: kappa 1, storage                {storage(1.0, SIG):9.4f}")
assert abs(iv - best[0]) < 1e-9 and plan == (0, 25, 25, 25, 25, 0, 0, -25, -25, -25, -25, 0), "two intrinsic roads"
assert abs(iv - sum(D[m] * 25 * ((F[m] - c) if m > 6 else -(F[m] + c)) for m in (1, 2, 3, 4, 7, 8, 9, 10))) < 1e-9, "intrinsic = hand sum"
assert gap < 1e-12, "tree reprices the strip"
assert max(abs(e - b) for e, b in zip(eur, b76)) < 0.003, "tree Europeans match Black-76"
assert abs(swv[12][JM] - sum(eur)) < 1e-9, "12 rights = the strip of Europeans"
assert iv < ri < stor[0][JM], "intrinsic < rolling intrinsic < full tree"
assert top4 < swv[NR][JM] < NR * swv[1][JM], "swing sits between fixed months and 4 Americans"
assert abs(mc1 - stor[0][JM]) < 3 * se1 and abs(mc2 - swv[NR][JM]) < 3 * se2, "simulation agrees"
assert abs(mc3 - ri) < 3 * se3 and abs(mcd - (stor[0][JM] - ri)) < 3 * sed, "rolling intrinsic agrees with its paths"
print("ALL CHECKS PASS")
