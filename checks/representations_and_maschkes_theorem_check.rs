// Representations and Maschke's theorem -- the same check as the Python, in Rust.  No crates.
// The tile's eight moves (sign, shift) send corner i to sign*i + shift, wrapped at 4, each a
// 4 by 4 shuffle matrix.  Two roads split corner heights: dot products, and Maschke's average.
type Mat = Vec<Vec<i64>>;
const ONES: [i64; 4] = [1, 1, 1, 1]; const TWIST: [i64; 4] = [1, -1, 1, -1];
const U: [i64; 4] = [1, 0, -1, 0];   const W: [i64; 4] = [0, 1, 0, -1];
fn home(a: (i64, i64), i: i64) -> i64 { (a.0 * i + a.1).rem_euclid(4) }
fn name(a: (i64, i64)) -> String { format!("r{}{}", a.1, if a.0 == -1 { "f" } else { "" }) }
fn rho(a: (i64, i64)) -> Mat { (0..4).map(|i| (0..4).map(|j| (home(a, j) == i) as i64).collect()).collect() }
fn mul(a: &Mat, b: &Mat) -> Mat { (0..a.len()).map(|i| (0..b[0].len()).map(|j| (0..b.len()).map(|k| a[i][k] * b[k][j]).sum()).collect()).collect() }
fn act(a: &Mat, x: &[i64]) -> Vec<i64> { a.iter().map(|r| r.iter().zip(x).map(|(p, q)| p * q).sum()).collect() }
fn tr(a: &Mat) -> i64 { (0..a.len()).map(|i| a[i][i]).sum() }
fn par(v: &[i64], w: &[i64]) -> bool { (0..4).all(|i| (0..4).all(|j| v[i] * w[j] == v[j] * w[i])) }
fn times8(a: &Mat) -> Mat { a.iter().map(|r| r.iter().map(|v| 8 * v).collect()).collect() }
fn row(t: &str, vals: &[String]) { println!("{:<25}{}", t, vals.iter().map(|v| format!("{:>5}", v)).collect::<String>()) }
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn average(rs: &[Mat], col: &[i64]) -> Mat {    // 8 x Maschke's average of the skewed projection
    let p: Mat = col.iter().map(|&c| vec![c, 0, 0, 0]).collect();      // whose column 0 is col
    let cs: Vec<Mat> = rs.iter().map(|g| {          // rho(g) P rho(g)^-1; inverse = transpose
        mul(&mul(g, &p), &(0..4).map(|i| (0..4).map(|j| g[j][i]).collect()).collect()) }).collect();
    (0..4).map(|i| (0..4).map(|j| cs.iter().map(|c| c[i][j]).sum()).collect()).collect()
}
fn plane(g: &Mat) -> Mat { let (cu, cw) = (act(g, &U), act(g, &W)); vec![vec![cu[0], cw[0]], vec![cu[1], cw[1]]] } // basis u, w
fn keeps(a: &Mat, (p, q): (i64, i64)) -> bool { let (x, y) = (a[0][0] + a[0][1] * p, a[0][1] * q); (x * p - y * q, x * q + y * p) == (a[1][0] + a[1][1] * p, a[1][1] * q) } // A sends (1, c) along (1, c); c = p + q i
fn split(x: &[i64]) -> (i64, i64, i64, i64) {       // road one: dot products with fixed patterns
    (x.iter().sum::<i64>() / 4, (x[0] - x[1] + x[2] - x[3]) / 4, (x[0] - x[2]) / 2, (x[1] - x[3]) / 2) }
fn s<T: ToString>(v: &[T]) -> Vec<String> { v.iter().map(|x| x.to_string()).collect() }
fn main() {
    let moves: Vec<(i64, i64)> = [1i64, -1].iter().flat_map(|&s| (0..4).map(move |k| (s, k))).collect();
    let r: Vec<Mat> = moves.iter().map(|&a| rho(a)).collect();
    let (m, t) = (average(&r, &ONES), average(&r, &TWIST));
    let signs: Vec<i64> = r.iter().map(|g| act(g, &TWIST)[0]).collect();
    let ptr: Vec<i64> = r.iter().map(|g| tr(&plane(g))).collect();
    let traces: Vec<i64> = r.iter().map(|g| tr(g)).collect();
    row("move", &moves.iter().map(|&a| name(a)).collect::<Vec<_>>());
    row("corners 0 1 2 3 go to", &moves.iter().map(|&a| (0..4).map(|i| home(a, i).to_string()).collect()).collect::<Vec<String>>());
    row("trace: corners left put", &s(&traces));
    row("twist piece acts as", &s(&signs));
    row("trace on the plane", &s(&ptr));
    let hom = moves.iter().all(|&a| moves.iter().all(|&b| mul(&rho(a), &rho(b)) == rho((a.0 * b.0, home(a, b.1)))));
    println!("rho(a * b) = rho(a) rho(b) for all 64 pairs: {}", yn(hom));
    println!("on the plane, basis u = e0 - e2, w = e1 - e3: r1 -> {:?}, r0f -> {:?}", plane(&r[1]), plane(&r[4]));
    let grid: Vec<Vec<i64>> = (0..81).map(|n| vec![n / 27 - 1, n / 9 % 3 - 1, n / 3 % 3 - 1, n % 3 - 1]).collect();
    let lines: Vec<Vec<i64>> = grid.into_iter().filter(|v| v.iter().any(|&e| e != 0)
        && *v.iter().find(|&&e| e != 0).unwrap() == 1 && r.iter().all(|g| par(&act(g, v), v))).collect();
    println!("lines kept by all 8 moves, entries -1, 0, 1 searched: {:?}", lines);
    let roots: Vec<(i64, i64)> = (-2..3).flat_map(|p| (-2..3).map(move |q| (p, q)))
        .filter(|&c| keeps(&plane(&r[1]), c)).collect();
    let flip: Vec<&(i64, i64)> = roots.iter().filter(|&&c| keeps(&plane(&r[4]), c)).collect();  // of those, kept by r0f too
    let rs: Vec<&str> = roots.iter().map(|&(_, q)| if q < 0 { "-i" } else { "i" }).collect();
    println!("plane lines (1, c) the quarter turn keeps: c = {}; the flip keeps {}", rs.join(", "), flip.len());
    let ok = [&m, &t].iter().all(|a| r.iter().all(|g| mul(a, g) == mul(g, a)) && mul(a, a) == times8(a));
    println!("8 x averaged projection, height: {:?}", m);
    println!("8 x averaged projection, twist: {:?}; both commute with all 8 moves and are projections: {}", t, yn(ok));
    let (x0, mut agree): (Vec<i64>, Vec<bool>) = (vec![6, 2, 4, 0], vec![]);
    for (label, xx) in [("heights", x0.clone()), ("after r1, heights", act(&r[1], &x0))] {
        let (h, tw, a, b) = split(&xx);
        let (mv, sv) = (act(&m, &xx), act(&t, &xx));                          // road two, times 8
        let pieces: Vec<Vec<i64>> = vec![vec![h; 4], TWIST.iter().map(|e| tw * e).collect(), vec![a, b, -a, -b]];
        let lhs: Vec<i64> = pieces.concat().iter().map(|v| 8 * v).collect();
        let rest: Vec<i64> = (0..4).map(|i| 8 * xx[i] - mv[i] - sv[i]).collect();
        let sq: Vec<i64> = pieces.iter().map(|p| p.iter().map(|v| v * v).sum::<i64>()).collect();
        let dots: Vec<i64> = [(0, 1), (0, 2), (1, 2)].iter().map(|&(i, j)| (0..4).map(|k| pieces[i][k] * pieces[j][k]).sum()).collect();
        agree.push(lhs == [mv.clone(), sv.clone(), rest].concat());
        println!("{} {:?} mm: height {}, twist {}, tilt ({}, {}); road two agrees: {}", label, xx, h, tw, a, b, yn(*agree.last().unwrap()));
        println!("  pieces {}; dot products {}; squared sizes {} = {}", pieces.iter().map(|p| format!("{:?}", p)).collect::<Vec<_>>().join(" + "),
                 s(&dots).join(", "), s(&sq).join(" + "), sq.iter().sum::<i64>());
        assert!(dots == vec![0, 0, 0] && sq.iter().sum::<i64>() == xx.iter().map(|v| v * v).sum::<i64>()); // at right angles, so the squares add
    }
    println!("mistake 1, complement x0 = 0 without averaging: kept by {} of 8 moves", r.iter().filter(|g| par(&g[0], &[1, 0, 0, 0])).count());
    println!("mistake 2, sum without the 1/8: trace {}, square = 8 x itself: {}", tr(&m), yn(mul(&m, &m) == times8(&m)));
    println!("mistake 3, splitting the plane along u = e0 - e2: kept by {} of 8 moves", r.iter().filter(|g| par(&act(g, &U), &U)).count());
    let two: Vec<(i64, i64)> = vec![(0, 1), (1, 0), (1, 1)];               // the 3 lines mod 2; the swap
    let kept: Vec<&(i64, i64)> = two.iter().filter(|v| (v.1, v.0) == **v).collect();   // keeps one only
    println!("mistake 4, swap on two coordinates mod 2: kept line {:?}, its complements kept: {} of {}", kept[0], kept.len() - 1, two.len() - 1);
    assert!(agree.iter().all(|&b| b) && hom && ok && lines == vec![TWIST.to_vec(), ONES.to_vec()]);
    assert!((0..8).all(|i| traces[i] == 1 + signs[i] + ptr[i]));                      // 4 = 1 + 1 + 2
    assert!(plane(&r[1]) == vec![vec![0, -1], vec![1, 0]] && plane(&r[4]) == vec![vec![1, 0], vec![0, -1]] && roots == vec![(0, -1), (0, 1)] && flip.is_empty());
    println!("ALL CHECKS PASS");
}
