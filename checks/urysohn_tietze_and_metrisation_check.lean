-- Urysohn and Tietze: a normal space has a continuous dial from 0 to 1 between any two disjoint closed sets, a bounded continuous reading on a closed set extends to the whole space, and a regular space with closed points and a countable basis is metrisable.
import Mathlib.Topology.UrysohnsLemma
import Mathlib.Topology.TietzeExtension
import Mathlib.Topology.Metrizable.Urysohn

open Set

/-- **Urysohn's lemma.** In a normal space, for two closed sets `A` and `B` that share no point,
there is a continuous dial `f : X → [0, 1]` that reads 0 on `A` and 1 on `B`. -/
theorem urysohn_dial_between_disjoint_closed_sets {X : Type*} [TopologicalSpace X] [NormalSpace X]
    {A B : Set X} (hA : IsClosed A) (hB : IsClosed B) (hAB : Disjoint A B) :
    ∃ f : X → ℝ, Continuous f ∧ (∀ x, f x ∈ Icc (0 : ℝ) 1) ∧
      (∀ x ∈ A, f x = 0) ∧ (∀ x ∈ B, f x = 1) := by
  obtain ⟨f, h0, h1, hI⟩ := exists_continuous_zero_one_of_isClosed hA hB hAB
  exact ⟨f, f.continuous, hI, fun x hx => h0 hx, fun x hx => h1 hx⟩

/-- **Tietze's extension theorem.** In a normal space, a continuous reading `g : A → [-1, 1]`
on a closed set `A` extends to a continuous `F : X → [-1, 1]` that agrees with `g` on `A`. -/
theorem tietze_extension_of_closed_set {X : Type*} [TopologicalSpace X] [NormalSpace X]
    {A : Set X} (hA : IsClosed A) (g : A → ℝ) (hg : Continuous g)
    (hg1 : ∀ a, g a ∈ Icc (-1 : ℝ) 1) :
    ∃ F : X → ℝ, Continuous F ∧ (∀ x, F x ∈ Icc (-1 : ℝ) 1) ∧ ∀ a : A, F a = g a := by
  obtain ⟨F, hF, hFg⟩ := ContinuousMap.exists_restrict_eq_forall_mem_of_closed
    (⟨g, hg⟩ : C(A, ℝ)) hg1 ⟨0, by norm_num⟩ hA
  exact ⟨F, F.continuous, hF, fun a => congrArg (fun k : C(A, ℝ) => k a) hFg⟩

/-- **Urysohn's metrisation theorem.** A space that is regular, whose single points are closed,
and that has a countable basis is metrisable: some distance gives exactly its open sets. -/
theorem urysohn_metrisation {X : Type*} [TopologicalSpace X] [RegularSpace X] [T1Space X]
    [SecondCountableTopology X] : TopologicalSpace.MetrizableSpace X := by
  infer_instance

/-! The card's worked numbers, checked exactly. -/

-- The dial at P = (3, 1): 3 m to the west wall, (24 - 4·3 - 3·1)/5 = 9/5 m to the far wall, dial 5/8.
example : (24 - 4 * 3 - 3 * 1 : ℚ) / 5 = 9 / 5 := by norm_num
example : (3 : ℚ) / (3 + 9 / 5) = 5 / 8 := by norm_num

/-- The three tent dials on the glued circle, at `t = j/24`, in twelfths, peaked at 0, 1/3, 2/3. -/
def circleDials (j : ℕ) : List ℕ :=
  [0, 8, 16].map fun c => 12 - min ((j + 24 - c) % 24) ((c + 24 - j) % 24)

/-- The dial distance `D` with weights 1/2, 1/4, 1/8, in 96ths. -/
def dialDist (i j : ℕ) : ℕ :=
  ((List.zip [4, 2, 1] (List.zip (circleDials i) (circleDials j))).map
    fun p => p.1 * ((p.2.1 - p.2.2) + (p.2.2 - p.2.1))).sum

/-- Arc length on the glued circle, in 24ths of a turn. -/
def arcDist (i j : ℕ) : ℕ := min ((i + 24 - j) % 24) ((j + 24 - i) % 24)

-- Dial readings at t = 1/24 and t = 23/24 are [11, 5, 3] and [11, 3, 5] twelfths.
example : circleDials 1 = [11, 5, 3] := by decide
example : circleDials 23 = [11, 3, 5] := by decide
-- D(1/24, 23/24) = 6/96 = 1/16 and D(1/4, 3/4) = 24/96 = 1/4.
example : dialDist 1 23 = 6 := by decide
example : dialDist 6 18 = 24 := by decide
-- On all pairs of 24 points, D is zero only on the diagonal, symmetric, and
-- D / arc length runs from 1/2 to 7/4 (D in 96ths, arc in 24ths: 2·arc ≤ D ≤ 7·arc).
example : ∀ i < 24, ∀ j < 24, i ≠ j → 0 < dialDist i j := by decide
example : ∀ i < 24, ∀ j < 24, dialDist i j = dialDist j i := by decide
example : ∀ i < 24, ∀ j < 24, 2 * arcDist i j ≤ dialDist i j ∧ dialDist i j ≤ 7 * arcDist i j := by decide
example : dialDist 6 18 = 2 * arcDist 6 18 := by decide
-- The triangle inequality on all 13,824 triples of the 24 points.
example : ∀ i < 24, ∀ j < 24, ∀ k < 24, dialDist i k ≤ dialDist i j + dialDist j k := by decide

#print axioms urysohn_dial_between_disjoint_closed_sets
#print axioms tietze_extension_of_closed_set
#print axioms urysohn_metrisation
