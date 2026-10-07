# Premiums and reserves -- the check behind the card.  Standard library only.
# Policy: 20-year term insurance on a life aged 40.  $100,000 paid at the end of
# the year of death; a level premium due at the start of each year while alive;
# money earns 5% a year, continuously compounded.  Nothing imported knows the answer.
from math import exp, log, sqrt

S, X, N, T, r = 100000.0, 40, 20, 10, 0.05    # sum insured, issue age, term, reserve year, rate
A_, B_, C_ = 0.00022, 2.7e-6, 1.124           # Makeham force of mortality: A + B c^age

def q(age):  # chance of dying within the year from `age`: 1 - e^-(the force, added up over the year)
    return 1.0 - exp(-A_ - B_ * C_ ** age * (C_ - 1.0) / log(C_))

def values(age, n, rate, freeze=None):
    # Road 1: add up the years.  Returns (A, a): insurance of $1 and annuity-due of $1 a year.
    v, ins, ann, alive = exp(-rate), 0.0, 0.0, 1.0
    for k in range(n):
        qk = q(age + k if freeze is None else freeze)
        ann += v ** k * alive
        ins += v ** (k + 1) * alive * qk
        alive *= 1.0 - qk
    return ins, ann

def premium(age=X, n=N, rate=r):
    ins, ann = values(age, n, rate)
    return S * ins / ann

def backward(P, age=X, n=N, rate=r):
    # Road 2: the recursion, run from the end of cover (reserve 0) back to the start.
    v, V = exp(-rate), [0.0] * (n + 1)
    for t in range(n - 1, -1, -1):
        V[t] = v * (q(age + t) * S + (1.0 - q(age + t)) * V[t + 1]) - P
    return V

def bisect_premium():  # the premium at which the backward recursion lands on 0 at issue
    lo, hi = 0.0, S
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if backward(mid)[0] > 0.0 else (lo, mid)
    return 0.5 * (lo + hi)

def cohort(P, lives=10000.0):
    # Road 3: follow the office's 10,000 policies forward.  Fund per survivor = reserve.
    fund, l, per, alive = 0.0, lives, [], []
    for t in range(N):
        per.append(fund / l); alive.append(l)
        deaths = l * q(X + t)
        fund = (fund + l * P) * exp(r) - deaths * S
        l -= deaths
    per.append(fund / l); alive.append(l)
    return per, alive

MASK, st = (1 << 64) - 1, [0x9E3779B97F4A7C15]
def uniform():  # xorshift64*, written out, so Python and Rust draw the same numbers
    x = st[0]; x ^= x >> 12; x ^= (x << 25) & MASK; x ^= x >> 27; st[0] = x
    return (((x * 0x2545F4914F6CDD1D) & MASK) >> 11) / 9007199254740992.0

def death_table(age, n):  # chance of dying by the end of year k+1, k = 0..n-1
    cum, alive = [], 1.0
    for k in range(n):
        alive *= 1.0 - q(age + k); cum.append(1.0 - alive)
    return cum

P = premium(); P2 = bisect_premium()
A40, a40 = values(X, N, r); A50, a50 = values(X + T, N - T, r)
V_pro = S * A50 - P * a50
V = backward(P)
per, alive = cohort(P)
v = exp(-r)
# Road 4: simulate 1,000,000 lives aged 50 and average the office's future loss on each.
cum50 = death_table(X + T, N - T)
loss = [S * v ** (k + 1) - P * sum(v ** j for j in range(k + 1)) for k in range(N - T)]
tot = tot2 = 0.0
for _ in range(1000000):
    u = uniform()
    L = next((loss[k] for k in range(N - T) if u < cum50[k]), -P * a50)
    tot += L; tot2 += L * L
mc = tot / 1e6; se = sqrt((tot2 / 1e6 - mc * mc) / 1e6)
# One simulated office: 10,000 lives aged 40, one draw each, run for ten years.
cum40, died = death_table(X, T), [0] * T
for _ in range(10000):
    u = uniform()
    k = next((k for k in range(T) if u < cum40[k]), None)
    if k is not None: died[k] += 1
fund, l = 0.0, 10000
for t in range(T):
    fund = (fund + l * P) * exp(r) - died[t] * S; l -= died[t]
lhs = (V_pro + P) * exp(r); rhs = q(X + T) * S + (1.0 - q(X + T)) * V[T + 1]
# What breaks
A40f, a40f = values(X + T, N - T, r, freeze=X)
A50z, a50z = values(X + T, N - T, 0.0)
nat40 = v * q(X) * S
rows = [
    ("q(40), q(50), q(59)", f"{q(40):.7f} {q(50):.7f} {q(59):.7f}"),
    ("A 40:20 per $1, a-due 40:20", f"{A40:.6f} {a40:.6f}"),
    ("A 50:10 per $1, a-due 50:10", f"{A50:.6f} {a50:.6f}"),
    ("v = e^-r, S times A 40:20", f"{v:.6f} {S * A40:.6f}"), ("S times A 50:10", f"{S * A50:.6f}"),
    ("P times a-due 50:10", f"{P * a50:.6f}"),
    ("1 premium by the sums", f"{P:.6f}"), ("2 premium by bisection", f"{P2:.6f}"),
    ("1 reserve at 10, prospective", f"{V_pro:.6f}"), ("2 reserve at 10, backward recursion", f"{V[T]:.6f}"),
    ("3 reserve at 10, office fund per survivor", f"{per[T]:.6f}"),
    ("4 reserve at 10, simulated mean, std error", f"{mc:.6f} {se:.6f}"),
    ("size of reserve at 0 (recursion), at 20 (fund)", f"{abs(V[0]):.6f} {abs(per[N]):.6f}"),
    ("step 10->11: (V10+P)e^r, q S + p V11", f"{lhs:.6f} {rhs:.6f}"),
    ("office: survivors at 10, fund at 10", f"{alive[T]:.4f} {per[T] * alive[T]:.2f}"),
    ("simulated office: deaths by 10, fund per survivor", f"{sum(died)} {fund / l:.6f}"),
    ("expected deaths by 10", f"{10000 - alive[T]:.4f}"),
    ("largest reserve: year, value", f"{max(range(N + 1), key=lambda t: V[t])} {max(V):.6f}"),
]
for lab, val in rows: print(f"{lab:<50}{val}")
for a in range(0, N + 1, 7): print("reserve  t=%2d.." % a, " ".join(f"{V[t]:.2f}" for t in range(a, min(a + 7, N + 1))))
for a in range(0, N, 7): print("yr cost  t=%2d.." % a, " ".join(f"{v * q(X + t) * S:.2f}" for t in range(a, min(a + 7, N))))
brk = [("forgot the premium due at 10", V_pro + P), ("age-40 death rates at 50-59", S * A40f - P * a40f),
       ("no interest in the reserve", S * A50z - P * a50z),
       ("first year's cost as premium", nat40), ("  short at issue per policy", S * A40 - nat40 * a40)]
for lab, val in brk: print(f"break  {lab:<43}{val:.6f}")
P50 = premium(age=50); P0 = premium(rate=0.0)
tries = [("sum insured $200,000: premium, reserve", 2 * P, 2 * V_pro),
         ("issue age 50: premium, reserve", P50, backward(P50, age=50)[T]),
         ("rate 0%: premium, reserve", P0, backward(P0, rate=0.0)[T])]
for lab, a, b in tries: print(f"try    {lab:<43}{a:.6f} {b:.6f}")
assert abs(P - P2) < 1e-6                       # sums vs root finder on the recursion
assert abs(V_pro - V[T]) < 1e-6                 # prospective vs recursion
assert abs(V_pro - per[T]) < 1e-6               # prospective vs retrospective fund
assert abs(mc - V_pro) < 4 * se                 # simulation agrees within 4 standard errors
assert abs(lhs - rhs) < 1e-6                    # one step of the recursion, by hand
assert abs(V[0]) < 1e-6                         # equivalence: nothing owed at issue
print("All checks passed.")
