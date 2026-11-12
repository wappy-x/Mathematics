// The check script -- the check behind the card.  Rust std only, no crates.
// Re-derives this wing's EOQ and queue numbers two ways each, compares them with the
// card to half a unit in the last printed digit, and exits 1 on any failure.
// Then it breaks things on purpose and confirms each break is caught.
use std::process::{exit, Command};

// copied by hand from the cards, exactly as printed; never computed here
const CARD: [(&str, &str); 10] = [
    ("EOQ order size Q*, cases", "707.1"), ("EOQ yearly cost, pounds", "1838.48"),
    ("EOQ best whole order, cases", "707"), ("EOQ deliveries a year", "7.35"),
    ("queue busy share rho", "0.9167"), ("queue Lq, people in line", "10.083"),
    ("queue Wq, minutes in line", "11.00"), ("queue W, minutes in shop", "12.00"),
    ("two tills P(wait)", "0.2881"), ("two tills Wq, minutes", "0.27"),
];
type Card = Vec<(&'static str, &'static str)>;
const K: f64 = 125.0; const D: f64 = 5200.0; const H: f64 = 2.60; const LAM: f64 = 55.0; const MU: f64 = 60.0;

// balance state by state: lam p[n] = min(n+1, c) mu p[n+1]; returns (p, L, Lq)
fn cuts(lam: f64, mu: f64, c: usize) -> (Vec<f64>, f64, f64) {
    let mut p = vec![1.0];
    for n in 0..4000 {
        p.push(p[n] * lam / ((n + 1).min(c) as f64 * mu));
    }
    let s: f64 = p.iter().sum();
    let p: Vec<f64> = p.iter().map(|x| x / s).collect();
    let l: f64 = p.iter().enumerate().map(|(n, x)| n as f64 * x).sum();
    let lq: f64 = (c..p.len()).map(|n| (n - c) as f64 * p[n]).sum();
    (p, l, lq)
}

// road 1 = closed form, road 2 = a different computation
fn derive(lam: f64, mu: f64, bug: &str) -> Vec<(f64, f64)> {
    let two = if bug == "drop the 2" { 1.0 } else { 2.0 };
    let q1 = (two * K * D / H).sqrt();
    let (mut lo, mut hi) = (1.0, 1e5); // road 2: bisect on "holding cost = ordering cost"
    for _ in 0..200 {
        let mid = (lo + hi) / 2.0;
        if H * mid / 2.0 < K * D / mid { lo = mid } else { hi = mid }
    }
    let cost = |q: f64| K * D / q + H * q / 2.0;
    let best = (1..=5000).min_by(|a, b| cost(*a as f64).partial_cmp(&cost(*b as f64)).unwrap()).unwrap(); // every whole order 1 to 5,000
    let rho = lam / mu;
    let (p1, l1, lq1) = cuts(lam, mu, 1);
    let wq = if bug == "W for Wq" { 1.0 / (mu - lam) } else { rho / (mu - lam) };
    let a = lam / mu;
    let top = a * a / 2.0 / (1.0 - a / 2.0); // Erlang C with two tills
    let pw = top / (1.0 + a + top);
    let (p2, _, lq2) = cuts(lam, mu, 2);
    vec![(q1, lo), ((two * K * D * H).sqrt(), cost(lo)), (q1.round(), best as f64), (D / q1, D / lo),
         (rho, 1.0 - p1[0]), (rho * rho / (1.0 - rho), lq1), (60.0 * wq, 60.0 * lq1 / lam),
         (60.0 / (mu - lam), 60.0 * l1 / lam), (pw, 1.0 - p2[0] - p2[1]), (60.0 * pw / (2.0 * mu - lam), 60.0 * lq2 / lam)]
}

fn decimals(s: &str) -> i32 {
    s.split('.').nth(1).map_or(0, |t| t.len() as i32)
}
// the labels of every claim that fails
fn compare(card: &Card, vals: &[(f64, f64)], rule: &str) -> Vec<&'static str> {
    let mut fails = vec![];
    for (&(label, printed), &(r1, r2)) in card.iter().zip(vals) {
        let ok = if rule == "itself" {
            (r1 - r1).abs() <= 1e-9 // the tautology, kept only to show it
        } else {
            let c: f64 = printed.parse().unwrap();
            let tol = if rule == "half-unit" { 0.5 * 10f64.powi(-decimals(printed)) } else { 0.01 * c.abs() };
            [r1, r2].iter().all(|r| (r - c).abs() <= tol * (1.0 + 1e-9))
        };
        if !ok { fails.push(label) }
    }
    fails
}
fn edit(label: &str, printed: &'static str) -> Card {
    CARD.iter().map(|&(l, p)| (l, if l == label { printed } else { p })).collect()
}

struct SplitMix(u64);
impl SplitMix {
    fn next(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}

// Lindley: next wait = max(0, wait + service - gap); returns (mean wait in minutes, standard error)
fn simulate(seed: u64) -> (f64, f64) {
    let (n, batches) = (1000000usize, 20usize);
    let (mut u, mut w, mut acc, mut means) = (SplitMix(seed), 0.0f64, 0.0, vec![]);
    for i in 0..n {
        acc += w;
        if (i + 1) % (n / batches) == 0 { means.push(60.0 * acc / (n / batches) as f64); acc = 0.0 }
        let s = -(1.0 - u.next()).ln() / MU;
        w = (w + s + (1.0 - u.next()).ln() / LAM).max(0.0);
    }
    let m = means.iter().sum::<f64>() / batches as f64;
    let var = means.iter().map(|x| (x - m) * (x - m)).sum::<f64>() / (batches - 1) as f64;
    (m, (var / batches as f64).sqrt())
}

fn main() {
    let card: Card = CARD.to_vec();
    let args: Vec<String> = std::env::args().collect();
    if args.iter().any(|a| a == "--break") { // run as a child with one card number mistyped
        exit(if compare(&edit(CARD[0].0, "701.7"), &derive(LAM, MU, ""), "half-unit").is_empty() { 0 } else { 1 });
    }
    if args.iter().any(|a| a == "--strip") { // a false assert that rustc -O removes
        debug_assert!(707.1f64 == 701.7);
        exit(0);
    }
    let mut bad: Vec<&str> = vec![];
    // an assert that survives rustc -O: it records, and the exit code reports
    let mut check = |ok: bool, what: &'static str| if !ok { bad.push(what); println!("FAIL {}", what) };

    let vals = derive(LAM, MU, "");
    for (&(label, printed), &(r1, r2)) in card.iter().zip(&vals) {
        let d = decimals(printed);
        println!("{}: card {}, road 1 {:.4}, road 2 {:.4}, allowed +/- {:.*}", label, printed, r1, r2, (d + 1) as usize, 0.5 * 10f64.powi(-d));
    }
    check(compare(&card, &vals, "half-unit").is_empty(), "every card number within half a unit, both roads");
    let (q, lq) = (vals[0].0, vals[5].0);
    println!("by hand: Q* off by {:.4} from 707.1, {:.4} from 701.7; Lq off by {:.4} from 10.083, {:.4} from 10.038; 1% of 10.038 is {:.4}",
             (q - 707.1).abs(), (q - 701.7).abs(), (lq - 10.083).abs(), (lq - 10.038).abs(), 0.01 * 10.038);
    println!("by hand: drop the 2 and Q* is {:.4}; W for Wq gives {:.4} min", derive(LAM, MU, "drop the 2")[0].0, derive(LAM, MU, "W for Wq")[6].0);
    let (m, se) = simulate(2026);
    println!("road 3, simulated Wq, 1,000,000 customers, seed 2026: {:.2} min, standard error {:.2}", m, se);
    check((m - vals[6].0).abs() <= 4.0 * se, "simulation within 4 standard errors of 11.00");

    let breaks: [(&str, Card, &str, &str, usize); 6] = [
        ("card typo: Q* 707.1 -> 701.7", edit(CARD[0].0, "701.7"), "", "half-unit", 0),
        ("code drops the 2 in Q*", card.clone(), "drop the 2", "half-unit", 0),
        ("code uses W for Wq", card.clone(), "W for Wq", "half-unit", 6),
        ("card typo: Lq 10.083 -> 10.038", edit(CARD[5].0, "10.038"), "", "half-unit", 5),
        ("card typo: Lq 10.083 -> 10.038", edit(CARD[5].0, "10.038"), "", "1% rel", 5),
        ("code drops the 2 in Q*", card.clone(), "drop the 2", "itself", 0)];
    let mut hits = vec![];
    for (name, c, bug, rule, target) in breaks.iter() { // is the broken number itself among the failures?
        let fails = compare(c, &derive(LAM, MU, bug), rule);
        hits.push(fails.contains(&CARD[*target].0));
        println!("break: {:<31} rule {:<9} failing {}  {}", name, rule, fails.len(), if *hits.last().unwrap() { "caught" } else { "MISSED" });
    }
    check(hits == [true, true, true, true, false, false], "half-unit catches all four breaks; 1% and itself miss");
    let alarm = compare(&card, &vals, "1% rel");
    println!("false alarm under the 1% rule: {}, off by {:.4}, allowed {:.4}", alarm.join(", "), 0.27 - vals[9].0, 0.01 * 0.27);
    check(alarm == [CARD[9].0], "the 1% rule flags the correct 0.27");

    let me = std::env::current_exe().unwrap();
    let child = Command::new(&me).arg("--break").output().unwrap().status.code().unwrap();
    let stripped = Command::new(&me).arg("--strip").output().unwrap().status.code().unwrap();
    println!("exit code, this script run on the mistyped card: {}", child);
    println!("exit code, a false assert the optimiser strips: {}", stripped);
    check(child == 1, "a broken card makes the script exit 1");
    check(stripped == 0, "the stripped assert lets a false claim exit 0");

    let v59 = derive(59.0, MU, "");
    let n59 = compare(&card, &v59, "half-unit");
    println!("try: 59 arrivals an hour, card unchanged: {} failing, Wq now {:.2} min", n59.len(), v59[6].0);
    check(n59.len() == 6, "every queue number moves when the arrival rate does");
    let off = (m - 11.0).abs();
    println!("try: simulated Wq held to +/- 0.005: off by {:.2}, {}", off, if off <= 0.005 { "pass" } else { "fail" });
    let (m2, se2) = simulate(7);
    println!("try: seed 7: simulated Wq {:.2} min, standard error {:.2}, within 4 se: {}", m2, se2, if (m2 - 11.0).abs() <= 4.0 * se2 { "yes" } else { "no" });

    if !bad.is_empty() {
        println!("{} CHECKS FAILED", bad.len());
        exit(1);
    }
    println!("ALL CHECKS PASS");
}
