-- Boolean algebra: the subsets of any fixed universe, ordered by "is inside", form a lattice whose meet is intersection and join is union, with distributivity both ways and a complement for every set; in every Boolean algebra the light rule distributes and De Morgan gives its off rule; and a complement is unique.
import Mathlib.Order.Bounds.Basic
import Mathlib.Order.BooleanAlgebra.Set
import Mathlib.Data.Fintype.Powerset
import Mathlib.Data.Fintype.Prod
import Mathlib.NumberTheory.Divisors

/-- The subsets of a fixed universe α, ordered by "is inside", are a Boolean algebra drawn
as a lattice: the intersection of two sets is their greatest lower bound (the meet), the
union their least upper bound (the join); the empty set is the bottom and the whole
universe the top; union spreads across intersection and intersection across union; and
every set's complement meets it at the empty set and joins it at the whole universe. -/
theorem subsets_form_boolean_lattice {α : Type*} :
    (∀ A B : Set α, IsGLB ({A, B} : Set (Set α)) (A ∩ B)) ∧
    (∀ A B : Set α, IsLUB ({A, B} : Set (Set α)) (A ∪ B)) ∧
    (∀ A : Set α, ∅ ⊆ A ∧ A ⊆ Set.univ) ∧
    (∀ A B C : Set α, A ∪ (B ∩ C) = (A ∪ B) ∩ (A ∪ C)) ∧
    (∀ A B C : Set α, A ∩ (B ∪ C) = (A ∩ B) ∪ (A ∩ C)) ∧
    (∀ A : Set α, A ∩ Aᶜ = ∅ ∧ A ∪ Aᶜ = Set.univ) := by
  refine ⟨fun A B => isGLB_pair, fun A B => isLUB_pair,
    fun A => ⟨Set.empty_subset A, Set.subset_univ A⟩,
    fun A B C => Set.union_inter_distrib_left A B C,
    fun A B C => Set.inter_union_distrib_left A B C,
    fun A => ⟨Set.inter_compl_self A, Set.union_compl_self A⟩⟩

/-- The porch-light rule in any Boolean algebra (truth values, subsets of a universe,
switch networks): "(M and D) or O" equals "(M or O) and (D or O)", the override
multiplied into both halves; and by De Morgan the light is off exactly when
"(not M or not D) and not O". -/
theorem light_rule_distributes_and_de_morgan {α : Type*} [BooleanAlgebra α] (m d o : α) :
    (m ⊓ d) ⊔ o = (m ⊔ o) ⊓ (d ⊔ o) ∧ ((m ⊓ d) ⊔ o)ᶜ = (mᶜ ⊔ dᶜ) ⊓ oᶜ := by
  refine ⟨sup_inf_right m d o, ?_⟩
  rw [compl_sup, compl_inf]

/-- A complement is unique: in a lattice with a bottom and a top where meet and join
spread across each other, if B and C both meet A at the bottom and join it at the top,
then B and C are the same element. -/
theorem complement_is_unique {α : Type*} [DistribLattice α] [BoundedOrder α] (a b c : α)
    (hb : a ⊓ b = ⊥) (hb' : a ⊔ b = ⊤) (hc : a ⊓ c = ⊥) (hc' : a ⊔ c = ⊤) : b = c := by
  exact IsCompl.right_unique ⟨disjoint_iff.mpr hb, codisjoint_iff.mpr hb'⟩
    ⟨disjoint_iff.mpr hc, codisjoint_iff.mpr hc'⟩

/-! ### The card's worked numbers -/

-- The rule at MDO = 110: (1 and 1) or 0 = 1; distributed, (1 or 0) and (1 or 0) = 1;
-- the off rule there, (0 or 0) and 1 = 0.
example : ((true && true) || false) = true := by decide
example : ((true || false) && (true || false)) = true := by decide
example : ((!true || !true) && !false) = false := by decide

-- On all eight rows the two forms agree, and the off rule is the flip of the rule.
example : ∀ m d o : Bool, ((m && d) || o) = ((m || o) && (d || o)) := by decide
example : ∀ m d o : Bool, ((!m || !d) && !o) = !((m && d) || o) := by decide

-- Eight rows; the light is on in 5 and off in 3.
example : Fintype.card (Bool × Bool × Bool) = 8 := by decide
example : (Finset.univ.filter
    (fun r : Bool × Bool × Bool => ((r.1 && r.2.1) || r.2.2) = true)).card = 5 := by decide
example : (Finset.univ.filter
    (fun r : Bool × Bool × Bool => ((!r.1 || !r.2.1) && !r.2.2) = true)).card = 3 := by decide

-- The three off rows: override down and no motion or a lit room (MDO = 000, 010, 100).
example : Finset.univ.filter
    (fun r : Bool × Bool × Bool => ((!r.1 || !r.2.1) && !r.2.2) = true) =
    {(false, false, false), (false, true, false), (true, false, false)} := by decide

-- Subsets of U = {a, b, c}, with a, b, c as 0, 1, 2: the cube has 8 vertices.
example : Fintype.card (Finset (Fin 3)) = 8 := by decide

-- 12 upward edges, each adding one member.
example : ((Finset.univ : Finset (Finset (Fin 3) × Finset (Fin 3))).filter
    (fun p => p.1 ⊆ p.2 ∧ (p.2 \ p.1).card = 1)).card = 12 := by decide

-- 28 pairs of different subsets, 19 comparable and 9 not (ordered pairs count each twice).
example : ((Finset.univ : Finset (Finset (Fin 3) × Finset (Fin 3))).filter
    (fun p => p.1 ≠ p.2)).card = 2 * 28 := by decide
example : ((Finset.univ : Finset (Finset (Fin 3) × Finset (Fin 3))).filter
    (fun p => p.1 ≠ p.2 ∧ (p.1 ⊆ p.2 ∨ p.2 ⊆ p.1))).card = 2 * 19 := by decide
example : ((Finset.univ : Finset (Finset (Fin 3) × Finset (Fin 3))).filter
    (fun p => ¬ p.1 ⊆ p.2 ∧ ¬ p.2 ⊆ p.1)).card = 2 * 9 := by decide

-- A = {a, b}, B = {b, c}: neither is inside the other; meet {b}, join {a, b, c},
-- and the complement of {a, b} inside U is {c}; the complement of the empty set is U.
example : ¬ ({0, 1} : Finset (Fin 3)) ⊆ {1, 2} ∧ ¬ ({1, 2} : Finset (Fin 3)) ⊆ {0, 1} := by
  decide
example : ({0, 1} : Finset (Fin 3)) ∩ {1, 2} = {1} := by decide
example : ({0, 1} : Finset (Fin 3)) ∪ {1, 2} = Finset.univ := by decide
example : ({0, 1} : Finset (Fin 3))ᶜ = {2} := by decide
example : (∅ : Finset (Fin 3))ᶜ = Finset.univ := by decide

-- Meet by search agrees with intersection on all 64 pairs: a set lies below both A and B
-- exactly when it lies inside A ∩ B; likewise above both exactly when it contains A ∪ B.
example : ∀ A B S : Finset (Fin 3), (S ⊆ A ∧ S ⊆ B ↔ S ⊆ A ∩ B) := by decide
example : ∀ A B S : Finset (Fin 3), (A ⊆ S ∧ B ⊆ S ↔ A ∪ B ⊆ S) := by decide

-- The usual mistakes, counted on the eight rows.
-- The join read as "exactly one": 1 row wrong, MDO = 111.
example : Finset.univ.filter (fun r : Bool × Bool × Bool =>
    xor (r.1 && r.2.1) r.2.2 ≠ ((r.1 && r.2.1) || r.2.2)) = {(true, true, true)} := by decide
-- A meet reversed term by term: 2 rows wrong, MDO = 010 and 100.
example : Finset.univ.filter (fun r : Bool × Bool × Bool =>
    ((!r.1 && !r.2.1) && !r.2.2) ≠ ((!r.1 || !r.2.1) && !r.2.2)) =
    {(false, true, false), (true, false, false)} := by decide
-- The override dropped from the second bracket: 2 rows wrong, MDO = 001 and 101.
example : Finset.univ.filter (fun r : Bool × Bool × Bool =>
    ((r.1 || r.2.2) && r.2.1) ≠ ((r.1 && r.2.1) || r.2.2)) =
    {(false, false, true), (true, false, true)} := by decide

-- Not every lattice is Boolean: on the divisors of 12 (meet gcd, join lcm, bottom 1,
-- top 12), neither 2 nor 6 has an opposite.
example : ¬ ∃ c ∈ Nat.divisors 12, Nat.gcd 2 c = 1 ∧ Nat.lcm 2 c = 12 := by decide
example : ¬ ∃ c ∈ Nat.divisors 12, Nat.gcd 6 c = 1 ∧ Nat.lcm 6 c = 12 := by decide

#print axioms subsets_form_boolean_lattice
#print axioms light_rule_distributes_and_de_morgan
#print axioms complement_is_unique
