-- Ill-posed problems: Tikhonov's filter-factor answer is the one and only minimiser of the damped miss and solves the damped normal equations, its noise gain is capped at 1/(2λ), and the discrepancy equation has exactly one root because the residual rises with λ.
import Mathlib.LinearAlgebra.UnitaryGroup
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Analysis.Real.Sqrt
import Mathlib.Order.Monotone.Basic
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.NormNum
import Mathlib.Topology.Order.IntermediateValue
import Mathlib.Topology.Algebra.Order.Field
import Mathlib.Topology.Algebra.Monoid
import Mathlib.LinearAlgebra.Matrix.DotProduct

open Matrix

/-! ### How the card's objects are written here

The blur is a square real matrix `A` with `n` rows and columns. Its SVD is given as on the card:
`A = U * diagonal σ * Vᵀ`, where `U` and `V` are orthogonal (Mathlib's `orthogonalGroup`: their
columns are the output patterns `u_i` and input patterns `v_i`, perpendicular unit vectors) and the
stretch factors `σ i` are positive (the card's blur is square and invertible).

Vectors are functions `Fin n → ℝ`; `M *ᵥ x` is the matrix times a vector and `x ⬝ᵥ y` the dot
product, so the squared length `‖x‖²` is `x ⬝ᵥ x` and the length is `Real.sqrt (x ⬝ᵥ x)`.
The data's share along pattern `i` is `c_i = u_iᵀ b = (Uᵀ *ᵥ b) i`.

Tikhonov's answer with parameter `λ` (written `lam`) is the filtered sum
`x_λ = Σ_i f_i (c_i / σ_i) v_i = V *ᵥ (fun i => f_i * (c_i / σ_i))`, with filter factor
`f_i = σ_i² / (σ_i² + λ²)`. The damped miss is `‖A x - b‖² + λ² ‖x‖²`. -/

lemma dil_dot_self_nonneg {n : ℕ} (v : Fin n → ℝ) : 0 ≤ v ⬝ᵥ v :=
  Finset.sum_nonneg fun i _ => mul_self_nonneg (v i)

lemma dil_orth_norm {n : ℕ} (U : Matrix (Fin n) (Fin n) ℝ) (hU : Uᵀ * U = 1)
    (x : Fin n → ℝ) : (U *ᵥ x) ⬝ᵥ (U *ᵥ x) = x ⬝ᵥ x := by
  rw [dotProduct_mulVec, ← mulVec_transpose, mulVec_mulVec, hU, one_mulVec]

lemma dil_A_mulVec {n : ℕ} (A U V : Matrix (Fin n) (Fin n) ℝ) (σ : Fin n → ℝ)
    (hV : Vᵀ * V = 1) (hA : A = U * diagonal σ * Vᵀ) (w : Fin n → ℝ) :
    A *ᵥ (V *ᵥ w) = U *ᵥ (fun i => σ i * w i) := by
  subst hA
  rw [mulVec_mulVec, Matrix.mul_assoc, Matrix.mul_assoc, hV, Matrix.mul_one,
    ← mulVec_mulVec]
  congr 1
  funext i
  exact mulVec_diagonal _ _ _

lemma dil_At_mulVec {n : ℕ} (A U V : Matrix (Fin n) (Fin n) ℝ) (σ : Fin n → ℝ)
    (hU : Uᵀ * U = 1) (hA : A = U * diagonal σ * Vᵀ) (w : Fin n → ℝ) :
    Aᵀ *ᵥ (U *ᵥ w) = V *ᵥ (fun i => σ i * w i) := by
  subst hA
  rw [transpose_mul, transpose_mul, transpose_transpose, diagonal_transpose, mulVec_mulVec,
    Matrix.mul_assoc, Matrix.mul_assoc, hU, Matrix.mul_one, ← mulVec_mulVec]
  congr 1
  funext i
  exact mulVec_diagonal _ _ _

lemma dil_residual {n : ℕ} (A U V : Matrix (Fin n) (Fin n) ℝ) (σ : Fin n → ℝ)
    (hU : U * Uᵀ = 1) (hV : Vᵀ * V = 1) (hA : A = U * diagonal σ * Vᵀ)
    (w b : Fin n → ℝ) :
    A *ᵥ (V *ᵥ w) - b = U *ᵥ (fun i => σ i * w i - (Uᵀ *ᵥ b) i) := by
  rw [dil_A_mulVec A U V σ hV hA w]
  have hb : b = U *ᵥ (Uᵀ *ᵥ b) := by rw [mulVec_mulVec, hU, one_mulVec]
  conv_lhs => rw [hb]
  rw [← mulVec_sub]
  rfl

#print axioms dil_dot_self_nonneg
#print axioms dil_orth_norm
#print axioms dil_A_mulVec
#print axioms dil_At_mulVec
#print axioms dil_residual

/-- Tikhonov's filter factors (Step 3). Let `A = U diag(σ) Vᵀ` be the SVD of a square matrix, with
`U`, `V` orthogonal and every `σ_i > 0`, and let `λ > 0`. Then the filtered answer
`x_λ = Σ_i σ_i²/(σ_i² + λ²) · (u_iᵀ b / σ_i) · v_i` solves the damped normal equations
`(AᵀA + λ² I) x = Aᵀ b`, it is their only solution, and it is the one and only minimiser of the
damped miss `‖A x - b‖² + λ² ‖x‖²`: every other `x` gives a strictly larger value. -/
theorem tikhonov_filter_factors_solve_damped_least_squares {n : ℕ}
    (A U V : Matrix (Fin n) (Fin n) ℝ) (σ : Fin n → ℝ)
    (hU : U ∈ orthogonalGroup (Fin n) ℝ) (hV : V ∈ orthogonalGroup (Fin n) ℝ)
    (hA : A = U * diagonal σ * Vᵀ) (hσ : ∀ i, 0 < σ i)
    (b : Fin n → ℝ) (lam : ℝ) (hlam : 0 < lam) :
    let xlam : Fin n → ℝ :=
      V *ᵥ (fun i => σ i ^ 2 / (σ i ^ 2 + lam ^ 2) * ((Uᵀ *ᵥ b) i / σ i))
    (Aᵀ * A + lam ^ 2 • (1 : Matrix (Fin n) (Fin n) ℝ)) *ᵥ xlam = Aᵀ *ᵥ b ∧
    (∀ x : Fin n → ℝ,
      (Aᵀ * A + lam ^ 2 • (1 : Matrix (Fin n) (Fin n) ℝ)) *ᵥ x = Aᵀ *ᵥ b → x = xlam) ∧
    ∀ x : Fin n → ℝ, x ≠ xlam →
      (A *ᵥ xlam - b) ⬝ᵥ (A *ᵥ xlam - b) + lam ^ 2 * (xlam ⬝ᵥ xlam)
        < (A *ᵥ x - b) ⬝ᵥ (A *ᵥ x - b) + lam ^ 2 * (x ⬝ᵥ x) := by
  intro xlam
  have hU1 : Uᵀ * U = 1 := (mem_orthogonalGroup_iff' (Fin n) ℝ).mp hU
  have hU2 : U * Uᵀ = 1 := (mem_orthogonalGroup_iff (Fin n) ℝ).mp hU
  have hV1 : Vᵀ * V = 1 := (mem_orthogonalGroup_iff' (Fin n) ℝ).mp hV
  set w : Fin n → ℝ := fun i => σ i ^ 2 / (σ i ^ 2 + lam ^ 2) * ((Uᵀ *ᵥ b) i / σ i) with hw
  have hx : xlam = V *ᵥ w := rfl
  clear_value xlam
  subst hx
  set M := Aᵀ * A + lam ^ 2 • (1 : Matrix (Fin n) (Fin n) ℝ) with hM
  have hMv : ∀ z, M *ᵥ z = Aᵀ *ᵥ (A *ᵥ z) + lam ^ 2 • z := by
    intro z
    rw [hM, add_mulVec, smul_mulVec, one_mulVec, ← mulVec_mulVec]
  have key : ∀ z, z ⬝ᵥ (M *ᵥ z) = (A *ᵥ z) ⬝ᵥ (A *ᵥ z) + lam ^ 2 * (z ⬝ᵥ z) := by
    intro z
    rw [hMv, dotProduct_add, dotProduct_smul, dotProduct_mulVec, vecMul_transpose, smul_eq_mul]
  have hnormal : M *ᵥ (V *ᵥ w) = Aᵀ *ᵥ b := by
    have hb : U *ᵥ (Uᵀ *ᵥ b) = b := by rw [mulVec_mulVec, hU2, one_mulVec]
    conv_rhs => rw [← hb]
    rw [hMv, dil_A_mulVec A U V σ hV1 hA, dil_At_mulVec A U V σ hU1 hA,
      dil_At_mulVec A U V σ hU1 hA, ← mulVec_smul, ← mulVec_add]
    congr 1
    funext i
    have hs := hσ i
    simp only [hw, Pi.add_apply, Pi.smul_apply, smul_eq_mul]
    field_simp
  refine ⟨hnormal, ?_, ?_⟩
  · intro x hxe
    set z := x - V *ᵥ w with hz
    have hMz : M *ᵥ z = 0 := by rw [hz, mulVec_sub, hxe, hnormal, sub_self]
    have h0 := key z
    rw [hMz, dotProduct_zero] at h0
    have h1 := dil_dot_self_nonneg (A *ᵥ z)
    have h2 := dil_dot_self_nonneg z
    have hl2 : 0 < lam ^ 2 := by positivity
    have hzz : z ⬝ᵥ z = 0 := by nlinarith
    rw [dotProduct_self_eq_zero, hz, sub_eq_zero] at hzz
    exact hzz
  · intro x hne
    set z := x - V *ᵥ w with hz
    have hz0 : z ≠ 0 := by rw [hz]; exact sub_ne_zero.mpr hne
    have hzpos : 0 < z ⬝ᵥ z := lt_of_le_of_ne (dil_dot_self_nonneg z)
      (fun h => hz0 (dotProduct_self_eq_zero.mp h.symm))
    have hxz : x = V *ᵥ w + z := by rw [hz]; abel
    set r := A *ᵥ (V *ᵥ w) - b with hr
    have hcross : r ⬝ᵥ (A *ᵥ z) + lam ^ 2 * ((V *ᵥ w) ⬝ᵥ z) = 0 := by
      have h : (M *ᵥ (V *ᵥ w) - Aᵀ *ᵥ b) ⬝ᵥ z = 0 := by
        rw [hnormal, sub_self, zero_dotProduct]
      rw [← h, hMv, dotProduct_mulVec, ← mulVec_transpose, hr, mulVec_sub]
      simp only [sub_dotProduct, add_dotProduct, smul_dotProduct, smul_eq_mul]
      ring
    have hAx : A *ᵥ x - b = r + A *ᵥ z := by rw [hxz, mulVec_add, hr]; abel
    rw [hAx, hxz]
    simp only [add_dotProduct, dotProduct_add]
    rw [dotProduct_comm (A *ᵥ z) r, dotProduct_comm z (V *ᵥ w)]
    have h1 := dil_dot_self_nonneg (A *ᵥ z)
    have hl2 : 0 < lam ^ 2 := by positivity
    nlinarith

/-- Tikhonov caps the noise gain at `1/(2λ)` (Step 4). For `λ > 0`, the gain on a pattern with
stretch `σ > 0` is `f/σ = σ/(σ² + λ²)`; it is at most `1/(2λ)`, with equality exactly when
`σ = λ`. So, with `A = U diag(σ) Vᵀ` as above, adding noise `e` to the data `b` moves Tikhonov's
answer by at most `‖e‖/(2λ)`. -/
theorem tikhonov_noise_gain_at_most_one_over_two_lambda {n : ℕ}
    (A U V : Matrix (Fin n) (Fin n) ℝ) (σ : Fin n → ℝ)
    (hU : U ∈ orthogonalGroup (Fin n) ℝ) (hV : V ∈ orthogonalGroup (Fin n) ℝ)
    (hA : A = U * diagonal σ * Vᵀ) (hσ : ∀ i, 0 < σ i)
    (lam : ℝ) (hlam : 0 < lam) :
    let tik : (Fin n → ℝ) → (Fin n → ℝ) := fun d =>
      V *ᵥ (fun i => σ i ^ 2 / (σ i ^ 2 + lam ^ 2) * ((Uᵀ *ᵥ d) i / σ i))
    (∀ s : ℝ, 0 < s →
      s / (s ^ 2 + lam ^ 2) ≤ 1 / (2 * lam) ∧
      (s / (s ^ 2 + lam ^ 2) = 1 / (2 * lam) ↔ s = lam)) ∧
    ∀ b e : Fin n → ℝ,
      Real.sqrt ((tik (b + e) - tik b) ⬝ᵥ (tik (b + e) - tik b))
        ≤ Real.sqrt (e ⬝ᵥ e) / (2 * lam) := by
  intro tik
  have hU2 : U * Uᵀ = 1 := (mem_orthogonalGroup_iff (Fin n) ℝ).mp hU
  have hV1 : Vᵀ * V = 1 := (mem_orthogonalGroup_iff' (Fin n) ℝ).mp hV
  have hscalar : ∀ s : ℝ, 0 < s →
      s / (s ^ 2 + lam ^ 2) ≤ 1 / (2 * lam) ∧
      (s / (s ^ 2 + lam ^ 2) = 1 / (2 * lam) ↔ s = lam) := by
    intro s hs
    have hd : 0 < s ^ 2 + lam ^ 2 := by positivity
    have h2 : 0 < 2 * lam := by positivity
    refine ⟨?_, ?_⟩
    · rw [div_le_div_iff₀ hd h2]
      nlinarith [sq_nonneg (s - lam)]
    · rw [div_eq_div_iff hd.ne' h2.ne']
      constructor
      · intro h
        have h0 : (s - lam) ^ 2 = 0 := by nlinarith
        have := pow_eq_zero_iff (two_ne_zero) |>.mp h0
        linarith
      · intro h
        subst h
        ring
  refine ⟨hscalar, ?_⟩
  intro b e
  set c : Fin n → ℝ := Uᵀ *ᵥ e with hc
  set u : Fin n → ℝ := fun i => σ i / (σ i ^ 2 + lam ^ 2) * c i with hu
  have hdiff : tik (b + e) - tik b = V *ᵥ u := by
    simp only [tik]
    rw [← mulVec_sub]
    congr 1
    funext i
    have hs := hσ i
    simp only [hu, hc, Pi.sub_apply, mulVec_add, Pi.add_apply]
    field_simp
    ring
  rw [hdiff, dil_orth_norm V hV1]
  have hce : c ⬝ᵥ c = e ⬝ᵥ e := by
    rw [hc]
    exact dil_orth_norm Uᵀ (by rw [transpose_transpose, hU2]) e
  have hk : 0 < 1 / (2 * lam) := by positivity
  have hle : u ⬝ᵥ u ≤ (1 / (2 * lam)) ^ 2 * (c ⬝ᵥ c) := by
    simp only [dotProduct, Finset.mul_sum]
    apply Finset.sum_le_sum
    intro i _
    obtain ⟨h1, -⟩ := hscalar (σ i) (hσ i)
    have hp : 0 ≤ σ i / (σ i ^ 2 + lam ^ 2) := by have := hσ i; positivity
    have hsq : (σ i / (σ i ^ 2 + lam ^ 2)) ^ 2 ≤ (1 / (2 * lam)) ^ 2 :=
      pow_le_pow_left₀ hp h1 2
    simp only [hu]
    nlinarith [mul_self_nonneg (c i)]
  rw [Real.sqrt_le_left (by have := Real.sqrt_nonneg (e ⬝ᵥ e); positivity), div_pow,
    Real.sq_sqrt (dil_dot_self_nonneg e), ← hce]
  calc u ⬝ᵥ u ≤ (1 / (2 * lam)) ^ 2 * (c ⬝ᵥ c) := hle
    _ = c ⬝ᵥ c / (2 * lam) ^ 2 := by ring

/-- The discrepancy principle has exactly one answer (Step 6). With `A = U diag(σ) Vᵀ` as above,
the residual length `ρ(λ) = ‖A x_λ - b‖` of Tikhonov's answer rises strictly with `λ > 0`; so if
the noise target satisfies `0 < √n δ < ‖b‖`, exactly one `λ > 0` makes `ρ(λ) = √n δ`. -/
theorem discrepancy_principle_has_one_root {n : ℕ}
    (A U V : Matrix (Fin n) (Fin n) ℝ) (σ : Fin n → ℝ)
    (hU : U ∈ orthogonalGroup (Fin n) ℝ) (hV : V ∈ orthogonalGroup (Fin n) ℝ)
    (hA : A = U * diagonal σ * Vᵀ) (hσ : ∀ i, 0 < σ i)
    (b : Fin n → ℝ) (δ : ℝ)
    (hpos : 0 < Real.sqrt n * δ) (hlt : Real.sqrt n * δ < Real.sqrt (b ⬝ᵥ b)) :
    let x : ℝ → (Fin n → ℝ) := fun lam =>
      V *ᵥ (fun i => σ i ^ 2 / (σ i ^ 2 + lam ^ 2) * ((Uᵀ *ᵥ b) i / σ i))
    let ρ : ℝ → ℝ := fun lam => Real.sqrt ((A *ᵥ x lam - b) ⬝ᵥ (A *ᵥ x lam - b))
    StrictMonoOn ρ (Set.Ioi 0) ∧
    ∃! lam : ℝ, 0 < lam ∧ ρ lam = Real.sqrt n * δ := by
  intro x ρ
  have hU1 : Uᵀ * U = 1 := (mem_orthogonalGroup_iff' (Fin n) ℝ).mp hU
  have hU2 : U * Uᵀ = 1 := (mem_orthogonalGroup_iff (Fin n) ℝ).mp hU
  have hV1 : Vᵀ * V = 1 := (mem_orthogonalGroup_iff' (Fin n) ℝ).mp hV
  set c : Fin n → ℝ := Uᵀ *ᵥ b with hc
  set G : ℝ → ℝ := fun lam => ∑ i, (lam ^ 2 / (σ i ^ 2 + lam ^ 2) * c i) ^ 2 with hG
  have hden : ∀ i (lam : ℝ), 0 < σ i ^ 2 + lam ^ 2 := fun i lam => by
    have := hσ i; positivity
  have hρG : ρ = fun lam => Real.sqrt (G lam) := by
    funext lam
    simp only [ρ, x]
    rw [dil_residual A U V σ hU2 hV1 hA, dil_orth_norm U hU1]
    congr 1
    simp only [hG, dotProduct]
    apply Finset.sum_congr rfl
    intro i _
    have hs := hσ i
    have hd := hden i lam
    rw [← hc]
    field_simp
    ring
  have hGnn : ∀ lam, 0 ≤ G lam := fun lam => Finset.sum_nonneg fun i _ => sq_nonneg _
  have hbc : b ⬝ᵥ b = ∑ i, c i ^ 2 := by
    rw [← dil_orth_norm Uᵀ (by rw [transpose_transpose, hU2]) b, ← hc]
    simp only [dotProduct, sq]
  set t := Real.sqrt n * δ with ht
  have ht2 : t ^ 2 < ∑ i, c i ^ 2 := by
    rw [← hbc]
    have := (Real.lt_sqrt hpos.le).mp hlt
    exact this
  have hci : ∃ i, c i ≠ 0 := by
    by_contra h
    push Not at h
    have : ∑ i, c i ^ 2 = 0 := Finset.sum_eq_zero fun i _ => by rw [h i]; ring
    nlinarith [sq_nonneg t]
  -- each filter ratio rises strictly with lam > 0
  have hratio : ∀ i (a b' : ℝ), 0 < a → a < b' →
      a ^ 2 / (σ i ^ 2 + a ^ 2) < b' ^ 2 / (σ i ^ 2 + b' ^ 2) := by
    intro i a b' ha hab
    have hs := hσ i
    rw [div_lt_div_iff₀ (hden i a) (hden i b')]
    have : a ^ 2 < b' ^ 2 := by nlinarith
    nlinarith [sq_nonneg (σ i), mul_pos (pow_pos hs 2) (sub_pos.mpr this)]
  have hGmono : StrictMonoOn G (Set.Ioi 0) := by
    intro a ha b' hb' hab
    simp only [Set.mem_Ioi] at ha hb'
    obtain ⟨j, hj⟩ := hci
    apply Finset.sum_lt_sum
    · intro i _
      have h1 := hratio i a b' ha hab
      have h0 : 0 ≤ a ^ 2 / (σ i ^ 2 + a ^ 2) := by have := hden i a; positivity
      rw [mul_pow, mul_pow]
      apply mul_le_mul_of_nonneg_right _ (sq_nonneg _)
      exact pow_le_pow_left₀ h0 h1.le 2
    · refine ⟨j, Finset.mem_univ _, ?_⟩
      have h1 := hratio j a b' ha hab
      have h0 : 0 ≤ a ^ 2 / (σ j ^ 2 + a ^ 2) := by have := hden j a; positivity
      rw [mul_pow, mul_pow]
      apply mul_lt_mul_of_pos_right _ (by positivity)
      exact pow_lt_pow_left₀ h1 h0 two_ne_zero
  have hρmono : StrictMonoOn ρ (Set.Ioi 0) := by
    rw [hρG]
    intro a ha b' hb' hab
    exact Real.sqrt_lt_sqrt (hGnn a) (hGmono ha hb' hab)
  refine ⟨hρmono, ?_⟩
  -- continuity and the limit at infinity
  have hGcont : Continuous G := by
    simp only [hG]
    refine continuous_finsetSum _ fun i _ => ?_
    refine ((Continuous.div (continuous_pow 2) (continuous_const.add (continuous_pow 2))
      fun lam => (hden i lam).ne').mul continuous_const).pow 2
  have hGlim : Filter.Tendsto G Filter.atTop (nhds (∑ i, c i ^ 2)) := by
    simp only [hG]
    refine tendsto_finsetSum _ fun i _ => ?_
    have h1 : Filter.Tendsto (fun lam : ℝ => σ i ^ 2 + lam ^ 2) Filter.atTop Filter.atTop :=
      Filter.tendsto_atTop_add_const_left _ _ (Filter.tendsto_pow_atTop two_ne_zero)
    have h2 : Filter.Tendsto (fun lam : ℝ => σ i ^ 2 / (σ i ^ 2 + lam ^ 2)) Filter.atTop
        (nhds 0) := tendsto_const_nhds.div_atTop h1
    have h3 := ((tendsto_const_nhds (x := (1 : ℝ))).sub h2).mul
      (tendsto_const_nhds (x := c i)) |>.pow 2
    simp only [sub_zero, one_mul] at h3
    refine h3.congr fun lam => ?_
    have hd := hden i lam
    congr 2
    field_simp
    ring
  obtain ⟨N, hN⟩ := Filter.eventually_atTop.mp (hGlim.eventually (lt_mem_nhds ht2))
  set L := max N 1 with hL
  have hL0 : 0 ≤ L := le_trans zero_le_one (le_max_right _ _)
  have hGL : t ^ 2 < G L := hN L (le_max_left _ _)
  have hρ0 : ρ 0 = 0 := by
    rw [hρG]
    simp [hG]
  have hρL : t < ρ L := by
    rw [hρG]
    exact (Real.lt_sqrt hpos.le).mpr hGL
  have hcontOn : ContinuousOn ρ (Set.Icc 0 L) := by
    rw [hρG]
    exact (Real.continuous_sqrt.comp hGcont).continuousOn
  obtain ⟨lam, ⟨hl0, -⟩, hlt'⟩ :=
    intermediate_value_Icc hL0 hcontOn ⟨by rw [hρ0]; exact hpos.le, hρL.le⟩
  have hlpos : 0 < lam := by
    rcases hl0.lt_or_eq with h | h
    · exact h
    · subst h
      rw [hρ0] at hlt'
      exact absurd hlt' hpos.ne
  refine ⟨lam, ⟨hlpos, hlt'⟩, ?_⟩
  rintro μ ⟨hμ, hμt⟩
  exact hρmono.injOn hμ hlpos (hμt.trans hlt'.symm)

-- The card's exact worked numbers.
-- Noise target: √64 × δ = 8δ, so with δ = 0.001 the target is 0.008.
example : Real.sqrt 64 = 8 := by
  rw [show (64 : ℝ) = 8 ^ 2 by norm_num, Real.sqrt_sq (by norm_num)]
-- The filter-factor table: σ = 10λ keeps 100/101 (0.9901), σ = λ keeps 1/2,
-- σ = λ/10 keeps 1/101 (0.0099).
example (lam : ℝ) (h : lam ≠ 0) :
    (10 * lam) ^ 2 / ((10 * lam) ^ 2 + lam ^ 2) = 100 / 101 := by
  field_simp; ring
example (lam : ℝ) (h : lam ≠ 0) : lam ^ 2 / (lam ^ 2 + lam ^ 2) = 1 / 2 := by
  field_simp; ring
example (lam : ℝ) (h : lam ≠ 0) :
    (lam / 10) ^ 2 / ((lam / 10) ^ 2 + lam ^ 2) = 1 / 101 := by
  field_simp; ring
-- Pattern counts: frequency 0, a cosine and a sine for each of 1 to 31, and frequency 32 make 64;
-- frequencies 0 to 12 are 25 patterns (Tikhonov keeps more than half of these);
-- frequencies 0 to 10 are the 21 patterns truncated SVD keeps.
example : 1 + 2 * 31 + 1 = 64 := by norm_num
example : 1 + 2 * 12 = 25 := by norm_num
example : 1 + 2 * 10 = 21 := by norm_num
-- Cost per new λ with the SVD in hand: 2n² + 4n flops at n = 64.
example : 2 * 64 ^ 2 + 4 * 64 = 8448 := by norm_num

#print axioms tikhonov_filter_factors_solve_damped_least_squares
#print axioms tikhonov_noise_gain_at_most_one_over_two_lambda
#print axioms discrepancy_principle_has_one_root
