<a name="top"></a>

[Syllabus](../../SYLLABUS.md) → Stochastic processes and calculus

# 11 · Stochastic processes and calculus

Follow randomness through time: random walks, martingales, Markov chains, Poisson arrivals, Brownian motion and the calculus built on it. Write and solve a stochastic differential equation, change the probability measure, simulate a path honestly, and state the theorems the finance wing rests on.

10 shelves · **83 of 83 cards ready to read**

Click a shelf to jump to its cards, then click a card's title to read it.

| Shelf | Cards |
| --- | ---: |
| [01 · Random Walks and Filtrations](#s01) | 6 |
| [02 · Martingales](#s02) | 9 |
| [03 · Markov Chains](#s03) | 8 |
| [04 · Poisson and Jump Processes](#s04) | 8 |
| [05 · Brownian Motion](#s05) | 12 |
| [06 · Ito Calculus](#s06) | 8 |
| [07 · Changing Measure](#s07) | 6 |
| [08 · Generators, Densities and Simulation](#s08) | 10 |
| [09 · Beyond Brownian](#s09) | 10 |
| [10 · Continuous Martingales](#s10) | 6 |

<a name="s01"></a>

## 01 · Random Walks and Filtrations · 6 cards

*Paths, the information available at each time, and the first questions about a walk*

1. [Stochastic processes: one random variable per time, and a path for each outcome](01-Random%20Walks%20and%20Filtrations/01-processes-and-paths.md)
2. [Simple random walk: plus one or minus one each step](01-Random%20Walks%20and%20Filtrations/02-simple-random-walk.md)
3. [Filtrations: what is known at each time, and processes that only use it](01-Random%20Walks%20and%20Filtrations/03-filtrations-and-information.md)
4. [Gambler's ruin: the chance of reaching the target before the floor](01-Random%20Walks%20and%20Filtrations/04-gamblers-ruin.md)
5. [Reflection principle: counting paths that touch a level](01-Random%20Walks%20and%20Filtrations/05-reflection-principle-for-walks.md)
6. [Hitting times: when a walk first reaches a level, and why the wait can have infinite mean](01-Random%20Walks%20and%20Filtrations/06-first-passage-and-hitting-times.md)

[↑ Back to the shelves](#top)

<a name="s02"></a>

## 02 · Martingales · 9 cards

*Fair games in time: the definition, the strategies that cannot beat them, and when you may stop*

1. [Martingales: a process whose best forecast is its current value](02-Martingales/01-martingales.md)
2. [Betting on a martingale: any predictable strategy leaves a martingale](02-Martingales/02-predictable-bets-and-the-martingale-transform.md)
3. [Stopping times: rules that use only the past, and the theorem that quitting does not help](02-Martingales/03-stopping-times-and-optional-stopping.md)
4. [Martingale convergence: a bounded martingale settles down](02-Martingales/04-martingale-convergence.md)
5. [Doob's inequalities: the maximum of a martingale is controlled by its endpoint](02-Martingales/05-doob-inequalities.md)
6. [Stopping without a bound: the uniform integrability that makes it safe](02-Martingales/06-uniform-integrability-and-unbounded-stopping.md)
7. [Representing a martingale: on a binary tree every martingale is a bet on the coin](02-Martingales/07-martingale-representation-in-discrete-time.md)
8. [Azuma-Hoeffding and McDiarmid: a martingale with bounded steps rarely strays far](02-Martingales/08-azuma-hoeffding-and-mcdiarmid.md)
9. [Branching processes: family trees that die out or explode](02-Martingales/09-galton-watson-branching-processes.md)

[↑ Back to the shelves](#top)

<a name="s03"></a>

## 03 · Markov Chains · 8 cards

*Memoryless chains: transition matrices, long-run behaviour, absorption and sampling by a chain*

1. [Markov chains: the future depends on the present only](03-Markov%20Chains/01-markov-chains.md)
2. [n-step transitions: matrix powers and Chapman-Kolmogorov](03-Markov%20Chains/02-multi-step-transitions.md)
3. [Classifying states: which states talk to which, which are trapped, and which repeat with a period](03-Markov%20Chains/03-classifying-states.md)
4. [Stationary distributions: the mix that stays the same under one more step](03-Markov%20Chains/04-stationary-distributions.md)
5. [Convergence to equilibrium: an irreducible aperiodic chain forgets where it started](03-Markov%20Chains/05-convergence-to-equilibrium.md)
6. [Absorption: the chance of ending in each trap, and how long it takes](03-Markov%20Chains/06-absorption-and-first-step-analysis.md)
7. [MCMC: building a chain whose equilibrium is the distribution you want](03-Markov%20Chains/07-markov-chain-monte-carlo.md)
8. [Hidden Markov models: a chain you cannot see, observed through noise](03-Markov%20Chains/08-hidden-markov-models.md)

[↑ Back to the shelves](#top)

<a name="s04"></a>

## 04 · Poisson and Jump Processes · 8 cards

*Arrivals that come one at a time: the Poisson process, its variants, and chains that jump in continuous time*

1. [Poisson process: arrivals with exponential gaps, and counts that are Poisson](04-Poisson%20and%20Jump%20Processes/01-poisson-process.md)
2. [Given n arrivals, when did they happen: uniform order statistics](04-Poisson%20and%20Jump%20Processes/02-arrival-times-and-order-statistics.md)
3. [Splitting and merging: thinning a Poisson process and adding two](04-Poisson%20and%20Jump%20Processes/03-splitting-and-superposition.md)
4. [Compound Poisson: random arrivals with random sizes](04-Poisson%20and%20Jump%20Processes/04-compound-poisson.md)
5. [Continuous-time chains: rates instead of probabilities, and the M/M/1 queue](04-Poisson%20and%20Jump%20Processes/05-continuous-time-markov-chains-and-queues.md)
6. [Renewal processes: arrivals with any gap distribution](04-Poisson%20and%20Jump%20Processes/06-renewal-processes-in-outline.md)
7. [Birth-and-death processes: populations and queues that move one step at a time](04-Poisson%20and%20Jump%20Processes/07-birth-and-death-processes.md)
8. [Arrivals whose rate changes: time-varying Poisson processes and self-exciting Hawkes processes](04-Poisson%20and%20Jump%20Processes/08-inhomogeneous-poisson-and-hawkes-processes.md)

[↑ Back to the shelves](#top)

<a name="s05"></a>

## 05 · Brownian Motion · 12 cards

*The continuous limit of the random walk: its definition, its strange paths, and its most useful properties*

1. [Brownian motion: the random walk with infinitely small steps](05-Brownian%20Motion/01-brownian-motion.md)
2. [Brownian paths: scaling by root t, continuous everywhere, smooth nowhere](05-Brownian%20Motion/02-scaling-and-path-roughness.md)
3. [Quadratic variation: squared increments add up to t](05-Brownian%20Motion/03-quadratic-variation.md)
4. [Reflection principle: the maximum of Brownian motion and the chance of touching a level](05-Brownian%20Motion/04-reflection-principle-and-running-maximum.md)
5. [Brownian bridge: Brownian motion pinned at both ends](05-Brownian%20Motion/05-brownian-bridge.md)
6. [Brownian martingales: W, W squared minus t, and the exponential martingale](05-Brownian%20Motion/06-brownian-martingales-and-exponential-martingale.md)
7. [Geometric Brownian motion: a price whose log is Brownian](05-Brownian%20Motion/07-geometric-brownian-motion.md)
8. [Building Brownian motion: Levy's midpoint construction and Kolmogorov's continuity test](05-Brownian%20Motion/08-constructing-brownian-motion.md)
9. [Gaussian processes: random functions set by a covariance, and the Karhunen-Loeve series](05-Brownian%20Motion/09-gaussian-processes-and-karhunen-loeve.md)
10. [Donsker's theorem: the whole random-walk path converges to Brownian motion](05-Brownian%20Motion/10-donskers-invariance-principle.md)
11. [Brownian paths up close: Blumenthal's zero-one law and the law of the iterated logarithm](05-Brownian%20Motion/11-blumenthal-zero-one-law-and-the-brownian-lil.md)
12. [Levy's arcsine laws: why a fair game's lead rarely changes hands](05-Brownian%20Motion/12-levys-arcsine-laws.md)

[↑ Back to the shelves](#top)

<a name="s06"></a>

## 06 · Ito Calculus · 8 cards

*Integrating against Brownian motion, the chain rule with its extra term, and solving stochastic differential equations*

1. [The Ito integral: integrating a strategy against Brownian motion](06-Ito%20Calculus/01-ito-integral.md)
2. [Ito's lemma: the chain rule with a second-derivative term](06-Ito%20Calculus/02-itos-lemma.md)
3. [Ito's product rule: integration by parts with a covariation term](06-Ito%20Calculus/03-ito-product-rule.md)
4. [Stochastic differential equations: a drift, a noise size, and a solution path](06-Ito%20Calculus/04-stochastic-differential-equations.md)
5. [Mean reversion: the Ornstein-Uhlenbeck and Cox-Ingersoll-Ross processes](06-Ito%20Calculus/05-ornstein-uhlenbeck-and-cir-processes.md)
6. [Several Brownian motions: correlated noise and the multidimensional Ito formula](06-Ito%20Calculus/06-multidimensional-ito-and-correlation.md)
7. [When an SDE has one solution: Lipschitz and growth conditions](06-Ito%20Calculus/07-existence-and-uniqueness-for-sdes.md)
8. [The Stratonovich integral: the midpoint rule that keeps the ordinary chain rule](06-Ito%20Calculus/08-stratonovich-integral.md)

[↑ Back to the shelves](#top)

<a name="s07"></a>

## 07 · Changing Measure · 6 cards

*Reweighting probabilities so a drift disappears, and the theorems that make replication work*

1. [Changing the measure: a density that reweights every path](07-Changing%20Measure/01-change-of-measure-and-density-processes.md)
2. [Girsanov: removing a drift by changing the measure](07-Changing%20Measure/02-girsanov-theorem.md)
3. [Novikov: when the exponential martingale is a true martingale](07-Changing%20Measure/03-novikov-condition.md)
4. [Martingale representation: every Brownian martingale is an Ito integral](07-Changing%20Measure/04-martingale-representation-theorem.md)
5. [Change of numeraire: measuring value in shares, bonds or annuities](07-Changing%20Measure/05-change-of-numeraire.md)
6. [Feynman-Kac: an expectation of a diffusion solves a PDE](07-Changing%20Measure/06-feynman-kac-formula.md)

[↑ Back to the shelves](#top)

<a name="s08"></a>

## 08 · Generators, Densities and Simulation · 10 cards

*The operator that describes a diffusion, the equations its densities obey, and how to simulate it without fooling yourself*

1. [The generator: the drift-and-diffusion operator that summarises an SDE](08-Generators%2C%20Densities%20and%20Simulation/01-infinitesimal-generator.md)
2. [Kolmogorov backward equation: how an expectation depends on the starting point](08-Generators%2C%20Densities%20and%20Simulation/02-kolmogorov-backward-equation.md)
3. [Fokker-Planck: how the density of a diffusion evolves](08-Generators%2C%20Densities%20and%20Simulation/03-fokker-planck-forward-equation.md)
4. [Euler-Maruyama: stepping an SDE with Gaussian increments](08-Generators%2C%20Densities%20and%20Simulation/04-euler-maruyama-scheme.md)
5. [Milstein and the two kinds of error: path error and average error](08-Generators%2C%20Densities%20and%20Simulation/05-milstein-and-strong-weak-convergence.md)
6. [Exact simulation: when you can skip the time steps](08-Generators%2C%20Densities%20and%20Simulation/06-exact-simulation-of-gbm-and-ou.md)
7. [Optimal stopping: when to stop a process to maximise an expected reward](08-Generators%2C%20Densities%20and%20Simulation/07-optimal-stopping-and-snell-envelope.md)
8. [Brownian motion in d dimensions: recurrent in the plane, gone for good in space](08-Generators%2C%20Densities%20and%20Simulation/08-recurrence-and-transience-of-brownian-motion.md)
9. [The Dirichlet problem by Brownian motion: boundary values averaged over where the path exits](08-Generators%2C%20Densities%20and%20Simulation/09-brownian-motion-and-the-dirichlet-problem.md)
10. [One-dimensional diffusions: the scale function, the speed measure, and what happens at the edges](08-Generators%2C%20Densities%20and%20Simulation/10-scale-function-speed-measure-and-boundaries.md)

[↑ Back to the shelves](#top)

<a name="s09"></a>

## 09 · Beyond Brownian · 10 cards

*Jumps, control and filtering: the processes that finance and engineering need beyond the diffusion*

1. [Levy processes: stationary independent increments, with jumps allowed](09-Beyond%20Brownian/01-levy-processes.md)
2. [Jump diffusions: Ito's lemma with a jump term](09-Beyond%20Brownian/02-jump-diffusions.md)
3. [Stochastic control: choosing a policy as the noise unfolds](09-Beyond%20Brownian/03-stochastic-control-and-the-hjb-equation.md)
4. [Filtering: estimating a hidden state from noisy observations in continuous time](09-Beyond%20Brownian/04-filtering-and-the-kalman-bucy-filter.md)
5. [Semimartingales: the largest class you can integrate against](09-Beyond%20Brownian/05-semimartingales-in-outline.md)
6. [Rougher than Brownian: fractional Brownian motion and why rough volatility needs new tools](09-Beyond%20Brownian/06-rough-paths-and-fractional-brownian-motion-in-outline.md)
7. [Malliavin calculus in outline: differentiating a random variable with respect to the noise](09-Beyond%20Brownian/07-malliavin-calculus-in-outline.md)
8. [Backward SDEs in outline: equations solved from a known end value](09-Beyond%20Brownian/08-backward-sdes-in-outline.md)
9. [Stochastic PDEs in outline: the heat equation driven by space-time noise](09-Beyond%20Brownian/09-stochastic-pdes-in-outline.md)
10. [McKean-Vlasov equations in outline: particles that feel the crowd's average](09-Beyond%20Brownian/10-mckean-vlasov-and-mean-field-limits-in-outline.md)

[↑ Back to the shelves](#top)

<a name="s10"></a>

## 10 · Continuous Martingales · 6 cards

*Fair games in continuous time: their clock, the bounds on their peaks, why each is a Brownian motion on its own clock, and SDEs solved in law.*

1. [Continuous martingales and local martingales: fair games in continuous time, and fair only up to a stopping time](10-Continuous%20Martingales/01-continuous-martingales-and-local-martingales.md)
2. [Doob-Meyer: every submartingale is a martingale plus a rising trend, and the bracket of a martingale](10-Continuous%20Martingales/02-doob-meyer-decomposition.md)
3. [Burkholder-Davis-Gundy: the peak of a martingale is controlled by its clock](10-Continuous%20Martingales/03-burkholder-davis-gundy-inequalities.md)
4. [Levy's characterisation and Dubins-Schwarz: every continuous martingale is Brownian motion on its own clock](10-Continuous%20Martingales/04-levys-characterisation-and-dubins-schwarz.md)
5. [Local time and Tanaka's formula: Ito's rule for a function with a kink](10-Continuous%20Martingales/05-local-time-and-tanakas-formula.md)
6. [Weak solutions and the martingale problem: an SDE solved in law, not path by path](10-Continuous%20Martingales/06-weak-solutions-and-the-martingale-problem.md)

[↑ Back to the shelves](#top)

---

[← 10 · Measure and integration](../10-Measure%20and%20integration/README.md) · [All wings](../../SYLLABUS.md) · [12 · Financial mathematics →](../12-Financial%20mathematics/README.md)
