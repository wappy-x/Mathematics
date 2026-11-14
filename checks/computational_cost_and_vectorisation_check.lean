-- Cost in practice: running a list of per-path instructions path by path or as arrays in chunks of b gives the same results and the same k n element operations, while the interpreter steps fall from k n to k times ⌈n/b⌉; and 552,859,891,708,071,949 of the 2^64 sequences of 64 coins have at least 40 heads.
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Nat.Choose.Sum
import Mathlib.Algebra.Order.Floor.Semiring
import Mathlib.Data.Rat.Floor
import Mathlib.Tactic.NormNum

open Finset

/-! The card's model of a run. One path's state `σ` is its own registers (for the card's
script, the numbers `z` and `t`). One path's work is a list `prog` of `k` instructions, each a
function of that path's own state only: no instruction reads another path, which is the card's
condition that the paths are independent. The `n` paths start from the list `xs`.

Every run below returns three things: the final value of every path, the interpreter steps
(instructions read and launched) and the element operations (work on one number). -/

/-- One path through the loop: each instruction is launched on its own, so it costs one
interpreter step and one element operation. -/
def loopPath {σ : Type*} (prog : List (σ → σ)) (z : σ) : σ × ℕ × ℕ :=
  prog.foldl (fun s f => (f s.1, s.2.1 + 1, s.2.2 + 1)) (z, 0, 0)

/-- The loop, path by path: for each path, for each instruction. -/
def runLoop {σ : Type*} (prog : List (σ → σ)) : List σ → List σ × ℕ × ℕ
  | [] => ([], 0, 0)
  | x :: xs =>
    let r := loopPath prog x
    let rest := runLoop prog xs
    (r.1 :: rest.1, r.2.1 + rest.2.1, r.2.2 + rest.2.2)

/-- One chunk as array work: each instruction is launched once for the whole array (one
interpreter step) and does one element operation per number in the array. -/
def arrayChunk {σ : Type*} (prog : List (σ → σ)) (zs : List σ) : List σ × ℕ × ℕ :=
  prog.foldl (fun s f => (s.1.map f, s.2.1 + 1, s.2.2 + s.1.length)) (zs, 0, 0)

/-- Array work in chunks of `b` paths: take the next `b` paths (or all that are left), run
every instruction across that chunk, then go on to the rest. (A chunk size of 0 makes no
sense and runs nothing.) -/
def runArrays {σ : Type*} (prog : List (σ → σ)) (b : ℕ) (xs : List σ) : List σ × ℕ × ℕ :=
  if _h : xs = [] ∨ b = 0 then ([], 0, 0) else
    let r := arrayChunk prog (xs.take b)
    let rest := runArrays prog b (xs.drop b)
    (r.1 ++ rest.1, r.2.1 + rest.2.1, r.2.2 + rest.2.2)
termination_by xs.length
decreasing_by
  simp only [not_or] at _h
  have := List.length_pos_of_ne_nil _h.1
  simp only [List.length_drop]
  omega

theorem loopPath_fold_aux {σ : Type*} (prog : List (σ → σ)) (z : σ) (a c : ℕ) :
    prog.foldl (fun s f => (f s.1, s.2.1 + 1, s.2.2 + 1)) (z, a, c) =
      (prog.foldl (fun x f => f x) z, a + prog.length, c + prog.length) := by
  induction prog generalizing z a c with
  | nil => simp
  | cons f fs ih => simp only [List.foldl_cons, ih, List.length_cons]; ext <;> simp <;> omega

theorem loopPath_eq {σ : Type*} (prog : List (σ → σ)) (z : σ) :
    loopPath prog z = (prog.foldl (fun x f => f x) z, prog.length, prog.length) := by
  simp [loopPath, loopPath_fold_aux]

theorem arrayChunk_fold_aux {σ : Type*} (prog : List (σ → σ)) (zs : List σ) (a c : ℕ) :
    prog.foldl (fun s f => (s.1.map f, s.2.1 + 1, s.2.2 + s.1.length)) (zs, a, c) =
      (zs.map (fun x => prog.foldl (fun x f => f x) x), a + prog.length,
        c + prog.length * zs.length) := by
  induction prog generalizing zs a c with
  | nil => simp
  | cons f fs ih =>
    simp only [List.foldl_cons, ih, List.length_cons, List.length_map, List.map_map]
    ext
    · simp [Function.comp_def]
    · simp; omega
    · simp; ring

theorem arrayChunk_eq {σ : Type*} (prog : List (σ → σ)) (zs : List σ) :
    arrayChunk prog zs = (zs.map (fun x => prog.foldl (fun x f => f x) x), prog.length,
      prog.length * zs.length) := by
  simp [arrayChunk, arrayChunk_fold_aux]

theorem runLoop_eq {σ : Type*} (prog : List (σ → σ)) (xs : List σ) :
    runLoop prog xs = (xs.map (fun x => prog.foldl (fun x f => f x) x),
      prog.length * xs.length, prog.length * xs.length) := by
  induction xs with
  | nil => simp [runLoop]
  | cons x xs ih =>
    simp only [runLoop, ih, loopPath_eq, List.map_cons, List.length_cons]
    ext <;> simp <;> ring

theorem ceil_chunks_step (n b : ℕ) (hb : 0 < b) (hn : 0 < n) :
    ⌈(n : ℚ) / b⌉₊ = 1 + ⌈((n - min b n : ℕ) : ℚ) / b⌉₊ := by
  have hbq : (0 : ℚ) < b := by exact_mod_cast hb
  rcases le_total b n with h | h
  · rw [min_eq_left h, Nat.cast_sub h]
    have : (n : ℚ) / b = ((n : ℚ) - b) / b + 1 := by field_simp; ring
    rw [this, Nat.ceil_add_one]
    · ring
    · apply div_nonneg _ hbq.le
      have : (b : ℚ) ≤ n := by exact_mod_cast h
      linarith
  · rw [min_eq_right h, Nat.sub_self]
    simp only [Nat.cast_zero, zero_div, Nat.ceil_zero, add_zero]
    rw [Nat.ceil_eq_iff one_ne_zero]
    constructor
    · simp only [Nat.sub_self, Nat.cast_zero]
      apply div_pos _ hbq; exact_mod_cast hn
    · rw [div_le_iff₀ hbq]; simp; exact_mod_cast h

theorem runArrays_eq {σ : Type*} (prog : List (σ → σ)) (b : ℕ) (hb : 0 < b) (xs : List σ) :
    runArrays prog b xs = (xs.map (fun x => prog.foldl (fun x f => f x) x),
      prog.length * ⌈(xs.length : ℚ) / b⌉₊, prog.length * xs.length) := by
  induction h : xs.length using Nat.strong_induction_on generalizing xs with
  | _ n ih =>
    rw [runArrays]
    by_cases hx : xs = []
    · subst hx; simp at h; subst h; simp
    · have hcond : ¬ (xs = [] ∨ b = 0) := by
        simp only [not_or]; exact ⟨hx, by omega⟩
      rw [dite_eq_right_of_eq_false (eq_false hcond)]
      have hlen : 0 < xs.length := List.length_pos_of_ne_nil hx
      have hd : (xs.drop b).length < n := by simp; omega
      rw [ih _ hd (xs.drop b) rfl, arrayChunk_eq]
      simp only [List.length_take, List.length_drop]
      ext
      · simp [List.take_append_drop]
      · simp only
        rw [← h, ceil_chunks_step xs.length b hb hlen]
        have : xs.length - min b xs.length = xs.length - b := by omega
        rw [this]; ring
      · simp only
        rw [← h]
        have : min b xs.length + (xs.length - b) = xs.length := by omega
        rw [← mul_add, this]

theorem card_bool_functions_with_j_true (n j : ℕ) :
    (univ.filter (fun s : Fin n → Bool => (univ.filter (fun i => s i = true)).card = j)).card =
      Nat.choose n j := by
  have hc : (powersetCard j (univ : Finset (Fin n))).card = Nat.choose n j := by simp
  rw [← hc]
  refine card_bij (fun s _ => univ.filter (fun i => s i = true)) ?_ ?_ ?_
  · intro s hs
    simp only [mem_filter, mem_univ, true_and] at hs
    simp [mem_powersetCard, hs]
  · intro s _ s' _ h
    funext i
    have := congrArg (fun t => i ∈ t) h
    simp only [mem_filter, mem_univ, true_and, eq_iff_iff] at this
    cases hs : s i <;> cases hs' : s' i <;> simp_all
  · intro t ht
    rw [mem_powersetCard] at ht
    refine ⟨fun i => decide (i ∈ t), ?_, ?_⟩
    · simp only [mem_filter, mem_univ, true_and, decide_eq_true_eq]
      rw [filter_mem_eq_inter, univ_inter, ht.2]
    · simp

theorem sum_choose_64_from_40 :
    ∑ j ∈ Icc 40 64, Nat.choose 64 j = 552859891708071949 := by
  decide

theorem card_at_least_m_true (n m : ℕ) :
    (univ.filter (fun s : Fin n → Bool =>
        m ≤ (univ.filter (fun i => s i = true)).card)).card =
      ∑ j ∈ Icc m n, Nat.choose n j := by
  rw [card_eq_sum_card_fiberwise (f := fun s : Fin n → Bool =>
    (univ.filter (fun i => s i = true)).card) (t := Icc m n)]
  · refine sum_congr rfl fun j hj => ?_
    rw [← card_bool_functions_with_j_true n j, filter_filter]
    simp only [mem_Icc] at hj
    exact congrArg card (filter_congr fun s _ => ⟨fun h => h.2, fun h => ⟨h ▸ hj.1, h⟩⟩)
  · intro s hs
    simp only [coe_filter, mem_univ, true_and, Set.mem_ofPred_eq] at hs
    simp only [coe_Icc, Set.mem_Icc]
    refine ⟨hs, ?_⟩
    calc _ ≤ (univ : Finset (Fin n)).card := card_le_univ _
      _ = n := by simp

/-- The card's main claim. Run the same `k` instructions on `n` independent paths, first as a
loop, path by path, and then as array work, `b` paths at a time with `b ≥ 1`. Both find the same
value for every path; both do exactly `E = k n` element operations, so arrays do not reduce the
arithmetic; but the loop launches `D = k n` interpreter steps and the arrays only
`D = k ⌈n / b⌉`. -/
theorem vectorising_keeps_arithmetic_and_cuts_launches {σ : Type*} (prog : List (σ → σ))
    (xs : List σ) (b : ℕ) (hb : 0 < b) :
    (runArrays prog b xs).1 = (runLoop prog xs).1 ∧
    (runLoop prog xs).2.2 = prog.length * xs.length ∧
    (runArrays prog b xs).2.2 = prog.length * xs.length ∧
    (runLoop prog xs).2.1 = prog.length * xs.length ∧
    (runArrays prog b xs).2.1 = prog.length * ⌈(xs.length : ℚ) / b⌉₊ := by
  simp [runArrays_eq prog b hb, runLoop_eq]

/-- A loop is just arrays of length one: array work in chunks of `b = 1` path gives the same
values, the same interpreter steps and the same element operations as the loop. -/
theorem loop_is_arrays_of_length_one {σ : Type*} (prog : List (σ → σ)) (xs : List σ) :
    runArrays prog 1 xs = runLoop prog xs := by
  rw [runArrays_eq prog 1 one_pos, runLoop_eq]
  simp

/-- The exact answer behind the simulation: of the `2^64` equally likely head-and-tail
sequences of 64 fair coins, the number with at least 40 heads is the sum of entries 40 to 64 of
row 64 of Pascal's triangle, which is 552,859,891,708,071,949. -/
theorem sequences_with_at_least_40_heads :
    (univ.filter (fun s : Fin 64 → Bool =>
        40 ≤ (univ.filter (fun i => s i = true)).card)).card =
      ∑ j ∈ Icc 40 64, Nat.choose 64 j ∧
    ∑ j ∈ Icc 40 64, Nat.choose 64 j = 552859891708071949 := by
  exact ⟨card_at_least_m_true 64 40, sum_choose_64_from_40⟩

/-! The card's whole-number worked examples. -/

-- Element operations per path: 15 instructions + 1 add to the total = 16.
example : 15 + 1 = 16 := by norm_num
-- Element operations for the whole run, and the loop's interpreter steps: 16 × 1,000,000.
example : 16 * 1000000 = 16000000 := by norm_num
-- Interpreter steps for one array chunk of all 1,000,000 paths: 16 × ⌈1,000,000 / 1,000,000⌉ = 16.
example : 16 * ⌈(1000000 : ℚ) / 1000000⌉₊ = 16 := by norm_num
-- Chunks of 100: ⌈1,000,000 / 100⌉ = 10,000 chunks, 16 × 10,000 = 160,000 steps.
example : ⌈(1000000 : ℚ) / 100⌉₊ = 10000 := by norm_num
example : 16 * ⌈(1000000 : ℚ) / 100⌉₊ = 160000 := by norm_num
-- Chunks of 10,000: 16 × 100 = 1,600 steps.
example : 16 * ⌈(1000000 : ℚ) / 10000⌉₊ = 1600 := by norm_num
-- Steps saved, loop ÷ one chunk: 16,000,000 ÷ 16 = 1,000,000.
example : 16000000 / 16 = 1000000 := by norm_num
-- Doubling test: 1,000 paths take 16,000 loop steps, 2,000 take 32,000; one array chunk takes 16 each time.
example : 16 * 1000 = 16000 ∧ 16 * 2000 = 32000 := by norm_num
example : 16 * ⌈(1000 : ℚ) / 1000⌉₊ = 16 ∧ 16 * ⌈(2000 : ℚ) / 2000⌉₊ = 16 := by norm_num
-- Where numbers wrap at 64 bits, 13 operations per path: 13 × 1,000,000 = 13,000,000.
example : 13 * 1000000 = 13000000 := by norm_num
-- The number of 64-coin sequences.
example : 2 ^ 64 = 18446744073709551616 := by norm_num
-- Adding entries 40 to 64 of row 64 of Pascal's triangle.
example : ∑ j ∈ Icc 40 64, Nat.choose 64 j = 552859891708071949 := by decide

#print axioms vectorising_keeps_arithmetic_and_cuts_launches
#print axioms loop_is_arrays_of_length_one
#print axioms sequences_with_at_least_40_heads
#print axioms loopPath_fold_aux
#print axioms loopPath_eq
#print axioms arrayChunk_fold_aux
#print axioms arrayChunk_eq
#print axioms runLoop_eq
#print axioms ceil_chunks_step
#print axioms runArrays_eq
#print axioms card_bool_functions_with_j_true
#print axioms sum_choose_64_from_40
#print axioms card_at_least_m_true
