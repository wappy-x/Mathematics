// Rings of integers of the quadratic fields Q(sqrt d): the mod-4 rule against two other roads.
// A number (A + B*sqrt(d))/q is stored as three whole numbers (A, B, q) with q > 0.
type E = (i64, i64, i64);

// the test: trace 2A/q and norm (A^2 - d B^2)/q^2 both whole
fn integral(d: i64, a: i64, b: i64, q: i64) -> bool {
    (2 * a) % q == 0 && (a * a - d * b * b) % (q * q) == 0
}

fn squarefree(n: i64) -> bool {
    let mut p = 2;
    while p * p <= n.abs() {
        if n % (p * p) == 0 {
            return false;
        }
        p += 1;
    }
    true
}

// Road 1, the theorem: the second basis number; the first is always 1
fn rule(d: i64) -> E { if d.rem_euclid(4) == 1 { (1, 1, 2) } else { (0, 1, 1) } }

// determinant of the trace matrix of the basis 1, e
fn disc(d: i64, e: E) -> i64 {
    let (a, b, q) = e;
    let top = 2 * 2 * (a * a + d * b * b) - (2 * a) * (2 * a); // Tr(1)Tr(e^2) - Tr(e)^2, over q^2
    assert!(top % (q * q) == 0);
    top / (q * q)
}

// N(x + y e) = x^2 + Tr(e) xy + N(e) y^2; discriminant Tr(e)^2 - 4 N(e)
fn form_disc(d: i64, e: E) -> i64 {
    let (a, b, q) = e;
    let (tr, nq) = (2 * a / q, a * a - d * b * b);
    assert!(nq % (q * q) == 0);
    tr * tr - 4 * (nq / (q * q))
}

// Road 3: for each prime p with p^2 | disc, try every (c1 + c2 e)/p
fn p_test(d: i64, e: E) -> Vec<E> {
    let (dd, (a, b, q)) = (disc(d, e), e);
    let mut found = Vec::new();
    for p in 2..=dd.abs() {
        if dd % (p * p) != 0 || (2..p).any(|r| p % r == 0) {
            continue;
        }
        for c1 in 0..p {
            for c2 in 0..p {
                if (c1, c2) != (0, 0) && integral(d, c1 * q + c2 * a, c2 * b, p * q) {
                    found.push((p, c1, c2));
                }
            }
        }
    }
    found
}

// is i/den + (j/den) sqrt d equal to x + y e with x, y whole?
fn in_ring(i: i64, j: i64, den: i64, e: E) -> bool {
    let (a, b, q) = e;
    if (j * q) % (den * b) != 0 {
        return false;
    }
    let y = j * q / (den * b);
    (i * q - y * a * den) % (den * q) == 0
}

// Road 2: test every a + b sqrt d, a and b in steps of 1/den from -2 to 2
fn grid(d: i64, e: E, den: i64) -> (i64, i64) {
    let (mut hits, mut clash) = (0, 0);
    for i in -2 * den..=2 * den {
        for j in -2 * den..=2 * den {
            let t = integral(d, i, j, den);
            hits += t as i64;
            clash += (t != in_ring(i, j, den, e)) as i64;
        }
    }
    (hits, clash)
}

// (x1 + y1 w)(x2 + y2 w) with w^2 = w + c, c = (d - 1)/4
fn mul(u: (i64, i64), v: (i64, i64), c: i64) -> (i64, i64) {
    (u.0 * v.0 + c * u.1 * v.1, u.0 * v.1 + v.0 * u.1 + u.1 * v.1)
}

fn yn(t: bool) -> &'static str { if t { "yes" } else { "no" } }

fn roots(f: impl Fn(i64) -> i64) -> Vec<i64> {
    (0..2).filter(|&x| f(x) % 2 == 0).collect()
}

fn units(nf: impl Fn(i64, i64) -> i64) -> i64 {
    let mut n = 0;
    for x in -3..4 {
        for y in -3..4 {
            n += (nf(x, y) == 1) as i64;
        }
    }
    n
}

fn main() {
    println!("grid: steps of 1/12 from -2 to 2, {} points per field", (4 * 12 + 1) * (4 * 12 + 1));
    println!(" d  d mod 4  integral basis      d_K  grid  rule=grid  p-test");
    let mut rows = 0;
    for d in -11i64..14 {
        if d == 0 || d == 1 || !squarefree(d) {
            continue;
        }
        let (e, plain) = (rule(d), (0, 1, 1));
        rows += 1;
        let (dk, (hits, clash)) = (disc(d, e), grid(d, e, 12));
        let name = if e != plain { "1, (1+sqrt d)/2" } else { "1, sqrt d" };
        let m = d.rem_euclid(4);
        println!("{:>3}  {:>4}     {:<16} {:>5}  {:>4}  {:>9}  {}", d, m, name, dk, hits, yn(clash == 0), p_test(d, e).len());
        assert!(clash == 0 && p_test(d, e).is_empty() && form_disc(d, e) == dk);
        assert!(dk == (if m == 1 { d } else { 4 * d }) && hits == (if m == 1 { 41 } else { 25 }));
        let (k2, extra) = (disc(d, plain) / dk, p_test(d, plain));
        assert!((k2 == 4) == (m == 1) && (m == 1) == (extra == vec![(2, 1, 1)]) && (k2 == 1 || k2 == 4));
    }

    println!("fields checked: {}", rows);
    let h = (1 + (-5) * 1 * (-1), 1 * (-1) + 1 * 1, 1); // (1 + sqrt-5)(1 - sqrt-5)
    println!("house d=-5: (1+sqrt-5)(1-sqrt-5) = {}; (1+sqrt-5)/2 has norm {}/4, integral {}; d_K = {}",
             h.0, 1 + 5, yn(integral(-5, 1, 1, 2)), disc(-5, rule(-5)));
    assert!(h.1 == 0 && h.2 == 1);
    let (pa, pb, pq) = rule(5);
    let k = (1..9).find(|k| k * k * disc(5, rule(5)) == disc(5, (0, 1, 1))).unwrap();
    println!("d=5: disc of 1, sqrt5 = {}; disc of 1, phi = {}; index {}; traces of 1, phi, phi^2: 2, {}, {}; of 5: {}",
             disc(5, (0, 1, 1)), disc(5, rule(5)), k, 2 * pa / pq, 2 * (pa * pa + 5 * pb * pb) / (pq * pq), 2 * 5);
    for (e, nm) in [((1, 0, 2), "1/2"), ((0, 1, 2), "sqrt5/2"), ((1, 1, 2), "(1+sqrt5)/2")] {
        println!("  candidate {}: trace {}/2, norm {}/4, integral {}", nm, 2 * e.0, e.0 * e.0 - 5 * e.1 * e.1,
                 yn(integral(5, e.0, e.1, e.2)));
    }
    println!("  p-test on 1, sqrt5 finds (p, c1, c2): {:?}; on 1, sqrt12: {:?}", p_test(5, (0, 1, 1)), p_test(12, (0, 1, 1)));

    let (mut p10, mut fib) = ((1i64, 0i64), vec![0i64, 1]);
    for _ in 0..10 {
        p10 = mul(p10, (0, 1), 1);
        let n = fib.len();
        fib.push(fib[n - 1] + fib[n - 2]);
    }
    let (a10, b10) = (2 * p10.0 + p10.1, p10.1); // x + y phi = (2x + y + y sqrt5)/2
    println!("phi^10 = {} + {} phi = ({} + {} sqrt5)/2; Fibonacci F0 to F11 = {:?}; norm {}",
             p10.0, p10.1, a10, b10, fib, (a10 * a10 - 5 * b10 * b10) / 4);
    assert!(p10 == (fib[9], fib[10]) && integral(5, a10, b10, 2) && (a10, b10) == (123, 55));
    let (inv1, inv2) = ((-1i64, 1i64), (2i64, -1i64));
    assert!(mul(inv1, (0, 1), 1) == (1, 0) && mul(mul(inv2, (0, 1), 1), (0, 1), 1) == (1, 0));
    println!("phi^-1 = {} + {} phi, phi^-2 = {} + ({}) phi: pentagram pieces", inv1.0, inv1.1, inv2.0, inv2.1);
    println!("norm form d=5: x^2 + xy - y^2, disc {}; d=-5: x^2 + 5y^2, disc {}", form_disc(5, rule(5)), form_disc(-5, rule(-5)));
    let fine = 30;
    let g30 = [grid(5, rule(5), fine), grid(-5, rule(-5), fine)];
    println!("grid in steps of 1/{} ({} points): d=5 {}, d=-5 {}", fine, (4 * fine + 1) * (4 * fine + 1), g30[0].0, g30[1].0);
    assert!(g30 == [(41, 0), (25, 0)]);

    let (z5, half_in) = (grid(5, (0, 1, 1), 12), grid(-5, (1, 1, 2), 12));
    println!("break: 1, sqrt5 as basis: ring has {} grid points, true {}; roots mod 2 of x^2-5: {:?}, of x^2-x-1: {:?}",
             z5.0 - z5.1, z5.0, roots(|x| x * x - 5), roots(|x| x * x - x - 1));
    println!("break: halves let in at d=-5: ring has {} grid points, true {}", half_in.0 + half_in.1, half_in.0);
    assert!(z5 == (41, 16) && half_in == (25, 16));
    println!("break: d=45 not squarefree: rule disc {}; p-test finds {:?}; true d_K {}",
             disc(45, rule(45)), p_test(45, rule(45)), disc(5, rule(5)));
    assert!(p_test(45, rule(45)) == vec![(3, 1, 1), (3, 2, 2)] && disc(45, rule(45)) == 9 * disc(5, rule(5)));
    let (u_omega, u_plain) = (units(|x, y| x * x + x * y + y * y), units(|x, y| x * x + 3 * y * y));
    println!("break: d=-3 as 1, sqrt-3: disc {}, units {}; true 1, omega: disc {}, units {}",
             disc(-3, (0, 1, 1)), u_plain, disc(-3, rule(-3)), u_omega);
    assert!((u_omega, u_plain) == (6, 2));
    println!("ALL CHECKS PASS");
}
