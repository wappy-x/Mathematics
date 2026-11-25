// Representations of sl(2) -- the same check as the Python, in Rust.  No crates.
// V_n is built from the ladder rules, its brackets and Casimir are checked by
// matrix products, and each tensor product is split by two roads that share no
// step: peeling highest weights off the list of weights, and counting the
// Casimir's eigenvectors by exact integer ranks.  Spin 1 is V_2, spin 1/2 is V_1.
type M = Vec<Vec<i64>>;

fn rep(n: i64) -> (M, M, M) {            // basis v_0..v_n; v_k has weight n - 2k
    let d = (n + 1) as usize;
    let mut h = vec![vec![0; d]; d];
    let mut e = vec![vec![0; d]; d];
    let mut f = vec![vec![0; d]; d];
    for j in 0..d {
        h[j][j] = n - 2 * j as i64;
        if j > 0 { e[j - 1][j] = j as i64 * (n - j as i64 + 1) }   // E v_k = k(n-k+1) v_(k-1)
        if j + 1 < d { f[j + 1][j] = 1 }                          // F v_k = v_(k+1)
    }
    (h, e, f)
}

fn mul(a: &M, b: &M) -> M {
    (0..a.len()).map(|i| (0..b[0].len()).map(|j| (0..b.len()).map(|k| a[i][k] * b[k][j]).sum()).collect()).collect()
}

fn lin(x: i64, a: &M, y: i64, b: &M) -> M {    // x A + y B
    a.iter().zip(b).map(|(r, s)| r.iter().zip(s).map(|(p, q)| x * p + y * q).collect()).collect()
}

fn eye(d: usize) -> M { (0..d).map(|i| (0..d).map(|j| (i == j) as i64).collect()).collect() }

fn br(a: &M, b: &M) -> M { lin(1, &mul(a, b), -1, &mul(b, a)) }   // [A, B] = AB - BA

fn casimir(r: &(M, M, M)) -> M {               // C = H^2 + 2EF + 2FE
    lin(1, &mul(&r.0, &r.0), 2, &lin(1, &mul(&r.1, &r.2), 1, &mul(&r.2, &r.1)))
}

fn kron(a: &M, b: &M) -> M {
    let mut out = Vec::new();
    for ra in a { for rb in b { out.push(ra.iter().flat_map(|x| rb.iter().map(move |y| x * y)).collect()) } }
    out
}

fn tensor(r: &(M, M, M), s: &(M, M, M)) -> (M, M, M) {   // X (x) 1 + 1 (x) X
    let t = |x: &M, y: &M| lin(1, &kron(x, &eye(y.len())), 1, &kron(&eye(x.len()), y));
    (t(&r.0, &s.0), t(&r.1, &s.1), t(&r.2, &s.2))
}

fn gcd(mut a: i64, mut b: i64) -> i64 { while b != 0 { (a, b) = (b, a % b) } a.abs() }

fn rank(m0: &M) -> usize {                      // fraction-free elimination on integers
    let (mut m, mut r) = (m0.clone(), 0);
    for c in 0..m[0].len() {
        let p = match (r..m.len()).find(|&i| m[i][c] != 0) { Some(p) => p, None => continue };
        m.swap(r, p);
        for i in r + 1..m.len() {
            let row: Vec<i64> = (0..m[i].len()).map(|j| m[r][c] * m[i][j] - m[i][c] * m[r][j]).collect();
            let g = row.iter().fold(0, |g, &x| gcd(g, x));
            m[i] = if g != 0 { row.iter().map(|x| x / g).collect() } else { row };
        }
        r += 1;
    }
    r
}

fn peel(ws0: &[i64]) -> Vec<i64> {              // road 1: strip whole ladders off the top
    let (mut ws, mut tops) = (ws0.to_vec(), Vec::new());
    ws.sort();
    while let Some(&top) = ws.last() {
        tops.push(top);
        let mut w = top;
        while w >= -top { let i = ws.iter().position(|&x| x == w).unwrap(); ws.remove(i); w -= 2 }
    }
    tops
}

fn kernel(c: &M, n: i64) -> usize { c.len() - rank(&lin(1, c, -n * (n + 2), &eye(c.len()))) }

fn by_casimir(r: &(M, M, M)) -> Vec<i64> {      // road 2: pieces V_n = dim ker(C - n(n+2)) / (n+1)
    let (c, mut tops) = (casimir(r), Vec::new());
    for n in (0..c.len() as i64).rev() {
        let k = kernel(&c, n) as i64;
        assert!(k % (n + 1) == 0);
        for _ in 0..k / (n + 1) { tops.push(n) }
    }
    tops
}

fn diag(m: &M) -> Vec<i64> { (0..m.len()).map(|i| m[i][i]).collect() }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn join(v: Vec<String>, s: &str) -> String { v.join(s) }

fn main() {
    let (h, e, f) = rep(2);
    println!("spin 1 = V_2, basis v_0, v_1, v_2");
    println!("H rows: {:?}   E rows: {:?}   F rows: {:?}", h, e, f);
    println!("E v_k = k(n-k+1) v_(k-1), coefficients for k = 1, 2: {:?}", [1, 2].map(|k: i64| k * (2 - k + 1)));
    println!("EF diagonal: {:?}   FE diagonal: {:?}   [E,F] diagonal: {:?}", diag(&mul(&e, &f)), diag(&mul(&f, &e)), diag(&br(&e, &f)));
    let ok = (0..7).map(rep).all(|r| br(&r.0, &r.1) == lin(2, &r.1, 0, &r.1)
        && br(&r.0, &r.2) == lin(-2, &r.2, 0, &r.2) && br(&r.1, &r.2) == r.0);
    println!("[H,E] = 2E, [H,F] = -2F, [E,F] = H for n = 0..6: {}", yn(ok));
    for n in 0..5i64 {
        let c = casimir(&rep(n));
        let spin = if n % 2 == 0 { format!("{}", n / 2) } else { format!("{}/2", n) };
        let same = yn(c == lin(c[0][0], &eye(n as usize + 1), 0, &eye(n as usize + 1)));
        println!("V_{}: dim {}, spin {}, weights {:?}, C = {} on every vector: {}, j(j+1) = C/4 = {:.2}",
                 n, n + 1, spin, diag(&rep(n).0), c[0][0], same, c[0][0] as f64 / 4.0);
    }
    let signs: Vec<i64> = (0..5).map(|n| {   // e^(i pi H) multiplies a weight-w vector by (-1)^w
        let s: Vec<i64> = diag(&rep(n).0).iter().map(|w| 1 - 2 * w.rem_euclid(2)).collect();
        if s.iter().all(|&x| x == s[0]) { s[0] } else { 0 }
    }).collect();
    println!("a full turn, e^(i pi H), multiplies all of V_n by one sign, n = 0..4: {:?}", signs);
    let cases: [(&str, Vec<i64>); 3] = [("V_1 x V_1, two spin-1/2 quarks", vec![1, 1]),
        ("V_2 x V_1, spin 1 with spin 1/2", vec![2, 1]), ("V_1 x V_1 x V_1, three quarks", vec![1, 1, 1])];
    let mut found = Vec::new();
    for (name, parts) in cases.iter() {
        let mut r = rep(parts[0]);
        for &m in &parts[1..] { r = tensor(&r, &rep(m)) }
        let mut ws = diag(&r.0);
        ws.sort_by(|a, b| b.cmp(a));
        let cas = casimir(&r);
        let (a, b) = (peel(&ws), by_casimir(&r));
        let mut ns = a.clone();
        ns.dedup();
        let eig = join(ns.iter().map(|&n| format!("{} on {} vectors", n * (n + 2), kernel(&cas, n))).collect(), ", ");
        println!("{}: dim {}, weights {:?}", name, ws.len(), ws);
        println!("  peeled tops {:?}; Casimir {}; pieces by Casimir {:?}", a, eig, b);
        println!("  = {}  dims {} = {}", join(a.iter().map(|n| format!("V_{}", n)).collect(), " + "),
                 join(a.iter().map(|n| format!("{}", n + 1)).collect(), " + "), a.iter().map(|n| n + 1).sum::<i64>());
        found.push((a, b));
    }
    let lam = 1.5f64;
    let co = |l: f64, k: i64| k as f64 * (l - k as f64 + 1.0);
    println!("mistake 1, top weight 1.5: E F^k v_0 coefficients k(1.5-k+1), k = 1..5: {} -- never 0, no top rung",
             join((1..6).map(|k| format!("{:.1}", co(lam, k))).collect(), ", "));
    println!("  top weight 2 for contrast: {}", join((1..4).map(|k| format!("{:.1}", co(2.0, k))).collect(), ", "));
    let mut e1 = vec![vec![0i64; 3]; 3];
    e1[0][1] = 1;
    e1[1][2] = 1;
    println!("mistake 2, every E coefficient 1: diagonal of [E,F] = {:?} but H = {:?}", diag(&br(&e1, &f)), diag(&h));
    println!("mistake 3, dimensions added: 3 + 2 = {} but V_2 x V_1 has {}", h.len() + rep(1).0.len(), tensor(&rep(2), &rep(1)).0.len());
    println!("mistake 4, list stepping by 1: V_3 + V_2 + V_1 has {} dims, not 6", [3, 2, 1].iter().map(|&n| rep(n).0.len()).sum::<usize>());
    assert!(ok && diag(&mul(&e, &f)) == vec![2, 2, 0] && diag(&mul(&f, &e)) == vec![0, 2, 2]);
    assert!((0..7).all(|n: i64| casimir(&rep(n)) == lin(n * (n + 2), &eye(n as usize + 1), 0, &eye(n as usize + 1))));
    assert!(found.iter().all(|(a, b)| a == b));        // peeling agrees with the Casimir count
    assert!(found.iter().map(|(a, _)| a.clone()).collect::<Vec<_>>() == vec![vec![2, 0], vec![3, 1], vec![3, 1, 1]]);
    assert!(signs == vec![1, -1, 1, -1, 1]);           // a full turn is +1 or -1 on a whole ladder
    assert!(br(&e1, &f) != h);                         // unit E coefficients break [E, F] = H
    assert!((1..40).all(|k| co(lam, k) != 0.0));       // a top of 1.5 never stops
    println!("ALL CHECKS PASS");
}
