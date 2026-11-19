// Modularity and the proof of Fermat -- the same check as the Python, in Rust.
// No crates.  Part 1 builds the Frey curve y^2 = x(x - A)(x + B), A + B = C,
// for the stand-in 3^2 + 4^2 = 5^2: its discriminant three ways, its bad primes
// two ways.  Part 2 counts points on y^2 = x^3 - x mod every odd prime below 100
// and compares them with the coefficients of a modular form of level 32.
// Part 3 counts weight-2 forms of level N by the genus formula, two ways.

fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn primes_upto(n: i64) -> Vec<i64> { (2..=n).filter(|&p| (2..p).all(|d| p % d != 0)).collect() }
fn prime_factors(n: i64) -> Vec<i64> { primes_upto(n).into_iter().filter(|p| n % p == 0).collect() }
fn rad(n: i64) -> i64 { prime_factors(n).iter().product() }
fn val(mut n: i128, p: i128) -> u32 { let mut k = 0; while n % p == 0 { n /= p; k += 1 } k }
fn md(x: i64, l: i64) -> i64 { x.rem_euclid(l) }
fn commas(n: i128) -> String {
    let s = n.to_string();
    let mut out = String::new();
    for (i, ch) in s.chars().enumerate() {
        if i > 0 && (s.len() - i) % 3 == 0 { out.push(',') }
        out.push(ch);
    }
    out
}
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

// Part 1: the Frey curve.  Roots 0, A, -B; in expanded form x^3 + a2 x^2 + a4 x.
fn disc_roots(a: i128, b: i128) -> i128 {
    let d = a.checked_mul(b).and_then(|t| t.checked_mul(a + b)).unwrap();
    16 * d.checked_mul(d).unwrap()
}
fn disc_coeffs(a: i128, b: i128) -> i128 {
    let (a2, a4) = (b - a, -a * b);
    16i128.checked_mul(a4 * a4).and_then(|t| t.checked_mul(a2 * a2 - 4 * a4)).unwrap()
}
fn disc_long(a1: i128, a2: i128, a4: i128) -> (i128, i128) {   // y^2 + a1 xy = x^3 + a2 x^2 + a4 x: Delta, c4
    let (b2, b4, b8) = (a1 * a1 + 4 * a2, 2 * a4, -a4.checked_mul(a4).unwrap());
    ((-b2 * b2).checked_mul(b8).unwrap() - 8 * b4.pow(3), b2 * b2 - 24 * b4) }
fn meeting_roots(a: i64, b: i64, l: i64) -> usize {
    let r = [0, md(a, l), md(-b, l)];
    r.iter().map(|x| r.iter().filter(|y| *y == x).count()).max().unwrap()
}
fn singular_kind(a: i64, b: i64, l: i64) -> usize {
    let (a2, a4) = (b - a, -a * b);
    for x in 0..l {
        if md(x * x * x + a2 * x * x + a4 * x, l) == 0 && md(3 * x * x + 2 * a2 * x + a4, l) == 0 {
            return if md(3 * x + a2, l) == 0 { 3 } else { 2 };
        }
    }
    1
}

fn count_points(l: i64, a2: i64, a4: i64) -> i64 {      // y^2 = x^3 + a2 x^2 + a4 x mod l
    let mut sq = vec![0i64; l as usize];
    for y in 0..l { sq[(y * y % l) as usize] += 1 }
    1 + (0..l).map(|x| sq[md(x * x * x + a2 * x * x + a4 * x, l) as usize]).sum::<i64>()
}
fn q_product(parts: &[(usize, usize)], m: usize) -> Vec<i64> {   // q * prod of (1 - q^(m n))^k
    let mut f = vec![0i64; m + 1];
    f[0] = 1;
    for &(mm, k) in parts { for _ in 0..k { for n in 1..=m / mm {
        let s = mm * n;
        for i in (s..=m).rev() { f[i] -= f[i - s] }
    } } }
    std::iter::once(0).chain(f[..m].iter().copied()).collect()
}
fn phi(n: i64) -> i64 { (1..=n).filter(|&k| gcd(k, n) == 1).count() as i64 }
fn genus_formula(n: i64) -> (i64, i64, i64, i64) {
    let ps = prime_factors(n);
    let mu = ps.iter().fold(n, |m, q| m / q * (q + 1));
    let n2 = if n % 4 == 0 { 0 } else { ps.iter().map(|&q| 1 + if q == 2 { 0 } else if q % 4 == 1 { 1 } else { -1 }).product() };
    let n3 = if n % 9 == 0 { 0 } else { ps.iter().map(|&q| 1 + if q == 3 { 0 } else if q % 3 == 1 { 1 } else { -1 }).product() };
    let cusps = (1..=n).filter(|d| n % d == 0).map(|d| phi(gcd(d, n / d))).sum();
    (mu, n2, n3, cusps)
}
fn genus_brute(n: i64) -> (i64, i64, i64) {
    let mut pairs = 0;
    for x in 0..n { for y in 0..n { if gcd(gcd(x, y), n) == 1 { pairs += 1 } } }
    let n2 = (0..n).filter(|x| (x * x + 1) % n == 0).count() as i64;
    let n3 = (0..n).filter(|x| (x * x + x + 1) % n == 0).count() as i64;
    (pairs / phi(n), n2, n3)
}
fn genus(n: i64) -> i64 {
    let (mu, n2, n3, cu) = genus_formula(n);
    let twelve_g = 12 + mu - 3 * n2 - 4 * n3 - 6 * cu;
    assert!(twelve_g % 12 == 0);
    twelve_g / 12
}

fn main() {
    let (a, b, c, p) = (3i64, 4i64, 5i64, 2u32);
    let (aa, bb) = (a.pow(p), b.pow(p));
    let d = disc_roots(aa as i128, bb as i128);
    let abc = a * b * c;
    println!("stand-in: {}^{} + {}^{} = {}^{}; Frey curve y^2 = x(x - {})(x + {})", a, p, b, p, c, p, aa, bb);
    let prd = (aa * bb * (aa + bb)) as i128;
    println!("root differences {}, {}, {}; product {}; squared {}", aa, bb, aa + bb, commas(prd), commas(prd * prd));
    println!("discriminant from the roots: {}", commas(d));
    println!("discriminant from the coefficients: {}", commas(disc_coeffs(aa as i128, bb as i128)));
    let pred = 16 * (abc as i128).pow(2 * p);
    println!("16(abc)^(2p) = 16 x {}^{} = {}", abc, 2 * p, commas(pred));
    let bad: Vec<(i64, usize)> = primes_upto(50)[1..].iter().map(|&l| (l, singular_kind(aa, bb, l))).filter(|t| t.1 > 1).collect();
    let bad_l: Vec<i64> = bad.iter().map(|t| t.0).collect();
    let meet: Vec<usize> = bad.iter().map(|t| meeting_roots(aa, bb, t.0)).collect();
    println!("odd primes below 50 where the curve is singular: {:?}", bad_l);
    println!("roots meeting there: {:?} (2 = node, 3 = cusp)", meet);
    println!("odd primes dividing abc = {}: {:?}", abc, &prime_factors(abc)[1..]);
    println!("exponents of 3 and 5 in the discriminant: {}, {}; 2p x exponent in abc: {}, {}", val(d, 3), val(d, 5),
             2 * p * val(abc as i128, 3), 2 * p * val(abc as i128, 5));
    let mut npairs = 0;
    let mut same = true;
    for x in 1..61i128 { for y in 1..61i128 { if gcd(x as i64, y as i64) == 1 {
        npairs += 1;
        same &= disc_roots(x, y) == disc_coeffs(x, y);
    } } }
    println!("Delta = 16(ABC)^2 by both formulas for all {} coprime pairs A, B up to 60: {}", commas(npairs), yn(same));

    let m = 100usize;
    let coef = q_product(&[(4, 2), (8, 2)], m);
    let odd: Vec<i64> = primes_upto(m as i64)[1..].to_vec();
    let ap = |l: i64| l + 1 - count_points(l, 0, -1);
    println!("prime l | points mod l | a_l = l + 1 - points | q^l coefficient of the form");
    for &l in &odd[..8] { println!("{:7} | {:12} | {:20} | {:27}", l, count_points(l, 0, -1), ap(l), coef[l as usize]) }
    let agree = odd.iter().filter(|&&l| ap(l) == coef[l as usize]).count();
    println!("agreement for odd primes below {}: {} of {}", m, agree, odd.len());
    let three: Vec<i64> = odd.iter().copied().filter(|l| l % 4 == 3).collect();
    println!("primes 3 mod 4 with a_l = 0: {} of {}", three.iter().filter(|&&l| ap(l) == 0).count(), three.len());
    let f15 = q_product(&[(1, 1), (3, 1), (5, 1), (15, 1)], m);
    let good: Vec<i64> = odd.iter().copied().filter(|l| abc % l != 0).collect();
    let twist = good.iter().filter(|&&l| {
        let sign = if l % 4 == 1 { 1 } else { -1 };
        l + 1 - count_points(l, bb - aa, -aa * bb) == sign * f15[l as usize]
    }).count();
    println!("stand-in: a_l = (-1)^((l-1)/2) x (q^l coefficient of the level-15 form), odd primes below {} not dividing abc: {} of {}",
             m, twist, good.len());
    println!("so the stand-in, A = {} = {} mod 4, fails the sign: level 16 x 15 = {}, not rad(abc) = {}", aa, aa.rem_euclid(4), 16 * 15, rad(abc));
    let flip = good.iter().filter(|&&l| l + 1 - count_points(l, aa - bb, -aa * bb) == f15[l as usize]).count();
    let (d15, c4f) = disc_long(1, ((aa - bb - 1) as i128).div_euclid(4), (-(aa * bb) as i128).div_euclid(16));
    println!("flipped y^2 = x(x + {})(x - {}): a_l = q^l coefficient of the level-15 form, no sign: {} of {}", aa, bb, flip, good.len());
    println!("its model at 2: discriminant {} = 3^{} x 5^{}, odd; gcd(c4, discriminant) = {}: level 15, 2 drops out",
             commas(d15), val(d15, 3), val(d15, 5), gcd(c4f as i64, d15 as i64));

    let roads = (1..=50).all(|n| { let (mu, n2, n3, _) = genus_formula(n); (mu, n2, n3) == genus_brute(n) });
    for n in [2, 11, 30, 32] {
        let (mu, n2, n3, cu) = genus_formula(n);
        println!("level {:2}: index {}, nu2 {}, nu3 {}, cusps {} -> genus {}", n, mu, n2, n3, cu, genus(n));
    }
    println!("index, nu2, nu3 by formula and by brute count agree for N = 1 to 50: {}", yn(roads));
    let zero: Vec<i64> = (1..=50).filter(|&n| genus(n) == 0).collect();
    println!("levels up to 50 with no weight-2 cusp form: {:?}", zero);
    println!("first level with a form: {}", (1..=50).find(|&n| genus(n) > 0).unwrap());

    let (a2, b2) = (81i64, 144i64);
    let (d2, c42) = disc_long(0, (b2 - a2) as i128, (-a2 * b2) as i128);
    println!("mistake 1, common factor 9^2 + 12^2 = 15^2: roots meeting mod 3 = {}, but v3(Delta) = {}, v3(c4) = {}: the equation is not minimal",
             meeting_roots(a2, b2, 3), val(d2, 3), val(c42, 3));
    let same3 = odd[1..].iter().all(|&l| count_points(l, b2 - a2, -a2 * b2) == count_points(l, bb - aa, -aa * bb));
    println!("   x = 9X, y = 27Y gives y^2 = x(x - {})(x + {}), the 3, 4, 5 curve: roots meeting mod 3 = {}, a node; same point counts mod 5 to {}: {}",
             a2 / 9, b2 / 9, meeting_roots(a2 / 9, b2 / 9, 3), odd[odd.len() - 1], yn(same3));
    println!("mistake 2, stopping at level rad(abc) = {}: genus {}, so forms exist and nothing clashes", rad(abc), genus(30));
    println!("mistake 3, discriminant taken as the level: {} instead of {}", commas(d), 16 * 15);

    assert!(d == disc_coeffs(aa as i128, bb as i128) && d == pred && d == 207360000 && same);
    assert!(bad_l == prime_factors(abc)[1..].to_vec() && bad.iter().all(|t| t.1 == 2));
    assert!(meet == bad.iter().map(|t| t.1).collect::<Vec<usize>>());
    assert!(agree == odd.len() && agree == 24 && ap(5) == -2 && twist == good.len() && twist == 22);
    assert!(roads && zero == vec![1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 13, 16, 18, 25]);
    assert!(genus(11) == 1 && genus(32) == 1 && genus(30) == 3 && meeting_roots(a2, b2, 3) == 3 && singular_kind(a2, b2, 3) == 3);
    assert!(val(d2, 3) == 16 && val(c42, 3) == 4 && d2 == 3i128.pow(12) * d && same3 && meeting_roots(a2 / 9, b2 / 9, 3) == 2);
    assert!(flip == good.len() && flip == 22 && d15 * 4096 == d && d15 == 81 * 625 && gcd(c4f as i64, d15 as i64) == 1);
    println!("ALL CHECKS PASS");
}
