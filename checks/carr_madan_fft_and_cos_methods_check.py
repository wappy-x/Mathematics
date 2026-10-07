# Transform pricing -- the check behind the card.  Standard library only.  Acme:
# S = 100, r = 5%, q = 2%, sigma = 20%, T = 1 year.  One object, the
# characteristic function of the log price, feeds two machines: Carr-Madan,
# which damps the call curve and inverts it with a single FFT, and COS, which
# expands the same law in cosine modes.  Both run first on the lognormal
# (Black-Scholes) law, where the closed formula is an independent referee, then
# on Heston, where no closed formula exists and the machines check each other.
# The bell-curve area, the FFT, the sums and the volatility search are written
# out here; nothing imported already knows an option price.
from math import log, sqrt, exp, erf, pi, cos, sin
from cmath import exp as cexp, sqrt as csqrt, log as clog

S, R, RATE, Q, SIG, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
ALPHA, N, ETA = 1.5, 4096, 0.25
LAM, HALF = 2.0*pi/(N*ETA), pi/ETA       # log-strike step, and half its window
HES = (0.04, 2.0, 0.04, 0.30, -0.70)     # v0, kappa, theta, vol of vol, rho
OFFSETS, LOW, HIGH = (-32, -16, 0, 16, 32), -3.0, 3.0
DISC, DIV = exp(-RATE*T), exp(-Q*T)

def bs_call(strike, vol=SIG):            # the referee: the closed formula
    ncdf = lambda x: 0.5*(1.0 + erf(x/sqrt(2.0)))    # bell-curve area left of x
    vt = vol*sqrt(T)
    d1 = (log(S/strike) + (RATE - Q + 0.5*vol*vol)*T)/vt
    return S*DIV*ncdf(d1) - strike*DISC*ncdf(d1 - vt)

def implied_vol(price, strike):          # bisection, written out, no library solver
    low, high = 0.005, 2.0
    for _ in range(80):
        mid = 0.5*(low + high)
        low, high = (low, mid) if bs_call(strike, mid) > price else (mid, high)
    return 0.5*(low + high)

def phi_gauss(z):                        # E[e^{zY}], Y = log(S_T/R), lognormal law
    return cexp(z*(RATE - Q - 0.5*SIG*SIG)*T + z*z*SIG*SIG*T/2.0)

def phi_heston(z, par=HES):              # the same object under Heston, one grouping
    v0, kap, th, xi, rho = par
    lin = rho*xi*z - kap
    root = csqrt(lin*lin - xi*xi*(z*z - z))       # principal branch, real part >= 0
    edge, g = (-lin - root)/(xi*xi), (-lin - root)/(-lin + root)
    decay = cexp(-root*T)
    bee = edge*(1.0 - decay)/(1.0 - g*decay)
    ay = kap*th*(edge*T - 2.0/(xi*xi)*clog((1.0 - g*decay)/(1.0 - g)))
    return cexp((RATE - Q)*z*T + ay + bee*v0)

def psi(u, phi, alpha=ALPHA):            # transform of the damped call curve
    p = alpha + 1.0
    return R*DISC*phi(complex(p, u))/(complex(alpha, u)*complex(p, u))

def fft(x):                              # radix two, minus sign, written out here
    n = len(x)
    if n == 1:
        return x[:]
    even, odd, out = fft(x[0::2]), fft(x[1::2]), [0j]*n
    for j in range(n//2):
        turn = cexp(complex(0.0, -2.0*pi*j/n))*odd[j]
        out[j], out[j + n//2] = even[j] + turn, even[j] - turn
    return out

def carr_madan(phi, alpha=ALPHA):
    freq = [(j + 0.5)*ETA for j in range(N)]
    val = [psi(u, phi, alpha) for u in freq]
    trans = fft([(1j if j % 2 == 0 else -1j)*v for j, v in enumerate(val)])
    def price(off, by_fft=True):         # off counts grid steps away from K = R
        cell, scale = N//2 + off, ETA*exp(-alpha*off*LAM)/pi
        if by_fft:                       # one transform serves every grid strike
            return scale*(cexp(complex(0.0, -pi*cell/N))*trans[cell]).real
        return scale*sum((cexp(complex(0.0, -u*off*LAM))*v      # the same sum alone
                          for u, v in zip(freq, val)), 0j).real
    return price

def cos_put(phi, strike, modes, low=LOW, high=HIGH, halve=True):
    width, edge = high - low, log(strike/R)
    top = low if edge <= low else min(high, edge)
    total = 0.0
    for n in range(modes):
        w = n*pi/width
        turn, ph = cexp(complex(0.0, -w*low))*phi(complex(0.0, w)), w*(top - low)
        flat = top - low if n == 0 else sin(ph)/w
        curved = (exp(top) - exp(low) if n == 0 else
                  (exp(top)*(cos(ph) + w*sin(ph)) - exp(low))/(1.0 + w*w))
        weight = 0.5 if n == 0 and halve else 1.0
        total += weight*2.0/width*turn.real*2.0/width*(strike*flat - R*curved)
    return DISC*width/2.0*total

def cos_call(phi, strike, modes, low=LOW, high=HIGH):
    return cos_put(phi, strike, modes, low, high) + S*DIV - strike*DISC

STRIKES = [R*exp(off*LAM) for off in OFFSETS]
grid_g, grid_h, grid_0 = carr_madan(phi_gauss), carr_madan(phi_heston), carr_madan(phi_gauss, 0.0)
forward = exp((RATE - Q)*T)
drift_ok = all(abs(f(complex(1.0, 0.0)).real - forward) < 1e-14 for f in (phi_gauss, phi_heston))
hes_fft, hes_cos, put128 = grid_h(0), cos_call(phi_heston, 100.0, 256), cos_put(phi_gauss, 100.0, 128)
vols = [[100.0*implied_vol(f(off), k) for off, k in zip(OFFSETS, STRIKES)] for f in (grid_g, grid_h)]
breaks = [("no damping, alpha = 0", grid_0(0), bs_call(100.0)),
          ("nearest node read for K = 100.30, node at 100.00",
           grid_g(round(log(100.30/R)/LAM)), bs_call(100.30)),
          ("COS window [-0.3, 0.3], 128 modes, the put",
           cos_put(phi_gauss, 100.0, 128, -0.3, 0.3), put128),
          ("COS constant mode at full weight, the put",
           cos_put(phi_gauss, 100.0, 128, LOW, HIGH, False), put128)]

print(f"""Acme, one year: S = 100, r = 5%, q = 2%, sigma = 20%, log prices against R = 100
grid: N = {N}, eta = {ETA}, cutoff N eta = {N*ETA:.0f}, lambda = {LAM:.9f}, half-window = {HALF:.6f}
damped transform at zero frequency, psi(0){psi(0.0, phi_gauss).real:>25.9f}
forward check, Phi(1) against e^(r-q)T = {forward:.12f}, both laws: {'yes' if drift_ok else 'no'}""")
for name, phi in (("lognormal law", phi_gauss), ("Heston law", phi_heston)):
    print(f"size of psi at u = 8, 16, 32, 64, {name:<14}"
          + " ".join(f"{abs(psi(u, phi)):>14.12f}" for u in (8.0, 16.0, 32.0, 64.0)))
print(f"\none FFT of {N} points, five strikes read off the same grid:")
print(f"{'strike':>11}{'Carr-Madan FFT':>17}{'direct sum':>17}{'closed formula':>17}{'Heston FFT':>17}")
for off, strike in zip(OFFSETS, STRIKES):
    print(f"{strike:>11.6f}{grid_g(off):>17.9f}{grid_g(off, False):>17.9f}"
          f"{bs_call(strike):>17.9f}{grid_h(off):>17.9f}")
print("\nCOS on the log window [-3, 3]: the put first, then the call by parity")
print(f"{'modes':>7}{'lognormal put':>17}{'lognormal call':>17}{'Heston put':>17}{'Heston call':>17}")
for modes in (8, 16, 32, 64, 128, 256):
    print(f"{modes:>7}{cos_put(phi_gauss, 100.0, modes):>17.9f}"
          f"{cos_call(phi_gauss, 100.0, modes):>17.9f}"
          f"{cos_put(phi_heston, 100.0, modes):>17.9f}"
          f"{cos_call(phi_heston, 100.0, modes):>17.9f}")
print("the house numbers, from the closed formula: put 6.330080627550, call 9.227005508154")
print(f"Heston at K = 100, the FFT road minus the COS road{hes_fft - hes_cos:>23.12f}")
print("\nimplied volatility backed out of those five prices, percent:")
print("  strike        " + "".join(f"{k:>8.2f}" for k in STRIKES))
print("  lognormal law " + "".join(f"{v:>8.2f}" for v in vols[0]))
print("  Heston law    " + "".join(f"{v:>8.2f}" for v in vols[1]))
print("\nwhat breaks:")
for label, wrong, right in breaks:
    print(f"  {label:<50}{wrong:>12.6f}   right: {right:.6f}")

assert max(abs(grid_g(o) - bs_call(k)) for o, k in zip(OFFSETS, STRIKES)) < 1e-8
assert max(abs(grid_g(o) - grid_g(o, False)) for o in OFFSETS) < 1e-9
assert abs(cos_call(phi_gauss, 100.0, 128) - bs_call(100.0)) < 1e-11
assert abs(bs_call(100.0) - 9.227005508154) < 1e-12
assert drift_ok and abs(hes_fft - hes_cos) < 1e-8
assert max(abs(v - 100.0*SIG) for v in vols[0]) < 1e-6
assert vols[1][0] > vols[1][2] > vols[1][4] and hes_fft < bs_call(100.0)
assert grid_0(0) < 0.0 and min(abs(w - right) for _, w, right in breaks) > 0.01
print("ALL CHECKS PASS")
