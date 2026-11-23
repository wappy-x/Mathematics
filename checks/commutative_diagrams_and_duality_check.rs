// Commutative diagrams and duality -- the same check as the Python, in Rust.
// No crates.  A cafe: drinks A, pastries B, a meal deal in A x B, a voucher
// item in A + B.  Each diagram is read as equations and every candidate arrow
// is tried; then a small category of finite sets is reversed, arrow by arrow.
use std::collections::BTreeSet;

const A: [&str; 2] = ["tea", "coffee"];
const B: [&str; 3] = ["scone", "muffin", "toast"];
const F: [usize; 3] = [0, 1, 0];                    // f: X -> A, drink per table
const G: [usize; 3] = [0, 2, 1];                    // g: X -> B, pastry per table
const P: [i64; 2] = [250, 300];                     // p: A -> Y, pence
const Q: [i64; 3] = [280, 320, 200];                // q: B -> Y, pence
const FIG: &str = "product: X 220,60; AxB 220,170; A 80,280; B 360,280 | sum: Y 680,60; A+B 680,170; A 540,280; B 820,280";

fn functions(n: usize, m: usize) -> Vec<Vec<usize>> {   // every map n -> m, as a list
    let mut out: Vec<Vec<usize>> = vec![vec![]];
    for _ in 0..n {
        let mut next = Vec::new();
        for h in &out { for c in 0..m { let mut k = h.clone(); k.push(c); next.push(k); } }
        out = next;
    }
    out
}
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }

type Arrow = (usize, usize, Vec<usize>);            // (domain size, codomain size, values)
fn comp(g: &Arrow, f: &Arrow) -> Arrow { (f.0, g.1, f.2.iter().map(|&i| g.2[i]).collect()) }
fn ident(n: usize) -> Arrow { (n, n, (0..n).collect()) }
struct Cat { op: bool }                                // C, or C^op: same arrows, reversed
impl Cat {
    fn d(&self, f: &Arrow) -> usize { if self.op { f.1 } else { f.0 } }
    fn c(&self, f: &Arrow) -> usize { if self.op { f.0 } else { f.1 } }
    fn k(&self, g: &Arrow, f: &Arrow) -> Arrow { if self.op { comp(f, g) } else { comp(g, f) } }
}
fn laws(cat: &Cat, ar: &[Arrow]) -> bool {           // identities and associativity
    let ok = ar.iter().all(|f| cat.k(f, &ident(cat.d(f))) == *f && cat.k(&ident(cat.c(f)), f) == *f);
    ok && ar.iter().all(|f| ar.iter().all(|g| ar.iter().all(|h|
        !(cat.c(f) == cat.d(g) && cat.c(g) == cat.d(h)) || cat.k(h, &cat.k(g, f)) == cat.k(&cat.k(h, g), f))))
}
fn mono(f: &Arrow, cat: &Cat, ar: &[Arrow]) -> bool { // f.g = f.h forces g = h
    ar.iter().all(|g| ar.iter().all(|h| !(cat.c(g) == cat.d(f) && cat.d(f) == cat.c(h)
        && cat.d(g) == cat.d(h) && cat.k(f, g) == cat.k(f, h)) || g == h))
}
fn epi(f: &Arrow, cat: &Cat, ar: &[Arrow]) -> bool {  // g.f = h.f forces g = h
    ar.iter().all(|g| ar.iter().all(|h| !(cat.d(g) == cat.c(f) && cat.c(f) == cat.d(h)
        && cat.c(g) == cat.c(h) && cat.k(g, f) == cat.k(h, f)) || g == h))
}
fn square(m: usize) -> (Vec<(usize, usize)>, Vec<(usize, usize)>) {
    let (mut good, mut bad) = (vec![], vec![]);
    for a in 0..12 { for b in 0..12 {
        if (a + b) % 12 % m == (a % m + b % m) % m { good.push((a, b)) } else { bad.push((a, b)) }
    } }
    (good, bad)
}

fn main() {
    let prod: Vec<(usize, usize)> = (0..2).flat_map(|a| (0..3).map(move |b| (a, b))).collect();
    let summ: Vec<(usize, usize)> = (0..2).map(|a| (0, a)).chain((0..3).map(|b| (1, b))).collect();
    let pairing: Vec<usize> = (0..3).map(|x| F[x] * 3 + G[x]).collect();       // <f, g>, built
    let prod_maps = functions(3, prod.len());
    let prod_pass: Vec<&Vec<usize>> = prod_maps.iter()
        .filter(|h| (0..3).all(|x| prod[h[x]].0 == F[x] && prod[h[x]].1 == G[x])).collect();
    let ys: Vec<i64> = P.iter().chain(Q.iter()).copied().collect::<BTreeSet<i64>>().into_iter().collect();
    let price = |t: usize, v: usize| if t == 0 { P[v] } else { Q[v] };
    let case: Vec<usize> = summ.iter().map(|&(t, v)| ys.iter().position(|&y| y == price(t, v)).unwrap()).collect();
    let sum_maps = functions(summ.len(), ys.len());
    let sum_pass: Vec<&Vec<usize>> = sum_maps.iter()
        .filter(|h| (0..2).all(|a| ys[h[a]] == P[a]) && (0..3).all(|b| ys[h[2 + b]] == Q[b])).collect();

    println!("drinks A = {}; pastries B = {}", A.join(", "), B.join(", "));
    println!("A x B, the meal deals: {} = 2 x 3; a third drink makes {}", prod.len(), (A.len() + 1) * B.len());
    println!("  {}", prod.iter().map(|&(a, b)| format!("({}, {})", A[a], B[b])).collect::<Vec<_>>().join(" "));
    println!("A + B, the voucher items: {} = 2 + 3; a third drink makes {}", summ.len(), A.len() + 1 + B.len());
    println!("  {}", summ.iter().map(|&(t, v)| if t == 0 { format!("drink:{}", A[v]) } else { format!("pastry:{}", B[v]) })
        .collect::<Vec<_>>().join(" "));
    println!("<f, g> sends tables 1, 2, 3 to: {}", pairing.iter().map(|&i| format!("({}, {})", A[prod[i].0], B[prod[i].1]))
        .collect::<Vec<_>>().join(" "));
    println!("functions X -> A x B tried: {}; passing fst after h = f, snd after h = g: {}", prod_maps.len(), prod_pass.len());
    println!("the one that passes is the pairing built directly: {}", yn(prod_pass == vec![&pairing]));
    println!("{} = 2^3 x 3^3 = {} x {}", prod_maps.len(), 2i64.pow(3), 3i64.pow(3));
    println!("[p, q] sends the voucher items to: {}", case.iter().map(|&i| ys[i].to_string()).collect::<Vec<_>>().join(" "));
    println!("functions A + B -> Y tried: {}; passing h after inl = p, h after inr = q: {}", sum_maps.len(), sum_pass.len());
    println!("the one that passes is the case split built directly: {}", yn(sum_pass == vec![&case]));
    println!("{} = {n}^2 x {n}^3 = {} x {}", sum_maps.len(), ys.len().pow(2), ys.len().pow(3), n = ys.len());

    let mut ar: Vec<Arrow> = vec![];                 // C: sets {}, {0}, {0, 1}, all functions
    for n in 0..3 { for m in 0..3 { for h in functions(n, m) { ar.push((n, m, h)); } } }
    let (c, cop) = (Cat { op: false }, Cat { op: true });
    let monos: Vec<&Arrow> = ar.iter().filter(|f| mono(f, &c, &ar)).collect();
    let epis: Vec<&Arrow> = ar.iter().filter(|f| epi(f, &c, &ar)).collect();
    let distinct = |f: &Arrow| f.2.iter().collect::<BTreeSet<_>>().len();
    let inj: Vec<&Arrow> = ar.iter().filter(|f| distinct(f) == f.0).collect();
    let sur: Vec<&Arrow> = ar.iter().filter(|f| distinct(f) == f.1).collect();
    let dual_ok = ar.iter().filter(|f| mono(f, &c, &ar) == epi(f, &cop, &ar) && epi(f, &c, &ar) == mono(f, &cop, &ar)).count();
    let (lc, lop) = (laws(&c, &ar), laws(&cop, &ar));
    println!("finite category C: sets of size 0, 1, 2 and every function between them: {} arrows", ar.len());
    println!("laws (identity, associativity) hold in C: {}; in C^op: {}", yn(lc), yn(lop));
    println!("monos in C: {}; one-to-one functions: {}; same arrows: {}", monos.len(), inj.len(), yn(monos == inj));
    println!("epis in C: {}; onto functions: {}; same arrows: {}", epis.len(), sur.len(), yn(epis == sur));
    println!("mono in C is epi in C^op, and epi is mono, arrow by arrow: {} of {}", dual_ok, ar.len());
    println!("epis in C^op: {}; monos in C^op: {}", ar.iter().filter(|f| epi(f, &cop, &ar)).count(),
             ar.iter().filter(|f| mono(f, &cop, &ar)).count());

    let ((good3, _), (good5, bad5)) = (square(3), square(5));
    let (a, b) = bad5[0];
    println!("group square, x mod 3 on the 12-hour clock: commutes on {} of 144 pairs", good3.len());
    println!("group square, x mod 5 on the 12-hour clock: commutes on {} of 144 pairs; first failure ({}, {}): {} against {}",
             good5.len(), a, b, (a + b) % 12 % 5, (a % 5 + b % 5) % 5);

    let (here, away): ([i64; 2], [i64; 2]) = (P, [230, 270]);
    let y2: Vec<i64> = here.iter().chain(away.iter()).copied().collect::<BTreeSet<i64>>().into_iter().collect();
    let union_pass = functions(2, y2.len()).iter().filter(|h| (0..2).all(|x| y2[h[x]] == here[x] && y2[h[x]] == away[x])).count();
    let twice_pass = functions(4, y2.len()).iter().filter(|h| (0..2).all(|x| y2[h[x]] == here[x] && y2[h[2 + x]] == away[x])).count();
    let both: Vec<String> = (0..2).map(|x| format!("{} {} or {}", A[x], here[x], away[x])).collect();
    println!("mistake 1, plain union A u A for here and takeaway, {}: 2 items, {} of {} functions pass",
             both.join(", "), union_pass, y2.len().pow(2));
    println!("   disjoint union A + A: 4 items, {} of {} functions pass", twice_pass, y2.len().pow(4));
    let empty_prod: Vec<(usize, usize)> = (0..2).flat_map(|x| (0..0).map(move |y| (x, y))).collect();
    let reached = empty_prod.iter().map(|p| p.0).collect::<BTreeSet<_>>().len();
    println!("mistake 2, dualising a fact about sets only: inl is one-to-one, but with B empty A x B has {} members and fst reaches {} of 2 drinks",
             empty_prod.len(), reached);
    println!("mistake 3, one pair checked: x mod 5 at (2, 3) gives {} both ways, yet {} of 144 pairs fail", (2 + 3) % 12 % 5, bad5.len());
    println!("mistake 4, the sum counted as a product: {}, not {}", A.len() * B.len(), summ.len());
    println!("figure, {}", FIG);

    assert!(prod_pass == vec![&pairing] && sum_pass == vec![&case]);      // exactly one, the built one
    assert!(prod_maps.len() == functions(3, 2).len() * functions(3, 3).len());
    assert!(sum_maps.len() == functions(2, ys.len()).len() * functions(3, ys.len()).len());
    assert!(lc && lop && monos == inj && epis == sur);                     // cancellation = elements
    assert!(dual_ok == ar.len() && monos.len() == 8 && epis.len() == 5);
    assert!(good3.len() == 144 && bad5.len() == (0..12).map(|a| (0..12).filter(|b| a + b >= 12).count()).sum::<usize>());
    assert!(union_pass == 0 && twice_pass == 1);
    println!("ALL CHECKS PASS");
}
