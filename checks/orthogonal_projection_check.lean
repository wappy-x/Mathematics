-- Projection: for any nonzero direction v, the shadow ((u · v) / (v · v)) v leaves a leftover perpendicular to v, it is the only such split and the strictly closest point on the line, the squared lengths add up by Pythagoras, and the same holds for a plane named by two perpendicular directions.
import Mathlib.Data.Matrix.Mul
import Mathlib.Basic.Real.Basic
import Mathlib.Data.Fin.VecNotation
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.LinearAlgebra.Matrix.DotProduct
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Positivity

/-- A nonzero real vector has positive squared length. -/
theorem dot_self_pos_of_ne_zero {n : ℕ} (v : Fin n → ℝ) (hv : v ≠ 0) : 0 < v ⬝ᵥ v := by
  have h0 : 0 ≤ v ⬝ᵥ v := Finset.sum_nonneg fun i _ => mul_self_nonneg (v i)
  have hne : v ⬝ᵥ v ≠ 0 := fun h => hv (dotProduct_self_eq_zero.mp h)
  exact lt_of_le_of_ne h0 (Ne.symm hne)

#print axioms dot_self_pos_of_ne_zero


/-- Projection onto a line. Take any vector u and any direction v that is not the zero vector,
both lists of n real numbers. Lay down t = (u · v) / (v · v) copies of v: the shadow p = t v.
Then the leftover u - p is perpendicular to v (dot product 0); this is the only split of u into
copies of v plus a leftover perpendicular to v; and p is the closest point of the line to u:
every other point s v of the line is strictly farther away in squared distance. -/
theorem projection_splits_uniquely_and_is_closest {n : ℕ} (u v : Fin n → ℝ) (hv : v ≠ 0) :
    (u - ((u ⬝ᵥ v) / (v ⬝ᵥ v)) • v) ⬝ᵥ v = 0 ∧
      (∀ s : ℝ, (u - s • v) ⬝ᵥ v = 0 → s • v = ((u ⬝ᵥ v) / (v ⬝ᵥ v)) • v) ∧
      (∀ s : ℝ, s • v ≠ ((u ⬝ᵥ v) / (v ⬝ᵥ v)) • v →
        (u - ((u ⬝ᵥ v) / (v ⬝ᵥ v)) • v) ⬝ᵥ (u - ((u ⬝ᵥ v) / (v ⬝ᵥ v)) • v) <
          (u - s • v) ⬝ᵥ (u - s • v)) := by
  have hc := dot_self_pos_of_ne_zero v hv
  have hc0 : v ⬝ᵥ v ≠ 0 := ne_of_gt hc
  simp only [sub_dotProduct, dotProduct_sub, smul_dotProduct, dotProduct_smul, smul_eq_mul,
    dotProduct_comm v u]
  refine ⟨?_, ?_, ?_⟩
  · field_simp; ring
  · intro s hs
    have : s = (u ⬝ᵥ v) / (v ⬝ᵥ v) := by
      field_simp; linarith
    rw [this]
  · intro s hs
    have hst : s ≠ (u ⬝ᵥ v) / (v ⬝ᵥ v) := fun h => hs (by rw [h])
    have hsq : 0 < (s - (u ⬝ᵥ v) / (v ⬝ᵥ v)) ^ 2 := by
      have : s - (u ⬝ᵥ v) / (v ⬝ᵥ v) ≠ 0 := sub_ne_zero.mpr hst
      positivity
    have key : u ⬝ᵥ u - s * (u ⬝ᵥ v) - (s * (u ⬝ᵥ v) - s * (s * (v ⬝ᵥ v))) -
        ((u ⬝ᵥ u) - (u ⬝ᵥ v) / (v ⬝ᵥ v) * (u ⬝ᵥ v) -
          ((u ⬝ᵥ v) / (v ⬝ᵥ v) * (u ⬝ᵥ v) -
            (u ⬝ᵥ v) / (v ⬝ᵥ v) * ((u ⬝ᵥ v) / (v ⬝ᵥ v) * (v ⬝ᵥ v)))) =
        (v ⬝ᵥ v) * (s - (u ⬝ᵥ v) / (v ⬝ᵥ v)) ^ 2 := by
      field_simp; ring
    nlinarith [mul_pos hc hsq]

/-- Pythagoras for the split. With v not the zero vector, shadow p = ((u · v) / (v · v)) v and
leftover e = u - p, the squared lengths add: u · u = p · p + e · e. -/
theorem projection_pythagoras {n : ℕ} (u v : Fin n → ℝ) (hv : v ≠ 0) :
    u ⬝ᵥ u =
      (((u ⬝ᵥ v) / (v ⬝ᵥ v)) • v) ⬝ᵥ (((u ⬝ᵥ v) / (v ⬝ᵥ v)) • v) +
        (u - ((u ⬝ᵥ v) / (v ⬝ᵥ v)) • v) ⬝ᵥ (u - ((u ⬝ᵥ v) / (v ⬝ᵥ v)) • v) := by
  have hc0 : v ⬝ᵥ v ≠ 0 := ne_of_gt (dot_self_pos_of_ne_zero v hv)
  simp only [sub_dotProduct, dotProduct_sub, smul_dotProduct, dotProduct_smul, smul_eq_mul,
    dotProduct_comm v u]
  field_simp; ring

/-- Projection onto a plane. Take two directions w₁ and w₂, neither the zero vector, that are
perpendicular (w₁ · w₂ = 0). Project u onto each and add the two shadows:
p = ((u · w₁) / (w₁ · w₁)) w₁ + ((u · w₂) / (w₂ · w₂)) w₂. Then the leftover u - p is
perpendicular to both directions, and p is the closest point of the plane to u: every other
mix a w₁ + b w₂ is strictly farther away in squared distance. -/
theorem plane_projection_perpendicular_and_closest {n : ℕ} (u w₁ w₂ : Fin n → ℝ)
    (h₁ : w₁ ≠ 0) (h₂ : w₂ ≠ 0) (hperp : w₁ ⬝ᵥ w₂ = 0) :
    (u - (((u ⬝ᵥ w₁) / (w₁ ⬝ᵥ w₁)) • w₁ + ((u ⬝ᵥ w₂) / (w₂ ⬝ᵥ w₂)) • w₂)) ⬝ᵥ w₁ = 0 ∧
      (u - (((u ⬝ᵥ w₁) / (w₁ ⬝ᵥ w₁)) • w₁ + ((u ⬝ᵥ w₂) / (w₂ ⬝ᵥ w₂)) • w₂)) ⬝ᵥ w₂ = 0 ∧
      (∀ a b : ℝ,
        a • w₁ + b • w₂ ≠ ((u ⬝ᵥ w₁) / (w₁ ⬝ᵥ w₁)) • w₁ + ((u ⬝ᵥ w₂) / (w₂ ⬝ᵥ w₂)) • w₂ →
        (u - (((u ⬝ᵥ w₁) / (w₁ ⬝ᵥ w₁)) • w₁ + ((u ⬝ᵥ w₂) / (w₂ ⬝ᵥ w₂)) • w₂)) ⬝ᵥ
            (u - (((u ⬝ᵥ w₁) / (w₁ ⬝ᵥ w₁)) • w₁ + ((u ⬝ᵥ w₂) / (w₂ ⬝ᵥ w₂)) • w₂)) <
          (u - (a • w₁ + b • w₂)) ⬝ᵥ (u - (a • w₁ + b • w₂))) := by
  have hc1 := dot_self_pos_of_ne_zero w₁ h₁
  have hc2 := dot_self_pos_of_ne_zero w₂ h₂
  have hc1' : w₁ ⬝ᵥ w₁ ≠ 0 := ne_of_gt hc1
  have hc2' : w₂ ⬝ᵥ w₂ ≠ 0 := ne_of_gt hc2
  have hperp' : w₂ ⬝ᵥ w₁ = 0 := by rw [dotProduct_comm]; exact hperp
  simp only [sub_dotProduct, dotProduct_sub, add_dotProduct, dotProduct_add, smul_dotProduct,
    dotProduct_smul, smul_eq_mul, dotProduct_comm w₁ u, dotProduct_comm w₂ u, hperp, hperp']
  refine ⟨?_, ?_, ?_⟩
  · field_simp; ring
  · field_simp; ring
  · intro a b hab
    set t₁ := (u ⬝ᵥ w₁) / (w₁ ⬝ᵥ w₁) with ht₁
    set t₂ := (u ⬝ᵥ w₂) / (w₂ ⬝ᵥ w₂) with ht₂
    have hne : a ≠ t₁ ∨ b ≠ t₂ := by
      by_contra h
      rw [not_or, not_not, not_not] at h
      exact hab (by rw [h.1, h.2])
    have hpos : 0 < (w₁ ⬝ᵥ w₁) * (a - t₁) ^ 2 + (w₂ ⬝ᵥ w₂) * (b - t₂) ^ 2 := by
      rcases hne with h | h
      · have : 0 < (a - t₁) ^ 2 := by
          have := sub_ne_zero.mpr h; positivity
        have : 0 ≤ (w₂ ⬝ᵥ w₂) * (b - t₂) ^ 2 := by positivity
        nlinarith [mul_pos hc1 ‹0 < (a - t₁) ^ 2›]
      · have : 0 < (b - t₂) ^ 2 := by
          have := sub_ne_zero.mpr h; positivity
        have : 0 ≤ (w₁ ⬝ᵥ w₁) * (a - t₁) ^ 2 := by positivity
        nlinarith [mul_pos hc2 ‹0 < (b - t₂) ^ 2›]
    have e1 : t₁ * (w₁ ⬝ᵥ w₁) = u ⬝ᵥ w₁ := by rw [ht₁]; field_simp
    have e2 : t₂ * (w₂ ⬝ᵥ w₂) = u ⬝ᵥ w₂ := by rw [ht₂]; field_simp
    rw [← e1, ← e2]
    ring_nf
    ring_nf at hpos
    linarith

-- The rower: pull u = (6, 2), heading v = (1, 1).
example : (![6, 2] : Fin 2 → ℝ) ⬝ᵥ ![1, 1] = 8 := by
  norm_num [dotProduct, Fin.sum_univ_two]

example : (![1, 1] : Fin 2 → ℝ) ⬝ᵥ ![1, 1] = 2 := by
  norm_num [dotProduct, Fin.sum_univ_two]

-- The shadow is (4, 4) and the leftover is (2, -2).
example : ((((![6, 2] : Fin 2 → ℝ) ⬝ᵥ ![1, 1]) / ((![1, 1] : Fin 2 → ℝ) ⬝ᵥ ![1, 1])) •
    (![1, 1] : Fin 2 → ℝ)) = ![4, 4] := by
  ext i; fin_cases i <;> norm_num [dotProduct, Fin.sum_univ_two]

example : (![6, 2] : Fin 2 → ℝ) - ![4, 4] = ![2, -2] := by
  ext i; fin_cases i <;> norm_num

-- The right angle, checked: 4 × 2 + 4 × (-2) = 0.
example : (![4, 4] : Fin 2 → ℝ) ⬝ᵥ ![2, -2] = 0 := by
  norm_num [dotProduct, Fin.sum_univ_two]

-- Pythagoras: 40 = 32 + 8.
example : (![6, 2] : Fin 2 → ℝ) ⬝ᵥ ![6, 2] = 40 ∧ (![4, 4] : Fin 2 → ℝ) ⬝ᵥ ![4, 4] = 32 ∧
    (![2, -2] : Fin 2 → ℝ) ⬝ᵥ ![2, -2] = 8 := by
  norm_num [dotProduct, Fin.sum_univ_two]

-- Step 2: the squared distance to t copies of (1, 1), completed to a square, bottoms out at 8.
example (t : ℝ) : (6 - t) ^ 2 + (2 - t) ^ 2 = 2 * (t - 4) ^ 2 + 8 := by
  ring

-- Step 4: pull (6, 2, 3) onto the water surface named by (1, 1, 0) and (1, -1, 0).
example : (![1, 1, 0] : Fin 3 → ℝ) ⬝ᵥ ![1, -1, 0] = 0 := by
  norm_num [dotProduct, Fin.sum_univ_succ]

example : ((((![6, 2, 3] : Fin 3 → ℝ) ⬝ᵥ ![1, 1, 0]) / ((![1, 1, 0] : Fin 3 → ℝ) ⬝ᵥ ![1, 1, 0])) •
      (![1, 1, 0] : Fin 3 → ℝ) +
    (((![6, 2, 3] : Fin 3 → ℝ) ⬝ᵥ ![1, -1, 0]) / ((![1, -1, 0] : Fin 3 → ℝ) ⬝ᵥ ![1, -1, 0])) •
      (![1, -1, 0] : Fin 3 → ℝ)) = ![6, 2, 0] := by
  ext i; fin_cases i <;> norm_num [dotProduct, Fin.sum_univ_succ]

example : (![6, 2, 3] : Fin 3 → ℝ) - ![6, 2, 0] = ![0, 0, 3] ∧
    (![0, 0, 3] : Fin 3 → ℝ) ⬝ᵥ ![1, 1, 0] = 0 ∧ (![0, 0, 3] : Fin 3 → ℝ) ⬝ᵥ ![1, -1, 0] = 0 := by
  refine ⟨?_, ?_, ?_⟩
  · ext i; fin_cases i <;> norm_num
  · norm_num [dotProduct, Fin.sum_univ_succ]
  · norm_num [dotProduct, Fin.sum_univ_succ]

#print axioms projection_splits_uniquely_and_is_closest
#print axioms projection_pythagoras
#print axioms plane_projection_perpendicular_and_closest
