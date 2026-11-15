// States and the GNS construction -- the same check as the Python, in Rust.  No crates.
// Algebra: 2 x 2 complex matrices.  State of a coin with heads chance p: omega(A) = p a11 + (1-p) a22.
// Roads: the Gram matrix built from omega against its closed form; pi(A) built from omega alone
// against the Bell-pair formula A (x) I; commutants by Gaussian elimination against known answers;
// the one-third event by counting all 2^N flip sequences against exact integer closed forms.
use std::ops::{Add, Div, Mul, Sub};
#[derive(Clone, Copy, Debug)]
struct C { re: f64, im: f64 }
impl Add for C { type Output = C; fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { C { re: self.re - o.re, im: self.im - o.im } } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } } }
impl Div for C { type Output = C; fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im;
    C { re: (self.re * o.re + self.im * o.im) / d, im: (self.im * o.re - self.re * o.im) / d } } }
impl C { fn conj(self) -> C { C { re: self.re, im: -self.im } } fn abs(self) -> f64 { self.re.hypot(self.im) } }
fn r(x: f64) -> C { C { re: x, im: 0.0 } }
type M = Vec<Vec<C>>;
fn mul(a: &M, b: &M) -> M { (0..a.len()).map(|i| (0..b[0].len()).map(|j| (0..b.len()).fold(r(0.0), |s, t| s + a[i][t] * b[t][j])).collect()).collect() }
fn star(a: &M) -> M { (0..a[0].len()).map(|i| (0..a.len()).map(|j| a[j][i].conj()).collect()).collect() }
fn kron(a: &M, b: &M) -> M { (0..4).map(|i| (0..4).map(|k| a[i / 2][k / 2] * b[i % 2][k % 2]).collect()).collect() }
fn omega(a: &M, p: f64) -> C { r(p) * a[0][0] + r(1.0 - p) * a[1][1] }
fn unit(i: usize, j: usize) -> M { (0..2).map(|a| (0..2).map(|b| r(if (a, b) == (i, j) { 1.0 } else { 0.0 })).collect()).collect() }
fn close(a: C, b: C) { assert!((a - b).abs() < 1e-12, "{:?} {:?}", a, b); }
fn same(a: &M, b: &M) { for (ra, rb) in a.iter().zip(b) { for (x, y) in ra.iter().zip(rb) { close(*x, *y); } } }
fn re(z: C) -> String { close(r(z.im), r(0.0)); format!("{:.6}", z.re) }
fn rank_null(rows0: &M) -> (usize, M) { // Gaussian elimination: rank, and a basis of the null space
    let (mut rows, mut piv, mut rr, n) = (rows0.clone(), vec![], 0, rows0[0].len());
    for c in 0..n {
        let b = (rr..rows.len()).fold(rr, |b, i| if rows[i][c].abs() > rows[b][c].abs() { i } else { b });
        if rows[b][c].abs() < 1e-9 { continue; }
        rows.swap(rr, b);
        let pv = rows[rr][c];
        rows[rr] = rows[rr].iter().map(|x| *x / pv).collect();
        for i in 0..rows.len() {
            let f = rows[i][c];
            if i != rr && f.abs() > 0.0 { let top = rows[rr].clone(); rows[i] = rows[i].iter().zip(&top).map(|(x, y)| *x - f * *y).collect(); }
        }
        piv.push(c); rr += 1;
        if rr == rows.len() { break; }
    }
    let mut null = vec![];
    for fc in (0..n).filter(|c| !piv.contains(c)) {
        let mut v = vec![r(0.0); n]; v[fc] = r(1.0);
        for (i, &c) in piv.iter().enumerate() { v[c] = r(0.0) - rows[i][fc]; }
        null.push(v);
    }
    (piv.len(), null)
}
fn commutant(gens: &[M], d: usize) -> Vec<M> { // every d x d matrix T with T G = G T for each G in gens
    let mut rows = vec![];
    for g in gens { for i in 0..d { for j in 0..d {
        let mut row = vec![r(0.0); d * d];
        for t in 0..d { row[i * d + t] = row[i * d + t] + g[t][j]; row[t * d + j] = row[t * d + j] - g[i][t]; }
        rows.push(row);
    } } }
    rank_null(&rows).1.iter().map(|v| (0..d).map(|a| v[a * d..(a + 1) * d].to_vec()).collect()).collect()
}
fn gns(p: f64, e: &[M]) -> (usize, Vec<M>, Vec<C>) {
    let g: M = e.iter().map(|c| e.iter().map(|d| omega(&mul(&star(c), d), p)).collect()).collect();
    let closed: M = (0..4).map(|k| (0..4).map(|l| r(if k == l { [p, 1.0 - p][k % 2] } else { 0.0 })).collect()).collect();
    same(&g, &closed);
    let dim = rank_null(&g).0;
    let basis: Vec<M> = (0..4).filter(|&k| g[k][k].abs() > 1e-12)
        .map(|k| e[k].iter().map(|row| row.iter().map(|x| *x / r(g[k][k].re.sqrt())).collect()).collect()).collect();
    let om: Vec<C> = basis.iter().map(|u| omega(&star(u), p)).collect(); // coordinates of the vector [I]
    (dim, basis, om)
}
fn pi(m: &M, basis: &[M], p: f64) -> M { basis.iter().map(|u| basis.iter().map(|v| omega(&mul(&star(u), &mul(m, v)), p)).collect()).collect() }
fn sandwich(om: &[C], pm: &M) -> C { let d = om.len(); (0..d).fold(r(0.0), |s, u| (0..d).fold(s, |s, v| s + om[u].conj() * pm[u][v] * om[v])) }
fn join(v: &[C]) -> String { v.iter().map(|z| re(*z)).collect::<Vec<_>>().join(", ") }

fn main() {
    // 1. The fair coin's expectation, first on payoffs (diagonal), then on every 2 x 2 matrix.
    let i1 = C { re: 0.0, im: 1.0 };
    let x: M = vec![vec![r(10.0), r(0.0)], vec![r(0.0), r(-6.0)]];
    let s: M = vec![vec![r(0.0), r(1.0)], vec![r(1.0), r(0.0)]];
    let y: M = vec![vec![r(1.0), r(2.0)], vec![i1, r(3.0)]]; // two test matrices
    let z: M = vec![vec![r(0.0), i1], vec![r(2.0), r(-1.0)]];
    let i2: M = vec![vec![r(1.0), r(0.0)], vec![r(0.0), r(1.0)]];
    let (ex, ex2) = (omega(&x, 0.5), omega(&mul(&star(&x), &x), 0.5));
    close(ex, r(0.5 * 10.0 + 0.5 * -6.0)); close(ex2, r(0.5 * 100.0 + 0.5 * 36.0));
    println!("coin, E[X] = {}, E[X^2] = {}, standard deviation = {:.6}", re(ex), re(ex2), (ex2.re - ex.re * ex.re).sqrt());
    println!("state, omega(I) = {}, omega(S) = {}, omega(Y) = {}", re(omega(&i2, 0.5)), re(omega(&s, 0.5)), re(omega(&y, 0.5)));
    for m in [&y, &z] { // positivity, against the closed form p(|a11|^2 + |a21|^2) + (1-p)(|a12|^2 + |a22|^2)
        close(omega(&mul(&star(m), m), 0.5), r(0.5 * m.iter().flatten().map(|c| c.abs().powi(2)).sum::<f64>()));
    }
    let (yy, zz, yz) = (omega(&mul(&star(&y), &y), 0.5), omega(&mul(&star(&z), &z), 0.5), omega(&mul(&star(&y), &z), 0.5));
    assert!(yz.abs().powi(2) <= yy.re * zz.re);
    println!("positive, omega(Y*Y) = {}, omega(Z*Z) = {}, |omega(Y*Z)|^2 = {:.6} <= {:.6}", re(yy), re(zz), yz.abs().powi(2), yy.re * zz.re);
    let rho: M = (0..2).map(|i| (0..2).map(|j| omega(&unit(j, i), 0.5)).collect()).collect(); // rho_ij = omega(E_ji)
    for m in [&x, &s, &y, &z] { let rm = mul(&rho, m); close(rm[0][0] + rm[1][1], omega(m, 0.5)); }
    assert!(rank_null(&rho).0 == 2); // rank 2, so no single vector psi (rho = psi psi*, rank 1) gives the fair coin
    println!("density, rho = [[{}, {}], [{}, {}]], omega(M) = trace(rho M) on 4 tests", re(rho[0][0]), re(rho[0][1]), re(rho[1][0]), re(rho[1][1]));

    // 2. GNS: vectors are matrices, <C, D> = omega(C* D); pi(M) acts by left multiplication.
    let e: Vec<M> = vec![unit(0, 0), unit(0, 1), unit(1, 0), unit(1, 1)]; // order E11, E12, E21, E22
    for (p, want) in [(0.5, (4, 4, 4)), (0.75, (4, 4, 4)), (1.0, (2, 1, 4))] {
        let (dim, basis, om) = gns(p, &e);
        for m in [&x, &s, &y, &z] {
            let pm = pi(m, &basis, p);
            close(sandwich(&om, &pm), omega(m, p));
            same(&pi(&mul(m, &y), &basis, p), &mul(&pm, &pi(&y, &basis, p))); same(&pi(&star(m), &basis, p), &star(&pm));
        }
        let gens: Vec<M> = e.iter().map(|ek| pi(ek, &basis, p)).collect();
        let dim_a = rank_null(&gens.iter().map(|g| g.iter().flatten().cloned().collect()).collect()).0;
        let c1 = commutant(&gens, dim); let c2 = commutant(&c1, dim);
        for g in &gens { for t in &c1 { same(&mul(g, t), &mul(t, g)); } }
        println!("gns, p = {:.2}, dim H = {}, dim pi(A) = {}, dim commutant = {}, dim double commutant = {}", p, dim, dim_a, c1.len(), c2.len());
        assert!((dim, c1.len(), c2.len()) == want && dim_a == c2.len());
    }
    let (_, basis, om) = gns(0.5, &e); // the Bell-pair road: pi(M) = M (x) I and Omega = (e11 + e22)/sqrt 2
    for m in [&x, &s, &y, &z] { same(&pi(m, &basis, 0.5), &kron(m, &i2)); }
    let h = r(1.0 / 2f64.sqrt());
    same(&vec![om.clone()], &vec![vec![h, r(0.0), r(0.0), h]]);
    for t in [kron(&i2, &s), kron(&i2, &y)] { for ek in &e { let pk = pi(ek, &basis, 0.5); same(&mul(&pk, &t), &mul(&t, &pk)); } }
    let (px, ps) = (pi(&x, &basis, 0.5), pi(&s, &basis, 0.5));
    let som: Vec<C> = (0..4).map(|u| (0..4).fold(r(0.0), |acc, v| acc + ps[u][v] * om[v])).collect();
    let sdot = (0..4).fold(r(0.0), |acc, u| acc + om[u].conj() * som[u]);
    let xom: Vec<C> = (0..4).map(|u| (0..4).fold(r(0.0), |acc, v| acc + px[u][v] * om[v])).collect();
    println!("bell, pi(X) Omega = ({}), <Omega, pi(X) Omega> = {}", join(&xom), re((0..4).fold(r(0.0), |acc, u| acc + om[u].conj() * xom[u])));
    println!("bell, pi(S) Omega = ({}), <Omega, pi(S) Omega> = {}", join(&som), re(sdot));
    println!("bell, Omega = ({}), pi(M) = M (x) I on 4 tests, I (x) S and I (x) Y commute with pi", join(&om));

    // 3. What breaks.
    let bad = |m: &M| r(1.5) * m[0][0] - r(0.5) * m[1][1];
    println!("breaks, 1.5 a11 - 0.5 a22: omega(I) = {}, omega(E22* E22) = {}", re(bad(&i2)), re(bad(&mul(&star(&e[3]), &e[3]))));
    let (n12, bad_r) = (omega(&mul(&star(&e[1]), &e[1]), 1.0), mul(&e[1], &e[2]));
    println!("breaks, p = 1, right action: |E12|^2 = {} but |E12 E21|^2 = {}", re(n12), re(omega(&mul(&star(&bad_r), &bad_r), 1.0)));
    let e1 = [r(1.0), r(0.0)];
    let v11 = (0..2).fold(r(0.0), |s, i| (0..2).fold(s, |s, j| s + e1[i].conj() * e[0][i][j] * e1[j]));
    println!("breaks, one vector in C^2 for the fair coin: e1* E11 e1 = {}, omega(E11) = {}", re(v11), re(omega(&e[0], 0.5)));

    // 4. Infinitely many flips: f = 1 if 0.X1X2X3... (binary) < 1/3, f_N reads only the first N flips.
    let mut chart = vec![];
    for n in (2..17).step_by(2) {
        let two: u64 = 1 << n;
        let count = (0..two).filter(|m| 3 * m < two).count() as u64;
        assert!(3 * count == two + 2); // closed form: omega(f_N) = (2^N + 2) / (3 2^N)
        let d2 = (3 * count - two) as f64 / (3 * two) as f64; // f <= f_N, so |f_N - f|^2 = f_N - f
        let below = |k: u64| (3 * k < two) as i64; // f at k / 2^N, and f_N on the prefix k
        let sup = (0..two).map(|m| (below(m) - below(m + 1)).abs()).max().unwrap(); // prefix m runs from m to m + 1, over 2^N
        let w = count - 1; // witness: first N digits spell w, then tails forever: f_N = 1, f = 0
        assert!(sup == 1 && below(w) == 1 && below(w + 1) == 0);
        let dist = d2.sqrt();
        close(r(dist), r((2.0f64 / 3.0).sqrt() * 2f64.powf(-(n as f64) / 2.0)));
        chart.push(format!("{:.3}", dist.log10()));
        println!("flips, N = {}, omega(f_N) = {:.6}, GNS distance = {:.6}, sup distance = {}", n, count as f64 / two as f64, dist, sup);
    }
    println!("chart, log10 GNS distance, N = 2..16 step 2, {}", chart.join(", "));
    println!("ALL CHECKS PASS");
}
