# The September 2026 Navier-Stokes claim: which Clay version it addresses, and the
# scalings of its collapsing vortex core, on a model swirl with the same scalings.
# Standard library only.  Units are normalised: viscosity nu = 1, blow-up at t = 1.
from math import exp, log, sqrt, pi

DELTA = 1 / 200            # the papers' parameter: 0 < delta < 1/200; the edge value, for illustration
NU = 1.0
TAUS = (1e-2, 1e-4, 1e-6)  # tau = 1 - t, the time left before the blow-up

def scales(tau, d):        # speed, core radius and core height of the model
    return tau ** (-(1 + d) / 2), tau ** 0.5, tau ** ((1 - d) / 2)

def swirl(r, z, tau, d):   # model swirl speed: A * F(r/a) * G(z/b), F(s) = s e^(-s^2), G = e^(-z^2)
    A, a, b = scales(tau, d)
    s = r / a
    return A * s * exp(-s * s) * exp(-(z / b) ** 2)

def energy_numeric(tau, d, n=400):     # road 1: Simpson's rule over r and z
    A, a, b = scales(tau, d)
    R, Z = 8 * a, 8 * b
    hr, hz = R / n, 2 * Z / n
    w = [1 if i in (0, n) else (4 if i % 2 else 2) for i in range(n + 1)]
    total = 0.0
    for i in range(n + 1):
        r = i * hr
        row = 0.0
        for j in range(n + 1):
            u = swirl(r, -Z + j * hz, tau, d)
            row += w[j] * u * u
        total += w[i] * row * 2 * pi * r
    return 0.5 * total * hr * hz / 9

def energy_closed(tau, d):             # road 2: by hand, (pi/4) sqrt(pi/2) times the scales
    return 0.5 * tau ** ((1 - 3 * d) / 2) * (pi / 4) * sqrt(pi / 2)

def peak_grid(tau, d, n=20000):        # road 1: search r on a grid at z = 0
    A, a, b = scales(tau, d)
    return max(swirl(8 * a * i / n, 0.0, tau, d) for i in range(n + 1))

def peak_closed(tau, d):               # road 2: F peaks at s = 1/sqrt 2
    return scales(tau, d)[0] * exp(-0.5) / sqrt(2)

def residual_fd(tau, d):               # road 1: force needed = time change - friction, by differences
    A, a, b = scales(tau, d)
    r, ht, hr, hz = a / sqrt(2), tau * 1e-4, a * 1e-3, b * 1e-3
    u = lambda rr, zz, tt: swirl(rr, zz, tt, d)
    dt = -(u(r, 0, tau + ht) - u(r, 0, tau - ht)) / (2 * ht)        # t = 1 - tau
    urr = (u(r + hr, 0, tau) - 2 * u(r, 0, tau) + u(r - hr, 0, tau)) / hr ** 2
    ur = (u(r + hr, 0, tau) - u(r - hr, 0, tau)) / (2 * hr)
    uzz = (u(r, hz, tau) - 2 * u(r, 0, tau) + u(r, -hz, tau)) / hz ** 2
    return dt - NU * (urr + ur / r - u(r, 0, tau) / r ** 2 + uzz)

def residual_closed(tau, d):           # road 2: the same force worked out by hand
    c = exp(-0.5)
    return (c * (1 + d) / (2 * sqrt(2)) * tau ** (-(3 + d) / 2)
            + NU * (3 * sqrt(2) * c * tau ** (-(3 + d) / 2) + sqrt(2) * c * tau ** (-(3 - d) / 2)))

print("ledger,1934,Leray: a blow-up is never slower than c sqrt(nu/(T - t))")
print("ledger,2000,Clay names seven prize problems, 1,000,000 US dollars each")
print("ledger,2026-09-08,announced by an AI lab: manuscript (166 pages) and Lean files")
print("ledger,2026-09-28,first exposition on arXiv (Part I)")
print("ledger,2026-10-06,critique on arXiv: Lean uses m+5 derivatives where the paper uses m+4")
print("ledger,2026-11-04,second exposition on arXiv (Part II)")
print("ledger,2026-11-23,Clay page lists the problem as 'Active'; status: claimed")
# Which version the claim addresses is read from Clay's statement and Part II, Theorem 1.1.
# No program can compute it, so these rows are a typed record and nothing is asserted about them.
no = "not addressed: needs f = 0, claim uses a force"
versions = [("A", "R3", "zero", "smooth forever", no), ("B", "torus", "zero", "smooth forever", no),
            ("C", "R3", "allowed", "breakdown", "addressed: Part II, Theorem 1.1, all of space"),
            ("D", "torus", "allowed", "breakdown", "addressed: from C by rescaling and copying")]
for name, space, force, asks, why in versions:
    print(f"version {name}: {space:<5} force {force:<7} asks {asks:<14} -> {why}")

print("tau      energy(Simpson)   energy(by hand)   peak(grid)     peak(by hand)  Reynolds  speed*sqrt(tau)")
E = {}
for tau in TAUS:
    en, ec = energy_numeric(tau, DELTA), energy_closed(tau, DELTA)
    pg, pc = peak_grid(tau, DELTA), peak_closed(tau, DELTA)
    assert abs(en - ec) < 1e-7 * ec and abs(pg - pc) < 1e-7 * pc
    re, ler = pc * (sqrt(tau) / sqrt(2)) / NU, pc * sqrt(tau / NU)
    E[tau] = en
    print(f"{tau:.0e}  {en:.10f}  {ec:.10f}  {pg:.6e}  {pc:.6e}  {re:.4f}    {ler:.4f}")
slope = log(E[1e-6] / E[1e-2]) / log(1e-6 / 1e-2)
assert abs(slope - (1 - 3 * DELTA) / 2) < 1e-9
print(f"energy exponent fitted {slope:.6f}, by hand (1 - 3 delta)/2 = {(1 - 3 * DELTA) / 2:.6f}")
for tau in TAUS:
    fd, fc = residual_fd(tau, DELTA), residual_closed(tau, DELTA)
    assert abs(fd - fc) < 1e-5 * fc
    print(f"swirl component of the force a naive swirl needs at tau {tau:.0e}: {fd:.4e} (by hand {fc:.4e})")
print(f"Leray floor factor tau^(-delta/2) at 1e-6: {1e-6 ** (-DELTA / 2):.4f}")

# what breaks
print(f"break: speed ~ tau^-0.4, ratio to Leray floor at 1e-6: {1e-6 ** 0.1:.4f} (must stay above a constant)")
print(f"break: delta = 0.4, energy factor at 1e-6: {1e-6 ** ((1 - 3 * 0.4) / 2):.4f} (energy grows)")
assert energy_closed(1e-6, 0.4) > energy_closed(1e-2, 0.4) > energy_closed(1.0, 0.4)
# try changing
print(f"try: delta = 0, Reynolds at 1e-2 and 1e-12: {peak_closed(1e-2, 0) * sqrt(1e-2 / 2):.4f} {peak_closed(1e-12, 0) * sqrt(1e-12 / 2):.4f}")
print(f"try: delta = 1/3, energy at 1e-2 and 1e-12: {energy_closed(1e-2, 1 / 3):.6f} {energy_closed(1e-12, 1 / 3):.6f}")
print(f"try: tau = 1e-12, speed*sqrt(tau): {peak_closed(1e-12, DELTA) * sqrt(1e-12):.4f}")
print(f"try: tau = 1e-12, swirl component of the naive force: {residual_closed(1e-12, DELTA):.4e}")
print("ALL CHECKS PASS")
