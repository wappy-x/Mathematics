// Expected shortfall and coherence -- the same check as expected_shortfall_and_coherence_check.py, in Rust.
// Std only, no crates.  Probabilities are whole millionths; tails are exact integer sums.
// Rust has no erf, so the bell-curve area is built by adding thin slices under the curve (Simpson).
use std::collections::BTreeMap;
use std::f64::consts::PI;

const DEN: i64 = 1_000_000;
type Law = BTreeMap<i64, i64>; // loss -> weight

fn pair_law(p: i64, together: bool) -> Vec<(i64, i64, i64)> {
    if together { return vec![(0, 0, DEN - 1000 * p), (100, 100, 1000 * p)]; }
    let n = 1000 - p;
    vec![(0, 0, n * n), (100, 0, p * n), (0, 100, n * p), (100, 100, p * p)]
}
fn merge(pairs: impl Iterator<Item = (i64, i64)>) -> Law {
    let mut law = Law::new();
    for (x, w) in pairs { *law.entry(x).or_insert(0) += w; }
    law
}
fn var(law: &Law, a: i64, den: i64) -> i64 {       // lowest loss whose cumulative weight reaches a/DEN
    let mut cum = 0;
    for (&x, &w) in law { cum += w; if cum * DEN >= a * den { return x; } }
    panic!("no quantile")
}
fn es_fill(law: &Law, a: i64, den: i64) -> i64 {   // road 1: fill the worst tail, largest losses first
    let (mut room, mut total) = ((DEN - a) * den, 0i64);
    for (&x, &w) in law.iter().rev() {
        let take = (w * DEN).min(room);
        total += x * take; room -= take;
    }
    total
}
fn es_min(law: &Law, a: i64, den: i64) -> i64 {    // road 2: min over s of s*t + E[(L-s)+], s on a loss value
    let t = (DEN - a) * den;
    law.keys().map(|&s| s * t + law.iter().map(|(&x, &w)| DEN * w * (x - s).max(0)).sum::<i64>()).min().unwrap()
}
fn es(law: &Law, a: i64, den: i64) -> f64 { es_fill(law, a, den) as f64 / ((DEN - a) * den) as f64 }
fn books(p: i64, together: bool) -> (Law, Law, Law) {
    let j = pair_law(p, together);
    (merge(j.iter().map(|&(x, _, w)| (x, w))), merge(j.iter().map(|&(_, y, w)| (y, w))),
     merge(j.iter().map(|&(x, y, w)| (x + y, w))))
}
struct Lcg(u64); // home-made generator: 64-bit LCG, top bits
impl Lcg {
    fn draw(&mut self) -> u64 {
        self.0 = self.0.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        (self.0 >> 33) % 1000
    }
}
fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}
fn n_cdf(x: f64) -> f64 { 0.5 + simpson(phi, 0.0, x, 4000) }
fn z_of(a: f64) -> f64 {
    let (mut lo, mut hi) = (-10.0, 10.0);
    for _ in 0..100 { let mid = 0.5 * (lo + hi); if n_cdf(mid) < a { lo = mid } else { hi = mid } }
    0.5 * (lo + hi)
}
fn tail_simpson(z: f64, t: f64) -> f64 { simpson(|x| x * phi(x), z, z + 12.0, 20000) / t }

fn main() {
    let a99 = 990_000;
    let (a, b, p) = books(10, false);
    let mut rows: Vec<(String, String)> = Vec::new();
    let f6 = |x: f64| format!("{:.6}", x);
    let push = |rows: &mut Vec<(String, String)>, n: &str, v: String| rows.push((n.to_string(), v));
    push(&mut rows, "state neither defaults", f6(p[&0] as f64 / DEN as f64));
    push(&mut rows, "state exactly one defaults", f6(p[&100] as f64 / DEN as f64));
    push(&mut rows, "state both default", f6(p[&200] as f64 / DEN as f64));
    for (name, law) in [("bond A", &a), ("bond B", &b), ("pair", &p)] {
        push(&mut rows, &format!("VaR99 {}", name), var(law, a99, DEN).to_string());
        push(&mut rows, &format!("ES99 {}, fill the tail", name), f6(es(law, a99, DEN)));
        push(&mut rows, &format!("ES99 {}, minimise over s", name), f6(es_min(law, a99, DEN) as f64 / ((DEN - a99) * DEN) as f64));
    }
    let v_sum = var(&a, a99, DEN) + var(&b, a99, DEN);
    push(&mut rows, "VaR99 pair minus sum of solo", (var(&p, a99, DEN) - v_sum).to_string());
    push(&mut rows, "ES99 sum of solo", f6(es(&a, a99, DEN) + es(&b, a99, DEN)));
    let above: i64 = p.iter().filter(|(&x, _)| x > 100).map(|(_, &w)| w).sum();
    push(&mut rows, "pair tail, weight taken at $100", f6((DEN - a99 - above) as f64 / DEN as f64));

    // ---- road 3: simulate a million days ----
    let mut g = Lcg(20260928);
    let n = 1_000_000i64;
    let mut counts = Law::from([(0, 0), (100, 0), (200, 0)]);
    for _ in 0..n {
        let la = if g.draw() < 10 { 100 } else { 0 };
        let lb = if g.draw() < 10 { 100 } else { 0 };
        *counts.get_mut(&(la + lb)).unwrap() += 1;
    }
    push(&mut rows, "simulated days, both default", counts[&200].to_string());
    push(&mut rows, "simulated VaR99 pair", var(&counts, a99, n).to_string());
    push(&mut rows, "simulated ES99 pair", f6(es(&counts, a99, n)));

    // ---- what breaks ----
    let v = var(&p, a99, DEN);
    let mean_where = |keep: &dyn Fn(i64) -> bool| {
        let (num, w): (i64, i64) = p.iter().filter(|(&x, _)| keep(x)).fold((0, 0), |(s, t), (&x, &w)| (s + x * w, t + w));
        num as f64 / w as f64
    };
    push(&mut rows, "wrong: mean of losses strictly above VaR", f6(mean_where(&|x| x > v)));
    push(&mut rows, "wrong: mean of losses at or above VaR", f6(mean_where(&|x| x >= v)));
    push(&mut rows, "axiom: ES99 pair + $5 certain loss", f6(es(&p.iter().map(|(&x, &w)| (x + 5, w)).collect(), a99, DEN)));
    push(&mut rows, "axiom: ES99 pair, doubled book", f6(es(&p.iter().map(|(&x, &w)| (2 * x, w)).collect(), a99, DEN)));

    // ---- try changing ----
    for (label, pp, tog) in [("try: p = 0.5%", 5, false), ("try: p = 2%", 20, false), ("try: defaults together", 10, true)] {
        let (ta, tb, tp) = books(pp, tog);
        push(&mut rows, &format!("{}, VaR99 pair | sum", label),
             format!("{:.2} | {:.2}", var(&tp, a99, DEN) as f64, (var(&ta, a99, DEN) + var(&tb, a99, DEN)) as f64));
        push(&mut rows, &format!("{}, ES99 pair | sum", label),
             format!("{:.2} | {:.2}", es(&tp, a99, DEN), es(&ta, a99, DEN) + es(&tb, a99, DEN)));
    }

    // ---- random books: 8 equally likely days, 80% level ----
    let (mut var_breaks, mut es_breaks, mut road_gaps) = (0, 0, 0);
    for _ in 0..2000 {
        let days: Vec<(i64, i64)> = (0..8).map(|_| {
            let x = 50 * (g.draw() % 5) as i64 - 50;
            (x, 50 * (g.draw() % 5) as i64 - 50)
        }).collect();
        let la = merge(days.iter().map(|d| (d.0, 125_000)));
        let lb = merge(days.iter().map(|d| (d.1, 125_000)));
        let lp = merge(days.iter().map(|d| (d.0 + d.1, 125_000)));
        if var(&lp, 800_000, DEN) > var(&la, 800_000, DEN) + var(&lb, 800_000, DEN) { var_breaks += 1; }
        if es_fill(&lp, 800_000, DEN) > es_fill(&la, 800_000, DEN) + es_fill(&lb, 800_000, DEN) { es_breaks += 1; }
        if es_fill(&lp, 800_000, DEN) != es_min(&lp, 800_000, DEN) { road_gaps += 1; }
    }
    push(&mut rows, "random books, VaR80 not subadditive", var_breaks.to_string());
    push(&mut rows, "random books, ES80 not subadditive", es_breaks.to_string());
    push(&mut rows, "random books, ES80 roads 1 and 2 disagree", road_gaps.to_string());

    // ---- a second case: a bell-curve loss with spread 1 ----
    for (lab, al) in [("99", 0.99), ("97.5", 0.975)] {
        let z = z_of(al);
        push(&mut rows, &format!("normal VaR{}", lab), f6(z));
        push(&mut rows, &format!("normal ES{}, phi(z)/t", lab), f6(phi(z) / (1.0 - al)));
        push(&mut rows, &format!("normal ES{}, integral", lab), f6(tail_simpson(z, 1.0 - al)));
    }
    for (name, x) in &rows { println!("{:<44} {:>14}", name, x); }

    // ---- chart points ----
    let levels = [950_000i64, 970_000, 980_000, 985_000, 990_000, 995_000, 999_000];
    let line = |name: &str, f: &dyn Fn(i64) -> f64| {
        println!("{:<22}{}", name, levels.iter().map(|&l| format!("{:>8.2}", f(l))).collect::<String>());
    };
    line("chart, confidence %", &|l| l as f64 / 10_000.0);
    line("chart, VaR pair", &|l| var(&p, l, DEN) as f64);
    line("chart, VaR sum", &|l| (var(&a, l, DEN) + var(&b, l, DEN)) as f64);
    line("chart, ES pair", &|l| es(&p, l, DEN));
    line("chart, ES sum", &|l| es(&a, l, DEN) + es(&b, l, DEN));

    assert_eq!(es_fill(&p, a99, DEN), es_min(&p, a99, DEN), "pair: fill road vs minimise road, exact");
    assert_eq!(es_fill(&a, a99, DEN), es_min(&a, a99, DEN), "bond A: fill road vs minimise road, exact");
    assert_eq!(es_fill(&p, a99, DEN), 101 * (DEN - a99) * DEN, "pair ES must be exactly $101");
    assert!(var(&p, a99, DEN) > v_sum, "VaR of the pair must exceed the sum");
    assert!((es(&counts, a99, n) - es(&p, a99, DEN)).abs() < 0.5, "simulation within 50 cents of the exact ES");
    assert_eq!(es_breaks, 0, "ES never breaks subadditivity");
    assert!(var_breaks > 0, "VaR breaks it on some random book");
    assert_eq!(road_gaps, 0, "fill and minimise agree on every random book");
    assert!((phi(z_of(0.99)) / 0.01 - tail_simpson(z_of(0.99), 0.01)).abs() < 1e-8, "normal ES: closed form vs integral");
    assert!((z_of(0.99) - 2.3263478740).abs() < 1e-8, "99% point vs the printed normal table");
    println!("ALL CHECKS PASS");
}
