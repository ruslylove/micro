# AVR Microcontroller and Embedded Systems - Lecture Slides

This repository contains lecture slides for a microcontroller course based on
**"The AVR Microcontroller and Embedded Systems Using Assembly and C"**
by Mazidi, Naimi & Naimi.

**Instructor:** Dr. Ruslee Sutthaweekul

These slides are built using [Slidev](https://sli.dev), an open-source slide deck generator for developers.

## Course Content

Chapters 0-6 of the textbook:

*   **Chapter 0:** Introduction to Computing (number systems, logic gates, memory, CPU architecture)
*   **Chapter 1:** The AVR Microcontroller: History and Features
*   **Chapter 2:** AVR Architecture and Assembly Language Programming
*   **Chapter 3:** Branch, Call, and Time Delay Loop
*   **Chapter 4:** AVR I/O Port Programming
*   **Chapter 5:** Arithmetic, Logic Instructions, and Programs
*   **Chapter 6:** AVR Advanced Assembly Language Programming

## How to View the Slides

Live version: https://ruslylove.github.io/micro/

To run the interactive slide show on your local machine, you need Node.js installed.

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/ruslylove/micro.git
    cd micro
    ```
2.  **Install dependencies:**
    ```bash
    npm install
    ```
3.  **Start the presentation:**
    ```bash
    npm run dev
    ```
4.  Open your browser and navigate to `http://localhost:3030`.

## Deployment

Pushes to `main` automatically build and deploy the slides to GitHub Pages via
`.github/workflows/deploy.yml`. Include `[pdf]` in a commit message (or run the
workflow manually) to also (re)export `slides.pdf`.

## License

The content and code examples in this repository are provided for educational purposes.

---

Learn more about Slidev at the official documentation.
