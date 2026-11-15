// The heat kernel in d dimensions: a hot spot in a 1 m copper rod, 10 s later.
// std only. erf, Simpson's rule and the grid are written out here.
use std::f64::consts::PI;

const KAPPA: f64 = 1.11e-4; // copper, m^2/s
const T: f64 = 10.0; // s
const A: f64 = 0.005; // slice half-width, m
const U0: f64 = 100.0; // K

fn sci(x: f64, p: usize) -> String { // Python's e-format: mantissa, sign, two-digit exponent
    let s = format!("{:.*e}", p, x);
    let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn erf(z: f64) -> f64 { // 2/sqrt(pi) e^(-z^2) sum 2^n z^(2n+1)/(1*3*...*(2n+1)): all terms positive
    if z < 0.0 { return -erf(-z); }
    let (mut s, mut term) = (z, z);
    for n in 1..400 {
        term *= 2.0 * z * z / (2 * n + 1) as f64; s += term;
        if term < 1e-17 * s { break; }
    }
    2.0 / PI.sqrt() * (-z * z).exp() * s
}
fn g(r2: f64, t: f64, d: i32, k: f64) -> f64 { // the kernel at squared distance r2, in d dimensions
    (-r2 / (4.0 * k * t)).exp() / (4.0 * PI * k * t).powf(d as f64 / 2.0)
}
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = 0.0;
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    h / 3.0 * (f(a) + f(b) + s)
}
fn bx(x: f64, t: f64) -> f64 { // the 1 cm slice at 100 K, spread by t seconds: closed form
    let w = 2.0 * (KAPPA * t).sqrt();
    U0 / 2.0 * (erf((x + A) / w) - erf((x - A) / w))
}
fn grid(m: usize) -> (f64, f64, f64) { // explicit grid on the whole 1 m rod, ends held at 0 K above the room
    let (nn, n) = (400 * m, 445 * m * m);
    let (h, dt) = (1.0 / nn as f64, T / n as f64);
    let r = KAPPA * dt / h.powf(2.0);
    assert!(r <= 0.5);
    let mut u: Vec<f64> = (0..=nn).map(|i| if (-0.5 + i as f64 * h).abs() < A - 1e-12 { U0 } else { 0.0 }).collect();
    for i in [nn / 2 - 2 * m, nn / 2 + 2 * m] { u[i] = U0 / 2.0; } // slice edges fall on nodes
    for _ in 0..n {
        let mut v = vec![0.0; nn + 1];
        for i in 1..nn { v[i] = u[i] + r * (u[i - 1] - 2.0 * u[i] + u[i + 1]); }
        u = v;
    }
    (u[nn / 2], h, r)
}
fn tych(x: f64, t0: f64, kk: usize) -> (f64, f64) { // Tychonoff, scaled kappa = 1: sum g^(k)(t) x^(2k)/(2k)!, g = e^(-1/t^2)
    let a: Vec<f64> = (0..=kk + 1).map(|j| -(if j % 2 == 0 { 1.0 } else { -1.0 }) * (j + 1) as f64 / t0.powf(2.0)).collect();
    let mut bk = vec![a[0].exp()];
    for k in 1..=kk + 1 {
        let mut s = 0.0;
        for j in 1..=k { s += j as f64 * a[j] * bk[k - j]; }
        bk.push(s / k as f64);
    }
    let (mut s, mut c) = (0.0, 1.0);
    for k in 0..=kk {
        s += c * bk[k];
        c *= (k + 1) as f64 / ((2 * k + 1) as f64 * (2 * k + 2) as f64) * x * x / t0;
    }
    (s, (c * bk[kk + 1]).abs()) // the sum to term kk, and the first omitted term, kk + 1
}

fn main() {
    let sig = (2.0 * KAPPA * T).sqrt();
    println!("hand: heat in the slice {:.0} K x {:.0} cm = {:.2} K m; 4 kappa t = {} m^2; sqrt(4 pi kappa t) = {:.5} m; 1/that = {:.4} per m",
        U0, 200.0 * A, U0 * 2.0 * A, sci(4.0 * KAPPA * T, 3), (4.0 * PI * KAPPA * T).sqrt(), 1.0 / (4.0 * PI * KAPPA * T).sqrt());
    println!("rod: kappa {} m^2/s, t = {:.0} s, width sqrt(2 kappa t) = {:.2} cm", sci(KAPPA, 3), T, 100.0 * sig);
    for d in 1..=3 {
        let om = [2.0, 2.0 * PI, 4.0 * PI][d as usize - 1]; // size of the unit sphere's surface
        let close = [erf(0.5f64.sqrt()), 1.0 - (-0.5f64).exp(), erf(0.5f64.sqrt()) - (2.0 / PI).sqrt() * (-0.5f64).exp()][d as usize - 1];
        let mass = simpson(|r| om * r.powf((d - 1) as f64) * g(r * r, T, d, KAPPA), 0.0, 0.5, 2000);
        let msq = simpson(|r| om * r.powf((d + 1) as f64) * g(r * r, T, d, KAPPA), 0.0, 0.5, 2000);
        let near = simpson(|r| om * r.powf((d - 1) as f64) * g(r * r, T, d, KAPPA), 0.0, sig, 2000);
        println!("d = {}: peak {} per m^{}; total {:.9}; rms distance {:.2} cm (sqrt(2 d kappa t) {:.2}); share within {:.2} cm {:.4} (closed form {:.4})",
            d, sci(g(0.0, T, d, KAPPA), 4), d, mass, 100.0 * msq.sqrt(), 100.0 * (2.0 * d as f64 * KAPPA * T).sqrt(), 100.0 * sig, near, close);
        assert!((mass - 1.0).abs() < 1e-9);
        assert!((msq - 2.0 * d as f64 * KAPPA * T).abs() < 1e-12);
        assert!((near - close).abs() < 1e-9);
    }

    let p = [0.02, 0.01, 0.01]; // the 3-d kernel put back into u_t = kappa Lap u
    let g3 = |q: [f64; 3], t: f64| g(q[0] * q[0] + q[1] * q[1] + q[2] * q[2], t, 3, KAPPA);
    let (mut res, mut ut, mut lap) = (vec![], 0.0, 0.0);
    for h in [0.002, 0.001] {
        ut = (g3(p, T + h * 50.0) - g3(p, T - h * 50.0)) / (h * 100.0);
        lap = 0.0;
        for i in 0..3 {
            let (mut up, mut dn) = (p, p);
            up[i] += h; dn[i] -= h;
            lap += (g3(up, T) - 2.0 * g3(p, T) + g3(dn, T)) / h.powf(2.0);
        }
        res.push(ut - KAPPA * lap);
    }
    println!("d = 3 at (2, 1, 1) cm: u_t = {:.4}, kappa Lap u = {:.4} per m^3 per s; residual {} then {}, ratio {:.2}",
        ut, KAPPA * lap, sci(res[0], 3), sci(res[1], 3), res[0] / res[1]);
    assert!((res[0] / res[1] - 4.0).abs() < 0.1);
    assert!((ut - KAPPA * lap).abs() < 1e-3 * ut.abs());

    let exact = bx(0.0, T);
    let conv = simpson(|y| U0 * g(y * y, T, 1, KAPPA), -A, A, 200);
    let point = U0 * 2.0 * A * g(0.0, T, 1, KAPPA);
    println!("rod centre at 10 s: erf form {:.4} K, kernel convolution {:.4} K, point mass {:.4} K ({:.2}% high)",
        exact, conv, point, 100.0 * (point / exact - 1.0));
    assert!((conv - exact).abs() < 1e-9);
    assert!((point / exact - 1.0).abs() < 0.002);
    let mut errs = vec![];
    for m in [1, 2, 4] {
        let (c, h, r) = grid(m);
        errs.push((c - exact).abs());
        println!("grid h = {:.3} mm, r = {:.4}: centre {:.6} K, error {} K", 1000.0 * h, r, c, sci(errs[errs.len() - 1], 2));
    }
    let o = |a: f64, b: f64| (a / b).ln() / 2f64.ln();
    println!("observed order {:.2}, {:.2}", o(errs[0], errs[1]), o(errs[1], errs[2]));
    assert!(1.8 < o(errs[1], errs[2]) && o(errs[1], errs[2]) < 2.2);
    println!("first image term from the held ends, at the centre: {} K", sci(2.0 * U0 * 2.0 * A * g(1.0, T, 1, KAPPA), 1));

    let b = 0.1; // the kernel tends to a point mass: test bump e^(-x^2/(2b^2)), b = 10 cm
    for t in [10.0, 1.0, 0.1] {
        let v = simpson(|x| g(x * x, t, 1, KAPPA) * (-x * x / (2.0 * b * b)).exp(), -1.0, 1.0, 4000);
        println!("t = {:4.1} s: integral of G times bump {:.6}; exact b/sqrt(b^2+2 kappa t) {:.6}; 1 - kappa t/b^2 {:.6}",
            t, v, b / (b * b + 2.0 * KAPPA * t).sqrt(), 1.0 - KAPPA * t / b.powf(2.0));
        assert!((v - b / (b * b + 2.0 * KAPPA * t).sqrt()).abs() < 1e-9);
    }

    for t in [2.5, 10.0, 40.0] {
        let pts: Vec<String> = (-12..13).step_by(2).map(|x| format!("{:.2}", bx(x as f64 / 100.0, t))).collect();
        println!("figure, t = {:4.1} s, x = -12..12 cm step 2: {}", t, pts.join(", "));
    }
    println!("peaks at 2.5, 10, 40 s: {:.2} {:.2} {:.2} K", bx(0.0, 2.5), bx(0.0, 10.0), bx(0.0, 40.0));

    println!("Tychonoff, scaled: x in m, time unit (1 m)^2/kappa = {:.0} s, so kappa = 1", 1.0 / KAPPA);
    for t in [0.4, 0.2, 0.1] {
        println!("Tychonoff, scaled, t = {}: u(0) = {}, u(1) = {}, u(2) = {}", t,
            sci(tych(0.0, t, 80).0, 3), sci(tych(1.0, t, 80).0, 3), sci(tych(2.0, t, 80).0, 3));
    }
    let mut big: f64 = 0.0;
    for x in [1.0, 2.0] { for t in [0.4, 0.2, 0.1] { big = big.max(tych(x, t, 80).1); } }
    println!("Tychonoff, largest first omitted term (term 81) over these: {}", sci(big, 1));
    let (mut tr, mut tut, mut uxx) = (vec![], 0.0, 0.0);
    for h in [0.01, 0.005] {
        tut = (tych(1.0, 0.4 + h, 80).0 - tych(1.0, 0.4 - h, 80).0) / (2.0 * h);
        uxx = (tych(1.0 + h, 0.4, 80).0 - 2.0 * tych(1.0, 0.4, 80).0 + tych(1.0 - h, 0.4, 80).0) / h.powf(2.0);
        tr.push(tut - uxx);
    }
    println!("Tychonoff at x = 1, t = 0.4: u_t = {:.4}, u_xx = {:.4}; residual {} then {}", tut, uxx, sci(tr[0], 2), sci(tr[1], 2));
    assert!((tr[0] / tr[1] - 4.0).abs() < 0.2);
    assert!(tych(1.0, 0.1, 80).0 < 1e-25 && 1e-25 < tych(1.0, 0.4, 80).0);

    let bb = |x: f64, t: f64| (x * x / (4.0 * (1.0 - t))).exp() / (1.0 - t).sqrt(); // the proof's barrier, scaled, S = 1
    let br = (bb(0.5, 0.51) - bb(0.5, 0.49)) / 0.02 - (bb(0.51, 0.5) - 2.0 * bb(0.5, 0.5) + bb(0.49, 0.5)) / 1e-4;
    println!("barrier at x = 0.5, t = 0.5, scaled: u_t - u_xx = {} (step 0.01)", sci(br, 2));
    assert!(br.abs() < 1e-3);

    println!("mistake 1, width sqrt(kappa t): {:.2} cm, not {:.2}", 100.0 * (KAPPA * T).sqrt(), 100.0 * sig);
    println!("mistake 2, 3-d spread taken as the 1-d width: {:.2} cm, rms is {:.2}", 100.0 * sig, 100.0 * (6.0 * KAPPA * T).sqrt());
    println!("mistake 3, 1-d prefactor in 3-d: total {:.5} m^2, not 1", 4.0 * PI * KAPPA * T);
    let fall: Vec<String> = (1..=3).map(|d| format!("{:.1}", g(0.0, 10.0, d, KAPPA) / g(0.0, 40.0, d, KAPPA))).collect();
    println!("peak falls from 10 s to 40 s, d = 1, 2, 3: {}", fall.join(" "));
    println!("mistake 4, 3-d peak from 10 s to 40 s: falls by {:.1}, not {:.1}",
        g(0.0, 10.0, 3, KAPPA) / g(0.0, 40.0, 3, KAPPA), g(0.0, 10.0, 1, KAPPA) / g(0.0, 40.0, 1, KAPPA));
    println!("finance: volatility 0.20, kappa = volatility^2/2 = {:.2} per year; width after 1 year {:.4} in log price",
        0.2f64.powf(2.0) / 2.0, (2.0 * 0.02 * 1.0f64).sqrt());
    println!("ALL CHECKS PASS");
}
