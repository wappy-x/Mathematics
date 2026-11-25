// Decidable theories -- the check behind the card.  std only, no crates.
// Part 1: a decision procedure for Presburger arithmetic (0, 1, +, <, on the
//         numbers 0, 1, 2, ...) by quantifier elimination with congruences,
//         checked against brute-force search on every x up to 59.
// Part 2: definable sets are eventually periodic; the squares are not.
// Part 3: over the reals, "some x has x^2 + bx + c = 0" against a grid search.
use std::collections::HashSet;
#[derive(Clone, Copy, PartialEq)] enum K { Ge, Dvd, Ndvd }
#[derive(Clone, PartialEq)] enum Fm { T, F, At(K, i64, [i64; 3], i64), And(Vec<Fm>), Or(Vec<Fm>), Not(Box<Fm>), Ex(usize, Box<Fm>), All(usize, Box<Fm>) }
use Fm::*;
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a } else { gcd(b, a % b) } } fn lcm(a: i64, b: i64) -> i64 { a * b / gcd(a, b) }
fn atom(k: K, m: i64, cs: [i64; 3], c: i64) -> Fm { // cs.(x, y, w) + c >= 0, or m divides it (Dvd), or not
    if cs.iter().any(|&v| v != 0) { return At(k, m, cs, c); }
    if match k { K::Ge => c >= 0, K::Dvd => c.rem_euclid(m) == 0, K::Ndvd => c.rem_euclid(m) != 0 } { T } else { F }
}
fn join(and: bool, fs: Vec<Fm>) -> Fm { // flattened, constants folded, repeats dropped
    let (stop, unit) = if and { (F, T) } else { (T, F) };
    let mut out: Vec<Fm> = Vec::new();
    for f in fs {
        let parts = match f { And(v) if and => v, Or(v) if !and => v, g => vec![g] };
        for g in parts { if g == stop { return stop; } if g != unit && !out.contains(&g) { out.push(g); } }
    }
    if out.is_empty() { unit } else if out.len() == 1 { out.pop().unwrap() } else if and { And(out) } else { Or(out) }
}
fn amap(f: &Fm, fun: &dyn Fn(&Fm) -> Fm) -> Fm {
    match f { And(v) => join(true, v.iter().map(|g| amap(g, fun)).collect()),
              Or(v) => join(false, v.iter().map(|g| amap(g, fun)).collect()), T | F => f.clone(), _ => fun(f) }
}
fn atoms(f: &Fm, out: &mut Vec<(K, i64, [i64; 3], i64)>) {
    match f { And(v) | Or(v) => for g in v { atoms(g, out) }, At(k, m, cs, c) => out.push((*k, *m, *cs, *c)), _ => {} }
}
fn neg(f: &Fm) -> Fm { // push "not" down to the atoms
    match f {
        And(v) => join(false, v.iter().map(neg).collect()), Or(v) => join(true, v.iter().map(neg).collect()),
        T => F, F => T, At(K::Ge, _, cs, c) => atom(K::Ge, 0, [-cs[0], -cs[1], -cs[2]], -c - 1),
        At(k, m, cs, c) => atom(if *k == K::Dvd { K::Ndvd } else { K::Dvd }, *m, *cs, *c), _ => unreachable!() }
}
fn elim(v: usize, f: &Fm, kd: bool, off: bool, count: &mut usize) -> Fm { // "some v >= 0 has f", without v
    let (mut a, mut l) = (Vec::new(), 1); atoms(f, &mut a);
    for t in &a { if t.2[v] != 0 { l = lcm(l, t.2[v].abs()); } }
    let scale = |g: &Fm| -> Fm { // make v's coefficient +1 or -1: z stands for L * v
        let At(k, m, cs, c) = g else { unreachable!() }; if cs[v] == 0 { return g.clone(); }
        let s = l / cs[v].abs(); let mut c2 = [s * cs[0], s * cs[1], s * cs[2]]; c2[v] = cs[v].signum();
        atom(*k, m * s, c2, c * s)
    };
    let mut unit = [0i64; 3]; unit[v] = 1;
    let g = join(true, vec![amap(f, &scale), if kd { atom(K::Dvd, l, unit, 0) } else { T }, atom(K::Ge, 0, unit, 0)]);
    let (mut d, mut b, mut ga): (i64, Vec<([i64; 3], i64)>, _) = (1, Vec::new(), Vec::new()); atoms(&g, &mut ga);
    for (k, m, cs, c) in ga {
        if cs[v] != 0 && k != K::Ge { d = lcm(d, m); }
        if k == K::Ge && cs[v] == 1 { // z >= -(rest): a lower bound
            let mut bc = [-cs[0], -cs[1], -cs[2]]; bc[v] = 0;
            if !b.contains(&(bc, -c)) { b.push((bc, -c)); }
        }
    }
    let (js, mut alts) = (if off { d } else { 1 }, Vec::new()); *count += b.len() * js as usize;
    for bb in &b { for j in 0..js {
        let put = |t: &Fm| -> Fm { // replace z by b + j
            let At(k, m, cs, c) = t else { unreachable!() }; let (cz, mut c2) = (cs[v], [0i64; 3]);
            for i in 0..3 { if i != v { c2[i] = cs[i] + cz * bb.0[i]; } }
            atom(*k, *m, c2, c + cz * (bb.1 + j))
        };
        alts.push(amap(&g, &put)); } }
    join(false, alts)
}
fn qe(f: &Fm, kd: bool, off: bool, n: &mut usize) -> Fm {
    match f {
        And(v) => join(true, v.iter().map(|g| qe(g, kd, off, n)).collect()),
        Or(v) => join(false, v.iter().map(|g| qe(g, kd, off, n)).collect()),
        Not(g) => neg(&qe(g, kd, off, n)),
        Ex(v, g) => { let b = qe(g, kd, off, n); elim(*v, &b, kd, off, n) }
        All(v, g) => { let b = neg(&qe(g, kd, off, n)); neg(&elim(*v, &b, kd, off, n)) } _ => f.clone() }
}
fn holds(f: &Fm, x: i64) -> bool {
    match f {
        T => true, F => false, And(v) => v.iter().all(|g| holds(g, x)), Or(v) => v.iter().any(|g| holds(g, x)),
        At(k, m, cs, c) => { let s = cs[0] * x + c;
            match k { K::Ge => s >= 0, K::Dvd => s.rem_euclid(*m) == 0, K::Ndvd => s.rem_euclid(*m) != 0 } } _ => unreachable!() }
}
fn show(f: &Fm) -> String { // print a formula in x alone
    match f {
        T => "true".into(), F => "false".into(),
        And(v) => format!("({})", v.iter().map(show).collect::<Vec<_>>().join(" and ")),
        Or(v) => format!("({})", v.iter().map(show).collect::<Vec<_>>().join(" or ")),
        At(k, m, cs, c) => {
            let t = format!("{}{}", if cs[0] < 0 { "-x" } else { "x" }, if *c > 0 { format!(" + {}", c) } else if *c < 0 { format!(" - {}", -c) } else { String::new() });
            match k { K::Ge => format!("{} >= 0", t), K::Dvd => format!("{} | {}", m, t), K::Ndvd => format!("{} does not divide {}", m, t) }
        } _ => unreachable!() }
}
fn eq(cs: [i64; 3], c: i64) -> Fm { join(true, vec![atom(K::Ge, 0, cs, c), atom(K::Ge, 0, [-cs[0], -cs[1], -cs[2]], -c)]) }
fn iff(a: Fm, b: Fm) -> Fm { And(vec![Or(vec![Not(Box::new(a.clone())), b.clone()]), Or(vec![a, Not(Box::new(b))])]) }
fn tf(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn main() {
    let even = Ex(1, Box::new(Or(vec![eq([1, -2, 0], 0), eq([1, -2, 0], -1)]))); // x = 2y or x = 2y + 1
    let third = Ex(1, Box::new(eq([-1, 3, 0], -1)));                            // 3y = x + 1
    let stamp = Ex(1, Box::new(Ex(2, Box::new(eq([1, -3, -5], 0)))));            // x = 3y + 5w
    let brute: Vec<Vec<bool>> = vec![(0..60).map(|x| (0..60).any(|y| x == 2 * y || x == 2 * y + 1)).collect(),
        (0..60).map(|x| (0..61).any(|y| 3 * y == x + 1)).collect(),
        (0..60).map(|x| (0..60).any(|y| (0..60).any(|w| 3 * y + 5 * w == x))).collect()];
    let names = ["EVEN", "THIRD", "STAMP"];
    println!("part 1: quantifier elimination, free variable x = 0 to 59");
    let mut psi = Vec::new();
    for (i, f) in [&even, &third, &stamp].iter().enumerate() {
        let mut n = 0; let p = qe(f, true, true, &mut n);
        let got: Vec<bool> = (0..60).map(|x| holds(&p, x)).collect();
        let mut a = Vec::new(); atoms(&p, &mut a);
        println!("{:<5}: candidates {:>3}, atoms left {:>3}, true for {} of 60, brute force {} of 60", names[i], n, a.len(),
                 got.iter().filter(|&&b| b).count(), brute[i].iter().filter(|&&b| b).count());
        assert!(got == brute[i], "elimination disagrees with search");
        psi.push(p);
    }
    println!("EVEN  becomes {}\nTHIRD becomes {}", show(&psi[0]), show(&psi[1]));
    let mod3 = (0..60).all(|x| holds(&psi[1], x) == (x % 3 == 2));
    let miss: Vec<String> = (0..60).filter(|&x| !holds(&psi[2], x)).map(|x| x.to_string()).collect();
    println!("THIRD true exactly when x mod 3 = 2: {}  at x = 4: {}  at x = 5: {}  STAMP false at: {}", tf(mod3), tf(holds(&psi[1], 4)), tf(holds(&psi[1], 5)), miss.join(" "));
    let ge = |c: i64| atom(K::Ge, 0, [-1, 0, 0], c);
    let sent = [("for all x, some y: x = 2y or x = 2y + 1", All(0, Box::new(even.clone()))),
        ("for all x, some y: 3y = x + 1", All(0, Box::new(third.clone()))),
        ("for all x: (some y: 3y = x + 1) iff 3 divides x + 1", All(0, Box::new(iff(third.clone(), atom(K::Dvd, 3, [1, 0, 0], 1))))),
        ("for all x >= 8, some y, w: x = 3y + 5w", All(0, Box::new(Or(vec![ge(7), stamp.clone()])))),
        ("for all x >= 7, some y, w: x = 3y + 5w", All(0, Box::new(Or(vec![ge(6), stamp.clone()]))))];
    let mut verdict = Vec::new();
    for (text, s) in sent.iter() {
        let mut n = 0; let r = qe(s, true, true, &mut n);
        println!("decide: {:<52} -> {}  ({} candidates)", text, if r == T { "true" } else { "false" }, n);
        verdict.push(r);
    }
    assert!(verdict == vec![T, F, T, T, F] && mod3, "the five verdicts, and 3y = x + 1 means x mod 3 = 2");
    let mut fam = 0; for a in 1..4i64 { for m in 2..6i64 { for k in 0..3i64 { for r in 0..3i64 {
        let f = Ex(1, Box::new(And(vec![atom(K::Ge, 0, [-1, a, 0], -k), atom(K::Ge, 0, [1, -a, 0], k + 2), atom(K::Dvd, m, [0, 1, 0], r)])));
        let mut n = 0; let p = qe(&f, true, true, &mut n); if (0..60).all(|x| holds(&p, x) == (0..70).any(|y| x + k <= a * y && a * y <= x + k + 2 && (y + r) % m == 0)) { fam += 1; }
    } } } }
    println!("family: some y, x + k <= ay <= x + k + 2 and m | y + r, a <= 3, m <= 5, k, r <= 2: {} of 108 agree", fam); assert!(fam == 108, "elimination disagrees with search on the family");
    println!("part 2: eventually periodic sets");
    for (i, p) in psi.iter().enumerate() {
        let (mut per, mut start, mut a) = (1i64, 0i64, Vec::new()); atoms(p, &mut a);
        for (k, m, _, c) in a { if k == K::Ge { start = start.max(c.abs() + 1); } else { per = lcm(per, m); } }
        let ok = (start..start + 300).all(|x| holds(p, x) == holds(p, x + per));
        println!("{:<5}: repeats with period {} from x = {}: {}", names[i], per, start, tf(ok));
        assert!(ok, "a definable set must be eventually periodic"); }
    let sq: HashSet<i64> = (0..200).map(|n| n * n).collect();
    let mut broken = 0;
    for p in 1..41 { for s in 0..101 { if (0..200i64).any(|n| n * n >= s && !sq.contains(&(n * n + p))) { broken += 1; } } }
    println!("squares: (period p <= 40, start s <= 100) pairs broken by some n^2 with n^2 + p not square: {} of 4040", broken);
    assert!(broken == 4040, "no period fits the squares");
    for i in 0..3 { println!("{:<7} {}", names[i], (0..30).map(|x| if holds(&psi[i], x) { '#' } else { '.' }).collect::<String>()); }
    println!("squares {}", (0..30).map(|x| if sq.contains(&x) { '#' } else { '.' }).collect::<String>());
    println!("what breaks");
    for (label, i, f, kd, off) in [("drop 'L divides z'", 1, &third, false, true), ("offset j = 0 only", 2, &stamp, true, false)] {
        let mut n = 0; let p = qe(f, kd, off, &mut n);
        let r: Vec<bool> = (0..60).map(|x| holds(&p, x)).collect();
        println!("{}: {} true for {} of 60 (truth {})", label, names[i], r.iter().filter(|&&b| b).count(), brute[i].iter().filter(|&&b| b).count());
        assert!(r != brute[i], "a broken elimination must give a wrong set");
    }
    println!("part 3: some real x has x^2 + bx + c = 0, for b, c = -6 to 6");
    let grid = |b: i64, c: i64| (-60..61i64).any(|k| k * k + 4 * b * k + 16 * c <= 0); // 16 f(k/4), x from -15 to 15
    let (mut agree, mut roots) = (0, 0);
    for b in -6..7 { for c in -6..7 { let disc = b * b - 4 * c >= 0; if disc == grid(b, c) { agree += 1; } if disc { roots += 1; } } }
    for (b, c) in [(-6i64, 8i64), (2, 1), (1, 1)] {
        println!("b = {}, c = {}: b^2 - 4c = {}, grid finds x^2 + bx + c <= 0: {}", b, c, b * b - 4 * c, tf(grid(b, c)));
    }
    println!("b^2 - 4c >= 0 against a grid search: agree on {} of 169, real root in {}", agree, roots);
    let cube = (-6..7i64).all(|b| (-6..7i64).all(|c| -64 - 4 * b + c < 0 && 0 < 64 + 4 * b + c));
    println!("x^3 + bx + c changes sign between x = -4 and x = 4 for all 169 pairs: {}", tf(cube));
    let ints: Vec<i64> = (-1000..1001i64).filter(|x| x * x == 2).collect();
    println!("x^2 - 2: b^2 - 4c = {}   whole-number roots up to 1000: {}", 0 - 4 * -2, if ints.is_empty() { "none".to_string() } else { format!("{:?}", ints) });
    assert!(agree == 169, "discriminant and grid disagree");
    println!("ALL CHECKS PASS");
}
