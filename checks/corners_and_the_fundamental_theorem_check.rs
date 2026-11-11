// Corners are enough: the same check as the Python, in Rust. No crates.
// The workshop: t tables, c chairs; maximise profit 19 t + 20 c (pounds) with
// timber 4t + 2c <= 160 m, labour 3t + c <= 120 h, finish t + 2c <= 64 litres.
// Exact fractions throughout. Roads: (1) every choice of 3 basic columns,
// solved by elimination; (2) prices that cap the profit; (3) every plan on a
// grid of tenths; (4) the proof's reduction, run from a plan inside.
use std::cmp::Ordering;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
struct Q { n: i64, d: i64 } // a fraction n/d, d > 0, in lowest terms
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i64, d: i64) -> Q { let g = gcd(n, d).max(1) * d.signum(); Q { n: n / g, d: d / g } }
fn z(n: i64) -> Q { q(n, 1) }
impl std::ops::Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.n * o.d + o.n * self.d, self.d * o.d) } }
impl std::ops::Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { q(self.n * o.d - o.n * self.d, self.d * o.d) } }
impl std::ops::Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.n * o.n, self.d * o.d) } }
impl std::ops::Div for Q { type Output = Q; fn div(self, o: Q) -> Q { q(self.n * o.d, self.d * o.n) } }
impl PartialOrd for Q { fn partial_cmp(&self, o: &Q) -> Option<Ordering> { Some(self.cmp(o)) } }
impl Ord for Q { fn cmp(&self, o: &Q) -> Ordering { (self.n * o.d).cmp(&(o.n * self.d)) } }

const A: [[i64; 5]; 3] = [[4, 2, 1, 0, 0], [3, 1, 0, 1, 0], [1, 2, 0, 0, 1]]; // slack columns added
const B: [i64; 3] = [160, 120, 64];
const C: [i64; 5] = [19, 20, 0, 0, 0];
const COL: [&str; 5] = ["t", "c", "s_timber", "s_labour", "s_finish"];
const LIM: [&str; 5] = ["t >= 0", "c >= 0", "timber", "labour", "finish"]; // zero entry = tight limit

fn show(x: Q) -> String { // exact fraction -> decimal text, at most 3 places
    let n = (x.n.abs() * 1000 * 2 + x.d) / (2 * x.d);
    let s = format!("{}.{:03}", n / 1000, n % 1000);
    let s = s.trim_end_matches('0').trim_end_matches('.');
    format!("{}{}", if x.n < 0 { "-" } else { "" }, s)
}
fn pt(x: (Q, Q)) -> String { format!("({}, {})", show(x.0), show(x.1)) }
fn vec(x: &[Q]) -> String { format!("({})", x.iter().map(|&v| show(v)).collect::<Vec<_>>().join(", ")) }
fn profit(x: &[Q]) -> Q { x.iter().zip(C.iter()).fold(z(0), |s, (&v, &ci)| s + z(ci) * v) }
fn bent(p: (Q, Q)) -> Q { z(19) * p.0 + z(20) * p.1 - p.1 * p.1 / z(2) } // chair profit falls 50p a chair

fn rref(cols: &[usize]) -> (Vec<Vec<Q>>, Vec<usize>) { // row-reduce chosen columns; rows and pivot columns
    let mut m: Vec<Vec<Q>> = (0..3).map(|r| cols.iter().map(|&j| z(A[r][j])).collect()).collect();
    let (mut piv, mut r) = (Vec::new(), 0);
    for k in 0..cols.len() {
        let p = match (r..3).find(|&i| m[i][k] != z(0)) { Some(p) => p, None => continue };
        m.swap(r, p);
        let h = m[r][k]; m[r] = m[r].iter().map(|&v| v / h).collect();
        for i in 0..3 {
            let f = m[i][k];
            if i != r && f != z(0) { m[i] = (0..cols.len()).map(|j| m[i][j] - f * m[r][j]).collect(); }
        }
        piv.push(k); r += 1;
    }
    (m, piv)
}
fn basic(cols: &[usize], b: &[i64]) -> Option<Vec<Q>> { // solve B x_B = b by elimination, other entries zero
    let mut m: Vec<Vec<Q>> = (0..3).map(|r| { let mut v: Vec<Q> = cols.iter().map(|&j| z(A[r][j])).collect(); v.push(z(b[r])); v }).collect();
    for k in 0..3 {
        let p = (k..3).find(|&i| m[i][k] != z(0))?;
        m.swap(k, p);
        let h = m[k][k]; m[k] = m[k].iter().map(|&v| v / h).collect();
        for i in 0..3 { let f = m[i][k]; if i != k { m[i] = (0..4).map(|j| m[i][j] - f * m[k][j]).collect(); } }
    }
    let mut x = vec![z(0); 5];
    for (k, &j) in cols.iter().enumerate() { x[j] = m[k][3]; }
    Some(x)
}

// road 4: the proof's reduction. While the columns of the positive entries are
// dependent, move along a direction d with A d = 0 that does not lower profit.
fn reduce(t0: i64, c0: i64, say: bool) -> (Vec<Q>, usize) {
    let (mut x, mut step) = (vec![z(t0), z(c0)], 0);
    for r in 0..3 { x.push(z(B[r] - A[r][0] * t0 - A[r][1] * c0)); }
    if say { println!("reduce, start {}, {} positive entries, profit {}", vec(&x), x.iter().filter(|&&v| v > z(0)).count(), show(profit(&x))); }
    loop {
        let s: Vec<usize> = (0..5).filter(|&j| x[j] > z(0)).collect();
        let (m, piv) = rref(&s);
        if piv.len() == s.len() { break; }
        let f = (0..s.len()).find(|k| !piv.contains(k)).unwrap();
        let mut d = vec![z(0); 5]; d[s[f]] = z(1);
        for (r, &k) in piv.iter().enumerate() { d[s[k]] = z(0) - m[r][f]; }
        if profit(&d) < z(0) || (profit(&d) == z(0) && d.iter().all(|&v| v >= z(0))) { d = d.iter().map(|&v| z(0) - v).collect(); }
        assert!((0..3).all(|r| (0..5).fold(z(0), |a, j| a + z(A[r][j]) * d[j]) == z(0)));
        let theta = (0..5).filter(|&j| d[j] < z(0)).map(|j| x[j] / (z(0) - d[j])).min().unwrap();
        let old = profit(&x);
        x = (0..5).map(|j| x[j] + theta * d[j]).collect(); step += 1;
        assert!(profit(&x) >= old && x.iter().all(|&v| v >= z(0)));
        if say { println!("reduce step {}: d = {}, move {}, profit rate {}, x = {}, profit {}", step, vec(&d), show(theta), show(profit(&d)), vec(&x), show(profit(&x))); }
    }
    (x, step)
}

fn main() {
    println!("model, max 19 t + 20 c | timber 4 t + 2 c <= 160 m | labour 3 t + c <= 120 h | finish t + 2 c <= 64 litres");
    println!("standard form, m = 3 rows, n = 5 columns (t, c and 3 slacks), at most {} bases", 5 * 4 * 3 / 6);
    let (mut corners, mut nfeas, mut bad, mut ntry): (Vec<((Q, Q), usize)>, usize, Vec<Vec<Q>>, usize) = (vec![], 0, vec![], 0);
    for i in 0..5 { for j in i + 1..5 { for k in j + 1..5 {
        let cols = [i, j, k];
        let x = basic(&cols, &B).expect("singular basis"); ntry += 1;
        let ok = x.iter().all(|&v| v >= z(0));
        let names = cols.iter().map(|&j| COL[j]).collect::<Vec<_>>().join(" ");
        if ok {
            nfeas += 1;
            match corners.iter_mut().find(|e| e.0 == (x[0], x[1])) { Some(e) => e.1 += 1, None => corners.push(((x[0], x[1]), 1)) }
        } else { bad.push(x.clone()); }
        let neg = if ok { String::new() } else {
            format!(", negative {}", (0..5).filter(|&j| x[j] < z(0)).map(|j| COL[j]).collect::<Vec<_>>().join(" ")) };
        println!("basis {}: x = {}, {}{}, profit {}", names, vec(&x), if ok { "feasible" } else { "infeasible" }, neg, show(profit(&x)));
    } } }
    println!("bases, {} tried, {} feasible, {} distinct corners", ntry, nfeas, corners.len());
    corners.sort();
    for &(p, nb) in &corners {
        let mut x = vec![p.0, p.1];
        for r in 0..3 { x.push(z(B[r]) - z(A[r][0]) * p.0 - z(A[r][1]) * p.1); }
        let tight: Vec<usize> = (0..5).filter(|&j| x[j] == z(0)).collect();
        let pos: Vec<usize> = (0..5).filter(|&j| x[j] != z(0)).collect();
        assert!(rref(&pos).1.len() == 5 - tight.len()); // positive entries have independent columns
        println!("corner {}: bases giving it {}, tight {}, profit {}", pt(p), nb,
                 tight.iter().map(|&j| LIM[j]).collect::<Vec<_>>().join(", "), show(profit(&x)));
    }
    let best = corners.iter().map(|e| e.0).max_by_key(|p| z(19) * p.0 + z(20) * p.1).unwrap();
    let zstar = z(19) * best.0 + z(20) * best.1;
    println!("best corner, {}, profit {}", pt(best), show(zstar));
    let th = (B[0] - B[2]) / (A[0][0] - A[2][0]); let ch = (B[2] - th) / 2; // by hand: timber minus finish
    println!("hand, timber minus finish: 3 t = {}, t = {}; finish: 2 c = {}, c = {}; labour slack {}; profit {} + {} = {}",
             B[0] - B[2], th, B[2] - th, ch, B[1] - 3 * th - ch, 19 * th, 20 * ch, 19 * th + 20 * ch);
    assert!((z(th), z(ch)) == best);
    let y = [3i64, 0, 7]; // road 2: prices per metre, hour and litre
    let cover: Vec<i64> = (0..2).map(|j| (0..3).map(|r| y[r] * A[r][j]).sum()).collect();
    let bound: i64 = (0..3).map(|r| y[r] * B[r]).sum();
    println!("certificate, prices timber {} labour {} finish {}; inputs priced: table {} vs profit {}, chair {} vs profit {}; cap {} + {} + {} = {}, gap {}",
             y[0], y[1], y[2], cover[0], C[0], cover[1], C[1], y[0] * B[0], y[1] * B[1], y[2] * B[2], bound, show(z(bound) - zstar));
    let (mut gbest, mut garg, mut nfit, mut gb, mut ga) = (-1i64, (0i64, 0i64), 0, -1i64, Vec::<(i64, i64)>::new());
    for t in 0..=400i64 { for c in 0..=320i64 { // road 3: plans in tenths, whole numbers so nothing rounds
        if 4 * t + 2 * c <= 1600 && 3 * t + c <= 1200 && t + 2 * c <= 640 {
            nfit += 1;
            if 19 * t + 20 * c > gbest { gbest = 19 * t + 20 * c; garg = (t, c); }
            let v = 380 * t + 400 * c - c * c; // falling chair profit, x 200
            if v > gb { gb = v; ga = vec![(t, c)]; } else if v == gb { ga.push((t, c)); }
        }
    } }
    println!("grid, {} plans in tenths fit, best {} at {}", nfit, show(q(gbest, 10)), pt((q(garg.0, 10), q(garg.1, 10))));
    let (x, step) = reduce(10, 10, true);
    let landed = corners.iter().any(|e| e.0 == (x[0], x[1]));
    println!("reduce, ends at {} after {} moves: in the corner list, {}", pt((x[0], x[1])), step, if landed { "yes" } else { "no" });
    let inf = bad.iter().max_by_key(|v| profit(v)).unwrap();
    println!("breaks, feasibility skipped: best basic solution {}, profit {}, timber {} m > 160",
             pt((inf[0], inf[1])), show(profit(inf)), show(z(4) * inf[0] + z(2) * inf[1]));
    println!("breaks, feasible bases counted as corners: {}, but {} corners", nfeas, corners.len());
    let tie: Vec<String> = corners.iter().map(|e| show(z(10) * e.0 .0 + z(20) * e.0 .1)).collect(); // parallel to the finish edge
    println!("breaks, profit 10 t + 20 c: corners {}; midpoint (16, 24) also {}", tie.join(" "), 10 * 16 + 20 * 24);
    let bc = corners.iter().map(|e| e.0).max_by_key(|&p| bent(p)).unwrap();
    let ce = q(21, 2); let te = z(40) - ce / z(2); // on the timber edge t = 40 - c/2 the slope 10.5 - c is zero
    println!("breaks, chair profit falling 50p a chair: best corner {} {}; edge point {} {}; grid best {} at {}",
             pt(bc), show(bent(bc)), pt((te, ce)), show(bent((te, ce))), show(q(gb, 200)), ga.iter().map(|&(t, c)| pt((q(t, 10), q(c, 10)))).collect::<Vec<_>>().join(" and "));
    let ends: Vec<(Q, Q)> = [12i64, 44].iter().map(|&t0| (z(t0), (zstar - z(19 * t0)) / z(20))).collect(); // the profit-928 line, drawn dashed
    println!("figure, corners {}; infeasible crossings {} {}; profit line {} from {} to {}",
             corners.iter().map(|e| pt(e.0)).collect::<Vec<_>>().join(" "), pt((bad[0][0], bad[0][1])), pt((bad[1][0], bad[1][1])),
             show(zstar), pt(ends[0]), pt(ends[1]));
    let mut f64v: Vec<Vec<Q>> = vec![]; // Try changing
    for i in 0..5 { for j in i + 1..5 { for k in j + 1..5 { let v = basic(&[i, j, k], &[160, 64, 64]).unwrap(); if v.iter().all(|&w| w >= z(0)) { f64v.push(v) } } } }
    let (b64, mut c64) = (f64v.iter().max_by_key(|v| profit(v)).unwrap(), f64v.iter().map(|v| (v[0], v[1])).collect::<Vec<_>>()); c64.sort(); c64.dedup();
    println!("try, labour 64 h: {} bases fit, {} corners, best {}, profit {}", f64v.len(), c64.len(), pt((b64[0], b64[1])), show(profit(b64)));
    let (x5, s5) = reduce(5, 25, false);
    println!("try, start (5, 25): {} moves to {}, profit {}", s5, pt((x5[0], x5[1])), show(profit(&x5)));
    let y6 = [3i64, 0, 6]; let c6: Vec<i64> = (0..2).map(|j| (0..3).map(|r| y6[r] * A[r][j]).sum()).collect();
    println!("try, finish price 6: inputs priced table {} vs profit 19, chair {} vs profit 20; cap {}", c6[0], c6[1], (0..3).map(|r| y6[r] * B[r]).sum::<i64>());
    assert!(corners.iter().map(|e| e.0).collect::<Vec<_>>() == vec![(z(0), z(0)), (z(0), z(32)), (z(32), z(16)), (z(40), z(0))] && corners[3].1 == 3);
    assert!(zstar == z(bound) && z(bound) == q(gbest, 10) && zstar == z(928) && best == (z(32), z(16)) && garg == (320, 160));
    assert!(cover[0] >= 19 && cover[1] >= 20 && y.iter().all(|&v| v >= 0) && landed);
    assert!(bent((te, ce)) > bent(bc) && bent((te, ce)) >= q(gb, 200) && q(gb, 200) > bent(bc));
    println!("ALL CHECKS PASS");
}
