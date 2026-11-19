// Hairy ball theorem -- the same check as vector_field_zeros_and_the_hairy_ball_check.py, in Rust.
// Standard library only, no crates.  Model pressure p = 1013 + 20 s hPa, s = 3 sqrt(3) x y z,
// on the Earth as a sphere of radius 6371 km; wind W = -grad p.  Four roads to the total index 2.
use std::collections::HashSet;
use std::f64::consts::PI;
type V3 = [f64; 3];
const TAU: f64 = 2.0 * PI;

fn dot(a: V3, b: V3) -> f64 { a[0] * b[0] + a[1] * b[1] + a[2] * b[2] }
fn cross(a: V3, b: V3) -> V3 { [a[1]*b[2] - a[2]*b[1], a[2]*b[0] - a[0]*b[2], a[0]*b[1] - a[1]*b[0]] }
fn unit(a: V3) -> V3 { let n = dot(a, a).sqrt(); [a[0] / n, a[1] / n, a[2] / n] }
fn amp() -> f64 { 20.0 * 3.0 * 3f64.sqrt() }
fn pressure(r: V3) -> f64 { 1013.0 + amp() * r[0] * r[1] * r[2] }
fn wind(r: V3) -> V3 {                          // -grad p, tangent to the globe, hPa per Earth radius
    let a = amp();
    let g = [a * r[1] * r[2], a * r[0] * r[2], a * r[0] * r[1]];
    let k = dot(g, r); [-(g[0] - k * r[0]), -(g[1] - k * r[1]), -(g[2] - k * r[2])]
}
fn turned(r: V3) -> V3 { cross(r, wind(r)) }   // every arrow given a quarter turn
fn east(r: V3) -> V3 { [-10.0 * r[1], 10.0 * r[0], 0.0] }
fn frame(p: V3) -> (V3, V3) {                   // e1, e2 tangent at p, with e1 x e2 = p
    let a = if p[2].abs() < 0.9 { [0.0, 0.0, 1.0] } else { [1.0, 0.0, 0.0] };
    let e1 = unit(cross(a, p)); (e1, cross(p, e1))
}
fn angle(f: fn(V3) -> V3, q: V3, e1: V3, e2: V3) -> f64 { let w = f(q); dot(w, e2).atan2(dot(w, e1)) }
fn walk(f: fn(V3) -> V3, pts: &[V3], e1: V3, e2: V3) -> f64 {
    let (mut tot, mut a0) = (0.0, angle(f, pts[0], e1, e2));
    for q in &pts[1..] {
        let a1 = angle(f, *q, e1, e2); let step = (a1 - a0 + PI).rem_euclid(TAU) - PI;
        assert!(step.abs() < 1.0, "steps too coarse to follow the wind");
        tot += step; a0 = a1;
    }
    tot / TAU
}
fn circle(p: V3, rad: f64, n: usize, sense: f64) -> Vec<V3> {
    let (e1, e2) = frame(p);
    (0..=n).map(|k| {
        let t = sense * TAU * k as f64 / n as f64;
        let mut q = [0.0; 3];
        for i in 0..3 { q[i] = rad.cos() * p[i] + rad.sin() * (t.cos() * e1[i] + t.sin() * e2[i]); } q
    }).collect()
}
fn loop_index(f: fn(V3) -> V3, p: V3, rad: f64, sense: f64) -> f64 {
    let (e1, e2) = frame(p); walk(f, &circle(p, rad, 360, sense), e1, e2)
}
fn det_sign(f: fn(V3) -> V3, p: V3) -> i64 {
    let (h, (e1, e2)) = (1e-5, frame(p));
    let comp = |s: f64, t: f64| {
        let q = unit([p[0] + s * e1[0] + t * e2[0], p[1] + s * e1[1] + t * e2[1], p[2] + s * e1[2] + t * e2[2]]);
        let w = f(q); (dot(w, e1), dot(w, e2))
    };
    let ((a, c), (a_, c_)) = (comp(h, 0.0), comp(-h, 0.0));
    let ((b, d), (b_, d_)) = (comp(0.0, h), comp(0.0, -h));
    let det = ((a - a_) * (d - d_) - (b - b_) * (c - c_)) / (4.0 * h * h);
    if det > 0.0 { 1 } else { -1 }
}
fn latlon(r: V3) -> (f64, f64) { let d = 180.0 / PI; (90.0 - r[2].acos() * d, r[1].atan2(r[0]) * d) }
fn rnd(x: f64) -> i64 { x.round() as i64 }

fn main() {
    let (s3, mut zeros) = (1.0 / 3f64.sqrt(), Vec::<V3>::new());
    for sx in [1.0, -1.0] { for sy in [1.0, -1.0] { for sz in [1.0, -1.0] { zeros.push([sx * s3, sy * s3, sz * s3]); } } }
    for j in 0..3 { for s in [1.0, -1.0] { let mut z = [0.0; 3]; z[j] = s; zeros.push(z); } }
    let rp = unit([0.3, 0.5, 0.8]); // W = -grad p, checked against differences of p
    for e in [frame(rp).0, frame(rp).1] { let ph = |s: f64| pressure(unit([rp[0] + s * e[0], rp[1] + s * e[1], rp[2] + s * e[2]]));
        assert!(((ph(1e-5) - ph(-1e-5)) / 2e-5 + dot(wind(rp), e)).abs() < 1e-6, "wind is not -grad p"); }
    println!("calm spot      lat        lon   p hPa  loop  det");
    let (mut tot1, mut tot2, mut tot_t) = (0, 0, 0);
    for &z in &zeros {
        assert!(dot(wind(z), wind(z)).sqrt() < 1e-12, "a listed calm spot is not calm");
        let raw = loop_index(wind, z, 0.02, 1.0);
        let (i1, i2) = (rnd(raw), det_sign(wind, z));
        assert!((raw - i1 as f64).abs() < 1e-9 && i1 == i2, "loop and determinant disagree");
        let it = rnd(loop_index(turned, z, 0.02, 1.0)); tot_t += it;
        assert!(it == i1, "a quarter turn changed an index");
        let p = pressure(z);
        let kind = if p > 1013.5 { "high" } else if p < 1012.5 { "low" } else { "col" };
        tot1 += i1; tot2 += i2;
        let (la, lo) = latlon(z);
        println!("{:>9} {:8.4} {:10.4} {:7.2} {:+5} {:+4}", kind, la, lo, p, i1, i2);
    }
    let count = |up: bool| zeros.iter().filter(|&&z| if up { pressure(z) > 1013.5 } else { pressure(z) < 1012.5 }).count() as i64;
    let (hi, lo) = (count(true), count(false)); assert!(hi == 4 && lo == 4, "the map should have 4 highs and 4 lows");
    println!("highs {}, lows {}, cols {}: {} + {} - {} = {:+}", hi, lo, 14 - hi - lo, hi, lo, 14 - hi - lo, hi + lo - (14 - hi - lo));
    println!("road 1 sum of loop indices          {:+}", tot1);
    println!("road 2 sum of determinant signs     {:+}", tot2);
    println!("quarter-turned wind, sum of loop indices {:+}", tot_t);
    println!("loop radius 0.02 rad = {:.1} km", 0.02 * 6371.0);

    let (ta, tb) = (0.75f64, 0.3f64);           // the grid is tilted, so no calm spot sits on a cell edge
    let q = [[ta.cos(), -ta.sin(), 0.0], [ta.sin() * tb.cos(), ta.cos() * tb.cos(), -tb.sin()],
             [ta.sin() * tb.sin(), ta.cos() * tb.sin(), tb.cos()]];
    let onsphere = |c: V3| unit([dot(q[0], c), dot(q[1], c), dot(q[2], c)]);
    let (n, m) = (9i64, 12i64);
    let (mut cells, mut tot3, mut found) = (0i64, 0i64, 0i64);
    let mut vs: HashSet<[i64; 3]> = HashSet::new();
    let mut es: HashSet<([i64; 3], [i64; 3])> = HashSet::new();
    for ax in 0..3 { for sg in [1i64, -1] {
        let pt = |i: i64, j: i64| { let mut c = [0i64; 3]; c[ax] = sg * n; c[(ax + 1) % 3] = i; c[(ax + 2) % 3] = j; c };
        let mut i = -n;
        while i < n { let mut j = -n; while j < n {
            let mut cor = vec![pt(i, j), pt(i + 2, j), pt(i + 2, j + 2), pt(i, j + 2), pt(i, j)];
            if sg < 0 { cor.reverse(); }
            let mut bd: Vec<V3> = Vec::new();
            for e in 0..4 { for k in 0..m {
                let mut c = [0.0; 3];
                for t in 0..3 { c[t] = cor[e][t] as f64 + ((cor[e + 1][t] - cor[e][t]) * k) as f64 / m as f64; }
                bd.push(onsphere(c));
            } }
            bd.push(onsphere([cor[0][0] as f64, cor[0][1] as f64, cor[0][2] as f64]));
            let mut ctr = [0.0; 3];
            for t in 0..3 { ctr[t] = (cor[0][t] + cor[1][t] + cor[2][t] + cor[3][t]) as f64 / 4.0; }
            let (e1, e2) = frame(onsphere(ctr)); let k = walk(wind, &bd, e1, e2);
            assert!((k - k.round()).abs() < 1e-9);
            cells += 1; tot3 += rnd(k); if rnd(k) != 0 { found += 1; }
            for e in 0..4 { vs.insert(cor[e]); let (a, b) = (cor[e], cor[e + 1]); es.insert(if a < b { (a, b) } else { (b, a) }); }
            j += 2; } i += 2; }
    } }
    let (nv, ne, nf) = (vs.len() as i64, es.len() as i64, cells);
    println!("road 3 cells {}, cells holding a calm spot {}, sum {:+}", cells, found, tot3);
    println!("road 4 grid V {}  E {}  F {}  V - E + F = {}", nv, ne, nf, nv - ne + nf);
    assert!(tot1 == 2 && tot2 == 2 && tot3 == 2 && nv - ne + nf == 2 && found == 14, "the four roads disagree");

    let poles = [loop_index(east, [0.0, 0.0, 1.0], 0.02, 1.0), loop_index(east, [0.0, 0.0, -1.0], 0.02, 1.0)]; assert!(rnd(poles[0]) == 1 && rnd(poles[1]) == 1);
    let ldn = (90.0f64 - 51.5).to_radians();
    println!("east wind: London {:.2} m/s, pole indices {:+} {:+}", 10.0 * ldn.sin(), rnd(poles[0]), rnd(poles[1]));

    let mut head = String::from("chart, loop position  ");
    for k in 0..13 { head += &format!("{:7}", 30 * k); }
    println!("{}", head);
    for (name, z) in [("high 35N 45E", zeros[0]), ("col North Pole", zeros[12])] {
        let ((e1, e2), pts) = (frame(z), circle(z, 0.02, 360, 1.0));
        let mut line = format!("chart, {:15}", name);
        for k in 0..13 { line += &format!("{:7.1}", walk(wind, &pts[..30 * k + 1], e1, e2) * 360.0); }
        println!("{}", line);
    }

    let (counted, cw) = (zeros.len() as i64, zeros.iter().map(|&z| rnd(loop_index(wind, z, 0.02, -1.0))).sum::<i64>());
    let big = loop_index(wind, [0.0, 0.0, 1.0], 60f64.to_radians(), 1.0);
    println!("wrong: every calm spot counted +1     {:+}", counted);
    println!("wrong: loops walked clockwise         {:+}", cw);
    println!("wrong: 60 deg loop round North Pole   {:+}  (1 col, 2 highs, 2 lows inside)", rnd(big));
    assert!(cw == -2 && rnd(big) == 3);

    let tor = |u: f64, v: f64| (u.sin(), v.sin());   // doughnut world: wind -grad(cos u + cos v)
    let tor_index = |u0: f64, v0: f64| {
        let (r, k) = (0.05, 360);
        let (x, y) = tor(u0 + r, v0); let (mut t, mut a0) = (0.0, y.atan2(x));
        for s in 1..=k {
            let (x, y) = tor(u0 + r * (TAU * s as f64 / k as f64).cos(), v0 + r * (TAU * s as f64 / k as f64).sin());
            let a1 = y.atan2(x);
            t += (a1 - a0 + PI).rem_euclid(TAU) - PI; a0 = a1;
        }
        rnd(t / TAU)
    };
    let ti: Vec<i64> = [(0.0, 0.0), (PI, PI), (0.0, PI), (PI, 0.0)].iter().map(|&(u, v)| tor_index(u, v)).collect();
    let nt = 6usize;
    let (mut tv, mut te, mut tf) = (HashSet::new(), HashSet::new(), 0i64);
    for i in 0..nt { for j in 0..nt {
        let c = [(i, j), ((i + 1) % nt, j), ((i + 1) % nt, (j + 1) % nt), (i, (j + 1) % nt)];
        for e in 0..4 { tv.insert(c[e]); let (a, b) = (c[e], c[(e + 1) % 4]); te.insert(if a < b { (a, b) } else { (b, a) }); }
        tf += 1;
    } }
    let (tchi, tsum) = (tv.len() as i64 - te.len() as i64 + tf, ti.iter().sum::<i64>());
    println!("doughnut: indices {:+} {:+} {:+} {:+}, sum {}; grid V {} E {} F {}, V - E + F = {}",
             ti[0], ti[1], ti[2], ti[3], tsum, tv.len(), te.len(), tf, tchi);
    println!("doughnut: wind round the tube (1, 0) has speed 1 everywhere, no calm spot");
    assert!(tsum == 0 && tchi == 0 && ti == vec![1, 1, -1, -1]);
    println!("ALL CHECKS PASS");
}
