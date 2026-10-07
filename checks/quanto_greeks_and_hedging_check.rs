// Hedging a quanto -- the same check as quanto_greeks_and_hedging_check.py, in Rust.
// Standard library only, no crates.  Normal CDF by series, tree by loops, splitmix64.
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn ncdf(x: f64) -> f64 {
    if x < 0.0 { return 1.0 - ncdf(-x); }
    if x > 8.5 { return 1.0; }
    let (mut term, mut total, mut k) = (x, x, 0.0);
    while term > 1e-17 * total { k += 1.0; term *= x * x / (2.0 * k + 1.0); total += term; }
    0.5 + phi(x) * total
}

const S0: f64 = 100.0; const K: f64 = 100.0; const XBAR: f64 = 1.10; const X0: f64 = 1.15;
const RD: f64 = 0.05; const RF: f64 = 0.03; const Q: f64 = 0.01;
const A: f64 = 0.20; const B: f64 = 0.10; const RHO: f64 = 0.30; const T: f64 = 1.0;

// road 1: the closed form, in USD. Arguments: S, a, b, rho, rd, rf, t
fn price(s: f64, a: f64, b: f64, rho: f64, rd: f64, rf: f64, t: f64) -> f64 {
    let (mu, w) = (rf - Q - rho * a * b, a * t.sqrt());
    let d1 = ((s / K).ln() + (mu + 0.5 * a * a) * t) / w;
    XBAR * (-rd * t).exp() * (s * (mu * t).exp() * ncdf(d1) - K * ncdf(d1 - w))
}
fn p0() -> f64 { price(S0, A, B, RHO, RD, RF, T) }
fn delta(s: f64, t: f64) -> f64 {
    let mu = RF - Q - RHO * A * B;
    XBAR * ((mu - RD) * t).exp() * ncdf(((s / K).ln() + (mu + 0.5 * A * A) * t) / (A * t.sqrt()))
}

// road 2: two-asset tree; drifts come from no-arbitrage, mu never used
fn tree(n: usize, rho: f64) -> (f64, f64) {
    let hh = T / n as f64; let sh = hh.sqrt(); let be = (1.0 - rho * rho).sqrt();
    let mx = ((B * sh).exp() + (-B * sh).exp()) / 2.0;
    let ax = ((RD - RF) * hh).exp() / mx;
    let (mut msx, mut step) = (0.0, 0.0);
    for e1 in [1.0, -1.0] { for e2 in [1.0, -1.0] { msx += (B * sh * e1 + A * sh * (rho * e1 + be * e2)).exp(); } }
    msx /= 4.0;
    let a_s = ((RD - Q) * hh).exp() / (ax * msx);
    let nf = n as f64;
    let mut v: Vec<Vec<f64>> = (0..=n).map(|i| (0..=n).map(|j| {
        let st = S0 * a_s.powf(nf) * (A * sh * (rho * (2.0 * i as f64 - nf) + be * (2.0 * j as f64 - nf))).exp();
        XBAR * (st - K).max(0.0) }).collect()).collect();
    let disc = (-RD * hh).exp() / 4.0;
    for m in (1..=n).rev() {
        v = (0..m).map(|i| (0..m).map(|j| disc * (v[i][j] + v[i + 1][j] + v[i][j + 1] + v[i + 1][j + 1])).collect()).collect();
    }
    for e1 in [1.0, -1.0] { for e2 in [1.0, -1.0] { step += (A * sh * (rho * e1 + be * e2)).exp(); } }
    step /= 4.0;
    (v[0][0], S0 * (a_s * step).powf(nf))
}

struct Rng(u64);
impl Rng {
    fn u01(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53) + 2f64.powi(-54)
    }
}

// road 3: hedge it, daily, 2000 paths. Strategies: full, no euro loan, loan frozen, shares = V_S
fn hedge_book(v0: f64, vs0: f64, mu: f64, paths: usize, steps: usize) -> Vec<(f64, f64)> {
    let dt = T / steps as f64; let be = (1.0 - RHO * RHO).sqrt();
    let mut rng = Rng(20260927);
    let mut err: Vec<Vec<f64>> = vec![Vec::new(); 4];
    for _ in 0..paths {
        let (mut s, mut x) = (S0, X0);
        let mut eta = [vs0 / x, vs0 / x, vs0 / x, vs0];
        let mut f = [-eta[0] * s, 0.0, -eta[2] * s, -eta[3] * s];
        let mut d = [0.0; 4];
        for k in 0..4 { d[k] = v0 - eta[k] * s * x - f[k] * x; }
        for st in 1..=steps {
            let (r1, r2) = ((-2.0 * rng.u01().ln()).sqrt(), 2.0 * PI * rng.u01());
            let (z1, z2) = (r1 * r2.cos(), r1 * r2.sin());
            x *= ((RD - RF - 0.5 * B * B) * dt + B * dt.sqrt() * z1).exp();
            s *= ((mu - 0.5 * A * A) * dt + A * dt.sqrt() * (RHO * z1 + be * z2)).exp();
            let vs = if st < steps { delta(s, T - st as f64 * dt) } else { 0.0 };
            for k in 0..4 {
                d[k] = d[k] * (RD * dt).exp() + eta[k] * s * ((Q * dt).exp() - 1.0) * x;
                f[k] *= (RF * dt).exp();
                if st == steps { continue; }
                let ne = if k == 3 { vs } else { vs / x };
                let nf = if k == 2 { f[k] } else if k == 1 { 0.0 } else { -ne * s };
                d[k] -= (ne - eta[k]) * s * x + (nf - f[k]) * x;
                eta[k] = ne; f[k] = nf;
            }
        }
        let pay = XBAR * (s - K).max(0.0);
        for k in 0..4 { err[k].push(eta[k] * s * x + f[k] * x + d[k] - pay); }
    }
    err.iter().map(|e| {
        let n = e.len() as f64; let m = e.iter().sum::<f64>() / n;
        (m, (e.iter().map(|x| x * x).sum::<f64>() / n - m * m).sqrt()) }).collect()
}

fn main() {
    let mu = RF - Q - RHO * A * B; let w = A * T.sqrt();
    let d1 = ((S0 / K).ln() + (mu + 0.5 * A * A) * T) / w;
    let (v, vs) = (p0(), delta(S0, T));
    let g: [(&str, f64); 7] = [
        ("delta, USD per EUR", vs),
        ("gamma, USD per EUR^2", XBAR * ((mu - RD) * T).exp() * phi(d1) / (S0 * w)),
        ("share vega, per unit", XBAR * (-RD * T).exp() * S0 * (mu * T).exp() * (T.sqrt() * phi(d1) - RHO * B * T * ncdf(d1))),
        ("FX vega, per unit", -RHO * A * T * S0 * vs),
        ("USD rho, per unit", -T * v),
        ("EUR rho, per unit", T * S0 * vs),
        ("correlation, per unit", -A * B * T * S0 * vs)];
    let h = 1e-4;
    let pr = |s: f64, a: f64, b: f64, rho: f64, rd: f64, rf: f64| price(s, a, b, rho, rd, rf, T);
    let bump = [
        (pr(S0 + 0.01, A, B, RHO, RD, RF) - pr(S0 - 0.01, A, B, RHO, RD, RF)) / 0.02,
        (pr(S0 + 0.01, A, B, RHO, RD, RF) - 2.0 * v + pr(S0 - 0.01, A, B, RHO, RD, RF)) / 1e-4,
        (pr(S0, A + h, B, RHO, RD, RF) - pr(S0, A - h, B, RHO, RD, RF)) / (2.0 * h),
        (pr(S0, A, B + h, RHO, RD, RF) - pr(S0, A, B - h, RHO, RD, RF)) / (2.0 * h),
        (pr(S0, A, B, RHO, RD + h, RF) - pr(S0, A, B, RHO, RD - h, RF)) / (2.0 * h),
        (pr(S0, A, B, RHO, RD, RF + h) - pr(S0, A, B, RHO, RD, RF - h)) / (2.0 * h),
        (pr(S0, A, B, RHO + h, RD, RF) - pr(S0, A, B, RHO - h, RD, RF)) / (2.0 * h)];
    let (t100, _) = tree(100, RHO); let (t200, fwd200) = tree(200, RHO);
    let t_rho = (tree(200, RHO + 0.05).0 - tree(200, RHO - 0.05).0) / 0.1;
    let hb = hedge_book(v, vs, mu, 2000, 252);
    let vw = XBAR * (-RD * T).exp() * S0 * (mu * T).exp() * T.sqrt() * phi(d1);   // vega of the width alone
    let mc3 = v - (-RD * T).exp() * hb[0].0; let mc3_se = (-RD * T).exp() * hb[0].1 / 2000f64.sqrt();

    let rows = [("rho a b", RHO * A * B), ("mu = rf - q - rho a b", mu), ("d1", d1), ("N(d1)", ncdf(d1)), ("phi(d1)", phi(d1)),
        ("e^(mu - rd)T", ((mu - RD) * T).exp()), ("phi(d1) - rho b T N(d1)", T.sqrt() * phi(d1) - RHO * B * T * ncdf(d1)),
        ("1 formula, call USD", v), ("2 tree, 100 steps", t100), ("2 tree, 200 steps", t200),
        ("2 tree, 2 x 200 - 100", 2.0 * t200 - t100), ("  tree mean share EUR", fwd200),
        ("  quanto forward S e^muT", S0 * (mu * T).exp()), ("3 hedged simulation, call USD", mc3),
        ("  standard error", mc3_se), ("  rule of thumb, daily spread", (PI / 4.0).sqrt() * vw * A / 252f64.sqrt())];
    for (name, x) in rows { println!("{:<34}{:>14.6}", name, x); }
    println!("{:<26}{:>14}{:>14}", "Greek", "formula", "bump");
    for ((name, x), bx) in g.iter().zip(bump.iter()) { println!("{:<26}{:>14.6}{:>14.6}", name, x, bx); }
    let more = [("  correlation, tree bump", t_rho), ("share vega, per point", g[2].1 / 100.0),
        ("FX vega, per point", g[3].1 / 100.0), ("correlation, per 0.01", g[6].1 / 100.0),
        ("hedge: shares = V_S / X", vs / X0), ("hedge: euro loan EUR", -vs / X0 * S0),
        ("hedge: euro loan in USD", -vs * S0), ("hedge: dollar cash USD", v),
        ("wrong: shares = V_S", vs), ("wrong: vega, drift frozen", vw / 100.0),
        ("wrong: delta, no adjustment", XBAR * ((RF - Q - RD) * T).exp() * ncdf(((S0 / K).ln() + (RF - Q + 0.5 * A * A) * T) / w)),
        ("shares at X = 1.25", vs / 1.25), ("euro loan at X = 1.25", -vs / 1.25 * S0)];
    for (name, x) in more { println!("{:<34}{:>14.6}", name, x); }
    let sp = [80.0, 90.0, 100.0, 110.0, 120.0];
    let line = |lab: &str, f: &dyn Fn(f64) -> String| println!("{}{}", lab, sp.iter().map(|&s| f(s)).collect::<Vec<_>>().join(" "));
    line("resize, share EUR     ", &|s| format!("{:7.0}", s));
    line("resize, shares        ", &|s| format!("{:7.4}", delta(s, T) / X0));
    line("resize, euro loan EUR ", &|s| format!("{:7.2}", -delta(s, T) / X0 * s));
    let rhos = [-1.0, -0.75, -0.5, -0.25, 0.0, 0.25, 0.5, 0.75, 1.0];
    println!("chart, correlation    {}", rhos.iter().map(|r| format!("{:6.2}", r)).collect::<Vec<_>>().join(" "));
    println!("chart, call USD       {}", rhos.iter().map(|&r| format!("{:6.2}", pr(S0, A, B, r, RD, RF))).collect::<Vec<_>>().join(" "));
    println!("{:<34}{:>14.6}", "average slope, -1 to +1", (pr(S0, A, B, 1.0, RD, RF) - pr(S0, A, B, -1.0, RD, RF)) / 2.0);
    for (name, (m, sd)) in ["full hedge", "no euro loan", "euro loan frozen", "shares = V_S"].iter().zip(hb.iter()) {
        println!("hedge error, {:<18} mean {:9.4}  spread {:8.4}", name, m, sd);
    }

    assert!((v - 9.151629).abs() < 5e-7, "formula vs the hand-worked 9.151629");
    assert!((2.0 * t200 - t100 - v).abs() < 0.002, "two-asset tree, extrapolated, lands on the formula");
    assert!((fwd200 - S0 * (mu * T).exp()).abs() < 1e-3, "the tree finds the quanto drift without being told it");
    assert!((mc3 - v).abs() < 4.0 * mc3_se, "hedged simulation within four standard errors");
    for ((name, x), bx) in g.iter().zip(bump.iter()) {
        assert!((x - bx).abs() < 1e-5 * x.abs().max(1.0), "Greek formula vs bump: {}", name);
    }
    assert!((t_rho - g[6].1).abs() < 0.01, "tree bump vs correlation Greek");
    assert!((hb[0].1 - (PI / 4.0).sqrt() * vw * A / 252f64.sqrt()).abs() < 0.1, "full hedge spread vs the rule of thumb");
    assert!(hb[1].1 > 5.0 * hb[0].1 && hb[2].1 > 2.0 * hb[0].1 && hb[3].1 > 2.0 * hb[0].1, "every broken hedge is worse");
    println!("ALL CHECKS PASS");
}
