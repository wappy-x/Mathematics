// Counting the work: Cramer's rule against elimination on a 20 by 20 system.
// std only, no crates. Every number on the card is printed here. Each flop
// (one + - * or / on two numbers) is counted where it happens, then compared
// with the formulas proved on the card.
use std::collections::BTreeMap; type Mat = Vec<Vec<f64>>;
const N: usize = 20; // unknowns; then tile, cache size and n for the memory model
const TILE: usize = 16; const CACHE: usize = 1280; const NM: usize = 48;

fn comma(k: u128) -> String {
    let s = k.to_string();
    s.chars().enumerate().map(|(i, c)| if i > 0 && (s.len() - i) % 3 == 0 { format!(",{}", c) } else { c.to_string() }).collect()
}
fn sci(x: f64) -> String { format!("{:.2e}", x) }

fn table(n: usize) -> Mat {              // M = 200(I - A): 200 on the diagonal, -a_ij * 200 off it
    (0..n).map(|i| (0..n).map(|j| if i == j { 200.0 } else { -(((3 * i + 7 * j + 10) % 11) as f64) }).collect()).collect()
}

fn pivot(a: &Mat, k: usize) -> usize {   // first row holding the largest entry in column k
    (k..a.len()).fold(k, |p, r| if a[r][k].abs() > a[p][k].abs() { r } else { p })
}

fn det_elim(m: &Mat) -> (f64, u128) {    // elimination to a staircase, then multiply the diagonal
    let (mut a, n, mut f, mut sign) = (m.clone(), m.len(), 0u128, 1.0f64);
    for k in 0..n {
        let p = pivot(&a, k);
        if p != k { a.swap(k, p); sign = -sign; }
        for i in k + 1..n {
            let mu = a[i][k] / a[k][k]; f += 1;
            for j in k + 1..n { a[i][j] -= mu * a[k][j]; f += 2; }
        }
    }
    let d = (1..n).fold(a[0][0], |d, k| { f += 1; d * a[k][k] });
    (sign * d, f)
}

fn solve(m: &Mat, b: &[f64]) -> (Vec<f64>, u128) { // elimination with the right side, then back substitution
    let (n, mut f) = (m.len(), 0u128);
    let mut a: Mat = (0..n).map(|i| { let mut r = m[i].clone(); r.push(b[i]); r }).collect();
    for k in 0..n {
        let p = pivot(&a, k); a.swap(k, p);
        for i in k + 1..n {
            let mu = a[i][k] / a[k][k]; f += 1;
            for j in k + 1..n + 1 { a[i][j] -= mu * a[k][j]; f += 2; }
        }
    }
    let mut x = vec![0.0; n];
    for i in (0..n).rev() {
        let mut s = a[i][n];
        for j in i + 1..n { s -= a[i][j] * x[j]; f += 2; }
        x[i] = s / a[i][i]; f += 1;
    }
    (x, f)
}

fn cramer(m: &Mat, b: &[f64]) -> (Vec<f64>, u128) { // x_i = det(M with column i replaced by b) / det(M)
    let ((d, mut f), mut x) = (det_elim(m), Vec::new());
    for i in 0..m.len() {
        let mi: Mat = m.iter().enumerate().map(|(k, r)| { let mut r = r.clone(); r[i] = b[k]; r }).collect();
        let (di, g) = det_elim(&mi);
        x.push(di / d); f += g + 1;
    }
    (x, f)
}

fn cofactor(m: &Mat) -> (f64, u128) {    // expansion along the top row, counted
    if m.len() == 1 { return (m[0][0], 0); }
    let (mut total, mut f) = (0.0, 0u128);
    for j in 0..m.len() {
        let minor: Mat = m[1..].iter().map(|r| { let mut r = r.clone(); r.remove(j); r }).collect();
        let (sub, g) = cofactor(&minor);
        let term = m[0][j] * sub; f += g + 1;
        if j == 0 { total = term; } else { total = if j % 2 == 1 { total - term } else { total + term }; f += 1; }
    }
    (total, f)
}

fn e_(n: u128) -> u128 { (4 * n * n * n + 9 * n * n - 7 * n) / 6 }     // solve by elimination
fn d_(n: u128) -> u128 { (4 * n * n * n - 3 * n * n + 5 * n - 6) / 6 } // one determinant by elimination
fn k_(n: u128) -> u128 { (n + 1) * d_(n) + n }                         // Cramer, determinants by elimination
fn c_(n: u128) -> u128 { if n == 1 { 0 } else { n * c_(n - 1) + 2 * n - 1 } } // one cofactor determinant
fn fact(n: u128) -> u128 { (1..=n).product() }
fn c_series(n: u128) -> u128 { (2..=n).map(|k| (2 * k - 1) * (fact(n) / fact(k))).sum() }
fn q_(n: u128) -> u128 { (n + 1) * c_(n) + n }                         // Cramer, determinants by cofactors

fn traffic(n: usize, t: usize, cache: usize, blocked: bool) -> (u128, u128) { // fetched by an LRU cache
    let (mut lru, mut last, mut now) = (BTreeMap::new(), vec![0u64; 3 * n * n], 1u64);
    let (mut miss, mut f) = (0u128, 0u128);
    let mut touch = |a: usize| {
        if last[a] > 0 { lru.remove(&last[a]); } else {
            miss += 1;
            if lru.len() == cache { let (_, old) = lru.pop_first().unwrap(); last[old] = 0; }
        }
        lru.insert(now, a); last[a] = now; now += 1;
    };
    let step = if blocked { t } else { n };
    for ii in (0..n).step_by(step) { for jj in (0..n).step_by(step) { for kk in (0..n).step_by(step) {
        for i in ii..ii + step { for j in jj..jj + step {
            touch(2 * n * n + i * n + j);
            for k in kk..kk + step { touch(i * n + k); touch(n * n + k * n + j); f += 2; }
            touch(2 * n * n + i * n + j);
        } }
    } } }
    (f, miss)
}

fn main() {
    let (m, nn) = (table(N), N as u128);
    let xt: Vec<f64> = (1..=N).map(|i| 10.0 + i as f64).collect();     // known output, $ billion (illustrative)
    let b: Vec<f64> = (0..N).map(|i| (0..N).fold(0.0, |s, j| s + m[i][j] * xt[j])).collect();
    let ((xe, fe), (xc, fc)) = (solve(&m, &b), cramer(&m, &b));
    let rel = |x: &[f64]| (0..N).map(|i| (x[i] - xt[i]).abs()).fold(0.0, f64::max) / xt[N - 1];
    let (dm, fd) = det_elim(&m);
    println!("system: n = {}, M = 200(I - A), known x_1..x_20 = 11..30, b_1 = {:.0}; M is {} numbers, {} bytes", N, b[0], N * N, comma((8 * N * N) as u128));
    println!("elimination: x_1 = {:.9}, x_20 = {:.9}, true error {}", xe[0], xe[N - 1], sci(rel(&xe)));
    println!("Cramer:      x_1 = {:.9}, x_20 = {:.9}, true error {}", xc[0], xc[N - 1], sci(rel(&xc)));
    println!("det M = {}", sci(dm));
    println!("counted, n = {}: solve {}; Cramer by elimination {}; one det {}", N, comma(fe), comma(fc), comma(fd));
    println!("formula, n = {}: solve {}; Cramer by elimination {}; one det {}; solve = {} + {} + {} + {}", N, comma(e_(nn)), comma(k_(nn)), comma(d_(nn)), N * (N - 1) / 2, comma(((N - 1) * N * (2 * N - 1) / 3) as u128), N * (N - 1), N * N);
    assert!(fe == e_(nn) && fc == k_(nn) && fd == d_(nn));
    assert!(rel(&xe) < 1e-13 && rel(&xc) < 1e-13);
    let cf: Vec<(f64, u128)> = (1..=8).map(|n| cofactor(&m[..n].iter().map(|r| r[..n].to_vec()).collect())).collect();
    let rec: Vec<u128> = (1..=8).map(c_).collect(); // the recurrence, n = 1..8
    println!("cofactor flops counted, n = 1..8: {}", cf.iter().map(|c| c.1.to_string()).collect::<Vec<_>>().join(" "));
    println!("by recurrence:                    {}", rec.iter().map(|c| c.to_string()).collect::<Vec<_>>().join(" "));
    assert!((1..=8).all(|n| cf[n - 1].1 == rec[n - 1] && rec[n - 1] == c_series(n as u128)));
    let d8 = det_elim(&m[..8].iter().map(|r| r[..8].to_vec()).collect()).0;
    println!("8 by 8 det: cofactors {}, elimination {}, relative gap {}", sci(cf[7].0), sci(d8), sci((cf[7].0 - d8).abs() / d8.abs()));
    assert!((cf[7].0 - d8).abs() < 1e-12 * d8.abs());
    let r20 = c_(20) as f64 / fact(20) as f64;
    println!("C(20) = {}; C(20)/20! = {:.12}; e = {:.12}", comma(c_(20)), r20, std::f64::consts::E);
    assert!(c_(20) == c_series(20) && (r20 - std::f64::consts::E).abs() < 1e-12);
    println!("Cramer by cofactors, n = {}: {} = {} flops", N, comma(q_(nn)), sci(q_(nn) as f64));
    for n in [5u128, 10, 20, 30, 100, 1000, 10000] {
        let q = if n <= 30 { sci(q_(n) as f64) } else { "-".to_string() };
        println!("growth n = {:>5}: solve {:>8}  Cramer-elim {:>8}  ratio {:7.1}  Cramer-cofactor {}",
                 n, sci(e_(n) as f64), sci(k_(n) as f64), k_(n) as f64 / e_(n) as f64, q);
    }
    println!("at an illustrative 1e11 flops/s: solve {} s; Cramer-cofactor {:.1} years",
             sci(e_(nn) as f64 / 1e11), q_(nn) as f64 / (1e11 * 365.25 * 86400.0));
    let lines: [(&str, fn(u128) -> u128); 3] = [("solve", e_), ("Cramer-elim", k_), ("Cramer-cofactor", q_)];
    for (name, fun) in lines {
        let pts: Vec<String> = (2..=20).step_by(2).map(|n| format!("{:.2}", (fun(n) as f64).log10())).collect();
        println!("chart, log10 {}: {}", name, pts.join(", "));
    }
    let ((fnn, mn), (fb, mb)) = (traffic(NM, TILE, CACHE, false), traffic(NM, TILE, CACHE, true));
    let (n3, n2) = ((NM * NM * NM) as u128, (NM * NM) as u128);
    let (pn, pb) = (n3 + 2 * n2, 2 * n3 / TILE as u128 + n2);
    println!("memory: C = AB, n = {}, tile {}, cache holds {} numbers", NM, TILE, CACHE);
    println!("plain loop: flops {}, numbers fetched {} (model {}), flops per number {:.2}", comma(fnn), comma(mn), comma(pn), fnn as f64 / mn as f64);
    println!("tiled loop: flops {}, numbers fetched {} (model {}), flops per number {:.2}", comma(fb), comma(mb), comma(pb), fb as f64 / mb as f64);
    let tol = |a: u128, p: u128| (a as f64 - p as f64).abs() < 0.02 * p as f64;
    assert!(fnn == fb && fb == 2 * n3 && tol(mn, pn) && tol(mb, pb));
    let nf = N as f64;
    println!("intensity, n = 20: matrix times vector {}/{} = {:.2}; matrix times matrix {}/{} = {:.2}",
             N * (2 * N - 1), N * N + 2 * N, nf * (2.0 * nf - 1.0) / (nf * nf + 2.0 * nf),
             N * N * (2 * N - 1), 3 * N * N, (2.0 * nf - 1.0) / 3.0);
    let (peak, feed, big) = (1e11f64, 2.5e9f64, 2e9 / (2e9 / 64.0 + 1e6)); // illustrative: flops/s, numbers/s (20 GB/s)
    println!("illustrative machine: {:.0} Gflop/s, {:.0} GB/s = {} numbers/s, balance {:.0} flops per number", peak / 1e9, 8.0 * feed / 1e9, sci(feed), peak / feed);
    for (name, i) in [("plain loop", fnn as f64 / mn as f64), ("tile 16", fb as f64 / mb as f64), ("tile 64, n = 1000", big)] {
        println!("  {:<18} {:6.2} flops per number -> {:6.2} Gflop/s", name, i, peak.min(i * feed) / 1e9);
    }
    println!("what breaks: multiplies and divides only, n = 20: {}", N * (N - 1) / 2 + (N - 1) * N * (2 * N - 1) / 6 + N * (N - 1) / 2 + N * (N + 1) / 2);
    println!("what breaks: leading term 2n^3/3 at n = 5: {:.1}, exact {}", 2.0 * 125.0 / 3.0, e_(5));
    println!("what breaks: Cramer by elimination over solve, n = 20: {:.1} times", k_(nn) as f64 / e_(nn) as f64);
    println!("tracker: 10,000,000 plain adds = {} flops; Kahan, 4 flops a step = {}", comma(10_000_000), comma(40_000_000));
    println!("try: n = 10, Cramer-cofactor {}; tile 8 fetched {}; cache 8192, plain loop fetched {}",
             comma(q_(10)), comma(traffic(NM, 8, CACHE, true).1), comma(traffic(NM, TILE, 8192, false).1));
    println!("ALL CHECKS PASS");
}
