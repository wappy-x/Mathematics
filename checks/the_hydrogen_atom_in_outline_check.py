# Hydrogen in outline -- the check behind the card.  Standard library only.
# One electron, one proton, the Coulomb pull.  Three roads to the levels:
# 1 the closed form from SI constants, 2 the radial power series that must
# stop, 3 a shooting solve of the radial equation itself (Numerov, bisection).
import math

H = 6.62607015e-34          # Planck constant, J s (exact in SI)
Q = 1.602176634e-19         # elementary charge, C (exact); also 1 eV in J
C = 299792458.0             # speed of light, m/s (exact)
EPS0 = 8.8541878188e-12     # electric constant, F/m (CODATA 2022)
ME = 9.1093837139e-31       # electron mass, kg (CODATA 2022)
MP = 1.67262192595e-27      # proton mass, kg (CODATA 2022)
MD = 3.3435837768e-27       # deuteron mass, kg (CODATA 2022)
ALPHA = 7.2973525643e-3     # fine-structure constant (CODATA 2022)
RYD_CODATA = 13.605693122990  # R_inf h c in eV, electron mass (CODATA 2022)
IE_NIST = 13.598434599702   # measured ionization energy of H, eV (NIST ASD)
A0_CODATA = 0.0529177210544 # Bohr radius in nm, electron mass (CODATA 2022)
HA_NIST = (656.460, 656.279)  # H-alpha, observed blend, vacuum and air, nm (NIST ASD)

def ryd(m):                 # road 1: |E_1| = m e^4 / (8 eps0^2 h^2), in eV
    return m * Q ** 4 / (8 * EPS0 * EPS0 * H * H) / Q
def bohr(m):                # 4 pi eps0 hbar^2 / (m e^2), in nm
    return 4 * math.pi * EPS0 * (H / (2 * math.pi)) ** 2 / (m * Q * Q) * 1e9
def reduced(M):             # reduced mass of an electron and a nucleus of mass M
    return ME * M / (ME + M)
def lam(E1, hi, lo):        # wavelength in nm of the light from the jump hi -> lo
    return H * C / (E1 * (1 / (lo * lo) - 1 / (hi * hi)) * Q) * 1e9
def series(nu, l, terms=200):  # road 2: R = r^l e^(-r/nu) (c0 + c1 r + ...), r in Bohr radii
    c = [1.0]
    for k in range(terms):
        c.append(c[-1] * 2 * (k + l + 1 - nu) / (nu * (k + 1) * (k + 2 * l + 2)))
    return c
def R_series(nu, l, r, terms=200):  # the same series summed term by term
    total, t = 0.0, 1.0
    for k in range(terms):
        total += t
        t *= 2 * (k + l + 1 - nu) / (nu * (k + 1) * (k + 2 * l + 2)) * r
    return r ** l * math.exp(-r / nu) * total

def shoot(En, l, rmax=50.0, h=0.01):  # road 3: u = r R, u'' = (l(l+1)/r^2 - 2/r - 2E) u
    w, ll = h * h / 12, l * (l + 1)
    r0, r1 = h, 2 * h
    a = -1 / (l + 1); b = (-2 * a - 2 * En) / (4 * l + 6)   # u = r^(l+1) (1 + a r + b r^2) near 0
    u0, u1 = r0 ** (l + 1) * (1 + a * r0 + b * r0 * r0), r1 ** (l + 1) * (1 + a * r1 + b * r1 * r1)
    f0, f1 = ll / (r0 * r0) - 2 / r0 - 2 * En, ll / (r1 * r1) - 2 / r1 - 2 * En
    for i in range(2, int(round(rmax / h))):
        r2 = (i + 1) * h
        f2 = ll / (r2 * r2) - 2 / r2 - 2 * En
        u2 = (2 * u1 * (1 + 5 * w * f1) - u0 * (1 - w * f0)) / (1 - w * f2)
        u0, u1, f0, f1 = u1, u2, f1, f2
    return u1
def levels(l, lo=-0.6, hi=-0.04, step=0.01):  # scan for sign changes, then bisect
    out, E, prev = [], lo, shoot(lo, l)
    while E + step <= hi + 1e-12:
        nxt = shoot(E + step, l)
        if (prev < 0) != (nxt < 0):
            a, b, fa = E, E + step, prev
            for _ in range(45):
                m = (a + b) / 2
                fm = shoot(m, l)
                if (fm < 0) == (fa < 0): a, fa = m, fm
                else: b = m
            out.append((a + b) / 2)
        E, prev = E + step, nxt
    return out
def simpson(f, a, b, n=2000):
    h = (b - a) / n
    return (f(a) + f(b) + sum((4 if i % 2 else 2) * f(a + i * h) for i in range(1, n))) * h / 3

mu = reduced(MP)
E1e, E1 = ryd(ME), ryd(mu)
a0 = bohr(mu)               # Bohr radius with the reduced mass, nm
En = [-E1 / (n * n) for n in range(1, 6)]
print("constants: m_e 9.1093837139e-31 kg, m_p 1.67262192595e-27 kg, eps0 8.8541878188e-12 F/m")
print("reduced mass mu / m_e                %.8f" % (mu / ME))
print("hc                                   %.6f eV nm" % (H * C / Q * 1e9))
print("|E_1| electron mass, from constants  %.6f eV" % E1e)
print("|E_1| electron mass, CODATA R_inf hc %.6f eV" % RYD_CODATA)
print("|E_1| reduced mass                   %.6f eV" % E1)
print("levels n = 1..5 (eV)  " + " ".join("%.6f" % e for e in En))
print("bars |E_n| (eV)       " + " ".join("%.2f" % -e for e in En))
print("Bohr radius a0 with mu               %.6f nm" % a0)
print("Bohr radius with m_e                 %.6f nm (CODATA %.6f nm)" % (bohr(ME), A0_CODATA))
print("H-alpha 3->2: energy %.6f eV, wavelength %.3f nm" % (E1 * (1 / 4 - 1 / 9), lam(E1, 3, 2)))
print("H-beta 4->2 %.2f nm, Lyman-alpha 2->1 %.2f nm, Balmer limit %.2f nm"
      % (lam(E1, 4, 2), lam(E1, 2, 1), lam(E1, 1e9, 2)))
print("measured ionization energy %.6f eV, outline misses by %.6f eV" % (IE_NIST, IE_NIST - E1))
print("H-alpha measured %.3f nm vacuum, %.3f nm air; outline is %.3f nm long" % (HA_NIST + (lam(E1, 3, 2) - HA_NIST[0],)))
for nu, l in ((2, 0), (3, 0), (3, 1)):
    print("series nu=%d l=%d: " % (nu, l) + " ".join("%.6f" % (x + 0.0) for x in series(nu, l)[:4]))
print("log10 |R(40 a0)|: nu = 2.00 gives %.2f, nu = 2.50 gives %.2f"
      % (math.log10(abs(R_series(2.0, 0, 40.0))), math.log10(abs(R_series(2.5, 0, 40.0)))))
shot = {l: levels(l) for l in (0, 1, 2)}
for l in (0, 1, 2):
    print("shooting l=%d (eV): " % l + " ".join("%.6f" % (2 * E1 * e) for e in shot[l]))
count = [sum(1 for l in range(n) for m in range(-l, l + 1)) for n in range(1, 5)]
print("states per shell n = 1..4: " + " ".join(str(c) for c in count) +
      "; with spin " + " ".join(str(2 * c) for c in count))
P1s = lambda r: r * r * R_series(1.0, 0, r) ** 2
N1 = simpson(P1s, 0.0, 40.0)
r_mean = simpson(lambda r: r * P1s(r), 0.0, 40.0) / N1
print("1s: normalising constant squared %.6f, mean radius %.6f a0" % (1 / N1, r_mean))
norm = {(n, l): simpson(lambda r: r * r * R_series(n, l, r) ** 2, 0.0, 80.0) for n, l in ((1, 0), (2, 0), (2, 1))}
overlap = simpson(lambda r: r * r * R_series(1, 0, r) * R_series(2, 0, r), 0.0, 80.0)
print("1s-2s overlap (should be 0)          %.6f" % (overlap / math.sqrt(norm[(1, 0)] * norm[(2, 0)])))
print("chart r (a0)  " + " ".join("%5d" % r for r in range(15)))
for n, l, name in ((1, 0, "1s"), (2, 0, "2s"), (2, 1, "2p")):
    vals = [r * r * R_series(n, l, r) ** 2 / norm[(n, l)] for r in range(15)]
    print("chart P %s    " % name + " ".join("%5.2f" % v for v in vals))
grid = [i * 0.001 for i in range(1, 20001)]
peak3 = max(grid, key=lambda r: r * r * R_series(3, 2, r) ** 2)
print("3d most likely radius %.3f a0 (n^2 = 9)" % peak3)
box = [n * n * H * H / (8 * ME * 1e-18) / Q for n in (1, 2, 3)]
print("1 nm box levels (eV) " + " ".join("%.3f" % b for b in box))
print("wrong: electron mass, |E_1| %.6f eV, H-alpha %.3f nm" % (E1e, lam(E1e, 3, 2)))
print("wrong: 1/n not 1/n^2, H-alpha %.2f nm" % (H * C / (E1 * (1 / 2 - 1 / 3) * Q) * 1e9))
print("wrong: forget m, n=2 shell holds %d not %d" % (2 * 2, 2 * count[1]))
split = E1 / 4 * ALPHA * ALPHA / 4                 # Dirac: n=2, j=1/2 versus j=3/2
print("outside the outline: n=2 fine split %.2f micro-eV, %.4f nm in H-alpha"
      % (split * 1e6, lam(E1, 3, 2) ** 2 * split / (H * C / Q * 1e9)))
dD = lam(ryd(reduced(MD)), 3, 2)
print("try: deuterium H-alpha %.3f nm, %.3f nm below hydrogen" % (dD, lam(E1, 3, 2) - dD))
print("try: n=100 circular state radius %.2f nm, energy %.3f meV" % (1e4 * a0, -E1 / 1e4 * 1e3))

assert abs(E1e - RYD_CODATA) < 1e-7, "road 1: constants must give CODATA's Rydberg energy"
assert abs(IE_NIST - E1) < 2e-4 and IE_NIST > E1, "outline within 0.0002 eV of measured"
assert abs(bohr(ME) - A0_CODATA) < 1e-9, "road 1: constants must give CODATA's Bohr radius"
assert abs(lam(E1, 3, 2) - HA_NIST[0]) < 0.02, "H-alpha within 0.02 nm of the measured line"
assert series(2, 0)[1] == -0.5 and abs(series(3, 0)[2] - 2 / 27) < 1e-15, "textbook R20, R30"
assert all(abs(c) < 1e-300 for c in series(3, 1)[2:]), "series stops at k = n - l - 1"
for l in (0, 1, 2):          # road 3 against road 1: lowest n is l+1, E = -1/(2 n^2)
    want = [-0.5 / (n * n) for n in range(l + 1, 4)]
    assert len(shot[l]) == len(want) and all(abs(s - w) < 1e-6 for s, w in zip(shot[l], want))
assert count == [n * n for n in range(1, 5)], "n^2 shapes per shell"
assert abs(r_mean - 1.5) < 1e-6 and abs(N1 - 0.25) < 1e-6, "mean radius 3/2 a0, R10 = 2 e^-r"
assert abs(overlap) < 1e-6 and abs(peak3 - 9.0) < 1e-3, "orthogonal, circular peak at n^2"
print("ALL CHECKS PASS")
