// Random walks as circuits -- the check behind the card.  std only, no crates.
// Same network, same four roads, same output as the Python check.
const NAMES: [&str; 6] = ["Market", "Park", "Library", "Hospital", "University", "Docks"];
const LINKS: [(usize, usize); 7] = [(0, 1), (1, 5), (0, 2), (2, 3), (3, 5), (1, 4), (4, 5)];
const M: usize = 0;
const D: usize = 5;

fn neighbours(n: usize, links: &[(usize, usize)]) -> Vec<Vec<usize>> {
    let mut nb = vec![Vec::new(); n];
    for &(x, y) in links { nb[x].push(y); nb[y].push(x); }
    nb
}

fn solve(mut a: Vec<Vec<f64>>, rhs: Vec<f64>) -> Vec<f64> {
    // Gaussian elimination with partial pivoting
    let k = rhs.len();
    for (i, row) in a.iter_mut().enumerate() { row.push(rhs[i]); }
    for c in 0..k {
        let p = (c..k).fold(c, |p, r| if a[r][c].abs() > a[p][c].abs() { r } else { p });
        a.swap(c, p);
        for r in 0..k {
            if r != c {
                let f = a[r][c] / a[c][c];
                for j in 0..=k { a[r][j] -= f * a[c][j]; }
            }
        }
    }
    (0..k).map(|i| a[i][k] / a[i][i]).collect()
}

fn index_without(n: usize, skip: usize) -> Vec<usize> {
    (0..n).filter(|&x| x != skip).collect()
}

fn voltages(nb: &[Vec<usize>], inject: &[f64], ground: usize) -> Vec<f64> {
    // Kirchhoff's current law: sum over links of (v_x - v_y) = current fed in at x
    let idx = index_without(nb.len(), ground);
    let pos = |y: usize| idx.iter().position(|&z| z == y).unwrap();
    let mut a = vec![vec![0.0; idx.len()]; idx.len()];
    for (r, &x) in idx.iter().enumerate() {
        a[r][r] = nb[x].len() as f64;
        for &y in &nb[x] {
            if y != ground { a[r][pos(y)] -= 1.0; }
        }
    }
    let v = solve(a, idx.iter().map(|&x| inject[x]).collect());
    let mut out = vec![0.0; nb.len()];
    for (r, &x) in idx.iter().enumerate() { out[x] = v[r]; }
    out
}

fn r_eff(nb: &[Vec<usize>], a: usize, b: usize) -> f64 {
    let mut inject = vec![0.0; nb.len()];
    inject[a] = 1.0;
    voltages(nb, &inject, b)[a]
}

fn first_step(out: &[Vec<usize>], target: usize) -> Vec<f64> {
    // t_x = 1 + average of t_y over the stations a rider at x may go to
    let idx = index_without(out.len(), target);
    let pos = |y: usize| idx.iter().position(|&z| z == y).unwrap();
    let mut a = vec![vec![0.0; idx.len()]; idx.len()];
    for (r, &x) in idx.iter().enumerate() {
        a[r][r] = 1.0;
        for &y in &out[x] {
            if y != target { a[r][pos(y)] -= 1.0 / out[x].len() as f64; }
        }
    }
    let t = solve(a, vec![1.0; idx.len()]);
    let mut res = vec![0.0; out.len()];
    for (r, &x) in idx.iter().enumerate() { res[x] = t[r]; }
    res
}

struct SplitMix64(u64);
impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
}

fn ride(nb: &[Vec<usize>], rng: &mut SplitMix64, start: usize, target: usize) -> u64 {
    let (mut x, mut trips) = (start, 0u64);
    while x != target { x = nb[x][(rng.next() % nb[x].len() as u64) as usize]; trips += 1; }
    trips
}

fn row(label: &str, v: &[f64]) -> String {
    let parts: Vec<String> = (0..6).map(|x| format!("{} {:.4}", &NAMES[x][..3], v[x])).collect();
    format!("{} {}", label, parts.join(" "))
}

fn main() {
    let nb = neighbours(6, &LINKS);
    let m = LINKS.len() as f64;
    let r = r_eff(&nb, M, D);
    let par = |r1: f64, r2: f64| r1 * r2 / (r1 + r2);
    let r_sp = par(1.0 + par(1.0, 1.0 + 1.0), 1.0 + 1.0 + 1.0);
    let deg: Vec<f64> = nb.iter().map(|z| z.len() as f64).collect();
    let v_hit = voltages(&nb, &deg, D);
    let (t_to_d, t_to_m) = (first_step(&nb, D), first_step(&nb, M));
    let commute = t_to_d[M] + t_to_m[D];

    let n = 20000u64;
    let mut rng = SplitMix64(2026);
    let (mut s1, mut s2, mut q) = (0u64, 0u64, 0u64);
    for _ in 0..n {
        let (a, b) = (ride(&nb, &mut rng, M, D), ride(&nb, &mut rng, D, M));
        s1 += a; s2 += b; q += (a + b) * (a + b);
    }
    let nf = n as f64;
    let (sim_go, sim_back, sim_c) = (s1 as f64 / nf, s2 as f64 / nf, (s1 + s2) as f64 / nf);
    let se = ((q as f64 / nf - sim_c * sim_c) / nf).sqrt();

    let mut oneway = nb.clone();
    oneway[1].retain(|&y| y != M); // no rider may go Park -> Market
    let (ow_go, ow_back) = (first_step(&oneway, D)[M], first_step(&oneway, M)[D]);

    assert!((r - 15.0 / 14.0).abs() < 1e-12, "circuit solve vs the hand fraction 15/14");
    assert!((r_sp - r).abs() < 1e-12, "series and parallel vs circuit solve");
    assert!((commute - 2.0 * m * r).abs() < 1e-9, "walk commute time vs 2 m R_eff");
    assert!((0..6).all(|x| (v_hit[x] - t_to_d[x]).abs() < 1e-9), "voltages vs hitting times");
    assert!((sim_c - commute).abs() < 4.0 * se, "simulated round trip vs exact commute time");
    assert!(((ow_go + ow_back) - 2.0 * m * r).abs() > 10.0, "a one-way lane should break the identity");

    println!("stations n 6  links m {}", LINKS.len());
    let degs: Vec<String> = (0..6).map(|x| format!("{}={}", NAMES[x], nb[x].len())).collect();
    println!("degrees d(x) {}", degs.join(" "));
    println!("1 R_eff Market-Docks, circuit solve   {:.4}", r);
    println!("2 R_eff by series and parallel        {:.4}  (= 15/14 ohm)", r_sp);
    println!("3 trips Market->Docks, first step     {:.4}", t_to_d[M]);
    println!("3 trips Docks->Market, first step     {:.4}", t_to_m[D]);
    println!("  commute time, sum of the two        {:.4}", commute);
    println!("  commute time, 2 m R_eff             {:.4}", 2.0 * m * r);
    println!("{}", row("voltages, d(x) amps in, Docks at 0 V:", &v_hit));
    println!("{}", row("hitting times to Docks, first step:  ", &t_to_d));
    println!("{}", row("hitting times to Market, first step: ", &t_to_m));
    println!("4 simulated, {} round trips, seed 2026", n);
    println!("  mean trips Market->Docks            {:.4}", sim_go);
    println!("  mean trips Docks->Market            {:.4}", sim_back);
    println!("  mean round trip                     {:.4}  standard error {:.4}", sim_c, se);
    println!("wrong: n stations for m links, 2nR    {:.4}", 2.0 * 6.0 * r);
    println!("wrong: drop the 2, m R                {:.4}", m * r);
    println!("wrong: shortest route 2 links, 2m*2   {:.4}", 2.0 * m * 2.0);
    println!("wrong: twice Market->Docks            {:.4}", 2.0 * t_to_d[M]);
    println!("wrong: twice Docks->Market            {:.4}", 2.0 * t_to_m[D]);
    println!("broken: one-way lane, Market->Docks   {:.4}", ow_go);
    println!("broken: one-way lane, Docks->Market   {:.4}", ow_back);
    println!("broken: one-way lane, commute         {:.4}  circuit still says {:.4}", ow_go + ow_back, 2.0 * m * r);
    let spur = [&LINKS[..], &[(1, 6)]].concat(); // a dead-end station 6 hung off Park
    let direct = [&LINKS[..], &[(0, 5)]].concat();
    let cut: Vec<(usize, usize)> = LINKS.iter().copied().filter(|&e| e != (4, 5)).collect();
    let tries = [("dead-end station off Park", spur, 7), ("direct Market-Docks link ", direct, 6), ("no University-Docks link ", cut, 6)];
    for (label, links, nn) in tries.iter() {
        let nbt = neighbours(*nn, links);
        let rt = r_eff(&nbt, M, D);
        let c = first_step(&nbt, D)[M] + first_step(&nbt, M)[D];
        assert!((c - 2.0 * links.len() as f64 * rt).abs() < 1e-9, "try network: walk commute time vs 2 m R_eff");
        println!("try: {}  m {}  R_eff {:.4}  commute {:.4}", label, links.len(), rt, c);
    }
    println!("figure, Market 40 120, Park 150 70, University 250 40, Docks 320 120, Library 120 190, Hospital 240 190");
    println!("ALL CHECKS PASS");
}
