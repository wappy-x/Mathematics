// Machines that prove -- the same check as the Python, in Rust.  No crates.
// A machine's output is a candidate, not a confirmation.  Six small audits a
// reader can rerun: each recomputes a number by a second, independent road.
use std::collections::HashMap;
type Big = Vec<u64>; // base 10^9 limbs, least significant first
const B: u64 = 1_000_000_000;
fn big_pow(a: u64, n: u32) -> Big {
    let mut x: Big = vec![1];
    for _ in 0..n {
        let mut carry = 0;
        for l in x.iter_mut() { let v = *l * a + carry; *l = v % B; carry = v / B; }
        while carry > 0 { x.push(carry % B); carry /= B; }
    }
    x
}
fn big_add(x: &Big, y: &Big) -> Big {
    let (mut z, mut carry) = (vec![], 0);
    for i in 0..x.len().max(y.len()) {
        let v = x.get(i).unwrap_or(&0) + y.get(i).unwrap_or(&0) + carry;
        z.push(v % B); carry = v / B;
    }
    if carry > 0 { z.push(carry); }
    z
}
fn big_sub(x: &Big, y: &Big) -> Big { // x >= y
    let (mut z, mut borrow) = (vec![], 0i64);
    for i in 0..x.len() {
        let mut v = x[i] as i64 - *y.get(i).unwrap_or(&0) as i64 - borrow;
        borrow = if v < 0 { v += B as i64; 1 } else { 0 };
        z.push(v as u64);
    }
    while z.len() > 1 && *z.last().unwrap() == 0 { z.pop(); }
    z
}
fn big_str(x: &Big) -> String {
    let mut s = format!("{}", x[x.len() - 1]);
    for l in x.iter().rev().skip(1) { s.push_str(&format!("{:09}", l)); }
    s
}
fn big_mod(x: &Big, p: u64) -> u64 { x.iter().rev().fold(0, |r, &l| (r * B + l) % p) }
fn fmt10(s: &str) -> String {
    let p = ((s[..11].parse::<u64>().unwrap() + 5) / 10).to_string();
    format!("{}.{}e{}", &p[..1], &p[1..], s.len() - 1)
}
fn fpow(a: f64, n: u32) -> f64 { let mut p = 1.0; for _ in 0..n { p *= a; } p }
fn pmod(a: u64, n: u32, p: u64) -> u64 { let mut r = 1; for _ in 0..n { r = r * a % p; } r }
fn gcd(a: u64, b: u64) -> u64 { if b == 0 { a } else { gcd(b, a % b) } }
fn search(n: u32, top: u64) -> usize {
    let pw: HashMap<u128, u64> = (1..=top).map(|c| ((c as u128).pow(n), c)).collect();
    let mut hits = 0;
    for a in 1..top { for b in a..top {
        if pw.contains_key(&((a as u128).pow(n) + (b as u128).pow(n))) { hits += 1; }
    } }
    hits
}
fn status(s: bool, a: bool, c: &str, kind: &'static str) -> &'static str {
    if c == "false" { return "refuted"; }
    if c == "gap" { return "as before"; }
    if s && a && c == "pass" { return kind; }
    "claimed"
}
fn main() {
    // 1. The near miss: 1782^12 + 1841^12 against 1922^12, three roads.
    let l = big_add(&big_pow(1782, 12), &big_pow(1841, 12));
    let r = big_pow(1922, 12);
    let (ls, rs) = (big_str(&l), big_str(&r));
    let gap = (fpow(1782.0, 12) + fpow(1841.0, 12) - fpow(1922.0, 12)) / fpow(1922.0, 12);
    println!("near miss, left  1782^12 + 1841^12 = {}", ls);
    println!("near miss, right 1922^12           = {}", rs);
    println!("left minus right                   = -{}", big_str(&big_sub(&r, &l)));
    println!("10-digit calculator shows {} and {}", fmt10(&ls), fmt10(&rs));
    println!("relative gap (floating point)      = {:.4e}", gap);
    let parity = |x: &Big| if big_mod(x, 2) == 1 { "odd" } else { "even" };
    println!("last digits {} and {} ; left is {} , right is {}", big_mod(&l, 10), big_mod(&r, 10), parity(&l), parity(&r));
    let primes = [1000003u64, 1000033, 1000037];
    let res: Vec<(u64, u64)> = primes.iter().map(|&p| ((pmod(1782, 12, p) + pmod(1841, 12, p)) % p, pmod(1922, 12, p))).collect();
    let rstr: Vec<String> = res.iter().map(|(a, b)| format!("({}, {})", a, b)).collect();
    println!("residues mod 1000003, 1000033, 1000037: [{}]", rstr.join(", "));

    // 2. Fermat, small cases: search c <= 100.  n = 2 is the control that must hit.
    let top = 100u64;
    let mut euclid = 0;
    for m in 2..11u64 { for j in 1..m {
        if (m - j) % 2 == 1 && gcd(m, j) == 1 { euclid += top / (m * m + j * j); }
    } }
    let hits: Vec<usize> = (2..11).map(|n| search(n, top)).collect();
    let hs: Vec<String> = hits.iter().map(|h| h.to_string()).collect();
    println!("solutions of a^n + b^n = c^n with c <= {}, n = 2..10: [{}]", top, hs.join(", "));
    println!("Euclid's formula count for n = 2: {}", euclid);
    let mut near = (i64::MAX, 0i64, 0i64, 0i64);
    for a in 2..100i64 { for b in a..100 { for c in b + 1..126 {
        let d = a * a * a + b * b * b - c * c * c;
        if d != 0 && (d.abs(), a, b, c) < near { near = (d.abs(), a, b, c); }
    } } }
    let (_, a, b, c) = near;
    println!("closest cube miss: {}^3 + {}^3 - {}^3 = {}", a, b, c, a * a * a + b * b * b - c * c * c);

    // 3. Zeta zeros: the proved lower bounds as percentages, and the 2026 constants.
    let x = 1.0 / 2f64.sqrt();
    let (mut s, mut cs, mut t, mut u) = (0.0, 0.0, x, 1.0);
    for k in 0..12 {
        s += t; cs += u;
        t *= -x * x / (((2 * k + 2) * (2 * k + 3)) as f64); u *= -x * x / (((2 * k + 1) * (2 * k + 2)) as f64);
    }
    let cinv_series = 0.5 + x * cs / s;
    let cinv_tan = 0.5 + x / x.tan();
    let (mt, mt_d) = (2.0 - cinv_series, (3.0 - cinv_series) / 2.0);
    for (name, v) in [("1974 one third", 1.0 / 3.0), ("1989 two fifths", 2.0 / 5.0), ("2020 five twelfths", 5.0 / 12.0),
                      ("2026 two thirds", 2.0 / 3.0), ("2026 with the MT window", mt)] {
        println!("zeros on the line, at least {:<24}{:8.3}%  {}", name, 100.0 * v, "#".repeat((50.0 * v as f64).round() as usize));
    }
    println!("MT window constant: series {:.12}, tangent {:.12}; distinct {:.5}", mt, 2.0 - cinv_tan, mt_d);

    // 4. Unit distances in a k by k grid: the commonest distance, two roads.
    let mut grid = vec![];
    for k in 2..9i64 {
        let pts: Vec<(i64, i64)> = (0..k).flat_map(|i| (0..k).map(move |j| (i, j))).collect();
        let mut cnt: HashMap<i64, i64> = HashMap::new();
        for p in 0..pts.len() { for q in p + 1..pts.len() {
            let d = (pts[p].0 - pts[q].0).pow(2) + (pts[p].1 - pts[q].1).pow(2);
            *cnt.entry(d).or_insert(0) += 1;
        } }
        let best = *cnt.values().max().unwrap();
        let d = *cnt.iter().filter(|(_, &v)| v == best).map(|(e, _)| e).min().unwrap();
        let mut rep = 0;
        for dx in -k + 1..k { for dy in -k + 1..k {
            if dx * dx + dy * dy == d { rep += (k - dx.abs()) * (k - dy.abs()); }
        } }
        rep /= 2;
        grid.push((k * k, d, best, rep));
        println!("grid {}x{}: n = {:2}, squared distance {}, pairs = {:3}, by counting vectors {:3}, log pairs / log n = {:.3}",
                 k, k, k * k, d, best, rep, (best as f64).ln() / ((k * k) as f64).ln());
    }
    println!("unit-distance exponent excess, quoted: 6.24e-38 in the checked write-up, 0.014 claimed in a sharper preprint");

    // 5. Finite-time blow-up in one line: y' = y^2, y(0) = 1, exact y = 1/(1 - t).
    let (mut y, h, mut step, mut blow) = (1.0f64, 0.0001, 0, vec![]);
    for stop in [5000, 9000, 9900, 9990] {
        while step < stop {
            let k1 = y * y; let mut a = y + h / 2.0 * k1; let k2 = a * a; a = y + h / 2.0 * k2; let k3 = a * a;
            a = y + h * k3; let k4 = a * a;
            y += h / 6.0 * (k1 + 2.0 * k2 + 2.0 * k3 + k4); step += 1;
        }
        let exact = 1.0 / (1.0 - stop as f64 * h);
        blow.push((y, exact));
        println!("blow-up toy at t = {:.3}: step by step {:.6}, exact 1/(1 - t) {:.6}", stop as f64 * h, y, exact);
    }

    // 6. The audit list.  Fields: statement matched (S), artifact public (A),
    //    independent check (C: pass, gap, false or none).  Status is computed, not typed.
    let rows = [("near miss, n = 12", true, true, if l == r { "pass" } else { "false" }, "proved"),
                ("Fermat formalisation", true, true, "pass", "proved"),
                ("zeta zeros, two thirds", true, true, "none", "proved"),
                ("unit-distance conjecture", true, true, "pass", "refuted"),
                ("Navier-Stokes blow-up", true, true, "none", "proved")];
    let audit: Vec<&str> = rows.iter().map(|&(_, s, a, c, kind)| status(s, a, c, kind)).collect();
    let yn = |v: bool| if v { "yes" } else { "no " };
    for (row, st) in rows.iter().zip(&audit) {
        println!("audit: {:<26} S={} A={} C={:<5} -> {}", row.0, yn(row.1), yn(row.2), row.3, st);
    }

    assert!(l != r && fmt10(&ls) == fmt10(&rs) && big_mod(&l, 2) != big_mod(&r, 2));
    assert!(res.iter().zip(primes).all(|(&rr, p)| rr == (big_mod(&l, p), big_mod(&r, p))));
    assert!(hits[0] == euclid as usize && euclid == 52 && hits[1..].iter().all(|&h| h == 0));
    assert!((cinv_series - cinv_tan).abs() < 1e-12 && (mt * 1e5).round() == 67250.0 && (mt_d * 1e5).round() == 83625.0);
    assert!(grid[1].2 == 12 && grid.iter().all(|g| g.2 == g.3));
    assert!(blow.iter().all(|(a, b)| (a / b - 1.0).abs() < 1e-5));
    assert!(audit == ["refuted", "proved", "claimed", "refuted", "claimed"]);
    println!("ALL CHECKS PASS");
}
