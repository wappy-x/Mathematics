// Compact operators -- the same check as the Python, in Rust.  No crates.
// A copper rod 1 m long, ends held at 0 C, smooths for about 450 s.  K maps the start
// profile f to the profile 450 s later: (Kf)(x) = integral of k(x, y) f(y) dy.
// Roads: the kernel two ways (sine modes, mirror images); finite-rank cuts two
// ways (keep N modes, average k on an N-by-N grid); norms by formula, power
// iteration and quadrature.  Every computation is a truncation of the rod.
use std::f64::consts::PI;

const KAPPA: f64 = 1.11e-4; // m^2/s (copper, illustrative)
const KT: f64 = 0.05; // kappa*t, m^2

fn lam(n: f64) -> f64 { (-n * n * PI * PI * KT).exp() } // factor by which mode n survives

fn k_modes(x: f64, y: f64) -> f64 { // road one: sum of sine modes
    (1..=30).map(|n| { let n = n as f64; 2.0 * lam(n) * (n * PI * x).sin() * (n * PI * y).sin() }).sum()
}

fn k_images(x: f64, y: f64) -> f64 { // road two: bell curves and mirror images
    let g = |z: f64| (-z * z / (4.0 * KT)).exp() / (4.0 * PI * KT).sqrt();
    (-2..=2).map(|m| { let m = m as f64; g(x - y + 2.0 * m) - g(x + y + 2.0 * m) }).sum()
}

fn sci(v: f64, d: usize) -> String { // the Python format: mantissa e sign two-digit exponent
    let s = format!("{:.*e}", d, v);
    let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}

fn main() {
    let t = KT / KAPPA; // seconds of smoothing, about 450
    println!("kappa*t = {} m^2/s x {:.1} s = {:.2} m^2", sci(KAPPA, 3), t, KT);
    for n in 1..10 { println!("mode {}: lambda = {}", n, sci(lam(n as f64), 4)); }
    let mut gap: f64 = 0.0;
    for i in 0..21 { for j in 0..21 {
        let (x, y) = (i as f64 / 20.0, j as f64 / 20.0);
        gap = gap.max((k_modes(x, y) - k_images(x, y)).abs());
    } }
    println!("kernel, sine modes against mirror images, 21 x 21 grid, worst gap below 1e-12 per m: {}", if gap < 1e-12 { "yes" } else { "no" });

    // The flat 100 C start: middle of the rod after 450 s, two roads.
    let c = |n: usize| if n % 2 == 1 { 2f64.sqrt() * 100.0 * 2.0 / (n as f64 * PI) } else { 0.0 };
    let mid_modes: f64 = (1..40).map(|n| lam(n as f64) * c(n) * 2f64.sqrt() * (n as f64 * PI / 2.0).sin()).sum();
    let q = 2000;
    let mid_quad: f64 = (0..q).map(|j| k_images(0.5, (j as f64 + 0.5) / q as f64) * 100.0 / q as f64).sum();
    println!("flat 100 C start, middle after 450 s: modes {:.4} C, quadrature {:.4} C", mid_modes, mid_quad);
    for n in [1usize, 3, 5] {
        println!("mode {}: amount c = {:.4} C, after smoothing lambda*c = {} C", n, c(n), sci(lam(n as f64) * c(n), 4));
    }
    for nn in 1..4usize {
        let tail = (nn + 1..60).map(|n| (lam(n as f64) * c(n)).powi(2)).sum::<f64>().sqrt();
        let bound = lam((nn + 1) as f64) * 100.0;
        println!("modes kept {}: rms error {} C, bound lambda_{} x 100 C = {} C", nn, sci(tail, 4), nn + 1, sci(bound, 4));
        assert!(tail <= bound); // the norm bound holds
    }

    // Norms: ||K|| by power iteration, ||K||_HS by quadrature, against the formulas.
    let p = 120;
    let xs: Vec<f64> = (0..p).map(|i| (i as f64 + 0.5) / p as f64).collect();
    let a: Vec<Vec<f64>> = xs.iter().map(|&x| xs.iter().map(|&y| k_images(x, y) / p as f64).collect()).collect();
    let mv = |v: &Vec<f64>| -> Vec<f64> { a.iter().map(|row| row.iter().zip(v).map(|(r, s)| r * s).sum()).collect() };
    let mut v = vec![1.0; p];
    for _ in 0..60 {
        let w = mv(&v);
        let s = w.iter().map(|t| t * t).sum::<f64>().sqrt();
        v = w.iter().map(|t| t / s).collect();
    }
    let rq: f64 = v.iter().zip(mv(&v)).map(|(x, y)| x * y).sum();
    println!("||K||: formula lambda_1 = {:.6}, power iteration on {} points = {:.6}", lam(1.0), p, rq);
    let bm: Vec<Vec<f64>> = (0..p).map(|i| (0..p).map(|j| a[i][j] - [1.0, 2.0, 3.0].iter()
        .map(|&n| 2.0 * lam(n) * (n * PI * xs[i]).sin() * (n * PI * xs[j]).sin()).sum::<f64>() / p as f64).collect()).collect(); // K - K_3
    let bv = |v: &Vec<f64>| -> Vec<f64> { bm.iter().map(|row| row.iter().zip(v).map(|(r, s)| r * s).sum()).collect() };
    let mut v = xs.clone(); // a start holding every mode, odd and even
    for _ in 0..30 {
        let w = bv(&v);
        let s = w.iter().map(|t| t * t).sum::<f64>().sqrt();
        v = w.iter().map(|t| t / s).collect();
    }
    let cut3: f64 = v.iter().zip(bv(&v)).map(|(x, y)| x * y).sum();
    println!("||K - K_3||: formula lambda_4 = {}, power iteration on {} points = {}", sci(lam(4.0), 4), p, sci(cut3, 4));
    let m = 840; // fine grid; 840 is divisible by 1..8
    let h = 1.0 / m as f64;
    let fx: Vec<f64> = (0..m).map(|i| (i as f64 + 0.5) * h).collect();
    let mut f = vec![vec![0.0; m]; m];
    for i in 0..m { for j in i..m { let k = k_images(fx[i], fx[j]); f[i][j] = k; f[j][i] = k; } }
    let sq: f64 = f.iter().map(|row| row.iter().map(|t| t * t).sum::<f64>()).sum();
    let hs_quad = (sq * h * h).sqrt();
    let hs_form = (1..40).map(|n| lam(n as f64).powi(2)).sum::<f64>().sqrt();
    println!("||K||_HS: formula sqrt(sum lambda^2) = {:.6}, quadrature on {} x {} = {:.6}", hs_form, m, m, hs_quad);

    // Finite-rank cuts: average k over an N-by-N grid (rank <= N), against keeping N modes.
    let mut s = vec![vec![0.0; m + 1]; m + 1]; // running sums for block sums
    for i in 0..m { for j in 0..m { s[i + 1][j + 1] = f[i][j] + s[i][j + 1] + s[i + 1][j] - s[i][j]; } }
    let mut errs = vec![0.0; 9];
    let mut errs_cf = vec![0.0; 9];
    for nn in 1..9usize {
        let b = m / nn;
        let cell: Vec<Vec<f64>> = (1..40).map(|n| { let n = n as f64; (0..nn).map(|i| ((n * PI * i as f64 / nn as f64).cos()
            - (n * PI * (i + 1) as f64 / nn as f64).cos()) / (n * PI)).collect() }).collect(); // integrals of mode n over strips
        let mut kept = 0.0;
        for i in 0..nn { for j in 0..nn {
            let t: f64 = (0..39).map(|k| 2.0 * lam((k + 1) as f64) * cell[k][i] * cell[k][j]).sum();
            kept += t * t;
        } }
        errs_cf[nn] = (hs_form * hs_form - kept * (nn * nn) as f64).sqrt(); // second road, no quadrature
        let mut lost = 0.0;
        for bi in 0..nn { for bj in 0..nn {
            let blk = s[(bi + 1) * b][(bj + 1) * b] - s[bi * b][(bj + 1) * b] - s[(bi + 1) * b][bj * b] + s[bi * b][bj * b];
            lost += blk * blk / (b * b) as f64;
        } }
        errs[nn] = ((sq - lost).max(0.0) * h * h).sqrt();
        let lm = lam((nn + 1) as f64);
        println!("N = {}: grid cut rank <= {}, HS error {:.4} (log10 {:.2}); mode cut error lambda_{} = {} (log10 {:.2})",
                 nn, nn, errs[nn], errs[nn].log10(), nn + 1, sci(lm, 3), lm.log10());
    }
    println!("grid cut, N x error: N=2 {:.4}, N=4 {:.4}, N=8 {:.4}", 2.0 * errs[2], 4.0 * errs[4], 8.0 * errs[8]);
    let gap_cf = (1..9).map(|n| (errs[n] - errs_cf[n]).abs()).fold(0.0, f64::max);
    println!("grid cut from closed-form cell integrals: N=1 {:.4}, N=8 {:.4}; every N within 1e-4 of the quadrature: {}",
             errs_cf[1], errs_cf[8], if gap_cf < 1e-4 { "yes" } else { "no" });

    // The closed-ideal rule: an inverse would make the identity compact.
    for n in [1.0, 3.0, 5.0] { println!("undo mode {}: multiply by 1/lambda = {}", n as i32, sci(1.0 / lam(n), 4)); }
    println!("0.001 C of noise in mode 5, smoothing undone: {:.1} C", 1e-3 / lam(5.0));

    // What breaks: no smoothing.  Modes needed for 1% worst-case error as t shrinks.
    for kt in [KT, KT / 10.0, KT / 100.0, 0.0] {
        let mut n: u64 = 1;
        while (-((n * n) as f64) * PI * PI * kt).exp() >= 0.01 && n < 1_000_000 { n += 1; }
        let need = if n < 1_000_000 { format!("{}", n - 1) } else { "none up to a million".to_string() };
        println!("kappa*t = {:.7} m^2: lambda_4 = {:.4}, modes for 1%: {}", kt, (-16.0 * PI * PI * kt).exp(), need);
    }
    let mode_gap = (fx.iter().map(|&x| (2f64.sqrt() * ((PI * x).sin() - (2.0 * PI * x).sin())).powi(2)).sum::<f64>() * h).sqrt();
    println!("no smoothing: modes 1 and 2 stay {:.6} apart, as sqrt(2) = {:.6}", mode_gap, 2f64.sqrt());
    let gq: Vec<f64> = (0..q).map(|j| (j as f64 + 0.5) / q as f64).collect(); // 2000 points keep modes up to 1999 apart
    for nn in [1usize, 9, 99, 999] {
        let rest = (100f64.powi(2) - (1..=nn).map(|n| c(n).powi(2)).sum::<f64>()).max(0.0).sqrt();
        let mut u: Vec<f64> = gq.iter().map(|&x| 2f64.sqrt() * (((nn + 1) as f64) * PI * x).sin()).collect();
        for n in 1..=nn { // apply I - P_N to mode N+1
            let vn: Vec<f64> = gq.iter().map(|&x| 2f64.sqrt() * (n as f64 * PI * x).sin()).collect();
            let d = u.iter().zip(&vn).map(|(a, b)| a * b).sum::<f64>() / q as f64;
            for (a, b) in u.iter_mut().zip(&vn) { *a -= d * b; }
        }
        let left = (u.iter().map(|a| a * a).sum::<f64>() / q as f64).sqrt();
        println!("no smoothing, modes kept {}: flat start misses {:.4} C rms; mode {} misses {:.6}", nn, rest, nn + 1, left);
        assert!((left - 1.0).abs() < 1e-9); // mode N+1 missed in full
    }

    assert!(gap < 1e-12); // two kernels agree
    assert!((mid_modes - mid_quad).abs() < 1e-4 && (mid_quad * 100.0).round() == 7723.0); // midpoint error ~ h^2
    assert!((rq - lam(1.0)).abs() < 1e-4); // power iteration finds ||K||
    assert!((cut3 - lam(4.0)).abs() < 1e-9); // measured ||K - K_3|| = lambda_4
    assert!((hs_quad - hs_form).abs() < 1e-5); // HS norm two roads
    assert!(gap_cf < 1e-4); // grid cut two roads
    assert!((1..8).all(|n| errs[n + 1] < errs[n]) && 1.8 < errs[4] / errs[8] && errs[4] / errs[8] < 2.2);
    assert!((1..9).all(|nn| (nn + 1..40).map(|n| lam(n as f64).powi(2)).sum::<f64>().sqrt() <= errs[nn]
                           && errs[nn] <= hs_quad)); // best rank-N cut, and a projection
    assert!((mode_gap - 2f64.sqrt()).abs() < 1e-9 && 1e-3 / lam(5.0) > 100.0);
    println!("ALL CHECKS PASS");
}
