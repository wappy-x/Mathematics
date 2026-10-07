# Divisibility rules -- the check behind the card.  Nothing is imported.  The
# $1,236 restaurant bill: every rule is decided from the digits alone, then
# checked against the real division, a second road to the same verdict.
BILL = 1236                                     # the restaurant bill, in dollars
SUM = 1 + 2 + 3 + 6                             # the digit sum, 12
NINES = 1 * 999 + 2 * 99 + 3 * 9                # the pile of nines under the digits
LOOK = {2: BILL % 10, 5: BILL % 10, 10: BILL % 10, 4: BILL % 100,
        8: BILL % 1000, 3: SUM, 9: SUM}         # the little number each rule reads
WORDS = {2: "last digit 6", 3: "digit sum 12", 4: "last two digits 36",
         5: "last digit 6", 6: "passes 2 and 3", 8: "last three digits 236",
         9: "digit sum 12", 10: "last digit 6"}

def rule(d):                        # the verdict from the digits, never dividing 1236
    return rule(2) and rule(3) if d == 6 else LOOK[d] % d == 0

for d in (2, 3, 4, 5, 6, 8, 9, 10):
    q, r = BILL // d, BILL % d
    done = f"1236 = {d} x {q}" + (f" + {r}" if r else "")
    print(f"{d:<4}{WORDS[d]:<23}{'yes' if rule(d) else 'no':<6}{done}")
    assert rule(d) == (r == 0)      # the digits and the division must agree
print(f"splits  1236 = {BILL - BILL % 10} + {BILL % 10} = {BILL - BILL % 100} + {BILL % 100}"
      f" = {BILL - BILL % 1000} + {BILL % 1000}; 10 = 2 x {10 // 2}, 100 = 4 x {100 // 4}, 1000 = 8 x {1000 // 8}")
print(f"nines   1236 = 1 x 999 + 2 x 99 + 3 x 9 + {SUM} = {NINES} + {SUM}, and {NINES} = 9 x {NINES // 9}")
print(f"mistakes  last digit for 4 says no (truth 4 x {BILL // 4}); sum 12 for 9 says yes "
      f"(truth 9 x {BILL // 9} + {BILL % 9}); last two digits for 8 says no on 1136 (truth 8 x {1136 // 8})")
assert BILL % 9 == SUM % 9 == 3 and BILL % 3 == SUM % 3 == 0
assert BILL % 8 == (BILL % 1000) % 8 == 4 and NINES % 9 == 0 and NINES + SUM == BILL
assert 1136 % 8 == 0 and (1136 % 100) % 8 != 0  # the rule that is not a rule
print("ALL CHECKS PASS")
