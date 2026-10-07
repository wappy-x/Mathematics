// Why there is no quintic formula -- the same check as the Python, in Rust.  No crates.  The group
// half peels the shuffles of 3, 4 and 5 roots by commutators; a shuffle of n places is a list of
// destinations, right-hand factor first.  The number half finds the root of x^5 - x - 1 and the
// radical root of x^5 - 2 by halving a bracket and again by Newton's step.
type P = Vec<i32>;
fn shuffles(n: i32) -> Vec<P> {                    // every rearrangement of n places
    let mut out: Vec<P> = vec![vec![]];
    for _ in 0..n { out = out.iter().flat_map(|s| (1..=n).filter(|d| !s.contains(d))
        .map(|d| { let mut t = s.clone(); t.push(d); t }).collect::<Vec<P>>()).collect(); }
    out
}
fn comp(a: &P, b: &P) -> P { b.iter().map(|&j| a[(j - 1) as usize]).collect() }   // b first
fn inv(a: &P) -> P { (1..=a.len() as i32).map(|i| a.iter().position(|&d| d == i).unwrap() as i32 + 1).collect() }
fn odd(a: &P) -> bool {                            // pairs standing out of order
    (0..a.len()).map(|i| (i + 1..a.len()).filter(|&j| a[i] > a[j]).count()).sum::<usize>() % 2 == 1
}
fn bracket(a: &P, b: &P) -> P { comp(&comp(a, b), &comp(&inv(a), &inv(b))) }
fn uniq(mut v: Vec<P>) -> Vec<P> { v.sort(); v.dedup(); v }
fn close(gens: Vec<P>, ident: &P) -> Vec<P> {      // smallest group holding the gens
    let mut g = uniq([gens, vec![ident.clone()]].concat());
    loop {
        let grown: Vec<P> = g.iter().flat_map(|a| g.iter().map(move |b| comp(a, b))).collect();
        let wider = uniq([g.clone(), grown].concat());
        if wider == g { return g; } else { g = wider; }
    }
}
fn peel(g: &[P], ident: &P) -> Vec<P> {
    close(g.iter().flat_map(|a| g.iter().map(move |b| bracket(a, b))).collect(), ident)
}
fn ladder(n: i32) -> Vec<usize> {                  // group sizes down the peeling chain
    let (ident, mut g, mut sizes): (P, Vec<P>, Vec<usize>) = ((1..=n).collect(), uniq(shuffles(n)), vec![]);
    for _ in 0..4 { sizes.push(g.len()); g = peel(&g, &ident); }
    sizes
}
fn chain(s: &[usize]) -> String { s.iter().map(|v| v.to_string()).collect::<Vec<_>>().join(" -> ") }
fn tf(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn five(x: f64) -> f64 { x * x * x * x * x }
fn hard(x: f64) -> f64 { five(x) - x - 1.0 }
fn easy(x: f64) -> f64 { five(x) - 2.0 }
fn halve(h: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {    // both curves rise
    for _ in 0..50 { let mid = (lo + hi) / 2.0; if h(mid) < 0.0 { lo = mid; } else { hi = mid; } }
    (lo + hi) / 2.0
}
fn newton(h: &dyn Fn(f64) -> f64, slope: &dyn Fn(f64) -> f64, mut x: f64) -> f64 {
    for _ in 0..8 { x = x - h(x) / slope(x); }
    x
}
fn main() {
    let (e5, s5): (P, Vec<P>) = ((1..=5).collect(), uniq(shuffles(5)));
    let (a5, first): (Vec<P>, Vec<P>) = (s5.iter().filter(|s| !odd(s)).cloned().collect(), peel(&s5, &e5));
    let threes: Vec<P> = a5.iter().filter(|s| s.iter().enumerate()
        .filter(|(i, &d)| d != *i as i32 + 1).count() == 3).cloned().collect();
    let commutators = uniq(a5.iter().flat_map(|a| a5.iter().map(move |b| bracket(a, b))).collect());
    let (built, s3, s4, sizes) = (close(threes.clone(), &e5), ladder(3), ladder(4), ladder(5));
    let pair = a5.iter().flat_map(|a| a5.iter().map(move |b| (a, b)))
        .find(|(a, b)| bracket(a, b) == vec![2, 3, 1, 4, 5]).unwrap();
    let every_three = threes.iter().all(|t| commutators.contains(t));
    println!("shuffles of 3, 4 and 5 roots: {}, {} and {}", shuffles(3).len(), shuffles(4).len(), s5.len());
    println!("peeled by commutators, 3 roots: {}; 4 roots: {} -- both reach 1", chain(&s3), chain(&s4));
    println!("peeled by commutators, 5 roots: {} -- stuck at {}", chain(&sizes), sizes[3]);
    println!("the first peel of the 120 is exactly the {} even shuffles: {}", a5.len(), tf(first == a5));
    println!("all {} three-place cycles are commutators of even shuffles: {}; they build \
all {}", threes.len(), tf(every_three), built.len());
    println!("smallest such pair: [2, 3, 1, 4, 5] from {:?} and {:?}", pair.0, pair.1);
    let (eb, hb) = (halve(&easy, 1.0, 2.0), halve(&hard, 1.0, 2.0));
    let (en, hn) = (newton(&easy, &|x: f64| 5.0 * x * x * x * x, 1.2),
                    newton(&hard, &|x: f64| 5.0 * x * x * x * x - 1.0, 1.2));
    println!("x^5 - 2 at x = 1 and x = 2: {:.2} and {:.2}; x^5 - x - 1 there: {:.2} and {:.2}",
             easy(1.0), easy(2.0), hard(1.0), hard(2.0));
    println!("x^5 - 2, the radical case: 50 halvings give {:.10}, 8 Newton steps {:.10}", eb, en);
    println!("that root's fifth power, by five multiplications: {:.10}", five(eb));
    println!("x^5 - x - 1: 50 halvings give {:.10}, 8 Newton steps from 1.2 {:.10}", hb, hn);
    println!("the four mistakes come out at a residual of {:.10}, a radical answer of {:.10}, \
a peel stuck at {} instead of 1, and a root of {:.10} all the same", hard(eb), eb, sizes[3], hb);
    assert!(first == a5 && a5.len() == 60 && sizes == vec![120, 60, 60, 60]);
    assert!(every_three && built == a5 && threes.len() == 20);
    assert!(s3 == vec![6, 3, 1, 1] && s4 == vec![24, 12, 4, 1]);
    assert!((hb - hn).abs() < 1e-12 && (five(hb) - hb - 1.0).abs() < 1e-12 && (five(eb) - 2.0).abs() < 1e-12);
    println!("ALL CHECKS PASS");
}
