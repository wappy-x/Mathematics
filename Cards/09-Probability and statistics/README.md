<a name="top"></a>

[Syllabus](../../SYLLABUS.md) → Probability and statistics

# 09 · Probability and statistics

Model chance with the standard distributions, compute and simulate probabilities, estimate from data with honest error bars, test claims, fit regressions and time series, and say what a result does and does not show. Proofs of the limit theorems are in wing 10; this wing states them and uses them.

14 shelves · **100 of 100 cards ready to read**

Click a shelf to jump to its cards, then click a card's title to read it.

| Shelf | Cards |
| --- | ---: |
| [01 · Chance and Events](#s01) | 7 |
| [02 · Random Variables](#s02) | 8 |
| [03 · Discrete Distributions](#s03) | 7 |
| [04 · Continuous Distributions](#s04) | 9 |
| [05 · Transformations and Joint Laws](#s05) | 8 |
| [06 · Limit Theorems in Practice](#s06) | 6 |
| [07 · Sampling and Estimation](#s07) | 8 |
| [08 · Confidence Intervals and Tests](#s08) | 8 |
| [09 · Regression](#s09) | 8 |
| [10 · Bayesian Inference](#s10) | 6 |
| [11 · Simulation](#s11) | 6 |
| [12 · Time Series](#s12) | 7 |
| [13 · Survival, Design and Causality](#s13) | 7 |
| [14 · Random Graphs and the Probabilistic Method](#s14) | 5 |

<a name="s01"></a>

## 01 · Chance and Events · 7 cards

*What probability is, how events combine, and how evidence updates a belief*

1. [Probability: a number between 0 and 1, and the three readings people give it](01-Chance%20and%20Events/01-what-probability-means.md)
2. [Sample spaces and events: listing what can happen](01-Chance%20and%20Events/02-sample-spaces-and-events.md)
3. [The rules: adding probabilities of separate events, and one minus for the complement](01-Chance%20and%20Events/03-probability-rules-and-complements.md)
4. [Counting chances: favourable over possible, with the counting done in wing 04](01-Chance%20and%20Events/04-equally-likely-outcomes-and-counting.md)
5. [Conditional probability: the chance of one thing given another has happened](01-Chance%20and%20Events/05-conditional-probability.md)
6. [Bayes' rule: turning the evidence round](01-Chance%20and%20Events/06-bayes-rule.md)
7. [Independence: when knowing one event says nothing about another](01-Chance%20and%20Events/07-independence.md)

[↑ Back to the shelves](#top)

<a name="s02"></a>

## 02 · Random Variables · 8 cards

*Numbers attached to outcomes, their averages and spreads, and the inequalities that bound them*

1. [Random variables: a number for each outcome, and the table of its chances](02-Random%20Variables/01-random-variables-and-distributions.md)
2. [Expectation: the long-run average, as a weighted sum](02-Random%20Variables/02-expectation.md)
3. [Variance: the average squared distance from the mean, and its square root in the original units](02-Random%20Variables/03-variance-and-standard-deviation.md)
4. [Two variables at once: joint tables, marginals, covariance and correlation](02-Random%20Variables/04-joint-distributions-and-covariance.md)
5. [Conditional expectation: the average given what you know, and the tower rule](02-Random%20Variables/05-conditional-expectation-in-tables.md)
6. [Jensen's inequality: the average of a curve is not the curve of the average](02-Random%20Variables/06-jensens-inequality.md)
7. [Moment generating functions: one function that stores every moment](02-Random%20Variables/07-moment-generating-functions.md)
8. [Markov and Chebyshev: bounds on tails from a mean and a variance alone](02-Random%20Variables/08-markov-and-chebyshev-inequalities.md)

[↑ Back to the shelves](#top)

<a name="s03"></a>

## 03 · Discrete Distributions · 7 cards

*The named distributions for counts and waits, when each applies, and what happens when you add them*

1. [Binomial: the number of successes in n independent tries](03-Discrete%20Distributions/01-bernoulli-and-binomial.md)
2. [Waiting for a success: how many tries until the first, and until the r-th](03-Discrete%20Distributions/02-geometric-and-negative-binomial.md)
3. [Hypergeometric: drawing without replacement, where every ball taken changes the odds for the next](03-Discrete%20Distributions/03-hypergeometric.md)
4. [Poisson: counts of rare events, and the limit of the binomial that produces it](03-Discrete%20Distributions/04-poisson.md)
5. [Multinomial: several categories at once](03-Discrete%20Distributions/05-multinomial.md)
6. [Adding counts: convolution, and why binomials and Poissons stay in the family](03-Discrete%20Distributions/06-sums-of-discrete-variables.md)
7. [Two classics: shared birthdays and collecting a full set](03-Discrete%20Distributions/07-birthday-and-coupon-collector.md)

[↑ Back to the shelves](#top)

<a name="s04"></a>

## 04 · Continuous Distributions · 9 cards

*Densities, the standard continuous distributions, and the ones with heavy tails*

1. [Densities: probability as area under a curve](04-Continuous%20Distributions/01-densities-and-cdfs.md)
2. [Uniform: every value in an interval equally likely](04-Continuous%20Distributions/02-uniform-distribution.md)
3. [Exponential: waiting times with no memory](04-Continuous%20Distributions/03-exponential-distribution.md)
4. [Normal: the bell curve, its two parameters and the 68-95-99.7 rule](04-Continuous%20Distributions/04-normal-distribution.md)
5. [Normal quantiles: the value with a given probability below it, and how a computer finds it](04-Continuous%20Distributions/05-normal-quantile.md)
6. [Lognormal: a quantity whose logarithm is normal, and why prices use it](04-Continuous%20Distributions/06-lognormal-distribution.md)
7. [Gamma and beta: waiting for several events, and a chance that is itself uncertain](04-Continuous%20Distributions/07-gamma-and-beta-distributions.md)
8. [Heavy tails: distributions where the mean or the variance does not exist](04-Continuous%20Distributions/08-heavy-tails-pareto-and-cauchy.md)
9. [Weibull and hazards: failure rates that rise or fall with age](04-Continuous%20Distributions/09-weibull-and-hazard-rates.md)

[↑ Back to the shelves](#top)

<a name="s05"></a>

## 05 · Transformations and Joint Laws · 8 cards

*Functions of random variables, several continuous variables together, and the multivariate normal*

1. [Transforming a variable: the density of a function of X](05-Transformations%20and%20Joint%20Laws/01-transforming-a-random-variable.md)
2. [Joint densities: two continuous variables and the surface over the plane](05-Transformations%20and%20Joint%20Laws/02-joint-densities-and-marginals.md)
3. [Conditional densities: the slice of the surface at a known value](05-Transformations%20and%20Joint%20Laws/03-conditional-densities.md)
4. [Adding continuous variables: the convolution integral, and why normal plus normal is normal](05-Transformations%20and%20Joint%20Laws/04-sums-and-convolution.md)
5. [Bivariate normal: two correlated bells, and the straight-line conditional mean](05-Transformations%20and%20Joint%20Laws/05-bivariate-normal-and-conditioning.md)
6. [Multivariate normal: a vector of correlated normals and its covariance matrix](05-Transformations%20and%20Joint%20Laws/06-multivariate-normal.md)
7. [Copulas: separating what each variable does from how they move together](05-Transformations%20and%20Joint%20Laws/07-copulas-and-sklars-theorem.md)
8. [Order statistics: the largest, the smallest and the median of a sample](05-Transformations%20and%20Joint%20Laws/08-order-statistics-and-extremes.md)

[↑ Back to the shelves](#top)

<a name="s06"></a>

## 06 · Limit Theorems in Practice · 6 cards

*Averages settle and their errors are bell-shaped: the laws that make statistics work, stated and used*

1. [Law of large numbers: averages settle down](06-Limit%20Theorems%20in%20Practice/01-law-of-large-numbers.md)
2. [Central limit theorem: the error of an average is bell-shaped, whatever the ingredients](06-Limit%20Theorems%20in%20Practice/02-central-limit-theorem.md)
3. [Normal approximation: a binomial as a bell, with the half-step correction](06-Limit%20Theorems%20in%20Practice/03-normal-approximation-to-binomial.md)
4. [Characteristic functions: the Fourier transform of a distribution, and how to get the distribution back](06-Limit%20Theorems%20in%20Practice/04-characteristic-functions-and-inversion.md)
5. [Delta method: the error of a function of an average](06-Limit%20Theorems%20in%20Practice/05-delta-method-and-slutsky.md)
6. [Concentration: exponential tail bounds for sums of bounded variables](06-Limit%20Theorems%20in%20Practice/06-concentration-inequalities-hoeffding-and-chernoff.md)

[↑ Back to the shelves](#top)

<a name="s07"></a>

## 07 · Sampling and Estimation · 8 cards

*Estimating a number from a sample and saying how wrong you might be*

1. [Samples and estimators: a rule that turns data into a guess, and what makes a guess good](07-Sampling%20and%20Estimation/01-populations-samples-and-estimators.md)
2. [Standard error: the spread of an average, and the square root of n](07-Sampling%20and%20Estimation/02-sample-mean-and-standard-error.md)
3. [The reference distributions: chi-square, t and F, and where each comes from](07-Sampling%20and%20Estimation/03-chi-square-t-and-f-distributions.md)
4. [Maximum likelihood: pick the parameter that makes the data least surprising](07-Sampling%20and%20Estimation/04-maximum-likelihood.md)
5. [Method of moments: match the sample's averages to the model's](07-Sampling%20and%20Estimation/05-method-of-moments.md)
6. [Bias and variance: the two ways an estimator can be wrong](07-Sampling%20and%20Estimation/06-bias-variance-and-mean-squared-error.md)
7. [Fisher information: how much a sample can tell you, and the floor on any estimator's error](07-Sampling%20and%20Estimation/07-fisher-information-and-cramer-rao.md)
8. [Bootstrap: resampling your own data to see how your estimate wobbles](07-Sampling%20and%20Estimation/08-bootstrap.md)

[↑ Back to the shelves](#top)

<a name="s08"></a>

## 08 · Confidence Intervals and Tests · 8 cards

*Error bars, tests, p-values, power, and what goes wrong when you test many things*

1. [Confidence intervals: a range that traps the truth 95 times in 100](08-Confidence%20Intervals%20and%20Tests/01-confidence-intervals.md)
2. [Intervals for a proportion: the Wald interval and the better Wilson one](08-Confidence%20Intervals%20and%20Tests/02-intervals-for-proportions.md)
3. [Hypothesis tests: a null, a statistic, and the p-value that measures surprise](08-Confidence%20Intervals%20and%20Tests/03-hypothesis-tests-and-p-values.md)
4. [Power: the chance of catching a real effect, and the sample size that buys it](08-Confidence%20Intervals%20and%20Tests/04-power-and-sample-size.md)
5. [t-tests: one sample, two samples, and paired](08-Confidence%20Intervals%20and%20Tests/05-t-tests-and-comparing-means.md)
6. [Chi-square tests: does the table fit the model, and are the rows independent](08-Confidence%20Intervals%20and%20Tests/06-chi-square-tests.md)
7. [Likelihood ratio tests: comparing two fits, and Wilks' chi-square rule](08-Confidence%20Intervals%20and%20Tests/07-likelihood-ratio-tests.md)
8. [Many tests: why one in twenty lies, and Bonferroni and false discovery control](08-Confidence%20Intervals%20and%20Tests/08-multiple-testing.md)

[↑ Back to the shelves](#top)

<a name="s09"></a>

## 09 · Regression · 8 cards

*Fitting lines and planes to data, saying how sure the fit is, and the models that extend it*

1. [Least squares: the line closest to the points, and what its slope means](09-Regression/01-least-squares-regression.md)
2. [Regression error bars: standard errors, t-tests and prediction intervals for a fitted line](09-Regression/02-regression-inference.md)
3. [Multiple regression: several predictors at once, and why least squares is best among linear unbiased fits](09-Regression/03-multiple-regression-and-gauss-markov.md)
4. [Diagnostics: residual plots, leverage, and the assumptions a regression quietly makes](09-Regression/04-diagnostics-and-residuals.md)
5. [Logistic regression: predicting a yes or no](09-Regression/05-logistic-regression.md)
6. [Regularisation: shrinking coefficients to trade bias for stability](09-Regression/06-ridge-and-lasso.md)
7. [Principal components: the directions your data varies most](09-Regression/07-principal-components.md)
8. [Overfitting: a model that memorises, and the held-out test that catches it](09-Regression/08-cross-validation-and-overfitting.md)

[↑ Back to the shelves](#top)

<a name="s10"></a>

## 10 · Bayesian Inference · 6 cards

*Priors, posteriors, conjugate updates, and decisions from a posterior*

1. [Bayesian updating: a prior belief, the data, and the posterior that combines them](10-Bayesian%20Inference/01-priors-posteriors-and-updating.md)
2. [Beta-binomial: the conjugate update for a proportion](10-Bayesian%20Inference/02-beta-binomial.md)
3. [Normal-normal: updating a mean with precision weights](10-Bayesian%20Inference/03-normal-normal.md)
4. [Gamma-Poisson: updating a rate from counts and hours, then predicting the next hour](10-Bayesian%20Inference/04-gamma-poisson.md)
5. [Credible intervals and decisions: what the posterior lets you say and do](10-Bayesian%20Inference/05-credible-intervals-and-decisions.md)
6. [MCMC in outline: sampling a posterior you cannot write down](10-Bayesian%20Inference/06-markov-chain-monte-carlo-in-outline.md)

[↑ Back to the shelves](#top)

<a name="s11"></a>

## 11 · Simulation · 6 cards

*Generating randomness, turning it into any distribution, and making Monte Carlo estimates cheaper*

1. [Random numbers from a computer: linear congruential and Mersenne generators, seeds and tests](11-Simulation/01-pseudo-random-numbers.md)
2. [Inverse transform: turning uniforms into any distribution with a CDF you can invert](11-Simulation/02-inverse-transform-sampling.md)
3. [Rejection sampling and Box-Muller: distributions without an invertible CDF, and normals from uniforms](11-Simulation/03-rejection-sampling-and-box-muller.md)
4. [Monte Carlo: an average of random draws, and the square-root-of-n error bar](11-Simulation/04-monte-carlo-estimates-and-error.md)
5. [Variance reduction: antithetic, control and stratified draws](11-Simulation/05-variance-reduction.md)
6. [Importance sampling: drawing from where it matters and reweighting](11-Simulation/06-importance-sampling.md)

[↑ Back to the shelves](#top)

<a name="s12"></a>

## 12 · Time Series · 7 cards

*Data in time order: dependence, models that forecast, and the volatility clustering finance lives with*

1. [Stationarity and autocorrelation: does the series keep its character, and does today remember yesterday](12-Time%20Series/01-stationarity-and-autocorrelation.md)
2. [Autoregression: tomorrow as a fraction of today plus noise](12-Time%20Series/02-ar-models.md)
3. [Moving average and ARMA: noise that lingers](12-Time%20Series/03-ma-and-arma.md)
4. [Unit roots: series that wander, and the differencing that tames them](12-Time%20Series/04-differencing-and-unit-roots.md)
5. [Forecasting: exponential smoothing, Holt-Winters and honest forecast intervals](12-Time%20Series/05-forecasting-and-exponential-smoothing.md)
6. [GARCH: volatility that clusters, and a model for tomorrow's spread](12-Time%20Series/06-garch-and-volatility-clustering.md)
7. [Cointegration: two wandering series tied together](12-Time%20Series/07-cointegration-in-outline.md)

[↑ Back to the shelves](#top)

<a name="s13"></a>

## 13 · Survival, Design and Causality · 7 cards

*Time-to-event data, designing an experiment that can answer a question, and when correlation says nothing about cause*

1. [Survival: the chance of lasting past t, and the hazard that drives it](13-Survival%2C%20Design%20and%20Causality/01-survival-functions-and-hazards.md)
2. [Kaplan-Meier: a survival curve from data with dropouts](13-Survival%2C%20Design%20and%20Causality/02-kaplan-meier.md)
3. [Cox regression in outline: how covariates scale the hazard](13-Survival%2C%20Design%20and%20Causality/03-cox-proportional-hazards-in-outline.md)
4. [Randomised experiments: why random assignment lets you say 'because'](13-Survival%2C%20Design%20and%20Causality/04-randomised-experiments-and-ab-tests.md)
5. [Blocking and factorial designs: getting more from fewer trials](13-Survival%2C%20Design%20and%20Causality/05-blocking-and-factorial-designs.md)
6. [Permutation tests: shuffle the labels to get the null distribution](13-Survival%2C%20Design%20and%20Causality/06-permutation-tests.md)
7. [Confounding: the hidden variable that reverses a conclusion](13-Survival%2C%20Design%20and%20Causality/07-confounding-and-simpsons-paradox.md)

[↑ Back to the shelves](#top)

<a name="s14"></a>

## 14 · Random Graphs and the Probabilistic Method · 5 cards

*Randomness on graphs: when a giant component appears, and proving things exist by showing they are likely*

1. [Random graphs: every edge tossed with probability p](14-Random%20Graphs%20and%20the%20Probabilistic%20Method/01-random-graphs-erdos-renyi.md)
2. [The giant component: a sudden switch when the average degree passes one](14-Random%20Graphs%20and%20the%20Probabilistic%20Method/02-the-giant-component.md)
3. [The probabilistic method: proving something exists by showing a random choice works](14-Random%20Graphs%20and%20the%20Probabilistic%20Method/03-probabilistic-method.md)
4. [First and second moments: showing a random count is zero, or is not](14-Random%20Graphs%20and%20the%20Probabilistic%20Method/04-first-and-second-moment-methods.md)
5. [Random walks on a graph: where a wanderer ends up, and how fast](14-Random%20Graphs%20and%20the%20Probabilistic%20Method/05-random-walks-on-graphs-and-mixing.md)

[↑ Back to the shelves](#top)

---

[← 08 · Differential equations and dynamics](../08-Differential%20equations%20and%20dynamics/README.md) · [All wings](../../SYLLABUS.md) · [10 · Measure and integration →](../10-Measure%20and%20integration/README.md)
