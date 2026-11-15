// Limits and continuity with distances -- the same check as the Python, in Rust.
// No crates.  Two spreadsheet cells refer to each other: bonus B = (P - B - T)/10
// and tax T = (P - B)/4, with profit P = 43000 dollars.  Recalculating from blank
// cells gives readings x_n, kept as exact fractions of checked i128 integers.
// Road one iterates; road two solves the two equations by Cramer's rule; road
// three is the proved bound 10000/4^n.  Floats appear only in the log10 chart
// points and the running total.
#[derive(Clone, Copy, PartialEq, Debug)]
struct Q { n: i128, d: i128 }                       // n/d in lowest terms, d > 0

fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q {
    let g = gcd(n, d).max(1) * d.signum();
    Q { n: n / g, d: d / g }
}
fn add(a: Q, b: Q) -> Q {                           // over the least common denominator
    let l = (a.d / gcd(a.d, b.d)).checked_mul(b.d).unwrap();
    q(a.n.checked_mul(l / a.d).unwrap().checked_add(b.n.checked_mul(l / b.d).unwrap()).unwrap(), l)
}
fn sub(a: Q, b: Q) -> Q { add(a, Q { n: -b.n, d: b.d }) }
fn mul(a: Q, b: Q) -> Q { q(a.n.checked_mul(b.n).unwrap(), a.d.checked_mul(b.d).unwrap()) }
fn abs(a: Q) -> Q { Q { n: a.n.abs(), d: a.d } }
fn lt(a: Q, b: Q) -> bool { sub(a, b).n < 0 }
fn max(a: Q, b: Q) -> Q { if lt(a, b) { b } else { a } }
fn f64q(a: Q) -> f64 { a.n as f64 / a.d as f64 }

type V = (Q, Q);
const P: Q = Q { n: 43000, d: 1 };
fn big_f(x: V) -> V { (mul(sub(sub(P, x.0), x.1), q(1, 10)), mul(sub(P, x.0), q(1, 4))) }
fn dinf(x: V, y: V) -> Q { max(abs(sub(x.0, y.0)), abs(sub(x.1, y.1))) }
fn d1(x: V, y: V) -> Q { add(abs(sub(x.0, y.0)), abs(sub(x.1, y.1))) }
fn ddisc(x: V, y: V) -> i32 { if x == y { 0 } else { 1 } }
fn dbonus(x: V, y: V) -> Q { abs(sub(x.0, y.0)) }
fn g(x: Q) -> Q { if x.n > 0 { mul(x, q(1, 2)) } else { q(1, 1) } }   // IF(x > 0, x/2, 1)
fn show(a: Q, k: u32) -> String {                   // exact fraction to k decimals, half away from zero
    let s = 10i128.pow(k);
    let m = (a.n.abs().checked_mul(s * 2).unwrap() + a.d) / (2 * a.d);
    format!("{}{}.{:0w$}", if a.n < 0 && m != 0 { "-" } else { "" }, m / s, m % s, w = k as usize)
}

fn main() {
    let det = 11 * 4 - 1 * 1;                       // 11B + T = P and B + 4T = P
    let star: V = (mul(sub(mul(q(4, 1), P), P), q(1, det)), mul(sub(mul(q(11, 1), P), P), q(1, det)));
    println!("road two, Cramer's rule on 11B + T = P, B + 4T = P: B = {}, T = {}", show(star.0, 4), show(star.1, 4));
    let mut xs: Vec<V> = vec![(q(0, 1), q(0, 1))];
    for _ in 0..16 { let x = big_f(*xs.last().unwrap()); xs.push(x) }
    let err: Vec<Q> = xs.iter().map(|&x| dinf(x, star)).collect();
    let bound: Vec<Q> = (0..17).map(|n| q(10000, 4i128.pow(n))).collect();
    let step: Vec<Q> = (0..17).map(|n| if n == 0 { q(0, 1) } else { dinf(xs[n], xs[n - 1]) }).collect();
    println!("n | bonus B | tax T | max change from limit | proved bound | step change");
    for n in 0..13 {
        let st = if n > 0 { show(step[n], 4) } else { "-".to_string() };
        println!("{} | {} | {} | {} | {} | {}", n, show(xs[n].0, 4), show(xs[n].1, 4), show(err[n], 4), show(bound[n], 4), st);
    }
    let eps = q(1, 1000);
    let cutoffs = |e: Q| ((0..17).find(|&n| err[n..].iter().all(|&x| lt(x, e))).unwrap(), (0..17).find(|&n| lt(bound[n], e)).unwrap());
    let (first_err, first_bound) = cutoffs(eps);
    let m = (1..17).find(|&n| lt(step[n], eps)).unwrap();
    println!("powers of 4 either side of 10^7: 4^11 = {}, 4^12 = {}", 4i128.pow(11), 4i128.pow(12));
    println!("tolerance {}: every reading within it from n = {}; the bound promises n = {}", f64q(eps), first_err, first_bound);
    let (try_err, try_bound) = cutoffs(q(1, 100));
    println!("try: tolerance 0.01: every reading within it from n = {}; the bound promises n = {}", try_err, try_bound);
    println!("step change first under {} at n = {}: step {}, true miss {}, at most step/3 = {}",
             f64q(eps), m, show(step[m], 6), show(err[m], 6), show(mul(step[m], q(1, 3)), 6));
    let r: Vec<Q> = xs[..13].iter().map(|&x| mul(d1(x, star), q(dinf(x, star).d, dinf(x, star).n))).collect();
    let (lo, hi) = (r.iter().fold(r[0], |a, &b| if lt(b, a) { b } else { a }), r.iter().fold(r[0], |a, &b| max(a, b)));
    println!("total change / max change, n = 0 to 12: lowest {}, highest {}", show(lo, 4), show(hi, 4));
    let disc: Vec<i32> = xs[..13].iter().map(|&x| ddisc(x, star)).collect();
    println!("discrete metric, distance to the limit for n = 0 to 12: {:?}", disc);
    let fake: V = (q(3000, 1), q(0, 1));
    println!("bonus-only distance at n = 12: to (3000, 10000) {}, to (3000, 0) {}; the two points are {} apart",
             show(dbonus(xs[12], star), 6), show(dbonus(xs[12], fake), 6), dbonus(star, fake).n);
    let fs = big_f(star);
    println!("F(limit) = ({}, {}); sequence test: d(F(x_5), F(limit)) = d(x_6, limit) = {}",
             show(fs.0, 4), show(fs.1, 4), show(dinf(big_f(xs[5]), fs), 4));
    let (mut best, mut at, mut cases) = (q(0, 1), (0i128, 0i128), 0);  // every whole-dollar offset up to 200
    for e1 in -200i128..=200 {
        for e2 in -200i128..=200 {
            if e1 != 0 || e2 != 0 {
                cases += 1;
                let p: V = (add(star.0, q(e1, 1)), add(star.1, q(e2, 1)));  // run F itself on the offset point
                let ratio = mul(dinf(big_f(p), fs), q(1, dinf(p, star).n));
                if lt(best, ratio) { best = ratio; at = (e1, e2) }
            }
        }
    }
    println!("largest output change / input change over {} offsets: {}/{} at offset ({}, {})", cases, best.n, best.d, at.0, at.1);
    let a_off: V = (add(star.0, q(4, 1)), star.1);
    println!("epsilon 1 dollar, delta 4 dollars: offset (4, 0) moves the output {}", show(dinf(big_f(a_off), star), 4));
    let mut ys = vec![q(8, 1)];
    for _ in 0..14 { let y = g(*ys.last().unwrap()); ys.push(y) }
    println!("IF cell from 8: x_14 = {}, g(x_14) = {}, g(0) = {}", show(ys[14], 6), show(g(ys[14]), 6), g(q(0, 1)).n);
    for dl in [q(1, 1), q(1, 10), q(1, 1000)] {
        let x = mul(dl, q(1, 2));
        println!("epsilon 1/2, delta {}: input {} lands {} from g(0)", show(dl, 3), show(x, 4), show(sub(q(1, 1), g(x)), 5));
    }
    let two: Vec<V> = [(1, 0), (0, 1)].iter().map(|&(u, v)| big_f(big_f((add(star.0, q(u, 1)), add(star.1, q(v, 1))))))
        .map(|y| (sub(y.0, star.0), sub(y.1, star.1))).collect();
    let even = xs.iter().step_by(2).all(|x| lt(x.1, star.1)); // Step 6: the even readings, n = 0, 2, ..., 16
    let fr = |a: Q| format!("{}/{}", a.n, a.d);
    println!("two recalculations send miss (1, 0) to ({}, {}) and (0, 1) to ({}, {}); tax under 10000 at every even n to 16: {}",
             fr(two[0].0), fr(two[0].1), fr(two[1].0), fr(two[1].1), if even { "yes" } else { "no" });
    let (mut s, mut n) = (0.0f64, 0u64);
    loop {
        n += 1;
        s += 1.0 / n as f64;
        if 1.0 / (n as f64) < 0.001 { break }
    }
    let (s_at, nstop) = (s, n);
    let mut s_half = 0.0;
    while n < 1000000 { n += 1; s += 1.0 / n as f64; if n == 500000 { s_half = s } }
    println!("running total of 1/n: step first under 0.001 at n = {}, total {:.4}; at n = {}, {:.4}; minus the total at n = 500000, {:.4}",
             nstop, s_at, n, s, s - s_half);
    let le: Vec<String> = err[..13].iter().map(|&e| format!("{:.2}", f64q(e).log10())).collect();
    let lb: Vec<String> = bound[..13].iter().map(|&b| format!("{:.2}", f64q(b).log10())).collect();
    println!("chart, log10 of max change from limit: {}", le.join(", "));
    println!("chart, log10 of proved bound: {}", lb.join(", "));
    assert!(big_f(star) == star && star == (q(3000, 1), q(10000, 1)));       // road two is road one's resting point
    assert!((0..17).all(|n| !lt(bound[n], err[n])) && err[16].n > 0);        // road three bounds road one, never exact
    assert!(first_err <= first_bound && first_bound == 12 && !lt(mul(step[m], q(1, 3)), err[m]));
    assert!(best == q(1, 4) && r.iter().all(|&x| !lt(x, q(1, 1)) && !lt(q(2, 1), x)));  // Lipschitz 1/4; d1, dinf
    assert!(lt(g(ys[14]), q(1, 1000)) && g(q(0, 1)) == q(1, 1));             // the IF cell fails the sequence test
    assert!(lt(dbonus(xs[12], fake), q(1, 10000)) && lt(q(9999, 1), dinf(xs[12], fake))); // bonus-only: near a far point too
    assert!(s > 14.0 && s - s_half > 0.5);                                   // steps shrink, totals stay apart
    assert!(even && two.iter().all(|y| y.0.n > 0 && y.1.n > 0));             // Step 6: two passes mix misses positively
    println!("ALL CHECKS PASS");
}
