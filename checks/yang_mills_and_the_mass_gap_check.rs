// Yang-Mills existence and mass gap -- the check behind the card.  Rust std only, no crates.
// Part 1 reads a published SU(3) lattice gap and extrapolates it to zero spacing.
// Part 2 builds a lattice transfer matrix (Z2 gauge theory, 2 by 2 box) and finds its gap.

// ---- Part 1: Athenodorou and Teper 2020, Table 1: beta, box in sites, a*sqrt(sigma), a*m(0++)
const DATA: [(f64, u32, f64, f64); 8] = [(5.6924, 10, 0.3999, 0.987), (5.80, 12, 0.31666, 0.908),
    (5.8941, 14, 0.26118, 0.7991), (5.99, 18, 0.21982, 0.7045), (6.0625, 20, 0.19472, 0.6365),
    (6.235, 26, 0.15003, 0.4969), (6.338, 30, 0.12928, 0.4276), (6.50, 38, 0.10383, 0.3474)];
const HBARC: f64 = 197.326980; const R0: f64 = 0.472; const R0SIG: f64 = 1.160;
const PAPER: f64 = 3.405; const PAPER_ERR: f64 = 0.021;

fn fit(p: &[(f64, u32, f64, f64)]) -> (f64, f64) { // least squares: m/sqrt(sig) = c0 + c1 (a sqrt(sig))^2
    let xs: Vec<f64> = p.iter().map(|d| d.2 * d.2).collect();
    let ys: Vec<f64> = p.iter().map(|d| d.3 / d.2).collect();
    let n = xs.len() as f64;
    let mx = xs.iter().fold(0.0, |a, x| a + x) / n; let my = ys.iter().fold(0.0, |a, y| a + y) / n;
    let (mut num, mut den) = (0.0, 0.0);
    for i in 0..xs.len() { num += (xs[i] - mx) * (ys[i] - my); }
    for i in 0..xs.len() { den += (xs[i] - mx) * (xs[i] - mx); }
    let c1 = num / den;
    (my - c1 * mx, c1)
}

// ---- Part 2: Z2 lattice gauge theory in 2+1 dimensions on a 2 by 2 spatial box
fn lid(x: usize, y: usize, d: usize) -> usize { 2 * ((x % 2) + 2 * (y % 2)) + d }
fn plaqs() -> Vec<u64> {
    let mut v = vec![];
    for y in 0..2 { for x in 0..2 {
        v.push((1u64 << lid(x, y, 0)) | (1 << lid(x + 1, y, 1)) | (1 << lid(x, y + 1, 0)) | (1 << lid(x, y, 1)));
    } }
    v
}
fn psum(s: u64, pl: &[u64]) -> i64 { pl.iter().map(|m| 1 - 2 * (((s & m).count_ones() & 1) as i64)).sum() }

fn jacobi(m: &Vec<Vec<f64>>) -> (Vec<f64>, Vec<Vec<f64>>) {
    let n = m.len(); let mut a = m.clone();
    let mut v: Vec<Vec<f64>> = (0..n).map(|i| (0..n).map(|j| if i == j { 1.0 } else { 0.0 }).collect()).collect();
    for _ in 0..60 {
        let (mut off, mut dia) = (0.0, 0.0);
        for i in 0..n { for j in 0..n { if i != j { off += a[i][j] * a[i][j]; } } }
        for i in 0..n { dia += a[i][i] * a[i][i]; }
        if off < 1e-26 * dia { break; }
        for p in 0..n - 1 { for q in p + 1..n {
            if a[p][q] == 0.0 { continue; }
            let th = (a[q][q] - a[p][p]) / (2.0 * a[p][q]);
            let t = (if th >= 0.0 { 1.0 } else { -1.0 }) / (th.abs() + (th * th + 1.0).sqrt());
            let c = 1.0 / (t * t + 1.0).sqrt(); let s = t * c;
            for r in [&mut a, &mut v] {
                for k in 0..n { let (x, y) = (r[k][p], r[k][q]); r[k][p] = c * x - s * y; r[k][q] = s * x + c * y; }
            }
            for k in 0..n { let (x, y) = (a[p][k], a[q][k]); a[p][k] = c * x - s * y; a[q][k] = s * x + c * y; }
        } }
    }
    let mut idx: Vec<usize> = (0..n).collect();
    idx.sort_by(|&i, &j| a[j][j].partial_cmp(&a[i][i]).unwrap());
    (idx.iter().map(|&i| a[i][i]).collect(), idx.iter().map(|&i| (0..n).map(|k| v[k][i]).collect()).collect())
}

// lowest level, level the plaquette sum creates, weights, eigenvalues
fn spectrum(b: f64, orb: &Vec<Vec<u64>>, pl: &[u64]) -> (Vec<f64>, Vec<f64>, f64, f64) {
    let tf = |s: u64, t: u64| (b / 2.0 * ((psum(s, pl) + psum(t, pl)) as f64)
        + b * ((8 - 2 * ((s ^ t).count_ones() as i64)) as f64)).exp();
    let tm: Vec<Vec<f64>> = orb.iter().map(|a| orb.iter().map(|bb| bb.iter().fold(0.0, |acc, &c| acc + tf(a[0], c))).collect()).collect();
    let (lam, vec) = jacobi(&tm);
    let w: Vec<f64> = (0..orb.len()).map(|n| { let mut s = 0.0;
        for i in 0..orb.len() { s += vec[n][i] * (psum(orb[i][0], pl) as f64) * vec[0][i]; } s * s }).collect();
    let wmax = w[1..].iter().cloned().fold(0.0, f64::max);
    let first = (1..orb.len()).find(|&n| w[n] > 1e-9 * wmax).unwrap();
    let (low, gap) = ((lam[0] / lam[1]).ln(), (lam[0] / lam[first]).ln());
    (lam, w, low, gap)
}

// ln Z by summing every link configuration of a 2x2xnt periodic lattice
fn brute(nt: usize, b: f64, pl: &[u64]) -> f64 {
    let mut masks: Vec<u64> = vec![];
    for t in 0..nt {
        let tl = |x: usize, y: usize| 1u64 << (8 * nt + 4 * t + (x % 2) + 2 * (y % 2)); // timelike link, layer t
        for m in pl { masks.push(m << (8 * t)); }
        for y in 0..2 { for x in 0..2 { for d in 0..2 {
            let l = lid(x, y, d);
            masks.push((1u64 << (l + 8 * t)) ^ (1u64 << (l + 8 * ((t + 1) % nt))) ^ tl(x, y) ^ tl(x + 1 - d, y + d));
        } } }
    }
    let vecf = |c: u64| masks.iter().enumerate().fold(0u64, |acc, (j, m)| acc + ((((c & m).count_ones() & 1) as u64) << j));
    let lo: Vec<u64> = (0..256u64).map(|c| vecf(c)).collect();
    let hi: Vec<u64> = (0..(1u64 << (12 * nt - 8))).map(|c| vecf(c << 8)).collect();
    let mut hist = vec![0u64; masks.len() + 1];
    for h in &hi { for v in &lo { hist[(h ^ v).count_ones() as usize] += 1; } }
    let mut z = 0.0;
    for (k, &n) in hist.iter().enumerate() { z += (n as f64) * (b * ((masks.len() as f64) - 2.0 * (k as f64))).exp(); }
    z.ln()
}

fn main() {
    let sig = R0SIG * HBARC / R0; // sqrt(string tension) in MeV
    println!("part 1: SU(3) glueball gap on the lattice (Athenodorou and Teper 2020)");
    println!("beta    box  a*sqrt(sig)  a*m     m/sqrt(sig)  a (fm)   box (fm)  m (MeV)");
    for &(b, l, s, m) in DATA.iter() {
        let a = s * HBARC / sig;
        println!("{:<7.4} {:>3}  {:.5}      {:.4}  {:.6}     {:.5}  {:.3}     {:.1}", b, l, s, m, m / s, a, (l as f64) * a, m / s * sig);
    }
    println!("scale: sqrt(sigma) = {:.3} x {:.6} / {:.3} = {:.3} MeV; paper: 485(6) MeV", R0SIG, HBARC, R0, sig);
    assert!((sig - 485.0).abs() < 6.0);
    let (c0, c1) = fit(&DATA[2..]);
    let (c0all, _) = fit(&DATA);
    let mean = DATA.iter().fold(0.0, |a, d| a + d.3 / d.2) / (DATA.len() as f64);
    println!("continuum fit, 6 finest: m/sqrt(sig) = {:.6} + ({:.6}) (a sqrt(sig))^2", c0, c1);
    println!("paper's fit {:.3}({:.0}): difference {:.6}", PAPER, PAPER_ERR * 1000.0, c0 - PAPER);
    println!("continuum gap: {:.6} x {:.3} = {:.1} MeV;  paper's: {:.1} MeV", c0, sig, c0 * sig, PAPER * sig);
    assert!((c0 - PAPER).abs() < PAPER_ERR);
    assert!((DATA[7].3 / DATA[7].2 / c0 - 1.0).abs() < 0.02);

    let pl = plaqs();
    let mut flip = vec![];
    for y in 0..2 { for x in 0..2 { flip.push((1u64 << lid(0, y, 0)) | (1 << lid(1, y, 0)) | (1 << lid(x, 0, 1)) | (1 << lid(x, 1, 1))); } }
    let mut gauge: Vec<u64> = (0..16u64).map(|i| (i & 1) * flip[0] ^ (i >> 1 & 1) * flip[1] ^ (i >> 2 & 1) * flip[2] ^ (i >> 3 & 1) * flip[3]).collect();
    gauge.sort(); gauge.dedup();
    let mut orb: Vec<Vec<u64>> = vec![]; let mut seen = [false; 256];
    for s in 0..256u64 {
        if !seen[s as usize] { let o: Vec<u64> = gauge.iter().map(|g| s ^ g).collect(); for &c in &o { seen[c as usize] = true; } orb.push(o); }
    }
    println!("part 2: Z2 gauge theory, 2+1 dimensions, 2x2 box: {} gauge changes, {} invariant states", gauge.len(), orb.len());
    println!("beta  lowest level  2(-ln tanh)  plaquette level  4(-ln tanh)  ratio  smallest eigenvalue");
    let mut ratios = vec![]; let mut store = vec![];
    for &b in [0.1, 0.2, 0.3, 0.4, 0.5].iter() {
        let (lam, w, low, gap) = spectrum(b, &orb, &pl); let u = -(b.tanh()).ln();
        ratios.push(gap / (4.0 * u));
        let mn = lam.iter().cloned().fold(f64::INFINITY, f64::min);
        println!("{:.1}   {:.6}      {:.6}     {:.6}         {:.6}     {:.4} {:.6}", b, low, 2.0 * u, gap, 4.0 * u, gap / (4.0 * u), mn);
        assert!(mn > 0.0);
        store.push((b, lam, w, low, gap));
    }
    assert!(ratios[0] > ratios[1] && ratios[1] > ratios[2] && ratios[0] > 0.95);

    let (_, lam, w, _, gap) = &store[2];
    let cc: Vec<f64> = (0..7).map(|t| { let mut s = 0.0; for n in 1..lam.len() { s += w[n] * (lam[n] / lam[0]).powf(t as f64); } s }).collect();
    let meff: Vec<f64> = (0..6).map(|t| (cc[t] / cc[t + 1]).ln()).collect();
    let ms: Vec<String> = meff.iter().map(|m| format!("{:.6}", m)).collect();
    println!("beta 0.3, effective mass ln(C(t)/C(t+1)), t = 0..5: {}", ms.join(" "));
    assert!(meff[0] > meff[2] && meff[2] > meff[5] && meff[5] > *gap && meff[5] - gap < 1e-3);

    for nt in [1usize, 2] {
        for (bi, b) in [(2usize, 0.3), (4, 0.5)] {
            let lam = &store[bi].1;
            let zt = (16f64.powi(nt as i32) * lam.iter().fold(0.0, |a, l| a + l.powf(nt as f64))).ln(); let zb = brute(nt, b, &pl);
            println!("ln Z, {} time step(s), beta {:.1}: every configuration {:.9}  transfer matrix {:.9}", nt, b, zb, zt);
            assert!((zb - zt).abs() < 1e-9);
        }
    }

    println!("what breaks:");
    println!("  lowest level in the box at beta 0.3: {:.6}, not the plaquette's {:.6}", store[2].3, store[2].4);
    println!("  plain average of m/sqrt(sig), no extrapolation: {:.6}, not {:.6}; all 8 points: {:.6}", mean, c0, c0all);
    println!("  effective mass at t = 0: {:.6}, not {:.6} ({:.1}% high)", meff[0], gap, 100.0 * (meff[0] / gap - 1.0));
    println!("  strong coupling at beta 0.5: {:.6}, not {:.6}", 4.0 * -(0.5f64.tanh()).ln(), store[4].4);
    let sig5 = R0SIG * HBARC / 0.5; let g05 = spectrum(0.05, &orb, &pl).3;
    println!("try: r0 = 0.500 fm: sqrt(sigma) {:.3} MeV, gap {:.1} MeV; beta 0.05: plaquette level {:.6}, ratio to 4(-ln tanh) {:.4}",
        sig5, c0 * sig5, g05, g05 / (-4.0 * (0.05f64.tanh()).ln()));
    println!("ALL CHECKS PASS");
}
