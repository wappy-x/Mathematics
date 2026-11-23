// Categories and functors -- the same check as the Python, in Rust.  No crates.
// Two finite categories are built and every law is tested on every arrow:
// SET, the sets {0}, {0,1}, {0,1,2} with every function between them, and GRP,
// four small groups with every homomorphism between them.  Then the flip-pattern
// functor F, from sets to groups, is built and its laws are tested on every pair.
// A function is a list: entry x is where x goes.  A group is its table: t[x][y].
type Fun = Vec<usize>;
type Tab = Vec<Vec<usize>>;

fn all_functions(a: usize, b: usize) -> Vec<Fun> {   // every list of a outputs, each below b
    let mut out: Vec<Fun> = vec![vec![]];
    for _ in 0..a {
        out = out.iter().flat_map(|f| (0..b).map(move |y| { let mut g = f.clone(); g.push(y); g })).collect();
    }
    out
}

fn compose(g: &Fun, f: &Fun) -> Fun { f.iter().map(|&x| g[x]).collect() }  // g after f
fn ident(n: usize) -> Fun { (0..n).collect() }

// hom[a][b] lists the arrows from object a to object b; size[a] counts a's members
fn check_category(size: &[usize], hom: &Vec<Vec<Vec<Fun>>>) -> (usize, usize, usize) {
    let (n, mut pairs, mut triples) = (size.len(), 0, 0);
    for a in 0..n { for b in 0..n { for f in &hom[a][b] {
        assert!(compose(&ident(size[b]), f) == *f && *f == compose(f, &ident(size[a])));
        for c in 0..n { for g in &hom[b][c] {
            let gf = compose(g, f);
            assert!(hom[a][c].contains(&gf));
            pairs += 1;
            for d in 0..n { for h in &hom[c][d] {
                assert!(compose(h, &gf) == compose(&compose(h, g), f));
                triples += 1;
            } }
        } }
    } } }
    let arrows = hom.iter().flatten().map(|v| v.len()).sum();
    (arrows, pairs, triples)
}

fn isos(size: &[usize], hom: &Vec<Vec<Vec<Fun>>>) -> Vec<(usize, usize)> {  // arrows undone by an arrow back
    let mut out = vec![];
    for a in 0..size.len() { for b in 0..size.len() { for f in &hom[a][b] {
        if hom[b][a].iter().any(|g| compose(g, f) == ident(size[a]) && compose(f, g) == ident(size[b])) {
            out.push((a, b));
        }
    } } }
    out
}

fn clock(n: usize) -> Tab { (0..n).map(|x| (0..n).map(|y| (x + y) % n).collect()).collect() }
// patterns of k switches, as bits; combining keeps a switch flipped in exactly one
fn flips(k: usize) -> Tab { (0..1 << k).map(|x| (0..1 << k).map(|y| x ^ y).collect()).collect() }

fn is_hom(f: &Fun, a: &Tab, b: &Tab) -> bool {
    (0..a.len()).all(|x| (0..a.len()).all(|y| f[a[x][y]] == b[f[x]][f[y]]))
}

fn times(b: &Tab, e: usize, m: usize) -> usize {      // e combined with itself m times
    let mut x = 0;
    for _ in 0..m { x = b[x][e] }
    x
}

fn formula(a: &str, b: &Tab) -> usize {              // a homomorphism is fixed by where generators go
    if a == "V" { return (0..b.len()).filter(|&e| b[e][e] == 0).count().pow(2) }
    let m: usize = a[1..].parse().unwrap();
    (0..b.len()).filter(|&e| times(b, e, m) == 0).count()
}

fn functor(f: &Fun, b: usize) -> Fun {               // F(f): flipped switches -> lamps that toggle
    (0..1usize << f.len()).map(|p| {
        let mut lamps = 0;
        for t in 0..b {
            let hits = (0..f.len()).filter(|&s| p >> s & 1 == 1 && f[s] == t).count();
            if hits % 2 == 1 { lamps |= 1 << t }
        }
        lamps
    }).collect()
}

fn image(f: &Fun, b: usize) -> Fun {                 // the tempting wrong rule: lamps touched at all
    (0..1usize << f.len()).map(|p| (0..b).filter(|&t| (0..f.len()).any(|s| p >> s & 1 == 1 && f[s] == t))
        .map(|t| 1 << t).sum()).collect()
}

fn show(p: usize, k: usize) -> String {
    let v: Vec<String> = (0..k).filter(|&s| p >> s & 1 == 1).map(|s| s.to_string()).collect();
    format!("{{{}}}", v.join(","))
}

fn table(m: &Fun, a: usize) -> String {
    (0..1 << a).map(|p| format!("{} -> {}", show(p, a), show(m[p], 2))).collect::<Vec<_>>().join(", ")
}

fn sorted(f: &Fun) -> Fun { let mut g = f.clone(); g.sort(); g }

fn main() {
    let s = [1usize, 2, 3];
    let hom_s: Vec<Vec<Vec<Fun>>> = s.iter().map(|&a| s.iter().map(|&b| all_functions(a, b)).collect()).collect();
    let sizes_s: Vec<Vec<usize>> = hom_s.iter().map(|r| r.iter().map(|v| v.len()).collect()).collect();
    let pow_s: Vec<Vec<usize>> = s.iter().map(|&a| s.iter().map(|&b| b.pow(a as u32)).collect()).collect();
    println!("SET objects: {{0}}, {{0,1}}, {{0,1,2}}; arrows: every function");
    println!("Hom sizes by search {:?}, by |B|^|A| {:?}", sizes_s, pow_s);
    let (n_s, p_s, t_s) = check_category(&s, &hom_s);
    println!("SET: {} arrows, identity laws on all {}, {} composable pairs closed, associativity on all {} triples", n_s, n_s, p_s, t_s);
    let iso_s = isos(&s, &hom_s);
    let fv = [1usize, 1 * 2, 1 * 2 * 3]; let fact: usize = fv.iter().sum();
    println!("SET isomorphisms by search: {}; bijections {} = {}", iso_s.len(), fv.map(|x| x.to_string()).join(" + "), fact);
    let names = ["C2", "C3", "C4", "V"];
    let g: Vec<Tab> = vec![clock(2), clock(3), clock(4), flips(2)];
    let size_g: Vec<usize> = g.iter().map(|t| t.len()).collect();
    let hom_g: Vec<Vec<Vec<Fun>>> = g.iter().map(|a| g.iter().map(|b|
        all_functions(a.len(), b.len()).into_iter().filter(|f| is_hom(f, a, b)).collect()).collect()).collect();
    let sizes_g: Vec<Vec<usize>> = hom_g.iter().map(|r| r.iter().map(|v| v.len()).collect()).collect();
    let form_g: Vec<Vec<usize>> = names.iter().map(|a| g.iter().map(|b| formula(a, b)).collect()).collect();
    println!("GRP objects: C2, C3, C4, V; arrows: every homomorphism");
    println!("Hom sizes by search {:?}, by generators {:?}", sizes_g, form_g);
    let (n_g, p_g, t_g) = check_category(&size_g, &hom_g);
    let rows_g: Vec<usize> = sizes_g.iter().map(|r| r.iter().sum()).collect();
    println!("GRP: {} arrows (rows {:?}), identity laws on all {}, {} composable pairs closed, associativity on all {} triples",
             n_g, rows_g, n_g, p_g, t_g);
    let iso_g = isos(&size_g, &hom_g);
    let bij_g = (0..4).flat_map(|a| (0..4).map(move |b| (a, b)))
        .map(|(a, b)| hom_g[a][b].iter().filter(|f| sorted(f) == ident(size_g[b])).count()).sum::<usize>();
    let per: Vec<String> = (0..4).map(|k| format!("{} {}", names[k], iso_g.iter().filter(|&&p| p == (k, k)).count())).collect();
    println!("GRP isomorphisms by search: {} ({}); between different groups {}; bijective homomorphisms {}",
             iso_g.len(), per.join(", "), iso_g.iter().filter(|p| p.0 != p.1).count(), bij_g);
    let (w, f, gg): (Fun, Fun, Fun) = (vec![0, 0], vec![0, 1, 0], vec![0, 0]);
    println!("stairs: w = {:?}; F(w): {}", w, table(&functor(&w, 1), 2));
    println!("landing: f = {:?}, g = {:?}", f, gg);
    let rows = [("F(f)", functor(&f, 2), 3), ("F(g)", functor(&gg, 1), 2), ("F(g o f)", functor(&compose(&gg, &f), 1), 3),
                ("F(g) o F(f)", compose(&functor(&gg, 1), &functor(&f, 2)), 3)];
    for (label, m, a) in rows.iter() { println!("{}: {}", label, table(m, *a)) }
    let (mut homs, mut comp, mut bad, mut inj, mut zero_c) = (0, 0, 0, 0, 0);
    for a in 0..3 { for b in 0..3 { for h in &hom_s[a][b] {
        if is_hom(&functor(h, s[b]), &flips(s[a]), &flips(s[b])) { homs += 1 }
        if !is_hom(&image(h, s[b]), &flips(s[a]), &flips(s[b])) { bad += 1 }
        if sorted(h).windows(2).all(|p| p[0] != p[1]) { inj += 1 }
        for c in 0..3 { for k in &hom_s[b][c] {
            if functor(&compose(k, h), s[c]) == compose(&functor(k, s[c]), &functor(h, s[b])) { comp += 1 }
            if vec![0; 1 << s[a]] == compose(&vec![0; 1 << s[b]], &vec![0; 1 << s[a]]) { zero_c += 1 }
        } }
    } } }
    let ids = s.iter().filter(|&&k| functor(&ident(k), k) == ident(1 << k)).count();
    println!("functor: F(f) a homomorphism for {} of {} functions; F(id) = id for {} of 3 sets; F(g o f) = F(g) o F(f) on {} of {} pairs",
             homs, n_s, ids, comp, p_s);
    let mut road2 = 0;
    for a in 0..2 { for b in 0..2 { for h in &hom_s[a][b] {     // search GRP's list; no parity counted
        let gi = |x: usize| if x == 0 { 0 } else { 3 };          // 1 switch -> C2, 2 switches -> V
        let found: Vec<&Fun> = hom_g[gi(a)][gi(b)].iter().filter(|m| (0..s[a]).all(|q| m[1 << q] == 1 << h[q])).collect();
        if found.len() == 1 && *found[0] == functor(h, s[b]) { road2 += 1 }
    } } }
    println!("second road: F(f) is the only homomorphism sending each single switch to its lamp, {} of 8 arrows", road2);
    let iso_f = (0..3).map(|a| hom_s[a][a].iter()
        .filter(|h| sorted(h) == ident(s[a]) && sorted(&functor(h, s[a])) == ident(1 << s[a])).count()).sum::<usize>();
    println!("bijections carried to isomorphisms: {} of {}", iso_f, iso_s.len());
    println!("mistake 1, lamps touched instead of parity: not a homomorphism for {} of {} functions, {} injective; stairs, both flipped: {}, not {}",
             bad, n_s, inj, show(image(&w, 1)[3], 1), show(functor(&w, 1)[3], 1));
    let zero_i = s.iter().filter(|&&k| vec![0; 1 << k] == ident(1 << k)).count();
    println!("mistake 2, every function sent to 'change nothing': composition on {} of {} pairs, identity on {} of 3", zero_c, p_s, zero_i);
    let bij = all_functions(4, 4).iter().filter(|h| sorted(h) == ident(4)).count();
    println!("mistake 3, all functions as arrows: C4 to V, {} bijections, {} group isomorphisms", bij,
             iso_g.iter().filter(|&&p| p == (2, 3)).count());
    assert!(sizes_s == pow_s && sizes_g == form_g);
    assert!(iso_s.len() == fact && iso_g.len() == bij_g && bij_g == 11);
    assert!(homs == n_s && comp == p_s);                        // F keeps every law
    assert!(ids == 3 && road2 == 8 && iso_f == iso_s.len());
    assert!(bad == n_s - inj && bij == 24);
    println!("ALL CHECKS PASS");
}
