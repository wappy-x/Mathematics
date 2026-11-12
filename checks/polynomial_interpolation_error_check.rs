// The interpolation error theorem -- the same check as polynomial_interpolation_error_check.py,
// in Rust, std only.  Sine on [0, pi] from four nodes: Lagrange on a grid (road 1), the
// closed form a x (pi - x) with bisection on e'(x) = 0 (road 2), divided differences (road 3),
// and the theorem tested point by point: 24 e(x) / omega(x) must be a value of sin.
// Compile: rustc --edition 2021 -O polynomial_interpolation_error_check.rs -o /tmp/pie_check
use std::f64::consts::PI;
const N: usize = 3600; // grid: 3600 slices of [0, pi]

fn lagrange(xs: &[f64], ys: &[f64], x: f64) -> f64 {
    let basis = |j: usize| (0..xs.len()).filter(|&k| k != j).map(|k| (x - xs[k]) / (xs[j] - xs[k])).product::<f64>();
    (0..xs.len()).map(|j| ys[j] * basis(j)).sum()
}

fn omega(xs: &[f64], x: f64) -> f64 { xs.iter().fold(1.0, |w, xk| w * (x - xk)) } // product of distances

fn divided(xs: &[f64], ys: &[f64]) -> f64 { // top divided difference f[x0..xm]
    let mut c = ys.to_vec();
    for k in 1..xs.len() {
        for i in (k..xs.len()).rev() {
            c[i] = (c[i] - c[i - 1]) / (xs[i] - xs[i - k]);
        }
    }
    c[xs.len() - 1]
}

fn study(xs: &[f64], f: &dyn Fn(f64) -> f64, lo: f64, hi: f64) -> (f64, f64) { // worst error, worst |omega|
    let ys: Vec<f64> = xs.iter().map(|&x| f(x)).collect();
    let (mut em, mut wm) = (0.0f64, 0.0f64);
    for i in 0..=N {
        let x = lo + (hi - lo) * i as f64 / N as f64;
        em = em.max((f(x) - lagrange(xs, &ys, x)).abs());
        wm = wm.max(omega(xs, x).abs());
    }
    (em, wm)
}

fn sci(v: f64) -> String { // Python's {:.3e}: 4.362e-02
    let s = format!("{:.3e}", v);
    let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}

fn join(v: &[f64], f: &dyn Fn(f64) -> String) -> String { v.iter().map(|&x| f(x)).collect::<Vec<_>>().join(" ") }

fn main() {
    let deg = |x: f64| x.to_degrees();
    let sin = |x: f64| x.sin();
    let eq: Vec<f64> = (0..4).map(|k| k as f64 * PI / 3.0).collect();
    let ys: Vec<f64> = eq.iter().map(|x| x.sin()).collect();
    println!("nodes, degrees {}", join(&eq, &|x| format!("{:.0}", deg(x))));
    println!("values, sin    {}", join(&ys, &|y| format!("{:.6}", y)));
    let a = 9.0 * 3f64.sqrt() / (4.0 * PI * PI); // p(x) = a x (pi - x) passes through all four
    let gap = (0..=N).map(|i| PI * i as f64 / N as f64).map(|x| (lagrange(&eq, &ys, x) - a * x * (PI - x)).abs()).fold(0.0, f64::max);
    assert!(gap < 1e-14, "{}", gap);
    println!("closed form a = {:.6}; matches Lagrange at all {} grid points", a, N + 1);

    let x = PI / 2.0; // the worked point, 90 degrees
    let p = lagrange(&eq, &ys, x);
    let e = x.sin() - p;
    let w = omega(&eq, x);
    let s = 24.0 * e / w;
    println!("at 90: p {:.6}  true error {:.6}  omega {:.6}  omega/24 {:.6}", p, e, w, w / 24.0);
    println!("at 90: sin(xi) = 24 e/omega = {:.6}, xi = {:.2} or {:.2} degrees", s, deg(s.asin()), 180.0 - deg(s.asin()));
    assert!((e - (1.0 - 9.0 * 3f64.sqrt() / 16.0)).abs() < 1e-14); // exact value by hand
    let mut nx = eq.clone(); nx.push(x);
    let mut ny = ys.clone(); ny.push(x.sin());
    let dd = divided(&nx, &ny);
    println!("at 90: f[x0..x3,x] = {:.6}, times omega = {:.6}", dd, dd * w);
    assert!((dd * w - e).abs() < 1e-12); // road 3 against road 1

    let (emax, wmax) = study(&eq, &sin, 0.0, PI);
    let (mut lo, mut hi) = (0.2f64, 0.6f64); // road 2: e'(x) = cos x - a (pi - 2x) = 0
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if mid.cos() - a * (PI - 2.0 * mid) < 0.0 { lo = mid } else { hi = mid }
    }
    let eb = (lo.sin() - a * lo * (PI - lo)).abs();
    println!("worst true error {:.6} (grid); {:.6} at {:.2} and {:.2} deg (bisection)", emax, eb, deg(lo), 180.0 - deg(lo));
    assert!((eb - emax).abs() < 1e-7);
    let sw = (3.0 - 5f64.sqrt()) / 2.0; // |s(s-1)(s-2)(s-3)| peaks at 1, at s = (3 - sqrt5)/2
    let h4 = (PI / 3.0).powi(4);
    println!("max|omega| {:.6} (grid); (pi/3)^4 = {:.6} at {:.2} and {:.2} deg", wmax, h4, deg(sw * PI / 3.0), 180.0 - deg(sw * PI / 3.0));
    assert!((wmax - h4).abs() < 1e-6);
    let bound = wmax / 24.0;
    println!("bound max|omega|/4! = {:.6}; true {:.6}; bound/true {:.3}", bound, emax, bound / emax);
    assert!(emax <= bound);

    let (mut lo_s, mut hi_s) = (1.0f64, 0.0f64); // the theorem, point by point
    for i in 0..=N {
        let t = PI * i as f64 / N as f64;
        if eq.iter().map(|xk| (t - xk).abs()).fold(f64::MAX, f64::min) > 1e-9 {
            let r = 24.0 * (t.sin() - lagrange(&eq, &ys, t)) / omega(&eq, t);
            lo_s = lo_s.min(r);
            hi_s = hi_s.max(r);
        }
    }
    println!("24 e/omega over the grid: min {:.6} max {:.6} (sin on [0, pi] spans 0 to 1)", lo_s, hi_s);
    assert!(0.0 <= lo_s && hi_s <= 1.0 && (hi_s - 24.0 * (1.0 - 9.0 * 3f64.sqrt() / 16.0) / (PI.powi(4) / 144.0)).abs() < 1e-9); // top: 90 by hand

    let cheb: Vec<f64> = (0..4).map(|k| PI / 2.0 * (1.0 - ((2 * k + 1) as f64 * PI / 8.0).cos())).collect();
    let bunch: Vec<f64> = (0..4).map(|k| PI / 4.0 + k as f64 * PI / 6.0).collect();
    println!("placement   nodes(deg)            max|omega|  bound     true      ratio");
    for (name, xs) in [("equal", &eq), ("chebyshev", &cheb), ("bunched", &bunch)] {
        let (em, wm) = study(xs, &sin, 0.0, PI);
        println!("{:10}  {}  {:.6}  {:.6}  {:.6}  {:.3}", name, join(xs, &|t| format!("{:5.1}", deg(t))), wm, wm / 24.0, em, wm / 24.0 / em);
        assert!(em <= wm / 24.0);
        if name == "chebyshev" {
            assert!((wm - 2.0 * (PI / 4.0).powi(4)).abs() < 1e-6); // the smallest possible max|omega|
        }
    }

    println!("window(deg)  true      bound     ratio  order");
    let mut errs: Vec<f64> = Vec::new();
    for k in 0..14 { // four equal nodes across a window centred on 90, down to rounding
        let wd = PI / 2f64.powi(k);
        let xs: Vec<f64> = (0..4).map(|j| PI / 2.0 - wd / 2.0 + j as f64 * wd / 3.0).collect();
        let (em, wm) = study(&xs, &sin, PI / 2.0 - wd / 2.0, PI / 2.0 + wd / 2.0);
        let order = if errs.is_empty() { String::new() } else { format!("{:.2}", (errs[errs.len() - 1] / em).log2()) };
        println!("{:9.2}  {}  {}  {:.3}  {}", deg(wd), sci(em), sci(wm / 24.0), wm / 24.0 / em, order);
        assert!(em <= wm / 24.0 + 1e-15); // rounding, a few units of 1.1e-16, lies outside the theorem
        errs.push(em);
    }
    let last = (errs[7] / errs[8]).log2();
    assert!(3.95 < last && last < 4.05 && (errs[6] / ((PI / 192.0).powi(4) / 24.0) - 1.0).abs() < 0.01); // error / 16; bound tight
    assert!(errs[13] > (PI / 24576.0).powi(4) / 24.0); // at the narrowest window rounding exceeds the bound
    let hmax = (24.0 * 1e-3f64).powf(0.25); let m = (PI / (3.0 * hmax)).ceil() as usize; let h = PI / (3 * m) as f64; // h^4/24 <= 0.001
    let ep = (0..m).map(|i| study(&(0..4).map(|j| (3 * i + j) as f64 * h).collect::<Vec<f64>>(), &sin, (3 * i) as f64 * h, (3 * i) as f64 * h + 3.0 * h).0).fold(0.0, f64::max);
    println!("target 0.001: spacing at most {:.1} deg; {} cubic pieces, {} values {:.0} deg apart; bound {}, true {}", deg(hmax), m, 3 * m + 1, deg(h), sci(h.powi(4) / 24.0), sci(ep));
    assert!(ep <= h.powi(4) / 24.0 && h.powi(4) / 24.0 < 1e-3 && 1e-3 < (PI / (3 * m - 3) as f64).powi(4) / 24.0); // one piece fewer misses

    let ac = |t: f64| t.cos().abs(); // what breaks: a kink at 90, no 4th derivative there
    let (ek, _) = study(&eq, &ac, 0.0, PI);
    let ycos: Vec<f64> = eq.iter().map(|&t| ac(t)).collect();
    let mut xk = 0.0;
    for i in 0..=N {
        let t = PI * i as f64 / N as f64;
        if (ac(t) - lagrange(&eq, &ycos, t)).abs() == ek && xk == 0.0 { xk = t }
    }
    println!("break, |cos x|: true {:.6} at {:.2} deg against the claimed bound {:.6}", ek, deg(xk), bound);
    assert!(ek > 8.0 * bound);
    println!("break, 3! for 4!: {:.6};  (b-a)^4 for omega: {:.6}", wmax / 6.0, PI.powi(4) / 24.0);
    let xo = 4.0 * PI / 3.0; // 240 degrees, outside the nodes
    let eo = (xo.sin() - lagrange(&eq, &ys, xo)).abs();
    println!("break, at 240 deg: true {:.6}; in-span bound {:.6}; right bound {:.6}", eo, bound, omega(&eq, xo).abs() / 24.0);
    assert!(bound < eo && eo <= omega(&eq, xo).abs() / 24.0);
    let x10 = PI / 18.0; // 10 degrees: derivative read at x, not at xi
    let e10 = (x10.sin() - lagrange(&eq, &ys, x10)).abs();
    println!("break, sin(x) for sin(xi) at 10 deg: predicts {:.6}; true {:.6}", x10.sin() * omega(&eq, x10).abs() / 24.0, e10);

    let unit = |j: usize| (0..4).map(|i| if i == j { 1.0 } else { 0.0 }).collect::<Vec<f64>>();
    let lsum = |x: f64| (0..4).map(|j| lagrange(&eq, &unit(j), x).abs()).sum::<f64>();
    let leb = (0..=N).map(|t| lsum(PI * t as f64 / N as f64)).fold(0.0, f64::max);
    println!("Lebesgue constant, equal nodes: {:.4}", leb);
    assert!((leb - 1.6311).abs() < 1e-4); // tabulated value for 4 equal nodes

    let five: Vec<f64> = (0..5).map(|k| k as f64 * PI / 4.0).collect(); // try changing: five nodes
    let (e5, w5) = study(&five, &sin, 0.0, PI);
    println!("try, five equal nodes: true {:.6}; bound max|omega|/5! {:.6}", e5, w5 / 120.0);
    assert!(e5 <= w5 / 120.0);

    let xs13: Vec<f64> = (0..13).map(|k| PI * k as f64 / 12.0).collect();
    let fix = |v: f64| if v.abs() < 5e-5 { 0.0 } else { v };
    println!("chart, x (deg)     {}", join(&xs13, &|t| format!("{:.0}", deg(t))));
    println!("chart, error       {}", join(&xs13, &|t| format!("{:.4}", fix(t.sin() - lagrange(&eq, &ys, t)))));
    println!("chart, omega/24    {}", join(&xs13, &|t| format!("{:.4}", fix(omega(&eq, t) / 24.0))));
    println!("chart, |omega| eq  {}", join(&xs13, &|t| format!("{:.4}", omega(&eq, t).abs())));
    println!("chart, |omega| ch  {}", join(&xs13, &|t| format!("{:.4}", omega(&cheb, t).abs())));
    println!("ALL CHECKS PASS");
}
