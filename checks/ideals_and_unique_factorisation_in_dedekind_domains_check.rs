// Ideals factor uniquely even where numbers do not -- the same check as the
// Python, in Rust.  No crates.  A number x + y*sqrt(d) is the pair (x, y).  An
// ideal is stored by its lattice basis (a, 0), (b, c), with 0 <= b < a, so equal
// ideals have equal triples (a, b, c), and its norm (the count of classes) is a * c.
type V = (i64, i64);
type Id = (i64, i64, i64);
const D: i64 = -5;
const B: i64 = 100;                                // the ring Z[sqrt(-5)]; ideals up to norm 100

fn fdiv(a: i64, b: i64) -> i64 { let q = a / b; if a % b != 0 && ((a < 0) != (b < 0)) { q - 1 } else { q } }
fn fmod(a: i64, b: i64) -> i64 { a - b * fdiv(a, b) }
fn mul(u: V, v: V, d: i64) -> V { (u.0 * v.0 + d * u.1 * v.1, u.0 * v.1 + u.1 * v.0) }

fn egcd(p: i64, q: i64) -> (i64, i64, i64) {      // Euclid, extended: p*s + q*t = g
    if q == 0 { return (p, 1, 0) }
    let (g, s, t) = egcd(q, fmod(p, q));
    (g, t, s - fdiv(p, q) * t)
}

fn lattice(vecs: &[V]) -> Id {                     // road 1: reduce generators to (a, b, c)
    let mut w: V = (0, 0);
    for v in vecs { let (g, s, t) = egcd(w.1, v.1); w = (s * w.0 + t * v.0, g) }
    if w.1 < 0 { w = (-w.0, -w.1) }
    let mut a = 0;
    for v in vecs { a = egcd(a, v.0 - fdiv(v.1, w.1) * w.0).0 }
    let a = a.abs();
    (a, fmod(w.0, a), w.1)
}

fn ideal(gens: &[V], d: i64) -> Id {               // the multiples of the generators
    let mut all: Vec<V> = gens.to_vec();
    for g in gens { all.push(mul(*g, (0, 1), d)) }
    lattice(&all)
}

fn basis(i: Id) -> [V; 2] { [(i.0, 0), (i.1, i.2)] }

fn times(i: Id, j: Id, d: i64) -> Id {             // every product of a member of I and of J
    let mut g = Vec::new();
    for u in basis(i) { for v in basis(j) { g.push(mul(u, v, d)) } }
    ideal(&g, d)
}

fn inside(i: Id, v: V) -> bool { fmod(v.1, i.2) == 0 && fmod(v.0 - fdiv(v.1, i.2) * i.1, i.0) == 0 }
fn norm(i: Id) -> i64 { i.0 * i.2 }

fn is_prime(i: Id) -> bool {                       // no two nonzero classes multiply to 0
    let reps: Vec<V> = (0..i.0).flat_map(|x| (0..i.2).map(move |y| (x, y))).skip(1).collect();
    norm(i) > 1 && reps.iter().all(|&r| reps.iter().all(|&s| !inside(i, mul(r, s, D))))
}

fn divides(dd: V, g: V) -> bool {                  // road 2: is g a multiple of dd in the ring?
    let n = dd.0 * dd.0 - D * dd.1 * dd.1;
    let (x, y) = mul(g, (dd.0, -dd.1), D);
    fmod(x, n) == 0 && fmod(y, n) == 0
}

fn witness(gens: &[V], target: V) -> Option<Vec<i64>> { // road 2: target as a small sum of generators
    let k = gens.len() as u32;
    for code in 0..3i64.pow(k) {
        let cs: Vec<i64> = (0..k).map(|i| (code / 3i64.pow(i)) % 3 - 1).collect();
        let s = cs.iter().zip(gens).fold((0, 0), |acc, (c, g)| (acc.0 + c * g.0, acc.1 + c * g.1));
        if s == target { return Some(cs) }
    }
    None
}

fn factor_count(i: Id, primes: &[Id], ideals: &[Id], start: usize) -> i64 { // lists of prime ideals giving I
    if norm(i) == 1 { return 1 }
    let mut total = 0;
    for k in start..primes.len() {
        let p = primes[k];
        if norm(i) % norm(p) == 0 && inside(p, basis(i)[0]) && inside(p, basis(i)[1]) {
            for &j in ideals {
                if norm(j) == norm(i) / norm(p) && times(p, j, D) == i { total += factor_count(j, primes, ideals, k) }
            }
        }
    }
    total
}

fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn show(i: Id) -> String { format!("(a, b, c) = {:?}, norm {}", i, norm(i)) }

fn fmt(v: V) -> String {                           // (4, -1) prints as 4 - r
    if v.1 == 0 { return format!("{}", v.0) }
    let sign = if v.1 > 0 { "+" } else { "-" };
    let k = if v.1.abs() == 1 { String::new() } else { format!("{}", v.1.abs()) };
    format!("{} {} {}r", v.0, sign, k)
}

fn main() {
    let (p2, p3, q3) = (ideal(&[(2, 0), (1, 1)], D), ideal(&[(3, 0), (1, 1)], D), ideal(&[(3, 0), (1, -1)], D));
    let six = ideal(&[(6, 0)], D);
    let small: Vec<V> = (-2..3).flat_map(|x| (-1..2).map(move |y| (x, y))).filter(|&(x, y)| [2, 3].contains(&(x * x + 5 * y * y))).collect();
    println!("6 = 2 x 3 = (1 + r)(1 - r), r = sqrt(-5): {}; norms 4, 9, 6, 6", fmt(mul((1, 1), (1, -1), D)));
    println!("numbers of norm 2 or 3: {:?}", small);
    println!("P2 = (2, 1 + r):  {}; prime: {}", show(p2), yn(is_prime(p2)));
    println!("P3 = (3, 1 + r):  {}; prime: {}", show(p3), yn(is_prime(p3)));
    println!("Q3 = (3, 1 - r):  {}; prime: {}", show(q3), yn(is_prime(q3)));
    let pairs = [("P2 x P2", times(p2, p2, D), (2, 0)), ("P3 x Q3", times(p3, q3, D), (3, 0)),
                 ("P2 x P3", times(p2, p3, D), (1, 1)), ("P2 x Q3", times(p2, q3, D), (1, -1))];
    for (name, i, num) in pairs { println!("road 1: {} = {} = ({}): {}", name, show(i), fmt(num), yn(i == ideal(&[num], D))) }
    let mut road2 = Vec::new();
    let r2: [(&str, Vec<V>, V); 3] = [("P2 x P2", vec![(4, 0), (2, 2), (-4, 2)], (2, 0)),
        ("P3 x Q3", vec![(9, 0), (3, -3), (3, 3), (6, 0)], (3, 0)), ("P2 x P3", vec![(6, 0), (2, 2), (3, 3), (-4, 2)], (1, 1))];
    for (name, gens, num) in r2.iter() {
        let (cs, ok) = (witness(gens, *num), gens.iter().all(|&g| divides(*num, g)));
        road2.push(ok && cs.is_some());
        println!("road 2: {}: generators {:?}, all multiples of {}: {}; {} = {:?} . generators", name, gens, fmt(*num), yn(ok), fmt(*num), cs.unwrap_or_default());
    }
    let whole = times(times(p2, p2, D), times(p3, q3, D), D);
    let other = times(times(p2, p3, D), times(p2, q3, D), D);
    println!("(6) = {}; (2)(3) grouping {}; (1 + r)(1 - r) grouping {}", show(six), yn(whole == six), yn(other == six));
    println!("norm check: N(6) = 6 x 6 = 36, ideal norms 2 x 2 x 3 x 3 = {}", norm(p2) * norm(p2) * norm(p3) * norm(q3));
    let mut ideals: Vec<Id> = Vec::new();
    for c in 1..=B { for a in (c..=B / c).step_by(c as usize) { for b in (0..a).step_by(c as usize) {
        let i = (a, b, c);
        if inside(i, mul((a, 0), (0, 1), D)) && inside(i, mul((b, c), (0, 1), D)) { ideals.push(i) }
    } } }
    let primes: Vec<Id> = ideals.iter().copied().filter(|&i| is_prime(i)).collect();
    let principal = ideals.iter().filter(|&&i| (0..11).any(|x: i64| (-10..11).any(|y: i64| x * x - D * y * y == norm(i) && inside(i, (x, y))))).count();
    let conj = ideals.iter().filter(|&&i| times(i, ideal(&[(i.1, -i.2), (i.0, 0)], D), D) == ideal(&[(norm(i), 0)], D)).count();
    let counts: Vec<i64> = ideals.iter().filter(|&&i| norm(i) > 1).map(|&i| factor_count(i, &primes, &ideals, 0)).collect();
    let mut pn: Vec<i64> = primes.iter().map(|&p| norm(p)).collect();
    pn.sort();
    println!("ideals of norm 1 to {}: {}; prime ideals among them: {}; principal (one number's multiples): {}", B, ideals.len(), primes.len(), principal);
    println!("prime ideal norms: {:?}", pn);
    println!("ideal times its mirror = (its norm), all {} ideals: {}", ideals.len(), yn(conj == ideals.len()));
    let unique = counts.iter().all(|&c| c == 1);
    println!("factorisations into prime ideals, ideals of norm 2 to {}: {} ideals, each with exactly one: {}", B, counts.len(), yn(unique));
    let (r7, s7) = (ideal(&[(7, 0), (3, 1)], D), ideal(&[(7, 0), (3, -1)], D));
    let named = [("P3", p3), ("Q3", q3), ("R7", r7), ("S7", s7)];
    let mut parts = Vec::new();
    let mut single = true;
    for v in [(1, 2), (1, -2), (4, 1), (4, -1)] {
        let mut hits = Vec::new();
        for (m, pm) in &named[..2] { for (n, pn) in &named[2..] {
            if times(*pm, *pn, D) == ideal(&[v], D) { hits.push(format!("{} x {}", m, n)) }
        } }
        single &= hits.len() == 1;
        parts.push(format!("{} = {}", fmt(v), hits.join(" ")));
    }
    println!("21 = 3 x 7 = (1 + 2r)(1 - 2r) = (4 + r)(4 - r); R7 = (7, 3 + r) and S7 = (7, 3 - r) prime: {}; (7) = R7 x S7: {}",
             yn(is_prime(r7) && is_prime(s7)), yn(times(r7, s7, D) == ideal(&[(7, 0)], D)));
    println!("the other four factors: {}", parts.join("; "));
    let wrong = ideal(&[(6, 0), mul((1, 1), (1, 1), D)], D);
    println!("mistake 1, matching pairs only: P2 x P3 taken as (6, (1 + r)^2) has norm {}, not {}", norm(wrong), norm(times(p2, p3, D)));
    let two = ideal(&[(2, 0)], D);
    println!("mistake 2, (2) taken as a prime ideal: prime? {}; 2 divides (1 + r)(1 - r) = 6, divides 1 + r? {}", yn(is_prime(two)), yn(divides((2, 0), (1, 1))));
    let p = ideal(&[(2, 0), (1, 1)], -3);
    let pp = times(p, p, -3);
    let two3 = ideal(&[(2, 0)], -3);
    println!("mistake 3, Z[s], s = sqrt(-3): P = (2, 1 + s) norm {}; P x P norm {}, not 4; P x P = (2) x P: {}; P = (2): {}",
             norm(p), norm(pp), yn(pp == times(two3, p, -3)), yn(p == two3));
    assert!([norm(p2), norm(p3), norm(q3)] == [2, 3, 3] && is_prime(p2) && is_prime(p3) && is_prime(q3));
    assert!(pairs.iter().all(|&(_, i, num)| i == ideal(&[num], D)) && road2.iter().all(|&x| x)); // two roads agree
    assert!(whole == six && six == other && norm(six) == 6 * 6);                                 // (6), and N(6) = 36
    assert!(unique && conj == ideals.len());                                                      // Dedekind, to norm 100
    assert!(principal * 2 == ideals.len() && !is_prime(two));
    assert!(single && norm(wrong) == 12);
    assert!(norm(pp) == 8 && p != two3);                                                          // the failure case
    println!("ALL CHECKS PASS");
}
