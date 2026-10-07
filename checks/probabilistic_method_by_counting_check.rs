// Erdos's counting trick -- the same check as the Python, in Rust, std only, no
// crates.  A server hall of 32 machines, every pair joined by copper or by fibre.
// The plans with ten machines joined all one way are over-counted by formula, then
// the same argument is re-run by listing every plan of K(4) and K(5).
const K: u32 = 10;
const N: u32 = 32;

// n x (n-1) x ... x (n-k+1), so falling(k, k) is k!
fn falling(n: u128, k: u32) -> u128 { (0..k as u128).fold(1, |out, i| out * (n - i)) }
fn choose(n: u128, k: u32) -> u128 {      // road one to C(n, k): multiply and divide in step
    (0..k as u128).fold(1, |c, i| c * (n - i) / (i + 1))
}
fn pascal(n: u32, k: u32) -> u128 {       // road two to C(n, k): Pascal's rule, row by row
    let mut row = vec![1u128];
    for _ in 0..n {
        let mut next = vec![1u128];
        for i in 0..row.len() - 1 { next.push(row[i] + row[i + 1]) }
        next.push(1);
        row = next;
    }
    row[k as usize]
}
fn bound(n: u32, k: u32, colours: u128) -> u128 {    // witnesses x plans per witness
    colours * choose(n as u128, k) << (choose(n as u128, 2) - choose(k as u128, 2))
}
fn share(n: u32, k: u32) -> f64 {         // the over-count over all plans
    2.0 * choose(n as u128, k) as f64 / 2f64.powi(choose(k as u128, 2) as i32)
}
fn bad_by_listing(n: u32, k: u32) -> (u64, u64) {    // every plan of K(n), searched for a one-type k-set
    let mut pairs = Vec::new();
    for i in 0..n { for j in i + 1..n { pairs.push((i, j)) } }
    let masks: Vec<u64> = (0u32..1 << n).filter(|s| s.count_ones() == k).map(|s| {
        pairs.iter().enumerate().filter(|(_, &(i, j))| s >> i & 1 == 1 && s >> j & 1 == 1)
            .fold(0u64, |m, (e, _)| m | 1 << e)
    }).collect();
    let all = 1u64 << pairs.len();
    ((0..all).filter(|c| masks.iter().any(|&m| c & m == 0 || c & m == m)).count() as u64, all)
}
fn root(k: u32) -> u128 {                 // the whole part of 2^(k/2), by halving an interval
    let (mut lo, mut hi) = (1u128, 1u128 << k);
    while hi - lo > 1 { let mid = (lo + hi) / 2; if mid * mid <= 1 << k { lo = mid } else { hi = mid } }
    lo
}
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }

fn main() {
    let (cn2, ck2) = (choose(N as u128, 2) as u32, choose(K as u128, 2) as u32);
    let (c_fall, c_pas) = (choose(N as u128, K), pascal(N, K));
    let exact = share(N, K);
    let loose = 2f64.powi(1 + K as i32 / 2) / falling(K as u128, K) as f64;
    let mut top = N;
    while share(top + 1, K) < 1.0 { top += 1 }        // the largest hall the exact test still clears
    let ((b44, a44), (b54, a54), (b53, a53)) = (bad_by_listing(4, 4), bad_by_listing(5, 4), bad_by_listing(5, 3));
    let passes = (3..17).all(|k| 2 * choose(root(k), k) < 1u128 << choose(k as u128, 2));
    let digits = (cn2 as f64 * 2f64.log10()).floor() as u32 + 1;
    let ordered = falling(N as u128, K);

    println!("k = {}, n = {}: {} pairs, {} inside a ten-set, 2^{} plans, a number of {} digits", K, N, cn2, ck2, cn2, digits);
    println!("ten-sets C({},{}) = {} by falling product, {} by Pascal's rule", N, K, c_fall, c_pas);
    println!("bad plans at most 2 x {} x 2^{}, a share of {}/2^{} = {:.8}", c_fall, cn2 - ck2, c_fall, ck2 - 1, exact);
    println!("loose form 2^{}/{}! = {}/{} = {:.8}", 1 + K / 2, K, 1u32 << (1 + K / 2), falling(K as u128, K), loose);
    println!("loose form under 1 from k = 3 on: 2^5 = {} < (3!)^2 = {}", 1u32 << 5, falling(3, 3).pow(2));
    println!("good plans at least {:.8} x 2^{}, so one exists: {}", 1.0 - exact, cn2, yn(exact < 1.0));
    println!("largest hall the exact test clears at k = {}: {} (share {:.4}); {} gives {:.4}", K, top, share(top, K), top + 1, share(top + 1, K));
    println!("listed, k = 4 on K(4): {} plans, {} bad, bound {}", a44, b44, bound(4, 4, 2));
    println!("listed, k = 4 on K(5): {} plans, {} bad, bound {}, so {} good", a54, b54, bound(5, 4, 2), a54 - b54);
    println!("listed, k = 3 on K(5): {} plans, {} bad, {} good = 5!/(5 x 2); bound {}, over the total", a53, b53, a53 - b53, bound(5, 3, 2));
    println!("n = whole part of 2^(k/2), k = 3 to 16: {:?}", (3..17).map(root).collect::<Vec<u128>>());
    println!("exact test passes at every one of them: {}", yn(passes));
    println!("mistake, ordered lists of ten: {}/2^{} = {:.2}", ordered, ck2 - 1, ordered as f64 / 2f64.powi(ck2 as i32 - 1));
    println!("mistake, one colour only: {:.8}; on K(4) it allows {} bad plan, listing finds {}", exact / 2.0, bound(4, 4, 1), b44);
    assert!(c_fall == c_pas);                                         // two roads to the ten-sets
    assert!(b44 as u128 == bound(4, 4, 2) && b54 as u128 <= bound(5, 4, 2) && a53 - b53 == (falling(5, 5) / 10) as u64);
    assert!(exact <= loose && loose < 1.0);                           // the exact share sits under the loose form
    assert!(passes && (3..17).all(|k| root(k) * root(k) <= 1 << k && 1u128 << k < (root(k) + 1) * (root(k) + 1)));
    println!("ALL CHECKS PASS");
}
