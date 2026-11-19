-- Birational equivalence: two varieties over a field k are birational exactly when their function fields match over k, and the circle is birational to the line.
import Mathlib.AlgebraicGeometry.Birational.Birational
import Mathlib.AlgebraicGeometry.FunctionField
import Mathlib.AlgebraicGeometry.Morphisms.FiniteType
import Mathlib.FieldTheory.RatFunc.AsPolynomial
import Mathlib.RingTheory.Localization.FractionRing
import Mathlib.RingTheory.MvPolynomial.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.NormNum
import Mathlib.RingTheory.Algebraic.Integral
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.LinearCombination

open AlgebraicGeometry CategoryTheory

universe u

/-- The constants of `k` inside the function field `k(X)` of a variety `X` over `k`:
a constant on `Spec k` pulls back to a global function on `X`, then to a fraction on `X`. -/
noncomputable def constantsToFunctionField {k : Type u} [Field k] {X : Scheme.{u}}
    [IsIntegral X] (sX : X ⟶ Spec (CommRingCat.of k)) : k →+* X.functionField :=
  haveI : Nonempty (⊤ : X.Opens) := ⟨⟨Classical.arbitrary X, trivial⟩⟩
  ((Scheme.ΓSpecIso (CommRingCat.of k)).inv ≫ sX.appTop ≫ X.germToFunctionField ⊤).hom

/-- The map of function fields `K(B) → K(A)` along a morphism `f : A ⟶ B`
sending the generic point to the generic point. -/
noncomputable def functionFieldMap {A B : Scheme.{u}} [IrreducibleSpace A] [IrreducibleSpace B]
    (f : A ⟶ B) (h : f (genericPoint A) = genericPoint B) : B.functionField ⟶ A.functionField :=
  B.presheaf.stalkSpecializes (Inseparable.of_eq h).specializes ≫ f.stalkMap (genericPoint A)

theorem functionFieldMap_constants {k : Type u} [Field k] {A B : Scheme.{u}}
    [IsIntegral A] [IsIntegral B] (f : A ⟶ B) (h : f (genericPoint A) = genericPoint B)
    (s : B ⟶ Spec (CommRingCat.of k)) (c : k) :
    functionFieldMap f h (constantsToFunctionField s c) = constantsToFunctionField (f ≫ s) c := by
  have : Nonempty (⊤ : A.Opens) := ⟨⟨Classical.arbitrary A, trivial⟩⟩
  have : Nonempty (⊤ : B.Opens) := ⟨⟨Classical.arbitrary B, trivial⟩⟩
  have key : B.germToFunctionField ⊤ ≫ B.presheaf.stalkSpecializes (Inseparable.of_eq h).specializes ≫
      f.stalkMap (genericPoint A) = f.appTop ≫ A.germToFunctionField ⊤ := by
    simp only [Scheme.germToFunctionField]
    rw [TopCat.Presheaf.germ_stalkSpecializes_assoc, Scheme.Hom.germ_stalkMap]
    rfl
  simp only [constantsToFunctionField, functionFieldMap, CommRingCat.hom_comp,
    RingHom.comp_apply, Scheme.Hom.comp_appTop]
  rw [← CommRingCat.comp_apply, ← CommRingCat.comp_apply, key]
  rfl

#print axioms functionFieldMap_constants

theorem functionFieldMap_isIso {A B : Scheme.{u}} [IrreducibleSpace A] [IrreducibleSpace B]
    (f : A ⟶ B) (h : f (genericPoint A) = genericPoint B) [IsOpenImmersion f] :
    IsIso (functionFieldMap f h) := by
  have key : ∀ (y : B) (h : y ⤳ genericPoint B), y = genericPoint B →
      IsIso (B.presheaf.stalkSpecializes h) := by
    rintro _ h rfl
    rw [TopCat.Presheaf.stalkSpecializes_refl]
    infer_instance
  have := key _ (Inseparable.of_eq h).specializes h
  unfold functionFieldMap
  infer_instance

#print axioms functionFieldMap_isIso

theorem fromSpecStalk_generic_comp {k : Type u} [Field k] {X : Scheme.{u}} [IsIntegral X]
    (sX : X ⟶ Spec (CommRingCat.of k)) :
    X.fromSpecStalk (genericPoint X) ≫ sX =
      Spec.map (CommRingCat.ofHom (constantsToFunctionField sX)) := by
  apply ext_of_isAffine
  rw [Scheme.Hom.comp_appTop, Scheme.fromSpecStalk_appTop,
    ← cancel_epi (Scheme.ΓSpecIso (CommRingCat.of k)).inv, ← Scheme.ΓSpecIso_inv_naturality]
  simp only [constantsToFunctionField, CommRingCat.ofHom_hom, Category.assoc]
  congr 3

#print axioms fromSpecStalk_generic_comp

theorem birational_forward {k : Type u} [Field k] {X Y : Scheme.{u}}
    (sX : X ⟶ Spec (CommRingCat.of k)) (sY : Y ⟶ Spec (CommRingCat.of k))
    [IsIntegral X] [IsIntegral Y] (H : Scheme.BirationalOver sX sY) :
      ∃ e : X.functionField ≃+* Y.functionField,
        ∀ c : k, e (constantsToFunctionField sX c) = constantsToFunctionField sY c := by
  obtain ⟨p, hp⟩ := H
  obtain ⟨x, hx⟩ := p.dense_source.nonempty
  obtain ⟨y, hy⟩ := p.dense_target.nonempty
  have : Nonempty p.source := ⟨⟨x, hx⟩⟩
  have : Nonempty p.target := ⟨⟨y, hy⟩⟩
  have hU := genericPoint_eq_of_isOpenImmersion p.source.ι
  have hV := genericPoint_eq_of_isOpenImmersion p.target.ι
  have hφ := genericPoint_eq_of_isOpenImmersion p.iso.hom
  have := functionFieldMap_isIso _ hU
  have := functionFieldMap_isIso _ hV
  have := functionFieldMap_isIso _ hφ
  refine ⟨(asIso (functionFieldMap _ hU) ≪≫ (asIso (functionFieldMap _ hφ)).symm ≪≫
    (asIso (functionFieldMap _ hV)).symm).commRingCatIsoToRingEquiv, fun c => ?_⟩
  have key : functionFieldMap _ hU (constantsToFunctionField sX c) =
      functionFieldMap _ hφ (functionFieldMap _ hV (constantsToFunctionField sY c)) := by
    rw [functionFieldMap_constants, functionFieldMap_constants, functionFieldMap_constants, hp]
  change (inv (functionFieldMap _ hV)) ((inv (functionFieldMap _ hφ))
    ((functionFieldMap _ hU) (constantsToFunctionField sX c))) = _
  rw [key]
  rw [← CommRingCat.comp_apply (functionFieldMap _ hφ), IsIso.hom_inv_id, CommRingCat.id_apply,
    ← CommRingCat.comp_apply, IsIso.hom_inv_id, CommRingCat.id_apply]

#print axioms birational_forward

theorem genericPoint_mem_of_dense {X : Scheme.{u}} [IrreducibleSpace X] (W : X.Opens)
    (hW : Dense (W : Set X)) : genericPoint X ∈ W := by
  obtain ⟨x, hx⟩ := hW.nonempty
  exact (genericPoint_specializes x).mem_open W.2 hx

#print axioms genericPoint_mem_of_dense

theorem partialMap_hom_genericPoint {X Y : Scheme.{u}} [IsIntegral X] [IsIntegral Y]
    (f : X.PartialMap Y) (hxf : genericPoint X ∈ f.domain)
    (α : Y.functionField ⟶ X.functionField)
    (hf : f.fromSpecStalkOfMem hxf = Spec.map α ≫ Y.fromSpecStalk (genericPoint Y)) :
    f.hom ⟨genericPoint X, hxf⟩ = genericPoint Y := by
  obtain ⟨pt, hpt⟩ : ∃ pt : Spec X.functionField,
      pt = IsLocalRing.closedPoint X.functionField := ⟨_, rfl⟩
  have h1 : (f.domain.fromSpecStalkOfMem _ hxf ≫ f.hom) pt =
      (Spec.map α ≫ Y.fromSpecStalk (genericPoint Y)) pt := by
    rw [← hf]; rfl
  have h2 : f.domain.fromSpecStalkOfMem _ hxf pt = ⟨genericPoint X, hxf⟩ := by
    apply Subtype.ext
    have e1 : (f.domain.fromSpecStalkOfMem _ hxf ≫ f.domain.ι) pt = X.fromSpecStalk _ pt := by
      rw [Scheme.Opens.fromSpecStalkOfMem_ι]
    rw [Scheme.Hom.comp_apply] at e1
    change f.domain.ι _ = genericPoint X
    rw [e1, hpt, Scheme.fromSpecStalk_closedPoint]
  have h3 : Spec.map α pt = IsLocalRing.closedPoint Y.functionField :=
    Subsingleton.elim (α := PrimeSpectrum Y.functionField) _ _
  rw [Scheme.Hom.comp_apply, Scheme.Hom.comp_apply, h2, h3, Scheme.fromSpecStalk_closedPoint] at h1
  exact h1

#print axioms partialMap_hom_genericPoint

theorem partialMap_leftInverse {X Y : Scheme.{u}} [IsIntegral X] [IsIntegral Y]
    (f : X.PartialMap Y) (g : Y.PartialMap X)
    (hxf : genericPoint X ∈ f.domain) (hyg : genericPoint Y ∈ g.domain)
    (α : Y.functionField ⟶ X.functionField) (β : X.functionField ⟶ Y.functionField)
    (hf : f.fromSpecStalkOfMem hxf = Spec.map α ≫ Y.fromSpecStalk (genericPoint Y))
    (hg : g.fromSpecStalkOfMem hyg = Spec.map β ≫ X.fromSpecStalk (genericPoint X))
    (hαβ : β ≫ α = 𝟙 _) :
    ∃ (W : X.Opens) (hW : W ≤ f.domain) (a : W.toScheme ⟶ g.domain.toScheme),
      genericPoint X ∈ W ∧ a ≫ g.domain.ι = X.homOfLE hW ≫ f.hom ∧ a ≫ g.hom = W.ι := by
  let D0 : X.Opens := f.domain.ι ''ᵁ (f.hom ⁻¹ᵁ g.domain)
  have hD0 : D0 ≤ f.domain := by
    rintro _ ⟨y, -, rfl⟩
    exact y.2
  have hrange : Set.range (X.homOfLE hD0 ≫ f.hom) ⊆ Set.range g.domain.ι := by
    rw [Scheme.Opens.range_ι]
    rintro _ ⟨z, rfl⟩
    obtain ⟨y, hy, hyz⟩ := z.2
    have : X.homOfLE hD0 z = y := Subtype.ext ((Scheme.homOfLE_apply hD0 z).trans hyz.symm)
    rw [Scheme.Hom.comp_apply, this]
    exact hy
  let F0 := IsOpenImmersion.lift g.domain.ι (X.homOfLE hD0 ≫ f.hom) hrange
  have hF0 : F0 ≫ g.domain.ι = X.homOfLE hD0 ≫ f.hom := IsOpenImmersion.lift_fac _ _ _
  have hη : genericPoint X ∈ D0 := by
    refine ⟨⟨_, hxf⟩, ?_, rfl⟩
    change f.hom ⟨_, hxf⟩ ∈ g.domain
    rw [partialMap_hom_genericPoint f hxf α hf]
    exact hyg
  have hdense : Dense (D0 : Set X) := D0.2.dense ⟨_, hη⟩
  have heq := Scheme.PartialMap.equiv_of_fromSpecStalkOfMem_eq (x := genericPoint X)
    ⟨D0, hdense, F0 ≫ g.hom⟩ ⟨D0, hdense, D0.ι⟩ hη hη ?_
  · obtain ⟨W, hW, hWl, hWr, e⟩ := heq
    refine ⟨W, hWl.trans hD0, X.homOfLE hWl ≫ F0, genericPoint_mem_of_dense W hW, ?_, ?_⟩
    · rw [Category.assoc, hF0, ← Category.assoc, Scheme.homOfLE_homOfLE]
    · simp only [Scheme.PartialMap.restrict_hom] at e
      rw [Category.assoc, e, Scheme.homOfLE_ι]
  · change D0.fromSpecStalkOfMem _ hη ≫ F0 ≫ g.hom = D0.fromSpecStalkOfMem _ hη ≫ D0.ι
    have h0 : D0.fromSpecStalkOfMem _ hη ≫ X.homOfLE hD0 = f.domain.fromSpecStalkOfMem _ hxf := by
      rw [← cancel_mono f.domain.ι, Category.assoc, Scheme.homOfLE_ι,
        Scheme.Opens.fromSpecStalkOfMem_ι, Scheme.Opens.fromSpecStalkOfMem_ι]
    have h1 : D0.fromSpecStalkOfMem _ hη ≫ F0 = Spec.map α ≫ g.domain.fromSpecStalkOfMem _ hyg := by
      rw [← cancel_mono g.domain.ι, Category.assoc, hF0, ← Category.assoc, h0, Category.assoc,
        Scheme.Opens.fromSpecStalkOfMem_ι]
      exact hf
    rw [← Category.assoc, h1, Category.assoc]
    change Spec.map α ≫ g.fromSpecStalkOfMem hyg = _
    rw [hg, ← Category.assoc, ← Spec.map_comp, hαβ, Spec.map_id, Category.id_comp,
      Scheme.Opens.fromSpecStalkOfMem_ι]

#print axioms partialMap_leftInverse

/-- The range condition for building the isomorphism: `f` maps `W₁ ∩ f⁻¹(W₂)` into
`W₂ ∩ g⁻¹(W₁)`. -/
theorem partialMap_range_aux {X Y : Scheme.{u}}
    (f : X.PartialMap Y) (g : Y.PartialMap X) (W1 : X.Opens) (W2 : Y.Opens)
    (hW1 : W1 ≤ f.domain) (a1 : W1.toScheme ⟶ g.domain.toScheme)
    (ha1 : a1 ≫ g.domain.ι = X.homOfLE hW1 ≫ f.hom) (ha1' : a1 ≫ g.hom = W1.ι)
    (hUf : W1 ⊓ f.domain.ι ''ᵁ (f.hom ⁻¹ᵁ W2) ≤ f.domain) :
    Set.range (X.homOfLE hUf ≫ f.hom) ⊆
      Set.range (W2 ⊓ g.domain.ι ''ᵁ (g.hom ⁻¹ᵁ W1)).ι := by
  have hUW1 : W1 ⊓ f.domain.ι ''ᵁ (f.hom ⁻¹ᵁ W2) ≤ W1 := inf_le_left
  rw [Scheme.Opens.range_ι]
  rintro _ ⟨z, rfl⟩
  refine ⟨?_, ?_⟩
  · obtain ⟨y, hy, hyz⟩ := z.2.2
    have : X.homOfLE hUf z = y := Subtype.ext ((Scheme.homOfLE_apply hUf z).trans hyz.symm)
    rw [Scheme.Hom.comp_apply, this]
    exact hy
  · refine ⟨a1 (X.homOfLE hUW1 z), ?_, ?_⟩
    · change g.hom (a1 (X.homOfLE hUW1 z)) ∈ W1
      rw [← Scheme.Hom.comp_apply, ha1']
      exact (X.homOfLE hUW1 z).2
    · change g.domain.ι (a1 (X.homOfLE hUW1 z)) = _
      rw [← Scheme.Hom.comp_apply, ha1, ← Scheme.Hom.comp_apply, ← Category.assoc,
        Scheme.homOfLE_homOfLE]

#print axioms partialMap_range_aux

theorem birational_backward {k : Type u} [Field k] {X Y : Scheme.{u}}
    (sX : X ⟶ Spec (CommRingCat.of k)) (sY : Y ⟶ Spec (CommRingCat.of k))
    [IsIntegral X] [IsIntegral Y] [LocallyOfFiniteType sX] [LocallyOfFiniteType sY]
    (e : X.functionField ≃+* Y.functionField)
    (he : ∀ c : k, e (constantsToFunctionField sX c) = constantsToFunctionField sY c) :
    Scheme.BirationalOver sX sY := by
  let α : Y.functionField ⟶ X.functionField := CommRingCat.ofHom e.symm.toRingHom
  let β : X.functionField ⟶ Y.functionField := CommRingCat.ofHom e.toRingHom
  have hαβ : β ≫ α = 𝟙 _ := by ext x; exact e.symm_apply_apply x
  have hβα : α ≫ β = 𝟙 _ := by ext x; exact e.apply_symm_apply x
  have hΦ : (Spec.map α ≫ Y.fromSpecStalk (genericPoint Y)) ≫ sY =
      X.fromSpecStalk (genericPoint X) ≫ sX := by
    rw [Category.assoc, fromSpecStalk_generic_comp, fromSpecStalk_generic_comp, ← Spec.map_comp]
    congr 1
    ext c
    exact e.symm_apply_eq.mpr (he c).symm
  have hΨ : (Spec.map β ≫ X.fromSpecStalk (genericPoint X)) ≫ sX =
      Y.fromSpecStalk (genericPoint Y) ≫ sY := by
    rw [Category.assoc, fromSpecStalk_generic_comp, fromSpecStalk_generic_comp, ← Spec.map_comp]
    congr 1
    ext c
    exact he c
  set f := Scheme.PartialMap.ofFromSpecStalk sX sY _ hΦ
  set g := Scheme.PartialMap.ofFromSpecStalk sY sX _ hΨ
  have hxf : genericPoint X ∈ f.domain := Scheme.PartialMap.mem_domain_ofFromSpecStalk sX sY _ hΦ
  have hyg : genericPoint Y ∈ g.domain := Scheme.PartialMap.mem_domain_ofFromSpecStalk sY sX _ hΨ
  have hf : f.fromSpecStalkOfMem hxf = Spec.map α ≫ Y.fromSpecStalk (genericPoint Y) :=
    Scheme.PartialMap.fromSpecStalkOfMem_ofFromSpecStalk sX sY _ hΦ
  have hg : g.fromSpecStalkOfMem hyg = Spec.map β ≫ X.fromSpecStalk (genericPoint X) :=
    Scheme.PartialMap.fromSpecStalkOfMem_ofFromSpecStalk sY sX _ hΨ
  have hfo : f.hom ≫ sY = f.domain.ι ≫ sX := Scheme.PartialMap.ofFromSpecStalk_comp sX sY _ hΦ
  obtain ⟨W1, hW1, a1, hη1, ha1, ha1'⟩ := partialMap_leftInverse f g hxf hyg α β hf hg hαβ
  obtain ⟨W2, hW2, a2, hη2, ha2, ha2'⟩ := partialMap_leftInverse g f hyg hxf β α hg hf hβα
  let U : X.Opens := W1 ⊓ f.domain.ι ''ᵁ (f.hom ⁻¹ᵁ W2)
  let V : Y.Opens := W2 ⊓ g.domain.ι ''ᵁ (g.hom ⁻¹ᵁ W1)
  have hUf : U ≤ f.domain := fun x hx => hW1 hx.1
  have hVg : V ≤ g.domain := fun y hy => hW2 hy.1
  have hUW1 : U ≤ W1 := inf_le_left
  have hVW2 : V ≤ W2 := inf_le_left
  let φ : U.toScheme ⟶ V.toScheme := IsOpenImmersion.lift V.ι (X.homOfLE hUf ≫ f.hom)
    (partialMap_range_aux f g W1 W2 hW1 a1 ha1 ha1' hUf)
  let ψ : V.toScheme ⟶ U.toScheme := IsOpenImmersion.lift U.ι (Y.homOfLE hVg ≫ g.hom)
    (partialMap_range_aux g f W2 W1 hW2 a2 ha2 ha2' hVg)
  have hφ : φ ≫ V.ι = X.homOfLE hUf ≫ f.hom := IsOpenImmersion.lift_fac _ _ _
  have hψ : ψ ≫ U.ι = Y.homOfLE hVg ≫ g.hom := IsOpenImmersion.lift_fac _ _ _
  have hφ' : φ ≫ Y.homOfLE hVg = X.homOfLE hUW1 ≫ a1 := by
    rw [← cancel_mono g.domain.ι, Category.assoc, Scheme.homOfLE_ι, hφ, Category.assoc, ha1,
      ← Category.assoc, Scheme.homOfLE_homOfLE]
  have hψ' : ψ ≫ X.homOfLE hUf = Y.homOfLE hVW2 ≫ a2 := by
    rw [← cancel_mono f.domain.ι, Category.assoc, Scheme.homOfLE_ι, hψ, Category.assoc, ha2,
      ← Category.assoc, Scheme.homOfLE_homOfLE]
  have hηU : genericPoint X ∈ U := by
    refine ⟨hη1, ⟨_, hxf⟩, ?_, rfl⟩
    change f.hom ⟨_, hxf⟩ ∈ W2
    rw [partialMap_hom_genericPoint f hxf α hf]
    exact hη2
  have hηV : genericPoint Y ∈ V := by
    refine ⟨hη2, ⟨_, hyg⟩, ?_, rfl⟩
    change g.hom ⟨_, hyg⟩ ∈ W1
    rw [partialMap_hom_genericPoint g hyg β hg]
    exact hη1
  refine ⟨⟨U, U.2.dense ⟨_, hηU⟩, V, V.2.dense ⟨_, hηV⟩,
    { hom := φ, inv := ψ, hom_inv_id := ?_, inv_hom_id := ?_ }⟩, ?_⟩
  · rw [← cancel_mono U.ι, Category.assoc, hψ, ← Category.assoc, hφ', Category.assoc, ha1',
      Scheme.homOfLE_ι, Category.id_comp]
  · rw [← cancel_mono V.ι, Category.assoc, hφ, ← Category.assoc, hψ', Category.assoc, ha2',
      Scheme.homOfLE_ι, Category.id_comp]
  · change φ ≫ V.ι ≫ sY = U.ι ≫ sX
    rw [← Category.assoc, hφ, Category.assoc, hfo, ← Category.assoc, Scheme.homOfLE_ι]

#print axioms birational_backward

/-- Two irreducible varieties `X` and `Y` over a field `k` are birational over `k`
(dense open pieces of them match by an isomorphism over `k`, that is, inverse rational maps)
exactly when their function fields `k(X)` and `k(Y)` are the same field, matched by an
isomorphism that leaves every constant of `k` alone. -/
theorem birational_iff_function_fields_isomorphic {k : Type u} [Field k] {X Y : Scheme.{u}}
    (sX : X ⟶ Spec (CommRingCat.of k)) (sY : Y ⟶ Spec (CommRingCat.of k))
    [IsIntegral X] [IsIntegral Y] [LocallyOfFiniteType sX] [LocallyOfFiniteType sY] :
    Scheme.BirationalOver sX sY ↔
      ∃ e : X.functionField ≃+* Y.functionField,
        ∀ c : k, e (constantsToFunctionField sX c) = constantsToFunctionField sY c :=
  ⟨birational_forward sX sY, fun ⟨e, he⟩ => birational_backward sX sY e he⟩

/-- The circle's equation `x^2 + y^2 - 1`, with `x = X 0` and `y = X 1`. -/
noncomputable abbrev circleIdeal (k : Type u) [Field k] : Ideal (MvPolynomial (Fin 2) k) :=
  Ideal.span {MvPolynomial.X 0 ^ 2 + MvPolynomial.X 1 ^ 2 - 1}

/-- The coordinate ring `k[C]`: polynomials in `x, y`, equal when they agree on the circle. -/
abbrev circleRing (k : Type u) [Field k] := MvPolynomial (Fin 2) k ⧸ circleIdeal k

/-- The function field `k(C)`: fractions of polynomial functions on the circle. -/
abbrev circleFunctionField (k : Type u) [Field k] := FractionRing (circleRing k)

theorem ratFunc_one_add_X_sq_ne_zero (k : Type u) [Field k] :
    (1 + RatFunc.X ^ 2 : RatFunc k) ≠ 0 := by
  rw [← RatFunc.algebraMap_X, ← map_pow, ← map_one (algebraMap (Polynomial k) (RatFunc k)),
    ← map_add]
  refine (map_ne_zero_iff _ (IsFractionRing.injective (Polynomial k) (RatFunc k))).mpr ?_
  intro h
  have := congrArg (Polynomial.coeff · 0) h
  simp at this

#print axioms ratFunc_one_add_X_sq_ne_zero

/-- Every function on the circle is `A(x) + B(x) y`. -/
theorem circleRing_normal_form (k : Type u) [Field k] (r : circleRing k) :
    ∃ A B : Polynomial k, r = Polynomial.aeval (Ideal.Quotient.mk (circleIdeal k) (MvPolynomial.X 0)) A +
      Polynomial.aeval (Ideal.Quotient.mk (circleIdeal k) (MvPolynomial.X 0)) B *
        Ideal.Quotient.mk (circleIdeal k) (MvPolynomial.X 1) := by
  obtain ⟨p, rfl⟩ := Ideal.Quotient.mk_surjective r
  set x := Ideal.Quotient.mk (circleIdeal k) (MvPolynomial.X 0)
  set y := Ideal.Quotient.mk (circleIdeal k) (MvPolynomial.X 1)
  have hy : y ^ 2 = 1 - x ^ 2 := by
    have : Ideal.Quotient.mk (circleIdeal k) (MvPolynomial.X 0 ^ 2 + MvPolynomial.X 1 ^ 2 - 1) = 0 :=
      Ideal.Quotient.eq_zero_iff_mem.mpr (Ideal.subset_span rfl)
    simp only [map_sub, map_add, map_pow, map_one] at this
    linear_combination this
  induction p using MvPolynomial.induction_on with
  | C a => exact ⟨Polynomial.C a, 0, by simp; rfl⟩
  | add p q hp hq =>
    obtain ⟨A, B, hAB⟩ := hp
    obtain ⟨C, D, hCD⟩ := hq
    exact ⟨A + C, B + D, by rw [map_add, hAB, hCD]; simp only [map_add]; ring⟩
  | mul_X p i hp =>
    obtain ⟨A, B, hAB⟩ := hp
    obtain rfl | rfl : i = 0 ∨ i = 1 := by fin_cases i <;> simp
    · refine ⟨A * Polynomial.X, B * Polynomial.X, ?_⟩
      rw [map_mul, hAB]; simp only [map_mul, Polynomial.aeval_X]; ring
    · refine ⟨B * (1 - Polynomial.X ^ 2), A, ?_⟩
      rw [map_mul, hAB]
      simp only [map_mul, map_sub, map_one, map_pow, Polynomial.aeval_X]
      rw [← hy]; ring

#print axioms circleRing_normal_form

noncomputable def circleToRatFunc (k : Type u) [Field k] : circleRing k →ₐ[k] RatFunc k :=
  Ideal.Quotient.liftₐ (circleIdeal k)
    (MvPolynomial.aeval ![(1 - RatFunc.X ^ 2) / (1 + RatFunc.X ^ 2),
      2 * RatFunc.X / (1 + RatFunc.X ^ 2)]) (by
      intro a ha
      obtain ⟨c, rfl⟩ := Ideal.mem_span_singleton'.mp ha
      have hne := ratFunc_one_add_X_sq_ne_zero k
      simp only [map_mul, map_sub, map_add, map_pow, MvPolynomial.aeval_X, map_one,
        Matrix.cons_val_zero, Matrix.cons_val_one]
      convert mul_zero _
      field_simp
      ring)

theorem circleToRatFunc_mk (k : Type u) [Field k] (p : MvPolynomial (Fin 2) k) :
    circleToRatFunc k (Ideal.Quotient.mk (circleIdeal k) p) =
      MvPolynomial.aeval ![(1 - RatFunc.X ^ 2) / (1 + RatFunc.X ^ 2),
        2 * RatFunc.X / (1 + RatFunc.X ^ 2)] p :=
  Ideal.Quotient.lift_mk (circleIdeal k) _ _

#print axioms circleToRatFunc_mk

theorem circleToRatFunc_x (k : Type u) [Field k] :
    circleToRatFunc k (Ideal.Quotient.mk (circleIdeal k) (MvPolynomial.X 0)) =
      (1 - RatFunc.X ^ 2) / (1 + RatFunc.X ^ 2) := by
  rw [circleToRatFunc_mk]; simp

#print axioms circleToRatFunc_x

theorem circleToRatFunc_y (k : Type u) [Field k] :
    circleToRatFunc k (Ideal.Quotient.mk (circleIdeal k) (MvPolynomial.X 1)) =
      2 * RatFunc.X / (1 + RatFunc.X ^ 2) := by
  rw [circleToRatFunc_mk]; simp

#print axioms circleToRatFunc_y

theorem ratFunc_transcendental_neg_X (k : Type u) [Field k] :
    Transcendental k (-RatFunc.X : RatFunc k) := by
  intro h
  exact RatFunc.transcendental_X (K := k) (by simpa using h.neg)

#print axioms ratFunc_transcendental_neg_X

theorem ratFunc_transcendental_u (k : Type u) [Field k] (h2 : (2 : k) ≠ 0) :
    Transcendental k ((1 - RatFunc.X ^ 2) / (1 + RatFunc.X ^ 2) : RatFunc k) := by
  intro h
  have hne := ratFunc_one_add_X_sq_ne_zero k
  have h2' : (2 : RatFunc k) ≠ 0 := by
    have : (algebraMap k (RatFunc k)) 2 ≠ 0 :=
      (map_ne_zero_iff _ (algebraMap k (RatFunc k)).injective).mpr h2
    rwa [map_ofNat] at this
  have e : (1 - RatFunc.X ^ 2) / (1 + RatFunc.X ^ 2) + 1 = (2 : RatFunc k) / (1 + RatFunc.X ^ 2) := by
    field_simp; ring
  have h1 : IsAlgebraic k ((2 : RatFunc k) / (1 + RatFunc.X ^ 2)) := by
    rw [← e]; exact h.add isAlgebraic_one
  have h3 : IsAlgebraic k ((1 + RatFunc.X ^ 2 : RatFunc k)) := by
    have := (h1.inv).mul (isAlgebraic_algebraMap (2 : k))
    convert this using 1
    simp only [map_ofNat]
    field_simp
  have h4 : IsAlgebraic k ((RatFunc.X : RatFunc k) ^ 2) := by
    simpa using h3.sub (isAlgebraic_one (R := k) (A := RatFunc k))
  exact RatFunc.transcendental_X (K := k) (h4.of_pow two_pos)

#print axioms ratFunc_transcendental_u

theorem ratFuncNeg_aux (k : Type u) [Field k] :
    nonZeroDivisors (Polynomial k) ≤
      (nonZeroDivisors (RatFunc k)).comap (Polynomial.aeval (-RatFunc.X : RatFunc k)) := by
  intro p hp
  rw [Submonoid.mem_comap, mem_nonZeroDivisors_iff_ne_zero]
  exact fun h0 => ratFunc_transcendental_neg_X k ⟨p, nonZeroDivisors.ne_zero hp, h0⟩

#print axioms ratFuncNeg_aux

/-- The reflection `t ↦ -t` of `k(t)`. -/
noncomputable def ratFuncNeg (k : Type u) [Field k] : RatFunc k →ₐ[k] RatFunc k :=
  RatFunc.liftAlgHom (Polynomial.aeval (-RatFunc.X : RatFunc k)) (ratFuncNeg_aux k)

theorem ratFuncNeg_X (k : Type u) [Field k] : ratFuncNeg k RatFunc.X = -RatFunc.X := by
  have := RatFunc.liftAlgHom_apply_div (S := k) (Polynomial.aeval (-RatFunc.X : RatFunc k))
    (ratFuncNeg_aux k) Polynomial.X 1
  simp only [RatFunc.algebraMap_X, map_one, div_one, Polynomial.aeval_X] at this
  exact this

#print axioms ratFuncNeg_X

theorem circleToRatFunc_injective (k : Type u) [Field k] (h2 : (2 : k) ≠ 0) :
    Function.Injective (circleToRatFunc k) := by
  rw [injective_iff_map_eq_zero]
  intro r hr
  obtain ⟨A, B, rfl⟩ := circleRing_normal_form k r
  rw [map_add, map_mul, ← Polynomial.aeval_algHom_apply, ← Polynomial.aeval_algHom_apply,
    circleToRatFunc_x, circleToRatFunc_y] at hr
  have hne := ratFunc_one_add_X_sq_ne_zero k
  have h2' : (2 : RatFunc k) ≠ 0 := by
    have : (algebraMap k (RatFunc k)) 2 ≠ 0 :=
      (map_ne_zero_iff _ (algebraMap k (RatFunc k)).injective).mpr h2
    rwa [map_ofNat] at this
  have hXne : (RatFunc.X : RatFunc k) ≠ 0 := RatFunc.X_ne_zero
  have hσu : ratFuncNeg k ((1 - RatFunc.X ^ 2) / (1 + RatFunc.X ^ 2)) =
      (1 - RatFunc.X ^ 2) / (1 + RatFunc.X ^ 2) := by
    simp [map_div₀, ratFuncNeg_X]
  have hσv : ratFuncNeg k (2 * RatFunc.X / (1 + RatFunc.X ^ 2)) =
      -(2 * RatFunc.X / (1 + RatFunc.X ^ 2)) := by
    simp [map_div₀, ratFuncNeg_X, neg_div, map_ofNat]
  have hr' := congrArg (ratFuncNeg k) hr
  rw [map_add, map_mul, ← Polynomial.aeval_algHom_apply, ← Polynomial.aeval_algHom_apply,
    hσu, hσv, map_zero] at hr'
  set a := Polynomial.aeval ((1 - RatFunc.X ^ 2) / (1 + RatFunc.X ^ 2) : RatFunc k) A
  set b := Polynomial.aeval ((1 - RatFunc.X ^ 2) / (1 + RatFunc.X ^ 2) : RatFunc k) B
  have ha : a = 0 := by
    have : 2 * a = 0 := by linear_combination hr + hr'
    simpa [h2'] using this
  have hv : (2 * RatFunc.X / (1 + RatFunc.X ^ 2) : RatFunc k) ≠ 0 :=
    div_ne_zero (mul_ne_zero h2' hXne) hne
  have hb : b = 0 := by
    rw [ha, zero_add] at hr
    exact (mul_eq_zero.mp hr).resolve_right hv
  have hA : A = 0 := by
    by_contra hA; exact ratFunc_transcendental_u k h2 ⟨A, hA, ha⟩
  have hB : B = 0 := by
    by_contra hB; exact ratFunc_transcendental_u k h2 ⟨B, hB, hb⟩
  simp [hA, hB]

#print axioms circleToRatFunc_injective

/-- The circle `x^2 + y^2 = 1` over a field `k` in which `2 ≠ 0` has the function field
`k(t)` of the line, with `t = y/(x + 1)`: there is an isomorphism over `k` from the fractions
of polynomial functions on the circle to the rational functions in one letter `t`, whose
inverse sends `t` to the fraction `y/(x + 1)`, that is, `t · (x + 1) = y`. -/
theorem circle_function_field_eq_rational_functions {k : Type u} [Field k] (h2 : (2 : k) ≠ 0) :
    ∃ e : circleFunctionField k ≃ₐ[k] RatFunc k,
      e.symm RatFunc.X * algebraMap (circleRing k) (circleFunctionField k)
          (Ideal.Quotient.mk (circleIdeal k) (MvPolynomial.X 0 + 1)) =
        algebraMap (circleRing k) (circleFunctionField k)
          (Ideal.Quotient.mk (circleIdeal k) (MvPolynomial.X 1)) := by
  have hinj := circleToRatFunc_injective k h2
  have : IsDomain (circleRing k) := hinj.isDomain (circleToRatFunc k).toRingHom
  let e0 : circleFunctionField k →ₐ[k] RatFunc k :=
    IsFractionRing.liftAlgHom (A := circleRing k) (K := circleFunctionField k) hinj
  have he0 : ∀ r, e0 (algebraMap (circleRing k) (circleFunctionField k) r) =
      circleToRatFunc k r := fun r => IsFractionRing.lift_algebraMap hinj r
  have hne := ratFunc_one_add_X_sq_ne_zero k
  have h2' : (2 : RatFunc k) ≠ 0 := by
    have : (algebraMap k (RatFunc k)) 2 ≠ 0 :=
      (map_ne_zero_iff _ (algebraMap k (RatFunc k)).injective).mpr h2
    rwa [map_ofNat] at this
  set w : circleFunctionField k :=
    algebraMap (circleRing k) (circleFunctionField k)
        (Ideal.Quotient.mk (circleIdeal k) (MvPolynomial.X 1)) /
      algebraMap (circleRing k) (circleFunctionField k)
        (Ideal.Quotient.mk (circleIdeal k) (MvPolynomial.X 0 + 1))
  have hw : e0 w = RatFunc.X := by
    rw [map_div₀, he0, he0, circleToRatFunc_mk, circleToRatFunc_mk]
    simp only [map_add, MvPolynomial.aeval_X, map_one, Matrix.cons_val_zero, Matrix.cons_val_one]
    have hu1 : (1 - RatFunc.X ^ 2) / (1 + RatFunc.X ^ 2) + 1 = (2 : RatFunc k) / (1 + RatFunc.X ^ 2) := by
      field_simp; ring
    rw [hu1, div_div_div_cancel_right₀ hne, mul_div_cancel_left₀ _ h2']
  have key : ∀ p : Polynomial k,
      algebraMap (Polynomial k) (RatFunc k) p = e0 (Polynomial.aeval w p) := by
    intro p
    rw [← Polynomial.aeval_algHom_apply, hw, ← RatFunc.algebraMap_X,
      Polynomial.aeval_algebraMap_apply, Polynomial.aeval_X_left_apply]
  have hsurj : Function.Surjective e0 := by
    intro f
    obtain ⟨p, q, -, rfl⟩ := IsFractionRing.div_surjective (A := Polynomial k) f
    exact ⟨Polynomial.aeval w p / Polynomial.aeval w q, by rw [map_div₀, ← key, ← key]⟩
  let e := AlgEquiv.ofBijective e0 ⟨e0.toRingHom.injective, hsurj⟩
  refine ⟨e, ?_⟩
  apply e.injective
  rw [map_mul, AlgEquiv.apply_symm_apply]
  change RatFunc.X * e0 _ = e0 _
  rw [he0, he0, circleToRatFunc_mk, circleToRatFunc_mk]
  simp only [map_add, MvPolynomial.aeval_X, map_one, Matrix.cons_val_zero, Matrix.cons_val_one]
  field_simp
  ring

/-- Stereographic projection from `(-1, 0)` matches the circle without `(-1, 0)` one to one
with the heights `t` where `1 + t^2 ≠ 0`, over any field with `2 ≠ 0`: the point `(x, y)`
goes to `t = y/(x + 1)`, and `t` goes back to `((1 - t^2)/(1 + t^2), 2t/(1 + t^2))`. -/
theorem stereographic_projection_inverse {k : Type u} [Field k] (h2 : (2 : k) ≠ 0) :
    (∀ x y : k, x ^ 2 + y ^ 2 = 1 → (x, y) ≠ (-1, 0) →
        1 + (y / (x + 1)) ^ 2 ≠ 0 ∧
        ((1 - (y / (x + 1)) ^ 2) / (1 + (y / (x + 1)) ^ 2),
          2 * (y / (x + 1)) / (1 + (y / (x + 1)) ^ 2)) = (x, y)) ∧
    (∀ t : k, 1 + t ^ 2 ≠ 0 →
        ((1 - t ^ 2) / (1 + t ^ 2)) ^ 2 + (2 * t / (1 + t ^ 2)) ^ 2 = 1 ∧
        ((1 - t ^ 2) / (1 + t ^ 2), 2 * t / (1 + t ^ 2)) ≠ (-1, 0) ∧
        (2 * t / (1 + t ^ 2)) / ((1 - t ^ 2) / (1 + t ^ 2) + 1) = t) := by
  refine ⟨fun x y h hne => ?_, fun t ht => ?_⟩
  · have hx1 : x + 1 ≠ 0 := by
      intro hx
      have hx' : x = -1 := by linear_combination hx
      subst hx'
      have hy : y ^ 2 = 0 := by linear_combination h
      exact hne (by simp [pow_eq_zero_iff two_ne_zero |>.mp hy])
    have key : 1 + (y / (x + 1)) ^ 2 = 2 / (x + 1) := by
      field_simp
      linear_combination h
    have k2 : 1 - (y / (x + 1)) ^ 2 = 2 * x / (x + 1) := by
      field_simp
      linear_combination -h
    refine ⟨?_, ?_⟩
    · rw [key]; exact div_ne_zero h2 hx1
    · rw [key, k2]
      ext
      · field_simp
      · field_simp
  · have hd : (1 - t ^ 2) / (1 + t ^ 2) + 1 = 2 / (1 + t ^ 2) := by
      field_simp; ring
    refine ⟨?_, ?_, ?_⟩
    · field_simp; ring
    · intro he
      have := congrArg Prod.fst he
      simp only at this
      field_simp at this
      apply h2
      linear_combination this
    · rw [hd]; field_simp

-- t = 1/2 goes to (3/5, 4/5), which is on the circle and goes back to 1/2.
example : ((1 - (1 / 2 : ℚ) ^ 2) / (1 + (1 / 2) ^ 2), 2 * (1 / 2 : ℚ) / (1 + (1 / 2) ^ 2))
    = (3 / 5, 4 / 5) := by norm_num
example : (3 / 5 : ℚ) ^ 2 + (4 / 5) ^ 2 = 1 := by norm_num
example : (4 / 5 : ℚ) / (3 / 5 + 1) = 1 / 2 := by norm_num
-- t = 2/3 goes to (5/13, 12/13); clearing the 13s gives the triangle (5, 12, 13).
example : ((1 - (2 / 3 : ℚ) ^ 2) / (1 + (2 / 3) ^ 2), 2 * (2 / 3 : ℚ) / (1 + (2 / 3) ^ 2))
    = (5 / 13, 12 / 13) := by norm_num
example : (5 : ℕ) ^ 2 + 12 ^ 2 = 13 ^ 2 := by norm_num
-- One element, two fractions: y * y - (1 - x)(x + 1) = x^2 + y^2 - 1.
example {R : Type*} [CommRing R] (x y : R) : y * y - (1 - x) * (x + 1) = x ^ 2 + y ^ 2 - 1 := by
  ring
-- The round trip in the field: (2x^2 + 2x)/(2x + 2) is x, cross-multiplied.
example {R : Type*} [CommRing R] (x : R) : (2 * x ^ 2 + 2 * x) - x * (2 * x + 2) = 0 := by ring
-- Counts over F_p: the circle has 8 points mod 7 and 4 mod 5; the line has 7 and 5.
example : (Finset.univ.filter (fun p : ZMod 7 × ZMod 7 => p.1 ^ 2 + p.2 ^ 2 = 1)).card = 8 := by
  decide
example : (Finset.univ.filter (fun p : ZMod 5 × ZMod 5 => p.1 ^ 2 + p.2 ^ 2 = 1)).card = 4 := by
  decide
-- Heights removed: t^2 = -1 has no root mod 7 and the roots 2 and 3 mod 5.
example : (Finset.univ.filter (fun t : ZMod 7 => 1 + t ^ 2 = 0)).card = 0 := by decide
example : Finset.univ.filter (fun t : ZMod 5 => 1 + t ^ 2 = 0) = {2, 3} := by decide
-- The reducible xy = 0 over F_7 has 13 points, and x * y is zero at all of them.
example : (Finset.univ.filter (fun p : ZMod 7 × ZMod 7 => p.1 * p.2 = 0)).card = 13 := by decide
-- x^2 + y^2 = 3 over Q: X^2 + Y^2 = 3Z^2 has no solution mod 9 with X, Y, Z not all divisible
-- by 3, while X^2 + Y^2 = Z^2 has 72.
set_option maxRecDepth 100000 in
example : (Finset.univ.filter (fun p : ZMod 9 × ZMod 9 × ZMod 9 =>
    p.1 ^ 2 + p.2.1 ^ 2 = 3 * p.2.2 ^ 2 ∧
      ¬ (3 ∣ p.1.val ∧ 3 ∣ p.2.1.val ∧ 3 ∣ p.2.2.val))).card = 0 := by decide
set_option maxRecDepth 100000 in
example : (Finset.univ.filter (fun p : ZMod 9 × ZMod 9 × ZMod 9 =>
    p.1 ^ 2 + p.2.1 ^ 2 = p.2.2 ^ 2 ∧
      ¬ (3 ∣ p.1.val ∧ 3 ∣ p.2.1.val ∧ 3 ∣ p.2.2.val))).card = 72 := by decide

#print axioms birational_iff_function_fields_isomorphic
#print axioms circle_function_field_eq_rational_functions
#print axioms stereographic_projection_inverse
