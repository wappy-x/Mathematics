// Multi-curve and the 3s6s basis -- the check behind the card.  Rust std only.
// One discount curve, two forecast curves, three roads: coupon-by-coupon sums with a
// bisection root finder, closed forms, and the single-curve telescope as a control.
const N: f64 = 10_000_000.0; // the house swap: 10 million, pay fixed 4.5% annual, 5 years
const K: f64 = 0.0450;
const T: f64 = 5.0;
const OIS: [f64; 5] = [0.0420, 0.0440, 0.0455, 0.0462, 0.0465]; // house curve par rates, read as OIS
const S3: f64 = 0.0475; // 5y par rate against the 3m index
const BASIS: f64 = 0.0008; // 5y 3s6s basis quote

fn bisect<F: Fn(f64) -> f64>(f: F, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if f(lo) * f(mid) <= 0.0 { hi = mid; } else { lo = mid; }
    }
    0.5 * (lo + hi)
}

struct M { p: Vec<f64>, af: f64, a3: f64, a6: f64, b3: f64, b3c: f64, b6: f64, b6c: f64,
           c3: f64, c6: f64, v: f64, vq: f64, vois: f64, vold: f64, s6: f64 }

impl M {
    fn d(&self, t: f64) -> f64 { // log-linear between pillars: flat overnight rate each year
        let k = (t as usize).min(self.p.len() - 2);
        let w = t - k as f64;
        ((1.0 - w) * self.p[k].ln() + w * self.p[k + 1].ln()).exp()
    }
    fn dates(a: f64, n: f64) -> Vec<f64> { (1..=((n / a).round() as usize)).map(|i| a * i as f64).collect() }
    fn ann(&self, a: f64, n: f64) -> f64 { M::dates(a, n).iter().map(|&t| a * self.d(t)).sum() }
    fn fwd(&self, a: f64, b: f64, t: f64) -> f64 { // index forward off H(u) = D(u) e^{-bu}
        let h = |u: f64| self.d(u) * (-b * u).exp();
        (h(t - a) / h(t) - 1.0) / a
    }
    fn leg(&self, a: f64, b: f64, n: f64) -> f64 { // road 1
        M::dates(a, n).iter().map(|&t| a * self.fwd(a, b, t) * self.d(t)).sum()
    }
    fn starts(&self, a: f64, n: f64) -> f64 { M::dates(a, n).iter().map(|&t| self.d(t - a)).sum() }
    fn closed(&self, a: f64, b: f64, n: f64) -> f64 { // road 2
        (1.0 - self.d(n)) + ((b * a).exp() - 1.0) * self.starts(a, n)
    }
}

fn market(ois: &[f64], s3: f64, basis: f64) -> M {
    let (mut p, mut bb) = (vec![1.0], 0.0);
    for &s in ois { let d = (1.0 - s * bb) / (1.0 + s); p.push(d); bb += d; }
    let mut m = M { p, af: 0.0, a3: 0.0, a6: 0.0, b3: 0.0, b3c: 0.0, b6: 0.0, b6c: 0.0,
                    c3: 0.0, c6: 0.0, v: 0.0, vq: 0.0, vois: 0.0, vold: 0.0, s6: 0.0 };
    m.af = m.ann(1.0, T); m.a3 = m.ann(0.25, T); m.a6 = m.ann(0.5, T);
    m.b3 = bisect(|b| m.leg(0.25, b, T) - s3 * m.af, -0.05, 0.05);
    m.b3c = 4.0 * (1.0 + (s3 * m.af - (1.0 - m.d(T))) / m.starts(0.25, T)).ln();
    m.c3 = m.leg(0.25, m.b3, T);
    m.b6 = bisect(|b| m.leg(0.5, b, T) - m.c3 - basis * m.a3, -0.05, 0.05);
    m.b6c = 2.0 * (1.0 + (s3 * m.af + basis * m.a3 - (1.0 - m.d(T))) / m.starts(0.5, T)).ln();
    m.c6 = m.leg(0.5, m.b6, T);
    m.v = N * (m.c3 - K * m.af); // to the payer
    m.vq = N * (s3 - K) * m.af;
    m.vois = N * ((1.0 - m.d(T)) - K * m.af);
    let h3 = |u: f64| m.d(u) * (-m.b3 * u).exp();
    let fixed3: f64 = (1..=5).map(|k| h3(k as f64)).sum();
    m.vold = N * ((1.0 - h3(T)) - K * fixed3);
    m.s6 = m.c6 / m.af;
    m
}

fn row(label: &str, v: f64, dp: usize) { println!("{:<44}{:.*}", label, dp, v); }

fn main() {
    let m = market(&OIS, S3, BASIS);
    let bp = 1e4;
    let par = |n: usize| (1.0 - m.p[n]) / m.p[1..=n].iter().sum::<f64>();
    for n in 1..=5 { row(&format!("D({}) discount factor", n), m.p[n], 8); }
    for n in 1..=5 { row(&format!("  OIS {}y par rate repriced, percent", n), 100.0 * par(n), 4); }
    row("annuity, annual fixed leg", m.af, 6); row("annuity, quarterly leg", m.a3, 6); row("annuity, half-yearly leg", m.a6, 6);
    row("sum of quarter-start discounts", (1..=20).map(|i| m.d(0.25 * (i - 1) as f64)).sum(), 6);
    row("sum of half-year-start discounts", (1..=10).map(|i| m.d(0.5 * (i - 1) as f64)).sum(), 6);
    row("b3 by bisection, bp", m.b3 * bp, 6); row("b3 closed form, bp", m.b3c * bp, 6);
    row("b6 by bisection, bp", m.b6 * bp, 6); row("b6 closed form, bp", m.b6c * bp, 6);
    row("3m leg, coupon by coupon", m.c3, 6); row("3m leg, closed form", m.closed(0.25, m.b3, T), 6);
    row("6m leg, coupon by coupon", m.c6, 6); row("6m leg, closed form", m.closed(0.5, m.b6, T), 6);
    row("OIS floater 1 - D(5)", 1.0 - m.d(T), 6); row("3m leg with b = 0 (telescope)", m.leg(0.25, 0.0, T), 6);
    row("fair 5y basis, sums, bp", (m.c6 - m.c3) / m.a3 * bp, 6);
    row("fair 5y basis, closed forms, bp", (m.closed(0.5, m.b6c, T) - m.closed(0.25, m.b3c, T)) / m.a3 * bp, 6);
    row("single-curve basis (b = 0), bp", ((m.leg(0.5, 0.0, T) - m.leg(0.25, 0.0, T)) / m.a3 * bp * 1e9).round() / 1e9 + 0.0, 6);
    for n in 1..=4 {
        let nf = n as f64;
        row(&format!("fair {}y basis off the curves, bp", n), (m.leg(0.5, m.b6, nf) - m.leg(0.25, m.b3, nf)) / m.ann(0.25, nf) * bp, 6);
    }
    row("house swap, multi-curve, sums", m.v, 2); row("house swap, off the 4.75% quote", m.vq, 2);
    row("wrong: forecast off OIS", m.vois, 2); row("wrong: one 3m curve does both", m.vold, 2);
    row("implied 5y par rate vs 6m, percent", 100.0 * m.s6, 4);
    row("wrong: 4.75% + 8 bp, percent", 100.0 * (S3 + BASIS), 4);
    row("  cost of that slip on 10m, dollars", N * (m.s6 - S3 - BASIS) * m.af, 2);
    row("wrong leg: fair spread on the 6m leg, bp", -(m.c6 - m.c3) / m.a6 * bp, 6);
    let vbs = N * (m.c3 + 0.0010 * m.a3 - m.c6);
    row("basis swap struck at 10 bp, sums", vbs, 2); row("basis swap struck at 10 bp, 2 bp x A3", N * 0.0002 * m.a3, 2);
    let up: Vec<f64> = OIS.iter().map(|x| x + 0.001).collect();
    row("try: basis 15 bp, 6m par percent", 100.0 * market(&OIS, S3, 0.0015).s6, 4);
    row("try: OIS all +10 bp, house swap", market(&up, S3, BASIS).v, 2);
    row("try: 3m par 4.65%, house swap", market(&OIS, 0.0465, BASIS).v, 2);
    let ends: Vec<f64> = (1..=10).map(|i| 0.5 * i as f64).collect();
    let line = |v: Vec<String>| v.join(" ");
    println!("{:<44}{}", "chart, period ends (years)", line(ends.iter().map(|t| format!("{:.1}", t)).collect()));
    for (label, a, b) in [("chart, OIS 3m forward %", 0.25, 0.0), ("chart, 3m index forward %", 0.25, m.b3),
                          ("chart, 6m index forward %", 0.5, m.b6)] {
        println!("{:<44}{}", label, line(ends.iter().map(|&t| format!("{:.2}", 100.0 * m.fwd(a, b, t))).collect()));
    }

    assert!((m.b3 - m.b3c).abs() < 1e-12, "3m spread: root finder vs closed form");
    assert!((m.b6 - m.b6c).abs() < 1e-12, "6m spread: root finder vs closed form");
    assert!((m.closed(0.5, m.b6, T) - m.c6).abs() < 1e-12, "6m leg: closed form vs coupon sum");
    assert!((m.v - m.vq).abs() < 1e-6, "coupon sums vs the quote identity (S3 - K) x annuity");
    assert!((m.leg(0.25, 0.0, T) - (1.0 - m.d(T))).abs() < 1e-14, "single curve: the coupons must telescope");
    assert!((1..=5).all(|n| (par(n) - OIS[n - 1]).abs() < 1e-14), "curve reprices OIS");
    assert!((vbs - N * 0.0002 * m.a3).abs() < 1e-6, "off-market basis swap: sums vs spread annuity");
    assert!((m.p[5] - 0.79621728).abs() < 5e-9 && (m.vois - 65736.36).abs() < 0.005, "house curve: D(5), card 01 value");
    println!("ALL CHECKS PASS");
}
