// Eigenvalues by iteration -- the same check as the Python, in Rust.  No crates.
// A five-storey shear frame: floor mass m, storey stiffness s, A = K / s.
// Road one: the closed form 4 sin^2((2j-1) pi / 22).  Road two: power, inverse
// and shifted inverse iteration.  Road three: the QR algorithm, with trace,
// determinant (product of Thomas pivots) and a power-iteration column as checks.
use std::f64::consts::PI;
const N: usize = 5;

fn dot(u: &[f64], v: &[f64]) -> f64 { let mut t = 0.0; for i in 0..u.len() { t += u[i] * v[i]; } t }
fn nrm(x: &[f64]) -> f64 { dot(x, x).sqrt() }
fn unit(x: &[f64]) -> Vec<f64> { let r = nrm(x); x.iter().map(|t| t / r).collect() }
fn mv(b: &[f64], x: &[f64], fl: &mut u32) -> Vec<f64> {        // A x on the three diagonals
    (0..N).map(|i| {
        let mut t = b[i] * x[i]; *fl += 1;
        if i > 0 { t -= x[i - 1]; *fl += 1; }
        if i < N - 1 { t -= x[i + 1]; *fl += 1; }
        t }).collect()
}
fn solve(b: &[f64], mu: f64, d: &[f64]) -> (Vec<f64>, Vec<f64>) {   // (A - mu I) y = d, Thomas sweep
    let (mut p, mut z) = (vec![b[0] - mu], vec![d[0]]);
    for i in 1..N {
        let l = -1.0 / p[i - 1];
        p.push(b[i] - mu + l); let zi = d[i] - l * z[i - 1]; z.push(zi);
    }
    let mut y = vec![0.0; N]; y[N - 1] = z[N - 1] / p[N - 1];
    for i in (0..N - 1).rev() { y[i] = (z[i] + y[i + 1]) / p[i]; }
    (y, p)
}
fn resid(b: &[f64], x: &[f64], lam: f64) -> f64 {              // |A x - lambda x|
    let ax = mv(b, x, &mut 0); nrm(&(0..N).map(|i| ax[i] - lam * x[i]).collect::<Vec<_>>())
}
fn err(x: &[f64], v: &[f64]) -> f64 {                          // e: distance off the true line
    let c = dot(x, v); nrm(&(0..N).map(|i| x[i] - c * v[i]).collect::<Vec<_>>())
}
fn pe(x: f64, d: usize) -> String {                            // Python-style 1.2e-05
    let s = format!("{:.*e}", d, x); let (m, e) = s.split_once('e').unwrap();
    let (sg, dg) = if let Some(r) = e.strip_prefix('-') { ('-', r) } else { ('+', e) };
    format!("{}e{}{:0>2}", m, sg, dg)
}
fn row(v: &[f64], d: usize) -> String { v.iter().map(|t| format!("{:.*}", d, t)).collect::<Vec<_>>().join(" ") }
fn qr_step(m0: &[Vec<f64>], mu: f64) -> (Vec<Vec<f64>>, Vec<(f64, f64)>) {   // M - mu I = Q R; R Q + mu I
    let k = m0.len(); let mut r = m0.to_vec(); let mut rot = vec![];
    for i in 0..k { r[i][i] -= mu; }
    for i in 0..k - 1 {
        let (a, c) = (r[i][i], r[i + 1][i]); let h = (a * a + c * c).sqrt(); let (cs, sn) = (a / h, c / h); rot.push((cs, sn));
        for j in 0..k { let (p, q) = (r[i][j], r[i + 1][j]); r[i][j] = cs * p + sn * q; r[i + 1][j] = -sn * p + cs * q; }
    }
    for (i, &(cs, sn)) in rot.iter().enumerate() {
        for j in 0..k { let (p, q) = (r[j][i], r[j][i + 1]); r[j][i] = cs * p + sn * q; r[j][i + 1] = -sn * p + cs * q; }
    }
    for i in 0..k { r[i][i] += mu; }
    (r, rot)
}

fn shifted_qr(a: &[Vec<f64>], wilkinson: bool) -> (Vec<Vec<f64>>, usize) {   // QR with deflation; Wilkinson or corner shift
    let (mut mm, mut e, mut ws) = (a.to_vec(), N - 1, 0);
    while e > 0 {
        let (p, c, d) = (mm[e - 1][e - 1], mm[e][e - 1], mm[e][e]); let h = (p - d) / 2.0;
        let w = if wilkinson { d - (if h >= 0.0 { 1.0 } else { -1.0 }) * c * c / (h.abs() + (h * h + c * c).sqrt()) } else { d };
        let (bb, _) = qr_step(&mm[..e + 1].iter().map(|r| r[..e + 1].to_vec()).collect::<Vec<_>>(), w); ws += 1;
        for i in 0..e + 1 { mm[i][..e + 1].copy_from_slice(&bb[i]); }
        while e > 0 && mm[e][e - 1].abs() < 1e-14 * (mm[e][e].abs() + mm[e - 1][e - 1].abs()) { e -= 1; }
    }
    (mm, ws)
}

fn main() {
    let (m, s) = (5.0e4, 1.0e8);                                // illustrative: 50 t floors, 100 MN/m storeys
    let mut b = vec![2.0; N]; b[N - 1] = 1.0;                   // diagonal of A; every off-diagonal is -1
    let a: Vec<Vec<f64>> = (0..N).map(|i| (0..N).map(|j| if i == j { b[i] } else if i.abs_diff(j) == 1 { -1.0 } else { 0.0 }).collect()).collect();
    let ones = vec![1.0; N];
    let lam: Vec<f64> = (1..=N).map(|j| { let t = ((2 * j - 1) as f64 * PI / (2 * (2 * N + 1)) as f64).sin(); 4.0 * t * t }).collect();
    let v: Vec<Vec<f64>> = (1..=N).map(|j| unit(&(1..=N).map(|i| (((2 * j - 1) * i) as f64 * PI / (2 * N + 1) as f64).sin()).collect::<Vec<_>>())).collect();
    let per = |l: f64| 2.0 * PI / (l * s / m).sqrt();           // period in seconds from an eigenvalue of A
    println!("closed form lambda_1..5: {}", row(&lam, 6));
    println!("periods: mode 1 {:.4} s ({:.3} Hz), mode 5 {:.4} s", per(lam[0]), (lam[0] * s / m).sqrt() / (2.0 * PI), per(lam[4]));
    println!("mode 1 shape, top floor = 1: {}", row(&v[0].iter().map(|t| t / v[0][N - 1]).collect::<Vec<_>>(), 4));
    println!("mode 5 shape, largest = 1: {}", row(&v[4].iter().map(|t| t / v[4][2]).collect::<Vec<_>>(), 4));
    let mf: Vec<f64> = v.iter().map(|w| dot(w, &ones) * dot(w, &ones) / N as f64).collect();
    println!("share of the frame's mass moving in each mode: {}", row(&mf, 4));

    let w0 = 2.0 * PI / 0.5; let mu = w0 * w0 * m / s;           // rule of thumb: 0.1 s a storey, so 0.5 s
    println!("shift mu from a 0.5 s guess = {:.6}", mu);
    let names = ["power", "inverse", "shifted"];
    let (tj, gam, kks) = ([4usize, 0, 0], [lam[3] / lam[4], lam[0] / lam[1], ((lam[0] - mu) / (lam[1] - mu)).abs()], [10usize, 3, 1]);
    let (mut hist, mut tb): (Vec<Vec<(f64, f64, f64, f64)>>, Vec<f64>) = (vec![], vec![]);
    for r in 0..3 {
        let (j, g, kk) = (tj[r], gam[r], kks[r]);
        let mut x = unit(&ones); let mut h = vec![];
        for _ in 0..121 {
            let l = dot(&x, &mv(&b, &x, &mut 0)); h.push((err(&x, &v[j]), (l - lam[j]).abs(), resid(&b, &x, l), l));
            x = unit(&match r { 0 => mv(&b, &x, &mut 0), 1 => solve(&b, 0.0, &x).0, _ => solve(&b, mu, &x).0 });
        }
        let ks = (0..121).find(|&k| h[k].2 < 1e-10).unwrap_or(120);
        println!("{}: gamma {:.6}, seen e ratio {:.6}, lambda-error ratio {:.6} (gamma^2 {:.6})",
                 names[r], g, h[kk + 1].0 / h[kk].0, h[kk + 1].1 / h[kk].1, g * g);
        let bd = h[ks].2 / (0..N).filter(|&i| i != j).map(|i| (lam[i] - h[ks].3).abs()).fold(f64::INFINITY, f64::min);
        tb.push(h[ks].0 / bd);
        println!("  residual < 1e-10 at step {}: lambda-hat {:.12}, true e {}, bound residual/gap {}, true/bound {:.3}",
                 ks, h[ks].3, pe(h[ks].0, 1), pe(bd, 1), h[ks].0 / bd);
        hist.push(h);
    }
    for r in 0..3 {
        println!("chart {}: log10 e_k, k = 0..12: {}", names[r], row(&hist[r][..13].iter().map(|t| t.0.max(1e-17).log10()).collect::<Vec<_>>(), 2));
    }
    let y = solve(&b, 0.0, &ones).0; let z = solve(&b, 0.0, &y).0;   // by hand: A^-1 has entries min(i, j)
    println!("by hand: A y = ones gives y = {} ; A z = y gives z = {}", row(&y, 4), row(&z, 4));
    let (q1, q2) = (dot(&y, &ones) / dot(&y, &y), dot(&z, &y) / dot(&z, &z));
    println!("  lambda-hat {:.0}/{:.0} = {:.6} ({:.4} s), {:.0}/{:.0} = {:.6} ({:.4} s)",
             dot(&y, &ones), dot(&y, &y), q1, per(q1), dot(&z, &y), dot(&z, &z), q2, per(q2));
    println!("  shape after two steps, top = 1: {}", row(&z.iter().map(|t| t / z[N - 1]).collect::<Vec<_>>(), 4));
    println!("first steps, inverse: lambda-hat {}", row(&hist[1][..4].iter().map(|t| t.3).collect::<Vec<_>>(), 6));
    let mut fl = 0; mv(&b, &ones, &mut fl);
    println!("flops: A x {} = 3n - 2 (off-diagonals are -1); a general Thomas solve 8n - 7 = {}", fl, 8 * N - 7);

    let (mut mm, mut qb, mut steps, mut col) = (a.clone(), (0..N).map(|i| (0..N).map(|j| if i == j { 1.0 } else { 0.0 }).collect::<Vec<f64>>()).collect::<Vec<_>>(), 0, 0.0);
    let mut xe = vec![0.0; N]; xe[0] = 1.0;
    while (0..N - 1).map(|i| mm[i + 1][i].abs()).fold(0.0, f64::max) >= 1e-12 {
        let (nm, rot) = qr_step(&mm, 0.0); mm = nm; steps += 1;
        for (i, &(cs, sn)) in rot.iter().enumerate() {
            for j in 0..N { let (p, q) = (qb[j][i], qb[j][i + 1]); qb[j][i] = cs * p + sn * q; qb[j][i + 1] = -sn * p + cs * q; }
        }
        xe = unit(&mv(&b, &xe, &mut 0));
        if steps == 10 {
            println!("unshifted QR, 10 steps: diagonal {}", row(&(0..N).map(|i| mm[i][i]).collect::<Vec<_>>(), 6));
            println!("  subdiagonal {}", (0..N - 1).map(|i| pe(mm[i + 1][i].abs(), 1)).collect::<Vec<_>>().join(" "));
            col = dot(&(0..N).map(|j| qb[j][0]).collect::<Vec<_>>(), &xe).abs();
            println!("  |first column of Q-bar . power vector from e1| = {:.15}", col);
        }
    }
    println!("unshifted QR: {} steps to subdiagonal < 1e-12; diagonal {}", steps, row(&(0..N).map(|i| mm[i][i]).collect::<Vec<_>>(), 6));
    let ((mm, ws), wc) = (shifted_qr(&a, true), shifted_qr(&a, false).1);
    let mut ev: Vec<f64> = (0..N).map(|i| mm[i][i]).collect(); ev.sort_by(|p, q| p.partial_cmp(q).unwrap());
    let (mut tr, mut pr, mut dt) = (0.0, 1.0, 1.0);
    for t in &ev { tr += t; pr *= t; }
    for t in &solve(&b, 0.0, &ones).1 { dt *= t; }
    println!("shifted QR: {} steps (corner shift alone: {}); eigenvalues {}", ws, wc, row(&ev, 12));
    println!("  sum {:.12} = trace 9; product {:.12} = det = Thomas pivots' product {:.12}", tr, pr, dt);
    // what breaks
    let (mut x, mut k) = (ones.clone(), 0);
    while x.iter().fold(0.0f64, |p, t| p.max(t.abs())) < f64::INFINITY { x = mv(&b, &x, &mut 0); k += 1; }
    println!("break, no normalising: entries overflow to inf at step {}", k);
    let mid = (lam[0] + lam[1]) / 2.0; let mut x = unit(&ones);
    for _ in 0..50 { x = unit(&solve(&b, mid, &x).0); }
    let lm = dot(&x, &mv(&b, &x, &mut 0));
    println!("break, shift midway {:.6}: lambda-hat after 50 steps {:.6}, residual {:.3}", mid, lm, resid(&b, &x, lm));
    println!("break, power iteration for the fundamental: period {:.4} s, not {:.4} s", per(hist[0][120].3), per(lam[0]));
    let h = &hist[0]; let kc = (0..120).find(|&k| (h[k + 1].3 - h[k].3).abs() < 1e-10).unwrap();
    println!("break, stop when lambda-hat moves < 1e-10: step {}, lambda error {}, mode-shape error e {}", kc + 1, pe(h[kc + 1].1, 1), pe(h[kc + 1].0, 1));

    assert!((0..N).map(|j| resid(&b, &v[j], lam[j])).fold(0.0, f64::max) < 1e-14);   // closed form solves A v = lambda v
    assert!((0..N).all(|i| (ev[i] - lam[i]).abs() < 1e-13));                         // QR agrees with the closed form
    assert!((tr - 9.0).abs() < 1e-13 && (pr - dt).abs() < 1e-13 && (dt - 1.0).abs() < 1e-13);
    for r in 0..3 {                                                                   // observed rate = eigenvalue gap
        let kk = kks[r]; assert!((hist[r][kk + 1].0 / hist[r][kk].0 - gam[r]).abs() < 0.02 * gam[r]);
    }
    assert!((col - 1.0).abs() < 1e-12 && ws < wc && (wc as f64) < steps as f64 / 5.0); // QR = power on e1; shifts pay; Wilkinson's best
    assert!(tb.iter().all(|t| *t < 1.001));                                           // true e <= residual/gap, up to rounding
    assert!(resid(&b, &x, lm) > 0.1 && lam.iter().all(|t| (lm - t).abs() > 0.05));     // equal gaps: no convergence
    println!("ALL CHECKS PASS");
}
