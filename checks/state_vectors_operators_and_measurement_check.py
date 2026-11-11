# States as vectors -- the check behind the card.  Standard library only.
# A photon polarised at 30 degrees meets a polariser whose axis is at 45 degrees.
# Roads to the pass probability: (1) eigenvectors of the Hermitian matrix, found
# by the 2x2 quadratic written out, then the Born rule; (2) the expected value
# psi* A psi against the eigenvalue average; (3) Malus's law from the angles
# alone; (4) photons simulated one at a time with a seeded generator.
from math import cos, sin, sqrt, pi, radians

def dot(u, v):  # conjugate the first vector, multiply matching entries, add
    return sum(a.conjugate() * b for a, b in zip(u, v))

def apply(A, v):
    return [A[0][0] * v[0] + A[0][1] * v[1], A[1][0] * v[0] + A[1][1] * v[1]]

def polariser(alpha):  # reading +1 along the axis at angle alpha, -1 across it
    c, s = round(cos(2 * alpha), 12) + 0.0, round(sin(2 * alpha), 12) + 0.0  # 0, not -6e-17
    return [[complex(c), complex(s)], [complex(s), complex(0.0 - c)]]

def eigen(A):  # 2x2 Hermitian [[a, b], [conj b, d]]: the quadratic, written out
    a, b, d = A[0][0].real, A[0][1], A[1][1].real
    r = sqrt(((a - d) / 2) ** 2 + abs(b) ** 2)
    out = []
    for lam in ((a + d) / 2 + r, (a + d) / 2 - r):
        if abs(b) > 1e-12:
            v = [b, complex(lam - a)]
        else:
            v = [1j * 0 + 1, 0j] if abs(lam - a) < 1e-12 else [0j, 1j * 0 + 1]
        n = sqrt(dot(v, v).real)
        out.append((lam, [x / n for x in v]))
    return out

def measure(A, psi):  # Born rule: (reading, probability, state afterwards)
    return [(lam, abs(dot(u, psi)) ** 2, u) for lam, u in eigen(A)]

def splitmix(seed):  # SplitMix64, so Python and Rust draw the same numbers
    M = (1 << 64) - 1
    while True:
        seed = (seed + 0x9E3779B97F4A7C15) & M
        z = seed
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M
        yield ((z ^ (z >> 31)) >> 11) / 2.0 ** 53

def sim(psi, alphas, n, rng):  # photons pass a chain of polarisers, or are stopped
    passed = 0
    for _ in range(n):
        state = psi
        for al in alphas:
            (lp, pp, up), _ = measure(polariser(al), state)
            if next(rng) >= pp:
                break
            state = up  # a photon that got through now carries the axis's state
        else:
            passed += 1
    return passed

th, al = radians(30), radians(45)
psi = [complex(cos(th)), complex(sin(th))]
A = polariser(al)
(lp, pp, up), (lm, pm, um) = measure(A, psi)
print(f"state psi at 30 deg: ({psi[0].real:.4f}, {psi[1].real:.4f}), length squared {dot(psi, psi).real:.4f}")
print("polariser at 45 deg: A = [[%.4f, %.4f], [%.4f, %.4f]]" % tuple(A[i][j].real for i in (0, 1) for j in (0, 1)))
for lam, u in ((lp, up), (lm, um)):
    Au = apply(A, u)
    assert max(abs(Au[k] - lam * u[k]) for k in (0, 1)) < 1e-12  # it really is an eigenvector
    print(f"eigenvalue {lam:+.4f}, eigenvector ({u[0].real:.4f}, {u[1].real:.4f})")
print(f"amplitudes: pass port {dot(up, psi).real:.4f}, blocked port {dot(um, psi).real:.4f}")
print(f"P(pass) {pp:.4f}, P(blocked) {pm:.4f}, sum {pp + pm:.4f}")
assert abs(pp + pm - 1) < 1e-12
ev_sandwich, ev_average = dot(psi, apply(A, psi)).real, lp * pp + lm * pm
malus = cos(al - th) ** 2
print(f"expected value: psi* A psi {ev_sandwich:.4f}, sum of reading x chance {ev_average:.4f}")
print(f"Malus's law from the angles: cos^2(15 deg) {malus:.4f}")
assert abs(ev_sandwich - ev_average) < 1e-12 and abs(pp - malus) < 1e-12
rate = 1_000_000
print(f"of {rate} photons a second: pass {round(rate * pp)}, blocked {round(rate * pm)}, spread {sqrt(rate * pp * pm):.0f}")
n = 100_000
k = sim(psi, [al], n, splitmix(2026))
se = sqrt(pp * (1 - pp) / n)
print(f"simulated {n} photons: {k} passed, fraction {k / n:.4f}, 4 standard errors {4 * se:.4f}")
assert abs(k / n - pp) < 4 * se
h, c, e = 6.62607015e-34, 299792458.0, 1.602176634e-19  # exact SI values (CODATA)
hbar, lam_m, power = h / (2 * pi), 633e-9, 1e-3
omega = 2 * pi * c / lam_m
E = hbar * omega
print(f"hbar {hbar * 1e34:.6f}e-34 J s; 633 nm light: omega {omega / 1e15:.4f}e15 rad/s, photon energy {E * 1e19:.4f}e-19 J = {E / e:.4f} eV")
flux = power / E
print(f"1.000 mW beam = {flux / 1e15:.4f}e15 photons/s; through the polariser {flux * pp * E * 1e3:.4f} mW")
assert abs(flux * pp * E - power * malus) < 1e-15 and abs(E - h * c / lam_m) < 1e-30
psic = [complex(cos(th)), 1j * sin(th)]
pH = measure(polariser(0.0), psic)[0][1]
(_, pc, _), _ = measure(A, psic)
evc = dot(psic, apply(A, psic))
print(f"complex state (0.8660, 0.5000i): P(H) {pH:.4f}; at 45 deg P(pass) {pc:.4f}, expected value {evc.real:.4f}")
assert abs(pH - cos(th) ** 2) < 1e-12 and abs(pc - (cos(th) * cos(al)) ** 2 - (sin(th) * sin(al)) ** 2) < 1e-12
assert abs(evc - cos(2 * th) * cos(2 * al)) < 1e-12  # elliptical light: cos 2theta cos 2alpha, real
pcirc = [measure(polariser(radians(a)), [complex(sqrt(0.5)), 1j * sqrt(0.5)])[0][1] for a in range(0, 180, 5)]
assert all(abs(p - 0.5) < 1e-12 for p in pcirc)  # circular light: one half at every axis, like unpolarised light
print(f"circular state (0.7071, 0.7071i): P(pass) {min(pcirc):.4f} to {max(pcirc):.4f} at every axis, 0 to 175 deg")
# what breaks
print(f"breaks, amplitude not squared: {dot(up, psi).real:.4f}, two 'chances' sum {dot(up, psi).real + dot(um, psi).real:.4f}")
raw = [complex(sqrt(3)), complex(1)]
print(f"breaks, state (1.7321, 1) not normalised: P(pass) {abs(dot(up, raw)) ** 2:.4f}")
noconj = psic[0] * (A[0][0] * psic[0] + A[0][1] * psic[1]) + psic[1] * (A[1][0] * psic[0] + A[1][1] * psic[1])
print(f"breaks, no conjugate on the complex state: 'expected value' {noconj.real:.4f} + {noconj.imag:.4f}i")
print(f"breaks, alpha in place of 2 alpha: P(pass) {measure(polariser(al / 2), psi)[0][1]:.4f}")
print(f"breaks, phase i dropped: P(pass) {abs(dot(up, [psic[0], complex(abs(psic[1]))])) ** 2:.4f} instead of {pc:.4f}")
N = [[1 + 0j, 2 + 0j], [0j, -1 + 0j]]  # not Hermitian, readings still +1 and -1
vecs = [[1 + 0j, 0j], [complex(1 / sqrt(2)), complex(-1 / sqrt(2))]]
for lam, v in zip((1, -1), vecs):
    Nv = apply(N, v)
    assert max(abs(Nv[k] - lam * v[k]) for k in (0, 1)) < 1e-12
fake = sum(abs(dot(v, psi)) ** 2 for v in vecs)
fev = dot(psi, apply(N, psi)).real
print(f"breaks, non-Hermitian [[1, 2], [0, -1]]: 'chances' sum {fake:.4f}, 'expected value' {fev:.4f}")
assert abs(fake - 1) > 0.1 and fev > 1
# a chain of polarisers: 30 deg photon, then 45 deg, then 120 deg
direct = measure(polariser(radians(120)), psi)[0][1]
two = pp * measure(polariser(radians(120)), up)[0][1]
print(f"chain: straight to 120 deg {direct:.4f}; via 45 deg {pp:.4f} x {two / pp:.4f} = {two:.4f}")
assert abs(two - (cos(al - th) * cos(radians(120) - al)) ** 2) < 1e-12
k2 = sim(psi, [al, radians(120)], n, splitmix(7))
print(f"chain simulated {n} photons: {k2} passed, fraction {k2 / n:.4f}, 4 standard errors {4 * sqrt(two * (1 - two) / n):.4f}")
assert abs(k2 / n - two) < 4 * sqrt(two * (1 - two) / n)
mids = range(30, 121, 15)
bars = [measure(polariser(radians(m)), psi)[0][1] * measure(polariser(radians(120)), measure(polariser(radians(m)), psi)[0][2])[0][1] for m in mids]
print("bars, middle axis deg : fraction through all three  " + "  ".join(f"{m}:{b:.4f}" for m, b in zip(mids, bars)))
angles = range(0, 181, 15)
print("chart, axis deg      " + " ".join(f"{a:5d}" for a in angles))
print("chart, linear 30 deg " + " ".join(f"{measure(polariser(radians(a)), psi)[0][1]:5.3f}" for a in angles))
print("chart, complex state " + " ".join(f"{measure(polariser(radians(a)), psic)[0][1]:5.3f}" for a in angles))
S, ox, oy = 160, 150, 210  # figure: 160 px per unit, origin of the plane
pts = [("psi", psi[0].real, psi[1].real), ("pass", *(dot(up, psi).real * x.real for x in up)),
       ("blocked", *(dot(um, psi).real * x.real for x in um))]
print("figure, px " + "  ".join(f"{nm}:({ox + S * x:.1f}, {oy - S * y:.1f})" for nm, x, y in pts))
psi40, m75, k1 = [complex(cos(radians(40))), complex(sin(radians(40)))], measure(polariser(radians(75)), psi), sim(psi, [al], n, splitmix(1))
print(f"try: photon at 40 deg P(pass) {measure(A, psi40)[0][1]:.4f}, simulated {sim(psi40, [al], n, splitmix(2026))} passed")
print(f"try: splitter at 75 deg P(pass) {m75[0][1]:.4f}, P(blocked) {m75[1][1]:.4f}, beam {flux * m75[0][1] * E * 1e3:.4f} mW")
print(f"try: n = 1000, {sim(psi, [al], 1000, splitmix(2026))} passed, 4 standard errors {4 * sqrt(pp * pm / 1000):.4f}; seed 1, {k1} passed, fraction {k1 / n:.4f}")
print("ALL CHECKS PASS")
