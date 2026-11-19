# The large sieve -- the check behind the card.  Standard library only.  The set A: whole numbers
# 1..10,000 that are a square mod every odd prime up to Q = 100.  Road one: count A exactly by
# Euler's criterion and compare with the perfect squares.  Road two: the large sieve bound
# (N - 1 + Q^2)/L.  Road three: the exponential sums S(a/q) themselves, between both sides of the
# inequality.  Road four: the worst-case ratio for a small case, by Jacobi rotations.
import math
N, Q = 10000, 100
def sieve(n):
    s = [True] * (n + 1); s[0] = s[1] = False
    for i in range(2, math.isqrt(n) + 1):
        if s[i]: s[i * i::i] = [False] * len(s[i * i::i])
    return s
isp = sieve(1000002)
P = [p for p in range(2, Q + 1) if isp[p]]
def L_of(Qm, h):                          # L = sum over squarefree q <= Qm of prod over p | q of h(p)
    tot = 0.0
    for q in range(1, Qm + 1):
        prod, m, p = 1.0, q, 2
        while m > 1:
            if m % p == 0:
                m //= p
                if m % p == 0: prod = None; break
                prod *= h(p)
            p += 1
        if prod is not None: tot += prod
    return tot
k_sq = lambda p: 0 if p == 2 else (p - 1) // 2          # k_p: classes a square never lands in, mod p
h_sq = lambda p: k_sq(p) / (p - k_sq(p))               # the odds k_p/(p - k_p)
# Road one: the exact count
A = [n for n in range(1, N + 1) if all(pow(n, (p - 1) // 2, p) in (0, 1) for p in P[1:])]
nsq = sum(1 for n in A if math.isqrt(n) ** 2 == n)
hit = {p: len({n % p for n in A}) for p in P}
print(f"A = n in 1..{N:,} that are a square mod every odd prime p <= {Q}: {len(A)} members, {nsq} of them perfect squares")
print(f"classes hit mod 3, 5, 7, 97: {hit[3]}, {hit[5]}, {hit[7]}, {hit[97]}; missed: {3 - hit[3]}, {5 - hit[5]}, {7 - hit[7]}, {97 - hit[97]}")
# Road two: the bound
budget = lambda n, q: n - 1 + q * q                  # the large sieve's constant N - 1 + Q^2, tested in road four
L = L_of(Q, h_sq)
L_seen = L_of(Q, lambda p: (p - hit[p]) / hit[p])   # second road: the odds from the classes A really hits
bound, gal = budget(N, Q) / L, (math.pi * N + Q * Q) / L
guess = N * math.prod(1 - k_sq(p) / p for p in P)
print(f"L = {L:.6f}; large sieve bound (N - 1 + Q^2)/L = {N - 1 + Q * Q:,}/{L:.6f} = {bound:.3f}")
print(f"Gallagher's constant (pi N + Q^2)/L = {gal:.3f}; independence guess N x prod(1 - k_p/p) = {guess:.6f}")
print(f"terms of L: q = 1: 1; q = 3: {h_sq(3):.6f}; q = 5: {h_sq(5):.6f}; q = 7: {h_sq(7):.6f}; q = 11: {h_sq(11):.6f}; q = 13: {h_sq(13):.6f}; q = 15: {h_sq(3) * h_sq(5):.6f}; total to 15: {L_of(15, h_sq):.6f}")
# Road three: the exponential sums at the Farey fractions a/q, q <= Q, gcd(a, q) = 1
def S(sq, a, q):                          # S(a/q) = sum over members n of e(n a/q), e(x) = exp(2 pi i x)
    re = im = 0.0
    for n in sq:
        t = 2 * math.pi * (n * a % q) / q; re += math.cos(t); im += math.sin(t)
    return re * re + im * im
farey = [(a, q) for q in range(1, Q + 1) for a in range(q) if math.gcd(a, q) == 1]
order = sorted(farey, key=lambda f: f[0] / f[1])
gaps = [(b * q - a * r, q * r) for (a, q), (b, r) in zip(order, order[1:])] + [(1 * order[-1][1] - order[-1][0], order[-1][1])]
mg = min(gaps, key=lambda g: g[0] / g[1])
print(f"Farey fractions with q <= {Q}: {len(farey):,}; closest pair {mg[0]}/{mg[1]:,}, at least 1/Q^2 = 1/{Q * Q:,}")
by_q = {}
for a, q in farey: by_q[q] = by_q.get(q, 0.0) + S(A, a, q)
T = sum(by_q.values())
print(f"left side, sum of |S(a/q)|^2: {T:,.3f}")
print(f"lower, |A|^2 L = {len(A) ** 2 * L:,.3f}; upper, (N - 1 + Q^2)|A| = {(N - 1 + Q * Q) * len(A):,}")
Z3 = [sum(1 for n in A if n % 3 == b) for b in range(3)]
print(f"q = 3: Z = {Z3}; |S(1/3)|^2 = {S(A, 1, 3):.3f}; sum over a = 1, 2: {by_q[3]:.3f}; lemma's floor |A|^2 x 1/2 = {len(A) ** 2 / 2:.3f}")
print(f"q = 3 Parseval: 3 x sum Z^2 = {3 * sum(z * z for z in Z3):,}; |S(0)|^2 + {by_q[3]:.3f} = {len(A) ** 2 + by_q[3]:,.3f}")
Z7 = [sum(1 for n in A if n % 7 == b) for b in range(7)]
par7 = sum(S(A, a, 7) for a in range(7))
print(f"q = 7: Z = {Z7}; sum over all a of |S(a/7)|^2 = {par7:,.3f}; 7 x sum Z^2 = {7 * sum(z * z for z in Z7):,}")
floors, worst = 0, 9.0
for q in range(2, Q + 1):
    f = L_of(q, h_sq) - L_of(q - 1, h_sq)        # the q-th term of L: 0 unless q is squarefree and odd
    if f > 0:
        floors += 1; worst = min(worst, by_q[q] / (len(A) ** 2 * f))
        assert by_q[q] >= len(A) ** 2 * f * (1 - 1e-9)   # Montgomery's lemma, modulus by modulus
print(f"odd squarefree q <= {Q} checked (q > 1) against the lemma's floor: {floors}; tightest ratio {worst:.6f}")
chart = [round((N - 1 + x * x) / L_of(x, h_sq)) for x in range(20, 201, 20)]
print("chart, bound at Q = 20, 40, ..., 200:", ", ".join(str(c) for c in chart))
# Road four: the worst sequence for a small case, N0 = 49 terms, Q0 = 7
N0, Q0 = 49, 7
F0 = [a / q for q in range(1, Q0 + 1) for a in range(q) if math.gcd(a, q) == 1]
c = [sum(math.cos(2 * math.pi * d * x) for x in F0) for d in range(N0)]
Kv = lambda v: [sum(c[abs(m - n)] * v[n] for n in range(N0)) for m in range(N0)]
M = [[c[abs(m - n)] for n in range(N0)] for m in range(N0)]   # the matrix whose top eigenvalue is the worst ratio
for sweep in range(12):                    # Jacobi rotations: zero each off-diagonal entry in turn
    for i in range(N0):
        for j in range(i + 1, N0):
            if abs(M[i][j]) < 1e-300: continue
            th = (M[j][j] - M[i][i]) / (2 * M[i][j]); t = (1 if th >= 0 else -1) / (abs(th) + math.sqrt(th * th + 1))
            cs = 1 / math.sqrt(t * t + 1); sn = t * cs
            for k in range(N0): M[k][i], M[k][j] = cs * M[k][i] - sn * M[k][j], sn * M[k][i] + cs * M[k][j]
            for k in range(N0): M[i][k], M[j][k] = cs * M[i][k] - sn * M[j][k], sn * M[i][k] + cs * M[j][k]
eig = sorted(M[i][i] for i in range(N0)); lam, off = eig[-1], max(abs(M[i][j]) for i in range(N0) for j in range(N0) if i != j)
st, worst_rand = 20261115, 0.0
for trial in range(20):                    # SplitMix64 signs: random +1/-1 sequences
    seq = []
    for _ in range(N0):
        st = (st + 0x9E3779B97F4A7C15) % 2 ** 64; z = st
        z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9 % 2 ** 64; z = (z ^ (z >> 27)) * 0x94D049BB133111EB % 2 ** 64
        seq.append(1.0 if (z ^ (z >> 31)) & 1 else -1.0)
    worst_rand = max(worst_rand, sum(x * y for x, y in zip(seq, Kv(seq))) / N0)
print(f"small case N0 = {N0}, Q0 = {Q0}: {len(F0)} fractions; worst ratio = top eigenvalue {lam:.6f}; next {eig[-2]:.6f}")
print(f"  eigenvalues add to {sum(eig):.6f}; trace N0 x fractions = {N0 * len(F0)}")
print(f"  random signs, best of 20: {worst_rand:.6f}; floor max(N0, fractions) = {max(N0, len(F0))}; bound N0 - 1 + Q0^2 = {N0 - 1 + Q0 * Q0}")
# The house example: twin pairs below a million
X, Qt = 10 ** 6, 300
twins = sum(1 for n in range(3, X + 1) if isp[n] and isp[n + 2])
small = sum(1 for n in range(3, Qt + 1) if isp[n] and isp[n + 2])
Lt = L_of(Qt, lambda p: 1 if p == 2 else 2 / (p - 2))
th = {p: len({n % p for n in range(Qt + 1, X + 1) if isp[n] and isp[n + 2]}) for p in range(2, Qt + 1) if isp[p]}
Lt_seen = L_of(Qt, lambda p: (p - th[p]) / th[p])   # second road: the odds from the classes the twins really hit
bt = (X - Qt - 1 + Qt * Qt) / Lt
print(f"twin pairs (n, n + 2) with n <= {X:,}: {twins:,}; with n <= {Qt}: {small}; above: {twins - small:,}")
print(f"twins, Q = {Qt}: L = {Lt:.6f}; bound ({X - Qt:,} - 1 + {Qt * Qt:,})/L = {bt:,.3f}; plus {small} small pairs = {bt + small:,.3f}")
# What breaks
primes = sum(isp[1:N + 1])
print(f"mistake 1, independence guess: {guess:.6f} against {len(A)} true")
print(f"mistake 2, the squares' bound used on the primes up to {N:,}: {bound:.3f} against {primes:,} primes")
print(f"mistake 3, drop Q^2: one term a_1 = 1 gives left side {len(farey):,} against N|a_1|^2 = 1 for N = 1")
print(f"mistake 4, points not spaced: {len(farey):,} copies of a/q = 0 give {len(farey) * len(A) ** 2:,} against {(N - 1 + Q * Q) * len(A):,}")
allq = sum(S(A, a, q) for q in range(1, Q + 1) for a in range(q))
print(f"trap, every a mod q, not just gcd 1: {allq:,.3f} against {(N - 1 + Q * Q) * len(A):,}")
Ls = L_of(Q, lambda p: k_sq(p) / p)
print(f"trap, q = 1 left out of L: bound {(N - 1 + Q * Q) / (L - 1):.3f}; shares k_p/p for odds: L = {Ls:.6f}, bound {(N - 1 + Q * Q) / Ls:.3f}")
assert len(A) == nsq == math.isqrt(N)                        # the sieve count equals the count of squares
assert all(hit[p] == (p + 1) // 2 for p in P[1:])             # A misses exactly (p - 1)/2 classes mod each odd p
assert len(A) <= bound < N and gal > bound                    # the theorem against the count
assert abs(L_seen - L) < 1e-9 and abs(Lt_seen - Lt) < 1e-9     # L from k_p by formula against k_p counted
assert len(A) ** 2 * L <= T <= (N - 1 + Q * Q) * len(A)       # both sides of the inequality
assert abs(par7 - 7 * sum(z * z for z in Z7)) < 1e-6          # Parseval: exponential sums against residue counts
assert mg == (1, Q * (Q - 1))                                # Farey spacing: closest pair 1/(Q(Q - 1))
assert off < 1e-9 and abs(sum(eig) - N0 * len(F0)) < 1e-9     # eigenvalues against the trace
assert max(N0, len(F0)) <= lam <= budget(N0, Q0) and worst_rand <= lam   # the exact worst case under the budget
assert twins == 8169 and bt >= twins - small                  # the house example
assert primes > bound and allq > (N - 1 + Q * Q) * len(A)     # the broken versions really break
print("ALL CHECKS PASS")
