# Sequence spaces: the check behind the card.  Standard library only.
# A fading guitar note, one peak per cycle, x_n = 0.98^(n-1), and five test
# lists are sized in l1, l2 and the sup norm.  Nothing imported knows a norm:
# every sum is a plain loop and every power of 0.98 a repeated multiply.
# Roads: closed forms (geometric series, pi^2/6, ln 2 by its own series)
# against long partial sums; integral bounds for the sums that never settle;
# brute force over on/off patterns for separability.
import math

R, HZ = 0.98, 110                       # 2% peak loss per cycle; A string at 110 Hz (illustrative)
NS = (100, 10000, 1000000)              # where the partial sums are read

def norms(xs):                          # (l1, l2, sup) of a finite list, by loops
    s1 = s2 = top = 0.0
    for v in xs:
        s1 += abs(v); s2 += v * v; top = max(top, abs(v))
    return s1, math.sqrt(s2), top

def partial(term):                      # plain sum, sum |x_n|, sum x_n^2 at each N in NS
    s = s1 = s2 = 0.0; out = []
    for n in range(1, NS[-1] + 1):
        v = term(n); s += v; s1 += abs(v); s2 += v * v
        if n in NS: out.append((s, s1, s2))
    return out

def note_term():                        # 1, R, R^2, ... by repeated multiply
    st = [1.0 / R]
    def t(n):
        st[0] *= R; return st[0]
    return t

def row(label, vals):
    print(f"   {label:<20}" + "".join(f"{v:13.4f}" for v in vals))

print("1. the note: x_n = 0.98^(n-1), one peak per cycle")
five = [1.0]
for _ in range(4): five.append(five[-1] * R)
print("   first five peaks " + " ".join(f"{v:.8f}" for v in five))
print("   first five: l1 {:.4f}  l2 {:.4f}  sup {:.4f}".format(*norms(five)))
L1, E, L2 = 1 / (1 - R), 1 / (1 - R * R), 1 / math.sqrt(1 - R * R)
print(f"   whole note, closed form: l1 {L1:.4f}  sum of squares {E:.4f}  l2 {L2:.4f}  sup 1")

print("2. partial sums after N = 100, 10000, 1000000 entries")
lists = [("note", note_term()), ("1/n", lambda n: 1 / n),
         ("signed", lambda n: (1 if n % 2 else -1) / n),
         ("1/sqrt(n)", lambda n: 1 / math.sqrt(n)), ("held", lambda n: 1.0)]
P = {name: partial(t) for name, t in lists}
for name, _ in lists:
    if name == "signed":
        row("(-1)^(n+1)/n  sum x", [p[0] for p in P[name]])
        continue
    row(name + "  sum|x|", [p[1] for p in P[name]])
    row(name + "  sum x^2", [p[2] for p in P[name]])
print("   ramp x_n = n: largest entry " + ", ".join(str(n) for n in NS) + ": no ceiling")

print("3. second roads")
note, h, alt, rt, held = (P[k] for k, _ in lists)
assert abs(note[2][1] - L1) < 1e-9 and abs(note[2][2] - E) < 1e-9          # geometric series
basel = math.pi ** 2 / 6
N = NS[1]
em = h[1][2] + 1 / N - 1 / (2 * N * N) + 1 / (6 * N ** 3)                     # Euler-Maclaurin tail
print(f"   sum 1/n^2: to 10000 plus tail {em:.9f}; pi^2/6 {basel:.9f}; l2 norm of 1/n {math.sqrt(basel):.6f}")
assert abs(em - basel) < 1e-10
for (k, Nk) in enumerate(NS):
    assert math.log(Nk + 1) <= h[k][1] <= 1 + math.log(Nk)                    # harmonic squeeze
    assert 2 * math.sqrt(Nk + 1) - 2 <= rt[k][1] <= 2 * math.sqrt(Nk) - 1     # sum 1/sqrt(n) squeeze
    assert abs(rt[k][2] - h[k][1]) < 1e-9 and held[k][1] == Nk                 # squares of 1/sqrt(n) are 1/n
print(f"   harmonic minus ln N at 10^6: {h[2][1] - math.log(NS[2]):.6f} (Euler's constant plus 1/(2N))")
print(f"   gain from 10^4 to 10^6: {h[2][1] - h[1][1]:.6f}; 2 ln 10 = {2 * math.log(10):.6f}")
assert abs(h[2][1] - h[1][1] - 2 * math.log(10)) < 1e-4
ln2 = 0.0
for k in range(1, 61): ln2 += 1 / (k * 2.0 ** k)                            # ln 2 = sum 1/(k 2^k)
print(f"   signed sum at 10^6 {alt[2][0]:.6f}; ln 2 by its own series {ln2:.6f}")
assert abs(alt[2][0] - ln2) <= 1 / (NS[2] + 1) and abs(ln2 - math.log(2)) < 1e-15
assert abs(alt[2][1] - h[2][1]) < 1e-9                                    # signed list: sizes are 1/n

print("4. sup distance from each list to its cut after N entries")
cuts = list(range(0, 201, 25))
a, tails = 1.0, []
for n in range(201):
    if n in cuts: tails.append(a)
    a *= R
for n, t in zip(cuts, tails):
    assert abs(t - math.exp(n * math.log(R))) < 1e-12                          # two roads to R^N
print("   N      " + " ".join(f"{n:6d}" for n in cuts))
print("   note   " + " ".join(f"{t:6.4f}" for t in tails))
print("   1/sqrt " + " ".join(f"{1 / math.sqrt(n + 1):6.4f}" for n in cuts))
print("   held   " + " ".join(f"{1.0:6.4f}" for n in cuts))
x = [1.0]
while len(x) < 3000: x.append(x[-1] * R)
db60 = next(n for n in range(len(x)) if x[n] <= 0.001)                         # peak number db60+1
assert db60 == math.ceil(math.log(0.001) / math.log(R))
print(f"   -60 dB after {db60} cycles = {db60 / HZ:.2f} s")
t1, t2, _ = norms(x[100:])
assert abs(t1 - L1 * R ** 100) < 1e-9 and abs(t2 - L2 * R ** 100) < 1e-9
print(f"   cut at 100: l1 gap {t1:.4f}  l2 gap {t2:.4f}  sup gap {x[100]:.4f}")
approx = [round(v * 10000) / 10000 for v in x[:db60]]
gap = max(max(abs(v - q) for v, q in zip(x, approx)), max(x[db60:]))
print(f"   {db60} peaks rounded to 4 decimals, rest 0: sup distance {gap:.7f}")
assert gap <= 0.001

print("5. unit lists and on/off patterns")
e3 = [1.0 if n == 3 else 0.0 for n in range(1, 9)]
e7 = [1.0 if n == 7 else 0.0 for n in range(1, 9)]
d = norms([u - v for u, v in zip(e3, e7)])
print("   e_3 - e_7: l1 {:.4f}  l2 {:.4f}  sup {:.4f}".format(*d))
assert abs(d[0] - 2) < 1e-15 and abs(d[1] - math.sqrt(2)) < 1e-15 and d[2] == 1
S = 8
pats = [[(k >> (S - 1 - j)) & 1 for j in range(S)] for k in range(2 ** S)]
far = sum(1 for i in range(len(pats)) for j in range(i)
          if max(abs(u - v) for u, v in zip(pats[i], pats[j])) == 1)
print(f"   {S} slots: {len(pats)} patterns, {far} pairs, all at sup distance 1")
assert far == len(pats) * (len(pats) - 1) // 2
listed = [pats[(37 * k + 11) % 256] for k in range(S)]
diag = [1 - listed[k][k] for k in range(S)]
print("   listed " + " ".join("".join(map(str, p)) for p in listed) + "  diagonal " + "".join(map(str, diag)))
assert diag not in listed and [p for p in pats if all(p[k] != q[k] for k, q in enumerate(listed))] == [diag]  # brute force

print("6. try changing")
R2 = 0.99
print(f"   R = 0.99: l1 {1 / (1 - R2):.4f}  l2 {1 / math.sqrt(1 - R2 * R2):.4f}  -60 dB after "
      f"{math.ceil(math.log(0.001) / math.log(R2))} cycles = {math.ceil(math.log(0.001) / math.log(R2)) / HZ:.2f} s")
s1 = s2 = 0.0; got = []
for n in range(1, NS[-1] + 1):
    q = math.sqrt(n); v = 1 / (q * math.sqrt(q)); s1 += v; s2 += v * v
    if n in NS[1:]: got.append((s1, s2))
print(f"   fade n^(-3/4): sum|x| {got[0][0]:.4f} -> {got[1][0]:.4f}; sum x^2 {got[0][1]:.4f} -> {got[1][1]:.4f}")
print(f"   10 slots: {2 ** 10} patterns, {2 ** 10 * (2 ** 10 - 1) // 2} pairs")
pt = (0.6, 0.6)
print("figure, unit balls: diamond (+-1,0),(0,+-1); circle r 1; square (+-1,+-1); point (0.6, 0.6) "
      "l1 {:.4f} l2 {:.4f} sup {:.4f}; svg centre (210, 200), 150 px per unit".format(*norms(pt)))
print("ALL CHECKS PASS")
