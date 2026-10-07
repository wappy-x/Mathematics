# Continuity -- the check behind the card.  Standard library only.  Two roads
# each time: a simulated meter against the fare formula, and a brute-force
# search for the widest safe window against the recipe the proofs give.
import math

def S(d): return 3 + 2 * math.ceil(d)                # stepped fare, by formula
def M(d): return 3 + 2 * d                            # metered fare
def meter(d):                                         # stepped fare, by driving
    fare = 3                                          # $3 at the kerb, then metre by metre
    for m in range(1, round(d * 1000) + 1):
        if m % 1000 == 1: fare += 2                   # a new kilometre starts
    return fare
def widest(f, a, tol):                                # widest window around a
    ok = lambda w: all(abs(f(a + s * w * k / 200) - f(a)) < tol   # that keeps
                       for k in range(1, 201) for s in (-1, 1))   # f within tol
    lo, hi = 0.0, 1.0
    for _ in range(60):                                # bisection on the width
        mid = (lo + hi) / 2; lo, hi = (mid, hi) if ok(mid) else (lo, mid)
    return lo
DS = [0, 0.4, 1, 1.001, 2, 2.5, 3.2]
print("setup: $3 at the kerb, $2 per km (started, or metered); cab 0.5 km a minute; "
      "waiting 0.25 a minute; surge 1 + 0.05 t")
for name, f in (("formula", S), ("driving", meter)):
    print(f"stepped fare by {name} at 0, 0.4, 1, 1.001, 2, 2.5, 3.2 km:", ", ".join(str(f(d)) for d in DS))
for a in (1, 2):
    print(f"at {a} km: from the left {S(a - 1e-9):.2f}, value {S(a):.2f}, "
          f"from the right {S(a + 1e-9):.2f}, jump {S(a + 1e-9) - S(a - 1e-9):.2f}")
print("stepped fare at 1.1, 1.01, 1.001 km:", ", ".join(str(S(1 + h)) for h in (0.1, 0.01, 0.001)))
blank = lambda d: 0 if d == 2 else M(d)               # a meter that blanks at 2 km
print(f"blanking meter at 2 km: from the left {blank(2 - 1e-9):.2f}, value {blank(2):.2f}, "
      f"from the right {blank(2 + 1e-9):.2f}")
print("metered price per km at 0.1, 0.01, 0.001 km:", ", ".join(f"{M(h) / h:.2f}" for h in (0.1, 0.01, 0.001)))
w_m, w_s = widest(M, 2, 0.01), widest(S, 1, 1)
print(f"metered fare at 2 km, within $0.01: recipe {0.01 / 2:.6f} km, widest {w_m:.6f} km")
print(f"stepped fare at 1 km, within $1: some window works: {'yes' if w_s > 1e-12 else 'no'}; "
      f"fare at 1.000000001 km is {S(1.000000001)}")
fare_t = lambda t: M(0.5 * t)                         # the cab covers 0.5 km a minute
total, surge = (lambda t: fare_t(t) + 0.25 * t), (lambda t: 1 + 0.05 * t)   # waiting; surge
prod = lambda t: fare_t(t) * surge(t)
eta = 0.01 / (fare_t(4) + surge(4) + 1)               # the product proof's recipe
q = lambda c: (-1.15 + math.sqrt(1.15 ** 2 - 0.2 * (3 - c))) / 0.1   # 0.05t^2 + 1.15t + 3 = c
w_q = min(q(8.41) - 4, 4 - q(8.39))                   # the exact widest window
rows = [("composition 3 + t", fare_t, 0.01 / 2 / 0.5), ("sum 3 + 1.25 t", total, min(0.005, 0.005 / 0.25)),
        ("product (3 + t)(1 + 0.05 t)", prod, min(eta, eta / 0.05))]
print(f"sum recipe: fare within $0.005 needs {0.005:.6f} min, waiting within $0.005 needs {0.005 / 0.25:.6f} min")
print(f"product recipe: 0.01 / ({fare_t(4):.2f} + {surge(4):.2f} + 1) = {eta:.6f} min; "
      f"whole tolerance to each part instead: {min(0.01, 0.01 / 0.05):.6f} min")
wide = [widest(f, 4, 0.01) for _, f, _ in rows]
for (name, f, rec), w in zip(rows, wide):
    print(f"{name} at 4 min = {f(4):.2f}; recipe {rec:.6f} min, widest {w:.6f} min")
print(f"product widest window by the quadratic formula: {w_q:.6f} min")
print(f"stepped fare over time at 4 min: {S(0.5 * 4)}, a moment later {S(0.5 * 4.000001)}")
X, Y = (lambda d: 40 + 80 * d), (lambda f: 210 - 16 * f)
print(f"figure, 80 px per km, 16 px per dollar; step tops at y = {', '.join(f'{Y(S(k)):.0f}' for k in (1, 2, 3, 4))}; "
      f"meter line ({X(0):.0f}, {Y(M(0)):.0f}) to ({X(3.5):.0f}, {Y(M(3.5)):.0f})")
assert [meter(d) for d in DS] == [S(d) for d in DS]                 # driving = formula
assert abs(w_m - 0.01 / 2) < 1e-9 and w_s < 1e-12                   # continuous vs jump
assert all(rec <= w + 1e-12 for (_, _, rec), w in zip(rows, wide))  # recipes are safe
assert abs(wide[2] - w_q) < 1e-9                                    # two roads agree
print("ALL CHECKS PASS")
