# Deciding under uncertainty: the market-stall order and the price of a forecast.
# Roads: fold back the tree; expected regret; every message-to-action rule counted on
# 1,000 whole Saturdays; a seeded simulation; bisection on the price of the forecast.
from math import log, exp

P_SUN = 0.6                                       # chance Saturday is sunny
ACTS = [("big", 600, -300), ("small", 250, 50)]   # profit in pounds: (name, sun, rain)
W0 = 1000.0                                       # manager's cash buffer, pounds
Q = 0.8                                           # forecast accuracy
FEE = 50.0                                        # what the forecast costs

def best(p_sun, u=lambda x: x):                   # fold back one chance node per action
    vals = [(p_sun * u(s) + (1 - p_sun) * u(r), n) for n, s, r in ACTS]
    return max(vals)

def messages(q):                                  # Bayes' rule: (P(message), P(sun | message))
    out = []
    for p_s, p_r in [(P_SUN * q, (1 - P_SUN) * (1 - q)), (P_SUN * (1 - q), (1 - P_SUN) * q)]:
        out.append((p_s + p_r, p_s / (p_s + p_r)))
    return out

def with_forecast(q, u=lambda x: x):              # expected score when the forecast is read first
    return sum(pm * best(ps, u)[0] for pm, ps in messages(q))

def price(q, u):                                  # largest fee the manager would pay, by bisection
    target = best(P_SUN, u)[0]
    lo, hi = 0.0, 500.0
    for _ in range(100):
        mid = (lo + hi) / 2
        if with_forecast(q, lambda x: u(x - mid)) > target:
            lo = mid
        else:
            hi = mid
    return lo

money = lambda x: x
logu = lambda x: log(W0 + x)
ce = lambda v: exp(v) - W0                        # certainty equivalent from a log score

print(f"Saturday stall: chance of sun {P_SUN}, manager's cash buffer {W0:.0f}")
print("action   sun   rain   expected   certainty equivalent (log)")
for n, s, r in ACTS:
    em = P_SUN * s + (1 - P_SUN) * r
    cu = ce(P_SUN * logu(s) + (1 - P_SUN) * logu(r))
    print(f"{n:<6} {s:>5} {r:>6} {em:>10.2f} {cu:>10.2f}")
v0, a0 = best(P_SUN)
u0, b0 = best(P_SUN, logu)
print(f"choice by expected money: {a0}; by expected utility: {b0}")

# Perfect information: learn the weather, then choose.
sun_best = max(s for _, s, _ in ACTS)
rain_best = max(r for _, _, r in ACTS)
v_perfect = P_SUN * sun_best + (1 - P_SUN) * rain_best
evpi = v_perfect - v0
print(f"perfect forecast: sun -> big, rain -> small, expected {v_perfect:.2f}")
print(f"EVPI = {v_perfect:.2f} - {v0:.2f} = {evpi:.2f}")
chosen = [a for a in ACTS if a[0] == a0][0]
regret = P_SUN * (sun_best - chosen[1]) + (1 - P_SUN) * (rain_best - chosen[2])
print(f"EVPI as expected regret of {a0}: {regret:.2f} (regret in rain {rain_best - chosen[2]:.2f})")
assert abs(evpi - regret) < 1e-9 and abs(evpi - 140) < 1e-9

# The 80% forecast, through Bayes' rule.
(pm_s, ps_s), (pm_r, ps_r) = messages(Q)
print(f"{Q:.0%} forecast: P(says sun) {pm_s:.4f}, P(sun | says sun) {ps_s:.4f}, P(sun | says rain) {ps_r:.4f}")
for label, ps in [("says sun", ps_s), ("says rain", ps_r)]:
    vals = "  ".join(f"{n} {ps * s + (1 - ps) * r:.2f}" for n, s, r in ACTS)
    print(f"  {label}: {vals} -> {best(ps)[1]}")
v_q = with_forecast(Q)
evsi = v_q - v0
print(f"expected with forecast {v_q:.2f}, worth {evsi:.2f}; fee {FEE:.2f} -> {'buy' if evsi > FEE else 'skip'}, ahead {evsi - FEE:.2f}")
print(f"Friday decision: no forecast {v0:.2f}, forecast after fee {v_q - FEE:.2f}; worth {max(v0, v_q - FEE):.2f}")

# Road 3: 1,000 Saturdays in whole numbers, every rule from message to action.
n_ss, n_sr = 480, 120                             # sunny days: forecast said sun / rain
n_rs, n_rr = 80, 320                              # rainy days: forecast said sun / rain
print(f"1000 Saturdays: sunny says sun {n_ss}, says rain {n_sr}; rainy says sun {n_rs}, says rain {n_rr}")
rules = []
for an, asun, arain in ACTS:                      # action after "says sun"
    for bn, bsun, brain in ACTS:                  # action after "says rain"
        tot = n_ss * asun + n_rs * arain + n_sr * bsun + n_rr * brain
        rules.append((tot, f"{an}/{bn}"))
print("1000 Saturdays, total profit per rule: " + "  ".join(f"{r} {t}" for t, r in rules))
assert max(rules)[0] == round(1000 * v_q) and max(rules)[1] == "big/small"

# Road 4: simulation, SplitMix64.
state = 20261111
def unif():
    global state
    state = (state + 0x9E3779B97F4A7C15) & 0xFFFFFFFFFFFFFFFF
    z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & 0xFFFFFFFFFFFFFFFF
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & 0xFFFFFFFFFFFFFFFF
    return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
N = 200000
tb = tp = tf = 0
for _ in range(N):
    sun = unif() < P_SUN
    says_sun = sun if unif() < Q else not sun
    tb += 600 if sun else -300
    tp += 600 if sun else 50
    tf += (600 if sun else -300) if says_sun else (250 if sun else 50)
print(f"simulated {N} Saturdays: always big {tb / N:.2f}, perfect {tp / N:.2f}, forecast {tf / N:.2f}")
assert abs(tb / N - v0) < 5 and abs(tp / N - v_perfect) < 5 and abs(tf / N - v_q) < 5

# Prices by bisection: straight utility must give back EVPI and the forecast's worth.
assert abs(price(1.0, money) - evpi) < 1e-6 and abs(price(Q, money) - evsi) < 1e-6
c_perfect, c_q = price(1.0, logu), price(Q, logu)
print(f"cautious manager (log): no forecast {ce(u0):.2f}; perfect worth {c_perfect:.2f}; {Q:.0%} worth {c_q:.2f}")
assert c_perfect > evpi and c_q > evsi            # here, minding risk raises the price
ce_q = ce(with_forecast(Q, logu))                 # the shortcut: subtract certainty equivalents, fee ignored
print(f"shortcut, difference of certainty equivalents: {ce_q:.2f} - {ce(u0):.2f} = {ce_q - ce(u0):.2f}, not {c_q:.2f}")

print("accuracy  money value  cautious price")
qs = [0.5 + 0.05 * i for i in range(11)]
for q in qs:
    vm = round(with_forecast(q) - v0, 9) + 0.0      # no "-0.00" at the tie
    assert abs(vm - max(0.0, 350 * q - 210)) < 1e-9   # closed form from the tree
    print(f"{q:.2f} {vm:>12.2f} {price(q, logu):>15.2f}")

print(f"money value passes the fee at accuracy {(FEE + 210) / 350:.4f}")
d_s, d_r = logu(600) - logu(250), logu(50) - logu(-300)  # log-score edge of big in sun, of small in rain
p_tip = d_r / (d_s + d_r)                         # chance of sun at which the cautious manager switches to big
q_tip = (1 - P_SUN) * p_tip / (P_SUN * (1 - p_tip) + (1 - P_SUN) * p_tip)  # accuracy where "says sun" gives p_tip
print(f"cautious price leaves zero at accuracy {q_tip:.4f}, where P(sun | says sun) reaches {p_tip:.4f}")
assert price(q_tip - 1e-3, logu) < 1e-9 < price(q_tip + 1e-3, logu)  # bisection agrees with the switch point
ce_big = ce(P_SUN * logu(600) + (1 - P_SUN) * logu(-300))
assert abs(ce_big - ((W0 + 600) ** 0.6 * (W0 - 300) ** 0.4 - W0)) < 1e-9  # log score: geometric mean
v_small = P_SUN * 250 + (1 - P_SUN) * 50
print(f"what breaks: best case minus average {sun_best - v0:.2f}; wrong baseline {v_perfect - v_small:.2f}; "
      f"{Q:.0%} of perfect {Q * evpi:.2f}; cautious manager on big loses {ce(u0) - ce_big:.2f}")
wet = 0.3                                         # a wetter season, for "When it holds"
wet_plan = max(wet * s + (1 - wet) * r for _, s, r in ACTS)
wet_evpi = wet * sun_best + (1 - wet) * rain_best - wet_plan
print(f"wetter season, sun {wet}: best plan {wet_plan:.2f}, EVPI {wet_evpi:.2f}")
assert abs(wet_evpi - wet * (sun_best - 250)) < 1e-9  # regret of the small order: sun only
print("ALL CHECKS PASS")
