-- Boolean circuits: unfolding a circuit of two-input AND, OR and NOT gates into formulas keeps every output's value and depth and gives it at most 2^d - 1 gates, and the k-bit ripple-carry adder adds correctly with 9k - 5 gates, depth 2k + 2 and 7k^2 - 2 formula gates.
import Mathlib.Data.Nat.Digits.Defs
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.IntervalCases
import Mathlib.Tactic.NormNum

/-! Mathlib has no Boolean circuits, so this file defines them as the card does.
A circuit is a list of gates; wires `0, …, inputs - 1` are the inputs and wire `inputs + j`
is gate `j`. Every gate has at most two inputs (the `Gate` type allows nothing else), and every
gate counts as one, NOT included. A formula is a tree: nothing in it is shared. -/

namespace BooleanCircuits

/-! ### Formulas: trees of gates -/

/-- A formula over the input bits `var 0, var 1, …`: AND, OR and NOT gates in a tree. -/
inductive Formula
  | var (i : ℕ)
  | not (f : Formula)
  | and (f g : Formula)
  | or (f g : Formula)
  deriving DecidableEq

namespace Formula

/-- The size of a formula: its number of gates, NOT included; inputs cost nothing. -/
def size : Formula → ℕ
  | var _ => 0
  | not f => f.size + 1
  | and f g => f.size + g.size + 1
  | or f g => f.size + g.size + 1

/-- The depth of a formula: the number of gates on its longest path from an input. -/
def depth : Formula → ℕ
  | var _ => 0
  | not f => f.depth + 1
  | and f g => max f.depth g.depth + 1
  | or f g => max f.depth g.depth + 1

/-- The value of a formula when input bit `i` is `x i`. -/
def eval (x : ℕ → Bool) : Formula → Bool
  | var i => x i
  | not f => !f.eval x
  | and f g => f.eval x && g.eval x
  | or f g => f.eval x || g.eval x

end Formula

/-! ### Circuits: gate lists that may reuse a wire -/

/-- A gate with at most two inputs; each input is a wire number. -/
inductive Gate
  | not (x : ℕ)
  | and (x y : ℕ)
  | or (x y : ℕ)

namespace Gate

/-- The wires a gate reads. -/
def reads : Gate → List ℕ
  | not x => [x]
  | and x y => [x, y]
  | or x y => [x, y]

/-- The gate's value, given the values of all earlier wires. -/
def value (vs : List Bool) : Gate → Bool
  | not x => !vs.getD x false
  | and x y => vs.getD x false && vs.getD y false
  | or x y => vs.getD x false || vs.getD y false

/-- The gate's depth, given the depths of all earlier wires. -/
def depth (ds : List ℕ) : Gate → ℕ
  | not x => ds.getD x 0 + 1
  | and x y => max (ds.getD x 0) (ds.getD y 0) + 1
  | or x y => max (ds.getD x 0) (ds.getD y 0) + 1

/-- The gate written as a formula, given the formulas of all earlier wires: each wire it reads
is copied in whole. -/
def formula (fs : List Formula) : Gate → Formula
  | not x => .not (fs.getD x (.var 0))
  | and x y => .and (fs.getD x (.var 0)) (fs.getD y (.var 0))
  | or x y => .or (fs.getD x (.var 0)) (fs.getD y (.var 0))

end Gate

/-- A circuit: `inputs` input bits, a list of gates, and the wires marked as outputs. -/
structure Circuit where
  inputs : ℕ
  gates : List Gate
  outputs : List ℕ

namespace Circuit

/-- No loops: gate `j` (wire `inputs + j`) reads only earlier wires, and every output is a wire
of the circuit. -/
def WellFormed (C : Circuit) : Prop :=
  (∀ j (hj : j < C.gates.length), ∀ w ∈ (C.gates[j]'hj).reads, w < C.inputs + j) ∧
    ∀ o ∈ C.outputs, o < C.inputs + C.gates.length

/-- The size of a circuit: its number of gates, NOT included. -/
def size (C : Circuit) : ℕ := C.gates.length

/-- The value on every wire, inputs first, when input bit `i` is `x i`. -/
def wireValues (C : Circuit) (x : ℕ → Bool) : List Bool :=
  C.gates.foldl (fun vs g => vs ++ [g.value vs]) ((List.range C.inputs).map x)

/-- The depth of every wire: gates on its longest path from an input. -/
def wireDepths (C : Circuit) : List ℕ :=
  C.gates.foldl (fun ds g => ds ++ [g.depth ds]) (List.replicate C.inputs 0)

/-- Every wire unfolded into a formula: a wire read twice is copied twice. -/
def wireFormulas (C : Circuit) : List Formula :=
  C.gates.foldl (fun fs g => fs ++ [g.formula fs]) ((List.range C.inputs).map Formula.var)

/-- The output bits, in order. -/
def run (C : Circuit) (x : ℕ → Bool) : List Bool :=
  C.outputs.map fun o => (C.wireValues x).getD o false

/-- The depth of each output. -/
def outputDepths (C : Circuit) : List ℕ :=
  C.outputs.map fun o => C.wireDepths.getD o 0

/-- The depth of a circuit: gates on its longest path from an input to an output. -/
def depth (C : Circuit) : ℕ := C.outputDepths.foldr max 0

/-- The circuit written as formulas, one for each output. -/
def formulas (C : Circuit) : List Formula :=
  C.outputs.map fun o => C.wireFormulas.getD o (.var 0)

/-- The total size of the circuit written as formulas. -/
def formulaSize (C : Circuit) : ℕ := (C.formulas.map Formula.size).sum

end Circuit

/-! ### The main claim -/

/-! ### Helper lemmas for the unfolding theorem -/

/-- Folding gates onto a wire list only appends: one new wire per gate. -/
theorem fold_prefix {α : Type} (f : List α → Gate → α) (gs : List Gate) (l : List α) :
    ∃ t, gs.foldl (fun l g => l ++ [f l g]) l = l ++ t ∧ t.length = gs.length := by
  induction gs generalizing l with
  | nil => exact ⟨[], by simp, rfl⟩
  | cons g gs ih =>
    obtain ⟨t, ht, hl⟩ := ih (l ++ [f l g])
    exact ⟨f l g :: t, by simp [List.foldl_cons, ht], by simp [hl]⟩

#print axioms fold_prefix

/-- The number of wires after folding. -/
theorem fold_length {α : Type} (f : List α → Gate → α) (gs : List Gate) (l : List α) :
    (gs.foldl (fun l g => l ++ [f l g]) l).length = l.length + gs.length := by
  obtain ⟨t, ht, hl⟩ := fold_prefix f gs l
  rw [ht, List.length_append, hl]

#print axioms fold_length

/-- Folding gates leaves the earlier wires unchanged. -/
theorem fold_getD_lt {α : Type} (f : List α → Gate → α) (gs : List Gate) (l : List α) (d : α)
    (w : ℕ) (hw : w < l.length) :
    (gs.foldl (fun l g => l ++ [f l g]) l).getD w d = l.getD w d := by
  obtain ⟨t, ht, -⟩ := fold_prefix f gs l
  rw [ht, List.getD_eq_getElem?_getD, List.getD_eq_getElem?_getD, List.getElem?_append_left hw]

#print axioms fold_getD_lt

/-- The wire of gate `j` holds the gate's rule applied to the finished wire list, provided the
rule only looks at the wires the gate reads and those are all earlier wires. -/
theorem fold_getD_gate {α : Type} (f : List α → Gate → α) (d : α)
    (hf : ∀ g l₁ l₂, (∀ w ∈ g.reads, l₁.getD w d = l₂.getD w d) → f l₁ g = f l₂ g)
    (init : List α) (gs : List Gate) (j : ℕ) (g : Gate) (hg : gs[j]? = some g)
    (hr : ∀ w ∈ g.reads, w < init.length + j) :
    (gs.foldl (fun l g => l ++ [f l g]) init).getD (init.length + j) d =
      f (gs.foldl (fun l g => l ++ [f l g]) init) g := by
  obtain ⟨hj, hgj⟩ := List.getElem?_eq_some_iff.1 hg
  have hsplit : gs = gs.take j ++ g :: gs.drop (j + 1) := by
    conv_lhs => rw [← List.take_append_drop j gs]
    rw [List.drop_eq_getElem_cons hj, hgj]
  obtain ⟨t, ht, htl⟩ := fold_prefix f (gs.take j) init
  have hP : ((gs.take j).foldl (fun l g => l ++ [f l g]) init).length = init.length + j := by
    rw [ht, List.length_append, htl, List.length_take]; omega
  generalize hPdef : (gs.take j).foldl (fun l g => l ++ [f l g]) init = P at hP
  obtain ⟨u, hu, -⟩ := fold_prefix f (gs.drop (j + 1)) (P ++ [f P g])
  have hfin : gs.foldl (fun l g => l ++ [f l g]) init = P ++ ([f P g] ++ u) := by
    conv_lhs => rw [hsplit]
    rw [List.foldl_append, List.foldl_cons, hPdef, hu, List.append_assoc]
  rw [hfin]
  have hloc : f P g = f (P ++ ([f P g] ++ u)) g := hf g _ _ (fun w hw => by
    have := hr w hw
    rw [List.getD_eq_getElem?_getD, List.getD_eq_getElem?_getD,
      List.getElem?_append_left (by omega)])
  rw [← hloc, List.getD_eq_getElem?_getD, List.getElem?_append_right (by omega), ← hP]
  simp

#print axioms fold_getD_gate

theorem value_local (g : Gate) (l₁ l₂ : List Bool)
    (h : ∀ w ∈ g.reads, l₁.getD w false = l₂.getD w false) : g.value l₁ = g.value l₂ := by
  cases g with
  | not x => simp only [Gate.value]; rw [h x (by simp [Gate.reads])]
  | and x y => simp only [Gate.value]; rw [h x (by simp [Gate.reads]), h y (by simp [Gate.reads])]
  | or x y => simp only [Gate.value]; rw [h x (by simp [Gate.reads]), h y (by simp [Gate.reads])]

#print axioms value_local

theorem depth_local (g : Gate) (l₁ l₂ : List ℕ)
    (h : ∀ w ∈ g.reads, l₁.getD w 0 = l₂.getD w 0) : g.depth l₁ = g.depth l₂ := by
  cases g with
  | not x => simp only [Gate.depth]; rw [h x (by simp [Gate.reads])]
  | and x y => simp only [Gate.depth]; rw [h x (by simp [Gate.reads]), h y (by simp [Gate.reads])]
  | or x y => simp only [Gate.depth]; rw [h x (by simp [Gate.reads]), h y (by simp [Gate.reads])]

#print axioms depth_local

theorem formula_local (g : Gate) (l₁ l₂ : List Formula)
    (h : ∀ w ∈ g.reads, l₁.getD w (.var 0) = l₂.getD w (.var 0)) :
    g.formula l₁ = g.formula l₂ := by
  cases g with
  | not x => simp only [Gate.formula]; rw [h x (by simp [Gate.reads])]
  | and x y =>
    simp only [Gate.formula]; rw [h x (by simp [Gate.reads]), h y (by simp [Gate.reads])]
  | or x y =>
    simp only [Gate.formula]; rw [h x (by simp [Gate.reads]), h y (by simp [Gate.reads])]

#print axioms formula_local

/-- One gate: if each wire it reads has a formula with the wire's value and depth, so does the
gate's own formula. -/
theorem gate_formula_step (g : Gate) (F : List Formula) (V : List Bool) (D : List ℕ)
    (x : ℕ → Bool)
    (h : ∀ w ∈ g.reads, (F.getD w (.var 0)).eval x = V.getD w false ∧
      (F.getD w (.var 0)).depth = D.getD w 0) :
    (g.formula F).eval x = g.value V ∧ (g.formula F).depth = g.depth D := by
  cases g with
  | not a =>
    obtain ⟨h1, h2⟩ := h a (by simp [Gate.reads])
    simp only [Gate.formula, Gate.value, Gate.depth, Formula.eval, Formula.depth, h1, h2]
    exact ⟨trivial, trivial⟩
  | and a b =>
    obtain ⟨h1, h2⟩ := h a (by simp [Gate.reads])
    obtain ⟨h3, h4⟩ := h b (by simp [Gate.reads])
    simp only [Gate.formula, Gate.value, Gate.depth, Formula.eval, Formula.depth, h1, h2, h3, h4]
    exact ⟨trivial, trivial⟩
  | or a b =>
    obtain ⟨h1, h2⟩ := h a (by simp [Gate.reads])
    obtain ⟨h3, h4⟩ := h b (by simp [Gate.reads])
    simp only [Gate.formula, Gate.value, Gate.depth, Formula.eval, Formula.depth, h1, h2, h3, h4]
    exact ⟨trivial, trivial⟩

#print axioms gate_formula_step

/-- Every formula has at most `2^depth - 1` gates, written without subtraction. -/
theorem formula_size_add_one_le (F : Formula) : F.size + 1 ≤ 2 ^ F.depth := by
  induction F with
  | var i => simp [Formula.size, Formula.depth]
  | not f ih =>
    simp only [Formula.size, Formula.depth, pow_succ]
    have := Nat.one_le_two_pow (n := f.depth)
    omega
  | and f g ihf ihg =>
    simp only [Formula.size, Formula.depth, pow_succ]
    have h1 : 2 ^ f.depth ≤ 2 ^ max f.depth g.depth :=
      Nat.pow_le_pow_right (by norm_num) (le_max_left _ _)
    have h2 : 2 ^ g.depth ≤ 2 ^ max f.depth g.depth :=
      Nat.pow_le_pow_right (by norm_num) (le_max_right _ _)
    omega
  | or f g ihf ihg =>
    simp only [Formula.size, Formula.depth, pow_succ]
    have h1 : 2 ^ f.depth ≤ 2 ^ max f.depth g.depth :=
      Nat.pow_le_pow_right (by norm_num) (le_max_left _ _)
    have h2 : 2 ^ g.depth ≤ 2 ^ max f.depth g.depth :=
      Nat.pow_le_pow_right (by norm_num) (le_max_right _ _)
    omega

#print axioms formula_size_add_one_le

/-- Every wire of a circuit with no loops: its formula has the wire's value and depth. -/
theorem wire_formula_correct (C : Circuit) (hC : C.WellFormed) (x : ℕ → Bool) :
    ∀ w, w < C.inputs + C.gates.length →
      (C.wireFormulas.getD w (.var 0)).eval x = (C.wireValues x).getD w false ∧
        (C.wireFormulas.getD w (.var 0)).depth = C.wireDepths.getD w 0 := by
  intro w
  induction w using Nat.strong_induction_on with
  | _ w ih =>
    intro hw
    by_cases hin : w < C.inputs
    · simp only [Circuit.wireFormulas, Circuit.wireValues, Circuit.wireDepths]
      rw [fold_getD_lt _ _ _ _ _ (by simpa using hin), fold_getD_lt _ _ _ _ _ (by simpa using hin),
        fold_getD_lt _ _ _ _ _ (by simpa using hin)]
      simp [List.getD_eq_getElem?_getD, hin, Formula.eval, Formula.depth]
    · obtain ⟨j, rfl⟩ : ∃ j, w = C.inputs + j := ⟨w - C.inputs, by omega⟩
      have hj : j < C.gates.length := by omega
      have hg : C.gates[j]? = some (C.gates[j]'hj) := List.getElem?_eq_getElem hj
      have hr := hC.1 j hj
      simp only [Circuit.wireFormulas, Circuit.wireValues, Circuit.wireDepths]
      have eF := fold_getD_gate (fun fs g => g.formula fs) (.var 0) formula_local
        ((List.range C.inputs).map Formula.var) C.gates j _ hg (by simpa using hr)
      have eV := fold_getD_gate (fun vs g => g.value vs) false value_local
        ((List.range C.inputs).map x) C.gates j _ hg (by simpa using hr)
      have eD := fold_getD_gate (fun ds g => g.depth ds) 0 depth_local
        (List.replicate C.inputs 0) C.gates j _ hg (by simpa using hr)
      simp only [List.length_map, List.length_range, List.length_replicate] at eF eV eD
      rw [eF, eV, eD]
      exact gate_formula_step _ _ _ _ x (fun r hrr => ih r (by have := hr r hrr; omega)
        (by have := hr r hrr; omega))

#print axioms wire_formula_correct

/-- **Unfolding a circuit into formulas.** Take a circuit with no loops whose gates are AND, OR
and NOT with at most two inputs. Write any output as a formula by copying every shared part.
The formula computes the same bit on every input, has exactly the same depth `d` as that output
of the circuit, and has at most `2^d - 1` gates. -/
theorem unfolding_keeps_depth_and_size_le_two_pow_depth_sub_one (C : Circuit)
    (hC : C.WellFormed) (o : ℕ) (ho : o ∈ C.outputs) :
    (∀ x : ℕ → Bool, (C.wireFormulas.getD o (.var 0)).eval x = (C.wireValues x).getD o false) ∧
      (C.wireFormulas.getD o (.var 0)).depth = C.wireDepths.getD o 0 ∧
      (C.wireFormulas.getD o (.var 0)).size ≤ 2 ^ (C.wireFormulas.getD o (.var 0)).depth - 1 := by
  have hlen : o < C.inputs + C.gates.length := hC.2 o ho
  refine ⟨fun x => (wire_formula_correct C hC x o hlen).1,
    (wire_formula_correct C hC (fun _ => false) o hlen).2, ?_⟩
  have := formula_size_add_one_le (C.wireFormulas.getD o (.var 0))
  omega

/-! ### The ripple-carry adder

Inputs: wire `i` is `a_i` and wire `k + i` is `b_i`, low bit first. With `N = 2k`, bit 0 is the
half adder at wires `N, …, N + 3` (`N` is the carry `c_0`, `N + 3` the sum bit `s_0`). Bit `i ≥ 1`
is a block of 9 gates starting at wire `B = N + 9i - 5`: `h = a_i AND b_i`, the XOR `t`, then
`u = t AND c_{i-1}`, the sum bit `s_i = t XOR c_{i-1}` at `B + 7`, and the carry
`c_i = h OR u` at `B + 8`. The outputs are `s_0, …, s_{k-1}` and the last carry `s_k = c_{k-1}`. -/

/-- The wire holding the carry `c_i` out of bit `i`. -/
def carryWire (k i : ℕ) : ℕ := if i = 0 then 2 * k else 2 * k + 9 * i + 3

/-- Bit 0: the half adder `a_0 AND b_0`, `a_0 OR b_0`, `NOT (a_0 AND b_0)`, and the sum bit. -/
def halfAdder (k : ℕ) : List Gate :=
  [.and 0 k, .or 0 k, .not (2 * k), .and (2 * k + 1) (2 * k + 2)]

/-- Bit `i ≥ 1`: the 9-gate block adding `a_i`, `b_i` and the carry `c_{i-1}`. -/
def fullAdder (k i : ℕ) : List Gate :=
  let B := 2 * k + 9 * i - 5
  let c := carryWire k (i - 1)
  [.and i (k + i), .or i (k + i), .not B, .and (B + 1) (B + 2),
    .and (B + 3) c, .or (B + 3) c, .not (B + 4), .and (B + 5) (B + 6),
    .or B (B + 4)]

/-- The ripple-carry adder `C_k` for two `k`-bit numbers. -/
def ripple (k : ℕ) : Circuit where
  inputs := 2 * k
  gates := halfAdder k ++ (List.range (k - 1)).flatMap fun j => fullAdder k (j + 1)
  outputs := (2 * k + 3) :: ((List.range (k - 1)).map fun j => 2 * k + 9 * (j + 1) + 2) ++
    [carryWire k (k - 1)]

/-- The input bits for adding `a` and `b`: bit `i` of `a` on wire `i`, bit `i` of `b` on wire `k + i`. -/
def inputBits (k a b : ℕ) : ℕ → Bool := fun w => if w < k then a.testBit w else b.testBit (w - k)

/-- The number whose binary digits, low bit first, are the given bits. -/
def bitsValue (l : List Bool) : ℕ := Nat.ofDigits 2 (l.map Bool.toNat)

/-! ### Helper lemmas for the ripple-carry adder -/

theorem fullAdder_succ (k j : ℕ) : fullAdder k (j + 1) =
    [.and (j + 1) (k + (j + 1)), .or (j + 1) (k + (j + 1)), .not (2 * k + 9 * j + 4),
      .and (2 * k + 9 * j + 4 + 1) (2 * k + 9 * j + 4 + 2),
      .and (2 * k + 9 * j + 4 + 3) (carryWire k j), .or (2 * k + 9 * j + 4 + 3) (carryWire k j),
      .not (2 * k + 9 * j + 4 + 4), .and (2 * k + 9 * j + 4 + 5) (2 * k + 9 * j + 4 + 6),
      .or (2 * k + 9 * j + 4) (2 * k + 9 * j + 4 + 4)] := by
  have h : 2 * k + 9 * (j + 1) - 5 = 2 * k + 9 * j + 4 := by omega
  simp only [fullAdder, h, Nat.add_sub_cancel]

#print axioms fullAdder_succ

theorem flat_length (k m : ℕ) :
    ((List.range m).flatMap fun j => fullAdder k (j + 1)).length = 9 * m := by
  induction m with
  | zero => simp
  | succ m ih =>
    rw [List.range_succ, List.flatMap_append, List.length_append, ih, List.flatMap_singleton]
    simp [fullAdder]
    omega

#print axioms flat_length

theorem flat_get (k m j r : ℕ) (hj : j < m) (hr : r < 9) :
    ((List.range m).flatMap fun j => fullAdder k (j + 1))[9 * j + r]? =
      (fullAdder k (j + 1))[r]? := by
  induction m with
  | zero => omega
  | succ m ih =>
    rw [List.range_succ, List.flatMap_append]
    rcases Nat.lt_succ_iff_lt_or_eq.1 hj with h | h
    · rw [List.getElem?_append_left (by rw [flat_length]; omega), ih h]
    · subst h
      rw [List.getElem?_append_right (by rw [flat_length]; omega), flat_length,
        List.flatMap_singleton, Nat.add_sub_cancel_left]

#print axioms flat_get

theorem ripple_size (k : ℕ) (hk : 1 ≤ k) : (ripple k).gates.length = 9 * k - 5 := by
  simp only [ripple, List.length_append, flat_length]
  simp [halfAdder]
  omega

#print axioms ripple_size

theorem ripple_gate_half (k r : ℕ) (hr : r < 4) :
    (ripple k).gates[r]? = (halfAdder k)[r]? := by
  simp only [ripple]
  rw [List.getElem?_append_left (by simp [halfAdder]; omega)]

#print axioms ripple_gate_half

theorem ripple_gate_full (k j r : ℕ) (hj : j < k - 1) (hr : r < 9) :
    (ripple k).gates[4 + 9 * j + r]? = (fullAdder k (j + 1))[r]? := by
  simp only [ripple]
  rw [List.getElem?_append_right (by simp only [halfAdder, List.length_cons, List.length_nil]; omega)]
  have : 4 + 9 * j + r - (halfAdder k).length = 9 * j + r := by simp [halfAdder]; omega
  rw [this, flat_get k (k - 1) j r hj hr]

#print axioms ripple_gate_full

theorem half_reads (k r : ℕ) (hk : 1 ≤ k) (hr : r < 4) (g : Gate) (hg : (halfAdder k)[r]? = some g) :
    ∀ w ∈ g.reads, w < 2 * k + r := by
  intro w hw
  interval_cases r <;> simp [halfAdder] at hg <;> subst hg <;> simp [Gate.reads] at hw <;> omega

#print axioms half_reads

theorem full_reads (k j r : ℕ) (hr : r < 9) (g : Gate)
    (hg : (fullAdder k (j + 1))[r]? = some g) : ∀ w ∈ g.reads, w < 2 * k + 9 * j + 4 + r := by
  intro w hw
  rw [fullAdder_succ] at hg
  have hc : carryWire k j < 2 * k + 9 * j + 4 := by unfold carryWire; split <;> omega
  interval_cases r <;> simp at hg <;> subst hg <;> simp [Gate.reads] at hw <;> omega

#print axioms full_reads

/-- A half-adder wire of `C_k` holds its gate's rule applied to the finished wire list. -/
theorem ripple_half_wire {α : Type} (k : ℕ) (hk : 1 ≤ k) (f : List α → Gate → α) (d : α)
    (hf : ∀ g l₁ l₂, (∀ w ∈ g.reads, l₁.getD w d = l₂.getD w d) → f l₁ g = f l₂ g)
    (init : List α) (hinit : init.length = 2 * k) (r : ℕ) (hr : r < 4) (g : Gate)
    (hg : (halfAdder k)[r]? = some g) :
    ((ripple k).gates.foldl (fun l g => l ++ [f l g]) init).getD (2 * k + r) d =
      f ((ripple k).gates.foldl (fun l g => l ++ [f l g]) init) g := by
  have := fold_getD_gate f d hf init (ripple k).gates r g (by rw [ripple_gate_half k r hr, hg])
    (by rw [hinit]; exact half_reads k r hk hr g hg)
  rwa [hinit] at this

#print axioms ripple_half_wire

/-- A full-adder wire of `C_k` holds its gate's rule applied to the finished wire list. -/
theorem ripple_full_wire {α : Type} (k : ℕ) (f : List α → Gate → α) (d : α)
    (hf : ∀ g l₁ l₂, (∀ w ∈ g.reads, l₁.getD w d = l₂.getD w d) → f l₁ g = f l₂ g)
    (init : List α) (hinit : init.length = 2 * k) (j r : ℕ) (hj : j < k - 1) (hr : r < 9)
    (g : Gate) (hg : (fullAdder k (j + 1))[r]? = some g) :
    ((ripple k).gates.foldl (fun l g => l ++ [f l g]) init).getD (2 * k + 9 * j + 4 + r) d =
      f ((ripple k).gates.foldl (fun l g => l ++ [f l g]) init) g := by
  have := fold_getD_gate f d hf init (ripple k).gates (4 + 9 * j + r) g
    (by rw [ripple_gate_full k j r hj hr, hg])
    (by rw [hinit]; have := full_reads k j r hr g hg; intro w hw; have := this w hw; omega)
  rw [hinit, show 2 * k + (4 + 9 * j + r) = 2 * k + 9 * j + 4 + r by omega] at this
  exact this

#print axioms ripple_full_wire

/-! Wire values of `C_k`. -/

theorem V_input (k : ℕ) (x : ℕ → Bool) (w : ℕ) (hw : w < 2 * k) :
    ((ripple k).wireValues x).getD w false = x w := by
  unfold Circuit.wireValues
  rw [fold_getD_lt _ _ _ _ _ (by simpa [ripple] using hw)]
  simp [List.getD_eq_getElem?_getD, ripple, hw]

#print axioms V_input

theorem V_half (k : ℕ) (hk : 1 ≤ k) (x : ℕ → Bool) (r : ℕ) (hr : r < 4) (g : Gate)
    (hg : (halfAdder k)[r]? = some g) :
    ((ripple k).wireValues x).getD (2 * k + r) false = g.value ((ripple k).wireValues x) :=
  ripple_half_wire k hk (fun vs g => g.value vs) false value_local ((List.range (2 * k)).map x)
    (by simp) r hr g hg

#print axioms V_half

theorem V_full (k : ℕ) (x : ℕ → Bool) (j r : ℕ) (hj : j < k - 1) (hr : r < 9) (g : Gate)
    (hg : (fullAdder k (j + 1))[r]? = some g) :
    ((ripple k).wireValues x).getD (2 * k + 9 * j + 4 + r) false =
      g.value ((ripple k).wireValues x) :=
  ripple_full_wire k (fun vs g => g.value vs) false value_local ((List.range (2 * k)).map x)
    (by simp) j r hj hr g hg

#print axioms V_full

/-- The sum bit and the carry out of a full-adder block, in terms of its three inputs. -/
theorem block_values (k : ℕ) (x : ℕ → Bool) (j : ℕ) (hj : j < k - 1) :
    ((ripple k).wireValues x).getD (2 * k + 9 * j + 4 + 7) false =
        ((((ripple k).wireValues x).getD (j + 1) false ^^
          ((ripple k).wireValues x).getD (k + (j + 1)) false) ^^
          ((ripple k).wireValues x).getD (carryWire k j) false) ∧
      ((ripple k).wireValues x).getD (2 * k + 9 * j + 4 + 8) false =
        ((((ripple k).wireValues x).getD (j + 1) false &&
          ((ripple k).wireValues x).getD (k + (j + 1)) false) ||
          ((((ripple k).wireValues x).getD (j + 1) false ^^
            ((ripple k).wireValues x).getD (k + (j + 1)) false) &&
            ((ripple k).wireValues x).getD (carryWire k j) false)) := by
  have e0 := V_full k x j 0 hj (by norm_num) _ (by rw [fullAdder_succ]; rfl)
  have e1 := V_full k x j 1 hj (by norm_num) _ (by rw [fullAdder_succ]; rfl)
  have e2 := V_full k x j 2 hj (by norm_num) _ (by rw [fullAdder_succ]; rfl)
  have e3 := V_full k x j 3 hj (by norm_num) _ (by rw [fullAdder_succ]; rfl)
  have e4 := V_full k x j 4 hj (by norm_num) _ (by rw [fullAdder_succ]; rfl)
  have e5 := V_full k x j 5 hj (by norm_num) _ (by rw [fullAdder_succ]; rfl)
  have e6 := V_full k x j 6 hj (by norm_num) _ (by rw [fullAdder_succ]; rfl)
  have e7 := V_full k x j 7 hj (by norm_num) _ (by rw [fullAdder_succ]; rfl)
  have e8 := V_full k x j 8 hj (by norm_num) _ (by rw [fullAdder_succ]; rfl)
  simp only [Gate.value, Nat.add_zero] at e0 e1 e2 e3 e4 e5 e6 e7 e8
  rw [e7, e8, e5, e6, e4, e3, e1, e2, e0]
  generalize ((ripple k).wireValues x).getD (j + 1) false = p
  generalize ((ripple k).wireValues x).getD (k + (j + 1)) false = q
  generalize ((ripple k).wireValues x).getD (carryWire k j) false = c
  cases p <;> cases q <;> cases c <;> exact ⟨rfl, rfl⟩

#print axioms block_values

/-! Binary arithmetic: the carry into bit `i` is `2^i ≤ a mod 2^i + b mod 2^i`. -/

theorem mod_two_pow_succ' (a i : ℕ) : a % 2 ^ (i + 1) = a % 2 ^ i + 2 ^ i * (a.testBit i).toNat := by
  rw [Nat.mod_pow_succ, Nat.toNat_testBit]

#print axioms mod_two_pow_succ'

theorem carry_succ (a b i : ℕ) :
    decide (2 ^ (i + 1) ≤ a % 2 ^ (i + 1) + b % 2 ^ (i + 1)) =
      ((a.testBit i && b.testBit i) ||
        ((a.testBit i ^^ b.testBit i) && decide (2 ^ i ≤ a % 2 ^ i + b % 2 ^ i))) := by
  have ha := Nat.mod_lt a (Nat.two_pow_pos i)
  have hb := Nat.mod_lt b (Nat.two_pow_pos i)
  rw [mod_two_pow_succ' a i, mod_two_pow_succ' b i, pow_succ]
  generalize a % 2 ^ i = A at *
  generalize b % 2 ^ i = B at *
  generalize 2 ^ i = P at *
  cases a.testBit i <;> cases b.testBit i <;> by_cases h : P ≤ A + B <;> simp [h] <;> omega

#print axioms carry_succ

theorem sum_bits (a b m : ℕ) :
    Nat.ofDigits 2 ((List.range m).map fun i =>
        ((a.testBit i ^^ b.testBit i) ^^ decide (2 ^ i ≤ a % 2 ^ i + b % 2 ^ i)).toNat) +
      2 ^ m * (decide (2 ^ m ≤ a % 2 ^ m + b % 2 ^ m)).toNat = a % 2 ^ m + b % 2 ^ m := by
  induction m with
  | zero => simp [Nat.mod_one]
  | succ m ih =>
    rw [List.range_succ, List.map_append, Nat.ofDigits_append, List.length_map,
      List.length_range, List.map_singleton, Nat.ofDigits_singleton, carry_succ,
      mod_two_pow_succ' a m, mod_two_pow_succ' b m, pow_succ]
    generalize decide (2 ^ m ≤ a % 2 ^ m + b % 2 ^ m) = c at *
    generalize Nat.ofDigits 2 _ = X at *
    generalize a.testBit m = p
    generalize b.testBit m = q
    generalize a % 2 ^ m = A at *
    generalize b % 2 ^ m = B at *
    generalize 2 ^ m = P at *
    cases p <;> cases q <;> cases c <;> simp at * <;> omega

#print axioms sum_bits

theorem input_a (k a b i : ℕ) (hi : i < k) : inputBits k a b i = a.testBit i := by
  simp [inputBits, hi]

#print axioms input_a

theorem input_b (k a b i : ℕ) : inputBits k a b (k + i) = b.testBit i := by
  simp [inputBits]

#print axioms input_b

/-- The carry wire `c_i` of `C_k` holds the carry out of bit `i`. -/
theorem carry_val (k a b : ℕ) (hk : 1 ≤ k) : ∀ i, i < k →
    ((ripple k).wireValues (inputBits k a b)).getD (carryWire k i) false =
      decide (2 ^ (i + 1) ≤ a % 2 ^ (i + 1) + b % 2 ^ (i + 1)) := by
  intro i
  induction i with
  | zero =>
    intro _
    have e := V_half k hk (inputBits k a b) 0 (by norm_num) _ rfl
    simp only [Gate.value, Nat.add_zero] at e
    rw [show carryWire k 0 = 2 * k by simp [carryWire], e, V_input k _ 0 (by omega),
      V_input k _ k (by omega), carry_succ, input_a k a b 0 (by omega)]
    have := input_b k a b 0
    rw [Nat.add_zero] at this
    rw [this]
    simp [Nat.mod_one]
  | succ j ih =>
    intro hj
    have hj' : j < k - 1 := by omega
    rw [show carryWire k (j + 1) = 2 * k + 9 * j + 4 + 8 by simp [carryWire]; omega,
      (block_values k _ j hj').2, ih (by omega), V_input k _ (j + 1) (by omega),
      V_input k _ (k + (j + 1)) (by omega), input_a k a b (j + 1) hj, input_b, carry_succ a b (j + 1)]

#print axioms carry_val

/-- The sum wire of bit `j + 1` holds `a_{j+1} XOR b_{j+1} XOR` the carry into that bit. -/
theorem sum_val (k a b j : ℕ) (hk : 1 ≤ k) (hj : j < k - 1) :
    ((ripple k).wireValues (inputBits k a b)).getD (2 * k + 9 * (j + 1) + 2) false =
      ((a.testBit (j + 1) ^^ b.testBit (j + 1)) ^^
        decide (2 ^ (j + 1) ≤ a % 2 ^ (j + 1) + b % 2 ^ (j + 1))) := by
  rw [show 2 * k + 9 * (j + 1) + 2 = 2 * k + 9 * j + 4 + 7 by omega, (block_values k _ j hj).1,
    carry_val k a b hk j (by omega), V_input k _ (j + 1) (by omega),
    V_input k _ (k + (j + 1)) (by omega), input_a k a b (j + 1) (by omega), input_b]

#print axioms sum_val

/-- The sum wire of bit 0. -/
theorem sum0_val (k a b : ℕ) (hk : 1 ≤ k) :
    ((ripple k).wireValues (inputBits k a b)).getD (2 * k + 3) false =
      ((a.testBit 0 ^^ b.testBit 0) ^^ decide (2 ^ 0 ≤ a % 2 ^ 0 + b % 2 ^ 0)) := by
  have e0 := V_half k hk (inputBits k a b) 0 (by norm_num) _ rfl
  have e1 := V_half k hk (inputBits k a b) 1 (by norm_num) _ rfl
  have e2 := V_half k hk (inputBits k a b) 2 (by norm_num) _ rfl
  have e3 := V_half k hk (inputBits k a b) 3 (by norm_num) _ rfl
  simp only [Gate.value, Nat.add_zero] at e0 e1 e2 e3
  rw [e3, e1, e2, e0, V_input k _ 0 (by omega), V_input k _ k (by omega),
    input_a k a b 0 (by omega)]
  have := input_b k a b 0
  rw [Nat.add_zero] at this
  rw [this]
  cases a.testBit 0 <;> cases b.testBit 0 <;> simp [Nat.mod_one]

#print axioms sum0_val

/-! Wire depths and wire formulas of `C_k`. -/

theorem D_input (k w : ℕ) (hw : w < 2 * k) : (ripple k).wireDepths.getD w 0 = 0 := by
  unfold Circuit.wireDepths
  rw [fold_getD_lt _ _ _ _ _ (by simpa [ripple] using hw)]
  simp [List.getD_eq_getElem?_getD, ripple, hw]

#print axioms D_input

theorem D_half (k : ℕ) (hk : 1 ≤ k) (r : ℕ) (hr : r < 4) (g : Gate)
    (hg : (halfAdder k)[r]? = some g) :
    (ripple k).wireDepths.getD (2 * k + r) 0 = g.depth (ripple k).wireDepths :=
  ripple_half_wire k hk (fun ds g => g.depth ds) 0 depth_local (List.replicate (2 * k) 0)
    (by simp) r hr g hg

#print axioms D_half

theorem D_full (k j r : ℕ) (hj : j < k - 1) (hr : r < 9) (g : Gate)
    (hg : (fullAdder k (j + 1))[r]? = some g) :
    (ripple k).wireDepths.getD (2 * k + 9 * j + 4 + r) 0 = g.depth (ripple k).wireDepths :=
  ripple_full_wire k (fun ds g => g.depth ds) 0 depth_local (List.replicate (2 * k) 0)
    (by simp) j r hj hr g hg

#print axioms D_full

theorem block_depths (k j : ℕ) (hj : j < k - 1) :
    (ripple k).wireDepths.getD (2 * k + 9 * j + 4 + 7) 0 =
        max 3 ((ripple k).wireDepths.getD (carryWire k j) 0) + 3 ∧
      (ripple k).wireDepths.getD (2 * k + 9 * j + 4 + 8) 0 =
        max 3 ((ripple k).wireDepths.getD (carryWire k j) 0) + 2 := by
  have e0 := D_full k j 0 hj (by norm_num) _ (by rw [fullAdder_succ]; rfl)
  have e1 := D_full k j 1 hj (by norm_num) _ (by rw [fullAdder_succ]; rfl)
  have e2 := D_full k j 2 hj (by norm_num) _ (by rw [fullAdder_succ]; rfl)
  have e3 := D_full k j 3 hj (by norm_num) _ (by rw [fullAdder_succ]; rfl)
  have e4 := D_full k j 4 hj (by norm_num) _ (by rw [fullAdder_succ]; rfl)
  have e5 := D_full k j 5 hj (by norm_num) _ (by rw [fullAdder_succ]; rfl)
  have e6 := D_full k j 6 hj (by norm_num) _ (by rw [fullAdder_succ]; rfl)
  have e7 := D_full k j 7 hj (by norm_num) _ (by rw [fullAdder_succ]; rfl)
  have e8 := D_full k j 8 hj (by norm_num) _ (by rw [fullAdder_succ]; rfl)
  simp only [Gate.depth, Nat.add_zero] at e0 e1 e2 e3 e4 e5 e6 e7 e8
  rw [e7, e8, e5, e6, e4, e3, e1, e2, e0, D_input k (j + 1) (by omega),
    D_input k (k + (j + 1)) (by omega)]
  omega

#print axioms block_depths

theorem carry_depth (k : ℕ) (hk : 1 ≤ k) : ∀ i, i < k →
    (ripple k).wireDepths.getD (carryWire k i) 0 = if i = 0 then 1 else 2 * i + 3 := by
  intro i
  induction i with
  | zero =>
    intro _
    have e := D_half k hk 0 (by norm_num) _ rfl
    simp only [Gate.depth, Nat.add_zero] at e
    rw [show carryWire k 0 = 2 * k by simp [carryWire], e, D_input k 0 (by omega),
      D_input k k (by omega)]
    rfl
  | succ j ih =>
    intro hj
    rw [show carryWire k (j + 1) = 2 * k + 9 * j + 4 + 8 by simp [carryWire]; omega,
      (block_depths k j (by omega)).2, ih (by omega)]
    by_cases h : j = 0 <;> simp [h]; omega

#print axioms carry_depth

theorem F_input (k w : ℕ) (hw : w < 2 * k) : (ripple k).wireFormulas.getD w (.var 0) = .var w := by
  unfold Circuit.wireFormulas
  rw [fold_getD_lt _ _ _ _ _ (by simpa [ripple] using hw)]
  simp [List.getD_eq_getElem?_getD, ripple, hw]

#print axioms F_input

theorem F_half (k : ℕ) (hk : 1 ≤ k) (r : ℕ) (hr : r < 4) (g : Gate)
    (hg : (halfAdder k)[r]? = some g) :
    (ripple k).wireFormulas.getD (2 * k + r) (.var 0) = g.formula (ripple k).wireFormulas :=
  ripple_half_wire k hk (fun fs g => g.formula fs) (.var 0) formula_local
    ((List.range (2 * k)).map Formula.var) (by simp) r hr g hg

#print axioms F_half

theorem F_full (k j r : ℕ) (hj : j < k - 1) (hr : r < 9) (g : Gate)
    (hg : (fullAdder k (j + 1))[r]? = some g) :
    (ripple k).wireFormulas.getD (2 * k + 9 * j + 4 + r) (.var 0) =
      g.formula (ripple k).wireFormulas :=
  ripple_full_wire k (fun fs g => g.formula fs) (.var 0) formula_local
    ((List.range (2 * k)).map Formula.var) (by simp) j r hj hr g hg

#print axioms F_full

theorem block_sizes (k j : ℕ) (hj : j < k - 1) :
    ((ripple k).wireFormulas.getD (2 * k + 9 * j + 4 + 7) (.var 0)).size =
        2 * ((ripple k).wireFormulas.getD (carryWire k j) (.var 0)).size + 12 ∧
      ((ripple k).wireFormulas.getD (2 * k + 9 * j + 4 + 8) (.var 0)).size =
        ((ripple k).wireFormulas.getD (carryWire k j) (.var 0)).size + 7 := by
  have e0 := F_full k j 0 hj (by norm_num) _ (by rw [fullAdder_succ]; rfl)
  have e1 := F_full k j 1 hj (by norm_num) _ (by rw [fullAdder_succ]; rfl)
  have e2 := F_full k j 2 hj (by norm_num) _ (by rw [fullAdder_succ]; rfl)
  have e3 := F_full k j 3 hj (by norm_num) _ (by rw [fullAdder_succ]; rfl)
  have e4 := F_full k j 4 hj (by norm_num) _ (by rw [fullAdder_succ]; rfl)
  have e5 := F_full k j 5 hj (by norm_num) _ (by rw [fullAdder_succ]; rfl)
  have e6 := F_full k j 6 hj (by norm_num) _ (by rw [fullAdder_succ]; rfl)
  have e7 := F_full k j 7 hj (by norm_num) _ (by rw [fullAdder_succ]; rfl)
  have e8 := F_full k j 8 hj (by norm_num) _ (by rw [fullAdder_succ]; rfl)
  simp only [Gate.formula, Nat.add_zero] at e0 e1 e2 e3 e4 e5 e6 e7 e8
  rw [e7, e8, e5, e6, e4, e3, e1, e2, e0, F_input k (j + 1) (by omega),
    F_input k (k + (j + 1)) (by omega)]
  simp only [Formula.size]
  omega

#print axioms block_sizes

theorem carry_size (k : ℕ) (hk : 1 ≤ k) : ∀ i, i < k →
    ((ripple k).wireFormulas.getD (carryWire k i) (.var 0)).size = 7 * i + 1 := by
  intro i
  induction i with
  | zero =>
    intro _
    have e := F_half k hk 0 (by norm_num) _ rfl
    simp only [Gate.formula, Nat.add_zero] at e
    rw [show carryWire k 0 = 2 * k by simp [carryWire], e, F_input k 0 (by omega),
      F_input k k (by omega)]
    rfl
  | succ j ih =>
    intro hj
    rw [show carryWire k (j + 1) = 2 * k + 9 * j + 4 + 8 by simp [carryWire]; omega,
      (block_sizes k j (by omega)).2, ih (by omega)]
    ring

#print axioms carry_size

theorem foldr_max_le (l : List ℕ) (M : ℕ) (h : ∀ x ∈ l, x ≤ M) : l.foldr max 0 ≤ M := by
  induction l with
  | nil => simp
  | cons a l ih =>
    simp only [List.mem_cons, forall_eq_or_imp] at h
    simp only [List.foldr_cons]
    exact max_le h.1 (ih h.2)

#print axioms foldr_max_le

theorem le_foldr_max (l : List ℕ) (x : ℕ) (hx : x ∈ l) : x ≤ l.foldr max 0 := by
  induction l with
  | nil => simp at hx
  | cons a l ih =>
    simp only [List.mem_cons] at hx
    simp only [List.foldr_cons]
    rcases hx with rfl | hx
    · exact le_max_left _ _
    · exact le_trans (ih hx) (le_max_right _ _)

#print axioms le_foldr_max

theorem sum_range_fourteen (m : ℕ) :
    ((List.range m).map fun j => 14 * (j + 1)).sum = 7 * m * (m + 1) := by
  induction m with
  | zero => simp
  | succ m ih =>
    rw [List.range_succ, List.map_append, List.sum_append, ih]
    simp
    ring

#print axioms sum_range_fourteen

/-- **The ripple-carry adder adds.** For `k ≥ 1` and two `k`-bit numbers `a` and `b`, the
`k + 1` output bits of `C_k` spell `a + b` in binary. -/
theorem ripple_carry_adder_adds (k a b : ℕ) (hk : 1 ≤ k) (ha : a < 2 ^ k) (hb : b < 2 ^ k) :
    bitsValue ((ripple k).run (inputBits k a b)) = a + b := by
  obtain ⟨m, rfl⟩ : ∃ m, k = m + 1 := ⟨k - 1, by omega⟩
  have hrun : (ripple (m + 1)).run (inputBits (m + 1) a b) =
      ((List.range (m + 1)).map fun i =>
        ((a.testBit i ^^ b.testBit i) ^^ decide (2 ^ i ≤ a % 2 ^ i + b % 2 ^ i))) ++
        [decide (2 ^ (m + 1) ≤ a % 2 ^ (m + 1) + b % 2 ^ (m + 1))] := by
    have hout : (ripple (m + 1)).outputs = (2 * (m + 1) + 3) ::
        ((List.range m).map fun j => 2 * (m + 1) + 9 * (j + 1) + 2) ++ [carryWire (m + 1) m] := rfl
    simp only [Circuit.run, hout, List.map_cons, List.map_append, List.map_map, List.map_nil]
    rw [List.range_succ_eq_map, List.map_cons, List.map_map, List.cons_append]
    congr 1
    · exact sum0_val (m + 1) a b hk
    · congr 1
      · apply List.map_congr_left
        intro j hj
        rw [List.mem_range] at hj
        exact sum_val (m + 1) a b j hk (by omega)
      · rw [carry_val (m + 1) a b hk m (by omega)]
  unfold bitsValue
  rw [hrun, List.map_append, Nat.ofDigits_append, List.map_singleton, Nat.ofDigits_singleton,
    List.map_map]
  simp only [List.length_map, List.length_range]
  have := sum_bits a b (m + 1)
  exact this.trans (by rw [Nat.mod_eq_of_lt ha, Nat.mod_eq_of_lt hb])

/-- **The three exact counts.** For `k ≥ 2`, the ripple-carry adder has `9k - 5` gates and depth
`2k + 2`, and written as formulas it has `7k^2 - 2` gates. -/
theorem ripple_carry_adder_counts (k : ℕ) (hk : 2 ≤ k) :
    (ripple k).size = 9 * k - 5 ∧ (ripple k).depth = 2 * k + 2 ∧
      (ripple k).formulaSize = 7 * k ^ 2 - 2 := by
  have hk1 : 1 ≤ k := by omega
  have hout : (ripple k).outputs = (2 * k + 3) ::
      ((List.range (k - 1)).map fun j => 2 * k + 9 * (j + 1) + 2) ++ [carryWire k (k - 1)] := rfl
  -- depths of the outputs
  have d0 : (ripple k).wireDepths.getD (2 * k + 3) 0 = 3 := by
    have e0 := D_half k hk1 0 (by norm_num) _ rfl
    have e1 := D_half k hk1 1 (by norm_num) _ rfl
    have e2 := D_half k hk1 2 (by norm_num) _ rfl
    have e3 := D_half k hk1 3 (by norm_num) _ rfl
    simp only [Gate.depth, Nat.add_zero] at e0 e1 e2 e3
    rw [e3, e1, e2, e0, D_input k 0 (by omega), D_input k k (by omega)]
    rfl
  have dj : ∀ j, j < k - 1 → (ripple k).wireDepths.getD (2 * k + 9 * (j + 1) + 2) 0 =
      if j = 0 then 6 else 2 * j + 6 := by
    intro j hj
    rw [show 2 * k + 9 * (j + 1) + 2 = 2 * k + 9 * j + 4 + 7 by omega, (block_depths k j hj).1,
      carry_depth k hk1 j (by omega)]
    split_ifs <;> omega
  have dlast : (ripple k).wireDepths.getD (carryWire k (k - 1)) 0 = 2 * k + 1 := by
    rw [carry_depth k hk1 (k - 1) (by omega)]
    split_ifs <;> omega
  -- sizes of the output formulas
  have s0 : ((ripple k).wireFormulas.getD (2 * k + 3) (.var 0)).size = 4 := by
    have e0 := F_half k hk1 0 (by norm_num) _ rfl
    have e1 := F_half k hk1 1 (by norm_num) _ rfl
    have e2 := F_half k hk1 2 (by norm_num) _ rfl
    have e3 := F_half k hk1 3 (by norm_num) _ rfl
    simp only [Gate.formula, Nat.add_zero] at e0 e1 e2 e3
    rw [e3, e1, e2, e0, F_input k 0 (by omega), F_input k k (by omega)]
    rfl
  have sj : ∀ j, j < k - 1 →
      ((ripple k).wireFormulas.getD (2 * k + 9 * (j + 1) + 2) (.var 0)).size = 14 * (j + 1) := by
    intro j hj
    rw [show 2 * k + 9 * (j + 1) + 2 = 2 * k + 9 * j + 4 + 7 by omega, (block_sizes k j hj).1,
      carry_size k hk1 j (by omega)]
    ring
  have slast : ((ripple k).wireFormulas.getD (carryWire k (k - 1)) (.var 0)).size =
      7 * (k - 1) + 1 := carry_size k hk1 (k - 1) (by omega)
  refine ⟨ripple_size k hk1, ?_, ?_⟩
  · unfold Circuit.depth Circuit.outputDepths
    rw [hout]
    apply le_antisymm
    · apply foldr_max_le
      intro d hd
      simp only [List.map_cons, List.map_append, List.map_map, List.map_nil, List.cons_append,
        List.mem_cons, List.mem_append, List.mem_map, List.mem_range, Function.comp,
        List.not_mem_nil, or_false] at hd
      rcases hd with rfl | ⟨j, hj, rfl⟩ | rfl
      · omega
      · rw [dj j hj]; split_ifs <;> omega
      · omega
    · have hmem : (ripple k).wireDepths.getD (2 * k + 9 * (k - 2 + 1) + 2) 0 ∈
          (((2 * k + 3) :: ((List.range (k - 1)).map fun j => 2 * k + 9 * (j + 1) + 2) ++
            [carryWire k (k - 1)]).map fun o => (ripple k).wireDepths.getD o 0) := by
        simp only [List.map_cons, List.map_append, List.map_map, List.cons_append,
          List.mem_cons, List.mem_append, List.mem_map, List.mem_range, Function.comp]
        exact Or.inr (Or.inl ⟨k - 2, by omega, rfl⟩)
      refine le_trans ?_ (le_foldr_max _ _ hmem)
      rw [dj (k - 2) (by omega)]
      split_ifs <;> omega
  · unfold Circuit.formulaSize Circuit.formulas
    rw [hout]
    simp only [List.map_cons, List.map_append, List.map_map, List.map_nil, List.sum_cons,
      List.sum_append, List.sum_nil, Function.comp_def]
    rw [s0, slast, List.map_congr_left (fun j hj => sj j (List.mem_range.1 hj)),
      sum_range_fourteen]
    obtain ⟨m, rfl⟩ : ∃ m, k = m + 1 := ⟨k - 1, by omega⟩
    simp only [Nat.add_sub_cancel]
    symm
    apply Nat.sub_eq_of_eq_add
    ring

/-! ### The card's worked numbers -/

-- The 2-bit adder: 13 gates, depth 6; output depths s0 = 3, s1 = 6, s2 = 5.
example : (ripple 2).size = 13 ∧ (ripple 2).depth = 6 := by decide
example : (ripple 2).outputDepths = [3, 6, 5] := by decide

-- The trace of 1 + 3: gates g1 … g13 read 1 1 0 0 0 1 1 1 1 1 0 0 1, and s2 s1 s0 = 100 = 4.
example : ((ripple 2).wireValues (inputBits 2 1 3)).drop 4 =
    [true, true, false, false, false, true, true, true, true, true, false, false, true] := by decide
example : (ripple 2).run (inputBits 2 1 3) = [false, false, true] := by decide
example : bitsValue ((ripple 2).run (inputBits 2 1 3)) = 4 := by decide

-- The circuit is right on all 16 inputs.
example : ∀ a : Fin 4, ∀ b : Fin 4,
    bitsValue ((ripple 2).run (inputBits 2 a b)) = a + b := by decide

-- As formulas: s0, s1, s2 cost 4, 14 and 8 gates, 26 in all, at depths 3, 6, 5,
-- within the bounds 7, 63 and 31.
example : (ripple 2).formulas.map Formula.size = [4, 14, 8] := by decide
example : (ripple 2).formulas.map Formula.depth = [3, 6, 5] := by decide
example : (ripple 2).formulaSize = 26 := by decide
example : (ripple 2).formulas.map (fun F => 2 ^ F.depth - 1) = [7, 63, 31] := by decide

-- The table: k = 1 has 4 gates, depth 3, formula 5; k = 4 has 31, 10, 110; k = 8 has 67, 18, 446.
example : (ripple 1).size = 4 ∧ (ripple 1).depth = 3 ∧ (ripple 1).formulaSize = 5 := by decide
example : (ripple 4).size = 31 ∧ (ripple 4).depth = 10 ∧ (ripple 4).formulaSize = 110 := by decide
example : (ripple 8).size = 67 ∧ (ripple 8).depth = 18 ∧ (ripple 8).formulaSize = 446 := by decide

#print axioms unfolding_keeps_depth_and_size_le_two_pow_depth_sub_one
#print axioms ripple_carry_adder_adds
#print axioms ripple_carry_adder_counts

end BooleanCircuits
