-- De Bruijn sequences: for any alphabet of n digits and any code length k there is a ring of n^k digits that reads every k-digit code exactly once, no ring holding every code is shorter, and a flat string of n^k + k - 1 presses also holds every code.
import Mathlib.Algebra.Order.Group.Nat
import Mathlib.Algebra.Ring.Nat
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Fintype.Card
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Data.Fin.VecNotation
import Mathlib.Algebra.Group.Basic
import Mathlib.Algebra.Ring.Periodic
import Mathlib.Tactic.NormNum
import Mathlib.GroupTheory.Perm.Cycle.Basic
import Mathlib.Logic.Equiv.Fin.Rotate
import Mathlib.GroupTheory.OrderOfElement

open Finset

section DeBruijnHelpers

open Equiv Equiv.Perm

theorem db_merge {α : Type*} [Fintype α] [DecidableEq α] (σ : Perm α) (x y z : α)
    (hxy : ¬ σ.SameCycle x y) (hz : σ.SameCycle x z) :
    (σ * swap x y).SameCycle y z := by
  have hex : ∃ m : ℕ, (σ ^ m) (σ x) = x := by
    refine ⟨orderOf σ - 1, ?_⟩
    have h1 := orderOf_pos σ
    have : (σ ^ (orderOf σ - 1)) (σ x) = (σ ^ orderOf σ) x := by
      rw [← Perm.mul_apply, ← pow_succ]
      congr 2
      omega
    rw [this, pow_orderOf_eq_one]
    rfl
  classical
  obtain ⟨m, hmx, hmin⟩ : ∃ m : ℕ, (σ ^ m) (σ x) = x ∧ ∀ j < m, (σ ^ j) (σ x) ≠ x :=
    ⟨Nat.find hex, Nat.find_spec hex, fun j hj => Nat.find_min hex hj⟩
  have step : ∀ j ≤ m, ((σ * swap x y) ^ (j + 1)) y = (σ ^ j) (σ x) := by
    intro j
    induction j with
    | zero => intro _; simp [Perm.mul_apply, swap_apply_right]
    | succ j ih =>
      intro hj
      rw [pow_succ', Perm.mul_apply, ih (by omega), Perm.mul_apply]
      have hne1 : (σ ^ j) (σ x) ≠ x := hmin j (by omega)
      have hne2 : (σ ^ j) (σ x) ≠ y := by
        intro h
        apply hxy
        rw [← h, sameCycle_pow_right, sameCycle_apply_right]
      rw [swap_apply_of_ne_of_ne hne1 hne2, ← Perm.mul_apply, ← pow_succ']
  have hper : (σ ^ (m + 1)) x = x := by
    rw [pow_succ, Perm.mul_apply, hmx]
  obtain ⟨i, rfl⟩ := hz.exists_nat_pow_eq
  have hred : (σ ^ i) x = (σ ^ (i % (m + 1))) x := by
    conv_lhs => rw [← Nat.mod_add_div i (m + 1), pow_add, pow_mul, Perm.mul_apply,
      pow_apply_eq_self_of_apply_eq_self hper]
  rw [hred]
  have key : ∃ t : ℕ, ((σ * swap x y) ^ t) y = (σ ^ (i % (m + 1))) x := by
    rcases h : i % (m + 1) with _ | r
    · exact ⟨m + 1, by rw [step m le_rfl, hmx]; simp⟩
    · have : r < m := by have := Nat.mod_lt i (show 0 < m + 1 by omega); rw [h] at this; omega
      exact ⟨r + 1, by rw [step r this.le, pow_succ, Perm.mul_apply]⟩
  obtain ⟨t, ht⟩ := key
  rw [← ht, sameCycle_pow_right]


theorem db_pair (n k : ℕ) (σ : Perm (Fin (k + 1) → Fin n))
    (hP : ∀ w (j : Fin k), σ w j.castSucc = w j.succ) (w0 : Fin (k + 1) → Fin n)
    (hnot : ¬ ∀ z, σ.SameCycle w0 z) :
    ∃ x y : Fin (k + 1) → Fin n, (∀ j : Fin k, x j.succ = y j.succ) ∧
      σ.SameCycle w0 x ∧ ¬ σ.SameCycle w0 y := by
  by_contra H
  push Not at H
  apply hnot
  have hstep : ∀ z z' : Fin (k + 1) → Fin n, σ.SameCycle w0 z →
      (∀ j : Fin k, z' j.castSucc = z j.succ) → σ.SameCycle w0 z' := by
    intro z z' hz hz'
    have hu : σ (σ.symm z') = z' := σ.apply_symm_apply z'
    have htail : ∀ j : Fin k, z j.succ = (σ.symm z') j.succ := by
      intro j
      rw [← hz' j, ← hP (σ.symm z') j, hu]
    have := H z (σ.symm z') htail hz
    rw [← hu, sameCycle_apply_right]
    exact this
  have hind : ∀ m ≤ k + 1, ∀ v : Fin (k + 1) → Fin n, ∃ z, σ.SameCycle w0 z ∧
      ∀ i j : Fin (k + 1), (i : ℕ) < m → (j : ℕ) + m = i + (k + 1) → z j = v i := by
    intro m
    induction m with
    | zero => intro _ v; exact ⟨w0, SameCycle.refl _ _, fun i j hi _ => by omega⟩
    | succ m ih =>
      intro hm v
      obtain ⟨z, hz, hzv⟩ := ih (by omega) v
      let z' : Fin (k + 1) → Fin n := fun j =>
        if h : (j : ℕ) < k then z ⟨j + 1, by omega⟩ else v ⟨m, by omega⟩
      refine ⟨z', hstep z z' hz ?_, ?_⟩
      · intro j
        simp only [z', Fin.val_castSucc, j.isLt, dite_true]
        rfl
      · intro i j hi hij
        simp only [z']
        split_ifs with h
        · exact hzv i ⟨j + 1, by omega⟩ (by omega) (by change (j : ℕ) + 1 + m = (i : ℕ) + (k + 1); omega)
        · congr 1
          ext
          simp
          omega
  intro v
  obtain ⟨z, hz, hzv⟩ := hind (k + 1) le_rfl v
  have : z = v := by
    funext j
    exact hzv j j j.isLt rfl
  exact this ▸ hz

theorem db_exists_cycle (n k : ℕ) (w0 : Fin (k + 1) → Fin n) :
    ∃ σ : Perm (Fin (k + 1) → Fin n), (∀ w (j : Fin k), σ w j.castSucc = w j.succ) ∧
      ∀ z, σ.SameCycle w0 z := by
  classical
  have main : ∀ d : ℕ, ∀ σ : Perm (Fin (k + 1) → Fin n),
      (∀ w (j : Fin k), σ w j.castSucc = w j.succ) →
      Fintype.card (Fin (k + 1) → Fin n) - (univ.filter (fun z => σ.SameCycle w0 z)).card = d →
      ∃ σ : Perm (Fin (k + 1) → Fin n), (∀ w (j : Fin k), σ w j.castSucc = w j.succ) ∧
        ∀ z, σ.SameCycle w0 z := by
    intro d
    induction d using Nat.strong_induction_on with
    | _ d ih =>
      intro σ hP hd
      by_cases hall : ∀ z, σ.SameCycle w0 z
      · exact ⟨σ, hP, hall⟩
      obtain ⟨x, y, hxy, hx, hy⟩ := db_pair n k σ hP w0 hall
      have hP' : ∀ w (j : Fin k), (σ * swap x y) w j.castSucc = w j.succ := by
        intro w j
        rw [Perm.mul_apply, hP, swap_apply_def]
        split_ifs with h1 h2
        · rw [h1, hxy]
        · rw [h2, hxy]
        · rfl
      have hxy' : ¬ σ.SameCycle x y := fun h => hy (hx.trans h)
      have hsub : univ.filter (fun z => σ.SameCycle w0 z) ⊂
          univ.filter (fun z => (σ * swap x y).SameCycle w0 z) := by
        have hw0 : (σ * swap x y).SameCycle y w0 := db_merge σ x y w0 hxy' hx.symm
        rw [Finset.ssubset_iff_of_subset]
        · refine ⟨y, by simp [hw0.symm], by simp [hy]⟩
        · intro z hz
          simp only [mem_filter, mem_univ, true_and] at hz ⊢
          exact hw0.symm.trans (db_merge σ x y z hxy' (hx.symm.trans hz))
      have hlt := Finset.card_lt_card hsub
      have hle := Finset.card_le_univ (univ.filter (fun z => (σ * swap x y).SameCycle w0 z))
      exact ih _ (by omega) (σ * swap x y) hP' rfl
  let ρ : Perm (Fin (k + 1) → Fin n) := (finRotate (k + 1)).symm.arrowCongr (Equiv.refl (Fin n))
  have hρ : ∀ w (j : Fin k), ρ w j.castSucc = w j.succ := by
    intro w j
    have h1 : finRotate (k + 1) j.castSucc = j.succ := by
      ext; rw [coe_finRotate_of_ne_last (Fin.castSucc_lt_last j).ne]; simp
    simp [ρ, Equiv.arrowCongr_apply, h1]
  exact main _ ρ hρ rfl

end DeBruijnHelpers

#print axioms db_merge
#print axioms db_pair
#print axioms db_exists_cycle

/-- De Bruijn's ring: for every number of digits `n` and every code length `k`, there is a
ring of `n ^ k` digits (a string `s` read round and round, so `s (i + n ^ k) = s i`) in which
the `k`-digit windows starting at the `n ^ k` positions are exactly the `n ^ k` possible codes,
each read once. The only condition is that there is at least one digit (with no digits and
`k = 0` a ring of length 1 cannot be written). -/
theorem de_bruijn_ring_exists (n k : ℕ) (hn : 0 < n) :
    ∃ s : ℕ → Fin n, Function.Periodic s (n ^ k) ∧
      Function.Bijective (fun i : Fin (n ^ k) => fun j : Fin k => s (i + j)) := by
  rcases k with _ | k
  · refine ⟨fun _ => ⟨0, hn⟩, fun _ => rfl, ?_, ?_⟩
    · intro a b _
      have ha := a.isLt; have hb := b.isLt
      simp only [pow_zero] at ha hb
      ext; omega
    · intro w
      exact ⟨⟨0, by simp⟩, funext fun j => j.elim0⟩
  set w0 : Fin (k + 1) → Fin n := fun _ => ⟨0, hn⟩
  obtain ⟨σ, hP, hall⟩ := db_exists_cycle n k w0
  have hcard : Fintype.card (Fin (k + 1) → Fin n) = n ^ (k + 1) := by simp
  have hex : ∃ m : ℕ, 0 < m ∧ (σ ^ m) w0 = w0 :=
    ⟨orderOf σ, orderOf_pos σ, by rw [pow_orderOf_eq_one]; rfl⟩
  classical
  obtain ⟨p, ⟨hp0, hpw⟩, hmin⟩ : ∃ p : ℕ, (0 < p ∧ (σ ^ p) w0 = w0) ∧
      ∀ j < p, ¬ (0 < j ∧ (σ ^ j) w0 = w0) :=
    ⟨Nat.find hex, Nat.find_spec hex, fun j hj => Nat.find_min hex hj⟩
  have hsurj : ∀ z, ∃ i < p, (σ ^ i) w0 = z := by
    intro z
    obtain ⟨i, rfl⟩ := (hall z).exists_nat_pow_eq
    refine ⟨i % p, Nat.mod_lt _ hp0, ?_⟩
    conv_rhs => rw [← Nat.mod_add_div i p, pow_add, pow_mul, Equiv.Perm.mul_apply,
      Equiv.Perm.pow_apply_eq_self_of_apply_eq_self hpw]
  have hinj : ∀ a b : ℕ, a < p → b < p → (σ ^ a) w0 = (σ ^ b) w0 → a = b := by
    have key : ∀ a b : ℕ, a < b → b < p → (σ ^ a) w0 = (σ ^ b) w0 → False := by
      intro a b hab hb h
      have h2 : (σ ^ b) w0 = (σ ^ a) ((σ ^ (b - a)) w0) := by
        rw [← Equiv.Perm.mul_apply, ← pow_add]; congr 2; omega
      rw [h2] at h
      exact hmin (b - a) (by omega) ⟨by omega, ((σ ^ a).injective h).symm⟩
    intro a b ha hb h
    rcases lt_trichotomy a b with hab | hab | hab
    · exact (key a b hab hb h).elim
    · exact hab
    · exact (key b a hab ha h.symm).elim
  have hbij : Function.Bijective (fun i : Fin p => (σ ^ (i : ℕ)) w0) :=
    ⟨fun a b h => Fin.ext (hinj a b a.isLt b.isLt h),
     fun z => by obtain ⟨i, hi, h⟩ := hsurj z; exact ⟨⟨i, hi⟩, h⟩⟩
  have hpN : p = n ^ (k + 1) := by
    have := Fintype.card_of_bijective hbij
    simpa [hcard] using this
  subst hpN
  have hwin : ∀ j : ℕ, ∀ u : Fin (k + 1) → Fin n, ∀ h : j < k + 1, (σ ^ j) u 0 = u ⟨j, h⟩ := by
    intro j
    induction j with
    | zero => intro u h; rfl
    | succ j ih =>
      intro u h
      rw [pow_succ, Equiv.Perm.mul_apply, ih (σ u) (by omega)]
      have := hP u ⟨j, by omega⟩
      simpa using this
  refine ⟨fun i => (σ ^ i) w0 0, ?_, ?_⟩
  · intro i
    simp only
    rw [pow_add, Equiv.Perm.mul_apply, hpw]
  · have heq : (fun i : Fin (n ^ (k + 1)) => fun j : Fin (k + 1) => (σ ^ ((i : ℕ) + (j : ℕ))) w0 0)
        = fun i : Fin (n ^ (k + 1)) => (σ ^ (i : ℕ)) w0 := by
      funext i j
      rw [show (i : ℕ) + (j : ℕ) = j + i from Nat.add_comm _ _, pow_add, Equiv.Perm.mul_apply, hwin j _ j.isLt]
    simp only
    rw [heq]
    exact hbij

/-- Nothing shorter works: if a ring of length `L` (a string with `s (i + L) = s i`) shows
every `k`-digit code in a window starting at one of its `L` positions, then `L ≥ n ^ k`,
because each position starts only one code. -/
theorem de_bruijn_ring_length_ge (n k L : ℕ) (s : ℕ → Fin n) (hs : Function.Periodic s L)
    (hall : ∀ w : Fin k → Fin n, ∃ i < L, (fun j : Fin k => s (i + j)) = w) :
    n ^ k ≤ L := by
  have := Fintype.card_le_of_surjective (fun i : Fin L => fun j : Fin k => s (i + j))
    (fun w => by obtain ⟨i, hi, h⟩ := hall w; exact ⟨⟨i, hi⟩, h⟩)
  simpa using this

/-- Typed flat on a keypad: a straight string of `n ^ k + k - 1` presses contains every
`k`-digit code as `k` consecutive presses (the ring with its first `k - 1` digits repeated
at the end). -/
theorem de_bruijn_flat_presses (n k : ℕ) (hn : 0 < n) :
    ∃ t : List (Fin n), t.length = n ^ k + k - 1 ∧
      ∀ w : Fin k → Fin n, ∃ i, i + k ≤ t.length ∧ ∀ j : Fin k, t[i + (j : ℕ)]? = some (w j) := by
  obtain ⟨s, -, hbij⟩ := de_bruijn_ring_exists n k hn
  have hpos : 0 < n ^ k := pow_pos hn k
  refine ⟨List.ofFn (fun i : Fin (n ^ k + k - 1) => s i), by simp, ?_⟩
  intro w
  obtain ⟨i, hi⟩ := hbij.2 w
  refine ⟨i, by simp; omega, ?_⟩
  intro j
  have hlt : (i : ℕ) + j < n ^ k + k - 1 := by have := i.isLt; have := j.isLt; omega
  rw [List.getElem?_ofFn]
  simp [hlt, ← hi]

-- The card's ring 00010111 (n = 2, k = 3), read round and round.
def ring00010111 (m : ℕ) : Fin 2 := (![0, 0, 0, 1, 0, 1, 1, 1] : Fin 8 → Fin 2) ⟨m % 8, Nat.mod_lt _ (by norm_num)⟩
-- It repeats every 8 digits, and its 8 windows are the 8 codes, once each.
example : Function.Periodic ring00010111 (2 ^ 3) := fun m => by simp [ring00010111]
example : Function.Bijective (fun i : Fin (2 ^ 3) => fun j : Fin 3 => ring00010111 (i + j)) := by
  decide
-- Typed flat with no wrap, the first 8 digits show only 6 of the 8 codes, missing 100 and 110.
example : ((univ : Finset (Fin 6)).image (fun i : Fin 6 => fun j : Fin 3 =>
    ring00010111 (i + j))).card = 6 := by
  decide
example : ![1, 0, 0] ∉ (univ : Finset (Fin 6)).image (fun i : Fin 6 => fun j : Fin 3 =>
    ring00010111 (i + j)) ∧ ![1, 1, 0] ∉ (univ : Finset (Fin 6)).image
      (fun i : Fin 6 => fun j : Fin 3 => ring00010111 (i + j)) := by
  decide
-- Typed flat as 0001011100: 10 = 2^3 + 3 - 1 presses, and every 3-digit code is three
-- consecutive presses somewhere in it.
example : ([0, 0, 0, 1, 0, 1, 1, 1, 0, 0] : List (Fin 2)).length = 2 ^ 3 + 3 - 1 ∧
    ∀ w : Fin 3 → Fin 2, ∃ i : Fin 8, (i : ℕ) + 3 ≤ 10 ∧ ∀ j : Fin 3,
      ([0, 0, 0, 1, 0, 1, 1, 1, 0, 0] : List (Fin 2))[(i : ℕ) + (j : ℕ)]? = some (w j) := by
  decide
-- Brute force: of the 256 eight-digit binary strings, 16 hold every 3-digit code round the ring.
example : ((univ : Finset (Fin 8 → Fin 2)).filter (fun s =>
    Function.Injective (fun i : Fin 8 => fun j : Fin 3 =>
      s ⟨(i + j : ℕ) % 8, Nat.mod_lt _ (by norm_num)⟩))).card = 16 := by
  decide
-- 16 strings over 8 rotations: 2 rings, as the formula (n!)^(n^(k-1)) / n^k gives.
example : 16 / 8 = 2 ∧ (Nat.factorial 2) ^ (2 ^ 2) / 2 ^ 3 = 2 := by decide
-- The formula at the two other sizes: 16 rings for n = 2, k = 4, and 24 for n = 3, k = 2.
example : (Nat.factorial 2) ^ (2 ^ 3) / 2 ^ 4 = 16 := by decide
example : (Nat.factorial 3) ^ (3 ^ 1) / 3 ^ 2 = 24 := by decide
-- Two digits, length 3: 8 codes, 4 windows, 10 presses flat against 24 listed one by one.
example : 2 ^ 3 = 8 ∧ 2 ^ 2 = 4 ∧ 2 ^ 3 + 3 - 1 = 10 ∧ 3 * 2 ^ 3 = 24 := by decide
-- The lock, ten digits, length 4: 10,003 presses against 40,000, saving 29,997.
example : 10 ^ 4 + 4 - 1 = 10003 ∧ 4 * 10 ^ 4 = 40000 ∧ 40000 - 10003 = 29997 := by norm_num

#print axioms de_bruijn_ring_exists
#print axioms de_bruijn_ring_length_ge
#print axioms de_bruijn_flat_presses
