# What probability means -- the check behind the card.  Standard library only.
# A 30 percent chance of rain, read three ways: as a long-run frequency, as the
# fair price of a $1 ticket, and as a stated belief that a score rewards.
# Random draws come from SplitMix64, written out, seed 20260928, so the Rust
# program draws exactly the same days and prints exactly the same numbers.
from math import sqrt
M = (1 << 64) - 1
class SplitMix64:
    def __init__(self, seed): self.s = seed & M
    def uniform(self):                          # a number in [0, 1), 53 random bits
        self.s = (self.s + 0x9E3779B97F4A7C15) & M
        z = self.s
        z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) & M
        z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M
        return ((z ^ (z >> 31)) >> 11) / 9007199254740992.0
P = 0.30                                        # the forecast: 30 percent chance of rain
rng = SplitMix64(20260928)

# ---- road 1: frequency.  100,000 days on which the chance of rain really is 0.30 ----
DAYS = 100000
CHECKS = [10, 30, 100, 300, 1000, 3000, 10000, 30000, 100000]
rain, wet, freqs = [], 0, []
print("road 1, frequency: days  rainy  share rainy  standard error")
for d in range(1, DAYS + 1):
    y = 1 if rng.uniform() < P else 0           # 1 = measurable rain that day
    rain.append(y); wet += y
    if d in CHECKS:
        se = sqrt(P * (1 - P) / d)
        freqs.append(wet / d)
        print(f"  {d:>6} {wet:>6} {wet / d:>12.4f} {se:>15.4f}")
f_all, se_all = wet / DAYS, sqrt(P * (1 - P) / DAYS)
print("chart, share rainy:", ", ".join(f"{f:.2f}" for f in freqs))

# ---- road 2: price.  A ticket pays $1 if it rains; odds of 7 to 3 against rain ----
payout = sum(1.0 if y else 0.0 for y in rain) / DAYS      # one ticket a day, $1 if it rains
print(f"road 2, price: fair price of a $1 rain ticket, from the chance   {P:.2f}")
print(f"  average payout per ticket over the 100,000 days            {payout:.4f}")
odds_against = (1 - P) / P
print(f"  odds against rain, (1 - p) / p                               {odds_against:.4f}")
win = 7.0                                                # stake $3 at 7 to 3: win $7
exact_gain = sum(pr * g for pr, g in ((P, win), (1 - P, -3.0)))   # weigh both outcomes
sim_gain = sum(win if y else -3.0 for y in rain) / DAYS
print(f"  weighed by hand: 0.30 x {win:.4f} = {P * win:.4f} against 0.70 x 3 = {(1 - P) * 3:.4f}")
print(f"  $3 on rain at 7 to 3: average gain, both outcomes weighed  {exact_gain:.4f}")
print(f"  $3 on rain at 7 to 3: average gain over the days {sim_gain:.4f} (se {10 * se_all:.4f})")
even = sum(1.0 if y else -1.0 for y in rain) / DAYS      # $1 at even money
print(f"  $1 on rain at even money: average gain over the days {even:.4f} (se {2 * se_all:.4f})")
prices = {"rain": 0.30, "no rain": 0.60}                 # an incoherent bookmaker
cost = sum(prices.values())
for weather in ("rain", "no rain"):                      # enumerate what can happen
    paid = sum(1.0 for ticket in prices if ticket == weather)
    print(f"  buy both tickets for ${cost:.2f}, weather is {weather:<8}: buyer nets {paid - cost:+.2f}")
def sure_wins(a, b):          # holdings of -5 to 5 of each ticket (negative = sold) netting > 0 in both weathers
    return sum(1 for h in range(-5, 6) for k in range(-5, 6)
               if min(h - (h * a + k * b), k - (h * a + k * b)) > 1e-9)
coherent_wins = sum(sure_wins(c / 100, 1 - c / 100) for c in range(101))   # every price pair summing to 1
book_wins = sure_wins(prices["rain"], prices["no rain"])
print(f"  searched 121 holdings at each of 101 price pairs summing to 1: {coherent_wins} win in both weathers")
print(f"  searched 121 holdings at the bookmaker's prices, sum {cost:.2f}: {book_wins} win in both weathers")

# ---- road 3: belief.  The Brier score: (forecast - what happened)^2, averaged ----
def brier_exact(q, p): return p * (1 - q) ** 2 + (1 - p) * q ** 2   # weigh the two outcomes
grid = [k / 10 for k in range(11)]
curve = [brier_exact(q, P) for q in grid]
print("road 3, belief: expected Brier score for forecasts 0.0 to 1.0 when the chance is 0.30")
print("  " + ", ".join(f"{s:.2f}" for s in curve))
print(f"  squared misses: forecast 0.30 costs {(1 - 0.3) ** 2:.4f} if rain, {0.3 ** 2:.4f} if dry; 0.50 costs {0.5 ** 2:.4f}")
best = min(range(1001), key=lambda k: brier_exact(k / 1000, P)) / 1000   # search, no calculus
print(f"  forecast with the lowest expected score, searched on a 0.001 grid  {best:.3f}")
for q in (0.0, 0.3, 0.5):
    s = sum((q - y) ** 2 for y in rain) / DAYS
    print(f"  forecast {q:.1f}: score over the days {s:.4f}, expected {brier_exact(q, P):.4f}")
sim03 = sum((0.3 - y) ** 2 for y in rain) / DAYS
se03 = 0.4 * sqrt(P * (1 - P) / DAYS)             # (0.3 - y)^2 is 0.49 or 0.09: spread 0.4 per day

# ---- calibration: two forecasters, 2,000 days at each stated chance ----
print("calibration: said  honest: rained  overconfident: really  rained  se")
honest_ok, over_bad, hb, ob, over_line, hon_line = True, 0, 0.0, 0.0, [], []
N = 2000
for k in range(1, 10):
    said = k / 10
    truth = 0.5 + 0.6 * (said - 0.5)            # the overconfident forecaster exaggerates
    h = o = 0
    for _ in range(N):
        yh = 1 if rng.uniform() < said else 0
        yo = 1 if rng.uniform() < truth else 0
        h += yh; o += yo
        hb += (said - yh) ** 2; ob += (said - yo) ** 2
    se = sqrt(said * (1 - said) / N)
    honest_ok = honest_ok and abs(h / N - said) < 4 * se
    over_bad += abs(o / N - said) > 4 * se
    hon_line.append(h / N); over_line.append(o / N)
    print(f"  {said:>15.1f} {h / N:>15.4f} {truth:>22.2f} {o / N:>7.4f} {se:.4f}")
print("chart, stated chance:", ", ".join(f"{k / 10:.2f}" for k in range(1, 10)))
print("chart, honest:", ", ".join(f"{v:.2f}" for v in hon_line))
print("chart, overconfident:", ", ".join(f"{v:.2f}" for v in over_line))
print(f"  Brier score over the 18,000 days: honest {hb / (9 * N):.4f}, overconfident {ob / (9 * N):.4f}")

# ---- mistakes ----
print(f"mistake: odds 3 to 7 read as 3/7 = {3 / 7:.4f}; right: 3/(3 + 7) = {3 / (3 + 7):.4f}")
print(f"mistake: judged on 10 days, share rainy {freqs[0]:.2f}, standard error {sqrt(P * (1 - P) / 10):.4f}")

assert abs(f_all - P) < 4 * se_all                          # frequency agrees with the chance
assert coherent_wins == 0                                   # no holding beats prices that sum to 1
assert book_wins > 0                                        # the incoherent bookmaker can be beaten
assert abs(sim_gain - exact_gain) < 4 * 10 * se_all         # the days agree with both outcomes weighed
assert best == P                                            # honesty minimises the score
assert abs(sim03 - brier_exact(0.3, P)) < 4 * se03          # days against the formula
assert honest_ok                                            # the honest forecaster is calibrated
assert over_bad >= 6                                        # the overconfident one is not
assert hb < ob                                              # and it scores worse
print("ALL CHECKS PASS")
