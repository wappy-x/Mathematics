// The exponential formula -- the same check as the Python, in Rust.  No crates.  A series
// is kept as its counts: entry n is n! times the coefficient of x^n.  Multiplying two
// series is then the labelled product, C(n, k) ways to share the labels, in whole numbers.
type V = Vec<i128>;
const N: usize = 6;                                    // sizes 0 to 5
fn fact(n: usize) -> i128 { (1..=n as i128).product() }
fn choose(n: usize, k: usize) -> i128 { fact(n) / (fact(k) * fact(n - k)) }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a } else { gcd(b, a % b) } }
fn times(a: &V, b: &V, n: usize) -> V { (0..n).map(|m| (0..=m).map(|k| choose(m, k) * a[k] * b[m - k]).sum()).collect() }
fn power(c: &V, k: usize, n: usize) -> V {             // C(x) to the k, as counts
    if k == 0 { (0..n).map(|m| (m == 0) as i128).collect() } else { times(&power(c, k - 1, n), c, n) }
}
fn exp(c: &V, n: usize) -> V {                         // road 1: add up C^k / k!
    (0..n).map(|m| (0..=m).map(|k| power(c, k, n)[m] / fact(k)).sum()).collect()
}
fn log(a: &V, n: usize) -> V {                         // add up (-1)^(k+1) (A - 1)^k / k
    let d: V = (0..n).map(|m| if m == 0 { 0 } else { a[m] }).collect();
    (0..n).map(|m| (1..=m).map(|k| (if k % 2 == 1 { 1 } else { -1 })
        * (power(&d, k, n)[m] / fact(k)) * fact(k - 1)).sum()).collect()
}
fn newest(c: &V, n: usize) -> V {                      // road 2: the piece holding label n
    let mut a: V = vec![1];
    for m in 1..n { let s = (1..=m).map(|k| choose(m - 1, k - 1) * c[k] * a[m - k]).sum(); a.push(s) }
    a
}
fn peel(a: &V, n: usize) -> V {                        // road 2 run backwards
    let mut c: V = vec![0];
    for m in 1..n { let s: i128 = (1..m).map(|k| choose(m - 1, k - 1) * c[k] * a[m - k]).sum(); c.push(a[m] - s) }
    c
}
fn selfundo(n: usize) -> i128 {                        // road 3: try every map, keep p(p(i)) = i
    (0..n.pow(n as u32)).filter(|code| { let p: Vec<usize> = (0..n).map(|i| code / n.pow(i as u32) % n).collect();
        (0..n).all(|i| p[p[i]] == i) }).count() as i128
}
fn graphs(n: usize) -> (i128, i128) {                  // road 3: every graph, flood from vertex 0
    let pairs: Vec<(usize, usize)> = (0..n).flat_map(|i| (i + 1..n).map(move |j| (i, j))).collect();
    let (mut conn, mut bare) = (0, 0);
    for mask in 0..1usize << pairs.len() {
        let e: Vec<&(usize, usize)> = pairs.iter().enumerate().filter(|(b, _)| mask >> b & 1 == 1).map(|(_, p)| p).collect();
        let mut seen: Vec<bool> = (0..n).map(|v| v == 0).collect();
        for _ in 0..n { for &&(i, j) in &e { if seen[i] || seen[j] { seen[i] = true; seen[j] = true } } }
        if seen.iter().all(|&s| s) { conn += 1 }
        if (0..n).all(|v| e.iter().any(|&&(i, j)| i == v || j == v)) { bare += 1 }
    }
    (conn, bare)
}
fn main() {
    let inv: V = vec![0, 1, 1, 0, 0, 0];               // a lone letter, or one cable
    let (i5, g5, r): (V, V, V) = (exp(&inv, N), (0..N).map(|n| 1i128 << (n * (n - 1) / 2)).collect(), newest(&inv, N));
    let (ordered, g): (V, i128) = ([3, 4, 5].iter().map(|&k| power(&inv, k, N)[5]).collect(), gcd(i5[5], fact(5)));
    let tries: V = (0..N).map(selfundo).collect();
    println!("involutions, e^(x + x^2/2), n = 0..5: {:?}", i5);
    println!("  same by the newest-letter recurrence: {:?}, a_5 = {} + 4 x {} = {}", r, r[4], r[3], r[4] + 4 * r[3]);
    println!("  same by trying every map:             {:?}", tries);
    let split: V = ordered.iter().zip([3, 4, 5]).map(|(o, k)| o / fact(k)).collect();
    println!("n = 5 by pieces k = 3, 4, 5: ordered {:?}, {} = 120 x {}/{}; divided by k! {:?}", ordered, ordered[0], ordered[0] / gcd(ordered[0], 120), 120 / gcd(ordered[0], 120), split);
    println!("coefficient of x^5: {}/120 = {}/{}, and 120 x {}/{} = {}", i5[5], i5[5] / g, 120 / g, i5[5] / g, 120 / g, i5[5]);
    let (ones, cyc): (V, V) = ((0..N).map(|n| (n > 0) as i128).collect(), (0..N).map(|n| if n > 0 { fact(n - 1) } else { 0 }).collect());
    println!("set partitions, e^(e^x - 1): {:?}", exp(&ones, N));
    println!("shuffles by cycles, e^(-ln(1 - x)): {:?}", exp(&cyc, N));
    let (l, brute): (V, Vec<(i128, i128)>) = (log(&g5, N), (1..N).map(graphs).collect());
    let (hand, conn): (Vec<[i128; 3]>, V) = ([1, 2, 3].iter().map(|&k| [choose(3, k - 1), l[k], g5[4 - k]]).collect(), brute.iter().map(|b| b.0).collect());
    println!("graphs on n = 1..5 vertices:        {:?}", &g5[1..]);
    println!("  connected, by the logarithm:      {:?}", &l[1..]);
    println!("  connected, by peeling backwards:  {:?}", &peel(&g5, N)[1..]);
    println!("  connected, by searching them all: {:?}", conn);
    println!("n = 4 by hand: 2^{} = {}, and {} - ({}) = {} - ({}) = {}", 4 * 3 / 2, g5[4], g5[4], hand.iter().map(|h| format!("{} x {} x {}", h[0], h[1], h[2])).collect::<Vec<_>>().join(" + "), g5[4], hand.iter().map(|h| (h[0] * h[1] * h[2]).to_string()).collect::<Vec<_>>().join(" + "), g5[4] - hand.iter().map(|h| h[0] * h[1] * h[2]).sum::<i128>());
    let pc: V = (0..27).map(|n| (n == 1 || n == 2) as i128).collect();
    let (p, ten) = (newest(&pc, 27)[26], fact(26) / (fact(6) * fact(10) * 1024));
    println!("plugboard, 26 letters: 10 cables {}; any number of cables {}", ten, p);
    println!("mistake 1, pieces as a list (no 1/k!): {}", (0..6).map(|k| power(&inv, k, N)[5]).sum::<i128>());
    println!("mistake 2, a cable counted as an ordered pair: {}", exp(&vec![0, 1, 2, 0, 0, 0], N)[5]);
    println!("mistake 3, only a lone computer counts as cut off: {}", brute[3].1);
    assert!(i5 == newest(&inv, N) && i5 == tries && i5 == vec![1, 1, 2, 4, 10, 26]);
    assert!(exp(&ones, N) == newest(&ones, N) && exp(&ones, N) == vec![1, 1, 2, 5, 15, 52]);
    assert!(exp(&cyc, N) == (0..N).map(fact).collect::<V>());
    assert!(l == peel(&g5, N) && l[1..] == conn[..] && l[0] == 0 && l[4] == 38 && exp(&l, N) == g5);
    assert!(p == (0..14).map(|j| fact(26) / (fact(26 - 2 * j) * fact(j) * (1i128 << j))).sum::<i128>());
    println!("ALL CHECKS PASS");
}
