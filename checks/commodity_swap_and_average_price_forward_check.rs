// Commodity swap and average-price forward -- the same check as the Python, in Rust.  std only.
// Twelve-month jet fuel swap, 10,000 bbl a month, 22 pricing days a month, paid at each month end.
// The random numbers are the same splitmix64 generator written out, so both scripts draw alike.
// Compile: rustc --edition 2021 -O commodity_swap_and_average_price_forward_check.rs -o /tmp/<dir>/chk
use std::f64::consts::PI;

const N_BBL: f64 = 10000.0;
const R: f64 = 0.05;
const DAYS: usize = 22;
const STRIP: [f64; 12] = [100.00, 100.36, 100.73, 101.09, 101.45, 101.82, 102.18, 102.55, 102.91, 103.27, 103.64, 104.00];
const MOVED: [f64; 12] = [103.00, 103.18, 103.36, 103.55, 103.73, 103.91, 104.09, 104.27, 104.45, 104.64, 104.82, 105.00];
const REALISED: f64 = 102.60;
const DONE: usize = 11;

fn disc(t0: f64, rate: f64) -> Vec<f64> { (0..12).map(|i| (-rate * ((i + 1) as f64 / 12.0 - t0)).exp()).collect() }
fn fair(c: &[f64], d: &[f64]) -> f64 { d.iter().zip(c).map(|(a, b)| a * b).sum::<f64>() / d.iter().sum::<f64>() }
fn pv(c: &[f64], k: f64, d: &[f64]) -> f64 { N_BBL * d.iter().zip(c).map(|(a, f)| a * (f - k)).sum::<f64>() }

fn bisect<G: Fn(f64) -> f64>(g: G, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if (g(lo) > 0.0) == (g(mid) > 0.0) { lo = mid; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}

struct Rng { s: u64 }
impl Rng {
    fn u(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn z(&mut self) -> f64 { let a = self.u(); let b = self.u(); (-2.0 * (1.0 - a).ln()).sqrt() * (2.0 * PI * b).cos() }
}

// road 3: month i's contract wanders as F_i exp(sigma W - sigma^2 (t - t0) / 2), one shared W.
fn simulate<P: Fn(&[f64]) -> Vec<f64>>(curve: &[f64], sigma: f64, pairs: usize, payoff: P,
                                       t0: f64, banked: usize, banked_avg: f64) -> (Vec<f64>, Vec<f64>) {
    let (mut rng, h, k) = (Rng { s: 7 }, 1.0 / (12.0 * DAYS as f64), payoff(&[curve[0]; 12]).len());
    let (mut acc, mut acc2) = (vec![0.0; k], vec![0.0; k]);
    for _ in 0..pairs {
        let zs: Vec<f64> = (0..12 * DAYS).map(|_| rng.z()).collect();
        let mut pair = vec![0.0; k];
        for sgn in [1.0, -1.0] {
            let (mut w, mut t, mut avgs) = (0.0_f64, t0, Vec::new());
            for i in 0..12 {
                let (mut s, n0) = if i == 0 { (banked_avg * banked as f64, banked) } else { (0.0, 0) };
                for j in n0..DAYS {
                    let tj = (i * DAYS + j + 1) as f64 * h;
                    w += sgn * sigma * (tj - t).sqrt() * zs[i * DAYS + j];
                    t = tj;
                    s += curve[i] * (w - 0.5 * sigma * sigma * (tj - t0)).exp();
                }
                avgs.push(s / DAYS as f64);
            }
            for (p, v) in pair.iter_mut().zip(payoff(&avgs)) { *p += 0.5 * v; }
        }
        for j in 0..k { acc[j] += pair[j]; acc2[j] += pair[j] * pair[j]; }
    }
    let m: Vec<f64> = acc.iter().map(|a| a / pairs as f64).collect();
    let se = acc2.iter().zip(&m).map(|(b, mm)| ((b / pairs as f64 - mm * mm) / pairs as f64).sqrt()).collect();
    (m, se)
}

fn main() {
    // ---- at inception ----
    let d0 = disc(0.0, R);
    let k = fair(&STRIP, &d0);
    let k_root = bisect(|x| pv(&STRIP, x, &d0), 90.0, 110.0);
    let (annuity, simple) = (d0.iter().sum::<f64>(), STRIP.iter().sum::<f64>() / 12.0);
    println!("annuity, sum of 12 discount factors    {:14.6}", annuity);
    println!("sum of D(t_i) F_i over the 12 months   {:14.6}", d0.iter().zip(&STRIP).map(|(d, f)| d * f).sum::<f64>());
    println!("road 1  fair fixed price, weighted     {:14.6}", k);
    println!("road 2  fair fixed price, bisection    {:14.6}", k_root);
    let mut sim = Vec::new();
    for sig in [0.20, 0.40] {
        let cap = |a: &[f64]| vec![fair(a, &d0), pv(a, k, &d0), N_BBL * d0[11] * (a[11] - k).max(0.0)];
        let (m, se) = simulate(&STRIP, sig, 20000, cap, 0.0, 0, 0.0);
        println!("road 3  vol {:.2}: fair price          {:14.6}   se {:.6}", sig, m[0], se[0]);
        println!("        vol {:.2}: swap value at K, $  {:14.2}   se {:.2}", sig, m[1], se[1]);
        println!("        vol {:.2}: month-12 cap, $     {:14.2}   se {:.2}", sig, m[2], se[2]);
        sim.push((m, se));
    }
    println!("month  forward   D(t_i)    gap F-K   PV of gap $   delta $ per $1");
    for i in 0..12 {
        println!("{:5} {:8.2} {:8.5} {:10.4} {:13.2} {:13.2}", i + 1, STRIP[i], d0[i], STRIP[i] - k,
                 N_BBL * d0[i] * (STRIP[i] - k), N_BBL * d0[i]);
    }
    println!("parallel delta, $ per $1 on all months {:14.2}", N_BBL * annuity);
    println!("rho, $ for rates up 1 percent          {:14.2}", pv(&STRIP, k, &disc(0.0, R + 0.01)));
    let chart: Vec<String> = (96..109).step_by(2).map(|a| format!("{:.2}", N_BBL * (a as f64 - k) / 1000.0)).collect();
    println!("chart, one month's net cash at avg 96..108, $000: {}", chart.join(" "));

    // ---- that afternoon the strip moves: front up 3, back up 1 ----
    let k_new = fair(&MOVED, &d0);
    let (m_gaps, m_offset) = (pv(&MOVED, k, &d0), N_BBL * (k_new - k) * annuity);
    println!("moved: new fair fixed price            {:14.6}", k_new);
    println!("moved: gap, new fair price minus K    {:14.6}", k_new - k);
    println!("moved: mark, discounted sum of gaps, $ {:14.2}", m_gaps);
    println!("moved: mark, offsetting swap, $        {:14.2}", m_offset);

    // ---- mid-month 1: 11 fixings banked at 102.60, curve as moved ----
    let t0 = DONE as f64 / (12.0 * DAYS as f64);
    let d1 = disc(t0, R);
    let month1 = |f1: f64| (DONE as f64 * REALISED + (DAYS - DONE) as f64 * f1) / DAYS as f64;
    let mut e = MOVED.to_vec();
    e[0] = month1(MOVED[0]);
    let mark_mid = pv(&e, k, &d1);
    let mark_off = N_BBL * (fair(&e, &d1) - k) * d1.iter().sum::<f64>();
    let (mc, se) = simulate(&MOVED, 0.20, 20000, |a: &[f64]| vec![pv(a, k, &d1)], t0, DONE, REALISED);
    let mut e_b = e.clone();
    e_b[0] = month1(MOVED[0] + 1.0);
    let delta1 = pv(&e_b, k, &d1) - mark_mid;
    let wrong_unbanked = pv(&MOVED, k, &d1);
    println!("mid-month: month 1 expected average    {:14.6}", e[0]);
    println!("mid-month: month 1 discount factor    {:14.6}", d1[0]);
    println!("mid-month: mark, formula, $            {:14.2}", mark_mid);
    println!("mid-month: mark, offsetting swap, $    {:14.2}", mark_off);
    println!("mid-month: mark, simulated, $          {:14.2}   se {:.2}", mc[0], se[0]);
    println!("mid-month: month 1 delta by bump, $    {:14.2}", delta1);
    println!("wrong: plain average as fixed price    {:14.6}", simple);
    println!("  its value to the fixed payer, $      {:14.2}", pv(&STRIP, simple, &d0));
    println!("wrong: fixed at today's front 100, $   {:14.2}", pv(&STRIP, 100.0, &d0));
    println!("wrong: moved mark undiscounted, $      {:14.2}", N_BBL * MOVED.iter().map(|f| f - k).sum::<f64>());
    println!("wrong: mid-month, banked half ignored  {:14.2}", wrong_unbanked);
    let rev: Vec<f64> = STRIP.iter().rev().cloned().collect();
    println!("try: rates at zero, fair price        {:14.6}", fair(&STRIP, &disc(0.0, 0.0)));
    println!("try: strip reversed, fair price        {:14.6}", fair(&rev, &d0));
    println!("try: rates at 10 percent, fair price   {:14.6}", fair(&STRIP, &disc(0.0, 0.10)));
    let bars: Vec<String> = [22.0, 16.0, 11.0, 6.0, 0.0].iter().map(|n| format!("{:.2}", N_BBL * n / DAYS as f64)).collect();
    println!("bars, month 1 barrels still exposed, fixings left 22 16 11 6 0: {}", bars.join(" "));

    assert!((k - k_root).abs() < 1e-9, "closed form vs bisection on the value");
    assert!((annuity - (-R / 12.0).exp() * (1.0 - (-R).exp()) / (1.0 - (-R / 12.0).exp())).abs() < 1e-9, "annuity vs geometric series");
    assert!((sim[0].0[0] - k).abs() < 4.0 * sim[0].1[0], "simulated fair price at 20% vol");
    assert!((sim[1].0[0] - k).abs() < 4.0 * sim[1].1[0], "simulated fair price at 40% vol");
    assert!(sim[1].0[2] > 1.5 * sim[0].0[2], "a cap on the average does depend on vol");
    assert!((m_gaps - m_offset).abs() < 1e-6, "sum of gaps vs offsetting swap");
    assert!((mark_off - mark_mid).abs() < 1e-6, "mid-month mark vs offsetting swap");
    assert!((mc[0] - mark_mid).abs() < 4.0 * se[0], "simulated mid-month mark");
    assert!((delta1 - N_BBL * d1[0] * (DAYS - DONE) as f64 / DAYS as f64).abs() < 1e-6, "month-1 delta scales with fixings left");
    println!("ALL CHECKS PASS");
}
