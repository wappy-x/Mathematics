<a name="top"></a>

[Syllabus](../../SYLLABUS.md) → Engineering mathematics

# 13 · Engineering mathematics

Turn a physical system into equations, choose the scales that matter, transform it, and decide whether it is stable. Design and tune a controller, process a sampled signal, estimate hidden states, and read the equations of circuits, structures, fluids, heat and quantum mechanics well enough to follow an engineering text.

10 shelves · **86 of 86 cards ready to read**

Click a shelf to jump to its cards, then click a card's title to read it.

| Shelf | Cards |
| --- | ---: |
| [01 · Units and Modelling](#s01) | 7 |
| [02 · Linear Systems and Transforms](#s02) | 9 |
| [03 · Feedback Control](#s03) | 10 |
| [04 · State Space and Optimal Control](#s04) | 10 |
| [05 · Signals](#s05) | 10 |
| [06 · Circuits and Electromagnetism](#s06) | 9 |
| [07 · Mechanics and Structures](#s07) | 9 |
| [08 · Fluids and Heat](#s08) | 9 |
| [09 · Quantum Mechanics in Outline](#s09) | 8 |
| [10 · Robustness and Adaptation](#s10) | 5 |

<a name="s01"></a>

## 01 · Units and Modelling · 7 cards

*Units, dimensionless groups, scaling, small parameters and how measurement error spreads*

1. [Units and dimensions: seven base quantities every formula has to balance](01-Units%20and%20Modelling/01-si-units-and-dimensional-homogeneity.md)
2. [Buckingham Pi: count the variables, subtract the dimensions, get the groups](01-Units%20and%20Modelling/02-dimensional-analysis-and-buckingham-pi.md)
3. [Nondimensionalisation: choose natural scales and the small parameter appears](01-Units%20and%20Modelling/03-scaling-and-nondimensionalisation.md)
4. [Similarity: when a small model in a tunnel really predicts the full size thing](01-Units%20and%20Modelling/04-similarity-and-model-testing.md)
5. [Regular perturbation: solve the easy problem, then correct in powers of a small number](01-Units%20and%20Modelling/05-regular-perturbation.md)
6. [Boundary layers: when the small term cannot be dropped near a wall](01-Units%20and%20Modelling/06-boundary-layers-and-singular-perturbation.md)
7. [Error propagation: measurement slop in the inputs becomes slop in the answer](01-Units%20and%20Modelling/07-error-propagation-and-sensitivity.md)

[↑ Back to the shelves](#top)

<a name="s02"></a>

## 02 · Linear Systems and Transforms · 9 cards

*One input and one output: impulse response, transfer function, poles, frequency response and sampling*

1. [Linear and time-invariant: superposition plus a fixed clock gives convolution](02-Linear%20Systems%20and%20Transforms/01-linear-time-invariant-systems-and-convolution.md)
2. [Transfer functions: the Laplace transform turns a differential equation into a ratio](02-Linear%20Systems%20and%20Transforms/02-impulse-response-and-transfer-functions.md)
3. [Poles and zeros: where a response decays, rings, or runs away](02-Linear%20Systems%20and%20Transforms/03-poles-zeros-and-stability.md)
4. [Bode plots: how much a system magnifies and delays each frequency](02-Linear%20Systems%20and%20Transforms/04-frequency-response-and-bode-plots.md)
5. [Final value and bandwidth: where a response settles and how fast it keeps up](02-Linear%20Systems%20and%20Transforms/05-final-value-theorem-and-steady-gain.md)
6. [Damping ratio and natural frequency: two numbers fix a second-order response](02-Linear%20Systems%20and%20Transforms/06-second-order-systems-damping-and-natural-frequency.md)
7. [Step response specs: rise time, overshoot, settling time and steady error](02-Linear%20Systems%20and%20Transforms/07-step-response-specifications.md)
8. [The z-transform: difference equations become algebra in the z-plane](02-Linear%20Systems%20and%20Transforms/08-z-transform-and-discrete-time-systems.md)
9. [Discretising a design: hold the input flat, or bend the frequency axis](02-Linear%20Systems%20and%20Transforms/09-zero-order-hold-and-tustin-discretisation.md)

[↑ Back to the shelves](#top)

<a name="s03"></a>

## 03 · Feedback Control · 10 cards

*Closing the loop: what feedback buys, when it goes unstable, and how to tune and shape it*

1. [Feedback: the closed loop is the open loop over one plus the open loop](03-Feedback%20Control/01-feedback-and-closed-loop-transfer-functions.md)
2. [Sensitivity functions: one loop has four paths and all four matter](03-Feedback%20Control/02-sensitivity-and-the-gang-of-four.md)
3. [Steady-state error: an integrator is what kills a permanent offset](03-Feedback%20Control/03-steady-state-error-and-system-type.md)
4. [Routh-Hurwitz: decide whether every root decays without finding a single root](03-Feedback%20Control/04-routh-hurwitz-criterion.md)
5. [Root locus: watch the closed-loop poles travel as you turn the gain up](03-Feedback%20Control/05-root-locus.md)
6. [Nyquist and margins: encirclements decide stability, margins say by how much](03-Feedback%20Control/06-nyquist-criterion-and-stability-margins.md)
7. [PID control: answer the error, its history and its trend](03-Feedback%20Control/07-pid-control-and-tuning.md)
8. [PID in practice: saturation, noisy derivatives, nested loops and feedforward](03-Feedback%20Control/08-pid-on-real-hardware.md)
9. [Loop shaping: buy phase with a lead, buy accuracy with a lag](03-Feedback%20Control/09-lead-lag-compensation-and-loop-shaping.md)
10. [Time delays: they eat phase margin, and a predictor can hide a known one](03-Feedback%20Control/10-smith-predictor-and-time-delays.md)

[↑ Back to the shelves](#top)

<a name="s04"></a>

## 04 · State Space and Optimal Control · 10 cards

*Many states at once: simulate, test what you can steer and see, place poles, optimise and estimate*

1. [State space: a list of internal numbers that steps forward, pushed by the input](04-State%20Space%20and%20Optimal%20Control/01-state-space-models-and-the-matrix-exponential.md)
2. [Linearisation: near a chosen operating point a curved model becomes a straight one](04-State%20Space%20and%20Optimal%20Control/02-linearisation-about-an-equilibrium.md)
3. [Can you steer every state, and can you see every state](04-State%20Space%20and%20Optimal%20Control/03-controllability-and-observability.md)
4. [Pole placement: if you can steer it, you can choose its response speeds](04-State%20Space%20and%20Optimal%20Control/04-pole-placement-and-observers.md)
5. [Stability of a state-space model: eigenvalue tests and the energy that certifies them](04-State%20Space%20and%20Optimal%20Control/05-hurwitz-schur-and-lyapunov-stability.md)
6. [The LQR: choose feedback by pricing error against control effort](04-State%20Space%20and%20Optimal%20Control/06-linear-quadratic-regulator.md)
7. [The Kalman filter: predict forward, then correct by the measurement's surprise](04-State%20Space%20and%20Optimal%20Control/07-kalman-filter.md)
8. [Filtering a nonlinear plant: relinearise each step, or push sample points through](04-State%20Space%20and%20Optimal%20Control/08-extended-kalman-filter-and-nonlinear-estimation.md)
9. [LQG: design regulator and estimator apart, then bolt them together](04-State%20Space%20and%20Optimal%20Control/09-lqg-and-the-separation-principle.md)
10. [Predictive control: plan a whole future, use the first move, replan next tick](04-State%20Space%20and%20Optimal%20Control/10-model-predictive-control.md)

[↑ Back to the shelves](#top)

<a name="s05"></a>

## 05 · Signals · 10 cards

*Sampled data: spectra, windows, filters, rate changes, spectral estimates and time-frequency pictures*

1. [Sampling: measure faster than twice the top frequency or fast becomes slow](05-Signals/01-sampling-and-the-nyquist-theorem.md)
2. [The DFT and the FFT: a block of samples becomes a list of frequencies](05-Signals/02-discrete-fourier-transform-and-the-fft.md)
3. [Windows: a recording has to stop, so energy leaks between frequencies](05-Signals/03-windows-and-spectral-leakage.md)
4. [Digital filters: weight the last few inputs, or feed the output back](05-Signals/04-digital-filters-fir-and-iir.md)
5. [Changing rate: filter then drop samples, or pad with zeros then smooth](05-Signals/05-resampling-decimation-and-interpolation.md)
6. [Spectral estimation: the plain periodogram is noisy, so taper and average](05-Signals/06-spectral-estimation-and-periodograms.md)
7. [Wiener and LMS: the best linear guess, then learning it sample by sample](05-Signals/07-adaptive-and-optimal-filters.md)
8. [Wavelets: a coarse picture plus the detail you left out at every scale](05-Signals/08-wavelets-and-multiresolution.md)
9. [Spectrograms: one spectrum per slice of time, and the blur you cannot avoid](05-Signals/09-short-time-fourier-and-spectrograms.md)
10. [Compressed sensing: few measurements suffice when the signal is mostly zeros](05-Signals/10-compressed-sensing-in-outline.md)

[↑ Back to the shelves](#top)

<a name="s06"></a>

## 06 · Circuits and Electromagnetism · 9 cards

*Circuits solved as algebra, then the four field equations underneath them*

1. [Kirchhoff's laws: charge balances at a node, voltage sums to zero round a loop](06-Circuits%20and%20Electromagnetism/01-kirchhoffs-laws-and-equivalent-circuits.md)
2. [Phasors: steady AC becomes complex arithmetic, and impedance replaces resistance](06-Circuits%20and%20Electromagnetism/02-phasors-and-impedance.md)
3. [RLC resonance: one frequency the circuit answers loudest, and how sharp the peak is](06-Circuits%20and%20Electromagnetism/03-rlc-circuits-and-resonance.md)
4. [Electric fields: Coulomb's law, flux through a closed surface, voltage as potential](06-Circuits%20and%20Electromagnetism/04-electrostatics-gauss-and-potential.md)
5. [Magnetic fields: currents make them, moving charges feel them, change induces voltage](06-Circuits%20and%20Electromagnetism/05-magnetism-and-faradays-law.md)
6. [Transformers: two coils sharing flux trade voltage against current](06-Circuits%20and%20Electromagnetism/06-transformers-and-mutual-inductance.md)
7. [Maxwell's equations: four statements holding all of classical electromagnetism](06-Circuits%20and%20Electromagnetism/07-maxwells-equations.md)
8. [Electromagnetic waves: the two curl equations feed each other and light falls out](06-Circuits%20and%20Electromagnetism/08-electromagnetic-waves.md)
9. [AC power: real, reactive and apparent, and why the grid uses three phases](06-Circuits%20and%20Electromagnetism/09-power-and-three-phase.md)

[↑ Back to the shelves](#top)

<a name="s07"></a>

## 07 · Mechanics and Structures · 9 cards

*Forces, rotation, energy methods, ringing modes, and what makes a member bend or buckle*

1. [Newton's laws: force sets acceleration, and work becomes energy](07-Mechanics%20and%20Structures/01-newtons-laws-work-and-energy.md)
2. [Rotation: moment of inertia is the mass that resists being spun](07-Mechanics%20and%20Structures/02-rigid-body-rotation-and-moment-of-inertia.md)
3. [Precession: push a spinning wheel sideways and it turns at right angles](07-Mechanics%20and%20Structures/03-gyroscopes-and-precession.md)
4. [Lagrangian and Hamiltonian mechanics: write the energies, get the equations](07-Mechanics%20and%20Structures/04-lagrangian-and-hamiltonian-mechanics-for-engineers.md)
5. [Equations of motion of a vehicle: six freedoms and the small-disturbance split](07-Mechanics%20and%20Structures/05-vehicle-equations-of-motion.md)
6. [Vibration modes: a structure rings in a few shapes at a few frequencies](07-Mechanics%20and%20Structures/06-vibration-modes-and-resonance.md)
7. [Stress, strain and bending: how a beam carries load and how far it sags](07-Mechanics%20and%20Structures/07-stress-strain-and-beam-bending.md)
8. [Buckling: a slender column bends away long before it is crushed](07-Mechanics%20and%20Structures/08-buckling-and-stability.md)
9. [Orbits: inverse-square gravity gives conic sections and Kepler's three laws](07-Mechanics%20and%20Structures/09-orbital-mechanics-and-the-kepler-problem.md)

[↑ Back to the shelves](#top)

<a name="s08"></a>

## 08 · Fluids and Heat · 9 cards

*Flow and heat as conservation laws, with the dimensionless numbers that decide the behaviour*

1. [Continuity and Bernoulli: what goes in comes out, and pressure trades against speed](08-Fluids%20and%20Heat/01-continuity-and-bernoulli.md)
2. [Viscosity: friction inside the fluid, and the pressure a pipe costs](08-Fluids%20and%20Heat/02-viscosity-and-pipe-flow.md)
3. [Navier-Stokes: Newton's law for a fluid parcel, and the number that says which term wins](08-Fluids%20and%20Heat/03-navier-stokes-and-the-reynolds-number.md)
4. [Lift and drag: circulation lifts, the thin wall layer drags, and stall ends both](08-Fluids%20and%20Heat/04-lift-drag-and-boundary-layers.md)
5. [Fourier's law: heat runs down a temperature gradient, and the heat equation follows](08-Fluids%20and%20Heat/05-heat-conduction-and-fouriers-law.md)
6. [Convection and radiation: the other two ways heat leaves a surface](08-Fluids%20and%20Heat/06-convection-and-radiation.md)
7. [The thermodynamic laws: energy is conserved and entropy only grows](08-Fluids%20and%20Heat/07-thermodynamic-laws-and-entropy.md)
8. [Heat engines: the best efficiency anything between two temperatures can reach](08-Fluids%20and%20Heat/08-heat-engines-and-carnot-efficiency.md)
9. [Finite elements: cut the shape into pieces and solve one stiffness matrix](08-Fluids%20and%20Heat/09-finite-element-method-in-outline.md)

[↑ Back to the shelves](#top)

<a name="s09"></a>

## 09 · Quantum Mechanics in Outline · 8 cards

*Enough quantum mechanics to read the equations: states, levels, uncertainty, spin and symmetry*

1. [Waves on strings and drums: standing patterns and the frequencies they pick](09-Quantum%20Mechanics%20in%20Outline/01-wave-equation-for-strings-and-membranes.md)
2. [States as vectors: operators for observables, eigenvalues for the outcomes](09-Quantum%20Mechanics%20in%20Outline/02-state-vectors-operators-and-measurement.md)
3. [Schrodinger's equation: a wave equation whose standing modes are energy levels](09-Quantum%20Mechanics%20in%20Outline/03-schrodinger-equation-and-the-particle-in-a-box.md)
4. [The quantum oscillator: evenly spaced levels and a floor you cannot get below](09-Quantum%20Mechanics%20in%20Outline/04-quantum-harmonic-oscillator.md)
5. [Uncertainty: sharp position and sharp momentum cannot happen at once](09-Quantum%20Mechanics%20in%20Outline/05-uncertainty-principle.md)
6. [Spin one-half: the smallest quantum system, run by three two-by-two matrices](09-Quantum%20Mechanics%20in%20Outline/06-spin-and-two-state-systems.md)
7. [Hydrogen in outline: separate the angles and shells with quantum numbers appear](09-Quantum%20Mechanics%20in%20Outline/07-the-hydrogen-atom-in-outline.md)
8. [Symmetry and conservation: each continuous symmetry hands you a conserved quantity](09-Quantum%20Mechanics%20in%20Outline/08-symmetry-and-conserved-quantities.md)

[↑ Back to the shelves](#top)

<a name="s10"></a>

## 10 · Robustness and Adaptation · 5 cards

*What to do when the model is wrong: bounded uncertainty, worst-case design, scheduling and learning*

1. [Writing down model error: an added lump or a percentage, and the small gain rule](10-Robustness%20and%20Adaptation/01-model-uncertainty-and-the-small-gain-theorem.md)
2. [Robust tests: does every plant in the family stay stable, and still perform](10-Robustness%20and%20Adaptation/02-robust-stability-and-robust-performance.md)
3. [H-infinity design: shrink the worst-case gain from disturbance to error](10-Robustness%20and%20Adaptation/03-h-infinity-control-in-outline.md)
4. [Adapting as you go: schedule the gains, or let the controller learn the plant](10-Robustness%20and%20Adaptation/04-gain-scheduling-and-adaptive-control.md)
5. [Passivity: join two parts that only absorb energy and the loop cannot blow up](10-Robustness%20and%20Adaptation/05-passivity-and-absolute-stability.md)

[↑ Back to the shelves](#top)

---

[← 12 · Financial mathematics](../12-Financial%20mathematics/README.md) · [All wings](../../SYLLABUS.md) · [14 · Applied and computational →](../14-Applied%20and%20computational/README.md)
