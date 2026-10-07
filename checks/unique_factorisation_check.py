# Why the factorisation is unique -- the check behind the card.  Nothing is
# imported.  86,400 seconds in a day: the smallest-prime-first split, then the
# same day down two trees, 24 x 3600 and 1440 x 60.  Then a world where it fails.
def factor(n):                           # pull out the smallest prime, over and over
    out, d = [], 2
    while d * d <= n:
        while n % d == 0: out.append(d); n //= d
        d += 1
    return out + ([n] if n > 1 else [])
def tree(a, b):                          # factor both branches, pool the leaves, sort
    return sorted(factor(a) + factor(b))
def unsplittable(m):                     # in the world 1, 5, 9, 13, ...: nothing smaller splits it
    return all(m % a for a in range(5, m, 4))
def show(xs): return " ".join(str(x) for x in xs)
def row(name, value): print(f"{name:<40}{value}")
day, plain = 86400, factor(86400)
p2, p3, p5 = 2 ** plain.count(2), 3 ** plain.count(3), 5 ** plain.count(5)
row("86,400 seconds, smallest prime first", show(plain))
row("the tree 24 x 3600", show(tree(24, 3600)))
row("the tree 1440 x 60", show(tree(1440, 60)))
row("seven 2s, three 3s, two 5s", f"{p2} x {p3} x {p5} = {p2 * p3 * p5}")
row("primes in the list", len(plain))
row("pieces if you stop at 24 x 3600", len([24, 3600]))
row("primes if you let a 1 in, then two", f"{len(plain) + 1} then {len(plain) + 2}")
row("441 in the world 1, 5, 9, 13, ...", f"{9 * 49} = 9 x 49 = 21 x 21")
row("and 9, 21, 49 unsplittable there", show([m for m in (9, 21, 49) if unsplittable(m)]))
assert plain == tree(24, 3600) == tree(1440, 60) and len(plain) == 12
assert p2 * p3 * p5 == day and (plain.count(2), plain.count(3), plain.count(5)) == (7, 3, 2)
assert all(unsplittable(m) for m in (9, 21, 49)) and 9 * 49 == 441 and 21 * 21 == 441
print("ALL CHECKS PASS")
