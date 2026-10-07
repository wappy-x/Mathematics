# Numerical derivatives -- the check behind the card.  Python standard library
# only.  The function is the Black-Scholes call price C(S) on the library's
# finance example (K = 100, r = 5%, q = 2%, sigma = 20%, T = 1 year), bumped
# around S = 100.  Road one: difference quotients at 13 step sizes.  Road two:
# the exact delta from its closed form.  Truncation laws and rounding checked.
import math
S0, K, r, q, sig, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
def phi(x): return math.exp(-x * x / 2) / math.sqrt(2 * math.pi)   # bell height
def N(x):                          # bell-curve area left of x, by its own series
    term, total, k = x, x, 0
    while abs(term) > 1e-18 * abs(total):
        k += 1; term *= x * x / (2 * k + 1); total += term
    return 0.5 + phi(x) * total
def d1_of(S): return (math.log(S / K) + (r - q + sig * sig / 2) * T) / (sig * math.sqrt(T))
def call(S):
    d1 = d1_of(S)
    return S * math.exp(-q * T) * N(d1) - K * math.exp(-r * T) * N(d1 - sig * math.sqrt(T))
def cents(S): return math.floor(call(S) * 100 + 0.5) / 100            # a quoted price
def kink(S): return max(S - K, 0.0)                                    # value on expiry day
def fwd(f, h): return (f(S0 + h) - f(S0)) / h
def ctr(f, h): return (f(S0 + h) - f(S0 - h)) / (2 * h)
def lg(x): return math.log(abs(x)) / math.log(10)
d1 = d1_of(S0)
delta = math.exp(-q * T) * N(d1)                                      # road two
c2 = math.exp(-q * T) * phi(d1) / (S0 * sig * math.sqrt(T))           # C'' (gamma)
c3 = -c2 / S0 * (1 + d1 / (sig * math.sqrt(T)))                       # C'''
print(f"call C(100) = {call(S0):.12f}; exact delta e^(-qT)N(d1) = {delta:.12f}")
print(f"C'' = {c2:.12f}; C''' = {c3:.12f}")
steps = [("1", 1.0), ("0.1", 0.1), ("0.01", 0.01), ("1e-3", 1e-3), ("1e-4", 1e-4),
         ("1e-5", 1e-5), ("1e-6", 1e-6), ("1e-7", 1e-7), ("1e-8", 1e-8), ("1e-9", 1e-9),
         ("1e-10", 1e-10), ("1e-11", 1e-11), ("1e-12", 1e-12)]
err_c = {}
for lab, h in steps:
    f, c = fwd(call, h), ctr(call, h)
    err_c[lab] = abs(c - delta)
    print(f"h={lab}: forward {f:.12f} log10 err {lg(f - delta):.2f}; central {c:.12f} log10 err {lg(c - delta):.2f}")
print(f"h=1 by hand: C(101) = {call(101.0):.12f}; C(99) = {call(99.0):.12f}; forward err {fwd(call, 1.0) - delta:+.12f} "
      f"vs h C''/2 = {c2 / 2:+.12f}; central err {ctr(call, 1.0) - delta:+.12f} vs h^2 C'''/6 = {c3 / 6:+.12f}")
rf = (fwd(call, 0.01) - delta) / (0.01 * c2 / 2)      # observed over predicted
rc = (ctr(call, 0.1) - delta) / (0.1 ** 2 * c3 / 6)
print(f"truncation law: forward err / (h C''/2) at h=0.01 = {rf:.5f}; central err / (h^2 C'''/6) at h=0.1 = {rc:.5f}; "
      f"kink max(S-100,0) at h=1, 1e-6: forward {fwd(kink, 1.0):.3f}, {fwd(kink, 1e-6):.3f}; central {ctr(kink, 1.0):.3f}, {ctr(kink, 1e-6):.3f}")
eta = 2.0 ** -52 * call(S0)                           # one unit of rounding in C
print(f"best step: doubles (eta {eta * 1e15:.2f}e-15) forward {2 * math.sqrt(eta / c2):.8f}, central {(3 * eta / -c3) ** (1 / 3):.5f}; "
      f"cents (eta 0.005) forward {2 * math.sqrt(0.005 / c2):.2f}, central {(3 * 0.005 / -c3) ** (1 / 3):.2f}")
cq = {lab: ctr(cents, h) for lab, h in (("0.01", 0.01), ("0.1", 0.1), ("1", 1.0), ("3", 3.0))}
print("cent-rounded prices, central: " + "; ".join(f"h={lab} {v:.4f} err {v - delta:+.4f}" for lab, v in cq.items()))
assert abs(ctr(call, 1e-4) - delta) < 1e-9          # the two roads meet
assert abs(rf - 1) < 1e-3 and abs(rc - 1) < 1e-3     # truncation shrinks as h, h^2
assert err_c["1e-12"] > 1000 * err_c["1e-4"]         # too small a step: rounding wins
assert abs(cq["0.01"] - delta) > 100 * abs(cq["3"] - delta)   # coarse prices want a big step
print("ALL CHECKS PASS")
