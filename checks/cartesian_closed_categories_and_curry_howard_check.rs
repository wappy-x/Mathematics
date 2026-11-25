// Cartesian closed categories -- the same check as the Python, in Rust.  No crates.
// Sets: currying matches rules A x B -> C with rules A -> C^B.  Typed lambda terms three ways: a type
// checker (types are formulas), the lambda-calculus card's environment evaluator (terms become arrows:
// functions between sets), and a proof search (Dyckhoff's rules), against truth and Kripke tables.
use std::rc::Rc;
const NA: usize = 2; const NB: usize = 3; const NC: usize = 2;
fn functions(n: usize, m: usize) -> Vec<Vec<usize>> { // every list of n outputs, each below m
    let mut out: Vec<Vec<usize>> = vec![vec![]];
    for _ in 0..n { out = out.iter().flat_map(|f| (0..m).map(move |v| [f.clone(), vec![v]].concat())).collect() }
    out
}
#[derive(Clone, PartialEq, Debug)]
enum Ty { At(char), And(Box<Ty>, Box<Ty>), Imp(Box<Ty>, Box<Ty>) } // a type is also a formula
fn and(x: Ty, y: Ty) -> Ty { Ty::And(Box::new(x), Box::new(y)) }
fn imp(x: Ty, y: Ty) -> Ty { Ty::Imp(Box::new(x), Box::new(y)) }
fn show(t: &Ty, w: &str) -> String { match t { Ty::At(c) => c.to_string(),
    Ty::And(x, y) => format!("({}{}{})", show(x, w), w, show(y, w)), Ty::Imp(x, y) => format!("({} -> {})", show(x, w), show(y, w)) } }
fn inner(s: String) -> String { s[1..s.len() - 1].to_string() }
#[derive(Clone, PartialEq)]
enum Tm { Var(&'static str), Lam(&'static str, Ty, Rc<Tm>), App(Rc<Tm>, Rc<Tm>), Pair(Rc<Tm>, Rc<Tm>), Fst(Rc<Tm>), Snd(Rc<Tm>) }
fn v(n: &'static str) -> Rc<Tm> { Rc::new(Tm::Var(n)) }
fn lam(n: &'static str, t: Ty, b: Rc<Tm>) -> Rc<Tm> { Rc::new(Tm::Lam(n, t, b)) }
fn app(f: Rc<Tm>, x: Rc<Tm>) -> Rc<Tm> { Rc::new(Tm::App(f, x)) }
fn pair(x: Rc<Tm>, y: Rc<Tm>) -> Rc<Tm> { Rc::new(Tm::Pair(x, y)) }
fn fst(x: Rc<Tm>) -> Rc<Tm> { Rc::new(Tm::Fst(x)) } fn snd(x: Rc<Tm>) -> Rc<Tm> { Rc::new(Tm::Snd(x)) }
fn type_of(t: &Tm, ctx: &Vec<(&'static str, Ty)>) -> Option<Ty> { // the type checker; None means rejected
    match t {
        Tm::Var(n) => ctx.iter().rev().find(|(m, _)| m == n).map(|(_, ty)| ty.clone()),
        Tm::Lam(n, ty, b) => { let mut c = ctx.clone(); c.push((*n, ty.clone())); type_of(b, &c).map(|r| imp(ty.clone(), r)) }
        Tm::Fst(x) => match type_of(x, ctx) { Some(Ty::And(a, _)) => Some(*a), _ => None },
        Tm::Snd(x) => match type_of(x, ctx) { Some(Ty::And(_, b)) => Some(*b), _ => None },
        Tm::Pair(x, y) => Some(and(type_of(x, ctx)?, type_of(y, ctx)?)),
        Tm::App(f, x) => match (type_of(f, ctx), type_of(x, ctx)) { (Some(Ty::Imp(a, r)), Some(b)) if *a == b => Some(*r), _ => None },
    }
}
#[derive(Clone, PartialEq)]
enum V { At(usize), Pr(Box<V>, Box<V>), Clo(&'static str, Rc<Tm>, Vec<(&'static str, V)>), Tab(Vec<(V, V)>) }
fn run(t: &Tm, env: &Vec<(&'static str, V)>) -> V { // values: atoms, pairs, closures, tables
    match t {
        Tm::Var(n) => env.iter().rev().find(|(m, _)| m == n).unwrap().1.clone(),
        Tm::Lam(n, _, b) => V::Clo(*n, b.clone(), env.clone()),
        Tm::Pair(x, y) => V::Pr(Box::new(run(x, env)), Box::new(run(y, env))),
        Tm::Fst(x) => match run(x, env) { V::Pr(a, _) => *a, _ => panic!("fst of a non-pair") },
        Tm::Snd(x) => match run(x, env) { V::Pr(_, b) => *b, _ => panic!("snd of a non-pair") },
        Tm::App(f, x) => apply(&run(f, env), run(x, env)),
    }
}
fn apply(f: &V, x: V) -> V {
    match f { V::Tab(t) => t.iter().find(|(k, _)| *k == x).unwrap().1.clone(),
              V::Clo(n, b, env) => { let mut e = env.clone(); e.push((*n, x)); run(b, &e) } _ => panic!("not a function") }
}
fn at(v: &V) -> usize { match v { V::At(n) => *n, _ => panic!("not an atom") } } fn parts(v: &V) -> (usize, usize) { match v { V::Pr(a, b) => (at(a), at(b)), _ => panic!("not a pair") } }
fn prove(g: &Vec<Ty>, goal: &Ty) -> bool { // Dyckhoff's search; the first six rules lose nothing
    for i in 0..g.len() {
        let mut rest = g.clone(); match rest.remove(i) {
            Ty::And(a, b) => { rest.push(*a); rest.push(*b); return prove(&rest, goal) }
            Ty::Imp(a, b) => match *a {
                Ty::And(c, d) => { rest.push(imp(*c, imp(*d, *b))); return prove(&rest, goal) }
                Ty::At(_) if rest.contains(&a) => { rest.push(*b); return prove(&rest, goal) }
                _ => {}
            },
            _ => {}
        }
    }
    if g.contains(goal) { return true }
    match goal { Ty::And(a, b) => return prove(g, a) && prove(g, b),
        Ty::Imp(a, b) => { let mut h = g.clone(); h.push((**a).clone()); return prove(&h, b) } _ => {} }
    for i in 0..g.len() { // the one rule that needs a choice: (C -> D) -> B
        let mut rest = g.clone(); if let Ty::Imp(a, b) = rest.remove(i) { if let Ty::Imp(_, d) = &*a {
            let (mut r1, mut r2) = (rest.clone(), rest);
            r1.push(imp((**d).clone(), (*b).clone()));
            r2.push(*b);
            if prove(&r1, &a) && prove(&r2, goal) { return true }
        } }
    }
    false
}
fn value(t: &Ty, v: &[usize]) -> usize { // two stages: 0 never true, 1 true only later, 2 true from the start
    match t { Ty::At(c) => v[(*c as u8 - b'P') as usize], Ty::And(a, b) => value(a, v).min(value(b, v)),
              Ty::Imp(a, b) => if value(a, v) <= value(b, v) { 2 } else { value(b, v) } }
}
fn homs(n: usize, m: usize) -> usize { // homomorphisms Z_n -> Z_m, by brute force
    functions(n, m).iter().filter(|f| (0..n).all(|x| (0..n).all(|y| f[(x + y) % n] == (f[x] + f[y]) % m))).count()
}
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn main() {
    let (an, bn, cn) = (["member", "guest"], ["S", "M", "L"], ["no", "yes"]);
    let (rules, expo, curried) = (functions(NA * NB, NC), functions(NB, NC), functions(NA, NC.pow(NB as u32)));
    let curry = |f: &Vec<usize>| -> Vec<usize> {
        (0..NA).map(|a| expo.iter().position(|h| *h == (0..NB).map(|b| f[a * NB + b]).collect::<Vec<_>>()).unwrap()).collect() };
    let ev = |h: usize, b: usize| expo[h][b]; // eval: C^B x B -> C
    let uncurry = |g: &Vec<usize>| -> Vec<usize> { (0..NA * NB).map(|i| ev(g[i / NB], i % NB)).collect() };
    let back1 = rules.iter().filter(|f| uncurry(&curry(f)) == **f).count();
    let back2 = curried.iter().filter(|g| curry(&uncurry(g)) == **g).count();
    let refill = vec![1, 1, 1, 0, 0, 1];
    let nat = functions(NA, NA).iter().map(|u| rules.iter().filter(|f| curry(&(0..NA * NB).map(|i| f[u[i / NB] * NB + i % NB]).collect())
        == (0..NA).map(|a| curry(f)[u[a]]).collect::<Vec<_>>()).count()).sum::<usize>();
    let words = |p: &Vec<usize>| p.iter().map(|&x| cn[x]).collect::<Vec<_>>();
    println!("== currying in Set: A = 2 customer types, B = 3 cup sizes, C = {{no, yes}} ==");
    println!("rules A x B -> C, listed: {}; points of C^B: {}; rules A -> C^B, listed: {}", rules.len(), expo.len(), curried.len());
    println!("uncurry after curry gives back {} of 64; curry after uncurry gives back {} of 64", back1, back2);
    println!("refill rule on (member S, M, L, guest S, M, L): {}", words(&refill).join(" "));
    let g = curry(&refill);
    println!("curried: member -> point {} = ({}), guest -> point {} = ({}); eval(guest's menu, L) = {}",
             g[0], words(&expo[g[0]]).join(", "), g[1], words(&expo[g[1]]).join(", "), cn[ev(g[1], 2)]);
    println!("naturality in A, curry(f after (u x id)) = curry(f) after u: {} of {}", nat, 4 * rules.len());
    let sizes: Vec<String> = [(1, 2, 3), (2, 2, 3), (3, 2, 2)].iter().map(|&(a, b, c)| format!("{}, {}, {}: {} and {}",
        a, b, c, functions(a * b, c).len(), functions(a, functions(b, c).len()).len())).collect();
    println!("both sides listed at |A|, |B|, |C| = {}", sizes.join("; "));
    println!("mistake, C^B read as B^C: {} points, {} curried rules", functions(NC, NB).len(), functions(NA, functions(NC, NB).len()).len());
    println!("mistake, C^B read as pairs C x B: {} points, {} curried rules", NC * NB, functions(NA, NC * NB).len());
    println!("== groups are not cartesian closed ==");
    println!("Hom(1 x Z2, Z2) = Hom(Z2, Z2): {}; Hom(Z3, Z3): {}; Hom(1, Z2): {}; Hom(1, Z3): {}", homs(2, 2), homs(3, 3), homs(1, 2), homs(1, 3));
    let (p, q, r, pq) = (Ty::At('P'), Ty::At('Q'), Ty::At('R'), and(Ty::At('P'), Ty::At('Q')));
    let terms: Vec<(&str, Rc<Tm>)> = vec![
        ("swap", lam("p", pq.clone(), pair(snd(v("p")), fst(v("p"))))),
        ("curry", lam("f", imp(pq.clone(), r.clone()), lam("a", p.clone(), lam("b", q.clone(), app(v("f"), pair(v("a"), v("b"))))))),
        ("uncurry", lam("g", imp(p.clone(), imp(q.clone(), r.clone())), lam("p", pq.clone(), app(app(v("g"), fst(v("p"))), snd(v("p")))))),
        ("const", lam("x", p.clone(), lam("y", q.clone(), v("x")))),
        ("same", lam("p", pq.clone(), pair(fst(v("p")), snd(v("p"))))),
        ("bad", lam("p", p.clone(), fst(v("p")))),
        ("bad apply", lam("f", imp(p.clone(), q.clone()), lam("r", r.clone(), app(v("f"), v("r")))))];
    let ty = |i: usize| type_of(&terms[i].1, &vec![]);
    println!("== simply typed terms: each type is a formula ==");
    for (i, (name, _)) in terms.iter().enumerate() {
        match ty(i) { Some(t) => println!("{}: type {}, formula {}", name, inner(show(&t, " x ")), inner(show(&t, " and "))),
                      None => println!("{}: rejected", name) }
    }
    println!("== terms as arrows in Set, with P = A, Q = B, R = C ==");
    let pr: Vec<V> = (0..NA * NB).map(|i| V::Pr(Box::new(V::At(i / NB)), Box::new(V::At(i % NB)))).collect();
    let sw = run(&terms[0].1, &vec![]);
    let swap_table: Vec<usize> = pr.iter().map(|x| { let (b, a) = parts(&apply(&sw, x.clone())); b * NA + a }).collect();
    let (b4, a4) = parts(&apply(&sw, pr[4].clone()));
    println!("[[swap]] sends (guest, M) to ({}, {})", bn[b4], an[a4]);
    let (cu, un) = (run(&terms[1].1, &vec![]), run(&terms[2].1, &vec![]));
    let (mut curry_ok, mut un_ok) = (0, 0);
    for f in &rules {
        let h = apply(&cu, V::Tab(pr.iter().cloned().zip(f.iter().map(|&c| V::At(c))).collect()));
        for i in 0..NA * NB { if at(&apply(&apply(&h, V::At(i / NB)), V::At(i % NB))) == ev(curry(f)[i / NB], i % NB) { curry_ok += 1 } }
        let back = apply(&un, h);
        if (0..NA * NB).all(|i| at(&apply(&back, pr[i].clone())) == f[i]) { un_ok += 1 }
    }
    println!("[[curry]] agrees with the listed curry on {} of {} entries; [[uncurry]] after [[curry]] gives back {} of 64 rules", curry_ok, 64 * 6, un_ok);
    let ends: Vec<(Vec<usize>, Vec<usize>)> = functions(NA, NA).iter().flat_map(|h| functions(NB, NB).into_iter().map(move |k| (h.clone(), k))).collect();
    let perms: Vec<(Vec<usize>, Vec<usize>)> = ends.iter().filter(|(h, k)| (0..NA).all(|y| h.contains(&y)) && (0..NB).all(|y| k.contains(&y))).cloned().collect();
    let natural = |f: &Vec<usize>, maps: &Vec<(Vec<usize>, Vec<usize>)>| maps.iter().all(|(h, k)| (0..NA).all(|a| (0..NB).all(|b|
        f[h[a] * NB + k[b]] == k[f[a * NB + b] / NA] * NA + h[f[a * NB + b] % NA])));
    let cands = functions(NA * NB, NA * NB);
    let by_all: Vec<&Vec<usize>> = cands.iter().filter(|f| natural(f, &ends)).collect();
    let by_perm = cands.iter().filter(|f| natural(f, &perms)).count();
    println!("functions A x B -> B x A: {}; natural for all {} x {} = {} relabellings: {}, and it is [[swap]]: {}",
             cands.len(), functions(NA, NA).len(), functions(NB, NB).len(), ends.len(), by_all.len(), yn(by_all == vec![&swap_table]));
    println!("mistake, naturality tested on the {} one-to-one relabellings only: {} pass", perms.len(), by_perm);
    let mut forms: Vec<(&str, Ty)> = (0..4).map(|i| (terms[i].0, ty(i).unwrap())).collect();
    forms.push(("nested if", imp(imp(imp(p.clone(), q.clone()), r.clone()), imp(q.clone(), r.clone()))));
    forms.extend([("Peirce's law", imp(imp(imp(p.clone(), q.clone()), p.clone()), p.clone())), ("guess", imp(imp(p.clone(), q.clone()), q.clone()))]);
    println!("== the formulas alone: proof search, truth table (8 rows of P, Q, R), two-stage Kripke table (27 rows) ==");
    let holds = |t: &Ty, all: bool| functions(3, 3).iter().filter(|s| (all || !s.contains(&1)) && value(t, s) == 2).count(); // no 1: truth table
    let res: Vec<(bool, usize, usize)> = forms.iter().map(|(_, t)| (prove(&vec![], t), holds(t, false), holds(t, true))).collect();
    for (i, (name, t)) in forms.iter().enumerate() {
        println!("{}: {}: proof found {}; true in {} of 8 rows and {} of 27 two-stage rows", name, inner(show(t, " and ")), yn(res[i].0), res[i].1, res[i].2);
    }
    assert!(rules.len() == NC.pow((NA * NB) as u32) && rules.len() == 64 && curried.len() == expo.len().pow(NA as u32)); // count vs power law
    assert!(back1 == 64 && back2 == 64 && nat == 256 && g == vec![7, 1] && expo[7] == vec![1, 1, 1] && expo[1] == vec![0, 0, 1] && ev(g[1], 2) == 1);
    assert!(curry_ok == 384 && un_ok == 64 && by_all == vec![&swap_table] && by_perm == 2); // interpreter; one natural arrow
    assert!(homs(2, 2) == 2 && homs(3, 3) == 3 && homs(1, 2) == 1 && homs(1, 3) == 1);
    assert!(ty(5).is_none() && ty(6).is_none() && ty(4) != ty(0) && (0..5).all(|i| res[i] == (true, 8, 27))); // provable: true everywhere
    assert!(res[5] == (false, 8, 24) && res[6] == (false, 6, 18)); // Peirce's law and the guess: no proof
    println!("ALL CHECKS PASS");
}
