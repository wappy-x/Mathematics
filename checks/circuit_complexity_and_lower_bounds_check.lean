-- Circuit lower bounds: a depth-2 AND/OR circuit for parity on n inputs needs exactly 2^(n-1) + 1 gates, every useful term names every input, and counting circuits shows some function needs more than s two-input gates.
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Fintype.Prod
import Mathlib.Data.Fintype.Card
import Mathlib.Algebra.Order.Group.Nat
import Mathlib.Algebra.Group.Nat.Even
import Mathlib.Order.Bounds.Defs
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Data.List.GetD

namespace CircuitLowerBounds

/-! ### Depth-2 circuits with unbounded fan-in

A rota on `n` staff is `x : Fin n → Bool`. A literal `(i, b)` is the wire "staff `i` is `b`"
(a NOT on an input wire when `b = false`). An AND gate (a term) is a finite set of literals and
fires when every literal holds. An OR gate (a clause) fires when some literal holds.
A depth-2 circuit is a finite set of such gates under one OR (an OR of ANDs) or under one AND
(an AND of ORs); its size is the number of gates in the set plus the one top gate. -/

/-- Parity: `true` when the number of staff on the night is odd. -/
def parity {n : ℕ} (x : Fin n → Bool) : Bool :=
  decide (Odd (Finset.univ.filter (fun i => x i = true)).card)

/-- An AND gate over literals fires when every literal holds. -/
def termFires {n : ℕ} (t : Finset (Fin n × Bool)) (x : Fin n → Bool) : Prop :=
  ∀ l ∈ t, x l.1 = l.2

/-- An OR gate over literals fires when some literal holds. -/
def clauseFires {n : ℕ} (c : Finset (Fin n × Bool)) (x : Fin n → Bool) : Prop :=
  ∃ l ∈ c, x l.1 = l.2

/-- An OR of AND gates computes `f`: the flag is up exactly when some term fires. -/
def OrOfAndsComputes {n : ℕ} (D : Finset (Finset (Fin n × Bool))) (f : (Fin n → Bool) → Bool) : Prop :=
  ∀ x, f x = true ↔ ∃ t ∈ D, termFires t x

/-- An AND of OR gates computes `f`: the flag is up exactly when every clause fires. -/
def AndOfOrsComputes {n : ℕ} (D : Finset (Finset (Fin n × Bool))) (f : (Fin n → Bool) → Bool) : Prop :=
  ∀ x, f x = true ↔ ∀ c ∈ D, clauseFires c x

instance {n : ℕ} (t : Finset (Fin n × Bool)) (x : Fin n → Bool) : Decidable (termFires t x) := by
  unfold termFires; infer_instance

instance {n : ℕ} (c : Finset (Fin n × Bool)) (x : Fin n → Bool) : Decidable (clauseFires c x) := by
  unfold clauseFires; infer_instance

instance {n : ℕ} (D : Finset (Finset (Fin n × Bool))) (f : (Fin n → Bool) → Bool) :
    Decidable (OrOfAndsComputes D f) := by
  unfold OrOfAndsComputes; infer_instance


theorem parity_flip {n : ℕ} (x : Fin n → Bool) (i : Fin n) :
    parity (Function.update x i (!x i)) = !parity x := by
  unfold parity
  have key : Odd (Finset.univ.filter (fun j => Function.update x i (!x i) j = true)).card ↔
      ¬ Odd (Finset.univ.filter (fun j => x j = true)).card := by
    by_cases hx' : x i = true
    swap
    · have hx : x i = false := by simpa using hx'
      have hS : (Finset.univ.filter (fun j => Function.update x i (!x i) j = true)) =
          insert i (Finset.univ.filter (fun j => x j = true)) := by
        ext j
        by_cases hj : j = i
        · subst hj; simp [hx]
        · simp [Function.update, hj]
      have hi : i ∉ Finset.univ.filter (fun j => x j = true) := by simp [hx]
      rw [hS, Finset.card_insert_of_notMem hi, Nat.odd_add_one]
    · have hx := hx'
      have hS : (Finset.univ.filter (fun j => x j = true)) =
          insert i (Finset.univ.filter (fun j => Function.update x i (!x i) j = true)) := by
        ext j
        by_cases hj : j = i
        · subst hj; simp [hx]
        · simp [Function.update, hj]
      have hi : i ∉ Finset.univ.filter (fun j => Function.update x i (!x i) j = true) := by
        simp [hx]
      rw [hS, Finset.card_insert_of_notMem hi, Nat.odd_add_one, not_not]
  by_cases h : Odd (Finset.univ.filter (fun j => x j = true)).card
  · simp [h, key]
  · simp [h, key]

/-- A function that flips whenever one input bit flips. -/
def Sensitive {n : ℕ} (f : (Fin n → Bool) → Bool) : Prop :=
  ∀ x i, f (Function.update x i (!x i)) = !f x

theorem parity_sensitive (n : ℕ) : Sensitive (parity (n := n)) := fun x i => parity_flip x i

theorem not_sensitive {n : ℕ} {f : (Fin n → Bool) → Bool} (hf : Sensitive f) :
    Sensitive (fun x => !f x) := fun x i => by simp [hf x i]

theorem term_names_all {n : ℕ} {f : (Fin n → Bool) → Bool} (hf : Sensitive f)
    {D : Finset (Finset (Fin n × Bool))} (hD : OrOfAndsComputes D f) {t : Finset (Fin n × Bool)}
    (ht : t ∈ D) {x : Fin n → Bool} (hx : termFires t x) : ∀ i : Fin n, ∃ b : Bool, (i, b) ∈ t := by
  intro i
  by_contra hno
  push Not at hno
  have h1 : f x = true := (hD x).2 ⟨t, ht, hx⟩
  have h2 : termFires t (Function.update x i (!x i)) := by
    intro l hl
    have hne : l.1 ≠ i := by
      intro he
      exact hno l.2 (by rw [← he]; exact hl)
    rw [Function.update_of_ne hne]
    exact hx l hl
  have h3 : f (Function.update x i (!x i)) = true := (hD _).2 ⟨t, ht, h2⟩
  rw [hf, h1] at h3
  simp at h3

theorem fires_unique {n : ℕ} {t : Finset (Fin n × Bool)} (hall : ∀ i : Fin n, ∃ b : Bool, (i, b) ∈ t)
    {x y : Fin n → Bool} (hx : termFires t x) (hy : termFires t y) : x = y := by
  funext i
  obtain ⟨b, hb⟩ := hall i
  rw [hx _ hb, hy _ hb]

theorem card_parity_eq (n : ℕ) (hn : 0 < n) :
    (Finset.univ.filter (fun x : Fin n → Bool => parity x = true)).card = 2 ^ (n - 1) ∧
    (Finset.univ.filter (fun x : Fin n → Bool => parity x = false)).card = 2 ^ (n - 1) := by
  set i0 : Fin n := ⟨0, hn⟩
  have hinv : ∀ x : Fin n → Bool,
      Function.update (Function.update x i0 (!x i0)) i0 (!(Function.update x i0 (!x i0)) i0) = x := by
    intro x; simp
  have heq : (Finset.univ.filter (fun x : Fin n → Bool => parity x = true)).card =
      (Finset.univ.filter (fun x : Fin n → Bool => parity x = false)).card := by
    apply Finset.card_nbij' (fun x => Function.update x i0 (!x i0)) (fun x => Function.update x i0 (!x i0))
    · intro x hx; simp only [Finset.coe_filter, Finset.mem_univ, true_and, Set.mem_ofPred_eq] at hx ⊢
      rw [parity_flip, hx]; rfl
    · intro x hx; simp only [Finset.coe_filter, Finset.mem_univ, true_and, Set.mem_ofPred_eq] at hx ⊢
      rw [parity_flip, hx]; rfl
    · intro x _; exact hinv x
    · intro x _; exact hinv x
  have hsum := Finset.card_filter_add_card_filter_not (s := (Finset.univ : Finset (Fin n → Bool)))
    (fun x => parity x = true)
  have hneg : (Finset.univ.filter (fun x : Fin n → Bool => ¬ parity x = true)) =
      (Finset.univ.filter (fun x : Fin n → Bool => parity x = false)) := by
    ext x; simp
  rw [hneg, Finset.card_univ] at hsum
  simp only [Fintype.card_fun, Fintype.card_bool, Fintype.card_fin] at hsum
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, by omega⟩
  rw [pow_succ] at hsum
  simp only [Nat.add_sub_cancel]
  omega

theorem card_true_le {n : ℕ} {f : (Fin n → Bool) → Bool} (hf : Sensitive f)
    {D : Finset (Finset (Fin n × Bool))} (hD : OrOfAndsComputes D f) :
    (Finset.univ.filter (fun x => f x = true)).card ≤ D.card := by
  classical
  let g : (Fin n → Bool) → Finset (Fin n × Bool) := fun x =>
    if h : ∃ t ∈ D, termFires t x then h.choose else ∅
  have hg : ∀ x, f x = true → g x ∈ D ∧ termFires (g x) x := by
    intro x hx
    have h : ∃ t ∈ D, termFires t x := (hD x).1 hx
    simp only [g, dite_eq_left h]
    exact h.choose_spec
  apply Finset.card_le_card_of_injOn g
  · intro x hx
    simp only [Finset.coe_filter, Finset.mem_univ, true_and, Set.mem_ofPred_eq] at hx
    exact (hg x hx).1
  · intro x hx y hy hxy
    simp only [Finset.coe_filter, Finset.mem_univ, true_and, Set.mem_ofPred_eq] at hx hy
    obtain ⟨hxD, hxf⟩ := hg x hx
    obtain ⟨_, hyf⟩ := hg y hy
    rw [hxy] at hxf hxD
    exact fires_unique (term_names_all hf hD hxD hxf) hxf hyf

/-- Flip every literal: turns a clause into the term that fires exactly when the clause fails. -/
def negLits {n : ℕ} (c : Finset (Fin n × Bool)) : Finset (Fin n × Bool) :=
  c.image (fun l => (l.1, !l.2))

theorem negLits_negLits {n : ℕ} (c : Finset (Fin n × Bool)) : negLits (negLits c) = c := by
  unfold negLits
  rw [Finset.image_image]
  have : ((fun l : Fin n × Bool => (l.1, !l.2)) ∘ (fun l : Fin n × Bool => (l.1, !l.2))) = id := by
    funext l; simp
  rw [this, Finset.image_id]

theorem termFires_negLits {n : ℕ} (c : Finset (Fin n × Bool)) (x : Fin n → Bool) :
    termFires (negLits c) x ↔ ¬ clauseFires c x := by
  unfold termFires clauseFires negLits
  simp only [Finset.mem_image, forall_exists_index, and_imp, not_exists, not_and]
  constructor
  · intro h l hl hx
    have := h _ l hl rfl
    simp [hx] at this
  · intro h l l' hl' hl
    subst hl
    have := h l' hl'
    cases hb : l'.2 <;> simp_all

theorem andOfOrs_to_orOfAnds {n : ℕ} {D : Finset (Finset (Fin n × Bool))}
    {f : (Fin n → Bool) → Bool} (hD : AndOfOrsComputes D f) :
    OrOfAndsComputes (D.image negLits) (fun x => !f x) ∧ (D.image negLits).card = D.card := by
  refine ⟨?_, ?_⟩
  · intro x
    have := hD x
    simp only [Bool.not_eq_true', Finset.mem_image, exists_exists_and_eq_and, termFires_negLits]
    constructor
    · intro hx
      by_contra hno
      push Not at hno
      rw [this.2 hno] at hx
      exact absurd hx (by simp)
    · rintro ⟨c, hc, hnc⟩
      by_contra hno
      have : f x = true := by simpa using hno
      exact hnc ((hD x).1 this c hc)
  · apply Finset.card_image_of_injective
    intro a b hab
    rw [← negLits_negLits a, hab, negLits_negLits]

/-- The full-width term for one rota: it names every staff member at that rota's value. -/
def fullTerm {n : ℕ} (x : Fin n → Bool) : Finset (Fin n × Bool) :=
  Finset.univ.image (fun i => (i, x i))

theorem fullTerm_fires {n : ℕ} (x y : Fin n → Bool) : termFires (fullTerm x) y ↔ y = x := by
  unfold termFires fullTerm
  simp only [Finset.mem_image, Finset.mem_univ, true_and, forall_exists_index]
  constructor
  · intro h; funext i; exact h _ i rfl
  · rintro rfl l i rfl; rfl

/-- The card's main result, `s_2(n) = 2^(n-1) + 1`: among all depth-2 circuits of AND, OR and
NOT gates with unbounded fan-in (an OR of ANDs or an AND of ORs) that compute parity on `n`
inputs, the fewest gates is exactly `2^(n-1) + 1`. One design reaches it (one full-width AND per
odd rota, plus the OR) and no design does better. -/
theorem depth_two_parity_size_eq (n : ℕ) (hn : 0 < n) :
    IsLeast {s | ∃ D : Finset (Finset (Fin n × Bool)),
        (OrOfAndsComputes D parity ∨ AndOfOrsComputes D parity) ∧ D.card + 1 = s}
      (2 ^ (n - 1) + 1) := by
  constructor
  · refine ⟨(Finset.univ.filter (fun x : Fin n → Bool => parity x = true)).image fullTerm,
      Or.inl ?_, ?_⟩
    · intro x
      constructor
      · intro hx
        exact ⟨fullTerm x, Finset.mem_image_of_mem _ (by simpa using hx), (fullTerm_fires x x).2 rfl⟩
      · rintro ⟨t, ht, hf⟩
        obtain ⟨y, hy, rfl⟩ := Finset.mem_image.1 ht
        rw [fullTerm_fires] at hf
        subst hf
        simpa using hy
    · rw [Finset.card_image_of_injective]
      · rw [(card_parity_eq n hn).1]
      · intro x y hxy
        have h : termFires (fullTerm y) x := by rw [← hxy]; exact (fullTerm_fires x x).2 rfl
        exact ((fullTerm_fires y x).1 h)
  · rintro s ⟨D, hD | hD, rfl⟩
    · have := card_true_le (parity_sensitive n) hD
      rw [(card_parity_eq n hn).1] at this
      omega
    · obtain ⟨h1, h2⟩ := andOfOrs_to_orOfAnds hD
      have := card_true_le (not_sensitive (parity_sensitive n)) h1
      simp only [Bool.not_eq_true'] at this
      rw [(card_parity_eq n hn).2, h2] at this
      omega

/-- Step 1's key fact: in an OR of ANDs that computes parity, every term that ever fires names
every staff member. A term that leaves someone out would also fire after that person's bit is
flipped, raising the flag on an even rota. -/
theorem parity_term_names_everyone (n : ℕ) (D : Finset (Finset (Fin n × Bool)))
    (hD : OrOfAndsComputes D parity) (t : Finset (Fin n × Bool)) (ht : t ∈ D)
    (hfires : ∃ x, termFires t x) : ∀ i : Fin n, ∃ b : Bool, (i, b) ∈ t := by
  obtain ⟨x, hx⟩ := hfires
  exact term_names_all (parity_sensitive n) hD ht hx

/-! ### Fan-in-2 circuits of any depth, and Shannon's count

A gate follows one of the 16 rules `Bool → Bool → Bool` and reads two wires. Wires are numbered:
`0, …, n-1` are the inputs and `n + j` is gate `j`. In a valid circuit gate `j` reads only wires
below `n + j`, so there are no loops. The output is the last gate (`false` for no gates). -/

/-- A two-input gate: its rule and the two wires it reads. -/
structure Gate where
  op : Bool → Bool → Bool
  a : ℕ
  b : ℕ

/-- Every wire value, inputs first, then each gate in order. -/
def wires {n : ℕ} (x : Fin n → Bool) (C : List Gate) : List Bool :=
  C.foldl (fun vals g => vals ++ [g.op (vals.getD g.a false) (vals.getD g.b false)]) (List.ofFn x)

/-- The circuit's answer: the value of its last gate. -/
def output {n : ℕ} (C : List Gate) (x : Fin n → Bool) : Bool :=
  if C.length = 0 then false else (wires x C).getD (n + C.length - 1) false

/-- No loops: gate `j` reads only inputs and earlier gates. -/
def Valid (n : ℕ) (C : List Gate) : Prop :=
  ∀ j (h : j < C.length), C[j].a < n + j ∧ C[j].b < n + j

/-- One step of `wires`: append the next gate's value. -/
def wstep (vals : List Bool) (g : Gate) : List Bool :=
  vals ++ [g.op (vals.getD g.a false) (vals.getD g.b false)]

theorem wires_eq_foldl {n : ℕ} (x : Fin n → Bool) (C : List Gate) :
    wires x C = C.foldl wstep (List.ofFn x) := rfl

theorem foldl_wstep_prefix (C : List Gate) (l : List Bool) :
    l <+: C.foldl wstep l ∧ (C.foldl wstep l).length = l.length + C.length := by
  induction C generalizing l with
  | nil => simp
  | cons g C ih =>
    obtain ⟨h1, h2⟩ := ih (wstep l g)
    refine ⟨List.IsPrefix.trans ⟨_, rfl⟩ h1, ?_⟩
    rw [List.foldl_cons, h2]
    simp [wstep]
    omega

theorem wires_length {n : ℕ} (x : Fin n → Bool) (C : List Gate) :
    (wires x C).length = n + C.length := by
  rw [wires_eq_foldl, (foldl_wstep_prefix C _).2, List.length_ofFn]

theorem wires_prefix {n : ℕ} (x : Fin n → Bool) (C L : List Gate) :
    wires x C <+: wires x (C ++ L) := by
  rw [wires_eq_foldl, wires_eq_foldl, List.foldl_append]
  exact (foldl_wstep_prefix L _).1

theorem wires_concat {n : ℕ} (x : Fin n → Bool) (C : List Gate) (g : Gate) :
    wires x (C ++ [g]) = wstep (wires x C) g := by
  rw [wires_eq_foldl, wires_eq_foldl, List.foldl_append]
  rfl

theorem getD_of_prefix {l l' : List Bool} (h : l <+: l') {i : ℕ} (hi : i < l.length) :
    l.getD i false = l'.getD i false := by
  obtain ⟨t, rfl⟩ := h
  rw [List.getD_append _ _ _ _ hi]

/-- The padding gate: it copies the old output wire (or gives `false` if there were no gates). -/
def padGate (n k : ℕ) : Gate := ⟨fun a _ => if k = 0 then false else a, n + k - 1, n + k - 1⟩

theorem output_pad {n : ℕ} (C : List Gate) (m : ℕ) (x : Fin n → Bool) :
    output (C ++ List.replicate m (padGate n C.length)) x = output C x := by
  cases m with
  | zero => simp
  | succ m =>
    rw [List.replicate_succ', ← List.append_assoc]
    set W := wires x (C ++ List.replicate m (padGate n C.length)) with hW
    have hWl : W.length = n + C.length + m := by
      rw [hW, wires_length]; simp; omega
    unfold output
    rw [ite_eq_right (by simp), wires_concat, ← hW]
    have hidx : n + (C ++ List.replicate m (padGate n C.length) ++ [padGate n C.length]).length - 1
        = W.length := by simp [hWl]; omega
    rw [hidx]
    unfold wstep
    rw [List.getD_append_right _ _ _ _ (le_refl _), Nat.sub_self]
    simp only [List.getD_cons_zero]
    unfold padGate
    by_cases hk : C.length = 0
    · simp [hk]
    · simp only [hk, ite_false]
      rw [← getD_of_prefix (wires_prefix x C _) (by rw [wires_length]; omega)]

/-- A circuit code: for each of `s` slots, a rule and two wire numbers below `n + s`. -/
abbrev Code (n s : ℕ) := Fin s → (Bool → Bool → Bool) × Fin (n + s) × Fin (n + s)

/-- Read a code as a list of gates and take its output. -/
def decode {n s : ℕ} (c : Code n s) : (Fin n → Bool) → Bool :=
  output (List.ofFn fun j => (⟨(c j).1, (c j).2.1, (c j).2.2⟩ : Gate))

theorem card_code (n s : ℕ) : Fintype.card (Code n s) = (16 * (n + s) ^ 2) ^ s := by
  simp only [Code, Fintype.card_fun, Fintype.card_prod, Fintype.card_bool, Fintype.card_fin]
  norm_num [sq]

theorem exists_code {n s : ℕ} (P : List Gate) (hlen : P.length = s)
    (hb : ∀ j (h : j < P.length), P[j].a < n + s ∧ P[j].b < n + s) :
    ∃ c : Code n s, decode c = output P := by
  subst hlen
  refine ⟨fun j => (P[j].op, ⟨P[j].a, (hb j j.2).1⟩, ⟨P[j].b, (hb j j.2).2⟩), ?_⟩
  unfold decode
  congr 1
  apply List.ext_getElem
  · simp
  · intro i h1 h2
    simp

theorem padded_code {n s : ℕ} (C : List Gate) (hC : C.length ≤ s) (hV : Valid n C) :
    ∃ c : Code n s, decode c = output C := by
  set P := C ++ List.replicate (s - C.length) (padGate n C.length) with hP
  have hlen : P.length = s := by simp [hP]; omega
  obtain ⟨c, hc⟩ := exists_code (n := n) P hlen (by
    intro j hj
    by_cases hjk : j < C.length
    · have := hV j hjk
      simp only [hP, List.getElem_append_left hjk]
      omega
    · simp only [hP, List.getElem_append_right (Nat.le_of_not_lt hjk), List.getElem_replicate,
        padGate]
      rw [hlen] at hj
      omega)
  refine ⟨c, ?_⟩
  rw [hc]
  funext x
  exact output_pad C _ x

/-- Shannon's counting bound: circuits with at most `s` two-input gates number at most
`(16 (n + s)^2)^s`, so when that is below the `2^(2^n)` functions of `n` inputs, some function
has no circuit of at most `s` gates. The count names no particular function. -/
theorem exists_function_needing_more_than_s_gates (n s : ℕ)
    (hcount : (16 * (n + s) ^ 2) ^ s < 2 ^ (2 ^ n)) :
    ∃ f : (Fin n → Bool) → Bool, ∀ C : List Gate, C.length ≤ s → Valid n C →
      ∃ x, output C x ≠ f x := by
  classical
  let F : Finset ((Fin n → Bool) → Bool) := (Finset.univ : Finset (Code n s)).image decode
  have hF : F.card < (Finset.univ : Finset ((Fin n → Bool) → Bool)).card := by
    refine lt_of_le_of_lt Finset.card_image_le ?_
    rw [Finset.card_univ, Finset.card_univ, card_code]
    simpa [Fintype.card_fun, Fintype.card_bool, Fintype.card_fin] using hcount
  obtain ⟨f, -, hf⟩ := Finset.exists_mem_notMem_of_card_lt_card hF
  refine ⟨f, fun C hC hV => ?_⟩
  by_contra hall
  push Not at hall
  obtain ⟨c, hc⟩ := padded_code C hC hV
  apply hf
  have : f = output C := funext fun x => (hall x).symm
  rw [this, ← hc]
  exact Finset.mem_image_of_mem _ (Finset.mem_univ _)

/-! ### The card's whole-number examples -/

-- Staff 1, 2 and 5 on the night of an 8-person rota: count 3, odd, flag.
example : parity (fun i : Fin 8 => decide (i.val = 0 ∨ i.val = 1 ∨ i.val = 4)) = true := by decide

-- The picture's checker for 3 staff: four full-width AND terms under one OR compute parity.
example : OrOfAndsComputes
    ({{(0, true), (1, false), (2, false)}, {(0, false), (1, true), (2, false)},
      {(0, false), (1, false), (2, true)}, {(0, true), (1, true), (2, true)}} :
      Finset (Finset (Fin 3 × Bool))) parity := by decide

-- What breaks: a term on staff 1 to 7 only (all off) fires on 2 rotas of 8, and 1 of them is even.
example : (Finset.univ.filter (fun x : Fin 8 → Bool =>
    termFires ((Finset.univ.filter (fun i : Fin 8 => i.val < 7)).image (fun i => (i, false))) x)).card = 2 ∧
  (Finset.univ.filter (fun x : Fin 8 → Bool => parity x = false ∧
    termFires ((Finset.univ.filter (fun i : Fin 8 => i.val < 7)).image (fun i => (i, false))) x)).card = 1 := by
  decide

-- Depth 2 for 8 staff: 128 odd rotas, 128 AND gates + 1 OR = 129 gates.
example : 2 ^ 8 / 2 = 128 ∧ 2 ^ (8 - 1) + 1 = 129 := by norm_num

-- Depth 2 for 64 staff: 2^63 + 1 gates.
example : 2 ^ (64 - 1) + 1 = 9223372036854775809 := by norm_num

-- Depth 3 for 64 staff, blocks of 8: 8 · 2^8 + 2^7 + 1 = 2,177 gates, under the bound 64 · 2^8.
example : 8 * 2 ^ 8 + 2 ^ 7 + 1 = 2177 ∧ 2177 ≤ 64 * 2 ^ 8 := by norm_num

-- All restrictions of 8 staff (each free, off or on): 3^8 = 6,561.
example : 3 ^ 8 = 6561 := by norm_num

-- Counting at 8 inputs: 18 gates give fewer than 2^242 circuits; at 19 the bound passes 2^256.
example : (16 * (8 + 18) ^ 2) ^ 18 < 2 ^ 242 ∧ 2 ^ 256 < (16 * (8 + 19) ^ 2) ^ 19 := by norm_num

-- So the counting theorem applies at n = 8, s = 18, with a factor 2^14 to spare.
example : (16 * (8 + 18) ^ 2) ^ 18 < 2 ^ (2 ^ 8) ∧ 2 ^ 242 * 2 ^ 14 = 2 ^ (2 ^ 8) := by norm_num

-- Sorting 8 staff: 8! = 40,320 orders, more than the 2^15 = 32,768 leaves of 15 comparisons.
example : Nat.factorial 8 = 40320 ∧ 2 ^ 15 = 32768 ∧ 2 ^ 15 < Nat.factorial 8 := by decide

#print axioms parity_flip
#print axioms parity_sensitive
#print axioms not_sensitive
#print axioms term_names_all
#print axioms fires_unique
#print axioms card_parity_eq
#print axioms card_true_le
#print axioms negLits_negLits
#print axioms termFires_negLits
#print axioms andOfOrs_to_orOfAnds
#print axioms fullTerm_fires
#print axioms wires_eq_foldl
#print axioms foldl_wstep_prefix
#print axioms wires_length
#print axioms wires_prefix
#print axioms wires_concat
#print axioms getD_of_prefix
#print axioms output_pad
#print axioms card_code
#print axioms exists_code
#print axioms padded_code
#print axioms depth_two_parity_size_eq
#print axioms parity_term_names_everyone
#print axioms exists_function_needing_more_than_s_gates

end CircuitLowerBounds
