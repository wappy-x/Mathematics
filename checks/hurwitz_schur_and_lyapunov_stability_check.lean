-- Stability of a state-space model: a constant linear model is Hurwitz exactly when its Lyapunov equation has a positive definite solution and exactly when every motion settles, and a step matrix is Schur exactly when its sampled Lyapunov equation has one.
import Mathlib.Analysis.Normed.Algebra.MatrixExponential
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.LinearAlgebra.Matrix.Charpoly.Eigs
import Mathlib

open Matrix Filter Topology

/-! ### Helper lemmas -/

lemma lyap_mem_spectrum_iff {n : Type*} [Fintype n] [DecidableEq n]
    (M : Matrix n n ℂ) (μ : ℂ) :
    μ ∈ spectrum ℂ M ↔ ∃ v : n → ℂ, v ≠ 0 ∧ M *ᵥ v = μ • v := by
  rw [← Matrix.spectrum_toLin', ← Module.End.hasEigenvalue_iff_mem_spectrum]
  constructor
  · intro h
    obtain ⟨v, hv⟩ := h.exists_hasEigenvector
    refine ⟨v, (Module.End.hasEigenvector_iff.mp hv).2, ?_⟩
    simpa [Matrix.toLin'_apply] using hv.apply_eq_smul
  · rintro ⟨v, hv0, hv⟩
    exact Module.End.hasEigenvalue_of_hasEigenvector
      (Module.End.hasEigenvector_iff.mpr ⟨Module.End.mem_eigenspace_iff.mpr
        (by simpa [Matrix.toLin'_apply] using hv), hv0⟩)

#print axioms lyap_mem_spectrum_iff

lemma lyap_re_quad_pos {n : Type*} [Fintype n] (P : Matrix n n ℝ) (hP : P.PosDef)
    (v : n → ℂ) (hv : v ≠ 0) : 0 < (star v ⬝ᵥ (P.map Complex.ofReal *ᵥ v)).re := by
  set a : n → ℝ := fun i => (v i).re
  set b : n → ℝ := fun i => (v i).im
  have key : (star v ⬝ᵥ (P.map Complex.ofReal *ᵥ v)).re = a ⬝ᵥ (P *ᵥ a) + b ⬝ᵥ (P *ᵥ b) := by
    simp only [dotProduct, mulVec, Complex.re_sum, Pi.star_apply, Complex.star_def,
      Complex.mul_re, Complex.conj_re, Complex.conj_im, Complex.im_sum, map_apply,
      Complex.im_ofReal_mul, a, b]
    rw [← Finset.sum_add_distrib]
    refine Finset.sum_congr rfl fun i _ => ?_
    rw [Finset.mul_sum, Finset.mul_sum, Finset.mul_sum, Finset.mul_sum, ← Finset.sum_sub_distrib,
      ← Finset.sum_add_distrib]
    refine Finset.sum_congr rfl fun j _ => ?_
    simp only [Complex.ofReal_re, Complex.ofReal_im]
    ring
  rw [key]
  have hpa := hP.posSemidef.dotProduct_mulVec_nonneg a
  have hpb := hP.posSemidef.dotProduct_mulVec_nonneg b
  simp only [star_trivial] at hpa hpb
  by_cases ha : a = 0
  · have hb : b ≠ 0 := by
      intro hb; apply hv; funext i
      apply Complex.ext
      · simpa [a] using congrFun ha i
      · simpa [b] using congrFun hb i
    have := hP.dotProduct_mulVec_pos hb
    simp only [star_trivial] at this
    linarith
  · have := hP.dotProduct_mulVec_pos ha
    simp only [star_trivial] at this
    linarith

#print axioms lyap_re_quad_pos

/-- `star (M *ᵥ v) = star v ᵥ* Mᵀ` for the complexification of a real matrix. -/
lemma lyap_star_mulVec_real {n : Type*} [Fintype n] (M : Matrix n n ℝ) (v : n → ℂ) :
    star (M.map Complex.ofReal *ᵥ v) = star v ᵥ* (M.map Complex.ofReal)ᵀ := by
  rw [star_mulVec]
  congr 1
  ext i j
  simp [conjTranspose_apply]

#print axioms lyap_star_mulVec_real

lemma lyap_map_mul {n : Type*} [Fintype n] (M N : Matrix n n ℝ) :
    (M * N).map Complex.ofReal = M.map Complex.ofReal * N.map Complex.ofReal :=
  Matrix.map_mul (f := Complex.ofRealHom)

#print axioms lyap_map_mul

lemma lyap_cont_forward {n : Type*} [Fintype n] [DecidableEq n]
    (A Q P : Matrix n n ℝ) (hQ : Q.PosDef) (hP : P.PosDef) (h : Aᵀ * P + P * A = -Q) :
    ∀ μ ∈ spectrum ℂ (A.map Complex.ofReal), μ.re < 0 := by
  intro μ hμ
  obtain ⟨v, hv0, hv⟩ := (lyap_mem_spectrum_iff _ μ).1 hμ
  have hc : (A.map Complex.ofReal)ᵀ * P.map Complex.ofReal + P.map Complex.ofReal * A.map Complex.ofReal
      = -Q.map Complex.ofReal := by
    have := congrArg (fun M => M.map Complex.ofReal) h
    simpa [Matrix.map_add, lyap_map_mul, Matrix.map_neg, Matrix.transpose_map] using this
  have hp := lyap_re_quad_pos P hP v hv0
  have hq := lyap_re_quad_pos Q hQ v hv0
  set p := star v ⬝ᵥ (P.map Complex.ofReal *ᵥ v)
  have hquad : star v ⬝ᵥ (((A.map Complex.ofReal)ᵀ * P.map Complex.ofReal
      + P.map Complex.ofReal * A.map Complex.ofReal) *ᵥ v) = (star μ + μ) * p := by
    rw [add_mulVec, dotProduct_add, ← mulVec_mulVec, ← mulVec_mulVec, hv, mulVec_smul,
      dotProduct_smul, dotProduct_mulVec, ← lyap_star_mulVec_real, hv, star_smul, smul_dotProduct]
    simp [p, add_mul]
  rw [hc, neg_mulVec, dotProduct_neg] at hquad
  have hre := congrArg Complex.re hquad
  rw [Complex.neg_re, Complex.star_def, Complex.mul_re, Complex.add_re, Complex.add_im,
    Complex.conj_re, Complex.conj_im] at hre
  simp only [neg_add_cancel, zero_mul, sub_zero] at hre
  by_contra hcon
  push Not at hcon
  nlinarith [mul_nonneg hcon hp.le]

#print axioms lyap_cont_forward

lemma lyap_disc_forward {n : Type*} [Fintype n] [DecidableEq n]
    (Ad Q P : Matrix n n ℝ) (hQ : Q.PosDef) (hP : P.PosDef) (h : Adᵀ * P * Ad - P = -Q) :
    ∀ μ ∈ spectrum ℂ (Ad.map Complex.ofReal), ‖μ‖ < 1 := by
  intro μ hμ
  obtain ⟨v, hv0, hv⟩ := (lyap_mem_spectrum_iff _ μ).1 hμ
  have hc : (Ad.map Complex.ofReal)ᵀ * P.map Complex.ofReal * Ad.map Complex.ofReal
      - P.map Complex.ofReal = -Q.map Complex.ofReal := by
    have := congrArg (fun M => M.map Complex.ofReal) h
    simpa [Matrix.map_sub, lyap_map_mul, Matrix.map_neg, Matrix.transpose_map] using this
  have hp := lyap_re_quad_pos P hP v hv0
  have hq := lyap_re_quad_pos Q hQ v hv0
  set p := star v ⬝ᵥ (P.map Complex.ofReal *ᵥ v)
  have hquad : star v ⬝ᵥ (((Ad.map Complex.ofReal)ᵀ * P.map Complex.ofReal * Ad.map Complex.ofReal
      - P.map Complex.ofReal) *ᵥ v) = (star μ * μ - 1) * p := by
    rw [sub_mulVec, dotProduct_sub, ← mulVec_mulVec, ← mulVec_mulVec, hv, mulVec_smul,
      dotProduct_mulVec, ← lyap_star_mulVec_real, hv, star_smul, smul_dotProduct, dotProduct_smul]
    simp [p, sub_mul, mul_assoc]
  rw [hc, neg_mulVec, dotProduct_neg] at hquad
  have hns : star μ * μ = ((Complex.normSq μ : ℝ) : ℂ) := by
    rw [Complex.normSq_eq_conj_mul_self]; rfl
  rw [hns] at hquad
  have hre := congrArg Complex.re hquad
  rw [Complex.neg_re, Complex.mul_re, Complex.sub_re, Complex.sub_im, Complex.ofReal_re,
    Complex.ofReal_im, Complex.one_re, Complex.one_im] at hre
  simp only [sub_zero, zero_mul] at hre
  have hlt : Complex.normSq μ < 1 := by
    by_contra hcon
    push Not at hcon
    nlinarith [mul_nonneg (sub_nonneg.2 hcon) hp.le]
  rw [Complex.normSq_eq_norm_sq] at hlt
  nlinarith [norm_nonneg μ]

#print axioms lyap_disc_forward

lemma lyap_map_pow {n : Type*} [Fintype n] [DecidableEq n] (M : Matrix n n ℝ) (k : ℕ) :
    (M ^ k).map Complex.ofReal = (M.map Complex.ofReal) ^ k :=
  map_pow (Complex.ofRealHom.mapMatrix) M k

#print axioms lyap_map_pow

open scoped Matrix.Norms.Operator in
lemma lyap_norm_map {n : Type*} [Fintype n] (M : Matrix n n ℝ) :
    ‖M.map Complex.ofReal‖ = ‖M‖ := by
  simp [linfty_opNorm_def]

#print axioms lyap_norm_map

open scoped Matrix.Norms.Operator in
lemma lyap_schur_pow_bound {n : Type*} [Fintype n] [DecidableEq n] (M : Matrix n n ℝ)
    (hM : ∀ μ ∈ spectrum ℂ (M.map Complex.ofReal), ‖μ‖ < 1) :
    ∃ C > 0, ∃ r : ℝ, 0 < r ∧ r < 1 ∧ ∀ k : ℕ, ‖M ^ k‖ ≤ C * r ^ k := by
  rcases isEmpty_or_nonempty n with hn | hn
  · refine ⟨1, one_pos, 1/2, by norm_num, by norm_num, fun k => ?_⟩
    rw [Subsingleton.elim (M ^ k) 0, norm_zero]; positivity
  · have hsr : spectralRadius ℂ (M.map Complex.ofReal) < 1 := by
      have := spectrum.spectralRadius_lt_of_forall_lt (M.map Complex.ofReal) (r := 1)
        (fun z hz => by
          have := hM z hz
          rw [← NNReal.coe_lt_coe, coe_nnnorm]; simpa using this)
      simpa using this
    rw [spectrum.spectralRadius_eq_gelfandRadius] at hsr
    have hg : gelfandRadius (M.map Complex.ofReal) < 1 := by
      rwa [ENNReal.ofReal_lt_one] at hsr
    have heq : gelfandRadius M = gelfandRadius (M.map Complex.ofReal) := by
      apply gelfandRadius_eq_of_norm_pow_eq
      intro k
      rw [← lyap_map_pow, lyap_norm_map]
    rw [← heq] at hg
    have h0 := gelfandRadius_nonneg M
    obtain ⟨C, hC, hb⟩ := norm_pow_le_mul_pow_of_gelfandRadius_lt M
      (r := (gelfandRadius M + 1) / 2) (by linarith)
    exact ⟨C, hC, (gelfandRadius M + 1) / 2, by linarith, by linarith, hb⟩

#print axioms lyap_schur_pow_bound

open scoped Matrix.Norms.Operator in
lemma lyap_disc_backward {n : Type*} [Fintype n] [DecidableEq n]
    (Ad Q : Matrix n n ℝ) (hQ : Q.PosDef)
    (hS : ∀ μ ∈ spectrum ℂ (Ad.map Complex.ofReal), ‖μ‖ < 1) :
    ∃ P : Matrix n n ℝ, P.PosDef ∧ Adᵀ * P * Ad - P = -Q := by
  obtain ⟨C₁, hC₁, r₁, hr₁0, hr₁1, h₁⟩ := lyap_schur_pow_bound Ad hS
  have hST : ∀ μ ∈ spectrum ℂ (Adᵀ.map Complex.ofReal), ‖μ‖ < 1 := by
    intro μ hμ; rw [Matrix.transpose_map, Matrix.spectrum_transpose] at hμ; exact hS μ hμ
  obtain ⟨C₂, hC₂, r₂, hr₂0, hr₂1, h₂⟩ := lyap_schur_pow_bound Adᵀ hST
  set f : ℕ → Matrix n n ℝ := fun k => (Adᵀ) ^ k * Q * Ad ^ k with hf
  have hsum : Summable f := by
    refine Summable.of_norm_bounded (g := fun k => C₂ * ‖Q‖ * C₁ * (r₂ * r₁) ^ k) ?_ ?_
    · exact (summable_geometric_of_lt_one (by positivity) (by nlinarith)).mul_left _
    · intro k
      calc ‖f k‖ ≤ ‖Adᵀ ^ k‖ * ‖Q‖ * ‖Ad ^ k‖ := by
            simp only [f]
            exact (norm_mul_le _ _).trans (by gcongr; exact norm_mul_le _ _)
        _ ≤ (C₂ * r₂ ^ k) * ‖Q‖ * (C₁ * r₁ ^ k) := by
            gcongr
            · exact h₂ k
            · exact h₁ k
        _ = _ := by rw [mul_pow]; ring
  set P := ∑' k, f k with hPdef
  have hf0 : f 0 = Q := by simp [f]
  have hshift : Adᵀ * P * Ad = ∑' k, f (k + 1) := by
    rw [hPdef, ← hsum.tsum_mul_left, ← (hsum.mul_left Adᵀ).tsum_mul_right]
    congr 1; funext k; simp only [f]; rw [pow_succ', pow_succ]; simp [Matrix.mul_assoc]
  have hP : P = Q + ∑' k, f (k + 1) := by rw [hPdef, hsum.tsum_eq_zero_add, hf0]
  have hfC : ∀ k, f k = (Ad ^ k)ᴴ * Q * Ad ^ k := by
    intro k; simp [f, conjTranspose_eq_transpose_of_trivial, transpose_pow]
  refine ⟨P, ?_, ?_⟩
  · refine PosDef.of_dotProduct_mulVec_pos ?_ ?_
    · show Pᴴ = P
      rw [hPdef, Matrix.conjTranspose_tsum]
      refine tsum_congr fun k => ?_
      rw [hfC k]
      exact isHermitian_conjTranspose_mul_mul (Ad ^ k) hQ.1
    · intro x hx
      let L : Matrix n n ℝ →+ ℝ := AddMonoidHom.mk' (fun M => star x ⬝ᵥ (M *ᵥ x))
        (by intro a b; simp [add_mulVec, dotProduct_add])
      have hL : Continuous L := by
        show Continuous fun M : Matrix n n ℝ => star x ⬝ᵥ (M *ᵥ x)
        fun_prop
      have hs := hsum.hasSum.map L hL
      have hle := le_hasSum hs 0 (fun j _ => by
        show 0 ≤ star x ⬝ᵥ (f j *ᵥ x)
        rw [hfC j]
        exact (hQ.posSemidef.conjTranspose_mul_mul_same (Ad ^ j)).dotProduct_mulVec_nonneg x)
      have hpos : 0 < star x ⬝ᵥ (f 0 *ᵥ x) := by rw [hf0]; exact hQ.dotProduct_mulVec_pos hx
      exact lt_of_lt_of_le hpos hle
  · rw [hshift, hP]; abel

#print axioms lyap_disc_backward

lemma lyap_cayley_schur (μ : ℂ) (hμ : μ + 1 ≠ 0) (h : ((μ - 1) / (μ + 1)).re < 0) : ‖μ‖ < 1 := by
  rw [Complex.div_re] at h
  have hn : 0 < Complex.normSq (μ + 1) := Complex.normSq_pos.2 hμ
  rw [← add_div] at h
  have h2 : (μ - 1).re * (μ + 1).re + (μ - 1).im * (μ + 1).im < 0 := by
    by_contra hc; push Not at hc
    have := div_nonneg hc hn.le; linarith
  simp only [Complex.sub_re, Complex.add_re, Complex.one_re, Complex.sub_im, Complex.add_im,
    Complex.one_im, sub_zero, add_zero] at h2
  have hsq : ‖μ‖ ^ 2 < 1 := by
    rw [← Complex.normSq_eq_norm_sq, Complex.normSq_apply]; nlinarith
  nlinarith [norm_nonneg μ]

#print axioms lyap_cayley_schur

lemma lyap_cont_backward {n : Type*} [Fintype n] [DecidableEq n]
    (A Q : Matrix n n ℝ) (hQ : Q.PosDef)
    (hH : ∀ μ ∈ spectrum ℂ (A.map Complex.ofReal), μ.re < 0) :
    ∃ P : Matrix n n ℝ, P.PosDef ∧ Aᵀ * P + P * A = -Q := by
  set B : Matrix n n ℝ := 1 - A with hBdef
  have hBmap : B.map Complex.ofReal = 1 - A.map Complex.ofReal := by
    simp [B, Matrix.map_sub, Matrix.map_one]
  have hB : IsUnit B.det := by
    rw [isUnit_iff_ne_zero]
    intro hdet
    have h1 : (1 : ℂ) ∈ spectrum ℂ (A.map Complex.ofReal) := by
      rw [spectrum.mem_iff, Matrix.isUnit_iff_isUnit_det, map_one, ← hBmap, isUnit_iff_ne_zero]
      intro h
      apply h
      have := RingHom.map_det Complex.ofRealHom B
      rw [hdet, map_zero] at this
      exact this.symm
    have := hH 1 h1
    norm_num at this
  set C : Matrix n n ℝ := B⁻¹ with hCdef
  have hCB : C * B = 1 := nonsing_inv_mul B hB
  have hBC : B * C = 1 := mul_nonsing_inv B hB
  set Ad : Matrix n n ℝ := (1 + A) * C with hAddef
  have hAdB : Ad * B = 1 + A := by rw [hAddef, Matrix.mul_assoc, hCB, Matrix.mul_one]
  have hcomm : B * (1 + A) = (1 + A) * B := by rw [hBdef]; noncomm_ring
  have hBAd : B * Ad = 1 + A := by
    rw [hAddef, ← Matrix.mul_assoc, hcomm, Matrix.mul_assoc, hBC, Matrix.mul_one]
  -- the Cayley transform is Schur
  have hS : ∀ μ ∈ spectrum ℂ (Ad.map Complex.ofReal), ‖μ‖ < 1 := by
    intro μ hμ
    obtain ⟨v, hv0, hv⟩ := (lyap_mem_spectrum_iff _ μ).1 hμ
    have hm : (1 - A.map Complex.ofReal) * Ad.map Complex.ofReal = 1 + A.map Complex.ofReal := by
      rw [← hBmap, ← lyap_map_mul, hBAd]; simp [Matrix.map_add, Matrix.map_one]
    have hv2 : ((1 - A.map Complex.ofReal) * Ad.map Complex.ofReal) *ᵥ v
        = (1 + A.map Complex.ofReal) *ᵥ v := by rw [hm]
    rw [← mulVec_mulVec, hv, mulVec_smul, sub_mulVec, add_mulVec, one_mulVec] at hv2
    -- hv2 : μ • (v - Ac v) = v + Ac v
    have hev : (μ + 1) • (A.map Complex.ofReal *ᵥ v) = (μ - 1) • v := by
      rw [smul_sub] at hv2
      have key : (μ + 1) • (A.map Complex.ofReal *ᵥ v) - (μ - 1) • v
          = -(μ • v - μ • (A.map Complex.ofReal *ᵥ v) - (v + A.map Complex.ofReal *ᵥ v)) := by
        rw [add_smul, sub_smul, one_smul, one_smul]; abel
      rw [hv2, sub_self, neg_zero] at key
      exact sub_eq_zero.1 key
    have hμ1 : μ + 1 ≠ 0 := by
      intro h0
      rw [h0, zero_smul] at hev
      have : μ - 1 = -2 := by linear_combination h0
      rw [this] at hev
      apply hv0
      have := congrArg (fun w => (-1/2 : ℂ) • w) hev
      simp only [smul_zero, smul_smul] at this
      norm_num at this
      exact this.symm
    have hlam : (μ - 1) / (μ + 1) ∈ spectrum ℂ (A.map Complex.ofReal) := by
      rw [lyap_mem_spectrum_iff]
      refine ⟨v, hv0, ?_⟩
      have := congrArg (fun w => (μ + 1)⁻¹ • w) hev
      simp only [smul_smul, inv_mul_cancel₀ hμ1, one_smul] at this
      rw [this, div_eq_inv_mul]
    exact lyap_cayley_schur μ hμ1 (hH _ hlam)
  have hCinj : Function.Injective C.mulVec := by
    intro x y hxy
    have := congrArg (fun w => B *ᵥ w) hxy
    simpa [mulVec_mulVec, hBC] using this
  have hQ' : ((2 : ℝ) • (Cᵀ * Q * C)).PosDef := by
    have := hQ.conjTranspose_mul_mul_same hCinj
    rw [conjTranspose_eq_transpose_of_trivial] at this
    exact this.smul (by norm_num)
  obtain ⟨P, hP, hPeq⟩ := lyap_disc_backward Ad _ hQ' hS
  refine ⟨P, hP, ?_⟩
  have e1 : Bᵀ * (Adᵀ * P * Ad - P) * B = (2 : ℝ) • (Aᵀ * P + P * A) := by
    have gen : ∀ X Y Z : Matrix n n ℝ,
        Yᵀ * (Xᵀ * Z * X - Z) * Y = (X * Y)ᵀ * Z * (X * Y) - Yᵀ * Z * Y := by
      intro X Y Z; rw [transpose_mul]; simp only [Matrix.mul_sub, Matrix.sub_mul, Matrix.mul_assoc]
    rw [gen, hAdB, hBdef, transpose_add, transpose_sub, transpose_one, two_smul]
    noncomm_ring
  have e2 : Bᵀ * (-((2 : ℝ) • (Cᵀ * Q * C))) * B = (2 : ℝ) • (-Q) := by
    have : Bᵀ * (Cᵀ * Q * C) * B = (C * B)ᵀ * Q * (C * B) := by
      rw [transpose_mul]; simp only [Matrix.mul_assoc]
    rw [Matrix.mul_neg, Matrix.neg_mul, Matrix.mul_smul, Matrix.smul_mul, this, hCB,
      transpose_one, Matrix.one_mul, Matrix.mul_one, smul_neg]
  rw [hPeq, e2] at e1
  exact (smul_right_injective _ (two_ne_zero : (2 : ℝ) ≠ 0) e1).symm

#print axioms lyap_cont_backward

open scoped Matrix.Norms.Operator in
lemma lyap_settle_forward {n : Type*} [Fintype n] [DecidableEq n] (A : Matrix n n ℝ)
    (h : ∀ x₀ : n → ℝ, Tendsto (fun t : ℝ => NormedSpace.exp (t • A) *ᵥ x₀) atTop (𝓝 0)) :
    ∀ μ ∈ spectrum ℂ (A.map Complex.ofReal), μ.re < 0 := by
  intro μ hμ
  rcases isEmpty_or_nonempty n with hn | hn
  · exfalso
    rw [spectrum.mem_iff] at hμ
    exact hμ (isUnit_of_subsingleton _)
  have hM : Tendsto (fun t : ℝ => NormedSpace.exp (t • A)) atTop (𝓝 0) := by
    apply tendsto_pi_nhds.2; intro i; apply tendsto_pi_nhds.2; intro j
    have := ((continuous_apply i).tendsto 0).comp (h (Pi.single j 1))
    simpa [Function.comp_def, mulVec_single_one] using this
  have hcont : Continuous (fun M : Matrix n n ℝ => M.map Complex.ofReal) :=
    continuous_id.matrix_map Complex.continuous_ofReal
  have hexp : ∀ t : ℝ, (NormedSpace.exp (t • A)).map Complex.ofReal
      = NormedSpace.exp (t • A.map Complex.ofReal) := by
    intro t
    have := NormedSpace.map_exp (Complex.ofRealHom.mapMatrix (m := n)) hcont (t • A)
    have hs : Complex.ofRealHom.mapMatrix (t • A) = t • A.map Complex.ofReal := by
      ext i j; simp [Complex.real_smul]
    rw [hs] at this
    exact this
  have hMc : Tendsto (fun t : ℝ => NormedSpace.exp (t • A.map Complex.ofReal)) atTop (𝓝 0) := by
    have := (hcont.tendsto 0).comp hM
    simp only [Function.comp_def, hexp] at this
    simpa using this
  set E := NormedSpace.exp (A.map Complex.ofReal) with hE
  have hseq : Tendsto (fun k : ℕ => E ^ k) atTop (𝓝 0) := by
    have := hMc.comp tendsto_natCast_atTop_atTop
    refine this.congr fun k => ?_
    simp only [Function.comp_apply]
    rw [Nat.cast_smul_eq_nsmul ℝ k, Matrix.exp_nsmul]
  have hnorm : Tendsto (fun k : ℕ => ‖E ^ k‖) atTop (𝓝 0) :=
    tendsto_zero_iff_norm_tendsto_zero.1 hseq
  have hmem : NormedSpace.exp μ ∈ spectrum ℂ E := spectrum.exp_mem_exp (𝕜 := ℂ) _ hμ
  have hle : ∀ k : ℕ, ‖NormedSpace.exp μ‖ ^ k ≤ ‖E ^ k‖ := by
    intro k
    have hk : NormedSpace.exp μ ^ k ∈ spectrum ℂ (E ^ k) := by
      rw [spectrum.map_pow]; exact ⟨_, hmem, rfl⟩
    rw [← norm_pow]
    exact spectrum.norm_le_norm_of_mem hk
  have hlt : ‖NormedSpace.exp μ‖ < 1 := by
    by_contra hc
    push Not at hc
    have h1 : ∀ k : ℕ, 1 ≤ ‖E ^ k‖ := fun k => (one_le_pow₀ hc).trans (hle k)
    have := ge_of_tendsto' hnorm h1
    linarith
  rw [← Complex.exp_eq_exp_ℂ, Complex.norm_exp] at hlt
  exact Real.exp_lt_one_iff.1 hlt

#print axioms lyap_settle_forward

lemma lyap_norm_sq_le {n : Type*} [Fintype n] (x : n → ℝ) : ‖x‖ ^ 2 ≤ x ⬝ᵥ x := by
  have h0 : 0 ≤ x ⬝ᵥ x := Finset.sum_nonneg fun i _ => mul_self_nonneg (x i)
  have : ‖x‖ ≤ Real.sqrt (x ⬝ᵥ x) := by
    refine (pi_norm_le_iff_of_nonneg (Real.sqrt_nonneg _)).2 fun i => ?_
    rw [Real.norm_eq_abs]
    apply Real.abs_le_sqrt
    have := Finset.single_le_sum (f := fun j => x j * x j) (fun j _ => mul_self_nonneg (x j))
      (Finset.mem_univ i)
    simpa [dotProduct, sq] using this
  calc ‖x‖ ^ 2 ≤ (Real.sqrt (x ⬝ᵥ x)) ^ 2 := by gcongr
    _ = x ⬝ᵥ x := Real.sq_sqrt h0

#print axioms lyap_norm_sq_le

lemma lyap_quad_bounds {n : Type*} [Fintype n] (P : Matrix n n ℝ) (hP : P.PosDef) :
    ∃ m M : ℝ, 0 < m ∧ 0 < M ∧ ∀ x : n → ℝ,
      m * ‖x‖ ^ 2 ≤ x ⬝ᵥ (P *ᵥ x) ∧ x ⬝ᵥ (P *ᵥ x) ≤ M * ‖x‖ ^ 2 := by
  rcases isEmpty_or_nonempty n with hn | hn
  · refine ⟨1, 1, one_pos, one_pos, fun x => ?_⟩
    have : x = 0 := Subsingleton.elim _ _
    subst this; simp
  · set q : (n → ℝ) → ℝ := fun x => x ⬝ᵥ (P *ᵥ x) with hq
    have hqc : Continuous q := by
      simp only [hq]
      exact continuous_id.dotProduct (continuous_const.matrix_mulVec continuous_id)
    have hK : IsCompact (Metric.sphere (0 : n → ℝ) 1) := isCompact_sphere 0 1
    have hne : (Metric.sphere (0 : n → ℝ) 1).Nonempty := NormedSpace.sphere_nonempty.2 zero_le_one
    obtain ⟨y0, hy0, hmin⟩ := hK.exists_isMinOn hne hqc.continuousOn
    obtain ⟨y1, hy1, hmax⟩ := hK.exists_isMaxOn hne hqc.continuousOn
    have hy0ne : y0 ≠ 0 := by
      intro h; rw [h] at hy0; simp at hy0
    have hm : 0 < q y0 := by
      have := hP.dotProduct_mulVec_pos hy0ne; simpa [q] using this
    have hscale : ∀ (c : ℝ) (x : n → ℝ), q (c • x) = c ^ 2 * q x := by
      intro c x; simp only [q, mulVec_smul, smul_dotProduct, dotProduct_smul, smul_eq_mul]; ring
    refine ⟨q y0, max (q y1) 1, hm, by positivity, fun x => ?_⟩
    by_cases hx : x = 0
    · subst hx; simp [q]
    have hxn : 0 < ‖x‖ := norm_pos_iff.2 hx
    set y := ‖x‖⁻¹ • x with hydef
    have hy : y ∈ Metric.sphere (0 : n → ℝ) 1 := by
      simp [y, norm_smul, hxn.ne']
    have hxy : x = ‖x‖ • y := by simp [y, smul_smul, hxn.ne']
    have hqx : q x = ‖x‖ ^ 2 * q y := by
      conv_lhs => rw [hxy]
      rw [hscale]
    have h1 := isMinOn_iff.1 hmin y hy
    have h2 := isMaxOn_iff.1 hmax y hy
    have hsq : 0 ≤ ‖x‖ ^ 2 := by positivity
    refine ⟨?_, ?_⟩
    · show q y0 * ‖x‖ ^ 2 ≤ q x
      rw [hqx]; nlinarith
    · show q x ≤ max (q y1) 1 * ‖x‖ ^ 2
      rw [hqx]
      have : q y ≤ max (q y1) 1 := h2.trans (le_max_left _ _)
      nlinarith

#print axioms lyap_quad_bounds

lemma lyap_quad_conj {n : Type*} [Fintype n] (E N : Matrix n n ℝ) (x₀ : n → ℝ) :
    x₀ ⬝ᵥ ((Eᵀ * N * E) *ᵥ x₀) = (E *ᵥ x₀) ⬝ᵥ (N *ᵥ (E *ᵥ x₀)) := by
  rw [← mulVec_mulVec, ← mulVec_mulVec, dotProduct_mulVec, vecMul_transpose]

#print axioms lyap_quad_conj

lemma lyap_hasDerivAt_linear {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    [FiniteDimensional ℝ E] (f : E →ₗ[ℝ] ℝ) {F : ℝ → E} {F' : E} {t : ℝ}
    (h : HasDerivAt F F' t) : HasDerivAt (fun s => f (F s)) (f F') t :=
  (LinearMap.toContinuousLinearMap f).hasFDerivAt.comp_hasDerivAt t h

#print axioms lyap_hasDerivAt_linear

open scoped Matrix.Norms.Operator in
lemma lyap_settle_backward {n : Type*} [Fintype n] [DecidableEq n] (A : Matrix n n ℝ)
    (hH : ∀ μ ∈ spectrum ℂ (A.map Complex.ofReal), μ.re < 0) (x₀ : n → ℝ) :
    Tendsto (fun t : ℝ => NormedSpace.exp (t • A) *ᵥ x₀) atTop (𝓝 0) := by
  obtain ⟨P, hP, hPeq⟩ := lyap_cont_backward A 1 PosDef.one hH
  obtain ⟨m, M, hm, hM, hb⟩ := lyap_quad_bounds P hP
  set x : ℝ → (n → ℝ) := fun t => NormedSpace.exp (t • A) *ᵥ x₀ with hx
  set g : ℝ → ℝ := fun t => x t ⬝ᵥ (P *ᵥ x t) with hg
  have hT : ∀ t : ℝ, NormedSpace.exp (t • Aᵀ) = (NormedSpace.exp (t • A))ᵀ := by
    intro t; rw [← transpose_smul, Matrix.exp_transpose]
  have hderiv : ∀ t, HasDerivAt g (-(x t ⬝ᵥ x t)) t := by
    intro t
    have h1 := hasDerivAt_exp_smul_const (𝕂 := ℝ) Aᵀ t
    have h2 := hasDerivAt_exp_smul_const' (𝕂 := ℝ) A t
    have hF := (h1.mul_const P).mul h2
    let ℓ : Matrix n n ℝ →ₗ[ℝ] ℝ :=
      { toFun := fun N => x₀ ⬝ᵥ (N *ᵥ x₀)
        map_add' := by intro a b; simp [add_mulVec, dotProduct_add]
        map_smul' := by intro c a; simp [smul_mulVec, dotProduct_smul] }
    have hG := lyap_hasDerivAt_linear ℓ hF
    convert hG using 1
    · funext s
      simp only [ℓ, LinearMap.coe_mk, AddHom.coe_mk, g, x, Pi.mul_apply]
      erw [hT, lyap_quad_conj]
    · simp only [ℓ, LinearMap.coe_mk, AddHom.coe_mk, x]
      erw [hT]
      have : (NormedSpace.exp (t • A))ᵀ * Aᵀ * P * NormedSpace.exp (t • A)
          + (NormedSpace.exp (t • A))ᵀ * P * (A * NormedSpace.exp (t • A))
          = (NormedSpace.exp (t • A))ᵀ * (Aᵀ * P + P * A) * NormedSpace.exp (t • A) := by
        simp only [Matrix.mul_add, Matrix.add_mul, Matrix.mul_assoc]
      erw [this]; rw [hPeq, lyap_quad_conj]
      simp [neg_mulVec]
  -- Gronwall-type estimate
  set c : ℝ := 1 / M with hc
  have hcpos : 0 < c := by positivity
  set h : ℝ → ℝ := fun t => Real.exp (c * t) * g t with hh
  have hhd : ∀ t, HasDerivAt h (Real.exp (c * t) * (c * 1) * g t
      + Real.exp (c * t) * (-(x t ⬝ᵥ x t))) t := by
    intro t
    exact (((hasDerivAt_id t).const_mul c).exp).mul (hderiv t)
  have hanti : Antitone h := by
    apply antitone_of_deriv_nonpos
    · intro t; exact (hhd t).differentiableAt
    · intro t
      rw [(hhd t).deriv]
      have hbd := (hb (x t)).2
      have hn2 := lyap_norm_sq_le (x t)
      have hg' : c * g t ≤ x t ⬝ᵥ x t := by
        have : g t ≤ M * (x t ⬝ᵥ x t) := hbd.trans (by gcongr)
        rw [hc, div_mul_eq_mul_div, one_mul, div_le_iff₀ hM]; linarith
      have he := Real.exp_pos (c * t)
      nlinarith
  have hbound : ∀ t, 0 ≤ t → m * ‖x t‖ ^ 2 ≤ g 0 * Real.exp (-(c * t)) := by
    intro t ht
    have h1 : h t ≤ h 0 := hanti ht
    simp only [hh, mul_zero, Real.exp_zero, one_mul] at h1
    have h2 : g t ≤ g 0 * Real.exp (-(c * t)) := by
      rw [Real.exp_neg, ← div_eq_mul_inv, le_div_iff₀ (Real.exp_pos _)]
      linarith [mul_comm (Real.exp (c * t)) (g t)]
    exact (hb (x t)).1.trans h2
  have hlim : Tendsto (fun t : ℝ => Real.sqrt (g 0 / m * Real.exp (-(c * t)))) atTop (𝓝 0) := by
    have he : Tendsto (fun t : ℝ => Real.exp (-(c * t))) atTop (𝓝 0) :=
      Real.tendsto_exp_atBot.comp
        (tendsto_neg_atTop_atBot.comp (Tendsto.const_mul_atTop hcpos tendsto_id))
    have := ((he.const_mul (g 0 / m)).sqrt)
    simpa using this
  rw [tendsto_zero_iff_norm_tendsto_zero]
  refine squeeze_zero' (Eventually.of_forall fun t => norm_nonneg _) ?_ hlim
  have hg0 : 0 ≤ g 0 := le_trans (by positivity) (hb (x 0)).1
  filter_upwards [eventually_ge_atTop 0] with t ht
  rw [Real.le_sqrt (norm_nonneg _) (by positivity), div_mul_eq_mul_div, le_div_iff₀ hm]
  linarith [hbound t ht, mul_comm m (‖x t‖ ^ 2)]

#print axioms lyap_settle_backward

/-- Continuous-time Lyapunov test. For a constant real rate matrix `A` and any chosen
positive definite `Q`, the equation `Aᵀ P + P A = -Q` has a positive definite solution `P`
exactly when `A` is Hurwitz: every (complex) eigenvalue of `A` has negative real part. -/
theorem lyapunov_equation_solvable_iff_hurwitz {n : Type*} [Fintype n] [DecidableEq n]
    (A Q : Matrix n n ℝ) (hQ : Q.PosDef) :
    (∃ P : Matrix n n ℝ, P.PosDef ∧ Aᵀ * P + P * A = -Q) ↔
      ∀ μ ∈ spectrum ℂ (A.map Complex.ofReal), μ.re < 0 := by
  exact ⟨fun ⟨P, hP, h⟩ => lyap_cont_forward A Q P hQ hP h, lyap_cont_backward A Q hQ⟩

/-- Sampled (discrete-time) Lyapunov test. For a constant real step matrix `Ad` and any chosen
positive definite `Q`, the equation `Adᵀ P Ad - P = -Q` has a positive definite solution `P`
exactly when `Ad` is Schur: every (complex) eigenvalue of `Ad` has size below 1. -/
theorem discrete_lyapunov_equation_solvable_iff_schur {n : Type*} [Fintype n] [DecidableEq n]
    (Ad Q : Matrix n n ℝ) (hQ : Q.PosDef) :
    (∃ P : Matrix n n ℝ, P.PosDef ∧ Adᵀ * P * Ad - P = -Q) ↔
      ∀ μ ∈ spectrum ℂ (Ad.map Complex.ofReal), ‖μ‖ < 1 := by
  exact ⟨fun ⟨P, hP, h⟩ => lyap_disc_forward Ad Q P hQ hP h, lyap_disc_backward Ad Q hQ⟩

/-- A linear model `x' = A x` with constant `A` settles (every motion `e^(At) x₀` tends to rest)
exactly when `A` is Hurwitz: every eigenvalue of `A` has negative real part. -/
theorem linear_model_settles_iff_hurwitz {n : Type*} [Fintype n] [DecidableEq n]
    (A : Matrix n n ℝ) :
    (∀ x₀ : n → ℝ, Tendsto (fun t : ℝ => NormedSpace.exp (t • A) *ᵥ x₀) atTop (𝓝 0)) ↔
      ∀ μ ∈ spectrum ℂ (A.map Complex.ofReal), μ.re < 0 := by
  exact ⟨lyap_settle_forward A, fun hH x₀ => lyap_settle_backward A hH x₀⟩

/-! ### The card's worked numbers, exactly -/

-- The open tilt pair `[[0, 1], [16, 0]]`: trace 0 and determinant -16, so eigenvalues 4 and -4,
-- which sum to zero.
example : Matrix.trace !![(0 : ℝ), 1; 16, 0] = 0 ∧ Matrix.det !![(0 : ℝ), 1; 16, 0] = -16 := by
  constructor
  · simp [Matrix.trace, Fin.sum_univ_two]
  · simp [Matrix.det_fin_two_of]
example : ((4 : ℝ) ^ 2 - 16 = 0) ∧ ((-4 : ℝ) ^ 2 - 16 = 0) ∧ (4 : ℝ) + (-4) = 0 := by norm_num

-- The angle loop `[[0, 1], [-8, -6]]`: trace -6, determinant 8, eigenvalues -2 and -4.
example : Matrix.trace !![(0 : ℝ), 1; -8, -6] = -6 ∧ Matrix.det !![(0 : ℝ), 1; -8, -6] = 8 := by
  constructor
  · simp [Matrix.trace, Fin.sum_univ_two]
  · simp [Matrix.det_fin_two_of]
example : ((-2 : ℝ) ^ 2 + 6 * (-2) + 8 = 0) ∧ ((-4 : ℝ) ^ 2 + 6 * (-4) + 8 = 0) := by norm_num

-- The certificate P = [[9/8, 1/16], [1/16, 3/32]] (1.125, 0.0625, 0.09375) solves Aᵀ P + P A = -I.
example :
    (!![(0 : ℝ), 1; -8, -6])ᵀ * !![(9 / 8 : ℝ), 1 / 16; 1 / 16, 3 / 32]
      + !![(9 / 8 : ℝ), 1 / 16; 1 / 16, 3 / 32] * !![(0 : ℝ), 1; -8, -6] = -1 := by
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [Matrix.mul_apply, Fin.sum_univ_two, Matrix.transpose_apply] <;> norm_num

-- Its leading minors 9/8 and 13/128 (1.125 and 0.1015625) are both positive.
example : (0 : ℝ) < 9 / 8 ∧ (9 / 8 : ℝ) * (3 / 32) - (1 / 16) ^ 2 = 13 / 128 ∧ (0 : ℝ) < 13 / 128 := by
  norm_num

-- The score at tilt 1/10 rad, rest otherwise: V = 9/800 (0.011250) and V' = -1/100 (-0.010000).
example : (9 / 8 : ℝ) * (1 / 10) ^ 2 = 9 / 800 ∧ -((1 / 10 : ℝ) ^ 2) = -1 / 100 := by norm_num

-- Rate gain with the wrong sign, `[[0, 1], [-8, 6]]`: P = [[-9/8, 1/16], [1/16, -3/32]] solves the
-- equation, but its top-left entry is negative, so it is not positive definite.
example :
    (!![(0 : ℝ), 1; -8, 6])ᵀ * !![(-9 / 8 : ℝ), 1 / 16; 1 / 16, -3 / 32]
      + !![(-9 / 8 : ℝ), 1 / 16; 1 / 16, -3 / 32] * !![(0 : ℝ), 1; -8, 6] = -1 := by
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [Matrix.mul_apply, Fin.sum_univ_two, Matrix.transpose_apply] <;> norm_num
example : ((4 : ℝ) ^ 2 - 6 * 4 + 8 = 0) ∧ ((2 : ℝ) ^ 2 - 6 * 2 + 8 = 0) := by norm_num

-- The full loop's polynomial s^4 + 10 s^3 + 35 s^2 + 50 s + 24 is (s+1)(s+2)(s+3)(s+4).
example (s : ℝ) : s ^ 4 + 10 * s ^ 3 + 35 * s ^ 2 + 50 * s + 24 = (s + 1) * (s + 2) * (s + 3) * (s + 4) := by
  ring

-- Q = diag(10, 1) on the angle loop gives P = [[21/4, 5/8], [5/8, 3/16]] (5.25, 0.625, 0.1875).
example :
    (!![(0 : ℝ), 1; -8, -6])ᵀ * !![(21 / 4 : ℝ), 5 / 8; 5 / 8, 3 / 16]
      + !![(21 / 4 : ℝ), 5 / 8; 5 / 8, 3 / 16] * !![(0 : ℝ), 1; -8, -6] = -!![(10 : ℝ), 0; 0, 1] := by
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [Matrix.mul_apply, Fin.sum_univ_two, Matrix.transpose_apply] <;> norm_num

#print axioms lyapunov_equation_solvable_iff_hurwitz
#print axioms discrete_lyapunov_equation_solvable_iff_schur
#print axioms linear_model_settles_iff_hurwitz
