// Asian Greeks and the running average -- the same check as the Python, in Rust.  std only, no crates.
// Road 1: Monte Carlo on common random numbers, bumped, geometric average as control.
// Road 2: the moment-matched (Levy) formula and its closed-form Greeks.
// Compile: rustc --edition 2021 -O asian_greeks_and_the_running_average_check.rs -o /tmp/<dir>/chk
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn ncdf(x: f64) -> f64 {                            // normal CDF from its power series
    if x.abs() > 9.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    let (mut term, mut total, mut k) = (x, x, 0.0);
    while term.abs() > 1e-17 * total.abs() { k += 1.0; term *= x * x / (2.0 * k + 1.0); total += term; }
    0.5 + phi(x) * total
}
fn fwd(s: f64, r: f64, t: &[f64]) -> Vec<f64> { t.iter().map(|ti| s * (r * ti).exp()).collect() }
fn moments(f: &[f64], t: &[f64], sig: f64) -> (f64, f64, f64) {
    let m = f.len() as f64; let (mut m2, mut dm2) = (0.0, 0.0);
    for i in 0..f.len() { for j in 0..f.len() {
        let c = t[i].min(t[j]); let e = f[i] * f[j] * (sig * sig * c).exp();
        m2 += e; dm2 += e * 2.0 * sig * c;
    } }
    (f.iter().sum::<f64>() / m, m2 / m / m, dm2 / m / m)
}
fn levy(s: f64, f: &[f64], t: &[f64], sig: f64, w: f64, ks: f64, disc: f64) -> [f64; 4] {
    let (m1, m2, dm2) = moments(f, t, sig);
    if ks <= 0.0 { return [disc * w * (m1 - ks), disc * w * m1 / s, 0.0, 0.0]; }
    let v = (m2 / m1 / m1).ln().sqrt(); let d1 = ((m1 / ks).ln() + 0.5 * v * v) / v;
    [disc * w * (m1 * ncdf(d1) - ks * ncdf(d1 - v)), disc * w * m1 / s * ncdf(d1),
     disc * w * m1 / s * phi(d1) / (s * v), disc * w * m1 * phi(d1) * dm2 / (2.0 * m2 * v) / 100.0]
}
fn geo(f: &[f64], t: &[f64], sig: f64, w: f64, ks: f64, disc: f64) -> f64 {
    let m = f.len() as f64;
    let mu = f.iter().map(|x| x.ln()).sum::<f64>() / m - 0.5 * sig * sig * t.iter().sum::<f64>() / m;
    let mut sm = 0.0; for a in t { for b in t { sm += a.min(*b); } }
    let s2 = sig * sig * sm / m / m; let g = (mu + 0.5 * s2).exp();
    if ks <= 0.0 { return disc * w * (g - ks); }
    let d1 = ((g / ks).ln() + 0.5 * s2) / s2.sqrt();
    disc * w * (g * ncdf(d1) - ks * ncdf(d1 - s2.sqrt()))
}
struct Path { a: f64, l: f64, q: [f64; 4] }
fn sim(f: &[f64], t: &[f64], sig: f64, pairs: usize, q: &[usize]) -> Vec<Path> {
    let mut st: u64 = 20260927; let m = f.len(); let mut out = Vec::new();
    let mut u = || { st = st.wrapping_add(0x9E3779B97F4A7C15); let mut z = st;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9); z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53) };
    for _ in 0..pairs {
        let mut zs: Vec<f64> = Vec::new();
        while zs.len() < m { let a = 1.0 - u(); let b = u(); let rr = (-2.0 * a.ln()).sqrt();
            zs.push(rr * (2.0 * PI * b).cos()); zs.push(rr * (2.0 * PI * b).sin()); }
        for sgn in [1.0, -1.0] {
            let (mut w, mut prev, mut a, mut l, mut qs) = (0.0, 0.0, 0.0, 0.0, [0.0f64; 4]);
            for i in 0..m {
                w += sgn * zs[i] * (t[i] - prev).sqrt(); prev = t[i];
                let x = f[i] * (sig * w - 0.5 * sig * sig * t[i]).exp(); a += x; l += x.ln(); qs[q[i]] += x;
            }
            out.push(Path { a: a / m as f64, l: l / m as f64, q: qs });
        }
    }
    out
}
#[allow(clippy::too_many_arguments)]
fn mc(p: &[Path], f: &[f64], t: &[f64], sig: f64, fixed: f64, w: f64, k: f64, disc: f64,
      scale: f64, q: &[usize], qb: i32, b: f64) -> f64 {
    let m = f.len() as f64; let ks = (k - fixed) / w;
    let fb: Vec<f64> = (0..f.len()).map(|i| f[i] * scale * (if qb >= 0 && q[i] as i32 == qb { b } else { 1.0 })).collect();
    let cnt = if qb >= 0 { q.iter().filter(|&&x| x as i32 == qb).count() as f64 } else { 0.0 };
    let mut tot = 0.0;
    for pa in p {
        let a = scale * (pa.a + if qb >= 0 { (b - 1.0) * pa.q[qb as usize] / m } else { 0.0 });
        let g = (pa.l + scale.ln() + if qb >= 0 { b.ln() * cnt / m } else { 0.0 }).exp();
        tot += (fixed + w * a - k).max(0.0) - w * (g - ks).max(0.0);
    }
    disc * tot / p.len() as f64 + geo(&fb, t, sig, w, ks, disc)
}
fn out(lab: &str, a: f64, b: f64) { println!("{:<34}{:>11.4}{:>11.4}", lab, a, b); }

fn main() {
    let (s, k, r, sig, n, pairs) = (100.0_f64, 100.0_f64, 0.05_f64, 0.20_f64, 52usize, 20000usize);
    let nf = n as f64;
    // ---- fresh contract ----
    let t: Vec<f64> = (0..n).map(|i| (i + 1) as f64 / nf).collect(); let f = fwd(s, r, &t);
    let qid: Vec<usize> = (0..n).map(|i| i / 13).collect(); let d = (-r).exp();
    let (p0, pu, pd) = (sim(&f, &t, sig, pairs, &qid), sim(&f, &t, sig + 0.01, pairs, &qid), sim(&f, &t, sig - 0.01, pairs, &qid));
    let pr = |p: &[Path], sg: f64, fx: f64, w: f64, sc: f64| mc(p, &f, &t, sg, fx, w, k, d, sc, &qid, -1, 1.0);
    let (v0, vu, vd) = (pr(&p0, sig, 0.0, 1.0, 1.0), pr(&p0, sig, 0.0, 1.0, 1.01), pr(&p0, sig, 0.0, 1.0, 0.99));
    let mcg = [(vu - vd) / 2.0, vu - 2.0 * v0 + vd, (pr(&pu, sig + 0.01, 0.0, 1.0, 1.0) - pr(&pd, sig - 0.01, 0.0, 1.0, 1.0)) / 2.0];
    let lf = levy(s, &f, &t, sig, 1.0, k, d);
    let fl = f[n - 1]; let d1 = ((fl / k).ln() + 0.5 * sig * sig) / sig; let bl = d * (fl * ncdf(d1) - k * ncdf(d1 - sig));
    println!("{:<34}{:>11}{:>11}", "fresh, 52 fixings to come", "MC bumped", "formula");
    out("price", v0, lf[0]); out("delta", mcg[0], lf[1]); out("gamma", mcg[1], lf[2]); out("vega per vol point", mcg[2], lf[3]);
    let gmc = d * p0.iter().map(|x| (x.l.exp() - k).max(0.0)).sum::<f64>() / p0.len() as f64;
    let gx = geo(&f, &t, sig, 1.0, k, d); out("geometric control, exact / MC", gx, gmc);
    out("plain Black-76 call: price, delta", bl, ncdf(d1)); out("plain call: gamma, vega/point", phi(d1) / (s * sig), s * phi(d1) / 100.0);
    let ladder = |p: &[Path], ff: &[f64], tt: &[f64], fixed: f64, w: f64, disc: f64, q: &[usize]| -> Vec<(f64, f64)> {
        let ks = (k - fixed) / w;
        let bump = |j: usize, b: f64| -> Vec<f64> { ff.iter().zip(q).map(|(x, &qi)| x * if qi == j { b } else { 1.0 }).collect() };
        (0..4).map(|j| if q.contains(&j) {
            ((mc(p, ff, tt, sig, fixed, w, k, disc, 1.0, q, j as i32, 1.01) - mc(p, ff, tt, sig, fixed, w, k, disc, 1.0, q, j as i32, 0.99)) / 2.0,
             (levy(s, &bump(j, 1.01), tt, sig, w, ks, disc)[0] - levy(s, &bump(j, 0.99), tt, sig, w, ks, disc)[0]) / 2.0)
        } else { (0.0, 0.0) }).collect()
    };
    let lad0 = ladder(&p0, &f, &t, 0.0, 1.0, d, &qid);
    // ---- seasoned: 26 banked at an average of 103, jet fuel back at 100 ----
    let (kk, abar) = (26usize, 103.0);
    let fixed = kk as f64 / nf * abar; let w = (n - kk) as f64 / nf; let ks = (k - fixed) / w;
    let t2: Vec<f64> = (0..n - kk).map(|i| (i + 1) as f64 / nf).collect(); let f2 = fwd(s, r, &t2); let d2 = (-r * t2[t2.len() - 1]).exp();
    let q2: Vec<usize> = (0..n - kk).map(|i| (kk + i) / 13).collect();
    let (q0, qu, qd) = (sim(&f2, &t2, sig, pairs, &q2), sim(&f2, &t2, sig + 0.01, pairs, &q2), sim(&f2, &t2, sig - 0.01, pairs, &q2));
    let sp = |p: &[Path], sg: f64, fx: f64, sc: f64| mc(p, &f2, &t2, sg, fx, w, k, d2, sc, &q2, -1, 1.0);
    let (s0, su, sd) = (sp(&q0, sig, fixed, 1.0), sp(&q0, sig, fixed, 1.01), sp(&q0, sig, fixed, 0.99));
    let sv = (sp(&qu, sig + 0.01, fixed, 1.0) - sp(&qd, sig - 0.01, fixed, 1.0)) / 2.0;
    let ls = levy(s, &f2, &t2, sig, w, ks, d2);
    println!("seasoned: banked part {:.2}, weight {:.2}, new strike {:.2}", fixed, w, ks);
    out("price, full payoff vs rewritten", s0, ls[0]); out("delta", (su - sd) / 2.0, ls[1]);
    out("gamma", su - 2.0 * s0 + sd, ls[2]); out("vega per vol point", sv, ls[3]);
    out("delta, seasoned / fresh", ((su - sd) / 2.0) / mcg[0], ls[1] / lf[1]);
    let lad2 = ladder(&q0, &f2, &t2, fixed, w, d2, &q2);
    let fx2 = kk as f64 / nf * 205.0; let fwd_mc = sp(&q0, sig, fx2, 1.0); let fwd_lv = levy(s, &f2, &t2, sig, w, (k - fx2) / w, d2)[0];
    out("banked at 205: strike -5, price", fwd_mc, fwd_lv);
    for (lab, ff, tt, kx, dd) in [("fresh", &f, &t, k, d), ("seasoned", &f2, &t2, ks, d2)] {
        let (m1, m2, _) = moments(ff, tt, sig); let v = (m2 / m1 / m1).ln().sqrt(); let e = ((m1 / kx).ln() + 0.5 * v * v) / v;
        println!("{:<34}{}", format!("{}: M1 v d1 N(d1) N(d1-v) D", lab), [m1, v, e, ncdf(e), ncdf(e - v), dd].iter().map(|x| format!("{:>9.4}", x)).collect::<String>());
    }
    println!("{:<22}{:>10}{:>10}{:>10}{:>10}", "delta ladder, quarter", "fresh MC", "formula", "seas. MC", "formula");
    for j in 0..4 { println!("{:<22}{:>10.4}{:>10.4}{:>10.4}{:>10.4}", format!("Q{}", j + 1), lad0[j].0, lad0[j].1, lad2[j].0, lad2[j].1); }
    // ---- risk draining as fixings are set ----
    println!("{:>10}{:>9}{:>9}{:>9}{:>9}{:>9}", "fixings in", "price", "delta", "vega/pt", "call dlt", "call vg");
    let (mut va, mut vc): (Vec<f64>, Vec<f64>) = (Vec::new(), Vec::new());
    for kx in [0usize, 13, 26, 39, 48] {
        let tk: Vec<f64> = (0..n - kx).map(|i| (i + 1) as f64 / nf).collect(); let tau = tk[tk.len() - 1];
        let e1 = (r + 0.5 * sig * sig) * tau / (sig * tau.sqrt());
        let p = levy(s, &fwd(s, r, &tk), &tk, sig, (n - kx) as f64 / nf, k, (-r * tau).exp());
        println!("{:>10}{:>9.4}{:>9.4}{:>9.4}{:>9.4}{:>9.4}", kx, p[0], p[1], p[3], ncdf(e1), s * phi(e1) * tau.sqrt() / 100.0);
        va.push(100.0 * p[3]); vc.push(s * phi(e1) * tau.sqrt());
    }
    let xs: Vec<f64> = (0..7).map(|i| 85.0 + 5.0 * i as f64).collect();
    let rows = [("chart, remaining average", xs.clone()), ("chart, seasoned payoff", xs.iter().map(|x| w * (x - ks).max(0.0)).collect()),
        ("chart, banked ignored", xs.iter().map(|x| (x - k).max(0.0)).collect()), ("chart, Asian vega cents", va), ("chart, call vega cents", vc)];
    for (lab, row) in rows.iter() { println!("{:<25}{}", lab, row.iter().map(|v| format!("{:6.2}", v)).collect::<Vec<_>>().join(" ")); }
    // ---- what breaks, and try changing ----
    let two = |lab: &str, x: [f64; 4]| out(lab, x[0], x[1]);
    two("wrong: ignore banked, fresh 26 at 100", levy(s, &f2, &t2, sig, 1.0, k, d2));
    two("wrong: strike 97 but full weight", levy(s, &f2, &t2, sig, 1.0, ks, d2));
    two("wrong: strike 100-51.5, not /0.5", levy(s, &f2, &t2, sig, w, k - fixed, d2));
    two("wrong: flat curve at 100, fresh", levy(s, &vec![s; n], &t, sig, 1.0, k, d));
    two("try: banked at 97, strike 103", levy(s, &f2, &t2, sig, w, (k - kk as f64 / nf * 97.0) / w, d2));
    let tm: Vec<f64> = (0..12).map(|i| (i + 1) as f64 / 12.0).collect();
    two("try: 12 monthly fixings, fresh", levy(s, &fwd(s, r, &tm), &tm, sig, 1.0, k, d));
    two("try: sigma 0.40, fresh", levy(s, &f, &t, 0.40, 1.0, k, d));

    assert!((gmc - gx).abs() < 0.02, "raw simulator, no control: geometric average vs its exact price");
    assert!((v0 - lf[0]).abs() < 0.03, "controlled simulation vs moment formula, fresh price");
    assert!((mcg[0] - lf[1]).abs() < 0.01, "bumped delta vs formula delta");
    assert!((mcg[2] - lf[3]).abs() < 0.005, "bumped vega vs formula vega");
    assert!((mcg[1] / lf[2] - 1.0).abs() < 0.1, "bumped gamma vs formula gamma, within 10 percent");
    assert!((s0 - ls[0]).abs() < 0.03, "full seasoned payoff simulated vs half an option struck at 97");
    assert!(((su - sd) / 2.0 - ls[1]).abs() < 0.01, "seasoned delta, bumped vs formula");
    assert!((lad0.iter().map(|x| x.0).sum::<f64>() - mcg[0]).abs() < 0.002 && (lad2.iter().map(|x| x.0).sum::<f64>() - (su - sd) / 2.0).abs() < 0.002, "rungs add up to delta");
    assert!((fwd_mc - fwd_lv).abs() < 0.02, "strike below zero: simulated vs the certain-payout forward value");
    assert!((bl - 10.450583572185565).abs() < 1e-9, "plain call against the house number");
    println!("ALL CHECKS PASS");
}
