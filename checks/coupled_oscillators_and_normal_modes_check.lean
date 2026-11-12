-- Normal modes: for masses on springs with positive masses and a symmetric positive definite stiffness matrix, there are n mode shapes, and every motion is the sum of these shapes, each swinging at the square root of its eigenvalue; energy stays fixed, and the card's two-cart numbers are checked exactly.
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Deriv
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Calculus.Deriv.Pi
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Tactic.NormNum.Irrational
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.Analysis.Matrix.PosDef
import Mathlib.Tactic

open Matrix

/-! The carts' distances from rest form one vector `x t : Fin n → ℝ`. The masses are `m i > 0`,
so the mass matrix is `M = diagonal m`. The stiffness matrix `K` is symmetric positive definite
(`K.PosDef`, which over ℝ includes `K` symmetric). Velocity `x'` and acceleration `x''` are
given as derivatives (`HasDerivAt`), and Newton's law `M x'' = -K x` holds at every time.
The eigenvalues are written `μ i` (the card's `λᵢ`; `λ` is a reserved word in Lean), and
`ω = √μ`. The dot `⬝ᵥ` multiplies two vectors entry by entry and adds. -/

theorem coupledOsc_hasDerivAt_mulVec {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ)
    {g : ℝ → Fin n → ℝ} {g' : Fin n → ℝ} {t : ℝ} (hg : HasDerivAt g g' t) :
    HasDerivAt (fun s => A *ᵥ g s) (A *ᵥ g') t := by
  rw [hasDerivAt_pi]
  intro i
  simp only [mulVec, dotProduct]
  exact HasDerivAt.fun_sum fun j _ => ((hasDerivAt_pi.1 hg) j).const_mul (A i j)

theorem coupledOsc_hasDerivAt_dotProduct {n : ℕ}
    {f g : ℝ → Fin n → ℝ} {f' g' : Fin n → ℝ} {t : ℝ}
    (hf : HasDerivAt f f' t) (hg : HasDerivAt g g' t) :
    HasDerivAt (fun s => f s ⬝ᵥ g s) (f' ⬝ᵥ g t + f t ⬝ᵥ g') t := by
  simp only [dotProduct]
  rw [← Finset.sum_add_distrib]
  exact HasDerivAt.fun_sum fun i _ => ((hasDerivAt_pi.1 hf) i).mul ((hasDerivAt_pi.1 hg) i)

theorem coupledOsc_dotProduct_mulVec_symm {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ)
    (hA : Aᵀ = A) (a b : Fin n → ℝ) : a ⬝ᵥ (A *ᵥ b) = b ⬝ᵥ (A *ᵥ a) := by
  rw [dotProduct_mulVec, dotProduct_comm, ← mulVec_transpose, hA]

theorem coupledOsc_transpose_of_posDef {n : ℕ} {K : Matrix (Fin n) (Fin n) ℝ}
    (hK : K.PosDef) : Kᵀ = K := by
  have h := hK.1
  rw [IsHermitian, conjTranspose_eq_transpose_of_trivial] at h
  exact h

theorem coupledOsc_scalar {μ : ℝ} (hμ : 0 < μ) (c c' c'' : ℝ → ℝ)
    (hc : ∀ t, HasDerivAt c (c' t) t) (hc' : ∀ t, HasDerivAt c' (c'' t) t)
    (h : ∀ t, c'' t = -μ * c t) :
    ∀ t, c t = c 0 * Real.cos (Real.sqrt μ * t) + c' 0 / Real.sqrt μ * Real.sin (Real.sqrt μ * t) := by
  set ω := Real.sqrt μ with hω
  have hωpos : 0 < ω := Real.sqrt_pos.2 hμ
  have hω2 : ω ^ 2 = μ := Real.sq_sqrt hμ.le
  set e : ℝ → ℝ := fun t => c t - (c 0 * Real.cos (ω * t) + c' 0 / ω * Real.sin (ω * t)) with he
  set e' : ℝ → ℝ := fun t => c' t - (c 0 * (-Real.sin (ω * t) * ω) + c' 0 / ω * (Real.cos (ω * t) * ω)) with he'
  have hcos : ∀ t, HasDerivAt (fun s => Real.cos (ω * s)) (-Real.sin (ω * t) * ω) t := by
    intro t
    have := ((hasDerivAt_id t).const_mul ω).cos
    simpa using this
  have hsin : ∀ t, HasDerivAt (fun s => Real.sin (ω * s)) (Real.cos (ω * t) * ω) t := by
    intro t
    have := ((hasDerivAt_id t).const_mul ω).sin
    simpa using this
  have hde : ∀ t, HasDerivAt e (e' t) t := by
    intro t
    exact (hc t).sub (((hcos t).const_mul (c 0)).add ((hsin t).const_mul (c' 0 / ω)))
  have hde' : ∀ t, HasDerivAt e' (-μ * e t) t := by
    intro t
    have := (hc' t).sub ((((hsin t).neg.mul_const ω).const_mul (c 0)).add
      (((hcos t).mul_const ω).const_mul (c' 0 / ω)))
    convert this using 1
    simp only [he, h t]
    rw [← hω2]
    field_simp
    ring
  set E : ℝ → ℝ := fun t => e' t ^ 2 + μ * e t ^ 2 with hE
  have hdE : ∀ t, HasDerivAt E 0 t := by
    intro t
    have := ((hde' t).pow 2).add (((hde t).pow 2).const_mul μ)
    convert this using 1
    simp
    ring
  have hconst := is_const_of_deriv_eq_zero (fun t => (hdE t).differentiableAt)
    (fun t => (hdE t).deriv)
  have hE0 : E 0 = 0 := by
    simp only [hE, he, he']
    simp
    field_simp
    ring
  intro t
  have hEt : E t = 0 := by rw [hconst t 0, hE0]
  have het : e t = 0 := by
    simp only [hE] at hEt
    by_contra hne
    have : 0 < e t ^ 2 := by positivity
    nlinarith [sq_nonneg (e' t), mul_pos hμ this]
  simp only [he] at het
  linarith

#print axioms coupledOsc_hasDerivAt_mulVec
#print axioms coupledOsc_hasDerivAt_dotProduct
#print axioms coupledOsc_dotProduct_mulVec_symm
#print axioms coupledOsc_transpose_of_posDef
#print axioms coupledOsc_scalar

/-- **Every motion is a sum of normal modes.** Take `n` masses `m i > 0` and a symmetric
positive definite stiffness matrix `K`. Then there are `n` nonzero mode shapes `v i` with
positive eigenvalues `μ i`, `K vᵢ = μᵢ M vᵢ`, perpendicular against the mass matrix
(`vᵢ · M vⱼ = 0` for `i ≠ j`). And every motion `x` with `M x'' = -K x` is the sum of the
modes, each swinging at `ωᵢ = √μᵢ`:
`x(t) = Σ (Aᵢ cos ωᵢt + Bᵢ sin ωᵢt) vᵢ`, with start share `Aᵢ = x(0)·M vᵢ / (vᵢ·M vᵢ)` and
`Bᵢ = x'(0)·M vᵢ / ((vᵢ·M vᵢ) ωᵢ)`. -/
theorem every_motion_is_a_sum_of_normal_modes
    {n : ℕ} (m : Fin n → ℝ) (hm : ∀ i, 0 < m i)
    (K : Matrix (Fin n) (Fin n) ℝ) (hK : K.PosDef) :
    ∃ (v : Fin n → Fin n → ℝ) (μ : Fin n → ℝ),
      (∀ i, v i ≠ 0) ∧ (∀ i, 0 < μ i) ∧
      (∀ i, K *ᵥ v i = μ i • (diagonal m *ᵥ v i)) ∧
      (∀ i j, i ≠ j → v i ⬝ᵥ (diagonal m *ᵥ v j) = 0) ∧
      ∀ (x x' x'' : ℝ → Fin n → ℝ),
        (∀ t, HasDerivAt x (x' t) t) → (∀ t, HasDerivAt x' (x'' t) t) →
        (∀ t, diagonal m *ᵥ x'' t = -(K *ᵥ x t)) →
        ∀ t, x t = ∑ i,
          ((x 0 ⬝ᵥ (diagonal m *ᵥ v i)) / (v i ⬝ᵥ (diagonal m *ᵥ v i))
              * Real.cos (Real.sqrt (μ i) * t)
            + (x' 0 ⬝ᵥ (diagonal m *ᵥ v i)) / ((v i ⬝ᵥ (diagonal m *ᵥ v i)) * Real.sqrt (μ i))
              * Real.sin (Real.sqrt (μ i) * t)) • v i := by
  classical
  set d : Fin n → ℝ := fun i => (Real.sqrt (m i))⁻¹ with hd
  have hsq : ∀ i, 0 < Real.sqrt (m i) := fun i => Real.sqrt_pos.2 (hm i)
  have hdne : ∀ i, d i ≠ 0 := fun i => inv_ne_zero (hsq i).ne'
  have hdd : ∀ i, m i * (d i * d i) = 1 := by
    intro i
    have h1 := Real.mul_self_sqrt (hm i).le
    have h2 := (hsq i).ne'
    simp only [hd]
    field_simp
    linarith
  have hDinj : Function.Injective (diagonal d).mulVec := by
    intro a b h
    funext k
    have := congrFun h k
    simp only [mulVec_diagonal] at this
    exact mul_left_cancel₀ (hdne k) this
  have hSpd : ((diagonal d)ᴴ * K * diagonal d).PosDef := hK.conjTranspose_mul_mul_same hDinj
  have hS : ((diagonal d)ᴴ * K * diagonal d).IsHermitian := hSpd.isHermitian
  obtain ⟨u, μ, hμpos, heig0, U, hU, hUe⟩ : ∃ (u : Fin n → Fin n → ℝ) (μ : Fin n → ℝ),
      (∀ i, 0 < μ i) ∧ (∀ i, ((diagonal d)ᴴ * K * diagonal d) *ᵥ u i = μ i • u i) ∧
      ∃ U : Matrix (Fin n) (Fin n) ℝ, U ∈ unitaryGroup (Fin n) ℝ ∧ ∀ k j, U k j = u j k :=
    ⟨fun j => ⇑(hS.eigenvectorBasis j), hS.eigenvalues, hSpd.eigenvalues_pos,
      hS.mulVec_eigenvectorBasis, hS.eigenvectorUnitary, hS.eigenvectorUnitary.2,
      fun k j => hS.eigenvectorUnitary_apply k j⟩
  have horth : ∀ i j, ∑ k, u i k * u j k = if i = j then 1 else 0 := by
    intro i j
    have := congrFun (congrFun (mem_unitaryGroup_iff'.1 hU) i) j
    rw [star_eq_conjTranspose, conjTranspose_eq_transpose_of_trivial, Matrix.mul_apply, Matrix.one_apply] at this
    simpa only [transpose_apply, hUe] using this
  have hcomp : ∀ k l, ∑ i, u i k * u i l = if k = l then 1 else 0 := by
    intro k l
    have := congrFun (congrFun (mem_unitaryGroup_iff.1 hU) k) l
    rw [star_eq_conjTranspose, conjTranspose_eq_transpose_of_trivial, Matrix.mul_apply, Matrix.one_apply] at this
    simpa only [transpose_apply, hUe] using this
  set v : Fin n → Fin n → ℝ := fun j => diagonal d *ᵥ u j with hv
  have hMv : ∀ j k, (diagonal m *ᵥ v j) k = m k * (d k * u j k) := by
    intro j k
    simp [hv, mulVec_diagonal]
  have hvMv : ∀ i j, v i ⬝ᵥ (diagonal m *ᵥ v j) = if i = j then 1 else 0 := by
    intro i j
    rw [← horth i j]
    simp only [dotProduct, hMv]
    refine Finset.sum_congr rfl fun k _ => ?_
    simp only [hv, mulVec_diagonal]
    have := hdd k
    linear_combination (u i k * u j k) * this
  have hvv : ∀ i, v i ⬝ᵥ (diagonal m *ᵥ v i) = 1 := fun i => by simp [hvMv]
  have heig : ∀ i, K *ᵥ v i = μ i • (diagonal m *ᵥ v i) := by
    intro i
    have h := heig0 i
    rw [← mulVec_mulVec, ← mulVec_mulVec, diagonal_conjTranspose, star_trivial] at h
    funext k
    have hk := congrFun h k
    simp only [mulVec_diagonal, Pi.smul_apply, smul_eq_mul] at hk
    rw [Pi.smul_apply, smul_eq_mul, hMv]
    have h1 := hdd k
    have h2 := hdne k
    -- d k * (K v) k = μ * u k
    have : (K *ᵥ v i) k = (K *ᵥ v i) k * (m k * (d k * d k)) := by rw [h1, mul_one]
    rw [this]
    simp only [hv]
    linear_combination (m k * d k) * hk
  have hexp : ∀ y : Fin n → ℝ, y = ∑ i, (y ⬝ᵥ (diagonal m *ᵥ v i)) • v i := by
    intro y
    funext k
    rw [Finset.sum_apply]
    simp only [Pi.smul_apply, smul_eq_mul, dotProduct, hMv]
    simp only [hv, mulVec_diagonal]
    simp_rw [Finset.sum_mul]
    rw [Finset.sum_comm]
    have : ∀ l, ∑ i, y l * (m l * (d l * u i l)) * (d k * u i k)
        = y l * m l * d l * d k * ∑ i, u i l * u i k := by
      intro l
      rw [Finset.mul_sum]
      refine Finset.sum_congr rfl fun i _ => ?_
      ring
    simp_rw [this, hcomp, mul_ite, mul_one, mul_zero, Finset.sum_ite_eq', Finset.mem_univ,
      ite_true]
    have := hdd k
    linear_combination (-y k) * this
  have hKt := coupledOsc_transpose_of_posDef hK
  have hMt : (diagonal m)ᵀ = diagonal m := diagonal_transpose m
  refine ⟨v, μ, ?_, hμpos, heig, ?_, ?_⟩
  · intro i h0
    have := hvv i
    rw [h0] at this
    simp at this
  · intro i j hij
    simp [hvMv, hij]
  · intro x x' x'' hx hx' hN t
    refine (hexp (x t)).trans (Finset.sum_congr rfl fun i _ => ?_)
    congr 1
    rw [hvv i, div_one, one_mul]
    set w := diagonal m *ᵥ v i
    have hd1 : ∀ s, HasDerivAt (fun r => x r ⬝ᵥ w) (x' s ⬝ᵥ w) s := by
      intro s
      simpa using coupledOsc_hasDerivAt_dotProduct (hx s) (hasDerivAt_const s w)
    have hd2 : ∀ s, HasDerivAt (fun r => x' r ⬝ᵥ w) (x'' s ⬝ᵥ w) s := by
      intro s
      simpa using coupledOsc_hasDerivAt_dotProduct (hx' s) (hasDerivAt_const s w)
    have hode : ∀ s, x'' s ⬝ᵥ w = -μ i * (x s ⬝ᵥ w) := by
      intro s
      simp only [w]
      rw [coupledOsc_dotProduct_mulVec_symm _ hMt, hN s, dotProduct_neg,
        coupledOsc_dotProduct_mulVec_symm _ hKt, heig i, dotProduct_smul, smul_eq_mul]
      ring
    exact coupledOsc_scalar (hμpos i) (fun r => x r ⬝ᵥ w) (fun r => x' r ⬝ᵥ w)
      (fun r => x'' r ⬝ᵥ w) hd1 hd2 hode t

/-- **A mode swings at the square root of its eigenvalue** (Step 0). With masses `m i > 0` and
`K` symmetric positive definite, if `K v = μ M v`, then the shape `v` swinging as
`x(t) = (A cos ωt + B sin ωt) v` with `ω = √μ`, whose velocity is `ω (B cos ωt − A sin ωt) v`
and acceleration `−ω² (A cos ωt + B sin ωt) v`, obeys Newton's law `M x'' = -K x` at every time. -/
theorem normal_mode_swings_at_sqrt_of_eigenvalue
    {n : ℕ} (m : Fin n → ℝ) (hm : ∀ i, 0 < m i)
    (K : Matrix (Fin n) (Fin n) ℝ) (hK : K.PosDef)
    (v : Fin n → ℝ) (μ : ℝ) (hv : K *ᵥ v = μ • (diagonal m *ᵥ v)) (A B : ℝ) :
    let ω := Real.sqrt μ
    let x := fun t : ℝ => (A * Real.cos (ω * t) + B * Real.sin (ω * t)) • v
    let x' := fun t : ℝ => (ω * (B * Real.cos (ω * t) - A * Real.sin (ω * t))) • v
    let x'' := fun t : ℝ => (-(ω ^ 2) * (A * Real.cos (ω * t) + B * Real.sin (ω * t))) • v
    (∀ t, HasDerivAt x (x' t) t) ∧ (∀ t, HasDerivAt x' (x'' t) t) ∧
      ∀ t, diagonal m *ᵥ x'' t = -(K *ᵥ x t) := by
  intro ω x x' x''
  have hcos : ∀ t, HasDerivAt (fun s => Real.cos (ω * s)) (-Real.sin (ω * t) * ω) t := by
    intro t
    have := ((hasDerivAt_id t).const_mul ω).cos
    simpa using this
  have hsin : ∀ t, HasDerivAt (fun s => Real.sin (ω * s)) (Real.cos (ω * t) * ω) t := by
    intro t
    have := ((hasDerivAt_id t).const_mul ω).sin
    simpa using this
  refine ⟨?_, ?_, ?_⟩
  · intro t
    have := (((hcos t).const_mul A).add ((hsin t).const_mul B)).smul_const v
    convert this using 2
    ring
  · intro t
    have := ((((hcos t).const_mul B).sub ((hsin t).const_mul A)).const_mul ω).smul_const v
    convert this using 2
    ring
  · intro t
    show diagonal m *ᵥ ((-(ω ^ 2) * (A * Real.cos (ω * t) + B * Real.sin (ω * t))) • v)
      = -(K *ᵥ ((A * Real.cos (ω * t) + B * Real.sin (ω * t)) • v))
    rw [mulVec_smul, mulVec_smul, hv]
    by_cases h0 : v = 0
    · subst h0; simp
    · have hpos := hK.dotProduct_mulVec_pos h0
      rw [star_trivial, hv, dotProduct_smul, smul_eq_mul] at hpos
      have hnn : 0 ≤ v ⬝ᵥ (diagonal m *ᵥ v) := by
        simp only [dotProduct, mulVec_diagonal]
        exact Finset.sum_nonneg fun i _ => by nlinarith [hm i, mul_self_nonneg (v i)]
      have hμ : 0 ≤ μ := by
        by_contra hneg
        have hneg' : μ < 0 := lt_of_not_ge hneg
        nlinarith
      have hω2 : ω ^ 2 = μ := Real.sq_sqrt hμ
      rw [hω2, smul_smul, ← neg_smul]
      congr 1
      ring

/-- **The energy stays fixed** (Step 4). With masses `m i > 0` and `K` symmetric positive
definite, every motion with `M x'' = -K x` keeps its energy, half of `x'·M x'` plus half of
`x·K x`, at its starting value for all time. -/
theorem energy_of_spring_system_is_conserved
    {n : ℕ} (m : Fin n → ℝ) (hm : ∀ i, 0 < m i)
    (K : Matrix (Fin n) (Fin n) ℝ) (hK : K.PosDef)
    (x x' x'' : ℝ → Fin n → ℝ)
    (hx : ∀ t, HasDerivAt x (x' t) t) (hx' : ∀ t, HasDerivAt x' (x'' t) t)
    (hN : ∀ t, diagonal m *ᵥ x'' t = -(K *ᵥ x t)) :
    ∀ t, (x' t ⬝ᵥ (diagonal m *ᵥ x' t)) / 2 + (x t ⬝ᵥ (K *ᵥ x t)) / 2
      = (x' 0 ⬝ᵥ (diagonal m *ᵥ x' 0)) / 2 + (x 0 ⬝ᵥ (K *ᵥ x 0)) / 2 := by
  have hKt := coupledOsc_transpose_of_posDef hK
  have hMt : (diagonal m)ᵀ = diagonal m := diagonal_transpose m
  have hd : ∀ t, HasDerivAt
      (fun s => (x' s ⬝ᵥ (diagonal m *ᵥ x' s)) / 2 + (x s ⬝ᵥ (K *ᵥ x s)) / 2) 0 t := by
    intro t
    have h1 := ((coupledOsc_hasDerivAt_dotProduct (hx' t)
      (coupledOsc_hasDerivAt_mulVec (diagonal m) (hx' t))).div_const 2).add
      ((coupledOsc_hasDerivAt_dotProduct (hx t)
      (coupledOsc_hasDerivAt_mulVec K (hx t))).div_const 2)
    convert h1 using 1
    rw [coupledOsc_dotProduct_mulVec_symm _ hMt (x'' t), hN t,
      coupledOsc_dotProduct_mulVec_symm _ hKt (x t), dotProduct_neg]
    ring
  have hc := is_const_of_deriv_eq_zero (fun t => (hd t).differentiableAt)
    (fun t => (hd t).deriv)
  intro t
  exact hc t 0

/-! The card's whole-number checks: two 1 kg carts, three 1 N/m springs, `M = I`,
`K = [[2, -1], [-1, 2]]`. -/

-- Forces on the left cart: −1 × x₁ + 1 × (x₂ − x₁) = −2x₁ + x₂.
example (x₁ x₂ : ℚ) : -1 * x₁ + 1 * (x₂ - x₁) = -2 * x₁ + x₂ := by ring
-- Trace 4, determinant 3.
example : (!![2, -1; -1, 2] : Matrix (Fin 2) (Fin 2) ℚ).trace = 4 := by
  simp [Matrix.trace, Fin.sum_univ_two]; norm_num
example : (!![2, -1; -1, 2] : Matrix (Fin 2) (Fin 2) ℚ).det = 3 := by
  rw [det_fin_two_of]; norm_num
-- det(K − λI) = (2 − λ)² − 1 = λ² − 4λ + 3 = (λ − 1)(λ − 3).
example (l : ℚ) : (2 - l) * (2 - l) - (-1) * (-1) = l ^ 2 - 4 * l + 3 := by ring
example (l : ℚ) : l ^ 2 - 4 * l + 3 = (l - 1) * (l - 3) := by ring
-- Mode shapes: K (1, 1) = 1 × (1, 1) and K (1, −1) = 3 × (1, −1).
example : (!![2, -1; -1, 2] : Matrix (Fin 2) (Fin 2) ℚ) *ᵥ ![1, 1] = (1 : ℚ) • ![1, 1] ∧
    (!![2, -1; -1, 2] : Matrix (Fin 2) (Fin 2) ℚ) *ᵥ ![1, -1] = (3 : ℚ) • ![1, -1] := by
  refine ⟨?_, ?_⟩ <;> ext i <;> fin_cases i <;> simp [mulVec, dotProduct, Fin.sum_univ_two] <;>
    norm_num
-- The modes are perpendicular: 1 × 1 + 1 × (−1) = 0.
example : (![1, 1] : Fin 2 → ℚ) ⬝ᵥ ![1, -1] = 0 := by
  simp [dotProduct, Fin.sum_univ_two]
-- The periods are in the ratio √3, not a fraction.
example : Irrational (Real.sqrt 3) := by norm_num
-- Shares of the start (10, 0): 10/2 = 5 for both modes, and 5 (1, 1) + 5 (1, −1) = (10, 0).
example : (![10, 0] : Fin 2 → ℚ) ⬝ᵥ ![1, 1] / (![1, 1] ⬝ᵥ ![1, 1]) = 5 ∧
    (![10, 0] : Fin 2 → ℚ) ⬝ᵥ ![1, -1] / (![1, -1] ⬝ᵥ ![1, -1]) = 5 := by
  simp [dotProduct, Fin.sum_univ_two]; norm_num
example : (5 : ℚ) • (![1, 1] : Fin 2 → ℚ) + (5 : ℚ) • ![1, -1] = ![10, 0] := by
  ext i; fin_cases i <;> norm_num
-- Energy at release, in joules with x in metres: ½ x·Kx = ½ × 2 × (1/10)² = 1/100 J (10 mJ),
-- split 1 : 3 as ½ × λ × 2 × (1/20)² per mode: 1/400 J + 3/400 J (2.50 + 7.50 mJ).
example : (![1 / 10, 0] : Fin 2 → ℚ) ⬝ᵥ ((!![2, -1; -1, 2] : Matrix (Fin 2) (Fin 2) ℚ) *ᵥ
    ![1 / 10, 0]) / 2 = 1 / 100 := by
  simp [mulVec, dotProduct, Fin.sum_univ_two]; norm_num
example : (1 / 2 : ℚ) * 1 * 2 * (1 / 20) ^ 2 = 1 / 400 ∧ (1 / 2 : ℚ) * 3 * 2 * (1 / 20) ^ 2 = 3 / 400 ∧
    (1 / 400 : ℚ) + 3 / 400 = 1 / 100 := by norm_num
-- Weak middle spring, 1/20 N/m: K = [[21/20, −1/20], [−1/20, 21/20]], eigenvalues 1 and 11/10.
example : (!![21 / 20, -1 / 20; -1 / 20, 21 / 20] : Matrix (Fin 2) (Fin 2) ℚ) *ᵥ ![1, 1]
      = (1 : ℚ) • ![1, 1] ∧
    (!![21 / 20, -1 / 20; -1 / 20, 21 / 20] : Matrix (Fin 2) (Fin 2) ℚ) *ᵥ ![1, -1]
      = (11 / 10 : ℚ) • ![1, -1] := by
  refine ⟨?_, ?_⟩ <;> ext i <;> fin_cases i <;> simp [mulVec, dotProduct, Fin.sum_univ_two] <;>
    norm_num
-- Mistake: shares taken as x(0)·v without dividing by v·v are 10 and 10, so x₁ starts at 20.
example : (![10, 0] : Fin 2 → ℚ) ⬝ᵥ ![1, 1] = 10 ∧ (![10, 0] : Fin 2 → ℚ) ⬝ᵥ ![1, -1] = 10 ∧
    (10 : ℚ) • (![1, 1] : Fin 2 → ℚ) + (10 : ℚ) • ![1, -1] = ![20, 0] := by
  refine ⟨?_, ?_, ?_⟩
  · simp [dotProduct, Fin.sum_univ_two]
  · simp [dotProduct, Fin.sum_univ_two]
  · ext i; fin_cases i <;> norm_num
-- Mistake: wall springs left out, K = [[1, −1], [−1, 1]], eigenvalues 0 and 2: the slow mode
-- has no restoring force.
example : (!![1, -1; -1, 1] : Matrix (Fin 2) (Fin 2) ℚ) *ᵥ ![1, 1] = (0 : ℚ) • ![1, 1] ∧
    (!![1, -1; -1, 1] : Matrix (Fin 2) (Fin 2) ℚ) *ᵥ ![1, -1] = (2 : ℚ) • ![1, -1] := by
  refine ⟨?_, ?_⟩ <;> ext i <;> fin_cases i <;> simp [mulVec, dotProduct, Fin.sum_univ_two] <;>
    norm_num

#print axioms every_motion_is_a_sum_of_normal_modes
#print axioms normal_mode_swings_at_sqrt_of_eigenvalue
#print axioms energy_of_spring_system_is_conserved
