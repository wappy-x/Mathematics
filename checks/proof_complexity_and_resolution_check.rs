// Proof complexity and resolution -- the same check as the Python, in Rust, no crates.
// The rota PHP(n + 1, n): n + 1 staff, n shifts, everyone needs a shift, no two share one.
// Roads: brute force; a hand resolution proof, checked; DPLL read as resolution; cutting planes.
use std::collections::BTreeMap;
type Clause = Vec<i32>;                    // sorted literals; -v means "not v"
type Ineq = (BTreeMap<i32, i64>, i64);     // sum(coefficient * variable) >= right side

fn norm(mut c: Clause) -> Clause { c.sort(); c.dedup(); c }
fn php(n: i32) -> Vec<Clause> {            // variable i*n + j + 1 means "staff i works shift j"
    let v = |i: i32, j: i32| i * n + j + 1;
    let mut cl: Vec<Clause> = (0..=n).map(|i| norm((0..n).map(|j| v(i, j)).collect())).collect();
    for j in 0..n { for i in 0..=n { for k in i + 1..=n { cl.push(norm(vec![-v(i, j), -v(k, j)])) } } }
    cl
}

fn holds(c: &Clause, a: u64) -> bool { c.iter().any(|&l| ((a >> (l.abs() - 1) & 1) == 1) == (l > 0)) }

fn models(cls: &[Clause], nv: u32) -> usize {      // road 1: try every assignment
    (0..1u64 << nv).filter(|&a| cls.iter().all(|c| holds(c, a))).count()
}

fn name(l: i32) -> String {                // PHP(3, 2) only: staff a(nn), b(ob), k(im)
    format!("{}{}{}", if l < 0 { "-" } else { "" }, ["a", "b", "k"][((l.abs() - 1) / 2) as usize], (l.abs() - 1) % 2 + 1)
}

fn show(c: &Clause) -> String {
    let mut c = c.clone(); c.sort_by_key(|&l| (l.abs(), l < 0));
    if c.is_empty() { "empty".to_string() } else { c.iter().map(|&l| name(l)).collect::<Vec<_>>().join(" v ") }
}

fn lit(s: &str) -> i32 {
    if let Some(r) = s.strip_prefix('-') { -lit(r) } else { "abk".find(&s[..1]).unwrap() as i32 * 2 + s[1..].parse::<i32>().unwrap() }
}

fn resolve(ci: &Clause, cj: &Clause, x: i32) -> Clause {
    norm(ci.iter().chain(cj.iter()).copied().filter(|&l| l != x && l != -x).collect())
}

fn check(axioms: &[Clause], steps: &[(Clause, Clause, i32, Clause)]) -> bool {  // the proof checker
    let mut known: Vec<Clause> = axioms.to_vec();
    for (ci, cj, x, r) in steps {
        assert!(known.contains(ci) && known.contains(cj) && ci.contains(x) && cj.contains(&-x));
        assert!(*r == resolve(ci, cj, *x) && !r.iter().any(|l| r.contains(&-l)));
        known.push(r.clone());
    }
    steps.last().unwrap().3.is_empty()
}

fn go(cls: &[Clause], asg: &mut Vec<i8>, steps: &mut Vec<(Clause, Clause, i32, Clause)>) -> Clause {
    for c in cls {                         // a clause this partial assignment makes false: a leaf
        if c.iter().all(|&l| (l.abs() as usize) < asg.len() && asg[l.abs() as usize] == if l < 0 { 1 } else { -1 }) { return c.clone() }
    }
    let x = asg.len() as i32;
    asg.push(1); let c1 = go(cls, asg, steps);
    asg.pop(); asg.push(-1); let c0 = go(cls, asg, steps); asg.pop();
    if !c1.contains(&-x) { return c1 }
    if !c0.contains(&x) { return c0 }
    let r = resolve(&c1, &c0, x); steps.push((c0, c1, x, r.clone())); r
}

fn dpll(cls: &[Clause]) -> Vec<(Clause, Clause, i32, Clause)> {  // road 3: DPLL read as resolution
    let (mut asg, mut steps) = (vec![0i8], Vec::new());           // slot 0 unused: variables are 1, 2, ...
    go(cls, &mut asg, &mut steps); steps
}

fn comb(terms: &[(i64, Ineq)]) -> Ineq {   // a sum of earlier lines times whole numbers 0 or more
    let (mut co, mut rhs) = (BTreeMap::new(), 0i64);
    for (m, (c, b)) in terms {
        for (k, a) in c { *co.entry(*k).or_insert(0) += m * a } rhs += m * b;
    }
    co.retain(|_, a| *a != 0); (co, rhs)
}

fn div(line: Ineq, d: i64) -> Ineq {       // divide by d, rounding the right side up
    assert!(line.0.values().all(|a| a % d == 0));
    (line.0.iter().map(|(k, a)| (*k, a / d)).collect(), -((-line.1).div_euclid(d)))
}

fn cutting_planes(n: i32) -> (usize, Ineq, Vec<Ineq>) {        // road 4
    let v = |i: i32, j: i32| i * n + j + 1;
    let pair = |i: i32, k: i32, j: i32| -> Ineq { (BTreeMap::from([(v(i, j), -1), (v(k, j), -1)]), -1) };
    let (mut count, mut holes) = (1, Vec::new());
    for j in 0..n {
        let mut s = pair(0, 1, j);         // "at most one of staff 0 and 1 on shift j"
        for k in 2..=n {
            let mut t = vec![((k - 1) as i64, s)];
            for i in 0..k { t.push((1, pair(i, k, j))) }
            s = div(comb(&t), k as i64); count += 2;
        }
        holes.push(s);
    }
    let mut t: Vec<(i64, Ineq)> = (0..=n).map(|i| (1, ((0..n).map(|j| (v(i, j), 1)).collect(), 1))).collect();
    for h in &holes { t.push((1, h.clone())) }
    (count, comb(&t), holes)
}

fn place(n: i32, rest: Vec<i32>, j: i32, a: u64, out: &mut Vec<u64>) {
    if j == n { out.push(a); return }
    for &i in &rest { place(n, rest.iter().copied().filter(|&r| r != i).collect(), j + 1, a | 1 << (i * n + j), out) }
}

fn critical(n: i32) -> Vec<u64> {          // Haken: n staff matched one-to-one to n shifts, one left out
    let mut out = Vec::new();
    for left in 0..=n { place(n, (0..=n).filter(|&i| i != left).collect(), 0, 0, &mut out) } out
}

fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn main() {
    let f = php(2);
    println!("PHP(3, 2): 3 staff, 2 shifts, 6 variables, {} clauses", f.len());
    for t in (0..9).step_by(3) {
        let row: Vec<String> = (0..3).map(|s| format!("({}) {}", t + s + 1, show(&f[t + s]))).collect();
        println!("  {}", row.join("   "));
    }
    println!("road 1, brute force: {} assignments, {} make every clause true", 1 << 6, models(&f, 6));
    let hand = [(2, 4, "b1", "-a1 v b2"), (3, 5, "k1", "-a1 v k2"), (10, 9, "b2", "-a1 v -k2"),
        (11, 12, "k2", "-a1"), (2, 7, "b2", "-a2 v b1"), (3, 8, "k2", "-a2 v k1"),
        (14, 6, "b1", "-a2 v -k1"), (15, 16, "k1", "-a2"), (1, 13, "a1", "a2"), (18, 17, "a2", "empty")];
    let (mut l, mut steps) = (f.clone(), Vec::new());
    for &(i, j, p, claim) in &hand {
        l.push(if claim == "empty" { vec![] } else { norm(claim.split(" v ").map(lit).collect()) });
        steps.push((l[i - 1].clone(), l[j - 1].clone(), lit(p), l[l.len() - 1].clone()));
        println!("  ({}) {:<9} from ({}) and ({}), on {}", l.len(), claim, i, j, p);
    }
    let (ok, crit) = (check(&f, &steps), critical(2));
    let sound = steps.iter().all(|(ci, cj, _, r)| (0..64).all(|a| holds(r, a) || !(holds(ci, a) && holds(cj, a))));
    println!("road 2, hand proof: {} resolution steps, checker accepts and ends empty: {}", steps.len(), yn(ok));
    println!("  each step true wherever both its parents are true, all 64 assignments: {}", yn(sound));
    let lone: Vec<u64> = (0..64).filter(|&a| {
        let bad: Vec<usize> = (0..9).filter(|&k| !holds(&f[k], a)).collect(); bad.len() == 1 && bad[0] < 3 }).collect();
    println!("critical assignments: {} by matching, {} by brute force, 3! = 6", crit.len(), lone.len());
    let mono = |c: &Clause| -> Clause {    // -x_ij becomes "someone else on shift j"
        norm(c.iter().flat_map(|&l| if l > 0 { vec![l] } else {
            (0..3).filter(|&k| k != (l.abs() - 1) / 2).map(|k| k * 2 + (l.abs() - 1) % 2 + 1).collect() }).collect())
    };
    let agree = steps.iter().all(|(_, _, _, r)| crit.iter().all(|&a| holds(r, a) == holds(&mono(r), a)));
    println!("  (13) -a1 on critical assignments reads {}; all 10 lines agree: {}", show(&mono(&l[12])), yn(agree));
    println!("n  staff  vars  clauses  models  resolution-by-DPLL  cutting-plane-lines");
    let mut pts = Vec::new();
    for n in 1..=6 {
        let cls = php(n);
        let st = dpll(&cls);
        let (cp, last, holes) = cutting_planes(n);
        let m = if n <= 3 { models(&cls, (n * (n + 1)) as u32).to_string() } else { "-".to_string() };
        assert!(check(&cls, &st) && last == (BTreeMap::new(), 1));
        for (j, h) in holes.iter().enumerate() { assert!(*h == ((0..=n).map(|i| (j as i32 + i * n + 1, -1)).collect(), -1)) }
        assert!(critical(n).len() == (1..=(n + 1) as usize).product::<usize>());
        pts.push(((st.len() as f64).log10(), (cp as f64).log10()));
        println!("{}  {:>5}  {:>4}  {:>7}  {:>6}  {:>18}  {:>19}", n, n + 1, n * (n + 1), cls.len(), m, st.len(), cp);
    }
    let fmt = |k: usize| pts.iter().map(|p| format!("{:.2}", if k == 0 { p.0 } else { p.1 })).collect::<Vec<_>>().join(", ");
    println!("chart, log10 resolution-by-DPLL: {}", fmt(0));
    println!("chart, log10 cutting-plane lines: {}", fmt(1));
    let two = vec![vec![1, 2], vec![-2, -1]];                 // Ann early or late, and not both
    let bad: Clause = norm(two.concat().into_iter().filter(|l| ![1, -1, 2, -2].contains(l)).collect());
    println!("mistake 1, two pivots at once on a1 v a2 and -a1 v -a2: {}, yet {} of 4 assignments work",
             show(&bad), models(&two, 2));
    let fits: Vec<u64> = (0..64).filter(|&a| f[..8].iter().all(|c| holds(c, a))).collect();
    let on: Vec<String> = (1..7).filter(|v| fits[0] >> (v - 1) & 1 == 1).map(name).collect();
    println!("mistake 2, clause (9) dropped: {} rota fits, {} true", fits.len(), on.join(", "));
    println!("mistake 3, DPLL's proof read as the shortest: {} steps, the hand proof has {}", dpll(&f).len(), hand.len());
    assert!(models(&f, 6) == 0 && ok && sound && agree);              // unsatisfiable, and the proof holds
    let (mut c1, mut c2) = (crit.clone(), lone.clone()); c1.sort(); c2.sort();
    assert!(crit.len() == 6 && lone.len() == 6 && c1 == c2);           // two roads to Haken's assignments
    assert!(bad.is_empty() && models(&two, 2) == 2 && fits.len() == 1);
    println!("ALL CHECKS PASS");
}
