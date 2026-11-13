# The HJB equation: dynamic programming in continuous time, and for linear motion with squared costs the best control is a feedback gain

[Syllabus](../../../SYLLABUS.md) → [Differential equations and dynamics](../README.md) → [Calculus of Variations and Optimal Control](../README.md#s12) → The HJB equation

---

## General Overview

A car on cruise control leaves a downhill stretch 2 m/s above its set speed. The controller commands an acceleration; drag is ignored. Each second off speed costs the square of the speed error; each second of pushing costs the square of the push, both weighted 1 in these units. Push hard and the error vanishes, expensively. Push gently and it lingers.

Dynamic programming ([Dynamic programming](07-dynamic-programming-and-the-bellman-equation.md)) works in stages. The car's clock has none. Shrink a stage to an instant and the Bellman equation becomes a differential equation for the best cost itself: the **Hamilton-Jacobi-Bellman equation**, HJB for short.

The answer is a rule, not a plan: decelerate at the speed error, 2 m/s^2 at 2 m/s too fast. The error halves every 0.693 s, and the manoeuvre costs 4 units, the square of the starting error.

**The best achievable cost, written as a function of the state, satisfies the HJB equation over every instant; for linear motion and squared costs it is a square whose coefficient solves a Riccati equation, and the best control is the state times a fixed gain.**

**What kind of fact this is:** a theorem, proved on this card in Why it works for the car and in the folded Detailed proof for any problem with a smooth best cost.

### The picture: the speed error under the best rule

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Speed error under u = -x, from 2 m/s"
    x-axis "time (s)" ["0", "0.5", "1", "1.5", "2", "2.5", "3"]
    y-axis "speed error (m/s)" 0 --> 2.2
    line [2.00, 1.21, 0.74, 0.45, 0.27, 0.16, 0.10]
```

The one line is the speed error under the rule "push equals minus the error", stepped by the check scripts.

---

## The formula

Notation first, in words. A prime means rate in time. For a function of time and state, subscripts mean partial derivatives: $V_t$ is the rate in time with the state fixed, $V_x$ the slope in the state. The car's motion and cost are

$$x' = u, \qquad J = \int_0^\infty \big(x^2 + u^2\big)\,dt .$$

The **value function** $V(t, x)$ is the least cost any control can achieve from state $x$ at time $t$. The HJB equation says

$$-V_t = \min_{u}\big(x^2 + u^2 + V_x\, u\big).$$

**Read it aloud:** the best cost falls with time at the smallest cost rate available now, counting the push's effect on the best cost.

With no deadline, $V_t = 0$. The guess $V = P x^2$ turns the equation into the **Riccati equation** $1 - P^2 = 0$, whose positive root gives

$$V(x) = x^2, \qquad u = -\tfrac12 V_x = -x .$$

**Read it aloud:** the best cost from error x is x squared, and the best push is minus the error.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $x$, $x_0$ | speed error, m/s; its starting value | $x_0$ = 2 m/s | cost grows as its square |
| $u$ | commanded acceleration, m/s^2 | −2 m/s^2 at the start | faster fix, dearer pushing |
| $t$, $h$ | time in s; $h$ a short step of time | $h$ = 0.1, 0.01, 0.001 s | larger $h$: cruder step |
| $J$ | total cost, the integral of $x^2 + u^2$ | 4 under the best rule | — |
| $V$, $V_t$, $V_x$, $W$ | value function; its rate in time; its slope in the state; $W$ a candidate for $V$ | $V(x) = x^2$, $V_x = 2x$ | — |
| $P$ | coefficient of the quadratic value, $V = P x^2$ | 1 with no deadline | bigger $P$: stronger push |
| $k$ | feedback gain: the rule $u = -k x$ | 1 is best | above 1 overpays for pushing |
| $T$, $s$, $\tanh$ | deadline, s; time left $s = T - t$; the hyperbolic tangent, $(e^{2s}-1)/(e^{2s}+1)$ | 1 s left: $P$ = 0.761594 | longer horizon: $P$ nears 1 |

### When it holds

- **A smooth value function.** The derivation uses $V_x$. If the push is capped and the cost is the time to reach zero error, the value has a corner at zero and HJB holds only in a weaker sense.
- **A positive cost on the push.** Without $u^2$ the minimum over $u$ does not exist.
- **Linear motion and squared costs, for the quadratic guess.** With drag, HJB still holds but $V$ is no longer $P x^2$.
- **The positive root.** $P = -1$ also solves $1 - P^2 = 0$, and gives a runaway car.
- **No noise.** Chance adds a second-derivative term (wing 11).

---

## Why it works

### Step 0: the best cost balances over every instant

The best cost from here is the cost of the next short stretch plus the best cost from where it ends, minimised over the first move. That holds for any length of stretch; shrink it to zero and the balance becomes a differential equation.

### Step 1: the Bellman equation over a short step

Hold the push $u$ for a short time $h$. The stretch costs about $(x^2 + u^2)h$ and moves the error to $x + uh$:

$$V(t, x) = \min_u \Big( (x^2 + u^2)\,h + V(t + h,\; x + u h) \Big).$$

To first order ([Taylor series](../../06-Calculus%20and%20analysis/06-Series/05-taylor-series.md)), $V(t+h, x+uh) = V + V_t h + V_x u h$. $V$ cancels from both sides. Divide by $h$ and let it shrink to zero:

$$0 = V_t + \min_u \big( x^2 + u^2 + V_x u \big).$$

### Step 2: the minimum over the push

The bracket is a bowl in $u$ with slope $2u + V_x$, zero at $u = -V_x/2$. There the bracket is $x^2 - V_x^2/4$, so HJB becomes $V_t + x^2 - \tfrac14 V_x^2 = 0$. At $x$ = 2 with $V_x$ = 4 (the slope Step 3 finds), a search in the check scripts, which never uses this algebra, finds the bottom at $u$ = −2.0000, with the bracket at 0.000000.

### Step 3: guess a square, get a Riccati equation

Doubling the error doubles every sensible push and quadruples every cost. So try $V = P x^2$: then $V_x = 2Px$ and HJB reads $V_t + x^2 - P^2x^2 = 0$.

With no deadline, $V_t = 0$ and $1 - P^2 = 0$, the **algebraic Riccati equation**. Its root $P = 1$ gives $u = -x$, so $x' = -x$ and $x = 2e^{-t}$, which halves when $t = \ln 2$ = 0.693 s.

With a deadline, $V = P(t)x^2$ and dividing by $x^2$ leaves the **Riccati differential equation**. In the time left $s$ it reads $dP/ds = 1 - P^2$, with $P = 0$ when no time is left. Its solution ([Bernoulli and Riccati equations](../01-Rate%20Equations/09-bernoulli-and-riccati-substitutions.md)) is $P = \tanh s$: 0.761594 with 1 s left, 0.995055 with 3 s left.

### Step 4: no other rule does better

The error's square changes at rate $2xu$, and $(x+u)^2 \geq 0$ gives

$$x^2 + u^2 \;\geq\; -2xu \;=\; -\frac{d}{dt}\,x^2 .$$

Integrate from time 0: any control that returns the error to zero costs at least $x_0^2$ = 4, with equality only when $u = -x$.

<details>
<summary>Detailed proof: the verification theorem</summary>

Let $W(t, x)$ be smooth, satisfy HJB, and be zero at the deadline $T$. Along any control's motion $W$ changes at rate $W_t + W_x u$ (chain rule), which HJB says is at least $-(x^2 + u^2)$. Integrating from 0 to $T$ gives $0 - W(0, x_0) \geq -J$, so every control costs at least $W(0, x_0)$. The minimising control makes each inequality an equality, so it costs exactly $W(0, x_0)$: $W$ is the value.

With no deadline, let $T$ grow: a control of finite cost makes $x^2$ and its rate $2xu$ integrable, so $x^2$, and with it $W$, tends to zero.

</details>

### Step 5: a second road, Bellman on short steps

Apply Bellman's rule exactly on steps of $h$, back from $P = 0$: each step turns $P$ into $h + P/(1+hP)$.

<details>
<summary>The algebra behind this, if you want it</summary>

One step costs $h(x^2 + u^2) + P(x + hu)^2$. Its slope in $u$ vanishes at $u = -Px/(1+hP)$, where $x + hu = x/(1+hP)$ and the step's best cost is $x^2\big(h + P/(1+hP)\big)$.

</details>

The recursion settles at 1.051249 for steps of 0.1 s, 1.005012 for 0.01 s, 1.000500 for 0.001 s: the gap to 1 shrinks with the step.

Pontryagin's principle ([Pontryagin's principle](06-pontryagins-principle-and-bang-bang-control.md)) is a third road: its costate, the price it puts on a unit of state, is $V_x$ along the best path. It finds one path from one start; HJB finds the best push from every state.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| HJB, no deadline, $V = Px^2$ | $1 - P^2 = 0$, positive root | $P$ = 1 |
| best push at the start | $u = -x_0$ | −2 m/s^2 |
| error after 1 s | $2e^{-1}$ | 0.74 m/s |
| halving time | $\ln 2$ | 0.693 s |
| total cost | $V(x_0) = x_0^2$ | **4** |
| with a 1 s deadline | $x_0^2 \tanh 1$ | 3.0464 |

The car sheds its excess speed with a brake that eases off as the error shrinks, and no rule does it for less than 4.

### The picture: what other gains cost

A fixed gain $k$ gives cost $x_0^2 (1 + k^2)/(2k)$; the check scripts step each gain instead.

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Total cost of the rule u = -k x, from 2 m/s"
    x-axis "gain k (m/s^2 per m/s)" ["0.25", "0.5", "1", "1.5", "2", "3"]
    y-axis "total cost (units)" 0 --> 9
    line [8.50, 5.00, 4.00, 4.33, 5.00, 6.67]
```

The one line is each gain's stepped cost, lowest at gain 1; a scan in steps of 0.01 also finds 1.00.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| No cost on the push | gain 20: error cost 0.1000, true cost 40.1000; no gain is best | without $u^2$ the minimum over $u$ does not exist |
| Slope of $x^2$ taken as $x$ | gain 0.5, cost 5.0000, halving in 1.386 s | the slope of $x^2$ is $2x$ |
| Root $P = -1$ | $u = +x$; error 40.1711 m/s after 3 s | a cost cannot be negative |
| No-deadline value on a 1 s trip | 4.0000 instead of 3.0464 | a deadline needs $P = \tanh s$ |

The code prints every entry.

---

## Code, from first principles, and it actually runs

Five roads: a ternary search (discarding a third of an interval at a time) for the best push; fourth-order Runge-Kutta (RK4) stepping the car and its cost under each gain; a scan over gains; the stepped Bellman recursion; and RK4 on the Riccati equation against $\tanh$ built from the exponential.

### Python

```python
# The HJB equation and the linear-quadratic regulator -- the check behind the card.
# Cruise control: speed error x (m/s), push u (m/s^2), x' = u, cost the integral of
# x^2 + u^2.  Claim: value V(x) = x^2, best push u = -x.  Roads: the formula; a search
# over u; RK4 stepping of the car; a backward Bellman recursion; RK4 on the Riccati.
import math
X0 = 2.0

def run(k, h=0.01, t_end=60.0):          # RK4 on x' = -k x, cost rate (1 + k^2) x^2
    f = lambda x: (-k * x, (1 + k * k) * x * x)
    x, c, t, half, path = X0, 0.0, 0.0, None, [X0]
    for _ in range(round(t_end / h)):
        a = f(x); b = f(x + h / 2 * a[0]); d = f(x + h / 2 * b[0]); e = f(x + h * d[0])
        xn = x + h / 6 * (a[0] + 2 * b[0] + 2 * d[0] + e[0])
        c += h / 6 * (a[1] + 2 * b[1] + 2 * d[1] + e[1])
        if half is None and xn <= X0 / 2:        # straight line between the two steps
            half = t + h * (x - X0 / 2) / (x - xn)
        x, t = xn, t + h; path.append(x)
    return c, half, path
def ternary(g, lo, hi):                  # the lowest point of a bowl-shaped g
    for _ in range(200):
        m1, m2 = lo + (hi - lo) / 3, hi - (hi - lo) / 3
        lo, hi = (lo, m2) if g(m1) < g(m2) else (m1, hi)
    return (lo + hi) / 2
def bellman(h, p=0.0):                   # V = P x^2 on steps of h, back from P = 0
    for _ in range(round(40 / h)):
        p = h + p / (1 + h * p)
    return p
def riccati(s_end, h, p=0.0, g=lambda p: 1 - p * p):   # RK4 on P' = 1 - P^2 in time to go
    for _ in range(round(s_end / h)):
        a = g(p); b = g(p + h / 2 * a); d = g(p + h / 2 * b); p += h / 6 * (a + 2 * b + 2 * d + g(p + h * d))
    return p

tanh = lambda s: (math.exp(2 * s) - 1) / (math.exp(2 * s) + 1)
u_best = ternary(lambda u: X0 * X0 + u * u + 2 * X0 * u, -10, 10)
c1, half, path = run(1.0)
gains = [0.25, 0.5, 1.0, 1.5, 2.0, 3.0]; costs = [run(k)[0] for k in gains]
scan = min((run(k / 100, h=0.02)[0], k / 100) for k in range(25, 301))
print(f"HJB at x = 2, V' = 4: search finds u = {u_best:.4f}, min of x^2 + u^2 + V'u = {X0 * X0 + u_best ** 2 + 2 * X0 * u_best:.6f}")
print(f"cost of u = -x from x0 = 2, RK4 stepped: {c1:.6f}; value V(2) = x0^2 = {X0 * X0:.6f}")
print(f"error halves after {half:.3f} s, stepped; ln 2 = {math.log(2):.3f} s")
print("chart, error x(t) at t = 0 0.5 1 1.5 2 2.5 3:", " ".join(f"{path[i]:.2f}" for i in range(0, 301, 50)))
print("chart, cost of gain k =", " ".join(f"{k}" for k in gains) + ":", " ".join(f"{c:.2f}" for c in costs))
print(f"best gain on a scan 0.25 to 3 in steps of 0.01: k = {scan[1]:.2f}, cost {scan[0]:.4f}")
for h in (0.1, 0.01, 0.001):
    p = bellman(h)
    print(f"Bellman on steps of {h}: P = {p:.6f}, gain {p / (1 + h * p):.6f}, P - 1 = {p - 1:.6f}")
for h in (0.1, 0.05):
    ps = [riccati(s, h) for s in (1, 2, 3)]
    print(f"Riccati RK4 h = {h}: P at 1, 2, 3 s to go = " + " ".join(f"{p:.6f}" for p in ps)
          + f"; worst error vs tanh {max(abs(p - tanh(s)) for p, s in zip(ps, (1, 2, 3))):.1e}")
print(f"tanh(1) = {tanh(1):.6f}; 1 s trip from x0 = 2 costs {X0 * X0 * tanh(1):.4f}, not {X0 * X0:.4f}")
c20, (c05, h05, _) = run(20.0, h=0.001), run(0.5)
print(f"mistake, no push cost: gain 20 gives speed cost {c20[0] / 401:.4f}, true cost {c20[0]:.4f}")
print(f"mistake, V' = x not 2x: gain 0.5, cost {c05:.4f}, halving time {h05:.3f} s")
print(f"mistake, root P = -1: u = +x, error after 3 s = {run(-1.0, t_end=3.0)[2][-1]:.4f} m/s")
assert abs(c1 - X0 * X0) < 1e-6 and abs(half - math.log(2)) < 1e-3   # stepping vs formula
assert abs(scan[1] - 1.0) < 1e-9 and all(abs(c - X0 * X0 * (1 + k * k) / (2 * k)) < 1e-6 for c, k in zip(costs, gains))
assert abs(bellman(0.001) - 1) < 1e-3 and 9 < (bellman(0.01) - 1) / (bellman(0.001) - 1) < 11
assert abs(u_best + X0) < 1e-6 and max(abs(riccati(s, 0.05) - tanh(s)) for s in (1, 2, 3)) < 1e-6
print("ALL CHECKS PASS")
```

**Ran 2026-09-28 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
HJB at x = 2, V' = 4: search finds u = -2.0000, min of x^2 + u^2 + V'u = 0.000000
cost of u = -x from x0 = 2, RK4 stepped: 4.000000; value V(2) = x0^2 = 4.000000
error halves after 0.693 s, stepped; ln 2 = 0.693 s
chart, error x(t) at t = 0 0.5 1 1.5 2 2.5 3: 2.00 1.21 0.74 0.45 0.27 0.16 0.10
chart, cost of gain k = 0.25 0.5 1.0 1.5 2.0 3.0: 8.50 5.00 4.00 4.33 5.00 6.67
best gain on a scan 0.25 to 3 in steps of 0.01: k = 1.00, cost 4.0000
Bellman on steps of 0.1: P = 1.051249, gain 0.951249, P - 1 = 0.051249
Bellman on steps of 0.01: P = 1.005012, gain 0.995012, P - 1 = 0.005012
Bellman on steps of 0.001: P = 1.000500, gain 0.999500, P - 1 = 0.000500
Riccati RK4 h = 0.1: P at 1, 2, 3 s to go = 0.761593 0.964026 0.995054; worst error vs tanh 1.4e-06
Riccati RK4 h = 0.05: P at 1, 2, 3 s to go = 0.761594 0.964028 0.995055; worst error vs tanh 8.7e-08
tanh(1) = 0.761594; 1 s trip from x0 = 2 costs 3.0464, not 4.0000
mistake, no push cost: gain 20 gives speed cost 0.1000, true cost 40.1000
mistake, V' = x not 2x: gain 0.5, cost 5.0000, halving time 1.386 s
mistake, root P = -1: u = +x, error after 3 s = 40.1711 m/s
ALL CHECKS PASS
```

### Rust

Same numbers, same labels, built with `rustc --edition 2021 -O`.

```rust
// The HJB equation and the linear-quadratic regulator -- the same check as the Python.
// Cruise control: speed error x (m/s), push u (m/s^2), x' = u, cost the integral of
// x^2 + u^2.  Claim: value V(x) = x^2, best push u = -x.  Roads: the formula; a search
// over u; RK4 stepping of the car; a backward Bellman recursion; RK4 on the Riccati.
const X0: f64 = 2.0;

fn run(k: f64, h: f64, t_end: f64) -> (f64, f64, Vec<f64>) { // RK4: x' = -k x, cost rate (1 + k^2) x^2
    let f = |x: f64| (-k * x, (1.0 + k * k) * x * x);
    let (mut x, mut c, mut t, mut half, mut path) = (X0, 0.0, 0.0, f64::NAN, vec![X0]);
    for _ in 0..(t_end / h).round() as usize {
        let a = f(x); let b = f(x + h / 2.0 * a.0); let d = f(x + h / 2.0 * b.0); let e = f(x + h * d.0);
        let xn = x + h / 6.0 * (a.0 + 2.0 * b.0 + 2.0 * d.0 + e.0);
        c += h / 6.0 * (a.1 + 2.0 * b.1 + 2.0 * d.1 + e.1);
        if half.is_nan() && xn <= X0 / 2.0 { half = t + h * (x - X0 / 2.0) / (x - xn) } // straight line
        x = xn; t += h; path.push(x);
    }
    (c, half, path)
}
fn ternary(g: impl Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 { // lowest point of a bowl
    for _ in 0..200 {
        let (m1, m2) = (lo + (hi - lo) / 3.0, hi - (hi - lo) / 3.0);
        if g(m1) < g(m2) { hi = m2 } else { lo = m1 }
    }
    (lo + hi) / 2.0
}
fn bellman(h: f64) -> f64 {                // V = P x^2 on steps of h, back from P = 0
    let mut p = 0.0;
    for _ in 0..(40.0 / h).round() as usize { p = h + p / (1.0 + h * p) }
    p
}
fn riccati(s_end: f64, h: f64) -> f64 {    // RK4 on P' = 1 - P^2 in time to go, P(0) = 0
    let (g, mut p) = (|p: f64| 1.0 - p * p, 0.0);
    for _ in 0..(s_end / h).round() as usize {
        let a = g(p); let b = g(p + h / 2.0 * a); let d = g(p + h / 2.0 * b);
        p += h / 6.0 * (a + 2.0 * b + 2.0 * d + g(p + h * d));
    }
    p
}
fn tanh(s: f64) -> f64 { ((2.0 * s).exp() - 1.0) / ((2.0 * s).exp() + 1.0) }
fn sci(v: f64) -> String {                 // 1.4e-06, the way Python prints it
    let s = format!("{:.1e}", v);
    let (m, e) = s.split_once('e').unwrap(); let n: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if n < 0 { '-' } else { '+' }, n.abs())
}
fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ") }
fn main() {
    let u_best = ternary(|u| X0 * X0 + u * u + 2.0 * X0 * u, -10.0, 10.0);
    let (c1, half, path) = run(1.0, 0.01, 60.0);
    let gains = [0.25, 0.5, 1.0, 1.5, 2.0, 3.0]; let costs: Vec<f64> = gains.iter().map(|&k| run(k, 0.01, 60.0).0).collect();
    let scan = (25..301).map(|k| (run(k as f64 / 100.0, 0.02, 60.0).0, k as f64 / 100.0))
        .fold((f64::INFINITY, 0.0), |b, c| if c.0 < b.0 { c } else { b });
    println!("HJB at x = 2, V' = 4: search finds u = {:.4}, min of x^2 + u^2 + V'u = {:.6}", u_best, X0 * X0 + u_best * u_best + 2.0 * X0 * u_best);
    println!("cost of u = -x from x0 = 2, RK4 stepped: {:.6}; value V(2) = x0^2 = {:.6}", c1, X0 * X0);
    println!("error halves after {:.3} s, stepped; ln 2 = {:.3} s", half, 2f64.ln());
    let pts: Vec<f64> = (0..301).step_by(50).map(|i| path[i]).collect();
    println!("chart, error x(t) at t = 0 0.5 1 1.5 2 2.5 3: {}", join(&pts, 2));
    println!("chart, cost of gain k = {}: {}", gains.iter().map(|k| format!("{:?}", k)).collect::<Vec<_>>().join(" "), join(&costs, 2));
    println!("best gain on a scan 0.25 to 3 in steps of 0.01: k = {:.2}, cost {:.4}", scan.1, scan.0);
    for h in [0.1, 0.01, 0.001] {
        let p = bellman(h);
        println!("Bellman on steps of {}: P = {:.6}, gain {:.6}, P - 1 = {:.6}", h, p, p / (1.0 + h * p), p - 1.0);
    }
    for h in [0.1, 0.05] {
        let ps: Vec<f64> = [1.0, 2.0, 3.0].iter().map(|&s| riccati(s, h)).collect();
        let worst = ps.iter().zip([1.0, 2.0, 3.0]).map(|(p, s)| (p - tanh(s)).abs()).fold(0.0, f64::max);
        println!("Riccati RK4 h = {}: P at 1, 2, 3 s to go = {}; worst error vs tanh {}", h, join(&ps, 6), sci(worst));
    }
    println!("tanh(1) = {:.6}; 1 s trip from x0 = 2 costs {:.4}, not {:.4}", tanh(1.0), X0 * X0 * tanh(1.0), X0 * X0);
    let (c20, (c05, h05, _)) = (run(20.0, 0.001, 60.0).0, run(0.5, 0.01, 60.0));
    println!("mistake, no push cost: gain 20 gives speed cost {:.4}, true cost {:.4}", c20 / 401.0, c20);
    println!("mistake, V' = x not 2x: gain 0.5, cost {:.4}, halving time {:.3} s", c05, h05);
    println!("mistake, root P = -1: u = +x, error after 3 s = {:.4} m/s", run(-1.0, 0.01, 3.0).2.last().unwrap());
    assert!((c1 - X0 * X0).abs() < 1e-6 && (half - 2f64.ln()).abs() < 1e-3); // stepping vs formula
    assert!((scan.1 - 1.0f64).abs() < 1e-9 && costs.iter().zip(gains).all(|(c, k)| (c - X0 * X0 * (1.0 + k * k) / (2.0 * k)).abs() < 1e-6));
    let r = (bellman(0.01) - 1.0) / (bellman(0.001) - 1.0);
    assert!((bellman(0.001) - 1.0).abs() < 1e-3 && 9.0 < r && r < 11.0);
    assert!((u_best + X0).abs() < 1e-6 && [1.0, 2.0, 3.0].iter().all(|&s| (riccati(s, 0.05) - tanh(s)).abs() < 1e-6));
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-28 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
HJB at x = 2, V' = 4: search finds u = -2.0000, min of x^2 + u^2 + V'u = 0.000000
cost of u = -x from x0 = 2, RK4 stepped: 4.000000; value V(2) = x0^2 = 4.000000
error halves after 0.693 s, stepped; ln 2 = 0.693 s
chart, error x(t) at t = 0 0.5 1 1.5 2 2.5 3: 2.00 1.21 0.74 0.45 0.27 0.16 0.10
chart, cost of gain k = 0.25 0.5 1.0 1.5 2.0 3.0: 8.50 5.00 4.00 4.33 5.00 6.67
best gain on a scan 0.25 to 3 in steps of 0.01: k = 1.00, cost 4.0000
Bellman on steps of 0.1: P = 1.051249, gain 0.951249, P - 1 = 0.051249
Bellman on steps of 0.01: P = 1.005012, gain 0.995012, P - 1 = 0.005012
Bellman on steps of 0.001: P = 1.000500, gain 0.999500, P - 1 = 0.000500
Riccati RK4 h = 0.1: P at 1, 2, 3 s to go = 0.761593 0.964026 0.995054; worst error vs tanh 1.4e-06
Riccati RK4 h = 0.05: P at 1, 2, 3 s to go = 0.761594 0.964028 0.995055; worst error vs tanh 8.7e-08
tanh(1) = 0.761594; 1 s trip from x0 = 2 costs 3.0464, not 4.0000
mistake, no push cost: gain 20 gives speed cost 0.1000, true cost 40.1000
mistake, V' = x not 2x: gain 0.5, cost 5.0000, halving time 1.386 s
mistake, root P = -1: u = +x, error after 3 s = 40.1711 m/s
ALL CHECKS PASS
```

The two outputs match line for line. Halving the RK4 step on the Riccati equation cuts its error from 1.4e-06 to 8.7e-08, the shrink a fourth-order method promises.

### Lean

Lean proves the card's three main facts for every starting error, every coefficient $P$ and every time left.

- Suppose the error starts at $x_0$, moves by $x' = u$ and returns to zero. Then the total cost $J$ is at least $x_0^2$.
- Suppose such a control costs exactly $x_0^2$. Then $u = -x$ at every time, except on a set of times of total length zero.
- Suppose the push follows the rule $u = -x$. Then the total cost is exactly $x_0^2$.
- Take the guess $V = P x^2$, so $V_x = 2Px$. Then the bracket $x^2 + u^2 + V_x u$ is smallest at $u = -Px$, and only there.
- That smallest value is $(1 - P^2) x^2$. So the no-deadline HJB equation holds at every state exactly when $1 - P^2 = 0$.
- Suppose $P$ solves $dP/ds = 1 - P^2$ in the time left $s$, with $P = 0$ when no time is left. Then $P = \tanh s$ for every $s \geq 0$, and $\tanh$ does solve it.
- The arithmetic: from 2 m/s the best cost is 4, the first push is −2 m/s^2, and the HJB bracket is then 0.
- The fixed gains 1, 1/2, 2 and 1/4 cost 4, 5, 5 and 8.50 by the formula.

Stepped costs, the halving time, the Bellman recursion and the decimals of $\tanh$ are left to the Python and Rust checks.

```lean
-- The HJB equation: for the car x' = u with cost the integral of x^2 + u^2, no control costs less than x0^2, the rule u = -x costs exactly x0^2, the quadratic guess V = P x^2 turns HJB into 1 - P^2 = 0, and P = tanh s solves the deadline Riccati equation.
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.MeasureTheory.Integral.IntegralEqImproper
import Mathlib.Order.Bounds.Basic
import Mathlib.Analysis.SpecialFunctions.ImproperIntegrals
import Mathlib.Analysis.ODE.ExistUnique
import Mathlib.Analysis.Calculus.FDeriv.Extend
import Mathlib.Analysis.SpecialFunctions.Trigonometric.DerivHyp

open MeasureTheory Set Filter Topology

theorem hjb_cost_identity (x u : ℝ → ℝ) (x₀ : ℝ) (h0 : x 0 = x₀) (hc : ContinuousOn x (Ici 0))
    (hd : ∀ t, 0 < t → HasDerivAt x (u t) t) (hlim : Tendsto x atTop (𝓝 0))
    (hfin : (∫⁻ t in Ioi 0, ENNReal.ofReal (x t ^ 2 + u t ^ 2)) ≠ ⊤) :
    IntegrableOn (fun t => (x t + u t) ^ 2) (Ioi 0) ∧
    (∫⁻ t in Ioi 0, ENNReal.ofReal (x t ^ 2 + u t ^ 2)) =
      ENNReal.ofReal (x₀ ^ 2 + ∫ t in Ioi 0, (x t + u t) ^ 2) := by
  have hxm : AEStronglyMeasurable x (volume.restrict (Ioi (0:ℝ))) :=
    (hc.mono Ioi_subset_Ici_self).aestronglyMeasurable measurableSet_Ioi
  have hum : AEStronglyMeasurable u (volume.restrict (Ioi (0:ℝ))) := by
    refine (measurable_deriv x).aestronglyMeasurable.congr ?_
    filter_upwards [ae_restrict_mem measurableSet_Ioi] with t ht
    exact (hd t ht).deriv
  have hF : IntegrableOn (fun t => x t ^ 2 + u t ^ 2) (Ioi 0) := by
    refine ⟨(hxm.pow 2).add (hum.pow 2), ?_⟩
    rw [hasFiniteIntegral_iff_ofReal (Eventually.of_forall fun t => by positivity)]
    exact lt_top_iff_ne_top.mpr hfin
  have hP : IntegrableOn (fun t => 2 * x t * u t) (Ioi 0) := by
    refine Integrable.mono' hF ((hxm.const_mul 2).mul hum) (Eventually.of_forall fun t => ?_)
    rw [Real.norm_eq_abs, abs_le]
    constructor <;> nlinarith [sq_nonneg (x t + u t), sq_nonneg (x t - u t)]
  have hFTC : ∫ t in Ioi 0, 2 * x t * u t = 0 - x 0 ^ 2 := by
    refine integral_Ioi_of_hasDerivAt_of_tendsto (f := fun t => x t ^ 2)
      ((hc 0 (mem_Ici.mpr le_rfl)).pow 2) (fun t ht => ?_) hP ?_
    · convert (hd t ht).pow 2 using 1
      push_cast; ring
    · simpa using hlim.pow 2
  have hS : IntegrableOn (fun t => (x t + u t) ^ 2) (Ioi 0) := by
    have := hF.add hP
    refine this.congr_fun (fun t _ => ?_) measurableSet_Ioi
    simp only [Pi.add_apply]; ring
  refine ⟨hS, ?_⟩
  have hsum : ∫ t in Ioi 0, (x t + u t) ^ 2 =
      (∫ t in Ioi 0, (x t ^ 2 + u t ^ 2)) + ∫ t in Ioi 0, 2 * x t * u t := by
    rw [← integral_add hF hP]
    congr 1; funext t; ring
  rw [← ofReal_integral_eq_lintegral_ofReal hF (Eventually.of_forall fun t => by positivity)]
  congr 1
  rw [hsum, hFTC, h0]; ring

#print axioms hjb_cost_identity

theorem tanh_hasDerivAt (s : ℝ) : HasDerivAt Real.tanh (1 - Real.tanh s ^ 2) s := by
  have hc : Real.cosh s ≠ 0 := (Real.cosh_pos s).ne'
  have h := (Real.hasDerivAt_sinh s).div (Real.hasDerivAt_cosh s) hc
  have heq : (Real.sinh / Real.cosh) = Real.tanh := by
    funext y; rw [Pi.div_apply, Real.tanh_eq_sinh_div_cosh]
  rw [heq] at h
  convert h using 1
  rw [Real.tanh_eq_sinh_div_cosh, div_pow]
  field_simp

#print axioms tanh_hasDerivAt

/-- The best cost from speed error `x₀` is `x₀ ^ 2`, and the best control is `u = -x`.
For motion `x' = u` (continuous from time 0, with rate `u t` at every later time) that
returns the error to zero: every control costs at least `x₀ ^ 2` in total `x^2 + u^2`, and
a control that costs exactly `x₀ ^ 2` pushes `u = -x` at almost every time. The feedback
rule `u = -x` costs exactly `x₀ ^ 2`. -/
theorem best_cost_is_square_and_best_push_is_minus_error (x₀ : ℝ) :
    (∀ x u : ℝ → ℝ, x 0 = x₀ → ContinuousOn x (Ici 0) →
        (∀ t, 0 < t → HasDerivAt x (u t) t) → Tendsto x atTop (𝓝 0) →
        ENNReal.ofReal (x₀ ^ 2) ≤ ∫⁻ t in Ioi 0, ENNReal.ofReal (x t ^ 2 + u t ^ 2) ∧
        ((∫⁻ t in Ioi 0, ENNReal.ofReal (x t ^ 2 + u t ^ 2)) = ENNReal.ofReal (x₀ ^ 2) →
          ∀ᵐ t ∂(volume.restrict (Ioi 0)), u t = -x t)) ∧
    (∀ x : ℝ → ℝ, x 0 = x₀ → ContinuousOn x (Ici 0) →
        (∀ t, 0 < t → HasDerivAt x (-x t) t) →
        (∫⁻ t in Ioi 0, ENNReal.ofReal (x t ^ 2 + (-x t) ^ 2)) = ENNReal.ofReal (x₀ ^ 2)) := by
  refine ⟨fun x u h0 hc hd hlim => ?_, fun x h0 hc hd => ?_⟩
  · by_cases hfin : (∫⁻ t in Ioi 0, ENNReal.ofReal (x t ^ 2 + u t ^ 2)) = ⊤
    · rw [hfin]
      exact ⟨le_top, fun h => absurd h.symm ENNReal.ofReal_ne_top⟩
    obtain ⟨hS, hEq⟩ := hjb_cost_identity x u x₀ h0 hc hd hlim hfin
    have hI : 0 ≤ ∫ t in Ioi 0, (x t + u t) ^ 2 := integral_nonneg fun t => sq_nonneg _
    rw [hEq]
    refine ⟨ENNReal.ofReal_le_ofReal (le_add_of_nonneg_right hI), fun h => ?_⟩
    rw [ENNReal.ofReal_eq_ofReal_iff (by positivity) (by positivity)] at h
    have h2 : ∫ t in Ioi 0, (x t + u t) ^ 2 = 0 := by linarith
    rw [integral_eq_zero_iff_of_nonneg (fun t => sq_nonneg _) hS] at h2
    filter_upwards [h2] with t ht
    have : x t + u t = 0 := by simpa using ht
    linarith
  · have hx : ∀ t, 0 < t → x t = x₀ * Real.exp (-t) := by
      intro t ht
      obtain ⟨c, _, hc'⟩ := exists_hasDerivAt_eq_slope (fun t => x t * Real.exp t) (fun _ => (0:ℝ))
        ht ((hc.mono Icc_subset_Ici_self).mul Real.continuous_exp.continuousOn)
        (fun c hc => by
          convert (hd c hc.1).mul (Real.hasDerivAt_exp c) using 1; ring)
      have hne : t - 0 ≠ 0 := by linarith
      have : x t * Real.exp t = x 0 * Real.exp 0 := by
        field_simp at hc'; linarith
      rw [Real.exp_zero, mul_one, h0] at this
      rw [← this, mul_assoc, ← Real.exp_add]; simp
    rw [setLIntegral_congr_fun measurableSet_Ioi
      (g := fun t => ENNReal.ofReal (2 * x₀ ^ 2 * Real.exp (-2 * t))) (fun t ht => by
        simp only
        rw [hx t ht, show -2 * t = -t + -t by ring, Real.exp_add]; ring_nf)]
    have hint : IntegrableOn (fun t => 2 * x₀ ^ 2 * Real.exp (-2 * t)) (Ioi 0) :=
      (integrableOn_exp_mul_Ioi (by norm_num : (-2:ℝ) < 0) 0).const_mul _
    rw [← ofReal_integral_eq_lintegral_ofReal hint (Eventually.of_forall fun t => by positivity),
      integral_const_mul, integral_exp_mul_Ioi (by norm_num : (-2:ℝ) < 0)]
    congr 1; simp; ring

/-- HJB with the quadratic guess `V = P x^2`, so `V_x = 2 P x`. The smallest cost rate
`x^2 + u^2 + V_x u` over all pushes `u` is `(1 - P^2) x^2`, reached only at the feedback
`u = -P x`. So the no-deadline HJB equation `0 = min_u (x^2 + u^2 + V_x u)` holds at every
state exactly when `P` solves the algebraic Riccati equation `1 - P^2 = 0`. -/
theorem hjb_quadratic_guess_gives_riccati (P : ℝ) :
    (∀ x : ℝ,
        IsLeast (range fun u : ℝ => x ^ 2 + u ^ 2 + 2 * P * x * u) ((1 - P ^ 2) * x ^ 2) ∧
        ∀ u : ℝ, x ^ 2 + u ^ 2 + 2 * P * x * u = (1 - P ^ 2) * x ^ 2 ↔ u = -P * x) ∧
    ((∀ x : ℝ, IsLeast (range fun u : ℝ => x ^ 2 + u ^ 2 + 2 * P * x * u) 0) ↔
        1 - P ^ 2 = 0) := by
  have hmin : ∀ x : ℝ,
      IsLeast (range fun u : ℝ => x ^ 2 + u ^ 2 + 2 * P * x * u) ((1 - P ^ 2) * x ^ 2) := by
    intro x
    refine ⟨⟨-P * x, by ring⟩, ?_⟩
    rintro _ ⟨u, rfl⟩
    nlinarith [sq_nonneg (u + P * x)]
  refine ⟨fun x => ⟨hmin x, fun u => ?_⟩, ⟨fun h => ?_, fun h x => ?_⟩⟩
  · constructor
    · intro h
      have : (u + P * x) ^ 2 = 0 := by linear_combination h
      have := pow_eq_zero_iff (n := 2) (by norm_num) |>.mp this
      linarith
    · rintro rfl; ring
  · have := (h 1).unique (hmin 1)
    linarith
  · have := hmin x
    rwa [h, zero_mul] at this

/-- With a deadline, the coefficient `P` as a function of the time left `s` solves the
Riccati differential equation `dP/ds = 1 - P^2` with `P = 0` when no time is left, and its
solution is `P = tanh s`: `tanh` solves it, and any solution equals `tanh` for `s ≥ 0`. -/
theorem riccati_with_deadline_solution_is_tanh :
    (Real.tanh 0 = 0 ∧ ∀ s : ℝ, HasDerivAt Real.tanh (1 - Real.tanh s ^ 2) s) ∧
    ∀ P : ℝ → ℝ, P 0 = 0 → ContinuousOn P (Ici 0) →
      (∀ s, 0 < s → HasDerivAt P (1 - P s ^ 2) s) → ∀ s, 0 ≤ s → P s = Real.tanh s := by
  refine ⟨⟨Real.tanh_zero, tanh_hasDerivAt⟩, fun P h0 hc hd s hs => ?_⟩
  obtain ⟨C, hC⟩ := isCompact_Icc.exists_bound_of_continuousOn (hc.mono (Icc_subset_Ici_self : Icc (0:ℝ) s ⊆ Ici 0))
  set R : ℝ := max C 1 with hR
  have hR1 : 1 ≤ R := le_max_right _ _
  have hLip : LipschitzOnWith (Real.toNNReal (2 * R)) (fun y : ℝ => 1 - y ^ 2)
      (Metric.closedBall 0 R) := by
    refine LipschitzOnWith.of_dist_le_mul fun y hy z hz => ?_
    rw [Metric.mem_closedBall, Real.dist_eq, sub_zero] at hy hz
    rw [Real.coe_toNNReal _ (by linarith), Real.dist_eq, Real.dist_eq]
    have : (1 - y ^ 2) - (1 - z ^ 2) = (z + y) * (z - y) := by ring
    rw [this, abs_mul, abs_sub_comm z y]
    have : |z + y| ≤ 2 * R := (abs_add_le z y).trans (by linarith)
    exact mul_le_mul_of_nonneg_right this (abs_nonneg _)
  have hP0 : HasDerivWithinAt P 1 (Ici 0) 0 := by
    have hcw : ContinuousWithinAt P (Ioi 0) 0 := (hc 0 (mem_Ici.mpr le_rfl)).mono Ioi_subset_Ici_self
    refine hasDerivWithinAt_Ici_of_tendsto_deriv
      (fun t ht => (hd t ht).differentiableAt.differentiableWithinAt) hcw self_mem_nhdsWithin ?_
    have h1 : Tendsto (fun t => 1 - P t ^ 2) (𝓝[>] 0) (𝓝 1) := by
      simpa [h0] using (hcw.tendsto.pow 2).const_sub 1
    refine h1.congr' ?_
    filter_upwards [self_mem_nhdsWithin] with t ht
    exact (hd t ht).deriv.symm
  have := ODE_solution_unique_of_mem_Icc_right (v := fun _ y => 1 - y ^ 2)
    (s := fun _ => Metric.closedBall (0:ℝ) R) (fun _ _ => hLip)
    (hc.mono Icc_subset_Ici_self)
    (fun t ht => by
      rcases eq_or_lt_of_le ht.1 with h | h
      · subst h; simpa [h0] using hP0
      · exact (hd t h).hasDerivWithinAt)
    (fun t ht => by
      rw [Metric.mem_closedBall, dist_zero_right]
      exact (hC t (Ico_subset_Icc_self ht)).trans (le_max_left _ _))
    (fun t _ => (tanh_hasDerivAt t).continuousAt.continuousWithinAt)
    (fun t _ => (tanh_hasDerivAt t).hasDerivWithinAt)
    (fun t _ => by
      rw [Metric.mem_closedBall, dist_zero_right, Real.norm_eq_abs]
      exact (Real.abs_tanh_lt_one t).le.trans hR1)
    (by rw [h0, Real.tanh_zero])
  exact this ⟨hs, le_rfl⟩

-- The card's car starts 2 m/s too fast: the best cost is 2^2 = 4.
example : (2 : ℝ) ^ 2 = 4 := by norm_num
-- Best push at the start: u = -x₀ = -2.
example : -(1 : ℝ) * 2 = -2 := by norm_num
-- Step 2: at x = 2 with V_x = 4, the push u = -2 makes the HJB bracket zero.
example : (2 : ℝ) ^ 2 + (-2) ^ 2 + 4 * (-2) = 0 := by norm_num
-- The positive root of 1 - P^2 = 0 is P = 1.
example : (1 : ℝ) - 1 ^ 2 = 0 := by norm_num
-- Fixed gains from x₀ = 2, cost x₀^2 (1 + k^2) / (2k): gain 1 costs 4, gains 1/2 and 2 cost 5,
-- gain 1/4 costs 17/2 (the chart's 8.50).
example : (2 : ℚ) ^ 2 * (1 + 1 ^ 2) / (2 * 1) = 4 := by norm_num
example : (2 : ℚ) ^ 2 * (1 + (1 / 2) ^ 2) / (2 * (1 / 2)) = 5 := by norm_num
example : (2 : ℚ) ^ 2 * (1 + 2 ^ 2) / (2 * 2) = 5 := by norm_num
example : (2 : ℚ) ^ 2 * (1 + (1 / 4) ^ 2) / (2 * (1 / 4)) = 17 / 2 := by norm_num

#print axioms best_cost_is_square_and_best_push_is_minus_error
#print axioms hjb_quadratic_guess_gives_riccati
#print axioms riccati_with_deadline_solution_is_tanh
```

**Checked 2026-11-12 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'hjb_cost_identity' depends on axioms: [propext, Classical.choice, Quot.sound]
'tanh_hasDerivAt' depends on axioms: [propext, Classical.choice, Quot.sound]
'best_cost_is_square_and_best_push_is_minus_error' depends on axioms: [propext, Classical.choice, Quot.sound]
'hjb_quadratic_guess_gives_riccati' depends on axioms: [propext, Classical.choice, Quot.sound]
'riccati_with_deadline_solution_is_tanh' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **A bigger error.** Set `X0 = 3.0`. The cost becomes 9; the halving time stays 0.693 s. Every assert passes.
> - **Dearer pushing.** In `run`, make the cost rate `(1 + 4 * k * k) * x * x`. Now $P = 2$ and the best gain is 0.5; the scan reports 0.50, cost 8, and the first assert stops the run.
> - **Never push.** In `bellman`, replace `p / (1 + h * p)` with `p`. $P$ climbs to 40; the third assert stops the run.

---

## The usual mistake

> [!warning]
> **Solving for a path instead of a rule.** HJB gives the push as a function of the current error, $u = -x$. The schedule $u = -2e^{-t}$ matches it only if nothing disturbs the car; after a gust the schedule pushes as planned, while the rule reads the new error. The other slips are in the table under What breaks.

---

## Where you meet it in real life

- **Autopilots and cruise controllers.** The linear-quadratic regulator (LQR), this card's answer with matrices for numbers, sets feedback gains in aircraft, satellites and robots ([The LQR](../../13-Engineering%20mathematics/04-State%20Space%20and%20Optimal%20Control/06-linear-quadratic-regulator.md)).
- **Portfolio choice.** Merton's portfolio problem is HJB's best-known use in finance: wealth is the state, the share held in stocks is the control ([Merton's problem](../../12-Financial%20mathematics/38-Performance%20and%20Multi-Period/03-mertons-portfolio-problem.md)).
- **Grid solvers.** Where no quadratic guess works, HJB is solved on a grid of states, Step 5's recursion in more dimensions.

> **Say it back**
> The value function is the best cost from each state. Bellman's balance over a short step, to first order, is the HJB equation. Linear motion and squared costs make the value a square, and HJB a Riccati equation for its coefficient. For the car the best push is minus the error. A smooth solution of HJB is the true value, since no control makes it fall faster than cost is paid.

---

## What this builds on

- [Dynamic programming](07-dynamic-programming-and-the-bellman-equation.md): the stage-by-stage balance Step 1 shrinks to an instant.
- [Pontryagin's principle](06-pontryagins-principle-and-bang-bang-control.md): the path-by-path road whose costate is $V_x$.
- [Bernoulli and Riccati equations](../01-Rate%20Equations/09-bernoulli-and-riccati-substitutions.md): solving $dP/ds = 1 - P^2$.
- [Taylor series](../../06-Calculus%20and%20analysis/06-Series/05-taylor-series.md): the first-order expansion behind Step 1.

## Where this goes next

- [Stochastic control](../../11-Stochastic%20processes%20and%20calculus/09-Beyond%20Brownian/03-stochastic-control-and-the-hjb-equation.md): noise adds a second-derivative term; Feynman-Kac, a formula that writes the solution as an average over random paths, ties it to averages.
- [The LQR](../../13-Engineering%20mathematics/04-State%20Space%20and%20Optimal%20Control/06-linear-quadratic-regulator.md): many states, a matrix $P$, the matrix Riccati equation.
- The HJB equation, a planned card in the Partial differential equations wing: value functions with corners.
- [Merton's problem](../../12-Financial%20mathematics/38-Performance%20and%20Multi-Period/03-mertons-portfolio-problem.md): the stochastic HJB equation choosing a stock holding.

What the best rule becomes when chance jostles the motion is the question the stochastic-control card answers.

---

## Sources

Verified 2026-09-28: every link below resolves to the publisher's page.

- Bertsekas, Dimitri P. *Dynamic Programming and Optimal Control*. Athena Scientific. [Publisher page](http://www.athenasc.com/dpbook.html). HJB from the discrete Bellman equation.
- Kirk, Donald E. *Optimal Control Theory: An Introduction*. Dover. [Publisher page](https://store.doverpublications.com/products/9780486434841). HJB and the linear regulator, introductory.
- Anderson, Brian D. O., and John B. Moore. *Optimal Control: Linear Quadratic Methods*. Dover. [Publisher page](https://store.doverpublications.com/products/9780486457666). The Riccati equation and its positive root.
- Liberzon, Daniel. *Calculus of Variations and Optimal Control Theory: A Concise Introduction*. Princeton University Press, 2012. [Publisher page](https://press.princeton.edu/books/hardcover/9780691151878/calculus-of-variations-and-optimal-control-theory). HJB, Pontryagin and verification.
