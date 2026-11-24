# McKean-Vlasov in outline: banks pulled toward the crowd's mean reserve.
# Bank i: dX^i = -K (X^i - crowd mean) dt + S dW^i from X0; limit dX = -K (X - E[X_t]) dt + S dW.
# Roads: closed forms; moment recursions of the Euler scheme; Simpson quadrature;
# Picard iteration on the mean; seeded particle simulation (SplitMix64, Box-Muller).
import math

K, S, X0, N, T = 1.0, 1.0, 2.0, 1000, 1.0
M64 = (1 << 64) - 1

class Rng:
    def __init__(self, seed):
        self.s, self.spare = seed, None
    def u(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & M64
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M64
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
    def normal(self):
        if self.spare is not None:
            z, self.spare = self.spare, None
            return z
        u1, u2 = 1.0 - self.u(), self.u()
        r = math.sqrt(-2.0 * math.log(u1))
        self.spare = r * math.sin(2.0 * math.pi * u2)
        return r * math.cos(2.0 * math.pi * u2)

def v_lim(t): return S * S / (2 * K) * (1 - math.exp(-2 * K * t))
def gap2(t, n): return S * S / n * (t - 2 * (1 - math.exp(-K * t)) / K + v_lim(t) / (S * S))
def cov2(t, n): return S * S / n * (t - v_lim(t) / (S * S))

def scheme(n, h, steps):  # exact moments of the Euler scheme: spread, mean, gap, pair covariance
    r = 1 - K * h
    v = q = a = c = 0.0
    for _ in range(steps):
        a, c = r * r * a + 2 * r * K * h * c + K * h * K * h * q, r * c + K * h * q
        v, q = r * r * v + S * S * h * (1 - 1 / n), q + S * S * h / n
    return v, q, a, q - v / (n - 1)

def simpson(f, a, b, m):
    s = f(a) + f(b)
    for j in range(1, m):
        s += (4 if j % 2 else 2) * f(a + j * (b - a) / m)
    return s * (b - a) / m / 3

def phi(x):  # chance a standard normal falls below x
    half = simpson(lambda y: math.exp(-y * y / 2) / math.sqrt(2 * math.pi), 0.0, abs(x), 2000)
    return 0.5 + half if x >= 0 else 0.5 - half

e1, e2 = math.exp(-1), math.exp(-2)
vl, vd = v_lim(T), (1 - 1 / N) * v_lim(T)
g, cv, vb = gap2(T, N), cov2(T, N), (1 - 1 / N) * v_lim(T) + S * S * T / N
p_lend, p_alone = phi(-X0 / math.sqrt(vb)), phi(-X0 / (S * math.sqrt(T)))
print(f"K = {K} per year, S = {S} $M per root year, X0 = {X0} $M, N = {N} banks, t = {T} year")
print(f"hand: e^-1 {e1:.6f}, e^-2 {e2:.6f}, 1 - 2(1 - e^-1) + v(1) = {g * N:.6f}")
print(f"limit variance v(1)              {vl:.6f}   stationary {S * S / (2 * K):.6f}")
print(f"spread around crowd mean, N={N} {vd:.6f}   stationary {(1 - 1 / N) * S * S / (2 * K):.6f}")
print(f"crowd mean variance t/N          {S * S * T / N:.6f}   sd {math.sqrt(S * S * T / N):.6f}")
print(f"gap to limit, mean square        {g:.6f}   x N {g * N:.6f}   rms {math.sqrt(g):.6f}")
print(f"covariance of two banks          {cv:.6f}   x N {cv * N:.6f}")
print(f"variance of one bank             {vb:.6f}   correlation {cv / vb:.6f}")
print(f"chance a bank is below 0         with lending {p_lend:.6f}   alone {p_alone:.6f}")
assert abs(p_alone - 0.0227501319) < 1e-8  # published value of the normal tail at 2
print(f"pull to fixed target 0: mean {X0 * e1:.6f}; crowd mean after 1000 years sd {math.sqrt(1000 / N):.6f}")
# road 2: moments of the Euler scheme with a fine step, against the closed forms
v, q, a, c = scheme(N, 1e-4, 10000)
print(f"recursion, step 1e-4: spread {v:.6f} mean var {q:.6f} gap {a * N:.6f}/N cov {c * N:.6f}/N")
for got, want in ((v, vd), (q, S * S * T / N), (a, g), (c, cv)):
    assert abs(got - want) < 1e-3 * abs(want)
simp = S * S * simpson(lambda u: (1 - math.exp(-K * u)) * (1 - math.exp(-K * u)), 0.0, 1.0, 1000)
print(f"Simpson, integral of (1 - e^-u)^2 over [0, 1]: {simp:.6f}")
assert abs(simp - g * N) < 1e-9
# road 3: Picard iteration on the mean path; closed form X0 e^-t (1 + t + ... + t^(k-1)/(k-1)!)
steps, h = 1000, 1e-3
m_path, decay = [0.0] * (steps + 1), math.exp(-K * h)
for k in range(1, 7):
    new, conv = [X0], 0.0
    for j in range(steps):
        conv = decay * conv + K * h / 2 * (decay * m_path[j] + m_path[j + 1])
        new.append(X0 * math.exp(-K * (j + 1) * h) + conv)
    m_path = new
    closed, term = 0.0, 1.0
    for j in range(k): closed, term = closed + term, term / (j + 1)
    closed = X0 * e1 * closed
    print(f"Picard round {k}: mean at 1 year {m_path[-1]:.6f}   closed form {closed:.6f}")
    assert abs(m_path[-1] - closed) < 1e-6
assert abs(m_path[-1] - X0) < 0.002
def simulate(n, reps, h, steps, every):  # road 4: Euler-Maruyama simulation
    sm = sd = sc = 0.0
    trace, sh = [], S * math.sqrt(h)
    for _ in range(reps):
        x, xb = [X0] * n, [X0] * n
        for k in range(steps + 1):
            tot = 0.0
            for xi in x: tot += xi
            m = tot / n
            if every and k % every == 0:
                ss = 0.0
                for xi in x: ss += (xi - m) * (xi - m)
                trace.append((k * h, m, ss / n))
            if k == steps:
                break
            for i in range(n):
                dw = sh * rng.normal()
                x[i] += -K * (x[i] - m) * h + dw
                xb[i] += -K * (xb[i] - X0) * h + dw
        s1 = s2 = 0.0
        for xi in x:
            s1 += xi - X0
            s2 += (xi - X0) * (xi - X0)
        sm += (m - X0) * (m - X0) / reps
        sd += (x[0] - xb[0]) * (x[0] - xb[0]) / reps
        sc += (s1 * s1 - s2) / (n * (n - 1)) / reps
    return sm, sd, sc, trace

rng = Rng(20261123)
print(f"-- simulation: one crowd of {N}, step 0.01 year, 5 years --")
_, _, _, tr = simulate(N, 1, 0.01, 500, 25)
for t_mark in (1.0, 5.0):
    t, m, sp = tr[int(t_mark * 4)]
    want = scheme(N, 0.01, int(t_mark * 100))[0]
    se = want * math.sqrt(2 / N)
    print(f"t = {t:.0f}: spread sim {sp:.6f} +- {se:.6f}  scheme {want:.6f}  crowd mean {m:.6f}")
    assert abs(sp - want) < 4 * se and abs(m - X0) < 4 * math.sqrt(t / N)
print("chart, t      " + " ".join(f"{t:.2f}" for t, _, _ in tr))
print("chart, spread " + " ".join(f"{sp:.3f}" for _, _, sp in tr))
print("chart, v(t)   " + " ".join(f"{(1 - 1 / N) * v_lim(t):.3f}" for t, _, _ in tr))
print("chart, mean   " + " ".join(f"{m:.3f}" for _, m, _ in tr))
print("chart, 2e^-t  " + " ".join(f"{X0 * math.exp(-K * t):.3f}" for t, _, _ in tr))
print("-- simulation: many small crowds, step 0.02 year, to 1 year --")
for n, reps in ((10, 10000), (100, 2000)):
    sm, sd, sc, _ = simulate(n, reps, 0.02, 50, 0)
    v, q, a, c = scheme(n, 0.02, 50)
    print(f"N = {n}, {reps} crowds: mean var sim {sm:.6f} scheme {q:.6f} formula {T / n:.6f}")
    print(f"  gap x N  sim {sd * n:.4f} +- {a * n * math.sqrt(2 / reps):.4f}  scheme {a * n:.4f}  formula {gap2(T, n) * n:.4f}")
    print(f"  cov x N  sim {sc * n:.4f} +- {q * n * math.sqrt(2 / reps):.4f}  scheme {c * n:.4f}  formula {cov2(T, n) * n:.4f}")
    assert abs(sm - q) < 4 * q * math.sqrt(2 / reps)
    assert abs(sd - a) < 4 * a * math.sqrt(2 / reps)
    assert abs(sc - c) < 4 * math.sqrt(2.0 / reps) * q
print("ALL CHECKS PASS")
