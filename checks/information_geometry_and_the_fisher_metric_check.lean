-- Fisher metric: the Fisher metric of the normal family in the dials (μ, σ) is (dμ² + 2 dσ²)/σ², its curvature is −1/2 at every point, and the natural gradient is the steepest step uphill under the Fisher ruler.
import Mathlib.Probability.Distributions.Gaussian.Real
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Inverse
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Tactic.NormNum

/-! A model's dials are a list `θ : Fin n → ℝ` (for the bell curve, `θ 0 = μ` and `θ 1 = σ`).
A family of models is given by its density `p θ x` for one observation `x` and its law
`P θ`, the measure observations are drawn from. Mathlib's `gaussianReal μ v` is the bell curve
with mean `μ` and variance `v`, and `gaussianPDFReal μ v` is its density. `a ⬝ᵥ b` is the dot
product and `M *ᵥ a` a matrix times a column. -/

open MeasureTheory ProbabilityTheory Matrix

noncomputable section

namespace FisherMetric

variable {n : ℕ}

/-- The log-likelihood `ℓ(θ; x) = ln p(x; θ)` of one observation `x` under the model `θ`. -/
def logLik (p : (Fin n → ℝ) → ℝ → ℝ) (θ : Fin n → ℝ) (x : ℝ) : ℝ :=
  Real.log (p θ x)

/-- The score `∂ℓ/∂θ^i`: the slope of the log-likelihood as dial `i` turns, the others held. -/
def score (p : (Fin n → ℝ) → ℝ → ℝ) (θ : Fin n → ℝ) (i : Fin n) (x : ℝ) : ℝ :=
  deriv (fun t => logLik p (Function.update θ i t) x) (θ i)

/-- The Fisher metric `g_ij(θ) = E[∂ℓ/∂θ^i · ∂ℓ/∂θ^j]`, the average taken over observations
drawn from the model `θ` itself. -/
def fisherMetric (p : (Fin n → ℝ) → ℝ → ℝ) (P : (Fin n → ℝ) → Measure ℝ) (θ : Fin n → ℝ) :
    Matrix (Fin n) (Fin n) ℝ :=
  Matrix.of fun i j => ∫ x, score p θ i x * score p θ j x ∂(P θ)

/-- The bell-curve density with mean `μ = θ 0` and standard deviation `σ = θ 1`. -/
def normalDensity (θ : Fin 2 → ℝ) (x : ℝ) : ℝ :=
  gaussianPDFReal (θ 0) (θ 1 ^ 2).toNNReal x

/-- The bell curve with mean `μ = θ 0` and standard deviation `σ = θ 1`, as a law. -/
def normalModel (θ : Fin 2 → ℝ) : Measure ℝ :=
  gaussianReal (θ 0) (θ 1 ^ 2).toNNReal

/-- Every power of the observation is integrable under a centred bell curve. -/
lemma gauss_int_pow (v : NNReal) (k : ℕ) :
    Integrable (fun x : ℝ => x ^ k) (gaussianReal 0 v) :=
  integrable_pow_of_mem_interior_integrableExpSet (X := fun x => x) (by simp) k

/-- The `k`-th moment of a centred bell curve is the `k`-th derivative of its moment
generating function `t ↦ exp (v t² / 2)` at `0`. -/
lemma gauss_moment (v : NNReal) (k : ℕ) :
    ∫ x, x ^ k ∂(gaussianReal 0 v) =
      iteratedDeriv k (fun t : ℝ => Real.exp ((v : ℝ) * t ^ 2 / 2)) 0 := by
  have := iteratedDeriv_mgf_zero (X := fun x : ℝ => x) (μ := gaussianReal 0 v) (by simp) k
  rw [mgf_fun_id_gaussianReal] at this
  simp only [zero_mul, zero_add] at this
  rw [this]
  rfl

/-- The first four derivatives of `t ↦ exp (v t² / 2)` at `0`: `0, v, 0, 3v²`. -/
lemma gauss_derivs (v : ℝ) :
    iteratedDeriv 4 (fun t : ℝ => Real.exp (v * t ^ 2 / 2)) 0 = 3 * v ^ 2 ∧
    iteratedDeriv 3 (fun t : ℝ => Real.exp (v * t ^ 2 / 2)) 0 = 0 ∧
    iteratedDeriv 2 (fun t : ℝ => Real.exp (v * t ^ 2 / 2)) 0 = v ∧
    iteratedDeriv 1 (fun t : ℝ => Real.exp (v * t ^ 2 / 2)) 0 = 0 := by
  set f : ℝ → ℝ := fun t => Real.exp (v * t ^ 2 / 2) with hf
  have hE : ∀ t, HasDerivAt f (v * t * f t) t := by
    intro t
    have h := ((hasDerivAt_pow 2 t).const_mul v).div_const 2 |>.exp
    convert h using 1
    simp [hf]; ring
  have d1 : deriv f = fun t => v * t * f t := funext fun t => (hE t).deriv
  have d2 : deriv (fun t => v * t * f t) = fun t => (v + v ^ 2 * t ^ 2) * f t := by
    funext t
    have h := ((hasDerivAt_id t).const_mul v).mul (hE t)
    refine h.deriv.trans ?_
    simp; ring
  have d3 : deriv (fun t => (v + v ^ 2 * t ^ 2) * f t) =
      fun t => (3 * v ^ 2 * t + v ^ 3 * t ^ 3) * f t := by
    funext t
    have h := (((hasDerivAt_pow 2 t).const_mul (v ^ 2)).const_add v).mul (hE t)
    refine h.deriv.trans ?_
    simp; ring
  have d4 : deriv (fun t => (3 * v ^ 2 * t + v ^ 3 * t ^ 3) * f t) =
      fun t => (3 * v ^ 2 + 6 * v ^ 3 * t ^ 2 + v ^ 4 * t ^ 4) * f t := by
    funext t
    have h := ((((hasDerivAt_id t).const_mul (3 * v ^ 2))).add
      ((hasDerivAt_pow 3 t).const_mul (v ^ 3))).mul (hE t)
    refine h.deriv.trans ?_
    simp; ring
  simp only [iteratedDeriv_succ, iteratedDeriv_zero, d1, d2, d3, d4]
  simp [hf]

/-- The average of a quartic under a centred bell curve of variance `v`. -/
lemma gauss_poly (v : NNReal) (a b c d e : ℝ) :
    ∫ x, (a * x ^ 4 + b * x ^ 3 + c * x ^ 2 + d * x + e) ∂(gaussianReal 0 v) =
      3 * a * (v : ℝ) ^ 2 + c * v + e := by
  have I := gauss_int_pow v
  obtain ⟨h4, h3, h2, h1⟩ := gauss_derivs (v : ℝ)
  have m : ∀ k, ∫ x, x ^ k ∂(gaussianReal 0 v) =
      iteratedDeriv k (fun t : ℝ => Real.exp ((v : ℝ) * t ^ 2 / 2)) 0 := gauss_moment v
  have I1 : Integrable (fun x : ℝ => x) (gaussianReal 0 v) := by simpa using I 1
  have m1 : ∫ x, x ∂(gaussianReal 0 v) = 0 := by simp
  rw [integral_add, integral_add, integral_add, integral_add]
  · simp only [integral_const_mul, integral_const, m, h4, h3, h2]
    simp
    rw [integral_const_mul, m1]
    ring
  all_goals repeat' first
    | refine Integrable.add ?_ ?_
    | exact integrable_const _
    | exact (I _).const_mul _
    | exact I1.const_mul _

/-- The average of a quartic in `x − μ` under the bell curve with mean `μ`, variance `v`. -/
lemma gauss_poly' (μ : ℝ) (v : NNReal) (a b c d e : ℝ) :
    ∫ x, (a * (x - μ) ^ 4 + b * (x - μ) ^ 3 + c * (x - μ) ^ 2 + d * (x - μ) + e)
      ∂(gaussianReal μ v) = 3 * a * (v : ℝ) ^ 2 + c * v + e := by
  have h : ∫ x, (a * (x - μ) ^ 4 + b * (x - μ) ^ 3 + c * (x - μ) ^ 2 + d * (x - μ) + e)
      ∂(gaussianReal μ v) =
      ∫ x, (a * x ^ 4 + b * x ^ 3 + c * x ^ 2 + d * x + e) ∂(gaussianReal μ v).map (· - μ) := by
    rw [integral_map (by fun_prop) (by fun_prop)]
  rw [h, gaussianReal_map_sub_const, sub_self, gauss_poly]

/-- The score for the mean: `(x − μ)/σ²`. -/
lemma score_normal_zero (μ σ : ℝ) (hσ : 0 < σ) (x : ℝ) :
    score normalDensity ![μ, σ] 0 x = (x - μ) / σ ^ 2 := by
  have hfun : (fun t => logLik normalDensity (Function.update ![μ, σ] 0 t) x) =
      fun t => -Real.log (√(2 * Real.pi * σ ^ 2)) - (x - t) ^ 2 / (2 * σ ^ 2) := by
    funext t
    have hv : (((σ ^ 2).toNNReal : NNReal) : ℝ) = σ ^ 2 := Real.coe_toNNReal _ (by positivity)
    simp only [logLik, normalDensity, Function.update_self]
    rw [Function.update_of_ne (by decide), gaussianPDFReal]
    simp only [Matrix.cons_val_one, Matrix.cons_val_fin_one]
    rw [hv, Real.log_mul (by positivity) (Real.exp_pos _).ne', Real.log_inv, Real.log_exp]
    ring
  have hd : HasDerivAt (fun t => -Real.log (√(2 * Real.pi * σ ^ 2)) - (x - t) ^ 2 / (2 * σ ^ 2))
      ((x - μ) / σ ^ 2) μ := by
    have h := ((((hasDerivAt_id μ).const_sub x).pow 2).div_const (2 * σ ^ 2)).const_sub
      (-Real.log (√(2 * Real.pi * σ ^ 2)))
    refine h.congr_deriv ?_
    simp only [id]
    field_simp
    ring
  rw [score, hfun]
  simpa using hd.deriv

/-- The score for the spread: `−1/σ + (x − μ)²/σ³`. -/
lemma score_normal_one (μ σ : ℝ) (hσ : 0 < σ) (x : ℝ) :
    score normalDensity ![μ, σ] 1 x = -1 / σ + (x - μ) ^ 2 / σ ^ 3 := by
  have hev : (fun t => logLik normalDensity (Function.update ![μ, σ] 1 t) x) =ᶠ[nhds σ]
      fun t => -Real.log (√(2 * Real.pi)) - Real.log t - (x - μ) ^ 2 / (2 * t ^ 2) := by
    filter_upwards [eventually_gt_nhds hσ] with t ht
    have hv : (((t ^ 2).toNNReal : NNReal) : ℝ) = t ^ 2 := Real.coe_toNNReal _ (by positivity)
    simp only [logLik, normalDensity, Function.update_self]
    rw [Function.update_of_ne (by decide), gaussianPDFReal]
    simp only [Matrix.cons_val_zero]
    rw [hv, Real.log_mul (by positivity) (Real.exp_pos _).ne', Real.log_inv,
      Real.log_exp, Real.sqrt_mul (by positivity), Real.sqrt_sq ht.le,
      Real.log_mul (by positivity) ht.ne']
    ring
  have hd : HasDerivAt
      (fun t => -Real.log (√(2 * Real.pi)) - Real.log t - (x - μ) ^ 2 / (2 * t ^ 2))
      (-1 / σ + (x - μ) ^ 2 / σ ^ 3) σ := by
    have h := ((Real.hasDerivAt_log hσ.ne').const_sub (-Real.log (√(2 * Real.pi)))).sub
      ((hasDerivAt_const σ ((x - μ) ^ 2)).div ((hasDerivAt_pow 2 σ).const_mul 2)
        (by positivity))
    convert h using 1
    field_simp
    ring
  rw [score]
  simpa using hev.deriv_eq.trans hd.deriv

#print axioms gauss_int_pow
#print axioms gauss_moment
#print axioms gauss_derivs
#print axioms gauss_poly
#print axioms gauss_poly'
#print axioms score_normal_zero
#print axioms score_normal_one

/-- **The normal family's Fisher metric.** For a bell curve with mean `μ` and standard
deviation `σ > 0` (a model inside the family), the average products of the two scores are
`1/σ²` for the mean, `2/σ²` for the spread and `0` across, so
`ds² = (dμ² + 2 dσ²)/σ²`. -/
theorem fisher_metric_normal_family (μ σ : ℝ) (hσ : 0 < σ) :
    fisherMetric normalDensity normalModel ![μ, σ] = !![1 / σ ^ 2, 0; 0, 2 / σ ^ 2] := by
  have hv : (((σ ^ 2).toNNReal : NNReal) : ℝ) = σ ^ 2 := Real.coe_toNNReal _ (by positivity)
  have hP : normalModel ![μ, σ] = gaussianReal μ (σ ^ 2).toNNReal := by
    simp [normalModel]
  have hσ0 : σ ≠ 0 := hσ.ne'
  ext i j
  fin_cases i <;> fin_cases j
  · simp only [fisherMetric, Matrix.of_apply, hP]
    simp only [Fin.zero_eta, Fin.isValue, score_normal_zero μ σ hσ]
    refine (integral_congr_ae (ae_of_all _ fun x => ?_)).trans
      ((gauss_poly' μ _ 0 0 (1 / σ ^ 4) 0 0).trans ?_)
    · field_simp; ring
    · simp [hv]; field_simp
  · simp only [fisherMetric, Matrix.of_apply, hP]
    simp only [Fin.zero_eta, Fin.isValue, Fin.mk_one, score_normal_zero μ σ hσ,
      score_normal_one μ σ hσ]
    refine (integral_congr_ae (ae_of_all _ fun x => ?_)).trans
      ((gauss_poly' μ _ 0 (1 / σ ^ 5) 0 (-1 / σ ^ 3) 0).trans ?_)
    · field_simp; ring
    · simp
  · simp only [fisherMetric, Matrix.of_apply, hP]
    simp only [Fin.zero_eta, Fin.isValue, Fin.mk_one, score_normal_zero μ σ hσ,
      score_normal_one μ σ hσ]
    refine (integral_congr_ae (ae_of_all _ fun x => ?_)).trans
      ((gauss_poly' μ _ 0 (1 / σ ^ 5) 0 (-1 / σ ^ 3) 0).trans ?_)
    · field_simp; ring
    · simp
  · simp only [fisherMetric, Matrix.of_apply, hP]
    simp only [Fin.isValue, Fin.mk_one, score_normal_one μ σ hσ]
    refine (integral_congr_ae (ae_of_all _ fun x => ?_)).trans
      ((gauss_poly' μ _ (1 / σ ^ 6) 0 (-2 / σ ^ 4) 0 (1 / σ ^ 2)).trans ?_)
    · field_simp; ring
    · simp [hv]; field_simp; ring

/-- Gaussian curvature of a metric `E du² + G dv²` with no cross term, by the formula of
the Sphere, plane and hyperbolic space card:
`K = −1/(2√(EG)) · (∂_u(G_u/√(EG)) + ∂_v(E_v/√(EG)))`. -/
def curvatureNoCrossTerm (E G : ℝ → ℝ → ℝ) (u v : ℝ) : ℝ :=
  -(1 / (2 * √(E u v * G u v))) *
    (deriv (fun u' => deriv (fun u'' => G u'' v) u' / √(E u' v * G u' v)) u
      + deriv (fun v' => deriv (fun v'' => E u v'') v' / √(E u v' * G u v')) v)

/-- **The normal family is a hyperbolic plane of curvature −1/2.** In the dials `(μ, σ)`, the
Fisher metric `g₁₁ = 1/σ²`, `g₂₂ = 2/σ²`, `g₁₂ = 0` has Gaussian curvature `−1/2` at every
model with `σ > 0`. -/
theorem normal_family_curvature (μ σ : ℝ) (hσ : 0 < σ) :
    curvatureNoCrossTerm (fun _ s => 1 / s ^ 2) (fun _ s => 2 / s ^ 2) μ σ = -1 / 2 := by
  have hσ0 : σ ≠ 0 := hσ.ne'
  have hs2 : (0 : ℝ) < √2 := by positivity
  have hsq : √2 ^ 2 = 2 := Real.sq_sqrt (by norm_num)
  have hroot : ∀ s : ℝ, 0 < s → √(1 / s ^ 2 * (2 / s ^ 2)) = √2 / s ^ 2 := by
    intro s hs
    rw [show 1 / s ^ 2 * (2 / s ^ 2) = (√2 / s ^ 2) ^ 2 by rw [div_pow, hsq]; ring]
    exact Real.sqrt_sq (by positivity)
  have hEv : ∀ s : ℝ, 0 < s → deriv (fun s' : ℝ => 1 / s' ^ 2) s = -2 / s ^ 3 := by
    intro s hs
    have h := (hasDerivAt_const s (1 : ℝ)).div (hasDerivAt_pow 2 s) (by positivity)
    refine h.deriv.trans ?_
    field_simp
    ring
  have hev : (fun v' => deriv (fun v'' => (fun (_ : ℝ) (s : ℝ) => 1 / s ^ 2) μ v'') v' /
      √((fun (_ : ℝ) (s : ℝ) => 1 / s ^ 2) μ v' * (fun (_ : ℝ) (s : ℝ) => 2 / s ^ 2) μ v'))
      =ᶠ[nhds σ] fun v' => -2 / (√2 * v') := by
    filter_upwards [eventually_gt_nhds hσ] with s hs
    rw [hEv s hs, hroot s hs]
    field_simp
  have hd : HasDerivAt (fun v' : ℝ => -2 / (√2 * v')) ((0 * (√2 * σ) - -2 * (√2 * 1)) /
      (√2 * σ) ^ 2) σ :=
    (hasDerivAt_const σ (-2 : ℝ)).div ((hasDerivAt_id σ).const_mul √2) (by positivity)
  unfold curvatureNoCrossTerm
  rw [hev.deriv_eq, hd.deriv, hroot σ hσ]
  simp only [zero_div, deriv_const, zero_add]
  field_simp
  rw [hsq]
  ring

/-- **The natural gradient is the steepest way uphill.** Let the Fisher metric `g` at a model
have an inverse (so, being a Fisher matrix, it is positive definite), and let the slope of the
average log-likelihood be `grad ≠ 0`. Among all steps `δ` of Fisher length `ε > 0`, that is
`δ · g δ = ε²`, the step along the natural gradient `g⁻¹ grad`, scaled to length `ε`, raises the
average log-likelihood the most, and it is the only step of that length that does. -/
theorem natural_gradient_is_steepest (g : Matrix (Fin n) (Fin n) ℝ) (hg : g.PosDef)
    (grad : Fin n → ℝ) (hgrad : grad ≠ 0) (ε : ℝ) (hε : 0 < ε) :
    let best := (ε / √(grad ⬝ᵥ (g⁻¹ *ᵥ grad))) • (g⁻¹ *ᵥ grad)
    best ⬝ᵥ (g *ᵥ best) = ε ^ 2 ∧
      ∀ δ : Fin n → ℝ, δ ⬝ᵥ (g *ᵥ δ) = ε ^ 2 →
        grad ⬝ᵥ δ ≤ grad ⬝ᵥ best ∧ (grad ⬝ᵥ δ = grad ⬝ᵥ best → δ = best) := by
  intro best
  have hgu : IsUnit g.det := (Matrix.isUnit_iff_isUnit_det g).mp hg.isUnit
  have hT : gᵀ = g := by
    have := hg.isHermitian.eq
    rwa [Matrix.conjTranspose_eq_transpose_of_trivial] at this
  have hsym : ∀ a b : Fin n → ℝ, a ⬝ᵥ (g *ᵥ b) = b ⬝ᵥ (g *ᵥ a) := by
    intro a b
    rw [Matrix.dotProduct_mulVec, ← Matrix.mulVec_transpose, hT, dotProduct_comm]
  set h := g⁻¹ *ᵥ grad with hh
  have hgh : g *ᵥ h = grad := by
    rw [hh, Matrix.mulVec_mulVec, Matrix.mul_nonsing_inv _ hgu, Matrix.one_mulVec]
  set c := grad ⬝ᵥ h with hc
  have hcpos : 0 < c := by
    have := hg.inv.dotProduct_mulVec_pos hgrad
    simpa [star_trivial] using this
  set k := ε / √c with hk
  have hkpos : 0 < k := by positivity
  have hsc : √c ^ 2 = c := Real.sq_sqrt hcpos.le
  have hbest : best = k • h := rfl
  have hQh : h ⬝ᵥ (g *ᵥ h) = c := by rw [hgh, dotProduct_comm]
  have hQb : best ⬝ᵥ (g *ᵥ best) = ε ^ 2 := by
    rw [hbest, Matrix.mulVec_smul, smul_dotProduct, dotProduct_smul, hQh, hk, smul_eq_mul,
      smul_eq_mul]
    field_simp
    rw [hsc]
  have hgb : grad ⬝ᵥ best = k * c := by
    rw [hbest, dotProduct_smul, smul_eq_mul]
  have hgd : ∀ δ : Fin n → ℝ, grad ⬝ᵥ δ = h ⬝ᵥ (g *ᵥ δ) := by
    intro δ
    rw [hsym, hgh, dotProduct_comm]
  have hkc : k * (k * c) = ε ^ 2 := by
    rw [hk]; field_simp; rw [hsc]
  have hexp : ∀ δ : Fin n → ℝ, δ ⬝ᵥ (g *ᵥ δ) = ε ^ 2 →
      (δ - best) ⬝ᵥ (g *ᵥ (δ - best)) = 2 * ε ^ 2 - 2 * k * (grad ⬝ᵥ δ) := by
    intro δ hδ
    have h1 : best ⬝ᵥ (g *ᵥ δ) = k * (grad ⬝ᵥ δ) := by
      rw [hbest, smul_dotProduct, hgd, smul_eq_mul]
    have h2 : δ ⬝ᵥ (g *ᵥ best) = k * (grad ⬝ᵥ δ) := by rw [hsym, h1]
    rw [Matrix.mulVec_sub, sub_dotProduct, dotProduct_sub, dotProduct_sub, hδ, hQb, h1, h2]
    ring
  refine ⟨hQb, fun δ hδ => ⟨?_, fun heq => ?_⟩⟩
  · have hnn := hg.posSemidef.dotProduct_mulVec_nonneg (δ - best)
    simp only [star_trivial] at hnn
    rw [hexp δ hδ] at hnn
    rw [hgb]
    have : k * (grad ⬝ᵥ δ) ≤ k * (k * c) := by nlinarith
    exact le_of_mul_le_mul_left this hkpos
  · by_contra hne
    have hpos := hg.dotProduct_mulVec_pos (sub_ne_zero.mpr hne)
    simp only [star_trivial] at hpos
    rw [hexp δ hδ, heq, hgb] at hpos
    nlinarith

/-! Worked numbers, by hand: start at `μ = 5.600 g`, `σ = 0.050 g`; the batch has mean
`m = 5.670 g` and standard deviation `s = 0.020 g`. All values are exact fractions. -/

/-- `v = s² + (m − μ)² = 0.0053 g²`. -/
example : ((1 : ℚ) / 50) ^ 2 + (567 / 100 - 56 / 10) ^ 2 = 53 / 10000 := by norm_num

/-- The metric at `σ = 0.050 g`: `1/σ² = 400` and `2/σ² = 800` per g². -/
example : (1 : ℚ) / (1 / 20) ^ 2 = 400 ∧ (2 : ℚ) / (1 / 20) ^ 2 = 800 := by norm_num

/-- The slopes: `(m − μ)/σ² = 28` per g and `−1/σ + v/σ³ = 22.4` per g. -/
example : ((567 : ℚ) / 100 - 56 / 10) / (1 / 20) ^ 2 = 28 ∧
    -1 / ((1 : ℚ) / 20) + (53 / 10000) / (1 / 20) ^ 3 = 112 / 5 := by norm_num

/-- The natural step: `28/400 = 0.070 g` and `22.4/800 = 0.028 g`, giving the new model
`(5.670 g, 0.078 g)`, which agrees with `Δμ = m − μ` and `Δσ = (v − σ²)/(2σ)`. -/
example : (28 : ℚ) / 400 = 7 / 100 ∧ (112 / 5 : ℚ) / 800 = 7 / 250 ∧
    (56 : ℚ) / 10 + 7 / 100 = 567 / 100 ∧ (1 : ℚ) / 20 + 7 / 250 = 39 / 500 ∧
    (567 : ℚ) / 100 - 56 / 10 = 7 / 100 ∧
    ((53 : ℚ) / 10000 - (1 / 20) ^ 2) / (2 * (1 / 20)) = 7 / 250 := by norm_num

/-- The whole coin family, `p` from 0 to 1, has Fisher length `2 |arcsin √1 − arcsin √0| = π`. -/
example : 2 * |Real.arcsin (√1) - Real.arcsin (√0)| = Real.pi := by
  rw [Real.sqrt_one, Real.sqrt_zero, Real.arcsin_one, Real.arcsin_zero, sub_zero,
    abs_of_pos (by positivity)]
  ring

#print axioms fisher_metric_normal_family
#print axioms normal_family_curvature
#print axioms natural_gradient_is_steepest

end FisherMetric
