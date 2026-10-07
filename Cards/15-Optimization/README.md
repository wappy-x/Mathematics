<a name="top"></a>

[Syllabus](../../SYLLABUS.md) → Optimization

# 15 · Optimization

Recognise a convex problem, prove the optimality conditions that certify its answer, and run gradient, Newton, quasi-Newton, trust region, simplex, interior point and proximal methods knowing how fast each converges. Use duality to bound and certify an answer, handle integer, cone and uncertain problems, and set up a dynamic program over time.

7 shelves · **0 of 64 cards ready to read** · all planned, not written yet

| Shelf | Cards |
| --- | ---: |
| [01 · Convexity](#s01) | 10 |
| [02 · Unconstrained Methods](#s02) | 10 |
| [03 · Constrained Optimisation](#s03) | 9 |
| [04 · Linear Programming](#s04) | 8 |
| [05 · Integer and Combinatorial Optimisation](#s05) | 8 |
| [06 · Conic, Quadratic and Stochastic Programs](#s06) | 10 |
| [07 · Dynamic Programming and Learning](#s07) | 9 |

<a name="s01"></a>

## 01 · Convexity · 10 cards

*Convex sets and convex functions, the tests that certify them, and the separation and conjugacy facts every later shelf rests on*

1. Local and global minima: the dip nearby against the true bottom
2. Convex sets: shapes with no dents, where the straight line stays inside
3. Convex functions: chords above the graph, and the curvature test that proves it
4. Convexity pays off: every local bottom of a convex problem is the lowest
5. Jensen's inequality: averaging inside a bowl beats averaging outside
6. Separating hyperplanes: a flat wall between a point and a convex set it misses
7. Subgradients: slopes that still work where the graph has a kink
8. Convex conjugates: describing a function by its slopes instead of its values
9. Building convex functions: the operations that cannot break the bowl
10. The standard convex problem: the shape every solver expects

[↑ Back to the shelves](#top)

<a name="s02"></a>

## 02 · Unconstrained Methods · 10 cards

*Conditions for a minimum, then the standard descent algorithms and an honest account of how fast each one gets there*

1. Optimality conditions: flat slope first, upward curvature second
2. Gradient descent: step downhill, and how the shape of the valley sets the pace
3. Convergence rates: linear, superlinear, quadratic, and what stretch costs you
4. Line search: how far to go once you have picked a direction
5. Newton and BFGS: use curvature, measured or remembered
6. L-BFGS: quasi-Newton when there are a million variables
7. Conjugate gradient: directions that never undo each other's work
8. Trust regions: trust the model only as far as it has earned
9. Nonlinear least squares: Gauss-Newton, and the damping that rescues it
10. Automatic differentiation: exact derivatives from the code, not from small steps

[↑ Back to the shelves](#top)

<a name="s03"></a>

## 03 · Constrained Optimisation · 9 cards

*Multipliers, the KKT checklist, duality as a certificate, and the four families of algorithm that enforce constraints*

1. Lagrange multipliers, proved: why the gradients must line up
2. KKT conditions: the checklist when inequalities can bind or slacken
3. Second-order conditions under constraints: curvature on the allowed directions only
4. Lagrangian duality: pricing the constraints gives a bound, sometimes exactly
5. Slater's condition: the strict feasibility that closes the gap
6. Saddle points: the same problem read as a two-player minimax
7. Penalties and augmented Lagrangians: fines that need not grow to infinity
8. Interior point methods: a barrier that keeps you strictly inside
9. Sequential quadratic programming: a quadratic model of the constrained problem each step

[↑ Back to the shelves](#top)

<a name="s04"></a>

## 04 · Linear Programming · 8 cards

*Linear programs from geometry to the simplex method, duality as a price system, and the interior point alternative*

1. Linear programs: straight-line costs over a shape cut by flat walls
2. Corners are enough: why a best linear answer sits at a vertex
3. The simplex method: walk the corners, improving on every move
4. LP duality: the partner problem with the same value, and the slackness that pairs them
5. Shadow prices: what one more hour of labour is actually worth
6. Network flows: shipping problems that are linear programs with whole answers
7. Modelling tricks: absolute values, worst cases and kinked costs as linear programs
8. Interior point for linear programs: polynomial time, and when simplex still wins

[↑ Back to the shelves](#top)

<a name="s05"></a>

## 05 · Integer and Combinatorial Optimisation · 8 cards

*Whole-number decisions: relaxations and bounds, search with pruning, cuts, the structures that make integrality free, and honest heuristics*

1. Integer programs: when the answer must be whole, and the relaxation that bounds it
2. Yes-or-no variables: switching constraints on and off with big-M
3. Branch and bound: split into cases and throw away what cannot win
4. Cutting planes: slicing off fractional corners without losing integer points
5. Total unimodularity: the matrices whose linear programs are already integral
6. Four classic models: knapsack, assignment, covering and routing
7. Lagrangian relaxation: price the awkward constraint and solve what is left
8. Heuristics with a promise: greedy bounds and approximation ratios

[↑ Back to the shelves](#top)

<a name="s06"></a>

## 06 · Conic, Quadratic and Stochastic Programs · 10 cards

*The problem classes solvers actually target, plus the proximal, splitting and sampling methods that scale*

1. Quadratic programs: a bowl-shaped cost under straight-line limits
2. Two goals at once: Pareto optimality and the frontier of trade-offs
3. Support vector machines: the widest gap as a quadratic program
4. Second-order cone programs: constraints shaped like ice cream cones
5. Semidefinite programs: optimising over matrices that must stay positive
6. Proximal gradient: a smooth step, then a shrink, and the lasso falls out
7. ADMM: split the problem, solve the easy halves, reconcile each round
8. Stochastic gradient: a noisy step is cheap enough to take many times
9. Momentum and Adam: inertia, and a step size per variable
10. Robust and chance constraints: answers that survive the data being wrong

[↑ Back to the shelves](#top)

<a name="s07"></a>

## 07 · Dynamic Programming and Learning · 9 cards

*Decisions over time: backward induction, Markov decision processes, the contraction that makes them solvable, learning when the model is unknown, and search when nothing is smooth*

1. Backward induction: solve the last decision first, then work back
2. Markov decision processes: states, actions, rewards and a transition rule
3. Value and policy iteration: two ways to settle on the best rule
4. The Bellman operator contracts: why repeated sweeps must converge
5. Q-learning: learning the values by trying, without knowing the model
6. Optimal stopping: deciding when now beats waiting
7. Two-stage stochastic programming: decide now, adjust when you know more
8. Bayesian optimisation: choosing the next expensive experiment wisely
9. Search without derivatives: Nelder-Mead, annealing and populations

[↑ Back to the shelves](#top)

---

[← 14 · Applied and computational](../14-Applied%20and%20computational/README.md) · [All wings](../../SYLLABUS.md) · [16 · Numerical analysis →](../16-Numerical%20analysis/README.md)
