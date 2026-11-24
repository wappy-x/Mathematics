// Burgard-Kjaer -- the same check as burgard_kjaer_funding_pde_check.py, in Rust.  No crates.
// The Acme call (S = K = 100, r = 5%, q = 2%, sigma = 20%, T = 1) bought from Northwind with no
// collateral.  Northwind's hazard 2%, the bank's own 1%, recovery 40% each; the bank borrows at
// 100 bp over r and lends at r.  One equation, three roads: closed forms where the funding never
// changes sign, a Crank-Nicolson grid (kink handled by policy iteration), and a binomial tree.
use std::f64::consts::PI;

const S0: f64 = 100.0;
const K: f64 = 100.0;
const R: f64 = 0.05;
const Q: f64 = 0.02;
const SIG: f64 = 0.20;
const T: f64 = 1.0;
const LC: f64 = 0.02; const LO: f64 = 0.01;           // hazards: Northwind's, the bank's own
const RC: f64 = 0.40; const RO: f64 = 0.40;           // recoveries
const SB: f64 = 0.01; const SL: f64 = 0.0;            // borrowing and lending spreads
const M: usize = 300; const NT: usize = 200; const XM: f64 = 1.5;   // grid in x = ln(S/K), steps

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n_cdf(x: f64) -> f64 {                              // 1/2 + phi(x)(x + x^3/3 + x^5/15 + ...)
    if x.abs() > 9.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    let (mut term, mut total, mut j) = (x, x, 1.0);
    while term.abs() > 1e-17 * total.abs() { j += 2.0; term *= x * x / j; total += term; }
    0.5 + phi(x) * total
}
fn bs(s: f64, left: f64, put: bool) -> f64 {           // clean Acme option, `left` years to run
    let v = SIG * left.sqrt();
    let d1 = ((s / K).ln() + (R - Q + 0.5 * SIG * SIG) * left) / v;
    if put { return K * (-R * left).exp() * n_cdf(v - d1) - s * (-Q * left).exp() * n_cdf(-d1); }
    s * (-Q * left).exp() * n_cdf(d1) - K * (-R * left).exp() * n_cdf(d1 - v)
}

fn thomas(sub: &[f64], dia: &[f64], sup: &[f64], rhs: &[f64]) -> Vec<f64> {
    let n = dia.len();
    let (mut c, mut d) = (vec![0.0; n], vec![0.0; n]);
    c[0] = sup[0] / dia[0]; d[0] = rhs[0] / dia[0];
    for i in 1..n {
        let m = dia[i] - sub[i] * c[i - 1];
        c[i] = sup[i] / m; d[i] = (rhs[i] - sub[i] * d[i - 1]) / m;
    }
    for i in (0..n - 1).rev() { d[i] -= c[i] * d[i + 1]; }
    d
}

// W_tau = A W_xx + B W_x - rate(W) W + src, Crank-Nicolson from expiry.  rate(w) reads the node's
// own sign (the kink); each step re-solves until no node changes side.  Returns every row.
fn grid(pay: &[f64], rate: &dyn Fn(f64) -> f64, src: Option<&dyn Fn(usize) -> Vec<f64>>) -> Vec<Vec<f64>> {
    let (h, k) = (2.0 * XM / M as f64, T / NT as f64);
    let (a, b) = (0.5 * SIG * SIG, R - Q - 0.5 * SIG * SIG);
    let (lo, hi, md) = (a * k / h / h - b * k / 2.0 / h, a * k / h / h + b * k / 2.0 / h, 2.0 * a * k / h / h);
    let (ea, eb) = ((-h).exp(), h.exp());              // far edges: value straight in S
    let mut w = pay.to_vec();
    let mut rows = vec![w.clone()];
    let z = vec![0.0; M + 1];
    for n in 0..NT {
        let (s0, s1) = match src { Some(f) => (f(n), f(n + 1)), None => (z.clone(), z.clone()) };
        let rhs: Vec<f64> = (1..M).map(|i| w[i] + 0.5 * (lo * w[i - 1] - (md + k * rate(w[i])) * w[i] + hi * w[i + 1])
            + 0.5 * k * (s0[i] + s1[i])).collect();
        let mut guess = w.clone();
        let mut new = w.clone();
        for _ in 0..50 {
            let rho: Vec<f64> = guess.iter().map(|&x| rate(x)).collect();
            let mut dia: Vec<f64> = (1..M).map(|i| 1.0 + 0.5 * (md + k * rho[i])).collect();
            let (mut sub, mut sup) = (vec![-0.5 * lo; M - 1], vec![-0.5 * hi; M - 1]);
            dia[0] -= 0.5 * lo * (1.0 + ea); sup[0] += 0.5 * lo * ea;
            dia[M - 2] -= 0.5 * hi * (1.0 + eb); sub[M - 2] += 0.5 * hi * eb;
            let u = thomas(&sub, &dia, &sup, &rhs);
            new = vec![(1.0 + ea) * u[0] - ea * u[1]];
            new.extend_from_slice(&u);
            new.push((1.0 + eb) * u[M - 2] - eb * u[M - 3]);
            if new.iter().map(|&x| rate(x)).collect::<Vec<f64>>() == rho { break; }
            guess = new.clone();
        }
        w = new;
        rows.push(w.clone());
    }
    rows
}

// binomial road, same rules one step at a time
fn tree(pay: &dyn Fn(f64) -> f64, lc: f64, lo: f64, sl: f64, n: usize) -> f64 {
    let dt = T / n as f64;
    let u = (SIG * dt.sqrt()).exp();
    let p = (((R - Q) * dt).exp() - 1.0 / u) / (u - 1.0 / u);
    let mut v: Vec<f64> = (0..=n).map(|j| pay(S0 * u.powi(2 * j as i32 - n as i32))).collect();
    let mut w = v.clone();
    for m in (0..n).rev() {
        v = (0..=m).map(|j| (-R * dt).exp() * (p * v[j + 1] + (1.0 - p) * v[j])).collect();
        w = (0..=m).map(|j| {
            let c = p * w[j + 1] + (1.0 - p) * w[j];
            (-(R + lc + lo + if c > 0.0 { SB } else { sl }) * dt).exp() * c
                + dt * (lc * (RC * v[j].max(0.0) + v[j].min(0.0)) + lo * (v[j].max(0.0) + RO * v[j].min(0.0)))
        }).collect();
    }
    v[0] - w[0]
}

fn main() {
    let h = 2.0 * XM / M as f64;
    let s: Vec<f64> = (0..=M).map(|i| K * (-XM + i as f64 * h).exp()).collect();
    let mid = M / 2;
    let mut cpay: Vec<f64> = s.iter().map(|&x| (x - K).max(0.0)).collect();
    cpay[mid] = K * ((h / 2.0).exp() - 1.0 - h / 2.0) / h;   // cell average
    let v = grid(&cpay, &|_| R, None);                 // clean call, every row
    let pos = |n: usize, c: f64| -> Vec<f64> { v[n].iter().map(|&x| c * x.max(0.0)).collect() };
    let z0 = vec![0.0; M + 1];
    let cva_g = grid(&z0, &|_| R + LC, Some(&|n| pos(n, (1.0 - RC) * LC)))[NT][mid];
    let fca_g = grid(&z0, &|_| R + LC, Some(&|n| pos(n, SB)))[NT][mid];
    let dva_g = grid(&z0, &|_| R + LC + LO, Some(&|n| pos(n, (1.0 - RO) * LO)))[NT][mid];
    // full Burgard-Kjaer for the bought call: U jumps to R_C V at Northwind's default, to V at the bank's
    let u = grid(&cpay, &|w| R + LC + LO + if w > 0.0 { SB } else { SL }, Some(&|n| pos(n, LC * RC + LO)));
    let bk_g = v[NT][mid] - u[NT][mid];
    let neg: Vec<f64> = cpay.iter().map(|c| -c).collect();   // the call sold instead
    let us = grid(&neg, &|w| R + LC + LO + if w > 0.0 { SB } else { SL }, Some(&|n| pos(n, -(LC + LO * RO))));
    let sold_g = -v[NT][mid] - us[NT][mid];

    let (c0, p0) = (bs(S0, T, false), bs(S0, T, true));
    let ann = |lam: f64| (1.0 - (-lam * T).exp()) / lam; // expected years alive within the year
    let (cva_u, fca_u) = ((1.0 - RC) * c0 * (1.0 - (-LC * T).exp()), SB * c0 * ann(LC));
    let (cva_b, fca_b, dva_b) = ((1.0 - RC) * LC * c0 * ann(LC + LO), SB * c0 * ann(LC + LO), (1.0 - RO) * LO * c0 * ann(LC + LO));
    let bk_c = ((1.0 - RC) * LC + SB) * c0 * ann(LC + LO + SB);   // U never changes sign: closed form
    let bk_t = tree(&|x| (x - K).max(0.0), LC, LO, SL, 2000);

    // funding alone (no defaults): call bought plus put sold, one netting set = a forward at K
    let fpay: Vec<f64> = s.iter().map(|&x| x - K).collect();
    let vf = grid(&fpay, &|_| R, None)[NT][mid];
    let bps = [0, 25, 50, 75, 100];
    let net: Vec<f64> = bps.iter().map(|&bp| {
        let sl = bp as f64 / 10000.0;
        vf - grid(&fpay, &|w| R + if w > 0.0 { SB } else { sl }, None)[NT][mid]
    }).collect();
    let pieces: Vec<f64> = bps.iter().map(|&bp| c0 * (1.0 - (-SB * T).exp()) - p0 * (1.0 - (-(bp as f64) / 10000.0 * T).exp())).collect();
    let net_t = tree(&|x| x - K, 0.0, 0.0, SL, 2000);

    let rows: Vec<(&str, f64)> = vec![
        ("clean call C0", c0), ("clean put P0", p0), ("clean forward C0 - P0", c0 - p0),
        ("expected years alive, Northwind only", ann(LC)), ("expected years alive, both", ann(LC + LO)),
        ("expected years alive, plus spread", ann(LC + LO + SB)),
        ("linear, Northwind only: CVA closed", cva_u), ("  CVA grid", cva_g),
        ("  FCA closed", fca_u), ("  FCA grid", fca_g),
        ("linear, both can fail: CVA", cva_b), ("  FCA", fca_b), ("  DVA (bought call)", 0.0),
        ("  sum of pieces", cva_b + fca_b), ("  DVA of the sold call, closed", dva_b),
        ("  DVA of the sold call, grid", dva_g),
        ("full equation, call: closed", bk_c), ("  grid", bk_g), ("  tree, 2000 steps", bk_t),
        ("  all-in value C0 - X", c0 - bk_g), ("  gap: pieces minus full", cva_b + fca_b - bk_g),
        ("funding alone: call FCA", c0 * (1.0 - (-SB * T).exp())), ("  sold put, no lending benefit", 0.0),
        ("  trade by trade, sum", pieces[0]), ("  netting set, grid", net[0]),
        ("  netting set, tree", net_t), ("  netting set, symmetric 100 bp", net[4]),
        ("  symmetric closed (C0-P0)(1-e^-s)", (c0 - p0) * (1.0 - (-SB * T).exp())),
        ("wrong: one blended rate, 50 bp", (c0 - p0) * (1.0 - (-0.005 * T).exp())),
        ("try: sold call, full equation, grid", sold_g),
    ];
    for (name, x) in &rows { println!("{:<38}{:12.6}", name, x); }
    let join = |xs: Vec<String>| xs.join(" ");
    println!("chart, lending spread bp {}", join(bps.iter().map(|b| format!("{:6}", b)).collect()));
    println!("chart, netting set grid  {}", join(net.iter().map(|x| format!("{:6.2}", 100.0 * x)).collect()));
    println!("chart, trade by trade    {}", join(pieces.iter().map(|x| format!("{:6.2}", 100.0 * x)).collect()));

    assert!((c0 - 9.227005508154).abs() < 1e-9, "own normal CDF reproduces the house call");
    assert!((cva_g - cva_u).abs() < 2e-5 && (fca_g - fca_u).abs() < 2e-5, "linear grid gives the CVA and FVA cards");
    assert!((dva_g - dva_b).abs() < 2e-5, "grid DVA of the sold call matches its closed form");
    assert!((bk_g - bk_c).abs() < 2e-5, "nonlinear grid matches the closed form where U keeps one sign");
    assert!((sold_g + dva_b).abs() < 2e-5, "sold call: the full equation leaves exactly minus the DVA");
    assert!((bk_t - bk_c).abs() < 2e-4, "tree matches the closed form");
    assert!((net[4] - (c0 - p0) * (1.0 - (-SB * T).exp())).abs() < 2e-5, "symmetric funding: netting set adds up");
    assert!((net_t - net[0]).abs() < 2e-4, "tree and grid agree on the kinked netting set");
    assert!(net[4] + 1e-3 < net[0] && net[0] < pieces[0] - 1e-3, "kink: neither symmetric nor additive");
    println!("ALL CHECKS PASS");
}
