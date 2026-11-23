# The status register -- the check behind the card.  Standard library only.
# The register is data typed in twice: the rows, and a dated log of changes.
# Roads: status rule vs rows, log replay vs rows, two day counts, small cases.
from fractions import Fraction as Fr

TODAY, SNAP = "2026-11-23", "2026-09-13"
# id kind status claim accept.  kind: C conjecture, T theorem, M model.
# status: o open, c claimed, p proved, r refuted.  claim: - none, P proof, D disproof.
# accept: - none, A authors only, X disputed, I independent (refereed, prize, formal rerun).
ROWS = """RH C p P I  BSD C o - -  PNP C o - -  NS C c D A  HODGE C o - -  YM C o - -
POINC C p P I  TWIN C o - -  GOLD C o - -  LEG C o - -  NSQ C o - -  ABC C c P X
BEAL C o - -  FLT C p P I  DIST C o - -  UNIT C r D I  KAK3 C p P I  KAKN C o - -
HN C o - -  CDC C c P A  ER C o - -  ES C c P A  UC C o - -  SP8 C p P I  SP24 C p P I
COLL C o - -  Z23 T c P A  JAC3 C r D I  JAC2 C o - -  SOFIC C c D A  KOTHE C c D A
PERC C c P A  IGP C o - -  M23 C c P A  CH T p P I  UGC C o - -  GI T p P I
BQP C o - -  ROUGH M o - -  OT T p P I  GEN C o - -  DDES C o - -  MF T p P I  SGD C o - -"""
LOG = """1963-12 CH o p|1991-06 OT o p|1993-06 FLT o c|1995-05 FLT c p
2002-11-11 POINC o c|2006-07-25 POINC c p|2012-08 ABC o c|2015-12-11 GI o c
2016-03-14 SP8 o c|2016-03-21 SP24 o c|2016-06-19 GI c p|2017-01-04 GI p o
2017-01-09 GI o c|2017-01-16 GI c p|2017-05-01 SP8 c p|2017-05-01 SP24 c p
2018-04-18 MF o c|2018-07-27 MF c p|2025-02-24 KAK3 o c|2026-05-20 UNIT o r
2026-07-10 CDC o c|2026-07-20 JAC3 o r|2026-07-23 KAK3 c p|2026-08-01 SOFIC o c
2026-08-09 M23 o c|2026-08-10 Z23 o c|2026-08-28 PERC o c|2026-09-07 KOTHE o c
2026-09-08 NS o c|2026-10-19 ES o c|2026-11-21 RH o p"""
w = ROWS.split()
rows = {w[i]: tuple(w[i + 1:i + 5]) for i in range(0, len(w), 5)}
log = [tuple(e.split()) for e in LOG.replace("\n", "|").split("|")]
NAME = {"o": "open", "c": "claimed", "p": "proved", "r": "refuted"}

def rule(claim, accept):                    # the status rule, from the evidence alone
    if claim == "-": return "o"
    if accept == "I": return "p" if claim == "P" else "r"
    return "c"

def replay(upto, monotone=False):           # rebuild every status from the log
    st = {k: "o" for k in rows}
    for d, k, old, new in sorted(log, key=lambda e: e[0]):
        if d > upto[:len(d)]: continue
        if monotone:
            if "ocpr".index(new) < "ocpr".index(st[k]): continue
        else: assert st[k] == old, (d, k)   # each entry starts where the last one left
        st[k] = new
    return st

def days(s):                                # road 1: closed formula, days since 1970-01-01
    y, m, d = map(int, s.split("-")); y -= m <= 2
    era = y // 400; yoe = y - era * 400
    doy = (153 * (m + (-3 if m > 2 else 9)) + 2) // 5 + d - 1
    return era * 146097 + yoe * 365 + yoe // 4 - yoe // 100 + doy - 719468

def days_loop(s):                           # road 2: add up whole years and months
    y, m, d = map(int, s.split("-")); n = 0
    leap = lambda t: t % 4 == 0 and (t % 100 != 0 or t % 400 == 0)
    for t in range(1970, y): n += 366 if leap(t) else 365
    for t in range(1, m): n += [31, 29 if leap(y) else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][t - 1]
    return n + d - 1

def date(n):                                # inverse of days(), found by counting forward
    y = 1970 + n // 366
    while days(f"{y + 1}-01-01") <= n: y += 1
    m = 1
    while m < 12 and days(f"{y}-{m + 1:02d}-01") <= n: m += 1
    return f"{y}-{m:02d}-{n - days(f'{y}-{m:02d}-01') + 1:02d}"

print(f"register as of {TODAY}: {len(rows)} rows, every row checked {TODAY}")
assert all(rule(c, a) == s for k, s, c, a in rows.values()), "status rule disagrees with a row"
now = replay(TODAY)
assert now == {k: v[1] for k, v in rows.items()}, "log replay disagrees with the rows"
tally = lambda st: [sum(v == s for v in st.values()) for s in "ocpr"]
assert tally(now) == [sum(v[1] == s for v in rows.values()) for s in "ocpr"]
print("open %d, claimed %d, proved %d, refuted %d" % tuple(tally(now)))
print("kinds: conjecture %d, theorem %d, model %d" % tuple(sum(v[0] == q for v in rows.values()) for q in "CTM"))
print(f"status rule = rows = log replay for all {len(rows)} rows; log has {len(log)} entries")
for i in range(0, len(log), 3): print("log  " + " | ".join(f"{d} {k} {NAME[o]}>{NAME[n]}" for d, k, o, n in log[i:i + 3]))
old = replay(SNAP)
print(f"changed between {SNAP} and {TODAY}: " + ", ".join(f"{k} {NAME[old[k]]}>{NAME[now[k]]}" for k in rows if old[k] != now[k]))
for a, b in [(SNAP, TODAY), ("2002-11-11", "2006-07-25"), ("2017-01-04", "2017-01-09"), ("2016-03-14", "2017-05-01"), ("2025-02-24", "2026-07-23")]:
    assert days(b) - days(a) == days_loop(b) - days_loop(a)
    print(f"days {a} to {b}: {days(b) - days(a)}")
due = {s: date(days(TODAY) + L) for s, L in [("c", 30), ("o", 365)]}
assert days(due["o"]) - days(TODAY) == 365 and date(days("2017-01-09")) == "2017-01-09"
print(f"next recheck: claimed rows {due['c']}, all other rows {due['o']}")
yrs = [str(y) for y in range(1995, 2026, 5)]               # the chart: replay stopped at each year's end
snaps = [replay(y + "-12-31") for y in yrs] + [now]
print("chart, end of " + " ".join(yrs) + ", then " + TODAY)
print("chart, claimed " + " ".join(str(tally(s)[1]) for s in snaps))
print("chart, proved or refuted " + " ".join(str(sum(tally(s)[2:])) for s in snaps))
# ---- what breaks ----
up = sum(rule(c, "I" if a in "AX" else a) in "pr" for k, s, c, a in rows.values())
abc = sum(rule(c, "I" if a == "X" else a) == "p" for k, s, c, a in rows.values())
print(f"breaks: claims counted as accepted: proved or refuted {sum(tally(now)[2:])} -> {up}")
print(f"breaks: abc's journal counted, dispute ignored: proved {tally(now)[2]} -> {abc}")
gi, gm = replay("2017-01-05")["GI"], replay("2017-01-05", True)["GI"]
assert (gi, gm) == ("o", "p")
print(f"breaks: never downgrade: GI on 2017-01-05 reads {NAME[gm]}, true {NAME[gi]}")
print(f"breaks: one 365-day period: claimed rows due {due['o']}, {days(due['o']) - days(due['c'])} days late")
# ---- a slice of small cases, each 'checked for n <= N', never 'true' ----
N = 10**6; sv = bytearray([1]) * (N + 1); sv[0] = sv[1] = 0
for i in range(2, 1001):
    if sv[i]: sv[i * i::i] = bytearray(len(range(i * i, N + 1, i)))
assert all(any(sv[p] and sv[n - p] for p in range(2, n // 2 + 1)) for n in range(4, 10001, 2))
print("GOLD: every even n with 4 <= n <= 10000 is a sum of two primes: checked")
tw = sum(sv[p] and sv[p + 2] for p in range(N - 1))
assert tw == 8169
print(f"TWIN: prime pairs p, p + 2 with p + 2 < 10^6: {tw}")
n, st, top = 27, 0, 27
while n != 1: n = n // 2 if n % 2 == 0 else 3 * n + 1; st += 1; top = max(top, n)
assert (st, top) == (111, 9232)
print(f"COLL: 27 reaches 1 in {st} steps, peak {top}")
def F(x, y, z):
    u, v = 1 + x * y, 4 + 3 * x * y         # products only, so floats agree to the bit with Rust
    return (u * u * u * z + y * y * u * v, y + 3 * x * u * u * z + 3 * x * y * y * v, 2 * x - 3 * x * x * y - x * x * x * z)
def det3(J): return (J[0][0] * (J[1][1] * J[2][2] - J[1][2] * J[2][1]) - J[0][1] * (J[1][0] * J[2][2] - J[1][2] * J[2][0])
                     + J[0][2] * (J[1][0] * J[2][1] - J[1][1] * J[2][0]))
def jac(x, y, z):                           # partial derivatives, worked by hand
    u, w = 1 + x * y, x * y
    return [[3 * u**2 * y * z + y**3 * (7 + 6 * w), 3 * u**2 * x * z + 2 * y * u * (4 + 3 * w) + x * y**2 * (7 + 6 * w), u**3],
            [3 * u**2 * z + 6 * w * u * z + 3 * y**2 * (4 + 3 * w) + 9 * x * y**3, 1 + 6 * x**2 * u * z + 6 * w * (4 + 3 * w) + 9 * w * w, 3 * x * u**2],
            [2 - 6 * w - 3 * x**2 * z, -3 * x**2, -x**3]]
pts = [(Fr(0), Fr(0), Fr(-1, 4)), (Fr(1), Fr(-3, 2), Fr(13, 2)), (Fr(-1), Fr(3, 2), Fr(13, 2))]
img = [F(*p) for p in pts]
assert img[0] == img[1] == img[2] == (Fr(-1, 4), 0, 0)
g = range(-3, 4)
assert all(det3(jac(x, y, z)) == -2 for x in g for y in g for z in g)
h, p0 = 0.001, (0.5, -0.25, 0.75)
fd = [[(F(*[p0[j] + h * (j == i) for j in range(3)])[r] - F(*[p0[j] - h * (j == i) for j in range(3)])[r]) / (2 * h)
       for i in range(3)] for r in range(3)]
assert abs(det3(fd) + 2) < 1e-4 and det3(jac(Fr(1, 2), Fr(-1, 3), Fr(2, 5))) == -2
print("JAC3: (0, 0, -1/4), (1, -3/2, 13/2), (-1, 3/2, 13/2) all map to (-1/4, 0, 0)")
print(f"JAC3: det = -2 at all 343 grid points; by central differences at (0.5, -0.25, 0.75): {det3(fd):.9f}")
print("ALL CHECKS PASS")
