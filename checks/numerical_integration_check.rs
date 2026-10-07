// Numerical integration -- the same check as the Python, in Rust.  No crates.
// The bell curve f(x) = exp(-x^2/2) / sqrt(2 pi) on [0, 1].  Road one: midpoint,
// trapezoid and Simpson sums.  Road two: the exp series integrated term by term,
// with Taylor's remainder bounding the terms left off.
const PI: f64 = std::f64::consts::PI;
fn c() -> f64 { 1.0 / (2.0 * PI).sqrt() }
fn f(x: f64) -> f64 { c() * (-x * x / 2.0).exp() }
fn mid(g: &dyn Fn(f64) -> f64, n: usize, a: f64, b: f64) -> f64 {
    let h = (b - a) / n as f64;
    h * (0..n).map(|i| g(a + (i as f64 + 0.5) * h)).sum::<f64>()
}
fn trap(g: &dyn Fn(f64) -> f64, n: usize, a: f64, b: f64) -> f64 {
    let h = (b - a) / n as f64;
    h * ((g(a) + g(b)) / 2.0 + (1..n).map(|i| g(a + i as f64 * h)).sum::<f64>())
}
fn simp_w(g: &dyn Fn(f64) -> f64, n: usize, a: f64, b: f64, third: f64) -> f64 {
    let h = (b - a) / n as f64;
    h / third * (g(a) + g(b) + (1..n).map(|i| if i % 2 == 1 { 4.0 } else { 2.0 } * g(a + i as f64 * h)).sum::<f64>())
}
fn simp(g: &dyn Fn(f64) -> f64, n: usize, a: f64, b: f64) -> f64 { simp_w(g, n, a, b, 3.0) }
fn row(xs: &[f64], d: usize) -> String { xs.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ") }
fn sci(x: f64) -> String {                    // 3.0e-7 written 3.0e-07, as Python does
    let s = format!("{:.1e}", x);
    let (m, e) = s.split_once('e').map(|(m, e)| (m, e.parse::<i32>().unwrap())).unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
type Rule = fn(&dyn Fn(f64) -> f64, usize, f64, f64) -> f64;
fn main() {
    let (k2, k4) = (c(), 3.0 * c());          // |f''| = |x^2 - 1| f, |f''''| = |x^4 - 6x^2 + 3| f, largest at x = 0
    let bounds = |n: f64| [k2 / (24.0 * n * n), k2 / (12.0 * n * n), k4 / (180.0 * n.powi(4))];
    let (mut fact, mut total) = (1.0f64, 0.0f64);
    for k in 0..13 {                          // integral of (-x^2/2)^k / k! from 0 to 1
        fact *= (k.max(1)) as f64;
        total += (-1f64).powi(k) / (2f64.powi(k) * fact * (2 * k + 1) as f64);
    }
    let (exact, tail) = (c() * total, c() * 0.5f64.powi(13) / (fact * 13.0));
    println!("f at x = 0, 1/8, ..., 1: {}", row(&(0..9).map(|k| f(k as f64 / 8.0)).collect::<Vec<_>>(), 6));
    println!("series road: 13 terms give {:.12}, tail below {}", exact, sci(tail));
    let rules: [(&str, Rule); 3] = [("midpoint", mid), ("trapezoid", trap), ("Simpson", simp)];
    for ((name, rule), bd) in rules.iter().zip(bounds(4.0)) {
        let v = rule(&f, 4, 0.0, 1.0);
        println!("n = 4 {}: {:.9}, error {:.9}, bound {:.9}", name, v, (v - exact).abs(), bd);
        assert!((v - exact).abs() <= bd);                           // road 1 inside the proved window
    }
    let err = |rule: Rule, n: usize| (rule(&f, n, 0.0, 1.0) - exact).abs();
    let r: Vec<f64> = rules.iter().map(|&(_, rule)| err(rule, 8) / err(rule, 16)).collect();
    println!("error ratio, n = 8 to n = 16: midpoint {:.2}, trapezoid {:.2}, Simpson {:.2}", r[0], r[1], r[2]);
    let (d, xs): (f64, Vec<f64>) = (0.01, (0..=1000).map(|i| i as f64 / 1000.0).collect());
    let q2 = xs.iter().map(|&x| ((f(x + d) - 2.0 * f(x) + f(x - d)) / (d * d)).abs()).fold(0.0, f64::max);
    let q4 = xs.iter().map(|&x| ((f(x + 2.0 * d) - 4.0 * f(x + d) + 6.0 * f(x) - 4.0 * f(x - d) + f(x - 2.0 * d)) / d.powi(4)).abs()).fold(0.0, f64::max);
    println!("difference quotients on 1001 points: max |f''| {:.6} vs K2 {:.6}; max |f''''| {:.6} vs K4 {:.6}", q2, k2, q4, k4);
    assert!((r[0] - 4.0).abs() < 0.05 && (r[1] - 4.0).abs() < 0.05 && (r[2] - 16.0).abs() < 0.5
        && (q2 - k2).abs() < 1e-4 && (q4 - k4).abs() < 1e-3);    // h^2, h^2, h^4; ceilings by a second road
    let eps = 5e-7;
    let (nm, nt) = ((k2 / (24.0 * eps)).sqrt().ceil() as usize, (k2 / (12.0 * eps)).sqrt().ceil() as usize);
    let mut ns = (k4 / (180.0 * eps)).powf(0.25).ceil() as usize;
    ns += ns % 2;
    println!("target 5e-7: bounds ask for midpoint n = {}, trapezoid n = {}, Simpson n = {}", nm, nt, ns);
    let e3 = [err(mid, nm), err(trap, nt), err(simp, ns)];
    println!("errors there: midpoint {}, trapezoid {}, Simpson {}", sci(e3[0]), sci(e3[1]), sci(e3[2]));
    let first: Vec<usize> = [(mid as Rule, 1), (trap, 1), (simp, 2)].iter()
        .map(|&(rule, s)| (s..999).step_by(s).find(|&n| err(rule, n) < eps).unwrap()).collect();
    println!("smallest n that actually works: midpoint {}, trapezoid {}, Simpson {}", first[0], first[1], first[2]);
    let (sv, tv) = (simp(&f, ns, 0.0, 1.0), trap(&f, nt, 0.0, 1.0));
    println!("six decimals: Simpson n = {} gives {:.6}, trapezoid n = {} gives {:.6}, series {:.6}", ns, sv, nt, tv, exact);
    assert!(e3.iter().all(|&e| e < eps) && format!("{:.6}", sv) == format!("{:.6}", exact));
    let v: Vec<f64> = rules.iter().map(|&(_, rule)| rule(&|t: f64| 3.0 + 2.0 * t, 10, 0.0, 10.0)).collect();
    println!("tank 3 + 2t over 10 minutes, n = 10: midpoint {:.6}, trapezoid {:.6}, Simpson {:.6}", v[0], v[1], v[2]);
    assert!(v.iter().all(|&x| (x - (3.0 * 10.0 + 10.0 * 20.0 / 2.0)).abs() < 1e-9));   // geometry: 30 + 100 litres
    println!("figure, 280 px per unit across, 400 px per unit up; x = {}", row(&(0..17).map(|k| 40.0 + 280.0 * k as f64 / 16.0).collect::<Vec<_>>(), 1));
    println!("figure, curve y = {}", row(&(0..17).map(|k| 215.0 - 400.0 * f(k as f64 / 16.0)).collect::<Vec<_>>(), 1));
    println!("figure, rectangle tops y = {}; ticks 0.2 at y = {:.0}, 0.4 at y = {:.0}",
             row(&[1.0, 3.0, 5.0, 7.0].map(|k: f64| 215.0 - 400.0 * f(k / 8.0)), 1), 215.0 - 400.0 * 0.2, 215.0 - 400.0 * 0.4);
    println!("mistake 1, K2 read at x = 1: |f''(1)| = |1 - 1| f(1) = {:.6}, yet n = 1 midpoint gives {:.6}, error {:.6}",
             ((1.0 * 1.0 - 1.0) * f(1.0)).abs(), mid(&f, 1, 0.0, 1.0), err(mid, 1));
    println!("mistake 2, Simpson n = 4 with h instead of h/3: {:.6}", simp_w(&f, 4, 0.0, 1.0, 1.0));
    println!("mistake 3, Simpson weights on odd n = 5: {:.6}, error {:.6}", simp(&f, 5, 0.0, 1.0), err(simp, 5));
    println!("ALL CHECKS PASS");
}
