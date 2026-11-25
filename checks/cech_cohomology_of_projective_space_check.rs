// Cech cohomology of O(d) on projective space -- the same check as the Python, in Rust.
// No crates.  P^n has coordinates x_0..x_n and the cover U_i = {x_i != 0}.
// A section of O(d) over the overlap U_I is a sum of Laurent monomials x^a of degree d
// (exponents add to d) with a_j >= 0 for every j outside I.  The code keeps the
// exponents in the box [-B, B]: the complex splits monomial by monomial, so the box
// loses nothing that lies inside it.
use std::collections::{BTreeMap, HashMap};

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
    fn div(self, o: Q) -> Q { self.mul(Q::new(o.d, o.n)) }
    fn sub(self, o: Q) -> Q {
        Q::new(self.n.checked_mul(o.d).unwrap() - o.n.checked_mul(self.d).unwrap(), self.d.checked_mul(o.d).unwrap())
    }
}
impl std::fmt::Display for Q {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        if self.d == 1 { write!(f, "{}", self.n) } else { write!(f, "{}/{}", self.n, self.d) }
    }
}

type Col = BTreeMap<usize, Q>;
fn rank(columns: &[Col]) -> usize {        // exact rank over Q, sparse elimination
    let mut pivots: HashMap<usize, Col> = HashMap::new();
    for col in columns {
        let mut v = col.clone();
        while let Some((&r, _)) = v.iter().next() {
            let p = match pivots.get(&r) { None => { pivots.insert(r, v); break } Some(p) => p };
            let f = v[&r].div(p[&r]);
            for (&k, &x) in p.iter() {
                let y = v.get(&k).copied().unwrap_or(Q::int(0)).sub(f.mul(x));
                if y.n != 0 { v.insert(k, y); } else { v.remove(&k); }
            }
        }
    }
    pivots.len()
}

fn product(lo: i64, hi: i64, m: usize) -> Vec<Vec<i64>> {   // every vector in [lo, hi)^m
    let mut out = vec![vec![]];
    for _ in 0..m { out = out.iter().flat_map(|v| (lo..hi).map(move |x| { let mut w = v.clone(); w.push(x); w })).collect() }
    out
}
fn combinations(opens: &[usize], k: usize) -> Vec<Vec<usize>> {
    if k == 0 { return vec![vec![]] }
    if opens.len() < k { return vec![] }
    let mut out: Vec<Vec<usize>> = combinations(&opens[1..], k - 1).into_iter().map(|mut c| { c.insert(0, opens[0]); c }).collect();
    out.extend(combinations(&opens[1..], k));
    out
}

struct Cech { dims: Vec<usize>, h: Vec<i64>, deltas: Vec<Vec<Col>>, index: Vec<HashMap<(Vec<usize>, Vec<i64>), usize>> }

fn cech(m: usize, d: i64, b: i64, opens: Option<Vec<usize>>, signed: bool) -> Cech {
    let opens = opens.unwrap_or((0..m).collect());
    let mons: Vec<Vec<i64>> = product(-b, b + 1, m).into_iter().filter(|a| a.iter().sum::<i64>() == d).collect();
    let faces: Vec<Vec<Vec<usize>>> = (0..opens.len()).map(|p| combinations(&opens, p + 1)).collect();
    let basis: Vec<Vec<(Vec<usize>, Vec<i64>)>> = faces.iter().map(|f| {
        let mut out = vec![];
        for i in f { for a in &mons { if (0..m).all(|j| i.contains(&j) || a[j] >= 0) { out.push((i.clone(), a.clone())) } } }
        out
    }).collect();
    let index: Vec<HashMap<(Vec<usize>, Vec<i64>), usize>> =
        basis.iter().map(|bs| bs.iter().enumerate().map(|(k, e)| (e.clone(), k)).collect()).collect();
    let mut deltas = vec![];                   // delta^p as a list of sparse columns
    for p in 0..faces.len() - 1 {
        let mut cols = vec![];
        for (i, a) in &basis[p] {
            let mut col = Col::new();
            for j in &faces[p + 1] {
                if i.iter().all(|x| j.contains(x)) {   // J = I plus one index, at position pos
                    let pos = j.iter().position(|x| !i.contains(x)).unwrap();
                    let s = if !signed || pos % 2 == 0 { 1 } else { -1 };
                    col.insert(index[p + 1][&(j.clone(), a.clone())], Q::int(s));
                }
            }
            cols.push(col);
        }
        deltas.push(cols);
    }
    let dims: Vec<usize> = basis.iter().map(|x| x.len()).collect();
    let mut rk: Vec<i64> = deltas.iter().map(|c| rank(c) as i64).collect();
    rk.push(0);
    let h = (0..dims.len()).map(|p| dims[p] as i64 - rk[p] - if p > 0 { rk[p - 1] } else { 0 }).collect();
    Cech { dims, h, deltas, index }
}

fn sign_count(m: usize, d: i64) -> (i64, i64) {   // road two: count monomials by their signs
    let top = product(0, d.max(-1) + 1, m).iter().filter(|a| a.iter().sum::<i64>() == d).count() as i64;
    let low = product(d, 0, m).iter().filter(|a| a.iter().sum::<i64>() == d).count() as i64;
    (top, low)
}
fn comb(n: i64, k: i64) -> i64 { if k < 0 || n < k { 0 } else { (0..k).fold(1, |acc, i| acc * (n - i) / (i + 1)) } }
fn formula(n: i64, d: i64) -> (i64, i64) {        // road three: the binomial counts
    (if d >= 0 { comb(d + n, n) } else { 0 }, if d <= -n - 1 { comb(-d - 1, n) } else { 0 })
}
fn hilbert(n: i64, d: i64) -> Q {                 // road four: Euler characteristic, a polynomial in d
    (1..=n).fold(Q::int(1), |v, i| v.mul(Q::new((d + i) as i128, i as i128)))
}

fn main() {
    let mut table: HashMap<(i64, i64), Vec<i64>> = HashMap::new();
    let runs: [(i64, i64, Vec<i64>); 3] = [(1, 6, (-4..4).collect()), (2, 5, (-5..3).collect()), (3, 4, vec![-5, -4, 0, 1])];
    for (n, b, ds) in runs.iter() {
        for &d in ds {
            let c = cech(*n as usize + 1, d, *b, None, true);
            let chi: i64 = c.dims.iter().enumerate().map(|(p, &x)| if p % 2 == 0 { x as i64 } else { -(x as i64) }).sum();
            println!("P^{} O({:2}): box {}, cochain dims {:?}; h = {:?}; signs (h^0, h^{}) = {:?}; formula {:?}; Euler {} = Hilbert {}",
                     n, d, b, c.dims, c.h, n, sign_count(*n as usize + 1, d), formula(*n, d), chi, hilbert(*n, d));
            assert!((c.h[0], c.h[*n as usize]) == sign_count(*n as usize + 1, d) && sign_count(*n as usize + 1, d) == formula(*n, d));
            assert!(c.h[1..*n as usize].iter().all(|&x| x == 0) && Q::int(chi as i128) == hilbert(*n, d));
            table.insert((*n, d), c.h);
        }
    }
    let c = cech(2, -2, 6, None, true);
    let words: Vec<String> = (-4..3i64).map(|k| {
        let a = (-2 - k, k);                       // x^-2 t^k = x^(-2-k) y^k on the overlap, t = y/x
        format!("t^{} {}", k, if a.1 >= 0 { "U_x" } else if a.0 >= 0 { "U_y" } else { "neither" })
    }).collect();
    println!("O(-2) on P^1, overlap term x^-2 t^k, t = y/x: {}", words.join(", "));
    let im = rank(&c.deltas[0]);
    for (a, name) in [(vec![-1i64, -1], "1/(xy)"), (vec![-3, 1], "y/x^3")] {
        let mut v = Col::new();
        v.insert(c.index[1][&(vec![0, 1], a.clone())], Q::int(1));
        let mut cols = c.deltas[0].clone();
        cols.push(v);
        let with = rank(&cols);
        println!("cocycle {}: rank of coboundaries {}, with it added {}; a coboundary: {}", name, im, with, if with == im { "yes" } else { "no" });
        assert!((with == im) == (a != vec![-1, -1]));   // only 1/(xy) is a real class
    }
    for n in [1i64, 2] {                            // Serre duality: h^n(O(d)) = h^0(O(-n-1-d))
        let pairs: Vec<(i64, i64, i64)> = (-n - 3..1).filter(|d| table.contains_key(&(n, -n - 1 - d)))
            .map(|d| (d, table[&(n, d)][n as usize], table[&(n, -n - 1 - d)][0])).collect();
        println!("duality on P^{}, (d, h^{}(O(d)), h^0(O({}-d))): {:?}", n, n, -n - 1, pairs);
        assert!(pairs.iter().all(|&(_, x, y)| x == y));
    }
    let genus: Vec<(i64, i64, i64)> = (1..6).map(|e| (e, table[&(2, -e)][2], (e - 1) * (e - 2) / 2)).collect();
    println!("plane curve of degree e: (e, h^2(P^2, O(-e)), (e-1)(e-2)/2) = {:?}", genus);
    assert!(genus.iter().all(|&(_, x, y)| x == y));
    let betti: Vec<i64> = (0..5).map(|k| if k % 2 == 0 { 1 } else { 0 }).collect();   // one cell in each even real dimension
    println!("P^2: Betti numbers {:?}; h^q(O) for q = 0, 1, 2: {:?}", betti, table[&(2, 0)]);
    let hu = cech(3, 0, 5, None, false).h;
    let h2u = cech(3, 2, 5, None, false).h;
    println!("mistake 1, no signs in delta: h^0(P^2, O) = {}, h^0(P^2, O(2)) = {}", hu[0], h2u[0]);
    let miss: Vec<i64> = [3, 5].iter().map(|&b| cech(3, 0, b, Some(vec![0, 1]), true).h[1]).collect();
    println!("mistake 2, only U_x and U_y on P^2: h^1(O) = {} in box 3, {} in box 5", miss[0], miss[1]);
    println!("mistake 3, cocycles not divided by coboundaries, O(-2) on P^1: {} in box 6, {} in box 9; classes {}",
             c.dims[1], cech(2, -2, 9, None, true).dims[1], c.h[1]);
    println!("mistake 4, O(2) for O(-2) on P^1: h = {:?} against {:?}", table[&(1, 2)], table[&(1, -2)]);
    assert!(hu[0] == 0 && h2u[0] == 0 && miss[0] < miss[1] && c.dims[1] as i64 > c.h[1] && c.h[1] == 1);
    for d in [2i64, -4] {
        let (lo, hi) = if d >= 0 { (0, d + 1) } else { (d, 0) };
        let mut dots: Vec<(i64, i64)> = product(lo, hi, 3).iter().filter(|a| a.iter().sum::<i64>() == d).map(|a| (a[0], a[1])).collect();
        dots.sort();
        println!("figure, d = {}: (a, b) of the classes x^a y^b z^c, c = d - a - b: {:?}", d, dots);
    }
    println!("ALL CHECKS PASS");
}
