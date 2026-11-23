-- Average-case hardness: the random self-reduction for discrete logarithms makes every shifted target uniform, so a solver right on a share of targets is right on that same share of shifts for any target, and shifting back always gives the true logarithm.
import Mathlib.GroupTheory.OrderOfElement
import Mathlib.Algebra.Group.Subgroup.ZPowers.Basic
import Mathlib.Data.Nat.Prime.Basic
import Mathlib.Tactic.NormNum.Prime

/-- Helper: a power of `g`, where `g` has positive order `m`, is `g ^ r` for some `r < m`. -/
theorem zpowers_eq_pow_lt_order {G : Type*} [Group G] [DecidableEq G]
    (g : G) {m : ℕ} (hm : orderOf g = m) (hpos : 0 < m) (w : G)
    (hw : w ∈ Subgroup.zpowers g) : ∃ r, r < m ∧ g ^ r = w := by
  have hx : IsOfFinOrder g := orderOf_pos_iff.mp (hm ▸ hpos)
  rw [hx.mem_zpowers_iff_mem_range_orderOf, Finset.mem_image] at hw
  obtain ⟨r, hr, hrw⟩ := hw
  exact ⟨r, hm ▸ Finset.mem_range.mp hr, hrw⟩

/-- Random self-reduction, the cost of one try: let `g` have order `m` and let the solver
answer the targets in a set `S` of powers of `g`. For any target `y = g ^ x`, the number of
shifts `r` from `0` to `m - 1` for which the shifted target `y * g ^ r` lies in `S` is exactly
`|S|`. So each random shift succeeds with chance exactly `ρ = |S| / m`, whatever `y` is. -/
theorem shifted_target_hits_solver_share {G : Type*} [Group G] [DecidableEq G]
    (g : G) {m : ℕ} (hm : orderOf g = m) (hpos : 0 < m)
    (S : Finset G) (hS : ∀ z ∈ S, z ∈ Subgroup.zpowers g) (x : ℕ) :
    ((Finset.range m).filter (fun r => g ^ x * g ^ r ∈ S)).card = S.card := by
  refine Finset.card_bij (fun r _ => g ^ x * g ^ r) ?_ ?_ ?_
  · intro r hr
    exact (Finset.mem_filter.mp hr).2
  · intro r1 hr1 r2 hr2 heq
    have h1 := Finset.mem_range.mp (Finset.mem_filter.mp hr1).1
    have h2 := Finset.mem_range.mp (Finset.mem_filter.mp hr2).1
    have h : g ^ r1 = g ^ r2 := mul_left_cancel heq
    rw [pow_inj_mod, hm, Nat.mod_eq_of_lt h1, Nat.mod_eq_of_lt h2] at h
    exact h
  · intro z hz
    obtain ⟨r, hr, hrw⟩ := zpowers_eq_pow_lt_order g hm hpos ((g ^ x)⁻¹ * z)
      (Subgroup.mul_mem _ (Subgroup.inv_mem _ (Subgroup.pow_mem _ (Subgroup.mem_zpowers g) x))
        (hS z hz))
    refine ⟨r, Finset.mem_filter.mpr ⟨Finset.mem_range.mpr hr, ?_⟩, ?_⟩
    · rw [hrw, mul_inv_cancel_left]; exact hz
    · rw [hrw, mul_inv_cancel_left]

/-- The shifted target is uniform: let `g` have order `m`. For any target `y = g ^ x`, every
power `z` of `g` is hit by exactly one shift `r` from `0` to `m - 1`, that is `y * g ^ r = z`
for exactly one such `r`. -/
theorem shifted_target_uniform {G : Type*} [Group G] [DecidableEq G]
    (g : G) {m : ℕ} (hm : orderOf g = m) (hpos : 0 < m) (x : ℕ)
    (z : G) (hz : z ∈ Subgroup.zpowers g) :
    ((Finset.range m).filter (fun r => g ^ x * g ^ r = z)).card = 1 := by
  have h := shifted_target_hits_solver_share g hm hpos {z}
    (fun w hw => (Finset.mem_singleton.mp hw) ▸ hz) x
  simpa using h

/-- Shifting back is always right: let `g` have order `m`, and let the shift `r` be below `m`.
If the solver's answer `s` satisfies `g ^ s = y * g ^ r`, then `s - r`, wrapped at `m`, is a
logarithm of `y`: `g ^ ((s + m - r) % m) = y`. -/
theorem shift_back_gives_log {G : Type*} [Group G]
    (g y : G) {m : ℕ} (hm : orderOf g = m) (s r : ℕ) (hr : r < m)
    (h : g ^ s = y * g ^ r) :
    g ^ ((s + m - r) % m) = y := by
  have hpos : 0 < m := lt_of_le_of_lt (Nat.zero_le r) hr
  have hy : y = g ^ s * (g ^ r)⁻¹ := by rw [h, mul_inv_cancel_right]
  rw [← hm, pow_mod_orderOf, hy, eq_mul_inv_iff_mul_eq, ← pow_add,
    Nat.sub_add_cancel (by omega), pow_add, pow_orderOf_eq_one, mul_one]

-- The toy clock of 1,009 with base 11 (insecure at this size).
example : Nat.Prime 1009 := by norm_num
example : 11 ^ 613 % 1009 = 956 := by decide +kernel
-- 11 has order 1,008 on the clock: 11 ^ 1008 is 1, and 11 ^ (1008 / p) is not 1 for the
-- primes p = 2, 3, 7 dividing 1,008 = 2 ^ 4 * 3 ^ 2 * 7.
example : 1008 = 2 ^ 4 * 3 ^ 2 * 7 := by norm_num
example : 11 ^ 1008 % 1009 = 1 := by decide +kernel
example : 11 ^ 504 % 1009 ≠ 1 := by decide +kernel
example : 11 ^ 336 % 1009 ≠ 1 := by decide +kernel
example : 11 ^ 144 % 1009 ≠ 1 := by decide +kernel

-- The rota: 5 staff have 10 pairs, so 2 ^ 10 = 1,024 clash lists; every rota tried is 3 ^ n.
example : Nat.choose 5 2 = 10 := by decide
example : 2 ^ 10 = 1024 := by norm_num
example : 3 ^ 5 = 243 := by norm_num
example : 3 ^ 10 = 59049 := by norm_num
example : 3 ^ 20 = 3486784401 := by norm_num
example : 3 ^ 30 = 205891132094649 := by norm_num
example : 3 ^ 60 = 42391158275216203514294433201 := by norm_num

#print axioms zpowers_eq_pow_lt_order
#print axioms shifted_target_hits_solver_share
#print axioms shifted_target_uniform
#print axioms shift_back_gives_log
