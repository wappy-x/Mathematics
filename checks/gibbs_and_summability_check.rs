// The Gibbs overshoot and the cure -- the same check as the Python, in Rust.  No
// crates.  Square wave: +1 V on (0, pi), -1 V on (-pi, 0), x = 2 pi 220 t.
// s_part(M, x) keeps harmonics up to M; sigma(N, x) averages S_0 .. S_(N-1) (Fejer).
use std::f64::consts::PI;

fn s_part(m: usize, x: f64) -> f64 {           // the partial sum of degree M
    let mut s = 0.0;
    for n in (1..=m).step_by(2) { s += 4.0 / PI * (n as f64 * x).sin() / n as f64 }
    s
}

fn sigma(nn: usize, x: f64) -> f64 {           // road one: taper harmonic n by 1 - n/N
    let mut s = 0.0;
    for n in (1..nn).step_by(2) {
        s += (1.0 - n as f64 / nn as f64) * 4.0 / PI * (n as f64 * x).sin() / n as f64;
    }
    s
}

fn sigma_avg(nn: usize, x: f64) -> f64 {       // road two: add S_0 .. S_(N-1), divide by N
    let (mut total, mut s) = (0.0, 0.0);
    for k in 0..nn {
        if k % 2 == 1 { s += 4.0 / PI * (k as f64 * x).sin() / k as f64 }
        total += s;
    }
    total / nn as f64
}

fn fejer(nn: usize, t: f64) -> f64 {           // F_N(t) = (sin(Nt/2) / sin(t/2))^2 / N
    let d = (t / 2.0).sin();
    if d.abs() < 1e-12 { nn as f64 } else { ((nn as f64 * t / 2.0).sin() / d).powi(2) / nn as f64 }
}

fn dirichlet(m: usize, t: f64) -> f64 {        // D_M(t) = sin((M + 1/2) t) / sin(t/2)
    let d = (t / 2.0).sin();
    if d.abs() < 1e-12 { 2.0 * m as f64 + 1.0 } else { ((m as f64 + 0.5) * t).sin() / d }
}

fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {   // our own integrator
    let (h, mut s) = ((b - a) / n as f64, 0.0);
    for i in 0..=n {
        let w = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        s += g(a + i as f64 * h) * w;
    }
    s * h / 3.0
}

fn sigma_kernel(nn: usize, x: f64) -> f64 {    // road three: 1 - (1/pi) * kernel area on the -1 side
    1.0 - simpson(&|t| fejer(nn, t), x, x + PI, 20000) / PI
}

fn solve(g: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64, target: f64) -> f64 {   // bisection
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if g(mid) < target { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}

fn si(u: f64) -> f64 {                          // sine integral, power series
    let (mut s, mut term, mut k) = (0.0, u, 0.0);
    while term.abs() > 1e-17 {
        s += term / (2.0 * k + 1.0);
        k += 1.0;
        term *= -u * u / ((2.0 * k) * (2.0 * k + 1.0));
    }
    s
}

fn ramp_sine(m: usize, x: f64) -> f64 {        // odd extension of x/pi: the sawtooth, jump 2 V at pi
    let mut s = 0.0;
    for n in 1..=m {
        let sign = if n % 2 == 1 { 1.0 } else { -1.0 };
        s += 2.0 / PI * sign * (n as f64 * x).sin() / n as f64;
    }
    s
}

fn ramp_cosine(m: usize, x: f64) -> f64 {      // even extension of x/pi: the triangle, no jump
    let mut s = 0.5;
    for n in (1..=m).step_by(2) { s -= 4.0 / (PI * PI) * (n as f64 * x).cos() / (n * n) as f64 }
    s
}

fn us(x: f64) -> f64 { x / (2.0 * PI * 220.0) * 1e6 }   // radians to microseconds after the switch
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn f6(v: f64) -> String { format!("{:.6}", if v.abs() < 5e-7 { 0.0 } else { v }) }
fn join(v: &[f64]) -> String { v.iter().map(|&x| f6(x)).collect::<Vec<_>>().join(" ") }
fn hfun(u: f64) -> f64 {
    simpson(&|s| if s == 0.0 { 1.0 } else { ((s / 2.0).sin() / (s / 2.0)).powi(2) }, 0.0, u, 4000) / PI
}

fn main() {
    println!("siren: +-1 V, 220 cycles a second, 440 switches; 1 radian = {:.2} us; CD rate 44100: harmonics up to n = {}, last odd n = {} ({} Hz)",
             us(1.0), 22050 / 220, (22050 / 220 - 1) | 1, ((22050 / 220 - 1) | 1) * 220);
    println!("by hand: 4/pi = {}, sin(pi/4) = {}, S_1(pi/4) = S_2(pi/4) = {} V", f6(4.0 / PI), f6((PI / 4.0).sin()), f6(s_part(2, PI / 4.0)));
    println!("by hand: S_3(pi/4) = {} V, sigma_4(pi/4) = {} V, average of S_0..S_3 = {} V",
             f6(s_part(3, PI / 4.0)), f6(sigma(4, PI / 4.0)), f6(sigma_avg(4, PI / 4.0)));
    println!("by hand: S_3(pi/2) = {} V, sigma_4(pi/2) = {} V", f6(s_part(3, PI / 2.0)), f6(sigma(4, PI / 2.0)));
    let grid: Vec<f64> = (1..=20000).map(|j| j as f64 * PI / 20000.0).collect();
    let fmin = grid.iter().map(|&t| fejer(100, t)).fold(f64::INFINITY, f64::min);
    let dmin = grid.iter().map(|&t| dirichlet(99, t)).fold(f64::INFINITY, f64::min);
    let area = simpson(&|t| fejer(100, t), -PI, PI, 20000) / (2.0 * PI);
    println!("kernels: F_100 lowest {}, mean {}; D_99 at 0 {:.0}, lowest {:.2}", f6(fmin), f6(area), dirichlet(99, 0.0), dmin);
    let mut gaps = Vec::new();
    for nn in [20usize, 100, 500] {
        let (n, peak, at) = (nn as f64, s_part(nn - 1, PI / nn as f64), sigma(nn, PI / nn as f64));
        let g: Vec<f64> = (1..2000).map(|j| sigma(nn, j as f64 * PI / 2000.0)).collect();
        let top = g.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
        let at_mid = g.iter().position(|&v| v == top) == Some(999);
        let rises = (0..999).all(|i| g[i + 1] >= g[i]);
        let roads = [sigma(nn, PI / 2.0), sigma_avg(nn, PI / 2.0), sigma_kernel(nn, PI / 2.0)];
        let (err, bound) = (1.0 - roads[0], 2.0 / nn as f64);
        let worst = (0..=400).map(|j| 1.0 - sigma(nn, 0.1 + j as f64 * (PI - 0.2) / 400.0))
            .fold(f64::NEG_INFINITY, f64::max);
        let xs = solve(&|x| sigma(nn, x), 0.0, PI / 2.0, 0.9);
        let xp = solve(&|x| s_part(nn - 1, x), 0.0, PI / nn as f64, 0.9);
        println!("N = {}: S_{} peak {} V at x = pi/N ({:.2} us); sigma_{} there {} V",
                 nn, nn - 1, f6(peak), us(PI / n), nn, f6(at));
        println!("N = {}: sigma_{} highest {} V, at x = pi/2: {}; rises without a dip: {}",
                 nn, nn, f6(top), yn(at_mid), yn(rises));
        println!("N = {}: three roads at pi/2: {}", nn, join(&roads));
        println!("N = {}: mid-top error {} V, N x error {}, bound 2/N {}, bound/true {:.2}; worst on [0.1, pi-0.1] {} V",
                 nn, f6(err), f6(n * err), f6(bound), bound / err, f6(worst));
        println!("N = {}: reaches 0.9 V at {:.2} us (N x = {:.4}); S_{} at {:.2} us (N x = {:.4})",
                 nn, us(xs), n * xs, nn - 1, us(xp), n * xp);
        assert!((roads[0] - roads[1]).abs() < 1e-12 && (roads[0] - roads[2]).abs() < 1e-9);  // three roads
        assert!(top < 1.0 && rises && peak - 1.0 > 0.178);   // no ear for sigma; ear for S
        assert!(err <= bound);                                // the tail bound holds
        gaps.push((peak - 1.0, at, top, err, n * xs, n * xp));
    }
    let (uh, us_) = (solve(&hfun, PI, 4.0 * PI, 0.9), solve(&|u| 2.0 / PI * si(u), 0.0, PI, 0.9));
    println!("limits: (2/pi) Si(pi) = {} ({:.2}% of the jump), H(pi) = {}, 2/pi = {}, 0.9 V at N x = {:.4} (sigma), {:.4} (S)",
             f6(2.0 / PI * si(PI)), (2.0 / PI * si(PI) - 1.0) / 2.0 * 100.0, f6(hfun(PI)), f6(2.0 / PI), uh, us_);
    let step = 2.0 * PI * 220.0 * 1e-5;          // chart: every 10 microseconds, 0 to 200
    let chart = |g: &dyn Fn(f64) -> f64| (0..21).map(|k| format!("{:.2}", g(k as f64 * step))).collect::<Vec<_>>().join(" ");
    println!("chart, S_99: {}", chart(&|x| s_part(99, x)));
    println!("chart, sigma_100: {}", chart(&|x| sigma(100, x)));
    let top_b: Vec<f64> = (1..6).map(|n| 2.0 / PI * simpson(&|x| (n as f64 * x).sin(), 0.0, PI, 2000)).collect();
    let top_a: Vec<f64> = (0..5).map(|n| 2.0 / PI * simpson(&|x| (n as f64 * x).cos(), 0.0, PI, 2000)).collect();
    println!("half-range, +1 V on (0, pi): sine b_1..b_5 {}", join(&top_b));
    println!("half-range, +1 V on (0, pi): cosine a_0..a_4 {}", join(&top_a));
    let mut odd_sq = 0.0;
    for n in (1..100).step_by(2) { odd_sq += 1.0 / (n * n) as f64 }
    let tail = 4.0 / (PI * PI) * (PI * PI / 8.0 - odd_sq);
    let rb1 = 2.0 / PI * simpson(&|x| x / PI * x.sin(), 0.0, PI, 2000);
    let ra1 = 2.0 / PI * simpson(&|x| x / PI * x.cos(), 0.0, PI, 2000);
    let rover = (1..=4000).map(|j| PI - j as f64 * 0.2 / 4000.0).map(|x| ramp_sine(99, x) - x / PI)
        .fold(f64::NEG_INFINITY, f64::max);
    let rworst = (0..=2000).map(|j| (ramp_cosine(99, j as f64 * PI / 2000.0) - j as f64 / 2000.0).abs())
        .fold(f64::NEG_INFINITY, f64::max);
    println!("ramp x/pi V: b_1 {} (formula {}), a_1 {} (formula {})", f6(rb1), f6(2.0 / PI), f6(ra1), f6(-4.0 / (PI * PI)));
    println!("ramp, degree 99: sine series overshoots the ramp by {} V; cosine series worst error {} V, tail {}",
             f6(rover), f6(rworst), f6(tail));
    println!("mistake 1, last partial sum: overshoot {}, {}, {} V for N = 20, 100, 500",
             f6(gaps[0].0), f6(gaps[1].0), f6(gaps[2].0));
    println!("mistake 2, divide by N - 1 = 99: peak {} V", f6(gaps[1].2 * 100.0 / 99.0));
    let mut tone = 0.0;
    for k in 0..100 { tone += if k == 0 { 0.0 } else { (PI / 2.0).sin() } }   // S_0 of sin x is 0
    println!("mistake 3, pure tone sin x at pi/2: sigma_100 {} V, S_1 {} V", f6(tone / 100.0), f6((PI / 2.0).sin()));
    println!("mistake 4, sine series of the top half: peak {} V; cosine series {} V", f6(gaps[1].0 + 1.0), f6(top_a[0] / 2.0));
    assert!((sigma(4, PI / 4.0) - sigma_avg(4, PI / 4.0)).abs() < 1e-12 && fmin >= 0.0 && dmin < 0.0 && (area - 1.0).abs() < 1e-9);
    assert!((gaps[2].0 + 1.0 - 2.0 / PI * si(PI)).abs() < 1e-4);              // Gibbs limit, two roads
    assert!((gaps[2].1 - hfun(PI)).abs() < 1e-4 && (gaps[2].3 * 500.0 - 2.0 / PI).abs() < 1e-3);
    assert!((gaps[2].4 - uh).abs() < 0.01 && (gaps[2].5 - us_).abs() < 0.01);
    assert!((1..6).all(|n| (top_b[n - 1] - if n % 2 == 1 { 4.0 / (PI * n as f64) } else { 0.0 }).abs() < 1e-9));
    assert!((top_a[0] - 2.0).abs() < 1e-9 && top_a[1..].iter().all(|v| v.abs() < 1e-9));
    assert!((rworst - tail).abs() < 1e-9 && (rover - gaps[1].0).abs() < 1e-3 && (ra1 + 4.0 / (PI * PI)).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
