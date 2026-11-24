// Generalised linear models -- the check behind the card.  std only, no crates.
// Help-desk emails per hour against staff on shift, fitted as a Poisson GLM with a log link.
// Roads: IRLS, a Newton step from the slope and curvature formulas, and a one-unknown root search;
// the deviance from its formula and from log-likelihoods; least squares as the same recipe.

fn irls(x: &[f64], y: &[f64], off: &[f64], b0: [f64; 2], steps: usize, poisson: bool) -> ([f64; 2], Vec<[f64; 2]>) {
    let mut b = b0;
    let mut trace = Vec::new();
    for _ in 0..steps {
        let (mut s0, mut s1, mut s2, mut t0, mut t1) = (0.0, 0.0, 0.0, 0.0, 0.0);
        for i in 0..x.len() {
            let eta = b[0] + b[1] * x[i] + off[i];
            // log link: mu = e^eta, weight mu, working response eta - offset + (y - mu)/mu;
            // normal family, identity link: weight 1, working response y
            let mu = if poisson { eta.exp() } else { 1.0 };
            let (w, z) = if poisson { (mu, eta - off[i] + (y[i] - mu) / mu) } else { (1.0, y[i]) };
            s0 += w; s1 += w * x[i]; s2 += w * x[i] * x[i]; t0 += w * z; t1 += w * x[i] * z;
        }
        let det = s0 * s2 - s1 * s1;
        b = [(s2 * t0 - s1 * t1) / det, (s0 * t1 - s1 * t0) / det];
        trace.push(b);
    }
    (b, trace)
}

fn means(x: &[f64], off: &[f64], b: [f64; 2]) -> Vec<f64> {
    x.iter().zip(off).map(|(xi, o)| (b[0] + b[1] * xi + o).exp()).collect()
}
fn deviance(y: &[f64], mu: &[f64]) -> f64 {
    2.0 * y.iter().zip(mu).map(|(yi, m)| (if *yi > 0.0 { yi * (yi / m).ln() } else { 0.0 }) - (yi - m)).sum::<f64>()
}
fn loglik(y: &[f64], mu: &[f64]) -> f64 {
    y.iter().zip(mu).map(|(yi, m)| {
        yi * m.ln() - m - (2..=(*yi as u64)).map(|k| (k as f64).ln()).sum::<f64>()
    }).sum()
}
fn phi(v: f64) -> f64 {
    // normal CDF from the Taylor series of erf
    let u = v / 2f64.sqrt();
    let (mut term, mut s) = (u, u);
    for n in 1..120 {
        term *= -u * u / n as f64;
        s += term / (2 * n + 1) as f64;
    }
    0.5 + s / std::f64::consts::PI.sqrt()
}
fn info_inv11(x: &[f64], mu: &[f64]) -> f64 {
    let s0: f64 = mu.iter().sum();
    let s1: f64 = mu.iter().zip(x).map(|(m, xi)| m * xi).sum();
    let s2: f64 = mu.iter().zip(x).map(|(m, xi)| m * xi * xi).sum();
    s0 / (s0 * s2 - s1 * s1)
}
fn f4(v: f64) -> String { format!("{:.4}", if v.abs() < 5e-5 { 0.0 } else { v }) }
fn j4(vs: &[f64]) -> String { vs.iter().map(|v| f4(*v)).collect::<Vec<_>>().join(" ") }
fn ints(vs: &[f64]) -> String { format!("{:?}", vs.iter().map(|v| *v as i64).collect::<Vec<_>>()) }

fn main() {
    let (x, y, n, zero) = ([1.0, 2.0, 3.0, 4.0], [14.0, 10.0, 7.0, 5.0], 4.0, [0.0; 4]);
    let ybar = y.iter().sum::<f64>() / n;
    let b_start = [ybar.ln(), 0.0];
    println!("data: staff {} emails {} | mean {} | start b0 = ln(mean) {}", ints(&x), ints(&y), f4(ybar), f4(b_start[0]));

    // ---- one IRLS step by hand: every mean is 9, every weight 9, so the step is plain least squares ----
    let zs: Vec<f64> = y.iter().map(|yi| b_start[0] + (yi - ybar) / ybar).collect();
    println!("step 1 working response z: {} | weights all {}", j4(&zs), f4(ybar));
    let sxz: f64 = (0..4).map(|i| (x[i] - 2.5) * (zs[i] - b_start[0])).sum();
    println!("  z - ln(mean): {} | mean staff 2.5000 | Sxz {} | Sxx 5.0000", j4(&y.map(|yi| (yi - ybar) / ybar)), f4(sxz));
    let (b1, _) = irls(&x, &y, &zero, b_start, 1, true);
    let hand_slope = x.iter().zip(&y).map(|(xi, yi)| (xi - 2.5) * (yi - ybar)).sum::<f64>() / ybar / 5.0;
    println!("after step 1: b0 {} b1 {} | by hand, Sxz/Sxx = {}", f4(b1[0]), f4(b1[1]), f4(hand_slope));
    assert!((b1[1] - hand_slope).abs() < 1e-12);

    // ---- road 1 and road 2: the same step as Newton's method on the log-likelihood ----
    let mu0 = means(&x, &zero, b_start);
    let (g0, g1): (f64, f64) = ((0..4).map(|i| y[i] - mu0[i]).sum(), (0..4).map(|i| x[i] * (y[i] - mu0[i])).sum());
    let (h00, h01): (f64, f64) = (mu0.iter().sum(), (0..4).map(|i| mu0[i] * x[i]).sum());
    let h11: f64 = (0..4).map(|i| mu0[i] * x[i] * x[i]).sum();
    let det = h00 * h11 - h01 * h01;
    let newton = [b_start[0] + (h11 * g0 - h01 * g1) / det, b_start[1] + (h00 * g1 - h01 * g0) / det];
    println!("Newton step from slopes {} {} -> {} {}", f4(g0), f4(g1), f4(newton[0]), f4(newton[1]));
    assert!((newton[0] - b1[0]).abs() < 1e-12 && (newton[1] - b1[1]).abs() < 1e-12);

    let (b, trace) = irls(&x, &y, &zero, b_start, 25, true);
    println!("IRLS slope b1 after steps 1-4: {}", trace[..4].iter().map(|t| format!("{:.10}", t[1])).collect::<Vec<_>>().join(" "));
    let mu = means(&x, &zero, b);
    println!("fit: b0 {} b1 {} | multiplier e^b1 {} | e^b0 {}", f4(b[0]), f4(b[1]), f4(b[1].exp()), f4(b[0].exp()));
    let (ysum, musum): (f64, f64) = (y.iter().sum(), mu.iter().sum());
    println!("fitted means: {} | sum {} observed {}", j4(&mu), f4(musum), ysum as i64);
    assert!((musum - ysum).abs() < 1e-9);

    // ---- road 3: the intercept equation solved exactly, then one unknown by bisection ----
    let slope_eq = |c: f64| -> f64 {
        let a = (ysum / x.iter().map(|xi| (c * xi).exp()).sum::<f64>()).ln();
        (0..4).map(|i| x[i] * (y[i] - (a + c * x[i]).exp())).sum()
    };
    let (mut lo, mut hi) = (-2.0, 2.0);
    for _ in 0..200 {
        let mid = (lo + hi) / 2.0; if slope_eq(mid) > 0.0 { lo = mid; } else { hi = mid; }
    }
    println!("bisection on the slope equation: b1 {:.10} | IRLS {:.10}", lo, b[1]);
    assert!((lo - b[1]).abs() < 1e-9);

    // ---- standard error, Wald interval ----
    let se = info_inv11(&x, &mu).sqrt();
    let zw = b[1] / se;
    println!("SE(b1) {} | z {} | two-sided p {}", f4(se), f4(zw), f4(2.0 * phi(zw)));
    println!("95% interval for the multiplier: {} to {}", f4((b[1] - 1.96 * se).exp()), f4((b[1] + 1.96 * se).exp()));
    let (lo_z, steps) = (-8.0, 4000usize);
    let h = (zw - lo_z) / steps as f64; // Simpson's rule on the bell curve, a second road to Phi
    let simpson: f64 = (0..=steps).map(|k| {
        let (c, t) = (if k == 0 || k == steps { 1.0 } else if k % 2 == 1 { 4.0 } else { 2.0 }, lo_z + k as f64 * h);
        c * (-t * t / 2.0).exp()
    }).sum::<f64>() * h / 3.0 / (2.0 * std::f64::consts::PI).sqrt();
    assert!((simpson - phi(zw)).abs() < 1e-4);
    // log-likelihood with the intercept set by its own equation: a second road to the SE
    let prof = |c: f64| -> f64 {
        let a = (ysum / x.iter().map(|xi| (c * xi).exp()).sum::<f64>()).ln();
        loglik(&y, &x.iter().map(|xi| (a + c * xi).exp()).collect::<Vec<f64>>())
    };
    let (dc, mid) = (1e-4, prof(b[1]));
    let curv = (prof(b[1] + dc) - 2.0 * mid + prof(b[1] - dc)) / (dc * dc);
    assert!((1.0 / (-curv).sqrt() - se).abs() < 1e-5);

    // ---- deviance, two roads ----
    let flat = [ybar; 4];
    let (d0, d) = (deviance(&y, &flat), deviance(&y, &mu));
    let drop = d0 - d;
    let lr = 2.0 * (loglik(&y, &mu) - loglik(&y, &flat));
    let p_drop = 2.0 * (1.0 - phi(drop.sqrt()));
    println!("null deviance {} on 3 df | residual deviance {} on 2 df", f4(d0), f4(d));
    println!("drop {} | 2 x log-likelihood gain {} | chi-square(1) p {}", f4(drop), f4(lr), f4(p_drop));
    println!("residual deviance chi-square(2) p {}", f4((-d / 2.0).exp()));
    assert!((drop - lr).abs() < 1e-9);
    let x2: f64 = (0..4).map(|i| (y[i] - mu[i]).powi(2) / mu[i]).sum();
    println!("Pearson X2 {:.6} | dispersion X2/(n-2) {:.6}", x2, x2 / 2.0);

    // ---- prediction, and the same recipe as least squares ----
    println!("Poisson prediction at 6 staff {}", f4((b[0] + 6.0 * b[1]).exp()));
    let (bl, _) = irls(&x, &y, &zero, [0.0, 0.0], 1, false);
    let ols_b1 = x.iter().zip(&y).map(|(xi, yi)| (xi - 2.5) * (yi - ybar)).sum::<f64>() / 5.0;
    println!("normal family, identity link, one step: b0 {} b1 {} | closed form b1 {}", f4(bl[0]), f4(bl[1]), f4(ols_b1));
    println!("straight-line prediction at 6 staff {}", f4(bl[0] + 6.0 * bl[1]));
    assert!((bl[1] - ols_b1).abs() < 1e-12);
    let pc: Vec<String> = (1..=6).map(|s| format!("{:.2}", (b[0] + b[1] * s as f64).exp())).collect();
    let lc: Vec<String> = (1..=6).map(|s| format!("{:.2}", bl[0] + bl[1] * s as f64)).collect();
    println!("chart, staff 1-6: Poisson {} | line {}", pc.join(" "), lc.join(" "));

    // ---- an offset for exposure: totals over different hours ----
    let (hours, tot) = ([1.0, 2.0, 1.0, 3.0], [14.0, 20.0, 7.0, 15.0]);
    let (logh, tsum): (Vec<f64>, f64) = (hours.iter().map(|t: &f64| t.ln()).collect(), tot.iter().sum());
    let (bo, _) = irls(&x, &tot, &logh, [(tsum / hours.iter().sum::<f64>()).ln(), 0.0], 25, true);
    let (bn, _) = irls(&x, &tot, &zero, [(tsum / n).ln(), 0.0], 25, true);
    println!("hours {} totals {} | with offset ln(hours): b1 {} multiplier {}", ints(&hours), ints(&tot), f4(bo[1]), f4(bo[1].exp()));
    println!("offset dropped: b1 {} multiplier {}", f4(bn[1]), f4(bn[1].exp()));
    let eqs = |yy: &[f64], f: &[f64]| (0..4).map(|i| yy[i] - f[i]).sum::<f64>().abs() + (0..4).map(|i| x[i] * (yy[i] - f[i])).sum::<f64>().abs();
    assert!(eqs(&tot, &means(&x, &logh, bo)) < 1e-9 && eqs(&tot, &means(&x, &zero, bn)) < 1e-9); // both fits solve their likelihood equations

    // ---- overdispersion: a noisier week ----
    let yn = [18.0, 7.0, 10.0, 3.0];
    let (bw, _) = irls(&x, &yn, &zero, [(yn.iter().sum::<f64>() / n).ln(), 0.0], 25, true);
    let mw = means(&x, &zero, bw); // fitted means, then the dispersion: Pearson X2 over n - 2
    let phw: f64 = (0..4).map(|i| (yn[i] - mw[i]).powi(2) / mw[i]).sum::<f64>() / 2.0;
    let sw = info_inv11(&x, &mw).sqrt(); println!("noisy week {} : b1 {} | dispersion {} | SE {} -> scaled {}", ints(&yn), f4(bw[1]), f4(phw), f4(sw), f4(sw * phw.sqrt()));
    assert!(eqs(&yn, &mw) < 1e-9 && (phw * (n - 2.0) - ((0..4).map(|i| yn[i] * yn[i] / mw[i]).sum::<f64>() - yn.iter().sum::<f64>())).abs() < 1e-9); // X2 = sum y^2/mu - sum y

    // ---- what breaks ----
    println!("mistake: b1 read as emails per person {} | fitted change 1 -> 2 staff {}", f4(b[1]), f4(mu[1] - mu[0]));
    println!("ALL CHECKS PASS");
}
