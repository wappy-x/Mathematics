// Shamir secret sharing -- the check behind the card.  std only, no crates.
// Toy sizes: a field of 7919 elements holds under 13 bits, so this is INSECURE
// as a key store.  Real systems split a 256-bit key byte by byte in GF(256).
use std::collections::HashMap;

const P: i64 = 7919; // a prime, so the clock mod P is a field
const COEF: [i64; 3] = [1234, 166, 94]; // f(x) = 1234 + 166x + 94x^2; in use 166, 94 are random
const SECRET: i64 = 1234; const K: usize = 3; const N: i64 = 5; // secret, threshold, share count

fn md(a: i64, p: i64) -> i64 { a.rem_euclid(p) }

fn inv(a: i64, p: i64) -> Option<i64> { // extended Euclid: a * inv(a) = 1 mod p
    let (mut r0, mut r1, mut t0, mut t1) = (p, md(a, p), 0i64, 1i64);
    while r1 != 0 {
        let q = r0 / r1;
        (r0, r1, t0, t1) = (r1, r0 - q * r1, t1, t0 - q * t1);
    }
    if r0 == 1 { Some(md(t0, p)) } else { None } // None: no inverse exists
}

fn f_at(coef: &[i64], x: i64, p: i64) -> i64 { // Horner's rule, mod p
    coef.iter().rev().fold(0, |y, &c| md(y * x + c, p))
}

fn weights(xs: &[i64], at: i64, p: i64) -> Vec<i64> { // l_j(at) = prod (at - x_m) / (x_j - x_m)
    let mut w = Vec::new();
    for (j, &xj) in xs.iter().enumerate() {
        let (mut num, mut den) = (1i64, 1i64);
        for (m, &xm) in xs.iter().enumerate() { if m != j { num = md(num * (at - xm), p); den = md(den * (xj - xm), p); } }
        w.push(md(num * inv(den, p).unwrap(), p));
    }
    w
}

fn lagrange(pts: &[(i64, i64)], at: i64, p: i64) -> i64 { // road 1: weighted sum of share values
    let xs: Vec<i64> = pts.iter().map(|q| q.0).collect();
    let w = weights(&xs, at, p);
    md(w.iter().zip(pts).map(|(wj, q)| wj * q.1).sum::<i64>(), p)
}

fn gauss(pts: &[(i64, i64)], p: i64) -> Vec<i64> { // road 2: solve for every coefficient
    let k = pts.len();
    let mut a: Vec<Vec<i64>> = pts.iter()
        .map(|&(x, y)| (0..k).map(|e| md(x.pow(e as u32), p)).chain([md(y, p)]).collect()).collect();
    for c in 0..k {
        let piv = (c..k).find(|&r| a[r][c] != 0).unwrap();
        a.swap(c, piv);
        let iv = inv(a[c][c], p).unwrap();
        a[c] = a[c].iter().map(|v| md(v * iv, p)).collect();
        for r in 0..k {
            let fac = a[r][c];
            let pc = a[c].clone();
            if r != c && fac != 0 { a[r] = a[r].iter().zip(&pc).map(|(x, y)| md(x - fac * y, p)).collect(); }
        }
    }
    (0..k).map(|r| a[r][k]).collect()
}

fn subsets<T: Clone>(items: &[T], size: usize) -> Vec<Vec<T>> { // every choice of `size` items
    if size == 0 { return vec![vec![]]; }
    let mut out = Vec::new();
    for i in 0..items.len() {
        for rest in subsets(&items[i + 1..], size - 1) { out.push([vec![items[i].clone()], rest].concat()); }
    }
    out
}

fn commas(x: i64) -> String {
    let s = x.to_string();
    s.chars().enumerate().map(|(i, ch)| if i > 0 && (s.len() - i) % 3 == 0 { format!(",{}", ch) } else { ch.to_string() }).collect()
}

fn real_at(pts: &[(f64, f64)], x: f64) -> f64 { // the same Lagrange sum, in ordinary decimals
    let mut total = 0.0;
    for (j, &(xj, yj)) in pts.iter().enumerate() {
        let mut r = 1.0;
        for (m, &(xm, _)) in pts.iter().enumerate() { if m != j { r *= (x - xm) / (xj - xm); } }
        total += yj * r;
    }
    total
}

fn main() {
    // ---- deal the shares ----
    println!("field GF({}), toy size: {:.2} bits per share, insecure; real: a 256-bit key, byte by byte in GF(256)", P, (P as f64).log2());
    let shares: Vec<(i64, i64)> = (1..=N).map(|x| (x, f_at(&COEF, x, P))).collect();
    println!("shares: {}", shares.iter().map(|(x, y)| format!("({}, {})", x, y)).collect::<Vec<_>>().join(" "));
    assert!(shares.iter().map(|q| q.1).collect::<Vec<_>>() == vec![1494, 1942, 2578, 3402, 4414]); // worked by hand
    assert!(f_at(&COEF, 0, P) == SECRET);

    // ---- rebuild from three shares, two ways ----
    let w123 = weights(&[1, 2, 3], 0, P);
    println!("shares 1,2,3: weights {}, {}, {} (3, -3, 1); secret {}", w123[0], w123[1], w123[2], lagrange(&shares[..3], 0, P));
    assert!(w123 == vec![3, P - 3, 1] && lagrange(&shares[..3], 0, P) == SECRET);
    let t = [shares[1], shares[3], shares[4]];
    let w245 = weights(&[2, 4, 5], 0, P);
    let terms: Vec<i64> = w245.iter().zip(&t).map(|(w, q)| md(w * q.1, P)).collect();
    let tsum: i64 = terms.iter().sum();
    println!("inverses mod {}: 1/2 = {}, 1/3 = {}, 1/6 = {}", P, inv(2, P).unwrap(), inv(3, P).unwrap(), inv(6, P).unwrap());
    println!("shares 2,4,5: weights {}, {}, {}; terms {} + {} + {} = {} -> secret {}", w245[0], w245[1], w245[2], terms[0], terms[1], terms[2], tsum, tsum % P);
    assert!(3 * inv(3, P).unwrap() % P == 1 && w245.iter().sum::<i64>() % P == 1 && tsum % P == SECRET);
    let raw: Vec<String> = w245.iter().zip(&t).map(|(w, q)| commas(w * q.1)).collect();
    println!("by hand: 20/6 = 20 x {} = {}; 10/(-2) = {}; 8/3 = 8 x {} = {}; products before wrapping {}", inv(6, P).unwrap(), commas(20 * inv(6, P).unwrap()), 10 / -2, inv(3, P).unwrap(), commas(8 * inv(3, P).unwrap()), raw.join(", "));
    let (mut ok_l, mut ok_g, mut total) = (0, 0, 0);
    for size in 3..=5usize {
        for sub in subsets(&shares, size) {
            total += 1;
            if lagrange(&sub, 0, P) == SECRET { ok_l += 1; }
            if gauss(&sub, P) == [COEF.to_vec(), vec![0; size - K]].concat() { ok_g += 1; }
        }
    }
    println!("every set of 3, 4 or 5 shares: {} sets; Lagrange gives 1234 in {}, row solving gives 1234 + 166x + 94x^2 in {}", total, ok_l, ok_g);
    assert!(total == 16 && ok_l == 16 && ok_g == 16);

    // ---- two shares: every secret fits, each by exactly one polynomial ----
    let (y1, y2) = (shares[0].1, shares[1].1);
    for guess in [0i64, 4321] {
        let c = gauss(&[(0, guess), (1, y1), (2, y2)], P);
        println!("secret {} fits shares 1, 2 with f(x) = {} + {}x + {}x^2", guess, c[0], c[1], c[2]);
        assert!(f_at(&c, 1, P) == y1 && f_at(&c, 2, P) == y2 && c[0] == guess);
    }
    for (p, label) in [(P, "prime 7919"), (P + 1, "7920, not prime")] {
        let mut cnt = vec![0i64; p as usize]; // share 1 fixes a1 from a2: count the a2 that also fit share 2
        for a2 in 0..p { cnt[((2 * a2) % p) as usize] += 1; }
        let per: Vec<i64> = (0..p).map(|s| cnt[md(y2 - 2 * y1 + s, p) as usize]).collect();
        let (lo, hi) = (*per.iter().min().unwrap(), *per.iter().max().unwrap());
        println!("mod {}: secrets fitting shares 1, 2 = {} of {}; polynomials per secret {} to {}", label, per.iter().filter(|&&v| v > 0).count(), p, lo, hi);
        assert!((lo, hi) == if p == P { (1, 1) } else { (0, 2) });
    }
    println!("chance of these two shares, for every secret: 1 in {}^2 = {}", P, commas(P * P));
    let p = 11i64; // road 3: every polynomial over GF(11), every pair of x
    let mut tally: HashMap<(i64, i64, i64, i64, i64), i64> = HashMap::new();
    for s in 0..p { for a1 in 0..p { for a2 in 0..p {
        for uv in subsets(&[1i64, 2, 3, 4, 5], 2) {
            let (u, v) = (uv[0], uv[1]);
            *tally.entry((u, v, f_at(&[s, a1, a2], u, p), f_at(&[s, a1, a2], v, p), s)).or_insert(0) += 1;
        }
    } } }
    let (tlo, thi) = (*tally.values().min().unwrap(), *tally.values().max().unwrap());
    println!("clock of {}, exhaustive: {} polynomials, 10 pairs, {} cells, hits per cell {} to {}", p, p * p * p, tally.len(), tlo, thi);
    assert!(tally.len() as i64 == 10 * p * p * p && tlo == 1 && thi == 1);

    // ---- what breaks ----
    let bad = [shares[0], (2, 1943), shares[2]];
    let (s_bad, f4) = (lagrange(&bad, 0, P), lagrange(&bad, 4, P));
    println!("share 2 typed as 1943: rebuilt secret {}; predicted share 4 {}, held {}", s_bad, f4, shares[3].1);
    assert!(s_bad == SECRET - 3 && f4 != shares[3].1);
    let mut cands: Vec<i64> = Vec::new();
    for a1 in 0..1495i64 { for a2 in 0..(1495 - a1) { // share 1 fixes s
        let s = 1494 - a1 - a2;
        if s + 2 * a1 + 4 * a2 == 1942 && !cands.contains(&s) { cands.push(s); } // does share 2 fit?
    } }
    let (cmin, cmax) = (*cands.iter().min().unwrap(), *cands.iter().max().unwrap());
    let even = if cands.iter().all(|c| c % 2 == 0) { "True" } else { "False" };
    println!("integers, coefficients >= 0: shares 1, 2 leave {} secrets, {} to {}, all even: {}", cands.len(), cmin, cmax, even);
    assert!(cands.contains(&SECRET) && cands.len() == 150);
    println!("mod 7920: 1/2 exists? {}", if inv(2, P + 1).is_some() { "True" } else { "False" });
    println!("share at x = 0 hands out f(0) = {}", f_at(&COEF, 0, P));

    // ---- chart: curves through shares 1, 2 over ordinary numbers ----
    let xs: Vec<f64> = (0..13).map(|i| i as f64 / 4.0).collect();
    for h in [0i64, 1234, 2500] {
        let pts = [(0.0, h as f64), (1.0, 1494.0), (2.0, 1942.0)];
        let ys: Vec<i64> = xs.iter().map(|&x| (real_at(&pts, x) + 0.5).floor() as i64).collect();
        println!("chart, secret {}: {}", h, ys.iter().map(|y| y.to_string()).collect::<Vec<_>>().join(", "));
        assert!(ys[4] == 1494 && ys[8] == 1942 && ys[0] == h);
    }
    println!("ALL CHECKS PASS");
}
