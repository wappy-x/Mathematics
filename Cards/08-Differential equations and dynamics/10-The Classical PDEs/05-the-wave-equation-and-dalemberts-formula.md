# The wave equation: a shape splits into two half-copies travelling opposite ways at speed c

[Syllabus](../../../SYLLABUS.md) → [Differential equations and dynamics](../README.md) → [The Classical PDEs](../README.md#s10) → The wave equation

---

## General Overview

A taut string 1 m long is pinched at its midpoint into a smooth bump 1 cm high, falling to about a third of that 5 cm either side, then let go without a push. Disturbances travel along it at 1 m/s.

The bump splits into two half-height copies that run apart. After 0.2 s they sit at 0.3 m and 0.7 m, and the middle is flat.

A loosely held skipping rope, flicked at one end, sends one pulse along at 0.5 m/s. A point 1 m away stays still for 2 s, then rises and falls. The flick gave the rope a starting velocity as well as a shape, and that velocity sends the whole pulse one way.

The rule behind both is the **wave equation**: each bit of string accelerates in proportion to how sharply the string bends there. **D'Alembert's formula** solves it on a long line, straight from the starting shape and velocity.

**On a long uniform string every motion is one shape sliding right plus one shape sliding left, both at speed c; released from rest, each carries half the starting shape, and a point feels only the starting data within distance ct of it.**

**What kind of fact this is:** a theorem, proved on this card in Why it works; the wave equation itself is a model of a string with small slopes.

### The picture: the pinch at release and 0.2 s later

<p align="center"><img src="../figures/the-wave-equation-and-dalemberts-formula.svg" alt="A 1 m string pinched 1 cm high at its middle (dashed, at release) and 0.2 s later (solid): two bumps 0.5 cm high at 0.3 m and 0.7 m, moving apart" width="420"></p>

Dashed: at release. Solid: 0.2 s later. To scale: 300 px per metre across, 150 px per centimetre up.

---

## The formula

Notation, as in [A partial differential equation](01-what-a-pde-says.md): a subscript names the rate. $u_t$ is the rate of change of height with time at a fixed place, $u_x$ the slope at a fixed time; a doubled letter takes the rate twice.

$$u_{tt} = c^2\, u_{xx}, \qquad c = \sqrt{T/\rho}$$

Here $u(x,t)$ is the string's height at position $x$ and time $t$, $T$ the tension and $\rho$ the mass per metre.

**Read it aloud:** the acceleration of each bit of string equals the wave speed squared times how sharply the string bends there.

On the whole line, starting from shape $f$ and velocity $g$, the solution is d'Alembert's formula:

$$u(x,t) = \frac{f(x-ct) + f(x+ct)}{2} + \frac{1}{2c}\int_{x-ct}^{x+ct} g(s)\,ds$$

**Read it aloud:** average the starting shape at the two points distance ct either side, then add the starting velocity summed between them, divided by twice the speed.

Behind it sits the general solution $u=F(x-ct)+G(x+ct)$: a profile $F$ sliding right plus a profile $G$ sliding left.

| Symbol | Plain meaning | In our example | Push it up and the answer… |
| --- | --- | --- | --- |
| $u$, $x$, $t$ | height, position, time | cm, m from 0 to 1, s | — |
| $u_t$, $u_x$, $u_{tt}$, $u_{xx}$ | velocity, slope, acceleration, bending (rate of change of slope) | bending peaks atop the pinch | more bending, more acceleration |
| $c$ | wave speed | 1 m/s string, 0.5 m/s rope | bumps travel farther |
| $T$, $\rho$ | tension, N; mass per metre, kg/m | rope: 0.05 and 0.2 | tension speeds waves, mass slows them |
| $f$, $g$ (with $H$, $w$) | starting shape and velocity; the pinch's height and width | $f(x)=H e^{-((x-0.5)/w)^2}$, 1 cm, 0.05 m; $g$ = 0 | copies scale with $f$; $g$ tips the balance between them |
| $F$, $G$ | right- and left-moving profiles | both $f/2$ for the pinch | — |
| $\xi$, $\eta$ | riding coordinates $x-ct$, $x+ct$ | 0.5 and 0.9 at 0.7 m, 0.2 s | — |
| $s$, $p$, $\Gamma$ | position summed over; rope pulse shape; antiderivative (running sum) of $g$ | $p$: 4 cm high, 0.2 m long, front at 0 | longer pulse, longer to pass |

### When it holds

- **Small slopes.** The upward pull is taken as tension times slope; steep bends break that.
- **Uniform string, constant tension.** Where $\rho$ changes, $c$ changes and part of a pulse reflects.
- **No friction or stiffness.** Drag or a stiff wire adds terms, and pulses shrink or change shape.
- **A whole line, or a time before anything reaches an end.** On the 1 m string the bumps' peaks reach the held ends at 0.50 s.
- **Smooth data.** $f$ twice differentiable, $g$ once; a kink travels by the formula but is not a solution in the plain sense.

---

## Why it works

### Step 0: coordinates that ride with the waves

A shape sliding right at speed c looks frozen to someone walking with it; [The transport equation](02-the-transport-equation-and-characteristics.md) used this for one direction. A string carries waves both ways, so the proof uses two walkers, one each way.

### Step 1: Newton on one short piece of string gives the equation

Take the piece from $x$ to $x+dx$, of mass $\rho\,dx$. With small slopes, the upward part of the tension at each end is tension times slope, so the net upward force is $T$ times the change in slope across the piece, $T\,u_{xx}\,dx$. Mass times acceleration equals force:

$$\rho\,dx\,u_{tt} = T\,u_{xx}\,dx \quad\Longrightarrow\quad u_{tt} = \frac{T}{\rho}\,u_{xx}.$$

Call $T/\rho$ by the name $c^2$. For the rope, $c=\sqrt{0.05/0.2}$ = 0.50 m/s.

### Step 2: any sliding shape solves it

Take $u=F(x-ct)$. By the [Chain rule](../../06-Calculus%20and%20analysis/02-Derivatives/03-chain-rule.md), each rate in $x$ brings out a factor 1 and each rate in $t$ a factor $-c$. So $u_{xx}=F''$ and $u_{tt}=c^2 F''$: the equation holds for any twice-differentiable $F$, and likewise for $G(x+ct)$. A sum of solutions is a solution, so $F(x-ct)+G(x+ct)$ solves it.

### Step 3: every solution is of that form

Change to the riding coordinates $\xi=x-ct$ and $\eta=x+ct$. The chain rule turns the equation into

$$u_{\xi\eta} = 0,$$

so the $\eta$-rate of $u$ does not change with $\xi$: it is a function of $\eta$ alone. Summing it up in $\eta$ gives a function of $\eta$ plus a function of $\xi$. So $u=F(\xi)+G(\eta)$ and nothing else.

<details>
<summary>The algebra behind Step 3</summary>

With $u(x,t)=U(\xi,\eta)$: $u_x=U_\xi+U_\eta$ and $u_t=-c\,U_\xi+c\,U_\eta$. Taking each rate again, $u_{xx}=U_{\xi\xi}+2U_{\xi\eta}+U_{\eta\eta}$ and $u_{tt}=c^2(U_{\xi\xi}-2U_{\xi\eta}+U_{\eta\eta})$. Subtract: $u_{tt}-c^2 u_{xx}=-4c^2\,U_{\xi\eta}$. Since $c$ is not zero, the wave equation holds exactly when $U_{\xi\eta}=0$.

</details>

### Step 4: the starting data fix the two profiles

At $t=0$ the shape and the velocity are given:

$$F(x) + G(x) = f(x), \qquad -c\,F'(x) + c\,G'(x) = g(x).$$

Summing the second from 0 to $x$ gives $G(x)-F(x)=\frac{1}{c}\int_0^x g(s)\,ds$ plus a constant. Add and subtract: $F$ and $G$ are each half of $f$, minus or plus half the summed velocity. Put them back with $x-ct$ and $x+ct$; the constants cancel and the two sums of $g$ join into one from $x-ct$ to $x+ct$. That is d'Alembert's formula.

Released from rest, $g=0$ and $F=G=f/2$: the pinch splits. The flick gives $g=-c\,p'$, the velocity of a right-moving pulse; then $G=0$ and $F=p$, and the whole pulse goes right.

### Step 5: finite speed and the domain of dependence

The formula uses $f$ only at $x \pm ct$ and $g$ only between. So the height at $x$ and time $t$ depends on the starting data from $x-ct$ to $x+ct$ and nowhere else: the **domain of dependence**.

<details>
<summary>Detailed proof</summary>

Claim: with $f$ twice and $g$ once continuously differentiable, d'Alembert's formula solves the equation on the whole line for $t \ge 0$, takes the given data, and is the only such solution.
Existence: the average of $f$ has the form $F(x-ct)+G(x+ct)$, so it solves by Step 2. The integral term is $\frac{1}{2c}(\Gamma(x+ct)-\Gamma(x-ct))$ with $\Gamma$ an antiderivative of $g$, the same form. At $t=0$ the first term is $f(x)$ and the integral is zero. The time rate at $t=0$ is $\frac{-c f'(x)+c f'(x)}{2}+\frac{c\,g(x)+c\,g(x)}{2c}=g(x)$.
Uniqueness: the difference of two solutions with the same data solves the equation with zero shape and zero velocity. It has continuous second rates, so Step 3 writes it as $F(\xi)+G(\eta)$. Step 4 with $f=g=0$ makes $F=-G$ a constant, so the difference is zero everywhere.
The whole line matters: Step 3 needs, for each $\eta$, every $\xi \le \eta$ (the half-plane $t \ge 0$). On a finite string the ends constrain the profiles.

</details>

Another route factors the equation into two transport equations, one per direction; d'Alembert takes it.

---

## Worked numbers, by hand

The pinch: $f(x)=e^{-((x-0.5)/0.05)^2}$ cm, $c$ = 1 m/s, released from rest, so $u=\tfrac12\big(f(x-t)+f(x+t)\big)$.

| Step | Arithmetic | Value |
| --- | --- | --- |
| Midpoint at release | $f(0.5)=e^0$ | 1.000000 cm |
| Midpoint at 0.05 s | $\tfrac12(f(0.45)+f(0.55))=\tfrac12(e^{-1}+e^{-1})$ | 0.367879 cm |
| Right bump at 0.2 s | $\tfrac12(f(0.5)+f(0.9))=\tfrac12(1+e^{-64})$ | 0.500000 cm |
| Midpoint at 0.2 s | $\tfrac12(f(0.3)+f(0.7))=e^{-16}$ | 0.000000 cm |
| Rope speed | $\sqrt{0.05 / 0.2}$ | 0.50 m/s |
| Rope arrival at 1 m | 1 m ÷ 0.50 m/s | **2.00 s** |

At 0.05 s each half-copy is one pinch-width off the midpoint. The rope's 4 cm peak passes 1 m at 2.2 s.

### What breaks if you drop a piece

| Mistake | Comes out at | What went wrong |
| --- | --- | --- |
| Drop the 1/2 in the average | right bump 1.000000 cm at 0.2 s | each copy at full height: the start would read double |
| Keep only the right-moving copy | u(0.30 m, 0.20 s) = 0.000000 cm, not 0.5 | that is the transport equation; the left bump is lost |
| Drop the velocity term on the rope | 2.000000 cm at 1 m, 2.2 s, not 4 | half the pulse is sent the wrong way |
| Speed as T/ρ, no square root | arrival at 4.00 s, not 2.00 | wrong units; here the speed halves |

---

## Code, from first principles, and it actually runs

Road one is d'Alembert's formula. Road two never uses it: it steps the string on a grid, bending measured by neighbouring heights, ends held at zero (the leapfrog scheme). Their gap at 0.2 s shrinks about fourfold each time the spacing halves: a second-order method. The second case is the rope: the formula, velocity term summed by Simpson's rule (a weighted sum of samples), against the sliding pulse $p(x-ct)$, plus a scan for first motion at 1 m.

### Python

```python
# The wave equation u_tt = c^2 u_xx, two roads: d'Alembert's formula and a grid stepped by its own loop.
import math

C, H, W = 1.0, 1.0, 0.05                   # string: speed m/s, pinch height cm, pinch width m
f = lambda x: H * math.exp(-((x - 0.5) / W) ** 2)          # starting shape, cm

def dalembert(x, t):                       # released from rest: two half-copies of f
    return 0.5 * (f(x - C * t) + f(x + C * t))

def grid(n, t_end, r=0.5):                 # leapfrog on 0..1 m, ends held at 0, r = c dt / dx
    dx = 1.0 / n; steps = round(t_end / (r * dx / C))
    lap = lambda u, j: u[j + 1] - 2 * u[j] + u[j - 1]
    old = [0.0] + [f(j * dx) for j in range(1, n)] + [0.0]
    new = [0.0] + [old[j] + 0.5 * r * r * lap(old, j) for j in range(1, n)] + [0.0]
    for _ in range(steps - 1):
        old, new = new, [0.0] + [2 * new[j] - old[j] + r * r * lap(new, j) for j in range(1, n)] + [0.0]
    return new, dx

for x, t in ((0.5, 0.0), (0.5, 0.05), (0.7, 0.2), (0.3, 0.2), (0.5, 0.2)):
    print(f"pinch: u({x:.2f} m, {t:.2f} s) = {dalembert(x, t):.6f} cm")
errs = []
for n in (100, 200, 400):
    u, dx = grid(n, 0.2)
    errs.append(max(abs(u[j] - dalembert(j * dx, 0.2)) for j in range(n + 1)))
    print(f"grid n={n}: dx = {dx:.4f} m, largest gap to d'Alembert at 0.2 s = {errs[-1]:.5f} cm")
print(f"error ratios: {errs[0] / errs[1]:.2f} {errs[1] / errs[2]:.2f} (order 2 means 4)")
jp = max(range(200, 401), key=lambda j: u[j])
print(f"grid right bump at 0.2 s: x = {jp * dx:.3f} m, height = {u[jp]:.4f} cm")
print(f"bump peaks reach the held ends at: {0.5 / C:.2f} s")
print(f"what breaks: no 1/2 gives {2 * dalembert(0.7, 0.2):.6f} cm; one copy only gives u(0.30, 0.20) = {f(0.3 - C * 0.2):.6f} cm")
print(f"figure, px: start peak (190, {190 - 150 * f(0.5):.0f}); bumps ({40 + 300 * 0.3:.0f}, {190 - 150 * dalembert(0.3, 0.2):.1f}) ({40 + 300 * 0.7:.0f}, {190 - 150 * dalembert(0.7, 0.2):.1f})")

# Second case: a rope, c = sqrt(T / rho), flicked so one pulse runs right from x = 0.
T, RHO, A = 0.05, 0.2, 4.0                 # tension N, mass per length kg/m, pulse height cm
c = math.sqrt(T / RHO)
p = lambda s: A * (1 - ((s + 0.1) / 0.1) ** 2) ** 3 if -0.2 < s < 0 else 0.0
dp = lambda s: A * 3 * (1 - ((s + 0.1) / 0.1) ** 2) ** 2 * (-2 * (s + 0.1) / 0.01) if -0.2 < s < 0 else 0.0
def rope(x, t, m=4000):                    # d'Alembert with f = p, g = -c p', g integrated by Simpson's rule
    a, b = x - c * t, x + c * t; h = (b - a) / m
    s = sum((1 if k in (0, m) else 4 if k % 2 else 2) * -c * dp(a + k * h) for k in range(m + 1)) * h / 3
    return 0.5 * (p(a) + p(b)) + s / (2 * c)
print(f"rope: c = sqrt({T} N / {RHO} kg/m) = {c:.2f} m/s, so 1 m takes {1 / c:.2f} s; T / rho = {T / RHO:.2f} would say {RHO / T:.2f} s")
print(f"rope u(1 m, 2.2 s): travelling pulse p(x - ct) = {p(1 - c * 2.2):.6f} cm, d'Alembert = {rope(1, 2.2):.6f} cm, no velocity term = {0.5 * (p(1 - c * 2.2) + p(1 + c * 2.2)):.6f} cm")
first = next(k / 100 for k in range(400) if abs(rope(1, k / 100)) > 1e-9)
print(f"rope: first motion at x = 1 m on a 0.01 s scan: t = {first:.2f} s")
print("rope u(1 m, t) cm, t = 1.90 to 2.50 step 0.05:", " ".join(f"{round(rope(1, 1.9 + 0.05 * k), 2) + 0.0:.2f}" for k in range(13)))

assert errs[2] < 1e-3                      # the grid, stepped blind, lands on d'Alembert's formula
assert 3.5 < errs[0] / errs[1] < 4.5       # halving dx cuts the gap about fourfold: second order
assert abs(rope(1, 2.2) - p(1 - c * 2.2)) < 1e-6   # the velocity integral turns two halves into one pulse
assert 1 / c <= first <= 1 / c + 0.01      # nothing arrives before distance / speed
print("ALL CHECKS PASS")
```

**Ran 2026-11-12 on macOS, Python 3.14.10, standard library only. All checks passed. Output, pasted from the run:**

```
pinch: u(0.50 m, 0.00 s) = 1.000000 cm
pinch: u(0.50 m, 0.05 s) = 0.367879 cm
pinch: u(0.70 m, 0.20 s) = 0.500000 cm
pinch: u(0.30 m, 0.20 s) = 0.500000 cm
pinch: u(0.50 m, 0.20 s) = 0.000000 cm
grid n=100: dx = 0.0100 m, largest gap to d'Alembert at 0.2 s = 0.00991 cm
grid n=200: dx = 0.0050 m, largest gap to d'Alembert at 0.2 s = 0.00245 cm
grid n=400: dx = 0.0025 m, largest gap to d'Alembert at 0.2 s = 0.00061 cm
error ratios: 4.05 4.01 (order 2 means 4)
grid right bump at 0.2 s: x = 0.700 m, height = 0.5000 cm
bump peaks reach the held ends at: 0.50 s
what breaks: no 1/2 gives 1.000000 cm; one copy only gives u(0.30, 0.20) = 0.000000 cm
figure, px: start peak (190, 40); bumps (130, 115.0) (250, 115.0)
rope: c = sqrt(0.05 N / 0.2 kg/m) = 0.50 m/s, so 1 m takes 2.00 s; T / rho = 0.25 would say 4.00 s
rope u(1 m, 2.2 s): travelling pulse p(x - ct) = 4.000000 cm, d'Alembert = 4.000000 cm, no velocity term = 2.000000 cm
rope: first motion at x = 1 m on a 0.01 s scan: t = 2.01 s
rope u(1 m, t) cm, t = 1.90 to 2.50 step 0.05: 0.00 0.00 0.00 0.33 1.69 3.30 4.00 3.30 1.69 0.33 0.00 0.00 0.00
ALL CHECKS PASS
```

### Rust

```rust
// The wave equation u_tt = c^2 u_xx, two roads: d'Alembert's formula and a grid stepped by its own loop.
const C: f64 = 1.0; // string speed, m/s
const H: f64 = 1.0; // pinch height, cm
const W: f64 = 0.05; // pinch width, m
const T: f64 = 0.05; // rope tension, N
const RHO: f64 = 0.2; // rope mass per length, kg/m
const A: f64 = 4.0; // rope pulse height, cm

fn f(x: f64) -> f64 { H * (-((x - 0.5) / W).powi(2)).exp() } // starting shape, cm
fn dalembert(x: f64, t: f64) -> f64 { 0.5 * (f(x - C * t) + f(x + C * t)) } // released from rest

fn grid(n: usize, t_end: f64, r: f64) -> (Vec<f64>, f64) { // leapfrog on 0..1 m, ends held at 0
    let dx = 1.0 / n as f64;
    let steps = (t_end / (r * dx / C)).round() as usize;
    let lap = |u: &Vec<f64>, j: usize| u[j + 1] - 2.0 * u[j] + u[j - 1];
    let mut old: Vec<f64> = (0..=n).map(|j| if j == 0 || j == n { 0.0 } else { f(j as f64 * dx) }).collect();
    let mut new: Vec<f64> = (0..=n).map(|j| if j == 0 || j == n { 0.0 } else { old[j] + 0.5 * r * r * lap(&old, j) }).collect();
    for _ in 0..steps - 1 {
        let next: Vec<f64> = (0..=n).map(|j| if j == 0 || j == n { 0.0 } else { 2.0 * new[j] - old[j] + r * r * lap(&new, j) }).collect();
        old = new;
        new = next;
    }
    (new, dx)
}

fn p(s: f64) -> f64 { if -0.2 < s && s < 0.0 { A * (1.0 - ((s + 0.1) / 0.1).powi(2)).powi(3) } else { 0.0 } }
fn dp(s: f64) -> f64 { if -0.2 < s && s < 0.0 { A * 3.0 * (1.0 - ((s + 0.1) / 0.1).powi(2)).powi(2) * (-2.0 * (s + 0.1) / 0.01) } else { 0.0 } }
fn rope(x: f64, t: f64, c: f64) -> f64 { // d'Alembert with f = p, g = -c p', g integrated by Simpson's rule
    let m = 4000;
    let (a, b) = (x - c * t, x + c * t);
    let h = (b - a) / m as f64;
    let s: f64 = (0..=m).map(|k| { let wt = if k == 0 || k == m { 1.0 } else if k % 2 == 1 { 4.0 } else { 2.0 }; wt * -c * dp(a + k as f64 * h) }).sum::<f64>() * h / 3.0;
    0.5 * (p(a) + p(b)) + s / (2.0 * c)
}

fn main() {
    for &(x, t) in &[(0.5, 0.0), (0.5, 0.05), (0.7, 0.2), (0.3, 0.2), (0.5, 0.2)] {
        println!("pinch: u({:.2} m, {:.2} s) = {:.6} cm", x, t, dalembert(x, t));
    }
    let mut errs = vec![];
    let (mut u, mut dx) = (vec![], 0.0);
    for &n in &[100usize, 200, 400] {
        let g = grid(n, 0.2, 0.5);
        u = g.0; dx = g.1;
        errs.push((0..=n).map(|j| (u[j] - dalembert(j as f64 * dx, 0.2)).abs()).fold(0.0, f64::max));
        println!("grid n={}: dx = {:.4} m, largest gap to d'Alembert at 0.2 s = {:.5} cm", n, dx, errs[errs.len() - 1]);
    }
    println!("error ratios: {:.2} {:.2} (order 2 means 4)", errs[0] / errs[1], errs[1] / errs[2]);
    let jp = (200..=400).fold(200, |b, j| if u[j] > u[b] { j } else { b });
    println!("grid right bump at 0.2 s: x = {:.3} m, height = {:.4} cm", jp as f64 * dx, u[jp]);
    println!("bump peaks reach the held ends at: {:.2} s", 0.5 / C);
    println!("what breaks: no 1/2 gives {:.6} cm; one copy only gives u(0.30, 0.20) = {:.6} cm", 2.0 * dalembert(0.7, 0.2), f(0.3 - C * 0.2));
    println!("figure, px: start peak (190, {:.0}); bumps ({:.0}, {:.1}) ({:.0}, {:.1})", 190.0 - 150.0 * f(0.5), 40.0 + 300.0 * 0.3, 190.0 - 150.0 * dalembert(0.3, 0.2), 40.0 + 300.0 * 0.7, 190.0 - 150.0 * dalembert(0.7, 0.2));
    let c = (T / RHO).sqrt();
    println!("rope: c = sqrt({} N / {} kg/m) = {:.2} m/s, so 1 m takes {:.2} s; T / rho = {:.2} would say {:.2} s", T, RHO, c, 1.0 / c, T / RHO, RHO / T);
    println!("rope u(1 m, 2.2 s): travelling pulse p(x - ct) = {:.6} cm, d'Alembert = {:.6} cm, no velocity term = {:.6} cm", p(1.0 - c * 2.2), rope(1.0, 2.2, c), 0.5 * (p(1.0 - c * 2.2) + p(1.0 + c * 2.2)));
    let first = (0..400).map(|k| k as f64 / 100.0).find(|&t| rope(1.0, t, c).abs() > 1e-9).unwrap();
    println!("rope: first motion at x = 1 m on a 0.01 s scan: t = {:.2} s", first);
    let row: Vec<String> = (0..13).map(|k| format!("{:.2}", (rope(1.0, 1.9 + 0.05 * k as f64, c) * 100.0).round() / 100.0 + 0.0)).collect();
    println!("rope u(1 m, t) cm, t = 1.90 to 2.50 step 0.05: {}", row.join(" "));

    assert!(errs[2] < 1e-3); // the grid, stepped blind, lands on d'Alembert's formula
    assert!(3.5 < errs[0] / errs[1] && errs[0] / errs[1] < 4.5); // halving dx cuts the gap about fourfold
    assert!((rope(1.0, 2.2, c) - p(1.0 - c * 2.2)).abs() < 1e-6); // the velocity integral makes one pulse
    assert!(1.0 / c <= first && first <= 1.0 / c + 0.01); // nothing arrives before distance / speed
    println!("ALL CHECKS PASS");
}
```

**Ran 2026-11-12 on macOS, rustc 1.98.1, no crates. All checks passed. Output, pasted from the run:**

```
pinch: u(0.50 m, 0.00 s) = 1.000000 cm
pinch: u(0.50 m, 0.05 s) = 0.367879 cm
pinch: u(0.70 m, 0.20 s) = 0.500000 cm
pinch: u(0.30 m, 0.20 s) = 0.500000 cm
pinch: u(0.50 m, 0.20 s) = 0.000000 cm
grid n=100: dx = 0.0100 m, largest gap to d'Alembert at 0.2 s = 0.00991 cm
grid n=200: dx = 0.0050 m, largest gap to d'Alembert at 0.2 s = 0.00245 cm
grid n=400: dx = 0.0025 m, largest gap to d'Alembert at 0.2 s = 0.00061 cm
error ratios: 4.05 4.01 (order 2 means 4)
grid right bump at 0.2 s: x = 0.700 m, height = 0.5000 cm
bump peaks reach the held ends at: 0.50 s
what breaks: no 1/2 gives 1.000000 cm; one copy only gives u(0.30, 0.20) = 0.000000 cm
figure, px: start peak (190, 40); bumps (130, 115.0) (250, 115.0)
rope: c = sqrt(0.05 N / 0.2 kg/m) = 0.50 m/s, so 1 m takes 2.00 s; T / rho = 0.25 would say 4.00 s
rope u(1 m, 2.2 s): travelling pulse p(x - ct) = 4.000000 cm, d'Alembert = 4.000000 cm, no velocity term = 2.000000 cm
rope: first motion at x = 1 m on a 0.01 s scan: t = 2.01 s
rope u(1 m, t) cm, t = 1.90 to 2.50 step 0.05: 0.00 0.00 0.00 0.33 1.69 3.30 4.00 3.30 1.69 0.33 0.00 0.00 0.00
ALL CHECKS PASS
```

### Lean

Lean proves d'Alembert's formula, the general solution and the domain of dependence for every speed $c$ above zero, plus the card's exact arithmetic.

- Take $c$ above zero, $f$ with continuous second rates and $g$ with a continuous first rate. Then d'Alembert's formula solves the wave equation on the whole line, starting with shape $f$ and velocity $g$.
- It is the only solution. Suppose $v$ has continuous second rates, solves the wave equation for $t \ge 0$, and starts with $f$ and $g$. Then $v$ equals d'Alembert's formula at every $x$ and every $t \ge 0$.
- Suppose $u$ has continuous second rates and solves the wave equation at every $x$ and $t$. Then $u = F(x-ct) + G(x+ct)$ for some profiles $F$ and $G$ with continuous second rates.
- Take two solutions for $t \ge 0$ with continuous second rates, and suppose their starting data agree within $c t_0$ of $x_0$. Then their heights at $x_0$ and time $t_0$ are equal, for any $t_0 \ge 0$.
- The rope arithmetic holds exactly: speed 0.50 m/s, arrival at 1 m after 2 s, and 4 s with the square root dropped.
- The pinch table's powers of $e$ hold exactly. They are $-1$ at 0.45 m and 0.55 m, $-64$ at 0.9 m, and $-16$ at 0.3 m and 0.7 m.
- The bumps' peaks start 0.5 m from each held end, so at 1 m/s they reach the ends at 0.50 s.

Decimals, the grid's fourfold shrink and the rope's Simpson sum are left to the Python and Rust checks.

```lean
-- The wave equation: d'Alembert's formula solves u_tt = c^2 u_xx on the whole line from a starting shape and velocity, it is the only solution, every solution is a right-moving plus a left-moving profile, and the height at a point depends only on starting data within distance ct.
import Mathlib.Analysis.Calculus.ContDiff.Basic
import Mathlib.MeasureTheory.Integral.IntervalIntegral.FundThmCalculus
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Calculus.FDeriv.Symmetric
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.ContDiff.Deriv
import Mathlib.Analysis.Calculus.Deriv.Prod

open scoped Topology

/-- A function with derivative zero on the interval between `0` and `s` takes the same value
at `s` and at `0`. -/
lemma wave_aux_const {φ φ' : ℝ → ℝ} (hφ : ∀ r, HasDerivAt φ (φ' r) r) (s : ℝ)
    (h0 : ∀ r ∈ Set.uIcc 0 s, φ' r = 0) : φ s = φ 0 := by
  have hcont : Continuous φ := continuous_iff_continuousAt.2 fun r => (hφ r).continuousAt
  rcases le_total 0 s with hs | hs
  · refine constant_of_has_deriv_right_zero (a := 0) (b := s) hcont.continuousOn
      (fun r hr => ?_) s ⟨hs, le_rfl⟩
    have := h0 r (by rw [Set.uIcc_of_le hs]; exact Set.Ico_subset_Icc_self hr)
    rw [← this]; exact (hφ r).hasDerivWithinAt
  · refine (constant_of_has_deriv_right_zero (a := s) (b := 0) hcont.continuousOn
      (fun r hr => ?_) 0 ⟨hs, le_rfl⟩).symm
    have := h0 r (by rw [Set.uIcc_of_ge hs]; exact Set.Ico_subset_Icc_self hr)
    rw [← this]; exact (hφ r).hasDerivWithinAt

lemma wave_hasDerivAt1 {W : ℝ × ℝ → ℝ} (hW : ContDiff ℝ 2 W) {γ : ℝ → ℝ × ℝ} {γ' : ℝ × ℝ}
    {s : ℝ} (hγ : HasDerivAt γ γ' s) :
    HasDerivAt (fun s => W (γ s)) (fderiv ℝ W (γ s) γ') s :=
  ((hW.differentiable (by norm_num)) (γ s)).hasFDerivAt.comp_hasDerivAt s hγ

lemma wave_hasDerivAt2 {W : ℝ × ℝ → ℝ} (hW : ContDiff ℝ 2 W) {γ : ℝ → ℝ × ℝ} {γ' : ℝ × ℝ}
    {s : ℝ} (hγ : HasDerivAt γ γ' s) (v : ℝ × ℝ) :
    HasDerivAt (fun s => fderiv ℝ W (γ s) v) (fderiv ℝ (fderiv ℝ W) (γ s) γ' v) s := by
  have hD : ContDiff ℝ 1 (fderiv ℝ W) := hW.fderiv_right (by norm_num)
  have h1 := ((hD.differentiable (by norm_num)) (γ s)).hasFDerivAt.comp_hasDerivAt s hγ
  have h2 := h1.clm_apply (hasDerivAt_const s v)
  simpa using h2

lemma wave_symm {W : ℝ × ℝ → ℝ} (hW : ContDiff ℝ 2 W) (p v w : ℝ × ℝ) :
    fderiv ℝ (fderiv ℝ W) p v w = fderiv ℝ (fderiv ℝ W) p w v :=
  hW.contDiffAt.isSymmSndFDerivAt (by simp) v w

lemma wave_dt (w : ℝ → ℝ → ℝ) (hw : ContDiff ℝ 2 (fun p : ℝ × ℝ => w p.1 p.2)) (x t : ℝ) :
    HasDerivAt (fun t => w x t) (fderiv ℝ (fun p : ℝ × ℝ => w p.1 p.2) (x, t) (0, 1)) t :=
  wave_hasDerivAt1 hw (HasDerivAt.prodMk (hasDerivAt_const t x) (hasDerivAt_id' t))

lemma wave_dx (w : ℝ → ℝ → ℝ) (hw : ContDiff ℝ 2 (fun p : ℝ × ℝ => w p.1 p.2)) (x t : ℝ) :
    HasDerivAt (fun x => w x t) (fderiv ℝ (fun p : ℝ × ℝ => w p.1 p.2) (x, t) (1, 0)) x :=
  wave_hasDerivAt1 hw (HasDerivAt.prodMk (hasDerivAt_id' x) (hasDerivAt_const x t))

lemma wave_dtt (w : ℝ → ℝ → ℝ) (hw : ContDiff ℝ 2 (fun p : ℝ × ℝ => w p.1 p.2)) (x t : ℝ) :
    deriv (fun t => deriv (fun t => w x t) t) t =
      fderiv ℝ (fderiv ℝ (fun p : ℝ × ℝ => w p.1 p.2)) (x, t) (0, 1) (0, 1) := by
  have e : (fun t => deriv (fun t => w x t) t) =
      fun t => fderiv ℝ (fun p : ℝ × ℝ => w p.1 p.2) (x, t) (0, 1) :=
    funext fun t => (wave_dt w hw x t).deriv
  rw [e]
  exact (wave_hasDerivAt2 hw (HasDerivAt.prodMk (hasDerivAt_const t x) (hasDerivAt_id' t)) (0, 1)).deriv

lemma wave_dxx (w : ℝ → ℝ → ℝ) (hw : ContDiff ℝ 2 (fun p : ℝ × ℝ => w p.1 p.2)) (x t : ℝ) :
    deriv (fun x => deriv (fun x => w x t) x) x =
      fderiv ℝ (fderiv ℝ (fun p : ℝ × ℝ => w p.1 p.2)) (x, t) (1, 0) (1, 0) := by
  have e : (fun x => deriv (fun x => w x t) x) =
      fun x => fderiv ℝ (fun p : ℝ × ℝ => w p.1 p.2) (x, t) (1, 0) :=
    funext fun x => (wave_dx w hw x t).deriv
  rw [e]
  exact (wave_hasDerivAt2 hw (HasDerivAt.prodMk (hasDerivAt_id' x) (hasDerivAt_const x t)) (1, 0)).deriv

/-- `u_t - c u_x` is constant along the right-moving lines `x - ct = const`. -/
lemma wave_char_a {W : ℝ × ℝ → ℝ} (hW : ContDiff ℝ 2 W) (c x₁ s : ℝ)
    (hwave : ∀ r ∈ Set.uIcc 0 s, fderiv ℝ (fderiv ℝ W) (x₁ + c * r, r) (0, 1) (0, 1) =
        c ^ 2 * fderiv ℝ (fderiv ℝ W) (x₁ + c * r, r) (1, 0) (1, 0)) :
    fderiv ℝ W (x₁ + c * s, s) (0, 1) - c * fderiv ℝ W (x₁ + c * s, s) (1, 0) =
      fderiv ℝ W (x₁, 0) (0, 1) - c * fderiv ℝ W (x₁, 0) (1, 0) := by
  have hγ : ∀ r, HasDerivAt (fun r : ℝ => ((x₁ + c * r, r) : ℝ × ℝ)) ((c, 1) : ℝ × ℝ) r := by
    intro r
    have := HasDerivAt.prodMk (HasDerivAt.const_add x₁ (HasDerivAt.const_mul c (hasDerivAt_id' r))) (hasDerivAt_id' r)
    simpa using this
  have key := wave_aux_const
    (φ := fun r => fderiv ℝ W (x₁ + c * r, r) (0, 1) - c * fderiv ℝ W (x₁ + c * r, r) (1, 0))
    (φ' := fun r => fderiv ℝ (fderiv ℝ W) (x₁ + c * r, r) (c, 1) (0, 1) -
      c * fderiv ℝ (fderiv ℝ W) (x₁ + c * r, r) (c, 1) (1, 0))
    (fun r => HasDerivAt.sub (wave_hasDerivAt2 hW (hγ r) (0, 1))
      (HasDerivAt.const_mul c (wave_hasDerivAt2 hW (hγ r) (1, 0)))) s
    (fun r hr => by
      have e : ((c, 1) : ℝ × ℝ) = c • ((1 : ℝ), (0 : ℝ)) + ((0 : ℝ), (1 : ℝ)) := by
        ext <;> simp
      have hs := wave_symm hW (x₁ + c * r, r) (1, 0) (0, 1)
      have hwr := hwave r hr
      simp only [e, map_add, map_smul, add_apply,
        smul_apply, smul_eq_mul]
      linear_combination c * hs + hwr)
  simp only [mul_zero, add_zero] at key
  exact key

/-- `u_t + c u_x` is constant along the left-moving lines `x + ct = const`. -/
lemma wave_char_b {W : ℝ × ℝ → ℝ} (hW : ContDiff ℝ 2 W) (c x₁ s : ℝ)
    (hwave : ∀ r ∈ Set.uIcc 0 s, fderiv ℝ (fderiv ℝ W) (x₁ - c * r, r) (0, 1) (0, 1) =
        c ^ 2 * fderiv ℝ (fderiv ℝ W) (x₁ - c * r, r) (1, 0) (1, 0)) :
    fderiv ℝ W (x₁ - c * s, s) (0, 1) + c * fderiv ℝ W (x₁ - c * s, s) (1, 0) =
      fderiv ℝ W (x₁, 0) (0, 1) + c * fderiv ℝ W (x₁, 0) (1, 0) := by
  have hγ : ∀ r, HasDerivAt (fun r : ℝ => ((x₁ - c * r, r) : ℝ × ℝ)) ((-c, 1) : ℝ × ℝ) r := by
    intro r
    have := HasDerivAt.prodMk (HasDerivAt.const_sub x₁ (HasDerivAt.const_mul c (hasDerivAt_id' r))) (hasDerivAt_id' r)
    simpa using this
  have key := wave_aux_const
    (φ := fun r => fderiv ℝ W (x₁ - c * r, r) (0, 1) + c * fderiv ℝ W (x₁ - c * r, r) (1, 0))
    (φ' := fun r => fderiv ℝ (fderiv ℝ W) (x₁ - c * r, r) (-c, 1) (0, 1) +
      c * fderiv ℝ (fderiv ℝ W) (x₁ - c * r, r) (-c, 1) (1, 0))
    (fun r => HasDerivAt.add (wave_hasDerivAt2 hW (hγ r) (0, 1))
      (HasDerivAt.const_mul c (wave_hasDerivAt2 hW (hγ r) (1, 0)))) s
    (fun r hr => by
      have e : ((-c, 1) : ℝ × ℝ) = (-c) • ((1 : ℝ), (0 : ℝ)) + ((0 : ℝ), (1 : ℝ)) := by
        ext <;> simp
      have hs := wave_symm hW (x₁ - c * r, r) (1, 0) (0, 1)
      have hwr := hwave r hr
      simp only [e, map_add, map_smul, add_apply,
        smul_apply, smul_eq_mul]
      linear_combination -c * hs + hwr)
  simp only [mul_zero, sub_zero] at key
  exact key

/-- The time derivative of a solution is determined by the starting data along the two
characteristic lines through the point. -/
lemma wave_ut_formula (c : ℝ) (w : ℝ → ℝ → ℝ) (hw : ContDiff ℝ 2 (fun p : ℝ × ℝ => w p.1 p.2))
    (x t : ℝ)
    (hwave : ∀ x' t', t' ∈ Set.uIcc 0 t → deriv (fun t => deriv (fun t => w x' t) t) t' =
        c ^ 2 * deriv (fun x => deriv (fun x => w x t') x) x') :
    deriv (fun t => w x t) t =
      ((deriv (fun s => w (x - c * t) s) 0 - c * deriv (fun y => w y 0) (x - c * t)) +
       (deriv (fun s => w (x + c * t) s) 0 + c * deriv (fun y => w y 0) (x + c * t))) / 2 := by
  have hw2 : ∀ x' t', t' ∈ Set.uIcc 0 t →
      fderiv ℝ (fderiv ℝ (fun p : ℝ × ℝ => w p.1 p.2)) (x', t') (0, 1) (0, 1) =
        c ^ 2 * fderiv ℝ (fderiv ℝ (fun p : ℝ × ℝ => w p.1 p.2)) (x', t') (1, 0) (1, 0) := by
    intro x' t' ht'
    have := hwave x' t' ht'
    rwa [wave_dtt w hw, wave_dxx w hw] at this
  have ha := wave_char_a hw c (x - c * t) t (fun r hr => hw2 _ r hr)
  have hb := wave_char_b hw c (x + c * t) t (fun r hr => hw2 _ r hr)
  rw [show x - c * t + c * t = x by ring] at ha
  rw [show x + c * t - c * t = x by ring] at hb
  rw [(wave_dt w hw x t).deriv, (wave_dt w hw (x - c * t) 0).deriv,
    (wave_dt w hw (x + c * t) 0).deriv, (wave_dx w hw (x - c * t) 0).deriv,
    (wave_dx w hw (x + c * t) 0).deriv]
  linear_combination (ha + hb) / 2

/-- Uniqueness: two solutions with the same starting data agree, as long as the wave equation
holds for both at every time between `0` and `t`. -/
lemma wave_uniq_gen (c : ℝ) (u v : ℝ → ℝ → ℝ) (hu : ContDiff ℝ 2 (fun p : ℝ × ℝ => u p.1 p.2))
    (hv : ContDiff ℝ 2 (fun p : ℝ × ℝ => v p.1 p.2)) (x t : ℝ)
    (hwu : ∀ x' t', t' ∈ Set.uIcc 0 t → deriv (fun t => deriv (fun t => u x' t) t) t' =
        c ^ 2 * deriv (fun x => deriv (fun x => u x t') x) x')
    (hwv : ∀ x' t', t' ∈ Set.uIcc 0 t → deriv (fun t => deriv (fun t => v x' t) t) t' =
        c ^ 2 * deriv (fun x => deriv (fun x => v x t') x) x')
    (h0 : ∀ y, u y 0 = v y 0)
    (h1 : ∀ y, deriv (fun t => u y t) 0 = deriv (fun t => v y t) 0) :
    u x t = v x t := by
  have hd0 : ∀ z, deriv (fun y => u y 0) z = deriv (fun y => v y 0) z := by
    intro z; rw [show (fun y => u y 0) = (fun y => v y 0) from funext h0]
  have key := wave_aux_const (φ := fun r => u x r - v x r)
    (φ' := fun r => fderiv ℝ (fun p : ℝ × ℝ => u p.1 p.2) (x, r) (0, 1) -
      fderiv ℝ (fun p : ℝ × ℝ => v p.1 p.2) (x, r) (0, 1))
    (fun r => HasDerivAt.sub (wave_dt u hu x r) (wave_dt v hv x r)) t
    (fun r hr => by
      have hsub : Set.uIcc 0 r ⊆ Set.uIcc 0 t := Set.uIcc_subset_uIcc Set.left_mem_uIcc hr
      have eu := wave_ut_formula c u hu x r (fun x' t' ht' => hwu x' t' (hsub ht'))
      have ev := wave_ut_formula c v hv x r (fun x' t' ht' => hwv x' t' (hsub ht'))
      rw [(wave_dt u hu x r).deriv] at eu
      rw [(wave_dt v hv x r).deriv] at ev
      show _ - _ = (0 : ℝ)
      rw [sub_eq_zero, eu, ev, h1 (x - c * r), h1 (x + c * r), hd0 (x - c * r),
        hd0 (x + c * r)])
  rw [h0 x, sub_self, sub_eq_zero] at key
  exact key

/-- Domain of dependence (same statement as `wave_domain_of_dependence`). -/
lemma wave_dod_aux (c : ℝ) (hc : 0 < c) (u v : ℝ → ℝ → ℝ)
    (hu : ContDiff ℝ 2 (fun p : ℝ × ℝ => u p.1 p.2))
    (hv : ContDiff ℝ 2 (fun p : ℝ × ℝ => v p.1 p.2))
    (hwu : ∀ x t, 0 ≤ t → deriv (fun t => deriv (fun t => u x t) t) t =
        c ^ 2 * deriv (fun x => deriv (fun x => u x t) x) x)
    (hwv : ∀ x t, 0 ≤ t → deriv (fun t => deriv (fun t => v x t) t) t =
        c ^ 2 * deriv (fun x => deriv (fun x => v x t) x) x)
    (x₀ t₀ : ℝ) (ht₀ : 0 ≤ t₀)
    (hshape : ∀ y ∈ Set.Icc (x₀ - c * t₀) (x₀ + c * t₀), u y 0 = v y 0)
    (hvel : ∀ y ∈ Set.Icc (x₀ - c * t₀) (x₀ + c * t₀),
        deriv (fun t => u y t) 0 = deriv (fun t => v y t) 0) :
    u x₀ t₀ = v x₀ t₀ := by
  have hd0 : ∀ z ∈ Set.Ioo (x₀ - c * t₀) (x₀ + c * t₀),
      deriv (fun y => u y 0) z = deriv (fun y => v y 0) z := by
    intro z hz
    apply Filter.EventuallyEq.deriv_eq
    filter_upwards [Ioo_mem_nhds hz.1 hz.2] with y hy
    exact hshape y (Set.Ioo_subset_Icc_self hy)
  have hcont : ContinuousOn (fun r => u x₀ r - v x₀ r) (Set.Icc 0 t₀) :=
    (continuous_iff_continuousAt.2 fun r =>
      (HasDerivAt.sub (wave_dt u hu x₀ r) (wave_dt v hv x₀ r)).continuousAt).continuousOn
  have hct : 0 ≤ c * t₀ := mul_nonneg hc.le ht₀
  have key := constant_of_has_deriv_right_zero hcont (fun r hr => ?_) t₀ ⟨ht₀, le_rfl⟩
  · rw [hshape x₀ ⟨by linarith, by linarith⟩, sub_self, sub_eq_zero] at key
    exact key
  · have hd := HasDerivAt.sub (wave_dt u hu x₀ r) (wave_dt v hv x₀ r)
    have hr0 : 0 ≤ r := hr.1
    have hsub : ∀ t' ∈ Set.uIcc 0 r, 0 ≤ t' := by
      intro t' ht'; rw [Set.uIcc_of_le hr0] at ht'; exact ht'.1
    have eu := wave_ut_formula c u hu x₀ r (fun x' t' ht' => hwu x' t' (hsub t' ht'))
    have ev := wave_ut_formula c v hv x₀ r (fun x' t' ht' => hwv x' t' (hsub t' ht'))
    rw [(wave_dt u hu x₀ r).deriv] at eu
    rw [(wave_dt v hv x₀ r).deriv] at ev
    have hcr : c * r < c * t₀ := mul_lt_mul_of_pos_left hr.2 hc
    have hcr0 : 0 ≤ c * r := mul_nonneg hc.le hr0
    have m1 : x₀ - c * r ∈ Set.Ioo (x₀ - c * t₀) (x₀ + c * t₀) :=
      ⟨by linarith, by linarith⟩
    have m2 : x₀ + c * r ∈ Set.Ioo (x₀ - c * t₀) (x₀ + c * t₀) :=
      ⟨by linarith, by linarith⟩
    have hz : fderiv ℝ (fun p : ℝ × ℝ => u p.1 p.2) (x₀, r) (0, 1) -
        fderiv ℝ (fun p : ℝ × ℝ => v p.1 p.2) (x₀, r) (0, 1) = 0 := by
      rw [sub_eq_zero, eu, ev, hvel _ (Set.Ioo_subset_Icc_self m1),
        hvel _ (Set.Ioo_subset_Icc_self m2), hd0 _ m1, hd0 _ m2]
    rw [hz] at hd
    exact hd.hasDerivWithinAt

/-- A twice-differentiable function of the sliding variables. -/
lemma wave_prof_contDiff {A B : ℝ → ℝ} (hA : ContDiff ℝ 2 A) (hB : ContDiff ℝ 2 B) (c : ℝ) :
    ContDiff ℝ 2 (fun p : ℝ × ℝ => A (p.1 - c * p.2) + B (p.1 + c * p.2)) :=
  (hA.comp (contDiff_fst.sub (contDiff_const.mul contDiff_snd))).add
    (hB.comp (contDiff_fst.add (contDiff_const.mul contDiff_snd)))

lemma wave_lin_t {A : ℝ → ℝ} (hA : Differentiable ℝ A) (c x t : ℝ) :
    HasDerivAt (fun t => A (x - c * t)) (deriv A (x - c * t) * (-c)) t := by
  have h1 : HasDerivAt (fun t => x - c * t) (-c) t := by
    simpa using HasDerivAt.const_sub x (HasDerivAt.const_mul c (hasDerivAt_id' t))
  exact (hA _).hasDerivAt.comp t h1

lemma wave_lin_t' {A : ℝ → ℝ} (hA : Differentiable ℝ A) (c x t : ℝ) :
    HasDerivAt (fun t => A (x + c * t)) (deriv A (x + c * t) * c) t := by
  have h1 : HasDerivAt (fun t => x + c * t) c t := by
    simpa using HasDerivAt.const_add x (HasDerivAt.const_mul c (hasDerivAt_id' t))
  exact (hA _).hasDerivAt.comp t h1

lemma wave_lin_x {A : ℝ → ℝ} (hA : Differentiable ℝ A) (c x t : ℝ) :
    HasDerivAt (fun x => A (x - c * t)) (deriv A (x - c * t)) x := by
  have h1 : HasDerivAt (fun x => x - c * t) 1 x := HasDerivAt.sub_const _ (hasDerivAt_id' x)
  have h2 := (hA _).hasDerivAt.comp x h1
  rw [mul_one] at h2
  exact h2

lemma wave_lin_x' {A : ℝ → ℝ} (hA : Differentiable ℝ A) (c x t : ℝ) :
    HasDerivAt (fun x => A (x + c * t)) (deriv A (x + c * t)) x := by
  have h1 : HasDerivAt (fun x => x + c * t) 1 x := HasDerivAt.add_const _ (hasDerivAt_id' x)
  have h2 := (hA _).hasDerivAt.comp x h1
  rw [mul_one] at h2
  exact h2

lemma wave_prof_dt {A B : ℝ → ℝ} (hA : Differentiable ℝ A) (hB : Differentiable ℝ B)
    (c x t : ℝ) :
    HasDerivAt (fun t => A (x - c * t) + B (x + c * t))
      (deriv A (x - c * t) * (-c) + deriv B (x + c * t) * c) t :=
  HasDerivAt.add (wave_lin_t hA c x t) (wave_lin_t' hB c x t)

lemma wave_d2 {A : ℝ → ℝ} (hA : ContDiff ℝ 2 A) : Differentiable ℝ (deriv A) := by
  have h : ContDiff ℝ (1 + 1) A := by norm_num; exact hA
  exact ((contDiff_succ_iff_deriv.1 h).2.2).differentiable (by norm_num)

/-- A sum of a right-moving and a left-moving profile solves the wave equation. -/
lemma wave_prof_wave {A B : ℝ → ℝ} (hA : ContDiff ℝ 2 A) (hB : ContDiff ℝ 2 B) (c x t : ℝ) :
    deriv (fun t => deriv (fun t => A (x - c * t) + B (x + c * t)) t) t =
      c ^ 2 * deriv (fun x => deriv (fun x => A (x - c * t) + B (x + c * t)) x) x := by
  have hA1 : Differentiable ℝ A := hA.differentiable (by norm_num)
  have hB1 : Differentiable ℝ B := hB.differentiable (by norm_num)
  have hA2 := wave_d2 hA
  have hB2 := wave_d2 hB
  have et : (fun t => deriv (fun t => A (x - c * t) + B (x + c * t)) t) =
      fun t => deriv A (x - c * t) * (-c) + deriv B (x + c * t) * c :=
    funext fun t => (wave_prof_dt hA1 hB1 c x t).deriv
  have ex : (fun x => deriv (fun x => A (x - c * t) + B (x + c * t)) x) =
      fun x => deriv A (x - c * t) + deriv B (x + c * t) :=
    funext fun x => (HasDerivAt.add (wave_lin_x hA1 c x t) (wave_lin_x' hB1 c x t)).deriv
  have h1 : HasDerivAt (fun t => deriv A (x - c * t) * (-c) + deriv B (x + c * t) * c)
      (deriv (deriv A) (x - c * t) * (-c) * (-c) + deriv (deriv B) (x + c * t) * c * c) t :=
    HasDerivAt.add (HasDerivAt.mul_const (wave_lin_t hA2 c x t) (-c))
      (HasDerivAt.mul_const (wave_lin_t' hB2 c x t) c)
  have h2 : HasDerivAt (fun x => deriv A (x - c * t) + deriv B (x + c * t))
      (deriv (deriv A) (x - c * t) + deriv (deriv B) (x + c * t)) x :=
    HasDerivAt.add (wave_lin_x hA2 c x t) (wave_lin_x' hB2 c x t)
  rw [et, ex, h1.deriv, h2.deriv]
  ring

/-- D'Alembert's integral formula, rewritten as a right-moving plus a left-moving profile. -/
lemma wave_dal_profile (c : ℝ) (hc : c ≠ 0) (f g : ℝ → ℝ) (hf : ContDiff ℝ 2 f)
    (hg : ContDiff ℝ 1 g) :
    ∃ A B : ℝ → ℝ, ContDiff ℝ 2 A ∧ ContDiff ℝ 2 B ∧
      (∀ x t, (f (x - c * t) + f (x + c * t)) / 2 +
          1 / (2 * c) * ∫ s in (x - c * t)..(x + c * t), g s = A (x - c * t) + B (x + c * t)) ∧
      (∀ y, A y + B y = f y) ∧
      (∀ y, deriv A y * (-c) + deriv B y * c = g y) := by
  obtain ⟨P, hP⟩ : ∃ P : ℝ → ℝ, P = fun y => ∫ s in (0 : ℝ)..y, g s := ⟨_, rfl⟩
  have hPd : ∀ y, HasDerivAt P (g y) y := by
    intro y; rw [hP]; exact (hg.continuous.integral_hasStrictDerivAt 0 y).hasDerivAt
  have hPc : ContDiff ℝ 2 P := by
    have h : ContDiff ℝ (1 + 1) P := by
      rw [contDiff_succ_iff_deriv]
      refine ⟨fun y => (hPd y).differentiableAt, by simp, ?_⟩
      rw [show deriv P = g from funext fun y => (hPd y).deriv]
      exact hg
    norm_num at h; exact h
  have hf1 : Differentiable ℝ f := hf.differentiable (by norm_num)
  refine ⟨fun y => f y / 2 - P y / (2 * c), fun y => f y / 2 + P y / (2 * c),
    (hf.div_const 2).sub (hPc.div_const _), (hf.div_const 2).add (hPc.div_const _), ?_, ?_, ?_⟩
  · intro x t
    have : ∫ s in (x - c * t)..(x + c * t), g s = P (x + c * t) - P (x - c * t) := by
      rw [hP]
      exact (intervalIntegral.integral_interval_sub_left
        (hg.continuous.intervalIntegrable _ _) (hg.continuous.intervalIntegrable _ _)).symm
    rw [this]
    field_simp
    ring
  · intro y; ring
  · intro y
    have dA : HasDerivAt (fun y => f y / 2 - P y / (2 * c)) (deriv f y / 2 - g y / (2 * c)) y :=
      HasDerivAt.sub ((hf1 y).hasDerivAt.div_const 2) ((hPd y).div_const _)
    have dB : HasDerivAt (fun y => f y / 2 + P y / (2 * c)) (deriv f y / 2 + g y / (2 * c)) y :=
      HasDerivAt.add ((hf1 y).hasDerivAt.div_const 2) ((hPd y).div_const _)
    rw [dA.deriv, dB.deriv]
    field_simp
    ring

#print axioms wave_aux_const
#print axioms wave_hasDerivAt1
#print axioms wave_hasDerivAt2
#print axioms wave_symm
#print axioms wave_dt
#print axioms wave_dx
#print axioms wave_dtt
#print axioms wave_dxx
#print axioms wave_char_a
#print axioms wave_char_b
#print axioms wave_ut_formula
#print axioms wave_uniq_gen
#print axioms wave_dod_aux
#print axioms wave_prof_contDiff
#print axioms wave_lin_t
#print axioms wave_lin_t'
#print axioms wave_lin_x
#print axioms wave_lin_x'
#print axioms wave_prof_dt
#print axioms wave_d2
#print axioms wave_prof_wave
#print axioms wave_dal_profile

/-- D'Alembert's formula. On a whole line with wave speed `c > 0`, take a starting shape `f`
that is twice continuously differentiable and a starting velocity `g` that is once continuously
differentiable. Then
`u(x,t) = (f(x - ct) + f(x + ct)) / 2 + (1 / 2c) ∫_{x-ct}^{x+ct} g(s) ds`
is twice continuously differentiable, solves the wave equation `u_tt = c^2 u_xx`, starts with
shape `f` and velocity `g`, and is the only such solution for `t ≥ 0`: any twice continuously
differentiable `v` solving the wave equation for `t ≥ 0` with the same starting shape and
velocity equals `u` at every `x` and every `t ≥ 0`. In particular, released from rest (`g = 0`)
the motion is two half-copies of `f`, one sliding each way. -/
theorem dalembert_formula (c : ℝ) (hc : 0 < c) (f g : ℝ → ℝ)
    (hf : ContDiff ℝ 2 f) (hg : ContDiff ℝ 1 g) :
    let u : ℝ → ℝ → ℝ := fun x t =>
      (f (x - c * t) + f (x + c * t)) / 2 + 1 / (2 * c) * ∫ s in (x - c * t)..(x + c * t), g s
    ContDiff ℝ 2 (fun p : ℝ × ℝ => u p.1 p.2) ∧
    (∀ x t, deriv (fun t => deriv (fun t => u x t) t) t =
        c ^ 2 * deriv (fun x => deriv (fun x => u x t) x) x) ∧
    (∀ x, u x 0 = f x) ∧
    (∀ x, deriv (fun t => u x t) 0 = g x) ∧
    (∀ v : ℝ → ℝ → ℝ, ContDiff ℝ 2 (fun p : ℝ × ℝ => v p.1 p.2) →
      (∀ x t, 0 ≤ t → deriv (fun t => deriv (fun t => v x t) t) t =
        c ^ 2 * deriv (fun x => deriv (fun x => v x t) x) x) →
      (∀ x, v x 0 = f x) →
      (∀ x, deriv (fun t => v x t) 0 = g x) →
      ∀ x t, 0 ≤ t → v x t = u x t) := by
  intro u
  obtain ⟨A, B, hA, hB, hrep, hsum, hder⟩ := wave_dal_profile c hc.ne' f g hf hg
  have hA1 : Differentiable ℝ A := hA.differentiable (by norm_num)
  have hB1 : Differentiable ℝ B := hB.differentiable (by norm_num)
  have hu : u = fun x t => A (x - c * t) + B (x + c * t) := by
    funext x t; exact hrep x t
  rw [hu]
  refine ⟨wave_prof_contDiff hA hB c, fun x t => wave_prof_wave hA hB c x t, fun x => ?_,
    fun x => ?_, ?_⟩
  · simp [hsum]
  · rw [(wave_prof_dt hA1 hB1 c x 0).deriv]
    simpa using hder x
  · intro v hv hwv hv0 hv1 x t ht
    apply wave_uniq_gen c v (fun x t => A (x - c * t) + B (x + c * t)) hv
      (wave_prof_contDiff hA hB c) x t
    · intro x' t' ht'
      apply hwv
      rw [Set.uIcc_of_le ht] at ht'
      exact ht'.1
    · intro x' t' _
      exact wave_prof_wave hA hB c x' t'
    · intro y
      simp [hv0, hsum]
    · intro y
      rw [hv1, (wave_prof_dt hA1 hB1 c y 0).deriv]
      simpa using (hder y).symm

/-- Every motion is one shape sliding right plus one shape sliding left. If `u` is twice
continuously differentiable on the whole `(x, t)` plane and solves `u_tt = c^2 u_xx` with
`c > 0`, then there are twice continuously differentiable profiles `F` and `G` with
`u(x,t) = F(x - ct) + G(x + ct)` everywhere. -/
theorem wave_solution_eq_sliding_profiles (c : ℝ) (hc : 0 < c) (u : ℝ → ℝ → ℝ)
    (hu : ContDiff ℝ 2 (fun p : ℝ × ℝ => u p.1 p.2))
    (hwave : ∀ x t, deriv (fun t => deriv (fun t => u x t) t) t =
        c ^ 2 * deriv (fun x => deriv (fun x => u x t) x) x) :
    ∃ F G : ℝ → ℝ, ContDiff ℝ 2 F ∧ ContDiff ℝ 2 G ∧
      ∀ x t, u x t = F (x - c * t) + G (x + c * t) := by
  have hf : ContDiff ℝ 2 (fun y => u y 0) := hu.comp (contDiff_id.prodMk contDiff_const)
  have hg : ContDiff ℝ 1 (fun y => deriv (fun t => u y t) 0) := by
    have e : (fun y => deriv (fun t => u y t) 0) =
        fun y => fderiv ℝ (fun p : ℝ × ℝ => u p.1 p.2) (y, 0) (0, 1) :=
      funext fun y => (wave_dt u hu y 0).deriv
    rw [e]
    have hD : ContDiff ℝ 1 (fderiv ℝ (fun p : ℝ × ℝ => u p.1 p.2)) :=
      hu.fderiv_right (by norm_num)
    exact (hD.comp (contDiff_id.prodMk contDiff_const)).clm_apply contDiff_const
  obtain ⟨A, B, hA, hB, -, hsum, hder⟩ := wave_dal_profile c hc.ne' _ _ hf hg
  have hA1 : Differentiable ℝ A := hA.differentiable (by norm_num)
  have hB1 : Differentiable ℝ B := hB.differentiable (by norm_num)
  refine ⟨A, B, hA, hB, fun x t => ?_⟩
  exact wave_uniq_gen c u (fun x t => A (x - c * t) + B (x + c * t)) hu
    (wave_prof_contDiff hA hB c) x t (fun x' t' _ => hwave x' t')
    (fun x' t' _ => wave_prof_wave hA hB c x' t')
    (fun y => by simp [hsum])
    (fun y => by
      rw [(wave_prof_dt hA1 hB1 c y 0).deriv]
      simpa using (hder y).symm)

/-- Domain of dependence. Take two twice continuously differentiable solutions of
`u_tt = c^2 u_xx` (`c > 0`) for `t ≥ 0`. If their starting shapes and starting velocities agree
on the interval from `x₀ - c t₀` to `x₀ + c t₀`, with `t₀ ≥ 0`, then the two heights agree at
position `x₀` and time `t₀`: a point feels only the starting data within distance `c t₀`. -/
theorem wave_domain_of_dependence (c : ℝ) (hc : 0 < c) (u v : ℝ → ℝ → ℝ)
    (hu : ContDiff ℝ 2 (fun p : ℝ × ℝ => u p.1 p.2))
    (hv : ContDiff ℝ 2 (fun p : ℝ × ℝ => v p.1 p.2))
    (hwu : ∀ x t, 0 ≤ t → deriv (fun t => deriv (fun t => u x t) t) t =
        c ^ 2 * deriv (fun x => deriv (fun x => u x t) x) x)
    (hwv : ∀ x t, 0 ≤ t → deriv (fun t => deriv (fun t => v x t) t) t =
        c ^ 2 * deriv (fun x => deriv (fun x => v x t) x) x)
    (x₀ t₀ : ℝ) (ht₀ : 0 ≤ t₀)
    (hshape : ∀ y ∈ Set.Icc (x₀ - c * t₀) (x₀ + c * t₀), u y 0 = v y 0)
    (hvel : ∀ y ∈ Set.Icc (x₀ - c * t₀) (x₀ + c * t₀),
        deriv (fun t => u y t) 0 = deriv (fun t => v y t) 0) :
    u x₀ t₀ = v x₀ t₀ :=
  wave_dod_aux c hc u v hu hv hwu hwv x₀ t₀ ht₀ hshape hvel

-- Rope speed: c = sqrt(T / ρ) with T = 0.05 N = 1/20 N and ρ = 0.2 kg/m = 1/5 kg/m gives 1/2 m/s.
example : Real.sqrt ((1 / 20 : ℝ) / (1 / 5)) = 1 / 2 := by
  rw [show (1 / 20 : ℝ) / (1 / 5) = (1 / 2) ^ 2 by norm_num]
  exact Real.sqrt_sq (by norm_num)

-- Rope arrival at 1 m: 1 m ÷ 1/2 m/s = 2 s; the mistake T/ρ = 1/4 m/s would give 4 s.
example : (1 : ℝ) / (1 / 2) = 2 := by norm_num
example : (1 : ℝ) / ((1 / 20) / (1 / 5)) = 4 := by norm_num

-- Pinch exponents ((x - 1/2) / (1/20))^2 in the worked table: 1 at x = 9/20 and 11/20,
-- 64 at x = 9/10, 16 at x = 3/10 and 7/10.
example : (((9 / 20 : ℚ) - 1 / 2) / (1 / 20)) ^ 2 = 1 := by norm_num
example : (((11 / 20 : ℚ) - 1 / 2) / (1 / 20)) ^ 2 = 1 := by norm_num
example : (((9 / 10 : ℚ) - 1 / 2) / (1 / 20)) ^ 2 = 64 := by norm_num
example : (((3 / 10 : ℚ) - 1 / 2) / (1 / 20)) ^ 2 = 16 := by norm_num
example : (((7 / 10 : ℚ) - 1 / 2) / (1 / 20)) ^ 2 = 16 := by norm_num

-- Bump peaks start 1/2 m from each held end, so at c = 1 m/s they reach the ends at 1/2 s.
example : ((1 : ℚ) - 1 / 2) / 1 = 1 / 2 := by norm_num

#print axioms dalembert_formula
#print axioms wave_solution_eq_sliding_profiles
#print axioms wave_domain_of_dependence
```

**Checked 2026-11-13 on macOS, Lean 4.36.0-rc2, Mathlib v4.36.0-rc2. Every proof is complete and uses only Lean's standard axioms. Output, pasted from the run:**

```
'wave_aux_const' depends on axioms: [propext, Classical.choice, Quot.sound]
'wave_hasDerivAt1' depends on axioms: [propext, Classical.choice, Quot.sound]
'wave_hasDerivAt2' depends on axioms: [propext, Classical.choice, Quot.sound]
'wave_symm' depends on axioms: [propext, Classical.choice, Quot.sound]
'wave_dt' depends on axioms: [propext, Classical.choice, Quot.sound]
'wave_dx' depends on axioms: [propext, Classical.choice, Quot.sound]
'wave_dtt' depends on axioms: [propext, Classical.choice, Quot.sound]
'wave_dxx' depends on axioms: [propext, Classical.choice, Quot.sound]
'wave_char_a' depends on axioms: [propext, Classical.choice, Quot.sound]
'wave_char_b' depends on axioms: [propext, Classical.choice, Quot.sound]
'wave_ut_formula' depends on axioms: [propext, Classical.choice, Quot.sound]
'wave_uniq_gen' depends on axioms: [propext, Classical.choice, Quot.sound]
'wave_dod_aux' depends on axioms: [propext, Classical.choice, Quot.sound]
'wave_prof_contDiff' depends on axioms: [propext, Classical.choice, Quot.sound]
'wave_lin_t' depends on axioms: [propext, Classical.choice, Quot.sound]
'wave_lin_t'' depends on axioms: [propext, Classical.choice, Quot.sound]
'wave_lin_x' depends on axioms: [propext, Classical.choice, Quot.sound]
'wave_lin_x'' depends on axioms: [propext, Classical.choice, Quot.sound]
'wave_prof_dt' depends on axioms: [propext, Classical.choice, Quot.sound]
'wave_d2' depends on axioms: [propext, Classical.choice, Quot.sound]
'wave_prof_wave' depends on axioms: [propext, Classical.choice, Quot.sound]
'wave_dal_profile' depends on axioms: [propext, Classical.choice, Quot.sound]
'dalembert_formula' depends on axioms: [propext, Classical.choice, Quot.sound]
'wave_solution_eq_sliding_profiles' depends on axioms: [propext, Classical.choice, Quot.sound]
'wave_domain_of_dependence' depends on axioms: [propext, Classical.choice, Quot.sound]
```

### The picture: the rope pulse passing the 1 m mark

```mermaid
%%{init: {"theme": "base", "themeVariables": {"xyChart": {"backgroundColor": "#fffaf0", "titleColor": "#1d1d1d", "xAxisLabelColor": "#1d1d1d", "xAxisTitleColor": "#1d1d1d", "xAxisTickColor": "#1d1d1d", "xAxisLineColor": "#1d1d1d", "yAxisLabelColor": "#1d1d1d", "yAxisTitleColor": "#1d1d1d", "yAxisTickColor": "#1d1d1d", "yAxisLineColor": "#1d1d1d", "plotColorPalette": "#e76f51, #2a9d8f, #264653"}}}}%%
xychart-beta
    title "Rope height 1 m from the flicked end, c = 0.5 m/s"
    x-axis "Time since the flick, s" [1.90, 1.95, 2.00, 2.05, 2.10, 2.15, 2.20, 2.25, 2.30, 2.35, 2.40, 2.45, 2.50]
    y-axis "Height, cm" 0 --> 4.5
    line [0.00, 0.00, 0.00, 0.33, 1.69, 3.30, 4.00, 3.30, 1.69, 0.33, 0.00, 0.00, 0.00]
```

The line: the formula with its velocity term.

> [!TIP]
> **Try changing**
> - **Guess first:** the grid with `r=1.0`? *Answer:* the gap drops to zero at the printed precision; the wave then moves exactly one point per step, so the fourfold assert fails for a good reason.
> - **Guess first:** `r=1.1`? *Answer:* the grid blows up. The wave crosses more than one point per step, but the grid passes news only one point per step: its domain of dependence misses the true one.
> - **Guess first:** `C` set to 2.0? *Answer:* by 0.2 s the bumps' tails touch the held ends, which the whole-line formula ignores; the gap stops shrinking.
> - **Guess first:** `-c * dp` changed to `c * dp`? *Answer:* the pulse runs left, the rope at 1 m stays flat, the third assert fails.

---

## The usual mistake

> [!warning]
> **Giving only the starting shape.** Two time rates need two pieces of starting data, shape and velocity. Leave out $g$ and the rope's 4 cm pulse arrives as 2.000000 cm.
>
> - **Reading the halves as decay.** Two half-height copies carry the whole disturbance; nothing is lost.
> - **Speed as T over ρ.** The square root gives 0.50 m/s; without it the pulse is timed at 4.00 s.
> - **The whole-line formula past 0.50 s.** Then the bumps reach the held ends.

---

## Where you meet it in real life

- **Musical strings.** A plucked string splits into two copies that reflect off the nut and bridge. Tuning pegs change $T$, so $c$ and the pitch.
- **Sound and light.** Pressure in a pipe, voltage on a cable and light obey the same equation ([Electromagnetic waves](../../13-Engineering%20mathematics/06-Circuits%20and%20Electromagnetism/08-electromagnetic-waves.md)).
- **Earthquake timing.** A distant seismometer feels nothing until the fastest wave arrives: distance over speed.
- **Simulation.** A grid solver's time step must keep its domain of dependence covering the true one.

> **Say it back**
> Newton's law on a piece of string: acceleration equals speed squared times bending, speed the square root of tension over mass per metre. In riding coordinates, every solution is one shape sliding right plus one sliding left. Shape and velocity at the start fix both: from rest, each is half the shape. The height at a point depends only on starting data within distance ct, so nothing arrives before distance over speed.

---

## What this builds on

- [The transport equation](02-the-transport-equation-and-characteristics.md): one shape sliding one way, carried along a line.
- [Chain rule](../../06-Calculus%20and%20analysis/02-Derivatives/03-chain-rule.md): the factors $-c$ and $+c$ in Steps 2 and 3.

## Where this goes next

- [Standing waves](06-standing-waves-on-a-string.md): the finite string, where reflected copies add into standing patterns.
- [Electromagnetic waves](../../13-Engineering%20mathematics/06-Circuits%20and%20Electromagnetism/08-electromagnetic-waves.md): the same equation for light.
- d'Alembert: characteristics, energy and uniqueness in full.

The formula leaves open what the string does once the copies hit the held ends at 0.50 s.

---

## Sources

Verified 2026-09-28: every link below resolves to a page naming the work.

- Strauss, Walter A. *Partial Differential Equations: An Introduction*, 2nd ed. Wiley, 2008. [Book page](https://books.google.com/books?vid=ISBN9780470054567). D'Alembert's formula and the domain of dependence.
- Lebl, Jiří. *Notes on Diffy Qs*, §4.8. [D'Alembert solution of the wave equation](https://www.jirka.org/diffyqs/html/dalemb_section.html). Free; riding coordinates and the formula.
- Olver, Peter J. *Introduction to Partial Differential Equations*. Springer, 2014. [Author's book page](https://www-users.cse.umn.edu/~olver/pde.html). The factored form and finite differences for waves.
- O'Connor, J. J., and E. F. Robertson. "Jean le Rond d'Alembert." MacTutor Archive, University of St Andrews. [Biography](https://mathshistory.st-andrews.ac.uk/Biographies/DAlembert/). Dates the 1747 vibrating-strings article, the equation's first printing.
