// Baire category theorem -- the same check as baire_category_theorem_check.py, in Rust.
// Standard library only, no crates.  Exact fractions on i128, kept in lowest terms.
// Space: the metre stick [0, 1], distance |x - y| in metres.
// Compile: rustc --edition 2021 -O baire_category_theorem_check.rs -o /tmp/baire_check
use std::cmp::Ordering;
use std::fmt;

fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
struct Q { n: i128, d: i128 }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d).max(1); let s = if d < 0 { -1 } else { 1 }; Q { n: s * n / g, d: s * d / g } }
impl std::ops::Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.n * o.d + o.n * self.d, self.d * o.d) } }
impl std::ops::Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { q(self.n * o.d - o.n * self.d, self.d * o.d) } }
impl std::ops::Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.n * o.n, self.d * o.d) } }
impl std::ops::Div for Q { type Output = Q; fn div(self, o: Q) -> Q { q(self.n * o.d, self.d * o.n) } }
impl PartialOrd for Q { fn partial_cmp(&self, o: &Q) -> Option<Ordering> { Some(self.cmp(o)) } }
impl Ord for Q { fn cmp(&self, o: &Q) -> Ordering { (self.n * o.d).cmp(&(o.n * self.d)) } }
impl fmt::Display for Q {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        let s = if self.d == 1 { format!("{}", self.n) } else { format!("{}/{}", self.n, self.d) };
        f.pad(&s)
    }
}

// the rationals in [0, 1] in one queue: by denominator, then numerator, lowest terms only
fn queue(count: usize) -> Vec<Q> {
    let (mut out, mut d) = (Vec::new(), 1i128);
    while out.len() < count {
        for p in 0..=d { if gcd(p, d) == 1 && out.len() < count { out.push(q(p, d)); } }
        d += 1;
    }
    out
}

// Euler's totient from the prime factors, no gcd
fn phi(n: i128) -> i128 {
    let (mut r, mut m, mut p) = (n, n, 2i128);
    while p * p <= m {
        if m % p == 0 { while m % p == 0 { m /= p; } r -= r / p; }
        p += 1;
    }
    if m > 1 { r - r / m } else { r }
}

// Baire's proof, run: keep a closed third of the interval that misses the next rational
fn chase(qs: &[Q], last: bool) -> Vec<(Q, Q, Q)> {
    let (mut a, mut b, mut rows) = (q(0, 1), q(1, 1), Vec::new());
    for &x in qs {
        let w = (b - a) / q(3, 1);
        let mut thirds = vec![(a, a + w), (a + w, a + w + w), (a + w + w, b)];
        if last { thirds.reverse(); }
        let t = *thirds.iter().find(|t| !(t.0 <= x && x <= t.1)).unwrap();
        a = t.0; b = t.1;
        rows.push((x, a, b));
    }
    rows
}

// membership by integer cross-multiplication, not by the fraction ordering
fn inside(x: Q, a: Q, b: Q) -> bool { a.n * x.d <= x.n * a.d && x.n * b.d <= b.n * x.d }

// the fraction with the smallest denominator in [a, b], by brute force over denominators
fn simplest(a: Q, b: Q) -> Q {
    let mut d = 1i128;
    loop {
        let p = -((-a.n * d).div_euclid(a.d));
        if p * b.d <= b.n * d { return q(p, d); }
        d += 1;
    }
}

fn dec(x: Q, k: u32) -> String {
    let s = format!("{:0>w$}", x.n * 10i128.pow(k) / x.d, w = k as usize + 1);
    format!("{}.{}", &s[..s.len() - k as usize], &s[s.len() - k as usize..])
}
fn rnd(x: Q, k: u32) -> String { dec(x + q(1, 2 * 10i128.pow(k)), k) }

// Cantor dust: at stage n cut a middle gap of length cut(n, piece) out of every piece
fn dust(stages: u32, cut: &dyn Fn(u32, Q) -> Q) -> Vec<(u32, Q, Q)> {
    let (mut pieces, mut rows) = (vec![(q(0, 1), q(1, 1))], Vec::new());
    for n in 1..=stages {
        let mut new = Vec::new();
        for &(a, b) in &pieces {
            let (m, g) = ((a + b) / q(2, 1), cut(n, b - a));
            new.push((a, m - g / q(2, 1)));
            new.push((m + g / q(2, 1), b));
        }
        pieces = new;
        let total = pieces.iter().fold(q(0, 1), |s, &(a, b)| s + (b - a));
        let longest = pieces.iter().map(|&(a, b)| b - a).max().unwrap();
        rows.push((n, total, longest));
    }
    rows
}

fn main() {
    let qs = queue(20);
    let first: Vec<String> = qs[..12].iter().map(|x| x.to_string()).collect();
    println!("queue, first 12: {}", first.join(" "));
    let k = 1 + (1..=10).map(phi).sum::<i128>() as usize;
    let (ek, ek1) = (*queue(k).last().unwrap(), *queue(k + 1).last().unwrap());
    println!("queue, denominators up to 10: {} by totients; entry {} is {}, entry {} is {}", k, k, ek, k + 1, ek1);
    assert!(ek.d == 10 && ek1.d == 11, "count by gcd scan vs totients");

    let rows = chase(&qs, false);
    println!("chase, step  dodge  kept interval (m)   width (m)");
    for (i, &(x, a, b)) in rows[..6].iter().enumerate() {
        println!("chase, {:>4}  {:>5}  {:<18}  {}", i + 1, x, format!("[{}, {}]", a, b), b - a);
    }
    for (i, &(_, a, b)) in rows.iter().enumerate() {
        assert!(b - a == q(1, 3i128.pow(i as u32 + 1)), "width after n dodges is 1/3^n");
        assert!(!qs[..=i].iter().any(|&y| inside(y, a, b)), "kept interval holds none of the dodged rationals");
    }
    let (a6, b6) = (rows[5].1, rows[5].2);
    let s6 = simplest(a6, b6);
    assert!(inside(s6, a6, b6) && !qs[..6].contains(&s6), "simplest fraction is inside and was not dodged");
    let found: Vec<Q> = (1..=s6.d).flat_map(|d| (0..=d).map(move |p| q(p, d))).filter(|&x| a6 <= x && x <= b6).collect();
    assert!(!found.is_empty() && found.iter().all(|&x| x == s6), "second search");
    println!("chase, after 6 steps: width {} m = {} m; simplest fraction still inside: {}", b6 - a6, rnd(b6 - a6, 6), s6);
    let (a20, b20) = (rows[19].1, rows[19].2);
    let hits = qs.iter().filter(|&&y| inside(y, a20, b20)).count();
    println!("chase, after 20 steps: width {} m; dodged rationals inside: {}", b20 - a20, hits);
    let lt = chase(&qs, true)[5];
    println!("chase, last-third rule after 6 steps: [{}, {}]", lt.1, lt.2);

    println!("dust, stage  length left (m)  longest piece (m)");
    for (n, total, longest) in dust(10, &|n, _| q(1, 4i128.pow(n))) {
        assert!(total == q(1, 2) + q(1, 2i128.pow(n + 1)), "length left vs 1/2 + 1/2^(n+1)");
        assert!(longest == q(1, 2i128.pow(n + 1)) + q(1, 2i128.pow(2 * n + 1)), "longest piece vs closed form");
        if [1, 2, 3, 4, 10].contains(&n) {
            println!("dust, {:>5}  {:>15}  {:>17}  = {}, {}", n, total, longest, rnd(total, 6), rnd(longest, 6));
        }
    }
    let thin = dust(10, &|_, piece| piece / q(3, 1))[9].1;
    assert!(thin == q(1024, 59049), "ordinary Cantor dust keeps 2/3 of its length each stage");
    println!("dust, ordinary middle thirds, stage 10: {} m = {} m", thin, rnd(thin, 6));
    let half = dust(10, &|n, _| q(1, 2 * 4i128.pow(n)))[9].1;
    assert!(half == q(3, 4) + q(1, 4 * 2i128.pow(10)), "half-size gaps leave 3/4 + 1/2^12");
    println!("dust, half-size gaps, stage 10: {} m = {} m", half, rnd(half, 6));

    println!("breaks, open intervals (0, 1/3^n): the 20th is (0, {}); all of them miss 0", q(1, 3i128.pow(20)));
    for n in 0..5usize {
        let (a, b) = if n == 0 { (q(0, 1), q(1, 1)) } else { (rows[n - 1].1, rows[n - 1].2) };
        let px = |x: Q| rnd(q(20, 1) + q(400, 1) * x, 1);
        let dodge = if n < 4 { format!("next dodge {} at {}", qs[n], px(qs[n])) } else { "end".to_string() };
        println!("figure, step {}: kept {} to {} px; {}", n, px(a), px(b), dodge);
    }
    println!("ALL CHECKS PASS");
}
