# Convergence in distribution -- the check behind the card.  Standard library only.
# Each number is found by two roads that share no arithmetic: die totals are
# counted by adding one die at a time and by inclusion-exclusion; the normal
# distribution function by its power series and by Simpson's rule; the discrete
# uniform's averages by a direct sum and by a closed form.  The code checks
# finite n only; every statement about the limit rests on the proofs.
from fractions import Fraction as Q
from math import sqrt, pi, exp

def choose(a, b):                        # binomial coefficient, exact
    r = 1
    for i in range(b):
        r = r * (a - i) // (i + 1)
    return r

def counts_by_adding(n):                 # ways to roll each total s (the index) with n dice
    w = [1]
    for _ in range(n):
        new = [0] * (len(w) + 6)
        for s, c in enumerate(w):
            for face in range(1, 7):
                new[s + face] += c
        w = new
    return w

def counts_by_formula(n):                # inclusion-exclusion over faces pushed past 6
    return [sum((-1) ** k * choose(n, k) * choose(s - 6 * k - 1, n - 1)
                for k in range(n + 1) if s - 6 * k >= n) for s in range(6 * n + 1)]

def probs(n):                            # the same law in floating point: sum of six, over 6
    p = [1.0]
    for _ in range(n):
        pad = [0.0] * 6 + p + [0.0] * 6
        p = [sum(pad[s:s + 6]) / 6 for s in range(len(p) + 6)]
    return p

def phi_series(t):                       # 1/2 + sum (-1)^k t^(2k+1) / (2^k k! (2k+1)) / sqrt(2 pi)
    term, total = t, 0.0
    for k in range(80):
        total += term / (2 * k + 1)
        term *= -t * t / 2 / (k + 1)
    return 0.5 + total / sqrt(2 * pi)

def phi(t, m=2000):                      # 1/2 + Simpson's rule for the bell density on [0, t]
    h, s = t / m, 1 + exp(-t * t / 2)
    for i in range(1, m):
        x = i * h
        s += (4 if i % 2 else 2) * exp(-x * x / 2)
    return 0.5 + s * h / 3 / sqrt(2 * pi)

def cdf(p, x):                           # P(S <= x) from a list indexed by total
    return sum(p[s] for s in range(len(p)) if s <= x)

def f4(x):
    return f"{x:.4f}"

P = {n: probs(n) for n in (1, 2, 10, 100, 1000)}
exact = {n: (counts_by_adding(n), counts_by_formula(n)) for n in (2, 10)}
print("die: S_n = total of n rolls, Z_n = (S_n - 3.5 n) / sqrt(35 n / 12)")
yes = lambda b: "yes" if b else "no"
print(f"counts by adding dice = counts by inclusion-exclusion: n=2 {yes(exact[2][0] == exact[2][1])} "
      f"({sum(exact[2][0])} outcomes), n=10 {yes(exact[10][0] == exact[10][1])} ({sum(exact[10][0])} outcomes)")
print("n=2 counts of totals 2..12:", " ".join(map(str, exact[2][0][2:])), f"; {sum(exact[2][0][:8])} of 36 at or below 7")
float_err = max(abs(P[10][s] - Q(c, 6 ** 10)) for s, c in enumerate(exact[10][0]))
print(f"n=10 floating-point law against exact fractions, worst gap below 1e-15: {yes(float_err < 1e-15)}")
ts = [x / 2 for x in range(-5, 6)]
ser = [phi_series(t) for t in ts]
simp = [phi(t) for t in ts]
print(f"Phi by series and by Simpson, t = 0.5, 1, 2: {ser[6]:.6f} {simp[6]:.6f}, "
      f"{ser[7]:.6f} {simp[7]:.6f}, {ser[9]:.6f} {simp[9]:.6f}")
Fz = lambda n, t: cdf(P[n], 3.5 * n + t * sqrt(35 * n / 12))
print("chart t:   ", ", ".join(f"{t:g}" for t in ts))
for n in (2, 10):
    print(f"chart F_{n}:{' ' * (3 - len(str(n)))}", ", ".join(f"{Fz(n, t):.2f}" for t in ts))
print("chart Phi: ", ", ".join(f"{x:.2f}" for x in simp))
gaps = {}
for n in (1, 2, 10, 100):                # sup |F_n - Phi| is reached at a jump of F_n
    sd, below, worst = sqrt(35 * n / 12), 0.0, 0.0
    for s in range(n, 6 * n + 1):
        ph = phi((s - 3.5 * n) / sd)
        worst = max(worst, abs(below - ph), abs(below + P[n][s] - ph))
        below += P[n][s]
    gaps[n] = worst
    print(f"n={n:3d}: F_n(0) = {f4(Fz(n, 0))}, largest jump {f4(max(P[n]))}, sup |F_n - Phi| = {f4(worst)}")

print("discrete uniform U_n on {1/n, ..., 1}; for U uniform on (0, 1), F(1/3) = 1/3 and E[U^2] = 1/3")
unif = []
for n in (10, 100, 1000):
    count = sum(1 for k in range(1, n + 1) if 3 * k <= n)
    sq_sum, sq_form = sum(Q(k * k, n ** 3) for k in range(1, n + 1)), Q((n + 1) * (2 * n + 1), 6 * n * n)
    unif.append((count, n // 3, sq_sum, sq_form))
    print(f"n={n:4d}: F_n(1/3) = {count}/{n} (formula floor(n/3)/n = {n // 3}/{n}), "
          f"E[U_n^2] = {float(sq_sum):.7f} (closed form {float(sq_form):.7f})")
ramp = lambda x, t, e: min(1.0, max(0.0, (t + e - x) / e))   # Step 1's g: 1 up to t, 0 from t + e
point = [(n, int(1 / n <= 0), int(1 / n <= 0.01)) for n in (10, 100, 1000)]
print("X_n = 1/n: n, F_n(0), F_n(0.01):", "; ".join(f"{a}, {b}, {c}" for a, b, c in point),
      "; limit F(0) = 1, F(0.01) = 1")
squeeze = all(ramp(1 / n + e, t, e) <= (1 / n <= t) <= ramp(1 / n, t, e)
              for n in (10, 100, 1000) for t in (0, 0.02, 0.2) for e in (0.001, 0.05))
print(f"ramps h <= F_n(t) <= g for X_n = 1/n at t = 0, 0.02, 0.2: {yes(squeeze)}")
faces = list(range(1, 7))
under = [7 - d for d in faces]                          # the face underneath, outcome by outcome
law = lambda xs: {v: Q(xs.count(v), len(xs)) for v in xs}   # six equally likely outcomes
near = sum(Q(1, 6) for d, u in zip(faces, under) if abs(u - d) < 1)
print("flip 7 - D: law equals D's law:", yes(law(under) == law(faces)), "; |(7 - D) - D| for D = 1..6:",
      " ".join(str(abs(u - d)) for d, u in zip(faces, under)), f"; P(|(7 - D) - D| < 1) = {near}")
lump = []
for n in (10, 100, 1000):                               # X_n = n with chance 1/n, else 0
    lw = {0: 1 - Q(1, n), n: Q(1, n)}
    lump.append((n, sum(p for x, p in lw.items() if x <= Q(1, 2)), sum(x * p for x, p in lw.items()),
                 sum(min(x, 1) * p for x, p in lw.items())))
print("X_n = n with chance 1/n, else 0: n, F_n(1/2), E[X_n], E[min(X_n, 1)]:",
      "; ".join(f"{a}, {b}, {c}, {d}" for a, b, c, d in lump), "; limit 0: 1, 0, 0")

print("running average A_n = S_n / n against the constant 3.5, gap at least 0.1:")
far = {}
for n in (10, 100, 1000):
    far[n] = sum(p for s, p in enumerate(P[n]) if 10 * abs(2 * s - 7 * n) >= 2 * n)
    print(f"n={n:4d}: P(|A_n - 3.5| >= 0.1) = {f4(far[n])}, Chebyshev bound 35/(12 n 0.01) = {f4(35 / (12 * n * 0.01))}")
tight = sum(p for s, p in enumerate(P[1000]) if 10 * abs(2 * s - 7000) >= 1000)   # tolerance 0.05
print(f"n=1000: P(|A_n - 3.5| < 0.1) = {f4(1 - far[1000])}; tolerance 0.05: P(|A_n - 3.5| >= 0.05) = {f4(tight)}")
nosc = {n: cdf(P[n], 3.5 * n + 10) for n in (10, 100, 1000)}
print("centred, unscaled S_n - 3.5 n: F(10) at n = 10, 100, 1000:", ", ".join(f4(nosc[n]) for n in nosc))

assert exact[2][0] == exact[2][1] and exact[10][0] == exact[10][1] and float_err < 1e-15
assert max(abs(a - b) for a, b in zip(ser, simp)) < 1e-10          # two roads to Phi
assert all(a == b and c == d for a, b, c, d in unif)                  # uniform: count and sum, two roads
assert gaps[1] > gaps[2] > gaps[10] > gaps[100] and abs(gaps[100] - max(P[100]) / 2) < 1e-3
assert round(1 - far[1000], 4) == 0.9346                              # wing 09's exact count
assert all(far[n] <= 35 / (12 * n * 0.01) for n in far)                # Chebyshev, a separate road
assert squeeze                                                              # Step 1's squeeze, at the jump and off it
assert law(under) == law(faces) and near == 0                                # same law, never close
assert all(m == 1 and c == Q(1, n) for n, _, m, c in lump)   # law's mean against n * (1/n) = 1; capped mean against 1/n
assert nosc[10] > nosc[100] > nosc[1000] > 0.5
