// Correlated paths -- the same check as the Python, in Rust.  No crates.  The
// factor, the normal draws, the standard deviations and the correlations are
// all written out here.  Three shares, Borex at $80, Acme at $100 and Cobalt
// at $120, each 20% volatility, every pair of shocks correlated 0.5, watched
// at 0.25, 0.5 and 1 year.  Build: rustc --edition 2021 -O this_file.rs
use std::f64::consts::PI;

const RHO: f64 = 0.5; const SIG: f64 = 0.20; const RATE: f64 = 0.05;
const PATHS: usize = 6000; const SEED: u64 = 20260914;
const SPOTS: [f64; 3] = [80.0, 100.0, 120.0]; const INCOME: [f64; 3] = [0.01, 0.02, 0.03];
const TIMES: [f64; 3] = [0.25, 0.5, 1.0]; const STEPS: [f64; 3] = [0.25, 0.25, 0.5];
const RHOS: [f64; 4] = [-0.25, 0.0, 0.5, 0.75];
const DIALS: [f64; 7] = [-0.5, -0.25, 0.0, 0.25, 0.5, 0.75, 1.0];
const PAIRS: [(usize, usize); 3] = [(0, 1), (0, 2), (1, 2)];

fn equi(rho: f64) -> Vec<Vec<f64>> {              // one correlation for every pair of shares
    (0..3).map(|i| (0..3).map(|j| if i == j { 1.0 } else { rho }).collect()).collect()
}
fn dot(x: &[f64], y: &[f64]) -> f64 { x.iter().zip(y).map(|(p, q)| p * q).sum() }
fn gram(m: &[Vec<f64>]) -> Vec<Vec<f64>> {        // row lengths squared down the diagonal, row dot products off it
    m.iter().map(|r| m.iter().map(|s| dot(r, s)).collect()).collect()
}
fn worst(m: &[Vec<f64>], t: &[Vec<f64>]) -> f64 {
    (0..m.len()).map(|i| (0..m[0].len()).map(|j| (m[i][j] - t[i][j]).abs()).fold(0.0, f64::max)).fold(0.0, f64::max)
}
fn quad(a: &[Vec<f64>], x: &[f64; 3]) -> f64 {    // the variance of a portfolio x
    (0..3).map(|i| (0..3).map(|j| x[i] * a[i][j] * x[j]).sum::<f64>()).sum()
}
fn chol(a: &[Vec<f64>]) -> (Option<Vec<Vec<f64>>>, f64) {      // the factor, one column at a time
    let n = a.len();
    let mut low = vec![vec![0.0_f64; n]; n];
    for j in 0..n {
        let pivot = a[j][j] - (0..j).map(|k| low[j][k] * low[j][k]).sum::<f64>();
        if pivot <= 0.0 { return (None, pivot); }               // no factor with a positive diagonal exists
        low[j][j] = pivot.sqrt();
        for i in j + 1..n { low[i][j] = (a[i][j] - (0..j).map(|k| low[i][k] * low[j][k]).sum::<f64>()) / low[j][j]; }
    }
    (Some(low), 0.0)
}
fn spread(col: &[f64]) -> f64 {                   // standard deviation of one column of numbers
    let mean = col.iter().sum::<f64>() / col.len() as f64;
    (col.iter().map(|v| (v - mean) * (v - mean)).sum::<f64>() / col.len() as f64).sqrt()
}
fn link(xs: &[f64], ys: &[f64]) -> f64 {          // sample correlation of two columns
    let mx = xs.iter().sum::<f64>() / xs.len() as f64;
    let my = ys.iter().sum::<f64>() / ys.len() as f64;
    let top: f64 = xs.iter().zip(ys).map(|(x, y)| (x - mx) * (y - my)).sum();
    let sxx: f64 = xs.iter().map(|x| (x - mx) * (x - mx)).sum();
    let syy: f64 = ys.iter().map(|y| (y - my) * (y - my)).sum();
    top / (sxx * syy).sqrt()
}
fn draws(count: usize, seed: u64) -> Vec<f64> {   // uniforms from a counter, paired into normals
    let (mut out, mut state) = (Vec::new(), seed);
    while out.len() < count {
        state = (1664525 * state + 1013904223) % 4294967296;
        let u = (state as f64 + 0.5) / 4294967296.0;
        state = (1664525 * state + 1013904223) % 4294967296;
        let v = (state as f64 + 0.5) / 4294967296.0;
        let (radius, angle) = ((-2.0 * u.ln()).sqrt(), 2.0 * PI * v);
        out.push(radius * angle.cos()); out.push(radius * angle.sin());
    }
    out
}
type Walk = (Vec<Vec<Vec<f64>>>, Vec<Vec<f64>>, f64, usize);
fn walk(mixer: &[Vec<f64>], normals: &[f64]) -> Walk {          // every path: mix, accumulate, then price
    let mut shock = vec![vec![vec![0.0_f64; PATHS]; 3]; 3];     // [date][share][path]
    let (mut ret, mut gap, mut ledger) = (vec![vec![0.0_f64; PATHS]; 3], 0.0_f64, 0);
    for p in 0..PATHS {
        let (mut w, mut stock) = ([0.0_f64; 3], SPOTS);
        for k in 0..3 {
            let z = &normals[9 * p + 3 * k..9 * p + 3 * k + 3];
            for i in 0..3 {
                let dw = STEPS[k].sqrt() * dot(&mixer[i], z);
                w[i] += dw;
                let drift = RATE - INCOME[i] - 0.5 * SIG * SIG;
                stock[i] *= (drift * STEPS[k] + SIG * dw).exp();                 // road one: step by step
                let direct = SPOTS[i] * (drift * TIMES[k] + SIG * w[i]).exp();   // road two: one exponential
                gap = gap.max((stock[i] / direct - 1.0).abs());
                ledger += 1;
                shock[k][i][p] = w[i];
            }
        }
        for i in 0..3 { ret[i][p] = stock[i] / SPOTS[i] - 1.0; }
    }
    (shock, ret, gap, ledger)
}
fn row(label: &str, v: &[f64]) { println!("{:<47}{}", label, v.iter().map(|x| format!("{:>12.6}", x)).collect::<String>()); }
fn tiny(label: &str, value: f64) { println!("{:<47}{:>16.12}", label, value); }
fn chart(label: &str, v: &[f64]) { println!("{:<47}{}", label, v.iter().map(|x| format!("{:>8.2}", x)).collect::<String>()); }

fn main() {
    let low = chol(&equi(RHO)).0.unwrap();
    let hand = vec![vec![1.0, 0.0, 0.0], vec![0.5, 3.0_f64.sqrt() / 2.0, 0.0],
                    vec![0.5, 1.0 / (2.0 * 3.0_f64.sqrt()), (2.0 / 3.0_f64).sqrt()]];
    let one: Vec<Vec<f64>> = (0..3).map(|i| (0..4).map(|j|             // one shared shock plus one of its own
        if j == 0 { RHO.sqrt() } else if j == i + 1 { (1.0 - RHO).sqrt() } else { 0.0 }).collect()).collect();
    let side: Vec<Vec<f64>> = (0..3).map(|i| (0..3).map(|j| low[j][i]).collect()).collect();
    let bad = vec![vec![1.0, 0.9, 0.9], vec![0.9, 1.0, -0.9], vec![0.9, -0.9, 1.0]];
    let (bad_low, bad_pivot) = chol(&bad);        // correlations that cannot happen
    let (mut entries, mut off_grid) = (0, 0.0_f64);
    for rho in RHOS {                             // the clock, by exact coefficient algebra
        let matrix = equi(rho);
        let lo = chol(&matrix).0.unwrap();
        let mut coef: Vec<Vec<f64>> = Vec::new();
        for a in 0..3 { for i in 0..3 {
            let mut c = Vec::new();
            for k in 0..3 { for j in 0..3 { c.push(if k <= a { STEPS[k].sqrt() * lo[i][j] } else { 0.0 }); } }
            coef.push(c);
        }}
        for a in 0..3 { for b in 0..3 { for i in 0..3 { for j in 0..3 {
            let want = matrix[i][j] * TIMES[a].min(TIMES[b]);
            off_grid = off_grid.max((dot(&coef[3 * a + i], &coef[3 * b + j]) - want).abs());
            entries += 1;
        }}}}
    }
    let (shock, ret, gap, ledger) = walk(&low, &draws(9 * PATHS, SEED));
    let basket: Vec<f64> = (0..PATHS).map(|p| (shock[2][0][p] + shock[2][1][p] + shock[2][2][p]) / 3.0).collect();
    let model = ((RHO * SIG * SIG).exp() - 1.0) / ((SIG * SIG).exp() - 1.0);
    let fat = ((RHO * 0.36).exp() - 1.0) / (0.36_f64.exp() - 1.0);
    let theory: Vec<f64> = DIALS.iter().map(|d| 100.0 * SIG * ((1.0 + 2.0 * d) / 3.0).sqrt()).collect();
    let (raw, sideways) = (gram(&equi(RHO)), gram(&side));
    let wide: Vec<Vec<f64>> = low.iter().map(|r| [r.clone(), vec![0.0]].concat()).collect();

    row("correlation asked for, every pair", &[RHO]);
    for i in 0..3 { row(&format!("L row {}", i + 1), &low[i]); }
    row("length of each L row", &(0..3).map(|i| dot(&low[i], &low[i]).sqrt()).collect::<Vec<f64>>());
    tiny("hand-written factor, worst entry off L", worst(&low, &hand));
    tiny("L L^T rebuilt, worst entry off R", worst(&gram(&low), &equi(RHO)));
    row("one-factor mixer row 1", &one[0]);
    tiny("one-factor mixer, worst entry off R", worst(&gram(&one), &equi(RHO)));
    tiny("the two mixers differ, worst entry", worst(&one, &wide));
    println!("grid covariance entries checked                 {}", entries);
    tiny("grid covariance, worst gap off rho x min(ta,tb)", off_grid);
    println!("paths {}, normal draws {}, seed {}", PATHS, 9 * PATHS, SEED);
    println!("stock ledger comparisons                       {}", ledger);
    tiny("stepwise price vs one exponential, worst gap", gap);
    row("sample sd of Borex shock at 0.25, 0.5, 1 year", &(0..3).map(|k| spread(&shock[k][0])).collect::<Vec<f64>>());
    row("sqrt of the time elapsed, same three dates", &TIMES.iter().map(|t| t.sqrt()).collect::<Vec<f64>>());
    row("sample sd of each shock at 1 year", &(0..3).map(|i| spread(&shock[2][i])).collect::<Vec<f64>>());
    row("sample shock correlation, pairs 1-2, 1-3, 2-3", &PAIRS.map(|(i, j)| link(&shock[2][i], &shock[2][j])));
    row("sample percent-return correlation, same pairs", &PAIRS.map(|(i, j)| link(&ret[i], &ret[j])));
    row("model percent-return correlation at 1 year", &[model]);
    tiny("the same value written 1/(1 + e^0.02), gap", (model - 1.0 / (1.0 + (RHO * SIG * SIG).exp())).abs());
    row("model percent-return correlation at 60% vol", &[fat]);
    row("three-share average sd at 1 year, percent", &[100.0 * SIG * spread(&basket), theory[4]]);
    chart("chart, correlation dial", &DIALS);
    chart("chart, three-share average sd, percent", &theory);
    chart("chart, one share alone, percent", &[100.0 * SIG; 7]);
    row("wrong: R as the mixer: variance, sd, corr 1-2", &[raw[0][0], raw[0][0].sqrt(), raw[0][1] / raw[0][0]]);
    row("wrong: L on its side: three variances", &(0..3).map(|i| sideways[i][i]).collect::<Vec<f64>>());
    row("wrong: L on its side: correlation 1-2", &[sideways[0][1] / (sideways[0][0] * sideways[1][1]).sqrt()]);
    println!("wrong: impossible dial has no factor           {}", if bad_low.is_none() { "yes" } else { "no" });
    row("wrong: impossible dial: third pivot, (1,-1,-1)", &[bad_pivot, quad(&bad, &[1.0, -1.0, -1.0])]);

    assert!(worst(&low, &hand) < 1e-15, "the recurrence must land on the hand-written factor");
    assert!(worst(&gram(&low), &equi(RHO)) < 1e-15, "L L^T must rebuild R");
    assert!(worst(&gram(&one), &equi(RHO)) < 1e-15, "the one-factor mixer must rebuild R as well");
    assert!(worst(&one, &wide) > 0.1, "two mixers rebuild one R: only the triangular one with a positive diagonal is unique");
    assert!(off_grid < 1e-12, "grid covariance must equal rho times the earlier date");
    assert!(bad_low.is_none(), "the impossible dial must break the factor");
    assert!(quad(&bad, &[1.0, -1.0, -1.0]) < 0.0, "and hold a portfolio of negative variance");
    assert!(gap < 1e-12, "stepping the price must match one exponential");
    assert!((0..3).all(|k| (spread(&shock[k][0]) - TIMES[k].sqrt()).abs() < 0.05), "spread grows as sqrt of time");
    assert!(PAIRS.iter().all(|(i, j)| (link(&shock[2][*i], &shock[2][*j]) - RHO).abs() < 0.03), "sample shocks near the dial");
    assert!(PAIRS.iter().all(|(i, j)| (link(&ret[*i], &ret[*j]) - model).abs() < 0.03), "sample returns near the model");
    assert!((model - 1.0 / (1.0 + (RHO * SIG * SIG).exp())).abs() < 1e-12, "two roads to the model correlation");
    assert!((100.0 * SIG * spread(&basket) - theory[4]).abs() < 1.0, "average-share spread, sample against theory");
    println!("ALL CHECKS PASS");
}
