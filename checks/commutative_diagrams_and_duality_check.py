# Commutative diagrams and duality -- the check behind the card.  Nothing is
# imported.  A cafe: drinks A, pastries B, a meal deal in A x B, a voucher item
# in A + B.  Each diagram is read as equations and every candidate arrow is
# tried; then a small category of finite sets is reversed, arrow by arrow.
A, B, TABLES = ["tea", "coffee"], ["scone", "muffin", "toast"], [1, 2, 3]
F = {1: "tea", 2: "coffee", 3: "tea"}                 # f: X -> A, drink per table
G = {1: "scone", 2: "toast", 3: "muffin"}             # g: X -> B, pastry per table
P = {"tea": 250, "coffee": 300}                       # p: A -> Y, pence
Q = {"scone": 280, "muffin": 320, "toast": 200}       # q: B -> Y, pence
FIG = "product: X 220,60; AxB 220,170; A 80,280; B 360,280 | sum: Y 680,60; A+B 680,170; A 540,280; B 820,280"

def functions(dom, cod):                  # every function dom -> cod, as a dict
    out = [{}]
    for d in dom:
        out = [{**h, d: c} for h in out for c in cod]
    return out

def yn(claim): return "yes" if claim else "no"

prod = [(a, b) for a in A for b in B]                 # A x B, from the pairs card
fst, snd = (lambda pr: pr[0]), (lambda pr: pr[1])
summ = [("drink", a) for a in A] + [("pastry", b) for b in B]   # A + B, tagged
inl, inr = (lambda a: ("drink", a)), (lambda b: ("pastry", b))

pairing = {x: (F[x], G[x]) for x in TABLES}           # <f, g>, built directly
prod_maps = functions(TABLES, prod)                   # road two: try them all
prod_pass = [h for h in prod_maps
             if all(fst(h[x]) == F[x] and snd(h[x]) == G[x] for x in TABLES)]
Y = sorted(set(P.values()) | set(Q.values()))
case = {item: (P[item[1]] if item[0] == "drink" else Q[item[1]]) for item in summ}
sum_maps = functions(summ, Y)
sum_pass = [h for h in sum_maps
            if all(h[inl(a)] == P[a] for a in A) and all(h[inr(b)] == Q[b] for b in B)]

print(f"drinks A = {', '.join(A)}; pastries B = {', '.join(B)}")
print(f"A x B, the meal deals: {len(prod)} = {len(A)} x {len(B)}; a third drink makes {(len(A) + 1) * len(B)}")
print("  " + " ".join(f"({a}, {b})" for a, b in prod))
print(f"A + B, the voucher items: {len(summ)} = {len(A)} + {len(B)}; a third drink makes {len(A) + 1 + len(B)}")
print("  " + " ".join(f"{t}:{v}" for t, v in summ))
print("<f, g> sends tables 1, 2, 3 to: " + " ".join(f"({a}, {b})" for a, b in pairing.values()))
print(f"functions X -> A x B tried: {len(prod_maps)}; passing fst after h = f, snd after h = g: {len(prod_pass)}")
print(f"the one that passes is the pairing built directly: {yn(prod_pass == [pairing])}")
print(f"{len(prod_maps)} = 2^3 x 3^3 = {2 ** 3} x {3 ** 3}")
print("[p, q] sends the voucher items to: " + " ".join(str(case[i]) for i in summ))
print(f"functions A + B -> Y tried: {len(sum_maps)}; passing h after inl = p, h after inr = q: {len(sum_pass)}")
print(f"the one that passes is the case split built directly: {yn(sum_pass == [case])}")
print(f"{len(sum_maps)} = {len(Y)}^2 x {len(Y)}^3 = {len(Y) ** 2} x {len(Y) ** 3}")

# A finite category C: the sets {}, {0}, {0, 1} and every function between them.
arrows = [(n, m, tuple(h[i] for i in range(n)))
          for n in range(3) for m in range(3) for h in functions(range(n), range(m))]
def comp(g, f): return (f[0], g[1], tuple(g[2][i] for i in f[2]))   # g after f
def dom(f): return f[0]
def cod(f): return f[1]
def dom_op(f): return f[1]                            # C^op: same arrows, reversed
def cod_op(f): return f[0]
def comp_op(g, f): return comp(f, g)
def ident(n): return (n, n, tuple(range(n)))

def laws(d, c, k):                       # identities and associativity, every case
    ok = all(k(f, ident(d(f))) == f and k(ident(c(f)), f) == f for f in arrows)
    return ok and all(k(h, k(g, f)) == k(k(h, g), f) for f in arrows for g in arrows
                      for h in arrows if c(f) == d(g) and c(g) == d(h))
def mono(f, d, c, k):                    # f.g = f.h forces g = h
    return all(g == h for g in arrows for h in arrows if c(g) == d(f) == c(h)
               and d(g) == d(h) and k(f, g) == k(f, h))
def epi(f, d, c, k):                     # g.f = h.f forces g = h
    return all(g == h for g in arrows for h in arrows if d(g) == c(f) == d(h)
               and c(g) == c(h) and k(g, f) == k(h, f))

C, COP = (dom, cod, comp), (dom_op, cod_op, comp_op)
monos = [f for f in arrows if mono(f, *C)]
epis = [f for f in arrows if epi(f, *C)]
inj = [f for f in arrows if len(set(f[2])) == f[0]]
sur = [f for f in arrows if len(set(f[2])) == f[1]]
dual_ok = [f for f in arrows if mono(f, *C) == epi(f, *COP) and epi(f, *C) == mono(f, *COP)]
print(f"finite category C: sets of size 0, 1, 2 and every function between them: {len(arrows)} arrows")
print(f"laws (identity, associativity) hold in C: {yn(laws(*C))}; in C^op: {yn(laws(*COP))}")
print(f"monos in C: {len(monos)}; one-to-one functions: {len(inj)}; same arrows: {yn(monos == inj)}")
print(f"epis in C: {len(epis)}; onto functions: {len(sur)}; same arrows: {yn(epis == sur)}")
print(f"mono in C is epi in C^op, and epi is mono, arrow by arrow: {len(dual_ok)} of {len(arrows)}")
print(f"epis in C^op: {sum(epi(f, *COP) for f in arrows)}; monos in C^op: {sum(mono(f, *COP) for f in arrows)}")

def square(m):                           # h(a + b) against h(a) + h(b) on the clock
    good = [(a, b) for a in range(12) for b in range(12) if (a + b) % 12 % m == (a % m + b % m) % m]
    bad = [(a, b) for a in range(12) for b in range(12) if (a, b) not in good]
    return good, bad
good3, bad3 = square(3)
good5, bad5 = square(5)
a, b = bad5[0]
print(f"group square, x mod 3 on the 12-hour clock: commutes on {len(good3)} of 144 pairs")
print(f"group square, x mod 5 on the 12-hour clock: commutes on {len(good5)} of 144 pairs; "
      f"first failure ({a}, {b}): {(a + b) % 12 % 5} against {(a % 5 + b % 5) % 5}")

HERE, AWAY = P, {"tea": 230, "coffee": 270}
Y2 = sorted(set(HERE.values()) | set(AWAY.values()))
union_pass = [h for h in functions(A, Y2) if all(h[x] == HERE[x] and h[x] == AWAY[x] for x in A)]
twice = [("here", x) for x in A] + [("away", x) for x in A]
twice_pass = [h for h in functions(twice, Y2)
              if all(h[("here", x)] == HERE[x] and h[("away", x)] == AWAY[x] for x in A)]
empty_prod = [(x, y) for x in A for y in []]
print(f"mistake 1, plain union A u A for here and takeaway, {', '.join(f'{x} {HERE[x]} or {AWAY[x]}' for x in A)}: "
      f"{len(set(A) | set(A))} items, {len(union_pass)} of {len(Y2) ** 2} functions pass")
print(f"   disjoint union A + A: {len(twice)} items, {len(twice_pass)} of {len(Y2) ** 4} functions pass")
print(f"mistake 2, dualising a fact about sets only: inl is one-to-one, but with B empty "
      f"A x B has {len(empty_prod)} members and fst reaches {len({fst(pr) for pr in empty_prod})} of {len(A)} drinks")
print(f"mistake 3, one pair checked: x mod 5 at (2, 3) gives {(2 + 3) % 12 % 5} both ways, "
      f"yet {len(bad5)} of 144 pairs fail")
print(f"mistake 4, the sum counted as a product: {len(A) * len(B)}, not {len(summ)}")
print("figure, " + FIG)

assert prod_pass == [pairing] and sum_pass == [case]                 # exactly one, the built one
assert len(prod_maps) == len(functions(TABLES, A)) * len(functions(TABLES, B))
assert len(sum_maps) == len(functions(A, Y)) * len(functions(B, Y))
assert laws(*C) and laws(*COP) and monos == inj and epis == sur     # cancellation = elements
assert len(dual_ok) == len(arrows) and (len(monos), len(epis)) == (8, 5)
assert len(good3) == 144 and len(bad5) == sum(1 for a in range(12) for b in range(12) if a + b >= 12)
assert union_pass == [] and len(twice_pass) == 1
print("ALL CHECKS PASS")
