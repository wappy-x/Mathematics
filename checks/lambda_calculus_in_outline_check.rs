// Lambda calculus: two plus three with functions only, then a reducer that reads the program.
// std only. A term is a variable V, a function L (name, body) or an application A (function, argument).
use std::{collections::BTreeSet, rc::Rc};
#[derive(Clone, PartialEq, Debug)]
enum T { V(String), L(String, Rc<T>), A(Rc<T>, Rc<T>) }
use T::*;
fn v(s: &str) -> Rc<T> { Rc::new(V(s.to_string())) }
fn a(f: Rc<T>, x: Rc<T>) -> Rc<T> { Rc::new(A(f, x)) }
fn l(x: &str, b: Rc<T>) -> Rc<T> { Rc::new(L(x.to_string(), b)) }
fn app(ts: &[Rc<T>]) -> Rc<T> { let mut t = ts[0].clone(); for x in &ts[1..] { t = a(t, x.clone()); } t }
struct P { toks: Vec<String>, i: usize }
fn parse(s: &str) -> Rc<T> {
    let toks = s.replace('(', " ( ").replace(')', " ) ").replace('.', " . ").replace('λ', " λ ")
        .split_whitespace().map(String::from).collect();
    P { toks, i: 0 }.term()
}
impl P {
    fn term(&mut self) -> Rc<T> {
        let x = self.toks.get(self.i + 1).cloned().unwrap_or_default();
        if self.toks[self.i] == "λ" { self.i += 3; return l(&x, self.term()); } // skip λ, the name and the dot
        let mut t = self.atom();
        while self.i < self.toks.len() && self.toks[self.i] != ")" {
            if self.toks[self.i] == "λ" { return a(t, self.term()); } // a lambda argument runs to the end
            t = a(t, self.atom()); // application groups to the left
        }
        t
    }
    fn atom(&mut self) -> Rc<T> {
        if self.toks[self.i] == "(" { self.i += 1; let t = self.term(); self.i += 1; return t; }
        self.i += 1; v(&self.toks[self.i - 1].clone())
    }
}
fn show(t: &T) -> String {
    match t { V(x) => x.clone(), L(x, b) => format!("λ{}.{}", x, show(b)), A(f, x) => {
        let fs = if matches!(**f, L(..)) { format!("({})", show(f)) } else { show(f) };
        let xs = if matches!(**x, V(_)) { show(x) } else { format!("({})", show(x)) };
        format!("{} {}", fs, xs) } }
}
fn free(t: &T) -> BTreeSet<String> {
    match t { V(x) => [x.clone()].into(), L(x, b) => { let mut s = free(b); s.remove(x); s }
              A(f, x) => { let mut s = free(f); s.extend(free(x)); s } }
}
// t with every free x replaced by s; a binder that would capture a free name of s is renamed.
fn subst(t: &Rc<T>, x: &str, s: &Rc<T>, rename: bool) -> Rc<T> {
    match &**t {
        V(y) => if y == x { s.clone() } else { t.clone() },
        A(f, g) => a(subst(f, x, s, rename), subst(g, x, s, rename)),
        L(y, b) => {
            if y == x { return t.clone(); }
            let (mut y, mut b) = (y.clone(), b.clone());
            if rename && free(s).contains(&y) {
                let (mut avoid, mut z) = (free(s), format!("{}'", y));
                avoid.extend(free(&b));
                while avoid.contains(&z) { z.push('\''); }
                b = subst(&b, &y, &v(&z), true); y = z;
            }
            l(&y, subst(&b, x, s, rename))
        }
    }
}
// One beta step, or None at a normal form. normal = leftmost outermost; otherwise arguments first.
fn step(t: &Rc<T>, normal: bool, rn: bool) -> Option<Rc<T>> {
    match &**t {
        V(_) => None,
        L(x, b) => step(b, normal, rn).map(|b| l(x, b)),
        A(f, g) => {
            if normal { if let L(x, b) = &**f { return Some(subst(b, x, g, rn)); } }
            if let Some(f2) = step(f, normal, rn) { return Some(a(f2, g.clone())); }
            if let Some(g2) = step(g, normal, rn) { return Some(a(f.clone(), g2)); }
            if let L(x, b) = &**f { Some(subst(b, x, g, rn)) } else { None }
        }
    }
}
// Returns (normal form, steps); a negative count means the term came back unchanged: it never stops.
fn reduce(t: &Rc<T>, normal: bool, cap: i64, mut trace: Option<&mut Vec<Rc<T>>>) -> (Option<Rc<T>>, i64) {
    let mut t = t.clone();
    for n in 0..=cap { // trace, if given, collects every term on the way
        if let Some(tr) = trace.as_mut() { tr.push(t.clone()); }
        match step(&t, normal, true) {
            None => return (Some(t), n),
            Some(u) => { if u == t { return (None, -n - 1); } t = u }
        }
    }
    (None, cap) // still running after cap steps
}
fn num(n: usize) -> Rc<T> { let mut b = v("x"); for _ in 0..n { b = a(v("f"), b); } l("f", l("x", b)) }
// Read a normal form λf.λx.f (f (.. x)) back as a count of f's, else -1.
fn decode(t: &Option<Rc<T>>) -> i64 {
    if let Some(t) = t { if let L(f, inner) = &**t { if let L(x, body) = &**inner {
        let (mut b, mut k) = (body.clone(), 0);
        loop {
            b = match &*b { A(g, y) if **g == V(f.clone()) => y.clone(), _ => break }; k += 1;
        }
        if *b == V(x.clone()) && f != x { return k; }
    } } }
    -1
}
// Road 2: an environment evaluator. Numbers are host integers; Inc adds one. No substitution.
#[derive(Clone)]
enum Val { Int(i64), Inc, Clo(String, Rc<T>, Vec<(String, Val)>) }
fn run(t: &Rc<T>, env: &Vec<(String, Val)>) -> Val {
    match &**t {
        V(x) => env.iter().rev().find(|(n, _)| n == x).unwrap().1.clone(),
        L(x, b) => Val::Clo(x.clone(), b.clone(), env.clone()),
        A(f, g) => match (run(f, env), run(g, env)) {
            (Val::Inc, Val::Int(k)) => Val::Int(k + 1),
            (Val::Clo(x, b, mut e), av) => { e.push((x, av)); run(&b, &e) }
            _ => panic!("not a function"),
        },
    }
}
fn host(t: Rc<T>) -> i64 {
    let env = vec![("inc".to_string(), Val::Inc), ("zero".to_string(), Val::Int(0))];
    match run(&app(&[t, v("inc"), v("zero")]), &env) { Val::Int(k) => k, _ => -1 }
}
fn main() {
    let (succ, plus) = (parse("λn.λf.λx.f (n f x)"), parse("λm.λn.λf.λx.m f (n f x)"));
    let (times, bad) = (parse("λm.λn.λf.m (n f)"), parse("λm.λn.λf.λx.m (n f) x"));
    assert!(parse("λf.λx.f (f x)") == num(2) && parse("λf.λx.x") == num(0));
    for (name, t) in [("two", num(2)), ("three", num(3)), ("succ", succ.clone()), ("plus", plus.clone())] { println!("term,{},{}", name, show(&t)); }
    let mut trace = Vec::new();
    let (five, steps) = reduce(&app(&[plus.clone(), num(2), num(3)]), true, 1000, Some(&mut trace));
    for (k, t) in trace.iter().enumerate() { println!("trace,{},{}", k, show(t)); }
    let h = host(app(&[plus.clone(), num(2), num(3)]));
    println!("answer,decoded {},host run {},plain 2 + 3 = {},beta steps {}", decode(&five), h, 2 + 3, steps);
    assert!(decode(&five) == 2 + 3 && h == 5 && five == Some(num(5)) && steps == 6);
    let mut pairs = 0;
    for m in 0..7usize { for n in 0..7usize {
        let (r, s) = reduce(&app(&[plus.clone(), num(m), num(n)]), true, 1000, None);
        let (r2, s2) = reduce(&app(&[plus.clone(), num(m), num(n)]), false, 1000, None);
        let h = host(app(&[plus.clone(), num(m), num(n)]));
        assert!(decode(&r) == (m + n) as i64 && h == (m + n) as i64 && r == r2 && s == 6 && s2 == 6);
        assert!(decode(&reduce(&app(&[succ.clone(), num(m)]), true, 1000, None).0) == (m + 1) as i64);
        assert!(decode(&reduce(&app(&[times.clone(), num(m), num(n)]), true, 1000, None).0) == (m * n) as i64); pairs += 1;
    } }
    println!("grid,plus m n for m and n in 0..6: {} pairs,all decode to m + n,both orders agree,6 steps each", pairs);
    let k = parse("λx.λy.x");
    let good = step(&app(&[k.clone(), v("y")]), true, true).unwrap();
    let naive = step(&app(&[k.clone(), v("y")]), true, false).unwrap();
    println!("break,capture: (λx.λy.x) y,renamed {},naive {}", show(&good), show(&naive));
    let (g2, n2) = (step(&a(good, v("z")), true, true).unwrap(), step(&a(naive, v("z")), true, true).unwrap());
    println!("break,capture: then applied to z,renamed {},naive {}", show(&g2), show(&n2));
    assert!(g2 == v("y") && n2 == v("z"));
    fn size(t: &T) -> usize { match t { V(_) => 1, L(_, b) => 1 + size(b), A(f, x) => 1 + size(f) + size(x) } }
    let mut t = app(&[num(3), num(2)]);
    for _ in 0..12 { t = step(&t, true, false).unwrap(); }
    println!("break,capture: three two (power) naive,after 12 steps no answer,term size {} nodes against {} for 8", size(&t), size(&num(8)));
    assert!(decode(&Some(t.clone())) == -1 && size(&t) > 1000 * size(&num(8)));
    let (r, _) = reduce(&app(&[bad, num(2), num(3)]), true, 1000, None);
    println!("break,bracket moved: λm.λn.λf.λx.m (n f) x on two three,decodes to {},not 5", decode(&r));
    assert!(decode(&r) == 6);
    let omega = parse("(λx.x x) (λx.x x)");
    let (r, s) = reduce(&omega, true, 1000, None);
    println!("break,omega {},after {} step the same term returns: no normal form", show(&omega), -s);
    assert!(r.is_none() && s == -1);
    let ko = app(&[k, v("y"), omega]);
    let ((r1, s1), (r2, s2)) = (reduce(&ko, true, 1000, None), reduce(&ko, false, 1000, None));
    let r1s = show(r1.as_ref().unwrap());
    println!("break,(λx.λy.x) y omega,normal order {} in {} steps", r1s, s1);
    println!("break,(λx.λy.x) y omega,arguments first {}", if s2 < 0 { "loops: omega returns unchanged" } else { "still running" });
    assert!(r1s == "y" && s1 == 2 && r2.is_none());
    for (label, t) in [("times two three", app(&[times.clone(), num(2), num(3)])), ("three two (power)", app(&[num(3), num(2)])),
                       ("plus twenty thirty", app(&[plus.clone(), num(20), num(30)]))] {
        let (r, s) = reduce(&t, true, 1000, None);
        println!("try,{},decodes to {},beta steps {}", label, decode(&r), s);
    }
    assert!(decode(&reduce(&app(&[num(3), num(2)]), true, 1000, None).0) == 2i64.pow(3));
    println!("ALL CHECKS PASS");
}
