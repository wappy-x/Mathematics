<a name="top"></a>

[Syllabus](../../SYLLABUS.md) → Numerical analysis

# 16 · Numerical analysis

Say how accurate a computed number is and why, and choose, cost and analyse a method for roots, linear systems, eigenvalues, interpolation, integrals, ODEs and PDEs. Every convergence claim the practical wings leaned on is proved here, with its failure mode and its price in arithmetic named.

8 shelves · **0 of 68 cards ready to read** · all planned, not written yet

| Shelf | Cards |
| --- | ---: |
| [01 · Floating Point and Error](#s01) | 9 |
| [02 · Root Finding and Fixed Points](#s02) | 8 |
| [03 · Numerical Linear Algebra](#s03) | 10 |
| [04 · Interpolation and Approximation](#s04) | 9 |
| [05 · Quadrature](#s05) | 7 |
| [06 · ODE Solvers](#s06) | 7 |
| [07 · PDE Solvers](#s07) | 10 |
| [08 · Derivatives by Machine](#s08) | 8 |

<a name="s01"></a>

## 01 · Floating Point and Error · 9 cards

*How a machine holds a number, where digits die, how much the problem itself magnifies a wobble, and what the work costs*

1. Absolute and relative error: wrong by how much, wrong by what fraction
2. IEEE 754: sign, exponent and fraction, and the numbers a computer cannot hold
3. Machine epsilon and cancellation: the gap next to one, and digits subtraction destroys
4. Two different errors: the formula's truncation and the machine's rounding
5. Conditioning and stability: a fragile problem is not the same thing as a sloppy method
6. Forward and backward error: a wrong answer, or the exact answer to a wrong question
7. Adding a million numbers without losing the small ones: Kahan, pairwise and Welford
8. Counting the work: flops, growth rates, and why a tuned library beats your loop
9. Interval arithmetic: carry a guaranteed range instead of a single number

[↑ Back to the shelves](#top)

<a name="s02"></a>

## 02 · Root Finding and Fixed Points · 8 cards

*Bracketing, tangent and chord steps with their convergence orders, safeguards, contraction maps, and every root of a polynomial*

1. Bisection: halve a bracket that has to contain a crossing
2. Newton and secant: a tangent step and a chord step, and how fast each converges
3. When to stop: residual, step size, and the test that survives a nearly flat curve
4. Newton's bad days: double roots, overshoot, and starting points that never settle
5. Brent's method: fast steps while they behave, bisection the moment they do not
6. Fixed points: iterate until nothing moves, and the contraction that makes it work
7. Newton in several unknowns, and Broyden when a Jacobian is too expensive
8. Every root at once: Horner's evaluation, deflation, and the companion matrix

[↑ Back to the shelves](#top)

<a name="s03"></a>

## 03 · Numerical Linear Algebra · 10 cards

*Factorisations and their cost, how far a data error can be amplified, eigenvalues by iteration, and solvers that exploit sparsity*

1. Matrix norms and the condition number: the worst amplification a linear system allows
2. LU with partial pivoting: factor once, then solve every right-hand side cheaply
3. The Thomas algorithm: a chain of unknowns solved in one sweep down and one back
4. Cholesky: half the work when a matrix is symmetric and positive definite
5. QR: rotate a matrix into a triangle, by reflections or by orthogonalising
6. Least squares two ways: the normal equations square the conditioning, QR does not
7. Eigenvalues by iteration: power steps, shifted inverse steps, and the QR algorithm
8. Singular value decomposition: rank you can trust, and the best low-rank fit
9. Iterating instead of factoring: Jacobi, Gauss-Seidel and conjugate gradient
10. Sparse storage and Krylov methods: work only where the entries are

[↑ Back to the shelves](#top)

<a name="s04"></a>

## 04 · Interpolation and Approximation · 9 cards

*Reading between data points, why high-degree polynomials misbehave, splines, best fits, and rational stand-ins*

1. Linear interpolation: read between two points, and the risk of reading past the last one
2. One polynomial through n points: Lagrange, divided differences and Vandermonde
3. The interpolation error theorem: one high derivative times the product of node distances
4. Runge's phenomenon: equal spacing fails at high degree, and Chebyshev nodes repair it
5. Cubic splines: smooth cubic pieces joined so that the curvature matches
6. Ends and shape: natural, clamped and not-a-knot, and keeping a fitted curve monotone
7. Fitting instead of passing through: least squares in an orthogonal basis
8. Weierstrass and the minimax fit: as close as you like, and the smallest worst error
9. Pade approximants: a ratio of polynomials copes with a pole that a polynomial cannot

[↑ Back to the shelves](#top)

<a name="s05"></a>

## 05 · Quadrature · 7 cards

*Simple rules with proved error bounds, optimal node choice, adaptivity, and what to do when the dimension climbs*

1. Trapezoid, midpoint and Simpson: fit a simple shape on each small piece
2. Error bounds and Romberg: the h squared law, and cancelling it by extrapolation
3. Gaussian quadrature: choose the sample points as well as their weights
4. Weighted Gauss rules: Hermite for a bell curve, Laguerre for a decaying tail
5. Adaptive quadrature and awkward integrals: spend points where the function misbehaves
6. Many dimensions: a product grid explodes, random points do not
7. Quasi-Monte Carlo and sparse grids: spread the points evenly on purpose

[↑ Back to the shelves](#top)

<a name="s06"></a>

## 06 · ODE Solvers · 7 cards

*The Runge-Kutta family and its order conditions, step control, multistep formulas, stiffness, structure-preserving steps, and boundary problems*

1. Runge-Kutta: several slope samples per step, laid out in a tableau
2. From local error to global error: why order p per step gives order p overall
3. Embedded pairs: two orders from one set of samples, so the step can choose itself
4. Multistep methods: reuse the slopes you already have, explicit or implicit
5. Stiffness: when stability not accuracy sets the step, and the barriers on the cure
6. Symplectic steps: schemes that keep a mechanical system's energy honest for ever
7. Two-point boundary problems: shoot and correct, or solve the whole grid at once

[↑ Back to the shelves](#top)

<a name="s07"></a>

## 07 · PDE Solvers · 10 cards

*Which family a PDE belongs to, grids that converge, stability analysis, implicit steps, flow problems, finite elements, and spectral methods*

1. Three families: elliptic, parabolic and hyperbolic, and why the family picks the method
2. Finite differences on a grid: consistency plus stability equals convergence
3. Von Neumann analysis: feed a wave into the scheme and see whether it grows
4. Crank-Nicolson and the theta family: average the explicit and the implicit step
5. Two space dimensions: the five-point Laplacian, and ADI to keep solves tridiagonal
6. Flow problems: upwind differencing, and the choice between smearing and wobble
7. Finite elements: multiply by a test function, integrate by parts, and use hat functions
8. Assembly and error: adding element matrices, the two boundary kinds, and the error bound
9. The fast Fourier transform: n log n instead of n squared, by splitting the sum in half
10. Spectral methods: differentiate by transforming, and the accuracy smoothness buys

[↑ Back to the shelves](#top)

<a name="s08"></a>

## 08 · Derivatives by Machine · 8 cards

*Difference formulas and their step-size dilemma, extrapolation, and differentiating the program itself instead of the answer*

1. Forward, backward and central differences: three routes to a slope, two accuracies
2. Stencils to order: a fourth-order slope, a mixed derivative, and how to build your own
3. Richardson extrapolation: combine two step sizes to cancel the leading error term
4. Choosing the step: truncation falls, rounding rises, and the best step sits in between
5. Complex steps and dual numbers: a derivative with no subtraction to cancel
6. Forward-mode automatic differentiation: differentiate the code, one operation at a time
7. Reverse mode: every sensitivity of one output for roughly the cost of one run
8. Bumping a simulated price: why common random numbers rescue a noisy sensitivity

[↑ Back to the shelves](#top)

---

[← 15 · Optimization](../15-Optimization/README.md) · [All wings](../../SYLLABUS.md) · [17 · Topology →](../17-Topology/README.md)
