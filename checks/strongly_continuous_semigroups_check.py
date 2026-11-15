# Strongly continuous semigroups -- the check behind the card.  Standard library only.
# A help desk queue moves one step at a time: an arrival adds a caller, a finished call removes one.
# Space: rows of chances p over the counts 0, 1, 2, ...; size ||p|| = sum of |p_n| (the l1 norm).
# Roads: closed forms; uniformization (a Poisson clock driving a jump table); Taylor series with
# repeated squaring; the stationary row as an invariant.  Every computation is a truncation.
import math
LAM, MU = 4.0, 5.0                      # arrivals and completions per hour

def chain(N, servers):                  # up and down rates on states 0..N-1, arrivals stop at N-1
    up = [LAM if n < N - 1 else 0.0 for n in range(N)]
    dn = [MU * min(n, servers) for n in range(N)]
    return up, dn

def row_at(up, dn, start, t, f=None):   # row start of P(t) = sum_k Poisson(Ct; k) K^k, K = I + G/C
    N = len(up); C = max(u + d for u, d in zip(up, dn))
    v = [0.0] * N; v[start] = 1.0
    w = math.exp(-C * t); out = [w * x for x in v]; k = 0; mass = w
    while mass < 1 - 1e-15 or k < C * t:
        k += 1
        v = [v[m] * (1 - (up[m] + dn[m]) / C) + (v[m - 1] * up[m - 1] / C if m else 0.0)
             + (v[m + 1] * dn[m + 1] / C if m + 1 < N else 0.0) for m in range(N)]
        w *= C * t / k; mass += w; out = [o + w * x for o, x in zip(out, v)]
    return out

def matrix(up, dn, t): return [row_at(up, dn, n, t) for n in range(len(up))]
def mul(A, B): return [[sum(a * b for a, b in zip(r, c)) for c in zip(*B)] for r in A]
def gap(A, B): return max(abs(a - b) for r, s in zip(A, B) for a, b in zip(r, s))
def dist_from_start(P): return max(2 * (1 - P[n][n]) for n in range(len(P)))  # ||P(t) - I||

def taylor_exp(up, dn, t, s=12):        # second road: e^{tG} by Taylor series, then square s times
    N = len(up); G = [[0.0] * N for _ in range(N)]
    for n in range(N):
        G[n][n] = -(up[n] + dn[n])
        if n + 1 < N: G[n][n + 1] = up[n]
        if n: G[n][n - 1] = dn[n]
    A = [[g * t / 2 ** s for g in r] for r in G]; E = [[float(i == j) for j in range(N)] for i in range(N)]
    term = [r[:] for r in E]
    for k in range(1, 12):
        term = [[x / k for x in r] for r in mul(term, A)]; E = [[e + x for e, x in zip(r, q)] for r, q in zip(E, term)]
    for _ in range(s): E = mul(E, E)
    return E

# 1. The desk with no hold line (N = 2): closed form against uniformization.
def two_state(t, lam=LAM):
    e = math.exp(-(lam + MU) * t); s = lam + MU
    return [[MU / s + lam / s * e, lam / s * (1 - e)], [MU / s * (1 - e), lam / s + MU / s * e]]
up2, dn2 = chain(2, 1)
for t in (0.25, 0.5, 0.75):
    P = two_state(t); assert gap(P, matrix(up2, dn2, t)) < 1e-12
    print(f"no hold line, P({t}) = [[{P[0][0]:.6f}, {P[0][1]:.6f}], [{P[1][0]:.6f}, {P[1][1]:.6f}]]")
PP = mul(two_state(0.25), two_state(0.5))
print(f"no hold line, P(0.25) P(0.5) row 0 = {PP[0][0]:.6f}, {PP[0][1]:.6f}; P(0.75) row 0 = {two_state(0.75)[0][0]:.6f}")
h1, h2 = two_state(0.25)[0][0] * two_state(0.5)[0][0], two_state(0.25)[0][1] * two_state(0.5)[1][0]
print(f"by hand, 5/9 = {5 / 9:.6f}, e^-2.25 = {math.exp(-2.25):.6f}, e^-4.5 = {math.exp(-4.5):.6f}, e^-6.75 = {math.exp(-6.75):.6f}, products {h1:.6f} + {h2:.6f}")
assert gap(PP, two_state(0.75)) < 1e-12 and gap(two_state(0.0), [[1, 0], [0, 1]]) < 1e-15

# 2. One agent with a hold line (M/M/1), cut at N = 40 states: the semigroup laws.
up, dn = chain(40, 1)
A, B, C = matrix(up, dn, 0.25), matrix(up, dn, 0.5), matrix(up, dn, 0.75)
law = gap(mul(A, B), C); road = gap(C, taylor_exp(up, dn, 0.75))
pi = [0.8 ** n for n in range(40)]; pi = [x / sum(pi) for x in pi]
inv = sum(abs(sum(pi[m] * C[m][n] for m in range(40)) - pi[n]) for n in range(40))
yes = lambda ok: "yes" if ok else "no"
print(f"M/M/1, N = 40, agree to 1e-12: P(0.25)P(0.5) with P(0.75) {yes(law < 1e-12)}; uniformization with Taylor {yes(road < 1e-12)}")
print(f"M/M/1, N = 40, P(0.75): rows sum to 1 {yes(max(abs(sum(r) - 1) for r in C) < 1e-12)}; no negative entry {yes(min(map(min, C)) > -1e-15)}; "
      f"stationary row unmoved {yes(inv < 1e-12)}; P(0) = I {yes(gap(matrix(up, dn, 0.0), taylor_exp(up, dn, 0.0)) < 1e-15)}")
assert law < 1e-12 and road < 1e-12 and inv < 1e-12 and min(map(min, C)) > -1e-15
print("norm continuity, t (h), ||P(t) - I|| on N = 10, on N = 40, bound 2(1 - e^{-9t})")
for t in (0.1, 0.01, 0.001):
    d10, d40 = dist_from_start(matrix(*chain(10, 1), t)), dist_from_start(matrix(up, dn, t)); bd = -2 * math.expm1(-9 * t)
    print(f"norm continuity, {t}, {d10:.4f}, {d40:.4f}, {bd:.4f}"); assert d40 <= bd and abs(d40 - d10) < 1e-3

# 3. An agent for every caller (M/M/infinity): exact P_nn(t) from survivors (binomial) plus newcomers (Poisson).
LF = [0.0]
for k in range(1, 10001): LF.append(LF[-1] + math.log(k))
def stay(n, t):                         # chance to be at n again after t hours, starting from n
    p, q = math.exp(-MU * t), -math.expm1(-MU * t); m = LAM / MU * q
    return sum(math.exp(LF[n] - LF[k] - LF[n - k] + (n - k) * math.log(p) + k * math.log(q)
                        - m + k * math.log(m) - LF[k]) for k in range(min(n, 200) + 1))
def parity(n, t):                       # (P(t)f)(n) for f(n) = (-1)^n, in closed form
    return (-1) ** n * (2 * math.exp(-MU * t) - 1) ** n * math.exp(-2 * LAM / MU * -math.expm1(-MU * t))
r = row_at(*chain(80, 80), 10, 0.05); pf = sum(x * (-1) ** m for m, x in enumerate(r))
print(f"M/M/inf, start 10, t = 0.05: P_10,10 exact {stay(10, 0.05):.6f}, uniformization on 80 states {r[10]:.6f}; "
      f"(P f)(10) exact {parity(10, 0.05):.6f}, uniformization {pf:.6f}")
assert abs(stay(10, 0.05) - r[10]) < 1e-9 and abs(parity(10, 0.05) - pf) < 1e-9
assert abs(sum(r) - 1) < 1e-12 and abs(sum(abs(x - (m == 10)) for m, x in enumerate(r)) - 2 * (1 - r[10])) < 1e-12
print("strong continuity, t (h), distance 2(1 - P_nn(t)) from start n = 1, 10, 100, 1000")
for t in (0.1, 0.01, 0.001):
    d = [2 * (1 - stay(n, t)) for n in (1, 10, 100, 1000)]
    print("strong continuity, " + f"{t}, " + ", ".join(f"{x:.4f}" for x in d))
    assert all(x <= -2 * math.expm1(-(LAM + MU * n) * t) for x, n in zip(d, (1, 10, 100, 1000)))
assert 2 * (1 - stay(1000, 0.001)) > 1.98 and 2 * (1 - stay(1, 0.001)) < 0.02
print("chart, log10 t, " + ", ".join(f"{-e / 2:.1f}" for e in range(2, 13)))
for n in (1, 100, 10000):
    print(f"chart, start {n}, " + ", ".join(f"{2 * (1 - stay(n, 10 ** (-e / 2))):.3f}" for e in range(2, 13)))
print("generator size ||G_N|| for M/M/inf cut at N = 10, 100, 1000: " + ", ".join(f"{2 * max(map(sum, zip(*chain(N, N)))):.0f}" for N in (10, 100, 1000)) + f"; M/M/1: {2 * (LAM + MU):.0f}")

# 4. What breaks.
q10 = max(u + d for u, d in zip(*chain(10, 10))); cut = -2 * math.expm1(-q10 * 0.001)
print(f"breaks, trust the N = 10 cut (top leaving rate {q10:.0f} an hour): distance at most {cut:.4f} at t = 0.001 for every start; from 1000 callers it is {2 * (1 - stay(1000, 0.001)):.4f}")
assert cut < 0.1 < 2 * (1 - stay(1000, 0.001))
print("breaks, sup norm on f(n) = (-1)^n at t = 0.001, gap |P(t)f(n) - f(n)| for n = 1, 10, 100, 1000: "
      + ", ".join(f"{abs(parity(n, 0.001) - (-1) ** n):.4f}" for n in (1, 10, 100, 1000)))
assert abs(parity(1000, 0.001) - 1) > 0.99
a, b = two_state(0.5)[0][0], two_state(0.5, 8.0)[0][0]
print(f"breaks, rush hour (arrivals 4 then 8 an hour): idle to idle over the first half hour {a:.6f}, over the second {b:.6f}")
assert abs(a - b) > 0.1
print("ALL CHECKS PASS")
