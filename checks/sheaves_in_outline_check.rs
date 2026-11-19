// Sheaves in outline -- the same check as the Python, in Rust.  No crates.
// The space is the projective line P^1, covered by two charts: U0 with
// coordinate t, and U1 with coordinate s, overlapping where s = 1/t.  A section
// over U0 is a polynomial f(t), over U1 a polynomial g(s); both restrict to the
// overlap as Laurent polynomials in t (powers of t from -12 to 12, as a list).
// The twist d sets the gluing rule f(t) = t^d g(1/t); d = 0 is the sheaf O.
// flip=false glues by s = t instead: the wrong rule, for "What breaks".
const LO: i64 = -12;
const HI: i64 = 12;
const W: usize = (HI - LO + 1) as usize;

#[derive(Clone, Copy, PartialEq, Debug)]
struct Q { n: i128, d: i128 }              // a fraction in lowest terms, d > 0

fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }

impl Q {
    fn new(n: i128, d: i128) -> Q {
        let g = gcd(n, d).max(1);
        let s = if d < 0 { -1 } else { 1 };
        Q { n: s * n / g, d: s * d / g }
    }
    fn int(n: i128) -> Q { Q { n, d: 1 } }
    fn mul(self, o: Q) -> Q { Q::new(self.n.checked_mul(o.n).unwrap(), self.d.checked_mul(o.d).unwrap()) }
    fn add(self, o: Q) -> Q {
        Q::new(self.n.checked_mul(o.d).unwrap() + o.n.checked_mul(self.d).unwrap(),
               self.d.checked_mul(o.d).unwrap())
    }
    fn neg(self) -> Q { Q { n: -self.n, d: self.d } }
    fn inv(self) -> Q { Q::new(self.d, self.n) }
}

impl std::fmt::Display for Q {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        if self.d == 1 { write!(f, "{}", self.n) } else { write!(f, "{}/{}", self.n, self.d) }
    }
}

fn from_u0(f: &[i64]) -> Vec<i64> {        // restrict f(t) to the overlap
    let mut out = vec![0; W];
    for (i, &c) in f.iter().enumerate() { out[(i as i64 - LO) as usize] += c }
    out
}

fn from_u1(g: &[i64], d: i64, flip: bool) -> Vec<i64> {   // restrict g(s), s = 1/t, times t^d
    let mut out = vec![0; W];
    for (j, &c) in g.iter().enumerate() {
        let e = if flip { d - j as i64 } else { d + j as i64 };
        out[(e - LO) as usize] += c;
    }
    out
}

fn rank(mut rows: Vec<Vec<Q>>) -> usize {  // Gaussian elimination over Q, exact
    let mut r = 0;
    for col in 0..rows[0].len() {
        let piv = match (r..rows.len()).find(|&i| rows[i][col].n != 0) { Some(p) => p, None => continue };
        rows.swap(r, piv);
        for i in 0..rows.len() {
            if i != r && rows[i][col].n != 0 {
                let k = rows[i][col].mul(rows[r][col].inv());
                let pivot_row = rows[r].clone();
                for (x, y) in rows[i].iter_mut().zip(pivot_row.iter()) { *x = x.add(k.mul(*y).neg()) }
            }
        }
        r += 1;
    }
    r
}

fn unit(i: usize) -> Vec<i64> { (0..=i).map(|k| if k == i { 1 } else { 0 }).collect() }

fn glue_road(n: usize, d: i64, flip: bool) -> (usize, usize) {   // road one: rank
    let mut cols: Vec<Vec<i64>> = (0..=n).map(|i| from_u0(&unit(i))).collect();
    for j in 0..=n { cols.push(from_u1(&unit(j), d, flip).iter().map(|x| -x).collect()) }
    let used: Vec<usize> = (0..W).filter(|&e| cols.iter().any(|c| c[e] != 0)).collect();
    let window = used[0]..=used[used.len() - 1];   // every power of t between the extremes
    let rows: Vec<Vec<Q>> = window.clone().map(|e| cols.iter().map(|c| Q::int(c[e] as i128)).collect()).collect();
    let rk = rank(rows);
    (2 * (n + 1) - rk, window.count() - rk)        // (glued sections, terms never reached)
}

fn polys(p: i64, n: usize) -> Vec<Vec<i64>> {      // every polynomial of degree <= n over F_p
    (0..p.pow(n as u32 + 1)).map(|code| (0..=n).map(|k| code / p.pow(k as u32) % p).collect()).collect()
}

fn brute_road(p: i64, n: usize, d: i64) -> i64 {   // road two: test every pair, mod p
    let mut hits = 0;
    let all = polys(p, n);
    for f in &all {
        let left: Vec<i64> = from_u0(f).iter().map(|x| x.rem_euclid(p)).collect();
        for g in &all {
            if left == from_u1(g, d, true).iter().map(|x| x.rem_euclid(p)).collect::<Vec<i64>>() { hits += 1 }
        }
    }
    hits
}

fn components(mut iv: Vec<(i64, i64)>) -> usize {  // open intervals: count connected pieces
    iv.sort();
    let (mut pieces, mut end): (usize, Option<i64>) = (0, None);
    for (a, b) in iv {
        if end.map_or(true, |e| a >= e) { pieces += 1 }
        end = Some(end.map_or(b, |e| e.max(b)));
    }
    pieces
}

fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }

fn f(t: i64) -> i64 { 3 + 2 * t }                  // a section over U0
fn g(s: Q) -> Q { Q::int(3).mul(s).add(Q::int(2)).mul(s.inv()) }   // the same, in s

fn main() {
    let (n, p, bn) = (6usize, 5i64, 2usize);
    println!("P^1 = U0 (coordinate t) and U1 (coordinate s), overlap s = 1/t");
    for t in [2, 10, 100, 1000] {
        println!("t = {}: f = 3 + 2t = {}; s = 1/{}: (3s + 2)/s = {}", t, f(t), t, g(Q::new(1, t as i128)));
    }
    println!("at s = 0, the point at infinity: (3s + 2)/s has denominator 0, so 3 + 2t is not global");
    println!("constant 3 on U0 glues with constant 3 on U1: {}", yn(from_u0(&[3]) == from_u1(&[3], 0, true)));
    let q2 = [1, 4, 1];                             // twist 2: f = 1 + 4t + t^2, g = 1 + 4s + s^2
    println!("twist 2: 1 + 4t + t^2 glues with 1 + 4s + s^2: {}", yn(from_u0(&q2) == from_u1(&q2, 2, true)));
    let mut table = Vec::new();
    for d in -2..4i64 {
        let (k, left) = glue_road(n, d, true);
        table.push((d, k, left));
        println!("twist d = {:2}: glued sections up to degree {}: {}; Laurent terms never reached: {}; formula max(d + 1, 0) = {}",
                 d, n, k, left, (d + 1).max(0));
    }
    let mut counts = Vec::new();
    for d in -2..3i64 {
        let c = brute_road(p, bn, d);
        counts.push((d, c));
        println!("over F_{}, degree <= {}, twist {:2}: {} of {} pairs glue", p, bn, d, c, p.pow(2 * bn as u32 + 2));
    }
    let only_u0 = n + 1;
    let (same_t, _) = glue_road(n, 0, false);
    println!("mistake 1, chart U0 alone: {} independent sections up to degree {}, one more per degree", only_u0, n);
    println!("mistake 2, overlap never checked: {} free coefficients up to degree {}; {} pairs over F_{}",
             2 * (n + 1), n, p.pow(2 * bn as u32 + 2), p);
    println!("mistake 3, charts glued by s = t: {} glued sections up to degree {}", same_t, n);
    println!("mistake 4, 3 + 2t read as global: f(1000) = {}, and no value at s = 0", f(1000));
    println!("sections up to degree {}: chart U0 {}; overlap, powers -{} to {}: {}", n, n + 1, n, n, 2 * n + 1);
    let line = p + 1;                                            // (1 : t) for each t, and infinity
    let mut scaled: Vec<(i64, i64)> = Vec::new();
    for a in 0..p { for b in 0..p { if (a, b) != (0, 0) {
        let r = (1..p).map(|c| (a * c % p, b * c % p)).min().unwrap();
        if !scaled.contains(&r) { scaled.push(r) }
    } } }
    let u0: Vec<i64> = (0..p).collect();                         // the points (1 : t) of U0 over F_5
    let same = u0.iter().all(|&x| x.pow(p as u32) % p == x);
    println!("points of P^1 over F_{}: {}; t^{} and t agree at each of the {} points of U0 over F_{}: {}", p, line, p, u0.len(), p, yn(same));
    let pieces = components(vec![(0, 1), (2, 3)]);
    let one = rank(vec![vec![Q::int(1)]; pieces]);               // one constant c restricts to (c, c): rank 1
    println!("constants on (0, 1) and (2, 3): {} free value; sections that glue: {}", one, pieces);
    let kernel = |d: i64| table.iter().find(|r| r.0 == d).unwrap();
    assert!(counts.iter().all(|&(d, c)| c == p.pow(kernel(d).1 as u32)));           // rank against brute force
    assert!(table.iter().all(|&(d, k, _)| k as i64 == (d + 1).max(0)));             // rank against the formula
    assert!(kernel(-2).2 == 1 && kernel(0).2 == 0);                                 // the gap at t^-1 only
    assert!(same_t == n + 1 && pieces == 2 && one == 1 && same && scaled.len() as i64 == line);
    assert!([2, 10, 100, 1000].iter().all(|&t| g(Q::new(1, t)) == Q::int(f(t as i64) as i128)));
    assert!(from_u0(&[3]) == from_u1(&[3], 0, true) && from_u0(&q2) == from_u1(&q2, 2, true));   // the glued examples
    println!("ALL CHECKS PASS");
}
