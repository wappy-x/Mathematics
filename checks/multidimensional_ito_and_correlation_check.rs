// Several Brownian motions -- the same check as multidimensional_ito_and_correlation_check.py.
// Standard library only, no crates.  Same generator, same seed, same order of draws,
// same plain left-to-right additions, so the output matches line for line.
// Compile: rustc --edition 2021 -O multidimensional_ito_and_correlation_check.rs -o /tmp/chk
use std::f64::consts::PI;

const A0: f64 = 100.0; const MU1: f64 = 0.08; const S1: f64 = 0.20;
const B0: f64 = 50.0; const MU2: f64 = 0.05; const S2: f64 = 0.30;
const RHO: f64 = 0.5; const T: f64 = 1.0;

struct Rng { s: u64 }
impl Rng {
    fn uniform(&mut self) -> f64 {                     // SplitMix64, top 53 bits
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 {                      // Box-Muller, cosine half only
        let u1 = 1.0 - self.uniform();
        let u2 = self.uniform();
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}

fn prices(t: f64, w1: f64, w2: f64) -> (f64, f64) {   // each share's exact solution
    (A0 * ((MU1 - 0.5 * S1 * S1) * t + S1 * w1).exp(), B0 * ((MU2 - 0.5 * S2 * S2) * t + S2 * w2).exp())
}

fn mean_se(xs: &[f64]) -> (f64, f64) {
    let mut m = 0.0;
    for x in xs { m += x; }
    m /= xs.len() as f64;
    let mut v = 0.0;
    for x in xs { v += (x - m) * (x - m); }
    (m, (v / (xs.len() - 1) as f64 / xs.len() as f64).sqrt())
}

fn ncdf(x: f64) -> f64 {                               // bell-curve area left of x: Simpson from 0 to x
    let (n, h) = (2000usize, x / 2000.0);
    let mut s = 0.0;
    for k in 0..=n {
        let wgt = if k == 0 || k == n { 1.0 } else if k % 2 == 1 { 4.0 } else { 2.0 };
        s += wgt * (-0.5 * (k as f64 * h) * (k as f64 * h)).exp();
    }
    0.5 + s * h / 3.0 / (2.0 * PI).sqrt()
}

fn row(label: &str, v: f64) { println!("{:<44}{:>12.6}", label, v); }
fn row_se(label: &str, m: (f64, f64)) { println!("{:<44}{:>12.6}  se {:.6}", label, m.0, m.1); }
fn join(v: &[f64]) -> String { v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(" ") }

fn main() {
    let mut rng = Rng { s: 20260930 };
    let c22 = (1.0 - RHO * RHO).sqrt();                // Cholesky factor: rows (1, 0), (RHO, c22)
    println!("A  formulas");
    let g = MU1 + MU2 + RHO * S1 * S2;                 // drift of the product, cross term included
    let vp = (S1 * S1 + S2 * S2 + 2.0 * RHO * S1 * S2).sqrt();
    let (ep, ep_ind) = (A0 * B0 * (g * T).exp(), A0 * B0 * ((MU1 + MU2) * T).exp());
    let er = A0 / B0 * ((MU1 - MU2 + S2 * S2 - RHO * S1 * S2) * T).exp();
    let pbelow = ncdf(-(g - 0.5 * vp * vp) * T.sqrt() / vp);
    row("Cholesky entry under the diagonal", RHO); row("Cholesky diagonal entry sqrt(1 - rho^2)", c22);
    row("drift of P = AB, with cross term", g); row("volatility of P", vp);
    row("E[P_1], multidimensional Ito", ep); row("E[P_1], cross term dropped = E[A_1]E[B_1]", ep_ind);
    row("Cov(A_1, B_1) = difference", ep - ep_ind); row("median P_1", A0 * B0 * ((g - 0.5 * vp * vp) * T).exp());
    row("P(P_1 < 5000)", pbelow); row("E[A_1 / B_1], ratio drift 0.09", er);
    row("E[W1_1 W2_1]: Ito rho T; ordinary rule 0", RHO * T); row("yearly price correlation Corr(A_1, B_1)", ((RHO * S1 * S2 * T).exp() - 1.0) / (((S1 * S1 * T).exp() - 1.0) * ((S2 * S2 * T).exp() - 1.0)).sqrt());
    let vw = RHO * RHO + (1.0 - RHO) * (1.0 - RHO);    // wrong mix: weights RHO and 1 - RHO
    row("wrong mix rho, 1 - rho: variance of W2", vw); row("wrong mix: correlation it delivers", RHO / vw.sqrt());
    println!("hand: rho s1 s2 {:.4}, mu1 + mu2 {:.4}, var of P {:.4}, log drift {:.4}, z {:.6}; try rho -0.5: {:.4}", RHO * S1 * S2,
        MU1 + MU2, vp * vp, g - 0.5 * vp * vp, -(g - 0.5 * vp * vp) / vp, A0 * B0 * ((MU1 + MU2 - 0.5 * S1 * S2) * T).exp());
    println!("figure, origin 60 200, Z1 tip 210 200, W2 tip {:.2} {:.2}", 60.0 + 150.0 * RHO, 200.0 - 150.0 * c22);

    let (h, dn) = (0.04, 2.0 * PI * c22);              // B: midpoint rule on [-8, 8]^2
    let (mut qp, mut qr, mut qxy) = (0.0f64, 0.0f64, 0.0f64);
    for i in 0..400 {
        let x = -8.0 + (i as f64 + 0.5) * h;
        for j in 0..400 {
            let y = -8.0 + (j as f64 + 0.5) * h;
            let wt = (-(x * x - 2.0 * RHO * x * y + y * y) / (2.0 * c22 * c22)).exp() / dn * h * h;
            let (a, b) = prices(T, T.sqrt() * x, T.sqrt() * y);
            qp += a * b * wt; qr += a / b * wt; qxy += x * y * wt;
        }
    }
    println!("B  integral against the joint bell curve, 400 x 400 cells");
    row("E[P_1]", qp); row("E[A_1 / B_1]", qr); row("E[W1_1 W2_1]", qxy);

    const NF: usize = 4096;
    let dt = T / NF as f64;
    let (mut f1, mut f2, mut fw, mut cr) = (Vec::new(), Vec::new(), Vec::new(), Vec::new());
    for _ in 0..NF {
        let (z1, z2) = (rng.normal(), rng.normal());
        f1.push(dt.sqrt() * z1); f2.push(dt.sqrt() * (RHO * z1 + c22 * z2));
        fw.push(dt.sqrt() * (RHO * z1 + (1.0 - RHO) * z2));
    }
    println!("C  one path: steps, sum dW1 dW2, its predicted sd, sum (dW2 wrong mix)^2");
    for n in [16usize, 64, 256, 1024, 4096] {
        let (m, mut c, mut q) = (NF / n, 0.0f64, 0.0f64);
        for k in 0..n {
            let (mut d1, mut d2, mut dw) = (0.0f64, 0.0f64, 0.0f64);
            for j in k * m..(k + 1) * m { d1 += f1[j]; d2 += f2[j]; dw += fw[j]; }
            c += d1 * d2; q += dw * dw;
        }
        cr.push((c, q));
        println!("   n {:>5}   {:>9.6}   {:.6}   {:.6}", n, c, ((1.0 + RHO * RHO) * T / n as f64).sqrt(), q);
    }

    const NP: usize = 20000;
    let (mut pv, mut rv, mut xy, mut bl) = (Vec::new(), Vec::new(), Vec::new(), Vec::new());
    let (mut w1s, mut wws, mut path) = (Vec::new(), Vec::new(), Vec::new());
    for i in 0..NP {
        let (mut w1, mut w2, mut ww) = (0.0f64, 0.0f64, 0.0f64);
        for j in 0..12 {                               // monthly steps
            let (z1, z2) = (rng.normal(), rng.normal());
            w1 += (T / 12.0).sqrt() * z1; w2 += (T / 12.0).sqrt() * (RHO * z1 + c22 * z2);
            ww += (T / 12.0).sqrt() * (RHO * z1 + (1.0 - RHO) * z2);
            if i == 0 { path.push(prices((j + 1) as f64 * T / 12.0, w1, w2)); }
        }
        let (a, b) = prices(T, w1, w2);
        pv.push(a * b); rv.push(a / b); xy.push(w1 * w2); bl.push(if a * b < A0 * B0 { 1.0 } else { 0.0 });
        w1s.push(w1); wws.push(ww);
    }
    let (mp, mr, mxy, mbl) = (mean_se(&pv), mean_se(&rv), mean_se(&xy), mean_se(&bl));
    let mww = mean_se(&wws.iter().map(|x| x * x).collect::<Vec<f64>>());
    let mwx = mean_se(&(0..NP).map(|i| w1s[i] * wws[i]).collect::<Vec<f64>>());
    println!("D  20000 paths, monthly steps");
    row_se("E[P_1]", mp); row_se("E[A_1 / B_1]", mr); row_se("E[W1_1 W2_1]", mxy);
    row_se("P(P_1 < 5000)", mbl);
    row_se("wrong mix: E[W2_1^2]", mww); row_se("wrong mix: E[W1_1 W2_1]", mwx);
    let pa: Vec<f64> = std::iter::once(A0).chain(path.iter().map(|p| p.0)).collect();
    let pb: Vec<f64> = std::iter::once(B0).chain(path.iter().map(|p| p.1)).collect();
    println!("chart, path A {}", join(&pa));
    println!("chart, path B {}", join(&pb));

    let ns = [16usize, 64, 256, 1024, 4096];
    let (mut ew, mut eo) = ([0.0f64; 5], [0.0f64; 5]);
    for _ in 0..200 {
        let (mut g1, mut g2) = (vec![0.0f64], vec![0.0f64]);
        for k in 0..NF {
            let (z1, z2) = (rng.normal(), rng.normal());
            let (n1, n2) = (g1[k] + dt.sqrt() * z1, g2[k] + dt.sqrt() * (RHO * z1 + c22 * z2));
            g1.push(n1); g2.push(n2);
        }
        let (a, b) = prices(T, g1[NF], g2[NF]);
        for (s, &n) in ns.iter().enumerate() {
            let (m, mut pw, mut po) = (NF / n, A0 * B0, A0 * B0);
            for k in 0..n {
                let (d1, d2) = (g1[(k + 1) * m] - g1[k * m], g2[(k + 1) * m] - g2[k * m]);
                pw += pw * (g * T / n as f64 + S1 * d1 + S2 * d2);
                po += po * ((MU1 + MU2) * T / n as f64 + S1 * d1 + S2 * d2);
            }
            ew[s] += (pw - a * b).abs() / 200.0; eo[s] += (po - a * b).abs() / 200.0;
        }
    }
    println!("E  200 paths: mean |error| of Euler P_1; steps, with cross term, without");
    for (s, n) in ns.iter().enumerate() { println!("   n {:>5}   {:9.2}   {:9.2}", n, ew[s], eo[s]); }

    assert!((qp - ep).abs() < 1e-6 * ep && (qr - er).abs() < 1e-6 * er, "integral agrees with Ito's drifts");
    assert!((qxy - RHO * T).abs() < 1e-6, "joint bell curve has covariance rho T");
    assert!((mp.0 - ep).abs() < 4.0 * mp.1, "simulated E[P_1] matches the cross-term formula");
    assert!((mp.0 - ep_ind).abs() > 4.0 * mp.1, "and rules out the formula without it");
    assert!((mr.0 - er).abs() < 4.0 * mr.1, "ratio drift includes s2^2 - rho s1 s2");
    assert!((mxy.0 - RHO * T).abs() < 4.0 * mxy.1, "E[W1 W2] = rho T, not 0");
    assert!((mbl.0 - pbelow).abs() < 4.0 * mbl.1, "chance of ending below 5000");
    assert!((cr[4].0 - RHO * T).abs() < 4.0 * ((1.0 + RHO * RHO) * T / NF as f64).sqrt(), "cross sum tends to rho T");
    assert!((mww.0 - 0.5).abs() < 4.0 * mww.1, "wrong mix: W2 has variance 0.5, not 1");
    assert!(ew[4] < ew[0] / 4.0 && (eo[4] - (ep - ep_ind)).abs() < 0.1 * (ep - ep_ind), "Euler needs the cross term");
    println!("ALL CHECKS PASS");
}
