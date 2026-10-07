// Same size means pairable -- the same check as same_size_by_pairing_check.py,
// in Rust.  No crates.  The hotel has a room for every counting number and
// every room is full; the first 8 rooms are shown.  Two pairings, each read
// forwards and then backwards, and a finite hotel of 8 rooms that manages
// neither.
const N: i64 = 8;

fn distinct(v: &[i64]) -> usize { let mut s = v.to_vec(); s.sort(); s.dedup(); s.len() }

fn row(name: &str, values: &[i64]) {
    let parts: Vec<String> = values.iter().map(|v| v.to_string()).collect();
    println!("{}: {}", name, parts.join(", "));
}

fn main() {
    let guests: Vec<i64> = (1..=N).collect();
    let shift: Vec<i64> = guests.iter().map(|n| n + 1).collect();          // a new guest: everyone moves up one
    let even: Vec<i64> = guests.iter().map(|n| 2 * n).collect();           // every guest into an even room
    let back: Vec<i64> = even.iter().map(|r| r / 2).collect();             // the same pairing, read backwards
    let listed: Vec<i64> = (1..=2 * N).filter(|r| r % 2 == 0).collect();   // the even rooms, listed straight
    let small: Vec<i64> = (1..=N).collect();                               // the finite hotel: 8 rooms and no more
    let housed = small.iter().filter(|n| small.contains(&(*n + 1))).count() as i64;
    let small_even: Vec<i64> = small.iter().cloned().filter(|r| r % 2 == 0).collect();
    row("the hotel, rooms 1 to 8 shown, every room full", &guests);
    row("a new guest: everyone moves up one, room n to room n+1", &shift);
    println!("room 1 is now empty: {} guests in {} different rooms, none lost", distinct(&shift), distinct(&shift));
    row("every guest into an even room, room n to room 2n", &even);
    row("the same pairing backwards, each even room halved", &back);
    row("the even rooms up to 16, listed straight", &listed);
    println!("that is {} even rooms for {} guests, nobody doubled up, no even room left empty", listed.len(), guests.len());
    println!("the endless hotel has room {}; the finite one stops at {} -- same {} guests, different answer", N + 1, N, N);
    println!("finite hotel of 8 rooms: moving up one houses {} of {}, {} guest left outside", housed, N, N - housed);
    let se: Vec<String> = small_even.iter().map(|r| r.to_string()).collect();
    println!("finite hotel of 8 rooms: the even rooms are {} -- {} rooms for {} guests, {} left outside",
             se.join(", "), small_even.len(), N, N - small_even.len() as i64);
    assert!(distinct(&shift) == N as usize && !shift.contains(&1) && shift == (2..=N + 1).collect::<Vec<i64>>());
    assert!(back == guests && even == listed && distinct(&even) == N as usize);
    assert!(housed == 7 && small_even == [2, 4, 6, 8] && small_even.len() == 4);
    println!("ALL CHECKS PASS");
}
