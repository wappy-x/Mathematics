# The par swap rate and its annuity on a five-year annual swap, by three roads.
# Standard library only: no imported finance, no imported root finder.

FWD = [0.050, 0.046, 0.043, 0.041, 0.040]   # one-year forward rates, years 1..5
N = 10_000_000.0                             # notional, dollars
K_HOUSE = 0.045                              # the house swap's fixed rate


def discount_factors(fwd):
    """D(i): chain the one-year growth factors and invert."""
    out, d = [], 1.0
    for f in fwd:
        d = d / (1.0 + f)
        out.append(d)
    return out


def payer_value_per_unit(fwd, k):
    """Pay k, receive the forward, valued backwards one year at a time.
    No discount factor and no annuity is formed: W(i-1) = (W(i) + f_i - k) / (1 + f_i)."""
    w = 0.0
    for f in reversed(fwd):
        w = (w + f - k) / (1.0 + f)
    return w


def par_bond_price(fwd, c):
    """A bond paying coupon c each year and 1 at the end, valued backwards."""
    v = 1.0 + c
    for i in range(len(fwd) - 1, 0, -1):
        v = v / (1.0 + fwd[i]) + c
    return v / (1.0 + fwd[0])


def bisect(g, lo, hi, tol=1e-15):
    glo = g(lo)
    for _ in range(200):
        mid = 0.5 * (lo + hi)
        gm = g(mid)
        if (gm > 0) == (glo > 0):
            lo, glo = mid, gm
        else:
            hi = mid
        if hi - lo < tol:
            break
    return 0.5 * (lo + hi)


def par_and_annuity(fwd):
    d = discount_factors(fwd)
    a = sum(d)
    return (1.0 - d[-1]) / a, a


D = discount_factors(FWD)
A = sum(D)
S1 = (1.0 - D[-1]) / A                                   # road 1: floating leg telescopes
W = [d / A for d in D]
S2 = sum(w * f for w, f in zip(W, FWD))                   # road 2: weighted forwards
S3 = bisect(lambda c: par_bond_price(FWD, c) - 1.0, 0.0, 0.2)   # road 3: par bond
h = 1e-4
A_bump = (payer_value_per_unit(FWD, S1 - h) - payer_value_per_unit(FWD, S1 + h)) / (2 * h)
V_house = N * payer_value_per_unit(FWD, K_HOUSE)          # pay 4.5%, by recursion
V_formula = N * A * (S1 - K_HOUSE)                        # pay 4.5%, by the annuity

print("year  forward %   growth G(i)      D(i)    weight %  weight x fwd %")
for i, (f, d, w) in enumerate(zip(FWD, D, W), 1):
    print(f"{i:>4}  {100*f:9.2f}  {1/d:12.6f}  {d:9.6f}  {100*w:9.4f}  {100*w*f:13.6f}")
print(f"weights add to                    {sum(W):.6f}")
print(f"1 - D(5), per dollar of notional  {1-D[-1]:.6f}")
print(f"annuity A = sum of D(i)           {A:.6f}")
print(f"annuity by bumping the fixed rate {A_bump:.6f}")
print(f"road 1 (1 - D(5)) / A, %          {100*S1:.6f}")
print(f"road 2 weighted forwards, %       {100*S2:.6f}")
print(f"road 3 par bond by bisection, %   {100*S3:.6f}")
print(f"par rate, 2 decimals, %           {100*S1:.2f}")
print(f"notional $, house fixed rate %    {N:.2f}  {100*K_HOUSE:.2f}")
print(f"floating leg on 10m, $            {N*(1-D[-1]):.2f}")
print(f"fixed leg at par on 10m, $        {N*S1*A:.2f}")
print(f"one bp of fixed rate on 10m, $    {N*A*1e-4:.2f}")
print(f"house swap, pay 4.50%, recursion  {V_house:.2f}")
print(f"house swap, pay 4.50%, N A (S-K)  {V_formula:.2f}")
print(f"house fixed above par, bp         {1e4*(K_HOUSE-S1):.4f}")

z5 = D[-1] ** (-1 / 5) - 1
print("what breaks")
print(f"  plain average of forwards, %    {100*sum(FWD)/5:.6f}")
print(f"  par above plain average, bp     {1e4*(S1-sum(FWD)/5):.4f}")
print(f"  five-year zero rate, %          {100*z5:.6f}")
print(f"  annuity = 5, no discounting, %  {100*(1-D[-1])/5:.6f}")
print(f"  annuity from D(0)..D(4), %      {100*(1-D[-1])/(1+sum(D[:4])):.6f}")

print("chart: payer value on 10m against the fixed rate, $ thousands")
for k in (0.040, 0.042, 0.044, 0.046, 0.048, 0.050):
    print(f"  fixed {100*k:4.1f}%   {N*payer_value_per_unit(FWD, k)/1000:9.2f}")

print("try changing")
up = [f + 0.01 for f in FWD]
s_up, a_up = par_and_annuity(up)
print(f"  every forward +1%: par %, A      {100*s_up:.6f}  {a_up:.6f}")
rev = list(reversed(FWD))
s_rev, a_rev = par_and_annuity(rev)
print(f"  forwards reversed: par %, A      {100*s_rev:.6f}  {a_rev:.6f}")
s_flat, a_flat = par_and_annuity([S1] * 5)
print(f"  flat at the par rate: par %, A   {100*s_flat:.6f}  {a_flat:.6f}")
s_two, a_two = par_and_annuity(FWD[:2])
print(f"  two-year swap: par %, A          {100*s_two:.6f}  {a_two:.6f}")

D_E = [1.0, 1.0 / 1.042]           # interest-rate-swaps' curve: 4.2% deposit, then par quotes
for n, q in ((2, 0.0440), (3, 0.0455), (4, 0.0462), (5, 0.0465)):
    D_E.append((1.0 - q * sum(D_E[1:n])) / (1.0 + q))
F_E = [D_E[i - 1] / D_E[i] - 1.0 for i in range(1, 6)]
S_E, A_E = par_and_annuity(F_E)
V_E = N * payer_value_per_unit(F_E, K_HOUSE)
print("same swap on the curve of interest-rate-swaps")
print(f"  par %, A                         {100*S_E:.6f}  {A_E:.6f}")
print(f"  pay 4.50%: recursion, N A (S-K)  {V_E:.2f}  {N*A_E*(S_E-K_HOUSE):.2f}")

assert abs(S_E - 0.0465) < 1e-12, "that curve was built so the five-year par rate is 4.65%"
assert abs(V_E - N * A_E * (S_E - K_HOUSE)) < 1e-6, "value = N A (S - K) on that curve too"
assert abs(S2 - S1) < 1e-12, "weighted forwards must equal the telescoped ratio"
assert abs(S3 - S1) < 1e-12, "the par bond coupon must equal the par swap rate"
assert abs(A_bump - A) < 1e-9, "slope of value in the fixed rate must be the annuity"
assert abs(V_house - V_formula) < 1e-6, "recursion and N A (S - K) must agree"
assert min(FWD) < S1 < max(FWD), "a weighted average sits inside its range"
assert abs(S1 - 0.0442) < 5e-5, "the card's quoted 4.42%"
assert abs(A - 4.38) < 5e-3, "the card's quoted 4.38"
print("ALL CHECKS PASS")
