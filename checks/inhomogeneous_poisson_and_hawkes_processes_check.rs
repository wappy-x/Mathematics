// Time-varying Poisson and Hawkes -- the same check as the Python, in Rust.  Standard library only.
// Part A: calls at rate 4 + 3 sin(2 pi t/24) an hour; Part B: Hawkes calls, base rate 2 an hour,
// each call adds 1 an hour to the rate, fading at rate 2 an hour, so each triggers 0.5 more.
use std::f64::consts::PI;
struct Rng { s: u64 }
impl Rng {                                         // SplitMix64, written out
    fn u(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53)
    }
    fn expo(&mut self, rate: f64) -> f64 { -(1.0 - self.u()).ln() / rate }
    fn poisson(&mut self, mean: f64) -> usize {   // inversion: walk up the cumulative chances
        let u = self.u();
        let (mut k, mut p) = (0usize, (-mean).exp());
        let mut c = p;
        while u > c { k += 1; p *= mean / k as f64; c += p; }
        k
    }
}
fn rate(t: f64) -> f64 { 4.0 + 3.0 * (2.0 * PI * t / 24.0).sin() }
fn big_lam(t: f64) -> f64 { 4.0 * t + (36.0 / PI) * (1.0 - (PI * t / 12.0).cos()) }
fn stats(xs: &[f64]) -> (f64, f64, f64) {
    let n = xs.len() as f64;
    let m = xs.iter().fold(0.0, |a, x| a + x) / n;
    let v = xs.iter().fold(0.0, |a, x| a + (x - m).powi(2)) / (n - 1.0);
    (m, v, (v / n).sqrt())
}
const T: f64 = 12.0; const PEAK: f64 = 7.0; const R: usize = 10000;
const MU: f64 = 2.0; const NB: f64 = 0.5; const BETA: f64 = 2.0; const JUMP: f64 = NB * BETA;
fn thin(rng: &mut Rng, prop: f64) -> (f64, f64) { // propose at rate prop, keep with chance rate/prop
    let (mut t, mut kept, mut made) = (0.0, 0.0, 0.0);
    loop {
        t += rng.expo(prop);
        if t > T { return (kept, made); }
        made += 1.0;
        if rng.u() * prop < rate(t).min(prop) { kept += 1.0; }
    }
}
fn stretched(rng: &mut Rng, cum: &[f64], h: f64) -> (f64, f64) { // unit-rate gaps, each total mapped back to a time through cum
    let (mut s, mut k) = (0.0, [0.0, 0.0]);
    loop {
        s += rng.expo(1.0);
        let i = cum.partition_point(|&c| c <= s);  // cum[i - 1] <= s < cum[i]
        if i >= cum.len() { return (k[0], k[1]); } // the mapped time is past noon
        let t = ((i - 1) as f64 + (s - cum[i - 1]) / (cum[i] - cum[i - 1])) * h; // Lambda(t) = s, straight line between steps
        k[(t > 3.0) as usize] += 1.0;              // before 3 am, or from 3 am to noon
    }
}
fn hawkes(rng: &mut Rng, hor: f64) -> Vec<f64> {  // thinning on the rate, which only fades between calls
    let (mut t, mut x, mut ev) = (0.0, 0.0, Vec::new());
    loop {
        let bound = MU + x; let w = rng.expo(bound); t += w;
        if t > hor { return ev; }
        x *= (-BETA * w).exp();
        if rng.u() * bound < MU + x { ev.push(t); x += JUMP; }
    }
}
fn main() {
    let exact = big_lam(T);
    let n = 1200; let h = T / n as f64;            // Simpson's rule on the rate, step by step: cum[i] = Lambda(i h)
    let cum = (0..n).fold(vec![0.0], |mut c: Vec<f64>, i| { let l = c[i]; c.push(l + (rate(i as f64 * h) + 4.0 * rate((i as f64 + 0.5) * h) + rate((i + 1) as f64 * h)) * h / 6.0); c });
    println!("A base part 4 x 12                  {:10.4}", 4.0 * T);
    println!("A wave part 72/pi                   {:10.4}", 72.0 / PI);
    println!("A expected calls to noon, formula   {:10.4}", exact);
    println!("A expected calls to noon, Simpson   {:10.4}", cum[n]);
    println!("A expected calls in 24 hours        {:10.4}", big_lam(24.0));
    println!("A spread of the noon count sqrt     {:10.4}", exact.sqrt());
    println!("A proposals at peak 7 x 12          {:10.4}", PEAK * T);
    println!("A share of proposals kept           {:10.4}", exact / (PEAK * T));
    let hours: Vec<String> = (0..25).map(|k| format!("{:.2}", rate(k as f64))).collect();
    println!("A rate by hour 0..24  {}", hours.join(" "));
    let mut rng = Rng { s: 20261123 };
    let runs: Vec<(f64, f64)> = (0..R).map(|_| thin(&mut rng, PEAK)).collect();
    let (m1, v1, se1) = stats(&runs.iter().map(|r| r.0).collect::<Vec<_>>());
    let (mp, _, _) = stats(&runs.iter().map(|r| r.1).collect::<Vec<_>>());
    let st: Vec<(f64, f64)> = (0..R).map(|_| stretched(&mut rng, &cum, h)).collect();
    let (m2, v2, se2) = stats(&st.iter().map(|k| k.0 + k.1).collect::<Vec<_>>()); let (m3, _, se3) = stats(&st.iter().map(|k| k.0).collect::<Vec<_>>());
    println!("A sim thinning: mean {:.3} se {:.3}  variance {:.2}  proposals {:.3}", m1, se1, v1, mp);
    println!("A sim stretched time: mean {:.3} se {:.3}  variance {:.2}  before 3 am {:.3} se {:.3}  (Lambda(3) {:.4}, even spread {:.4})", m2, se2, v2, m3, se3, big_lam(3.0), exact / 4.0);
    let simp_low = (0..n).fold(0.0, |a, i| a + (rate(i as f64 * h).min(5.0) + 4.0 * rate((i as f64 + 0.5) * h).min(5.0) + rate((i + 1) as f64 * h).min(5.0)) * h / 6.0); // wrong: 5
    println!("A wrong: rate at noon x 12          {:10.4}", rate(12.0) * T);
    println!("A wrong: keep every peak proposal   {:10.4}", PEAK * T);
    println!("A wrong: propose at 5, not 7        {:10.4}", simp_low);
    let mut lam = MU;
    for _ in 0..60 { lam = MU + NB * lam; }        // fixed point of rate = base + n x rate
    let series = (0..60).fold(0.0, |a, k| a + NB.powi(k));
    println!("B long-run rate mu/(1-n)            {:10.4}", MU / (1.0 - NB));
    println!("B fixed-point iteration             {:10.4}", lam);
    println!("B mean cluster 1/(1-n)              {:10.4}", 1.0 / (1.0 - NB));
    println!("B geometric series 1+n+n^2+...      {:10.4}", series);
    let parts: Vec<String> = (0..6).map(|k| format!("{:.4}", (0..k + 1).fold(0.0, |a, j| a + NB.powi(j)))).collect();
    println!("B series partial sums  {}", parts.join(" "));
    let (mut borel, mut lf) = (Vec::new(), 0.0f64);  // Borel law: P(k) = e^-nk (nk)^(k-1) / k!
    for k in 1..=4000 {
        let kf = k as f64;
        lf += kf.ln(); borel.push((-NB * kf + (kf - 1.0) * (NB * kf).ln() - lf).exp());
    }
    let b4: Vec<String> = borel[..4].iter().map(|p| format!("{:.4}", p)).collect();
    println!("B Borel P(cluster=1..4)  {}", b4.join(" "));
    let bmean = borel.iter().enumerate().fold(0.0, |a, (k, p)| a + (k as f64 + 1.0) * p);
    let bsq = borel.iter().enumerate().fold(0.0, |a, (k, p)| a + (k as f64 + 1.0).powi(2) * p);
    let btot = borel.iter().fold(0.0, |a, p| a + p);
    println!("B Borel total {:.6}  mean {:.6}  variance {:.6}", btot, bmean, bsq - bmean * bmean);
    println!("B long-window variance per hour 2 E[S^2]  {:.4}", MU * bsq);
    let var12 = 4.0 * T + 12.0 * (T - (1.0 - (-T).exp()));   // stationary 12-hour variance, covariance 6 e^-|s|
    let empty12 = 4.0 * T - 2.0 * (1.0 - (-T).exp());       // mean 12-hour count from an empty start
    println!("B 12-hour count: mean {:.4}  variance {:.4}  Poisson would say {:.4}", 4.0 * T, var12, 4.0 * T);
    println!("B 12-hour mean from an empty start {:.4};  rate after 1 hour {:.4}", empty12, 4.0 - 2.0 * (-1.0f64).exp());
    let hh = 12.0 * 8400.0;                        // 8400 half-days
    let ev = hawkes(&mut rng, hh);
    let mut wins = vec![0.0; (hh / T) as usize];
    for e in &ev { wins[(e / T) as usize] += 1.0; }
    let (_, vw, _) = stats(&wins);
    let evn = ev.len() as f64;
    println!("B sim thinning, {:.0} hours: rate {:.4} se {:.4}  12-hour variance {:.2}", hh, evn / hh, 4.0 / hh.sqrt(), vw);
    let (e12, _, se12) = stats(&(0..R).map(|_| hawkes(&mut rng, T).len() as f64).collect::<Vec<_>>());
    println!("B sim empty start, 12 hours: mean {:.3} se {:.3}", e12, se12);
    let (mut sizes, mut inside, mut t, mut bygen) = (Vec::new(), 0usize, 0.0, [0usize; 5]); // family trees
    loop {
        t += rng.expo(MU);
        if t > hh { break; }
        let (mut gen, mut size, mut d) = (vec![t], 0usize, 0usize);
        while !gen.is_empty() {
            size += gen.len(); inside += gen.iter().filter(|g| **g <= hh).count();
            if d < 5 { bygen[d] += gen.len(); }
            let mut next = Vec::new();
            for g in &gen { for _ in 0..rng.poisson(NB) { next.push(g + rng.expo(BETA)); } }
            gen = next; d += 1;
        }
        sizes.push(size as f64);
    }
    let (ms, vs, ses) = stats(&sizes);
    let ones = sizes.iter().filter(|s| **s == 1.0).count() as f64 / sizes.len() as f64;
    println!("B sim trees: {} clusters  mean {:.4} se {:.4}  variance {:.3}", sizes.len(), ms, ses, vs);
    println!("B sim trees: lone calls {:.4}  rate {:.4}", ones, inside as f64 / hh);
    let gf: Vec<String> = (0..5).map(|d| format!("{:.4}", MU * NB.powi(d))).collect();
    println!("B rate by generation, formula  {}", gf.join(" "));
    let gt: Vec<String> = bygen.iter().map(|c| format!("{:.4}", *c as f64 / hh)).collect();
    println!("B rate by generation, trees    {}", gt.join(" "));
    let near: Vec<f64> = ev.iter().cloned().filter(|e| 92.0 < *e && *e < 106.0).collect();
    let pts: Vec<String> = (0..31).map(|i| 100.0 + 0.2 * i as f64).map(|s| format!("{:.2}",
        MU + near.iter().filter(|e| **e < s).fold(0.0, |a, e| a + JUMP * (-BETA * (s - e)).exp()))).collect();
    println!("B rate on hours 100-106 every 12 min  {}", pts.join(" "));
    for (i, c) in near.iter().filter(|e| **e > 100.0).take(5).enumerate() {
        let before = MU + near.iter().filter(|e| *e < c).fold(0.0, |a, e| a + JUMP * (-BETA * (c - e)).exp());
        println!("B story call {} at hour 100 + {:.2}  rate before {:.2}  after {:.2}", i + 1, c - 100.0, before, before + JUMP);
    }
    let calls: Vec<String> = near.iter().filter(|e| **e > 100.0).map(|e| format!("{:.2}", e - 100.0)).collect();
    println!("B calls on hours 100-106  {}", calls.join(" "));
    let top = near.iter().filter(|e| **e > 100.0).map(|&c| (MU + near.iter().filter(|e| **e <= c).fold(0.0, |a, e| a + JUMP * (-BETA * (c - e)).exp()), c)).fold((0.0, 0.0), |b, x| if x.0 > b.0 { x } else { b });
    println!("B top rate on hours 100-106: {:.2}, just after the call at hour 100 + {:.2}", top.0, top.1 - 100.0);
    println!("B wrong: first generation only mu(1+n)  {:.4}", MU * (1.0 + NB));
    println!("B try: n = 0.9   rate {:.4}  cluster {:.4}", MU / 0.1, 1.0 / 0.1);
    assert!((cum[n] - exact).abs() < 1e-9, "Simpson against the closed form");
    assert!((m1 - exact).abs() < 4.0 * se1 && (m2 - exact).abs() < 4.0 * se2, "both simulations hit 70.92");
    assert!((m3 - big_lam(3.0)).abs() < 4.0 * se3, "stretched clock: calls before 3 am hit Lambda(3)");
    assert!((v1 / m1 - 1.0).abs() < 0.05, "thinned count is Poisson: variance equals mean");
    assert!((lam - MU / (1.0 - NB)).abs() < 1e-12 && (bmean - 1.0 / (1.0 - NB)).abs() < 1e-9, "fixed point, Borel mean");
    assert!((evn / hh - 4.0).abs() < 4.0 * 4.0 / hh.sqrt() && (inside as f64 / hh - 4.0).abs() < 0.05, "both Hawkes roads give 4");
    assert!((ms - 2.0).abs() < 4.0 * ses && (ones - borel[0]).abs() < 0.005, "cluster mean 2, lone share e^-0.5");
    assert!((vw / var12 - 1.0).abs() < 0.1 && (e12 - empty12).abs() < 4.0 * se12, "12-hour variance and empty start");
    println!("ALL CHECKS PASS");
}
