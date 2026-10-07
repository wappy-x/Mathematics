# The real numbers have no gaps -- the check behind the card.  Nothing is
# imported.  The collection is every number whose square is under 2 -- the
# spot the dart hit on the tape.  Two roads to its least ceiling: decimal
# places, then halving a bracket.  Whole numbers only, so nothing rounds.
def dec(n, places):                 # dec(14142, 4) -> "1.4142"
    s = str(n).rjust(places + 1, "0")
    return s if places == 0 else s[:len(s) - places] + "." + s[len(s) - places:]

print("places   below       its square    above       its square")
for k, low, high in [(0, 1, 2), (1, 14, 15), (2, 141, 142), (3, 1414, 1415), (4, 14142, 14143)]:
    unit = 10 ** k
    assert low * low < 2 * unit * unit < high * high     # low is inside, high is a ceiling
    print(f"  {k}      {dec(low * 10 ** (4 - k), 4):<12}{dec(low * low, 2 * k):<14}{dec(high * 10 ** (4 - k), 4):<12}{dec(high * high, 2 * k)}")

lo, hi, den = 1, 2, 1                                    # the second road: halve the gap
for _ in range(40):
    lo, hi, den = 2 * lo, 2 * hi, 2 * den
    mid = (lo + hi) // 2
    if mid * mid < 2 * den * den: lo = mid
    else: hi = mid
print(f"halving from 1 to 2, forty times: the least ceiling is caught between {dec(lo * 10 ** 8 // den, 8)} and {dec(hi * 10 ** 8 // den, 8)}")
assert 14142 * den <= lo * 10000 and hi * 10000 <= 14143 * den
print("the two roads agree: the halving bracket sits inside 1.4142 and 1.4143")
print(f"a ceiling, but not the least: 1.415 squares to {dec(1415 * 1415, 6)}, and 1.4143 squares to {dec(14143 * 14143, 8)}")
print(f"not a ceiling at all: 1.4142 squares to {dec(14142 * 14142, 8)}, which is under 2")
assert 14142 * 14142 < 2 * 10000 * 10000 < 14143 * 14143 and 14143 < 1415 * 10
print("ALL CHECKS PASS")
