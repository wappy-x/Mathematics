// Stock: EOQ, reorder point and the newsvendor -- the check behind the card.
// std only.  The normal curve is built from its series, the quantile by bisection,
// random numbers by SplitMix64 (seed 2026).  Every number on the card is printed.
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }   // bell-curve height
fn big_phi(x: f64) -> f64 {                                          // area left of x, by series
    if x < -8.0 { return 0.0; }
    if x > 8.0 { return 1.0; }
    let (mut term, mut total, mut n) = (x, x, 0.0);
    while term.abs() > 1e-17 * total.abs() {
        n += 1.0;
        term = term * x * x / (2.0 * n + 1.0);
        total += term;
    }
    0.5 + phi(x) * total
}
fn quantile(p: f64) -> f64 {                                         // z with Phi(z) = p, by halving
    let (mut lo, mut hi) = (-8.0, 8.0);
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if big_phi(mid) < p { lo = mid; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}
fn g_loss(z: f64) -> f64 { phi(z) - z * (1.0 - big_phi(z)) }        // expected shortfall past z, in spreads

struct Rng(u64);
impl Rng {
    fn rand(&mut self) -> f64 {                                      // SplitMix64, a uniform in (0, 1)
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0 + 1.0 / 18014398509481984.0
    }
    fn normal(&mut self) -> f64 {                                    // Box-Muller
        let u = self.rand();
        let w = self.rand();
        (-2.0 * u.ln()).sqrt() * (2.0 * PI * w).cos()
    }
}

fn main() {
    let mut rng = Rng(2026);
    // ---- 1. EOQ: butter for the croissants, at the warehouse ----
    let (d, k, h) = (5200.0_f64, 125.0_f64, 2.60_f64);
    let cost = |q: f64| k * d / q + h * q / 2.0;
    let qs = (2.0 * k * d / h).sqrt();
    let mut best = 1;                                                // road 2: try every whole order size
    for q in 1..=3000 { if cost(q as f64) < cost(best as f64) { best = q; } }
    println!("EOQ inputs: D {:.0} cases/yr (100/week, 52 weeks), K {:.2}, h {:.2}", d, k, h);
    println!("Q* {:.4}  C(Q*) {:.4}  holding {:.4}  ordering {:.4}", qs, cost(qs), h * qs / 2.0, k * d / qs);
    println!("orders/yr {:.4}  weeks between {:.4}  scan best {}  C({}) {:.4}", d / qs, 52.0 * qs / d, best, best, cost(best as f64));
    println!("hand: 2KD {:.0}  2KD/h {:.0}", 2.0 * k * d, 2.0 * k * d / h);
    assert!(best == 707 && (cost(best as f64) - cost(qs)).abs() < 0.01);
    assert!((h * qs / 2.0 - k * d / qs).abs() < 1e-9);
    for r in [1.2, 0.8] {
        println!("  Q = Q* x {:.1} = {:.1}: C {:.2}, extra {:.2}%", r, r * qs, cost(r * qs), 100.0 * (cost(r * qs) / cost(qs) - 1.0));
    }
    let q2 = (k * d / h).sqrt();
    println!("wrong: drop the 2 -> Q {:.1}, C {:.2}, extra {:.2}%", q2, cost(q2), 100.0 * (cost(q2) / cost(qs) - 1.0));
    let qw = (2.0 * k * d / (h / 52.0)).sqrt();
    println!("wrong: h per week with D per year -> Q {:.1}, true cost {:.2}", qw, cost(qw));
    let qq: Vec<f64> = (2..=14).map(|i| 100.0 * i as f64).collect();
    let row = |f: &dyn Fn(f64) -> String| qq.iter().map(|&q| f(q)).collect::<Vec<_>>().join(" ");
    println!("chart Q: {}", row(&|q| format!("{}", q as i64)));
    println!("chart holding: {}", row(&|q| format!("{:.0}", h * q / 2.0)));
    println!("chart ordering: {}", row(&|q| format!("{:.0}", k * d / q)));
    println!("chart total: {}", row(&|q| format!("{:.0}", cost(q))));

    // ---- 2. Reorder point and safety stock ----
    let (dw, sw, tl, alpha) = (100.0_f64, 20.0_f64, 2, 0.95_f64);
    let (mul, sl) = (dw * tl as f64, sw * (tl as f64).sqrt());
    let z = quantile(alpha);
    println!("reorder inputs: {:.0}/week, spread {:.0}/week, lead time {} weeks, service level {:.2}", dw, sw, tl, alpha);
    let s = z * sl;
    let r = mul + s;
    let short = sl * g_loss(z);
    println!("hand: lead-time variance {:.0}  G(z) {:.4}", sw * sw * tl as f64, g_loss(z));
    println!("lead-time demand mean {:.0} spread {:.4}  z {:.4}  safety {:.4}  R {:.4} (order at {})", mul, sl, z, s, r, r.ceil() as i64);
    println!("stock-out chance {:.4}  short/cycle {:.4}  fill rate {:.5}  stock-outs/yr {:.4} (one per {:.2} yr)",
             1.0 - big_phi(z), short, 1.0 - short / qs, (1.0 - big_phi(z)) * d / qs, qs / d / (1.0 - big_phi(z)));
    assert!((z - 1.6448536270).abs() < 1e-9 && (big_phi(z) - alpha).abs() < 1e-12);
    let n = 200000;
    let (mut outs, mut tot, mut sq, mut s1) = (0, 0.0, 0.0, 0.0);
    for _ in 0..n {
        let a = dw + sw * rng.normal();                             // two separate weeks, added
        let dd = a + (dw + sw * rng.normal());
        s1 += dd; sq += dd * dd;
        if dd > r { outs += 1; tot += dd - r; }
    }
    let nf = n as f64;
    let sd_sim = (sq / nf - (s1 / nf).powi(2)).sqrt();
    println!("sim {} cycles: spread {:.4}  stock-out {:.4}  short/cycle {:.4}", n, sd_sim, outs as f64 / nf, tot / nf);
    assert!((outs as f64 / nf - 0.05).abs() < 3.0 * (0.05 * 0.95 / nf).sqrt());
    assert!((sd_sim - sl).abs() < 0.2 && (tot / nf - short).abs() < 0.03);
    let s1w = z * sw;
    println!("wrong: one week's spread -> safety {:.4}, true stock-out {:.4}", s1w, 1.0 - big_phi(s1w / sl));

    // ---- 3. Newsvendor: croissants for tomorrow ----
    let (p, c, v, mu, sg) = (2.80_f64, 0.70_f64, 0.0_f64, 120.0_f64, 30.0_f64);
    let (cu, co) = (p - c, c - v);
    let f = cu / (cu + co);
    println!("newsvendor inputs: price {:.2} cost {:.2} leftover value {:.2} demand mean {:.0} spread {:.0}", p, c, v, mu, sg);
    let qn = mu + sg * quantile(f);
    let prof = |q: f64| -> (f64, f64) {                              // expected profit, from G
        let sold = mu - sg * g_loss((q - mu) / sg);
        (p * sold + v * (q - sold) - c * q, sold)
    };
    let prof_int = |q: f64| -> f64 {                                 // road 2: Simpson over the demand curve, no G
        let (a, b, m) = (mu - 8.0 * sg, mu + 8.0 * sg, 2000);
        let hh = (b - a) / m as f64;
        let g = |x: f64| (p * x.min(q) + v * (q - x).max(0.0) - c * q) * phi((x - mu) / sg) / sg;
        let mut t = g(a) + g(b);
        for i in 1..m { t += (if i % 2 == 1 { 4.0 } else { 2.0 }) * g(a + i as f64 * hh); }
        t * hh / 3.0
    };
    let mut bestn = 0;
    for q in 0..=250 { if prof_int(q as f64) > prof_int(bestn as f64) { bestn = q; } }
    let (pr, sold) = prof(140.0);
    println!("cu {:.2} co {:.2} ratio {:.2} fractile {:.4} z {:.4} Q* {:.4}  scan best {}", cu, co, cu / co, f, quantile(f), qn, bestn);
    println!("Q=140: profit {:.4} (Simpson {:.4})  sold {:.4}  left {:.4}  lost sales {:.4}",
             pr, prof_int(140.0), sold, 140.0 - sold, mu - sold);
    let zn = (qn - mu) / sg;
    println!("marginal at Q*: P(D>Q)*cu {:.4}  P(D<=Q)*co {:.4}", (1.0 - big_phi(zn)) * cu, big_phi(zn) * co);
    println!("hand: z*spread {:.4}  G {:.4}  revenue {:.4}  baking {:.2}", sg * quantile(f), g_loss((140.0 - mu) / sg), p * sold, c * 140.0);
    assert!(bestn == 140 && (prof_int(140.0) - pr).abs() < 1e-6);
    let mut sims = Vec::with_capacity(n);
    for _ in 0..n {
        let dd = mu + sg * rng.normal();
        sims.push(p * dd.min(140.0) + v * (140.0 - dd).max(0.0) - c * 140.0);
    }
    let m = sims.iter().sum::<f64>() / nf;
    let se = (sims.iter().map(|x| (x - m).powi(2)).sum::<f64>() / (nf - 1.0) / nf).sqrt();
    println!("sim {} days at Q=140: profit {:.4}  standard error {:.4}", n, m, se);
    assert!((m - pr).abs() < 4.0 * se);
    println!("wrong: bake the average 120 -> profit {:.4}, gap {:.4}/day", prof(120.0).0, pr - prof(120.0).0);
    let qf = mu + sg * quantile(co / (cu + co));
    println!("wrong: fractile flipped to {:.4} -> Q {:.4}, profit {:.4}", co / (cu + co), qf, prof(qf).0);
    let two = |q: f64| 0.5 * (p * q.min(80.0) - c * q) + 0.5 * (p * q.min(160.0) - c * q);
    let qb = (mu + 40.0 * quantile(f)).round();
    let mut best2 = 0;
    for q in 0..=250 { if two(q as f64) > two(best2 as f64) { best2 = q; } }
    println!("two-humped demand (80 or 160): bell-curve fit (mean 120, spread 40) Q {} profit {:.2}; true best Q {} profit {:.2}",
             qb as i64, two(qb), best2, two(best2 as f64));
    assert!(best2 == 160 && qb == 147.0);
    let qn2: Vec<i64> = (8..=20).map(|i| 10 * i).collect();
    println!("chart Q: {}", qn2.iter().map(|q| q.to_string()).collect::<Vec<_>>().join(" "));
    println!("chart profit: {}", qn2.iter().map(|&q| format!("{:.2}", prof(q as f64).0)).collect::<Vec<_>>().join(" "));

    // ---- try changing ----
    let v2 = 0.35;
    println!("try: leftovers sold at {:.2} -> fractile {:.4}, Q {:.4}", v2, cu / (cu + c - v2), mu + sg * quantile(cu / (cu + c - v2)));
    println!("try: spread 15 -> Q {:.4};  K 250 -> Q* {:.4}", mu + 15.0 * quantile(f), (2.0 * 250.0 * d / h).sqrt());
    println!("try: service 0.99 -> z {:.4}, R {:.4}", quantile(0.99), mul + quantile(0.99) * sl);
    println!("ALL CHECKS PASS");
}
