# Carr-Madan spanning and the log contract -- the check behind the card.
# Standard library only.  The normal CDF is a series written out below, the
# integrals are Simpson's rule written out, nothing imported knows an answer.
from math import log, exp, sqrt, pi

S0, r, q, sig, T = 100.0, 0.05, 0.02, 0.20, 1.0
F, D = S0 * exp((r - q) * T), exp(-r * T)          # forward price, discount factor

def N(x):                                          # bell-curve area left of x
    if x > 8.5: return 1.0
    if x < -8.5: return 0.0
    y = abs(x) / sqrt(2.0); term = y; total = y; n = 0
    while term > 1e-17 * total:                    # erf(y) = 2/sqrt(pi) e^(-y^2) sum 2^n y^(2n+1)/(2n+1)!!
        n += 1; term *= 2.0 * y * y / (2 * n + 1); total += term
    e = 2.0 / sqrt(pi) * exp(-y * y) * total
    return 0.5 * (1.0 + e) if x >= 0 else 0.5 * (1.0 - e)

def call(K, s=sig):
    v = s * sqrt(T); d1 = (log(S0 / K) + (r - q + 0.5 * s * s) * T) / v
    return S0 * exp(-q * T) * N(d1) - K * D * N(d1 - v)
def put(K, s=sig):  return call(K, s) - S0 * exp(-q * T) + K * D   # put-call parity
def otm(K):         return put(K) if K < F else call(K)             # put below F, call above

def simpson(f, a, b, n):
    h = (b - a) / n; s = f(a) + f(b)
    for i in range(1, n): s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3.0

# the two payoffs: g, its slope g1, its curvature g2
LOG = (lambda x: 100.0 * log(x / 100.0), lambda x: 100.0 / x, lambda x: -100.0 / (x * x))
SQR = (lambda x: (x - 100.0) ** 2,        lambda x: 2.0 * (x - 100.0), lambda x: 2.0)

def road1(name, s=sig):                            # closed form from the lognormal's moments
    if name == "log": return 100.0 * D * (r - q - 0.5 * s * s) * T
    return D * (F * F * exp(s * s * T) - 200.0 * F + 10000.0)
def road2(g, S=S0, s=sig):                         # average the payoff over the bell curve, no options
    m = (r - q - 0.5 * s * s) * T
    return D * simpson(lambda z: g(S * exp(m + s * sqrt(T) * z)) * exp(-0.5 * z * z) / sqrt(2 * pi), -10.0, 10.0, 4000)
def road3(p):                                      # bond + forward + continuum strip, in log-strike
    g, g1, g2 = p; w = 12.0 * sig * sqrt(T)
    f = lambda x: g2(exp(x)) * otm(exp(x)) * exp(x)
    return D * g(F) + simpson(f, log(F) - w, log(F), 3000) + simpson(f, log(F), log(F) + w, 3000)
def strip(p, lo, hi, dk):                          # the discrete book: bond + one OTM option per strike
    g, g1, g2 = p; n = int(round((hi - lo) / dk)); tot = D * g(F)
    for i in range(n + 1):
        K = lo + i * dk; tot += g2(K) * dk * otm(K)
    return tot
def rebuilt(p, ST):                                # payoff of bond + forward + continuum at one S_T
    g, g1, g2 = p; a, b = min(F, ST), max(F, ST)
    return g(F) + g1(F) * (ST - F) + simpson(lambda K: g2(K) * (b - K) if ST > F else g2(K) * (K - a), a, b, 2000)

print(f"house: S 100, r 0.05, q 0.02, sigma 0.20, T 1; forward F = {F:.6f}, discount D = {D:.6f}")
print(f"listed: 90-put {put(90):.6f}, 120-call {call(120):.6f}; call at F {call(F):.6f} = put at F {put(F):.6f}")
print(f"log strip holdings (short): 90-put {100*30/90**2:.6f}, 120-call {100*30/120**2:.6f}; square strip (long): {2*30:.0f} each")
r1, r2, r3 = road1("log"), road2(LOG[0]), road3(LOG)
print(f"log contract, road 1 closed form      {r1:.6f}")
print(f"log contract, road 2 bell-curve mean  {r2:.6f}")
print(f"log contract, road 3 continuum strip  {r3:.6f} = bond {D*LOG[0](F):.6f} - options {D*LOG[0](F)-r3:.6f}")
print(f"variance the strip prices: 2 x options / (100 D T) = {2*(D*LOG[0](F)-r3)/(100*D*T):.6f}")
hp, hc = 100*30/90**2 * put(90), 100*30/120**2 * call(120)
print(f"two-strike log book: options {hp:.6f} + {hc:.6f} = {hp+hc:.6f}; price {D*LOG[0](F)-hp-hc:.6f}")
print(f"two-strike square book: 60 x (put + call) = {60*(put(90)+call(120)):.6f}; price {D*SQR[0](F)+60*(put(90)+call(120)):.6f}")
s1, s2, s3 = road1("sqr"), road2(SQR[0]), road3(SQR)
print(f"square contract, roads 1, 2, 3        {s1:.6f}, {s2:.6f}, {s3:.6f}; bond {D*SQR[0](F):.6f}")
print("strip                  strikes   log price        gap   square price       gap")
BOOKS = [("90 & 120 only", 90, 120, 30), ("80 to 120 by 10", 80, 120, 10), ("50 to 200 by 5", 50, 200, 5),
         ("20 to 400 by 1", 20, 400, 1), ("10 to 600 by 0.25", 10, 600, 0.25)]
for lab, lo, hi, dk in BOOKS:
    a, b = strip(LOG, lo, hi, dk), strip(SQR, lo, hi, dk)
    print(f"{lab:<22} {int(round((hi-lo)/dk))+1:>7} {a:>11.6f} {a-r1:>+10.6f} {b:>14.4f} {b-s1:>+9.4f}")
fine = strip(LOG, 10, 600, 0.25)
print("pathwise, log payoff: S_T, exact, tangent (bond+forward), options pay, rebuilt")
worst = 0.0
for ST in (70.0, 90.0, 110.0, 140.0):
    ex, tan, rb = LOG[0](ST), LOG[0](F) + LOG[1](F) * (ST - F), rebuilt(LOG, ST)
    worst = max(worst, abs(rb - ex), abs(rebuilt(SQR, ST) - SQR[0](ST)))
    print(f"  S_T {ST:6.2f}: exact {ex:9.6f}, tangent {tan:9.6f}, options {rb-tan:9.6f}, rebuilt {rb:9.6f}")
print(f"  two-listed book at S_T 110: {LOG[0](F)+LOG[1](F)*(110-F):.6f} (both options expire worthless)")
print(f"pathwise, both payoffs rebuilt to within 1e-9 at every S_T: {'yes' if worst < 1e-9 else 'no'}")
print("chart: S_T, log payoff, tangent, two-strike book")
xs = [60, 70, 80, 90, 100, 110, 120, 130, 140, 150]
book = lambda x: LOG[0](F) + LOG[1](F) * (x - F) - 100*30/8100 * max(90 - x, 0) - 100*30/14400 * max(x - 120, 0)
print("  x " + ", ".join(f"{x}" for x in xs))
print("  log " + ", ".join(f"{LOG[0](x):.2f}" for x in xs))
print("  tangent " + ", ".join(f"{LOG[0](F)+LOG[1](F)*(x-F):.2f}" for x in xs))
print("  book " + ", ".join(f"{book(x):.2f}" for x in xs))
h = 0.01
def dgam(S): return S * S * (road2(LOG[0], S + h) - 2 * road2(LOG[0], S) + road2(LOG[0], S - h)) / (h * h)
cg = lambda S: S * S * exp(-q * T) * exp(-0.5 * ((log(S / 100) + (r - q + 0.5 * sig * sig) * T) / sig) ** 2) / sqrt(2 * pi) / (S * sig)
print(f"log delta at S 100: closed {D:.6f}, bumped {(road2(LOG[0], 100+h)-road2(LOG[0], 100-h))/(2*h):.6f}")
print(f"log vega per vol point: closed {-100*D*sig*T/100:.6f}, bumped {(road2(LOG[0], 100, sig+1e-4)-road2(LOG[0], 100, sig-1e-4))/2e-4/100:.6f}")
gs = [dgam(S) for S in (80.0, 100.0, 125.0)]
print(f"log dollar gamma S^2 x gamma: closed {-100*D:.4f}; bumped at S 80, 100, 125: " + ", ".join(f"{g:.4f}" for g in gs))
print("  chart S " + ", ".join(f"{s}" for s in range(60, 161, 10)))
print("  log |S^2 gamma| " + ", ".join(f"{100*D:.2f}" for s in range(60, 161, 10)))
print("  100-call S^2 gamma " + ", ".join(f"{cg(s):.2f}" for s in range(60, 161, 10)))
bond, opts = D * LOG[0](F), D * LOG[0](F) - fine
wrong = [("strip held long", bond + opts), ("one weight 1/F^2 for all", bond - sum(100 * 0.25 / F ** 2 * otm(10 + i * 0.25) for i in range(2361))),
         ("calls below F, not puts", bond - sum(100 * 0.25 / (10 + i * 0.25) ** 2 * call(10 + i * 0.25) for i in range(2361))),
         ("bond piece dropped", -opts)]
for lab, v in wrong: print(f"mistake, {lab:<24} {v:10.6f} (right {r1:.6f})")
assert abs(r1 - r2) < 1e-8 and abs(s1 - s2) < 1e-6, "closed form vs bell-curve average"
assert abs(r3 - r1) < 1e-6 and abs(s3 - s1) < 1e-4, "continuum strip vs closed form"
assert abs(fine - r1) < 1e-4 and abs(strip(LOG, 90, 120, 30) - r1) > 0.3, "fine strip closes the gap, two strikes do not"
assert worst < 1e-9, "spanning identity holds pathwise"
assert all(abs(g + 100 * D) < 1e-3 for g in gs), "dollar gamma is flat at -100 D"
print("ALL CHECKS PASS")
