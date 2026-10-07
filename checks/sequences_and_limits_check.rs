// Sequences and limits -- the same check as the Python, in Rust.  No crates;
// f64::sqrt is the one primitive used.  Each cutoff N is found by a formula and
// by walking the terms; the climb to 2 is met by iterating and by algebra.

fn cutoff_formula(p: u64, q: u64) -> u64 { q / p }     // tolerance p/q: 1/n < p/q exactly when n > q/p

fn cutoff_scan(p: u64, q: u64) -> u64 {                // walk n up, remember the last term not inside
    let mut last = 0;
    for n in 1..10 * q {                                // 1/n only shrinks, so no later term can fail
        if 1.0 / n as f64 >= p as f64 / q as f64 { last = n }
    }
    last
}

fn two(xs: &[f64]) -> String {
    xs.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(" ")
}

fn six(xs: &[f64]) -> String {
    xs.iter().map(|x| format!("{:.6}", x)).collect::<Vec<_>>().join(" ")
}

fn main() {
    println!("sequence a_n = 1/n, heading for L = 0");
    let recips: Vec<f64> = (1..13).map(|n| 1.0 / n as f64).collect();
    println!("chart, 1/n for n = 1..12: {}", two(&recips));
    for (p, q) in [(1u64, 10u64), (1, 100), (3, 1000)] {
        let (nf, ns) = (cutoff_formula(p, q), cutoff_scan(p, q));
        println!("tolerance {}/{}: N by formula {}, N by scan {}", p, q, nf, ns);
        assert_eq!(nf, ns);                                               // two roads, one cutoff
    }
    println!("term 10 misses by {:.6}, term 11 is inside at {:.6}", 1.0 / 10.0, 1.0 / 11.0);
    println!("mistake, cutoff 9 for tolerance 1/10: term 10 sits at {:.6}, not below 0.1", 1.0 / 10.0);
    let alt: Vec<i64> = [101u32, 102].iter().map(|&n| (-1i64).pow(n)).collect();
    println!("mistake, bounded is not convergent: (-1)^n at n = 101, 102 gives {}, {}; gap {} > 2 x 0.1",
             alt[0], alt[1], alt[1] - alt[0]);
    let x: f64 = 1.0 + 1.0 / 11.0;
    let f = (x * x - 1.0) / (x - 1.0);                                    // the uncancelled fraction
    println!("house example, (x^2 - 1)/(x - 1) at x = 1 + 1/11: {:.6}, off 2 by {:.6}", f, f - 2.0);
    assert!(((f - 2.0) - 1.0 / 11.0).abs() < 1e-12);                     // fraction road vs 1/n road
    let (mut c, mut climb) = (0.0f64, Vec::new());
    for _ in 1..21 {                                                      // c_1 = 0, c_(n+1) = sqrt(2 + c_n)
        climb.push(c);
        c = (2.0 + c).sqrt();
    }
    let gaps: Vec<f64> = climb[..6].iter().map(|v| 2.0 - v).collect();
    println!("climb c_n, n = 1..6: {}", six(&climb[..6]));
    println!("gap 2 - c_n, n = 1..6: {}", six(&gaps));
    println!("chart, c_n for n = 1..5: {}", two(&climb[..5]));
    let up = climb.windows(2).all(|w| w[0] < w[1]) && climb.iter().all(|&v| v < 2.0);
    println!("every step up and every term below 2, n = 1..20: {}", if up { "yes" } else { "no" });
    let root = (1.0 + (1.0f64 + 8.0).sqrt()) / 2.0;                       // road 2: L*L = 2 + L
    println!("road 2, L = sqrt(2 + L) so L^2 - L - 2 = 0: L = {:.6} or {:.6}",
             root, (1.0 - (1.0f64 + 8.0).sqrt()) / 2.0);
    assert!(up && (climb[19] - root).abs() < 1e-10);                      // iteration vs algebra
    let first = climb.iter().position(|&v| 2.0 - v < 0.1).unwrap() + 1;
    println!("first climb term within 0.1 of 2: n = {}", first);
    let mut d: u64 = 1;
    for _ in 0..19 { d *= 2 }
    println!("mistake, no ceiling: d_(n+1) = 2 d_n from 1 has 'fixed point' 0, yet d_20 = {}", d);
    let h: f64 = (1..1025).map(|k| 1.0 / k as f64).sum();               // road 1: add every term
    println!("mistake, steps shrink but no ceiling: 1 + 1/2 + ... + 1/1024 = {:.6}, doubling-block bound 1 + 10/2 = {:.6}, last step {:.6}",
             h, 1.0 + 10.0 / 2.0, 1.0 / 1024.0);
    assert!(h >= 1.0 + 10.0 / 2.0);                                       // road 2: blocks of 1/2
    println!("ALL CHECKS PASS");
}
