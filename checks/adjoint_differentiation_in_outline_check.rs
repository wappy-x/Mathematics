// Adjoint differentiation -- the same check as the Python, in Rust.  No crates.
// Rust has no erf, so the bell-curve area is built the honest way: thin slices
// under the curve (Simpson).  The tape, the reverse sweep, forward mode and the
// bumping are all written out here, as in the Python.
use std::f64::consts::PI;
const INP: u8 = 0; const ADD: u8 = 1; const SUB: u8 = 2; const MUL: u8 = 3;
const DIV: u8 = 4; const LN: u8 = 5; const EXP: u8 = 6; const SQRT: u8 = 7;
const NCDF: u8 = 8; const SCALE: u8 = 9;
type Node = (u8, usize, usize, f64);
type Slopes = Vec<Vec<(usize, f64)>>;

fn npdf(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }   // the curve's height at x
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64; let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0 }
fn ncdf(x: f64) -> f64 { 0.5 + simpson(npdf, 0.0, x, 4000) }      // bell-curve area left of x
fn evaluate(tape: &[Node], xs: &[f64]) -> (Vec<f64>, Slopes) {    // values, and every edge's slope
    let (mut v, mut sl): (Vec<f64>, Slopes) = (Vec::new(), Vec::new());
    for &(op, i, j, c) in tape {
        let (val, edges): (f64, Vec<(usize, f64)>) = match op {
            INP => (xs[i], vec![]), ADD => (v[i] + v[j], vec![(i, 1.0), (j, 1.0)]),
            SUB => (v[i] - v[j], vec![(i, 1.0), (j, -1.0)]),
            MUL => (v[i] * v[j], vec![(i, v[j]), (j, v[i])]),
            DIV => (v[i] / v[j], vec![(i, 1.0 / v[j]), (j, -v[i] / (v[j] * v[j]))]),
            LN => (v[i].ln(), vec![(i, 1.0 / v[i])]), EXP => (v[i].exp(), vec![(i, v[i].exp())]),
            SQRT => (v[i].sqrt(), vec![(i, 0.5 / v[i].sqrt())]),
            NCDF => (ncdf(v[i]), vec![(i, npdf(v[i]))]), _ => (c * v[i], vec![(i, c)]),
        };
        v.push(val); sl.push(edges);
    }
    (v, sl) }
fn sweep(tape: &[Node], sl: &Slopes, add: bool, back: bool) -> Vec<f64> {  // every node's adjoint,
    let n = tape.len(); let mut a = vec![0.0; n];   // and the inputs are nodes 0, 1, 2, ... in order
    a[n - 1] = 1.0;                          // seed: the answer's derivative with itself
    let order: Vec<usize> = if back { (0..n).rev().collect() } else { (0..n).collect() };
    for k in order {
        for &(p, s) in &sl[k] {
            let inc = a[k] * s;
            if add { a[p] += inc } else { a[p] = inc }   // add: a reused value collects each one
        }
    }
    a }

fn tangent(tape: &[Node], sl: &Slopes, seed: usize) -> f64 {   // forward mode, one input at a time
    let n = tape.len(); let mut t = vec![0.0; n];
    for (k, &(op, i, _, _)) in tape.iter().enumerate() {
        t[k] = if op == INP { if i == seed { 1.0 } else { 0.0 } }
               else { sl[k].iter().map(|&(p, s)| s * t[p]).sum::<f64>() };
    }
    t[n - 1] }
fn counts(tape: &[Node], sl: &Slopes) -> (usize, usize) {
    (tape.iter().filter(|nd| nd.0 != INP).count(), sl.iter().map(|e| e.len()).sum()) }
fn toy_tape() -> Vec<Node> {
    vec![(INP, 0, 0, 0.0), (INP, 1, 0, 0.0), (INP, 2, 0, 0.0), (INP, 3, 0, 0.0),  // S, r, q, T
         (SUB, 1, 2, 0.0), (MUL, 4, 3, 0.0),       // n4, n5 = r - q, then (r-q)T
         (EXP, 5, 0, 0.0), (MUL, 0, 6, 0.0)] }     // n6, n7 = e^((r-q)T), then F = S times it

fn bs_tape() -> Vec<Node> {
    vec![(INP, 0, 0, 0.0), (INP, 1, 0, 0.0), (INP, 2, 0, 0.0),      // n0..n2 = S, K, r
         (INP, 3, 0, 0.0), (INP, 4, 0, 0.0), (INP, 5, 0, 0.0),      // n3..n5 = q, sigma, T
         (SQRT, 5, 0, 0.0), (MUL, 4, 6, 0.0),       // n6, n7 = sqrt(T), one wiggle unit
         (DIV, 0, 1, 0.0), (LN, 8, 0, 0.0),         // n8, n9 = S/K, then ln(S/K)
         (SUB, 2, 3, 0.0),                          // n10 = r - q
         (MUL, 4, 4, 0.0), (SCALE, 11, 0, 0.5),     // n11, n12 = sigma*sigma, then half of it
         (ADD, 10, 12, 0.0), (MUL, 13, 5, 0.0),     // n13, n14 = the drift, then times T
         (ADD, 9, 14, 0.0), (DIV, 15, 7, 0.0),      // n15, n16 = d1's top, then d1
         (SUB, 16, 7, 0.0),                         // n17 = d2
         (NCDF, 16, 0, 0.0), (NCDF, 17, 0, 0.0),    // n18, n19 = N(d1), N(d2)
         (MUL, 3, 5, 0.0), (SCALE, 20, 0, -1.0), (EXP, 21, 0, 0.0),   // n20..n22 = e^-qT
         (MUL, 2, 5, 0.0), (SCALE, 23, 0, -1.0), (EXP, 24, 0, 0.0),   // n23..n25 = e^-rT
         (MUL, 0, 22, 0.0), (MUL, 26, 18, 0.0),     // n26, n27 = S e^-qT, then the share leg
         (MUL, 1, 25, 0.0), (MUL, 28, 19, 0.0),     // n28, n29 = K e^-rT, then the cash leg
         (SCALE, 29, 0, -1.0), (ADD, 27, 30, 0.0)] }  // n30, n31 = minus the cash leg, the price

fn closed(s: f64, k: f64, r: f64, q: f64, sg: f64, t: f64) -> Vec<f64> {   // the same six by hand
    let v = sg * t.sqrt(); let d1 = ((s / k).ln() + (r - q + 0.5 * sg * sg) * t) / v; let d2 = d1 - v;
    vec![(-q * t).exp() * ncdf(d1), -(-r * t).exp() * ncdf(d2),
         k * t * (-r * t).exp() * ncdf(d2), -s * t * (-q * t).exp() * ncdf(d1),
         s * (-q * t).exp() * npdf(d1) * t.sqrt(),
         s * (-q * t).exp() * npdf(d1) * sg / (2.0 * t.sqrt())
         - q * s * (-q * t).exp() * ncdf(d1) + r * k * (-r * t).exp() * ncdf(d2)] }

fn row(lab: &str, xs: &[f64]) {
    let mut ln = format!("  {:<48}", lab);
    for x in xs { ln.push_str(&format!("{:>13.6}", x)); } println!("{}", ln); }

fn worst(a: &[f64], b: &[f64]) -> f64 {
    a.iter().zip(b.iter()).map(|(p, q)| (p - q).abs()).fold(0.0_f64, f64::max) }

fn main() {
    let (bs, toy) = (bs_tape(), toy_tape());
    let names = ["S", "K", "r", "q", "sigma", "T"];
    let x = vec![100.0_f64, 100.0, 0.05, 0.02, 0.20, 1.0];
    let price = |xs: &[f64]| { let (v, _) = evaluate(&bs, xs); v[bs.len() - 1] };
    let grad = |xs: &[f64], a: bool, b: bool| { let (_, sl) = evaluate(&bs, xs); sweep(&bs, &sl, a, b) };
    let bumped = |k: usize, h: f64| {
        let (mut up, mut dn) = (x.clone(), x.clone()); up[k] += h; dn[k] -= h;
        (price(&up) - price(&dn)) / (2.0 * h)
    };
    let ty = [100.0_f64, 0.05, 0.02, 1.0];                  // the toy graph on the same market
    let (tv, tsl) = evaluate(&toy, &ty);
    let (tg, (tops, tedges)) = (sweep(&toy, &tsl, true, true), counts(&toy, &tsl));
    let gr = ((ty[1] - ty[2]) * ty[3]).exp();
    let tcl = [gr, ty[0] * ty[3] * gr, -ty[0] * ty[3] * gr, ty[0] * (ty[1] - ty[2]) * gr];
    println!("the toy graph: forward price F = S e^((r-q)T), {} operations, {} edges", tops, tedges);
    row("F, forward pass through the tape", &[tv[toy.len() - 1]]);
    for (nm, (a, b)) in ["dF/dS", "dF/dr", "dF/dq", "dF/dT"].iter().zip(tg.iter().zip(tcl.iter()))
        { println!("  {} by sweep {:>14.6}    the same by hand {:>14.6}", nm, a, b); }
    let (v, sl) = evaluate(&bs, &x);
    let (ops, edges) = counts(&bs, &sl);
    let c = v[bs.len() - 1];
    let g = sweep(&bs, &sl, true, true);        // g[0..6] are the six Greeks
    let cl = closed(x[0], x[1], x[2], x[3], x[4], x[5]);
    let bp: Vec<f64> = (0..6).map(|k| bumped(k, 1.0e-4)).collect();
    let fm: Vec<f64> = (0..6).map(|k| tangent(&bs, &sl, k)).collect();
    println!("\nthe Black-Scholes tape: 6 inputs, {} operations, {} edges", ops, edges);
    println!("  d1 {:.6}   d2 {:.6}   N(d1) {:.6}   N(d2) {:.6}", v[16], v[17], v[18], v[19]);
    row("call price, forward pass, then the house number", &[c, 9.227005508154]);
    println!("\nfive Greeks and the strike sensitivity, from ONE backward sweep");
    println!("  {:<7}{:>13}{:>14}{:>13}{:>14}", "input", "sweep", "by hand", "bumped", "forward mode");
    for k in 0..6
        { println!("  {:<7}{:>13.6}{:>14.6}{:>13.6}{:>14.6}", names[k], g[k], cl[k], bp[k], fm[k]); }
    println!("\nthe same five, named and scaled the way a desk quotes them");
    for (lab, val) in [("delta, per $1 on Acme", g[0]), ("vega, per volatility point", g[4] / 100.0),
                       ("rho, per basis point on r", g[2] / 10000.0),
                       ("psi, per basis point on q", g[3] / 10000.0),
                       ("theta, per calendar day", -g[5] / 365.0)] { row(lab, &[val]); }
    let (mut up, mut dn) = (x.clone(), x.clone()); up[0] += 0.01; dn[0] -= 0.01;
    let gam = (grad(&up, true, true)[0] - grad(&dn, true, true)[0]) / 0.02;
    let gcl = (-x[3] * x[5]).exp() * npdf(v[16]) / (x[0] * x[4] * x[5].sqrt());
    let pde = -g[5] + (x[2] - x[3]) * x[0] * g[0] + 0.5 * x[4] * x[4] * x[0] * x[0] * gam - x[2] * c;
    println!("\nadjoints picked out of the sweep, on the way to the Greeks");
    println!("  adj N(d1) {:>12.6}   adj N(d2) {:>12.6}   phi(d1) {:>10.6}   phi(d2) {:>10.6}",
             g[18], g[19], npdf(v[16]), npdf(v[17]));
    println!("  adj d1 {:>15.6}   adj d2 {:>12.6}   adj one wiggle unit {:>12.6}", g[16], g[17], g[7]);
    println!("\nfirst derivatives only: gamma costs a second pass");
    row("gamma, two sweeps a bump apart, then its formula", &[gam, gcl]);
    row("size of the Black-Scholes equation residual", &[pde.abs()]);
    row("S dC/dS + K dC/dK, then the price itself", &[x[0] * g[0] + x[1] * g[1], c]);
    println!("\ncost, counted in forward passes through the tape");
    println!("  {:<48}{:>13}", "forward pass, operations", ops);
    println!("  {:<48}{:>13}", "backward sweep, multiply-and-adds", edges);
    let cost = edges as f64 / ops as f64;
    row("the sweep alone", &[cost]);
    row("price and all six derivatives, adjoint", &[1.0 + cost]);
    row("price and all six by central differences", &[13.0]);
    let (mut l1, mut l2, mut l3) = (String::from("chart, sensitivities asked for "),
        String::from("chart, central differences     "), String::from("chart, adjoint, one sweep      "));
    for k in 1..=6 {
        l1.push_str(&format!("{:>6}", k)); l2.push_str(&format!("{:>6.2}", 2.0 * k as f64 + 1.0));
        l3.push_str(&format!("{:>6.2}", 1.0 + cost)); }
    println!("{}\n{}\n{}", l1, l2, l3);
    println!("\nwhat breaks");
    row("overwrite instead of add: dC/dsigma, then right", &[grad(&x, false, true)[4], g[4]]);
    row("swept forward, not in reverse: dC/dS, then right", &[grad(&x, true, false)[0], g[0]]);
    row("theta taken as +dC/dT per year, then right", &[g[5], -g[5]]);
    row("delta from a $10 bump, then right", &[bumped(0, 10.0), g[0]]);
    assert!((c - 9.227005508154).abs() < 1e-9, "tape price vs the house number");
    assert!(worst(&g, &cl) < 1e-9, "sweep vs the hand-differentiated forms");
    assert!(worst(&g, &bp) < 1e-5, "sweep vs central differences");
    assert!(worst(&g, &fm) < 1e-12, "sweep vs forward mode");
    assert!((x[0] * g[0] + x[1] * g[1] - c).abs() < 1e-9, "S dC/dS + K dC/dK must be the price");
    assert!((gam - gcl).abs() < 1e-7 && pde.abs() < 1e-6, "gamma, and the Black-Scholes equation");
    assert!(worst(&tg, &tcl) < 1e-12, "toy sweep vs its hand-made forms");
    assert!((ops, edges) == (26, 42), "the tape this card describes");
    println!("ALL CHECKS PASS");
}
