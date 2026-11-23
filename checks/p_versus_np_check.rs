// P versus NP, the Clay problem -- the same check as the Python, in Rust.  No crates.
// One payment, twenty open invoices: which invoices does it pay?  That is SUBSET SUM,
// an NP-complete problem.  Checking a claimed answer is a few additions; finding one
// is a search.  Four roads find the same answer; then the costs are grown to 60 and
// 100 invoices, and the poll counts behind "most believe" are turned into percentages.
use std::collections::HashSet;

fn c(x: u128) -> String {
    let s = x.to_string();
    let mut out = String::new();
    for (i, ch) in s.chars().enumerate() {
        if i > 0 && (s.len() - i) % 3 == 0 { out.push(',') }
        out.push(ch);
    }
    out
}
fn cash(cents: u64) -> String { format!("${}.{:02}", c((cents / 100) as u128), cents % 100) }
fn tf(b: bool) -> &'static str { if b { "True" } else { "False" } }

fn half_sums(xs: &[u64]) -> Vec<u64> {
    let mut out = vec![0u64];
    for &a in xs {
        let more: Vec<u64> = out.iter().map(|s| s + a).collect();
        out.extend(more);
    }
    out
}
fn decide(xs: &[u64], t: u64) -> bool {           // yes/no only, by meet in the middle
    let h = xs.len() / 2;
    let r: HashSet<u64> = half_sums(&xs[h..]).into_iter().collect();
    half_sums(&xs[..h]).iter().any(|&s| s <= t && r.contains(&(t - s)))
}

fn main() {
    let a: [u64; 20] = [48215, 112040, 23999, 375010, 89950, 154281, 61830, 298000, 17465, 205590,
                        73320, 131085, 44700, 260415, 98760, 186230, 35580, 142900, 67125, 228860];
    let (s, m) = (832530u64, a.len());            // the payment, in cents; m invoices
    println!("invoices: m = {}, open total {}; payment S = {}", m, cash(a.iter().sum()), cash(s));

    // 0. The verifier: a claimed list of invoices is checked by adding them up.
    let claim = vec![1usize, 4, 6, 9, 13, 16, 18];
    let (mut total, mut adds) = (0u64, 0);
    for &i in &claim { total += a[i]; adds += 1; }
    println!("certificate check: {} invoices, {} additions, sum {}, matches {}", claim.len(), adds, cash(total), tf(total == s));

    // 1. Brute force: every subset.  sums[mask] is the total of the invoices whose bits are set.
    let sums = half_sums(&a);
    let brute: Vec<usize> = (0..sums.len()).filter(|&k| sums[k] == s).collect();
    let picked: Vec<usize> = (0..m).filter(|&i| brute[0] >> i & 1 == 1).collect();
    println!("brute force: {} subsets, {} match; invoices {:?}", c(sums.len() as u128), brute.len(), picked);

    // 2. Meet in the middle (1974): all sums of each half, sorted, then matched.
    let left = half_sums(&a[..m / 2]);
    let mut right = half_sums(&a[m / 2..]);
    right.sort();
    let mut mitm = 0;
    for &l in &left {
        if l > s { continue }
        let t = s - l;
        mitm += right.partition_point(|&x| x <= t) - right.partition_point(|&x| x < t);
    }
    println!("meet in the middle: {} + {} half-sums, {} match", c(left.len() as u128), c(right.len() as u128), mitm);

    // 3. The amount table (pseudo-polynomial): bit t of reach is 1 when t cents can be made.
    let words = (s as usize + 1 + 63) / 64;
    let mut reach = vec![0u64; words];
    reach[0] = 1;
    for &x in &a {
        let (ws, bs) = ((x / 64) as usize, (x % 64) as u32);
        let old = reach.clone();
        for i in ws..words {
            let mut v = old[i - ws] << bs;
            if bs > 0 && i > ws { v |= old[i - ws - 1] >> (64 - bs) }
            reach[i] |= v;
        }
    }
    let bit = |t: u64| reach[(t / 64) as usize] >> (t % 64) & 1 == 1;
    let cells = m as u128 * (s as u128 + 1);
    println!("amount table: {} columns x {} rows = {} cells, payable {}", c(s as u128 + 1), m, c(cells), tf(bit(s)));
    println!("every invoice 1,000 times larger: {} cells; brute force still {}", c(m as u128 * (1000 * s as u128 + 1)), c(sums.len() as u128));

    // 4. Search from decision: a yes/no oracle, asked once per invoice, recovers the list.
    let (mut keep, mut rest, mut asks) = (Vec::new(), s, 0);
    for i in 0..m {
        asks += 1;
        if !decide(&a[i + 1..], rest) { keep.push(i); rest -= a[i]; }
    }
    println!("search from decision: {} yes/no questions, invoices {:?}, left over {}", asks, keep, rest);

    // 5. Growth: brute force against meet in the middle, at a billion subsets a second.
    let year: u128 = 31557600;                    // seconds in a year of 365.25 days
    for k in [20u32, 40, 60, 100] {
        let p = 1u128 << k;
        let (ms, tenths) = (p / 1_000_000, 10 * p / (1_000_000_000 * year));
        println!("m = {}: subsets {}; half-sums {}; at 1e9 subsets/s {}.{:03} s = {}.{} years",
                 k, c(p), c(1u128 << (k / 2)), c(ms / 1000), ms % 1000, c(tenths / 10), tenths % 10);
    }
    let lg = |x: u128| x.to_string().len() - 1;
    println!("bars, log10 of work at m = 60: brute {}, half-sums {}, check {}", lg(1 << 60), lg(1 << 30), lg(60));

    // 6. Opinion is not proof: three polls of researchers, P != NP answers over all answers.
    for (yr, ne, eq, n) in [(2002u64, 61u64, 9u64, 100u64), (2012, 126, 12, 152), (2019, 109, 15, 124)] {
        let pct = |x: u64| { let r = (1000 * x + n / 2) / n; format!("{}.{}%", r / 10, r % 10) };
        println!("poll {}: {} of {} say P != NP ({}), {} say P = NP ({})", yr, ne, n, pct(ne), eq, pct(eq));
    }
    println!("Clay fund: 7 problems x $1,000,000 = ${}; solved 1, open {}", c(7 * 1000000), 7 - 1);

    let mask: usize = claim.iter().map(|&i| 1usize << i).sum();
    assert!(total == s && brute == vec![mask]);                 // verifier against brute force
    assert!(mitm == brute.len() && mitm == 1);                  // two searches agree
    let sumset: HashSet<u64> = sums.iter().copied().collect();  // table against brute force:
    assert!((0..=s).step_by(997).all(|t| bit(t) == sumset.contains(&t)) && bit(s));
    assert!(keep == claim && rest == 0);                        // decision oracle rebuilds the list
    assert!((1u128 << 60) / (1_000_000_000 * year) == 36);      // by hand: 1.15e18 s / 3.16e16
    println!("ALL CHECKS PASS");
}
