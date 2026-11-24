// Iterative refinement: factor once in low precision, form each residual in double, win back double accuracy.
const R: usize = 16;
const C: usize = 16;
const N: usize = R * C; // a 16 by 16 grid of junctions: 256 unknown drawdowns, 480 grid pipes + 20 feed pipes
type Mat = Vec<Vec<f64>>;
struct Lu { a: Mat, perm: Vec<usize>, nz_l: Vec<Vec<usize>>, nz_u: Vec<Vec<usize>>, swaps: usize }

fn rnd(x: f64, p: u32) -> f64 { // round a double to p significant bits, ties to even (p = 24 single, 11 half, 53 double)
    if p == 53 || x == 0.0 { return x; }
    let b = x.to_bits(); let sh = 53 - p; let rem = b & ((1u64 << sh) - 1); let mut t = b - rem; let half = 1u64 << (sh - 1);
    if rem > half || (rem == half && (t >> sh) & 1 == 1) { t += 1u64 << sh; }
    f64::from_bits(t)
}
fn network(feeds: &[usize], g_feed: f64) -> Mat { // nodal matrix: row i says water into junction i = the demand drawn there
    let mut a = vec![vec![0.0; N]; N];
    let mut pipe = |i: usize, j: usize, g: f64| { a[i][i] += g; a[j][j] += g; a[i][j] -= g; a[j][i] -= g; };
    for r in 0..R { for c in 0..C {
        let k = r * C + c;
        if c + 1 < C { pipe(k, k + 1, (1 + (7 * r + 3 * c) % 3) as f64); } // conductance 1, 2 or 3 L/s per m
        if r + 1 < R { pipe(k, k + C, (1 + (7 * r + 3 * c + 1) % 3) as f64); }
    } }
    for &k in feeds { a[k][k] += g_feed; } // a feed pipe from the reservoir
    a
}
fn lu(m: &Mat, p: u32) -> Lu { // LU with partial pivoting, every operation rounded to p bits
    let mut a: Mat = m.iter().map(|row| row.iter().map(|&v| rnd(v, p)).collect()).collect();
    let mut perm: Vec<usize> = (0..N).collect(); let mut swaps = 0;
    for k in 0..N {
        let mut mi = k;
        for i in k..N { if a[i][k].abs() > a[mi][k].abs() { mi = i; } }
        if mi != k { a.swap(k, mi); perm.swap(k, mi); swaps += 1; }
        let cols: Vec<usize> = (k + 1..N).filter(|&j| a[k][j] != 0.0).collect();
        for i in k + 1..N {
            if a[i][k] == 0.0 { continue; } // a zero multiplier changes nothing: skipped for speed only
            let l = rnd(a[i][k] / a[k][k], p); a[i][k] = l;
            for &j in &cols { a[i][j] = rnd(a[i][j] - rnd(l * a[k][j], p), p); }
        }
    }
    let nz_l = (0..N).map(|i| (0..i).filter(|&j| a[i][j] != 0.0).collect()).collect();
    let nz_u = (0..N).map(|i| (i + 1..N).filter(|&j| a[i][j] != 0.0).collect()).collect();
    Lu { a, perm, nz_l, nz_u, swaps }
}
fn solve(f: &Lu, b: &[f64], p: u32) -> Vec<f64> { // sweep down L, then up U, rounding to p bits
    let (mut y, mut x) = (vec![0.0; N], vec![0.0; N]);
    for i in 0..N {
        let mut s = rnd(b[f.perm[i]], p);
        for &j in &f.nz_l[i] { s = rnd(s - rnd(f.a[i][j] * y[j], p), p); }
        y[i] = s;
    }
    for i in (0..N).rev() {
        let mut s = y[i];
        for &j in &f.nz_u[i] { s = rnd(s - rnd(f.a[i][j] * x[j], p), p); }
        x[i] = rnd(s / f.a[i][i], p);
    }
    x
}
fn matvec(a: &Mat, x: &[f64], p: u32) -> Vec<f64> {
    a.iter().map(|row| { let mut s = 0.0;
        for (j, &v) in row.iter().enumerate() { if v != 0.0 { s = rnd(s + rnd(v * x[j], p), p); } } s }).collect()
}
fn norm(v: &[f64]) -> f64 { v.iter().fold(0.0, |m: f64, t| m.max(t.abs())) }
fn rel(x: &[f64], xs: &[f64]) -> f64 { norm(&(0..N).map(|i| x[i] - xs[i]).collect::<Vec<_>>()) / norm(xs) }
fn unit(j: usize) -> Vec<f64> { (0..N).map(|i| if i == j { 1.0 } else { 0.0 }).collect() }
fn setup(feeds: &[usize], g_feed: f64) -> (Mat, Lu, f64, f64, f64, Vec<f64>, Vec<f64>, bool) { // kappa two ways, exact truth
    let a = network(feeds, g_feed); let f64lu = lu(&a, 53);
    let na = a.iter().map(|row| row.iter().map(|v| v.abs()).sum::<f64>()).fold(0.0, f64::max);
    let inv: Mat = (0..N).map(|j| solve(&f64lu, &unit(j), 53)).collect(); // columns
    let n_inv = (0..N).map(|i| (0..N).map(|j| inv[j][i].abs()).sum::<f64>()).fold(0.0, f64::max);
    let w = solve(&f64lu, &vec![1.0; N], 53); // A^-1 has no negative entry, so its norm is the largest entry of A^-1 * ones
    let xs: Vec<f64> = w.iter().map(|v| (v * 1048576.0).round_ties_even() / 1048576.0).collect(); // 2^-20 m grid
    let b = matvec(&a, &xs, 53); // demands those drawdowns imply; checked exact in whole-number arithmetic
    let exact = a.iter().enumerate().all(|(i, row)| (b[i] * 2f64.powi(30)).fract() == 0.0 &&
        row.iter().enumerate().map(|(j, v)| (v * 1024.0) as i128 * (xs[j] * 1048576.0) as i128).sum::<i128>()
            == (b[i] * 2f64.powi(30)) as i128);
    (a, f64lu, na, n_inv, norm(&w), xs, b, exact)
}
fn refine(a: &Mat, f: &Lu, b: &[f64], xs: &[f64], pf: u32, pr: u32, px: u32, steps: usize) -> (Vec<f64>, Vec<f64>) {
    let mut x: Vec<f64> = solve(f, b, pf).iter().map(|&v| rnd(v, px)).collect(); // pf factor, pr residual, px answer
    let (mut err, mut dn) = (vec![rel(&x, xs)], vec![]);
    for _ in 0..steps {
        let r: Vec<f64> = matvec(a, &x, pr).iter().enumerate().map(|(i, v)| rnd(b[i] - v, pr)).collect();
        let d = solve(f, &r, pf); dn.push(norm(&d) / norm(&x));
        x = (0..N).map(|i| rnd(x[i] + d[i], px)).collect(); err.push(rel(&x, xs));
    }
    (err, dn)
}
fn e(x: f64, p: usize) -> String { // Python-style e-notation: 6.84e-06
    let s = format!("{:.*e}", p, x); let (m, ex) = s.split_once('e').unwrap(); let ex: i32 = ex.parse().unwrap();
    format!("{}e{}{:02}", m, if ex < 0 { '-' } else { '+' }, ex.abs())
}
fn commas(n: u64) -> String {
    let s = n.to_string(); let mut out = String::new();
    for (i, ch) in s.chars().enumerate() { if i > 0 && (s.len() - i) % 3 == 0 { out.push(','); } out.push(ch); }
    out
}
fn first_where(v: &[f64], t: f64) -> usize { v.iter().position(|&x| x < t).unwrap() }
fn eta_g(a: &Mat, f: &Lu, na: f64) -> (f64, f64) { // eta = |PA - LU|/|A| and |G| = |I - F^-1 A| for the factors f
    let mut rows: Mat = (0..N).map(|i| (0..N).map(|j| if j >= i { f.a[i][j] } else { 0.0 }).collect()).collect();
    for i in 0..N { for &k in &f.nz_l[i] { for j in k..N { rows[i][j] += f.a[i][k] * f.a[k][j]; } } } // L times U, exact products
    let eta = (0..N).map(|i| (0..N).map(|j| (a[f.perm[i]][j] - rows[i][j]).abs()).sum::<f64>()).fold(0.0, f64::max) / na;
    let m: Mat = (0..N).map(|j| solve(f, &(0..N).map(|i| a[i][j]).collect::<Vec<_>>(), 53)).collect(); // F^-1 A
    (eta, (0..N).map(|i| (0..N).map(|j| (if i == j { 1.0 } else { 0.0 } - m[j][i]).abs()).sum::<f64>()).fold(0.0, f64::max))
}
fn main() {
    let (u11, u24, u53) = (2f64.powi(-11), 2f64.powi(-24), 2f64.powi(-53));
    let mut feeds: Vec<usize> = (0..C).collect(); feeds.extend((1..5).map(|r| C * r)); // top row and four down the left side
    let (a, f64lu, na, n_inv, n_w, xs, b, exact) = setup(&feeds, 2.0);
    let kap = na * n_inv;
    println!("network: {} junctions, {} grid pipes + {} feed pipes; A is {} by {}", N, 2 * R * (C - 1), feeds.len(), N, N);
    println!("norm A {:.2}  norm A^-1 {:.4} (full inverse) {:.4} (A^-1 x ones)  kappa {:.2}", na, n_inv, n_w, kap);
    println!("unit roundoff: half {}  single {}  double {}", e(u11, 2), e(u24, 2), e(u53, 2));
    println!("kappa x u: half {:.2}  single {}  double {}", kap * u11, e(kap * u24, 2), e(kap * u53, 2));
    let (mn, mx) = (b.iter().cloned().fold(f64::MAX, f64::min), b.iter().cloned().fold(f64::MIN, f64::max));
    let pyb = |t: bool| if t { "True" } else { "False" };
    println!("true drawdowns: largest {:.6} m; demands {:.7} to {:.7} L/s; exact: {}", norm(&xs), mn, mx, pyb(exact));
    assert!(exact && (n_inv - n_w).abs() < 1e-12 * n_w && 1e3 < kap && kap < 2e3);
    let f32lu = lu(&a, 24); let a32 = &f32lu.a; let (eta, ng) = eta_g(&a, &f32lu, na);
    let lib = a32.iter().flatten().filter(|&&v| (v as f32) as f64 == v).count();
    println!("single LU: swaps {}, eta = |PA - LU|/|A| {} = {:.2} u_single, library f32 agrees on {} of {}", f32lu.swaps, e(eta, 2), eta / u24, lib, N * N);
    println!("|G| = |I - F^-1 A| {} <= kappa eta/(1 - kappa eta) {}", e(ng, 2), e(kap * eta / (1.0 - kap * eta), 2));
    assert!(lib == N * N && ng <= kap * eta / (1.0 - kap * eta) && ng < 1.0);
    let (mix, dmix) = refine(&a, &f32lu, &b, &xs, 24, 53, 53, 8); let (fix, _) = refine(&a, &f32lu, &b, &xs, 24, 24, 24, 8);
    let f16lu = lu(&a, 11); let (hal, _) = refine(&a, &f16lu, &b, &xs, 11, 53, 53, 8); let (eh, gh) = eta_g(&a, &f16lu, na);
    println!("step  mixed: single LU,  |d|/|x|   fixed: all     half LU,");
    println!("      double residual               single         double residual");
    for k in 0..9 {
        println!("{:3}   {}  {:>10}    {}       {}", k, e(mix[k], 2), e(if k > 0 { dmix[k - 1] } else { 0.0 }, 2), e(fix[k], 2), e(hal[k], 2));
    }
    let x0 = solve(&f32lu, &b, 24); let e0: Vec<f64> = (0..N).map(|i| x0[i] - xs[i]).collect();
    let fe = solve(&f32lu, &matvec(&a, &e0, 53), 53);
    let ge: Vec<f64> = (0..N).map(|i| e0[i] - fe[i]).collect(); // G e0, the proof's prediction of e1
    let r1 = norm(&ge) / norm(&xs);
    let (rat, bnd) = (mix[1] / mix[0], kap * eta / (1.0 - kap * eta));
    println!("step ratios {} {}; |G| is {:.1} times the first, the bound {:.1} times", e(rat, 2), e(mix[2] / mix[1], 2), ng / rat, bnd / rat);
    println!("proof's G e0 predicts e1 {}; observed e1 / predicted {:.3}", e(r1, 2), mix[1] / r1);
    let stop = (1..8).find(|&k| dmix[k] <= u53 || dmix[k] > dmix[k - 1] / 2.0).unwrap();
    let xd = solve(&f64lu, &b, 53); let ed = rel(&xd, &xs);
    println!("stop test passes at step {}: error {}; floor kappa x u_double {}; double LU {}", stop + 1, e(mix[stop + 1], 2), e(kap * u53, 2), e(ed, 2));
    let mx3 = mix[3..].iter().cloned().fold(0.0, f64::max);
    assert!(mix[1] < kap * u24 * mix[0] && mix[2] < 1e-14 && mx3 < kap * u53 && (mix[1] / r1 - 1.0).abs() < 0.1);
    assert!(fix.iter().cloned().fold(1.0, f64::min) > 10.0 * u24 && hal[8] < 1e-5 && hal[8] < hal[4] && hal[4] < hal[0] && kap * eh > 0.5 && (0..8).all(|k| hal[k + 1] < gh * hal[k]));
    let n = N as u64; let f_cost = (4 * n * n * n - 3 * n * n - n) / 6; let s_cost = 2 * n * n + (2 * n * n - n) + n;
    println!("flops n = {}: factor {} (single), each step {} = 4n^2, {} steps {:.2}% of the factor", N, commas(f_cost), commas(s_cost), stop + 1, (stop + 1) as f64 * s_cost as f64 / f_cost as f64 * 100.0);
    let tiny = f16lu.a.iter().flatten().filter(|&&v| v != 0.0 && v.abs() < 2f64.powi(-14)).count();
    println!("half LU: {} factor entries below 6.10e-5, half precision's smallest normal number (range ignored here)", tiny);
    println!("half LU: swaps {}, eta {} = {:.2} u_half, kappa eta {:.2} > 1/2, yet |G| {:.3} < 1; step ratio {:.2}", f16lu.swaps, e(eh, 2), eh / u11, kap * eh, gh, hal[1] / hal[0]);
    let (aw, _, naw, niw, _, xw, bw, ex2) = setup(&[0], 2f64.powi(-4)); let kw = naw * niw;
    let (hw, _) = refine(&aw, &lu(&aw, 11), &bw, &xw, 11, 53, 53, 12); let (sw, _) = refine(&aw, &lu(&aw, 24), &bw, &xw, 24, 53, 53, 3);
    let (xsg, _) = refine(&a, &f32lu, &b, &xs, 24, 53, 24, 8);
    println!("weak feed (one pipe, 0.0625 L/s per m): kappa {:.2}, kappa x u_half {:.1}, exact: {}", kw, kw * u11, pyb(ex2));
    println!("  half LU after 12 steps: error {} (start {}); single LU after 3 steps: {}", e(hw[12], 3), e(hw[0], 3), e(sw[3], 2));
    let mnmx = |v: &[f64]| (v.iter().cloned().fold(f64::MAX, f64::min), v.iter().cloned().fold(0.0, f64::max));
    let ((g1, g2), (h1, h2)) = (mnmx(&xsg[1..]), mnmx(&fix[1..]));
    println!("wrong: no refinement {}; answer kept in single {} to {}", e(mix[0], 2), e(g1, 2), e(g2, 2));
    println!("wrong: residual and answer in single {} to {}", e(h1, 2), e(h2, 2));
    assert!(ex2 && kw * u11 > 1.0 && hw[12] > 0.1 && sw[3] < 1e-11 && g1 > 0.1 * u24);
    println!("chart, step         {}", (0..9).map(|k| format!("{:6}", k)).collect::<Vec<_>>().join(" "));
    for (name, v) in [("mixed", &mix), ("fixed", &fix), ("half ", &hal)] {
        println!("chart, log10 {}  {}", name, v.iter().map(|x| format!("{:6.1}", x.log10())).collect::<Vec<_>>().join(" "));
    }
    let n2: u64 = 1000; let f2 = (4 * n2 * n2 * n2 - 3 * n2 * n2 - n2) / 6;
    let k12 = first_where(&refine(&a, &f16lu, &b, &xs, 11, 53, 53, 30).0, 1e-12);
    println!("try: half steps to 1e-12: {}; n = 1000: {} steps {:.2}% of the factor", k12, stop + 1, (stop + 1) as f64 * 4.0 * (n2 * n2) as f64 / f2 as f64 * 100.0);
    println!("ALL CHECKS PASS");
}
