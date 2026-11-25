// Flat, smooth and etale -- the same check as the Python, in Rust.  No crates.
// A polynomial is a list of (exponent vector, integer).  Ranks are exact:
// integer row reduction in i128 with checked arithmetic, each new row divided by
// its gcd.  Roads: the Hilbert function by rank, by standard monomials and by
// formula; Tor_1 by rank; etale points by the Jacobian against brute-force root
// counts; Hensel lifting against enumeration.
use std::collections::HashMap;
type Poly = Vec<(Vec<usize>, i128)>;
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn rank(rows: &[Vec<i128>]) -> usize {
    let mut m: Vec<Vec<i128>> = rows.to_vec();
    let mut rk = 0;
    let ncol = if m.is_empty() { 0 } else { m[0].len() };
    for col in 0..ncol {
        let piv = match (rk..m.len()).find(|&i| m[i][col] != 0) { Some(i) => i, None => continue };
        m.swap(rk, piv);
        for i in rk + 1..m.len() {
            let row: Vec<i128> = (0..m[i].len()).map(|j| {
                m[rk][col].checked_mul(m[i][j]).unwrap().checked_sub(m[i][col].checked_mul(m[rk][j]).unwrap()).unwrap()
            }).collect();
            let g = row.iter().fold(0, |g, &v| gcd(g, v));
            m[i] = if g != 0 { row.iter().map(|v| v / g).collect() } else { row };
        }
        rk += 1;
    }
    rk
}
fn monos(k: usize, n: usize, upto: bool) -> Vec<Vec<usize>> {  // exponent vectors in k variables
    if k == 1 { return if upto { (0..=n).map(|d| vec![d]).collect() } else { vec![vec![n]] }; }
    let mut out = vec![];
    for a in 0..=n { for r in monos(k - 1, n - a, upto) { let mut e = vec![a]; e.extend(r); out.push(e) } }
    out
}
fn times(g: &Poly, m: &[usize]) -> Poly {                     // g times the monomial m
    g.iter().map(|(e, c)| (e.iter().zip(m).map(|(a, b)| a + b).collect(), *c)).collect()
}
fn mult_rows(gs: &[Poly], src: &[Vec<usize>], dst: &[Vec<usize>]) -> Vec<Vec<i128>> {
    let pos: HashMap<&Vec<usize>, usize> = dst.iter().enumerate().map(|(i, e)| (e, i)).collect();
    src.iter().map(|m| {
        let mut row = vec![0i128; dst.len() * gs.len()];
        for (block, g) in gs.iter().enumerate() {
            for (e, c) in times(g, m) { row[block * dst.len() + pos[&e]] += c }
        }
        row
    }).collect()
}

fn hf(g: &Poly, k: usize, n: usize, deg: usize) -> usize {   // Hilbert function of k[vars]/(g)
    if n < deg { return monos(k, n, false).len(); }
    monos(k, n, false).len() - rank(&mult_rows(&[g.clone()], &monos(k, n - deg, false), &monos(k, n, false)))
}

fn inv(a: i64, m: i64) -> i64 {                               // inverse mod m by Euclid
    let (mut r0, mut r1, mut s0, mut s1) = (a.rem_euclid(m), m, 1i64, 0i64);
    while r1 != 0 { let q = r0 / r1; (r0, r1) = (r1, r0 - q * r1); (s0, s1) = (s1, s0 - q * s1); }
    assert!(r0 == 1);
    s0.rem_euclid(m)
}

fn main() {
    println!("1. the family xy = t z^2 in P^2 over the t-line; field Q; HF for n = 0..6");
    let mut fam: Vec<Vec<usize>> = vec![];
    for t in [1i128, -1, 5, 0] {
        let g: Poly = vec![(vec![1, 1, 0], 1), (vec![0, 0, 2], -t)];
        let h: Vec<usize> = (0..7).map(|n| hf(&g, 3, n, 2)).collect();
        println!("   t = {:2}: by rank {:?}", t, h);
        fam.push(h);
    }
    let std: Vec<usize> = (0..7).map(|n| monos(3, n, false).iter().filter(|e| !(e[0] > 0 && e[1] > 0)).count()).collect();
    let formula: Vec<usize> = (0..7).map(|n| 2 * n + 1).collect();
    println!("   standard monomials, not divisible by xy: {:?}; formula 2n + 1: {:?}", std, formula);
    let n_ = 4;
    let (v, v2) = (monos(2, n_, true), monos(2, n_ + 2, true));
    for c in [0i128, 1, -1] {
        let r = rank(&mult_rows(&[vec![(vec![1, 1], 1), (vec![0, 0], -c)]], &v, &v2));
        println!("   Tor_1 over Q[t] at t = {:2}: times (xy - c) on {} monomials, rank {}, kernel {}", c, v.len(), r, v.len() - r); assert!(r == v.len());
    }
    println!("2. blowing up the plane at the origin, chart y = x t: B = Q[x, t], y -> x t");
    let v3 = monos(2, n_ + 3, true);
    let mut rows = mult_rows(&[vec![(vec![1, 0], 1)]], &v, &v3);
    rows.extend(mult_rows(&[vec![(vec![1, 1], 1)]], &v, &v3));
    let d2 = rank(&rows);
    let d1 = rank(&mult_rows(&[vec![(vec![1, 1], -1)], vec![(vec![1, 0], 1)]], &monos(2, n_ - 2, true), &v));
    let ker = 2 * v.len() - d2;
    println!("   Koszul on (x, x t), degree <= {}: kernel {}, boundaries {}, Tor_1 piece {}", n_, ker, d1, ker - d1);
    let mut wit: HashMap<Vec<usize>, i128> = HashMap::new();
    for (e, c) in times(&vec![(vec![1, 0], 1)], &[0, 1]) { *wit.entry(e).or_insert(0) -= c }   // x times -t
    for (e, c) in times(&vec![(vec![1, 1], 1)], &[0, 0]) { *wit.entry(e).or_insert(0) += c }   // (x t) times 1
    println!("   witness (-t, 1): x(-t) + (x t)(1) = {}; second entry 1 is not a multiple of x",
             if wit.values().all(|&c| c == 0) { "0" } else { "not 0" });
    let mut fib: Vec<Vec<usize>> = vec![];
    for (a, b) in [(1i128, 0i128), (2, 3), (0, 0)] {
        let h: Vec<usize> = (0..5).map(|n| hf(&vec![(vec![1, 0], -b), (vec![0, 1], a)], 2, n, 1)).collect();
        println!("   fibre over {:?}: HF {:?}", (a, b), h);
        fib.push(h);
    }
    let p: i64 = 7;
    let mut p1: Vec<(i64, i64)> = (0..p).map(|v| (1, v)).collect();
    p1.push((0, 1));
    let sizes: Vec<usize> = (0..p).flat_map(|a| (0..p).map(move |b| (a, b)))
        .map(|(a, b)| p1.iter().filter(|&&(u, v)| (a * v - b * u).rem_euclid(p) == 0).count()).collect();
    let (s1, s8) = (sizes.iter().filter(|&&s| s == 1).count(), sizes.iter().filter(|&&s| s == 8).count());
    println!("   over F_7: fibres of size 1: {}, of size 8: {}, total {}", s1, s8, sizes.iter().sum::<usize>());
    println!("3. relative Jacobian of xy - t over the t-line, over F_7");
    let bad: Vec<(i64, i64)> = (0..p).flat_map(|x| (0..p).map(move |y| (x, y))).filter(|&(x, y)| rank(&[vec![(y % p) as i128, (x % p) as i128]]) == 0).collect();
    let mut om: Vec<usize> = (0..p).flat_map(|x| (0..p).map(move |y| (x, y)))
        .map(|(x, y)| 2 - rank(&[vec![(y % p) as i128, (x % p) as i128]])).collect();
    om.sort(); om.dedup();
    println!("   points with (y, x) = (0, 0): {} of {}, at {:?} in the fibre t = 0; Omega ranks met {:?}", bad.len(), p * p, bad[0], om);
    let tot = (0..p).flat_map(|x| (0..p).map(move |y| (x, y))).filter(|&(x, y)| rank(&[vec![y as i128, x as i128, (-1i64).rem_euclid(p) as i128]]) == 0).count();
    println!("   total space, Jacobian (y, x, -1): singular points {}", tot);
    println!("4. x -> u = x^2: B = A[x]/(x^2 - u), basis 1, x; Omega = B/(2x)");
    let roots7: Vec<usize> = (0..p).map(|c| (0..p).filter(|x| (x * x - c).rem_euclid(p) == 0).count()).collect();
    let f49: Vec<(i64, i64)> = (0..p).flat_map(|a| (0..p).map(move |b| (a, b))).collect();   // a + b i, i^2 = -1
    let sq = |z: (i64, i64)| ((z.0 * z.0 - z.1 * z.1).rem_euclid(p), 2 * z.0 * z.1 % p);
    let roots49: Vec<usize> = (0..p).map(|c| f49.iter().filter(|&&z| sq(z) == (c, 0)).count()).collect();
    let mult49: Vec<usize> = (0..p).map(|c| f49.iter().filter(|&&z| sq(z) == (c, 0))
        .map(|&z| 1 + (2 * z.0 % p == 0 && 2 * z.1 % p == 0) as usize).sum()).collect();   // 2x = 0: double
    println!("   roots of x^2 = c, c = 0..6: in F_7 {:?}; in F_49 {:?}; with multiplicity {:?}", roots7, roots49, mult49);
    let et7 = (0..p).filter(|x| 2 * x % p != 0).count();
    println!("   etale points of X(F_7), where 2x != 0: {} of {}; only x = 0 fails", et7, p);
    let r2: Vec<Vec<i64>> = (0..2).map(|c| (0..2).filter(|x| (x * x - c) % 2 == 0).collect()).collect();
    let et2 = (0..2i64).filter(|x| 2 * x % 2 != 0).count();
    println!("   over F_2: roots per c {:?}, one each, but 2x = 0: etale points {} of 2", r2, et2);
    println!("5. Spec Z[i] -> Spec Z: Z[i] = Z[x]/(x^2 + 1), Jacobian 2x, discriminant -4");
    for q in [2i64, 3, 5, 13, 29] {
        let rs: Vec<i64> = (0..q).filter(|x| (x * x + 1) % q == 0).collect();
        println!("   p = {:2}: roots of x^2 + 1 {:?}; 2x = 0 at a root: {}", q, rs, if rs.iter().any(|x| 2 * x % q == 0) { "yes" } else { "no" });
    }
    let primes: Vec<i64> = (2..1000).filter(|&q| (2..).take_while(|d| d * d <= q).all(|d| q % d != 0)).collect();
    let ram: Vec<i64> = primes.iter().cloned().filter(|&q| (0..q).any(|x| (x * x + 1) % q == 0 && 2 * x % q == 0)).collect();
    let div4: Vec<i64> = primes.iter().cloned().filter(|q| 4 % q == 0).collect();
    println!("   of {} primes below 1000, not etale above: {:?}; dividing -4: {:?}", primes.len(), ram, div4);
    let m2i: Vec<(i64, i64)> = [(1i64, 0i64), (0, 1)].iter().map(|&(a, b)| (a * 0 - b * 2, a * 2 + b * 0)).collect();
    println!("   Omega = Z[i]/(2i): 2i sends 1, i to {:?}; Omega has {} elements, the determinant", m2i, m2i[0].0 * m2i[1].1 - m2i[0].1 * m2i[1].0);
    let (mut x, mut lifts) = (2i64, vec![2i64]);
    for k in 2..7u32 {
        let m = 5i64.pow(k);
        x = (x - (x * x + 1) * inv(2 * x, m)).rem_euclid(m);
        lifts.push(x);
    }
    let brute5: Vec<usize> = (1..5u32).map(|k| (0..5i64.pow(k)).filter(|y| (y * y + 1) % 5i64.pow(k) == 0).count()).collect();
    let brute2: Vec<usize> = (1..5u32).map(|k| (0..2i64.pow(k)).filter(|y| (y * y + 1) % 2i64.pow(k) == 0).count()).collect();
    println!("   Hensel, x^2 = -1 mod 5^k, k = 1..6: {:?}; solutions k = 1..4 by search {:?}", lifts, brute5);
    println!("   mod 2^k, k = 1..4: solutions {:?}; 2x is never a unit mod 2", brute2);
    println!("6. y^2 = x^3 - x -> x-line: not etale where 2y = 0");
    let hinf = |w: i64, yw: i64| yw * yw - (w - w * w * w);      // chart w = 1/x, Y = y w^2: Y^2 = w - w^3
    let mut nes: Vec<(usize, usize)> = vec![];
    for q in [7i64, 11, 13] {
        let pts: Vec<(i64, i64)> = (0..q).flat_map(|a| (0..q).map(move |b| (a, b)))
            .filter(|&(a, b)| (b * b - a * a * a + a).rem_euclid(q) == 0).collect();
        let inf: Vec<i64> = (0..q).filter(|&yw| hinf(0, yw).rem_euclid(q) == 0).collect();   // the fibre over w = 0: x at infinity
        let (ne, ni) = (pts.iter().filter(|&&(_, b)| 2 * b % q == 0).count(), inf.iter().filter(|&&yw| 2 * yw % q == 0).count());
        println!("   over F_{}: {} affine points, {} not etale; chart w = 1/x, over w = 0: {} point, {} not etale", q, pts.len(), ne, inf.len(), ni);
        nes.push((ne, ni));
    }
    let br = (nes[0].0 + nes[0].1) as i64;                   // x = -1, 0, 1 and the point at infinity
    let g = (2 * (0 - 1) * 2 + br + 2) / 2;
    println!("   Riemann-Hurwitz: 2g - 2 = 2(-2) + {}, g = {}; plane formula (3 - 1)(3 - 2)/2 = {}", br, g, (3 - 1) * (3 - 2) / 2);
    println!("   forgetting infinity: 2g - 2 = 2(-2) + {} = {}, odd, so no whole g", br - 1, 2 * -2 + br - 1);
    let (v1, v4) = (1f64.sqrt(), 0.25f64.sqrt());             // vertex of xy = t at (sqrt t, sqrt t)
    println!("figure, xy = t for t = 1, 1/4, 0, -1/4: vertices ({:.1}, {:.1}), ({:.1}, {:.1}), the axes, ({:.1}, {:.1}); box -2.5..2.5", v1, v1, v4, v4, v4, -v4);
    assert!(fam.iter().all(|h| *h == std && std == formula));                 // rank vs count vs formula
    assert!(ker - d1 == n_ && fib[2] == (1..6).collect::<Vec<usize>>() && fib[0] == vec![1; 5]);
    assert!(s8 == 1 && sizes.iter().sum::<usize>() == (p * p - 1 + p + 1) as usize);   // one fibre is a line
    assert!(mult49 == vec![2; 7] && roots7 == vec![1, 2, 2, 0, 2, 0, 0] && et2 == 0);   // constant length 2
    assert!(ram == vec![2] && brute5 == vec![2; 4] && lifts.iter().enumerate().all(|(k, y)| (y * y + 1) % 5i64.pow(k as u32 + 1) == 0));
    assert!(brute2 == vec![1, 0, 0, 0] && bad == vec![(0, 0)] && om == vec![1, 2] && tot == 0 && nes == vec![(3, 1); 3] && g == (3 - 1) * (3 - 2) / 2);
    println!("ALL CHECKS PASS");
}
