# The August 2026 zeta-zeros claim -- the check behind the card.  Standard library only.
# It checks the claim's arithmetic and its counting step on small cases, never the theorem itself:
# the window constant Q(g) by quadrature against its closed form, a search for the best window,
# the counting lemma on random toy sets of "zeros", and the gaps between the dated records.
import math
from fractions import Fraction
N = 4000                                       # midpoint grid on the window's support [-w, w]
def Q(g, w=0.5, pairs=True):                   # (int g^2 + iint g(x) g(y) |x - y|) / (int g)^2
    h = 2 * w / N; xs = [-w + (k + 0.5) * h for k in range(N)]; v = [g(x) for x in xs]
    A = sum(v) * h; B = sum(t * t for t in v) * h
    C = S = Sx = 0.0                           # pairs j < i, by running sums: O(N), not O(N^2)
    for x, t in zip(xs, v):
        C += t * (x * S - Sx); S += t; Sx += t * x
    return (B + (2 * C * h * h if pairs else 0.0)) / (A * A)
r2 = math.sqrt(2)
q_flat = Q(lambda x: 1.0)                      # Montgomery's window (the Fejer kernel)
q_flat_exact = Fraction(1) + Fraction(1, 3)    # int 1 = 1, iint |x - y| over the unit square = 1/3
q_mt = Q(lambda x: math.cos(r2 * x))           # the Montgomery-Taylor window
q_mt_exact = 0.5 + 1 / (r2 * math.tan(1 / r2)) # closed form 1/2 + cot(1/sqrt 2)/sqrt 2
lo, hi = 0.5, 3.0                              # golden-section search over windows cos(a x)
phi = (math.sqrt(5) - 1) / 2
for _ in range(40):
    m1, m2 = hi - phi * (hi - lo), lo + phi * (hi - lo)
    if Q(lambda x: math.cos(m1 * x)) < Q(lambda x: math.cos(m2 * x)): hi = m2
    else: lo = m1
a_best = (lo + hi) / 2
q_tri = Q(lambda x: 1 - 2 * abs(x))            # a triangle window, for "Try changing"
q_a1 = Q(lambda x: math.cos(x))
C0 = 2 - q_mt_exact                            # simple and on the line
C1 = (C0 + 1) / 2                              # distinct
C2 = (1 + 2 * r2 + 2 * C0) / (3 + 2 * r2)      # simple or on the line (the second proof's extra)
print(f"window g = 1:            Q by quadrature {q_flat:.6f}, exact {q_flat_exact} = {float(q_flat_exact):.6f}")
print(f"  bound 2 - Q = {2 - q_flat:.6f} (exact {2 - q_flat_exact})")
print(f"window g = cos(sqrt2 x): Q by quadrature {q_mt:.6f}, closed form {q_mt_exact:.10f}")
print(f"  bound 2 - Q = {C0:.7f}")
print(f"best window cos(a x) by search: a = {a_best:.5f} (sqrt 2 = {r2:.5f}), Q = {Q(lambda x: math.cos(a_best * x)):.6f}")
print(f"other windows: triangle 1 - 2|x|: Q = {q_tri:.6f}, bound {2 - q_tri:.6f}; cos(x): Q = {q_a1:.6f}, bound {2 - q_a1:.6f}")
print(f"distinct (C0 + 1)/2 = {C1:.5f}; simple or on the line (1 + 2 sqrt2 + 2 C0)/(3 + 2 sqrt2) = {C2:.5f}")
def csin(a, b): return (math.sin(a) * math.cosh(b), math.cos(a) * math.sinh(b))
def K2(z, s):                                  # K(z - s)^2, K(w) = sin(pi w)/(pi w); real part of the pair sum
    a, b = (z[0] - s[0]) * math.pi, (z[1] - s[1]) * math.pi
    if a == 0 and b == 0: return (1.0, 0.0)
    sr, si = csin(a, b); d = a * a + b * b
    kr, ki = (sr * a + si * b) / d, (si * a - sr * b) / d
    return (kr * kr - ki * ki, 2 * kr * ki)
def lemma(Z):                                  # (simple points on the real line, 2 #Z - sum K^2)
    simple = sum(1 for z in Z if z[1] == 0 and Z.count(z) == 1)
    return simple, 2 * len(Z) - sum(K2(z, s)[0] for z in Z for s in Z)
state = 20260813                               # SplitMix64, seed stated
def rnd():
    global state
    state = (state + 0x9E3779B97F4A7C15) % 2 ** 64; z = state
    z = ((z ^ (z >> 30)) * 0xBF58476D1CE4E5B9) % 2 ** 64; z = ((z ^ (z >> 27)) * 0x94D049BB133111EB) % 2 ** 64
    return ((z ^ (z >> 31)) >> 11) / 2 ** 53
worst, worst_off, offline_sets, trials = 1e9, 1e9, 0, 4000
for _ in range(trials):
    Z, off = [], False
    for _ in range(1 + int(rnd() * 5)):
        x = -3 + 6 * rnd()
        if rnd() < 0.4:
            y = 0.01 + 0.99 * rnd(); Z += [(x, y), (x, -y)]; off = True
        else:
            Z += [(x, 0.0)] * [1, 1, 1, 2, 3][int(rnd() * 5)]
    s, b = lemma(Z); worst = min(worst, s - b); offline_sets += off
    if off: worst_off = min(worst_off, s - b)  # the twin case on its own
print(f"counting lemma, {trials} random toy sets ({offline_sets} with off-line pairs): smallest slack {round(worst, 6) + 0.0:.6f}")
print(f"  smallest slack among the sets with off-line pairs: {worst_off:.6f}")
mult = max(m * (2 - m) - (1 if m == 1 else 0) for m in range(1, 50))
print(f"one point of multiplicity m: m(2 - m) minus [m = 1] is at most {mult}, checked for m <= 49")
toy = [(0.0, 0.0), (1.5, 0.0), (3.0, 0.3), (3.0, -0.3), (5.0, 0.0), (5.0, 0.0)]
s, b = lemma(toy)
naive = sum(1 for z in toy if toy.count(z) == 1)
pair = K2((3.0, 0.3), (3.0, -0.3))[0]
print(f"toy set, 6 zeros: simple on the line {s}; lemma bound {b:.4f}; naive count of lone points {naive}")
print(f"  off-line pair 3 +- 0.3i: cross term K(0.6i)^2 = {pair:.4f}, so the pair costs {2 + 2 * pair:.4f} against a double zero's 4")
pair2 = K2((3.0, 0.05), (3.0, -0.05))[0]      # twins pulled toward the line
print(f"  pull the twins to 3 +- 0.05i: the pair costs {2 + 2 * pair2:.4f}")
q_wide = Q(lambda x: 1.0, w=1.0)               # window on [-1, 1]: reaches alpha = 2, |alpha| proved only to 1
q_diag = Q(lambda x: 1.0, pairs=False)         # self-pairs only, the |alpha| term dropped
rec = [("Levinson 1974, on the line", 0.3474), ("Conrey 1989, on the line", 0.4088),
       ("PRZZ 2020, on the line", 0.417293), ("2026 claim, simple + line", round(C0, 6)),
       ("ceiling of this method", 0.682), ("Riemann hypothesis says", 1.0)]
for name, x in rec:
    print(f"bars, {name:27s} {'#' * round(40 * x):40s} {x:.4f}")
print(f"five-twelfths = {5 / 12:.6f}; PRZZ simple and on the line 0.407511; rise 0.417293 -> {C0:.4f}, ratio {C0 / 0.417293:.3f}")
print(f"left unplaced by the claim: at most {1 - C0:.4f} of all zeros")
print(f"what breaks: drop the |alpha| term: bound {2 - q_diag:.4f}; window past alpha = 1: bound {2 - q_wide:.4f}; "
      f"0.6725 x 29 zeros below height 100 = {0.6725 * 29:.2f}, true count on the line 29 (quoted)")
print("ledger: statement  simple-and-on-the-line share of zeta zeros >= 0.6725007 (liminf, with multiplicity)")
print("ledger: artifact   preprint v1 2026-08-13, v2 2026-08-19; Lean 4 formalisation reported, not run here")
print("ledger: check      independent second proof, preprint v1 2026-09-02; follow-up 0.67353, preprint 2026-10-06")
print("ledger: check      second proof's key inequality: formal certificate by an outside machine prover, not run here")
print("ledger: status     statement proved from 2026-11-21: RH (formal proof certified) with Montgomery-Taylor 1975")
print("ledger: status     the preprints' proof without RH: claimed, not refereed, as of 2026-11-23")
assert abs(q_flat - float(q_flat_exact)) < 1e-6 and abs(q_mt - q_mt_exact) < 1e-6     # quadrature vs closed form
assert abs(a_best - r2) < 0.01 and abs(Q(lambda x: math.cos(a_best * x)) - q_mt_exact) < 1e-6  # search finds sqrt 2
assert abs(C0 - 0.6725007) < 1e-7 and abs(C1 - 0.83625) < 1e-5 and abs(C2 - 0.88762) < 1e-5     # the papers' quoted constants
assert worst > -1e-9 and offline_sets > 1000 and mult <= 0                    # counting lemma holds on every toy set
assert s == 2 and naive == 4 and b <= s + 1e-9 and pair > pair2 > 1                    # off-line pair priced like a double zero
assert q_tri > q_mt_exact and q_a1 > q_mt_exact and abs(q_wide - 7 / 6) < 1e-6 and abs(q_diag - 1) < 1e-9  # hand values
print("ALL CHECKS PASS")
