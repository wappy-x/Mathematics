# Random numbers from a computer -- the check behind the card.  Standard library
# only, no random module: every generator is written out here.  Roads: rule
# against brute force, stepping against jumping ahead against published values,
# and statistical tests whose own yardstick is checked against a printed table.
import math
M32, M64, P = 2**32 - 1, 2**64 - 1, 2**31 - 1

def lcg(a, c, m, x, n):                        # n outputs of x -> (a x + c) mod m
    out = []
    for _ in range(n):
        x = (a * x + c) % m
        out.append(x)
    return out

def cycle(a, c, m, x):                         # length of the loop the seed falls into
    seen, n = {}, 0
    while x not in seen:
        seen[x], x, n = n, (a * x + c) % m, n + 1
    return n - seen[x]

def powmod(b, e, m):                           # square-and-multiply, to jump ahead
    r = 1
    while e:
        if e & 1: r = r * b % m
        b, e = b * b % m, e >> 1
    return r

class MT:                                      # MT19937, Matsumoto and Nishimura 1998
    def __init__(self, seed):
        self.s = [seed]
        for i in range(1, 624):
            self.s.append((1812433253 * (self.s[-1] ^ (self.s[-1] >> 30)) + i) & M32)
        self.i = 624
    def next32(self):
        s = self.s
        if self.i == 624:                      # refill all 624 words at once
            for k in range(624):
                y = (s[k] & 0x80000000) | (s[(k + 1) % 624] & 0x7FFFFFFF)
                s[k] = s[(k + 397) % 624] ^ (y >> 1) ^ (0x9908B0DF * (y & 1))
            self.i = 0
        y = s[self.i]; self.i += 1
        y ^= y >> 11; y ^= (y << 7) & 0x9D2C5680; y ^= (y << 15) & 0xEFC60000
        return y ^ (y >> 18)
    def u(self): return self.next32() / 2**32

def splitmix(state):                           # SplitMix64: a counter, then a scrambler
    state = (state + 0x9E3779B97F4A7C15) & M64
    z = ((state ^ (state >> 30)) * 0xBF58476D1CE4E5B9) & M64
    z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) & M64
    return state, z ^ (z >> 31)

def chi2(draw, n=10000, k=10):                 # counts in k equal bins, and the statistic
    obs = [0] * k
    for _ in range(n): obs[int(draw() * k)] += 1
    return obs, sum((o - n / k) ** 2 / (n / k) for o in obs)

def pvalue(x, steps=2000):                     # chance a true uniform scores above x, for
    g = 3.5 * 2.5 * 1.5 * 0.5 * math.sqrt(math.pi)    # 9 degrees of freedom, by Simpson's rule
    f = lambda t: t ** 3.5 * math.exp(-t / 2) / (2 ** 4.5 * g)
    h = x / steps
    s = f(0) + f(x) + sum((4 if j % 2 else 2) * f(j * h) for j in range(1, steps))
    return 1 - s * h / 3

def stream(a, m, x):                           # an LCG without increment, as u in [0, 1)
    def draw():
        nonlocal x
        x = a * x % m
        return x / m
    return draw

def darts(seed, n=100000):                     # the house example: darts at a unit square
    g, hits = MT(seed), 0
    for _ in range(n):
        x, y = g.u(), g.u()
        hits += x * x + y * y < 1
    p = hits / n
    return 4 * p, 4 * math.sqrt(p * (1 - p) / n)

yn = lambda b: "yes" if b else "no"
toy = lcg(5, 3, 16, 7, 16)
pairs = sorted(zip([7] + toy[:15], toy))
print(f"toy,x -> (5x + 3) mod 16,seed 7,outputs {toy},cycle {cycle(5, 3, 16, 7)}")
print(f"toy,u = x/16,first four {', '.join(f'{x / 16:.4f}' for x in toy[:4])},last bits {[x & 1 for x in toy[:12]]}")
print(f"figure,pairs {pairs},values of x + 3y {sorted({x + 3 * y for x, y in pairs})}")
rule_ok = True
for m in (16, 64):
    brute = [(a, c) for a in range(m) for c in range(m) if cycle(a, c, m, 0) == m]
    rule = [(a, c) for a in range(m) for c in range(m) if c % 2 == 1 and a % 4 == 1]
    rule_ok = rule_ok and brute == rule
    print(f"full cycle,m {m},pairs by brute force {len(brute)},by the rule {len(rule)},same pairs {yn(brute == rule)}")
print(f"cycle,(5x + 2) mod 16 from 7: {cycle(5, 2, 16, 7)},(3x + 3) mod 16 from 7: {cycle(3, 3, 16, 7)},"
      f"(x + 1) mod 16: {cycle(1, 1, 16, 7)} {lcg(1, 1, 16, 7, 6)}")
step, jump = lcg(16807, 0, P, 1, 10000)[-1], powmod(16807, 10000, P)
print(f"minstd,x -> 16807x mod (2^31 - 1),seed 1,10000th by stepping {step},by jumping {jump},published 1043618065")
g = MT(5489)
mt_out = [g.next32() for _ in range(10000)]
print(f"mt19937,seed 5489,first {mt_out[0]},10000th {mt_out[-1]},published 10000th 4123659995")
s, sm = 0, []
for _ in range(10000):
    s, z = splitmix(s)
    sm.append(z)
jump_sm = splitmix((10000 - 1) * 0x9E3779B97F4A7C15 & M64)[1]   # the counter jumps straight there
print(f"splitmix64,seed 0,first {sm[0]:016x},10000th by stepping {sm[-1]:016x},by jumping {jump_sm:016x}")
print(f"chi-square,table 5% point for 9 degrees of freedom 16.919,p by Simpson {pvalue(16.919):.4f}")
pv = []
for name, draw in [("mt19937 seed 20260929", MT(20260929).u), ("minstd seed 1", stream(16807, P, 1)),
                   ("randu seed 1", stream(65539, 2**31, 1))]:
    obs, x2 = chi2(draw)
    pv.append(pvalue(x2))
    print(f"uniformity,{name},10000 draws in 10 bins (1000 expected in each) {obs},chi-square {x2:.2f},p {pv[-1]:.4f}")
low = sum(1 for sd in range(1, 101) if pvalue(chi2(MT(sd).u)[1]) < 0.05)
print(f"uniformity,mt19937 seeds 1 to 100,tests with p below 0.05: {low} of 100")
r = lcg(65539, 0, 2**31, 1, 10002)
g = MT(20260929)
w = [g.next32() >> 1 for _ in range(10002)]
on = sum(1 for i in range(10000) if (9 * r[i] - 6 * r[i + 1] + r[i + 2]) % 2**31 == 0)
planes = len({(9 * r[i] - 6 * r[i + 1] + r[i + 2]) // 2**31 for i in range(10000)})
on_mt = sum(1 for i in range(10000) if (9 * w[i] - 6 * w[i + 1] + w[i + 2]) % 2**31 == 0)
print(f"triples,randu,9x - 6y + z a multiple of 2^31 in {on} of 10000,planes {planes},mt19937 {on_mt} of 10000")
s1, s2 = lcg(16807, 0, P, 1, 1000), lcg(16807, 0, P, 2, 1000)
twice = sum(1 for a, b in zip(s1, s2) if b == 2 * a % P)
print(f"seeds,minstd seed 1 {', '.join(f'{x / P:.6f}' for x in s1[:3])},seed 2 {', '.join(f'{x / P:.6f}' for x in s2[:3])},"
      f"seed-2 output = 2 x seed-1 output mod m in {twice} of 1000")
(a1, se1), (a2, _), (b1, seb) = darts(20260929), darts(20260929), darts(20260930)
print(f"darts,100000 each,seed 20260929 run 1 {a1:.5f} ({round(a1 * 25000)} hits),run 2 {a2:.5f},se {se1:.5f}")
print(f"darts,seed 20260930 {b1:.5f},se {seb:.5f},pi {math.pi:.5f},gap between seeds {abs(a1 - b1):.5f}")
assert sorted(toy) == list(range(16)) and all((x + 3 * y) % 16 == 9 for x, y in pairs)  # rule; x + 3y = 9 mod 16
assert rule_ok and cycle(5, 2, 16, 7) == cycle(3, 3, 16, 7) == 8  # rule = brute force; broken rule halves
assert step == jump == 1043618065                              # three roads to minstd's 10000th
assert mt_out[-1] == 4123659995 and sm[-1] == jump_sm          # published value; counter jump
assert abs(pvalue(16.919) - 0.05) < 1e-4                       # own integrator = printed table
assert on == 10000 and planes == 15 and on_mt < 5              # a^2 = 6a - 9 predicts the planes
assert twice == 1000                                           # algebra predicts the seed clone
assert round(a1 * 25000) == 78464 and a1 != b1                 # the Rust run's hits; new seed, new run
assert abs(a1 - math.pi) < 4 * se1 and abs(b1 - math.pi) < 4 * seb
assert min(pv) > 0.001 and low <= 14                           # 5 in 100 expected, sd about 2
print("ALL CHECKS PASS")
