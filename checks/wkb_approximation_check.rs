// WKB approximation -- the same check as the Python, in Rust, std only.
// A string whose mass per length grows as (1 + x)^2 obeys y'' + lam^2 (1 + x)^2 y = 0
// on [0, 1] with y(0) = y(1) = 0.  Its eigenvalues lam_n are found three ways: the WKB
// rule lam * S = n pi, RK4 shooting, and the exact Bessel-function solution.  Then two
// places where WKB fails: a sudden jump in mass, and a turning point (Airy).
use std::f64::consts::PI;

fn q_str(x: f64) -> f64 { (1.0 + x).powi(2) }       // mass per length over its light-end value
fn q_step(x: f64) -> f64 { if x < 0.5 { 1.0 } else { 4.0 } } // two uniform halves, mass ratio 4

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 { // phase integral S
    let h = (b - a) / n as f64;
    let mut s = 0.0;
    for i in 0..=n {
        let w = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        s += w * f(a + i as f64 * h);
    }
    h / 3.0 * s
}

// RK4 on y'' = -lam^2 q y, y(0) = 0, y'(0) = lam; returns y(1), or y every `every` steps
fn shoot(lam: f64, q: &dyn Fn(f64) -> f64, n: usize, every: usize) -> (f64, Vec<f64>) {
    let (h, mut y, mut v, mut out) = (1.0 / n as f64, 0.0, lam, vec![0.0]);
    let f = |x: f64, y: f64, v: f64| (v, -lam * lam * q(x) * y);
    for i in 0..n {
        let x = i as f64 * h;
        let k1 = f(x, y, v);
        let k2 = f(x + h / 2.0, y + h / 2.0 * k1.0, v + h / 2.0 * k1.1);
        let k3 = f(x + h / 2.0, y + h / 2.0 * k2.0, v + h / 2.0 * k2.1);
        let k4 = f(x + h, y + h * k3.0, v + h * k3.1);
        y += h / 6.0 * (k1.0 + 2.0 * k2.0 + 2.0 * k3.0 + k4.0);
        v += h / 6.0 * (k1.1 + 2.0 * k2.1 + 2.0 * k3.1 + k4.1);
        if every > 0 && (i + 1) % every == 0 { out.push(y) }
    }
    (y, out)
}

fn bisect(g: &dyn Fn(f64) -> f64, mut a: f64, mut b: f64) -> f64 { // one sign change inside [a, b]
    let mut ga = g(a);
    for _ in 0..60 {
        let m = 0.5 * (a + b);
        let gm = g(m);
        if (gm < 0.0) == (ga < 0.0) { a = m; ga = gm } else { b = m }
    }
    0.5 * (a + b)
}

fn bj(nu: f64, z: f64) -> f64 {                     // Bessel series, without its constant factor
    let (mut t, mut s) = ((z / 2.0).powf(nu), 0.0);
    for m in 0..80 {
        s += t;
        t *= -(z / 2.0).powi(2) / ((m + 1) as f64 * ((m + 1) as f64 + nu));
    }
    s
}

fn bessel(lam: f64) -> f64 {                        // y = sqrt(t) [A J(1/4, lam t^2/2) + B J(-1/4, .)]
    bj(0.25, lam / 2.0) * bj(-0.25, 2.0 * lam) - bj(-0.25, lam / 2.0) * bj(0.25, 2.0 * lam)
}

fn peaks(ys: &[f64]) -> Vec<f64> {                  // largest |y| in each lobe
    let (mut out, mut cur) = (vec![], 0.0f64);
    for w in ys.windows(2) {
        if w[0] != 0.0 && (w[0] < 0.0) != (w[1] < 0.0) { out.push(cur); cur = 0.0 }
        cur = cur.max(w[1].abs());
    }
    out.push(cur);
    out
}

fn g_step(l: f64) -> f64 { 2.0 * (l / 2.0).sin() * (1.0 - 2.0 * (l / 2.0).sin().powi(2)) + (1.0 - 2.0 * (l / 4.0).sin().powi(2)) * l.sin() }
fn row(lab: &str, v: &[f64]) -> String { format!("{}{}", lab, v.iter().map(|y| format!(" {:5.2}", y)).collect::<String>()) }

fn main() {
    let s = simpson(&|x| q_str(x).sqrt(), 0.0, 1.0, 1000);
    let (l, c0) = (0.65, 2.0 * 0.65 * 110.0);       // metres; light-end wave speed, m/s
    let hz = c0 / (2.0 * PI * l);                   // f = lam c0 / (2 pi L)
    println!("string: y'' + lam^2 (1 + x)^2 y = 0 on [0, 1], y(0) = y(1) = 0");
    println!("phase integral S by Simpson {:.6}   L {:.2} m   c0 {:.1} m/s   f = lam x {:.4} Hz", s, l, c0, hz);
    println!(" n   WKB nπ/S  shooting    Bessel  corrected  WKB err  n x err  WKB ¢  corr ¢  slowness");
    let mut rows = vec![];
    for n in 1..=5 {
        let w = n as f64 * PI / s;
        let ex = bisect(&|x| shoot(x, &q_str, 2000, 0).0, w - 1.0, w + 1.0);
        let bs = bisect(&bessel, w - 1.0, w + 1.0);
        let co = (w * w - 3.0 / 16.0).sqrt();       // first correction: lam^2 = (n pi/S)^2 + mean of Q
        rows.push((w, ex, bs, co));
        println!("{:2} {:10.6} {:9.6} {:9.6} {:10.6} {:8.6} {:8.6} {:+6.2} {:+7.2} {:9.3}", n, w, ex, bs, co, w - ex,
                 n as f64 * (w - ex), 1200.0 * (w / ex).log2(), 1200.0 * (co / ex).log2(), 2.0 / ex);
    }
    println!("limit of n x err, 9/(64 pi) = {:.6}", 9.0 / (64.0 * PI));
    let fr: Vec<String> = rows[..3].iter().enumerate()
        .map(|(i, r)| format!("n={} WKB {:.2} exact {:.2}", i + 1, r.0 * hz, r.1 * hz)).collect();
    println!("frequency, Hz: {}", fr.join("   "));
    let grid: Vec<f64> = (0..=2000).map(|i| i as f64 / 2000.0).collect();
    let w5 = rows[4].0;
    let e5 = shoot(rows[4].1, &q_str, 2000, 1).1;
    let pe = peaks(&e5[..2000]);
    let wk5: Vec<f64> = grid.iter().map(|&x| q_str(x).powf(-0.25) * (w5 * (x + x * x / 2.0)).sin()).collect();
    let nq5: Vec<f64> = grid.iter().map(|&x| (w5 * (x + x * x / 2.0)).sin()).collect();
    let (pw, pn) = (peaks(&wk5[..2000]), peaks(&nq5[..2000]));
    let r = |p: &Vec<f64>| p[p.len() - 1] / p[0];
    println!("mode 5, last lobe peak / first lobe peak: exact {:.4}   WKB {:.4}   no q^(-1/4) {:.4}", r(&pe), r(&pw), r(&pn));
    println!("mistake, light-end speed only, lam_1 = pi {:.4} ({:.2} Hz); heavy end only pi/2 {:.4} ({:.2} Hz)", PI, PI * hz, PI / 2.0, PI / 2.0 * hz);

    println!("jump: two uniform halves, mass ratio 4 (2 tan(lam/2) + tan(lam) = 0); WKB still n pi/1.5");
    println!(" n     exact  shooting       WKB   WKB err");
    let mut step = vec![];
    for n in 1..=5 {
        let w = n as f64 * PI / 1.5;
        let (ex, sh) = (bisect(&g_step, w - 1.0, w + 1.0), bisect(&|x| shoot(x, &q_step, 2000, 0).0, w - 1.0, w + 1.0));
        step.push((ex, sh, w));
        println!("{:2} {:9.6} {:9.6} {:9.6} {:+9.6}", n, ex, sh, w, w - ex);
    }
    println!("first jump eigenvalue 2 atan(sqrt 2) = {:.6}", 2.0 * 2f64.sqrt().atan());

    let fa = |z: f64, u: f64, v: f64| (v, z * u);   // Airy: u'' = z u, integrated from z = 8 down
    let (h, mut z, mut u) = (1e-4f64, 8.0f64, 1e-6f64);
    let mut v = -(8.0f64).sqrt() * 1e-6;
    let (mut zeros, mut big, mut slope) = (vec![], 0.0f64, 0.0);
    for _ in 0..(14.0 / h).round() as usize {
        let k1 = fa(z, u, v);
        let k2 = fa(z - h / 2.0, u - h / 2.0 * k1.0, v - h / 2.0 * k1.1);
        let k3 = fa(z - h / 2.0, u - h / 2.0 * k2.0, v - h / 2.0 * k2.1);
        let k4 = fa(z - h, u - h * k3.0, v - h * k3.1);
        let un = u - h / 6.0 * (k1.0 + 2.0 * k2.0 + 2.0 * k3.0 + k4.0);
        v -= h / 6.0 * (k1.1 + 2.0 * k2.1 + 2.0 * k3.1 + k4.1);
        if zeros.is_empty() { big = big.max(un.abs()) }
        if (un < 0.0) != (u < 0.0) {
            zeros.push(-(z - h * u / (u - un)));
            if zeros.len() == 1 { slope = v }
        }
        u = un;
        z -= h;
    }
    println!("turning point: y'' + lam^2 (1 - x) y = 0, y(0) = 0, y decays past x = 1; exact lam = a^(3/2)");
    println!(" n  Airy zero a  exact lam  (n - 1/4) rule  error   naive n rule  error");
    let mut tp = vec![];
    for (i, &a) in zeros[..3].iter().enumerate() {
        let n = (i + 1) as f64;
        let (ex, co, nv) = (a.powf(1.5), 1.5 * PI * (n - 0.25), 1.5 * PI * n);
        tp.push((a, ex, co, nv));
        println!("{:2} {:12.9} {:10.6} {:15.6} {:+.4} {:14.6} {:+.4}", i + 1, a, ex, co, co - ex, nv, nv - ex);
    }
    let (lam1, co1) = (tp[0].1, tp[0].2);
    let wk: Vec<f64> = [0.99, 0.9999].iter().map(|&x: &f64| (1.0 - x).powf(-0.25) * (co1 * 2.0 / 3.0 * (1.0 - (1.0 - x).powf(1.5))).sin()).collect();
    println!("mode 1, both with slope lam at x = 0: exact largest |y| {:.4}   WKB at x = 0.99 {:.4}, at x = 0.9999 {:.4}",
             lam1.powf(1.0 / 3.0) * big / slope.abs(), wk[0], wk[1]);
    let xs: Vec<f64> = (0..21).map(|k| 0.05 * k as f64).collect();
    let ce = shoot(rows[2].1, &q_str, 2000, 100).1;
    let cw: Vec<f64> = xs.iter().map(|&x| q_str(x).powf(-0.25) * (rows[2].0 * (x + x * x / 2.0)).sin()).collect();
    println!("{}", row("chart, x         ", &xs));
    println!("{}", row("chart, exact n=3 ", &ce));
    println!("{}", row("chart, WKB n=3   ", &cw));

    assert!((s - 1.5).abs() < 1e-9, "Simpson must land on the integral of (1 + x), 1.5");
    assert!(rows.iter().all(|r| (r.1 - r.2).abs() < 1e-7), "shooting and the Bessel solution must agree");
    assert!(rows[4].0 - rows[4].1 < (rows[0].0 - rows[0].1) / 3.0, "WKB error must fall as n grows");
    assert!((5.0 * (rows[4].0 - rows[4].1) - 9.0 / (64.0 * PI)).abs() < 0.002, "n x error must approach 9/(64 pi)");
    assert!(rows[2..].iter().all(|t| (t.3 - t.1).abs() < (t.0 - t.1) / 4.0), "the correction must beat plain WKB from n = 3");
    assert!((r(&pe) - r(&pw)).abs() < 0.01, "q^(-1/4) must predict the lobe heights");
    assert!(ce.iter().zip(&cw).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max) < 0.02, "WKB mode 3 must trace the exact mode");
    assert!(step.iter().all(|t| (t.0 - t.1).abs() < 1e-3) && (step[0].0 - 2.0 * 2f64.sqrt().atan()).abs() < 1e-9, "jump: two roads");
    assert!(step.iter().map(|t| (t.2 - t.0).abs()).filter(|&d| d > 1e-6).fold(f64::MAX, f64::min) > 0.18, "jump: WKB error does not fall");
    assert!((tp[0].0 - 2.338107410).abs() < 1e-6, "first Airy zero, DLMF table 9.9.1");
    assert!(tp.iter().all(|t| (t.3 - t.1).abs() > 1.1 && (t.2 - t.1).abs() < 0.05), "turning point needs the 1/4");
    println!("ALL CHECKS PASS");
}
