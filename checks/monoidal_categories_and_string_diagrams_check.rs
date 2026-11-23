// Monoidal categories and string diagrams -- the same check as the Python, in
// Rust.  No crates.  Two parcels ride two lanes: A (1,200 g) through a box
// machine, B (800 g) through a wrap machine, then both through pricing, and a
// merge adds the two bills.  Road one reads the diagram stage by stage, road
// two lane by lane, road three slides one box past the other; a search then
// checks the same law for every function on a two-member set, and the swap and
// the brackets too.
fn bx(w: i64) -> i64 { w + 150 }                      // f: adds 150 g of cardboard
fn wrap(w: i64) -> i64 { w + 50 }                     // g: adds 50 g of bubble wrap
fn price(w: i64) -> i64 { 300 + w / 10 }              // f' = g': 300 p plus 1 p per 10 g
fn merge(p: (i64, i64)) -> i64 { p.0 + p.1 }          // two wires in, one wire out
fn id(x: i64) -> i64 { x }
fn tensor(f: fn(i64) -> i64, g: fn(i64) -> i64, p: (i64, i64)) -> (i64, i64) { (f(p.0), g(p.1)) }
fn assoc<A, B, C>(t: ((A, B), C)) -> (A, (B, C)) { (t.0 .0, (t.0 .1, t.1)) }
type T = [usize; 2];                                   // a function {0,1} -> {0,1}, as its table
fn ten(f: T, g: T, p: (usize, usize)) -> (usize, usize) { (f[p.0], g[p.1]) }
fn then(f: T, g: T) -> T { [g[f[0]], g[f[1]]] }        // in turn: f, then g
fn swap(p: (usize, usize)) -> (usize, usize) { (p.1, p.0) }
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
type M = Vec<Vec<i64>>;
fn kron(m: &M, n: &M) -> M { (0..4).map(|i| (0..4).map(|j| m[i / 2][j / 2] * n[i % 2][j % 2]).collect()).collect() }
fn mul(m: &M, n: &M) -> M {
    (0..m.len()).map(|i| (0..n[0].len()).map(|j| (0..n.len()).map(|t| m[i][t] * n[t][j]).sum()).collect()).collect()
}

fn main() {
    let parcels = (1200, 800);
    let by_stage = tensor(price, price, tensor(bx, wrap, parcels));
    let by_lane = (price(bx(parcels.0)), price(wrap(parcels.1)));
    let slid = tensor(price, price, tensor(bx, id, tensor(id, wrap, parcels)));
    println!("parcels in: A {} g, B {} g", parcels.0, parcels.1);
    println!("after box and wrap, side by side: {:?}", tensor(bx, wrap, parcels));
    println!("road 1, stage by stage: bills {:?} pence", by_stage);
    println!("road 2, lane by lane:   bills {:?} pence", by_lane);
    println!("road 3, wrap slid before box: bills {:?} pence", slid);
    println!("merge the two wires into one: {} pence", merge(by_stage));

    let fns: Vec<T> = vec![[0, 0], [0, 1], [1, 0], [1, 1]];
    let idt: T = [0, 1];
    let pairs = [(0, 0), (0, 1), (1, 0), (1, 1)];
    let (mut law, mut slide, mut cross, mut quads) = (0, 0, 0, 0);
    for &f in &fns { for &g in &fns { for &h in &fns { for &k in &fns {
        quads += 1;
        for &p in &pairs {
            if ten(h, k, ten(f, g, p)) != ten(then(f, h), then(g, k), p) { law += 1 }
            if ten(f, idt, ten(idt, g, p)) != ten(idt, g, ten(f, idt, p)) { slide += 1 }
        }
    }}}}
    for &f in &fns { for &g in &fns { for &p in &pairs { if swap(ten(f, g, p)) != ten(g, f, swap(p)) { cross += 1 } } } }
    let twice = pairs.iter().filter(|&&p| swap(swap(p)) != p).count();
    println!("all functions on {{0, 1}}: {}; quadruples {}, inputs checked {}", fns.len(), quads, quads * pairs.len());
    println!("interchange failures {}; sliding failures {}; crossing failures {}; swap twice failures {}", law, slide, cross, twice);

    let mut agree = 0;
    let mut members = 0;
    for a in 0..2 { for b in 0..2 { for c in 0..2 { for d in 0..2 {
        let x = (((a, b), c), d);
        members += 1;
        let p1 = assoc(assoc(x));
        let z = assoc((assoc(x.0), x.1));
        let p2 = (z.0, assoc(z.1));
        if p1 == p2 { agree += 1 }
    }}}}
    println!("pentagon: {} members of ((A x B) x C) x D, the two re-bracketings agree on {}", members, agree);
    let x = ((0, 1), 0);
    let same = format!("{:?}", x) == format!("{:?}", assoc(x));
    let mut left3 = Vec::new();                         // (A x B) x C, listed
    for a in 0..2 { for b in 0..2 { for c in 0..2 { left3.push(((a, b), c)) } } }
    let images: std::collections::BTreeSet<(i32, (i32, i32))> = left3.iter().map(|&t| assoc(t)).collect();
    println!("brackets: {:?} becomes {:?}; the same element: {}; both sets have {} members, matched one for one: {}",
             x, assoc(x), yn(same), left3.len(), yn(images.len() == left3.len()));
    let unit: Vec<(i64, ())> = [0, 1, 2].iter().map(|&a| (a, ())).collect();
    println!("unit: A = {{0, 1, 2}} beside the one-point set has {} members", unit.len());

    let labels = |order: [char; 2]| { let mut out = [0; 2]; for (n, &lane) in order.iter().enumerate() { out[if lane == 'A' { 0 } else { 1 }] = n + 1 } out };
    let (l1, l2) = (labels(['A', 'B']), labels(['B', 'A']));
    println!("mistake 1, shared counter: lane A first gives A #{}, B #{}; lane B first gives A #{}, B #{}", l1[0], l1[1], l2[0], l2[1]);
    println!("mistake 2, price before box: {} p, not {} p", price(parcels.0), by_lane.0);

    let (a, b): (M, M) = (vec![vec![1, 1], vec![0, 1]], vec![vec![2, 0], vec![0, 1]]);
    let (a2, b2): (M, M) = (vec![vec![0, 1], vec![1, 0]], vec![vec![1, 0], vec![1, 1]]);
    let (lhs, rhs) = (mul(&kron(&a2, &b2), &kron(&a, &b)), kron(&mul(&a2, &a), &mul(&b2, &b)));
    println!("vectors: (A' x B')(A x B) = (A'A) x (B'B): {}; rows {:?}", yn(lhs == rhs), rhs);
    let (u3, w3) = (vec![1, 2], vec![3, 4, 5]);        // one vector in R^2, one in R^3
    let tens: Vec<i64> = u3.iter().flat_map(|s| w3.iter().map(move |t| s * t)).collect();
    println!("mistake 3, dimensions: R^2 tensor R^3 has {}, R^2 and R^3 listed one after the other (the direct sum) has {}",
             tens.len(), [u3.clone(), w3.clone()].concat().len());
    let v = (1, 0, 0, 1);
    let mut hits = 0;
    for u0 in -3..4 { for u1 in -3..4 { for w0 in -3..4 { for w1 in -3..4 {
        if (u0 * w0, u0 * w1, u1 * w0, u1 * w1) == v { hits += 1 }
    }}}}
    println!("mistake 4, {:?} as a pair: ad - bc = {}; pairs found with entries -3 to 3: {}", v, v.0 * v.3 - v.1 * v.2, hits);
    let (pa, pb) = ([90, 10], [80, 20]);
    let joint: Vec<i64> = (0..4).map(|n| pa[n / 2] * pb[n % 2] / 100).collect();
    println!("independent lanes: ({}, {}) x ({}, {}) percent = {:?}; ad - bc = {}", pa[0], pa[1], pb[0], pb[1], joint, joint[0] * joint[3] - joint[1] * joint[2]);
    let (mut step, mut g) = (1, (1, 1));
    while g != (0, 0) { g = ((g.0 + 1) % 2, (g.1 + 1) % 3); step += 1 }
    let z6: Vec<(i64, i64)> = (0..2).flat_map(|s| (0..3).map(move |t| (s, t))).collect();
    println!("groups: Z2 x Z3 has {} members; (1, 1) has order {}", z6.len(), step);
    let cols: Vec<i64> = (0..3).map(|k| 200 + 200 * k).collect(); // figure layout: one column per stage, one row per lane
    let rows: Vec<i64> = (0..2).map(|i| 90 + 100 * i).collect();
    println!("figure, schematic: stage columns x {:?}; lane wires y {:?}; merged wire y {}", cols, rows, (rows[0] + rows[1]) / 2);
    assert!(by_stage == (435, 385) && merge(by_stage) == 820);                  // by hand
    assert!(by_lane == by_stage && slid == by_stage);
    assert!(law == 0 && slide == 0 && cross == 0 && twice == 0 && agree == members);
    assert!(l1 != l2 && lhs == rhs && hits == 0 && step == 6);
    assert!(z6.len() == step && images.len() == left3.len() && left3.len() == 8); // order against size
    println!("ALL CHECKS PASS");
}
