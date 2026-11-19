-- Covectors and tensor fields: an invertible symmetric metric turns each covector into exactly one arrow, the gradient [g]⁻¹[df], and covector and metric readings do not depend on the chart.
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.LinearAlgebra.Matrix.Symmetric
import Mathlib.Data.Sym.Card
import Mathlib.Basic.Real.Basic

open Matrix

/-- A metric that can be inverted turns each covector into exactly one arrow.
In a chart, let the metric have the symmetric table `g`, with `g(u, v) = u ⬝ᵥ (g *ᵥ v)`,
and let the table be invertible. For a covector with components `α`, an arrow `v`
satisfies `g(v, w) = α(w)` for every velocity `w` exactly when `v = g⁻¹ α`.
So the gradient exists, is unique, and is `[grad f] = [g]⁻¹ [df]`. -/
theorem gradient_from_metric_unique {n : ℕ} (g : Matrix (Fin n) (Fin n) ℝ)
    (hsymm : g.IsSymm) (hinv : IsUnit g.det) (α v : Fin n → ℝ) :
    (∀ w : Fin n → ℝ, v ⬝ᵥ (g *ᵥ w) = α ⬝ᵥ w) ↔ v = g⁻¹ *ᵥ α := by
  have key : ∀ w : Fin n → ℝ, v ⬝ᵥ (g *ᵥ w) = (g *ᵥ v) ⬝ᵥ w := by
    intro w
    rw [Matrix.dotProduct_mulVec, ← Matrix.mulVec_transpose, hsymm.eq]
  constructor
  · intro h
    have hv : g *ᵥ v = α := by
      funext i
      have := h (Pi.single i 1)
      rw [key] at this
      simpa [dotProduct_single] using this
    rw [← hv, Matrix.mulVec_mulVec, Matrix.nonsing_inv_mul g hinv, Matrix.one_mulVec]
  · rintro rfl w
    rw [key, Matrix.mulVec_mulVec, Matrix.mul_nonsing_inv g hinv, Matrix.one_mulVec]

/-- A covector's reading does not depend on the chart.
Let `J` be the table of rates of the old coordinates against the new and `K` the table of
the new against the old, inverse tables in the sense `K J = 1`. Covector components move by
`α̃ = Jᵀ α` and velocity components by `ṽ = K v`; then `α̃(ṽ) = α(v)`. -/
theorem covector_reading_chart_independent {n : ℕ} (J K : Matrix (Fin n) (Fin n) ℝ)
    (hKJ : K * J = 1) (α v : Fin n → ℝ) :
    (Jᵀ *ᵥ α) ⬝ᵥ (K *ᵥ v) = α ⬝ᵥ v := by
  have hJK : J * K = 1 := mul_eq_one_comm.mp hKJ
  rw [Matrix.mulVec_transpose, ← Matrix.dotProduct_mulVec, Matrix.mulVec_mulVec, hJK,
    Matrix.one_mulVec]

/-- A metric's reading does not depend on the chart.
With the same inverse tables `J` and `K` (`K J = 1`), the metric's table moves by
`g̃ = Jᵀ g J`, one factor of `J` per slot, and velocities by `ũ = K u`, `ṽ = K v`;
then `g̃(ũ, ṽ) = g(u, v)`. -/
theorem metric_reading_chart_independent {n : ℕ} (J K g : Matrix (Fin n) (Fin n) ℝ)
    (hKJ : K * J = 1) (u v : Fin n → ℝ) :
    (K *ᵥ u) ⬝ᵥ ((Jᵀ * g * J) *ᵥ (K *ᵥ v)) = u ⬝ᵥ (g *ᵥ v) := by
  have hJK : J * K = 1 := mul_eq_one_comm.mp hKJ
  rw [Matrix.mulVec_mulVec, Matrix.mul_assoc (Jᵀ * g) J K, hJK, Matrix.mul_one,
    ← Matrix.mulVec_mulVec, Matrix.dotProduct_mulVec, Matrix.vecMul_transpose,
    Matrix.mulVec_mulVec, hJK, Matrix.one_mulVec]

-- On the globe a tensor with two velocity slots has 2 × 2 = 4 components in a chart.
example : Fintype.card (Fin 2 × Fin 2) = 4 := by decide

-- The metric, being symmetric, has 3 independent components on the globe.
example : Fintype.card (Sym2 (Fin 2)) = 3 := by
  rw [Sym2.card, Fintype.card_fin]; rfl

#print axioms gradient_from_metric_unique
#print axioms covector_reading_chart_independent
#print axioms metric_reading_chart_independent
