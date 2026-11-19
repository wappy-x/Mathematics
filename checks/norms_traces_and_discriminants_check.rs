// Norm, trace and discriminant -- the same check as the Python, in Rust.  No
// crates.  Road 1 multiplies an element's matrix exactly (a small fraction
// type); road 2 plugs it into every complex embedding (a small complex type;
// rounded to 5 places); road 3 uses the closed formulas a^2 + 5b^2, 2a and the
// polynomial discriminant.  A brute-force search in Z[sqrt-5] backs the norm test.
use std::ops::{Add, Mul, Sub};

fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }

#[derive(Clone, Copy, PartialEq, Debug)]
struct Fr { n: i128, d: i128 }
fn fr(n: i128, d: i128) -> Fr { let g = gcd(n, d).max(1) * d.signum(); Fr { n: n / g, d: d / g } }
impl Add for Fr { type Output = Fr; fn add(self, o: Fr) -> Fr { fr(self.n.checked_mul(o.d).unwrap().checked_add(o.n.checked_mul(self.d).unwrap()).unwrap(), self.d.checked_mul(o.d).unwrap()) } }
impl Sub for Fr { type Output = Fr; fn sub(self, o: Fr) -> Fr { fr(self.n.checked_mul(o.d).unwrap().checked_sub(o.n.checked_mul(self.d).unwrap()).unwrap(), self.d.checked_mul(o.d).unwrap()) } }
impl Mul for Fr { type Output = Fr; fn mul(self, o: Fr) -> Fr { fr(self.n.checked_mul(o.n).unwrap(), self.d.checked_mul(o.d).unwrap()) } }
impl std::fmt::Display for Fr {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        if self.d == 1 { write!(f, "{}", self.n) } else { write!(f, "{}/{}", self.n, self.d) }
    }
}

#[derive(Clone, Copy, Debug)]
struct Cx { re: f64, im: f64 }
impl Add for Cx { type Output = Cx; fn add(self, o: Cx) -> Cx { Cx { re: self.re + o.re, im: self.im + o.im } } }
impl Sub for Cx { type Output = Cx; fn sub(self, o: Cx) -> Cx { Cx { re: self.re - o.re, im: self.im - o.im } } }
impl Mul for Cx {
    type Output = Cx;
    fn mul(self, o: Cx) -> Cx { Cx { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
}

// Laplace expansion: works for fractions and complex numbers
fn det<T: Copy + Add<Output = T> + Sub<Output = T> + Mul<Output = T>>(m: &Vec<Vec<T>>) -> T {
    if m.len() == 1 { return m[0][0]; }
    let mut out: Option<T> = None;
    for j in 0..m.len() {
        let minor: Vec<Vec<T>> = m[1..].iter().map(|r| [&r[..j], &r[j + 1..]].concat()).collect();
        let t = m[0][j] * det(&minor);
        out = Some(match out { None => if j % 2 == 0 { t } else { t - t - t }, Some(s) => if j % 2 == 0 { s + t } else { s - t } });
    }
    out.unwrap()
}

type V = Vec<Fr>;
fn iv(xs: &[i128]) -> V { xs.iter().map(|&x| fr(x, 1)).collect() }
fn mat_of(x: &V, p: &[i128]) -> Vec<V> {  // road 1: the matrix of "multiply by x"
    let n = p.len();
    let c: Vec<V> = (0..n).map(|r| (0..n).map(|k| if k == n - 1 { fr(p[r], 1) } else { fr((r == k + 1) as i128, 1) }).collect()).collect();
    let mut m = vec![vec![fr(0, 1); n]; n];
    let mut pw: Vec<V> = (0..n).map(|i| (0..n).map(|j| fr((i == j) as i128, 1)).collect()).collect();
    for &ci in x {
        for i in 0..n { for j in 0..n { m[i][j] = m[i][j] + ci * pw[i][j]; } }
        pw = (0..n).map(|i| (0..n).map(|j| (0..n).fold(fr(0, 1), |s, k| s + c[i][k] * pw[k][j])).collect()).collect();
    }
    m
}
fn mul(x: &V, y: &V, p: &[i128]) -> V {
    let m = mat_of(x, p);
    (0..p.len()).map(|i| (0..p.len()).fold(fr(0, 1), |s, k| s + m[i][k] * y[k])).collect()
}
fn norm(x: &V, p: &[i128]) -> Fr { det(&mat_of(x, p)) }
fn trace(x: &V, p: &[i128]) -> Fr { let m = mat_of(x, p); (0..p.len()).fold(fr(0, 1), |s, i| s + m[i][i]) }
fn gram(b: &Vec<V>, p: &[i128]) -> Vec<V> { b.iter().map(|u| b.iter().map(|v| trace(&mul(u, v, p), p)).collect()).collect() }
fn disc(b: &Vec<V>, p: &[i128]) -> Fr { det(&gram(b, p)) }
fn embed(x: &V, r: Cx) -> Cx {
    let (mut s, mut pw) = (Cx { re: 0.0, im: 0.0 }, Cx { re: 1.0, im: 0.0 });
    for c in x { s = s + Cx { re: c.n as f64 / c.d as f64, im: 0.0 } * pw; pw = pw * r; }
    s
}
fn embed_mat(b: &Vec<V>, roots: &[Cx]) -> Vec<Vec<Cx>> { roots.iter().map(|&r| b.iter().map(|w| embed(w, r)).collect()).collect() }
fn prod(zs: &[Cx]) -> Cx { zs.iter().fold(Cx { re: 1.0, im: 0.0 }, |s, &z| s * z) }
fn sum(zs: &[Cx]) -> Cx { zs.iter().fold(Cx { re: 0.0, im: 0.0 }, |s, &z| s + z) }
fn cl(v: f64) -> f64 { if (v * 1e5).round() == 0.0 { 0.0 } else { v } }
fn fl(v: f64) -> String { format!("{:.5}", cl(v)) }
fn fc(z: Cx) -> String { format!("{:.5} {} {:.5}i", cl(z.re), if cl(z.im) < 0.0 { "-" } else { "+" }, cl(z.im).abs()) }
fn vecs(x: &V) -> String { format!("[{}]", x.iter().map(|c| c.to_string()).collect::<Vec<_>>().join(", ")) }
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn divides(y: (i128, i128), x: (i128, i128)) -> bool {  // y | x: x times conj(y) over N(y) is whole
    let n = y.0 * y.0 + 5 * y.1 * y.1;
    n != 0 && (x.0 * y.0 + 5 * x.1 * y.1) % n == 0 && (x.1 * y.0 - x.0 * y.1) % n == 0
}

fn main() {
    let (m5, c2, p5): (&[i128], &[i128], &[i128]) = (&[-5, 0], &[2, 0, 0], &[5, 0]);
    let s5 = 5f64.sqrt();
    let r5 = [Cx { re: 0.0, im: s5 }, Cx { re: 0.0, im: -s5 }];
    let c = 2f64.powf(1.0 / 3.0);
    let pi = std::f64::consts::PI;
    let r2: Vec<Cx> = (0..3).map(|k| { let t = 2.0 * pi * k as f64 / 3.0; Cx { re: c * t.cos(), im: c * t.sin() } }).collect();
    let alpha = iv(&[1, 1]);
    let conj: Vec<Cx> = r5.iter().map(|&r| embed(&alpha, r)).collect();
    let (n_mat, t_mat) = (norm(&alpha, m5), trace(&alpha, m5));
    let (n_cnj, t_cnj) = (prod(&conj), sum(&conj));
    let (n_frm, t_frm) = (1 * 1 + 5 * 1 * 1, 2 * 1);
    let sq = mul(&alpha, &alpha, m5);
    let minpoly_at: V = (0..2).map(|i| sq[i] - t_mat * alpha[i] + if i == 0 { n_mat } else { fr(0, 1) }).collect();
    println!("field Q(sqrt-5), theta^2 = -5; alpha = 1 + sqrt-5, written [1, 1] on the basis 1, sqrt-5");
    println!("conjugates of alpha: {} and {}", fc(conj[0]), fc(conj[1]));
    println!("N(alpha): product of conjugates {}; matrix determinant {}; a^2 + 5b^2 = {}", fc(n_cnj), n_mat, n_frm);
    println!("Tr(alpha): sum of conjugates {}; matrix trace {}; 2a = {}", fc(t_cnj), t_mat, t_frm);
    println!("matrix of multiply-by-alpha: [{}]", mat_of(&alpha, m5).iter().map(vecs).collect::<Vec<_>>().join(", "));
    println!("alpha squared {}; alpha^2 - {} alpha + {} = {}", vecs(&sq), t_mat, n_mat, vecs(&minpoly_at));
    let named: Vec<(&str, (i128, i128))> = vec![("2", (2, 0)), ("3", (3, 0)), ("1 + sqrt-5", (1, 1)), ("1 - sqrt-5", (1, -1))];
    let nq = |x: (i128, i128)| x.0 * x.0 + 5 * x.1 * x.1;
    let ns: Vec<String> = named.iter().map(|(_, x)| norm(&iv(&[x.0, x.1]), m5).to_string()).collect();
    println!("norms of {}: {}", named.iter().map(|(s, _)| *s).collect::<Vec<_>>().join(", "), ns.join(", "));
    let bx: Vec<(i128, i128)> = (-10..11).flat_map(|a| (-10..11).map(move |b| (a, b))).collect();
    let mut values: Vec<i128> = bx.iter().map(|&x| nq(x)).filter(|&n| n <= 30).collect();
    values.sort(); values.dedup();
    let cnt = |n: i128| bx.iter().filter(|&&x| nq(x) == n).count();
    let counts: Vec<usize> = [1, 2, 3, 4, 6, 9].iter().map(|&n| cnt(n)).collect();
    println!("norm values up to 30: {:?}", values);
    println!("elements of norm 1, 2, 3, 4, 6, 9: {}", counts.iter().map(|k| k.to_string()).collect::<Vec<_>>().join(", "));
    let small: Vec<(i128, i128)> = (-6..7).flat_map(|a| (-6..7).map(move |b| (a, b))).collect();
    let good = small.iter().all(|&(a, b)| small.iter().all(|&(c, d)| nq((a * c - 5 * b * d, a * d + b * c)) == nq((a, b)) * nq((c, d))));
    println!("N(xy) = N(x)N(y) on all {} pairs with |a|, |b| <= 6: {}", small.len() * small.len(), yn(good));
    let proper: Vec<usize> = named.iter().map(|&(_, x)| bx.iter().filter(|&&y| 1 < nq(y) && nq(y) < nq(x) && divides(y, x)).count()).collect();
    println!("proper divisors found by search: {}", named.iter().zip(&proper).map(|((s, _), k)| format!("of {}: {}", s, k)).collect::<Vec<_>>().join("; "));
    println!("2 divides 1 + sqrt-5: {}; 3 divides 1 + sqrt-5: {}", yn(divides((2, 0), (1, 1))), yn(divides((3, 0), (1, 1))));
    let (beta, cof) = (iv(&[1, 1, 0]), iv(&[1, -1, 1]));
    let conj3: Vec<Cx> = r2.iter().map(|&r| embed(&beta, r)).collect();
    let nb = norm(&beta, c2);
    println!("field Q(cbrt 2), theta^3 = 2; beta = 1 + cbrt2, written [1, 1, 0]");
    println!("conjugates of beta: {}", conj3.iter().map(|&z| fc(z)).collect::<Vec<_>>().join("; "));
    println!("N(beta): product {}; determinant {}; -f(-1) = {}", fc(prod(&conj3)), nb, -(-1 - 2));
    println!("Tr(beta): sum {}; trace {}", fc(sum(&conj3)), trace(&beta, c2));
    println!("(1 + cbrt2)(1 - cbrt2 + cbrt4) = {}", vecs(&mul(&beta, &cof, c2)));
    let r5r = [Cx { re: s5, im: 0.0 }, Cx { re: -s5, im: 0.0 }];
    let fields: Vec<(&str, Vec<V>, &[i128], &[Cx], i128)> = vec![
        ("Q(sqrt-5), basis 1, sqrt-5", vec![iv(&[1, 0]), iv(&[0, 1])], m5, &r5, 0 - 4 * 5),
        ("Q(cbrt 2), basis 1, cbrt2, cbrt4", vec![iv(&[1, 0, 0]), iv(&[0, 1, 0]), iv(&[0, 0, 1])], c2, &r2, -4 * 0 - 27 * 4),
        ("Q(sqrt 5), basis 1, (1 + sqrt5)/2", vec![iv(&[1, 0]), vec![fr(1, 2), fr(1, 2)]], p5, &r5r, 0 + 4 * 5)];
    let mut ds: Vec<(Fr, Cx, i128)> = vec![];
    for (name, basis, p, roots, polyd) in &fields {
        let (d, e) = (disc(basis, p), det(&embed_mat(basis, roots)));
        ds.push((d, e * e, *polyd));
        println!("d_K for {}: Tr(w_i w_j) = [{}]", name, gram(basis, p).iter().map(vecs).collect::<Vec<_>>().join(", "));
        println!("    its determinant {}; embeddings squared {}; polynomial formula {}", d, fc(e * e), polyd);
    }
    let primes: Vec<Vec<i128>> = ds.iter().map(|(d, _, _)| (2..=d.n.abs()).filter(|&q| d.n % q == 0 && (2..q).all(|s| q % s != 0)).collect()).collect();
    println!("primes dividing -20: {:?}; -108: {:?}; 5: {:?}", primes[0], primes[1], primes[2]);
    let wrong5 = disc(&vec![iv(&[1, 0]), iv(&[0, 1])], p5);
    let quot: V = mul(&alpha, &alpha, m5).iter().map(|&v| v * fr(1, 6)).collect();
    let half = det(&embed_mat(&vec![iv(&[1, 0]), iv(&[0, 1])], &r5));
    println!("mistake 1, the Gaussian norm a^2 + b^2 on 1 + sqrt-5: {}, not {}", 1 + 1, n_mat);
    println!("mistake 2, beta times its complex conjugate only: {}, not a whole number", fl((conj3[1] * conj3[2]).re));
    println!("mistake 3, Z[sqrt5] taken for the ring of integers: {}, not {}; ratio {}", wrong5, ds[2].0, fr(wrong5.n * ds[2].0.d, wrong5.d * ds[2].0.n));
    println!("mistake 4, N(1 - sqrt-5) = 6 divides 6, yet (1 + sqrt-5)/(1 - sqrt-5) = {}, not whole", vecs(&quot));
    println!("mistake 5, the embedding determinant not squared: {}", fc(half));
    let on: Vec<usize> = [2, 3, 4, 6, 9].iter().map(|&n| cnt(n)).collect();
    println!("figure, 50 px per unit, rows at b*sqrt5 = {}; radii {}, {}, 2, {}, 3; lattice points on them {:?}",
             fl(s5), fl(2f64.sqrt()), fl(3f64.sqrt()), fl(6f64.sqrt()), on);
    assert!(n_mat == fr(n_frm, 1) && n_cnj.re.round() == 6.0 && t_mat == fr(t_frm, 1) && t_cnj.re.round() == 2.0);
    assert!(minpoly_at == iv(&[0, 0]) && nb == fr(3, 1) && prod(&conj3).re.round() == 3.0);
    assert!(mul(&beta, &cof, c2) == iv(&[3, 0, 0]) && good && values[..5] == [0, 1, 4, 5, 6]);
    assert!(counts == vec![2, 0, 0, 2, 4, 6] && proper == vec![0, 0, 0, 0] && !divides((2, 0), (1, 1)) && divides((1, 1), (-4, 2)));
    assert!(ds.iter().all(|(d, e, _)| d.d == 1 && d.n as f64 == e.re.round()));
    assert!(ds.iter().map(|x| x.0.n).collect::<Vec<_>>() == vec![-20, -108, 5] && ds.iter().map(|x| x.2).collect::<Vec<_>>() == vec![-20, -108, 20]);
    assert!(wrong5 == fr(4 * ds[2].0.n, 1) && quot == vec![fr(-2, 3), fr(1, 3)] && half.re.abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
