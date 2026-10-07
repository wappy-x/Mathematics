// Why the factorisation is unique -- the same check as unique_factorisation_check.py,
// in Rust.  No crates.  86,400 seconds in a day: the smallest-prime-first split,
// then the same day down two trees, 24 x 3600 and 1440 x 60, and a world where it fails.
fn factor(mut n: i64) -> Vec<i64> {          // pull out the smallest prime, over and over
    let (mut out, mut d) = (Vec::new(), 2);
    while d * d <= n {
        while n % d == 0 { out.push(d); n /= d; }
        d += 1;
    }
    if n > 1 { out.push(n); }
    out
}
fn tree(a: i64, b: i64) -> Vec<i64> {        // factor both branches, pool the leaves, sort
    let mut v = factor(a);
    v.extend(factor(b));
    v.sort();
    v
}
fn unsplittable(m: i64) -> bool { (5..m).step_by(4).all(|a| m % a != 0) }   // world 1, 5, 9, 13, ...
fn show(xs: &[i64]) -> String { xs.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(" ") }
fn row(name: &str, value: &str) { println!("{:<40}{}", name, value); }
fn main() {
    let (day, plain) = (86400i64, factor(86400));
    let count = |p: i64| plain.iter().filter(|&&x| x == p).count() as u32;
    let (p2, p3, p5) = (2i64.pow(count(2)), 3i64.pow(count(3)), 5i64.pow(count(5)));
    row("86,400 seconds, smallest prime first", &show(&plain));
    row("the tree 24 x 3600", &show(&tree(24, 3600)));
    row("the tree 1440 x 60", &show(&tree(1440, 60)));
    row("seven 2s, three 3s, two 5s", &format!("{} x {} x {} = {}", p2, p3, p5, p2 * p3 * p5));
    row("primes in the list", &plain.len().to_string());
    row("pieces if you stop at 24 x 3600", &[24, 3600].len().to_string());
    row("primes if you let a 1 in, then two", &format!("{} then {}", plain.len() + 1, plain.len() + 2));
    row("441 in the world 1, 5, 9, 13, ...", &format!("{} = 9 x 49 = 21 x 21", 9 * 49));
    let odd: Vec<i64> = [9, 21, 49].into_iter().filter(|&m| unsplittable(m)).collect();
    row("and 9, 21, 49 unsplittable there", &show(&odd));
    assert!(plain == tree(24, 3600) && plain == tree(1440, 60) && plain.len() == 12);
    assert!(p2 * p3 * p5 == day && (count(2), count(3), count(5)) == (7, 3, 2));
    assert!([9, 21, 49].iter().all(|&m| unsplittable(m)) && 9 * 49 == 441 && 21 * 21 == 441);
    println!("ALL CHECKS PASS");
}
