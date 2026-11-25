<a name="top"></a>

[Syllabus](../../SYLLABUS.md) → Harmonic analysis

# 20 · Harmonic analysis

Prove the convergence theorems for Fourier series and the inversion and Plancherel theorems for the transform, and use convolution, kernels and approximate identities as everyday tools. Derive the probability results that rest on characteristic functions, build and use wavelets, and read a modern harmonic-analysis statement about maximal functions, singular integrals and restriction.

8 shelves · **70 of 70 cards ready to read**

Click a shelf to jump to its cards, then click a card's title to read it.

| Shelf | Cards |
| --- | ---: |
| [01 · Fourier Series in Depth](#s01) | 9 |
| [02 · The Fourier Transform](#s02) | 11 |
| [03 · Convolution and Approximate Identities](#s03) | 10 |
| [04 · Characteristic Functions and Probability](#s04) | 9 |
| [05 · Wavelets and Time-Frequency](#s05) | 9 |
| [06 · Maximal Functions and Beyond](#s06) | 12 |
| [07 · Multipliers and Estimates for PDE](#s07) | 6 |
| [08 · Harmonic Analysis on Groups](#s08) | 4 |

<a name="s01"></a>

## 01 · Fourier Series in Depth · 9 cards

*Coefficients, kernels, and exactly when and in what sense the series equals the function*

1. [Fourier coefficients: each wave's share, read off by an integral that ignores the rest](01-Fourier%20Series%20in%20Depth/01-fourier-coefficients-and-orthogonality.md)
2. [Partial sums are the best fit: least squares in function space, and Bessel's inequality](01-Fourier%20Series%20in%20Depth/02-best-approximation-and-bessels-inequality.md)
3. [Dirichlet and Fejer kernels: a partial sum is the signal smeared by a fixed shape](01-Fourier%20Series%20in%20Depth/03-dirichlet-and-fejer-kernels.md)
4. [Dirichlet's theorem: where the series equals the signal, and where it averages the jump](01-Fourier%20Series%20in%20Depth/04-pointwise-and-uniform-convergence.md)
5. [Convergence in energy: Parseval, completeness, and Riesz-Fischer](01-Fourier%20Series%20in%20Depth/05-l2-convergence-and-riesz-fischer.md)
6. [Smoothness shows in the tail: how fast coefficients shrink, and how many terms you need](01-Fourier%20Series%20in%20Depth/06-decay-of-coefficients-and-smoothness.md)
7. [Differentiating a series term by term: when it is legal, and what integration costs](01-Fourier%20Series%20in%20Depth/07-term-by-term-differentiation-and-integration.md)
8. [The Gibbs overshoot and the cure: Fejer averaging and half-range series](01-Fourier%20Series%20in%20Depth/08-gibbs-and-summability.md)
9. [Carleson's theorem in outline: almost everywhere, the series does converge](01-Fourier%20Series%20in%20Depth/09-carleson-in-outline.md)

[↑ Back to the shelves](#top)

<a name="s02"></a>

## 02 · The Fourier Transform · 11 cards

*The transform of an integrable and of a square-integrable signal, inversion, energy, distributions, and the limits on locality*

1. [The Fourier transform of an absolutely integrable signal, and why it fades at infinity](02-The%20Fourier%20Transform/01-fourier-transform-on-l1-and-riemann-lebesgue.md)
2. [The transform rulebook: shifting, scaling, and turning derivatives into multiplication](02-The%20Fourier%20Transform/02-shift-scale-and-derivative-rules.md)
3. [Two pairs worth memorising: gate and sinc, and the bell curve that transforms to itself](02-The%20Fourier%20Transform/03-gaussian-and-sinc-transform-pairs.md)
4. [Fourier inversion: rebuilding the signal from its spectrum, proved with a bell curve](02-The%20Fourier%20Transform/04-fourier-inversion-theorem.md)
5. [Plancherel: the transform preserves energy, and extends to every square-integrable signal](02-The%20Fourier%20Transform/05-plancherel-and-l2.md)
6. [Schwartz space and tempered distributions: transforms of spikes, constants and steps](02-The%20Fourier%20Transform/06-schwartz-space-and-tempered-distributions.md)
7. [The uncertainty principle: no signal is both brief and narrow in frequency](02-The%20Fourier%20Transform/07-uncertainty-principle.md)
8. [Poisson summation and sampling: samples are enough when nothing wiggles too fast](02-The%20Fourier%20Transform/08-poisson-summation-and-sampling.md)
9. [The Hilbert transform: shift every frequency a quarter turn, and read off the envelope](02-The%20Fourier%20Transform/09-hilbert-transform-and-analytic-signals.md)
10. [Transforms in two and three dimensions: a slice of the spectrum is a shadow of the object](02-The%20Fourier%20Transform/10-multidimensional-transform-and-tomography.md)
11. [Paley-Wiener-Schwartz: a signal confined to a window has an entire spectrum whose growth gives the window's width](02-The%20Fourier%20Transform/11-paley-wiener-schwartz-theorem.md)

[↑ Back to the shelves](#top)

<a name="s03"></a>

## 03 · Convolution and Approximate Identities · 10 cards

*Convolution as filtering and as smoothing, the kernels that do it, and what it does to densities and to spectra*

1. [Convolution: slide, multiply, add, and the inequality that bounds the result](03-Convolution%20and%20Approximate%20Identities/01-convolution-and-youngs-inequality.md)
2. [The convolution theorem: blending in time is multiplying in frequency](03-Convolution%20and%20Approximate%20Identities/02-convolution-theorem-and-impulse-response.md)
3. [Approximate identities: a shrinking bump that smooths a signal without moving it](03-Convolution%20and%20Approximate%20Identities/03-approximate-identities.md)
4. [The Gaussian and Poisson kernels: heat spreading, and a disc's boundary values](03-Convolution%20and%20Approximate%20Identities/04-gaussian-and-poisson-kernels.md)
5. [Blurring and unblurring: why a blur is easy and undoing it is not](03-Convolution%20and%20Approximate%20Identities/05-smoothing-blurring-and-deconvolution.md)
6. [Correlation: sliding one signal against another to find a known shape in noise](03-Convolution%20and%20Approximate%20Identities/06-correlation-and-the-matched-filter.md)
7. [Wiener-Khinchin: the power spectrum is the transform of the autocorrelation](03-Convolution%20and%20Approximate%20Identities/07-wiener-khinchin-and-the-power-spectrum.md)
8. [Densities add by convolution: the law of a sum of independent quantities](03-Convolution%20and%20Approximate%20Identities/08-convolution-of-densities.md)
9. [Solving differential equations by transform: derivatives become multiplication](03-Convolution%20and%20Approximate%20Identities/09-fourier-methods-for-differential-equations.md)
10. [Wiener's Tauberian theorem: shifts of one signal fill L¹ exactly when its spectrum never vanishes](03-Convolution%20and%20Approximate%20Identities/10-wieners-tauberian-theorem.md)

[↑ Back to the shelves](#top)

<a name="s04"></a>

## 04 · Characteristic Functions and Probability · 9 cards

*Fourier analysis of probability laws: inversion, continuity, the central limit theorem, jump laws and option pricing*

1. [Characteristic functions: the transform of a probability law, which always exists](04-Characteristic%20Functions%20and%20Probability/01-characteristic-functions-in-depth.md)
2. [Moments and cumulants: what differentiating the fingerprint at zero tells you](04-Characteristic%20Functions%20and%20Probability/02-moments-and-cumulants-from-the-fingerprint.md)
3. [Levy's inversion formula: getting the law back out of its fingerprint](04-Characteristic%20Functions%20and%20Probability/03-levy-inversion-and-uniqueness.md)
4. [Levy's continuity theorem: when fingerprints converge, the laws converge too](04-Characteristic%20Functions%20and%20Probability/04-levy-continuity-theorem.md)
5. [The central limit theorem in four lines, once you have fingerprints](04-Characteristic%20Functions%20and%20Probability/05-central-limit-theorem-by-characteristic-functions.md)
6. [How big must n be: the Berry-Esseen bound and the skewness correction](04-Characteristic%20Functions%20and%20Probability/06-berry-esseen-and-the-rate.md)
7. [Infinitely divisible laws: the Levy-Khintchine recipe of drift, wobble and jumps](04-Characteristic%20Functions%20and%20Probability/07-infinitely-divisible-laws-and-levy-khintchine.md)
8. [Stable laws: the limits you reach when the variance is infinite](04-Characteristic%20Functions%20and%20Probability/08-stable-laws-and-heavy-tails.md)
9. [Pricing by transform: Carr-Madan turns a fingerprint into a ladder of option prices](04-Characteristic%20Functions%20and%20Probability/09-carr-madan-and-fourier-pricing.md)

[↑ Back to the shelves](#top)

<a name="s05"></a>

## 05 · Wavelets and Time-Frequency · 9 cards

*Seeing when each frequency happens: windows, scales, filter banks, denoising and compression*

1. [Short-time Fourier transform: run the transform on sliding windows](05-Wavelets%20and%20Time-Frequency/01-short-time-fourier-and-gabor.md)
2. [Continuous wavelet transform: compare the signal with stretched and shifted wiggles](05-Wavelets%20and%20Time-Frequency/02-continuous-wavelet-transform-and-the-scalogram.md)
3. [The Haar wavelet: averages and differences, and the ladder of coarse-to-fine views](05-Wavelets%20and%20Time-Frequency/03-haar-wavelet-and-multiresolution.md)
4. [Mallat's algorithm: every scale in linear time by filtering and halving](05-Wavelets%20and%20Time-Frequency/04-mallats-fast-wavelet-transform.md)
5. [Filter banks: when splitting and rejoining returns the signal unchanged](05-Wavelets%20and%20Time-Frequency/05-filter-banks-and-perfect-reconstruction.md)
6. [Daubechies wavelets: short, smooth, and blind to polynomial trends](05-Wavelets%20and%20Time-Frequency/06-daubechies-and-vanishing-moments.md)
7. [Wavelet denoising: keep the big coefficients, throw the small ones away](05-Wavelets%20and%20Time-Frequency/07-wavelet-denoising.md)
8. [Compression by wavelets: why a few coefficients carry a whole picture](05-Wavelets%20and%20Time-Frequency/08-wavelet-compression-and-image-coding.md)
9. [Frames in outline: redundant building blocks that still rebuild a signal stably](05-Wavelets%20and%20Time-Frequency/09-frames-in-outline.md)

[↑ Back to the shelves](#top)

<a name="s06"></a>

## 06 · Maximal Functions and Beyond · 12 cards

*The tools of modern harmonic analysis, proved where the proof is short and stated where it is deep*

1. [The maximal function: the biggest average around a point, and the bound it obeys](06-Maximal%20Functions%20and%20Beyond/01-hardy-littlewood-maximal-function.md)
2. [Calderon-Zygmund decomposition: halve the boxes until the average is just big enough](06-Maximal%20Functions%20and%20Beyond/02-calderon-zygmund-decomposition-in-outline.md)
3. [Singular integrals: kernels that only just fail to be integrable, yet stay bounded](06-Maximal%20Functions%20and%20Beyond/03-singular-integrals-and-the-hilbert-transform-bound.md)
4. [Interpolation: bounds at two sizes give bounds at every size between](06-Maximal%20Functions%20and%20Beyond/04-interpolation-riesz-thorin-and-marcinkiewicz.md)
5. [Bochner's theorem: which functions are fingerprints, and which are spectra](06-Maximal%20Functions%20and%20Beyond/05-bochner-and-positive-definite-functions.md)
6. [Restriction and Kakeya in outline: what a spectrum living on a sphere can tell you](06-Maximal%20Functions%20and%20Beyond/06-restriction-and-kakeya-in-outline.md)
7. [Riesz transforms: the Hilbert transform in n dimensions, and second derivatives from the Laplacian](06-Maximal%20Functions%20and%20Beyond/07-riesz-transforms-and-singular-integrals-in-higher-dimensions.md)
8. [Fractional integration: the Hardy-Littlewood-Sobolev inequality, and Sobolev embedding in one line](06-Maximal%20Functions%20and%20Beyond/08-riesz-potentials-and-hardy-littlewood-sobolev.md)
9. [BMO: functions that wobble a bounded amount on every interval, and the exponential tail that forces](06-Maximal%20Functions%20and%20Beyond/09-bmo-and-the-john-nirenberg-inequality.md)
10. [The Hardy space H¹: atoms, the endpoint where singular integrals behave, and Fefferman's duality with BMO](06-Maximal%20Functions%20and%20Beyond/10-hardy-space-h1-and-its-duality-with-bmo.md)
11. [Muckenhoupt weights: exactly which weightings keep the maximal function and singular integrals bounded](06-Maximal%20Functions%20and%20Beyond/11-muckenhoupt-weights.md)
12. [Stationary phase: a fast-oscillating integral is decided near the points where the phase stops moving](06-Maximal%20Functions%20and%20Beyond/12-oscillatory-integrals-and-stationary-phase.md)

[↑ Back to the shelves](#top)

<a name="s07"></a>

## 07 · Multipliers and Estimates for PDE · 6 cards

*Operators that act on frequencies: the test for a safe multiplier, octave splitting, products sorted by frequency, singular integrals without translation symmetry, symbols that change with position, and the time-averaged decay behind nonlinear waves*

1. [Fourier multipliers: which equaliser settings are safe on every Lᵖ, by the Mihlin-Hörmander test](07-Multipliers%20and%20Estimates%20for%20PDE/01-mihlin-hormander-multiplier-theorem.md)
2. [Littlewood-Paley: split a signal into octaves, and its size is the size of the octaves' combined energy](07-Multipliers%20and%20Estimates%20for%20PDE/02-littlewood-paley-theory.md)
3. [Paraproducts: sort a product by which factor carries the high frequencies](07-Multipliers%20and%20Estimates%20for%20PDE/03-paraproducts-and-the-coifman-meyer-theorem.md)
4. [The T(1) theorem: a singular integral with no translation symmetry is bounded on L² when T(1) and T*(1) lie in BMO](07-Multipliers%20and%20Estimates%20for%20PDE/04-the-t1-theorem.md)
5. [Pseudodifferential operators: a Fourier multiplier whose gain also depends on position](07-Multipliers%20and%20Estimates%20for%20PDE/05-pseudodifferential-operators.md)
6. [Strichartz estimates: dispersion averaged over time, and when a nonlinear Schrödinger wave exists, scatters or blows up](07-Multipliers%20and%20Estimates%20for%20PDE/06-strichartz-estimates-and-nonlinear-schrodinger.md)

[↑ Back to the shelves](#top)

<a name="s08"></a>

## 08 · Harmonic Analysis on Groups · 4 cards

*One Fourier theory for every group with a fair way to measure size: characters of finite abelian groups, Haar measure, Pontryagin duality, and Peter-Weyl for compact groups*

1. [Fourier analysis on a finite abelian group: characters as the waves, and the transform on bit strings](08-Harmonic%20Analysis%20on%20Groups/01-fourier-analysis-on-finite-abelian-groups.md)
2. [Haar measure: the one fair way to measure size on a group](08-Harmonic%20Analysis%20on%20Groups/02-haar-measure.md)
3. [Pontryagin duality: the line, the circle, the integers and the clock as one Fourier theory](08-Harmonic%20Analysis%20on%20Groups/03-pontryagin-duality.md)
4. [Peter-Weyl: Fourier series on a compact group, with the matrix entries of its representations as the waves](08-Harmonic%20Analysis%20on%20Groups/04-peter-weyl-theorem.md)

[↑ Back to the shelves](#top)

---

[← 19 · Partial differential equations](../19-Partial%20differential%20equations/README.md) · [All wings](../../SYLLABUS.md) · [21 · Algebraic and analytic number theory →](../21-Algebraic%20and%20analytic%20number%20theory/README.md)
