-- What compactness and connectedness buy: a continuous map sends compact sets to compact sets and connected sets to connected sets, so real functions reach a maximum and minimum and cross every value between, and a continuous bijection from a compact space onto a Hausdorff space is a homeomorphism.
import Mathlib.Topology.Homeomorph.Lemmas
import Mathlib.Topology.Order.Compact
import Mathlib.Topology.Order.IntermediateValue
import Mathlib.Topology.Instances.Real.Lemmas
import Mathlib.Tactic.NormNum

/-! The card's terms in Mathlib:
* compact set: `IsCompact K` (every open cover has a finite subcover);
* connected set, as the card defines it (no split into two disjoint, non-empty pieces
  that are each open in the set): `IsPreconnected C`; a connected space is `PreconnectedSpace X`;
* Hausdorff space: `T2Space Y`;
* homeomorphism: `X ≃ₜ Y`, a continuous bijection with continuous inverse. -/

/-- A continuous map sends compact sets to compact sets and connected sets to
connected sets: if `f` is continuous, then `f(K)` is compact whenever `K` is compact,
and `f(C)` is connected whenever `C` is connected. -/
theorem continuous_image_compact_and_connected
    {X Y : Type*} [TopologicalSpace X] [TopologicalSpace Y]
    (f : X → Y) (hf : Continuous f) :
    (∀ K : Set X, IsCompact K → IsCompact (f '' K)) ∧
    (∀ C : Set X, IsPreconnected C → IsPreconnected (f '' C)) := by
  exact ⟨fun K hK => hK.image hf, fun C hC => hC.image f hf.continuousOn⟩

/-- The real-valued payoffs. Extreme values: a continuous real function `h` on a
non-empty compact space reaches its maximum at some `c` and its minimum at some `d`.
Intermediate values: a continuous real function on a connected space takes every
value `y` strictly between two values `h p < y < h q` it takes. -/
theorem extreme_and_intermediate_values
    {X : Type*} [TopologicalSpace X] (h : X → ℝ) (hh : Continuous h) :
    ((CompactSpace X ∧ Nonempty X) →
        ∃ c d : X, ∀ x : X, h d ≤ h x ∧ h x ≤ h c) ∧
    (PreconnectedSpace X → ∀ (p q : X) (y : ℝ), h p < y → y < h q →
        ∃ x : X, h x = y) := by
  refine ⟨?_, ?_⟩
  · rintro ⟨_, hne⟩
    obtain ⟨c, -, hc⟩ := isCompact_univ.exists_isMaxOn Set.univ_nonempty hh.continuousOn
    obtain ⟨d, -, hd⟩ := isCompact_univ.exists_isMinOn Set.univ_nonempty hh.continuousOn
    exact ⟨c, d, fun x => ⟨hd (Set.mem_univ x), hc (Set.mem_univ x)⟩⟩
  · intro _ p q y hpy hyq
    exact intermediate_value_univ p q hh ⟨hpy.le, hyq.le⟩

/-- Free inverses: a continuous bijection `f` from a compact space `X` onto a
Hausdorff space `Y` is a homeomorphism, so its inverse is continuous with no work:
there is a homeomorphism `X ≃ₜ Y` whose underlying map is `f`. -/
theorem continuous_bijection_compact_to_hausdorff_is_homeomorph
    {X Y : Type*} [TopologicalSpace X] [TopologicalSpace Y]
    [CompactSpace X] [T2Space Y]
    (f : X → Y) (hf : Continuous f) (hbij : Function.Bijective f) :
    ∃ g : X ≃ₜ Y, ⇑g = f := by
  exact ⟨(hf.homeoOfEquivCompactToT2 (f := Equiv.ofBijective f hbij)), rfl⟩

/-! The drone's loop: the point `(E, N)` in loop radii, with `E^2 + N^2 = 1`,
flies at altitude `120 + 15E + 20N` metres. -/

-- The top, 300 m east and 400 m north, is on the loop and flies 145 m.
example : (3 / 5 : ℚ) ^ 2 + (4 / 5) ^ 2 = 1 ∧ (120 : ℚ) + 15 * (3 / 5) + 20 * (4 / 5) = 145 := by
  norm_num

-- The bottom, 300 m west and 400 m south, flies 95 m.
example : (120 : ℚ) + 15 * (-3 / 5) + 20 * (-4 / 5) = 95 := by norm_num

-- The two 120 m crossings, 400 m east 300 m south and 400 m west 300 m north, are on the loop.
example : (4 / 5 : ℚ) ^ 2 + (-3 / 5) ^ 2 = 1 ∧ (120 : ℚ) + 15 * (4 / 5) + 20 * (-3 / 5) = 120 ∧
    (120 : ℚ) + 15 * (-4 / 5) + 20 * (3 / 5) = 120 := by
  norm_num

-- The four compass points fly 140, 135, 100 and 105 m; the margin under the 150 m cloud base is 5 m.
example : (120 : ℤ) + 20 = 140 ∧ (120 : ℤ) + 15 = 135 ∧ (120 : ℤ) - 20 = 100 ∧
    (120 : ℤ) - 15 = 105 ∧ (150 : ℤ) - 145 = 5 := by
  decide

-- The slopes t = -1/3 and t = 3 solve 15(1 - t^2) + 40t = 0, the 120 m equation.
example : (15 : ℚ) * (1 - (-1 / 3) ^ 2) + 40 * (-1 / 3) = 0 ∧ (15 : ℚ) * (1 - 3 ^ 2) + 40 * 3 = 0 := by
  norm_num

#print axioms continuous_image_compact_and_connected
#print axioms extreme_and_intermediate_values
#print axioms continuous_bijection_compact_to_hausdorff_is_homeomorph
