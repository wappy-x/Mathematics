<a name="top"></a>

[Syllabus](../../SYLLABUS.md) → Numerical analysis

# 16 · Numerical analysis

Say how accurate a computed number is and why, and choose, cost and analyse a method for roots, linear systems, eigenvalues, interpolation, integrals, ODEs and PDEs. Every convergence claim the practical wings leaned on is proved here, with its failure mode and its price in arithmetic named.

8 shelves · **68 of 68 cards ready to read**

Click a shelf to jump to its cards, then click a card's title to read it.

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

1. [Absolute and relative error: wrong by how much, wrong by what fraction](01-Floating%20Point%20and%20Error/01-absolute-and-relative-error.md)
2. [IEEE 754: sign, exponent and fraction, and the numbers a computer cannot hold](01-Floating%20Point%20and%20Error/02-ieee-floating-point.md)
3. [Machine epsilon and cancellation: the gap next to one, and digits subtraction destroys](01-Floating%20Point%20and%20Error/03-rounding-cancellation-and-machine-epsilon.md)
4. [Two different errors: the formula's truncation and the machine's rounding](01-Floating%20Point%20and%20Error/04-truncation-versus-rounding-error.md)
5. [Conditioning and stability: a fragile problem is not the same thing as a sloppy method](01-Floating%20Point%20and%20Error/05-conditioning-and-stability.md)
6. [Forward and backward error: a wrong answer, or the exact answer to a wrong question](01-Floating%20Point%20and%20Error/06-forward-and-backward-error.md)
7. [Adding a million numbers without losing the small ones: Kahan, pairwise and Welford](01-Floating%20Point%20and%20Error/07-summation-kahan-and-welford.md)
8. [Counting the work: flops, growth rates, and why a tuned library beats your loop](01-Floating%20Point%20and%20Error/08-operation-counts-and-cost.md)
9. [Interval arithmetic: carry a guaranteed range instead of a single number](01-Floating%20Point%20and%20Error/09-interval-arithmetic-in-outline.md)

[↑ Back to the shelves](#top)

<a name="s02"></a>

## 02 · Root Finding and Fixed Points · 8 cards

*Bracketing, tangent and chord steps with their convergence orders, safeguards, contraction maps, and every root of a polynomial*

1. [Bisection: halve a bracket that has to contain a crossing](02-Root%20Finding%20and%20Fixed%20Points/01-bisection-and-bracketing.md)
2. [Newton and secant: a tangent step and a chord step, and how fast each converges](02-Root%20Finding%20and%20Fixed%20Points/02-newton-and-secant-with-convergence-orders.md)
3. [When to stop: residual, step size, and the test that survives a nearly flat curve](02-Root%20Finding%20and%20Fixed%20Points/03-stopping-criteria-and-error-estimates.md)
4. [Newton's bad days: double roots, overshoot, and starting points that never settle](02-Root%20Finding%20and%20Fixed%20Points/04-when-newton-fails.md)
5. [Brent's method: fast steps while they behave, bisection the moment they do not](02-Root%20Finding%20and%20Fixed%20Points/05-brent-and-safeguarded-methods.md)
6. [Fixed points: iterate until nothing moves, and the contraction that makes it work](02-Root%20Finding%20and%20Fixed%20Points/06-fixed-point-iteration-and-contraction.md)
7. [Newton in several unknowns, and Broyden when a Jacobian is too expensive](02-Root%20Finding%20and%20Fixed%20Points/07-newton-for-systems-and-broyden.md)
8. [Every root at once: Horner's evaluation, deflation, and the companion matrix](02-Root%20Finding%20and%20Fixed%20Points/08-polynomial-roots-and-companion-matrices.md)

[↑ Back to the shelves](#top)

<a name="s03"></a>

## 03 · Numerical Linear Algebra · 10 cards

*Factorisations and their cost, how far a data error can be amplified, eigenvalues by iteration, and solvers that exploit sparsity*

1. [Matrix norms and the condition number: the worst amplification a linear system allows](03-Numerical%20Linear%20Algebra/01-matrix-norms-and-the-condition-number.md)
2. [LU with partial pivoting: factor once, then solve every right-hand side cheaply](03-Numerical%20Linear%20Algebra/02-lu-decomposition-and-pivoting.md)
3. [The Thomas algorithm: a chain of unknowns solved in one sweep down and one back](03-Numerical%20Linear%20Algebra/03-tridiagonal-systems-and-the-thomas-algorithm.md)
4. [Cholesky: half the work when a matrix is symmetric and positive definite](03-Numerical%20Linear%20Algebra/04-cholesky-decomposition.md)
5. [QR: rotate a matrix into a triangle, by reflections or by orthogonalising](03-Numerical%20Linear%20Algebra/05-qr-householder-and-gram-schmidt.md)
6. [Least squares two ways: the normal equations square the conditioning, QR does not](03-Numerical%20Linear%20Algebra/06-least-squares-normal-equations-versus-qr.md)
7. [Eigenvalues by iteration: power steps, shifted inverse steps, and the QR algorithm](03-Numerical%20Linear%20Algebra/07-eigenvalues-power-iteration-and-the-qr-algorithm.md)
8. [Singular value decomposition: rank you can trust, and the best low-rank fit](03-Numerical%20Linear%20Algebra/08-svd-and-the-pseudoinverse.md)
9. [Iterating instead of factoring: Jacobi, Gauss-Seidel and conjugate gradient](03-Numerical%20Linear%20Algebra/09-iterative-methods-jacobi-gauss-seidel-and-conjugate-gradient.md)
10. [Sparse storage and Krylov methods: work only where the entries are](03-Numerical%20Linear%20Algebra/10-sparse-matrices-and-krylov-methods.md)

[↑ Back to the shelves](#top)

<a name="s04"></a>

## 04 · Interpolation and Approximation · 9 cards

*Reading between data points, why high-degree polynomials misbehave, splines, best fits, and rational stand-ins*

1. [Linear interpolation: read between two points, and the risk of reading past the last one](04-Interpolation%20and%20Approximation/01-linear-interpolation-and-extrapolation.md)
2. [One polynomial through n points: Lagrange, divided differences and Vandermonde](04-Interpolation%20and%20Approximation/02-lagrange-and-newton-interpolation.md)
3. [The interpolation error theorem: one high derivative times the product of node distances](04-Interpolation%20and%20Approximation/03-polynomial-interpolation-error.md)
4. [Runge's phenomenon: equal spacing fails at high degree, and Chebyshev nodes repair it](04-Interpolation%20and%20Approximation/04-runge-phenomenon-and-chebyshev-nodes.md)
5. [Cubic splines: smooth cubic pieces joined so that the curvature matches](04-Interpolation%20and%20Approximation/05-splines.md)
6. [Ends and shape: natural, clamped and not-a-knot, and keeping a fitted curve monotone](04-Interpolation%20and%20Approximation/06-spline-end-conditions-and-shape.md)
7. [Fitting instead of passing through: least squares in an orthogonal basis](04-Interpolation%20and%20Approximation/07-least-squares-and-orthogonal-polynomials.md)
8. [Weierstrass and the minimax fit: as close as you like, and the smallest worst error](04-Interpolation%20and%20Approximation/08-weierstrass-and-best-approximation.md)
9. [Pade approximants: a ratio of polynomials copes with a pole that a polynomial cannot](04-Interpolation%20and%20Approximation/09-pade-and-rational-approximation.md)

[↑ Back to the shelves](#top)

<a name="s05"></a>

## 05 · Quadrature · 7 cards

*Simple rules with proved error bounds, optimal node choice, adaptivity, and what to do when the dimension climbs*

1. [Trapezoid, midpoint and Simpson: fit a simple shape on each small piece](05-Quadrature/01-newton-cotes-and-composite-rules.md)
2. [Error bounds and Romberg: the h squared law, and cancelling it by extrapolation](05-Quadrature/02-error-bounds-and-romberg.md)
3. [Gaussian quadrature: choose the sample points as well as their weights](05-Quadrature/03-gaussian-quadrature.md)
4. [Weighted Gauss rules: Hermite for a bell curve, Laguerre for a decaying tail](05-Quadrature/04-gauss-hermite-and-weighted-rules.md)
5. [Adaptive quadrature and awkward integrals: spend points where the function misbehaves](05-Quadrature/05-adaptive-and-improper-quadrature.md)
6. [Many dimensions: a product grid explodes, random points do not](05-Quadrature/06-multidimensional-and-monte-carlo-quadrature.md)
7. [Quasi-Monte Carlo and sparse grids: spread the points evenly on purpose](05-Quadrature/07-quasi-monte-carlo-and-sparse-grids.md)

[↑ Back to the shelves](#top)

<a name="s06"></a>

## 06 · ODE Solvers · 7 cards

*The Runge-Kutta family and its order conditions, step control, multistep formulas, stiffness, structure-preserving steps, and boundary problems*

1. [Runge-Kutta: several slope samples per step, laid out in a tableau](06-ODE%20Solvers/01-runge-kutta-and-butcher-tableaux.md)
2. [From local error to global error: why order p per step gives order p overall](06-ODE%20Solvers/02-convergence-of-one-step-methods.md)
3. [Embedded pairs: two orders from one set of samples, so the step can choose itself](06-ODE%20Solvers/03-embedded-pairs-and-adaptive-steps.md)
4. [Multistep methods: reuse the slopes you already have, explicit or implicit](06-ODE%20Solvers/04-multistep-adams-and-bdf.md)
5. [Stiffness: when stability not accuracy sets the step, and the barriers on the cure](06-ODE%20Solvers/05-stiffness-a-stability-and-the-dahlquist-barriers.md)
6. [Symplectic steps: schemes that keep a mechanical system's energy honest for ever](06-ODE%20Solvers/06-symplectic-integrators.md)
7. [Two-point boundary problems: shoot and correct, or solve the whole grid at once](06-ODE%20Solvers/07-boundary-value-problems-shooting-and-collocation.md)

[↑ Back to the shelves](#top)

<a name="s07"></a>

## 07 · PDE Solvers · 10 cards

*Which family a PDE belongs to, grids that converge, stability analysis, implicit steps, flow problems, finite elements, and spectral methods*

1. [Three families: elliptic, parabolic and hyperbolic, and why the family picks the method](07-PDE%20Solvers/01-pde-families-elliptic-parabolic-hyperbolic.md)
2. [Finite differences on a grid: consistency plus stability equals convergence](07-PDE%20Solvers/02-finite-differences-consistency-stability-and-convergence.md)
3. [Von Neumann analysis: feed a wave into the scheme and see whether it grows](07-PDE%20Solvers/03-von-neumann-analysis-and-the-cfl-condition.md)
4. [Crank-Nicolson and the theta family: average the explicit and the implicit step](07-PDE%20Solvers/04-crank-nicolson-and-theta-methods.md)
5. [Two space dimensions: the five-point Laplacian, and ADI to keep solves tridiagonal](07-PDE%20Solvers/05-adi-and-multidimensional-grids.md)
6. [Flow problems: upwind differencing, and the choice between smearing and wobble](07-PDE%20Solvers/06-upwind-schemes-and-conservation-laws.md)
7. [Finite elements: multiply by a test function, integrate by parts, and use hat functions](07-PDE%20Solvers/07-finite-elements-galerkin-and-hat-functions.md)
8. [Assembly and error: adding element matrices, the two boundary kinds, and the error bound](07-PDE%20Solvers/08-finite-element-assembly-and-error.md)
9. [The fast Fourier transform: n log n instead of n squared, by splitting the sum in half](07-PDE%20Solvers/09-the-fast-fourier-transform.md)
10. [Spectral methods: differentiate by transforming, and the accuracy smoothness buys](07-PDE%20Solvers/10-spectral-methods-and-the-fft.md)

[↑ Back to the shelves](#top)

<a name="s08"></a>

## 08 · Derivatives by Machine · 8 cards

*Difference formulas and their step-size dilemma, extrapolation, and differentiating the program itself instead of the answer*

1. [Forward, backward and central differences: three routes to a slope, two accuracies](08-Derivatives%20by%20Machine/01-forward-backward-and-central-differences.md)
2. [Stencils to order: a fourth-order slope, a mixed derivative, and how to build your own](08-Derivatives%20by%20Machine/02-stencils-for-higher-and-mixed-derivatives.md)
3. [Richardson extrapolation: combine two step sizes to cancel the leading error term](08-Derivatives%20by%20Machine/03-richardson-extrapolation.md)
4. [Choosing the step: truncation falls, rounding rises, and the best step sits in between](08-Derivatives%20by%20Machine/04-choosing-the-step-truncation-against-rounding.md)
5. [Complex steps and dual numbers: a derivative with no subtraction to cancel](08-Derivatives%20by%20Machine/05-complex-step-and-dual-numbers.md)
6. [Forward-mode automatic differentiation: differentiate the code, one operation at a time](08-Derivatives%20by%20Machine/06-forward-mode-automatic-differentiation.md)
7. [Reverse mode: every sensitivity of one output for roughly the cost of one run](08-Derivatives%20by%20Machine/07-reverse-mode-automatic-differentiation.md)
8. [Bumping a simulated price: why common random numbers rescue a noisy sensitivity](08-Derivatives%20by%20Machine/08-bumped-sensitivities-and-monte-carlo-noise.md)

[↑ Back to the shelves](#top)

---

[← 15 · Optimization](../15-Optimization/README.md) · [All wings](../../SYLLABUS.md) · [17 · Topology →](../17-Topology/README.md)
