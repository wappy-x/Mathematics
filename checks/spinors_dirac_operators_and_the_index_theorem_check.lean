-- Spinors and the Dirac operator: two matrices that square to one and anticommute make D = -i(a ∂x + b ∂y) square to minus the flat Laplacian, on the torus wave with whole-number frequencies (m, n) the Pauli Dirac operator acts as m σ₁ + n σ₂ with eigenvalues ±√(m² + n²), and the spin element q(θ) = cos(θ/2) − sin(θ/2) σ₁σ₂ turns the plane by θ while q(360°) = −1 and q(720°) = +1.
import Mathlib.Analysis.Calculus.FDeriv.Symmetric
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.LinearAlgebra.Matrix.NonsingularInverse
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.Analysis.Complex.RealDeriv
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.Tactic.Module
import Mathlib.Topology.Algebra.Module.FiniteDimension
import Mathlib.Tactic.LinearCombination

open Matrix

namespace SpinorDirac

/-! A spinor is a column of two complex numbers, `Fin 2 → ℂ`. A spinor field on the plane is a
function `ψ : ℝ × ℝ → Fin 2 → ℂ`; a field on the flat torus with sides `2π` is one that repeats
when `x` or `y` grows by `2π`. The rates of change `∂x ψ` and `∂y ψ` are ordinary derivatives
along one coordinate with the other held fixed. A matrix acts on a spinor by `*ᵥ`. -/

/-- The Pauli matrix `σ₁ = [[0, 1], [1, 0]]`. -/
def σ₁ : Matrix (Fin 2) (Fin 2) ℂ := !![0, 1; 1, 0]
/-- The Pauli matrix `σ₂ = [[0, −i], [i, 0]]`. -/
def σ₂ : Matrix (Fin 2) (Fin 2) ℂ := !![0, -Complex.I; Complex.I, 0]
/-- The Pauli matrix `σ₃ = [[1, 0], [0, −1]]`, which marks handedness. -/
def σ₃ : Matrix (Fin 2) (Fin 2) ℂ := !![1, 0; 0, -1]

/-- The rate of change along `x`: `∂x ψ (x, y)` is the derivative of `t ↦ ψ (t, y)` at `x`. -/
noncomputable def dx (ψ : ℝ × ℝ → Fin 2 → ℂ) : ℝ × ℝ → Fin 2 → ℂ :=
  fun p => deriv (fun t => ψ (t, p.2)) p.1

/-- The rate of change along `y`: `∂y ψ (x, y)` is the derivative of `t ↦ ψ (x, t)` at `y`. -/
noncomputable def dy (ψ : ℝ × ℝ → Fin 2 → ℂ) : ℝ × ℝ → Fin 2 → ℂ :=
  fun p => deriv (fun t => ψ (p.1, t)) p.2

/-- The flat Laplacian `∂x² ψ + ∂y² ψ`, taken on each entry of the spinor. -/
noncomputable def laplacian (ψ : ℝ × ℝ → Fin 2 → ℂ) : ℝ × ℝ → Fin 2 → ℂ :=
  fun p => dx (dx ψ) p + dy (dy ψ) p

/-- The Dirac operator built from two 2 by 2 matrices `a` and `b`:
`D ψ = −i (a ∂x ψ + b ∂y ψ)`. The card's operator is `dirac σ₁ σ₂`. -/
noncomputable def dirac (a b : Matrix (Fin 2) (Fin 2) ℂ) (ψ : ℝ × ℝ → Fin 2 → ℂ) :
    ℝ × ℝ → Fin 2 → ℂ :=
  fun p => (-Complex.I) • (a *ᵥ dx ψ p + b *ᵥ dy ψ p)

/-- The wave `e^{i(mx + ny)} ξ` with whole-number frequencies `m`, `n` and a fixed spinor `ξ`.
It repeats when `x` or `y` grows by `2π`, so it is a spinor field on the flat torus. -/
noncomputable def wave (m n : ℤ) (ξ : Fin 2 → ℂ) : ℝ × ℝ → Fin 2 → ℂ :=
  fun p => Complex.exp (Complex.I * ((m : ℂ) * (p.1 : ℂ) + (n : ℂ) * (p.2 : ℂ))) • ξ

/-- The spin element that turns the `e₁e₂` plane by `θ`, with `e₁ = σ₁` and `e₂ = σ₂`:
`q(θ) = cos(θ/2) − sin(θ/2) σ₁σ₂`. -/
noncomputable def spinElt (θ : ℝ) : Matrix (Fin 2) (Fin 2) ℂ :=
  (Real.cos (θ / 2) : ℂ) • (1 : Matrix (Fin 2) (Fin 2) ℂ) - (Real.sin (θ / 2) : ℂ) • (σ₁ * σ₂)


lemma hasDerivAt_lineX {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (g : ℝ × ℝ → E) (g' : (ℝ × ℝ) →L[ℝ] E) (p : ℝ × ℝ) (h : HasFDerivAt g g' p) :
    HasDerivAt (fun t => g (t, p.2)) (g' (1, 0)) p.1 := by
  have hl : HasDerivAt (fun t : ℝ => (t, p.2)) ((1 : ℝ), (0 : ℝ)) p.1 :=
    (hasDerivAt_id p.1).prodMk (hasDerivAt_const p.1 p.2)
  have h' : HasFDerivAt g g' (p.1, p.2) := h
  exact h'.comp_hasDerivAt p.1 hl

lemma hasDerivAt_lineY {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    (g : ℝ × ℝ → E) (g' : (ℝ × ℝ) →L[ℝ] E) (p : ℝ × ℝ) (h : HasFDerivAt g g' p) :
    HasDerivAt (fun t => g (p.1, t)) (g' (0, 1)) p.2 := by
  have hl : HasDerivAt (fun t : ℝ => (p.1, t)) ((0 : ℝ), (1 : ℝ)) p.2 :=
    (hasDerivAt_const p.2 p.1).prodMk (hasDerivAt_id p.2)
  have h' : HasFDerivAt g g' (p.1, p.2) := h
  exact h'.comp_hasDerivAt p.2 hl

lemma hasDerivAt_mulVec (a : Matrix (Fin 2) (Fin 2) ℂ) {F : ℝ → Fin 2 → ℂ} {F' : Fin 2 → ℂ}
    {x : ℝ} (hF : HasDerivAt F F' x) : HasDerivAt (fun t => a *ᵥ F t) (a *ᵥ F') x := by
  let L : (Fin 2 → ℂ) →L[ℝ] (Fin 2 → ℂ) :=
    (LinearMap.toContinuousLinearMap (Matrix.mulVecLin a)).restrictScalars ℝ
  have := L.hasFDerivAt.comp_hasDerivAt x hF
  simpa [L, Function.comp_def] using this

lemma hasDerivAt_comb (c : ℂ) (a b : Matrix (Fin 2) (Fin 2) ℂ) {F G : ℝ → Fin 2 → ℂ}
    {F' G' : Fin 2 → ℂ} {x : ℝ} (hF : HasDerivAt F F' x) (hG : HasDerivAt G G' x) :
    HasDerivAt (fun t => c • (a *ᵥ F t + b *ᵥ G t)) (c • (a *ᵥ F' + b *ᵥ G')) x :=
  ((hasDerivAt_mulVec a hF).add (hasDerivAt_mulVec b hG)).const_smul c

lemma hasDerivAt_wave_line (ξ : Fin 2 → ℂ) (x : ℝ) (c k : ℂ) :
    HasDerivAt (fun t : ℝ => Complex.exp (Complex.I * (k * (t : ℂ) + c)) • ξ)
      ((Complex.exp (Complex.I * (k * (x : ℂ) + c)) * (Complex.I * k)) • ξ) x := by
  have h1 : HasDerivAt (fun t : ℝ => (t : ℂ)) 1 x := (hasDerivAt_id x).ofReal_comp
  have h2 := ((h1.const_mul k).add_const (c : ℂ)).const_mul Complex.I
  have h3 := h2.cexp.smul_const ξ
  simpa using h3

/-- **A square root of the Laplacian.** If two matrices each square to one and anticommute,
`a² = b² = 1` and `ab + ba = 0` (the Clifford rules), then the first-order operator
`D = −i(a ∂x + b ∂y)` squares to minus the flat Laplacian: `D(Dψ) = −(∂x²ψ + ∂y²ψ)` for every
twice continuously differentiable spinor field `ψ`. -/
theorem dirac_sq_eq_neg_laplacian (a b : Matrix (Fin 2) (Fin 2) ℂ)
    (ha : a * a = 1) (hb : b * b = 1) (hab : a * b + b * a = 0)
    (ψ : ℝ × ℝ → Fin 2 → ℂ) (hψ : ContDiff ℝ 2 ψ) :
    dirac a b (dirac a b ψ) = -laplacian ψ := by
  have hd : Differentiable ℝ ψ := hψ.differentiable (by norm_num)
  have hfd : Differentiable ℝ (fderiv ℝ ψ) :=
    (hψ.fderiv_right (m := 1) (by norm_num)).differentiable (by norm_num)
  set D := fderiv ℝ (fderiv ℝ ψ) with hD
  have hsymm : ∀ p, IsSymmSndFDerivAt ℝ ψ p := fun p => by
    apply ContDiffAt.isSymmSndFDerivAt hψ.contDiffAt
    simp
  have hdx : dx ψ = fun q => fderiv ℝ ψ q (1, 0) := by
    funext q
    exact (hasDerivAt_lineX ψ _ q (hd q).hasFDerivAt).deriv
  have hdy : dy ψ = fun q => fderiv ℝ ψ q (0, 1) := by
    funext q
    exact (hasDerivAt_lineY ψ _ q (hd q).hasFDerivAt).deriv
  -- line derivatives of the first partials
  have hXv : ∀ (q : ℝ × ℝ) (v : ℝ × ℝ),
      HasDerivAt (fun t => fderiv ℝ ψ (t, q.2) v) (D q (1, 0) v) q.1 := by
    intro q v
    have := (hasDerivAt_lineX (fderiv ℝ ψ) _ q (hfd q).hasFDerivAt).clm_apply
      (hasDerivAt_const q.1 v)
    simpa using this
  have hYv : ∀ (q : ℝ × ℝ) (v : ℝ × ℝ),
      HasDerivAt (fun t => fderiv ℝ ψ (q.1, t) v) (D q (0, 1) v) q.2 := by
    intro q v
    have := (hasDerivAt_lineY (fderiv ℝ ψ) _ q (hfd q).hasFDerivAt).clm_apply
      (hasDerivAt_const q.2 v)
    simpa using this
  have hDx : ∀ q, dx (dirac a b ψ) q =
      (-Complex.I) • (a *ᵥ D q (1, 0) (1, 0) + b *ᵥ D q (1, 0) (0, 1)) := by
    intro q
    have := hasDerivAt_comb (-Complex.I) a b (hXv q (1, 0)) (hXv q (0, 1))
    change deriv (fun t => (-Complex.I) • (a *ᵥ dx ψ (t, q.2) + b *ᵥ dy ψ (t, q.2))) q.1 = _
    rw [hdx, hdy]
    exact this.deriv
  have hDy : ∀ q, dy (dirac a b ψ) q =
      (-Complex.I) • (a *ᵥ D q (0, 1) (1, 0) + b *ᵥ D q (0, 1) (0, 1)) := by
    intro q
    have := hasDerivAt_comb (-Complex.I) a b (hYv q (1, 0)) (hYv q (0, 1))
    change deriv (fun t => (-Complex.I) • (a *ᵥ dx ψ (q.1, t) + b *ᵥ dy ψ (q.1, t))) q.2 = _
    rw [hdx, hdy]
    exact this.deriv
  have hxx : ∀ q, dx (dx ψ) q = D q (1, 0) (1, 0) := fun q => by
    rw [hdx]; exact (hXv q (1, 0)).deriv
  have hyy : ∀ q, dy (dy ψ) q = D q (0, 1) (0, 1) := fun q => by
    rw [hdy]; exact (hYv q (0, 1)).deriv
  funext q
  have hs := hsymm q (1, 0) (0, 1)
  rw [← hD] at hs
  have hab' : a * b = -(b * a) := eq_neg_of_add_eq_zero_left hab
  simp only [dirac, laplacian, hDx, hDy, hxx, hyy, hs, Pi.neg_apply]
  simp only [Matrix.mulVec_smul, Matrix.mulVec_add, Matrix.mulVec_mulVec, smul_add, smul_smul,
    ha, hb, hab', Matrix.neg_mulVec, Matrix.one_mulVec]
  have hI : -Complex.I * -Complex.I = -1 := by simp
  rw [hI]
  module

/-- **The torus eigenvalues.** On the wave `e^{i(mx + ny)} ξ` with whole numbers `m`, `n`, the
Dirac operator `D = −i(σ₁ ∂x + σ₂ ∂y)` acts as the matrix `m σ₁ + n σ₂`, and a number `λ` is an
eigenvalue of `D` on such a wave (some nonzero `ξ` has `D(e^{i(mx+ny)} ξ) = λ e^{i(mx+ny)} ξ`)
exactly when `λ = √(m² + n²)` or `λ = −√(m² + n²)`. -/
theorem torus_mode_eigenvalues (m n : ℤ) :
    (∀ ξ : Fin 2 → ℂ,
      dirac σ₁ σ₂ (wave m n ξ) = wave m n (((m : ℂ) • σ₁ + (n : ℂ) • σ₂) *ᵥ ξ)) ∧
    (∀ lam : ℂ, (∃ ξ : Fin 2 → ℂ, ξ ≠ 0 ∧ dirac σ₁ σ₂ (wave m n ξ) = lam • wave m n ξ) ↔
      (lam = (Real.sqrt ((m : ℝ) ^ 2 + (n : ℝ) ^ 2) : ℂ) ∨
        lam = -(Real.sqrt ((m : ℝ) ^ 2 + (n : ℝ) ^ 2) : ℂ))) := by
  have hpart : ∀ ξ : Fin 2 → ℂ,
      dirac σ₁ σ₂ (wave m n ξ) = wave m n (((m : ℂ) • σ₁ + (n : ℂ) • σ₂) *ᵥ ξ) := by
    intro ξ
    funext q
    have hx : dx (wave m n ξ) q =
        (Complex.exp (Complex.I * ((m : ℂ) * (q.1 : ℂ) + (n : ℂ) * (q.2 : ℂ))) *
          (Complex.I * m)) • ξ := by
      have := hasDerivAt_wave_line ξ q.1 ((n : ℂ) * (q.2 : ℂ)) (m : ℂ)
      simp only [dx, wave]
      exact this.deriv
    have hy : dy (wave m n ξ) q =
        (Complex.exp (Complex.I * ((m : ℂ) * (q.1 : ℂ) + (n : ℂ) * (q.2 : ℂ))) *
          (Complex.I * n)) • ξ := by
      have h := hasDerivAt_wave_line ξ q.2 ((m : ℂ) * (q.1 : ℂ)) (n : ℂ)
      simp only [dy, wave]
      have e : (fun t : ℝ => Complex.exp (Complex.I * ((m : ℂ) * (q.1 : ℂ) + (n : ℂ) * (t : ℂ))) • ξ)
          = (fun t : ℝ => Complex.exp (Complex.I * ((n : ℂ) * (t : ℂ) + (m : ℂ) * (q.1 : ℂ))) • ξ) := by
        funext t; ring_nf
      rw [e, h.deriv, add_comm ((n : ℂ) * (q.2 : ℂ))]
    simp only [dirac, hx, hy, wave, Matrix.mulVec_smul, Matrix.add_mulVec, Matrix.smul_mulVec,
      smul_add, smul_smul]
    have hI : ∀ z w : ℂ, -Complex.I * (z * (Complex.I * w)) = z * w := by
      intro z w
      linear_combination (-z * w) * Complex.I_sq
    rw [hI, hI]
  refine ⟨hpart, fun lam => ?_⟩
  set s : ℂ := (Real.sqrt ((m : ℝ) ^ 2 + (n : ℝ) ^ 2) : ℂ) with hsdef
  have hs : s ^ 2 = (m : ℂ) ^ 2 + (n : ℂ) ^ 2 := by
    rw [hsdef, ← Complex.ofReal_pow, Real.sq_sqrt (by positivity)]
    push_cast; ring
  have hw0 : ∀ v, wave m n v (0, 0) = v := by intro v; simp [wave]
  have key : ∀ ξ, (dirac σ₁ σ₂ (wave m n ξ) = lam • wave m n ξ) ↔
      (((m : ℂ) • σ₁ + (n : ℂ) • σ₂) *ᵥ ξ = lam • ξ) := by
    intro ξ
    rw [hpart]
    constructor
    · intro h
      have := congrFun h (0, 0)
      simpa [hw0] using this
    · intro h
      rw [h]
      funext q
      exact smul_comm _ _ _
  simp_rw [key]
  have hM : ∀ ξ : Fin 2 → ℂ, ((m : ℂ) • σ₁ + (n : ℂ) • σ₂) *ᵥ ξ =
      ![((m : ℂ) - n * Complex.I) * ξ 1, ((m : ℂ) + n * Complex.I) * ξ 0] := by
    intro ξ
    ext i
    fin_cases i
    · simp [σ₁, σ₂, Matrix.mulVec, dotProduct, Fin.sum_univ_two]
      left; ring
    · simp [σ₁, σ₂, Matrix.mulVec, dotProduct, Fin.sum_univ_two]
  simp_rw [hM]
  constructor
  · rintro ⟨ξ, hξ, h⟩
    have h0 := congrFun h 0
    have h1 := congrFun h 1
    simp at h0 h1
    have e0 : (lam ^ 2 - s ^ 2) * ξ 0 = 0 := by
      rw [hs]
      linear_combination -lam * h0 - ((m : ℂ) - n * Complex.I) * h1 - (n : ℂ) ^ 2 * ξ 0 * Complex.I_sq
    have e1 : (lam ^ 2 - s ^ 2) * ξ 1 = 0 := by
      rw [hs]
      linear_combination -lam * h1 - ((m : ℂ) + n * Complex.I) * h0 - (n : ℂ) ^ 2 * ξ 1 * Complex.I_sq
    have hl : lam ^ 2 - s ^ 2 = 0 := by
      by_contra hne
      apply hξ
      funext i
      fin_cases i
      · exact (mul_eq_zero.1 e0).resolve_left hne
      · exact (mul_eq_zero.1 e1).resolve_left hne
    have : (lam - s) * (lam + s) = 0 := by linear_combination hl
    rcases mul_eq_zero.1 this with h | h
    · left; linear_combination h
    · right; linear_combination h
  · intro h
    have hl2 : lam ^ 2 = s ^ 2 := by
      rcases h with h | h
      · rw [h]
      · rw [h]; ring
    by_cases h0 : (m : ℂ) + n * Complex.I = 0
    · have hlam : lam = 0 := by
        have : lam ^ 2 = 0 := by
          rw [hl2, hs]
          linear_combination ((m : ℂ) - n * Complex.I) * h0 + (n : ℂ) ^ 2 * Complex.I_sq
        exact pow_eq_zero_iff (n := 2) (by norm_num) |>.1 this
      refine ⟨![1, 0], ?_, ?_⟩
      · intro hc
        have := congrFun hc 0
        simp at this
      · funext i
        fin_cases i <;> simp [h0, hlam]
    · refine ⟨![lam, (m : ℂ) + n * Complex.I], ?_, ?_⟩
      · intro hc
        have := congrFun hc 1
        exact h0 (by simpa using this)
      · funext i
        fin_cases i
        · simp
          rw [hs] at hl2
          linear_combination -hl2 - (n : ℂ) ^ 2 * Complex.I_sq
        · simp; ring

/-- **Spinors turn by half the angle.** The sandwich with the spin element
`q(θ) = cos(θ/2) − sin(θ/2) σ₁σ₂` turns the plane by `θ`: `q σ₁ q⁻¹ = cos θ σ₁ + sin θ σ₂` and
`q σ₂ q⁻¹ = −sin θ σ₁ + cos θ σ₂`. Yet after a full turn `q(360°) = −1`, and only after two
full turns `q(720°) = +1`: `q` and `−q` give the same rotation, the double cover. -/
theorem spin_element_double_cover (θ : ℝ) :
    spinElt θ * σ₁ * (spinElt θ)⁻¹ = (Real.cos θ : ℂ) • σ₁ + (Real.sin θ : ℂ) • σ₂ ∧
    spinElt θ * σ₂ * (spinElt θ)⁻¹ = (-(Real.sin θ) : ℂ) • σ₁ + (Real.cos θ : ℂ) • σ₂ ∧
    spinElt (2 * Real.pi) = -1 ∧ spinElt (4 * Real.pi) = 1 := by
  have h12 : σ₁ * σ₂ = !![Complex.I, 0; 0, -Complex.I] := by
    ext i j
    fin_cases i <;> fin_cases j <;> simp [σ₁, σ₂, Matrix.mul_apply, Fin.sum_univ_two]
  have hq : ∀ φ, spinElt φ = !![(Real.cos (φ / 2) : ℂ) - Complex.I * Real.sin (φ / 2), 0;
      0, (Real.cos (φ / 2) : ℂ) + Complex.I * Real.sin (φ / 2)] := by
    intro φ
    rw [spinElt, h12]
    ext i j
    fin_cases i <;> fin_cases j <;> simp <;> ring
  have hinv : (spinElt θ)⁻¹ = spinElt (-θ) := by
    apply Matrix.inv_eq_left_inv
    rw [hq, hq, neg_div, Real.cos_neg, Real.sin_neg]
    have hpy := Real.cos_sq_add_sin_sq (θ / 2)
    generalize Real.cos (θ / 2) = c at hpy ⊢
    generalize Real.sin (θ / 2) = s at hpy ⊢
    have hpy' : (c : ℂ) ^ 2 + (s : ℂ) ^ 2 = 1 := by exact_mod_cast hpy
    ext i j
    fin_cases i <;> fin_cases j <;> simp [Matrix.mul_apply, Fin.sum_univ_two]
    · linear_combination hpy' - (s : ℂ) ^ 2 * Complex.I_sq
    · linear_combination hpy' - (s : ℂ) ^ 2 * Complex.I_sq
  refine ⟨?_, ?_, ?_, ?_⟩
  · rw [hinv, hq, hq, neg_div, Real.cos_neg, Real.sin_neg]
    obtain ⟨φ, rfl⟩ : ∃ φ, θ = 2 * φ := ⟨θ / 2, by ring⟩
    rw [mul_div_cancel_left₀ _ two_ne_zero, Real.cos_two_mul', Real.sin_two_mul]
    generalize Real.cos φ = c
    generalize Real.sin φ = s
    ext i j
    fin_cases i <;> fin_cases j <;> simp [σ₁, σ₂, Matrix.mul_apply, Fin.sum_univ_two]
    · linear_combination (s : ℂ) ^ 2 * Complex.I_sq
    · linear_combination (s : ℂ) ^ 2 * Complex.I_sq
  · rw [hinv, hq, hq, neg_div, Real.cos_neg, Real.sin_neg]
    obtain ⟨φ, rfl⟩ : ∃ φ, θ = 2 * φ := ⟨θ / 2, by ring⟩
    rw [mul_div_cancel_left₀ _ two_ne_zero, Real.cos_two_mul', Real.sin_two_mul]
    generalize Real.cos φ = c
    generalize Real.sin φ = s
    ext i j
    fin_cases i <;> fin_cases j <;> simp [σ₁, σ₂, Matrix.mul_apply, Fin.sum_univ_two]
    · linear_combination (2 * (s : ℂ) * c - Complex.I * (s : ℂ) ^ 2) * Complex.I_sq
    · linear_combination (2 * (s : ℂ) * c + Complex.I * (s : ℂ) ^ 2) * Complex.I_sq
  · rw [spinElt, mul_div_cancel_left₀ _ two_ne_zero]
    simp
  · rw [spinElt, show 4 * Real.pi / 2 = 2 * Real.pi by ring]
    simp

/-! The card's whole-number worked examples. -/

-- Clifford rules for the Pauli matrices: σ₁σ₁ = 1, σ₂σ₂ = 1, σ₁σ₂ + σ₂σ₁ = 0, and σ₁σ₂ = iσ₃.
-- So σ₁, σ₂ meet the hypotheses of `dirac_sq_eq_neg_laplacian`, and the card's D squares to −Δ.
example : σ₁ * σ₁ = 1 ∧ σ₂ * σ₂ = 1 ∧ σ₁ * σ₂ + σ₂ * σ₁ = 0 ∧ σ₁ * σ₂ = Complex.I • σ₃ := by
  norm_num [σ₁, σ₂, σ₃, ← Matrix.ext_iff, Fin.forall_fin_two, Matrix.one_fin_two]

-- Torus eigenvalues: the modes (m, n) with m² + n² = 0, 1, 2, 4, 5 number 1, 4, 4, 4, 8, so
-- 0 appears twice (two constant spinors) and ±1, ±√2, ±2, ±√5 appear 4, 4, 4, 8 times each.
example : [0, 1, 2, 4, 5].map (fun k : ℤ =>
    ((Finset.Icc (-3 : ℤ) 3 ×ˢ Finset.Icc (-3 : ℤ) 3).filter
      (fun p => p.1 ^ 2 + p.2 ^ 2 = k)).card) = [1, 4, 4, 4, 8] := by decide
-- Mode (1, 2): eigenvalues ±√(1 + 4) = ±√5.  Mode (3, 4): ±√(9 + 16) = ±5.
example : (1 : ℤ) ^ 2 + 2 ^ 2 = 5 ∧ (3 : ℤ) ^ 2 + 4 ^ 2 = 5 ^ 2 := by norm_num
-- Commuting matrices, σ₁ twice, on mode (1, 1): (1 + 1)² = 4, not 1² + 1² = 2.
example : ((1 : ℤ) + 1) ^ 2 = 4 ∧ (1 : ℤ) ^ 2 + 1 ^ 2 = 2 := by norm_num
-- Torus Dirac index: (1, 0) in S⁺ and (0, 1) in S⁻, index 1 − 1 = 0.
example : (1 : ℤ) - 1 = 0 := by norm_num
-- Sphere: V − E + F = 4 − 6 + 4 = 2 and b₀ − b₁ + b₂ = 1 − 0 + 1 = 2; the d + δ kernels are
-- 2 on even forms and 0 on odd forms, index 2.
example : (4 : ℤ) - 6 + 4 = 2 ∧ (1 : ℤ) - 0 + 1 = 2 ∧ (2 : ℤ) - 0 = 2 := by norm_num
-- The simplicial d + δ on the sphere maps 4 + 4 = 8 numbers to 6, so its index is 8 − 6 = 2.
example : (4 : ℤ) + 4 - 6 = 2 := by norm_num
-- Torus: V − E + F = 9 − 27 + 18 = 0 and b₀ − b₁ + b₂ = 1 − 2 + 1 = 0.
example : (9 : ℤ) - 27 + 18 = 0 ∧ (1 : ℤ) - 2 + 1 = 0 := by norm_num
-- A disc, one flat triangle: V − E + F = 3 − 3 + 1 = 1.
example : (3 : ℤ) - 3 + 1 = 1 := by norm_num
-- K3: χ = 2 + 22 = 24 = c₂, p₁ = c₁² − 2c₂ = 0 − 48 = −48, signature 3 − 19 = −16 = p₁/3,
-- and Â = −p₁/24 = 2.
example : (2 : ℚ) + 22 = 24 ∧ (0 : ℚ) ^ 2 - 2 * 24 = -48 ∧ (3 : ℚ) - 19 = -16 ∧
    (-48 : ℚ) / 3 = -16 ∧ -(-48 : ℚ) / 24 = 2 := by norm_num
-- CP²: p₁ = 3, signature p₁/3 = 1, and Â = −p₁/24 = −1/8 = −0.125, not a whole number.
example : (3 : ℚ) / 3 = 1 ∧ -(3 : ℚ) / 24 = -1 / 8 := by norm_num
-- Riemann-Roch on the sphere, degree 3: d − g + 1 = 3 − 0 + 1 = 4 sections 1, z, z², z³.
example : (3 : ℤ) - 0 + 1 = 4 := by norm_num

#print axioms hasDerivAt_lineX
#print axioms hasDerivAt_lineY
#print axioms hasDerivAt_mulVec
#print axioms hasDerivAt_comb
#print axioms hasDerivAt_wave_line
#print axioms dirac_sq_eq_neg_laplacian
#print axioms torus_mode_eigenvalues
#print axioms spin_element_double_cover

end SpinorDirac
