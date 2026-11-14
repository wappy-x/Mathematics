-- Huffman coding: joining the two least likely symbols again and again gives the shortest prefix-free code, every code that can be read back has Kraft sum at most one, and its average length is at least the entropy while Huffman's is less than one bit above it.
import Mathlib.InformationTheory.Coding.KraftMcMillan
import Mathlib.InformationTheory.Coding.PrefixFree
import Mathlib.Analysis.SpecialFunctions.Log.NegMulLog
import Mathlib.Data.List.Sort
import Mathlib.InformationTheory.Coding.Kraft
import Mathlib.Algebra.BigOperators.Field
import Mathlib.Analysis.SpecialFunctions.Log.Base

open InformationTheory

namespace HuffmanCard

/-! ### Codes, as on the card

A code for `n` symbols gives symbol `i` a codeword `c i : List Bool` (`false` is the bit 0,
`true` the bit 1). -/

/-- A prefix-free code: different symbols get different codewords, and no codeword is the
start of another one (Mathlib's `IsPrefixFree`). -/
def IsPrefixFreeCode {n : ℕ} (c : Fin n → List Bool) : Prop :=
  Function.Injective c ∧ IsPrefixFree (Set.range c)

/-- A code that can be read back: different symbols get different codewords, and two different
messages never send the same bits (Mathlib's `IsUniquelyDecodable`). -/
def CanBeReadBack {n : ℕ} (c : Fin n → List Bool) : Prop :=
  Function.Injective c ∧ IsUniquelyDecodable (Set.range c)

/-- The average codeword length `L = ∑ pᵢ ℓᵢ`. -/
noncomputable def avgLength {n : ℕ} (p : Fin n → ℝ) (c : Fin n → List Bool) : ℝ :=
  ∑ i, p i * ((c i).length : ℝ)

/-- The Kraft sum `K = ∑ 2^(-ℓᵢ)` of a list of codeword lengths. -/
noncomputable def kraftSum {n : ℕ} (ℓ : Fin n → ℕ) : ℝ :=
  ∑ i, (1 / 2 : ℝ) ^ ℓ i

/-- The entropy in bits, `H = ∑ pᵢ log₂ (1/pᵢ)`. -/
noncomputable def entropyBits {n : ℕ} (p : Fin n → ℝ) : ℝ :=
  ∑ i, Real.negMulLog (p i) / Real.log 2

/-! ### Huffman's method -/

/-- A binary tree with the symbols at its leaves. -/
inductive CodeTree (n : ℕ) where
  | leaf : Fin n → CodeTree n
  | node : CodeTree n → CodeTree n → CodeTree n
  deriving DecidableEq

/-- Read the codewords down the tree: a left step writes 0, a right step writes 1. -/
def CodeTree.words {n : ℕ} : CodeTree n → List (Fin n × List Bool)
  | .leaf i => [(i, [])]
  | .node l r =>
      l.words.map (fun e => (e.1, false :: e.2)) ++ r.words.map (fun e => (e.1, true :: e.2))

/-- Huffman's joins on a list kept sorted by weight, lightest first: join the two lightest into
one node whose weight is their sum, put it back in order (after any node of equal weight, so
ties go to the older node), and repeat. `fuel` counts the joins still allowed. -/
def huffmanJoin {K : Type*} [LinearOrder K] [Add K] {n : ℕ} :
    ℕ → List (K × CodeTree n) → Option (CodeTree n)
  | _, [] => none
  | _, [(_, t)] => some t
  | 0, (_, t) :: _ :: _ => some t
  | fuel + 1, (w₁, t₁) :: (w₂, t₂) :: rest =>
      huffmanJoin fuel
        (rest.orderedInsert (fun a b => a.1 < b.1) (w₁ + w₂, CodeTree.node t₁ t₂))

/-- Huffman's tree for the weights `p`: sort the symbols by weight, then make the `n - 1` joins. -/
def huffmanTree {K : Type*} [LinearOrder K] [Add K] {n : ℕ} (p : Fin n → K) :
    Option (CodeTree n) :=
  huffmanJoin n
    (((List.finRange n).map (fun i => (p i, CodeTree.leaf i))).insertionSort
      (fun a b => a.1 ≤ b.1))

/-- Huffman's code for the weights `p`: the codeword of each symbol in Huffman's tree. -/
def huffmanCode {K : Type*} [LinearOrder K] [Add K] {n : ℕ} (p : Fin n → K) (i : Fin n) :
    List Bool :=
  match huffmanTree p with
  | none => []
  | some t => (t.words.lookup i).getD []

/-! ### Helper lemmas for the proofs -/

/-- `(1/2)^x * 2^b = 2^(b - x)` when `x ≤ b`. -/
lemma half_pow_mul (x b : ℕ) (h : x ≤ b) : (1 / 2 : ℝ) ^ x * 2 ^ b = 2 ^ (b - x) := by
  obtain ⟨d, rfl⟩ := Nat.exists_eq_add_of_le h
  rw [Nat.add_sub_cancel_left, pow_add, ← mul_assoc, ← mul_pow]
  norm_num

/-- The Kraft sum of a code that can be read back is at most one (Mathlib's Kraft–McMillan). -/
lemma kraft_of_readBack {n : ℕ} {c : Fin n → List Bool} (hc : CanBeReadBack c) :
    kraftSum (fun i => (c i).length) ≤ 1 := by
  have hS : ((Finset.univ.image c : Finset (List Bool)) : Set (List Bool)) = Set.range c := by
    ext w; simp
  have h := IsUniquelyDecodable.finsetSum_one_div_card_pow_length_le_one
    (S := Finset.univ.image c) (by rw [hS]; exact hc.2)
  rw [Finset.sum_image (fun i _ j _ hij => hc.1 hij)] at h
  simpa [kraftSum, Fintype.card_bool] using h

/-- The Kraft sum of a prefix-free code is at most one (Mathlib's Kraft inequality). -/
lemma kraft_of_prefixFree {n : ℕ} {c : Fin n → List Bool} (hc : IsPrefixFreeCode c) :
    kraftSum (fun i => (c i).length) ≤ 1 := by
  have hS : ((Finset.univ.image c : Finset (List Bool)) : Set (List Bool)) = Set.range c := by
    ext w; simp
  have h := IsPrefixFree.finsetSum_one_div_card_pow_length_le_one
    (S := Finset.univ.image c) (by rw [hS]; exact hc.2)
  rw [Finset.sum_image (fun i _ j _ hij => hc.1 hij)] at h
  simpa [kraftSum, Fintype.card_bool] using h

/-- Kraft's construction: lengths with Kraft sum at most one on a set `s` of symbols can be given
codewords on `s`, none the start of another. Built by adding symbols longest-last and picking a
free word of the right length by counting. -/
lemma kraft_construct {n : ℕ} (ℓ : Fin n → ℕ) (s : Finset (Fin n)) :
    ∑ i ∈ s, (1 / 2 : ℝ) ^ ℓ i ≤ 1 →
      ∃ c : Fin n → List Bool, (∀ i ∈ s, (c i).length = ℓ i) ∧
        ∀ i ∈ s, ∀ j ∈ s, c i <+: c j → i = j := by
  induction s using Finset.induction_on_max_value ℓ with
  | empty => intro _; exact ⟨fun _ => [], by simp, by simp⟩
  | insert a s has hmax ih =>
    intro hK
    rw [Finset.sum_insert has] at hK
    have hpos : 0 < (1 / 2 : ℝ) ^ ℓ a := by positivity
    obtain ⟨c, hlen, hpf⟩ := ih (by linarith)
    let bad : Fin n → Finset (Fin (ℓ a) → Bool) :=
      fun j => Finset.univ.filter (fun g => c j <+: List.ofFn g)
    have hbad : ∀ j ∈ s, (bad j).card ≤ 2 ^ (ℓ a - ℓ j) := by
      intro j hj
      have hcard : (Finset.univ : Finset (Fin (ℓ a - ℓ j) → Bool)).card = 2 ^ (ℓ a - ℓ j) := by
        simp
      rw [← hcard]
      refine Finset.card_le_card_of_injOn
        (fun g k => g ⟨ℓ j + k.1, by omega⟩) (fun _ _ => by simp) ?_
      intro g1 hg1 g2 hg2 heq
      simp only [bad, Finset.coe_filter, Finset.mem_univ, true_and, Set.mem_ofPred_eq] at hg1 hg2
      funext k
      by_cases hk : k.1 < ℓ j
      · have hk' : k.1 < (c j).length := by rw [hlen j hj]; exact hk
        have e1 := hg1.getElem hk'
        have e2 := hg2.getElem hk'
        simp only [List.getElem_ofFn] at e1 e2
        rw [← e1, ← e2]
      · have := congrFun heq ⟨k.1 - ℓ j, by omega⟩
        simp only at this
        have hk2 : (⟨ℓ j + (k.1 - ℓ j), by omega⟩ : Fin (ℓ a)) = k := by
          ext; simp; omega
        rw [hk2] at this
        exact this
    have hsum : ∑ j ∈ s, 2 ^ (ℓ a - ℓ j) < 2 ^ ℓ a := by
      have h1 : ((∑ j ∈ s, 2 ^ (ℓ a - ℓ j) : ℕ) : ℝ) = (∑ j ∈ s, (1 / 2 : ℝ) ^ ℓ j) * 2 ^ ℓ a := by
        push_cast
        rw [Finset.sum_mul]
        exact Finset.sum_congr rfl (fun j hj => (half_pow_mul _ _ (hmax j hj)).symm)
      have h2 : (1 / 2 : ℝ) ^ ℓ a * 2 ^ ℓ a = 1 := by rw [← mul_pow]; norm_num
      have h3 : (∑ j ∈ s, (1 / 2 : ℝ) ^ ℓ j) * 2 ^ ℓ a ≤ (1 - (1 / 2 : ℝ) ^ ℓ a) * 2 ^ ℓ a :=
        mul_le_mul_of_nonneg_right (by linarith) (by positivity)
      have : ((∑ j ∈ s, 2 ^ (ℓ a - ℓ j) : ℕ) : ℝ) < 2 ^ ℓ a := by
        rw [h1]; nlinarith
      exact_mod_cast this
    have hlt : (s.biUnion bad).card < (Finset.univ : Finset (Fin (ℓ a) → Bool)).card := by
      calc (s.biUnion bad).card ≤ ∑ j ∈ s, (bad j).card := Finset.card_biUnion_le
        _ ≤ ∑ j ∈ s, 2 ^ (ℓ a - ℓ j) := Finset.sum_le_sum hbad
        _ < 2 ^ ℓ a := hsum
        _ = _ := by simp
    obtain ⟨g, -, hg⟩ := Finset.exists_mem_notMem_of_card_lt_card hlt
    have hg' : ∀ j ∈ s, ¬ c j <+: List.ofFn g := fun j hj h =>
      hg (Finset.mem_biUnion.mpr ⟨j, hj, by simp [bad, h]⟩)
    have hne : ∀ k ∈ s, k ≠ a := fun k hk h => has (h ▸ hk)
    refine ⟨Function.update c a (List.ofFn g), ?_, ?_⟩
    · intro i hi
      rcases Finset.mem_insert.mp hi with h | hi
      · subst h; simp
      · rw [Function.update_of_ne (hne i hi), hlen i hi]
    · intro i hi j hj hij
      rcases Finset.mem_insert.mp hi with h1 | hi <;>
        rcases Finset.mem_insert.mp hj with h2 | hj
      · rw [h1, h2]
      · exfalso
        rw [h1, Function.update_self, Function.update_of_ne (hne j hj)] at hij
        have hl : (List.ofFn g).length = (c j).length :=
          le_antisymm hij.length_le (by simp [hlen j hj, hmax j hj])
        have := hij.eq_of_length hl
        exact hg' j hj (this ▸ List.prefix_refl _)
      · exfalso
        rw [h2, Function.update_self, Function.update_of_ne (hne i hi)] at hij
        exact hg' i hi hij
      · rw [Function.update_of_ne (hne i hi), Function.update_of_ne (hne j hj)] at hij
        exact hpf i hi j hj hij

/-- Gibbs' inequality in the form needed: if the lengths have Kraft sum at most one, the
average length is at least the entropy. -/
lemma entropy_le_of_kraft {n : ℕ} (p : Fin n → ℝ) (hp : ∀ i, 0 < p i) (hsum : ∑ i, p i = 1)
    (ℓ : Fin n → ℕ) (hK : ∑ i, (1 / 2 : ℝ) ^ ℓ i ≤ 1) :
    ∑ i, Real.negMulLog (p i) / Real.log 2 ≤ ∑ i, p i * (ℓ i : ℝ) := by
  have hlog2 : 0 < Real.log 2 := Real.log_pos (by norm_num)
  have key : ∀ i, Real.negMulLog (p i) - p i * ℓ i * Real.log 2 ≤ (1 / 2 : ℝ) ^ ℓ i - p i := by
    intro i
    have hpi := hp i
    have hx : 0 < (1 / 2 : ℝ) ^ ℓ i / p i := by positivity
    have h1 := Real.log_le_sub_one_of_pos hx
    rw [Real.log_div (by positivity) hpi.ne', Real.log_pow, one_div, Real.log_inv] at h1
    have h2 := mul_le_mul_of_nonneg_left h1 hpi.le
    have h3 : p i * ((2⁻¹ : ℝ) ^ ℓ i / p i - 1) = (2⁻¹ : ℝ) ^ ℓ i - p i := by
      field_simp
    rw [h3] at h2
    simp only [Real.negMulLog, one_div]
    nlinarith
  rw [← Finset.sum_div, div_le_iff₀ hlog2]
  have h := Finset.sum_le_sum (fun i (_ : i ∈ Finset.univ) => key i)
  rw [Finset.sum_sub_distrib, Finset.sum_sub_distrib, hsum] at h
  rw [Finset.sum_mul]
  linarith

/-! #### Huffman's tree: weights, costs and leaves -/

/-- The total weight of a tree's leaves. -/
noncomputable def tWeight {n : ℕ} (p : Fin n → ℝ) (t : CodeTree n) : ℝ :=
  (t.words.map (fun e => p e.1)).sum

/-- The weighted depth `∑ pᵢ ℓᵢ` over a tree's leaves. -/
noncomputable def tCost {n : ℕ} (p : Fin n → ℝ) (t : CodeTree n) : ℝ :=
  (t.words.map (fun e => p e.1 * (e.2.length : ℝ))).sum

/-- The total cost of the trees in a forest. -/
noncomputable def fCost {n : ℕ} (p : Fin n → ℝ) (F : List (ℝ × CodeTree n)) : ℝ :=
  (F.map (fun x => tCost p x.2)).sum

/-- All the symbols at the leaves of a forest. -/
def fKeys {n : ℕ} (F : List (ℝ × CodeTree n)) : List (Fin n) :=
  F.flatMap (fun x => x.2.words.map Prod.fst)

/-- The cost `∑ w λ` of a list of (weight, length) pairs. -/
noncomputable def pCost (P : List (ℝ × ℕ)) : ℝ :=
  (P.map (fun x => x.1 * (x.2 : ℝ))).sum

/-- The Kraft sum of a list of lengths. -/
noncomputable def pKraft (L : List ℕ) : ℝ :=
  (L.map (fun k => (1 / 2 : ℝ) ^ k)).sum

lemma words_node_keys {n : ℕ} (l r : CodeTree n) :
    (CodeTree.node l r).words.map Prod.fst = l.words.map Prod.fst ++ r.words.map Prod.fst := by
  simp [CodeTree.words, Function.comp_def]

lemma tWeight_node {n : ℕ} (p : Fin n → ℝ) (l r : CodeTree n) :
    tWeight p (CodeTree.node l r) = tWeight p l + tWeight p r := by
  simp [tWeight, CodeTree.words, Function.comp_def]

lemma tCost_node {n : ℕ} (p : Fin n → ℝ) (l r : CodeTree n) :
    tCost p (CodeTree.node l r) = tCost p l + tCost p r + tWeight p l + tWeight p r := by
  simp only [tCost, tWeight, CodeTree.words, List.map_append, List.map_map, List.sum_append,
    Function.comp_def, List.length_cons, Nat.cast_add, Nat.cast_one, mul_add, mul_one,
    List.sum_map_add]
  ring

lemma tWeight_nonneg {n : ℕ} (p : Fin n → ℝ) (hp : ∀ i, 0 ≤ p i) (t : CodeTree n) :
    0 ≤ tWeight p t :=
  List.sum_nonneg (by simp only [List.mem_map]; rintro _ ⟨e, -, rfl⟩; exact hp _)

lemma pCost_perm {P P' : List (ℝ × ℕ)} (h : P.Perm P') : pCost P = pCost P' :=
  (h.map _).sum_eq

lemma pKraft_perm {L L' : List ℕ} (h : L.Perm L') : pKraft L = pKraft L' :=
  (h.map _).sum_eq

lemma fCost_perm {n : ℕ} (p : Fin n → ℝ) {F F' : List (ℝ × CodeTree n)} (h : F.Perm F') :
    fCost p F = fCost p F' :=
  (h.map _).sum_eq

/-- The words of any tree: no word is the start of a different entry's word. -/
lemma words_pairwise {n : ℕ} (t : CodeTree n) :
    t.words.Pairwise (fun e e' => ¬ e.2 <+: e'.2 ∧ ¬ e'.2 <+: e.2) := by
  induction t with
  | leaf i => simp [CodeTree.words]
  | node l r ihl ihr =>
    simp only [CodeTree.words]
    rw [List.pairwise_append, List.pairwise_map, List.pairwise_map]
    refine ⟨ihl.imp ?_, ihr.imp ?_, ?_⟩
    · intro a b h; simpa using h
    · intro a b h; simpa using h
    · intro a ha b hb
      obtain ⟨e, -, rfl⟩ := List.mem_map.mp ha
      obtain ⟨e', -, rfl⟩ := List.mem_map.mp hb
      simp

/-- With distinct keys, `lookup` finds the entry. -/
lemma lookup_of_mem {n : ℕ} {β : Type*} :
    ∀ (l : List (Fin n × β)) (a : Fin n) (b : β), (l.map Prod.fst).Nodup → (a, b) ∈ l →
      l.lookup a = some b
  | [], _, _, _, h => by simp at h
  | (k, v) :: l, a, b, hnd, h => by
    rw [List.map_cons, List.nodup_cons] at hnd
    rcases List.mem_cons.mp h with h1 | h1
    · obtain ⟨rfl, rfl⟩ := Prod.mk.inj h1
      simp
    · have hak : a ≠ k := by
        intro hak
        subst hak
        exact hnd.1 (List.mem_map.mpr ⟨_, h1, rfl⟩)
      have := lookup_of_mem l a b hnd.2 h1
      rw [List.lookup_cons, beq_false_of_ne hak]
      exact this

/-- Reading the code off a tree whose leaves are the symbols, each once: it is prefix-free and
its average length is the tree's cost. -/
lemma code_props {n : ℕ} (p : Fin n → ℝ) (t : CodeTree n)
    (ht : (t.words.map Prod.fst).Perm (List.finRange n))
    (c : Fin n → List Bool) (hc : ∀ i, c i = (t.words.lookup i).getD []) :
    IsPrefixFreeCode c ∧ avgLength p c = tCost p t := by
  have hnd : (t.words.map Prod.fst).Nodup := ht.nodup_iff.mpr (List.nodup_finRange n)
  have hmem : ∀ e ∈ t.words, c e.1 = e.2 := by
    intro e he
    rw [hc, lookup_of_mem _ e.1 e.2 hnd he]
    rfl
  have hall : ∀ i, (i, c i) ∈ t.words := by
    intro i
    have : i ∈ t.words.map Prod.fst := ht.symm.subset (List.mem_finRange i)
    obtain ⟨e, he, rfl⟩ := List.mem_map.mp this
    rw [hmem e he]
    exact he
  have : Std.Symm (fun e e' : Fin n × List Bool => ¬ e.2 <+: e'.2 ∧ ¬ e'.2 <+: e.2) :=
    ⟨fun _ _ h => ⟨h.2, h.1⟩⟩
  have key : ∀ i j, c i <+: c j → i = j := by
    intro i j hij
    by_contra hne
    have := List.Pairwise.forall (words_pairwise t) (hall i) (hall j) (by simp [hne])
    exact this.1 hij
  refine ⟨⟨fun i j h => key i j (h ▸ List.prefix_refl _), ?_⟩, ?_⟩
  · rintro _ ⟨i, rfl⟩ _ ⟨j, rfl⟩ h
    rw [key i j h]
  · let g : Fin n → ℝ := fun i => p i * ((c i).length : ℝ)
    have h1 : t.words.map (fun e => p e.1 * (e.2.length : ℝ)) = (t.words.map Prod.fst).map g := by
      rw [List.map_map]
      apply List.map_congr_left
      intro e he
      simp [g, hmem e he]
    unfold avgLength tCost
    rw [h1, (ht.map g).sum_eq, Fin.sum_univ_def]

/-- `orderedInsert` keeps a list sorted by weight. -/
lemma pairwise_orderedInsert_fst {T : Type*} (r : ℝ × T → ℝ × T → Prop) [DecidableRel r]
    (x : ℝ × T) (hr1 : ∀ b, r x b → x.1 ≤ b.1) (hr2 : ∀ b, ¬ r x b → b.1 ≤ x.1) :
    ∀ l : List (ℝ × T), l.Pairwise (fun a b => a.1 ≤ b.1) →
      (l.orderedInsert r x).Pairwise (fun a b => a.1 ≤ b.1)
  | [], _ => by simp
  | b :: l, h => by
    rw [List.pairwise_cons] at h
    by_cases hxb : r x b
    · simp only [List.orderedInsert_cons, hxb, ↓reduceIte]
      refine List.Pairwise.cons ?_ (List.Pairwise.cons h.1 h.2)
      intro y hy
      rcases List.mem_cons.mp hy with hy' | hy
      · rw [hy']; exact hr1 _ hxb
      · exact le_trans (hr1 _ hxb) (h.1 y hy)
    · simp only [List.orderedInsert_cons, hxb, ↓reduceIte]
      refine List.Pairwise.cons ?_ (pairwise_orderedInsert_fst r x hr1 hr2 l h.2)
      intro y hy
      rcases List.mem_cons.mp (((List.perm_orderedInsert r x l).mem_iff).mp hy) with hy' | hy
      · rw [hy']; exact hr2 _ hxb
      · exact h.1 y hy

/-- Sorting by weight gives a list sorted by weight. -/
lemma pairwise_insertionSort_fst {T : Type*} :
    ∀ l : List (ℝ × T),
      (l.insertionSort (fun a b => a.1 ≤ b.1)).Pairwise (fun a b => a.1 ≤ b.1)
  | [] => by simp
  | x :: l => by
    rw [List.insertionSort_cons]
    exact pairwise_orderedInsert_fst _ x (fun _ h => h)
      (fun _ h => (le_total _ _).resolve_left h) _ (pairwise_insertionSort_fst l)

/-- Take one entry of weight `w` out of a list of (weight, length) pairs. -/
lemma perm_extract {P : List (ℝ × ℕ)} {w : ℝ} {R : List ℝ}
    (h : (P.map Prod.fst).Perm (w :: R)) :
    ∃ a Q, P.Perm ((w, a) :: Q) ∧ (Q.map Prod.fst).Perm R := by
  have hw : w ∈ P.map Prod.fst := h.symm.subset List.mem_cons_self
  obtain ⟨x, hx, rfl⟩ := List.mem_map.mp hw
  refine ⟨x.2, P.erase x, List.perm_cons_erase hx, ?_⟩
  have h2 : ((x :: P.erase x).map Prod.fst).Perm (x.1 :: R) :=
    ((List.perm_cons_erase hx).map Prod.fst).symm.trans h
  exact List.Perm.cons_inv h2

/-- Exchange step: give the lightest weight a length at least as long as every later one,
without raising the cost and without changing the lengths used. -/
lemma swap_aux (w₁ : ℝ) : ∀ (a : ℕ) (Q : List (ℝ × ℕ)), (∀ x ∈ Q, w₁ ≤ x.1) →
    ∃ a' Q', Q'.map Prod.fst = Q.map Prod.fst ∧
      (a' :: Q'.map Prod.snd).Perm (a :: Q.map Prod.snd) ∧
      (∀ x ∈ Q', x.2 ≤ a') ∧ w₁ * a' + pCost Q' ≤ w₁ * a + pCost Q
  | a, [], _ => ⟨a, [], rfl, List.Perm.refl _, by simp, le_rfl⟩
  | a, (w, l) :: Q, hQ => by
    obtain ⟨a'', Q'', h1, h2, h3, h4⟩ :=
      swap_aux w₁ a Q (fun x hx => hQ x (List.mem_cons_of_mem _ hx))
    have hw : w₁ ≤ w := hQ (w, l) List.mem_cons_self
    by_cases hl : l ≤ a''
    · refine ⟨a'', (w, l) :: Q'', by simp [h1], ?_, ?_, ?_⟩
      · simp only [List.map_cons]
        exact (List.Perm.swap _ _ _).trans ((h2.cons l).trans (List.Perm.swap _ _ _))
      · intro x hx
        rcases List.mem_cons.mp hx with rfl | hx
        · exact hl
        · exact h3 x hx
      · simp only [pCost, List.map_cons, List.sum_cons] at h4 ⊢
        linarith
    · push Not at hl
      refine ⟨l, (w, a'') :: Q'', by simp [h1], ?_, ?_, ?_⟩
      · simp only [List.map_cons]
        exact (h2.cons l).trans (List.Perm.swap _ _ _)
      · intro x hx
        rcases List.mem_cons.mp hx with rfl | hx
        · exact hl.le
        · exact (h3 x hx).trans hl.le
      · have hl' : (a'' : ℝ) ≤ l := by exact_mod_cast hl.le
        have : 0 ≤ (w - w₁) * ((l : ℝ) - a'') := mul_nonneg (by linarith) (by linarith)
        simp only [pCost, List.map_cons, List.sum_cons] at h4 ⊢
        nlinarith

/-- Dyadic step: if the two longest lengths are `a ≥ b`, joining them into one word of length
`b - 1` keeps the Kraft sum at most one. -/
lemma dyadic_merge (a b : ℕ) (L : List ℕ) (_hab : b ≤ a) (hL : ∀ x ∈ L, x ≤ b)
    (hK : (1 / 2 : ℝ) ^ a + (1 / 2) ^ b + pKraft L ≤ 1) :
    1 ≤ b ∧ (1 / 2 : ℝ) ^ (b - 1) + pKraft L ≤ 1 := by
  have hN : ∀ L : List ℕ, (∀ x ∈ L, x ≤ b) →
      pKraft L * 2 ^ b = ((L.map (fun x => 2 ^ (b - x))).sum : ℕ) := by
    intro L hL
    induction L with
    | nil => simp [pKraft]
    | cons x L ih =>
      have hx := hL x List.mem_cons_self
      have := ih (fun y hy => hL y (List.mem_cons_of_mem _ hy))
      simp only [pKraft, List.map_cons, List.sum_cons] at this ⊢
      rw [add_mul, this, half_pow_mul _ _ hx]
      push_cast
      ring
  set N : ℕ := (L.map (fun x => 2 ^ (b - x))).sum with hNdef
  have hNL := hN L hL
  have hpa : 0 < (1 / 2 : ℝ) ^ a := by positivity
  have h2b : (0 : ℝ) < 2 ^ b := by positivity
  have hbb : (1 / 2 : ℝ) ^ b * 2 ^ b = 1 := by rw [← mul_pow]; norm_num
  have hlt : (1 : ℝ) + N < 2 ^ b := by
    have : ((1 / 2 : ℝ) ^ b + pKraft L) * 2 ^ b < 1 * 2 ^ b :=
      mul_lt_mul_of_pos_right (by linarith) h2b
    rw [add_mul, hbb, hNL] at this
    linarith
  have hltN : 1 + N < 2 ^ b := by exact_mod_cast hlt
  have hb1 : 1 ≤ b := by
    rcases Nat.eq_zero_or_pos b with h0 | h0
    · rw [h0] at hltN; simp at hltN
    · exact h0
  refine ⟨hb1, ?_⟩
  have hb' : (1 / 2 : ℝ) ^ (b - 1) * 2 ^ b = 2 := by
    rw [half_pow_mul _ _ (Nat.sub_le b 1), Nat.sub_sub_self hb1]; norm_num
  have h2N : 2 + N ≤ 2 ^ b := by omega
  have h2N' : (2 : ℝ) + N ≤ 2 ^ b := by exact_mod_cast h2N
  have : ((1 / 2 : ℝ) ^ (b - 1) + pKraft L) * 2 ^ b ≤ 1 * 2 ^ b := by
    rw [add_mul, hb', hNL]; linarith
  exact le_of_mul_le_mul_right this h2b

/-- The exchange argument behind Huffman's method: any lengths for the two lightest weights and
the rest can be traded for lengths where the two lightest share one joined word, at no extra
cost. -/
lemma exchange (w₁ w₂ : ℝ) (a b : ℕ) (Q : List (ℝ × ℕ)) (h0 : 0 ≤ w₁) (h12 : w₁ ≤ w₂)
    (hQ : ∀ x ∈ Q, w₂ ≤ x.1)
    (hK : (1 / 2 : ℝ) ^ a + (1 / 2) ^ b + pKraft (Q.map Prod.snd) ≤ 1) :
    ∃ m : ℕ, ∃ Q' : List (ℝ × ℕ), Q'.map Prod.fst = Q.map Prod.fst ∧ (1 / 2 : ℝ) ^ m + pKraft (Q'.map Prod.snd) ≤ 1 ∧
      (w₁ + w₂) * (1 + m) + pCost Q' ≤ w₁ * a + w₂ * b + pCost Q := by
  obtain ⟨a', R1, h1, h2, h3, h4⟩ := swap_aux w₁ a ((w₂, b) :: Q) (by
    intro x hx
    rcases List.mem_cons.mp hx with rfl | hx
    · exact h12
    · exact h12.trans (hQ x hx))
  obtain ⟨⟨w', b1⟩, Q1, rfl⟩ : ∃ y Q1, R1 = y :: Q1 := by
    cases R1 with
    | nil => simp at h1
    | cons y Q1 => exact ⟨y, Q1, rfl⟩
  simp only [List.map_cons, List.cons.injEq] at h1
  obtain ⟨rfl, h1⟩ := h1
  have hQ1 : ∀ x ∈ Q1, w' ≤ x.1 := by
    intro x hx
    have : x.1 ∈ Q.map Prod.fst := h1 ▸ List.mem_map_of_mem hx
    obtain ⟨y, hy, hyx⟩ := List.mem_map.mp this
    rw [← hyx]; exact hQ y hy
  obtain ⟨b', Q2, g1, g2, g3, g4⟩ := swap_aux w' b1 Q1 hQ1
  have hb'a' : b' ≤ a' := by
    have : b' ∈ b1 :: Q1.map Prod.snd := g2.subset List.mem_cons_self
    rcases List.mem_cons.mp this with h | h
    · rw [h]; exact h3 (w', b1) List.mem_cons_self
    · obtain ⟨y, hy, rfl⟩ := List.mem_map.mp h
      exact h3 y (List.mem_cons_of_mem _ hy)
  have hperm : (a' :: b' :: Q2.map Prod.snd).Perm (a :: b :: Q.map Prod.snd) := by
    have := h2
    simp only [List.map_cons] at this
    exact (g2.cons a').trans this
  have hK2 : (1 / 2 : ℝ) ^ a' + (1 / 2) ^ b' + pKraft (Q2.map Prod.snd) ≤ 1 := by
    have := pKraft_perm hperm
    simp only [pKraft, List.map_cons, List.sum_cons] at this hK ⊢
    linarith
  obtain ⟨hb1, hK3⟩ := dyadic_merge a' b' (Q2.map Prod.snd) hb'a'
    (by intro x hx; obtain ⟨y, hy, rfl⟩ := List.mem_map.mp hx; exact g3 y hy) hK2
  refine ⟨b' - 1, Q2, g1.trans h1, hK3, ?_⟩
  have hcast : ((b' - 1 : ℕ) : ℝ) = (b' : ℝ) - 1 := by
    rw [Nat.cast_sub hb1]; simp
  have hab : (b' : ℝ) ≤ a' := by exact_mod_cast hb'a'
  rw [hcast]
  simp only [pCost, List.map_cons, List.sum_cons] at h4 g4 ⊢
  nlinarith

lemma pCost_nonneg {P : List (ℝ × ℕ)} (h : ∀ x ∈ P, 0 ≤ x.1) : 0 ≤ pCost P :=
  List.sum_nonneg (by
    simp only [List.mem_map]
    rintro _ ⟨x, hx, rfl⟩
    exact mul_nonneg (h x hx) (Nat.cast_nonneg _))

/-- What Huffman's joins produce from a sorted forest: a tree with all the forest's leaves, whose
cost is at most the forest's cost plus the cost of any lengths with Kraft sum at most one for
the forest's weights. -/
lemma huffmanJoin_spec {n : ℕ} (p : Fin n → ℝ) (hp : ∀ i, 0 ≤ p i) (fuel : ℕ) :
    ∀ F : List (ℝ × CodeTree n), F ≠ [] → F.length ≤ fuel + 1 →
      F.Pairwise (fun a b => a.1 ≤ b.1) → (∀ x ∈ F, x.1 = tWeight p x.2) →
      ∃ t, huffmanJoin fuel F = some t ∧ (t.words.map Prod.fst).Perm (fKeys F) ∧
        ∀ P : List (ℝ × ℕ), (P.map Prod.fst).Perm (F.map Prod.fst) →
          pKraft (P.map Prod.snd) ≤ 1 → tCost p t ≤ fCost p F + pCost P := by
  have single : ∀ (fuel : ℕ) (w : ℝ) (t : CodeTree n), w = tWeight p t →
      ∃ t', huffmanJoin fuel [(w, t)] = some t' ∧ (t'.words.map Prod.fst).Perm (fKeys [(w, t)]) ∧
        ∀ P : List (ℝ × ℕ), (P.map Prod.fst).Perm ([(w, t)].map Prod.fst) →
          pKraft (P.map Prod.snd) ≤ 1 → tCost p t' ≤ fCost p [(w, t)] + pCost P := by
    intro fuel w t hw
    refine ⟨t, by cases fuel <;> rfl, by simp [fKeys], ?_⟩
    intro P hP _
    have : 0 ≤ pCost P := pCost_nonneg (by
      intro x hx
      have : x.1 ∈ [(w, t)].map Prod.fst := hP.subset (List.mem_map_of_mem hx)
      simp only [List.map_cons, List.map_nil, List.mem_singleton] at this
      rw [this, hw]; exact tWeight_nonneg p hp t)
    simp only [fCost, List.map_cons, List.map_nil, List.sum_cons, List.sum_nil]
    linarith
  induction fuel with
  | zero =>
    intro F hF hlen _ hw
    rcases F with _ | ⟨⟨w, t⟩, _ | ⟨y, rest⟩⟩
    · exact absurd rfl hF
    · exact single 0 w t (hw _ List.mem_cons_self)
    · simp at hlen
  | succ f ih =>
    intro F hF hlen hs hw
    rcases F with _ | ⟨⟨w₁, t₁⟩, _ | ⟨⟨w₂, t₂⟩, rest⟩⟩
    · exact absurd rfl hF
    · exact single (f + 1) w₁ t₁ (hw _ List.mem_cons_self)
    · have hw1 : w₁ = tWeight p t₁ := hw _ List.mem_cons_self
      have hw2 : w₂ = tWeight p t₂ := hw _ (List.mem_cons_of_mem _ List.mem_cons_self)
      have hwr : ∀ x ∈ rest, x.1 = tWeight p x.2 := fun x hx =>
        hw x (List.mem_cons_of_mem _ (List.mem_cons_of_mem _ hx))
      rw [List.pairwise_cons, List.pairwise_cons] at hs
      have h12 : w₁ ≤ w₂ := hs.1 (w₂, t₂) List.mem_cons_self
      have h2r : ∀ y ∈ rest, w₂ ≤ y.1 := hs.2.1
      have h0 : 0 ≤ w₁ := hw1 ▸ tWeight_nonneg p hp t₁
      have hperm : (rest.orderedInsert (fun a b : ℝ × CodeTree n => a.1 < b.1)
          (w₁ + w₂, CodeTree.node t₁ t₂)).Perm ((w₁ + w₂, CodeTree.node t₁ t₂) :: rest) :=
        List.perm_orderedInsert _ _ _
      obtain ⟨t, ht, hkeys, hcost⟩ := ih
        (rest.orderedInsert (fun a b : ℝ × CodeTree n => a.1 < b.1)
          (w₁ + w₂, CodeTree.node t₁ t₂))
        (fun h => by simpa [h] using hperm.length_eq)
        (by rw [hperm.length_eq]; simp at hlen ⊢; omega)
        (pairwise_orderedInsert_fst _ _ (fun _ h => h.le) (fun _ h => not_lt.mp h) _ hs.2.2)
        (by
          intro x hx
          rcases List.mem_cons.mp (hperm.subset hx) with rfl | hx
          · simp [tWeight_node, hw1, hw2]
          · exact hwr x hx)
      refine ⟨t, ?_, ?_, ?_⟩
      · rw [huffmanJoin]; exact ht
      · refine hkeys.trans ((hperm.flatMap_right _).trans ?_)
        simp [fKeys, words_node_keys]
      · intro P hP hK
        simp only [List.map_cons] at hP
        obtain ⟨a, P1, hPP1, hP1⟩ := perm_extract hP
        obtain ⟨b, Q, hP1Q, hQ⟩ := perm_extract hP1
        have hPQ : P.Perm ((w₁, a) :: (w₂, b) :: Q) := hPP1.trans (hP1Q.cons _)
        have hQw : ∀ x ∈ Q, w₂ ≤ x.1 := by
          intro x hx
          have : x.1 ∈ rest.map Prod.fst := hQ.subset (List.mem_map_of_mem hx)
          obtain ⟨y, hy, hyx⟩ := List.mem_map.mp this
          rw [← hyx]; exact h2r y hy
        have hK' : (1 / 2 : ℝ) ^ a + (1 / 2) ^ b + pKraft (Q.map Prod.snd) ≤ 1 := by
          have := pKraft_perm (hPQ.map Prod.snd)
          simp only [pKraft, List.map_cons, List.sum_cons] at this hK ⊢
          linarith
        obtain ⟨m, Q', hQ'1, hQ'K, hQ'c⟩ := exchange w₁ w₂ a b Q h0 h12 hQw hK'
        have hP' : (((w₁ + w₂, m) :: Q').map Prod.fst).Perm
            ((rest.orderedInsert (fun a b : ℝ × CodeTree n => a.1 < b.1)
              (w₁ + w₂, CodeTree.node t₁ t₂)).map Prod.fst) := by
          refine List.Perm.trans ?_ (hperm.map Prod.fst).symm
          simp only [List.map_cons, hQ'1]
          exact hQ.cons _
        have hc := hcost _ hP' (by simpa [pKraft] using hQ'K)
        rw [fCost_perm p hperm] at hc
        have hPc := pCost_perm hPQ
        simp only [fCost, pCost, List.map_cons, List.sum_cons, tCost_node] at hc hPc hQ'c ⊢
        rw [hPc]
        rw [← hw1, ← hw2] at hc
        nlinarith

/-- Huffman's tree for nonnegative weights: its leaves are the symbols, each once, and its cost
is at most the cost of any lengths with Kraft sum at most one. -/
lemma huffman_main {n : ℕ} (p : Fin n → ℝ) (hp : ∀ i, 0 ≤ p i) (hn : n ≠ 0) :
    ∃ t, huffmanTree p = some t ∧ (t.words.map Prod.fst).Perm (List.finRange n) ∧
      ∀ P : List (ℝ × ℕ), (P.map Prod.fst).Perm ((List.finRange n).map p) →
        pKraft (P.map Prod.snd) ≤ 1 → tCost p t ≤ pCost P := by
  have hperm : (((List.finRange n).map (fun i => (p i, CodeTree.leaf i))).insertionSort
      (fun a b : ℝ × CodeTree n => a.1 ≤ b.1)).Perm
        ((List.finRange n).map (fun i => (p i, CodeTree.leaf i))) :=
    List.perm_insertionSort _ _
  obtain ⟨t, ht, hkeys, hcost⟩ := huffmanJoin_spec p hp n _
    (fun h => by
      have := hperm.length_eq
      rw [h] at this
      simp at this
      exact hn this.symm)
    (by rw [hperm.length_eq]; simp)
    (pairwise_insertionSort_fst _)
    (by
      intro x hx
      obtain ⟨i, -, rfl⟩ := List.mem_map.mp (hperm.subset hx)
      simp [tWeight, CodeTree.words])
  refine ⟨t, ht, ?_, ?_⟩
  · refine hkeys.trans ((hperm.flatMap_right _).trans ?_)
    simp [CodeTree.words, List.flatMap_map]
  · intro P hP hK
    have h1 := hcost P (hP.trans (by
      have := (hperm.map Prod.fst).symm
      simpa [List.map_map, Function.comp_def] using this)) hK
    have h0 : fCost p (((List.finRange n).map (fun i => (p i, CodeTree.leaf i))).insertionSort
        (fun a b : ℝ × CodeTree n => a.1 ≤ b.1)) = 0 := by
      rw [fCost_perm p hperm]
      simp [fCost, tCost, Function.comp_def, CodeTree.words]
    linarith


#print axioms half_pow_mul
#print axioms kraft_of_readBack
#print axioms kraft_of_prefixFree
#print axioms kraft_construct
#print axioms entropy_le_of_kraft
#print axioms tWeight
#print axioms tCost
#print axioms fCost
#print axioms fKeys
#print axioms pCost
#print axioms pKraft
#print axioms words_node_keys
#print axioms tWeight_node
#print axioms tCost_node
#print axioms tWeight_nonneg
#print axioms pCost_perm
#print axioms pKraft_perm
#print axioms fCost_perm
#print axioms words_pairwise
#print axioms lookup_of_mem
#print axioms code_props
#print axioms pairwise_orderedInsert_fst
#print axioms pairwise_insertionSort_fst
#print axioms perm_extract
#print axioms swap_aux
#print axioms dyadic_merge
#print axioms exchange
#print axioms pCost_nonneg
#print axioms huffmanJoin_spec
#print axioms huffman_main

/-! ### The card's theorems -/

/-- **Huffman's code is the shortest prefix-free code.** For any probabilities `p₁, …, pₙ`,
the code built by joining the two least likely symbols again and again is prefix-free, and no
prefix-free code for the same symbols has a smaller average length `∑ pᵢ ℓᵢ`. -/
theorem huffman_code_is_shortest_prefix_free {n : ℕ} (p : Fin n → ℝ)
    (hp : ∀ i, 0 ≤ p i) (hsum : ∑ i, p i = 1) :
    IsPrefixFreeCode (huffmanCode p) ∧
      ∀ c : Fin n → List Bool, IsPrefixFreeCode c →
        avgLength p (huffmanCode p) ≤ avgLength p c := by
  have hn : n ≠ 0 := by
    rintro rfl
    simp at hsum
  obtain ⟨t, ht, hkeys, hopt⟩ := huffman_main p hp hn
  have hc : ∀ i, huffmanCode p i = (t.words.lookup i).getD [] := by
    intro i
    simp [huffmanCode, ht]
  obtain ⟨hpf, havg⟩ := code_props p t hkeys (huffmanCode p) hc
  refine ⟨hpf, fun c hc' => ?_⟩
  rw [havg]
  have hK := kraft_of_prefixFree hc'
  have h := hopt ((List.finRange n).map (fun i => (p i, (c i).length)))
    (by simp [List.map_map, Function.comp_def])
    (by
      simp only [pKraft, List.map_map, Function.comp_def]
      rw [← Fin.sum_univ_def]
      exact hK)
  have he : pCost ((List.finRange n).map (fun i => (p i, (c i).length))) = avgLength p c := by
    simp only [pCost, List.map_map, Function.comp_def, avgLength]
    rw [← Fin.sum_univ_def]
  linarith

/-- **Kraft–McMillan, both ways.** Every code that can be read back, prefix-free or not, has
Kraft sum `∑ 2^(-ℓᵢ)` at most one; and whole-number lengths `ℓ₁, …, ℓₙ` belong to some
prefix-free code exactly when their Kraft sum is at most one. -/
theorem kraft_mcmillan {n : ℕ} :
    (∀ c : Fin n → List Bool, CanBeReadBack c → kraftSum (fun i => (c i).length) ≤ 1) ∧
      ∀ ℓ : Fin n → ℕ,
        (∃ c : Fin n → List Bool, IsPrefixFreeCode c ∧ ∀ i, (c i).length = ℓ i) ↔
          kraftSum ℓ ≤ 1 := by
  refine ⟨fun c hc => kraft_of_readBack hc, fun ℓ => ⟨?_, ?_⟩⟩
  · rintro ⟨c, hc, hlen⟩
    have h : (fun i => (c i).length) = ℓ := funext hlen
    rw [← h]
    exact kraft_of_prefixFree hc
  · intro hK
    obtain ⟨c, hlen, hpf⟩ := kraft_construct ℓ Finset.univ (by simpa [kraftSum] using hK)
    refine ⟨c, ⟨fun i j h => hpf i (Finset.mem_univ _) j (Finset.mem_univ _)
      (h ▸ List.prefix_refl _), ?_⟩, fun i => hlen i (Finset.mem_univ _)⟩
    rintro _ ⟨i, rfl⟩ _ ⟨j, rfl⟩ h
    rw [hpf i (Finset.mem_univ _) j (Finset.mem_univ _) h]

/-- **The entropy bound.** For probabilities `p₁, …, pₙ`, all positive, every code that can be
read back has average length at least the entropy `H = ∑ pᵢ log₂ (1/pᵢ)`, and Huffman's code
has average length less than `H + 1`. -/
theorem entropy_le_avg_length_and_huffman_lt_entropy_add_one {n : ℕ} (p : Fin n → ℝ)
    (hp : ∀ i, 0 < p i) (hsum : ∑ i, p i = 1) :
    (∀ c : Fin n → List Bool, CanBeReadBack c → entropyBits p ≤ avgLength p c) ∧
      avgLength p (huffmanCode p) < entropyBits p + 1 := by
  have hn : n ≠ 0 := by
    rintro rfl
    simp at hsum
  have hp1 : ∀ i, p i ≤ 1 := fun i =>
    hsum ▸ Finset.single_le_sum (fun j _ => (hp j).le) (Finset.mem_univ i)
  refine ⟨fun c hc => ?_, ?_⟩
  · have hK := kraft_of_readBack hc
    exact entropy_le_of_kraft p hp hsum (fun i => (c i).length) hK
  · let ℓ : Fin n → ℕ := fun i => ⌈-Real.logb 2 (p i)⌉₊
    have hℓK : ∀ i, (1 / 2 : ℝ) ^ ℓ i ≤ p i := by
      intro i
      have h1 : -Real.logb 2 (p i) ≤ (ℓ i : ℝ) := Nat.le_ceil _
      have h2 : (2 : ℝ) ^ (-(ℓ i : ℝ)) ≤ (2 : ℝ) ^ (Real.logb 2 (p i)) :=
        Real.rpow_le_rpow_of_exponent_le (by norm_num) (by linarith)
      rw [Real.rpow_logb (by norm_num) (by norm_num) (hp i), Real.rpow_neg (by norm_num),
        Real.rpow_natCast] at h2
      rw [one_div, inv_pow]
      exact h2
    have hℓlt : ∀ i, (ℓ i : ℝ) < -Real.logb 2 (p i) + 1 := by
      intro i
      exact Nat.ceil_lt_add_one (by
        have := Real.logb_nonpos (b := 2) (by norm_num) (hp i).le (hp1 i)
        linarith)
    obtain ⟨c, hc, hlen⟩ := (kraft_mcmillan.2 ℓ).2 (by
      unfold kraftSum
      calc ∑ i, (1 / 2 : ℝ) ^ ℓ i ≤ ∑ i, p i := Finset.sum_le_sum (fun i _ => hℓK i)
        _ = 1 := hsum)
    have h1 := (huffman_code_is_shortest_prefix_free p (fun i => (hp i).le) hsum).2 c hc
    have hne : (Finset.univ : Finset (Fin n)).Nonempty := ⟨⟨0, Nat.pos_of_ne_zero hn⟩, by simp⟩
    calc avgLength p (huffmanCode p) ≤ avgLength p c := h1
      _ = ∑ i, p i * (ℓ i : ℝ) := by simp [avgLength, hlen]
      _ < ∑ i, p i * (-Real.logb 2 (p i) + 1) :=
          Finset.sum_lt_sum_of_nonempty hne (fun i _ => mul_lt_mul_of_pos_left (hℓlt i) (hp i))
      _ = entropyBits p + 1 := by
          simp only [mul_add, mul_one, Finset.sum_add_distrib, hsum, entropyBits]
          congr 1
          apply Finset.sum_congr rfl
          intro i _
          simp only [Real.negMulLog, Real.logb]
          ring

/-! ### The card's worked numbers, checked exactly

Symbols in the card's order: 0 Sun, 1 Cloud, 2 Rain, 3 Snow. -/

/-- Summer odds: 1/2, 1/4, 1/8, 1/8. -/
def summer : Fin 4 → ℚ := ![1/2, 1/4, 1/8, 1/8]

/-- Autumn odds: 2/5, 3/10, 1/5, 1/10. -/
def autumn : Fin 4 → ℚ := ![2/5, 3/10, 1/5, 1/10]

-- Summer: Huffman gives Sun 0, Cloud 10, Rain 110, Snow 111.
example : List.ofFn (huffmanCode summer) =
    [[false], [true, false], [true, true, false], [true, true, true]] := by decide +kernel

-- Summer: average length 1/2·1 + 1/4·2 + 1/8·3 + 1/8·3 = 7/4 = 1.75 bits a day.
example : ∑ i, summer i * (huffmanCode summer i).length = 7 / 4 := by decide +kernel

-- Summer: Kraft sum 1/2 + 1/4 + 1/8 + 1/8 = 1.
example : ∑ i, (1 / 2 : ℚ) ^ (huffmanCode summer i).length = 1 := by decide +kernel

-- Summer: entropy 1/2·1 + 1/4·2 + 1/8·3 + 1/8·3 = 7/4, with log₂(1/pᵢ) = 1, 2, 3, 3.
example : (1/2 : ℚ) * 1 + 1/4 * 2 + 1/8 * 3 + 1/8 * 3 = 7 / 4 := by norm_num

-- A year: 365 · 7/4 = 638.75 bits against 730, saving 91.25.
example : (365 : ℚ) * (7 / 4) = 2555 / 4 ∧ (730 : ℚ) - 2555 / 4 = 365 / 4 := by norm_num

-- The week Sun Sun Cloud Rain Sun Snow Cloud goes out as 0010110011110: 13 bits.
example : (([0, 0, 1, 2, 0, 3, 1] : List (Fin 4)).map (huffmanCode summer)).flatten =
    [false, false, true, false, true, true, false, false, true, true, true, true, false] := by
  decide +kernel

-- Autumn: Huffman gives Sun 0, Cloud 10, Rain 111, Snow 110, average 19/10 = 1.9 bits.
example : List.ofFn (huffmanCode autumn) =
    [[false], [true, false], [true, true, true], [true, true, false]] := by decide +kernel

example : ∑ i, autumn i * (huffmanCode autumn i).length = 19 / 10 := by decide +kernel

-- Autumn: the joins 1/10 + 1/5, then 3/10 + 3/10, then 2/5 + 3/5 add up to 19/10.
example : (1/10 + 1/5 : ℚ) + (3/10 + 3/10) + (2/5 + 3/5) = 19 / 10 := by norm_num

-- Autumn, Shannon lengths 2, 2, 3, 4: Kraft sum 11/16 = 0.6875, average 12/5 = 2.4 bits.
example : (1/2 : ℚ)^2 + (1/2)^2 + (1/2)^3 + (1/2)^4 = 11 / 16 := by norm_num
example : (2/5 : ℚ) * 2 + 3/10 * 2 + 1/5 * 3 + 1/10 * 4 = 12 / 5 := by norm_num

-- Short words to the rare days (lengths 3, 3, 2, 1) cost 21/8 = 2.625 bits a day.
example : (1/2 : ℚ) * 3 + 1/4 * 3 + 1/8 * 2 + 1/8 * 1 = 21 / 8 := by norm_num

-- The bad code 0, 1, 10, 11: Kraft sum 3/2, average 5/4 = 1.25 bits, and Rain = Cloud then Sun.
example : (1/2 : ℚ)^1 + (1/2)^1 + (1/2)^2 + (1/2)^2 = 3 / 2 := by norm_num
example : (1/2 : ℚ) * 1 + 1/4 * 1 + 1/8 * 2 + 1/8 * 2 = 5 / 4 := by norm_num
example : [true, false] = [true] ++ [false] := by decide

-- The bad code: 24 three-forecast messages come out 4 bits long, and there are only 16
-- strings of 4 bits.
example : (Finset.univ.filter
    (fun m : Fin 3 → Fin 4 => ∑ j, (![1, 1, 2, 2] : Fin 4 → ℕ) (m j) = 4)).card = 24 ∧
    2 ^ 4 = 16 := by decide

#print axioms huffman_code_is_shortest_prefix_free
#print axioms kraft_mcmillan
#print axioms entropy_le_avg_length_and_huffman_lt_entropy_add_one

end HuffmanCard
