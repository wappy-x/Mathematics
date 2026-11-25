// Godel's completeness theorem -- the same check as the Python, in Rust.  No
// crates.  It runs Henkin's construction on T, the theory of a strict order
// where every point has one after it: witnesses c0 < c1 < c2 ..., then Lindenbaum's
// yes-or-no pass over every atom ci < cj, then the model read off the result.
// It also checks the 4-line refutation of the cycle theory.
// Consistency test: T's order axioms are Horn clauses (at most one positive
// part), so a set of atoms and negated atoms is consistent with them exactly
// when its transitive closure has no ci < ci and hits no negated atom.  The
// point-after axiom can always be met by new points above, so it adds nothing.
use std::collections::{BTreeMap, BTreeSet};
type Rel = BTreeSet<(usize, usize)>;

fn closure(pos: &Rel) -> Rel {                  // forward chaining with transitivity
    let mut known = pos.clone();
    loop {
        let mut new = Rel::new();
        for &(i, j) in &known { for &(k, l) in &known { if j == k && !known.contains(&(i, l)) { new.insert((i, l)); } } }
        if new.is_empty() { return known; }
        known.extend(new);
    }
}

fn consistent(pos: &Rel, neg: &Rel) -> bool {
    let c = closure(pos);
    c.iter().all(|&(i, j)| i != j) && c.intersection(neg).next().is_none()
}

fn lindenbaum(n: usize, witnesses: bool, yes_first: bool) -> (Rel, Rel) {
    let mut pos: Rel = if witnesses { (0..n.saturating_sub(1)).map(|i| (i, i + 1)).collect() } else { Rel::new() };
    let mut neg = Rel::new();
    for i in 0..n { for j in 0..n {
        let a = (i, j);
        let (mut p2, mut n2) = (pos.clone(), neg.clone());
        if yes_first {
            p2.insert(a);
            if consistent(&p2, &neg) { pos.insert(a); } else { neg.insert(a); }
        } else {
            n2.insert(a);
            if consistent(&pos, &n2) { neg.insert(a); } else { pos.insert(a); }
        }
    } }
    (closure(&pos), neg)
}

fn waiting(n: usize, r: &Rel) -> Vec<usize> { (0..n).filter(|&i| !(0..n).any(|j| r.contains(&(i, j)))).collect() }

fn show(r: &Rel) -> String {
    if r.is_empty() { return "(none)".to_string(); }
    r.iter().map(|&(i, j)| format!("c{}<c{}", i, j)).collect::<Vec<_>>().join(" ")
}

fn all_relations(n: usize) -> Vec<Rel> {        // brute force: every relation on n points
    let pairs: Vec<(usize, usize)> = (0..n).flat_map(|i| (0..n).map(move |j| (i, j))).collect();
    (0u64..1 << pairs.len()).map(|m| pairs.iter().enumerate().filter(|(b, _)| m >> b & 1 == 1).map(|(_, &p)| p).collect()).collect()
}

fn is_order(n: usize, r: &Rel) -> bool {        // irreflexive and transitive, checked directly
    (0..n).all(|i| !r.contains(&(i, i)))
        && r.iter().all(|&(i, j)| r.iter().all(|&(j2, k)| j != j2 || r.contains(&(i, k))))
}

fn two_way(r: &Rel) -> bool { r.iter().any(|&(i, j)| r.contains(&(j, i))) }

#[derive(Clone, PartialEq, Debug)]
enum F { Lt(char, char), Not(Box<F>), And(Box<F>, Box<F>), Imp(Box<F>, Box<F>) }
fn lt(x: char, y: char) -> F { F::Lt(x, y) }
fn not(f: F) -> F { F::Not(Box::new(f)) }
fn and(f: F, g: F) -> F { F::And(Box::new(f), Box::new(g)) }
fn imp(f: F, g: F) -> F { F::Imp(Box::new(f), Box::new(g)) }

fn var(s: char, c: char, sub: &mut BTreeMap<char, char>) -> bool {
    if "xyz".contains(s) { *sub.entry(s).or_insert(c) == c } else { s == c }
}

fn matches(schema: &F, f: &F, sub: &mut BTreeMap<char, char>) -> bool {   // is f the schema with x, y, z filled in?
    match (schema, f) {
        (F::Lt(a, b), F::Lt(c, d)) => var(*a, *c, sub) && var(*b, *d, sub),
        (F::Not(a), F::Not(c)) => matches(a, c, sub),
        (F::And(a, b), F::And(c, d)) | (F::Imp(a, b), F::Imp(c, d)) => matches(a, c, sub) && matches(b, d, sub),
        _ => false,
    }
}

fn check(proof: &[(F, &str)], axioms: &BTreeMap<&str, F>, hyp: &F) -> String {
    for (k, (f, why)) in proof.iter().enumerate() {
        let ok = if *why == "hypothesis" { f == hyp }
            else if *why == "transitivity" || *why == "irreflexivity" { axioms.get(why).map_or(false, |s| matches(s, f, &mut BTreeMap::new())) }
            else if why.starts_with("mp") {
                let b = why.as_bytes();
                let (i, j) = ((b[3] - b'1') as usize, (b[5] - b'1') as usize);
                imp(proof[i].0.clone(), f.clone()) == proof[j].0
            } else { false };
        if !ok { return format!("line {} rejected", k + 1); }
    }
    if proof.iter().any(|(g, _)| proof.iter().any(|(h, _)| *h == not(g.clone()))) { "contradiction reached".into() } else { "no contradiction".into() }
}

fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn main() {
    let irr = not(lt('x', 'x'));
    let trans = imp(and(lt('x', 'y'), lt('y', 'z')), lt('x', 'z'));
    let hyp = and(lt('a', 'b'), lt('b', 'a'));
    let proof = vec![(hyp.clone(), "hypothesis"), (imp(hyp.clone(), lt('a', 'a')), "transitivity"),
                     (lt('a', 'a'), "mp 1 2"), (not(lt('a', 'a')), "irreflexivity")];
    let words = ["a<b and b<a", "(a<b and b<a) -> a<a", "a<a", "not a<a"];
    let full: BTreeMap<&str, F> = [("transitivity", trans.clone()), ("irreflexivity", irr.clone())].into_iter().collect();
    let no_trans: BTreeMap<&str, F> = [("irreflexivity", irr.clone())].into_iter().collect();
    println!("Henkin stages for T: stage n has c0..c(n-1) and witnesses c(i) < c(i+1)");
    for n in 1..7 {
        let (rel, neg) = lindenbaum(n, true, true);
        let expect: Rel = (0..n).flat_map(|i| (0..n).map(move |j| (i, j))).filter(|&(i, j)| i < j).collect();
        assert!(rel == expect && rel.len() == n * (n - 1) / 2 && rel.len() + neg.len() == n * n);
        let w: Vec<String> = waiting(n, &rel).iter().map(|i| format!("'c{}'", i)).collect();
        println!("stage {}: atoms decided {}, true {}, waiting for a witness [{}]", n, n * n, rel.len(), w.join(", "));
    }
    let (yes4, _) = lindenbaum(4, true, true);
    let (no4, _) = lindenbaum(4, true, false);
    println!("stage 4, yes-first pass: {}", show(&yes4));
    println!("stage 4, no-first pass gives the same set: {}", yn(no4 == yes4));
    let facts: Rel = [(0, 1), (1, 2), (2, 3)].into_iter().collect();
    let brute: Vec<Rel> = all_relations(4).into_iter().filter(|r| is_order(4, r) && facts.is_subset(r)).collect();
    println!("brute force over {} relations on 4 points: {} model(s) with the witness facts, equal to Lindenbaum's: {}",
             1u64 << 16, brute.len(), yn(brute == vec![yes4.clone()]));
    let names = ["orders", "T", "cycle", "cycle, no transitivity"];
    let mut counts: Vec<Vec<usize>> = vec![Vec::new(); 4];
    for n in 1..5 {
        let rels = all_relations(n);
        let orders: Vec<&Rel> = rels.iter().filter(|r| is_order(n, r)).collect();
        counts[0].push(orders.len());
        counts[1].push(orders.iter().filter(|r| waiting(n, r).is_empty()).count());
        counts[2].push(orders.iter().filter(|r| two_way(r)).count());
        counts[3].push(rels.iter().filter(|r| two_way(r) && (0..n).all(|i| !r.contains(&(i, i)))).count());
    }
    for k in 0..4 { println!("models on 1, 2, 3, 4 points, {}: {:?}", names[k], counts[k]); }
    println!("refutation of the cycle theory:");
    for (k, (_, why)) in proof.iter().enumerate() { println!("  {}. {:<24} {}", k + 1, words[k], why); }
    println!("checker: {}", check(&proof, &full, &hyp));
    let cyc: Rel = [(0, 1), (1, 0)].into_iter().collect();
    println!("forward chaining from a<b, b<a reaches a<a: {}", yn(closure(&cyc).contains(&(0, 0))));
    let bare = lindenbaum(4, false, false).0;
    println!("mistake 1, no witnesses, no-first pass on 4 points: true atoms {}, points with nothing above {} of 4",
             show(&bare), waiting(4, &bare).len());
    let everything: Rel = (0..4).flat_map(|i| (0..4).map(move |j| (i, j))).collect();
    println!("mistake 2, every atom added unchecked: {} true, c(i)<c(i) at {} points, consistent: {}", everything.len(),
             (0..4).filter(|&i| everything.contains(&(i, i))).count(), yn(consistent(&everything, &Rel::new())));
    println!("mistake 3, finite search for T finds {:?}, yet stage 6 above is consistent", counts[1]);
    println!("mistake 4, transitivity dropped: checker says {}; a 2-point model exists: {}", check(&proof, &no_trans, &hyp), counts[3][1]);
    assert!(counts[0] == vec![1, 3, 19, 219] && counts[1] == vec![0, 0, 0, 0]);
    assert!(brute == vec![yes4.clone()] && no4 == yes4 && counts[2] == vec![0, 0, 0, 0]);
    assert!(check(&proof, &full, &hyp) == "contradiction reached");
    assert!(check(&[(hyp.clone(), "hypothesis"), (imp(hyp.clone(), lt('b', 'b')), "transitivity")], &full, &hyp) == "line 2 rejected");
    assert!(check(&[proof[0].clone(), proof[1].clone(), (lt('b', 'b'), "mp 1 2")], &full, &hyp) == "line 3 rejected"); // modus ponens must match
    let (p2, n2): (Rel, Rel) = ([(0, 1), (1, 2)].into_iter().collect(), [(0, 2)].into_iter().collect());
    assert!(!consistent(&p2, &n2));                 // transitivity forces c0<c2, which was denied
    let rest: Rel = everything.difference(&yes4).copied().collect();
    assert!(!consistent(&cyc, &Rel::new()) && consistent(&yes4, &rest));
    assert!(check(&proof, &no_trans, &hyp) == "line 2 rejected" && counts[3][1] == 1);
    println!("ALL CHECKS PASS");
}
