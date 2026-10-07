// Random variables: a number for each outcome, and the table of its chances.
// Raffle: 100 tickets, one number drawn, the held ticket (37) pays $100.
// Roads: count every outcome; multiply single-raffle counts; seeded simulation.
use std::collections::BTreeMap;

const MINE: u64 = 37;
type Table = BTreeMap<i64, u64>;

fn x(drawn: u64) -> i64 {
    // the random variable: number drawn -> payout
    if drawn == MINE { 100 } else { 0 }
}

fn table<I: Iterator<Item = i64>>(values: I) -> Table {
    // pool outcomes by value: value -> outcome count
    let mut t = Table::new();
    for v in values {
        *t.entry(v).or_insert(0) += 1;
    }
    t
}

fn cdf(t: &Table, at: i64) -> u64 {
    // running total of a table: count of values <= at
    t.iter().filter(|(v, _)| **v <= at).map(|(_, c)| *c).sum()
}

fn splitmix64(s: &mut u64) -> u64 {
    *s = s.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = *s;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}

fn main() {
    // One raffle: 100 outcomes pooled into two values
    let one = table((1..=100).map(x));
    println!("one raffle, tickets 1-100, held ticket {}, pooled to 0: {}, pooled to 100: {}", MINE, one[&0], one[&100]);
    for (v, c) in &one {
        println!("pmf X, {}, {:.6}", v, *c as f64 / 100.0);
    }
    for at in [-50, -1, 0, 50, 99, 100, 150] {
        let direct = (1..=100).filter(|w| x(*w) <= at).count() as u64;
        assert_eq!(cdf(&one, at), direct);
        println!("cdf X, {}, {:.6}", at, cdf(&one, at) as f64 / 100.0);
    }
    let jump = |a: i64, b: i64| (cdf(&one, a) - cdf(&one, b)) as f64 / 100.0;
    println!("jump of F at 0: {:.6}, at 100: {:.6}", jump(0, -1), jump(100, 99));
    println!("P(0 < X <= 100) = F(100) - F(0) = {:.6}", jump(100, 0));

    // A different space with the same table: last two digits of a number 000-999 are 77
    let bet = table((0..1000u64).map(|n| if n % 100 == 77 { 100 } else { 0 }));
    let scaled = |t: &Table, k: u64| t.iter().map(|(v, c)| (*v, c * k)).collect::<Table>();
    assert_eq!(scaled(&bet, 100), scaled(&one, 1000));
    println!("77 bet, 1000 outcomes, {} pay, pmf 0: {:.6}, pmf 100: {:.6}",
             bet[&100], bet[&0] as f64 / 1000.0, bet[&100] as f64 / 1000.0);

    // A function of X is a random variable: net gain Y = X - 2 for a $2 ticket
    let net = table((1..=100).map(|w| x(w) - 2));
    for (v, c) in &net {
        println!("pmf Y, {}, {:.6}", v, *c as f64 / 100.0);
    }
    println!("cdf Y, 0, {:.6}", cdf(&net, 0) as f64 / 100.0);

    // Three separate raffles, one ticket in each: T = total payout
    let vals: Vec<i64> = (1..=100).map(x).collect();
    let (mut three, mut le100) = (Table::new(), 0u64);
    for a in &vals {
        for b in &vals {
            for c in &vals {
                let s = a + b + c;
                *three.entry(s).or_insert(0) += 1;
                if s <= 100 { le100 += 1; }
            }
        }
    }
    let mut prod = Table::new(); // road 2: multiply the single-raffle counts
    for (a, ca) in &one {
        for (b, cb) in &one {
            for (c, cc) in &one {
                *prod.entry(a + b + c).or_insert(0) += ca * cb * cc;
            }
        }
    }
    assert_eq!(prod, three);
    assert_eq!(cdf(&prod, 100), le100);
    for (v, c) in &three {
        println!("pmf T, {}, count {} of 1000000, {:.6}", v, c, *c as f64 / 1e6);
    }
    for at in [0, 100, 200, 300] {
        println!("cdf T, {}, {:.6}", at, cdf(&prod, at) as f64 / 1e6);
    }
    let win = 1.0 - cdf(&prod, 0) as f64 / 1e6;
    println!("P(T >= 100) = 1 - F(0) = {:.6}, {} of 1000000, about 1 in {:.2}",
             win, 1_000_000 - cdf(&prod, 0), 1.0 / win);

    // Road 3: seeded simulation of 200,000 three-raffle weeks
    let (n, mut s) = (200_000u64, 2026u64);
    let mut sim = Table::new();
    println!("simulation, {} weeks, seed {}", n, s);
    for _ in 0..n {
        let mut tot = 0;
        for _ in 0..3 {
            tot += x(splitmix64(&mut s) % 100 + 1);
        }
        *sim.entry(tot).or_insert(0) += 1;
    }
    for v in [0, 100, 200, 300] {
        let p = prod[&v] as f64 / 1e6;
        let q = *sim.get(&v).unwrap_or(&0) as f64 / n as f64;
        let se = (p * (1.0 - p) / n as f64).sqrt();
        assert!((q - p).abs() <= 4.0 * se);
        println!("simulated T, {}, {:.6}, exact {:.6}, se {:.6}", v, q, p, se);
    }

    // What breaks
    println!("break, four values read as equally likely, P(T=0) = {:.6}", 1.0 / 4.0);
    println!("break, strict < in place of <=, P(T<100) = {:.6}", cdf(&prod, 99) as f64 / 1e6);
    println!("break, three win chances added, {:.6}", 3.0 * one[&100] as f64 / 100.0);
    println!("break, one outcome's chance read as P(X=0), {:.6}", 1.0 / 100.0);
    println!("all checks passed");
}
