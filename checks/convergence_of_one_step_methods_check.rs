// From local error to global error -- the same check as the Python, in Rust.  No crates.
// A model rocket coasts from burnout: height y, speed v, y' = v, v' = -g - k v.
// Road one: run a one-step method and subtract the closed-form flight.
// Road two: carry each step's local error to the end, step by step, and add.
// Road three: the theorem's bound, which must sit above both.
const G: f64 = 9.8; const K: f64 = 0.05; const T: f64 = 30.0;    // m/s^2, 1/s, s
const Y0: f64 = 40.0; const V0: f64 = 180.0;                      // m, m/s
type X = (f64, f64);
struct Tab { a: Vec<Vec<f64>>, b: Vec<f64>, c: Vec<f64> }

fn sci(x: f64, d: usize) -> String { format!("{:.*e}", d, x) }    // 2.280e-3, as in Python
fn exact(t: f64, y0: f64, v0: f64, a: f64, k: f64) -> X {        // closed form, thrust a
    let vi = (a - G) / k; let am = v0 - vi; let q = (-k * t).exp();
    (y0 + vi * t + am * (1.0 - q) / k, vi + am * q)
}
fn ex(t: f64, k: f64) -> X { exact(t, Y0, V0, 0.0, k) }
fn rocket(k: f64, a: f64, tb: f64) -> impl Fn(f64, X) -> X {     // thrust a until tb
    move |t, x| (x.1, (if t < tb { a } else { 0.0 }) - G - k * x.1)
}
fn step(tab: &Tab, f: &dyn Fn(f64, X) -> X, t: f64, x: X, h: f64) -> X {
    let mut ks: Vec<X> = vec![];
    for i in 0..tab.b.len() {
        let mut z = x;
        for j in 0..i { z = (z.0 + h * tab.a[i - 1][j] * ks[j].0, z.1 + h * tab.a[i - 1][j] * ks[j].1) }
        ks.push(f(t + tab.c[i] * h, z));
    }
    let (mut s0, mut s1) = (0.0, 0.0);
    for i in 0..tab.b.len() { s0 += tab.b[i] * ks[i].0; s1 += tab.b[i] * ks[i].1 }
    (x.0 + h * s0, x.1 + h * s1)
}
fn run(tab: &Tab, f: &dyn Fn(f64, X) -> X, h: f64, mut x: X, t_end: f64) -> X {
    for n in 0..(t_end / h).round() as i64 { x = step(tab, f, n as f64 * h, x, h) }
    x
}
fn size(d: X, k: f64) -> f64 { d.0.abs().max(d.1.abs() / k) }   // metres: height, or speed x 1/k
fn err(x: X, xe: X) -> X { (xe.0 - x.0, xe.1 - x.1) }
fn e_of(tab: &Tab, h: f64, k: f64, t_end: f64) -> f64 {
    size(err(run(tab, &rocket(k, 0.0, 0.0), h, (Y0, V0), t_end), ex(t_end, k)), k)
}
fn lam(l: f64, h: f64) -> f64 { l * (1.0 + h * l / 2.0 + (h * l).powi(2) / 6.0 + (h * l).powi(3) / 24.0) }
fn theorem(rk: &Tab, h: f64, k: f64, t_end: f64) -> (f64, f64, f64, Vec<f64>) {
    let f = rocket(k, 0.0, 0.0);
    let fh = move |_t: f64, x: X| (x.1, -k * x.1);                // the rate law minus gravity
    let (mut e, mut taus): (X, Vec<f64>) = ((0.0, 0.0), vec![]);
    for n in 0..(t_end / h).round() as i64 {
        let (x0, x1) = (ex(n as f64 * h, k), ex((n + 1) as f64 * h, k));
        let loc = err(step(rk, &f, n as f64 * h, x0, h), x1);       // h times tau_n
        taus.push(size(loc, k) / h);
        let r = step(rk, &fh, 0.0, e, h); e = (r.0 + loc.0, r.1 + loc.1);
    }
    let big = taus.iter().cloned().fold(0.0, f64::max);
    (e_of(rk, h, k, t_end), size(e, k), big * ((lam(k, h) * t_end).exp() - 1.0) / lam(k, h), taus)
}
fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ") }
fn orders(e: &[f64]) -> Vec<f64> { (0..e.len() - 1).map(|i| (e[i] / e[i + 1]).log2()).collect() }

fn main() {
    let euler = Tab { a: vec![], b: vec![1.0], c: vec![0.0] };
    let heun = Tab { a: vec![vec![1.0]], b: vec![0.5, 0.5], c: vec![0.0, 1.0] };
    let rka = vec![vec![0.5], vec![0.0, 0.5], vec![0.0, 0.0, 1.0]];
    let rkc = vec![0.0, 0.5, 0.5, 1.0];
    let rk4 = Tab { a: rka.clone(), b: vec![1.0 / 6.0, 1.0 / 3.0, 1.0 / 3.0, 1.0 / 6.0], c: rkc.clone() };
    let f = rocket(K, 0.0, 0.0);
    println!("rocket from burnout: y0 = 40 m, v0 = 180 m/s, g = 9.8 m/s^2, k = 0.05 /s, T = 30 s");
    let xt = ex(T, K);
    println!("exact at 30 s: height {:.4} m, speed {:.4} m/s", xt.0, xt.1);
    let hs: Vec<f64> = (0..13).map(|j| 2.0 / 2f64.powi(j)).collect();   // 2 s down to 1/2048 s
    let names = ["Euler", "Heun", "RK4"];
    let errs: Vec<Vec<f64>> = [&euler, &heun, &rk4].iter().map(|t| hs.iter().map(|&h| e_of(t, h, K, T)).collect()).collect();
    for &h in &hs[..4] {
        let d = err(run(&rk4, &f, h, (Y0, V0), T), xt);
        println!("RK4 h = {:?}: height error {} m, speed error {} m/s, E = {} m", h, sci(d.0, 3), sci(d.1, 3), sci(size(d, K), 3));
    }
    let er = &errs[2];
    let ratios: Vec<f64> = (0..3).map(|i| er[i] / er[i + 1]).collect();
    println!("RK4 error ratio per halving: {}", join(&ratios, 2));
    for (n, e) in names.iter().zip(&errs) { println!("observed order, {}: {}", n, join(&orders(&e[..4]), 2)) }
    let loc: Vec<f64> = [1.0, 0.5].iter().map(|&h| size(err(step(&rk4, &f, 0.0, (Y0, V0), h), ex(h, K)), K)).collect();
    println!("one RK4 step from burnout: local error h = 1: {} m, h = 0.5: {} m, ratio {:.2}", sci(loc[0], 3), sci(loc[1], 3), loc[0] / loc[1]);
    let (true1, carried, bound1, taus) = theorem(&rk4, 1.0, K, T);
    let big = taus.iter().cloned().fold(0.0, f64::max);
    println!("h = 1: size of exact minus run {} m; local errors carried and added {} m", sci(true1, 6), sci(carried, 6));
    println!("theorem, h = 1: L = 0.05 /s, Lambda = {:.6} /s, largest tau = {} m/s, last tau = {} m/s",
             lam(K, 1.0), sci(big, 3), sci(taus[taus.len() - 1], 3));
    println!("theorem, h = 1: bound {} m, true {} m, bound / true {:.2}", sci(bound1, 3), sci(true1, 3), bound1 / true1);
    println!("over 30 s the bound lets errors grow by e^(Lambda T) = {:.2}; drag shrinks a speed error by e^(-kT) = {:.3}",
             (lam(K, 1.0) * T).exp(), (-K * T).exp());
    println!("along the flight, h = 1: t, true E, bound, bound / true");
    for tt in [6.0, 12.0, 18.0, 24.0, 30.0] {
        let (tr, _, b, _) = theorem(&rk4, 1.0, K, tt);
        println!("  {:4.0} s  {} m  {} m  {:.2}", tt, sci(tr, 3), sci(b, 3), b / tr);
    }
    let lp = lam(1.0, 1.0);                                        // L = 1 /s if speed counts as metres
    let plain = big * ((lp * T).exp() - 1.0) / lp;                 // height part is the larger: same tau
    println!("plain sizes (L = 1 /s, Lambda = {:.6} /s): bound {} m, bound / true {}", lp, sci(plain, 3), sci(plain / true1, 3));
    for h in [2.0, 0.5] {
        let (tr, _, b, _) = theorem(&rk4, h, K, T);
        println!("theorem, h = {:?}: bound {} m, true {} m, bound / true {:.2}", h, sci(b, 3), sci(tr, 3), b / tr);
    }
    println!("chart x, log10 h: {}", join(&hs.iter().map(|h| h.log10()).collect::<Vec<_>>(), 2));
    for (n, e) in names.iter().zip(&errs) { println!("chart, log10 E, {}: {}", n, join(&e.iter().map(|x| x.log10()).collect::<Vec<_>>(), 2)) }
    let mut lo = 0;
    for i in 0..hs.len() { if er[i] < er[lo] { lo = i } }
    println!("rounding floor, RK4: smallest E {} m at h = 1/{} s; at h = 1/2048 s, E = {} m",
             sci(er[lo], 1), (1.0 / hs[lo]).round(), sci(er[er.len() - 1], 1));
    let (at, tb) = (110.0, 1.7);                                     // mistake 1: thrust inside the run
    let (yb, vb) = exact(tb, 0.0, 0.0, at, K);
    let xe = exact(T - tb, yb, vb, 0.0, K);
    let th: Vec<f64> = [1.0, 0.5, 0.25, 0.125].iter().map(|&h| size(err(run(&rk4, &rocket(K, at, tb), h, (0.0, 0.0), T), xe), K)).collect();
    println!("mistake 1, 1.7 s burn at 110 m/s^2 inside the run, h = 1, 0.5, 0.25, 0.125: E = {} m; orders {}", join(&th, 1), join(&orders(&th), 2));
    let bad = Tab { a: rka.clone(), b: vec![1.0 / 6.0, 1.0 / 6.0, 1.0 / 3.0, 1.0 / 3.0], c: rkc.clone() };  // add to 1
    let inc = Tab { a: rka.clone(), b: vec![1.0 / 6.0, 1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0], c: rkc.clone() };  // add to 7/6
    let hb = [1.0, 0.5, 0.25];
    let eb: Vec<f64> = hb.iter().map(|&h| e_of(&bad, h, K, T)).collect();
    println!("mistake 2, weights 1/6, 1/6, 1/3, 1/3, h = 1, 0.5, 0.25: E = {} m; orders {}", join(&eb, 2), join(&orders(&eb), 2));
    println!("mistake 3, weights adding to 7/6, h = 1, 0.5, 0.25: E = {} m", join(&hb.iter().map(|&h| e_of(&inc, h, K, T)).collect::<Vec<_>>(), 2));
    println!("mistake 4, the 32-fold local gain read as the global one: guess E(0.5) = {} m, actual {} m", sci(er[1] / 32.0, 3), sci(er[2], 3));
    let (tr, _, b, _) = theorem(&rk4, 1.0, 0.1, T);
    println!("try, drag k = 0.1 /s, h = 1: bound / true {:.2}", b / tr);
    let (tr, _, b, _) = theorem(&rk4, 1.0, K, 10.0);
    println!("try, stop at T = 10 s, h = 1: bound / true {:.2}", b / tr);

    for h in [2.0, 1.0, 0.5] {                                       // road two equals road one,
        let (tr, cr, b, _) = theorem(&rk4, h, K, T);                 // to the 1e-12 m rounding floor
        assert!((cr - tr).abs() < 1e-10 && tr < b);                  // and the bound sits above
    }
    let fh = |_t: f64, x: X| (x.1, -K * x.1);                         // linear law: a gap obeys the law minus gravity
    let stretch = [(1.0, 0.0), (0.0, K)].iter().map(|&d| { let s = step(&rk4, &fh, 0.0, d, 1.0);
        size(((s.0 - d.0) / 1.0, (s.1 - d.1) / 1.0), K) }).fold(0.0, f64::max);   // 1 m gaps, in height and in speed
    assert!(stretch <= lam(K, 1.0) && lam(K, 1.0) < 1.1 * stretch);  // Lambda bounds the measured stretch, closely
    assert!(9.0 < bound1 / true1 && bound1 / true1 < 11.0);           // the bound sits about 10 times above
    let ob = orders(&eb);
    assert!(0.95 < ob[1] && ob[1] < 1.05);                           // two swapped weights: order 1
    assert!(orders(er)[..4].iter().all(|&p| 3.9 < p && p < 4.2));   // RK4: order 4 overall
    let (oe, oh) = (orders(&errs[0]), orders(&errs[1]));
    assert!(0.95 < oe[1] && oe[1] < 1.05 && 1.9 < oh[1] && oh[1] < 2.1);
    assert!(31.0 < loc[0] / loc[1] && loc[0] / loc[1] < 33.0);       // one step: order 5 locally
    assert!(er[er.len() - 1] > er[lo] && 1e-13 < er[lo] && er[lo] < 1e-10);  // rounding stops the fall
    assert!((xt.0 - run(&rk4, &f, 1.0 / 64.0, (Y0, V0), T).0).abs() < 1e-9); // closed form vs fine run
    println!("ALL CHECKS PASS");
}
