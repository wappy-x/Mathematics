# Convergence to equilibrium -- the check behind the card.  Standard library only.
# Weather in states 0 sunny, 1 cloudy, 2 rainy; one step is one day.
# Road 1: exact matrix powers in whole numbers (10^n P^n).  Road 2: the eigenvalue
# formula P^n = Pi + (1/2)^n A2 + (3/10)^n A3.  Road 3: a seeded simulation of the
# coupling used in the proof, and of a month of weather.
from math import sqrt, log, ceil

P10 = [[8, 1, 1], [5, 4, 1], [1, 3, 6]]      # P in tenths
PI5 = [3, 1, 1]                              # stationary law in fifths: 0.6, 0.2, 0.2

def mat_mul(a, b):
    return [[sum(a[i][k] * b[k][j] for k in range(3)) for j in range(3)] for i in range(3)]

def powers(p, top):                          # exact whole-number powers of p, n = 0..top
    out, a = [], [[int(i == j) for j in range(3)] for i in range(3)]
    for n in range(top + 1):
        out.append(a); a = mat_mul(a, p)
    return out

def tv(u, v):                                # total variation distance between two laws
    return 0.5 * sum(abs(x - y) for x, y in zip(u, v))

def d_exact(a, n, pin, pid):                  # worst-start distance to pi = pin / pid, one exact division
    num = max(sum(abs(pid * a[i][j] - pin[j] * 10 ** n) for j in range(3)) for i in range(3))
    return num / (2 * pid * 10 ** n)

def sci(x): return f"{x:.3e}"

def pw(x, n):                                # x to the n by repeated multiplication
    out = 1.0
    for _ in range(n): out *= x
    return out

# ---- road 1: exact powers ----
A = powers(P10, 31)
assert all(sum(PI5[i] * P10[i][j] for i in range(3)) == 10 * PI5[j] for j in range(3))  # pi P = pi
d = [d_exact(A[n], n, PI5, 5) for n in range(32)]
Pn = lambda n: [[A[n][i][j] / 10 ** n for j in range(3)] for i in range(3)]

# ---- road 2: eigenvalues from trace and determinant, then Sylvester's formula ----
P = [[x / 10 for x in row] for row in P10]
tr = P[0][0] + P[1][1] + P[2][2]
det = (P[0][0] * (P[1][1] * P[2][2] - P[1][2] * P[2][1]) - P[0][1] * (P[1][0] * P[2][2] - P[1][2] * P[2][0])
       + P[0][2] * (P[1][0] * P[2][1] - P[1][1] * P[2][0]))
s, pr = tr - 1.0, det                        # the other two eigenvalues: sum s, product pr
l2 = (s + sqrt(s * s - 4 * pr)) / 2
l3 = (s - sqrt(s * s - 4 * pr)) / 2
I = [[float(i == j) for j in range(3)] for i in range(3)]
def comb(a, b, x, y): return [[x * a[i][j] + y * b[i][j] for j in range(3)] for i in range(3)]
def proj(la, lb, lc):                        # (P - lb I)(P - lc I) / ((la - lb)(la - lc))
    m = mat_mul(comb(P, I, 1, -lb), comb(P, I, 1, -lc))
    return [[x / ((la - lb) * (la - lc)) for x in row] for row in m]
PI, A2, A3 = proj(1.0, l2, l3), proj(l2, 1.0, l3), proj(l3, 1.0, l2)
spec = lambda n: [[PI[i][j] + pw(l2, n) * A2[i][j] + pw(l3, n) * A3[i][j] for j in range(3)] for i in range(3)]
worst = max(abs(spec(n)[i][j] - Pn(n)[i][j]) for n in range(31) for i in range(3) for j in range(3))
assert worst < 1e-12                          # the two roads agree on every entry, 31 days
eps = sum(min(P10[i][j] for i in range(3)) for j in range(3)) / 10   # Doeblin's common part
print(f"eigenvalues from trace {tr:.1f} and determinant {det:.2f}: other two sum {s:.1f}, product {pr:.2f}, root {sqrt(s * s - 4 * pr):.1f}: 1, {l2:.6f}, {l3:.6f}")
print(f"stationary law: sunny {PI[0][0]:.6f} cloudy {PI[0][1]:.6f} rainy {PI[0][2]:.6f}")
print("weather P, rows sunny cloudy rainy: " + " | ".join(" ".join(f"{x / 10:.1f}" for x in row) for row in P10))
print(f"common part of the rows eps = {eps:.1f}; guaranteed factor 1 - eps = {1 - eps:.1f}")
print(f"roads 1 and 2 agree on all 9 entries, days 0..30, to 1e-12: {'yes' if worst < 1e-12 else 'no'}; d(31)/d(30) = {d[31] / d[30]:.6f}; d(30)/0.5^30 = {d[30] / pw(0.5, 30):.4f}")

# ---- the forecasts: chance of sun on day n from each start ----
print("day  sun|sunny  sun|cloudy  sun|rainy   d(n) exact  bound 0.7^n  0.5^n")
for n in list(range(11)) + [14, 30]:
    q = Pn(n)
    print(f"{n:3d}  {q[0][0]:9.6f}  {q[1][0]:10.6f}  {q[2][0]:9.6f}   {sci(d[n])}  {sci(pw(0.7, n))}  {sci(pw(0.5, n))}")
assert all(d[n] <= pw(0.7, n) + 1e-15 for n in range(32))          # the guarantee holds every day
assert abs(d[31] / d[30] - l2) < 1e-6                             # the true rate is lambda2
print(f"by hand, rainy start: sun on day n = 0.6 + a 0.5^n + b 0.3^n, a = {A2[2][0]:.4f}, b = {A3[2][0]:.4f}")
assert abs(A2[2][0] + 1.6) < 1e-9 and abs(A3[2][0] - 1) < 1e-9   # the by-hand weights a, b
for n in (1, 2, 3, 7):
    print(f"  day {n}: a 0.5^n = {A2[2][0] * pw(l2, n):.7f}  b 0.3^n = {A3[2][0] * pw(l3, n):.7f}  sun = {PI[2][0] + A2[2][0] * pw(l2, n) + A3[2][0] * pw(l3, n):.7f}")
first = lambda f, lim: next(n for n in range(200) if f(n) <= lim)
for lim in (0.25, 0.01):
    print(f"first day d(n) <= {lim}: exact {first(lambda n: d[n], lim)}, from bound {first(lambda n: pw(1 - eps, n), lim)}")
    assert first(lambda n: pw(1 - eps, n), lim) == ceil(log(lim) / log(1 - eps))   # the bound's day, two ways
assert first(lambda n: d[n], 0.01) == 8                                            # the exact day, from P^n
print("chart, sun|sunny " + " ".join(f"{Pn(n)[0][0]:.2f}" for n in range(11)))
print("chart, sun|cloudy " + " ".join(f"{Pn(n)[1][0]:.2f}" for n in range(11)))
print("chart, sun|rainy " + " ".join(f"{Pn(n)[2][0]:.2f}" for n in range(11)))

# ---- road 3: simulation, SplitMix64 seed 20260929 ----
state = 20260929
def rand():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
def pick(w, u):                               # state drawn from weights w, by one uniform u
    t, acc = u * sum(w), 0
    for j in range(3):
        acc += w[j]
        if t < acc: return j
    return 2
RES = [[P10[i][j] - 1 for j in range(3)] for i in range(3)]      # what is left after the common part
N, DAYS = 20000, 8
alive = [0] * (DAYS + 1)                     # pairs not yet met after n days
for _ in range(N):
    x, y = 0, 2                              # one copy starts sunny, the other rainy
    for n in range(1, DAYS + 1):
        if x == y:
            x = y = pick(P10[x], rand())
        elif rand() < eps:
            x = y = pick([1, 1, 1], rand())  # the shared draw: both land together
        else:
            x, y = pick(RES[x], rand()), pick(RES[y], rand())
        alive[n] += x != y
print(f"coupling, {N} pairs from sunny and rainy: n, P(not met) +- se, bound 0.7^n, exact P(not met), exact TV")
unmet = [[0.0, 0.0, 1.0], [0.0] * 3, [0.0] * 3]  # exact chance on each unmet pair (x, y); day 0 sunny, rainy
for n in range(1, 7):
    p = alive[n] / N
    se = sqrt(p * (1 - p) / N)
    gap = tv(Pn(n)[0], Pn(n)[2])
    unmet = [[0.0 if a == b else sum(unmet[x][y] * (1 - eps) * RES[x][a] * RES[y][b] / (sum(RES[x]) * sum(RES[y])) for x in range(3) for y in range(3)) for b in range(3)] for a in range(3)]
    print(f"  {n}  {p:.4f} +- {se:.4f}  {pw(0.7, n):.4f}  {sum(map(sum, unmet)):.4f}  {gap:.4f}")
    assert gap <= p + 3 * se and p <= pw(0.7, n) + 3 * se           # coupling inequality, Doeblin bound
    assert abs(sum(map(sum, unmet)) - gap) < 1e-12                  # for this pair the coupling is exact
sunny = 0
for _ in range(N):
    x = 2
    for _ in range(30): x = pick(P10[x], rand())
    sunny += x == 0
p = sunny / N
se = sqrt(p * (1 - p) / N)
print(f"month from rainy, {N} runs: sunny on day 30 {p:.4f} +- {se:.4f}, exact {Pn(30)[2][0]:.6f}")
assert abs(p - 0.6) < 4 * se

# ---- what breaks ----
CYC = [[0, 10, 0], [0, 0, 10], [10, 0, 0]]   # sunny -> cloudy -> rainy -> sunny, period 3
C = powers(CYC, 30)
print(f"breaks, cycle: d(29) {d_exact(C[29], 29, [1, 1, 1], 3):.6f}  d(30) {d_exact(C[30], 30, [1, 1, 1], 3):.6f}")
assert all(abs(d_exact(C[n], n, [1, 1, 1], 3) - 2 / 3) < 1e-12 for n in range(31))   # never settles
RED = [[8, 2, 0], [5, 5, 0], [0, 0, 10]]     # rainy never leaves, the others never reach it
R = powers(RED, 30)
print(f"breaks, two climates: TV(start sunny, start rainy) day 30 {tv(R[30][0], R[30][2]) / 10 ** 30:.6f}")
assert all(abs(tv(R[n][0], R[n][2]) / 10 ** n - 1) < 1e-12 for n in range(31))   # the starts never meet
