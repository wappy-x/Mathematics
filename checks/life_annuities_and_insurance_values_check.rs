// Life annuities and insurance -- the same check as life_annuities_and_insurance_values_check.py.
// Standard library only, no crates.  Makeham's law mu(y) = A + B c^y, 5 percent interest.
// Compile: rustc --edition 2021 -O life_annuities_and_insurance_values_check.rs -o /tmp/<dir>/chk

const A: f64 = 0.00022;
const B: f64 = 2.7e-6;
const C: f64 = 1.124;
const I: f64 = 0.05;
const TOP: usize = 131; // nobody is followed past age 130
const PAY: f64 = 10000.0;
const BEN: f64 = 100000.0;

fn tp_b(x: f64, t: f64, b: f64) -> f64 { // chance a life aged x is alive at x + t
    (-A * t - b * C.powf(x) * (C.powf(t) - 1.0) / C.ln()).exp()
}
fn tp(x: f64, t: f64) -> f64 { tp_b(x, t, B) }

// road 1: add up birthdays alive, and years of death
fn by_sums(x: usize, v: f64, p: &dyn Fn(f64, f64) -> f64, top: usize) -> (f64, f64) {
    let (mut due, mut ins) = (0.0, 0.0);
    for k in 0..(top - x) {
        let (xf, kf) = (x as f64, k as f64);
        due += v.powf(kf) * p(xf, kf);
        ins += v.powf(kf + 1.0) * p(xf, kf) * (1.0 - p(xf + kf, 1.0));
    }
    (due, ins)
}

// road 2: work back from age 130 one year at a time
fn by_recursion(x: usize, v: f64) -> (f64, f64) {
    let (mut due, mut ins) = (0.0, 0.0);
    for y in (x..TOP).rev() {
        let py = tp(y as f64, 1.0);
        let (nd, ni) = (1.0 + v * py * due, v * (1.0 - py) + v * py * ins);
        due = nd;
        ins = ni;
    }
    (due, ins)
}

struct Rng(u64); // splitmix64: our own uniform numbers in (0, 1)
impl Rng {
    fn next(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53) + 2f64.powi(-54)
    }
}

fn death_time(x: f64, u: f64) -> f64 { // solve tp(x, t) = u by bisection
    let (mut lo, mut hi) = (0.0, TOP as f64 - x);
    for _ in 0..60 {
        let mid = 0.5 * (lo + hi);
        if tp(x, mid) > u { lo = mid; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}

fn main() {
    let (v, d, delta) = (1.0 / (1.0 + I), I / (1.0 + I), (1.0 + I).ln());
    let (due, ins) = by_sums(65, v, &tp, TOP);
    let (due_r, ins_r) = by_recursion(65, v);
    let e65: f64 = (1..(TOP - 65)).map(|k| tp(65.0, k as f64)).sum();

    let n = 100000usize; // road 3: live 100,000 pensioners' lives
    let mut g = Rng(20260928);
    let (mut sy, mut syy, mut sz, mut sbar, mut sbb) = (0.0, 0.0, 0.0, 0.0, 0.0);
    let mut exact_paths = 0usize;
    for _ in 0..n {
        let t = death_time(65.0, g.next());
        let k = t as usize;
        let y: f64 = (0..=k).map(|j| v.powf(j as f64)).sum(); // payments received, discounted
        let z = v.powf(k as f64 + 1.0); // benefit at the end of the death year
        if (d * y + z - 1.0).abs() < 1e-12 { exact_paths += 1; }
        let e = (-delta * t).exp(); // benefit at the moment of death
        sy += y; syy += y * y; sz += z; sbar += e; sbb += e * e;
    }
    let nf = n as f64;
    let (due_mc, ins_mc, bar_mc) = (sy / nf, sz / nf, sbar / nf);
    let se_mc = ((syy / nf - due_mc * due_mc) / nf).sqrt();
    let se_bar = ((sbb / nf - bar_mc * bar_mc) / nf).sqrt();

    // payment at the moment of death: e^-dt t_p_65 mu(65+t), by Simpson's rule
    let f = |t: f64| (-delta * t).exp() * tp(65.0, t) * (A + B * C.powf(65.0 + t));
    let (m, span) = (6600usize, (TOP - 65) as f64);
    let h = span / m as f64;
    let mut s = f(0.0) + f(span);
    for j in 1..m { s += if j % 2 == 1 { 4.0 } else { 2.0 } * f(j as f64 * h); }
    let bar = s * h / 3.0;

    let (due40, ins40) = by_sums(40, v, &tp, TOP);
    let e2540 = v.powf(25.0) * tp(40.0, 25.0);
    let defer_direct: f64 = (25..(TOP - 40)).map(|k| v.powf(k as f64) * tp(40.0, k as f64)).sum();
    let toy = |_x: f64, t: f64| 0.9f64.powf(t); // a toy basis: 90 percent survive every year
    let (toy_due, toy_ins) = by_sums(65, v, &toy, 465); // followed 400 years

    let rows: Vec<(&str, f64)> = vec![
        ("v = 1/(1+i)", v), ("d = i/(1+i)", d), ("delta = ln(1+i)", delta),
        ("1p65  alive at 66", tp(65.0, 1.0)), ("q65   dies before 66", 1.0 - tp(65.0, 1.0)),
        ("25p40 alive at 65, from 40", tp(40.0, 25.0)), ("e65   whole years still to live", e65),
        ("1 annuity-due, sum of survivals", due), ("2 annuity-due, backward recursion", due_r),
        ("3 annuity-due, 100000 lives", due_mc), ("  simulation standard error", se_mc),
        ("4 insurance, sum over death years", ins), ("5 insurance, backward recursion", ins_r),
        ("6 insurance, 100000 lives", ins_mc), ("  identity: 1 - d x annuity-due", 1.0 - d * due),
        ("  paths with dY + Z = 1", exact_paths as f64),
        ("moment of death, integral", bar), ("moment of death, 100000 lives", bar_mc),
        ("  simulation standard error", se_bar),
        ("  v x moment of death", v * bar),
        ("pension 10,000 a year from 65", PAY * due), ("death benefit 100,000 at 65", BEN * ins),
        ("25E40 = v^25 x 25p40", e2540), ("pension bought at 40, deferred", PAY * e2540 * due),
        ("pension bought at 40, direct sum", PAY * defer_direct),
        ("annuity-due at 40", due40), ("insurance at 40", ins40),
        ("wrong: annuity-immediate", PAY * (due - 1.0)),
        ("wrong: certain, 1 + e65 payments", PAY * (1.0 - v.powf(1.0 + e65)) / d),
        ("wrong: no interest", PAY * (1.0 + e65)),
        ("wrong: benefit as 1 - i x annuity", BEN * (1.0 - I * due)),
        ("wrong: benefit as 1 - d x immediate", BEN * (1.0 - d * (due - 1.0))),
        ("try: 3% interest, annuity-due", by_sums(65, 1.0 / 1.03, &tp, TOP).0),
        ("try: age 75, annuity-due", by_sums(75, v, &tp, TOP).0),
        ("try: ageing term doubled, annuity-due", by_sums(65, v, &|x, t| tp_b(x, t, 2.0 * B), TOP).0),
        ("try: toy 0.9 survival, annuity-due", toy_due), ("try: toy 0.9 survival, insurance", toy_ins),
    ];
    for (name, val) in &rows { println!("{:<38} {:>16.6}", name, val); }

    println!();
    let yrs: Vec<usize> = (0..50).step_by(5).collect();
    let mut l1 = format!("{:<26}", "chart, years after 65");
    let mut l2 = format!("{:<26}", "chart, 10,000 v^k kp65");
    for &k in &yrs {
        l1.push_str(&format!("{:>9}", k));
        l2.push_str(&format!("{:>9.2}", PAY * v.powf(k as f64) * tp(65.0, k as f64)));
    }
    println!("{}\n{}", l1, l2);
    let ages: Vec<usize> = (40..110).step_by(10).collect();
    let vals: Vec<(f64, f64)> = ages.iter().map(|&x| by_sums(x, v, &tp, TOP)).collect();
    let mut la = format!("{:<26}", "chart, age");
    let mut lb = format!("{:<26}", "chart, 100 x A");
    let mut lc = format!("{:<26}", "chart, 100 x d x due");
    let mut ld = format!("{:<26}", "chart, sum of the two");
    for (x, (u, a)) in ages.iter().zip(vals.iter()) {
        la.push_str(&format!("{:>9}", x));
        lb.push_str(&format!("{:>9.2}", 100.0 * a));
        lc.push_str(&format!("{:>9.2}", 100.0 * d * u));
        ld.push_str(&format!("{:>9.2}", 100.0 * (a + d * u)));
    }
    println!("{}\n{}\n{}\n{}", la, lb, lc, ld);

    assert!((due - 13.5498).abs() < 5e-5, "published SULT annuity-due at 65, 5%");
    assert!((ins - 0.35477).abs() < 5e-6, "published SULT insurance at 65, 5%");
    assert!((due_r - due).abs() < 1e-9, "annuity: recursion road vs sum road");
    assert!((ins_r - ins).abs() < 1e-9, "insurance: recursion road vs sum road");
    assert!((ins - (1.0 - d * due)).abs() < 1e-12, "identity: death-year sum vs 1 - d x birthday sum");
    assert!((due_mc - due).abs() < 4.0 * se_mc, "simulated lives within 4 standard errors");
    assert!(exact_paths == n, "every simulated life satisfies dY + Z = 1");
    assert!((bar - bar_mc).abs() < 4.0 * se_bar, "moment-of-death integral vs simulated lives");
    assert!(v * bar < ins && ins < bar, "end of death year sits between the two moment-of-death values");
    assert!((e2540 * due - defer_direct).abs() < 1e-9, "deferral factor vs direct sum from 40");
    assert!((toy_due - 7.0).abs() < 1e-9, "toy basis: 1/(1 - 0.9v) = 7 by hand");
    assert!((toy_ins - 2.0 / 3.0).abs() < 1e-9, "toy basis: 0.1v/(1 - 0.9v) = 2/3 by hand");
    println!("ALL CHECKS PASS");
}
