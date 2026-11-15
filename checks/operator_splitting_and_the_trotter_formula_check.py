# Operator splitting and the Trotter formula -- the check behind the card.  Standard library only.
# A 100 kg spill drifts and spreads for 1 h in a river reach whose speed rises downstream.
# Roads: step-by-step moment maps against closed-form sums and the leading-error formula;
# an N-cell grid whose exponentials are summed term by term; the commutator against 2 beta B.
import math

Q, C0, BETA, KAPPA, W0, T = 100.0, 0.5, 1e-4, 20.0, 200.0, 3600.0   # kg, m/s, 1/s, m^2/s, m, s

def close(a, b, tol):
    assert abs(a - b) <= tol * max(1.0, abs(b)), (a, b)
def drift(mu, v, dt):            # the flow x' = C0 + BETA x moves the centre and stretches the variance
    return (mu + C0 / BETA) * math.exp(BETA * dt) - C0 / BETA, v * math.exp(2 * BETA * dt)

def spread(mu, v, dt):           # spreading adds 2 kappa dt to the variance and leaves the centre
    return mu, v + 2 * KAPPA * dt

def run(n, order, t=T):          # "drift-spread": drift then spread; "spread-drift": spread then drift; "strang": half, full, half
    mu, v, dt = 0.0, W0 * W0, t / n
    for _ in range(n):
        if order == "drift-spread":
            mu, v = spread(*drift(mu, v, dt), dt)
        elif order == "spread-drift":
            mu, v = drift(*spread(mu, v, dt), dt)
        else:
            mu, v = drift(*spread(*drift(mu, v, dt / 2), dt), dt / 2)
    return mu, v

def phi(z):                      # normal CDF from the power series of erf
    s, term, k = 0.0, z / math.sqrt(2), 0
    while abs(term) > 1e-18:
        s, k = s + term / (2 * k + 1), k + 1
        term *= -z * z / 2 / k
    return 0.5 + s / math.sqrt(math.pi)

def l1_gap(va, vb):              # L1 distance of two plumes, same mass and centre: each misplaced kg counts twice
    sa, sb = math.sqrt(min(va, vb)), math.sqrt(max(va, vb))
    z = math.sqrt(2 * math.log(sb / sa) * sa * sa * sb * sb / (sb * sb - sa * sa))
    return 4 * Q * (phi(z / sa) - phi(z / sb))

load = lambda x, mu, v: Q / math.sqrt(2 * math.pi * v) * math.exp(-(x - mu) ** 2 / (2 * v))
# 1. The true flow in closed form: the centre follows the water, the variance obeys v' = 2 beta v + 2 kappa.
q = math.exp(2 * BETA * T)
mu_t, v_t = (C0 / BETA) * (math.exp(BETA * T) - 1), W0 * W0 * q + (KAPPA / BETA) * (q - 1)
print(f"true, e^(beta t) {math.exp(BETA * T):.6f}, e^(2 beta t) {q:.6f}, centre {mu_t:.2f} m, width {math.sqrt(v_t):.2f} m, peak {load(0, 0, v_t):.6f} kg/m")
(m1, v1), s600 = run(1, "drift-spread", 600.0), W0 * W0 * math.exp(1200 * BETA)
v600 = s600 + (KAPPA / BETA) * (math.exp(1200 * BETA) - 1)
print(f"first step, 600 s: c0/beta {C0 / BETA:.2f} m, kappa/beta {KAPPA / BETA:.2f} m^2, start variance {W0 * W0:.2f}, e^(beta dt) {math.exp(600 * BETA):.6f}, e^(2 beta dt) {math.exp(1200 * BETA):.6f}, centre {m1:.2f} m, stretched variance {s600:.2f}, spread adds {2 * KAPPA * 600:.2f}")
print(f"first step, 600 s: split variance {v1:.2f}, width {math.sqrt(v1):.2f}; true adds {v600 - s600:.2f}, true variance {v600:.2f}, width {math.sqrt(v600):.2f}")

# 2. Split steps: iterate the moment maps, compare with the closed-form sums.
print("split, n, step (s), scheme, width (m), peak (kg/m), width error (m), L1 gap (kg)")
for n in (1, 6, 60):
    dt = T / n
    r = math.exp(2 * BETA * dt)
    sums = {"drift-spread": 1.0, "spread-drift": r, "strang": math.exp(BETA * dt)}
    for order in ("drift-spread", "spread-drift", "strang"):
        mu, v = run(n, order)
        close(mu, mu_t, 1e-10)
        close(v, W0 * W0 * q + 2 * KAPPA * dt * sums[order] * (q - 1) / (r - 1), 1e-12)
        print(f"split, {n}, {dt:.0f}, {order}, {math.sqrt(v):.2f}, {load(0, 0, v):.6f}, "
              f"{math.sqrt(v) - math.sqrt(v_t):+.3f}, {l1_gap(v, v_t):.4f}")
for name, (mu, v) in (("true", (mu_t, v_t)), ("drift-spread n=1", run(1, "drift-spread")), ("spread-drift n=1", run(1, "spread-drift"))):
    print(f"profile, {name}, " + ", ".join(f"{load(x, mu, v):.4f}" for x in range(0, 4500, 500)))

# 3. Rates: drift-spread's variance error is about kappa dt (e^(2 beta t) - 1); Strang's falls like 1/n^2.
print("chart, log10 n, 0, 1, 2, 3")
for order in ("drift-spread", "strang"):
    e = [abs(run(n, order)[1] - v_t) for n in (1, 10, 100, 1000)]
    print(f"chart, log10 variance error {order} (m^2), " + ", ".join(f"{math.log10(x):.3f}" for x in e))
    close(math.log10(e[3] / e[2]), -1.0 if order == "drift-spread" else -2.0, 0.01)
    dt = T / 1000
    lead = KAPPA * dt * (q - 1) if order == "drift-spread" else KAPPA * BETA * dt * dt * (q - 1) / 6
    assert abs(e[3] / lead - 1) < 2e-3, (e[3], lead)
    print(f"rate, {order}, n = 1000: variance error {e[3]:.6f} m^2, leading-term formula {lead:.6f} m^2")

# 4. The finite rehearsal: N cells on [-1500, 5500] m, load held at 0 beyond the ends.
#    A_N: drift, central fluxes c (u_i + u_i+1)/2.  B_N: spread, kappa (u_i+1 - 2 u_i + u_i-1)/h^2.
def grid(N):
    h = 7000.0 / N
    cf = [C0 + BETA * (-1500 + i * h) for i in range(N + 1)]
    def A(u):
        p = [0.0] + u + [0.0]
        fl = [cf[i] * (p[i] + p[i + 1]) / 2 for i in range(N + 1)]
        return [-(fl[i + 1] - fl[i]) / h for i in range(N)]
    def B(u):
        p = [0.0] + u + [0.0]
        return [KAPPA * (p[i + 2] - 2 * p[i + 1] + p[i]) / (h * h) for i in range(N)]
    return h, A, B, [load(-1500 + (i + 0.5) * h, 0, W0 * W0) for i in range(N)]

def expv(op, size, tau, u):      # e^(tau op) u: Taylor series on m substeps with tau * size / m <= 0.5
    m = max(1, math.ceil(tau * size / 0.5))
    for _ in range(m):
        term, s, k = u, u[:], 0
        while k < 30 and max(abs(x) for x in term) > 1e-17 * max(abs(x) for x in s):
            k += 1
            term = [x * tau / m / k for x in op(term)]
            s = [a + b for a, b in zip(s, term)]
        u = s
    return u
print("grid, N, h (m), mass (kg), L1 gap (kg) at n = 6: drift-spread, strang; continuum: drift-spread, strang")
cont, errs = [l1_gap(run(6, o)[1], v_t) for o in ("drift-spread", "strang")], {}
for N in (35, 70, 140, 280):
    h, A, B, u0 = grid(N)
    sa, sb = 2 * (C0 + BETA * 5500) / h, 4 * KAPPA / h / h
    true = expv(lambda u: [a + b for a, b in zip(A(u), B(u))], sa + sb, T, u0)
    lie, st = u0, u0
    for _ in range(6):
        lie = expv(B, sb, 600.0, expv(A, sa, 600.0, lie))
        st = expv(A, sa, 300.0, expv(B, sb, 600.0, expv(A, sa, 300.0, st)))
    el, es = (h * sum(abs(a - b) for a, b in zip(w, true)) for w in (lie, st))
    close(el, cont[0], 0.05 * (70 / N) ** 2)        # the grid's own error falls like h^2
    errs[N] = el
    print(f"grid, {N}, {h:.0f}, {h * sum(true):.4f}, {el:.4f}, {es:.4f}; {cont[0]:.4f}, {cont[1]:.4f}")

# 5. The commutator [A_N, B_N] = A_N B_N - B_N A_N: near 2 beta B_N on the plume, yet its norm has no ceiling.
print("commutator, N, h (m), L1 norm (1/s^2), largest column away from the ends, times h^2, gap to 2 beta B_N on the plume")
for N in (35, 70, 140, 280, 560):
    h, A, B, u0 = grid(N)
    cols = [sum(abs(a - b) for a, b in zip(A(B(e)), B(A(e)))) for e in ([float(i == j) for i in range(N)] for j in range(N))]
    inner = max(cols[3:N - 3])
    close(inner * h * h, 2 * BETA * KAPPA, 1e-9)
    cu, pred = [a - b for a, b in zip(A(B(u0)), B(A(u0)))], [2 * BETA * x for x in B(u0)]
    gap = sum(abs(a - b) for a, b in zip(cu, pred)) / sum(abs(x) for x in pred)
    print(f"commutator, {N}, {h:.1f}, {max(cols):.4e}, {inner:.4e}, {inner * h * h:.6f}, {gap:.6f}")
    if N == 140:
        bound = T * T / 12 * max(cols) * Q
assert gap < 0.01 and bound > 100 * errs[140]
print(f"bound, N = 140, n = 6: t^2/(2n) x norm x 100 kg = {bound:.1f} kg; actual {errs[140]:.4f} kg")

# 6. What breaks.  Backward spreading is not a generator: its top grid mode grows without limit as h shrinks.
print("backward, N, growth of the top grid mode in one 600 s step, closed form")
for N in (35, 70, 140):
    h, A, B, u0 = grid(N)
    v = [math.sin(N * math.pi * (i + 1) / (N + 1)) for i in range(N)]
    w = expv(lambda u: [-x for x in B(u)], 4 * KAPPA / h / h, 600.0, v)
    g = sum(abs(x) for x in w) / sum(abs(x) for x in v)
    f = math.exp(600 * 4 * KAPPA * math.cos(math.pi / (2 * N + 2)) ** 2 / h / h)
    close(g, f, 1e-9 * f)
    print(f"backward, {N}, {g:.6e}, {f:.6e}")
print("ALL CHECKS PASS")
