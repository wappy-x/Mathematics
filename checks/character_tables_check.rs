// Character tables -- the same check as the Python, in Rust.  No crates.  Each group is the list r^k f^m built from
// two generators.  Road one finds the classes by conjugating; road two finds the one-dimensional pieces by trying
// signs for r and f; road three is the trace of a 2-by-2 action.  Orthogonality, the regular representation and commutators cross-check.
type E = [i64; 4]; type C = [(i64, i64); 4];     // E: a 2-by-2 matrix row by row, or a quaternion; C: complex 2-by-2, (re, im)
fn cmat(p: C, q: C) -> C {
    let e = |i: usize, j: usize| (0..2).fold((0, 0), |(re, im), k| { let (a, b) = (p[2 * i + k], q[2 * k + j]); (re + a.0 * b.0 - a.1 * b.1, im + a.0 * b.1 + a.1 * b.0) });
    [e(0, 0), e(0, 1), e(1, 0), e(1, 1)] }
fn mat(p: E, q: E) -> E { [p[0]*q[0] + p[1]*q[2], p[0]*q[1] + p[1]*q[3], p[2]*q[0] + p[3]*q[2], p[2]*q[1] + p[3]*q[3]] }
fn quat(p: E, q: E) -> E {                        // quaternions a + b i + c j + d k
    [p[0]*q[0] - p[1]*q[1] - p[2]*q[2] - p[3]*q[3], p[0]*q[1] + p[1]*q[0] + p[2]*q[3] - p[3]*q[2],
     p[0]*q[2] - p[1]*q[3] + p[2]*q[0] + p[3]*q[1], p[0]*q[3] + p[1]*q[2] - p[2]*q[1] + p[3]*q[0]]
}
fn fixed(g: E, corners: &[(i64, i64)]) -> i64 {   // corners a matrix sends to themselves
    corners.iter().filter(|&&(x, y)| (g[0]*x + g[1]*y, g[2]*x + g[3]*y) == (x, y)).count() as i64
}
fn ip(sizes: &[i64], u: &[i64], v: &[i64]) -> i64 { (0..sizes.len()).map(|c| sizes[c] * u[c] * v[c]).sum() }
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
struct T { reps: Vec<E>, sizes: Vec<i64>, rows: Vec<Vec<i64>>, twos: i64, hom2: bool }
fn table(name: &str, r: E, f: E, n: usize, mul: fn(E, E) -> E, one: E, act2: fn(E) -> C) -> T {
    let pw = |x: E, k: usize| (0..k).fold(one, |acc, _| mul(acc, x));
    let mut g: Vec<E> = vec![];
    for m in 0..2 { for k in 0..n { g.push(mul(pw(r, k), pw(f, m))) } }
    let inv = |x: E| *g.iter().find(|&&y| mul(x, y) == one).unwrap();
    let (mut reps, mut classes): (Vec<E>, Vec<Vec<E>>) = (vec![], vec![]);
    for &x in &g {                                // road one: conjugate each member by all
        if classes.iter().any(|c| c.contains(&x)) { continue }
        let mut c: Vec<E> = vec![];
        for &h in &g { let y = mul(mul(h, x), inv(h)); if !c.contains(&y) { c.push(y) } }
        reps.push(x); classes.push(c);
    }
    classes.sort_by_key(|c| c.len()); reps = classes.iter().map(|c| c[0]).collect();   // smaller classes first
    let sizes: Vec<i64> = classes.iter().map(|c| c.len() as i64).collect();
    let mut rows: Vec<Vec<i64>> = vec![];         // road two: a sign for r, a sign for f
    for (a, b) in [(1i64, 1i64), (1, -1), (-1, 1), (-1, -1)] {
        let val = |x: E| { let i = g.iter().position(|&y| y == x).unwrap(); a.pow((i % n) as u32) * b.pow((i / n) as u32) };
        if g.iter().all(|&x| g.iter().all(|&y| val(mul(x, y)) == val(x) * val(y))) {
            rows.push(reps.iter().map(|&x| val(x)).collect());
        }
    }
    let ones = rows.len(); rows.push(reps.iter().map(|&x| act2(x)[0].0 + act2(x)[3].0).collect());   // road three: trace of the 2-by-2 action
    let hom2 = g.iter().all(|&x| g.iter().all(|&y| cmat(act2(x), act2(y)) == act2(mul(x, y))));      // ... and it respects products
    let (dims, big): (Vec<i64>, i64) = (rows.iter().map(|row| row[0]).collect(), g.len() as i64);
    let orth = (0..rows.len()).all(|i| (0..rows.len()).all(|j| ip(&sizes, &rows[i], &rows[j]) == if i == j { big } else { 0 }));
    let reg: Vec<i64> = reps.iter().map(|&h| g.iter().filter(|&&x| mul(h, x) == x).count() as i64).collect();
    let split: Vec<i64> = (0..reps.len()).map(|c| (0..rows.len()).map(|i| dims[i] * rows[i][c]).sum()).collect();
    let mut comm: Vec<E> = vec![];
    for &x in &g { for &y in &g { let z = mul(mul(x, y), mul(inv(x), inv(y))); if !comm.contains(&z) { comm.push(z) } } }
    loop {                                        // close up under products
        let before = comm.len();
        for i in 0..before { for j in 0..before { let z = mul(comm[i], comm[j]); if !comm.contains(&z) { comm.push(z) } } }
        if comm.len() == before { break } }
    let (sq, tab, total): (Vec<String>, Vec<String>, i64) = (dims.iter().map(|d| (d * d).to_string()).collect(), rows.iter().map(|row| format!("{:?}", row)).collect(), dims.iter().map(|d| d * d).sum());
    println!("{}: {} members, {} classes of sizes {:?}, commutator subgroup of size {}", name, big, reps.len(), sizes, comm.len());
    println!("{} table: {}", name, tab.join(" "));
    println!("{}: {} pieces, {} = {}; one-dim {} = {} / {}; rows orthonormal: {}; regular = dims x rows: {}",
             name, rows.len(), sq.join(" + "), total, ones, big, comm.len(), yn(orth), yn(reg == split));
    assert!(rows.len() == reps.len() && total == big);           // pieces = classes, squares add to |G|
    assert!(orth && reg == split && ones * comm.len() == g.len() && g.iter().all(|&x| g.iter().all(|&y| g.iter().all(|&z| mul(mul(x, y), z) == mul(x, mul(y, z))))));
    T { reps, sizes, rows, twos: g.iter().filter(|&&x| mul(x, x) == one).count() as i64 - 1, hom2 }
}
fn main() {
    let t = table("tile", [0, -1, 1, 0], [1, 0, 0, -1], 4, mat, [1, 0, 0, 1], |g| [(g[0], 0), (g[1], 0), (g[2], 0), (g[3], 0)]);
    let s = table("S3", [0, -1, 1, -1], [0, 1, 1, 0], 3, mat, [1, 0, 0, 1], |g| [(g[0], 0), (g[1], 0), (g[2], 0), (g[3], 0)]);
    let q = table("Q8", [0, 1, 0, 0], [0, 0, 1, 0], 4, quat, [1, 0, 0, 0], |q| [(q[0], q[1]), (q[2], q[3]), (-q[2], q[3]), (q[0], -q[1])]);   // q0 + q1 i + q2 j + q3 k, complex
    let by_corners: Vec<i64> = s.reps.iter().map(|&g| fixed(g, &[(1, 0), (0, 1), (-1, -1)]) - 1).collect();
    let shuffle: Vec<i64> = t.reps.iter().map(|&g| fixed(g, &[(1, 0), (0, 1), (-1, 0), (0, -1)])).collect();   // corners on the axes
    let holds: Vec<i64> = t.rows.iter().map(|row| ip(&t.sizes, &shuffle, row) / 8).collect();
    let rebuilt: Vec<i64> = (0..5).map(|c| (0..5).map(|i| holds[i] * t.rows[i][c]).sum()).collect();
    let dimsum = |rows: &Vec<Vec<i64>>| rows.iter().map(|r| r[0]).sum::<i64>();
    println!("S3 two-dim row by fixed corners minus 1: {:?}", by_corners);
    println!("tile 4-by-4 corner shuffle by fixed corners: {:?}; copies of each piece: {:?}", shuffle, holds);
    println!("Q8's complex 2-by-2 matrices multiply like Q8: {}; tile and Q8 tables identical: {}; members of order 2: tile {}, Q8 {}", yn(q.hom2), yn(t.rows == q.rows && t.sizes == q.sizes), t.twos, q.twos);
    println!("mistake 1, dimensions added, not squared: tile {}, S3 {}", dimsum(&t.rows), dimsum(&s.rows));
    println!("mistake 2, S3 trivial against sign without class sizes: {}/6, not {}",
             (0..3).map(|c| s.rows[0][c] * s.rows[1][c]).sum::<i64>(), ip(&s.sizes, &s.rows[0], &s.rows[1]));
    println!("mistake 3, one piece per member: 8 one-dim pieces needed, {} found", t.rows.iter().filter(|r| r[0] == 1).count());
    assert!(by_corners == s.rows[2] && rebuilt == shuffle);             // two roads to the same rows
    assert!(q.hom2 && t.rows == q.rows && t.sizes == q.sizes && (t.twos, q.twos) == (5, 1));   // one table, two groups
    println!("ALL CHECKS PASS");
}
