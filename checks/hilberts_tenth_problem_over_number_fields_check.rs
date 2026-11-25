// Hilbert's tenth problem over number fields -- the same check as the Python,
// in Rust.  No crates.  Part 1: Lagrange's four squares pick out 0, 1, 2, ...
// inside the integers, counted by brute force and by Jacobi's divisor formula.
// Part 2: in Z[sqrt2] a square need not be a whole number.  Part 3: the curve
// E5: y^2 = x^3 - 25x and its point P = (-4, 6); the denominators of kP come
// by adding points and by the division-polynomial recursion.  Part 4: the twist
// by 2 decides whether the rank grows in Q(sqrt2): Tunnell's counts against a
// search for points.  Both programs print the same lines.
const N: i64 = 60;

fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }

#[derive(Clone, Copy, PartialEq)]
struct Fr { n: i128, d: i128 }               // a fraction in lowest terms, d > 0
fn fr(n: i128, d: i128) -> Fr {
    let g = gcd(n, d) * d.signum();
    Fr { n: n / g, d: d / g }
}
fn sub(a: Fr, b: Fr) -> Fr { fr(a.n * b.d - b.n * a.d, a.d * b.d) }
fn mul(a: Fr, b: Fr) -> Fr { fr(a.n * b.n, a.d * b.d) }
fn div(a: Fr, b: Fr) -> Fr { fr(a.n * b.d, a.d * b.n) }
fn show(a: Fr) -> String { if a.d == 1 { format!("{}", a.n) } else { format!("{}/{}", a.n, a.d) } }

fn isqrt(v: i128) -> i128 {                  // floor square root by Newton's method
    if v < 2 { return v }
    let (mut x, mut y) = (v, (v + 1) / 2);
    while y < x { x = y; y = (x + v / x) / 2 }
    x
}

fn r3(n: i64) -> i64 {                       // signed, ordered ways as three squares
    let mut c = 0;
    for a in -8..9i64 { for b in -8..9i64 { for d in -8..9i64 { if a*a + b*b + d*d == n { c += 1 } } } }
    c
}
fn r4(n: i64) -> i64 { (-8..9i64).filter(|d| d * d <= n).map(|d| r3(n - d * d)).sum() }
fn jacobi(n: i64) -> i64 { 8 * (1..=n).filter(|d| n % d == 0 && d % 4 != 0).sum::<i64>() }
fn form_8t7(mut n: i64) -> bool {            // n = 4^e (8s + 7)?
    while n > 0 && n % 4 == 0 { n /= 4 }
    n % 8 == 7
}
fn zmul(u: (i64, i64), v: (i64, i64)) -> (i64, i64) { (u.0 * v.0 + 2 * u.1 * v.1, u.0 * v.1 + u.1 * v.0) }

fn add(p: (Fr, Fr), q: (Fr, Fr), n: i128) -> (Fr, Fr) {   // chord and tangent on y^2 = x^3 - n^2 x
    let lam = if p == q {
        div(sub(mul(fr(3, 1), mul(p.0, p.0)), fr(n * n, 1)), mul(fr(2, 1), p.1))
    } else { div(sub(q.1, p.1), sub(q.0, p.0)) };
    let x3 = sub(sub(mul(lam, lam), p.0), q.0);
    (x3, sub(mul(lam, sub(p.0, x3)), p.1))
}

fn psi(k_max: usize) -> Vec<i128> {          // division polynomials of E5 at x = -4, y = 6
    let (a, x, y): (i128, i128, i128) = (-25, -4, 6);
    let mut p = vec![0, 1, 2 * y, 3 * x.pow(4) + 6 * a * x * x - a * a,
                     4 * y * (x.pow(6) + 5 * a * x.pow(4) - 5 * a * a * x * x - a.pow(3))];
    for k in 5..=k_max {
        let m = k / 2;
        let v = if k % 2 == 1 { p[m+2] * p[m].pow(3) - p[m-1] * p[m+1].pow(3) }
                else { p[m] * (p[m+2] * p[m-1].pow(2) - p[m-2] * p[m+1].pow(2)) / p[2] };
        p.push(v);
    }
    p
}

fn tunnell(n: i64) -> (i64, i64) {           // Tunnell's two counts for y^2 = x^3 - n^2 x
    let (m, c) = if n % 2 == 1 { (n, 2) } else { (n / 2, 4) };
    let r = isqrt(m as i128) as i64;
    let (mut a, mut b) = (0, 0);
    for x in -r..=r { for y in -r..=r { for z in -r..=r {
        if x*x + c*y*y + 8*z*z == m { a += 1 }
        if x*x + c*y*y + 32*z*z == m { b += 1 }
    } } }
    (a, b)
}

fn search(n: i128) -> Vec<(i128, i128)> {   // points x = a/e^2, y = b/e^3 with y > 0
    let mut found = Vec::new();
    for e in 1..=12i128 { for a in -2000..=2000i128 {
        if gcd(a, e) != 1 { continue }
        let v = a.pow(3) - n * n * a * e.pow(4);
        if v > 0 && isqrt(v).pow(2) == v { found.push((a, e)) }
    } }
    found
}

fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn main() {
    println!("part 1: the whole numbers 0, 1, 2, ... picked out by four squares");
    println!("7 = 4 + 1 + 1 + 1; signed ways to write 7: three squares {}, four squares {}", r3(7), r4(7));
    let counts: Vec<i64> = (1..=N).map(r4).collect();
    let jac_ok = counts == (1..=N).map(jacobi).collect::<Vec<i64>>();
    println!("four-square counts agree with Jacobi's divisor formula for n <= {}: {}", N, yn(jac_ok));
    let need4: Vec<i64> = (0..=N).filter(|&n| r3(n) == 0).collect();
    let legendre: Vec<i64> = (0..=N).filter(|&n| form_8t7(n)).collect();
    println!("n <= {} needing four squares: {:?}", N, need4);
    println!("the same list from the form 4^e(8s + 7): {}", yn(need4 == legendre));
    println!("n <= {} with no four-square form: {}", N, counts.iter().filter(|&&c| c == 0).count());
    println!("part 2: four squares fail in Z[sqrt2]");
    let (a, b) = zmul((1, 1), (1, 1));       // (1 + sqrt2) times itself, in Z[sqrt2]
    println!("(1 + sqrt2)^2 = {} + {} sqrt2, a square that is not a whole number; norm {}", a, b, a * a - 2 * b * b);
    println!("part 3: E5: y^2 = x^3 - 25x and the point P = (-4, 6)");
    let p = (fr(-4, 1), fr(6, 1));
    println!("check: 6^2 = {} and (-4)^3 - 25(-4) = {}", 6 * 6, (-4i64).pow(3) + 100);
    let q2 = add(p, p, 5);
    println!("2P = ({}, {}), not whole, so P has infinite order (Nagell-Lutz)", show(q2.0), show(q2.1));
    let ps = psi(8);
    let mut road1 = vec![isqrt(p.0.d)];
    let mut q = p;
    for _ in 2..5 { q = add(q, p, 5); road1.push(isqrt(q.0.d)) }
    let d: Vec<i128> = ps.iter().map(|v| v.abs()).collect();
    println!("k, d_k by adding points, d_k by the division-polynomial recursion, its digits");
    for k in 1..9 {
        let r = if k <= 4 { road1[k - 1].to_string() } else { "-".to_string() };
        println!("{} {} {} {}", k, r, d[k], d[k].to_string().len());
    }
    let strong = (1..9).all(|j| (1..9).all(|k| (d[k] % d[j] == 0) == (k % j == 0)));
    println!("d_j divides d_k exactly when j divides k, checked for j, k <= 8: {}", yn(strong));
    let md = |v: i128| v.rem_euclid(1_000_000_007);      // the identity, checked modulo a prime
    let r: Vec<i128> = ps.iter().map(|&v| md(v)).collect();
    let eds = [(5usize, 2usize), (6, 2)].iter().all(|&(m, n)| md(r[m+n] * r[m-n])
        == md(md(md(r[m+1] * r[m-1]) * md(r[n] * r[n])) - md(md(r[n+1] * r[n-1]) * md(r[m] * r[m]))));
    println!("second road to d_5..d_8: psi(m+n)psi(m-n) = psi(m+1)psi(m-1)psi(n)^2 - psi(n+1)psi(n-1)psi(m)^2 at (m, n) = (5, 2), (6, 2), pairs the recursion never uses: {}", yn(eds));
    println!("part 4: does the rank grow in Q(sqrt2)? ask the twist by 2");
    let mut agree = true;
    for n in [3i64, 5, 6, 10, 41] {        // at 41 the z terms count, testing 8 and 32
        let (ta, tb) = tunnell(n);
        let pts = search(n as i128);
        agree &= (ta == 2 * tb) == !pts.is_empty();
        let verdict = if ta == 2 * tb { "A = 2B: rank may be positive" } else { "A != 2B: rank 0 (Tunnell, Coates-Wiles)" };
        let first = if pts.is_empty() { "none".to_string() } else { format!("first x = {}", show(fr(pts[0].0, pts[0].1 * pts[0].1))) };
        println!("E{}: A = {}, B = {}, {}; search finds {} points, {}", n, ta, tb, verdict, pts.len(), first);
    }
    println!("rank E5 over Q(sqrt2) = rank E5 over Q + rank E10 over Q = rank E5 over Q + 0");
    println!("part 5: what breaks");
    println!("mistake 1, three squares instead of four: 7 has {} forms; {} numbers <= {} missed", r3(7), need4.len(), N);
    println!("mistake 2, four squares in Z[sqrt2]: {} + {} sqrt2 passes and is not a whole number", a, b);
    let (bx, by) = (fr(-3, 1), fr(9, 1));    // E6's point (-3, 9) becomes (X/2, Y sqrt2/4) on E3
    let x3 = div(bx, fr(2, 1));
    let y4 = div(by, fr(4, 1));
    let ysq = mul(mul(y4, y4), fr(2, 1));
    let lhs = sub(mul(x3, mul(x3, x3)), mul(fr(9, 1), x3));
    println!("mistake 3, E3 in place of E5: rank 0 over Q, but ({}, {} sqrt2) lies on it over Q(sqrt2): x^3 - 9x = {}, y^2 = {}",
             show(x3), show(y4), show(lhs), show(ysq));
    println!("  that point has infinite order: 2(-3, 9) on E6 has x = {}", show(add((bx, by), (bx, by), 6).0));
    assert!(jac_ok && r4(7) == 64 && r3(7) == 0);                 // brute force against Jacobi
    assert!(need4 == legendre);                                  // brute force against Legendre's form
    assert!(road1[..] == d[1..5] && strong);                     // two roads to the denominators
    assert!(eds);                                                // the identity checks d_5 to d_8
    assert!(agree);                                              // Tunnell against search
    assert!(lhs == ysq && q2.0.d != 1);
    println!("ALL CHECKS PASS");
}
