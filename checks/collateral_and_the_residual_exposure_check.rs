// Collateral and the residual exposure -- the check behind the card.  Rust std only, no crates.
// Every number on the card is printed here.  The normal CDF, the root finder, the integrator
// and the random numbers are all written below.
use std::f64::consts::PI;

const S0: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02;
const SIG: f64 = 0.20; const T: f64 = 1.0; const LAM: f64 = 0.02; const LGD: f64 = 0.60;
const H: f64 = 2.0; const M: f64 = 0.5; const NB: usize = 12;

fn n_cdf(x: f64) -> f64 { // normal CDF, Hart's rational approximation (double precision)
    let a = x.abs(); let e = (-a * a / 2.0).exp();
    let c = if a > 37.0 { 0.0 } else if a < 7.07106781186547 {
        let p = (((((0.0352624965998911 * a + 0.700383064443688) * a + 6.37396220353165) * a + 33.912866078383) * a + 112.079291497871) * a + 221.213596169931) * a + 220.206867912376;
        let s = ((((((0.0883883476483184 * a + 1.75566716318264) * a + 16.064177579207) * a + 86.7807322029461) * a + 296.564248779674) * a + 637.333633378831) * a + 793.826512519948) * a + 440.413735824752;
        e * p / s
    } else { e / (a + 1.0 / (a + 2.0 / (a + 3.0 / (a + 4.0 / (a + 0.65))))) / 2.506628274631 };
    if x > 0.0 { 1.0 - c } else { c }
}

fn n_inv(p: f64) -> f64 { // root finder: bisection on the CDF
    let (mut lo, mut hi) = (-10.0_f64, 10.0_f64);
    for _ in 0..200 { let mid = (lo + hi) / 2.0; if n_cdf(mid) < p { lo = mid } else { hi = mid } }
    (lo + hi) / 2.0
}

fn mu() -> f64 { R - Q - SIG * SIG / 2.0 }

fn v(s: f64, t: f64) -> f64 { // the call's clean value at date t when Acme is at s
    let u = T - t;
    if u <= 1e-12 { return (s - K).max(0.0); }
    let d1 = ((s / K).ln() + (R - Q + SIG * SIG / 2.0) * u) / (SIG * u.sqrt());
    s * (-Q * u).exp() * n_cdf(d1) - K * (-R * u).exp() * n_cdf(d1 - SIG * u.sqrt())
}

struct Grid { z: Vec<f64>, w: Vec<f64> }

fn grid() -> Grid { // Simpson nodes and weights on [-8, 8], bell-curve height folded in
    let (nz, l) = (80usize, 8.0_f64); let hz = 2.0 * l / nz as f64;
    let z: Vec<f64> = (0..=nz).map(|i| -l + i as f64 * hz).collect();
    let w = z.iter().enumerate().map(|(i, &zz)| {
        let m = if i == 0 || i == nz { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        m * hz / 3.0 * (-zz * zz / 2.0).exp() / (2.0 * PI).sqrt()
    }).collect();
    Grid { z, w }
}

// Road 1: discounted expected residual at date t; lag = 0 means margin arrives instantly
fn ee(g: &Grid, t: f64, h: f64, lag: f64) -> f64 {
    let tl = (t - lag).max(0.0); let dl = t - tl; let mut tot = 0.0;
    for (&z1, &w1) in g.z.iter().zip(g.w.iter()) {
        let s1 = S0 * (mu() * tl + SIG * tl.sqrt() * z1).exp();
        if lag == 0.0 { tot += w1 * v(s1, t).min(h); continue; }
        let c = (v(s1, tl) - h).max(0.0); // collateral held: set at the last margin call, frozen since
        let mut inner = 0.0;
        for (&z2, &w2) in g.z.iter().zip(g.w.iter()) {
            inner += w2 * (v(s1 * (mu() * dl + SIG * dl.sqrt() * z2).exp(), t) - c).max(0.0);
        }
        tot += w1 * inner;
    }
    (-R * t).exp() * tot
}

fn cva(g: &Grid, h: f64, lag: f64, lam: f64) -> (f64, Vec<f64>) {
    let prof: Vec<f64> = (0..NB).map(|i| ee(g, (i as f64 + 0.5) / NB as f64, h, lag)).collect();
    let s: f64 = prof.iter().enumerate()
        .map(|(i, e)| ((-lam * i as f64 / NB as f64).exp() - (-lam * (i + 1) as f64 / NB as f64).exp()) * e).sum();
    (LGD * s, prof)
}

struct Rng(u64);
impl Rng { // xorshift64*, top 53 bits, never 0
    fn unif(&mut self) -> f64 {
        self.0 ^= self.0 >> 12; self.0 ^= self.0 << 25; self.0 ^= self.0 >> 27;
        ((self.0.wrapping_mul(2685821657736338717) >> 11) as f64 + 0.5) / 9007199254740992.0
    }
}

fn main() {
    let g = grid(); let lag = 10.0 / 252.0; let mu = mu();
    // Road 2: daily Monte Carlo paths, margin called every day, default on any day
    let (nd, lagd, pairs) = (252usize, 10usize, 2500usize); let dt = T / nd as f64;
    let wk: Vec<f64> = (0..=nd).map(|k| (-LAM * (k as f64 - 1.0) * dt).exp() - (-LAM * k as f64 * dt).exp()).collect();
    let dk: Vec<f64> = (0..=nd).map(|k| (-R * k as f64 * dt).exp()).collect();
    let mut rng = Rng(0x2545F4914F6CDD1D);
    let mut acc = vec![Vec::with_capacity(pairs); 5]; let mut moves = Vec::new(); let mut worst = -1.0_f64;
    for _ in 0..pairs {
        let zs: Vec<f64> = (0..nd).map(|_| { let u1 = rng.unif(); let u2 = rng.unif();
            (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos() }).collect();
        let mut pair = [0.0_f64; 5]; // none, thr, thr_mpor, zero_mpor, thr_mpor_mta
        for sgn in [1.0_f64, -1.0] { // antithetic: the same path and its mirror image
            let mut s = S0; let mut vv = vec![v(s, 0.0)];
            for k in 1..=nd { s *= (mu * dt + SIG * dt.sqrt() * sgn * zs[k - 1]).exp(); vv.push(v(s, k as f64 * dt)); }
            moves.push(vv[lagd] - vv[0]);
            let c2: Vec<f64> = vv.iter().map(|x| (x - H).max(0.0)).collect();
            let mut cm = Vec::with_capacity(nd + 1); let mut held = 0.0_f64;
            for &x in &vv { let tgt = (x - H).max(0.0); if (tgt - held).abs() >= M { held = tgt; } cm.push(held); }
            for k in 1..=nd {
                let j = k.saturating_sub(lagd); let f = wk[k] * dk[k] / 2.0;
                let res = (vv[k] - cm[j]).max(0.0);
                worst = worst.max(res - (H + M + (vv[k] - vv[j]).max(0.0)));
                pair[0] += f * vv[k]; pair[1] += f * vv[k].min(H);
                pair[2] += f * (vv[k] - c2[j]).max(0.0); pair[3] += f * (vv[k] - vv[j]).max(0.0);
                pair[4] += f * res;
            }
        }
        for c in 0..5 { acc[c].push(LGD * pair[c]); }
    }
    let np = pairs as f64; let mc: Vec<f64> = acc.iter().map(|a| a.iter().sum::<f64>() / np).collect();
    let se: Vec<f64> = acc.iter().zip(mc.iter())
        .map(|(a, m)| (a.iter().map(|x| (x - m) * (x - m)).sum::<f64>() / (np - 1.0) / np).sqrt()).collect();

    // the numbers
    let c0 = v(S0, 0.0); let pd1 = 1.0 - (-LAM * T).exp();
    let d1 = ((S0 / K).ln() + (R - Q + SIG * SIG / 2.0) * T) / (SIG * T.sqrt()); let delta = (-Q * T).exp() * n_cdf(d1);
    let cva_none = LGD * c0 * pd1;
    let (cva_thr, prof_thr) = cva(&g, H, 0.0, LAM);
    let (cva_mp, prof_mp) = cva(&g, H, lag, LAM);
    let (cva_zero, prof_zero) = cva(&g, 0.0, lag, LAM);
    let cap = LGD * H * LAM * (1.0 - (-(LAM + R) * T).exp()) / (LAM + R); // threshold-only can never exceed this
    let z99 = n_inv(0.99); let move_delta = z99 * delta * S0 * SIG * lag.sqrt();
    let move_full = v(S0 * (mu * lag + SIG * lag.sqrt() * z99).exp(), lag) - c0;
    moves.sort_by(|a, b| a.partial_cmp(b).unwrap()); let move_mc = moves[(0.99 * moves.len() as f64) as usize - 1];
    let envelope = LGD * pd1 * delta * S0 * SIG * lag.sqrt() / (2.0 * PI).sqrt(); // back of envelope, zero threshold
    let vm0 = c0 - H; let (h, fall) = (0.04, 0.03); let bonds = vm0 / (1.0 - h);
    let disc_pd: f64 = (0..NB).map(|i| { let t = (i as f64 + 0.5) / NB as f64;
        ((-LAM * i as f64 / NB as f64).exp() - (-LAM * (i + 1) as f64 / NB as f64).exp()) * (-R * t).exp() }).sum();
    let wrong_q99 = LGD * disc_pd * (H + move_delta);

    let rows: Vec<(&str, f64)> = vec![("clean call C0", c0), ("default chance in the year", pd1), ("call delta", delta),
        ("margin period in years (10/252)", lag),
        ("CVA, no collateral: closed form", cva_none), ("CVA, no collateral: Monte Carlo", mc[0]),
        ("  Monte Carlo standard error", se[0]),
        ("CVA, threshold 2, instant: Simpson", cva_thr), ("CVA, threshold 2, instant: Monte Carlo", mc[1]),
        ("  ceiling LGD x H x discounted PD", cap),
        ("CVA, threshold 2 + 10 days: Simpson", cva_mp), ("CVA, threshold 2 + 10 days: Monte Carlo", mc[2]),
        ("  Monte Carlo standard error", se[2]),
        ("CVA, threshold 0 + 10 days: Simpson", cva_zero), ("CVA, threshold 0 + 10 days: Monte Carlo", mc[3]),
        ("  Monte Carlo standard error", se[3]), ("  back of envelope", envelope),
        ("CVA, threshold 2 + 10 days + MTA 0.5: MC", mc[4]),
        ("worst residual minus bound H+M+move", worst),
        ("z at 99%", z99), ("99% ten-day move, delta rule", move_delta),
        ("99% ten-day move, full revaluation", move_full), ("99% ten-day move, Monte Carlo", move_mc),
        ("99% residual, threshold 2", H + move_delta),
        ("margin called today, threshold 2", vm0), ("bonds posted at 4% haircut", bonds),
        ("  after a 3% fall", bonds * (1.0 - fall)),
        ("  shortfall with no haircut", vm0 * fall),
        ("wrong: 99% move in place of average", wrong_q99),
        ("try: 20-day margin period, threshold 2", cva(&g, H, 2.0 * lag, LAM).0),
        ("try: 20-day margin period, threshold 0", cva(&g, 0.0, 2.0 * lag, LAM).0),
        ("try: hazard 4%, threshold 2 + 10 days", cva(&g, H, lag, 0.04).0)];
    for (name, x) in &rows { println!("{:<42} {:>12.6}", name, x); }
    println!("CVA against threshold H, 10-day margin period: dollars, cents");
    for hh in [0.0, 0.5, 1.0, 2.0, 3.0, 5.0, 10.0, f64::INFINITY] {
        let x = if hh != H { cva(&g, hh, lag, LAM).0 } else { cva_mp };
        println!("  H = {:>4.1} {:>12.6} {:>8.2}", hh, x, 100.0 * x);
    }
    println!("discounted expected residual, cents: instant thr 2 | thr 2 + 10d | thr 0 + 10d");
    for i in 0..NB {
        println!("  t = {:.4} {:>8.2} {:>8.2} {:>8.2}", (i as f64 + 0.5) / NB as f64, 100.0 * prof_thr[i], 100.0 * prof_mp[i], 100.0 * prof_zero[i]);
    }

    assert!((c0 - 9.227005508154).abs() < 1e-9);                     // house call, from the pilot card
    assert!((mc[0] - cva_none).abs() < 4.0 * se[0] + 2e-4);          // simulation meets the closed form
    assert!((mc[1] - cva_thr).abs() < 4.0 * se[1] + 2e-5);           // simulation meets Simpson
    assert!((mc[2] - cva_mp).abs() < 4.0 * se[2] + 2e-5);
    assert!((mc[3] - cva_zero).abs() < 4.0 * se[3] + 2e-5);
    assert!(cva_thr < cap); assert!(worst <= 1e-12);                 // the two bounds proved on the card
    assert!((envelope / cva_zero - 1.0).abs() < 0.1); assert!((move_mc - move_full).abs() < 0.4);
    println!("all checks passed");
}
