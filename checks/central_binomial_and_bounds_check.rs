// The middle of the row -- the same check as the Python, in Rust.  No crates.  A shop stocks
// 20 cheeses and a tasting board holds 10.  The count of boards is reached four ways, then
// trapped between bounds that never compute it; and again for 5 from 100.
const N: usize = 20; const K: usize = 10; const M: usize = 100; const J: usize = 5;
fn triangle_row(n: usize, width: usize) -> Vec<u64> {   // road one: each entry is the sum of the two above it
    let mut row = vec![0u64; width + 1];                // row 0, kept to its first width + 1 entries
    row[0] = 1;
    for _ in 0..n {
        let mut next = vec![1u64; width + 1];
        for j in 1..=width { next[j] = row[j - 1] + row[j] }
        row = next;
    }
    row
}
fn falling(n: u64, k: u64) -> u64 {                     // n(n-1)...(n-k+1): k slots filled in order
    (0..k).fold(1u64, |out, i| out * (n - i))
}
fn factorial(m: u64) -> u64 { (2..=m).fold(1u64, |out, i| out * i) }   // 1 x 2 x ... x m
fn by_listing(n: usize) -> Vec<u64> {                   // road three: one bit per cheese, in or out
    let mut counts = vec![0u64; n + 1];
    for m in 0..(1u64 << n) { counts[m.count_ones() as usize] += 1 }
    counts
}
fn main() {
    let (row, ten, hundred) = (triangle_row(N, N), triangle_row(K, K), triangle_row(M, J));
    let listed = by_listing(N);
    let central = falling(N as u64, K as u64) / factorial(K as u64);   // road two: the product formula
    let vander: u64 = ten.iter().map(|x| x * x).sum();                 // road four: row 10 squared and added
    let c100 = falling(M as u64, J as u64) / factorial(J as u64);
    let total: u64 = row.iter().sum();
    let avg = total as f64 / (2 * K + 1) as f64;
    let peak = (0..=N).filter(|&k| N - k + 1 > k).max().unwrap();      // the last k whose neighbour ratio beats 1
    let rises = (1..=K).all(|k| row[k] > row[k - 1]);
    let falls = (K + 1..=N).all(|k| row[k] < row[k - 1]);
    let hi20 = (N as u64).pow(K as u32) as f64 / factorial(K as u64) as f64;
    let hi100 = (M as u64).pow(J as u32) as f64 / factorial(J as u64) as f64;
    let (listed_total, ten_sum): (u64, u64) = (listed.iter().sum(), ten.iter().sum());
    let cells: Vec<String> = row.iter().map(|x| x.to_string()).collect();
    let tens: Vec<String> = ten.iter().map(|x| x.to_string()).collect();
    println!("{} cheeses on the counter, a tasting board holds {} of them", N, K);
    println!("four roads to the count: adding down the triangle {}, the product formula {}, \
listing all {} selections {}, squaring and adding row {} {}",
             row[K], central, 1u64 << N, listed[K], K, vander);
    println!("row {}: {}", N, cells.join(" "));
    println!("neighbour ratios at the middle: {}/{} = {:.3} above 1, {}/{} = {:.3} below 1",
             row[K], row[K - 1], row[K] as f64 / row[K - 1] as f64,
             row[K + 1], row[K], row[K + 1] as f64 / row[K] as f64);
    println!("the row rises to k = {} and falls after it: {}; biggest entry {}",
             peak, if rises && falls { "yes" } else { "no" }, row.iter().max().unwrap());
    println!("row {} adds to {} = 4^{}, and the listing found {} selections in all", N, total, K, listed_total);
    println!("upper bound, one entry cannot beat the whole row: {} <= {}", row[K], total);
    println!("lower bound, {} entries so the biggest beats the average: {}/{} = {:.2} <= {}",
             2 * K + 1, total, 2 * K + 1, avg, row[K]);
    println!("the same lower bound cleared of fractions: {} <= {} x {} = {}",
             total, 2 * K + 1, row[K], (2 * K as u64 + 1) * row[K]);
    println!("the middle entry is {:.4} of its row; it beats the average by {:.2} and misses the whole row by {:.2}",
             row[K] as f64 / total as f64, row[K] as f64 / avg, total as f64 / row[K] as f64);
    println!("digit counts: lower bound {}, the count {}, upper bound {}",
             (avg as u64).to_string().len(), row[K].to_string().len(), total.to_string().len());
    println!("bounds at n = {}, k = {}: ({}/{})^{} = {} <= {} <= {}^{}/{}! = {:.2}",
             N, K, N, K, K, (N as u64 / K as u64).pow(K as u32), row[K], N, K, K, hi20);
    println!("bounds at n = {}, k = {}: ({}/{})^{} = {} <= {} <= {}^{}/{}! = {:.2}",
             M, J, M, J, J, (M as u64 / J as u64).pow(J as u32), c100, M, J, J, hi100);
    println!("upper bound divided by the truth: {:.2} at k = {} of {}, {:.2} at k = {} of {}",
             hi20 / row[K] as f64, K, N, hi100 / c100 as f64, J, M);
    println!("house row {}: {} adds to {} = 4^{}", K, tens.join(" "), ten_sum, K / 2);
    println!("house row {} sandwich: {}/{} = {:.2} <= {} <= {}",
             K, ten_sum, K + 1, ten_sum as f64 / (K + 1) as f64, ten[K / 2], ten_sum);
    println!("mistakes: half the row gives {}; 2^{} in place of 4^{} gives {}; the average {:.2} read as the count",
             total / 2, K, K, 2u64.pow(K as u32), avg);
    assert!(row == listed && row[K] == central && row[K] == vander && c100 == hundred[J]);
    assert!(peak == K && row[K] == *row.iter().max().unwrap() && rises && falls);
    assert!(total == 4u64.pow(K as u32) && listed_total == total && row[K] <= total
            && (2 * K as u64 + 1) * row[K] >= total);
    assert!(factorial(K as u64) * row[K] <= (N as u64).pow(K as u32)
            && (K as u64).pow(K as u32) * row[K] >= (N as u64).pow(K as u32)
            && factorial(J as u64) * c100 <= (M as u64).pow(J as u32)
            && (J as u64).pow(J as u32) * c100 >= (M as u64).pow(J as u32));
    println!("ALL CHECKS PASS");
}
