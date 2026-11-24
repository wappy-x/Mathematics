// Generalised eigenvectors -- the same check as the Python, in Rust.  No crates.  Road one: sizes of ker (A - lambda I)^k
// by elimination, in A's axes and in others.  Road two: multiplicities from traces.  Road three: Bezout projectors.  Road four: A^10 two ways.
type M = Vec<Vec<i64>>;
const N: usize = 3;
fn a() -> M { vec![vec![2, 1, 0], vec![0, 2, 0], vec![0, 0, 3]] }
fn id() -> M { (0..N).map(|i| (0..N).map(|j| (i == j) as i64).collect()).collect() }
fn mul(x: &M, y: &M) -> M { (0..N).map(|i| (0..N).map(|j| (0..N).map(|k| x[i][k] * y[k][j]).sum()).collect()).collect() }
fn add(x: &M, y: &M, c: i64) -> M { (0..N).map(|i| (0..N).map(|j| x[i][j] + c * y[i][j]).collect()).collect() }
fn act(x: &M, v: [i64; 3]) -> [i64; 3] { std::array::from_fn(|i| (0..N).map(|k| x[i][k] * v[k]).sum()) }
fn shift(lam: i64) -> M { add(&a(), &id(), -lam) }              // A - lambda I
fn mpow(x: &M, k: usize) -> M { if k == 0 { id() } else { mul(&mpow(x, k - 1), x) } }
fn rank(x: &M) -> usize {                   // elimination that stays in whole numbers
    let (mut rows, mut r) = (x.clone(), 0);
    for c in 0..N {
        let Some(p) = (r..N).find(|&i| rows[i][c] != 0) else { continue };
        rows.swap(r, p);
        for i in r + 1..N {
            let (pv, f) = (rows[r][c], rows[i][c]);
            for j in 0..N { rows[i][j] = pv * rows[i][j] - f * rows[r][j]; }
        }
        r += 1;
    }
    r
}
fn divide(c: &[i64], r: i64) -> (Vec<i64>, i64) {     // synthetic division by (t - r)
    let mut q = vec![c[0]];
    for &x in &c[1..] { let last = q[q.len() - 1]; q.push(x + r * last); }
    let rem = q.pop().unwrap(); (q, rem)
}
fn mult(c: &[i64], r: i64) -> usize {                  // how many times (t - r) divides
    let (mut m, (mut q, mut rem)) = (0, divide(c, r));
    while rem == 0 { m += 1; let next = divide(&q, r); q = next.0; rem = next.1; }
    m
}
fn vec3(v: [i64; 3]) -> String { format!("({}, {}, {})", v[0], v[1], v[2]) }
fn main() {
    let (am, i3, z, v): (M, M, M, [i64; 3]) = (a(), id(), vec![vec![0; N]; N], [1, 1, 1]);
    let (s, si): (M, M) = (vec![vec![1, 1, 1], vec![0, 1, 1], vec![1, 1, 2]], vec![vec![1, -1, 0], vec![1, 1, -1], vec![-1, 0, 1]]); // other axes, inverse
    let (mut coef, mut m) = (vec![1i64], z.clone());            // det(tI - A) from traces of powers
    for k in 1..=N {
        m = add(&mul(&am, &m), &i3, coef[coef.len() - 1]);
        let am_m = mul(&am, &m);
        coef.push(-(0..N).map(|i| am_m[i][i]).sum::<i64>() / k as i64);
    }
    let roots: Vec<i64> = (-12..13).filter(|&r| divide(&coef, r).1 == 0).collect();
    let dims = |lam: i64| -> Vec<usize> { (1..4).map(|k| N - rank(&mpow(&shift(lam), k))).collect() };
    let (p2, p3) = (mul(&add(&i3, &am, -1), &shift(3)), mpow(&shift(2), 2)); // (1 - t)(t - 3), (t - 2)^2
    let mut pa = z.clone();
    for (i, &c) in coef.iter().enumerate() { pa = add(&pa, &mpow(&am, N - i), c); }
    let (u, w, slow) = (act(&p2, v), act(&p3, v), act(&mpow(&am, 10), v));
    let nu = act(&shift(2), u);
    let fast: [i64; 3] = std::array::from_fn(|i| 2i64.pow(10) * u[i] + 10 * 2i64.pow(9) * nu[i] + 3i64.pow(10) * w[i]);
    let (d2, d3) = (dims(2), dims(3));
    let bez: Vec<i64> = (0..6).map(|t: i64| (1 - t) * (t - 3) + (t - 2) * (t - 2)).collect();
    println!("A = {:?}; characteristic polynomial coefficients {:?}", am, coef);
    for &lam in &roots {
        println!("eigenvalue {}: multiplicity {}; dim ker (A - {}I)^k, k = 1, 2, 3: {:?}", lam, mult(&coef, lam), lam, dims(lam));
    }
    println!("A - 2I sends (0, 1, 0) to {}, which it sends to {}", vec3(act(&shift(2), [0, 1, 0])), vec3(act(&shift(2), [1, 0, 0])));
    println!("A sends (1, 0, 0) to {} and (0, 1, 0) to {}", vec3(act(&am, [1, 0, 0])), vec3(act(&am, [0, 1, 0])));
    println!("A - 2I = {:?}; (A - 2I)^2 = {:?}; A - 3I = {:?}", shift(2), p3, shift(3));
    println!("(1 - t)(t - 3) + (t - 2)^2 at t = 0..5: {:?}", bez);
    println!("P2 = (I - A)(A - 3I) = {:?}", p2);
    println!("P2 + P3 = {:?}; P2 P3 = {:?}", add(&p2, &p3, 1), mul(&p2, &p3));
    println!("Cayley-Hamilton, p(A) = {:?}", pa);
    println!("(1, 1, 1) = {} + {}; piece sizes {} + {} = {}", vec3(u), vec3(w), rank(&p2), rank(&p3), rank(&p2) + rank(&p3));
    println!("A^10 (1, 1, 1), ten multiplications: {}; by the pieces: {}", vec3(slow), vec3(fast));
    println!("mistake, eigenvectors only: {} + {} = {} directions for {}; whole chain added: {}", d2[0], d3[0], d2[0] + d3[0], N, d2[0] + d2[1] + d3[0]);
    println!("mistake, powers as if diagonal: {}, missing 10 x 2^9 = {}", vec3(act(&mpow(&vec![vec![2, 0, 0], vec![0, 2, 0], vec![0, 0, 3]], 10), v)), 10 * 2i64.pow(9));
    println!("mistake, projector without the Bezout factor: {}, not {}", vec3(act(&shift(3), v)), vec3(u));
    let stable: Vec<usize> = roots.iter().map(|&l| dims(l)[2]).collect();
    let mults: Vec<usize> = roots.iter().map(|&l| mult(&coef, l)).collect();
    assert!(stable == mults && mults == vec![2, 1]);
    assert!(add(&p2, &p3, 1) == i3 && mul(&p2, &p3) == z && pa == z && rank(&p2) == d2[2]);
    assert!([[1, 0, 0], [0, 1, 0]].iter().all(|&e| act(&p3, act(&am, e)) == [0, 0, 0])); // A keeps the plane
    assert!(mul(&s, &si) == i3 && roots.iter().all(|&l| (1..4).all(|k| N - rank(&mul(&mul(&s, &mpow(&shift(l), k)), &si)) == dims(l)[k - 1]))); // other axes
    assert!(slow == fast && d2[0] < d2[1] && d2[1] == d2[2]);
    println!("ALL CHECKS PASS");
}
