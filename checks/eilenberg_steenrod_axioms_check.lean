-- Eilenberg-Steenrod axioms: from what the axioms give on disc pairs, every sphere S^n has one copy of ℤ in dimension n and nothing else (reduced), and singular homology obeys the dimension and homotopy axioms.
import Mathlib.AlgebraicTopology.SingularHomology.Basic
import Mathlib.AlgebraicTopology.SingularHomology.HomotopyInvariance
import Mathlib.AlgebraicTopology.SingularHomology.HomologyZero
import Mathlib.Algebra.Category.Grp.Abelian
import Mathlib.Algebra.Category.Grp.Colimits
import Mathlib.Algebra.Exact.Basic
import Mathlib.Tactic.NormNum

open CategoryTheory Limits AlgebraicTopology

/-- The sphere ladder (Steps 1 to 4 of the card), from the axioms only.
Let `hS n k` be the reduced group h̃_k(S^n) of a homology theory, `hR n k` the relative group
h_k(D^n, S^(n-1)), and `hB n k` the reduced group h̃_k(D^n). Suppose the axioms give:
the disc squashes to a point, so every reduced group of the disc is 0 (homotopy axiom);
the pair (D^(n+1), S^n) has the exact sequence
h̃_(k+1)(D) → h_(k+1)(D, S) → h̃_k(S) → h̃_k(D), ending in h̃_0(D) → h_0(D, S) → 0
(exactness axiom, groups in negative dimensions being 0);
h̃_k(S^(n+1)) ≅ h_k(D^(n+1), S^n) (Step 3: a cap squashes, then excision);
and two points have reduced h̃_0(S^0) = ℤ and nothing else (dimension axiom and additivity).
Then every sphere S^n has reduced group ℤ in dimension n and 0 in every other dimension. -/
theorem reduced_sphere_homology_from_axioms
    (hS hR hB : ℕ → ℕ → Type)
    [∀ n k, AddCommGroup (hS n k)] [∀ n k, AddCommGroup (hR n k)]
    [∀ n k, AddCommGroup (hB n k)]
    (disc_contractible : ∀ n k, Subsingleton (hB n k))
    (j : ∀ n k, hB (n + 1) (k + 1) →+ hR (n + 1) (k + 1))
    (bd : ∀ n k, hR (n + 1) (k + 1) →+ hS n k)
    (i : ∀ n k, hS n k →+ hB (n + 1) k)
    (exact_at_pair : ∀ n k, Function.Exact (j n k) (bd n k))
    (exact_at_rim : ∀ n k, Function.Exact (bd n k) (i n k))
    (j₀ : ∀ n, hB (n + 1) 0 →+ hR (n + 1) 0)
    (exact_at_end : ∀ n, Function.Surjective (j₀ n))
    (excision : ∀ n k, Nonempty (hS (n + 1) k ≃+ hR (n + 1) k))
    (two_points : Nonempty (hS 0 0 ≃+ ℤ))
    (two_points_higher : ∀ k, k ≠ 0 → Subsingleton (hS 0 k)) :
    ∀ n k, (k = n → Nonempty (hS n k ≃+ ℤ)) ∧ (k ≠ n → Subsingleton (hS n k)) := by
  intro n
  induction n with
  | zero =>
    intro k
    refine ⟨fun hk => hk ▸ two_points, fun hk => two_points_higher k hk⟩
  | succ n ih =>
    intro k
    obtain ⟨e⟩ := excision n k
    cases k with
    | zero =>
      have hsurj := exact_at_end n
      have : Subsingleton (hR (n + 1) 0) := by
        constructor
        intro a b
        obtain ⟨a', rfl⟩ := hsurj a
        obtain ⟨b', rfl⟩ := hsurj b
        rw [Subsingleton.elim a' b']
      refine ⟨fun h => absurd h (by omega), fun _ => e.injective.subsingleton⟩
    | succ k =>
      have hinj : Function.Injective (bd n k) := by
        rw [injective_iff_map_eq_zero]
        intro a ha
        obtain ⟨b, rfl⟩ := (exact_at_pair n k a).1 ha
        rw [Subsingleton.elim b 0, map_zero]
      have hsurj : Function.Surjective (bd n k) := by
        intro a
        exact (exact_at_rim n k a).1 (Subsingleton.elim _ _)
      let f : hR (n + 1) (k + 1) ≃+ hS n k := AddEquiv.ofBijective (bd n k) ⟨hinj, hsurj⟩
      have e' : hS (n + 1) (k + 1) ≃+ hS n k := e.trans f
      refine ⟨fun h => ?_, fun h => ?_⟩
      · obtain ⟨g⟩ := (ih k).1 (by omega)
        exact ⟨e'.trans g⟩
      · have := (ih k).2 (by omega)
        exact e'.injective.subsingleton

/-- Singular homology obeys the dimension axiom: the one-point space has singular homology
ℤ in dimension 0 and 0 in every other dimension. -/
theorem singular_homology_dimension_axiom :
    Nonempty ((((singularHomologyFunctor AddCommGrpCat.{0} 0).obj (AddCommGrpCat.of ℤ)).obj
        (TopCat.of PUnit.{1})) ≅ AddCommGrpCat.of ℤ) ∧
    ∀ n : ℕ, n ≠ 0 →
      IsZero (((singularHomologyFunctor AddCommGrpCat.{0} n).obj (AddCommGrpCat.of ℤ)).obj
        (TopCat.of PUnit.{1})) := by
  have : PathConnectedSpace (TopCat.of PUnit.{1}) :=
    ⟨⟨PUnit.unit⟩, fun x y => by cases x; cases y; exact Joined.refl _⟩
  refine ⟨⟨asIso (TopCat.singularHomology₀ε (TopCat.of PUnit.{1}) (AddCommGrpCat.of ℤ))⟩, ?_⟩
  intro n hn
  exact isZero_singularHomologyFunctor_of_totallyDisconnectedSpace _ n _ _ hn

/-- Singular homology obeys the homotopy axiom: if two continuous maps f and g are homotopic,
they give the same map f_* = g_* on singular homology with whole-number coefficients,
in every dimension. -/
theorem singular_homology_homotopy_axiom {X Y : TopCat.{0}} (f g : X ⟶ Y)
    (hfg : ContinuousMap.Homotopic f.hom g.hom) (n : ℕ) :
    ((singularHomologyFunctor AddCommGrpCat.{0} n).obj (AddCommGrpCat.of ℤ)).map f =
      ((singularHomologyFunctor AddCommGrpCat.{0} n).obj (AddCommGrpCat.of ℤ)).map g := by
  obtain ⟨H⟩ := hfg
  exact TopCat.Homotopy.congr_homologyMap_singularChainComplexFunctor (f := f) (g := g) H _ n

-- The dome: 42 joints, 120 struts, 80 panels; Euler characteristic 2 = 1 - 0 + 1 (ℤ, 0, ℤ).
example : (42 : ℤ) - 120 + 80 = 2 := by norm_num
example : (42 : ℤ) - 120 + 80 = 1 - 0 + 1 := by norm_num
-- Dome less 3 panels collapses to 8 joints and 9 struts: loops 9 - 8 + 1 = 2, so β₁ = 2.
example : (9 : ℤ) - 8 + 1 = 2 := by norm_num
-- Its Euler characteristic matches ℤ, ℤ², 0, with 77 panels kept.
example : (42 : ℤ) - 120 + 77 = 1 - 2 + 0 := by norm_num

#print axioms reduced_sphere_homology_from_axioms
#print axioms singular_homology_dimension_axiom
#print axioms singular_homology_homotopy_axiom
