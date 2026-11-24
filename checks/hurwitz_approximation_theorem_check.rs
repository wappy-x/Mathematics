// Hurwitz's theorem -- the same check as the Python, in Rust.  No crates.
use std::f64::consts::PI;
const TOP: i64 = 120;
fn eps(x: f64, p: i64, q: i64) -> f64 { (q * q) as f64 * (x - p as f64 / q as f64).abs() }  // q^2 x error
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a } else { gcd(b, a % b) } }
fn hits(x: f64, c: f64) -> Vec<String> {             // road 1: try every bottom number q up to TOP
    (1..=TOP).filter_map(|q| { let p = (x * q as f64).round() as i64;
        if gcd(p, q) == 1 && eps(x, p, q) < 1.0 / c { Some(format!("{}/{}", p, q)) } else { None } }).collect()
}
fn farey(x: f64, steps: usize, r5: f64) -> usize {  // road 2: walk Farey neighbours a/b < x < c/d
    let (mut a, mut b, mut c, mut d, mut ok) = (x.floor() as i64, 1, x.floor() as i64 + 1, 1, 0);
    for _ in 0..steps {                              // count triples a/b, mediant, c/d with a hit
        if [(a, b), (c, d), (a + c, b + d)].iter().any(|&(h, k)| eps(x, h, k) < 1.0 / r5) { ok += 1; }
        if ((a + c) as f64 / (b + d) as f64) < x { a += c; b += d; } else { c += a; d += b; }
    }
    ok
}
fn main() {
    let r5 = 5f64.sqrt(); let phi = (1.0 + r5) / 2.0; let qmax = (1.0 / (2.3 * (2.3 - r5))).sqrt();
    let f: [(i64, i64); 8] = [(1, 1), (2, 1), (3, 2), (5, 3), (8, 5), (13, 8), (21, 13), (34, 21)];  // phi's stops
    let e: Vec<f64> = f.iter().map(|&(p, q)| eps(phi, p, q)).collect();
    let mut fib: Vec<i64> = vec![1, 1]; while fib[fib.len() - 1] <= 2 * TOP { let n = fib[fib.len() - 1] + fib[fib.len() - 2]; fib.push(n); }
    println!("root 5 = {:.7}, 1/root 5 = {:.7}, golden ratio = {:.7}", r5, 1.0 / r5, phi);
    println!("pi: 22/7 is off by {:.5}, bound 1/(root 5 x 49) = {:.5}", (PI - 22.0 / 7.0).abs(), 1.0 / (r5 * 49.0));
    let pe: Vec<String> = [(3, 1), (22, 7), (333, 106), (355, 113)].iter().map(|&(p, q)| format!("{:.4}", eps(PI, p, q))).collect();
    println!("pi, q^2 x error at 3/1 22/7 333/106 355/113: {}", pe.join(" "));
    println!("phi, q^2 x error at 1/1 2/1 3/2 5/3 8/5 13/8 21/13 34/21: {}", e.iter().map(|v| format!("{:.4}", v)).collect::<Vec<_>>().join(" "));
    println!("phi, p^2 - pq - q^2 at the same fractions: {}", f.iter().map(|&(p, q)| (p * p - p * q - q * q).to_string()).collect::<Vec<_>>().join(" "));
    println!("8/5 is off by {:.5}, bound {:.5} | 13/8 is off by {:.5}, bound {:.5}", phi - 1.6, 1.0 / (r5 * 25.0), 1.625 - phi, 1.0 / (r5 * 64.0));
    println!("every q up to {}, within 1/(root 5 q^2): pi {} | phi {}", TOP, hits(PI, r5).join(" "), hits(phi, r5).join(" "));
    println!("phi with 2.3 for root 5: {} | the proof allows only q below {:.2}", hits(phi, 2.3).join(" "), qmax);
    println!("Farey triples with a hit, of 15 walked: pi {}, phi {}", farey(PI, 15, r5), farey(phi, 15, r5));
    println!("mistakes: 3 for root 5 finds {} for phi | 8/5 against 1/(root 5 x 5) = {:.5} | phi as 1.618 puts 13/8 at {:.4}", hits(phi, 3.0).len(), 1.0 / (r5 * 5.0), eps(1.618, 13, 8));
    assert!(f.iter().zip(&e).all(|(&(p, q), &v)| (p * p - p * q - q * q).abs() == 1 && (v - 1.0 / (p as f64 / q as f64 + phi - 1.0)).abs() < 1e-12));
    assert!(e[2..].iter().map(|&v| v > 1.0 / r5).collect::<Vec<_>>() == [true, false].repeat(3) && farey(PI, 15, r5) == 15 && farey(phi, 15, r5) == 15);
    let want: Vec<String> = fib.iter().zip(&fib[1..]).filter(|&(&q, &p)| q <= TOP && p * p - p * q - q * q == 1).map(|(q, p)| format!("{}/{}", p, q)).collect();
    assert!(hits(phi, r5) == want && hits(PI, r5) == ["3/1", "22/7", "355/113"]
            && hits(phi, 2.3).iter().all(|h| (h.split('/').nth(1).unwrap().parse::<i64>().unwrap() as f64) < qmax));
    println!("ALL CHECKS PASS");
}
