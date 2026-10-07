# Adding and multiplying on the clock -- the check behind the card.  Nothing is
# imported.  The receipt: 47 x 23 = 1,081, checked by casting out nines.  Digit
# sums are one road; taking 9s away from the whole number is the other.
def cast_out(n):                     # add the digits, again and again; 9 lands on 0
    while n > 9:
        n = sum(int(d) for d in str(n))
    return 0 if n == 9 else n
def take_nines_away(n):              # the same remainder, by subtracting 9 over and over
    while n >= 9:
        n -= 9
    return n
def row(name, value):
    print(f"{name:<42}{value:>6}")
row("47 by digit sums", cast_out(47))
row("23 by digit sums", cast_out(23))
row("2 x 5 = 10, by digit sums", cast_out(2 * 5))
row("47 x 23 the long way", 47 * 23)
row("1081 by digit sums", cast_out(47 * 23))
row("1081 by taking 9s away, 120 times", take_nines_away(47 * 23))
row("47 + 23 = 70, and 2 + 5 = 7, both leave", cast_out(47 + 23))
row("a swapped 1801 passes anyway", cast_out(1801))
row("a slipped 1061 is caught, not 1", cast_out(1061))
row("1061 by taking 9s away, 8 again", take_nines_away(1061))
row("3 x 4 = 12 and 3 x 1 = 3 both leave", cast_out(3 * 4))
assert cast_out(47) == 2 and cast_out(23) == 5 and cast_out(2 * 5) == 1 and 47 * 23 == 1081
assert cast_out(1081) == 1 and take_nines_away(1081) == 1 and cast_out(3 * 4) == 3
assert cast_out(47 + 23) == 7 and cast_out(2 + 5) == 7 and cast_out(1801) == 1 and cast_out(1061) == 8
assert take_nines_away(1061) == 8 and cast_out(9) == 0 and cast_out(18) == 0
print("ALL CHECKS PASS")
