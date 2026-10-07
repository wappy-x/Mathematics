// Infinite series -- the same check as the Python, in Rust.  No crates.
// A perpetuity pays 100 at the end of every year, forever, at a 5% rate.
// Its value is the sum of the discounted payments, reached by three roads:
// adding the payments one by one, the closed form, and the self-similar equation.
const PAY: f64 = 100.0;
const RATE: f64 = 0.05;

fn added(n: usize, first: f64, ratio: f64) -> f64 {  // road one: add n discounted payments
    let (mut total, mut term) = (0.0, first);
    for _ in 0..n {
        total += term;
        term *= ratio;
    }
    total
}

fn formula(n: usize, a: f64, r: f64) -> f64 {       // road two: a(1 - r^n)/(1 - r), r^n by logs
    a * (1.0 - (n as f64 * r.ln()).exp()) / (1.0 - r)
}

fn within(tol: f64, a: f64, r: f64, limit: f64) -> (usize, usize) {  // the tolerance game, two ways
    let mut n = 0;
    while limit - added(n, a, r) > tol {
        n += 1;
    }
    (n, ((limit / tol).ln() / (1.0 + RATE).ln()).ceil() as usize)
}

fn main() {
    let r = 1.0 / (1.0 + RATE);                      // each payment is worth r times the one before
    let a = PAY * r;                                 // the first payment, discounted one year
    let limit = a / (1.0 - r);                       // road two, all payments
    let self_similar = PAY / RATE;                   // road three: S = (100 + S)/1.05
    let by_adding = added(700, a, r);
    let (mut pay, mut disc, mut grow) = (PAY, 1.0, Vec::new());  // term test: payments growing 5% a year
    for _ in 0..100 {
        disc *= 1.0 + RATE;
        grow.push(pay / disc);
        pay *= 1.0 + RATE;
    }
    let (mut h, mut bounds) = (0.0, Vec::new());     // harmonic series 1 + 1/2 + 1/3 + ...
    for k in 1..=1024u32 {
        h += 1.0 / k as f64;
        if k & (k - 1) == 0 {                        // k is a power of 2: record (H_k, 1 + j/2)
            bounds.push((h, 1.0 + (k as f64).log2() / 2.0));
        }
    }
    let grow_sum: f64 = grow.iter().sum();
    let grow_min = grow.iter().cloned().fold(f64::INFINITY, f64::min);
    println!("perpetuity 100 a year at 5%: ratio r = {:.6}, first term a = {:.6}", r, a);
    println!("first three terms {:.6} {:.6} {:.6}, S_3 = {:.6}", a, a * r, a * r * r, added(3, a, r));
    println!("limit, closed form a/(1 - r): {:.6}", limit);
    println!("limit, self-similar S = (100 + S)/1.05, so S = 100/0.05: {:.6}", self_similar);
    println!("limit, adding 700 payments: {:.6}", by_adding);
    for n in (0..=200).step_by(25) {
        println!("chart, n = {:3}: added {:8.2}, formula {:8.2}, tail {:8.2}",
                 n, added(n, a, r), formula(n, a, r), limit - formula(n, a, r));
    }
    for tol in [1.0, 0.01] {
        let (by_add, by_log) = within(tol, a, r, limit);
        println!("within {:.2} of {:.0}: n = {} by adding, {} by logs", tol, limit, by_add, by_log);
    }
    println!("term test, payments growing 5% a year: term 1 = {:.6}, term 100 = {:.6}, S_100 = {:.2}",
             grow[0], grow[99], grow_sum);
    println!("harmonic 1 + 1/2 + ... + 1/1024: last term {:.6}, sum {:.4}, doubling bound {:.0}",
             1.0 / 1024.0, h, bounds[bounds.len() - 1].1);
    println!("mistakes: ratio 0.95 gives {:.2}; a payment today added gives {:.2}; S = 1 + 2S gives {:.0}",
             95.0 / (1.0 - 0.95), PAY + limit, 1.0 / (1.0 - 2.0));
    assert!((0..=200).step_by(25).all(|n| (added(n, a, r) - formula(n, a, r)).abs() < 1e-9));
    assert!((by_adding - self_similar).abs() < 1e-9 && (limit - self_similar).abs() < 1e-9);
    let (w1, w2) = (within(1.0, a, r, limit), within(0.01, a, r, limit));
    assert!(w1.0 == w1.1 && w2.0 == w2.1);
    assert!(bounds.iter().all(|&(hk, b)| hk >= b) && grow_min > 0.99 * a);  // harmonic bound; growing terms never shrink
    println!("ALL CHECKS PASS");
}
