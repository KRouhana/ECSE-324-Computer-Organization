### **Learning Objectives**
- **Advanced I/O Programming:** Develop drivers for VGA displays and PS/2 keyboards to explore complex I/O capabilities.
- **Device Control:** Understand memory-mapped I/O and use it to interact with graphical and textual outputs on a VGA screen and keyboard inputs via PS/2 protocol.
- **Integrated Application Development:** Combine multiple drivers into a cohesive application for dynamic visual output based on keyboard interactions.

---

### **Computer Organization Concepts Covered**
- **Memory-Mapped I/O:** Direct manipulation of pixel and character buffers for rendering graphics and text on a VGA display.
- **Driver Development:** Creation of modular subroutines to handle VGA and PS/2 keyboard functionality.
- **Keyboard Protocols:** Handling make and break codes in the PS/2 protocol to process keypress events.
- **Graphics Rendering:** Drawing points, rectangles, and characters on a screen by writing to specific memory addresses.
- **Integration of Subsystems:** Combining input and output drivers to create a real-time interactive application.

---

### **Summary of the Problem and Deliverables**
#### **Part 1: VGA Driver**
- **Task:**
  - Implement functions to:
    - Draw points on the screen (`VGA_draw_point_ASM`).
    - Clear the pixel buffer (`VGA_clear_pixelbuff_ASM`).
    - Write ASCII characters on the screen (`VGA_write_char_ASM`).
    - Clear the character buffer (`VGA_clear_charbuff_ASM`).
  - Test the driver by rendering a predefined image using the VGA pixel buffer and character buffer.

#### **Part 2: PS/2 Driver**
- **Task:**
  - Implement the `read_PS2_data_ASM` function to:
    - Read and validate keyboard inputs from the PS/2 data register.
    - Store valid inputs and return their status.
  - Test the driver by displaying keyboard make and break codes on the VGA screen.

#### **Part 3: Vexillology Application**
- **Task:**
  - Combine the VGA and PS/2 drivers into an application to display a gallery of flags.
  - Implement navigation through flags using keyboard inputs (e.g., "A" to show the previous flag and "D" to show the next flag).
  - Create two additional flags (one real and one imaginary) using provided drawing functions (`draw_rectangle`, `draw_star`).
