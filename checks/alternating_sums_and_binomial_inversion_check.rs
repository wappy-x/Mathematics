// Alternating sums and binomial inversion -- the same check as the Python, in Rust.  No
// crates.  Five tunes -- Anchor, Bramble, Cinder, Dovetail, Ember -- and a setlist is a
// running order of some of them.  Pascal's rows come from addition alone, and every
// count is reached twice: once by listing the things, once by a formula.
const ROWS: usize = 10;
const N: usize = 5;
const TUNES: [&str; 5] = ["Anchor", "Bramble", "Cinder", "Dovetail", "Ember"];
fn triangle(top: usize) -> Vec<Vec<i64>> {     // rows 0 to top, each entry from the two above
    let mut out: Vec<Vec<i64>> = vec![vec![1]];
    for n in 1..=top {
        let a = out[n - 1].clone();
        out.push((0..=n).map(|k| if k == 0 || k == n { 1 } else { a[k - 1] + a[k] }).collect());
    }
    out
}
fn factorial(m: i64) -> i64 { if m < 2 { 1 } else { m * factorial(m - 1) } }  // 0! = 1
fn subsets(n: usize) -> Vec<Vec<usize>> {      // every in-or-out choice over n tunes
    (0..(1usize << n)).map(|m| (0..n).filter(|i| m >> i & 1 == 1).collect()).collect()
}
fn setlists(pool: &[usize]) -> Vec<Vec<usize>> {   // every running order of some of the pool
    let mut out: Vec<Vec<usize>> = vec![vec![]];
    for (i, &t) in pool.iter().enumerate() {
        let rest: Vec<usize> = pool.iter().enumerate().filter(|p| p.0 != i).map(|p| *p.1).collect();
        for mut s in setlists(&rest) { s.insert(0, t); out.push(s) }
    }
    out
}
fn signs(row: &[i64]) -> String {              // the row written out with its signs
    row.iter().enumerate().map(|(k, x)| format!("{}{}", if k % 2 == 0 { "+" } else { "-" }, x))
        .collect::<Vec<String>>().join(" ")
}
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }

fn main() {
    let tri = triangle(ROWS);
    let sign = |k: usize, v: i64| if k % 2 == 0 { v } else { -v };
    let signed: Vec<i64> = (0..=ROWS).map(|n| (0..=n).map(|k| sign(k, tri[n][k])).sum()).collect();
    let plain: Vec<i64> = (0..=ROWS).map(|n| tri[n].iter().sum()).collect();
    let parity = |n: usize, r: usize| subsets(n).iter().filter(|s| s.len() % 2 == r).count() as i64;
    let evens: Vec<i64> = (0..=ROWS).map(|n| parity(n, 0)).collect();
    let odds: Vec<i64> = (0..=ROWS).map(|n| parity(n, 1)).collect();
    let diff: Vec<i64> = evens.iter().zip(&odds).map(|(e, o)| e - o).collect();  // road two
    let exact: Vec<i64> = (0..=N).map(|k| factorial(k as i64)).collect();        // a(k) = k!
    let pool: Vec<usize> = (0..N).collect();
    let by_order: Vec<i64> = (0..=N)
        .map(|k| setlists(&pool[..k]).iter().filter(|s| s.len() == k).count() as i64).collect();
    let b_listed: Vec<i64> = (0..=N).map(|n| setlists(&pool[..n]).len() as i64).collect();
    let b_sum: Vec<i64> = (0..=N).map(|n| (0..=n).map(|k| tri[n][k] * exact[k]).sum()).collect();
    let inv = |n: usize, f: usize| -> i64 { (f..=n).map(|k| sign(n - k, tri[n][k] * b_listed[k])).sum() };
    let back: Vec<i64> = (0..=N).map(|n| inv(n, 0)).collect();
    let terms: Vec<i64> = (0..=N).map(|k| sign(N - k, tri[N][k] * b_listed[k])).collect();
    let sizes: Vec<i64> = (0..=N).map(|k| tri[N][k] * exact[k]).collect();
    let unsigned: i64 = (0..=N).map(|k| tri[N][k] * b_listed[k]).sum();   // mistake one: no signs
    let early: i64 = (0..N).map(|k| sign(k, tri[N][k])).sum();            // mistake two: cut short
    let no_zero = inv(N, 1);
    let mut run = terms[0].to_string();
    for t in &terms[1..] { run += &format!(" {} {}", if *t > 0 { "+" } else { "-" }, t.abs()) }
    println!("five tunes: {} -- a setlist is a running order of some of them", TUNES.join(", "));
    println!("row 5 signed: {} -> {}; unsigned -> {}", signs(&tri[5]), signed[5], plain[5]);
    println!("row 10 signed: {} -> {}; unsigned -> {}", signs(&tri[10]), signed[10], plain[10]);
    println!("signed row sums, rows 0 to {}: {:?}", ROWS, signed);
    println!("even-size picks, by listing: {:?}", evens);
    println!("odd-size picks, by listing:  {:?}", odds);
    println!("each signed row sum is even-size minus odd-size: {}", yn(signed == diff));
    println!("setlists of exactly k tunes from {}, k = 0 to {}: {:?}", N, N, sizes);
    println!("'at most' counts b(n) for pools of 0 to {} tunes, by listing every setlist: {:?}", N, b_listed);
    println!("the same counts from b(n) = sum C(n,k) k!: {}", yn(b_listed == b_sum));
    println!("inverting with signs: a(n) = {:?}; k! by multiplying, and by listing running orders: {}",
             back, yn(exact == by_order));
    println!("the inverse at n = {}, term by term: {} = {}", N, run, terms.iter().sum::<i64>());
    println!("mistakes: inverting without signs gives {}, not {}; stopping row {} one term early \
gives {}, not {}; dropping the k = 0 term gives {}, not {}",
             unsigned, back[N], N, early, signed[N], no_zero, back[N]);
    assert!(signed == diff);                     // signed rows against counts of picks by parity
    assert!(b_listed == b_sum && by_order == exact);   // listing against the forward sum
    assert!(back == exact);                      // the signed inverse against k! by multiplying
    assert!((unsigned, early, no_zero) == (872, 1, 121));  // the three mistakes, worked by hand
    println!("ALL CHECKS PASS");
}
