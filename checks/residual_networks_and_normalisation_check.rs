// Residual connections and normalisation -- the same check as the Python, in Rust.  std only.
// A synthetic 50-layer, 4-wide network: each plain layer turns its input (a random rotation,
// SplitMix64 seed 2026) and scales it by 0.9.  Three roads to the gradient that reaches layer 0:
// the closed form 0.9^50, backpropagation through the layers, and a central difference.
// Compile: rustc --edition 2021 -O residual_networks_and_normalisation_check.rs -o /tmp/resnorm
use std::f64::consts::PI;

const D: usize = 4;
const L: usize = 50;
type M = [[f64; D]; D];

fn splitmix(state: u64) -> (u64, f64) {      // returns (new state, uniform in [0, 1))
    let s = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = s;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0)
}

fn rotations(seed: u64) -> Vec<M> {          // 50 random 4-by-4 rotations, four plane turns each
    let (mut out, mut s) = (Vec::new(), seed);
    for _ in 0..L {
        let mut a = [[0.0; D]; D];
        for i in 0..D { a[i][i] = 1.0; }
        for (i, j) in [(0, 1), (2, 3), (0, 2), (1, 3)] {
            let (s2, u) = splitmix(s); s = s2;
            let (c, t) = ((2.0 * PI * u).cos(), (2.0 * PI * u).sin());
            for r in a.iter_mut() { let (ri, rj) = (r[i], r[j]); r[i] = c * ri - t * rj; r[j] = t * ri + c * rj; }
        }
        out.push(a);
    }
    out
}
fn mv(a: &M, x: &[f64]) -> Vec<f64> { (0..D).map(|i| (0..D).map(|j| a[i][j] * x[j]).sum()).collect() }
fn mtv(a: &M, x: &[f64]) -> Vec<f64> { (0..D).map(|i| (0..D).map(|j| a[j][i] * x[j]).sum()).collect() }
fn norm(v: &[f64]) -> f64 { v.iter().map(|t| t * t).sum::<f64>().sqrt() }

// a = 0: plain layer h = s Q h; else h = h + a tanh(s Q h)
fn forward(q: &[M], x: &[f64], s: f64, a: f64) -> Vec<Vec<f64>> {
    let mut hs = vec![x.to_vec()];
    let mut x = x.to_vec();
    for l in 0..L {
        let z: Vec<f64> = mv(&q[l], &x).iter().map(|t| s * t).collect();
        x = if a == 0.0 { z } else { (0..D).map(|i| x[i] + a * z[i].tanh()).collect() };
        hs.push(x.clone());
    }
    hs
}

// loss = first entry of h_50, so its gradient is (1, 0, 0, 0)
fn backward(q: &[M], x: &[f64], s: f64, a: f64) -> (Vec<f64>, Vec<f64>) {
    let hs = forward(q, x, s, a);
    let (mut g, mut sizes) = (vec![1.0, 0.0, 0.0, 0.0], vec![1.0]);
    for l in (0..L).rev() {
        if a == 0.0 { g = mtv(&q[l], &g).iter().map(|t| s * t).collect(); } else {
            let z: Vec<f64> = mv(&q[l], &hs[l]).iter().map(|t| s * t).collect();
            let inner: Vec<f64> = (0..D).map(|i| a * (1.0 - z[i].tanh().powi(2)) * g[i] * s).collect();
            let side = mtv(&q[l], &inner);
            g = (0..D).map(|i| g[i] + side[i]).collect();   // identity path plus side branch
        }
        sizes.push(norm(&g));
    }
    (g, sizes)
}

fn central(q: &[M], x: &[f64], s: f64, a: f64) -> Vec<f64> {
    let e = 1e-6;
    (0..D).map(|i| {
        let (mut up, mut dn) = (x.to_vec(), x.to_vec()); up[i] += e; dn[i] -= e;
        (forward(q, &up, s, a)[L][0] - forward(q, &dn, s, a)[L][0]) / (2.0 * e)
    }).collect()
}

fn row(label: &str, vals: &[f64]) {
    let mut out = format!("{:<42}", label);
    for v in vals { out += &format!("{:>11.6}", v + 0.0); }
    println!("{}", out);
}

fn layer_norm(x: &[f64], eps: f64, n_minus_1: bool) -> (Vec<f64>, f64, f64) {
    let d = x.len() as f64;
    let mu = x.iter().sum::<f64>() / d;
    let var = x.iter().map(|t| (t - mu).powi(2)).sum::<f64>() / if n_minus_1 { d - 1.0 } else { d };
    (x.iter().map(|t| (t - mu) / (var + eps).sqrt()).collect(), mu, var)
}

fn batch_norm(batch: &[Vec<f64>], eps: f64) -> Vec<Vec<f64>> {   // each feature normalised over the batch
    let cols: Vec<Vec<f64>> = (0..batch[0].len())
        .map(|f| layer_norm(&batch.iter().map(|ex| ex[f]).collect::<Vec<f64>>(), eps, false).0).collect();
    (0..batch.len()).map(|b| (0..cols.len()).map(|f| cols[f][b]).collect()).collect()
}

fn main() {
    let q = rotations(2026);
    let x0 = [0.1, 0.2, 0.3, 0.4];
    row("chain: 0.9^50, 1.1^50", &[0.9f64.powf(50.0), 1.1f64.powf(50.0)]);
    row("chain: 50 ln 0.9, exp of it", &[50.0 * 0.9f64.ln(), 2.718281828459045f64.powf(50.0 * 0.9f64.ln())]);
    let mut res = Vec::new();
    for (name, s, a) in [("plain 0.9", 0.9, 0.0), ("residual a=0.1", 0.9, 0.1), ("plain 1.1", 1.1, 0.0), ("residual a=1", 0.9, 1.0)] {
        let (g, sizes) = backward(&q, &x0, s, a);
        let cd = central(&q, &x0, s, a);
        row(&format!("{}: backprop |g0|, central |g0|", name), &[norm(&g), norm(&cd)]);
        res.push((g, cd, sizes));
    }
    row("residual a=0.1: bounds 0.91^50, 1.09^50", &[0.91f64.powf(50.0), 1.09f64.powf(50.0)]);
    println!("chart, layers back: plain 0.9 | residual a=0.1");
    for k in (0..=L).step_by(5) { row(&format!("  {} layers back", k), &[res[0].2[k], res[1].2[k]]); }

    let x = vec![1.0, 2.0, 3.0, 4.0];
    let (y, mu, var) = layer_norm(&x, 0.0, false);
    row("layer norm: mean, variance, sd", &[mu, var, var.sqrt()]);
    row("layer norm of (1, 2, 3, 4)", &y);
    row("  with eps = 1e-5", &layer_norm(&x, 1e-5, false).0);
    row("  output mean, output variance", &[y.iter().sum::<f64>() / 4.0, y.iter().map(|t| t * t).sum::<f64>() / 4.0]);
    let big: Vec<f64> = x.iter().map(|t| 117.390853 * t).collect();
    let (ybig, _, varbig) = layer_norm(&big, 0.0, false);
    row("layer norm of 117.39 x (1, 2, 3, 4)", &ybig);
    let delta = |i: usize, j: usize| if i == j { 1.0 } else { 0.0 };
    let j0: Vec<f64> = (0..D).map(|j| (delta(0, j) - 0.25 - y[0] * y[j] / 4.0) / var.sqrt()).collect();
    let jcd: Vec<f64> = (0..D).map(|k| {
        let (mut up, mut dn) = (x.clone(), x.clone()); up[k] += 1e-6; dn[k] -= 1e-6;
        (layer_norm(&up, 0.0, false).0[0] - layer_norm(&dn, 0.0, false).0[0]) / 2e-6
    }).collect();
    row("LN slopes of y1: formula", &j0);
    row("LN slopes of y1: central difference", &jcd);
    let jbig: Vec<f64> = (0..D).map(|j| (delta(0, j) - 0.25 - y[0] * y[j] / 4.0) / varbig.sqrt()).collect();
    row("LN slopes of y1, input x 117.39", &jbig);
    let frac = norm(&j0) / norm(&x) / (norm(&jbig) / norm(&big));   // a step's size over the input's size, scale 1 over scale 117.39
    row("  step fraction ratio, 1 vs 117.39", &[frac]);
    let batch = vec![vec![1.0, 2.0, 3.0, 4.0], vec![2.0, 4.0, 6.0, 8.0], vec![3.0, 0.0, 3.0, 0.0]];
    let bn = batch_norm(&batch, 0.0);
    row("batch norm, image A in batch A B C", &bn[0]);
    let batch2 = vec![batch[0].clone(), batch[1].clone(), vec![9.0; 4]];
    let bn2 = batch_norm(&batch2, 0.0);
    row("batch norm, image A, C now (9,9,9,9)", &bn2[0]);
    row("layer norm, image B = 2 x image A", &layer_norm(&batch[1], 0.0, false).0);
    let one = batch_norm(&[x.clone()], 1e-5);
    row("wrong: batch norm, batch of one", &one[0]);
    let wrong = layer_norm(&x, 0.0, true).0;
    let wrong_var = wrong.iter().map(|t| t * t).sum::<f64>() / 4.0;
    row("wrong: divide by d - 1", &wrong);
    row("  its output variance", &[wrong_var]);
    row("flat (5,5,5,5) with eps = 1e-5", &layer_norm(&[5.0; 4], 1e-5, false).0);
    println!("flat (5,5,5,5) with eps = 0: variance 0, division by zero");

    let (gp, gr) = (&res[0].0, &res[1].0);
    assert!((norm(gp) - 0.9f64.powf(50.0)).abs() < 1e-12, "plain net: backprop against the closed form 0.9^50");
    assert!((norm(&res[2].0) - 1.1f64.powf(50.0)).abs() < 1e-9, "plain net, 1.1: closed form 1.1^50");
    for (g, cd, _) in &res {
        let worst = (0..D).map(|i| (g[i] - cd[i]).abs()).fold(0.0, f64::max);
        assert!(worst < 1e-6 * norm(g).max(1.0), "backprop vs central");
    }
    let nr = norm(gr);
    assert!(nr > 0.5 && nr < 2.0 && nr > 0.91f64.powf(50.0) && nr < 1.09f64.powf(50.0), "residual gradient stays near 1");
    assert!(norm(&res[3].0) > 10.0, "a full-size side branch explodes");
    let exact = [-3.0 / 5f64.sqrt(), -1.0 / 5f64.sqrt(), 1.0 / 5f64.sqrt(), 3.0 / 5f64.sqrt()];
    assert!((0..D).all(|i| (y[i] - exact[i]).abs() < 1e-12), "LN against the hand values");
    assert!(y.iter().sum::<f64>().abs() < 1e-12 && (y.iter().map(|t| t * t).sum::<f64>() / 4.0 - 1.0).abs() < 1e-12, "LN output: mean 0, variance 1");
    assert!((0..D).all(|k| (j0[k] - jcd[k]).abs() < 1e-8), "LN Jacobian formula vs central difference");
    assert!((0..D).all(|i| (ybig[i] - y[i]).abs() < 1e-12), "LN ignores overall scale");
    assert!((0..D).all(|k| (jbig[k] - j0[k] / 117.390853).abs() < 1e-12), "slopes shrink by the scale");
    assert!((frac - 117.390853f64.powi(2)).abs() < 1e-6, "a step's fraction shrinks by the scale squared");
    let hand = [-(1.5f64).sqrt(), 0.0, -1.0 / 2f64.sqrt(), 0.0];
    assert!((0..D).all(|i| (bn[0][i] - hand[i]).abs() < 1e-12), "batch norm by hand");
    assert!((0..D).all(|i| (bn2[0][i] + 3.0 / ((9.0 + (i as f64 - 2.0).powi(2) + (5.0 - i as f64).powi(2)) / 3.0).sqrt()).abs() < 1e-12), "C changed, by hand");
    assert!(one[0].iter().all(|&t| t == 0.0), "batch of one: every output is 0");
    assert!((wrong_var - 0.75).abs() < 1e-12, "n - 1 spread gives variance (d-1)/d");
    println!("ALL CHECKS PASS");
}
