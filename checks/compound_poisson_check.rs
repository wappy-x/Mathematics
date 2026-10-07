// Compound Poisson -- the same check as the Python, in Rust.  No crates.
// Insurance claims arrive at 4 an hour; each is $100, $500 or $2,000 with
// chances 0.5, 0.3 and 0.2.  S(t) is the total claimed by hour t.  Roads to its
// mean, variance and moment generating function: the formulas; the exact law of
// S(t), built by conditioning on the count and adding claim laws; the hour cut
// into m slots with at most one claim each; and 20000 simulated hours.
const LAM: f64 = 4.0;
const SIZES: [u64; 3] = [100, 500, 2000];
const PROBS: [f64; 3] = [0.5, 0.3, 0.2];
const SEED: u64 = 20260929;
const HOURS: usize = 20000;
const DIAL: f64 = 0.0002;
const BIG: f64 = 10000.0;

fn claim_moment(k: i32) -> f64 {                    // E[Y^k], the claim law's k-th moment
    (0..3).map(|i| PROBS[i] * (SIZES[i] as f64).powi(k)).sum()
}

fn m_claim(s: f64) -> f64 {                         // M_Y(s) = E[e^(sY)]
    (0..3).map(|i| PROBS[i] * (s * SIZES[i] as f64).exp()).sum()
}

fn m_total(s: f64, lt: f64) -> f64 {                // the card's formula: exp(lt (M_Y(s) - 1))
    (lt * (m_claim(s) - 1.0)).exp()
}

fn exact_law(lt: f64) -> (Vec<f64>, f64) {          // P(S = 100 x) for x = 0, 1, 2, ...
    let nmax = (lt + 12.0 * lt.sqrt() + 30.0) as usize;
    let top = (SIZES[2] / 100) as usize;             // grid steps of $100 in the largest claim
    let size = top * (nmax + 1) + 1;
    let (mut law, mut conv) = (vec![0.0; size], vec![0.0; size]);
    conv[0] = 1.0;
    let (mut pn, mut kept) = ((-lt).exp(), 0.0);
    for n in 0..=nmax {                             // conv = law of n claims added up
        for x in 0..=top * n { law[x] += pn * conv[x] }
        kept += pn;
        let mut new = vec![0.0; size];
        for x in 0..=top * n {
            for i in 0..3 { new[x + (SIZES[i] / 100) as usize] += conv[x] * PROBS[i] }
        }
        conv = new;
        pn = pn * lt / (n + 1) as f64;
    }
    (law, 1.0 - kept)
}

fn summary(law: &[f64]) -> (f64, f64, f64) {        // mean, variance, third central moment
    let mean: f64 = law.iter().enumerate().map(|(x, q)| 100.0 * x as f64 * q).sum();
    let var: f64 = law.iter().enumerate().map(|(x, q)| (100.0 * x as f64 - mean).powi(2) * q).sum();
    let third: f64 = law.iter().enumerate().map(|(x, q)| (100.0 * x as f64 - mean).powi(3) * q).sum();
    (mean, var, third)
}

struct SplitMix64 { s: u64 }                        // the wing's generator, written out
impl SplitMix64 {
    fn uniform(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}

fn claims_until(g: &mut SplitMix64, t: f64) -> Vec<(f64, u64)> {  // exponential gaps, then sizes
    let (mut clock, mut out) = (0.0, Vec::new());
    loop {
        clock += -(1.0 - g.uniform()).ln() / LAM;
        if clock > t { return out }
        let u = g.uniform();
        out.push((clock, if u < 0.5 { 100 } else if u < 0.8 { 500 } else { 2000 }));
    }
}

fn join(v: &[f64]) -> String { v.iter().map(|q| format!("{:.2}", 100.0 * q)).collect::<Vec<_>>().join(", ") }

fn main() {
    let (mu, m2, m3) = (claim_moment(1), claim_moment(2), claim_moment(3));
    println!("claims: {:.0} an hour, sizes {:?} with chances {:?}", LAM, SIZES, PROBS);
    println!("claim law: mean {:.2}, E[Y^2] {:.2}, Var(Y) {:.2}, E[Y^3] {:.0}", mu, m2, m2 - mu * mu, m3);
    for i in 0..3 {
        let a = SIZES[i] as f64;
        println!("split stream of ${} claims: rate {:.1} an hour, adds {:.0} to the variance, {:.1} percent of it",
                 SIZES[i], LAM * PROBS[i], a * a * LAM * PROBS[i], 100.0 * a * a * PROBS[i] / m2);
    }
    let mut law1 = Vec::new();
    for t in [1.0f64, 8.0] {
        let lt = LAM * t;
        let (law, lost) = exact_law(lt);
        let (em, ev, e3) = summary(&law);
        let mgf_exact: f64 = law.iter().enumerate().map(|(x, q)| q * (DIAL * 100.0 * x as f64).exp()).sum();
        println!("t = {} h  formula  mean {:.2}  var {:.2}  sd {:.2}  third {:.4}e9  M({}) {:.6}",
                 t, lt * mu, lt * m2, (lt * m2).sqrt(), lt * m3 / 1e9, DIAL, m_total(DIAL, lt));
        println!("t = {} h  exact    mean {:.2}  var {:.2}  sd {:.2}  third {:.4}e9  M({}) {:.6}",
                 t, em, ev, ev.sqrt(), e3 / 1e9, DIAL, mgf_exact);
        println!("t = {} h  skewness {:.4}; P(S = 0) {:.6} = e^-{:.0}; chance left out below 1e-12: {}",
                 t, lt * m3 / (lt * m2).powf(1.5), law[0], lt, if lost < 1e-12 { "yes" } else { "no" });
        assert!((em - lt * mu).abs() < 1e-6 * lt * mu && (ev - lt * m2).abs() < 1e-6 * lt * m2);
        assert!((e3 - lt * m3).abs() < 1e-6 * lt * m3);                // third cumulant = lt E[Y^3]
        assert!((mgf_exact / m_total(DIAL, lt) - 1.0).abs() < 1e-9);
        if t == 1.0 { law1 = law }
    }
    println!("M_Y({}) = {:.6}; exponent {:.0} x {:.6} = {:.6}", DIAL, m_claim(DIAL), LAM, m_claim(DIAL) - 1.0, LAM * (m_claim(DIAL) - 1.0));
    let mut mgf_m = 0.0;
    for m in [10.0f64, 100.0, 1000.0, 10000.0] {        // the hour in m slots, one claim at most each
        let p = LAM / m;
        let var_m = m * (p * m2 - (p * mu).powi(2));
        mgf_m = (m * (1.0 + p * (m_claim(DIAL) - 1.0)).ln()).exp();
        println!("slots m = {:5}: var {:.2} (short by {:.2}), M({}) {:.6} (short by {:.6})",
                 m, var_m, LAM * m2 - var_m, DIAL, mgf_m, m_total(DIAL, LAM) - mgf_m);
        let lnm = |s: f64| m * (p * (m_claim(s) - 1.0)).ln_1p();   // ln of the slot MGF
        assert!(((lnm(1e-6) + lnm(-1e-6)) / 1e-12 / var_m - 1.0).abs() < 1e-5);   // its curvature at 0 = variance
    }
    assert!((mgf_m / m_total(DIAL, LAM) - 1.0).abs() < 1e-4);
    let mut g = SplitMix64 { s: SEED + 1 };
    let totals: Vec<f64> = (0..HOURS).map(|_| claims_until(&mut g, 1.0).iter().map(|c| c.1 as f64).sum()).collect();
    let n = totals.len() as f64;
    let sm = totals.iter().sum::<f64>() / n;
    let c2 = totals.iter().map(|x| (x - sm).powi(2)).sum::<f64>() / n;
    let c4 = totals.iter().map(|x| (x - sm).powi(4)).sum::<f64>() / n;
    let sv = c2 * n / (n - 1.0);
    let es: Vec<f64> = totals.iter().map(|x| (DIAL * x).exp()).collect();
    let se_m = es.iter().sum::<f64>() / n;
    let sd_e = (es.iter().map(|e| (e - se_m).powi(2)).sum::<f64>() / (n - 1.0)).sqrt();
    let zeros = totals.iter().filter(|&&x| x == 0.0).count() as f64 / n;
    println!("simulated {} hours: mean {:.2} +- {:.2}, var {:.0} +- {:.0}, M({}) {:.4} +- {:.4}, P(S = 0) {:.4} +- {:.4}",
             HOURS, sm, (sv / n).sqrt(), sv, ((c4 - c2 * c2) / n).sqrt(), DIAL, se_m, sd_e / n.sqrt(), zeros, (zeros * (1.0 - zeros) / n).sqrt());
    assert!((sm - LAM * mu).abs() < 4.0 * (sv / n).sqrt() && (sv - LAM * m2).abs() < 4.0 * ((c4 - c2 * c2) / n).sqrt());
    assert!((se_m - m_total(DIAL, LAM)).abs() < 4.0 * sd_e / n.sqrt());
    assert!((zeros - (-LAM).exp()).abs() < 4.0 * (zeros * (1.0 - zeros) / n).sqrt());
    let mut bands: Vec<f64> = (0..10).map(|b| law1[10 * b..10 * b + 10].iter().sum()).collect();
    bands.push(law1[100..].iter().sum());
    let simb: Vec<f64> = (0..11).map(|b| totals.iter().filter(|&&x| ((x as u64) / 1000).min(10) == b).count() as f64 / n).collect();
    println!("figure, exact P(S(1) in $1000 band 0..9, then 10000 up), percent: {}", join(&bands));
    println!("figure, simulated, same bands, percent: {}", join(&simb));
    println!("figure, standard error of each simulated band, percent: {}", join(&simb.iter().map(|q| (q * (1.0 - q) / n).sqrt()).collect::<Vec<_>>()));
    let (mut lo, mut hi) = (0.0f64, 0.003f64);          // Chernoff: minimise e^(-s x) M_S(s) over s
    for _ in 0..200 {
        let (a, b) = (lo + (hi - lo) / 3.0, hi - (hi - lo) / 3.0);
        if -a * BIG + LAM * (m_claim(a) - 1.0) < -b * BIG + LAM * (m_claim(b) - 1.0) { hi = b } else { lo = a }
    }
    let bound = (-lo * BIG + LAM * (m_claim(lo) - 1.0)).exp();
    println!("tail: exact P(S(1) >= {}) {:.6}; MGF bound {:.6} at s = {:.6} per dollar", BIG, bands[10], bound, lo);
    assert!(bands[10] <= bound && bound < 1.0);
    let path = claims_until(&mut SplitMix64 { s: SEED }, 8.0);
    let grid: Vec<String> = (0..33).map(|k| path.iter().filter(|c| c.0 <= k as f64 / 4.0).map(|c| c.1).sum::<u64>().to_string()).collect();
    println!("figure, one simulated shift, total every 15 minutes: {}", grid.join(", "));
    println!("figure, that shift: {} claims, total {}, largest claim {}", path.len(), grid[32], path.iter().map(|c| c.1).max().unwrap());
    let (calm, storm) = (exact_law(2.0).0, exact_law(6.0).0);
    let mix: Vec<f64> = (0..storm.len()).map(|x| 0.5 * (if x < calm.len() { calm[x] } else { 0.0 }) + 0.5 * storm[x]).collect();
    let mv = summary(&mix).1;
    println!("mistake, variance from claim spread only, lt Var(Y): {:.2}, sd {:.2}, missing {:.1} percent",
             LAM * (m2 - mu * mu), (LAM * (m2 - mu * mu)).sqrt(), 100.0 * mu * mu / m2);
    println!("mistake, variance from the count only, Var(N) mu^2: {:.2}", LAM * mu * mu);
    println!("mistake, rate 2 or 6 an hour at random: exact var {:.2}, P(S = 0) {:.6}; formula at rate 4 says {:.2}", mv, mix[0], LAM * m2);
    assert!((mv - (4.0 * (m2 - mu * mu) + 8.0 * mu * mu)).abs() < 1e-6 * mv);   // E[N] Var(Y) + Var(N) mu^2: 4 and 8
    println!("ALL CHECKS PASS");
}
