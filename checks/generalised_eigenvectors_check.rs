// Generalised eigenvectors -- the same check as the Python, in Rust.  No crates.  A: one minute of a van's (position, speed, shown position).
// Road one: sizes of ker (A - lambda I)^k by elimination, in A's axes and others.  Two: multiplicities from traces.  Three: Bezout projectors.  Four: A^10 two ways.
type M = Vec<Vec<i64>>;
const N: usize = 3;
fn a() -> M { vec![vec![1, 1, 0], vec![0, 1, 0], vec![1, 0, 0]] }
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
    let (am, i3, z, v): (M, M, M, [i64; 3]) = (a(), id(), vec![vec![0; N]; N], [3, 1, 0]);
    let (s, si): (M, M) = (vec![vec![1, 1, 1], vec![0, 1, 1], vec![1, 1, 2]], vec![vec![1, -1, 0], vec![1, 1, -1], vec![-1, 0, 1]]); // other axes, inverse
    let (mut coef, mut m) = (vec![1i64], z.clone());            // det(tI - A) from traces of powers
    for k in 1..=N {
        m = add(&mul(&am, &m), &i3, coef[coef.len() - 1]);
        let am_m = mul(&am, &m);
        coef.push(-(0..N).map(|i| am_m[i][i]).sum::<i64>() / k as i64);
    }
    let roots: Vec<i64> = (-12..13).filter(|&r| divide(&coef, r).1 == 0).collect();
    let dims = |lam: i64| -> Vec<usize> { (1..4).map(|k| N - rank(&mpow(&shift(lam), k))).collect() };
    let (p1, p0) = (mul(&add(&add(&i3, &i3, 1), &am, -1), &am), mpow(&shift(1), 2)); // (2 - t) t, (t - 1)^2
    let mut pa = z.clone();
    for (i, &c) in coef.iter().enumerate() { pa = add(&pa, &mpow(&am, N - i), c); }
    let (u, w, slow) = (act(&p1, v), act(&p0, v), act(&mpow(&am, 10), v));
    let nu = act(&shift(1), u);
    let fast: [i64; 3] = std::array::from_fn(|i| 1i64.pow(10) * u[i] + 10 * 1i64.pow(9) * nu[i] + 0i64.pow(10) * w[i]);
    let (d1, d0) = (dims(1), dims(0));
    let bez: Vec<i64> = (0..6).map(|t: i64| (2 - t) * t + (t - 1) * (t - 1)).collect();
    println!("A = {:?}; characteristic polynomial coefficients {:?}", am, coef);
    for &lam in &roots {
        println!("eigenvalue {}: multiplicity {}; dim ker (A - {}I)^k, k = 1, 2, 3: {:?}", lam, mult(&coef, lam), lam, dims(lam));
    }
    println!("A - I sends (1, 1, 0) to {}, which it sends to {}", vec3(act(&shift(1), [1, 1, 0])), vec3(act(&shift(1), [1, 0, 1])));
    println!("A sends (1, 0, 1) to {} and (1, 1, 0) to {}", vec3(act(&am, [1, 0, 1])), vec3(act(&am, [1, 1, 0])));
    println!("A - I = {:?}; (A - I)^2 = {:?}; (A - I)^3 = {:?}", shift(1), p0, mpow(&shift(1), 3));
    println!("(2 - t) t + (t - 1)^2 at t = 0..5: {:?}", bez);
    println!("P1 = (2I - A) A = {:?}", p1);
    println!("P1 + P0 = {:?}; P1 P0 = {:?}", add(&p1, &p0, 1), mul(&p1, &p0));
    println!("Cayley-Hamilton, p(A) = {:?}", pa);
    println!("(3, 1, 0) = {} + {}; piece sizes {} + {} = {}", vec3(u), vec3(w), rank(&p1), rank(&p0), rank(&p1) + rank(&p0));
    println!("A^10 (3, 1, 0), ten multiplications: {}; by the pieces: {}", vec3(slow), vec3(fast));
    println!("mistake, eigenvectors only: {} + {} = {} directions for {}; whole chain added: {}", d1[0], d0[0], d1[0] + d0[0], N, d1[0] + d1[1] + d0[0]);
    println!("mistake, powers as if diagonal: {}, missing 10 x {}", vec3(u), vec3(nu));
    println!("mistake, projector without the Bezout factor: {}, not {}", vec3(act(&am, v)), vec3(u));
    let stable: Vec<usize> = roots.iter().map(|&l| dims(l)[2]).collect();
    let mults: Vec<usize> = roots.iter().map(|&l| mult(&coef, l)).collect();
    assert!(stable == mults && mults == vec![1, 2]);
    assert!(add(&p1, &p0, 1) == i3 && mul(&p1, &p0) == z && pa == z && rank(&p1) == d1[2]);
    assert!([[1, 0, 1], [1, 1, 0]].iter().all(|&e| act(&p0, act(&am, e)) == [0, 0, 0])); // A keeps the plane
    assert!(mul(&s, &si) == i3 && roots.iter().all(|&l| (1..4).all(|k| N - rank(&mul(&mul(&s, &mpow(&shift(l), k)), &si)) == dims(l)[k - 1]))); // other axes
    assert!(slow == fast && d1[0] < d1[1] && d1[1] == d1[2]);
    println!("ALL CHECKS PASS");
}
