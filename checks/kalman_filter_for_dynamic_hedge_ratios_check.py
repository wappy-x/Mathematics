# A moving hedge ratio -- the check behind the card.  Standard library only.
# Nothing imported knows the answer: the random numbers, the filter, the rolling
# regression and the tridiagonal solver are all written out below.
from math import log, cos, sqrt, pi

MASK = (1 << 64) - 1

class Rng:                                   # splitmix64, then Box-Muller for bell-curve draws
    def __init__(self, seed): self.s = seed
    def uniform(self):
        self.s = (self.s + 0x9E3779B97F4A7C15) & MASK
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & MASK
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & MASK
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
    def normal(self):
        u1, u2 = 1.0 - self.uniform(), self.uniform()
        return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2)

def kalman(A, B, m0, P0, Q, R):              # road 1: predict, then update, one day at a time
    m, P, out = m0, P0, []
    for a, b in zip(A, B):
        Pp = P + Q                           # predict: the ratio may have taken a step of variance Q
        S = b * b * Pp + R                   # variance of today's price surprise
        K = Pp * b / S                       # gain: change in the ratio per dollar of surprise
        e = a - m * b                        # surprise: A's price minus the A price predicted
        m, P = m + K * e, Pp * R / S
        out.append((m, P, K * b, e))
    return out

def batch(A, B, m0, P0, Q, R):               # road 2: one penalised regression over the whole path
    n = len(A)                               # unknowns beta_0 .. beta_n, tridiagonal normal equations
    diag = [1 / P0 + 1 / Q] + [2 / Q + b * b / R for b in B[:-1]] + [1 / Q + B[-1] ** 2 / R]
    rhs = [m0 / P0] + [a * b / R for a, b in zip(A, B)]
    off = -1 / Q
    for i in range(1, n + 1):                # Thomas algorithm: eliminate downwards,
        f = off / diag[i - 1]
        diag[i] -= f * off
        rhs[i] -= f * rhs[i - 1]
    return rhs[n] / diag[n]                  # and the last unknown is today's ratio

def rolling(A, B, w, t):                     # least squares through zero on the last w days, from day 1
    days = range(max(1, t - w + 1), t + 1)
    return sum(A[j] * B[j] for j in days) / sum(B[j] ** 2 for j in days)

# ---- hand example: B at $100 every day, prior 1.30, P0 = Q = 0.0001, R = 1 ----
hA, hB = [129.0, 127.0, 126.0, 124.0], [100.0] * 4
hand = kalman(hA, hB, 1.30, 1e-4, 1e-4, 1.0)
fib = [0, 1]
for _ in range(60): fib.append(fib[-1] + fib[-2])
print("hand example: B = $100 every day, prior 1.30, P0 = Q = 0.0001, R = 1")
for d, (a, (m, P, w, e)) in enumerate(zip(hA, hand), 1):
    r2 = sum(hA[max(0, d - 2):d]) / (100 * len(hA[max(0, d - 2):d]))
    print(f"  day {d}  A {a:6.2f}  surprise {e:+.4f}  weight {w:.6f} = {fib[2*d+1]}/{fib[2*d+2]}  estimate {m:.6f}  P {P:.8f}  2-day {r2:.4f}")
hand_batch = batch(hA, hB, 1.30, 1e-4, 1e-4, 1.0)
w20 = kalman([130.0] * 20, [100.0] * 20, 1.30, 1e-4, 1e-4, 1.0)[-1][2]
golden = (sqrt(5.0) - 1.0) / 2.0
print(f"  day 4 by batch regression {hand_batch:.6f}")
print(f"  weight on day 20 {w20:.9f};  (sqrt 5 - 1)/2 = {golden:.9f}")

# ---- the simulated year: B wanders from $100, true ratio slides 1.30 -> 1.10, A = ratio x B + $1 noise ----
rng = Rng(20260928)
N, M0, P0, Q, R = 250, 1.30, 1e-4, 1e-6, 1.0
beta = [1.3 - 0.2 * t / N for t in range(N + 1)]
B = [100.0]
for t in range(N): B.append(B[-1] + rng.normal())
A = [beta[t] * B[t] + rng.normal() for t in range(N + 1)]
kf = kalman(A[1:], B[1:], M0, P0, Q, R)
est = [M0] + [row[0] for row in kf]          # est[t] uses prices up to and including day t
road2 = max(abs(batch(A[1:t + 1], B[1:t + 1], M0, P0, Q, R) - est[t]) for t in range(1, N + 1))
static = kalman(A[1:], B[1:], M0, P0, 0.0, R)[-1][0]
closed = (M0 / P0 + sum(a * b for a, b in zip(A[1:], B[1:])) / R) / (1 / P0 + sum(b * b for b in B[1:]) / R)
fixed = sum(a * b for a, b in zip(A[1:], B[1:])) / sum(b * b for b in B[1:])
roll = {w: [rolling(A, B, w, t) for t in range(60, N + 1)] for w in (20, 60, 120)}

def rmse(path): return sqrt(sum((p - beta[t]) ** 2 for t, p in zip(range(60, N + 1), path)) / (N - 59))
print(f"simulated year: prior {M0:.2f}, P0 {P0:.4f}, Q {Q:.6f}, R {R:.0f}; B steps and A noise have sd $1")
print(f"  seed 20260928: B starts {B[0]:.2f}, ends {B[N]:.2f}; A starts {A[0]:.2f}, ends {A[N]:.2f}")
print(f"  true ratio day 250           {beta[N]:.6f}")
print(f"  Kalman estimate day 250      {est[N]:.6f}  plus or minus {2 * sqrt(kf[-1][1]):.6f} (two sd)")
print(f"  Kalman weight on day 250     {kf[-1][2]:.6f}")
print(f"  rolling 60-day, day 250      {roll[60][-1]:.6f}")
print(f"  one fixed ratio, whole year  {fixed:.6f}")
k, mean_e = kf[-1][2], sum(row[3] for row in kf) / N
print(f"  lag rule, drift {0.2 / N:.4f} a day: rolling 60 lags {0.2 / N * 59 / 2:.6f}; Kalman lags {0.2 / N * (1 - k) / k:.6f}")
print(f"  Kalman surprise, mean over days 1 to 250: {mean_e:.4f}; shrink factor 1 - weight = {1 - k:.6f}")
print(f"  road 2, batch regression vs filter, worst day: {road2 * 1e15:.2f} x 10^-15")
print(f"  Q = 0 filter {static:.9f};  expanding regression with prior {closed:.9f}")
print("accuracy against the true ratio, days 60 to 250 (root mean square error)")
kf_rmse = {}
for q, label in ((0.0, "0"), (1e-7, "0.0000001"), (1e-6, "0.000001"), (1e-5, "0.00001"), (1e-4, "0.0001")):
    path = [M0] + [row[0] for row in kalman(A[1:], B[1:], M0, P0, q, R)]
    kf_rmse[q] = rmse(path[60:])
    print(f"  Kalman, Q = {label:<10}      {kf_rmse[q]:.6f}")
for w in (20, 60, 120):
    print(f"  rolling {w:>3}-day             {rmse(roll[w]):.6f}")

# ---- road 3: does the filter's own P match its real error?  2,000 worlds drawn from the model ----
mc, sq = Rng(7), 0.0
for _ in range(2000):
    b_true = M0 + sqrt(P0) * mc.normal()
    As = []
    for t in range(1, 51):
        b_true += sqrt(Q) * mc.normal()
        As.append(b_true * B[t] + sqrt(R) * mc.normal())
    sq += (kalman(As, B[1:51], M0, P0, Q, R)[-1][0] - b_true) ** 2
print(f"road 3: filter's P on day 50 {kf[49][1]:.10f};  mean squared error over 2,000 simulated worlds {sq / 2000:.10f}")

days = list(range(60, N + 1, 10))
print("chart, day            " + " ".join(f"{t:6d}" for t in days))
print("chart, true ratio     " + " ".join(f"{beta[t]:6.3f}" for t in days))
print("chart, Kalman         " + " ".join(f"{est[t]:6.3f}" for t in days))
print("chart, rolling 60     " + " ".join(f"{roll[60][t - 60]:6.3f}" for t in days))
sdays = list(range(0, N + 1, 10))
print("chart, spread day     " + " ".join(f"{t:6d}" for t in sdays))
print("chart, fixed ratio $  " + " ".join(f"{A[t] - fixed * B[t]:6.2f}" for t in sdays))
print("chart, Kalman $       " + " ".join(f"{A[t] - est[max(t - 1, 0)] * B[t]:6.2f}" for t in sdays))

assert all(abs(w - fib[2 * d + 1] / fib[2 * d + 2]) < 1e-12 for d, (_, _, w, _) in enumerate(hand, 1))
assert abs(hand_batch - hand[-1][0]) < 1e-9 and abs(w20 - golden) < 1e-12
assert road2 < 1e-9, "the filter must equal the end point of the whole-path regression"
assert abs(static - closed) < 1e-12, "with Q = 0 the filter is an expanding regression"
assert abs(sq / 2000 / kf[49][1] - 1) < 0.10, "the filter's P must match its real squared error"
assert kf_rmse[1e-6] < rmse(roll[60]) and kf_rmse[1e-6] < kf_rmse[0.0]
print("ALL CHECKS PASS")
