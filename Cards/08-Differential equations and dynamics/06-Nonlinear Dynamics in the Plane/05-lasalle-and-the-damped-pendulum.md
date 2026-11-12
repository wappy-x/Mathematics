# LaSalle's principle: when the energy only pauses on a thin set, solutions still end where they can stay on it

[Syllabus](../../../SYLLABUS.md) → [Differential equations and dynamics](../README.md) → [Nonlinear Dynamics in the Plane](../README.md#s06) → LaSalle's principle

---

## General Overview

A playground swing hangs from rigid rods 1 m long. Pull the seat back to 60 degrees and let go. Air and the pivots drag on it, more at higher speed. It ends hanging straight down, yet the equation of motion has no formula solution to prove it.

Energy is the natural witness: drag only takes it, so it never rises. But at the release and each turnaround the seat is still for an instant, drag does nothing, and the energy pauses. The energy test of [Lyapunov functions](04-lyapunov-functions.md) needs the energy to fall at every moment away from rest, so it gives no verdict.

The way out: a pause is not a place to stay. At a turnaround gravity still pulls the seat off. Only hanging straight down is a still position gravity leaves alone. Joseph LaSalle made this a theorem in 1960: **LaSalle's principle**.

**A trapped motion whose energy never rises ends where a whole motion could stay inside the pause set; for the swing that is hanging at rest, so every swing with less energy than upside down settles there.**

**What kind of fact this is:** a theorem, proved on this card in Why it works, the limit argument in a folded proof.

### The picture: the swing in the angle-and-speed plane

<p align="center"><img src="../figures/lasalle-and-the-damped-pendulum.svg" alt="Phase plane of the damped swing, angle across and speed up. A shaded eye bounded by v = plus or minus 2 cos(theta/2) runs between the two upside-down points at minus pi and pi. The swing released at 60 degrees with zero speed spirals in to hanging at rest. A dashed line marks v = 0, where the energy&#x27;s rate is zero." width="420"></p>

To scale: 45 drawing units per radian and per unit of speed, centred on hanging at rest. The spiral is the swing every 0.25 time units to t = 12. The eye holds every state with less energy than upside down, the open circles.

### The picture: the energy only pauses

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Energy of the swing released from 60 degrees, c = 0.5"
    x-axis "Time t, in units of 0.3193 s" [0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5, 5.5, 6, 6.5, 7, 7.5, 8, 8.5, 9, 9.5, 10, 10.5, 11, 11.5, 12]
    y-axis "Energy V, in units of weight times rod length" 0 --> 0.5
    line [0.50, 0.49, 0.42, 0.31, 0.19, 0.12, 0.10, 0.09, 0.09, 0.07, 0.05, 0.03, 0.02, 0.02, 0.02, 0.02, 0.01, 0.01, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00]
```

The line is the energy V: steep while the seat is fast, flat near the turnarounds at t = 3.41 and 6.68, never rising.

---

## The formula

A prime means a rate, as across this wing: θ′ is how fast the angle changes, V′ how fast the energy does. From [The pendulum](03-the-nonlinear-pendulum.md), with drag added:

$$\theta'' + c\,\theta' + \sin\theta = 0, \qquad v = \theta'$$

**Read it aloud:** angular acceleration is minus the sine of the angle (gravity) minus c times the speed (drag).

Time runs in units of $\sqrt{l/g}$: rod length $l$ = 1 m, gravity $g$ = 9.81 m/s^2, so one unit is 0.3193 s.

$$V(\theta, v) = \tfrac12 v^2 + 1 - \cos\theta, \qquad V' = -c\,v^2$$

**Read it aloud:** energy is motion energy plus height energy, and it drains at c times the square of the speed.

$V$ is counted in units of the seat's weight times $l$: 0 hanging at rest, 2 upside down.

**LaSalle's principle.** Let $K$ be a closed, bounded region no motion leaves once inside, with $V' \le 0$ throughout. Let $Z$ be the points of $K$ where $V' = 0$, and $M$ the largest invariant set in $Z$: every state whose whole motion, past and future, stays in $Z$. Then

$$\text{every motion starting in } K \text{ approaches } M \text{ as } t \to \infty.$$

**Read it aloud:** a trapped motion whose energy never rises ends on the pause points it could stay on for ever.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $\theta$, $v$ | angle from straight down, in radians; angular speed | π/3 and 0 at release | past π, over the top |
| $t$, $l$, $g$ | time in units of √(l/g); rod length; gravity | 1 m, 9.81 m/s^2; unit 0.3193 s | longer rods, slower swings |
| $c$ | drag per unit of speed | 0.5 per time unit | faster settling; at 0, none |
| $V$, $V'$ | energy; its rate along the motion | 0.500 and 0.000 at release | above 2, the trap is lost |
| $K$ | the trap | angles within ±π, V ≤ 0.5 | same conclusion |
| $Z$, $M$ | where V′ = 0; the part a whole motion can stay on | line v = 0; point (0, 0) | a bigger M says less |
| $\lambda$ | Jacobian eigenvalues at a rest point | −0.250 ± 0.9682i at the bottom | positive: a saddle, one way in and one way out |

### When it holds

- **Drag c above 0.** At c = 0, Z is the whole trap, so M is too, and the swing turns at 60° for ever.
- **A closed, bounded trap.** Energy below 2 keeps the seat from upside down. Above 2 it may go over the top and settle in the next well, hanging down again 360° round.
- **V′ ≤ 0 on the whole trap; V and the rate law with continuous slopes.** Nearby starts then give nearby motions, as Step 3 needs.
- **The conclusion is a set.** It names one end point only when M is one point.

---

## Why it works

### Step 0: a pause is not a place to stay

Energy that never rises levels off, so the late swing loses almost none. Losing none for a while means staying on the pause line v = 0, and only hanging at rest can.

### Step 1: the energy drains at c times speed squared

By the chain rule:

$$V' = \sin\theta \cdot \theta' + v \cdot v' = \sin\theta \cdot v + v(-\sin\theta - c v) = -c\,v^2.$$

Gravity's terms cancel: climbing trades motion energy for height one for one. Drag's term is zero exactly when v = 0. At release V′ = 0, yet the acceleration is −sin 60° = −0.866: the swing leaves the pause line at once.

### Step 2: the energy builds the trap

V stays at most 0.5, so 1 − cos θ ≤ 0.5: the angle stays within 60°, the speed at most 1. Upside down needs V = 2. So K, angles within ±π with V ≤ 0.5, is a closed, bounded trap, and a motion held there runs for all time.

### Step 3: the late motion lives on the pause line, for ever

V falls and stays above 0, so it tends to a limit. The states the swing returns arbitrarily close to, later and later, form the **limit set**: not empty, since the trap is bounded, with V at its limit value throughout.

A motion started there copies the old one's late behaviour, so it stays there with V′ = 0: it lies in Z. So the limit set is inside M, and the swing approaches M.

<details>
<summary>Detailed proof: trapped motions approach M</summary>

Let x(t) be the motion from a start in K, and φ(s, p) the state at time s of the motion from p.

1. V(x(t)) never increases and is bounded below on K, so it tends to a limit ℓ.
2. Let Ω be the points p with x(tₙ) → p for some times tₙ → ∞. K is closed and bounded, so every sequence in it has a convergent subsequence: Ω is not empty and lies in K. By continuity V = ℓ on Ω.
3. If x(tₙ) → p, then for each real s, x(tₙ + s) = φ(s, x(tₙ)) → φ(s, p), since motions depend continuously on the start (the pendulum's slopes are bounded, so its motions run for all time, forward and back). So Ω is invariant.
4. V = ℓ along φ(s, p), so V′ = 0 there: the motion through p lies in Z. Hence Ω lies in M.
5. If x(t) stayed ε from M at times tₙ → ∞, a subsequence would converge to a point of Ω, which is in M: a contradiction.

</details>

### Step 4: only hanging at rest can stay on the pause line

A motion staying on v = 0 has θ′ = 0, so θ is constant, and v′ = −sin θ must be 0. Within ±π only θ = 0 works. So M is the point (0, 0): the swing approaches hanging at rest. With the stay-near half from [Lyapunov functions](04-lyapunov-functions.md), the bottom is **asymptotically stable**: nearby motions stay near and settle.

### Step 5: the eye is inside the basin

Only one fact about 60° was used: its energy is below 2. So every start within ±π below energy 2 ends at (0, 0). Since 1 + cos θ = 2 cos^2(θ/2), the edge V = 2 is v = ±2 cos(θ/2): the eye.

It lies inside the **basin**, the starts that end at rest, but is not all of it: a push of speed 3 from the bottom, energy 4.500, loses enough to drag on the way up to fall back.

A second road: linearise at (0, 0) ([Linearisation](02-linearisation-and-the-jacobian.md)). Trace −c and determinant 1 give λ^2 + 0.5λ + 1 = 0, so λ = −0.250 ± 0.9682i. That covers only starts near rest; LaSalle covers the eye.

---

## Worked numbers, by hand

| Step | Arithmetic | Value |
| --- | --- | --- |
| release energy | 1 − cos 60° | 0.500 |
| acceleration at release | −sin 60° | −0.866 |
| widest angle, fastest speed | 1 − cos θ = 0.5; √(2 × 0.5) | 60.00°; 1.000 |
| energy upside down | 1 − cos 180° | 2.000 |
| eigenvalues at the bottom | λ^2 + 0.5λ + 1 = 0 | −0.250 ± 0.9682i |
| late shrink per half swing | e^(−0.25 × π / 0.9682) | 0.4443 |
| where it ends | M is one point | **hanging at rest, (0, 0)** |

Turnarounds fall to 25.16°, 11.07°, 4.91°, 2.18°, 0.97°: under 1° from t = 16.42, which is 5.24 s.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| No drag, c = 0 | energy 0.500000 at t = 40, turning at 59.99° | M is the whole trap |
| The strict energy test | no verdict: V′ = 0.000 at release | V′ = 0 on all of v = 0 |
| Starting upside down | stays: eigenvalues 0.781 and −1.281 | a saddle on the eye's edge |
| Eye taken as the basin | energy 4.500 settles in well 0; 6.125 in well 1 | the eye is enough, not everything |

The code prints all four.

---

## Code, from first principles, and it actually runs

Only `math` is imported. Road one steps the swing by Runge-Kutta 4 (four slope samples per step, weighted 1, 2, 2, 1; its card is [Runge-Kutta four](../05-Numerical%20Evolution/04-runge-kutta-four.md)). Road two checks without stepping. Energy lost must equal c times the integral of v^2, by Simpson's rule, which fits a parabola through each three samples ([Numerical integration](../../06-Calculus%20and%20analysis/04-Integrals/08-numerical-integration.md)). The gap shrinks sixteenfold as the step halves. Late half swings must shrink by the eigenvalue factor. A bisection finds the widest angle.

### Python

```python
# LaSalle and the damped swing -- the check behind the card.  Only math is
# imported.  theta'' + c theta' + sin(theta) = 0, time in units of sqrt(l/g).
# Road one steps the swing by Runge-Kutta 4 and records where it ends.  Road
# two books the energy lost against c times the integral of v^2 (Simpson),
# and the late swings against the eigenvalues of the swing near the bottom.
from math import sin, cos, sqrt, pi, exp
C, TH0, T, DEG, UNIT = 0.5, pi / 3, 40.0, 180 / pi, sqrt(1 / 9.81)

def f(th, v, c): return v, -sin(th) - c * v
def energy(th, v): return 0.5 * v * v + 1 - cos(th)

def run(th, v, c, h):                    # RK4 steps; a turnaround is where v flips sign
    out, turns = [(th, v)], []
    for k in range(round(T / h)):
        a1, b1 = f(th, v, c); a2, b2 = f(th + h/2*a1, v + h/2*b1, c)
        a3, b3 = f(th + h/2*a2, v + h/2*b2, c); a4, b4 = f(th + h*a3, v + h*b3, c)
        t2, v2 = th + h/6*(a1 + 2*a2 + 2*a3 + a4), v + h/6*(b1 + 2*b2 + 2*b3 + b4)
        if v * v2 < 0: turns.append((k*h + h*v/(v - v2), th + (t2 - th)*v/(v - v2)))
        th, v = t2, v2; out.append((th, v))
    return out, turns

def lost(out, c, h):                     # c times the integral of v^2, by Simpson's rule
    w = [1] + [4 if i % 2 else 2 for i in range(1, len(out) - 1)] + [1]
    return c * h / 3 * sum(wi * v * v for wi, (_, v) in zip(w, out))

def widest(e):                           # bisection: the angle where 1 - cos(theta) = e
    lo, hi = 0.0, pi
    for _ in range(60):
        m = (lo + hi) / 2
        lo, hi = (m, hi) if 1 - cos(m) < e else (lo, m)
    return lo

E0 = energy(TH0, 0.0)
print(f"time unit {UNIT:.4f} s; release: V0 = {E0:.3f}, V' = {sin(TH0) * 0.0 + 0.0 * f(TH0, 0.0, C)[1]:.3f}, v' = {f(TH0, 0.0, C)[1]:.3f}")
print(f"trap: |theta| <= {widest(E0) * DEG:.2f} deg, |v| <= {sqrt(2 * E0):.3f}, top V(pi, 0) = {energy(pi, 0.0):.3f}")
w, s = sqrt(4 - C * C) / 2, sqrt(C * C + 4)          # bottom: trace -c, det 1; top: det -1
print(f"eigenvalues: bottom {-C / 2:.3f} +- {w:.4f}i, top {(-C + s) / 2:.3f} and {(-C - s) / 2:.3f}")
out, turns = run(TH0, 0.0, C, 0.05)
print("turnarounds (t, deg): " + ", ".join(f"({t:.2f}, {a * DEG:.2f})" for t, a in turns[:5]))
ratios = [abs(turns[i + 1][1] / turns[i][1]) for i in range(len(turns) - 1)]
pred = exp(-C / 2 * pi / w)              # linear swing: each half swing shrinks by this
print(f"half-swing ratio: first {abs(turns[0][1] / TH0):.4f}, 6th {ratios[5]:.4f}, from eigenvalues {pred:.4f}")
first = next(t for t, a in turns if abs(a) * DEG < 1)
print(f"turnarounds under 1 deg from t = {first:.2f}, which is {first * UNIT:.2f} s")
print(f"at t = 40: theta = {out[-1][0]:.6f}, v = {out[-1][1]:.6f}, widest ever {max(abs(a) for a, _ in out) * DEG:.2f} deg")
d = [E0 - energy(*o[-1]) - lost(o, C, h) for h in (0.1, 0.05) for o in [run(TH0, 0.0, C, h)[0]]]
print(f"V0 - V(40) = {E0 - energy(*out[-1]):.6f}; c * integral of v^2 = {lost(out, C, 0.05):.6f}")
print(f"bookkeeping gap in millionths: h = 0.1 {d[0] * 1e6:.3f}, h = 0.05 {d[1] * 1e6:.3f}, ratio {d[0] / d[1]:.1f}")
print("chart, V at t = 0, 0.5, ..., 12: " + ", ".join(f"{energy(*p):.2f}" for p in out[:241:10]))
print("figure, spiral x = 180 + 45 theta, y = 120 - 45 v: " + " ".join(f"{180 + 45 * a:.1f},{120 - 45 * b:.1f}" for a, b in out[:241:5]))
print("figure, eye edge v = 2 cos(theta/2), theta = -pi..pi by pi/8: " + " ".join(f"{2 * cos(k * pi / 16):.2f}" for k in range(-8, 9)))
free, free_turns = run(TH0, 0.0, 0.0, 0.05)
print(f"c = 0: V(40) = {energy(*free[-1]):.6f}, last turnaround {abs(free_turns[-1][1]) * DEG:.2f} deg")
ends = {v0: run(0.0, v0, C, 0.05)[0][-1][0] for v0 in (3.0, 3.5)}
print("push from the bottom: " + ", ".join(f"v0 = {v0:.1f} (V0 = {energy(0.0, v0):.3f}) ends in well {round(e / (2 * pi))}" for v0, e in ends.items()))
assert abs(d[1]) < 1e-6 and 12 < d[0] / d[1] < 20       # energy book balances, at RK4's order
assert abs(ratios[5] / pred - 1) < 0.01                  # late swings obey the eigenvalues
assert abs(out[-1][0]) < 1e-3 and abs(out[-1][1]) < 1e-3 and max(abs(a) for a, _ in out) <= widest(E0) + 1e-9
assert abs(energy(*free[-1]) - E0) < 1e-6 and abs(ends[3.5] - 2 * pi) < 1e-3
print("ALL CHECKS PASS")
```

**Ran 2026-09-28 on macOS, Python 3.14.6, standard library only. All checks passed. Output, pasted from the run:**

```
time unit 0.3193 s; release: V0 = 0.500, V' = 0.000, v' = -0.866
trap: |theta| <= 60.00 deg, |v| <= 1.000, top V(pi, 0) = 2.000
eigenvalues: bottom -0.250 +- 0.9682i, top 0.781 and -1.281
turnarounds (t, deg): (3.41, -25.16), (6.68, 11.07), (9.93, -4.91), (13.18, 2.18), (16.42, -0.97)
half-swing ratio: first 0.4193, 6th 0.4444, from eigenvalues 0.4443
turnarounds under 1 deg from t = 16.42, which is 5.24 s
at t = 40: theta = 0.000040, v = -0.000036, widest ever 60.00 deg
V0 - V(40) = 0.500000; c * integral of v^2 = 0.500000
bookkeeping gap in millionths: h = 0.1 -1.961, h = 0.05 -0.123, ratio 16.0
chart, V at t = 0, 0.5, ..., 12: 0.50, 0.49, 0.42, 0.31, 0.19, 0.12, 0.10, 0.09, 0.09, 0.07, 0.05, 0.03, 0.02, 0.02, 0.02, 0.02, 0.01, 0.01, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00
figure, spiral x = 180 + 45 theta, y = 120 - 45 v: 227.1,120.0 226.0,129.1 222.7,136.9 217.6,143.1 211.3,147.7 203.9,150.6 196.1,151.5 188.3,150.6 181.0,148.1 174.4,144.2 168.9,139.4 164.8,134.0 162.0,128.5 160.5,123.2 160.3,118.3 161.3,114.1 163.2,110.8 165.8,108.3 169.0,106.7 172.4,106.1 175.8,106.4 179.1,107.4 182.1,109.0 184.6,111.1 186.5,113.5 187.8,115.9 188.5,118.3 188.7,120.6 188.3,122.5 187.5,124.0 186.3,125.2 184.9,125.9 183.4,126.2 181.9,126.1 180.4,125.6 179.1,124.9 178.0,124.0 177.1,122.9 176.5,121.8 176.2,120.7 176.2,119.8 176.3,118.9 176.7,118.2 177.2,117.7 177.8,117.4 178.5,117.3 179.2,117.3 179.8,117.5 180.4,117.8
figure, eye edge v = 2 cos(theta/2), theta = -pi..pi by pi/8: 0.00 0.39 0.77 1.11 1.41 1.66 1.85 1.96 2.00 1.96 1.85 1.66 1.41 1.11 0.77 0.39 0.00
c = 0: V(40) = 0.500000, last turnaround 59.99 deg
push from the bottom: v0 = 3.0 (V0 = 4.500) ends in well 0, v0 = 3.5 (V0 = 6.125) ends in well 1
ALL CHECKS PASS
```

### Rust

Same numbers, same labels.

```rust
// LaSalle and the damped swing -- the same check as the Python, in Rust.  No
// crates.  theta'' + c theta' + sin(theta) = 0, time in units of sqrt(l/g).
// Road one steps the swing by Runge-Kutta 4 and records where it ends.  Road
// two books the energy lost against c times the integral of v^2 (Simpson),
// and the late swings against the eigenvalues of the swing near the bottom.
use std::f64::consts::PI;
const C: f64 = 0.5;
const TH0: f64 = PI / 3.0;
const T: f64 = 40.0;
const DEG: f64 = 180.0 / PI;
fn f(th: f64, v: f64, c: f64) -> (f64, f64) { (v, -th.sin() - c * v) }
fn energy(p: (f64, f64)) -> f64 { 0.5 * p.1 * p.1 + 1.0 - p.0.cos() }
type Run = (Vec<(f64, f64)>, Vec<(f64, f64)>);
fn run(mut th: f64, mut v: f64, c: f64, h: f64) -> Run {  // RK4; a turnaround is where v flips sign
    let (mut out, mut turns) = (vec![(th, v)], Vec::new());
    for k in 0..(T / h).round() as usize {
        let (a1, b1) = f(th, v, c);
        let (a2, b2) = f(th + h / 2.0 * a1, v + h / 2.0 * b1, c);
        let (a3, b3) = f(th + h / 2.0 * a2, v + h / 2.0 * b2, c);
        let (a4, b4) = f(th + h * a3, v + h * b3, c);
        let t2 = th + h / 6.0 * (a1 + 2.0 * a2 + 2.0 * a3 + a4);
        let v2 = v + h / 6.0 * (b1 + 2.0 * b2 + 2.0 * b3 + b4);
        if v * v2 < 0.0 { turns.push((k as f64 * h + h * v / (v - v2), th + (t2 - th) * v / (v - v2))); }
        th = t2; v = v2; out.push((th, v));
    }
    (out, turns)
}
fn lost(out: &[(f64, f64)], c: f64, h: f64) -> f64 {     // c times the integral of v^2, Simpson
    let n = out.len() - 1;
    let s: f64 = out.iter().enumerate()
        .map(|(i, p)| (if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * p.1 * p.1).sum();
    c * h / 3.0 * s
}
fn widest(e: f64) -> f64 {                                 // bisection: 1 - cos(theta) = e
    let (mut lo, mut hi) = (0.0f64, PI);
    for _ in 0..60 { let m = (lo + hi) / 2.0; if 1.0 - m.cos() < e { lo = m } else { hi = m } }
    lo
}
fn join(v: Vec<String>, sep: &str) -> String { v.join(sep) }
fn main() {
    let (e0, unit) = (energy((TH0, 0.0)), (1.0f64 / 9.81).sqrt());
    println!("time unit {:.4} s; release: V0 = {:.3}, V' = {:.3}, v' = {:.3}", unit, e0, TH0.sin() * 0.0 + 0.0 * f(TH0, 0.0, C).1, f(TH0, 0.0, C).1);
    println!("trap: |theta| <= {:.2} deg, |v| <= {:.3}, top V(pi, 0) = {:.3}", widest(e0) * DEG, (2.0 * e0).sqrt(), energy((PI, 0.0)));
    let (w, s) = ((4.0 - C * C).sqrt() / 2.0, (C * C + 4.0).sqrt());  // bottom: det 1; top: det -1
    println!("eigenvalues: bottom {:.3} +- {:.4}i, top {:.3} and {:.3}", -C / 2.0, w, (-C + s) / 2.0, (-C - s) / 2.0);
    let (out, turns) = run(TH0, 0.0, C, 0.05);
    println!("turnarounds (t, deg): {}", join(turns[..5].iter().map(|(t, a)| format!("({:.2}, {:.2})", t, a * DEG)).collect(), ", "));
    let ratios: Vec<f64> = (0..turns.len() - 1).map(|i| (turns[i + 1].1 / turns[i].1).abs()).collect();
    let pred = (-C / 2.0 * PI / w).exp();                  // linear swing: shrink per half swing
    println!("half-swing ratio: first {:.4}, 6th {:.4}, from eigenvalues {:.4}", (turns[0].1 / TH0).abs(), ratios[5], pred);
    let first = turns.iter().find(|(_, a)| a.abs() * DEG < 1.0).unwrap().0;
    println!("turnarounds under 1 deg from t = {:.2}, which is {:.2} s", first, first * unit);
    let end = out[out.len() - 1];
    let widest_seen = out.iter().map(|p| p.0.abs()).fold(0.0, f64::max);
    println!("at t = 40: theta = {:.6}, v = {:.6}, widest ever {:.2} deg", end.0, end.1, widest_seen * DEG);
    let d: Vec<f64> = [0.1, 0.05].iter().map(|&h| { let o = run(TH0, 0.0, C, h).0; e0 - energy(o[o.len() - 1]) - lost(&o, C, h) }).collect();
    println!("V0 - V(40) = {:.6}; c * integral of v^2 = {:.6}", e0 - energy(end), lost(&out, C, 0.05));
    println!("bookkeeping gap in millionths: h = 0.1 {:.3}, h = 0.05 {:.3}, ratio {:.1}", d[0] * 1e6, d[1] * 1e6, d[0] / d[1]);
    println!("chart, V at t = 0, 0.5, ..., 12: {}", join(out[..241].iter().step_by(10).map(|&p| format!("{:.2}", energy(p))).collect(), ", "));
    let fg = out[..241].iter().step_by(5).map(|p| format!("{:.1},{:.1}", 180.0 + 45.0 * p.0, 120.0 - 45.0 * p.1)).collect();
    println!("figure, spiral x = 180 + 45 theta, y = 120 - 45 v: {}", join(fg, " "));
    let eye = (-8..=8).map(|k| format!("{:.2}", 2.0 * (k as f64 * PI / 16.0).cos())).collect();
    println!("figure, eye edge v = 2 cos(theta/2), theta = -pi..pi by pi/8: {}", join(eye, " "));
    let (free, free_turns) = run(TH0, 0.0, 0.0, 0.05);
    let fend = free[free.len() - 1];
    println!("c = 0: V(40) = {:.6}, last turnaround {:.2} deg", energy(fend), free_turns[free_turns.len() - 1].1.abs() * DEG);
    let ends: Vec<f64> = [3.0, 3.5].iter().map(|&v0| { let o = run(0.0, v0, C, 0.05).0; o[o.len() - 1].0 }).collect();
    let pl = [3.0f64, 3.5].iter().zip(&ends).map(|(v0, e)| format!("v0 = {:.1} (V0 = {:.3}) ends in well {}", v0, energy((0.0, *v0)), (e / (2.0 * PI)).round() as i64)).collect();
    println!("push from the bottom: {}", join(pl, ", "));
    assert!(d[1].abs() < 1e-6 && 12.0 < d[0] / d[1] && d[0] / d[1] < 20.0);   // book balances, RK4 order
    assert!((ratios[5] / pred - 1.0).abs() < 0.01);                          // late swings obey eigenvalues
    assert!(end.0.abs() < 1e-3 && end.1.abs() < 1e-3 && widest_seen <= widest(e0) + 1e-9);
    assert!((energy(fend) - e0).abs() < 1e-6 && (ends[1] - 2.0 * PI).abs() < 1e-3);
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-09-28 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
time unit 0.3193 s; release: V0 = 0.500, V' = 0.000, v' = -0.866
trap: |theta| <= 60.00 deg, |v| <= 1.000, top V(pi, 0) = 2.000
eigenvalues: bottom -0.250 +- 0.9682i, top 0.781 and -1.281
turnarounds (t, deg): (3.41, -25.16), (6.68, 11.07), (9.93, -4.91), (13.18, 2.18), (16.42, -0.97)
half-swing ratio: first 0.4193, 6th 0.4444, from eigenvalues 0.4443
turnarounds under 1 deg from t = 16.42, which is 5.24 s
at t = 40: theta = 0.000040, v = -0.000036, widest ever 60.00 deg
V0 - V(40) = 0.500000; c * integral of v^2 = 0.500000
bookkeeping gap in millionths: h = 0.1 -1.961, h = 0.05 -0.123, ratio 16.0
chart, V at t = 0, 0.5, ..., 12: 0.50, 0.49, 0.42, 0.31, 0.19, 0.12, 0.10, 0.09, 0.09, 0.07, 0.05, 0.03, 0.02, 0.02, 0.02, 0.02, 0.01, 0.01, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00
figure, spiral x = 180 + 45 theta, y = 120 - 45 v: 227.1,120.0 226.0,129.1 222.7,136.9 217.6,143.1 211.3,147.7 203.9,150.6 196.1,151.5 188.3,150.6 181.0,148.1 174.4,144.2 168.9,139.4 164.8,134.0 162.0,128.5 160.5,123.2 160.3,118.3 161.3,114.1 163.2,110.8 165.8,108.3 169.0,106.7 172.4,106.1 175.8,106.4 179.1,107.4 182.1,109.0 184.6,111.1 186.5,113.5 187.8,115.9 188.5,118.3 188.7,120.6 188.3,122.5 187.5,124.0 186.3,125.2 184.9,125.9 183.4,126.2 181.9,126.1 180.4,125.6 179.1,124.9 178.0,124.0 177.1,122.9 176.5,121.8 176.2,120.7 176.2,119.8 176.3,118.9 176.7,118.2 177.2,117.7 177.8,117.4 178.5,117.3 179.2,117.3 179.8,117.5 180.4,117.8
figure, eye edge v = 2 cos(theta/2), theta = -pi..pi by pi/8: 0.00 0.39 0.77 1.11 1.41 1.66 1.85 1.96 2.00 1.96 1.85 1.66 1.41 1.11 0.77 0.39 0.00
c = 0: V(40) = 0.500000, last turnaround 59.99 deg
push from the bottom: v0 = 3.0 (V0 = 4.500) ends in well 0, v0 = 3.5 (V0 = 6.125) ends in well 1
ALL CHECKS PASS
```

The two outputs match line for line.

### Lean

Lean proves LaSalle's principle for every closed, bounded trap, and that every swing with drag below the energy of upside down ends at rest.

- LaSalle's principle, as The formula states it. Take a rate law and an energy V with continuous slopes, and a closed, bounded trap K with V′ ≤ 0 on it. Every motion starting in K approaches M, the states whose whole motion stays in Z.
- Step 1 holds for every drag c: along the swing, the energy drains at V′ = −c v^2.
- Step 5 holds for every drag c above 0. Every motion of the swing that starts within ±π with energy below 2 has angle and speed tending to 0: it ends hanging at rest.
- The hand numbers hold exactly: release energy 0.500, 2.000 upside down, pushes of 3 and 3.5 with energies 4.500 and 6.125, fastest speed 1.000.

Eigenvalues, turnarounds, settling times, the energy bookkeeping, the figure, the chart and where the pushes end are left to the Python and Rust checks.

```lean
-- LaSalle's principle: a motion trapped in a closed, bounded region where the energy never rises approaches the largest set of states whose whole motion stays where the energy rate is zero, so the damped swing started below the energy of upside down settles to hanging at rest.
import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.Calculus.FDeriv.Basic
import Mathlib.Analysis.Normed.Module.FiniteDimension
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Topology.NhdsSet
import Mathlib.Analysis.ODE.Gronwall
import Mathlib.Analysis.Calculus.ContDiff.RCLike
import Mathlib.Analysis.Calculus.UniformLimitsDeriv
import Mathlib.Analysis.Calculus.Deriv.Shift
import Mathlib.Topology.Order.MonotoneConvergence
import Mathlib.Analysis.Calculus.Deriv.MeanValue

open Filter Topology Set

/-- Two-sided Gronwall estimate for two exact solutions of `y' = f y` that stay in a set where
`f` is Lipschitz. -/
lemma lasalle_gronwall_two_sided {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (f : E → E) (K : Set E) (L : NNReal) (hL : LipschitzOnWith L f K)
    (u w : ℝ → E) (c S : ℝ)
    (hu : ∀ t ∈ Icc (c - S) (c + S), HasDerivAt u (f (u t)) t)
    (hw : ∀ t ∈ Icc (c - S) (c + S), HasDerivAt w (f (w t)) t)
    (huK : ∀ t ∈ Icc (c - S) (c + S), u t ∈ K) (hwK : ∀ t ∈ Icc (c - S) (c + S), w t ∈ K) :
    ∀ t ∈ Icc (c - S) (c + S), dist (u t) (w t) ≤ dist (u c) (w c) * Real.exp (L * S) := by
  intro t ht
  have hd0 : 0 ≤ dist (u c) (w c) := dist_nonneg
  rcases le_total c t with hct | htc
  · -- forward in time
    have hsub : Icc c (c + S) ⊆ Icc (c - S) (c + S) := Icc_subset_Icc (by linarith [ht.1, ht.2]) le_rfl
    have key := dist_le_of_trajectories_ODE_of_mem (v := fun _ => f) (s := fun _ => K)
      (a := c) (b := c + S) (K := L) (δ := dist (u c) (w c)) (fun _ _ => hL)
      (fun s hs => (hu s (hsub hs)).continuousAt.continuousWithinAt)
      (fun s hs => (hu s (hsub (Ico_subset_Icc_self hs))).hasDerivWithinAt)
      (fun s hs => huK s (hsub (Ico_subset_Icc_self hs)))
      (fun s hs => (hw s (hsub hs)).continuousAt.continuousWithinAt)
      (fun s hs => (hw s (hsub (Ico_subset_Icc_self hs))).hasDerivWithinAt)
      (fun s hs => hwK s (hsub (Ico_subset_Icc_self hs))) le_rfl t ⟨hct, ht.2⟩
    refine key.trans (mul_le_mul_of_nonneg_left (Real.exp_le_exp.2 ?_) hd0)
    exact mul_le_mul_of_nonneg_left (by linarith [ht.2]) L.2
  · -- backward in time: reverse the clock
    have hmem : ∀ τ ∈ Icc 0 S, c - τ ∈ Icc (c - S) (c + S) := fun τ hτ =>
      ⟨by linarith [hτ.2], by linarith [hτ.1, ht.1, ht.2]⟩
    have hLn : LipschitzOnWith L (fun y => -f y) K := by
      refine LipschitzOnWith.of_dist_le_mul fun a ha b hb => ?_
      rw [dist_neg_neg]; exact hL.dist_le_mul a ha b hb
    have hu' : ∀ τ ∈ Icc 0 S, HasDerivAt (fun τ => u (c - τ)) (-f (u (c - τ))) τ :=
      fun τ hτ => HasDerivAt.comp_const_sub c τ (hu _ (hmem τ hτ))
    have hw' : ∀ τ ∈ Icc 0 S, HasDerivAt (fun τ => w (c - τ)) (-f (w (c - τ))) τ :=
      fun τ hτ => HasDerivAt.comp_const_sub c τ (hw _ (hmem τ hτ))
    have key := dist_le_of_trajectories_ODE_of_mem (v := fun _ y => -f y) (s := fun _ => K)
      (f := fun τ => u (c - τ)) (g := fun τ => w (c - τ))
      (a := 0) (b := S) (K := L) (δ := dist (u c) (w c)) (fun _ _ => hLn)
      (fun s hs => (hu' s hs).continuousAt.continuousWithinAt)
      (fun s hs => (hu' s (Ico_subset_Icc_self hs)).hasDerivWithinAt)
      (fun s hs => huK _ (hmem s (Ico_subset_Icc_self hs)))
      (fun s hs => (hw' s hs).continuousAt.continuousWithinAt)
      (fun s hs => (hw' s (Ico_subset_Icc_self hs)).hasDerivWithinAt)
      (fun s hs => hwK _ (hmem s (Ico_subset_Icc_self hs))) (by simp) (c - t)
      ⟨by linarith, by linarith [ht.1]⟩
    simp only [sub_sub_cancel, sub_zero] at key
    refine key.trans (mul_le_mul_of_nonneg_left (Real.exp_le_exp.2 ?_) hd0)
    exact mul_le_mul_of_nonneg_left (by linarith [ht.1]) L.2

#print axioms lasalle_gronwall_two_sided

/-- A limit point of a trapped motion, along times going to infinity, lies on a whole motion
that stays in the trap and on which the energy rate is zero. -/
lemma lasalle_limit_point {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    [FiniteDimensional ℝ E]
    (f : E → E) (V : E → ℝ) (hV : ContDiff ℝ 1 V)
    (K : Set E) (hKc : IsClosed K) (L : NNReal) (hL : LipschitzOnWith L f K)
    (x : ℝ → E) (hxd : ∀ t, 0 < t → HasDerivAt x (f (x t)) t) (hxK : ∀ t, 0 ≤ t → x t ∈ K)
    (ℓ : ℝ) (hℓ : Tendsto (fun t => V (x t)) atTop (𝓝 ℓ))
    (τ : ℕ → ℝ) (hτ : Tendsto τ atTop atTop) (p : E)
    (hp : Tendsto (fun n => x (τ n)) atTop (𝓝 p)) :
    ∃ γ : ℝ → E, γ 0 = p ∧ (∀ t, HasDerivAt γ (f (γ t)) t) ∧
      ∀ t, γ t ∈ K ∧ fderiv ℝ V (γ t) (f (γ t)) = 0 := by
  have : CompleteSpace E := FiniteDimensional.complete ℝ E
  -- the shifted motions stay close to each other
  have hB : ∀ S : ℝ, ∀ n m, S < τ n → S < τ m → ∀ s ∈ Icc (-S) S,
      dist (x (τ n + s)) (x (τ m + s)) ≤ dist (x (τ n)) (x (τ m)) * Real.exp (L * S) := by
    intro S n m hn hm s hs
    have h := lasalle_gronwall_two_sided f K L hL (fun r => x (τ n + r)) (fun r => x (τ m + r))
      0 S
      (fun r hr => HasDerivAt.comp_const_add (τ n) r (hxd _ (by linarith [hr.1])))
      (fun r hr => HasDerivAt.comp_const_add (τ m) r (hxd _ (by linarith [hr.1])))
      (fun r hr => hxK _ (by linarith [hr.1]))
      (fun r hr => hxK _ (by linarith [hr.1])) s (by simpa using hs)
    simpa using h
  have hcauchy : ∀ s, CauchySeq (fun n => x (τ n + s)) := by
    intro s
    rw [Metric.cauchySeq_iff]
    intro ε hε
    have hexp : 0 < Real.exp (L * |s|) := Real.exp_pos _
    obtain ⟨N1, hN1⟩ := Metric.cauchySeq_iff.1 hp.cauchySeq (ε / Real.exp (L * |s|))
      (div_pos hε hexp)
    obtain ⟨N2, hN2⟩ := eventually_atTop.1 (hτ.eventually_gt_atTop |s|)
    refine ⟨max N1 N2, fun m hm n hn => ?_⟩
    have h := hB |s| m n (hN2 m (le_of_max_le_right hm)) (hN2 n (le_of_max_le_right hn)) s
      ⟨neg_abs_le s, le_abs_self s⟩
    have h2 := hN1 m (le_of_max_le_left hm) n (le_of_max_le_left hn)
    calc dist (x (τ m + s)) (x (τ n + s)) ≤ dist (x (τ m)) (x (τ n)) * Real.exp (L * |s|) := h
      _ < ε / Real.exp (L * |s|) * Real.exp (L * |s|) := mul_lt_mul_of_pos_right h2 hexp
      _ = ε := div_mul_cancel₀ ε hexp.ne'
  choose γ hγlim using fun s => cauchySeq_tendsto_of_complete (hcauchy s)
  have hγ0 : γ 0 = p := tendsto_nhds_unique (by simpa using hγlim 0) hp
  have hγK : ∀ s, γ s ∈ K := fun s =>
    hKc.mem_of_tendsto (hγlim s)
      ((hτ.eventually_ge_atTop (-s)).mono fun n hn => hxK _ (by linarith))
  -- uniform bound on the distance to the limit motion
  have hU : ∀ S : ℝ, ∀ n, S < τ n → ∀ s ∈ Icc (-S) S,
      dist (x (τ n + s)) (γ s) ≤ dist (x (τ n)) p * Real.exp (L * S) := by
    intro S n hn s hs
    refine le_of_tendsto_of_tendsto (tendsto_const_nhds.dist (hγlim s))
      ((tendsto_const_nhds.dist hp).mul_const _) ?_
    exact (hτ.eventually_gt_atTop S).mono fun m hm => hB S n m hn hm s hs
  -- the limit motion solves the rate law
  have hγd : ∀ s, HasDerivAt γ (f (γ s)) s := by
    intro s0
    set S : ℝ := |s0| + 1 with hS
    have hs0 : s0 ∈ Ioo (-S) S := ⟨by linarith [neg_abs_le s0], by linarith [le_abs_self s0]⟩
    refine hasDerivAt_of_tendstoUniformlyOn (l := atTop) (f := fun n r => x (τ n + r))
      (f' := fun n r => f (x (τ n + r))) (g := γ) (g' := fun r => f (γ r)) isOpen_Ioo ?_ ?_
      (fun r _ => hγlim r) hs0
    · rw [Metric.tendstoUniformlyOn_iff]
      intro ε hε
      have hexp : 0 < Real.exp (L * S) := Real.exp_pos _
      have hC : 0 < ((L : ℝ) + 1) * Real.exp (L * S) := by positivity
      have hp' : ∀ᶠ n in atTop, dist (x (τ n)) p < ε / (((L : ℝ) + 1) * Real.exp (L * S)) :=
        (Metric.tendsto_nhds.1 hp) _ (div_pos hε hC)
      filter_upwards [hp', hτ.eventually_gt_atTop S] with n hn hnS r hr
      have h1 := hU S n hnS r (Ioo_subset_Icc_self hr)
      have h2 : dist (f (γ r)) (f (x (τ n + r))) ≤ L * dist (γ r) (x (τ n + r)) :=
        hL.dist_le_mul _ (hγK r) _ (hxK _ (by linarith [hr.1]))
      rw [dist_comm (γ r)] at h2
      have hL0 : (0 : ℝ) ≤ L := L.2
      have hd0 : 0 ≤ dist (x (τ n + r)) (γ r) := dist_nonneg
      have h3 : dist (x (τ n)) p * (((L : ℝ) + 1) * Real.exp (L * S)) < ε := by
        rwa [lt_div_iff₀ hC] at hn
      calc dist (f (γ r)) (f (x (τ n + r))) ≤ L * dist (x (τ n + r)) (γ r) := h2
        _ ≤ ((L : ℝ) + 1) * dist (x (τ n + r)) (γ r) := by nlinarith
        _ ≤ ((L : ℝ) + 1) * (dist (x (τ n)) p * Real.exp (L * S)) :=
            mul_le_mul_of_nonneg_left h1 (by positivity)
        _ = dist (x (τ n)) p * (((L : ℝ) + 1) * Real.exp (L * S)) := by ring
        _ < ε := h3
    · filter_upwards [hτ.eventually_gt_atTop S] with n hn r hr
      exact HasDerivAt.comp_const_add (τ n) r (hxd _ (by linarith [hr.1]))
  -- the energy is constant along the limit motion, so its rate is zero
  have hVγ : ∀ s, V (γ s) = ℓ := fun s =>
    tendsto_nhds_unique ((hV.continuous.tendsto _).comp (hγlim s))
      (hℓ.comp (tendsto_atTop_add_const_right _ s hτ))
  refine ⟨γ, hγ0, hγd, fun s => ⟨hγK s, ?_⟩⟩
  have h1 : HasDerivAt (fun r => V (γ r)) (fderiv ℝ V (γ s) (f (γ s))) s :=
    ((hV.differentiable one_ne_zero) (γ s)).hasFDerivAt.comp_hasDerivAt s (hγd s)
  have h2 : HasDerivAt (fun r => V (γ r)) 0 s := by
    have : (fun r => V (γ r)) = fun _ => ℓ := funext hVγ
    rw [this]; exact hasDerivAt_const s ℓ
  exact h1.unique h2

#print axioms lasalle_limit_point

/-- The energy rate along the damped swing (used by Step 1 and Step 5). -/
lemma damped_energy_rate_aux (c : ℝ) (θ v : ℝ → ℝ) (t : ℝ)
    (hθ : HasDerivAt θ (v t) t) (hv : HasDerivAt v (-Real.sin (θ t) - c * v t) t) :
    HasDerivAt (fun s => v s ^ 2 / 2 + 1 - Real.cos (θ s)) (-c * v t ^ 2) t := by
  have h := (((hv.pow 2).div_const 2).add_const 1).sub hθ.cos
  convert h using 1
  push_cast
  ring

#print axioms damped_energy_rate_aux

/-- The energy rate of the damped swing as a derivative of the energy on the plane. -/
lemma damped_energy_fderiv (c : ℝ) (y : ℝ × ℝ) :
    fderiv ℝ (fun p : ℝ × ℝ => p.2 ^ 2 / 2 + 1 - Real.cos p.1) y
      (y.2, -Real.sin y.1 - c * y.2) = -c * y.2 ^ 2 := by
  have hW : DifferentiableAt ℝ (fun p : ℝ × ℝ => p.2 ^ 2 / 2 + 1 - Real.cos p.1) y := by
    fun_prop
  have hl : HasDerivAt (fun s : ℝ => y + s • ((y.2, -Real.sin y.1 - c * y.2) : ℝ × ℝ))
      (y.2, -Real.sin y.1 - c * y.2) 0 := by
    have := ((hasDerivAt_id (0 : ℝ)).smul_const
      ((y.2, -Real.sin y.1 - c * y.2) : ℝ × ℝ)).const_add y
    simp only [id, one_smul] at this
    exact this
  have h1 := hW.hasFDerivAt.comp_hasDerivAt_of_eq 0 hl (by rw [zero_smul, add_zero])
  have hθ : HasDerivAt (fun s : ℝ => y.1 + s * y.2)
      ((fun s : ℝ => y.2 + s * (-Real.sin y.1 - c * y.2)) 0) 0 := by
    have := ((hasDerivAt_id (0 : ℝ)).mul_const y.2).const_add y.1
    simp only [id, one_mul] at this
    simp only [zero_mul, add_zero]
    exact this
  have hv : HasDerivAt (fun s : ℝ => y.2 + s * (-Real.sin y.1 - c * y.2))
      (-Real.sin ((fun s : ℝ => y.1 + s * y.2) 0)
        - c * (fun s : ℝ => y.2 + s * (-Real.sin y.1 - c * y.2)) 0) 0 := by
    have := ((hasDerivAt_id (0 : ℝ)).mul_const (-Real.sin y.1 - c * y.2)).const_add y.2
    simp only [id, one_mul] at this
    simp only [zero_mul, add_zero]
    exact this
  have h2 := damped_energy_rate_aux c (fun s : ℝ => y.1 + s * y.2)
    (fun s : ℝ => y.2 + s * (-Real.sin y.1 - c * y.2)) 0 hθ hv
  have h3 : HasDerivAt ((fun p : ℝ × ℝ => p.2 ^ 2 / 2 + 1 - Real.cos p.1) ∘
      (fun s : ℝ => y + s • ((y.2, -Real.sin y.1 - c * y.2) : ℝ × ℝ))) (-c * y.2 ^ 2) 0 := by
    have e : ((fun p : ℝ × ℝ => p.2 ^ 2 / 2 + 1 - Real.cos p.1) ∘
        (fun s : ℝ => y + s • ((y.2, -Real.sin y.1 - c * y.2) : ℝ × ℝ))) =
        fun s => (fun s : ℝ => y.2 + s * (-Real.sin y.1 - c * y.2)) s ^ 2 / 2 + 1
          - Real.cos ((fun s : ℝ => y.1 + s * y.2) s) := by
      funext s
      simp only [Function.comp_apply, Prod.snd_add, Prod.fst_add, Prod.smul_mk, smul_eq_mul]
    rw [e]
    simpa only [zero_mul, add_zero] using h2
  exact h1.unique h3

#print axioms damped_energy_fderiv

/-- LaSalle's principle. Take a rate law x' = f(x) and an energy V on a finite-dimensional
real space, both with continuous slopes. Let K be a closed, bounded region that no motion
leaves once inside, with energy rate V'(x) = dV_x(f(x)) ≤ 0 throughout K. Let
Z = {x ∈ K | V'(x) = 0} be the pause set and M the largest invariant set in Z: the states p
whose whole motion, past and future, stays in Z. Then every motion starting in K approaches M
as t → ∞: it is eventually inside every open set that contains M. -/
theorem lasalle_invariance_principle
    {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] [FiniteDimensional ℝ E]
    (f : E → E) (V : E → ℝ) (hf : ContDiff ℝ 1 f) (hV : ContDiff ℝ 1 V)
    (K : Set E) (hKc : IsClosed K) (hKb : Bornology.IsBounded K)
    (hK_trap : ∀ (γ : ℝ → E) (T : ℝ),
      (∀ t ∈ Ico 0 T, HasDerivWithinAt γ (f (γ t)) (Ico 0 T) t) →
      γ 0 ∈ K → ∀ t ∈ Ico 0 T, γ t ∈ K)
    (hV_rate : ∀ x ∈ K, fderiv ℝ V x (f x) ≤ 0)
    (x : ℝ → E) (hx : ∀ t ∈ Ici (0 : ℝ), HasDerivWithinAt x (f (x t)) (Ici 0) t)
    (hx0 : x 0 ∈ K) :
    let Z : Set E := {y ∈ K | fderiv ℝ V y (f y) = 0}
    let M : Set E := {p | ∃ γ : ℝ → E, γ 0 = p ∧
      (∀ t, HasDerivAt γ (f (γ t)) t) ∧ ∀ t, γ t ∈ Z}
    Tendsto x atTop (𝓝ˢ M) := by
  intro Z M
  have hxK : ∀ t, 0 ≤ t → x t ∈ K := fun t ht =>
    hK_trap x (t + 1) (fun s hs => (hx s hs.1).mono Ico_subset_Ici_self) hx0 t
      ⟨ht, by linarith⟩
  have hxd : ∀ t, 0 < t → HasDerivAt x (f (x t)) t := fun t ht =>
    (hx t (le_of_lt ht)).hasDerivAt (Ici_mem_nhds ht)
  have hKcpt : IsCompact K := Metric.isCompact_of_isClosed_isBounded hKc hKb
  obtain ⟨L, hL⟩ :=
    (hf.locallyLipschitz.locallyLipschitzOn (s := K)).exists_lipschitzOnWith_of_compact hKcpt
  -- the energy along the motion never rises
  have hanti : AntitoneOn (fun t => V (x t)) (Ici 0) := by
    refine antitoneOn_of_hasDerivWithinAt_nonpos (convex_Ici 0)
      (hV.continuous.comp_continuousOn fun t ht => (hx t ht).continuousWithinAt)
      (f' := fun t => fderiv ℝ V (x t) (f (x t))) ?_ ?_
    · intro t ht
      rw [interior_Ici] at ht
      exact (((hV.differentiable one_ne_zero) (x t)).hasFDerivAt.comp_hasDerivAt t
        (hxd t ht)).hasDerivWithinAt
    · intro t ht
      rw [interior_Ici] at ht
      exact hV_rate _ (hxK t (le_of_lt ht))
  let W : ℝ → ℝ := fun t => V (x (max t 0))
  have hWanti : Antitone W := fun a b hab =>
    hanti (show (0 : ℝ) ≤ max a 0 from le_max_right _ _)
      (show (0 : ℝ) ≤ max b 0 from le_max_right _ _) (max_le_max hab le_rfl)
  have hbdd : BddBelow (range W) := by
    obtain ⟨m, hm⟩ := hKcpt.bddBelow_image hV.continuous.continuousOn
    refine ⟨m, ?_⟩
    rintro _ ⟨t, rfl⟩
    exact hm ⟨x (max t 0), hxK _ (le_max_right _ _), rfl⟩
  have hℓ : Tendsto (fun t => V (x t)) atTop (𝓝 (⨅ t, W t)) :=
    (tendsto_atTop_ciInf hWanti hbdd).congr'
      ((eventually_ge_atTop 0).mono fun t ht => by simp [W, max_eq_left ht])
  -- every limit point lies in M, so the motion ends near M
  rw [(hasBasis_nhdsSet M).tendsto_right_iff]
  rintro U ⟨hUo, hMU⟩
  by_contra hcon
  rw [not_eventually] at hcon
  have hfr := frequently_atTop.1 hcon
  choose τ hτge hτU using fun n : ℕ => hfr (n : ℝ)
  have hτ : Tendsto τ atTop atTop := tendsto_atTop_mono hτge tendsto_natCast_atTop_atTop
  obtain ⟨p, -, φ, hφ, hlim⟩ := hKcpt.tendsto_subseq (x := fun n => x (τ n))
    fun n => hxK _ (le_trans (Nat.cast_nonneg n) (hτge n))
  obtain ⟨γ, hγ0, hγd, hγZ⟩ := lasalle_limit_point f V hV K hKc L hL x hxd hxK _ hℓ
    (τ ∘ φ) (hτ.comp hφ.tendsto_atTop) p hlim
  have hpM : p ∈ M := ⟨γ, hγ0, hγd, fun t => hγZ t⟩
  obtain ⟨n, hn⟩ := (hlim.eventually (hUo.mem_nhds (hMU hpM))).exists
  exact hτU (φ n) hn

/-- Step 1: along the damped swing θ'' + c θ' + sin θ = 0, written as θ' = v,
v' = -sin θ - c v, the energy V = v²/2 + 1 - cos θ changes at the rate V' = -c v². -/
theorem damped_swing_energy_rate (c : ℝ) (θ v : ℝ → ℝ) (t : ℝ)
    (hθ : HasDerivAt θ (v t) t) (hv : HasDerivAt v (-Real.sin (θ t) - c * v t) t) :
    HasDerivAt (fun s => v s ^ 2 / 2 + 1 - Real.cos (θ s)) (-c * v t ^ 2) t := by
  exact damped_energy_rate_aux c θ v t hθ hv

/-- Step 5: with drag c > 0, every motion of the damped swing that starts with angle
within ±π and energy V = v²/2 + 1 - cos θ below 2 (the energy of upside down) ends hanging
at rest: θ(t) → 0 and v(t) → 0. -/
theorem damped_swing_below_top_settles (c : ℝ) (hc : 0 < c) (θ v : ℝ → ℝ)
    (hθ : ∀ t ∈ Ici (0 : ℝ), HasDerivWithinAt θ (v t) (Ici 0) t)
    (hv : ∀ t ∈ Ici (0 : ℝ), HasDerivWithinAt v (-Real.sin (θ t) - c * v t) (Ici 0) t)
    (hθ0 : |θ 0| ≤ Real.pi)
    (hE0 : v 0 ^ 2 / 2 + 1 - Real.cos (θ 0) < 2) :
    Tendsto θ atTop (𝓝 0) ∧ Tendsto v atTop (𝓝 0) := by
  let E0 : ℝ := v 0 ^ 2 / 2 + 1 - Real.cos (θ 0)
  let F : ℝ × ℝ → ℝ × ℝ := fun p => (p.2, -Real.sin p.1 - c * p.2)
  let W : ℝ × ℝ → ℝ := fun p => p.2 ^ 2 / 2 + 1 - Real.cos p.1
  let K : Set (ℝ × ℝ) := {p | |p.1| ≤ Real.pi ∧ W p ≤ E0}
  have hE0' : E0 < 2 := hE0
  have hF : ContDiff ℝ 1 F := by fun_prop
  have hW : ContDiff ℝ 1 W := by fun_prop
  have hrateY : ∀ y, fderiv ℝ W y (F y) = -c * y.2 ^ 2 := fun y => damped_energy_fderiv c y
  have hKc : IsClosed K := by
    show IsClosed ({p : ℝ × ℝ | |p.1| ≤ Real.pi} ∩ {p | W p ≤ E0})
    exact (isClosed_le (continuous_abs.comp continuous_fst) continuous_const).inter
      (isClosed_le hW.continuous continuous_const)
  have hcos : ∀ p ∈ K, -1 < Real.cos p.1 := by
    intro p hp
    have h2 : p.2 ^ 2 / 2 + 1 - Real.cos p.1 ≤ E0 := hp.2
    nlinarith [sq_nonneg p.2]
  have habs : ∀ p ∈ K, |p.1| < Real.pi := by
    intro p hp
    refine lt_of_le_of_ne hp.1 fun h => ?_
    have := Real.cos_abs p.1
    rw [h, Real.cos_pi] at this
    linarith [hcos p hp]
  have hKb : Bornology.IsBounded K := by
    refine isBounded_iff_forall_norm_le.2 ⟨4, fun p hp => norm_prod_le_iff.2 ⟨?_, ?_⟩⟩
    · rw [Real.norm_eq_abs]; linarith [hp.1, Real.pi_le_four]
    · have h2 : p.2 ^ 2 / 2 + 1 - Real.cos p.1 ≤ E0 := hp.2
      have := Real.cos_le_one p.1
      rw [Real.norm_eq_abs, abs_le]
      constructor <;> nlinarith [sq_nonneg p.2]
  have htrap : ∀ (γ : ℝ → ℝ × ℝ) (T : ℝ),
      (∀ t ∈ Ico 0 T, HasDerivWithinAt γ (F (γ t)) (Ico 0 T) t) →
      γ 0 ∈ K → ∀ t ∈ Ico 0 T, γ t ∈ K := by
    intro γ T hγ hγ0 t ht
    have hcont : ContinuousOn γ (Ico 0 T) := fun s hs => (hγ s hs).continuousWithinAt
    have hWγ : AntitoneOn (fun s => W (γ s)) (Ico 0 T) := by
      refine antitoneOn_of_hasDerivWithinAt_nonpos (convex_Ico 0 T)
        (hW.continuous.comp_continuousOn hcont) (f' := fun s => -c * (γ s).2 ^ 2) ?_ ?_
      · intro s hs
        rw [interior_Ico] at hs
        have hd : HasDerivAt γ (F (γ s)) s :=
          (hγ s (Ioo_subset_Ico_self hs)).hasDerivAt (Ico_mem_nhds hs.1 hs.2)
        have := ((hW.differentiable one_ne_zero) (γ s)).hasFDerivAt.comp_hasDerivAt s hd
        rw [hrateY] at this
        exact this.hasDerivWithinAt
      · intro s _
        have := sq_nonneg (γ s).2
        nlinarith
    have h0 : (0 : ℝ) ∈ Ico 0 T := ⟨le_rfl, lt_of_le_of_lt ht.1 ht.2⟩
    have hE : ∀ s ∈ Ico 0 T, W (γ s) ≤ E0 := fun s hs => (hWγ h0 hs hs.1).trans hγ0.2
    refine ⟨?_, hE t ht⟩
    by_contra hbig
    replace hbig := not_le.1 hbig
    have hsub : Icc 0 t ⊆ Ico 0 T := Icc_subset_Ico_right ht.2
    have hg : ContinuousOn (fun s => |(γ s).1|) (Icc 0 t) :=
      continuous_abs.comp_continuousOn (continuous_fst.comp_continuousOn (hcont.mono hsub))
    obtain ⟨s, hs, hseq⟩ := intermediate_value_Icc ht.1 hg ⟨hγ0.1, hbig.le⟩
    have hcs : Real.cos (γ s).1 = -1 := by
      have := Real.cos_abs (γ s).1
      simp only at hseq
      rw [hseq, Real.cos_pi] at this
      exact this.symm
    have hWs : (γ s).2 ^ 2 / 2 + 1 - Real.cos (γ s).1 ≤ E0 := hE s (hsub hs)
    rw [hcs] at hWs
    nlinarith [sq_nonneg (γ s).2]
  have hrate : ∀ y ∈ K, fderiv ℝ W y (F y) ≤ 0 := by
    intro y _
    rw [hrateY]
    have := sq_nonneg y.2
    nlinarith
  let X : ℝ → ℝ × ℝ := fun t => (θ t, v t)
  have hX : ∀ t ∈ Ici (0 : ℝ), HasDerivWithinAt X (F (X t)) (Ici 0) t :=
    fun t ht => (hθ t ht).prodMk (hv t ht)
  have hX0 : X 0 ∈ K := ⟨hθ0, le_rfl⟩
  have h := lasalle_invariance_principle F W hF hW K hKc hKb htrap hrate X hX hX0
  dsimp only at h
  have hM : ∀ p : ℝ × ℝ, (∃ γ : ℝ → ℝ × ℝ, γ 0 = p ∧ (∀ t, HasDerivAt γ (F (γ t)) t) ∧
      ∀ t, γ t ∈ {y ∈ K | fderiv ℝ W y (F y) = 0}) → p = (0, 0) := by
    rintro p ⟨γ, rfl, hγd, hγZ⟩
    have hv0 : ∀ t, (γ t).2 = 0 := by
      intro t
      have h1 := (hγZ t).2
      rw [hrateY] at h1
      have h2 : (γ t).2 ^ 2 = 0 := by
        rcases mul_eq_zero.1 h1 with h | h
        · exact absurd (neg_eq_zero.1 h) hc.ne'
        · exact h
      exact pow_eq_zero_iff two_ne_zero |>.1 h2
    have hd2 : HasDerivAt (fun t => (γ t).2) (F (γ 0)).2 0 := by
      have := (hasFDerivAt_snd (𝕜 := ℝ) (E := ℝ) (F := ℝ) (p := γ 0)).comp_hasDerivAt 0 (hγd 0)
      exact this
    have hd2' : HasDerivAt (fun t => (γ t).2) 0 0 := by
      have : (fun t => (γ t).2) = fun _ => (0 : ℝ) := funext hv0
      rw [this]; exact hasDerivAt_const _ _
    have hsin : Real.sin (γ 0).1 = 0 := by
      have h3 : (F (γ 0)).2 = 0 := hd2.unique hd2'
      have h4 : -Real.sin (γ 0).1 - c * (γ 0).2 = 0 := h3
      rw [hv0 0] at h4
      linarith
    have hK0 := (hγZ 0).1
    have hlt := abs_lt.1 (habs _ hK0)
    have h1 : (γ 0).1 = 0 := (Real.sin_eq_zero_iff_of_lt_of_lt hlt.1 hlt.2).1 hsin
    exact Prod.ext h1 (hv0 0)
  have h' : Tendsto X atTop (𝓝 ((0 : ℝ), (0 : ℝ))) := by
    rw [← nhdsSet_singleton]
    exact h.mono_right (nhdsSet_mono fun p hp => hM p hp)
  exact ⟨(continuous_fst.tendsto _).comp h', (continuous_snd.tendsto _).comp h'⟩

-- The card's exact energies. Released at 60 degrees with zero speed: V = 1 - cos 60° = 1/2.
example : (0 : ℝ) ^ 2 / 2 + 1 - Real.cos (Real.pi / 3) = 1 / 2 := by
  rw [Real.cos_pi_div_three]; norm_num
-- Upside down, at rest: V = 1 - cos 180° = 2.
example : (0 : ℝ) ^ 2 / 2 + 1 - Real.cos Real.pi = 2 := by
  rw [Real.cos_pi]; norm_num
-- A push of speed 3 from the bottom has energy 9/2; a push of 7/2 has energy 49/8.
example : (3 : ℚ) ^ 2 / 2 + 1 - 1 = 9 / 2 ∧ (7 / 2 : ℚ) ^ 2 / 2 + 1 - 1 = 49 / 8 := by norm_num
-- The trap at energy 1/2: the speed is at most 1, since 1²/2 = 1/2.
example : (1 : ℚ) ^ 2 / 2 = 1 / 2 := by norm_num

#print axioms lasalle_invariance_principle
#print axioms damped_swing_energy_rate
#print axioms damped_swing_below_top_settles
```

**Checked 2026-11-12 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'lasalle_gronwall_two_sided' depends on axioms: [propext, Classical.choice, Quot.sound]
'lasalle_limit_point' depends on axioms: [propext, Classical.choice, Quot.sound]
'damped_energy_rate_aux' depends on axioms: [propext, Classical.choice, Quot.sound]
'damped_energy_fderiv' depends on axioms: [propext, Classical.choice, Quot.sound]
'lasalle_invariance_principle' depends on axioms: [propext, Classical.choice, Quot.sound]
'damped_swing_energy_rate' depends on axioms: [propext, Classical.choice, Quot.sound]
'damped_swing_below_top_settles' depends on axioms: [propext, Classical.choice, Quot.sound]
```

> [!TIP]
> **Try changing**
> Guess first, then run it.
> - **Double the drag.** `C` to `1.0`: under 1° from t = 11.11 (3.55 s), late shrink 0.1630. The push of 3.5 falls back to well 0, so the last assert fails.
> - **Release from 170°.** `TH0` to `170 * pi / 180`: energy 1.985, under 2, so all checks pass; under 1° from t = 22.59.
> - **No drag.** `C` to `0.0`: turnarounds stay at 59.99°, and the search for one under 1° stops the program.

---

## The usual mistake

> [!warning]
> **Treating a zero energy rate as a resting place.** At the release V′ = 0, yet the acceleration is −0.866. The pause set, the line v = 0, is far bigger than where a motion can stay, one point. LaSalle's principle is the step between them.
>
> - **Forgetting the trap.** Energy 6.125 ends in well 1, 360° round.
> - **Taking the eye for the basin.** Energy 4.500 still settles in well 0.
> - **Claiming a speed.** LaSalle says where, not how fast; the shrink of 0.4443 per late half swing is the eigenvalues' work.

---

## Where you meet it in real life

- **Power grids.** A generator's rotor angle obeys this law, the swing equation; an eye-like energy region bounds the fault it survives.
- **Robot arms.** Drag added through velocity alone gives an energy rate like −c v^2; the settling proof is this card's.
- **Checking a simulation.** Energy lost must equal the drag integral: 0.500000 against 0.500000 here.
- **Limit sets.** Step 3's limit set is what [Poincare-Bendixson](09-poincare-bendixson-and-bendixsons-criterion.md) classifies; a closed loop, as in [Limit cycles](08-limit-cycles-and-van-der-pol.md), can be one.

> **Say it back**
> The swing's energy drains at c times speed squared: it never rises, but pauses at each turnaround. Below the energy of upside down, the swing is trapped. Its late motion loses no energy, so it lies on the pause line for all time. Only hanging at rest can, so the swing ends there, as does every start in the eye.

---

## What this builds on

- [Lyapunov functions](04-lyapunov-functions.md): the energy test, and the stay-near half of the conclusion.
- [The pendulum](03-the-nonlinear-pendulum.md): the equation of motion, its time unit, its energy and its rest points.

## Where this goes next

- [Passivity](../../13-Engineering%20mathematics/10-Robustness%20and%20Adaptation/05-passivity-and-absolute-stability.md): systems that only store or burn energy, and feedback proved stable by the same pause-set argument.

Physics handed the swing its energy function; for a controller or a circuit with no obvious energy, the open question is how to build one whose rate is never positive, and passivity supplies it.

---

## Sources

Verified 2026-09-28: every link below resolves to the publisher's page.

- LaSalle, J. "Some Extensions of Liapunov's Second Method." *IRE Transactions on Circuit Theory* 7, no. 4 (1960): 520–527. [doi:10.1109/TCT.1960.1086720](https://doi.org/10.1109/TCT.1960.1086720). The invariance principle, first stated.
- Teschl, Gerald. *Ordinary Differential Equations and Dynamical Systems*. AMS Graduate Studies in Mathematics 140. [Author's page with the free text](https://www.mat.univie.ac.at/~gerald/ftp/book-ode/). Theorems 6.14 and 6.15 prove the Krasovskii–LaSalle principle; the pendulum with friction is Problem 6.26.
- Strogatz, Steven H. *Nonlinear Dynamics and Chaos*, 3rd ed. CRC Press. [Publisher page](https://www.routledge.com/Nonlinear-Dynamics-and-Chaos-With-Applications-to-Physics-Biology-Chemistry-and-Engineering/Strogatz/p/book/9780367026509). The pendulum's phase plane.
