// Reduced forms and class numbers, no crates.  A form (a, b, c) is ax^2 + bxy + cy^2, D = b^2 - 4ac < 0.
type F = (i64, i64, i64);
fn shift(f: F, k: i64) -> F { (f.0, f.1 + 2 * f.0 * k, f.0 * k * k + f.1 * k + f.2) }   // x -> x + ky
fn turn(f: F) -> F { (f.2, -f.1, f.0) }                                                   // x -> -y, y -> x
fn reduce(f: F) -> Vec<F> {                       // apply the two moves until -a < b <= a <= c
    let (a, b, c) = f;
    let next = if !(-a < b && b <= a) { shift(f, (a - b).div_euclid(2 * a)) } else if a > c || (a == c && b < 0) { turn(f) } else { return vec![f] };
    let mut out = vec![f]; out.extend(reduce(next)); out
}
fn gcd(x: i64, y: i64) -> i64 { if y == 0 { x.abs() } else { gcd(y, x % y) } }
fn classes(d: i64, lo: i64) -> Vec<F> {           // list the primitive reduced forms directly; 3a^2 <= -D
    let mut out = vec![];
    for a in 1..=((-d as f64 / 3.0).sqrt() as i64) { for b in (lo - a)..=a {
        if (b * b - d) % (4 * a) == 0 { let c = (b * b - d) / (4 * a); if c >= a && (b >= 0 || a < c) && gcd(gcd(a, b), c) == 1 { out.push((a, b, c)); } }
    } }
    out
}
fn ends(d: i64) -> std::collections::BTreeSet<F> { (1..40).flat_map(|a| (-40..41).map(move |b| (a, b))).filter(|&(a, b)| (b * b - d) % (4 * a) == 0 && gcd(gcd(a, b), (b * b - d) / (4 * a)) == 1).map(|(a, b)| *reduce((a, b, (b * b - d) / (4 * a))).last().unwrap()).collect() }
fn values(f: F, top: i64) -> Vec<i64> { let mut v: Vec<i64> = (-9..10).flat_map(|x| (-9..10).map(move |y| f.0 * x * x + f.1 * x * y + f.2 * y * y)).filter(|&n| n >= 1 && n <= top).collect(); v.sort(); v.dedup(); v }
fn sub(f: F, p: i64, q: i64, r: i64, s: i64) -> F { let (a, b, c) = f; (a*p*p + b*p*r + c*r*r, 2*a*p*q + b*(p*s + q*r) + 2*c*r*s, a*q*q + b*q*s + c*s*s) }
fn powmod(k: i64, e: i64, p: i64) -> i64 { (0..e).fold(1, |acc, _| acc * k % p) }
fn dirichlet(p: i64) -> i64 { (1..(p + 1) / 2).map(|k| if powmod(k, (p - 1) / 2, p) == 1 { 1 } else { -1 }).sum::<i64>() / (if p % 8 == 7 { 1 } else { 3 }) }
fn show(v: &[F]) -> String { v.iter().map(|f| format!("{:?}", f)).collect::<Vec<_>>().join(", ") }
fn main() {
    let path = reduce((3, 8, 7));
    let run: Vec<i64> = (0..41).filter(|&n| { let m = n * n + n + 41; (2..m).all(|d| m % d != 0) }).collect();
    let hits: Vec<(i64, i64, i64, i64)> = (-2..3).flat_map(|p| (-2..3).flat_map(move |q| (-2..3).flat_map(move |r| (-2..3).map(move |s| (p, q, r, s))))).filter(|&(p, q, r, s)| p * s - q * r == 1 && sub((3, 8, 7), p, q, r, s) == (2, 2, 3)).collect();
    println!("(3, 8, 7), D = {} - {} = {}: {}", 8 * 8, 4 * 3 * 7, 8 * 8 - 4 * 3 * 7, path.iter().map(|f| format!("{:?}", f)).collect::<Vec<_>>().join(" -> "));
    let h = hits[0]; println!("search, entries -2 to 2, determinant 1: {} substitutions, e.g. x -> ({})x + ({})y, y -> ({})x + ({})y", hits.len(), h.0, h.1, h.2, h.3);
    for d in [-4, -20, -23, -32, -163] { println!("h({}) = {}: {}   reducing every primitive form in a box lands on {}", d, classes(d, 1).len(), show(&classes(d, 1)), ends(d).len()); }
    println!("values up to 15: (1, 0, 5) {:?}, (2, 2, 3) {:?}", values((1, 0, 5), 15), values((2, 2, 3), 15));
    println!("Dirichlet's sum, a second road: h(-23) = {}, h(-163) = {}", dirichlet(23), dirichlet(163));
    println!("n^2 + n + 41 is prime for n = 0 to {}; n = 40 gives {} = 41 x 41", run.len() - 1, 40 * 40 + 40 + 41);
    let plain: std::collections::BTreeSet<F> = classes(-23, 1).iter().map(|&(a, b, c)| (a, b.abs(), c)).collect();
    println!("mistakes: plain swap h(-23) = {}; b = -a let in h(-20) = {}; c left alone D = {}", plain.len(), classes(-20, 0).len(), 2 * 2 - 4 * 3 * 7);
    assert!(path == vec![(3, 8, 7), (3, 2, 2), (2, -2, 3), (2, 2, 3)] && hits.contains(&(-1, -2, 1, 1)));
    assert!([-4, -20, -23, -32, -163].iter().all(|&d| classes(d, 1).into_iter().collect::<std::collections::BTreeSet<F>>() == ends(d)) && [dirichlet(23), dirichlet(163)] == [3, 1] && classes(-32, 1).len() == 2);
    assert!(values((3, 8, 7), 60) == values((2, 2, 3), 60) && values((2, 2, 3), 60) != values((1, 0, 5), 60) && run == (0..40).collect::<Vec<i64>>());
    println!("ALL CHECKS PASS");
}
