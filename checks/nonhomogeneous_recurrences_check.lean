-- Recurrences with a driving term: every solution of a(n) = c·a(n−1) + f(n) is one particular solution plus A·c^n for exactly one number A, so the Tower of Hanoi takes 2^n − 1 moves and the card's savings account holds 101000·1.01^n − 1000n − 101000 dollars.
import Mathlib.Basic.Real.Basic
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring

/-- Particular plus homogeneous: fix the multiplier `c` and any driving term `f`, and let
`p` be one sequence obeying the full rule `p(n) = c·p(n−1) + f(n)` for every `n ≥ 1`.
Then a sequence `a` obeys the same rule exactly when `a(n) = A·c^n + p(n)` for every `n`,
and the number `A` is then the only one that works (it is fixed by the seed `a(0)`). -/
theorem solution_eq_homogeneous_add_particular (c : ℝ) (f p : ℕ → ℝ)
    (hp : ∀ n, p (n + 1) = c * p n + f (n + 1)) (a : ℕ → ℝ) :
    (∀ n, a (n + 1) = c * a n + f (n + 1)) ↔ ∃! A : ℝ, ∀ n, a n = A * c ^ n + p n := by
  constructor
  · intro ha
    refine ⟨a 0 - p 0, ?_, ?_⟩
    · intro n
      induction n with
      | zero => simp
      | succ n ih => rw [ha n, hp n, ih]; ring
    · intro B hB
      have := hB 0
      simp at this
      rw [this]; ring
  · rintro ⟨A, hA, -⟩ n
    rw [hA (n + 1), hA n, hp n]
    ring

/-- The Tower of Hanoi count: if `h(0) = 0` and `h(n) = 2·h(n−1) + 1` for every `n ≥ 1`,
then `h(n) = 2^n − 1` for every `n`. -/
theorem hanoi_closed_form (h : ℕ → ℕ) (h0 : h 0 = 0)
    (hstep : ∀ n, h (n + 1) = 2 * h n + 1) (n : ℕ) :
    h n = 2 ^ n - 1 := by
  have key : ∀ m, h m + 1 = 2 ^ m := by
    intro m
    induction m with
    | zero => simp [h0]
    | succ m ih => rw [hstep m, pow_succ]; omega
  have := key n
  omega

/-- The savings account: if `s(0) = 0` and `s(n) = 1.01·s(n−1) + 10n` for every `n ≥ 1`
(1% a month, a deposit of `10n` dollars at the end of month `n`), then
`s(n) = 101000·1.01^n − 1000n − 101000` for every `n`. -/
theorem savings_closed_form (s : ℕ → ℝ) (h0 : s 0 = 0)
    (hstep : ∀ n, s (n + 1) = 101 / 100 * s n + 10 * ((n : ℝ) + 1)) (n : ℕ) :
    s n = 101000 * (101 / 100 : ℝ) ^ n - 1000 * n - 101000 := by
  induction n with
  | zero => simp [h0]
  | succ n ih =>
    rw [hstep n, ih]
    push_cast
    ring

-- The discs, stepped forward from h(0) = 0: 1, 3, 7, 15, 31, 63, matching 2^n − 1.
example : (List.range 6).map (fun n => Nat.rec (motive := fun _ => ℕ) 0 (fun _ h => 2 * h + 1) (n + 1))
    = [1, 3, 7, 15, 31, 63] := by decide
example : (List.range 6).map (fun n => 2 ^ (n + 1) - 1) = [1, 3, 7, 15, 31, 63] := by decide
-- Six discs: 2^6 − 1 = 63 moves.
example : 2 ^ 6 - 1 = 63 := by norm_num
-- The constant guess B = 2B + 1 gives B = −1, and A − 1 = 0 gives A = 1.
example : (-1 : ℤ) = 2 * (-1) + 1 := by norm_num
example : (1 : ℤ) * 2 ^ 0 + (-1) = 0 := by norm_num
-- The account's n parts: B = 1.01B + 10 at B = −1000; constant parts: C = −1.01B + 1.01C at C = −101000.
example : (-1000 : ℚ) = 101 / 100 * (-1000) + 10 := by norm_num
example : (-101000 : ℚ) = -(101 / 100) * (-1000) + 101 / 100 * (-101000) := by norm_num
-- The seed s(0) = 0: A − 101000 = 0 gives A = 101000.
example : (101000 : ℚ) * (101 / 100) ^ 0 - 1000 * 0 - 101000 = 0 := by norm_num
-- Twelve months: the closed form rounds to $809.33 (within half a cent).
example : (161865 / 200 : ℚ) ≤ 101000 * (101 / 100) ^ 12 - 1000 * 12 - 101000 ∧
    (101000 : ℚ) * (101 / 100) ^ 12 - 1000 * 12 - 101000 < 161867 / 200 := by norm_num
-- At 0% the deposits add up to 5n(n+1): $780 after twelve months.
example : ∑ k ∈ Finset.range 13, 10 * k = 780 ∧ 5 * 12 * (12 + 1) = 780 := by decide
-- t(n) = 2t(n−1) + 3^n from 0 runs 3, 15, 57, 195, 633, matching 3^(n+1) − 3·2^n.
example : (List.range 5).map
      (fun n => Nat.rec (motive := fun _ => ℕ) 0 (fun k t => 2 * t + 3 ^ (k + 1)) (n + 1))
    = [3, 15, 57, 195, 633] := by decide
example : (List.range 5).map (fun n => 3 ^ (n + 2) - 3 * 2 ^ (n + 1)) = [3, 15, 57, 195, 633] := by
  decide
-- Resonance: t(n) = 2t(n−1) + 2^n from 0 runs 2, 8, 24, 64, 160, matching n·2^n.
example : (List.range 5).map
      (fun n => Nat.rec (motive := fun _ => ℕ) 0 (fun k t => 2 * t + 2 ^ (k + 1)) (n + 1))
    = [2, 8, 24, 64, 160] := by decide
example : (List.range 5).map (fun n => (n + 1) * 2 ^ (n + 1)) = [2, 8, 24, 64, 160] := by decide
-- The guess B·n·2^n with B = 1 obeys the rule: n·2^n = 2·(n − 1)·2^(n−1) + 2^n.
example : ∀ n < 10, (n + 1) * 2 ^ (n + 1) = 2 * (n * 2 ^ n) + 2 ^ (n + 1) := by decide
-- Mistakes: dropping the added 1 and fitting A·2^n at one disc gives A = 1/2 and 32 moves;
-- a(n) = a(n−1) + 1 from 0 gives a(6) = 6.
example : (1 / 2 : ℚ) * 2 ^ 1 = 1 ∧ (1 / 2 : ℚ) * 2 ^ 6 = 32 := by norm_num
example : Nat.rec (motive := fun _ => ℕ) 0 (fun _ a => a + 1) 6 = 6 := by decide

#print axioms solution_eq_homogeneous_add_particular
#print axioms hanoi_closed_form
#print axioms savings_closed_form
