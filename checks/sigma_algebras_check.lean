-- Sigma-algebras: the sets any record settles always form a sigma-algebra, on a finite space every sigma-algebra is what some record settles, and a finite sigma-algebra with k blocks has exactly 2^k sets.
import Mathlib.MeasureTheory.MeasurableSpace.Constructions
import Mathlib.Combinatorics.Enumerative.Bell
import Mathlib.SetTheory.Cardinal.Finite

open Set MeasureTheory

universe u v

/-- A set `A` of outcomes is settled by a report (a rule sending each outcome to a message) when
two outcomes with the same message are either both in `A` or both out of it. -/
def SettledBy {Ω : Type u} {M : Type v} (report : Ω → M) (A : Set Ω) : Prop :=
  ∀ ω ω', report ω = report ω' → (ω ∈ A ↔ ω' ∈ A)

/-- Helper: on a finite space, a set is measurable exactly when it is settled by the
measurable-atom report. -/
theorem measurableSet_iff_settledBy_measurableAtom {Ω : Type u} [Finite Ω] [MeasurableSpace Ω]
    (A : Set Ω) : MeasurableSet A ↔ SettledBy (measurableAtom : Ω → Set Ω) A := by
  constructor
  · intro hA ω ω' h
    constructor
    · intro hω
      have hsub := measurableAtom_subset hA hω
      rw [h] at hsub
      exact hsub (mem_measurableAtom_self ω')
    · intro hω'
      have hsub := measurableAtom_subset hA hω'
      rw [← h] at hsub
      exact hsub (mem_measurableAtom_self ω)
  · intro hS
    have hA : A = ⋃ ω ∈ A, measurableAtom ω := by
      ext x
      simp only [mem_iUnion]
      constructor
      · intro hx
        exact ⟨x, hx, mem_measurableAtom_self x⟩
      · rintro ⟨ω, hω, hx⟩
        exact (hS x ω (measurableAtom_eq_of_mem hx)).2 hω
    rw [hA]
    exact MeasurableSet.biUnion (Set.to_countable A)
      (fun ω _ => MeasurableSet.measurableAtom_of_countable ω)

/-- The questions any record can settle always form a sigma-algebra, on any space, finite or not:
for every report there is a sigma-algebra (Mathlib's `MeasurableSpace`: contains the whole space,
the complement of each of its sets and the union of any countable list of its sets) whose
measurable sets are exactly the sets the report settles. -/
theorem settled_sets_form_sigma_algebra {Ω : Type u} {M : Type v} (report : Ω → M) :
    ∃ m : MeasurableSpace Ω, ∀ A : Set Ω, MeasurableSet[m] A ↔ SettledBy report A := by
  refine ⟨{ MeasurableSet' := SettledBy report
            measurableSet_empty := fun ω ω' _ => by simp
            measurableSet_compl := fun s hs ω ω' h => by
              simp only [mem_compl_iff]
              exact not_congr (hs ω ω' h)
            measurableSet_iUnion := fun f hf ω ω' h => by
              simp only [mem_iUnion]
              exact exists_congr (fun i => hf i ω ω' h) }, fun A => Iff.rfl⟩

/-- On a finite space, every sigma-algebra is what some record settles: there is a report whose
settled sets are exactly the measurable sets. -/
theorem finite_sigma_algebra_is_settled_by_a_record {Ω : Type u} [Finite Ω] [MeasurableSpace Ω] :
    ∃ (M : Type u) (report : Ω → M), ∀ A : Set Ω, MeasurableSet A ↔ SettledBy report A := by
  exact ⟨Set Ω, measurableAtom, measurableSet_iff_settledBy_measurableAtom⟩

/-- On a finite space, a sigma-algebra that cuts the space into `k` blocks has exactly `2 ^ k`
sets. The block of an outcome is the intersection of all measurable sets containing it
(Mathlib's `measurableAtom`), and `k` is the number of different blocks. -/
theorem finite_sigma_algebra_card_eq_two_pow_blocks {Ω : Type u} [Finite Ω] [MeasurableSpace Ω] :
    Nat.card {A : Set Ω // MeasurableSet A} =
      2 ^ Nat.card (Set.range (measurableAtom : Ω → Set Ω)) := by
  classical
  set f : Ω → Set.range (measurableAtom : Ω → Set Ω) := Set.rangeFactorization measurableAtom
    with hf
  have hfsurj : Function.Surjective f := Set.rangeFactorization_surjective
  have hmeas : ∀ T : Set (Set.range (measurableAtom : Ω → Set Ω)), MeasurableSet (f ⁻¹' T) := by
    intro T
    rw [measurableSet_iff_settledBy_measurableAtom]
    intro ω ω' h
    have h' : f ω = f ω' := Subtype.ext h
    simp only [mem_preimage, h']
  let g : Set (Set.range (measurableAtom : Ω → Set Ω)) → {A : Set Ω // MeasurableSet A} :=
    fun T => ⟨f ⁻¹' T, hmeas T⟩
  have hg : Function.Bijective g := by
    constructor
    · intro T T' h
      exact Set.preimage_injective.mpr hfsurj (congrArg Subtype.val h)
    · rintro ⟨A, hA⟩
      refine ⟨f '' A, Subtype.ext ?_⟩
      show f ⁻¹' (f '' A) = A
      apply Subset.antisymm
      · rintro x ⟨a, ha, hax⟩
        have hS := (measurableSet_iff_settledBy_measurableAtom A).1 hA
        exact (hS a x (congrArg Subtype.val hax)).1 ha
      · exact subset_preimage_image f A
  rw [← Nat.card_congr (Equiv.ofBijective g hg)]
  have : Fintype (Set.range (measurableAtom : Ω → Set Ω)) := Fintype.ofFinite _
  rw [Nat.card_eq_fintype_card, Fintype.card_set, Nat.card_eq_fintype_card]

/- The card's worked numbers. A week is three days, each rain (`true`) or dry (`false`). -/

/-- The valley station: "any rain this week". -/
def anyRain (w : Fin 3 → Bool) : Bool := decide (∃ i, w i = true)

/-- The rain-day count: how many of the three days it rained. -/
def rainDays (w : Fin 3 → Bool) : ℕ := (Finset.univ.filter (fun i => w i = true)).card

-- 2 × 2 × 2 = 8 possible weeks.
example : Fintype.card (Fin 3 → Bool) = 8 := by simp

-- The full log (the report is the week itself) settles all 256 sets of weeks.
example : (Finset.univ.filter (fun A : Finset (Fin 3 → Bool) =>
    ∀ x y, id x = id y → (x ∈ A ↔ y ∈ A))).card = 256 := by
  rw [Finset.filter_true_of_mem (fun A _ x y h => by rw [show x = y from h])]
  simp

-- The rain-day count has 4 blocks and settles 2 ^ 4 = 16 sets.
example : (Finset.univ.filter (fun A : Finset (Fin 3 → Bool) =>
    ∀ x y, rainDays x = rainDays y → (x ∈ A ↔ y ∈ A))).card = 16 := by decide

-- The valley station has 2 blocks and settles 2 ^ 2 = 4 sets.
example : (Finset.univ.filter (fun A : Finset (Fin 3 → Bool) =>
    ∀ x y, anyRain x = anyRain y → (x ∈ A ↔ y ∈ A))).card = 4 := by decide

-- "Rain on day two" is not settled by the valley station (DDR and DRD send the same line).
example : ¬ SettledBy anyRain {w : Fin 3 → Bool | w 1 = true} := by
  intro h
  have := (h ![false, true, false] ![false, false, true] (by decide)).1 rfl
  simp at this

-- Sigma-algebras on 1, 2, 3, 4 points, counted as partitions (Bell numbers): 1, 2, 5, 15.
example : Nat.bell 1 = 1 ∧ Nat.bell 2 = 2 ∧ Nat.bell 3 = 5 ∧ Nat.bell 4 = 15 := by decide +kernel

-- Sigma-algebras on the station's 8 outcomes: the Bell number 4140.
example : Nat.bell 8 = 4140 := by decide +kernel

#print axioms measurableSet_iff_settledBy_measurableAtom
#print axioms settled_sets_form_sigma_algebra
#print axioms finite_sigma_algebra_is_settled_by_a_record
#print axioms finite_sigma_algebra_card_eq_two_pow_blocks
