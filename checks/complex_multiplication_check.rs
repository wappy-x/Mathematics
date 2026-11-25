// Complex multiplication -- the same check as the Python, in Rust.  No crates.
// The curve E is y^2 = x^3 - x.  A point mod p is Some((x, y)); None is O.
// Road 1 counts the points mod p: square every y, then look up each x.
// Road 2 adds up Euler's square test over x, one question per x.
// Road 3 reads a_p from p = a^2 + b^2 alone, with no counting.
// Road 4 tests the Frobenius claim: the Gaussian integer a + b[i] fixes every
// point mod p, and no b + a[i] does.  The map [i](x, y) = (-x, iy) is tested as a map of the group.
// Lattice j-values come from q-series in floats, by two separate series.
type Pt = Option<(i64, i64)>;

fn power(a: i64, mut k: i64, p: i64) -> i64 {       // square-and-multiply, mod p
    let (mut out, mut a) = (1, a.rem_euclid(p));
    while k > 0 { if k & 1 == 1 { out = out * a % p } a = a * a % p; k >>= 1 }
    out
}

fn add(pp: Pt, qq: Pt, p: i64) -> Pt {              // chord and tangent on y^2 = x^3 - x, mod p
    let ((x1, y1), (x2, y2)) = match (pp, qq) { (None, _) => return qq, (_, None) => return pp, (Some(a), Some(b)) => (a, b) };
    if x1 == x2 && (y1 + y2) % p == 0 { return None }
    let m = if pp == qq { (3 * x1 * x1 - 1).rem_euclid(p) * power(2 * y1, p - 2, p) % p }
            else { (y2 - y1).rem_euclid(p) * power(x2 - x1, p - 2, p) % p };
    let x3 = (m * m - x1 - x2).rem_euclid(p);
    Some((x3, (m * (x1 - x3) - y1).rem_euclid(p)))
}

fn neg(pp: Pt, p: i64) -> Pt { pp.map(|(x, y)| (x, (-y).rem_euclid(p))) }
fn mul(n: i64, pp: Pt, p: i64) -> Pt {              // n times P by repeated adding
    let (n, pp) = if n < 0 { (-n, neg(pp, p)) } else { (n, pp) };
    let mut r = None;
    for _ in 0..n { r = add(r, pp, p) }
    r
}

fn imap(i: i64, pp: Pt, p: i64) -> Pt { pp.map(|(x, y)| ((-x).rem_euclid(p), i * y % p)) }
fn f(x: i64, a: i64, b: i64, p: i64) -> i64 { (x * x % p * x + a * x + b).rem_euclid(p) }

fn points(p: i64, a: i64, b: i64) -> Vec<Pt> {     // road 1: O, then each x with every y
    let mut roots = vec![Vec::new(); p as usize];
    for y in 0..p { roots[(y * y % p) as usize].push(y) }
    let mut out = vec![None];
    for x in 0..p { for &y in &roots[f(x, a, b, p) as usize] { out.push(Some((x, y))) } }
    out
}

fn legendre(v: i64, p: i64) -> i64 { let t = power(v, (p - 1) / 2, p); if t == p - 1 { -1 } else { t } }
fn ap_euler(p: i64, a: i64, b: i64) -> i64 { -(0..p).map(|x| legendre(f(x, a, b, p), p)).sum::<i64>() }
fn isqrt(n: i64) -> i64 { let mut r = (n as f64).sqrt() as i64; while r * r > n { r -= 1 } while (r + 1) * (r + 1) <= n { r += 1 } r }

fn two_squares(p: i64) -> (i64, i64) {              // a odd, b even, a + b = 1 mod 4
    let b = (0..).step_by(2).find(|b| { let a = isqrt(p - b * b); a * a == p - b * b }).unwrap();
    let a = isqrt(p - b * b);
    (if (a + b) % 4 == 1 { a } else { -a }, b)
}

fn ap_cm(p: i64) -> i64 { if p % 4 == 3 { 0 } else { 2 * two_squares(p).0 } }
fn sqrt_m1(p: i64) -> i64 { (0..p).find(|t| t * t % p == p - 1).unwrap() }
fn pt(pp: Pt) -> String { match pp { None => "O".to_string(), Some((x, y)) => format!("({}, {})", x, y) } }
fn list(v: &[i64]) -> String { format!("[{}]", v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ")) }
fn dict(ps: &[i64], a: i64, b: i64) -> String {
    format!("{{{}}}", ps.iter().map(|&p| format!("{}: {}", p, ap_euler(p, a, b))).collect::<Vec<_>>().join(", "))
}
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }

fn j_tau(t: f64) -> (f64, f64) {                    // tau = i t; road A and road B
    let q = (-2.0 * std::f64::consts::PI * t).exp();
    let (mut e4, mut e6, mut dprod, mut qn) = (1.0f64, 1.0f64, q, 1.0f64);
    for n in 1..40i64 {
        qn *= q;
        e4 += 240.0 * (1..=n).filter(|d| n % d == 0).map(|d| d * d * d).sum::<i64>() as f64 * qn;
        e6 -= 504.0 * (1..=n).filter(|d| n % d == 0).map(|d| d * d * d * d * d).sum::<i64>() as f64 * qn;
        let fq = 1.0 - qn;
        for _ in 0..24 { dprod *= fq }
    }
    (1728.0 * e4.powf(3.0) / (e4.powf(3.0) - e6 * e6), e4.powf(3.0) / dprod)
}

fn class_number(d: i64) -> i64 {                    // reduced primitive forms of discriminant d
    let mut h = 0;
    for a in 1..=isqrt(-d / 3) {
        for b in (-a + 1)..=a {
            if (b * b - d) % (4 * a) != 0 { continue }
            let c = (b * b - d) / (4 * a);
            if c >= a && !(b < 0 && c == a) && gcd(gcd(a, b), c) == 1 { h += 1 }
        }
    }
    h
}

fn main() {
    let primes: Vec<i64> = (3..1000).filter(|&p| (2..=isqrt(p)).all(|d| p % d != 0)).collect();
    println!("E: y^2 = x^3 - x, Delta = {}  [i](x, y) = (-x, iy): (iy)^2 = -y^2 = -(x^3 - x) = (-x)^3 - (-x)", -16 * (4 * (-1i64).pow(3) + 27 * 0i64.pow(2)));
    for &p in &[7i64, 11, 13, 17, 29] {
        let n = points(p, -1, 0).len() as i64;
        if p % 4 == 3 { println!("p = {}, 3 mod 4: {} points, a_{} = {}", p, n, p, p + 1 - n) } else {
            let (a, b) = two_squares(p);
            println!("p = {} = {}^2 + {}^2, a = {}, a + b = {} = {} mod 4: {} points, a_{} = {} = 2a",
                     p, a.abs(), b, a, a + b, (a + b).rem_euclid(4), n, p, p + 1 - n);
        }
    }
    println!("p = 7, square test of x^3 - x for x = 1..6: {}", list(&(1..7).map(|x| legendre(f(x, -1, 0, 7), 7)).collect::<Vec<_>>()));
    for &p in &primes {                              // roads 1, 2 and 3 agree at every odd prime below 1000
        let n = points(p, -1, 0).len() as i64;
        assert!(n == p + 1 - ap_euler(p, -1, 0) && ap_euler(p, -1, 0) == ap_cm(p));
        assert!(p % 4 == 3 || n % 8 == 0);
    }
    println!("roads 1, 2, 3 agree at all {} odd primes below 1000; 8 divides the count at all {} primes = 1 mod 4",
             primes.len(), primes.iter().filter(|&&p| p % 4 == 1).count());
    println!("chart, p: {}", list(&primes[..18]));
    println!("chart, a_p: {}", list(&primes[..18].iter().map(|&p| ap_cm(p)).collect::<Vec<_>>()));
    let (p, i) = (13, sqrt_m1(13));
    let e = points(13, -1, 0);
    println!("figure, E mod 13 (i = {}): {}", i, e[1..].iter().map(|&q| pt(q)).collect::<Vec<_>>().join(" "));
    let mut orbit = vec![Some((5i64, 4i64))];
    while orbit.len() < 4 { let last = *orbit.last().unwrap(); orbit.push(imap(i, last, p)) }
    println!("figure, [i] cycle: {} -> {}", orbit.iter().map(|&q| pt(q)).collect::<Vec<_>>().join(" -> "), pt(imap(i, orbit[3], p)));
    assert!(e.iter().all(|&q| e.contains(&imap(i, q, p)) && imap(i, imap(i, q, p), p) == neg(q, p)));
    assert!(e.iter().all(|&a| e.iter().all(|&b| imap(i, add(a, b, p), p) == add(imap(i, a, p), imap(i, b, p), p))));
    assert!(e.iter().all(|&q| { let r = add(q, imap(i, q, p), p); add(r, neg(imap(i, r, p), p), p) == mul(2, q, p) }));
    let ker: Vec<Pt> = e.iter().cloned().filter(|&q| add(q, imap(i, q, p), p).is_none()).collect();
    println!("mod 13: [i] keeps the curve, [i][i] = [-1], [i](P + Q) = [i]P + [i]Q for all 64 pairs, (1 - [i])(1 + [i]) = [2]; kernel of 1 + [i]: {}",
             ker.iter().map(|&q| pt(q)).collect::<Vec<_>>().join(", "));
    let qq = Some((i, (1 - i).rem_euclid(p)));
    println!("order-4 point Q = (i, 1 - i) = {}: 2Q = {}, 4Q = {}", pt(qq), pt(mul(2, qq, p)), pt(mul(4, qq, p)));
    assert!(e.contains(&qq) && mul(2, qq, p) == Some((0, 0)) && mul(4, qq, p).is_none());
    let (p29, i29) = (29, sqrt_m1(29));
    let e29 = points(29, -1, 0);
    let k5: Vec<usize> = [1i64, -1].iter().map(|&s| e29.iter().filter(|&&q| add(mul(2, q, p29), mul(s, imap(i29, q, p29), p29), p29).is_none()).count()).collect();
    println!("mod 29 (i = {}, {} points): kernel of 2 + [i] has {}, of 2 - [i] has {}", i29, e29.len(), k5[0], k5[1]);
    assert!(k5.iter().min() == Some(&1) && k5.iter().max() == Some(&5));
    for &p in primes.iter().filter(|&&q| q % 4 == 1 && q < 100) {   // road 4: Frobenius = a + b[i], never b + a[i]
        let (i, (a, b), e) = (sqrt_m1(p), two_squares(p), points(p, -1, 0));
        let mut fix = Vec::new();
        for &(u, v) in &[(a, b), (b, a)] { for &s in &[u, -u] { for &t in &[v, -v] {
            if e.iter().all(|&q| add(mul(s, q, p), mul(t, imap(i, q, p), p), p) == q) { fix.push((s, t)) }
        } } }
        assert!(!fix.is_empty() && fix.iter().all(|&(s, _)| s == a) && fix.len() <= 2);
        if p == 13 || p == 29 {
            println!("Frobenius mod {} (i = {}): of the eight a + b[i] and b + a[i] with a, b = {}, {} up to sign, those fixing all {} points: {}",
                     p, i, a.abs(), b, e.len(), fix.iter().map(|&(s, t)| format!("{} + ({})[i]", s, t)).collect::<Vec<_>>().join(", "));
        }
    }
    println!("house curve y^2 = x^3 - 2: {}", dict(&[5, 7, 11, 13], 0, -2));
    println!("twist y^2 = x^3 - 49x: {}", dict(&[13, 17, 29], -49, 0));
    println!("no CM, y^2 = x^3 - x + 1: {}", dict(&[7, 11, 13, 17], -1, 1));
    for &p in &[13i64, 17, 29] { assert!(ap_euler(p, -49, 0) == legendre(7, p) * ap_cm(p)) }
    for (name, a, b) in [("y^2 = x^3 - x", -1i64, 0i64), ("y^2 = x^3 - 30x + 56", -30, 56), ("y^2 = x^3 - 11x + 14", -11, 14)] {
        let (top, bot) = (1728 * 4 * a * a * a, 4 * a * a * a + 27 * b * b);
        let g = gcd(top, bot) * bot.signum();
        let (top, bot) = (top / g, bot / g);
        let c = (top as f64 / bot as f64).powf(1.0 / 3.0).round() as i64;
        assert!(bot == 1 && top == c * c * c);
        println!("{}: j = {} = {}^3", name, top, c);
    }
    for (label, t, want) in [("i", 1.0f64, Some(1728.0f64)), ("i sqrt2", 2f64.sqrt(), Some(8000.0)), ("2i", 2.0, Some(287496.0)), ("1.5i", 1.5, None)] {
        let (ja, jb) = j_tau(t);
        assert!((ja - jb).abs() < 1e-6 * jb && want.map_or(true, |w| (jb - w).abs() < 1e-6 * w));
        println!("j({}) = {:.4}", label, jb);
    }
    let j15 = j_tau(1.5).1;
    assert!((j15 - j15.round()).abs() > 0.01);
    let ds = [-4i64, -8, -16, -144];
    println!("class numbers h(D): {{{}}}", ds.iter().map(|&d| format!("{}: {}", d, class_number(d))).collect::<Vec<_>>().join(", "));
    assert!(ds.iter().map(|&d| class_number(d)).collect::<Vec<_>>() == vec![1, 1, 1, 4]);
    let (a, b) = two_squares(13);                   // the three wrong rules, read from 13 = a^2 + b^2
    println!("what breaks, p = 13: rule a_p = 0 gives {} points; a = {} gives {}; 2b in place of 2a gives {}; the count is {}",
             13 + 1, -a, 13 + 1 + 2 * a, 13 + 1 - 2 * b, points(13, -1, 0).len());
    println!("ALL CHECKS PASS");
}
