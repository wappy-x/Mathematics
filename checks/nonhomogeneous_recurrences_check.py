# Recurrences with a driving term -- the check behind the card.  Nothing is
# imported.  Two rules that add an outside amount at every step: the Tower of
# Hanoi, h(n) = 2 h(n-1) + 1 with h(0) = 0, and a savings account at 1% a month
# taking a deposit of 10n dollars in month n.  Every answer is reached at least
# twice: forward from the seed, and from the closed form that undetermined
# coefficients builds.  The Hanoi moves are also actually made, on three pegs.
DISCS, MONTHS, RATE = 6, 12, 1.01
def moves(n, src=0, dst=2, spare=1):            # the recursion, written out as moves
    if n == 0: return []
    return moves(n - 1, src, spare, dst) + [(n, src, dst)] + moves(n - 1, spare, dst, src)
def rebuilt(n):                                 # make those moves on three real pegs
    pegs = [list(range(n, 0, -1)), [], []]
    for disc, src, dst in moves(n):
        if not pegs[src] or pegs[src][-1] != disc: return False
        if pegs[dst] and pegs[dst][-1] < disc: return False
        pegs[dst].append(pegs[src].pop())
    return pegs[2] == list(range(n, 0, -1))
def forward(c, drive, seed, last):              # a(n) = c a(n-1) + drive(n), stepped
    out, a = [], seed
    for n in range(1, last + 1):
        a = c * a + drive(n)
        out.append(a)
    return out
def row(name, vals, w=7): print(f"{name:<36}" + "".join(f"{v:>{w}}" for v in vals))
def cash(vals): return [f"{v:.2f}" for v in vals]
def yn(claim): return "yes" if claim else "no"
ns, ms = list(range(1, DISCS + 1)), list(range(1, MONTHS + 1))
fwd_h, closed_h = forward(2, lambda n: 1, 0, DISCS), [2 ** n - 1 for n in ns]
made = [len(moves(n)) for n in ns]
fwd_s = forward(RATE, lambda n: 10 * n, 0.0, MONTHS)
closed_s = [101000 * RATE ** n - 1000 * n - 101000 for n in ms]
grown = [sum(10 * k * RATE ** (n - k) for k in range(1, n + 1)) for n in ms]
flat = [5 * n * (n + 1) for n in ms]
geo_f, geo_c = forward(2, lambda n: 3 ** n, 0, 5), [3 ** (n + 1) - 3 * 2 ** n for n in range(1, 6)]
res_f, res_c = forward(2, lambda n: 2 ** n, 0, 5), [n * 2 ** n for n in range(1, 6)]
print("Tower of Hanoi, h(n) = 2 h(n-1) + 1, h(0) = 0; closed form 2^n - 1")
row("discs n", ns)
row("forward, one step at a time", fwd_h)
row("from the closed form", closed_h)
row("moves the recursion actually makes", made)
print(f"six discs: {closed_h[-1]} moves, every move legal and the tower rebuilt: {yn(rebuilt(DISCS))}")
print("Savings at 1% a month, s(n) = 1.01 s(n-1) + 10n, s(0) = 0; closed form 101000 x 1.01^n - 1000n - 101000")
row("month n", ms)
row("forward, month by month", cash(fwd_s))
row("from the closed form", cash(closed_s))
row("each deposit grown, added up", cash(grown))
row("at 0% instead, 5n(n+1)", cash(flat))
print(f"after twelve months {fwd_s[-1]:.2f}: deposits {flat[-1]:.2f} and interest {fwd_s[-1] - flat[-1]:.2f}")
print(f"t(n) = 2 t(n-1) + 3^n: forward {geo_f}, closed form 3^(n+1) - 3 x 2^n {geo_c}, same: {yn(geo_f == geo_c)}")
print(f"t(n) = 2 t(n-1) + 2^n: forward {res_f}, closed form n x 2^n {res_c}, same: {yn(res_f == res_c)}")
print(f"mistake 1, the particular part alone: {int(1 / (1 - 2))} moves for six discs, not {closed_h[-1]}")
print(f"mistake 2, the added 1 dropped: A x 2^n fitted at one disc gives {fwd_h[0] / 2 * 2 ** DISCS:.0f}, not {closed_h[-1]}")
print(f"mistake 3, a constant guess where c = 1: B = B + 1 has no solution, and a(6) = {forward(1, lambda n: 1, 0, DISCS)[-1]}")
print(f"mistake 4, resonance with a plain geometric guess: {forward(2, lambda n: 0, 0, 5)[-1]} at n = 5, not {res_c[-1]}")
assert made == fwd_h == closed_h
assert cash(fwd_s) == cash(closed_s) == cash(grown)
assert geo_f == geo_c and res_f == res_c
assert rebuilt(DISCS) and flat == [sum(10 * k for k in range(1, n + 1)) for n in ms]
print("ALL CHECKS PASS")
