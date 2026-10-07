# Two-asset portfolio: mean and spread of a 60-40 mix of shares and bonds.
# Standard library only.  Three roads to the 60-40 spread: the variance
# formula, a four-state ledger in dollars, and a simulation with home-made
# random numbers.  The least-risk weight is found by formula and by search.
from math import sqrt, log, cos, pi

MA, SA = 0.08, 0.20            # shares: mean return, spread (standard deviation)
MB, SB = 0.04, 0.06            # bonds: mean return, spread
RHO, W = 0.2, 0.6              # correlation, weight in shares

def formula_var(w, rho):       # road 1: w^2 vA + (1-w)^2 vB + 2 w (1-w) rho sA sB
    return w * w * SA * SA + (1 - w) ** 2 * SB * SB + 2 * w * (1 - w) * rho * SA * SB

def ledger(w, rho, money=1000.0):   # road 2: four states, each asset one spread up or down
    states = []                     # P(both up) = P(both down) = (1+rho)/4, mixed = (1-rho)/4
    for sa, sb in ((1, 1), (1, -1), (-1, 1), (-1, -1)):
        p = (1 + rho * sa * sb) / 4
        ra, rb = MA + sa * SA, MB + sb * SB
        shares, bonds = w * money * (1 + ra), (1 - w) * money * (1 + rb)
        states.append((p, ra, rb, shares, bonds, (shares + bonds) / money - 1))
    mean = sum(s[0] * s[5] for s in states)
    var = sum(s[0] * (s[5] - mean) ** 2 for s in states)
    return states, mean, var

def simulate(w, rho, n=200000, seed=20260928):   # road 3: correlated normal draws
    x = seed
    def uniform():
        nonlocal x                    # xorshift64: shift-and-xor random bits
        x ^= (x << 13) & 0xFFFFFFFFFFFFFFFF
        x ^= x >> 7
        x ^= (x << 17) & 0xFFFFFFFFFFFFFFFF
        return ((x >> 11) + 0.5) / 9007199254740992.0
    s = s2 = 0.0
    for _ in range(n):
        u1, u2, u3, u4 = uniform(), uniform(), uniform(), uniform()
        z1 = sqrt(-2 * log(u1)) * cos(2 * pi * u2)         # Box-Muller: uniform -> normal
        z2 = sqrt(-2 * log(u3)) * cos(2 * pi * u4)
        za, zb = z1, rho * z1 + sqrt(1 - rho * rho) * z2  # give the pair correlation rho
        rp = w * (MA + SA * za) + (1 - w) * (MB + SB * zb)
        s += rp; s2 += rp * rp
    m = s / n
    return m, sqrt(s2 / n - m * m)

pct = lambda v: f"{100 * v:.2f}%"
cov = RHO * SA * SB
mean60 = W * MA + (1 - W) * MB
v_f = formula_var(W, RHO)
states, mean_l, v_l = ledger(W, RHO)
m_sim, sd_sim = simulate(W, RHO)
avg_sd = W * SA + (1 - W) * SB
print("inputs: shares 8.00% mean, 20.00% spread; bonds 4.00%, 6.00%; correlation 0.2")
print(f"covariance rho*sA*sB            {cov:.6f}")
print(f"variances vA, vB; d = vA+vB-2c   {SA*SA:.6f} {SB*SB:.6f} {SA*SA + SB*SB - 2*cov:.6f}")
print(f"60-40 pieces w^2vA, (1-w)^2vB, 2w(1-w)c  {W*W*SA*SA:.6f} {(1-W)**2*SB*SB:.6f} {2*W*(1-W)*cov:.6f}")
print(f"60-40 mean, weighted average    {pct(mean60)}")
print(f"60-40 variance, formula         {v_f:.6f}")
print(f"60-40 variance, ledger          {v_l:.6f}")
print(f"60-40 spread, formula           {pct(sqrt(v_f))}")
print(f"60-40 spread, ledger            {pct(sqrt(v_l))}")
print(f"60-40 mean and spread, simulated {pct(m_sim)} {pct(sd_sim)} (200000 draws)")
print(f"simulation gap in mean, std error {100 * abs(m_sim - mean60):.2f} {100 * sqrt(v_f / 200000):.2f} points")
print(f"weighted average of spreads     {pct(avg_sd)}")
print(f"diversification saves           {100 * (avg_sd - sqrt(v_f)):.2f} points")
print(f"one-spread range for the year   {pct(mean60 - sqrt(v_f))} to {pct(mean60 + sqrt(v_f))}")
print("ledger on $1,000: prob, shares ret, bonds ret, shares $, bonds $, total $, portfolio ret")
for p, ra, rb, sh, bo, rp in states:
    print(f"  {p:.2f}  {pct(ra):>7} {pct(rb):>7}  {sh:7.2f} {bo:7.2f} {sh + bo:8.2f}  {pct(rp):>7}")
assert abs(v_l - v_f) < 1e-12 and abs(mean_l - mean60) < 1e-12
assert abs(sd_sim - sqrt(v_f)) < 0.002 and abs(m_sim - mean60) < 0.003

# least-risk weight: completing the square, then a search on the ledger
d = SA * SA + SB * SB - 2 * cov
w_star = (SB * SB - cov) / d
lo, hi = 0.0, 1.0
for _ in range(200):                  # ternary search: keep the lower third
    a, b = lo + (hi - lo) / 3, hi - (hi - lo) / 3
    if ledger(a, RHO)[2] < ledger(b, RHO)[2]: hi = b
    else: lo = a
w_search = (lo + hi) / 2
assert abs(w_search - w_star) < 1e-7
v_star = formula_var(w_star, RHO)
print(f"least-risk weight, formula      {w_star:.6f} ({pct(w_star)})")
print(f"w* > 0 needs rho below sB/sA    {SB / SA:.6f}")
print(f"least-risk weight, search       {w_search:.6f}")
print(f"least-risk mix mean, spread     {pct(w_star * MA + (1 - w_star) * MB)} {pct(sqrt(v_star))}")
print(f"variance check V(w*)+d(0.6-w*)^2 {v_star + d * (W - w_star) ** 2:.6f}")
w_hedge = SB / (SA + SB)              # perfect negative correlation: spreads cancel
v_hedge = ledger(w_hedge, -1.0)[2]
assert v_hedge < 1e-15
print(f"rho=-1 zero-risk weight         {w_hedge:.6f} ({pct(w_hedge)}), mean {pct(w_hedge * MA + (1 - w_hedge) * MB)}, ledger variance {v_hedge:.6f}")

print("curve: shares %, mean, spread at rho=1, rho=0.2, rho=-1")
for k in range(11):
    w = k / 10
    row = [sqrt(ledger(w, r)[2]) for r in (1.0, 0.2, -1.0)]
    assert abs(row[1] ** 2 - formula_var(w, 0.2)) < 1e-12 and row[1] <= row[0] + 1e-12
    print(f"  {10 * k:3d}  {pct(w * MA + (1 - w) * MB)}  " + "  ".join(pct(v) for v in row))
print("60-40 spread by correlation")
for r in (-1.0, -0.5, 0.0, 0.2, 0.5, 1.0):
    print(f"  rho {r:+.1f}  {pct(sqrt(formula_var(W, r)))}")

print("what breaks, 60-40:")
print(f"  average the spreads            {pct(avg_sd)}")
print(f"  drop the cross term            {pct(sqrt(W*W*SA*SA + (1-W)**2*SB*SB))}")
print(f"  cross term without the 2       {pct(sqrt(W*W*SA*SA + (1-W)**2*SB*SB + W*(1-W)*cov))}")
print(f"  weights not squared            {pct(sqrt(W*SA*SA + (1-W)*SB*SB + 2*W*(1-W)*cov))}")
print("try changing:")
print(f"  50-50 mix                      {pct(0.5*MA + 0.5*MB)} {pct(sqrt(formula_var(0.5, RHO)))}")
print(f"  80-20 mix                      {pct(0.8*MA + 0.2*MB)} {pct(sqrt(formula_var(0.8, RHO)))}")
print(f"  least-risk weight at rho=0.5   {(SB*SB - 0.5*SA*SB) / (SA*SA + SB*SB - SA*SB):.6f}")
print("All checks passed.")
