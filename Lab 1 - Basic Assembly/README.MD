### **Learning Objectives**
- **Assembly Language Programming:** Learn to implement basic functions and algorithms in ARM assembly, including function calls, recursive calls, and stack usage.
- **Algorithm Implementation:** Gain experience in translating common algorithms like exponentiation, factorial, and quicksort into low-level assembly instructions.
- **Subroutine Conventions:** Understand and apply subroutine calling conventions to manage arguments, return values, and the call stack effectively.

---

### **Computer Organization Concepts Covered**
- **Function Calling Conventions:** Use of registers (e.g., R0-R3) for argument passing and stack operations for saving/restoring processor state.
- **Recursion in Assembly:** Implementation of recursive functions using the stack for intermediate state storage.
- **Sorting Algorithms:** Understanding and implementing the quicksort algorithm in assembly language, including swapping and recursive partitioning.
- **Efficient Computation:** Optimization techniques such as exponentiation by squaring for efficient mathematical operations.

---

### **Summary of the Problem and Deliverables**
#### **Part 1: Function Implementations**
1. **Exponential Function (part1-exp.s):** Write a loop-based assembly program to compute \(x^n\) for integer \(x\) and positive integer \(n\).
2. **Factorial Function (part1-fact.s):** Implement a recursive function in assembly to calculate \(n!\), demonstrating recursive calls and base case handling.
3. **Exponentiation by Squaring (part1-expbysq.s):** Implement a more efficient recursive algorithm for computing \(x^n\) using exponentiation by squaring.

#### **Part 2: Quicksort Implementation**
1. **Quicksort Algorithm (part2.s):** Write an assembly program to implement the quicksort algorithm, sorting an array in ascending order. Use a helper function to swap elements and ensure recursive partitioning is handled correctly.

