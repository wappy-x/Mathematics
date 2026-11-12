-- Sequential quadratic programming: the SQP step points downhill for the l1 merit function so the halving line search stops, the step solves its quadratic model, and the card's three-pump schedule draws the least power, 250 kW.
import Mathlib.Analysis.Calculus.Gradient.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.LinearAlgebra.Matrix.Symmetric
import Mathlib.Data.Matrix.Mul
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Analysis.Calculus.Deriv.Add
import Mathlib.Analysis.Calculus.Deriv.Comp

open Filter Topology Matrix
open scoped RealInnerProductSpace

lemma sqp_line_estimate {n : ℕ} (f : EuclideanSpace ℝ (Fin n) → ℝ) (a x d : EuclideanSpace ℝ (Fin n))
    (hf : HasGradientAt f a x) {ε : ℝ} (hε : 0 < ε) :
    ∀ᶠ α in 𝓝 (0 : ℝ), |f (x + α • d) - f x - α * ⟪a, d⟫| ≤ ε * |α| := by
  have hline : HasDerivAt (fun α : ℝ => x + α • d) d 0 := by
    simpa using ((hasDerivAt_id (0 : ℝ)).smul_const d).const_add x
  have hF : HasFDerivAt f (InnerProductSpace.toDual ℝ _ a) (x + (0 : ℝ) • d) := by
    simpa using hasGradientAt_iff_hasFDerivAt.mp hf
  have hD := hF.comp_hasDerivAt (0 : ℝ) hline
  have h := (hasDerivAt_iff_isLittleO.mp hD).def hε
  filter_upwards [h] with α hα
  simpa [Function.comp, InnerProductSpace.toDual_apply_apply, Real.norm_eq_abs, mul_comm] using hα

#print axioms sqp_line_estimate

/-- The SQP step is a descent direction for the merit function.
Take a point `x` with cost `f₀`, demand rule `h₁ = 0` and inequality rule `f₁ ≤ 0`,
whose gradients at `x` are `g`, `a₁`, `a₂`. Let the step `d` and new prices `ν`, `λ` solve
the KKT system `B d + ν a₁ + λ a₂ = -g`, `⟪a₁, d⟫ = -h₁ x`, `⟪a₂, d⟫ = -f₁ x`,
with `d ≠ 0`, `⟪d, B d⟫ > 0`, `λ ≥ 0` and `ρ ≥ max |ν| λ`.
Then the predicted slope `D = ⟪g, d⟫ - ρ (|h₁ x| + max 0 (f₁ x))` satisfies
`D ≤ -⟪d, B d⟫ - (ρ - |ν|) |h₁ x| - (ρ - λ) max 0 (f₁ x)` and `D < 0`, and for every small
enough step fraction `α > 0` the merit `φ = f₀ + ρ (|h₁| + max 0 f₁)` falls by at least
`10⁻⁴ α |D|`, so the halving line search stops after finitely many halvings. -/
theorem sqp_step_is_descent_for_merit {n : ℕ}
    (f₀ h₁ f₁ : EuclideanSpace ℝ (Fin n) → ℝ) (x g a₁ a₂ d : EuclideanSpace ℝ (Fin n))
    (B : EuclideanSpace ℝ (Fin n) →L[ℝ] EuclideanSpace ℝ (Fin n)) (ν lam ρ : ℝ)
    (hf₀ : HasGradientAt f₀ g x) (hh₁ : HasGradientAt h₁ a₁ x) (hf₁ : HasGradientAt f₁ a₂ x)
    (hrow1 : B d + ν • a₁ + lam • a₂ = -g)
    (hrow2 : ⟪a₁, d⟫ = -h₁ x) (hrow3 : ⟪a₂, d⟫ = -f₁ x)
    (hd : d ≠ 0) (hB : 0 < ⟪d, B d⟫) (hlam : 0 ≤ lam) (hρ : max |ν| lam ≤ ρ) :
    let φ : EuclideanSpace ℝ (Fin n) → ℝ := fun y => f₀ y + ρ * (|h₁ y| + max 0 (f₁ y))
    let D : ℝ := ⟪g, d⟫ - ρ * (|h₁ x| + max 0 (f₁ x))
    D ≤ -⟪d, B d⟫ - (ρ - |ν|) * |h₁ x| - (ρ - lam) * max 0 (f₁ x) ∧ D < 0 ∧
      ∀ᶠ α in 𝓝[>] (0 : ℝ), φ (x + α • d) ≤ φ x + 1 / 10000 * α * D := by
  intro φ D
  have hg : ⟪g, d⟫ = -⟪d, B d⟫ + ν * h₁ x + lam * f₁ x := by
    have : g = -(B d + ν • a₁ + lam • a₂) := by rw [hrow1, neg_neg]
    rw [this, inner_neg_left, inner_add_left, inner_add_left, real_inner_smul_left,
      real_inner_smul_left, hrow2, hrow3, real_inner_comm (B d) d]
    ring
  have hν : |ν| ≤ ρ := le_trans (le_max_left _ _) hρ
  have hl : lam ≤ ρ := le_trans (le_max_right _ _) hρ
  have hρ0 : 0 ≤ ρ := le_trans (abs_nonneg _) hν
  have e1 : ν * h₁ x ≤ |ν| * |h₁ x| := by
    rw [← abs_mul]; exact le_abs_self _
  have e2 : lam * f₁ x ≤ lam * max 0 (f₁ x) := mul_le_mul_of_nonneg_left (le_max_right _ _) hlam
  have hbound : D ≤ -⟪d, B d⟫ - (ρ - |ν|) * |h₁ x| - (ρ - lam) * max 0 (f₁ x) := by
    show ⟪g, d⟫ - ρ * (|h₁ x| + max 0 (f₁ x)) ≤ _
    rw [hg]; nlinarith
  have hDneg : D < 0 := by
    have : 0 ≤ (ρ - |ν|) * |h₁ x| := mul_nonneg (by linarith) (abs_nonneg _)
    have : 0 ≤ (ρ - lam) * max 0 (f₁ x) := mul_nonneg (by linarith) (le_max_left _ _)
    linarith
  refine ⟨hbound, hDneg, ?_⟩
  set E : ℝ := -D with hE
  have hE0 : 0 < E := by linarith
  set ε : ℝ := E / (2 * (1 + 2 * ρ)) with hε
  have hε0 : 0 < ε := by positivity
  have hερ : ε * (1 + 2 * ρ) = E / 2 := by
    rw [hε]; field_simp
  have L0 := sqp_line_estimate f₀ g x d hf₀ hε0
  have L1 := sqp_line_estimate h₁ a₁ x d hh₁ hε0
  have L2 := sqp_line_estimate f₁ a₂ x d hf₁ hε0
  have hIoo : Set.Ioo (0 : ℝ) 1 ∈ 𝓝[>] (0 : ℝ) := Ioo_mem_nhdsGT one_pos
  filter_upwards [nhdsWithin_le_nhds L0, nhdsWithin_le_nhds L1, nhdsWithin_le_nhds L2, hIoo]
    with α h0 h1 h2 hα
  obtain ⟨hα0, hα1⟩ := hα
  rw [abs_of_pos hα0] at h0 h1 h2
  rw [hrow2] at h1
  rw [hrow3] at h2
  have u := (abs_le.mp h0).2
  have v1 := (abs_le.mp h1).1
  have v2 := (abs_le.mp h1).2
  have w1 := (abs_le.mp h2).2
  -- |h₁ (x+αd)| ≤ (1-α)|h₁ x| + εα
  have hv : |h₁ (x + α • d)| ≤ (1 - α) * |h₁ x| + ε * α := by
    have : |(1 - α) * h₁ x| = (1 - α) * |h₁ x| := by
      rw [abs_mul, abs_of_pos (by linarith : (0:ℝ) < 1 - α)]
    have ht : |h₁ (x + α • d)| ≤ |(1 - α) * h₁ x| + |h₁ (x + α • d) - (1 - α) * h₁ x| := by
      have := abs_add_le ((1 - α) * h₁ x) (h₁ (x + α • d) - (1 - α) * h₁ x)
      simpa using this
    have hr : |h₁ (x + α • d) - (1 - α) * h₁ x| ≤ ε * α := by
      have : h₁ (x + α • d) - (1 - α) * h₁ x = h₁ (x + α • d) - h₁ x - α * -h₁ x := by ring
      rw [this]; exact h1
    linarith
  have hw : max 0 (f₁ (x + α • d)) ≤ (1 - α) * max 0 (f₁ x) + ε * α := by
    apply max_le
    · have := le_max_left 0 (f₁ x)
      have : 0 ≤ (1 - α) * max 0 (f₁ x) := mul_nonneg (by linarith) this
      nlinarith
    · have := le_max_right 0 (f₁ x)
      have : (1 - α) * f₁ x ≤ (1 - α) * max 0 (f₁ x) :=
        mul_le_mul_of_nonneg_left this (by linarith)
      linarith
  show f₀ (x + α • d) + ρ * (|h₁ (x + α • d)| + max 0 (f₁ (x + α • d))) ≤
    f₀ x + ρ * (|h₁ x| + max 0 (f₁ x)) + 1 / 10000 * α * D
  have hDdef : D = ⟪g, d⟫ - ρ * (|h₁ x| + max 0 (f₁ x)) := rfl
  have hsum : ρ * (|h₁ (x + α • d)| + max 0 (f₁ (x + α • d))) ≤
      ρ * ((1 - α) * |h₁ x| + ε * α + ((1 - α) * max 0 (f₁ x) + ε * α)) :=
    mul_le_mul_of_nonneg_left (add_le_add hv hw) hρ0
  have hED : E = -D := hE
  nlinarith [hερ, mul_pos hα0 hE0]

/-- The SQP step solves the quadratic model. If `B` is symmetric (a Hessian), `d` and the
prices `μ` solve the KKT system `B d + Jᵀ μ = -g`, `J d = -c`, and `B` curves up along every
allowed step (`zᵀ B z > 0` whenever `z ≠ 0` and `J z = 0`), then `d` is the unique minimiser of
`gᵀ d' + ½ d'ᵀ B d'` over all steps `d'` with `c + J d' = 0`. -/
theorem kkt_point_is_unique_min_of_quadratic_model {n m : ℕ}
    (B : Matrix (Fin n) (Fin n) ℝ) (J : Matrix (Fin m) (Fin n) ℝ)
    (g d : Fin n → ℝ) (c μ : Fin m → ℝ)
    (hBsymm : B.IsSymm)
    (hrow1 : B *ᵥ d + Jᵀ *ᵥ μ = -g) (hrow2 : J *ᵥ d = -c)
    (hbowl : ∀ z : Fin n → ℝ, z ≠ 0 → J *ᵥ z = 0 → 0 < z ⬝ᵥ (B *ᵥ z)) :
    ∀ d' : Fin n → ℝ, J *ᵥ d' = -c → d' ≠ d →
      g ⬝ᵥ d + 1 / 2 * (d ⬝ᵥ (B *ᵥ d)) < g ⬝ᵥ d' + 1 / 2 * (d' ⬝ᵥ (B *ᵥ d')) := by
  intro d' hd' hne
  set z := d' - d with hz
  have hz0 : z ≠ 0 := sub_ne_zero.mpr hne
  have hJz : J *ᵥ z = 0 := by rw [hz, mulVec_sub, hd', hrow2, sub_self]
  have hpos := hbowl z hz0 hJz
  have hd'eq : d' = d + z := by rw [hz]; abel
  have hsym : d ⬝ᵥ (B *ᵥ z) = z ⬝ᵥ (B *ᵥ d) := by
    rw [dotProduct_mulVec, ← mulVec_transpose, hBsymm.eq, dotProduct_comm]
  have hJ : z ⬝ᵥ (Jᵀ *ᵥ μ) = 0 := by
    rw [dotProduct_mulVec, vecMul_transpose, hJz, zero_dotProduct]
  have hBd : B *ᵥ d = -g - Jᵀ *ᵥ μ := by rw [← hrow1]; abel
  have hzBd : z ⬝ᵥ (B *ᵥ d) = -(g ⬝ᵥ z) := by
    rw [hBd, dotProduct_sub, dotProduct_neg, hJ, dotProduct_comm]; ring
  rw [hd'eq, mulVec_add, dotProduct_add, add_dotProduct, dotProduct_add, dotProduct_add,
    hsym, hzBd]
  linarith

/-- The card's answer. Pumps with power coefficients `1/50, 3/100, 1/20` kW per (L/s)² and
heads `1/10, 1/5, 2/5` m per L/s deliver flows `√(xᵢ / aᵢ)`. Running them at 50, 75 and 125 kW
meets 150 L/s of demand with at least 35 m of head and draws 250 kW, and every feasible
schedule of non-negative powers draws at least 250 kW. -/
theorem pump_schedule_least_power_is_250 :
    let a : Fin 3 → ℝ := ![1 / 50, 3 / 100, 1 / 20]
    let k : Fin 3 → ℝ := ![1 / 10, 1 / 5, 2 / 5]
    let feasible : (Fin 3 → ℝ) → Prop := fun x =>
      ∑ i, Real.sqrt (x i / a i) = 150 ∧ 35 ≤ ∑ i, k i * Real.sqrt (x i / a i)
    (feasible ![50, 75, 125] ∧ ∑ i, (![50, 75, 125] : Fin 3 → ℝ) i = 250) ∧
      ∀ x : Fin 3 → ℝ, (∀ i, 0 ≤ x i) → feasible x → 250 ≤ ∑ i, x i := by
  intro a k feasible
  have s : Real.sqrt 2500 = 50 := by
    rw [show (2500 : ℝ) = 50 ^ 2 by norm_num]; exact Real.sqrt_sq (by norm_num)
  refine ⟨⟨⟨?_, ?_⟩, ?_⟩, ?_⟩
  · simp only [a, Fin.sum_univ_three]
    norm_num [s]
  · simp only [a, k, Fin.sum_univ_three]
    norm_num [s]
  · simp only [Fin.sum_univ_three]; norm_num
  · intro x hx hf
    obtain ⟨h1, h2⟩ := hf
    simp only [a, k, Fin.sum_univ_three] at h1 h2 ⊢
    simp only [Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.cons_val_two,
      Matrix.head_cons, Matrix.tail_cons] at h1 h2
    have q0 := Real.sq_sqrt (div_nonneg (hx 0) (by norm_num : (0:ℝ) ≤ 1 / 50))
    have q1 := Real.sq_sqrt (div_nonneg (hx 1) (by norm_num : (0:ℝ) ≤ 3 / 100))
    have q2 := Real.sq_sqrt (div_nonneg (hx 2) (by norm_num : (0:ℝ) ≤ 1 / 20))
    generalize Real.sqrt (x 0 / (1 / 50)) = r0 at h1 h2 q0
    generalize Real.sqrt (x 1 / (3 / 100)) = r1 at h1 h2 q1
    generalize Real.sqrt (x 2 / (1 / 20)) = r2 at h1 h2 q2
    have e0 : x 0 = 1 / 50 * r0 ^ 2 := by rw [q0]; ring
    have e1 : x 1 = 3 / 100 * r1 ^ 2 := by rw [q1]; ring
    have e2 : x 2 = 1 / 20 * r2 ^ 2 := by rw [q2]; ring
    rw [e0, e1, e2]
    nlinarith [sq_nonneg (r0 - 50), sq_nonneg (r1 - 50), sq_nonneg (r2 - 50)]

-- Worked numbers: each pump delivers 50 L/s at the answer, so its power is aᵢ · 50².
example : (1 / 50 : ℚ) * 50 ^ 2 = 50 := by norm_num
example : (3 / 100 : ℚ) * 50 ^ 2 = 75 := by norm_num
example : (1 / 20 : ℚ) * 50 ^ 2 = 125 := by norm_num
example : (50 : ℚ) + 75 + 125 = 250 := by norm_num
-- Demand 150 L/s and head 35 m are met exactly.
example : (50 : ℚ) + 50 + 50 = 150 := by norm_num
example : (1 / 10 : ℚ) * 50 + 1 / 5 * 50 + 2 / 5 * 50 = 35 := by norm_num
-- Stationarity in flows at prices ν = 1, λ = 10: 2 aᵢ qᵢ = ν + λ kᵢ for each pump.
example : 2 * (1 / 50 : ℚ) * 50 = 1 + 10 * (1 / 10) := by norm_num
example : 2 * (3 / 100 : ℚ) * 50 = 1 + 10 * (1 / 5) := by norm_num
example : 2 * (1 / 20 : ℚ) * 50 = 1 + 10 * (2 / 5) := by norm_num

#print axioms sqp_step_is_descent_for_merit
#print axioms kkt_point_is_unique_min_of_quadratic_model
#print axioms pump_schedule_least_power_is_250
