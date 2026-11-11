// Automatic differentiation on the Rosenbrock valley: the check behind the card.
// std only.  Four roads to the gradient: forward mode (dual numbers), reverse
// mode (a tape swept backwards), the hand formula, and finite differences.
// Every arithmetic operation on a number is counted, so the costs are measured.
use std::cell::{Cell, RefCell};
use std::ops::{Add, Mul, Sub};

thread_local! {
    static OPS: Cell<usize> = Cell::new(0);                          // operations counted so far
    static TAPE: RefCell<Vec<Vec<(usize, f64)>>> = RefCell::new(Vec::new()); // one entry per operation
}
fn count(k: usize) { OPS.with(|o| o.set(o.get() + k)); }
fn ops() -> usize { OPS.with(|o| o.get()) }
fn reset() { OPS.with(|o| o.set(0)); }

#[derive(Clone, Copy)]
struct Dual { a: f64, b: f64 }                    // a + b*eps with eps*eps = 0
impl Add for Dual { type Output = Dual; fn add(self, o: Dual) -> Dual { count(2); Dual { a: self.a + o.a, b: self.b + o.b } } }
impl Sub for Dual { type Output = Dual; fn sub(self, o: Dual) -> Dual { count(2); Dual { a: self.a - o.a, b: self.b - o.b } } }
impl Mul for Dual { type Output = Dual; fn mul(self, o: Dual) -> Dual { count(4); Dual { a: self.a * o.a, b: self.a * o.b + self.b * o.a } } }
fn dual(a: f64, b: f64) -> Dual { Dual { a, b } }

#[derive(Clone, Copy)]
struct Node { v: f64, i: usize }                  // a value and its place on the tape
fn node(v: f64, parents: Vec<(usize, f64)>) -> Node {
    TAPE.with(|t| { let mut t = t.borrow_mut(); t.push(parents); Node { v, i: t.len() - 1 } })
}
impl Add for Node { type Output = Node; fn add(self, o: Node) -> Node { count(1); node(self.v + o.v, vec![(self.i, 1.0), (o.i, 1.0)]) } }
impl Sub for Node { type Output = Node; fn sub(self, o: Node) -> Node { count(1); node(self.v - o.v, vec![(self.i, 1.0), (o.i, -1.0)]) } }
impl Mul for Node { type Output = Node; fn mul(self, o: Node) -> Node { count(1); node(self.v * o.v, vec![(self.i, o.v), (o.i, self.v)]) } }
fn leaf(v: f64) -> Node { node(v, vec![]) }

fn backward(out: Node, overwrite: bool) -> Vec<f64> {   // the reverse sweep, last operation first
    TAPE.with(|t| {
        let (t, mut adj) = (t.borrow(), vec![0.0; t.borrow().len()]);
        adj[out.i] = 1.0;
        for k in (0..t.len()).rev() {
            for &(p, slope) in &t[k] {
                count(2);
                adj[p] = if overwrite { adj[k] * slope } else { adj[p] + adj[k] * slope };
            }
        }
        adj
    })
}

fn rosen<T: Copy + Add<Output = T> + Sub<Output = T> + Mul<Output = T>>(x: &[T], k: impl Fn(f64) -> T) -> (T, Vec<T>) {
    let mut f: Option<T> = None;
    let mut first = vec![];
    for i in 0..x.len() - 1 {
        let s = x[i] * x[i]; let d = x[i + 1] - s; let c = k(1.0) - x[i];
        let dd = d * d; let t = k(100.0) * dd; let u = c * c; let term = t + u;
        f = Some(match f { None => term, Some(g) => g + term });
        if i == 0 { first = vec![s, d, c, dd, t, u, term]; }
    }
    (f.unwrap(), first)
}
fn plain(x: &[f64]) -> f64 { rosen(x, |c| c).0 }

fn hand(x: &[f64]) -> Vec<f64> {
    let (n, mut g) = (x.len(), vec![0.0; x.len()]);
    for j in 0..n {
        if j < n - 1 { g[j] += -400.0 * x[j] * (x[j + 1] - x[j] * x[j]) - 2.0 * (1.0 - x[j]); }
        if j > 0 { g[j] += 200.0 * (x[j] - x[j - 1] * x[j - 1]); }
    }
    g
}

fn forward_mode(x: &[f64]) -> Vec<f64> {
    (0..x.len()).map(|j| {
        let xs: Vec<Dual> = x.iter().enumerate().map(|(i, &v)| dual(v, if i == j { 1.0 } else { 0.0 })).collect();
        rosen(&xs, |c| dual(c, 0.0)).0.b
    }).collect()
}

fn reverse_mode(x: &[f64], overwrite: bool) -> (Vec<f64>, Vec<Node>, Vec<f64>) {
    TAPE.with(|t| t.borrow_mut().clear());
    let xs: Vec<Node> = x.iter().map(|&v| leaf(v)).collect();
    let (f, first) = rosen(&xs, leaf);
    let adj = backward(f, overwrite);
    (xs.iter().map(|n| adj[n.i]).collect(), first, adj)
}

fn fd(h: f64, central: bool) -> f64 {
    let up = plain(&[-1.2 + h, 1.0]);
    let down = if central { plain(&[-1.2 - h, 1.0]) } else { plain(&[-1.2, 1.0]) };
    (up - down) / if central { 2.0 * h } else { h }
}

fn cost(x: &[f64]) -> (usize, usize, usize, Vec<f64>, Vec<f64>) {   // one evaluation, forward, reverse
    TAPE.with(|t| t.borrow_mut().clear()); reset();
    rosen(&x.iter().map(|&v| leaf(v)).collect::<Vec<_>>(), leaf);
    let l = ops();
    reset(); let g_f = forward_mode(x); let c_f = ops();
    reset(); let g_r = reverse_mode(x, false).0; let c_r = ops();
    println!("operations at n = {}: evaluation {}, forward mode {}, central differences {}, reverse mode {}",
             x.len(), l, c_f, 2 * x.len() * l, c_r);
    assert!(l == 8 * (x.len() - 1) - 1 && c_r == 5 * l);           // 7 a link, plus the joining additions
    (l, c_f, c_r, g_f, g_r)
}

fn main() {
    // ---- the 2-D valley at the classic start (-1.2, 1), traced line by line ----
    let x2 = [-1.2, 1.0];
    let (_, fx) = rosen(&[dual(-1.2, 1.0), dual(1.0, 0.0)], |c| dual(c, 0.0));
    let (_, fy) = rosen(&[dual(-1.2, 0.0), dual(1.0, 1.0)], |c| dual(c, 0.0));
    let (g_rev, first, adj) = reverse_mode(&x2, false);
    println!("2-D valley at (x, y) = (-1.2, 1); tangents seeded x-dot = 1");
    println!("{:<12}{:>12}{:>13}{:>13}", "line", "value", "tangent", "adjoint");
    let names = ["s = x*x", "d = y - s", "c = 1 - x", "dd = d*d", "t = 100*dd", "u = c*c", "f = t + u"];
    for k in 0..7 { println!("{:<12}{:12.6}{:13.6}{:13.6}", names[k], fx[k].a, fx[k].b, adj[first[k].i]); }
    let g_hand = hand(&x2);
    println!("df/dx: forward {:.6}  reverse {:.6}  hand {:.6}", fx[6].b, g_rev[0], g_hand[0]);
    println!("df/dy: forward {:.6}  reverse {:.6}  hand {:.6}", fy[6].b, g_rev[1], g_hand[1]);
    assert!((fx[6].b - (-215.6)).abs() < 1e-12 && (fy[6].b - (-88.0)).abs() < 1e-12);
    assert!((g_rev[0] - g_hand[0]).abs() < 1e-12 && (g_rev[1] - g_hand[1]).abs() < 1e-12);

    // ---- finite differences: the step size has no right answer ----
    let (mut hs, mut p) = (vec![], 1.0);
    for _ in 1..15 { p *= 10.0; hs.push(1.0 / p); }
    let fwd_err: Vec<f64> = hs.iter().map(|&h| (fd(h, false) - (-215.6)).abs().log10()).collect();
    let cen_err: Vec<f64> = hs.iter().map(|&h| (fd(h, true) - (-215.6)).abs().log10()).collect();
    println!("chart, log10 h            {}", (1..15).map(|k: i32| format!("{:6}", -k)).collect::<Vec<_>>().join(" "));
    println!("chart, forward, log10 err {}", fwd_err.iter().map(|e| format!("{:6.2}", e)).collect::<Vec<_>>().join(" "));
    println!("chart, central, log10 err {}", cen_err.iter().map(|e| format!("{:6.2}", e)).collect::<Vec<_>>().join(" "));
    let argmin = |v: &Vec<f64>| (0..v.len()).fold(0, |b, i| if v[i] < v[b] { i } else { b });
    let (bf, bc) = (argmin(&fwd_err), argmin(&cen_err));
    println!("best forward difference error 10^{:.2} at h = 1e-{}; best central 10^{:.2} at h = 1e-{}",
             fwd_err[bf], bf + 1, cen_err[bc], bc + 1);
    assert!(fwd_err[0] > 1.0 && fwd_err[13] > -1.0 && fwd_err[bf] < -5.0);

    // ---- what breaks ----
    let (bad, _, _) = reverse_mode(&x2, true);
    let both = rosen(&[dual(-1.2, 1.0), dual(1.0, 1.0)], |c| dual(c, 0.0)).0.b;
    println!("mistake, = instead of +=: df/dx {:.6}  df/dy {:.6}", bad[0], bad[1]);
    println!("mistake, both tangents seeded at once: {:.6}", both);
    println!("mistake, forward difference h = 0.1: {:.6}", fd(0.1, false));
    println!("mistake, forward difference h = 1e-12: {:.6}", fd(hs[11], false));
    assert!((both - (g_hand[0] + g_hand[1])).abs() < 1e-12 && (bad[0] - g_hand[0]).abs() > 100.0);
    let sq = |x: Dual| if x.a == 1.0 { dual(1.0, 0.0) } else { x * x };   // one shortcut branch
    let (ad_kink, true_kink) = (sq(dual(1.0, 1.0)).b, (dual(1.0, 1.0) * dual(1.0, 1.0)).b);   // branch; plain x * x
    let fd_kink = (sq(dual(1.0 + 1e-6, 0.0)).a - sq(dual(1.0 - 1e-6, 0.0)).a) / 2e-6;     // through the routine itself
    println!("branch x == 1: AD says {:.6}, true {:.6}, central difference {:.6}", ad_kink, true_kink, fd_kink);
    assert!(ad_kink == 0.0 && (true_kink - 2.0f64).abs() < 1e-12 && (fd_kink - true_kink).abs() < 1e-6);

    // ---- 50 inputs: every partial, and what each road costs ----
    let n = 50;
    let x: Vec<f64> = (0..n).map(|i| if i % 2 == 0 { -1.2 } else { 1.0 }).collect();
    let (f50, g_h, h) = (plain(&x), hand(&x), 1e-6);
    let g_cd: Vec<f64> = (0..n).map(|j| {
        let (mut a, mut b) = (x.clone(), x.clone());
        a[j] += h; b[j] -= h;
        (plain(&a) - plain(&b)) / (2.0 * h)
    }).collect();
    println!("50-D valley, start (-1.2, 1, -1.2, 1, ...): f = {:.6}", f50);
    cost(&x2);
    let (l, c_fwd, c_rev, g_fwd, g_r) = cost(&x);
    println!("at n = 50, in evaluations: forward {:.1}, central {:.1}, reverse {:.1}",
             c_fwd as f64 / l as f64, (2 * n) as f64, c_rev as f64 / l as f64);
    let gap = |u: &Vec<f64>, v: &Vec<f64>| u.iter().zip(v).fold(0.0f64, |m, (a, b)| m.max((a - b).abs()));
    let (gap_fr, gap_rh, gap_ch) = (gap(&g_fwd, &g_r), gap(&g_r, &g_h), gap(&g_cd, &g_h));
    println!("partials 1, 2, 3, 49, 50: {}", [0, 1, 2, 48, 49].iter().map(|&j| format!("{:.6}", g_r[j])).collect::<Vec<_>>().join(", "));
    println!("largest gap: forward vs reverse {:.12}, reverse vs hand {:.12}", gap_fr, gap_rh);
    println!("largest gap: central difference (h = 1e-6) vs hand {:.6}", gap_ch);
    assert!(gap_fr < 1e-9 && gap_rh < 1e-9 && gap_ch < 1e-3);
    assert!((f50 - 12221.0).abs() < 1e-9 && (g_r[1] - 792.0).abs() < 1e-9 && (g_r[2] + 655.6).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
