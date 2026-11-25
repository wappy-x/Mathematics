-- Kan extensions: the colimit and limit formulas give left and right Kan extensions with their defining property, limits and colimits are Kan extensions to one point, and adjoints are Kan extensions of the identity.
import Mathlib.CategoryTheory.Functor.KanExtension.Pointwise
import Mathlib.CategoryTheory.Adjunction.Basic
import Mathlib.CategoryTheory.PUnit
import Mathlib.Data.List.Basic

open CategoryTheory CategoryTheory.Limits CategoryTheory.Functor

universe w

theorem kanCheck_isLeftKanExtension_of_bijective
    {C D H : Type*} [Category* C] [Category* D] [Category* H]
    {L : C ⥤ D} {F : C ⥤ H} {F' : D ⥤ H} (α : F ⟶ L ⋙ F')
    (h : ∀ G : D ⥤ H, Function.Bijective (fun β : F' ⟶ G => α ≫ whiskerLeft L β)) :
    F'.IsLeftKanExtension α := by
  choose β hβ using fun G : LeftExtension L F => (h G.right).2 G.hom
  refine ⟨⟨IsInitial.ofUniqueHom
    (fun G => StructuredArrow.homMk (β G) ?_) ?_⟩⟩
  · simpa using hβ G
  · intro G m
    ext1
    apply (h G.right).1
    refine Eq.trans ?_ (hβ G).symm
    simpa using m.w

theorem kanCheck_isRightKanExtension_of_bijective
    {C D H : Type*} [Category* C] [Category* D] [Category* H]
    {L : C ⥤ D} {F : C ⥤ H} {F' : D ⥤ H} (α : L ⋙ F' ⟶ F)
    (h : ∀ G : D ⥤ H, Function.Bijective (fun β : G ⟶ F' => whiskerLeft L β ≫ α)) :
    F'.IsRightKanExtension α := by
  choose β hβ using fun G : RightExtension L F => (h G.left).2 G.hom
  refine ⟨⟨IsTerminal.ofUniqueHom
    (fun G => CostructuredArrow.homMk (β G) ?_) ?_⟩⟩
  · simpa using hβ G
  · intro G m
    ext1
    apply (h G.left).1
    refine Eq.trans ?_ (hβ G).symm
    simpa using m.w

#print axioms kanCheck_isLeftKanExtension_of_bijective
#print axioms kanCheck_isRightKanExtension_of_bijective

/-- The colimit and limit formulas give the Kan extensions. Let `K : A ⥤ B` be the functor to
extend along and `F : A ⥤ H` the functor known on `A`. If the target `H` has, for each object
`b` of `B`, the colimit of `F` over the pairs (`a`, an arrow `K a ⟶ b`), then some `E : B ⥤ H`
with `α : F ⟶ K ⋙ E` has `E b` equal to that colimit for every `b` (the colimit formula), and
natural maps `E ⟶ G` match natural maps `F ⟶ K ⋙ G` one for one for every functor `G` on `B`
(the defining property of the left Kan extension `Lan_K F`). Dually, if `H` has the limits over
the pairs (`a`, an arrow `b ⟶ K a`), the limit formula gives `E` with `α : K ⋙ E ⟶ F`, and
natural maps `G ⟶ E` match natural maps `K ⋙ G ⟶ F` one for one (the right Kan extension
`Ran_K F`). -/
theorem kan_extensions_by_colimit_and_limit_formulas
    {A B H : Type*} [Category* A] [Category* B] [Category* H]
    (K : A ⥤ B) (F : A ⥤ H) :
    (HasPointwiseLeftKanExtension K F →
      ∃ (E : B ⥤ H) (α : F ⟶ K ⋙ E),
        (∀ b : B, Nonempty (IsColimit ((LeftExtension.mk E α).coconeAt b))) ∧
        ∀ G : B ⥤ H, Function.Bijective (fun β : E ⟶ G => α ≫ whiskerLeft K β)) ∧
    (HasPointwiseRightKanExtension K F →
      ∃ (E : B ⥤ H) (α : K ⋙ E ⟶ F),
        (∀ b : B, Nonempty (IsLimit ((RightExtension.mk E α).coneAt b))) ∧
        ∀ G : B ⥤ H, Function.Bijective (fun β : G ⟶ E => whiskerLeft K β ≫ α)) := by
  refine ⟨fun _ => ?_, fun _ => ?_⟩
  · refine ⟨pointwiseLeftKanExtension K F, pointwiseLeftKanExtensionUnit K F,
      fun b => ⟨pointwiseLeftKanExtensionIsPointwiseLeftKanExtension K F b⟩,
      fun G => ?_⟩
    exact (homEquivOfIsLeftKanExtension _ (pointwiseLeftKanExtensionUnit K F) G).bijective
  · refine ⟨pointwiseRightKanExtension K F, pointwiseRightKanExtensionCounit K F,
      fun b => ⟨pointwiseRightKanExtensionIsPointwiseRightKanExtension K F b⟩,
      fun G => ?_⟩
    exact (homEquivOfIsRightKanExtension _ (pointwiseRightKanExtensionCounit K F) G).bijective

/-- Limits and colimits are Kan extensions along the only functor `! : A ⥤ 1` to the category
with one object. A cocone `c` on `F` (the point `c.pt`, seen as a functor on the one-object
category, with the cocone's legs as the map `F ⟶ ! ⋙ c.pt`) is a colimit of `F` exactly when
it is the left Kan extension of `F` along `!`; a cone `d` on `F` is a limit of `F` exactly when
it is the right Kan extension of `F` along `!`. -/
theorem limits_and_colimits_are_kan_extensions_to_a_point
    {A H : Type*} [Category* A] [Category* H] (F : A ⥤ H) (c : Cocone F) (d : Cone F) :
    (Nonempty (IsColimit c) ↔
      ((Functor.const (Discrete PUnit.{w + 1})).obj c.pt).IsLeftKanExtension
        (L := Functor.star A) (c.ι : F ⟶ Functor.star A ⋙ (Functor.const _).obj c.pt)) ∧
    (Nonempty (IsLimit d) ↔
      ((Functor.const (Discrete PUnit.{w + 1})).obj d.pt).IsRightKanExtension
        (L := Functor.star A) (d.π : Functor.star A ⋙ (Functor.const _).obj d.pt ⟶ F)) := by
  refine ⟨⟨?_, ?_⟩, ⟨?_, ?_⟩⟩
  · rintro ⟨hc⟩
    apply kanCheck_isLeftKanExtension_of_bijective
    intro G
    constructor
    · intro β₁ β₂ hβ
      have key : β₁.app ⟨⟨⟩⟩ = β₂.app ⟨⟨⟩⟩ := hc.hom_ext (fun j => by
        simpa using congr_app hβ j)
      ext ⟨⟨⟩⟩
      exact key
    · intro γ
      let s : Cocone F :=
        { pt := G.obj ⟨⟨⟩⟩
          ι := { app := fun j => γ.app j
                 naturality := by
                   intro j j' f
                   have h := γ.naturality f
                   dsimp at h ⊢
                   rw [h]
                   simp [Functor.star] } }
      refine ⟨{ app := fun _ => hc.desc s
                naturality := ?_ }, ?_⟩
      · rintro ⟨⟨⟩⟩ ⟨⟨⟩⟩ f
        obtain rfl : f = 𝟙 _ := Subsingleton.elim _ _
        simp
      · ext j
        simp [s]
  · intro hK
    let δ : ∀ s : Cocone F, (Functor.const (Discrete PUnit.{w + 1})).obj c.pt ⟶
        (Functor.const (Discrete PUnit.{w + 1})).obj s.pt := fun s =>
      descOfIsLeftKanExtension (L := Functor.star A) _ c.ι _ s.ι
    refine ⟨{ desc := fun s => (δ s).app ⟨⟨⟩⟩, fac := fun s j => ?_, uniq := fun s m hm => ?_ }⟩
    · exact descOfIsLeftKanExtension_fac_app (L := Functor.star A)
            ((Functor.const (Discrete PUnit.{w + 1})).obj c.pt) c.ι
            ((Functor.const (Discrete PUnit.{w + 1})).obj s.pt) s.ι j
    · have e : (Functor.const (Discrete PUnit.{w + 1})).map m = δ s :=
        hom_ext_of_isLeftKanExtension (L := Functor.star A) _ c.ι _ _ (by
          ext j
          have h2 := descOfIsLeftKanExtension_fac_app (L := Functor.star A)
            ((Functor.const (Discrete PUnit.{w + 1})).obj c.pt) c.ι
            ((Functor.const (Discrete PUnit.{w + 1})).obj s.pt) s.ι j
          dsimp [δ] at h2 ⊢
          rw [hm j, h2])
      exact congr_app e ⟨⟨⟩⟩
  · rintro ⟨hd⟩
    apply kanCheck_isRightKanExtension_of_bijective
    intro G
    constructor
    · intro β₁ β₂ hβ
      have key : β₁.app ⟨⟨⟩⟩ = β₂.app ⟨⟨⟩⟩ := hd.hom_ext (fun j => by
        simpa using congr_app hβ j)
      ext ⟨⟨⟩⟩
      exact key
    · intro γ
      let s : Cone F :=
        { pt := G.obj ⟨⟨⟩⟩
          π := { app := fun j => γ.app j
                 naturality := by
                   intro j j' f
                   have h := γ.naturality f
                   dsimp at h ⊢
                   rw [← h]
                   simp [Functor.star] } }
      refine ⟨{ app := fun _ => hd.lift s
                naturality := ?_ }, ?_⟩
      · rintro ⟨⟨⟩⟩ ⟨⟨⟩⟩ f
        obtain rfl : f = 𝟙 _ := Subsingleton.elim _ _
        simp
      · ext j
        simp [s]
  · intro hK
    let δ : ∀ s : Cone F, (Functor.const (Discrete PUnit.{w + 1})).obj s.pt ⟶
        (Functor.const (Discrete PUnit.{w + 1})).obj d.pt := fun s =>
      liftOfIsRightKanExtension (L := Functor.star A) _ d.π _ s.π
    refine ⟨{ lift := fun s => (δ s).app ⟨⟨⟩⟩, fac := fun s j => ?_, uniq := fun s m hm => ?_ }⟩
    · exact liftOfIsRightKanExtension_fac_app (L := Functor.star A)
            ((Functor.const (Discrete PUnit.{w + 1})).obj d.pt) d.π
            ((Functor.const (Discrete PUnit.{w + 1})).obj s.pt) s.π j
    · have e : (Functor.const (Discrete PUnit.{w + 1})).map m = δ s :=
        hom_ext_of_isRightKanExtension (L := Functor.star A) _ d.π _ _ (by
          ext j
          have h2 := liftOfIsRightKanExtension_fac_app (L := Functor.star A)
            ((Functor.const (Discrete PUnit.{w + 1})).obj d.pt) d.π
            ((Functor.const (Discrete PUnit.{w + 1})).obj s.pt) s.π j
          dsimp [δ] at h2 ⊢
          rw [hm j, h2])
      exact congr_app e ⟨⟨⟩⟩

/-- Adjoints are Kan extensions of the identity. If `L ⊣ R`, then `R` with the unit
`𝟭 ⟶ L ⋙ R` is the left Kan extension of the identity along `L`, and `L` with the counit
`R ⋙ L ⟶ 𝟭` is the right Kan extension of the identity along `R`. -/
theorem adjoints_are_kan_extensions_of_the_identity
    {C D : Type*} [Category* C] [Category* D] (L : C ⥤ D) (R : D ⥤ C) (adj : L ⊣ R) :
    R.IsLeftKanExtension adj.unit ∧ L.IsRightKanExtension adj.counit := by
  constructor
  · apply kanCheck_isLeftKanExtension_of_bijective
    intro G
    refine Function.bijective_iff_has_inverse.2
      ⟨fun γ => { app := fun d => γ.app (R.obj d) ≫ G.map (adj.counit.app d)
                  naturality := by
                    intro d d' f
                    have h1 := γ.naturality (R.map f)
                    dsimp at h1 ⊢
                    rw [reassoc_of% h1, Category.assoc, ← G.map_comp, ← G.map_comp]
                    congr 2
                    simp }, ?_, ?_⟩
    · intro β
      ext d
      dsimp
      rw [Category.assoc, ← β.naturality, Adjunction.right_triangle_components_assoc]
    · intro γ
      ext c
      have h1 := γ.naturality (adj.unit.app c)
      dsimp at h1 ⊢
      rw [reassoc_of% h1, ← G.map_comp, Adjunction.left_triangle_components, G.map_id,
        Category.comp_id]
  · apply kanCheck_isRightKanExtension_of_bijective
    intro G
    refine Function.bijective_iff_has_inverse.2
      ⟨fun γ => { app := fun c => G.map (adj.unit.app c) ≫ γ.app (L.obj c)
                  naturality := by
                    intro c c' f
                    have h1 := γ.naturality (L.map f)
                    dsimp at h1 ⊢
                    rw [Category.assoc, ← h1, ← G.map_comp_assoc, ← G.map_comp_assoc]
                    congr 2
                    simp }, ?_, ?_⟩
    · intro β
      ext c
      simp
    · intro γ
      ext d
      have h1 := γ.naturality (adj.counit.app d)
      dsimp at h1 ⊢
      rw [Category.assoc, ← h1, ← G.map_comp_assoc, Adjunction.right_triangle_components, G.map_id,
        Category.id_comp]

/-! ### The card's whole-number worked examples -/

-- The log so far on reading days 1, 3, 5 has 1, 2, 3 entries; carried forward (the last
-- reading day up to b) the left extension on days 1 to 6 has 1, 1, 2, 2, 3, 3 entries.
example : ([1, 2, 3, 4, 5, 6].map fun b => ([1, 3, 5].filter (· ≤ b)).length)
    = [1, 1, 2, 2, 3, 3] := by decide

-- Carried back (the next reading day from b on) the right extension on days 1 to 5 has
-- 1, 2, 2, 3, 3 entries; day 6 has no reading ahead.
example : ([1, 2, 3, 4, 5].map fun b =>
    ([1, 3, 5].filter (· ≤ (([1, 3, 5].filter (b ≤ ·)).headD 0))).length)
    = [1, 2, 2, 3, 3] ∧ ([1, 3, 5].filter (6 ≤ ·)) = [] := by decide

-- Left at day 6 before gluing: 1 + 2 + 3 = 6 tagged entries; right at day 2 before
-- agreement: 2 × 3 = 6 pairs.
example : 1 + 2 + 3 = 6 ∧ 2 * 3 = 6 := by decide

-- Colimit of F (3 entries): natural maps to a 2-element set number 2^3 = 8;
-- limit of F (1 entry): natural maps from a 2-element set number 1^2 = 1.
example : 2 ^ 3 = 8 ∧ 1 ^ 2 = 1 := by decide

-- Adjoints: 6 is the largest x with 3x ≤ 20, which is ⌊20/3⌋; 18 is the smallest y with
-- 6 ≤ ⌊y/3⌋, which is 3 × 6.
example : 3 * 6 ≤ 20 ∧ ¬ 3 * 7 ≤ 20 ∧ (20 : ℤ) / 3 = 6 := by decide
example : (6 : ℤ) ≤ 18 / 3 ∧ ¬ (6 : ℤ) ≤ 17 / 3 ∧ 3 * 6 = 18 := by decide

-- 3x ≤ y exactly when x ≤ ⌊y/3⌋, checked on all 61 × 61 pairs from −30 to 30.
example : ∀ x : Fin 61, ∀ y : Fin 61,
    (3 * ((x : ℤ) - 30) ≤ (y : ℤ) - 30 ↔ (x : ℤ) - 30 ≤ ((y : ℤ) - 30) / 3) := by decide

#print axioms kan_extensions_by_colimit_and_limit_formulas
#print axioms limits_and_colimits_are_kan_extensions_to_a_point
#print axioms adjoints_are_kan_extensions_of_the_identity
