// Boolean circuits -- the same check as the Python, in Rust.  No crates.  A k-bit adder
// is built from AND, OR and NOT gates three ways: a ripple-carry circuit that shares gates,
// the same adder as a formula (a tree: a shared part is copied each time it is used) and a
// carry-lookahead circuit.  Each runs on real sums; sizes and depths are counted, not assumed.
use std::rc::Rc;

trait Build { type N: Clone; fn and(&mut self, x: Self::N, y: Self::N) -> Self::N;
    fn or(&mut self, x: Self::N, y: Self::N) -> Self::N; fn not(&mut self, x: Self::N) -> Self::N; }

struct Circuit { ops: Vec<(u8, usize, usize)>, n: usize }   // op 0 input, 1 NOT, 2 AND, 3 OR
impl Circuit {
    fn new(n: usize) -> Circuit { Circuit { ops: (0..n).map(|i| (0, i, 0)).collect(), n } }
    fn add(&mut self, op: u8, x: usize, y: usize) -> usize { self.ops.push((op, x, y)); self.ops.len() - 1 }
    fn size(&self) -> usize { self.ops.len() - self.n }
    fn depths(&self) -> Vec<usize> {                         // gates on the longest path from an input
        let mut d: Vec<usize> = Vec::new();
        for &(op, x, y) in &self.ops { let v = match op { 0 => 0, 1 => 1 + d[x], _ => 1 + d[x].max(d[y]) }; d.push(v); }
        d
    }
    fn run(&self, bits: &[u8]) -> Vec<u8> {
        let mut v: Vec<u8> = Vec::new();
        for &(op, x, y) in &self.ops { let w = match op { 0 => bits[x], 1 => 1 - v[x], 2 => v[x] & v[y], _ => v[x] | v[y] }; v.push(w); }
        v
    }
}
impl Build for Circuit { type N = usize;
    fn and(&mut self, x: usize, y: usize) -> usize { self.add(2, x, y) }
    fn or(&mut self, x: usize, y: usize) -> usize { self.add(3, x, y) }
    fn not(&mut self, x: usize) -> usize { self.add(1, x, 0) } }

enum T { In(usize), Not(Rc<T>), And(Rc<T>, Rc<T>), Or(Rc<T>, Rc<T>) }   // a formula: a tree
struct Formula;
impl Build for Formula { type N = Rc<T>;
    fn and(&mut self, x: Rc<T>, y: Rc<T>) -> Rc<T> { Rc::new(T::And(x, y)) }
    fn or(&mut self, x: Rc<T>, y: Rc<T>) -> Rc<T> { Rc::new(T::Or(x, y)) }
    fn not(&mut self, x: Rc<T>) -> Rc<T> { Rc::new(T::Not(x)) } }
fn t_size(t: &T) -> usize { match t { T::In(_) => 0, T::Not(x) => 1 + t_size(x), T::And(x, y) | T::Or(x, y) => 1 + t_size(x) + t_size(y) } }
fn t_depth(t: &T) -> usize { match t { T::In(_) => 0, T::Not(x) => 1 + t_depth(x), T::And(x, y) | T::Or(x, y) => 1 + t_depth(x).max(t_depth(y)) } }
fn t_eval(t: &T, b: &[u8]) -> u8 { match t { T::In(i) => b[*i], T::Not(x) => 1 - t_eval(x, b),
    T::And(x, y) => t_eval(x, b) & t_eval(y, b), T::Or(x, y) => t_eval(x, b) | t_eval(y, b) } }

fn xor<B: Build>(m: &mut B, x: B::N, y: B::N) -> (B::N, B::N) {   // (x OR y) AND NOT(x AND y)
    let both = m.and(x.clone(), y.clone()); let o = m.or(x, y); let nb = m.not(both.clone());
    (m.and(o, nb), both)
}
fn ripple<B: Build>(m: &mut B, a: &[B::N], b: &[B::N]) -> Vec<B::N> {
    let (s, mut c) = xor(m, a[0].clone(), b[0].clone());   // bit 0: sum bit, and carry a0 AND b0
    let mut out = vec![s];
    for i in 1..a.len() {
        let (t, h) = xor(m, a[i].clone(), b[i].clone());  // t = a XOR b, h = a AND b
        let (s, u) = xor(m, t, c.clone());                 // sum bit, and u = t AND carry-in
        out.push(s); c = m.or(h, u);
    }
    out.push(c); out
}
fn lookahead(m: &mut Circuit, k: usize) -> Vec<usize> {    // Kogge-Stone: spans double each round
    let g: Vec<usize> = (0..k).map(|i| m.and(i, k + i)).collect();
    let p: Vec<usize> = (0..k).map(|i| m.or(i, k + i)).collect();
    let x: Vec<usize> = (0..k).map(|i| { let ng = m.not(g[i]); m.and(p[i], ng) }).collect();
    let (mut gg, mut pp, mut d) = (g.clone(), p.clone(), 1);
    while d < k {
        let mut g2 = gg.clone(); let mut p2 = pp.clone();
        for i in d..k { let t = m.and(pp[i], gg[i - d]); g2[i] = m.or(gg[i], t); }
        if 2 * d < k { for i in d..k { p2[i] = m.and(pp[i], pp[i - d]); } }
        gg = g2; pp = p2; d *= 2;
    }
    let mut out = vec![x[0]];
    for i in 1..k { out.push(xor(m, x[i], gg[i - 1]).0); }
    out.push(gg[k - 1]); out
}
fn bits_of(a: u128, b: u128, k: usize) -> Vec<u8> { (0..k).map(|i| (a >> i & 1) as u8).chain((0..k).map(|i| (b >> i & 1) as u8)).collect() }
fn value(bits: &[u8]) -> u128 { bits.iter().enumerate().map(|(i, &v)| (v as u128) << i).sum() }
fn build_ripple(k: usize) -> (Circuit, Vec<usize>) { let mut m = Circuit::new(2 * k); let ins: Vec<usize> = (0..2 * k).collect(); let o = ripple(&mut m, &ins[..k], &ins[k..]); (m, o) }
fn formula(k: usize) -> Vec<Rc<T>> { let ins: Vec<Rc<T>> = (0..2 * k).map(|i| Rc::new(T::In(i))).collect(); ripple(&mut Formula, &ins[..k], &ins[k..]) }
fn run_sum(m: &Circuit, outs: &[usize], a: u128, b: u128, k: usize) -> u128 { let v = m.run(&bits_of(a, b, k)); value(&outs.iter().map(|&o| v[o]).collect::<Vec<u8>>()) }
fn f_sum(fo: &[Rc<T>], a: u128, b: u128, k: usize) -> u128 { let bits = bits_of(a, b, k); value(&fo.iter().map(|t| t_eval(t, &bits)).collect::<Vec<u8>>()) }
fn join(v: Vec<String>, sep: &str) -> String { v.join(sep) }

const A: u8 = 0b1100; const B: u8 = 0b1010; const ALL: u8 = 0b1111; const XOR: u8 = 0b0110; const CARRY: u8 = 0b1000;
fn fits(nodes: &mut Vec<u8>, targets: &[u8], left: usize) -> bool {   // can `left` more gates reach every target?
    if targets.iter().all(|t| nodes.contains(t)) { return true; }
    if left == 0 { return false; }
    let n = nodes.len();
    let mut new: Vec<u8> = nodes.iter().map(|x| ALL ^ x).collect();
    for i in 0..n { for j in i + 1..n { new.push(nodes[i] & nodes[j]); new.push(nodes[i] | nodes[j]); } }
    for w in new { nodes.push(w); let ok = fits(nodes, targets, left - 1); nodes.pop(); if ok { return true; } }
    false
}
fn least_gates(targets: &[u8]) -> usize { (0..9).find(|&g| fits(&mut vec![A, B], targets, g)).unwrap() }
fn least_depth(t: u8) -> usize {
    let (mut level, mut d) = ([false; 16], 0);
    level[A as usize] = true; level[B as usize] = true;
    while !level[t as usize] {
        let mut next = level;
        for x in 0..16u8 { if !level[x as usize] { continue; } next[(ALL ^ x) as usize] = true;
            for y in 0..16u8 { if level[y as usize] { next[(x & y) as usize] = true; next[(x | y) as usize] = true; } } }
        level = next; d += 1;
    }
    d
}
fn adder2(a: u128, b: u128, slip: &str) -> u128 {          // the 2-bit adder in plain bit arithmetic, one piece swapped
    let (a0, a1, b0, b1) = (a & 1, a >> 1, b & 1, b >> 1);
    let c0 = if slip == "carry into bit 1 dropped" { 0 } else { a0 & b0 };
    let s0 = if slip == "OR for the sum bit" { a0 | b0 } else { a0 ^ b0 };
    let mut s2 = (a1 & b1) | ((a1 ^ b1) & c0);
    if slip == "answer cut to two bits" { s2 = 0 } else if slip == "carry out as a1 AND b1" { s2 = a1 & b1 }
    s0 + 2 * (a1 ^ b1 ^ c0) + 4 * s2
}
fn wide_tree(fan: usize, d: usize) -> (usize, usize) {     // a tree of gates with `fan` inputs each: (gates, depth)
    if d == 0 { (0, 0) } else { let (s, e) = wide_tree(fan, d - 1); (1 + fan * s, 1 + e) }
}

fn main() {
    let (m, outs) = build_ripple(2); let dep = m.depths(); let dmax = *dep.iter().max().unwrap();
    let name = |j: usize| -> String { if j < 4 { ["a0", "a1", "b0", "b1"][j].to_string() } else { format!("g{}", j - 3) } };
    println!("2-bit adder circuit: {} gates, depth {}; output depths {}", m.size(), dmax,
             join(outs.iter().enumerate().map(|(i, &o)| format!("s{}={}", i, dep[o])).collect(), " "));
    let mut ok = 0; for a in 0..4u128 { for b in 0..4u128 { if run_sum(&m, &outs, a, b, 2) == a + b { ok += 1; } } }
    println!("circuit right on {} of 16 inputs", ok);
    let v = m.run(&bits_of(1, 3, 2));
    println!("trace 1 + 3: {} -> s2 s1 s0 = {}{}{} = {}", join((4..v.len()).map(|j| format!("{}={}", name(j), v[j])).collect(), " "),
             v[outs[2]], v[outs[1]], v[outs[0]], value(&outs.iter().map(|&o| v[o]).collect::<Vec<u8>>()));
    let cols: Vec<String> = (0..=dmax).map(|c| format!("{}: {}", c, join((0..dep.len()).filter(|&j| dep[j] == c).map(|j| name(j)).collect(), " "))).collect();
    println!("figure, depth columns: {}", join(cols, " | "));
    let fo = formula(2);
    let fs: Vec<usize> = fo.iter().map(|t| t_size(t)).collect(); let fd: Vec<usize> = fo.iter().map(|t| t_depth(t)).collect();
    let mut fok = 0; for a in 0..4u128 { for b in 0..4u128 { if f_sum(&fo, a, b, 2) == a + b { fok += 1; } } }
    println!("formula: s0={} s1={} s2={} gates, {} in all; depths {}, {}, {}; right on {} of 16 inputs",
             fs[0], fs[1], fs[2], fs.iter().sum::<usize>(), fd[0], fd[1], fd[2], fok);
    println!("unfolding bound, size <= 2^depth - 1: {}", join((0..3).map(|i| format!("{} <= {}", fs[i], (1usize << fd[i]) - 1)).collect(), ", "));
    assert!(ok == 16 && fok == 16 && (0..3).all(|i| fd[i] == dep[outs[i]] && fs[i] <= (1usize << fd[i]) - 1));
    assert!(fs.iter().sum::<usize>() == 2 * m.size());

    let (lx, dx, lh) = (least_gates(&[XOR]), least_depth(XOR), least_gates(&[XOR, CARRY]));
    let mut xc = Circuit::new(2); xor(&mut xc, 0, 1);
    println!("search: XOR needs {} gates (none with {}) and depth {}; half adder (sum and carry) needs {} gates", lx, lx - 1, dx, lh);
    assert!(lx == xc.size() && dx == *xc.depths().iter().max().unwrap() && lh == lx);

    let mut state: u64 = 2026;                               // SplitMix64, seed 2026, for test sums
    let mut splitmix = || -> u128 { state = state.wrapping_add(0x9E3779B97F4A7C15); let mut z = state;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9); z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB); (z ^ (z >> 31)) as u128 };
    for &k in &[1usize, 2, 4, 8, 16, 32, 64] {
        let (r, ro) = build_ripple(k); let mut l = Circuit::new(2 * k); let lo = lookahead(&mut l, k); let fo = formula(k);
        let fsz: usize = fo.iter().map(|t| t_size(t)).sum();
        let (rd, ld) = (*r.depths().iter().max().unwrap(), *l.depths().iter().max().unwrap());
        let top: u128 = (1u128 << k) - 1;
        let mut pairs: Vec<(u128, u128)> = Vec::new();
        if k <= 4 { for a in 0..=top { for b in 0..=top { pairs.push((a, b)); } } }
        else { pairs.push((top, 1)); for _ in 0..40 { let a = splitmix() & top; let b = splitmix() & top; pairs.push((a, b)); } }
        let good = pairs.iter().filter(|&&(a, b)| run_sum(&r, &ro, a, b, k) == a + b && run_sum(&l, &lo, a, b, k) == a + b && f_sum(&fo, a, b, k) == a + b).count();
        println!("k={}: ripple {} gates, depth {}; formula {} gates; lookahead {} gates, depth {}; {} of {} sums right",
                 k, r.size(), rd, fsz, l.size(), ld, good, pairs.len());
        let ceil_log = (usize::BITS - (k - 1).leading_zeros()) as usize;
        assert!(good == pairs.len() && r.size() == 9 * k - 5 && fsz == 7 * k * k - 2);
        assert!(rd == (if k == 1 { 3 } else { 2 * k + 2 }) && fo.iter().map(|t| t_depth(t)).max().unwrap() == rd && ld <= 2 * ceil_log + 4);
    }

    let mut miss = vec![(0..16u128).filter(|&i| adder2(i / 4, i % 4, "none") != i / 4 + i % 4).count()];
    for slip in ["OR for the sum bit", "carry into bit 1 dropped", "carry out as a1 AND b1", "answer cut to two bits"] {
        let bad: Vec<(u128, u128)> = (0..16u128).map(|i| (i / 4, i % 4)).filter(|&(a, b)| adder2(a, b, slip) != a + b).collect();
        let (a, b) = bad[bad.len() - 1]; miss.push(bad.len());
        println!("mistake, {}: wrong on {} of 16, e.g. {} + {} -> {}", slip, bad.len(), a, b, adder2(a, b, slip));
    }
    let (ws, wd) = wide_tree(3, 2);                           // an OR of three ANDs, 3 inputs a gate
    println!("mistake, gates with 3 inputs: an OR of three ANDs, depth {}, {} gates; bound 2^{} - 1 = {}", wd, ws, wd, (1usize << wd) - 1);
    assert!(miss == vec![0, 4, 4, 2, (0..16u128).filter(|&i| i / 4 + i % 4 >= 4).count()]);
    assert!(ws == (3usize.pow(wd as u32) - 1) / 2 && ws > (1usize << wd) - 1);   // a 3-input tree beats the bound
    println!("ALL CHECKS PASS");
}
