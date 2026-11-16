// Lax-Milgram for steady heat in a two-material wall: constants, bounds, three roads.
const K1: f64 = 1.8; const K2: f64 = 0.04; // conductivity of concrete and formwork, W/(m K)
const S: f64 = 0.30; const D2: f64 = 0.05; // thickness of concrete and formwork, m
const F: f64 = 1000.0; // heating in the concrete, W/m^3
const L: f64 = S + D2;
const R2: f64 = D2 / K2;

// exact rise above the air, K: -(k u')' - beta*u = F in the concrete
fn closed(x: f64, beta: f64) -> f64 {
    let inner = |y: f64| -> f64 {
        if beta == 0.0 {
            let a = F * S * (1.0 + S / (2.0 * K1 * R2)) / (K1 + S / R2);
            -F * y * y / (2.0 * K1) + a * y
        } else {
            let mu = (beta / K1).sqrt();
            let (c, s) = ((mu * S).cos(), (mu * S).sin());
            let (p, q) = (F / beta * (c - 1.0), -F / beta * mu * s);
            let b = -(p / R2 + K1 * q) / (K1 * mu * c + s / R2);
            F / beta * ((mu * y).cos() - 1.0) + b * (mu * y).sin()
        }
    };
    if x <= S { inner(x) } else { inner(S) * (L - x).max(0.0) / D2 }
}

// solve a three-diagonal system; also return the smallest pivot (None if a pivot is zero)
fn thomas(lo: &[f64], di: &[f64], up: &[f64], rhs: &[f64]) -> (Option<Vec<f64>>, f64) {
    let n = di.len();
    let (mut d, mut r) = (di.to_vec(), rhs.to_vec());
    let mut piv = d[0].abs();
    for i in 1..n {
        if d[i - 1] == 0.0 { return (None, 0.0); }
        let m = lo[i] / d[i - 1];
        d[i] -= m * up[i - 1];
        r[i] -= m * r[i - 1];
        piv = piv.min(d[i].abs());
    }
    let mut x = vec![0.0; n];
    x[n - 1] = r[n - 1] / d[n - 1];
    for i in (0..n - 1).rev() { x[i] = (r[i] - up[i] * x[i + 1]) / d[i]; }
    (Some(x), piv)
}

struct Fem { u: Option<Vec<f64>>, piv: f64, di: Vec<f64>, off: Vec<f64>, md: Vec<f64>, mo: Vec<f64>, rhs: Vec<f64> }

// hat functions; node on the joint when 7 divides N
fn fem(n: usize, beta: f64, k2: f64, heat_all: bool, k1: f64) -> Fem {
    let h = L / n as f64;
    let (mut di, mut off, mut md, mut mo, mut rhs) = (vec![0.0; n - 1], vec![0.0; n - 1], vec![0.0; n - 1], vec![0.0; n - 1], vec![0.0; n - 1]);
    for e in 0..n {
        let conc = (e as f64 + 0.5) * h < S;
        let k = if conc { k1 } else { k2 };
        let w = if conc || heat_all { 1.0 } else { 0.0 };
        for i in [e as i64 - 1, e as i64] {
            if i >= 0 && (i as usize) < n - 1 {
                let i = i as usize;
                di[i] += k / h; md[i] += w * h / 3.0; rhs[i] += w * F * h / 2.0;
            }
        }
        if e >= 1 && e < n - 1 { off[e] = -k / h; mo[e] = w * h / 6.0; }
    }
    let lo: Vec<f64> = (0..n - 1).map(|i| off[i] - beta * mo[i]).collect();
    let mut up = lo[1..].to_vec(); up.push(0.0);
    let dd: Vec<f64> = (0..n - 1).map(|i| di[i] - beta * md[i]).collect();
    let (u, piv) = thomas(&lo, &dd, &up, &rhs);
    Fem { u, piv, di, off, md, mo, rhs }
}

fn mul(a: &[f64], b: &[f64], v: &[f64]) -> Vec<f64> {
    let n = v.len();
    (0..n).map(|i| a[i] * v[i] + (if i > 0 { b[i] * v[i - 1] } else { 0.0 }) + (if i + 1 < n { b[i + 1] * v[i + 1] } else { 0.0 })).collect()
}
fn dot(a: &[f64], b: &[f64]) -> f64 { let mut s = 0.0; for i in 0..a.len() { s += a[i] * b[i]; } s }

// inverse iteration: smallest lambda with K v = lambda M v
fn lowest_eig(n: usize, heat_all: bool) -> f64 {
    let k = if heat_all { 1.0 } else { K1 };
    let m = fem(n, 0.0, if heat_all { k } else { K2 }, heat_all, k);
    let mut up = m.off[1..].to_vec(); up.push(0.0);
    let mut v = vec![1.0; n - 1];
    for _ in 0..60 {
        v = thomas(&m.off, &m.di, &up, &mul(&m.md, &m.mo, &v)).0.unwrap();
        let s = v.iter().fold(0.0f64, |a, t| a.max(t.abs()));
        v = v.iter().map(|t| t / s).collect();
    }
    dot(&v, &mul(&m.di, &m.off, &v)) / dot(&v, &mul(&m.md, &m.mo, &v))
}

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {
    let n = 2000; let h = (b - a) / n as f64; let mut acc = 0.0;
    for i in 1..n { acc += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    h / 3.0 * (f(a) + f(b) + acc)
}

fn peak(beta: f64) -> (f64, f64) {
    let (mut bx, mut bv) = (0.0, closed(0.0, beta));
    for i in 0..7001 {
        let x = i as f64 * L / 7000.0; let v = closed(x, beta);
        if v.abs() > bv.abs() { bx = x; bv = v; }
    }
    (bx, bv)
}

fn tf(b: bool) -> &'static str { if b { "True" } else { "False" } }

fn main() {
    let (m, alpha, cp) = (K1, K2, L / std::f64::consts::PI);
    println!("wall: concrete {:.2} m k {:.3}, formwork {:.2} m k {:.3} W/(m K), heating {:.0} W/m3", S, K1, D2, K2, F);
    println!("constants: M = k_max {:.3}, alpha = k_min {:.3} W/(m K), M/alpha {:.1}", m, alpha, m / alpha);
    let cp_fe = 1.0 / lowest_eig(280, true).sqrt();
    println!("Poincare: C_P = L/pi {:.6} m, finite elements N = 280: {:.6} m", cp, cp_fe);
    println!("full Sobolev norm: alpha = k_min/(1 + C_P^2) = {:.6} (x in m); factor 1/(1 + C_P^2) = {:.5} (x in m), {:.7} (x in mm)", alpha / (1.0 + cp * cp), 1.0 / (1.0 + cp * cp), 1.0 / (1.0 + (1000.0 * cp).powi(2)));
    let fnorm = F * S.sqrt(); let lnorm = cp * fnorm; let ceil = lnorm / alpha; let pceil = L.sqrt() / 2.0 * ceil;
    println!("load: |f| {:.4} W/m^2.5, |l| at most C_P |f| = {:.4} W/m^1.5", fnorm, lnorm);
    println!("ceilings: |u'| at most {:.2} K/m^0.5, peak rise at most {:.2} K", ceil, pceil);
    let uj = closed(S, 0.0); let a0 = F * S * (1.0 + S / (2.0 * K1 * R2)) / (K1 + S / R2);
    let xp = a0 * K1 / F; let up_ = closed(xp, 0.0);
    println!("closed form: joint {:.4} K, peak {:.4} K at {:.4} m", uj, up_, xp);
    let (q0, ql) = (K1 * a0, uj / R2); // heat leaving each face, W/m2
    println!("by hand: formwork resistance {:.4} m2 K/W, slope at the bare face {:.4} K/m, sqrt(L)/2 = {:.6} m^0.5", R2, a0, L.sqrt() / 2.0);
    println!("heat out: bare face {:.4} W/m2, formwork face {:.4} W/m2, sum {:.4} = F S {:.4}", q0, ql, q0 + ql, F * S);
    let g1 = simpson(&|x| (a0 - F * x / K1).powi(2), 0.0, S); let g2 = (uj / D2).powi(2) * D2;
    let (grad, energy) = ((g1 + g2).sqrt(), K1 * g1 + K2 * g2);
    let work = simpson(&|x| F * closed(x, 0.0), 0.0, S);
    println!("|u'| = {:.4} K/m^0.5; energy a(u,u) = {:.4}, l(u) = {:.4} W K/m2", grad, energy, work);
    let ratio = energy / (grad * grad);
    println!("a(u,u)/|u'|^2 = {:.4}, between alpha and M: {}", ratio, tf(alpha - 1e-9 <= ratio && ratio <= m + 1e-9));
    assert!(alpha - 1e-9 <= ratio && ratio <= m + 1e-9); // the true profile obeys both constants (1e-9 for rounding)
    assert!((cp_fe - cp).abs() < 1e-5 && (q0 + ql - F * S).abs() < 1e-9);
    assert!((energy - work).abs() < 1e-9 * work && (up_ - peak(0.0).1).abs() < 1e-6 && grad <= ceil && up_ <= pceil);
    println!("Galerkin, beta = 0:   N  nodes exact to 1e-12  energy error W K/m2  ratio");
    let mut prev: Option<f64> = None;
    for n in [7usize, 14, 28, 56] {
        let r = fem(n, 0.0, K2, false, K1); let u = r.u.unwrap(); let h = L / n as f64;
        let err = (0..n - 1).fold(0.0f64, |a, i| a.max((u[i] - closed((i + 1) as f64 * h, 0.0)).abs()));
        let e = work - dot(&u, &r.rhs);
        let rs = match prev { Some(p) => format!("{:.3}", p / e), None => "  -".to_string() };
        println!("                   {:4}  {:>20}  {:19.6}  {}", n, tf(err < 1e-12), e, rs);
        assert!(err < 1e-12 && prev.map_or(true, |p| 3.9 < p / e && p / e < 4.1));
        prev = Some(e);
    }
    let lam1_fe: Vec<f64> = [70usize, 140, 280].iter().map(|&n| lowest_eig(n, false)).collect();
    let (mut a, mut b) = (std::f64::consts::PI / (2.0 * S), std::f64::consts::PI / S);
    let g = |m: f64| K1 * m * (S * m).cos() + (K2 / D2) * (S * m).sin();
    let mut mm = 0.0;
    for _ in 0..100 { mm = (a + b) / 2.0; if g(a) * g(mm) <= 0.0 { b = mm; } else { a = mm; } }
    let lam1 = K1 * mm * mm;
    println!("critical rate beta*: matching root {:.4}, finite elements N = 70/140/280: {:.4} {:.4} {:.4} W/(m3 K)", lam1, lam1_fe[0], lam1_fe[1], lam1_fe[2]);
    println!("crude Poincare test certifies beta < k_min/C_P^2 = {:.4} W/(m3 K) only", K2 / (cp * cp));
    assert!((lam1_fe[2] - lam1).abs() < 1e-3 && lam1_fe[0] > lam1_fe[1] && lam1_fe[1] > lam1_fe[2] && lam1_fe[2] > lam1);
    println!("  beta W/(m3 K)  beta/beta*  alpha_beta  peak closed K  peak N = 280 K");
    for r in [0.0, 0.5, 0.8, 0.9, 0.99, 1.01] {
        let beta = r * lam1; let (_, pb) = peak(beta);
        let u = fem(280, beta, K2, false, K1).u.unwrap();
        let pf = u.iter().fold(0.0f64, |a, &t| if t.abs() > a.abs() { t } else { a });
        println!("  {:12.4}  {:10.2}  {:10.5}  {:13.4}  {:14.4}", beta, r, (1.0 - r) * alpha, pb, pf);
        assert!((pf - pb).abs() < 2e-3 * pb.abs());
    }
    let piv0 = fem(70, 0.0, 0.0, false, K1).piv;
    println!("what breaks: formwork k = 0: smallest pivot {:.4}", piv0);
    println!("what breaks: beta = 1.01 beta*: rise {:.1} K, below the air", peak(1.01 * lam1).1);
    println!("what breaks: beta = 10: crude alpha {:.5}, true alpha {:.5}, peak {:.4} K", K2 - 10.0 * cp * cp, (1.0 - 10.0 / lam1) * alpha, peak(10.0).1);
    assert!(piv0 == 0.0 && peak(1.01 * lam1).1 < 0.0 && peak(10.0).1 > 0.0);
    let xs: Vec<String> = (0..8).map(|i| format!("{:7.2}", 0.05 * i as f64)).collect();
    println!("chart, x (m)       {}", xs.join(" "));
    for r in [0.0, 0.5, 0.8] {
        let ys: Vec<String> = (0..8).map(|i| format!("{:7.2}", closed(0.05 * i as f64, r * lam1))).collect();
        println!("chart, beta/beta* {:.1}{}", r, ys.join(" "));
    }
    println!("ALL CHECKS PASS");
}
