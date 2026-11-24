// Building the integers and fractions -- the same check as the Python, in Rust.  No crates.  An integer is a pair
// (paid in, owed), a fraction a pair (top, bottom).  Every rule is tried on every choice of same pairs.
type P = (i64, i64); type Same = fn(P, P) -> bool; type Rule = fn(P, P) -> P; type Op = fn(f64, f64) -> f64;
fn zsame(p: P, q: P) -> bool { p.0 + q.1 == q.0 + p.1 }  fn qsame(p: P, q: P) -> bool { p.0 * q.1 == p.1 * q.0 }  // plus only; times only
fn zadd(p: P, q: P) -> P { (p.0 + q.0, p.1 + q.1) }  fn zmul(p: P, q: P) -> P { (p.0 * q.0 + p.1 * q.1, p.0 * q.1 + p.1 * q.0) }
fn qadd(p: P, q: P) -> P { (p.0 * q.1 + p.1 * q.0, p.1 * q.1) }  fn qmul(p: P, q: P) -> P { (p.0 * q.0, p.1 * q.1) }
fn zval(p: P) -> f64 { (p.0 - p.1) as f64 }  fn qval(p: P) -> f64 { p.0 as f64 / p.1 as f64 }  // road 2: signed numbers, decimals
fn add(x: f64, y: f64) -> f64 { x + y }  fn mul(x: f64, y: f64) -> f64 { x * y }  fn yn(t: bool) -> &'static str { if t { "yes" } else { "no" } }
fn gcd(a: i64, b: i64) -> i64 { if b != 0 { gcd(b, a % b) } else { a.abs() } }  fn low(p: P) -> P { let g = gcd(p.0, p.1); (p.0 / g, p.1 / g) }
fn test(same: Same, rule: Rule, pairs: &[P], val: fn(P) -> f64, op: Op) -> (usize, usize, usize) {
    let (mut n, mut dep, mut off) = (0, 0, 0);       // choices tried, answers that depend on the pick, answers off road 2
    for &p in pairs { for &p2 in pairs.iter().filter(|&&x| same(p, x)) { for &q in pairs { for &q2 in pairs.iter().filter(|&&x| same(q, x)) {
        let (r, r2) = (rule(p, q), rule(p2, q2));
        n += 1; dep += !same(r, r2) as usize; off += ((val(r) - op(val(p), val(q))).abs() > 1e-9) as usize; } } } }
    (n, dep, off)
}
fn main() {
    let z: Vec<P> = (0..6).flat_map(|a| (0..6).map(move |b| (a, b))).collect();
    let q: Vec<P> = (-3..4).flat_map(|a| (1..5).map(move |b| (a, b))).collect();
    let rows: [(&str, Same, Rule, &[P], fn(P) -> f64, Op); 6] = [("integer +", zsame, zadd, &z, zval, add), ("integer x", zsame, zmul, &z, zval, mul), ("fraction +", qsame, qadd, &q, qval, add),
        ("fraction x", qsame, qmul, &q, qval, mul), ("broken fraction +", qsame, zadd, &q, qval, add), ("broken integer x", zsame, qmul, &z, zval, mul)];
    let res: Vec<(usize, usize, usize)> = rows.iter().map(|r| test(r.1, r.2, r.3, r.4, r.5)).collect();
    let (a, b, h, h2, h3, t, t2, o, f, v) = ((3, 5), (0, 2), (1, 2), (2, 4), (3, 6), (1, 3), (2, 6), (0, 0), (3, 4), (33, 100));
    println!("{:?} ~ {:?}: {}, as {} + {} = {} = {} + {}; road 2 gives {} and {}", a, b, yn(zsame(a, b)), a.0, b.1, a.0 + b.1, b.0, a.1, zval(a), zval(b));
    println!("{:?} + {:?} = {:?} and {:?} + {:?} = {:?}, worth {} and {}", a, b, zadd(a, b), b, b, zadd(b, b), zval(zadd(a, b)), zval(zadd(b, b)));
    println!("{:?} x {:?} = {:?} and {:?} x {:?} = {:?}, worth {} and {}", a, b, zmul(a, b), b, b, zmul(b, b), zval(zmul(a, b)), zval(zmul(b, b)));
    println!("{:?} ~ {:?} ~ {:?}: {}, as {} x {} = {} = {} x {} and {} x {} = {} = {} x {}", h, h2, h3, yn(qsame(h, h2) && qsame(h2, h3)), h.0, h2.1, h.0 * h2.1, h.1, h2.0, h2.0, h3.1, h2.0 * h3.1, h2.1, h3.0);
    let (s, u) = (qadd(h2, t2), qadd(h, t));
    println!("{:?} + {:?} = {:?} and {:?} + {:?} = {:?}: {} x {} = {} = {} x {}", h, t, u, h2, t2, s, s.0, u.1, s.0 * u.1, s.1, u.0);
    println!("{:?} x {:?} = {:?} and {:?} x {:?} = {:?}; lowest terms {:?} and {:?}", h, t, qmul(h, t), h2, t2, qmul(h2, t2), low(s), low(qmul(h2, t2)));
    for i in [0, 2, 4] { let (x, y) = (res[i], res[i + 1]);
        println!("{} and {}: {} and {} choices of same pairs; {} and {} answers depend on the pick; {} and {} miss road 2", rows[i].0, rows[i + 1].0, x.0, y.0, x.1, y.1, x.2, y.2); }
    let (w, w2) = (zadd(h, t), zadd(h, t2));
    println!("broken fraction +: {:?} + {:?} = {:?} but {:?} + {:?} = {:?}, and {} x {} = {}, not {}; to two places {:?} and {:?} give {:.2} and {:.2}, but {:?} ~ {:?}: {}", h, t, w, h, t2, w2, w.0, w2.1, w.0 * w2.1, w.1 * w2.0, t, v, qval(t), qval(v), t, v, yn(qsame(t, v)));
    println!("broken integer x: {:?} x {:?} = {:?}, worth {}; bottom zero: {:?} ~ {:?} ~ {:?}: {}, but {:?} ~ {:?}: {}", b, b, qmul(b, b), zval(qmul(b, b)), h, o, f, yn(qsame(h, o) && qsame(o, f)), h, f, yn(qsame(h, f)));
    assert!(zval(zadd(a, b)) == -4.0 && zval(zadd(b, b)) == -4.0 && zval(zmul(a, b)) == 4.0 && zval(a) * zval(b) == 4.0 && zsame(a, b) && !zsame(a, (5, 3)));
    assert!(low(s) == (5, 6) && low(u) == (5, 6) && low(qmul(h2, t2)) == (1, 6) && qsame(u, s) && !qsame(h, f) && !qsame(t, v));
    assert!(res[..4].iter().all(|r| r.1 == 0 && r.2 == 0) && res[4].1 > 0 && res[5].1 > 0 && qsame(h, o) && qsame(o, f) && zval(qmul(b, b)) == -4.0);
    println!("ALL CHECKS PASS");
}
