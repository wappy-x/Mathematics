// Prize citations -- the check behind the card.  std only, no crates.
// Sort a citation's phrases, match results to papers, apply the status rule, compute small cases.
const R: &str = "result"; const K: &str = "reproof"; const T: &str = "tool"; const F: &str = "field";
type Cit = (&'static str, &'static [(&'static str, &'static str)]);
const CITATIONS: [Cit; 8] = [  // (citation, [(phrase, type read by hand)])
    ("Abel 2026 Faltings, short", &[("introducing powerful tools in arithmetic geometry", T),
        ("resolving long-standing diophantine conjectures of Mordell", R),
        ("resolving long-standing diophantine conjectures of ... Lang", R)]),
    ("Abel 2026 Faltings, long", &[("the Mordell conjecture ... proved by Faltings in 1983", R),
        ("resolving an important case of a conjecture of John Tate", R),
        ("resolving ... a conjecture of Igor Shafarevich", R),
        ("adapted this approach to prove ... the Mordell-Lang conjecture", R),
        ("also proved the finiteness of integral points on affine subvarieties of abelian varieties", R),
        ("gave a new proof of Roth's theorem and ... the Schmidt subspace theorem", K),
        ("major contributions to p-adic Hodge theory", F), ("tools introduced by Faltings ... the purity theorem", T),
        ("giving proofs of the main conjectures formulated by Tate and ... Fontaine", R),
        ("constructed an arithmetic compactification of these varieties", T)]),
    ("Fields 2022 Huh, short", &[("bringing the ideas of Hodge theory to combinatorics", F),
        ("the proof of the Dowling-Wilson conjecture for geometric lattices", R),
        ("the proof of the Heron-Rota-Welsh conjecture for matroids", R),
        ("the development of the theory of Lorentzian polynomials", T),
        ("the proof of the strong Mason conjecture", R)]),
    ("Abel 2024 Talagrand, short", &[("groundbreaking contributions to probability theory and functional analysis", F),
        ("outstanding applications in mathematical physics and statistics", F)]),
    ("Abel 2025 Kashiwara, short", &[("fundamental contributions to algebraic analysis and representation theory", F),
        ("the development of the theory of D-modules", T), ("the discovery of crystal graphs", T)]),
    ("Breakthrough 2025 Gaitsgory", &[("breakthrough contributions to the geometric Langlands program", F),
        ("the development of the derived algebraic geometry approach", T),
        ("the proof of the geometric Langlands conjecture in characteristic 0", R)]),
    ("Fields 2026 Wang, short", &[("her work in harmonic analysis and geometric measure theory", F),
        ("applications of multiscale and decoupling techniques to the local smoothing conjecture", F),
        ("major advances in ... the Kakeya problem in three dimensions", F)]),
    ("Fields 2026 Wang, long", &[("decoupling and multiscale arguments to resolve the local smoothing conjecture", R),
        ("fundamental progress in Fourier restriction theory", F), ("obtained major results on the Falconer distance set problem", F),
        ("breakthrough contributions to the theory of Furstenberg sets", F), ("major advances on the Kakeya problem in three dimensions", F),
        ("developed new bounds and structural techniques for collections of thin tubes", T)]),
];
fn scan(phrase: &str) -> &'static str {  // road two: the reading rule as keywords
    let p = phrase.to_lowercase();
    if p.contains("new proof") { return K; }
    if ["proof of", "proofs of", "prove", "resolv"].iter().any(|w| p.contains(w)) { return R; }
    if ["develop", "introduc", "discover", "construct"].iter().any(|w| p.contains(w)) { return T; }
    F
}
const RESULTS: [(&str, Option<&str>, Option<&str>); 13] = [  // (result as matched to its paper, refereed, citation)
    ("Mordell: genus >= 2, finitely many points", Some("1983-10"), Some("2026-03-19")),
    ("Tate, maps of abelian varieties only", Some("1983-10"), Some("2026-03-19")),
    ("Shafarevich, abelian varieties", Some("1983-10"), Some("2026-03-19")),
    ("Mordell-Lang, general case (1994 paper)", Some("1994"), Some("2026-03-19")),
    ("Lang, integral points (1991 paper)", Some("1991-05"), Some("2026-03-19")),
    ("Tate-Fontaine, no single paper", None, None),
    ("Dowling-Wilson, realizable matroids", Some("2017"), Some("2022-07-05")),
    ("Dowling-Wilson, all geometric lattices", Some("2026-07-01"), Some("2022-07-05")),  // the short sentence's scope
    ("Heron-Rota-Welsh, matroids", Some("2018-09"), Some("2022-07-05")), ("strong Mason", Some("2020-11"), Some("2022-07-05")),
    ("geometric Langlands, characteristic 0", None, Some("2025-04-05")),
    ("local smoothing, planar wave", Some("2020-09"), Some("2026-07-23")),
    ("Kakeya, three dimensions", Some("2026-11-06"), None),
];
// the status rule: the earliest acceptance
fn accepted(r: Option<&'static str>, p: Option<&'static str>) -> Option<&'static str> { [r, p].into_iter().flatten().min() }
fn days_civil(y: i64, m: i64, d: i64) -> i64 {  // road one: days since 1970-01-01, by formula
    let y = if m <= 2 { y - 1 } else { y };
    let era = y.div_euclid(400); let yoe = y - era * 400;
    let doy = (153 * (m + if m > 2 { -3 } else { 9 }) + 2) / 5 + d - 1;
    era * 146097 + yoe * 365 + yoe / 4 - yoe / 100 + doy - 719468
}
fn days_table(m1: usize, d1: i64, m2: usize, d2: i64) -> i64 {  // road two: month lengths of 2026
    [31i64, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][m1 - 1..m2 - 1].iter().sum::<i64>() - d1 + d2
}
fn genus_formula(n: i64) -> i64 { (n - 1) * (n - 2) / 2 }
fn interior(a: i64, b: i64) -> i64 {     // lattice points strictly inside the triangle (0,0),(a,0),(0,b)
    (1..a).map(|i| (1..b).filter(|j| b * i + a * j < a * b).count() as i64).sum()
}
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn isqrt(n: i128) -> i128 {
    if n < 2 { return n; }
    let mut x = (n as f64).sqrt() as i128;
    while x * x > n { x -= 1; }
    while (x + 1) * (x + 1) <= n { x += 1; }
    x
}
const HMAX: i128 = 1000;                 // height: larger of the numerator and denominator of x
fn elliptic_search() -> Vec<i128> {      // road one: y^2 = x^3 - x + 1, x = a/e^2, y = b/e^3
    let mut pts = vec![];
    for e in 1..=isqrt(HMAX) { for a in -HMAX..=HMAX {
        let r = a * a * a - a * e.pow(4) + e.pow(6);
        if gcd(a, e) == 1 && r >= 0 && isqrt(r).pow(2) == r {
            for _ in 0..(if r != 0 { 2 } else { 1 }) { pts.push(a.abs().max(e * e)); }
        }
    } }
    pts
}
type Q = (i128, i128);
fn q(n: i128, d: i128) -> Q {            // an exact fraction n/d, in lowest terms
    let g = gcd(n, d) * if d > 0 { 1 } else { -1 }; (n / g, d / g)
}
fn sub(a: Q, b: Q) -> Q { q(a.0 * b.1 - b.0 * a.1, a.1 * b.1) }
fn mul(a: Q, b: Q) -> Q { q(a.0 * b.0, a.1 * b.1) }
fn div(a: Q, b: Q) -> Q { q(a.0 * b.1, a.1 * b.0) }
fn multiples(k_max: usize) -> Vec<i128> {  // road two: kP by the chord rule, P = (1, 1)
    let one = (1, 1); let (mut x, mut y, mut hs): (Q, Q, Vec<i128>) = ((-1, 1), (1, 1), vec![1, 1]);
    for _ in 3..=k_max {                 // (k+1)P = kP + P, through the chord
        let m = div(sub(y, one), sub(x, one));
        let x3 = sub(sub(mul(m, m), x), one);
        y = sub(mul(m, sub(one, x3)), one); x = x3;
        hs.push(x.0.abs().max(x.1));
    }
    hs
}
fn quartic_search() -> Vec<i128> {       // x^4 + y^4 = 1 with x = a/c, y = b/c: a^4 + b^4 = c^4
    let mut pts = vec![];
    for c in 1..=HMAX { for a in 0..=c {
        let r = c.pow(4) - a.pow(4); let b = isqrt(isqrt(r));
        if b.pow(4) == r && gcd(gcd(a, b), c) == 1 {
            for _ in 0..(if a != 0 { 2 } else { 1 }) * (if b != 0 { 2 } else { 1 }) { pts.push(c); }
        }
    } }
    pts
}
fn main() {
    println!("phrases by type: result, reproof, tool or theory, field or progress");
    let counts: Vec<Vec<usize>> = CITATIONS.iter().map(|(_, ph)|
        [R, K, T, F].iter().map(|k| ph.iter().filter(|(_, t)| t == k).count()).collect()).collect();
    for (i, (cit, _)) in CITATIONS.iter().enumerate() {
        println!("  {:<30}{}", cit, counts[i].iter().map(|c| format!("{:>4}", c)).collect::<String>());
    }
    let agree = CITATIONS.iter().flat_map(|(_, ph)| ph.iter()).filter(|(x, t)| scan(x) == *t).count();
    let total: usize = CITATIONS.iter().map(|(_, ph)| ph.len()).sum();
    println!("hand reading = keyword scan: {} of {} phrases", agree, total);
    println!("outside them, a refutation: 'answered ... in the negative' scans as {}", scan("he answered a longstanding question ... in the negative"));
    println!("results matched to papers; status rule applied 2026-11-24");
    println!("  {:<42}{:<11}{:<12}{:<12}by", "result", "refereed", "citation", "accepted");
    let mut by_prize = vec![];
    for (name, r, p) in RESULTS.iter() {
        let acc = accepted(*r, *p);
        let who = if acc.is_none() { "not set here" } else if acc == *p && acc != *r { "citation" } else { "paper" };
        if who == "citation" { by_prize.push(*name); }
        println!("  {:<42}{:<11}{:<12}{:<12}{}", name, r.unwrap_or("-"), p.unwrap_or("-"), acc.unwrap_or("-"), who);
    }
    println!("accepted by the citation itself: {} ({})", by_prize.len(), by_prize.join("; "));
    let (d_formula, d_table) = (days_civil(2026, 11, 6) - days_civil(2026, 7, 23), days_table(7, 23, 11, 6));
    println!("Kakeya read off the citation: 2026-07-23, refereed proof 2026-11-06: {} days early (formula), {} (month table)", d_formula, d_table);
    println!("genus of x^n + y^n = 1 by formula / by interior points: {}",
        (3..7).map(|n| format!("n={} {}/{}", n, genus_formula(n), interior(n, n))).collect::<Vec<_>>().join(", "));
    println!("genus of y^2 = x^3 - x + 1 by interior points: {}", interior(3, 2));
    let hs = multiples(16);
    println!("heights of kP, k = 1..16: {}", hs.iter().map(|h| h.to_string()).collect::<Vec<_>>().join(" "));
    let (ell, quart, hb) = (elliptic_search(), quartic_search(), [10i128, 100, 1000]);
    let cnt = |v: &Vec<i128>, h: i128, w: usize| w * v.iter().filter(|&&x| x <= h).count();
    let row_s: Vec<usize> = hb.iter().map(|&h| cnt(&ell, h, 1)).collect();
    let row_m: Vec<usize> = hb.iter().map(|&h| cnt(&hs, h, 2)).collect();
    let row_q: Vec<usize> = hb.iter().map(|&h| cnt(&quart, h, 1)).collect();
    let fmt = |v: &Vec<usize>| v.iter().map(|c| format!("{:>6}", c)).collect::<String>();
    println!("rational points with height <= H:        H=10  H=100  H=1000");
    println!("  y^2 = x^3 - x + 1, genus 1, by search  {}", fmt(&row_s));
    println!("  y^2 = x^3 - x + 1, as +-kP             {}", fmt(&row_m));
    println!("  x^4 + y^4 = 1, genus 3, by search      {}", fmt(&row_q));
    println!("results named per citation (# = one):");
    for i in [1usize, 2, 5, 7, 3, 4] {
        println!("  {:<30}{:<7}{}", CITATIONS[i].0, "#".repeat(counts[i][0]), counts[i][0]);
    }
    assert!(agree == total && total == 35);                  // two readings of every phrase agree
    assert!(counts[0][0] == 2 && counts[1][0] == 6);
    assert!(by_prize == vec!["Dowling-Wilson, all geometric lattices", "geometric Langlands, characteristic 0"]);  // set by a prize
    assert!(d_formula == 106 && d_table == 106);             // two calendars, one gap
    assert!((3..7).all(|n| genus_formula(n) == interior(n, n)) && interior(3, 2) == 1);
    assert!(row_s == row_m && row_s == vec![12, 18, 24]);    // search and chord rule agree, no end
    assert!(row_q == vec![4, 4, 4]);                         // genus 3: (+-1, 0), (0, +-1) only, checked for H <= 1000
    println!("ALL CHECKS PASS");
}
