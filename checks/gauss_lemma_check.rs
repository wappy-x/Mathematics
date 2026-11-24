// Gauss's lemma -- the same check as the Python one, in Rust.  No crates.  Three roads
// to "is a a square on the p-clock?": try every x, Euler's power, and Gauss's count.
fn euler(a: i64, p: i64) -> i64 {      // a multiplied in (p - 1)/2 times, read as 1 or -1
    let mut r = 1;
    for _ in 0..(p - 1) / 2 { r = (r * a).rem_euclid(p); }
    if r == p - 1 { -1 } else { r }
}
fn top(a: i64, p: i64) -> Vec<i64> {   // readings of a, 2a, ... up to (p - 1)/2 times a, above p/2
    (1..(p + 1) / 2).map(|k| (k * a).rem_euclid(p)).filter(|&r| 2 * r > p).collect()
}
fn root(a: i64, p: i64) -> Option<i64> { (1..p).find(|&x| x * x % p == a.rem_euclid(p)) }
fn show(r: Option<i64>) -> String { r.map_or("-".to_string(), |x| x.to_string()) }
fn join(v: &[i64]) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(" ") }
fn main() {
    let reads: Vec<i64> = (1..6).map(|k| k * 3 % 11).collect();
    let fold: Vec<i64> = reads.iter().map(|&r| if 2 * r < 11 { r } else { 11 - r }).collect();
    println!("3 x 1, 2, 3, 4, 5 on the 11-clock reads: {}", join(&reads));
    println!("above 5.5: {} (count {}, even); folded: {}", join(&top(3, 11)), top(3, 11).len(), join(&fold));
    println!("Euler: 3^5 = {} = {} x 11 + {}, reads {}; root {}: 25 reads {}", 3i64.pow(5), 3i64.pow(5) / 11, 3i64.pow(5) % 11, euler(3, 11), show(root(3, 11)), 25 % 11);
    let mut sq: Vec<i64> = (1..11).map(|x| x * x % 11).collect(); sq.sort(); sq.dedup();
    println!("the squares on the 11-clock: {}", join(&sq));
    println!("-1 on 11: count {}, Euler {}, root {}; on 17: count {}, Euler {}, root {}", top(-1, 11).len(), euler(-1, 11), show(root(-1, 11)), top(-1, 17).len(), euler(-1, 17), show(root(-1, 17)));
    for p in [7i64, 11, 13, 17, 23] {
        println!("2 on the {:>2}-clock ({} mod 8): count above {:>4} is {}, Euler {:>2}, root {}", p, p % 8, p as f64 / 2.0, top(2, p).len(), euler(2, p), show(root(2, p)));
    }
    let below = reads.iter().filter(|&&r| 2 * r < 11).count();
    let allten = (1..11).filter(|k| 2 * (k * 3 % 11) > 11).count();
    println!("mistakes: bottom-half count {}, all ten multiples count {}, 2^10 reads {}, 2 on 15 counts {}, root {}", below, allten, 2i64.pow(10) % 11, top(2, 15).len(), show(root(2, 15)));
    let primes: Vec<i64> = (3..200).filter(|&p| (2..p).all(|d| p % d != 0)).collect();
    for &p in &primes {
        for a in 1..p {                 // brute force, Euler and Gauss all agree
            let gauss = if top(a, p).len() % 2 == 0 { 1 } else { -1 };
            assert!(euler(a, p) == if root(a, p).is_some() { 1 } else { -1 } && euler(a, p) == gauss);
        }
        assert!(root(-1, p).is_some() == (p % 4 == 1) && root(2, p).is_some() == (p % 8 == 1 || p % 8 == 7));
    }
    assert!(root(3, 11) == Some(5) && euler(2, 11) == -1 && top(2, 15).len() == 4 && root(2, 15).is_none());
    println!("ALL CHECKS PASS");
}
