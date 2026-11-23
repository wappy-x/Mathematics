-- Proof assistants: no whole numbers p and q, with q at least 1, have p * p = 2 * (q * q), so root 2 is not a fraction. Lean's core library only.
theorem sq_odd (k : Nat) : (2*k+1) * (2*k+1) = 4*(k*k) + 4*k + 1 := by
  rw [Nat.add_mul, Nat.mul_add, Nat.mul_add, Nat.mul_mul_mul_comm]; omega

theorem sq_even (k : Nat) : (2*k) * (2*k) = 4*(k*k) := by
  rw [Nat.mul_mul_mul_comm]

-- If a square is even, the number is even: the odd case clashes on parity.
theorem even_of_sq (p y : Nat) (h : p * p = 2 * y) : ∃ k, p = 2 * k := by
  cases Nat.mod_two_eq_zero_or_one p with
  | inl h0 => exact ⟨p / 2, by omega⟩
  | inr h1 =>
    have hp : p = 2 * (p / 2) + 1 := by omega
    rw [hp, sq_odd] at h; omega

theorem root_two_irrational (q : Nat) : ∀ p, 1 ≤ q → p * p ≠ 2 * (q * q) := by
  induction q using Nat.strongRecOn with
  | ind q ih =>
    intro p hq h
    obtain ⟨k, rfl⟩ := even_of_sq p (q * q) h          -- step 3: p = 2k
    rw [sq_even] at h                                  -- step 4: 4kk = 2qq
    have h5 : q * q = 2 * (k * k) := by omega          -- step 5: halve
    obtain ⟨m, rfl⟩ := even_of_sq q (k * k) h5         -- step 6: q = 2m
    rw [sq_even] at h5                                 -- step 7: 2kk = 4mm
    exact ih m (by omega) k (by omega) (by omega)      -- steps 8 to 11: descent

#print axioms sq_odd
#print axioms sq_even
#print axioms even_of_sq
#print axioms root_two_irrational
