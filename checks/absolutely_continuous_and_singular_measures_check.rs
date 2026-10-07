// Absolutely continuous and singular measures -- the same check in Rust, std
// only.  Die weights are whole numbers of sixtieths, so every set's size is
// exact.  Every one of the 64 sets of faces is tested against the definitions
// and, by a second road, against the faces that carry weight.  Then the
// epsilon-delta form, a density on the line by two integrals, Cantor stages.
const NAMES: [&str; 5] = ["P", "Q", "R", "T", "D"];
const DICE: [[i64; 6]; 5] = [[10, 10, 10, 10, 10, 10], [6, 6, 6, 6, 12, 24],
    [12, 12, 12, 12, 12, 0], [0, 12, 12, 12, 12, 12], [0, 0, 0, 0, 0, 60]];

fn size(w: &[i64; 6], a: usize) -> i64 { (0..6).filter(|k| a >> k & 1 == 1).map(|k| w[k]).sum() }
fn ac(nu: &[i64; 6], mu: &[i64; 6]) -> bool {       // road one: mu-null sets are nu-null
    (0..64).all(|a| size(mu, a) != 0 || size(nu, a) == 0)
}
fn sing(nu: &[i64; 6], mu: &[i64; 6]) -> bool {     // road one: a separating set S
    (0..64).any(|s| size(mu, 63 ^ s) == 0 && size(nu, s) == 0)
}
fn faces(w: &[i64; 6]) -> u32 { (0..6).filter(|&k| w[k] > 0).fold(0, |m, k| m | 1 << k) }
fn verdict(i: usize, j: usize) -> String {
    let (x, y, a, b) = (&DICE[i], &DICE[j], NAMES[i], NAMES[j]);
    if sing(x, y) { return "mutually singular".to_string() }
    match (ac(x, y), ac(y, x)) {
        (true, true) => "equivalent".to_string(),
        (true, false) => format!("{} << {} only", a, b),
        (false, true) => format!("{} << {} only", b, a),
        _ => "neither".to_string(),
    }
}
fn ex(x: f64) -> f64 {                              // e^x by its series, written out here
    let (mut total, mut term) = (0.0, 1.0);
    for k in 1..40 { total += term; term = term * x / k as f64; }
    total
}
fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64, m: usize) -> f64 {
    let h = (b - a) / m as f64;
    let s = (0..=m).fold(0.0, |s, j| s + (if j == 0 || j == m { 1.0 } else if j % 2 == 1 { 4.0 } else { 2.0 }) * g(a + j as f64 * h));
    h / 3.0 * s
}
fn overlap(a: f64, b: f64) -> f64 { (b.min(1.0) - a.max(0.0)).max(0.0) }

fn main() {
    println!("face weights, faces 1 to 6; faces with weight; count of null sets out of 64");
    for (n, w) in NAMES.iter().zip(DICE.iter()) {
        let ws: Vec<String> = w.iter().map(|&p| format!("{:.4}", p as f64 / 60.0)).collect();
        let fs: Vec<String> = (0..6).filter(|&k| w[k] > 0).map(|k| (k + 1).to_string()).collect();
        let nulls = (0..64).filter(|&a| size(w, a) == 0).count();
        println!("{}: {}; [{}]; {}", n, ws.join(" "), fs.join(", "), nulls);
    }
    let (mut agree, mut table) = (true, Vec::new());
    for i in 0..5 {
        for j in i + 1..5 {
            let (x, y, fx, fy) = (&DICE[i], &DICE[j], faces(&DICE[i]), faces(&DICE[j]));
            agree &= ac(x, y) == (fx & !fy == 0) && ac(y, x) == (fy & !fx == 0);
            agree &= sing(x, y) == (fx & fy == 0);
            table.push(verdict(i, j));
            println!("{} and {}: {}", NAMES[i], NAMES[j], table.last().unwrap());
        }
    }
    println!("definition over 64 sets agrees with the face comparison: {}", if agree { "yes" } else { "no" });
    let f: Vec<f64> = (0..6).map(|k| DICE[1][k] as f64 / DICE[0][k] as f64).collect();
    let fs: Vec<String> = f.iter().map(|v| format!("{:.2}", v)).collect();
    println!("density of Q against P: {}", fs.join(" "));
    println!("Q(5 or 6) as the integral of f against P: {:.4}", (f[4] + f[5]) / 6.0);
    println!("P(6) = {:.4}, R(6) = {:.4}, Q(6) = {:.4}", DICE[0][5] as f64 / 60.0, DICE[2][5] as f64 / 60.0, DICE[1][5] as f64 / 60.0);
    let dens_ok = (0..729).all(|g: i64| {
        let mut nu = [0i64; 6];
        for k in 0..6 { nu[k] = g / 3i64.pow(k as u32) % 3 * DICE[2][k]; }
        ac(&nu, &DICE[2])
    });
    println!("all 729 densities with values 0, 1, 2 give measures << R: {}", if dens_ok { "yes" } else { "no" });

    // epsilon-delta: mu(n) = 1/2^n in units of 1/2^16, nu(n) = 1/(n(n+1)) in units of 1/L
    let l: i64 = 12252240;                          // the least common multiple of 1 to 17
    let mut best = 0;
    for a in 0..1usize << 16 {
        let mu: i64 = (1..17).filter(|n| a >> (n - 1) & 1 == 1).map(|n| 1i64 << (16 - n)).sum();
        if mu < 1 << 6 {                           // mu(A) below delta = 1/1024
            best = best.max((1..17i64).filter(|n| a >> (n - 1) & 1 == 1).map(|n| l / (n * (n + 1))).sum());
        }
    }
    best += l / 17;                                 // nu of 17, 18, 19, ... together
    println!("searched {} sets of the numbers 1 to 16; weight beyond 16: 1/17", 1u32 << 16);
    println!("eps 0.1, delta 1/1024: sup of nu(A) over mu(A) < delta, by search {:.4}, by telescoping 1/11 = {:.4}",
             best as f64 / l as f64, 1.0 / 11.0);
    for n in [10u32, 20] { println!("infinite nu (counting): mu({}) = 1/{}, nu({}) = 1", n, 1u64 << n, n); }

    println!("bus waits: d, E1[0,d] = 1 - e^-d, E2[0,d] closed form, E2 by Simpson, bound 2d");
    let (mut gap, mut below, mut chart) = (0.0f64, true, vec![Vec::new(), Vec::new(), Vec::new()]);
    for d in [0.01, 0.05, 0.1, 0.2, 0.3, 0.4, 0.5] {
        let (e1, e2) = (1.0 - ex(-d), 1.0 - ex(-2.0 * d));
        if d > 0.01 { for (row, v) in chart.iter_mut().zip([2.0 * d, e2, e1]) { row.push(format!("{:.2}", v)) } }
        let s2 = simpson(&|x| 2.0 * ex(-2.0 * x), 0.0, d, 200);
        gap = gap.max((e2 - s2).abs());
        below = below && e1 <= d && e2 <= 2.0 * d;
        println!("{:.2}, {:.4}, {:.4}, {:.4}, {:.2}", d, e1, e2, s2, 2.0 * d);
    }
    let rows: Vec<String> = chart.iter().map(|r| r.join(", ")).collect();
    println!("chart, d = 0.05 to 0.5; 2d, E2, E1 to two places: {}", rows.join("; "));
    println!("point mass at 6 on the line: lambda({{6}}) <= 2h, D({{6}}) = 1");
    for h in [0.1f64, 0.001] { println!("h = {}: interval length {}", h, 2.0 * h); }
    let (m6, m01) = (0.5 * 1.0 + 0.5 * overlap(6.0, 6.0), 0.5 * 0.0 + 0.5 * overlap(0.0, 1.0));
    println!("M = half D plus half length on [0, 1]: M({{6}}) = {:.1}, length({{6}}) = {:.1}, M([0, 1]) = {:.1}",
             m6, overlap(6.0, 6.0), m01);

    println!("Cantor stages: n, intervals, total length by list, (2/3)^n, kappa per interval");
    let top: i64 = 59049;                           // 3^10: every endpoint is a whole number of these
    let (mut stage, mut cantor_ok) = (vec![(0i64, top)], true);
    for n in 1..=10u32 {
        stage = stage.iter().flat_map(|&(a, b)| { let t = (b - a) / 3; vec![(a, a + t), (b - t, b)] }).collect();
        let total: i64 = stage.iter().map(|&(a, b)| b - a).sum();
        cantor_ok &= total * 3i64.pow(n) == 2i64.pow(n) * top;
        if [1, 2, 5, 10].contains(&n) {
            println!("{}, {}, {:.4}, {:.4}, 1/{}", n, stage.len(), total as f64 / top as f64, (2.0f64 / 3.0).powi(n as i32), 1u32 << n);
        }
    }
    println!("figure, bars 100 px per unit on baselines y=70,140,210; x=110+40(k-1), width 24; P 16.67 px, Q 10,10,10,10,20,40 px, R 20 px and none at face 6");

    assert!(agree);                                                  // two roads, 20 verdicts
    assert!(table[..4] == ["equivalent", "R << P only", "T << P only", "D << P only"]);
    assert!(table.iter().any(|v| v == "mutually singular") && table.iter().filter(|v| *v == "neither").count() == 1);
    assert!(f.iter().zip([0.6, 0.6, 0.6, 0.6, 1.2, 2.4]).all(|(a, b)| (a - b).abs() < 1e-12)); // density against the hand values
    assert!(dens_ok && best * 11 == l);                              // density; search against telescoping
    assert!(best * 10 < l);                                          // delta 1/1024 meets eps 0.1
    assert!(gap < 1e-9 && below && cantor_ok);                       // two integrals; stages
}
