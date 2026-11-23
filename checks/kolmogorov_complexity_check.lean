-- Kolmogorov complexity: on a fixed universal machine, the length of the shortest program that prints a string changes by at most a constant between machines, fewer than 2^(n-k) strings of length n have it below n - k, and no program computes it.
import Mathlib.Computability.Partrec
import Mathlib.Data.Set.Card
import Mathlib.Data.Set.Finite.List
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Order.Lattice.Nat
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Tactic.NormNum

namespace KolmogorovComplexity

/-- A machine reads a program `p`, a string of bits, and may halt with an output string.
`x ∈ U p` means "run `p` on `U`; it halts with output `x`". A run that never halts gives no
output. -/
abbrev Machine := List Bool →. List Bool

/-- `U` is a universal machine: it is itself a program (partial computable), and for every
partial computable machine `V` there is a fixed interpreter text `e` such that `U` run on `e`
followed by any program `p` does exactly what `V` does on `p`. -/
def IsUniversal (U : Machine) : Prop :=
  Partrec U ∧ ∀ V : Machine, Partrec V → ∃ e : List Bool, ∀ p : List Bool, U (e ++ p) = V p

/-- The Kolmogorov complexity of `x` on `U`, in bits:
`K_U(x) = min {|p| : U(p) = x}`, the length of the shortest program that makes `U` print `x`
and halt. -/
noncomputable def K (U : Machine) (x : List Bool) : ℕ :=
  sInf {n | ∃ p : List Bool, p.length = n ∧ x ∈ U p}

theorem cnt_eq (m : ℕ) : {p : List Bool | p.length = m}.ncard = 2 ^ m := by
  rw [← _root_.Nat.card_coe_set_eq]
  change Nat.card (List.Vector Bool m) = 2 ^ m
  rw [Nat.card_eq_fintype_card, card_vector, Fintype.card_bool]

#print axioms cnt_eq

theorem cnt_lt (m : ℕ) : {p : List Bool | p.length < m}.ncard + 1 = 2 ^ m := by
  induction m with
  | zero => simp
  | succ m ih =>
    have hs : {p : List Bool | p.length < m + 1} =
        {p : List Bool | p.length < m} ∪ {p : List Bool | p.length = m} := by
      ext p; simp; omega
    rw [hs, Set.ncard_union_eq _ (List.finite_length_lt Bool m) (List.finite_length_eq Bool m),
      cnt_eq, pow_succ]
    · omega
    · rw [Set.disjoint_left]; intro p h1 h2; simp at h1 h2; omega

#print axioms cnt_lt

theorem exists_prog (U : Machine) (hU : IsUniversal U) (x : List Bool) :
    ∃ p : List Bool, x ∈ U p := by
  obtain ⟨e, he⟩ := hU.2 (fun _ => Part.some x) (Partrec.const' _)
  exact ⟨e ++ [], by rw [he]; exact Part.mem_some x⟩

#print axioms exists_prog

theorem K_spec (U : Machine) (hU : IsUniversal U) (x : List Bool) :
    ∃ p : List Bool, p.length = K U x ∧ x ∈ U p := by
  obtain ⟨p, hp⟩ := exists_prog U hU x
  exact Nat.sInf_mem (s := {n | ∃ p : List Bool, p.length = n ∧ x ∈ U p}) ⟨_, p, rfl, hp⟩

#print axioms K_spec

theorem K_le (U : Machine) {x p : List Bool} (h : x ∈ U p) : K U x ≤ p.length :=
  Nat.sInf_le ⟨p, rfl, h⟩

#print axioms K_le

theorem K_le_add (U V : Machine) (hU : IsUniversal U) (hV : IsUniversal V) :
    ∃ c : ℕ, ∀ x, K U x ≤ K V x + c := by
  obtain ⟨e, he⟩ := hU.2 V hV.1
  refine ⟨e.length, fun x => ?_⟩
  obtain ⟨p, hp, hx⟩ := K_spec V hV x
  have := K_le U (x := x) (p := e ++ p) (by rw [he]; exact hx)
  simp at this; omega

#print axioms K_le_add

def fam (n : ℕ) : List Bool := (List.range n).map (fun _ => true)

#print axioms fam

theorem fam_inj : Function.Injective fam := by
  intro a b h
  have := congrArg List.length h
  simpa [fam] using this

#print axioms fam_inj

theorem exists_big (U : Machine) (hU : IsUniversal U) (N : ℕ) : ∃ n, N ≤ K U (fam n) := by
  by_contra hc
  push Not at hc
  have hF : {x : List Bool | ∃ p ∈ {p : List Bool | p.length < N}, x ∈ U p}.Finite := by
    have : {x : List Bool | ∃ p ∈ {p : List Bool | p.length < N}, x ∈ U p} =
        ⋃ p ∈ {p : List Bool | p.length < N}, {x | x ∈ U p} := by ext; simp
    rw [this]
    refine (List.finite_length_lt Bool N).biUnion fun p _ => ?_
    exact Set.Subsingleton.finite fun a ha b hb => Part.mem_unique ha hb
  apply Set.infinite_range_of_injective fam_inj
  refine hF.subset ?_
  rintro _ ⟨n, rfl⟩
  obtain ⟨p, hp, hx⟩ := K_spec U hU (fam n)
  exact ⟨p, by simp only [Set.mem_ofPred_eq]; rw [hp]; exact hc n, hx⟩

#print axioms exists_big

/-- No program computes Kolmogorov complexity: on a universal machine `U`, no program that
always halts returns `K_U(x)` for every string `x`. -/
theorem kolmogorov_complexity_not_computable (U : Machine) (hU : IsUniversal U) :
    ¬ Computable (K U) := by
  intro hK
  let V : Machine := fun p =>
    (Nat.rfind fun n => Part.some (decide (2 * p.length + 1 ≤ K U (fam n)))).map fam
  have hfam : Computable fam :=
    (Primrec.list_map Primrec.list_range (Primrec.const true).to₂).to_comp
  have hV : Partrec V := by
    refine Partrec.map (Partrec.rfind ?_) (hfam.comp Computable.snd).to₂
    refine Computable₂.partrec₂ ?_
    refine Computable₂.comp₂ (Primrec.nat_le.decide.to_comp) ?_ ?_
    · exact (Primrec.succ.comp (Primrec.nat_mul.comp (Primrec.const 2)
        (Primrec.list_length.comp Primrec.fst))).to_comp
    · exact (hK.comp (hfam.comp Computable.snd))
  obtain ⟨e, he⟩ := hU.2 V hV
  obtain ⟨n0, hn0⟩ := exists_big U hU (2 * e.length + 1)
  let p := List.replicate e.length false
  have hdom : (Nat.rfind fun n => Part.some (decide (2 * p.length + 1 ≤ K U (fam n)))).Dom := by
    refine Nat.rfind_dom'.2 ⟨n0, ?_, fun _ => trivial⟩
    simpa [p] using hn0
  have hmem := Part.get_mem hdom
  have hspec := Nat.rfind_spec hmem
  simp only [Part.mem_some_iff] at hspec
  have hx : fam (Part.get _ hdom) ∈ U (e ++ p) := by
    rw [he]; exact Part.mem_map fam hmem
  have := K_le U hx
  simp [p] at this hspec
  omega

/-- The invariance theorem: for two universal machines `U` and `V` there is a constant `c`,
the cost of switching machines, with `|K_U(x) - K_V(x)| ≤ c` for every string `x`. -/
theorem kolmogorov_complexity_invariance (U V : Machine) (hU : IsUniversal U)
    (hV : IsUniversal V) :
    ∃ c : ℕ, ∀ x : List Bool, |(K U x : ℤ) - (K V x : ℤ)| ≤ c := by
  obtain ⟨c1, h1⟩ := K_le_add U V hU hV
  obtain ⟨c2, h2⟩ := K_le_add V U hV hU
  refine ⟨c1 + c2, fun x => ?_⟩
  have a := h1 x; have b := h2 x
  rw [abs_le]; constructor <;> push_cast <;> omega

/-- The counting bound: out of the `2^n` strings of length `n`, fewer than `2^(n-k)` have
`K_U(x) < n - k`, because there are only `2^(n-k) - 1` programs shorter than `n - k` bits and
each prints at most one string. -/
theorem few_strings_are_compressible (U : Machine) (hU : IsUniversal U) (n k : ℕ) :
    {x : List Bool | x.length = n ∧ K U x < n - k}.ncard < 2 ^ (n - k) := by
  choose g hg1 hg2 using K_spec U hU
  have hle := Set.ncard_le_ncard_of_injOn (s := {x : List Bool | x.length = n ∧ K U x < n - k}) (t := {p : List Bool | p.length < n - k}) g
    (fun x hx => by simp only [Set.mem_ofPred_eq] at hx ⊢; rw [hg1]; exact hx.2)
    (fun x _ y _ hxy => Part.mem_unique (hg2 x) (hxy ▸ hg2 y))
    (List.finite_length_lt Bool _)
  have := cnt_lt (n - k)
  omega

/-! The card's own whole-number worked examples. -/

-- Programs shorter than n - k bits: 1 + 2 + 4 + ... + 2^(n-k-1) = 2^(n-k) - 1.
-- For n = 16, k = 4 that is 4,095 programs, out of 65,536 strings of 16 bits.
example : (Finset.range 12).sum (fun i => 2 ^ i) = 2 ^ 12 - 1 ∧ 2 ^ 12 - 1 = 4095 ∧
    2 ^ 16 = 65536 := by
  decide

-- The run-length code describes 1,150 of the 16-bit strings in fewer than 16 bits and 28 in
-- fewer than 12; the counting bound allows up to 2^16 - 1 and 2^12 - 1.
example : 1150 ≤ 2 ^ 16 - 1 ∧ 28 ≤ 2 ^ 12 - 1 := by norm_num

-- A million flips with k = 20: fewer than one sequence in 2^20 = 1,048,576 has a program
-- shorter than 1,000,000 - 20 = 999,980 bits.
example : (2 : ℕ) ^ 20 = 1048576 ∧ 1000000 - 20 = 999980 := by norm_num
example : (2 : ℕ) ^ 999980 * 2 ^ 20 = 2 ^ 1000000 := by rw [← pow_add]

-- The named pi program: the 429-byte function plus the call line `print(pi_digits(1000000))`
-- and a newline (26 bytes) is 3,640 bits; with `print(pi_digits(10))` (21 bytes) it is 3,600.
example : (429 + 26) * 8 = 3640 ∧ (429 + 21) * 8 = 3600 := by norm_num

-- Packed digits: 10 decimal digits need 34 bits (2^33 < 10^10 ≤ 2^34), and 1,000 digits need
-- 3,322 bits (2^3321 < 10^1000 ≤ 2^3322).
example : (2 : ℕ) ^ 33 < 10 ^ 10 ∧ (10 : ℕ) ^ 10 ≤ 2 ^ 34 := by norm_num
set_option exponentiation.threshold 4000 in
example : (2 : ℕ) ^ 3321 < 10 ^ 1000 ∧ (10 : ℕ) ^ 1000 ≤ 2 ^ 3322 := by norm_num

-- `0011` repeated 250,000 times: the run-length code spends 1 bit, then 3 bits on each of its
-- 500,000 runs of two, 1,500,001 bits; `print('0011' * 250000)` with a newline is 23 bytes,
-- 184 bits. The 214-byte flip generator is 1,712 bits.
example : 1 + 3 * 500000 = 1500001 ∧ 23 * 8 = 184 ∧ 214 * 8 = 1712 := by norm_num

-- The Berry search with L = 20 prints `00001100110011`: runs 4, 2, 2, 2, 2, 2, coded as
-- 1 bit, then 5 bits for the run of 4 and 3 bits for each run of 2, 21 bits, just above 20.
example : 1 + 5 + 5 * 3 = 21 ∧ 20 < 21 ∧ 4 + 5 * 2 = 14 := by norm_num

#print axioms kolmogorov_complexity_not_computable
#print axioms kolmogorov_complexity_invariance
#print axioms few_strings_are_compressible

end KolmogorovComplexity
