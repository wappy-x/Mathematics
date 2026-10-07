<a name="top"></a>

[Syllabus](../../SYLLABUS.md) → Differential equations and dynamics

# 08 · Differential equations and dynamics

Write down a rate law for a real situation, solve it by hand where a formula exists, step it on a computer where none does, and say whether the answer is trustworthy, stable, oscillating or chaotic. Carry the same toolkit into heat, waves and steady states, into discrete iteration, and into choosing the best path or control, ready for the stochastic and financial versions in wings 11 and 12.

12 shelves · **93 of 93 cards ready to read**

Click a shelf to jump to its cards, then click a card's title to read it.

| Shelf | Cards |
| --- | ---: |
| [01 · Rate Equations](#s01) | 9 |
| [02 · Existence, Uniqueness and Sensitivity](#s02) | 5 |
| [03 · Oscillators: Second-Order Linear Equations](#s03) | 9 |
| [04 · Systems and the Matrix Exponential](#s04) | 7 |
| [05 · Numerical Evolution](#s05) | 7 |
| [06 · Nonlinear Dynamics in the Plane](#s06) | 10 |
| [07 · Series Solutions and Boundary Problems](#s07) | 10 |
| [08 · Laplace Transforms for Initial-Value Problems](#s08) | 7 |
| [09 · Fourier Series](#s09) | 5 |
| [10 · The Classical PDEs](#s10) | 10 |
| [11 · Discrete Dynamics and Chaos](#s11) | 6 |
| [12 · Calculus of Variations and Optimal Control](#s12) | 8 |

<a name="s01"></a>

## 01 · Rate Equations · 9 cards

*Reading an ODE and an initial value problem, slope fields and the phase line, separable and linear first-order equations, growth, decay and cooling, tank mixing, logistic growth, exact equations, Bernoulli and Riccati substitutions.*

1. [A differential equation: a rule for the rate, and the starting value that picks one curve](01-Rate%20Equations/01-what-a-differential-equation-says.md)
2. [Slope fields and the phase line: sketch every solution without solving anything](01-Rate%20Equations/02-slope-fields-and-the-phase-line.md)
3. [Separable equations: put each variable on its own side and integrate both](01-Rate%20Equations/03-separable-equations.md)
4. [Growth, decay and cooling: when the rate is proportional to the amount, the answer is an exponential](01-Rate%20Equations/04-exponential-growth-decay-and-cooling.md)
5. [The integrating factor: multiply by the right function and the left side becomes one derivative](01-Rate%20Equations/05-integrating-factor.md)
6. [Mixing tanks: rate in minus rate out is a differential equation, and units keep you honest](01-Rate%20Equations/06-mixing-tanks-and-compartments.md)
7. [Logistic growth: a ceiling bends the exponential into an S-curve](01-Rate%20Equations/07-logistic-growth.md)
8. [Exact equations: when the equation is the derivative of a hidden function, find that function](01-Rate%20Equations/08-exact-equations.md)
9. [Bernoulli and Riccati equations: one substitution turns a nonlinear equation into a linear one](01-Rate%20Equations/09-bernoulli-and-riccati-substitutions.md)

[↑ Back to the shelves](#top)

<a name="s02"></a>

## 02 · Existence, Uniqueness and Sensitivity · 5 cards

*Picard iteration, the Lipschitz condition and the Picard-Lindelof theorem, non-uniqueness, finite-time blow-up and maximal intervals, Gronwall's inequality and continuous dependence, the flow map. Plain register; the contraction argument is done in outline on the card, the metric-space machinery is not built here.*

1. [Picard iteration: turn the equation into an integral, then keep feeding the guess back in](02-Existence%2C%20Uniqueness%20and%20Sensitivity/01-picard-iteration.md)
2. [The Picard-Lindelof theorem: a speed limit on the rate guarantees exactly one solution](02-Existence%2C%20Uniqueness%20and%20Sensitivity/02-lipschitz-and-the-picard-lindelof-theorem.md)
3. [Blow-up: a smooth equation can send its solution to infinity in finite time](02-Existence%2C%20Uniqueness%20and%20Sensitivity/03-blow-up-and-the-life-span-of-a-solution.md)
4. [Gronwall's inequality: nearby starts stay nearby for a while, and here is the bound](02-Existence%2C%20Uniqueness%20and%20Sensitivity/04-gronwall-and-continuous-dependence.md)
5. [The flow: a rule that moves every starting point forward by t, and running it twice is running it longer](02-Existence%2C%20Uniqueness%20and%20Sensitivity/05-the-flow-of-an-equation.md)

[↑ Back to the shelves](#top)

<a name="s03"></a>

## 03 · Oscillators: Second-Order Linear Equations · 9 cards

*Superposition and the two-dimensional solution space, the characteristic equation with real, repeated and complex roots, damping regimes, the Wronskian and reduction of order, forcing by undetermined coefficients, resonance and beats, variation of parameters, the RLC circuit, the Cauchy-Euler equation.*

1. [Superposition: for a linear equation, solutions add and scale, so two of them are enough](03-Oscillators%20-%20Second-Order%20Linear%20Equations/01-superposition-and-the-shape-of-linear-solutions.md)
2. [The characteristic equation: guess an exponential and the differential equation becomes a quadratic](03-Oscillators%20-%20Second-Order%20Linear%20Equations/02-the-characteristic-equation.md)
3. [Complex roots: the exponential of an imaginary number is a rotation, so the solution rings down](03-Oscillators%20-%20Second-Order%20Linear%20Equations/03-complex-roots-and-damped-oscillation.md)
4. [The Wronskian: a determinant that says two solutions are genuinely different, and how to find the second from the first](03-Oscillators%20-%20Second-Order%20Linear%20Equations/04-wronskian-and-reduction-of-order.md)
5. [Undetermined coefficients: for simple forcing, guess a solution of the same shape and solve for the constants](03-Oscillators%20-%20Second-Order%20Linear%20Equations/05-undetermined-coefficients.md)
6. [Resonance: push at the natural frequency and the swing grows, push nearby and it beats](03-Oscillators%20-%20Second-Order%20Linear%20Equations/06-resonance-and-beats.md)
7. [Variation of parameters: let the constants vary and any forcing term can be handled](03-Oscillators%20-%20Second-Order%20Linear%20Equations/07-variation-of-parameters.md)
8. [The RLC circuit: the same equation as a spring, with charge in the place of position](03-Oscillators%20-%20Second-Order%20Linear%20Equations/08-the-rlc-circuit-and-the-spring.md)
9. [The Cauchy-Euler equation: coefficients that scale with x are solved by powers of x](03-Oscillators%20-%20Second-Order%20Linear%20Equations/09-the-cauchy-euler-equation.md)

[↑ Back to the shelves](#top)

<a name="s04"></a>

## 04 · Systems and the Matrix Exponential · 7 cards

*Reducing to a first-order system, the eigenvalue method, complex eigenvalues and spirals, the matrix exponential including the defective case, the trace-determinant classification of linear equilibria, forced systems by variation of constants, coupled oscillators and normal modes.*

1. [From one equation to a system: any higher-order equation is several first-order ones in a vector](04-Systems%20and%20the%20Matrix%20Exponential/01-from-one-equation-to-a-system.md)
2. [The eigenvalue method: along an eigenvector the system only stretches, so each mode is a plain exponential](04-Systems%20and%20the%20Matrix%20Exponential/02-the-eigenvalue-method.md)
3. [Complex eigenvalues: rotation plus growth or decay, so the state spirals](04-Systems%20and%20the%20Matrix%20Exponential/03-complex-eigenvalues-and-spirals.md)
4. [The matrix exponential: e^(At) moves any starting state forward, even when eigenvectors run out](04-Systems%20and%20the%20Matrix%20Exponential/04-the-matrix-exponential.md)
5. [Trace and determinant: two numbers sort every planar linear system into node, saddle, spiral or centre](04-Systems%20and%20the%20Matrix%20Exponential/05-classifying-equilibria-by-trace-and-determinant.md)
6. [Forced systems: the response is the start propagated forward plus every past input propagated to now](04-Systems%20and%20the%20Matrix%20Exponential/06-forced-systems-and-variation-of-constants.md)
7. [Normal modes: two connected springs vibrate in a few pure patterns, and every motion mixes them](04-Systems%20and%20the%20Matrix%20Exponential/07-coupled-oscillators-and-normal-modes.md)

[↑ Back to the shelves](#top)

<a name="s05"></a>

## 05 · Numerical Evolution · 7 cards

*Euler's method, local and global error and the order of a method, midpoint and Heun, classical RK4, adaptive step size with embedded pairs, stiffness and backward Euler with the trapezoidal rule, symplectic steps for oscillators. Multistep and production solver design are wing 16.*

1. [Euler's method: step forward along the current slope, and the smaller the step the closer you land](05-Numerical%20Evolution/01-eulers-method.md)
2. [Order of a method: the error of one step, how the errors pile up, and the number that says how fast they shrink](05-Numerical%20Evolution/02-local-and-global-error-and-order.md)
3. [Midpoint and Heun: sample the slope twice per step and the error shrinks four times faster](05-Numerical%20Evolution/03-midpoint-and-heun-methods.md)
4. [Runge-Kutta four: four slopes per step, weighted 1-2-2-1, and the error shrinks sixteen-fold per halving](05-Numerical%20Evolution/04-runge-kutta-four.md)
5. [Adaptive steps: two estimates per step disagree by about the error, so let the solver pick its own step](05-Numerical%20Evolution/05-adaptive-step-size.md)
6. [Stiff equations: when fast and slow parts coexist, step from the destination's slope instead](05-Numerical%20Evolution/06-stiff-equations-and-backward-euler.md)
7. [Symplectic steps: for frictionless motion, a stepper that keeps energy bounded for a million steps](05-Numerical%20Evolution/07-symplectic-steps-for-oscillators.md)

[↑ Back to the shelves](#top)

<a name="s06"></a>

## 06 · Nonlinear Dynamics in the Plane · 10 cards

*Phase portraits and nullclines, linearisation and the Jacobian, the nonlinear pendulum, Lyapunov functions, LaSalle's principle, predator-prey cycles, the SIR epidemic, limit cycles and van der Pol, Poincare-Bendixson and Bendixson's criterion, bifurcations of equilibria.*

1. [Phase portraits and nullclines: draw where each variable stops changing and the arrows fill themselves in](06-Nonlinear%20Dynamics%20in%20the%20Plane/01-phase-portraits-and-nullclines.md)
2. [Linearisation: near an equilibrium the system looks like its matrix of slopes, and usually that is enough](06-Nonlinear%20Dynamics%20in%20the%20Plane/02-linearisation-and-the-jacobian.md)
3. [The pendulum: swinging and spinning over live in one picture, separated by the energy of standing on end](06-Nonlinear%20Dynamics%20in%20the%20Plane/03-the-nonlinear-pendulum.md)
4. [Lyapunov functions: find something that only ever decreases and you have proved the system settles, without solving it](06-Nonlinear%20Dynamics%20in%20the%20Plane/04-lyapunov-functions.md)
5. [LaSalle's principle: when the energy only pauses on a thin set, solutions still end where they can stay on it](06-Nonlinear%20Dynamics%20in%20the%20Plane/05-lasalle-and-the-damped-pendulum.md)
6. [Predator and prey: two populations chase each other in cycles that never die out](06-Nonlinear%20Dynamics%20in%20the%20Plane/06-predator-prey.md)
7. [The SIR model: an outbreak grows while each case infects more than one, and burns out before everyone is ill](06-Nonlinear%20Dynamics%20in%20the%20Plane/07-the-sir-epidemic-model.md)
8. [Limit cycles: a self-sustaining rhythm that nearby states spiral onto, unlike the fragile circles of a centre](06-Nonlinear%20Dynamics%20in%20the%20Plane/08-limit-cycles-and-van-der-pol.md)
9. [Poincare-Bendixson: in the plane a trapped path that cannot rest must loop, and a divergence test rules loops out](06-Nonlinear%20Dynamics%20in%20the%20Plane/09-poincare-bendixson-and-bendixsons-criterion.md)
10. [Bifurcations: turn a dial slowly and a resting state can vanish, swap stability or split in two](06-Nonlinear%20Dynamics%20in%20the%20Plane/10-bifurcations-of-equilibria.md)

[↑ Back to the shelves](#top)

<a name="s07"></a>

## 07 · Series Solutions and Boundary Problems · 10 cards

*Power series at ordinary points, Frobenius at regular singular points, Bessel and Legendre, two-point boundary value problems, shooting, finite differences, eigenvalue problems, Sturm-Liouville orthogonality, Green's functions.*

1. [Series solutions: assume the answer is a polynomial that never stops and match the coefficients](07-Series%20Solutions%20and%20Boundary%20Problems/01-power-series-at-an-ordinary-point.md)
2. [Frobenius: at a mild singular point, let the series start at a fractional or negative power](07-Series%20Solutions%20and%20Boundary%20Problems/02-frobenius-and-regular-singular-points.md)
3. [Bessel's equation: the drum's answer is a new function whose zeros set the drum's notes](07-Series%20Solutions%20and%20Boundary%20Problems/03-bessels-equation-and-the-drum.md)
4. [Legendre's equation: for whole-number parameters the series stops, giving a family of polynomials](07-Series%20Solutions%20and%20Boundary%20Problems/04-legendre-polynomials.md)
5. [Boundary value problems: conditions at both ends instead of one start, so there may be one answer, none or infinitely many](07-Series%20Solutions%20and%20Boundary%20Problems/05-two-point-boundary-value-problems.md)
6. [Shooting: guess the missing starting slope, integrate forward, see how far you miss, and correct](07-Series%20Solutions%20and%20Boundary%20Problems/06-the-shooting-method.md)
7. [Finite differences: replace the derivatives by differences on a grid and solve one linear system](07-Series%20Solutions%20and%20Boundary%20Problems/07-finite-differences-for-boundary-problems.md)
8. [Eigenvalue problems: only special parameter values allow a nonzero solution, and those are the natural modes](07-Series%20Solutions%20and%20Boundary%20Problems/08-eigenvalues-and-eigenfunctions.md)
9. [Sturm-Liouville: the standard form whose modes are real, perpendicular under a weight, and rich enough to expand functions in](07-Series%20Solutions%20and%20Boundary%20Problems/09-sturm-liouville-and-orthogonality.md)
10. [Green's function: the response to a single point load, from which every load's response is a sum](07-Series%20Solutions%20and%20Boundary%20Problems/10-greens-function-for-a-boundary-problem.md)

[↑ Back to the shelves](#top)

<a name="s08"></a>

## 08 · Laplace Transforms for Initial-Value Problems · 7 cards

*The one-sided Laplace transform and its table, transforms of derivatives, inversion by partial fractions, the full round trip on an initial value problem, step functions and delays, impulses and the delta function, convolution and the impulse response. Transfer functions proper are wing 13.*

1. [The Laplace transform: multiply by a decaying exponential and integrate, and calculus turns into algebra](08-Laplace%20Transforms%20for%20Initial-Value%20Problems/01-the-laplace-transform.md)
2. [Transforming a derivative: multiply by s and the initial value walks in on its own](08-Laplace%20Transforms%20for%20Initial-Value%20Problems/02-transforms-of-derivatives.md)
3. [Inverting: split the transformed answer into table entries and read the solution off](08-Laplace%20Transforms%20for%20Initial-Value%20Problems/03-inverting-by-partial-fractions.md)
4. [The round trip: transform, solve the algebra, invert, and the forced oscillator falls out in one pass](08-Laplace%20Transforms%20for%20Initial-Value%20Problems/04-solving-an-initial-value-problem-by-transform.md)
5. [Step functions: a switch thrown at time a is e^(-as) in transform space](08-Laplace%20Transforms%20for%20Initial-Value%20Problems/05-step-functions-and-delays.md)
6. [Impulses: a hammer blow is a narrow tall pulse, its limit is the delta, and its transform is e^(-as)](08-Laplace%20Transforms%20for%20Initial-Value%20Problems/06-impulses-and-the-delta-function.md)
7. [Convolution: the response to any input is the impulse response blended with that input](08-Laplace%20Transforms%20for%20Initial-Value%20Problems/07-convolution-and-the-impulse-response.md)

[↑ Back to the shelves](#top)

<a name="s09"></a>

## 09 · Fourier Series · 5 cards

*Sines and cosines as an orthogonal basis on a period, coefficient formulas, convergence at jumps and the Gibbs overshoot, Parseval's identity, half-range sine and cosine series for boundary conditions, and the complex form with the Fourier transform introduced in outline as the bridge to wings 09, 12, 13 and 20.*

1. [Fourier series: any repeating signal is a sum of sines and cosines, and orthogonality hands you each coefficient](09-Fourier%20Series/01-fourier-series-and-orthogonality.md)
2. [Convergence: the series lands on the function where it is smooth, on the midpoint at a jump, and overshoots by 9% beside it](09-Fourier%20Series/02-convergence-jumps-and-gibbs.md)
3. [Parseval's identity: the energy of a signal equals the energy of its coefficients, so nothing is lost](09-Fourier%20Series/03-parsevals-identity.md)
4. [Half-range series: extend a function on \[0, L\] as odd or even so the series matches fixed or insulated ends](09-Fourier%20Series/04-half-range-sine-and-cosine-series.md)
5. [The complex form: one coefficient c\_n e^(inx) per frequency, and letting the period grow gives the Fourier transform](09-Fourier%20Series/05-complex-fourier-series-and-the-transform-in-outline.md)

[↑ Back to the shelves](#top)

<a name="s10"></a>

## 10 · The Classical PDEs · 10 cards

*What a PDE says and the three types, transport and characteristics, the heat equation and its separation, the wave equation with d'Alembert and standing waves, Laplace's equation and harmonic functions, the rectangle by separation, finite differences for heat, the heat kernel on a line. Weak solutions and rigorous theory are wing 19.*

1. [A partial differential equation: rates in more than one direction, and three families with three personalities](10-The%20Classical%20PDEs/01-what-a-pde-says.md)
2. [The transport equation: a shape carried along unchanged, and the lines along which a PDE is really an ODE](10-The%20Classical%20PDEs/02-the-transport-equation-and-characteristics.md)
3. [The heat equation: each point drifts toward the average of its neighbours, so bumps flatten and never grow](10-The%20Classical%20PDEs/03-the-heat-equation.md)
4. [Separation of variables: guess a product of a space shape and a time factor, and the PDE splits into two ODEs](10-The%20Classical%20PDEs/04-separation-of-variables-for-the-heat-equation.md)
5. [The wave equation: a shape splits into two half-copies travelling opposite ways at speed c](10-The%20Classical%20PDEs/05-the-wave-equation-and-dalemberts-formula.md)
6. [Standing waves: a fixed string vibrates in harmonics, and the pluck shape decides how loud each one is](10-The%20Classical%20PDEs/06-standing-waves-on-a-string.md)
7. [Laplace's equation: what is left when everything has settled, and each point is the average of its neighbours](10-The%20Classical%20PDEs/07-laplaces-equation-and-harmonic-functions.md)
8. [Laplace on a rectangle: separate into sines one way and sinh the other, one hot edge at a time](10-The%20Classical%20PDEs/08-laplace-on-a-rectangle.md)
9. [Stepping the heat equation on a grid: the explicit scheme works only when the time step is small enough](10-The%20Classical%20PDEs/09-finite-differences-for-the-heat-equation.md)
10. [The heat kernel: on an endless line a point of heat becomes a bell curve, and any start is a blend of bells](10-The%20Classical%20PDEs/10-the-heat-kernel.md)

[↑ Back to the shelves](#top)

<a name="s11"></a>

## 11 · Discrete Dynamics and Chaos · 6 cards

*Iteration and cobweb plots, stability of fixed points of a map, the logistic map and period doubling, chaos and the Lyapunov exponent, the doubling map and symbolic dynamics, the Lorenz system and strange attractors. Fractal geometry is wing 05, Julia and Mandelbrot sets wing 07, ergodic theory wing 10, chaos in data wing 14.*

1. [Iteration: apply one rule over and over, and the cobweb staircase shows where it goes](11-Discrete%20Dynamics%20and%20Chaos/01-iteration-and-cobweb-plots.md)
2. [Fixed points of a map: a slope smaller than one in size pulls nearby points in, larger pushes them away](11-Discrete%20Dynamics%20and%20Chaos/02-fixed-points-of-a-map.md)
3. [The logistic map: turn one dial and a settling population starts alternating, then doubles again and again toward chaos](11-Discrete%20Dynamics%20and%20Chaos/03-the-logistic-map-and-period-doubling.md)
4. [The Lyapunov exponent: how fast two nearly identical starts drift apart, and positive means chaos](11-Discrete%20Dynamics%20and%20Chaos/04-chaos-and-the-lyapunov-exponent.md)
5. [The doubling map: doubling and dropping the whole part shifts the binary digits, which is why chaos can be proved](11-Discrete%20Dynamics%20and%20Chaos/05-the-doubling-map-and-symbolic-dynamics.md)
6. [The Lorenz system: three weather equations that never settle and never repeat, on a butterfly no thicker than a sheet](11-Discrete%20Dynamics%20and%20Chaos/06-the-lorenz-system-and-strange-attractors.md)

[↑ Back to the shelves](#top)

<a name="s12"></a>

## 12 · Calculus of Variations and Optimal Control · 8 cards

*Functionals and the Euler-Lagrange equation, the brachistochrone and the Beltrami identity, constrained paths and the hanging chain, Lagrangian mechanics, Hamilton's equations, Pontryagin's principle and bang-bang control, dynamic programming and the Bellman equation, the HJB equation with the linear-quadratic regulator. Stochastic control, Merton and execution models are wings 11 and 12; MDPs and value iteration wing 15.*

1. [The Euler-Lagrange equation: to find the best curve, nudge it, and the nudge must change the cost by nothing](12-Calculus%20of%20Variations%20and%20Optimal%20Control/01-functionals-and-the-euler-lagrange-equation.md)
2. [The brachistochrone: the fastest slide is a cycloid, found with a shortcut that works when the cost ignores the horizontal](12-Calculus%20of%20Variations%20and%20Optimal%20Control/02-the-brachistochrone-and-the-beltrami-identity.md)
3. [Paths with a budget: a Lagrange multiplier joins the constraint to the cost, and a chain hangs as a cosh](12-Calculus%20of%20Variations%20and%20Optimal%20Control/03-constrained-paths-and-the-hanging-chain.md)
4. [Lagrangian mechanics: nature makes kinetic minus potential energy stationary, and the equations of motion fall out](12-Calculus%20of%20Variations%20and%20Optimal%20Control/04-lagrangian-mechanics.md)
5. [Hamilton's equations: trade velocity for momentum and the motion becomes a pair of first-order equations that conserve energy](12-Calculus%20of%20Variations%20and%20Optimal%20Control/05-hamiltons-equations.md)
6. [Pontryagin's principle: the best control maximises a Hamiltonian at every instant, and often that means full throttle or full brake](12-Calculus%20of%20Variations%20and%20Optimal%20Control/06-pontryagins-principle-and-bang-bang-control.md)
7. [Dynamic programming: any tail of a best plan is itself a best plan, so solve from the finish backwards](12-Calculus%20of%20Variations%20and%20Optimal%20Control/07-dynamic-programming-and-the-bellman-equation.md)
8. [The HJB equation: dynamic programming in continuous time, and for linear motion with squared costs the best control is a feedback gain](12-Calculus%20of%20Variations%20and%20Optimal%20Control/08-the-hjb-equation-and-the-linear-quadratic-regulator.md)

[↑ Back to the shelves](#top)

---

[← 07 · Complex analysis](../07-Complex%20analysis/README.md) · [All wings](../../SYLLABUS.md) · [09 · Probability and statistics →](../09-Probability%20and%20statistics/README.md)
