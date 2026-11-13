-- Regularisation: for a fixed charge, ridge's slopes have mean β − λ(G + λI)⁻¹β and covariance σ²(G + λI)⁻¹G(G + λI)⁻¹, so along each direction its error is (σ²d + λ²θ²)/(d + λ)², a small enough charge beats least squares in every direction at once, and with one measurement ridge scales the slope by d/(d + λ) while lasso soft-thresholds it, landing on exactly zero when the slope is small.
import Mathlib.Basic.Real.Sign
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.Probability.Independence.Basic
import Mathlib.Probability.Moments.Covariance
import Mathlib.Probability.Moments.Variance
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.NormNum
import Mathlib.Tactic

/-! Notation as on the card. `X` is the centred table of measurements, `n` cars by `p`
measurements, and `G = Xᵀ X`. The charge is `lam` (λ on the card; `λ` is a reserved word in
Lean). Ridge's slopes are `(G + λI)⁻¹ Xᵀ y`. `S r t = sign(r) · max(|r| − t, 0)` is the
soft-threshold. -/

open Matrix MeasureTheory ProbabilityTheory

noncomputable section

namespace RidgeLasso

variable {n p : ℕ}

/-- Ridge's slopes for prices `y` at charge `lam`: `b̂ = (G + λI)⁻¹ Xᵀ y`, with `G = Xᵀ X`. -/
def ridge (X : Matrix (Fin n) (Fin p) ℝ) (lam : ℝ) (y : Fin n → ℝ) : Fin p → ℝ :=
  (Xᵀ * X + lam • (1 : Matrix (Fin p) (Fin p) ℝ))⁻¹ *ᵥ (Xᵀ *ᵥ y)

/-- The soft-threshold `S(r, t) = sign(r) · max(|r| − t, 0)`: move `r` toward zero by `t`,
stopping at zero. -/
def softThreshold (r t : ℝ) : ℝ := Real.sign r * max (|r| - t) 0

lemma noise_moment {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (ε : Fin n → Ω → ℝ) (σ : ℝ) (hind : iIndepFun ε P) (hL2 : ∀ i, MemLp (ε i) 2 P)
    (hmean : ∀ i, ∫ ω, ε i ω ∂P = 0) (hvar : ∀ i, variance (ε i) P = σ ^ 2) (i i' : Fin n) :
    ∫ ω, ε i ω * ε i' ω ∂P = if i = i' then σ ^ 2 else 0 := by
  have hc := covariance_eq_sub (hL2 i) (hL2 i')
  rw [hmean i, hmean i', mul_zero, sub_zero] at hc
  have hc' : ∫ ω, ε i ω * ε i' ω ∂P = covariance (ε i) (ε i') P := hc.symm
  rw [hc']
  split_ifs with h
  · subst h
    rw [covariance_self (hL2 i).aestronglyMeasurable.aemeasurable, hvar]
  · exact (hind.indepFun h).covariance_eq_zero (hL2 i) (hL2 i')

lemma lin_integral {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (ε : Fin n → Ω → ℝ) (hL2 : ∀ i, MemLp (ε i) 2 P)
    (hmean : ∀ i, ∫ ω, ε i ω ∂P = 0) (c : ℝ) (w : Fin n → ℝ) :
    ∫ ω, (c + ∑ i, w i * ε i ω) ∂P = c := by
  have hint : ∀ i, Integrable (ε i) P := fun i => (hL2 i).integrable one_le_two
  rw [integral_add (integrable_const _)
      (integrable_finsetSum _ (fun i _ => (hint i).const_mul (w i))),
    integral_finsetSum _ (fun i _ => (hint i).const_mul (w i))]
  simp [integral_const_mul, hmean]

lemma lin_mul_integral {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (ε : Fin n → Ω → ℝ) (σ : ℝ) (hL2 : ∀ i, MemLp (ε i) 2 P)
    (hmean : ∀ i, ∫ ω, ε i ω ∂P = 0)
    (hmom : ∀ i i', ∫ ω, ε i ω * ε i' ω ∂P = if i = i' then σ ^ 2 else 0)
    (c c' : ℝ) (w w' : Fin n → ℝ) :
    ∫ ω, (c + ∑ i, w i * ε i ω) * (c' + ∑ i, w' i * ε i ω) ∂P =
      c * c' + σ ^ 2 * ∑ i, w i * w' i := by
  have hint : ∀ i, Integrable (ε i) P := fun i => (hL2 i).integrable one_le_two
  have hint2 : ∀ i i', Integrable (fun ω => ε i ω * ε i' ω) P :=
    fun i i' => (hL2 i).integrable_mul (hL2 i')
  have expand : ∀ ω, (c + ∑ i, w i * ε i ω) * (c' + ∑ i, w' i * ε i ω) =
      c * c' + ((∑ i, (c * w' i) * ε i ω + ∑ i, (c' * w i) * ε i ω) +
        ∑ i, ∑ i', (w i * w' i') * (ε i ω * ε i' ω)) := by
    intro ω
    rw [add_mul, mul_add, mul_add, Finset.sum_mul_sum, Finset.mul_sum, Finset.sum_mul]
    have e1 : ∀ i, c * (w' i * ε i ω) = (c * w' i) * ε i ω := fun i => by ring
    have e2 : ∀ i, w i * ε i ω * c' = (c' * w i) * ε i ω := fun i => by ring
    have e3 : ∀ i i', w i * ε i ω * (w' i' * ε i' ω) = (w i * w' i') * (ε i ω * ε i' ω) :=
      fun i i' => by ring
    simp only [e1, e2, e3]
    ring
  simp_rw [expand]
  have hA : Integrable (fun ω => ∑ i, (c * w' i) * ε i ω) P :=
    integrable_finsetSum _ (fun i _ => (hint i).const_mul _)
  have hB : Integrable (fun ω => ∑ i, (c' * w i) * ε i ω) P :=
    integrable_finsetSum _ (fun i _ => (hint i).const_mul _)
  have hC : Integrable (fun ω => ∑ i, ∑ i', (w i * w' i') * (ε i ω * ε i' ω)) P :=
    integrable_finsetSum _ (fun i _ => integrable_finsetSum _
      (fun i' _ => (hint2 i i').const_mul _))
  have hAB : Integrable (fun ω => ∑ i, (c * w' i) * ε i ω + ∑ i, (c' * w i) * ε i ω) P :=
    hA.add hB
  have hABC : Integrable (fun ω => (∑ i, (c * w' i) * ε i ω + ∑ i, (c' * w i) * ε i ω) +
      ∑ i, ∑ i', (w i * w' i') * (ε i ω * ε i' ω)) P := hAB.add hC
  rw [integral_add (integrable_const _) hABC, integral_add hAB hC,
    integral_add hA hB, integral_finsetSum _ (fun i _ => (hint i).const_mul _),
    integral_finsetSum _ (fun i _ => (hint i).const_mul _),
    integral_finsetSum _ (fun i _ => integrable_finsetSum _
      (fun i' _ => (hint2 i i').const_mul _))]
  simp_rw [integral_finsetSum _ (fun i' _ => (hint2 _ i').const_mul _), integral_const_mul,
    hmean, hmom]
  simp [Finset.mul_sum, mul_comm]
lemma softThreshold_of_gt {r t : ℝ} (ht : 0 ≤ t) (h : t < r) : softThreshold r t = r - t := by
  rw [softThreshold, Real.sign_of_pos (by linarith), abs_of_pos (by linarith),
    max_eq_left (by linarith)]; ring

lemma softThreshold_of_lt {r t : ℝ} (ht : 0 ≤ t) (h : r < -t) : softThreshold r t = r + t := by
  rw [softThreshold, Real.sign_of_neg (by linarith), abs_of_neg (by linarith),
    max_eq_left (by linarith)]; ring

lemma softThreshold_of_abs_le {r t : ℝ} (h : |r| ≤ t) : softThreshold r t = 0 := by
  rw [softThreshold, max_eq_right (by linarith)]; ring
/-- **Ridge's exact bias and variance (Why it works, detailed proof).** Fix a positive charge
`λ` and a table of measurements `X` whose columns are centred (each column adds to zero), and
write `G = Xᵀ X` and `A = G + λI`. Let the prices be `y = a₀·1 + Xβ + ε`, where the noises
`ε₁, …, εₙ` are independent, each with mean zero and the same finite variance `σ²`. Then
ridge's slopes `b̂ = A⁻¹ Xᵀ y`
* have mean `β − λ A⁻¹ β`, so their bias is `−λ A⁻¹ β`;
* have covariance `σ² A⁻¹ G A⁻¹`;
* along any unit direction `q` with `G q = d q` (strength `d`, true coordinate `θ = q·β`), have
  mean squared error `(σ² d + λ² θ²) / (d + λ)²`. -/
theorem ridge_bias_and_variance (X : Matrix (Fin n) (Fin p) ℝ) (hX : ∀ j, ∑ i, X i j = 0)
    (a₀ : ℝ) (β : Fin p → ℝ) (σ lam : ℝ) (hlam : 0 < lam)
    {Ω : Type*} [MeasurableSpace Ω] {P : Measure Ω} [IsProbabilityMeasure P]
    (ε : Fin n → Ω → ℝ) (hind : iIndepFun ε P) (hL2 : ∀ i, MemLp (ε i) 2 P)
    (hmean : ∀ i, ∫ ω, ε i ω ∂P = 0) (hvar : ∀ i, variance (ε i) P = σ ^ 2) :
    let A := Xᵀ * X + lam • (1 : Matrix (Fin p) (Fin p) ℝ)
    let bhat := fun ω => ridge X lam (fun i => a₀ + (X *ᵥ β) i + ε i ω)
    (∀ j, ∫ ω, bhat ω j ∂P = β j - lam * (A⁻¹ *ᵥ β) j) ∧
      (∀ j k, covariance (fun ω => bhat ω j) (fun ω => bhat ω k) P =
        σ ^ 2 * (A⁻¹ * (Xᵀ * X) * A⁻¹) j k) ∧
      (∀ (q : Fin p → ℝ) (d : ℝ), q ⬝ᵥ q = 1 → (Xᵀ * X) *ᵥ q = d • q →
        ∫ ω, (q ⬝ᵥ bhat ω - q ⬝ᵥ β) ^ 2 ∂P =
          (σ ^ 2 * d + lam ^ 2 * (q ⬝ᵥ β) ^ 2) / (d + lam) ^ 2) := by
  intro A bhat
  have hmom := noise_moment ε σ hind hL2 hmean hvar
  have nn : ∀ {m : ℕ} (v : Fin m → ℝ), 0 ≤ v ⬝ᵥ v :=
    fun v => Finset.sum_nonneg (fun i _ => mul_self_nonneg (v i))
  -- `A` is invertible.
  have hdet : IsUnit A.det := by
    rw [isUnit_iff_ne_zero]
    intro h0
    obtain ⟨v, hv, hAv⟩ := Matrix.exists_mulVec_eq_zero_iff.mpr h0
    have h1 : v ⬝ᵥ (A *ᵥ v) = (X *ᵥ v) ⬝ᵥ (X *ᵥ v) + lam * (v ⬝ᵥ v) := by
      simp only [A, add_mulVec, smul_mulVec, one_mulVec, dotProduct_add, dotProduct_smul,
        ← mulVec_mulVec, dotProduct_mulVec, vecMul_transpose, smul_eq_mul]
    rw [hAv, dotProduct_zero] at h1
    have h2 : 0 ≤ (X *ᵥ v) ⬝ᵥ (X *ᵥ v) := nn _
    have h3 : 0 ≤ v ⬝ᵥ v := nn _
    have h4 : v ⬝ᵥ v = 0 := by nlinarith
    exact hv (dotProduct_self_eq_zero.mp h4)
  have hinvA : A⁻¹ * A = 1 := nonsing_inv_mul A hdet
  have hAT : Aᵀ = A := by
    simp only [A, transpose_add, transpose_mul, transpose_transpose, transpose_smul,
      transpose_one]
  have hinvT : A⁻¹ᵀ = A⁻¹ := by rw [transpose_nonsing_inv, hAT]
  have hG : A⁻¹ * (Xᵀ * X) = 1 - lam • A⁻¹ := by
    have : Xᵀ * X = A - lam • (1 : Matrix (Fin p) (Fin p) ℝ) := by simp [A]
    rw [this, Matrix.mul_sub, hinvA, Matrix.mul_smul, Matrix.mul_one]
  set M := A⁻¹ * Xᵀ with hM
  set c : Fin p → ℝ := β - lam • (A⁻¹ *ᵥ β) with hc
  -- ridge's slopes are a constant plus a fixed linear map of the noise.
  have hb : ∀ ω j, bhat ω j = c j + ∑ i, M j i * ε i ω := by
    intro ω j
    have hy : (fun i => a₀ + (X *ᵥ β) i + ε i ω) =
        (fun _ => a₀) + X *ᵥ β + (fun i => ε i ω) := rfl
    have h0 : Xᵀ *ᵥ (fun _ : Fin n => a₀) = 0 := by
      ext j
      simp [mulVec, dotProduct, ← Finset.sum_mul, hX]
    have hv : bhat ω = c + M *ᵥ (fun i => ε i ω) := by
      show A⁻¹ *ᵥ (Xᵀ *ᵥ (fun i => a₀ + (X *ᵥ β) i + ε i ω)) = c + M *ᵥ (fun i => ε i ω)
      rw [hy, mulVec_add, mulVec_add, mulVec_add, h0, zero_add, mulVec_mulVec (M := Xᵀ) (N := X),
        mulVec_mulVec, mulVec_mulVec, hG, sub_mulVec, one_mulVec, smul_mulVec]
    rw [hv]
    simp [mulVec, dotProduct]
  have hmeanb : ∀ j, ∫ ω, bhat ω j ∂P = c j := by
    intro j
    simp_rw [hb]
    exact lin_integral ε hL2 hmean _ _
  refine ⟨?_, ?_, ?_⟩
  · intro j
    rw [hmeanb j]
    simp [c]
  · intro j k
    rw [covariance, hmeanb j, hmeanb k]
    have e : ∀ ω l, bhat ω l - c l = 0 + ∑ i, M l i * ε i ω := by
      intro ω l; rw [hb]; ring
    simp_rw [e]
    rw [lin_mul_integral ε σ hL2 hmean hmom, zero_mul, zero_add]
    congr 1
    have : A⁻¹ * (Xᵀ * X) * A⁻¹ = M * Mᵀ := by
      rw [hM, transpose_mul, transpose_transpose, hinvT, Matrix.mul_assoc, Matrix.mul_assoc,
        Matrix.mul_assoc]
    rw [this]
    rfl
  · intro q d hq hGq
    -- the eigen-direction facts
    have hd0 : d = (X *ᵥ q) ⬝ᵥ (X *ᵥ q) := by
      have : q ⬝ᵥ ((Xᵀ * X) *ᵥ q) = d := by rw [hGq, dotProduct_smul, hq, smul_eq_mul, mul_one]
      rw [← this, ← mulVec_mulVec, dotProduct_mulVec, vecMul_transpose]
    have hdnn : 0 ≤ d := hd0 ▸ nn _
    have hs : 0 < d + lam := by linarith
    have hAq : A *ᵥ q = (d + lam) • q := by
      simp only [A, add_mulVec, hGq, smul_mulVec, one_mulVec, add_smul]
    have hAinvq : A⁻¹ *ᵥ q = (d + lam)⁻¹ • q := by
      have : A⁻¹ *ᵥ (A *ᵥ q) = q := by rw [mulVec_mulVec, hinvA, one_mulVec]
      rw [hAq, mulVec_smul] at this
      calc A⁻¹ *ᵥ q = (d + lam)⁻¹ • ((d + lam) • A⁻¹ *ᵥ q) := by
            rw [smul_smul, inv_mul_cancel₀ hs.ne', one_smul]
        _ = (d + lam)⁻¹ • q := by rw [this]
    have hqAinv : q ᵥ* A⁻¹ = (d + lam)⁻¹ • q := by
      rw [← mulVec_transpose, hinvT, hAinvq]
    have hw : q ᵥ* M = (d + lam)⁻¹ • (X *ᵥ q) := by
      rw [hM, ← vecMul_vecMul, hqAinv, vecMul_transpose, mulVec_smul]
    have e : ∀ ω, q ⬝ᵥ bhat ω - q ⬝ᵥ β =
        (-(lam * (d + lam)⁻¹ * (q ⬝ᵥ β))) + ∑ i, (q ᵥ* M) i * ε i ω := by
      intro ω
      have hv : bhat ω = c + M *ᵥ (fun i => ε i ω) := by
        ext j; rw [hb]; simp [mulVec, dotProduct]
      rw [hv, dotProduct_add, dotProduct_mulVec, hc, dotProduct_sub, dotProduct_smul,
        dotProduct_mulVec, hqAinv, smul_dotProduct, smul_eq_mul, smul_eq_mul]
      simp only [dotProduct]
      ring
    simp_rw [e, sq]
    rw [lin_mul_integral ε σ hL2 hmean hmom, hw]
    have hsum : ∑ i, ((d + lam)⁻¹ • (X *ᵥ q)) i * ((d + lam)⁻¹ • (X *ᵥ q)) i =
        (d + lam)⁻¹ ^ 2 * d := by
      rw [hd0]
      simp only [Pi.smul_apply, smul_eq_mul, dotProduct, Finset.mul_sum]
      refine Finset.sum_congr rfl (fun i _ => by ring)
    rw [hsum]
    field_simp
    ring

/-- **Some charge always beats least squares (Step 3; Hoerl and Kennard, 1970).** Take any
number of directions with strengths `d j > 0`, any true coordinates `θ j`, and real noise
(`σ > 0`). Along direction `j`, least squares has error `σ²/d j` and ridge at charge `λ` has
error `(σ² d j + λ² θ j²)/(d j + λ)²`. Then there is a threshold `c > 0` such that every
charge strictly between `0` and `c` lowers every direction's error at once. -/
theorem small_ridge_charge_beats_least_squares (d θ : Fin p → ℝ) (hd : ∀ j, 0 < d j)
    (σ : ℝ) (hσ : 0 < σ) :
    ∃ c > 0, ∀ lam, 0 < lam → lam < c → ∀ j,
      (σ ^ 2 * d j + lam ^ 2 * θ j ^ 2) / (d j + lam) ^ 2 < σ ^ 2 / d j := by
  set S := ∑ j, θ j ^ 2 with hS
  have hS0 : 0 ≤ S := Finset.sum_nonneg (fun j _ => sq_nonneg (θ j))
  refine ⟨2 * σ ^ 2 / (S + 1), by positivity, ?_⟩
  intro lam hlam hc j
  have hdj := hd j
  have hθS : θ j ^ 2 ≤ S :=
    Finset.single_le_sum (f := fun j => θ j ^ 2) (fun j _ => sq_nonneg (θ j)) (Finset.mem_univ j)
  rw [lt_div_iff₀ (by positivity)] at hc
  have h1 : lam * θ j ^ 2 < 2 * σ ^ 2 := by nlinarith
  rw [div_lt_div_iff₀ (by positivity) hdj]
  have hσ2 : 0 < σ ^ 2 := by positivity
  nlinarith [mul_lt_mul_of_pos_left h1 (mul_pos hdj hlam), mul_pos hσ2 (mul_pos hlam hlam)]

/-- **One measurement: ridge scales, lasso soft-thresholds (Step 4).** For one measurement
with sum of squares `d > 0`, least-squares slope `z` and charge `λ ≥ 0`:
* ridge's total `d(b − z)² + λb²` has exactly one smallest point, `b = z d/(d + λ)`;
* lasso's total `d(b − z)² + λ|b|` has exactly one smallest point, `b = S(z, λ/(2d))`;
* lasso's slope is exactly zero when, and only when, `|z| ≤ λ/(2d)`. -/
theorem one_slope_ridge_scales_lasso_soft_thresholds (d z lam : ℝ) (hd : 0 < d)
    (hlam : 0 ≤ lam) :
    (∀ b, b ≠ z * d / (d + lam) →
        d * (z * d / (d + lam) - z) ^ 2 + lam * (z * d / (d + lam)) ^ 2 <
          d * (b - z) ^ 2 + lam * b ^ 2) ∧
      (∀ b, b ≠ softThreshold z (lam / (2 * d)) →
        d * (softThreshold z (lam / (2 * d)) - z) ^ 2 + lam * |softThreshold z (lam / (2 * d))| <
          d * (b - z) ^ 2 + lam * |b|) ∧
      (softThreshold z (lam / (2 * d)) = 0 ↔ |z| ≤ lam / (2 * d)) := by
  have ht : 0 ≤ lam / (2 * d) := by positivity
  have hlt : lam = 2 * d * (lam / (2 * d)) := by field_simp
  set t := lam / (2 * d) with htdef
  refine ⟨?_, ?_, ?_⟩
  · intro b hb
    have hs : 0 < d + lam := by linarith
    have key : d * (b - z) ^ 2 + lam * b ^ 2 -
        (d * (z * d / (d + lam) - z) ^ 2 + lam * (z * d / (d + lam)) ^ 2) =
        (d + lam) * (b - z * d / (d + lam)) ^ 2 := by
      field_simp; ring
    have : 0 < (d + lam) * (b - z * d / (d + lam)) ^ 2 :=
      mul_pos hs (by positivity [sub_ne_zero.mpr hb])
    linarith
  · intro b hb
    rcases lt_or_ge t z with hz | hz
    · rw [softThreshold_of_gt ht hz] at hb ⊢
      have hb' : b - (z - t) ≠ 0 := sub_ne_zero.mpr hb
      have hpos : 0 < (b - (z - t)) ^ 2 := by positivity
      rw [abs_of_pos (by linarith : 0 < z - t)]
      rw [hlt]
      nlinarith [le_abs_self b]
    rcases lt_or_ge z (-t) with hz' | hz'
    · rw [softThreshold_of_lt ht hz'] at hb ⊢
      have hb' : b - (z + t) ≠ 0 := sub_ne_zero.mpr hb
      have hpos : 0 < (b - (z + t)) ^ 2 := by positivity
      rw [abs_of_neg (by linarith : z + t < 0)]
      rw [hlt]
      nlinarith [neg_abs_le b]
    · have habs : |z| ≤ t := abs_le.mpr ⟨hz', hz⟩
      rw [softThreshold_of_abs_le habs] at hb ⊢
      have hpos : 0 < b ^ 2 := by positivity
      have hbz : b * z ≤ |b| * t := by
        calc b * z ≤ |b * z| := le_abs_self _
          _ = |b| * |z| := abs_mul _ _
          _ ≤ |b| * t := mul_le_mul_of_nonneg_left habs (abs_nonneg _)
      rw [hlt, abs_zero]
      nlinarith [mul_le_mul_of_nonneg_left hbz hd.le, mul_pos hd hpos]
  · constructor
    · intro h0
      by_contra hc
      push Not at hc
      rcases lt_or_ge 0 z with hz | hz
      · rw [abs_of_pos hz] at hc
        rw [softThreshold_of_gt ht hc] at h0; linarith
      · rw [abs_of_nonpos hz] at hc
        rw [softThreshold_of_lt ht (by linarith)] at h0; linarith
    · exact softThreshold_of_abs_le

end RidgeLasso

open RidgeLasso

/-! Worked numbers, by hand: two exact twins on three cars, centred readings −1, 0, 1 on both,
centred prices −2, 0, 2, charge 2. -/

/-- The twins' measurements: both columns read −1, 0, 1. -/
def twinX : Matrix (Fin 3) (Fin 2) ℝ := !![-1, -1; 0, 0; 1, 1]
/-- The three centred prices. -/
def twinY : Fin 3 → ℝ := ![-2, 0, 2]

-- G = [[2, 2], [2, 2]].
example : twinXᵀ * twinX = !![2, 2; 2, 2] := by
  ext i j; fin_cases i <;> fin_cases j <;>
    simp [twinX, Matrix.mul_apply, Fin.sum_univ_succ] <;> norm_num
-- Xᵀy = (4, 4).
example : twinXᵀ *ᵥ twinY = ![4, 4] := by
  ext i; fin_cases i <;> simp [twinX, twinY, Matrix.mulVec, dotProduct, Fin.sum_univ_succ] <;>
    norm_num
-- G + 2I = [[4, 2], [2, 4]], and (2/3, 2/3) solves (G + 2I) b = Xᵀy: 4b + 2b = 4.
example : !![(2 : ℝ), 2; 2, 2] + (2 : ℝ) • (1 : Matrix (Fin 2) (Fin 2) ℝ) = !![4, 2; 2, 4] := by
  ext i j; fin_cases i <;> fin_cases j <;> simp <;> norm_num
example : !![(4 : ℝ), 2; 2, 4] *ᵥ ![2 / 3, 2 / 3] = ![4, 4] := by
  ext i; fin_cases i <;> simp [Matrix.mulVec, dotProduct, Fin.sum_univ_succ] <;> norm_num
-- Ridge's slopes: 2/3 each (0.6667).
example : ridge twinX 2 twinY = ![2 / 3, 2 / 3] := by
  have hA : twinXᵀ * twinX + (2 : ℝ) • (1 : Matrix (Fin 2) (Fin 2) ℝ) = !![4, 2; 2, 4] := by
    ext i j; fin_cases i <;> fin_cases j <;>
      simp [twinX, Matrix.mul_apply, Fin.sum_univ_succ] <;> norm_num
  rw [ridge, hA, Matrix.inv_eq_left_inv (B := !![1 / 3, -1 / 6; -1 / 6, 1 / 3])]
  · ext i; fin_cases i <;> simp [twinX, twinY, Matrix.mulVec, dotProduct, Fin.sum_univ_succ] <;>
      norm_num
  · ext i j; fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, Fin.sum_univ_succ] <;>
      norm_num
-- Fit error 2 × (2 − 2 × 2/3)² = 8/9 (0.8889); ridge charge 2 × ((2/3)² + (2/3)²) = 16/9 (1.7778).
example : (2 : ℚ) * (2 - 2 * (2 / 3)) ^ 2 = 8 / 9 ∧ (2 : ℚ) * ((2 / 3) ^ 2 + (2 / 3) ^ 2) = 16 / 9 := by
  norm_num
-- Lasso, total slope s: the rate of change −4(2 − s) + 2 is zero at s = 3/2.
example : -4 * (2 - (3 / 2 : ℚ)) + 2 = 0 := by norm_num
-- Descent: the first twin, from zero, has r = 4 and takes S(4, 1)/2 = 3/2; the second's
-- r = 4 − 2 × 3/2 = 1 is not above λ/2 = 1, so it stays at 0.
example : softThreshold 4 1 / 2 = 3 / 2 ∧ softThreshold (4 - 2 * (3 / 2)) 1 = 0 := by
  constructor
  · rw [softThreshold, Real.sign_of_pos (by norm_num)]; norm_num
  · rw [softThreshold]; norm_num
-- Lasso's total 2(2 − b₁ − b₂)² + 2(|b₁| + |b₂|) is 7/2 (3.5) at (3/2, 0) and at (3/4, 3/4).
example : (2 : ℚ) * (2 - 3 / 2 - 0) ^ 2 + 2 * (|3 / 2| + |0|) = 7 / 2 ∧
    (2 : ℚ) * (2 - 3 / 4 - 3 / 4) ^ 2 + 2 * (|3 / 4| + |3 / 4|) = 7 / 2 := by
  norm_num [abs_of_pos]
-- The symbol table: S(2, 1/2) = 3/2.
example : softThreshold 2 (1 / 2) = 3 / 2 := by
  rw [softThreshold, Real.sign_of_pos (by norm_num)]; norm_num
-- The one-measurement chart, d = 40, charge 40: ridge keeps 40/(40 + 40) = 1/2 of each slope,
-- and lasso's threshold is 40/(2 × 40) = 1/2.
example : (40 : ℚ) / (40 + 40) = 1 / 2 ∧ (40 : ℚ) / (2 * 40) = 1 / 2 := by norm_num
-- Lasso's row of the chart: least-squares slopes 0, 1/2, 1, 3/2, 2, 5/2, 3 become
-- 0, 0, 1/2, 1, 3/2, 2, 5/2.
example : softThreshold 0 (1 / 2) = 0 ∧ softThreshold (1 / 2) (1 / 2) = 0 ∧
    softThreshold 1 (1 / 2) = 1 / 2 ∧ softThreshold 3 (1 / 2) = 5 / 2 := by
  refine ⟨?_, ?_, ?_, ?_⟩ <;> simp only [softThreshold] <;> norm_num [Real.sign_of_pos]

#print axioms ridge_bias_and_variance
#print axioms small_ridge_charge_beats_least_squares
#print axioms one_slope_ridge_scales_lasso_soft_thresholds
#print axioms noise_moment
#print axioms lin_integral
#print axioms lin_mul_integral
#print axioms softThreshold_of_gt
#print axioms softThreshold_of_lt
#print axioms softThreshold_of_abs_le
