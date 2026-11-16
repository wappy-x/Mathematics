// Densities add by convolution -- the check behind the card.  std only, no crates.
// Packing delay X uniform on [0, 2] h, courier delay Y uniform on [0, 3] h, independent.
// Roads to the total S = X + Y: the trapezoid by hand, the convolution integral,
// step laws convolved on a grid, the transform product inverted, and simulation.
use std::f64::consts::PI;

const A: f64 = 2.0; // width of the packing delay, hours
const B: f64 = 3.0; // width of the courier delay, hours
const D: f64 = 4.0; // the promise, hours; widths whole, A <= B <= D <= A + B
const M: f64 = (A + B) / 2.0; // centre of the total

fn f(x: f64) -> f64 { if (0.0..A).contains(&x) { 1.0 / A } else { 0.0 } }
fn g(y: f64) -> f64 { if (0.0..B).contains(&y) { 1.0 / B } else { 0.0 } }
fn trap(s: f64) -> f64 { (A.min(s) - (s - B).max(0.0)).max(0.0) / (A * B) } // overlap / (A B)
fn conv(s: f64) -> f64 {
    // midpoint sum of the integral of f(x) g(s - x) dx
    let n = 6000;
    let dx = A / n as f64;
    (0..n).map(|k| { let x = (k as f64 + 0.5) * dx; f(x) * g(s - x) }).sum::<f64>() * dx
}
fn simpson(fun: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let hh = (b - a) / n as f64;
    let mut tot = 0.0;
    for k in 0..=n {
        let w = if k == 0 || k == n { 1.0 } else if k % 2 == 1 { 4.0 } else { 2.0 };
        tot += w * fun(a + k as f64 * hh);
    }
    hh / 3.0 * tot
}
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a } else { gcd(b, a % b) } }
fn sinc(u: f64) -> f64 { if u == 0.0 { 1.0 } else { (PI * u).sin() / (PI * u) } }
fn phi(z: f64) -> f64 {
    // standard bell's area left of z, by its power series
    let (mut t, mut s, mut n) = (z, z, 0.0);
    while t.abs() > 1e-17 {
        n += 1.0;
        t *= -z * z / (2.0 * n);
        s += t / (2.0 * n + 1.0);
    }
    0.5 + s / (2.0 * PI).sqrt()
}
fn bell(s: f64, m: f64, v: f64) -> f64 { (-(s - m).powi(2) / (2.0 * v)).exp() / (2.0 * PI * v).sqrt() }
struct Rng(u64); // SplitMix64, seed 2026, top 53 bits
impl Rng {
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 2f64.powi(53)
    }
}
fn row(name: &str, fun: &dyn Fn(f64) -> f64, dp: usize) {
    let v: Vec<String> = (0..21).map(|k| format!("{:.*}", dp, fun(k as f64 / 4.0))).collect();
    println!("chart {}: {}", name, v.join(" "));
}

fn main() {
    println!("X uniform on [0, {:.1}] h, Y uniform on [0, {:.1}] h, independent; S = X + Y; promise D = {:.1} h", A, B, D);
    for s in [1.0, M, 4.0] {
        println!("h({:.1}) trapezoid {:.6}  convolution integral {:.6}", s, trap(s), conv(s));
        assert!((trap(s) - conv(s)).abs() < 1e-9);
    }
    let (late, den) = (((A + B - D) as i64).pow(2), 2 * (A * B) as i64); // late corner: triangle of side A + B - D
    let (g0, num) = (gcd(den - late, den), den - late);
    let (num, den) = (num / g0, den / g0);
    let exact = num as f64 / den as f64;
    let area = simpson(&trap, 0.0, A, 200) + simpson(&trap, A, B, 100) + simpson(&trap, B, D, 100);
    let shown = if den == 1 { format!("{}", num) } else { format!("{}/{}", num, den) };
    let lg = gcd(late, 2 * (A * B) as i64);
    let lshown = if late == 0 { "0".to_string() } else { format!("{}/{}", late / lg, 2 * (A * B) as i64 / lg) };
    println!("P(S <= D): exact {} = {:.6}  late {} = {:.6}  area under trapezoid {:.6}", shown, exact, lshown, 1.0 - exact, area);
    assert!((area - exact).abs() < 1e-12);
    let mut gap = 1.0;
    for step in [60i64, 360] {
        // step laws: X = (i + 1/2)/step, Y = (j + 1/2)/step
        let (nx, ny) = ((A * step as f64) as i64, (B * step as f64) as i64);
        let mut pmf = vec![0i64; (nx + ny - 1) as usize];
        for i in 0..nx { for j in 0..ny { pmf[(i + j) as usize] += 1; } }
        let on: i64 = pmf[..((D * step as f64) as i64 - 1) as usize].iter().sum(); // atoms below D; the atom at S = D is left out
        let tot = nx * ny;
        gap = (on * den - num * tot) as f64 / (tot * den) as f64;
        println!("grid of 1/{} h: P(S < D) {:.6}  gap {:.6}  peak h {:.6}", step, on as f64 / tot as f64, gap,
                 (pmf.iter().max().unwrap() * step) as f64 / tot as f64);
    }
    assert!(gap.abs() < 1e-3);
    let n = 200000;
    let mut rng = Rng(2026);
    let (mut hit, mut tied, mut cs, mut sn) = (0, 0, 0.0, 0.0);
    for _ in 0..n {
        let x = A * rng.unif();
        let y = B * rng.unif();
        if x + y <= D { hit += 1; }
        if x + B / A * x <= D { tied += 1; } // what breaks: Y = (B/A) X, the same storm hits both
        cs += (2.0 * PI * 0.25 * (x + y)).cos();
        sn -= (2.0 * PI * 0.25 * (x + y)).sin();
    }
    let nf = n as f64;
    let se = (exact * (1.0 - exact) / nf).sqrt();
    let ph = hit as f64 / nf;
    println!("simulated {} orders: P(S <= D) {:.4}  standard error {:.4}", n, ph, se);
    assert!((ph - exact).abs() <= 4.0 * se);
    println!("frequency: hat f(xi) = e^(-i pi A xi) sinc(A xi), xi in cycles per hour");
    let xi = 0.25;
    let mag = sinc(A * xi) * sinc(B * xi);
    let (pr, pim) = (mag * (PI * (A + B) * xi).cos(), -mag * (PI * (A + B) * xi).sin());
    let dr = simpson(&|s| trap(s) * (2.0 * PI * xi * s).cos(), 0.0, A + B, 3000);
    let di = simpson(&|s| -trap(s) * (2.0 * PI * xi * s).sin(), 0.0, A + B, 3000);
    println!("xi = 0.25: sinc(A xi) {:.6}  sinc(B xi) {:.6}  |product| {:.6}  phase {:.6} {:+.6}i", sinc(A * xi), sinc(B * xi), mag,
             (PI * (A + B) * xi).cos(), -(PI * (A + B) * xi).sin());
    println!("  product {:.6} {:+.6}i  transform of h {:.6} {:+.6}i  simulated {:.4} {:+.4}i", pr, pim, dr, di, cs / nf, sn / nf);
    assert!((pr - dr).abs() < 1e-9 && (pim - di).abs() < 1e-9);
    assert!((cs / nf - pr).abs() < 4.0 * (0.5 / nf).sqrt() && (sn / nf - pim).abs() < 4.0 * (0.5 / nf).sqrt());
    for z in [1.0 / B, 1.0 / A, 2.0 / B] {
        let re = simpson(&|s| trap(s) * (2.0 * PI * z * s).cos(), 0.0, A + B, 3000);
        let im = simpson(&|s| trap(s) * (2.0 * PI * z * s).sin(), 0.0, A + B, 3000);
        let dz = re.hypot(im);
        println!("  zero of a factor at xi = {:.6}: |transform of h| {:.6}", z, dz);
        assert!(dz < 1e-9);
    }
    for cut in [25usize, 100] {
        // invert at the centre: h(M) = integral of sinc(A xi) sinc(B xi)
        let inv = 2.0 * simpson(&|u| sinc(A * u) * sinc(B * u), 0.0, cut as f64, 400 * cut);
        let tail = 2.0 / (PI * PI * A * B * cut as f64);
        println!("inverse at s = {:.1}, cut-off {}/h: {:.9}  gap {:.9}  tail bound {:.6}", M, cut, inv, (inv - trap(M)).abs(), tail);
        assert!((inv - trap(M)).abs() <= tail);
    }
    let (v1, v2) = (A * A / 12.0, B * B / 12.0); // the same delays as bell curves, same centres and spreads
    let sd = (v1 + v2).sqrt();
    for s in [M, 4.0] {
        let num = simpson(&|x| bell(x, A / 2.0, v1) * bell(s - x, B / 2.0, v2), -9.0, 11.0, 4000);
        println!("bells: h({:.1}) convolution integral {:.6}  one bell, variances added {:.6}", s, num, bell(s, M, v1 + v2));
        assert!((num - bell(s, M, v1 + v2)).abs() < 1e-9);
    }
    let pb = phi((D - M) / sd);
    println!("bells: sd {:.6} h  P(S <= D) {:.6}  P(S < 0) {:.6}  peak {:.6}", sd, pb, phi(-M / sd), bell(M, M, v1 + v2));
    println!("centres {:.6} + {:.6} = {:.6} h; spreads added {:.6} + {:.6} = {:.6} h, true spread {:.6} h",
             A / 2.0, B / 2.0, M, v1.sqrt(), v2.sqrt(), v1.sqrt() + v2.sqrt(), sd);
    let vt: f64 = [(0.0, A), (A, B), (B, A + B)].iter().map(|&(a, b)| simpson(&|s| (s - M).powi(2) * trap(s), a, b, 300)).sum();
    println!("bells: variances {:.6} + {:.6} = {:.6} h^2; the trapezoid's own variance {:.6} h^2", v1, v2, v1 + v2, vt);
    assert!((vt - (v1 + v2)).abs() < 1e-12); // the bells get the true total's spread
    assert!((pb - 0.5 - simpson(&|z| bell(z, 0.0, 1.0), 0.0, (D - M) / sd, 2000)).abs() < 1e-12); // series against area
    let l2 = [(0.0, A), (A, B), (B, A + B)].iter().map(|&(a, b)| simpson(&|s| trap(s).powi(2), a, b, 300)).sum::<f64>().sqrt();
    let peak = (0..=(100.0 * (A + B)) as i64).map(|k| trap(k as f64 / 100.0)).fold(0.0, f64::max);
    let l2x = ((B - A / 3.0) / (B * B)).sqrt();
    println!("Young: peak h {:.6} <= |f|_1 |g|_inf {:.6} and |f|_inf |g|_1 {:.6}", peak, 1.0 / B, 1.0 / A);
    println!("Young: |h|_2 {:.6} (exact {:.6}) <= |g|_2 {:.6}  ratio {:.6}", l2, l2x, (1.0 / B).sqrt(), l2 / (1.0 / B).sqrt());
    assert!((l2 - l2x).abs() < 1e-12 && l2 <= (1.0 / B).sqrt() && peak <= 1.0 / B);
    let slope = (-100..600).map(|k| ((trap(k as f64 / 100.0 + 0.01) - trap(k as f64 / 100.0)) / 0.01).abs()).fold(0.0, f64::max);
    println!("smoothing: steepest slope of h {:.6} per h^2, bound |f|_inf * 2/B {:.6}", slope, 2.0 / (A * B));
    assert!((slope - 1.0 / (A * B)).abs() < 1e-9);
    let mids: Vec<f64> = (0..(100.0 * D) as i64).map(|k| (k as f64 + 0.5) / 100.0).collect(); // midpoint sums up to the promise
    let mix = mids.iter().map(|&x| 0.5 * (f(x) + g(x))).sum::<f64>() / 100.0;
    let prod = mids.iter().map(|&x| f(x) * g(x)).sum::<f64>() / 100.0;
    let pt = tied as f64 / nf;
    println!("what breaks: mixture P {:.6}  product area {:.6}  tied delays exact {:.6} simulated {:.4}", mix, prod, D / (A + B), pt);
    assert!((pt - D / (A + B)).abs() <= 4.0 * (0.25 / nf).sqrt());
    println!("chart s: {}", (0..21).map(|k| format!("{:.2}", k as f64 / 4.0)).collect::<Vec<_>>().join(" "));
    row("f", &f, 3);
    row("g", &g, 3);
    row("h", &trap, 3);
    row("bell", &|s| bell(s, M, v1 + v2), 3);
    println!("ALL CHECKS PASS");
}
