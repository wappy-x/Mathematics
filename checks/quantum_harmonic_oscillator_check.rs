// Quantum oscillator check: the vibration of one H-35Cl molecule.  Standard library only, no crates.
// Levels in units of hbar*omega reached four ways: the ladder formula n + 1/2, ladder steps
// applied to a Gaussian on a grid, the grid matrix's eigenvalues by Sturm counting, and the
// power series shot out to xi = 6 with the energy found by bisection.
use std::f64::consts::PI;

const L: f64 = 8.0;
const DX: f64 = 0.01;

fn sci(x: f64, p: usize) -> String {                      // 5.391e-07, the way Python prints it
    let s = format!("{:.*e}", p, x);
    let (m, e) = s.split_once('e').unwrap();
    let ev: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if ev < 0 { '-' } else { '+' }, ev.abs())
}
fn slope(f: &[f64]) -> Vec<f64> {
    let n = f.len();
    let mut g = vec![0.0; n];
    for i in 1..n - 1 { g[i] = (f[i + 1] - f[i - 1]) / (2.0 * DX); }
    g
}
fn up(f: &[f64], xs: &[f64]) -> Vec<f64> {                // a-dagger
    let g = slope(f);
    (0..f.len()).map(|i| (xs[i] * f[i] - g[i]) / 2f64.sqrt()).collect()
}
fn down(f: &[f64], xs: &[f64]) -> Vec<f64> {              // a
    let g = slope(f);
    (0..f.len()).map(|i| (xs[i] * f[i] + g[i]) / 2f64.sqrt()).collect()
}
fn size(f: &[f64]) -> f64 { (f.iter().map(|v| v * v).sum::<f64>() * DX).sqrt() }
fn energy(f: &[f64], xs: &[f64]) -> f64 {                 // <f|H|f>/<f|f>, H = -1/2 d2 + 1/2 xi^2
    let mut top = 0.0;
    for i in 1..f.len() - 1 {
        top += f[i] * (-(f[i + 1] - 2.0 * f[i] + f[i - 1]) / (2.0 * DX * DX) + 0.5 * xs[i].powi(2) * f[i]);
    }
    top / f.iter().map(|v| v * v).sum::<f64>()
}
fn count_below(diag: &[f64], off2: f64, lam: f64) -> usize { // Sturm count: eigenvalues below lam
    let (mut cnt, mut q) = (0, 1.0);
    for (i, d) in diag.iter().enumerate() {
        q = d - lam - if i > 0 { off2 / q } else { 0.0 };
        if q == 0.0 { q = 1e-300; }
        if q < 0.0 { cnt += 1; }
    }
    cnt
}
fn matrix_level(diag: &[f64], off2: f64, n: usize) -> f64 {
    let (mut lo, mut hi) = (0.0, 20.0);
    for _ in 0..50 {
        let mid = (lo + hi) / 2.0;
        if count_below(diag, off2, mid) > n { hi = mid; } else { lo = mid; }
    }
    (lo + hi) / 2.0
}
fn series(eps: f64, start: usize, xi: f64) -> f64 {       // y(xi) = sum a_j xi^j, psi = y e^(-xi^2/2)
    let (mut a, mut total) = (1.0, 0.0);
    let mut j = start;
    while j < 300 {
        total += a * xi.powi(j as i32);
        a *= (2.0 * j as f64 + 1.0 - 2.0 * eps) / (((j + 1) * (j + 2)) as f64);
        j += 2;
    }
    total
}
fn shoot(n: usize, xi: f64) -> f64 {                      // find eps where the tail at xi flips sign
    let (mut lo, mut hi) = (n as f64 + 0.1, n as f64 + 2.1); // the only root of level n's parity in here
    let s_lo = series(lo, n % 2, xi) > 0.0;
    assert!(s_lo != (series(hi, n % 2, xi) > 0.0), "no sign change: the root is outside the bracket");
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if (series(mid, n % 2, xi) > 0.0) == s_lo { lo = mid; } else { hi = mid; }
    }
    (lo + hi) / 2.0
}

fn main() {
    let (h, c, u, ev, kb) = (6.62607015e-34, 299792458.0, 1.66053906892e-27, 1.602176634e-19, 1.380649e-23);
    let hbar = h / (2.0 * PI);
    let (mh, mcl, md) = (1.00782503223, 34.968852682, 2.01410177812);
    let (we, wexe, re, be) = (2990.9463_f64, 52.8186, 127.4552, 10.593416); // cm^-1, cm^-1, pm, cm^-1 (NIST WebBook)
    let (wn2, wo2) = (2358.57_f64, 1580.193_f64); // N2 and O2 vibration, cm^-1 (NIST WebBook)
    let mu_u = mh * mcl / (mh + mcl);
    let mu = mu_u * u;
    let omega = 2.0 * PI * c * we * 100.0;
    let k = mu * omega * omega;
    let gap = hbar * omega / ev;
    let x0 = (hbar / (mu * omega)).sqrt() * 1e12;
    let kt = kb * 298.15 / ev;

    let n_pts = (2.0 * L / DX).round() as usize + 1;
    let xs: Vec<f64> = (0..n_pts).map(|i| -L + i as f64 * DX).collect();
    let psi: Vec<f64> = xs.iter().map(|x| (-x * x / 2.0).exp()).collect();
    let kill = size(&down(&psi, &xs)) / size(&psi);
    let p1 = up(&psi, &xs);
    let grow = size(&up(&p1, &xs)) / size(&p1);
    let mut ladder = vec![];
    let mut f = psi.clone();
    for _ in 0..5 { ladder.push(energy(&f, &xs)); f = up(&f, &xs); }
    let diag: Vec<f64> = xs[1..n_pts - 1].iter().map(|x| 1.0 / (DX * DX) + 0.5 * x * x).collect();
    let off2 = (0.5 / (DX * DX)).powi(2);
    let matrix: Vec<f64> = (0..5).map(|n| matrix_level(&diag, off2, n)).collect();
    let shot: Vec<f64> = (0..5).map(|n| shoot(n, 6.0)).collect();

    println!("reduced mass {:.6} u   omega {} rad/s   stiffness {:.1} N/m", mu_u, sci(omega, 5), k);
    println!("rung hbar*omega {:.5} eV   floor E0 {:.5} eV   wavelength {:.4} um", gap, gap / 2.0, 1e4 / we);
    println!("natural length x0 {:.3} pm   ground spread x0/sqrt2 {:.3} pm = {:.2} % of {} pm",
             x0, x0 / 2f64.sqrt(), 100.0 * x0 / 2f64.sqrt() / re, re);
    println!("hbar {} J s   mu {} kg   h/hbar {:.2}   bond {:.1} pm   xi=2.5 is {:.1} pm", sci(hbar, 4), sci(mu, 4), 2.0 * PI, re, 2.5 * x0);
    println!("kT at 298.15 K {:.5} eV   rung/kT {:.3}   share above v=0 {}", kt, gap / kt, sci((-gap / kt).exp(), 3));
    println!("N2 rung {:.1} cm^-1 = {:.1} kT   O2 rung {:.1} cm^-1 = {:.1} kT   HCl rotation comb 2 Be {:.0} cm^-1",
             wn2, wn2 / we * gap / kt, wo2, wo2 / we * gap / kt, 2.0 * be);
    println!("a on ground state, size ratio {};  a-dagger on state 1, size ratio {:.6}", sci(kill, 2), grow);
    println!(" n   formula   ladder grid   matrix grid   series shot   level eV");
    for n in 0..5 {
        let e = n as f64 + 0.5;
        println!("{:2} {:9.4} {:13.6} {:13.6} {:13.9} {:10.5}", n, e, ladder[n], matrix[n], shot[n], e * gap);
    }
    let mut a_s = vec![1.0_f64];
    for j in [0.0_f64, 2.0, 4.0] { let last = *a_s.last().unwrap(); a_s.push(last * (2.0 * j + 1.0 - 5.0) / ((j + 1.0) * (j + 2.0)) + 0.0); }
    let a_txt: Vec<String> = a_s.iter().map(|v| format!("{:.1}", v)).collect();
    println!("series at eps 2.5: a0 a2 a4 a6 {};  psi(6) {}", a_txt.join(" "), sci(series(2.5, 0, 6.0) * (-18f64).exp(), 3));
    println!("series at eps 2.6: psi(6) {}", sci(series(2.6, 0, 6.0) * (-18f64).exp(), 3));
    println!("gaps v->v+1, cm^-1: v  harmonic  anharmonic");
    let anh: Vec<f64> = (0..10).map(|v| we - 2.0 * wexe * (v as f64 + 1.0)).collect();
    for v in [0usize, 1, 2, 3, 4, 5, 9] { println!("  {:2} {:9.1} {:10.1}", v, we, anh[v]); }
    println!("v=0 gap below the spring model by {:.1} %;  corrected line {:.4} um", 100.0 * (we - anh[0]) / we, 1e4 / anh[0]);
    let de = we * we / (4.0 * wexe);
    println!("Morse: top bound level v={}   De {:.0} cm^-1 = {:.3} eV", (we / (2.0 * wexe) - 0.5).floor() as i64, de, de * 100.0 * h * c / ev);
    println!("wrong: drop the half, E0 {:.5} eV;  h for hbar, E0 {:.4} eV", 0.0, gap / 2.0 * 2.0 * PI);
    let wh = we * (mu_u / mh).sqrt();
    println!("wrong: H mass alone {:.1} cm^-1 = {:.4} um", wh, 1e4 / wh);
    println!("wrong: box ladder, 0->2 line {:.1} cm^-1 vs oscillator {:.1} cm^-1", we * 8.0 / 3.0, 2.0 * we);
    let mu_d = md * mcl / (md + mcl);
    let wd = we * (mu_u / mu_d).sqrt();
    println!("try: D-35Cl {:.1} cm^-1 = {:.4} um;  share above v=0 at 1000 K {:.4}", wd, 1e4 / wd, (-gap * ev / (kb * 1000.0)).exp());
    let walled = [shoot(0, 2.5), shoot(4, 2.5)];
    println!("try: shoot to xi=2.5, levels {:.4} {:.4}, rises {:.4} {:.4}", walled[0], walled[1], walled[0] - 0.5, walled[1] - 4.5);
    let ve = |r: f64| 0.5 * k * ((r - re) * 1e-12).powi(2) / ev;
    let a_m = (k / (2.0 * de * 100.0 * h * c)).sqrt() * 1e-12;
    let vm = |r: f64| de * 100.0 * h * c / ev * (1.0 - (-a_m * (r - re)).exp()).powi(2);
    let rs: Vec<f64> = (0..10).map(|i| 100.0 + 10.0 * i as f64).collect();
    let row = |g: &dyn Fn(f64) -> f64| rs.iter().map(|r| format!("{:5.2}", g(*r))).collect::<Vec<_>>().join(" ");
    println!("figure, r pm   {}", rs.iter().map(|r| format!("{:5}", *r as i64)).collect::<Vec<_>>().join(" "));
    println!("figure, V harm {}", row(&ve));
    println!("figure, Morse  {}", row(&vm));
    for v in 0..4 {
        let e = (v as f64 + 0.5) * gap;
        let w = (2.0 * e * ev / k).sqrt() * 1e12;
        println!("figure, v={} at {:.3} eV, turning points {:.1} {:.1} pm", v, e, re - w, re + w);
    }

    assert!((0..5).all(|n| (ladder[n] - (n as f64 + 0.5)).abs() < 2e-3), "ladder steps on the grid");
    assert!((0..5).all(|n| (matrix[n] - (n as f64 + 0.5)).abs() < 1e-3), "matrix eigenvalues");
    assert!((0..5).all(|n| (shot[n] - (n as f64 + 0.5)).abs() < 1e-6), "series shooting");
    assert!(kill < 1e-3, "lowering operator must kill the Gaussian");
    assert!((grow - 2f64.sqrt()).abs() < 1e-3, "raising state 1 multiplies its size by sqrt(2)");
    println!("ALL CHECKS PASS");
}
