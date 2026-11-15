-- Mayer-Vietoris and exact sequences: for a simplicial set covered by two subcomplexes the Mayer-Vietoris row of chains is short exact and its homology row is exact at every spot, excision holds for subcomplexes, and at an exact spot of vector spaces the dimension is the rank in plus the rank out.
import Mathlib.AlgebraicTopology.SimplicialSet.Homology.Relative
import Mathlib.AlgebraicTopology.SimplicialSet.SubcomplexColimits
import Mathlib.CategoryTheory.Abelian.CommSq
import Mathlib.Algebra.Homology.HomologicalComplexLimits
import Mathlib.LinearAlgebra.FiniteDimensional.Lemmas
import Mathlib.Tactic.NormNum

open CategoryTheory Limits SSet

universe w

theorem mv_isPushout_sSet {X : SSet.{w}} (U V : X.Subcomplex) (hcover : U ⊔ V = ⊤) :
    IsPushout (Subcomplex.homOfLE (inf_le_left : U ⊓ V ≤ U))
      (Subcomplex.homOfLE (inf_le_right : U ⊓ V ≤ V)) U.ι V.ι := by
  have sq : Subcomplex.BicartSq (U ⊓ V) U V ⊤ := ⟨hcover, rfl⟩
  exact sq.isPushout.of_iso (Iso.refl _) (Iso.refl _) (Iso.refl _) (Subcomplex.topIso X)
    rfl rfl rfl rfl

theorem mv_isPushout_X {𝒜 : Type*} [Category* 𝒜] [Preadditive 𝒜] [HasCoproducts.{w} 𝒜]
    {A B C D : SSet.{w}} {t : A ⟶ B} {l : A ⟶ C} {r : B ⟶ D} {b : C ⟶ D}
    (h : IsPushout t l r b) (R : 𝒜) (n : ℕ) :
    IsPushout ((chainComplexMap t R).f n) ((chainComplexMap l R).f n)
      ((chainComplexMap r R).f n) ((chainComplexMap b R).f n) := by
  have h1 := h.map ((evaluation _ _).obj (Opposite.op (SimplexCategory.mk n)))
  have h2 := h1.map (sigmaConst.{w}.obj R)
  exact h2

theorem mv_isPushout_chain {𝒜 : Type*} [Category* 𝒜] [Preadditive 𝒜] [HasCoproducts.{w} 𝒜]
    {A B C D : SSet.{w}} {t : A ⟶ B} {l : A ⟶ C} {r : B ⟶ D} {b : C ⟶ D}
    (h : IsPushout t l r b) (R : 𝒜) :
    IsPushout (chainComplexMap t R) (chainComplexMap l R)
      (chainComplexMap r R) (chainComplexMap b R) := by
  have w : chainComplexMap t R ≫ chainComplexMap r R =
      chainComplexMap l R ≫ chainComplexMap b R := by
    simp only [← Functor.map_comp, h.w]
  refine ⟨⟨w⟩, ⟨HomologicalComplex.isColimitOfEval _ _ (fun n => ?_)⟩⟩
  exact (PushoutCocone.isColimitMapCoconeEquiv _ _).2 (mv_isPushout_X h R n).isColimit

theorem mv_isIso_of_isPushout {𝒜 : Type*} [Category* 𝒜] [Preadditive 𝒜]
    {X₁ X₂ X₃ X₄ : 𝒜} {t : X₁ ⟶ X₂} {l : X₁ ⟶ X₃} {r : X₂ ⟶ X₄} {b : X₃ ⟶ X₄}
    (hP : IsPushout t l r b) {c₁ : CokernelCofork t} {c₂ : CokernelCofork b}
    (hc₁ : IsColimit c₁) (hc₂ : IsColimit c₂) (φ : c₁.pt ⟶ c₂.pt)
    (hφ : c₁.π ≫ φ = r ≫ c₂.π) : IsIso φ := by
  let d : X₄ ⟶ c₁.pt := hP.desc c₁.π 0 (by simp [c₁.condition])
  have hd : b ≫ d = 0 := by simp [d]
  let ψ : c₂.pt ⟶ c₁.pt := Cofork.IsColimit.desc hc₂ d (by simpa using hd)
  have hψ : c₂.π ≫ ψ = d := Cofork.IsColimit.π_desc' hc₂ d _
  refine ⟨ψ, ?_, ?_⟩
  · apply Cofork.IsColimit.hom_ext hc₁
    rw [reassoc_of% hφ, hψ]
    simp [d]
  · apply Cofork.IsColimit.hom_ext hc₂
    rw [reassoc_of% hψ]
    apply hP.hom_ext
    · simp [d, hφ]
    · simp [d, reassoc_of% hd, c₂.condition]

section MayerVietoris

variable {𝒜 : Type*} [Category* 𝒜] [Abelian 𝒜] [HasCoproducts.{w} 𝒜]

/-- The Mayer-Vietoris row of chains for two subcomplexes `U`, `V` of `X`, coefficients `R`:
`C(U ∩ V) → C(U) ⊕ C(V) → C(X)`, with `i(c) = (c, -c)` and `j(a, b) = a + b`. -/
noncomputable def mayerVietorisChains {X : SSet.{w}} (U V : X.Subcomplex) (R : 𝒜) :
    ShortComplex (ChainComplex 𝒜 ℕ) :=
  ShortComplex.mk
    (biprod.lift (chainComplexMap (Subcomplex.homOfLE (inf_le_left : U ⊓ V ≤ U)) R)
      (-chainComplexMap (Subcomplex.homOfLE (inf_le_right : U ⊓ V ≤ V)) R))
    (biprod.desc (chainComplexMap U.ι R) (chainComplexMap V.ι R))
    (by simp [← Functor.map_comp])

/-- Mayer-Vietoris: split a complex `X` into two subcomplexes `U` and `V` that together cover it.
Then the row of chains `0 → C(U ∩ V) → C(U) ⊕ C(V) → C(X) → 0` is exact, and the long row
`H_k(U ∩ V) → H_k(U) ⊕ H_k(V) → H_k(X) → H_{k-1}(U ∩ V) → ⋯`, with `i_*`, `j_*` and the
connecting map `∂_*`, is exact at every spot: at the pieces, at the whole, and at the overlap. -/
theorem mayer_vietoris_sequence_exact {X : SSet.{w}} (U V : X.Subcomplex)
    (hcover : U ⊔ V = ⊤) (R : 𝒜) :
    ∃ hS : (mayerVietorisChains U V R).ShortExact,
      (∀ k : ℕ, (ShortComplex.mk
          (HomologicalComplex.homologyMap (mayerVietorisChains U V R).f k)
          (HomologicalComplex.homologyMap (mayerVietorisChains U V R).g k)
          (by rw [← HomologicalComplex.homologyMap_comp, ShortComplex.zero,
            HomologicalComplex.homologyMap_zero])).Exact) ∧
      (∀ (k m : ℕ) (h : m + 1 = k),
        (ShortComplex.mk _ _ (hS.comp_δ k m h)).Exact) ∧
      (∀ (k m : ℕ) (h : m + 1 = k),
        (ShortComplex.mk _ _ (hS.δ_comp k m h)).Exact) := by
  have hP := mv_isPushout_chain (mv_isPushout_sSet U V hcover) R
  have hS : (mayerVietorisChains U V R).ShortExact := by
    have hmono : Mono (chainComplexMap (Subcomplex.homOfLE (inf_le_left : U ⊓ V ≤ U)) R) :=
      inferInstanceAs (Mono (SSet.chainComplexMap
        (SSetPair.of (Subcomplex.homOfLE (inf_le_left : U ⊓ V ≤ U))).hom R))
    have : Mono (mayerVietorisChains U V R).f :=
      @mono_of_mono_fac _ _ _ _ _ _ _ _ hmono (biprod.lift_fst
        (chainComplexMap (Subcomplex.homOfLE (inf_le_left : U ⊓ V ≤ U)) R)
        (-chainComplexMap (Subcomplex.homOfLE (inf_le_right : U ⊓ V ≤ V)) R))
    exact { exact := hP.exact_shortComplex, epi_g := hP.epi_shortComplex_g }
  exact ⟨hS, fun k => hS.homology_exact₂ k, fun k m h => hS.homology_exact₃ k m h,
    fun k m h => hS.homology_exact₁ k m h⟩

/-- Excision for subcomplexes: when `X = U ∪ V`, the inclusion of pairs `(U, U ∩ V) → (X, V)`
induces an isomorphism `H_k(U, U ∩ V) ≅ H_k(X, V)` in every degree `k`. -/
theorem excision_for_subcomplexes {X : SSet.{w}} (U V : X.Subcomplex)
    (hcover : U ⊔ V = ⊤) (R : 𝒜) (k : ℕ) :
    IsIso (SSetPair.homologyMap
      (SSetPair.homMk (X := SSetPair.of (Subcomplex.homOfLE (inf_le_left : U ⊓ V ≤ U)))
        (Y := V.pair) (Subcomplex.homOfLE (inf_le_right : U ⊓ V ≤ V)) U.ι rfl) R k) := by
  have hP := mv_isPushout_chain (mv_isPushout_sSet U V hcover) R
  have : IsIso (SSetPair.chainComplexMap
      (SSetPair.homMk (X := SSetPair.of (Subcomplex.homOfLE (inf_le_left : U ⊓ V ≤ U)))
        (Y := V.pair) (Subcomplex.homOfLE (inf_le_right : U ⊓ V ≤ V)) U.ι rfl) R) := by
    refine mv_isIso_of_isPushout hP
      (SSetPair.isColimitCokernelCoforkChainComplex
        (SSetPair.of (Subcomplex.homOfLE (inf_le_left : U ⊓ V ≤ U))) R)
      (V.pair.isColimitCokernelCoforkChainComplex R) _ ?_
    exact (((SSetPair.chainComplexFunctorπ 𝒜).app R).naturality _).symm
  infer_instance

end MayerVietoris

/-- Exactness turns into counting: at an exact spot `P → Q → R` of vector spaces over a field
(image of the first map equals kernel of the second), `dim Q = rank f + rank g`. -/
theorem finrank_eq_rank_in_add_rank_out {K P Q R : Type*} [Field K]
    [AddCommGroup P] [Module K P] [AddCommGroup Q] [Module K Q] [AddCommGroup R] [Module K R]
    [FiniteDimensional K Q] (f : P →ₗ[K] Q) (g : Q →ₗ[K] R)
    (hexact : LinearMap.range f = LinearMap.ker g) :
    Module.finrank K Q =
      Module.finrank K (LinearMap.range f) + Module.finrank K (LinearMap.range g) := by
  rw [hexact, add_comm]
  exact (LinearMap.finrank_range_add_finrank_ker g).symm

-- Euler checks on the small sphere: caps, band, whole, and χ(U) + χ(V) - χ(U ∩ V) = χ(X)
example : (7 : ℤ) - 15 + 9 = 1 ∧ (6 : ℤ) - 12 + 6 = 0 ∧ (8 : ℤ) - 18 + 12 = 2 := by norm_num
example : (1 : ℤ) + 1 - 0 = 2 ∧ (9 : ℕ) + 9 - 6 = 12 := by norm_num
-- Euler checks on the dome: caps 36, 95, 60; band 30, 70, 40; whole 42, 120, 80
example : (36 : ℤ) - 95 + 60 = 1 ∧ (30 : ℤ) - 70 + 40 = 0 ∧ (42 : ℤ) - 120 + 80 = 2 := by norm_num
-- the counting formula on the small sphere, k = 0, 1, 2
example : ((1 : ℤ) + 1 - 1) + 0 = 1 ∧ ((0 : ℤ) + 0 - 0) + (1 - 1) = 0 ∧
    ((0 : ℤ) + 0 - 0) + (1 - 0) = 1 := by norm_num
-- Betti cross-check 1 - 0 + 1 = 2; ranks at exact spots: 1 = 1 + 0 and 2 = 1 + 1
example : (1 : ℤ) - 0 + 1 = 2 ∧ (1 : ℕ) = 1 + 0 ∧ (2 : ℕ) = 1 + 1 := by norm_num
-- mistake 1, Betti numbers by inclusion-exclusion: 1, -1, 0 instead of 1, 0, 1
example : ((1 : ℤ) + 1 - 1, (0 : ℤ) + 0 - 1, (0 : ℤ) + 0 - 0) = (1, -1, 0) := by norm_num
-- dome with one north panel out: β₂ = (0 + 0 - 0) + (1 - 1) = 0; relative Euler 0 - 0 + 1 = 2 - 1
example : ((0 : ℤ) + 0 - 0) + (1 - 1) = 0 ∧ (0 : ℤ) - 0 + 1 = 2 - 1 := by norm_num

#print axioms mayer_vietoris_sequence_exact
#print axioms excision_for_subcomplexes
#print axioms finrank_eq_rank_in_add_rank_out
#print axioms mv_isPushout_sSet
#print axioms mv_isPushout_X
#print axioms mv_isPushout_chain
#print axioms mv_isIso_of_isPushout
