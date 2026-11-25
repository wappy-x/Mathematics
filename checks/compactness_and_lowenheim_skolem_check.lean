-- Compactness and Lowenheim-Skolem: a first-order theory has a model exactly when every finite part of it has one, a countable theory with an infinite model has models of every infinite size, and an infinite graph whose finite parts are k-colourable is k-colourable.
import Mathlib.ModelTheory.Satisfiability
import Mathlib.Combinatorics.SimpleGraph.Coloring.Vertex
import Mathlib.Tactic.NormNum
import Mathlib.Combinatorics.Compactness

open FirstOrder FirstOrder.Language Cardinal

universe u v w w'

/-- The compactness theorem: a set of first-order sentences `T` has a model exactly when
every finite batch `T0` of sentences taken from `T` has a model. -/
theorem compactness {L : Language.{u, v}} (T : L.Theory) :
    T.IsSatisfiable ↔
      ∀ T0 : Finset L.Sentence, (T0 : L.Theory) ⊆ T → Theory.IsSatisfiable (T0 : L.Theory) := by
  exact Theory.isSatisfiable_iff_isFinitelySatisfiable

/-- The Lowenheim-Skolem theorem: if a theory `T` in a countable language has one infinite
model `M`, then for every infinite size `κ` it has a model of size exactly `κ`. -/
theorem lowenheim_skolem {L : Language.{u, v}} [Countable L.Symbols] (T : L.Theory)
    (M : Type w') [L.Structure M] [M ⊨ T] [Infinite M]
    (κ : Cardinal.{w}) (hκ : ℵ₀ ≤ κ) :
    ∃ N : T.ModelType.{u, v, w}, #N = κ := by
  have hL : Cardinal.lift.{w} L.card ≤ Cardinal.lift.{max u v} κ := by
    have h0 : L.card ≤ ℵ₀ := Cardinal.mk_le_aleph0
    have h1 : Cardinal.lift.{w} L.card ≤ ℵ₀ := by
      simpa using Cardinal.lift_le.{w}.2 h0
    have h2 : ℵ₀ ≤ Cardinal.lift.{max u v} κ := by
      simpa using Cardinal.lift_le.{max u v}.2 hκ
    exact h1.trans h2
  obtain ⟨N, hMN, hN⟩ := exists_elementarilyEquivalent_card_eq L M κ hκ hL
  have : Nonempty N := hMN.nonempty
  have : N ⊨ T := hMN.theory_model
  exact ⟨Theory.ModelType.of T N, hN⟩

/-- The de Bruijn-Erdos theorem: if every finite part of a graph (a map, with touching regions
joined) can be properly coloured with `k` colours, then the whole graph can. -/
theorem de_bruijn_erdos {V : Type*} (G : SimpleGraph V) (k : ℕ)
    (h : ∀ s : Finset V, (G.induce (s : Set V)).Colorable k) :
    G.Colorable k := by
  classical
  obtain ⟨χ, hχ⟩ := Finset.rado_selection_subtype (β := fun _ : V => Fin k)
    (fun s x => (h s).some x)
  refine ⟨SimpleGraph.Coloring.mk χ ?_⟩
  intro u v huv
  obtain ⟨t, hst, ht⟩ := hχ {u, v}
  have hu := ht ⟨u, by simp⟩
  have hv := ht ⟨v, by simp⟩
  simp only at hu hv
  rw [hu, hv]
  apply (h t).some.valid
  simpa using huv

-- Worked numbers from the card.
-- Witness for the first 1,000 axioms c > 0, ..., c > 999: c = 999 + 1 = 1,000.
example : 999 + 1 = 1000 := by norm_num
example : ∀ n : ℕ, n < 1000 → 999 + 1 > n := by norm_num
-- Witness for the batch 3, 17, 999, 123,456: c = 123,457.
example : 123456 + 1 = 123457 ∧ 123457 > 3 ∧ 123457 > 17 ∧ 123457 > 999 ∧ 123457 > 123456 := by
  norm_num
-- c = 1,000 fails the axiom c > 1,000.
example : ¬ (1000 > 1000) := by decide
-- Colourings of one 2 × 2 block: 4 × 3 × 2 × 1 = 24.
example : 4 * 3 * 2 * 1 = 24 := by norm_num
-- Colourings of the n × n box, 24(2^(n-1) - 1), for n = 2, 3, 4, 5.
example : 24 * (2 ^ (2 - 1) - 1) = 24 := by norm_num
example : 24 * (2 ^ (3 - 1) - 1) = 72 := by norm_num
example : 24 * (2 ^ (4 - 1) - 1) = 168 := by norm_num
example : 24 * (2 ^ (5 - 1) - 1) = 360 := by norm_num
-- Height of x^2 - 2: degree 2 plus 1 + 0 + 2.
example : 2 + (1 + 0 + 2) = 5 := by norm_num
-- Polynomials of height 5 with positive leading coefficient, by degree 1, 2, 3, 4.
example : 7 + 13 + 7 + 1 = 28 := by norm_num

#print axioms compactness
#print axioms lowenheim_skolem
#print axioms de_bruijn_erdos
