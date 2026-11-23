// Reading a statement -- the same check as the Python, in Rust.  No crates.
// Three statements, each tested on small cases: the four-colour theorem on six
// small maps, Goldbach on the even numbers to 10,000, and the data clauses of
// Clay's Navier-Stokes statement (A) on two starting flows.
use std::collections::BTreeSet;
use std::f64::consts::PI;
type E = Vec<(usize, usize)>;
fn brute(n: usize, edges: &E, k: usize) -> i64 {        // road 1: try every colouring
    let mut count = 0;
    for code in 0..k.pow(n as u32) {
        let c: Vec<usize> = (0..n).map(|i| (code / k.pow(i as u32)) % k).collect();
        if edges.iter().all(|&(a, b)| c[a] != c[b]) { count += 1; }
    }
    count
}
fn poly(n: usize, edges: &[(usize, usize)], k: i64) -> i64 {   // road 2: deletion-contraction
    if edges.is_empty() { return k.pow(n as u32); }
    let ((a, b), rest) = (edges[0], &edges[1..]);
    let mv = |x: usize| if x == b { a } else { x };
    let merged: BTreeSet<(usize, usize)> = rest.iter()
        .map(|&(x, y)| { let (p, q) = (mv(x), mv(y)); (p.min(q), p.max(q)) }).filter(|e| e.0 != e.1).collect();
    let m: E = merged.into_iter().collect();
    poly(n, rest, k) - poly(n - 1, &m, k)
}
fn relabel(raw: &[(&str, &str)]) -> (usize, E) {      // vertices 0..n-1
    let names: Vec<&str> = raw.iter().flat_map(|&(a, b)| [a, b]).collect::<BTreeSet<_>>().into_iter().collect();
    let ix = |s: &str| names.iter().position(|&x| x == s).unwrap();
    (names.len(), raw.iter().map(|&(a, b)| (ix(a).min(ix(b)), ix(a).max(ix(b)))).collect())
}
fn ring(m: usize) -> E { (0..m).map(|i| { let j = (i + 1) % m; (i.min(j), i.max(j)) }).collect() }
fn complete(m: usize) -> E { (0..m).flat_map(|i| (i + 1..m).map(move |j| (i, j))).collect() }
fn commas(n: usize) -> String {                       // Python's {:,}
    let s = n.to_string();
    s.chars().enumerate().map(|(i, c)| if i > 0 && (s.len() - i) % 3 == 0 { format!(",{}", c) } else { c.to_string() }).collect()
}
fn sci(v: f64) -> String {                             // Python's {:.3e}
    let s = format!("{:.3e}", v); let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn swirl(x: f64, y: f64, z: f64) -> [f64; 3] {        // start A: a smooth swirl round the z-axis
    let g = (-(x * x + y * y + z * z)).exp();
    [-2.0 * y * g, 2.0 * x * g, 0.0]
}
fn norm(v: [f64; 3]) -> f64 { v.iter().map(|c| c * c).sum::<f64>().sqrt() }
const K: f64 = 2.0 * PI;
const NU: f64 = 0.01;
fn abc(p: &[f64; 4]) -> [f64; 3] {                     // start B: repeats in the unit cube
    let (x, y, z, a) = (p[0], p[1], p[2], (-NU * K * K * p[3]).exp());
    [a * ((K * z).sin() + (K * y).cos()), a * ((K * x).sin() + (K * z).cos()), a * ((K * y).sin() + (K * x).cos())]
}
fn pres(p: &[f64; 4]) -> f64 { -0.5 * abc(p).iter().map(|c| c * c).sum::<f64>() }
fn shift(p: &[f64; 4], axis: usize, h: f64) -> [f64; 4] { let mut q = *p; q[axis] += h; q }
fn d(f: &dyn Fn(&[f64; 4]) -> f64, p: &[f64; 4], axis: usize, h: f64) -> f64 {   // centred difference
    (f(&shift(p, axis, h)) - f(&shift(p, axis, -h))) / (2.0 * h)
}
fn main() {
    let benelux: E = relabel(&[("BE", "NL"), ("BE", "LU"), ("BE", "FR"), ("BE", "DE"), ("NL", "DE"),
        ("LU", "FR"), ("LU", "DE"), ("FR", "DE")]).1;
    let maps: Vec<(&str, usize, E)> = vec![("Benelux, France, Germany", 5, benelux),
        ("Four Corners, borders only", 4, ring(4)), ("Four Corners, points count", 4, complete(4)),
        ("6-slice cake, borders only", 6, ring(6)), ("6-slice cake, points count", 6, complete(6)),
        ("5 regions all touching", 5, complete(5))];
    println!("map                           regions pairs  most  colours  ways at k-1, k (brute / poly)");
    let mut needed = Vec::new();
    for (name, n, edges) in &maps {
        let k = (1..=*n).find(|&k| brute(*n, edges, k) > 0).unwrap();
        let (lo, hi) = (brute(*n, edges, k - 1), brute(*n, edges, k));
        assert!((lo, hi) == (poly(*n, edges, k as i64 - 1), poly(*n, edges, k as i64)));
        needed.push((k, edges.len(), 3 * n - 6));
        println!("{:<30}{:>7}{:>6}{:>6}{:>9}   {}, {} / {}, {}", name, n, edges.len(), 3 * n - 6, k, lo, hi, lo, hi);
    }
    assert!(needed[0].0 == 4 && needed[4].0 == 6);
    assert!(needed[5].0 == 5 && (needed[5].1, needed[5].2) == (10, 9));

    const N: usize = 10000;                            // Goldbach
    let mut sieve = vec![true; N + 1]; sieve[0] = false; sieve[1] = false;
    let mut i = 2;
    while i * i <= N { if sieve[i] { let mut j = i * i; while j <= N { sieve[j] = false; j += i; } } i += 1; }
    let trial: Vec<bool> = (0..=N).map(|m| m > 1 && (2..).take_while(|d| d * d <= m).all(|d| m % d != 0)).collect();
    assert!(sieve == trial);
    let ways = |m: usize, distinct: bool| (2..=m / 2).filter(|&p| sieve[p] && sieve[m - p] && !(distinct && 2 * p == m)).count();
    println!("primes below {}: {} (sieve and trial division agree)", commas(N), sieve.iter().filter(|&&b| b).count());
    let w: Vec<String> = [2, 4, 6, 8, 100].iter().map(|&m| format!("{}: {}", m, ways(m, false))).collect();
    println!("ways as a sum of two primes:  {}", w.join("  "));
    let w: Vec<String> = [4, 6, 8].iter().map(|&m| format!("{}: {}", m, ways(m, true))).collect();
    println!("the same, two different primes: {}", w.join("  "));
    let evens: Vec<usize> = (4..=N).step_by(2).collect();
    let fail: Vec<usize> = evens.iter().cloned().filter(|&m| ways(m, false) == 0).collect();
    let fail_distinct: Vec<usize> = evens.iter().cloned().filter(|&m| ways(m, true) == 0).collect();
    let odd_fail: Vec<usize> = (3..31).step_by(2).filter(|&m| ways(m, false) == 0).collect();
    println!("even numbers 4 to {} checked: {}; with no split: {}", commas(N), commas(evens.len()), fail.len());
    println!("with no split into two different primes: {:?}", fail_distinct);
    println!("odd numbers 3 to 29 with no split: {:?}", odd_fail);
    println!("quoted, not computed: even numbers checked to 4e18 (published 2014)");
    assert!(fail.is_empty() && fail_distinct == vec![4, 6] && ways(2, false) == 0 && ways(100, false) == 6);
    assert!(odd_fail[..3] == [3, 11, 17]);

    let (h, mut worst) = (1e-4, 0.0f64);
    for &(x, y, z) in &[(0.3, -0.7, 0.2), (1.1, 0.4, -0.5), (-0.6, 0.9, 1.3)] {
        let dv = ((swirl(x + h, y, z)[0] - swirl(x - h, y, z)[0]) + (swirl(x, y + h, z)[1] - swirl(x, y - h, z)[1])) / (2.0 * h);
        worst = worst.max(dv.abs());
    }
    let peak = (0..=3000).map(|i| norm(swirl(i as f64 / 1000.0, 0.0, 0.0))).fold(0.0f64, f64::max);
    let decay: Vec<f64> = [5.0f64, 7.0, 9.0].iter().map(|&r| (1.0 + r).powi(10) * norm(swirl(r, 0.0, 0.0))).collect();
    let (s, m) = (0.125, 80);                         // road 1: grid sum over [-5, 5]^3
    let mut grid = 0.0;
    for i in 0..m { for j in 0..m { for l in 0..m {
        let c = |q: usize| -5.0 + (q as f64 + 0.5) * s;
        grid += swirl(c(i), c(j), c(l)).iter().map(|v| v * v).sum::<f64>();
    } } }
    grid *= s * s * s;
    let exact = 2.0 * (PI / 2.0).powf(1.5);           // road 2: the Gaussian integral by hand
    let pf = 2.0f64.sqrt() * (-0.5f64).exp();
    println!("start A: divergence at 3 points below 1e-6: {}; peak speed {:.6} (formula {:.6})",
             if worst < 1e-6 { "True" } else { "False" }, peak, pf);
    println!("start A: (1+|x|)^10 x speed at |x| = 5, 7, 9: {}", decay.iter().map(|&v| sci(v)).collect::<Vec<_>>().join(", "));
    println!("start A: energy integral, grid {:.6}, formula {:.6}", grid, exact);
    assert!(worst < 1e-6 && (peak - pf).abs() < 1e-6 && (grid - exact).abs() < 1e-6);
    assert!(decay[0] > decay[1] && decay[1] > decay[2]);

    let (mut left, mut biggest) = (0.0f64, 0.0f64);
    for p in [[0.1, 0.2, 0.3, 0.5], [0.7, 0.4, 0.9, 0.5], [0.25, 0.6, 0.05, 1.0]] {
        let u = abc(&p);
        for i in 0..3 {
            let comp = move |q: &[f64; 4]| abc(q)[i];
            let ut = d(&comp, &p, 3, 1e-5);
            let conv: f64 = (0..3).map(|j| u[j] * d(&comp, &p, j, 1e-5)).sum();
            let lap: f64 = (0..3).map(|j| (comp(&shift(&p, j, 1e-3)) - 2.0 * u[i] + comp(&shift(&p, j, -1e-3))) / 1e-6).sum();
            left = left.max((ut + conv + d(&pres, &p, i, 1e-5) - NU * lap).abs());
            biggest = biggest.max(conv.abs());
        }
    }
    println!("start B: Navier-Stokes leftover at 3 points below 1e-4: {} (largest term {:.2})",
             if left < 1e-4 { "True" } else { "False" }, biggest);
    let mut cells = Vec::new();
    for side in 1..=3usize {                           // energy in a box of side 1, 2, 3 cells
        let q = 16 * side; let mut e = 0.0;
        for i in 0..q { for j in 0..q { for l in 0..q {
            e += abc(&[i as f64 / 16.0, j as f64 / 16.0, l as f64 / 16.0, 0.0]).iter().map(|c| c * c).sum::<f64>();
        } } }
        cells.push(e / 4096.0);
    }
    println!("start B: energy integral in a box of side 1, 2, 3: {} (formula 3, 24, 81); one cell at t = 1: {:.4}",
             cells.iter().map(|e| format!("{:.4}", e)).collect::<Vec<_>>().join(", "), 3.0 * (-2.0 * NU * K * K).exp());
    assert!(left < 1e-4 && cells.iter().zip([1.0f64, 2.0, 3.0]).all(|(e, s)| (e - 3.0 * s * s * s).abs() < 1e-9));
    println!("ALL CHECKS PASS");
}
