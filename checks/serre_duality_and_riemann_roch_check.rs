// Serre duality and Riemann-Roch -- the same check as the Python.  No crates.
// Road 1: Cech cohomology of O(d) on P^n by exact ranks, one Laurent monomial x^a at a time.
// Road 2: closed counts of monomials.  Road 3: a curve's points over F_13, and the rank of forms on them.
use std::collections::HashMap;
type Hc = (Vec<i64>, Vec<Vec<i64>>, Vec<Vec<i64>>); // h^0..h^n, exponents spanning H^0, exponents spanning H^n

fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn rank(rows: &Vec<Vec<i128>>, p: i128) -> usize { // exact rank: over Q (p = 0) or over F_p
    let mut m = rows.clone(); let mut r = 0;
    let cols = if m.is_empty() { 0 } else { m[0].len() };
    for c in 0..cols {
        let nz = |v: i128| if p > 0 { v % p != 0 } else { v != 0 };
        let q = match (r..m.len()).find(|&i| nz(m[i][c])) { Some(q) => q, None => continue };
        m.swap(r, q);
        for i in r + 1..m.len() {
            let (a, b) = (m[r][c], m[i][c]);
            let row: Vec<i128> = (0..cols).map(|k| a.checked_mul(m[i][k]).unwrap() - b.checked_mul(m[r][k]).unwrap()).collect();
            let g = row.iter().fold(0, |g, &x| gcd(g, x)).max(1);
            m[i] = row.iter().map(|&x| if p > 0 { x.rem_euclid(p) } else { x / g }).collect();
        }
        r += 1;
    }
    r
}
fn face(j: &Vec<usize>, i: &Vec<usize>) -> i128 { // sign of I inside J in the Cech differential
    for k in 0..j.len() {
        let mut s = j.clone(); s.remove(k);
        if &s == i { return if k % 2 == 0 { 1 } else { -1 }; }
    }
    0
}
fn combos(n: usize, k: usize) -> Vec<Vec<usize>> { // subsets of 0..n of size k, in lexicographic order
    if k == 0 { return vec![vec![]]; }
    let mut out = vec![];
    for first in 0..n { for rest in combos(n, k - 1) { if rest.iter().all(|&x| x > first) { let mut v = vec![first]; v.extend(rest); out.push(v); } } }
    out
}
fn cech(n: usize, d: i64) -> Hc { // h^0..h^n of O(d) on P^n from the n + 1 standard charts
    let b = d.abs() + n as i64 + 1;
    let (mut h, mut top0, mut topn) = (vec![0i64; n + 1], vec![], vec![]);
    let mut head = vec![-b; n];
    loop {
        let last = d - head.iter().sum::<i64>();
        if last.abs() <= b {
            let mut a = head.clone(); a.push(last); // the monomial x_0^a_0 ... x_n^a_n of degree d
            let neg: Vec<usize> = (0..=n).filter(|&j| a[j] < 0).collect();
            let cells: Vec<Vec<Vec<usize>>> = (0..=n).map(|p| combos(n + 1, p + 1).into_iter().filter(|c| neg.iter().all(|x| c.contains(x))).collect()).collect();
            let mut rk = vec![0usize; n + 2]; // rk[p]: rank of the Cech map C^(p-1) -> C^p
            for p in 1..=n {
                if !cells[p - 1].is_empty() && !cells[p].is_empty() {
                    rk[p] = rank(&cells[p].iter().map(|j| cells[p - 1].iter().map(|i| face(j, i)).collect()).collect(), 0);
                }
            }
            for p in 0..=n {
                let k = cells[p].len() as i64 - rk[p] as i64 - rk[p + 1] as i64;
                h[p] += k;
                if k > 0 && p == 0 { top0.push(a.clone()); }
                if k > 0 && p == n { topn.push(a.clone()); }
            }
        }
        let mut i = n; // next head, last coordinate fastest
        loop { if i == 0 { return (h, top0, topn); } i -= 1; if head[i] < b { head[i] += 1; break; } head[i] = -b; }
    }
}
fn comb(n: i64, k: i64) -> i64 { if k < 0 || n < k { 0 } else { (0..k).fold(1, |c, i| c * (n - i) / (i + 1)) } }
fn tf(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn lst(v: &Vec<i64>) -> String { format!("[{}]", v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ")) }
fn tup(v: &Vec<Vec<i64>>) -> String { format!("[{}]", v.iter().map(|t| format!("({})", t.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", "))).collect::<Vec<_>>().join(", ")) }
fn pairing(a: &Vec<Vec<i64>>, b: &Vec<Vec<i64>>) -> Vec<Vec<i128>> {
    a.iter().map(|x| b.iter().map(|y| x.iter().zip(y).all(|(u, v)| u + v == -1) as i128).collect()).collect() }
fn main() {
    let mut hh: HashMap<(usize, i64), Hc> = HashMap::new(); let mut keys = vec![];
    for (n, lo, hi) in [(1usize, -5i64, 3i64), (2, -8, 5), (3, -5, 1)] { // each range is symmetric under d -> -d - n - 1
        for d in lo..=hi { hh.insert((n, d), cech(n, d)); keys.push((n, d)); }
        for i in 0..=n { println!("P^{}, h^{}(O(d)) for d = {}..{}: {}", n, i, lo, hi, lst(&(lo..=hi).map(|d| hh[&(n, d)].0[i]).collect())); }
    }
    let closed = |n: i64, d: i64, i: i64| if i == 0 && d >= 0 { comb(d + n, n) } else if i == n && d <= -n - 1 { comb(-d - 1, n) } else { 0 };
    assert!(keys.iter().all(|&(n, d)| (0..=n).all(|i| hh[&(n, d)].0[i] == closed(n as i64, d, i as i64))));
    println!("Cech ranks against the monomial counts C(d + n, n) and C(-d - 1, n): agree at all {} (n, d)", keys.len());
    let (mut ok, mut bad) = (vec![], vec![]);
    for &(n, d) in &keys {
        for i in 0..=n { ok.push(hh[&(n, d)].0[i] == hh[&(n, -d - n as i64 - 1)].0[n - i]); }
        if let Some(w) = hh.get(&(n, -d - n as i64)) { for i in 0..=n { bad.push(hh[&(n, d)].0[i] != w.0[n - i]); } }
    }
    let cnt = |v: &Vec<bool>| v.iter().filter(|&&x| x).count();
    println!("Serre duality, K = O(-n - 1): h^i(O(d)) = h^(n-i)(O(-d - n - 1)) at {} of {} (n, d, i)", cnt(&ok), ok.len());
    println!("mistake, K = O(-n): {} of {} (n, d, i) fail", cnt(&bad), bad.len());
    assert!(cnt(&ok) == ok.len() && cnt(&bad) > 0);
    let mut sizes = vec![]; // the Cech pairing H^0(O(d)) x H^n(O(-d-n-1)) -> H^n(K)
    for &(n, d) in &keys {
        let (a, b) = (&hh[&(n, d)].1, &hh[&(n, -d - n as i64 - 1)].2);
        if !a.is_empty() { assert!(a.len() == b.len() && b.len() == rank(&pairing(a, b), 0)); sizes.push(a.len()); }
    }
    let mx = *sizes.iter().max().unwrap();
    println!("Cech pairing, x^a times x^b lands on 1/(x_0...x_n) exactly when b = -1 - a: perfect at {} (n, d), sizes up to {} x {}", sizes.len(), mx, mx);
    let (a, b) = (&hh[&(1, 1)].1, &hh[&(1, -3)].2);
    println!("P^1: H^0(O(1)) has exponents {}, H^1(O(-3)) has {}", tup(a), tup(b));
    let pm: Vec<Vec<i64>> = pairing(a, b).iter().map(|r| r.iter().map(|&x| x as i64).collect()).collect();
    println!("P^1: pairing matrix {}, so h^1(O(-3)) = {} = h^0(O(1))", tup(&pm).replace('(', "[").replace(')', "]"), b.len());
    println!("mistake, pair H^1(O(-3)) with H^0 of the dual O(3) alone: {}, not {}", hh[&(1, 3)].0[0], b.len());
    let hp = |i: usize, m: i64| hh[&(2, m)].0[i]; // plane curve C of degree d: 0 -> O(m - d) -> O(m) -> O_C(m) -> 0
    let h0c = |d: i64, m: i64| hp(0, m) - hp(0, m - d); // the H^1 terms of P^2 are 0, as printed above
    let h1c = |d: i64, m: i64| hp(2, m - d) - hp(2, m);
    let mon = |d: i64, m: i64| (0..=m).map(|i| (0..=m - i).filter(|j| m - i - j < d).count() as i64).sum::<i64>(); // z-power below d
    let gs: Vec<i64> = (1..6).map(|d| h1c(d, 0)).collect();
    println!("plane curves x^d + y^d + z^d, d = 1..5: genus h^1(O_C) = h^2(O(-d)) - h^2(O) = {}; (d-1)(d-2)/2 = {}", lst(&gs), lst(&(1..6).map(|d| (d - 1) * (d - 2) / 2).collect()));
    println!("deg K = d(d - 3) = {}; 2g - 2 = {}", lst(&(1..6).map(|d| d * (d - 3)).collect()), lst(&gs.iter().map(|g| 2 * g - 2).collect()));
    assert!((1..6).all(|d| gs[d as usize - 1] == (d - 1) * (d - 2) / 2 && d * (d - 3) == 2 * gs[d as usize - 1] - 2));
    let pairs: Vec<(i64, i64)> = (1..6).flat_map(|d| (-3..6).map(move |m| (d, m))).collect();
    let g = |d: i64| gs[d as usize - 1];
    let dual = pairs.iter().all(|&(d, m)| h1c(d, m) == h0c(d, d - 3 - m));
    let chi = pairs.iter().all(|&(d, m)| h0c(d, m) - h1c(d, m) == m * d + 1 - g(d));
    let rr = pairs.iter().all(|&(d, m)| h0c(d, m) - h0c(d, d - 3 - m) == m * d + 1 - g(d));
    let mons = pairs.iter().filter(|e| e.1 >= 0).all(|&(d, m)| h0c(d, m) == mon(d, m));
    println!("on C, D = m times a line section, m = -3..5: duality h^1(O_C(D)) = h^0(O_C(K - D)) at all {}: {}", pairs.len(), tf(dual));
    println!("chi(O_C(D)) = deg D + 1 - g at all {}: {}; Riemann-Roch l(D) - l(K - D) = deg D + 1 - g: {}", pairs.len(), tf(chi), tf(rr));
    println!("h^0(O_C(m)) against the monomials of degree m with z-power below d, m >= 0: {}", tf(mons));
    assert!(dual && chi && rr && mons);
    let p: i128 = 13;
    let pts = |d: u32| -> Vec<[i128; 3]> { // points of x^d + y^d + z^d = 0 over F_13, one per line through 0
        let mut c: Vec<[i128; 3]> = (0..p).flat_map(|y| (0..p).map(move |z| [1, y, z])).collect();
        c.extend((0..p).map(|z| [0, 1, z])); c.push([0, 0, 1]);
        c.into_iter().filter(|v| v.iter().map(|x| x.pow(d)).sum::<i128>() % p == 0).collect() };
    let evrank = |d: u32, m: u32| { // rank of the degree-m forms evaluated at those points
        let ms: Vec<(u32, u32, u32)> = (0..=m).flat_map(|i| (0..=m - i).map(move |j| (i, j, m - i - j))).collect();
        rank(&pts(d).iter().map(|v| ms.iter().map(|&(i, j, k)| v[0].pow(i) * v[1].pow(j) * v[2].pow(k) % p).collect()).collect(), p) as i64 };
    for (d, m, what) in [(3i64, 1i64, "cubic, D = line section, degree 3"), (4, 1, "quartic, D = K = line section, degree 4"), (4, 2, "quartic, D = 2K, degree 8"), (4, 4, "quartic, D = 4K, degree 16")] {
        let (gg, e) = (g(d), h0c(d, d - 3 - m));
        let (np, er) = (pts(d as u32).len() as i64, evrank(d as u32, m as u32));
        println!("{}: h^0 = {}; monomials {}; Riemann-Roch {} + 1 - {} + l(K - D) {} = {}", what, h0c(d, m), mon(d, m), m * d, gg, e, m * d + 1 - gg + e);
        println!("  over F_{}: {} points; the {} forms of degree {} have rank {} on them", p, np, comb(m + 2, 2), m, er);
        assert!(h0c(d, m) == mon(d, m) && mon(d, m) == m * d + 1 - gg + e && e + m * d + 1 - gg == er && np > m * d);
    }
    println!("quartic: h^0(2K) = {} = 3g - 3, the number of parameters of curves of genus 3", h0c(4, 2));
    println!("mistake, Riemann-Roch without l(K - D): quartic at D = K gives {}, not {}; cubic at D = 0 gives {}, not {}", 4 + 1 - 3, h0c(4, 1), 0 + 1 - 1, h0c(3, 0));
    let aff: Vec<i64> = [10i64, 100, 1000].iter().map(|&n| (0..=n).count() as i64).collect(); // the monomials x^a with 0 <= a <= N on the one chart
    let c1 = combos(1, 2); // Cech 1-cells of a one-chart cover: none, so h^1 = 0
    println!("mistake, the affine line (not projective): polynomials of degree <= N number {}, no end; h^1(K) = {} with one chart", lst(&aff), c1.len());
    assert!(aff[0] < aff[1] && aff[1] < aff[2] && c1.is_empty());
    println!("ALL CHECKS PASS");
}
