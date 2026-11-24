# Jarrow-Yildirim: a 5-year 0% zero-coupon inflation floor, Black on the model's volatility. Roads: closed-form
# variance vs quadrature; Black vs payoff integral; Monte Carlo of the model vs both; three routes to the YoY term.
from math import erf, exp, log, sqrt, pi, cos, sin

def N(x): return 0.5 * (1.0 + erf(x / sqrt(2.0)))
def phi(x): return exp(-0.5 * x * x) / sqrt(2.0 * pi)
def B(a, t): return (1.0 - exp(-a * t)) / a

T, K, VOL, RN, BE = 5.0, 1.0, 0.02, 0.035, 0.01     # maturity, strike ratio, ZC vol, nominal rate, breakeven
AN, SN, AR, SR = 0.10, 0.010, 0.05, 0.008           # Hull-White speed and vol: nominal, real
RNR, RNI, RRI = 0.90, 0.20, -0.10                   # correlations: nominal-real, nominal-index, real-index
def D(t, rn=RN): return (1.0 + rn) ** (-t)
def fwd(t, be=BE): return (1.0 + be) ** t

def pieces(t, si, sn=SN, sr=SR, rnr=RNR, rni=RNI, rri=RRI):   # the six variance terms, closed form
    i_n, i_r = (t - B(AN, t)) / AN, (t - B(AR, t)) / AR
    i_nn, i_rr = (t - 2 * B(AN, t) + B(2 * AN, t)) / AN ** 2, (t - 2 * B(AR, t) + B(2 * AR, t)) / AR ** 2
    i_nr = (t - B(AN, t) - B(AR, t) + B(AN + AR, t)) / (AN * AR)
    return [si * si * t, sn * sn * i_nn, sr * sr * i_rr,
            2 * rni * sn * si * i_n, -2 * rri * sr * si * i_r, -2 * rnr * sn * sr * i_nr]
def jyvol(t, si, **kw): return sqrt(sum(pieces(t, si, **kw)) / t)

def simpson(fn, lo, hi, n=2000):
    h = (hi - lo) / n
    return (fn(lo) + fn(hi) + sum((4 if i % 2 else 2) * fn(lo + i * h) for i in range(1, n))) * h / 3.0

def jyvol_quad(t, si):           # integrate the forward ratio's instantaneous variance over time
    def inst(s):
        bn, br = B(AN, t - s), B(AR, t - s)
        return (si * si + SN * SN * bn * bn + SR * SR * br * br + 2 * RNI * SN * si * bn
                - 2 * RRI * SR * si * br - 2 * RNR * SN * SR * bn * br)
    return sqrt(simpson(inst, 0.0, t) / t)

rest = sum(pieces(T, 0.0)); c1 = sum(pieces(T, 1.0)) - T - rest       # variance = T si^2 + c1 si + rest
SI = (-c1 + sqrt(c1 * c1 - 4 * T * (rest - VOL * VOL * T))) / (2 * T)  # index vol that gives 2% at 5 years

def black(f, k, w, put):         # Black on the index ratio, undiscounted
    d1 = (log(f / k) + 0.5 * w * w) / w; d2 = d1 - w
    return k * N(-d2) - f * N(-d1) if put else f * N(d1) - k * N(d2)
def zc(k, put=True, be=BE, vol=VOL, t=T, rn=RN): return 100 * D(t, rn) * black(fwd(t, be), k, vol * sqrt(t), put)

def zc_integral(k, put=True):    # average the payoff over the lognormal ratio; kink found by bisection
    w, f = VOL * sqrt(T), fwd(T)
    x = lambda z: f * exp(-0.5 * w * w + w * z)
    pay = lambda z: (max(k - x(z), 0.0) if put else max(x(z) - k, 0.0)) * phi(z)
    lo, hi = -12.0, 12.0
    for _ in range(200):
        mid = 0.5 * (lo + hi); lo, hi = (mid, hi) if x(mid) < k else (lo, mid)
    return 100 * D(T) * (simpson(pay, -12.0, lo) + simpson(pay, lo, 12.0))

def monte_carlo(paths=20000, steps=100, seed=1):   # simulate n, r and the index under nominal pricing
    st, mask = [seed], (1 << 64) - 1
    def u():                     # splitmix64, then a uniform strictly inside (0, 1)
        st[0] = (st[0] + 0x9E3779B97F4A7C15) & mask; z = st[0]
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & mask; z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & mask
        return (((z ^ (z >> 31)) >> 11) + 0.5) / 9007199254740992.0
    dt = T / steps; sq = sqrt(dt); fn, fr = log(1 + RN), log((1 + RN) / (1 + BE))
    l22 = sqrt(1 - RNR ** 2); l32 = (RRI - RNI * RNR) / l22; l33 = sqrt(1 - RNI ** 2 - l32 ** 2)
    phn = [fn + SN ** 2 / (2 * AN ** 2) * (1 - exp(-AN * k * dt)) ** 2 for k in range(steps + 1)]
    phr = [fr + SR ** 2 / (2 * AR ** 2) * (1 - exp(-AR * k * dt)) ** 2 for k in range(steps + 1)]
    sd = sf = sfl = sl = sl2 = 0.0; pair = []
    for _ in range(paths):
        zs = []
        for k in range(steps):
            r1, t1, r2, t2 = sqrt(-2 * log(u())), 2 * pi * u(), sqrt(-2 * log(u())), 2 * pi * u()
            zs.append((r1 * cos(t1), r1 * sin(t1), r2 * cos(t2)))
        pv = 0.0
        for sg in (1.0, -1.0):   # each draw and its mirror image
            xn = xr = lni = intn = 0.0
            for k in range(steps):
                z1, z2, z3 = sg * zs[k][0], sg * zs[k][1], sg * zs[k][2]
                w2, w3 = RNR * z1 + l22 * z2, RNI * z1 + l32 * z2 + l33 * z3
                nn, rr = phn[k] + xn, phr[k] + xr
                lni += (nn - rr - 0.5 * SI * SI) * dt + SI * sq * w3
                xn1 = xn - AN * xn * dt + SN * sq * z1
                xr += (-AR * xr - RRI * SR * SI) * dt + SR * sq * w2
                intn += 0.5 * (nn + phn[k + 1] + xn1) * dt; xn = xn1
            d, i = exp(-intn), exp(lni)
            f = d * max(K - i, 0.0)
            sd += d; sf += d * i; sfl += f; sl += d * lni; sl2 += d * lni * lni; pv += 0.5 * f
        pair.append(pv)
    m = 2 * paths; mu = sum(pair) / paths; se = sqrt(sum((p - mu) ** 2 for p in pair) / (paths - 1) / paths)
    return sd / m, sf / m, sqrt((sl2 / sd - (sl / sd) ** 2) / T), 100 * sfl / m, 100 * se

def conv(t0, t1, si):            # year-on-year correction, this card's arrangement
    br = B(AR, t0)
    return SR * B(AR, t1 - t0) * (RRI * si * br + RNR * SN * (br - B(AN + AR, t0)) / AN - 0.5 * SR * br * br)
def conv_pub(t0, t1, si):        # the same, in the arrangement published by Mercurio (2005)
    br, bn, g = B(AR, t0), B(AN, t0), RNR * SN / (AN + AR)
    return SR * B(AR, t1 - t0) * (br * (RRI * si - 0.5 * SR * br + g * (1 + AR * bn)) - g * bn)
def conv_quad(t0, t1, si):       # the integral before it is done in closed form
    g = lambda s: exp(-AR * (t0 - s)) * (RRI * si + RNR * SN * B(AN, t0 - s) - SR * B(AR, t0 - s))
    return SR * B(AR, t1 - t0) * simpson(g, 0.0, t0)

def row(label, v, d=6): print(f"{label:<40}{v:>14.{d}f}")
w = VOL * sqrt(T); F = fwd(T); d1 = (log(F / K) + 0.5 * w * w) / w; d2 = d1 - w
flo, flo_i, cap3, cap3_i = zc(K), zc_integral(K), zc(1.03 ** 5, False), zc_integral(1.03 ** 5, False)
par_l, par_r = zc_integral(K, False) - flo_i, 100 * D(T) * (F - K)
mc_d, mc_f, mc_v, mc_fl, mc_se = monte_carlo()
lk0 = 100 * D(T) * F; lk1 = lk0 + flo; y0, y1 = (100 / lk0) ** 0.2 - 1, (100 / lk1) ** 0.2 - 1
seas, c5, c20 = 110 * D(T) * black(F, 1 / 1.10, w, True), conv(4, 5, SI), conv(19, 20, SI)
print("inputs: T 5y, strike ratio 1.00, ZC vol 2.00 pct, nominal 3.50 pct, breakeven 1.00 pct")
row("D(5), nominal discount factor", D(T)); row("F, forward index ratio (1.01^5)", F)
row("P_r(0,5), real bond = D F", D(T) * F)
for lab, p in zip(("index", "nominal bond", "real bond", "nominal x index", "real x index",
                   "nominal x real"), pieces(T, SI)):
    row(f"variance piece, {lab}", p, 8)
row("sigma_I, index vol solved, pct", 100 * SI); row("rates-only vol (sigma_I = 0), pct", 100 * jyvol(T, 0.0))
row("ZC vol, closed form, pct", 100 * jyvol(T, SI)); row("ZC vol, Simpson in time, pct", 100 * jyvol_quad(T, SI))
row("ZC vol, Monte Carlo, pct", 100 * mc_v)
row("MC: P_n(0,5)", mc_d); row("MC: P_r(0,5)", mc_f); row("w = vol sqrt(T)", w)
row("d1", d1); row("d2", d2); row("N(-d2)", N(-d2)); row("N(-d1)", N(-d1))
row("1 floor 0%, Black, per 100", flo); row("2 floor 0%, payoff integral, per 100", flo_i)
row("3 floor 0%, Monte Carlo, per 100", mc_fl); row("  Monte Carlo standard error", mc_se)
row("cap 3% a year (K 1.159274), Black", cap3); row("cap 3% a year, payoff integral", cap3_i)
row("parity: cap 1.00 minus floor 1.00", par_l); row("parity: D (F - 1) x 100", par_r)
row("house: floor at 2.5% breakeven", zc(K, be=0.025)); row("house: F at 2.5% (1.025^5)", fwd(T, 0.025))
row("linker without floor, per 100", lk0); row("linker with floor, per 100", lk1)
row("real yield without floor, pct", 100 * y0); row("real yield with floor, pct", 100 * y1)
row("floor in real yield, bp", 1e4 * (y0 - y1)); row("seasoned linker (ratio 1.10), floor", seas)
print(f"YoY year 5: C, bp (card, published, Simpson) {1e4 * c5:.6f} {1e4 * conv_pub(4, 5, SI):.6f} "
      f"{1e4 * conv_quad(4, 5, SI):.6f}"); row("YoY year 20: C, bp", 1e4 * c20)
row("YoY year 20 forward, pct", 100 * ((1 + BE) * exp(c20) - 1))
row("wrong: index vol only, rates ignored", zc(K, vol=SI)); row("wrong: discounted with real bond", flo * F)
row("wrong: correlations set to 0, vol pct", 100 * jyvol(T, SI, rnr=0, rni=0, rri=0))
row("wrong: correlations set to 0, floor", zc(K, vol=jyvol(T, SI, rnr=0, rni=0, rri=0)))
row("wrong: breakeven ignored (F = 1)", zc(K, be=0.0))
row("try: ZC vol 3%", zc(K, vol=0.03)); row("try: 10 years, ZC vol pct", 100 * jyvol(10, SI))
row("try: 10 years, floor", zc(K, vol=jyvol(10, SI), t=10)); row("try: breakeven 0.5%", zc(K, be=0.005))
print("chart, breakeven pct  " + "".join(f"{b:>8.1f}" for b in (0, 0.5, 1, 1.5, 2, 2.5)))
print("chart, floor per 100  " + "".join(f"{zc(K, be=b / 100):>8.3f}" for b in (0, 0.5, 1, 1.5, 2, 2.5)))
print("chart, ZC vol pct     " + "".join(f"{100 * jyvol(t, SI):>6.2f}" for t in range(1, 11)))
assert abs(jyvol(T, SI) - jyvol_quad(T, SI)) < 1e-10            # closed-form integrals against quadrature
assert abs(flo - flo_i) < 1e-9 and abs(cap3 - cap3_i) < 1e-9     # Black against the payoff integral
assert abs(par_l - par_r) < 1e-9                                 # parity: cap minus floor is a swap
assert abs(mc_fl - flo) < 4 * mc_se                              # the simulated model prices the same floor
assert abs(mc_v - VOL) < 3e-4 and abs(mc_d - D(T)) < 1e-4 and abs(mc_f - D(T) * F) < 1e-4
assert abs(c5 - conv_pub(4, 5, SI)) < 1e-14 and abs(c5 - conv_quad(4, 5, SI)) < 1e-12
assert round(flo, 3) == 0.258                                    # the spec's quoted price
print("ALL CHECKS PASS")
