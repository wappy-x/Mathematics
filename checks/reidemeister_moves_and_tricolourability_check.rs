// Reidemeister moves and the three-colour test -- the same check as the Python,
// in Rust.  No crates.  A diagram is a count of arcs and a list of crossings
// (over arc, under arc, under arc).  Colourings are counted two ways: every
// paint job tried, and 3 to the power (arcs - rank) by elimination mod 3.  The
// three moves are checked on every colouring of their loose ends, and the
// linking number is found two ways.
const P: i64 = 3; // number of colours: 0 red, 1 yellow, 2 blue
type Cr = Vec<(usize, usize, usize)>;
type Tangle = (usize, Cr, Vec<usize>);

fn paints(n: usize, p: i64) -> Vec<Vec<i64>> { // every way to give n arcs a colour 0..p-1
    let mut out: Vec<Vec<i64>> = vec![vec![]];
    for _ in 0..n {
        out = out.iter().flat_map(|c| (0..p).map(move |k| { let mut d = c.clone(); d.push(k); d })).collect();
    }
    out
}

fn legal(cr: &Cr, col: &[i64], p: i64, rule: &str) -> bool { // the crossing rule, and two broken ones
    match rule {
        "none" => true,
        "different" => cr.iter().all(|&(o, a, b)| col[o] != col[a] && col[a] != col[b] && col[o] != col[b]),
        _ => cr.iter().all(|&(o, a, b)| (2 * col[o] - col[a] - col[b]).rem_euclid(p) == 0),
    }
}

fn brute(n: usize, cr: &Cr, p: i64, rule: &str) -> i64 { // road one: try every paint job
    paints(n, p).iter().filter(|c| legal(cr, c, p, rule)).count() as i64
}

fn by_rank(n: usize, cr: &Cr, p: i64) -> (i64, usize) { // road two: p ** (arcs - rank mod p)
    let mut rows: Vec<Vec<i64>> = cr.iter().map(|&(o, a, b)| {
        let mut r = vec![0i64; n];
        r[o] += 2; r[a] -= 1; r[b] -= 1;
        r.iter().map(|x| x.rem_euclid(p)).collect()
    }).collect();
    let mut rank = 0;
    for col in 0..n {
        let piv = match (rank..rows.len()).find(|&i| rows[i][col] != 0) { Some(i) => i, None => continue };
        rows.swap(rank, piv);
        let mut inv = 1;
        for _ in 0..p - 2 { inv = inv * rows[rank][col] % p }
        rows[rank] = rows[rank].iter().map(|x| x * inv % p).collect();
        for i in 0..rows.len() {
            if i != rank && rows[i][col] != 0 {
                let f = rows[i][col];
                let piv_row = rows[rank].clone();
                rows[i] = rows[i].iter().zip(&piv_row).map(|(x, y)| (x - f * y).rem_euclid(p)).collect();
            }
        }
        rank += 1;
    }
    (p.pow((n - rank) as u32), rank)
}

fn inside(t: &Tangle, fixed: &[i64], rule: &str) -> i64 { // colourings of a move's inside, ends fixed
    paints(t.0, P).iter().filter(|c| legal(&t.1, c, P, rule) && t.2.iter().map(|&e| c[e]).collect::<Vec<i64>>() == fixed).count() as i64
}

fn same_inside(before: &Tangle, after: &Tangle, rule: &str) -> bool { // equal on every colouring of the ends
    paints(before.2.len(), P).iter().all(|f| inside(before, f, rule) == inside(after, f, rule))
}

fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

struct Half(i64); // an exact half, printed like Python's Fraction
impl std::fmt::Display for Half {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        if self.0 % 2 == 0 { write!(f, "{}", self.0 / 2) } else { write!(f, "{}/2", self.0) }
    }
}

fn lk_twice(cr: &[(u8, u8, i64)]) -> i64 { cr.iter().filter(|c| c.0 != c.1).map(|c| c.2).sum() } // road one, doubled
fn lk_over(cr: &[(u8, u8, i64)]) -> i64 { cr.iter().filter(|c| (c.0, c.1) == (0, 1)).map(|c| c.2).sum() } // road two

fn main() {
    let d: Vec<(&str, usize, Cr)> = vec![
        ("circle", 1, vec![]), ("circle + R1 kink", 1, vec![(0, 0, 0)]),
        ("circle + R2 poke", 2, vec![(0, 0, 1), (0, 1, 0)]),
        ("trefoil", 3, vec![(0, 1, 2), (1, 2, 0), (2, 0, 1)]),
        ("trefoil + R1 kink", 4, vec![(0, 1, 2), (1, 2, 0), (2, 3, 1), (3, 0, 3)]),
        ("figure-eight", 4, vec![(0, 1, 2), (2, 3, 0), (1, 2, 3), (3, 0, 1)]),
        ("two-circle unlink", 2, vec![]), ("Hopf link", 2, vec![(0, 1, 1), (1, 0, 0)])];
    let mut counts = std::collections::BTreeMap::new();
    for (name, n, cr) in &d {
        let (t, rank) = by_rank(*n, cr, P);
        let b = brute(*n, cr, P, "mod");
        counts.insert(*name, b);
        println!("{}: arcs {}, crossings {}, rank {}; colourings by brute force {}, by 3^(arcs - rank) {}", name, n, cr.len(), rank, b, t);
        assert!(b == t); // two roads agree
    }
    let r1a: Tangle = (2, vec![(0, 0, 1)], vec![0, 1]);
    let r1_before: Tangle = (1, vec![], vec![0, 0]);
    let moves: Vec<(&str, Tangle, Tangle)> = vec![
        ("R1 kink, over first", r1_before.clone(), r1a.clone()),
        ("R1 kink, under first", r1_before.clone(), (2, vec![(1, 0, 1)], vec![0, 1])),
        ("R2 poke", (2, vec![], vec![0, 0, 1, 1]), (4, vec![(0, 1, 2), (0, 2, 3)], vec![0, 0, 1, 3])),
        ("R3 slide", (6, vec![(1, 3, 4), (0, 4, 5), (0, 1, 2)], vec![0, 0, 1, 2, 3, 5]),
                     (6, vec![(0, 1, 2), (0, 3, 4), (2, 4, 5)], vec![0, 0, 1, 2, 3, 5]))];
    for (name, bef, aft) in &moves {
        let ok = same_inside(bef, aft, "mod");
        println!("{}: inside counts agree on all {} colourings of the ends: {}", name, P.pow(bef.2.len() as u32), yn(ok));
        assert!(ok); // exhaustive: a proof for 3 colours
    }
    let (u, m, t) = (1i64, 2i64, 0i64); // R3 worked: x under y comes out 2y - x
    let b2 = (2 * m - u).rem_euclid(P); let b3 = (2 * t - b2).rem_euclid(P);
    let m2 = (2 * t - m).rem_euclid(P); let a2 = (2 * t - u).rem_euclid(P); let a3 = (2 * m2 - a2).rem_euclid(P);
    println!("R3 worked, u, m, t = {}, {}, {}: before u -> {} -> {}; after m -> {}, u -> {} -> {}", u, m, t, b2, b3, m2, a2, a3);
    assert!(b3 == a3 && a3 == (2 * t - 2 * m + u).rem_euclid(P));
    println!("trefoil one-colour 3 + all-different 6 = {}; unknot {}", counts["trefoil"], counts["circle"]);
    assert!(counts["trefoil"] == 3 + 6 && counts["trefoil"] != counts["circle"]);

    let hopf: Vec<(u8, u8, i64)> = vec![(0, 1, 1), (1, 0, 1)];
    let cat = |extra: &[(u8, u8, i64)]| { let mut v = hopf.clone(); v.extend_from_slice(extra); v };
    let links: Vec<(&str, Vec<(u8, u8, i64)>)> = vec![("unlink", vec![]), ("Hopf link", hopf.clone()),
        ("Hopf + R1 kink", cat(&[(0, 0, 1)])), ("Hopf + R2 poke", cat(&[(0, 1, 1), (0, 1, -1)])),
        ("Solomon link", cat(&hopf))];
    for (name, cr) in &links {
        println!("linking number of {}: half-sum {}, K1-over sum {}", name, Half(lk_twice(cr)), lk_over(cr));
        assert!(lk_twice(cr) == 2 * lk_over(cr)); // two roads agree
    }
    assert!(lk_twice(&links[2].1) == 2 && lk_twice(&links[3].1) == 2);

    let get = |k: &str| d.iter().find(|x| x.0 == k).unwrap();
    let (tre, tk, ci, ck) = (get("trefoil"), get("trefoil + R1 kink"), get("circle"), get("circle + R1 kink"));
    println!("mistake 1, no rule: trefoil {}, after a kink {}; R1 inside agrees: {}", brute(tre.1, &tre.2, P, "none"),
             brute(tk.1, &tk.2, P, "none"), yn(same_inside(&r1_before, &r1a, "none")));
    println!("mistake 2, all different required: circle {}, after a kink {}", brute(ci.1, &ci.2, P, "different"),
             brute(ck.1, &ck.2, P, "different"));
    println!("mistake 3, two colours: trefoil {}, circle {}", brute(tre.1, &tre.2, 2, "mod"), brute(ci.1, &ci.2, 2, "mod"));
    let all_signs: i64 = links[2].1.iter().map(|c| c.2).sum();
    println!("mistake 4, self-crossing counted: Hopf + R1 kink gives {}", Half(all_signs));
    assert!(brute(tk.1, &tk.2, P, "none") == 81 && brute(ck.1, &ck.2, P, "different") == 0);
    let c = -0.25f64; // figure: cos t = -1/4, so y = c - 2(2c^2 - 1) = 3/2
    let y2 = 2.0 * (c - 2.0 * (2.0 * c * c - 1.0)); // twice y, an exact 3
    let (y, h) = (y2 / 2.0, 3.0 * 15f64.sqrt() / 16.0);
    println!("figure, trefoil crossings at (0, {}/2), ({:.3}, {:.3}), ({:.3}, {:.3}); strand heights +{:.3} and -{:.3}",
             y2, y * 3f64.sqrt() / 2.0, -y / 2.0, -y * 3f64.sqrt() / 2.0, -y / 2.0, h, h);
    println!("ALL CHECKS PASS");
}
