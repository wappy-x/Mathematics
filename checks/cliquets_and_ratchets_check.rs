// Cliquets -- the check behind the card.  Rust std only; nothing imported knows the answer: bell-curve area
// by its series, random numbers by a 64-bit congruential recurrence and Box-Muller, implied vol by bisection.
use std::f64::consts::PI;

const R: f64 = 0.05; const Q: f64 = 0.02; const SIG: f64 = 0.20; const T: f64 = 1.0;   // the house market
const NQ: usize = 4; const M: usize = 8; const NS: usize = NQ * M;                    // four quarters, eight steps each
const CAP: f64 = 0.05; const FLO: f64 = -0.05;                                        // local cap and floor; global floor 0
const KAP: f64 = 2.0; const TH: f64 = 0.04; const XI: f64 = 0.3; const RHO: f64 = -0.7; const V0: f64 = 0.04;
const NP: usize = 100000; const NB: usize = 50; const W: f64 = 0.04;                 // paths; local-vol table bins
const KS: [f64; 5] = [0.90, 0.95, 1.00, 1.05, 1.10];

fn n(x: f64) -> f64 {                                   // bell-curve area left of x, Marsaglia's series
    if x < -8.0 { return 0.0; }
    if x > 8.0 { return 1.0; }
    let (mut s, mut t, mut b, xx, mut i) = (x, 0.0, x, x * x, 1.0);
    while s != t { t = s; i += 2.0; b *= xx / i; s = t + b; }
    0.5 + s * (-0.5 * xx - 0.91893853320467274178).exp()
}
fn unit_call(k: f64, ta: f64, sg: f64, rr: f64) -> (f64, f64, f64) {   // Black-Scholes call on a $1 share
    let d1 = (-k.ln() + (rr - Q + 0.5 * sg * sg) * ta) / (sg * ta.sqrt()); let d2 = d1 - sg * ta.sqrt();
    ((-Q * ta).exp() * n(d1) - k * (-rr * ta).exp() * n(d2), d1, d2)
}
fn implied(price: f64, k: f64, ta: f64) -> f64 {        // bisection: the flat vol that gives this price
    let (mut lo, mut hi) = (0.01, 1.0);
    for _ in 0..60 {
        let mid = 0.5 * (lo + hi);
        if unit_call(k, ta, mid, R).0 > price { hi = mid; } else { lo = mid; }
    }
    0.5 * (lo + hi)
}
fn conv_price(sg: f64, cap: f64, flo: f64, gf: f64, rr: f64) -> (f64, f64, f64, f64, f64, f64) {
    // Road 2, flat model only: the quarter's capped coupon on a grid, four copies added by convolution
    let (h, tau) = (0.00025, T / NQ as f64);
    let (mu, s) = ((rr - Q - 0.5 * sg * sg) * tau, sg * tau.sqrt());
    let f = |a: f64| n(((1.0 + a).ln() - mu) / s);     // chance the quarter's return is below a
    let m = ((cap - flo) / h).round() as usize;
    let mut p = vec![f(flo + h / 2.0)];
    for i in 1..m { p.push(f(flo + i as f64 * h + h / 2.0) - f(flo + i as f64 * h - h / 2.0)); }
    p.push(1.0 - f(cap - h / 2.0));
    let mut d = p.clone();
    for _ in 0..NQ - 1 {
        let mut out = vec![0.0; d.len() + m];
        for (i, a) in d.iter().enumerate() { for (j, b) in p.iter().enumerate() { out[i + j] += a * b; } }
        d = out;
    }
    let ev: f64 = d.iter().enumerate().map(|(k, w)| w * (NQ as f64 * flo + k as f64 * h).max(gf)).sum();
    let ec: f64 = p.iter().enumerate().map(|(k, w)| w * (flo + k as f64 * h)).sum();
    let ep: f64 = p.iter().enumerate().map(|(k, w)| w * (flo + k as f64 * h).max(0.0)).sum();
    (100.0 * (-rr * T).exp() * ev, 1.0 - p[m] - p[0], p[0], p[m], ec, ep)
}
struct Rng(u64);
impl Rng {
    fn u(&mut self) -> f64 {
        self.0 = self.0.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((self.0 >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn pair(&mut self) -> (f64, f64) {                  // two independent standard normal draws
        let (u1, u2) = (self.u(), self.u());
        let rr = (-2.0 * u1.ln()).sqrt(); (rr * (2.0 * PI * u2).cos(), rr * (2.0 * PI * u2).sin())
    }
}
struct Pay { capped: f64, unc: f64, fwd: [f64; 5], van: [f64; 5], c: f64, ncap: f64, nflo: f64 }
fn payoffs(xs: &[f64]) -> Pay {                         // xs = ln(S/S0) at 0, 0.25, 0.5, 0.75, 1
    let rt: Vec<f64> = (0..NQ).map(|i| (xs[i + 1] - xs[i]).exp() - 1.0).collect();
    let c: f64 = rt.iter().map(|x| x.max(FLO).min(CAP)).sum();
    Pay { capped: c.max(0.0), unc: rt.iter().map(|x| x.max(0.0)).sum(),
          fwd: KS.map(|k| (1.0 + rt[3] - k).max(0.0)), van: KS.map(|k| (xs[NQ].exp() - k).max(0.0)), c,
          ncap: rt.iter().filter(|&&x| x > CAP).count() as f64, nflo: rt.iter().filter(|&&x| x < FLO).count() as f64 }
}
fn stats(a: &[f64]) -> (f64, f64) {
    let nn = a.len() as f64; let m = a.iter().sum::<f64>() / nn;
    (m, (a.iter().map(|x| (x - m) * (x - m)).sum::<f64>() / (nn - 1.0) / nn).sqrt())
}
fn showp(label: &str, vals: &[f64], dp: usize) {
    let mut s = format!("{:<44}", label);
    for v in vals { s += &format!("{:>11.*}", dp, v); }
    println!("{}", s);
}
fn show(label: &str, vals: &[f64]) { showp(label, vals, 6) }
fn main() {
    let tau = T / NQ as f64; let dt = tau / M as f64; let bin = |x: f64| (((x + 1.0) / W) as i64).max(0).min(NB as i64 - 1) as usize;
    // ---- Road 3: Heston paths; the same pass records the average variance at each price and date ----
    let rq = (1.0 - RHO * RHO).sqrt();
    let row = [0.0f64; NB]; let (mut sv, mut cn) = (vec![row; NS], vec![row; NS]);
    let mut rng = Rng(0x2545F4914F6CDD1D); let mut hp = Vec::with_capacity(NP);
    for _ in 0..NP {
        let (mut x, mut v, mut xs) = (0.0f64, V0, vec![0.0]);
        for j in 0..NS {
            let vp = if v > 0.0 { v } else { 0.0 };
            let b = bin(x); sv[j][b] += vp; cn[j][b] += 1.0;
            let (z1, z2) = rng.pair();
            x += (R - Q - 0.5 * vp) * dt + (vp * dt).sqrt() * z1;
            v += KAP * (TH - vp) * dt + XI * (vp * dt).sqrt() * (RHO * z1 + rq * z2);
            if (j + 1) % M == 0 { xs.push(x); }
        }
        hp.push(payoffs(&xs));
    }
    // local variance = average Heston variance of the paths at that price and date (Gyongy), shrunk to the date's mean
    let l: Vec<Vec<f64>> = (0..NS).map(|j| { let tot: f64 = sv[j].iter().sum();
        (0..NB).map(|b| (sv[j][b] + 50.0 * tot / NP as f64) / (cn[j][b] + 50.0)).collect() }).collect();
    // ---- Roads 4 and 1b: local-vol paths and flat paths, driven by the same share shocks as Heston ----
    let mut rng = Rng(0x2545F4914F6CDD1D); let (mut lp, mut fp) = (Vec::with_capacity(NP), Vec::with_capacity(NP));
    for _ in 0..NP {
        let (mut x, mut y, mut xs, mut ys) = (0.0f64, 0.0f64, vec![0.0], vec![0.0]);
        for j in 0..NS {
            let lv = l[j][bin(x)];
            let (z1, _z2) = rng.pair();
            x += (R - Q - 0.5 * lv) * dt + (lv * dt).sqrt() * z1;
            y += (R - Q - 0.5 * SIG * SIG) * dt + SIG * dt.sqrt() * z1;
            if (j + 1) % M == 0 { xs.push(x); ys.push(y); }
        }
        lp.push(payoffs(&xs)); fp.push(payoffs(&ys));
    }
    let dd = (-R * T).exp(); let npf = NP as f64;
    // ---- Road 1: the uncapped cliquet is four forward-start calls, closed form ----
    let (u, d1, d2) = unit_call(1.0, tau, SIG, R);
    let leg = 100.0 * (-R * (T - tau)).exp() * u;
    let fs_house = 100.0 * (-Q * 0.5).exp() * unit_call(1.0, 0.5, SIG, R).0;   // the shelf's forward-start, reset 0.5 year
    show("d1, d2, N(d1), N(d2) (one quarter)", &[d1, d2, n(d1), n(d2)]);
    show("unit call C(1,1,0.25), e^-r(T-tau)", &[u, (-R * (T - tau)).exp()]);
    show("house check: forward-start reset 0.5y", &[fs_house]);
    show("uncapped leg, each of four", &[leg]); show("uncapped: sum of four legs", &[4.0 * leg]);
    let (unc, unc_se) = stats(&fp.iter().map(|a| 100.0 * dd * a.unc).collect::<Vec<_>>());
    show("uncapped: flat simulation, std error", &[unc, unc_se]);
    show("wrong: notional carried as a share", &[(0..NQ).map(|i| 100.0 * (-Q * i as f64 * tau - R * (T - (i + 1) as f64 * tau)).exp() * u).sum::<f64>()]);
    show("monthly resets, uncapped (12 legs)", &[1200.0 * (-R * (T - T / 12.0)).exp() * unit_call(1.0, T / 12.0, SIG, R).0]);
    let (cv, pin, pfl, pcap, ec, ep) = conv_price(SIG, CAP, FLO, 0.0, R);
    show("flat: P(floor), P(inside), P(cap), E[c]", &[pfl, pin, pcap, ec]); show("capped: flat, convolution", &[cv]);
    let st = |ps: &Vec<Pay>| stats(&ps.iter().map(|a| 100.0 * dd * a.capped).collect::<Vec<_>>());
    let (fl, fl_se) = st(&fp); show("capped: flat simulation, std error", &[fl, fl_se]);
    let (he, he_se) = st(&hp); show("capped: Heston simulation, std error", &[he, he_se]);
    let (lo, lo_se) = st(&lp); show("capped: local vol simulation, std error", &[lo, lo_se]);
    let (gap, gap_se) = stats(&(0..NP).map(|i| 100.0 * dd * (hp[i].capped - lp[i].capped)).collect::<Vec<_>>());
    show("Heston minus local vol, std error", &[gap, gap_se]); show("Heston minus flat", &[he - fl]);
    for (nm, a) in [("Heston", &hp), ("local vol", &lp), ("flat", &fp)] {
        show(&format!("{}: P(cap), P(floor), no floor", nm), &[a.iter().map(|p| p.ncap).sum::<f64>() / (4.0 * npf),
            a.iter().map(|p| p.nflo).sum::<f64>() / (4.0 * npf), 100.0 * dd * a.iter().map(|p| p.c).sum::<f64>() / npf]);
    }
    show("wrong: no global floor", &[100.0 * dd * 4.0 * ec]); show("wrong: local floor 0, no global", &[100.0 * dd * 4.0 * ep]);
    let mut atm1y = [0.0; 2];
    for (nm, a) in [("Heston", &hp), ("local vol", &lp), ("flat", &fp)] {
        let iv: Vec<f64> = (0..5).map(|i| 100.0 * implied(a.iter().map(|p| p.fwd[i]).sum::<f64>() / npf * (-R * tau).exp(), KS[i], tau)).collect();
        showp(&format!("forward smile Q4, {} (%)", nm), &iv, 2);
    }
    for (c, (nm, a)) in [("Heston", &hp), ("local vol", &lp)].into_iter().enumerate() {
        let iv: Vec<f64> = (0..5).map(|i| 100.0 * implied(a.iter().map(|p| p.van[i]).sum::<f64>() / npf * dd, KS[i], T)).collect();
        showp(&format!("1-year smile, {} (%)", nm), &iv, 2); atm1y[c] = iv[2];
    }
    let hump: Vec<f64> = [0.10, 0.15, 0.20, 0.25, 0.30].iter().map(|&s| conv_price(s, CAP, FLO, 0.0, R).0).collect();
    showp("flat price at vol 10,15,20,25,30%", &hump, 2);
    show("vega per vol point (19% to 21%)", &[(conv_price(0.21, CAP, FLO, 0.0, R).0 - conv_price(0.19, CAP, FLO, 0.0, R).0) / 2.0]);
    show("rho per rate point (4% to 6%)", &[(conv_price(SIG, CAP, FLO, 0.0, 0.06).0 - conv_price(SIG, CAP, FLO, 0.0, 0.04).0) / 2.0]);
    show("try: global floor 2%", &[conv_price(SIG, CAP, FLO, 0.02, R).0]); show("try: cap 10%, floor -10%", &[conv_price(SIG, 0.10, -0.10, 0.0, R).0]);
    let rs = [-10.0, -7.5, -5.0, -2.5, 0.0, 2.5, 5.0, 7.5, 10.0f64];
    showp("coupon (%) at return -10..10 by 2.5", &rs.map(|x| 100.0 * (x / 100.0).max(FLO).min(CAP)), 2);
    showp("uncapped coupon (%), same returns", &rs.map(|x| 100.0 * (x / 100.0).max(0.0)), 2);
    let path = [0.08, -0.03, 0.02, -0.07f64]; let cs: f64 = path.iter().map(|x| x.max(FLO).min(CAP)).sum();
    show("path +8,-3,+2,-7%: sum, paid, uncapped", &[100.0 * cs, 100.0 * cs.max(0.0), 100.0 * path.iter().map(|x| x.max(0.0)).sum::<f64>()]);

    assert!((unc - 4.0 * leg).abs() < 3.0 * unc_se, "uncapped: simulation must match four forward-start closed forms");
    assert!((fl - cv).abs() < 3.0 * fl_se, "capped, flat: simulation must match convolution");
    assert!((fs_house - 6.244873).abs() < 1e-6, "forward-start must match the shelf's house number");
    assert!((atm1y[0] - atm1y[1]).abs() < 0.3, "local vol must reprice Heston's 1-year ATM call");
    assert!(gap > 5.0 * gap_se, "Heston and local vol must disagree on the cliquet");
    println!("All checks passed.");
}
