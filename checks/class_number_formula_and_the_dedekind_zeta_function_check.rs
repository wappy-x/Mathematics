// The class number formula -- the same check as the Python, in Rust.  No crates.
// Field K = Q(sqrt-5): discriminant d = -20, w = 2 units (+1 and -1), regulator 1.
// Road 1 counts reduced quadratic forms of discriminant d: one per ideal class.
// Road 2 reads h off the L-value: partial sums of chi(n)/n, then h = w sqrt|d| L / (2 pi).
// Road 3 is the finite sum h = -(w / 2|d|) * (sum of chi(a) a for a = 1 to |d|).
// Road 4 counts ideals of norm <= X two ways (divisor sums of chi; lattice points of
// the forms) and sets the count beside residue times X.  chi comes from Euler's criterion.
use std::f64::consts::PI;

fn powmod(mut b: i64, mut e: i64, m: i64) -> i64 {
    let mut r = 1 % m;
    while e > 0 { if e & 1 == 1 { r = r * b % m; } b = b * b % m; e >>= 1; }
    r
}

fn kronecker(d: i64, mut n: i64) -> i64 { // (d/n), d a field discriminant, n >= 1, by factoring n
    let (mut out, mut p) = (1i64, 2i64);
    while n > 1 {
        if p * p > n { p = n; }
        while n % p == 0 {
            n /= p;
            if p == 2 {
                out *= if d % 2 == 0 { 0 } else if [1, 7].contains(&d.rem_euclid(8)) { 1 } else { -1 };
            } else {
                let r = powmod(d.rem_euclid(p), (p - 1) / 2, p); // Euler's criterion
                out *= if r == p - 1 { -1 } else { r };
            }
        }
        p += 1;
    }
    out
}

fn isqrt(n: i64) -> i64 {
    let mut r = (n as f64).sqrt() as i64;
    while r * r > n { r -= 1; } while (r + 1) * (r + 1) <= n { r += 1; } r
}

fn reduced_forms(d: i64) -> Vec<(i64, i64, i64)> {
    let mut out = vec![];
    for a in 1..=isqrt(-d / 3) {
        for b in (-a + 1)..=a {
            if (b * b - d) % (4 * a) == 0 {
                let c = (b * b - d) / (4 * a);
                if c >= a && !(a == c && b < 0) { out.push((a, b, c)); }
            }
        }
    }
    out
}

fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }

fn finite_h(d: i64, w: i64) -> (i64, i64) { // road 3, as a reduced fraction
    let s: i64 = (1..=d.abs()).map(|a| kronecker(d, a) * a).sum();
    let (num, den) = (-w * s, 2 * d.abs());
    let g = gcd(num, den);
    (num / g, den / g)
}

fn fr((n, d): (i64, i64)) -> String { if d == 1 { format!("{}", n) } else { format!("{}/{}", n, d) } }

fn l1(d: i64, n: i64) -> f64 { // road 2: chi(1)/1 + ... + chi(N)/N, chi from one period
    let per: Vec<i64> = (1..=d.abs()).map(|a| kronecker(d, a)).collect();
    (1..=n).map(|k| per[((k - 1) % d.abs()) as usize] as f64 / k as f64).sum()
}

fn points(f: (i64, i64, i64), x: i64) -> i64 { // (x, y) with a x^2 + b x y + c y^2 <= X, origin included
    let (a, b, c) = f;
    let (dd, mut tot, mut y) = (4 * a * c - b * b, 0i64, 0i64);
    while dd * y * y <= 4 * a * x { // 4a Q = (2ax + by)^2 + D y^2
        let (m, r) = (isqrt(4 * a * x - dd * y * y), (b * y).rem_euclid(2 * a));
        let k = (m - r).div_euclid(2 * a) - (-m - 1 - r).div_euclid(2 * a);
        tot += if y == 0 { k } else { 2 * k };
        y += 1;
    }
    tot
}

fn list(v: &[i64]) -> String { format!("[{}]", v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ")) }

fn main() {
    let (d, w) = (-20i64, 2i64);
    let chi: Vec<i64> = (1..=20).map(|a| kronecker(d, a)).collect();
    let periodic = (21..=4000).all(|n| kronecker(d, n) == chi[((n - 1) % 20) as usize]);
    println!("field Q(sqrt-5): d = {}, w = {}; chi(a) for a = 1..20: {}", d, w, list(&chi));
    println!("chi repeats with period 20 for n up to 4000: {}", if periodic { "yes" } else { "no" });
    let kind = |c: i64| if c == 1 { "split" } else if c == -1 { "inert" } else { "ramified" };
    let pr: Vec<String> = [2, 3, 5, 7, 11, 13, 23, 29].iter().map(|&p| format!("{} {}", p, kind(kronecker(d, p)))).collect();
    println!("primes: {}", pr.join(", "));
    let forms = reduced_forms(d);
    let an: Vec<i64> = (1..=20).map(|n| (1..=n).filter(|e| n % e == 0).map(|e| kronecker(d, e)).sum()).collect();
    let reps = |f: (i64, i64, i64), n: i64| points(f, n) - points(f, n - 1);
    let prin: Vec<i64> = (1..=20).map(|n| reps(forms[0], n) / w).collect();
    let nonp: Vec<i64> = (1..=20).map(|n| reps(forms[1], n) / w).collect();
    println!("ideals of norm n, n = 1..20: {}", list(&an));
    println!("  principal (x^2 + 5y^2):    {}", list(&prin));
    println!("  other class (2x^2+2xy+3y^2): {}", list(&nonp));
    let mut six = vec![];
    for x in -3..4i64 { for y in -2..3i64 { if x * x + 5 * y * y == 6 { six.push(format!("({}, {})", x, y)); } } }
    println!("elements of norm 6: [{}]; ideals {}", six.join(", "), six.len() as i64 / w);
    let h1 = forms.len() as i64;
    let fs: Vec<String> = forms.iter().map(|f| format!("({}, {}, {})", f.0, f.1, f.2)).collect();
    println!("road 1, reduced forms of discriminant -20: [{}]; h = {}", fs.join(", "), h1);
    for n in [100i64, 10_000, 1_000_000] {
        println!("road 2, L(1, chi) summed to N = {:>7}: {:.6}", n, l1(d, n));
    }
    let (l, exact) = (l1(d, 1_000_000), 2.0 * PI / 20f64.sqrt());
    let h2 = w as f64 * 20f64.sqrt() * l / (2.0 * PI);
    let h3 = finite_h(d, w);
    println!("        2 pi / sqrt 20 = {:.6}; h = w sqrt|d| L / (2 pi) = {:.5}", exact, h2);
    let sca: i64 = chi.iter().enumerate().map(|(i, c)| c * (i as i64 + 1)).sum();
    println!("road 3, -(2/40) * sum chi(a) a = -(1/20) * {} = {}", sca, fr(h3));
    let kappa = 2.0 * PI * h1 as f64 / (w as f64 * 20f64.sqrt());
    println!("residue of zeta_K at 1: 2 pi h / (w sqrt 20) = {:.6}", kappa);
    println!("lattice cell area sqrt20 / 2 = {:.5}; share of one class 2 pi / (w sqrt 20) = {:.5}", 20f64.sqrt() / 2.0, kappa / h1 as f64);
    println!("road 4, ideals of norm <= X: X, by divisor sums, by lattice points, count/X, count - kappa X, principal/X");
    let (mut ratios, mut prat) = (vec![], vec![]);
    for x in [10i64, 100, 1000, 10_000, 100_000, 1_000_000] {
        let s: i64 = (1..=x).map(|e| chi[((e - 1) % 20) as usize] * (x / e)).sum();
        let lat = forms.iter().map(|&f| points(f, x) - 1).sum::<i64>() / w;
        let p = (points(forms[0], x) - 1) / w;
        ratios.push(s as f64 / x as f64); prat.push(p as f64 / x as f64);
        println!("  {:>7} {:>8} {:>8} {:.5} {:>9.2} {:.5}", x, s, lat, s as f64 / x as f64,
                 s as f64 - kappa * x as f64, p as f64 / x as f64);
        assert!(s == lat, "the two ideal counts must agree exactly");
    }
    let nz = 100_000usize;
    let mut a_sieve = vec![0i64; nz + 1];
    for e in 1..=nz { let mut m = e; while m <= nz { a_sieve[m] += chi[(e - 1) % 20]; m += e; } }
    let mut series = 0.0; for n in 1..=nz { series += a_sieve[n] as f64 / (n * n) as f64; }
    let (mut sieve, mut prod) = (vec![true; nz + 1], 1.0f64);
    for p in 2..=nz {
        if sieve[p] {
            let mut m = p * p; while m <= nz { sieve[m] = false; m += p; }
            let (c, q) = (kronecker(d, p as i64), (p as f64).powi(-2));
            prod *= if c == 0 { 1.0 / (1.0 - q) } else if c == 1 { 1.0 / ((1.0 - q) * (1.0 - q)) } else { 1.0 / (1.0 - (p as f64).powi(-4)) };
        }
    }
    let mut l2 = 0.0; for n in 1..=nz { l2 += chi[(n - 1) % 20] as f64 / (n * n) as f64; }
    let zl = PI * PI / 6.0 * l2;
    println!("zeta_K(2): sum a_n/n^2 {:.5}; Euler product {:.5}; zeta(2) L(2, chi) {:.5}", series, prod, zl);
    let table: Vec<(i64, i64, (i64, i64))> = [-3i64, -4, -7, -8, -15, -20, -23, -24, -47, -71, -163].iter()
        .map(|&dd| (dd, reduced_forms(dd).len() as i64, finite_h(dd, if dd == -3 { 6 } else if dd == -4 { 4 } else { 2 }))).collect();
    let ts: Vec<String> = table.iter().map(|(dd, a, b)| format!("{}: {}/{}", dd, a, fr(*b))).collect();
    println!("other fields, d: forms h / finite-sum h: {}", ts.join(", "));
    let (l5, r5) = (l1(5, 1_000_000), ((1.0 + 5f64.sqrt()) / 2.0).ln());
    println!("mistake, w left out: sqrt 20 L / (2 pi) = {:.5}", 20f64.sqrt() * l / (2.0 * PI));
    let lp = prat[prat.len() - 1];
    println!("mistake, principal ideals only at X = 10^6: {:.5} per unit of X; h read as {:.5}", lp, lp / kappa * h1 as f64);
    println!("mistake, Z[sqrt-3] with d = -12 in the finite sum: {}; true d = -3, w = 6: {}", fr(finite_h(-12, 2)), fr(finite_h(-3, 6)));
    println!("mistake, Q(sqrt5) without the regulator: L(1) = {:.5}, sqrt5 L / 2 = {:.5}; R = {:.5}; with R: {:.5}",
             l5, 5f64.sqrt() * l5 / 2.0, r5, 5f64.sqrt() * l5 / (2.0 * r5));
    let l100 = l1(d, 100);
    println!("mistake, L(1, chi) cut at 100 terms: {:.5}; h read as {:.5}", l100, w as f64 * 20f64.sqrt() * l100 / (2.0 * PI));
    let j = |v: &[f64]| v.iter().map(|r| format!("{:.3}", r)).collect::<Vec<_>>().join(" ");
    println!("chart, X: 10^1 .. 10^6; ideals/X {}; principal/X {}; kappa {:.3}", j(&ratios), j(&prat), kappa);
    assert!(h1 == 2 && h3 == (2, 1) && (h2 - 2.0).abs() < 1e-5, "three roads to h = 2");
    assert!((l - exact).abs() < 5e-6, "partial sums of chi(n)/n must approach 2 pi / sqrt 20");
    assert!(periodic && an[5] == 2 && six.len() == 4);
    assert!(prin.iter().zip(&nonp).map(|(p, q)| p + q).collect::<Vec<_>>() == an, "ideal counts by class must add to the divisor sums");
    assert!((ratios[5] - kappa).abs() < 1e-3 && (lp - kappa / 2.0).abs() < 1e-3);
    assert!((series - zl).abs() < 1e-4 && (prod - zl).abs() < 1e-4);
    assert!(table.iter().all(|(_, a, b)| *b == (*a, 1)) && finite_h(-12, 2) == (2, 3));
    assert!((5f64.sqrt() * l5 / (2.0 * r5) - 1.0).abs() < 1e-5);
    println!("ALL CHECKS PASS");
}
