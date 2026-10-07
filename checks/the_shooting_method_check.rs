// The shooting method -- the same check as the Python, in Rust.  No crates; exp is
// the one primitive.  Cable on a spring bed: y'' = y, x in m, y in cm,
// y(0) = 1, y(1) = 2.  Self-heating slab: y'' = -e^y, y(0) = y(1) = 0, scaled.
fn shoot(f: &dyn Fn(f64) -> f64, y0: f64, s: f64, n: usize) -> f64 {
    let (h, mut y, mut v) = (1.0 / n as f64, y0, s);   // RK4 on y' = v, v' = f(y)
    for _ in 0..n {
        let k1 = (v, f(y)); let k2 = (v + h / 2.0 * k1.1, f(y + h / 2.0 * k1.0));
        let k3 = (v + h / 2.0 * k2.1, f(y + h / 2.0 * k2.0)); let k4 = (v + h * k3.1, f(y + h * k3.0));
        y += h / 6.0 * (k1.0 + 2.0 * k2.0 + 2.0 * k3.0 + k4.0); v += h / 6.0 * (k1.1 + 2.0 * k2.1 + 2.0 * k3.1 + k4.1);
    }
    y                                                   // the landing height y(1)
}
fn secant(g: &dyn Fn(f64) -> f64, mut s0: f64, mut s1: f64) -> (f64, Vec<(f64, f64)>) {
    let (mut g0, mut g1, mut rows) = (g(s0), g(s1), vec![]);   // re-aim through the last two shots
    while g1.abs() > 1e-10 {
        let s2 = s1 - g1 * (s1 - s0) / (g1 - g0); s0 = s1; s1 = s2; g0 = g1; g1 = g(s1); rows.push((s1, g1));
    }
    (s1, rows)
}
fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..100 { let mid = (lo + hi) / 2.0; if f(lo) * f(mid) > 0.0 { lo = mid } else { hi = mid } }
    lo                                                  // halve a bracket where f changes sign
}
fn sci(x: f64, plus: bool) -> String {                  // 1.23e-05, as Python prints it
    let t = format!("{:.2e}", x); let (m, e) = t.split_once('e').unwrap(); let e: i32 = e.parse().unwrap();
    format!("{}{}e{}{:02}", if plus && x >= 0.0 { "+" } else { "" }, m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn cosh(z: f64) -> f64 { (z.exp() + (-z).exp()) / 2.0 }
fn sinh(z: f64) -> f64 { (z.exp() - (-z).exp()) / 2.0 }
fn main() {
    let (ch, sh) = (cosh(1.0), sinh(1.0));
    let tanh = |z: f64| (1.0 - (-2.0 * z).exp()) / (1.0 + (-2.0 * z).exp());
    let cable = |n: usize| move |s: f64| shoot(&|y| y, 1.0, s, n) - 2.0;
    let g = cable(64); let (a, b) = (g(0.0) + 2.0, g(1.0) + 2.0);
    println!("cable, shots s = 0 and 1 land at {:.6} and {:.6}, misses {:.6} and {:.6}", a, b, a - 2.0, b - 2.0);
    let s_cab = 0.0 - (a - 2.0) * (1.0 - 0.0) / (b - a);     // road 1: one secant step from two shots
    let exact = (2.0 - ch) / sh;                            // road 2: the closed form
    println!("cable, secant through the two shots: s = {:.8}, third shot lands at {:.8}", s_cab, g(s_cab) + 2.0);
    println!("cable, closed form (2 - cosh 1)/sinh 1 = {:.8}; miss rises sinh 1 = {:.6} per unit of s", exact, sh);
    assert!((s_cab - exact).abs() < 1e-8);
    let errs: Vec<f64> = [4, 8, 16].iter().map(|&n| (secant(&cable(n), 0.0, 1.0).0 - exact).abs()).collect();
    println!("cable, slope error with 4, 8, 16 steps: {} {} {}; ratios {:.2} {:.2}",
        sci(errs[0], false), sci(errs[1], false), sci(errs[2], false), errs[0] / errs[1], errs[1] / errs[2]);
    assert!((0..2).all(|i| 14.0 < errs[i] / errs[i + 1] && errs[i] / errs[i + 1] < 18.0));
    for (s, name) in [(0.0, "s = 0"), (1.0, "s = 1"), (exact, "s = 0.3888")] {
        let pts: Vec<String> = (0..9).map(|k| { let x = k as f64 / 8.0;
            format!("{:.1},{:.1}", 40.0 + 240.0 * x, 200.0 - 100.0 * (cosh(x) + s * sinh(x) - 0.9)) }).collect();
        println!("figure, {}: {}", name, pts.join(" "));
    }
    let heat = |s: f64| shoot(&|y: f64| -y.exp(), 0.0, s, 256);
    let fth = |t: f64| t - 2f64.sqrt() * cosh(t / 4.0);
    let th = [bisect(&fth, 0.0, 4.0), bisect(&fth, 4.0, 20.0)];
    let slopes = th.map(|t| t * tanh(t / 4.0));             // road 2: y'(0) = theta tanh(theta/4)
    println!("slab, theta by bisection {:.6} and {:.6}; exact slopes {:.6} and {:.6}", th[0], th[1], slopes[0], slopes[1]);
    let (low, rows) = secant(&heat, 0.0, 1.0);
    for (k, (s, m)) in rows.iter().enumerate() { println!("slab, correction {}: s = {:.10}, miss = {}", k + 1, s, sci(*m, true)); }
    let (high, rows2) = secant(&heat, 10.0, 12.0);
    println!("slab, from shots 10 and 12: s = {:.6} after {} corrections", high, rows2.len());
    assert!((low - slopes[0]).abs() < 1e-8 && (high - slopes[1]).abs() < 1e-7);
    let ss: Vec<f64> = (0..8).map(|i| 2.0 * i as f64).collect();
    println!("chart, s: {}", ss.iter().map(|s| format!("{}", s)).collect::<Vec<_>>().join(" "));
    println!("chart, miss: {}", ss.iter().map(|&s| format!("{:.2}", heat(s))).collect::<Vec<_>>().join(" "));
    let flat = secant(&|s| shoot(&|y| y, 0.0, s, 64) - 2.0, 0.0, 1.0).0;
    let pi2 = std::f64::consts::PI * std::f64::consts::PI;
    let res = [0.0, 1.0].map(|s| shoot(&|y| -pi2 * y, 0.0, s, 64) - 1.0);
    let hot = (0..301).map(|s| shoot(&|y: f64| -4.0 * y.exp(), 0.0, s as f64 / 10.0, 64)).fold(f64::MIN, f64::max);
    println!("mistake, left height dropped: s = {:.6}, not {:.6}", flat, exact);
    println!("mistake, y'' = -pi^2 y from y(0) = 0 aiming at 1: misses {:.6} and {:.6} at s = 0 and 1", res[0], res[1]);
    println!("mistake, slab heating 4 times as fast: best landing for s from 0 to 30 is {:.4}, never 0", hot);
    assert!((flat - 2.0 / sh).abs() < 1e-8 && res.iter().all(|r| (r + 1.0).abs() < 1e-6) && hot < 0.0);
    println!("ALL CHECKS PASS");
}
