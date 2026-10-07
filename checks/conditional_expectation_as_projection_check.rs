// Conditional expectation as a projection -- the check behind the card.
// Std only; exact fractions are done by hand on i128.  A month at the station
// is one of 8 equally likely outcomes: a season and a dry or wet year, 10 mm
// below or above that season's mean.  What is known, G, is the season.  The
// forecast E[X | G] is found by two roads that share no arithmetic: averaging
// each season's cell, and least squares on the features 1, T, T^2, T^3
// (T the season's temperature), solved by Gaussian elimination.
use std::fmt;
use std::ops::{Add, Div, Mul, Sub};

#[derive(Clone, Copy, PartialEq, Debug)]
struct Q { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q {
    let g = gcd(n, d).max(1); let s = if d < 0 { -1 } else { 1 };
    Q { n: s * n / g, d: s * d / g }
}
fn z(n: i128) -> Q { q(n, 1) }
impl Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.n * o.d + o.n * self.d, self.d * o.d) } }
impl Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { q(self.n * o.d - o.n * self.d, self.d * o.d) } }
impl Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.n * o.n, self.d * o.d) } }
impl Div for Q { type Output = Q; fn div(self, o: Q) -> Q { q(self.n * o.d, self.d * o.n) } }
impl PartialOrd for Q {
    fn partial_cmp(&self, o: &Q) -> Option<std::cmp::Ordering> { (self.n * o.d).partial_cmp(&(o.n * self.d)) }
}
impl fmt::Display for Q {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        let s = if self.d == 1 { format!("{}", self.n) } else { format!("{}/{}", self.n, self.d) };
        f.pad(&s)
    }
}
impl Q { fn f(self) -> f64 { self.n as f64 / self.d as f64 } }

const NAME: [&str; 4] = ["winter", "spring", "summer", "autumn"];
const MEAN: [i128; 4] = [30, 60, 90, 40];           // seasonal mean rainfall, mm
const TEMP: [i128; 4] = [5, 11, 19, 13];            // seasonal mean temperature, C

fn e(v: &[Q]) -> Q { v.iter().fold(z(0), |acc, &x| acc + q(1, 8) * x) }   // each weighs 0.125
fn show(v: &[Q]) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(" ") }
fn sq_err(a: &[Q], b: &[Q]) -> Q { e(&a.iter().zip(b).map(|(&x, &y)| (x - y) * (x - y)).collect::<Vec<_>>()) }
fn prod(a: &[Q], b: &[Q]) -> Vec<Q> { a.iter().zip(b).map(|(&x, &y)| x * y).collect() }

fn lstsq(y: &[Q], feats: &[Vec<Q>]) -> (Vec<Q>, Vec<Q>) {       // normal equations, eliminated
    let k = feats.len();
    let mut a: Vec<Vec<Q>> = feats.iter().map(|f| {
        let mut row: Vec<Q> = feats.iter().map(|g| e(&prod(f, g))).collect();
        row.push(e(&prod(f, y))); row }).collect();
    for c in 0..k {
        let piv = (c..k).find(|&r| a[r][c] != z(0)).unwrap();
        a.swap(c, piv);
        for r in 0..k {
            if r != c && a[r][c] != z(0) {
                let m = a[r][c] / a[c][c];
                let rc = a[c].clone();
                for j in 0..=k { a[r][j] = a[r][j] - m * rc[j]; }
            }
        }
    }
    let coef: Vec<Q> = (0..k).map(|r| a[r][k] / a[r][r]).collect();
    let fit = (0..8).map(|i| (0..k).fold(z(0), |acc, j| acc + coef[j] * feats[j][i])).collect();
    (coef, fit)
}

fn main() {
    let s: Vec<usize> = (0..8).map(|i| i / 2).collect();            // season of each outcome
    let x: Vec<Q> = (0..8).map(|i| z(MEAN[i / 2] + if i % 2 == 0 { -10 } else { 10 })).collect();
    let t: Vec<Q> = s.iter().map(|&k| z(TEMP[k])).collect();
    let ind = |k: usize| -> Vec<Q> { s.iter().map(|&j| z((j == k) as i128)).collect() };
    // road one: the partition formula, E[X 1_B] / P(B) on each season's cell B
    let m: Vec<Q> = s.iter().map(|&k| e(&prod(&x, &ind(k))) / e(&ind(k))).collect();
    println!("1. the eight outcomes, each with probability 0.125");
    println!("   season  : {}", s.iter().map(|&k| format!("{:>6}", NAME[k])).collect::<Vec<_>>().join(" "));
    println!("   rain X  : {}", x.iter().map(|v| format!("{:>6}", v)).collect::<Vec<_>>().join(" "));
    println!("   E[X | G]: {}", m.iter().map(|v| format!("{:>6}", v)).collect::<Vec<_>>().join(" "));
    println!("   temp T  : {}", t.iter().map(|v| format!("{:>6}", v)).collect::<Vec<_>>().join(" "));
    let mut events = 0;
    for mask in 0..16usize {                                       // every event G can see
        let a: Vec<Q> = s.iter().map(|&k| z(((mask >> k) & 1) as i128)).collect();
        assert_eq!(e(&prod(&x, &a)), e(&prod(&m, &a)));
        events += 1;
    }
    println!("   defining property E[X 1_A] = E[M 1_A] holds on {} of 16 events in G", events);
    // road two: least squares on 1, T, T^2, T^3, which never looks at a season name
    let one = vec![z(1); 8];
    let (_, m2) = lstsq(&x, &[one.clone(), t.clone(), prod(&t, &t), prod(&prod(&t, &t), &t)]);
    assert_eq!(m2, m);
    let evens = |v: &[Q]| -> Vec<Q> { v.iter().step_by(2).cloned().collect() };
    println!("2. least squares on 1, T, T^2, T^3 gives {}: the same forecast", show(&evens(&m2)));
    println!("3. the error X - M is perpendicular to every known quantity");
    let r: Vec<Q> = x.iter().zip(&m).map(|(&a, &b)| a - b).collect();
    for k in 0..4 {
        let dot = e(&prod(&r, &ind(k)));
        assert_eq!(dot, z(0));
        println!("   E[(X - M) 1_{}] = {}", NAME[k], dot);
    }
    let rt = e(&prod(&r, &t)); assert_eq!(rt, z(0));                // and to the temperature
    println!("   E[(X - M) T] = {}", rt);
    let (ex, ex2, em2) = (e(&x), e(&prod(&x, &x)), e(&prod(&m, &m)));
    assert!(em2 <= ex2);
    println!("   E[X] = {}, E[X^2] = {}, E[M^2] = {}: M is in L2(G)", ex, ex2, em2);
    println!("4. all 81 forecasts M + d, d in {{-10, 0, 5}} for each season");
    let (mut best, mut beat, mut worst) = (None, 0, z(0));
    for idx in 0..81usize {
        let d: Vec<i128> = (0..4).map(|j| [-10, 0, 5][(idx / 3usize.pow(3 - j as u32)) % 3]).collect();
        let zz: Vec<Q> = (0..8).map(|i| m[i] + z(d[s[i]])).collect();
        let extra = e(&s.iter().map(|&k| z(d[k] * d[k])).collect::<Vec<_>>());   // E[(M - Z)^2]
        let err = sq_err(&x, &zz);
        assert_eq!(err, sq_err(&x, &m) + extra);                          // Pythagoras, exactly
        if err < sq_err(&x, &m) { beat += 1; }
        if err > worst { worst = err; }
        best = Some(match best { Some(b) if b < err => b, _ => err });
    }
    let best = best.unwrap();
    assert_eq!(beat, 0);
    assert_eq!(best, sq_err(&x, &m));
    println!("   Pythagoras exact on 81 of 81; best {} at d = 0; worst {}; {} beat M", best, worst, beat);
    println!("5. the law of total variance");
    let var_direct = e(&x.iter().map(|&v| (v - ex) * (v - ex)).collect::<Vec<_>>());
    let within = e(&prod(&r, &r)); let between = e(&m.iter().map(|&v| (v - ex) * (v - ex)).collect::<Vec<_>>());
    let cond_var: Vec<Q> = (0..4).map(|k| e(&prod(&prod(&r, &r), &ind(k))) / q(1, 4)).collect();
    assert_eq!(var_direct, ex2 - ex * ex);
    assert_eq!(ex2 - ex * ex, within + between);
    println!("   Var X = E[(X - 55)^2] = {}; E[X^2] - 55^2 = {}", var_direct, ex2 - ex * ex);
    println!("   55^2 = {}; seasonal means minus 55: {}", ex * ex, show(&evens(&m.iter().map(|&v| v - ex).collect::<Vec<_>>())));
    println!("   Var(X | season) = {}; within {} + between {}", show(&cond_var), within, between);
    println!("   = {}; share explained by the season {:.2}", within + between, (between / var_direct).f());
    println!("6. least squares on 1 and T only: a smaller space of known quantities");
    let (c1, fit) = lstsq(&x, &[one.clone(), t.clone()]);
    let (c2, _) = lstsq(&m, &[one.clone(), t.clone()]);
    let gap = sq_err(&m, &fit);
    let tm = e(&t); let cov = e(&t.iter().zip(&m).map(|(&a, &b)| (a - tm) * (b - ex)).collect::<Vec<_>>());
    let vt = e(&t.iter().map(|&a| (a - tm) * (a - tm)).collect::<Vec<_>>());
    assert_eq!(c1[1], cov / vt);                                   // slope by formula
    assert_eq!(c1[0], ex - c1[1] * tm);                            // intercept by formula
    assert_eq!(c1, c2);
    assert_eq!(sq_err(&x, &fit), within + gap);
    println!("   from X: rain = {} + {} T;  from M: rain = {} + {} T", c1[0], c1[1], c2[0], c2[1]);
    println!("   by hand: mean T {}, deviations {}, mean square {}, average product with M - 55 {}",
             tm, show(&evens(&t.iter().map(|&a| a - tm).collect::<Vec<_>>())), vt, cov);
    println!("   M minus line: {}", show(&evens(&m.iter().zip(&fit).map(|(&a, &b)| a - b).collect::<Vec<_>>())));
    println!("   fitted {}; error {} = {} + {}", show(&evens(&fit)), sq_err(&x, &fit), within, gap);
    println!("   explained by the line {}; plus {} = {}", sq_err(&fit, &vec![ex; 8]), gap, between);
    println!("7. what breaks");
    let peek = sq_err(&x, &x);
    let cross = e(&r.iter().zip(m.iter().zip(&x)).map(|(&a, (&b, &c))| a * (b - c)).collect::<Vec<_>>());
    let pyth = within + sq_err(&m, &x);
    assert!(peek < sq_err(&x, &m)); assert!(peek != pyth);
    assert!(cross != z(0));                                        // orthogonality fails: Z is not known
    println!("   peeking forecast Z = X: error {}, Pythagoras would say {}, E[(X - M)(M - Z)] = {}", peek, pyth, cross);
    let desert = [0i128, 0, 0, 40];
    let mu = q(desert.iter().sum(), 4);
    let sq: Vec<Q> = [mu, z(0)].iter().map(|&c| desert.iter().fold(z(0), |a, &y| a + (z(y) - c) * (z(y) - c)) / z(4)).collect();
    let ab: Vec<Q> = [mu, z(0)].iter().map(|&c| desert.iter().fold(z(0), |a, &y| { let w = z(y) - c; a + if w < z(0) { z(0) - w } else { w } }) / z(4)).collect();
    assert!(sq[0] < sq[1]); assert!(ab[0] > ab[1]);
    println!("   desert month 0, 0, 0, 40: squared loss mean {} -> {}, 0 -> {}; absolute loss mean {} -> {}, 0 -> {}",
             mu, sq[0], sq[1], mu, ab[0], ab[1]);
    let tail = |n: u32| (1..=n).fold(z(0), |a, k| a + q(3, 4i128.pow(k)) * z(4i128.pow(k)));
    let mean20 = (1..=20u32).fold(z(0), |a, k| a + q(3, 4i128.pow(k)) * z(2i128.pow(k)));
    println!("   X = 2^k w.p. 3/4^k: E[X^2] partial sums {}, {}, {}; E[X] to 20 terms {:.6}",
             tail(5), tail(10), tail(20), mean20.f());
    println!("8. chart and figure");
    println!("chart, X: {}", show(&x));
    println!("chart, M: {}", show(&m));
    println!("chart, line: {}", show(&fit));
    println!("chart, mean: {}", show(&vec![ex; 8]));
    let sc = 8.0;                                                  // figure: 8 units per mm
    let (lb, lw, lv) = (between.f().sqrt(), within.f().sqrt(), var_direct.f().sqrt());
    println!("figure, scale {:.0} per mm, O=(40,200) M=({:.2},200) X=({:.2},{:.2}) legs {:.2} and {:.2}, hypotenuse {:.2}",
             sc, 40.0 + sc * lb, 40.0 + sc * lb, 200.0 - sc * lw, lb, lw, lv);
}
