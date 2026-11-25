// Bochner spaces and the weak heat equation -- the check behind the card.
// Standard library only.  A copper rod 1 m long, ends held at 0 C, diffusivity
// 1.11e-4 m^2/s, starting at 100 C on 0.4 < x < 0.6 m and 0 C elsewhere.
// Roads: (1) the sine series with closed-form coefficients; (2) the heat kernel
// with images, integrated by Simpson's rule; (3) Galerkin on N sine modes, its
// matrices and loads by Simpson, solved by Gauss-Jordan, stepped by
// Crank-Nicolson; (4) the energy identity and the decay bound.
use std::f64::consts::PI;
const KAP: f64 = 1.11e-4; const T: f64 = 60.0; const HOT: f64 = 100.0; const A: f64 = 0.4; const B: f64 = 0.6;
const E0: f64 = 0.5 * HOT * HOT * (B - A); // start energy, C^2 m
type Mat = Vec<Vec<f64>>;

fn nsum<I: Iterator<Item = f64>>(it: I) -> f64 { // compensated, the same rule as Python's sum() of floats
    let (mut s, mut c) = (0.0f64, 0.0f64);
    for x in it { let t = s + x; if s.abs() >= x.abs() { c += (s - t) + x } else { c += (x - t) + s } s = t; }
    if c != 0.0 && c.is_finite() { s + c } else { s }
}
fn sci(v: f64) -> String {
    if v == 0.0 { return "0.000e+00".to_string(); }
    let mut e = v.abs().log10().floor() as i32;
    let mut m = v / 10f64.powf(e as f64);
    if m.abs() >= 9.9995 { m /= 10.0; e += 1; }
    format!("{:.3}e{}{:02}", m, if e >= 0 { '+' } else { '-' }, e.abs())
}
fn lam(n: usize) -> f64 { (n as f64 * PI).powi(2) }
fn bn(n: usize) -> f64 { let np = n as f64 * PI; 2.0 * HOT / np * ((np * A).cos() - (np * B).cos()) }
fn series(x: f64, t: f64) -> f64 { nsum((1..=2000).map(|n| bn(n) * (n as f64 * PI * x).sin() * (-KAP * lam(n) * t).exp())) }
fn energy(t: f64) -> f64 { nsum((1..=2000).map(|n| bn(n).powi(2) * (-2.0 * KAP * lam(n) * t).exp())) / 4.0 }
fn bound(t: f64) -> f64 { E0 * (-2.0 * PI.powi(2) * KAP * t).exp() }
fn weights(a: f64, b: f64, m: usize) -> Vec<f64> {
    (0..=m).map(|i| (b - a) / m as f64 / 3.0 * if i == 0 || i == m { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }).collect()
}
fn kernel(x: f64, t: f64) -> f64 { // heat kernel with images at 0 and 1 m
    let (m, s) = (400usize, 4.0 * KAP * t);
    let (w, mut tot) = (weights(A, B, m), 0.0);
    for i in 0..=m {
        let y = A + (B - A) * i as f64 / m as f64;
        tot += w[i] * nsum([-1.0f64, 0.0, 1.0].iter().map(|&k| (-(x - y - 2.0 * k).powi(2) / s).exp() - (-(x + y - 2.0 * k).powi(2) / s).exp()));
    }
    HOT * tot / (PI * s).sqrt()
}
fn solve(am: &Mat, bm: &Mat) -> Mat { // Gauss-Jordan, partial pivoting: am X = bm
    let n = am.len();
    let mut m: Mat = (0..n).map(|i| { let mut r = am[i].clone(); r.extend_from_slice(&bm[i]); r }).collect();
    for c in 0..n {
        let mut p = c;
        for r in c + 1..n { if m[r][c].abs() > m[p][c].abs() { p = r; } }
        m.swap(c, p); let piv = m[c][c];
        m[c] = m[c].iter().map(|v| v / piv).collect();
        for r in 0..n {
            if r != c && m[r][c] != 0.0 {
                let (f, rc) = (m[r][c], m[c].clone());
                m[r] = m[r].iter().zip(rc.iter()).map(|(a, b)| a - f * b).collect();
            }
        }
    }
    m.iter().map(|r| r[n..].to_vec()).collect()
}
fn en(v: &[f64], g: &Mat) -> f64 {
    let n = v.len();
    0.5 * nsum((0..n).flat_map(|i| (0..n).map(move |j| (i, j))).map(|(i, j)| v[i] * g[i][j] * v[j]))
}
fn galerkin(mm: &Mat, kk: &Mat, f: &[f64], n: usize, dt: f64) -> (Vec<f64>, Vec<f64>, f64, f64, f64, f64) {
    let mn: Mat = mm[..n].iter().map(|r| r[..n].to_vec()).collect();
    let kn: Mat = kk[..n].iter().map(|r| r[..n].to_vec()).collect();
    let mut c: Vec<f64> = solve(&mn, &f[..n].iter().map(|&x| vec![x]).collect()).iter().map(|r| r[0]).collect();
    let h = KAP * dt / 2.0;
    let st = solve(&(0..n).map(|i| (0..n).map(|j| mn[i][j] + h * kn[i][j]).collect()).collect(),
                   &(0..n).map(|i| (0..n).map(|j| mn[i][j] - h * kn[i][j]).collect()).collect());
    let (e_start, mut diss, mut worst, c0) = (en(&c, &mn), 0.0f64, 0.0f64, c.clone());
    for step in 0..(T / dt).round() as usize {
        let cn: Vec<f64> = (0..n).map(|i| nsum((0..n).map(|j| st[i][j] * c[j]))).collect();
        let mid: Vec<f64> = c.iter().zip(cn.iter()).map(|(a, b)| (a + b) / 2.0).collect();
        diss += KAP * dt * 2.0 * en(&mid, &kn); c = cn;
        worst = worst.max(en(&c, &mn) / bound((step + 1) as f64 * dt));
    }
    let et = en(&c, &mn); (c0, c, e_start, et, diss, worst)
}
fn at(c: &[f64], x: f64) -> f64 { nsum(c.iter().enumerate().map(|(k, ck)| ck * (((k + 1) as f64) * PI * x).sin())) }
fn rms_gap(c: &[f64], t: f64) -> f64 { (0.5 * nsum(c.iter().enumerate().map(|(k, ck)| (ck - bn(k + 1) * (-KAP * lam(k + 1) * t).exp()).powi(2)))).sqrt() }
fn row(label: &str, v: &[String]) { println!("{}{}", label, v.join(" ")); }

fn main() {
    println!("rod 1 m, kappa {} m^2/s, 100 C on 0.4..0.6 m, t = {:.0} s; kappa pi^2 = {} /s", sci(KAP), T, sci(KAP * PI.powi(2)));
    println!("spread 2 sqrt(kappa t) = {:.4} m; start energy 0.5||u0||^2 = {:.4} C^2 m", 2.0 * (KAP * T).sqrt(), E0);
    // ---- roads 1 and 2: the series and the kernel agree ----
    for (x, t) in [(0.5, T), (0.4, T), (0.3, T), (0.05, 600.0)] { // the last needs the images
        let (s, k) = (series(x, t), kernel(x, t));
        println!("u({}, {:.0} s): series {:.6} C, kernel with images {:.6} C", x, t, s, k);
        assert!((s - k).abs() < 1e-6);
    }
    println!("series: 2000 modes, first omitted term {} C", sci(bn(2001).abs() * (-KAP * lam(2001) * T).exp()));
    // ---- road 3: Galerkin, assembled by Simpson on 2000 intervals ----
    let (nm, w) = (80usize, weights(0.0, 1.0, 2000));
    let xs: Vec<f64> = (0..=2000).map(|i| i as f64 / 2000.0).collect();
    let s: Mat = (1..=nm).map(|k| xs.iter().map(|&x| (k as f64 * PI * x).sin()).collect()).collect();
    let cc: Mat = (1..=nm).map(|k| xs.iter().map(|&x| k as f64 * PI * (k as f64 * PI * x).cos()).collect()).collect();
    let ws: Mat = s.iter().map(|r| w.iter().zip(r).map(|(a, b)| a * b).collect()).collect();
    let wc: Mat = cc.iter().map(|r| w.iter().zip(r).map(|(a, b)| a * b).collect()).collect();
    let mm: Mat = (0..nm).map(|j| (0..nm).map(|k| nsum(ws[j].iter().zip(&s[k]).map(|(a, b)| a * b))).collect()).collect();
    let kk: Mat = (0..nm).map(|j| (0..nm).map(|k| nsum(wc[j].iter().zip(&cc[k]).map(|(a, b)| a * b))).collect()).collect();
    let wl = weights(A, B, 800);
    let f: Vec<f64> = (1..=nm).map(|k| HOT * nsum((0..=800).map(|i| wl[i] * (k as f64 * PI * (A + 0.2 * i as f64 / 800.0)).sin()))).collect();
    let mut off = 0.0f64;
    for j in 0..nm { for k in 0..nm { if j != k { off = off.max(mm[j][k].abs() + kk[j][k].abs() / lam(80)); } } }
    assert!(off < 1e-12 && (0..nm).all(|k| (mm[k][k] - 0.5).abs() < 1e-12 && (kk[k][k] / lam(k + 1) - 0.5).abs() < 1e-12));
    println!("mass matrix 1/2 I, stiffness diag(lambda_k/2): off-diagonal below 1e-12 (stiffness over lambda_80), as orthogonality says");

    println!("Galerkin, Crank-Nicolson dt = 0.5 s");
    println!(" N | u_N(0.5,60) C | gap to series C | rms err t=0 C | rms err t=60 C | 1st omitted C | E_N(60) C^2 m | kappa int|du/dx|^2 | max E/bound");
    let mut runs = Vec::new();
    for n in [5usize, 20, 80] {
        let r = galerkin(&mm, &kk, &f, n, 0.5);
        let (c0, c, es, et, diss, worst) = (&r.0, &r.1, r.2, r.3, r.4, r.5);
        assert!(c0.iter().enumerate().map(|(k, a)| (a - bn(k + 1)).abs()).fold(0.0, f64::max) < 1e-6); // quadrature against closed form
        assert!((es - et - diss).abs() < 1e-9 * E0 && worst <= 1.0); // energy identity, decay bound
        let r0 = (2.0 * (E0 - nsum((1..=n).map(|m| bn(m).powi(2))) / 4.0)).sqrt();
        let r60 = (0.5 * nsum((n + 1..=2000).map(|m| bn(m).powi(2) * (-2.0 * KAP * lam(m) * T).exp()))).sqrt();
        let (mo, g) = (n + 1 + n % 2, at(c, 0.5) - series(0.5, T));
        let om = bn(mo).abs() * (-KAP * lam(mo) * T).exp();
        println!("{:2} | {:13.6} | {:15.6} | {:13.4} | {:>14} | {:>13} | {:13.4} | {:18.4} | {:.4}", n, at(c, 0.5), g, r0, sci(r60), sci(om), et, diss, worst);
        runs.push(r);
    }
    let fac: Vec<f64> = [1usize, 3, 5].iter().map(|&k| (-KAP * lam(k) * T).exp()).collect();
    let h5: Vec<f64> = [1usize, 3, 5].iter().zip(&fac).map(|(&k, f)| bn(k) * (k as f64 * PI / 2.0).sin() * f).collect();
    println!("by hand, N = 5 at the centre: b_1, b_3, b_5 = {:.4}, {:.4}, {:.4} C; decay {:.6}, {:.6}, {:.6}", bn(1), bn(3), bn(5), fac[0], fac[1], fac[2]);
    println!("  terms {:.4} + ({:.4}) + {:.4} = {:.4} C, the 5-mode series exactly", h5[0], h5[1], h5[2], h5[0] + h5[1] + h5[2]);
    assert!((runs[2].3 - energy(T)).abs() < 2e-3 && (at(&runs[2].1, 0.4) - series(0.4, T)).abs() < 2e-4); // CN error, dt 0.5 s
    let errs: Vec<f64> = [2.0, 1.0, 0.5].iter().map(|&dt| rms_gap(&galerkin(&mm, &kk, &f, 80, dt).1, T)).collect();
    let (o1, o2) = ((errs[0] / errs[1]).log2(), (errs[1] / errs[2]).log2());
    println!("Crank-Nicolson time error, N = 80, dt 2, 1, 0.5 s: {}, {}, {} C rms; orders {:.3}, {:.3}", sci(errs[0]), sci(errs[1]), sci(errs[2]), o1, o2);
    assert!(1.9 < o1 && o1 < 2.1 && 1.9 < o2 && o2 < 2.1);
    // ---- the path: continuous in L^2, not in H^1_0 ----
    let (lead, tail) = (2.0 * HOT.powi(2) / (8.0 * PI * KAP).sqrt(), 2.0 * E0 - nsum((1..=100000).map(|n| 0.5 * bn(n).powi(2)))); // Parseval
    println!("t s | rms ||u(t)-u0|| C | two jumps alone C | ||du/dx||^2 C^2/m | times sqrt(t)  (two-jump limit {:.1}; 100000 modes + Parseval tail {:.4} C^2)", lead, tail);
    let mut prev = 0.0;
    for t in [0.06, 0.6, 6.0, 60.0] {
        let (mut d2, mut g2) = (tail, 0.0f64); // modes above 100000 have died, each adding b_n^2 / 2 to the gap^2
        for n in 1..=100000usize {
            let (b, q) = (bn(n), (-KAP * lam(n) * t).exp());
            d2 += 0.5 * b * b * (1.0 - q).powi(2); g2 += 0.5 * b * b * lam(n) * q * q;
        }
        let cf = (HOT.powi(2) * (4.0 * KAP * t).sqrt() * (2.0 - 2f64.sqrt()) / PI.sqrt()).sqrt(); // two erf steps on a line
        println!("{:5.2} | {:17.4} | {:17.4} | {:17.1} | {:.1}", t, d2.sqrt(), cf, g2, g2 * t.sqrt());
        assert!(prev < d2.sqrt() && d2.sqrt() < 30.0 && (t > 1.0 || (d2.sqrt() - cf).abs() < 1e-6) && (t > 10.0 || (g2 * t.sqrt() / lead - 1.0).abs() < 0.01));
        prev = d2.sqrt();
    }
    let el = energy(T);
    println!("exact E(60) = {:.4} C^2 m; int_0^60 ||du/dx||^2 dt = (E0 - E(60))/kappa = {} C^2 s/m; int ||u'||^2_(H^-1) = {:.6} C^2 m^3/s", el, sci((E0 - el) / KAP), (E0 - el) * KAP);
    // ---- what breaks ----
    let ls: Vec<f64> = [5usize, 20, 80].iter().map(|&n| nsum((1..=n).map(|m| bn(m).powi(2) * KAP * lam(m) * (1.0 - (-2.0 * KAP * lam(m) * T).exp()))) / 4.0).collect();
    println!("u' in L^2(0,60; L^2) instead: int ||u_N'||^2 dt for N = 5, 20, 80 = {:.4}, {:.4}, {:.4} C^2 m/s, growing", ls[0], ls[1], ls[2]);
    assert!(ls[2] > 4.0 * ls[1] && ls[1] > 3.0 * ls[0]);
    let grow = 1e-6 * (KAP * lam(21) * T).exp();
    println!("backward in time: 1e-6 C in mode 21 becomes {} C after 60 s", sci(grow));
    let mean = HOT * (B - A); // insulated ends keep the mean, C
    let ins = 0.5 * (mean.powi(2) + 0.5 * nsum((1..=2000).map(|n| (2.0 * HOT / (n as f64 * PI) * ((n as f64 * PI * B).sin() - (n as f64 * PI * A).sin())).powi(2) * (-2.0 * KAP * lam(n) * 3600.0).exp())));
    println!("insulated ends, cosine series: mean {:.1} C never decays, energy {:.4} C^2 m at 3600 s, bound {:.4}", mean, ins, bound(3600.0));
    assert!(ins > 100.0 * bound(3600.0) && (ins - 0.5 * mean.powi(2)).abs() < 1e-6);
    // ---- chart points ----
    row("chart, x m:       ", &(0..21).map(|i| format!("{:.2}", i as f64 / 20.0)).collect::<Vec<_>>());
    row("chart, start:     ", &(0..21).map(|i| format!("{:.2}", if (8..=12).contains(&i) { HOT } else { 0.0 })).collect::<Vec<_>>());
    row("chart, N=5, t=0:  ", &(0..21).map(|i| format!("{:.2}", at(&runs[0].0, i as f64 / 20.0))).collect::<Vec<_>>());
    row("chart, t=60 s:    ", &(0..21).map(|i| format!("{:.2}", series(i as f64 / 20.0, T))).collect::<Vec<_>>());
    row("chart, t s:       ", &(0..11).map(|i| format!("{}", 60 * i)).collect::<Vec<_>>());
    row("chart, energy:    ", &(0..11).map(|i| format!("{:.1}", if i == 0 { E0 } else { energy(60.0 * i as f64) })).collect::<Vec<_>>());
    row("chart, bound:     ", &(0..11).map(|i| format!("{:.1}", bound(60.0 * i as f64))).collect::<Vec<_>>());
    assert!((1..11).all(|i| energy(60.0 * i as f64) <= bound(60.0 * i as f64)));
    println!("ALL CHECKS PASS");
}
