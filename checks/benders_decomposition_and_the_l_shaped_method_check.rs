// Benders decomposition and the L-shaped method -- the check behind the card.
// std only, exact fractions in a small rational struct.  The reservoir buys x
// thousand m3 of irrigation water now at GBP 1k per thousand m3.  Demand is 50,
// 100 or 150 (chance 1/3 each); each thousand m3 short costs GBP 2k.  Minimise
// the expected cost.  Road 1: single-cut L-shaped.  Road 2: multi-cut.  Road 3:
// the extensive form's plan with dual prices that meet its cost.  Road 4: a
// scan of every whole x, cost worked out directly.
use std::cmp::Ordering;
use std::ops::{Add, Div, Mul, Neg, Sub};

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
struct R(i64, i64);
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn r(n: i64, d: i64) -> R { let g = gcd(n, d).max(1) * d.signum(); R(n / g, d / g) }
fn ri(n: i64) -> R { R(n, 1) }
impl Add for R { type Output = R; fn add(self, o: R) -> R { r(self.0 * o.1 + o.0 * self.1, self.1 * o.1) } }
impl Sub for R { type Output = R; fn sub(self, o: R) -> R { r(self.0 * o.1 - o.0 * self.1, self.1 * o.1) } }
impl Mul for R { type Output = R; fn mul(self, o: R) -> R { r(self.0 * o.0, self.1 * o.1) } }
impl Div for R { type Output = R; fn div(self, o: R) -> R { r(self.0 * o.1, self.1 * o.0) } }
impl Neg for R { type Output = R; fn neg(self) -> R { R(-self.0, self.1) } }
impl PartialOrd for R { fn partial_cmp(&self, o: &R) -> Option<Ordering> { Some(self.cmp(o)) } }
impl Ord for R { fn cmp(&self, o: &R) -> Ordering { (self.0 * o.1).cmp(&(o.0 * self.1)) } }
impl std::fmt::Display for R {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        if self.1 == 1 { write!(f, "{}", self.0) } else { write!(f, "{}/{}", self.0, self.1) } } }
fn fm(v: R) -> String { if v.1 == 1 { format!("{}", v.0) } else { format!("{:.2}", v.0 as f64 / v.1 as f64) } }
fn line(a: R, b: R) -> String { format!("theta >= {} {} {} x", a, if b < ri(0) { "-" } else { "+" }, if b < ri(0) { -b } else { b }) }
fn join<T: ToString>(v: &[T], s: &str) -> String { v.iter().map(|t| t.to_string()).collect::<Vec<_>>().join(s) }

const D: [i64; 3] = [50, 100, 150];
fn p() -> R { r(1, 3) }
enum Sub_ { Ray(R), Opt(R, i64) }

// scenario LP: min q*y, y >= d - x, 0 <= y (<= cap).  Dual: max lam*(d-x) - mu*cap over
// lam, mu >= 0, lam - mu <= q.  Corners (0,0), (q,0); rays (0,1), (1,1) if capped.
fn sub(x: R, d: i64, q: i64, cap: Option<i64>, tight: bool) -> Sub_ {
    if let Some(c) = cap { for (lam, mu) in [(0i64, 1i64), (1, 1)] {
        if ri(lam) * (ri(d) - x) - ri(mu * c) > ri(0) { return Sub_::Ray(r(lam * d - mu * c, lam)); } } }
    let best = if ri(d) - x > ri(0) { q } else { 0 };
    Sub_::Opt(ri(best) * (ri(d) - x), if tight { best } else { q })
}

fn master(c: R, groups: &[Vec<(R, R)>], w: &[R], lo: R, grid: Option<Vec<R>>) -> (R, R) {
    let g = |x: R| { let mut s = c * x; for (wi, gr) in w.iter().zip(groups) {
        s = s + *wi * gr.iter().map(|&(a, b)| a + b * x).fold(ri(0), |m, v| m.max(v)); } s };
    let mut cand: Vec<R> = match grid { Some(v) => v, None => { let mut v = vec![lo];
        for gr in groups { let mut ls = gr.clone(); ls.push((ri(0), ri(0)));
            for &(a1, b1) in &ls { for &(a2, b2) in &ls { if b1 != b2 { v.push((a2 - a1) / (b1 - b2)); } } } } v } };
    cand.retain(|&x| x >= lo); cand.sort(); cand.dedup();
    let best = *cand.iter().min_by(|&&x, &&y| g(x).cmp(&g(y)).then(x.cmp(&y))).unwrap();
    (best, g(best))
}

struct Run { x: R, v: R, k: i64, visited: Vec<R> }
fn benders(c: R, q: i64, cap: Option<i64>, multi: bool, block: Option<i64>, tight: bool, tag: &str, show: bool, kmax: i64) -> Run {
    let mut groups: Vec<Vec<(R, R)>> = vec![vec![]; if multi { 3 } else { 1 }];
    let w: Vec<R> = if multi { vec![p(); 3] } else { vec![ri(1)] };
    let (mut lo, mut ub, mut k, mut visited) = (ri(0), None::<R>, 0, vec![]);
    let (mut x, mut lb) = (ri(0), ri(0));
    while k <= kmax {
        let grid = block.map(|b| (0..6).map(|n| ri(b * n)).filter(|&v| v >= lo).collect());
        let m = master(c, &groups, &w, lo, grid); x = m.0; lb = m.1;
        let res: Vec<Sub_> = D.iter().map(|&d| sub(x, d, q, cap, tight)).collect();
        let rays: Vec<R> = res.iter().filter_map(|s| if let Sub_::Ray(v) = s { Some(*v) } else { None }).collect();
        if !rays.is_empty() {
            for &v in &rays { lo = lo.max(v); }
            if show { println!("{} k={} x={} infeasible -> feasibility cuts {}", tag, k, fm(x),
                join(&rays.iter().map(|v| format!("x >= {}", v)).collect::<Vec<_>>(), ", ")); }
            k += 1; continue;
        }
        visited.push(x);
        let opt: Vec<(R, i64)> = res.iter().map(|s| if let Sub_::Opt(v, l) = s { (*v, *l) } else { unreachable!() }).collect();
        let val = opt.iter().fold(c * x, |s, &(v, _)| s + p() * v);
        ub = Some(match ub { None => val, Some(u) => u.min(val) });
        let mut cuts: Vec<(R, R)> = opt.iter().zip(D).map(|(&(_, l), d)| (ri(l * d), ri(-l))).collect();
        if !multi { cuts = vec![cuts.iter().fold((ri(0), ri(0)), |(sa, sb), &(a, b)| (sa + p() * a, sb + p() * b))]; }
        let lams = join(&opt.iter().map(|o| o.1).collect::<Vec<_>>(), ",");
        let done = Some(lb) == ub;
        let tail = if done { "stop".to_string() } else { format!("prices {} | {}", lams, if multi { format!("{} cuts", cuts.len()) }
            else { join(&cuts.iter().map(|&(a, b)| line(a, b)).collect::<Vec<_>>(), "; ") }) };
        let qs = join(&opt.iter().map(|o| fm(o.0)).collect::<Vec<_>>(), ",");
        if show { println!("{} k={} x={} theta={} LB={} | Q={} cost={} UB={} | {}", tag, k, fm(x), fm(lb - c * x), fm(lb), qs, fm(val), fm(ub.unwrap()), tail); }
        if done { return Run { x, v: ub.unwrap(), k, visited }; }
        for (gr, cut) in groups.iter_mut().zip(cuts) { gr.push(cut); }
        k += 1;
    }
    Run { x, v: lb, k, visited }
}

fn f(c: R, x: R, q: i64, cap: Option<i64>) -> Option<R> {
    let short: Vec<R> = D.iter().map(|&d| (ri(d) - x).max(ri(0))).collect();
    if let Some(cp) = cap { if *short.iter().max().unwrap() > ri(cp) { return None; } }
    Some(short.iter().fold(c * x, |s, &v| s + p() * ri(q) * v))
}
fn scan(c: R, xs: &[i64], q: i64, cap: Option<i64>) -> (R, R) {
    let mut best: Option<(R, R)> = None;
    for &x in xs { if let Some(v) = f(c, ri(x), q, cap) { if best.map_or(true, |(bv, _)| v < bv) { best = Some((v, ri(x))); } } }
    (best.unwrap().1, best.unwrap().0)
}

fn main() {
    let one = ri(1);
    let all: Vec<i64> = (0..=200).collect();
    println!("demand 50/100/150 (1/3 each), buy at 1, shortfall at 2; GBP thousand, thousand m3");
    let s1 = benders(one, 2, None, false, None, true, "single", true, 20);
    let s2 = benders(one, 2, None, true, None, true, "multi", true, 20);
    let (xs, vs) = scan(one, &all, 2, None);
    println!("dual corners per scenario 2, so at most {} different single cuts", 2i64.pow(D.len() as u32));
    let kinks: Vec<String> = [0, 50, 100, 150].iter().map(|&x| fm(f(one, ri(x), 2, None).unwrap())).collect();
    println!("scan x = 0..200: best x={} cost={};  f at kinks 0,50,100,150: {}", xs, fm(vs), join(&kinks, ", "));
    let ys: Vec<R> = D.iter().map(|&d| (ri(d) - s1.x).max(ri(0))).collect();
    let mut lam = vec![ri(0); 3]; let mut left = one;
    for i in (0..3).rev() { lam[i] = (ri(2) * p()).min(left); left = left - lam[i]; }   // largest demand first
    let primal = ys.iter().fold(s1.x, |s, &y| s + ri(2) * p() * y);
    let bound = lam.iter().zip(D).fold(ri(0), |s, (&l, d)| s + l * ri(d));
    let lsum = lam.iter().fold(ri(0), |s, &l| s + l);
    println!("extensive form: x={}, y={}, cost {}; dual prices {} sum {}, bound {}", s1.x, join(&ys, ", "), fm(primal), join(&lam, ", "), lsum, fm(bound));
    let sc = benders(one, 2, Some(30), false, None, true, "cap 30", true, 20);
    let (xcs, vcs) = scan(one, &all, 2, Some(30));
    println!("cap 30 scan: best x={} cost={}", xcs, fm(vcs));
    let sb = benders(one, 2, None, false, Some(35), true, "blocks 35", true, 20);
    let grid: Vec<i64> = (0..6).map(|n| 35 * n).collect();
    let (xbs, vbs) = scan(one, &grid, 2, None);
    println!("blocks 35 enumeration: {}", join(&grid.iter().map(|&x| format!("f({})={}", x, fm(f(one, ri(x), 2, None).unwrap()))).collect::<Vec<_>>(), ", "));
    let xs25: Vec<i64> = (0..=150).step_by(25).collect();
    println!("chart x       {}", join(&xs25.iter().map(|x| format!("{:>6}", x)).collect::<Vec<_>>(), " "));
    for (name, cuts) in [("true", vec![]), ("1 cut", vec![(ri(200), ri(-2))]), ("2 cuts", vec![(ri(200), ri(-2)), (ri(100), r(-2, 3))])] {
        let vals: Vec<String> = xs25.iter().map(|&x| { let x = ri(x); let v = if cuts.is_empty() { f(one, x, 2, None).unwrap() }
            else { cuts.iter().fold(ri(0), |m: R, &(a, b)| m.max(a + b * x)) + x }; format!("{:>6}", fm(v)) }).collect();
        println!("chart {:<8}{}", name, join(&vals, " "));
    }
    let (_, lbc) = master(one, &[vec![(ri(200), ri(0))]], &[one], ri(0), None);
    println!("break: flat cut theta >= 200 from x=0 -> master LB {} > optimum {}", lbc, fm(s1.v));
    let sl = benders(one, 2, None, false, None, false, "", false, 4);
    println!("break: prices 2 in every season -> x visits {}; LB stuck at {}", join(&sl.visited.iter().map(|&v| fm(v)).collect::<Vec<_>>(), ", "), fm(sl.v));
    println!("break: cap 30 ignored -> x={}, {} thousand m3 unmet when demand is 150", s1.x, ri(150) - s1.x - ri(30));
    let fi = |x: R| D.iter().fold(x, |s, &d| { let sh = (ri(d) - x).max(ri(0)); s + p() * ri(80) * ri((sh.0 + 40 * sh.1 - 1) / (40 * sh.1)) });
    let xi = (0..=200).map(ri).min_by(|&a, &b| fi(a).cmp(&fi(b)).then(a.cmp(&b))).unwrap();
    let ubi = s1.visited.iter().map(|&x| fi(x)).min().unwrap();
    println!("break: tankers of 40 at 80 -> LP cuts stop at LB {}, best visited {}; true best x={} cost {}", fm(s1.v), fm(ubi), xi, fm(fi(xi)));
    for (label, q, cap, block) in [("shortfall 4", 4, None, None), ("cap 60", 2, Some(60), None), ("blocks 25", 2, None, Some(25))] {
        let t = benders(one, q, cap, false, block, true, &format!("try {}", label), label == "cap 60", 20);
        println!("try {}: x={} cost={} after {} master solves", label, fm(t.x), fm(t.v), t.k + 1);
    }
    let t = benders(r(3, 2), 2, None, false, None, true, "", false, 20);
    println!("try buy 1.5: x={} cost={} after {} master solves", fm(t.x), fm(t.v), t.k + 1);

    assert!((s1.x, s1.v, s1.k) == (xs, vs, 3) && (xs, vs) == (ri(100), r(400, 3)), "single-cut must match the scan, in 4 master solves");
    assert!((s2.x, s2.v, s2.k) == (ri(100), r(400, 3), 1), "multi-cut must match, in 2 master solves");
    assert!(lam.iter().all(|&l| l >= ri(0) && l <= ri(2) * p()) && lsum <= one, "dual prices feasible");
    assert!(bound == primal && primal == s1.v, "dual bound must meet the extensive form's cost: the certificate");
    assert!((sc.x, sc.v) == (xcs, vcs) && (xcs, vcs) == (ri(120), ri(140)), "feasibility cuts must reach the capped optimum");
    assert!((sb.x, sb.v) == (xbs, vbs) && (xbs, vbs) == (ri(105), ri(135)), "integer master must match enumeration");
    assert!(lbc > s1.v && sl.v < s1.v && fi(xi) < ubi && s1.v < fi(xi), "the four breaks must show");
    println!("ALL CHECKS PASS");
}
