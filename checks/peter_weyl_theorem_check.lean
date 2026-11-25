-- Peter-Weyl: on a compact group with its Haar average, averaging makes every representation keep lengths, matrix entries of irreducible pieces are orthogonal with energy one over the size, and the entries scaled by the square root of the size form an orthonormal basis of the finite-energy functions.
import Mathlib.MeasureTheory.Measure.Haar.Basic
import Mathlib.MeasureTheory.Function.L2Space
import Mathlib.Analysis.InnerProductSpace.l2Space
import Mathlib.LinearAlgebra.UnitaryGroup
import Mathlib.LinearAlgebra.Matrix.PosDef
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Tactic.NormNum
import Mathlib.MeasureTheory.Measure.Haar.Unique
import Mathlib.Analysis.Matrix.Order
import Mathlib.Analysis.SpecialFunctions.ContinuousFunctionalCalculus.Rpow.Basic
import Mathlib.LinearAlgebra.Eigenspace.Triangularizable
import Mathlib.Analysis.Complex.Polynomial.Basic
import Mathlib.MeasureTheory.Function.ContinuousMapDense
import Mathlib.Topology.UniformSpace.Ascoli
import Mathlib.Analysis.InnerProductSpace.Spectrum
import Mathlib.Analysis.Normed.Operator.Compact.Basic
import Mathlib.MeasureTheory.Integral.Prod

open MeasureTheory Matrix
open scoped ComplexOrder

universe u

namespace PeterWeyl

variable {G : Type u} [Group G] [TopologicalSpace G] [IsTopologicalGroup G] [CompactSpace G]
  [MeasurableSpace G] [BorelSpace G]

/-- A continuous unitary representation of size `n`: each member `g` gets an `n`-by-`n` matrix
`π g`, with `π (g * h) = π g * π h` (built into `G →* _`), continuous in `g`, and every `π g`
keeps lengths: `(π g)ᴴ * π g = 1`. -/
def IsContUnitaryRep {n : ℕ} (π : G →* Matrix (Fin n) (Fin n) ℂ) : Prop :=
  Continuous (fun g => π g) ∧ ∀ g, π g ∈ Matrix.unitaryGroup (Fin n) ℂ

/-- Irreducible: the space `ℂⁿ` is not zero, and no subspace other than zero and the whole space
is sent into itself by every `π g`. -/
def IsIrred {n : ℕ} (π : G →* Matrix (Fin n) (Fin n) ℂ) : Prop :=
  0 < n ∧ ∀ W : Submodule ℂ (Fin n → ℂ), (∀ g, ∀ v ∈ W, π g *ᵥ v ∈ W) → W = ⊥ ∨ W = ⊤

/-- Two representations count as one when a change of basis `T` turns one into the other:
`T (π g v) = σ g (T v)` for every member `g` and vector `v`. -/
def Equivalent {n m : ℕ} (π : G →* Matrix (Fin n) (Fin n) ℂ)
    (σ : G →* Matrix (Fin m) (Fin m) ℂ) : Prop :=
  ∃ T : (Fin n → ℂ) ≃ₗ[ℂ] (Fin m → ℂ), ∀ g v, T (π g *ᵥ v) = σ g *ᵥ T v

/-! ### Helper lemmas for the proofs below -/

lemma haar_rightInvariant (μ : Measure G) [μ.IsHaarMeasure] [IsProbabilityMeasure μ] :
    μ.IsMulRightInvariant := by
  constructor
  intro g
  have h := Measure.isMulInvariant_eq_smul_of_compactSpace (μ.map (· * g)) μ
  have hu := congrArg (fun ν : Measure G => ν Set.univ) h
  simp only [Measure.smul_apply, measure_univ] at hu
  simp at hu
  have hc : Measure.haarScalarFactor (μ.map (· * g)) μ = 1 := by
    exact_mod_cast hu.symm
  rw [h, hc, one_smul]

lemma integrable_of_cont {μ : Measure G} [IsFiniteMeasure μ] {f : G → ℂ} (hf : Continuous f) :
    Integrable f μ :=
  hf.integrable_of_hasCompactSupport (HasCompactSupport.of_compactSpace f)

section MatInt
variable {a b c d : Type*} [Fintype a] [Fintype b] [Fintype c] [Fintype d]

lemma mul_of_integral_mul (μ : Measure G) (F : G → Matrix a b ℂ)
    (hF : ∀ i j, Integrable (fun g => F g i j) μ) (A : Matrix c a ℂ) (B : Matrix b d ℂ) :
    A * Matrix.of (fun i j => ∫ g, F g i j ∂μ) * B = Matrix.of fun i j => ∫ g, (A * F g * B) i j ∂μ := by
  ext i j
  simp only [Matrix.mul_apply, Matrix.of_apply]
  rw [integral_finsetSum]
  · refine Finset.sum_congr rfl fun l _ => ?_
    simp_rw [Finset.sum_mul]
    rw [integral_finsetSum]
    · refine Finset.sum_congr rfl fun k _ => ?_
      rw [← integral_const_mul, ← integral_mul_const]
    · intro k _
      exact ((hF k l).const_mul _).mul_const _
  · intro l _
    simp_rw [Finset.sum_mul]
    exact integrable_finsetSum _ fun k _ => ((hF k l).const_mul _).mul_const _


lemma dot_of_integral (μ : Measure G) (F : G → Matrix a b ℂ)
    (hF : ∀ i j, Integrable (fun g => F g i j) μ) (u : a → ℂ) (v : b → ℂ) :
    u ⬝ᵥ (Matrix.of (fun i j => ∫ g, F g i j ∂μ) *ᵥ v) = ∫ g, u ⬝ᵥ (F g *ᵥ v) ∂μ := by
  simp only [dotProduct, mulVec, of_apply]
  rw [integral_finsetSum]
  · refine Finset.sum_congr rfl fun i _ => ?_
    rw [integral_const_mul, integral_finsetSum]
    · congr 1
      refine Finset.sum_congr rfl fun j _ => ?_
      rw [integral_mul_const]
    · intro j _; exact (hF i j).mul_const _
  · intro i _
    exact (integrable_finsetSum _ fun j _ => (hF i j).mul_const _).const_mul _

end MatInt

open scoped MatrixOrder in
lemma exists_sqrt_of_posDef {n : ℕ} {M : Matrix (Fin n) (Fin n) ℂ} (hM : M.PosDef) :
    ∃ P : Matrix (Fin n) (Fin n) ℂ, IsUnit P ∧ Pᴴ = P ∧ P * P = M := by
  have h0 : 0 ≤ M := nonneg_iff_posSemidef.mpr hM.posSemidef
  refine ⟨CFC.sqrt M, ?_, ?_, CFC.sqrt_mul_sqrt_self M h0⟩
  · rw [CFC.isUnit_sqrt_iff M h0]; exact hM.isUnit
  · exact (CFC.sqrt_nonneg M).isSelfAdjoint

lemma rep_inv_mul {n : ℕ} (π : G →* Matrix (Fin n) (Fin n) ℂ) (g : G) : π g⁻¹ * π g = 1 := by
  rw [← map_mul, inv_mul_cancel, map_one]

lemma rep_mul_inv {n : ℕ} (π : G →* Matrix (Fin n) (Fin n) ℂ) (g : G) : π g * π g⁻¹ = 1 := by
  rw [← map_mul, mul_inv_cancel, map_one]

lemma haar_unitary_aux (μ : Measure G) [μ.IsHaarMeasure] [IsProbabilityMeasure μ]
    {n : ℕ} (π : G →* Matrix (Fin n) (Fin n) ℂ) (hπ : Continuous fun g => π g) :
    let M : Matrix (Fin n) (Fin n) ℂ := Matrix.of fun i j => ∫ g, ((π g)ᴴ * π g) i j ∂μ
    M.PosDef ∧ (∀ h, (π h)ᴴ * M * π h = M) ∧
      ∃ P : Matrix (Fin n) (Fin n) ℂ, IsUnit P ∧
        ∀ g, P * π g * P⁻¹ ∈ Matrix.unitaryGroup (Fin n) ℂ := by
  intro M
  have hcont : ∀ i j, Continuous fun g => ((π g)ᴴ * π g) i j := fun i j =>
    ((hπ.matrix_conjTranspose).matrix_mul hπ).matrix_elem i j
  have hint : ∀ i j, Integrable (fun g => ((π g)ᴴ * π g) i j) μ := fun i j =>
    integrable_of_cont (hcont i j)
  have hinv : ∀ h, (π h)ᴴ * M * π h = M := by
    intro h
    have := mul_of_integral_mul μ (fun g => (π g)ᴴ * π g) hint (π h)ᴴ (π h)
    rw [this]
    ext i j
    simp only [M, of_apply]
    have hr := haar_rightInvariant μ
    rw [← integral_mul_right_eq_self (μ := μ) (fun g => ((π g)ᴴ * π g) i j) h]
    congr 1; ext g
    simp [map_mul, conjTranspose_mul, Matrix.mul_assoc]
  have hherm : M.IsHermitian := by
    ext i j
    simp only [M, conjTranspose_apply, of_apply]
    rw [show star (∫ g, ((π g)ᴴ * π g) j i ∂μ) = (starRingEnd ℂ) (∫ g, ((π g)ᴴ * π g) j i ∂μ)
      from rfl, ← integral_conj]
    congr 1; ext g
    rw [show (starRingEnd ℂ) (((π g)ᴴ * π g) j i) = ((π g)ᴴ * π g)ᴴ i j from rfl,
      conjTranspose_mul, conjTranspose_conjTranspose]
  have hpos : ∀ ⦃x : Fin n → ℂ⦄, x ≠ 0 → 0 < star x ⬝ᵥ (M *ᵥ x) := by
    intro x hx
    rw [dot_of_integral μ _ hint]
    have e : ∀ g, star x ⬝ᵥ (((π g)ᴴ * π g) *ᵥ x) =
        ((∑ k, Complex.normSq ((π g *ᵥ x) k) : ℝ) : ℂ) := by
      intro g
      rw [← mulVec_mulVec, dotProduct_mulVec, ← star_mulVec]
      simp only [dotProduct, Pi.star_apply, Complex.ofReal_sum]
      refine Finset.sum_congr rfl fun k _ => ?_
      rw [mul_comm]; exact Complex.mul_conj _
    simp_rw [e]
    rw [integral_complex_ofReal]
    have hc : Continuous fun g => ∑ k, Complex.normSq ((π g *ᵥ x) k) := by
      refine continuous_finsetSum _ fun k _ => Complex.continuous_normSq.comp ?_
      exact (continuous_apply k).comp (hπ.matrix_mulVec continuous_const)
    obtain ⟨k, hk⟩ : ∃ k, x k ≠ 0 := Function.ne_iff.mp hx
    have h1 : (fun g => ∑ k, Complex.normSq ((π g *ᵥ x) k)) 1 ≠ 0 := by
      simp only [map_one, one_mulVec]
      refine ne_of_gt (lt_of_lt_of_le (Complex.normSq_pos.mpr hk) ?_)
      exact Finset.single_le_sum (f := fun k => Complex.normSq (x k))
        (fun k _ => Complex.normSq_nonneg _) (Finset.mem_univ k)
    have := integral_pos_of_integrable_nonneg_ne_zero (μ := μ) hc
      (hc.integrable_of_hasCompactSupport (HasCompactSupport.of_compactSpace _))
      (fun g => Finset.sum_nonneg fun k _ => Complex.normSq_nonneg _) h1
    exact_mod_cast this
  have hM : M.PosDef := PosDef.of_dotProduct_mulVec_pos hherm hpos
  refine ⟨hM, hinv, ?_⟩
  obtain ⟨P, hPu, hPh, hPP⟩ := exists_sqrt_of_posDef hM
  refine ⟨P, hPu, fun g => ?_⟩
  rw [mem_unitaryGroup_iff']
  have hPi : P⁻¹ * P = 1 := Matrix.nonsing_inv_mul P ((Matrix.isUnit_iff_isUnit_det P).mp hPu)
  have hPi' : P * P⁻¹ = 1 := Matrix.mul_nonsing_inv P ((Matrix.isUnit_iff_isUnit_det P).mp hPu)
  have hs : star (P * π g * P⁻¹) = P⁻¹ * (π g)ᴴ * P := by
    rw [star_eq_conjTranspose, conjTranspose_mul, conjTranspose_mul, conjTranspose_nonsing_inv,
      hPh, Matrix.mul_assoc]
  rw [hs]
  calc P⁻¹ * (π g)ᴴ * P * (P * π g * P⁻¹) = P⁻¹ * ((π g)ᴴ * (P * P) * π g) * P⁻¹ := by
        simp only [Matrix.mul_assoc]
    _ = 1 := by rw [hPP, hinv, ← hPP, ← Matrix.mul_assoc, hPi, Matrix.one_mul, hPi']


lemma rep_inv_eq_star {n : ℕ} {π : G →* Matrix (Fin n) (Fin n) ℂ}
    (hπ : ∀ g, π g ∈ Matrix.unitaryGroup (Fin n) ℂ) (g : G) : π g⁻¹ = star (π g) := by
  have h1 : star (π g) * π g = 1 := mem_unitaryGroup_iff'.mp (hπ g)
  calc π g⁻¹ = (star (π g) * π g) * π g⁻¹ := by rw [h1, Matrix.one_mul]
    _ = star (π g) := by rw [Matrix.mul_assoc, rep_mul_inv, Matrix.mul_one]

lemma equivalent_symm {n m : ℕ} {π : G →* Matrix (Fin n) (Fin n) ℂ}
    {σ : G →* Matrix (Fin m) (Fin m) ℂ} : Equivalent π σ → Equivalent σ π := by
  rintro ⟨T, hT⟩
  refine ⟨T.symm, fun g v => ?_⟩
  apply T.injective
  rw [hT, LinearEquiv.apply_symm_apply, LinearEquiv.apply_symm_apply]

lemma schur_zero {n m : ℕ} (π : G →* Matrix (Fin n) (Fin n) ℂ) (σ : G →* Matrix (Fin m) (Fin m) ℂ)
    (hπi : IsIrred π) (hσi : IsIrred σ) (T : Matrix (Fin n) (Fin m) ℂ)
    (hT : ∀ h, π h * T = T * σ h) (hne : ¬ Equivalent σ π) : T = 0 := by
  let L := Matrix.toLin' T
  have hk := hσi.2 (LinearMap.ker L) (fun g v hv => by
    simp only [L, LinearMap.mem_ker, Matrix.toLin'_apply] at hv ⊢
    rw [mulVec_mulVec, ← hT, ← mulVec_mulVec, hv, mulVec_zero])
  have hr := hπi.2 (LinearMap.range L) (fun g v hv => by
    obtain ⟨w, rfl⟩ := hv
    exact ⟨σ g *ᵥ w, by simp only [L, Matrix.toLin'_apply, mulVec_mulVec, hT]⟩)
  have hL : L = 0 → T = 0 := fun h => (Matrix.toLin').map_eq_zero_iff.mp h
  rcases hk with hk | hk
  · rcases hr with hr | hr
    · exact hL (LinearMap.range_eq_bot.mp hr)
    · exfalso; apply hne
      have hb : Function.Bijective L := ⟨LinearMap.ker_eq_bot.mp hk, LinearMap.range_eq_top.mp hr⟩
      refine ⟨LinearEquiv.ofBijective L hb, fun g v => ?_⟩
      change T *ᵥ (σ g *ᵥ v) = π g *ᵥ (T *ᵥ v)
      rw [mulVec_mulVec, mulVec_mulVec, hT]
  · exact hL (LinearMap.ker_eq_top.mp hk)

lemma schur_scalar {n : ℕ} (π : G →* Matrix (Fin n) (Fin n) ℂ)
    (hπi : IsIrred π) (T : Matrix (Fin n) (Fin n) ℂ)
    (hT : ∀ h, π h * T = T * π h) : ∃ c : ℂ, T = c • 1 := by
  have : Nontrivial (Fin n → ℂ) := by
    have : Nonempty (Fin n) := ⟨⟨0, hπi.1⟩⟩
    infer_instance
  obtain ⟨c, hc⟩ := Module.End.exists_eigenvalue (Matrix.toLin' T)
  obtain ⟨v, hv⟩ := hc.exists_hasEigenvector
  refine ⟨c, ?_⟩
  let S := T - c • (1 : Matrix (Fin n) (Fin n) ℂ)
  have hS : ∀ h, π h * S = S * π h := by
    intro h; simp only [S, Matrix.mul_sub, Matrix.sub_mul, hT, Matrix.mul_smul, Matrix.smul_mul,
      Matrix.mul_one, Matrix.one_mul]
  have hk := hπi.2 (LinearMap.ker (Matrix.toLin' S)) (fun g w hw => by
    simp only [LinearMap.mem_ker, Matrix.toLin'_apply] at hw ⊢
    rw [mulVec_mulVec, ← hS, ← mulVec_mulVec, hw, mulVec_zero])
  have hvS : v ∈ LinearMap.ker (Matrix.toLin' S) := by
    have := hv.apply_eq_smul
    simp only [Matrix.toLin'_apply] at this
    simp only [LinearMap.mem_ker, Matrix.toLin'_apply, S, sub_mulVec, this, smul_mulVec,
      one_mulVec, sub_self]
  rcases hk with hk | hk
  · rw [hk] at hvS
    exact absurd ((Submodule.mem_bot ℂ).mp hvS) hv.2
  · have : S = 0 := (Matrix.toLin').map_eq_zero_iff.mp (LinearMap.ker_eq_top.mp hk)
    exact sub_eq_zero.mp this

/-- The averaged matrix `∫ π g X σ(g⁻¹) dg`. -/
lemma avg_intertwine (μ : Measure G) [μ.IsHaarMeasure] [IsProbabilityMeasure μ]
    {n m : ℕ} (π : G →* Matrix (Fin n) (Fin n) ℂ) (σ : G →* Matrix (Fin m) (Fin m) ℂ)
    (hπ : Continuous fun g => π g) (hσ : Continuous fun g => σ g) (X : Matrix (Fin n) (Fin m) ℂ)
    (h : G) :
    π h * Matrix.of (fun i k => ∫ g, (π g * X * σ g⁻¹) i k ∂μ) =
      Matrix.of (fun i k => ∫ g, (π g * X * σ g⁻¹) i k ∂μ) * σ h := by
  have hint : ∀ i k, Integrable (fun g => (π g * X * σ g⁻¹) i k) μ := fun i k =>
    integrable_of_cont (((hπ.matrix_mul continuous_const).matrix_mul
      (hσ.comp continuous_inv)).matrix_elem i k)
  have e := mul_of_integral_mul μ _ hint (π h) (σ h⁻¹)
  have e2 : (Matrix.of fun i j => ∫ g, (π h * (π g * X * σ g⁻¹) * σ h⁻¹) i j ∂μ) =
      Matrix.of (fun i k => ∫ g, (π g * X * σ g⁻¹) i k ∂μ) := by
    ext i k
    simp only [of_apply]
    rw [← integral_mul_left_eq_self (μ := μ) (fun g => (π g * X * σ g⁻¹) i k) h]
    congr 1; ext g
    simp only [_root_.mul_inv_rev, map_mul, Matrix.mul_assoc]
  rw [e2] at e
  calc _ = (π h * Matrix.of (fun i k => ∫ g, (π g * X * σ g⁻¹) i k ∂μ) * σ h⁻¹) * σ h := by
        rw [Matrix.mul_assoc _ (σ h⁻¹), rep_inv_mul, Matrix.mul_one]
    _ = _ := by rw [e]

lemma avg_trace (μ : Measure G) [μ.IsHaarMeasure] [IsProbabilityMeasure μ]
    {n : ℕ} (π : G →* Matrix (Fin n) (Fin n) ℂ)
    (hπ : Continuous fun g => π g) (X : Matrix (Fin n) (Fin n) ℂ) :
    (Matrix.of (fun i k => ∫ g, (π g * X * π g⁻¹) i k ∂μ)).trace = X.trace := by
  have hint : ∀ i k, Integrable (fun g => (π g * X * π g⁻¹) i k) μ := fun i k =>
    integrable_of_cont (((hπ.matrix_mul continuous_const).matrix_mul
      (hπ.comp continuous_inv)).matrix_elem i k)
  simp only [Matrix.trace, Matrix.diag, of_apply]
  rw [← integral_finsetSum _ (fun i _ => hint i i)]
  have : ∀ g, ∑ i, (π g * X * π g⁻¹) i i = ∑ i, X i i := by
    intro g
    change (π g * X * π g⁻¹).trace = X.trace
    rw [Matrix.trace_mul_comm, ← Matrix.mul_assoc, rep_inv_mul, Matrix.one_mul]
  simp_rw [this]
  simp

lemma schur_aux (μ : Measure G) [μ.IsHaarMeasure] [IsProbabilityMeasure μ]
    {n m : ℕ} (π : G →* Matrix (Fin n) (Fin n) ℂ) (σ : G →* Matrix (Fin m) (Fin m) ℂ)
    (hπ : IsContUnitaryRep π) (hπi : IsIrred π) (hσ : IsContUnitaryRep σ) (hσi : IsIrred σ) :
    (¬ Equivalent π σ → ∀ i j k l, ∫ g, π g i j * star (σ g k l) ∂μ = 0) ∧
      ∀ i j k l, ∫ g, π g i j * star (π g k l) ∂μ = if i = k ∧ j = l then 1 / (n : ℂ) else 0 := by
  have entry : ∀ {m' : ℕ} (σ' : G →* Matrix (Fin m') (Fin m') ℂ), IsContUnitaryRep σ' →
      ∀ i j k l, ∫ g, π g i j * star (σ' g k l) ∂μ =
        (Matrix.of (fun i k => ∫ g, (π g * Matrix.single j l (1 : ℂ) * σ' g⁻¹) i k ∂μ)) i k := by
    intro m' σ' hσ' i j k l
    simp only [of_apply]
    congr 1; ext g
    rw [rep_inv_eq_star hσ'.2]
    simp [Matrix.mul_apply, Matrix.single_apply, Matrix.star_apply, ite_and, Finset.sum_ite_eq]
  refine ⟨fun hne i j k l => ?_, fun i j k l => ?_⟩
  · rw [entry σ hσ]
    rw [schur_zero π σ hπi hσi _ (avg_intertwine μ π σ hπ.1 hσ.1 _)
      (fun h => hne (equivalent_symm h))]
    rfl
  · rw [entry π hπ]
    obtain ⟨c, hc⟩ := schur_scalar π hπi _ (avg_intertwine μ π π hπ.1 hπ.1 (Matrix.single j l (1 : ℂ)))
    have ht := avg_trace μ π hπ.1 (Matrix.single j l (1 : ℂ))
    rw [hc] at ht ⊢
    have htr : (Matrix.single j l (1 : ℂ)).trace = if j = l then 1 else 0 := by
      split_ifs with hjl
      · subst hjl; exact Matrix.trace_single_eq_same _ _
      · exact Matrix.trace_single_eq_of_ne _ _ _ hjl
    simp only [Matrix.trace_smul, Matrix.trace_one, Fintype.card_fin, htr,
      smul_eq_mul] at ht
    have hn : (n : ℂ) ≠ 0 := by exact_mod_cast hπi.1.ne'
    have hc' : c = (if j = l then 1 else 0) / n := by
      rw [eq_div_iff hn]; rw [← ht]
    simp only [Matrix.smul_apply, Matrix.one_apply, hc', smul_eq_mul]
    split_ifs <;> simp_all


section Hilb
open Filter
open scoped InnerProductSpace
variable (μ : Measure G) [μ.IsHaarMeasure] [IsProbabilityMeasure μ]

/-- Continuous functions as elements of `L²`. -/
noncomputable abbrev toH : C(G, ℂ) →L[ℂ] Lp ℂ 2 μ := ContinuousMap.toLp 2 μ ℂ

lemma toH_ae (φ : C(G, ℂ)) : ⇑(toH μ φ) =ᵐ[μ] φ := ContinuousMap.coeFn_toLp μ φ

lemma toH_inner (φ χ : C(G, ℂ)) :
    ⟪toH μ φ, toH μ χ⟫_ℂ = ∫ x, χ x * (starRingEnd ℂ) (φ x) ∂μ :=
  ContinuousMap.inner_toLp μ φ χ

lemma toH_inj {φ χ : C(G, ℂ)} (h : toH μ φ = toH μ χ) : φ = χ := by
  have h1 : (φ : G → ℂ) =ᵐ[μ] χ := (toH_ae μ φ).symm.trans (h ▸ toH_ae μ χ)
  have := (Continuous.ae_eq_iff_eq μ φ.continuous χ.continuous).mp h1
  ext x; exact congrFun this x

lemma toH_dense : DenseRange (toH μ) := ContinuousMap.toLp_denseRange ℂ μ ℂ (by norm_num)

lemma mp_right (h : G) : MeasurePreserving (· * h) μ μ := by
  have := haar_rightInvariant μ
  exact measurePreserving_mul_right μ h

/-- Right translation `f ↦ f(· h)` on `L²`. -/
noncomputable def R (h : G) : Lp ℂ 2 μ →ₗᵢ[ℂ] Lp ℂ 2 μ :=
  Lp.compMeasurePreservingₗᵢ ℂ (· * h) (mp_right μ h)

lemma R_ae (h : G) (f : Lp ℂ 2 μ) : ⇑(R μ h f) =ᵐ[μ] (⇑f) ∘ (· * h) :=
  Lp.coeFn_compMeasurePreserving f (mp_right μ h)

lemma R_toH (h : G) (φ : C(G, ℂ)) :
    R μ h (toH μ φ) = toH μ (φ.comp (ContinuousMap.mulRight h)) := by
  apply Lp.ext
  refine (R_ae μ h _).trans ?_
  refine ((mp_right μ h).quasiMeasurePreserving.ae_eq_comp (toH_ae μ φ)).trans ?_
  exact (toH_ae μ (φ.comp (ContinuousMap.mulRight h))).symm

lemma R_mul (g h : G) (f : Lp ℂ 2 μ) : R μ (g * h) f = R μ g (R μ h f) := by
  apply Lp.ext
  refine (R_ae μ _ _).trans ?_
  refine EventuallyEq.trans ?_ (R_ae μ g _).symm
  have := (mp_right μ g).quasiMeasurePreserving.ae_eq_comp (R_ae μ h f)
  refine EventuallyEq.trans ?_ this.symm
  exact Filter.Eventually.of_forall fun x => by simp [mul_assoc]

lemma R_one (f : Lp ℂ 2 μ) : R μ 1 f = f := by
  apply Lp.ext
  refine (R_ae μ _ _).trans ?_
  exact Filter.Eventually.of_forall fun x => by simp

lemma R_inv_R (h : G) (f : Lp ℂ 2 μ) : R μ h (R μ h⁻¹ f) = f := by
  rw [← R_mul, mul_inv_cancel, R_one]

lemma R_R_inv (h : G) (f : Lp ℂ 2 μ) : R μ h⁻¹ (R μ h f) = f := by
  rw [← R_mul, inv_mul_cancel, R_one]

lemma R_inner (h : G) (f g : Lp ℂ 2 μ) : ⟪R μ h f, R μ h g⟫_ℂ = ⟪f, g⟫_ℂ :=
  LinearIsometry.inner_map_map _ _ _

lemma R_adj (h : G) (f g : Lp ℂ 2 μ) : ⟪R μ h f, g⟫_ℂ = ⟪f, R μ h⁻¹ g⟫_ℂ := by
  conv_lhs => rw [← R_inv_R μ h g]
  rw [R_inner]

lemma cont_mulRight (φ : C(G, ℂ)) : Continuous fun h : G => φ.comp (ContinuousMap.mulRight h) := by
  let F : C(G × G, ℂ) := ⟨fun p => φ (p.2 * p.1), by fun_prop⟩
  have : (fun h : G => φ.comp (ContinuousMap.mulRight h)) = ContinuousMap.curry F := by
    ext h x; rfl
  rw [this]; exact (ContinuousMap.curry F).continuous

lemma R_cont (φ : C(G, ℂ)) : Continuous fun h => R μ h (toH μ φ) := by
  simp_rw [R_toH]
  exact (toH μ).continuous.comp (cont_mulRight φ)


/-- The kernel `x ↦ (y ↦ conj ψ(x y⁻¹))`. -/
noncomputable def kerC (ψ : C(G, ℂ)) : C(G, C(G, ℂ)) :=
  ContinuousMap.curry ⟨fun p : G × G => (starRingEnd ℂ) (ψ (p.1 * p.2⁻¹)), by fun_prop⟩

lemma kerC_apply (ψ : C(G, ℂ)) (x y : G) : kerC ψ x y = (starRingEnd ℂ) (ψ (x * y⁻¹)) := rfl

/-- `Φ x` is the function `y ↦ conj ψ(x y⁻¹)` in `L²`. -/
noncomputable def Φ (ψ : C(G, ℂ)) (x : G) : Lp ℂ 2 μ := toH μ (kerC ψ x)

lemma Φ_cont (ψ : C(G, ℂ)) : Continuous (Φ μ ψ) := (toH μ).continuous.comp (kerC ψ).continuous

lemma Φ_bound (ψ : C(G, ℂ)) : ∃ C, ∀ x, ‖Φ μ ψ x‖ ≤ C := by
  obtain ⟨C, hC⟩ := isCompact_univ.exists_bound_of_continuousOn (Φ_cont μ ψ).continuousOn
  exact ⟨C, fun x => hC x (Set.mem_univ x)⟩

/-- `x ↦ ⟪Φ x, f⟫ = ∫ ψ(x y⁻¹) f(y) dy`, a continuous function. -/
noncomputable def Jfun (ψ : C(G, ℂ)) (f : Lp ℂ 2 μ) : C(G, ℂ) :=
  ⟨fun x => ⟪Φ μ ψ x, f⟫_ℂ, (Φ_cont μ ψ).inner continuous_const⟩

noncomputable def Jlin (ψ : C(G, ℂ)) : Lp ℂ 2 μ →ₗ[ℂ] C(G, ℂ) where
  toFun := Jfun μ ψ
  map_add' f g := by ext x; simp [Jfun, inner_add_right]
  map_smul' c f := by ext x; simp [Jfun, inner_smul_right]

noncomputable def J (ψ : C(G, ℂ)) : Lp ℂ 2 μ →L[ℂ] C(G, ℂ) :=
  (Jlin μ ψ).mkContinuousOfExistsBound (by
    obtain ⟨C, hC⟩ := Φ_bound μ ψ
    refine ⟨max C 0, fun f => ?_⟩
    rw [ContinuousMap.norm_le _ (by positivity)]
    intro x
    calc ‖⟪Φ μ ψ x, f⟫_ℂ‖ ≤ ‖Φ μ ψ x‖ * ‖f‖ := norm_inner_le_norm _ _
      _ ≤ max C 0 * ‖f‖ := by gcongr; exact (hC x).trans (le_max_left _ _))

lemma J_apply (ψ : C(G, ℂ)) (f : Lp ℂ 2 μ) (x : G) : J μ ψ f x = ⟪Φ μ ψ x, f⟫_ℂ := rfl

/-- The convolution operator `f ↦ ∫ ψ(x y⁻¹) f(y) dy` on `L²`. -/
noncomputable def K (ψ : C(G, ℂ)) : Lp ℂ 2 μ →L[ℂ] Lp ℂ 2 μ := (toH μ).comp (J μ ψ)

lemma K_apply (ψ : C(G, ℂ)) (f : Lp ℂ 2 μ) : K μ ψ f = toH μ (J μ ψ f) := rfl

lemma J_compact (ψ : C(G, ℂ)) : IsCompactOperator (J μ ψ) := by
  obtain ⟨C, hC⟩ := Φ_bound μ ψ
  let T : Set (G → ℂ) := {f | ∀ x, ‖f x‖ ≤ C ∧ ∀ y, ‖f x - f y‖ ≤ ‖Φ μ ψ x - Φ μ ψ y‖}
  let S : Set C(G, ℂ) := {φ | (φ : G → ℂ) ∈ T}
  have hTc : ∀ f ∈ T, Continuous f := by
    intro f hf
    rw [continuous_iff_continuousAt]; intro x₀
    rw [ContinuousAt, tendsto_iff_norm_sub_tendsto_zero]
    have h := (Φ_cont μ ψ).tendsto x₀
    rw [tendsto_iff_norm_sub_tendsto_zero] at h
    exact squeeze_zero (fun _ => norm_nonneg _) (fun x => (hf x).2 x₀) h
  have himg : ContinuousMap.toFun '' S = T := by
    ext f; constructor
    · rintro ⟨φ, hφ, rfl⟩; exact hφ
    · intro hf; exact ⟨⟨f, hTc f hf⟩, hf, rfl⟩
  have hTcl : IsClosed T := by
    have : T = (⋂ x, {f : G → ℂ | ‖f x‖ ≤ C}) ∩
        ⋂ x, ⋂ y, {f : G → ℂ | ‖f x - f y‖ ≤ ‖Φ μ ψ x - Φ μ ψ y‖} := by
      ext f; simp [T, forall_and]
    rw [this]
    exact (isClosed_iInter fun x => isClosed_le (by fun_prop) continuous_const).inter
      (isClosed_iInter fun x => isClosed_iInter fun y => isClosed_le (by fun_prop) continuous_const)
  have hTsub : T ⊆ Set.pi Set.univ (fun _ => Metric.closedBall (0 : ℂ) C) := by
    intro f hf x _; simpa using (hf x).1
  have hTk : IsCompact T :=
    (isCompact_univ_pi fun _ => isCompact_closedBall 0 C).of_isClosed_subset hTcl hTsub
  have hS : IsCompact S := by
    apply ArzelaAscoli.isCompact_of_equicontinuous S (himg ▸ hTk)
    intro x₀
    rw [Metric.equicontinuousAt_iff_right]
    intro ε hε
    have h := Metric.tendsto_nhds.mp ((Φ_cont μ ψ).tendsto x₀) ε hε
    filter_upwards [h] with x hx
    rintro ⟨φ, hφ⟩
    rw [dist_eq_norm]
    calc ‖φ x₀ - φ x‖ ≤ ‖Φ μ ψ x₀ - Φ μ ψ x‖ := (hφ x₀).2 x
      _ < ε := by rwa [dist_comm, dist_eq_norm] at hx
  rw [isCompactOperator_iff_exists_mem_nhds_image_subset_compact]
  refine ⟨Metric.ball 0 1, Metric.ball_mem_nhds 0 one_pos, S, hS, ?_⟩
  rintro _ ⟨f, hf, rfl⟩
  have hf1 : ‖f‖ < 1 := by simpa using hf
  intro x
  refine ⟨?_, fun y => ?_⟩
  · calc ‖⟪Φ μ ψ x, f⟫_ℂ‖ ≤ ‖Φ μ ψ x‖ * ‖f‖ := norm_inner_le_norm _ _
      _ ≤ C * 1 := mul_le_mul (hC x) hf1.le (norm_nonneg _) (le_trans (norm_nonneg _) (hC x))
      _ = C := mul_one C
  · change ‖⟪Φ μ ψ x, f⟫_ℂ - ⟪Φ μ ψ y, f⟫_ℂ‖ ≤ _
    rw [← inner_sub_left]
    calc _ ≤ ‖Φ μ ψ x - Φ μ ψ y‖ * ‖f‖ := norm_inner_le_norm _ _
      _ ≤ ‖Φ μ ψ x - Φ μ ψ y‖ * 1 := by gcongr
      _ = _ := mul_one _

lemma K_compact (ψ : C(G, ℂ)) : IsCompactOperator (K μ ψ) :=
  (J_compact μ ψ).clm_comp (toH μ)


/-- `ψ(y⁻¹) = conj ψ(y)`: the kernel is Hermitian. -/
def Adm (ψ : C(G, ℂ)) : Prop := ∀ y, ψ y⁻¹ = (starRingEnd ℂ) (ψ y)

lemma J_toH (ψ φ : C(G, ℂ)) (x : G) : J μ ψ (toH μ φ) x = ∫ y, φ y * ψ (x * y⁻¹) ∂μ := by
  rw [J_apply, Φ, toH_inner]
  simp [kerC_apply]

lemma K_symm (ψ : C(G, ℂ)) (hψ : Adm ψ) :
    (K μ ψ : Lp ℂ 2 μ →ₗ[ℂ] Lp ℂ 2 μ).IsSymmetric := by
  intro f g
  refine DenseRange.induction_on₂ (p := fun f g => ⟪K μ ψ f, g⟫_ℂ = ⟪f, K μ ψ g⟫_ℂ)
    (toH_dense μ) ?_ ?_ f g
  · exact isClosed_eq (((K μ ψ).continuous.comp continuous_fst).inner continuous_snd)
      (continuous_fst.inner ((K μ ψ).continuous.comp continuous_snd))
  · intro φ χ
    rw [K_apply, K_apply, toH_inner, toH_inner]
    simp_rw [J_toH]
    have e1 : ∀ x, χ x * (starRingEnd ℂ) (∫ y, φ y * ψ (x * y⁻¹) ∂μ) =
        ∫ y, χ x * (starRingEnd ℂ) (φ y) * ψ (y * x⁻¹) ∂μ := by
      intro x
      rw [← integral_conj, ← integral_const_mul]
      congr 1; ext y
      rw [map_mul, ← hψ, _root_.mul_inv_rev, inv_inv]; ring
    have e2 : ∀ y, (∫ x, χ x * ψ (y * x⁻¹) ∂μ) * (starRingEnd ℂ) (φ y) =
        ∫ x, χ x * (starRingEnd ℂ) (φ y) * ψ (y * x⁻¹) ∂μ := by
      intro y
      rw [← integral_mul_const]
      congr 1; ext x; ring
    simp_rw [e1, e2]
    exact integral_integral_swap_of_hasCompactSupport
      (f := fun x y => χ x * (starRingEnd ℂ) (φ y) * ψ (y * x⁻¹)) (by fun_prop)
      (HasCompactSupport.of_compactSpace _)

/-- A matrix entry of a continuous representation, as a continuous function. -/
def coefC {n : ℕ} (σ : G →* Matrix (Fin n) (Fin n) ℂ) (hσ : Continuous fun g => σ g)
    (j k : Fin n) : C(G, ℂ) := ⟨fun g => σ g j k, hσ.matrix_elem j k⟩

lemma coefC_apply {n : ℕ} (σ : G →* Matrix (Fin n) (Fin n) ℂ) (hσ : Continuous fun g => σ g)
    (j k : Fin n) (g : G) : coefC σ hσ j k g = σ g j k := rfl

lemma coefC_mulRight {n : ℕ} (σ : G →* Matrix (Fin n) (Fin n) ℂ) (hσ : Continuous fun g => σ g)
    (j k : Fin n) (h : G) :
    (coefC σ hσ j k).comp (ContinuousMap.mulRight h) = ∑ l, σ h l k • coefC σ hσ j l := by
  ext x
  simp [coefC_apply, map_mul, Matrix.mul_apply, mul_comm]

lemma J_coefC (ψ : C(G, ℂ)) {n : ℕ} (σ : G →* Matrix (Fin n) (Fin n) ℂ)
    (hσ : Continuous fun g => σ g) (j k : Fin n) :
    J μ ψ (toH μ (coefC σ hσ j k)) =
      ∑ l, (∫ w, σ w j l * ψ w⁻¹ ∂μ) • coefC σ hσ l k := by
  have := haar_rightInvariant μ
  ext x
  rw [J_toH]
  rw [← integral_mul_right_eq_self (μ := μ) (fun y => coefC σ hσ j k y * ψ (x * y⁻¹)) x]
  have e : ∀ w, coefC σ hσ j k (w * x) * ψ (x * (w * x)⁻¹) =
      ∑ l, σ w j l * ψ w⁻¹ * σ x l k := by
    intro w
    rw [coefC_apply, map_mul, Matrix.mul_apply, Finset.sum_mul]
    have : x * (w * x)⁻¹ = w⁻¹ := by group
    rw [this]
    refine Finset.sum_congr rfl fun l _ => by ring
  simp_rw [e]
  rw [integral_finsetSum]
  · simp only [ContinuousMap.coe_sum, ContinuousMap.coe_smul, Finset.sum_apply, Pi.smul_apply,
      smul_eq_mul, coefC_apply]
    refine Finset.sum_congr rfl fun l _ => ?_
    rw [integral_mul_const]
  · intro l _
    refine Integrable.mul_const ?_ _
    exact integrable_of_cont ((hσ.matrix_elem j l).mul (ψ.continuous.comp continuous_inv))

lemma kerC_mulRight (ψ : C(G, ℂ)) (x h : G) :
    (kerC ψ x).comp (ContinuousMap.mulRight h⁻¹) = kerC ψ (x * h) := by
  ext y
  simp only [ContinuousMap.comp_apply, ContinuousMap.coe_mulRight, kerC_apply]
  congr 2; group

lemma J_R (ψ : C(G, ℂ)) (h : G) (f : Lp ℂ 2 μ) :
    J μ ψ (R μ h f) = (J μ ψ f).comp (ContinuousMap.mulRight h) := by
  ext x
  rw [J_apply]
  have := R_adj μ h⁻¹ (Φ μ ψ x) f
  rw [inv_inv] at this
  rw [← this, Φ, R_toH, kerC_mulRight]
  rfl

lemma K_R (ψ : C(G, ℂ)) (h : G) (f : Lp ℂ 2 μ) : K μ ψ (R μ h f) = R μ h (K μ ψ f) := by
  rw [K_apply, K_apply, J_R, R_toH]

lemma K_eq_zero (ψ : C(G, ℂ)) (hψ : Adm ψ) (f : Lp ℂ 2 μ) (hf : K μ ψ f = 0) :
    ⟪toH μ ψ, f⟫_ℂ = 0 := by
  have h0 : J μ ψ f = 0 := by
    apply toH_inj μ
    rw [← K_apply, hf, map_zero]
  have h1 := congrArg (fun φ : C(G, ℂ) => φ 1) h0
  simp only [J_apply, ContinuousMap.zero_apply] at h1
  have : kerC ψ 1 = ψ := by
    ext y; rw [kerC_apply, one_mul, hψ, Complex.conj_conj]
  rwa [Φ, this] at h1


/-- The span of the matrix entries of `σ` in `L²`. -/
noncomputable def coefSpan {n : ℕ} (σ : G →* Matrix (Fin n) (Fin n) ℂ)
    (hσ : Continuous fun g => σ g) : Submodule ℂ (Lp ℂ 2 μ) :=
  Submodule.span ℂ (Set.range fun p : Fin n × Fin n => toH μ (coefC σ hσ p.1 p.2))

lemma coef_mem_of_equiv {n m : ℕ} (σ : G →* Matrix (Fin n) (Fin n) ℂ)
    (τ : G →* Matrix (Fin m) (Fin m) ℂ) (hσ : Continuous fun g => σ g)
    (hτ : Continuous fun g => τ g) (he : Equivalent σ τ) (a b : Fin n) :
    toH μ (coefC σ hσ a b) ∈ coefSpan μ τ hτ := by
  obtain ⟨T, hT⟩ := he
  let A := LinearMap.toMatrix' (T : (Fin n → ℂ) →ₗ[ℂ] (Fin m → ℂ))
  let B := LinearMap.toMatrix' (T.symm : (Fin m → ℂ) →ₗ[ℂ] (Fin n → ℂ))
  have key : ∀ g, B * τ g * A = σ g := by
    intro g
    apply Matrix.toLin'.injective
    apply LinearMap.ext; intro v
    rw [Matrix.toLin'_apply, Matrix.toLin'_apply, ← mulVec_mulVec, ← mulVec_mulVec]
    simp only [A, B, LinearMap.toMatrix'_mulVec, LinearEquiv.coe_coe]
    rw [← hT, LinearEquiv.symm_apply_apply]
  have hc : coefC σ hσ a b = ∑ c, ∑ d, (B a c * A d b) • coefC τ hτ c d := by
    ext g
    simp only [coefC_apply, ContinuousMap.coe_sum, ContinuousMap.coe_smul, Finset.sum_apply,
      Pi.smul_apply, smul_eq_mul]
    rw [← key g]
    simp only [Matrix.mul_apply, Finset.sum_mul]
    rw [Finset.sum_comm]
    refine Finset.sum_congr rfl fun d _ => Finset.sum_congr rfl fun c _ => by ring
  rw [hc, map_sum]
  refine Submodule.sum_mem _ fun c _ => ?_
  rw [map_sum]
  refine Submodule.sum_mem _ fun d _ => ?_
  rw [map_smul]
  exact Submodule.smul_mem _ _ (Submodule.subset_span ⟨(c, d), rfl⟩)


lemma irred_piece (U : Submodule ℂ (Lp ℂ 2 μ)) [FiniteDimensional ℂ U] (hU : U ≠ ⊥)
    (hR : ∀ h, ∀ u ∈ U, R μ h u ∈ U)
    (hmin : ∀ U' ≤ U, (∀ h, ∀ u ∈ U', R μ h u ∈ U') → U' = ⊥ ∨ U' = U)
    (hc : ∀ u ∈ U, ∃ φ, u = toH μ φ) :
    ∃ (n : ℕ) (σ : G →* Matrix (Fin n) (Fin n) ℂ) (hσ : IsContUnitaryRep σ),
      IsIrred σ ∧ U ≤ coefSpan μ σ hσ.1 := by
  classical
  set n := Module.finrank ℂ U with hn
  let ob : OrthonormalBasis (Fin n) ℂ U := stdOrthonormalBasis ℂ U
  let b : Fin n → Lp ℂ 2 μ := fun j => (ob j : Lp ℂ 2 μ)
  have hb : ∀ j, b j ∈ U := fun j => (ob j).2
  have hbo : ∀ i j, ⟪b i, b j⟫_ℂ = if i = j then 1 else 0 := by
    intro i j
    have := (orthonormal_iff_ite.mp ob.orthonormal) i j
    simpa [b, Submodule.coe_inner] using this
  have hexp : ∀ u ∈ U, u = ∑ k, ⟪b k, u⟫_ℂ • b k := by
    intro u hu
    have h1 := congrArg Subtype.val (ob.sum_repr' ⟨u, hu⟩)
    simpa [b, Submodule.coe_inner] using h1.symm
  let c : G → Matrix (Fin n) (Fin n) ℂ := fun h => Matrix.of fun k j => ⟪b k, R μ h (b j)⟫_ℂ
  have hE : ∀ h j, R μ h (b j) = ∑ k, c h k j • b k := fun h j => hexp _ (hR h _ (hb j))
  have hmul : ∀ g h, c (g * h) = c g * c h := by
    intro g h; ext k j
    simp only [c, of_apply, Matrix.mul_apply]
    rw [R_mul]
    conv_lhs => rw [hE h j, map_sum, inner_sum]
    refine Finset.sum_congr rfl fun l _ => ?_
    rw [map_smul, inner_smul_right, mul_comm]; rfl
  have hone : c 1 = 1 := by
    ext k j; simp only [c, of_apply, R_one, hbo, Matrix.one_apply]
  let σ : G →* Matrix (Fin n) (Fin n) ℂ := { toFun := c, map_one' := hone, map_mul' := hmul }
  have hσc : ∀ h, σ h = c h := fun h => rfl
  choose φ hφ using fun j => hc (b j) (hb j)
  have hcont : Continuous fun g => σ g := by
    refine continuous_pi fun k => continuous_pi fun j => ?_
    change Continuous fun h => ⟪b k, R μ h (b j)⟫_ℂ
    rw [hφ j]
    exact continuous_const.inner (R_cont μ (φ j))
  have hunit : ∀ g, σ g ∈ Matrix.unitaryGroup (Fin n) ℂ := by
    intro g
    rw [mem_unitaryGroup_iff']
    ext a a'
    simp only [Matrix.mul_apply, Matrix.star_apply, hσc, c, of_apply, Matrix.one_apply]
    have h1 := ob.sum_inner_mul_inner ⟨R μ g (b a), hR g _ (hb a)⟩ ⟨R μ g (b a'), hR g _ (hb a')⟩
    simp only [Submodule.coe_inner] at h1
    rw [← hbo, ← R_inner μ g, ← h1]
    refine Finset.sum_congr rfl fun k _ => ?_
    rw [show star ⟪b k, R μ g (b a)⟫_ℂ = (starRingEnd ℂ) ⟪b k, R μ g (b a)⟫_ℂ from rfl,
      inner_conj_symm]
  have hn0 : 0 < n := by
    rw [hn]; apply Nat.pos_of_ne_zero; intro h0; exact hU (Submodule.finrank_eq_zero.mp h0)
  let ι : (Fin n → ℂ) →ₗ[ℂ] Lp ℂ 2 μ := Fintype.linearCombination ℂ b
  have hι : ∀ v, ι v = ∑ k, v k • b k := fun v => Fintype.linearCombination_apply ℂ b v
  have hιU : ∀ v, ι v ∈ U := fun v => by
    rw [hι]; exact Submodule.sum_mem _ fun k _ => Submodule.smul_mem _ _ (hb k)
  have hιR : ∀ h v, R μ h (ι v) = ι (σ h *ᵥ v) := by
    intro h v
    rw [hι, hι, map_sum]
    simp_rw [map_smul, hE, Finset.smul_sum, smul_smul]
    rw [Finset.sum_comm]
    refine Finset.sum_congr rfl fun k _ => ?_
    simp only [mulVec, dotProduct, Finset.sum_smul]
    refine Finset.sum_congr rfl fun j _ => ?_
    rw [hσc, mul_comm]
  have hli : LinearIndependent ℂ b :=
    ob.orthonormal.linearIndependent.map' U.subtype (Submodule.ker_subtype U)
  have hιinj : Function.Injective ι := by
    rw [← LinearMap.ker_eq_bot, LinearMap.ker_eq_bot']
    intro v hv
    rw [hι] at hv
    funext k; exact Fintype.linearIndependent_iff.mp hli v hv k
  have hirr : IsIrred σ := by
    refine ⟨hn0, fun W hW => ?_⟩
    have hle : W.map ι ≤ U := by rintro _ ⟨v, _, rfl⟩; exact hιU v
    have hinv : ∀ h, ∀ u ∈ W.map ι, R μ h u ∈ W.map ι := by
      rintro h _ ⟨v, hv, rfl⟩; exact ⟨σ h *ᵥ v, hW h v hv, (hιR h v).symm⟩
    rcases hmin _ hle hinv with h0 | h1
    · left
      rw [eq_bot_iff]; intro v hv
      have : ι v ∈ W.map ι := ⟨v, hv, rfl⟩
      rw [h0, Submodule.mem_bot] at this
      rw [Submodule.mem_bot]; exact hιinj (this.trans (map_zero ι).symm)
    · right
      rw [eq_top_iff]; intro v _
      have : ι v ∈ W.map ι := h1 ▸ hιU v
      obtain ⟨v', hv', he⟩ := this
      rwa [← hιinj he]
  refine ⟨n, σ, ⟨hcont, hunit⟩, hirr, ?_⟩
  have hbj : ∀ j, b j ∈ coefSpan μ σ hcont := by
    intro j
    have hpt : ∀ h x, φ j (x * h) = ∑ k, c h k j * φ k x := by
      intro h
      have e1 := hE h j
      rw [hφ j, R_toH] at e1
      have e2 : ∑ k, c h k j • b k = toH μ (∑ k, c h k j • φ k) := by
        rw [map_sum]; simp_rw [map_smul, ← hφ]
      rw [e2] at e1
      have e3 := toH_inj μ e1
      intro x
      have := congrArg (fun F : C(G, ℂ) => F x) e3
      simpa using this
    have hφj : φ j = ∑ k, φ k 1 • coefC σ hcont k j := by
      ext h
      have := hpt h 1
      rw [one_mul] at this
      rw [this]
      simp [coefC_apply, hσc, mul_comm]
    rw [hφ j, hφj, map_sum]
    exact Submodule.sum_mem _ fun k _ => by
      rw [map_smul]; exact Submodule.smul_mem _ _ (Submodule.subset_span ⟨(k, j), rfl⟩)
  intro u hu
  rw [hexp u hu]
  exact Submodule.sum_mem _ fun k _ => Submodule.smul_mem _ _ (hbj k)


lemma orth_of_adm (f : Lp ℂ 2 μ) (hf : ∀ ψ : C(G, ℂ), Adm ψ → ⟪toH μ ψ, f⟫_ℂ = 0) : f = 0 := by
  have hall : ∀ φ : C(G, ℂ), ⟪toH μ φ, f⟫_ℂ = 0 := by
    intro φ
    let φs : C(G, ℂ) := ⟨fun y => (starRingEnd ℂ) (φ y⁻¹), by fun_prop⟩
    let ψ1 : C(G, ℂ) := φ + φs
    let ψ2 : C(G, ℂ) := Complex.I • (φ - φs)
    have h1 : Adm ψ1 := by
      intro y
      simp only [ψ1, φs, ContinuousMap.add_apply, ContinuousMap.coe_mk, inv_inv, map_add,
        Complex.conj_conj]
      ring
    have h2 : Adm ψ2 := by
      intro y
      simp only [ψ2, φs, ContinuousMap.smul_apply, ContinuousMap.sub_apply, ContinuousMap.coe_mk,
        inv_inv, smul_eq_mul, map_mul, map_sub, Complex.conj_conj, Complex.conj_I]
      ring
    have h3 : (2 : ℂ) • φ = ψ1 - Complex.I • ψ2 := by
      ext y
      simp only [ψ1, ψ2, ContinuousMap.smul_apply, ContinuousMap.sub_apply, ContinuousMap.add_apply,
        smul_eq_mul]
      ring_nf
      rw [Complex.I_sq]; ring
    have h4 : ⟪toH μ ((2 : ℂ) • φ), f⟫_ℂ = 0 := by
      rw [h3, map_sub, map_smul, inner_sub_left, inner_smul_left, hf ψ1 h1, hf ψ2 h2]
      simp
    rw [map_smul, inner_smul_left] at h4
    simpa using h4
  have : ⟪f, f⟫_ℂ = 0 := by
    refine DenseRange.induction_on (p := fun g => ⟪g, f⟫_ℂ = 0) (toH_dense μ) f ?_ hall
    exact isClosed_eq (continuous_id.inner continuous_const) continuous_const
  exact inner_self_eq_zero.mp this

lemma complete_aux (S : Submodule ℂ (Lp ℂ 2 μ))
    (hK : ∀ ψ, ∀ s ∈ S, K μ ψ s ∈ S) (hRS : ∀ h, ∀ s ∈ S, R μ h s ∈ S)
    (hirr : ∀ (n : ℕ) (σ : G →* Matrix (Fin n) (Fin n) ℂ) (hσ : IsContUnitaryRep σ),
      IsIrred σ → coefSpan μ σ hσ.1 ≤ S) :
    Sᗮ = ⊥ := by
  rw [Submodule.eq_bot_iff]; intro f hf
  have hWK : ∀ ψ, Adm ψ → ∀ w ∈ Sᗮ, K μ ψ w ∈ Sᗮ := by
    intro ψ hψ w hw
    rw [Submodule.mem_orthogonal]; intro s hs
    have := K_symm μ ψ hψ s w
    simp only [ContinuousLinearMap.coe_coe] at this
    rw [← this]
    exact (Submodule.mem_orthogonal _ _).mp hw _ (hK ψ s hs)
  have hWR : ∀ h, ∀ w ∈ Sᗮ, R μ h w ∈ Sᗮ := by
    intro h w hw
    rw [Submodule.mem_orthogonal]; intro s hs
    have := R_adj μ h⁻¹ s w
    rw [inv_inv] at this
    rw [← this]
    exact (Submodule.mem_orthogonal _ _).mp hw _ (hRS _ s hs)
  refine orth_of_adm μ f fun ψ hψ => K_eq_zero μ ψ hψ f ?_
  let KW : Sᗮ →L[ℂ] Sᗮ := (K μ ψ).restrict (hWK ψ hψ)
  have hcomp : IsCompactOperator KW := (K_compact μ ψ).restrict' (hWK ψ hψ)
  have hsym : (KW : Sᗮ →ₗ[ℂ] Sᗮ).IsSymmetric := (K_symm μ ψ hψ).restrict_invariant (hWK ψ hψ)
  have hKW : KW = 0 := by
    rw [← ContinuousLinearMap.eq_zero_of_forall_hasEigenvalue_eq_zero hcomp hsym]
    intro l hl
    by_contra hl0
    have hfin := ContinuousLinearMap.finite_dimensional_eigenspace hcomp l hl0
    let E := Module.End.eigenspace (KW : Module.End ℂ Sᗮ) l
    let E' : Submodule ℂ (Lp ℂ 2 μ) := E.map (Sᗮ).subtype
    have hE'mem : ∀ x ∈ E', x ∈ Sᗮ ∧ K μ ψ x = l • x := by
      rintro _ ⟨w, hw, rfl⟩
      refine ⟨w.2, ?_⟩
      have := Module.End.mem_eigenspace_iff.mp hw
      exact congrArg Subtype.val this
    have hE'of : ∀ x (hx : x ∈ Sᗮ), K μ ψ x = l • x → x ∈ E' := by
      intro x hx hKx
      exact ⟨⟨x, hx⟩, Module.End.mem_eigenspace_iff.mpr (Subtype.ext hKx), rfl⟩
    have hE'ne : E' ≠ ⊥ := by
      obtain ⟨v, hv, hv0⟩ := Submodule.exists_mem_ne_zero_of_ne_bot
        (Module.End.hasEigenvalue_iff.mp hl)
      intro hbot
      have : (v : Lp ℂ 2 μ) ∈ E' := ⟨v, hv, rfl⟩
      rw [hbot, Submodule.mem_bot] at this
      exact hv0 (Subtype.ext this)
    have hE'R : ∀ h, ∀ u ∈ E', R μ h u ∈ E' := by
      intro h u hu
      obtain ⟨hu1, hu2⟩ := hE'mem u hu
      refine hE'of _ (hWR h u hu1) ?_
      rw [K_R, hu2, map_smul]
    have hE'c : ∀ u ∈ E', ∃ φ, u = toH μ φ := by
      intro u hu
      obtain ⟨_, hu2⟩ := hE'mem u hu
      refine ⟨l⁻¹ • J μ ψ u, ?_⟩
      rw [map_smul, ← K_apply, hu2, smul_smul, inv_mul_cancel₀ hl0, one_smul]
    have hE'fin : FiniteDimensional ℂ E' := Module.Finite.map _ _
    have hex : ∃ m, ∃ U : Submodule ℂ (Lp ℂ 2 μ), U ≤ E' ∧ U ≠ ⊥ ∧
        (∀ h, ∀ u ∈ U, R μ h u ∈ U) ∧ Module.finrank ℂ U = m :=
      ⟨_, E', le_rfl, hE'ne, hE'R, rfl⟩
    classical
    obtain ⟨U, hUE, hU0, hUR, hUm⟩ := Nat.find_spec hex
    have hUfin : FiniteDimensional ℂ U := Submodule.finiteDimensional_of_le hUE
    have hmin : ∀ U' ≤ U, (∀ h, ∀ u ∈ U', R μ h u ∈ U') → U' = ⊥ ∨ U' = U := by
      intro U' hU' hU'R
      by_cases h0 : U' = ⊥
      · left; exact h0
      · right
        apply Submodule.eq_of_le_of_finrank_le hU'
        rw [hUm]
        exact Nat.find_min' hex ⟨U', hU'.trans hUE, h0, hU'R, rfl⟩
    obtain ⟨n, σ, hσ, hσi, hUle⟩ :=
      irred_piece μ U hU0 hUR hmin (fun u hu => hE'c u (hUE hu))
    have hUS : U ≤ S := hUle.trans (hirr n σ hσ hσi)
    apply hU0
    rw [eq_bot_iff]; intro u hu
    have h1 : u ∈ Sᗮ := (hE'mem u (hUE hu)).1
    rw [Submodule.mem_bot]
    exact inner_self_eq_zero.mp ((Submodule.mem_orthogonal _ _).mp h1 u (hUS hu))
  have := congrArg (fun T : Sᗮ →L[ℂ] Sᗮ => ((T ⟨f, hf⟩ : Sᗮ) : Lp ℂ 2 μ)) hKW
  simpa [KW] using this

end Hilb


section Index

/-- Continuous unitary irreducible representations of every size. -/
def IrrRep (G : Type u) [Group G] [TopologicalSpace G] : Type u :=
  {p : Σ n : ℕ, G →* Matrix (Fin n) (Fin n) ℂ // IsContUnitaryRep p.2 ∧ IsIrred p.2}

/-- Two of them are related when they are equivalent. -/
def irrSetoid : Setoid (IrrRep G) where
  r p q := Equivalent p.1.2 q.1.2
  iseqv := ⟨fun _ => ⟨LinearEquiv.refl ℂ _, fun _ _ => rfl⟩, fun h => equivalent_symm h,
    fun ⟨T, hT⟩ ⟨T', hT'⟩ => ⟨T.trans T', fun g v => by simp [hT, hT']⟩⟩

lemma peter_weyl_aux (μ : Measure G) [μ.IsHaarMeasure] [IsProbabilityMeasure μ] :
    ∃ (ι : Type u) (d : ι → ℕ) (π : ∀ i, G →* Matrix (Fin (d i)) (Fin (d i)) ℂ),
      (∀ i, IsContUnitaryRep (π i) ∧ IsIrred (π i)) ∧
      (∀ i j, Equivalent (π i) (π j) → i = j) ∧
      (∀ (n : ℕ) (σ : G →* Matrix (Fin n) (Fin n) ℂ),
        IsContUnitaryRep σ → IsIrred σ → ∃ i, Equivalent σ (π i)) ∧
      ∃ b : HilbertBasis (Σ i, Fin (d i) × Fin (d i)) ℂ (Lp ℂ 2 μ),
        ∀ i j k, ⇑(b ⟨i, (j, k)⟩) =ᵐ[μ] fun g => (Real.sqrt (d i) : ℂ) * π i g j k := by
  classical
  let ι := Quotient (irrSetoid (G := G))
  let d : ι → ℕ := fun i => i.out.1.1
  let π : ∀ i, G →* Matrix (Fin (d i)) (Fin (d i)) ℂ := fun i => i.out.1.2
  have hπ : ∀ i, IsContUnitaryRep (π i) ∧ IsIrred (π i) := fun i => i.out.2
  have hinj : ∀ i j, Equivalent (π i) (π j) → i = j := fun i j h =>
    Quotient.out_equiv_out.mp h
  have hall : ∀ (n : ℕ) (σ : G →* Matrix (Fin n) (Fin n) ℂ),
      IsContUnitaryRep σ → IsIrred σ → ∃ i, Equivalent σ (π i) := by
    intro n σ h1 h2
    let p : IrrRep G := ⟨⟨n, σ⟩, h1, h2⟩
    exact ⟨Quotient.mk _ p, equivalent_symm (Quotient.mk_out (s := irrSetoid) p)⟩
  refine ⟨ι, d, π, hπ, hinj, hall, ?_⟩
  let sq : ι → ℂ := fun i => (Real.sqrt (d i) : ℂ)
  have hsq : ∀ i, sq i * (starRingEnd ℂ) (sq i) = d i := by
    intro i
    simp only [sq, Complex.conj_ofReal]
    rw [← Complex.ofReal_mul, Real.mul_self_sqrt (Nat.cast_nonneg _)]
    simp
  have hsq0 : ∀ i, sq i ≠ 0 := by
    intro i h
    have := hsq i
    rw [h, zero_mul] at this
    exact (Nat.cast_ne_zero.mpr (hπ i).2.1.ne') this.symm
  let e : (Σ i, Fin (d i) × Fin (d i)) → Lp ℂ 2 μ := fun p =>
    toH μ (sq p.1 • coefC (π p.1) (hπ p.1).1.1 p.2.1 p.2.2)
  have hon : Orthonormal ℂ e := by
    rw [orthonormal_iff_ite]
    rintro ⟨i, j, k⟩ ⟨i', j', k'⟩
    simp only [e]
    rw [toH_inner]
    simp only [ContinuousMap.smul_apply, coefC_apply, smul_eq_mul]
    by_cases hii : i = i'
    · subst hii
      have hs := (schur_aux μ (π i) (π i) (hπ i).1 (hπ i).2 (hπ i).1 (hπ i).2).2 j' k' j k
      have e1 : ∀ x, sq i * π i x j' k' * (starRingEnd ℂ) (sq i * π i x j k) =
          (d i : ℂ) * (π i x j' k' * star (π i x j k)) := by
        intro x
        rw [← hsq i, map_mul]
        change _ = _ * (_ * (starRingEnd ℂ) _)
        ring
      simp_rw [e1]
      rw [integral_const_mul, hs]
      have hd : (d i : ℂ) ≠ 0 := Nat.cast_ne_zero.mpr (hπ i).2.1.ne'
      by_cases hjk : j' = j ∧ k' = k
      · obtain ⟨rfl, rfl⟩ := hjk
        simp [hd]
      · rw [if_neg hjk, mul_zero, if_neg]
        intro heq
        apply hjk
        simp only [Sigma.mk.injEq, heq_eq_eq, true_and, Prod.mk.injEq] at heq
        exact ⟨heq.1.symm, heq.2.symm⟩
    · have hne : ¬ Equivalent (π i') (π i) := fun h => hii (hinj _ _ h).symm
      have hs := (schur_aux μ (π i') (π i) (hπ i').1 (hπ i').2 (hπ i).1 (hπ i).2).1 hne j' k' j k
      have e1 : ∀ x, sq i' * π i' x j' k' * (starRingEnd ℂ) (sq i * π i x j k) =
          (sq i' * (starRingEnd ℂ) (sq i)) * (π i' x j' k' * star (π i x j k)) := by
        intro x
        rw [map_mul]
        change _ = _ * (_ * (starRingEnd ℂ) _)
        ring
      simp_rw [e1]
      rw [integral_const_mul, hs, mul_zero, if_neg]
      intro heq
      exact hii (congrArg Sigma.fst heq)
  set S := Submodule.span ℂ (Set.range e) with hS
  have hcoef : ∀ i (a b : Fin (d i)), toH μ (coefC (π i) (hπ i).1.1 a b) ∈ S := by
    intro i a b
    have : toH μ (coefC (π i) (hπ i).1.1 a b) = (sq i)⁻¹ • e ⟨i, (a, b)⟩ := by
      simp only [e, map_smul, smul_smul, inv_mul_cancel₀ (hsq0 i), one_smul]
    rw [this]
    exact Submodule.smul_mem _ _ (Submodule.subset_span ⟨_, rfl⟩)
  have hgen : ∀ T : Lp ℂ 2 μ →ₗ[ℂ] Lp ℂ 2 μ, (∀ p, T (e p) ∈ S) → ∀ s ∈ S, T s ∈ S := by
    intro T hT s hs
    have : S ≤ S.comap T := Submodule.span_le.mpr (by rintro _ ⟨p, rfl⟩; exact hT p)
    exact this hs
  have hK : ∀ ψ, ∀ s ∈ S, K μ ψ s ∈ S := by
    intro ψ
    refine hgen (K μ ψ : Lp ℂ 2 μ →ₗ[ℂ] Lp ℂ 2 μ) ?_
    rintro ⟨i, j, k⟩
    simp only [e, ContinuousLinearMap.coe_coe, map_smul, K_apply, J_coefC, map_sum]
    exact Submodule.smul_mem _ _ (Submodule.sum_mem _ fun l _ => Submodule.smul_mem _ _
      (hcoef i l k))
  have hRS : ∀ h, ∀ s ∈ S, R μ h s ∈ S := by
    intro h
    refine hgen (R μ h : Lp ℂ 2 μ →ₗ[ℂ] Lp ℂ 2 μ) ?_
    rintro ⟨i, j, k⟩
    change R μ h (toH μ (sq i • coefC (π i) (hπ i).1.1 j k)) ∈ S
    simp only [map_smul]
    rw [R_toH, coefC_mulRight, map_sum]
    exact Submodule.smul_mem _ _ (Submodule.sum_mem _ fun l _ => Submodule.smul_mem _ _
      (hcoef i j l))
  have hirr : ∀ (n : ℕ) (σ : G →* Matrix (Fin n) (Fin n) ℂ) (hσ : IsContUnitaryRep σ),
      IsIrred σ → coefSpan μ σ hσ.1 ≤ S := by
    intro n σ hσ hσi
    obtain ⟨i, hi⟩ := hall n σ hσ hσi
    refine Submodule.span_le.mpr ?_
    rintro _ ⟨⟨a, b⟩, rfl⟩
    have h1 := coef_mem_of_equiv μ σ (π i) hσ.1 (hπ i).1.1 hi a b
    exact (Submodule.span_le.mpr (by rintro _ ⟨⟨c, d'⟩, rfl⟩; exact hcoef i c d') :
      coefSpan μ (π i) (hπ i).1.1 ≤ S) h1
  have hsp : (Submodule.span ℂ (Set.range e))ᗮ = ⊥ := complete_aux μ S hK hRS hirr
  refine ⟨HilbertBasis.mkOfOrthogonalEqBot hon hsp, fun i j k => ?_⟩
  rw [HilbertBasis.coe_mkOfOrthogonalEqBot]
  exact toH_ae μ _

end Index

/-- **Peter-Weyl: the matrix entries are a Fourier basis.** Let `G` be a compact group and `μ` its
Haar average (shift-proof, total 1). Then there is a list `π i` of continuous, unitary,
irreducible representations, of sizes `d i`, no two of them equivalent and every continuous
unitary irreducible representation equivalent to one on the list (this list is `Ĝ`), such that
the functions `g ↦ √(d i) · (π i g) j k`, over every `i` and every row `j` and column `k`, form
an orthonormal basis of `L²(G)`: every finite-energy function is the sum, converging in energy,
of its matrix-entry waves, and its energy is the sum of the squared coefficients. -/
theorem matrix_entries_form_orthonormal_basis
    (μ : Measure G) [μ.IsHaarMeasure] [IsProbabilityMeasure μ] :
    ∃ (ι : Type u) (d : ι → ℕ) (π : ∀ i, G →* Matrix (Fin (d i)) (Fin (d i)) ℂ),
      (∀ i, IsContUnitaryRep (π i) ∧ IsIrred (π i)) ∧
      (∀ i j, Equivalent (π i) (π j) → i = j) ∧
      (∀ (n : ℕ) (σ : G →* Matrix (Fin n) (Fin n) ℂ),
        IsContUnitaryRep σ → IsIrred σ → ∃ i, Equivalent σ (π i)) ∧
      ∃ b : HilbertBasis (Σ i, Fin (d i) × Fin (d i)) ℂ (Lp ℂ 2 μ),
        ∀ i j k, ⇑(b ⟨i, (j, k)⟩) =ᵐ[μ] fun g => (Real.sqrt (d i) : ℂ) * π i g j k := by
  exact peter_weyl_aux μ

/-- **Averaging makes a representation keep lengths.** Let `π` be any continuous representation
of the compact group `G` by `n`-by-`n` complex matrices, and average `(π g)ᴴ (π g)` with Haar
measure: `M = ∫ (π g)ᴴ (π g) dg`, so that `uᴴ M v = ∫ ⟨π g u, π g v⟩ dg`. Then `M` is positive
definite (an inner product) and every move keeps it: `(π h)ᴴ M (π h) = M`. Hence, in a basis
orthonormal for `M`, every `π g` is unitary: some invertible `P` makes every `P (π g) P⁻¹`
unitary. -/
theorem haar_average_makes_representation_unitary
    (μ : Measure G) [μ.IsHaarMeasure] [IsProbabilityMeasure μ]
    {n : ℕ} (π : G →* Matrix (Fin n) (Fin n) ℂ) (hπ : Continuous fun g => π g) :
    let M : Matrix (Fin n) (Fin n) ℂ := Matrix.of fun i j => ∫ g, ((π g)ᴴ * π g) i j ∂μ
    M.PosDef ∧ (∀ h, (π h)ᴴ * M * π h = M) ∧
      ∃ P : Matrix (Fin n) (Fin n) ℂ, IsUnit P ∧
        ∀ g, P * π g * P⁻¹ ∈ Matrix.unitaryGroup (Fin n) ℂ := by
  exact haar_unitary_aux μ π hπ

/-- **The entries are orthogonal (Schur).** For continuous unitary irreducible representations
`π` (size `n`) and `σ` (size `m`) of the compact group `G`, with Haar average `μ`: if `π` and `σ`
are not equivalent, every entry of `π` is perpendicular to every entry of `σ`,
`∫ π_ij(g) · conj σ_kl(g) dg = 0`; and two entries of `π` itself satisfy
`∫ π_ij(g) · conj π_kl(g) dg = δ_ik δ_jl / n`. -/
theorem schur_orthogonality_of_entries
    (μ : Measure G) [μ.IsHaarMeasure] [IsProbabilityMeasure μ]
    {n m : ℕ} (π : G →* Matrix (Fin n) (Fin n) ℂ) (σ : G →* Matrix (Fin m) (Fin m) ℂ)
    (hπ : IsContUnitaryRep π) (hπi : IsIrred π) (hσ : IsContUnitaryRep σ) (hσi : IsIrred σ) :
    (¬ Equivalent π σ → ∀ i j k l, ∫ g, π g i j * star (σ g k l) ∂μ = 0) ∧
      ∀ i j k l, ∫ g, π g i j * star (π g k l) ∂μ = if i = k ∧ j = l then 1 / (n : ℂ) else 0 := by
  exact schur_aux μ π σ hπ hπi hσ hσi

/-! ### The card's worked numbers -/

/-- The triangle's turn `A` and swap `B`, in the basis of two corners 120° apart. -/
def triA : Matrix (Fin 2) (Fin 2) ℤ := !![0, -1; 1, -1]
def triB : Matrix (Fin 2) (Fin 2) ℤ := !![0, 1; 1, 0]

/-- The six symmetries of the triangle: `1, A, A², B, AB, A²B`. -/
def triSix : List (Matrix (Fin 2) (Fin 2) ℤ) := [1, triA, triA ^ 2, triB, triA * triB, triA ^ 2 * triB]

-- The turn has order 3, the swap order 2, and `B A B = A²`: so these six are closed under
-- multiplying, and they are six different matrices.
example : triA ^ 3 = 1 ∧ triB ^ 2 = 1 ∧ triB * triA * triB = triA ^ 2 := by decide
example : triSix.Nodup ∧ triSix.length = 6 := by decide
example : ∀ g ∈ triSix, ∀ h ∈ triSix, g * h ∈ triSix := by decide

-- The sum-of-squares rule for the triangle: 1² + 1² + 2² = 6, the size of S₃.
example : (1 : ℕ) ^ 2 + 1 ^ 2 + 2 ^ 2 = 6 ∧ Fintype.card (Equiv.Perm (Fin 3)) = 6 := by decide

-- A does not keep plain lengths: it sends (1, 1), squared length 2, to (−1, 0), squared length 1.
example : triA *ᵥ ![1, 1] = ![-1, 0] := by decide

-- Averaging gᵀ g over the six moves: the sum is [[8, −4], [−4, 8]], so M = [[4/3, −2/3], [−2/3, 4/3]].
example : (triSix.map fun g => gᵀ * g).sum = !![8, -4; -4, 8] := by decide

-- Every move keeps the averaged inner product: gᵀ M g = M (checked on 6M = [[8, −4], [−4, 8]]).
example : ∀ g ∈ triSix, gᵀ * !![8, -4; -4, 8] * g = !![8, -4; -4, 8] := by decide

-- Before averaging, the mean of the squared top-left entry is 4/6 = 2/3, not 1/2.
example : (triSix.map fun g => g 0 0 ^ 2).sum = 4 := by decide
example : (4 : ℚ) / 6 = 2 / 3 ∧ (2 / 3 : ℚ) ≠ 1 / 2 := by norm_num

-- The single swap: without the weights d_π, its value at the swap is rebuilt as 2/3, not 1:
-- 1/6 from the constant, 1/6 from the sign, and 2/6 from the four entries of the 2-by-2 piece
-- (their squares at the swap add to 2, since that matrix is unitary).
example : (1 / 6 : ℚ) + 1 / 6 + 1 / 3 = 2 / 3 := by norm_num

-- The 12-hour clock: 12 characters, each a 1-by-1 matrix: 12 × 1² = 12.
example : 12 * 1 ^ 2 = 12 := by norm_num

-- Spherical harmonics: (ℓ + 1)(ℓ + 2)/2 terms of degree ℓ, minus the ℓ(ℓ − 1)/2 of degree ℓ − 2,
-- leave 2ℓ + 1: 1, 3, 5, 7, 9 for ℓ = 0 to 4.
example : ∀ l ∈ Finset.range 5, (l + 1) * (l + 2) / 2 - l * (l - 1) / 2 = 2 * l + 1 := by decide
example : (List.range 5).map (fun l => (l + 1) * (l + 2) / 2) = [1, 3, 6, 10, 15] := by decide

-- Up to degree 3: the sphere holds 1 + 3 + 5 + 7 = 16 numbers, the rotations 1 + 9 + 25 + 49 = 84.
example : ((List.range 4).map fun l => 2 * l + 1).sum = 16 ∧
    ((List.range 4).map fun l => (2 * l + 1) ^ 2).sum = 84 := by decide

-- The globe T = 30 − 40 z²: degree-0 part 50/3 °C, E₀ = 2500/9, E₂ = 1280/9, total 420 °C².
example : (30 : ℚ) - 40 / 3 = 50 / 3 ∧ (50 / 3 : ℚ) ^ 2 = 2500 / 9 ∧
    1600 * ((1 : ℚ) / 5 - 2 / 9 + 1 / 9) = 1280 / 9 ∧
    900 - 2400 * (1 / 3 : ℚ) + 1600 * (1 / 5) = 420 ∧ (2500 / 9 : ℚ) + 1280 / 9 = 420 := by
  norm_num

-- Tilted 30°: the north pole reads 30 − 40 cos² 30° = 0 °C.
example : (30 : ℝ) - 40 * Real.cos (Real.pi / 6) ^ 2 = 0 := by
  rw [Real.cos_pi_div_six, div_pow, Real.sq_sqrt (by norm_num)]; norm_num

-- The shear [[1, 1], [0, 1]] on the whole numbers sends (0, 1) to (n, 1) after n steps:
-- squared lengths 2, 101, 10001 after 1, 10, 100 steps.
example : (!![1, 1; 0, 1] : Matrix (Fin 2) (Fin 2) ℤ) ^ 10 *ᵥ ![0, 1] = ![10, 1] := by decide
example : (1 : ℤ) ^ 2 + 1 ^ 2 = 2 ∧ (10 : ℤ) ^ 2 + 1 ^ 2 = 101 ∧ (100 : ℤ) ^ 2 + 1 ^ 2 = 10001 := by
  norm_num

#print axioms haar_rightInvariant
#print axioms integrable_of_cont
#print axioms mul_of_integral_mul
#print axioms dot_of_integral
#print axioms exists_sqrt_of_posDef
#print axioms rep_inv_mul
#print axioms rep_mul_inv
#print axioms haar_unitary_aux
#print axioms rep_inv_eq_star
#print axioms equivalent_symm
#print axioms schur_zero
#print axioms schur_scalar
#print axioms avg_intertwine
#print axioms avg_trace
#print axioms schur_aux
#print axioms toH_ae
#print axioms toH_inner
#print axioms toH_inj
#print axioms toH_dense
#print axioms mp_right
#print axioms R_ae
#print axioms R_toH
#print axioms R_mul
#print axioms R_one
#print axioms R_inv_R
#print axioms R_R_inv
#print axioms R_inner
#print axioms R_adj
#print axioms cont_mulRight
#print axioms R_cont
#print axioms kerC_apply
#print axioms Φ_cont
#print axioms Φ_bound
#print axioms J_apply
#print axioms K_apply
#print axioms J_compact
#print axioms K_compact
#print axioms J_toH
#print axioms K_symm
#print axioms coefC_apply
#print axioms coefC_mulRight
#print axioms J_coefC
#print axioms kerC_mulRight
#print axioms J_R
#print axioms K_R
#print axioms K_eq_zero
#print axioms coef_mem_of_equiv
#print axioms irred_piece
#print axioms orth_of_adm
#print axioms complete_aux
#print axioms peter_weyl_aux
#print axioms matrix_entries_form_orthonormal_basis
#print axioms haar_average_makes_representation_unitary
#print axioms schur_orthogonality_of_entries

end PeterWeyl
