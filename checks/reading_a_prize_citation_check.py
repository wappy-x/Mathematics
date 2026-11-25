# Prize citations -- the check behind the card.  Standard library only.
# Sort a citation's phrases, match results to papers, apply the status rule, compute small cases.
from math import isqrt, gcd
R, K, T, F = "result", "reproof", "tool", "field"
CITATIONS = [  # (citation, [(phrase, type read by hand)])
    ("Abel 2026 Faltings, short", [("introducing powerful tools in arithmetic geometry", T),
        ("resolving long-standing diophantine conjectures of Mordell", R),
        ("resolving long-standing diophantine conjectures of ... Lang", R)]),
    ("Abel 2026 Faltings, long", [("the Mordell conjecture ... proved by Faltings in 1983", R),
        ("resolving an important case of a conjecture of John Tate", R),
        ("resolving ... a conjecture of Igor Shafarevich", R),
        ("adapted this approach to prove ... the Mordell-Lang conjecture", R),
        ("also proved the finiteness of integral points on affine subvarieties of abelian varieties", R),
        ("gave a new proof of Roth's theorem and ... the Schmidt subspace theorem", K),
        ("major contributions to p-adic Hodge theory", F), ("tools introduced by Faltings ... the purity theorem", T),
        ("giving proofs of the main conjectures formulated by Tate and ... Fontaine", R),
        ("constructed an arithmetic compactification of these varieties", T)]),
    ("Fields 2022 Huh, short", [("bringing the ideas of Hodge theory to combinatorics", F),
        ("the proof of the Dowling-Wilson conjecture for geometric lattices", R),
        ("the proof of the Heron-Rota-Welsh conjecture for matroids", R),
        ("the development of the theory of Lorentzian polynomials", T),
        ("the proof of the strong Mason conjecture", R)]),
    ("Abel 2024 Talagrand, short", [("groundbreaking contributions to probability theory and functional analysis", F),
        ("outstanding applications in mathematical physics and statistics", F)]),
    ("Abel 2025 Kashiwara, short", [("fundamental contributions to algebraic analysis and representation theory", F),
        ("the development of the theory of D-modules", T), ("the discovery of crystal graphs", T)]),
    ("Breakthrough 2025 Gaitsgory", [("breakthrough contributions to the geometric Langlands program", F),
        ("the development of the derived algebraic geometry approach", T),
        ("the proof of the geometric Langlands conjecture in characteristic 0", R)]),
    ("Fields 2026 Wang, short", [("her work in harmonic analysis and geometric measure theory", F),
        ("applications of multiscale and decoupling techniques to the local smoothing conjecture", F),
        ("major advances in ... the Kakeya problem in three dimensions", F)]),
    ("Fields 2026 Wang, long", [("decoupling and multiscale arguments to resolve the local smoothing conjecture", R),
        ("fundamental progress in Fourier restriction theory", F), ("obtained major results on the Falconer distance set problem", F),
        ("breakthrough contributions to the theory of Furstenberg sets", F), ("major advances on the Kakeya problem in three dimensions", F),
        ("developed new bounds and structural techniques for collections of thin tubes", T)]),
]
def scan(phrase):                        # road two: the reading rule as keywords
    p = phrase.lower()
    if "new proof" in p: return K
    if any(w in p for w in ("proof of", "proofs of", "prove", "resolv")): return R
    if any(w in p for w in ("develop", "introduc", "discover", "construct")): return T
    return F
RESULTS = [  # (result as matched to its paper, refereed date, citation date if it names the proof)
    ("Mordell: genus >= 2, finitely many points", "1983-10", "2026-03-19"),
    ("Tate, maps of abelian varieties only", "1983-10", "2026-03-19"),
    ("Shafarevich, abelian varieties", "1983-10", "2026-03-19"),
    ("Mordell-Lang, general case (1994 paper)", "1994", "2026-03-19"),
    ("Lang, integral points (1991 paper)", "1991-05", "2026-03-19"),
    ("Tate-Fontaine, no single paper", None, None),
    ("Dowling-Wilson, realizable matroids", "2017", "2022-07-05"),
    ("Dowling-Wilson, all geometric lattices", "2026-07-01", "2022-07-05"),  # the short sentence's scope
    ("Heron-Rota-Welsh, matroids", "2018-09", "2022-07-05"), ("strong Mason", "2020-11", "2022-07-05"),
    ("geometric Langlands, characteristic 0", None, "2025-04-05"),
    ("local smoothing, planar wave", "2020-09", "2026-07-23"),
    ("Kakeya, three dimensions", "2026-11-06", None),
]
def accepted(ref, prize):                # the status rule: the earliest acceptance
    return min([d for d in (ref, prize) if d], default=None)
def days_civil(y, m, d):                 # road one: days since 1970-01-01, by formula
    y -= m <= 2; era = y // 400; yoe = y - era * 400
    doy = (153 * (m + (-3 if m > 2 else 9)) + 2) // 5 + d - 1
    return era * 146097 + yoe * 365 + yoe // 4 - yoe // 100 + doy - 719468
def days_table(m1, d1, m2, d2):          # road two: walk the month lengths of 2026
    return sum([31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][m1 - 1:m2 - 1]) - d1 + d2
def genus_formula(n): return (n - 1) * (n - 2) // 2
def interior(a, b):                      # lattice points strictly inside the triangle (0,0),(a,0),(0,b)
    return sum(1 for i in range(1, a) for j in range(1, b) if b * i + a * j < a * b)
HMAX = 1000                              # height: larger of the numerator and denominator of x
def elliptic_search():                   # road one: y^2 = x^3 - x + 1, x = a/e^2, y = b/e^3
    pts = []
    for e in range(1, isqrt(HMAX) + 1):
        for a in range(-HMAX, HMAX + 1):
            r = a ** 3 - a * e ** 4 + e ** 6
            if gcd(a, e) == 1 and r >= 0 and isqrt(r) ** 2 == r:
                pts += [max(abs(a), e * e)] * (2 if r else 1)
    return pts
def q(n, d):                             # an exact fraction n/d, in lowest terms
    g = gcd(n, d) * (1 if d > 0 else -1); return (n // g, d // g)
def sub(a, b): return q(a[0] * b[1] - b[0] * a[1], a[1] * b[1])
def mul(a, b): return q(a[0] * b[0], a[1] * b[1])
def div(a, b): return q(a[0] * b[1], a[1] * b[0])
def multiples(k_max):                    # road two: kP by the chord rule, P = (1, 1)
    one = (1, 1); x, y, hs = (-1, 1), (1, 1), [1, 1]   # 2P, from the tangent at P, slope 1
    for _ in range(3, k_max + 1):        # (k+1)P = kP + P, through the chord
        m = div(sub(y, one), sub(x, one))
        x3 = sub(sub(mul(m, m), x), one)
        x, y = x3, sub(mul(m, sub(one, x3)), one)
        hs.append(max(abs(x[0]), x[1]))
    return hs
def quartic_search():                    # x^4 + y^4 = 1 with x = a/c, y = b/c: a^4 + b^4 = c^4
    pts = []
    for c in range(1, HMAX + 1):
        for a in range(0, c + 1):
            r = c ** 4 - a ** 4; b = isqrt(isqrt(r))
            if b ** 4 == r and gcd(gcd(a, b), c) == 1:
                pts += [c] * ((2 if a else 1) * (2 if b else 1))
    return pts

print("phrases by type: result, reproof, tool or theory, field or progress")
counts = {cit: [sum(1 for _, t in ph if t == k) for k in (R, K, T, F)] for cit, ph in CITATIONS}
for cit, _ in CITATIONS: print(f"  {cit:30}" + "".join(f"{c:4}" for c in counts[cit]))
agree, total = sum(1 for _, ph in CITATIONS for text, t in ph if scan(text) == t), sum(len(ph) for _, ph in CITATIONS)
print(f"hand reading = keyword scan: {agree} of {total} phrases")
print(f"outside them, a refutation: 'answered ... in the negative' scans as {scan('he answered a longstanding question ... in the negative')}")
print("results matched to papers; status rule applied 2026-11-24")
print(f"  {'result':42}{'refereed':11}{'citation':12}{'accepted':12}by")
by_prize = []
for name, ref, prize in RESULTS:
    acc = accepted(ref, prize)
    who = "not set here" if acc is None else "citation" if acc == prize and acc != ref else "paper"
    if who == "citation": by_prize.append(name)
    print(f"  {name:42}{ref or '-':11}{prize or '-':12}{acc or '-':12}{who}")
print(f"accepted by the citation itself: {len(by_prize)} ({'; '.join(by_prize)})")
d_formula, d_table = days_civil(2026, 11, 6) - days_civil(2026, 7, 23), days_table(7, 23, 11, 6)
print(f"Kakeya read off the citation: 2026-07-23, refereed proof 2026-11-06: {d_formula} days early (formula), {d_table} (month table)")
print("genus of x^n + y^n = 1 by formula / by interior points: " +
      ", ".join(f"n={n} {genus_formula(n)}/{interior(n, n)}" for n in range(3, 7)))
print(f"genus of y^2 = x^3 - x + 1 by interior points: {interior(3, 2)}")
hs = multiples(16)
print("heights of kP, k = 1..16: " + " ".join(str(h) for h in hs))
ell, quart, HS = elliptic_search(), quartic_search(), (10, 100, 1000)
row_s = [sum(1 for h in ell if h <= H) for H in HS]
row_m = [2 * sum(1 for h in hs if h <= H) for H in HS]
row_q = [sum(1 for h in quart if h <= H) for H in HS]
print("rational points with height <= H:        H=10  H=100  H=1000")
print("  y^2 = x^3 - x + 1, genus 1, by search  " + "".join(f"{c:6}" for c in row_s))
print("  y^2 = x^3 - x + 1, as +-kP             " + "".join(f"{c:6}" for c in row_m))
print("  x^4 + y^4 = 1, genus 3, by search      " + "".join(f"{c:6}" for c in row_q))
print("results named per citation (# = one):")
for cit in [CITATIONS[i][0] for i in (1, 2, 5, 7, 3, 4)]:
    print(f"  {cit:30}{'#' * counts[cit][0]:7}{counts[cit][0]}")
assert agree == total == 35                                # two readings of every phrase agree
assert counts["Abel 2026 Faltings, short"][0] == 2 and counts["Abel 2026 Faltings, long"][0] == 6
assert by_prize == ["Dowling-Wilson, all geometric lattices", "geometric Langlands, characteristic 0"]  # set by a prize
assert d_formula == d_table == 106                         # two calendars, one gap
assert all(genus_formula(n) == interior(n, n) for n in range(3, 7)) and interior(3, 2) == 1
assert row_s == row_m == [12, 18, 24]                      # search and chord rule agree, no end
assert row_q == [4, 4, 4]                                  # genus 3: (+-1, 0), (0, +-1) only, checked for H <= 1000
print("ALL CHECKS PASS")
