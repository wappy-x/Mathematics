# Finite elements: cut the shape into pieces and solve one stiffness matrix

[Syllabus](../../../SYLLABUS.md) → [Engineering mathematics](../README.md) → [Fluids and Heat](../README.md#s08) → Finite elements

---

## General Overview

A steel beam sticks 3 m out of a warehouse wall over a loading bay. It is built solidly into the wall at one end and free at the other: a **cantilever**. A chain hoist hangs from its tip and lifts a 102.0 kg crate, a load of 1000 N (1 kN). The beam is the 120 mm deep I-section from [Stress, strain and bending](../07-Mechanics%20and%20Structures/07-stress-strain-and-beam-bending.md).

The engineer wants one number: how far does the tip drop? The design here allows span/180, which is 16.67 mm.

This beam has a textbook formula. A wing, a car door or a boiler bracket does not. The finite element method handles all of them the same way.

Cut the shape into a few simple pieces, called **elements**, joined at points called **nodes**. Work out, once, how one piece pushes back when its ends move. Add those pieces up into one big table of push-backs, the **stiffness matrix** $K$. Fix whatever is held, put on the loads $F$, and solve one linear system, $K u = F$, for the list $u$ of how far every node moves.

Here three 1 m elements give a tip drop of 14.69 mm, under the limit. With the beam's own weight added it is 16.32 mm, still under.

**Cut the structure into pieces whose behaviour is known exactly, add each piece's stiffness into one matrix wherever pieces share a node, fix the supports, and solve K u = F for how every node moves.**

**What kind of fact this is:** a method. For this beam, the answer at the nodes is exact; that is a theorem, proved on this card in Why it works. For a general shape the method gives an approximation that improves as the pieces shrink, and this card only states that.

### The picture: the cantilever in three pieces

<p align="center"><img src="../figures/finite-element-method-in-outline.svg" alt="A 3 m cantilever built into a wall, cut into three 1 m elements joined at nodes 0 to 3, with 1 kN at the tip; the dashed deflected shape drops 14.69 mm at the tip" width="420"></p>

To scale: 120 px per metre along the beam, and 6 px per millimetre of drop, so the bend is greatly exaggerated. The dots on the dashed curve are the three free nodes, the only places the method computes directly.

### The four steps

```mermaid
flowchart LR
  A["Cut: 3 elements, 4 nodes"] --> B["One element: its 4 by 4 stiffness k"]
  B --> C["Add every k into one 8 by 8 K"]
  C --> D["Fix the wall: remove node 0"]
  D --> E["Solve K u = F: 6 unknowns"]
```

---

## The formula

Each node can move in two ways: drop by a distance $v$ (positive down) and turn by a small angle $\theta$, the slope of the beam there. One element with end nodes 1 and 2 therefore has four end movements, $(v_1, \theta_1, v_2, \theta_2)$. Its **element stiffness matrix** $k$ gives the four end forces and moments that hold it in that shape:

$$
\begin{pmatrix} F_1 \\ M_1 \\ F_2 \\ M_2 \end{pmatrix}
= \frac{EI}{\ell^3}
\begin{pmatrix}
12 & 6\ell & -12 & 6\ell \\
6\ell & 4\ell^2 & -6\ell & 2\ell^2 \\
-12 & -6\ell & 12 & -6\ell \\
6\ell & 2\ell^2 & -6\ell & 4\ell^2
\end{pmatrix}
\begin{pmatrix} v_1 \\ \theta_1 \\ v_2 \\ \theta_2 \end{pmatrix}
$$

**Read it aloud:** the forces at a piece's ends are its bending stiffness over its length cubed, times a fixed table of numbers, times how its ends have moved.

Adding every element's $k$ into the rows and columns of its own two nodes gives the whole structure's stiffness matrix $K$, and

$$K\,u = F, \qquad u = (v_1, \theta_1, v_2, \theta_2, v_3, \theta_3), \qquad F = (0, 0, 0, 0, P, 0).$$

**Read it aloud:** the whole beam's stiffness times the list of every node's movement equals the list of loads put on the nodes.

The wall node is left out of $u$ because it cannot move. Solving $K u = F$ is the job of [Solving A x = b](../../03-Algebra/05-Solving%20Systems/01-matrix-equation-ax-b.md); the code here uses Gaussian elimination written out.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $P$ | load at the tip, N | 1000 N | every movement grows in proportion |
| $L$, $x$ | length of the cantilever, and distance from the wall, m | $L$ = 3 m | tip drop grows as $L^3$ |
| $\ell$, $s$ | length of one element, m; $s = x/\ell$, position along one element, 0 to 1 | $\ell$ = 1 m | at the nodes, nothing here: the answer is exact for any $\ell$ |
| $E$, $I$, $EI$ | Young's modulus (how stiff the steel is: stress per unit stretch), second moment of area (how well the section's shape resists bending), and their product, the bending stiffness, N m² | 200 GPa, 306.31 cm⁴, 612626 N m² | every movement shrinks |
| $v$, $\theta$ | drop of a node (m, down positive) and its slope (rad) | tip: 14.69 mm, 0.007345 rad | — |
| $k$ | element stiffness matrix: end forces per unit end movement | the 4 by 4 above, units of $EI/\ell^3$ = 612626 N/m | — |
| $K$ | the assembled stiffness matrix of the whole beam | 6 by 6 after the wall is fixed | — |
| $u$, $d$ | list of all free node movements; $d$, the four end movements of one element | 6 numbers; 4 numbers | — |
| $F$; $F_1, M_1, F_2, M_2$ | list of loads on the free nodes; the end forces (N) and moments (N m) of one element | $P$ at the tip, zeros elsewhere | $u$ grows in proportion |
| $N_1 \dots N_4$ | shape functions: the four cubic curves an element can be bent into | used in Why it works | — |
| $w$ | the beam's own weight per metre, N/m | 98.46 N/m | adds $wL^4/8EI$ to the tip |
| $M$, $W$, $c$, $\sigma$ | bending moment (N m); section modulus $I/c$ (m³), with $c$ the distance to the outer face; bending stress (Pa) | at the wall $M$ = 3000 N m, $W$ = 51.05 cm³, $c$ = half the 120 mm depth, $\sigma$ = 58.76 MPa | stress grows with $P$ and $L$ |

### When it holds

- **Linear elastic steel.** $K$ is a fixed matrix only while stress stays in proportion to strain. Counting the tip load alone, without the beam's own weight, it yields (starts to bend permanently) at a tip load of 4680 N. At 10000 N the method still reports 146.9 mm and 588 MPa, but the steel is past the 275 MPa yield stress of grade S275 (EN 1993-1-1, Table 3.1, cited on [Stress, strain and bending](../07-Mechanics%20and%20Structures/07-stress-strain-and-beam-bending.md)) and both numbers are wrong.
- **Small slopes.** The tip turns 0.007345 rad, well under a degree, so treating slope as the angle is safe. A fishing rod bent into a curve breaks this, and the matrix must be rebuilt as the shape changes.
- **Loads put on the nodes the right way.** Between nodes this beam carries no load, so its true shape on each piece is a cubic, and the element's cubics contain it: the nodes are exact. A spread load such as the beam's own weight bends each piece into a quartic (a fourth-degree curve) instead. It goes onto the nodes as **consistent loads** (the four end loads $\int_0^\ell w\,N_i\,dx$, which do the same work on the element's shapes as the spread load): $w\ell/2$, $w\ell^2/12$, $w\ell/2$, $-w\ell^2/12$ per element. With them a beam's node answers stay exact, 1.627 mm, and only the cubic between nodes approximates the quartic. Putting the weight on as plain forces drops the end moments $\pm w\ell^2/12$ and gives 1.687 mm.
- **A rigid wall.** The model fixes both the drop and the slope at the wall. A real bolted end plate lets the beam turn a little, which adds drop the model misses.
- **A slender beam.** The elements use the bending equation from [Stress, strain and bending](../07-Mechanics%20and%20Structures/07-stress-strain-and-beam-bending.md), which ignores shear. A 3 m beam that is 0.12 m deep is slender enough.

---

## Why it works

### Step 0: a piece only has to know how its ends push back

Cut the beam at a node. The two pieces meeting there each push on the node with some force and twist it with some moment. The node is still, so those pushes plus the outside load add to zero. If each piece's push is known in terms of how its ends moved, every node gives one equation, and the whole structure becomes a linear system. That is the method. Everything else is finding the pushes.

### Step 1: an unloaded piece of beam bends into a cubic

The beam card gives $EI\,v'' = -M(x)$: curvature is moment over bending stiffness. With no load between its ends, the moment along a piece changes in a straight line, so $v''$ is a straight line and $v$ is a cubic. A cubic has four coefficients, and four end values fix it: $v_1, \theta_1, v_2, \theta_2$.

Write $s = x/\ell$ for the position along the element, 0 at the left end and 1 at the right. The four **shape functions** are the cubics that are 1 in one end value and 0 in the other three:

$$N_1 = 1 - 3s^2 + 2s^3,\quad N_2 = \ell(s - 2s^2 + s^3),\quad N_3 = 3s^2 - 2s^3,\quad N_4 = \ell(s^3 - s^2).$$

Any shape of the element is $v = N_1 v_1 + N_2 \theta_1 + N_3 v_2 + N_4 \theta_2$.

### Step 2: the stiffness matrix comes from the stored energy

A bent beam stores energy $\tfrac12 \int EI\,(v'')^2\,dx$. Put the element's cubic in, and the energy becomes $\tfrac12 d^{\mathsf T} k\, d$, where $d$ is the list of four end values, $d^{\mathsf T}$ is the same list written as a row, and the entry in row $i$, column $j$ of $k$ is

$$k_{ij} = \int_0^\ell EI\,N_i''\,N_j''\,dx.$$

One entry by hand: $N_1'' = (-6 + 12s)/\ell^2$, so $k_{11} = \dfrac{EI}{\ell^3}\int_0^1 (12s - 6)^2\,ds = \dfrac{EI}{\ell^3}\cdot 12$. The other fifteen follow the same way and give the matrix in The formula. The code computes all sixteen by numerical integration and checks them against the table.

Each column has a physical reading. Column 1 is the set of end forces and moments needed to drop the left end by 1 m while holding the other three end values at zero.

### Step 3: assembly is adding, because energies add

The beam's total energy is the sum of its elements' energies. Node 1 belongs to element 1 (as its right end) and element 2 (as its left end), so its movements appear in both, and their entries add. Node 1's up-down diagonal entry is $12 + 12 = 24$. Its turning diagonal entry is $4 + 4 = 8$. The coupling between its drop and its turn is $-6 + 6 = 0$.

The loads do work $F^{\mathsf T} u$. The beam settles where the total, $\tfrac12 u^{\mathsf T} K u - F^{\mathsf T} u$, is least, and setting its slope to zero gives $K u = F$. The same equation is the force balance of Step 0, node by node.

### Step 4: supports make the matrix solvable

Before the wall is fixed, $K$ is 8 by 8 and has no inverse. Lift the whole beam 1 m without bending it, or turn it as a rigid stick: $K$ times either movement is 0 N, so no force resists it, and a load would push the beam away without limit. Fixing $v_0 = \theta_0 = 0$ removes those two rows and columns. What is left, 6 by 6, has an inverse, and the solve gives one answer.

### Step 5: why the nodes are exact here, and not in general

The loads act only at nodes, so the true shape on each piece is a cubic (Step 1), which is one of the shapes the element can take. Among all the shapes built from these pieces, the method picks the one of least total energy. The true shape is among them and is the least of all, so the method returns it. That is why one, two, three or six elements all give 14.6909 mm at the tip.

For a plate, a solid or a heat-conducting fin, the true shape is not a polynomial on each piece. The method then returns the best shape the pieces allow, measured by energy, and that best shape closes in on the truth as the pieces shrink. How fast it closes in is the subject of [Assembly and error](../../16-Numerical%20analysis/07-PDE%20Solvers/08-finite-element-assembly-and-error.md).

### The contrast: finite differences

[Finite differences](../../08-Differential%20equations%20and%20dynamics/07-Series%20Solutions%20and%20Boundary%20Problems/07-finite-differences-for-boundary-problems.md) replace each derivative at a grid point by a difference of neighbouring values. Finite elements replace the shape itself by simple pieces, and for this tip-loaded beam they keep the physics exact on each piece.

On the same three 1 m pieces, finite differences give a tip drop of 15.51 mm against the true 14.69 mm. Their error falls as the spacing squared: 14.6990 mm with 30 steps, 14.6909 mm with 300. Finite elements also bend to any shape of mesh, which a regular grid cannot.

### What this outline leaves out

Triangles, bricks and curved elements; the general recipe for turning any differential equation into element matrices (the weak form); building meshes; error bounds; and solvers for matrices with millions of rows. [Finite elements](../../16-Numerical%20analysis/07-PDE%20Solvers/07-finite-elements-galerkin-and-hat-functions.md) and [Assembly and error](../../16-Numerical%20analysis/07-PDE%20Solvers/08-finite-element-assembly-and-error.md) take these up. The mathematics of convergence belongs to the partial differential equations wing, and large sparse solvers to the numerical analysis wing.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| bending stiffness | $EI \approx$ 200 GPa × 306.31 cm⁴ | 612626 N m² |
| one element, $\ell$ = 1 m | $EI/\ell^3$ | 612626 N/m |
| first row of $k$ | in units of $EI/\ell^3$ | 12, 6, −12, 6 |
| node 1, shared by elements 1 and 2 | drop 12 + 12, turn 4 + 4, coupling −6 + 6 | 24, 8, 0 |
| free $K$, units $EI/\ell^3$ | rows listed below | 6 by 6 |
| unit of movement | $P\ell^3/EI$ = 1000 / 612626 m | 1.6323 mm |
| solve $Ku = F$ | $u$ in units of $P\ell^3/EI$ | 1.3333, 2.5000, 4.6667, 4.0000, 9.0000, 4.5000 |
| check row 1 (node 1 drop) | 24 × 1.3333 − 12 × 4.6667 + 6 × 4.0000 = 32 − 56 + 24 | 0 P |
| check row 5 (tip drop) | −56 − 24 + 12 × 9.0000 − 6 × 4.5000 = −56 − 24 + 108 − 27 | 1 P |
| tip drop | 9.0000 × 1.6323 mm | **14.69 mm** |
| against the formula | $PL^3/3EI$ | 14.69 mm |
| own weight added | $wL^4/8EI$ = 1.627 mm | 16.32 mm, limit 16.67 mm |
| stress at the wall | $PL/W$ = 3000 N m / 51.05 cm³ | 58.76 MPa |

The six free rows of $K$, in units of $EI/\ell^3$, ordered $v_1, \theta_1, v_2, \theta_2, v_3, \theta_3$:

```
 24   0  -12   6    0   0
  0   8   -6   2    0   0
-12  -6   24   0  -12   6
  6   2    0   8   -6   2
  0   0  -12  -6   12  -6
  0   0    6   2   -6   4
```

Check rows 1 and 5 equal the loads, 0 and $P$: the solve is right. The tip drops 14.69 mm under the crate and 16.32 mm with the beam's own weight, inside the 16.67 mm limit, and under the crate alone the steel at the wall works at 58.76 MPa, far below yield. The hoist beam passes, and drop, not strength, is the tighter limit.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| No supports | $K$ × rigid lift = 0.0 N, no answer | Nothing holds the beam, so $K$ has no inverse |
| Assemble by overwriting, not adding | tip −3.26 mm, rising | Node 1 and node 2 lose one element's stiffness each |
| Own weight lumped as nodal forces only | 1.687 mm against 1.627 mm | The end moments $\pm w\ell^2/12$ of each element are dropped |
| Finite differences on the same 3 pieces | 15.51 mm against 14.69 mm | Differences approximate the derivatives; elements keep each piece exact |
| Load past yield, 10000 N | 146.9 mm, 588 MPa | Yield is at 4680 N; beyond it $K$ no longer describes the steel |

---

## Code, from first principles, and it actually runs

The code builds the element matrix from the formula, then again by integrating $EI\,N_i''\,N_j''$ by Simpson's rule (a weighted sum of the integrand at evenly spaced points), and checks the two agree. It assembles $K$, fixes the wall and solves by Gaussian elimination. The tip drop is then reached four independent ways: the elements; the closed form $PL^3/3EI$; an energy integral of the bending moment, by Simpson's rule; and finite differences on 300 steps. It also checks the wall reactions against the load, repeats the solve with 1, 2 and 6 elements, and prints every number on the card.

### Python

```python
# Finite elements in outline -- the check behind the card.  Standard library only.
# A 3 m steel cantilever (the 120 mm I) holds 1 kN at its tip.  Cut it into three
# 1 m beam elements, assemble one stiffness matrix, fix the wall, solve K u = F.
L, NE, P, E, G, RHO = 3.0, 3, 1000.0, 200e9, 9.80665, 7850.0  # m, pieces, N, Pa, m/s^2, kg/m^3
SIGMA_Y = 275e6                                               # S275 yield stress, Pa
h, b, tf, tw = 120.0, 64.0, 6.3, 4.4                          # the 120 mm I, mm
I = (2 * (b * tf**3 / 12 + b * tf * ((h - tf) / 2) ** 2) + tw * (h - 2 * tf) ** 3 / 12) * 1e-12
EI, W = E * I, I / (h / 2 * 1e-3)                             # N m^2, section modulus m^3
w_self = (2 * b * tf + (h - 2 * tf) * tw) * 1e-6 * RHO * G    # own weight, N per m

def k_formula(le):             # element stiffness, unknowns (v1, th1, v2, th2): road 1
    a, l = EI / le**3, le
    return [[12*a, 6*l*a, -12*a, 6*l*a], [6*l*a, 4*l*l*a, -6*l*a, 2*l*l*a],
            [-12*a, -6*l*a, 12*a, -6*l*a], [6*l*a, 2*l*l*a, -6*l*a, 4*l*l*a]]

def curv(s, le):               # second derivatives of the four cubic shape functions
    return [(-6 + 12*s) / le**2, (-4 + 6*s) / le, (6 - 12*s) / le**2, (-2 + 6*s) / le]

def k_energy(le, n=100):       # road 2: k_ij = integral of EI N_i'' N_j'' dx, by Simpson
    k = [[0.0] * 4 for _ in range(4)]
    for m in range(n + 1):
        wt, c = (1 if m in (0, n) else 4 if m % 2 else 2) * le / n / 3, curv(m / n, le)
        for i in range(4):
            for j in range(4):
                k[i][j] += wt * EI * c[i] * c[j]
    return k

def assemble(ne, le, add=True):  # each element adds its 4x4 block at its two nodes
    n = 2 * (ne + 1)
    K, ke = [[0.0] * n for _ in range(n)], k_formula(le)
    for e in range(ne):
        for i in range(4):
            for j in range(4):
                K[2*e+i][2*e+j] = (K[2*e+i][2*e+j] if add else 0.0) + ke[i][j]
    return K

def solve(A, rhs):             # Gaussian elimination with row swaps, then back substitution
    n = len(rhs)
    M = [A[i][:] + [rhs[i]] for i in range(n)]
    for c in range(n):
        p = max(range(c, n), key=lambda r: abs(M[r][c]))
        M[c], M[p] = M[p], M[c]
        for r in range(c + 1, n):
            f = M[r][c] / M[c][c]
            M[r] = [M[r][k] - f * M[c][k] for k in range(n + 1)]
    x = [0.0] * n
    for i in range(n - 1, -1, -1):
        x[i] = (M[i][n] - sum(M[i][k] * x[k] for k in range(i + 1, n))) / M[i][i]
    return x

def fem(ne, loads, add=True):  # fix the wall (drop v0, th0), solve for the free 2*ne
    K = assemble(ne, L / ne, add)
    return [0.0, 0.0] + solve([row[2:] for row in K[2:]], loads[2:]), K

def fd_tip(n):                 # finite differences on v'' = P(L - x)/EI, ghost point at the wall
    hh, v = L / n, [0.0, 0.0]
    v[1] = hh * hh * P * L / EI / 2
    for i in range(1, n):
        v.append(2 * v[i] - v[i - 1] + hh * hh * P * (L - i * hh) / EI)
    return v[n]

def exact(x): return P * x * x * (3 * L - x) / (6 * EI)        # closed-form sag, m
def tip_load(ne): return [0.0] * (2 * ne) + [P, 0.0]

print(f"cantilever: {L:.0f} m, 120 mm I, I = {I * 1e8:.2f} cm^4, EI = {EI:.0f} N m^2, tip load {P:.0f} N = {P / G:.1f} kg")
ke, k2 = k_formula(1.0), k_energy(1.0)
print("element k for 1 m, in units of EI/m^3:", " ".join(f"{ke[0][j] / EI:.0f}" for j in range(4)),
      "|", " ".join(f"{ke[1][j] / EI:.0f}" for j in range(4)))
assert max(abs(ke[i][j] - k2[i][j]) for i in range(4) for j in range(4)) < 1e-9 * EI
u, K = fem(NE, tip_load(NE))
print("assembled K, free rows, units EI/m^3:")
for row in K[2:]:
    print("  " + "".join(f"{x / EI:6.0f}" for x in row[2:]))
print(f"u in units of P m^3/EI = {P / EI * 1e3:.4f} mm:", " ".join(f"{x * EI / P:.4f}" for x in u[2:]))
for r in (2, 6):                               # two rows of K u = F, term by term
    print(f"row {r - 1} of K u:", " ".join(f"{K[r][c] * u[c] / P:+.0f}" for c in range(2, len(u)) if K[r][c]),
          f"= {round(sum(K[r][c] * u[c] for c in range(len(u))) / P)} P")
for i in range(1, NE + 1):
    print(f"node {i} at {i * L / NE:.2f} m: sag {u[2*i] * 1e3:6.3f} mm, slope {u[2*i+1]:.6f} rad,"
          f" exact {exact(i * L / NE) * 1e3:6.3f} mm")
tip = u[2 * NE]
d_energy, nn = 0.0, 300                                         # road 3: unit-load integral
for m in range(nn + 1):
    x = m * L / nn
    d_energy += (1 if m in (0, nn) else 4 if m % 2 else 2) * P * (L - x) ** 2 / EI * L / nn / 3
print(f"tip sag: elements {tip * 1e3:.4f} mm, PL^3/3EI {P * L**3 / (3 * EI) * 1e3:.4f} mm,"
      f" energy {d_energy * 1e3:.4f} mm")
assert abs(tip - P * L**3 / (3 * EI)) < 1e-9 and abs(d_energy - tip) < 1e-9
assert max(abs(u[2*i] - exact(i * L / NE)) for i in range(NE + 1)) < 1e-12
fw = [sum(K[r][c] * u[c] for c in range(len(u))) for r in range(2)]
print(f"wall reaction from K u: {-fw[0]:.1f} N up, {-fw[1]:.1f} N m; W = {W * 1e6:.2f} cm^3, stress at wall {-fw[1] / W / 1e6:.2f} MPa")
assert abs(-fw[0] - P) < 1e-6 and abs(-fw[1] - P * L) < 1e-6
for ne in (1, 2, 6):
    print(f"elements: {ne}, tip {fem(ne, tip_load(ne))[0][2 * ne] * 1e3:.4f} mm")
for n in (3, 30, 300):
    print(f"finite differences, {n} steps: tip {fd_tip(n) * 1e3:.4f} mm")
assert abs(fd_tip(300) - tip) / tip < 1e-4 and 0.01 < abs(fd_tip(3) - tip) / tip
def weight_tips(ne):           # own weight w per metre: consistent loads, and nodal forces only
    le, fq = L / ne, [0.0] * (2 * ne + 2)
    fl = fq[:]
    for e in range(ne):
        for i, f in enumerate((w_self * le / 2, w_self * le * le / 12, w_self * le / 2, -w_self * le * le / 12)):
            fq[2 * e + i] += f
        fl[2 * e] += w_self * le / 2
        fl[2 * e + 2] += w_self * le / 2
    return fem(ne, fq)[0][2 * ne], fem(ne, fl)[0][2 * ne]
le, (uw, ul) = L / NE, weight_tips(NE)
uw_exact = w_self * L**4 / (8 * EI)
print(f"own weight {w_self:.2f} N/m: tip {uw * 1e3:.3f} mm (consistent loads), exact wL^4/8EI {uw_exact * 1e3:.3f} mm")
assert abs(uw - uw_exact) < 1e-12
print(f"total tip {(tip + uw) * 1e3:.2f} mm against limit L/180 = {L / 180 * 1e3:.2f} mm")
rigid = [1.0, 0.0] * (NE + 1)
spin = [v for i in range(NE + 1) for v in (i * le, 1.0)]
for name, z in (("lift", rigid), ("spin", spin)):
    print(f"wrong: no supports, K times rigid {name} = {max(abs(sum(r[c] * z[c] for c in range(len(z)))) for r in K):.1f} N")
u_over = fem(NE, tip_load(NE), add=False)[0][2 * NE]
print(f"wrong: assembled by overwriting, not adding: tip {u_over * 1e3:.2f} mm")
print(f"wrong: own weight lumped as nodal forces only: tip {ul * 1e3:.3f} mm against {uw_exact * 1e3:.3f} mm")
print(f"wrong: finite differences on the same 3 pieces: tip {fd_tip(3) * 1e3:.2f} mm")
assert u_over < 0 < tip and abs(ul - uw_exact) > 0.02 * uw_exact
P_y = SIGMA_Y * W / L
print(f"outside the model: yield at P = {P_y:.0f} N; at 10000 N it says {10000 * L**3 / (3 * EI) * 1e3:.1f} mm,"
      f" {10000 * L / W / 1e6:.0f} MPa")
print(f"try: 5000 N tip {5 * tip * 1e3:.2f} mm, {5000 * L / W / 1e6:.0f} MPa;"
      f" L = 4 m tip {P * 64 / (3 * EI) * 1e3:.2f} mm against {4 / 180 * 1e3:.2f} mm;"
      f" 6 elements, own weight lumped {weight_tips(6)[1] * 1e3:.3f} mm")
print("figure, 120 px/m, 6 px/mm, sag px at 0.25 m steps:",
      " ".join(f"{exact(0.25 * k) * 6e3:.1f}" for k in range(13)))
print("ALL CHECKS PASS")
```

**Ran 2026-11-11 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
cantilever: 3 m, 120 mm I, I = 306.31 cm^4, EI = 612626 N m^2, tip load 1000 N = 102.0 kg
element k for 1 m, in units of EI/m^3: 12 6 -12 6 | 6 4 -6 2
assembled K, free rows, units EI/m^3:
      24     0   -12     6     0     0
       0     8    -6     2     0     0
     -12    -6    24     0   -12     6
       6     2     0     8    -6     2
       0     0   -12    -6    12    -6
       0     0     6     2    -6     4
u in units of P m^3/EI = 1.6323 mm: 1.3333 2.5000 4.6667 4.0000 9.0000 4.5000
row 1 of K u: +32 -56 +24 = 0 P
row 5 of K u: -56 -24 +108 -27 = 1 P
node 1 at 1.00 m: sag  2.176 mm, slope 0.004081 rad, exact  2.176 mm
node 2 at 2.00 m: sag  7.617 mm, slope 0.006529 rad, exact  7.617 mm
node 3 at 3.00 m: sag 14.691 mm, slope 0.007345 rad, exact 14.691 mm
tip sag: elements 14.6909 mm, PL^3/3EI 14.6909 mm, energy 14.6909 mm
wall reaction from K u: 1000.0 N up, 3000.0 N m; W = 51.05 cm^3, stress at wall 58.76 MPa
elements: 1, tip 14.6909 mm
elements: 2, tip 14.6909 mm
elements: 6, tip 14.6909 mm
finite differences, 3 steps: tip 15.5070 mm
finite differences, 30 steps: tip 14.6990 mm
finite differences, 300 steps: tip 14.6909 mm
own weight 98.46 N/m: tip 1.627 mm (consistent loads), exact wL^4/8EI 1.627 mm
total tip 16.32 mm against limit L/180 = 16.67 mm
wrong: no supports, K times rigid lift = 0.0 N
wrong: no supports, K times rigid spin = 0.0 N
wrong: assembled by overwriting, not adding: tip -3.26 mm
wrong: own weight lumped as nodal forces only: tip 1.687 mm against 1.627 mm
wrong: finite differences on the same 3 pieces: tip 15.51 mm
outside the model: yield at P = 4680 N; at 10000 N it says 146.9 mm, 588 MPa
try: 5000 N tip 73.45 mm, 294 MPa; L = 4 m tip 34.82 mm against 22.22 mm; 6 elements, own weight lumped 1.642 mm
figure, 120 px/m, 6 px/mm, sag px at 0.25 m steps: 0.0 0.9 3.5 7.6 13.1 19.8 27.5 36.2 45.7 55.8 66.3 77.2 88.1
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// Finite elements in outline -- the same check as the Python, in Rust.  No crates.
// A 3 m steel cantilever (the 120 mm I) holds 1 kN at its tip.  Cut it into three
// 1 m beam elements, assemble one stiffness matrix, fix the wall, solve K u = F.
const L: f64 = 3.0; const NE: usize = 3; const P: f64 = 1000.0; const E: f64 = 200e9;
const G: f64 = 9.80665; const RHO: f64 = 7850.0; const SIGMA_Y: f64 = 275e6;
const H: f64 = 120.0; const B: f64 = 64.0; const TF: f64 = 6.3; const TW: f64 = 4.4; // mm

fn ei() -> f64 {
    let i = 2.0 * (B * TF.powi(3) / 12.0 + B * TF * ((H - TF) / 2.0).powi(2)) + TW * (H - 2.0 * TF).powi(3) / 12.0;
    E * i * 1e-12
}
fn k_formula(le: f64) -> Vec<Vec<f64>> {     // element stiffness, unknowns (v1, th1, v2, th2): road 1
    let (a, l) = (ei() / le.powi(3), le);
    vec![vec![12.0*a, 6.0*l*a, -12.0*a, 6.0*l*a], vec![6.0*l*a, 4.0*l*l*a, -6.0*l*a, 2.0*l*l*a],
         vec![-12.0*a, -6.0*l*a, 12.0*a, -6.0*l*a], vec![6.0*l*a, 2.0*l*l*a, -6.0*l*a, 4.0*l*l*a]]
}
fn curv(s: f64, le: f64) -> [f64; 4] {        // second derivatives of the four cubic shape functions
    [(-6.0 + 12.0*s) / le.powi(2), (-4.0 + 6.0*s) / le, (6.0 - 12.0*s) / le.powi(2), (-2.0 + 6.0*s) / le]
}
fn simpson_w(m: usize, n: usize) -> f64 { if m == 0 || m == n { 1.0 } else if m % 2 == 1 { 4.0 } else { 2.0 } }
fn k_energy(le: f64, n: usize) -> Vec<Vec<f64>> { // road 2: k_ij = integral of EI N_i'' N_j'' dx
    let mut k = vec![vec![0.0; 4]; 4];
    for m in 0..=n {
        let (wt, c) = (simpson_w(m, n) * le / n as f64 / 3.0, curv(m as f64 / n as f64, le));
        for i in 0..4 { for j in 0..4 { k[i][j] += wt * ei() * c[i] * c[j]; } }
    }
    k
}
fn assemble(ne: usize, le: f64, add: bool) -> Vec<Vec<f64>> { // each element adds its 4x4 block
    let n = 2 * (ne + 1);
    let (mut k, ke) = (vec![vec![0.0; n]; n], k_formula(le));
    for e in 0..ne { for i in 0..4 { for j in 0..4 {
        k[2*e+i][2*e+j] = (if add { k[2*e+i][2*e+j] } else { 0.0 }) + ke[i][j];
    } } }
    k
}
fn solve(a: &Vec<Vec<f64>>, rhs: &[f64]) -> Vec<f64> { // Gaussian elimination with row swaps
    let n = rhs.len();
    let mut m: Vec<Vec<f64>> = (0..n).map(|i| { let mut r = a[i].clone(); r.push(rhs[i]); r }).collect();
    for c in 0..n {
        let mut p = c;
        for r in c..n { if m[r][c].abs() > m[p][c].abs() { p = r; } }
        m.swap(c, p);
        for r in c + 1..n {
            let f = m[r][c] / m[c][c];
            m[r] = (0..=n).map(|k| m[r][k] - f * m[c][k]).collect();
        }
    }
    let mut x = vec![0.0; n];
    for i in (0..n).rev() {
        let mut s = 0.0;
        for k in i + 1..n { s += m[i][k] * x[k]; }
        x[i] = (m[i][n] - s) / m[i][i];
    }
    x
}
fn fem(ne: usize, loads: &[f64], add: bool) -> (Vec<f64>, Vec<Vec<f64>>) { // fix the wall, solve
    let k = assemble(ne, L / ne as f64, add);
    let free: Vec<Vec<f64>> = k[2..].iter().map(|r| r[2..].to_vec()).collect();
    let mut u = vec![0.0, 0.0];
    u.extend(solve(&free, &loads[2..]));
    (u, k)
}
fn fd_tip(n: usize) -> f64 {                  // finite differences on v'' = P(L - x)/EI, ghost point
    let hh = L / n as f64;
    let mut v = vec![0.0, hh * hh * P * L / ei() / 2.0];
    for i in 1..n { let nv = 2.0 * v[i] - v[i - 1] + hh * hh * P * (L - i as f64 * hh) / ei(); v.push(nv); }
    v[n]
}
fn exact(x: f64) -> f64 { P * x * x * (3.0 * L - x) / (6.0 * ei()) }
fn tip_load(ne: usize) -> Vec<f64> { let mut f = vec![0.0; 2 * ne + 2]; f[2 * ne] = P; f }

fn main() {
    let ei = ei();
    let i_m4 = ei / E;
    let w = i_m4 / (H / 2.0 * 1e-3);
    let w_self = (2.0 * B * TF + (H - 2.0 * TF) * TW) * 1e-6 * RHO * G;
    println!("cantilever: {:.0} m, 120 mm I, I = {:.2} cm^4, EI = {:.0} N m^2, tip load {:.0} N = {:.1} kg", L, i_m4 * 1e8, ei, P, P / G);
    let (ke, k2) = (k_formula(1.0), k_energy(1.0, 100));
    let r0: Vec<String> = (0..4).map(|j| format!("{:.0}", ke[0][j] / ei)).collect();
    let r1: Vec<String> = (0..4).map(|j| format!("{:.0}", ke[1][j] / ei)).collect();
    println!("element k for 1 m, in units of EI/m^3: {} | {}", r0.join(" "), r1.join(" "));
    let mut dk: f64 = 0.0;
    for i in 0..4 { for j in 0..4 { dk = dk.max((ke[i][j] - k2[i][j]).abs()); } }
    assert!(dk < 1e-9 * ei);
    let (u, k) = fem(NE, &tip_load(NE), true);
    println!("assembled K, free rows, units EI/m^3:");
    for row in &k[2..] { println!("  {}", row[2..].iter().map(|x| format!("{:6.0}", x / ei)).collect::<String>()); }
    println!("u in units of P m^3/EI = {:.4} mm: {}", P / ei * 1e3, u[2..].iter().map(|x| format!("{:.4}", x * ei / P)).collect::<Vec<_>>().join(" "));
    for r in [2, 6] {                          // two rows of K u = F, term by term
        let terms: Vec<String> = (2..u.len()).filter(|&c| k[r][c] != 0.0).map(|c| format!("{:+.0}", k[r][c] * u[c] / P)).collect();
        let mut s = 0.0;
        for c in 0..u.len() { s += k[r][c] * u[c]; }
        println!("row {} of K u: {} = {} P", r - 1, terms.join(" "), (s / P).round() as i64);
    }
    for i in 1..=NE {
        let x = i as f64 * L / NE as f64;
        println!("node {} at {:.2} m: sag {:6.3} mm, slope {:.6} rad, exact {:6.3} mm", i, x, u[2*i] * 1e3, u[2*i+1], exact(x) * 1e3);
    }
    let tip = u[2 * NE];
    let (mut d_energy, nn) = (0.0, 300);       // road 3: unit-load integral
    for m in 0..=nn {
        let x = m as f64 * L / nn as f64;
        d_energy += simpson_w(m, nn) * P * (L - x).powi(2) / ei * L / nn as f64 / 3.0;
    }
    println!("tip sag: elements {:.4} mm, PL^3/3EI {:.4} mm, energy {:.4} mm", tip * 1e3, P * L.powi(3) / (3.0 * ei) * 1e3, d_energy * 1e3);
    assert!((tip - P * L.powi(3) / (3.0 * ei)).abs() < 1e-9 && (d_energy - tip).abs() < 1e-9);
    assert!((0..=NE).all(|i| (u[2*i] - exact(i as f64 * L / NE as f64)).abs() < 1e-12));
    let fw: Vec<f64> = (0..2).map(|r| { let mut s = 0.0; for c in 0..u.len() { s += k[r][c] * u[c]; } s }).collect();
    println!("wall reaction from K u: {:.1} N up, {:.1} N m; W = {:.2} cm^3, stress at wall {:.2} MPa", -fw[0], -fw[1], w * 1e6, -fw[1] / w / 1e6);
    assert!((-fw[0] - P).abs() < 1e-6 && (-fw[1] - P * L).abs() < 1e-6);
    for ne in [1, 2, 6] { println!("elements: {}, tip {:.4} mm", ne, fem(ne, &tip_load(ne), true).0[2 * ne] * 1e3); }
    for n in [3, 30, 300] { println!("finite differences, {} steps: tip {:.4} mm", n, fd_tip(n) * 1e3); }
    assert!((fd_tip(300) - tip).abs() / tip < 1e-4 && 0.01 < (fd_tip(3) - tip).abs() / tip);
    let weight_tips = |ne: usize| -> (f64, f64) { // own weight: consistent loads, and nodal forces only
        let le = L / ne as f64;
        let (mut fq, mut fl) = (vec![0.0; 2 * ne + 2], vec![0.0; 2 * ne + 2]);
        for e in 0..ne {
            let parts = [w_self * le / 2.0, w_self * le * le / 12.0, w_self * le / 2.0, -w_self * le * le / 12.0];
            for i in 0..4 { fq[2 * e + i] += parts[i]; }
            fl[2 * e] += w_self * le / 2.0;
            fl[2 * e + 2] += w_self * le / 2.0;
        }
        (fem(ne, &fq, true).0[2 * ne], fem(ne, &fl, true).0[2 * ne])
    };
    let (le, (uw, ul)) = (L / NE as f64, weight_tips(NE));
    let uw_exact = w_self * L.powi(4) / (8.0 * ei);
    println!("own weight {:.2} N/m: tip {:.3} mm (consistent loads), exact wL^4/8EI {:.3} mm", w_self, uw * 1e3, uw_exact * 1e3);
    assert!((uw - uw_exact).abs() < 1e-12);
    println!("total tip {:.2} mm against limit L/180 = {:.2} mm", (tip + uw) * 1e3, L / 180.0 * 1e3);
    let rigid: Vec<f64> = (0..=NE).flat_map(|_| [1.0, 0.0]).collect();
    let spin: Vec<f64> = (0..=NE).flat_map(|i| [i as f64 * le, 1.0]).collect();
    for (name, z) in [("lift", &rigid), ("spin", &spin)] {
        let mut worst: f64 = 0.0;
        for r in &k { let mut s = 0.0; for c in 0..z.len() { s += r[c] * z[c]; } worst = worst.max(s.abs()); }
        println!("wrong: no supports, K times rigid {} = {:.1} N", name, worst);
    }
    let u_over = fem(NE, &tip_load(NE), false).0[2 * NE];
    println!("wrong: assembled by overwriting, not adding: tip {:.2} mm", u_over * 1e3);
    println!("wrong: own weight lumped as nodal forces only: tip {:.3} mm against {:.3} mm", ul * 1e3, uw_exact * 1e3);
    println!("wrong: finite differences on the same 3 pieces: tip {:.2} mm", fd_tip(3) * 1e3);
    assert!(u_over < 0.0 && 0.0 < tip && (ul - uw_exact).abs() > 0.02 * uw_exact);
    let p_y = SIGMA_Y * w / L;
    println!("outside the model: yield at P = {:.0} N; at 10000 N it says {:.1} mm, {:.0} MPa", p_y, 10000.0 * L.powi(3) / (3.0 * ei) * 1e3, 10000.0 * L / w / 1e6);
    println!("try: 5000 N tip {:.2} mm, {:.0} MPa; L = 4 m tip {:.2} mm against {:.2} mm; 6 elements, own weight lumped {:.3} mm",
             5.0 * tip * 1e3, 5000.0 * L / w / 1e6, P * 64.0 / (3.0 * ei) * 1e3, 4.0 / 180.0 * 1e3, weight_tips(6).1 * 1e3);
    println!("figure, 120 px/m, 6 px/mm, sag px at 0.25 m steps: {}", (0..13).map(|k| format!("{:.1}", exact(0.25 * k as f64) * 6e3)).collect::<Vec<_>>().join(" "));
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-11 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
cantilever: 3 m, 120 mm I, I = 306.31 cm^4, EI = 612626 N m^2, tip load 1000 N = 102.0 kg
element k for 1 m, in units of EI/m^3: 12 6 -12 6 | 6 4 -6 2
assembled K, free rows, units EI/m^3:
      24     0   -12     6     0     0
       0     8    -6     2     0     0
     -12    -6    24     0   -12     6
       6     2     0     8    -6     2
       0     0   -12    -6    12    -6
       0     0     6     2    -6     4
u in units of P m^3/EI = 1.6323 mm: 1.3333 2.5000 4.6667 4.0000 9.0000 4.5000
row 1 of K u: +32 -56 +24 = 0 P
row 5 of K u: -56 -24 +108 -27 = 1 P
node 1 at 1.00 m: sag  2.176 mm, slope 0.004081 rad, exact  2.176 mm
node 2 at 2.00 m: sag  7.617 mm, slope 0.006529 rad, exact  7.617 mm
node 3 at 3.00 m: sag 14.691 mm, slope 0.007345 rad, exact 14.691 mm
tip sag: elements 14.6909 mm, PL^3/3EI 14.6909 mm, energy 14.6909 mm
wall reaction from K u: 1000.0 N up, 3000.0 N m; W = 51.05 cm^3, stress at wall 58.76 MPa
elements: 1, tip 14.6909 mm
elements: 2, tip 14.6909 mm
elements: 6, tip 14.6909 mm
finite differences, 3 steps: tip 15.5070 mm
finite differences, 30 steps: tip 14.6990 mm
finite differences, 300 steps: tip 14.6909 mm
own weight 98.46 N/m: tip 1.627 mm (consistent loads), exact wL^4/8EI 1.627 mm
total tip 16.32 mm against limit L/180 = 16.67 mm
wrong: no supports, K times rigid lift = 0.0 N
wrong: no supports, K times rigid spin = 0.0 N
wrong: assembled by overwriting, not adding: tip -3.26 mm
wrong: own weight lumped as nodal forces only: tip 1.687 mm against 1.627 mm
wrong: finite differences on the same 3 pieces: tip 15.51 mm
outside the model: yield at P = 4680 N; at 10000 N it says 146.9 mm, 588 MPa
try: 5000 N tip 73.45 mm, 294 MPa; L = 4 m tip 34.82 mm against 22.22 mm; 6 elements, own weight lumped 1.642 mm
figure, 120 px/m, 6 px/mm, sag px at 0.25 m steps: 0.0 0.9 3.5 7.6 13.1 19.8 27.5 36.2 45.7 55.8 66.3 77.2 88.1
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves Steps 2, 4 and 5 of Why it works, for any number of equal elements, and checks the worked numbers.

- Take $n \ge 1$ equal elements, the wall fixed, $EI > 0$, $\ell > 0$ and tip load $P$. Then $K u = F$ has exactly one solution: the true drop $v$ and slope $\theta$ at every node.
- Take any element length $\ell > 0$ and the four shape functions $N_1 \dots N_4$. Then each entry $k_{ij}$ equals $\int_0^\ell EI\,N_i''\,N_j''\,dx$.
- Take $K$ before the wall is fixed, for any number of elements. Then $K$ times a rigid lift or a rigid turn is zero, so $K$ has no inverse.
- For three 1 m elements, Lean checks the six free rows of $K$ listed above. It checks the solve $u = (4/3, 5/2, 14/3, 4, 9, 9/2)$, in units of $P\ell^3/EI$.
- It also checks the hand integral for $k_{11}$ and node 1's entries 24, 8 and 0.

The numbers in millimetres, the own-weight loads, finite differences and the yield limit are left to the Python and Rust checks.

```lean
-- Finite elements: for a cantilever cut into any number of equal beam elements with a load at the tip, the assembled and supported stiffness system K u = F has exactly one solution, and it is the true drop and slope at every node; each element matrix is the energy integral of its cubic shape functions, and without supports K has no inverse.
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Analysis.SpecialFunctions.Integrals.Basic
import Mathlib.Analysis.Calculus.Deriv.Basic

noncomputable section

namespace FEBeam

open Matrix

/-- The element stiffness matrix `k` of one beam element of length `ℓ` and bending stiffness
`EI`, with end movements ordered `(v₁, θ₁, v₂, θ₂)`. -/
def kElem (EI ℓ : ℝ) : Matrix (Fin 4) (Fin 4) ℝ :=
  (EI / ℓ ^ 3) • !![12, 6 * ℓ, -12, 6 * ℓ;
                    6 * ℓ, 4 * ℓ ^ 2, -6 * ℓ, 2 * ℓ ^ 2;
                    -12, -6 * ℓ, 12, -6 * ℓ;
                    6 * ℓ, 2 * ℓ ^ 2, -6 * ℓ, 4 * ℓ ^ 2]

/-- Node `i` (at distance `i ℓ` from the wall) has movement number `2 i` (its drop) and
`2 i + 1` (its slope). Element `e` joins nodes `e` and `e + 1`, so its four end movements are
numbers `2e, 2e+1, 2e+2, 2e+3`. This is the entry element `e` adds at position `(a, b)`. -/
def elemEntry (EI ℓ : ℝ) (e a b : ℕ) : ℝ :=
  if h : 2 * e ≤ a ∧ a < 2 * e + 4 ∧ 2 * e ≤ b ∧ b < 2 * e + 4 then
    kElem EI ℓ ⟨a - 2 * e, by omega⟩ ⟨b - 2 * e, by omega⟩
  else 0

/-- The assembled stiffness matrix of `n` elements, every node free (nothing fixed):
each element's `k` is added into the rows and columns of its two nodes. -/
def Kfull (n : ℕ) (EI ℓ : ℝ) : Matrix (Fin (2 * (n + 1))) (Fin (2 * (n + 1))) ℝ :=
  fun a b => ∑ e ∈ Finset.range n, elemEntry EI ℓ e a b

/-- The same matrix with the wall fixed: node 0's drop and slope are removed, so free
movement number `a` is overall movement number `a + 2`. -/
def Kfree (n : ℕ) (EI ℓ : ℝ) : Matrix (Fin (2 * n)) (Fin (2 * n)) ℝ :=
  fun a b => ∑ e ∈ Finset.range n, elemEntry EI ℓ e (a + 2) (b + 2)

/-- The load list `F`: a force `P` on the drop of the tip node `n`, zero everywhere else. -/
def tipLoad (n : ℕ) (P : ℝ) : Fin (2 * n) → ℝ :=
  fun a => if (a : ℕ) = 2 * n - 2 then P else 0

/-- The free node `a / 2 + 1` that free movement number `a` belongs to sits at this distance
from the wall. -/
def nodeX (ℓ : ℝ) (a : ℕ) : ℝ := ((a / 2 + 1 : ℕ) : ℝ) * ℓ

/-- The four cubic shape functions of one element of length `ℓ`, written in `x`
(with `s = x / ℓ`): `N₁ = 1 - 3s² + 2s³`, `N₂ = ℓ(s - 2s² + s³)`, `N₃ = 3s² - 2s³`,
`N₄ = ℓ(s³ - s²)`. -/
def shapeFn (ℓ : ℝ) : Fin 4 → ℝ → ℝ
  | 0 => fun x => 1 - 3 * (x / ℓ) ^ 2 + 2 * (x / ℓ) ^ 3
  | 1 => fun x => ℓ * ((x / ℓ) - 2 * (x / ℓ) ^ 2 + (x / ℓ) ^ 3)
  | 2 => fun x => 3 * (x / ℓ) ^ 2 - 2 * (x / ℓ) ^ 3
  | 3 => fun x => ℓ * ((x / ℓ) ^ 3 - (x / ℓ) ^ 2)

lemma sum_loc (N e : ℕ) (g : ℕ → ℝ) (hN : 2 * e + 4 ≤ N)
    (hg : ∀ b, b < 2 * e ∨ 2 * e + 4 ≤ b → g b = 0) :
    ∑ b ∈ Finset.range N, g b = g (2 * e) + g (2 * e + 1) + g (2 * e + 2) + g (2 * e + 3) := by
  obtain ⟨m, rfl⟩ := Nat.exists_eq_add_of_le hN
  rw [show 2 * e + 4 + m = 2 * e + (4 + m) by ring, Finset.sum_range_add, Finset.sum_range_add]
  have h1 : ∑ x ∈ Finset.range (2 * e), g x = 0 :=
    Finset.sum_eq_zero fun x hx => hg x (Or.inl (Finset.mem_range.1 hx))
  have h2 : ∑ x ∈ Finset.range m, g (2 * e + (4 + x)) = 0 :=
    Finset.sum_eq_zero fun x _ => hg _ (Or.inr (by omega))
  rw [h1, h2]
  simp [Finset.sum_range_succ]

#print axioms sum_loc

lemma elemEntry_out (EI ℓ : ℝ) (e a b : ℕ) (h : ¬ (2 * e ≤ a ∧ a < 2 * e + 4)) :
    elemEntry EI ℓ e a b = 0 := by
  unfold elemEntry; rw [dite_eq_right]; tauto

#print axioms elemEntry_out

lemma elemEntry_out' (EI ℓ : ℝ) (e a b : ℕ) (h : b < 2 * e ∨ 2 * e + 4 ≤ b) :
    elemEntry EI ℓ e a b = 0 := by
  unfold elemEntry; rw [dite_eq_right]; omega

#print axioms elemEntry_out'

lemma elemEntry_loc (EI ℓ : ℝ) (e i j : ℕ) (hi : i < 4) (hj : j < 4) :
    elemEntry EI ℓ e (2 * e + i) (2 * e + j) = kElem EI ℓ ⟨i, hi⟩ ⟨j, hj⟩ := by
  unfold elemEntry; rw [dif_pos (show 2 * e ≤ 2 * e + i ∧ 2 * e + i < 2 * e + 4 ∧ 2 * e ≤ 2 * e + j ∧ 2 * e + j < 2 * e + 4 by omega)]
  congr 1 <;> ext <;> simp

#print axioms elemEntry_loc

/-- Row `a` of the assembled matrix acting on a vector, element by element. -/
lemma Kfull_mulVec (n : ℕ) (EI ℓ : ℝ) (W : ℕ → ℝ) (a : Fin (2 * (n + 1))) :
    (Kfull n EI ℓ *ᵥ fun b => W b) a = ∑ e ∈ Finset.range n,
      (elemEntry EI ℓ e a (2 * e) * W (2 * e) + elemEntry EI ℓ e a (2 * e + 1) * W (2 * e + 1) +
       elemEntry EI ℓ e a (2 * e + 2) * W (2 * e + 2) +
       elemEntry EI ℓ e a (2 * e + 3) * W (2 * e + 3)) := by
  simp only [mulVec, dotProduct, Kfull, Finset.sum_mul]
  rw [Finset.sum_comm]
  refine Finset.sum_congr rfl fun e he => ?_
  rw [Fin.sum_univ_eq_sum_range (fun b => elemEntry EI ℓ e a b * W b)]
  apply sum_loc
  · have := Finset.mem_range.1 he; omega
  · intro b hb; rw [elemEntry_out' _ _ _ _ _ hb, zero_mul]

#print axioms Kfull_mulVec

lemma Kfree_mulVec (n : ℕ) (EI ℓ : ℝ) (W : ℕ → ℝ) (h0 : W 0 = 0) (h1 : W 1 = 0)
    (a : Fin (2 * n)) :
    (Kfree n EI ℓ *ᵥ fun b => W (b + 2)) a = ∑ e ∈ Finset.range n,
      (elemEntry EI ℓ e (a + 2) (2 * e) * W (2 * e) +
       elemEntry EI ℓ e (a + 2) (2 * e + 1) * W (2 * e + 1) +
       elemEntry EI ℓ e (a + 2) (2 * e + 2) * W (2 * e + 2) +
       elemEntry EI ℓ e (a + 2) (2 * e + 3) * W (2 * e + 3)) := by
  simp only [mulVec, dotProduct, Kfree, Finset.sum_mul]
  rw [Finset.sum_comm]
  refine Finset.sum_congr rfl fun e he => ?_
  rw [Fin.sum_univ_eq_sum_range (fun b => elemEntry EI ℓ e (a + 2) (b + 2) * W (b + 2))]
  have : ∑ b ∈ Finset.range (2 * n), elemEntry EI ℓ e (a + 2) (b + 2) * W (b + 2) =
      ∑ b ∈ Finset.range (2 * n + 2), elemEntry EI ℓ e (a + 2) b * W b := by
    rw [Finset.sum_range_succ', Finset.sum_range_succ']
    simp [h0, h1]
  rw [this]
  apply sum_loc
  · have := Finset.mem_range.1 he; omega
  · intro b hb; rw [elemEntry_out' _ _ _ _ _ hb, zero_mul]

#print axioms Kfree_mulVec

lemma summand_loc (EI ℓ : ℝ) (W : ℕ → ℝ) (e r i : ℕ) (hi : i < 4) (hr : r = 2 * e + i) :
    elemEntry EI ℓ e r (2 * e) * W (2 * e) + elemEntry EI ℓ e r (2 * e + 1) * W (2 * e + 1) +
      elemEntry EI ℓ e r (2 * e + 2) * W (2 * e + 2) +
      elemEntry EI ℓ e r (2 * e + 3) * W (2 * e + 3) =
    kElem EI ℓ ⟨i, hi⟩ 0 * W (2 * e) + kElem EI ℓ ⟨i, hi⟩ 1 * W (2 * e + 1) +
      kElem EI ℓ ⟨i, hi⟩ 2 * W (2 * e + 2) + kElem EI ℓ ⟨i, hi⟩ 3 * W (2 * e + 3) := by
  subst hr
  have q0 := elemEntry_loc EI ℓ e i 0 hi (by norm_num)
  rw [add_zero] at q0
  rw [q0, elemEntry_loc EI ℓ e i 1 hi (by norm_num),
    elemEntry_loc EI ℓ e i 2 hi (by norm_num), elemEntry_loc EI ℓ e i 3 hi (by norm_num)]
  rfl

#print axioms summand_loc

lemma summand_out (EI ℓ : ℝ) (W : ℕ → ℝ) (e r : ℕ) (h : ¬ (2 * e ≤ r ∧ r < 2 * e + 4)) :
    elemEntry EI ℓ e r (2 * e) * W (2 * e) + elemEntry EI ℓ e r (2 * e + 1) * W (2 * e + 1) +
      elemEntry EI ℓ e r (2 * e + 2) * W (2 * e + 2) +
      elemEntry EI ℓ e r (2 * e + 3) * W (2 * e + 3) = 0 := by
  simp [elemEntry_out _ _ _ _ _ h]

#print axioms summand_out

lemma Kfree_row (n : ℕ) (EI ℓ : ℝ) (W : ℕ → ℝ) (h0 : W 0 = 0) (h1 : W 1 = 0)
    (k : ℕ) (hk : k < n) :
    (Kfree n EI ℓ *ᵥ fun b => W (b + 2)) ⟨2 * k, by omega⟩ =
      EI / ℓ ^ 3 * (-12 * W (2 * k) - 6 * ℓ * W (2 * k + 1) + 12 * W (2 * k + 2)
        - 6 * ℓ * W (2 * k + 3)) +
      (if k + 1 < n then EI / ℓ ^ 3 * (12 * W (2 * k + 2) + 6 * ℓ * W (2 * k + 3)
        - 12 * W (2 * k + 4) + 6 * ℓ * W (2 * k + 5)) else 0) ∧
    (Kfree n EI ℓ *ᵥ fun b => W (b + 2)) ⟨2 * k + 1, by omega⟩ =
      EI / ℓ ^ 3 * (6 * ℓ * W (2 * k) + 2 * ℓ ^ 2 * W (2 * k + 1) - 6 * ℓ * W (2 * k + 2)
        + 4 * ℓ ^ 2 * W (2 * k + 3)) +
      (if k + 1 < n then EI / ℓ ^ 3 * (6 * ℓ * W (2 * k + 2) + 4 * ℓ ^ 2 * W (2 * k + 3)
        - 6 * ℓ * W (2 * k + 4) + 2 * ℓ ^ 2 * W (2 * k + 5)) else 0) := by
  rw [Kfree_mulVec _ _ _ _ h0 h1, Kfree_mulVec _ _ _ _ h0 h1]
  simp only []
  have e1 : 2 * (k + 1) = 2 * k + 2 := by ring
  have e2 : 2 * k + 2 + 1 = 2 * k + 3 := by ring
  have e3 : 2 * k + 2 + 2 = 2 * k + 4 := by ring
  have e4 : 2 * k + 2 + 3 = 2 * k + 5 := by ring
  by_cases hk1 : k + 1 < n
  · rw [Finset.sum_eq_add_of_mem k (k + 1) (Finset.mem_range.2 hk) (Finset.mem_range.2 hk1)
      (by omega), Finset.sum_eq_add_of_mem k (k + 1) (Finset.mem_range.2 hk)
      (Finset.mem_range.2 hk1) (by omega)]
    · rw [summand_loc EI ℓ W k _ 2 (by norm_num) (by ring),
        summand_loc EI ℓ W (k + 1) _ 0 (by norm_num) (by ring),
        summand_loc EI ℓ W k _ 3 (by norm_num) (by ring),
        summand_loc EI ℓ W (k + 1) _ 1 (by norm_num) (by ring)]
      simp only [e1, e2, e3, e4, if_pos hk1]
      constructor <;> simp [kElem] <;> ring
    · intro c _ hc
      exact summand_out EI ℓ W c _ (by omega)
    · intro c _ hc
      exact summand_out EI ℓ W c _ (by omega)
  · rw [Finset.sum_eq_single k, Finset.sum_eq_single k]
    · rw [summand_loc EI ℓ W k _ 2 (by norm_num) (by ring),
        summand_loc EI ℓ W k _ 3 (by norm_num) (by ring)]
      simp only [if_neg hk1]
      constructor <;> simp [kElem] <;> ring
    · intro c hc hck
      have := Finset.mem_range.1 hc
      exact summand_out EI ℓ W c _ (by omega)
    · intro h; exact absurd (Finset.mem_range.2 hk) h
    · intro c hc hck
      have := Finset.mem_range.1 hc
      exact summand_out EI ℓ W c _ (by omega)
    · intro h; exact absurd (Finset.mem_range.2 hk) h

#print axioms Kfree_row

lemma cubic_dd (c0 c1 c2 c3 : ℝ) :
    deriv (deriv (fun x : ℝ => c0 + c1 * x + c2 * x ^ 2 + c3 * x ^ 3)) =
      fun x => 2 * c2 + 6 * c3 * x := by
  have h1 : ∀ x : ℝ, HasDerivAt (fun x : ℝ => c0 + c1 * x + c2 * x ^ 2 + c3 * x ^ 3)
      (c1 + 2 * c2 * x + 3 * c3 * x ^ 2) x := by
    intro x
    have := ((((hasDerivAt_const x c0).add ((hasDerivAt_id x).const_mul c1)).add
      ((hasDerivAt_pow 2 x).const_mul c2)).add ((hasDerivAt_pow 3 x).const_mul c3))
    convert this using 1
    · funext y; simp
    · simp; ring
  have h2 : deriv (fun x : ℝ => c0 + c1 * x + c2 * x ^ 2 + c3 * x ^ 3) =
      fun x => c1 + 2 * c2 * x + 3 * c3 * x ^ 2 := funext fun x => (h1 x).deriv
  rw [h2]
  funext x
  have := ((((hasDerivAt_const x c1).add ((hasDerivAt_id x).const_mul (2 * c2))).add
      ((hasDerivAt_pow 2 x).const_mul (3 * c3))))
  rw [show (fun x : ℝ => c1 + 2 * c2 * x + 3 * c3 * x ^ 2) =
    (fun x => c1 + 2 * c2 * id x + 3 * c3 * x ^ 2) from rfl]
  convert this.deriv using 1
  simp; ring

#print axioms cubic_dd

lemma lin_integral (EI ℓ a b c d : ℝ) :
    ∫ x in (0 : ℝ)..ℓ, EI * (a + b * x) * (c + d * x) =
      EI * (a * c * ℓ + (a * d + b * c) * ℓ ^ 2 / 2 + b * d * ℓ ^ 3 / 3) := by
  have hF : ∀ x ∈ Set.uIcc (0:ℝ) ℓ, HasDerivAt
      (fun x : ℝ => EI * (a * c * x + (a * d + b * c) * x ^ 2 / 2 + b * d * x ^ 3 / 3))
      (EI * (a + b * x) * (c + d * x)) x := by
    intro x _
    have := (((((hasDerivAt_id x).const_mul (a * c)).add
      (((hasDerivAt_pow 2 x).const_mul (a * d + b * c)).div_const 2)).add
      (((hasDerivAt_pow 3 x).const_mul (b * d)).div_const 3)).const_mul EI)
    convert this using 1
    · funext y; simp
    · simp; ring
  rw [intervalIntegral.integral_eq_sub_of_hasDerivAt hF]
  · simp
  · apply Continuous.intervalIntegrable; fun_prop

#print axioms lin_integral

/-- The card's main claim (Steps 1 to 5 of Why it works). A cantilever of length `L = n ℓ`,
built into a wall at `x = 0`, is cut into `n ≥ 1` elements of length `ℓ > 0`, with bending
stiffness `EI > 0` and a load `P` at the tip. Its true drop `v` (down positive) obeys the
bending equation `EI v'' = P (L - x)`, with `v = 0` and slope `v' = 0` at the wall. Then
`K u = F`, with the wall fixed, has exactly one solution `u`, and it is the true drop and
slope at every node: the method is exact at the nodes for any number of elements. -/
theorem cantilever_tip_load_fem_exact_at_nodes
    (n : ℕ) (hn : 0 < n) (EI ℓ P : ℝ) (hEI : 0 < EI) (hℓ : 0 < ℓ)
    (v v' : ℝ → ℝ)
    (hv : ∀ x, HasDerivAt v (v' x) x)
    (hv' : ∀ x, HasDerivAt v' (P * (n * ℓ - x) / EI) x)
    (hv0 : v 0 = 0) (hv'0 : v' 0 = 0) :
    ∀ u : Fin (2 * n) → ℝ, Kfree n EI ℓ *ᵥ u = tipLoad n P ↔
      u = fun a : Fin (2 * n) => if (a : ℕ) % 2 = 0 then v (nodeX ℓ a) else v' (nodeX ℓ a) := by
  have hl : ℓ ≠ 0 := hℓ.ne'
  have hE : EI ≠ 0 := hEI.ne'
  have hc : EI / ℓ ^ 3 ≠ 0 := by positivity
  -- the true slope and drop, in closed form
  have hv'f : ∀ x, v' x = P * (n * ℓ * x - x ^ 2 / 2) / EI := by
    have hd : ∀ x, HasDerivAt (fun x => v' x - P * (n * ℓ * x - x ^ 2 / 2) / EI) 0 x := by
      intro x
      have h2 := ((((hasDerivAt_id x).const_mul ((n : ℝ) * ℓ)).sub
        ((hasDerivAt_pow 2 x).div_const 2)).const_mul P).div_const EI
      convert (hv' x).sub h2 using 1
      · funext y; simp only [Pi.sub_apply, id]
      · simp
    intro x
    have := is_const_of_deriv_eq_zero (fun x => (hd x).differentiableAt) (fun x => (hd x).deriv) x 0
    simp only [hv'0] at this
    norm_num at this
    linarith
  have hvf : ∀ x, v x = P * (n * ℓ * x ^ 2 / 2 - x ^ 3 / 6) / EI := by
    have hd : ∀ x, HasDerivAt (fun x => v x - P * (n * ℓ * x ^ 2 / 2 - x ^ 3 / 6) / EI) 0 x := by
      intro x
      have h2 := (((((hasDerivAt_pow 2 x).const_mul ((n : ℝ) * ℓ)).div_const 2).sub
        ((hasDerivAt_pow 3 x).div_const 6)).const_mul P).div_const EI
      convert (hv x).sub h2 using 1
      rw [hv'f]; simp; ring
    intro x
    have := is_const_of_deriv_eq_zero (fun x => (hd x).differentiableAt) (fun x => (hd x).deriv) x 0
    simp only [hv0] at this
    norm_num at this
    linarith
  intro u
  set U : ℕ → ℝ := fun k => if h : 2 ≤ k ∧ k < 2 * n + 2 then u ⟨k - 2, by omega⟩ else 0 with hU
  have hu : u = fun b : Fin (2 * n) => U (b + 2) := by
    funext b
    simp only [hU]
    rw [dif_pos (by omega)]
    congr 1
  have U0 : U 0 = 0 := by simp [hU]
  have U1 : U 1 = 0 := by simp [hU]
  have hrow := Kfree_row n EI ℓ U U0 U1
  rw [hu]
  -- the equations, row by row
  have hB : (Kfree n EI ℓ *ᵥ fun b => U (b + 2)) = tipLoad n P ↔ ∀ k (hk : k < n),
      (Kfree n EI ℓ *ᵥ fun b => U (b + 2)) ⟨2 * k, by omega⟩ = (if k + 1 = n then P else 0) ∧
      (Kfree n EI ℓ *ᵥ fun b => U (b + 2)) ⟨2 * k + 1, by omega⟩ = 0 := by
    constructor
    · intro h k hk
      rw [h]
      simp only [tipLoad]
      constructor
      · by_cases hk1 : k + 1 = n
        · rw [if_pos hk1, if_pos (by omega)]
        · rw [if_neg hk1, if_neg (by omega)]
      · rw [if_neg (by omega)]
    · intro h
      funext a
      obtain ⟨k, hk | hk⟩ := Nat.even_or_odd' (a : ℕ)
      · have hkn : k < n := by omega
        have := (h k hkn).1
        have ha : a = ⟨2 * k, by omega⟩ := Fin.ext hk
        rw [ha, this]
        simp only [tipLoad]
        by_cases hk1 : k + 1 = n
        · rw [if_pos hk1, if_pos (by omega)]
        · rw [if_neg hk1, if_neg (by omega)]
      · have hkn : k < n := by omega
        have := (h k hkn).2
        have ha : a = ⟨2 * k + 1, by omega⟩ := Fin.ext hk
        rw [ha, this]
        simp only [tipLoad]
        rw [if_neg (by omega)]
  -- the answer, node by node
  have hC : ((fun b : Fin (2 * n) => U (b + 2)) =
      fun a : Fin (2 * n) => if (a : ℕ) % 2 = 0 then v (nodeX ℓ a) else v' (nodeX ℓ a)) ↔
      ∀ m ≤ n, U (2 * m) = v ((m : ℝ) * ℓ) ∧ U (2 * m + 1) = v' ((m : ℝ) * ℓ) := by
    constructor
    · intro h m hm
      rcases m with _ | m
      · simp [U0, U1, hv0, hv'0]
      · have hx : nodeX ℓ (2 * m) = ((m + 1 : ℕ) : ℝ) * ℓ := by
          unfold nodeX; congr 2; omega
        have hx' : nodeX ℓ (2 * m + 1) = ((m + 1 : ℕ) : ℝ) * ℓ := by
          unfold nodeX; congr 2; omega
        have h1 := congrFun h ⟨2 * m, by omega⟩
        have h2 := congrFun h ⟨2 * m + 1, by omega⟩
        dsimp only at h1 h2
        rw [if_pos (by omega), hx] at h1
        rw [if_neg (by omega), hx'] at h2
        rw [show 2 * (m + 1) = 2 * m + 2 by ring, show 2 * m + 2 + 1 = 2 * m + 1 + 2 by ring]
        exact ⟨h1, h2⟩
    · intro h
      funext a
      obtain ⟨k, hk | hk⟩ := Nat.even_or_odd' (a : ℕ)
      · have hkn : k < n := by omega
        obtain ⟨h1, _⟩ := h (k + 1) (by omega)
        have hx : nodeX ℓ a = ((k + 1 : ℕ) : ℝ) * ℓ := by
          unfold nodeX; congr 2; omega
        rw [if_pos (by omega), hx, hk, ← h1]
        congr 1
      · have hkn : k < n := by omega
        obtain ⟨_, h2⟩ := h (k + 1) (by omega)
        have hx : nodeX ℓ a = ((k + 1 : ℕ) : ℝ) * ℓ := by
          unfold nodeX; congr 2; omega
        rw [if_neg (by omega), hx, hk, ← h2]
        congr 1
  rw [hB, hC]
  constructor
  · intro h
    -- the end forces of every element, from the tip back to the wall
    have hF : ∀ m e, e + m + 1 = n →
        EI / ℓ ^ 3 * (-12 * U (2 * e) - 6 * ℓ * U (2 * e + 1) + 12 * U (2 * e + 2)
          - 6 * ℓ * U (2 * e + 3)) = P ∧
        EI / ℓ ^ 3 * (6 * ℓ * U (2 * e) + 2 * ℓ ^ 2 * U (2 * e + 1) - 6 * ℓ * U (2 * e + 2)
          + 4 * ℓ ^ 2 * U (2 * e + 3)) = m * ℓ * P := by
      intro m
      induction m with
      | zero =>
        intro e he
        have h1 := (h e (by omega)).1
        have h2 := (h e (by omega)).2
        rw [(hrow e (by omega)).1, if_neg (by omega), if_pos (by omega)] at h1
        rw [(hrow e (by omega)).2, if_neg (by omega)] at h2
        constructor
        · linear_combination h1
        · push_cast; linear_combination h2
      | succ m ih =>
        intro e he
        obtain ⟨i1, i2⟩ := ih (e + 1) (by omega)
        simp only [show 2 * (e + 1) = 2 * e + 2 by ring, show 2 * e + 2 + 1 = 2 * e + 3 by ring,
          show 2 * e + 2 + 2 = 2 * e + 4 by ring, show 2 * e + 2 + 3 = 2 * e + 5 by ring] at i1 i2
        have h1 := (h e (by omega)).1
        have h2 := (h e (by omega)).2
        rw [(hrow e (by omega)).1, if_pos (by omega), if_neg (by omega)] at h1
        rw [(hrow e (by omega)).2, if_pos (by omega)] at h2
        constructor
        · linear_combination h1 + i1
        · push_cast; linear_combination h2 + ℓ * i1 + i2
    -- the node movements, from the wall out to the tip
    intro m
    induction m with
    | zero => intro _; simp [U0, U1, hv0, hv'0]
    | succ e ih =>
      intro he
      obtain ⟨j0, j1⟩ := ih (by omega)
      obtain ⟨m, hm⟩ : ∃ m, e + m + 1 = n := ⟨n - e - 1, by omega⟩
      obtain ⟨f1, f2⟩ := hF m e hm
      have hnR : (n : ℝ) = e + m + 1 := by rw [← hm]; push_cast; ring
      rw [j0, j1] at f1 f2
      have x1 : EI / ℓ ^ 3 * (-12 * v (e * ℓ) - 6 * ℓ * v' (e * ℓ) + 12 * v (((e + 1 : ℕ) : ℝ) * ℓ)
          - 6 * ℓ * v' (((e + 1 : ℕ) : ℝ) * ℓ)) = P := by
        simp only [hvf, hv'f]; push_cast; rw [hnR]; field_simp; ring
      have x2 : EI / ℓ ^ 3 * (6 * ℓ * v (e * ℓ) + 2 * ℓ ^ 2 * v' (e * ℓ)
          - 6 * ℓ * v (((e + 1 : ℕ) : ℝ) * ℓ) + 4 * ℓ ^ 2 * v' (((e + 1 : ℕ) : ℝ) * ℓ)) =
          m * ℓ * P := by
        simp only [hvf, hv'f]; push_cast; rw [hnR]; field_simp; ring
      have d1 : EI / ℓ ^ 3 * (12 * (U (2 * e + 2) - v (((e + 1 : ℕ) : ℝ) * ℓ))
          - 6 * ℓ * (U (2 * e + 3) - v' (((e + 1 : ℕ) : ℝ) * ℓ))) = 0 := by
        linear_combination f1 - x1
      have d2 : EI / ℓ ^ 3 * (-6 * ℓ * (U (2 * e + 2) - v (((e + 1 : ℕ) : ℝ) * ℓ))
          + 4 * ℓ ^ 2 * (U (2 * e + 3) - v' (((e + 1 : ℕ) : ℝ) * ℓ))) = 0 := by
        linear_combination f2 - x2
      have d1' := (mul_eq_zero.1 d1).resolve_left hc
      have d2' := (mul_eq_zero.1 d2).resolve_left hc
      have hq2 : ℓ ^ 2 * (U (2 * e + 3) - v' (((e + 1 : ℕ) : ℝ) * ℓ)) = 0 := by
        linear_combination (ℓ / 2) * d1' + d2'
      have hq := (mul_eq_zero.1 hq2).resolve_left (pow_ne_zero 2 hl)
      have hp : U (2 * e + 2) - v (((e + 1 : ℕ) : ℝ) * ℓ) = 0 := by
        linear_combination d1' / 12 + ℓ / 2 * hq
      rw [show 2 * (e + 1) = 2 * e + 2 by ring, show 2 * e + 2 + 1 = 2 * e + 3 by ring]
      constructor
      · linear_combination hp
      · linear_combination hq
  · intro h k hk
    obtain ⟨a0, a1⟩ := h k hk.le
    obtain ⟨b0, b1⟩ := h (k + 1) hk
    simp only [show 2 * (k + 1) = 2 * k + 2 by ring, show 2 * k + 2 + 1 = 2 * k + 3 by ring] at b0 b1
    rw [(hrow k hk).1, (hrow k hk).2]
    by_cases hk1 : k + 1 < n
    · obtain ⟨c0, c1⟩ := h (k + 2) hk1
      simp only [show 2 * (k + 2) = 2 * k + 4 by ring, show 2 * k + 4 + 1 = 2 * k + 5 by ring]
        at c0 c1
      rw [if_pos hk1, if_pos hk1, if_neg (by omega), a0, a1, b0, b1, c0, c1]
      simp only [hvf, hv'f]
      push_cast
      constructor <;> field_simp <;> ring
    · have hnk : n = k + 1 := by omega
      rw [if_neg hk1, if_neg hk1, if_pos (by omega), a0, a1, b0, b1]
      have hnR : (n : ℝ) = k + 1 := by rw [hnk]; push_cast; ring
      simp only [hvf, hv'f]
      push_cast
      rw [hnR]
      constructor <;> field_simp <;> ring

/-- Step 2: the element stiffness matrix comes from the stored energy. Entry `(i, j)` of `k`
is `∫₀^ℓ EI Nᵢ'' Nⱼ'' dx`, for every element length `ℓ > 0`. -/
theorem element_stiffness_eq_energy_integral (EI ℓ : ℝ) (hℓ : 0 < ℓ) (i j : Fin 4) :
    ∫ x in (0 : ℝ)..ℓ, EI * deriv (deriv (shapeFn ℓ i)) x * deriv (deriv (shapeFn ℓ j)) x =
      kElem EI ℓ i j := by
  have hl : ℓ ≠ 0 := hℓ.ne'
  have h0 : deriv (deriv (shapeFn ℓ 0)) = fun x => -6 / ℓ ^ 2 + 12 / ℓ ^ 3 * x := by
    have : shapeFn ℓ 0 = fun x : ℝ => 1 + 0 * x + (-3 / ℓ ^ 2) * x ^ 2 + (2 / ℓ ^ 3) * x ^ 3 := by
      funext x; simp only [shapeFn]; field_simp; ring
    rw [this, cubic_dd]; funext x; ring
  have h1 : deriv (deriv (shapeFn ℓ 1)) = fun x => -4 / ℓ + 6 / ℓ ^ 2 * x := by
    have : shapeFn ℓ 1 = fun x : ℝ => 0 + 1 * x + (-2 / ℓ) * x ^ 2 + (1 / ℓ ^ 2) * x ^ 3 := by
      funext x; simp only [shapeFn]; field_simp; ring
    rw [this, cubic_dd]; funext x; ring
  have h2 : deriv (deriv (shapeFn ℓ 2)) = fun x => 6 / ℓ ^ 2 + -12 / ℓ ^ 3 * x := by
    have : shapeFn ℓ 2 = fun x : ℝ => 0 + 0 * x + (3 / ℓ ^ 2) * x ^ 2 + (-2 / ℓ ^ 3) * x ^ 3 := by
      funext x; simp only [shapeFn]; field_simp; ring
    rw [this, cubic_dd]; funext x; ring
  have h3 : deriv (deriv (shapeFn ℓ 3)) = fun x => -2 / ℓ + 6 / ℓ ^ 2 * x := by
    have : shapeFn ℓ 3 = fun x : ℝ => 0 + 0 * x + (-1 / ℓ) * x ^ 2 + (1 / ℓ ^ 2) * x ^ 3 := by
      funext x; simp only [shapeFn]; field_simp; ring
    rw [this, cubic_dd]; funext x; ring
  have hs : ∀ i, deriv (deriv (shapeFn ℓ i)) = fun x =>
      ![-6 / ℓ ^ 2, -4 / ℓ, 6 / ℓ ^ 2, -2 / ℓ] i + ![12 / ℓ ^ 3, 6 / ℓ ^ 2, -12 / ℓ ^ 3, 6 / ℓ ^ 2] i * x := by
    intro i
    fin_cases i
    · exact h0
    · exact h1
    · exact h2
    · exact h3
  rw [hs i, hs j]
  rw [show (fun x => EI * (![-6 / ℓ ^ 2, -4 / ℓ, 6 / ℓ ^ 2, -2 / ℓ] i + ![12 / ℓ ^ 3, 6 / ℓ ^ 2, -12 / ℓ ^ 3, 6 / ℓ ^ 2] i * x) * (![-6 / ℓ ^ 2, -4 / ℓ, 6 / ℓ ^ 2, -2 / ℓ] j + ![12 / ℓ ^ 3, 6 / ℓ ^ 2, -12 / ℓ ^ 3, 6 / ℓ ^ 2] j * x)) = _ from rfl]
  rw [lin_integral]
  fin_cases i <;> fin_cases j <;> simp [kElem] <;> field_simp <;> ring

/-- Step 4: without supports, `K` times a rigid lift (every node drops 1, no node turns) is
zero, and `K` times a rigid turn (node `i` drops `i ℓ`, every node turns 1) is zero, so no
force resists either movement and `K` has no inverse: its determinant is 0. -/
theorem unsupported_stiffness_singular (n : ℕ) (EI ℓ : ℝ) :
    Kfull n EI ℓ *ᵥ (fun a => if (a : ℕ) % 2 = 0 then 1 else 0) = 0 ∧
    Kfull n EI ℓ *ᵥ (fun a => if (a : ℕ) % 2 = 0 then ((a : ℕ) / 2 : ℕ) * ℓ else 1) = 0 ∧
    (Kfull n EI ℓ).det = 0 := by
  have key : ∀ W : ℕ → ℝ, (∀ e (i : Fin 4),
      kElem EI ℓ i 0 * W (2 * e) + kElem EI ℓ i 1 * W (2 * e + 1) +
      kElem EI ℓ i 2 * W (2 * e + 2) + kElem EI ℓ i 3 * W (2 * e + 3) = 0) →
      Kfull n EI ℓ *ᵥ (fun b => W b) = 0 := by
    intro W hW
    funext a
    rw [Kfull_mulVec]
    simp only [Pi.zero_apply]
    refine Finset.sum_eq_zero fun e _ => ?_
    by_cases h : 2 * e ≤ (a : ℕ) ∧ (a : ℕ) < 2 * e + 4
    · obtain ⟨i, hi⟩ : ∃ i, (a : ℕ) = 2 * e + i := ⟨a - 2 * e, by omega⟩
      have hi4 : i < 4 := by omega
      have q0 := elemEntry_loc EI ℓ e i 0 hi4 (by norm_num)
      rw [add_zero] at q0
      rw [hi, q0, elemEntry_loc EI ℓ e i 1 hi4 (by norm_num),
        elemEntry_loc EI ℓ e i 2 hi4 (by norm_num), elemEntry_loc EI ℓ e i 3 hi4 (by norm_num)]
      exact hW e ⟨i, hi4⟩
    · simp [elemEntry_out _ _ _ _ _ h]
  have hlift := key (fun b => if b % 2 = 0 then 1 else 0) (by
    intro e i
    have a1 : (2 * e + 1) % 2 = 1 := by omega
    have a2 : (2 * e + 2) % 2 = 0 := by omega
    have a3 : (2 * e + 3) % 2 = 1 := by omega
    simp only [a1, a2, a3, Nat.mul_mod_right]
    fin_cases i <;> simp [kElem] <;> ring)
  have hturn := key (fun b => if b % 2 = 0 then ((b / 2 : ℕ) : ℝ) * ℓ else 1) (by
    intro e i
    have a1 : (2 * e + 1) % 2 = 1 := by omega
    have a2 : (2 * e + 2) % 2 = 0 := by omega
    have a3 : (2 * e + 3) % 2 = 1 := by omega
    have b0 : 2 * e / 2 = e := by omega
    have b2 : (2 * e + 2) / 2 = e + 1 := by omega
    simp only [a1, a2, a3, Nat.mul_mod_right, b0, b2]
    fin_cases i <;> simp [kElem] <;> push_cast <;> ring)
  refine ⟨hlift, hturn, ?_⟩
  rw [← Matrix.exists_mulVec_eq_zero_iff]
  refine ⟨_, ?_, hlift⟩
  intro h
  have := congrFun h ⟨0, by omega⟩
  simp at this

end FEBeam

open FEBeam Matrix

/-- One entry by hand: `k₁₁ = (EI/ℓ³) ∫₀¹ (12s - 6)² ds = 12 EI/ℓ³`. -/
example : ∫ s in (0 : ℝ)..1, (12 * s - 6) ^ 2 = 12 := by
  have : (fun s : ℝ => (12 * s - 6) ^ 2) = fun s => 144 * s ^ 2 - 144 * s + 36 := by
    funext s; ring
  rw [this, intervalIntegral.integral_add, intervalIntegral.integral_sub,
    intervalIntegral.integral_const_mul, intervalIntegral.integral_const_mul]
  · norm_num [integral_pow]
  all_goals first
    | exact (continuous_const.mul (continuous_pow 2)).intervalIntegrable _ _
    | exact (continuous_const.mul continuous_id).intervalIntegrable _ _
    | exact ((continuous_const.mul (continuous_pow 2)).sub
        (continuous_const.mul continuous_id)).intervalIntegrable _ _
    | exact intervalIntegrable_const

/-- Node 1 is shared by elements 1 and 2: drop entry `12 + 12`, turn entry `4 + 4`,
coupling `-6 + 6`. -/
example : (12 + 12 : ℤ) = 24 ∧ (4 + 4 : ℤ) = 8 ∧ (-6 + 6 : ℤ) = 0 := by norm_num

/-- The six free rows of `K` for three 1 m elements, in units of `EI/ℓ³`. -/
example : Kfree 3 1 1 = !![24, 0, -12, 6, 0, 0;
                           0, 8, -6, 2, 0, 0;
                           -12, -6, 24, 0, -12, 6;
                           6, 2, 0, 8, -6, 2;
                           0, 0, -12, -6, 12, -6;
                           0, 0, 6, 2, -6, 4] := by
  ext i j
  fin_cases i <;> fin_cases j <;> simp [Kfree, elemEntry, kElem, Finset.sum_range_succ] <;> norm_num

/-- The solve, in units of `P ℓ³ / EI`: `u = (4/3, 5/2, 14/3, 4, 9, 9/2)` gives `K u = F`;
the tip drops 9 units, which is `P L³ / 3EI` with `L = 3ℓ`. -/
example : Kfree 3 1 1 *ᵥ ![4/3, 5/2, 14/3, 4, 9, 9/2] = tipLoad 3 1 := by
  ext i
  fin_cases i <;>
    simp [Kfree, elemEntry, kElem, Finset.sum_range_succ, tipLoad, mulVec, dotProduct,
      Fin.sum_univ_succ] <;> norm_num

/-- Check rows 1 and 5 by hand: `32 - 56 + 24 = 0` and `-56 - 24 + 108 - 27 = 1`. -/
example : (24 * (4/3) - 12 * (14/3) + 6 * 4 : ℚ) = 0 ∧
    (-12 * (14/3) - 6 * 4 + 12 * 9 - 6 * (9/2) : ℚ) = 1 ∧ (3 : ℚ) ^ 3 / 3 = 9 := by
  norm_num

#print axioms cantilever_tip_load_fem_exact_at_nodes
#print axioms element_stiffness_eq_energy_integral
#print axioms unsupported_stiffness_singular
```

**Checked 2026-11-14 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'FEBeam.sum_loc' depends on axioms: [propext, Classical.choice, Quot.sound]
'FEBeam.elemEntry_out' depends on axioms: [propext, Classical.choice, Quot.sound]
'FEBeam.elemEntry_out'' depends on axioms: [propext, Classical.choice, Quot.sound]
'FEBeam.elemEntry_loc' depends on axioms: [propext, Classical.choice, Quot.sound]
'FEBeam.Kfull_mulVec' depends on axioms: [propext, Classical.choice, Quot.sound]
'FEBeam.Kfree_mulVec' depends on axioms: [propext, Classical.choice, Quot.sound]
'FEBeam.summand_loc' depends on axioms: [propext, Classical.choice, Quot.sound]
'FEBeam.summand_out' depends on axioms: [propext, Classical.choice, Quot.sound]
'FEBeam.Kfree_row' depends on axioms: [propext, Classical.choice, Quot.sound]
'FEBeam.cubic_dd' depends on axioms: [propext, Classical.choice, Quot.sound]
'FEBeam.lin_integral' depends on axioms: [propext, Classical.choice, Quot.sound]
'FEBeam.cantilever_tip_load_fem_exact_at_nodes' depends on axioms: [propext, Classical.choice, Quot.sound]
'FEBeam.element_stiffness_eq_energy_integral' depends on axioms: [propext, Classical.choice, Quot.sound]
'FEBeam.unsupported_stiffness_singular' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> An assert is a line that stops the program if a number comes out wrong. Guess first, then run it.
> - **Guess first:** do six elements beat three? Set `NE = 6`. The tip is still 14.6909 mm: when the true shape is a cubic on each piece, more pieces add nothing at the nodes. But the lumped own-weight answer moves from 1.687 mm to 1.642 mm, closer to the true 1.627 mm, and the assert that expects a large lumping error stops the program. Smaller pieces fix an approximate load; they cannot improve an exact one.
> - **Guess first:** what does a 5000 N load do? Set `P = 5000.0`. The tip drops 73.45 mm and the wall stress is 294 MPa, past the 275 MPa yield. The code reports both without complaint; only the engineer knows the model has left its range.
> - **Guess first:** what does a 4 m beam need? Set `L = 4.0`. The tip drops 34.82 mm against a limit of 22.22 mm: drop grows as the cube of length, the limit only in proportion.
> - **Guess first:** what happens if the matrix is overwritten instead of added? In `fem`, change `add=True` to `add=False`. The tip moves up, −3.26 mm, and the assert that compares it with $PL^3/3EI$ stops the program.

---

## The usual mistake

> [!warning]
> **Forgetting the supports.** Without the wall, $K$ times a rigid lift or a rigid turn is 0.0 N: the beam can float away for free, $K$ has no inverse, and a solver either stops on a zero pivot (a zero where elimination must divide) or prints meaningless large numbers. Every model needs enough supports to stop all rigid movement before the solve.
>
> - **Overwriting shared entries instead of adding them.** The tip comes out at −3.26 mm, moving up under a downward load.
> - **Putting a spread load on the nodes as forces only.** The own-weight drop comes out 1.687 mm instead of 1.627 mm; the element end moments carry the rest.
> - **Trusting an exact-looking answer outside the model.** At 10000 N the elements give 146.9 mm and 588 MPa with full precision, for a beam that has already yielded at 4680 N.

---

## Where you meet it in real life

- **Aircraft.** The method grew out of 1950s work on jet aircraft wings, where a skin with stiffeners was cut into triangles and bars and assembled into one stiffness matrix exactly as here (the 1956 paper in Sources).
- **Bridges and buildings.** Frame programs treat every beam and column as elements like the three on this card, with six movements per node in 3D instead of two.
- **Heat in a radiator panel.** Replace drop by temperature and stiffness by heat conductance, and the same assembly gives the temperatures inside a radiator or a boiler wall: [Fourier's law](05-heat-conduction-and-fouriers-law.md) sets the element matrix.
- **Car crashes and implants.** The same four steps run on millions of solid elements, with materials that yield, which is where the linear $K$ of this card is replaced step by step.

> **Say it back**
> Cut the structure into elements joined at nodes. For a beam element, the four end movements fix a cubic shape, and its stored energy gives a 4 by 4 stiffness matrix. Add each element's matrix into one big K wherever elements share a node, fix the supports, and solve K u = F. For the 3 m cantilever with 1 kN at the tip, three elements give 14.69 mm, exactly the formula, because the true shape is a cubic on each piece. For general shapes the answer is approximate and improves as the pieces shrink.

---

## What this builds on

- [Stress, strain and bending](../07-Mechanics%20and%20Structures/07-stress-strain-and-beam-bending.md): the bending equation $EI\,v'' = -M$, the stored energy, and the 120 mm I-section with its 306.31 cm⁴.
- [Solving A x = b](../../03-Algebra/05-Solving%20Systems/01-matrix-equation-ax-b.md): when a square system has exactly one answer, and why a missing support leaves none.
- [Finite differences](../../08-Differential%20equations%20and%20dynamics/07-Series%20Solutions%20and%20Boundary%20Problems/07-finite-differences-for-boundary-problems.md): the grid method this one is contrasted with, and the 300-step check on the tip drop.

## Where this goes next

- [Finite elements](../../16-Numerical%20analysis/07-PDE%20Solvers/07-finite-elements-galerkin-and-hat-functions.md): the weak form that turns any boundary problem into element matrices, shown on a hanging cable with tent-shaped hat functions, and why the answer is the best the pieces allow.
- [Assembly and error](../../16-Numerical%20analysis/07-PDE%20Solvers/08-finite-element-assembly-and-error.md): how big sparse matrices (mostly zeros) are assembled and solved, and how fast the answer improves as the mesh is refined.

This card used elements whose shapes contain the truth; how good the answer is when they do not, and how to tell from the computed numbers alone, is the question it leaves open.

---

## Sources

Verified 2026-11-11: every link below resolves to the publisher's page.

- Cook, Robert D., David S. Malkus, Michael E. Plesha and Robert J. Witt. *Concepts and Applications of Finite Element Analysis*, 4th ed. Wiley, 2001. [Publisher's page](https://www.wiley.com/en-us/Concepts+and+Applications+of+Finite+Element+Analysis%2C+4th+Edition-p-9780471356059). The beam element, its cubic shape functions, assembly, supports and consistent loads.
- Turner, M. J., R. W. Clough, H. C. Martin and L. J. Topp. "Stiffness and Deflection Analysis of Complex Structures." *Journal of the Aeronautical Sciences* 23 (1956): 805–823. [doi:10.2514/8.3664](https://doi.org/10.2514/8.3664). The direct stiffness method: element matrices added into one structure matrix.
- Courant, R. "Variational methods for the solution of problems of equilibrium and vibrations." *Bulletin of the American Mathematical Society* 49 (1943): 1–23. [doi:10.1090/S0002-9904-1943-07818-4](https://doi.org/10.1090/S0002-9904-1943-07818-4). Least energy over piecewise polynomial shapes, the idea behind Step 5.
- Goodno, Barry J., and James M. Gere. *Mechanics of Materials*, 9th ed. Cengage, 2018. [Publisher's page](https://www.cengage.com/c/mechanics-of-materials-9e-goodno-gere/9781337093347). The cantilever formulas $PL^3/3EI$ and $wL^4/8EI$, and steel at E = 200 GPa and 7850 kg/m³.
- NIST. "Standard acceleration of gravity." CODATA recommended values. [NIST page](https://physics.nist.gov/cgi-bin/cuu/Value?gn). The 9.80665 m/s² that turns 1000 N into 102.0 kg and the beam's mass into 98.46 N/m.
