# Forward-mode automatic differentiation check, standard library only: one pricer, three number types.
import math, sys; sys.setrecursionlimit(20000)
OPS, MISTAKE = [0, 0], ""   # operations done [on values, on slopes]; "" or "product" or "chain"

class Dual:           # a + b eps, with eps * eps = 0: a value carrying its slope
    def __init__(s, v, d=0.0): s.v, s.d = v, d
    def __add__(s, o): o = lift(o); OPS[0] += 1; OPS[1] += 1; return Dual(s.v + o.v, s.d + o.d)
    def __sub__(s, o): o = lift(o); OPS[0] += 1; OPS[1] += 1; return Dual(s.v - o.v, s.d - o.d)
    def __mul__(s, o):
        o = lift(o); OPS[0] += 1; OPS[1] += 3
        return Dual(s.v * o.v, s.v * o.d if MISTAKE == "product" else s.v * o.d + s.d * o.v)
    def __truediv__(s, o):
        o = lift(o); OPS[0] += 1; OPS[1] += 3; q = s.v / o.v
        return Dual(q, (s.d - q * o.d) / o.v)
    def __rtruediv__(s, o): return lift(o) / s
    def __rmul__(s, o): return lift(o) * s
    __radd__ = __add__
    def exp(s):
        e = math.exp(s.v); OPS[0] += 1; OPS[1] += 1
        return Dual(e, e if MISTAKE == "chain" else e * s.d)
    def log(s): OPS[0] += 1; OPS[1] += 1; return Dual(math.log(s.v), s.d / s.v)
    def round_bp(s): OPS[0] += 1; return Dual(math.floor(s.v * 1e4 + 0.5) / 1e4, 0.0)

def lift(o): return o if isinstance(o, Dual) else Dual(float(o))

class Ex:             # a symbolic expression: an operation and its inputs
    def __init__(s, op, a=None, b=None, c=0.0): s.op, s.a, s.b, s.c = op, a, b, c
    def __add__(s, o): return Ex("+", s, ex(o))
    def __radd__(s, o): return Ex("+", ex(o), s)
    def __sub__(s, o): return Ex("-", s, ex(o))
    def __mul__(s, o): return Ex("*", s, ex(o))
    def __rmul__(s, o): return Ex("*", ex(o), s)
    def __truediv__(s, o): return Ex("/", s, ex(o))
    def __rtruediv__(s, o): return Ex("/", ex(o), s)
    def exp(s): return Ex("exp", s)
    def log(s): return Ex("log", s)

def ex(o): return o if isinstance(o, Ex) else Ex("c", c=float(o))
def mk(op, a, b):     # build a node, dropping terms that are the constant 0 (None)
    if op == "+": return b if a is None else a if b is None else Ex("+", a, b)
    if op == "-": return a if b is None else Ex("-", ex(0.0) if a is None else a, b)
    if op == "*": return None if a is None or b is None else Ex("*", a, b)
    return None if a is None else Ex("/", a, b)

def diff(e, memo):    # the textbook rules, applied to the expression's tree
    if id(e) not in memo:
        a, b = e.a, e.b
        da, db = (diff(a, memo) if a else None), (diff(b, memo) if b else None)
        memo[id(e)] = {"c": lambda: None, "y": lambda: Ex("c", c=1.0),
            "+": lambda: mk("+", da, db), "-": lambda: mk("-", da, db),
            "*": lambda: mk("+", mk("*", da, b), mk("*", a, db)),
            "/": lambda: mk("/", mk("-", mk("*", da, b), mk("*", a, db)), Ex("*", b, b)),
            "exp": lambda: mk("*", e, da), "log": lambda: mk("/", da, a)}[e.op]()
    return memo[id(e)]

def evaluate(e, y, memo):
    if id(e) not in memo:
        p = evaluate(e.a, y, memo) if e.a else 0.0
        q = evaluate(e.b, y, memo) if e.b else 0.0
        memo[id(e)] = {"c": lambda: e.c, "y": lambda: y, "+": lambda: p + q, "-": lambda: p - q,
            "*": lambda: p * q, "/": lambda: p / q, "exp": lambda: math.exp(p),
            "log": lambda: math.log(p)}[e.op]()
    return memo[id(e)]

def sizes(e, memo, seen):  # nodes written out in full; seen collects the distinct nodes
    if id(e) not in memo:
        seen.add(id(e))
        memo[id(e)] = 1 + sum(sizes(k, memo, seen) for k in (e.a, e.b) if k)
    return memo[id(e)]

def EXP(x): return x.exp() if hasattr(x, "exp") else math.exp(x)
def LOG(x): return x.log() if hasattr(x, "log") else math.log(x)

def clean_price(y, years=30, rounded=False):
    # clean price per $100 face of a 4% bond paying $2 a half year, 2 months into a period
    if rounded: y = y.round_bp()   # quote the yield to a whole basis point first
    face, cpn = 100.0, 2.0         # face value; the coupon paid each half year
    n = 2 * years                  # coupons still to come: 60
    w = 4.0 / 6.0                  # periods until the next coupon: 4 months of 6
    v = 1.0 / (1.0 + y / 2.0)      # one half year's discount factor
    df = EXP(w * LOG(v))           # discount to the first coupon, v to the power w
    pv = 0.0
    for k in range(n):
        pv = pv + cpn * df         # add this coupon's present value
        if k < n - 1:
            df = df * v            # step the discount one half year further out
    pv = pv + face * df            # the face value comes back with the last coupon
    accrued = cpn * (1.0 - w)      # coupon already earned by the seller
    return pv - accrued

def by_hand(y, years=30, m=1):     # d^m P/dy^m on paper: d^m(v^t)/dy^m = (-1/2)^m t(t+1)...(t+m-1) v^(t+m)
    v, w, n, s = 1.0 / (1.0 + y / 2.0), 4.0 / 6.0, 2 * years, 0.0
    rise = lambda t: math.prod(t + j for j in range(m)) * v ** (t + m) * (-0.5) ** m
    for k in range(n): s += 2.0 * rise(w + k)   # the coupons of 2; the face of 100 comes with the last
    return s + 100.0 * rise(w + n - 1)

y0, h = 0.045, 1e-4
plain, hand, d3 = clean_price(y0), by_hand(y0), by_hand(y0, m=3)
vv = 1.0 / (1.0 + y0 / 2.0)        # closed form: the 60 coupons as one geometric sum
annuity = vv ** (4 / 6) * (2.0 * (1 - vv ** 60) / (1 - vv) + 100.0 * vv ** 59) - 2.0 / 3.0
OPS[:] = [0, 0]; pd = clean_price(Dual(y0, 1.0)); ops_v, ops_d = OPS[0], OPS[1]
P = clean_price(Ex("y")); dP = diff(P, {}); sym_p, sym_d = evaluate(P, y0, {}), evaluate(dP, y0, {})
up, down = clean_price(y0 + h), clean_price(y0 - h)
fwd, ctr = (up - plain) / h, (up - down) / (2 * h)
MISTAKE = "product"; bad_prod = clean_price(Dual(y0, 1.0)).d
MISTAKE = "chain"; bad_chain = clean_price(Dual(y0, 1.0)).d
MISTAKE = ""; rnd = clean_price(Dual(y0, 1.0), rounded=True).d
rnd_bump = (clean_price(Dual(y0 + h), rounded=True).v - clean_price(Dual(y0), rounded=True).v) / h
d10, y6 = clean_price(Dual(y0, 1.0), years=10), clean_price(Dual(0.06, 1.0))
rows = [("price, plain floats", plain), ("price, closed-form annuity", annuity),
        ("price, dual value part", pd.v), ("price, symbolic evaluated", sym_p),
        ("1 dP/dy, dual slope part", pd.d), ("2 dP/dy, symbolic derivative", sym_d), ("3 dP/dy, calculus by hand", hand),
        ("  gap, dual - by hand", pd.d - hand), ("  gap, symbolic - by hand", sym_d - hand), ("4 dP/dy, central 1bp bumps", ctr),
        ("  dP/dy, one-sided 1bp bump", fwd), ("  gap, one-sided bump - dual", fwd - pd.d), ("  gap, central bumps - dual", ctr - pd.d),
        ("  h^2 P'''/6, P''' by hand", h * h * d3 / 6), ("DV01 = -dP/dy x 0.0001", -pd.d * h),
        ("operations, dual run / plain run", (ops_v + ops_d) / ops_v),
        ("price after +1bp", up), ("price change after +1bp", up - plain), ("modified duration -P'/P", -pd.d / plain),
        ("wrong: product rule half dropped", bad_prod), ("wrong: chain factor dropped", bad_chain),
        ("wrong: yield rounded to 1bp, AD", rnd), ("  same pricer, 1bp bump", rnd_bump),
        ("try: 10-year bond, price", d10.v), ("try: 10-year bond, dP/dy", d10.d),
        ("try: 30-year at 6%, price", y6.v), ("try: 30-year at 6%, dP/dy", y6.d)]
for name, v in rows:
    print(f"{name:<34} {v:>16.8f}")
tr, lab = [Dual(y0, 1.0)], ["y", "y/2", "1 + y/2", "v = 1/(1 + y/2)", "log v", "w log v", "exp(w log v)", "2 x that"]
for f in (lambda a: a / 2.0, lambda a: 1.0 + a, lambda a: 1.0 / a, Dual.log, lambda a: (4.0 / 6.0) * a, Dual.exp, lambda a: 2.0 * a): tr.append(f(tr[-1]))
for name, d in zip(lab, tr): print(f"trace {name:<16} value {d.v:>12.8f}  slope {d.d:>12.8f}")
print("years  plain ops  dual ops  price nodes  slope nodes  distinct")
for yrs in (1, 5, 10, 30):
    OPS[:] = [0, 0]; clean_price(Dual(y0, 1.0), years=yrs); seen = set()
    E = clean_price(Ex("y"), years=yrs); pn = sizes(E, {}, set()); sn = sizes(diff(E, {}), {}, seen)
    print(f"{yrs:>5} {OPS[0]:>10} {OPS[0] + OPS[1]:>9} {pn:>12} {sn:>12} {len(seen):>9}")
assert abs(plain - annuity) < 1e-10, "price against the closed-form annuity formula"
assert abs(pd.v - plain) < 1e-12, "the dual's value part is the plain price"
assert abs(pd.d - hand) < 1e-9, "dual slope against calculus by hand"
assert abs(sym_d - hand) < 1e-9, "symbolic derivative against calculus by hand"
assert abs(ctr - hand - h * h * d3 / 6) < 2e-8, "central 1bp bump: error h^2 P'''/6 (next term 7e-10, rounding under 2e-8)"
assert abs(bad_prod - hand) > 1.0 and abs(bad_chain - hand) > 1.0, "broken rules must show"
assert abs(rnd - hand) > 1000.0 and abs(rnd_bump - fwd) < 1e-9, "rounding hides the slope"
assert (ops_v, ops_v + ops_d) == (3 * 60 + 8, 10 * 60 + 22), "operations counted by hand: 3n + 8 plain, 10n + 22 dual"
print("ALL CHECKS PASS")
