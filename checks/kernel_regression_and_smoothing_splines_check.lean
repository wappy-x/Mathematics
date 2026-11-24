-- Smoothing a scatter: with bell weights, the local-linear fit reproduces any straight line exactly, the Nadaraya-Watson estimate is a weighted mean of the waits, and on a straight line its error is the slope times the weighted average distance.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Algebra.Order.BigOperators.Group.Finset
import Mathlib.Algebra.BigOperators.Field

open Finset

/-- No edge bias from the slope: weight each visit `i` at time `x i` by the bell
`w i = exp (-((x i - x₀) / h) ^ 2 / 2)`, form the sums `W₀ = ∑ w i`, `W₁ = ∑ w i (x i - x₀)`,
`W₂ = ∑ w i (x i - x₀) ^ 2`, and the local-linear weights
`ℓ i = w i (W₂ - (x i - x₀) W₁) / (W₀ W₂ - W₁ ^ 2)`.
If at least two visit times differ, then on waits lying on any straight line `α + β x`
the local-linear estimate `∑ ℓ i y i` at `x₀` equals the line's true value `α + β x₀`,
at every `x₀`, edges included. -/
theorem local_linear_reproduces_lines {ι : Type*} (s : Finset ι) (x : ι → ℝ) (x₀ h α β : ℝ)
    (hx : ∃ i ∈ s, ∃ j ∈ s, x i ≠ x j) :
    let w : ι → ℝ := fun i => Real.exp (-((x i - x₀) / h) ^ 2 / 2)
    let W₀ := ∑ i ∈ s, w i
    let W₁ := ∑ i ∈ s, w i * (x i - x₀)
    let W₂ := ∑ i ∈ s, w i * (x i - x₀) ^ 2
    let ℓ : ι → ℝ := fun i => w i * (W₂ - (x i - x₀) * W₁) / (W₀ * W₂ - W₁ ^ 2)
    ∑ i ∈ s, ℓ i * (α + β * x i) = α + β * x₀ := by
  intro w W₀ W₁ W₂ ℓ
  have hw : ∀ i, 0 < w i := fun i => Real.exp_pos _
  have h2D : 2 * (W₀ * W₂ - W₁ ^ 2) =
      ∑ i ∈ s, ∑ j ∈ s, w i * w j * ((x i - x₀) - (x j - x₀)) ^ 2 := by
    have e : ∀ i j, w i * w j * ((x i - x₀) - (x j - x₀)) ^ 2 =
        w i * (w j * (x j - x₀) ^ 2) - 2 * (w i * (x i - x₀)) * (w j * (x j - x₀))
          + w i * (x i - x₀) ^ 2 * w j := fun i j => by ring
    simp_rw [e, sum_add_distrib, sum_sub_distrib, ← mul_sum, ← sum_mul, ← mul_sum]
    simp only [W₀, W₁, W₂]
    ring
  have hD : W₀ * W₂ - W₁ ^ 2 ≠ 0 := by
    obtain ⟨i, hi, j, hj, hij⟩ := hx
    have hpos : 0 < ∑ i ∈ s, ∑ j ∈ s, w i * w j * ((x i - x₀) - (x j - x₀)) ^ 2 := by
      have hnn : ∀ a b, 0 ≤ w a * w b * ((x a - x₀) - (x b - x₀)) ^ 2 := fun a b =>
        mul_nonneg (mul_nonneg (hw a).le (hw b).le) (sq_nonneg _)
      have hterm : 0 < w i * w j * ((x i - x₀) - (x j - x₀)) ^ 2 := by
        apply mul_pos (mul_pos (hw i) (hw j))
        have : (x i - x₀) - (x j - x₀) ≠ 0 := by
          intro h0; apply hij; linarith
        positivity
      calc (0:ℝ) < w i * w j * ((x i - x₀) - (x j - x₀)) ^ 2 := hterm
        _ ≤ ∑ j ∈ s, w i * w j * ((x i - x₀) - (x j - x₀)) ^ 2 :=
          single_le_sum (f := fun b => w i * w b * ((x i - x₀) - (x b - x₀)) ^ 2)
            (fun b _ => hnn i b) hj
        _ ≤ _ := single_le_sum (f := fun a => ∑ j ∈ s, w a * w j * ((x a - x₀) - (x j - x₀)) ^ 2)
            (fun a _ => sum_nonneg (fun b _ => hnn a b)) hi
    intro h0
    rw [h0, mul_zero] at h2D
    linarith
  have e : ∀ i, ℓ i * (α + β * x i) =
      ((α + β * x₀) * W₂ * w i + (β * W₂ - (α + β * x₀) * W₁) * (w i * (x i - x₀))
        - β * W₁ * (w i * (x i - x₀) ^ 2)) / (W₀ * W₂ - W₁ ^ 2) := fun i => by
    simp only [ℓ]
    rw [div_mul_eq_mul_div]
    congr 1
    ring
  rw [sum_congr rfl (fun i _ => e i), ← sum_div, div_eq_iff hD, sum_sub_distrib,
    sum_add_distrib, ← mul_sum, ← mul_sum, ← mul_sum]
  simp only [W₀, W₁, W₂]
  ring

/-- The Nadaraya-Watson estimate is a weighted mean: with bell weights
`w i = exp (-((x i - x₀) / h) ^ 2 / 2)` and at least one visit, the estimate
`(∑ w i y i) / (∑ w i)` lies between the smallest and the largest wait used. -/
theorem nadaraya_watson_between_min_and_max {ι : Type*} (s : Finset ι) (hs : s.Nonempty)
    (x y : ι → ℝ) (x₀ h m M : ℝ) (hy : ∀ i ∈ s, m ≤ y i ∧ y i ≤ M) :
    let w : ι → ℝ := fun i => Real.exp (-((x i - x₀) / h) ^ 2 / 2)
    m ≤ (∑ i ∈ s, w i * y i) / (∑ i ∈ s, w i) ∧
      (∑ i ∈ s, w i * y i) / (∑ i ∈ s, w i) ≤ M := by
  intro w
  have hw : ∀ i, 0 < w i := fun i => Real.exp_pos _
  have hW : 0 < ∑ i ∈ s, w i := sum_pos (fun i _ => hw i) hs
  constructor
  · rw [le_div_iff₀ hW, mul_sum]
    apply sum_le_sum
    intro i hi
    rw [mul_comm]
    exact mul_le_mul_of_nonneg_left (hy i hi).1 (hw i).le
  · rw [div_le_iff₀ hW, mul_sum]
    apply sum_le_sum
    intro i hi
    rw [mul_comm M]
    exact mul_le_mul_of_nonneg_left (hy i hi).2 (hw i).le

/-- Edge bias of the plain average: on waits lying on a straight line `α + β x`, the
Nadaraya-Watson estimate at `x₀` equals the true value `α + β x₀` plus the slope `β` times the
weighted average distance `(∑ w i (x i - x₀)) / (∑ w i)` from `x₀` to the visits. -/
theorem nadaraya_watson_on_a_line {ι : Type*} (s : Finset ι) (hs : s.Nonempty)
    (x : ι → ℝ) (x₀ h α β : ℝ) :
    let w : ι → ℝ := fun i => Real.exp (-((x i - x₀) / h) ^ 2 / 2)
    (∑ i ∈ s, w i * (α + β * x i)) / (∑ i ∈ s, w i) =
      α + β * x₀ + β * ((∑ i ∈ s, w i * (x i - x₀)) / (∑ i ∈ s, w i)) := by
  intro w
  have hW : 0 < ∑ i ∈ s, w i := sum_pos (fun i _ => Real.exp_pos _) hs
  have e : ∀ i, w i * (α + β * x i) = (α + β * x₀) * w i + β * (w i * (x i - x₀)) :=
    fun i => by ring
  rw [sum_congr rfl (fun i _ => e i), sum_add_distrib, ← mul_sum, ← mul_sum]
  field_simp

#print axioms local_linear_reproduces_lines
#print axioms nadaraya_watson_between_min_and_max
#print axioms nadaraya_watson_on_a_line
