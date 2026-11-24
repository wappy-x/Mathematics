// Friedrichs extension and energy forms -- the same check as the Python, in Rust.
// No crates.  The bar runs from 0 to pi with both ends held at 0.  The energy is
// q(u) = integral of u'^2.  A spike of strength ALPHA sits at the middle, pi/2,
// and adds ALPHA * u(pi/2)^2 to the energy.  Every grid matrix is a truncation.
use std::f64::consts::PI;
const ALPHA: f64 = 1.0;

fn count_below(d: &[f64], off: f64, x: f64) -> usize {  // Sturm count below x
    let (mut q, mut k) = (1.0f64, 0usize);
    for i in 0..d.len() {
        q = d[i] - x - if i > 0 { off * off / q } else { 0.0 };
        if q == 0.0 { q = 1e-300 }
        if q < 0.0 { k += 1 }
    }
    k
}

fn kth_eig(d: &[f64], off: f64, k: usize) -> f64 {    // k-th smallest eigenvalue by bisection
    let mx = d.iter().cloned().fold(f64::MIN, f64::max);
    let (mut lo, mut hi) = (-1.0, 4.0 * mx + 1.0);
    for _ in 0..100 {
        let mid = 0.5 * (lo + hi);
        if count_below(d, off, mid) > k { hi = mid } else { lo = mid }
    }
    0.5 * (lo + hi)
}

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {  // Simpson's rule, 2000 panels
    let m = 2000;
    let h = (b - a) / m as f64;
    let mut s = f(a) + f(b);
    for j in 1..m { s += if j % 2 == 1 { 4.0 } else { 2.0 } * f(a + j as f64 * h) }
    s * h / 3.0
}

fn root(g: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {  // bisection on a sign change
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if g(lo) * g(mid) > 0.0 { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}

fn kink(k: f64, a: f64) -> f64 {   // even mode: -u'' = k^2 u, slope jumps by a * u(pi/2)
    2.0 * k * (k * PI / 2.0).cos() + a * (k * PI / 2.0).sin()
}

fn sci(x: f64, p: usize) -> String {  // Python-style scientific notation, e.g. 7.766e-03
    let s = format!("{:.*e}", p, x);
    let (m, e) = s.split_once('e').unwrap();
    let ev: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if ev < 0 { '-' } else { '+' }, ev.abs())
}

fn join(v: &[f64]) -> String { v.iter().map(|x| format!("{:.3}", x)).collect::<Vec<_>>().join(", ") }

fn main() {
    let k1 = root(&|k| kink(k, ALPHA), 1.0, 2.0);
    let k3 = root(&|k| kink(k, ALPHA), 3.0, 4.0);
    let exact = [k1 * k1, 4.0, k3 * k3];   // the odd mode sin 2x is 0 at pi/2, so 4 stays
    println!("road 1, exact: an even mode needs 2k cos(k pi/2) + alpha sin(k pi/2) = 0");
    println!("  alpha = {:.0}: k = {:.9}, lowest = k^2 = {:.9}; levels {:.6}, {:.6}, {:.6}",
             ALPHA, k1, exact[0], exact[0], exact[1], exact[2]);
    println!("road 2, grid: N inside points, h = pi/(N+1), spike adds alpha/h to the middle diagonal");
    println!("N     no spike: lam1    lam2        lam3        spike: lam1   lam2        lam3");
    let mut errs = Vec::new();
    for &n in &[9usize, 99, 999] {
        let (h, m) = (PI / (n + 1) as f64, (n - 1) / 2);   // point m sits at x = pi/2
        let d = vec![2.0 / (h * h); n];
        let mut ds = d.clone();
        ds[m] += ALPHA / h;
        let plain: Vec<f64> = (0..3).map(|j| kth_eig(&d, -1.0 / (h * h), j)).collect();
        let spike: Vec<f64> = (0..3).map(|j| kth_eig(&ds, -1.0 / (h * h), j)).collect();
        println!("{:<5} {:.6}    {:.6}    {:.6}    {:.6}      {:.6}    {:.6}",
                 n, plain[0], plain[1], plain[2], spike[0], spike[1], spike[2]);
        for j in 0..3 {                    // grid closed form 4/h^2 sin^2(n h/2) for the plain bar
            let cf = 4.0 / (h * h) * ((j + 1) as f64 * h / 2.0).sin().powi(2);
            assert!((plain[j] - cf).abs() < 1e-8 * plain[j]);
        }
        errs.push((spike[0] - exact[0]).abs());
    }
    println!("spike lowest, grid error: N=9 {}, N=99 {}, N=999 {}", sci(errs[0], 3), sci(errs[1], 3), sci(errs[2], 3));
    assert!(errs[2] < 1e-5 && errs[2] < errs[1] && errs[1] < errs[0]);
    let sq = simpson(&|x: f64| x.cos().powi(2), 0.0, PI);
    let nn = simpson(&|x: f64| x.sin().powi(2), 0.0, PI);
    let ray = (sq + ALPHA * (PI / 2.0).sin().powi(2)) / nn;
    println!("road 3, Rayleigh bracket with the trial function sin x (in the form domain H^1_0):");
    println!("  q(sin) = {:.6}, ||sin||^2 = {:.6}, spike energy = {:.6}", sq, nn, (PI / 2.0).sin().powi(2));
    println!("  1 <= lowest = {:.6} <= (q + spike)/||sin||^2 = {:.6} = 1 + 2/pi = {:.6}", exact[0], ray, 1.0 + 2.0 / PI);
    assert!(1.0 <= exact[0] && exact[0] <= ray && (ray - (1.0 + 2.0 / PI)).abs() < 1e-9);
    println!("why the energy route picks held ends: ramps from 0 up to the constant 1 within eps of each end");
    println!("eps      L2 distance to 1   energy q    (closed forms sqrt(2 eps/3), 2/eps)");
    for &eps in &[0.1f64, 0.01, 0.001] {
        let mm = 200000;                   // midpoint sums over (0, pi)
        let ramp = |x: f64| 1.0f64.min(x / eps).min((PI - x) / eps);
        let s: f64 = (0..mm).map(|i| (1.0 - ramp((i as f64 + 0.5) * PI / mm as f64)).powi(2)).sum();
        let dist = (s * PI / mm as f64).sqrt();
        let mut en = 0.0f64;               // energy: (rise over run)^2 times run, each straight piece cut in 1000
        for &(a, b) in &[(0.0f64, eps), (eps, PI - eps), (PI - eps, PI)] {
            let xs: Vec<f64> = (0..=1000).map(|j| a + (b - a) * j as f64 / 1000.0).collect();
            en += (0..1000).map(|j| (ramp(xs[j + 1]) - ramp(xs[j])).powi(2) / (xs[j + 1] - xs[j])).sum::<f64>();
        }
        println!("{:<8} {:.6}           {:.1}", eps, dist, en);
        assert!((dist - (2.0 * eps / 3.0).sqrt()).abs() < 1e-4);
        assert!((en - 2.0 / eps).abs() < 1e-6 * en);
    }
    let nnc = 100;                          // insulated ends: N cells, mirror at each end
    let hn = PI / nnc as f64;
    let mut dn = vec![2.0 / (hn * hn); nnc];
    dn[0] = 1.0 / (hn * hn);
    dn[nnc - 1] = 1.0 / (hn * hn);
    let (n0, n1) = (kth_eig(&dn, -1.0 / (hn * hn), 0), kth_eig(&dn, -1.0 / (hn * hn), 1));
    println!("insulated ends (form on all of H^1), N=100: lowest {:.6}, next {:.6}", n0.abs(), n1);
    assert!(n0.abs() < 1e-6 && (n1 - 1.0).abs() < 1e-3);
    println!("form bound: u(pi/2)^2 <= ||u|| ||u'|| <= a ||u'||^2 + ||u||^2/(4a) for every a > 0");
    for &(name, w) in &[("sin x", PI / 2.0), ("tent, half-width 0.1", 0.1), ("tent, half-width 0.001", 0.001)] {
        let sinx = name == "sin x";        // t = distance from pi/2
        let u = move |t: f64| if sinx { t.cos() } else { 1.0 - t / w };
        let du = move |t: f64| if sinx { t.sin() } else { 1.0 / w };
        let nrm = (2.0 * simpson(&|t| u(t).powi(2), 0.0, w)).sqrt();
        let slope = (2.0 * simpson(&|t| du(t).powi(2), 0.0, w)).sqrt();
        println!("  {:<24} u(pi/2)^2 = {:.6} <= ||u|| ||u'|| = {:.6}", name, u(0.0).powi(2), nrm * slope);
        assert!(u(0.0).powi(2) <= nrm * slope);
    }
    println!("the spike is not an operator on L2: its output on sin x has grid size alpha/sqrt(h)");
    for &n in &[9usize, 99, 999] {
        let (h, m) = (PI / (n + 1) as f64, (n - 1) / 2);
        let u: Vec<f64> = (0..n).map(|i| ((i + 1) as f64 * h).sin()).collect();
        let vu = (h * (ALPHA / h * u[m]).powi(2)).sqrt();
        println!("  N={:<4} size {:.6}, closed form sqrt((N+1)/pi) = {:.6}; its energy alpha u(pi/2)^2 = {:.6}",
                 n, vu, ((n + 1) as f64 / PI).sqrt(), ALPHA * u[m].powi(2));
        assert!((vu - ((n + 1) as f64 / PI).sqrt()).abs() < 1e-9 * vu);
    }
    println!("a point couple u'(pi/2)^2 is not form-bounded: bump of half-width w, ratio pi^2/(pi^2 w + w^3)");
    for &w in &[0.1f64, 0.01, 0.001] {
        let qb = simpson(&|x: f64| (PI * (PI * x / w).cos()).powi(2), -w, w);
        let nb = simpson(&|x: f64| (w * (PI * x / w).sin()).powi(2), -w, w);
        println!("  w={:<6} q = {:.6}, ||u||^2 = {}, u'(pi/2)^2/(q + ||u||^2) = {:.4}", w, qb, sci(nb, 3), PI * PI / (qb + nb));
        assert!((PI * PI / (qb + nb) - PI * PI / (PI * PI * w + w * w * w)).abs() < 1e-6 / w);
    }
    let nrm2 = simpson(&|x: f64| (k1 * x).sin().powi(2), 0.0, PI / 2.0) * 2.0;  // even about pi/2
    assert!((nrm2 - (PI / 2.0 - (k1 * PI).sin() / (2.0 * k1))).abs() < 1e-9);
    let chart: Vec<f64> = (0..9).map(|j| (k1 * (j as f64 * PI / 8.0).min(PI - j as f64 * PI / 8.0)).sin() / nrm2.sqrt()).collect();
    let plain: Vec<f64> = (0..9).map(|j| (j as f64 * PI / 8.0).sin() / (PI / 2.0).sqrt()).collect();
    println!("chart, x = j pi/8, j = 0..8, both of unit L2 size");
    println!("  with spike: {}", join(&chart));
    println!("  sin x:      {}", join(&plain));
    println!("slowest heat pattern, half-life ln 2/lowest: no spike {:.6}, spike {:.6}", 2f64.ln(), 2f64.ln() / exact[0]);
    println!("mistake, energy not divided by ||sin||^2: {:.6}, which is no level of the bar", sq + ALPHA);
    println!("ALL CHECKS PASS");
}
