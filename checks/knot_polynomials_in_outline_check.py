# Knot polynomials in outline -- the check behind the card.  Standard library
# only.  A diagram is a planar-diagram code: one X[a, b, c, d] per crossing,
# edge labels read anticlockwise from the incoming under-strand, labels rising
# along the knot.  Polynomials are dicts {exponent: integer coefficient}.
# Road 1: the bracket state sum over all 2^n smoothings, then the writhe.
# Road 2: the Jones skein relation, by hand: unlink -> Hopf link -> trefoil.
from itertools import product

LEFT = [(1, 4, 2, 5), (3, 6, 4, 1), (5, 2, 6, 3)]   # the trefoil of the tables
KINK = [(1, 1, 2, 2)]                                # an unknot with one twist

def mul(p, q):
    out = {}
    for e, c in p.items():
        for f, k in q.items():
            out[e + f] = out.get(e + f, 0) + c * k
    return {e: c for e, c in out.items() if c}

def add(p, q):
    out = dict(p)
    for e, c in q.items():
        out[e] = out.get(e, 0) + c
    return {e: c for e, c in out.items() if c}

def scale(p, k, shift):                          # k * p, exponents moved by shift
    return {e + shift: k * c for e, c in p.items()}

D = {2: -1, -2: -1}                              # d = -A^2 - A^-2, one loop's worth
ONE, ROOT = {0: 1}, {1: 1, -1: -1}               # 1 and t^(1/2) - t^(-1/2)

def positive(x):                                 # sign of a crossing
    a, b, c, dd = x
    return a == b or c == dd or b - dd == 1 or dd - b > 1

def writhe(pd):
    return sum(1 if positive(x) else -1 for x in pd)

def mirror(pd):                                  # swap over and under everywhere
    return [(d, a, b, c) if positive((a, b, c, d)) else (b, c, d, a)
            for a, b, c, d in pd]

def loops(pairs):                                # count closed loops: union-find
    parent = {}
    def find(x):
        parent.setdefault(x, x)
        while parent[x] != x:
            x = parent[x]
        return x
    for u, v in pairs:
        parent[find(u)] = find(v)
    return len({find(x) for x in list(parent)})

def states(pd, loop_power=-1):        # every smoothing: name, A-power, loops, term
    for state in product("AB", repeat=len(pd)):
        pairs = []
        for (a, b, c, d), s in zip(pd, state):
            pairs += [(a, b), (c, d)] if s == "A" else [(a, d), (b, c)]
        power, n = 2 * state.count("A") - len(pd), loops(pairs)
        term = {power: 1}
        for _ in range(n + loop_power):
            term = mul(term, D)
        yield "".join(state), power, n, term

def bracket(pd, loop_power=-1):
    total = {}
    for _, _, _, term in states(pd, loop_power):
        total = add(total, term)
    return total

def jones(br, w):                    # (-A^3)^-w <D>, then A = t^(-1/4); t in half-steps
    f = scale(br, -1 if w % 2 else 1, -3 * w)
    assert all(e % 2 == 0 for e in f)
    return {-e // 2: c for e, c in f.items()}

def show(p, v, den):                 # print a polynomial, lowest power first
    out = ""
    for e in sorted(p):
        c, g = p[e], [k for k in (den, 1) if e % k == 0][0]
        n, m = e // g, den // g
        pw = "" if e == 0 else v if (n, m) == (1, 1) else f"{v}^{n}" if m == 1 else f"{v}^({n}/{m})"
        mag = "" if abs(c) == 1 and pw else str(abs(c))
        sign = ("-" if c < 0 else "") if not out else (" - " if c < 0 else " + ")
        out += sign + mag + pw
    return out or "0"

def tricolourings(pd):
    arcs = {}
    for a, b, c, d in pd:
        arcs[d] = b                  # the over-strand keeps one arc through b and d
    def arc(x):
        while x in arcs and arcs[x] != x:
            x = arcs[x]
        return x
    names = sorted({arc(x) for X in pd for x in X})
    count = 0
    for cols in product(range(3), repeat=len(names)):
        col = dict(zip(names, cols))
        count += all((col[arc(a)] + col[arc(c)] + col[arc(b)]) % 3 == 0 for a, b, c, d in pd)
    return count

RIGHT = mirror(LEFT)
print("state, A-power, loops, term of the right trefoil:")
for name, power, n, term in states(RIGHT):
    print(f"  {name}  A^{power}  loops {n}  term {show(term, 'A', 1)}")
br, bl = bracket(RIGHT), bracket(LEFT)
vr, vl = jones(br, writhe(RIGHT)), jones(bl, writhe(LEFT))
print(f"right trefoil: writhe {writhe(RIGHT)}, bracket {show(br, 'A', 1)}")
fr = scale(ONE, -1 if writhe(RIGHT) % 2 else 1, -3 * writhe(RIGHT))
print(f"  writhe factor (-A^3)^-{writhe(RIGHT)} = {show(fr, 'A', 1)}; corrected {show(mul(fr, br), 'A', 1)}")
print(f"  span of the bracket {max(br) - min(br)} = 4 x {len(RIGHT)} crossings")
print(f"  Jones V(t) = {show(vr, 't', 2)}")
print(f"left trefoil (mirror): writhe {writhe(LEFT)}, bracket {show(bl, 'A', 1)}")
print(f"  Jones V(t) = {show(vl, 't', 2)}")
# Road 2: t^-1 V(L+) - t V(L-) = (t^(1/2) - t^(-1/2)) V(L0), solved for V(L+).
def skein(v_minus, v_zero):
    return scale(add(scale(v_minus, 1, 2), mul(ROOT, v_zero)), 1, 2)
unlink = {1: -1, -1: -1}                         # two separate loops: d, at A = t^(-1/4)
hopf = skein(unlink, ONE)
tref = skein(ONE, hopf)
print(f"skein road: unlink {show(unlink, 't', 2)}; Hopf link {show(hopf, 't', 2)}")
print(f"skein road: (t^(1/2) - t^(-1/2)) x Hopf = {show(mul(ROOT, hopf), 't', 2)}")
print(f"skein road: right trefoil {show(tref, 't', 2)}")
flip = {-e: c for e, c in vr.items()}
print(f"right trefoil's V at t -> 1/t: {show(flip, 't', 2)}; mirror differs: {'yes' if vr != vl else 'no'}")
bk = bracket(KINK)
print(f"kinked unknot: writhe {writhe(KINK)}, bracket {show(bk, 'A', 1)}, Jones {show(jones(bk, 1), 't', 2)}")
print(f"tricolourings: right {tricolourings(RIGHT)}, left {tricolourings(LEFT)}, unknot {tricolourings(KINK)}")
print(f"mistake 1, bracket with no writhe factor: kinked unknot {show(bk, 'A', 1)}, not 1")
print(f"mistake 2, d^loops not d^(loops-1): kinked unknot {show(bracket(KINK, 0), 'A', 1)}; "
      f"trefoil {show(jones(bracket(RIGHT, 0), 3), 't', 2)}")
swapped = [(b, c, d, a) for a, b, c, d in RIGHT]      # A and B smoothings swapped
print(f"mistake 3, A and B swapped, writhe kept: {show(jones(bracket(swapped), 3), 't', 2)}")
assert tref == vr                                 # road 1 = road 2
assert vl == flip and vr != vl                    # the mirror is V(1/t), and differs
assert jones(bk, writhe(KINK)) == ONE and bk == {3: -1}
assert br == {-7: 1, -3: -1, 5: -1} and max(br) - min(br) == 4 * len(RIGHT)
assert tricolourings(RIGHT) == tricolourings(LEFT) == 9
print("ALL CHECKS PASS")
