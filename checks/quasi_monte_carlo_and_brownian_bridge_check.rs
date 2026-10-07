// Quasi-Monte Carlo and the Brownian bridge -- the same check as the Python, in Rust, std only
// and no crates.  Nothing here knows an answer in advance either: the bell-curve area is the
// same series written out, its inverse is Newton's method on that series, the Sobol directions
// are built and their polynomials tested, and the pseudorandom stream is written out.  Acme:
// S = 100, K = 100, r = 5%, q = 2%, sigma = 20%, one year, a call, on a path cut into 16 steps.
use std::f64::consts::PI;
use std::sync::LazyLock;
const S: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02;
const SIG: f64 = 0.20; const T: f64 = 1.0; const HOUSE: f64 = 9.227005508154;
const D: usize = 16; const WORD: usize = 30; const DT: f64 = T / D as f64; const GN: usize = 480;
const MS: [usize; 5] = [8, 10, 12, 14, 16];
const POLYS: [u64; 15] = [3, 7, 11, 13, 19, 25, 37, 41, 47, 55, 59, 61, 67, 91, 97];
fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }      // bell-curve height at x
fn ncdf(x: f64) -> f64 {                    // area under the bell curve to the left of x
    let (z, mut term, mut tot, mut n) = (x.abs() / 2.0f64.sqrt(), 1.0f64, 1.0f64, 0u32);
    while term > 1e-17 * tot { term = term * 2.0 * z * z / (2 * n + 3) as f64; n += 1; tot += term }
    let a = 2.0 * z * (-z * z).exp() * tot / PI.sqrt();   // every term positive, nothing cancels
    if x >= 0.0 { 0.5 * (1.0 + a) } else { 0.5 * (1.0 - a) }
}                                           // a coarse table of that area, to start Newton off
static GP: LazyLock<Vec<f64>> = LazyLock::new(|| (0..=GN).map(|i| ncdf(-6.0 + 12.0 * i as f64 / GN as f64)).collect());
fn ninv(u: f64) -> f64 {                    // the inverse: read the table, then Newton twice
    let (mut lo, mut hi) = (0usize, GN);
    while hi - lo > 1 { let mid = (lo + hi) / 2; if GP[mid] <= u { lo = mid } else { hi = mid } }
    let mut x = -6.0 + 12.0 * lo as f64 / GN as f64 + (u - GP[lo]) * (12.0 / GN as f64) / (GP[hi] - GP[lo]);
    for _ in 0..2 { x -= (ncdf(x) - u) / phi(x) }
    x
}
fn order(p: u64) -> u32 {                   // multiplies by x that return to 1, in the ring
    let (s, mut x, mut k) = (p.ilog2(), 1u64, 0u32);
    while x != 1 || k == 0 { x = if ((x << 1) >> s) & 1 == 1 { (x << 1) ^ p } else { x << 1 }; k += 1 }
    k
}
fn directions(poly: u64) -> Vec<u64> {      // direction integers from Sobol's recurrence
    let (s, mut v) = (poly.ilog2() as usize, vec![0u64; WORD + 1]);
    for k in 1..=s { v[k] = 1 << (WORD - k) }    // every start 1: the simplest legal choice
    for k in s + 1..=WORD {
        v[k] = v[k - s] ^ (v[k - s] >> s);
        for i in 1..s { if (poly >> (s - i)) & 1 == 1 { v[k] ^= v[k - i] } }
    }
    v
}
fn point(mut i: usize, v: &[u64]) -> u64 {  // one coordinate of Sobol point i: XOR its 1-bits
    let (mut a, mut j) = (0u64, 1usize);
    while i > 0 { if i & 1 == 1 { a ^= v[j] } i >>= 1; j += 1 }
    a
}
fn grid(m: usize, vs: &[Vec<u64>]) -> Vec<Vec<usize>> {   // the first 2^m points, in whole steps
    (0..1usize << m).map(|i| vs.iter().map(|v| (point(i, v) >> (WORD - m)) as usize).collect()).collect()
}
fn natural(z: &[f64]) -> Vec<f64> {         // the path in time order: each step adds one draw
    let mut w = vec![DT.sqrt() * z[0]];
    for k in 1..D { w.push(w[k - 1] + DT.sqrt() * z[k]) }
    w
}
fn bridge(z: &[f64]) -> Vec<f64> {          // the end first, then midpoints, the gap halving
    let (mut w, mut j, mut gap) = (vec![0.0f64; D + 1], 1usize, D);
    w[D] = T.sqrt() * z[0];
    while gap > 1 {
        let (half, mut a) = (gap / 2, 0usize);
        while a + gap <= D { w[a + half] = 0.5 * (w[a] + w[a + gap]) + 0.5 * (gap as f64 * DT).sqrt() * z[j]; j += 1; a += gap }
        gap = half;
    }
    w[1..].to_vec()
}
fn acme(w: &[f64]) -> f64 { S * ((R - Q - 0.5 * SIG * SIG) * T + SIG * w[D - 1]).exp() }
fn payoff(w: &[f64]) -> f64 { (-R * T).exp() * (acme(w) - K).max(0.0) }
fn columns(build: fn(&[f64]) -> Vec<f64>) -> Vec<Vec<f64>> {   // the path from draw i alone
    (0..D).map(|i| build(&(0..D).map(|j| if j == i { 1.0 } else { 0.0 }).collect::<Vec<f64>>())).collect()
}
fn cov_gap(cols: &[Vec<f64>]) -> f64 {      // the built covariance against min(t_i, t_j)
    let mut worst = 0.0f64;
    for k in 0..D { for l in 0..D {
        let c: f64 = (0..D).map(|i| cols[i][k] * cols[i][l]).sum();
        worst = worst.max((c - (k + 1).min(l + 1) as f64 * DT).abs());
    } }
    worst
}
fn carried(cols: &[Vec<f64>]) -> String {   // share of the path's wiggle in the first 1, 2, 4, 8
    let sq: Vec<f64> = cols.iter().map(|c| c.iter().map(|v| v * v).sum()).collect();
    [1usize, 2, 4, 8].iter().map(|&k| format!("{:.2}", 100.0 * sq[..k].iter().sum::<f64>() / sq.iter().sum::<f64>())).collect::<Vec<String>>().join(" ")
}
fn bs_call() -> f64 {                       // road one: the closed formula, own bell-curve area
    let d1 = ((S / K).ln() + (R - Q + 0.5 * SIG * SIG) * T) / (SIG * T.sqrt());
    S * (-Q * T).exp() * ncdf(d1) - K * (-R * T).exp() * ncdf(d1 - SIG * T.sqrt())
}
fn nxt(state: &mut u64) -> f64 {            // one step of the stream, then one kick
    *state = state.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
    ninv(((*state >> 11) as f64 + 0.5) * 2.0f64.powi(-53))
}
fn row(label: &str, value: f64, tail: &str) { println!("{:<52}{:>12.6}{}", label, value, tail) }
fn main() {
    let mut vs: Vec<Vec<u64>> = vec![(0..=WORD).map(|k| if k > 0 { 1 << (WORD - k) } else { 0 }).collect()];
    for p in POLYS { vs.push(directions(p)) }
    let (exact, cn, cb) = (bs_call(), columns(natural), columns(bridge));
    let later = (1..D).map(|i| cb[i][D - 1].abs()).fold(0.0f64, f64::max);
    let mut uniq = vs.clone(); uniq.sort(); uniq.dedup();
    println!("Acme: S {:.2}  K {:.2}  r 5%  q 2%  sigma 20%  T 1 year, a call on a {}-step path", S, K, D);
    row("road one, the closed formula", exact, &format!("   the shelf's house number {:.6}", HOUSE));
    row("our bell-curve area at 1", ncdf(1.0), &format!("   known 0.841345, and the 97.5% point {:.6}", ninv(0.975)));
    println!("{:<52}{:?}", "primitive polynomial degrees, dimensions 2 to 16", POLYS.iter().map(|p| p.ilog2()).collect::<Vec<u32>>());
    for j in 1..3 { println!("{:<52}{:?}", format!("direction integers m_1 to m_5, dimension {}", j + 1), (1..6).map(|k| vs[j][k] >> (WORD - k)).collect::<Vec<u64>>()) }
    println!("{:<52}time order {:.6}, bridge {:.6}", "worst gap against min(t_i, t_j)", cov_gap(&cn), cov_gap(&cb));
    row("the bridge's end point from draw one alone", cb[0][D - 1], &format!("   from every later draw {:.6}", later));
    println!("{:<52}{}", "share of the wiggle in draws 1, 2, 4, 8, bridge", carried(&cb));
    println!("{:<52}{}", "the same shares in time order", carried(&cn));
    println!("\nby hand, four points in bridge order: cell middle, kick, Acme at one year, payoff");
    let z4: Vec<f64> = (0..4).map(|b| ninv((b as f64 + 0.5) / 4.0)).collect();
    let mut raw = 0.0f64;
    for p in grid(2, &vs) {
        let st = acme(&bridge(&p.iter().map(|&b| z4[b]).collect::<Vec<f64>>()));
        raw += (st - K).max(0.0);
        println!("   {:>10.6} {:>11.6} {:>13.6} {:>12.6}", (p[0] as f64 + 0.5) / 4.0, z4[p[0]], st, (st - K).max(0.0));
    }
    row("   their average payoff", raw / 4.0, &format!("   discounted {:.6}, error {:+.6}", (-R * T).exp() * raw / 4.0, (-R * T).exp() * raw / 4.0 - exact));
    println!("\n{:>6}  {:>12}{:>15}  {:>18}  {:>14}", "N", "Monte Carlo", "its error bar", "Sobol, time order", "Sobol, bridge");
    let (mut res, mut perm, mut state): (Vec<[f64; 5]>, bool, u64) = (vec![], true, 20260919);
    for &m in MS.iter() {
        let n = 1usize << m;
        let ints = grid(m, &vs);
        for j in 0..D {
            let mut c: Vec<usize> = ints.iter().map(|p| p[j]).collect();
            c.sort();
            perm = perm && c == (0..n).collect::<Vec<usize>>();
        }
        let zs: Vec<f64> = (0..n).map(|b| ninv((b as f64 + 0.5) / n as f64)).collect();
        let (mut qn, mut qb, mut sq, mut tot, mut tsq) = (0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64);
        for p in &ints {
            let z: Vec<f64> = p.iter().map(|&b| zs[b]).collect();
            let v = payoff(&bridge(&z));
            qn += payoff(&natural(&z)); qb += v; sq += v * v;
        }
        for _ in 0..n {
            let v = payoff(&natural(&(0..D).map(|_| nxt(&mut state)).collect::<Vec<f64>>()));
            tot += v; tsq += v * v;
        }
        let (mc, qbm) = (tot / n as f64, qb / n as f64);
        let bar = ((tsq / n as f64 - mc * mc).max(0.0) / (n - 1) as f64).sqrt();
        let fake = ((sq / n as f64 - qbm * qbm).max(0.0) / (n - 1) as f64).sqrt();
        res.push([mc - exact, bar, qn / n as f64 - exact, qbm - exact, fake]);
        println!("{:>6}  {:>+12.6}{:>15.6}  {:>+18.6}  {:>+14.6}", n, mc - exact, bar, qn / n as f64 - exact, qbm - exact);
    }
    let sl: Vec<f64> = [1usize, 2, 3].iter().map(|&c| (res[4][c] / res[0][c]).abs().ln() / 2.0f64.ln() / (MS[4] - MS[0]) as f64).collect();
    println!("{:<52}{}, on {} different direction rows", "every coordinate a permutation of its own grid", if perm { "yes" } else { "no" }, uniq.len());
    println!("error halvings per doubling, 256 to 65536: error bar {:+.4}, time order {:+.4}, bridge {:+.4}", sl[0], sl[1], sl[2]);
    println!("{:<41}{}", "chart, log2 of the budget", MS.iter().map(|m| format!("{:>6}", m)).collect::<Vec<String>>().join(" "));
    for (lab, c) in [("Monte Carlo error bar", 1usize), ("Sobol in time order", 2), ("Sobol in bridge order", 3)] {
        println!("{:<41}{}", format!("chart, log2 error, {}", lab), (0..5).map(|i| format!("{:>6.2}", res[i][c].abs().ln() / 2.0f64.ln())).collect::<Vec<String>>().join(" "));
    }
    println!();
    row("right: Sobol in bridge order, 4,096 points", exact + res[2][3], &format!("   error {:+.6}", res[2][3]));
    row("wrong: Sobol in time order, 4,096 points", exact + res[2][2], &format!("   error {:+.6}, {:.0} times the bridge's", res[2][2], (res[2][2] / res[2][3]).abs()));
    row("wrong: time order at 16,384 against bridge at 4,096", exact + res[3][2], &format!("   error {:+.6}, {:.0} times", res[3][2], (res[3][2] / res[2][3]).abs()));
    row("wrong: payoff scatter over root N as an error bar", res[2][4], &format!("   true error {:+.6}", res[2][3]));
    assert!(POLYS.iter().all(|&p| order(p) == (1u32 << p.ilog2()) - 1));   // every one primitive
    assert!((exact - HOUSE).abs() < 1e-9);              // our own formula vs the shelf's number
    assert!((ncdf(1.0) - 0.8413447460685429).abs() < 1e-12 && (ninv(0.975) - 1.959963984540054).abs() < 1e-9);
    assert!(cov_gap(&cn) < 1e-12 && cov_gap(&cb) < 1e-12);   // both maps rebuild min(t_i, t_j)
    assert!((cb[0][D - 1] - T.sqrt()).abs() < 1e-15 && later < 1e-15);   // the end is one draw
    assert!(perm && uniq.len() == D);                   // stratified, and 16 different rows
    assert!(res[4][0].abs() < 3.0 * res[4][1]);         // the random road inside three error bars
    assert!(res[2][3].abs() < 0.001);                   // the bridge, inside a tenth of a cent
    assert!(res[2][3].abs() < 0.01 * res[2][2].abs());  // a hundred times closer than time order
    assert!(res[2][3].abs() < 0.1 * res[3][2].abs());   // beating time order at four times the budget
    assert!(sl[0] > -0.55 && sl[0] < -0.45 && sl[2] < -0.9);   // the two rates, measured
    assert!(res[2][4] > 100.0 * res[2][3].abs());       // the fake error bar is not an error
    println!("ALL CHECKS PASS");
}
