// Branch and bound on a festival booking -- the check behind the card.  std only, no crates.
// Five acts, a £150k fee budget: book the acts that bring the most extra ticket sales (maximise).
// Every relaxation is solved in exact fractions, with a small rational type written out below.
use std::cmp::Ordering;
const NAMES: [&str; 5] = ["A", "B", "C", "D", "E"];
const FEE: [i64; 5] = [30, 80, 80, 30, 90]; // f_j, the act's fee, £k
const SALES: [i64; 5] = [70, 130, 115, 40, 90]; // v_j, extra ticket sales it brings, £k
const BUDGET: i64 = 150;
const BY_RATIO: [usize; 5] = [0, 1, 2, 3, 4]; // sales per £ of fee, best first (checked below)
const BY_SALES: [usize; 5] = [1, 2, 4, 0, 3]; // biggest sales first: the wrong fill
#[derive(Clone, Copy, Debug, PartialEq)]
struct Q(i64, i64); // numerator, denominator > 0, in lowest terms
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i64, d: i64) -> Q { let g = gcd(n, d).max(1); Q(n / g, d / g) }
impl Q {
    fn add(self, o: Q) -> Q { q(self.0 * o.1 + o.0 * self.1, self.1 * o.1) }
    fn mul(self, o: Q) -> Q { q(self.0 * o.0, self.1 * o.1) }
    fn cmp(self, o: Q) -> Ordering { (self.0 * o.1).cmp(&(o.0 * self.1)) }
}
fn num(x: Q) -> String { // an exact decimal: every number here has one
    assert!(10000 % x.1 == 0); let v = x.0 * (10000 / x.1);
    format!("{}.{:04}", v / 10000, v % 10000).trim_end_matches('0').trim_end_matches('.').to_string()
}
type Fix = Vec<(usize, i64)>; // acts set so far, in the order they were set: 1 booked, 0 skipped
type Relax = Option<(Q, Option<usize>, Vec<usize>)>; // ceiling, act taken in part, acts taken whole
fn get(fix: &Fix, j: usize) -> Option<i64> { fix.iter().find(|p| p.0 == j).map(|p| p.1) }
fn relax(fix: &Fix, budget: i64, order: &[usize; 5]) -> Relax {
    let mut took: Vec<usize> = fix.iter().filter(|p| p.1 == 1).map(|p| p.0).collect();
    let mut left = budget - fees(&took);
    if left < 0 { return None; } // the acts already booked break the budget
    let mut z = q(sales(&took), 1);
    for &j in order {
        if get(fix, j).is_some() { continue; }
        if FEE[j] > left { return Some(if left > 0 { (z.add(q(SALES[j] * left, FEE[j])), Some(j), took) } else { (z, None, took) }); }
        left -= FEE[j]; z = z.add(q(SALES[j], 1)); took.push(j);
    }
    Some((z, None, took))
}
// Road 2: charge lam per £k of fee. Every whole plan in the node earns at most this. No fill used.
fn price_bound(fix: &Fix, lam: Q) -> Q {
    let booked: Vec<usize> = fix.iter().filter(|p| p.1 == 1).map(|p| p.0).collect();
    let mut b = q(sales(&booked), 1).add(lam.mul(q(BUDGET - fees(&booked), 1)));
    for j in (0..5).filter(|&j| get(fix, j).is_none()) {
        let gain = q(SALES[j], 1).add(lam.mul(q(-FEE[j], 1))); if gain.0 > 0 { b = b.add(gain); } }
    b
}
struct Node { fix: Fix, r: Relax, depth: i64, verdict: &'static str, inc: Q, parent: i64 }
// Road 1. A node is solved when made, then closed or split when taken off the list.
fn search(best_first: bool, in_order: bool, budget: i64, order: &[usize; 5], first_whole: bool) -> (Vec<Node>, Q, Vec<usize>) {
    let mut todo: Vec<(Fix, Relax, i64, i64)> = vec![(vec![], relax(&vec![], budget, order), 0, -1)];
    let (mut done, mut inc, mut plan): (Vec<Node>, Q, Vec<usize>) = (vec![], q(-1, 1), vec![]);
    while !todo.is_empty() {
        let mut k = todo.len() - 1; // depth-first: the last one made
        if best_first { // best-first: highest ceiling, oldest on a tie
            let key = |i: usize| todo[i].1.as_ref().map(|r| r.0).unwrap_or(q(-1, 1));
            k = (1..todo.len()).fold(0, |k, i| if key(i).cmp(key(k)) == Ordering::Greater { i } else { k });
        }
        let (fix, r, depth, parent) = todo.remove(k);
        let verdict = match &r {
            None => "infeasible",
            Some((z, _, _)) if z.cmp(inc) != Ordering::Greater => "bound",
            Some((z, None, took)) => { inc = *z; plan = took.clone(); plan.sort(); "whole" }
            Some((_, Some(part), _)) => {
                let j = if in_order { (0..5).find(|&i| get(&fix, i).is_none()).unwrap() } else { *part };
                let mut kids: Vec<_> = [1, 0].iter().map(|&v| { let mut f = fix.clone(); f.push((j, v));
                    let rr = relax(&f, budget, order); (f, rr, depth + 1, done.len() as i64) }).collect();
                if !best_first { kids.reverse(); } // depth-first takes "book it" first
                todo.extend(kids); "split"
            }
        };
        done.push(Node { fix, r, depth, verdict, inc, parent });
        if first_whole && verdict == "whole" { break; }
    }
    (done, inc, plan)
}
fn acts(p: &[usize]) -> String { let mut s = p.to_vec(); s.sort(); s.iter().map(|&j| NAMES[j]).collect::<Vec<_>>().join(" ") }
fn fees(p: &[usize]) -> i64 { p.iter().map(|&j| FEE[j]).sum() }
fn sales(p: &[usize]) -> i64 { p.iter().map(|&j| SALES[j]).sum() }
fn place(done: &Vec<Node>, i: usize, nxt: &mut i64, pos: &mut Vec<(i64, i64)>) -> i64 {
    let mut kids: Vec<usize> = (0..done.len()).filter(|&k| done[k].parent == i as i64).collect();
    kids.sort_by_key(|&k| -done[k].fix.last().unwrap().1); // the "book it" child on the left
    let xs: Vec<i64> = kids.iter().map(|&k| place(done, k, nxt, pos)).collect();
    let x = if xs.is_empty() { *nxt += 80; *nxt - 80 } else { (xs[0] + xs[1]) / 2 };
    pos[i] = (x, 28 + 55 * done[i].depth);
    x
}
fn main() {
    assert!(BY_RATIO.windows(2).all(|w| SALES[w[0]] * FEE[w[1]] > SALES[w[1]] * FEE[w[0]]));
    let hdr: Vec<String> = (0..5).map(|j| { let r = (2000 * SALES[j] + FEE[j]) / (2 * FEE[j]);
        format!("{} {} {} {}.{:03}", NAMES[j], FEE[j], SALES[j], r / 1000, r % 1000) }).collect();
    println!("acts (fee, sales, per £): {}", hdr.join(", "));
    let best_first = false; let (done, best, plan) = search(best_first, false, BUDGET, &BY_RATIO, false); // true: best-first
    for (n, d) in done.iter().enumerate() {
        let mut what = d.verdict.to_string();
        if let Some((z, Some(p), _)) = &d.r {
            if d.verdict == "split" { what = format!("split on {}", NAMES[*p]); }
            let lam = q(SALES[*p], FEE[*p]); // road 2 at every node with an act booked in part
            assert!(price_bound(&d.fix, lam) == *z && price_bound(&d.fix, lam.add(q(1, 8))).cmp(*z) == Ordering::Greater);
            what += &format!(", price {}", num(lam));
        }
        let lab = d.fix.iter().map(|p| format!("{}{}", if p.1 == 1 { "+" } else { "-" }, NAMES[p.0])).collect::<Vec<_>>().join(" ");
        let lab = if lab.is_empty() { "root".to_string() } else { lab };
        let ceil = d.r.as_ref().map(|r| num(r.0)).unwrap_or("none".into());
        println!("node {}  {:<9} ceiling {:>7}  {:<24} best so far {}", n + 1, lab, ceil, what, if d.inc.0 < 0 { "none".into() } else { num(d.inc) });
    }
    let count = |v: &str| done.iter().filter(|d| d.verdict == v).count();
    println!("{}: {} nodes, {} split, {} pruned ({} infeasible, {} bound, {} whole)", if best_first { "best-first" } else { "depth-first" }, done.len(), count("split"),
        done.len() - count("split"), count("infeasible"), count("bound"), count("whole"));
    let root = done[0].r.as_ref().unwrap().0;
    println!("answer: book {}, sales {}, fees {}; root ceiling {}, integrality gap {}", acts(&plan), num(best), fees(&plan), num(root), num(root.add(q(-best.0, best.1))));
    // How the search moves: after each node, the most any plan still on the list could earn, and the best in hand
    let (mut hi, mut lo) = (vec![root], vec![q(0, 1)]);
    for n in 0..done.len() {
        let floor = if done[n].inc.0 < 0 { q(0, 1) } else { done[n].inc }; let mut top = floor;
        for (m, d) in done.iter().enumerate() {
            if let Some(r) = &d.r { if m > n && d.parent <= n as i64 && r.0.cmp(top) == Ordering::Greater { top = r.0; } }
        }
        hi.push(top); lo.push(floor);
    }
    let gap: Vec<Q> = hi.iter().zip(&lo).map(|(a, b)| a.add(q(-b.0, b.1))).collect();
    for (name, row) in [("most still possible", &hi), ("best found", &lo), ("search gap", &gap)] {
        println!("{:<20} {}", format!("{}:", name), row.iter().map(|&x| num(x)).collect::<Vec<_>>().join(" "));
    }
    // Road 3: all 32 plans, and a check that the closed nodes hold each plan exactly once
    let plans: Vec<Vec<usize>> = (0..32).map(|m| (0..5).filter(|j| m >> j & 1 == 1).collect()).collect();
    let fits: Vec<&Vec<usize>> = plans.iter().filter(|p| fees(p) <= BUDGET).collect();
    let top = fits.iter().map(|p| sales(p)).max().unwrap();
    let winners: Vec<&&Vec<usize>> = fits.iter().filter(|p| sales(p) == top).collect();
    let leaves: Vec<&Node> = done.iter().filter(|d| d.verdict != "split").collect();
    for p in &plans {
        let home: Vec<&&Node> = leaves.iter().filter(|d| d.fix.iter().all(|f| p.contains(&f.0) == (f.1 == 1))).collect();
        assert!(home.len() == 1);
        if fees(p) <= BUDGET { assert!(home[0].r.as_ref().unwrap().0.cmp(q(sales(p), 1)) != Ordering::Less); }
    }
    println!("every plan: {} plans, {} fit, best {} = {}, winners {}", plans.len(), fits.len(), top, acts(winners[0]), winners.len());
    println!("the {} closed nodes hold all {} plans once each; none beats its node's ceiling", leaves.len(), plans.len());
    assert!(best == q(top, 1) && winners.len() == 1 && *winners[0] == &plan);
    assert!((done.len(), leaves.len(), count("whole")) == (9, 5, 2));
    // Other choices of node and of branching act: same answer, different work
    for (name, bf, ord) in [("best-first", true, false), ("branch in order A to E", false, true)] {
        let (d, b, p) = search(bf, ord, BUDGET, &BY_RATIO, false);
        assert!(b == best && p == plan);
        println!("{}: {} nodes, answer {}", name, d.len(), num(b));
    }
    // What breaks
    let (d, b, p) = search(false, false, BUDGET, &BY_RATIO, true);
    println!("stop at the first whole plan: {}, sales {}, after {} nodes", acts(&p), num(b), d.len());
    let (rz, rp, rt) = relax(&vec![], BUDGET, &BY_RATIO).unwrap();
    let mut up = rt.clone(); up.push(rp.unwrap());
    println!("round the root down: {}, sales {}; round it up: {}, fees {} against {}", acts(&rt), sales(&rt), acts(&up), fees(&up), BUDGET);
    let (d, b, p) = search(false, false, BUDGET, &BY_SALES, false);
    let wrong = d[0].r.as_ref().unwrap().0;
    println!("fill biggest sales first: root 'ceiling' {}, answer {} {}", num(wrong), acts(&p), num(b));
    assert!(b.cmp(best) == Ordering::Less && wrong.cmp(best) == Ordering::Less && rz.cmp(best) == Ordering::Greater);
    assert!(sales(&rt) < top && top < sales(&up));
    let real = |p: &[usize]| sales(p) - if p.contains(&0) && p.contains(&1) { 30 } else { 0 }; // A and B pull the same crowd
    let alt = fits.iter().fold(fits[0], |a, p| if real(p) > real(a) { p } else { a });
    println!("A and B share fans, £30k less together: {} really earns {}; best is {} {}", acts(&plan), real(&plan), acts(alt), real(alt));
    // Try changing the budget
    for bud in [140, 130] {
        let (d, b, p) = search(false, false, bud, &BY_RATIO, false);
        println!("budget {}: {} nodes, book {}, sales {}", bud, d.len(), acts(&p), num(b));
    }
    // Figure: leaves 80 apart left to right, each parent above the middle of its two children
    let (mut nxt, mut pos) = (40, vec![(0, 0); done.len()]);
    place(&done, 0, &mut nxt, &mut pos);
    let fig: Vec<String> = pos.iter().enumerate().map(|(n, p)| format!("{}:{},{}", n + 1, p.0, p.1)).collect();
    println!("figure, {}", fig.join(" "));
    println!("ALL CHECKS PASS");
}
