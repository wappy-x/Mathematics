# Tolerances -- the check behind the card.  Standard library only.
# Every number on the card is printed here.  struct only hands over a double's
# 64 bits; each exact error is then worked out in whole numbers (pennies over
# powers of two), which cannot round, and set against the machine's answer.
import math, struct

U = 2.0 ** -53                          # unit roundoff: worst relative error of one rounding
TOL_REL, TOL_ABS = 1e-9, 1e-12          # the library's default pair
ITEMS = (0.99, 1.19, 2.19)              # the receipt, in the order it was rung up
PENNIES = (99, 119, 219)                # the same prices as whole numbers: no rounding

def bits(x): return struct.unpack(">Q", struct.pack(">d", x))[0]

def exact_error(x, p):                  # (stored x) - p/100, worked in whole numbers
    b = bits(x)
    m, k = (1 << 52) | (b & ((1 << 52) - 1)), 1075 - ((b >> 52) & 0x7FF)   # x = m / 2^k
    return (100 * m - p * (1 << k)) / (100 * (1 << k))

def close(a, b, rel, abs_):             # the card's formula
    return abs(a - b) <= max(rel * max(abs(a), abs(b)), abs_)

def add_up(xs):
    s = 0.0
    for x in xs: s += x
    return s

def sci(x):
    a, e = f"{x:.3e}".split("e"); return f"{a}e{int(e)}"
def yn(flag): return "yes" if flag else "no"
def row(label, value): print(f"{label:<40} {value}")

# ---- 1. one receipt, added in two orders ----
pennies = sum(PENNIES)
s_rung = add_up(ITEMS)
s_sorted = add_up(ITEMS[::-1])          # the same three prices, dearest first
gap_ulps = bits(s_sorted) - bits(s_rung)
row("pennies 99 + 119 + 219", pennies)
row("0.99 + 1.19 + 2.19", repr(s_rung))
row("2.19 + 1.19 + 0.99", repr(s_sorted))
row("== 4.37, rung-up order / dearest first", f"{yn(s_rung == 4.37)} / {yn(s_sorted == 4.37)}")
row("gap between the two sums, in ulps", gap_ulps)
row("one ulp at 4.37", sci(s_sorted - s_rung))
e_rung, e_sorted = exact_error(s_rung, pennies), exact_error(s_sorted, pennies)
row("exact error, rung-up order", sci(e_rung))
row("exact error, dearest first", sci(e_sorted))
n_small = 5                             # 3 prices stored, 2 additions: 5 roundings
bound_small = n_small * U * pennies / 100
row("worst-case bound, 5 roundings", sci(bound_small))
assert 1.0 + U == 1.0 and 1.0 + 2 * U > 1.0, "u is half the gap between 1 and the next double"
assert gap_ulps == 1, "the two orders sit one step apart"
assert e_sorted - e_rung == s_sorted - s_rung, "exact errors and machine sums give the same gap"
assert 0 < abs(e_rung) <= bound_small and abs(e_sorted) <= bound_small, "exact errors under the bound"

# ---- 2. choosing the tolerance: correct sum against a penny mistake ----
s_wrong = add_up((0.98, 1.19, 2.19))    # a typo: water rung up at 98p
row("the penny mistake, 0.98 + 1.19 + 2.19", repr(s_wrong))
print("absolute tolerance   correct sum passes   penny mistake caught")
verdicts = {}
for tol in (0.0, 1e-16, 1e-15, 1e-12, 1e-9, 1e-6, 1e-3, 5e-3, 1e-2, 2e-2):
    ok, caught = close(s_rung, 4.37, 0.0, tol), not close(s_wrong, 4.37, 0.0, tol)
    verdicts[tol] = (ok, caught)
    print(f"{sci(tol) if tol else '0, i.e. ==':>18}   {yn(ok):>18}   {yn(caught):>20}")
assert verdicts[1e-9] == (True, True), "1e-9 must pass the right sum and catch the wrong one"
assert verdicts[0.0][0] is False and verdicts[2e-2][1] is False, "both edges of the window must fail"
floor, ceiling = abs(s_rung - 4.37), 0.01
lo, hi = 10 * n_small * U, ceiling / (10 * 4.37)       # the window for the relative tolerance
row("4.37 minus the penny mistake", repr(4.37 - s_wrong))
row("relative 1e-9 allows at 4.37", sci(TOL_REL * 4.37))
row("relative window, 10 n u .. Delta/(10 b)", f"{sci(lo)} .. {sci(hi)}")
row("middle of that window, log scale", sci(10 ** ((math.log10(lo) + math.log10(hi)) / 2)))
for label, v in (("gap of one ulp", floor), ("worst-case bound", bound_small), ("tolerance at 4.37", TOL_REL * 4.37),
                 ("a tenth of a penny", 1e-3), ("one penny", ceiling)):   # bar length: 2 x (17 + log10)
    print(f"{label:<20}{'#' * round(2 * (17 + math.log10(v))):<31}{sci(v)}")

# ---- 3. the same receipt 100,000 times: absolute breaks, relative holds ----
N_REC = 100000
big = add_up(ITEMS * N_REC)
big_p = pennies * N_REC
want = big_p / 100                      # 437000.0: exact, a whole number
e_big = exact_error(big, big_p)
bound_big = (3 * N_REC + 3) * U * big_p / 100
row("100,000 receipts, added item by item", f"{big:.8f}")
row("exact error", sci(e_big))
row("worst-case bound, 300,003 roundings", sci(bound_big))
row("absolute 1e-9 / relative 1e-9 passes", f"{yn(close(big, want, 0.0, 1e-9))} / {yn(close(big, want, TOL_REL, 0.0))}")
row("relative 1e-9 allows, in pounds", sci(TOL_REL * want))
assert abs(e_big) <= bound_big and abs(e_big) > 1e-9, "error above 1e-9 yet under the bound"
assert close(big, want, TOL_REL, TOL_ABS) and not close(big, want, 0.0, 1e-9), "scale needs relative"

# ---- 4. near zero: refund every item, expect 0 ----
left = s_rung
for x in ITEMS: left -= x
floor_needed = 10 * 8 * U * 2 * pennies / 100   # 10 x 8 roundings x u x sum|x| (4.37 up, 4.37 down)
row("refund: 4.37 total minus each item", sci(left))
row("relative 1e-9 only / with floor 1e-12", f"{yn(close(left, 0.0, TOL_REL, 0.0))} / {yn(close(left, 0.0, TOL_REL, TOL_ABS))}")
row("inputs' size, 4.37 up and 4.37 down", 2 * pennies / 100)
row("floor needed, 10 n u sum|x|, n = 8", sci(floor_needed))
assert 0 < abs(left) <= floor_needed / 10, "a nonzero leftover, under the worst-case noise"
assert close(left, 0.0, TOL_REL, TOL_ABS) and not close(left, 0.0, TOL_REL, 0.0), "near zero, the floor decides"
big_left = big
for x in ITEMS * N_REC: big_left -= x   # refund all 100,000 receipts, item by item
floor_big = 10 * (6 * N_REC + 3) * U * 2 * big_p / 100   # 300,003 roundings up, 300,000 down
row("refund of 100,000 receipts", sci(big_left))
row("inputs' size, 437,000 up, 437,000 down", 2 * big_p // 100)
row("floor needed, 10 n u sum|x|, n = 600,003", sci(floor_big))
row("floor 1e-12 / floor 10 n u sum|x| passes", f"{yn(close(big_left, 0.0, TOL_REL, TOL_ABS))} / {yn(close(big_left, 0.0, TOL_REL, floor_big))}")
assert not close(big_left, 0.0, TOL_REL, TOL_ABS) and close(big_left, 0.0, TOL_REL, floor_big), "big inputs need a bigger floor"

# ---- 5. a tolerance is not equality: it does not chain ----
a, b, c = 4.366, 4.370, 4.374
row("4.366~4.370, 4.370~4.374, 4.366~4.374", " ".join(yn(close(p, q, 0.0, 5e-3)) for p, q in ((a, b), (b, c), (a, c))))

# ---- 6. the library's rule, in numbers ----
row("unit roundoff u = 2^-53", sci(U))
row("default pair: relative, absolute", f"{sci(TOL_REL)}, {sci(TOL_ABS)}")
row("roundings 1e-9 covers, worst case", f"{TOL_REL / U:.2e}".replace("e+0", "e"))
row("the same, with a tenfold margin", f"{TOL_REL / U / 10:.2e}".replace("e+0", "e"))
row("n x inputs' size the floor 1e-12 covers", f"{TOL_ABS / (10 * U):.1f}")
print("ALL CHECKS PASS")
