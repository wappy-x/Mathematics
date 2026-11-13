# Duration and convexity: how a bond price moves when its yield moves

[Syllabus](../../../SYLLABUS.md) → [Financial mathematics](../README.md) → [Money, Dates and Discounting](../README.md#s01) → Duration and convexity

---

## General Overview

The house bond pays 60 dollars a year, its coupon, for five years and hands back 1,000 dollars, its face value, with the last payment. At a market yield of five percent, the one rate every payment is discounted at, it sells for **$1,043.29** ([Bond price and yield](05-bonds-price-and-yield.md)).

Rates rise. The yield goes to six percent. Price the five payments again, one at a time, and the total comes out at exactly **$1,000.00** — face value, because a six percent yield now matches the six percent coupon.

Repricing is fine for one bond. A trading desk holding four hundred of them wants the answer before the move, for any size of move, without rebuilding four hundred payment schedules. It wants one or two numbers per bond that stand in for the whole calculation.

Two numbers do it. Plot the bond's price against its yield and a curve appears, falling to the right. The **slope** of that curve, scaled by the price, says what fraction of its value the bond loses per unit of yield: that is **duration**, 4.264525 here. The curve is not straight, so a second number measures the **bend**: **convexity**, 23.444091.

Watch them work on the one-point rise. The slope on its own predicts $998.80. Slope plus bend predicts $1,000.03. The truth is $1,000.00. Duration alone was $1.20 out on a thousand-dollar bond; adding convexity cut the miss to under three cents.

**Duration is the slope of a bond's price-against-yield curve and convexity is its bend, so a yield move turns into a price move by arithmetic instead of a reprice.**

**What kind of fact this is:** an approximation, and this card states its error — the second-order price move comes with a bound that the checks confirm on both a rise and a fall. The two durations and convexity are definitions; that modified duration and convexity come from the price's first and second derivatives is a theorem, proved in Why it works.

### The picture: the curve, and the straight line duration draws through it

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "The house bond priced at every yield, against what duration alone predicts"
    x-axis "Market yield, percent a year" [3, 3.5, 4, 4.5, 5, 5.5, 6, 6.5, 7]
    y-axis "Price in dollars, face 1000" 940 --> 1160
    line [1137.39, 1112.88, 1089.04, 1065.85, 1043.29, 1021.35, 1000.00, 979.22, 959.00]
    line [1132.28, 1110.03, 1087.79, 1065.54, 1043.29, 1021.05, 998.80, 976.56, 954.31]
```

The bending line is the bond's real price. The straight line is duration's prediction: the tangent, which touches the curve at a five percent yield and shares its slope there. They agree at five percent and part company either side, with the curve above the line in both directions. That gap is convexity: a rise costs less than duration threatens, a fall pays more than it promises.

---

## The formula

Three pieces of notation first, in words.

- The tall sigma sign, with $t$ running from 1 to $N$, says: write one term for each year and add them up.
- A **derivative**, written $dP/dy$, is the rate at which the price changes as the yield changes — the slope of the curve above. Doing it twice, $d^2P/dy^2$, gives the rate at which that slope itself changes: the bend.
- Capital delta marks a change, so $\Delta y$ is a yield move and $\Delta P$ the price move it causes.

Rates are decimals inside a formula: one percentage point is $\Delta y = 0.01$.

The price of a bond, from the previous card, with $A_t$ standing for the whole amount paid in year $t$ — the coupon, and in the final year the coupon plus the face:

$$P(y) \;=\; \sum_{t=1}^{N} \frac{A_t}{(1+y)^{t}}$$

Each payment's share of today's price is its **weight**. The weights are what turn a pile of dates into one number:

$$w_t \;=\; \frac{A_t/(1+y)^t}{P}, \qquad D_{\text{Mac}} \;=\; \sum_{t=1}^{N} t\,w_t, \qquad D_{\text{mod}} \;=\; \frac{D_{\text{Mac}}}{1+y}$$

**Read it aloud:** weigh each payment by the share of the price it accounts for, average the payment years under those weights to get Macaulay duration, then divide by one plus the yield to get modified duration — the fraction of its price the bond loses per unit of yield.

Convexity is the same list of payments weighted by $t(t+1)$ instead of $t$, with two extra years of discounting:

$$C \;=\; \frac{1}{P}\sum_{t=1}^{N} \frac{t(t+1)\,A_t}{(1+y)^{t+2}}$$

And the two of them together answer the question the card asks:

$$\frac{\Delta P}{P} \;\approx\; -\,D_{\text{mod}}\,\Delta y \;+\; \tfrac12\,C\,(\Delta y)^2$$

**Read it aloud:** the price falls by duration times the yield move, then bends back up by half the convexity times the move squared.

| Symbol | Plain meaning | In the house bond | Push it up and the price move… |
| --- | --- | --- | --- |
| $P$ | the price: what the bond sells for today | $1,043.29 | — |
| $y$ | the yield: the one rate every payment is discounted at | 5% | shrinks, because everything is discounted harder already |
| $A_t$ | the amount paid in year $t$ | 60 four times, then 1,060 | grows: more money is exposed to the rate |
| $t$ | which year a payment lands in | 1 to 5 | — |
| $N$ | years until the last payment | 5 | grows sharply: far-off money is rate-sensitive money |
| $w_t$ | that payment's share of today's price | 0.054772 in year 1, 0.796072 in year 5 | pulls the average year toward that payment |
| $D_{\text{Mac}}$ | Macaulay duration: the weighted average year a dollar comes back | 4.477751 years | grows |
| $D_{\text{mod}}$ | modified duration: fraction of price lost per unit of yield | 4.264525 | grows in proportion |
| $C$ | convexity: how fast the slope itself changes, in years squared | 23.444091 | the correction grows, and always upward |
| $M$ | the most the third derivative can reach in size across a move | the error bound's only input | — |
| $R$ | what the two terms leave out | at most 0.026649 on the one-point rise | — |

One more number falls straight out, and desks quote it more often than duration. A **basis point** is a hundredth of a percentage point. **DV01** is the cash lost on a one-basis-point rise:

$$\text{DV01} \;=\; D_{\text{mod}} \times P \times 0.0001$$

For the house bond that is $0.444916, a shade under 45 cents per 1,000 dollars of face. Duration is a percentage; DV01 is cash, and cash is what adds up across a book, all of a desk's positions.

### When it holds

- **One yield moves, and it moves every payment together.** A curve that twists — short rates up, long rates down — is not a move in $y$ at all, and no single duration describes it.
- **The payments are fixed.** Nothing may cancel, reschedule or repay early. When the payments themselves react to rates, as a callable bond's or a mortgage's do, the bend can turn the other way: [Negative convexity](../35-Mortgages%2C%20Callables%20and%20Prepayment/03-negative-convexity.md).
- **The move is modest.** What the two terms leave out grows as the cube of the move. On this bond a one-point move leaves under three cents unaccounted for; a three-point rise leaves 0.680863 dollars unaccounted for, and the two numbers are no longer enough.
- **The yield stays above minus one hundred percent,** so $(1+y)$ is positive and the discounting means something.
- **The quote is annual, as here.** Conventions verified 14 September 2026: this card uses one coupon a year discounted at an annual yield. A bond quoted with two coupons a year discounts once per half-year, so with $t$ still in years $(1+y)^t$ becomes $(1+y/2)^{2t}$, modified duration divides by $(1+y/2)$, and convexity weights each year by $t(t+\tfrac12)$. The calendar rule that fixes each $t$ is its own card: [Day counts](02-day-counts-and-dates.md).

---

## Why it works

### Step 0: freeze the contract and one number is left moving

The bond's payments and their dates are printed in the contract. None of them change when the market changes its mind about interest rates. The only thing that moves is the yield.

So the price is a function of one number, and everything known about such functions applies: it has a slope, the slope has a slope, and Taylor's theorem turns those two into a prediction with a stated error ([Taylor's theorem](../../06-Calculus%20and%20analysis/03-What%20Derivatives%20Tell%20You/05-taylors-theorem.md)). That is the whole card; the rest is working out the two slopes for this particular function.

### Step 1: differentiate once, and a weighted average time falls out

Each payment contributes $A_t/(1+y)^t$ to the price: the amount, times the discount factor for its year ([Discount factors](01-compounding-and-discount-factors.md)). Nudge the yield up and that term shrinks, and it shrinks faster the further off the payment is, because it is being divided by $(1+y)$ more times. Differentiating one term gives $-t\,A_t/(1+y)^{t+1}$: the extra factor of $t$ is the whole story, and it is why long bonds are dangerous.

Add the terms and pull out one factor of $(1+y)$:

$$-\frac{dP}{dy} \;=\; \frac{1}{1+y}\sum_{t=1}^{N} \frac{t\,A_t}{(1+y)^{t}}$$

Divide by the price. Each $A_t/(1+y)^t$ over $P$ is the weight $w_t$, so what is left is an average of the years $t$ under those weights:

$$-\frac{1}{P}\frac{dP}{dy} \;=\; \frac{1}{1+y}\sum_{t=1}^{N} t\,w_t \;=\; \frac{D_{\text{Mac}}}{1+y} \;=\; D_{\text{mod}}$$

The checks confirm it the honest way: they get the slope by nudging the yield up and down, never touching the weights, and land on the same 4.264525.

<details>
<summary>The algebra behind this</summary>

Write one term as $A_t (1+y)^{-t}$. The power rule sends $(1+y)^{-t}$ to $-t(1+y)^{-t-1}$, so the term's derivative is $-t A_t (1+y)^{-t-1}$. Summing over $t$ gives
$$\frac{dP}{dy} = -\sum_{t=1}^{N} t\,A_t\,(1+y)^{-t-1} = -\frac{1}{1+y}\sum_{t=1}^{N} t\,A_t\,(1+y)^{-t}.$$
Divide both sides by $-P$ and insert $w_t = A_t(1+y)^{-t}/P$. The weights are non-negative and add to one, since their numerators are the pieces the price was built from, so $\sum t\,w_t$ is a genuine average of the numbers 1 to $N$ and must land between them.

</details>

### Step 2: the same number is the bond's centre of gravity

Macaulay duration was defined as an average of payment years, so it is measured in years — and that gives it a second meaning with no calculus in it. Lay the five payments along a line at their dates, each weighing what it contributes to today's price. Macaulay duration is the balance point.

For the house bond it is 4.477751 years, short of the five years to maturity: the four coupons hand part of the money back early and pull the balance point in. The final payment is 0.796072 of the price on its own, which is why the point still sits close to year five.

A bond with no coupons pays once, at maturity, so all the weight sits at one date and the balance point is that date: a five-year zero-coupon bond has a Macaulay duration of exactly 5.000000 years, which the checks confirm.

### Step 3: differentiate twice, and the bend is always upward

Differentiate the terms of $dP/dy$ once more. Each $-t A_t (1+y)^{-t-1}$ becomes $t(t+1) A_t (1+y)^{-t-2}$:

$$\frac{d^2P}{dy^2} \;=\; \sum_{t=1}^{N} \frac{t(t+1)\,A_t}{(1+y)^{t+2}}$$

Divide by the price and that is $C$, convexity, 23.444091 for the house bond.

Now look at what the formula cannot do. Every payment $A_t$ is positive, every $t(t+1)$ is positive, every power of $(1+y)$ is positive. A sum of positive things is positive, so the second derivative is positive for any bond whose payments are all positive.

A positive second derivative means the slope is rising: the curve flattens as the yield climbs, and it sits above every tangent it has. That is the promise in the first picture, and it holds for far more than this one bond.

<details>
<summary>The algebra behind this</summary>

Applying the power rule to $(1+y)^{-t-1}$ gives $(-t-1)(1+y)^{-t-2}$. The term $-t A_t (1+y)^{-t-1}$ therefore differentiates to $t(t+1) A_t (1+y)^{-t-2}$, and summing gives the displayed second derivative.

In weights, $C = \frac{1}{(1+y)^2}\sum_t t(t+1) w_t$: a weighted average of $t(t+1)$, discounted twice more. Since $t(t+1)$ grows about as the square of $t$, convexity grows about as the square of a bond's length while duration grows in proportion to it — which is why convexity matters far more on a thirty-year bond than on a two-year one.

One more differentiation gives $\frac{d^3P}{dy^3} = -\sum_t t(t+1)(t+2) A_t (1+y)^{-t-3}$, which Step 4 needs.

</details>

### Step 4: Taylor's theorem stitches them together and bounds the leftover

Taylor's theorem says a function with three continuous derivatives equals its value, plus its slope times the step, plus half its bend times the step squared, plus a remainder $R$. $R$ is one sixth of the third derivative, taken somewhere along the way, times the step cubed. Written for the price, moving the yield by $\Delta y$:

$$P(y+\Delta y) \;=\; P(y)\Big[1 - D_{\text{mod}}\,\Delta y + \tfrac12\,C\,(\Delta y)^2\Big] \;+\; R$$

The remainder is not left vague. The third derivative is a sum of terms sitting over powers of $(1+y)$, so its size is largest at the low end of the move. Take the lower of the two yields — the starting one on a rise, the ending one on a fall — and call it the move's floor. The largest size the third derivative reaches anywhere on that move, written $M$, then caps the leftover:

$$M \;=\; \sum_{t=1}^{N} \frac{t(t+1)(t+2)\,A_t}{(1+y_{\text{floor}})^{t+3}}, \qquad |R| \;\le\; \frac{M\,|\Delta y|^3}{6}$$

That is a certificate, computed before the move is made, and it covers the whole move rather than just its endpoint. On the one-point rise it says the leftover is at most 0.026649 dollars; the actual leftover is 0.026155. On the one-point fall it says at most 0.028743; the actual is 0.027159. Both are asserted in the checks.

<details>
<summary>Detailed proof: why the low end of the move bounds the whole of it</summary>

The price is a finite sum of powers of $(1+y)$, so it has continuous derivatives of every order wherever $(1+y)$ is positive. Fix the starting yield $y$ and a move $\Delta y$ with both ends above minus one hundred percent, and write $y_{\text{floor}}$ for the lower of the two.

Taylor's theorem with the Lagrange form of the remainder gives, for some yield $u$ strictly between $y$ and $y + \Delta y$,
$$P(y+\Delta y) = P(y) + P'(y)\,\Delta y + \tfrac12 P''(y)\,(\Delta y)^2 + \tfrac16 P'''(u)\,(\Delta y)^3 .$$
Substituting $P'(y) = -D_{\text{mod}} P(y)$ from Step 1 and $P''(y) = C\,P(y)$ from Step 3 produces the bracketed form above, with $R = \tfrac16 P'''(u)(\Delta y)^3$.

The bound now only needs the size of $P'''$ on the segment. From Step 3's last line,
$$|P'''(u)| = \sum_{t=1}^{N} \frac{t(t+1)(t+2)\,A_t}{(1+u)^{t+3}},$$
and every term of that sum shrinks as $u$ grows, because $u$ sits in a denominator raised to a positive power. So the whole expression is largest at the move's floor, giving $|P'''(u)| \le M$ and $|R| \le M|\Delta y|^3/6$.

Two limits. It bounds the truncation error alone: a wrongly assembled payment schedule, or a yield that is itself a guess, needs its own accounting. And as the floor approaches minus one hundred percent the bound blows up, so no claim is made that every move is well approximated.

</details>

The third derivative is negative for a bond with positive payments, so the remainder has the opposite sign to the cube of the move. The two-term estimate therefore sits above the true price on a rise and below it on a fall. Both appear in the checks, as an error of $-0.026155$ going up and $+0.027159$ coming down.

There is a second road to any single answer here, needing no calculus: reprice the bond at the new yield and subtract. It is exact, and the checks use it as the yardstick. Duration and convexity earn their keep elsewhere — they combine across a portfolio, so one line on a risk report can stand for a thousand positions.

---

## Worked numbers, by hand

The house bond, at a five percent yield, to six decimals.

| Step | Arithmetic | Value |
| --- | --- | --- |
| year 1 payment, discounted | $60 / 1.05$ | 57.142857 |
| year 2 | $60 / 1.05^2$ | 54.421769 |
| year 3 | $60 / 1.05^3$ | 51.830256 |
| year 4 | $60 / 1.05^4$ | 49.362148 |
| year 5, coupon plus face | $1060 / 1.05^5$ | 830.537736 |
| price | the five added | **1,043.294767** |
| year 5's weight | $830.537736 / 1043.294767$ | 0.796072 |
| Macaulay duration | $0.054772 + 0.104327 + 0.149038 + 0.189255 + 3.980360$ | **4.477751 years** |
| modified duration | $4.477751 / 1.05$ | **4.264525** |
| convexity | weighted $t(t+1)$, twice more discounted | **23.444091** |
| DV01 | $4.264525 \times 1043.294767 \times 0.0001$ | **0.444916** |
| a one-point rise, duration only | $1043.294767 \times (1 - 4.264525 \times 0.01)$ | **998.803201** |
| the convexity correction | $\tfrac12 \times 23.444091 \times 0.01^2$ | **+0.117220%** |
| the same rise, with convexity | duration-only plus that correction | **1,000.026155** |
| the bond, simply repriced at 6% | $60/1.06 + \dots + 1060/1.06^5$ | **1,000.000000** |

In the world: the bond loses 4.149812 percent of its value when the market yield rises one point. Duration on its own claimed 4.264525 percent; the convexity term hands back 0.117220 percentage points of it, and what is still missing is under three cents on a bond worth over a thousand dollars.

Run it the other way and the asymmetry shows. A one-point fall lifts the bond 4.384349 percent, more than the 4.264525 percent duration promised. Same duration, same size of move, bigger gain than loss — that is convexity, and it is why a bond holder would rather own a convex bond than a straight-line one.

### How wrong the straight line gets, by size of the move

Dollars missed on 1,000 of face, yield rising, duration used alone (bp is a basis point):

```
   10 bp  ▏                                   $0.01
   50 bp  █                                   $0.30
  100 bp  ████                                $1.20
  200 bp  ████████████████                    $4.69
  300 bp  ███████████████████████████████████ $10.33
```

Double the move and the miss roughly quadruples: $1.20 at a hundred basis points becomes $4.69 at two hundred. That squaring is what the convexity term is shaped to catch, which is why one extra number closes so much of the gap.

### What breaks if you drop a piece

Same bond, same one-point rise, right answer 1,000.000000:

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Macaulay duration used where modified belongs | 996.578622 | The missing division by 1.05 overstates the fall by a factor of 1.05 |
| Convexity term without the one-half | 1001.249110 | Taylor's second term carries a half; doubling it overshoots past the true price |
| Convexity term subtracted instead of added | 997.580246 | The curve is above its tangent, so the correction is upward on a rise and a fall alike |
| A hundred basis points typed as 1.0 | −3,405.861841 | A yield move is a decimal. Read as 100 percentage points it returns a negative price |

---

## Duration and convexity do not stay put

A hedge built on this morning's duration is wrong by the afternoon, and nothing needs to happen in the market for that to be true. Duration is a slope measured at one yield on one day. Move the yield, or move the day, and it changes.

Take the day first. Hold the yield at five percent and let the bond age:

| Years still to run | Modified duration |
| --- | --- |
| 5 | 4.26 |
| 4 | 3.50 |
| 3 | 2.70 |
| 2 | 1.85 |
| 1 | 0.95 |

Every year the bond lives through, it sheds the best part of a year of duration, and more of one near the end. On a risk report, a five-year bond and the same bond four years later are different instruments.

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Modified duration of the same bond as the years run off, yield held at 5 percent"
    x-axis "Years still to run" [1, 2, 3, 4, 5]
    y-axis "Modified duration" 0 --> 5
    line [0.95, 1.85, 2.70, 3.50, 4.26]
```

The single line is the bond's modified duration, read off at each remaining maturity.

Now the yield. Hold the maturity at five years and slide the yield instead: duration is 4.37 at a three percent yield, 4.26 at five percent, 4.16 at seven percent. The slide is gentle, and it is the bend showing itself from another angle: a curve with no bend would have the same slope at every yield. The more convexity a bond carries, the faster its duration falls as rates climb.

So the number a desk hedges with has a shelf life, which is why a rates book is re-measured daily and rebalanced when it drifts. Carrying the arithmetic onto an instrument with two legs is [Swap DV01](../28-Swaps/03-swap-dv01-and-hedging.md).

---

## Code, from first principles, and it actually runs

Nothing is imported, in either language. Three independent roads reach the same numbers, and a fourth certifies the error.

1. The first builds duration and convexity out of present-value weighted sums.
2. The second never mentions a weight: it nudges the yield up and down and reads the slope and the bend straight off the price function.
3. The third prices the bond in whole numbers — a 5% yield is exactly 21/20, so the price is one integer over another, with a single division at the end.
4. The fourth is Step 4's bound, computed before the estimate is made.

The outputs also carry every number quoted anywhere on this card, each plotted point and each bar included.

### Python

```python
# Duration and convexity -- the check behind the card.  Nothing is imported.
# The bond: 1,000 face, 6% annual coupon, five years, priced at a 5% yield.
# Four roads reach the same numbers: present-value weighted sums; central
# differences on the price function itself; whole-number arithmetic with a
# single division at the end; and a certified bound on what the second-order
# estimate leaves out.
FACE, COUPON, YEARS, Y, UP = 1000, 60, 5, 0.05, 0.01

def flows(face=FACE, coupon=COUPON, years=YEARS):
    return [(t, coupon + (face if t == years else 0)) for t in range(1, years + 1)]

def price(y, fl):
    return sum(c / (1.0 + y) ** t for t, c in fl)

def macaulay(y, fl):                 # road 1: the present-value weighted average time
    return sum(t * c / (1.0 + y) ** t for t, c in fl) / price(y, fl)

def convexity(y, fl):                # road 1: weighted t(t+1), two extra discounts
    return sum(t * (t + 1) * c / (1.0 + y) ** (t + 2) for t, c in fl) / price(y, fl)

def third_size(y, fl):               # the largest the third derivative gets on a move
    return sum(t * (t + 1) * (t + 2) * c / (1.0 + y) ** (t + 3) for t, c in fl)

def slope(y, fl, h=1e-5):            # road 2: dP/dy by nudging the yield both ways
    return (price(y + h, fl) - price(y - h, fl)) / (2.0 * h)

def bend(y, fl, h=1e-4):             # road 2: d2P/dy2 by nudging the yield both ways
    return (price(y + h, fl) - 2.0 * price(y, fl) + price(y - h, fl)) / (h * h)

def exact_price(a, b, fl, n=YEARS):  # road 3: (1+y) = a/b, whole numbers, one division
    return sum(c * b ** t * a ** (n - t) for t, c in fl) / a ** n

def pair(label, vals):
    print(f"{label:<38}" + "".join(f"{v:>15.6f}" for v in vals))

fl = flows()
P = price(Y, fl)
Dmac = macaulay(Y, fl)
Dmod = Dmac / (1.0 + Y)
Cvx = convexity(Y, fl)

print("the house bond: 1000 face, 6% annual coupon, 5 years, priced at a 5% yield")
print(f"{'year':>4}{'cash':>10}{'present value':>16}{'share of price':>16}{'year x share':>14}")
for t, c in fl:
    pv = c / (1.0 + Y) ** t
    print(f"{t:>4}{c:>10.2f}{pv:>16.6f}{pv / P:>16.6f}{t * pv / P:>14.6f}")
print(f"{'totals':>14}{P:>16.6f}{1.0:>16.6f}{Dmac:>14.6f}")
print()
print(f"{'price P':<40}{P:>14.6f}")
print(f"{'  by whole-number arithmetic':<40}{exact_price(21, 20, fl):>14.6f}")
print(f"{'Macaulay duration, years':<40}{Dmac:>14.6f}")
print(f"{'modified duration, per 1.00 of yield':<40}{Dmod:>14.6f}")
print(f"{'  -(1/P) dP/dy by nudging':<40}{-slope(Y, fl) / P:>14.6f}")
print(f"{'convexity, years squared':<40}{Cvx:>14.6f}")
print(f"{'  (1/P) d2P/dy2 by nudging':<40}{bend(Y, fl) / P:>14.6f}")
print(f"{'DV01, dollars per basis point':<40}{Dmod * P * 1e-4:>14.6f}")

shocks = []
for h, a, b in ((UP, 53, 50), (-UP, 26, 25)):
    exact = exact_price(a, b, fl)
    lin = P * (1.0 - Dmod * h)
    quad = lin + P * 0.5 * Cvx * h * h
    bound = third_size(min(Y, Y + h), fl) * abs(h) ** 3 / 6.0
    shocks.append((h, exact, lin, quad, bound))
print()
print(f"{'a 1-point move from the 5% yield':<38}{'rise to 6%':>15}{'fall to 4%':>15}")
pair("  exact new price, whole numbers", [s[1] for s in shocks])
pair("  duration-only estimate", [s[2] for s in shocks])
pair("  duration + convexity estimate", [s[3] for s in shocks])
pair("  duration-only error, dollars", [s[1] - s[2] for s in shocks])
pair("  duration + convexity error, dollars", [s[1] - s[3] for s in shocks])
pair("  certified error bound, dollars", [s[4] for s in shocks])
pair("  actual move, percent of price", [100.0 * (s[1] - P) / P for s in shocks])
pair("  duration-only said, percent", [-100.0 * Dmod * s[0] for s in shocks])
pair("  convexity correction, percent", [50.0 * Cvx * s[0] * s[0] for s in shocks])

print()
print("what breaks, on the 1-point rise (right answer 1000.000000)")
print(f"{'  Macaulay used in place of modified':<40}{P * (1.0 - Dmac * UP):>14.6f}")
print(f"{'  convexity term without the half':<40}{shocks[0][2] + P * Cvx * UP * UP:>14.6f}")
print(f"{'  convexity term subtracted':<40}{shocks[0][2] - P * 0.5 * Cvx * UP * UP:>14.6f}")
print(f"{'  100 basis points typed as 1.0':<40}{P * (1.0 - Dmod * 1.0):>14.6f}")

print()
zc = flows(coupon=0)
ten = flows(years=10)
big = 3.0 * UP
print(f"{'try: 5-year zero, Macaulay duration':<40}{macaulay(Y, zc):>14.6f}")
print(f"{'try: 5-year zero, convexity':<40}{convexity(Y, zc):>14.6f}")
print(f"{'try: 10-year bond, modified duration':<40}{macaulay(Y, ten) / (1.0 + Y):>14.6f}")
print(f"{'try: 3-point rise, with convexity error':<40}"
      f"{price(Y + big, fl) - P * (1.0 - Dmod * big + 0.5 * Cvx * big * big):>14.6f}")

print()
chart_y = [0.03 + 0.005 * i for i in range(9)]
print("chart, yield percent      " + " ".join(f"{100.0 * y:7.2f}" for y in chart_y))
print("chart, actual price       " + " ".join(f"{price(y, fl):7.2f}" for y in chart_y))
print("chart, duration-only line " + " ".join(f"{P * (1.0 - Dmod * (y - Y)):7.2f}" for y in chart_y))
moves = [0.001, 0.005, 0.01, 0.02, 0.03]
print("bars, move in basis points" + " ".join(f"{10000.0 * h:7.0f}" for h in moves))
print("bars, duration-only error " + " ".join(
    f"{price(Y + h, fl) - P * (1.0 - Dmod * h):7.2f}" for h in moves))
ages = [5, 4, 3, 2, 1]
print("chart, years remaining    " + " ".join(f"{n:7d}" for n in ages))
print("chart, modified duration  " + " ".join(
    f"{macaulay(Y, flows(years=n)) / (1.0 + Y):7.2f}" for n in ages))
drift = [0.03, 0.04, 0.05, 0.06, 0.07]
print("drift, yield percent      " + " ".join(f"{100.0 * y:7.2f}" for y in drift))
print("drift, modified duration  " + " ".join(f"{macaulay(y, fl) / (1.0 + y):7.2f}" for y in drift))

assert abs(-slope(Y, fl) / P - Dmod) < 1e-6, "nudged slope must land on Macaulay/(1+y)"
assert abs(bend(Y, fl) / P - Cvx) < 1e-4, "nudged bend must land on the weighted t(t+1) sum"
assert abs(exact_price(21, 20, fl) - P) < 1e-9, "whole numbers must land on the float price"
assert abs(macaulay(Y, zc) - YEARS) < 1e-12, "a zero's average payment time is its maturity"
for h, exact, lin, quad, bound in shocks:
    assert abs(exact - quad) <= bound, "the second-order error must respect its bound"
    assert abs(exact - quad) < abs(exact - lin), "convexity must shrink the error"
    assert exact > lin, "the curve must sit above its tangent on both sides"
print("ALL CHECKS PASS")
```

**Ran 2026-09-14 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
the house bond: 1000 face, 6% annual coupon, 5 years, priced at a 5% yield
year      cash   present value  share of price  year x share
   1     60.00       57.142857        0.054772      0.054772
   2     60.00       54.421769        0.052163      0.104327
   3     60.00       51.830256        0.049679      0.149038
   4     60.00       49.362148        0.047314      0.189255
   5   1060.00      830.537736        0.796072      3.980360
        totals     1043.294767        1.000000      4.477751

price P                                    1043.294767
  by whole-number arithmetic               1043.294767
Macaulay duration, years                      4.477751
modified duration, per 1.00 of yield          4.264525
  -(1/P) dP/dy by nudging                     4.264525
convexity, years squared                     23.444091
  (1/P) d2P/dy2 by nudging                   23.444092
DV01, dollars per basis point                 0.444916

a 1-point move from the 5% yield           rise to 6%     fall to 4%
  exact new price, whole numbers          1000.000000    1089.036447
  duration-only estimate                   998.803201    1087.786333
  duration + convexity estimate           1000.026155    1089.009288
  duration-only error, dollars               1.196799       1.250114
  duration + convexity error, dollars       -0.026155       0.027159
  certified error bound, dollars             0.026649       0.028743
  actual move, percent of price             -4.149812       4.384349
  duration-only said, percent               -4.264525       4.264525
  convexity correction, percent              0.117220       0.117220

what breaks, on the 1-point rise (right answer 1000.000000)
  Macaulay used in place of modified        996.578622
  convexity term without the half          1001.249110
  convexity term subtracted                 997.580246
  100 basis points typed as 1.0           -3405.861841

try: 5-year zero, Macaulay duration           5.000000
try: 5-year zero, convexity                  27.210884
try: 10-year bond, modified duration          7.516332
try: 3-point rise, with convexity error      -0.680863

chart, yield percent         3.00    3.50    4.00    4.50    5.00    5.50    6.00    6.50    7.00
chart, actual price       1137.39 1112.88 1089.04 1065.85 1043.29 1021.35 1000.00  979.22  959.00
chart, duration-only line 1132.28 1110.03 1087.79 1065.54 1043.29 1021.05  998.80  976.56  954.31
bars, move in basis points     10      50     100     200     300
bars, duration-only error    0.01    0.30    1.20    4.69   10.33
chart, years remaining          5       4       3       2       1
chart, modified duration     4.26    3.50    2.70    1.85    0.95
drift, yield percent         3.00    4.00    5.00    6.00    7.00
drift, modified duration     4.37    4.32    4.26    4.21    4.16
ALL CHECKS PASS
```

### Rust

Same inputs, same labels, same four roads, built with `rustc --edition 2021 -O`. The whole-number road uses 128-bit integers so nothing overflows.

```rust
// Duration and convexity -- the same check as the Python, in Rust.  No crates.
// The bond: 1,000 face, 6% annual coupon, five years, priced at a 5% yield.
// Four roads reach the same numbers: present-value weighted sums; central
// differences on the price function itself; whole-number arithmetic with a
// single division at the end; and a certified bound on what the second-order
// estimate leaves out.
const FACE: f64 = 1000.0;
const COUPON: f64 = 60.0;
const YEARS: u32 = 5;
const Y: f64 = 0.05;
const UP: f64 = 0.01;

fn flows(coupon: f64, years: u32) -> Vec<(u32, f64)> {
    (1..=years).map(|t| (t, coupon + if t == years { FACE } else { 0.0 })).collect()
}

fn price(y: f64, fl: &[(u32, f64)]) -> f64 {
    let mut s = 0.0;
    for &(t, c) in fl { s += c / (1.0 + y).powf(t as f64) }
    s
}

fn macaulay(y: f64, fl: &[(u32, f64)]) -> f64 {   // road 1: the present-value weighted average time
    let mut s = 0.0;
    for &(t, c) in fl { s += (t as f64) * c / (1.0 + y).powf(t as f64) }
    s / price(y, fl)
}

fn convexity(y: f64, fl: &[(u32, f64)]) -> f64 {  // road 1: weighted t(t+1), two extra discounts
    let mut s = 0.0;
    for &(t, c) in fl { s += (t as f64) * ((t + 1) as f64) * c / (1.0 + y).powf((t + 2) as f64) }
    s / price(y, fl)
}

fn third_size(y: f64, fl: &[(u32, f64)]) -> f64 { // the largest the third derivative gets on a move
    let mut s = 0.0;
    for &(t, c) in fl {
        s += (t as f64) * ((t + 1) as f64) * ((t + 2) as f64) * c / (1.0 + y).powf((t + 3) as f64)
    }
    s
}

fn slope(y: f64, fl: &[(u32, f64)]) -> f64 {      // road 2: dP/dy by nudging the yield both ways
    let h = 1e-5;
    (price(y + h, fl) - price(y - h, fl)) / (2.0 * h)
}

fn bend(y: f64, fl: &[(u32, f64)]) -> f64 {       // road 2: d2P/dy2 by nudging the yield both ways
    let h = 1e-4;
    (price(y + h, fl) - 2.0 * price(y, fl) + price(y - h, fl)) / (h * h)
}

fn exact_price(a: i128, b: i128, fl: &[(u32, f64)]) -> f64 {  // road 3: (1+y) = a/b, whole numbers
    let mut num: i128 = 0;
    for &(t, c) in fl { num += (c as i128) * b.pow(t) * a.pow(YEARS - t) }
    num as f64 / a.pow(YEARS) as f64
}

fn pair(label: &str, vals: [f64; 2]) {
    let mut line = format!("{:<38}", label);
    for v in vals { line.push_str(&format!("{:>15.6}", v)) }
    println!("{}", line);
}

fn row(prefix: &str, cells: Vec<String>) { println!("{}{}", prefix, cells.join(" ")) }

fn main() {
    let fl = flows(COUPON, YEARS);
    let p = price(Y, &fl);
    let dmac = macaulay(Y, &fl);
    let dmod = dmac / (1.0 + Y);
    let cvx = convexity(Y, &fl);

    println!("the house bond: 1000 face, 6% annual coupon, 5 years, priced at a 5% yield");
    println!("{:>4}{:>10}{:>16}{:>16}{:>14}",
             "year", "cash", "present value", "share of price", "year x share");
    for &(t, c) in &fl {
        let pv = c / (1.0 + Y).powf(t as f64);
        println!("{:>4}{:>10.2}{:>16.6}{:>16.6}{:>14.6}", t, c, pv, pv / p, (t as f64) * pv / p);
    }
    println!("{:>14}{:>16.6}{:>16.6}{:>14.6}", "totals", p, 1.0, dmac);
    println!();
    println!("{:<40}{:>14.6}", "price P", p);
    println!("{:<40}{:>14.6}", "  by whole-number arithmetic", exact_price(21, 20, &fl));
    println!("{:<40}{:>14.6}", "Macaulay duration, years", dmac);
    println!("{:<40}{:>14.6}", "modified duration, per 1.00 of yield", dmod);
    println!("{:<40}{:>14.6}", "  -(1/P) dP/dy by nudging", -slope(Y, &fl) / p);
    println!("{:<40}{:>14.6}", "convexity, years squared", cvx);
    println!("{:<40}{:>14.6}", "  (1/P) d2P/dy2 by nudging", bend(Y, &fl) / p);
    println!("{:<40}{:>14.6}", "DV01, dollars per basis point", dmod * p * 1e-4);

    let mut shocks: Vec<(f64, f64, f64, f64, f64)> = Vec::new();
    for (h, a, b) in [(UP, 53i128, 50i128), (-UP, 26i128, 25i128)] {
        let exact = exact_price(a, b, &fl);
        let lin = p * (1.0 - dmod * h);
        let quad = lin + p * 0.5 * cvx * h * h;
        let bound = third_size(Y.min(Y + h), &fl) * h.abs().powf(3.0) / 6.0;
        shocks.push((h, exact, lin, quad, bound));
    }
    let (s0, s1) = (shocks[0], shocks[1]);
    println!();
    println!("{:<38}{:>15}{:>15}", "a 1-point move from the 5% yield", "rise to 6%", "fall to 4%");
    pair("  exact new price, whole numbers", [s0.1, s1.1]);
    pair("  duration-only estimate", [s0.2, s1.2]);
    pair("  duration + convexity estimate", [s0.3, s1.3]);
    pair("  duration-only error, dollars", [s0.1 - s0.2, s1.1 - s1.2]);
    pair("  duration + convexity error, dollars", [s0.1 - s0.3, s1.1 - s1.3]);
    pair("  certified error bound, dollars", [s0.4, s1.4]);
    pair("  actual move, percent of price", [100.0 * (s0.1 - p) / p, 100.0 * (s1.1 - p) / p]);
    pair("  duration-only said, percent", [-100.0 * dmod * s0.0, -100.0 * dmod * s1.0]);
    pair("  convexity correction, percent",
         [50.0 * cvx * s0.0 * s0.0, 50.0 * cvx * s1.0 * s1.0]);

    println!();
    println!("what breaks, on the 1-point rise (right answer 1000.000000)");
    println!("{:<40}{:>14.6}", "  Macaulay used in place of modified", p * (1.0 - dmac * UP));
    println!("{:<40}{:>14.6}", "  convexity term without the half", s0.2 + p * cvx * UP * UP);
    println!("{:<40}{:>14.6}", "  convexity term subtracted", s0.2 - p * 0.5 * cvx * UP * UP);
    println!("{:<40}{:>14.6}", "  100 basis points typed as 1.0", p * (1.0 - dmod * 1.0));

    println!();
    let zc = flows(0.0, YEARS);
    let ten = flows(COUPON, 10);
    let big = 3.0 * UP;
    println!("{:<40}{:>14.6}", "try: 5-year zero, Macaulay duration", macaulay(Y, &zc));
    println!("{:<40}{:>14.6}", "try: 5-year zero, convexity", convexity(Y, &zc));
    println!("{:<40}{:>14.6}", "try: 10-year bond, modified duration", macaulay(Y, &ten) / (1.0 + Y));
    println!("{:<40}{:>14.6}", "try: 3-point rise, with convexity error",
             price(Y + big, &fl) - p * (1.0 - dmod * big + 0.5 * cvx * big * big));

    println!();
    let chart_y: Vec<f64> = (0..9).map(|i| 0.03 + 0.005 * i as f64).collect();
    row("chart, yield percent      ", chart_y.iter().map(|y| format!("{:7.2}", 100.0 * y)).collect());
    row("chart, actual price       ", chart_y.iter().map(|&y| format!("{:7.2}", price(y, &fl))).collect());
    row("chart, duration-only line ",
        chart_y.iter().map(|&y| format!("{:7.2}", p * (1.0 - dmod * (y - Y)))).collect());
    let moves = [0.001, 0.005, 0.01, 0.02, 0.03];
    row("bars, move in basis points", moves.iter().map(|h| format!("{:7.0}", 10000.0 * h)).collect());
    row("bars, duration-only error ",
        moves.iter().map(|&h| format!("{:7.2}", price(Y + h, &fl) - p * (1.0 - dmod * h))).collect());
    let ages = [5u32, 4, 3, 2, 1];
    row("chart, years remaining    ", ages.iter().map(|n| format!("{:7}", n)).collect());
    row("chart, modified duration  ",
        ages.iter().map(|&n| format!("{:7.2}", macaulay(Y, &flows(COUPON, n)) / (1.0 + Y))).collect());
    let drift = [0.03, 0.04, 0.05, 0.06, 0.07];
    row("drift, yield percent      ", drift.iter().map(|y| format!("{:7.2}", 100.0 * y)).collect());
    row("drift, modified duration  ",
        drift.iter().map(|&y| format!("{:7.2}", macaulay(y, &fl) / (1.0 + y))).collect());

    assert!((-slope(Y, &fl) / p - dmod).abs() < 1e-6, "nudged slope must land on Macaulay/(1+y)");
    assert!((bend(Y, &fl) / p - cvx).abs() < 1e-4, "nudged bend must land on the weighted t(t+1) sum");
    assert!((exact_price(21, 20, &fl) - p).abs() < 1e-9, "whole numbers must land on the float price");
    assert!((macaulay(Y, &zc) - YEARS as f64).abs() < 1e-12, "a zero's average payment time is its maturity");
    for &(_h, exact, lin, quad, bound) in &shocks {
        assert!((exact - quad).abs() <= bound, "the second-order error must respect its bound");
        assert!((exact - quad).abs() < (exact - lin).abs(), "convexity must shrink the error");
        assert!(exact > lin, "the curve must sit above its tangent on both sides");
    }
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-14 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
the house bond: 1000 face, 6% annual coupon, 5 years, priced at a 5% yield
year      cash   present value  share of price  year x share
   1     60.00       57.142857        0.054772      0.054772
   2     60.00       54.421769        0.052163      0.104327
   3     60.00       51.830256        0.049679      0.149038
   4     60.00       49.362148        0.047314      0.189255
   5   1060.00      830.537736        0.796072      3.980360
        totals     1043.294767        1.000000      4.477751

price P                                    1043.294767
  by whole-number arithmetic               1043.294767
Macaulay duration, years                      4.477751
modified duration, per 1.00 of yield          4.264525
  -(1/P) dP/dy by nudging                     4.264525
convexity, years squared                     23.444091
  (1/P) d2P/dy2 by nudging                   23.444092
DV01, dollars per basis point                 0.444916

a 1-point move from the 5% yield           rise to 6%     fall to 4%
  exact new price, whole numbers          1000.000000    1089.036447
  duration-only estimate                   998.803201    1087.786333
  duration + convexity estimate           1000.026155    1089.009288
  duration-only error, dollars               1.196799       1.250114
  duration + convexity error, dollars       -0.026155       0.027159
  certified error bound, dollars             0.026649       0.028743
  actual move, percent of price             -4.149812       4.384349
  duration-only said, percent               -4.264525       4.264525
  convexity correction, percent              0.117220       0.117220

what breaks, on the 1-point rise (right answer 1000.000000)
  Macaulay used in place of modified        996.578622
  convexity term without the half          1001.249110
  convexity term subtracted                 997.580246
  100 basis points typed as 1.0           -3405.861841

try: 5-year zero, Macaulay duration           5.000000
try: 5-year zero, convexity                  27.210884
try: 10-year bond, modified duration          7.516332
try: 3-point rise, with convexity error      -0.680863

chart, yield percent         3.00    3.50    4.00    4.50    5.00    5.50    6.00    6.50    7.00
chart, actual price       1137.39 1112.88 1089.04 1065.85 1043.29 1021.35 1000.00  979.22  959.00
chart, duration-only line 1132.28 1110.03 1087.79 1065.54 1043.29 1021.05  998.80  976.56  954.31
bars, move in basis points     10      50     100     200     300
bars, duration-only error    0.01    0.30    1.20    4.69   10.33
chart, years remaining          5       4       3       2       1
chart, modified duration     4.26    3.50    2.70    1.85    0.95
drift, yield percent         3.00    4.00    5.00    6.00    7.00
drift, modified duration     4.37    4.32    4.26    4.21    4.16
ALL CHECKS PASS
```

The two outputs match line for line, from two programs that share no code.

### Lean

Lean proves the price-move bound, the derivative link and the upward bend for every fixed-payment bond, and checks the house bond's numbers.

- Suppose the payments are fixed and never negative, and both yields stay above minus one hundred percent. Then $|R| \le M\,|\Delta y|^3/6$, with $M$ read at the move's floor.
- On those same terms, the two-term estimate is never below the true price on a rise, and never above it on a fall.
- Take any fixed payments and a yield above minus one hundred percent. Then minus the slope over the price is $D_{\text{mod}}$, and the bend over the price is $C$.
- Suppose the bond has at least one payment, and every payment is positive. Then the second derivative of the price and $C$ are both positive.
- On those terms, the price curve sits strictly above the tangent duration draws, at every other yield above minus one hundred percent.
- Repriced at 6 percent, the house bond is worth exactly 1,000.
- A five-year zero-coupon bond has a Macaulay duration of exactly 5 years.
- The house bond's Macaulay duration rounds to 4.477751, its modified duration to 4.264525, and its convexity to 23.444091.
- On the one-point rise, duration plus convexity predicts 1,000.026155, and the bound on the leftover rounds to 0.026649.

The one-point fall, DV01, the nudged slopes and the tables of aging and drift are left to the Python and Rust checks.

```lean
-- Duration and convexity: for a bond with fixed non-negative payments, modified duration and convexity are minus the price's first derivative and its second derivative, each divided by the price, and a yield move changes the price by the duration and convexity terms plus a leftover no bigger than M times the cube of the move over six, with the leftover's sign set by the move's direction.
import Mathlib.Analysis.Calculus.Taylor
import Mathlib.Analysis.Calculus.Deriv.Inv
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FieldSimp

open Finset

/-! A bond pays `A t` dollars at the end of year `t`, for `t = 1, …, N`; the face is part of the
last payment. At a yield `y` every payment is discounted at the one rate `y`. -/

/-- The price: `P(y) = ∑_{t=1}^{N} A_t / (1 + y)^t`. -/
noncomputable def price (A : ℕ → ℝ) (N : ℕ) (y : ℝ) : ℝ :=
  ∑ t ∈ Icc 1 N, A t / (1 + y) ^ t

/-- A payment's weight: its share of today's price, `w_t = (A_t / (1 + y)^t) / P`. -/
noncomputable def weight (A : ℕ → ℝ) (N : ℕ) (y : ℝ) (t : ℕ) : ℝ :=
  A t / (1 + y) ^ t / price A N y

/-- Macaulay duration: the payment years averaged under the weights, `∑ t w_t`. -/
noncomputable def macaulay (A : ℕ → ℝ) (N : ℕ) (y : ℝ) : ℝ :=
  ∑ t ∈ Icc 1 N, (t : ℝ) * weight A N y t

/-- Modified duration: Macaulay duration divided by `1 + y`. -/
noncomputable def modDuration (A : ℕ → ℝ) (N : ℕ) (y : ℝ) : ℝ :=
  macaulay A N y / (1 + y)

/-- Convexity: `C = (1/P) ∑_{t=1}^{N} t (t + 1) A_t / (1 + y)^(t + 2)`. -/
noncomputable def convexity (A : ℕ → ℝ) (N : ℕ) (y : ℝ) : ℝ :=
  1 / price A N y * ∑ t ∈ Icc 1 N, (t : ℝ) * (t + 1) * A t / (1 + y) ^ (t + 2)

/-- The card's `M`, read at the move's floor:
`M = ∑_{t=1}^{N} t (t + 1) (t + 2) A_t / (1 + y_floor)^(t + 3)`. -/
noncomputable def thirdCap (A : ℕ → ℝ) (N : ℕ) (yFloor : ℝ) : ℝ :=
  ∑ t ∈ Icc 1 N, (t : ℝ) * (t + 1) * (t + 2) * A t / (1 + yFloor) ^ (t + 3)

lemma hasDerivAt_term (c : ℝ) (n : ℕ) {x : ℝ} (hx : -1 < x) :
    HasDerivAt (fun x : ℝ => c / (1 + x) ^ n) (-(n * c) / (1 + x) ^ (n + 1)) x := by
  have h0 : (1 + x) ≠ 0 := by linarith
  have h1 : HasDerivAt (fun y : ℝ => (1 + y) ^ n) (n * (1 + x) ^ (n - 1) * 1) x :=
    ((hasDerivAt_id' x).const_add 1).fun_pow n
  have h2 := (h1.fun_inv (pow_ne_zero n h0)).const_mul c
  convert h2 using 1
  · funext y; simp [div_eq_mul_inv]
  · rcases n with _ | k
    · simp
    · simp only [Nat.add_sub_cancel]
      field_simp
      ring

lemma anti_of {g g' : ℝ → ℝ} {a b : ℝ} (hd : ∀ x ∈ Set.Icc a b, HasDerivAt g (g' x) x)
    (hn : ∀ x ∈ Set.Icc a b, g' x ≤ 0) : AntitoneOn g (Set.Icc a b) :=
  antitoneOn_of_hasDerivWithinAt_nonpos (convex_Icc a b)
    (fun x hx => (hd x hx).continuousAt.continuousWithinAt)
    (fun x hx => (hd x (interior_subset hx)).hasDerivWithinAt)
    (fun x hx => hn x (interior_subset hx))

lemma mono_of {g g' : ℝ → ℝ} {a b : ℝ} (hd : ∀ x ∈ Set.Icc a b, HasDerivAt g (g' x) x)
    (hn : ∀ x ∈ Set.Icc a b, 0 ≤ g' x) : MonotoneOn g (Set.Icc a b) :=
  monotoneOn_of_hasDerivWithinAt_nonneg (convex_Icc a b)
    (fun x hx => (hd x hx).continuousAt.continuousWithinAt)
    (fun x hx => (hd x (interior_subset hx)).hasDerivWithinAt)
    (fun x hx => hn x (interior_subset hx))

lemma smono_of {g g' : ℝ → ℝ} {a b : ℝ} (hd : ∀ x ∈ Set.Icc a b, HasDerivAt g (g' x) x)
    (hn : ∀ x ∈ Set.Ioo a b, 0 < g' x) : StrictMonoOn g (Set.Icc a b) :=
  strictMonoOn_of_hasDerivWithinAt_pos (convex_Icc a b)
    (fun x hx => (hd x hx).continuousAt.continuousWithinAt)
    (fun x hx => (hd x (interior_subset hx)).hasDerivWithinAt)
    (fun x hx => hn x (by simpa using hx))

lemma santi_of {g g' : ℝ → ℝ} {a b : ℝ} (hd : ∀ x ∈ Set.Icc a b, HasDerivAt g (g' x) x)
    (hn : ∀ x ∈ Set.Ioo a b, g' x < 0) : StrictAntiOn g (Set.Icc a b) :=
  strictAntiOn_of_hasDerivWithinAt_neg (convex_Icc a b)
    (fun x hx => (hd x hx).continuousAt.continuousWithinAt)
    (fun x hx => (hd x (interior_subset hx)).hasDerivWithinAt)
    (fun x hx => hn x (by simpa using hx))

lemma chain_up {g g1 g2 g3 : ℝ → ℝ} {a b : ℝ} (hab : a ≤ b)
    (d0 : ∀ x ∈ Set.Icc a b, HasDerivAt g (g1 x) x)
    (d1 : ∀ x ∈ Set.Icc a b, HasDerivAt g1 (g2 x) x)
    (d2 : ∀ x ∈ Set.Icc a b, HasDerivAt g2 (g3 x) x)
    (h3 : ∀ x ∈ Set.Icc a b, g3 x ≤ 0) (e0 : g a = 0) (e1 : g1 a = 0) (e2 : g2 a = 0) :
    g b ≤ 0 := by
  have ha : a ∈ Set.Icc a b := ⟨le_rfl, hab⟩
  have A2 := anti_of d2 h3
  have n2 : ∀ x ∈ Set.Icc a b, g2 x ≤ 0 := fun x hx => (A2 ha hx hx.1).trans e2.le
  have A1 := anti_of d1 n2
  have n1 : ∀ x ∈ Set.Icc a b, g1 x ≤ 0 := fun x hx => (A1 ha hx hx.1).trans e1.le
  have A0 := anti_of d0 n1
  exact (A0 ha ⟨hab, le_rfl⟩ hab).trans e0.le

lemma chain_down {g g1 g2 g3 : ℝ → ℝ} {a b : ℝ} (hab : a ≤ b)
    (d0 : ∀ x ∈ Set.Icc a b, HasDerivAt g (g1 x) x)
    (d1 : ∀ x ∈ Set.Icc a b, HasDerivAt g1 (g2 x) x)
    (d2 : ∀ x ∈ Set.Icc a b, HasDerivAt g2 (g3 x) x)
    (h3 : ∀ x ∈ Set.Icc a b, g3 x ≤ 0) (e0 : g b = 0) (e1 : g1 b = 0) (e2 : g2 b = 0) :
    0 ≤ g a := by
  have ha : a ∈ Set.Icc a b := ⟨le_rfl, hab⟩
  have hb : b ∈ Set.Icc a b := ⟨hab, le_rfl⟩
  have A2 := anti_of d2 h3
  have n2 : ∀ x ∈ Set.Icc a b, 0 ≤ g2 x := fun x hx => e2.symm.le.trans (A2 hx hb hx.2)
  have M1 := mono_of d1 n2
  have n1 : ∀ x ∈ Set.Icc a b, g1 x ≤ 0 := fun x hx => (M1 hx hb hx.2).trans e1.le
  have A0 := anti_of d0 n1
  exact e0.symm.le.trans (A0 ha hb hab)

lemma hd_poly {φ : ℝ → ℝ} {φ' x : ℝ} (h : HasDerivAt φ φ' x) (a c0 c1 c2 c3 : ℝ) :
    HasDerivAt (fun x => φ x - c0 - c1 * (x - a) - c2 * (x - a) ^ 2 / 2 - c3 * (x - a) ^ 3 / 6)
      (φ' - c1 - c2 * (x - a) - c3 * (x - a) ^ 2 / 2) x := by
  have hl : HasDerivAt (fun x : ℝ => x - a) 1 x := (hasDerivAt_id' x).sub_const a
  have := (((h.sub_const c0).sub (hl.const_mul c1)).sub
    (((hl.fun_pow 2).const_mul c2).div_const 2)).sub (((hl.fun_pow 3).const_mul c3).div_const 6)
  convert this using 1
  push_cast
  ring

lemma taylor3_up {f f1 f2 f3 : ℝ → ℝ} {a b K : ℝ} (hab : a ≤ b)
    (h0 : ∀ x ∈ Set.Icc a b, HasDerivAt f (f1 x) x)
    (h1 : ∀ x ∈ Set.Icc a b, HasDerivAt f1 (f2 x) x)
    (h2 : ∀ x ∈ Set.Icc a b, HasDerivAt f2 (f3 x) x)
    (hK : ∀ x ∈ Set.Icc a b, f3 x ≤ K) :
    f b - (f a + f1 a * (b - a) + f2 a * (b - a) ^ 2 / 2) ≤ K * (b - a) ^ 3 / 6 := by
  have := chain_up (g := fun x => f x - f a - f1 a * (x - a) - f2 a * (x - a) ^ 2 / 2 - K * (x - a) ^ 3 / 6)
    (g1 := fun x => f1 x - f1 a - f2 a * (x - a) - K * (x - a) ^ 2 / 2 - 0 * (x - a) ^ 3 / 6)
    (g2 := fun x => f2 x - f2 a - K * (x - a) - 0 * (x - a) ^ 2 / 2 - 0 * (x - a) ^ 3 / 6)
    (g3 := fun x => f3 x - K) hab
    (fun x hx => (hd_poly (h0 x hx) a _ _ _ _).congr_deriv (by ring))
    (fun x hx => (hd_poly (h1 x hx) a _ _ _ _).congr_deriv (by ring))
    (fun x hx => (hd_poly (h2 x hx) a _ _ _ _).congr_deriv (by ring))
    (fun x hx => by linarith [hK x hx]) (by simp) (by simp) (by simp)
  linarith

lemma taylor3_down {f f1 f2 f3 : ℝ → ℝ} {a b K : ℝ} (hab : a ≤ b)
    (h0 : ∀ x ∈ Set.Icc a b, HasDerivAt f (f1 x) x)
    (h1 : ∀ x ∈ Set.Icc a b, HasDerivAt f1 (f2 x) x)
    (h2 : ∀ x ∈ Set.Icc a b, HasDerivAt f2 (f3 x) x)
    (hK : ∀ x ∈ Set.Icc a b, f3 x ≤ K) :
    K * (a - b) ^ 3 / 6 ≤ f a - (f b + f1 b * (a - b) + f2 b * (a - b) ^ 2 / 2) := by
  have := chain_down (g := fun x => f x - f b - f1 b * (x - b) - f2 b * (x - b) ^ 2 / 2 - K * (x - b) ^ 3 / 6)
    (g1 := fun x => f1 x - f1 b - f2 b * (x - b) - K * (x - b) ^ 2 / 2 - 0 * (x - b) ^ 3 / 6)
    (g2 := fun x => f2 x - f2 b - K * (x - b) - 0 * (x - b) ^ 2 / 2 - 0 * (x - b) ^ 3 / 6)
    (g3 := fun x => f3 x - K) hab
    (fun x hx => (hd_poly (h0 x hx) b _ _ _ _).congr_deriv (by ring))
    (fun x hx => (hd_poly (h1 x hx) b _ _ _ _).congr_deriv (by ring))
    (fun x hx => (hd_poly (h2 x hx) b _ _ _ _).congr_deriv (by ring))
    (fun x hx => by linarith [hK x hx]) (by simp) (by simp) (by simp)
  linarith

lemma hasDerivAt_price (A : ℕ → ℝ) (N : ℕ) {x : ℝ} (hx : -1 < x) :
    HasDerivAt (price A N) (∑ t ∈ Icc 1 N, -((t : ℝ) * A t) / (1 + x) ^ (t + 1)) x := by
  have := HasDerivAt.fun_sum (u := Icc 1 N) (A := fun t x => A t / (1 + x) ^ t)
    (fun t _ => hasDerivAt_term (A t) t hx)
  exact this

lemma hasDerivAt_d1 (A : ℕ → ℝ) (N : ℕ) {x : ℝ} (hx : -1 < x) :
    HasDerivAt (fun x : ℝ => ∑ t ∈ Icc 1 N, -((t : ℝ) * A t) / (1 + x) ^ (t + 1))
      (∑ t ∈ Icc 1 N, (t : ℝ) * (t + 1) * A t / (1 + x) ^ (t + 2)) x := by
  have := HasDerivAt.fun_sum (u := Icc 1 N) (A := fun t x => -((t : ℝ) * A t) / (1 + x) ^ (t + 1))
    (fun t _ => hasDerivAt_term _ (t + 1) hx)
  refine this.congr_deriv (Finset.sum_congr rfl fun t _ => ?_)
  push_cast
  ring

lemma hasDerivAt_d2 (A : ℕ → ℝ) (N : ℕ) {x : ℝ} (hx : -1 < x) :
    HasDerivAt (fun x : ℝ => ∑ t ∈ Icc 1 N, (t : ℝ) * (t + 1) * A t / (1 + x) ^ (t + 2))
      (-∑ t ∈ Icc 1 N, (t : ℝ) * (t + 1) * (t + 2) * A t / (1 + x) ^ (t + 3)) x := by
  have := HasDerivAt.fun_sum (u := Icc 1 N)
    (A := fun t x => (t : ℝ) * (t + 1) * A t / (1 + x) ^ (t + 2))
    (fun t _ => hasDerivAt_term _ (t + 2) hx)
  refine this.congr_deriv ?_
  rw [← Finset.sum_neg_distrib]
  refine Finset.sum_congr rfl fun t _ => ?_
  push_cast
  ring

lemma deriv_price (A : ℕ → ℝ) (N : ℕ) {y : ℝ} (hy : -1 < y) :
    deriv (price A N) y = ∑ t ∈ Icc 1 N, -((t : ℝ) * A t) / (1 + y) ^ (t + 1) :=
  (hasDerivAt_price A N hy).deriv

lemma deriv2_price (A : ℕ → ℝ) (N : ℕ) {y : ℝ} (hy : -1 < y) :
    deriv (deriv (price A N)) y = ∑ t ∈ Icc 1 N, (t : ℝ) * (t + 1) * A t / (1 + y) ^ (t + 2) := by
  have hev : deriv (price A N) =ᶠ[nhds y]
      (fun x : ℝ => ∑ t ∈ Icc 1 N, -((t : ℝ) * A t) / (1 + x) ^ (t + 1)) := by
    filter_upwards [Ioi_mem_nhds hy] with x hx using deriv_price A N hx
  rw [hev.deriv_eq, (hasDerivAt_d1 A N hy).deriv]

lemma dur_id (A : ℕ → ℝ) (N : ℕ) (y : ℝ) :
    -(1 / price A N y) * (∑ t ∈ Icc 1 N, -((t : ℝ) * A t) / (1 + y) ^ (t + 1)) =
      modDuration A N y := by
  unfold modDuration macaulay weight
  rw [Finset.mul_sum, Finset.sum_div]
  refine Finset.sum_congr rfl fun t _ => ?_
  generalize 1 + y = u
  rw [pow_succ]
  ring

lemma zero_of_price_zero (A : ℕ → ℝ) (N : ℕ) (y : ℝ) (hA : ∀ t ∈ Icc 1 N, 0 ≤ A t) (hy : -1 < y)
    (hP : price A N y = 0) : ∀ t ∈ Icc 1 N, A t = 0 := by
  have hz := (Finset.sum_eq_zero_iff_of_nonneg
    (fun t ht => div_nonneg (hA t ht) (pow_pos (by linarith : (0 : ℝ) < 1 + y) t).le)).mp hP
  intro t ht
  have h1 := hz t ht
  have hpos : (0 : ℝ) < (1 + y) ^ t := pow_pos (by linarith) t
  rcases div_eq_zero_iff.mp h1 with h | h
  · exact h
  · exact absurd h hpos.ne'

lemma P_mul_dur (A : ℕ → ℝ) (N : ℕ) (y : ℝ) (hA : ∀ t ∈ Icc 1 N, 0 ≤ A t) (hy : -1 < y) :
    price A N y * modDuration A N y =
      -∑ t ∈ Icc 1 N, -((t : ℝ) * A t) / (1 + y) ^ (t + 1) := by
  by_cases hP : price A N y = 0
  · have hz := zero_of_price_zero A N y hA hy hP
    rw [hP, zero_mul, eq_comm, neg_eq_zero]
    exact Finset.sum_eq_zero fun t ht => by simp [hz t ht]
  · rw [← dur_id]
    field_simp

lemma P_mul_conv (A : ℕ → ℝ) (N : ℕ) (y : ℝ) (hA : ∀ t ∈ Icc 1 N, 0 ≤ A t) (hy : -1 < y) :
    price A N y * convexity A N y =
      ∑ t ∈ Icc 1 N, (t : ℝ) * (t + 1) * A t / (1 + y) ^ (t + 2) := by
  by_cases hP : price A N y = 0
  · have hz := zero_of_price_zero A N y hA hy hP
    rw [hP, zero_mul, eq_comm]
    exact Finset.sum_eq_zero fun t ht => by simp [hz t ht]
  · unfold convexity
    field_simp

lemma third_bounds (A : ℕ → ℝ) (N : ℕ) (m : ℝ) (hA : ∀ t ∈ Icc 1 N, 0 ≤ A t) (hm : -1 < m)
    (x : ℝ) (hx : m ≤ x) :
    -thirdCap A N m ≤ -∑ t ∈ Icc 1 N, (t : ℝ) * (t + 1) * (t + 2) * A t / (1 + x) ^ (t + 3) ∧
      -∑ t ∈ Icc 1 N, (t : ℝ) * (t + 1) * (t + 2) * A t / (1 + x) ^ (t + 3) ≤ 0 := by
  have hnum : ∀ t ∈ Icc 1 N, 0 ≤ (t : ℝ) * (t + 1) * (t + 2) * A t := fun t ht =>
    mul_nonneg (by positivity) (hA t ht)
  constructor
  · rw [neg_le_neg_iff]
    unfold thirdCap
    refine Finset.sum_le_sum fun t ht => ?_
    exact div_le_div_of_nonneg_left (hnum t ht) (pow_pos (by linarith) _)
      (pow_le_pow_left₀ (by linarith) (by linarith) _)
  · rw [neg_nonpos]
    exact Finset.sum_nonneg fun t ht => div_nonneg (hnum t ht) (pow_pos (by linarith) _).le

/-- **A yield move turns into a price move by arithmetic, with a certified leftover.** For fixed
payments that are never negative, and a starting yield `y` and new yield `y + Δy` both above
minus one hundred percent,
`P(y + Δy) = P(y) [1 - D_mod Δy + ½ C (Δy)²] + R` with `|R| ≤ M |Δy|³ / 6`, where `M` is read
at the move's floor, the lower of the two yields. The leftover also has a sign: the two-term
estimate is never below the true price on a rise and never above it on a fall. -/
theorem price_move_by_duration_and_convexity (A : ℕ → ℝ) (N : ℕ) (y Δy : ℝ)
    (hA : ∀ t ∈ Icc 1 N, 0 ≤ A t) (hy : -1 < y) (hy' : -1 < y + Δy) :
    |price A N (y + Δy) -
        price A N y * (1 - modDuration A N y * Δy + 1 / 2 * convexity A N y * Δy ^ 2)|
      ≤ thirdCap A N (min y (y + Δy)) * |Δy| ^ 3 / 6 ∧
    (0 < Δy → price A N (y + Δy) ≤
        price A N y * (1 - modDuration A N y * Δy + 1 / 2 * convexity A N y * Δy ^ 2)) ∧
    (Δy < 0 → price A N y * (1 - modDuration A N y * Δy + 1 / 2 * convexity A N y * Δy ^ 2)
        ≤ price A N (y + Δy)) := by
  have e : price A N y * (1 - modDuration A N y * Δy + 1 / 2 * convexity A N y * Δy ^ 2) =
      price A N y + (∑ t ∈ Icc 1 N, -((t : ℝ) * A t) / (1 + y) ^ (t + 1)) * Δy +
        (∑ t ∈ Icc 1 N, (t : ℝ) * (t + 1) * A t / (1 + y) ^ (t + 2)) * Δy ^ 2 / 2 := by
    linear_combination (-Δy) * P_mul_dur A N y hA hy + (Δy ^ 2 / 2) * P_mul_conv A N y hA hy
  rw [e]
  have hm : -1 < min y (y + Δy) := lt_min hy hy'
  have hM0 : 0 ≤ thirdCap A N (min y (y + Δy)) := by
    have := third_bounds A N _ hA hm _ le_rfl
    linarith [this.1, this.2]
  rcases lt_trichotomy Δy 0 with h | rfl | h
  · have hmin : min y (y + Δy) = y + Δy := min_eq_right (by linarith)
    rw [hmin] at hM0 ⊢
    have hab : y + Δy ≤ y := by linarith
    have hI : ∀ x ∈ Set.Icc (y + Δy) y, -1 < x := fun x hx => by linarith [hx.1]
    have L := taylor3_down (K := 0) hab
      (fun x hx => hasDerivAt_price A N (hI x hx))
      (fun x hx => hasDerivAt_d1 A N (hI x hx))
      (fun x hx => hasDerivAt_d2 A N (hI x hx))
      (fun x hx => (third_bounds A N _ hA hy' x hx.1).2)
    have U := taylor3_down (f := fun x => -price A N x) (K := thirdCap A N (y + Δy)) hab
      (fun x hx => (hasDerivAt_price A N (hI x hx)).neg)
      (fun x hx => (hasDerivAt_d1 A N (hI x hx)).neg)
      (fun x hx => (hasDerivAt_d2 A N (hI x hx)).neg)
      (fun x hx => by linarith [(third_bounds A N _ hA hy' x hx.1).1])
    have hs : y + Δy - y = Δy := by ring
    rw [hs] at L U
    rw [abs_of_neg h]
    have hc : (-Δy) ^ 3 = -Δy ^ 3 := by ring
    have hp : 0 ≤ thirdCap A N (y + Δy) * (-Δy) ^ 3 :=
      mul_nonneg hM0 (pow_nonneg (by linarith) 3)
    refine ⟨abs_le.mpr ⟨?_, ?_⟩, fun h' => absurd h' (by linarith), fun _ => by linarith⟩
    · linarith
    · rw [hc]; linarith
  · simp
  · have hmin : min y (y + Δy) = y := min_eq_left (by linarith)
    rw [hmin] at hM0 ⊢
    have hab : y ≤ y + Δy := by linarith
    have hI : ∀ x ∈ Set.Icc y (y + Δy), -1 < x := fun x hx => by linarith [hx.1]
    have L := taylor3_up (K := 0) hab
      (fun x hx => hasDerivAt_price A N (hI x hx))
      (fun x hx => hasDerivAt_d1 A N (hI x hx))
      (fun x hx => hasDerivAt_d2 A N (hI x hx))
      (fun x hx => (third_bounds A N _ hA hy x hx.1).2)
    have U := taylor3_up (f := fun x => -price A N x) (K := thirdCap A N y) hab
      (fun x hx => (hasDerivAt_price A N (hI x hx)).neg)
      (fun x hx => (hasDerivAt_d1 A N (hI x hx)).neg)
      (fun x hx => (hasDerivAt_d2 A N (hI x hx)).neg)
      (fun x hx => by linarith [(third_bounds A N _ hA hy x hx.1).1])
    have hs : y + Δy - y = Δy := by ring
    rw [hs] at L U
    rw [abs_of_pos h]
    have hp : 0 ≤ thirdCap A N y * Δy ^ 3 := mul_nonneg hM0 (pow_nonneg h.le 3)
    refine ⟨abs_le.mpr ⟨?_, ?_⟩, fun _ => by linarith, fun h' => absurd h' (by linarith)⟩
    · linarith
    · linarith

/-- **Duration and convexity are the price's slope and bend.** For any fixed payments and a
yield above minus one hundred percent, `-(1/P) dP/dy` is the modified duration and
`(1/P) d²P/dy²` is the convexity. -/
theorem duration_and_convexity_from_derivatives (A : ℕ → ℝ) (N : ℕ) (y : ℝ) (hy : -1 < y) :
    -(1 / price A N y) * deriv (price A N) y = modDuration A N y ∧
    1 / price A N y * deriv (deriv (price A N)) y = convexity A N y := by
  rw [deriv_price A N hy, deriv2_price A N hy]
  exact ⟨dur_id A N y, rfl⟩

/-- **The bend is always upward.** For a bond with at least one payment and every payment
positive, at any yield above minus one hundred percent the second derivative of the price and
the convexity are positive, and the price curve sits strictly above the duration line at every
other yield above minus one hundred percent: a rise costs less than duration alone says, a fall
pays more. -/
theorem convexity_pos_and_price_above_duration_line (A : ℕ → ℝ) (N : ℕ) (y Δy : ℝ)
    (hN : 1 ≤ N) (hA : ∀ t ∈ Icc 1 N, 0 < A t) (hy : -1 < y) (hy' : -1 < y + Δy)
    (hΔ : Δy ≠ 0) :
    0 < deriv (deriv (price A N)) y ∧ 0 < convexity A N y ∧
    price A N y * (1 - modDuration A N y * Δy) < price A N (y + Δy) := by
  have hA' : ∀ t ∈ Icc 1 N, 0 ≤ A t := fun t ht => (hA t ht).le
  have hP : 0 < price A N y :=
    Finset.sum_pos (fun t ht => div_pos (hA t ht) (pow_pos (by linarith) t))
      (Finset.nonempty_Icc.mpr hN)
  have hd2 : ∀ x : ℝ, -1 < x →
      0 < ∑ t ∈ Icc 1 N, (t : ℝ) * (t + 1) * A t / (1 + x) ^ (t + 2) := fun x hx =>
    Finset.sum_pos (fun t ht => by
      have ht1 : (1 : ℝ) ≤ t := by exact_mod_cast (Finset.mem_Icc.mp ht).1
      exact div_pos (mul_pos (mul_pos (by linarith) (by linarith)) (hA t ht))
        (pow_pos (by linarith) _))
      (Finset.nonempty_Icc.mpr hN)
  refine ⟨?_, ?_, ?_⟩
  · rw [deriv2_price A N hy]; exact hd2 y hy
  · unfold convexity
    exact mul_pos (one_div_pos.mpr hP) (hd2 y hy)
  · have e : price A N y * (1 - modDuration A N y * Δy) =
        price A N y + (∑ t ∈ Icc 1 N, -((t : ℝ) * A t) / (1 + y) ^ (t + 1)) * Δy := by
      linear_combination (-Δy) * P_mul_dur A N y hA' hy
    rw [e]
    rcases lt_or_gt_of_ne hΔ with h | h
    · have hab : y + Δy ≤ y := by linarith
      have hI : ∀ x ∈ Set.Icc (y + Δy) y, -1 < x := fun x hx => by linarith [hx.1]
      have S1 := smono_of (fun x hx => hasDerivAt_d1 A N (hI x hx))
        (fun x hx => hd2 x (hI x (Set.Ioo_subset_Icc_self hx)))
      have S0 := santi_of
        (fun x hx => hd_poly (hasDerivAt_price A N (hI x hx)) y (price A N y)
          (∑ t ∈ Icc 1 N, -((t : ℝ) * A t) / (1 + y) ^ (t + 1)) 0 0)
        (fun x hx => by
          have := S1 (Set.Ioo_subset_Icc_self hx) ⟨hab, le_rfl⟩ hx.2
          simp only [zero_mul, zero_div, sub_zero]
          linarith)
      have := S0 ⟨le_rfl, hab⟩ ⟨hab, le_rfl⟩ (by linarith)
      simp only [sub_self, mul_zero, zero_mul, zero_div, sub_zero, add_sub_cancel_left] at this
      linarith
    · have hab : y ≤ y + Δy := by linarith
      have hI : ∀ x ∈ Set.Icc y (y + Δy), -1 < x := fun x hx => by linarith [hx.1]
      have S1 := smono_of (fun x hx => hasDerivAt_d1 A N (hI x hx))
        (fun x hx => hd2 x (hI x (Set.Ioo_subset_Icc_self hx)))
      have S0 := smono_of
        (fun x hx => hd_poly (hasDerivAt_price A N (hI x hx)) y (price A N y)
          (∑ t ∈ Icc 1 N, -((t : ℝ) * A t) / (1 + y) ^ (t + 1)) 0 0)
        (fun x hx => by
          have := S1 ⟨le_rfl, hab⟩ (Set.Ioo_subset_Icc_self hx) hx.1
          simp only [zero_mul, zero_div, sub_zero]
          linarith)
      have := S0 ⟨le_rfl, hab⟩ ⟨hab, le_rfl⟩ (by linarith)
      simp only [sub_self, mul_zero, zero_mul, zero_div, sub_zero, add_sub_cancel_left] at this
      linarith

/-! The card's house bond: 60 a year for five years, with the face of 1,000 paid alongside the
last coupon, so 60, 60, 60, 60, 1060. A 5% yield is `1/20`. Decimals on the card are checked as
windows of half a unit in their last place. -/

-- Repriced at 6%, the house bond is worth exactly its face, 1,000.
example : price (fun t => if t = 5 then 1060 else 60) 5 (6 / 100) = 1000 := by
  simp [price, Finset.sum_Icc_succ_top]
  norm_num

-- A five-year zero-coupon bond has a Macaulay duration of exactly 5 years.
example : macaulay (fun t => if t = 5 then 1000 else 0) 5 (1 / 20) = 5 := by
  simp [macaulay, weight, price, Finset.sum_Icc_succ_top]
  norm_num

-- The house bond's Macaulay duration rounds to 4.477751 years.
example : (44777505 / 10000000 : ℝ) ≤ macaulay (fun t => if t = 5 then 1060 else 60) 5 (1 / 20) ∧
    macaulay (fun t => if t = 5 then 1060 else 60) 5 (1 / 20) < 44777515 / 10000000 := by
  simp [macaulay, weight, price, Finset.sum_Icc_succ_top]
  norm_num

-- Its modified duration rounds to 4.264525.
example : (42645245 / 10000000 : ℝ) ≤
      modDuration (fun t => if t = 5 then 1060 else 60) 5 (1 / 20) ∧
    modDuration (fun t => if t = 5 then 1060 else 60) 5 (1 / 20) < 42645255 / 10000000 := by
  simp [modDuration, macaulay, weight, price, Finset.sum_Icc_succ_top]
  norm_num

-- Its convexity rounds to 23.444091.
example : (234440905 / 10000000 : ℝ) ≤
      convexity (fun t => if t = 5 then 1060 else 60) 5 (1 / 20) ∧
    convexity (fun t => if t = 5 then 1060 else 60) 5 (1 / 20) < 234440915 / 10000000 := by
  simp [convexity, price, Finset.sum_Icc_succ_top]
  norm_num

-- On the one-point rise, duration plus convexity predicts 1,000.026155 against a true 1,000.
example :
    let P := price (fun t => if t = 5 then 1060 else 60) 5 (1 / 20)
    let D := modDuration (fun t => if t = 5 then 1060 else 60) 5 (1 / 20)
    let C := convexity (fun t => if t = 5 then 1060 else 60) 5 (1 / 20)
    (10000261545 / 10000000 : ℝ) ≤ P * (1 - D * (1 / 100) + 1 / 2 * C * (1 / 100) ^ 2) ∧
      P * (1 - D * (1 / 100) + 1 / 2 * C * (1 / 100) ^ 2) < 10000261555 / 10000000 := by
  simp [modDuration, macaulay, weight, convexity, price, Finset.sum_Icc_succ_top]
  norm_num

-- The certified bound on that rise, read at the 5% floor, rounds to 0.026649 dollars.
example : (266485 / 10000000 : ℝ) ≤
      thirdCap (fun t => if t = 5 then 1060 else 60) 5 (1 / 20) * |(1 / 100 : ℝ)| ^ 3 / 6 ∧
    thirdCap (fun t => if t = 5 then 1060 else 60) 5 (1 / 20) * |(1 / 100 : ℝ)| ^ 3 / 6
      < 266495 / 10000000 := by
  simp [thirdCap, Finset.sum_Icc_succ_top]
  norm_num

#print axioms price_move_by_duration_and_convexity
#print axioms duration_and_convexity_from_derivatives
#print axioms convexity_pos_and_price_above_duration_line
#print axioms hasDerivAt_term
#print axioms anti_of
#print axioms mono_of
#print axioms smono_of
#print axioms santi_of
#print axioms chain_up
#print axioms chain_down
#print axioms hd_poly
#print axioms taylor3_up
#print axioms taylor3_down
#print axioms hasDerivAt_price
#print axioms hasDerivAt_d1
#print axioms hasDerivAt_d2
#print axioms deriv_price
#print axioms deriv2_price
#print axioms dur_id
#print axioms zero_of_price_zero
#print axioms P_mul_dur
#print axioms P_mul_conv
#print axioms third_bounds
```

**Checked 2026-11-13 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'price_move_by_duration_and_convexity' depends on axioms: [propext, Classical.choice, Quot.sound]
'duration_and_convexity_from_derivatives' depends on axioms: [propext, Classical.choice, Quot.sound]
'convexity_pos_and_price_above_duration_line' depends on axioms: [propext, Classical.choice, Quot.sound]
'hasDerivAt_term' depends on axioms: [propext, Classical.choice, Quot.sound]
'anti_of' depends on axioms: [propext, Classical.choice, Quot.sound]
'mono_of' depends on axioms: [propext, Classical.choice, Quot.sound]
'smono_of' depends on axioms: [propext, Classical.choice, Quot.sound]
'santi_of' depends on axioms: [propext, Classical.choice, Quot.sound]
'chain_up' depends on axioms: [propext, Classical.choice, Quot.sound]
'chain_down' depends on axioms: [propext, Classical.choice, Quot.sound]
'hd_poly' depends on axioms: [propext, Classical.choice, Quot.sound]
'taylor3_up' depends on axioms: [propext, Classical.choice, Quot.sound]
'taylor3_down' depends on axioms: [propext, Classical.choice, Quot.sound]
'hasDerivAt_price' depends on axioms: [propext, Classical.choice, Quot.sound]
'hasDerivAt_d1' depends on axioms: [propext, Classical.choice, Quot.sound]
'hasDerivAt_d2' depends on axioms: [propext, Classical.choice, Quot.sound]
'deriv_price' depends on axioms: [propext, Classical.choice, Quot.sound]
'deriv2_price' depends on axioms: [propext, Classical.choice, Quot.sound]
'dur_id' depends on axioms: [propext, Classical.choice, Quot.sound]
'zero_of_price_zero' depends on axioms: [propext, Classical.choice, Quot.sound]
'P_mul_dur' depends on axioms: [propext, Classical.choice, Quot.sound]
'P_mul_conv' depends on axioms: [propext, Classical.choice, Quot.sound]
'third_bounds' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess the direction first, then run it.
> - **Strip the coupons.** Set `COUPON` to `0`: a five-year zero. Macaulay duration becomes 5.000000 years, exactly the maturity, and convexity climbs from 23.444091 to 27.210884. Coupons pull money forward, and that cuts both.
> - **Double the maturity.** Set `YEARS` to `10`. Modified duration goes from 4.264525 to 7.516332, so the same one-point rise costs three quarters as much again.
> - **Make the move big.** A three-point rise leaves the second-order estimate 0.680863 out, against under three cents for one point: the leftover grows as the cube of the move.
> - **Break the maths.** Change `0.5 * Cvx` to `Cvx` in the quadratic estimate and the certificate assert stops the program: the error is now larger than Step 4 proved it could be.

---

## The usual mistake

> [!warning]
> **Reading duration as a date.** "Duration 4.48 years" sounds like a maturity, and it is not one. It is the average year a dollar comes back, weighted by what each payment contributes to today's price — 4.477751 years on a bond that runs five. Only a bond with no coupons has the two coincide. And modified duration, 4.264525, is not a time at all: it is a fraction of the price per unit of yield, which happens to be written in the same units.
>
> - **Using the wrong duration in the price formula.** Macaulay where modified belongs prices the one-point rise at 996.578622 when the answer is 1,000.000000. The two differ by one factor of $(1+y)$, so at a five percent yield the predicted fall comes out five percent too big.
> - **Feeding in the wrong units.** A hundred basis points is $\Delta y = 0.01$. Typed as 1.0 the formula returns −3,405.861841, a negative price, which at least announces itself. Ten basis points typed as 10 does not.
> - **Dropping the one-half.** Taylor's second term carries a half. Without it the same rise prices at 1001.249110, past the true price rather than short of it.
> - **Believing every bond is convex.** Positive payments make the bend positive, and only positive payments. A bond the issuer can repay early, or a pool of mortgages that can be refinanced, has payments that move with rates, and its curve can bend the other way: [Negative convexity](../35-Mortgages%2C%20Callables%20and%20Prepayment/03-negative-convexity.md).

---

## Where you meet it in real life

- **A rates desk's risk screen.** Every position shows a DV01, the cash it loses on a one-basis-point rise: 0.444916 dollars per 1,000 of face here. Summed across the book, it is the one number the desk manages all day.
- **Pension funds and insurers.** A pension promises payments decades out: a very long bond in disguise. Matching the duration of what is owned to the duration of what is owed makes the fund roughly indifferent to a rate move — immunisation, set out by F. M. Redington in 1952.
- **Comparing loans and projects.** The same arithmetic works on any fixed stream of cash, so a mortgage, a lease or a project appraisal has a duration too: [Annuities](03-annuities-and-loans.md) and [NPV and IRR](04-net-present-value-and-irr.md).
- **The options desk, under other names.** [Delta](../09-The%20Greeks%2C%20one%20each/01-delta.md) and [Gamma](../09-The%20Greeks%2C%20one%20each/02-gamma.md) are the first and second derivatives of an option's price against the share price: same Taylor expansion, different curve.
- **Reading a price backwards.** Everything here starts from a yield. Markets quote prices, and getting the yield out of a price takes a search rather than a formula: [Yield from price](07-yield-from-price.md).

> **Say it back**
> A bond's price is a curve drawn against its yield: falling, and bending. Duration is the slope of that curve, convexity the bend. Macaulay duration is the average year a dollar comes back, weighted by each payment's share of the price; divide it by one plus the yield to get modified duration, the fraction of the price lost per unit of yield. Convexity weights the same payments by $t(t+1)$ and is positive whenever the payments are, so the curve always sits above its tangent: a rise costs less than duration threatens and a fall pays more than it promises. Together they predict a price move to second order, with a leftover that grows as the cube of the move and can be bounded before the move happens.

---

## What this builds on

- [Bond price and yield](05-bonds-price-and-yield.md): the price function itself — five dated payments, one yield, one number — and the discount factors that build it. This card differentiates it twice.
- [Taylor's theorem](../../06-Calculus%20and%20analysis/03-What%20Derivatives%20Tell%20You/05-taylors-theorem.md): the rule that a smooth function near a point equals its value, plus slope times step, plus half the bend times step squared, plus a remainder that can be bounded. Duration and convexity are the first two terms; Step 4's certificate is the remainder.

## Where this goes next

- [Swap DV01](../28-Swaps/03-swap-dv01-and-hedging.md): DV01 applied to an instrument with two legs, and the trade that sets a book's rate risk to zero.
- [Negative convexity](../35-Mortgages%2C%20Callables%20and%20Prepayment/03-negative-convexity.md): what happens when the payments themselves react to rates, and the bend turns the wrong way.
- [Key-rate durations](../33-Curves%20in%20Depth/02-key-rate-durations-and-curve-hedging.md): one duration for each point on the curve, for a curve that twists.

This card held two things still: the payments were fixed, and the whole yield moved as one block. Let go of the first and convexity can turn negative; let go of the second and one number per bond stops being enough — and those are the two doors later cards go through.

---

## Sources

Verified 14 Sep 2026: every link below resolves to the publisher's page.

- Macaulay, Frederick R. *Some Theoretical Problems Suggested by the Movements of Interest Rates, Bond Yields and Stock Prices in the United States since 1856*. National Bureau of Economic Research, 1938. [Publisher page](https://www.nber.org/books-and-chapters/some-theoretical-problems-suggested-movements-interest-rates-bond-yields-and-stock-prices-united). Where the weighted average time to payment was first defined and named.
- Redington, F. M. "Review of the Principles of Life-Office Valuations." *Journal of the Institute of Actuaries* 78, no. 3 (1952): 286–340. [doi:10.1017/S0020268100052811](https://doi.org/10.1017/S0020268100052811). Immunisation: matching the duration of assets to liabilities, and why the second derivative decides whether the match helps or hurts.
- Tuckman, Bruce, and Angel Serrat. *Fixed Income Securities: Tools for Today's Markets*, 4th ed. Wiley, 2022. [Publisher page](https://www.wiley.com/en-us/Fixed+Income+Securities%3A+Tools+for+Today%27s+Markets%2C+4th+Edition-p-9781119835554). The market-desk treatment: DV01, duration, convexity and the hedges built from them.
- Hull, John C. *Options, Futures, and Other Derivatives*, 11th ed. Pearson. [Publisher page](https://www.pearson.com/en-us/subject-catalog/p/options-futures-and-other-derivatives/P200000005938). The textbook derivation of duration and the convexity correction, and the bridge to delta and gamma.
