// The abc conjecture: radicals of a + b = c, and what abc would decide.  Rust std only, no crates.
// abc is open, so every count here is evidence.  Roads: radical by sieve against trial division;
// hit count by a pruned search against brute force; Frey discriminant two ways.
use std::collections::{BTreeMap, BTreeSet};
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn primes_of(mut n: u128) -> BTreeSet<u128> { // trial division: the set of primes dividing n
    let (mut out, mut p) = (BTreeSet::new(), 2u128);
    while p * p <= n {
        while n % p == 0 { out.insert(p); n /= p; }
        p += 1; }
    if n > 1 { out.insert(n); }
    out
}
fn rad_trial(n: u128) -> u128 { primes_of(n).iter().product() }
fn qual(a: u128, b: u128, c: u128) -> f64 { (c as f64).ln() / (rad_trial(a * b * c) as f64).ln() }
fn commas(n: u128) -> String {
    let (s, mut out) = (n.to_string(), String::new());
    for (i, ch) in s.chars().enumerate() {
        if i > 0 && (s.len() - i) % 3 == 0 { out.push(','); }
        out.push(ch);
    }
    out
}
fn sci(x: f64) -> String { // Python's {:.2e}: two-digit exponent with sign
    let s = format!("{:.2e}", x);
    let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn frac(n: i128, d: i128) -> (i128, i128) { let g = gcd(n, d); (n / g, d / g) }
fn invariants(a1: i128, a2: i128, a4: i128) -> (i128, i128) { // y^2 + a1 xy = x^3 + a2 x^2 + a4 x
    let (b2, b4, b8) = (a1 * a1 + 4 * a2, 2 * a4, -a4.checked_mul(a4).unwrap());
    let d = (-b2 * b2).checked_mul(b8).unwrap() - 8 * b4.pow(3);
    (d, b2 * b2 - 24 * b4) // discriminant, c4
}
fn main() {
    println!("example: 1 + 8 = 9");
    println!("rad(1*8*9) = {}  c = 9  quality = {:.4}", rad_trial(72), qual(1, 8, 9));
    println!("typical: 2 + 3 = 5   rad = {}  quality = {:.4}", rad_trial(30), qual(2, 3, 5));
    assert!(rad_trial(72) == 6 && rad_trial(2 * 3 * 5) == 30); // trial division against the factorisations

    println!("\nfamily 1 + (3^(2^k) - 1) = 3^(2^k): c/rad grows without bound");
    let mut fam = Vec::new();
    for k in 1..6u32 {
        let (c, b) = (3u128.pow(2u32.pow(k)), 3u128.pow(2u32.pow(k)) - 1);
        let mut ps = BTreeSet::from([3u128]);
        for j in 0..k { ps.extend(primes_of(3u128.pow(2u32.pow(j)) + 1)); }
        let r: u128 = ps.iter().product();
        if k <= 4 { assert_eq!(r, rad_trial(b * c)); } // second road for the radical
        let lb = 2f64.powi(k as i32 + 1) / 3.0;
        assert!(b % 2u128.pow(k + 2) == 0 && 3 * c > 2u128.pow(k + 1) * r); // exact: c/rad > 2^(k+1)/3
        fam.push(c as f64 / r as f64);
        println!("k={}  c={:>20}  rad={:>14}  c/rad={:12.4}  lower bound={:.4}  quality={:.4}",
            k, commas(c), commas(r), c as f64 / r as f64, lb, (c as f64).ln() / (r as f64).ln());
    }

    const N: usize = 100_000;
    let mut rad = vec![1u128; N + 1];
    for p in 2..=N {
        if rad[p] == 1 { let mut m = p; while m <= N { rad[m] *= p as u128; m += p; } }
    }
    assert!((1..=3000).all(|m| rad[m] == rad_trial(m as u128)));
    let mut order: Vec<usize> = (1..=N).collect();
    order.sort_by_key(|&a| rad[a]);
    let mut hits: Vec<(u128, u128, u128)> = Vec::new();
    for c in 3..=N {
        let bound = c as u128 / rad[c];
        for &a in &order {
            if rad[a] > bound { break; }
            if 2 * a >= c { continue; }
            let b = c - a;
            if gcd(a as i128, b as i128) == 1 && rad[a] * rad[b] * rad[c] < c as u128 { hits.push((a as u128, b as u128, c as u128)); }
        }
    }
    let brute = (3..1000u128).map(|c| (1..(c + 1) / 2)
        .filter(|&a| gcd(a as i128, c as i128) == 1 && rad_trial(a * (c - a) * c) < c).count()).sum::<usize>();
    assert!(brute == hits.iter().filter(|h| h.2 < 1000).count() && brute == 31);
    println!("\nhits: coprime a < b with a + b = c, c below the bound, and rad(abc) < c");
    let mut phi: Vec<u128> = (0..=N as u128).collect();
    for p in 2..=N {
        if phi[p] == p as u128 { let mut m = p; while m <= N { phi[m] -= phi[m] / p as u128; m += p; } }
    }
    for m in [100usize, 1000, 10_000, 100_000] {
        let h = hits.iter().filter(|t| t.2 < m as u128).count();
        let total: u128 = (3..m).map(|c| phi[c] / 2).sum();
        println!("c < {:>7}  hits={:>4}  all triples={:>13}  share={}",
            commas(m as u128), h, commas(total), sci(h as f64 / total as f64));
        assert!(m > 1000 || total == (3..m).map(|c| (1..(c + 1) / 2).filter(|&a| gcd(a as i128, c as i128) == 1).count() as u128).sum::<u128>());
    }
    println!("brute force below 1,000 agrees: 31");
    let mut top = hits.clone(); // stable sort, best quality first
    top.sort_by(|x, y| qual(y.0, y.1, y.2).partial_cmp(&qual(x.0, x.1, x.2)).unwrap());
    println!("highest quality, c <= 100,000:");
    for t in &top[..6] {
        println!("  {} + {} = {}   rad={}   quality={:.4}", t.0, t.1, t.2, commas(rad_trial(t.0 * t.1 * t.2)), qual(t.0, t.1, t.2));
    }
    println!("triples with quality > 1.4: {}", hits.iter().filter(|t| qual(t.0, t.1, t.2) > 1.4).count());
    assert!(hits.iter().all(|t| qual(t.0, t.1, t.2) < 2.0)); // c < rad^2 holds throughout the search
    let (a, b, c) = (2u128, 3u128.pow(10) * 109, 23u128.pow(5));
    assert_eq!(a + b, c);
    println!("record: 2 + 3^10*109 = 23^5 = {}   rad={}   quality={:.4}", commas(c), commas(rad_trial(a * b * c)), qual(a, b, c));

    println!("\nexponent room: rad(x^n y^n z^n) = rad(xyz) < z^3, so c < rad^2 forces n < 6");
    let s1 = (4..40i128).map(|n| frac(3, n)).max_by(|x, y| (x.0 * y.1).cmp(&(y.0 * x.1))).unwrap();
    let e1 = frac(s1.1 - s1.0, s1.0);
    println!("largest 3/n, n >= 4 (Fermat) = {}/{}, abc bites for eps < {}/{}", s1.0, s1.1, e1.0, e1.1);
    let (mut s2, mut s3) = ((0i128, 1i128), (0i128, 1i128));
    for l in 2..40i128 {
        for m in l..40 {
            if (l, m) != (2, 2) && (l + m) * s2.1 > s2.0 * l * m { s2 = frac(l + m, l * m); }
            for n in m..40 {
                let (nu, de) = (m * n + l * n + l * m, l * m * n);
                if nu < de && nu * s3.1 > s3.0 * de { s3 = frac(nu, de); } } } }
    let (e2, e3) = (frac(s2.1 - s2.0, s2.0), frac(s3.1 - s3.0, s3.0));
    println!("largest 1/m + 1/n (Catalan) = {}/{}, abc bites for eps < {}/{}", s2.0, s2.1, e2.0, e2.1);
    println!("largest 1/l + 1/m + 1/n below 1 = {}/{}, abc bites for eps < {}/{}", s3.0, s3.1, e3.0, e3.1);
    assert!(s1 == (3, 4) && s2 == (5, 6) && s3 == (41, 42));
    println!("\nwhat breaks");
    println!("product instead of radical: 1*8*9 = {} (always above c)", 1 * 8 * 9);
    println!("no epsilon, fixed K: family c/rad at k=5 is {:.4}", fam[fam.len() - 1]);
    println!("common factor: 512 + 512 = 1024, rad = {}, quality = {:.4}", rad_trial(512 * 512 * 1024), 1024f64.ln() / 2f64.ln());

    const L: u128 = 1_000_000; // perfect powers up to L, highest exponent kept
    let mut pw: BTreeMap<u128, (u128, u32)> = BTreeMap::new();
    for e in 2..(128 - L.leading_zeros()) { // 2^e <= L needs e below L's bit length
        let mut x = 2u128;
        while x.pow(e) <= L { pw.insert(x.pow(e), (x, e)); x += 1; }
    }
    pw.insert(1, (1, 1_000_000_000)); // 1 = 1^e for every e
    let vals: Vec<u128> = pw.keys().cloned().collect();
    let consec: Vec<String> = vals[1..].windows(2).filter(|w| w[1] - w[0] == 1).map(|w| format!("({}, {})", w[0], w[1])).collect();
    println!("\nconsecutive perfect powers up to {}: [{}]", commas(L), consec.join(", "));
    let (mut fc, mut beal, mut beal_nc) = (Vec::new(), 0, Vec::new());
    for (i, &u) in vals.iter().enumerate() {
        for &v in &vals[i..] {
            let w = u + v;
            if w > L { break; }
            if let Some(&pwv) = pw.get(&w) {
                let (el, em, en) = (pw[&u].1 as f64, pw[&v].1 as f64, pwv.1 as f64);
                if gcd(u as i128, v as i128) == 1 {
                    if 1.0 / el + 1.0 / em + 1.0 / en < 1.0 { fc.push((pw[&u], pw[&v], pwv)); }
                    if el.min(em).min(en) >= 3.0 { beal += 1; }
                } else if el.min(em).min(en) >= 3.0 && u > 1 { beal_nc.push((u, v, w)); }
            }
        }
    }
    println!("Fermat-Catalan solutions, coprime, 1/l + 1/m + 1/n < 1, up to {}:", commas(L));
    let show = |p: (u128, u32)| if p.0 > 1 { format!("{}^{}", p.0, p.1) } else { format!("{}^any", p.0) };
    for s in &fc { println!("  {} + {} = {}^{}", show(s.0), show(s.1), s.2 .0, s.2 .1); }
    println!("coprime with all exponents >= 3 (Beal): {}", beal);
    let has = beal_nc.contains(&(27, 216, 243));
    println!("not coprime, all exponents >= 3: {}  first: {:?}  also 27 + 216 = 243: {}",
        beal_nc.len(), beal_nc[0], if has { "True" } else { "False" });
    assert!(fc.len() == 5 && beal == 0 && has);

    println!("\nFrey curves");
    let (d, c4) = invariants(0, 7, -8); // y^2 = x(x - 1)(x + 8), from 1 + 8 = 9
    println!("1 + 8 = 9: y^2 = x(x-1)(x+8)  disc = {}  16(abc)^2 = {}  c4 = {}  gcd(c4, disc) = {}",
        commas(d as u128), commas(16 * 72 * 72), commas(c4 as u128), gcd(c4, d));
    assert!(d == 16 * 72 * 72 && c4 == 16 * (1 + 8 + 64)); // Tate's c4 against 16(A^2 + AB + B^2)
    for c in [81i128, 6561] { // 1 + (c-1) = c with A = -c, B = c - 1, 16 | B
        let (a_, b_) = (-c, c - 1); // y^2 = x(x - A)(x + B), rescaled to a minimal model
        let (d, c4) = invariants(1, (b_ - a_ - 1) / 4, -a_ * b_ / 16);
        let n_e = rad_trial(d as u128); // semistable, so N = rad(disc): 2 drops out unless 32 | B
        assert!(d == (a_ * b_).pow(2) / 256 && gcd(c4, d) == 1 && n_e == rad_trial((b_ * c) as u128) / if b_ % 32 == 0 { 1 } else { 2 });
        println!("1 + {} = {}: first disc 16(abc)^2 = {}, minimal disc = {} = (abc)^2/2^8\n   c4 = {}   gcd(c4, disc) = 1   conductor = {}   rad(abc) = {}   log disc/log N = {:.4}",
            b_, c, commas((16 * (b_ * c).pow(2)) as u128), commas(d as u128), commas(c4 as u128), commas(n_e), commas(rad_trial((b_ * c) as u128)), (d as f64).ln() / (n_e as f64).ln());
    }
    println!("ALL CHECKS PASS");
}
