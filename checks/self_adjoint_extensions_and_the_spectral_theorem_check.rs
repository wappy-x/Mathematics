// Self-adjoint extensions -- the same check as the Python, in Rust.  No crates.
// A 1 m bar; the operator is A = -d^2/dx^2 (minus the bending).  Two choices of
// boundary condition: ends held at 0 C (Dirichlet) or ends insulated (Neumann).
use std::f64::consts::PI;

fn z(x: f64) -> f64 { if x.abs() < 5e-7 { 0.0 } else { x } }   // print a tiny rounding residue as 0

fn sci(x: f64, d: usize) -> String {       // Python's {:.de}: two-digit signed exponent
    let s = format!("{:.*e}", d, x);
    let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}

fn count_below(d: &[f64], e: f64, x: f64) -> usize {   // Sturm count: eigenvalues below x
    let (mut q, mut k) = (1.0f64, 0);
    for i in 0..d.len() {
        q = d[i] - x - if i > 0 { e * e / q } else { 0.0 };
        if q == 0.0 { q = 1e-300 }
        if q < 0.0 { k += 1 }
    }
    k
}

fn kth_eig(d: &[f64], e: f64, k: usize) -> f64 {        // k-th smallest eigenvalue by bisection
    let (mut lo, mut hi) = (-1.0, 4.0 * d.iter().cloned().fold(f64::MIN, f64::max) + 1.0);
    for _ in 0..100 {
        let mid = 0.5 * (lo + hi);
        if count_below(d, e, mid) > k { hi = mid } else { lo = mid }
    }
    0.5 * (lo + hi)
}

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, m: usize) -> f64 {   // Simpson's rule, m even
    let h = (b - a) / m as f64;
    let inner: f64 = (1..m).map(|j| (if j % 2 == 1 { 4.0 } else { 2.0 }) * f(a + j as f64 * h)).sum();
    (f(a) + f(b) + inner) * h / 3.0
}

const AR: f64 = std::f64::consts::FRAC_1_SQRT_2;
fn ue(x: f64, sg: f64) -> (f64, f64) {      // e^(sg a x), a = (1 - i)/sqrt 2, as (real, imaginary)
    ((sg * AR * x).exp() * (-sg * AR * x).cos(), (sg * AR * x).exp() * (-sg * AR * x).sin())
}
fn sh(x: f64) -> (f64, f64) { let (p, m) = (ue(x, 1.0), ue(x, -1.0)); (p.0 - m.0, p.1 - m.1) }

fn rayleigh(u: &dyn Fn(f64) -> (f64, f64)) -> (f64, f64) {  // pointwise eigen-check, Au by differences
    let hh = 1e-3;
    let (mut nr, mut ni, mut den) = (0.0, 0.0, 0.0);
    for j in 1..1000 {
        let (x, w) = (j as f64 * hh, if j % 2 == 0 { 2.0 } else { 4.0 });
        let ((ur, ui), (pr, pq), (mr, mq)) = (u(x), u(x + hh), u(x - hh));
        let (ar, ai) = (-(pr - 2.0 * ur + mr) / (hh * hh), -(pq - 2.0 * ui + mq) / (hh * hh));
        nr += w * (ur * ar + ui * ai);       // conjugate first slot
        ni += w * (ur * ai - ui * ar);
        den += w * (ur * ur + ui * ui);
    }
    (nr / den, ni / den)
}

fn main() {
    let pi2 = PI * PI;
    println!("finite rehearsal: the bar on a grid; every grid matrix is symmetric, domain = all vectors");
    println!("N     held: lam1     error vs pi^2   insulated: lam0  lam1");
    for n in [10usize, 100, 1000] {
        let h = 1.0 / (n as f64 + 1.0);
        let hn = 1.0 / n as f64;
        let dd = vec![2.0 / (h * h); n];
        let mut dn = vec![2.0 / (hn * hn); n];
        dn[0] = 1.0 / (hn * hn);
        dn[n - 1] = 1.0 / (hn * hn);
        let (l1, n0, n1) = (kth_eig(&dd, -1.0 / (h * h), 0), kth_eig(&dn, -1.0 / (hn * hn), 0), kth_eig(&dn, -1.0 / (hn * hn), 1));
        println!("{:<5} {:.9}   {}      {:.9}      {:.9}", n, l1, sci(l1 - pi2, 3), z(n0), n1);
        assert!((l1 - 4.0 / (h * h) * (PI * h / 2.0).sin().powi(2)).abs() < 1e-6 * l1);
        assert!(pi2 - l1 > 0.0 && pi2 - l1 < 1.1 * pi2 * pi2 * h * h / 12.0 && n0.abs() < 1e-6);
    }
    println!("limits: held n^2 pi^2 = {:.9}, {:.9}, {:.9}; insulated adds 0", pi2, 4.0 * pi2, 9.0 * pi2);
    println!("boundary form <Au, v> - <u, Av> on (0, 1): Simpson against the end terms [-u'v + u v']");
    type F = Box<dyn Fn(f64) -> f64>;
    let pairs: Vec<(&str, F, F, F, F, F, F)> = vec![
        ("held/held", Box::new(|x| x * (1.0 - x)), Box::new(|x| 1.0 - 2.0 * x), Box::new(|_| 2.0),
         Box::new(|x| (PI * x).sin()), Box::new(|x| PI * (PI * x).cos()), Box::new(|x| PI * PI * (PI * x).sin())),
        ("insulated/insulated", Box::new(|x| x * x - 2.0 * x * x * x / 3.0), Box::new(|x| 2.0 * x - 2.0 * x * x),
         Box::new(|x| 4.0 * x - 2.0), Box::new(|x| (PI * x).cos()), Box::new(|x| -PI * (PI * x).sin()),
         Box::new(|x| PI * PI * (PI * x).cos())),
        ("held/insulated", Box::new(|x| x * (1.0 - x)), Box::new(|x| 1.0 - 2.0 * x), Box::new(|_| 2.0),
         Box::new(|_| 1.0), Box::new(|_| 0.0), Box::new(|_| 0.0))];
    for (name, u, du, au, v, dv, av) in &pairs {
        let lhs = simpson(&|x| au(x) * v(x) - u(x) * av(x), 0.0, 1.0, 2000);
        let rhs = (-du(1.0) * v(1.0) + u(1.0) * dv(1.0)) - (-du(0.0) * v(0.0) + u(0.0) * dv(0.0));
        println!("  {:<20} Simpson {:.6}   end terms {:.6}", name, z(lhs), z(rhs));
        assert!((lhs - rhs).abs() < 1e-9);
    }
    let (rr, ri) = rayleigh(&|x| ue(x, 1.0));
    println!("no conditions at all: u = e^(a x), a = (1 - i)/sqrt2; <u, Au>/<u, u> = {:.6} + {:.6}i", z(rr), ri);
    assert!(rr.abs() < 1e-5 && (ri - 1.0).abs() < 1e-5);
    let s2 = 2f64.sqrt();
    println!("deficiency count: squared size int_0^R |u|^2 dx of the two solutions of -u'' = i u");
    println!("R     decaying e^(-a x)          growing e^(a x)");
    let mut size = vec![];
    for r in [1.0f64, 5.0, 10.0, 20.0] {
        let dec = simpson(&|x| (-s2 * x).exp(), 0.0, r, 2000);
        let gro = simpson(&|x| (s2 * x).exp(), 0.0, r, 20000);
        let (de, ge) = ((1.0 - (-s2 * r).exp()) / s2, ((s2 * r).exp() - 1.0) / s2);
        println!("{:<5} {:.6} (exact {:.6})  {} (exact {})", r, dec, de, sci(gro, 6), sci(ge, 6));
        assert!((dec - de).abs() < 1e-9 && (gro / ge - 1.0).abs() < 1e-8);
        size.push((dec, gro));
    }
    let settled = [size[3].0 - size[2].0 < 1e-3, size[3].1 - size[2].1 < 1e-3];   // does the size stop growing?
    let n_bar = [size[0].0, size[0].1].iter().filter(|v| v.is_finite()).count(); // on the bar both are finite
    let n_half = settled.iter().filter(|&&b| b).count();
    let n_line = (0..2).filter(|&k| settled[k] && settled[1 - k]).count();
    println!("so n+ = n- = {} on the bar (0, 1), {} on the half-line, {} on the whole line; bar extensions: {} x {} = {} real parameters",
             n_bar, n_half, n_line, n_bar, n_bar, n_bar * n_bar);
    assert!((n_half, n_line) == (1, 0));
    let (p1, m1) = (ue(1.0, 1.0), ue(1.0, -1.0));
    let sa = ((p1.0 - m1.0) / 2.0, (p1.1 - m1.1) / 2.0); // sinh(a); v(0) = 0 leaves sinh(a x), v'(0) = 0 cosh(a x)
    println!("+-i test on the bar: held ends need sinh(a) = 0, insulated ends a sinh(a) = 0; sinh(a) = {:.6} - {:.6}i, so n+ = n- = 0 for both", sa.0, -sa.1);
    assert!((sa.0 - AR.sinh() * AR.cos()).abs() < 1e-12 && (sa.1 + AR.cosh() * AR.sin()).abs() < 1e-12 && sa.0.hypot(sa.1) > 0.5);
    let mom: Vec<f64> = [5.0, 20.0].iter().map(|&r| simpson(&|x| (-2.0 * x).exp(), 0.0, r, 2000)).collect();
    println!("momentum -i d/dx on the half-line: |e^(-x)|^2 to R = 5, 20: {:.6}, {:.6}; e^x unbounded: n+ = 1, n- = 0", mom[0], mom[1]);
    assert!((mom[1] - 0.5).abs() < 1e-9);
    println!("spectral domain test for f = 1 (100 C everywhere), held-ends modes sqrt2 sin(n pi x)");
    println!("N      sum c_n^2    sum lam_n^2 c_n^2");
    for nn in [10usize, 100, 1000] {
        let c: Vec<f64> = (1..=nn).map(|n| s2 * (if n % 2 == 1 { 2.0 } else { 0.0 }) / (n as f64 * PI)).collect();
        let s: f64 = c.iter().map(|t| t * t).sum();
        let sl: f64 = (1..=nn).map(|n| (n as f64 * PI).powi(4) * c[n - 1] * c[n - 1]).sum();
        println!("{:<6} {:.6}     {}", nn, s, sci(sl, 6));
        assert!(1.0 - s > 0.0 && 1.0 - s < 4.1 / (pi2 * nn as f64));
    }
    let cs: Vec<f64> = [1.0, 2.0, 3.0].iter().map(|&n| simpson(&|x| s2 * (n * PI * x).sin(), 0.0, 1.0, 2000)).collect();
    println!("c_1, c_2, c_3 by Simpson: {:.6}, {:.6}, {:.6}; closed form 2sqrt2/(n pi) for odd n", cs[0], z(cs[1]), cs[2]);
    assert!((cs[0] - 2.0 * s2 / PI).abs() < 1e-9 && (cs[2] - 2.0 * s2 / (3.0 * PI)).abs() < 1e-9);
    let (kap, t0) = (1.0e-4, 100.0);       // diffusivity m^2/s (illustrative, about copper's); start 100 C
    let mid = |t: f64| t0 * (1..400).step_by(2).map(|n| { let nf = n as f64;
        4.0 / (nf * PI) * (if (n - 1) / 2 % 2 == 0 { 1.0 } else { -1.0 }) * (-kap * (nf * PI).powi(2) * t).exp() }).sum::<f64>();
    let mean = |t: f64| t0 * (1..400).step_by(2).map(|n| { let nf = n as f64;
        8.0 / (nf * PI).powi(2) * (-kap * (nf * PI).powi(2) * t).exp() }).sum::<f64>();
    let (h, dt) = (0.01, 0.25);            // grid road: 99 inside points, explicit steps of 0.25 s
    let (mut ud, mut un) = (vec![t0; 99], vec![t0; 100]);
    let r = kap * dt / (h * h);
    for _ in 0..2400 {                     // 600 s
        ud = (0..99).map(|i| ud[i] + r * ((if i > 0 { ud[i - 1] } else { 0.0 }) - 2.0 * ud[i] + (if i < 98 { ud[i + 1] } else { 0.0 }))).collect();
        un = (0..100).map(|i| un[i] + r * (un[i.saturating_sub(1)] - 2.0 * un[i] + un[(i + 1).min(99)])).collect();
    }
    let un_mean = un.iter().sum::<f64>() / 100.0;
    let e1 = kap * pi2 * 600.0;
    println!("by hand at 600 s: kappa pi^2 t = {:.6}; e^(-that) = {:.6}; modes 1, 3, 5 give {:.4}, {:.4}, {:.6} C", e1, (-e1).exp(),
             400.0 / PI * (-e1).exp(), -400.0 / (3.0 * PI) * (-9.0 * e1).exp(), 400.0 / (5.0 * PI) * (-25.0 * e1).exp());
    println!("after 600 s, ends held at 0 C: midpoint {:.4} C by modes, {:.4} C by grid; mean {:.4} C", mid(600.0), ud[49], mean(600.0));
    println!("after 600 s, ends insulated: midpoint 100.0000 C by modes (only lam0 = 0 survives), {:.4} C by grid; mean {:.4} C", un[50], un_mean);
    assert!((mid(600.0) - ud[49]).abs() < 0.02 && (un_mean - t0).abs() < 1e-9);
    println!("mistake: held-ends modes used for the insulated bar give {:.4} C, not 100.0000 C", mid(600.0));
    let (sr, si) = rayleigh(&sh);
    println!("mistake: only the left end held, u = e^(a x) - e^(-a x): <u, Au>/<u, u> = {:.6} + {:.6}i, not real", z(sr), si);
    assert!(sr.abs() < 1e-5 && (si - 1.0).abs() < 1e-5);
    let pts: Vec<String> = (5..61).step_by(5).map(|m| format!("{:.2}", mid(60.0 * m as f64))).collect();
    println!("chart, ends held: minutes 0,5,...,60 -> 100.00, {}", pts.join(", "));
    println!("ALL CHECKS PASS");
}
