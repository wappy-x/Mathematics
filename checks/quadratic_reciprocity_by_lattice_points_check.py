# Quadratic reciprocity by counting dots -- the check behind the card.  Nothing
# is imported.  Road one counts dots under a diagonal (Eisenstein); road two
# lists every square on the clock and looks the number up.
def col(q, p): return [q * k // p for k in range(1, (p - 1) // 2 + 1)]  # whole parts
def sign(n): return 1 if n % 2 == 0 else -1                             # even +1, odd -1
def sq(p): return sorted({x * x % p for x in range(1, p)})              # the squares
def listed(a, p): return 1 if a % p in sq(p) else -1                    # road two
def rect(p, q): return (p - 1) // 2 * ((q - 1) // 2)                    # h x k dots
for p, q in [(5, 7), (3, 7)]:
    lo, hi, g = col(q, p), col(p, q), sum(k * q % p * 2 > p for k in range(1, p // 2 + 1))  # g: Gauss
    print(f"{p} and {q}: below {' + '.join(map(str, lo))} = {sum(lo)}, above {' + '.join(map(str, hi))}"
          f" = {sum(hi)}, total {sum(lo) + sum(hi)} = {(p - 1) // 2} x {(q - 1) // 2}")
    print(f"  ({p}/{q}) = {sign(sum(hi))}, ({q}/{p}) = {sign(sum(lo))}; squares mod {q}: {sq(q)}, mod {p}: {sq(p)}; Gauss count {g}")
    assert sum(lo) + sum(hi) == rect(p, q) and sign(sum(hi)) == listed(p, q) and sign(sum(lo)) == listed(q, p) == sign(g)
def side(s): return " ".join(f"({x},{y})" for x in (1, 2) for y in (1, 2, 3) if s * (7 * x - 5 * y) > 0)  # 5, 7 dots
print(f"figure, below {side(1)}; above {side(-1)}; line (0,0) to ({5 / 2},{7 / 2})")
for p, q in [(29, 43), (11, 29), (7, 11)]:
    print(f"flip {p} and {q}: {(p - 1) // 2} x {(q - 1) // 2} = {rect(p, q)} dots, sign {sign(rect(p, q))};"
          f" then {q} reads {q % p} on the {p}-clock")
road1 = sign(rect(29, 43)) * sign(rect(11, 29)) * sign(rect(7, 11)) * listed(4, 7)
print(f"275 = 9 x 29 + {275 % 29} = 25 x 11. Is 29 a square mod 43? flips {road1}, squares list {listed(29, 43)}")
assert road1 == listed(29, 43) == -1
ps = [n for n in range(3, 50) if all(n % d for d in range(2, n))]
pairs = [(p, q) for p in ps for q in ps if p < q]
for p, q in pairs:
    assert sum(col(q, p)) + sum(col(p, q)) == rect(p, q) and sign(sum(col(q, p))) == listed(q, p) and listed(p, q) * listed(q, p) == sign(rect(p, q))
print(f"all {len(pairs)} pairs of odd primes up to {ps[-1]}: dots fill the rectangle, both roads agree")
print(f"mistakes: full rectangle {(3 - 1) * (7 - 1)} dots for 3 and 7; no flip sign gives {-road1}; "
      f"2 on the 5-clock counts {sum(col(2, 5))} dots but is {listed(2, 5)}; (2/3)(2/5) = {listed(2, 3) * listed(2, 5)}, squares mod 15: {sq(15)}")
print("ALL CHECKS PASS")
