<a name="top"></a>

[Syllabus](../../SYLLABUS.md) → Financial mathematics

# 12 · Financial mathematics

Price, hedge, risk-manage and solve backwards the main products across rates, equity, FX, commodities, credit and their combinations, plus portfolio, risk, trading and insurance mathematics. Each formula is solved for each of its inputs where that is possible, and the card says when it is not and on what domain.

51 shelves · **332 of 332 cards ready to read**

Click a shelf to jump to its cards, then click a card's title to read it.

| Shelf | Cards |
| --- | ---: |
| [01 · Money, Dates and Discounting](#s01) | 7 |
| [02 · Curves](#s02) | 6 |
| [03 · Contracts and No-Arbitrage](#s03) | 7 |
| [04 · Binomial Trees](#s04) | 6 |
| [05 · Black-Scholes from the Ground Up](#s05) | 8 |
| [06 · Numerical Methods for Pricing](#s06) | 9 |
| [07 · Greeks by Numbers and Calibration](#s07) | 7 |
| [08 · The Black-Scholes call and put](#s08) | 9 |
| [09 · The Greeks, one each](#s09) | 10 |
| [10 · Digitals and the implied density](#s10) | 6 |
| [11 · Implied volatility and the vanilla inverses](#s11) | 5 |
| [12 · The smile and the surface](#s12) | 5 |
| [13 · Local volatility and jumps](#s13) | 5 |
| [14 · Stochastic volatility: Heston, SABR and their mix](#s14) | 6 |
| [15 · American and Bermudan exercise](#s15) | 7 |
| [16 · Barriers, touches and lookbacks](#s16) | 7 |
| [17 · Averages, choosers, compounds and forward-starts](#s17) | 7 |
| [18 · Many underlyings: exchange, spread, basket and rainbow](#s18) | 5 |
| [19 · Variance swaps, the log contract and VIX](#s19) | 6 |
| [20 · FX spot, forwards and interest parity](#s20) | 5 |
| [21 · FX vanilla options: Garman-Kohlhagen and the desk conventions](#s21) | 7 |
| [22 · The FX smile: risk reversals, butterflies and vanna-volga](#s22) | 6 |
| [23 · FX exotics as desks use them: digitals, touches and barriers](#s23) | 8 |
| [24 · Quantos and composites](#s24) | 5 |
| [25 · Commodity forwards: carry, storage, convenience yield and the curve](#s25) | 6 |
| [26 · Options on commodity futures and spreads](#s26) | 7 |
| [27 · Averages: commodity swaps and Asian options](#s27) | 5 |
| [28 · Swaps](#s28) | 7 |
| [29 · Caps, Floors and Swaptions](#s29) | 9 |
| [30 · Short-Rate Models](#s30) | 8 |
| [31 · Forward-Rate Models](#s31) | 6 |
| [32 · Convexity and Exotics](#s32) | 6 |
| [33 · Curves in Depth](#s33) | 6 |
| [34 · Inflation and Real Rates](#s34) | 5 |
| [35 · Mortgages, Callables and Prepayment](#s35) | 5 |
| [36 · Returns and Utility](#s36) | 6 |
| [37 · Portfolio Theory](#s37) | 8 |
| [38 · Performance and Multi-Period](#s38) | 5 |
| [39 · Value at Risk and Expected Shortfall](#s39) | 8 |
| [40 · Hedging, Volatility Forecasts and Stress](#s40) | 6 |
| [41 · Default, Survival and the Hazard Rate](#s41) | 5 |
| [42 · Credit Default Swaps: Pricing, the Par Spread and the Hazard Behind It](#s42) | 9 |
| [43 · Structural Models: Default from the Balance Sheet](#s43) | 6 |
| [44 · Reduced-Form Models: Risky Bonds, Spreads and Random Hazards](#s44) | 5 |
| [45 · Portfolio Credit: Correlation, Copulas, Indices and Tranches](#s45) | 7 |
| [46 · Counterparty Risk and CVA](#s46) | 6 |
| [47 · Collateral, Funding and the Rest of the XVAs](#s47) | 5 |
| [48 · Regulatory Capital in Outline](#s48) | 5 |
| [49 · Microstructure and Execution](#s49) | 7 |
| [50 · Signals, Mean Reversion and Backtesting](#s50) | 7 |
| [51 · Insurance and Actuarial Mathematics](#s51) | 8 |

<a name="s01"></a>

## 01 · Money, Dates and Discounting · 7 cards

*Discount factors, day counts, annuities, bonds, duration and the first inverse problem: yield from price*

1. [Discount factors: the price today of one unit later, under any compounding convention](01-Money%2C%20Dates%20and%20Discounting/01-compounding-and-discount-factors.md)
2. [Day counts: Actual/360, 30/360 and Actual/Actual, and why the same coupon has three sizes](01-Money%2C%20Dates%20and%20Discounting/02-day-counts-and-dates.md)
3. [Annuities: a level stream of payments as one closed form, and the loan schedule it implies](01-Money%2C%20Dates%20and%20Discounting/03-annuities-and-loans.md)
4. [NPV and IRR: is a project worth it, and the rate that makes it break even](01-Money%2C%20Dates%20and%20Discounting/04-net-present-value-and-irr.md)
5. [Bond price and yield: coupons and face discounted at one rate](01-Money%2C%20Dates%20and%20Discounting/05-bonds-price-and-yield.md)
6. [Duration and convexity: how a bond price moves when its yield moves](01-Money%2C%20Dates%20and%20Discounting/06-duration-and-convexity.md)
7. [Yield from price: the first inverse problem, and when it has exactly one answer](01-Money%2C%20Dates%20and%20Discounting/07-yield-from-price.md)

[↑ Back to the shelves](#top)

<a name="s02"></a>

## 02 · Curves · 6 cards

*Building the discount curve from market quotes, reading forward rates off it, and the instruments that define it*

1. [Spot, forward and par rates: three ways to read one curve](02-Curves/01-spot-forward-and-par-rates.md)
2. [Forward rate agreements: locking a rate for a future period](02-Curves/02-forward-rate-agreements.md)
3. [Money markets: bills, repos and overnight rates, and the compounded-in-arrears convention](02-Curves/03-money-market-instruments-and-sofr.md)
4. [Bootstrapping: solving for discount factors one maturity at a time](02-Curves/04-bootstrapping-the-discount-curve.md)
5. [Between the pillars: log-linear, monotone convex and Nelson-Siegel, and what each does to forwards](02-Curves/05-curve-interpolation-and-shape.md)
6. [Spreads over the curve: the z-spread and asset-swap spread of a risky bond](02-Curves/06-z-spread-and-asset-swap-spread.md)

[↑ Back to the shelves](#top)

<a name="s03"></a>

## 03 · Contracts and No-Arbitrage · 7 cards

*What a derivative is, why two portfolios with the same payoff must cost the same, and what that forces on forwards and futures*

1. [Payoffs: long and short, calls and puts, and the diagram that shows what you get at the end](03-Contracts%20and%20No-Arbitrage/01-payoffs-and-positions.md)
2. [No arbitrage: you cannot make something from nothing, so same payoff means same price](03-Contracts%20and%20No-Arbitrage/02-no-arbitrage-and-the-law-of-one-price.md)
3. [Forward price: what you must agree to pay later so the contract costs nothing now](03-Contracts%20and%20No-Arbitrage/03-forward-price-by-cash-and-carry.md)
4. [An old forward: worth the discounted gap between today's forward price and the one you locked](03-Contracts%20and%20No-Arbitrage/04-forward-value-after-inception.md)
5. [Futures: daily settlement, and why a futures price can differ from a forward](03-Contracts%20and%20No-Arbitrage/05-futures-margining-and-the-forward-futures-difference.md)
6. [Replication: a portfolio that copies a payoff without new money](03-Contracts%20and%20No-Arbitrage/06-replication-and-self-financing.md)
7. [State prices: the price of one unit in each future state, and the fake probabilities they become](03-Contracts%20and%20No-Arbitrage/07-state-prices-and-risk-neutral-pricing-in-one-period.md)

[↑ Back to the shelves](#top)

<a name="s04"></a>

## 04 · Binomial Trees · 6 cards

*The first pricing engine: trees that replicate step by step, converge to Black-Scholes, and handle early exercise*

1. [One step: two states, two instruments, one hedge](04-Binomial%20Trees/01-one-step-binomial-replication.md)
2. [The risk-neutral probability: q equals (R minus d) over (u minus d), and why it is not a forecast](04-Binomial%20Trees/02-risk-neutral-probability.md)
3. [Many steps: price at the end, roll back one step at a time](04-Binomial%20Trees/03-multi-step-trees-and-backward-induction.md)
4. [Cox-Ross-Rubinstein: choosing u and d from volatility, and watching the tree price converge](04-Binomial%20Trees/04-crr-tree-and-convergence.md)
5. [Early exercise: compare holding with exercising at every node](04-Binomial%20Trees/05-american-exercise-on-a-tree.md)
6. [Trinomial trees: three branches, a free parameter, and the finite-difference grid in disguise](04-Binomial%20Trees/06-trinomial-trees-and-the-grid-connection.md)

[↑ Back to the shelves](#top)

<a name="s05"></a>

## 05 · Black-Scholes from the Ground Up · 8 cards

*The continuous-time engine: geometric Brownian motion, the risk-neutral measure, the pricing equation, and the forward-level models that reuse it*

1. [Prices as geometric Brownian motion: the model behind Black-Scholes](05-Black-Scholes%20from%20the%20Ground%20Up/01-geometric-brownian-motion-for-prices.md)
2. [The fundamental theorems: no arbitrage means a pricing measure exists, and completeness means it is unique](05-Black-Scholes%20from%20the%20Ground%20Up/02-risk-neutral-measure-and-the-fundamental-theorems.md)
3. [Black-Scholes by hedging: the equation a hedged portfolio must obey](05-Black-Scholes%20from%20the%20Ground%20Up/03-black-scholes-by-delta-hedging.md)
4. [Black-Scholes by expectation: the discounted average payoff under the pricing measure](05-Black-Scholes%20from%20the%20Ground%20Up/04-black-scholes-by-risk-neutral-expectation.md)
5. [Changing the unit of account: pricing in shares, bonds or annuities](05-Black-Scholes%20from%20the%20Ground%20Up/05-change-of-numeraire-in-pricing.md)
6. [Black-76: Black-Scholes for anything quoted as a forward](05-Black-Scholes%20from%20the%20Ground%20Up/06-black-76-and-forward-level-pricing.md)
7. [Bachelier: the normal model for a level that can go negative](05-Black-Scholes%20from%20the%20Ground%20Up/07-bachelier-model.md)
8. [Shifted lognormal and volatility conversion: a floor moved below zero, and comparing normal with lognormal volatility](05-Black-Scholes%20from%20the%20Ground%20Up/08-shifted-lognormal-and-volatility-conversion.md)

[↑ Back to the shelves](#top)

<a name="s06"></a>

## 06 · Numerical Methods for Pricing · 9 cards

*The engines every product card calls as a second road: simulation, grids, transforms and regression for early exercise*

1. [Monte Carlo pricing: simulate the end, average the payoff, discount](06-Numerical%20Methods%20for%20Pricing/01-monte-carlo-pricing.md)
2. [Cheaper Monte Carlo: antithetic paths, control variates and stratification](06-Numerical%20Methods%20for%20Pricing/02-variance-reduction-for-pricing.md)
3. [Quasi-Monte Carlo: Sobol points and the Brownian bridge that makes them work](06-Numerical%20Methods%20for%20Pricing/03-quasi-monte-carlo-and-brownian-bridge.md)
4. [Correlated paths: several assets from one Cholesky factor](06-Numerical%20Methods%20for%20Pricing/04-correlated-paths-and-cholesky.md)
5. [Stepping an SDE: Euler, Milstein and Andersen's scheme for Heston](06-Numerical%20Methods%20for%20Pricing/05-discretisation-schemes-for-sdes.md)
6. [Longstaff-Schwartz: early exercise by regression on simulated paths](06-Numerical%20Methods%20for%20Pricing/06-longstaff-schwartz-least-squares-monte-carlo.md)
7. [Pricing on a grid: explicit, implicit and Crank-Nicolson schemes](06-Numerical%20Methods%20for%20Pricing/07-finite-differences-for-the-black-scholes-equation.md)
8. [American options on a grid: the free boundary as a complementarity problem](06-Numerical%20Methods%20for%20Pricing/08-american-options-by-psor-and-lcp.md)
9. [Transform pricing: prices from a characteristic function by FFT or cosine series](06-Numerical%20Methods%20for%20Pricing/09-carr-madan-fft-and-cos-methods.md)

[↑ Back to the shelves](#top)

<a name="s07"></a>

## 07 · Greeks by Numbers and Calibration · 7 cards

*Sensitivities without formulas, root-finders for every inverse, and fitting a model to quotes*

1. [Bump and revalue: shift an input, reprice, divide, and use the same random numbers both times](07-Greeks%20by%20Numbers%20and%20Calibration/01-bump-and-revalue-and-common-random-numbers.md)
2. [Greeks inside the simulation: differentiate the payoff, or differentiate the density](07-Greeks%20by%20Numbers%20and%20Calibration/02-pathwise-and-likelihood-ratio-greeks.md)
3. [Adjoint differentiation: every sensitivity for the cost of one extra pass](07-Greeks%20by%20Numbers%20and%20Calibration/03-adjoint-differentiation-in-outline.md)
4. [Greeks from a tree or grid: read the slope off the nodes](07-Greeks%20by%20Numbers%20and%20Calibration/04-greeks-from-a-tree-or-grid.md)
5. [Solving backwards: bisection, Newton and Brent for any inverse problem](07-Greeks%20by%20Numbers%20and%20Calibration/05-root-finding-for-inverses.md)
6. [Calibration: choosing parameters so the model reprices the quotes](07-Greeks%20by%20Numbers%20and%20Calibration/06-calibration-as-least-squares.md)
7. [Model risk: two models that fit today's quotes and disagree tomorrow](07-Greeks%20by%20Numbers%20and%20Calibration/07-model-risk-and-parameter-stability.md)

[↑ Back to the shelves](#top)

<a name="s08"></a>

## 08 · The Black-Scholes call and put · 9 cards

*The pilot call, the put, parity, model-free bounds and strike/calendar shape, intrinsic and time value, the Black-Scholes equation as the other door, known cash dividends, and the assumptions with their failure cases. Everything on the house market.*

1. [Black–Scholes call: what a call option is, and what it should cost](08-The%20Black-Scholes%20call%20and%20put/01-black-scholes-call.md)
2. [Black-Scholes put: the right to sell, priced from the same six numbers](08-The%20Black-Scholes%20call%20and%20put/02-black-scholes-put.md)
3. [Put-call parity: call minus put is a forward, so three prices fix the fourth](08-The%20Black-Scholes%20call%20and%20put/03-put-call-parity.md)
4. [Option price bounds: the floor and ceiling every call and put must respect before any model](08-The%20Black-Scholes%20call%20and%20put/04-option-price-bounds.md)
5. [Shape across strikes and expiries: calls fall and curve the right way in strike, and total variance never falls in time](08-The%20Black-Scholes%20call%20and%20put/05-strike-and-calendar-shape.md)
6. [Intrinsic and time value: what you could cash today, and what you pay for the time left](08-The%20Black-Scholes%20call%20and%20put/06-intrinsic-and-time-value.md)
7. [The Black-Scholes equation: hedge away the randomness and every option price obeys one equation](08-The%20Black-Scholes%20call%20and%20put/07-black-scholes-equation.md)
8. [Known cash dividends: escrow the dividend, then price the share that is left](08-The%20Black-Scholes%20call%20and%20put/08-known-cash-dividends.md)
9. [The Black-Scholes assumptions: six idealisations, which term each holds up, and what breaks when it fails](08-The%20Black-Scholes%20call%20and%20put/09-black-scholes-assumptions-and-failures.md)

[↑ Back to the shelves](#top)

<a name="s09"></a>

## 09 · The Greeks, one each · 10 cards

*Delta, gamma, vega, theta, rho (with dividend rho), vanna, volga and charm, each on its own card for call and put together; then the Greeks as a Taylor expansion of profit and loss, and the identity that theta pays for gamma, with the delta-hedged profit and loss.*

1. [Delta: how many shares an option behaves like, and the number that hedges it](09-The%20Greeks%2C%20one%20each/01-delta.md)
2. [Gamma: how fast the hedge ratio changes, so how often you must rebuild it](09-The%20Greeks%2C%20one%20each/02-gamma.md)
3. [Vega: what one point of volatility is worth](09-The%20Greeks%2C%20one%20each/03-vega.md)
4. [Theta: what a day costs, and why it is rent rather than a fee](09-The%20Greeks%2C%20one%20each/04-theta.md)
5. [Rho and dividend rho: how rates and the yield move the price](09-The%20Greeks%2C%20one%20each/05-rho-and-dividend-rho.md)
6. [Vanna: how delta shifts when volatility moves, and how vega shifts when spot moves](09-The%20Greeks%2C%20one%20each/06-vanna.md)
7. [Volga: the curvature of the volatility bet](09-The%20Greeks%2C%20one%20each/07-volga.md)
8. [Charm: how delta drifts as the clock runs, with nothing else moving](09-The%20Greeks%2C%20one%20each/08-charm.md)
9. [The Greeks together: a day's profit and loss as a Taylor expansion](09-The%20Greeks%2C%20one%20each/09-greeks-together-taylor-pnl.md)
10. [Theta pays for gamma: the delta-hedged profit and loss, and the break-even daily move](09-The%20Greeks%2C%20one%20each/10-theta-pays-for-gamma-hedged-pnl.md)

[↑ Back to the shelves](#top)

<a name="s10"></a>

## 10 · Digitals and the implied density · 6 cards

*Cash and asset digitals as the two halves of the call, their Greeks and pin risk, the digital as the limit of a call spread with the skew term, the butterfly as the market's density (Breeden-Litzenberger), and the digital inverses with their two-root cases.*

1. [Cash-or-nothing digital: one dollar if the share finishes above the line](10-Digitals%20and%20the%20implied%20density/01-cash-or-nothing-digital.md)
2. [Asset-or-nothing digital: the share itself if it finishes above the line, and why the call is two digitals](10-Digitals%20and%20the%20implied%20density/02-asset-or-nothing-digital.md)
3. [Digital Greeks and pin risk: a hedge that goes wild in the last days](10-Digitals%20and%20the%20implied%20density/03-digital-greeks-and-pin-risk.md)
4. [A digital from a call spread: the limit that prices it, and the extra term the smile adds](10-Digitals%20and%20the%20implied%20density/04-digital-from-a-call-spread-and-the-skew-term.md)
5. [The butterfly and the implied density: differentiate call prices twice in strike and the market's probabilities fall out](10-Digitals%20and%20the%20implied%20density/05-butterfly-and-the-implied-density.md)
6. [Digital inverses: the strike is exact, the volatility can have two answers](10-Digitals%20and%20the%20implied%20density/06-digital-inverses-vol-and-strike.md)

[↑ Back to the shelves](#top)

<a name="s11"></a>

## 11 · Implied volatility and the vanilla inverses · 5 cards

*Running the vanilla formula backwards: implied volatility (existence, uniqueness, the solver and its conditioning), strike from a delta quote, strike or spot from a target premium, and the forward and dividend yield implied by parity.*

1. [Implied volatility: the one volatility that makes the formula match the quote](11-Implied%20volatility%20and%20the%20vanilla%20inverses/01-implied-volatility.md)
2. [Solving for implied volatility: Newton steered by vega, bisection as the safety net, and when the answer is fuzzy](11-Implied%20volatility%20and%20the%20vanilla%20inverses/02-implied-volatility-by-newton-and-bisection.md)
3. [Strike from delta: turning a delta quote back into a strike](11-Implied%20volatility%20and%20the%20vanilla%20inverses/03-strike-from-delta.md)
4. [Strike or spot from a target premium: which strike makes the option cost what you can pay](11-Implied%20volatility%20and%20the%20vanilla%20inverses/04-strike-or-spot-from-a-target-premium.md)
5. [Implied forward and dividend from parity: a call-put pair tells you the forward, and the forward tells you the yield](11-Implied%20volatility%20and%20the%20vanilla%20inverses/05-implied-forward-and-dividend-from-parity.md)

[↑ Back to the shelves](#top)

<a name="s12"></a>

## 12 · The smile and the surface · 5 cards

*Why implied vol varies with strike and expiry, how to measure skew and term structure, forward volatility between two expiries, the surface grid and its butterfly and calendar arbitrage tests, the SVI fit, and how the hedge changes once the smile moves with spot.*

1. [The volatility smile and skew: one price per strike means one volatility per strike, and why that is not a mistake](12-The%20smile%20and%20the%20surface/01-volatility-smile-and-skew.md)
2. [Term structure and forward volatility: total variance adds, so two expiries imply the vol in between](12-The%20smile%20and%20the%20surface/02-term-structure-and-forward-volatility.md)
3. [The volatility surface: a grid of vols in strike and expiry, and the two tests that keep it honest](12-The%20smile%20and%20the%20surface/03-volatility-surface-and-its-arbitrage-rules.md)
4. [The SVI smile: five numbers that fit one expiry, and the constraints that keep it arbitrage-free](12-The%20smile%20and%20the%20surface/04-svi-smile-fit.md)
5. [Smile-adjusted delta: when vol moves with spot, the hedge ratio is not the Black-Scholes delta](12-The%20smile%20and%20the%20surface/05-smile-adjusted-delta.md)

[↑ Back to the shelves](#top)

<a name="s13"></a>

## 13 · Local volatility and jumps · 5 cards

*Dupire's local volatility read off a surface (from prices and from implied vols), pricing under it and its flat forward smile, then Merton's jump-diffusion as the first model that makes a smile on its own, with its Greeks, hedge error and calibration.*

1. [Dupire local volatility: one volatility per price and date, read straight off call prices](13-Local%20volatility%20and%20jumps/01-dupire-local-volatility.md)
2. [Local volatility in implied-vol terms: the version you can compute from quotes, and the twice-the-skew rule](13-Local%20volatility%20and%20jumps/02-local-volatility-from-implied-volatility.md)
3. [Pricing with local volatility: it reprices every vanilla exactly, then predicts a future smile that is too flat](13-Local%20volatility%20and%20jumps/03-pricing-under-local-volatility-and-the-forward-smile.md)
4. [Merton jump-diffusion: add sudden gaps, and the price is a weighted sum of Black-Scholes prices](13-Local%20volatility%20and%20jumps/04-merton-jump-diffusion.md)
5. [Greeks under jumps: the delta hedge that cannot be perfect, and fitting the three jump numbers to the smile](13-Local%20volatility%20and%20jumps/05-merton-greeks-hedge-error-and-calibration.md)

[↑ Back to the shelves](#top)

<a name="s14"></a>

## 14 · Stochastic volatility: Heston, SABR and their mix · 6 cards

*Heston's wandering variance (dynamics, the characteristic-function price, Greeks and calibration), SABR with Hagan's implied-vol formula and its three-quote calibration, and the stochastic-local mix desks use to fit vanillas exactly while keeping forward smiles.*

1. [The Heston model: variance that wanders and is pulled home, and which dial does what to the smile](14-Stochastic%20volatility%20-%20Heston%2C%20SABR%20and%20their%20mix/01-heston-model.md)
2. [Pricing Heston exactly: the closed-form fingerprint and the one integral that turns it into a price](14-Stochastic%20volatility%20-%20Heston%2C%20SABR%20and%20their%20mix/02-heston-pricing-by-characteristic-function.md)
3. [Heston Greeks and calibration: sensitivities from the integral, and five parameters from a surface](14-Stochastic%20volatility%20-%20Heston%2C%20SABR%20and%20their%20mix/03-heston-greeks-and-calibration.md)
4. [SABR and Hagan's formula: a stochastic-vol model whose implied volatility you can write down](14-Stochastic%20volatility%20-%20Heston%2C%20SABR%20and%20their%20mix/04-sabr-model-and-hagan-formula.md)
5. [SABR from three quotes: alpha from the ATM vol, rho and nu from the wings, and where the formula breaks](14-Stochastic%20volatility%20-%20Heston%2C%20SABR%20and%20their%20mix/05-sabr-calibration-from-three-quotes.md)
6. [Stochastic-local volatility: a leverage function that makes a stochastic-vol model reprice every vanilla](14-Stochastic%20volatility%20-%20Heston%2C%20SABR%20and%20their%20mix/06-stochastic-local-volatility.md)

[↑ Back to the shelves](#top)

<a name="s15"></a>

## 15 · American and Bermudan exercise · 7 cards

*Options you may exercise early: what the price is, the tree that finds it, Merton's theorem for calls, Bermudan dates, the exercise boundary and smooth pasting, the perpetual put's closed form, the Barone-Adesi-Whaley shortcut, and the Greeks and implied volatility of an American option.*

1. [American options: exercise any day, so the price is the best stopping rule, found by working backwards](15-American%20and%20Bermudan%20exercise/01-american-options-and-early-exercise.md)
2. [Merton's theorem: never exercise a call early on a share that pays nothing, and the two places the rule stops](15-American%20and%20Bermudan%20exercise/02-mertons-no-early-exercise-theorem.md)
3. [Bermudan options: exercise on listed dates only, sitting between European and American](15-American%20and%20Bermudan%20exercise/03-bermudan-options.md)
4. [The exercise boundary and smooth pasting: where to stop waiting, pinned by matching height and slope](15-American%20and%20Bermudan%20exercise/04-exercise-boundary-and-smooth-pasting.md)
5. [The perpetual American put: the one American option with an exact answer, and the boundary it hands you](15-American%20and%20Bermudan%20exercise/05-perpetual-american-put.md)
6. [Barone-Adesi-Whaley: an American price in a microsecond by bolting one lump onto the European price](15-American%20and%20Bermudan%20exercise/06-barone-adesi-whaley-approximation.md)
7. [American Greeks and implied volatility: sensitivities off the tree, a delta that hits -1, and a unique implied vol](15-American%20and%20Bermudan%20exercise/07-american-greeks-and-implied-volatility.md)

[↑ Back to the shelves](#top)

<a name="s16"></a>

## 16 · Barriers, touches and lookbacks · 7 cards

*Options that depend on the running maximum or minimum: knock-outs and knock-ins with in-out parity, the eight closed forms, the daily-monitoring correction, the hedge at the wall, one-touch and no-touch bets, lookbacks, and the inverses (barrier level from a premium; the volatility that is not unique).*

1. [Knock-out and knock-in options: a contract that dies or is born the first time the share touches a line](16-Barriers%2C%20touches%20and%20lookbacks/01-knock-out-and-knock-in-options.md)
2. [The eight barrier formulas: up or down, in or out, call or put, all from the same six building blocks](16-Barriers%2C%20touches%20and%20lookbacks/02-reiner-rubinstein-barrier-formulas.md)
3. [Daily monitoring: a barrier checked once a day is worth more than the continuous formula says, and the fix is a shifted barrier](16-Barriers%2C%20touches%20and%20lookbacks/03-discrete-monitoring-correction.md)
4. [Barrier Greeks: a delta that explodes at the wall and a vega that changes sign](16-Barriers%2C%20touches%20and%20lookbacks/04-barrier-greeks-at-the-wall.md)
5. [One-touch and no-touch: a fixed sum if the line is ever reached, priced from the chance of touching](16-Barriers%2C%20touches%20and%20lookbacks/05-one-touch-and-no-touch.md)
6. [Lookback options: buy at the lowest, sell at the highest, and what never regretting costs](16-Barriers%2C%20touches%20and%20lookbacks/06-lookback-options.md)
7. [Barrier inverses: the barrier level from a premium is unique, the volatility from a knock-out price is not](16-Barriers%2C%20touches%20and%20lookbacks/07-barrier-inverses-level-and-volatility.md)

[↑ Back to the shelves](#top)

<a name="s17"></a>

## 17 · Averages, choosers, compounds and forward-starts · 7 cards

*Asian options (geometric closed form first, then arithmetic by simulation steered by it, then their Greeks and implied vol), choosers, compound options, forward-start options and the forward volatility they imply, and cliquets built from them.*

1. [The geometric Asian call: an average that stays lognormal, so Black-Scholes prices it with a smaller vol and a slower drift](17-Averages%2C%20choosers%2C%20compounds%20and%20forward-starts/01-geometric-asian-kemna-vorst.md)
2. [Arithmetic Asian options: the average everyone trades has no formula, so simulate and let the geometric twin steer](17-Averages%2C%20choosers%2C%20compounds%20and%20forward-starts/02-arithmetic-asian-options.md)
3. [Asian Greeks and implied volatility: averaging is a sedative, and the fixings already in are a fixed amount](17-Averages%2C%20choosers%2C%20compounds%20and%20forward-starts/03-asian-greeks-and-implied-volatility.md)
4. [Chooser options: decide later whether it is a call or a put, and parity prices it today](17-Averages%2C%20choosers%2C%20compounds%20and%20forward-starts/04-chooser-options.md)
5. [Compound options: an option on an option, priced with a two-dimensional bell curve](17-Averages%2C%20choosers%2C%20compounds%20and%20forward-starts/05-compound-options.md)
6. [Forward-start options: a strike fixed later, so the price is shares times a unit option, and it pays on the forward vol](17-Averages%2C%20choosers%2C%20compounds%20and%20forward-starts/06-forward-start-options-and-forward-volatility.md)
7. [Cliquets: a chain of forward-starts with local caps and a global floor, and why the forward smile prices it](17-Averages%2C%20choosers%2C%20compounds%20and%20forward-starts/07-cliquets-and-ratchets.md)

[↑ Back to the shelves](#top)

<a name="s18"></a>

## 18 · Many underlyings: exchange, spread, basket and rainbow · 5 cards

*Options on two or more shares: Margrabe's exchange option where rates drop out, spread options by Kirk against simulation, baskets by moment matching against simulation, best-of and worst-of rainbows, and correlation as the input with its own Greeks and implied value.*

1. [The exchange option: the right to swap one share for another, priced with no interest rate at all](18-Many%20underlyings%20-%20exchange%2C%20spread%2C%20basket%20and%20rainbow/01-exchange-option-margrabe.md)
2. [Spread options: an option on the difference of two prices, with Kirk's shortcut and a simulation to keep it honest](18-Many%20underlyings%20-%20exchange%2C%20spread%2C%20basket%20and%20rainbow/02-spread-options-and-kirk.md)
3. [Basket options: one option on a weighted group of shares, where correlation is the input that matters](18-Many%20underlyings%20-%20exchange%2C%20spread%2C%20basket%20and%20rainbow/03-basket-options.md)
4. [Rainbow options: pay on the best or the worst of several shares, and the correlation sign flips between them](18-Many%20underlyings%20-%20exchange%2C%20spread%2C%20basket%20and%20rainbow/04-rainbow-best-of-and-worst-of.md)
5. [Correlation Greeks and implied correlation: the sensitivity nobody can hedge directly, and the number an index option implies](18-Many%20underlyings%20-%20exchange%2C%20spread%2C%20basket%20and%20rainbow/05-correlation-greeks-and-implied-correlation.md)

[↑ Back to the shelves](#top)

<a name="s19"></a>

## 19 · Variance swaps, the log contract and VIX · 6 cards

*Volatility as a thing you can trade: realised variance from daily prices, any payoff from a strip of options (Carr-Madan) with the log contract as the case that matters, the variance swap's model-free fair strike, marking it after inception with forward variance, the volatility swap's convexity and the jump bias, and the VIX recipe.*

1. [Realised variance: add up squared daily returns, annualise, and know what the number is estimating](19-Variance%20swaps%2C%20the%20log%20contract%20and%20VIX/01-realised-variance-from-daily-prices.md)
2. [Any payoff from a strip of options: integrate by parts twice, and the log contract is the case that trades variance](19-Variance%20swaps%2C%20the%20log%20contract%20and%20VIX/02-carr-madan-spanning-and-the-log-contract.md)
3. [The variance swap: pay realised variance, receive a fixed strike, and the strike comes from the option strip with no model](19-Variance%20swaps%2C%20the%20log%20contract%20and%20VIX/03-variance-swap-fair-strike.md)
4. [Marking a variance swap: accrued realised plus the remaining forward variance, and the forward variance two expiries imply](19-Variance%20swaps%2C%20the%20log%20contract%20and%20VIX/04-variance-swap-after-inception-and-forward-variance.md)
5. [The volatility swap and the jump bias: why a swap on vol is worth less than the root of the variance strike, and why gaps break the strip](19-Variance%20swaps%2C%20the%20log%20contract%20and%20VIX/05-volatility-swap-and-jump-bias.md)
6. [The VIX: the published recipe that turns listed index options into a thirty-day volatility number](19-Variance%20swaps%2C%20the%20log%20contract%20and%20VIX/06-vix-index.md)

[↑ Back to the shelves](#top)

<a name="s20"></a>

## 20 · FX spot, forwards and interest parity · 5 cards

*Reading a currency quote and building crosses; the forward from two interest rates by cash-and-carry with both arbitrage ledgers; forward points and the FX swap; marking an old forward in either currency; the inverse (the rate a forward implies) and the cross-currency basis where parity visibly fails.*

1. [Reading a currency quote: which currency is the price, which is the thing, and how to flip and cross it](20-FX%20spot%2C%20forwards%20and%20interest%20parity/01-currency-quotes-and-cross-rates.md)
2. [Covered interest parity: the forward exchange rate from today's rate and the two interest rates](20-FX%20spot%2C%20forwards%20and%20interest%20parity/02-covered-interest-parity.md)
3. [Forward points and the FX swap: the forward quoted as pips over spot, and the trade that carries them](20-FX%20spot%2C%20forwards%20and%20interest%20parity/03-forward-points-and-fx-swaps.md)
4. [Valuing an old currency forward: the gap to today's forward, discounted, in whichever currency you count](20-FX%20spot%2C%20forwards%20and%20interest%20parity/04-fx-forward-value-after-inception.md)
5. [The interest rate a forward implies: parity run backwards, and the cross-currency basis where the market says no](20-FX%20spot%2C%20forwards%20and%20interest%20parity/05-implied-yield-and-cross-currency-basis.md)

[↑ Back to the shelves](#top)

<a name="s21"></a>

## 21 · FX vanilla options: Garman-Kohlhagen and the desk conventions · 7 cards

*Pricing a currency call and put; the same option seen from the other currency and the four premium quotes; its Greeks with one rho per currency; the four deltas and three at-the-money definitions FX desks use; and the two inverses, strike from delta and vol from premium.*

1. [Garman-Kohlhagen: pricing a currency option by treating foreign cash as a share that pays the foreign rate](21-FX%20vanilla%20options%20-%20Garman-Kohlhagen%20and%20the%20desk%20conventions/01-garman-kohlhagen.md)
2. [One option, two currencies: the same contract seen from the other side, and the four ways its premium is quoted](21-FX%20vanilla%20options%20-%20Garman-Kohlhagen%20and%20the%20desk%20conventions/02-premium-currency-and-foreign-domestic-symmetry.md)
3. [The Greeks of a currency option: delta in euros, gamma and vega in dollars, and one rho for each currency](21-FX%20vanilla%20options%20-%20Garman-Kohlhagen%20and%20the%20desk%20conventions/03-garman-kohlhagen-greeks.md)
4. [Four deltas for one option: spot, forward, and premium-adjusted, and which one a currency desk means](21-FX%20vanilla%20options%20-%20Garman-Kohlhagen%20and%20the%20desk%20conventions/04-fx-delta-conventions.md)
5. [Three meanings of at-the-money: spot, forward, and the delta-neutral straddle the FX market actually uses](21-FX%20vanilla%20options%20-%20Garman-Kohlhagen%20and%20the%20desk%20conventions/05-at-the-money-conventions.md)
6. [Strike from delta: turning a delta-quoted option into a strike you can price](21-FX%20vanilla%20options%20-%20Garman-Kohlhagen%20and%20the%20desk%20conventions/06-fx-strike-from-delta.md)
7. [Implied vol for a currency option: from a premium in any quote to the one vol, and the bounds that say when none exists](21-FX%20vanilla%20options%20-%20Garman-Kohlhagen%20and%20the%20desk%20conventions/07-fx-implied-volatility.md)

[↑ Back to the shelves](#top)

<a name="s22"></a>

## 22 · The FX smile: risk reversals, butterflies and vanna-volga · 6 cards

*How currency desks quote a smile as level, tilt and curvature; the market-strangle subtlety; vanna and volga as the smile's own Greeks; the vanna-volga price and the vanna-volga smile curve; how the smile moves with spot and what that does to the delta hedge.*

1. [Risk reversal and butterfly: quoting a smile as its tilt and its curvature, and turning the quotes back into three vols](22-The%20FX%20smile%20-%20risk%20reversals%2C%20butterflies%20and%20vanna-volga/01-risk-reversal-and-butterfly.md)
2. [The broker butterfly: a strangle quoted at one vol, and the one-unknown solve that turns it into smile vols](22-The%20FX%20smile%20-%20risk%20reversals%2C%20butterflies%20and%20vanna-volga/02-market-strangle-and-smile-strangle.md)
3. [Vanna and volga: the two second-order vol Greeks, and why the risk reversal trades vanna and the butterfly trades volga](22-The%20FX%20smile%20-%20risk%20reversals%2C%20butterflies%20and%20vanna-volga/03-vanna-and-volga-on-the-smile.md)
4. [Vanna-volga pricing: charge for the three vol risks Black-Scholes cannot see, using the three quotes the market gives you](22-The%20FX%20smile%20-%20risk%20reversals%2C%20butterflies%20and%20vanna-volga/04-vanna-volga-pricing.md)
5. [The vanna-volga smile: a closed-form vol at any strike from three pillars, and where it breaks in the wings](22-The%20FX%20smile%20-%20risk%20reversals%2C%20butterflies%20and%20vanna-volga/05-vanna-volga-smile-curve.md)
6. [Hedging with the smile: sticky delta in FX, and the vega term that corrects the delta](22-The%20FX%20smile%20-%20risk%20reversals%2C%20butterflies%20and%20vanna-volga/06-smile-adjusted-delta-and-sticky-delta.md)

[↑ Back to the shelves](#top)

<a name="s23"></a>

## 23 · FX exotics as desks use them: digitals, touches and barriers · 8 cards

*Digitals paying in either currency with the smile's slope; single barriers by reflection and the full eight-type table with rebates; one-touch and no-touch; double barriers and the double no-touch; the Greeks that blow up at the wall; the survival-weighted smile correction; and the inverses: barrier level from a budget, touch level from a price.*

1. [Currency digitals: a fixed payout in dollars or in euros, priced as a discounted probability and corrected for the smile's slope](23-FX%20exotics%20as%20desks%20use%20them%20-%20digitals%2C%20touches%20and%20barriers/01-fx-digitals.md)
2. [Knock-out and knock-in: the plain option minus its mirror image, and knock-in plus knock-out equals the plain option](23-FX%20exotics%20as%20desks%20use%20them%20-%20digitals%2C%20touches%20and%20barriers/02-barrier-options-by-reflection.md)
3. [The eight single barriers in one table: up or down, in or out, call or put, with rebates, from six building blocks](23-FX%20exotics%20as%20desks%20use%20them%20-%20digitals%2C%20touches%20and%20barriers/03-the-eight-barrier-types.md)
4. [One-touch and no-touch: a fixed payout on whether a level ever trades, priced from the chance of a first touch](23-FX%20exotics%20as%20desks%20use%20them%20-%20digitals%2C%20touches%20and%20barriers/04-fx-one-touch-and-no-touch.md)
5. [Two walls: double knock-outs and the double no-touch, priced by a sum of images that converges in a handful of terms](23-FX%20exotics%20as%20desks%20use%20them%20-%20digitals%2C%20touches%20and%20barriers/05-double-barriers-and-double-no-touch.md)
6. [Greeks at the wall: delta past one, gamma turning negative, vega flipping sign, and how desks bend the barrier to survive it](23-FX%20exotics%20as%20desks%20use%20them%20-%20digitals%2C%20touches%20and%20barriers/06-barrier-and-touch-greeks.md)
7. [Barriers on a smile: vanna-volga weighted by the chance of survival, and where it stops being enough](23-FX%20exotics%20as%20desks%20use%20them%20-%20digitals%2C%20touches%20and%20barriers/07-barriers-with-the-smile.md)
8. [Solving for the barrier: the knock-out level that makes the option cost what the client will pay, and the touch level a price implies](23-FX%20exotics%20as%20desks%20use%20them%20-%20digitals%2C%20touches%20and%20barriers/08-barrier-level-from-a-target-premium.md)

[↑ Back to the shelves](#top)

<a name="s24"></a>

## 24 · Quantos and composites · 5 cards

*A foreign asset paid in home money at a fixed rate: the quanto forward and its drift correction, the quanto option, its Greeks including correlation sensitivity and the self-resizing currency hedge, the composite option (the same asset in home currency at the market rate), and the inverse: correlation from a quanto quote.*

1. [The quanto adjustment: a foreign price paid in home money at a fixed rate drifts slower by correlation times two vols](24-Quantos%20and%20composites/01-quanto-forward-and-adjustment.md)
2. [Quanto option: Black-Scholes on the foreign share with its drift slowed, discounted at home, times the fixed rate](24-Quantos%20and%20composites/02-quanto-option.md)
3. [Hedging a quanto: shares in euros, a currency hedge that resizes itself, and the Greek nobody else has, sensitivity to correlation](24-Quantos%20and%20composites/03-quanto-greeks-and-hedging.md)
4. [Composite option: the foreign share priced in your currency at the market rate, so the vol is the vol of a product](24-Quantos%20and%20composites/04-composite-option.md)
5. [Correlation from a quanto price: the one input you cannot see, solved backwards, and the range where a solution exists](24-Quantos%20and%20composites/05-implied-correlation-from-a-quanto.md)

[↑ Back to the shelves](#top)

<a name="s25"></a>

## 25 · Commodity forwards: carry, storage, convenience yield and the curve · 6 cards

*The forward for a commodity you can borrow (gold) and one you cannot (wheat, oil); storage as negative income; why the reverse trade fails so carry gives a ceiling, not an equality; the convenience yield read backwards from the market; contango, backwardation and the roll; seasonal gas curves; and the mean-reverting spot model that shapes a futures strip.*

1. [Gold forward: spot grown at interest minus the lease rate, exact because gold can be borrowed like a currency](25-Commodity%20forwards%20-%20carry%2C%20storage%2C%20convenience%20yield%20and%20the%20curve/01-gold-forward-and-the-lease-rate.md)
2. [Storage and the carry ceiling: for grain and oil the forward can sit below spot plus carry, never above it](25-Commodity%20forwards%20-%20carry%2C%20storage%2C%20convenience%20yield%20and%20the%20curve/02-storage-cost-and-the-carry-ceiling.md)
3. [Convenience yield: the number that makes the carry formula hit the market forward, and what it says about scarcity](25-Commodity%20forwards%20-%20carry%2C%20storage%2C%20convenience%20yield%20and%20the%20curve/03-convenience-yield-implied-by-the-forward.md)
4. [Contango and backwardation: reading a futures strip, and the roll that pays or bleeds a long-only holder](25-Commodity%20forwards%20-%20carry%2C%20storage%2C%20convenience%20yield%20and%20the%20curve/04-contango-backwardation-and-roll-yield.md)
5. [Seasonal curves: natural gas forwards that hump every winter, and the storage trade that keeps summer-to-winter spreads bounded](25-Commodity%20forwards%20-%20carry%2C%20storage%2C%20convenience%20yield%20and%20the%20curve/05-seasonality-and-the-gas-curve.md)
6. [A spot price that reverts: the Schwartz one-factor model, its futures formula, and why long-dated futures barely move](25-Commodity%20forwards%20-%20carry%2C%20storage%2C%20convenience%20yield%20and%20the%20curve/06-mean-reverting-spot-and-the-futures-curve.md)

[↑ Back to the shelves](#top)

<a name="s26"></a>

## 26 · Options on commodity futures and spreads · 7 cards

*Black-76 applied to a futures option with its two expiry dates and margined premium; the Greeks in lots with rho equal to minus time times price; implied vol and the upward commodity skew with Samuelson decay; spread options by Margrabe and Kirk with their Greeks and the implied correlation; electricity, where carry fails and the spark spread is an option on a power plant.*

1. [Options on a futures price: Black-76 with the future as underlying, the spot nowhere, and two expiry dates to keep apart](26-Options%20on%20commodity%20futures%20and%20spreads/01-options-on-commodity-futures.md)
2. [Greeks of a futures option: delta in contracts not barrels, rho that is minus time times price, and vega per vol point per lot](26-Options%20on%20commodity%20futures%20and%20spreads/02-futures-option-greeks.md)
3. [Implied vol on a futures option and the commodity smile: an upward skew for oil and gas, and vol that fades with maturity](26-Options%20on%20commodity%20futures%20and%20spreads/03-commodity-implied-vol-and-the-call-skew.md)
4. [Spread options: exchanging one price for another with Margrabe's exact formula, and Kirk's shortcut when there is a strike](26-Options%20on%20commodity%20futures%20and%20spreads/04-margrabe-and-kirk-spread-options.md)
5. [Greeks of a spread option: a delta for each leg, a cross gamma, two vegas, and the sensitivity to correlation](26-Options%20on%20commodity%20futures%20and%20spreads/05-spread-option-greeks.md)
6. [Correlation from a spread option: the market's number for how two prices move together, and when no number fits](26-Options%20on%20commodity%20futures%20and%20spreads/06-implied-correlation-from-a-spread-option.md)
7. [Power that cannot be stored: why carry fails, hourly shapes and spikes, and the spark spread as an option on a power plant](26-Options%20on%20commodity%20futures%20and%20spreads/07-electricity-and-the-spark-spread.md)

[↑ Back to the shelves](#top)

<a name="s27"></a>

## 27 · Averages: commodity swaps and Asian options · 5 cards

*The commodity swap as a strip of average-price forwards; the geometric Asian with an exact price; the arithmetic Asian desks trade, by moment matching and by controlled simulation; Asian Greeks and the seasoned average; and the inverse, implied vol from an Asian quote.*

1. [Commodity swap: a fixed price against the monthly average, priced as a strip of forwards with no option in it](27-Averages%20-%20commodity%20swaps%20and%20Asian%20options/01-commodity-swap-and-average-price-forward.md)
2. [Kemna-Vorst: the Asian option with an exact price, because a geometric average of lognormals is lognormal](27-Averages%20-%20commodity%20swaps%20and%20Asian%20options/02-kemna-vorst-geometric-asian.md)
3. [The Asian option desks trade: no exact formula, so match two moments and let the geometric twin steer the simulation](27-Averages%20-%20commodity%20swaps%20and%20Asian%20options/03-arithmetic-asian-option.md)
4. [Asian Greeks and the average already banked: damped delta and vega, and the strike that shrinks as fixings come in](27-Averages%20-%20commodity%20swaps%20and%20Asian%20options/04-asian-greeks-and-the-running-average.md)
5. [Implied vol from an Asian quote: invert the moment-matched price, and why it is not the vanilla's vol](27-Averages%20-%20commodity%20swaps%20and%20Asian%20options/05-asian-implied-volatility.md)

[↑ Back to the shelves](#top)

<a name="s28"></a>

## 28 · Swaps · 7 cards

*Fixed-for-floating swaps, their value, their hedge numbers, and the multi-curve world they live in*

1. [Interest rate swaps: fixed for floating, valued as two bonds or as a strip of forwards](28-Swaps/01-interest-rate-swaps.md)
2. [The par swap rate: the fixed rate that makes a new swap worth zero, and the annuity it divides by](28-Swaps/02-par-swap-rate-and-annuity.md)
3. [Swap DV01: the value change for one basis point, and hedging one swap with another](28-Swaps/03-swap-dv01-and-hedging.md)
4. [Multi-curve: one curve to forecast, another to discount, and the basis between them](28-Swaps/04-basis-swaps-and-the-multi-curve-framework.md)
5. [Collateral discounting: why a collateralised swap discounts at the overnight rate](28-Swaps/05-ois-discounting-and-collateral.md)
6. [Cross-currency swaps: exchanging notionals and the basis spread the market charges](28-Swaps/06-cross-currency-swaps-and-basis.md)
7. [Solving a swap backwards: the fixed rate from a value, and a curve point from a par quote](28-Swaps/07-swap-inverses-rate-and-curve-from-price.md)

[↑ Back to the shelves](#top)

<a name="s29"></a>

## 29 · Caps, Floors and Swaptions · 9 cards

*Options on rates: the Black formulas, the measures that justify them, the volatility conventions and the inverses*

1. [Caplets and floorlets: a call or put on one forward rate, priced with Black-76 under the forward measure](29-Caps%2C%20Floors%20and%20Swaptions/01-caplets-and-floorlets.md)
2. [Caps and floors: strips of caplets, and the parity that ties a cap, a floor and a swap](29-Caps%2C%20Floors%20and%20Swaptions/02-caps-floors-and-parity.md)
3. [Caplet stripping: recovering each caplet's volatility from cap quotes](29-Caps%2C%20Floors%20and%20Swaptions/03-caplet-stripping.md)
4. [Swaptions: the right to enter a swap, priced with Black on the forward swap rate](29-Caps%2C%20Floors%20and%20Swaptions/04-swaptions-payer-and-receiver.md)
5. [The annuity measure: why the forward swap rate is a martingale when the annuity is the unit](29-Caps%2C%20Floors%20and%20Swaptions/05-the-annuity-measure.md)
6. [Rate volatilities: lognormal, normal and shifted, and converting between them](29-Caps%2C%20Floors%20and%20Swaptions/06-normal-and-shifted-volatilities-for-rates.md)
7. [SABR for rates: the smile across strikes, expiries and tenors](29-Caps%2C%20Floors%20and%20Swaptions/07-sabr-for-rates-and-the-volatility-cube.md)
8. [Swaption Greeks: delta in swaps, vega in the cube, and the annuity's own sensitivity](29-Caps%2C%20Floors%20and%20Swaptions/08-swaption-greeks-and-hedging.md)
9. [Solving rate options backwards: implied volatility, strike from delta, and rate from price](29-Caps%2C%20Floors%20and%20Swaptions/09-rate-option-inverses.md)

[↑ Back to the shelves](#top)

<a name="s30"></a>

## 30 · Short-Rate Models · 8 cards

*Models of the overnight rate: closed-form bonds, options on bonds, trees, and how to calibrate them*

1. [A short-rate model: one random rate, and the equation every bond must satisfy](30-Short-Rate%20Models/01-the-term-structure-equation.md)
2. [Vasicek: a mean-reverting normal rate with closed-form bonds](30-Short-Rate%20Models/02-vasicek-model.md)
3. [Cox-Ingersoll-Ross: square-root noise that keeps the rate positive](30-Short-Rate%20Models/03-cox-ingersoll-ross-model.md)
4. [Hull-White: Vasicek with a time-dependent drift that fits today's curve exactly](30-Short-Rate%20Models/04-hull-white-model.md)
5. [Bond options: a call on a zero in closed form, and a coupon-bond option as a portfolio of them](30-Short-Rate%20Models/05-bond-options-and-jamshidians-trick.md)
6. [The Hull-White tree: a trinomial lattice for the short rate that handles any payoff](30-Short-Rate%20Models/06-hull-white-trinomial-tree.md)
7. [Beyond one factor: G2++, Black-Karasinski and Black-Derman-Toy in outline](30-Short-Rate%20Models/07-two-factor-and-lognormal-short-rate-models.md)
8. [Calibrating Hull-White: reversion and volatility from swaptions](30-Short-Rate%20Models/08-calibrating-a-short-rate-model.md)

[↑ Back to the shelves](#top)

<a name="s31"></a>

## 31 · Forward-Rate Models · 6 cards

*Modelling the whole curve: HJM, forward measures, and the market models banks calibrate*

1. [Heath-Jarrow-Morton: model the forward curve and let no-arbitrage fix the drift](31-Forward-Rate%20Models/01-hjm-framework-and-the-drift-condition.md)
2. [Forward measures: a bond as the unit makes its forward rate a martingale](31-Forward-Rate%20Models/02-forward-measures-for-rates.md)
3. [Market models: lognormal forward rates, the drift under one terminal measure, and simulation](31-Forward-Rate%20Models/03-libor-and-sofr-market-models.md)
4. [Calibrating a market model: caplet volatilities exactly, swaptions approximately](31-Forward-Rate%20Models/04-calibrating-a-market-model.md)
5. [Swap market model: lognormal swap rates instead of forwards, and why you cannot have both](31-Forward-Rate%20Models/05-swap-market-model-in-outline.md)
6. [Bermudan swaptions: many exercise dates, priced by regression on simulated curves](31-Forward-Rate%20Models/06-bermudan-swaptions-by-regression.md)

[↑ Back to the shelves](#top)

<a name="s32"></a>

## 32 · Convexity and Exotics · 6 cards

*Where a payoff and its natural measure disagree, and the products that live in that gap*

1. [Futures against forwards: the convexity that makes a rate future differ from an FRA](32-Convexity%20and%20Exotics/01-futures-forward-convexity.md)
2. [Constant-maturity swaps: paying a swap rate on the wrong date, and the replication that prices it](32-Convexity%20and%20Exotics/02-cms-and-the-convexity-adjustment.md)
3. [Timing adjustments: rates paid at the start of the period instead of the end](32-Convexity%20and%20Exotics/03-timing-and-in-arrears-adjustments.md)
4. [Quanto rates: a foreign rate paid in domestic currency](32-Convexity%20and%20Exotics/04-quanto-adjustments-for-rates.md)
5. [Callable and cancellable swaps: a swap plus a Bermudan swaption](32-Convexity%20and%20Exotics/05-callable-and-cancellable-swaps.md)
6. [Structured rate notes: range accruals, inverse floaters and target redemption, in outline](32-Convexity%20and%20Exotics/06-structured-notes-in-outline.md)

[↑ Back to the shelves](#top)

<a name="s33"></a>

## 33 · Curves in Depth · 6 cards

*Reading, hedging and forecasting a whole curve*

1. [Level, slope and curvature: the three moves that explain almost every curve change](33-Curves%20in%20Depth/01-principal-components-of-the-curve.md)
2. [Key-rate durations: sensitivity to each pillar, and hedging a bond book against the whole curve](33-Curves%20in%20Depth/02-key-rate-durations-and-curve-hedging.md)
3. [Fitting a curve with four or six parameters: Nelson-Siegel and Svensson](33-Curves%20in%20Depth/03-nelson-siegel-and-svensson-fitting.md)
4. [What a curve says: expectations, term premium, and why an inverted curve worries people](33-Curves%20in%20Depth/04-term-premium-and-expectations.md)
5. [Carry and roll-down: what a bond earns if the curve does not move](33-Curves%20in%20Depth/05-carry-and-roll-down.md)
6. [Negative rates: what breaks, what is floored, and which models survive](33-Curves%20in%20Depth/06-negative-rates-and-floors.md)

[↑ Back to the shelves](#top)

<a name="s34"></a>

## 34 · Inflation and Real Rates · 5 cards

*Real against nominal: the bonds, swaps and options that trade inflation*

1. [Real rates: nominal minus inflation, exactly and approximately](34-Inflation%20and%20Real%20Rates/01-real-rates-and-the-fisher-equation.md)
2. [Inflation-linked bonds: coupons and principal scaled by an index ratio](34-Inflation%20and%20Real%20Rates/02-inflation-linked-bonds.md)
3. [Breakeven inflation: the inflation rate at which a linker and a nominal bond tie](34-Inflation%20and%20Real%20Rates/03-breakeven-inflation.md)
4. [Inflation swaps: a fixed rate against realised inflation](34-Inflation%20and%20Real%20Rates/04-zero-coupon-inflation-swaps.md)
5. [Inflation caps and floors in outline: year-on-year options priced with a shifted Black formula](34-Inflation%20and%20Real%20Rates/05-inflation-options-in-outline.md)

[↑ Back to the shelves](#top)

<a name="s35"></a>

## 35 · Mortgages, Callables and Prepayment · 5 cards

*Bonds with embedded options: callables, mortgage-backed securities and the option-adjusted spread*

1. [Callable bonds: a bond minus a call option, and the yields quoted on them](35-Mortgages%2C%20Callables%20and%20Prepayment/01-callable-bonds-and-yield-to-worst.md)
2. [Mortgage pools: scheduled amortisation plus prepayment, and the cash flows they produce](35-Mortgages%2C%20Callables%20and%20Prepayment/02-mortgage-cash-flows-and-prepayment.md)
3. [Negative convexity: why a mortgage bond falls faster than it rises](35-Mortgages%2C%20Callables%20and%20Prepayment/03-negative-convexity.md)
4. [Option-adjusted spread: the spread over the curve after the embedded option is priced out](35-Mortgages%2C%20Callables%20and%20Prepayment/04-option-adjusted-spread.md)
5. [Mortgage-backed securities in outline: pass-throughs, tranches and interest-only strips](35-Mortgages%2C%20Callables%20and%20Prepayment/05-mortgage-backed-securities-in-outline.md)

[↑ Back to the shelves](#top)

<a name="s36"></a>

## 36 · Returns and Utility · 6 cards

*Measuring returns and deciding under uncertainty*

1. [Returns: simple, log, and annualised, and when they differ](36-Returns%20and%20Utility/01-returns-simple-log-and-annualised.md)
2. [Expected utility: why a sure 4 percent can beat a risky 8, and the number that says how much you mind risk](36-Returns%20and%20Utility/02-expected-utility-and-risk-aversion.md)
3. [Risk premium: what a gamble is worth to you, and the discount you demand for it](36-Returns%20and%20Utility/03-certainty-equivalent-and-risk-premium.md)
4. [Stochastic dominance: when one gamble beats another for every sensible investor](36-Returns%20and%20Utility/04-stochastic-dominance.md)
5. [Kelly: the bet size that grows wealth fastest, and why half of it is safer](36-Returns%20and%20Utility/05-kelly-criterion-and-growth.md)
6. [Prospect theory in outline: how people actually weigh gains, losses and small chances](36-Returns%20and%20Utility/06-prospect-theory-in-outline.md)

[↑ Back to the shelves](#top)

<a name="s37"></a>

## 37 · Portfolio Theory · 8 cards

*Combining assets: the frontier, the market line, betas, factors and the estimation problems that follow*

1. [Two assets: mean adds, variance does not, and correlation does the work](37-Portfolio%20Theory/01-two-asset-portfolio-risk-and-return.md)
2. [The efficient frontier: the least risk for each return, and the portfolio with the least risk of all](37-Portfolio%20Theory/02-efficient-frontier-and-minimum-variance.md)
3. [Adding a riskless asset: the tangency portfolio and the line every investor sits on](37-Portfolio%20Theory/03-tangency-portfolio-and-the-capital-market-line.md)
4. [CAPM: expected return as a reward for beta only](37-Portfolio%20Theory/04-capm-and-beta.md)
5. [Factor models: returns explained by a few common factors, and the pricing they imply](37-Portfolio%20Theory/05-factor-models-and-apt.md)
6. [Black-Litterman: starting from the market and tilting toward your views](37-Portfolio%20Theory/06-black-litterman.md)
7. [Estimation error: why optimised portfolios chase noise, and shrinkage that calms them](37-Portfolio%20Theory/07-estimation-error-and-shrinkage.md)
8. [Risk parity: equalising risk contributions instead of weights](37-Portfolio%20Theory/08-risk-parity-and-alternative-weightings.md)

[↑ Back to the shelves](#top)

<a name="s38"></a>

## 38 · Performance and Multi-Period · 5 cards

*Judging a track record and investing over a lifetime*

1. [Performance measures: Sharpe, information ratio, maximum drawdown, and their error bars](38-Performance%20and%20Multi-Period/01-sharpe-information-and-drawdown.md)
2. [Attribution: splitting a return into allocation, selection and interaction](38-Performance%20and%20Multi-Period/02-performance-attribution.md)
3. [Merton's problem: the constant share of wealth to keep in risky assets](38-Performance%20and%20Multi-Period/03-mertons-portfolio-problem.md)
4. [Rebalancing: how often, at what cost, and the no-trade band that answers both](38-Performance%20and%20Multi-Period/04-rebalancing-and-transaction-costs.md)
5. [Investing over a lifetime: sequence risk, safe withdrawal rates and glide paths](38-Performance%20and%20Multi-Period/05-life-cycle-and-glide-paths.md)

[↑ Back to the shelves](#top)

<a name="s39"></a>

## 39 · Value at Risk and Expected Shortfall · 8 cards

*One number for how bad a bad day is, three ways to compute it, and the better number that replaces it*

1. [Value at risk: the loss you exceed one day in a hundred](39-Value%20at%20Risk%20and%20Expected%20Shortfall/01-profit-and-loss-distribution-and-var.md)
2. [Parametric VaR: map the book to risk factors, assume normal, and use a covariance matrix](39-Value%20at%20Risk%20and%20Expected%20Shortfall/02-parametric-var-and-delta-normal.md)
3. [Historical and Monte Carlo VaR: replay the past, or simulate the future](39-Value%20at%20Risk%20and%20Expected%20Shortfall/03-historical-and-monte-carlo-var.md)
4. [Options in the book: the delta-gamma approximation and the Cornish-Fisher quantile](39-Value%20at%20Risk%20and%20Expected%20Shortfall/04-delta-gamma-var-and-cornish-fisher.md)
5. [Expected shortfall: the average loss beyond VaR, and why it adds up when VaR does not](39-Value%20at%20Risk%20and%20Expected%20Shortfall/05-expected-shortfall-and-coherence.md)
6. [Whose risk is it: marginal, incremental and component VaR by Euler's rule](39-Value%20at%20Risk%20and%20Expected%20Shortfall/06-var-decomposition-euler-and-component-var.md)
7. [Extreme value theory: modelling the tail beyond the data](39-Value%20at%20Risk%20and%20Expected%20Shortfall/07-extreme-value-theory-and-tails.md)
8. [Backtesting VaR: counting exceptions, and the tests that judge them](39-Value%20at%20Risk%20and%20Expected%20Shortfall/08-backtesting-var.md)

[↑ Back to the shelves](#top)

<a name="s40"></a>

## 40 · Hedging, Volatility Forecasts and Stress · 6 cards

*Greeks at the portfolio level, hedge ratios for imperfect hedges, volatility forecasts and stress scenarios*

1. [Portfolio Greeks: adding sensitivities across positions and predicting a day's P&L](40-Hedging%2C%20Volatility%20Forecasts%20and%20Stress/01-portfolio-greeks-and-taylor-pnl.md)
2. [Hedging three Greeks at once: solving for the option positions that flatten delta, gamma and vega](40-Hedging%2C%20Volatility%20Forecasts%20and%20Stress/02-delta-gamma-vega-hedging.md)
3. [Imperfect hedges: the minimum-variance hedge ratio and the basis risk that remains](40-Hedging%2C%20Volatility%20Forecasts%20and%20Stress/03-hedge-ratios-basis-risk-and-cross-hedging.md)
4. [Tomorrow's volatility: EWMA, GARCH and realised measures compared](40-Hedging%2C%20Volatility%20Forecasts%20and%20Stress/04-volatility-forecasting-ewma-garch-and-realised.md)
5. [Stress tests: spot-and-volatility grids, historical replays and hypothetical shocks](40-Hedging%2C%20Volatility%20Forecasts%20and%20Stress/05-scenario-grids-and-stress-tests.md)
6. [Limits: notional, sensitivity, VaR and drawdown limits, and the appetite statement behind them](40-Hedging%2C%20Volatility%20Forecasts%20and%20Stress/06-risk-limits-and-risk-appetite.md)

[↑ Back to the shelves](#top)

<a name="s41"></a>

## 41 · Default, Survival and the Hazard Rate · 5 cards

*Default probability, recovery and expected loss; the hazard rate and the survival curve it builds; piecewise-flat hazard curves; rating transition tables as the historical source of default rates; simulating a default time from any survival curve. Needs wing 01 discounting and logs, wing 03 matrix powers, wing 09 conditional probability and the exponential distribution.*

1. [Default probability, recovery and expected loss: the three numbers behind every credit loss](41-Default%2C%20Survival%20and%20the%20Hazard%20Rate/01-default-probability-recovery-and-expected-loss.md)
2. [The hazard rate: the chance of failing in the next instant given survival so far, and the survival curve it builds](41-Default%2C%20Survival%20and%20the%20Hazard%20Rate/02-hazard-rate-and-survival-probability.md)
3. [The piecewise-flat hazard curve: a handful of rates that give survival at every date](41-Default%2C%20Survival%20and%20the%20Hazard%20Rate/03-piecewise-flat-hazard-curve.md)
4. [Rating transition matrices: a one-year table of grade moves, and multi-year default chances by multiplying it](41-Default%2C%20Survival%20and%20the%20Hazard%20Rate/04-rating-transition-matrix-and-cumulative-default-rates.md)
5. [Simulating a default time: draw a uniform number and read it off the survival curve](41-Default%2C%20Survival%20and%20the%20Hazard%20Rate/05-simulating-a-default-time.md)

[↑ Back to the shelves](#top)

<a name="s42"></a>

## 42 · Credit Default Swaps: Pricing, the Par Spread and the Hazard Behind It · 9 cards

*The CDS contract and its conventions; the two legs, the risky annuity and the par spread; the credit triangle; implied hazard from one quote; recovery assumptions; bootstrapping a curve from several quotes; marking an old trade and the upfront convention; CDS risk numbers; market-implied versus historical default probability.*

1. [The credit default swap: insurance on a borrower, quoted as a spread, and who pays what when](42-Credit%20Default%20Swaps%20-%20Pricing%2C%20the%20Par%20Spread%20and%20the%20Hazard%20Behind%20It/01-credit-default-swap-contract.md)
2. [Pricing a CDS: the premium leg, the protection leg, the risky annuity, and the spread that makes them equal](42-Credit%20Default%20Swaps%20-%20Pricing%2C%20the%20Par%20Spread%20and%20the%20Hazard%20Behind%20It/02-cds-legs-risky-annuity-and-par-spread.md)
3. [The credit triangle: spread is about hazard times loss, the one-line bridge between a quote and a probability, and how far off it is](42-Credit%20Default%20Swaps%20-%20Pricing%2C%20the%20Par%20Spread%20and%20the%20Hazard%20Behind%20It/03-the-credit-triangle.md)
4. [Implied hazard from one CDS quote: solving the par-spread equation backwards, and why the answer is unique](42-Credit%20Default%20Swaps%20-%20Pricing%2C%20the%20Par%20Spread%20and%20the%20Hazard%20Behind%20It/04-implied-hazard-from-a-cds-quote.md)
5. [Recovery assumptions: one spread, many default probabilities, depending on what you assume you get back](42-Credit%20Default%20Swaps%20-%20Pricing%2C%20the%20Par%20Spread%20and%20the%20Hazard%20Behind%20It/05-recovery-assumptions-and-what-they-change.md)
6. [Bootstrapping a hazard curve: one tenor at a time, each quote fixing one flat piece](42-Credit%20Default%20Swaps%20-%20Pricing%2C%20the%20Par%20Spread%20and%20the%20Hazard%20Behind%20It/06-bootstrapping-the-hazard-curve-from-cds-quotes.md)
7. [Valuing an existing CDS: (par spread minus contract spread) times the risky annuity, and the fixed-coupon-plus-upfront convention](42-Credit%20Default%20Swaps%20-%20Pricing%2C%20the%20Par%20Spread%20and%20the%20Hazard%20Behind%20It/07-marking-a-cds-to-market-and-the-upfront.md)
8. [CDS risk numbers: CS01, jump-to-default, recovery and rate sensitivity, and the carry of a position](42-Credit%20Default%20Swaps%20-%20Pricing%2C%20the%20Par%20Spread%20and%20the%20Hazard%20Behind%20It/08-cds-risk-numbers.md)
9. [Two default probabilities: what history shows and what the market charges, and why both are right](42-Credit%20Default%20Swaps%20-%20Pricing%2C%20the%20Par%20Spread%20and%20the%20Hazard%20Behind%20It/09-market-implied-versus-historical-default-probability.md)

[↑ Back to the shelves](#top)

<a name="s43"></a>

## 43 · Structural Models: Default from the Balance Sheet · 6 cards

*Merton's equity-as-a-call, risky debt as safe debt minus a put, the credit spread and default probability that follow; the sensitivities of every claim; distance to default and the KMV default frequency; backing out asset value and volatility from the share price; Black-Cox first-passage default; where structural models fail and the patches.*

1. [Merton's model: equity is a call on the firm's assets, so risky debt is a safe bond minus a put](43-Structural%20Models%20-%20Default%20from%20the%20Balance%20Sheet/01-merton-model-equity-as-a-call.md)
2. [How the balance-sheet claims move: volatility helps shareholders and hurts lenders, leverage and time widen the spread](43-Structural%20Models%20-%20Default%20from%20the%20Balance%20Sheet/02-structural-model-sensitivities.md)
3. [Distance to default: how many standard deviations of bad luck the firm can absorb, and the KMV default frequency built on it](43-Structural%20Models%20-%20Default%20from%20the%20Balance%20Sheet/03-distance-to-default-and-expected-default-frequency.md)
4. [Backing out the unobservable: asset value and asset volatility from the share price and its volatility, two equations in two unknowns](43-Structural%20Models%20-%20Default%20from%20the%20Balance%20Sheet/04-asset-value-and-volatility-from-the-share-price.md)
5. [Black-Cox: default the first moment assets touch a barrier, and the reflection term Merton misses](43-Structural%20Models%20-%20Default%20from%20the%20Balance%20Sheet/05-black-cox-first-passage-default.md)
6. [Where structural models break: the vanishing short-term spread, jumps, and the patches that fix it](43-Structural%20Models%20-%20Default%20from%20the%20Balance%20Sheet/06-where-structural-models-fail.md)

[↑ Back to the shelves](#top)

<a name="s44"></a>

## 44 · Reduced-Form Models: Risky Bonds, Spreads and Random Hazards · 5 cards

*Pricing a coupon bond off the survival curve with either recovery convention; implied hazard from a bond price and the CDS-bond basis; a random, mean-reverting hazard and what it changes; the forward CDS; options on a CDS with Black's formula and implied spread volatility.*

1. [A risky bond from the hazard curve: survival-weighted coupons plus recovery on default](44-Reduced-Form%20Models%20-%20Risky%20Bonds%2C%20Spreads%20and%20Random%20Hazards/01-pricing-a-defaultable-bond-from-the-survival-curve.md)
2. [Implied hazard from a bond price, and why the CDS disagrees: the basis](44-Reduced-Form%20Models%20-%20Risky%20Bonds%2C%20Spreads%20and%20Random%20Hazards/02-implied-hazard-from-a-bond-price-and-the-cds-bond-basis.md)
3. [A random hazard: the Cox process, a mean-reverting intensity, and survival as the average of an exponential](44-Reduced-Form%20Models%20-%20Risky%20Bonds%2C%20Spreads%20and%20Random%20Hazards/03-stochastic-hazard-cox-process.md)
4. [The forward CDS: protection that starts later, its par spread from two annuities, and the knock-out if default comes early](44-Reduced-Form%20Models%20-%20Risky%20Bonds%2C%20Spreads%20and%20Random%20Hazards/04-forward-cds-and-the-forward-spread.md)
5. [Options on a CDS: Black's formula on the forward spread with the risky annuity as the unit, and the implied spread volatility](44-Reduced-Form%20Models%20-%20Risky%20Bonds%2C%20Spreads%20and%20Random%20Hazards/05-cds-option-and-implied-spread-volatility.md)

[↑ Back to the shelves](#top)

<a name="s45"></a>

## 45 · Portfolio Credit: Correlation, Copulas, Indices and Tranches · 7 cards

*Default correlation and joint default; the one-factor Gaussian copula; Vasicek's large-pool loss curve and the Basel capital formula; credit indices; tranches in outline; implied and base correlation; tail dependence and the t copula.*

1. [Default correlation: why a pool's losses cluster, measured by the chance two borrowers fail together](45-Portfolio%20Credit%20-%20Correlation%2C%20Copulas%2C%20Indices%20and%20Tranches/01-default-correlation-and-joint-default.md)
2. [The one-factor Gaussian copula: one shared economy dial plus private luck, gluing single-name default chances into a joint story](45-Portfolio%20Credit%20-%20Correlation%2C%20Copulas%2C%20Indices%20and%20Tranches/02-one-factor-gaussian-copula.md)
3. [Vasicek's large-pool loss curve: a whole book's loss distribution from three numbers, and the regulator's capital formula built on it](45-Portfolio%20Credit%20-%20Correlation%2C%20Copulas%2C%20Indices%20and%20Tranches/03-vasicek-loss-distribution-and-basel-capital.md)
4. [Credit indices (CDX and iTraxx in outline): one contract on 125 names, priced off their survival curves, and the index skew](45-Portfolio%20Credit%20-%20Correlation%2C%20Copulas%2C%20Indices%20and%20Tranches/04-credit-indices.md)
5. [Tranches: slicing a pool's losses into layers, and pricing a layer as its expected loss over time](45-Portfolio%20Credit%20-%20Correlation%2C%20Copulas%2C%20Indices%20and%20Tranches/05-cdo-tranches-in-outline.md)
6. [Implied correlation: the correlation that reprices a tranche, why a mezzanine quote can have two answers or none, and base correlation's fix](45-Portfolio%20Credit%20-%20Correlation%2C%20Copulas%2C%20Indices%20and%20Tranches/06-implied-and-base-correlation.md)
7. [Tail dependence: the Gaussian copula's calm at the extremes, and the Student-t copula that fails together](45-Portfolio%20Credit%20-%20Correlation%2C%20Copulas%2C%20Indices%20and%20Tranches/07-tail-dependence-and-the-t-copula.md)

[↑ Back to the shelves](#top)

<a name="s46"></a>

## 46 · Counterparty Risk and CVA · 6 cards

*Exposure and netting; expected exposure profiles and potential future exposure; CVA as loss times default chance times exposure over the life; DVA and the bilateral adjustment; wrong-way risk; CVA risk numbers and hedging.*

1. [Counterparty exposure: what you would lose if the other side failed today, why only positive value counts, and how netting shrinks it](46-Counterparty%20Risk%20and%20CVA/01-counterparty-exposure-and-netting.md)
2. [Expected exposure over time: what you are likely to be owed at each future date, and the tail (PFE) above it](46-Counterparty%20Risk%20and%20CVA/02-expected-exposure-profiles.md)
3. [CVA: the price of the counterparty's default, as loss times default chance times exposure summed over the deal's life](46-Counterparty%20Risk%20and%20CVA/03-cva.md)
4. [DVA: the mirror gain from your own default, and the bilateral adjustment that nets the two](46-Counterparty%20Risk%20and%20CVA/04-dva-and-bilateral-cva.md)
5. [Wrong-way risk: when the exposure grows just as the counterparty weakens, and what it does to CVA](46-Counterparty%20Risk%20and%20CVA/05-wrong-way-risk.md)
6. [CVA risk numbers: sensitivity to the counterparty's spread, to the underlying, and how a CDS hedges it](46-Counterparty%20Risk%20and%20CVA/06-cva-risk-numbers-and-hedging.md)

[↑ Back to the shelves](#top)

<a name="s47"></a>

## 47 · Collateral, Funding and the Rest of the XVAs · 5 cards

*Collateral agreements and the exposure they leave; FVA and the discounting argument behind it; MVA for initial margin; KVA for capital; the assembled adjusted price and its overlaps, with central clearing in outline.*

1. [Collateral: variation margin tracks the mark-to-market, thresholds and the margin period of risk leave a residual, and the CVA that remains](47-Collateral%2C%20Funding%20and%20the%20Rest%20of%20the%20XVAs/01-collateral-and-the-residual-exposure.md)
2. [FVA: funding the uncollateralised exposure at the bank's own spread, and the adjustment that books the cost](47-Collateral%2C%20Funding%20and%20the%20Rest%20of%20the%20XVAs/02-fva.md)
3. [MVA: initial margin sits idle for the life of the trade, and its funding cost is priced](47-Collateral%2C%20Funding%20and%20the%20Rest%20of%20the%20XVAs/03-mva.md)
4. [KVA: the capital a trade ties up over its life, charged at the bank's hurdle rate](47-Collateral%2C%20Funding%20and%20the%20Rest%20of%20the%20XVAs/04-kva.md)
5. [Putting the adjustments together: clean price minus CVA plus DVA minus FVA, MVA and KVA, what overlaps, and who charges whom](47-Collateral%2C%20Funding%20and%20the%20Rest%20of%20the%20XVAs/05-the-xva-desk-view.md)

[↑ Back to the shelves](#top)

<a name="s48"></a>

## 48 · Regulatory Capital in Outline · 5 cards

*Why banks hold capital, how much, and the rules that shape the numbers in slices D and F*

1. [Expected and unexpected loss: provisions cover the average, capital covers the surprise](48-Regulatory%20Capital%20in%20Outline/01-expected-versus-unexpected-loss.md)
2. [Basel capital: risk-weighted assets, the ratios, and the buffers on top](48-Regulatory%20Capital%20in%20Outline/02-basel-capital-and-risk-weighted-assets.md)
3. [The Basel credit formula: one-factor Vasicek behind the risk weights](48-Regulatory%20Capital%20in%20Outline/03-vasicek-asrf-and-credit-capital.md)
4. [Market-risk capital: from 99 percent VaR to 97.5 percent expected shortfall, and liquidity horizons](48-Regulatory%20Capital%20in%20Outline/04-frtb-and-the-shift-to-expected-shortfall.md)
5. [Liquidity and leverage: LCR, NSFR and the leverage ratio, and what each guards against](48-Regulatory%20Capital%20in%20Outline/05-liquidity-and-leverage-ratios.md)

[↑ Back to the shelves](#top)

<a name="s49"></a>

## 49 · Microstructure and Execution · 7 cards

*How prices form in the book, what a trade costs, and how to execute a large order*

1. [The order book: bids, asks, queues and the matching rule](49-Microstructure%20and%20Execution/01-the-limit-order-book.md)
2. [The spread: what it costs to trade now, and why informed traders make it wider](49-Microstructure%20and%20Execution/02-bid-ask-spread-and-adverse-selection.md)
3. [Kyle's model: how much a trade moves the price, and the square-root law seen in data](49-Microstructure%20and%20Execution/03-kyle-model-and-price-impact.md)
4. [Almgren-Chriss: trading a large order over time, balancing impact against risk](49-Microstructure%20and%20Execution/04-optimal-execution-almgren-chriss.md)
5. [Market making: quoting both sides, skewing for inventory](49-Microstructure%20and%20Execution/05-market-making-avellaneda-stoikov.md)
6. [Measuring execution: implementation shortfall, VWAP and arrival-price benchmarks](49-Microstructure%20and%20Execution/06-transaction-cost-analysis.md)
7. [Liquidity: effective spread, Amihud illiquidity and the depth-resilience picture](49-Microstructure%20and%20Execution/07-liquidity-measures.md)

[↑ Back to the shelves](#top)

<a name="s50"></a>

## 50 · Signals, Mean Reversion and Backtesting · 7 cards

*Finding a tradable pattern, sizing it, and not fooling yourself about it*

1. [Mean reversion: fitting an Ornstein-Uhlenbeck spread and trading its z-score](50-Signals%2C%20Mean%20Reversion%20and%20Backtesting/01-ornstein-uhlenbeck-mean-reversion-trading.md)
2. [Pairs trading: two prices tied by cointegration, and the hedge ratio between them](50-Signals%2C%20Mean%20Reversion%20and%20Backtesting/02-pairs-trading-and-cointegration.md)
3. [Momentum and factor signals: sorting stocks and reading the spread](50-Signals%2C%20Mean%20Reversion%20and%20Backtesting/03-momentum-and-factor-signals.md)
4. [The fundamental law: skill times breadth, and the information coefficient that measures skill](50-Signals%2C%20Mean%20Reversion%20and%20Backtesting/04-information-coefficient-and-the-fundamental-law.md)
5. [Backtesting: look-ahead, survivorship, costs and regime change, and how each flatters a strategy](50-Signals%2C%20Mean%20Reversion%20and%20Backtesting/05-backtesting-pitfalls.md)
6. [Trying many strategies: the deflated Sharpe ratio and the probability of backtest overfitting](50-Signals%2C%20Mean%20Reversion%20and%20Backtesting/06-deflated-sharpe-and-multiple-testing.md)
7. [A moving hedge ratio: the Kalman filter as a regression that updates](50-Signals%2C%20Mean%20Reversion%20and%20Backtesting/07-kalman-filter-for-dynamic-hedge-ratios.md)

[↑ Back to the shelves](#top)

<a name="s51"></a>

## 51 · Insurance and Actuarial Mathematics · 8 cards

*The same tools applied to lives and claims: life tables, premiums, aggregate claims, ruin and reserving*

1. [Life tables: survival by age, and the force of mortality that is a hazard rate by another name](51-Insurance%20and%20Actuarial%20Mathematics/01-survival-life-tables-and-force-of-mortality.md)
2. [Life annuities and insurance: paying while alive, paying at death, and the relation between them](51-Insurance%20and%20Actuarial%20Mathematics/02-life-annuities-and-insurance-values.md)
3. [Premiums and reserves: the equivalence principle and the money set aside as a policy ages](51-Insurance%20and%20Actuarial%20Mathematics/03-premiums-and-reserves.md)
4. [Aggregate claims: random count times random size](51-Insurance%20and%20Actuarial%20Mathematics/04-collective-risk-and-compound-poisson.md)
5. [Panjer's recursion: the aggregate claim distribution computed exactly](51-Insurance%20and%20Actuarial%20Mathematics/05-panjer-recursion-and-aggregate-claims.md)
6. [Ruin: the chance an insurer's surplus ever goes below zero](51-Insurance%20and%20Actuarial%20Mathematics/06-ruin-theory-and-lundberg.md)
7. [Reserving: estimating claims not yet reported from a run-off triangle](51-Insurance%20and%20Actuarial%20Mathematics/07-reserving-chain-ladder-and-bornhuetter-ferguson.md)
8. [Credibility and reinsurance: weighting a policy's own history, and laying off the tail](51-Insurance%20and%20Actuarial%20Mathematics/08-credibility-and-reinsurance.md)

[↑ Back to the shelves](#top)

---

[← 11 · Stochastic processes and calculus](../11-Stochastic%20processes%20and%20calculus/README.md) · [All wings](../../SYLLABUS.md) · [13 · Engineering mathematics →](../13-Engineering%20mathematics/README.md)
