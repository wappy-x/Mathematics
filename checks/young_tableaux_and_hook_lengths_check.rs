// Young tableaux and hook lengths -- the same check as the Python, in Rust.  No crates.  Five
// ballots, three yes and two no, fill the shape (3, 2), counted by listing, by the hook formula,
// by the hook walk and by reflection; Schur polynomials come from semistandard tableaux.
use std::collections::BTreeMap;
type Cell = (usize, usize); type Frac = (u128, u128); type Tab = Vec<Vec<usize>>;
fn fact(n: u128) -> u128 { (1..=n).product() }
fn choose(n: u128, k: u128) -> u128 { fact(n) / (fact(k) * fact(n - k)) }
fn gcd(a: u128, b: u128) -> u128 { if b == 0 { a } else { gcd(b, a % b) } }
fn frac(a: u128, b: u128) -> Frac { let g = gcd(a, b); (a / g, b / g) }
fn add(x: Frac, y: Frac) -> Frac { frac(x.0 * y.1 + y.0 * x.1, x.1 * y.1) }
fn cells(lam: &[usize]) -> Vec<Cell> { (0..lam.len()).flat_map(|i| (0..lam[i]).map(move |j| (i, j))).collect() }
fn hook_cells(lam: &[usize], c: Cell) -> Vec<Cell> {     // the cells right of c, then the cells below c
    (c.1 + 1..lam[c.0]).map(|j| (c.0, j)).chain((c.0 + 1..lam.len()).filter(|&i| lam[i] > c.1).map(|i| (i, c.1))).collect() }
fn hooks(lam: &[usize]) -> Vec<u128> { cells(lam).iter().map(|&c| 1 + hook_cells(lam, c).len() as u128).collect() }
fn by_hooks(lam: &[usize]) -> u128 { fact(lam.iter().sum::<usize>() as u128) / hooks(lam).iter().product::<u128>() }  // road one
fn fill(lam: &[usize], p: &[usize]) -> Tab { let mut k = 0; lam.iter().map(|&r| { k += r; p[k - r..k].to_vec() }).collect() }
fn ok(t: &Tab, strict: bool) -> bool {                  // rows rise (strictly or weakly), columns rise strictly
    cells(&t.iter().map(|r| r.len()).collect::<Vec<_>>()).iter().all(|&(i, j)|
        (j == 0 || t[i][j] > t[i][j - 1] || (!strict && t[i][j] == t[i][j - 1])) && (i == 0 || t[i][j] > t[i - 1][j])) }
fn perms(v: &[usize]) -> Vec<Vec<usize>> {
    if v.is_empty() { return vec![vec![]] }
    (0..v.len()).flat_map(|i| { let mut r = v.to_vec(); let x = r.remove(i); perms(&r).into_iter().map(move |p| [vec![x], p].concat()) }).collect() }
fn words(m: usize, len: usize) -> Vec<Vec<usize>> {
    if len == 0 { vec![vec![]] } else { words(m, len - 1).into_iter().flat_map(|w| (1..=m).map(move |v| [w.clone(), vec![v]].concat())).collect() } }
fn tableaux(lam: &[usize], all: Vec<Vec<usize>>, strict: bool) -> Vec<Tab> { all.iter().map(|p| fill(lam, p)).filter(|t| ok(t, strict)).collect() }
fn standard(lam: &[usize]) -> Vec<Tab> { tableaux(lam, perms(&(1..=lam.iter().sum()).collect::<Vec<usize>>()), true) }  // road two
fn schur(lam: &[usize], m: usize, strict: bool) -> BTreeMap<Vec<usize>, usize> {   // monomial -> count
    let mut p = BTreeMap::new();
    for t in tableaux(lam, words(m, lam.iter().sum()), strict) {
        *p.entry((1..=m).map(|v| t.concat().iter().filter(|&&x| x == v).count()).collect()).or_insert(0) += 1 }
    p }
fn walk(lam: &[usize], c: Cell, out: &mut BTreeMap<Cell, Frac>, w: Frac) {   // road three: the hook walk
    let step = hook_cells(lam, c);
    if step.is_empty() { let e = out.entry(c).or_insert((0, 1)); *e = add(*e, w); }
    for d in &step { walk(lam, *d, out, frac(w.0, w.1 * step.len() as u128)) } }
fn shapes(n: usize, top: usize) -> Vec<Vec<usize>> {
    if n == 0 { vec![vec![]] } else { (1..=top.min(n)).rev().flat_map(|a| shapes(n - a, a).into_iter().map(move |r| [vec![a], r].concat())).collect() } }
fn join<T: ToString>(v: &[T], sep: &str) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(sep) }
fn show(t: &Tab) -> String { format!("[{}]", t.iter().map(|r| join(r, " ")).collect::<Vec<_>>().join("/")) }
fn poly(p: &BTreeMap<Vec<usize>, usize>) -> String {
    p.iter().rev().map(|(e, &k)| format!("{}{}", if k > 1 { format!("{} ", k) } else { String::new() },
        join(&e.iter().enumerate().filter(|&(_, &x)| x > 0).map(|(v, &x)| if x > 1 { format!("x{}^{}", v + 1, x) } else { format!("x{}", v + 1) })
        .collect::<Vec<_>>(), " "))).collect::<Vec<_>>().join(" + ") }
fn main() {
    let (lam, n, h, h10, h23) = (vec![3, 2], 5u128, hooks(&[3, 2]), hooks(&[10, 10]), hooks(&[2, 3]).iter().product::<u128>());
    let (syt, ssyt) = (standard(&lam), tableaux(&[2, 1], words(2, 3), false)); let mut ends = BTreeMap::new();
    for c in cells(&lam) { walk(&lam, c, &mut ends, (1, n)) }
    let (a, b) = (standard(&[2, 2]).len() as u128, standard(&[3, 1]).len() as u128);
    let listed: Vec<u128> = shapes(5, 5).iter().map(|mu| standard(mu).len() as u128).collect();
    let hooked: Vec<u128> = shapes(5, 5).iter().map(|mu| by_hooks(mu)).collect();
    let (s21, s21x3, s32x5, s21s) = (schur(&[2, 1], 2, false), schur(&[2, 1], 3, false), schur(&lam, 5, false), schur(&[2, 1], 2, true));
    let symmetric = s21x3.iter().all(|(e, k)| perms(&[0, 1, 2]).iter().all(|s| s21x3[&s.iter().map(|&q| e[q]).collect::<Vec<_>>()] == *k));
    let legs: Vec<u128> = cells(&lam).iter().map(|&(r, j)| (r..2).filter(|&i| lam[i] > j).count() as u128).collect();
    let ballots: Vec<String> = syt.iter().map(|t| (1..=5).map(|v| if t[1].contains(&v) { 'N' } else { 'Y' }).collect()).collect();
    println!("shape (3, 2), n = {}; hook lengths by row: {:?} {:?}", n, &h[..3], &h[3..]);
    println!("hook formula: {}!/({}) = {}/{} = {}", n, join(&h, "*"), fact(n), h.iter().product::<u128>(), by_hooks(&lam));
    println!("standard tableaux by listing all {} fillings: {}\n  {}", fact(n), syt.len(), syt.iter().map(show).collect::<Vec<_>>().join("  "));
    println!("as ballot orders (row 1 = yes, row 2 = no): {}", ballots.join(" "));
    println!("reflection count: C(5,2) - C(5,1) = {} - {} = {}; corner recurrence, by listing: f(2, 2) + f(3, 1) = {} + {} = {}",
             choose(5, 2), choose(5, 1), choose(5, 2) - choose(5, 1), a, b, a + b);
    for ((c, p), (s, mu)) in ends.iter().zip([("(2, 2)", [2, 2]), ("(3, 1)", [3, 1])]) {
        let q = frac(by_hooks(&mu), by_hooks(&lam));
        println!("hook walk ends at corner ({},{}) with chance {}/{} = f{}/f(3, 2) = {}/{}", c.0 + 1, c.1 + 1, p.0, p.1, s, q.0, q.1);
        assert!(*p == q) }
    println!("all shapes of 5, listed: {:?}; by hooks: {:?}; squares add to {} = 5!", listed, hooked, listed.iter().map(|f| f * f).sum::<u128>());
    println!("rows lengthening downward, 2 over 3: {} fillings by listing, but hooks give {}/{} = {}/{}", perms(&[1, 2, 3, 4, 5]).iter().filter(|p| p[0] < p[1] && p[2] < p[3] && p[3] < p[4] && p[0] < p[2] && p[1] < p[3]).count(), fact(n), h23, frac(fact(n), h23).0, frac(fact(n), h23).1);
    println!("shape (10, 10): hook rows {}..{} and {}..{}; hooks give {}; reflection C(20,10) - C(20,9) = {} - {} = {}", h10[0], h10[9], h10[10], h10[19],
             by_hooks(&[10, 10]), choose(20, 10), choose(20, 9), choose(20, 10) - choose(20, 9));
    println!("semistandard (2, 1), entries 1..2: {}; s(2,1)(x1,x2) = {}", ssyt.iter().map(show).collect::<Vec<_>>().join(" "), poly(&s21));
    println!("s(2,1)(x1,x2,x3): {} tableaux, symmetric under every swap of variables: {}; x1 x2 x3 coefficient {} = f(2, 1)", s21x3.values().sum::<usize>(), if symmetric { "yes" } else { "no" }, s21x3[&vec![1, 1, 1]]);
    println!("s(3,2) in 5 variables: x1 x2 x3 x4 x5 coefficient {} = f(3, 2)", s32x5[&vec![1, 1, 1, 1, 1]]);
    println!("mistake 1, columns ignored: {}, not 5", perms(&[1, 2, 3, 4, 5]).iter().filter(|p| p[0] < p[1] && p[1] < p[2] && p[3] < p[4]).count());
    println!("mistake 2, hooks counting only cells below: {}/{} = {}, not 5", fact(n), legs.iter().product::<u128>(), fact(n) / legs.iter().product::<u128>());
    println!("mistake 3, rows strictly rising in a semistandard tableau: {} tableau, {}, not symmetric", s21s.values().sum::<usize>(), poly(&s21s));
    assert!(syt.len() as u128 == by_hooks(&lam) && by_hooks(&lam) == choose(5, 2) - choose(5, 1) && a + b == 5 && h == vec![4, 3, 1, 2, 1]);
    assert!(ends.values().fold((0, 1), |s, &p| add(s, p)) == (1, 1) && listed == hooked && listed.iter().map(|f| f * f).sum::<u128>() == fact(n));
    assert!(by_hooks(&[10, 10]) == choose(20, 10) - choose(20, 9) && symmetric && s21x3[&vec![1, 1, 1]] as u128 == by_hooks(&[2, 1]));
    assert!(s21.len() == 2 && s21[&vec![2, 1]] == 1 && s21[&vec![1, 2]] == 1 && s32x5[&vec![1, 1, 1, 1, 1]] == 5);
    println!("ALL CHECKS PASS");
}
