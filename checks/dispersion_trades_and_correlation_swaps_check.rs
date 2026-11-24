// Dispersion trade and correlation swap -- the check behind the card. std only.
const W: [f64; 2] = [0.5, 0.5]; // house: weights, implied vols, implied correlation
const VOL: [f64; 2] = [0.20, 0.20]; const RHO: f64 = 0.5;

fn show(label: &str, x: f64) { // tiny float noise prints as 0, not -0
    println!("{:<50}{:.6}", label, if x.abs() > 1e-12 { x } else { 0.0 });
}

fn index_var(w: &[f64], v: &[f64], rho: f64) -> f64 {
    let n = w.len();
    let mut s = 0.0;
    for i in 0..n { for j in 0..n { s += w[i] * w[j] * v[i] * v[j] * (if i == j { 1.0 } else { rho }); } }
    s
}

fn cross(w: &[f64], v: &[f64]) -> f64 {
    let n = w.len();
    let mut s = 0.0;
    for i in 0..n { for j in 0..n { if i != j { s += w[i] * w[j] * v[i] * v[j]; } } }
    s
}

fn implied_corr(ki: f64, w: &[f64], k: &[f64]) -> f64 {
    let own: f64 = w.iter().zip(k).map(|(wi, kk)| wi * wi * kk).sum();
    let roots: Vec<f64> = k.iter().map(|x| x.sqrt()).collect();
    (ki - own) / cross(w, &roots)
}

fn notionals(w: &[f64], v: &[f64], rho: f64) -> Vec<f64> {
    let n = w.len();
    (0..n).map(|i| {
        let o: f64 = (0..n).filter(|&j| j != i).map(|j| w[j] * v[j]).sum();
        w[i] * w[i] + rho * w[i] * o / v[i]
    }).collect()
}

fn pnl(nn: &[f64], ki: f64, k: &[f64], rvi: f64, rv: &[f64]) -> f64 {
    let m: f64 = nn.iter().zip(rv).zip(k).map(|((n, r), kk)| n * (r - kk)).sum();
    (ki - rvi) + m
}

struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53) + 2f64.powi(-54)
    }
    fn normal(&mut self) -> f64 {
        let (u0, u1) = (self.uniform(), self.uniform());
        (-2.0 * u0.ln()).sqrt() * (2.0 * std::f64::consts::PI * u1).cos()
    }
}

fn year(g: &mut Rng, rho: f64) -> (f64, f64, f64, f64) { // 252 days; index rebalanced daily to 50/50
    let (mut a, mut b, mut xy, mut ii) = (0.0, 0.0, 0.0, 0.0);
    for _ in 0..252 {
        let z1 = g.normal();
        let z2 = rho * z1 + (1.0 - rho * rho).sqrt() * g.normal();
        let x1 = -0.5 * 0.04 / 252.0 + 0.2 * z1 / 252f64.sqrt();
        let x2 = -0.5 * 0.04 / 252.0 + 0.2 * z2 / 252f64.sqrt();
        let xi = (1.0 + W[0] * (x1.exp() - 1.0) + W[1] * (x2.exp() - 1.0)).ln();
        a += x1 * x1; b += x2 * x2; xy += x1 * x2; ii += xi * xi;
    }
    (a, b, xy / (a * b).sqrt(), ii)
}

fn main() {
    // ---- strikes and sizing ----
    let k: Vec<f64> = VOL.iter().map(|s| s * s).collect();
    let ki = index_var(&W, &VOL, RHO);
    let scenario = |nn: &[f64], vols: &[f64], rho_r: f64| -> f64 {
        let rv: Vec<f64> = vols.iter().map(|s| s * s).collect();
        pnl(nn, ki, &k, index_var(&W, vols, rho_r), &rv)
    };
    show("index variance strike K_I", ki);
    show("index volatility, percent", 100.0 * ki.sqrt());
    show("implied correlation from the strikes", implied_corr(ki, &W, &k));
    let nn = notionals(&W, &VOL, RHO);
    let h = 1e-4;
    let bumped = (index_var(&W, &[VOL[0] + h, VOL[1]], RHO) - index_var(&W, &[VOL[0] - h, VOL[1]], RHO)) / (2.0 * h);
    show("index variance slope in share 1 vol", bumped);
    show("member notional, closed form", nn[0]);
    show("member notional, bump / (2 sigma_1)", bumped / (2.0 * VOL[0]));
    assert!((nn[0] - bumped / (2.0 * VOL[0])).abs() < 1e-9);
    let tot: f64 = nn.iter().zip(&k).map(|(n, kk)| n * kk).sum();
    show("members' total notional x strike", tot);
    assert!((tot - ki).abs() < 1e-12);
    // ---- the trade, settled ----
    let rvi = index_var(&W, &VOL, 0.3);
    show("index realised variance at correlation 0.3", rvi);
    show("profit: index leg", ki - rvi);
    show("profit: member legs", nn.iter().zip(&k).zip(&k).map(|((n, r), kk)| n * (r - kk)).sum::<f64>());
    let p = scenario(&nn, &VOL, 0.3);
    show("profit: whole trade", p);
    show("profit at correlation 0.8, both 20%", scenario(&nn, &VOL, 0.8));
    let cx = cross(&W, &VOL);
    show("cross term sum w_i w_j sigma_i sigma_j", cx);
    show("profit: (rho_impl - rho_real) x cross term", (RHO - 0.3) * cx);
    assert!((p - (RHO - 0.3) * cx).abs() < 1e-12);
    show("correlation swap notional per unit", cx);
    let ni = 100000.0 / (2.0 * 100.0 * ki.sqrt());
    show("index variance notional, $ per var point", ni);
    show("member variance notional, $ each", nn[0] * ni);
    show("member vega notional, $ each", nn[0] * ni * 2.0 * 100.0 * VOL[0]);
    show("profit in dollars at correlation 0.3", ni * 10000.0 * p);
    // ---- flat in single-name vol, and what breaks ----
    let (wt, sq): (Vec<f64>, Vec<f64>) = (W.to_vec(), W.iter().map(|w| w * w).collect());
    for (name, m) in [("vega-neutral", &nn), ("by weight", &wt), ("by weight squared", &sq)] {
        let slope = (scenario(m, &[0.21, 0.20], RHO) - scenario(m, &[0.19, 0.20], RHO)) / 2.0;
        show(&format!("{}: slope per vol point of share 1", name), slope);
        show(&format!("{}: both 25%, correlation 0.5", name), scenario(m, &[0.25, 0.25], RHO));
        show(&format!("{}: both 30%, correlation 0.3", name), scenario(m, &[0.30, 0.30], 0.3));
    }
    assert!(scenario(&nn, &[0.25, 0.25], RHO).abs() < 1e-12 && (scenario(&wt, &[0.25, 0.25], RHO) - 0.005625).abs() < 1e-12);
    show("vega-neutral: 25% and 15%, correlation 0.5", scenario(&nn, &[0.25, 0.15], RHO));
    show("vol gap term rho w1 w2 (sigma1 - sigma2)^2", RHO * W[0] * W[1] * (0.25f64 - 0.15).powi(2));
    assert!((scenario(&nn, &[0.25, 0.15], RHO) - RHO * W[0] * W[1] * 0.01).abs() < 1e-12);
    for v in [0.15, 0.20, 0.30] { // chart: profit against realised correlation
        let pts: Vec<String> = (0..11).map(|c| {
            let x = 10000.0 * scenario(&nn, &[v, v], c as f64 / 10.0);
            format!("{:.2}", if x.abs() > 1e-9 { x } else { 0.0 })
        }).collect();
        println!("chart vol {:.2},{}", v, pts.join(","));
    }
    // ---- correlation swap strike from variance strikes ----
    let sw: f64 = W.iter().zip(&k).map(|(w, kk)| w * kk.sqrt()).sum();
    show("proxy K_I / (sum w_i sqrt K_i)^2, two names", ki / sw.powi(2));
    let w50 = vec![1.0 / 50.0; 50];
    let k50 = index_var(&w50, &vec![0.2; 50], RHO);
    show("50 names: index variance strike", k50);
    show("50 names: exact implied correlation", implied_corr(k50, &w50, &vec![0.04; 50]));
    let s50: f64 = w50.iter().map(|w| w * 0.2).sum();
    show("50 names: proxy", k50 / s50.powi(2));
    let states = [(0.5, 0.15, 0.3), (0.5, 0.30, 0.8)]; // (probability, vol, correlation)
    let ks: f64 = states.iter().map(|&(pr, v, _)| pr * v * v).sum();
    let kis: f64 = states.iter().map(|&(pr, v, c)| pr * index_var(&W, &[v, v], c)).sum();
    let ri = implied_corr(kis, &W, &[ks, ks]);
    let vw: f64 = states.iter().map(|&(pr, v, c)| pr * c * v * v).sum::<f64>() / ks;
    show("two states: member variance strike", ks);
    show("two states: index variance strike", kis);
    show("two states: implied correlation", ri);
    show("two states: variance-weighted correlation", vw);
    show("two states: correlation swap fair strike", states.iter().map(|&(pr, _, c)| pr * c).sum::<f64>());
    assert!((ri - vw).abs() < 1e-12);
    // ---- road 3: simulate daily prices, settle the legs from the path ----
    let mut g = Rng(20261123);
    let (a, b, rr, ii) = year(&mut g, 0.3);
    let legs = pnl(&nn, ki, &k, ii, &[a, b]);
    let formula = RHO * W[0] * W[1] * (a + b) - rr * 2.0 * W[0] * W[1] * (a * b).sqrt();
    show("sim year 1: share 1 realised vol, percent", 100.0 * a.sqrt());
    show("sim year 1: share 2 realised vol, percent", 100.0 * b.sqrt());
    show("sim year 1: realised correlation", rr);
    show("sim year 1: index realised variance", ii);
    show("sim year 1: profit from the three legs", legs);
    show("sim year 1: profit from the formula", formula);
    assert!((legs - formula).abs() < 2e-5);
    let ps: Vec<f64> = (0..1000).map(|_| {
        let (x, y, _, i) = year(&mut g, 0.3);
        pnl(&nn, ki, &k, i, &[x, y])
    }).collect();
    let m = ps.iter().sum::<f64>() / ps.len() as f64;
    let se = (ps.iter().map(|x| (x - m).powi(2)).sum::<f64>() / (ps.len() as f64 - 1.0) / ps.len() as f64).sqrt();
    show("1000 sim years: average profit", m);
    show("1000 sim years: standard error", se);
    assert!((m - 0.004).abs() < 4.0 * se);
    println!("ALL CHECKS PASS");
}
