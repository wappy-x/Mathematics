-- Instrumental variables and difference-in-differences: with a 0-or-1 instrument that moves the treatment and is unrelated to the error, the Wald ratio equals the covariance ratio and both equal the effect; with no defiers the Wald ratio is the compliers' average effect; and under parallel trends the difference-in-differences is the rule's effect on the treated town.
import Mathlib.Algebra.BigOperators.Field
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Positivity

open Finset

/-- The mean of `v` over the people in `s`: the total divided by the head count. -/
noncomputable def mean {ι : Type*} (s : Finset ι) (v : ι → ℝ) : ℝ :=
  (∑ i ∈ s, v i) / s.card

/-- The covariance of `z` and `v` over `s`: the average product of their distances from
their own means. -/
noncomputable def cov {ι : Type*} (s : Finset ι) (z v : ι → ℝ) : ℝ :=
  (∑ i ∈ s, (z i - mean s z) * (v i - mean s v)) / s.card


/-- Covariance written with plain sums. -/
theorem cov_eq_sums {ι : Type*} (s : Finset ι) (z v : ι → ℝ) :
    cov s z v = ((∑ i ∈ s, z i * v i) - (∑ i ∈ s, z i) * (∑ i ∈ s, v i) / s.card) / s.card := by
  unfold cov mean
  rcases Nat.eq_zero_or_pos s.card with h | h
  · simp [h]
  · have hn : (s.card : ℝ) ≠ 0 := by positivity
    have e : ∀ i ∈ s, (z i - (∑ j ∈ s, z j) / s.card) * (v i - (∑ j ∈ s, v j) / s.card)
        = z i * v i - ((∑ j ∈ s, z j) / s.card) * v i - ((∑ j ∈ s, v j) / s.card) * z i
          + ((∑ j ∈ s, z j) / s.card) * ((∑ j ∈ s, v j) / s.card) := by
      intro i _; ring
    rw [Finset.sum_congr rfl e]
    simp only [Finset.sum_add_distrib, Finset.sum_sub_distrib, ← Finset.mul_sum,
      Finset.sum_const, nsmul_eq_mul]
    field_simp
    ring

/-- With a 0-or-1 instrument, the covariance is the group-mean gap times `n₁ n₀ / n²`. -/
theorem cov_binary {ι : Type*} (s : Finset ι) (z v : ι → ℝ)
    (hz : ∀ i ∈ s, z i = 0 ∨ z i = 1) :
    cov s z v = ((s.filter (fun i => z i = 1)).card * (s.filter (fun i => z i = 0)).card
        / (s.card : ℝ) ^ 2) *
      (mean (s.filter (fun i => z i = 1)) v - mean (s.filter (fun i => z i = 0)) v) := by
  classical
  have h1 : ∑ i ∈ s, z i * v i = ∑ i ∈ s.filter (fun i => z i = 1), v i := by
    rw [Finset.sum_filter]
    refine Finset.sum_congr rfl (fun i hi => ?_)
    rcases hz i hi with h | h <;> simp [h]
  have h2 : ∑ i ∈ s, z i = ((s.filter (fun i => z i = 1)).card : ℝ) := by
    rw [Finset.card_filter, Nat.cast_sum]
    refine Finset.sum_congr rfl (fun i hi => ?_)
    rcases hz i hi with h | h <;> simp [h]
  have hf : s.filter (fun i => ¬ z i = 1) = s.filter (fun i => z i = 0) := by
    refine Finset.filter_congr (fun i hi => ?_)
    rcases hz i hi with h | h <;> simp [h]
  have h3 : ∑ i ∈ s, v i = ∑ i ∈ s.filter (fun i => z i = 1), v i
      + ∑ i ∈ s.filter (fun i => z i = 0), v i := by
    rw [← hf, Finset.sum_filter_add_sum_filter_not]
  have h4 : (s.card : ℝ) = (s.filter (fun i => z i = 1)).card
      + (s.filter (fun i => z i = 0)).card := by
    rw [← hf]; exact_mod_cast (Finset.card_filter_add_card_filter_not (fun i => z i = 1)).symm
  rw [cov_eq_sums, h1, h2, h3, h4]
  unfold mean
  set n1 := (s.filter (fun i => z i = 1)).card with hn1
  set n0 := (s.filter (fun i => z i = 0)).card with hn0
  set S1 := ∑ i ∈ s.filter (fun i => z i = 1), v i
  set S0 := ∑ i ∈ s.filter (fun i => z i = 0), v i
  rcases Nat.eq_zero_or_pos n1 with a | a
  · have : S1 = 0 := by
      simp only [S1]; rw [Finset.card_eq_zero.mp a]; simp
    rw [this, a]; simp
  rcases Nat.eq_zero_or_pos n0 with b | b
  · have : S0 = 0 := by
      simp only [S0]; rw [Finset.card_eq_zero.mp b]; simp
    rw [this, b]
    have : (n1 : ℝ) ≠ 0 := by positivity
    field_simp
    ring
  have : (n1 : ℝ) ≠ 0 := by positivity
  have : (n0 : ℝ) ≠ 0 := by positivity
  have : (n1 : ℝ) + n0 ≠ 0 := by positivity
  field_simp
  ring

/-- The instrument gives the effect as a ratio. People `i` in `s`; `z i` is the instrument
(1 if mailed a voucher, 0 if not), `d i` the treatment, and the outcome follows the
straight-line model `y = α + β d + ε`. Independence and exclusion say the instrument has zero
covariance with the error `ε`; relevance says it has non-zero covariance with the treatment.
Then the covariance ratio `Cov(Z, Y) / Cov(Z, D)` is the effect `β`, and so is the Wald ratio:
the gap in mean outcome between the `Z = 1` and `Z = 0` groups divided by their gap in mean
treatment. -/
theorem wald_ratio_eq_effect {ι : Type*} (s : Finset ι) (z d ε y : ι → ℝ) (α β : ℝ)
    (hz : ∀ i ∈ s, z i = 0 ∨ z i = 1)
    (hy : ∀ i ∈ s, y i = α + β * d i + ε i)
    (hexcl : cov s z ε = 0)
    (hrel : cov s z d ≠ 0) :
    cov s z y / cov s z d = β ∧
      (mean (s.filter (fun i => z i = 1)) y - mean (s.filter (fun i => z i = 0)) y) /
          (mean (s.filter (fun i => z i = 1)) d - mean (s.filter (fun i => z i = 0)) d) = β := by
  have hlin : cov s z y = β * cov s z d + cov s z ε := by
    have e1 : ∑ i ∈ s, z i * y i = α * ∑ i ∈ s, z i + β * ∑ i ∈ s, z i * d i
        + ∑ i ∈ s, z i * ε i := by
      rw [Finset.mul_sum, Finset.mul_sum, ← Finset.sum_add_distrib, ← Finset.sum_add_distrib]
      exact Finset.sum_congr rfl (fun i hi => by rw [hy i hi]; ring)
    have e2 : ∑ i ∈ s, y i = α * s.card + β * ∑ i ∈ s, d i + ∑ i ∈ s, ε i := by
      rw [Finset.mul_sum, show α * (s.card : ℝ) = ∑ _i ∈ s, α by simp [mul_comm],
        ← Finset.sum_add_distrib, ← Finset.sum_add_distrib]
      exact Finset.sum_congr rfl (fun i hi => by rw [hy i hi])
    rw [cov_eq_sums, cov_eq_sums, cov_eq_sums, e1, e2]
    rcases Nat.eq_zero_or_pos s.card with h | h
    · simp [h]
    · have : (s.card : ℝ) ≠ 0 := by positivity
      field_simp
      ring
  have hyd : cov s z y = β * cov s z d := by rw [hlin, hexcl, add_zero]
  refine ⟨by rw [hyd]; field_simp, ?_⟩
  have cy := cov_binary s z y hz
  have cd := cov_binary s z d hz
  set c := ((s.filter (fun i => z i = 1)).card * (s.filter (fun i => z i = 0)).card
        / (s.card : ℝ) ^ 2)
  have hc : c ≠ 0 := by
    intro h; apply hrel; rw [cd, h, zero_mul]
  have hdd : mean (s.filter (fun i => z i = 1)) d - mean (s.filter (fun i => z i = 0)) d ≠ 0 := by
    intro h; apply hrel; rw [cd, h, mul_zero]
  rw [div_eq_iff hdd]
  apply mul_left_cancel₀ hc
  rw [← cy, hyd, cd]; ring

/-- When effects differ, the Wald ratio is the compliers' effect. Person `i` would join
(`true`) or not with no voucher, `d0 i`, and with one, `d1 i`; they would lose `y0 i` without
the gym and `y1 i` with it, so the voucher reaches weight only through joining (exclusion).
The coin gives each arm the same people, so each arm's averages are the averages over everyone
of what they would do under that arm (independence). With no defiers (nobody joins only
without a voucher) and a non-zero sign-up gap (relevance), the weight gap divided by the
sign-up gap is the average effect `y1 - y0` among compliers, those who join only with a
voucher. -/
theorem wald_ratio_eq_compliers_effect {ι : Type*} (s : Finset ι) (d0 d1 : ι → Bool)
    (y0 y1 : ι → ℝ)
    (hnodef : ∀ i ∈ s, d0 i = true → d1 i = true)
    (hrel : mean s (fun i => if d1 i then 1 else 0) - mean s (fun i => if d0 i then 1 else 0) ≠ 0) :
    (mean s (fun i => if d1 i then y1 i else y0 i) - mean s (fun i => if d0 i then y1 i else y0 i)) /
        (mean s (fun i => if d1 i then 1 else 0) - mean s (fun i => if d0 i then 1 else 0)) =
      mean (s.filter (fun i => d0 i = false ∧ d1 i = true)) (fun i => y1 i - y0 i) := by
  classical
  set C := s.filter (fun i => d0 i = false ∧ d1 i = true)
  have hnum : mean s (fun i => if d1 i then y1 i else y0 i)
      - mean s (fun i => if d0 i then y1 i else y0 i) = (∑ i ∈ C, (y1 i - y0 i)) / s.card := by
    unfold mean
    rw [← sub_div, ← Finset.sum_sub_distrib, Finset.sum_filter]
    congr 1
    refine Finset.sum_congr rfl (fun i hi => ?_)
    have := hnodef i hi
    cases h0 : d0 i <;> cases h1 : d1 i <;> simp_all
  have hden : mean s (fun i => if d1 i then (1 : ℝ) else 0)
      - mean s (fun i => if d0 i then (1 : ℝ) else 0) = (C.card : ℝ) / s.card := by
    unfold mean
    rw [← sub_div, ← Finset.sum_sub_distrib, Finset.card_filter, Nat.cast_sum]
    congr 1
    refine Finset.sum_congr rfl (fun i hi => ?_)
    have := hnodef i hi
    cases h0 : d0 i <;> cases h1 : d1 i <;> simp_all
  rw [hden] at hrel
  rw [hnum, hden]
  have hn : (s.card : ℝ) ≠ 0 := by
    intro h; apply hrel; rw [h, div_zero]
  rw [div_div_div_cancel_right₀ hn]
  rfl

/-- Difference-in-differences under parallel trends. Town A's mean goes from `aBefore` to
`aAfter` with the rule, town B's from `bBefore` to `bAfter` without it, and `aAfter0` is town
A's after-mean had there been no rule. If town A would have changed as town B did, the
difference-in-differences is the rule's effect on town A, `aAfter - aAfter0`. -/
theorem did_eq_effect_under_parallel_trends (aBefore aAfter bBefore bAfter aAfter0 : ℝ)
    (hpar : aAfter0 - aBefore = bAfter - bBefore) :
    (aAfter - aBefore) - (bAfter - bBefore) = aAfter - aAfter0 := by
  linarith

/-! ### The card's made-up numbers, exactly
Shares are in percent and kilograms in tenths, so every number is whole: always-takers 20%,
losing 10 tenths without the gym and 40 with it; compliers 30%, 5 and 35; never-takers 50%,
1 and 11. Jobs per shop in town A are 21, 20, 21; in town B 24, 23, 22. -/

-- Sign-up 20% and 50%; mean loss 1000 and 1900 (percent times tenths, that is 1.00 and
-- 1.90 kg); Wald ratio 900 / 30 = 30 tenths = 3.0 kg; average effect over everyone 2.0 kg.
example :
    (20 : ℚ) * 40 + 30 * 5 + 50 * 1 = 1000 ∧
    (20 : ℚ) * 40 + 30 * 35 + 50 * 1 = 1900 ∧
    ((1900 : ℚ) - 1000) / (50 - 20) = 30 ∧
    ((20 : ℚ) * 30 + 30 * 30 + 50 * 10) / 100 = 20 := by
  norm_num

-- Members lose 265/7 tenths (3.7857 kg), non-members 25/13 tenths (0.1923 kg).
example :
    ((10 : ℚ) * 40 + 10 * 40 + 15 * 35) / (10 + 10 + 15) = 265 / 7 ∧
    ((15 : ℚ) * 5 + 25 * 1 + 25 * 1) / (15 + 25 + 25) = 25 / 13 := by
  norm_num

-- A letter worth 15 hundredths of a kg breaks exclusion: (90 + 15) / 30 = 7/2 kg, a bias of
-- 1/2 kg at a 30-point lift and 5 kg at a 3-point lift.
example : ((90 : ℚ) + 15) / 30 = 7 / 2 ∧ (15 : ℚ) / 30 = 1 / 2 ∧ (15 : ℚ) / 3 = 5 := by
  norm_num

-- Jobs per shop: DiD +2, town A without the rule 19, placebo 0, before-and-after +1,
-- after-only -1.
example :
    ((21 : ℤ) - 20) - (22 - 23) = 2 ∧ (20 : ℤ) + (22 - 23) = 19 ∧
    ((20 : ℤ) - 21) - (23 - 24) = 0 ∧ (21 : ℤ) - 20 = 1 ∧ (21 : ℤ) - 22 = -1 := by
  decide

#print axioms cov_eq_sums
#print axioms cov_binary
#print axioms wald_ratio_eq_effect
#print axioms wald_ratio_eq_compliers_effect
#print axioms did_eq_effect_under_parallel_trends
