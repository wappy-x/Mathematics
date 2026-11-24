-- Cofibrations: if a pair has the homotopy extension property and the piece is contractible, squashing the piece to a point is a homotopy equivalence; the property is the same as a retraction of the solid cylinder onto floor and walls; and every mapping cylinder deformation retracts onto its target.
import Mathlib.Topology.Homotopy.Contractible
import Mathlib.Topology.Homotopy.Equiv
import Mathlib.Topology.Homotopy.Basic
import Mathlib.Topology.Constructions
import Mathlib.Topology.UnitInterval
import Mathlib.Analysis.Complex.Basic
import Mathlib.Topology.CompactOpen

open unitInterval ContinuousMap

universe u v

section Pairs

variable {X : Type u} [TopologicalSpace X]

/-- The homotopy extension property of a pair (X, A): for every space Y, every map
F₀ : X → Y and every homotopy h : A × I → Y that starts at F₀ on A, there is a homotopy
H : X × I → Y that starts at F₀ and agrees with h on A × I. -/
def HasHEP (A : Set X) : Prop :=
  ∀ (Y : Type u) [TopologicalSpace Y] (F₀ : C(X, Y)) (h : C(A × I, Y)),
    (∀ a : A, h (a, 0) = F₀ a) →
    ∃ H : C(X × I, Y), (∀ x, H (x, 0) = F₀ x) ∧ ∀ (a : A) (t : I), H (a, t) = h (a, t)

/-- Squashing A to one point: x and y are glued when they are equal or both lie in A.
The quotient by this relation is X/A, and `Quotient.mk` is the squashing map q. -/
def collapseSetoid (A : Set X) : Setoid X where
  r x y := x = y ∨ (x ∈ A ∧ y ∈ A)
  iseqv :=
    { refl := fun _ => Or.inl rfl
      symm := by
        rintro x y (rfl | ⟨hx, hy⟩)
        exacts [Or.inl rfl, Or.inr ⟨hy, hx⟩]
      trans := by
        rintro x y z (rfl | ⟨hx, hy⟩) (rfl | ⟨hy', hz⟩)
        exacts [Or.inl rfl, Or.inr ⟨hy', hz⟩, Or.inr ⟨hx, hy⟩, Or.inr ⟨hx, hz⟩] }

/-- The collapse theorem (Hatcher, Proposition 0.17): if the pair (X, A) has the homotopy
extension property, A is closed and A is contractible, then the squashing map
q : X → X/A is a homotopy equivalence. -/
theorem collapse_contractible_is_homotopy_equivalence (A : Set X) (hA : IsClosed A)
    (hHEP : HasHEP A) [ContractibleSpace A] :
    ∃ e : X ≃ₕ Quotient (collapseSetoid A), ⇑e = Quotient.mk (collapseSetoid A) := by
  obtain ⟨a₀, ⟨K⟩⟩ := id_nullhomotopic A
  obtain ⟨F, hF0, hFA⟩ := hHEP X (ContinuousMap.id X)
    ⟨fun p => (K (p.2, p.1) : X), by fun_prop⟩ (fun a => by simp)
  have hFmem : ∀ x t, x ∈ A → F (x, t) ∈ A := fun x t hx => by
    have := hFA ⟨x, hx⟩ t
    simp only at this
    rw [this]; exact (K (t, ⟨x, hx⟩)).2
  have hF1 : ∀ x, x ∈ A → F (x, 1) = a₀ := fun x hx => by
    have := hFA ⟨x, hx⟩ 1
    simp only at this
    rw [this]; simp
  let s := collapseSetoid A
  have hresp : ∀ t : I, ∀ x y : X, s x y → (Quotient.mk s (F (x, t))) = Quotient.mk s (F (y, t)) := by
    rintro t x y (rfl | ⟨hx, hy⟩)
    · rfl
    · exact Quotient.sound (Or.inr ⟨hFmem x t hx, hFmem y t hy⟩)
  let q : C(X, Quotient s) := ⟨Quotient.mk s, continuous_quotient_mk'⟩
  let g : C(Quotient s, X) := ⟨Quot.lift (fun x => F (x, 1)) (by
      rintro x y (rfl | ⟨hx, hy⟩)
      · rfl
      · rw [hF1 x hx, hF1 y hy]),
    continuous_quot_lift _ (F.continuous.comp (continuous_id.prodMk continuous_const))⟩
  let L : I × Quotient s → Quotient s := fun p => Quot.lift (fun x => Quotient.mk s (F (x, p.1)))
    (hresp p.1) p.2
  have hLc : Continuous L :=
    isQuotientMap_quotient_mk'.continuous_lift_prod_right
      (continuous_quotient_mk'.comp (F.continuous.comp continuous_swap))
  refine ⟨⟨q, g, ⟨?_⟩, ⟨?_⟩⟩, rfl⟩
  · refine Homotopy.symm
      { toFun := fun p => F (p.2, p.1)
        continuous_toFun := by fun_prop
        map_zero_left := ?_
        map_one_left := ?_ }
    · intro x; exact hF0 x
    · intro x; rfl
  · refine Homotopy.symm
      { toFun := L
        continuous_toFun := hLc
        map_zero_left := ?_
        map_one_left := ?_ }
    · intro z
      induction z using Quotient.inductionOn with
      | h x => show Quotient.mk s (F (x, 0)) = _; rw [hF0]; rfl
    · intro z
      induction z using Quotient.inductionOn with
      | h x => rfl


/-- The homotopy extension property is one retraction: for a closed subset A, the pair
(X, A) has the homotopy extension property exactly when there is a retraction of the solid
cylinder X × I onto its floor X × {0} together with its walls A × I, that is, a map into
floor and walls that keeps every point of floor and walls fixed. -/
theorem hasHEP_iff_exists_retraction (A : Set X) (hA : IsClosed A) :
    HasHEP A ↔ ∃ r : C(X × I, X × I),
      (∀ p, r p ∈ {q : X × I | q.2 = 0} ∪ A ×ˢ Set.univ) ∧
      ∀ p ∈ {q : X × I | q.2 = 0} ∪ A ×ˢ Set.univ, r p = p := by
  classical
  set Z : Set (X × I) := {q : X × I | q.2 = 0} ∪ A ×ˢ Set.univ with hZ
  constructor
  · intro hH
    obtain ⟨H, h0, h1⟩ := hH Z ⟨fun x => ⟨(x, 0), Or.inl rfl⟩, by fun_prop⟩
      ⟨fun p => ⟨((p.1 : X), p.2), Or.inr ⟨p.1.2, trivial⟩⟩, by fun_prop⟩ (fun a => rfl)
    refine ⟨⟨fun p => (H p).1, by fun_prop⟩, fun p => (H p).2, ?_⟩
    rintro ⟨x, t⟩ (ht | ⟨hx, -⟩)
    · simp only [Set.mem_ofPred_eq] at ht
      subst ht
      show ((H (x, 0)) : X × I) = (x, 0)
      rw [h0]
      rfl
    · show ((H (x, t)) : X × I) = (x, t)
      exact congrArg Subtype.val (h1 ⟨x, hx⟩ t)
  · rintro ⟨r, hr1, hr2⟩ Y _ F₀ h hh
    let G : X × I → Y := fun p => if hp : p.1 ∈ A then h (⟨p.1, hp⟩, p.2) else F₀ p.1
    have hG0 : ∀ x, G (x, 0) = F₀ x := by
      intro x
      simp only [G]
      split_ifs with hx
      · exact hh ⟨x, hx⟩
      · rfl
    have hGc : ContinuousOn G Z := by
      refine ContinuousOn.union_of_isClosed ?_ ?_
        (isClosed_eq continuous_snd continuous_const) (hA.prod isClosed_univ)
      · have : Set.EqOn G (fun p => F₀ p.1) {q : X × I | q.2 = 0} := by
          rintro ⟨x, t⟩ ht
          simp only [Set.mem_ofPred_eq] at ht
          subst ht
          exact hG0 x
        exact (F₀.continuous.comp continuous_fst).continuousOn.congr this
      · rw [continuousOn_iff_continuous_domRestrict]
        have : (A ×ˢ Set.univ).domRestrict G =
            fun p : ↥(A ×ˢ (Set.univ : Set I)) => h (⟨p.1.1, p.2.1⟩, p.1.2) := by
          funext p
          obtain ⟨⟨x, t⟩, hx, -⟩ := p
          simp [G, hx]
        rw [this]
        fun_prop
    have hHc : Continuous fun p => G (r p) := hGc.comp_continuous r.continuous hr1
    refine ⟨⟨fun p => G (r p), hHc⟩, ?_, ?_⟩
    · intro x
      show G (r (x, 0)) = F₀ x
      rw [hr2 _ (Or.inl rfl)]
      exact hG0 x
    · intro a t
      show G (r (a, t)) = h (a, t)
      rw [hr2 _ (Or.inr ⟨a.2, trivial⟩)]
      simp [G, a.2]


end Pairs

section Cylinder

variable {X : Type u} {Y : Type v} [TopologicalSpace X] [TopologicalSpace Y]

/-- The gluing of the mapping cylinder: the far end (x, 1) of the cylinder on X is glued
to f(x) in Y. -/
def cylGlue (f : C(X, Y)) : (X × I) ⊕ Y → (X × I) ⊕ Y → Prop :=
  fun p q => ∃ x, p = Sum.inl (x, 1) ∧ q = Sum.inr (f x)

/-- The mapping cylinder M_f = ((X × I) ⊔ Y) / ((x, 1) ∼ f(x)), with the quotient topology. -/
abbrev MappingCylinder (f : C(X, Y)) := Quot (cylGlue f)

/-- Y sitting inside the mapping cylinder as the far end. -/
def cylTarget (f : C(X, Y)) : C(Y, MappingCylinder f) :=
  ⟨fun y => Quot.mk _ (Sum.inr y), continuous_quot_mk.comp continuous_inr⟩

/-- X sitting inside the mapping cylinder as the near end, height 0. -/
def cylDomain (f : C(X, Y)) : C(X, MappingCylinder f) :=
  ⟨fun x => Quot.mk _ (Sum.inl (x, 0)),
    continuous_quot_mk.comp (continuous_inl.comp (continuous_id.prodMk continuous_const))⟩

/-- The mapping cylinder slides onto its target: there is a retraction r of M_f onto Y,
and Y is a deformation retract of M_f (the composite of r with the inclusion of Y is
homotopic to the identity by a film that keeps Y still), so M_f ≃ Y. Following the slide
from the near end gives back f, so every map is an inclusion followed by a homotopy
equivalence. -/
theorem mappingCylinder_deformation_retracts_onto_target (f : C(X, Y)) :
    ∃ r : C(MappingCylinder f, Y),
      r.comp (cylTarget f) = ContinuousMap.id Y ∧
      ((cylTarget f).comp r).HomotopicRel (ContinuousMap.id _) (Set.range (cylTarget f)) ∧
      r.comp (cylDomain f) = f := by
  let r0 : (X × I) ⊕ Y → Y := Sum.elim (fun p => f p.1) id
  have hr0 : ∀ p q, cylGlue f p q → r0 p = r0 q := by
    rintro _ _ ⟨x, rfl, rfl⟩; rfl
  let r : C(MappingCylinder f, Y) :=
    ⟨Quot.lift r0 hr0, continuous_quot_lift _
      (continuous_sum_dom.2 ⟨f.continuous.comp continuous_fst, continuous_id⟩)⟩
  -- the slide
  let g1 : I × (X × I) → MappingCylinder f :=
    fun p => Quot.mk _ (Sum.inl (p.2.1, σ (p.1 * σ p.2.2)))
  let g2 : I × Y → MappingCylinder f := fun p => Quot.mk _ (Sum.inr p.2)
  let H0 : I × ((X × I) ⊕ Y) → MappingCylinder f :=
    Sum.elim g1 g2 ∘ Homeomorph.prodSumDistrib
  have hmul : Continuous fun p : I × I => p.1 * p.2 :=
    Continuous.subtype_mk ((continuous_subtype_val.comp continuous_fst).mul
      (continuous_subtype_val.comp continuous_snd)) _
  have hH0c : Continuous H0 := by
    refine Continuous.comp (continuous_sum_dom.2 ⟨?_, ?_⟩) (Homeomorph.continuous _)
    · exact continuous_quot_mk.comp (continuous_inl.comp
        ((continuous_fst.comp continuous_snd).prodMk
          (continuous_symm.comp (hmul.comp (continuous_fst.prodMk
            (continuous_symm.comp (continuous_snd.comp continuous_snd)))))))
    · exact continuous_quot_mk.comp (continuous_inr.comp continuous_snd)
  have hH0 : ∀ s p q, cylGlue f p q → H0 (s, p) = H0 (s, q) := by
    rintro s _ _ ⟨x, rfl, rfl⟩
    show Quot.mk _ (Sum.inl (x, σ (s * σ 1))) = Quot.mk (cylGlue f) (Sum.inr (f x))
    rw [symm_one, mul_zero, symm_zero]
    exact Quot.sound ⟨x, rfl, rfl⟩
  let H : I × MappingCylinder f → MappingCylinder f :=
    fun p => Quot.lift (fun q => H0 (p.1, q)) (hH0 p.1) p.2
  have hHc : Continuous H :=
    (isQuotientMap_quot_mk).continuous_lift_prod_right hH0c
  refine ⟨r, rfl, ⟨?_⟩, rfl⟩
  refine
    { toFun := H
      continuous_toFun := hHc
      map_zero_left := ?_
      map_one_left := ?_
      prop' := ?_ }
  · intro z
    induction z using Quot.ind with
    | mk p =>
      rcases p with ⟨x, t⟩ | y
      · show Quot.mk _ (Sum.inl (x, σ (0 * σ t))) = Quot.mk (cylGlue f) (Sum.inr (f x))
        rw [zero_mul, symm_zero]
        exact Quot.sound ⟨x, rfl, rfl⟩
      · rfl
  · intro z
    induction z using Quot.ind with
    | mk p =>
      rcases p with ⟨x, t⟩ | y
      · show Quot.mk _ (Sum.inl (x, σ (1 * σ t))) = Quot.mk (cylGlue f) (Sum.inl (x, t))
        rw [one_mul, symm_symm]
      · rfl
  · rintro s _ ⟨y, rfl⟩
    rfl

end Cylinder

-- The card's worked numbers.
-- z ↦ z² sends the upper points 1 and -1 to the same lower point 1.
example : ((-1 : ℂ)) ^ 2 = 1 ∧ ((1 : ℂ)) ^ 2 = 1 := by norm_num
-- Euler characteristics: target circle (1, 1, 0); cylinder (3, 5, 2); cone by spokes (4, 7, 4);
-- cylinder with the domain squashed (2, 3, 2); the projective plane (1, 1, 1).
example : (1 : ℤ) - 1 + 0 = 0 ∧ (3 : ℤ) - 5 + 2 = 0 ∧ (4 : ℤ) - 7 + 4 = 1 ∧
    (2 : ℤ) - 3 + 2 = 1 ∧ (1 : ℤ) - 1 + 1 = 1 := by norm_num
-- Theta graph (2 points, 3 edges) and the figure eight after collapsing e (1 point, 2 edges):
-- χ = -1 both times, loop rank 1 - χ = 2 both times.
example : (2 : ℤ) - 3 = -1 ∧ (1 : ℤ) - 2 = -1 ∧ 1 - ((2 : ℤ) - 3) = 2 ∧ 1 - ((1 : ℤ) - 2) = 2 := by
  norm_num
-- What breaks: collapsing the loop x y leaves a circle, χ = 1 - 1 = 0, rank 1;
-- leaving out the cylinder's 2 squares gives χ = 3 - 5 = -2, rank 3.
example : (1 : ℤ) - 1 = 0 ∧ 1 - ((1 : ℤ) - 1) = 1 ∧ (3 : ℤ) - 5 = -2 ∧ 1 - ((3 : ℤ) - 5) = 3 := by
  norm_num

/-- The radial push of the lead square [-1, 1] × [0, 1] from the point (0, 2). -/
def leadPush (x t : ℚ) : ℚ × ℚ :=
  if 2 * |x| ≤ 2 - t then (2 * x / (2 - t), 0) else (x / |x|, 2 - (2 - t) / |x|)

-- r(3/4, 1) = (1, 2 - 4/3) = (1, 2/3).
example : leadPush (3 / 4) 1 = (1, 2 / 3) := by norm_num [leadPush, abs_of_pos]
-- At t = 1 the marks -1, -1/2, 0, 1/2, 3/4, 1 land on floor or wall at these points;
-- reading the data there (floor: the mark itself; right wall at height s: 1 + s; left wall: -1)
-- sends them to -1, -1, 0, 1, 5/3, 2.
example : leadPush (-1) 1 = (-1, 1) ∧ leadPush (-1 / 2) 1 = (-1, 0) ∧ leadPush 0 1 = (0, 0) ∧
    leadPush (1 / 2) 1 = (1, 0) ∧ leadPush 1 1 = (1, 1) := by
  norm_num [leadPush, abs_of_pos, abs_of_neg]
example : (1 : ℚ) + 2 / 3 = 5 / 3 ∧ (1 : ℚ) + 1 = 2 := by norm_num

#print axioms collapse_contractible_is_homotopy_equivalence
#print axioms hasHEP_iff_exists_retraction
#print axioms mappingCylinder_deformation_retracts_onto_target
