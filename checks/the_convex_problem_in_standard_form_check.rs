// The standard convex problem -- the same check as the Python, in Rust.  No crates.
// One kilo of coffee blended from Brazil, Colombia and Robusta beans: x[i] is the
// kilos of bean i.  Minimise the cost in pounds per kilo, keep caffeine at or
// above 1.6 percent, stay within 0.2 of the house recipe 50/30/20.  Each piece is
// judged twice: by the rules a solver applies to the formula, and by a midpoint
// test on random blends.  The answer is found twice: by a Cauchy-Schwarz bound
// that one blend meets, and by listing every blend on a 0.001 grid.
const COST: [f64; 3] = [9.0, 12.0, 6.0];
const CAF: [f64; 3] = [1.2, 1.4, 2.4];
const REF: [f64; 3] = [0.5, 0.3, 0.2];
const R2: f64 = 0.04;
const N: usize = 2000;

#[derive(Clone)] enum E { Aff(Vec<f64>, f64), Sq(Box<E>), Sqrt(Box<E>), Sum(Vec<E>), Div(Box<E>, Box<E>) }

fn unit(i: usize, s: f64) -> Vec<f64> { (0..3).map(|j| if j == i { s } else { 0.0 }).collect() }
fn taste() -> E {                                        // squared distance from the recipe
    E::Sum((0..3).map(|i| E::Sq(Box::new(E::Aff(unit(i, 1.0), -REF[i])))).collect())
}

fn ev(e: &E, x: &[f64]) -> f64 {                         // the value of a formula at x
    match e {
        E::Aff(a, b) => a.iter().zip(x).fold(0.0, |s, (p, q)| s + p * q) + b,
        E::Sq(t) => ev(t, x) * ev(t, x),
        E::Sqrt(t) => ev(t, x).powf(0.5),
        E::Sum(ts) => ts.iter().fold(0.0, |s, t| s + ev(t, x)),
        E::Div(t, u) => ev(t, x) / ev(u, x),
    }
}

fn curv(e: &E) -> &'static str {                        // road one: the solver's rules
    match e {
        E::Aff(..) => "affine",
        E::Sq(t) => if curv(t) == "affine" { "convex" } else { "unknown" },
        E::Sqrt(t) => if curv(t) == "affine" || curv(t) == "concave" { "concave" } else { "unknown" },
        E::Sum(ts) => {
            let mut kinds: Vec<&str> = ts.iter().map(curv).filter(|k| *k != "affine").collect();
            kinds.sort();
            kinds.dedup();
            if kinds.is_empty() { "affine" } else if kinds.len() == 1 && kinds[0] != "unknown" { kinds[0] } else { "unknown" }
        }
        E::Div(..) => "unknown",                         // no rule for a ratio
    }
}

fn accepted(role: &str, e: &E) -> bool {
    if role == "eq" { curv(e) == "affine" } else { curv(e) == "affine" || curv(e) == "convex" }
}

struct Rng(u64);
impl Rng {                                               // SplitMix64, seed 2026
    fn next(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn blend(&mut self) -> Vec<f64> {                    // a random point of the triangle
        let (mut u, mut v) = (self.next(), self.next());
        if u + v > 1.0 { u = 1.0 - u; v = 1.0 - v; }
        vec![u, v, 1.0 - u - v]
    }
}

fn misses(role: &str, e: &E, pairs: &[(Vec<f64>, Vec<f64>)]) -> usize {   // road two
    let mut bad = 0;
    for (a, b) in pairs {
        let m: Vec<f64> = a.iter().zip(b).map(|(p, q)| (p + q) / 2.0).collect();
        let (mid, avg) = (ev(e, &m), (ev(e, a) + ev(e, b)) / 2.0);
        if (role == "eq" && (mid - avg).abs() > 1e-9) || (role != "eq" && mid > avg + 1e-9) { bad += 1; }
    }
    bad
}

fn dot(a: &[f64], x: &[f64]) -> f64 { a.iter().zip(x).fold(0.0, |s, (p, q)| s + p * q) }
fn cost(x: &[f64]) -> f64 { dot(&COST, x) }
fn feasible(x: &[f64]) -> bool {
    let caf = dot(&CAF, x);
    let total = x.iter().fold(0.0, |s, v| s + v);
    (total - 1.0).abs() < 1e-9 && x.iter().all(|v| *v >= 0.0) && ev(&taste(), x) <= R2 + 1e-12
        && caf >= 1.6
}
fn on_grid(i: i64, j: i64, k: i64, flip: bool) -> bool {  // the same tests in whole thousandths
    let caf = 12 * i + 14 * j + 24 * k - 16000;
    let near = (i - 500).pow(2) + (j - 300).pow(2) + (k - 200).pow(2) <= (R2 * 1e6) as i64;
    near && (if flip { caf <= 0 } else { caf >= 0 })
}

fn grid(flip: bool) -> (f64, Vec<f64>, usize) {         // every blend on a 0.001 grid
    let (mut best, mut at, mut count) = (1e9, vec![], 0);
    for i in 0..=1000i64 {
        for j in 0..=(1000 - i) {
            let x = vec![i as f64 / 1000.0, j as f64 / 1000.0, (1000 - i - j) as f64 / 1000.0];
            if on_grid(i, j, 1000 - i - j, flip) {
                count += 1;
                if cost(&x) < best { best = cost(&x); at = x; }
            }
        }
    }
    (best, at, count)
}

fn px(x: &[f64]) -> String {                             // the figure: 240 px per unit, to scale
    let (u, w) = ((x[1] - x[2]) / 2f64.powf(0.5), (2.0 * x[0] - x[1] - x[2]) / 6f64.powf(0.5));
    format!("({:.1} {:.1})", 200.0 + 240.0 * u, 225.0 - 240.0 * w)
}
fn v4(x: &[f64]) -> String { format!("[{:.4}, {:.4}, {:.4}]", x[0], x[1], x[2]) }

fn main() {
    let tz = E::Sum(vec![taste(), E::Aff(vec![0.0; 3], -R2)]);
    let mut pieces: Vec<(String, &str, E)> = vec![
        ("f0 = c.x, cost to minimise".into(), "min", E::Aff(COST.to_vec(), 0.0)),
        ("h1 = x1 + x2 + x3 - 1".into(), "eq", E::Aff(vec![1.0; 3], -1.0)),
        ("f1 = 1.6 - s.x, caffeine".into(), "le", E::Aff(CAF.iter().map(|c| -c).collect(), 1.6)),
        ("f2 = taste - 0.04".into(), "le", tz.clone())];
    for i in 0..3 { pieces.push((format!("f{} = -x{}, no negative kilos", 3 + i, i + 1), "le", E::Aff(unit(i, -1.0), 0.0))); }
    let ratio = E::Div(Box::new(E::Aff(COST.to_vec(), 0.0)), Box::new(E::Aff(CAF.to_vec(), 0.0)));
    pieces.push(("taste = 0.04, the circle".into(), "eq", tz));
    pieces.push(("sqrt(taste) - 0.2 <= 0".into(), "le", E::Sum(vec![E::Sqrt(Box::new(taste())), E::Aff(vec![0.0; 3], -0.2)])));
    pieces.push(("cost per caffeine, minimise".into(), "min", ratio.clone()));
    let mut rng = Rng(2026);
    let pairs: Vec<(Vec<f64>, Vec<f64>)> = (0..N).map(|_| { let a = rng.blend(); (a, rng.blend()) }).collect();
    println!("Brazil, Colombia, Robusta: pounds a kilo {:?}, caffeine percent {:?}", COST, CAF);
    println!("{:<28}{:<10}{:<10}midpoint misses in {}", "piece", "rule says", "accepted", N);
    let mut results = vec![];
    for (name, role, e) in &pieces {
        let (ok, bad) = (accepted(role, e), misses(role, e, &pairs));
        results.push((ok, bad));
        println!("{:<28}{:<10}{:<10}{}", name, curv(e), if ok { "yes" } else { "no" }, bad);
    }
    println!("house recipe {:?}: cost {:.4}, caffeine {:.4}", REF, cost(&REF), dot(&CAF, &REF));
    let m = COST.iter().fold(0.0, |s, c| s + c) / 3.0;
    let pc: Vec<f64> = COST.iter().map(|c| c - m).collect();   // the cost with its even part removed
    let norm = pc.iter().fold(0.0, |s, p| s + p * p).powf(0.5);
    let bound = cost(&REF) - R2.powf(0.5) * norm;               // Cauchy-Schwarz on the taste ball
    let xs: Vec<f64> = REF.iter().zip(&pc).map(|(r, p)| r - R2.powf(0.5) * p / norm).collect();
    println!("projected cost {:?}, its length {:.4}; lower bound {:.4} - {:.1} x {:.4} = {:.4}", pc, norm, cost(&REF), R2.powf(0.5), norm, bound);
    println!("step from the recipe: [{:.4}, {:.4}, {:.4}]", xs[0] - REF[0], xs[1] - REF[1], xs[2] - REF[2]);
    println!("blend meeting it: x* = {}, cost {:.4}, caffeine {:.4}, taste {:.4}, feasible {}", v4(&xs), cost(&xs),
             dot(&CAF, &xs), ev(&taste(), &xs), if feasible(&xs) { "yes" } else { "no" });
    let (gc, gx, gn) = grid(false);
    println!("grid: {} of 501501 blends feasible; best {:?} at cost {:.4}, {:.4} above the bound", gn, gx, gc, gc - bound);
    let (fc, fx, _) = grid(true);
    let (p, q) = ([0.0, 0.8, 0.2], [2.0 / 3.0, 0.0, 1.0 / 3.0]); // where caffeine 1.6 meets the edges
    let d: Vec<f64> = p.iter().zip(&q).map(|(a, b)| b - a).collect();
    let e0: Vec<f64> = p.iter().zip(&REF).map(|(a, r)| a - r).collect();
    let (qa, qb, qc) = (dot(&d, &d), 2.0 * dot(&d, &e0), dot(&e0, &e0) - R2);
    let root = (qb * qb - 4.0 * qa * qc).powf(0.5);
    let cut: Vec<Vec<f64>> = [(-qb - root) / (2.0 * qa), (-qb + root) / (2.0 * qa)].iter()
        .map(|t| p.iter().zip(&d).map(|(a, s)| a + t * s).collect()).collect();
    let fl = cost(&cut[0]).min(cost(&cut[1]));                  // a linear cost is least at an end of the chord
    println!("mistake, caffeine flipped to at most 1.6: exact {:.4}; grid best {:?} at {:.4}", fl, fx, fc);
    let a: Vec<f64> = REF.iter().zip(&xs).map(|(r, x)| 2.0 * r - x).collect();   // x* mirrored
    let mid: Vec<f64> = a.iter().zip(&xs).map(|(p, q)| (p + q) / 2.0).collect();
    println!("mistake, circle: x* and {} have taste {:.4}, {:.4}; midpoint taste {:.4}",
             v4(&a), ev(&taste(), &a), ev(&taste(), &xs), ev(&taste(), &mid));
    let (br, co) = ([1.0, 0.0, 0.0], [0.0, 1.0, 0.0]);
    let (rm, ra) = (ev(&ratio, &[0.5, 0.5, 0.0]), (ev(&ratio, &br) + ev(&ratio, &co)) / 2.0);
    println!("mistake, ratio: Brazil {:.4}, Colombia {:.4}, half and half {:.4} above their average {:.4}",
             ev(&ratio, &br), ev(&ratio, &co), rm, ra);
    println!("figure, Brazil {} Colombia {} Robusta {} recipe {} radius {:.1} x* {} caffeine line {} {} cuts circle {} {}",
             px(&br), px(&co), px(&[0.0, 0.0, 1.0]), px(&REF), 240.0 * 0.2, px(&xs), px(&p), px(&q), px(&cut[0]), px(&cut[1]));
    assert!(results[..7].iter().all(|(ok, bad)| *ok && *bad == 0));
    assert!(results[8].1 == 0 && !results[8].0);                 // rejected, yet convex: the rules are cautious
    assert!(!results[7].0 && !results[9].0 && results[7].1 > 0 && results[9].1 > 0 && rm > ra);    // rejected, and truly not convex
    assert!(feasible(&xs) && (cost(&xs) - bound).abs() < 1e-12 && gc - bound >= 0.0 && gc - bound < 0.005);
    assert!(fc - fl >= 0.0 && fc - fl < 0.005 && fl > bound + 0.03 && ev(&taste(), &mid) < R2);
    println!("ALL CHECKS PASS");
}
