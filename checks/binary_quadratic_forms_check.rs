// Binary quadratic forms of discriminant -20 -- the same check as the Python, in Rust.  No crates.
const FORMS: [(i64, i64, i64); 2] = [(1, 0, 5), (2, 2, 3)];   // (a, b, c): a x^2 + b xy + c y^2
const D: i64 = -20; const TOP: i64 = 100;
fn f(g: (i64, i64, i64), x: i64, y: i64) -> i64 { g.0 * x * x + g.1 * x * y + g.2 * y * y }
fn disc(g: (i64, i64, i64)) -> i64 { g.1 * g.1 - 4 * g.0 * g.2 }
fn gcd(x: i64, y: i64) -> i64 { if y == 0 { x.abs() } else { gcd(y, x % y) } }
fn reach(g: (i64, i64, i64), n: i64) -> bool {               // road 1: search coprime x, y
    (-11..12).any(|x| (-11..12).any(|y| f(g, x, y) == n && gcd(x, y) == 1))
}
fn roots(n: i64) -> Vec<i64> { (0..2 * n).filter(|b| (b * b - D) % (4 * n) == 0).collect() } // road 2
fn j(v: &[i64]) -> String { v.iter().map(|n| n.to_string()).collect::<Vec<_>>().join(" ") }
fn m20(v: &[i64]) -> String { let mut m: Vec<i64> = v.iter().map(|n| n % 20).collect(); m.sort(); m.dedup(); j(&m) }
fn main() {
    println!("discriminants: {} {}", disc(FORMS[0]), disc(FORMS[1]));
    for g in FORMS { let v: Vec<i64> = (1..31).filter(|&n| reach(g, n)).collect();
        println!("({}, {}, {}) reaches, up to 30: {}", g.0, g.1, g.2, j(&v)); }
    let (p, q) = (3, 2);                                     // 29 = 3^2 + 5 x 2^2
    let (r, s) = (0..6).flat_map(|r| (0..6).map(move |s| (r, s))).find(|&(r, s)| p * s - q * r == 1).unwrap();
    let (a, c) = (f(FORMS[0], p, q), f(FORMS[0], r, s));
    let b = f(FORMS[0], p + r, q + s) - a - c;               // the new form at X = Y = 1 is a + b + c
    println!("{} = f({}, {}); r, s = {}, {}; new form ({}, {}, {}), discriminant {}; {}^2 + 20 = {} = {} x {}",
             a, p, q, r, s, a, b, c, disc((a, b, c)), b, b * b + 20, (b * b + 20) / (4 * a), 4 * a);
    let b23 = *roots(23).iter().find(|&&b| b % 2 == 0).unwrap();
    let c23 = (b23 * b23 - D) / 92;
    println!("23: b = {}, form (23, {}, {}), discriminant {}", b23, b23, c23, disc((23, b23, c23)));
    let primes: Vec<i64> = (3..TOP).filter(|&n| n != 5 && (2..n).all(|k| n % k != 0)).collect();
    let by: Vec<Vec<i64>> = FORMS.iter().map(|&g| primes.iter().copied().filter(|&n| reach(g, n)).collect()).collect();
    let none: Vec<i64> = primes.iter().copied().filter(|&n| roots(n).is_empty()).collect();
    for (name, l) in [("first form", &by[0]), ("second form", &by[1]), ("neither", &none)] {
        println!("primes below {}, {}: {} | mod 20: {}", TOP, name, j(l), m20(l)); }
    let m4: Vec<i64> = (0..4).filter(|b| (b * b - D) % 4 == 0).collect();
    println!("mistakes: middle read as 1 gives {} | 4 tested mod 4 has roots {} | x^2 + 5y^2 alone misses {} primes",
             1 - 4 * 2 * 3, j(&m4), by[1].len());
    assert!((1..TOP).all(|n| FORMS.iter().any(|&g| reach(g, n)) == !roots(n).is_empty()));
    assert!(a == 29 && disc((a, b, c)) == D && (b * b - D) % (4 * a) == 0 && (r, s) == (1, 1));
    assert!(m20(&by[0]) == "1 9" && m20(&by[1]) == "3 7");
    let mut all: Vec<i64> = [by[0].clone(), by[1].clone(), none.clone()].concat(); all.sort();
    assert!(all == primes && roots(4).is_empty() && !FORMS.iter().any(|&g| reach(g, 4)));
    println!("ALL CHECKS PASS");
}
