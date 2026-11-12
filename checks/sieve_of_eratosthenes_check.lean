-- The sieve of Eratosthenes: for every corridor length N, shutting locker 1 and then, for each door still open whose number times itself fits in the corridor, slamming its multiples leaves open exactly the primes from 1 to N.
import Mathlib.Data.Nat.Prime.Defs
import Mathlib.Order.Interval.Finset.Nat
import Mathlib.Tactic.NormNum.Prime
import Mathlib.Data.Nat.Sqrt
import Mathlib.Tactic.Linarith

/-- One pass of the sieve. If door `p` is still open, keep it and slam every multiple of `p`
from `start p` on; if door `p` is already shut, nothing happens. The card starts each pass at
`p × p`; starting at `2 × p` (every multiple after `p`) is the other form it mentions. -/
def sievePass (start : ℕ → ℕ) (open_ : Finset ℕ) (p : ℕ) : Finset ℕ :=
  if p ∈ open_ then open_.filter (fun k => ¬ (p ∣ k ∧ start p ≤ k)) else open_

/-- The kept numbers walked in order: 2, 3, 4, … , stopping once the number times itself runs
past the end of the corridor `N`. -/
def passNumbers (N : ℕ) : List ℕ :=
  (List.range' 2 N).takeWhile (fun p => p * p ≤ N)

/-- The sieve on lockers 1 to `N`: locker 1 is shut by hand, so doors 2 to `N` start open; then
every pass runs in order. The result is the set of doors still open. -/
def sieveWith (start : ℕ → ℕ) (N : ℕ) : Finset ℕ :=
  (passNumbers N).foldl (sievePass start) (Finset.Icc 2 N)

lemma takeWhile_range'_sq (N : ℕ) : ∀ (n a : ℕ),
    (List.range' a n).takeWhile (fun p => decide (p * p ≤ N)) =
      List.range' a (min n (Nat.sqrt N + 1 - a)) := by
  intro n
  induction n with
  | zero => intro a; simp
  | succ n ih =>
    intro a
    rw [List.range'_succ, List.takeWhile_cons]
    by_cases h : a * a ≤ N
    · have ha : a ≤ Nat.sqrt N := Nat.le_sqrt.mpr h
      simp only [h, decide_true, ite_true]
      rw [ih (a + 1)]
      have : min (n + 1) (Nat.sqrt N + 1 - a) = min n (Nat.sqrt N + 1 - (a + 1)) + 1 := by omega
      rw [this, List.range'_succ]
    · have ha : ¬ a ≤ Nat.sqrt N := fun h' => h (Nat.le_sqrt.mp h')
      simp only [h, decide_false]
      have : min (n + 1) (Nat.sqrt N + 1 - a) = 0 := by omega
      simp [this]

#print axioms takeWhile_range'_sq

open scoped Classical in
lemma sieve_fold (s : ℕ → ℕ) (h1 : ∀ p, 2 ≤ p → p < s p) (N : ℕ) : ∀ j : ℕ, j + 1 ≤ N →
    (List.range' 2 j).foldl (sievePass s) (Finset.Icc 2 N) =
      (Finset.Icc 2 N).filter (fun n => ¬ ∃ d, 2 ≤ d ∧ d ≤ j + 1 ∧ d ∣ n ∧ s d ≤ n) := by
  intro j
  induction j with
  | zero =>
    intro _
    simp only [List.range'_zero, List.foldl_nil]
    symm
    apply Finset.filter_true_of_mem
    intro n _
    rintro ⟨d, h2, h3, _⟩
    omega
  | succ j ih =>
    intro hj
    rw [List.range'_concat, List.foldl_append, ih (by omega)]
    simp only [List.foldl_cons, List.foldl_nil, one_mul]
    unfold sievePass
    ext n
    by_cases hp : (2 + j) ∈ (Finset.Icc 2 N).filter (fun n => ¬ ∃ d, 2 ≤ d ∧ d ≤ j + 1 ∧ d ∣ n ∧ s d ≤ n)
    · rw [if_pos hp]
      simp only [Finset.mem_filter, Finset.mem_Icc]
      constructor
      · rintro ⟨⟨hn, hne⟩, hnn⟩
        refine ⟨hn, ?_⟩
        rintro ⟨d, hd2, hd, hdn, hsd⟩
        by_cases hd' : d ≤ j + 1
        · exact hne ⟨d, hd2, hd', hdn, hsd⟩
        · have : d = 2 + j := by omega
          subst this
          exact hnn ⟨hdn, hsd⟩
      · rintro ⟨hn, hne⟩
        refine ⟨⟨hn, fun ⟨d, hd2, hd, hdn, hsd⟩ => hne ⟨d, hd2, by omega, hdn, hsd⟩⟩, ?_⟩
        rintro ⟨hdn, hsd⟩
        exact hne ⟨2 + j, by omega, by omega, hdn, hsd⟩
    · rw [if_neg hp]
      have hp' : ∃ d, 2 ≤ d ∧ d ≤ j + 1 ∧ d ∣ 2 + j ∧ s d ≤ 2 + j := by
        by_contra hc
        exact hp (Finset.mem_filter.mpr ⟨Finset.mem_Icc.mpr ⟨by omega, by omega⟩, hc⟩)
      obtain ⟨d, hd2, hd, hdp, hsd⟩ := hp'
      have hlt := h1 (2 + j) (by omega)
      simp only [Finset.mem_filter, Finset.mem_Icc]
      constructor
      · rintro ⟨hn, hne⟩
        refine ⟨hn, ?_⟩
        rintro ⟨e, he2, he, hen, hse⟩
        by_cases he' : e ≤ j + 1
        · exact hne ⟨e, he2, he', hen, hse⟩
        · have : e = 2 + j := by omega
          subst this
          exact hne ⟨d, hd2, hd, dvd_trans hdp hen, by omega⟩
      · rintro ⟨hn, hne⟩
        exact ⟨hn, fun ⟨e, he2, he, hen, hse⟩ => hne ⟨e, he2, by omega, hen, hse⟩⟩

#print axioms sieve_fold

lemma sieveWith_eq_primes (s : ℕ → ℕ) (h1 : ∀ p, 2 ≤ p → p < s p)
    (h2 : ∀ p, 2 ≤ p → s p ≤ p * p) (N : ℕ) :
    sieveWith s N = (Finset.Icc 1 N).filter Nat.Prime := by
  rcases Nat.eq_zero_or_pos N with rfl | hN
  · simp [sieveWith, passNumbers]
  have hsq : Nat.sqrt N - 1 + 1 = Nat.sqrt N := by
    have : 1 ≤ Nat.sqrt N := Nat.le_sqrt.mpr (by omega)
    omega
  have hle := Nat.sqrt_le_self N
  unfold sieveWith passNumbers
  rw [takeWhile_range'_sq]
  have hmin : min N (Nat.sqrt N + 1 - 2) = Nat.sqrt N - 1 := by omega
  rw [hmin, sieve_fold s h1 N (Nat.sqrt N - 1) (by omega), hsq]
  ext n
  simp only [Finset.mem_filter, Finset.mem_Icc]
  constructor
  · rintro ⟨⟨hn2, hnN⟩, hne⟩
    refine ⟨⟨by omega, hnN⟩, ?_⟩
    by_contra hnp
    apply hne
    have hmf : n.minFac.Prime := Nat.minFac_prime (by omega)
    have hmd : n.minFac ∣ n := Nat.minFac_dvd n
    have hmsq : n.minFac ^ 2 ≤ n := Nat.minFac_sq_le_self (by omega) hnp
    have hm2 := hmf.two_le
    refine ⟨n.minFac, hm2, Nat.le_sqrt.mpr (by nlinarith), hmd, ?_⟩
    have := h2 _ hm2
    nlinarith
  · rintro ⟨⟨hn1, hnN⟩, hnp⟩
    have hn2 := hnp.two_le
    refine ⟨⟨hn2, hnN⟩, ?_⟩
    rintro ⟨d, hd2, hdN, hdn, hsd⟩
    have hdeq : d = n := by
      rcases (Nat.dvd_prime hnp).mp hdn with h | h
      · omega
      · exact h
    subst hdeq
    have := h1 d hd2
    omega
#print axioms sieveWith_eq_primes

/-- The sieve of Eratosthenes. In a corridor of lockers 1 to N, shut locker 1, then for each
door still open whose number times itself fits in the corridor, keep it and slam its multiples
from its square on. The doors still open are exactly the primes from 1 to N. -/
theorem sieve_leaves_exactly_the_primes (N : ℕ) :
    sieveWith (fun p => p * p) N = (Finset.Icc 1 N).filter Nat.Prime := by
  apply sieveWith_eq_primes
  · intro p hp; nlinarith
  · intro p hp; exact le_refl _

/-- Every composite gets slammed. A whole number above 1 that is not prime has a smallest
divisor above 1 that is prime, divides it, and times itself is no more than the number; so the
number sits at or past where that prime's pass begins. -/
theorem composite_is_hit_by_its_smallest_prime_divisor (n : ℕ) (h1 : 1 < n) (hn : ¬ n.Prime) :
    n.minFac.Prime ∧ n.minFac ∣ n ∧ n.minFac * n.minFac ≤ n := by
  have hp : n.minFac.Prime := Nat.minFac_prime (by omega)
  exact ⟨hp, Nat.minFac_dvd n, by
    have := Nat.minFac_sq_le_self (by omega) hn
    nlinarith⟩

/-- Where a pass starts does not matter. Starting each pass at the kept number doubled (slamming
every multiple after it) leaves the same doors open as starting at the kept number times itself:
every door in between was already slammed by a smaller pass. -/
theorem pass_start_at_double_gives_the_same_sieve (N : ℕ) :
    sieveWith (fun p => 2 * p) N = sieveWith (fun p => p * p) N := by
  rw [sieve_leaves_exactly_the_primes]
  apply sieveWith_eq_primes
  · intro p hp; omega
  · intro p hp; nlinarith

-- The corridor of 100: the passes run for 2 to 10, and stop because 11 × 11 = 121 is past 100.
example : passNumbers 100 = [2, 3, 4, 5, 6, 7, 8, 9, 10] ∧ 11 * 11 = 121 := by decide
-- Lockers still open, after locker 1 is shut and after each pass: 99, 50, 34, 28, 25.
example : (Finset.Icc 2 100).card = 99 := by decide
example : ([2].foldl (sievePass (fun p => p * p)) (Finset.Icc 2 100)).card = 50 := by decide
example : ([2, 3].foldl (sievePass (fun p => p * p)) (Finset.Icc 2 100)).card = 34 := by decide
example : ([2, 3, 5].foldl (sievePass (fun p => p * p)) (Finset.Icc 2 100)).card = 28 := by decide
example : (sieveWith (fun p => p * p) 100).card = 25 := by decide
-- 5's pass slams 25, 35, 55, 65, 85, 95; 7's pass slams 49, 77, 91.
example : [2, 3].foldl (sievePass (fun p => p * p)) (Finset.Icc 2 100) \
    [2, 3, 5].foldl (sievePass (fun p => p * p)) (Finset.Icc 2 100) = {25, 35, 55, 65, 85, 95} := by
  decide
example : [2, 3, 5].foldl (sievePass (fun p => p * p)) (Finset.Icc 2 100) \
    [2, 3, 5, 7].foldl (sievePass (fun p => p * p)) (Finset.Icc 2 100) = {49, 77, 91} := by
  decide
-- The 25 doors still open.
example : sieveWith (fun p => p * p) 100 =
    {2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97} := by
  decide
-- 91 = 7 × 13: its smallest divisor is 7, and 7 × 7 = 49 is at most 91.
example : (91 : ℕ) = 7 * 13 ∧ Nat.minFac 91 = 7 ∧ 7 * 7 ≤ 91 := by norm_num
-- The mistakes. Stopping after 5's pass: 28 open, and 49, 77, 91 are among them.
example : let s := [2, 3, 5].foldl (sievePass (fun p => p * p)) (Finset.Icc 2 100)
    s.card = 28 ∧ 49 ∈ s ∧ 77 ∈ s ∧ 91 ∈ s := by decide
-- Slamming each kept number too: 21 open.
example : (sieveWith (fun p => p) 100).card = 21 := by decide
-- Leaving locker 1 open: 26 open.
example : ((passNumbers 100).foldl (sievePass (fun p => p * p)) (Finset.Icc 1 100)).card = 26 := by
  decide

#print axioms sieve_leaves_exactly_the_primes
#print axioms composite_is_hit_by_its_smallest_prime_divisor
#print axioms pass_start_at_double_gives_the_same_sieve
