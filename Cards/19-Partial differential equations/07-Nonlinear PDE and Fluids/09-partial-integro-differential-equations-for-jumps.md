# When prices jump: a pricing equation with an integral term

[Syllabus](../../../SYLLABUS.md) → [Partial differential equations](../README.md) → [Nonlinear PDE and Fluids](../README.md#s07) → When prices jump

---

## General Overview

Acme shares trade at $100. A one-year call option gives the right to buy one share for $100 in a year. Cash earns 5% a year, the share pays a 2% dividend yield, and its day-to-day wiggle has a volatility of 20% a year. These rates are illustrative.

Shelf 03 showed that, without gaps, the call's pricing equation is the heat equation in disguise ([Black-Scholes is the heat equation after a change of variables](../03-The%20Heat%20Equation%20in%20Depth/07-black-scholes-to-the-heat-equation.md)). There, the value at $100 changes only through its slope and curvature at $100. Those are local facts: they need only the values at prices next to $100.

Now let Acme gap. A profit warning arrives, on average, once every two years. Each one multiplies the price by a random factor, typically a fall of just under 10%, from $100 to $90.48. Of all gaps from $100, 99% land Acme between $61.49 and $133.16. So the call's value at $100 now depends directly on its value at $70, at $85 and at $120. The pricing equation gains a term that averages the value over every landing price. That average is an integral.

An equation with both derivatives and an integral of the unknown is a **partial integro-differential equation**, PIDE for short. This card writes it for Acme, shows why its integral term is **non-local** (it links each price to prices far away), and solves it on a grid. The grid gives $10.414564 at its finest step. Merton's series of Black-Scholes prices gives $10.416477. Without gaps the call would cost $9.227006.

**Jumps add one integral term to the pricing equation: the jump rate times the average change in value over every landing price, which ties each price to distant prices.**

**What kind of fact this is:** a theorem inside a model. Gaps arriving at random with lognormal sizes is a model (Merton's jump-diffusion), not a law. Given the model, the PIDE is derived on this card in Why it works, and the grid answer is checked against Merton's exact series.

### The picture: where one gap from $100 lands

```
where Acme lands after one jump from $100 (percent of jumps)

under $70   ####                          4.35
$70-80      ################             16.23
$80-90      ############################ 27.99
$90-100     ##########################   26.18
$100-110    ################             15.60
$110-120    #######                       6.65
over $120   ###                           2.99
```

One bar per $10 band; both checks print every value. The jumps lean down, because the typical gap is a fall from $100 to $90.48. Of all jumps, 4.35% land below $70 and 16.23% between $70 and $80, many grid cells away. The derivatives in the Black-Scholes equation never look that far.

---

## The formula

**Unknown, region and data.** The unknown is the call's value $`V(x, s)`$ in dollars. Here $`x = \ln S`$ is the log of the share price $`S`$, and $`s`$ is the time to expiry in years. The region is every real $`x`$ and $`0 < s \le 1`$. The data is the payoff at expiry, $`V(x, 0) = \max(e^x - K, 0)`$ with strike $`K = 100`$.

Jumps arrive at rate $`\lambda`$ (lambda) a year. A jump multiplies the price by $`Y`$. Its log, $`z = \ln Y`$, is a bell curve with mean $`\mu_J`$ and spread $`\delta`$; $`g(z)`$ is that bell curve's density. The average jump, as a fraction of the price, is $`k = E[Y] - 1`$, where $`E[\cdot]`$ means "the average over jump sizes". Here $`k`$ is Merton's letter, not a wavenumber. Two more letters differ from [Integral equations](07-integral-equations-fredholm-and-volterra.md): here $`\lambda`$ is the jump rate, not the feedback parameter, and $`K`$ is the strike, not a kernel; this card's kernel is $`g(z)`$.

```math
V_s = \tfrac12\sigma^2 V_{xx} + \left(r - q - \lambda k - \tfrac12\sigma^2\right) V_x - (r + \lambda)\,V + \lambda \int_{-\infty}^{\infty} V(x + z, s)\, g(z)\, dz
```

**Read it aloud:** the value grows with more time to expiry by the diffusion term, the drift term and the discount, exactly as in Black-Scholes, plus a jump term: at rate λ a jump removes the current value and replaces it with the average of the value over every price the jump can land on.

The last two pieces together are $`\lambda\big(E[V(x + z)] - V(x)\big)`$: the jump rate times the average change in value a jump causes. Subscripts mean partial derivatives, so $`V_{xx}`$ is the curvature in log price.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $`V`$; $`V_s`$, $`V_x`$, $`V_{xx}`$; $`U`$, $`M_t`$ | the call's value in dollars; its rate of change with time to expiry, its slope and curvature in log price; the value written in log price, and the discounted value $`e^{-rt}V`$, in the proof | $10.416477 today | is the answer |
| $`S`$, $`x`$; $`S_t`$, $`S_T`$ | share price; its natural log; the price at date $`t`$ and at expiry | $100; $`\ln 100`$ | rises |
| $`s`$; $`t`$, $`T`$ | time to expiry, in years; the calendar date and the expiry date | 1 | rises |
| $`K`$ | strike | $100 | falls |
| $`r`$, $`q`$ | bank rate and dividend yield, a year, continuously compounded | 0.05, 0.02 | $`r`$ up: rises; $`q`$ up: falls |
| $`\sigma`$; $`\mu`$ | volatility of the wiggle between jumps; drift between jumps, $`r - q - \lambda k`$ | 0.20; 0.072463 a year | $`\sigma`$ up: rises |
| $`\lambda`$ | jump rate: average jumps a year | 0.5 | rises: $11.503925 at 1 |
| $`Y`$, $`z`$; $`\mu_J`$, $`\delta`$ | one jump's price factor and its log; the log's mean and spread | typical landing $90.48 from $100; −0.10 and 0.15 | wider jumps either way: rises |
| $`g(z)`$, $`E[\cdot]`$; $`f`$ | the bell-curve density of $`z`$; the average over jump sizes; any function of the price, in the generator | — | — |
| $`k`$ | average jump as a fraction of the price, $`e^{\mu_J + \delta^2/2} - 1`$ | −0.084926 | — |
| $`w_n`$, $`\sigma_n`$, $`q_n`$, $`C_{\text{BS}}`$, $`n`$ | Merton's series: chance of $`n`$ jumps, the $`n`$-jump volatility and yield, a Black-Scholes call; a jump count | first term 7.244796 | — |
| $`h`$, $`\Delta s`$; $`j`$ | grid steps in log price and in years; how many cells a jump moves | 0.04, 0.02, 0.01 | error falls 4 times per halving |

### When it holds

- **Jumps arrive one at a time at a steady rate, with sizes independent of each other and of the wiggle.** Then the jump term is one fixed integral against $`g`$. If the rate or size law depends on the price, the kernel changes from point to point, and Merton's series no longer applies, though a grid still does.
- **Finitely many jumps a year.** Then $`g`$ has total weight 1 and the integral is ordinary. For processes with infinitely many tiny jumps (variance gamma, CGMY), the kernel blows up near $`z = 0`$, and small jumps must be compensated and treated as extra diffusion, as Cont and Voltchkova do.
- **Jump risk carries no premium.** Merton's argument: a firm's own gaps do not move the whole market, so pricing may use jump numbers measured from history. A gap cannot be hedged with shares and cash, so if investors demand a reward for it, the jump numbers in the PIDE differ from the historical ones.
- **A European payoff.** Early exercise turns the PIDE into an obstacle problem with an integral term, the jump version of [An American option](../06-Weak%20Solutions%20and%20Free%20Boundaries/09-american-options-as-a-free-boundary-problem.md).
- **The kind of solution.** With $`\sigma > 0`$ the value is a classical solution for $`s > 0`$: twice differentiable in $`x`$, once in $`s`$. It is unique among continuous solutions that grow no faster than the share price; Cont and Voltchkova prove uniqueness in the wider class of viscosity solutions ([Viscosity solutions](../06-Weak%20Solutions%20and%20Free%20Boundaries/06-viscosity-solutions.md)).

---

## Why it works

### Step 0: a fair price has no average drift once discounted

The option's value today is the discounted average payoff in the pricing world, where Acme grows on average at the bank rate less the dividend yield. Discounted at the bank rate, that value must have zero average change, or a free bet exists. So write down the value's average rate of change, set the discounted version to zero, and the pricing equation appears.

With jumps, that average rate of change has a new part. It is the jump rate times the average change a jump causes. That change compares the value at the landing price with the value now, and the landing price can be far away. That is the whole source of the integral.

### Step 1: the average rate of change, with jumps

[Jump diffusions](../../11-Stochastic%20processes%20and%20calculus/09-Beyond%20Brownian/02-jump-diffusions.md) proves Ito's lemma with jumps and averages it. For a function $`f`$ of the price, the average rate of change per year is the generator (the average rate of change of $`f`$ from the price $`S`$):

```math
\mu S f'(S) + \tfrac12\sigma^2 S^2 f''(S) + \lambda\big(E[f(SY)] - f(S)\big)
```

Here $`\mu`$ is the drift between jumps. The first two terms are Ito's slope and curvature terms. The third is the jump part: at rate $`\lambda`$, the function moves from $`f(S)`$ to $`f(SY)`$.

### Step 2: the compensator fixes the drift

[Merton jump-diffusion](../../12-Financial%20mathematics/13-Local%20volatility%20and%20jumps/04-merton-jump-diffusion.md) shows that jumps add $`\lambda k`$ to Acme's average growth. In the pricing world the total must be $`r - q`$, so the drift between jumps is $`\mu = r - q - \lambda k`$. Here $`k = e^{-0.10 + 0.5 \times 0.15^2} - 1 = -0.084926`$, so the compensator $`-\lambda k`$ adds 0.042463 a year to the drift. It pays back, on average, what the downward gaps take away.

### Step 3: put the value into the generator

Apply the generator to $`V`$, add the change from time passing, and subtract the discount $`rV`$. Setting the total to zero gives the PIDE in calendar time $`t`$ and price $`S`$:

```math
V_t + (r - q - \lambda k)\,S V_S + \tfrac12\sigma^2 S^2 V_{SS} - rV + \lambda\big(E[V(SY, t)] - V(S, t)\big) = 0
```

Now change to log price and time to expiry, as on shelf 03. With $`x = \ln S`$ and $`s = T - t`$, the chain rule gives $`S V_S = V_x`$, $`S^2 V_{SS} = V_{xx} - V_x`$ and $`V_t = -V_s`$. A jump multiplies $`S`$ by $`Y`$, so it adds $`z`$ to $`x`$, and $`E[V(SY)]`$ becomes $`\int V(x + z)\, g(z)\, dz`$. Collect terms and the PIDE of The formula appears.

<details>
<summary>Detailed proof: the discounted value has no drift, so it solves the PIDE</summary>

Let $`V(S, t) = e^{-r(T - t)} E[\max(S_T - K, 0) \mid S_t = S]`$, the discounted average payoff given today's price.

The process $`M_t = e^{-rt} V(S_t, t)`$ is the average of one fixed amount, $`e^{-rT}\max(S_T - K, 0)`$, given what is known at time $`t`$. An average of a fixed future amount, updated as information arrives, has no average drift: it is a martingale.

For $`\sigma > 0`$ the value is smooth for $`t < T`$: each branch of Merton's series is a Black-Scholes price, and the series and its derivatives converge uniformly on compact sets. So Ito's lemma with jumps applies to $`M_t`$. Its average rate of change is

$`\displaystyle e^{-rt}\Big(V_t + \mu S V_S + \tfrac12\sigma^2 S^2 V_{SS} + \lambda\big(E[V(SY, t)] - V\big) - rV\Big)`$

with $`\mu = r - q - \lambda k`$. A martingale's average rate of change is zero at every state the process can reach. The price can reach every positive $`S`$, because the wiggle has a positive spread. So the bracket is zero for all $`S > 0`$ and $`t < T`$: that is the PIDE in $`S`$ and $`t`$.

The change of variables: with $`V(S, t) = U(\ln S, T - t)`$, $`V_S = U_x / S`$, $`V_{SS} = (U_{xx} - U_x)/S^2`$ and $`V_t = -U_s`$. Substituting gives

$`\displaystyle U_s = \tfrac12\sigma^2 U_{xx} + \big(r - q - \lambda k - \tfrac12\sigma^2\big)U_x - (r + \lambda)U + \lambda \int U(x + z, s)\, g(z)\, dz.`$

Merton's series is $`\sum_n w_n C_{\text{BS}}(S, K, r, q_n, \sigma_n, s)`$ with $`w_n = e^{-\lambda s}(\lambda s)^n / n!`$, $`\sigma_n^2 = \sigma^2 + n\delta^2/s`$ and $`q_n = q + \lambda k - n\ln(1 + k)/s`$. The checks confirm that it satisfies the PIDE at Acme's point: the residual falls from 0.0019370 to 0.0004847 when the difference step halves, as a second-order error should.

</details>

### Step 4: why the integral term is non-local

A derivative at $`x`$ is a limit of differences between $`x`$ and points ever closer to it. On a grid, $`V_x`$ and $`V_{xx}`$ at a node use three nodes: itself and its two neighbours. The integral at $`x`$ uses the value at $`x + z`$ for every jump size $`z`$ the bell curve allows.

On Acme's grid with $`h = 0.01`$, that is 213 nodes per row, against 3 for the derivatives. The jump range does not shrink when the grid is refined. So the equation's matrix is no longer tridiagonal (three diagonals, solved in one sweep): every row holds a wide band.

Non-locality also changes the edges. A grid from $30.12 to $332.01 still needs values beyond its ends, because jumps from nodes near an edge land outside it. The checks use the call's far-field values there: zero far below the strike, $`S e^{-qs} - K e^{-rs}`$ far above it.

No change of variables removes the integral. Exponential factors and moving frames turn derivatives into derivatives. The integral is a convolution, a weighted sum of shifted copies of $`V`$, and stays one in any such coordinates.

### Step 5: how it is solved

Three routes are in use.

1. **A grid, with the integral treated as a sum.** Replace the integral by the trapezoid rule on the grid's own spacing: weights $`h\,g(jh)`$ for a jump of $`j`$ cells. Step the derivative part by Crank-Nicolson (half old time, half new time), which needs a tridiagonal solve. Treat the jump part by fixed-point passes: guess the new values, compute the jump sum, solve, and repeat. Each pass shrinks the gap by a factor of about $`\lambda \Delta s / 2`$, so a few passes settle. This is the method of d'Halluin, Forsyth and Vetzal. Four half-size fully implicit first steps damp the payoff's kink (Rannacher's start).
2. **A series.** For lognormal jump sizes, Merton's sum of Black-Scholes prices is exact. It is this card's check, not its method.
3. **A transform.** The integral is a convolution in $`x`$, which a Fourier transform turns into a multiplication, so the PIDE becomes one multiplication per frequency and one inverse transform prices every strike at once ([Pricing by transform](../../20-Harmonic%20analysis/04-Characteristic%20Functions%20and%20Probability/09-carr-madan-and-fourier-pricing.md)).

For barrier and American options under jumps, the transform method meets a boundary, and the standard tool is the Wiener-Hopf factorisation (splitting a function of frequency into one part analytic above the real axis and one below), as in Boyarchenko and Levendorskii. This card names it and does not use it.

---

## Worked numbers, by hand

The PIDE at Acme's point, $`S = 100`$ and one year to go. Each term is in dollars a year.

| Step | Arithmetic | Value |
| --- | --- | --- |
| average jump $`k`$ | $`e^{-0.10 + 0.5 \times 0.15^2} - 1`$ | −0.084926 |
| compensator $`\lambda k`$ | $`0.5 \times (-0.084926)`$ | −0.042463 a year |
| value today $`V`$ | Merton's series, 40 terms | 10.416477 |
| jump average $`E[V(100Y)]`$ | Simpson's rule over $`z`$, 400 intervals | 7.595313 |
| diffusion $`\tfrac12\sigma^2 V_{xx}`$ | $`0.5 \times 0.2^2 \times 226.2595`$, with $`V_{xx}`$ by centred differences, step 0.01 | 4.5252 |
| drift $`(r - q - \lambda k - \tfrac12\sigma^2)V_x`$ | $`(0.03 + 0.042463 - 0.02) \times 59.9915`$, with $`V_x`$ by centred differences, step 0.01 | 3.1473 |
| discount $`-rV`$ | $`-0.05 \times 10.416477`$ | −0.5208 |
| jumps out $`-\lambda V`$ | $`-0.5 \times 10.416477`$ | −5.2082 |
| jumps in $`\lambda E[V(100Y)]`$ | $`0.5 \times 7.595313`$ | 3.7977 |
| right side | the five terms added, before rounding | 5.7411 |
| left side $`V_s`$ | centred difference in time, step 0.01 | 5.7416 |
| **residual** | left side less right side | **0.0004847** |

The residual is the differences' own error: at step 0.02 it is 0.0019370, four times larger. So Merton's price satisfies the PIDE, and the PIDE's solution is $10.416477.

The jump average, $7.595313, sits well below today's $10.416477. A gap is usually a fall, and a fall cuts the call's value: $2.098518 at $80, $5.513266 at $90.48. So the jump term, net, is $`0.5 \times (7.595313 - 10.416477) = -1.4106`$ dollars a year: gaps take value from the call, and the raised drift pays it back.

The grid, run at three steps:

| Step $`h`$ | Time steps | Jump stencil | Grid price | Error |
| --- | --- | --- | --- | --- |
| 0.04 | 25 | 54 nodes | 10.385672 | −0.030805 |
| 0.02 | 50 | 107 nodes | 10.408815 | −0.007662 |
| 0.01 | 100 | 213 nodes | 10.414564 | −0.001913 |

Each halving cuts the error by 4.021, then 4.005: an observed order of 2.002. Richardson's combination of the last two, $`(4 \times 10.414564 - 10.408815)/3`$, gives 10.416480, off by 0.000003.

**The call is worth $10.416477 with gaps, $1.189472 more than the $9.227006 Black-Scholes price at the same 20% wiggle.**

That extra $1.189472 is the price of the gaps: the fatter spread of outcomes that the integral term carries in from distant prices.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Drop every jump term | 9.227006 | plain Black-Scholes: no gaps, no fatter spread |
| Drop the integral, keep $`-\lambda V`$ | 7.244796 | jumps only destroy value; the answer is Merton's no-jump term alone |
| Drop the compensator $`-\lambda k`$ | 8.071035 | Acme's average price falls short of the forward |
| Replace the integral by its Taylor terms in $`z`$ up to $`z^2`$ | 10.671343 | a local stand-in: Black-Scholes at 23.72% volatility, 1.9412% yield; it keeps the variance and loses the lopsided tail |
| Cut the jump stencil to the mean ± 2 spreads, $`h = 0.02`$ | 10.079030 against 10.408815 | 32 nodes instead of 107; the landings beyond two spreads, the most distant ones, are lost |

The Taylor stand-in is the clearest sign of non-locality. It replaces the integral with a slope and a curvature at $`x`$, and it prices the call at $10.671343 against $10.416477.

---

## Code, from first principles, and it actually runs

The code takes three roads to the price. Road 1 is Merton's series, with its first omitted terms bounded. Road 2 solves the PIDE on a grid at three steps, with the jump integral as a trapezoid sum, a written-out tridiagonal solver and fixed-point passes, and reports the observed order. Road 3 puts Merton's price into the PIDE by centred differences and Simpson's rule and prints the residual at two steps. The normal area is Marsaglia's series written out, since Rust has no error function. The same code prints every row of "What breaks" and the experiments below.

### Python

```python
# When prices jump -- the check behind the card.  Standard library only.
# Acme at $100, a one-year call struck at $100; jumps arrive 0.5 times a year
# and multiply the price by Y, log Y normal with mean -0.10 and spread 0.15.
# Roads to the price: (1) Merton's series of Black-Scholes prices, (2) the
# PIDE on a grid in log price at three steps, (3) the PIDE's residual at the
# series by centred differences and Simpson's rule.  Nothing imported knows
# the answer: the normal area, the integrals and the solver are written out.
from math import exp, log, sqrt, pi

S0, K, R, Q, SIG, T = 100.0, 100.0, 0.05, 0.02, 0.20, 1.0
LAM, MUJ, DEL = 0.5, -0.10, 0.15
X0 = log(S0)

def kj(muj=MUJ): return exp(muj + 0.5 * DEL * DEL) - 1.0      # average jump k

def ncdf(x):                                     # normal area, Marsaglia's series
    if abs(x) > 9.0: return 0.0 if x < 0.0 else 1.0
    s, b, i = x, x, 1.0
    while s + b * x * x / (i + 2.0) != s:
        i += 2.0; b *= x * x / i; s += b
    return 0.5 + s * exp(-0.5 * x * x) / sqrt(2.0 * pi)

def bs(S, s, q, sig):                            # Black-Scholes call, s years to go
    v = sig * sqrt(s); d1 = (log(S / K) + (R - q + 0.5 * sig * sig) * s) / v
    return S * exp(-q * s) * ncdf(d1) - K * exp(-R * s) * ncdf(d1 - v)

def merton(S, s, terms=40, lam=LAM, muj=MUJ, comp=True):    # sum of w_n C_BS
    k = kj(muj); tot, w = 0.0, exp(-lam * s)
    for n in range(terms):
        if n: w *= lam * s / n
        qn = Q + (lam * k if comp else 0.0) - n * log(1.0 + k) / s
        tot += w * bs(S, s, qn, sqrt(SIG**2 + n * DEL**2 / s))
    return tot

def add(vals):                                   # plain left-to-right sum, as in the Rust
    t = 0.0
    for v in vals: t += v
    return t

def g(z): return exp(-0.5 * ((z - MUJ) / DEL) ** 2) / (DEL * sqrt(2.0 * pi))

def simpson(f, m=400):                           # integral of g(z) f(z) over mean +- 8 spreads
    a, h = MUJ - 8.0 * DEL, 16.0 * DEL / m
    return h / 3.0 * add((1 if i in (0, m) else 4 if i % 2 else 2) * g(a + i * h) * f(a + i * h)
                         for i in range(m + 1))

def far(x, s):                                   # the call far from the strike
    return max(exp(x - Q * s) - K * exp(-R * s), 0.0) if x > X0 else 0.0

def grid(h, nst, L=1.2, W=7, zero=False):    # Crank-Nicolson, Rannacher start
    M = round(L / h); n = 2 * M + 1; xs = [X0 + (i - M) * h for i in range(n)]
    a, b, c = 0.5 * SIG**2, R - Q - LAM * kj() - 0.5 * SIG**2, -(R + LAM)
    lo, up, mid = a / h**2 - b / (2 * h), a / h**2 + b / (2 * h), c - 2 * a / h**2
    j0, j1 = int((MUJ - W * DEL) / h) - 1, int((MUJ + W * DEL) / h) + 2
    ws = [(j, h * g(j * h)) for j in range(j0, j1)]          # trapezoid weights in z = j h
    def jump(V, s):                              # lambda * sum over j of w_j V(x_i + j h)
        out = lambda y: 0.0 if zero else far(y, s)              # values beyond the grid
        return [LAM * add(w * (V[i + j] if 0 <= i + j < n else out(xs[i] + j * h))
                          for j, w in ws) for i in range(n)]
    V, s = [max(exp(x) - K, 0.0) for x in xs], 0.0
    for th, dt in [(1.0, T / nst / 2)] * 4 + [(0.5, T / nst)] * (nst - 2):
        Jn, s1 = jump(V, s), s + dt
        rhs = [V[i] + (1 - th) * dt * (lo * V[i - 1] + mid * V[i] + up * V[i + 1] + Jn[i])
               if 0 < i < n - 1 else 0.0 for i in range(n)]
        rhs[0], rhs[-1] = far(xs[0], s1), far(xs[-1], s1)
        guess = V
        for _ in range(20):                      # fixed-point passes on the jump term
            Jg = jump(guess, s1)
            d = [rhs[i] + th * dt * Jg[i] if 0 < i < n - 1 else rhs[i] for i in range(n)]
            A, B, Cc = -th * dt * lo, 1 - th * dt * mid, -th * dt * up
            cp, dp = [0.0] * n, [0.0] * n; dp[0] = d[0]           # Thomas algorithm
            for i in range(1, n - 1):
                m = B - A * cp[i - 1]; cp[i] = Cc / m; dp[i] = (d[i] - A * dp[i - 1]) / m
            new = [0.0] * n; new[0], new[-1] = d[0], d[-1]
            for i in range(n - 2, 0, -1): new[i] = dp[i] - cp[i] * new[i + 1]
            done = max(abs(p - q) for p, q in zip(new, guess)) < 1e-10
            guess = new
            if done: break
        V, s = guess, s1
    return V[M], len(ws)

k = kj()
print(f"average jump k = {k:.6f}; compensator lambda k = {LAM * k:.6f}; drift r - q - lambda k = {R - Q - LAM * k:.6f} a year")
print(f"E[Y] by Simpson = {simpson(exp):.6f}; 1 + k = {1 + k:.6f}")
bands = [0, 70, 80, 90, 100, 110, 120, 1e9]
cdf = [0.0] + [ncdf((log(v / S0) - MUJ) / DEL) for v in bands[1:-1]] + [1.0]
names = ["under 70", "70-80", "80-90", "90-100", "100-110", "110-120", "over 120"]
print("where one jump from $100 lands (%): " + ", ".join(
    f"{names[i]} {100 * (cdf[i + 1] - cdf[i]):.2f}" for i in range(7)))
print(f"middle 99% of landings: ${S0 * exp(MUJ - 2.5758 * DEL):.2f} to ${S0 * exp(MUJ + 2.5758 * DEL):.2f}")
ser = [merton(S0, T, terms=N) for N in (1, 2, 6)]
C = merton(S0, T)
p6 = add(exp(-LAM) * LAM**n / [1, 1, 2, 6, 24, 120][n] for n in range(6))  # P(N <= 5)
bound = S0 * exp(-(Q + LAM * k) * T) * (1 - p6)
print("series after 1, 2, 6 terms: " + ", ".join(f"{v:.6f}" for v in ser)
      + f"; tail {C - ser[2]:.6f}, bound {bound:.6f}")
print(f"road 1, Merton series: {C:.6f}")
assert 0.0 < C - ser[2] <= bound
assert abs(simpson(exp) - (1 + k)) < 1e-9
EV = simpson(lambda z: merton(exp(X0 + z), T))
print(f"jump average E[V(100 Y)] = {EV:.6f}; V at $80, ${S0 * exp(MUJ):.2f}, $100 = "
      f"{merton(80.0, T):.6f}, {merton(S0 * exp(MUJ), T):.6f}, {C:.6f}")
print(f"net jump term lambda (E[V] - V) = {LAM * (EV - C):.4f} a year")
res = []
for e in (0.02, 0.01):
    Vp, Vm = merton(exp(X0 + e), T), merton(exp(X0 - e), T)
    Vs = (merton(S0, T + e) - merton(S0, T - e)) / (2 * e)
    terms = [0.5 * SIG**2 * (Vp - 2 * C + Vm) / e**2, (R - Q - LAM * k - 0.5 * SIG**2) * (Vp - Vm) / (2 * e),
             -R * C, -LAM * C, LAM * EV]
    res.append(Vs - add(terms))
    print(f"step {e}: V_x {(Vp - Vm) / (2 * e):.4f}, V_xx {(Vp - 2 * C + Vm) / e**2:.4f}, V_s {Vs:.4f}; diffusion {terms[0]:.4f}, drift {terms[1]:.4f}, "
          f"-rV {terms[2]:.4f}, -lambda V {terms[3]:.4f}, lambda E[V] {terms[4]:.4f}; sum {add(terms):.4f}; residual {res[-1]:.7f}")
assert abs(res[1]) < 1e-3 and 3.5 < res[0] / res[1] < 4.5
print(f"grid edges ${S0 * exp(-1.2):.2f} to ${S0 * exp(1.2):.2f}; nodes {round(2.4 / 0.04) + 1}, "
      f"{round(2.4 / 0.02) + 1}, {round(2.4 / 0.01) + 1}; derivative stencil 3 nodes")
runs = [grid(h, nst) for h, nst in ((0.04, 25), (0.02, 50), (0.01, 100))]
for (h, nst), (v, nw) in zip(((0.04, 25), (0.02, 50), (0.01, 100)), runs):
    print(f"road 2, grid h = {h}, {nst} steps, jump stencil {nw} nodes: {v:.6f}, error {v - C:.6f}")
e = [v - C for v, _ in runs]
rich = (4 * runs[2][0] - runs[1][0]) / 3
print(f"error ratios {e[0] / e[1]:.3f}, {e[1] / e[2]:.3f}; observed order {log(e[1] / e[2]) / log(2):.3f}")
print(f"Richardson from h = 0.02 and 0.01: {rich:.6f}, off by {rich - C:.6f}")
assert abs(e[2]) < 3e-3 and 3.5 < e[1] / e[2] < 4.5 and abs(rich - C) < 2e-5
print("what breaks:")
print(f"  no jumps at all (Black-Scholes at 20%): {bs(S0, T, Q, SIG):.6f}; jumps add {C - bs(S0, T, Q, SIG):.6f}")
print(f"  drop the integral, keep -lambda V: {exp(-LAM * T) * bs(S0, T, Q + LAM * k, SIG):.6f}")
print(f"  drop the compensator: {merton(S0, T, comp=False):.6f}")
se = sqrt(SIG**2 + LAM * (MUJ**2 + DEL**2)); qe = Q + LAM * k - LAM * MUJ - 0.5 * LAM * (MUJ**2 + DEL**2)
print(f"  local Taylor stand-in (vol {100 * se:.2f}%, yield {100 * qe:.4f}%): {bs(S0, T, qe, se):.6f}")
w2 = grid(0.02, 50, W=2)
print(f"  jump stencil cut to mean +- 2 spreads ({w2[1]} nodes), h = 0.02: {w2[0]:.6f}")
assert w2[0] < runs[1][0] - 0.1
print("try changing:")
print(f"  one jump a year: {merton(S0, T, lam=1.0):.6f}; gaps of +10% instead: {merton(S0, T, muj=0.10):.6f}")
v6 = grid(0.02, 50, L=0.6, zero=True)[0]
print(f"  grid h = 0.02 on ${S0 * exp(-0.6):.2f} to ${S0 * exp(0.6):.2f}, zero beyond: {v6:.6f}, error {v6 - C:.6f}")
assert abs(v6 - C) > 3 * abs(e[1])
print("ALL CHECKS PASS")
```

**Ran 2026-11-15 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
average jump k = -0.084926; compensator lambda k = -0.042463; drift r - q - lambda k = 0.072463 a year
E[Y] by Simpson = 0.915074; 1 + k = 0.915074
where one jump from $100 lands (%): under 70 4.35, 70-80 16.23, 80-90 27.99, 90-100 26.18, 100-110 15.60, 110-120 6.65, over 120 2.99
middle 99% of landings: $61.49 to $133.16
series after 1, 2, 6 terms: 7.244796, 9.864250, 10.416447; tail 0.000030, bound 0.001449
road 1, Merton series: 10.416477
jump average E[V(100 Y)] = 7.595313; V at $80, $90.48, $100 = 2.098518, 5.513266, 10.416477
net jump term lambda (E[V] - V) = -1.4106 a year
step 0.02: V_x 59.9981, V_xx 226.1787, V_s 5.7418; diffusion 4.5236, drift 3.1477, -rV -0.5208, -lambda V -5.2082, lambda E[V] 3.7977; sum 5.7398; residual 0.0019370
step 0.01: V_x 59.9915, V_xx 226.2595, V_s 5.7416; diffusion 4.5252, drift 3.1473, -rV -0.5208, -lambda V -5.2082, lambda E[V] 3.7977; sum 5.7411; residual 0.0004847
grid edges $30.12 to $332.01; nodes 61, 121, 241; derivative stencil 3 nodes
road 2, grid h = 0.04, 25 steps, jump stencil 54 nodes: 10.385672, error -0.030805
road 2, grid h = 0.02, 50 steps, jump stencil 107 nodes: 10.408815, error -0.007662
road 2, grid h = 0.01, 100 steps, jump stencil 213 nodes: 10.414564, error -0.001913
error ratios 4.021, 4.005; observed order 2.002
Richardson from h = 0.02 and 0.01: 10.416480, off by 0.000003
what breaks:
  no jumps at all (Black-Scholes at 20%): 9.227006; jumps add 1.189472
  drop the integral, keep -lambda V: 7.244796
  drop the compensator: 8.071035
  local Taylor stand-in (vol 23.72%, yield 1.9412%): 10.671343
  jump stencil cut to mean +- 2 spreads (32 nodes), h = 0.02: 10.079030
try changing:
  one jump a year: 11.503925; gaps of +10% instead: 10.605291
  grid h = 0.02 on $54.88 to $182.21, zero beyond: 10.372362, error -0.044115
ALL CHECKS PASS
```

### Rust

```rust
// When prices jump -- the check behind the card.  Standard library only, no crates.
// Acme at $100, a one-year call struck at $100; jumps arrive 0.5 times a year
// and multiply the price by Y, log Y normal with mean -0.10 and spread 0.15.
// Roads to the price: (1) Merton's series of Black-Scholes prices, (2) the
// PIDE on a grid in log price at three steps, (3) the PIDE's residual at the
// series by centred differences and Simpson's rule.
use std::f64::consts::PI;

const S0: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02; const SIG: f64 = 0.20;
const T: f64 = 1.0;
const LAM: f64 = 0.5; const MUJ: f64 = -0.10; const DEL: f64 = 0.15;

fn x0() -> f64 { S0.ln() }
fn kj(muj: f64) -> f64 { (muj + 0.5 * DEL * DEL).exp() - 1.0 }   // average jump k

fn ncdf(x: f64) -> f64 {                          // normal area, Marsaglia's series
    if x.abs() > 9.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    let (mut s, mut b, mut i) = (x, x, 1.0);
    while s + b * x * x / (i + 2.0) != s { i += 2.0; b *= x * x / i; s += b; }
    0.5 + s * (-0.5 * x * x).exp() / (2.0 * PI).sqrt()
}

fn bs(s_: f64, s: f64, q: f64, sig: f64) -> f64 { // Black-Scholes call, s years to go
    let v = sig * s.sqrt();
    let d1 = ((s_ / K).ln() + (R - q + 0.5 * sig * sig) * s) / v;
    s_ * (-q * s).exp() * ncdf(d1) - K * (-R * s).exp() * ncdf(d1 - v)
}

fn merton_full(s_: f64, s: f64, terms: usize, lam: f64, muj: f64, comp: bool) -> f64 {
    let k = kj(muj);
    let (mut tot, mut w) = (0.0, (-lam * s).exp());
    for n in 0..terms {
        if n > 0 { w *= lam * s / n as f64; }
        let qn = Q + (if comp { lam * k } else { 0.0 }) - n as f64 * (1.0 + k).ln() / s;
        tot += w * bs(s_, s, qn, (SIG.powi(2) + n as f64 * DEL.powi(2) / s).sqrt());
    }
    tot
}
fn merton(s_: f64, s: f64) -> f64 { merton_full(s_, s, 40, LAM, MUJ, true) }

fn g(z: f64) -> f64 { (-0.5 * ((z - MUJ) / DEL).powi(2)).exp() / (DEL * (2.0 * PI).sqrt()) }

fn simpson(f: &dyn Fn(f64) -> f64) -> f64 {      // integral of g(z) f(z) over mean +- 8 spreads
    let m = 400;
    let (a, h) = (MUJ - 8.0 * DEL, 16.0 * DEL / m as f64);
    let mut t = 0.0;
    for i in 0..=m {
        let c = if i == 0 || i == m { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        let z = a + i as f64 * h; t += c * g(z) * f(z);
    }
    h / 3.0 * t
}

fn far(x: f64, s: f64) -> f64 {                   // the call far from the strike
    if x > x0() { ((x - Q * s).exp() - K * (-R * s).exp()).max(0.0) } else { 0.0 }
}

fn grid(h: f64, nst: usize, l: f64, wd: f64, zero: bool) -> (f64, usize) {
    let m_ = (l / h).round() as i64; let n = (2 * m_ + 1) as usize;
    let xs: Vec<f64> = (0..n).map(|i| x0() + (i as i64 - m_) as f64 * h).collect();
    let (a, b, c) = (0.5 * SIG.powi(2), R - Q - LAM * kj(MUJ) - 0.5 * SIG.powi(2), -(R + LAM));
    let (lo, up, mid) = (a / h.powi(2) - b / (2.0 * h), a / h.powi(2) + b / (2.0 * h), c - 2.0 * a / h.powi(2));
    let (j0, j1) = (((MUJ - wd * DEL) / h) as i64 - 1, ((MUJ + wd * DEL) / h) as i64 + 2);
    let ws: Vec<(i64, f64)> = (j0..j1).map(|j| (j, h * g(j as f64 * h))).collect();
    let jump = |v: &Vec<f64>, s: f64| -> Vec<f64> {
        (0..n).map(|i| {
            let mut t = 0.0;
            for &(j, w) in &ws {
                let ij = i as i64 + j;
                let val = if ij >= 0 && ij < n as i64 { v[ij as usize] }
                          else if zero { 0.0 } else { far(xs[i] + j as f64 * h, s) };
                t += w * val;
            }
            LAM * t
        }).collect()
    };
    let mut v: Vec<f64> = xs.iter().map(|&x| (x.exp() - K).max(0.0)).collect();
    let mut s = 0.0;
    let mut plan = vec![(1.0, T / nst as f64 / 2.0); 4];
    plan.extend(vec![(0.5, T / nst as f64); nst - 2]);
    for (th, dt) in plan {
        let (jn, s1, mut rhs) = (jump(&v, s), s + dt, vec![0.0; n]);
        for i in 1..n - 1 {
            rhs[i] = v[i] + (1.0 - th) * dt * (lo * v[i - 1] + mid * v[i] + up * v[i + 1] + jn[i]);
        }
        rhs[0] = far(xs[0], s1); rhs[n - 1] = far(xs[n - 1], s1);
        let mut guess = v.clone();
        for _ in 0..20 {                           // fixed-point passes on the jump term
            let jg = jump(&guess, s1);
            let d: Vec<f64> = (0..n).map(|i| if i > 0 && i < n - 1 { rhs[i] + th * dt * jg[i] } else { rhs[i] }).collect();
            let (aa, bb, cc) = (-th * dt * lo, 1.0 - th * dt * mid, -th * dt * up);
            let (mut cp, mut dp) = (vec![0.0; n], vec![0.0; n]); dp[0] = d[0];   // Thomas algorithm
            for i in 1..n - 1 {
                let m = bb - aa * cp[i - 1]; cp[i] = cc / m; dp[i] = (d[i] - aa * dp[i - 1]) / m;
            }
            let mut new = vec![0.0; n]; new[0] = d[0]; new[n - 1] = d[n - 1];
            for i in (1..n - 1).rev() { new[i] = dp[i] - cp[i] * new[i + 1]; }
            let done = new.iter().zip(guess.iter()).map(|(p, q)| (p - q).abs()).fold(0.0, f64::max) < 1e-10;
            guess = new;
            if done { break; }
        }
        v = guess; s = s1;
    }
    (v[m_ as usize], ws.len())
}

fn main() {
    let k = kj(MUJ);
    println!("average jump k = {:.6}; compensator lambda k = {:.6}; drift r - q - lambda k = {:.6} a year", k, LAM * k, R - Q - LAM * k);
    println!("E[Y] by Simpson = {:.6}; 1 + k = {:.6}", simpson(&|z: f64| z.exp()), 1.0 + k);
    let bands = [70.0, 80.0, 90.0, 100.0, 110.0, 120.0];
    let mut cdf = vec![0.0]; for b in bands { cdf.push(ncdf(((b / S0).ln() - MUJ) / DEL)); } cdf.push(1.0);
    let names = ["under 70", "70-80", "80-90", "90-100", "100-110", "110-120", "over 120"];
    let parts: Vec<String> = (0..7).map(|i| format!("{} {:.2}", names[i], 100.0 * (cdf[i + 1] - cdf[i]))).collect();
    println!("where one jump from $100 lands (%): {}", parts.join(", "));
    println!("middle 99% of landings: ${:.2} to ${:.2}", S0 * (MUJ - 2.5758 * DEL).exp(), S0 * (MUJ + 2.5758 * DEL).exp());
    let ser: Vec<f64> = [1, 2, 6].iter().map(|&nn| merton_full(S0, T, nn, LAM, MUJ, true)).collect();
    let c = merton(S0, T);
    let fact = [1.0, 1.0, 2.0, 6.0, 24.0, 120.0];
    let mut p6 = 0.0; for n in 0..6 { p6 += (-LAM).exp() * LAM.powf(n as f64) / fact[n]; }   // P(N <= 5)
    let bound = S0 * (-(Q + LAM * k) * T).exp() * (1.0 - p6);
    println!("series after 1, 2, 6 terms: {:.6}, {:.6}, {:.6}; tail {:.6}, bound {:.6}", ser[0], ser[1], ser[2], c - ser[2], bound);
    println!("road 1, Merton series: {:.6}", c);
    assert!(0.0 < c - ser[2] && c - ser[2] <= bound);
    assert!((simpson(&|z: f64| z.exp()) - (1.0 + k)).abs() < 1e-9);
    let ev = simpson(&|z: f64| merton((x0() + z).exp(), T));
    println!("jump average E[V(100 Y)] = {:.6}; V at $80, ${:.2}, $100 = {:.6}, {:.6}, {:.6}",
             ev, S0 * MUJ.exp(), merton(80.0, T), merton(S0 * MUJ.exp(), T), c);
    println!("net jump term lambda (E[V] - V) = {:.4} a year", LAM * (ev - c)); let mut res = vec![];
    for e in [0.02, 0.01] {
        let (vp, vm) = (merton((x0() + e).exp(), T), merton((x0() - e).exp(), T));
        let vs = (merton(S0, T + e) - merton(S0, T - e)) / (2.0 * e);
        let terms = [0.5 * SIG.powi(2) * (vp - 2.0 * c + vm) / e.powi(2),
                     (R - Q - LAM * k - 0.5 * SIG.powi(2)) * (vp - vm) / (2.0 * e), -R * c, -LAM * c, LAM * ev];
        let mut t = 0.0; for x in terms { t += x; }
        res.push(vs - t);
        println!("step {}: V_x {:.4}, V_xx {:.4}, V_s {:.4}; diffusion {:.4}, drift {:.4}, -rV {:.4}, -lambda V {:.4}, lambda E[V] {:.4}; sum {:.4}; residual {:.7}",
                 e, (vp - vm) / (2.0 * e), (vp - 2.0 * c + vm) / e.powi(2), vs, terms[0], terms[1], terms[2], terms[3], terms[4], t, res[res.len() - 1]);
    }
    assert!(res[1].abs() < 1e-3 && 3.5 < res[0] / res[1] && res[0] / res[1] < 4.5);
    println!("grid edges ${:.2} to ${:.2}; nodes {}, {}, {}; derivative stencil 3 nodes", S0 * (-1.2f64).exp(), S0 * 1.2f64.exp(),
             (2.4f64 / 0.04).round() as i64 + 1, (2.4f64 / 0.02).round() as i64 + 1, (2.4f64 / 0.01).round() as i64 + 1);
    let cases = [(0.04, 25), (0.02, 50), (0.01, 100)];
    let runs: Vec<(f64, usize)> = cases.iter().map(|&(h, nst)| grid(h, nst, 1.2, 7.0, false)).collect();
    for (&(h, nst), &(v, nw)) in cases.iter().zip(runs.iter()) {
        println!("road 2, grid h = {}, {} steps, jump stencil {} nodes: {:.6}, error {:.6}", h, nst, nw, v, v - c);
    }
    let e: Vec<f64> = runs.iter().map(|&(v, _)| v - c).collect();
    let rich = (4.0 * runs[2].0 - runs[1].0) / 3.0;
    println!("error ratios {:.3}, {:.3}; observed order {:.3}", e[0] / e[1], e[1] / e[2], (e[1] / e[2]).ln() / 2f64.ln());
    println!("Richardson from h = 0.02 and 0.01: {:.6}, off by {:.6}", rich, rich - c);
    assert!(e[2].abs() < 3e-3 && 3.5 < e[1] / e[2] && e[1] / e[2] < 4.5 && (rich - c).abs() < 2e-5);
    println!("what breaks:");
    println!("  no jumps at all (Black-Scholes at 20%): {:.6}; jumps add {:.6}", bs(S0, T, Q, SIG), c - bs(S0, T, Q, SIG));
    println!("  drop the integral, keep -lambda V: {:.6}", (-LAM * T).exp() * bs(S0, T, Q + LAM * k, SIG));
    println!("  drop the compensator: {:.6}", merton_full(S0, T, 40, LAM, MUJ, false));
    let se = (SIG.powi(2) + LAM * (MUJ.powi(2) + DEL.powi(2))).sqrt();
    let qe = Q + LAM * k - LAM * MUJ - 0.5 * LAM * (MUJ.powi(2) + DEL.powi(2));
    println!("  local Taylor stand-in (vol {:.2}%, yield {:.4}%): {:.6}", 100.0 * se, 100.0 * qe, bs(S0, T, qe, se));
    let w2 = grid(0.02, 50, 1.2, 2.0, false);
    println!("  jump stencil cut to mean +- 2 spreads ({} nodes), h = 0.02: {:.6}", w2.1, w2.0);
    assert!(w2.0 < runs[1].0 - 0.1);
    println!("try changing:");
    println!("  one jump a year: {:.6}; gaps of +10% instead: {:.6}",
             merton_full(S0, T, 40, 1.0, MUJ, true), merton_full(S0, T, 40, LAM, 0.10, true));
    let v6 = grid(0.02, 50, 0.6, 7.0, true).0;
    println!("  grid h = 0.02 on ${:.2} to ${:.2}, zero beyond: {:.6}, error {:.6}", S0 * (-0.6f64).exp(), S0 * 0.6f64.exp(), v6, v6 - c);
    assert!((v6 - c).abs() > 3.0 * e[1].abs());
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-15 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
average jump k = -0.084926; compensator lambda k = -0.042463; drift r - q - lambda k = 0.072463 a year
E[Y] by Simpson = 0.915074; 1 + k = 0.915074
where one jump from $100 lands (%): under 70 4.35, 70-80 16.23, 80-90 27.99, 90-100 26.18, 100-110 15.60, 110-120 6.65, over 120 2.99
middle 99% of landings: $61.49 to $133.16
series after 1, 2, 6 terms: 7.244796, 9.864250, 10.416447; tail 0.000030, bound 0.001449
road 1, Merton series: 10.416477
jump average E[V(100 Y)] = 7.595313; V at $80, $90.48, $100 = 2.098518, 5.513266, 10.416477
net jump term lambda (E[V] - V) = -1.4106 a year
step 0.02: V_x 59.9981, V_xx 226.1787, V_s 5.7418; diffusion 4.5236, drift 3.1477, -rV -0.5208, -lambda V -5.2082, lambda E[V] 3.7977; sum 5.7398; residual 0.0019370
step 0.01: V_x 59.9915, V_xx 226.2595, V_s 5.7416; diffusion 4.5252, drift 3.1473, -rV -0.5208, -lambda V -5.2082, lambda E[V] 3.7977; sum 5.7411; residual 0.0004847
grid edges $30.12 to $332.01; nodes 61, 121, 241; derivative stencil 3 nodes
road 2, grid h = 0.04, 25 steps, jump stencil 54 nodes: 10.385672, error -0.030805
road 2, grid h = 0.02, 50 steps, jump stencil 107 nodes: 10.408815, error -0.007662
road 2, grid h = 0.01, 100 steps, jump stencil 213 nodes: 10.414564, error -0.001913
error ratios 4.021, 4.005; observed order 2.002
Richardson from h = 0.02 and 0.01: 10.416480, off by 0.000003
what breaks:
  no jumps at all (Black-Scholes at 20%): 9.227006; jumps add 1.189472
  drop the integral, keep -lambda V: 7.244796
  drop the compensator: 8.071035
  local Taylor stand-in (vol 23.72%, yield 1.9412%): 10.671343
  jump stencil cut to mean +- 2 spreads (32 nodes), h = 0.02: 10.079030
try changing:
  one jump a year: 11.503925; gaps of +10% instead: 10.605291
  grid h = 0.02 on $54.88 to $182.21, zero beyond: 10.372362, error -0.044115
ALL CHECKS PASS
```

The two outputs agree line for line.

### Lean

Lean proves the change to log price behind the PIDE, and the average jump $`k`$, for any rates and jump sizes.

- Take $`V(S) = U(\ln S)`$ with $`U`$ twice differentiable, and $`S > 0`$. Then $`S V_S = U_x`$ and $`S^2 V_{SS} = U_{xx} - U_x`$.
- Take $`U`$ twice differentiable in log price for $`s > 0`$, and set $`V(S, t) = U(\ln S, T - t)`$. Then $`V`$ solves the PIDE in $`S`$ and $`t`$, for $`t < T`$, exactly when $`U`$ solves the PIDE of The formula.
- Take the log jump size $`z`$ as a bell curve with mean $`\mu_J`$ and spread $`\delta`$. Then $`k = E[Y] - 1 = e^{\mu_J + \delta^2/2} - 1`$.

Merton's series, the residual at Acme's point and the grid prices are left to the Python and Rust checks.

```lean
-- When prices jump: the jump-diffusion pricing equation in price and calendar time is the same equation as the log-price PIDE with its integral term, and the compensator is k = exp(μ_J + δ²/2) − 1.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Analysis.Calculus.Deriv.Shift

open Real MeasureTheory ProbabilityTheory

theorem deriv_comp_log_of_differentiable (f : ℝ → ℝ) (hf : Differentiable ℝ f) {S : ℝ}
    (hS : 0 < S) : deriv (fun P => f (log P)) S = deriv f (log S) / S := by
  have h : HasDerivAt (fun P => f (log P)) (deriv f (log S) * S⁻¹) S :=
    (hf (log S)).hasDerivAt.comp S (hasDerivAt_log hS.ne')
  rw [h.deriv, div_eq_mul_inv]

theorem deriv_deriv_comp_log_of_differentiable (f : ℝ → ℝ) (hf : Differentiable ℝ f)
    (hf' : Differentiable ℝ (deriv f)) {S : ℝ} (hS : 0 < S) :
    deriv (fun P => deriv (fun P' => f (log P')) P) S
      = (deriv (deriv f) (log S) - deriv f (log S)) / S ^ 2 := by
  have heq : (fun P => deriv (fun P' => f (log P')) P) =ᶠ[nhds S]
      (fun P => deriv f (log P) / P) := by
    filter_upwards [Ioi_mem_nhds hS] with P hP
    exact deriv_comp_log_of_differentiable f hf hP
  rw [heq.deriv_eq]
  have h1 : HasDerivAt (fun P => deriv f (log P)) (deriv (deriv f) (log S) * S⁻¹) S :=
    (hf' (log S)).hasDerivAt.comp S (hasDerivAt_log hS.ne')
  have h2 : HasDerivAt (fun P => deriv f (log P) / P)
      ((deriv (deriv f) (log S) * S⁻¹ * S - deriv f (log S) * 1) / S ^ 2) S :=
    h1.div (hasDerivAt_id' S) hS.ne'
  rw [h2.deriv]
  field_simp

#print axioms deriv_comp_log_of_differentiable
#print axioms deriv_deriv_comp_log_of_differentiable

/-- The PIDE in log price. A value `U x s` (log price `x`, time to expiry `s`) is a classical
solution for `s > 0` when, for every `x` and every `s > 0`,
`U_s = ½σ² U_xx + (r − q − λk − ½σ²) U_x − (r + λ) U + λ ∫ U(x + z, s) g(z) dz`,
where `g` is the bell-curve density of the log jump size, with mean `μJ` and spread `δ`,
and `k = exp(μJ + δ²/2) − 1` is the average jump. -/
def LogPIDE (r q σ lam μJ δ : ℝ) (U : ℝ → ℝ → ℝ) : Prop :=
  ∀ x : ℝ, ∀ s : ℝ, 0 < s →
    deriv (fun τ => U x τ) s =
      (1 / 2) * σ ^ 2 * deriv (fun y => deriv (fun w => U w s) y) x
      + (r - q - lam * (exp (μJ + δ ^ 2 / 2) - 1) - (1 / 2) * σ ^ 2) * deriv (fun y => U y s) x
      - (r + lam) * U x s
      + lam * ∫ z, U (x + z) s * gaussianPDFReal μJ (δ ^ 2).toNNReal z

/-- **Jumps add one integral term to the pricing equation.** Let `U` be twice differentiable
in log price for every time to expiry `s > 0` (a classical solution), and write the value in
share price `S` and calendar time `t` as `V(S, t) = U(ln S, T − t)`. Then `V` solves the
price-form jump-diffusion pricing equation, for every `S > 0` and `t < T`,
`V_t + (r − q − λk) S V_S + ½σ² S² V_SS − rV + λ (E[V(SY, t)] − V(S, t)) = 0`,
where a jump multiplies the price by `Y = e^z` with `z` drawn from the bell curve `g`,
exactly when `U` solves the log-price PIDE. -/
theorem jump_pricing_equation_iff_log_pide
    (r q σ lam μJ δ T : ℝ) (U : ℝ → ℝ → ℝ)
    (hU1 : ∀ s : ℝ, 0 < s → Differentiable ℝ (fun x => U x s))
    (hU2 : ∀ s : ℝ, 0 < s → Differentiable ℝ (fun x => deriv (fun y => U y s) x)) :
    (∀ S : ℝ, 0 < S → ∀ t : ℝ, t < T →
      deriv (fun τ => U (log S) (T - τ)) t
      + (r - q - lam * (exp (μJ + δ ^ 2 / 2) - 1)) * S
          * deriv (fun P => U (log P) (T - t)) S
      + (1 / 2) * σ ^ 2 * S ^ 2
          * deriv (fun P => deriv (fun P' => U (log P') (T - t)) P) S
      - r * U (log S) (T - t)
      + lam * ((∫ z, U (log (S * exp z)) (T - t) * gaussianPDFReal μJ (δ ^ 2).toNNReal z)
                - U (log S) (T - t)) = 0)
    ↔ LogPIDE r q σ lam μJ δ U := by
  -- pointwise rewriting of the price-form expression into log-price quantities
  have key : ∀ S : ℝ, 0 < S → ∀ s : ℝ, 0 < s →
      deriv (fun τ => U (log S) (T - τ)) (T - s)
      + (r - q - lam * (exp (μJ + δ ^ 2 / 2) - 1)) * S
          * deriv (fun P => U (log P) s) S
      + (1 / 2) * σ ^ 2 * S ^ 2
          * deriv (fun P => deriv (fun P' => U (log P') s) P) S
      - r * U (log S) s
      + lam * ((∫ z, U (log (S * exp z)) s * gaussianPDFReal μJ (δ ^ 2).toNNReal z)
                - U (log S) s)
      = -(deriv (fun τ => U (log S) τ) s -
          ((1 / 2) * σ ^ 2 * deriv (fun y => deriv (fun w => U w s) y) (log S)
          + (r - q - lam * (exp (μJ + δ ^ 2 / 2) - 1) - (1 / 2) * σ ^ 2)
              * deriv (fun y => U y s) (log S)
          - (r + lam) * U (log S) s
          + lam * ∫ z, U (log S + z) s * gaussianPDFReal μJ (δ ^ 2).toNNReal z)) := by
    intro S hS s hs
    have ht : deriv (fun τ => U (log S) (T - τ)) (T - s) = -deriv (fun τ => U (log S) τ) s := by
      rw [deriv_comp_const_sub (f := fun τ => U (log S) τ)]
      simp
    have h1 := deriv_comp_log_of_differentiable (fun w => U w s) (hU1 s hs) hS
    have h2 := deriv_deriv_comp_log_of_differentiable (fun w => U w s) (hU1 s hs) (hU2 s hs) hS
    have hint : (∫ z, U (log (S * exp z)) s * gaussianPDFReal μJ (δ ^ 2).toNNReal z)
        = ∫ z, U (log S + z) s * gaussianPDFReal μJ (δ ^ 2).toNNReal z := by
      congr 1
      funext z
      rw [log_mul hS.ne' (exp_pos z).ne', log_exp]
    rw [ht, h1, h2, hint]
    have hS2 : S ^ 2 ≠ 0 := pow_ne_zero 2 hS.ne'
    field_simp
    ring
  constructor
  · intro h x s hs
    have hh := h (exp x) (exp_pos x) (T - s) (by linarith)
    rw [sub_sub_cancel, key (exp x) (exp_pos x) s hs, log_exp] at hh
    linarith
  · intro h S hS t ht
    have hk := key S hS (T - t) (by linarith)
    rw [sub_sub_cancel] at hk
    rw [hk, h (log S) (T - t) (by linarith)]
    ring

/-- **The compensator.** If the log jump size is a bell curve with mean `μJ` and spread `δ`,
the average jump factor is `E[Y] = E[e^z] = exp(μJ + δ²/2)`, so the average jump as a
fraction of the price is `k = E[Y] − 1 = exp(μJ + δ²/2) − 1`. -/
theorem average_jump_eq_compensator (μJ δ : ℝ) :
    (∫ z, exp z ∂(gaussianReal μJ (δ ^ 2).toNNReal)) - 1 = exp (μJ + δ ^ 2 / 2) - 1 := by
  have h := congrFun (mgf_id_gaussianReal (μ := μJ) (v := (δ ^ 2).toNNReal)) 1
  simp only [mgf, id, one_mul, one_pow, mul_one] at h
  rw [h, Real.coe_toNNReal _ (sq_nonneg δ)]

#print axioms jump_pricing_equation_iff_log_pide
#print axioms average_jump_eq_compensator
```

**Checked 2026-11-15 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'deriv_comp_log_of_differentiable' depends on axioms: [propext, Classical.choice, Quot.sound]
'deriv_deriv_comp_log_of_differentiable' depends on axioms: [propext, Classical.choice, Quot.sound]
'jump_pricing_equation_iff_log_pide' depends on axioms: [propext, Classical.choice, Quot.sound]
'average_jump_eq_compensator' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> - Guess first: if Acme gaps once a year instead of once every two years, does the call gain as much again? Call `merton(S0, T, lam=1.0)`. It costs $11.503925, against $10.416477: a second gain, a little smaller than the first $1.189472.
> - Guess first: if the gaps go up 10% instead of down, is the call dearer or cheaper? Call `merton(S0, T, muj=0.10)`. It costs $10.605291, more than with downward gaps: upward gaps fatten the right tail, where the call pays, while the compensator keeps the average price at the forward.
> - Guess first: if the grid runs only from $54.88 to $182.21 and treats every value beyond as zero, how far off is it? Call `grid(0.02, 50, L=0.6, zero=True)`. It gives $10.372362, an error of −0.044115, against −0.007662 for the full grid at the same step: jumps from near the top edge land beyond it, where the call is worth a lot, not zero.

---

## The usual mistake

> [!warning]
> **Treating the jump term as if it were local.** A derivative needs only the neighbours of a point; the jump integral needs the value everywhere a jump can land. Replace it by a slope and a curvature at the point and the call comes out at $10.671343 instead of $10.416477. Cut the grid's jump stencil to the mean ± 2 spreads and it comes out at $10.079030 instead of $10.408815.
>
> - **Keeping only the $`-\lambda V`$ part.** The integral is the half that brings value back. Without it the price is $7.244796, Merton's no-jump term alone.
> - **Forgetting the compensator.** The drift between jumps must be $`r - q - \lambda k`$, not $`r - q`$. Without the extra 0.042463 a year, the price is $8.071035.
> - **Setting values beyond the grid to zero.** Jumps from nodes near the edge land outside it. On a grid from $54.88 to $182.21 the price falls to $10.372362.
> - **Underrating the cost of refining.** The jump stencil grows as the step shrinks: 54, 107, then 213 nodes. Each halving of the step doubles the nodes, the time steps and the stencil, so without fast convolution the work grows far faster than for Black-Scholes.

---

## Where you meet it in real life

- **Equity index options.** Index options show a steep skew: low-strike puts are dear. Desks fit jump-diffusion PIDEs to that skew, as Andersen and Andreasen did, and price the exotic options the skew affects on PIDE grids.
- **Default risk.** A company's shares can jump to near zero on bankruptcy. A jump to default is a PIDE whose jump lands at one price, and equity and credit desks price convertible bonds this way.
- **Electricity prices.** A cold snap or a failed power station makes the price spike. Options on power use the same PIDE, with upward jumps ([Jump diffusions](../../11-Stochastic%20processes%20and%20calculus/09-Beyond%20Brownian/02-jump-diffusions.md)).
- **Insurance.** An insurer's capital rises steadily with premiums and drops at each claim. Its chance of ruin satisfies an integro-differential equation of the same shape, with the claim-size law as the kernel.

> **Say it back**
> When a share price can gap, the option's value at one price depends directly on its value at every price a gap can reach. The pricing equation is then Black-Scholes plus a jump term: the jump rate times the average change in value over all landing prices. That term is an integral, so the equation is a PIDE, and its integral makes every grid row reach across the whole jump range. Grids solve it with a tridiagonal step for the derivatives and fixed-point passes for the integral; for Acme they reach $10.414564 at the finest step, second order, against Merton's exact $10.416477.

---

## What this builds on

- [Integral equations](07-integral-equations-fredholm-and-volterra.md): an unknown inside its own integral, and the fixed-point passes used here on the jump term.
- [Black-Scholes is the heat equation after a change of variables](../03-The%20Heat%20Equation%20in%20Depth/07-black-scholes-to-the-heat-equation.md): log price, time to expiry and the no-jump equation, which is this PIDE with $`\lambda = 0`$.
- [Jump diffusions](../../11-Stochastic%20processes%20and%20calculus/09-Beyond%20Brownian/02-jump-diffusions.md): Ito's lemma with jumps and the generator's jump part $`\lambda\big(E[f(xY)] - f(x)\big)`$, put into the backward equation here.
- [Merton jump-diffusion](../../12-Financial%20mathematics/13-Local%20volatility%20and%20jumps/04-merton-jump-diffusion.md): the model, the compensator and the series price that checks the grid.

---

## Where this goes next

- [Pricing by transform](../../20-Harmonic%20analysis/04-Characteristic%20Functions%20and%20Probability/09-carr-madan-and-fourier-pricing.md): the convolution in the PIDE becomes a multiplication, and one fast transform prices every strike.
- [An American option](../06-Weak%20Solutions%20and%20Free%20Boundaries/09-american-options-as-a-free-boundary-problem.md): the American version, where the equation holds only where early exercise does not pay; with jumps it gains this card's integral term.

The other cards on this shelf treat fluids and patterns: [Navier-Stokes](01-navier-stokes-derivation.md), [Leray's weak solutions](02-leray-weak-solutions-of-navier-stokes.md), [The energy inequality, and the gap it leaves in three dimensions](03-energy-inequality-and-the-regularity-question.md), [Vorticity](04-vorticity-and-the-euler-equations.md), [Reaction-diffusion](05-reaction-diffusion-and-pattern-formation.md) and [Solitons](06-nonlinear-schrodinger-and-solitons-in-outline.md). Earlier on this shelf, [The Fredholm alternative](08-fredholm-alternative-and-compact-operators.md) decides when an equation with an integral operator has exactly one solution, the question behind every fixed-point pass.

This card leaves one question open: when the jumps are infinitely many and tiny, so the kernel blows up near zero, how does a grid keep its second order?

---

## Sources

Verified 2026-11-15: every link below resolves to the publisher's page.

- Merton, Robert C. "Option pricing when underlying stock returns are discontinuous." *Journal of Financial Economics* 3, no. 1–2 (1976): 125–144. [doi:10.1016/0304-405X(76)90022-2](https://doi.org/10.1016/0304-405X(76)90022-2). The model, the integro-differential pricing equation and the series solution used as the check.
- Andersen, Leif, and Jesper Andreasen. "Jump-Diffusion Processes: Volatility Smile Fitting and Numerical Methods for Option Pricing." *Review of Derivatives Research* 4, no. 3 (2000): 231–262. [doi:10.1023/A:1011354913068](https://doi.org/10.1023/A:1011354913068). The PIDE fitted to an index skew, with the integral handled by fast convolution.
- Cont, Rama, and Ekaterina Voltchkova. "A Finite Difference Scheme for Option Pricing in Jump Diffusion and Exponential Lévy Models." *SIAM Journal on Numerical Analysis* 43, no. 4 (2005): 1596–1626. [doi:10.1137/S0036142903436186](https://doi.org/10.1137/S0036142903436186). Viscosity solutions of the PIDE, uniqueness, the treatment of small jumps and of values beyond the grid, and a convergence proof.
- d'Halluin, Y., P. A. Forsyth, and K. R. Vetzal. "Robust numerical methods for contingent claims under jump diffusion processes." *IMA Journal of Numerical Analysis* 25, no. 1 (2005): 87–112. [doi:10.1093/imanum/drh011](https://doi.org/10.1093/imanum/drh011). Crank-Nicolson with fixed-point passes on the jump term, as in the checks.
- Boyarchenko, Svetlana I., and Sergei Z. Levendorskii. *Non-Gaussian Merton-Black-Scholes Theory*. World Scientific, 2002. [doi:10.1142/4955](https://doi.org/10.1142/4955). Pricing under jump processes by transforms, and the Wiener-Hopf factorisation for barrier and American options.
