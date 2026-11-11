-- Exponential generating functions: multiplying two series whose counts are divided by n! gives the series of the binomial convolution, so n! times the coefficient of x^n counts the arrangements of a rack of tiles.
import Mathlib
import Mathlib.RingTheory.PowerSeries.Basic
import Mathlib.Data.Nat.Choose.Sum
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Rat.Defs
import Mathlib.Tactic.NormNum

open Finset PowerSeries

theorem egf_derivative_prod {ι : Type*} [DecidableEq ι] (s : Finset ι) (f : ι → ℚ⟦X⟧) :
    d⁄dX (∏ i ∈ s, f i) = ∑ a ∈ s, (∏ j ∈ s.erase a, f j) * d⁄dX (f a) := by
  induction s using Finset.induction_on with
  | empty => simp
  | insert a s ha ih =>
    rw [prod_insert ha, Derivation.leibniz, ih, sum_insert ha, erase_insert ha, smul_eq_mul,
      smul_eq_mul, mul_sum]
    have : ∀ b ∈ s, (∏ j ∈ (insert a s).erase b, f j) * d⁄dX (f b)
        = f a * ((∏ j ∈ s.erase b, f j) * d⁄dX (f b)) := by
      intro b hb
      have hab : a ≠ b := fun h => ha (h ▸ hb)
      rw [erase_insert_of_ne hab, prod_insert (fun h => ha (mem_of_mem_erase h)), mul_assoc]
    rw [sum_congr rfl this]
    ring

theorem egf_derivative_trunc (k : ℕ) :
    d⁄dX (mk (fun j => if j ≤ k then (1 : ℚ) / j.factorial else 0)) =
      if 1 ≤ k then mk (fun j => if j ≤ k - 1 then (1 : ℚ) / j.factorial else 0) else 0 := by
  ext n
  rw [coeff_derivative, coeff_mk]
  by_cases hk : 1 ≤ k
  · rw [if_pos hk, coeff_mk]
    by_cases hn : n + 1 ≤ k
    · rw [if_pos hn, if_pos (by omega), Nat.factorial_succ]
      push_cast
      have : (n.factorial : ℚ) ≠ 0 := by positivity
      field_simp
    · rw [if_neg hn, if_neg (by omega)]; simp
  · rw [if_neg hk, map_zero, if_neg (by omega)]; simp

theorem egf_count_cons {r n : ℕ} (a : Fin r) (w : Fin n → Fin r) (i : Fin r) :
    (univ.filter (fun p => Fin.consEquiv (fun _ => Fin r) (a, w) p = i)).card =
      (univ.filter (fun p => w p = i)).card + if a = i then 1 else 0 := by
  rw [card_filter, card_filter, Fin.sum_univ_succ]
  simp only [Fin.consEquiv_apply, Fin.cons_zero, Fin.cons_succ]
  ring

theorem egf_words_succ {r : ℕ} (m : Fin r → ℕ) (n : ℕ) :
    (univ.filter (fun w : Fin (n + 1) → Fin r =>
        ∀ i, (univ.filter (fun p => w p = i)).card ≤ m i)).card =
      ∑ a, if 1 ≤ m a then (univ.filter (fun w : Fin n → Fin r =>
        ∀ i, (univ.filter (fun p => w p = i)).card ≤ Function.update m a (m a - 1) i)).card
        else 0 := by
  rw [card_filter, ← (Fin.consEquiv (fun _ => Fin r)).sum_comp, Fintype.sum_prod_type]
  refine sum_congr rfl fun a _ => ?_
  have key : ∀ w : Fin n → Fin r,
      (∀ i, (univ.filter (fun p => (Fin.consEquiv (fun _ => Fin r) (a, w)) p = i)).card ≤ m i) ↔
        1 ≤ m a ∧ ∀ i, (univ.filter (fun p => w p = i)).card ≤ Function.update m a (m a - 1) i := by
    intro w
    simp only [egf_count_cons]
    constructor
    · intro h
      refine ⟨by have := h a; simp at this; omega, fun i => ?_⟩
      have := h i
      by_cases hia : i = a
      · subst hia; simp at this ⊢; omega
      · rw [Function.update_of_ne hia]; rw [if_neg (Ne.symm hia)] at this; omega
    · rintro ⟨h1, h⟩ i
      have := h i
      by_cases hia : i = a
      · subst hia; simp at this ⊢; omega
      · rw [Function.update_of_ne hia] at this; rw [if_neg (Ne.symm hia)]; omega
  simp only [key]
  split_ifs with h
  · simp only [h, true_and]
    rw [card_filter]
  · simp [h]

theorem egf_coeff_succ {r : ℕ} (m : Fin r → ℕ) (n : ℕ) :
    ((n + 1).factorial : ℚ) * coeff (n + 1)
        (∏ i, mk (fun j => if j ≤ m i then (1 : ℚ) / j.factorial else 0)) =
      ∑ a, if 1 ≤ m a then (n.factorial : ℚ) * coeff n
        (∏ i, mk (fun j => if j ≤ Function.update m a (m a - 1) i then (1 : ℚ) / j.factorial
          else 0)) else 0 := by
  have h : ((n + 1).factorial : ℚ) * coeff (n + 1)
        (∏ i, mk (fun j => if j ≤ m i then (1 : ℚ) / j.factorial else 0)) =
      n.factorial * coeff n (d⁄dX
        (∏ i, mk (fun j => if j ≤ m i then (1 : ℚ) / j.factorial else 0))) := by
    rw [coeff_derivative, Nat.factorial_succ]; push_cast; ring
  rw [h, egf_derivative_prod, map_sum, mul_sum]
  refine sum_congr rfl fun a _ => ?_
  rw [egf_derivative_trunc]
  split_ifs with ha
  · congr 2
    rw [← prod_erase_mul _ _ (mem_univ a), Function.update_self]
    congr 1
    refine prod_congr rfl fun j hj => ?_
    rw [Function.update_of_ne (ne_of_mem_erase hj)]
  · simp

/-- The product rule for exponential generating functions: if a first part has `a n` ways
on `n` places and a second part `b n` ways, then the product of their series
`∑ a n xⁿ / n!` and `∑ b n xⁿ / n!` is the series `∑ c n xⁿ / n!` with
`c n = ∑ₖ C(n, k) · a k · b (n - k)`, the binomial convolution. -/
theorem egf_mul_eq_egf_binomial_convolution (a b : ℕ → ℕ) :
    mk (fun n => (a n : ℚ) / n.factorial) * mk (fun n => (b n : ℚ) / n.factorial) =
      mk (fun n => ((∑ k ∈ range (n + 1), n.choose k * a k * b (n - k) : ℕ) : ℚ) / n.factorial) := by
  ext n
  rw [coeff_mul, coeff_mk, Nat.sum_antidiagonal_eq_sum_range_succ_mk]
  push_cast
  rw [sum_div]
  refine sum_congr rfl fun k hk => ?_
  simp only [coeff_mk]
  have hkn : k ≤ n := Nat.lt_succ_iff.mp (mem_range.mp hk)
  rw [Nat.cast_choose ℚ hkn]
  have h1 : (k.factorial : ℚ) ≠ 0 := by positivity
  have h2 : ((n - k).factorial : ℚ) ≠ 0 := by positivity
  have h3 : (n.factorial : ℚ) ≠ 0 := by positivity
  field_simp

/-- Handing out the places: when each part's count depends only on how many places it gets,
summing over every set `S` of places given to the first part (the rest go to the second)
gives the binomial convolution `∑ₖ C(n, k) · a k · b (n - k)`. -/
theorem hand_out_places_eq_binomial_convolution (a b : ℕ → ℕ) (n : ℕ) :
    ∑ S ∈ (univ : Finset (Fin n)).powerset, a S.card * b (n - S.card) =
      ∑ k ∈ range (n + 1), n.choose k * a k * b (n - k) := by
  rw [sum_powerset_apply_card (fun k => a k * b (n - k))]
  simp [card_univ, Fintype.card_fin, smul_eq_mul, mul_assoc]

/-- The rack: with `m i` identical tiles of letter `i`, the number of words of length `n`
(rows of `n` distinguishable places, each letter used at most `m i` times) is `n!` times the
coefficient of `xⁿ` in the product over the letters of `1 + x + x²/2! + ⋯ + x^(m i)/(m i)!`. -/
theorem rack_words_eq_factorial_mul_coeff {r : ℕ} (m : Fin r → ℕ) (n : ℕ) :
    (((univ : Finset (Fin n → Fin r)).filter
        (fun w => ∀ i, (univ.filter (fun p => w p = i)).card ≤ m i)).card : ℚ) =
      n.factorial * coeff n
        (∏ i, mk (fun j => if j ≤ m i then (1 : ℚ) / j.factorial else 0)) := by
  induction n generalizing m with
  | zero =>
    rw [coeff_zero_eq_constantCoeff_apply, map_prod]
    simp [← coeff_zero_eq_constantCoeff_apply]
  | succ n ih =>
    rw [egf_words_succ, egf_coeff_succ]
    push_cast
    refine sum_congr rfl fun a _ => ?_
    split_ifs
    · exact ih _
    · rfl

-- The rack A, A, B, B, C spells 30 four-letter words and 30 five-letter words.
example : ((univ : Finset (Fin 4 → Fin 3)).filter
    (fun w => ∀ i, (univ.filter (fun p => w p = i)).card ≤ ![2, 2, 1] i)).card = 30 := by
  decide
example : ((univ : Finset (Fin 5 → Fin 3)).filter
    (fun w => ∀ i, (univ.filter (fun p => w p = i)).card ≤ ![2, 2, 1] i)).card = 30 := by
  decide
-- 4! times the coefficient 5/4 is 30; 5! times 1/4 is 30.
example : (Nat.factorial 4 : ℚ) * (5 / 4) = 30 := by norm_num [Nat.factorial]
example : (Nat.factorial 5 : ℚ) * (1 / 4) = 30 := by norm_num [Nat.factorial]
-- All five tiles down: 5! / (2! × 2!) = 30.
example : Nat.factorial 5 / (Nat.factorial 2 * Nat.factorial 2) = 30 := by decide
-- The split at n = 4: C(4, 3) × 6 + C(4, 4) × 6 = 24 + 6 = 30.
example : Nat.choose 4 3 * 6 + Nat.choose 4 4 * 6 = 30 := by decide
-- By selection: 6 + 12 + 12 = 30.
example : Nat.factorial 4 / (Nat.factorial 2 * Nat.factorial 2) + Nat.factorial 4 / Nat.factorial 2 + Nat.factorial 4 / Nat.factorial 2 = 30 := by decide

#print axioms egf_derivative_prod
#print axioms egf_derivative_trunc
#print axioms egf_count_cons
#print axioms egf_words_succ
#print axioms egf_coeff_succ
#print axioms egf_mul_eq_egf_binomial_convolution
#print axioms hand_out_places_eq_binomial_convolution
#print axioms rack_words_eq_factorial_mul_coeff
