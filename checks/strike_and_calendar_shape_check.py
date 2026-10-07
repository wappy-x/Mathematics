# Shape across strikes and expiries -- the check behind the card.  Standard library only, and
# nothing imported that already knows an option price: the bell-curve area comes from math.erf,
# every integral is Simpson's rule written out below, the implied variance a bisection likewise.
from math import log, sqrt, exp, erf, pi
S, R, Q, SIG = 100.0, 0.05, 0.02, 0.20       # Acme spot, rate, dividend yield, volatility
T1, T2 = 0.5, 1.0                            # near and far expiry, in years
STRIKES = [80.0, 90.0, 100.0, 110.0, 120.0]
def N(x):    return 0.5 * (1.0 + erf(x / sqrt(2.0)))      # bell-curve area left of x
def phi(x):  return exp(-0.5 * x * x) / sqrt(2.0 * pi)    # bell-curve height at x
def disc(t): return exp(-R * t)                           # D(t): a dollar at t, valued today
def fwd(t):  return S * exp((R - Q) * t)                  # F(t): the forward price
def simpson(f, a, b, n):                                  # plain Simpson's rule
    h, s = (b - a) / n, f(a) + f(b)
    for i in range(1, n):
        s += (4.0 if i % 2 else 2.0) * f(a + i * h)
    return s * h / 3.0
def call(k, t, s=S, sig=SIG):                             # Black-Scholes call
    d1 = (log(s / k) + (R - Q + 0.5 * sig * sig) * t) / (sig * sqrt(t))
    return s * exp(-Q * t) * N(d1) - k * exp(-R * t) * N(d1 - sig * sqrt(t))
def putp(k, t, s=S, sig=SIG):                             # Black-Scholes put
    d1 = (log(s / k) + (R - Q + 0.5 * sig * sig) * t) / (sig * sqrt(t))
    return k * exp(-R * t) * N(sig * sqrt(t) - d1) - s * exp(-Q * t) * N(-d1)
def by_payoff(payoff, t):                                 # road 2: average the payoff itself
    def f(z): return payoff(S * exp((R - Q - 0.5 * SIG * SIG) * t + SIG * sqrt(t) * z)) * phi(z)
    return disc(t) * simpson(f, -10.0, 10.0, 40000)
def cnorm(k, w):                  # normalized call: moneyness and total variance, nothing else
    d1 = (-log(k) + 0.5 * w) / sqrt(w)
    return N(d1) - k * N(d1 - sqrt(w))
def implied_w(k, c):              # bisection; cnorm climbs strictly in w, so there is one root
    assert max(1.0 - k, 0.0) < c < 1.0, "at or outside the bounds no total variance exists"
    lo, hi = 1e-12, 100.0
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        lo, hi = (mid, hi) if cnorm(k, mid) < c else (lo, mid)
    return 0.5 * (lo + hi)
# ---- the house market, and the one-year strip -------------------------------------------
cash = {k: call(k, T2) for k in STRIKES}
integ = {k: by_payoff(lambda st, k=k: max(st - k, 0.0), T2) for k in STRIKES}
cap = disc(T2) * 10.0
spread = {k: cash[k] - cash[k + 10.0] for k in STRIKES[:-1]}
fly = {k: cash[k - 10.0] - 2.0 * cash[k] + cash[k + 10.0] for k in STRIKES[1:-1]}
tent = by_payoff(lambda st: max(st - 90.0, 0.0) - 2.0 * max(st - 100.0, 0.0) + max(st - 110.0, 0.0), T2)
ramp = by_payoff(lambda st: min(max(st - 90.0, 0.0), 10.0), T2)
ok_k = min(spread.values()) > 0 and max(spread.values()) < cap and min(fly.values()) > 0
print("Acme: S = 100, r = 5%, q = 2%, sigma = 20%; expiries 0.5 and 1 year")
print(f"forward F(1) = S e^((r-q)T) {fwd(T2):12.6f}   F(0.5) {fwd(T1):12.6f}")
print(f"discount D(1) = e^(-rT)     {disc(T2):12.6f}   D(0.5) {disc(T1):12.6f}\n")
print(f"{'K':>5} {'C(K,1) formula':>15} {'by integral':>12} {'C(K)-C(K+10)':>13} {'cap D(1)*10':>12} {'butterfly':>10}")
for k in STRIKES:
    sp = f"{spread[k]:13.6f}" if k in spread else f"{'--':>13}"
    bf = f"{fly[k]:10.6f}" if k in fly else f"{'--':>10}"
    print(f"{k:5.0f} {cash[k]:15.6f} {integ[k]:12.6f} {sp} {cap:12.6f} {bf}")
print(f"every spread inside 0 and the cap, every butterfly above zero: {'yes' if ok_k else 'no'}")
print(f"butterfly 90/100/110 from three prices {fly[100.0]:11.6f};  90/110 average {0.5 * (cash[90.0] + cash[110.0]):11.6f}")
print(f"the same tent payoff, integrated       {tent:11.6f};  call spread 90/100 {spread[90.0]:11.6f}")
print(f"its capped ramp payoff, integrated     {ramp:11.6f};  C(100,1)           {cash[100.0]:11.6f}")
# ---- the calendar pair, in forward-adjusted strike --------------------------------------
kfar = 100.0 * fwd(T2) / fwd(T1)              # the forward-adjusted strike
wgt = exp(-Q * (T2 - T1))                     # near legs that one far leg can cover
near, far = call(100.0, T1), call(kfar, T2)
money = 100.0 / fwd(T1)                       # forward moneyness, shared by the pair
nrm_n, nrm_f = near / (S * exp(-Q * T1)), far / (S * exp(-Q * T2))
wn, wf = implied_w(money, nrm_n), implied_w(money, nrm_f)
spots = [60.0, 80.0, 100.0, 120.0, 140.0, 160.0]
legf, short = [call(kfar, T2 - T1, s=x) for x in spots], [wgt * max(x - 100.0, 0.0) for x in spots]
cover = [a - b for a, b in zip(legf, short)]
byput = [call(kfar, T2 - T1, s=x) if x <= 100.0 else putp(kfar, T2 - T1, s=x) for x in spots]
dense = [call(kfar, T2 - T1, s=x) if x <= 100.0 else putp(kfar, T2 - T1, s=x) for x in (50.0 + 0.5 * i for i in range(301))]
print(f"\nforward-adjusted strike K2 = 100 F(1)/F(0.5) {kfar:12.6f};  weight w = e^(-q(T2-T1)) {wgt:10.6f}")
print(f"near call C(100, 0.5) {near:11.6f};  far call C(101.511306, 1) {far:11.6f};  far - w x near {far - wgt * near:10.6f}")
print(f"shared moneyness k {money:8.6f};  normalized c = C/(S e^(-qT)): near {nrm_n:10.6f}, far {nrm_f:10.6f}")
print(f"total implied variance by bisection: near {wn:8.6f}, far {wf:8.6f};  sigma^2 T {SIG * SIG * T1:8.6f} {SIG * SIG * T2:8.6f}")
print("at the near expiry the far leg covers w near legs, whatever Acme does\nAcme at T1  "
      + "".join(f"{x:10.0f}" for x in spots))
print("far leg     " + "".join(f"{v:10.6f}" for v in legf))
print("w x payoff  " + "".join(f"{v:10.6f}" for v in short))
print("cover       " + "".join(f"{v:10.6f}" for v in cover))
print("as far put  " + "".join(f"{v:10.6f}" for v in byput))
print(f"cover positive at 301 spots from 50 to 200: {'yes' if min(dense) > 0 else 'no'};  peak {max(dense):10.6f}")
# ---- road 3: no model at all.  A lumpy law with the right forward, and a tree -----------
nodes, prob = [60.0, 85.0, 100.0, 125.0, 170.0], [0.10, 0.20, 0.40, 0.0, 0.0]
prob[3] = (fwd(T2) - sum(n * p for n, p in zip(nodes, prob)) - 170.0 * 0.30) / (125.0 - 170.0)
prob[4] = 0.30 - prob[3]           # the last two weights are what makes the mean equal F(1)
lump = lambda k: disc(T2) * sum(p * max(n - k, 0.0) for n, p in zip(nodes, prob))
lsp = [lump(k) - lump(k + 10.0) for k in STRIKES[:-1]]
lfly = [lump(k - 10.0) - 2.0 * lump(k) + lump(k + 10.0) for k in STRIKES[1:-1]]
up, dn = 1.25, 0.80
pu = (1.0 - dn) / (up - dn)         # the weights hold the forward flat: pu*up + (1-pu)*dn = 1
law1, law2 = [(up, pu), (dn, 1.0 - pu)], [(up * up, pu * pu), (up * dn, 2.0 * pu * (1.0 - pu)),
                                           (dn * dn, (1.0 - pu) ** 2)]
cl = lambda law, k: sum(p * max(x - k, 0.0) for x, p in law)
gaps = [cl(law2, 0.60 + 0.025 * i) - cl(law1, 0.60 + 0.025 * i) for i in range(33)]
ok_lump = min(lsp) > 0 and max(lsp) < cap and min(lfly) > 0
print("\nlumpy law, no Black-Scholes: nodes " + ", ".join(f"{n:.0f}" for n in nodes)
      + ", weights " + ", ".join(f"{p:.6f}" for p in prob))
print(f"its mean {sum(n * p for n, p in zip(nodes, prob)):11.6f} is F(1);  both strike rules hold:"
      f" {'yes' if ok_lump else 'no'};  its 90/100/110 butterfly {lfly[1]:10.6f}")
print(f"two-step flat-forward tree at moneyness 0.90: near {cl(law1, 0.90):10.6f}, far {cl(law2, 0.90):10.6f}")
print(f"none of 33 moneynesses from 0.60 to 1.40 falls with expiry: {'yes' if min(gaps) > -1e-15 else 'no'}")
# ---- a hand-made sheet that breaks all three, and the free trade ------------------------
quote = {80.0: 24.80, 90.0: 15.10, 100.0: 10.60, 110.0: 5.20, 120.0: 5.40}   # one-year quotes
qnear, qfar = 8.60, 8.40                    # half-year 100-call, one-year 101.511306-call
def worst(legs, csh, t):            # least wealth at t: banked cash plus the worst payoff
    return csh / disc(t) + min(sum(n * max(1.0 + 0.25 * i - k, 0.0) for k, n in legs) for i in range(1200))
bad_cap, bad_cal = quote[80.0] - quote[90.0], wgt * qnear - qfar
bad_fly, bad_mon = 2.0 * quote[100.0] - quote[90.0] - quote[110.0], quote[120.0] - quote[110.0]
broken = [("cap on the 80/90 spread", bad_cap, bad_cap - cap, [(80.0, -1.0), (90.0, 1.0)]),
          ("butterfly 90/100/110", bad_fly, bad_fly, [(90.0, 1.0), (100.0, -2.0), (110.0, 1.0)]),
          ("the 120 quoted above the 110", bad_mon, bad_mon, [(110.0, 1.0), (120.0, -1.0)]),
          ("calendar, near against far", bad_cal, bad_cal, None)]
print("\nhand-made one-year quotes: " + ", ".join(f"{k:.0f} at {v:.2f}" for k, v in quote.items())
      + f";  half-year 100-call {qnear:.2f}, one-year 101.511306-call {qfar:.2f}")
print(f"{'rule broken':<30}{'cash in today':>14}{'least wealth later':>20}{'free money today':>18}")
leasts = [worst(lg, ch, T2) if lg else ch / disc(T1) + min(dense) for _, ch, _, lg in broken]
for (name, csh, free, _), least in zip(broken, leasts):
    print(f"{name:<30}{csh:14.6f}{least:20.6f}{free:18.6f}")
# ---- what breaks if a piece is dropped --------------------------------------------------
print(f"\nno forward adjustment: cash C(100,200) - C(100,1) {call(100.0, 200.0) - cash[100.0]:10.6f}")
print(f"cap read as 10.00 not {cap:.6f}: free money per spread {10.0 - cap:10.6f}")
print(f"unequal wings 90/100/120, weights 2 to 1: bound {(2.0 * cash[90.0] + cash[120.0]) / 3.0:10.6f},"
      f" plain average {0.5 * (cash[90.0] + cash[120.0]):10.6f}")
print(f"implied vol 25% then 20% is no violation: total variance {0.25*0.25*T1:8.6f} then {SIG*SIG*T2:8.6f},"
      f" normalized call {call(100.0, T1, sig=0.25)/(S*exp(-Q*T1)):8.6f} then {nrm_f:8.6f}")
print("\nchart, strike K     " + "".join(f"{80.0 + 5.0 * i:8.0f}" for i in range(9)))
print("chart, call C(K,1)  " + "".join(f"{call(80.0 + 5.0 * i, T2):8.2f}" for i in range(9)))
print("chart, chord 90-110 " + "".join(f"{cash[90.0] + (i - 2.0) * (cash[110.0] - cash[90.0]) / 4.0:8.2f}" for i in range(9)))
print("chart, Acme at T1   " + "".join(f"{x:8.0f}" for x in spots))
print("chart, far leg      " + "".join(f"{v:8.2f}" for v in legf))
print("chart, w x payoff   " + "".join(f"{v:8.2f}" for v in short))
assert abs(cash[100.0] - 9.227005508154) < 1e-9, "the shelf's house call"
assert max(abs(cash[k] - integ[k]) for k in STRIKES) < 1e-6 and abs(fly[100.0] - tent) < 1e-6 \
    and abs(spread[90.0] - ramp) < 1e-6, "the formula, and both combinations, against the payoffs"
assert ok_k and min(dense) > 0, "the house strip obeys both strike rules, and the far leg covers"
assert max(abs(cover[i] - byput[i]) for i in range(len(spots))) < 1e-12, "cover equals the far put"
assert abs(wn - SIG * SIG * T1) < 1e-9 and abs(wf - SIG * SIG * T2) < 1e-9, "bisection recovers sigma^2 T"
assert ok_lump and min(gaps) > -1e-15 and abs(lump(0.0) - disc(T2) * fwd(T2)) < 1e-9 \
    and abs(cl(law1, 0.0) - 1.0) + abs(cl(law2, 0.0) - 1.0) < 1e-15, \
    "a lumpy law and a tree, each carrying the right forward, obey all three rules"
assert min([r[1] for r in broken] + [r[2] for r in broken] + leasts) > 0, "each broken rule pays cash that outlasts its worst outcome"
print("ALL CHECKS PASS")
