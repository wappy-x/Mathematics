// NC and P-completeness -- the same check as the Python, in Rust.  No crates.
// Part 1: 1,024 transactions totalled and running-totalled in parallel rounds.  Part 2:
// a machine's run as a circuit (circuit value).  Part 3: Barrington's width-5 programs.
const N: usize = 1024;
const M32: u64 = (1 << 32) - 1;
type P = Vec<usize>;
fn tree<T: Clone>(mut xs: Vec<T>, op: &dyn Fn(&T, &T) -> T) -> (T, usize, usize) {
    let (mut rounds, mut ops) = (0, 0);           // each round combines neighbouring pairs at once
    while xs.len() > 1 {
        let nxt: Vec<T> = (0..xs.len() / 2).map(|j| op(&xs[2 * j], &xs[2 * j + 1])).collect();
        (ops, rounds) = (ops + nxt.len(), rounds + 1);
        xs = [nxt, xs[xs.len() - xs.len() % 2..].to_vec()].concat();
    }
    (xs[0].clone(), rounds, ops)
}
fn scan(xs: &[i64], plan: &[(usize, Vec<usize>)]) -> (Vec<i64>, usize, usize) {
    let (mut x, mut adds) = (xs.to_vec(), 0);     // each round does x[j] += x[j - s], all at once
    for (s, starts) in plan { let old = x.clone(); for &j in starts { x[j] = old[j] + old[j - s]; adds += 1 } }
    (x, plan.iter().filter(|p| !p.1.is_empty()).count(), adds)   // rounds that do work
}
fn carry_save(xs: &[i64]) -> (i64, Vec<usize>) {  // three numbers in, two out: one fixed-depth layer
    let (mut v, mut sizes): (Vec<u64>, Vec<usize>) = (xs.iter().map(|&x| (x as u64) & M32).collect(), vec![xs.len()]);
    while v.len() > 2 {
        let fa = |j: usize| { let (a, b, c) = (v[j], v[j + 1], v[j + 2]); [a ^ b ^ c, (((a & b) | (a & c) | (b & c)) << 1) & M32] };
        v = [(0..v.len() / 3).flat_map(|j| fa(3 * j)).collect::<Vec<u64>>(), v[v.len() - v.len() % 3..].to_vec()].concat();
        sizes.push(v.len());
    }
    let t = (v[0] + v[1]) & M32;
    (if t >> 31 == 1 { t as i64 - (1i64 << 32) } else { t as i64 }, sizes)
}

// Part 2.  Cell = symbol * 5 + state; symbols 0, 1, blank; states -, E, O, A, R.
fn flip(q: usize, s: usize) -> usize { if (q == 2) != (s == 1) { 2 } else { 1 } }
fn rule(l: usize, m: usize) -> usize {           // the new cell, from the cells above-left and above
    let (ls, lq, ms, mq) = (l / 5, l % 5, m / 5, m % 5);
    if mq == 1 || mq == 2 { return m - mq + if ms == 2 { 5 - mq } else { 0 } }
    if mq >= 3 { return m }
    if (lq == 1 || lq == 2) && ls != 2 { return m + flip(lq, ls) }
    m
}
fn build_tableau(n: usize) -> (Vec<(u8, Vec<usize>)>, usize, usize) {
    let (mut gates, mut depth): (Vec<(u8, Vec<usize>)>, Vec<usize>) = (vec![], vec![]);
    let mut gate = |op: u8, ins: Vec<usize>, g: &mut Vec<(u8, Vec<usize>)>| -> usize {
        depth.push(if ins.is_empty() { 0 } else { 1 + ins.iter().map(|&i| depth[i]).max().unwrap() });
        g.push((op, ins));
        g.len() - 1
    };                                            // op 0 input, 1 AND, 2 OR
    let mut row: Vec<Vec<usize>> = (0..n + 2).map(|_| (0..15).map(|_| gate(0, vec![], &mut gates)).collect()).collect();
    for _ in 0..n + 1 {                           // one row per step, n + 1 steps
        let mut new: Vec<Vec<usize>> = vec![];
        for i in 0..n + 1 {
            let left = if i == 0 { row[n + 1].clone() } else { row[i - 1].clone() };
            let mut feeds: Vec<Vec<usize>> = vec![vec![]; 15];
            for u in 0..15 { for v in 0..15 { feeds[rule(u, v)].push(gate(1, vec![left[u], row[i][v]], &mut gates)) } }
            new.push(feeds.into_iter().map(|f| gate(2, f, &mut gates)).collect());
        }
        new.push(row[n + 1].clone()); row = new;  // the blank wall stays left of cell 0
    }
    let acc: Vec<usize> = (0..n + 1).flat_map(|i| (0..3).map(move |s| (i, s * 5 + 3))).map(|(i, k)| row[i][k]).collect();
    let out = gate(2, acc, &mut gates);
    (gates, depth[out], out)
}
fn evaluate(gates: &[(u8, Vec<usize>)], w: &[usize], out: usize) -> usize {
    let mut cells: Vec<usize> = w.iter().enumerate().map(|(i, &s)| s * 5 + (i == 0) as usize).collect();
    cells.extend([10, 10]);                       // the blank after the input, then the wall
    let mut val: Vec<bool> = cells.iter().flat_map(|&c| (0..15).map(move |v| c == v)).collect();
    for (op, ins) in &gates[val.len()..] {        // circuit value: one gate after another
        let x = if *op == 2 { ins.iter().any(|&i| val[i]) } else { ins.iter().all(|&i| val[i]) }; val.push(x) }
    val[out] as usize
}

// Part 3.  Permutations of 0..4; compose(p, q) does p first, then q.
fn compose(p: &P, q: &P) -> P { p.iter().map(|&i| q[i]).collect() }
fn inv(p: &P) -> P { let mut r = vec![0; p.len()]; for (i, &x) in p.iter().enumerate() { r[x] = i } r }
fn comm(a: &P, b: &P) -> P { compose(&compose(&compose(a, b), &inv(a)), &inv(b)) }
fn conj(t: &P, p: &P) -> P { compose(&compose(&inv(t), p), t) }
fn perms(w: usize) -> Vec<P> {
    if w == 0 { return vec![vec![]] } (0..w).flat_map(|i| perms(w - 1).into_iter().map(move |p| [vec![i], p.iter().map(|&x| x + (x >= i) as usize).collect()].concat())).collect()
}
fn cycles(p: &P) -> Vec<Vec<usize>> {
    let mut seen = vec![false; p.len()];
    (0..p.len()).map(|s| { let (mut c, mut i) = (vec![], s); while !seen[i] { seen[i] = true; c.push(i + 1); i = p[i] } c })
        .filter(|c| !c.is_empty()).collect()
}
fn ctype(p: &P) -> Vec<usize> { let mut t: Vec<usize> = cycles(p).iter().map(|c| c.len()).collect(); t.sort(); t }
fn show(p: &P) -> String {
    let s: String = cycles(p).iter().filter(|c| c.len() > 1).map(|c| format!("({})", join(c))).collect();
    if s.is_empty() { "e".to_string() } else { s }
}
enum F { X(usize), Not(Box<F>), And(Box<F>, Box<F>) }
fn or(f: F, g: F) -> F { F::Not(Box::new(F::And(Box::new(F::Not(Box::new(f))), Box::new(F::Not(Box::new(g)))))) }
fn and(f: F, g: F) -> F { F::And(Box::new(f), Box::new(g)) }
fn build(f: &F, s: &P, k: &(Vec<P>, P, P), commute: bool) -> Vec<(usize, P, P)> {
    let e: P = (0..5).collect();                  // a program computing f "via s": s when 1, e when 0
    match f {
        F::X(i) => vec![(*i, e, s.clone())],
        F::Not(g) => {                            // compute g via s^-1, then do s once more at the end
            let mut p = build(g, &inv(s), k, commute);
            let (i, p0, p1) = p.pop().unwrap();
            p.push((i, compose(&p0, s), compose(&p1, s))); p
        }
        F::And(g, h) => {
            let t = k.0.iter().find(|t| conj(t, &comm(&k.1, &k.2)) == *s).unwrap();
            let (a, b) = if commute { (s.clone(), s.clone()) } else { (conj(t, &k.1), conj(t, &k.2)) };
            [build(g, &a, k, commute), build(h, &b, k, commute), build(g, &inv(&a), k, commute), build(h, &inv(&b), k, commute)].concat()
        }
    }
}
fn run_program(prog: &[(usize, P, P)], bits: &[usize]) -> P {
    let mut r: P = (0..5).collect();
    for (i, p0, p1) in prog { r = compose(&r, if bits[*i] == 1 { p1 } else { p0 }) } r
}
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn join(v: &[usize]) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(" ") }
fn main() {
    let amounts: Vec<i64> = (0..N as i64).map(|i| (i * 7919) % 20001 - 10000).collect();
    let l = (usize::BITS - (N - 1).leading_zeros()) as usize;   // 10 levels for 1,024
    let mut bkp: Vec<(usize, Vec<usize>)> = (0..l).map(|d| (1 << d, (2 * (1 << d) - 1..N).step_by(2 << d).collect())).collect();
    bkp.extend((0..l - 1).rev().map(|d| (1 << d, (3 * (1 << d) - 1..N).step_by(2 << d).collect())));
    let ksp: Vec<(usize, Vec<usize>)> = (0..l).map(|d| (1 << d, (1 << d..N).collect())).collect();
    let (mut running, mut total) = (vec![], 0i64);
    for a in &amounts { total += a; running.push(total) }     // road one: one add at a time
    let (t_sum, t_rounds, t_adds) = tree(amounts.clone(), &|x: &i64, y: &i64| x + y);
    let ((bk, bk_rounds, bk_adds), (ks, ks_rounds, ks_adds)) = (scan(&amounts, &bkp), scan(&amounts, &ksp));
    let (cs_total, cs_sizes) = carry_save(&amounts);
    println!("statement: {} lines, from {} to {} pence; closing balance {} pence", N, amounts.iter().min().unwrap(), amounts.iter().max().unwrap(), total);
    println!("one at a time: {} adds in {} rounds; balanced tree: {} adds in {} rounds, total {}", N - 1, N - 1, t_adds, t_rounds, t_sum);
    let up: Vec<usize> = bkp[..l].iter().map(|p| p.1.len()).filter(|&a| a > 0).collect();   // up-sweep rounds that do work
    println!("running balances, Brent-Kung: {} adds in {} rounds ({} in {} up, {} in {} down); all {} match: {}", bk_adds, bk_rounds,
             up.iter().sum::<usize>(), up.len(), bk_adds - up.iter().sum::<usize>(), bk_rounds - up.len(), N, yn(bk == running));
    println!("running balances, Kogge-Stone: {} adds in {} rounds; all {} match: {}", ks_adds, ks_rounds, N, yn(ks == running));
    println!("balances after lines 1, 2, 3: {}, {}, {}; lowest {}, highest {}", running[0], running[1], running[2], running.iter().min().unwrap(), running.iter().max().unwrap());
    println!("carry-save: numbers left {}; total {}", join(&cs_sizes), cs_total);
    println!("carry-save gate depth: {} layers x 6 + 13 for the last add = {}", cs_sizes.len() - 1, (cs_sizes.len() - 1) * 6 + 13);
    println!("OR of {} bits: depth 1 with one unbounded gate; depth {} with {} two-input gates", N, l, N - 1);
    for (n, words) in [(4usize, 16usize), (5, 32), (8, 256), (16, 4)] {
        let (gates, dep, out) = build_tableau(n);
        let size = gates.iter().filter(|g| g.0 != 0).count();
        let ws: Vec<Vec<usize>> = (0..words).map(|v| (0..n).rev().map(|b| ((if n == 16 { v * 4369 + 1 } else { v }) >> b) & 1).collect()).collect();
        let right = ws.iter().filter(|w| evaluate(&gates, w, out) == w.iter().sum::<usize>() % 2).count();   // against counting
        println!("tableau n={}: {} gates, 240(n+1)^2+1 = {}; depth {}, 2(n+1)+1 = {}; right on {} of {}", n, size, 240 * (n + 1) * (n + 1) + 1, dep, 2 * n + 3, right, words);
        assert!(size == 240 * (n + 1) * (n + 1) + 1 && dep == 2 * n + 3 && right == words);
    }
    let (s5, a0): (Vec<P>, P) = (perms(5), vec![1, 2, 3, 4, 0]);   // a0 is the cycle (1 2 3 4 5)
    let b0 = s5.iter().find(|b| ctype(b) == vec![5] && ctype(&comm(&a0, b)) == vec![5]).unwrap().clone();
    let fives: Vec<&P> = s5.iter().filter(|p| ctype(p) == vec![5]).collect();
    let good = fives.iter().flat_map(|a| fives.iter().map(move |b| (*a, *b))).filter(|(a, b)| ctype(&comm(a, b)) == vec![5]).count();
    println!("S5: {} permutations, {} five-cycles; pairs whose commutator is a five-cycle: {} of {}", s5.len(), fives.len(), good, fives.len() * fives.len());
    println!("chosen pair: a = {}, b = {}; a then b then a^-1 then b^-1 = {}", show(&a0), show(&b0), show(&comm(&a0, &b0)));
    let us: Vec<usize> = [3usize, 4, 5].iter().map(|&w| { let g = perms(w);
        g.iter().flat_map(|a| g.iter().map(move |b| (a, b))).filter(|(a, b)| ctype(a) == ctype(b) && ctype(b) == ctype(&comm(a, b)) && ctype(a) != vec![1; w]).count() }).collect();
    for (w, u) in [3, 4, 5].iter().zip(&us) { println!("width {}: pairs a, b in one class other than e, commutator in that class too: {}", w, u) }
    let x = |i: usize| F::X(i);                   // a0, a1, b0, b1
    let carry_f = or(and(x(1), x(3)), and(or(x(1), x(3)), and(x(0), x(2))));
    let inputs: Vec<Vec<usize>> = (0..4).flat_map(|a| (0..4).map(move |b| vec![a & 1, a >> 1, b & 1, b >> 1])).collect();
    let carry: Vec<bool> = inputs.iter().map(|x| x[0] + 2 * x[1] + x[2] + 2 * x[3] >= 4).collect();
    let kit = (s5.clone(), a0.clone(), b0.clone());
    let (prog, bad) = (build(&carry_f, &a0, &kit, false), build(&carry_f, &a0, &kit, true));
    let ok = inputs.iter().zip(&carry).filter(|(x, &c)| run_program(&prog, x) == if c { a0.clone() } else { (0..5).collect() }).count();
    println!("carry-out program: length {}, bound 4^3 = 64; right on {} of 16, carry 1 on {}", prog.len(), ok, carry.iter().filter(|&&c| c).count());
    let (top, rounds, _) = tree(prog.iter().map(|t| t.2.clone()).collect(), &|p: &P, q: &P| compose(p, q));
    println!("its {} permutations multiplied in a balanced tree: {} rounds; same product: {}", prog.len(), rounds, yn(top == run_program(&prog, &[1, 1, 1, 1])));
    let wrong = inputs.iter().zip(&carry).filter(|(x, &c)| (run_program(&bad, x) == a0) == c).count();
    println!("what breaks, a commuting pair in the AND step: right on {} of 16", wrong);
    assert!(t_sum == total && cs_total == total && total == amounts.iter().sum::<i64>() && t_rounds == l);
    assert!(bk == running && ks == running && (bk_rounds, bk_adds, ks_adds) == (2 * l - 1, 2 * N - l - 2, l * N - N + 1));
    assert!(us[0] == 0 && us[1] == 0 && 0 < good && good <= us[2] && good == fives.len() * fives.iter().filter(|b| ctype(&comm(&a0, b)) == vec![5]).count());   // by symmetry
    assert!(top == run_program(&prog, &[1, 1, 1, 1]) && ok == 16 && rounds == 6 && wrong < 16);
    println!("ALL CHECKS PASS");
}
