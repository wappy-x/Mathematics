// The p-adic numbers and Hensel's lemma -- the same check as the Python, in
// Rust.  No crates.  Root 2 in the 7-adics by three roads: road 1 lifts a root
// one power of 7 at a time (Hensel's step); road 2 tries every residue mod 7^k;
// road 3 runs Newton's step on exact fractions (i128 pairs, checked) and reads
// each one mod 7^k and as a decimal.  Then the failures, distances and Ostrowski.
const P: i128 = 7;

fn v(mut n: i128, p: i128) -> u32 {  // p-adic valuation: how many times p divides n
    let mut k = 0;
    while n % p == 0 { n /= p; k += 1; }
    k
}

fn md(a: i128, m: i128) -> i128 { ((a % m) + m) % m }

fn inv(a: i128, m: i128) -> i128 {   // inverse of a mod m, extended Euclid
    let (mut r0, mut r1, mut s0, mut s1) = (md(a, m), m, 1i128, 0i128);
    while r1 != 0 {
        let q = r0.div_euclid(r1);
        (r0, r1, s0, s1) = (r1, r0 - q * r1, s1, s0 - q * s1);
    }
    assert!(r0 == 1);
    md(s0, m)
}

fn size(n: i128, p: i128) -> String { // |n|_p written as a fraction
    if n == 0 { "0".to_string() } else if v(n, p) > 0 { format!("1/{}", p.pow(v(n, p))) } else { "1".to_string() }
}

fn roots(c: i128, p: i128, k: u32) -> Vec<i128> { // road 2: every x mod p^k with x^2 = c
    let m = p.pow(k);
    (0..m).filter(|&x| md(x * x - c, m) == 0).collect()
}

fn lift(mut a: i128, steps: u32, show: bool) -> Vec<i128> { // road 1: root mod 7 -> mod 7^(steps+1)
    let (mut out, mut pk) = (vec![a], P);
    for k in 1..=steps {
        let fa = a.checked_mul(a).unwrap() - 2;
        let (c, d) = (fa.div_euclid(pk), inv(2 * a, P));
        let t = md(-c * d, P);
        if show {
            println!("lift {}: a = {}, f(a) = {} = 7^{} * {}, c mod 7 = {}, f'(a) = {} = {} mod 7, inverse {}, t = {}, new root {} mod {}",
                k, a, fa, k, c, md(c, P), 2 * a, md(2 * a, P), d, t, a + t * pk, pk * P);
        }
        a += t * pk;
        pk *= P;
        out.push(a);
    }
    out
}

fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }

fn list(xs: &[i128]) -> String {
    format!("[{}]", xs.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", "))
}

fn commas(n: i128) -> String {
    let s = n.to_string();
    let mut out = String::new();
    for (i, ch) in s.chars().enumerate() {
        if i > 0 && (s.len() - i) % 3 == 0 { out.push(','); }
        out.push(ch);
    }
    out
}

fn main() {
    let mut sq: Vec<i128> = (1..P).map(|x| x * x % P).collect();
    sq.sort();
    sq.dedup();
    println!("f(x) = x^2 - 2, p = 7; roots mod 7: {} ; nonzero squares mod 7: {}", list(&roots(2, P, 1)), list(&sq));
    let up = lift(3, 15, false);
    lift(3, 3, true);
    let down = lift(4, 7, false);
    println!("lifts of 3, one power at a time: {}", list(&up[..8]));
    println!("lifts of 4, one power at a time: {}", list(&down));
    let digits: Vec<i128> = (0..16).map(|i| (up[15] / P.pow(i)) % P).collect();
    println!("7-adic digits of the root above 3, lowest first: {}", list(&digits));
    let dd: Vec<i128> = (0..8).map(|i| (down[7] / P.pow(i)) % P).collect();
    println!("7-adic digits of the root above 4, lowest first: {}", list(&dd));
    for k in 1..7u32 {                // road 2 against road 1
        let r = roots(2, P, k);
        let (a, b) = (up[k as usize - 1], down[k as usize - 1]);
        println!("mod 7^{} = {}: {} roots by search, lift of 3 is {}, lift of 4 is {}", k, P.pow(k), r.len(), a, b);
        assert!(r == vec![a.min(b), a.max(b)]);
    }
    let (mut xn, mut xd) = (3i128, 1i128); // road 3: Newton's step on exact fractions
    let mut newton_v = vec![];
    for n in 0..5u32 {
        let m = P.pow(1 << n);
        let res = md(md(xn, m) * inv(xd, m), m);
        newton_v.push(v(xn.checked_mul(xn).unwrap() - 2 * xd.checked_mul(xd).unwrap(), P));
        let shown = if xd == 1 { xn.to_string() } else { format!("{}/{}", xn, xd) };
        println!("Newton x_{} = {} = {:.6}; mod 7^{} it is {}; v_7(x^2 - 2) = {}", n, shown, xn as f64 / xd as f64, 1 << n, res, newton_v[n as usize]);
        assert!(res == md(up[(1 << n) - 1], m));
        let (nn, nd) = (xn.checked_mul(xn).unwrap() + 2 * xd.checked_mul(xd).unwrap(), 2 * xn.checked_mul(xd).unwrap());
        let g = gcd(nn, nd);
        xn = nn / g;
        xd = nd / g;
    }
    let xf = xn as f64 / xd as f64;
    assert!((xf * xf - 2.0).abs() < 1e-12);
    assert!(newton_v == vec![1, 2, 4, 8, 16]);
    let lin: Vec<i128> = up[..5].iter().map(|&a| v(a * a - 2, P) as i128).collect();
    let nv: Vec<i128> = newton_v.iter().map(|&x| x as i128).collect();
    println!("correct 7-adic digits after each step: one power at a time {}; Newton {}", list(&lin), list(&nv));
    assert!(up[..4] == [3, 10, 108, 2166]);
    assert!(up.iter().enumerate().all(|(k, &a)| md(a * a - 2, P.pow(k as u32 + 1)) == 0));
    println!("7-adic distances: |10 - 3| = {}, |108 - 10| = {}, |108 - 3| = {}; |108|_7 = {}, |1/7|_7 = {}",
             size(7, P), size(98, P), size(105, P), size(108, P), P.pow(v(7, P) - v(1, P)));
    println!("|f(a)|_7 for 3, 10, 108: {}, {}, {}; f(108) = {}", size(7, P), size(98, P), size(108 * 108 - 2, P), 108 * 108 - 2);
    let (mut bad7, mut bad_abs, mut pairs) = (0i128, 0i128, 0i128);
    for x1 in -300i128..301 {         // the strong triangle rule on 600 x 600 pairs
        for y1 in -300i128..301 {
            if x1 != 0 && y1 != 0 && x1 + y1 != 0 {
                pairs += 1;
                bad7 += (v(x1 + y1, P) < v(x1, P).min(v(y1, P))) as i128;
                bad_abs += ((x1 + y1).abs() > x1.abs().max(y1.abs())) as i128;
            }
        }
    }
    println!("strong triangle rule broken, of {} pairs: 7-adic {}, ordinary size {}", commas(pairs), bad7, commas(bad_abs));
    assert!(bad7 == 0);
    assert!(bad_abs > 0);
    let n = 108i128 * 108 - 2;
    let places: Vec<i128> = (2..=n).filter(|&p| n % p == 0 && (2..p).take_while(|q| q * q <= p).all(|q| p % q != 0)).collect();
    let (mut pn, mut pd) = (n, 1i128);
    for &p in &places { pd *= p.pow(v(n, p)); }
    let g = gcd(pn, pd);
    pn /= g;
    pd /= g;
    let sizes: Vec<String> = places.iter().map(|&p| size(n, p)).collect();
    let prod = if pd == 1 { pn.to_string() } else { format!("{}/{}", pn, pd) };
    println!("product formula for {}: |n| = {}, primes {}, p-adic sizes {}, product {}", n, n, list(&places), sizes.join(", "), prod);
    assert!(pn == 1 && pd == 1);
    println!("mistake 1, no root mod 7 to start: x^2 = 3 mod 7 has roots {}", list(&roots(3, P, 1)));
    println!("mistake 2, f'(a) divisible by 7: x^2 = 7 has roots {} mod 7 and {} mod 49", list(&roots(7, P, 1)), list(&roots(7, P, 2)));
    let c17: Vec<i128> = (1..7).map(|k| roots(17, 2, k).len() as i128).collect();
    println!("mistake 3, p = 2 and x^2 = 17: roots mod 2, 4, ..., 64 number {}", list(&c17));
    let (f1, d1) = (v(1 - 17, 2), v(2 * 1, 2)); // the sharper test at a = 1: |f(1)|_2 < |f'(1)|_2^2
    println!("sharper test for x^2 = 17 at a = 1: |f(1)|_2 = 1/{}, |f'(1)|_2^2 = 1/{}, passes: {}",
             2i128.pow(f1), 2i128.pow(2 * d1), if f1 > 2 * d1 { "yes" } else { "no" });
    let gaps: Vec<i128> = (0..3).map(|k| up[k + 1] - up[k]).collect();
    let gs: Vec<String> = gaps.iter().map(|&g| size(g, P)).collect();
    println!("mistake 4, ordinary size: gaps {} grow; 7-adic sizes {} shrink", list(&gaps), gs.join(", "));
    assert!(roots(3, P, 1).is_empty() && roots(7, P, 2).is_empty());
    assert!(c17 == vec![1, 2, 4, 4, 4, 4]);
    assert!(f1 > 2 * d1);             // yet the sharper lemma puts sqrt 17 in Q_2
    let mut h = vec![3i128];
    for k in 1..3u32 {                // house example: x^2 + 5 = 0 has a root mod 7 that lifts
        let a = *h.last().unwrap();
        let c = (a * a + 5) / P.pow(k);
        h.push(a + md(-c * inv(2 * a, P), P) * P.pow(k));
    }
    let hv: Vec<i128> = h.iter().map(|&a| a * a + 5).collect();
    println!("house example, x^2 = -5: lifts of 3 are {}; a^2 + 5 = {}", list(&h), list(&hv));
    assert!(roots(-5, P, 3).contains(&h[2]) && roots(-5, P, 2).contains(&h[1]));
    println!("ALL CHECKS PASS");
}
