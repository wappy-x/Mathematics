<a name="top"></a>

[Syllabus](../../SYLLABUS.md) → Optimization

# 15 · Optimization

Recognise a convex problem, prove the optimality conditions that certify its answer, and run gradient, Newton, quasi-Newton, trust region, simplex, interior point and proximal methods knowing how fast each converges. Use duality to bound and certify an answer, handle integer, cone and uncertain problems, and set up a dynamic program over time.

7 shelves · **64 of 64 cards ready to read**

Click a shelf to jump to its cards, then click a card's title to read it.

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

1. [Local and global minima: the dip nearby against the true bottom](01-Convexity/01-local-and-global-minima.md)
2. [Convex sets: shapes with no dents, where the straight line stays inside](01-Convexity/02-convex-sets.md)
3. [Convex functions: chords above the graph, and the curvature test that proves it](01-Convexity/03-convex-functions-and-their-tests.md)
4. [Convexity pays off: every local bottom of a convex problem is the lowest](01-Convexity/04-local-minima-are-global-when-convex.md)
5. [Jensen's inequality: averaging inside a bowl beats averaging outside](01-Convexity/05-jensen-and-supporting-lines.md)
6. [Separating hyperplanes: a flat wall between a point and a convex set it misses](01-Convexity/06-separating-hyperplanes.md)
7. [Subgradients: slopes that still work where the graph has a kink](01-Convexity/07-subgradients.md)
8. [Convex conjugates: describing a function by its slopes instead of its values](01-Convexity/08-conjugates-and-fenchel-duality.md)
9. [Building convex functions: the operations that cannot break the bowl](01-Convexity/09-operations-that-preserve-convexity.md)
10. [The standard convex problem: the shape every solver expects](01-Convexity/10-the-convex-problem-in-standard-form.md)

[↑ Back to the shelves](#top)

<a name="s02"></a>

## 02 · Unconstrained Methods · 10 cards

*Conditions for a minimum, then the standard descent algorithms and an honest account of how fast each one gets there*

1. [Optimality conditions: flat slope first, upward curvature second](02-Unconstrained%20Methods/01-optimality-conditions.md)
2. [Gradient descent: step downhill, and how the shape of the valley sets the pace](02-Unconstrained%20Methods/02-gradient-descent-and-its-rate.md)
3. [Convergence rates: linear, superlinear, quadratic, and what stretch costs you](02-Unconstrained%20Methods/03-rates-of-convergence-and-conditioning.md)
4. [Line search: how far to go once you have picked a direction](02-Unconstrained%20Methods/04-line-search-armijo-and-wolfe.md)
5. [Newton and BFGS: use curvature, measured or remembered](02-Unconstrained%20Methods/05-newton-and-quasi-newton-bfgs.md)
6. [L-BFGS: quasi-Newton when there are a million variables](02-Unconstrained%20Methods/06-l-bfgs-and-limited-memory-updates.md)
7. [Conjugate gradient: directions that never undo each other's work](02-Unconstrained%20Methods/07-conjugate-gradient-method.md)
8. [Trust regions: trust the model only as far as it has earned](02-Unconstrained%20Methods/08-trust-region-methods.md)
9. [Nonlinear least squares: Gauss-Newton, and the damping that rescues it](02-Unconstrained%20Methods/09-nonlinear-least-squares-gauss-newton-and-levenberg-marquardt.md)
10. [Automatic differentiation: exact derivatives from the code, not from small steps](02-Unconstrained%20Methods/10-automatic-differentiation-and-backpropagation.md)

[↑ Back to the shelves](#top)

<a name="s03"></a>

## 03 · Constrained Optimisation · 9 cards

*Multipliers, the KKT checklist, duality as a certificate, and the four families of algorithm that enforce constraints*

1. [Lagrange multipliers, proved: why the gradients must line up](03-Constrained%20Optimisation/01-lagrange-multipliers-revisited.md)
2. [KKT conditions: the checklist when inequalities can bind or slacken](03-Constrained%20Optimisation/02-kkt-conditions.md)
3. [Second-order conditions under constraints: curvature on the allowed directions only](03-Constrained%20Optimisation/03-second-order-conditions-for-constrained-problems.md)
4. [Lagrangian duality: pricing the constraints gives a bound, sometimes exactly](03-Constrained%20Optimisation/04-lagrangian-duality-weak-and-strong.md)
5. [Slater's condition: the strict feasibility that closes the gap](03-Constrained%20Optimisation/05-slaters-condition-and-duality-gaps.md)
6. [Saddle points: the same problem read as a two-player minimax](03-Constrained%20Optimisation/06-saddle-points-and-minimax.md)
7. [Penalties and augmented Lagrangians: fines that need not grow to infinity](03-Constrained%20Optimisation/07-penalty-and-augmented-lagrangian-methods.md)
8. [Interior point methods: a barrier that keeps you strictly inside](03-Constrained%20Optimisation/08-interior-point-methods.md)
9. [Sequential quadratic programming: a quadratic model of the constrained problem each step](03-Constrained%20Optimisation/09-sequential-quadratic-programming.md)

[↑ Back to the shelves](#top)

<a name="s04"></a>

## 04 · Linear Programming · 8 cards

*Linear programs from geometry to the simplex method, duality as a price system, and the interior point alternative*

1. [Linear programs: straight-line costs over a shape cut by flat walls](04-Linear%20Programming/01-linear-programs-and-polyhedra.md)
2. [Corners are enough: why a best linear answer sits at a vertex](04-Linear%20Programming/02-corners-and-the-fundamental-theorem.md)
3. [The simplex method: walk the corners, improving on every move](04-Linear%20Programming/03-simplex-method.md)
4. [LP duality: the partner problem with the same value, and the slackness that pairs them](04-Linear%20Programming/04-lp-duality-and-complementary-slackness.md)
5. [Shadow prices: what one more hour of labour is actually worth](04-Linear%20Programming/05-sensitivity-and-shadow-prices.md)
6. [Network flows: shipping problems that are linear programs with whole answers](04-Linear%20Programming/06-network-flows-as-linear-programs.md)
7. [Modelling tricks: absolute values, worst cases and kinked costs as linear programs](04-Linear%20Programming/07-piecewise-linear-and-minimax-objectives-as-lps.md)
8. [Interior point for linear programs: polynomial time, and when simplex still wins](04-Linear%20Programming/08-interior-point-for-lp-and-complexity.md)

[↑ Back to the shelves](#top)

<a name="s05"></a>

## 05 · Integer and Combinatorial Optimisation · 8 cards

*Whole-number decisions: relaxations and bounds, search with pruning, cuts, the structures that make integrality free, and honest heuristics*

1. [Integer programs: when the answer must be whole, and the relaxation that bounds it](05-Integer%20and%20Combinatorial%20Optimisation/01-integer-programs-and-relaxations.md)
2. [Yes-or-no variables: switching constraints on and off with big-M](05-Integer%20and%20Combinatorial%20Optimisation/02-modelling-with-binary-variables-big-m-and-indicators.md)
3. [Branch and bound: split into cases and throw away what cannot win](05-Integer%20and%20Combinatorial%20Optimisation/03-branch-and-bound.md)
4. [Cutting planes: slicing off fractional corners without losing integer points](05-Integer%20and%20Combinatorial%20Optimisation/04-cutting-planes.md)
5. [Total unimodularity: the matrices whose linear programs are already integral](05-Integer%20and%20Combinatorial%20Optimisation/05-total-unimodularity.md)
6. [Four classic models: knapsack, assignment, covering and routing](05-Integer%20and%20Combinatorial%20Optimisation/06-classic-integer-models-knapsack-assignment-and-covering.md)
7. [Lagrangian relaxation: price the awkward constraint and solve what is left](05-Integer%20and%20Combinatorial%20Optimisation/07-lagrangian-relaxation-and-decomposition.md)
8. [Heuristics with a promise: greedy bounds and approximation ratios](05-Integer%20and%20Combinatorial%20Optimisation/08-heuristics-and-approximation-guarantees.md)

[↑ Back to the shelves](#top)

<a name="s06"></a>

## 06 · Conic, Quadratic and Stochastic Programs · 10 cards

*The problem classes solvers actually target, plus the proximal, splitting and sampling methods that scale*

1. [Quadratic programs: a bowl-shaped cost under straight-line limits](06-Conic%2C%20Quadratic%20and%20Stochastic%20Programs/01-quadratic-programs-and-markowitz.md)
2. [Two goals at once: Pareto optimality and the frontier of trade-offs](06-Conic%2C%20Quadratic%20and%20Stochastic%20Programs/02-multi-objective-trade-offs-and-the-pareto-frontier.md)
3. [Support vector machines: the widest gap as a quadratic program](06-Conic%2C%20Quadratic%20and%20Stochastic%20Programs/03-support-vector-machines-as-a-quadratic-program.md)
4. [Second-order cone programs: constraints shaped like ice cream cones](06-Conic%2C%20Quadratic%20and%20Stochastic%20Programs/04-second-order-cone-programs.md)
5. [Semidefinite programs: optimising over matrices that must stay positive](06-Conic%2C%20Quadratic%20and%20Stochastic%20Programs/05-semidefinite-programs-and-relaxations.md)
6. [Proximal gradient: a smooth step, then a shrink, and the lasso falls out](06-Conic%2C%20Quadratic%20and%20Stochastic%20Programs/06-proximal-methods-ista-fista-and-the-lasso.md)
7. [ADMM: split the problem, solve the easy halves, reconcile each round](06-Conic%2C%20Quadratic%20and%20Stochastic%20Programs/07-admm.md)
8. [Stochastic gradient: a noisy step is cheap enough to take many times](06-Conic%2C%20Quadratic%20and%20Stochastic%20Programs/08-stochastic-gradient-and-sample-average-approximation.md)
9. [Momentum and Adam: inertia, and a step size per variable](06-Conic%2C%20Quadratic%20and%20Stochastic%20Programs/09-momentum-adam-and-step-size-schedules.md)
10. [Robust and chance constraints: answers that survive the data being wrong](06-Conic%2C%20Quadratic%20and%20Stochastic%20Programs/10-robust-and-chance-constrained-optimisation.md)

[↑ Back to the shelves](#top)

<a name="s07"></a>

## 07 · Dynamic Programming and Learning · 9 cards

*Decisions over time: backward induction, Markov decision processes, the contraction that makes them solvable, learning when the model is unknown, and search when nothing is smooth*

1. [Backward induction: solve the last decision first, then work back](07-Dynamic%20Programming%20and%20Learning/01-finite-horizon-dynamic-programming-and-backward-induction.md)
2. [Markov decision processes: states, actions, rewards and a transition rule](07-Dynamic%20Programming%20and%20Learning/02-markov-decision-processes.md)
3. [Value and policy iteration: two ways to settle on the best rule](07-Dynamic%20Programming%20and%20Learning/03-value-and-policy-iteration.md)
4. [The Bellman operator contracts: why repeated sweeps must converge](07-Dynamic%20Programming%20and%20Learning/04-the-bellman-operator-as-a-contraction.md)
5. [Q-learning: learning the values by trying, without knowing the model](07-Dynamic%20Programming%20and%20Learning/05-q-learning-and-temporal-differences.md)
6. [Optimal stopping: deciding when now beats waiting](07-Dynamic%20Programming%20and%20Learning/06-optimal-stopping-as-a-dynamic-program.md)
7. [Two-stage stochastic programming: decide now, adjust when you know more](07-Dynamic%20Programming%20and%20Learning/07-stochastic-programming-with-recourse.md)
8. [Bayesian optimisation: choosing the next expensive experiment wisely](07-Dynamic%20Programming%20and%20Learning/08-global-optimisation-and-bayesian-optimisation.md)
9. [Search without derivatives: Nelder-Mead, annealing and populations](07-Dynamic%20Programming%20and%20Learning/09-derivative-free-and-metaheuristic-search.md)

[↑ Back to the shelves](#top)

---

[← 14 · Applied and computational](../14-Applied%20and%20computational/README.md) · [All wings](../../SYLLABUS.md) · [16 · Numerical analysis →](../16-Numerical%20analysis/README.md)
