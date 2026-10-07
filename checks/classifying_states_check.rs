// Classifying states -- the same check as the Python, in Rust.  No crates.  A token
// needs a six to leave S for a ring A, B, C, D; a coin moves it one square either
// way; D sends it to jail J.  Q is a small exact fraction type, written out here.
const N: [&str; 5] = ["S", "A", "B", "C", "J"];
const SEED: u64 = 20260929; const RUNS: usize = 20000; const HORIZON: usize = 5000;
#[derive(Clone, Copy, PartialEq)]
struct Q { n: i64, d: i64 }
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }  // Euclid
fn q(n: i64, d: i64) -> Q { let g = gcd(n, d).max(1) * d.signum(); Q { n: n / g, d: d / g } }
fn add(a: Q, b: Q) -> Q { q(a.n * b.d + b.n * a.d, a.d * b.d) }
fn sub(a: Q, b: Q) -> Q { q(a.n * b.d - b.n * a.d, a.d * b.d) }
fn mul(a: Q, b: Q) -> Q { q(a.n * b.n, a.d * b.d) }
fn div(a: Q, b: Q) -> Q { q(a.n * b.d, a.d * b.n) }
fn fl(a: Q) -> f64 { a.n as f64 / a.d as f64 }
fn show(a: Q) -> String { if a.d == 1 { format!("{}", a.n) } else { format!("{}/{}", a.n, a.d) } }
type M = Vec<Vec<Q>>; type B = Vec<Vec<bool>>;
fn chain(rule: usize) -> M {                     // rows S, A, B, C, J; the rule sets jail to A, J
    let ((a, j), z, h) = ([(q(1, 6), q(5, 6)), (q(1, 1), q(0, 1)), (q(0, 1), q(1, 1))][rule], q(0, 1), q(1, 2));
    vec![vec![q(5, 6), q(1, 6), z, z, z], vec![z, z, h, z, h], vec![z, h, z, h, z],
         vec![z, z, h, z, h], vec![z, a, z, z, j]]
}
fn arrows(p: &M) -> B { p.iter().map(|r| r.iter().map(|x| x.n > 0).collect()).collect() }
fn boolmul(x: &B, y: &B) -> B { (0..5).map(|i| (0..5).map(|j| (0..5).any(|k| x[i][k] && y[k][j])).collect()).collect() }
fn reach_powers(p: &M) -> B {                    // road one: I or P or ... or P^4
    let a = arrows(p);
    let mut pk: B = (0..5).map(|i| (0..5).map(|j| i == j).collect()).collect();
    let mut r = pk.clone();
    for _ in 0..4 { pk = boolmul(&pk, &a); for i in 0..5 { for j in 0..5 { r[i][j] |= pk[i][j]; } } }
    r
}
fn reach_search(p: &M) -> B {                    // road two: follow arrows, depth first
    (0..5).map(|i| {
        let (mut seen, mut stack): (Vec<bool>, _) = ((0..5).map(|j| j == i).collect(), vec![i]);
        while let Some(u) = stack.pop() {
            for v in 0..5 { if p[u][v].n > 0 && !seen[v] { seen[v] = true; stack.push(v); } }
        }
        seen
    }).collect()
}

fn classes(r: &B) -> Vec<Vec<usize>> {
    let mut cs: Vec<Vec<usize>> = Vec::new();
    for i in 0..5 { let c: Vec<usize> = (0..5).filter(|&j| r[i][j] && r[j][i]).collect(); if !cs.contains(&c) { cs.push(c); } }
    cs
}
fn return_lengths(p: &M, i: usize, most: usize) -> Vec<usize> {  // every n <= most with P^n(i,i) > 0
    let (a, mut out) = (arrows(p), Vec::new());
    let mut pk = a.clone();
    for n in 1..=most { if pk[i][i] { out.push(n); } pk = boolmul(&pk, &a); }
    out
}
fn period_levels(p: &M, c: &[usize]) -> i64 {    // gcd of level jumps along arrows in class c
    let (mut lvl, mut queue, mut k) = ([-1i64; 5], vec![c[0]], 0);
    lvl[c[0]] = 0;
    while k < queue.len() {
        let u = queue[k]; k += 1;
        for &v in c { if p[u][v].n > 0 && lvl[v] < 0 { lvl[v] = lvl[u] + 1; queue.push(v); } }
    }
    let mut g = 0;
    for &u in c { for &v in c { if p[u][v].n > 0 { g = gcd(g, (lvl[u] + 1 - lvl[v]).abs()); } } }
    g
}

fn return_chance(p: &M, i: usize, reach: &B) -> (Q, Vec<Q>) {  // exact first-step equations for f_i
    let ks: Vec<usize> = (0..5).filter(|&k| k != i && reach[k][i]).collect();
    let n = ks.len();
    let mut m: M = ks.iter().map(|&a| {
        let mut row: Vec<Q> = ks.iter().map(|&b| sub(q((a == b) as i64, 1), p[a][b])).collect();
        row.push(p[a][i]); row
    }).collect();
    for c in 0..n {                              // Gauss-Jordan elimination in fractions
        let piv = (c..n).find(|&r| m[r][c].n != 0).unwrap();
        m.swap(c, piv);
        let lead = m[c][c];
        m[c] = m[c].iter().map(|&x| div(x, lead)).collect();
        for r in (0..n).filter(|&r| r != c) { let f = m[r][c]; m[r] = (0..=n).map(|t| sub(m[r][t], mul(f, m[c][t]))).collect(); }
    }
    let h: Vec<Q> = (0..5).map(|k| match ks.iter().position(|&x| x == k) { Some(r) => m[r][n], None => q(0, 1) }).collect();
    let f = (0..5).filter(|&k| k != i).fold(p[i][i], |acc, k| add(acc, mul(p[i][k], h[k])));
    (f, h)
}

fn powers_row(p: &M, i: usize, n: usize) -> Vec<Vec<f64>> {  // row i of P^0 .. P^n, floats
    let (mut row, mut rows): (Vec<f64>, Vec<Vec<f64>>) = ((0..5).map(|j| if j == i { 1.0 } else { 0.0 }).collect(), Vec::new());
    for _ in 0..=n {
        rows.push(row.clone());
        row = (0..5).map(|j| (0..5).fold(0.0, |s, k| s + row[k] * fl(p[k][j]))).collect();
    }
    rows
}

fn uniform(s: &mut u64) -> f64 {                 // SplitMix64, the wing's generator
    *s = s.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = (*s ^ (*s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
}

fn simulate(p: &M, i: usize, reach: &B) -> (f64, f64) {  // share of runs back at i within HORIZON turns
    let (mut s, mut back) = (SEED + i as u64, 0);
    for _ in 0..RUNS {
        let mut x = i;
        for _ in 0..HORIZON {                    // a run ends early where no arrows lead back
            if !reach[x][i] { break; }
            let u = uniform(&mut s);
            let (mut acc, mut y) = (0.0, 4);
            for j in 0..5 { acc += fl(p[x][j]); if u < acc { y = j; break; } }
            x = y;
            if x == i { back += 1; break; }
        }
    }
    let f = back as f64 / RUNS as f64;
    (f, (f * (1.0 - f) / RUNS as f64).sqrt())
}

fn main() {
    let names = ["doubles", "at once", "no key"];
    println!("simulation: SplitMix64 seed {}, {} runs per state, at most {} turns a run, \
              asserts within 4 standard errors; periods from return lengths up to 30 turns", SEED, RUNS, HORIZON);
    for rule in 0..3 {
        let p = chain(rule);
        let rp = reach_powers(&p);
        assert!(rp == reach_search(&p));                             // powers agree with search
        let cs = classes(&rp);
        let label = |c: &Vec<usize>| c.iter().map(|&k| N[k]).collect::<Vec<_>>();
        println!("jail rule '{}': classes {}", names[rule],
                 cs.iter().map(|c| format!("{{{}}}", label(c).join(","))).collect::<Vec<_>>().join(" "));
        let mut shut = [false; 5];                                   // state -> is its class closed?
        for c in &cs {
            let closed = c.iter().all(|&i| (0..5).all(|j| c.contains(&j) || p[i][j].n == 0));
            let d = period_levels(&p, c);
            for &i in c {
                let g = return_lengths(&p, i, 30).iter().fold(0, |g, &n| gcd(g, n as i64));
                assert!(g == d);                                     // return lengths agree with levels
                shut[i] = closed;
            }
            let ds = if d > 0 { d.to_string() } else { "none".to_string() };
            println!("  class {}: {}, period {}", label(c).concat(), if closed { "closed" } else { "open" }, ds);
        }
        for i in 0..5 {
            let (f, h) = return_chance(&p, i, &rp);
            let rows = powers_row(&p, i, 1000);
            let v: f64 = rows.iter().fold(0.0, |s, r| s + r[i]);
            let v500: f64 = rows[..501].iter().fold(0.0, |s, r| s + r[i]);
            let (fs, se) = simulate(&p, i, &rp);
            assert!((fs - fl(f)).abs() <= 4.0 * se + 1e-12);         // simulation within 4 standard errors
            assert!((f.n == f.d) == shut[i]);                        // recurrent exactly when the class is closed
            if f.n < f.d { assert!((v - 1.0 / (1.0 - fl(f))).abs() < 1e-9); }  // visits = 1/(1 - f)
            else { assert!(v > 1.5 * v500); }                        // visits keep growing when f = 1
            println!("  {}: f = {:>3} = {:.4}, simulated {:.4} +- {:.4}, visits to n=1000 {:9.4}, {}", N[i], show(f),
                     fl(f), fs, se, v, if f.n == f.d { "recurrent" } else { "transient" });
            if rule == 2 && i == 1 {
                let hs: Vec<String> = (0..5).filter(|&k| k != i).map(|k| format!("{} {}", N[k], show(h[k]))).collect();
                println!("  worked, 'no key': chance of reaching A from {}; f_A = 1/2 x {} + 1/2 x {} = {}",
                         hs.join(", "), show(h[2]), show(h[4]), show(f));
            }
        }
    }
    for rule in 0..2 {
        let rows = powers_row(&chain(rule), 1, 201);
        let pts: Vec<String> = rows[..17].iter().map(|r| format!("{:.2}", r[1])).collect();
        println!("figure, P^n(A,A), n = 0..16, '{}': {}", names[rule], pts.join(", "));
        let lim: Vec<String> = (0..5).map(|j| format!("{} {:.4}", N[j], rows[200][j])).collect();
        println!("limit, '{}': P^200 from A: {}; P^201(A,A) = {:.4}", names[rule], lim.join(" "), rows[201][1]);
        let ls: Vec<String> = return_lengths(&chain(rule), 1, 8).iter().map(|n| n.to_string()).collect();
        println!("return lengths at A up to 8 turns, '{}': {}", names[rule], ls.join(", "));
    }
    println!("figure, node centres: S (40,60) A (140,60) B (280,60) C (280,180) J (140,180), radius 22");
    println!("ALL CHECKS PASS");
}
