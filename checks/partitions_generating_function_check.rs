// Euler's product -- the same check as the Python, in Rust.  No crates.  Eight identical marbles go
// into unmarked cups, none empty: 22 ways.  The count is reached twice, by listing every split and
// by multiplying one geometric bracket per cup size, and a third time at n = 50 by Euler's
// pentagonal recurrence.  All-different and all-odd splits are counted by listing and by products.
const N: usize = 50; const MARBLES: usize = 8;
fn splits(total: usize, largest: usize) -> Vec<Vec<usize>> {   // non-increasing lists summing to total
    if total == 0 { return vec![vec![]] }
    (1..=largest.min(total)).rev().flat_map(|k| splits(total - k, k).into_iter()
        .map(move |rest| { let mut s = vec![k]; s.extend(rest); s })).collect()
}
fn times(a: &[i128], b: &[i128]) -> Vec<i128> {                // coefficient lists, degrees over N dropped
    (0..=N).map(|d| (0..=d).map(|i| a[i] * b[d - i]).sum()).collect()
}
fn product(factors: Vec<Vec<i128>>) -> Vec<i128> {             // multiply a run of brackets, from 1
    let mut out = vec![0i128; N + 1]; out[0] = 1;
    for f in factors { out = times(&out, &f) }
    out
}
fn any_number_of(k: usize) -> Vec<i128> { (0..=N).map(|d| i128::from(d % k == 0)).collect() }
fn at_most_one(k: usize) -> Vec<i128> { (0..=N).map(|d| i128::from(d == 0 || d == k)).collect() }
fn pentagonal(upto: usize, paired: bool) -> Vec<i128> {        // p(n) = p(n-1) + p(n-2) - p(n-5) - ...
    let mut p = vec![0i128; upto + 1]; p[0] = 1;
    for n in 1..=upto {
        let (mut total, mut j) = (0i128, 1usize);
        while j * (3 * j - 1) / 2 <= n {
            let s: i128 = if paired && j % 2 == 0 { -1 } else { 1 };
            total += [j * (3 * j - 1) / 2, j * (3 * j + 1) / 2].iter()
                .filter(|&&w| w <= n).map(|&w| s * p[n - w]).sum::<i128>();
            j += 1;
        }
        p[n] = total;
    }
    p
}
fn grid(name: &str, values: &[i128]) {
    println!("{:<40}{}", name, values.iter().map(|v| format!("{:>6}", v)).collect::<String>());
}
fn show(rows: &[Vec<usize>]) -> String {
    rows.iter().map(|r| r.iter().map(|k| k.to_string()).collect::<Vec<String>>().join("+"))
        .collect::<Vec<String>>().join("; ")
}
fn main() {
    let euler = product((1..=N).map(any_number_of).collect());
    let pent = pentagonal(N, true);
    let listed: Vec<i128> = (0..11).map(|n| splits(n, n).len() as i128).collect();
    let distinct = product((1..=N).map(at_most_one).collect());
    let odd = product((1..=N).step_by(2).map(any_number_of).collect());
    let all8 = splits(MARBLES, MARBLES);
    let diff8: Vec<Vec<usize>> = all8.iter().filter(|s| s.windows(2).all(|w| w[0] != w[1])).cloned().collect();
    let odd8: Vec<Vec<usize>> = all8.iter().filter(|s| s.iter().all(|k| k % 2 == 1)).cloned().collect();
    let running: Vec<i128> = (1..=MARBLES).map(|m| product((1..=m).map(any_number_of).collect())[MARBLES]).collect();
    let mut comps = vec![0i128; MARBLES + 1]; comps[0] = 1;
    for n in 1..=MARBLES { comps[n] = (1..=n).map(|k| comps[n - k]).sum() }
    println!("{} identical marbles into unmarked cups, none empty; cup sizes 1 to {}", MARBLES, MARBLES);
    grid("marbles to share, n", &(0..11).collect::<Vec<i128>>());
    grid("splits listed one by one", &listed);
    grid("coefficient of x^n in the product", &euler[..11]);
    grid("the same, by the pentagonal recurrence", &pent[..11]);
    grid("all cups different, from 1+x^k", &distinct[..11]);
    grid("all cups odd, from odd sizes only", &odd[..11]);
    println!("the x^{} coefficient as sizes 1 to {} are added: {:?}", MARBLES, MARBLES, running);
    println!("the {} all-different splits of {}: {}", diff8.len(), MARBLES, show(&diff8));
    println!("the {} all-odd splits of {}: {}", odd8.len(), MARBLES, show(&odd8));
    println!("p({}) from the product: {}", N, euler[N]);
    println!("p({}) from the pentagonal recurrence: {}", N, pent[N]);
    println!("mistake 1, order counted: {} ordered writings of {}, not {}", comps[MARBLES], MARBLES, euler[MARBLES]);
    println!("mistake 2, sizes stopped at 4: {}, not {}", running[3], euler[MARBLES]);
    println!("mistake 3, every size at most once: {}, not {}", distinct[MARBLES], euler[MARBLES]);
    println!("mistake 4, pentagonal signs all plus: {}, not {}", pentagonal(MARBLES, false)[MARBLES], euler[MARBLES]);
    assert!(listed == euler[..11].to_vec() && euler[..11] == pent[..11]);   // listing, product, recurrence
    assert!(euler[MARBLES] == 22 && euler[N] == 204226);                   // the published partition numbers
    assert!(distinct == odd && distinct[MARBLES] == diff8.len() as i128 && diff8.len() == odd8.len() && odd8.len() == 6);
    assert!(running == vec![1, 5, 10, 15, 18, 20, 21, 22] && comps[MARBLES] == 1i128 << (MARBLES - 1));
    println!("ALL CHECKS PASS");
}
