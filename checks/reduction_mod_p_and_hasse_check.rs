// The curve mod p and Hasse's bound -- the same check as the Python, in Rust.
// No crates.  The curve is y^2 = x^3 - 2, with the rational point (3, 5).  Its
// points mod p are counted three ways: by trying every pair (x, y), by Euler's
// square test on each x, and over the 49-element field, where Frobenius
// predicts the count.  Bad primes come from the discriminant and, separately,
// from a hunt for singular points.
const B: i64 = -2;                                   // the curve is y^2 = x^3 + B
type Pt = Option<(i64, i64)>;                        // None is O
type Fr = (i128, i128);                              // exact fraction (top, bottom)

fn f(x: i64, p: i64) -> i64 { (x * x * x + B).rem_euclid(p) }

fn power(a: i64, mut k: i64, p: i64) -> i64 {        // square-and-multiply, mod p
    let (mut out, mut a) = (1, a.rem_euclid(p));
    while k > 0 {
        if k & 1 == 1 { out = out * a % p }
        a = a * a % p;
        k >>= 1;
    }
    out
}

fn euler(v: i64, p: i64) -> i64 {                    // Euler's test: +1, -1 or 0
    let t = power(v, (p - 1) / 2, p);
    if t == p - 1 { -1 } else { t }
}

fn count_pairs(p: i64) -> i64 {                      // road 1: every pair, plus O
    1 + (0..p).map(|x| (0..p).filter(|y| (y * y - f(x, p)).rem_euclid(p) == 0).count() as i64).sum::<i64>()
}

fn count_euler(p: i64) -> i64 {                      // road 2: 1 + (f(x)/p) points per x
    p + 1 + (0..p).map(|x| euler(f(x, p), p)).sum::<i64>()
}

fn primes(n: i64) -> Vec<i64> {
    (2..n).filter(|&q| (2..q).filter(|d| d * d <= q).all(|d| q % d != 0)).collect()
}

fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }

fn add(pp: Pt, qq: Pt, p: i64) -> Pt {               // chord and tangent, mod p
    let ((x1, y1), (x2, y2)) = match (pp, qq) { (None, _) => return qq, (_, None) => return pp, (Some(a), Some(b)) => (a, b) };
    if x1 == x2 && (y1 + y2) % p == 0 { return None }
    let m = if pp == qq { 3 * x1 * x1 % p * power(2 * y1, p - 2, p) % p }
            else { (y2 - y1).rem_euclid(p) * power(x2 - x1, p - 2, p) % p };
    let x3 = (m * m - x1 - x2).rem_euclid(p);
    Some((x3, (m * (x1 - x3) - y1).rem_euclid(p)))
}

fn gcd(a: i128, b: i128) -> i128 { let (mut a, mut b) = (a.abs(), b.abs()); while b != 0 { (a, b) = (b, a % b) } a }

fn norm(t: i128, d: i128) -> Fr {                    // lowest terms, bottom positive
    let g = gcd(t, d) * if d < 0 { -1 } else { 1 };
    (t / g, d / g)
}

fn fadd(a: Fr, b: Fr) -> Fr {
    norm(a.0.checked_mul(b.1).unwrap() + b.0.checked_mul(a.1).unwrap(), a.1.checked_mul(b.1).unwrap())
}

fn fmul(a: Fr, b: Fr) -> Fr { norm(a.0.checked_mul(b.0).unwrap(), a.1.checked_mul(b.1).unwrap()) }

fn neg(a: Fr) -> Fr { (-a.0, a.1) }

fn qadd(pp: (Fr, Fr), qq: (Fr, Fr)) -> (Fr, Fr) {   // chord and tangent over the rationals
    let ((x1, y1), (x2, y2)) = (pp, qq);
    let (top, bot) = if pp == qq { (fmul((3, 1), fmul(x1, x1)), fmul((2, 1), y1)) }
                     else { (fadd(y2, neg(y1)), fadd(x2, neg(x1))) };
    let m = fmul(top, norm(bot.1, bot.0));
    let x3 = fadd(fmul(m, m), neg(fadd(x1, x2)));
    (x3, fadd(fmul(m, fadd(x1, neg(x3))), neg(y1)))
}

fn fq(a: Fr, p: i64) -> i64 {                        // a fraction read mod p
    (a.0.rem_euclid(p as i128) as i64) * power(a.1.rem_euclid(p as i128) as i64, p - 2, p) % p
}

fn m49(a: (i64, i64), b: (i64, i64)) -> (i64, i64) { // the 49-element field: c + d*i, i^2 = -1
    ((a.0 * b.0 - a.1 * b.1).rem_euclid(7), (a.0 * b.1 + a.1 * b.0).rem_euclid(7))
}

fn show(v: &[(i64, i64)]) -> String {
    format!("[{}]", v.iter().map(|(x, y)| format!("({}, {})", x, y)).collect::<Vec<_>>().join(", "))
}

fn main() {
    let p = 7;
    println!("curve y^2 = x^3 - 2 over F_{}; Euler's test raises to the power {}", p, (p - 1) / 2);
    for x in 0..p {
        let v = f(x, p);
        println!("x = {}: f = {}, f^3 = {}, symbol {:+}, points {}", x, v, power(v, 3, p), euler(v, p), 1 + euler(v, p));
    }
    let pts: Vec<(i64, i64)> = (0..p).flat_map(|x| (0..p).map(move |y| (x, y)))
        .filter(|&(x, y)| (y * y - f(x, p)).rem_euclid(p) == 0).collect();
    let (n7, a7) = (count_euler(p), p + 1 - count_euler(p));
    println!("points: {} and O", show(&pts));
    println!("count by every pair {}; by Euler's test {}; a_7 = {}", count_pairs(p), n7, a7);
    let w = 2.0 * (p as f64).sqrt();
    println!("Hasse window: {} - {:.4} to {} + {:.4}; inside: {}", p + 1, w, p + 1, w, yn(a7 * a7 <= 4 * p));
    let mut mults: Vec<Pt> = vec![Some((3, 5))];
    while mults[mults.len() - 1].is_some() { let next = add(mults[mults.len() - 1], Some((3, 5)), p); mults.push(next) }
    let shown: Vec<(i64, i64)> = mults[..mults.len() - 1].iter().map(|q| q.unwrap()).collect();
    println!("multiples of (3, 5) mod 7: {}, then O at {}P", show(&shown), mults.len());
    let base: (Fr, Fr) = ((3, 1), (5, 1));
    let p2 = qadd(base, base);
    let p3 = qadd(p2, base);
    let mut reads_ok = true;
    for (name, q, r) in [("2P", p2, shown[1]), ("3P", p3, shown[2])] {
        let red = (fq(q.0, 7), fq(q.1, 7));
        reads_ok &= red == r;
        println!("{} over Q = ({}/{}, {}/{}) reads mod 7 as ({}, {}); mod-7 sum ({}, {})",
                 name, q.0.0, q.0.1, q.1.0, q.1.1, red.0, red.1, r.0, r.1);
    }
    let f49: Vec<(i64, i64)> = (0..7).flat_map(|c| (0..7).map(move |d| (c, d))).collect();
    let mut roots = std::collections::HashMap::new();
    for &y in &f49 { *roots.entry(m49(y, y)).or_insert(0i64) += 1 }
    let n49 = 1 + f49.iter().map(|&x| { let c = m49(m49(x, x), x); *roots.get(&((c.0 + B).rem_euclid(7), c.1)).unwrap_or(&0) }).sum::<i64>();
    println!("over F_49: counted {}; Frobenius predicts 49 + 1 - (a_7^2 - 14) = {}", n49, 50 - (a7 * a7 - 14));
    let (disc, mut rest, mut bad) = (-16 * 27 * B * B, 16 * 27 * B * B, Vec::new());
    for q in primes(100) { while rest % q == 0 { bad.push(q); rest /= q } }
    let mut bad_set = bad.clone();
    bad_set.dedup();
    let sing = |q: i64| -> Vec<(i64, i64)> { (0..q).flat_map(|x| (0..q).map(move |y| (x, y))).filter(|&(x, y)|
        (y * y - f(x, q)).rem_euclid(q) == 0 && 2 * y % q == 0 && 3 * x * x % q == 0).collect() };
    let singular: Vec<i64> = primes(100).into_iter().filter(|&q| !sing(q).is_empty()).collect();
    let fac: Vec<String> = bad_set.iter().map(|q| format!("{}^{}", q, bad.iter().filter(|&b| b == q).count())).collect();
    println!("discriminant {} = -({}); bad primes {:?}", disc, fac.join(" x "), bad_set);
    println!("primes below 100 with a singular point mod p: {:?}", singular);
    for q in [2, 3] { let c = sing(q)[0]; println!("mod {}: {} points with O; singular point ({}, {})", q, count_pairs(q), c.0, c.1) }
    let sweep: Vec<i64> = primes(1000)[2..].to_vec();
    let counts: std::collections::HashMap<i64, i64> = sweep.iter().map(|&q| (q, count_euler(q))).collect();
    let ratio = |q: i64| ((q + 1 - counts[&q]).abs() as f64) / (q as f64).sqrt();
    let mut worst = sweep[0];
    for &q in &sweep { if ratio(q) > ratio(worst) { worst = q } }
    let ss: Vec<i64> = sweep.iter().copied().filter(|q| q % 3 == 2).collect();
    let hasse_all = sweep.iter().all(|&q| (q + 1 - counts[&q]).pow(2) <= 4 * q);
    println!("primes {} to {}: {}; all inside Hasse's window: {}", sweep[0], sweep[sweep.len() - 1], sweep.len(), yn(hasse_all));
    println!("closest to the edge: p = {}, a_p = {}, |a_p|/(2 sqrt p) = {:.4}", worst, worst + 1 - counts[&worst], ratio(worst) / 2.0);
    println!("primes 2 mod 3: {}; all with exactly p + 1 points: {}", ss.len(), yn(ss.iter().all(|&q| counts[&q] == q + 1)));
    for &q in &primes(62)[2..] {
        let s = 2.0 * (q as f64).sqrt();
        println!("chart, p = {}, count {}, low {:.2}, high {:.2}", q, counts[&q], q as f64 + 1.0 - s, q as f64 + 1.0 + s);
    }
    println!("mistake 1, O left out: {}", n7 - 1);
    println!("mistake 2, one point per square x: {}", 1 + (0..p).filter(|&x| euler(f(x, p), p) == 1).count());
    println!("mistake 3, exponent p - 1 for (p - 1)/2: {}", 1 + (0..p).map(|x| 1 + power(f(x, p), p - 1, p)).sum::<i64>());
    println!("figure, F_7 points: {}", pts.iter().map(|(x, y)| format!("({},{})", x, y)).collect::<Vec<_>>().join(" "));
    assert!(count_pairs(p) == n7 && n7 == 7 && mults.len() as i64 == n7);             // three roads to 7
    assert!(sweep.iter().filter(|&&q| q < 200).all(|&q| count_pairs(q) == counts[&q])); // pairs against Euler
    assert!(n49 == 50 - (a7 * a7 - 14) && n49 == 63);                                  // Frobenius over F_49
    assert!(reads_ok);                                                                 // reduction respects adding
    assert!(bad_set == singular && singular == vec![2, 3]);                            // two roads to bad primes
    assert!(hasse_all);                                                                // Hasse, exactly
    assert!(ss.iter().all(|&q| counts[&q] == q + 1));                                 // cubing permutes F_p
    println!("ALL CHECKS PASS");
}
