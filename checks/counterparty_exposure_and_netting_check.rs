// Counterparty exposure and netting -- the check behind the card.  Rust std only, no crates.
// Every number quoted on the card is printed here.  Nothing used knows the answer:
// the bell-curve area is Simpson's rule written out, the random numbers are our own.
use std::f64::consts::PI;

fn pos(x: f64) -> f64 { if x > 0.0 { x } else { 0.0 } }     // the floor: x+ = max(x, 0)

fn set_sum(v: &[f64], s: &[usize]) -> f64 { s.iter().map(|&i| v[i]).sum() }

// road 1: add inside each netting set, floor, add the sets
fn exposure(v: &[f64], sets: &[Vec<usize>]) -> f64 { sets.iter().map(|s| pos(set_sum(v, s))).sum() }

// road 2: follow the cash on the day Northwind fails
fn ledger(v: &[f64], sets: &[Vec<usize>], rec: f64) -> (f64, f64) {
    let mut cash = 0.0;
    for s in sets {
        let amount = set_sum(v, s);                               // close-out: one amount per set
        cash += if amount > 0.0 { rec * amount } else { amount }; // claim recovers R; debt paid in full
    }
    (v.iter().sum::<f64>() - cash, cash)                          // loss = worth if it survived - cash
}

// road 3: cancel a cent owed to the bank against a cent it owes
fn pairing(v: &[f64], sets: &[Vec<usize>]) -> f64 {
    let mut left: i64 = 0;
    for s in sets {
        let mut owed: i64 = s.iter().filter(|&&i| v[i] > 0.0).map(|&i| (100.0 * v[i]).round() as i64).sum();
        let mut owes: i64 = s.iter().filter(|&&i| v[i] < 0.0).map(|&i| (-100.0 * v[i]).round() as i64).sum();
        while owed > 0 && owes > 0 { owed -= 1; owes -= 1; }
        left += owed;
    }
    left as f64 / 100.0
}

fn ncdf(x: f64) -> f64 {    // bell-curve area left of x: 1/2 plus Simpson's rule from 0 to x
    let n = 2000;
    let h = x / n as f64;
    let f = |z: f64| (-0.5 * z * z).exp() / (2.0 * PI).sqrt();
    let mut s = f(0.0) + f(x);
    for k in 1..n { s += if k % 2 == 1 { 4.0 } else { 2.0 } * f(k as f64 * h); }
    0.5 + s * h / 3.0
}

fn ln(x: f64) -> f64 {      // natural log as the area under 1/t from 1 to x (Simpson again)
    let n = 4000;
    let h = (x - 1.0) / n as f64;
    let mut s = 1.0 + 1.0 / x;
    for k in 1..n { s += if k % 2 == 1 { 4.0 } else { 2.0 } / (1.0 + k as f64 * h); }
    s * h / 3.0
}

struct Lcg(u64);
impl Lcg { fn next(&mut self, m: u64) -> u64 { self.0 = (1103515245 * self.0 + 12345) % 2147483648; self.0 % m } }

fn main() {
    let v = [5.0, -3.0, 2.0];   // the three Northwind trades, value to the bank, $ millions
    let r_rec = 0.40;           // recovery: share of a claim on Northwind the bank gets back
    let one = vec![vec![0, 1, 2]];
    let sep = vec![vec![0, 2], vec![1]];                          // one master agreement; -3 trade apart
    let each = vec![vec![0], vec![1], vec![2]];
    let (gross, net, sepx) = (exposure(&v, &each), exposure(&v, &one), exposure(&v, &sep));
    let p: f64 = v.iter().map(|&x| pos(x)).sum();
    let q: f64 = v.iter().map(|&x| pos(-x)).sum();
    let (loss_net, cash_net) = ledger(&v, &one, r_rec);
    let (loss_sep, cash_sep) = ledger(&v, &sep, r_rec);
    let (loss_each, cash_each) = ledger(&v, &each, r_rec);

    // ---- the house example: Acme options bought from and sold to Northwind ----
    let (s0, k, r, qd, sig, t) = (100.0_f64, 100.0_f64, 0.05_f64, 0.02_f64, 0.20_f64, 1.0_f64);
    let d1 = (ln(s0 / k) + (r - qd + 0.5 * sig * sig) * t) / (sig * t.sqrt());
    let d2 = d1 - sig * t.sqrt();
    let call = s0 * (-qd * t).exp() * ncdf(d1) - k * (-r * t).exp() * ncdf(d2);
    let put = k * (-r * t).exp() * ncdf(-d2) - s0 * (-qd * t).exp() * ncdf(-d1);
    let fwd = s0 * (-qd * t).exp() - k * (-r * t).exp();         // parity: no bell curve needed
    let acme_net = exposure(&[call, -put], &[vec![0, 1]]);
    let acme_sep = exposure(&[call, -put], &[vec![0], vec![1]]);

    // ---- road 4: 20,000 random books, our own random numbers (a linear congruential generator) ----
    let mut g = Lcg(20260928);
    let (mut books, mut merges) = (0, 0);
    for _ in 0..20000 {
        let n = 1 + g.next(6) as usize;
        let vv: Vec<f64> = (0..n).map(|_| g.next(19) as f64 - 9.0).collect();
        let lab: Vec<u64> = (0..n).map(|_| g.next(3)).collect();
        let sets: Vec<Vec<usize>> = (0..3).map(|gr| (0..n).filter(|&i| lab[i] == gr).collect::<Vec<usize>>())
            .filter(|s: &Vec<usize>| !s.is_empty()).collect();
        let x = exposure(&vv, &sets);
        let all: Vec<Vec<usize>> = vec![(0..n).collect()];
        let singles: Vec<Vec<usize>> = (0..n).map(|i| vec![i]).collect();
        assert!(exposure(&vv, &all) <= x && x <= exposure(&vv, &singles));
        assert!((pairing(&vv, &sets) - x).abs() < 1e-9 && (ledger(&vv, &sets, r_rec).0 - (1.0 - r_rec) * x).abs() < 1e-9);
        if sets.len() > 1 {                                       // merge the first two agreements
            let mut merged = vec![sets[0].iter().chain(sets[1].iter()).cloned().collect::<Vec<usize>>()];
            merged.extend(sets[2..].iter().cloned());
            assert!(exposure(&vv, &merged) <= x);
            merges += 1;
        }
        books += 1;
    }

    let rows: Vec<(&str, f64)> = vec![
        ("trade 1", v[0]), ("trade 2", v[1]), ("trade 3", v[2]),
        ("gross: floor each trade, add", gross), ("net: add, then floor", net),
        ("net by cent pairing", pairing(&v, &one)), ("P  owed to the bank, trade by trade", p),
        ("Q  owed by the bank, trade by trade", q), ("gross - net", gross - net),
        ("min(P, Q)", p.min(q)), ("net-to-gross ratio", net / gross),
        ("separate: -3 trade apart", sepx), ("  still owed by the bank", -set_sum(&v, &sep[1])),
        ("partition {1,2}{3}", exposure(&v, &[vec![0, 1], vec![2]])), ("  set {1,2} total", v[0] + v[1]),
        ("partition {2,3}{1}", exposure(&v, &[vec![1, 2], vec![0]])), ("  set {2,3} total", v[1] + v[2]),
        ("R  recovery", r_rec), ("LGD = 1 - R", 1.0 - r_rec),
        ("loss, one agreement, ledger", loss_net), ("  (1-R) x net", (1.0 - r_rec) * net),
        ("  cash the bank ends with", cash_net),
        ("loss, -3 apart, ledger", loss_sep), ("  (1-R) x separate", (1.0 - r_rec) * sepx),
        ("  claim recovered, -3 apart", r_rec * sepx), ("  cash the bank ends with", cash_sep),
        ("loss, no agreement, ledger", loss_each), ("  cash the bank ends with", cash_each),
        ("Acme call bought", call), ("Acme put", put), ("exposure, call bought only", exposure(&[call], &[vec![0]])),
        ("exposure, put sold only", exposure(&[-put], &[vec![0]])),
        ("exposure, call bought + put sold, one set", acme_net), ("  S e^-qT - K e^-rT", fwd),
        ("exposure, the two apart", acme_sep),
        ("wrong: floor each, one agreement", gross), ("wrong: net across two agreements", net),
        ("wrong: no floor, trade 2 = -9", 5.0 - 9.0 + 2.0), ("wrong: sizes |V| added", v.iter().map(|x| x.abs()).sum()),
        ("try: trade 2 = -9, net", exposure(&[5.0, -9.0, 2.0], &one)),
        ("try: trade 2 = -9, bank owes", -(5.0 - 9.0 + 2.0)),
        ("try: R = 0, loss one agreement", ledger(&v, &one, 0.0).0),
        ("try: +2 trade apart", exposure(&v, &[vec![0, 1], vec![2]])),
        ("try: trade 2 = +3, net", exposure(&[5.0, 3.0, 2.0], &one)),
    ];
    for (name, x) in &rows { println!("{:<42} {:>11.6}", name, x); }
    println!("random books checked {}, merges checked {}", books, merges);
    let xs: Vec<i32> = (-10..5).collect();
    println!("chart, trade 2 value {}", xs.iter().map(|x| format!("{:5}", x)).collect::<Vec<_>>().join(" "));
    println!("chart, net           {}", xs.iter().map(|&x| format!("{:5.2}", exposure(&[5.0, x as f64, 2.0], &one))).collect::<Vec<_>>().join(" "));
    println!("chart, gross         {}", xs.iter().map(|&x| format!("{:5.2}", exposure(&[5.0, x as f64, 2.0], &each))).collect::<Vec<_>>().join(" "));

    assert!((net - pairing(&v, &one)).abs() < 1e-12, "floor formula vs cent pairing");
    assert!((gross - net - p.min(q)).abs() < 1e-12, "netting saves exactly min(P, Q)");
    assert!((loss_net - (1.0 - r_rec) * net).abs() < 1e-12, "cash ledger vs (1-R) x exposure");
    assert!((acme_net - fwd).abs() < 1e-9, "netted Acme pair vs put-call parity");
    assert!((call - 9.227005508154).abs() < 1e-9, "house call value");
    println!("ALL CHECKS PASS");
}
