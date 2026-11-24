# Constant rank theorem -- the check behind the card.  Nothing is imported.
# Two valves feed one pipe: x, y in litres per second.  F(x, y) = (x + y, (x + y)^2)
# gives total flow s and pressure drop t.  Road 1: the charts by hand.  Road 2: the
# proof's recipe run blind (Newton undo, R sampled at one v).  Ranks by a determinant test.
def F(x, y): return (x + y, (x + y) ** 2)
def jac(f, x, y, h=1e-5):                  # central differences, one column per input
    cx = [(a - b) / (2 * h) for a, b in zip(f(x + h, y), f(x - h, y))]
    cy = [(a - b) / (2 * h) for a, b in zip(f(x, y + h), f(x, y - h))]
    return [[cx[0], cy[0]], [cx[1], cy[1]]]
def det(J): return J[0][0] * J[1][1] - J[0][1] * J[1][0]
def rank(J, tol=1e-6):                     # determinant test on a 2 by 2 matrix
    if max(abs(e) for row in J for e in row) < tol: return 0
    return 2 if abs(det(J)) > tol * max(1, abs(J[0][0] * J[1][1]), abs(J[0][1] * J[1][0])) else 1
def mul(A, B): return [[sum(A[i][k] * B[k][j] for k in range(2)) for j in range(2)] for i in range(2)]
def phi(x, y): return (x + y, y)           # the recipe: keep the first output, then y
def undo(u, v, x=0.0, y=0.0):              # Newton's method on phi(x, y) = (u, v)
    for k in range(1, 50):
        J, (p, q) = jac(phi, x, y), phi(x, y)
        dx = ((u - p) * J[1][1] - (v - q) * J[0][1]) / det(J)
        dy = ((v - q) * J[0][0] - (u - p) * J[1][0]) / det(J)
        x, y = x + dx, y + dy
        if abs(dx) + abs(dy) < 1e-13: return x, y, k
    return x, y, k
def R(u, v): return F(*undo(u, v)[:2])[1]  # the leftover output in the new input chart
def psi(s, t): return (s, t - R(s, 2.0))   # road 2 output chart, R sampled at v = 2 only
def psi_hand(s, t): return (s, t - s * s)  # road 1 output chart
A = jac(F, 1, 2)
print(f"point (1, 2): F = ({F(1, 2)[0]}, {F(1, 2)[1]}); Jacobian [[{A[0][0]:.6f}, {A[0][1]:.6f}], [{A[1][0]:.6f}, {A[1][1]:.6f}]]")
grid = [(-5 + i / 2, -5 + j / 2) for i in range(21) for j in range(21)]
ranks = sorted({rank(jac(F, x, y)) for x, y in grid})
print(f"rank by determinant test at {len(grid)} grid points in [-5, 5] by [-5, 5]: {ranks}")
J0 = [[round(e) for e in row] for row in A]        # Step 1: Q and P read off the computed Jacobian
Q, P = [[1, 0], [-J0[1][0] // J0[0][0], 1]], [[1, -J0[0][1] // J0[0][0]], [0, 1]]
D = mul(mul(Q, J0), P)
print(f"linear case: J = {J0}, Q = {Q}, P = {P}, Q J P = {D}")
x, y, k = undo(3, 2)
print(f"input chart: phi(1, 2) = {phi(1, 2)}, Jacobian {[[round(e) for e in r] for r in jac(phi, 1, 2)]}, "
      f"det {det(jac(phi, 1, 2)):.6f}; Newton undo of (3, 2): ({x:.6f}, {y:.6f}) in {k} steps")
dRdv = (R(3, 2 + 1e-4) - R(3, 2 - 1e-4)) / 2e-4
print(f"in the new chart: G(3, 2) = (3, {R(3, 2):.6f}); dR/dv at (3, 2) = {abs(dRdv):.6f}")
print(f"output chart: recipe psi(3, 9) = (3, {psi(3, 9)[1]:.6f}); by hand ({psi_hand(3, 9)[0]}, {psi_hand(3, 9)[1]})")
err = max(abs(a - b) for u, v in grid for a, b in zip(psi(*F(*undo(u, v)[:2])), (u, 0.0)))
gap = max(abs(psi(*F(u, v))[1] - psi_hand(*F(u, v))[1]) for u, v in grid)
print(f"projection form on the grid: max error {err:.9f}; recipe vs hand chart {gap:.9f}")
print(f"ignored direction: F(1.5, 1.5) = ({F(1.5, 1.5)[0]:.1f}, {F(1.5, 1.5)[1]:.1f}), F(3, 0) = {F(3, 0)}")
print(f"meter reading (3, 9.4): corrected output (3, {psi_hand(3, 9.4)[1]:.1f})")
lv = [undo(3, v)[:2] for v in (1.0, 2.0, 3.0)]   # fix u = 3, let v run: the level set
print("level set s = 3: " + ", ".join(f"({a:.6f}, {b:.6f})" for a, b in lv) + f"; slope -Fx/Fy = {-A[0][0] / A[0][1]:.6f}")
def fold(x, y): return (x, y * y)
print(f"fold (x, y) to (x, y^2): rank {rank(jac(fold, 1, 0.1))} at (1, 0.1), {rank(jac(fold, 1, 0))} at (1, 0); (1, 0.1) goes to (1, {fold(1, 0.1)[1]:.6f}), (1, -0.1) goes to (1, {fold(1, -0.1)[1]:.6f})")
tan = [s * s - 6 * s + 9 for s in (3, 4)]
Jb = jac(lambda x, y: (x + y, x + y), 1, 2)
print(f"mistakes: t - s gives (3, {F(1, 2)[1] - F(1, 2)[0]}); tangent fix t - 6s + 9 at s = 3, 4 gives {tan[0]}, {tan[1]}; v = x + y gives det {abs(det(Jb)):.6f}")
assert ranks == [1] and rank(jac(fold, 1, 0.1)) == 2 and rank(jac(fold, 1, 0)) == 1   # determinant test
assert J0 == [[1, 1], [6, 6]] and D == [[1, 0], [0, 0]] and all(abs(a - b) < 1e-6 for ra, rb in zip(A, J0) for a, b in zip(ra, rb))  # linear form of F
assert abs(dRdv) < 1e-6                                                # R ignores v
assert err < 1e-9 and gap < 1e-9                                       # blind recipe = projection = hand
assert abs(x - 1) < 1e-12 and abs(y - 2) < 1e-12                       # Newton undoes phi
assert all(abs(a + b - 3) < 1e-12 for a, b in lv)                     # level set x + y = 3
print("ALL CHECKS PASS")
