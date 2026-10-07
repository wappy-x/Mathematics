# The characteristic equation and Binet -- the check behind the card.  Nothing is
# imported.  A hallway 2 tiles wide and n long is covered with 1 x 2 tiles, counted
# twice: by laying tiles on the grid one at a time, and by Binet's formula with the
# square root of 5 worked out here.  Two more step rules follow, 5, -6 and 4, -4.
def root(x):                                   # Newton's method, nothing imported
    g = x
    for _ in range(60): g = (g + x / g) / 2
    return g

def pw(x, k):                                  # powers by repeated multiplying
    out = 1.0
    for _ in range(k): out *= x
    return out

def tilings(n):                                # road one: lay tiles on the grid
    full = (1 << (2 * n)) - 1
    def lay(used):
        if used == full: return 1
        i = 0
        while used >> i & 1: i += 1
        r, c, ways = i // n, i % n, 0
        if c + 1 < n and not used >> (i + 1) & 1: ways += lay(used | 1 << i | 1 << (i + 1))
        if r == 0 and not used >> (i + n) & 1: ways += lay(used | 1 << i | 1 << (i + n))
        return ways
    return lay(0)

def run(c1, c2, a0, a1, N):                    # road two: the step rule, whole numbers
    a = [a0, a1]
    while len(a) <= N: a.append(c1 * a[-1] + c2 * a[-2])
    return a[:N + 1]
S5 = root(5.0)
PHI, PSI = (1 + S5) / 2, (1 - S5) / 2
def binet(n): return (pw(PHI, n) - pw(PSI, n)) / S5        # road three: the closed form
def row(name, xs): print(f"{name:<40}" + " ".join(str(x) for x in xs))

hall = [tilings(n) for n in range(11)]
F = run(1, 1, 0, 1, 20)
second, closed = run(5, -6, 2, 5, 8), [2 ** n + 3 ** n for n in range(9)]
rep, repclosed = run(4, -4, 1, 6, 7), [(1 + 2 * n) * 2 ** n for n in range(8)]
gaps = [abs(pw(PSI, n) / S5) for n in range(21)]
print(f"sqrt(5) = {S5:.10f}, phi = {PHI:.10f}, psi = {PSI:.10f}")
row("hallway 2 x n, tiles laid one by one:", hall)
row("F(0)..F(12) from the step rule:", F[:13])
row("F(0)..F(12) from Binet, rounded:", [round(binet(n)) for n in range(13)])
print(f"the 2 x 10 hallway: {hall[10]} coverings by laying tiles, F(11) = {F[11]} by the step rule")
print(f"phi^10/sqrt(5) = {pw(PHI, 10) / S5:.10f}, psi^10/sqrt(5) = {pw(PSI, 10) / S5:.10f}, Binet F(10) = {binet(10):.10f}")
print(f"phi^11/sqrt(5) = {pw(PHI, 11) / S5:.10f}, psi^11/sqrt(5) = {pw(PSI, 11) / S5:.10f}, Binet F(11) = {binet(11):.10f}")
print(f"largest small-root gap over n = 0..20: {max(gaps):.10f} at n = {gaps.index(max(gaps))}, under one half")
row("weights 5, -6 from seeds 2, 5:", second)
row("the same list from 2^n + 3^n:", closed)
row("weights 4, -4 from seeds 1, 6:", rep)
row("the same list from (1 + 2n) 2^n:", repclosed)
print(f"mistake 1, no n at the repeated root: a(7) = {2 ** 7}, not {rep[7]}")
print(f"mistake 2, signs carried straight across: a(4) = {11 * (-2) ** 4 - 9 * (-3) ** 4}, not {second[4]}")
print(f"mistake 3, constants fitted to seeds 2, 3: a(4) = {3 * 2 ** 4 - 3 ** 4}, not {second[4]}")
assert hall == F[1:12]                                  # laying tiles against the step rule
assert [round(binet(n)) for n in range(21)] == F        # Binet against the step rule
assert second == closed                                 # roots 2 and 3, fitted to the seeds
assert rep == repclosed                                 # the repeated root needs its n
print("ALL CHECKS PASS")
