// Knot polynomials in outline -- the same check as the Python, in Rust.  No
// crates.  A diagram is a planar-diagram code: one X[a, b, c, d] per crossing,
// edge labels read anticlockwise from the incoming under-strand, labels rising
// along the knot.  Polynomials are BTreeMaps {exponent: integer coefficient}.
// Road 1: the bracket state sum over all 2^n smoothings, then the writhe.
// Road 2: the Jones skein relation, by hand: unlink -> Hopf link -> trefoil.
use std::collections::{BTreeMap, BTreeSet, HashMap};

type Poly = BTreeMap<i64, i64>;
type Pd = Vec<[i64; 4]>;

fn poly(terms: &[(i64, i64)]) -> Poly { terms.iter().cloned().collect() }

fn clean(p: Poly) -> Poly { p.into_iter().filter(|&(_, c)| c != 0).collect() }

fn mul(p: &Poly, q: &Poly) -> Poly {
    let mut out = Poly::new();
    for (e, c) in p { for (f, k) in q { *out.entry(e + f).or_insert(0) += c * k; } }
    clean(out)
}

fn add(p: &Poly, q: &Poly) -> Poly {
    let mut out = p.clone();
    for (e, c) in q { *out.entry(*e).or_insert(0) += c; }
    clean(out)
}

fn scale(p: &Poly, k: i64, shift: i64) -> Poly { p.iter().map(|(e, c)| (e + shift, k * c)).collect() }

fn positive(x: &[i64; 4]) -> bool {               // sign of a crossing
    let [a, b, c, d] = *x;
    a == b || c == d || b - d == 1 || d - b > 1
}

fn writhe(pd: &Pd) -> i64 { pd.iter().map(|x| if positive(x) { 1 } else { -1 }).sum() }

fn mirror(pd: &Pd) -> Pd {                         // swap over and under everywhere
    pd.iter().map(|&[a, b, c, d]| if positive(&[a, b, c, d]) { [d, a, b, c] } else { [b, c, d, a] }).collect()
}

fn find(parent: &mut HashMap<i64, i64>, mut x: i64) -> i64 {
    parent.entry(x).or_insert(x);
    while parent[&x] != x { x = parent[&x]; }
    x
}

fn loops(pairs: &[(i64, i64)]) -> i64 {           // count closed loops: union-find
    let mut parent: HashMap<i64, i64> = HashMap::new();
    for &(u, v) in pairs { let (ru, rv) = (find(&mut parent, u), find(&mut parent, v)); parent.insert(ru, rv); }
    let keys: Vec<i64> = parent.keys().cloned().collect();
    keys.iter().map(|&x| find(&mut parent, x)).collect::<BTreeSet<i64>>().len() as i64
}

fn states(pd: &Pd, loop_power: i64) -> Vec<(String, i64, i64, Poly)> {   // name, A-power, loops, term
    let d = poly(&[(2, -1), (-2, -1)]);           // d = -A^2 - A^-2, one loop's worth
    let mut out = Vec::new();
    for mask in 0..(1usize << pd.len()) {
        let (mut pairs, mut name) = (Vec::new(), String::new());
        for (i, &[a, b, c, d]) in pd.iter().enumerate() {
            if (mask >> (pd.len() - 1 - i)) & 1 == 0 { pairs.extend([(a, b), (c, d)]); name.push('A') }
            else { pairs.extend([(a, d), (b, c)]); name.push('B') }
        }
        let power = 2 * name.matches('A').count() as i64 - pd.len() as i64;
        let n = loops(&pairs);
        let mut term = poly(&[(power, 1)]);
        for _ in 0..(n + loop_power) { term = mul(&term, &d); }
        out.push((name, power, n, term));
    }
    out
}

fn bracket(pd: &Pd, loop_power: i64) -> Poly {
    states(pd, loop_power).iter().fold(Poly::new(), |acc, s| add(&acc, &s.3))
}

fn jones(br: &Poly, w: i64) -> Poly {             // (-A^3)^-w <D>, then A = t^(-1/4); t in half-steps
    let f = scale(br, if w % 2 == 0 { 1 } else { -1 }, -3 * w);
    assert!(f.keys().all(|e| e % 2 == 0));
    f.iter().map(|(e, c)| (-e / 2, *c)).collect()
}

fn show(p: &Poly, v: &str, den: i64) -> String {  // print a polynomial, lowest power first
    let mut out = String::new();
    for (&e, &c) in p {
        let g = if e % den == 0 { den } else { 1 };
        let (n, m) = (e / g, den / g);
        let pw = if e == 0 { String::new() } else if (n, m) == (1, 1) { v.to_string() }
                 else if m == 1 { format!("{}^{}", v, n) } else { format!("{}^({}/{})", v, n, m) };
        let mag = if c.abs() == 1 && !pw.is_empty() { String::new() } else { c.abs().to_string() };
        let sign = if out.is_empty() { if c < 0 { "-" } else { "" } } else if c < 0 { " - " } else { " + " };
        out += &format!("{}{}{}", sign, mag, pw);
    }
    if out.is_empty() { "0".to_string() } else { out }
}

fn tricolourings(pd: &Pd) -> i64 {
    let arcs: HashMap<i64, i64> = pd.iter().map(|&[_, b, _, d]| (d, b)).collect();
    let arc = |mut x: i64| { while arcs.contains_key(&x) && arcs[&x] != x { x = arcs[&x]; } x };
    let names: Vec<i64> = pd.iter().flatten().map(|&x| arc(x)).collect::<BTreeSet<i64>>().into_iter().collect();
    let mut count = 0;
    for code in 0..3i64.pow(names.len() as u32) {
        let col: HashMap<i64, i64> = names.iter().enumerate()
            .map(|(i, &n)| (n, code / 3i64.pow((names.len() - 1 - i) as u32) % 3)).collect();
        if pd.iter().all(|&[a, b, c, _]| (col[&arc(a)] + col[&arc(c)] + col[&arc(b)]) % 3 == 0) { count += 1; }
    }
    count
}

fn main() {
    let left: Pd = vec![[1, 4, 2, 5], [3, 6, 4, 1], [5, 2, 6, 3]];   // the trefoil of the tables
    let kink: Pd = vec![[1, 1, 2, 2]];                                  // an unknot with one twist
    let right = mirror(&left);
    println!("state, A-power, loops, term of the right trefoil:");
    for (name, power, n, term) in states(&right, -1) {
        println!("  {}  A^{}  loops {}  term {}", name, power, n, show(&term, "A", 1));
    }
    let (br, bl) = (bracket(&right, -1), bracket(&left, -1));
    let (vr, vl) = (jones(&br, writhe(&right)), jones(&bl, writhe(&left)));
    let span = br.keys().max().unwrap() - br.keys().min().unwrap();
    println!("right trefoil: writhe {}, bracket {}", writhe(&right), show(&br, "A", 1));
    let w = writhe(&right);
    let fr = scale(&poly(&[(0, 1)]), if w % 2 == 0 { 1 } else { -1 }, -3 * w);
    println!("  writhe factor (-A^3)^-{} = {}; corrected {}", w, show(&fr, "A", 1), show(&mul(&fr, &br), "A", 1));
    println!("  span of the bracket {} = 4 x {} crossings", span, right.len());
    println!("  Jones V(t) = {}", show(&vr, "t", 2));
    println!("left trefoil (mirror): writhe {}, bracket {}", writhe(&left), show(&bl, "A", 1));
    println!("  Jones V(t) = {}", show(&vl, "t", 2));
    // Road 2: t^-1 V(L+) - t V(L-) = (t^(1/2) - t^(-1/2)) V(L0), solved for V(L+).
    let (one, root) = (poly(&[(0, 1)]), poly(&[(1, 1), (-1, -1)]));
    let skein = |vm: &Poly, v0: &Poly| scale(&add(&scale(vm, 1, 2), &mul(&root, v0)), 1, 2);
    let unlink = poly(&[(1, -1), (-1, -1)]);       // two separate loops: d, at A = t^(-1/4)
    let hopf = skein(&unlink, &one);
    let tref = skein(&one, &hopf);
    println!("skein road: unlink {}; Hopf link {}", show(&unlink, "t", 2), show(&hopf, "t", 2));
    println!("skein road: (t^(1/2) - t^(-1/2)) x Hopf = {}", show(&mul(&root, &hopf), "t", 2));
    println!("skein road: right trefoil {}", show(&tref, "t", 2));
    let flip: Poly = vr.iter().map(|(e, c)| (-e, *c)).collect();
    println!("right trefoil's V at t -> 1/t: {}; mirror differs: {}", show(&flip, "t", 2), if vr != vl { "yes" } else { "no" });
    let bk = bracket(&kink, -1);
    println!("kinked unknot: writhe {}, bracket {}, Jones {}", writhe(&kink), show(&bk, "A", 1), show(&jones(&bk, 1), "t", 2));
    println!("tricolourings: right {}, left {}, unknot {}", tricolourings(&right), tricolourings(&left), tricolourings(&kink));
    println!("mistake 1, bracket with no writhe factor: kinked unknot {}, not 1", show(&bk, "A", 1));
    println!("mistake 2, d^loops not d^(loops-1): kinked unknot {}; trefoil {}",
             show(&bracket(&kink, 0), "A", 1), show(&jones(&bracket(&right, 0), 3), "t", 2));
    let swapped: Pd = right.iter().map(|&[a, b, c, d]| [b, c, d, a]).collect();   // A and B smoothings swapped
    println!("mistake 3, A and B swapped, writhe kept: {}", show(&jones(&bracket(&swapped, -1), 3), "t", 2));
    assert!(tref == vr);                                        // road 1 = road 2
    assert!(vl == flip && vr != vl);                            // the mirror is V(1/t), and differs
    assert!(jones(&bk, writhe(&kink)) == one && bk == poly(&[(3, -1)]));
    assert!(br == poly(&[(-7, 1), (-3, -1), (5, -1)]) && span == 4 * right.len() as i64);
    assert!(tricolourings(&right) == 9 && tricolourings(&left) == 9);
    println!("ALL CHECKS PASS");
}
