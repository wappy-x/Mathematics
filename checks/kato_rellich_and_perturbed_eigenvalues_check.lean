-- Kato-Rellich: a symmetric addition bounded by a fraction a < 1 of a self-adjoint operator plus a constant leaves it self-adjoint on the same domain, the lower eigenvalue of [[1, e], [e, 2]] is within e^4 above 1 - e^2, and e^(-r/2) solves the hydrogen equation with energy -1/4.
import Mathlib.Analysis.InnerProductSpace.LinearPMap
import Mathlib.Analysis.InnerProductSpace.Laplacian
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.LinearAlgebra.Eigenspace.Basic
import Mathlib.LinearAlgebra.Matrix.ToLin
import Mathlib.Topology.MetricSpace.Contracting
import Mathlib.Analysis.InnerProductSpace.Calculus
import Mathlib.Analysis.SpecialFunctions.ExpDeriv
import Mathlib.Analysis.Calculus.Deriv.Inv

open Laplacian

section ProofHelpers

open scoped InnerProductSpace ComplexConjugate Topology
open LinearPMap InnerProductSpace

lemma kr_sa_mem {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℂ E] [CompleteSpace E]
    {A : E →ₗ.[ℂ] E} (hA : IsSelfAdjoint A) {y z : E}
    (h : ∀ x : A.domain, ⟪z, (x : E)⟫_ℂ = ⟪y, A x⟫_ℂ) :
    ∃ hy : y ∈ A.domain, A ⟨y, hy⟩ = z := by
  have hd := hA.dense_domain
  have hy : y ∈ A†.domain := mem_adjoint_domain_of_exists y ⟨z, h⟩
  have he : A† ⟨y, hy⟩ = z := adjoint_apply_eq hd ⟨y, hy⟩ h
  have key : ∀ T : E →ₗ.[ℂ] E, T = A → ∀ (h : y ∈ T.domain), T ⟨y, h⟩ = z →
      ∃ h' : y ∈ A.domain, A ⟨y, h'⟩ = z := by
    rintro T rfl h e; exact ⟨h, e⟩
  exact key _ (isSelfAdjoint_def.mp hA) hy he

lemma kr_symm {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℂ E] [CompleteSpace E]
    {A : E →ₗ.[ℂ] E} (hA : IsSelfAdjoint A) : A.IsFormalAdjoint A := by
  have h := adjoint_isFormalAdjoint (T := A) hA.dense_domain
  have key : ∀ T, T = A → T.IsFormalAdjoint A → A.IsFormalAdjoint A := by
    rintro T rfl h; exact h
  exact key _ (isSelfAdjoint_def.mp hA) h

lemma kr_norm_sq {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℂ E] [CompleteSpace E]
    {A : E →ₗ.[ℂ] E} (hA : IsSelfAdjoint A) (ν : ℝ) (p : A.domain) :
    ‖A p + ((ν : ℂ) * Complex.I) • (p : E)‖ ^ 2 = ‖A p‖ ^ 2 + ν ^ 2 * ‖(p : E)‖ ^ 2 := by
  have hs : ⟪A p, (p : E)⟫_ℂ = ⟪(p : E), A p⟫_ℂ := kr_symm hA p p
  have him : (⟪A p, (p : E)⟫_ℂ).im = 0 := by
    have h2 : conj ⟪A p, (p : E)⟫_ℂ = ⟪A p, (p : E)⟫_ℂ := by
      rw [inner_conj_symm, hs]
    exact Complex.conj_eq_iff_im.mp h2
  rw [@norm_add_sq ℂ, inner_smul_right, norm_smul]
  simp [him, mul_pow]

lemma kr_lb {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℂ E] [CompleteSpace E]
    {A : E →ₗ.[ℂ] E} (hA : IsSelfAdjoint A) (ν : ℝ) (p : A.domain) :
    |ν| * ‖(p : E)‖ ≤ ‖A p + ((ν : ℂ) * Complex.I) • (p : E)‖ ∧
    ‖A p‖ ≤ ‖A p + ((ν : ℂ) * Complex.I) • (p : E)‖ := by
  have h := kr_norm_sq hA ν p
  have h1 : 0 ≤ |ν| * ‖(p : E)‖ := by positivity
  have h2 : 0 ≤ ‖A p + ((ν : ℂ) * Complex.I) • (p : E)‖ := norm_nonneg _
  have h3 : (|ν| * ‖(p : E)‖) ^ 2 = ν ^ 2 * ‖(p : E)‖ ^ 2 := by rw [mul_pow, sq_abs]
  constructor
  · nlinarith [sq_nonneg (‖A p‖), norm_nonneg (A p)]
  · nlinarith [sq_nonneg (‖A p‖), norm_nonneg (A p), sq_nonneg (ν * ‖(p : E)‖)]

lemma kr_surj {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℂ E] [CompleteSpace E]
    {A : E →ₗ.[ℂ] E} (hA : IsSelfAdjoint A) {ν : ℝ} (hν : ν ≠ 0) (f : E) :
    ∃ p : A.domain, A p + ((ν : ℂ) * Complex.I) • (p : E) = f := by
  have hν' : 0 < |ν| := abs_pos.mpr hν
  let L : A.graph →L[ℂ] E :=
    (ContinuousLinearMap.snd ℂ E E + ((ν : ℂ) * Complex.I) • ContinuousLinearMap.fst ℂ E E).comp
      A.graph.subtypeL
  have hL : ∀ q : A.graph, L q = (q : E × E).2 + ((ν : ℂ) * Complex.I) • (q : E × E).1 :=
    fun q => rfl
  have hq : ∀ q : A.graph, ∃ y : A.domain, (y : E) = (q : E × E).1 ∧ A y = (q : E × E).2 :=
    fun q => (mem_graph_iff A).mp q.2
  have : CompleteSpace A.graph := hA.isClosed.completeSpace_coe
  have hanti : AntilipschitzWith (Real.toNNReal (1 + 1 / |ν|)) L := by
    apply AntilipschitzWith.of_le_mul_dist
    intro q₁ q₂
    rw [dist_eq_norm, dist_eq_norm, ← _root_.map_sub]
    obtain ⟨y, hy1, hy2⟩ := hq (q₁ - q₂)
    have hlb := kr_lb hA ν y
    rw [hy1, hy2, ← hL] at hlb
    rw [Real.coe_toNNReal _ (by positivity)]
    have hn : ‖q₁ - q₂‖ ≤ ‖((q₁ - q₂ : A.graph) : E × E).1‖ + ‖((q₁ - q₂ : A.graph) : E × E).2‖ := by
      show ‖((q₁ - q₂ : A.graph) : E × E)‖ ≤ _
      rw [Prod.norm_def]
      exact max_le_add_of_nonneg (norm_nonneg _) (norm_nonneg _)
    have h1 : ‖((q₁ - q₂ : A.graph) : E × E).1‖ ≤ 1 / |ν| * ‖L (q₁ - q₂)‖ := by
      rw [one_div, ← div_eq_inv_mul, le_div_iff₀ hν']
      linarith [hlb.1]
    linarith [hlb.2]
  have hcl : IsClosed (Set.range L) := hanti.isClosed_range L.uniformContinuous
  set S : Submodule ℂ E := LinearMap.range (L : A.graph →ₗ[ℂ] E) with hSdef
  have hSc : IsClosed (S : Set E) := by
    rw [hSdef, LinearMap.coe_range]; simpa using hcl
  have : CompleteSpace S := hSc.completeSpace_coe
  have hbot : Sᗮ = ⊥ := by
    rw [Submodule.eq_bot_iff]
    intro w hw
    rw [Submodule.mem_orthogonal] at hw
    have h0 : ∀ x : A.domain, ⟪A x + ((ν : ℂ) * Complex.I) • (x : E), w⟫_ℂ = 0 := fun x =>
      hw _ ⟨⟨((x : E), A x), mem_graph A x⟩, rfl⟩
    have h1 : ∀ x : A.domain, ⟪((ν : ℂ) * Complex.I) • w, (x : E)⟫_ℂ = ⟪w, A x⟫_ℂ := by
      intro x
      have h' := inner_eq_zero_symm.mp (h0 x)
      rw [inner_add_right, inner_smul_right] at h'
      rw [inner_smul_left]
      simp only [map_mul, Complex.conj_ofReal, Complex.conj_I]
      linear_combination -h'
    obtain ⟨hw', hAw⟩ := kr_sa_mem hA h1
    have hlb := (kr_lb hA (-ν) ⟨w, hw'⟩).1
    rw [hAw] at hlb
    have hz : ((ν : ℂ) * Complex.I) • w + (((-ν : ℝ) : ℂ) * Complex.I) • (w : E) = 0 := by
      rw [← add_smul]; simp
    simp only [hz, norm_zero, abs_neg] at hlb
    have : ‖w‖ ≤ 0 := by nlinarith [norm_nonneg w]
    exact norm_le_zero_iff.mp this
  have hS_top : S = ⊤ := Submodule.orthogonal_eq_bot_iff.mp hbot
  have hfS : f ∈ S := by rw [hS_top]; trivial
  obtain ⟨q, hqf⟩ := LinearMap.mem_range.mp hfS
  obtain ⟨y, hy1, hy2⟩ := hq q
  exact ⟨y, by rw [hy1, hy2, ← hL]; exact hqf⟩

lemma kr_surjT {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℂ E] [CompleteSpace E]
    {A V : E →ₗ.[ℂ] E} (hA : IsSelfAdjoint A)
    (hdom : A.domain ≤ V.domain) {a b : ℝ} (ha : a < 1)
    (hbound : ∀ u : A.domain, ‖V ⟨(u : E), hdom u.2⟩‖ ≤ a * ‖A u‖ + b * ‖(u : E)‖)
    {ν : ℝ} (hν : 2 * (max b 0 + 1) / (1 - max a 0) ≤ |ν|) (f : E) :
    ∃ x : A.domain, A x + V ⟨(x : E), hdom x.2⟩ + ((ν : ℂ) * Complex.I) • (x : E) = f := by
  set a' := max a 0 with ha'def
  set b' := max b 0 with hb'def
  have ha' : a' < 1 := max_lt ha (by norm_num)
  have ha0 : 0 ≤ a' := le_max_right _ _
  have hb0 : 0 ≤ b' := le_max_right _ _
  have haa : a ≤ a' := le_max_left _ _
  have hbb : b ≤ b' := le_max_left _ _
  have hpos : 0 < 2 * (b' + 1) / (1 - a') := by apply div_pos <;> linarith
  have hν' : 0 < |ν| := lt_of_lt_of_le hpos hν
  have hν0 : ν ≠ 0 := abs_pos.mp hν'
  have hb' : b' ≤ (1 - a') / 2 * |ν| := by
    rw [div_le_iff₀ (by linarith)] at hν
    nlinarith
  choose R hR using kr_surj hA hν0
  let K : E → E := fun g => V ⟨(R g : E), hdom (R g).2⟩
  have hK : ∀ g h, ‖K g - K h‖ ≤ ((1 + a') / 2) * ‖g - h‖ := by
    intro g h
    have hp : A (R g - R h) + ((ν : ℂ) * Complex.I) • ((R g - R h : A.domain) : E) = g - h := by
      calc A (R g - R h) + ((ν : ℂ) * Complex.I) • ((R g - R h : A.domain) : E)
          = (A (R g) + ((ν : ℂ) * Complex.I) • (R g : E))
            - (A (R h) + ((ν : ℂ) * Complex.I) • (R h : E)) := by
            rw [LinearPMap.map_sub, Submodule.coe_sub, smul_sub]; abel
        _ = g - h := by rw [hR g, hR h]
    have hlb := kr_lb hA ν (R g - R h)
    rw [hp] at hlb
    have hKs : K g - K h = V ⟨((R g - R h : A.domain) : E), hdom (R g - R h).2⟩ := by
      rw [← LinearPMap.map_sub]; rfl
    rw [hKs]
    have hbd := hbound (R g - R h)
    have n1 := norm_nonneg (A (R g - R h))
    have n2 := norm_nonneg ((R g - R h : A.domain) : E)
    have n3 := norm_nonneg (g - h)
    have e1 : a * ‖A (R g - R h)‖ ≤ a' * ‖g - h‖ :=
      (mul_le_mul_of_nonneg_right haa n1).trans (mul_le_mul_of_nonneg_left hlb.2 ha0)
    have e2 : b * ‖((R g - R h : A.domain) : E)‖ ≤ (1 - a') / 2 * ‖g - h‖ := by
      have s1 := mul_le_mul_of_nonneg_right hbb n2
      have s2 := mul_le_mul_of_nonneg_right hb' n2
      have s3 := mul_le_mul_of_nonneg_left hlb.1 (show 0 ≤ (1 - a') / 2 by linarith)
      nlinarith
    linarith
  have hq1 : (1 + a') / 2 < 1 := by linarith
  have hq0 : 0 ≤ (1 + a') / 2 := by linarith
  have hcon : ContractingWith (Real.toNNReal ((1 + a') / 2)) (fun g => f - K g) := by
    refine ⟨Real.toNNReal_lt_one.mpr hq1, ?_⟩
    apply LipschitzWith.of_dist_le_mul
    intro g h
    rw [Real.coe_toNNReal _ hq0, dist_eq_norm, dist_eq_norm]
    rw [show f - K g - (f - K h) = -(K g - K h) by abel, norm_neg]
    exact hK g h
  set g := ContractingWith.fixedPoint _ hcon
  have hfix : f - K g = g := hcon.fixedPoint_isFixedPt
  have hgf : g + K g = f := eq_sub_iff_add_eq.mp hfix.symm
  refine ⟨R g, ?_⟩
  calc A (R g) + V ⟨(R g : E), hdom (R g).2⟩ + ((ν : ℂ) * Complex.I) • (R g : E)
      = (A (R g) + ((ν : ℂ) * Complex.I) • (R g : E)) + K g := by
        simp only [K]; abel
    _ = g + K g := by rw [hR g]
    _ = f := hgf

theorem kato_rellich_aux {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℂ E] [CompleteSpace E]
    (A V : E →ₗ.[ℂ] E) (hA : IsSelfAdjoint A) (hV : V.IsFormalAdjoint V)
    (hdom : A.domain ≤ V.domain) {a b : ℝ} (ha : a < 1)
    (hbound : ∀ u : A.domain, ‖V ⟨(u : E), hdom u.2⟩‖ ≤ a * ‖A u‖ + b * ‖(u : E)‖) :
    IsSelfAdjoint (A + V) ∧ (A + V).domain = A.domain := by
  have hTdom : (A + V).domain = A.domain := by
    rw [LinearPMap.add_domain]; exact inf_eq_left.mpr hdom
  have hmem : ∀ x : A.domain, (x : E) ∈ (A + V).domain := fun x => ⟨x.2, hdom x.2⟩
  have happ : ∀ x : A.domain, (A + V) ⟨x, hmem x⟩ = A x + V ⟨x, hdom x.2⟩ := fun x => rfl
  have hTdense : Dense ((A + V).domain : Set E) := by rw [hTdom]; exact hA.dense_domain
  have hsymA := kr_symm hA
  have hTsymm : (A + V).IsFormalAdjoint (A + V) := by
    intro x y
    rw [LinearPMap.add_apply, LinearPMap.add_apply, inner_add_left, inner_add_right]
    exact congrArg₂ (· + ·) (hsymA ⟨x, x.2.1⟩ ⟨y, y.2.1⟩) (hV ⟨x, x.2.2⟩ ⟨y, y.2.2⟩)
  have hle : A + V ≤ (A + V)† := hTsymm.le_adjoint hTdense
  have hadj := adjoint_isFormalAdjoint hTdense
  set ν0 := 2 * (max b 0 + 1) / (1 - max a 0) with hν0
  have hdom2 : (A + V)†.domain ≤ (A + V).domain := by
    intro y hy
    set w := (A + V)† ⟨y, hy⟩ with hw
    obtain ⟨x, hx⟩ := kr_surjT hA hdom ha hbound (ν := ν0) (le_abs_self _)
      (w + ((ν0 : ℂ) * Complex.I) • y)
    obtain ⟨z, hz⟩ := kr_surjT hA hdom ha hbound (ν := -ν0) (by rw [abs_neg]; exact le_abs_self _)
      (y - x)
    have k1 : ⟪w, (z : E)⟫_ℂ = ⟪y, (A + V) ⟨z, hmem z⟩⟫_ℂ := hadj ⟨y, hy⟩ ⟨z, hmem z⟩
    have k2 : ⟪(A + V) ⟨x, hmem x⟩, (z : E)⟫_ℂ = ⟪(x : E), (A + V) ⟨z, hmem z⟩⟫_ℂ :=
      hTsymm ⟨x, hmem x⟩ ⟨z, hmem z⟩
    rw [happ] at k1 k2
    rw [happ] at k2
    have hTx : A x + V ⟨x, hdom x.2⟩ = w + ((ν0 : ℂ) * Complex.I) • y
        - ((ν0 : ℂ) * Complex.I) • (x : E) := eq_sub_of_add_eq hx
    rw [hTx, inner_sub_left, inner_add_left, inner_smul_left, inner_smul_left] at k2
    have hyx : ⟪y - x, y - (x : E)⟫_ℂ = 0 := by
      calc ⟪y - x, y - (x : E)⟫_ℂ
          = ⟪y - x, A z + V ⟨z, hdom z.2⟩ + (((-ν0 : ℝ) : ℂ) * Complex.I) • (z : E)⟫_ℂ := by
            rw [hz]
        _ = 0 := by
          rw [inner_add_right, inner_sub_left, inner_sub_left, ← k1, ← k2, inner_smul_right,
            inner_smul_right]
          simp only [map_mul, Complex.conj_ofReal, Complex.conj_I, Complex.ofReal_neg]
          ring
    have hyx' : y = x := sub_eq_zero.mp (inner_self_eq_zero.mp hyx)
    rw [hTdom, hyx']
    exact x.2
  have hdomeq : (A + V).domain = (A + V)†.domain := le_antisymm hle.1 hdom2
  exact ⟨isSelfAdjoint_def.mpr (LinearPMap.eq_of_le_of_domain_eq hle hdomeq).symm, hTdom⟩

lemma two_level_eig_iff (e μ : ℝ) (v : Fin 2 → ℝ) :
    Matrix.toLin' !![1, e; e, 2] v = μ • v ↔ v 0 + e * v 1 = μ * v 0 ∧ e * v 0 + 2 * v 1 = μ * v 1 := by
  rw [Matrix.toLin'_apply, funext_iff]
  simp [Fin.forall_fin_two, Matrix.mulVec, dotProduct, Fin.sum_univ_two]

theorem two_level_second_order_aux (e : ℝ) :
    Module.End.HasEigenvalue (Matrix.toLin' !![1, e; e, 2]) ((3 - Real.sqrt (1 + 4 * e ^ 2)) / 2)
    ∧ (∀ μ : ℝ, Module.End.HasEigenvalue (Matrix.toLin' !![1, e; e, 2]) μ →
        (3 - Real.sqrt (1 + 4 * e ^ 2)) / 2 ≤ μ)
    ∧ 0 ≤ (3 - Real.sqrt (1 + 4 * e ^ 2)) / 2 - (1 - e ^ 2)
    ∧ (3 - Real.sqrt (1 + 4 * e ^ 2)) / 2 - (1 - e ^ 2) ≤ e ^ 4 := by
  set s := Real.sqrt (1 + 4 * e ^ 2) with hs
  have hs0 : 0 ≤ s := Real.sqrt_nonneg _
  have hs2 : s ^ 2 = 1 + 4 * e ^ 2 := Real.sq_sqrt (by positivity)
  refine ⟨?_, ?_, ?_, ?_⟩
  · apply Module.End.hasEigenvalue_of_hasEigenvector (x := ![(1 + s) / 2, -e])
    refine ⟨?_, ?_⟩
    · rw [Module.End.mem_eigenspace_iff, two_level_eig_iff]
      simp
      constructor <;> nlinarith
    · intro h
      have := congrFun h 0
      simp at this
      linarith
  · intro μ hμ
    obtain ⟨v, hv⟩ := hμ.exists_hasEigenvector
    have hv1 := (two_level_eig_iff e μ v).mp (Module.End.mem_eigenspace_iff.mp hv.1)
    have hchar : (1 - μ) * (2 - μ) - e ^ 2 = 0 := by
      by_contra hne
      apply hv.2
      funext i
      fin_cases i
      · simp
        apply (mul_left_cancel₀ hne)
        linear_combination (2 - μ) * hv1.1 - e * hv1.2
      · simp
        apply (mul_left_cancel₀ hne)
        linear_combination (1 - μ) * hv1.2 - e * hv1.1
    nlinarith [sq_nonneg (2 * μ - 3 + s)]
  · nlinarith [sq_nonneg e, sq_nonneg (1 + 2 * e ^ 2 - s)]
  · rcases le_or_gt (e ^ 2) 2 with h | h
    · have hL : (1 + 2 * e ^ 2 - 2 * (e ^ 2) ^ 2) ^ 2 ≤ s ^ 2 := by
        nlinarith [mul_nonneg (pow_nonneg (sq_nonneg e) 3) (sub_nonneg.mpr h)]
      have hL' : 1 + 2 * e ^ 2 - 2 * (e ^ 2) ^ 2 ≤ s := by
        nlinarith [sq_nonneg (1 + 2 * e ^ 2 - 2 * (e ^ 2) ^ 2 + s)]
      nlinarith
    · nlinarith [sq_nonneg e]

lemma hyd_norm {F : Type*} [NormedAddCommGroup F] [InnerProductSpace ℝ F] {y : F} (hy : y ≠ 0) :
    HasFDerivAt (fun z : F => ‖z‖) (‖y‖⁻¹ • innerSL ℝ y) y := by
  have h0 : ‖y‖ ^ 2 ≠ 0 := pow_ne_zero 2 (norm_ne_zero_iff.mpr hy)
  have h := (hasStrictFDerivAt_norm_sq y).hasFDerivAt.sqrt h0
  have hf : (fun z : F => √(‖z‖ ^ 2)) = fun z => ‖z‖ :=
    funext fun z => Real.sqrt_sq (norm_nonneg z)
  rw [hf, Real.sqrt_sq (norm_nonneg y)] at h
  convert h using 1
  ext w
  have : ‖y‖ ≠ 0 := norm_ne_zero_iff.mpr hy
  simp
  field_simp

lemma hyd_phi {F : Type*} [NormedAddCommGroup F] [InnerProductSpace ℝ F] {y : F} (hy : y ≠ 0) :
    HasFDerivAt (fun z : F => Real.exp (-‖z‖ / 2))
      ((-(1 / 2) * Real.exp (-‖y‖ / 2) * ‖y‖⁻¹) • innerSL ℝ y) y := by
  have h := ((((hasDerivAt_id ‖y‖).neg).div_const 2).exp).comp_hasFDerivAt y (hyd_norm hy)
  refine h.congr_fderiv ?_
  ext w
  simp only [_root_.smul_apply, smul_eq_mul, Pi.neg_apply, id]
  ring

lemma hyd_c {F : Type*} [NormedAddCommGroup F] [InnerProductSpace ℝ F] {y : F} (hy : y ≠ 0) :
    HasFDerivAt (fun z : F => -(1 / 2) * Real.exp (-‖z‖ / 2) * ‖z‖⁻¹)
      ((Real.exp (-‖y‖ / 2) * (1 / 4 * ‖y‖⁻¹ ^ 2 + 1 / 2 * ‖y‖⁻¹ ^ 3)) • innerSL ℝ y) y := by
  have hn : ‖y‖ ≠ 0 := norm_ne_zero_iff.mpr hy
  have h := ((hyd_phi hy).const_mul (-(1 / 2) : ℝ)).mul
    ((hasDerivAt_inv hn).comp_hasFDerivAt y (hyd_norm hy))
  refine h.congr_fderiv ?_
  ext w
  simp only [_root_.smul_apply, _root_.add_apply, smul_eq_mul,
    Function.comp]
  field_simp
  ring

theorem hydrogen_ground_state_aux (x : EuclideanSpace ℝ (Fin 3)) (hx : x ≠ 0) :
    -(Δ (fun y : EuclideanSpace ℝ (Fin 3) => Real.exp (-‖y‖ / 2))) x
      - Real.exp (-‖x‖ / 2) / ‖x‖ = -(1 / 4) * Real.exp (-‖x‖ / 2) := by
  have hG : (fderiv ℝ (fun y : EuclideanSpace ℝ (Fin 3) => Real.exp (-‖y‖ / 2))) =ᶠ[𝓝 x]
      fun y => (-(1 / 2) * Real.exp (-‖y‖ / 2) * ‖y‖⁻¹) • innerSL ℝ y := by
    filter_upwards [isOpen_ne.mem_nhds hx] with y hy
    exact (hyd_phi hy).fderiv
  have hGd0 := (hyd_c hx).smul (innerSL ℝ (E := EuclideanSpace ℝ (Fin 3))).hasFDerivAt
  have hGd : HasFDerivAt (fun y : EuclideanSpace ℝ (Fin 3) =>
      (-(1 / 2) * Real.exp (-‖y‖ / 2) * ‖y‖⁻¹) • innerSL ℝ y) _ x := hGd0
  rw [laplacian_eq_iteratedFDeriv_orthonormalBasis _ (EuclideanSpace.basisFun (Fin 3) ℝ)]
  simp only [iteratedFDeriv_two_apply, hG.fderiv_eq, hGd.fderiv]
  simp [Fin.sum_univ_three, innerSL_apply_apply, EuclideanSpace.inner_single_right]
  repeat erw [innerSL_apply_apply]
  simp [EuclideanSpace.inner_single_right]
  have hr : x.ofLp 0 * x.ofLp 0 + x.ofLp 1 * x.ofLp 1 + x.ofLp 2 * x.ofLp 2 = ‖x‖ ^ 2 := by
    rw [EuclideanSpace.norm_sq_eq]
    simp [Fin.sum_univ_three, Real.norm_eq_abs, sq]
  have hn : ‖x‖ ≠ 0 := norm_ne_zero_iff.mpr hx
  linear_combination (norm := skip)
    (-(Real.exp (-‖x‖ / 2) * (4⁻¹ * (‖x‖ ^ 2)⁻¹ + 2⁻¹ * (‖x‖ ^ 3)⁻¹))) * hr
  field_simp
  ring

end ProofHelpers

#print axioms kr_sa_mem
#print axioms kr_symm
#print axioms kr_norm_sq
#print axioms kr_lb
#print axioms kr_surj
#print axioms kr_surjT
#print axioms kato_rellich_aux
#print axioms two_level_eig_iff
#print axioms two_level_second_order_aux
#print axioms hyd_norm
#print axioms hyd_phi
#print axioms hyd_c
#print axioms hydrogen_ground_state_aux

/-- Kato-Rellich. Let `A` be a self-adjoint operator on a complex Hilbert space `E`, with domain
`D(A)`. Let `V` be symmetric (`⟨Vu, w⟩ = ⟨u, Vw⟩` on its domain), defined on all of `D(A)`, and
`A`-bounded with relative bound `a < 1`: `‖Vu‖ ≤ a‖Au‖ + b‖u‖` for every `u` in `D(A)`.
Then `A + V` is self-adjoint, and its domain is exactly `D(A)`. -/
theorem kato_rellich {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℂ E] [CompleteSpace E]
    (A V : E →ₗ.[ℂ] E) (hA : IsSelfAdjoint A) (hV : V.IsFormalAdjoint V)
    (hdom : A.domain ≤ V.domain) {a b : ℝ} (ha : a < 1)
    (hbound : ∀ u : A.domain, ‖V ⟨(u : E), hdom u.2⟩‖ ≤ a * ‖A u‖ + b * ‖(u : E)‖) :
    IsSelfAdjoint (A + V) ∧ (A + V).domain = A.domain := by
  exact kato_rellich_aux A V hA hV hdom ha hbound

/-- The 2 × 2 rehearsal: `(3 − √(1 + 4e²))/2` is an eigenvalue of `[[1, e], [e, 2]]`, it is the
lowest one, and it lies between `1 − e²` and `1 − e² + e⁴`, so the second-order guess `1 − e²` is off
by at most `e⁴`. -/
theorem two_level_second_order (e : ℝ) :
    Module.End.HasEigenvalue (Matrix.toLin' !![1, e; e, 2]) ((3 - Real.sqrt (1 + 4 * e ^ 2)) / 2)
    ∧ (∀ μ : ℝ, Module.End.HasEigenvalue (Matrix.toLin' !![1, e; e, 2]) μ →
        (3 - Real.sqrt (1 + 4 * e ^ 2)) / 2 ≤ μ)
    ∧ 0 ≤ (3 - Real.sqrt (1 + 4 * e ^ 2)) / 2 - (1 - e ^ 2)
    ∧ (3 - Real.sqrt (1 + 4 * e ^ 2)) / 2 - (1 - e ^ 2) ≤ e ^ 4 := by
  exact two_level_second_order_aux e

/-- Hydrogen's ground state: on `ℝ³` away from the proton, `ψ = e^(−r/2)` with `r = ‖x‖` solves
`−Δψ − ψ/r = −ψ/4`, so its energy is `−1/4`. -/
theorem hydrogen_ground_state (x : EuclideanSpace ℝ (Fin 3)) (hx : x ≠ 0) :
    -(Δ (fun y : EuclideanSpace ℝ (Fin 3) => Real.exp (-‖y‖ / 2))) x
      - Real.exp (-‖x‖ / 2) / ‖x‖ = -(1 / 4) * Real.exp (-‖x‖ / 2) := by
  exact hydrogen_ground_state_aux x hx

-- Step 2's numbers: a = 1/2, b = 3, μ = 12 give a + b/μ = 3/4.
example : (1 / 2 : ℚ) + 3 / 12 = 3 / 4 := by norm_num
-- The matrix at e = 1/10: characteristic equation λ² − 3λ + 199/100, second-order guess 99/100.
example : (1 : ℚ) * 2 - (1 / 10) ^ 2 = 199 / 100 := by norm_num
example : (1 : ℚ) - (1 / 10) ^ 2 = 99 / 100 := by norm_num
-- Hydrogen's energy from the shells: (2π − 4π)/(8π) = (2 − 4)/8 = −1/4.
example : ((2 : ℚ) - 4) / 8 = -1 / 4 := by norm_num
-- Charge Z = 1 + ε: first order −1/4 − ε/2 against exact −(1 + ε)²/4, at ε = 1/10 and ε = 1.
example : -(1 / 4 : ℚ) - (1 / 10) * (4 / 8) = -3 / 10 := by norm_num
example : -((11 / 10 : ℚ) ^ 2) / 4 = -121 / 400 := by norm_num
example : -(1 / 4 : ℚ) - 1 * (4 / 8) = -3 / 4 := by norm_num
example : -((2 : ℚ) ^ 2) / 4 = -1 := by norm_num

#print axioms kato_rellich
#print axioms two_level_second_order
#print axioms hydrogen_ground_state
