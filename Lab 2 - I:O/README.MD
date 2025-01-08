### **Learning Objectives**
- **I/O Programming:** Understand memory-mapped I/O concepts and implement drivers for basic and advanced peripherals like LEDs, HEX displays, and pushbuttons.
- **Timer and Interrupt Handling:** Learn to configure and use hardware timers, implement polling-based and interrupt-based applications, and manage asynchronous events effectively.
- **Low-Level Programming:** Gain practical experience in ARM assembly language to interface with hardware components and control peripherals on the DE1-SoC board.

---

### **Computer Organization Concepts Covered**
- **Memory-Mapped I/O:** Access and manipulate hardware registers mapped to specific memory addresses for peripheral control.
- **Polling vs Interrupts:** Compare and implement both techniques for handling events, such as button presses and timer expirations.
- **Timer Configuration:** Configure and use hardware counters for time tracking and synchronization tasks.
- **Interrupt Service Routines (ISRs):** Write and manage ISRs to handle asynchronous events efficiently, using the ARM Generic Interrupt Controller (GIC).
- **Driver Development:** Develop reusable drivers for I/O devices, emphasizing modular design and proper calling conventions.

---

### **Summary of the Problem and Deliverables**
#### **Part 1: I/O Routine Library**
- **Tasks:**
  1. Write drivers for slider switches, LEDs, HEX displays, and pushbuttons to read/write states or display values.
  2. Create an application to:
     - Map slider switch states to LEDs.
     - Display a number (0–15) on HEX displays when a pushbutton is pressed, based on the states of SW3–SW0.
     - Clear all HEX displays when SW9 is asserted.

#### **Part 2: Polling-Based Stopwatch**
- **Task:**
  - Implement a stopwatch using the ARM A9 private timer and pushbuttons.
  - Display milliseconds, seconds, minutes, and hours on HEX displays.
  - Use polling to handle button presses for starting, stopping, and resetting the stopwatch.

#### **Part 3: Interrupt-Based Stopwatch**
- **Task:**
  - Modify the stopwatch to use interrupts instead of polling.
  - Enable interrupts for the timer and pushbuttons using the ARM GIC.
  - Handle asynchronous events in ISRs, such as timer expiration and button presses.