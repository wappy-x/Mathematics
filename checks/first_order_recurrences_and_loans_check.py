# First-order recurrences and loans -- the check behind the card.  Nothing is
# imported.  A $20,000 car loan at 0.5% a month over 48 months, with balance
# B(n) = 1.005 B(n-1) - P, reached twice: by stepping, and by the closed form.
B0, RATE, N = 20000.0, 0.005, 48
R = 1.0 + RATE                              # the monthly growth factor

def power(x, k):                            # x multiplied in k times
    out = 1.0
    for _ in range(k): out = out * x
    return out

def step(start, pay, months):               # road one: a month at a time
    path = [start]
    for _ in range(months): path.append(path[-1] * R - pay)
    return path

def closed(start, pay, n):                  # road two: shift to the fixed point
    anchor = -pay / (1.0 - R)               # c / (1 - r), here with c = -pay
    return power(R, n) * (start - anchor) + anchor

def level_payment(rate, n):                 # the closed-form level repayment
    g = power(1.0 + rate, n)
    return B0 * rate * g / (g - 1.0)

def bisect_payment(n):                      # road three: bisection on the stepping
    lo, hi = 0.0, 2000.0
    for _ in range(200):
        mid = (lo + hi) / 2.0
        lo, hi = (mid, hi) if step(B0, mid, n)[-1] > 0.0 else (lo, mid)
    return (lo + hi) / 2.0

def cash(v):                                # a residue under half a cent reads 0.00
    return f"{0.0 if abs(v) < 0.005 else v:.2f}"

P, guess = level_payment(RATE, N), bisect_payment(N)
path, anchor, marks = step(B0, P, N), P / RATE, list(range(0, N + 1, 6))
save = [0.0]
for _ in range(N): save.append(save[-1] * R + P)    # the same rule, payment added
split = [path[m - 1] * RATE for m in (1, 12, 24, 36, 48)]
print(f"loan {cash(B0)} at {RATE * 100:.1f}% a month over {N} months; growth factor {R}; {N} multiplies give {power(R, N):.6f}")
print(f"level payment: closed form {P:.4f}, bisection on the stepping {guess:.4f}")
print(f"the anchor, payment / rate: {cash(anchor)} -- the balance this payment holds still")
print("month        " + "".join(f"{m:>9}" for m in marks))
print("balance      " + "".join(f"{cash(path[m]):>9}" for m in marks))
print("closed form  " + "".join(f"{cash(closed(B0, P, m)):>9}" for m in marks))
print("straight line" + "".join(f"{cash(B0 * (1 - m / N)):>9}" for m in marks))
print(f"month 1: interest {cash(split[0])}, principal {cash(P - split[0])}, balance {cash(path[1])}")
print(f"month 2: interest {cash(path[1] * RATE)}, principal {cash(P - path[1] * RATE)}, balance {cash(path[2])}")
print("interest  inside the payment at months 1, 12, 24, 36, 48: " + ", ".join(cash(i) for i in split))
print("principal inside the payment at months 1, 12, 24, 36, 48: " + ", ".join(cash(P - i) for i in split))
print(f"paid in all {cash(N * P)}; interest {cash(N * P - B0)}; last balance {cash(path[N])}")
print(f"the same payment saved reaches {cash(save[N])}; the loan left unpaid grows to {cash(B0 * power(R, N))}")
print(f"mistake 1, {cash(B0 / N)} a month and no interest: {cash(step(B0, B0 / N, N)[-1])} still owing")
print(f"mistake 2, 6% a year read as 6% a month: payment {cash(level_payment(0.06, N))}")
print(f"mistake 3, payment rounded down to 469.00: {cash(step(B0, 469.0, N)[-1])} still owing")
assert max(abs(path[m] - closed(B0, P, m)) for m in range(N + 1)) < 1e-9   # stepping vs closed form
assert abs(guess - P) < 1e-6 and abs(path[N]) < 1e-6                       # root hunt vs formula
assert abs(save[N] - B0 * power(R, N)) < 1e-6                              # saved vs principal grown
assert round(P * 100) == 46970 and round(anchor * 100) == 9394012
print("ALL CHECKS PASS")
