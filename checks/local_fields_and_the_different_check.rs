// Local fields and the different -- the same check as the Python, in Rust.
// No crates.  Part 1 completes Q(i) at 5, 3 and 2 by searching roots of
// x^2 + 1 modulo prime powers.  Part 2 reaches the norm of the different two
// ways for four fields with O_K = Z[alpha], the trace-form determinant and the
// norm of f'(alpha); a count of the dual lattice checks the index.  Part 3 reads
// each ramified prime's share of the different off an Eisenstein polynomial.
type Poly = Vec<i128>;

fn ev(f: &[i128], x: i128) -> i128 {             // f(x); coefficients lowest first
    f.iter().enumerate().map(|(k, c)| c * x.pow(k as u32)).sum()
}

fn roots(f: &[i128], m: i128) -> Vec<i128> {     // every r mod m with f(r) = 0 mod m, by search
    (0..m).filter(|&r| ev(f, r).rem_euclid(m) == 0).collect()
}

fn lift(f: &[i128], df: &[i128], mut a: i128, p: i128, k: usize) -> Vec<i128> {
    let (mut out, mut q) = (vec![a], p);         // Hensel: one new p-adic digit per step
    for _ in 0..k - 1 {
        let t = (0..p).find(|t| (ev(f, a) / q + t * ev(df, a)).rem_euclid(p) == 0).unwrap();
        a += t * q; q *= p; out.push(a);
    }
    out
}

fn mulmat(h: &[i128], f: &[i128]) -> Vec<Vec<i128>> { // "multiply by h(alpha)" on 1, alpha, ...
    let n = f.len() - 1;
    let mut cur: Poly = h.to_vec();
    cur.extend(vec![0; f.len()]);
    let mut cols: Vec<Poly> = Vec::new();
    for _ in 0..n {
        for d in (n..cur.len()).rev() {          // reduce by the monic f
            let c = cur[d]; cur[d] = 0;
            for i in 0..n { cur[d - n + i] -= c * f[i] }
        }
        cols.push(cur[..n].to_vec());
        cur.insert(0, 0); cur.pop();
    }
    (0..n).map(|i| (0..n).map(|j| cols[j][i]).collect()).collect()
}

fn det(m: &[Vec<i128>]) -> i128 {                // Bareiss: exact integer determinant
    let (mut a, n, mut sign, mut prev) = (m.to_vec(), m.len(), 1i128, 1i128);
    for k in 0..n - 1 {
        if a[k][k] == 0 {
            let s = (k + 1..n).find(|&i| a[i][k] != 0).unwrap();
            a.swap(k, s); sign = -sign;
        }
        for i in k + 1..n {
            for j in k + 1..n { a[i][j] = (a[i][j] * a[k][k] - a[i][k] * a[k][j]) / prev }
        }
        prev = a[k][k];
    }
    sign * a[n - 1][n - 1]
}

fn vp(mut x: i128, p: i128) -> i128 {            // how many times p divides x
    let mut v = 0;
    while x % p == 0 { x /= p; v += 1 }
    v
}

fn dual_count(t: &[Vec<i128>], m: i128) -> i128 { // a/m, a mod m, with Tr(a/m * alpha^j) whole
    let (n, mut hits) = (t.len(), 0);
    let mut a = vec![0i128; n];
    loop {
        if (0..n).all(|j| (0..n).map(|i| a[i] * t[i][j]).sum::<i128>().rem_euclid(m) == 0) { hits += 1 }
        let mut i = 0;
        while i < n && a[i] == m - 1 { a[i] = 0; i += 1 }
        if i == n { return hits }
        a[i] += 1;
    }
}

fn shift(f: &[i128], r: i128) -> Poly {          // coefficients of f(x + r), by Taylor shift
    let (mut g, n) = (f.to_vec(), f.len() - 1);
    for i in 0..n {
        for j in (i..n).rev() { g[j] += r * g[j + 1] }
    }
    g
}

fn tform(f: &[i128]) -> Vec<Vec<i128>> {         // the trace form: Tr(alpha^(i + j)), a matrix trace
    let n = f.len() - 1;
    (0..n).map(|i| (0..n).map(|j| {
        let mut h = vec![0i128; i + j]; h.push(1);
        let m = mulmat(&h, f);
        (0..n).map(|t| m[t][t]).sum()
    }).collect()).collect()
}

fn eisenstein(g: &[i128], p: i128) -> bool {
    let n = g.len() - 1;
    g[n] == 1 && g[..n].iter().all(|c| c % p == 0) && g[0] % (p * p) != 0
}

fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }

fn gmul(u: (i128, i128), v: (i128, i128), m: i128) -> (i128, i128) { // (a + bi)(c + di) mod m
    ((u.0 * v.0 - u.1 * v.1).rem_euclid(m), (u.0 * v.1 + u.1 * v.0).rem_euclid(m))
}

fn order(u: (i128, i128), m: i128) -> i128 {
    let (mut x, mut k) = (u, 1);
    while x != (1, 0) { x = gmul(x, u, m); k += 1 }
    k
}

fn main() {
    let f: Poly = vec![1, 0, 1];                 // x^2 + 1
    let counts: Vec<Vec<usize>> = [5i128, 3, 2].iter()
        .map(|&p| (1..7).map(|k| roots(&f, p.pow(k)).len()).collect()).collect();
    for (idx, p) in [5, 3, 2].iter().enumerate() { println!("roots of x^2 + 1 mod {}^k, k = 1..6: {:?}", p, counts[idx]) }
    let chain = lift(&f, &[0, 2], 2, 5, 6);
    println!("i in Q_5, lifted from 2: {:?}", chain);
    let nonzero: Vec<(i128, i128)> = (0..9).map(|x| (x / 3, x % 3)).filter(|&u| u != (0, 0)).collect();
    let inv: Vec<(i128, i128)> = nonzero.iter().copied()
        .filter(|&u| nonzero.iter().any(|&v| gmul(u, v, 3) == (1, 0))).collect();
    println!("Z[i]/3: 9 members, {} of 8 nonzero invertible; order of i {}, of 1 + i {}",
             inv.len(), order((0, 1), 3), order((1, 1), 3));
    let sq = gmul((1, 1), (1, 1), 1_000_000);
    let pi_poly = shift(&f, -1);                 // x^2 + 1 at x - 1: the polynomial of 1 + i
    println!("1 + i: norm 2; (1 + i)^2 = {} + {}i; its polynomial {:?} (lowest first) Eisenstein at 2: {}",
             sq.0, sq.1, pi_poly, yn(eisenstein(&pi_poly, 2)));
    let name_of = |c: usize| match c { 2 => "split, two completions Q_5", 1 => "ramified, e = 2", _ => "inert, f = 2" };
    let parts: Vec<String> = [5, 3, 2].iter().map(|&p| format!("p = {}: {}", p, name_of(roots(&f, p).len()))).collect();
    println!("{}", parts.join("; "));
    let fields: Vec<(&str, &str, Poly)> = vec![("Q(i)", "x^2 + 1", vec![1, 0, 1]), ("Q(sqrt-5)", "x^2 + 5", vec![5, 0, 1]),
        ("Q(sqrt5)", "x^2 - x - 1", vec![-1, -1, 1]), ("Q(2^(1/3))", "x^3 - 2", vec![-2, 0, 0, 1])];
    let mut table: Vec<(i128, i128, i128, &str)> = Vec::new();   // e, v by Eisenstein, v by norm, kind
    for (name, shown, h) in &fields {
        let (n, t) = (h.len() - 1, tform(h));
        let df: Poly = (1..=n).map(|k| k as i128 * h[k]).collect();
        let (dk, nd) = (det(&t), det(&mulmat(&df, h)));
        let cnt = dual_count(&t, dk.abs());
        println!("{:11} {:12} d_K by trace form {:5}; N(f'(alpha)) {:5}; dual lattice index {:4}", name, shown, dk, nd, cnt);
        println!("  trace form {:?}", t);
        let mut prod = 1i128;
        for p in [2i128, 3, 5].into_iter().filter(|q| dk % q == 0) {
            let r = (0..p).find(|&r| eisenstein(&shift(h, r), p)).unwrap();
            let g = shift(h, r);                 // pi = alpha - r is a uniformiser; e = n, f = 1
            let ni = n as i128;
            let v = (1..=n).filter(|&j| g[j] != 0).map(|j| ni * vp(j as i128 * g[j], p) + j as i128 - 1).min().unwrap();
            let kind = if ni % p != 0 { "tame" } else { "wild" };
            println!("  at {}: pi = alpha - {}, e = {}; v(different) {} by Eisenstein, {} from the norm; tame rule e - 1 = {}: {}",
                     p, r, n, v, vp(nd.abs(), p), ni - 1, kind);
            table.push((ni, v, vp(nd.abs(), p), kind));
            prod *= p.pow(v as u32);
        }
        assert!(prod == nd.abs() && nd.abs() == dk.abs() && dk.abs() == cnt);   // three roads and the index count
        assert!(dk == (-1i128).pow((n * (n - 1) / 2) as u32) * nd);
    }
    println!("mistake 1, tame rule at 2 in Q(i): norm 2^1 = {}, not {}", 2i128.pow(1), 2i128.pow(table[0].1 as u32));
    let z5: Poly = vec![-5, 0, 1];
    let (nz, d5) = (det(&mulmat(&[0, 2], &z5)), dual_count(&tform(&z5), 20));
    println!("mistake 2, Z[sqrt5] for Q(sqrt5): N(2 sqrt5) = {}, dual index {}, roots of x^2 - 5 mod 2: {} (a double root), not d_K = 5",
             nz, d5, roots(&z5, 2).len());
    println!("mistake 3, lifting the root 1 of x^2 + 1 mod 2: roots mod 4 = {}", roots(&f, 4).len());
    println!("mistake 4, 5 read as one completion of degree 2: {} roots mod 5, so {} completions of degree 1",
             roots(&f, 5).len(), roots(&f, 5).len());
    assert!(counts == vec![vec![2; 6], vec![0; 6], vec![1, 0, 0, 0, 0, 0]]);
    assert!(chain.iter().enumerate().all(|(k, a)| (a * a + 1) % 5i128.pow(k as u32 + 1) == 0));
    assert!(inv.len() == 8 && order((1, 1), 3) == 8 && sq == (0, 2));
    assert!(table.iter().all(|&(e, v, _, kind)| if kind == "tame" { v == e - 1 } else { v >= e }));
    assert!(table.iter().all(|&(_, v, w, _)| v == w));          // Eisenstein road against the norm road
    assert!(nz == -20 && d5 == 20 && roots(&z5, 2).len() == 1);
    assert!(!(0..2).any(|r| eisenstein(&shift(&[3, 0, 1], r), 2)));   // x^2 + 2x + 4 fails only the p^2 test
    println!("ALL CHECKS PASS");
}
