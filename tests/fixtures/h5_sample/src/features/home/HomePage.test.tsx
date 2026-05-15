import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { HomePage } from "./HomePage";

describe("HomePage", () => {
  it("renders default title", () => {
    render(<HomePage />);
    expect(screen.getByText("Home")).toBeTruthy();
  });
});
