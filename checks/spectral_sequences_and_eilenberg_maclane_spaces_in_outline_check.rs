// Spectral sequences in outline -- the same check as the Python, in Rust.  No crates.
// Page arithmetic only: entries of a page are groups Z, Z/n or 0 (or ranks over Q), and a
// differential d_r kills what it maps one for one.  Every list stops at degree N = 8.
const N: usize = 8;

fn cyc(m: i64) -> String {                    // the group Z/m, with Z/0 = Z and Z/1 = 0
    match m.abs() { 0 => "Z".to_string(), 1 => "0".to_string(), a => format!("Z/{}", a) }
}

fn rk(g: &str) -> i64 { if g == "Z" { 1 } else { 0 } }   // rank over Q: only Z survives

// Part 1. Circle bundles over S^2, Euler number c (n here).  Cells e0, e1 over the base point,
// e2, e3 over the rest; the one coboundary that jumps columns is delta(e1) = n e2.
type Page = Vec<((usize, usize), String)>;

fn by_page(n: i64) -> (Vec<String>, Page, Page) {  // road one: E2 page, then d2 = n
    let e2: Page = vec![((0, 0), "Z".into()), ((0, 1), "Z".into()), ((2, 0), "Z".into()), ((2, 1), "Z".into())];
    let mut einf = e2.clone();
    einf[1].1 = if n == 0 { "Z".into() } else { "0".into() };  // kernel of d2 out of (0,1)
    einf[2].1 = cyc(n);                                         // cokernel of d2 into (2,0)
    let h = (0..4).map(|k| einf.iter().find(|((p, q), _)| p + q == k)
        .map(|(_, g)| g.clone()).unwrap_or("0".into())).collect();
    (h, e2, einf)
}

fn by_cochains(n: i64) -> Vec<String> {      // road two: the whole cochain complex, no pages
    let delta = [0, n, 0];                    // C^0 -> C^1 -> C^2 -> C^3, each a copy of Z
    (0..4).map(|k| {
        let d_out = if k < 3 { delta[k] } else { 0 };
        let d_in = if k > 0 { delta[k - 1] } else { 0 };
        if d_out != 0 { "0".to_string() } else { cyc(d_in) }
    }).collect()
}

fn chi(page: &Page) -> i64 {                  // Euler characteristic of a page, ranks over Q
    page.iter().map(|((p, q), g)| if (p + q) % 2 == 0 { rk(g) } else { -rk(g) }).sum()
}

fn ranks(h: &[String]) -> Vec<i64> { h.iter().map(|g| rk(g)).collect() }

// Part 2. Pages that must end empty: see the Python for the two rules.
fn survives(s: &[i64], gap: usize) -> bool {
    let out = (1..=N).all(|k| s[k] <= if k >= gap { s[k - gap] } else { 0 });
    let hit = (0..=N - gap).all(|k| s[k] <= s[k + gap]);
    out && hit
}

fn rows_survive(b: &[i64], gap: usize) -> bool {   // K(Z,2): rows q = 0 and 1, both copies of b
    let row1 = (0..=N - gap).all(|p| b[p] <= b[p + gap]);                       // (p,1) goes out
    let row0 = (1..=N).all(|p| b[p] <= if p >= gap { b[p - gap] } else { 0 });  // (p,0) is hit
    row1 && row0
}

// Columns 0 and 3 both hold s; one differential d_r.  See the Python for the rule.
fn emptied_by(s: &[i64], r: usize) -> bool {
    let (r, n, col) = (r as i64, N as i64, |p: i64| p == 0 || p == 3);
    for p in [0i64, 3] {
        for q in (if p == 0 { 1 } else { 0 })..=n {
            let v = s[q as usize];
            let out = col(p + r) && q - r + 1 >= 0 && v <= s[(q - r + 1) as usize];
            let hit = col(p - r) && (q + r - 1 > n || v <= s[(q + r - 1) as usize]);
            if v != 0 && !(out || hit) { return false; }
        }
    }
    true
}

fn by_recursion(gap: usize) -> Vec<i64> {    // road one: solve the page degree by degree
    let mut s = vec![1];
    for k in 1..=N { let v = if k >= gap { s[k - gap] } else { 0 }; s.push(v); }
    s
}

fn by_search(gap: usize, rule: fn(&[i64], usize) -> bool) -> Vec<Vec<i64>> {  // road two
    let mut found = Vec::new();
    for code in 0..3usize.pow(N as u32) {     // every list of ranks 0, 1, 2, in Python's order
        let mut s = vec![1i64];
        for i in (0..N).rev() { s.push(((code / 3usize.pow(i as u32)) % 3) as i64); }
        if rule(&s, gap) { found.push(s); }
    }
    found
}

fn main() {
    let names = ["S2 x S1", "S3, Hopf", "RP3, rotations", "lens space L(3,1)"];
    println!("Circle bundles over S2, Euler number c: cohomology H0..H3 over Z");
    for n in 0..4i64 {
        let (h, e2, einf) = by_page(n);
        let c = by_cochains(n);
        assert!(h == c);
        assert!(chi(&e2) == chi(&einf) && chi(&einf) == 2 * 0);   // chi(base) x chi(fibre)
        println!("  c = {}  {:<18} page {:<13} cochains {:<13} ranks over Q {:?}  chi E2 {}, E-infinity {}",
                 n, names[n as usize], h.join(", "), c.join(", "), ranks(&h), chi(&e2), chi(&einf));
    }
    for m in 2..=4 { println!("Loop space of S{}: ranks of H0..H{} = {:?}", m, N, by_recursion(m - 1)); }
    let lp = by_search(2, survives);
    println!("Loop space of S3, exhaustive: {} lists tried, {} survives: {:?}", 3usize.pow(N as u32), lp.len(), lp[0]);
    for q in (2..7).step_by(2) { println!("  d3 : E3(0,{}) = Z  ->  E3(3,{}) = Z, one for one", q, q - 2); }
    let kz2 = by_search(2, rows_survive);
    let cells: Vec<i64> = (0..=N).map(|p| if p % 2 == 0 { 1 } else { 0 }).collect();
    println!("K(Z,2) from fibre S1, exhaustive: {} survives: {:?}; cells of CP-infinity {:?}", kz2.len(), kz2[0], cells);
    assert!(lp == vec![by_recursion(2)] && kz2 == vec![cells]);
    assert!(by_recursion(1) == vec![1; N + 1] && by_recursion(3) == vec![1, 0, 0, 1, 0, 0, 1, 0, 0]);

    // What breaks.  Stop at E2: both columns keep the true list, and each diagonal is read as an answer.
    let e2_loop: Vec<i64> = (0..=N).map(|k| lp[0][k] + if k >= 3 { lp[0][k - 3] } else { 0 }).collect();
    println!("Stop at E2 for the loop space: E2(3,0) = Z stays; the point PS3 would get ranks {:?} in H0..H{}", e2_loop, N);
    let (by_d3, by_d2) = (by_search(3, emptied_by), by_search(2, emptied_by));
    println!("One differential on columns 0 and 3, every rank list: emptied by d3: {}, {:?}; by d2: {}",
             by_d3.len(), by_d3[0], by_d2.len());
    let (h1, e2_hopf, _) = by_page(1);
    let naive: Vec<i64> = (0..4).map(|k| e2_hopf.iter().filter(|((p, q), _)| p + q == k).map(|(_, g)| rk(g)).sum()).collect();
    println!("Stop at E2 for the Hopf bundle: H0..H3 ranks {:?}, true {:?}", naive, ranks(&h1));
    let rank1 = |col: &[i64], m: i64| -> i64 { if col.iter().any(|&x| (if m != 0 { x % m } else { x }) != 0) { 1 } else { 0 } };
    let bd2 = [2i64, 0];                      // Klein bottle: cell c has boundary 2a + 0b; bd1 = 0
    let klein_q = vec![1, 2 - rank1(&bd2, 0), 1 - rank1(&bd2, 0)];
    let klein_2 = vec![1, 2 - rank1(&bd2, 2), 1 - rank1(&bd2, 2)];
    let untwisted = vec![1i64, 2, 1];         // H(S1) x H(S1), as if the fibre were never flipped
    println!("Klein bottle as a circle over a circle: untwisted page {:?}, true over Q {:?}, true mod 2 {:?}",
             untwisted, klein_q, klein_2);
    let (h2, _, _) = by_page(2);
    println!("RP3 over Q {:?}, the same as S3; over Z H2 = {}", ranks(&h2), h2[2]);
    assert!(by_d3 == lp && by_d2.is_empty() && e2_loop == vec![1, 0, 1, 1, 1, 1, 1, 1, 1]);
    assert!(naive == vec![1, 1, 1, 1] && klein_q == vec![1, 1, 0] && klein_2 == untwisted);
    assert!(h2[2] == "Z/2" && ranks(&h2) == ranks(&h1));
    println!("ALL CHECKS PASS");
}
