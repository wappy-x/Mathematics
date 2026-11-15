-- Closure, interior and boundary: the open-set definitions of closure, interior and boundary agree with each other, and the rationals are dense in the real line with empty interior.
import Mathlib.Topology.Closure
import Mathlib.Topology.Instances.Irrational
import Mathlib.Tactic.NormNum

/-- In any topological space, the interior of `A` is the union of the open sets inside `A`;
the closure of `A` is the set of points every open set around which meets `A`, and it equals
the overlap of the closed sets holding `A` and the outside of the interior of the outside;
and the boundary is the closure minus the interior. -/
theorem closure_interior_boundary_from_open_sets {X : Type*} [TopologicalSpace X]
    (A : Set X) :
    interior A = ⋃₀ {U | IsOpen U ∧ U ⊆ A} ∧
    closure A = {x | ∀ U : Set X, IsOpen U → x ∈ U → (U ∩ A).Nonempty} ∧
    closure A = ⋂₀ {C | IsClosed C ∧ A ⊆ C} ∧
    (closure A)ᶜ = interior Aᶜ ∧
    frontier A = closure A \ interior A := by
  refine ⟨rfl, ?_, rfl, interior_compl.symm, rfl⟩
  ext x
  exact mem_closure_iff

/-- The boundary of `A` is the closure of `A` met with the closure of its outside; the closure
of `A` is `A` together with its limit points (points every open set around which meets `A`
somewhere other than the point itself); and `A` is dense exactly when every non-empty open
set meets it. -/
theorem boundary_limit_points_and_dense {X : Type*} [TopologicalSpace X] (A : Set X) :
    frontier A = closure A ∩ closure Aᶜ ∧
    closure A = A ∪ {x | ∀ U : Set X, IsOpen U → x ∈ U → (U ∩ (A \ {x})).Nonempty} ∧
    (Dense A ↔ ∀ U : Set X, IsOpen U → U.Nonempty → (U ∩ A).Nonempty) := by
  refine ⟨frontier_eq_closure_inter_closure, ?_, dense_iff_inter_open⟩
  ext x
  constructor
  · intro hx
    by_cases hxA : x ∈ A
    · exact Or.inl hxA
    · refine Or.inr fun U hU hxU => ?_
      obtain ⟨y, hyU, hyA⟩ := mem_closure_iff.mp hx U hU hxU
      refine ⟨y, hyU, hyA, ?_⟩
      rintro rfl
      exact hxA hyA
  · rintro (hxA | hx)
    · exact subset_closure hxA
    · refine mem_closure_iff.mpr fun U hU hxU => ?_
      obtain ⟨y, hyU, hyA, -⟩ := hx U hU hxU
      exact ⟨y, hyU, hyA⟩

/-- Every band of the real line from `s` to `t` holds a fraction and a non-fraction, so the
fractions are dense in the line, have empty interior, and have the whole line as boundary. -/
theorem rationals_dense_with_empty_interior :
    (∀ s t : ℝ, s < t →
      (∃ q : ℚ, s < (q : ℝ) ∧ (q : ℝ) < t) ∧ (∃ x : ℝ, Irrational x ∧ s < x ∧ x < t)) ∧
    Dense (Set.range ((↑) : ℚ → ℝ)) ∧
    interior (Set.range ((↑) : ℚ → ℝ)) = ∅ ∧
    frontier (Set.range ((↑) : ℚ → ℝ)) = Set.univ := by
  have hdense : Dense (Set.range ((↑) : ℚ → ℝ)) := Rat.denseRange_cast
  have hint : interior (Set.range ((↑) : ℚ → ℝ)) = ∅ := by
    rw [interior_eq_empty_iff_dense_compl]
    exact dense_irrational
  refine ⟨fun s t hst => ⟨exists_rat_btwn hst, exists_irrational_btwn hst⟩, hdense, hint, ?_⟩
  rw [frontier, hdense.closure_eq, hint, Set.sdiff_empty]

-- Root 2 lies in the band from 1414/1000 to 1415/1000 metres.
example : (1414 / 1000 : ℚ) ^ 2 = 1999396 / 1000000 ∧ (1415 / 1000 : ℚ) ^ 2 = 2002225 / 1000000 ∧
    (1414 / 1000 : ℚ) ^ 2 < 2 ∧ 2 < (1415 / 1000 : ℚ) ^ 2 := by norm_num

-- Step 5 on that band: n = 1001 exceeds 1/width = 1000; n * s = 1415414/1000, whole part 1415; m = 1416.
example : (1 : ℚ) / (1415 / 1000 - 1414 / 1000) = 1000 ∧ 1001 * 1414 = 1415414 ∧
    1415414 / 1000 = 1415 := by norm_num

-- Step 5's fraction 1416/1001 and the simplest fraction 58/41 both lie in the band.
example : (1414 / 1000 : ℚ) < 1416 / 1001 ∧ (1416 / 1001 : ℚ) < 1415 / 1000 ∧
    (1414 / 1000 : ℚ) < 58 / 41 ∧ (58 / 41 : ℚ) < 1415 / 1000 := by norm_num

-- No fraction p/q with bottom q below 41 lies strictly between 1414/1000 and 1415/1000.
example : ∀ q < 41, ∀ p < 2 * q + 1, ¬ (1414 * q < 1000 * p ∧ 1000 * p < 1415 * q) := by
  decide

-- The band a millionth of a millionth wide still holds a fraction, 2273378/1607521.
example : (1414213562373 / 1000000000000 : ℚ) < 2273378 / 1607521 ∧
    (2273378 / 1607521 : ℚ) < 1414213562374 / 1000000000000 := by norm_num

-- What breaks: (3/5, 4/5) pushed out by 1/2000 lands off the unit circle.
example : (3 / 5 * (2001 / 2000) : ℚ) ^ 2 + (4 / 5 * (2001 / 2000)) ^ 2 = 4004001 / 4000000 ∧
    (4004001 / 4000000 : ℚ) ≠ 1 := by norm_num

#print axioms closure_interior_boundary_from_open_sets
#print axioms boundary_limit_points_and_dense
#print axioms rationals_dense_with_empty_interior
