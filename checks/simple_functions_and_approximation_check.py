# Simple functions and the dyadic staircase: the check behind the card.
# Standard library only; Fraction keeps every length and energy exact.
from fractions import Fraction as F
W = [400, 350, 300, 300, 300, 350, 800, 1900, 1400, 700, 600, 600, 900,
     700, 600, 600, 800, 1600, 2700, 3100, 2400, 1700, 1100, 600, 400]
TOP = F(10**9)                          # "no upper edge" for the cap band, in W

def f6(x, d=6): return f"{float(x):.{d}f}"

def band_len(v0, v1, a, b):             # hours of one hour-segment where a <= p < b
    if v0 == v1: return F(int(a <= v0 < b))
    lo, hi = sorted([(a - v0) / F(v1 - v0), (b - v0) / F(v1 - v0)])
    return max(F(0), min(F(1), hi) - max(F(0), lo))

def ge_len(v0, v1, c):                  # hours of one hour-segment where p >= c
    if v0 == v1: return F(int(v0 >= c))
    u = min(F(1), max(F(0), (c - v0) / F(v1 - v0)))
    return 1 - u if v1 > v0 else u

def pieces(n):                          # standard form: (value in kW, hours at that value)
    d = 2**n; out = []
    for j in range(n * d + 1):
        a = F(1000 * j, d); b = F(1000 * (j + 1), d) if j < n * d else TOP
        out.append((F(j, d), sum(band_len(W[i], W[i + 1], a, b) for i in range(24))))
    return out

def layers(n):                          # road 2: sum over k of 2^-n times hours with p >= k 2^-n
    d = 2**n
    return sum(F(1, d) * sum(ge_len(W[i], W[i + 1], F(1000 * k, d)) for i in range(24))
               for k in range(1, n * d + 1))

# road 3: one sample per second, at the middle of the second; power in kW is x / U
U = 7_200_000
P = [7200 * W[h] + (W[h + 1] - W[h]) * (2 * m + 1) for h in range(24) for m in range(3600)]
def stair(n, x): return min(n * 2**n, (2**n * x) // U)   # s_n in units of 2^-n kW

print("readings, kW, hours 0 to 24:", " ".join(f"{w / 1000:.2f}" for w in W))
E_trap = F(sum(W[i] + W[i + 1] for i in range(24)), 2000)
E_mid = F(sum(P), U * 3600)
assert E_trap == E_mid
print("energy of the curve: trapezoids", f6(E_trap), "kWh; 86400 midpoints", f6(E_mid), "kWh")

cross = {c: [i + F(c - W[i], W[i + 1] - W[i]) for i in range(24)
             if (W[i] - c) * (W[i + 1] - c) < 0] for c in (500, 1000)}
for c in (500, 1000):
    print(f"p = {c / 1000:.1f} kW at hours", ", ".join(f6(t, 4) for t in cross[c]))
print("stage 1 standard form: value kW, hours")
for v, L in pieces(1): print(f"  {f6(v, 1)}, {f6(L)}")
over = all(500 * ((1000 * x >= 500 * U) + (1000 * x >= 1000 * U)) == 500 * stair(1, x) for x in P)
print("stage 1 as 0.5 1{p >= 0.5} + 0.5 1{p >= 1}, same at all 86400 samples:", "yes" if over else "no")
assert over

print("n, step kW, grid levels, E_n by pieces, by layers, by samples, gap to E, 24/2^n")
prev, chart = F(0), []
for n in range(1, 9):
    pc = pieces(n); En = sum(v * L for v, L in pc); Ek = layers(n)
    Es = F(sum(stair(n, x) for x in P), 2**n * 3600)
    assert En == Ek and abs(En - Es) < F(1, 1000) and En > prev
    assert sum(L for _, L in pc) == 24
    if n >= 4: assert 0 < E_trap - En <= F(24, 2**n)
    prev = En
    chart.append(f"{float(En):.2f}")
    print(f"{n}, 1/{2**n}, {len(pc)}, {f6(En)}, {f6(Ek)}, {f6(Es)}, {f6(E_trap - En)}, {f6(F(24, 2**n))}")

print("chart, E_n in kWh for n = 1 to 8:", " ".join(chart))
print("largest sampled gap p - s_n, kW, against 2^-n")
for n in range(1, 9):
    assert all(2 * stair(n, x) <= stair(n + 1, x) and U * stair(n, x) <= 2**n * x for x in P)
    g = F(max(2**n * x - U * stair(n, x) for x in P), U * 2**n)
    if n >= 4: assert g < F(1, 2**n)
    print(f"  n={n}: {f6(g)} against {f6(F(1, 2**n), 8)}")

print("at 19:00, p = 3.1 kW: n, s_n, error, 2^-n")
for n in range(1, 9):
    s = F(min(n * 2**n, (2**n * 31) // 10), 2**n)
    assert s <= F(31, 10) and (n < 4 or F(31, 10) - s < F(1, 2**n))
    print(f"  {n}, {f6(s, 8)}, {f6(F(31, 10) - s, 8)}, {f6(F(1, 2**n), 8)}")

def near(n, x): return (2**(n + 1) * x + U) // (2 * U)      # nearest multiple of 2^-n, uncapped
above = sum(near(2, x) * U > 4 * x for x in P)
drop = sum(near(2, x) < 2 * near(1, x) for x in P)
thirds = sum(2 * ((3 * x) // U) < 3 * ((2 * x) // U) for x in P)
print("nearest instead of down, n=2: seconds above the curve", above, "/ seconds below stage 1", drop)
print("steps of 1/2 then 1/3 kW: seconds where the 1/3 staircase is lower", thirds)
assert above > 0 and drop > 0 and thirds > 0
vals = len({(4 * 10000) // j for j in range(1, 10001)})
assert vals > 2 * 4 + 1
print("1/x on (0,1] at x = j/10000: uncapped stage 2 takes", vals, "values; capped stage 2 at most", 2 * 4 + 1)
net = F(900 - 1500, 1000); pos, neg = max(net, 0), max(-net, 0)
sp, sn = [F((2**4 * y.numerator) // y.denominator, 2**4) for y in (pos, neg)]
assert pos - neg == net and 0 <= (sp - sn) - net < F(1, 2**4)
print(f"12:00 with 1.5 kW solar: net {f6(net, 4)}, parts {f6(pos, 4)} and {f6(neg, 4)}, stage 4 {f6(sp - sn, 4)}")
print("figure, x = 36 + 13 t, y = 210 - 50 p; stage-1 corners at x =",
      ", ".join(f"{36 + 13 * float(t):.2f}" for t in sorted(cross[500] + cross[1000])))
