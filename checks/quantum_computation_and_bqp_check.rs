// BQP -- the same check as the Python, in Rust.  No crates.  The state-vector
// simulator is the one the Qubits card explains: a list of 2^q amplitudes for
// q qubits, each gate an update of that list.  Every gate here has real
// entries, so the amplitudes stay real numbers.
type M = Vec<Vec<f64>>;
fn r() -> f64 { 1.0 / 2f64.sqrt() }
fn h(s: &[f64], k: usize, q: usize) -> Vec<f64> {    // Hadamard on qubit k of q (qubit 0 leftmost)
    let (b, mut t) = (1usize << (q - 1 - k), s.to_vec());
    for i in 0..s.len() {
        if i & b == 0 { t[i] = r() * (s[i] + s[i | b]); t[i | b] = r() * (s[i] - s[i | b]); }
    }
    t
}
fn xg(s: &[f64], k: usize, q: usize) -> Vec<f64> {   // X, the NOT gate, on qubit k
    (0..s.len()).map(|i| s[i ^ (1 << (q - 1 - k))]).collect()
}
fn oracle(s: &[f64], f: &[usize]) -> Vec<f64> {      // U_f: (inputs, y) -> (inputs, y xor f(inputs))
    (0..s.len()).map(|i| s[i ^ f[i >> 1]]).collect()
}
fn bad_oracle(s: &[f64], f: &[usize]) -> Vec<f64> {  // (inputs, y) -> (inputs, f(inputs)): not reversible
    let mut t = vec![0.0; s.len()];
    for i in 0..s.len() { t[(i >> 1 << 1) | f[i >> 1]] += s[i]; }
    t
}
fn run(f: &[usize], n: usize, flip: bool, last_h: bool) -> f64 {   // returns Pr[inputs read 0]
    let q = n + 1;
    let mut s = vec![0.0; 1 << q];
    s[0] = 1.0;
    if flip { s = xg(&s, n, q); }
    for k in 0..q { s = h(&s, k, q); }
    s = oracle(&s, f);
    if last_h { for k in 0..n { s = h(&s, k, q); } }
    s[0].powi(2) + s[1].powi(2)
}
fn sign_sum(f: &[usize]) -> f64 {                    // (average of (-1)^f(x)) squared
    (f.iter().map(|&v| if v == 0 { 1.0 } else { -1.0 }).sum::<f64>() / f.len() as f64).powi(2)
}
fn kron(a: &M, b: &M) -> M {
    let mut out = Vec::new();
    for ra in a { for rb in b { out.push(ra.iter().flat_map(|x| rb.iter().map(move |y| x * y)).collect()); } }
    out
}
fn mul(a: &M, b: &M) -> M {
    (0..a.len()).map(|i| (0..b[0].len()).map(|j| (0..b.len()).map(|k| a[i][k] * b[k][j]).sum()).collect()).collect()
}
fn perm(f: &[usize]) -> M {
    (0..4).map(|i| (0..4).map(|j| if i == j ^ f[j >> 1] { 1.0 } else { 0.0 }).collect()).collect()
}
fn comb(k: u64, j: u64) -> f64 { (0..j).fold(1.0, |acc, i| acc * (k - i) as f64 / (i + 1) as f64) }
fn majority_error(p: f64, k: u64) -> f64 {           // exact chance that at least half of k runs are wrong
    ((k + 1) / 2..=k).map(|j| comb(k, j) * p.powi(j as i32) * (1.0 - p).powi((k - j) as i32)).sum()
}
fn row(v: &[f64]) -> String { v.iter().map(|p| format!("{:.6}", p)).collect::<Vec<_>>().join(" ") }

fn main() {
    let (i2, x2, h2): (M, M, M) = (vec![vec![1.0, 0.0], vec![0.0, 1.0]], vec![vec![0.0, 1.0], vec![1.0, 0.0]],
                                   vec![vec![r(), r()], vec![r(), -r()]]);
    let deutsch: [(&str, [usize; 2]); 4] = [("constant 0", [0, 0]), ("constant 1", [1, 1]),
                                             ("copy, the adder's sum bit", [0, 1]), ("negate", [1, 0])];
    println!("Deutsch's test, one query: Pr[first qubit reads 1] for each one-bit function");
    for (name, f) in deutsch.iter() {
        let (p1, formula) = (1.0 - run(f, 1, true, true), 1.0 - sign_sum(f));
        let u = mul(&kron(&h2, &i2), &mul(&perm(f), &mul(&kron(&h2, &h2), &kron(&i2, &x2))));
        let ut: M = (0..4).map(|i| (0..4).map(|j| u[j][i]).collect()).collect();
        let utu = mul(&ut, &u);
        let unitary = (0..4).all(|i| (0..4).all(|j| (utu[i][j] - if i == j { 1.0 } else { 0.0 }).abs() < 1e-12));
        let matrix_p1 = u[2][0].powi(2) + u[3][0].powi(2);
        println!("  f = {:<26} {:.6}  {:<20}  formula {:.6}  matrix {:.6}  unitary {}", name, p1,
                 "#".repeat((20.0 * p1).round() as usize), formula, matrix_p1, if unitary { "yes" } else { "no" });
        assert!((p1 - formula).abs() < 1e-12 && (p1 - matrix_p1).abs() < 1e-12 && unitary);
        assert!((p1.round() == 1.0) == (f[0] != f[1]));
    }
    let mut s = vec![1.0, 0.0, 0.0, 0.0];             // the copy function, traced step by step
    println!("trace for f = copy, amplitudes of 00 01 10 11:");
    for label in ["after X on the answer qubit", "after H on both", "after U_f", "after H on the first"] {
        s = match label {
            "after X on the answer qubit" => xg(&s, 1, 2),
            "after H on both" => h(&h(&s, 0, 2), 1, 2),
            "after U_f" => oracle(&s, &[0, 1]),
            _ => h(&s, 0, 2),
        };
        println!("  {:<30}{}", label, s.iter().map(|a| format!("{:+.4}", a)).collect::<Vec<_>>().join(" "));
    }
    let mut one_query = Vec::new();
    for b in 0..2 { for ans in [[0, 0], [0, 1], [1, 0], [1, 1]] {
        one_query.push(deutsch.iter().filter(|(_, f)| (ans[f[b]] == 1) == (f[0] != f[1])).count());
    } }
    let best = *one_query.iter().max().unwrap();
    println!("best classical one-query strategy: right on {} of 4 functions", best);
    assert!(best == 2);

    let tables: Vec<Vec<usize>> = (0..16).map(|m| (0..4).map(|j| (m >> (3 - j)) & 1).collect()).collect();
    let cons: Vec<Vec<usize>> = tables.iter().filter(|t| t.iter().all(|&v| v == t[0])).cloned().collect();
    let bal: Vec<Vec<usize>> = tables.iter().filter(|t| t.iter().sum::<usize>() == 2).cloned().collect();
    let both: Vec<Vec<usize>> = cons.iter().chain(bal.iter()).cloned().collect();
    let dj: Vec<f64> = both.iter().map(|f| run(f, 2, true, true)).collect();
    println!("Deutsch-Jozsa on two-bit inputs: {} constant, {} balanced; Pr[inputs read 00]: {}", cons.len(), bal.len(), row(&dj));
    assert!(dj.iter().zip(both.iter()).all(|(p, f)| (p - sign_sum(f)).abs() < 1e-12) && dj.windows(2).all(|w| w[0] >= w[1]));
    let off = run(&[0, 0, 0, 1], 2, true, true);      // outside the promise: one 1 in four
    println!("no promise, f = 0001: Pr[inputs read 00] {:.6}", off);
    assert!((off - sign_sum(&[0, 0, 0, 1])).abs() < 1e-12 && (off - 0.25).abs() < 1e-12);
    let pairs: Vec<(usize, usize)> = (0..4).flat_map(|a| (a + 1..4).map(move |b| (a, b))).collect();
    let fooled = pairs.iter().filter(|&&(a, b)| cons.iter().any(|c| bal.iter().any(|g| c[a] == g[a] && c[b] == g[b]))).count();
    let mut triples = Vec::new();
    for a in 0..4 { for b in a + 1..4 { for c in b + 1..4 { triples.push([a, b, c]); } } }
    let fooled3 = triples.iter().filter(|t| cons.iter().any(|k| bal.iter().any(|g| t.iter().all(|&i| k[i] == g[i])))).count();
    let same = bal.iter().map(|f| pairs.iter().filter(|&&(a, b)| f[a] == f[b]).count()).sum::<usize>();
    let err2 = same as f64 / (bal.len() * pairs.len()) as f64;
    println!("two classical queries: {} of {} pairs fit a constant and a balanced function; three queries: {} of {} triples",
             fooled, pairs.len(), fooled3, triples.len());
    println!("two random distinct queries call a balanced function constant with probability {:.6}", err2);
    assert!(fooled == 6 && fooled3 == 0 && (err2 - 1.0 / 3.0).abs() < 1e-12);
    println!("exact classical queries for n input bits, against 1 quantum query:");
    for n in [2u32, 10, 20, 40] { println!("  n = {:<3} {}", n, 2u64.pow(n - 1) + 1); }
    let err10 = bal.iter().map(|f| (0..2).map(|v| (f.iter().filter(|&&x| x == v).count() as f64 / 4.0).powi(10)).sum::<f64>())
        .fold(0.0, f64::max);                         // all ten see one value
    println!("ten random queries with repeats call a balanced function constant with probability {:.6}", err10);
    assert!((err10 - 2f64.powi(1 - 10)).abs() < 1e-15);

    println!("majority of k runs, each wrong with probability 1/3: exact error, then the bound exp(-k/18)");
    for k in [1u64, 5, 15, 25, 51] {
        let (e, bound) = (majority_error(1.0 / 3.0, k), (-(k as f64) / 18.0).exp());
        println!("  k = {:<3} {:.6}  {:.6}", k, e, bound);
        assert!(e <= bound);
    }
    assert!(majority_error(1.0 / 3.0, 15) < majority_error(1.0 / 3.0, 5) && majority_error(1.0 / 3.0, 5) < 1.0 / 3.0);
    println!("amplitudes a classical simulator stores, 16 bytes each:");
    for q in [10u32, 20, 30, 40, 50] { println!("  {} qubits  {} amplitudes  {} bytes", q, 1u64 << q, 16u64 << q); }
    println!("what breaks, for constant 0, constant 1, copy, negate:");
    let no_flip: Vec<f64> = deutsch.iter().map(|(_, f)| 1.0 - run(f, 1, false, true)).collect();
    let no_h: Vec<f64> = deutsch.iter().map(|(_, f)| 1.0 - run(f, 1, true, false)).collect();
    println!("  answer qubit left at 0: Pr[reads 1] {}", row(&no_flip));
    println!("  no final H: Pr[reads 1] {}", row(&no_h));
    let lost: f64 = bad_oracle(&h(&h(&[0.0, 1.0, 0.0, 0.0], 0, 2), 1, 2), &[0, 0]).iter().map(|a| a * a).sum();
    println!("  oracle that overwrites y, f = constant 0: total probability {:.6}", lost);
    println!("  each run wrong with probability 1/2: majority of 15 runs wrong with probability {:.6}", majority_error(0.5, 15));
    assert!(lost < 1e-12 && (majority_error(0.5, 15) - 0.5).abs() < 1e-12);
    println!("figure, wires y=70,150; X x=90; H x=170; U_f x=260; H x=350; meter x=430");
    println!("ALL CHECKS PASS");
}
