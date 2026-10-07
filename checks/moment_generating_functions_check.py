# Moment generating functions -- the check behind the card.  Only math is
# imported, for exp, log and sqrt.  A fair coin scores X = 1 for heads and 0
# for tails; S counts the heads in ten independent flips.  Each moment E[S^k]
# is reached four ways: Taylor coefficients of M_X(t) multiplied ten times,
# an average over all 1,024 flip sequences, numerical derivatives of E[e^(tS)]
# at t = 0, and a seeded simulation.  Then two failures: copies, a heavy tail.
import math

P, N, KMAX = 0.5, 10, 4
LAW_X = [(0, 1 - P), (1, P)]                  # (value, chance) for one flip

def mgf(law, t):                              # the definition: sum of chance * e^(t x)
    total = 0.0                               # a plain loop, added in order, as in Rust
    for x, c in law:
        total += c * math.exp(t * x)
    return total

SEQS = []                                     # every sequence of ten flips, as (heads, chance)
for code in range(2 ** N):
    h = bin(code).count("1")
    SEQS.append((h, P ** h * (1 - P) ** (N - h)))

def mgf_s_enum(t):                            # E[e^(tS)] straight from the 1,024 sequences
    return mgf(SEQS, t)

def moment_enum(k):                           # road 2: E[S^k] by averaging over sequences
    return sum(c * h ** k for h, c in SEQS)

def taylor_x():                               # coefficients E[X^k] / k! of M_X(t)
    return [sum(c * x ** k for x, c in LAW_X) / math.factorial(k) for k in range(KMAX + 1)]

def poly_mul(a, b):                           # product of two series, cut at t^KMAX
    out = [0.0] * (KMAX + 1)
    for i, ai in enumerate(a):
        for j, bj in enumerate(b):
            if i + j <= KMAX:
                out[i + j] += ai * bj
    return out

series_s = [1.0] + [0.0] * KMAX               # road 1: M_S = M_X ten times over
for _ in range(N):
    series_s = poly_mul(series_s, taylor_x())
m_taylor = [series_s[k] * math.factorial(k) for k in range(KMAX + 1)]

def derivs_at_zero(f, h):                     # road 3: central differences, orders 1 to 4
    f2, f1, f0, g1, g2 = f(2 * h), f(h), f(0.0), f(-h), f(-2 * h)
    return [f0, (f1 - g1) / (2 * h), (f1 - 2 * f0 + g1) / h ** 2,
            (f2 - 2 * f1 + 2 * g1 - g2) / (2 * h ** 3), (f2 - 4 * f1 + 6 * f0 - 4 * g1 + g2) / h ** 4]
m_diff = derivs_at_zero(mgf_s_enum, 1e-3)

def splitmix64(state):                        # the generator both languages share
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return state, z ^ (z >> 31)

RUNS, state, sums = 200_000, 20260928, [0.0] * 6   # road 4: S, S^2, e^(0.1 S), and their squares
for _ in range(RUNS):
    s = 0
    for _ in range(N):
        state, z = splitmix64(state)
        s += 1 if (z >> 11) * 2.0 ** -53 < P else 0
    for i, v in enumerate((s, s * s, math.exp(0.1 * s))):
        sums[i] += v
        sums[i + 3] += v * v
est = [sums[i] / RUNS for i in range(3)]
se = [math.sqrt((sums[i + 3] / RUNS - est[i] ** 2) / RUNS) for i in range(3)]

def row(label, v, fmt="{:>14.6f}"):
    print(f"{label:<44}" + fmt.format(v))

row("coin: M_X(0)", mgf(LAW_X, 0.0))
coin_slope = derivs_at_zero(lambda t: mgf(LAW_X, t), 1e-3)[1]
row("coin: M_X'(0) by central difference", coin_slope)
row("coin: E[X^2] = E[X^3] = E[X^4]", sum(c * x ** 3 for x, c in LAW_X))
row("coin: variance E[X^2] - E[X]^2", P - P * P)
print("ten flips, E[S^k]:  k   Taylor x k!   all 1,024   derivative   simulated (se)")
for k in range(1, KMAX + 1):
    sim = f"{est[k - 1]:>10.4f} ({se[k - 1]:.4f})" if k <= 2 else ""
    print(f"{'':<20}{k:>2} {m_taylor[k]:>12.4f} {moment_enum(k):>11.4f} {m_diff[k]:>12.4f}  {sim}".rstrip())
mean_s, var_s = moment_enum(1), moment_enum(2) - moment_enum(1) ** 2
row("ten flips: variance E[S^2] - E[S]^2", var_s)
row("ten flips: standard deviation", math.sqrt(var_s))
row("ten flips: third central moment", moment_enum(3) - 3 * mean_s * moment_enum(2) + 2 * mean_s ** 3)
row("Taylor coefficient of t^2 in M_S", series_s[2])
row("Taylor coefficient of t^3 in M_S", series_s[3])
row("P(S = 5): count of sequences with 5 heads", sum(c for h, c in SEQS if h == 5))
print("product rule:   t    E[e^(tS)] over 1,024   M_X(t)^10")
for t in (-1.0, -0.5, 0.1, 0.5, 1.0):
    print(f"{'':<12}{t:>6.1f} {mgf_s_enum(t):>21.6f} {mgf(LAW_X, t) ** N:>11.6f}")
    assert abs(mgf_s_enum(t) - mgf(LAW_X, t) ** N) < 1e-12 * mgf_s_enum(t), t
row("simulated E[e^(0.1 S)]", est[2])
row("  its standard error", se[2])

COPY = [(0, 1 - P), (N, P)]                   # one flip copied ten times: S = 10 X
row("wrong: copies, M(0.1) of 10X", mgf(COPY, 0.1))
row("wrong: copies, E[(10X)^2] by derivative", derivs_at_zero(lambda t: mgf(COPY, t), 1e-3)[2])
row("wrong: copies, variance", N * N * (P - P * P))
row("wrong: slope at t = 1, M_X'(1)", P * math.exp(1.0))
row("wrong: t^2 coefficient read as E[S^2]", series_s[2])
TAIL = [(k, math.exp(-math.sqrt(k))) for k in range(40_001)]
c_tail = sum(w for _, w in TAIL)              # heavy tail: chance of k proportional to e^(-sqrt k)
row("heavy tail: E[L]", sum(k * w for k, w in TAIL) / c_tail)
row("heavy tail: E[L^2]", sum(k * k * w for k, w in TAIL) / c_tail)
logs = []
for cut in (2_500, 10_000, 40_000):
    logs.append(math.log(sum(math.exp(0.01 * k) * w for k, w in TAIL[:cut + 1]) / c_tail))
    row(f"heavy tail: ln of E[e^(0.01 L)], k <= {cut:,}", logs[-1])
ts = [-2 + 0.5 * i for i in range(9)]
print("chart1, M_X(t):   " + " ".join(f"{mgf(LAW_X, t):.2f}" for t in ts))
print("chart1, 1 + t/2:  " + " ".join(f"{1 + t / 2:.2f}" for t in ts))
print("chart1, + t^2/4:  " + " ".join(f"{1 + t / 2 + t * t / 4:.2f}" for t in ts))
ts2 = [-0.3 + 0.1 * i for i in range(7)]
print("chart2, independent: " + " ".join(f"{mgf(LAW_X, t) ** N:.2f}" for t in ts2))
print("chart2, copies 10X:  " + " ".join(f"{mgf(COPY, t):.2f}" for t in ts2))

for k in range(1, KMAX + 1):
    assert abs(m_taylor[k] - moment_enum(k)) < 1e-9 * moment_enum(k), f"Taylor vs sequences, k={k}"
    assert abs(m_diff[k] - moment_enum(k)) < 1e-3 * moment_enum(k), f"derivative vs sequences, k={k}"
for i, exact in enumerate((moment_enum(1), moment_enum(2), mgf_s_enum(0.1))):
    assert abs(est[i] - exact) < 4 * se[i], f"simulation {i} within four standard errors"
assert abs(mgf(COPY, 0.1) - mgf(LAW_X, 0.1) ** N) > 0.1, "copies must break the product rule"
assert abs(coin_slope - sum(c * x for x, c in LAW_X)) < 1e-6, "coin slope at zero is the mean"
assert logs[0] < 1 < 10 * logs[1] < logs[2], "heavy tail: partial sums must run away"
print("ALL CHECKS PASS")
