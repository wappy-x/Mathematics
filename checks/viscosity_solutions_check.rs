// Viscosity solutions -- the same check as the Python, in Rust.  No crates.
// A car breaks down at km x of a 10 km road with garages at km 0 and km 10.
// Limping on costs C dollars per km; stopping for a tow costs PSI dollars.
// Least cost u(x) = min(PSI, C x, C (L - x)) solves max(u - PSI, |u'| - C) = 0.
// Roads: the closed form, dynamic programming on a grid, smooth functions that
// touch the graph, comparison with sub- and supersolutions, vanishing viscosity.
const L: f64 = 10.0; const C: f64 = 30.0; const PSI: f64 = 120.0;  // km, $/km, $ (illustrative)
const K: f64 = 100.0; const HALF: f64 = 0.5; const NS: usize = 100; // curvature, window, samples
const H: f64 = 0.1; const N: usize = 100;                          // Bellman grid

fn value(x: f64, c: f64, psi: f64) -> f64 { psi.min(c * x).min(c * (L - x)) }   // road 1
fn u(x: f64) -> f64 { value(x, C, PSI) }
fn tent(x: f64) -> f64 { C * x.min(L - x) }                               // no tow on offer
fn phantom(x: f64) -> f64 { PSI.min(C * x).min(C * (x - 5.0).abs()).min(C * (L - x)) }
fn half_u(x: f64) -> f64 { 0.5 * u(x) }
fn flat(_x: f64) -> f64 { PSI }
fn mtent(x: f64) -> f64 { -tent(x) }
fn f_eq(r: f64, p: f64) -> f64 { (r - PSI).max(p.abs() - C) }          // the equation's left side
fn g_eq(_r: f64, p: f64) -> f64 { p.abs() - C }                         // no tow: |u'| - C
fn gflip(_r: f64, p: f64) -> f64 { C - p.abs() }                        // the same, sign flipped
type Fun = fn(f64) -> f64;
type Eq = fn(f64, f64) -> f64;

fn touches(f: Fun, x0: f64, p: f64, side: f64) -> bool {  // phi = f(x0) + p s + side K s^2
    for j in 1..=NS {
        for s in [-HALF * j as f64 / NS as f64, HALF * j as f64 / NS as f64] {
            let gap = f(x0) + p * s + side * K * s * s - f(x0 + s);
            if side * gap < -1e-9 { return false; }
        }
    }
    true
}
fn test(f: Fun, x0: f64, eq: Eq) -> (Vec<i32>, Vec<i32>, Option<f64>, Option<f64>) {
    let slopes: Vec<i32> = (-8..=8).map(|k| 5 * k).collect();
    let above: Vec<i32> = slopes.iter().copied().filter(|&p| touches(f, x0, p as f64, 1.0)).collect();
    let below: Vec<i32> = slopes.iter().copied().filter(|&p| touches(f, x0, p as f64, -1.0)).collect();
    let sub = above.iter().map(|&p| eq(f(x0), p as f64)).fold(None, |m: Option<f64>, v| Some(m.map_or(v, |m| m.max(v))));
    let sup = below.iter().map(|&p| eq(f(x0), p as f64)).fold(None, |m: Option<f64>, v| Some(m.map_or(v, |m| m.min(v))));
    (above, below, sub, sup)
}
fn ok(f: Fun, x0: f64, eq: Eq, need: &str) -> bool {
    let (_, _, sub, sup) = test(f, x0, eq);
    let gs = sub.map_or(true, |v| v <= 1e-9);
    let gp = sup.map_or(true, |v| v >= -1e-9);
    match need { "sub" => gs, "super" => gp, _ => gs && gp }
}
fn show(name: &str, f: Fun, x0: f64, eq: Eq) {
    let (a, b, sub, sup) = test(f, x0, eq);
    let rng = |s: &Vec<i32>| if s.is_empty() { "none".to_string() } else { format!("{} to {}", s[0], s[s.len() - 1]) };
    let num = |v: Option<f64>| v.map_or("-".to_string(), |v| format!("{:.0}", v));
    println!("{:<20} km {:3.1}: value {:7.2} $; from above {:>9}, max F {:>2}; from below {:>9}, min F {:>3}",
             name, x0, f(x0), rng(&a), num(sub), rng(&b), num(sup));
}
fn dp(start: f64) -> (Vec<f64>, usize) {
    let mut v = vec![start; N + 1]; v[0] = 0.0; v[N] = 0.0;
    let mut sweeps = 0;
    loop {
        let mut new = vec![0.0; N + 1];
        for i in 1..N { new[i] = PSI.min(C * H + v[i - 1].min(v[i + 1])); }
        sweeps += 1;
        let d = new.iter().zip(&v).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max);
        if d < 1e-12 { return (new, sweeps); }
        v = new;
    }
}
fn visc(x: f64, e: f64) -> f64 {                     // -e u'' + |u'| = C, u(0) = u(L) = 0
    let y = x.min(L - x);
    C * y - C * e * (((y - L / 2.0) / e).exp() - (-L / 2.0 / e).exp())
}
fn resid(x: f64, e: f64, d: f64) -> f64 {           // centred differences
    let u2 = (visc(x + d, e) - 2.0 * visc(x, e) + visc(x - d, e)) / (d * d);
    let u1 = (visc(x + d, e) - visc(x - d, e)) / (2.0 * d);
    -e * u2 + u1.abs() - C
}
fn main() {
    let grid: Vec<f64> = (0..=N).map(|i| i as f64 * H).collect();
    let (down, s1) = dp(PSI);
    let (up, s2) = dp(0.0);
    let err = down.iter().zip(&grid).map(|(d, &x)| (d - u(x)).abs()).fold(0.0, f64::max);
    let err2 = up.iter().zip(&grid).map(|(d, &x)| (d - u(x)).abs()).fold(0.0, f64::max);
    println!("road {:.0} km, garages at km 0 and 10; limping {:.0} $/km; tow {:.0} $", L, C, PSI);
    println!("closed form: u(3) = {:.2} $, u(4) = {:.2} $, u(5) = {:.2} $, u(6) = {:.2} $", u(3.0), u(4.0), u(5.0), u(6.0));
    println!("stop where u = tow fee: km {:.2} to {:.2}; no-tow tent at km 5: {:.2} $", PSI / C, L - PSI / C, tent(5.0));
    println!("dynamic programming, step 0.1 km: from above {} sweeps, from below {} sweeps; both equal the closed form to 1e-9 $ at all {} nodes: {}",
             s1, s2, N + 1, if err < 1e-9 && err2 < 1e-9 { "yes" } else { "no" });
    println!("by hand at km 4: slope 40 line at km 3.9 gives {:.2} $, u(3.9) = {:.2} $", 120.0 + 40.0 * (3.9 - 4.0), u(3.9));
    for x in [3.0, 4.0, 5.0, 6.0] { show("value u", u, x, f_eq); }
    show("phantom garage", phantom, 5.0, f_eq); show("phantom garage", phantom, 2.5, f_eq);
    show("tent, no tow", tent, 5.0, g_eq); show("tent, flipped sign", tent, 5.0, gflip);
    show("minus tent, flipped", mtent, 5.0, gflip);
    let inner: Vec<f64> = grid[1..N].to_vec();
    let fails = |f: Fun, need: &str| -> Vec<f64> { inner.iter().copied().filter(|&x| !ok(f, x, f_eq, need)).collect() };
    let (fu, fph, fph_sub) = (fails(u, "both"), fails(phantom, "super"), fails(phantom, "sub"));
    let smooth: Vec<f64> = inner.iter().copied().filter(|&x| ![25, 50, 75].contains(&((x * 10.0).round() as i32))).collect();
    let ae = smooth.iter().map(|&x| f_eq(phantom(x), (phantom(x + 0.01) - phantom(x - 0.01)) / 0.02).abs()).fold(0.0, f64::max);
    println!("grid scan, {} points: u fails a test at {}; phantom fails at {} (km {:.1}, the super test) and the sub test at {}",
             inner.len(), fu.len(), fph.len(), fph[0], fph_sub.len());
    println!("phantom's largest |F| at its {} smooth grid points: {:.6} $/km", smooth.len(), ae);
    let subs: [Fun; 2] = [half_u, phantom];
    let sups: [Fun; 2] = [tent, flat];
    for &f in &subs { assert!(fails(f, "sub").is_empty()); }
    for &f in &sups { assert!(fails(f, "super").is_empty()); }
    let gap_lo = subs.iter().flat_map(|&f| grid.iter().map(move |&x| u(x) - f(x))).fold(f64::INFINITY, f64::min);
    let gap_hi = sups.iter().flat_map(|&f| grid.iter().map(move |&x| f(x) - u(x))).fold(f64::INFINITY, f64::min);
    println!("comparison on all {} nodes: least of u - sub {:.2} $, least of super - u {:.2} $", N + 1, gap_lo, gap_hi);
    println!("  at km 5: half of u {:.2}, phantom {:.2} <= u {:.2} <= flat {:.2}, tent {:.2} $",
             half_u(5.0), phantom(5.0), u(5.0), flat(5.0), tent(5.0));
    let eps = [1.0, 0.5, 0.25, 0.125];
    let row = |f: &dyn Fn(f64) -> f64, w: usize, d: usize| eps.iter().map(|&e| format!("{:w$.d$}", f(e), w = w, d = d)).collect::<String>();
    println!("vanishing viscosity, eps km    {}", row(&|e| e, 9, 3));
    println!("  u_eps(5) $                   {}", row(&|e| visc(5.0, e), 9, 4));
    println!("  tent(5) - u_eps(5) $         {}", row(&|e| tent(5.0) - visc(5.0, e), 9, 4));
    let (r1, r2) = (resid(2.0, 0.5, 0.01).abs(), resid(2.0, 0.5, 0.005).abs());
    println!("  residual at km 2, eps 0.5, step 0.01, 0.005 km: {:.3} {:.3} x 1e-6 $/km", r1 * 1e6, r2 * 1e6);
    println!("  first-order residual at the top, km 5: {:.0} $/km for every eps", g_eq(visc(5.0, 0.5), 0.0));
    let chart = |name: &str, f: &dyn Fn(f64) -> f64| println!("{:<19}{}", name, (0..=10).map(|x| format!("{:8.2}", f(x as f64))).collect::<String>());
    println!("chart, km          {}", (0..=10).map(|x| format!("{:>8}", x)).collect::<String>());
    chart("chart, eps 1 km", &|x| visc(x, 1.0));
    chart("chart, eps 0.25 km", &|x| visc(x, 0.25));
    chart("chart, tent", &|x| tent(x));
    println!("mistake 1, phantom garage at km 5: {:.2} $, not {:.2} $; tooth tops {:.2} $", phantom(5.0), u(5.0), phantom(2.5));
    println!("mistake 2, sign flipped, no tow: {:.2} $ at km 5, not {:.2} $", -tent(5.0), tent(5.0));
    println!("mistake 3, tow forgotten: {:.2} $ at km 5, not {:.2} $", tent(5.0), u(5.0));
    println!("try: tow 150 $ gives u(5) = {:.2} $; damage 20 $/km gives u(5) = {:.2} $; eps 0.05 km gives u_eps(5) = {:.4} $",
             value(5.0, C, 150.0), value(5.0, 20.0, PSI), visc(5.0, 0.05));
    println!("figure, x 0 to 10 km at 50 px/km from 60; y 0 to 160 $ at 1.5 px/$ up from 300; kinks (4, {:.0}) (6, {:.0}); phantom teeth (2.5, {:.0}) (5, {:.0}) (7.5, {:.0})",
             u(4.0), u(6.0), phantom(2.5), phantom(5.0), phantom(7.5));
    assert!(err < 1e-9 && err2 < 1e-9);                            // Bellman grid = closed form
    let t4 = test(u, 4.0, f_eq);
    assert!(t4.0 == vec![0, 5, 10, 15, 20, 25, 30] && t4.1.is_empty());
    assert!(fu.is_empty() && fph == vec![5.0] && fph_sub.is_empty() && ae < 1e-6);
    assert!(test(tent, 5.0, gflip).2.unwrap() > 0.0 && ok(mtent, 5.0, gflip, "both"));
    assert!(gap_lo >= 0.0 && gap_hi >= 0.0 && gap_lo.abs() < 1e-9);  // phantom touches u at km 0
    for &e in &eps {
        let d = tent(5.0) - visc(5.0, e);
        assert!(0.0 < d && d <= C * e && visc(0.0, e).abs() < 1e-9); // below the tent; u_eps(0) = 0
    }
    assert!(r2 < r1 / 3.0 && r1 < 1e-3);                            // second order in the step
    println!("ALL CHECKS PASS");
}
