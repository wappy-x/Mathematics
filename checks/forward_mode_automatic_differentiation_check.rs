// Forward-mode automatic differentiation check, std only: one pricer, three number types.
use std::cell::Cell;
use std::collections::{HashMap, HashSet};
use std::ops::{Add, Div, Mul, Sub};
use std::rc::Rc;
thread_local! {
    static OPS: Cell<(usize, usize)> = Cell::new((0, 0)); // operations: (on values, on slopes)
    static MISTAKE: Cell<u8> = Cell::new(0);               // 0 correct, 1 product, 2 chain
}
fn tick(v: usize, d: usize) { OPS.with(|o| { let (a, b) = o.get(); o.set((a + v, b + d)) }); }
fn mistake() -> u8 { MISTAKE.with(|m| m.get()) }
fn set_mistake(k: u8) { MISTAKE.with(|m| m.set(k)); }
fn ops(reset: bool) -> (usize, usize) { OPS.with(|o| { let r = o.get(); if reset { o.set((0, 0)) }; r }) }
trait Num: Clone + Add<Output = Self> + Sub<Output = Self> + Mul<Output = Self> + Div<Output = Self> {
    fn c(x: f64) -> Self; fn exp(&self) -> Self; fn ln(&self) -> Self; fn round_bp(&self) -> Self;
}
impl Num for f64 {
    fn c(x: f64) -> Self { x } fn exp(&self) -> Self { f64::exp(*self) } fn ln(&self) -> Self { f64::ln(*self) }
    fn round_bp(&self) -> Self { (self * 1e4 + 0.5).floor() / 1e4 }
}
#[derive(Clone, Copy)]
struct Dual { v: f64, d: f64 } // a + b eps, with eps * eps = 0: a value carrying its slope
impl Add for Dual { type Output = Dual; fn add(self, o: Dual) -> Dual { tick(1, 1); Dual { v: self.v + o.v, d: self.d + o.d } } }
impl Sub for Dual { type Output = Dual; fn sub(self, o: Dual) -> Dual { tick(1, 1); Dual { v: self.v - o.v, d: self.d - o.d } } }
impl Mul for Dual { type Output = Dual; fn mul(self, o: Dual) -> Dual { tick(1, 3);
    Dual { v: self.v * o.v, d: if mistake() == 1 { self.v * o.d } else { self.v * o.d + self.d * o.v } } } }
impl Div for Dual { type Output = Dual; fn div(self, o: Dual) -> Dual { tick(1, 3);
    let q = self.v / o.v; Dual { v: q, d: (self.d - q * o.d) / o.v } } }
impl Num for Dual {
    fn c(x: f64) -> Self { Dual { v: x, d: 0.0 } }
    fn exp(&self) -> Self { tick(1, 1); let e = self.v.exp(); Dual { v: e, d: if mistake() == 2 { e } else { e * self.d } } }
    fn ln(&self) -> Self { tick(1, 1); Dual { v: self.v.ln(), d: self.d / self.v } }
    fn round_bp(&self) -> Self { tick(1, 0); Dual { v: (self.v * 1e4 + 0.5).floor() / 1e4, d: 0.0 } }
}
enum Node { C(f64), Y, Bin(char, Ex, Ex), Un(char, Ex) } // a symbolic expression
#[derive(Clone)] struct Ex(Rc<Node>);
fn node(n: Node) -> Ex { Ex(Rc::new(n)) }
fn key(e: &Ex) -> usize { Rc::as_ptr(&e.0) as usize }
impl Add for Ex { type Output = Ex; fn add(self, o: Ex) -> Ex { node(Node::Bin('+', self, o)) } }
impl Sub for Ex { type Output = Ex; fn sub(self, o: Ex) -> Ex { node(Node::Bin('-', self, o)) } }
impl Mul for Ex { type Output = Ex; fn mul(self, o: Ex) -> Ex { node(Node::Bin('*', self, o)) } }
impl Div for Ex { type Output = Ex; fn div(self, o: Ex) -> Ex { node(Node::Bin('/', self, o)) } }
impl Num for Ex {
    fn c(x: f64) -> Self { node(Node::C(x)) } fn round_bp(&self) -> Self { self.clone() }
    fn exp(&self) -> Self { node(Node::Un('e', self.clone())) } fn ln(&self) -> Self { node(Node::Un('l', self.clone())) }
}
// build a node, dropping terms that are the constant 0 (None)
fn mk(op: char, a: Option<Ex>, b: Option<Ex>) -> Option<Ex> {
    match op {
        '+' => match (a, b) { (None, b) => b, (a, None) => a, (Some(a), Some(b)) => Some(a + b) },
        '-' => match (a, b) { (a, None) => a, (a, Some(b)) => Some(a.unwrap_or(Ex::c(0.0)) - b) },
        '*' => match (a, b) { (Some(a), Some(b)) => Some(a * b), _ => None },
        _ => match (a, b) { (Some(a), Some(b)) => Some(a / b), _ => None },
    }
}
fn diff(e: &Ex, memo: &mut HashMap<usize, Option<Ex>>) -> Option<Ex> { // the textbook rules
    if let Some(r) = memo.get(&key(e)) { return r.clone(); }
    let r = match &*e.0 {
        Node::C(_) => None,
        Node::Y => Some(Ex::c(1.0)),
        Node::Bin(op, a, b) => {
            let (da, db) = (diff(a, memo), diff(b, memo));
            let (sa, sb) = (Some(a.clone()), Some(b.clone()));
            match op { '+' | '-' => mk(*op, da, db), '*' => mk('+', mk('*', da, sb), mk('*', sa, db)),
                _ => mk('/', mk('-', mk('*', da, sb.clone()), mk('*', sa, db)), Some(b.clone() * b.clone())) }
        }
        Node::Un('e', a) => mk('*', Some(e.clone()), diff(a, memo)),
        Node::Un(_, a) => mk('/', diff(a, memo), Some(a.clone())),
    };
    memo.insert(key(e), r.clone());
    r
}
fn evaluate(e: &Ex, y: f64, memo: &mut HashMap<usize, f64>) -> f64 {
    if let Some(r) = memo.get(&key(e)) { return *r; }
    let r = match &*e.0 {
        Node::C(c) => *c,
        Node::Y => y,
        Node::Bin(op, a, b) => { let (p, q) = (evaluate(a, y, memo), evaluate(b, y, memo));
            match op { '+' => p + q, '-' => p - q, '*' => p * q, _ => p / q } }
        Node::Un(op, a) => { let p = evaluate(a, y, memo); if *op == 'e' { p.exp() } else { p.ln() } }
    };
    memo.insert(key(e), r);
    r
}
// nodes written out in full; seen collects the distinct nodes
fn sizes(e: &Ex, memo: &mut HashMap<usize, u64>, seen: &mut HashSet<usize>) -> u64 {
    if let Some(r) = memo.get(&key(e)) { return *r; }
    seen.insert(key(e));
    let r = 1 + match &*e.0 { Node::Bin(_, a, b) => sizes(a, memo, seen) + sizes(b, memo, seen),
        Node::Un(_, a) => sizes(a, memo, seen), _ => 0 };
    memo.insert(key(e), r);
    r
}

// clean price per $100 face of a 4% bond paying $2 a half year, 2 months into a period
fn clean_price<T: Num>(y: T, years: usize, rounded: bool) -> T {
    let y = if rounded { y.round_bp() } else { y }; // quote the yield to a whole basis point first
    let (face, cpn) = (100.0, 2.0);                 // face value; the coupon paid each half year
    let n = 2 * years;                              // coupons still to come: 60
    let w = 4.0 / 6.0;                              // periods until the next coupon: 4 months of 6
    let v = T::c(1.0) / (T::c(1.0) + y / T::c(2.0)); // one half year's discount factor
    let mut df = (T::c(w) * v.ln()).exp();          // discount to the first coupon, v to the power w
    let mut pv = T::c(0.0);
    for k in 0..n {
        pv = pv + T::c(cpn) * df.clone();           // add this coupon's present value
        if k < n - 1 { df = df * v.clone(); }       // step the discount one half year further out
    }
    pv = pv + T::c(face) * df;                      // the face value comes back with the last coupon
    let accrued = cpn * (1.0 - w);                  // coupon already earned by the seller
    pv - T::c(accrued)
}
fn by_hand(y: f64, years: usize, m: i32) -> f64 { // d^m P/dy^m on paper: d^m(v^t)/dy^m = (-1/2)^m t(t+1)...(t+m-1) v^(t+m)
    let (v, w, n) = (1.0 / (1.0 + y / 2.0), 4.0 / 6.0, 2 * years);
    let rise = |t: f64| (0..m).map(|j| t + j as f64).product::<f64>() * v.powf(t + m as f64) * (-0.5f64).powi(m);
    let mut s = 0.0; for k in 0..n { s += 2.0 * rise(w + k as f64); } // the coupons of 2; the face of 100 comes with the last
    s + 100.0 * rise(w + n as f64 - 1.0)
}
fn dual(y: f64) -> Dual { Dual { v: y, d: 1.0 } }

fn main() {
    let (y0, h) = (0.045, 1e-4);
    let (plain, hand, d3) = (clean_price(y0, 30, false), by_hand(y0, 30, 1), by_hand(y0, 30, 3));
    let vv = 1.0 / (1.0 + y0 / 2.0); let annuity = vv.powf(4.0 / 6.0) * (2.0 * (1.0 - vv.powf(60.0)) / (1.0 - vv) + 100.0 * vv.powf(59.0)) - 2.0 / 3.0;
    ops(true); let pd = clean_price(dual(y0), 30, false); let (ops_v, ops_d) = ops(false);
    let p = clean_price(Ex(Rc::new(Node::Y)), 30, false); let dp = diff(&p, &mut HashMap::new()).unwrap();
    let (sym_p, sym_d) = (evaluate(&p, y0, &mut HashMap::new()), evaluate(&dp, y0, &mut HashMap::new()));
    let (up, down) = (clean_price(y0 + h, 30, false), clean_price(y0 - h, 30, false)); let (fwd, ctr) = ((up - plain) / h, (up - down) / (2.0 * h));
    set_mistake(1); let bad_prod = clean_price(dual(y0), 30, false).d;
    set_mistake(2); let bad_chain = clean_price(dual(y0), 30, false).d;
    set_mistake(0); let rnd = clean_price(dual(y0), 30, true).d;
    let rnd_bump = (clean_price(y0 + h, 30, true) - clean_price(y0, 30, true)) / h;
    let (d10, y6) = (clean_price(dual(y0), 10, false), clean_price(dual(0.06), 30, false));
    let rows = [("price, plain floats", plain), ("price, closed-form annuity", annuity),
        ("price, dual value part", pd.v), ("price, symbolic evaluated", sym_p),
        ("1 dP/dy, dual slope part", pd.d), ("2 dP/dy, symbolic derivative", sym_d), ("3 dP/dy, calculus by hand", hand),
        ("  gap, dual - by hand", pd.d - hand), ("  gap, symbolic - by hand", sym_d - hand), ("4 dP/dy, central 1bp bumps", ctr),
        ("  dP/dy, one-sided 1bp bump", fwd), ("  gap, one-sided bump - dual", fwd - pd.d), ("  gap, central bumps - dual", ctr - pd.d),
        ("  h^2 P'''/6, P''' by hand", h * h * d3 / 6.0), ("DV01 = -dP/dy x 0.0001", -pd.d * h),
        ("operations, dual run / plain run", (ops_v + ops_d) as f64 / ops_v as f64),
        ("price after +1bp", up), ("price change after +1bp", up - plain), ("modified duration -P'/P", -pd.d / plain),
        ("wrong: product rule half dropped", bad_prod), ("wrong: chain factor dropped", bad_chain),
        ("wrong: yield rounded to 1bp, AD", rnd), ("  same pricer, 1bp bump", rnd_bump),
        ("try: 10-year bond, price", d10.v), ("try: 10-year bond, dP/dy", d10.d),
        ("try: 30-year at 6%, price", y6.v), ("try: 30-year at 6%, dP/dy", y6.d)];
    for (name, v) in rows.iter() { println!("{:<34} {:>16.8}", name, v); }
    let lab = ["y", "y/2", "1 + y/2", "v = 1/(1 + y/2)", "log v", "w log v", "exp(w log v)", "2 x that"];
    let fs: [fn(Dual) -> Dual; 7] = [|a| a / Dual::c(2.0), |a| Dual::c(1.0) + a, |a| Dual::c(1.0) / a, |a| a.ln(),
        |a| Dual::c(4.0 / 6.0) * a, |a| a.exp(), |a| Dual::c(2.0) * a];
    let mut tr = vec![dual(y0)]; for f in fs { let x = f(*tr.last().unwrap()); tr.push(x); }
    for (name, d) in lab.iter().zip(tr.iter()) { println!("trace {:<16} value {:>12.8}  slope {:>12.8}", name, d.v, d.d); }
    println!("years  plain ops  dual ops  price nodes  slope nodes  distinct");
    for yrs in [1usize, 5, 10, 30] {
        ops(true); clean_price(dual(y0), yrs, false); let (a, b) = ops(false);
        let e = clean_price(Ex(Rc::new(Node::Y)), yrs, false);
        let (pn, mut seen) = (sizes(&e, &mut HashMap::new(), &mut HashSet::new()), HashSet::new());
        let sn = sizes(&diff(&e, &mut HashMap::new()).unwrap(), &mut HashMap::new(), &mut seen);
        println!("{:>5} {:>10} {:>9} {:>12} {:>12} {:>9}", yrs, a, a + b, pn, sn, seen.len());
    }
    assert!((plain - annuity).abs() < 1e-10, "price against the closed-form annuity formula");
    assert!((pd.v - plain).abs() < 1e-12, "the dual's value part is the plain price");
    assert!((pd.d - hand).abs() < 1e-9, "dual slope against calculus by hand");
    assert!((sym_d - hand).abs() < 1e-9, "symbolic derivative against calculus by hand");
    assert!((ctr - hand - h * h * d3 / 6.0).abs() < 2e-8, "central 1bp bump: error h^2 P'''/6 (next term 7e-10, rounding under 2e-8)");
    assert!((bad_prod - hand).abs() > 1.0 && (bad_chain - hand).abs() > 1.0, "broken rules must show");
    assert!((rnd - hand).abs() > 1000.0 && (rnd_bump - fwd).abs() < 1e-9, "rounding hides the slope");
    assert!((ops_v, ops_v + ops_d) == (3 * 60 + 8, 10 * 60 + 22), "operations counted by hand: 3n + 8 plain, 10n + 22 dual");
    println!("ALL CHECKS PASS");
}
